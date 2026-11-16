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
-- the crafters' home (T-60): profile, presence, favourites, watched recipes, deliveries, search.
-- One table, filled further down, so the file keeps few top-level locals.
local K = {}
O._K = K   -- for the offline tests

ns.AddEnglish({
    ["Commandes"] = "Orders",
    ["%s a annulé sa commande : %s ×%d."] = "%s cancelled their order: %s ×%d.",
    ["%s a pris la commande %s avant toi : elle n'est plus pour toi."] = "%s took the order %s before you: it is no longer yours.",
    ["Nouvelle commande de %s : %s ×%d, %s."] = "New order from %s: %s ×%d, %s.",
    ["Nouvelle demande de %s : %s ×%d (%s), %s."] = "New request from %s: %s ×%d (%s), %s.",
    ["Voir la commande"] = "View the order",
    ["Répondre"] = "Reply",
    ["Nouvelle commande de %s : %s ×%d"] = "New order from %s: %s ×%d",
    ["Nouvelle demande de %s : %s ×%d"] = "New request from %s: %s ×%d",
    ["%s de commission"] = "%s fee",
    ["sans commission"] = "no fee",
    ["%s a accepté ta commande : %s ×%d."] = "%s accepted your order: %s ×%d.",
    ["%s a refusé ta commande de %s (%s)."] = "%s declined your order for %s (%s).",
    ["%s a fabriqué ta commande : %s ×%d. Elle t'arrive par la poste, contre-remboursement s'il y a une commission, ou en échange."] =
        "%s crafted your order: %s ×%d. It comes by mail, cash on delivery if there is a fee, or by trade.",
    ["Tu as reçu ta commande : %s ×%d de %s."] = "You received your order: %s ×%d from %s.",
    ["%s t'a livré %s."] = "%s delivered %s to you.",
    ["Commande WL : %s ×%d"] = "WL order: %s ×%d",
    ["Commission trop basse"] = "Commission too low",
    ["Pas les composants"] = "Missing reagents",
    ["Pas le temps"] = "No time",
    ["Recharge en cours"] = "On cooldown",
    ["Autre"] = "Other",
    ["L'onglet Envoyer n'est pas ouvert : ouvre-le dans la boîte aux lettres, puis reclique."] =
        "The Send tab is not open: open it in the mailbox, then click again.",
    ["Message de %s sur la commande %s : « %s »."] = "Message from %s about the order %s: \"%s\".",
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
    -- the crafters' home (T-60): alerts
    ["%s sait maintenant faire %s."] = "%s can now make %s.",
    ["%s est en ligne."] = "%s is online.",
    ["%s est hors ligne : ta commande l'attendra."] = "%s is offline: your order will wait for them.",
    ["%s sait maintenant faire %s. Tape /wlh orders pour le commander."] = "%s can now make %s. Type /wlh orders to order it.",
    ["%s est en ligne (%s)."] = "%s is online (%s).",
    ["Voir sa fiche"] = "Open profile",
    ["%s, ton artisan favori, est en ligne. Tape /wlh orders pour voir sa fiche."] =
        "%s, one of your favourite crafters, is online. Type /wlh orders to open their profile.",
    ["1 favori en ligne : %s."] = "1 favourite online: %s.",
    ["%d favoris en ligne : %s."] = "%d favourites online: %s.",
    ["%s est en ligne et sait faire %s."] = "%s is online and can make %s.",
    ["%s est en ligne et sait faire %s. Tape /wlh orders pour le commander."] = "%s is online and can make %s. Type /wlh orders to order it.",
    ["Et 1 autre alerte dans les Commandes."] = "And 1 more alert in Orders.",
    ["Et %d autres alertes dans les Commandes."] = "And %d more alerts in Orders.",
    ["Ouvrir"] = "Open",
    ["1 commande t'a attendu pendant le donjon."] = "1 order waited for you during the dungeon.",
    ["%d commandes t'ont attendu pendant le donjon."] = "%d orders waited for you during the dungeon.",
    ["Les voir"] = "See them",
    ["%s est en donjon : ta commande attend, tu es %s dans sa file."] = "%s is in a dungeon: your order is waiting, you are %s in line.",
    ["Utilise : "] = "Uses: ",
    -- T-80: "tell me when someone can make it" (the Request page)
    ["%s sait faire %s : tu peux le lui commander. Tape /wlh orders."] = "%s can make %s: you can order it from them. Type /wlh orders.",
    -- T-65: the item tooltip line
    ["Fabricable par 1 artisan de la guilde (en ligne)"] = "Craftable by 1 guild crafter (online)",
    ["Fabricable par 1 artisan de la guilde (hors ligne)"] = "Craftable by 1 guild crafter (offline)",
    ["Fabricable par %d artisans de la guilde (%d en ligne)"] = "Craftable by %d guild crafters (%d online)",
    ["Fabricable par %d artisans de la guilde (personne en ligne)"] = "Craftable by %d guild crafters (none online)",
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
-- a name from the network as the key its data is kept under: alone for my realm, "Name-Realm" for
-- another (a namesake never takes a member's entry); nil when secret or malformed
local function Key(n) if root.SenderKey then return root.SenderKey(n) end return n and Short(n) end

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
local function PumpOnce(Pump)
    local m = outbox[1]
    if not m then pumping = false; return end
    local now = GetTime()
    tokens = math.min(10, tokens + (now - tokensAt)); tokensAt = now
    if tokens < 1 then C_Timer.After(1 - tokens, Pump); return end
    local ok, r = false, nil
    if m[2] == "WHISPER" then
        -- a whisper only to a player still surely online (root.AddonWhisper checks it again)
        if root.AddonWhisper then ok = pcall(root.AddonWhisper, PREFIX, m[1], m[3]) end
    elseif SendRaw then ok, r = pcall(SendRaw, PREFIX, m[1], m[2], m[3]) end
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
-- A timer that fires at once (some stubs, some clients at 0 s) must not recurse: re-entry is
-- turned into a bounded loop, and past the bound the queue waits for the next Send.
local pumpDepth, pumpAgain = 0, false
local function Pump()
    if pumpDepth > 0 then pumpAgain = true; return end
    pumpDepth = 1
    local n = 0
    repeat
        pumpAgain = false; n = n + 1
        if not pcall(PumpOnce, Pump) then pumpAgain = false; pumping = false end
    until not pumpAgain or n >= 100
    if pumpAgain then pumping = false end
    pumpDepth = 0
end
-- a large recipe list is many parts (one a second): the cap only stops a runaway queue
local OUTBOX_MAX = 500
local function Send(msg, channel, target)
    if not channel then return end
    -- everything goes on the guild channel; a whisper (none today) only to a player surely online
    if channel == "WHISPER" and not (root.OnlineNow and root.OnlineNow(target)) then return end
    for _, m in ipairs(outbox) do if m[1] == msg and m[2] == channel and m[3] == target then return end end
    if #outbox >= OUTBOX_MAX then return end
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
    local ids = T.GetAllRecipeIDs() or {}
    -- right after switching professions the window can still hold the previous one's list: the
    -- first recipe must belong to the open profession, or the read waits (ReadProfession retries)
    if T.GetProfessionInfoByRecipeID and ids[1] and type(base.professionID) == "number" then
        local ok, pi = pcall(T.GetProfessionInfoByRecipeID, ids[1])
        if ok and type(pi) == "table" then
            local a, b = pi.professionID, pi.parentProfessionID
            if type(a) == "number" and a ~= base.professionID and b ~= base.professionID then return "stale" end
        end
    end
    for _, id in ipairs(ids) do
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
        if ok and p == "stale" then
            -- another profession's list still in the window: read again shortly (3 times at most)
            K.staleTries = (K.staleTries or 0) + 1
            if K.staleTries <= 3 and C_Timer and C_Timer.After then C_Timer.After(0.6, ReadProfession) else K.staleTries = 0 end
            return
        end
        K.staleTries = 0
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
    if throttled and GetTime() - announcedAt < 30 then return end
    announcedAt = GetTime()
    -- my crafter profile (status, note, counts) goes with it, recipes shared or not
    if K.SendA then pcall(K.SendA) end
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
-- the range of each number (item: an item ID, or an enchant's spell ID kept negative; money in copper)
local RANGE = { item = { -10000000, 10000000 }, qty = { 0, 10000 }, fee = { 0, 1e10 }, tip = { 0, 1e10 }, paid = { 0, 1e10 },
    expires = { 0, 4e9 } }
local function GoodNumber(k, v)
    local r = RANGE[k]
    return type(v) == "number" and v == v and v == math.floor(v) and v >= r[1] and v <= r[2]
end
O.GoodNumber = GoodNumber
-- an order as saved can be used: its numbers are numbers (older copies stored anything they got)
local function Sane(o)
    if type(o) ~= "table" or type(o.id) ~= "string" then return false end
    for k in pairs(NUMERIC) do
        if o[k] ~= nil and not GoodNumber(k, o[k]) then return false end
    end
    return true
end
O.Sane = Sane

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
        if k and v ~= "" then
            if NUMERIC[k] then
                local n = tonumber(v)
                if not GoodNumber(k, n) then return nil end
                o[k] = n
            else
                o[k] = v
            end
        end
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

local function MergeRaw(o)
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
-- every merge also feeds my recent orders and the weekly delivery counts (K.AfterMerge, below)
local function Merge(o)
    local cur, changed = MergeRaw(o)
    if K.AfterMerge and cur then pcall(K.AfterMerge, cur) end
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
    for id, o in pairs(d.list) do
        if not Sane(o) then d.list[id] = nil; o = nil end
        if o and o.status == "open" and o.expires and o.expires < now then o.status = "expired" end
        if not o then
        elseif o.from == me then mine[#mine + 1] = o
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
-- Each member also gets { level, class, zone, online, afk, lastOnline (seconds) } (O.Member).
local onlineCache, classCache, onlineAt = {}, {}, 0
function O.OnlineGuild(force)
    if not force and GetTime() - onlineAt < 30 then return onlineCache end
    onlineCache, classCache, onlineAt = {}, {}, GetTime()
    K.members = {}
    if not (IsInGuild and IsInGuild() and GetNumGuildMembers and GetGuildRosterInfo) then return onlineCache end
    for i = 1, (GetNumGuildMembers() or 0) do
        local name, _, _, level, _, zone, _, _, online, status, cls = GetGuildRosterInfo(i)
        local n = name and (Key(name) or Short(name))
        if n then
            onlineCache[n] = online and true or false
            if cls then classCache[n] = cls end
            -- status: 1/2 (or "<AFK>"/"<DND>") = away or busy
            local afk = (status == 1 or status == 2) or (type(status) == "string" and status ~= "")
            local m = { level = type(level) == "number" and level or nil, class = cls, zone = type(zone) == "string" and zone or nil,
                online = online and true or false, afk = afk and true or nil }
            if not online and GetGuildRosterLastOnline then
                local ok, y, mo, dd, hh = pcall(GetGuildRosterLastOnline, i)
                if ok and type(y) == "number" then
                    m.lastOnline = (((y * 365 + (mo or 0) * 30 + (dd or 0)) * 24) + (hh or 0)) * 3600
                end
            end
            K.members[n] = m
        end
    end
    return onlineCache
end
function O.Member(name)
    if name == Me() then return { level = UnitLevel and UnitLevel("player"), class = select(2, UnitClass("player")), online = true,
        zone = GetRealZoneText and GetRealZoneText() or nil } end
    O.OnlineGuild()
    return K.members and K.members[name] or nil
end
function O.ClassOf(name)
    if name == Me() then return select(2, UnitClass("player")) end
    O.OnlineGuild()
    return classCache[name]
end

-- ---------------------------------------------------------------- the item tooltip (T-65)
-- One line on an item's tooltip: "Fabricable par 3 artisans de la guilde (1 en ligne)", from the
-- shared recipe lists (exact recipes only, never a guess from the profession; me left out). No line
-- when nobody can make it. The names per item are cached until a list changes (O.ListsChanged);
-- who is online comes from O.OnlineGuild (itself read at most every 30 s).
-- Turned off with WLWritsDB.orders.tipCrafters = false (My crafter profile page).
local tipGen, tipCache, tipCacheGen = 0, {}, -1
function O.ListsChanged() tipGen = tipGen + 1 end
function O.TipCraftersOn() return DB().tipCrafters ~= false end
function O.SetTipCrafters(on) if on then DB().tipCrafters = nil else DB().tipCrafters = false end end
-- the guild members who have the recipe of this item (my own characters' lists aside: me excluded)
function O.TipCrafters(item)
    if tipCacheGen ~= tipGen then tipCache, tipCacheGen = {}, tipGen end
    local names = tipCache[item]
    if not names then
        names = {}
        local me = Me()
        for name, profs in pairs(DB().crafters) do
            if name ~= me then
                for _, p in pairs(profs) do
                    if type(p) == "table" and p.recipes and p.recipes[item] then names[#names + 1] = name; break end
                end
            end
        end
        tipCache[item] = names
    end
    if #names == 0 then return 0, 0 end
    -- filtered at count time (the alts list can change without ListsChanged): my alts, ignored
    -- players and people no longer in the roster (nil there; offline members are false) are left out
    local online = O.OnlineGuild()
    local alts = O.Profile().alts or {}
    local total, on = 0, 0
    for _, n in ipairs(names) do
        if online[n] ~= nil and not alts[n] and not (K.Ignored and K.Ignored(n)) then
            total = total + 1
            if online[n] then on = on + 1 end
        end
    end
    return total, on
end
function O.TipText(item)
    if type(item) ~= "number" or item <= 0 then return nil end
    local n, on = O.TipCrafters(item)
    if n == 0 then return nil end
    if n == 1 then
        return on > 0 and L("Fabricable par 1 artisan de la guilde (en ligne)") or L("Fabricable par 1 artisan de la guilde (hors ligne)")
    end
    if on == 0 then return string.format(L("Fabricable par %d artisans de la guilde (personne en ligne)"), n) end
    return string.format(L("Fabricable par %d artisans de la guilde (%d en ligne)"), n, on)
end
local function Secret(v) return root.IsSecret and root.IsSecret(v) end
function O.TooltipLine(tip, id)
    if not (tip and WLWritsDB) then return end
    if tip.IsForbidden and tip:IsForbidden() then return end
    if WP.ModuleOn and not WP.ModuleOn("orders") then return end
    if not O.TipCraftersOn() then return end
    if Secret(id) or type(id) ~= "number" then return end
    local text = O.TipText(id)
    if not text then return end
    local c = S.C.muted or S.C.text
    -- no tip:Show(): the game sizes the tooltip itself (an addon calling it can taint it)
    tip:AddLine(text, c[1], c[2], c[3])
end
local function TipID(tip, data)
    local id = type(data) == "table" and data.id or nil
    if Secret(id) then return nil end
    if type(id) == "number" then return id end
    local ok, _, link = pcall(tip.GetItem, tip)
    if ok and type(link) == "string" and not Secret(link) then return LinkID(link) end
end
if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tip, data)
        if tip ~= GameTooltip and tip ~= ItemRefTooltip then return end
        pcall(function() O.TooltipLine(tip, TipID(tip, data)) end)
    end)
else
    for _, t in ipairs({ GameTooltip, ItemRefTooltip }) do
        if t and t.HookScript then
            t:HookScript("OnTooltipSetItem", function(tip) pcall(function() O.TooltipLine(tip, TipID(tip)) end) end)
        end
    end
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

-- ---------------------------------------------------------------- the crafters' home (T-60)
-- My crafter profile (status, a note for buyers, what I hide) goes to the guild in one "A"
-- message; the others' come back into d.profiles. Around it: favourites, watched recipes, my
-- recent orders, the week's deliveries, alerts with their limits, a search that folds accents,
-- and one counted set of crafters (O.CrafterSet) that every number of the home reads.
do
    local DAY = 86400
    local function Day(t) return math.floor((t or time()) / DAY) end
    K.Day = Day
    local function Now() return GetTime and GetTime() or 0 end
    local function InCombat() return (InCombatLockdown and InCombatLockdown()) and true or false end
    K.InCombat = InCombat
    local function En() return ns.English and ns.English() or false end
    -- a yes/no from the game that may be a secret value: false unless plainly true
    local function Yes(f, ...)
        if not f then return false end
        local ok, v = pcall(f, ...)
        if not ok or (root.IsSecret and root.IsSecret(v)) then return false end
        return v == true or (v ~= nil and v ~= false and v ~= 0)
    end
    local function Bit(f, b) return math.floor((tonumber(f) or 0) / b) % 2 == 1 end
    K.Bit = Bit

    -- ---- my profile (account-wide), my status (per character)
    function O.Profile()
        local d = DB()
        local p = d.profile
        if type(p) ~= "table" then p = {}; d.profile = p end
        if type(p.note) ~= "string" then p.note = "" end
        if p.hideAlts == nil then p.hideAlts = false end
        if p.showZone == nil then p.showZone = true end
        if p.quiet == nil then p.quiet = true end
        if p.autoBusy == nil then p.autoBusy = true end
        if type(p.alts) ~= "table" then p.alts = {} end
        return p
    end
    local function CharDB()
        if type(WLWritsCharDB) ~= "table" then WLWritsCharDB = {} end
        return WLWritsCharDB
    end
    -- the words of a status, in the player's language (never through L: "Absent" is taken)
    local WORDS = { a = { "Disponible", "Available" }, b = { "Occupé", "Busy" }, o = { "Absent", "Away" }, d = { "En donjon", "In a dungeon" } }
    function O.StatusWord(s)
        local w = WORDS[s]
        if not w then return nil end
        return En() and w[2] or w[1]
    end
    -- the status picked by hand: a (available), b (busy), o (away)
    function O.BaseStatus()
        local s = CharDB().crafterStatus
        return (s == "a" or s == "b" or s == "o") and s or "a"
    end
    function O.SetCrafterStatus(s)
        if s ~= "a" and s ~= "b" and s ~= "o" then return end
        CharDB().crafterStatus = s
        K.Reeval()
    end
    function O.CycleStatus() O.SetCrafterStatus(({ a = "b", b = "o", o = "a" })[O.BaseStatus()]) end

    -- queued for a battleground or the dungeon finder (read only)
    local function Queued()
        if GetMaxBattlefieldID and GetBattlefieldStatus then
            local n = GetMaxBattlefieldID()
            for i = 1, (type(n) == "number" and n or 0) do
                if GetBattlefieldStatus(i) == "queued" then return true end
            end
        end
        if GetLFGQueueStats and LE_LFG_CATEGORY_LFD then
            if GetLFGQueueStats(LE_LFG_CATEGORY_LFD) then return true end
        end
        return false
    end
    local function InInstance()
        if not IsInInstance then return false end
        local ok, inside, kind = pcall(IsInInstance)
        if not ok or (root.IsSecret and (root.IsSecret(inside) or root.IsSecret(kind))) then return false end
        return (inside and (kind == "party" or kind == "raid" or kind == "pvp" or kind == "arena")) and true or false
    end
    K.InInstance = InInstance
    -- what the guild sees, worked out each time (never stored): Away wins; then Busy on its own
    -- (AFK, queued); then In a dungeon (quiet mode); then the status picked by hand.
    -- Second value: why it is automatic ("afk", "queue", "inst").
    function O.MyStatus()
        local base = O.BaseStatus()
        if base == "o" then return "o" end
        local p = O.Profile()
        if p.autoBusy then
            if Yes(UnitIsAFK, "player") then return "b", "afk" end
            if Yes(Queued) then return "b", "queue" end
        end
        if p.quiet and InInstance() then return "d", "inst" end
        return base
    end
    function O.MyMain()
        local p = O.Profile()
        if type(p.main) == "string" and p.main ~= "" and p.alts[p.main] then return p.main end
    end

    -- ---- the buyer's note: one line, no link, colour or texture, 50 characters (150 bytes) at most
    local function CutChars(t, n)
        local count, i = 0, 1
        while i <= #t do
            local c = t:byte(i)
            local len = c >= 0xF0 and 4 or c >= 0xE0 and 3 or c >= 0xC0 and 2 or 1
            count = count + 1
            if count > n then return t:sub(1, i - 1) end
            i = i + len
        end
        return t
    end
    function O.NoteLength(t) local _, n = tostring(t or ""):gsub("[^\128-\191]", ""); return n end
    function O.CleanNote(t)
        t = tostring(t or "")
        t = t:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|H.-|h", ""):gsub("|h", ""):gsub("|T.-|t", ""):gsub("|A.-|a", "")
        t = t:gsub("[|%c]", " "):gsub("%s+", " "):gsub("^ ", ""):gsub(" $", "")
        return (Utf8Cut(CutChars(t, 50), 150))
    end

    -- ---- the "A" message: A|v=1,s=a,f=0,w=3,t=40,m=Main|note
    -- f: 1 = zone hidden, 2 = alts hidden, 4 = recipes not shared. Unknown keys are ignored (a v2
    -- adds keys, never reorders). H and the other kinds are unchanged on the wire.
    function O.BuildA()
        local p = O.Profile()
        local f = (p.showZone == false and 1 or 0) + (p.hideAlts and 2 or 0) + (WLWritsDB.ordersShare == false and 4 or 0)
        local kv = { "v=1", "s=" .. O.MyStatus(), "f=" .. f, "w=" .. math.min(999, O.MyWeek()), "t=" .. math.min(99999, DB().myDelivTotal or 0) }
        local main = O.MyMain()
        if main and not p.hideAlts and main ~= Me() then
            local m = Utf8Cut((main:gsub("[,|=%c%s]", "")), 36)
            if m ~= "" then kv[#kv + 1] = "m=" .. m end
        end
        return "A|" .. table.concat(kv, ",") .. "|" .. O.CleanNote(p.note)
    end
    -- what a received "A" says, clamped (rest: everything after "A|")
    function O.ParseA(rest)
        local kvs, note = tostring(rest or ""):match("^([^|]*)|?(.*)$")
        local t = {}
        for item in ((kvs or "") .. ","):gmatch("([^,]*),") do
            local k, v = item:match("^(%a)=(.+)$")
            if k then t[k] = v end
        end
        local function Num(v, max)
            v = tonumber(v)
            if not v or v ~= v or v < 0 then return 0 end
            return math.min(max, math.floor(v))
        end
        local a = { v = Num(t.v, 999), s = ({ a = "a", b = "b", o = "o", d = "d" })[t.s], f = Num(t.f, 255), w = Num(t.w, 999), tot = Num(t.t, 99999) }
        if t.m and not Bit(a.f, 2) then
            local m = Utf8Cut((t.m:gsub("[,|=%c%s]", "")), 36)
            if m ~= "" then a.m = m end
        end
        a.note = O.CleanNote(note or "")
        return a
    end
    function K.OnProfile(sender, rest)
        local a = O.ParseA(rest)
        -- the main must be a member of the guild, and someone else
        if a.m and (a.m == sender or not O.Member(a.m)) then a.m = nil end
        local d = DB()
        d.profiles = d.profiles or {}
        d.profiles[sender] = { s = a.s, f = a.f, w = a.w, tot = a.tot, m = a.m, note = a.note, at = time(), v = a.v }
        -- one per sender per 5 s redraws the window; later ones are kept, quietly
        K.aSeen = K.aSeen or {}
        local now = Now()
        if K.aSeen[sender] and now - K.aSeen[sender] < 5 then return end
        K.aSeen[sender] = now
        K.RefreshSoon()
    end
    function K.RefreshSoon()
        if K.refreshPending then return end
        K.refreshPending = true
        C_Timer.After(0.5, function() K.refreshPending = false; if WP.RefreshOrders then WP.RefreshOrders() end end)
    end

    -- ---- sending my "A": at login (O.Announce), in answer to Q (same 30 s limit), and on a change
    -- of status, note or flags: 3 s later (changes merged, the latest wins), at most once per 30 s,
    -- never in combat. Busy or in a dungeon: said again after 15 min for whoever logged in since.
    local A = { lastAt = -1e9, dirty = false, timer = false }
    K.A = A
    function K.Sig()
        local p = O.Profile()
        return table.concat({ O.MyStatus(), p.note, tostring(p.hideAlts), tostring(p.showZone), tostring(WLWritsDB.ordersShare ~= false),
            tostring((O.MyMain())) }, "|")
    end
    function K.SendA()
        if not (IsInGuild and IsInGuild()) then return end
        if InCombat() then A.dirty = true; A.waitCombat = true; return end
        A.dirty, A.waitCombat = false, false
        A.lastAt = Now()
        A.sig = K.Sig()
        Guild(O.BuildA())
        A.resendToken = (A.resendToken or 0) + 1
        local token = A.resendToken
        C_Timer.After(900, function()
            if A.resendToken ~= token then return end
            -- Away too: a status older than 20 min reads as Available on the other side
            if O.MyStatus() ~= "a" then K.SendA() end
        end)
    end
    function K.QueueA()
        A.dirty = true
        if A.timer then return end
        A.timer = true
        C_Timer.After(math.max(3, 30 - (Now() - A.lastAt)), function()
            A.timer = false
            if A.dirty then K.SendA() end
        end)
    end
    -- something that may change what the guild sees: status, note, flags (and the way out of a
    -- dungeon: the orders that waited, the alerts held)
    -- fromEvent: a game event (AFK flag, queue, zone) only redraws the window when what it shows
    -- changed (LFG_UPDATE and UPDATE_BATTLEFIELD_STATUS come often while queued)
    function K.Reeval(fromEvent)
        local s, why = O.MyStatus()
        local was, wasWhy = K.lastStatus, K.lastWhy
        K.lastStatus, K.lastWhy = s, why
        if was == "d" and s ~= "d" then pcall(K.QuietReturn); pcall(K.FlushAlerts) end
        local sig = K.Sig()
        local changed = s ~= was or why ~= wasWhy
        if A.sig == nil and A.lastAt < 0 then A.sig = sig      -- not sent yet: the login announce says it
        elseif sig ~= A.sig then A.sig = sig; K.QueueA(); changed = true end
        if (changed or not fromEvent) and WP.RefreshOrders then WP.RefreshOrders() end
    end
    function O.SetNote(t)
        local link = tostring(t or ""):find("|", 1, true) ~= nil
        local n = O.CleanNote(t)
        O.Profile().note = n
        K.Reeval()
        return n, link
    end
    function O.SetProfileFlag(k, v)
        if k ~= "hideAlts" and k ~= "showZone" and k ~= "quiet" and k ~= "autoBusy" and k ~= "main" then return end
        O.Profile()[k] = v
        K.Reeval()
    end
    function O.ShareChanged() K.Reeval() end

    -- ---- alerts: never in combat (queued, the latest per key), held in a dungeon, chat only when
    -- Away, 3 toasts per 5 min (the rest merged into one), chat lines through Say (30 s de-duplication)
    local AL = { q = {}, order = {}, shown = {}, extra = 0 }
    K.AL = AL
    -- toast = { text, sub, linkLabel, onLink }
    function K.ShowAlert(toast, chat)
        if chat and K.Say then K.Say(chat, nil, "find") end
        if not toast or O.MyStatus() == "o" then return "chat" end
        local now = Now()
        for i = #AL.shown, 1, -1 do if now - AL.shown[i] >= 300 then table.remove(AL.shown, i) end end
        if #AL.shown >= 3 then
            AL.extra = AL.extra + 1
            if not AL.extraTimer then
                AL.extraTimer = true
                C_Timer.After(math.max(1, 300 - (now - AL.shown[1])), function()
                    AL.extraTimer = false
                    local n = AL.extra
                    AL.extra = 0
                    if n > 0 then
                        K.ShowAlert({ n == 1 and L("Et 1 autre alerte dans les Commandes.") or string.format(L("Et %d autres alertes dans les Commandes."), n),
                            nil, L("Ouvrir"), function() if WP.ShowOrdersTab then WP.ShowOrdersTab("find") end end })
                    end
                end)
            end
            return "merged"
        end
        AL.shown[#AL.shown + 1] = now
        if S and S.Toast then pcall(S.Toast, toast[1], toast[2], "info", toast[3], toast[4]) end
        return "toast"
    end
    function O.Alert(key, toast, chat)
        if WP.ModuleOn and not WP.ModuleOn("orders") then return "off" end
        if InCombat() or O.MyStatus() == "d" then
            if not AL.q[key] then AL.order[#AL.order + 1] = key end
            AL.q[key] = { toast, chat }
            return "queued"
        end
        return K.ShowAlert(toast, chat)
    end
    function K.FlushAlerts()
        if InCombat() or O.MyStatus() == "d" then return end
        local order, q = AL.order, AL.q
        AL.order, AL.q = {}, {}
        for _, k in ipairs(order) do local a = q[k]; if a then K.ShowAlert(a[1], a[2]) end end
    end

    -- ---- quiet in a dungeon (crafter side): new orders for me wait without a sound
    K.held = {}
    function K.HoldQuiet(o)
        if O.MyStatus() ~= "d" then return false end
        K.held[o.id] = true
        return true
    end
    function K.QuietReturn()
        local n, d = 0, DB()
        for id in pairs(K.held) do local o = d.list[id]; if o and o.status == "open" then n = n + 1 end end
        K.held = {}
        if n == 0 then return end
        K.ShowAlert({ n == 1 and L("1 commande t'a attendu pendant le donjon.") or string.format(L("%d commandes t'ont attendu pendant le donjon."), n),
            nil, L("Les voir"), function() if WP.ShowOrdersTab then WP.ShowOrdersTab("recv") end end })
    end

    -- ---- favourites (50 at most), watched recipes (30 at most)
    function O.IsFav(name) local f = DB().favs; return (f and name and f[name] ~= nil) and true or false end
    function O.ToggleFav(name)
        local d = DB()
        d.favs = d.favs or {}
        if not name then return false end
        if d.favs[name] then d.favs[name] = nil; return true, false end
        local n = 0
        for _ in pairs(d.favs) do n = n + 1 end
        if n >= 50 then return false, "cap" end
        d.favs[name] = time()
        return true, true
    end
    function O.IsWatched(id) local w = DB().watch; return (w and id and w[id] ~= nil) and true or false end
    function O.WatchCount() local n = 0; for _ in pairs(DB().watch or {}) do n = n + 1 end; return n end
    O.WATCH_MAX = 30
    function O.ToggleWatch(id)
        local d = DB()
        d.watch = d.watch or {}
        if not id then return false end
        if d.watch[id] then d.watch[id] = nil; return true, false end
        if O.WatchCount() >= O.WATCH_MAX then return false, "cap" end
        -- whoever already makes it never alerts
        local seen = {}
        for _, c in ipairs(O.Crafters(id)) do if not c.me then seen[c.name] = true end end
        d.watch[id] = { t = time(), seen = seen }
        return true, true
    end
    -- ---- "tell me when someone can make it" (T-80, the Request page): an item nobody makes yet.
    -- The first guild member whose recipe list arrives with it: one chat line, a sound when the
    -- setting allows it, then forgotten (once). Whoever already makes it does not count.
    O.KNOWN_MAX = 30
    function O.IsKnownWatch(id) local w = DB().knownWatch; return (w and id and w[id] ~= nil) and true or false end
    function O.ToggleKnownWatch(id)
        local d = DB()
        d.knownWatch = d.knownWatch or {}
        if type(id) ~= "number" or id == 0 then return false end
        if d.knownWatch[id] then d.knownWatch[id] = nil; return true, false end
        local n = 0
        for _ in pairs(d.knownWatch) do n = n + 1 end
        if n >= O.KNOWN_MAX then return false, "cap" end
        local seen = {}
        for _, c in ipairs(O.Crafters(id)) do if not c.me then seen[c.name] = true end end
        d.knownWatch[id] = { t = time(), seen = seen }
        return true, true
    end
    function K.OnKnown(sender, recipes, hadList)
        local d = DB()
        if type(d.knownWatch) ~= "table" or sender == Me() or O.Profile().alts[sender] then return end
        local on = not (WP.ModuleOn and not WP.ModuleOn("orders"))
        local said = false
        for id, w in pairs(d.knownWatch) do
            if recipes[id] and not (type(w) == "table" and type(w.seen) == "table" and w.seen[sender]) then
                d.knownWatch[id] = nil
                -- a watched recipe gives the same news with its own alert: not twice
                local ww = type(d.watch) == "table" and d.watch[id]
                local watchSays = type(ww) == "table" and not (type(ww.seen) == "table" and ww.seen[sender])
                    and hadList ~= false and WLWritsDB.ordersAlertWatch ~= false
                if on and not watchSays and K.Say
                    and K.Say(string.format(L("%s sait faire %s : tu peux le lui commander. Tape /wlh orders."), sender, O.Name(id)), nil, "find") then
                    said = true
                end
            end
        end
        -- one sound for the list, never in combat or in a dungeon (the other Orders alerts wait there too)
        if said and WLWritsDB.ordersKnownSound ~= false and not K.InCombat() and O.MyStatus() ~= "d"
            and PlaySound and SOUNDKIT and SOUNDKIT.READY_CHECK then
            pcall(PlaySound, SOUNDKIT.READY_CHECK, "Master")
        end
    end
    -- a member's recipe list arrived (only when its hash changed): watched recipes they now make.
    -- hadList false: no earlier list for this member and profession, so seen quietly (no alert)
    function K.OnRecipes(sender, prof, recipes, hadList)
        K.index = nil
        pcall(K.OnKnown, sender, recipes, hadList)
        local d = DB()
        for id, w in pairs(d.watch or {}) do
            if recipes[id] and type(w) == "table" then
                w.seen = w.seen or {}
                if not w.seen[sender] then
                    w.seen[sender] = true
                    if hadList ~= false and WLWritsDB.ordersAlertWatch ~= false then
                        local on = O.OnlineGuild()[sender]
                        local item = O.Name(id)
                        O.Alert("w:" .. id .. ":" .. sender, { string.format(L("%s sait maintenant faire %s."), sender, item),
                            on and string.format(L("%s est en ligne."), sender) or string.format(L("%s est hors ligne : ta commande l'attendra."), sender),
                            L("Commander"), function() if WP.NewOrder then WP.NewOrder(id, sender) end end },
                            string.format(L("%s sait maintenant faire %s. Tape /wlh orders pour le commander."), sender, item))
                    end
                end
            end
        end
    end
    -- the first watched recipe a member makes, or nil
    function K.WatchedBy(name)
        for id in pairs(DB().watch or {}) do if O.CanCraft(name, id) then return id end end
    end

    -- ---- presence: a favourite (or a crafter of a watched recipe) comes online. Signals: their
    -- "S" when they log in, else the roster going from offline to online. Once per 30 min per name;
    -- the first 90 s after my login, one summary instead.
    K.presAt = {}
    function K.ProfLine(name)
        local t = {}
        for pname, p in pairs(DB().crafters[name] or {}) do
            if type(p) == "table" then t[#t + 1] = { O.ProfName(O.ProfKeyOf(pname) or pname), p.rank or 0 } end
        end
        table.sort(t, function(a, b) return a[2] > b[2] end)
        local out = {}
        for i = 1, math.min(3, #t) do out[i] = t[i][1] .. " " .. t[i][2] end
        local pf = (DB().profiles or {})[name]
        local s = table.concat(out, " · ")
        if pf and pf.note and pf.note ~= "" then s = s .. (s ~= "" and " · " or "") .. "« " .. pf.note .. " »" end
        return s ~= "" and s or nil
    end
    function K.GraceSummary()
        K.graceTimer = false
        local names = K.grace or {}
        K.grace = {}
        if #names == 0 then return end
        table.sort(names)
        local list = table.concat(names, ", ", 1, math.min(6, #names)) .. (#names > 6 and (", +" .. (#names - 6)) or "")
        O.Alert("grace", { #names == 1 and string.format(L("1 favori en ligne : %s."), list) or string.format(L("%d favoris en ligne : %s."), #names, list),
            nil, L("Ouvrir"), function() if WP.ShowOrdersTab then WP.ShowOrdersTab("find") end end })
    end
    function K.Presence(name)
        if not name or name == Me() then return end
        local now = Now()
        if K.presAt[name] and now - K.presAt[name] < 1800 then return end
        local fav = O.IsFav(name)
        local watched = (not fav) and K.WatchedBy(name) or nil
        if not fav and not watched then return end
        K.presAt[name] = now
        local grace = K.loginAt and now - K.loginAt < 90
        if fav then
            if WLWritsDB.ordersAlertFav == false then return end
            if grace then
                K.grace = K.grace or {}
                K.grace[#K.grace + 1] = name
                if not K.graceTimer then
                    K.graceTimer = true
                    C_Timer.After(math.max(0.1, 90 - (now - K.loginAt)), K.GraceSummary)
                end
                return "grace"
            end
            local word = O.StatusWord(O.StatusOf(name))
            return O.Alert("f:" .. name, { word and string.format(L("%s est en ligne (%s)."), name, word) or string.format(L("%s est en ligne."), name),
                K.ProfLine(name), L("Voir sa fiche"), function() if WP.OpenCrafterPage then WP.OpenCrafterPage(name) end end },
                string.format(L("%s, ton artisan favori, est en ligne. Tape /wlh orders pour voir sa fiche."), name))
        end
        if grace or WLWritsDB.ordersAlertWatch == false then return end
        local item = O.Name(watched)
        return O.Alert("f:" .. name, { string.format(L("%s est en ligne et sait faire %s."), name, item), K.ProfLine(name),
            L("Commander"), function() if WP.NewOrder then WP.NewOrder(watched, name) end end },
            string.format(L("%s est en ligne et sait faire %s. Tape /wlh orders pour le commander."), name, item))
    end
    function K.RosterDiff()
        local prev = K.prevOnline
        local cur = {}
        for n, v in pairs(O.OnlineGuild(true)) do cur[n] = v end
        K.prevOnline = cur
        if not prev then
            -- the first read: who is online counts as arriving only during the login grace
            if K.loginAt and Now() - K.loginAt < 90 then for n, v in pairs(cur) do if v then K.Presence(n) end end end
            return
        end
        for n, v in pairs(cur) do if v and not prev[n] then K.Presence(n) end end
        K.RefreshSoon()
    end

    -- ---- my recent orders (30, both sides) and the deliveries of the week
    local function IdTime(id) return tonumber(tostring(id or ""):match("%-(%d+)%-%d+$")) end
    K.IdTime = IdTime
    -- two names of the same player (one is the other's main, or they share one)
    function K.SameOwner(a, b)
        if not a or not b then return false end
        if a == b then return true end
        local P = DB().profiles or {}
        local ma, mb = P[a] and P[a].m, P[b] and P[b].m
        return ma == b or mb == a or (ma ~= nil and ma == mb)
    end
    -- a delivered order counts once: for me (one per customer per day, never myself or my alts),
    -- or seen for its crafter (kept 14 days, apart from the orders list)
    function K.CountDelivery(o)
        local d = DB()
        d.seenDelivIDs = d.seenDelivIDs or {}
        if not (o.id and o.by and o.from) or d.seenDelivIDs[o.id] then return end
        local day = Day()
        d.seenDelivIDs[o.id] = day
        local me = Me()
        if o.by == me then
            if o.from == me or O.Profile().alts[o.from] then return end
            d.myDeliv = d.myDeliv or {}
            local e = d.myDeliv[day]
            if type(e) ~= "table" then e = { n = 0, who = {} }; d.myDeliv[day] = e end
            e.who = e.who or {}
            if e.who[o.from] then return end
            e.who[o.from] = true
            e.n = (e.n or 0) + 1
            d.myDelivTotal = (d.myDelivTotal or 0) + 1
            K.QueueA()
        elseif not K.SameOwner(o.by, o.from) then
            d.seenDeliv = d.seenDeliv or {}
            d.seenDeliv[o.by] = d.seenDeliv[o.by] or {}
            d.seenDeliv[o.by][day] = (d.seenDeliv[o.by][day] or 0) + 1
        end
    end
    function K.AfterMerge(o)
        local d, me = DB(), Me()
        if o.from == me or o.by == me then
            d.recent = d.recent or {}
            local side = (o.from == me) and "out" or "in"
            local e
            for _, x in ipairs(d.recent) do if x.id == o.id then e = x; break end end
            if not e then
                e = { id = o.id, t = IdTime(o.id) or time() }
                table.insert(d.recent, 1, e)
                table.sort(d.recent, function(a, b) return (a.t or 0) > (b.t or 0) end)
                while #d.recent > 30 do table.remove(d.recent) end
            end
            e.item, e.title, e.qty, e.side, e.st = o.item, o.title, o.qty, side, o.status
            e.who = side == "out" and (o.by or o.to) or o.from
        end
        if o.status == "delivered" then K.CountDelivery(o) end
    end
    -- delivered in the last 7 days (today and the 6 before)
    function O.MyWeek()
        local today, n = Day(), 0
        for day, e in pairs(DB().myDeliv or {}) do
            if type(day) == "number" and day > today - 7 and day <= today and type(e) == "table" then n = n + (e.n or 0) end
        end
        return n
    end
    function O.SeenWeek(name)
        local today, n = Day(), 0
        for day, k in pairs((DB().seenDeliv or {})[name] or {}) do
            if type(day) == "number" and day > today - 7 and day <= today then n = n + (tonumber(k) or 0) end
        end
        return n
    end
    -- forgets what is outside its window; favourites and watched recipes stay
    function K.Prune()
        local d, today, now = DB(), Day(), time()
        for day, e in pairs(d.myDeliv or {}) do
            if type(day) ~= "number" or day <= today - 14 then d.myDeliv[day] = nil
            elseif day < today and type(e) == "table" then e.who = nil end
        end
        for name, days in pairs(d.seenDeliv or {}) do
            if type(days) == "table" then
                for day in pairs(days) do if type(day) ~= "number" or day <= today - 14 then days[day] = nil end end
            end
            if type(days) ~= "table" or next(days) == nil then d.seenDeliv[name] = nil end
        end
        for id, day in pairs(d.seenDelivIDs or {}) do if type(day) ~= "number" or day <= today - 14 then d.seenDelivIDs[id] = nil end end
        for name, p in pairs(d.profiles or {}) do if type(p) ~= "table" or (p.at or 0) < now - 30 * DAY then d.profiles[name] = nil end end
        for id, w in pairs(d.knownWatch or {}) do if type(w) ~= "table" or (w.t or 0) < now - 30 * DAY then d.knownWatch[id] = nil end end
        if type(d.recent) == "table" then
            for i = #d.recent, 1, -1 do if type(d.recent[i]) ~= "table" or (d.recent[i].t or 0) < now - 14 * DAY then table.remove(d.recent, i) end end
        end
        K.index = nil
    end
    -- the searches typed (8, newest first, the same words once)
    function O.AddSearch(q)
        q = tostring(q or ""):gsub("^%s+", ""):gsub("%s+$", "")
        if #q < 2 or q:find("|", 1, true) then return end
        local d = DB()
        d.searches = d.searches or {}
        local f = O.Fold(q)
        for i = #d.searches, 1, -1 do if O.Fold(d.searches[i]) == f then table.remove(d.searches, i) end end
        table.insert(d.searches, 1, q)
        while #d.searches > 8 do table.remove(d.searches) end
    end

    -- ---- place in line: an order to a crafter waits behind their earlier open or running orders
    function O.PlaceInLine(o)
        local x = o and (o.by or o.to)
        if not x then return nil end
        local mine, now = IdTime(o.id) or 0, time()
        local n = 1
        for _, y in pairs(DB().list) do
            if y.id ~= o.id then
                local q = (y.to == x and y.status == "open" and (y.expires or now) >= now) or (y.by == x and (y.status == "accepted" or y.status == "crafted"))
                if q and (IdTime(y.id) or 0) < mine then n = n + 1 end
            end
        end
        return n
    end
    function O.Ordinal(n)
        if En() then
            local t, s = n % 100, "th"
            if t < 11 or t > 13 then s = ({ "st", "nd", "rd" })[n % 10] or "th" end
            return n .. s
        end
        return n == 1 and "1er" or (n .. "e")
    end
    -- another member's status: their last "A" (20 min at most) while online, else away in the roster
    function O.StatusOf(name)
        if name == Me() then return (O.MyStatus()) end
        if not O.OnlineGuild()[name] then return nil end
        local pf = (DB().profiles or {})[name]
        if pf and pf.s and time() - (pf.at or 0) < 1200 then return pf.s end
        local m = O.Member(name)
        if m and m.afk then return "b" end
        return nil
    end

    -- ---- folding for the search: lower case, accents off (the game's lower() only does A-Z)
    local FOLD = {}
    for base, chars in pairs({
        a = "ÀÁÂÃÄÅàáâãäåĀāĂăĄą", ae = "Ææ", c = "ÇçĆćĈĉĊċČč", d = "ĎďĐđÐð", e = "ÈÉÊËèéêëĒēĔĕĖėĘęĚě",
        g = "ĜĝĞğĠġĢģ", h = "ĤĥĦħ", i = "ÌÍÎÏìíîïĨĩĪīĬĭĮįİı", ij = "Ĳĳ", j = "Ĵĵ", k = "Ķķĸ", l = "ĹĺĻļĽľĿŀŁł",
        n = "ÑñŃńŅņŇňŉŊŋ", o = "ÒÓÔÕÖØòóôõöøŌōŎŏŐő", oe = "Œœ", r = "ŔŕŖŗŘř", s = "ŚśŜŝŞşŠšſ", ss = "ß",
        t = "ŢţŤťŦŧ", th = "Þþ", u = "ÙÚÛÜùúûüŨũŪūŬŭŮůŰűŲų", w = "Ŵŵ", y = "ÝýÿŶŷŸ", z = "ŹźŻżŽž", ["'"] = "’‘ʼ´`",
    }) do
        for ch in chars:gmatch("[%z\1-\127\192-\244][\128-\191]*") do FOLD[ch] = base end
    end
    function O.Fold(s)
        -- accents first, then A-Z only (a locale-aware lower() could change the bytes of UTF-8 letters)
        s = tostring(s or ""):gsub("[\192-\244][\128-\191]*", FOLD)
        return (s:gsub("[A-Z]", string.lower):gsub("`", "'"))
    end

    -- ---- the set of crafters every number of the home reads
    function K.Ignored(name)
        return Yes(C_FriendList and C_FriendList.IsIgnored, name)
    end
    -- { list = groups, byName, online, avail, zone, known, prof = { [key] = { total, online } }, top }
    -- A group is one player: characters with the same main are shown as one, under the online one
    -- (else the main), "+N alts". Each: name, chars, class, level, online, status, zone, note,
    -- week, tot, profs = { { key, rank, n, char } } (best per profession), favourite, stars, seen.
    function O.CrafterSet()
        local d, me = DB(), Me()
        local p = O.Profile()
        local on = O.OnlineGuild()
        local P = d.profiles or {}
        local names = {}
        for name, profs in pairs(d.crafters) do
            if type(profs) == "table" then
                for _, pr in pairs(profs) do
                    if type(pr) == "table" and ((pr.rank or 0) > 1 or next(pr.recipes or {}) ~= nil) then names[name] = true; break end
                end
            end
        end
        for name in pairs(P) do names[name] = true end
        local chars = {}
        for name in pairs(names) do
            if name ~= me and not p.alts[name] and not K.Ignored(name) then
                local pf, m = P[name], O.Member(name)
                local online = on[name] and true or false
                local st
                if online then
                    if pf and pf.s and time() - (pf.at or 0) < 1200 then st = pf.s
                    elseif m and m.afk then st = "b" end
                end
                local profs = {}
                for pname, pr in pairs(d.crafters[name] or {}) do
                    if type(pr) == "table" then
                        local n = 0
                        for _ in pairs(pr.recipes or {}) do n = n + 1 end
                        profs[#profs + 1] = { key = O.ProfKeyOf(pname) or pname, raw = pname, rank = pr.rank or 0, max = pr.max, n = n, char = name }
                    end
                end
                chars[#chars + 1] = { name = name, main = pf and pf.m or nil, class = m and m.class or nil, level = m and m.level or nil,
                    online = online, status = st, zone = (online and m and not (pf and Bit(pf.f, 1))) and m.zone or nil,
                    lastOnline = m and m.lastOnline or nil, note = (pf and pf.note ~= "") and pf.note or nil,
                    week = pf and pf.w or 0, tot = pf and pf.tot or 0, profs = profs, fav = O.IsFav(name) }
            end
        end
        local groups, byKey = {}, {}
        for _, c in ipairs(chars) do
            local key = c.main or c.name
            local g = byKey[key]
            if not g then g = { key = key, chars = {} }; byKey[key] = g; groups[#groups + 1] = g end
            g.chars[#g.chars + 1] = c
        end
        local myZone = GetRealZoneText and GetRealZoneText() or nil
        local set = { list = groups, byName = {}, online = 0, avail = 0, zone = 0, known = #groups, prof = {}, top = {} }
        for _, g in ipairs(groups) do
            table.sort(g.chars, function(a, b)
                if a.online ~= b.online then return a.online end
                if (a.status == "a") ~= (b.status == "a") then return a.status == "a" end
                if (a.name == g.key) ~= (b.name == g.key) then return a.name == g.key end
                return a.name < b.name
            end)
            local rep = g.chars[1]
            g.name, g.class, g.level, g.online, g.status, g.zone = rep.name, rep.class, rep.level, rep.online, rep.status, rep.zone
            g.alts = #g.chars - 1
            g.week, g.tot, g.stars, g.seen, g.fav = 0, 0, 0, 0, false
            local best = {}
            for _, c in ipairs(g.chars) do
                set.byName[c.name] = g
                g.week, g.tot = math.max(g.week, c.week), math.max(g.tot, c.tot)
                g.stars = g.stars + O.Stars(c.name)
                g.seen = g.seen + O.SeenWeek(c.name)
                g.fav = g.fav or c.fav
                if not g.note and c.note then g.note = c.note end
                if c.lastOnline and (not g.lastOnline or c.lastOnline < g.lastOnline) then g.lastOnline = c.lastOnline end
                for _, pr in ipairs(c.profs) do
                    if not best[pr.key] or pr.rank > best[pr.key].rank then best[pr.key] = pr end
                end
            end
            if rep.note then g.note = rep.note end
            g.profs = {}
            for _, pr in pairs(best) do g.profs[#g.profs + 1] = pr end
            table.sort(g.profs, function(a, b) if a.rank ~= b.rank then return a.rank > b.rank end return tostring(a.key) < tostring(b.key) end)
            g.available = g.online and (g.status == "a" or g.status == nil)
            if g.online then
                set.online = set.online + 1
                if g.available then set.avail = set.avail + 1 end
                if myZone and g.zone == myZone then set.zone = set.zone + 1 end
            end
            for key in pairs(best) do
                local e = set.prof[key]
                if not e then e = { total = 0, online = 0 }; set.prof[key] = e end
                e.total = e.total + 1
                if g.online then e.online = e.online + 1 end
            end
            if g.week > 0 then set.top[#set.top + 1] = g end
        end
        table.sort(set.top, function(a, b)
            if a.week ~= b.week then return a.week > b.week end
            if a.seen ~= b.seen then return a.seen > b.seen end
            if a.stars ~= b.stars then return a.stars > b.stars end
            return a.name < b.name
        end)
        return set
    end

    -- ---- search: players, items, materials (a lazy index, rebuilt when lists change)
    function K.Index()
        if K.index then return K.index end
        local idx = { names = {}, raw = {}, mats = {}, matNames = {}, who = {}, pending = {} }
        local me = Me()
        local function Walk(name, recipes)
            for id, re in pairs(recipes or {}) do
                if type(id) == "number" then
                    if not idx.raw[id] then
                        local n = O.Name(id)
                        idx.raw[id], idx.names[id] = n, O.Fold(n)
                        if id > 0 and n:match("^item:?%s?%d+$") then
                            idx.pending[id] = true
                            if C_Item and C_Item.RequestLoadItemDataByID then pcall(C_Item.RequestLoadItemDataByID, id) end
                        end
                    end
                    if name ~= me then
                        local w = idx.who[id]
                        if not w then w = {}; idx.who[id] = w end
                        w[#w + 1] = name
                    end
                    for rid in tostring(re):gmatch("(%d+):%d+") do
                        rid = tonumber(rid)
                        local t = idx.mats[rid]
                        if not t then t = {}; idx.mats[rid] = t end
                        t[id] = true
                    end
                end
            end
        end
        for name, profs in pairs(DB().crafters) do
            if type(profs) == "table" then for _, p in pairs(profs) do if type(p) == "table" then Walk(name, p.recipes) end end end
        end
        for _, p in pairs(DB().mine) do if type(p) == "table" then Walk(me, p.recipes) end end
        K.index = idx
        return idx
    end
    function K.MatName(idx, rid)
        local n = idx.matNames[rid]
        if not n then
            local raw = O.Name(rid)
            n = O.Fold(raw)
            if raw:match("^item:?%s?%d+$") then idx.pending[rid] = true else idx.matNames[rid] = n end
        end
        return n
    end
    -- 1 = starts with the words, 2 = a word starts with them, 3 = anywhere
    local function Rank(fname, fq)
        if fname:sub(1, #fq) == fq then return 1 end
        local at = fname:find(fq, 1, true)
        if not at then return nil end
        if fname:sub(at - 1, at - 1):match("[%s%-'%(]") then return 2 end
        return 3
    end
    K.Rank = Rank
    O.SEARCH_CAPS = { players = 5, items = 20, mats = 5 }
    -- O.Search(q, caps, set) -> { players, items, mats = { list, total }, use = reagent id or false }
    function O.Search(q, caps, set)
        caps = caps or {}
        local fq = O.Fold((tostring(q or ""):gsub("^%s+", ""):gsub("%s+$", "")))
        local res = { players = { list = {}, total = 0 }, items = { list = {}, total = 0 }, mats = { list = {}, total = 0 }, q = fq }
        if #fq < 2 then return res end
        local idx = K.Index()
        local on = O.OnlineGuild()
        local function Cap(g, list, cap)
            g.total = #list
            for i = 1, math.min(#list, cap) do g.list[i] = list[i] end
        end
        -- "Uses: <material>": the items made with it, and nothing else
        local useP = O.Fold(L("Utilise : "))
        local useOnly
        if fq:sub(1, #useP) == useP then
            local want = (fq:sub(#useP + 1):gsub("^%s+", ""))
            for rid in pairs(idx.mats) do if K.MatName(idx, rid) == want then useOnly = rid; break end end
            res.use = useOnly or false
        end
        -- items
        local items = {}
        if res.use ~= nil then
            for id in pairs(useOnly and idx.mats[useOnly] or {}) do items[#items + 1] = { id = id, rank = 1 } end
        else
            for id, fname in pairs(idx.names) do
                local r = Rank(fname, fq)
                if r then items[#items + 1] = { id = id, rank = r } end
            end
        end
        for _, it in ipairs(items) do
            it.name = idx.raw[it.id] or O.Name(it.id)
            local who = idx.who[it.id] or {}
            it.n = #who
            for _, n in ipairs(who) do
                if on[n] and not it.online then it.online = n end
                if O.IsFav(n) then it.fav = true end
            end
        end
        table.sort(items, function(a, b)
            if a.rank ~= b.rank then return a.rank < b.rank end
            if (a.online ~= nil) ~= (b.online ~= nil) then return a.online ~= nil end
            if (a.fav or false) ~= (b.fav or false) then return a.fav or false end
            if a.name ~= b.name then return a.name < b.name end
            return a.id < b.id
        end)
        Cap(res.items, items, caps.items or O.SEARCH_CAPS.items)
        if res.use ~= nil then return res end
        -- players: name, main, or a profession (either language)
        set = set or O.CrafterSet()
        local players = {}
        for _, g in ipairs(set.list) do
            local r
            for _, c in ipairs(g.chars) do
                local x = Rank(O.Fold(c.name), fq) or (c.main and Rank(O.Fold(c.main), fq))
                if x and (not r or x < r) then r = x end
            end
            if not r then
                for _, pr in ipairs(g.profs) do
                    for _, n in ipairs(PROF_NAMES[pr.key] or { pr.raw or pr.key }) do
                        local x = Rank(O.Fold(n), fq)
                        if x then r = math.max(2, x) end
                    end
                end
            end
            if r then players[#players + 1] = { g = g, rank = r } end
        end
        table.sort(players, function(a, b)
            if a.rank ~= b.rank then return a.rank < b.rank end
            if a.g.online ~= b.g.online then return a.g.online end
            if a.g.fav ~= b.g.fav then return a.g.fav end
            return a.g.name < b.g.name
        end)
        for i, x in ipairs(players) do players[i] = x.g end
        Cap(res.players, players, caps.players or O.SEARCH_CAPS.players)
        -- materials
        local mats = {}
        for rid, ids in pairs(idx.mats) do
            local fname = K.MatName(idx, rid)
            local r = Rank(fname, fq)
            if r then
                local n = 0
                for _ in pairs(ids) do n = n + 1 end
                mats[#mats + 1] = { id = rid, rank = r, name = O.Name(rid), n = n }
            end
        end
        table.sort(mats, function(a, b)
            if a.rank ~= b.rank then return a.rank < b.rank end
            if a.name ~= b.name then return a.name < b.name end
            return a.id < b.id
        end)
        Cap(res.mats, mats, caps.mats or O.SEARCH_CAPS.mats)
        return res
    end

    -- ---- events: status changes, combat, the roster, item names arriving
    local ev = CreateFrame("Frame")
    for _, e in ipairs({ "PLAYER_LOGIN", "PLAYER_REGEN_ENABLED", "GUILD_ROSTER_UPDATE", "PLAYER_FLAGS_CHANGED", "UPDATE_BATTLEFIELD_STATUS",
        "LFG_UPDATE", "PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA", "GET_ITEM_INFO_RECEIVED" }) do pcall(ev.RegisterEvent, ev, e) end
    local function AddAlt() if IsInGuild and IsInGuild() then O.Profile().alts[Me()] = true end end
    ev:SetScript("OnEvent", function(_, e, a1)
        if not WLWritsDB then return end
        if e == "PLAYER_LOGIN" then
            K.loginAt = Now()
            pcall(AddAlt)
            C_Timer.After(20, function() pcall(AddAlt) end)
        elseif e == "PLAYER_REGEN_ENABLED" then
            if A.waitCombat or A.dirty then
                if Now() - A.lastAt >= 30 then pcall(K.SendA) else K.QueueA() end
            end
            pcall(K.FlushAlerts)
        elseif e == "GUILD_ROSTER_UPDATE" then
            if K.rosterPending then return end
            K.rosterPending = true
            C_Timer.After(math.max(2, 10 - (Now() - (K.rosterAt or -1e9))), function()
                K.rosterPending = false
                K.rosterAt = Now()
                pcall(K.RosterDiff)
            end)
        elseif e == "GET_ITEM_INFO_RECEIVED" then
            -- a name the search was waiting for: rebuild the index (0.3 s after the last one), and
            -- the results again while they show
            if K.index and a1 and K.index.pending[a1] and not K.itemTimer then
                K.itemTimer = true
                C_Timer.After(0.3, function()
                    K.itemTimer = false
                    K.index = nil
                    local f = WP.OrdersUI and WP.OrdersUI.find
                    if f and f.box and f.box:IsVisible() and #((f.box:GetText() or ""):gsub("%s", "")) >= 2 then K.RefreshSoon() end
                end)
            end
        elseif e == "PLAYER_FLAGS_CHANGED" and type(a1) == "string" and not (root.IsSecret and root.IsSecret(a1)) and a1 ~= "player" then
            return   -- a party member's flags
        else
            pcall(K.Reeval, true)
        end
    end)
end

-- ---------------------------------------------------------------- receiving
local parts = {}
-- the guild answers in bursts (each crafter sends one "H" per profession): one redraw for the lot
local function RefreshSoon()
    if K.RefreshSoon and C_Timer and C_Timer.After then K.RefreshSoon() elseif WP.RefreshOrders then WP.RefreshOrders() end
end
-- "[text]" at the end of a chat line, a link to an Orders tab (FinderPeople.lua reads it)
local function Link(text, tab) return (WP.AddonLink and tab) and (" " .. WP.AddonLink(text, "orders", tab)) or "" end
-- A profession's name as a copy sends it (the game's name, any language): letters, spaces and
-- apostrophes, never digits or separators; 8 professions per member at most.
local MAX_PROFS, MAX_RECIPES = 8, 2000
local function GoodProf(prof)
    return type(prof) == "string" and #prof >= 2 and #prof <= 32 and not prof:find("[%d%c|~:;,=]")
end
local function ProfSlot(d, sender, prof)
    if not GoodProf(prof) then return nil end
    local ps = d.crafters[sender]
    if ps and ps[prof] then return ps end
    local n = 0
    for _ in pairs(ps or {}) do n = n + 1 end
    if n >= MAX_PROFS then return nil end
    ps = ps or {}
    d.crafters[sender] = ps
    return ps
end
local function OnPayload(sender, key, payload)
    local prof, hash = key:match("^R:(.-):(%x+)$")
    if prof and #hash <= 16 then
        local recipes, n = {}, 0
        for id, re in payload:gmatch("(%-?%d+)=([%d:,]*)") do
            id = tonumber(id)
            if id and id == math.floor(id) and math.abs(id) <= 10000000 and #re <= 120 and n < MAX_RECIPES then
                if recipes[id] == nil then n = n + 1 end
                recipes[id] = re
            end
        end
        local d = DB()
        if not ProfSlot(d, sender, prof) then return end
        local c = d.crafters[sender][prof] or {}
        -- a first list for this member and profession (first sync, after the 30-day prune, a fresh
        -- install) says nothing new: it only marks the watched recipes as seen
        local hadList = type(c.recipes) == "table"
        c.recipes, c.hash, c.t = recipes, hash, time()
        d.crafters[sender][prof] = c
        O.ListsChanged()
        -- a watched recipe learned by this member, and the search index to rebuild
        if K.OnRecipes then pcall(K.OnRecipes, sender, prof, recipes, hadList) end
        RefreshSoon()
    end
end

local askedW
local unknownStars = {}
local resendAt, resendQueued = -1e9, false
-- A new order from another member: open, expiring within a month, 25 running per customer and
-- 300 of the others' open orders in all (the oldest finished ones are pruned at login).
local function NewOrderOk(d, o, sender)
    if o.from ~= sender or #o.id > 64 or (o.to and not Key(o.to)) then return false end
    if not o.expires then return false end
    local mine, all = 0, 0
    for _, x in pairs(d.list) do
        if x.from ~= Me() and (x.status == "open" or Running(x)) then
            all = all + 1
            if x.from == sender then mine = mine + 1 end
        end
    end
    return mine < 25 and all < 300
end
local function OnMessage(msg, channel, sender)
    local d = DB()
    local kind, rest = msg:match("^(%u)|(.*)$")
    if kind == "H" and channel == "GUILD" then
        -- a member's profession hash: ask for the list when ours is older
        local prof, rank, max, hash = rest:match("^(.-)|(%d+)|(%d+)|(%x+)$")
        if prof and #hash <= 16 and ProfSlot(d, sender, prof) then
            local c = d.crafters[sender][prof] or {}
            c.rank, c.max, c.t = math.min(tonumber(rank) or 0, 1000), math.min(tonumber(max) or 0, 1000), time()   -- seen now, even if the list did not change
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
            RefreshSoon()
        end
    elseif kind == "W" then
        -- "W|prof|owner" on the guild (1.0.0-beta.29+): only the owner answers; "W|prof" by whisper
        -- from older copies: answered too (the list itself always goes on the guild channel)
        -- by whisper: only from a member of the guild (a stranger never makes me post to the guild)
        if channel == "WHISPER" and O.OnlineGuild()[sender] == nil then return end
        local prof, owner = rest:match("^(.-)|([^|]+)$")
        if prof then
            if owner == Me() then SendRecipes(prof) end
        else
            SendRecipes(rest)
        end
    elseif kind == "P" and channel == "GUILD" then
        local key, i, n, chunk = rest:match("^(.-)|(%d+)|(%d+)|(.*)$")
        i, n = tonumber(i), tonumber(n)
        -- a part numbered 1..n, n at most 200 (40 KB), for a key no longer than a profession's
        if key and #key <= 60 and i and n and n >= 1 and n <= 200 and i >= 1 and i <= n then
            local id = sender .. "|" .. key
            local now = GetTime()
            local open, own = 0, 0
            for k, p in pairs(parts) do
                if now - (p.t or now) > 120 then parts[k] = nil
                else open = open + 1; if p.who == sender then own = own + 1 end end
            end
            -- a list announced with another number of parts starts again
            if parts[id] and parts[id].n ~= n then parts[id] = nil end
            if not parts[id] then
                -- 400 lists in progress at most (a fresh install hears the whole guild), 8 per member
                if open >= 400 or own >= 8 then return end
                parts[id] = { n = n, who = sender }
            end
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
        -- the names a copy writes for itself (its name without the realm) are the sender's key here
        if o and o.from and o.from ~= sender and root.NameIs and root.NameIs(o.from, sender) then o.from = sender end
        if o and o.by and o.by ~= sender and root.NameIs and root.NameIs(o.by, sender) then o.by = sender end
        -- an order lasts 3 days at most: one expiring in more than a month did not come from WL Helper
        if o and o.expires and o.expires > time() + 31 * 86400 then o = nil end
        if o and not d.list[o.id] and not NewOrderOk(d, o, sender) then o = nil end
        if o and Allowed(o, sender) then
            -- an order I was making for someone else: told if it slips away (cancelled, taken by another)
            local was = d.list[o.id]
            local wasMine = was and was.by == Me() and was.from ~= Me() and (was.status == "accepted" or was.status == "crafted")
            local merged, changed = Merge(o)
            if changed then O.Notify(merged) end
            if wasMine and changed and merged then O.NotifySlip(merged) end
            RefreshSoon()
        end
    elseif kind == "M" and channel == "GUILD" then
        -- a message on an order: kept when it is between its customer and its crafter, and I am one of them
        local id, text = rest:match("^([^|]+)|(.*)$")
        local o = id and d.list[id]
        if o and (sender == o.from or sender == o.by) and (Me() == o.from or Me() == o.by) then
            AddMessage(o, sender, CleanText(text))
            if WP.ModuleOn("orders") then
                WP.ordersPendingTab = (Me() == o.from) and "mine" or "recv"
                WP.Print(string.format(L("Message de %s sur la commande %s : « %s »."), sender, O.Name(o), CleanText(text))
                    .. Link(L("Répondre"), WP.ordersPendingTab))
            end
            RefreshSoon()
        end
    elseif kind == "V" and channel == "GUILD" then
        -- a thank-you: one star per delivered order, given by its customer only
        local id, crafter = rest:match("^([^|]+)|([^|]+)$")
        local o = id and d.list[id]
        -- the crafter as this copy keeps him (an older copy writes the name without the realm)
        if crafter and o and o.by and o.by ~= crafter and root.NameIs and root.NameIs(crafter, o.by) then crafter = o.by
        else crafter = crafter and Key(crafter) end
        -- an order I know: its customer thanks its crafter, once it was crafted or delivered; an order
        -- I never saw (pruned, before my install): its id must be the sender's, 20 such stars a session
        local ok = false
        if crafter and crafter ~= sender and #id <= 64 then
            if o then ok = o.from == sender and o.by == crafter and (Running(o) or o.status == "delivered")
            else
                local short = sender:match("^([^%-%s]+)") or sender
                unknownStars[sender] = unknownStars[sender] or 0
                ok = id:match("^(.-)%-%d+%-%d+$") == short and unknownStars[sender] < 20
                if ok then unknownStars[sender] = unknownStars[sender] + 1 end
            end
        end
        if ok then
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
        if K.Presence then pcall(K.Presence, sender) end
        -- answered once a few seconds later; requests inside the next 30 s get one more answer when
        -- they end (several members logging in together get the same lines, once)
        if resendQueued then return end
        resendQueued = true
        C_Timer.After(math.max(1 + math.random() * 4, resendAt + 30 - GetTime()), function()
            resendQueued = false; resendAt = GetTime()
            local me = Me()
            for _, o in pairs(DB().list) do
                if Sane(o) and ((o.from == me and o.status == "open") or ((o.from == me or o.by == me) and Running(o))) then Broadcast(o) end
            end
        end)
    elseif kind == "A" and channel == "GUILD" then
        -- a member's crafter profile (T-60); older copies have no "A" branch and ignore it
        if K.OnProfile then pcall(K.OnProfile, sender, rest) end
    end
end

-- At login: forget orders finished or expired more than a week ago, and crafters gone quiet for a month.
local function Prune()
    local d = DB()
    local now = time()
    for id, o in pairs(d.list) do
        if not Sane(o) then
            d.list[id] = nil; if d.hidden then d.hidden[id] = nil end
        else
            local done = (STATUS_RANK[o.status] or 0) >= 4 or (o.status == "open" and (o.expires or 0) < now)
            if done and (o.expires or 0) < now - 7 * 86400 then d.list[id] = nil; if d.hidden then d.hidden[id] = nil end end
        end
    end
    for name, profs in pairs(d.crafters) do
        local recent = false
        for _, p in pairs(profs) do if (p.t or 0) > now - 30 * 86400 then recent = true end end
        if not recent then d.crafters[name] = nil end
    end
    O.ListsChanged()
    if K.Prune then pcall(K.Prune) end
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
K.Say = Say

-- One chat line when an order concerns you.
local newsAt, newsN, bannerAt = -1e9, 0, -1e9
function O.Notify(o)
    if WP.ModuleOn and not WP.ModuleOn("orders") then return end
    local me = Me()
    local name = O.Name(o)
    -- a request (o.prof set) alerts everyone who declared its profession, or any profession when unknown
    if o.status == "open" and o.from ~= me and (o.to == me or (not o.to and O.CanServe(me, o))) then
        -- quiet in a dungeon: no line, no sound; counted, and told on the way out
        if K.HoldQuiet and K.HoldQuiet(o) then return end
        local money = (o.fee or 0) + (o.tip or 0)
        local fee = money > 0 and string.format(L("%s de commission"), S.Money(money)) or L("sans commission")
        local msg = (o.prof and string.format(L("Nouvelle demande de %s : %s ×%d (%s), %s."), o.from, name, o.qty or 1, O.ProfName(o.prof), fee)
            or string.format(L("Nouvelle commande de %s : %s ×%d, %s."), o.from, name, o.qty or 1, fee)) .. Link(L("Voir la commande"), "recv")
        -- a burst of new orders: 4 lines a minute at most (the Orders window lists them all)
        local t = GetTime and GetTime() or 0
        if t - newsAt >= 60 then newsAt, newsN = t, 0 end
        if newsN >= 4 then return end
        -- the banner and the sound only with a new chat line (not for each copy of the same order),
        -- once every 20 s
        local said = Say(msg, o, "recv")
        if said then newsN = newsN + 1 end
        if said and t - bannerAt >= 20 and WLWritsDB.ordersAlert ~= false then
            bannerAt = t
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
        Say(string.format(L("%s a refusé ta commande de %s (%s)."), o.by or "?", name, L(o.reason or "Autre")) .. Link(L("Voir la commande"), "mine"), o, "mine")
    elseif o.from == me and o.status == "crafted" then
        Say(string.format(L("%s a fabriqué ta commande : %s ×%d. Elle t'arrive par la poste, contre-remboursement s'il y a une commission, ou en échange."), o.by or "?", name, o.qty or 1), o, "mine")
    elseif o.from == me and o.status == "delivered" and not o.thanked then
        Say(string.format(L("%s t'a livré %s."), o.by or "?", name) .. Link(L("Remercier"), "mine"), o, "mine")
    end
end

-- An order I had accepted (or crafted) for someone else is no longer mine: its customer cancelled it,
-- or another crafter took it at the same time and the guild kept theirs. One line, to "Pour moi".
function O.NotifySlip(o)
    if WP.ModuleOn and not WP.ModuleOn("orders") then return end
    local me = Me()
    if o.from == me then return end
    if o.status == "cancelled" then
        Say(string.format(L("%s a annulé sa commande : %s ×%d."), o.from or "?", O.Name(o), o.qty or 1), o, "recv")
    elseif o.by and o.by ~= me and (o.status == "accepted" or o.status == "crafted") then
        Say(string.format(L("%s a pris la commande %s avant toi : elle n'est plus pour toi."), o.by, O.Name(o)), o, "recv")
    end
end

-- ---------------------------------------------------------------- automatic steps
local function PrintReceived(o)
    WP.ordersPendingTab = "mine"
    WP.Print(string.format(L("Tu as reçu ta commande : %s ×%d de %s."), O.Name(o), o.qty or 1, o.by or "?") .. Link(L("Remercier"), "mine"))
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
        local who = Key(sender)
        if not who or who == Me() or (root.Readable and not root.Readable(msg)) then return end
        if channel ~= "GUILD" and channel ~= "WHISPER" then return end
        OnMessage(msg, channel, who)
    end
end)
