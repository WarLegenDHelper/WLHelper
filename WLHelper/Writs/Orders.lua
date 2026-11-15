-- Writs/Orders.lua: crafting orders between guild members, like the retail crafting orders.
--
--  Recipes   Each member who has WL Helper shares the recipes of the professions he opened (the
--            item made and its reagents). A short "hash" goes to the guild at login; whoever holds
--            an older copy asks for the full list by whisper.
--  Orders    A customer publishes an order to the whole guild or to one crafter: item, quantity,
--            who provides each reagent, commission, optional tip, how long it stays open, a note.
--            A crafter accepts or declines (with a reason). Status: open, accepted, crafted,
--            delivered, declined, cancelled, expired. Everything goes on the guild's addon channel;
--            every copy keeps the orders it saw (WLWritsDB.orders).
--  Mail      Nothing is sent by the addon: at the mailbox it fills the mail (recipient, subject,
--            attachments, money or cash on delivery) and the player clicks Send. The crafter's
--            inbox is read to tell what already arrived from the customer: reagents and money.
--
-- Only item IDs, counts, prices, names of guild members and the note travel. Nothing else.
local ADDON, root = ...
root.Writs = root.Writs or {}
local ns = root.Writs
local WP = ns.WP
local L = ns.L

local O = {}
WP.Orders = O
local S = ns.S

ns.AddEnglish({
    ["Commandes"] = "Orders",
    ["Nouvelle commande de %s : %s ×%d (%s)."] = "New order from %s: %s ×%d (%s).",
    ["%s a accepté ta commande : %s ×%d."] = "%s accepted your order: %s ×%d.",
    ["%s a refusé ta commande (%s)."] = "%s declined your order (%s).",
    ["%s a fabriqué ta commande : %s ×%d. Elle arrive par la poste."] = "%s crafted your order: %s ×%d. It comes by mail.",
    ["Commande WL : %s ×%d"] = "WL order: %s ×%d",
    ["Commission trop basse"] = "Commission too low",
    ["Pas les composants"] = "Missing reagents",
    ["Pas le temps"] = "No time",
    ["Recharge en cours"] = "On cooldown",
    ["Autre"] = "Other",
    ["ouvre la boîte aux lettres, onglet Envoyer."] = "open the mailbox, Send tab.",
    ["Contre-remboursement impossible sans objet joint : demande %s à %s."] = "Cash on delivery needs an attached item: ask %s from %s.",
})

local PREFIX = "WLHord"
local CI = C_ChatInfo
local Register = (CI and CI.RegisterAddonMessagePrefix) or RegisterAddonMessagePrefix
local SendRaw = (CI and CI.SendAddonMessage) or SendAddonMessage
if Register then pcall(Register, PREFIX) end

local function safe(f, ...)
    if not f then return nil end
    local ok, a, b, c, d, e, g, h = pcall(f, ...)
    if ok then return a, b, c, d, e, g, h end
end

local function Me() return (UnitName("player")) end
local function Short(n) return n and (n:gsub("%-.*$", "")) end

-- ---------------------------------------------------------------- storage
local function DB()
    WLWritsDB.orders = WLWritsDB.orders or {}
    local d = WLWritsDB.orders
    d.crafters = d.crafters or {}   -- [player] = { [prof] = { rank, max, hash, t, recipes = { [itemID] = "id:n,id:n" } } }
    d.list = d.list or {}           -- [orderID] = order
    d.mine = d.mine or {}           -- my own professions, as read: [prof] = { rank, max, recipes }
    return d
end
O.DB = DB

