-- Writs/Cooldowns.lua: profession cooldowns on every character of the account (WP.Cooldowns).
--
-- What is followed (the spell ids of Forever's crafting cooldowns): the Arcanite transmute (about
-- 2 days), the elemental transmutes (23 h), Iron to Gold and Mithril to Truesilver (1 h), Mooncloth
-- (about 4 days) and the Salt Shaker, an item (Refined Deeprock Salt, about 3 days).
-- Read with the game's own cooldown of each spell (or of the item) on login, when a profession
-- window opens, when the spells or the bag cooldowns change, and every 60 s. No TRADE_SKILL_UPDATE
-- on Forever. Values hidden in a fight (secret) are skipped: what was stored stays.
--
-- Stored account-wide: WLWritsDB.cooldowns["Realm-Name"][spell] = readyAt (server time(); 0 =
-- known and ready, never seen on cooldown). The Salt Shaker's key is "i15846". WLWritsDB.cdTold
-- remembers which readyAt was already announced, WLWritsDB.cdAlert == false turns the chat line off,
-- WLWritsDB.cdSeen[realm-char][spell] is the last time the spell was seen known or on cooldown.
-- Nothing runs while the Writs module is off, nor until 10 s after login or a loading screen.
--   Rows()            { key, name, realm, mine, group, label, at, left } one per character and
--                     group (the soonest spell of the group), yours first, then by name
--   Left(at) / FormatLeft(sec)   seconds left (0 = ready), and "2 j 4 h" / "2d 4h" ("%d min" is Finder's)
--   Scan() / Tick()   read this character's cooldowns / announce what became ready
--   AlertOn() / SetAlert(v)      the chat line, on by default
local ADDON, root = ...
root.Writs = root.Writs or {}
local ns = root.Writs
local WP = ns.WP
local L = ns.L

ns.AddEnglish({
    ["Recharges"] = "Cooldowns",
    ["Transmutation : Arcanite"] = "Transmute: Arcanite",
    ["Transmutations élémentaires"] = "Elemental transmutes",
    ["Transmutations fer et mithril"] = "Iron and mithril transmutes",
    ["Étoffe lunaire"] = "Mooncloth",
    ["Salière"] = "Salt Shaker",
    ["Prête"] = "Ready",
    ["%d j %d h"] = "%dd %dh",
    ["%d h %d min"] = "%dh %d min",
    ["Recharge prête : %s."] = "Cooldown ready: %s.",
})

local CD = {}
WP.Cooldowns = CD

-- the groups, in display order; alert: a chat line when it is ready (not for the 1 h transmutes)
CD.GROUPS = {
    { key = "arcanite",  label = "Transmutation : Arcanite",      alert = true,  spells = { 17187 } },
    { key = "elemental", label = "Transmutations élémentaires",   alert = true,
      spells = { 17559, 17560, 17561, 17562, 17563, 17564, 17565, 17566 } },
    { key = "metal",     label = "Transmutations fer et mithril", alert = false, spells = { 11479, 11480 } },
    { key = "mooncloth", label = "Étoffe lunaire",                alert = true,  spells = { 18560 } },
    { key = "salt",      label = "Salière",                       alert = true,  item = 15846 },
}
local SALT_KEY = "i15846"
local GROUP_OF = {}            -- [spell key] = group
for i, g in ipairs(CD.GROUPS) do
    g.order = i
    if g.item then GROUP_OF["i" .. g.item] = g end
    for _, id in ipairs(g.spells or {}) do GROUP_OF[id] = g end
end
CD.GROUP_OF = GROUP_OF

local STALE = 60 * 86400       -- an entry ready, and not seen known for this long, is deleted (Prune)
local MIN_CD = 60              -- s: shorter is the global cooldown, not the recipe's

local function Secret(v) return issecretvalue ~= nil and issecretvalue(v) end
local function Str(s) return type(s) == "string" and s ~= "" and not Secret(s) end

local function DB()
    if type(WLWritsDB) ~= "table" then return nil end
    if type(WLWritsDB.cooldowns) ~= "table" then WLWritsDB.cooldowns = {} end
    if type(WLWritsDB.cdTold) ~= "table" then WLWritsDB.cdTold = {} end
    return WLWritsDB.cooldowns, WLWritsDB.cdTold
end

local function Realm()
    local r = (GetRealmName and GetRealmName()) or ""
    return Str(r) and r or ""
end
-- "Realm-Name" of this character, or nil while the name is not known
function CD.MyKey()
    local n = UnitName and UnitName("player")
    if not Str(n) or n == UNKNOWNOBJECT then return nil end
    return Realm() .. "-" .. n
end

function CD.AlertOn() return not (type(WLWritsDB) == "table" and WLWritsDB.cdAlert == false) end
function CD.SetAlert(v) if type(WLWritsDB) == "table" then WLWritsDB.cdAlert = v and true or false end end

-- ---------------------------------------------------------------- reading the game
local function SpellCD(id)
    if C_Spell and C_Spell.GetSpellCooldown then
        local ok, info = pcall(C_Spell.GetSpellCooldown, id)
        if ok and type(info) == "table" then return info.startTime, info.duration end
        if ok then return nil end
    end
    if GetSpellCooldown then
        local ok, s, d = pcall(GetSpellCooldown, id)
        if ok then return s, d end
    end
end
local function ItemCD(id)
    local f = (C_Container and C_Container.GetItemCooldown) or GetItemCooldown
    if not f then return nil end
    local ok, s, d = pcall(f, id)
    if ok then return s, d end
end
-- bank: count the bank too
local function ItemCount(id, bank)
    local f = (C_Item and C_Item.GetItemCount) or GetItemCount
    if not f then return 0 end
    local ok, n = pcall(f, id, bank and true or false)
    if ok and not Secret(n) and type(n) == "number" then return n end
    return 0
end
local function Knows(id)
    if IsPlayerSpell then
        local ok, v = pcall(IsPlayerSpell, id)
        if ok and not Secret(v) and v then return true end
    end
    if IsSpellKnown then
        local ok, v = pcall(IsSpellKnown, id)
        if ok and not Secret(v) and v then return true end
    end
    return false
end

-- the recipes of the open profession window, by the spell id of their link (no TRADE_SKILL_UPDATE
-- on Forever: read on TRADE_SKILL_SHOW)
local function TradeKnown()
    local out = {}
    if not (GetNumTradeSkills and GetTradeSkillRecipeLink) then return out end
    local ok, n = pcall(GetNumTradeSkills)
    if not ok or Secret(n) or type(n) ~= "number" then return out end
    for i = 1, math.min(n, 500) do
        local okL, link = pcall(GetTradeSkillRecipeLink, i)
        if okL and Str(link) then
            local id = tonumber(link:match("enchant:(%d+)") or link:match("spell:(%d+)"))
            if id and GROUP_OF[id] then out[id] = true end
        end
    end
    return out
end

-- seconds left from a (start, duration) pair; nil = hidden (secret), 0 = ready
local function LeftOf(start, dur)
    if Secret(start) or Secret(dur) then return nil end
    start, dur = tonumber(start), tonumber(dur)
    if not (start and dur) or start <= 0 or dur <= MIN_CD then return 0 end
    local now = GetTime and GetTime() or 0
    local left = start + dur - now
    return left > 0 and left or 0
end

-- one spell (or the Salt Shaker) into this character's table; known: the game says he has it
local function Store(mine, key, left, known)
    local now = time()
    local old = mine[key]
    if left == nil then return false end
    if left > 0 then
        local at = math.floor(now + left + 0.5)
        -- the same cooldown read again: a second of drift is not a change
        if old and old > 0 and math.abs(old - at) <= 2 then return false end
        mine[key] = at
        return true
    end
    -- A 0 reading never moves a stored ready time earlier: Classic crafting cooldowns do not end
    -- early, and the game reads 0 during a loading screen or before the server sent the cooldowns.
    if old == nil and known then mine[key] = 0; return true end
    return false
end

-- WLWritsDB.cdSeen[realm-char][spell] = the last time() the spell was seen known or on cooldown
local function SeenDB()
    if type(WLWritsDB) ~= "table" then return nil end
    if type(WLWritsDB.cdSeen) ~= "table" then WLWritsDB.cdSeen = {} end
    return WLWritsDB.cdSeen
end
-- true when an entry is ready and was neither ready nor confirmed in the last STALE seconds (a
-- dropped profession, a deleted character). An entry never confirmed gets STALE from now.
local function Gone(seen, key, spell, at, now)
    local s = seen and seen[key]
    local last = s and tonumber(s[spell])
    if not last and seen then
        s = s or {}; seen[key] = s; s[spell] = now; last = now
    end
    if at > now then return false end
    return now - math.max(at, last or now) > STALE
end

-- Deletes the entries Gone() and the characters left with nothing. -> true when something went
function CD.Prune()
    local db = DB()
    if not db then return false end
    local seen, now, changed = SeenDB(), time(), false
    for key, spells in pairs(db) do
        if type(spells) == "table" then
            for spell, at in pairs(spells) do
                at = tonumber(at)
                if not GROUP_OF[spell] or not at or Gone(seen, key, spell, at, now) then
                    spells[spell] = nil; changed = true
                    if seen and seen[key] then seen[key][spell] = nil end
                end
            end
            if not next(spells) then db[key] = nil; changed = true end
        else
            db[key] = nil; changed = true
        end
    end
    if seen then
        for key, s in pairs(seen) do
            if db[key] == nil or type(s) ~= "table" then seen[key] = nil
            else for spell in pairs(s) do if db[key][spell] == nil then s[spell] = nil end end end
        end
    end
    return changed
end

-- Reads this character's cooldowns. tradeKnown: recipe ids from the open profession window.
-- -> true when something changed
function CD.Scan(tradeKnown)
    local db = DB()
    local me = CD.MyKey()
    if not (db and me) then return false end
    local seen = SeenDB()
    local mine = db[me] or {}
    local changed = false
    local now = time()
    local function Confirm(key)
        if not seen then return end
        seen[me] = seen[me] or {}
        seen[me][key] = now
    end
    for _, g in ipairs(CD.GROUPS) do
        if g.item then
            local n = ItemCount(g.item, true)          -- bags and bank: he still has one
            local inBags = ItemCount(g.item) > 0       -- the item cooldown is only trusted in the bags
            local left = LeftOf(ItemCD(g.item))
            if n > 0 or (left and left > 0) then
                if Store(mine, SALT_KEY, left, inBags) then changed = true end
                if mine[SALT_KEY] ~= nil then Confirm(SALT_KEY) end
            elseif mine[SALT_KEY] and (mine[SALT_KEY] <= now) then
                mine[SALT_KEY] = nil; changed = true   -- the shaker is gone
            end
        else
            for _, id in ipairs(g.spells) do
                local known = Knows(id) or (tradeKnown and tradeKnown[id]) or false
                local left = (known or mine[id] ~= nil) and LeftOf(SpellCD(id)) or nil
                -- not known but on cooldown: he has it (a recipe is not always in the spellbook).
                -- Only for a group of one spell: the transmutes share their cooldown, so the
                -- Arcanite one would put every elemental transmute on cooldown too.
                if left == nil and not known and mine[id] == nil and #g.spells == 1 then
                    local l2 = LeftOf(SpellCD(id))
                    if l2 and l2 > 0 then left = l2 end
                end
                if Store(mine, id, left, known) then changed = true end
                if mine[id] ~= nil and (known or (left and left > 0)) then Confirm(id) end
            end
        end
    end
    if next(mine) then db[me] = mine elseif db[me] then db[me] = nil; changed = true end
    return changed
end

-- ---------------------------------------------------------------- what is shown
function CD.Left(at)
    at = tonumber(at) or 0
    local d = at - time()
    return d > 0 and d or 0
end

function CD.FormatLeft(sec)
    sec = math.max(0, math.floor(tonumber(sec) or 0))
    if sec <= 0 then return L("Prête") end
    local d, h, m = math.floor(sec / 86400), math.floor(sec % 86400 / 3600), math.floor(sec % 3600 / 60)
    if d > 0 then return string.format(L("%d j %d h"), d, h) end
    if h > 0 then return string.format(L("%d h %d min"), h, m) end
    return string.format(L("%d min"), math.max(1, m))
end

local function NameOf(key)
    local realm, name = tostring(key):match("^(.*)%-([^%-]+)$")
    return name or tostring(key), realm or ""
end
CD.NameOf = NameOf

-- One row per character and group: the soonest spell of the group (two elemental transmutes on
-- separate cooldowns: one of them can be done when the soonest is ready).
function CD.Rows()
    local db = DB()
    if not db then return {} end
    local me, now, seen = CD.MyKey(), time(), SeenDB()
    local out = {}
    for key, spells in pairs(db) do
        if type(spells) == "table" then
            local best = {}
            for spell, at in pairs(spells) do
                local g = GROUP_OF[spell]
                at = tonumber(at)
                if g and at and not Gone(seen, key, spell, at, now) then
                    if best[g] == nil or at < best[g] then best[g] = at end
                end
            end
            local name, realm = NameOf(key)
            for g, at in pairs(best) do
                out[#out + 1] = { key = key, name = name, realm = realm, mine = key == me, group = g.key, order = g.order,
                    label = L(g.label), at = at, left = CD.Left(at) }
            end
        end
    end
    table.sort(out, function(a, b)
        if a.mine ~= b.mine then return a.mine end
        if a.key ~= b.key then return a.key < b.key end
        return a.order < b.order
    end)
    return out
end

-- ---------------------------------------------------------------- the chat line
-- Announces once each cooldown that became ready (on any character), in one line. Spells first
-- seen ready (0) are never announced. -> the line said, or nil
function CD.Tick()
    local db, told = DB()
    if not db then return nil end
    pcall(CD.Prune)
    local now = time()
    local parts, seen = {}, {}
    local keys = {}
    for key in pairs(db) do keys[#keys + 1] = key end
    table.sort(keys)
    for _, key in ipairs(keys) do
        local spells = db[key]
        if type(spells) == "table" then
            local t = told[key] or {}
            for spell, at in pairs(spells) do
                local g = GROUP_OF[spell]
                at = tonumber(at)
                if g and at and at > 0 and at <= now and t[spell] ~= at then
                    t[spell] = at
                    if now - at <= STALE and g.alert and not seen[key .. g.key] then
                        seen[key .. g.key] = true
                        parts[#parts + 1] = { order = g.order, key = key,
                            text = L(g.label) .. " (" .. NameOf(key) .. ")" }
                    end
                end
            end
            -- forget what is no longer stored
            for spell in pairs(t) do if spells[spell] == nil then t[spell] = nil end end
            told[key] = next(t) and t or nil
        end
    end
    for key in pairs(told) do if db[key] == nil then told[key] = nil end end
    if #parts == 0 or not CD.AlertOn() then return nil end
    table.sort(parts, function(a, b) if a.key ~= b.key then return a.key < b.key end return a.order < b.order end)
    local list = {}
    for i, p in ipairs(parts) do list[i] = p.text end
    local line = string.format(L("Recharge prête : %s."), table.concat(list, ", "))
    if WP.Print then WP.Print(line) end
    return line
end

-- ---------------------------------------------------------------- events
local function Update(tradeKnown)
    local ok, changed = pcall(CD.Scan, tradeKnown)
    pcall(CD.Tick)
    if ok and changed and WP.RefreshHome then pcall(WP.RefreshHome) end
end
CD.Update = Update

local function On() return not WP.ModuleOn or WP.ModuleOn("writs") end

-- ready: the cooldowns can be trusted. Off from login and during every loading screen, on 10 s
-- after it (its own timer: the other events cannot shorten that wait).
local ready, gen = false, 0
local function Settle(delay)
    ready = false
    gen = gen + 1
    local g = gen
    C_Timer.After(delay, function()
        if g ~= gen then return end
        ready = true
        if On() then Update() end
    end)
end
CD.IsReady = function() return ready end

local queued = false
local function Soon(delay, trade)
    if not ready then return end
    if queued and not trade then return end
    queued = true
    C_Timer.After(delay or 1, function()
        queued = false
        if not (ready and On()) then return end
        local known
        if trade then local ok, k = pcall(TradeKnown); known = ok and k or nil end
        Update(known)
    end)
end

local ticker
local ev = CreateFrame("Frame")
for _, e in ipairs({ "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "LOADING_SCREEN_ENABLED", "LOADING_SCREEN_DISABLED",
    "TRADE_SKILL_SHOW", "SPELLS_CHANGED", "BAG_UPDATE_COOLDOWN" }) do
    pcall(ev.RegisterEvent, ev, e)
end
ev:SetScript("OnEvent", function(self, event)
    if event == "LOADING_SCREEN_ENABLED" then
        ready = false; gen = gen + 1
        return
    elseif event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" or event == "LOADING_SCREEN_DISABLED" then
        Settle(10)
        if event == "PLAYER_LOGIN" and not ticker and C_Timer and C_Timer.NewTicker then
            ticker = C_Timer.NewTicker(60, function()
                if not (ready and On()) then return end
                -- Home is refreshed every time: the times left move every minute
                pcall(CD.Scan)
                pcall(CD.Tick)
                if WP.RefreshHome then pcall(WP.RefreshHome) end
            end)
        end
        return
    end
    if not On() then return end
    if event == "TRADE_SKILL_SHOW" then
        -- the recipe list fills a moment after the window opens: read it then
        Soon(1, true)
    else
        Soon(1)
    end
end)
