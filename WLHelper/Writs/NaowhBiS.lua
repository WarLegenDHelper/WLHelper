-- Writs/NaowhBiS.lua: Naowh Forever's BiS list and stat weights, asked live (WP.NaowhBiS).
--
-- Naowh Forever (all rights reserved) publishes its namespace as _G.NaowhForever; its BiS List
-- addon (NaowhForever_BiS) adds ns.BiS (the player's lists, shared per class, one set of picks per
-- spec) and ns.StatWeights (each spec's weights, the player's own changes kept). Nothing of it is
-- copied here: its functions are called at runtime, every call in a pcall, and everything answers
-- nil when it is not installed, not loaded yet, or switched off.
--   Rank(item [, spec])  1 = BiS, 2 = second pick, n, or nil (the active list, the spec it shows)
--   Label(rank) / Badge(rank)  "BiS" / "2e choix", and the coloured badge with its star
--   Gain(item [, spec])  the percent an item adds by Naowh's weights (signed), or nil + why
--   Custom(key)          the player changed this Naowh spec's weights himself (Naowh keeps only
--                        his changes, per account)
--   WeightsOn([spec]) / TipOn()  one of our specs (default: any spec of the class) has the player's
--                        own Naowh weights / Naowh adds its own tooltip line
--   JudgeKey(spec) / TipShows(key)  the Naowh spec key judging one of our specs (only when the
--                        player changed its weights in Naowh: else WL Helper Gear judges, with
--                        its caps and leveling), and whether Naowh's own tooltip line shows that spec
local ADDON, root = ...
root.Writs = root.Writs or {}
local ns = root.Writs
local WP = ns.WP
local L = ns.L

ns.AddEnglish({
    ["BiS"] = "BiS",
    ["2e choix"] = "2nd pick",
    ["%de choix"] = "#%d pick",
})

local NB = {}
WP.NaowhBiS = NB

local RANK_TTL = 30            -- s: the rank cache is emptied at least this often
local STAR = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:%d:%d:0:0|t"
local RANK_HEX = { "ff8000", "c7ccdb" }   -- BiS orange, second pick silver
local MUTED_HEX = "9d9d9d"

-- ---------------------------------------------------------------- Naowh's tables, when there
local function N()
    local n = rawget(_G, "NaowhForever")
    return type(n) == "table" and n or nil
end
local function BiS()
    local n = N()
    local B = n and n.BiS
    if type(B) == "table" and type(B.Lists) == "table" and type(n.IsBisItem) == "function" then return B, n end
    return nil
end
local function SW()
    local n = N()
    local S = n and n.StatWeights
    if type(S) == "table" and type(S.For) == "function" and type(S.BestGain) == "function"
        and type(S.Power) == "function" and type(S.Settings) == "table" then return S, n end
    return nil
end
local function Now() return (GetTime and GetTime()) or 0 end