-- ---------------------------------------------------------------- sending, throttled
-- Addon messages are limited to 255 bytes and the server drops floods: a burst of 10, then one
-- a second (a token bucket). A message the client refuses as throttled waits and goes again.
local outbox = {}
local pumping = false
local tokens, tokensAt = 10, 0
local function Pump()
    local m = outbox[1]
    if not m then pumping = false; return end
    local now = GetTime()
    tokens = math.min(10, tokens + (now - tokensAt)); tokensAt = now
    if tokens < 1 then C_Timer.After(1 - tokens, Pump); return end
    local ok, r = false, nil
    if SendRaw then ok, r = pcall(SendRaw, PREFIX, m[1], m[2], m[3]) end
    -- false, or a non-zero result code (modern clients: 0 = success), means throttled or refused
    local refused = ok and (r == false or (type(r) == "number" and r ~= 0))
    if refused and (m.tries or 0) < 3 then
        m.tries = (m.tries or 0) + 1
        tokens = 0
        C_Timer.After(1.5, Pump); return
    end
    table.remove(outbox, 1)
    tokens = tokens - 1
    C_Timer.After(0.1, Pump)
end
local function Send(msg, channel, target)
    if not channel then return end
    outbox[#outbox + 1] = { msg, channel, target }
    if not pumping then pumping = true; C_Timer.After(0.05, Pump) end
end
local function Guild(msg) if IsInGuild and IsInGuild() then Send(msg, "GUILD") end end
-- Long payloads are cut in parts: "P|key|i|n|chunk".
local function SendParts(key, payload, channel, target)
    local size = 200
    local n = math.max(1, math.ceil(#payload / size))
    for i = 1, n do Send("P|" .. key .. "|" .. i .. "|" .. n .. "|" .. payload:sub((i - 1) * size + 1, i * size), channel, target) end
end

-- ---------------------------------------------------------------- my recipes
-- "itemID:n,itemID:n" for a recipe's reagents
local function Encode(reagents)
    local t = {}
    for _, r in ipairs(reagents) do t[#t + 1] = r[1] .. ":" .. r[2] end
    return table.concat(t, ",")
end
function O.Decode(s)
    local out = {}
    for id, n in tostring(s or ""):gmatch("(%d+):(%d+)") do out[#out + 1] = { tonumber(id), tonumber(n) } end
    return out
end

local function Hash(recipes)
    local keys = {}
    for k, v in pairs(recipes) do keys[#keys + 1] = k .. "=" .. v end
    table.sort(keys)
    local h = 5381
    for _, s in ipairs(keys) do
        for i = 1, #s do h = (h * 33 + s:byte(i)) % 4294967296 end
    end
    return string.format("%08x", h)
end

local function LinkID(link) return link and tonumber(link:match("item:(%d+)")) end

-- Reads the open profession window (trade skills; enchanting's craft window too).
local function ReadProfession()
    local prof, rank, max
    local recipes = {}
    if GetTradeSkillLine and GetNumTradeSkills and (GetNumTradeSkills() or 0) > 0 then
        prof, rank, max = GetTradeSkillLine()
        for i = 1, GetNumTradeSkills() do
            local name, kind = GetTradeSkillInfo(i)
            if name and kind ~= "header" then
                local id = LinkID(safe(GetTradeSkillItemLink, i))
                if id then
                    local reagents = {}
                    for j = 1, (safe(GetTradeSkillNumReagents, i) or 0) do
                        local _, _, count = safe(GetTradeSkillReagentInfo, i, j)
                        local rid = LinkID(safe(GetTradeSkillReagentItemLink, i, j))
                        if rid and count then reagents[#reagents + 1] = { rid, count } end
                    end
                    recipes[id] = Encode(reagents)
                end
            end
        end
    elseif GetCraftDisplaySkillLine and GetNumCrafts and (GetNumCrafts() or 0) > 0 then
        prof, rank, max = GetCraftDisplaySkillLine()
        for i = 1, GetNumCrafts() do
            local name, _, kind = GetCraftInfo(i)
            if name and kind ~= "header" then
                -- an enchant makes no item: kept by its spell, as a negative number
                local link = safe(GetCraftItemLink, i)
                local spell = link and tonumber(link:match("enchant:(%d+)"))
                if spell then
                    local reagents = {}
                    for j = 1, (safe(GetCraftNumReagents, i) or 0) do
                        local _, _, count = safe(GetCraftReagentInfo, i, j)
                        local rid = LinkID(safe(GetCraftReagentItemLink, i, j))
                        if rid and count then reagents[#reagents + 1] = { rid, count } end
                    end
                    recipes[-spell] = Encode(reagents)
                end
            end
        end
    end
    if not prof or not next(recipes) then return end
    local d = DB()
    local old = d.mine[prof]
    -- a filtered window or collapsed headers show only part of the list: add, never shrink
    if old and old.recipes then
        for id, re in pairs(old.recipes) do if recipes[id] == nil then recipes[id] = re end end
    end
    local hash = Hash(recipes)
    d.mine[prof] = { rank = rank, max = max, recipes = recipes, hash = hash }
    if not old or old.hash ~= hash then O.Announce() end
end
local readQueued = false
local function QueueRead()
    if readQueued then return end
    readQueued = true
    C_Timer.After(1, function() readQueued = false; ReadProfession() end)
end

-- My professions' hashes to the guild: those with an older copy will ask for the list.
function O.Announce()
    if WLWritsDB.ordersShare == false then return end
    for prof, p in pairs(DB().mine) do
        Guild("H|" .. prof .. "|" .. (p.rank or 0) .. "|" .. (p.max or 0) .. "|" .. p.hash)
    end
end

-- The list goes to the whole guild, at most once a minute per profession, however many ask.
local recipesSent = {}
local function SendRecipes(prof)
    if WLWritsDB.ordersShare == false then return end
    local p = DB().mine[prof]
    if not p then return end
    local since = recipesSent[prof] and GetTime() - recipesSent[prof]
    if since and since < 60 then
        -- asked again within the minute: one more send when the minute is over
        if not recipesSent[prof .. "?"] then
            recipesSent[prof .. "?"] = true
            C_Timer.After(61 - since, function() recipesSent[prof .. "?"] = nil; SendRecipes(prof) end)
        end
        return
    end
    recipesSent[prof] = GetTime()
    local t = {}
    for id, re in pairs(p.recipes) do t[#t + 1] = id .. "=" .. re end
    if IsInGuild and IsInGuild() then SendParts("R:" .. prof .. ":" .. p.hash, table.concat(t, ";"), "GUILD") end
end

-- An item's name, or an enchant's (kept as a negative spell ID).
function O.Name(id)
    if not id then return "?" end
    if id > 0 then return WP.ItemName(id) or ("item " .. id) end
    local n = (C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(-id)) or (GetSpellInfo and GetSpellInfo(-id))
    return n or "?"
end

-- ---------------------------------------------------------------- orders
local function NewID() return Me() .. "-" .. time() .. "-" .. math.random(100, 999) end

-- order = { id, from, to (nil = guild), item, qty, give = "id:n,..." (customer), crafter = "id:n,..."
--           (crafter provides), fee (copper), tip, paid (upfront copper), note, expires, status, by, reason }
local FIELDS = { "id", "from", "to", "item", "qty", "give", "crafter", "fee", "tip", "paid", "expires", "status", "by", "reason", "note" }

-- "O|" + fields must fit in one 255-byte message: the note is shortened (whole UTF-8 characters).
local MAXMSG = 250
local function Serialize(o)
    local t = {}
    for i, k in ipairs(FIELDS) do
        local v = o[k]
        if v == nil then v = "" end
        t[i] = (tostring(v):gsub("[|;~]", " "))
    end
    local s = table.concat(t, "~")
    local noteAt = #FIELDS
    while #s + 2 > MAXMSG and t[noteAt] ~= "" do
        t[noteAt] = t[noteAt]:gsub("[%z\1-\127\192-\255][\128-\191]*$", "")
        s = table.concat(t, "~")
    end
    return s
end
local function Parse(s)
    local o, i = {}, 0
    for v in (s .. "~"):gmatch("(.-)~") do
        i = i + 1
        local k = FIELDS[i]
        if k and v ~= "" then o[k] = (k == "qty" or k == "fee" or k == "tip" or k == "paid" or k == "expires" or k == "item") and tonumber(v) or v end
    end
    return o.id and o
end

local STATUS_RANK = { open = 1, accepted = 2, crafted = 3, delivered = 4, declined = 5, cancelled = 5, expired = 5 }

-- Merges what another copy says about an order; a status never goes back. The wire fields are
-- copied into our copy, so what only we know (got, gotMoney, sentGive, snapshots) stays.
local function Merge(o)
    local d = DB()
    local cur = d.list[o.id]
    if not cur then d.list[o.id] = o; return o, true end
    if cur == o then return cur, true end
    local r1, r2 = STATUS_RANK[o.status] or 0, STATUS_RANK[cur.status] or 0
    if r1 < r2 then return cur, false end
    -- two crafters took the same guild order: everyone keeps the same one (the first name)
    if r1 == r2 and cur.by and o.by and cur.by ~= o.by and cur.by < o.by then return cur, false end
    local changed = cur.status ~= o.status or cur.by ~= o.by
    local tip = math.max(cur.tip or 0, o.tip or 0)
    for _, k in ipairs(FIELDS) do cur[k] = o[k] end
    if tip > 0 then cur.tip = tip end
    return cur, changed
end

-- Who may say what: the customer creates, rewrites (tip) and cancels; the crafter who took it
-- accepts, crafts, delivers; a crafter declines an order sent to him.
local function Allowed(o, sender)
    local cur = DB().list[o.id]
    local from = cur and cur.from or o.from
    if not cur then return sender == o.from end
    if o.from ~= cur.from then return false end
    if sender == from then return o.status == cur.status or o.status == "cancelled" or o.status == "expired" or (o.by == cur.by) end
    if o.status == "accepted" then return o.by == sender and (not cur.to or cur.to == sender) end
    if o.status == "crafted" or o.status == "delivered" then return o.by == sender end
    if o.status == "declined" then return cur.to == sender end
    return false
end

local function Broadcast(o) Guild("O|" .. Serialize(o)) end

function O.Publish(order)
    order.id = NewID()
    order.from = Me()
    order.status = "open"
    order.expires = time() + (order.hours or 24) * 3600
    order.hours = nil
    Merge(order)
    Broadcast(order)
    if WP.RefreshOrders then WP.RefreshOrders() end
    return order
end

local function SetStatus(o, status, extra)
    o.status = status
    for k, v in pairs(extra or {}) do o[k] = v end
    Merge(o)
    Broadcast(o)
    if WP.RefreshOrders then WP.RefreshOrders() end
end
function O.Accept(o) if o.status == "open" then SetStatus(o, "accepted", { by = Me() }) end end
function O.Decline(o, reason)
    if o.to then SetStatus(o, "declined", { by = Me(), reason = reason })
    else
        -- an order to the whole guild stays open for the others; only you stop seeing it
        local d = DB(); d.hidden = d.hidden or {}; d.hidden[o.id] = true
        if WP.RefreshOrders then WP.RefreshOrders() end
    end
end
function O.Crafted(o) SetStatus(o, "crafted") end
function O.Delivered(o) SetStatus(o, "delivered") end
function O.Cancel(o) SetStatus(o, "cancelled") end
function O.AddTip(o, copper) o.tip = (o.tip or 0) + copper; Merge(o); Broadcast(o) end

-- Orders as lists: mine (I asked), for me (I may craft), each sorted newest first.
function O.Lists()
    local d = DB()
    local me = Me()
    local mine, forMe = {}, {}
    local now = time()
    for _, o in pairs(d.list) do
        if o.status == "open" and o.expires and o.expires < now then o.status = "expired" end
        if o.from == me then mine[#mine + 1] = o
        elseif (o.to == me or (not o.to and O.CanCraft(me, o.item))) and not (d.hidden and d.hidden[o.id]) then
            if o.status == "open" or o.by == me then forMe[#forMe + 1] = o end
        end
    end
    local function newest(a, b) return (a.expires or 0) > (b.expires or 0) end
    table.sort(mine, newest); table.sort(forMe, newest)
    return mine, forMe
end

-- ---------------------------------------------------------------- crafters
-- Who can make an item: { { name, prof, rank, online } }, best rank first.
function O.Crafters(item)
    local out = {}
    local online = O.OnlineGuild()
    for name, profs in pairs(DB().crafters) do
        for prof, p in pairs(profs) do
            if p.recipes and p.recipes[item] then
                out[#out + 1] = { name = name, prof = prof, rank = p.rank or 0, online = online[name] or false, seen = p.t }
            end
        end
    end
    for prof, p in pairs(DB().mine) do
        if p.recipes[item] then out[#out + 1] = { name = Me(), prof = prof, rank = p.rank or 0, online = true, me = true } end
    end
    table.sort(out, function(a, b)
        if a.online ~= b.online then return a.online end
        return a.rank > b.rank
    end)
    return out
end
function O.CanCraft(name, item)
    if name == Me() then
        for _, p in pairs(DB().mine) do if p.recipes[item] then return true end end
        return false
    end
    for _, p in pairs(DB().crafters[name] or {}) do if p.recipes and p.recipes[item] then return true end end
    return false
end
-- Reagents of an item, from any crafter's list.
function O.Reagents(item)
    for _, p in pairs(DB().mine) do if p.recipes[item] then return O.Decode(p.recipes[item]) end end
    for _, profs in pairs(DB().crafters) do
        for _, p in pairs(profs) do if p.recipes and p.recipes[item] then return O.Decode(p.recipes[item]) end end
    end
    return {}
end
-- Every craftable item known in the guild: { [item] = profession }
function O.Catalog()
    local out = {}
    for _, profs in pairs(DB().crafters) do
        for prof, p in pairs(profs) do for id in pairs(p.recipes or {}) do out[id] = prof end end
    end
    for prof, p in pairs(DB().mine) do for id in pairs(p.recipes) do out[id] = out[id] or prof end end
    return out
end

local onlineCache, onlineAt = {}, 0
function O.OnlineGuild()
    if GetTime() - onlineAt < 30 then return onlineCache end
    onlineCache, onlineAt = {}, GetTime()
    if not (IsInGuild and IsInGuild() and GetNumGuildMembers and GetGuildRosterInfo) then return onlineCache end
    for i = 1, (GetNumGuildMembers() or 0) do
        local name, _, _, _, _, _, _, _, online = GetGuildRosterInfo(i)
        if name then onlineCache[Short(name)] = online and true or false end
    end
    return onlineCache
end

-- ---------------------------------------------------------------- mail: what arrived, and filling a mail
-- Each order's mail carries a short tag in its subject ("#4821-317"), so two orders from the same
-- customer are told apart. An untagged mail from him counts only if he has one running order.
function O.Tag(o) return "#" .. (o.id:match("(%d%d%d%d%-%d+)$") or o.id) end

local function Running(o) return o.status == "accepted" or o.status == "crafted" end
local function MailIsFor(o, subject)
    subject = subject or ""
    if subject:find(O.Tag(o), 1, true) then return true end
    if subject:find("#%d%d%d%d%-%d+") then return false end   -- another order's mail
    local me, n = Me(), 0
    for _, x in pairs(DB().list) do if x.from == o.from and x.by == me and Running(x) then n = n + 1 end end
    return n <= 1
end

-- From the open inbox: items (by ID) and money this order's customer sent.
function O.InboxFrom(sender, o)
    local items, money = {}, 0
    if not (GetInboxNumItems and GetInboxHeaderInfo) then return items, money end
    for i = 1, (GetInboxNumItems() or 0) do
        local _, _, from, subject, m, cod, _, hasItem = GetInboxHeaderInfo(i)
        if from and Short(from) == sender and (not o or MailIsFor(o, subject)) then
            money = money + (m or 0)
            if hasItem then
                for j = 1, (ATTACHMENTS_MAX_RECEIVE or 16) do
                    local link = safe(GetInboxItemLink, i, j)
                    local id = LinkID(link)
                    if id then
                        local _, _, _, count = safe(GetInboxItem, i, j)
                        items[id] = (items[id] or 0) + (count or 1)
                    end
                end
            end
        end
    end
    return items, money
end

-- What an accepted order has received so far: for each reagent the customer gives, how many;
-- and the money (upfront payment). Received = what was taken out of the inbox + what is in it.
-- The inbox is only read while the mailbox is open; when what it holds drops, the difference was
-- taken (o.taken). Otherwise the last known numbers stand.
-- true from the first MAIL_INBOX_UPDATE after the mailbox opens (before it, the inbox reads empty)
local inboxReady = false
local function MailboxOpen() return inboxReady and MailFrame and MailFrame:IsShown() end
function O.Received(o)
    o.got = o.got or {}
    o.taken = o.taken or {}
    o.inbox = o.inbox or {}
    if MailboxOpen() then
        local items, money = O.InboxFrom(o.from, o)
        items.money = money
        for _, r in ipairs(O.Decode(o.give)) do items[r[1]] = items[r[1]] or 0 end
        for k, n in pairs(items) do
            local before = o.inbox[k] or 0
            if n < before then o.taken[k] = (o.taken[k] or 0) + (before - n) end
            o.inbox[k] = n
        end
    end
    local list = {}
    for _, r in ipairs(O.Decode(o.give)) do
        local n = (o.taken[r[1]] or 0) + (o.inbox[r[1]] or 0)
        o.got[r[1]] = n
        list[#list + 1] = { id = r[1], need = r[2] * (o.qty or 1), have = n }
    end
    o.gotMoney = (o.taken.money or 0) + (o.inbox.money or 0)
    return list, o.gotMoney
end
-- At the mailbox: note what arrived for every order I am crafting.
local function ScanInbox()
    if not MailboxOpen() then return end
    local me = Me()
    for _, o in pairs(DB().list) do
        if o.by == me and Running(o) then O.Received(o) end
    end
end

-- Fills Blizzard's send-mail form. kind: "give" (the customer sends reagents and, if paying upfront,
-- the money), "deliver" (the crafter sends the crafted items, cash on delivery for the fee).
-- Returns what it could not attach. The player clicks Send.
function O.FillMail(o, kind)
    if not (SendMailFrame and SendMailFrame:IsShown()) then WP.Print(L("ouvre la boîte aux lettres, onglet Envoyer.")); return end
    local to = kind == "give" and (o.by or o.to) or o.from
    if not to then return end
    if SendMailNameEditBox then SendMailNameEditBox:SetText(to) end
    if SendMailSubjectEditBox then SendMailSubjectEditBox:SetText(string.format(L("Commande WL : %s ×%d"), O.Name(o.item), o.qty or 1) .. " " .. O.Tag(o)) end
    local want = {}
    if kind == "give" then
        for _, r in ipairs(O.Decode(o.give)) do want[#want + 1] = { r[1], r[2] * (o.qty or 1) } end
    else
        if o.item and o.item > 0 then want[#want + 1] = { o.item, o.qty or 1 } end
    end
    local maxSlots = ATTACHMENTS_MAX_SEND or 12
    local function FreeSlot()
        for i = 1, maxSlots do if not (GetSendMailItem and GetSendMailItem(i)) then return i end end
    end
    local missing, attached = {}, 0
    for _, w in ipairs(want) do
        local left = w[2]
        for bag = 0, NUM_BAG_SLOTS or 4 do
            for s = 1, (safe(C_Container.GetContainerNumSlots, bag) or 0) do
                local slot = left > 0 and FreeSlot()
                if slot then
                    local info = safe(C_Container.GetContainerItemInfo, bag, s)
                    if info and info.itemID == w[1] and not info.isLocked then
                        local take = math.min(left, info.stackCount or 1)
                        ClearCursor()
                        if take < (info.stackCount or 1) then C_Container.SplitContainerItem(bag, s, take)
                        else C_Container.PickupContainerItem(bag, s) end
                        if CursorHasItem and CursorHasItem() then
                            ClickSendMailItemButton(slot)
                            -- the slot took it when the cursor is empty again; otherwise it goes back
                            if not CursorHasItem() then left = left - take; attached = attached + 1 end
                        end
                        ClearCursor()
                    end
                end
            end
        end
        if left > 0 then missing[#missing + 1] = { w[1], left } end
    end
    -- money: an upfront payment the customer chose, or cash on delivery for the crafter's fee.
    -- Cash on delivery needs an attachment, and the form updates a moment later: set it then, and
    -- check the box really switched, so the fee is never sent as gold by mistake.
    local fee = (o.fee or 0) + (o.tip or 0)
    local cod = fee - (o.gotMoney or 0)
    if kind == "give" and (o.paid or 0) > 0 and SendMailMoney and MoneyInputFrame_SetCopper then
        if SendMailSendMoneyButton then SendMailSendMoneyButton:Click() end
        MoneyInputFrame_SetCopper(SendMailMoney, o.paid)
    elseif kind == "deliver" and cod > 0 and SendMailMoney and MoneyInputFrame_SetCopper then
        C_Timer.After(0.3, function()
            local hasItem = GetSendMailItem and GetSendMailItem(1)
            if hasItem and SendMailCODButton then
                if not SendMailCODButton:GetChecked() then SendMailCODButton:Click() end
            end
            if hasItem and SendMailCODButton and SendMailCODButton:GetChecked() then
                MoneyInputFrame_SetCopper(SendMailMoney, cod)
            else
                if MoneyInputFrame_ResetMoney then MoneyInputFrame_ResetMoney(SendMailMoney) end
                WP.Print(string.format(L("Contre-remboursement impossible sans objet joint : demande %s à %s."), S.Money(cod), o.from))
            end
        end)
    end
    return missing, attached
end

-- ---------------------------------------------------------------- receiving
local parts = {}
local function OnPayload(sender, key, payload)
    local prof, hash = key:match("^R:(.-):(%x+)$")
    if prof then
        local recipes = {}
        for id, re in payload:gmatch("(%-?%d+)=([%d:,]*)") do recipes[tonumber(id)] = re end
        local d = DB()
        d.crafters[sender] = d.crafters[sender] or {}
        local c = d.crafters[sender][prof] or {}
        c.recipes, c.hash, c.t = recipes, hash, time()
        d.crafters[sender][prof] = c
        if WP.RefreshOrders then WP.RefreshOrders() end
    end
end

local function OnMessage(msg, channel, sender)
    local d = DB()
    local kind, rest = msg:match("^(%u)|(.*)$")
    if kind == "H" and channel == "GUILD" then
        -- a member's profession hash: ask for the list when ours is older
        local prof, rank, max, hash = rest:match("^(.-)|(%d+)|(%d+)|(%x+)$")
        if prof then
            d.crafters[sender] = d.crafters[sender] or {}
            local c = d.crafters[sender][prof] or {}
            c.rank, c.max = tonumber(rank), tonumber(max)
            d.crafters[sender][prof] = c
            if c.hash ~= hash then Send("W|" .. prof, "WHISPER", sender) end
        end
    elseif kind == "W" then
        SendRecipes(rest)
    elseif kind == "P" and channel == "GUILD" then
        local key, i, n, chunk = rest:match("^(.-)|(%d+)|(%d+)|(.*)$")
        if key then
            i, n = tonumber(i), tonumber(n)
            local id = sender .. key
            local now = GetTime()
            for k, p in pairs(parts) do if now - (p.t or now) > 120 then parts[k] = nil end end
            parts[id] = parts[id] or {}
            parts[id].t = now
            parts[id][i] = chunk
            local all = true
            for k = 1, n do if not parts[id][k] then all = false; break end end
            if all then
                local payload = table.concat(parts[id], "", 1, n)
                parts[id] = nil
                OnPayload(sender, key, payload)
            end
        end
    elseif kind == "O" and channel == "GUILD" then
        local o = Parse(rest)
        if o and Allowed(o, sender) then
            local merged, changed = Merge(o)
            if changed then O.Notify(merged) end
            if WP.RefreshOrders then WP.RefreshOrders() end
        end
    elseif kind == "S" and channel == "GUILD" then
        -- someone just logged in: resend the running orders I published or I am crafting
        local me = Me()
        for _, o in pairs(d.list) do
            if (o.from == me and o.status == "open") or ((o.from == me or o.by == me) and Running(o)) then Broadcast(o) end
        end
    end
end

-- At login: forget orders finished or expired more than a week ago, and crafters gone quiet for a month.
local function Prune()
    local d = DB()
    local now = time()
    for id, o in pairs(d.list) do
        local done = (STATUS_RANK[o.status] or 0) >= 4 or (o.status == "open" and (o.expires or 0) < now)
        if done and (o.expires or 0) < now - 7 * 86400 then d.list[id] = nil; if d.hidden then d.hidden[id] = nil end end
    end
    for name, profs in pairs(d.crafters) do
        local recent = false
        for _, p in pairs(profs) do if (p.t or now) > now - 30 * 86400 then recent = true end end
        if not recent then d.crafters[name] = nil end
    end
end

-- One chat line when an order concerns you.
function O.Notify(o)
    if WP.ModuleOn and not WP.ModuleOn("orders") then return end
    local me = Me()
    local name = O.Name(o.item)
    if o.status == "open" and o.from ~= me and (o.to == me or (not o.to and O.CanCraft(me, o.item))) then
        WP.Print(string.format(L("Nouvelle commande de %s : %s ×%d (%s)."), o.from, name, o.qty or 1, S.Money((o.fee or 0) + (o.tip or 0))))
    elseif o.from == me and o.status == "accepted" then
        WP.Print(string.format(L("%s a accepté ta commande : %s ×%d."), o.by or "?", name, o.qty or 1))
    elseif o.from == me and o.status == "declined" then
        WP.Print(string.format(L("%s a refusé ta commande (%s)."), o.by or "?", o.reason or "?"))
    elseif o.from == me and o.status == "crafted" then
        WP.Print(string.format(L("%s a fabriqué ta commande : %s ×%d. Elle arrive par la poste."), o.by or "?", name, o.qty or 1))
    end
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("CHAT_MSG_ADDON")
f:RegisterEvent("TRADE_SKILL_SHOW")
f:RegisterEvent("TRADE_SKILL_UPDATE")
pcall(f.RegisterEvent, f, "CRAFT_SHOW")
pcall(f.RegisterEvent, f, "CRAFT_UPDATE")
f:RegisterEvent("MAIL_INBOX_UPDATE")
f:RegisterEvent("MAIL_CLOSED")
f:SetScript("OnEvent", function(_, e, prefix, msg, channel, sender)
    if not WLWritsDB then return end
    if e == "PLAYER_LOGIN" then
        pcall(Prune)
        C_Timer.After(20, function()
            O.Announce()
            Guild("S|")   -- ask the others to resend their running orders
        end)
    elseif e == "TRADE_SKILL_SHOW" or e == "TRADE_SKILL_UPDATE" or e == "CRAFT_SHOW" or e == "CRAFT_UPDATE" then
        QueueRead()
    elseif e == "MAIL_INBOX_UPDATE" then
        inboxReady = true
        ScanInbox()
        if WP.RefreshOrders then WP.RefreshOrders() end
    elseif e == "MAIL_CLOSED" then
        inboxReady = false
    elseif prefix == PREFIX and type(msg) == "string" and sender then
        local who = Short(sender)
        if who == Me() then return end
        if channel ~= "GUILD" and channel ~= "WHISPER" then return end
        OnMessage(msg, channel, who)
    end
end)
