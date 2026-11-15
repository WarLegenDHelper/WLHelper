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
-- Only item IDs, counts, prices, names of guild members, the note, and for a request with no item
-- its short title and profession travel. Nothing else.
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
    ["Nouvelle commande de %s : %s ×%d, %s. Tape /wlh orders, onglet Pour moi, pour l'accepter."] =
        "New order from %s: %s ×%d, %s. Type /wlh orders, For me tab, to accept it.",
    ["Nouvelle demande de %s : %s ×%d (%s), %s. Tape /wlh orders, onglet Pour moi, pour l'accepter."] =
        "New request from %s: %s ×%d (%s), %s. Type /wlh orders, For me tab, to accept it.",
    ["Nouvelle commande de %s : %s ×%d"] = "New order from %s: %s ×%d",
    ["Nouvelle demande de %s : %s ×%d"] = "New request from %s: %s ×%d",
    ["%s de commission"] = "%s fee",
    ["sans commission"] = "no fee",
    ["%s a accepté ta commande : %s ×%d."] = "%s accepted your order: %s ×%d.",
    ["%s a refusé ta commande de %s (%s). Tape /wlh orders, onglet Mes commandes, puis clique sur Commander à nouveau pour la proposer à toute la guilde."] =
        "%s declined your order for %s (%s). Type /wlh orders, My orders tab, then click Order again to offer it to the whole guild.",
    ["%s a fabriqué ta commande : %s ×%d. Elle t'arrive par la poste, contre-remboursement s'il y a une commission, ou en échange."] =
        "%s crafted your order: %s ×%d. It comes by mail, cash on delivery if there is a fee, or by trade.",
    ["Tu as reçu ta commande : %s ×%d de %s. Tape /wlh orders, onglet Mes commandes, puis clique sur Remercier pour lui donner une étoile."] =
        "You received your order: %s ×%d from %s. Type /wlh orders, My orders tab, then click Thank to give them a star.",
    ["%s t'a livré %s. Tape /wlh orders, onglet Mes commandes, puis clique sur Remercier pour lui donner une étoile."] =
        "%s delivered %s to you. Type /wlh orders, My orders tab, then click Thank to give them a star.",
    ["Commande WL : %s ×%d"] = "WL order: %s ×%d",
    ["Commission trop basse"] = "Commission too low",
    ["Pas les composants"] = "Missing reagents",
    ["Pas le temps"] = "No time",
    ["Recharge en cours"] = "On cooldown",
    ["Autre"] = "Other",
    ["L'onglet Envoyer n'est pas ouvert : ouvre-le dans la boîte aux lettres, puis reclique."] =
        "The Send tab is not open: open it in the mailbox, then click again.",
    ["Message de %s sur la commande %s : « %s ». Tape /wlh orders pour répondre."] =
        "Message from %s about the order %s: \"%s\". Type /wlh orders to reply.",
    ["il t'en manque %d"] = "%d missing",
    ["Envoie-lui par la poste ou en échange : %s. À la boîte aux lettres, l'addon remplit le courrier pour toi."] =
        "Send them by mail or trade: %s. At the mailbox, the addon fills in the mail for you.",
    ["Commande fabriquée : %s ×%d pour %s. Livre-la par la poste ou en échange."] = "Order crafted: %s ×%d for %s. Deliver it by mail or trade.",
    ["Composants remis à %s pour %s."] = "Reagents handed to %s for %s.",
    ["Commande livrée à %s : %s."] = "Order delivered to %s: %s.",
    ["%s te remercie pour sa commande."] = "%s thanks you for their order.",
    ["Contre-remboursement impossible sans objet joint : joins l'objet, ou demande %s à %s en échange."] =
        "Cash on delivery needs an attached item: attach it, or ask %s from %s by trade.",
    ["métier inconnu"] = "profession unknown",
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
-- "Name-Realm" or "Name Realm": the name alone
local function Short(n) return n and (n:gsub("[%- ].*$", "")) end

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
-- The modern profession API (C_TradeSkillUI, what this client uses): every learned recipe with what
-- it makes (item ID, or the recipe's spell as a negative number for an enchant) and its reagents.
local function ReadModern(recipes)
    local T = C_TradeSkillUI
    if (T.IsTradeSkillLinked and T.IsTradeSkillLinked()) or (T.IsTradeSkillGuild and T.IsTradeSkillGuild()) then return end
    local base = T.GetBaseProfessionInfo and T.GetBaseProfessionInfo()
    local prof = base and base.professionName
    if not prof or prof == "" then return end
    for _, id in ipairs(T.GetAllRecipeIDs() or {}) do
        local info = T.GetRecipeInfo(id)
        if info and info.learned then
            local sch = T.GetRecipeSchematic and T.GetRecipeSchematic(id, false)
            local reagents = {}
            for _, slot in ipairs(sch and sch.reagentSlotSchematics or {}) do
                local basic = not Enum.CraftingReagentType or slot.reagentType == Enum.CraftingReagentType.Basic
                local r = slot.reagents and slot.reagents[1]
                if basic and r and r.itemID then reagents[#reagents + 1] = { r.itemID, slot.quantityRequired or 1 } end
            end
            local out = sch and sch.outputItemID
            recipes[(out and out > 0) and out or -id] = Encode(reagents)
        end
    end
    return prof, base.skillLevel, base.maxSkillLevel
end

local function ReadProfession()
    local prof, rank, max
    local recipes = {}
    if C_TradeSkillUI and C_TradeSkillUI.GetAllRecipeIDs then
        local ok, p, r, m = pcall(ReadModern, recipes)
        if ok then prof, rank, max = p, r, m end
    end
    if prof then
        -- read by the modern API
    elseif GetTradeSkillLine and GetNumTradeSkills and (GetNumTradeSkills() or 0) > 0 then
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
-- Your recipes as Mastercraft already knows them (its saved scans of your profession windows), so
-- the guild sees them without you reopening each window. Only fills what WL Helper has not read itself.
local function ProfessionRanks()
    local out = {}
    if GetProfessions and GetProfessionInfo then
        local list = { pcall(GetProfessions) }
        for i = 2, #list do
            local idx = list[i]
            if idx then
                local ok, name, _, rank, max = pcall(GetProfessionInfo, idx)
                if ok and name then out[name] = { rank, max } end
            end
        end
    end
    return out
end
function O.ImportFromMastercraft(quiet)
    local db = MastercraftDB and MastercraftDB.recipes
    local mine = db and UnitGUID and db[UnitGUID("player")]
    if type(mine) ~= "table" then return false end
    local d, ranks, changed = DB(), ProfessionRanks(), false
    for prof, p in pairs(mine) do
        -- an entry with no recipe yet (made by ReadProfessionList) has not been read: fill it
        local cur = d.mine[prof]
        if type(p) == "table" and type(p.list) == "table" and (not cur or not next(cur.recipes or {})) then
            local recipes = {}
            for _, r in ipairs(p.list) do
                if type(r) == "table" and r.learned ~= false and (r.output or r.id) then
                    local reagents = {}
                    for _, g in ipairs(r.reagents or {}) do
                        if g.itemID then reagents[#reagents + 1] = { g.itemID, g.qty or 1 } end
                    end
                    local key = (type(r.output) == "number" and r.output > 0) and r.output or (type(r.id) == "number" and -r.id)
                    if key then recipes[key] = Encode(reagents) end
                end
            end
            if next(recipes) then
                local rk = ranks[prof] or {}
                d.mine[prof] = { rank = (cur and cur.rank ~= 0 and cur.rank) or rk[1] or 0, max = (cur and cur.max ~= 0 and cur.max) or rk[2] or 0,
                    recipes = recipes, hash = Hash(recipes), from = "Mastercraft" }
                changed = true
            end
        end
    end
    if changed and not quiet then O.Announce() end
    return changed
end

-- Your professions and their level, straight from the game (no profession window needed): the guild
-- sees who crafts what even before the recipe lists arrive.
function O.ReadProfessionList(quiet)
    local d, changed = DB(), false
    for prof, rk in pairs(ProfessionRanks()) do
        local p = d.mine[prof]
        if not p then
            d.mine[prof] = { rank = rk[1] or 0, max = rk[2] or 0, recipes = {}, hash = "0" }
            changed = true
        elseif p.rank ~= rk[1] then
            p.rank, p.max = rk[1] or p.rank, rk[2] or p.max
            changed = true
        end
    end
    if changed and not quiet then O.Announce() end
end

local readQueued = false
local function QueueRead()
    if readQueued then return end
    readQueued = true
    C_Timer.After(1, function() readQueued = false; ReadProfession() end)
end

-- My professions' hashes to the guild: those with an older copy will ask for the list.
local announcedAt = 0
function O.Announce(throttled)
    if WLWritsDB.ordersShare == false then return end
    if throttled and GetTime() - announcedAt < 30 then return end
    announcedAt = GetTime()
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

-- An item's name, or an enchant's (kept as a negative spell ID). Given an order, its item's name,
-- or its title when it asks for something with no known item.
function O.Name(id)
    if type(id) == "table" then
        local o = id
        if o.item and o.item ~= 0 then return O.Name(o.item) end
        return (o.title and o.title ~= "") and o.title or "?"
    end
    if not id or id == 0 then return "?" end
    if id > 0 then return WP.ItemName(id) or ("item " .. id) end
    local n = (C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(-id)) or (GetSpellInfo and GetSpellInfo(-id))
    return n or "?"
end

-- ---------------------------------------------------------------- orders
local function NewID() return Me() .. "-" .. time() .. "-" .. math.random(100, 999) end

-- order = { id, from, to (nil = guild), item, qty, give = "id:n,..." (customer), crafter = "id:n,..."
--           (crafter provides), fee (copper), tip, paid (upfront copper), note, expires, status, by, reason,
--           title (what is asked when no item is known), prof (English profession key, "" = unknown;
--           nil on an order made from a recipe: then only its recipe decides who is told) }
--
-- The fields go in this order, separated by "~". title and prof come AFTER the note, never before:
-- a copy older than them reads the first 15 positions and ignores the rest, so it still reads the
-- note where it always was (inserting them before the note would make it read the title as the
-- note and lose the real one). The note never holds a "~" (every field is cleaned), so being last
-- was never needed to parse it, only to shorten it first: NOTE_AT names its place.
-- An older copy does not know the title: for an order with no item, the title also goes at the front
-- of the note on the wire ("title - note"), so its crafters can read what is asked. Parse and Merge
-- take that prefix off again. An older copy that sends the order back (accepting it) drops title
-- and prof: Merge keeps the ones we had.
local FIELDS = { "id", "from", "to", "item", "qty", "give", "crafter", "fee", "tip", "paid", "expires", "status", "by", "reason", "note",
    "title", "prof" }
local NOTE_AT, TITLE_AT = 15, 16
local NUMERIC = { qty = true, fee = true, tip = true, paid = true, expires = true, item = true }

-- A request's title: one short line with none of the wire's separators, at most 40 bytes (whole
-- UTF-8 characters).
local function Utf8Cut(t, max)
    if #t <= max then return t end
    t = t:sub(1, max)
    while #t > 0 and t:byte(#t) >= 0x80 and t:byte(#t) < 0xC0 do t = t:sub(1, -2) end
    if #t > 0 and t:byte(#t) >= 0xC0 then t = t:sub(1, -2) end
    return t
end
function O.CleanTitle(t)
    t = tostring(t or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|H.-|h", ""):gsub("|h", "")
    t = t:gsub("[|~;%c]", " "):gsub("%s+", " "):gsub("^ ", ""):gsub(" $", "")
    t = Utf8Cut(t, 40)
    -- " - " separates the title from the note on the wire: never inside a title, nor a dash at its end
    local n
    repeat t, n = t:gsub("%s+%-%s+", " ") until n == 0
    repeat t, n = t:gsub("%s+%-+$", "") until n == 0
    t = t:gsub(" $", "")
    return t
end

-- "title - note" on the wire back to the note alone
local function StripTitle(o)
    local t, n = o.title, o.note
    if not (t and t ~= "" and n and (o.item or 0) == 0) then return end
    if n == t then o.note = nil
    elseif n:sub(1, #t + 3) == t .. " - " then
        n = n:sub(#t + 4)
        o.note = n ~= "" and n or nil
    end
end
O.StripTitle = StripTitle

-- "O|" + fields must fit in one 255-byte message: the customer's note is shortened (whole UTF-8
-- characters), never the "title - " in front of it; then, if ever needed, the title.
-- The title of an item-less request travels once: in front of the note, with TITLE_MARK in its own
-- field to say so (Parse reads it back from the note: the part before the first " - ").
local MAXMSG = 250
local TITLE_MARK = "^"
local function CutLast(v) return (v:gsub("[%z\1-\127\192-\255][\128-\191]*$", "")) end
local function Serialize(o)
    local t = {}
    local title = (o.item or 0) == 0 and o.title and o.title ~= "" and o.title:gsub("[|;~]", " ") or nil
    for i, k in ipairs(FIELDS) do
        local v = o[k]
        if v == nil then v = "" end
        if k == "prof" and v == "" and o.prof then v = "*" end   -- "" = unknown, kept apart from "no field"
        if k == "item" and v == 0 then v = "" end
        v = (tostring(v):gsub("[|;~]", " "))
        if title and k == "note" then v = title .. ((v ~= "") and (" - " .. v) or "") end
        if title and k == "title" then v = TITLE_MARK end
        t[i] = v
    end
    local s = table.concat(t, "~")
    if title then
        -- the customer's own words first, down to "title - "; then that separator; then the title
        local keep = #title + 3
        while #s + 2 > MAXMSG and #t[NOTE_AT] > keep do
            t[NOTE_AT] = CutLast(t[NOTE_AT])
            s = table.concat(t, "~")
        end
        if #t[NOTE_AT] < keep then t[NOTE_AT] = title end   -- a cut ending inside "title - "
        if #s + 2 > MAXMSG then t[NOTE_AT] = title; s = table.concat(t, "~") end
        while #s + 2 > MAXMSG and #t[NOTE_AT] > 1 do
            t[NOTE_AT] = CutLast(t[NOTE_AT])
            s = table.concat(t, "~")
        end
        s = table.concat(t, "~")
    else
        for _, at in ipairs({ NOTE_AT, TITLE_AT }) do
            while #s + 2 > MAXMSG and t[at] ~= "" do
                t[at] = CutLast(t[at])
                s = table.concat(t, "~")
            end
        end
    end
    return s
end
local function Parse(s)
    local o, i = {}, 0
    for v in (s .. "~"):gmatch("(.-)~") do
        i = i + 1
        local k = FIELDS[i]
        if k and v ~= "" then o[k] = NUMERIC[k] and tonumber(v) or v end
    end
    if o.prof == "*" then o.prof = "" end
    if o.title == TITLE_MARK then
        local n = o.note or ""
        local at = n:find(" - ", 1, true)
        if at then o.title, o.note = n:sub(1, at - 1), n:sub(at + 3)
        else o.title, o.note = n, nil end
        if o.title == "" then o.title = nil end
        if o.note == "" then o.note = nil end
    else
        StripTitle(o)
    end
    return o.id and o
end
O.Serialize, O.Parse = Serialize, Parse

local STATUS_RANK = { open = 1, accepted = 2, crafted = 3, delivered = 4, declined = 5, cancelled = 5, expired = 5 }

-- Merges what another copy says about an order; a status never goes back. The wire fields are
-- copied into our copy, so what only we know (got, gotMoney, sentGive, snapshots) stays.
local function LogStep(o, status, by)
    o.log = o.log or {}
    local last = o.log[#o.log]
    if last and last.s == status then return end
    o.log[#o.log + 1] = { s = status, by = by, t = time() }
    while #o.log > 12 do table.remove(o.log, 1) end
end
O.LogStep = LogStep

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
    if cur.status ~= o.status then LogStep(cur, o.status, o.status == "open" and o.from or o.by or o.from) end
    local tip = math.max(cur.tip or 0, o.tip or 0)
    for _, k in ipairs(FIELDS) do
        -- title and prof: an older copy sends the order back without them, keep ours
        if k == "title" or k == "prof" then cur[k] = o[k] or cur[k] else cur[k] = o[k] end
    end
    StripTitle(cur)
    if tip > 0 then cur.tip = tip end
    -- my order was just crafted: what my bags hold now, so the item arriving marks it delivered
    if changed and cur.status == "crafted" and cur.from == Me() and (cur.item or 0) > 0 and not cur.custBase then
        local count = (C_Item and C_Item.GetItemCount) or GetItemCount
        cur.custBase = count and (count(cur.item) or 0) or nil
    end
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
    if order.item == 0 then order.item = nil end
    -- a title only for what has no item; it never holds the wire's separators
    if order.item then order.title = nil
    else
        order.title = O.CleanTitle(order.title)
        if order.title == "" then order.title = nil end
    end
    LogStep(order, "open", order.from)
    Merge(order)
    Broadcast(order)
    if WP.RefreshOrders then WP.RefreshOrders() end
    return order
end

local function SetStatus(o, status, extra)
    LogStep(o, status, (extra and extra.by) or (status == "cancelled" and o.from) or o.by or Me())
    o.status = status
    for k, v in pairs(extra or {}) do o[k] = v end
    Merge(o)
    Broadcast(o)
    if WP.RefreshOrders then WP.RefreshOrders() end
end
function O.Accept(o)
    if o.status ~= "open" then return end
    local count = (C_Item and C_Item.GetItemCount) or GetItemCount
    o.baseCount = (o.item and o.item > 0 and count) and (count(o.item) or 0) or nil
    SetStatus(o, "accepted", { by = Me() })
end
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

-- A message on an order, between its customer and its crafter (anyone of the guild sees it go by,
-- only the two of them keep it). At most 120 characters.
local function CleanText(t)
    t = tostring(t or ""):gsub("[|~\n]", " ")
    if #t > 120 then
        t = t:sub(1, 120)
        while #t > 0 and t:byte(#t) >= 0x80 and t:byte(#t) < 0xC0 do t = t:sub(1, -2) end
        if #t > 0 and t:byte(#t) >= 0xC0 then t = t:sub(1, -2) end
    end
    return t
end
local function AddMessage(o, from, text)
    o.msgs = o.msgs or {}
    o.msgs[#o.msgs + 1] = { from = from, text = text, t = time() }
    while #o.msgs > 20 do table.remove(o.msgs, 1) end
end
function O.Say(o, text)
    text = CleanText(text)
    if text == "" then return end
    AddMessage(o, Me(), text)
    Guild("M|" .. o.id .. "|" .. text)
    if WP.RefreshOrders then WP.RefreshOrders() end
end

-- After delivery the customer can thank the crafter: a star on their name for the whole guild.
function O.Thank(o)
    if o.from ~= Me() or not o.by or o.thanked then return end
    o.thanked = true
    local d = DB(); d.stars = d.stars or {}
    d.stars[o.by] = d.stars[o.by] or {}
    d.stars[o.by][o.id] = true
    Guild("V|" .. o.id .. "|" .. o.by)
    if WP.RefreshOrders then WP.RefreshOrders() end
end
function O.Stars(name)
    local n = 0
    for _ in pairs((DB().stars or {})[name] or {}) do n = n + 1 end
    return n
end

-- The board: every open order of the guild you could take (to the whole guild or to you), not yours.
-- canOnly: only what your shared recipes make.
function O.Board(canOnly)
    local d, me, now, out = DB(), Me(), time(), {}
    for _, o in pairs(d.list) do
        if o.status == "open" and (o.expires or 0) >= now and o.from ~= me and (not o.to or o.to == me)
            and not (d.hidden and d.hidden[o.id]) and (not canOnly or O.CanServe(me, o)) then
            out[#out + 1] = o
        end
    end
    table.sort(out, function(a, b) return (a.expires or 0) > (b.expires or 0) end)
    return out
end

-- ---------------------------------------------------------------- who could make it
-- Without a shared recipe, the kind of item tells the profession: a potion is alchemy, cloth armour
-- tailoring, leather armour leatherworking, plate blacksmithing, food cooking, a bandage first aid...
-- Keys are English profession names, as the game gives them on an English client.
local PROF_NAMES = {
    Alchemy = { "Alchemy", "Alchimie" }, Blacksmithing = { "Blacksmithing", "Forge" }, Enchanting = { "Enchanting", "Enchantement" },
    Engineering = { "Engineering", "Ingénierie" }, Leatherworking = { "Leatherworking", "Travail du cuir" }, Tailoring = { "Tailoring", "Couture" },
    Cooking = { "Cooking", "Cuisine" }, ["First Aid"] = { "First Aid", "Secourisme" }, Mining = { "Mining", "Minage" },
}
local function SameProf(name, key)
    for _, n in ipairs(PROF_NAMES[key] or {}) do if n:lower() == tostring(name):lower() then return true end end
    return false
end
function O.LikelyProfs(item)
    local GetInfo = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
    if not (GetInfo and item and item > 0) then return {} end
    local _, _, _, equipLoc, _, classID, subID = GetInfo(item)
    if classID == 0 then        -- consumables
        if subID == 1 or subID == 2 or subID == 3 then return { "Alchemy" } end
        if subID == 5 then return { "Cooking" } end
        if subID == 7 then return { "First Aid" } end
        if subID == 6 then return { "Leatherworking", "Enchanting", "Alchemy" } end
        return { "Alchemy", "Engineering", "Cooking" }
    elseif classID == 2 then    -- weapons: guns and bows from engineering and leatherworking-free smiths
        if subID == 3 or subID == 18 then return { "Engineering" } end
        return { "Blacksmithing" }
    elseif classID == 4 then    -- armour by its material
        if subID == 1 then return equipLoc == "INVTYPE_CLOAK" and { "Tailoring", "Leatherworking" } or { "Tailoring" } end
        if subID == 2 then return { "Leatherworking" } end
        if subID == 3 then return { "Blacksmithing", "Leatherworking" } end
        if subID == 4 or subID == 6 then return { "Blacksmithing" } end
        return { "Engineering", "Blacksmithing", "Tailoring" }
    elseif classID == 1 then return { "Tailoring", "Leatherworking" }      -- bags
    elseif classID == 7 then    -- trade goods
        if subID == 1 or subID == 2 or subID == 3 then return { "Engineering" } end
        if subID == 5 then return { "Tailoring" } end
        if subID == 6 then return { "Leatherworking" } end
        if subID == 7 then return { "Mining", "Blacksmithing" } end
        if subID == 8 then return { "Cooking" } end
        if subID == 12 then return { "Enchanting" } end
    end
    return {}
end
O.PROF_KEYS = { "Alchemy", "Blacksmithing", "Enchanting", "Engineering", "Leatherworking", "Tailoring", "Cooking", "First Aid", "Mining" }
-- a profession name as the game gives it (either language) to its English key, or nil
function O.ProfKeyOf(name)
    if not name then return nil end
    for key in pairs(PROF_NAMES) do if SameProf(name, key) then return key end end
end
-- does a declared profession (name in either language) match a key; key "" = any profession
local function ProfMatches(name, key)
    if key == "" then return true end
    return SameProf(name, key) or tostring(name):lower() == tostring(key):lower()
end
O.ProfMatches = ProfMatches
-- a profession key's name in the player's language ("" = unknown)
function O.ProfName(key)
    if not key or key == "" then return L("métier inconnu") end
    local n = PROF_NAMES[key]
    if not n then return key end
    return (root.lang == "en") and n[1] or n[2]
end

-- Members whose declared profession may make this item: { { name, prof, rank, online, exact } }.
-- Exact ones (a shared recipe) first, then the ones whose profession fits, best rank first.
-- prof (optional): the profession asked for (English key, "" = any profession) instead of the ones
-- the kind of item tells; item may be nil (a request with only a title).
function O.Possible(item, prof)
    local out, seen = {}, {}
    if item and item ~= 0 then
        for _, c in ipairs(O.Crafters(item)) do c.exact = true; out[#out + 1] = c; seen[c.name] = true end
    end
    local online = O.OnlineGuild()
    local profs
    if prof == "" then profs = { "" } elseif prof then profs = { prof } else profs = O.LikelyProfs(item) end
    for name, list in pairs(DB().crafters) do
        if not seen[name] then
            for pname, p in pairs(list) do
                for _, key in ipairs(profs) do
                    if ProfMatches(pname, key) and not seen[name] then
                        seen[name] = true
                        out[#out + 1] = { name = name, prof = pname, rank = p.rank or 0, online = online[name] or false }
                    end
                end
            end
        end
    end
    table.sort(out, function(a, b)
        if (a.exact or false) ~= (b.exact or false) then return a.exact or false end
        if a.online ~= b.online then return a.online end
        return a.rank > b.rank
    end)
    return out
end

-- What the customer still has to send for an order: { { id, need, have, bank } }, have = in bags and
-- bank, bank = the part of it in the bank
function O.ToSend(o)
    local out = {}
    for _, r in ipairs(O.Decode(o.give)) do
        local need = r[2] * (o.qty or 1)
        out[#out + 1] = { id = r[1], need = need, have = WP.OwnedCount and WP.OwnedCount(r[1]) or 0,
            bank = WP.InBank and WP.InBank(r[1]) or 0 }
    end
    return out
end

-- Orders as lists: mine (I asked), for me (I may craft), each sorted newest first.
function O.Lists()
    local d = DB()
    local me = Me()
    local mine, forMe = {}, {}
    local now = time()
    for _, o in pairs(d.list) do
        if o.status == "open" and o.expires and o.expires < now then o.status = "expired" end
        if o.from == me then mine[#mine + 1] = o
        elseif o.by == me then forMe[#forMe + 1] = o   -- taken by me, even from the board's full list
        elseif (o.to == me or (not o.to and O.CanServe(me, o))) and not (d.hidden and d.hidden[o.id]) then
            if o.status == "open" then forMe[#forMe + 1] = o end
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
-- May this member take this order: he has its recipe, or it is a request (o.prof set) for a
-- profession he declared ("" = any profession: everyone who has one).
function O.CanServe(name, o)
    if o.item and o.item ~= 0 and O.CanCraft(name, o.item) then return true end
    if o.prof == nil then return false end
    local profs = (name == Me()) and DB().mine or DB().crafters[name] or {}
    for pname in pairs(profs) do if ProfMatches(pname, o.prof) then return true end end
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

-- Who of the guild is online, and each member's class (file name, "WARRIOR"...), read together
local onlineCache, classCache, onlineAt = {}, {}, 0
function O.OnlineGuild()
    if GetTime() - onlineAt < 30 then return onlineCache end
    onlineCache, classCache, onlineAt = {}, {}, GetTime()
    if not (IsInGuild and IsInGuild() and GetNumGuildMembers and GetGuildRosterInfo) then return onlineCache end
    for i = 1, (GetNumGuildMembers() or 0) do
        local name, _, _, _, _, _, _, _, online, _, cls = GetGuildRosterInfo(i)
        if name then
            onlineCache[Short(name)] = online and true or false
            if cls then classCache[Short(name)] = cls end
        end
    end
    return onlineCache
end
function O.ClassOf(name)
    if name == Me() then return select(2, UnitClass("player")) end
    O.OnlineGuild()
    return classCache[name]
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
    if not (SendMailFrame and SendMailFrame:IsShown()) then WP.Print(L("L'onglet Envoyer n'est pas ouvert : ouvre-le dans la boîte aux lettres, puis reclique.")); return end
    local to = kind == "give" and (o.by or o.to) or o.from
    if not to then return end
    if SendMailNameEditBox then SendMailNameEditBox:SetText(to) end
    -- the tag goes first: the subject is cut at 64 characters, and a cut tag no longer matches
    if SendMailSubjectEditBox then SendMailSubjectEditBox:SetText(O.Tag(o) .. " " .. string.format(L("Commande WL : %s ×%d"), O.Name(o), o.qty or 1)) end
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
                WP.Print(string.format(L("Contre-remboursement impossible sans objet joint : joins l'objet, ou demande %s à %s en échange."), S.Money(cod), o.from))
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

local askedW
local function OnMessage(msg, channel, sender)
    local d = DB()
    local kind, rest = msg:match("^(%u)|(.*)$")
    if kind == "H" and channel == "GUILD" then
        -- a member's profession hash: ask for the list when ours is older
        local prof, rank, max, hash = rest:match("^(.-)|(%d+)|(%d+)|(%x+)$")
        if prof then
            d.crafters[sender] = d.crafters[sender] or {}
            local c = d.crafters[sender][prof] or {}
            c.rank, c.max, c.t = tonumber(rank), tonumber(max), time()   -- seen now, even if the list did not change
            d.crafters[sender][prof] = c
            -- ask for the list on the guild channel, naming its owner: no whisper (a whisper to a name
            -- without its realm fails with "No player named ..." for members of a connected realm).
            -- "0" = professions only, no recipe list to ask for.
            if c.hash ~= hash and hash ~= "0" then
                askedW = askedW or {}
                local k = sender .. "|" .. prof
                if not askedW[k] or GetTime() - askedW[k] > 60 then
                    askedW[k] = GetTime()
                    Guild("W|" .. prof .. "|" .. sender)
                end
            end
            if WP.RefreshOrders then WP.RefreshOrders() end
        end
    elseif kind == "W" then
        -- "W|prof|owner" on the guild (1.0.0-beta.29+): only the owner answers; "W|prof" by whisper
        -- from older copies: answered too (the list itself always goes on the guild channel)
        local prof, owner = rest:match("^(.-)|([^|]+)$")
        if prof then
            if owner == Me() then SendRecipes(prof) end
        else
            SendRecipes(rest)
        end
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
    elseif kind == "M" and channel == "GUILD" then
        -- a message on an order: kept when it is between its customer and its crafter, and I am one of them
        local id, text = rest:match("^([^|]+)|(.*)$")
        local o = id and d.list[id]
        if o and (sender == o.from or sender == o.by) and (Me() == o.from or Me() == o.by) then
            AddMessage(o, sender, CleanText(text))
            if WP.ModuleOn("orders") then
                WP.ordersPendingTab = (Me() == o.from) and "mine" or "recv"
                WP.Print(string.format(L("Message de %s sur la commande %s : « %s ». Tape /wlh orders pour répondre."), sender, O.Name(o), CleanText(text)))
            end
            if WP.RefreshOrders then WP.RefreshOrders() end
        end
    elseif kind == "V" and channel == "GUILD" then
        -- a thank-you: one star per delivered order, given by its customer only
        local id, crafter = rest:match("^([^|]+)|([^|]+)$")
        local o = id and d.list[id]
        if crafter and (not o or (o.from == sender and o.by == crafter)) then
            d.stars = d.stars or {}
            d.stars[crafter] = d.stars[crafter] or {}
            d.stars[crafter][id] = true
            if crafter == Me() and WP.ModuleOn("orders") then WP.Print(string.format(L("%s te remercie pour sa commande."), sender)) end
        end
    elseif kind == "Q" and channel == "GUILD" then
        -- someone asks who crafts what: my professions' hashes (they ask for the lists they lack)
        O.Announce(true)
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
        for _, p in pairs(profs) do if (p.t or 0) > now - 30 * 86400 then recent = true end end
        if not recent then d.crafters[name] = nil end
    end
end

-- Asks the guild for its crafters (at login and when the Orders window opens, once a minute at most):
-- each copy answers with its professions' hashes, and the lists we lack come by themselves.
local askedAt = -60
function O.AskRecipes()
    if GetTime() - askedAt < 60 then return end
    askedAt = GetTime()
    Guild("Q|")
end

-- The same line about the same order at most once per 30 s (an order can come back from several
-- copies); true when it printed. tab: the Orders tab the line sends to (/wlh orders opens it).
local said = {}
local function Say(msg, o, tab)
    local now = GetTime and GetTime() or 0
    local key = (o and o.id) and (o.id .. "|" .. tostring(o.status) .. "|" .. msg) or msg
    if said[key] and now - said[key] < 30 then return false end
    said[key] = now
    if tab then WP.ordersPendingTab = tab end
    WP.Print(msg)
    return true
end

-- One chat line when an order concerns you.
function O.Notify(o)
    if WP.ModuleOn and not WP.ModuleOn("orders") then return end
    local me = Me()
    local name = O.Name(o)
    -- a request (o.prof set) alerts everyone who declared its profession, or any profession when unknown
    if o.status == "open" and o.from ~= me and (o.to == me or (not o.to and O.CanServe(me, o))) then
        local money = (o.fee or 0) + (o.tip or 0)
        local fee = money > 0 and string.format(L("%s de commission"), S.Money(money)) or L("sans commission")
        local msg = o.prof and string.format(L("Nouvelle demande de %s : %s ×%d (%s), %s. Tape /wlh orders, onglet Pour moi, pour l'accepter."), o.from, name, o.qty or 1, O.ProfName(o.prof), fee)
            or string.format(L("Nouvelle commande de %s : %s ×%d, %s. Tape /wlh orders, onglet Pour moi, pour l'accepter."), o.from, name, o.qty or 1, fee)
        -- the banner and the sound only with a new chat line (not for each copy of the same order)
        if Say(msg, o, "recv") and WLWritsDB.ordersAlert ~= false then
            -- the centre of the screen: the short line only
            local short = o.prof and string.format(L("Nouvelle demande de %s : %s ×%d"), o.from, name, o.qty or 1)
                or string.format(L("Nouvelle commande de %s : %s ×%d"), o.from, name, o.qty or 1)
            if RaidNotice_AddMessage and RaidWarningFrame then RaidNotice_AddMessage(RaidWarningFrame, short, { r = 1, g = 0.82, b = 0.3 }) end
            if PlaySound and SOUNDKIT and SOUNDKIT.READY_CHECK then pcall(PlaySound, SOUNDKIT.READY_CHECK, "Master") end
        end
    elseif o.from == me and o.status == "accepted" then
        Say(string.format(L("%s a accepté ta commande : %s ×%d."), o.by or "?", name, o.qty or 1), o, "mine")
        local t = {}
        for _, g in ipairs(O.ToSend(o)) do t[#t + 1] = g.need .. "× " .. O.Name(g.id) .. (g.have < g.need and (" (" .. string.format(L("il t'en manque %d"), g.need - g.have) .. ")") or "") end
        if #t > 0 then Say(string.format(L("Envoie-lui par la poste ou en échange : %s. À la boîte aux lettres, l'addon remplit le courrier pour toi."), table.concat(t, ", ")), o) end
    elseif o.from == me and o.status == "declined" then
        Say(string.format(L("%s a refusé ta commande de %s (%s). Tape /wlh orders, onglet Mes commandes, puis clique sur Commander à nouveau pour la proposer à toute la guilde."), o.by or "?", name, L(o.reason or "Autre")), o, "mine")
    elseif o.from == me and o.status == "crafted" then
        Say(string.format(L("%s a fabriqué ta commande : %s ×%d. Elle t'arrive par la poste, contre-remboursement s'il y a une commission, ou en échange."), o.by or "?", name, o.qty or 1), o, "mine")
    elseif o.from == me and o.status == "delivered" and not o.thanked then
        Say(string.format(L("%s t'a livré %s. Tape /wlh orders, onglet Mes commandes, puis clique sur Remercier pour lui donner une étoile."), o.by or "?", name), o, "mine")
    end
end

-- ---------------------------------------------------------------- automatic steps
local function PrintReceived(o)
    WP.ordersPendingTab = "mine"
    WP.Print(string.format(L("Tu as reçu ta commande : %s ×%d de %s. Tape /wlh orders, onglet Mes commandes, puis clique sur Remercier pour lui donner une étoile."),
        O.Name(o), o.qty or 1, o.by or "?"))
end
-- The crafter made the order: the item shows up in their bags (more than when they accepted it).
-- The customer got it: the item shows up in their bags (more than when it was crafted).
local function CheckBags()
    local me = Me()
    local count = (C_Item and C_Item.GetItemCount) or GetItemCount
    if not count then return end
    for _, o in pairs(DB().list) do
        if o.by == me and o.status == "accepted" and o.item and o.item > 0 and o.baseCount then
            if (count(o.item) or 0) >= o.baseCount + (o.qty or 1) then
                O.Crafted(o)
                WP.Print(string.format(L("Commande fabriquée : %s ×%d pour %s. Livre-la par la poste ou en échange."), O.Name(o), o.qty or 1, o.from))
            end
        end
    end
    for _, o in pairs(DB().list) do
        if o.from == me and o.status == "crafted" and (o.item or 0) > 0 then
            if o.custBase == nil then
                o.custBase = count(o.item) or 0   -- first look: note it and wait for the item
            elseif (count(o.item) or 0) >= o.custBase + (o.qty or 1) then
                O.Delivered(o)
                PrintReceived(o)
            end
        end
    end
end

-- A trade with the other side of an order: what you gave decides the step (the customer's reagents
-- are sent; the crafter's item is delivered). Read when both sides accepted, applied when it completes.
local trade = {}
local function TradeItems(get)
    local out = {}
    for i = 1, 6 do
        local link = get and get(i)
        local id = link and tonumber(link:match("item:(%d+)"))
        if id then out[id] = true end
    end
    return out
end
local function TradeDone()
    local me, who, gave, got = Me(), trade.with, trade.gave or {}, trade.got or {}
    if not who then return end
    for _, o in pairs(DB().list) do
        -- the customer got the crafted item in this trade (an accepted order can also have its
        -- reagents handed over in the same trade, so this is checked on its own, after)
        local received = o.from == me and o.by == who and (o.status == "accepted" or o.status == "crafted")
            and (o.item or 0) > 0 and got[o.item]
        if o.from == me and o.by == who and o.status == "accepted" and not o.sentGive then
            for _, g in ipairs(O.Decode(o.give)) do
                if gave[g[1]] then o.sentGive = true; WP.Print(string.format(L("Composants remis à %s pour %s."), who, O.Name(o))); break end
            end
        elseif o.by == me and o.from == who and (o.status == "accepted" or o.status == "crafted") and (o.item or 0) > 0 and gave[o.item] then
            O.Delivered(o)
            WP.Print(string.format(L("Commande livrée à %s : %s."), who, O.Name(o)))
        end
        if received then O.Delivered(o); PrintReceived(o) end
    end
    if WP.RefreshOrders then WP.RefreshOrders() end
end
local tf = CreateFrame("Frame")
for _, e in ipairs({ "TRADE_SHOW", "TRADE_ACCEPT_UPDATE", "TRADE_CLOSED", "UI_INFO_MESSAGE", "BAG_UPDATE_DELAYED" }) do pcall(tf.RegisterEvent, tf, e) end
local craftQueued = false
tf:SetScript("OnEvent", function(_, e, a1, a2)
    if not (WLWritsDB and WP.ModuleOn("orders")) then return end
    if e == "TRADE_SHOW" then
        trade = { with = Short(UnitName("NPC") or "") }
    elseif e == "TRADE_ACCEPT_UPDATE" then
        trade.gave = TradeItems(GetTradePlayerItemLink)
        trade.got = TradeItems(GetTradeTargetItemLink)
    elseif e == "UI_INFO_MESSAGE" then
        local msg = type(a2) == "string" and a2 or a1
        if ERR_TRADE_COMPLETE and msg == ERR_TRADE_COMPLETE then TradeDone(); trade = {} end
    elseif e == "TRADE_CLOSED" then
        C_Timer.After(1, function() trade = {} end)
    elseif e == "BAG_UPDATE_DELAYED" and not craftQueued then
        craftQueued = true
        C_Timer.After(0.5, function()
            craftQueued = false
            CheckBags()
            -- counts on the order cards follow purchases and bank withdrawals
            if WP.RefreshOrders then WP.RefreshOrders() end
        end)
    end
end)

local f = CreateFrame("Frame")
pcall(f.RegisterEvent, f, "PLAYER_LOGIN")
pcall(f.RegisterEvent, f, "CHAT_MSG_ADDON")
pcall(f.RegisterEvent, f, "TRADE_SKILL_SHOW")
pcall(f.RegisterEvent, f, "TRADE_SKILL_UPDATE")
pcall(f.RegisterEvent, f, "TRADE_SKILL_LIST_UPDATE")
pcall(f.RegisterEvent, f, "TRADE_SKILL_DATA_SOURCE_CHANGED")
pcall(f.RegisterEvent, f, "CRAFT_SHOW")
pcall(f.RegisterEvent, f, "CRAFT_UPDATE")
pcall(f.RegisterEvent, f, "MAIL_INBOX_UPDATE")
pcall(f.RegisterEvent, f, "MAIL_CLOSED")
f:SetScript("OnEvent", function(_, e, prefix, msg, channel, sender)
    if not WLWritsDB then return end
    if e == "PLAYER_LOGIN" then
        pcall(Prune)
        C_Timer.After(20, function()
            -- read quietly, then announce once
            pcall(O.ImportFromMastercraft, true)
            pcall(O.ReadProfessionList, true)
            O.Announce()
            Guild("S|")   -- ask the others to resend their running orders
            O.AskRecipes()
        end)
    elseif e == "TRADE_SKILL_SHOW" or e == "TRADE_SKILL_UPDATE" or e == "TRADE_SKILL_LIST_UPDATE" or e == "TRADE_SKILL_DATA_SOURCE_CHANGED"
        or e == "CRAFT_SHOW" or e == "CRAFT_UPDATE" then
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