-- ---------------------------------------------------------------- change listeners
local listeners = {}
function NB.OnChange(fn) listeners[#listeners + 1] = fn end
local rankCache, rankStamp = {}, 0
local listKeys = {}            -- [spec asked] = list key or false: Naowh's List() is not asked per item
local weighed = {}             -- [key] = { at, weights, power }
local function Changed()
    wipe(rankCache); wipe(listKeys); rankStamp = Now()
    wipe(weighed)
    for i = 1, #listeners do pcall(listeners[i]) end
end
-- Naowh's own callbacks: a list or pick changed (B.OnListChange), weights changed (SW.OnChange),
-- a Stat Weights setting changed (its switches, its spec). Hooked once per Naowh table (the BiS
-- addon may load after us: tried again on each call until it is there).
local hookedB, hookedS
local function Hook()
    local B = BiS()
    if B and hookedB ~= B and type(B.OnListChange) == "function" then
        if pcall(B.OnListChange, Changed) then hookedB = B end
    end
    local S = SW()
    if S and hookedS ~= S then
        local ok = type(S.OnChange) ~= "function" or pcall(S.OnChange, Changed)
        if ok and type(S.Settings.OnChange) == "function" then pcall(S.Settings.OnChange, Changed) end
        hookedS = S
    end
end
NB.Hook = Hook

-- ---------------------------------------------------------------- specs: ours -> Naowh's keys
-- spec: one of WP.Weights.SPECS ({ "frost", "Givre", "Frost", ... }), one of our keys ("frost"),
-- or a Naowh key ("frost-mage"). Naowh's spec names ("Frost", "Feral Tank") are matched to our keys
-- by WP.Weights.SpecKeyFor; when two match (Feral DPS and Feral Tank), Naowh's own choice wins.
local function OurKey(spec)
    if type(spec) == "table" then return spec[1] end
    return spec
end
local function Matches(nspec, our, short)
    if nspec.key == our then return true end
    local W = WP.Weights
    local name = short and short(nspec) or nspec.name
    return W and W.SpecKeyFor and type(name) == "string" and W.SpecKeyFor(name) == our or false
end
local function MatchKey(list, spec, preferred, short)
    local our = OurKey(spec)
    if not our then return preferred end
    if preferred then
        for _, s in ipairs(list) do
            if s.key == preferred and Matches(s, our, short) then return preferred end
        end
    end
    for _, s in ipairs(list) do
        if Matches(s, our, short) then return s.key end
    end
    return nil
end

-- ---------------------------------------------------------------- BiS ranks
function NB.Available()
    local B = BiS()
    if not B then return false end
    Hook()
    local ok, on = pcall(B.On)
    return ok and on == true
end

local function ItemID(item)
    if type(item) == "number" then return item end
    if type(item) ~= "string" then return nil end
    local id = tonumber(item:match("item:(%d+)")) or tonumber(item)
    if id then return id end
    local Instant = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
    return Instant and tonumber((Instant(item))) or nil
end

-- "current" (the spec the active list shows), a BiS spec key, or nil (a spec Naowh has no list for)
local function ListKey(spec)
    if spec == nil then return "current" end
    local B = BiS()
    local R, Ls = B.Rankings, B.Lists
    local cur = Ls.CurrentSpec and Ls.CurrentSpec()
    local short = Ls.SpecShort and function(s) return Ls.SpecShort(s) end
    local key = MatchKey(R.ClassSpecs(), spec, cur and cur.key, short)
    if key and cur and key == cur.key then return "current" end
    return key
end

-- the best rank of an item in the active list's picks for one spec (lists are shared per class:
-- the picks of the other specs are parked in it)
local function RankOn(key, id)
    local B = BiS()
    local list = B.Lists.List()
    local slots, extra = B.Lists.PicksOn(list.id, key)
    if not slots then return nil end
    local best
    for _, pick in pairs(slots) do
        if pick == id then return 1 end
    end
    for _, picks in pairs(extra or {}) do
        for i, pick in ipairs(picks) do
            if pick == id and (not best or i + 1 < best) then best = i + 1 end
        end
    end
    return best
end

-- 1 (BiS), 2 (second pick), n, or nil. spec: optional (ours or Naowh's), else the spec the
-- player's active Naowh list shows.
function NB.Rank(item, spec)
    local id = ItemID(item)
    if not (id and NB.Available()) then return nil end
    if Now() - rankStamp > RANK_TTL then wipe(rankCache); wipe(listKeys); rankStamp = Now() end
    local sk = spec == nil and "" or tostring(OurKey(spec))
    local key = listKeys[sk]
    if key == nil then
        local okK, k = pcall(ListKey, spec)
        key = okK and type(k) == "string" and k or false
        listKeys[sk] = key
    end
    if not key then return nil end
    local ck = key .. ":" .. id
    local c = rankCache[ck]
    if c ~= nil then return c or nil end
    local ok, rank
    if key == "current" then
        local _, n = BiS()
        ok, rank = pcall(n.IsBisItem, id)
    else
        ok, rank = pcall(RankOn, key, id)
    end
    rank = ok and type(rank) == "number" and rank or nil
    rankCache[ck] = rank or false
    return rank
end

function NB.Label(rank)
    if rank == 1 then return L("BiS") end
    if rank == 2 then return L("2e choix") end
    if type(rank) == "number" then return string.format(L("%de choix"), rank) end
    return nil
end

-- "|cffff8000BiS|r [star]", "|cffc7ccdb2e choix|r", a muted "#3 pick"; nil without a rank
function NB.Badge(rank, size)
    local label = NB.Label(rank)
    if not label then return nil end
    local hex = RANK_HEX[rank] or MUTED_HEX
    local text = "|cff" .. hex .. label .. "|r"
    if rank == 1 then
        size = size or 12
        text = text .. " " .. STAR:format(size, size)
    end
    return text
end

-- r, g, b of a rank (for a badge drawn as a FontString)
function NB.Color(rank)
    local hex = RANK_HEX[rank] or MUTED_HEX
    return tonumber(hex:sub(1, 2), 16) / 255, tonumber(hex:sub(3, 4), 16) / 255, tonumber(hex:sub(5, 6), 16) / 255
end

-- ---------------------------------------------------------------- stat weights
-- Naowh's weights (MythicSim level 60 sims, no hit or defense cap, no leveling) judge a spec only
-- when the player changed that spec's weights himself in Naowh: Naowh stores only his changes
-- (account settings, statWeights[key][stat]) and answers SW.Changed(key, stat) for each of its
-- SW.STATS. Its tooltip and marks switches no longer decide: without changes, WL Helper Gear judges.
local function HasChanges(S, n, key)
    if type(S.Changed) == "function" and type(S.STATS) == "table" then
        for _, st in ipairs(S.STATS) do
            local stat = type(st) == "table" and st[1] or st
            if stat ~= nil and S.Changed(key, stat) then return true end
        end
        return false
    end
    -- an older Naowh without Changed: its stored changes table, read only
    local acc = type(n.AccountSettings) == "function" and n.AccountSettings()
    local changes = type(acc) == "table" and acc.statWeights
    local mine = type(changes) == "table" and changes[key]
    return type(mine) == "table" and next(mine) ~= nil
end

-- true when the player changed this Naowh spec key's weights himself
function NB.Custom(key)
    if type(key) ~= "string" then return false end
    local S, n = SW()
    if not S then return false end
    Hook()
    local ok, yes = pcall(HasChanges, S, n, key)
    return ok and yes == true
end

-- Naowh adds its own upgrade line on item tooltips
function NB.TipOn()
    local S = SW()
    if not S then return false end
    local ok, on = pcall(function() return S.Settings.Get("enabled") == true end)
    return ok and on == true
end

-- Naowh's active spec key (its "Your Spec" choice, or its talents)
function NB.ActiveKey()
    local S = SW()
    if not S or type(S.ActiveSpec) ~= "function" then return nil end
    local ok, key = pcall(S.ActiveSpec)
    return ok and key or nil
end

-- the Naowh key that judges one of our specs: the matching Naowh spec whose weights the player
-- changed himself (Naowh's own choice first when two match, as Feral DPS and Feral Tank), else nil
function NB.JudgeKey(spec)
    local S = SW()
    if not (S and spec) then return nil end
    Hook()
    local ok, key = pcall(function()
        local list = S.ClassSpecs()
        local key = MatchKey(list, spec, NB.ActiveKey())
        if key and NB.Custom(key) then return S.For(key) and key or nil end
        -- another Naowh spec matching the same one of ours, with the player's changes
        local our = OurKey(spec)
        for _, s in ipairs(list) do
            if s.key ~= key and Matches(s, our) and NB.Custom(s.key) then return S.For(s.key) and s.key or nil end
        end
        return nil
    end)
    return ok and key or nil
end

-- one of our specs (or, without one, any spec of the class) is judged by the player's Naowh weights
function NB.WeightsOn(spec)
    local S = SW()
    if not S then return false end
    if spec ~= nil then return NB.JudgeKey(spec) ~= nil end
    local ok, any = pcall(function()
        for _, s in ipairs(S.ClassSpecs()) do
            if NB.Custom(s.key) and S.For(s.key) then return true end
        end
        return false
    end)
    return ok and any == true
end

-- Naowh's own tooltip line is for this key: ours would repeat it
function NB.TipShows(key)
    return key ~= nil and NB.TipOn() and NB.ActiveKey() == key
end

-- weights and power of a key, asked once per frame (power reads what you wear)
local function Weighed(S, key)
    local w = weighed[key]
    local now = Now()
    if w and w.at == now then return w.weights, w.power end
    local weights = S.For(key)
    local power = weights and S.Power(weights)
    weighed[key] = { at = now, weights = weights, power = power }
    return weights, power
end

-- The percent an item adds by Naowh's weights for a spec (default: Naowh's active spec): Naowh's
-- best slot when it is an upgrade (its own minimum), else the best slot's signed percent.
-- nil + why: "absent", "nospec", "notgear", "unusable", "loading" (item or stats not loaded),
-- "nopower" (Naowh cannot read your stats now: secret stats before it ever read them), "error".
-- When Naowh's BestGain says no upgrade, the percent stays below its minimum (never an arrow
-- Naowh would not give).
function NB.Gain(item, spec)
    local S, n = SW()
    if not S then return nil, "absent" end
    Hook()
    local ok, g, why = pcall(function()
        local key
        if spec == nil then key = NB.ActiveKey()
        elseif type(spec) == "string" and type(S.Spec) == "function" and S.Spec(spec) then key = spec
        else key = MatchKey(S.ClassSpecs(), spec, NB.ActiveKey()) end
        if not key then return nil, "nospec" end
        local weights, power = Weighed(S, key)
        if not weights then return nil, "nospec" end
        if type(power) ~= "number" or not (power > 0) then return nil, "nopower" end
        local id = ItemID(item)
        if not id then return nil, "loading" end
        local link = type(item) == "string" and item:find("item:", 1, true) and item or nil
        local Items = n.Shared and n.Shared.Items
        local slots = Items and Items.SlotsFor and Items.SlotsFor(id)
        if not slots then return nil, "notgear" end
        if S.Stats and S.Stats(link or id) == nil then return nil, "loading" end
        local best = S.BestGain(id, link, weights, power)
        if best then return best end
        if S.Usable then
            local usable = S.Usable(id, link)
            if usable == false then return nil, "unusable" end
            if usable == nil then return nil, "loading" end
        end
        local top
        local twoHand = Items.IsTwoHand and Items.IsTwoHand(id)
        local main = GetInventoryItemID and GetInventoryItemID("player", 16)
        local wornTwoHand = main and Items.IsTwoHand and Items.IsTwoHand(main)
        for _, slot in ipairs(slots) do
            -- the other hand counted as Naowh does: a two-hander frees the off hand, an off hand
            -- replaces a worn two-hander
            local also = (slot == 16 and twoHand and 17) or (slot == 17 and wornTwoHand and 16) or nil
            local g = S.Gain(link or id, slot, weights, power, also)
            if type(g) == "number" and (not top or g > top) then top = g end
        end
        if top == nil then return nil, "loading" end
        -- Naowh said no upgrade (BestGain nil): below its 0.5 % minimum, whatever our simpler sum says
        if top > 0.49 then top = 0.49 end
        return top
    end)
    if not ok then return nil, "error" end
    return g, why
end

local ev = CreateFrame("Frame")
pcall(ev.RegisterEvent, ev, "PLAYER_LOGIN")
ev:SetScript("OnEvent", function() pcall(Hook) end)
