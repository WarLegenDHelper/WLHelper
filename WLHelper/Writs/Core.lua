-- Writs/Core.lua: prices, daily status, reputation and the buying plan for the Craftsman's Writs.
local ADDON, root = ...
-- The Writs module of WL Helper keeps its own table inside the addon's namespace.
root.Writs = root.Writs or {}
local ns = root.Writs
local L = ns.L
local WP = {}
ns.WP = WP
_G.WLWrits = WP

local CALLER = "WLHelper"
WP.NAME = "WL Helper"
local SECONDS_PER_DAY = 86400
local FACTION_HINT = "Supply and Logistics"
local COIN_POUCHES = { 284583, 284584, 284585, 284586 }   -- the writs' reward bags

-- Lowest level a zone is comfortable at; turn-in spots in zones above your level are hidden on request.
-- Searing Gorge counts as 48: from the Horde side you reach it through Burning Steppes.
local ZONE_MIN = {
    [1413] = 10, [1442] = 15, [1440] = 18, [1431] = 18, [1437] = 20, [1424] = 20, [1441] = 25,
    [1416] = 30, [1417] = 30, [1443] = 30, [1434] = 30, [1418] = 35, [1435] = 35, [1445] = 35,
    [1446] = 40, [1425] = 40, [1444] = 40, [1427] = 48, [1448] = 48, [1449] = 48, [1450] = 48,
    [1430] = 50, [1422] = 51, [1452] = 53,
}
local ZONE_NAME = {
    [1413] = "The Barrens", [1416] = "Alterac Mountains", [1417] = "Arathi Highlands", [1418] = "Badlands",
    [1422] = "Western Plaguelands", [1424] = "Hillsbrad Foothills", [1425] = "The Hinterlands",
    [1427] = "Searing Gorge", [1430] = "Deadwind Pass", [1431] = "Duskwood", [1434] = "Stranglethorn Vale",
    [1435] = "Swamp of Sorrows", [1437] = "Wetlands", [1440] = "Ashenvale", [1441] = "Thousand Needles",
    [1442] = "Stonetalon Mountains", [1443] = "Desolace", [1444] = "Feralas", [1445] = "Dustwallow Marsh",
    [1446] = "Tanaris", [1448] = "Felwood", [1449] = "Un'Goro Crater", [1450] = "Moonglade", [1452] = "Winterspring",
}
-- French names; read them through WP.Tier and WP.Reaction, which translate at the time of use.
WP.TIER_FR = { Journeyman = "Compagnon", Expert = "Expert", Artisan = "Artisan" }
function WP.Tier(t) return L(WP.TIER_FR[t] or t) end

local DEFAULTS = {
    pouch = 10000,           -- what a Coin Pouch is worth, in copper, until one is measured
    usePouchMeasured = true,
    autoRescan = true,
    -- GPS: provider "auto" (Zygor when its travel system is on, else ours) | "wl" | "zygor"
    gpsOpts = { provider = "auto", teleports = true, autoFlight = false, scale = 1, alpha = 0, hideCombat = false },
    -- Comptoir comforts
    comfort = { autoTurnIn = true, autoAccept = true, reminder = true, tooltip = true, autoCrates = true },
    modules = { dungeons = true, writs = true, bags = true, orders = true, upgrades = true, guild = true, events = true },   -- Settings > General > Modules       -- rescan the shopping list when the auction house opens
    tiers = { Journeyman = true, Expert = true, Artisan = true },
    hideHigh = true,         -- hide turn-in spots in zones above your level
    hideUnknown = false,     -- hide writs whose turn-in spot is unknown
    hideDone = false,        -- hide writs already turned in today
    goal = 0,                -- 0 = next standing, otherwise a reaction (5 Friendly, 6 Honored, 7 Revered)
    maxPer100 = 4000,        -- plan skips writs whose net cost (after the Coin Pouch) passes this per 100 rep; 0 = no cap
    sort = "per100", sortDesc = false,
    pouchSamples = {},       -- copper found in recent Coin Pouches, any kind
    pouchById = {},          -- [pouch item ID] = { copper, ... }
    pouchOfTier = {},        -- [writ tier] = pouch item ID it gives
}

local function CopyDefaults(dst, src)
    for k, v in pairs(src) do
        if dst[k] == nil then
            if type(v) == "table" then dst[k] = {}; CopyDefaults(dst[k], v) else dst[k] = v end
        elseif type(v) == "table" and type(dst[k]) == "table" then
            CopyDefaults(dst[k], v)
        end
    end
end

-- ---------------------------------------------------------------- helpers

local function safe(f, ...)
    if not f then return nil end
    local ok, a, b, c = pcall(f, ...)
    if ok then return a, b, c end
end

local GetItemCountFn = (C_Item and C_Item.GetItemCount) or GetItemCount
local function BagCount(id)
    return safe(GetItemCountFn, id) or 0
end
-- Bags and bank (the game knows the bank once you opened it, like Naowh's counts): what you own.
local function OwnedCount(id)
    return safe(GetItemCountFn, id, true) or BagCount(id)
end
function WP.OwnedCount(id) return OwnedCount(id) end
function WP.InBank(id) return math.max(0, OwnedCount(id) - BagCount(id)) end

local nameCache = {}
function WP.ItemName(id, fallback)
    local name = nameCache[id]
    if name then return name end
    name = safe(C_Item and C_Item.GetItemNameByID, id) or safe(GetItemInfo, id)
    if name then nameCache[id] = name; return name end
    return fallback or ("item:" .. id)
end

local zoneNames = {}   -- a zone's name never changes: asked once
function WP.ZoneName(map)
    if not map then return "?" end
    local n = zoneNames[map]
    if n then return n end
    local info = safe(C_Map and C_Map.GetMapInfo, map)
    n = (info and info.name) or ZONE_NAME[map]
    if n then zoneNames[map] = n end
    return n or tostring(map)
end

function WP.ZoneMin(map) return map and ZONE_MIN[map] end

-- Day index that changes at the daily reset.
function WP.Today()
    local left = safe(C_DateAndTime and C_DateAndTime.GetSecondsUntilDailyReset) or safe(GetQuestResetTime) or 0
    -- Half a day of margin: the reset time read back can be a second off either way.
    return math.floor((GetServerTime() + left + SECONDS_PER_DAY / 2) / SECONDS_PER_DAY)
end

function WP.SecondsToReset()
    return safe(C_DateAndTime and C_DateAndTime.GetSecondsUntilDailyReset) or safe(GetQuestResetTime) or 0
end

-- ---------------------------------------------------------------- prices

-- Returns copper, source label, age in days (Auctionator only).
local SCAN_FRESH = 6 * 3600   -- the addon's own scan beats every other source for this long
local ABSENT_FRESH = 30 * 60  -- "not for sale" is believed for half an hour, then other sources speak

-- Returns copper, source, age in days, quantity listed (own scan only).
function WP.Price(itemID, snapshot)
    local p, q, ago
    if WP.Scan then p, q, ago = WP.Scan.Get(itemID) end
    if ago then
        if p and q > 0 and ago < SCAN_FRESH then return p, "Scan", 0, q end
        if q == 0 and ago < ABSENT_FRESH then return nil, "Absent", 0, 0 end   -- scanned, not for sale
    end
    local A = Auctionator and Auctionator.API and Auctionator.API.v1
    if A and A.GetAuctionPriceByItemID then
        local p = safe(A.GetAuctionPriceByItemID, CALLER, itemID)
        if p and p > 0 then
            local age = A.GetAuctionAgeByItemID and safe(A.GetAuctionAgeByItemID, CALLER, itemID)
            return p, "Auctionator", age
        end
    end
    if TSM_API and TSM_API.GetCustomPriceValue then
        local p = safe(TSM_API.GetCustomPriceValue, "first(dbminbuyout, dbmarket, dbregionsaleavg)", "i:" .. itemID)
        if p and p > 0 then return p, "TSM" end
    end
    if snapshot and snapshot > 0 then return snapshot, L("Instantané") end
    return nil, L("aucun prix")
end

local function Average(list)
    if type(list) ~= "table" or #list == 0 then return nil, 0 end
    local sum = 0
    for _, v in ipairs(list) do sum = sum + v end
    return math.floor(sum / #list), #list
end

-- What a writ's Coin Pouch is worth. Each writ tier seems to give its own pouch (four pouch items
-- exist): the pouch a tier gives is learned at turn-in, and its value from the pouches you open.
-- Returns copper, number of samples, and whether the value is measured for this very tier.
function WP.PouchValue(tier)
    local db = WLWritsDB
    if db.usePouchMeasured then
        local id = tier and db.pouchOfTier[tier]
        local v, n = Average(id and db.pouchById[id])
        if v then return v, n, true end
        v, n = Average(db.pouchSamples)
        if v then return v, n, false end   -- pouches of any kind: better than a guess
    end
    return db.pouch or 0, 0, false
end

-- ---------------------------------------------------------------- quest state

local function QuestLogIndex(q)
    if C_QuestLog and C_QuestLog.GetLogIndexForQuestID then
        local i = safe(C_QuestLog.GetLogIndexForQuestID, q)
        if i and i > 0 then return i end
        return nil
    end
    local i = safe(GetQuestLogIndexByID, q)
    if i and i > 0 then return i end
end

local function QuestComplete(q, index)
    if C_QuestLog and C_QuestLog.IsComplete then
        local c = safe(C_QuestLog.IsComplete, q)
        if c ~= nil then return c end
    end
    if index and GetQuestLogTitle then
        local _, _, _, _, _, isComplete = safe(GetQuestLogTitle, index)
        return isComplete == 1 or isComplete == true
    end
    return false
end

-- WP.Rows asks for 150 writs in a row: the day index is read once per second at most.
local todayCache, todayAt = nil, -1
local function TodayFast()
    local t = GetTime()
    if t - todayAt >= 1 then todayCache, todayAt = WP.Today(), t end
    return todayCache
end

local function DoneToday(q)
    if not q then return false end
    if WLWritsCharDB.turnedIn[q] == TodayFast() then return true end
    local f = (C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted) or IsQuestFlaggedCompleted
    return safe(f, q) == true
end

-- State of one writ: "done", "ready", "log", "bag" or "buy".
function WP.State(w)
    if DoneToday(w.quest) then return "done" end
    local index = w.quest and QuestLogIndex(w.quest)
    if index then return QuestComplete(w.quest, index) and "ready" or "log" end
    if BagCount(w.writ) > 0 then return "bag" end
    return "buy"
end

-- ---------------------------------------------------------------- reputation

local function FactionByIndex(i)
    if C_Reputation and C_Reputation.GetFactionDataByIndex then
        local d = safe(C_Reputation.GetFactionDataByIndex, i)
        if d then return d.name, d.factionID, d.isHeader, d.isCollapsed end
        return nil
    end
    local name, _, _, _, _, _, _, _, isHeader, isCollapsed, _, _, _, factionID = safe(GetFactionInfo, i)
    return name, factionID, isHeader, isCollapsed
end

local function FindFaction()
    local n = safe(C_Reputation and C_Reputation.GetNumFactions) or safe(GetNumFactions) or 0
    for i = 1, n do
        local name, id = FactionByIndex(i)
        if name and id and name:find(FACTION_HINT, 1, true) then return id end
    end
end

-- Returns name, reaction (4 Neutral, 5 Friendly...), value inside the standing, standing size, total.
function WP.Reputation()
    local db = WLWritsCharDB   -- per character: Horde and Alliance have their own company
    -- 2587 is Durotar Supply and Logistics (Horde); the name search covers the Alliance company.
    if not db.factionID and UnitFactionGroup("player") == "Horde" then db.factionID = 2587 end
    db.factionID = db.factionID or FindFaction()
    local id = db.factionID
    if not id then return nil end
    if C_Reputation and C_Reputation.GetFactionDataByID then
        local d = safe(C_Reputation.GetFactionDataByID, id)
        if d and d.name then
            local lo, hi = d.currentReactionThreshold or 0, d.nextReactionThreshold or 0
            return d.name, d.reaction, (d.currentStanding or 0) - lo, hi - lo, d.currentStanding or 0, hi
        end
    end
    if GetFactionInfoByID then
        local name, _, reaction, lo, hi, value = safe(GetFactionInfoByID, id)
        if name then return name, reaction, value - lo, hi - lo, value, hi end
    end
end

-- Total reputation needed for each reaction, counted from 0 at the start of Neutral.
local REACTION_TOTAL = { [5] = 3000, [6] = 9000, [7] = 21000, [8] = 42000 }
WP.REACTION_FR = { [4] = "Neutre", [5] = "Amical", [6] = "Honoré", [7] = "Révéré", [8] = "Exalté" }
function WP.Reaction(n) return WP.REACTION_FR[n] and L(WP.REACTION_FR[n]) or "?" end

-- Reputation still needed for the goal (or the next standing), and the goal's reaction.
function WP.RepNeeded()
    local name, reaction, _, _, total, nextAt = WP.Reputation()
    if not name then return nil end
    local goal = WLWritsDB.goal or 0
    -- a chosen goal stops there: once reached, nothing more is needed
    if goal > 0 and REACTION_TOTAL[goal] then
        local t = REACTION_TOTAL[goal]
        if t > total then return t - total, goal end
        return 0, goal
    end
    if reaction and reaction >= 8 then return 0, 8 end
    return math.max(0, (nextAt or total) - total), (reaction or 4) + 1
end

-- ---------------------------------------------------------------- the list

-- Builds one row per writ with prices, state and cost per 100 reputation.
function WP.Rows()
    local db = WLWritsDB
    local level = UnitLevel("player") or 1
    local rows = {}
    local mySide = UnitFactionGroup("player") == "Alliance" and 1 or 2
    for _, w in ipairs(ns.WRITS) do
        -- Writs only the other faction can hand in are left out entirely.
        if not w.side or w.side == mySide then
            rows[#rows + 1] = { w = w, state = WP.State(w) }
        end
    end
    -- Items in your bags go to the writs closest to turn-in first, one item per writ,
    -- so two writs asking for the same item never both count it as owned.
    local avail, ORDER = {}, { ready = 1, log = 2, bag = 3, buy = 4, done = 5 }
    local byOrder = {}
    for i, r in ipairs(rows) do byOrder[i] = r end
    table.sort(byOrder, function(a, b)
        if ORDER[a.state] ~= ORDER[b.state] then return ORDER[a.state] < ORDER[b.state] end
        return a.w.writ < b.w.writ
    end)
    for _, r in ipairs(byOrder) do
        local id, n = r.w.item, r.w.count or 1
        if avail[id] == nil then avail[id] = OwnedCount(id) end   -- the bank counts: no need to buy it again
        if r.state == "done" then
            r.ownItem = false
        elseif avail[id] >= n then
            r.ownItem = true
            avail[id] = avail[id] - n
        elseif avail[id] > 0 and r.state ~= "ready" then
            r.ownItem, r.haveItems = false, avail[id]   -- some of a multi-item request in the bags
            avail[id] = 0
        else
            r.ownItem = r.state == "ready"
        end
    end
    for _, r in ipairs(rows) do
        local w = r.w
        r.ownWrit = r.state ~= "buy"
        r.writPrice, r.writSrc, r.writAge, r.writQty = WP.Price(w.writ, w.snapWrit)
        r.itemPrice, r.itemSrc, r.itemAge, r.itemQty = WP.Price(w.item, w.snapItem)
        local cw = r.ownWrit and 0 or r.writPrice
        local ci = (r.ownItem or r.state == "ready") and 0 or (r.itemPrice and r.itemPrice * ((w.count or 1) - (r.haveItems or 0)))
        if cw and ci then
            r.cost = cw + ci
            r.net = r.cost - WP.PouchValue(w.tier)
            r.per100 = r.net / w.rep * 100
        end
        r.zone = WP.ZoneName(w.map)
        r.zoneMin = WP.ZoneMin(w.map)
        r.tooHigh = r.zoneMin and level < r.zoneMin or false
        -- set aside by the player: this writ, or every writ of its zone (never bought by the plan)
        local skip = WLWritsCharDB.skip
        r.skipped = skip and ((skip.writs and skip.writs[w.writ]) or (w.map and skip.zones and skip.zones[w.map])) and true or false
        local show = db.tiers[w.tier]
        if db.hideHigh and r.tooHigh and r.state == "buy" then show = false end
        if db.hideUnknown and not w.map then show = false end
        if db.hideDone and r.state == "done" then show = false end
        r.show = show
    end
    return rows
end

-- Picks the cheapest writs to buy so that pending writs plus the plan reach the goal.
-- Writs already owned count first; each writ is once a day, so the plan never repeats one.
-- Sets a writ (by envelope item ID) or a zone (by map ID) aside, or back in the plan.
function WP.SetSkipped(kind, id, on)
    local db = WLWritsCharDB
    db.skip = db.skip or {}
    db.skip[kind] = db.skip[kind] or {}
    db.skip[kind][id] = on and true or nil
    if WP.Refresh then WP.Refresh() end
end
function WP.IsSkipped(kind, id)
    local s = WLWritsCharDB.skip
    return s and s[kind] and s[kind][id] and true or false
end

-- ---------------------------------------------------------------- budget plan (T-70)
-- With a budget (WLWritsDB.budget, copper; 0 = no limit), the plan is the set of writs that brings
-- the most reputation for the trip it asks, without spending more than the budget:
--   maximise  reputation (up to the goal) - lambda x seconds of travel,  with  gold spent <= budget.
-- The trip is a tree over the turn-in spots: from where you stand to a spot (the GPS's own search:
-- flights, ships, teleports, the Hearthstone), or from a spot already on the tour to the next one
-- (a ride or a flight); writs handed in at one spot share its trip. Lambda comes from the
-- "Prefer" choice (WLWritsDB.budgetPref): reputation, or the least travel.
-- Greedy (the best reputation per gold among single writs and whole groups at a new spot), then a
-- local improvement (drop a spot, fill again, keep it when the result is better).
WP.BUDGET_LAMBDA = { rep = 0.1, trip = 1 }   -- reputation points one second of travel is worth
WP.BUDGET_STEPS = { 10000, 30000, 100000 }   -- the budget's quick choices: 1, 3 and 10 gold

local FROM_YOU_FRESH = 20                     -- seconds the GPS's times from you stay valid
local UNREACHABLE = 600                       -- a spot the GPS cannot price: ten minutes
local fromYou = { at = -1000, sig = nil, out = {} }

local function SpotKey(w)
    return w.map .. ":" .. math.floor((w.x or 0) + 0.5) .. ":" .. math.floor((w.y or 0) + 0.5)
end

-- Seconds from where you stand to each spot, in one GPS search (cached a few seconds).
local function SecondsFromYou(spots)
    local G = WP.GPS
    if not (G and G.CostsTo) then return {} end
    local keys = {}
    for i, s in ipairs(spots) do keys[i] = s.key end
    local sig = table.concat(keys, ",")
    local now = (GetTime and GetTime()) or 0
    if fromYou.sig == sig and now - fromYou.at < FROM_YOU_FRESH then return fromYou.out end
    -- no router in combat: the last times stay (whatever their age), or every spot waits unpriced
    -- until the fight ends (PLAYER_REGEN_ENABLED refreshes the window)
    if InCombatLockdown and InCombatLockdown() then
        return fromYou.sig == sig and fromYou.out or {}
    end
    local dests, idx, out = {}, {}, {}
    for i, s in ipairs(spots) do
        if s.p then dests[#dests + 1] = { cont = s.p.cont, wx = s.p.wx, wy = s.p.wy, map = s.map, kind = "dest" }; idx[#dests] = i end
    end
    if #dests > 0 then
        local ok, costs = pcall(G.CostsTo, dests)
        if ok and type(costs) == "table" then
            for j, t in pairs(costs) do if idx[j] and type(t) == "number" then out[idx[j]] = t end end
        end
    end
    -- no position (an instance, a loading screen): keep the last good times for these spots
    if not next(out) and fromYou.sig == sig and next(fromYou.out) then return fromYou.out end
    fromYou.at, fromYou.sig, fromYou.out = now, sig, out
    return out
end
function WP._BudgetResetCache() fromYou.at, fromYou.sig, fromYou.out = -1000, nil, {} end

-- Seconds from spot a to spot b once a is on the tour: a ride or a flight on one continent,
-- else the way from where you stand (a ship or a teleport).
local function Hop(a, b, speed)
    local pa, pb = a.p, b.p
    if pa and pb and pa.cont == pb.cont then
        local dx, dy = pa.wx - pb.wx, pa.wy - pb.wy
        local d = math.sqrt(dx * dx + dy * dy)
        local ride = d * 1.3 / speed
        local fly = d * 1.25 / 30 + 20 + 40     -- the flight, its stop, and the rides to and from the masters
        return math.min(ride, fly, b.t0)
    end
    if not (pa and pb) and a.map == b.map then return 30 end
    return b.t0
end

-- Seconds of a tour through these spots: the tree that joins them to you at the least cost.
local function TreeSeconds(list, speed)
    local n = #list
    if n == 0 then return 0 end
    local inTree, best, total = {}, {}, 0
    for i = 1, n do best[i] = list[i].t0 end
    for _ = 1, n do
        local u, bu = nil, math.huge
        for i = 1, n do if not inTree[i] and best[i] < bu then u, bu = i, best[i] end end
        if not u then break end
        inTree[u] = true
        total = total + bu
        for i = 1, n do
            if not inTree[i] then
                local h = Hop(list[u], list[i], speed)
                if h < best[i] then best[i] = h end
            end
        end
    end
    return total
end

-- cands: rows the plan may buy (each with .w, .writPrice, .itemPrice, .ownItem, .haveItems, .cost);
-- o = { budget = copper, lambda, left = reputation still wanted, fixed = rows to hand in anyway,
--       taken = { [itemID] = units already bought for them } }.
-- Returns the chosen rows (in tour order), and { cost, rep, seconds, spots }.
function WP.BudgetPick(cands, o)
    local lambda, left0 = o.lambda or WP.BUDGET_LAMBDA.rep, o.left or math.huge
    local speed = ((UnitLevel and UnitLevel("player")) or 1) >= 40 and 11.2 or 7
    local G = WP.GPS
    -- the spots: every turn-in place, the fixed ones (writs you hand in anyway) and the candidates'
    local spots, byKey = {}, {}
    local function spotOf(w)
        local k = SpotKey(w)
        local s = byKey[k]
        if not s then
            local p
            if G and G.Point and w.x and w.y then
                local ok, v = pcall(G.Point, w.map, w.x, w.y)
                if ok and type(v) == "table" then p = v end
            end
            s = { key = k, map = w.map, p = p, writs = {} }
            byKey[k] = s
            spots[#spots + 1] = s
        end
        return s
    end
    for _, r in ipairs(o.fixed or {}) do spotOf(r.w).fixed = true end
    for _, r in ipairs(cands) do local s = spotOf(r.w); s.writs[#s.writs + 1] = r end
    table.sort(spots, function(a, b) return a.key < b.key end)
    local t0 = SecondsFromYou(spots)
    for i, s in ipairs(spots) do s.t0 = t0[i] or UNREACHABLE end
    -- inside a spot, the most reputation per gold first
    for _, s in ipairs(spots) do
        table.sort(s.writs, function(a, b)
            local ra, rb = a.w.rep / math.max(1, a.cost or 1), b.w.rep / math.max(1, b.cost or 1)
            if ra ~= rb then return ra > rb end
            return a.w.writ < b.w.writ
        end)
    end

    -- What k more units of an item cost after `have` (the price ladder when the auction house
    -- gave one: the sixth crate costs more than the first). Asked once per item, not per trial.
    local ladder, inBank = {}, {}
    local CostFor = WP.CostFor
    for _, r in ipairs(cands) do
        local w = r.w
        for _, x in ipairs({ w.writ, w.item }) do
            if ladder[x] == nil then ladder[x] = (CostFor and WP.Ladder and WP.Ladder(x)) and true or false end
        end
        if inBank[w.writ] == nil then inBank[w.writ] = (WP.InBank and WP.InBank(w.writ) > 0) or false end
    end
    local function Units(id, price, have, k)
        if k <= 0 then return 0 end
        if ladder[id] then
            local a = CostFor(id, have + k)
            -- a fresh ladder with nothing for sale: this item cannot be bought now
            if a == nil then return nil end
            local b = CostFor(id, have)
            if b then return a - b end
        end
        return price and price * k or nil
    end
    -- What a writ costs to buy now, given the units already taken; adds its units to `taken`.
    local function WritCost(r, taken)
        local w = r.w
        local env = 0
        if not inBank[w.writ] then
            env = Units(w.writ, r.writPrice, taken[w.writ] or 0, 1)
        end
        local n = r.ownItem and 0 or ((w.count or 1) - (r.haveItems or 0))
        local item = Units(w.item, r.itemPrice, taken[w.item] or 0, n)
        if not env or not item then return nil end
        taken[w.writ] = (taken[w.writ] or 0) + 1
        taken[w.item] = (taken[w.item] or 0) + n
        return env + item
    end
    local function Copy(t) local c = {}; for k, v in pairs(t) do c[k] = v end; return c end

    -- One run of the greedy from a starting choice; `banned` spots are not used.
    local function Run(start, banned)
        local st = { chosen = {}, order = {}, taken = Copy(o.taken or {}), spent = 0, rep = 0, onTour = {}, hop = {} }
        local tour = {}
        local layer = { __index = st.taken }   -- a trial's units sit over the plan's, without a copy
        st.joinHop = {}
        local function join(s)
            if st.onTour[s] then return end
            st.joinHop[s] = st.hop[s] or s.t0
            st.onTour[s] = true
            tour[#tour + 1] = s
            for _, x in ipairs(spots) do
                if not st.onTour[x] then
                    local h = Hop(s, x, speed)
                    if h < (st.hop[x] or x.t0) then st.hop[x] = h end
                end
            end
        end
        for _, s in ipairs(spots) do if s.fixed then join(s) end end
        local function take(r, c)
            st.chosen[r] = true
            st.order[#st.order + 1] = r
            st.spent = st.spent + c
            st.rep = st.rep + r.w.rep
        end
        for _, r in ipairs(start or {}) do
            local c = WritCost(r, st.taken)
            if c and st.spent + c <= o.budget then take(r, c); join(spotOf(r.w)) end
        end
        while st.rep < left0 do
            local best
            for _, s in ipairs(spots) do
                if not (banned and banned[s]) then
                    local travel = st.onTour[s] and 0 or (st.hop[s] or s.t0)
                    local overlay = setmetatable({}, layer)
                    local cost, rep = 0, 0
                    local picks = {}
                    for _, r in ipairs(s.writs) do
                        if not st.chosen[r] then
                            -- a writ too dear for what is left is skipped, not the end of the spot:
                            -- a cheaper one after it may still fit (its units are tried apart)
                            local trial = setmetatable({}, { __index = overlay })
                            local c = WritCost(r, trial)
                            if c and st.spent + cost + c <= o.budget then
                                for k, v in pairs(trial) do overlay[k] = v end
                                cost, rep = cost + c, rep + r.w.rep
                                picks[#picks + 1] = r
                                local gain = math.min(rep, left0 - st.rep) - lambda * travel
                                if gain > 0 then
                                    local ratio = gain / math.max(cost, 1)
                                    if not best or ratio > best.ratio then
                                        local list = {}; for j = 1, #picks do list[j] = picks[j] end
                                        best = { s = s, picks = list, ratio = ratio }
                                    end
                                end
                                if st.rep + rep >= left0 then break end
                            end
                        end
                    end
                end
            end
            if not best then break end
            for _, r in ipairs(best.picks) do
                if not st.chosen[r] then take(r, WritCost(r, st.taken)) end
            end
            join(best.s)
        end
        st.tour = tour
        st.seconds = TreeSeconds(tour, speed)
        st.score = math.min(st.rep, left0) - lambda * st.seconds
        return st
    end

    local best = Run(nil, nil)
    -- local improvement: leave out one spot of the plan and fill again, the weakest spots first
    -- (reputation for its trip and gold); two rounds of six tries at most, so it stays quick
    local rounds, improved = 0, true
    while improved and rounds < 2 do
        improved, rounds = false, rounds + 1
        local worth, list = {}, {}
        for _, r in ipairs(best.order) do
            local s = spotOf(r.w)
            local x = worth[s] or { rep = 0, cost = 0 }
            worth[s] = x
            x.rep, x.cost = x.rep + r.w.rep, x.cost + (r.cost or 0)
        end
        for s, x in pairs(worth) do
            if not s.fixed then
                x.v = (x.rep - lambda * (best.joinHop[s] or s.t0)) / math.max(1, x.cost)
                list[#list + 1] = s
            end
        end
        table.sort(list, function(a, b)
            if worth[a].v ~= worth[b].v then return worth[a].v < worth[b].v end
            return a.key < b.key
        end)
        for i, s in ipairs(list) do
            if i > 6 then break end
            do
                local keep = {}
                for _, r in ipairs(best.order) do if spotOf(r.w) ~= s then keep[#keep + 1] = r end end
                local alt = Run(keep, { [s] = true })
                if alt.score > best.score + 0.01 or (math.abs(alt.score - best.score) <= 0.01 and alt.spent < best.spent) then
                    best, improved = alt, true
                    break
                end
            end
        end
    end
    -- the chosen writs, spot by spot in the order the tour reached them
    local out = {}
    for _, s in ipairs(best.tour) do
        for _, r in ipairs(best.order) do if spotOf(r.w) == s then out[#out + 1] = r end end
    end
    return out, { cost = best.spent, rep = best.rep, seconds = best.seconds, spots = #best.tour }
end

function WP.Plan(rows)
    local need = WP.RepNeeded()
    local plan, pending, readyRep, zones = {}, 0, 0, {}
    WP.budgetInfo = nil
    if not need then return plan, nil, 0, 0, zones end
    -- Zones on the route, in the order given: those with writs ready first (most reputation
    -- first), then the ones the plan adds, in the order it adds them.
    local visited, route, zoneRep = {}, {}, {}
    local function visit(map)
        if not visited[map] then visited[map] = true; route[#route + 1] = map end
    end
    for _, r in ipairs(rows) do
        if r.state == "ready" or r.state == "log" or r.state == "bag" then
            -- Only writs you can hand in now count: a ready writ for a zone above your level waits.
            if r.w.map and not r.tooHigh then
                pending = pending + r.w.rep
                if r.state == "ready" then readyRep = readyRep + r.w.rep end
                zoneRep[r.w.map] = (zoneRep[r.w.map] or 0) + r.w.rep
            end
        end
    end
    local startZones = {}
    for map in pairs(zoneRep) do startZones[#startZones + 1] = map end
    table.sort(startZones, function(a, b)
        if zoneRep[a] ~= zoneRep[b] then return zoneRep[a] > zoneRep[b] end
        return a < b
    end)
    for _, map in ipairs(startZones) do visit(map) end
    local left = need - pending
    if left <= 0 then return plan, need, pending, readyRep, WP.ZoneList(route) end

    -- Candidates by zone, cheapest first inside each zone.
    local cap = (WLWritsDB.maxPer100 or 0) > 0 and WLWritsDB.maxPer100 or nil
    local byZone
    local function build()
        byZone = {}
        for _, r in ipairs(rows) do
            -- r.skipped covers the writs and the zones you left out (Shopping tab, right-click, settings)
            local pick = r.show and r.state == "buy" and r.per100 and r.w.map and not r.tooHigh and not r.skipped
                and (not cap or r.per100 <= cap)
            if pick then
                local z = byZone[r.w.map] or {}
                byZone[r.w.map] = z
                z[#z + 1] = r
            end
        end
        for _, z in pairs(byZone) do table.sort(z, function(a, b) return a.per100 < b.per100 end) end
    end

    local function take(map)
        for _, r in ipairs(byZone[map] or {}) do
            if left <= 0 then break end
            r.inPlan = true
            plan[#plan + 1] = r
            left = left - r.w.rep
        end
        byZone[map] = nil
        visit(map)
    end
    local function fill()
        -- Zones you already have to visit come first: their writs cost no extra trip.
        for _, map in ipairs(startZones) do if byZone[map] then take(map) end end
        -- Then the fewest extra zones: the zone that covers the most of what is left, cheapest on ties.
        while left > 0 do
            local best, bestRep, bestCost
            for map, z in pairs(byZone) do
                local rep, cost = 0, 0
                for _, r in ipairs(z) do
                    if rep >= left then break end
                    rep = rep + r.w.rep
                    cost = cost + r.net
                end
                local covered = math.min(rep, left)
                if not best or covered > bestRep or (covered == bestRep and (cost < bestCost
                    or (cost == bestCost and map < best))) then
                    best, bestRep, bestCost = map, covered, cost
                end
            end
            if not best then break end
            take(best)
        end
    end
    build()
    local budget = tonumber(WLWritsDB.budget) or 0
    if budget > 0 then
        -- the writs you hand in anyway: their trip is paid, and the items still missing for those in
        -- your quest log come out of the budget first (the Shopping tab buys them too)
        local fixed, taken, committed = {}, {}, 0
        for _, r in ipairs(rows) do
            if (r.state == "ready" or r.state == "log" or r.state == "bag") and r.w.map and not r.tooHigh then
                fixed[#fixed + 1] = r
                if r.state ~= "ready" and not r.ownItem then
                    local n = (r.w.count or 1) - (r.haveItems or 0)
                    if n > 0 then
                        committed = committed + (r.itemPrice or 0) * n
                        taken[r.w.item] = (taken[r.w.item] or 0) + n
                    end
                end
            end
        end
        local cands = {}
        for _, z in pairs(byZone) do for _, r in ipairs(z) do cands[#cands + 1] = r end end
        local lambda = WP.BUDGET_LAMBDA[WLWritsDB.budgetPref or "rep"] or WP.BUDGET_LAMBDA.rep
        local picked, info = WP.BudgetPick(cands, { budget = budget - committed, lambda = lambda, left = left, fixed = fixed, taken = taken })
        for _, r in ipairs(picked) do
            r.inPlan = true
            plan[#plan + 1] = r
            visit(r.w.map)
        end
        info.budget, info.committed, info.cost = budget, committed, info.cost + committed
        info.n = #plan
        info.cands = #cands
        info.over = committed > budget
        WP.budgetInfo = info
        return plan, need, pending, readyRep, WP.ZoneList(route)
    end
    fill()
    return plan, need, pending, readyRep, WP.ZoneList(route)
end

-- Writs you tick yourself ("All" tab). When any is ticked, the buying plan is your pick.
function WP.IsPicked(w) local p = WLWritsCharDB.picked; return p and p[w.writ] and true or false end
function WP.SetPicked(w, on)
    WLWritsCharDB.picked = WLWritsCharDB.picked or {}
    WLWritsCharDB.picked[w.writ] = on and true or nil
    if WP.Refresh then WP.Refresh() end
end
function WP.ClearPicked()
    WLWritsCharDB.picked = {}
    if WP.Refresh then WP.Refresh() end
end
-- Your pick in numbers: writs, cost to buy (envelope + item), cost after the Coin Pouches, reputation.
function WP.PickTotals(rows)
    local n, cost, net, rep, unknown = 0, 0, 0, 0, 0
    for _, r in ipairs(rows) do
        if WP.IsPicked(r.w) and r.state ~= "done" then
            n = n + 1
            rep = rep + r.w.rep
            if r.state == "buy" then
                if r.cost then cost = cost + r.cost; net = net + (r.net or r.cost) else unknown = unknown + 1 end
            end
        end
    end
    return n, cost, net, rep, unknown
end

local AutoPlan = WP.Plan
function WP.Plan(rows)
    local plan, need, pending, readyRep, zones = AutoPlan(rows)
    local picked = WLWritsCharDB.picked
    if not picked or not next(picked) then return plan, need, pending, readyRep, zones end
    WP.budgetInfo = nil   -- your ticks are the plan: the budget does not choose them
    for _, r in ipairs(plan) do r.inPlan = nil end
    plan = {}
    for _, r in ipairs(rows) do
        -- a ticked writ whose zone you left out is not bought either
        if picked[r.w.writ] and r.state == "buy" and not (r.w.map and WP.IsSkipped("zones", r.w.map)) then
            r.inPlan = true; plan[#plan + 1] = r
        end
    end
    return plan, need, pending, readyRep, zones
end

function WP.ZoneList(maps)
    local list = {}
    for i, map in ipairs(maps) do list[i] = WP.ZoneName(map) end
    return list
end

-- ---------------------------------------------------------------- shopping list

local function AuctionHouseOpen()
    return (AuctionHouseFrame and AuctionHouseFrame:IsShown()) or (AuctionFrame and AuctionFrame:IsShown()) or false
end
WP.AuctionHouseOpen = AuctionHouseOpen

-- Everything to buy: the plan's writs and their items, plus the items missing for writs
-- already in your quest log (on the route, not above your level). One entry per item ID,
-- with the count still to buy, the expected unit price and a ceiling 25% above it.
function WP.ShoppingList(rows)
    local byID, list = {}, {}
    local function add(id, name, price, src, age, why, group, order, count, zone, map)
        local e = byID[id]
        if not e then
            e = { id = id, name = WP.ItemName(id, name), need = 0, price = price, src = src, age = age, why = {},
                  group = group, order = order, zone = zone, map = map, isWrit = why == "writ" }
            byID[id] = e
            list[#list + 1] = e
        end
        e.need = e.need + (count or 1)
        e.why[#e.why + 1] = why
    end
    for _, r in ipairs(rows) do
        local w = r.w
        local onRoute = w.map and not r.tooHigh
        -- an envelope waiting in the bank is not bought again
        if r.inPlan and not r.ownWrit and WP.InBank(w.writ) > 0 then r.ownWrit = true end
        if r.inPlan then
            local group = (r.zone or "") .. WP.ItemName(w.item, w.itemName)
            if not r.ownWrit then add(w.writ, w.writName, r.writPrice, r.writSrc, r.writAge, "writ", group, 1, 1, r.zone, w.map) end
            if not r.ownItem then add(w.item, w.itemName, r.itemPrice, r.itemSrc, r.itemAge, WP.ItemName(w.writ, w.writName), group, 2, (w.count or 1) - (r.haveItems or 0), r.zone, w.map) end
        elseif (r.state == "log" or r.state == "bag") and onRoute and not r.ownItem then
            add(w.item, w.itemName, r.itemPrice, r.itemSrc, r.itemAge, WP.ItemName(w.writ, w.writName),
                " " .. WP.ItemName(w.item, w.itemName), 2, (w.count or 1) - (r.haveItems or 0), r.zone, w.map)
        end
    end
    local total = 0
    for _, e in ipairs(list) do
        e.have = OwnedCount(e.id)
        e.bank = WP.InBank(e.id)
        local _, listed, ago = WP.Scan.Get(e.id)
        e.listed = ago and ago < SCAN_FRESH and listed or nil
        e.done = e.have >= e.need
        -- Ceiling: 25% over a fresh Auctionator price, 50% over an older or snapshot one.
        local fresh = e.src == "Auctionator" and e.age ~= nil and e.age < 2
        e.maxPrice = e.price and math.ceil(e.price * (fresh and 1.25 or 1.5) / 100) * 100 or nil
        if not e.done and e.price then total = total + e.price * (e.need - e.have) end
    end
    table.sort(list, function(a, b)
        -- Not bought first; items missing for writs you hold first; then each writ beside its item.
        if a.done ~= b.done then return not a.done end
        if a.group ~= b.group then return (a.group or "") < (b.group or "") end
        return (a.order or 0) < (b.order or 0)
    end)
    return list, total
end

-- Item IDs still to buy, for the last-minute rescan.
function WP.ShoppingIDs()
    local rows = WP.Rows()
    WP.Plan(rows)
    local list = WP.ShoppingList(rows)
    local ids = {}
    for _, e in ipairs(list) do if not e.done then ids[#ids + 1] = e.id end end
    return ids
end

local function SearchTerm(e)
    return { searchString = e.name, isExact = true, maxPrice = e.maxPrice, quantity = math.max(1, e.need - (e.have or 0)) }
end

-- Saves the list as an Auctionator shopping list named WP.NAME (replaced each time).
function WP.SaveAuctionatorList(list)
    local A = Auctionator and Auctionator.API and Auctionator.API.v1
    if not (A and A.CreateShoppingList and A.ConvertToSearchString) then
        WP.Print(L("Cette liste a besoin d'un addon d'hôtel des ventes, et aucun n'est chargé."), true)
        return
    end
    local strings = {}
    for _, e in ipairs(list) do
        if not e.done then
            local s = safe(A.ConvertToSearchString, CALLER, SearchTerm(e))
            strings[#strings + 1] = s or ('"' .. e.name .. '"')
        end
    end
    if #strings == 0 then WP.Print(L("Tout est déjà acheté : rien à mettre dans la liste.")); return end
    local ok, err = pcall(A.CreateShoppingList, CALLER, WP.NAME, strings)
    if ok then
        WP.Print(#strings == 1 and L("Liste d'achat « WL Helper » créée : 1 objet, avec son prix plafond.")
            or string.format(L("Liste d'achat « WL Helper » créée : %d objets, avec leur prix plafond."), #strings))
    else
        WP.Print(tostring(err):match("Details: (.*)") or tostring(err))
    end
end

-- Searches the given entries at the auction house, filtered to at most their ceiling price.
function WP.SearchList(list)
    local A = Auctionator and Auctionator.API and Auctionator.API.v1
    if not (A and A.MultiSearchAdvanced) then
        WP.Print(L("Cette recherche a besoin d'un addon d'hôtel des ventes, et aucun n'est chargé."), true)
        return
    end
    if not AuctionHouseOpen() then
        WP.Print(L("L'hôtel des ventes est fermé : parle à un commissaire-priseur, puis recommence."), true)
        return
    end
    local terms = {}
    for _, e in ipairs(list) do if not e.done then terms[#terms + 1] = SearchTerm(e) end end
    if #terms == 0 then WP.Print(L("Tout est déjà acheté : rien à chercher.")); return end
    local ok, err = pcall(A.MultiSearchAdvanced, CALLER, terms)
    if not ok then
        local msg = tostring(err):match("Details: (.*)") or tostring(err)
        if msg:find("not open", 1, true) then msg = L("L'hôtel des ventes est fermé : parle à un commissaire-priseur, puis recommence.") end
        WP.Print(msg)
    end
end

-- ---------------------------------------------------------------- actions


-- Searches the given writs and the items they ask for in Auctionator's Shopping tab.
function WP.Search(rows)
    local A = Auctionator and Auctionator.API and Auctionator.API.v1
    if not (A and A.MultiSearchExact) then
        WP.Print(L("Cette recherche a besoin d'un addon d'hôtel des ventes, et aucun n'est chargé."), true)
        return
    end
    local terms, seen = {}, {}
    local function add(id, fallback)
        local name = WP.ItemName(id, fallback)
        if name and not seen[name] then seen[name] = true; terms[#terms + 1] = name end
    end
    for _, r in ipairs(rows) do
        if not r.ownWrit then add(r.w.writ, r.w.writName) end
        if not r.ownItem and r.state ~= "ready" then add(r.w.item, r.w.itemName) end
    end
    if #terms == 0 then
        WP.Print(L("Rien à chercher : tu as déjà tout."))
        return
    end
    if not WP.AuctionHouseOpen() then
        WP.Print(L("L'hôtel des ventes est fermé : parle à un commissaire-priseur, puis recommence."), true)
        return
    end
    local ok, err = pcall(A.MultiSearchExact, CALLER, terms)
    if not ok then
        local msg = tostring(err):match("Details: (.*)") or tostring(err)
        if msg:find("not open", 1, true) then msg = L("L'hôtel des ventes est fermé : parle à un commissaire-priseur, puis recommence.") end
        WP.Print(msg)
    end
end

-- ---------------------------------------------------------------- events

local questToWrit = {}

-- ---- Coin Pouch value: measured only when you open a pouch yourself (right-click from your
-- bags with no merchant, bank or mailbox open), as the money you have once its loot closes.
local POUCH = {}
for _, id in ipairs(COIN_POUCHES) do POUCH[id] = true end
local opening   -- { money = copper before, t = GetTime(), count = pouches before, looting = loot window seen }

local turnIn   -- { tier, t, counts } just after a writ is turned in

local function PouchCounts()
    local out = {}
    for _, id in ipairs(COIN_POUCHES) do out[id] = BagCount(id) end
    return out
end

local function CountPouches()
    local n = 0
    for _, id in ipairs(COIN_POUCHES) do n = n + BagCount(id) end
    return n
end

local function RecordPouch(amount, id)
    local db = WLWritsDB
    local function push(s)
        s[#s + 1] = amount
        while #s > 20 do table.remove(s, 1) end
    end
    push(db.pouchSamples)
    if id then
        db.pouchById[id] = db.pouchById[id] or {}
        push(db.pouchById[id])
    end
    if WP.RefreshSoon then WP.RefreshSoon() end
end

local function Shown(frame) return frame and frame.IsShown and frame:IsShown() end
local function Busy()
    return Shown(MerchantFrame) or Shown(BankFrame) or Shown(MailFrame) or Shown(TradeFrame)
        or Shown(AuctionHouseFrame) or Shown(AuctionFrame) or Shown(GuildBankFrame) or false
end

local function OnUseItem(bag, slot)
    if not WP.ModuleOn("writs") then return end
    local id = C_Container and C_Container.GetContainerItemID and safe(C_Container.GetContainerItemID, bag, slot)
        or (GetContainerItemID and safe(GetContainerItemID, bag, slot))
    if id and POUCH[id] and not Busy() then
        opening = { money = GetMoney(), t = GetTime(), count = CountPouches(), id = id }
    end
end
if C_Container and C_Container.UseContainerItem then
    hooksecurefunc(C_Container, "UseContainerItem", OnUseItem)
elseif UseContainerItem then
    hooksecurefunc("UseContainerItem", OnUseItem)
end

-- A sample counts only if the loot window opened within 2 s of using the pouch, and the pouch
-- is gone from the bags once it closes: a failed use, a bank transfer or a sale never qualifies.
local function OnLootOpened()
    if opening and GetTime() - opening.t <= 2 then opening.looting = true else opening = nil end
end

local function FinishPouch()
    local o = opening
    opening = nil
    if not (o and o.looting) or GetTime() - o.t > 10 then return end
    if CountPouches() >= o.count then return end
    local gain = GetMoney() - o.money
    if gain > 0 then RecordPouch(gain, o.id) end
end

-- ---- turn-in spots learned from the quest log, for writs the data has no spot for. Kept
-- account-wide: the NPC stands in the same place for every character.

local function ApplySpot(w, spot)
    w.map, w.x, w.y, w.learned = spot[1], spot[2], spot[3], true
end

local function IsZoneMap(map)
    local info = safe(C_Map and C_Map.GetMapInfo, map)
    local zone = Enum and Enum.UIMapType and Enum.UIMapType.Zone or 3
    return info and info.mapType == zone
end

-- Learns where a writ is handed in from the quest's own map marker: only for a completed writ
-- (its marker is then the turn-in), and only on the zone map you are standing in, never from a
-- routing step such as a zeppelin or a zone exit.
local learnPending = false
local unmapped = {}   -- writs with no known turn-in spot, filled at load
local function LearnSpots()
    if #unmapped == 0 then return end
    local GetQuestsOnMap = C_QuestLog and C_QuestLog.GetQuestsOnMap
    local here = safe(C_Map and C_Map.GetBestMapForUnit, "player")
    if not (GetQuestsOnMap and here and IsZoneMap(here)) then return end
    local wanted = {}
    for _, w in ipairs(unmapped) do
        if not w.map and QuestLogIndex(w.quest) and QuestComplete(w.quest) then wanted[w.quest] = w end
    end
    if not next(wanted) then return end
    local learned = false
    local quests = safe(GetQuestsOnMap, here)
    for _, q in ipairs(type(quests) == "table" and quests or {}) do
        local w = type(q) == "table" and wanted[q.questID]
        if w and not q.isQuestStart and type(q.x) == "number" and type(q.y) == "number" and q.x > 0 and q.y > 0 then
            local spot = { here, math.floor(q.x * 1000 + 0.5) / 10, math.floor(q.y * 1000 + 0.5) / 10 }
            WLWritsDB.spots[w.quest] = spot
            ApplySpot(w, spot)
            learned = true
        end
    end
    if learned then
        for i = #unmapped, 1, -1 do if unmapped[i].map then table.remove(unmapped, i) end end
        if WP.RefreshSoon then WP.RefreshSoon() end
    end
end
local function LearnSoon(delay)
    if learnPending or #unmapped == 0 then return end
    learnPending = true
    C_Timer.After(delay, function() learnPending = false; LearnSpots() end)
end

-- ---- events

local REFRESH_EVENTS = { QUEST_LOG_UPDATE = true, BAG_UPDATE_DELAYED = true, UPDATE_FACTION = true }

-- One chat prefix for the whole addon. WP.Print(msg, true) is for reminders and errors: the same
-- sentence is then said at most once every 30 s. The result of a click (sold, thrown away, scan
-- finished...) never passes it, so a second identical action still gets its confirmation.
local saidAt = {}
function WP.Print(msg, once)
    local key = tostring(msg)
    if once then
        local now = GetTime and GetTime() or 0
        if saidAt[key] and now - saidAt[key] < 30 then return end
        for k, t in pairs(saidAt) do if now - t >= 30 then saidAt[k] = nil end end
        saidAt[key] = now
    end
    if root.Print then root.Print(msg) else print("WL Helper " .. key) end
end

-- When the game blocks something WL Helper did, say which function (the game's own popup does not)
-- and keep it for the bug form (/wlh idea, Writs/Feedback.lua).
ns.AddEnglish({
    ["Le jeu a bloqué « %s »%s. Tape /wlh idee pour le signaler : le nom de la fonction est déjà dans le formulaire."] =
        "The game blocked \"%s\"%s. Type /wlh idea to report it: the function's name is already in the form.",
    [" en combat"] = " in combat",
    ["Le jeu bloque les marques de raid posées par une macro écrite par un addon. La macro %s contient /tm : c'est elle (RXPTargeting vient de RestedXP, qui la réécrit à chaque étape). Rien à signaler, le ciblage marche quand même."] =
        "The game blocks raid markers set by a macro an addon wrote. The macro %s has /tm in it: that is the one (RXPTargeting comes from RestedXP, which rewrites it at each step). Nothing to report, targeting still works.",
    ["Writs"] = "Writs",
    ["Groupes"] = "Groups",
    ["Writs, liste d'achat et remise automatique"] = "Writs, shopping list and automatic turn-in",
    ["Commandes des Writs :"] = "Writs commands:",
    ["  /wlh trade : ouvre ou ferme les Writs"] = "  /wlh trade: open or close the trading post",
    ["  /wlh trade gps : lance ou arrête la tournée GPS des writs prêts à rendre"] = "  /wlh trade gps: start or stop the GPS tour of the writs ready to turn in",
    ["  /wlh trade stop : arrête le GPS"] = "  /wlh trade stop: stop the GPS",
    ["  /wlh trade scan : scanne les prix de la liste d'achat à l'HV"] = "  /wlh trade scan: scan the shopping list's prices at the AH",
    ["  /wlh trade reset : oublie les bourses mesurées et la faction"] = "  /wlh trade reset: forget the measured Coin Pouches and the faction",
    ["Le module %s est éteint. Rallume-le dans Réglages, Général, Modules."] = "The %s module is off. Turn it back on in Settings, General, Modules.",
    ["Mesures des bourses et faction oubliées : elles seront relevées à nouveau."] = "Coin Pouch samples and faction forgotten: they will be measured again.",
    ["Cette liste a besoin d'un addon d'hôtel des ventes, et aucun n'est chargé."] = "This list needs an auction house addon, and none is loaded.",
    ["Cette recherche a besoin d'un addon d'hôtel des ventes, et aucun n'est chargé."] = "This search needs an auction house addon, and none is loaded.",
    ["Tout est déjà acheté : rien à mettre dans la liste."] = "Everything is already bought: nothing to put in the list.",
    ["Liste d'achat « WL Helper » créée : 1 objet, avec son prix plafond."] = "Shopping list \"WL Helper\" created: 1 item, with its price ceiling.",
    ["Liste d'achat « WL Helper » créée : %d objets, avec leur prix plafond."] = "Shopping list \"WL Helper\" created: %d items, with their price ceilings.",
    ["L'hôtel des ventes est fermé : parle à un commissaire-priseur, puis recommence."] = "The auction house is closed: talk to an auctioneer, then try again.",
    ["Tout est déjà acheté : rien à chercher."] = "Everything is already bought: nothing to search.",
    ["Rien à chercher : tu as déjà tout."] = "Nothing to search: you already have everything.",
})
local blocked = CreateFrame("Frame")
pcall(blocked.RegisterEvent, blocked, "ADDON_ACTION_BLOCKED")
pcall(blocked.RegisterEvent, blocked, "ADDON_ACTION_FORBIDDEN")
local blockedSaid = {}
blocked:SetScript("OnEvent", function(_, _, addon, func)
    if addon ~= ADDON then return end
    local combat = InCombatLockdown and InCombatLockdown() or false
    local meta = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
    if WLWritsDB then
        WLWritsDB.lastBlocked = { func = tostring(func), combat = combat, t = time(), ver = meta and meta(ADDON, "Version") or "?" }
    end
    local key = tostring(func)
    if blockedSaid[key] then return end
    blockedSaid[key] = true
    -- a raid marker from a macro another addon wrote (RestedXP's "RXPTargeting" adds "/tm !7"): the
    -- game may blame us, but the line is not ours; name the macro instead of asking for a report
    if key:find("SetRaidTarget", 1, true) and GetMacroInfo then
        local found = {}
        for i = 1, 150 do
            local ok, name, _, body = pcall(GetMacroInfo, i)
            if ok and type(name) == "string" and type(body) == "string"
                and not (issecretvalue and (issecretvalue(name) or issecretvalue(body)))
                and (body:find("\n/tm ", 1, true) or body:find("^/tm ") or body:find("SetRaidTarget", 1, true)
                     or body:find("/targetmarker", 1, true)) then
                found[#found + 1] = "« " .. name .. " »"
            end
        end
        if #found > 0 then
            WP.Print(string.format(L("Le jeu bloque les marques de raid posées par une macro écrite par un addon. La macro %s contient /tm : c'est elle (RXPTargeting vient de RestedXP, qui la réécrit à chaque étape). Rien à signaler, le ciblage marche quand même."), table.concat(found, ", ")))
            return
        end
    end
    WP.Print(string.format(L("Le jeu a bloqué « %s »%s. Tape /wlh idee pour le signaler : le nom de la fonction est déjà dans le formulaire."),
        tostring(func), combat and L(" en combat") or ""))
end)

local f = CreateFrame("Frame")
pcall(f.RegisterEvent, f, "ADDON_LOADED")
pcall(f.RegisterEvent, f, "QUEST_TURNED_IN")
pcall(f.RegisterEvent, f, "QUEST_ACCEPTED")
pcall(f.RegisterEvent, f, "ZONE_CHANGED_NEW_AREA")
pcall(f.RegisterEvent, f, "QUEST_LOG_UPDATE")
pcall(f.RegisterEvent, f, "BAG_UPDATE_DELAYED")
pcall(f.RegisterEvent, f, "UPDATE_FACTION")
pcall(f.RegisterEvent, f, "LOOT_OPENED")
pcall(f.RegisterEvent, f, "LOOT_CLOSED")
pcall(f.RegisterEvent, f, "PLAYER_REGEN_ENABLED")
f:SetScript("OnEvent", function(_, event, a1)
    if event ~= "ADDON_LOADED" and not WP.ModuleOn("writs") then return end
    if event == "ADDON_LOADED" then
        if a1 ~= ADDON then return end
        WLWritsDB = WLWritsDB or {}
        CopyDefaults(WLWritsDB, DEFAULTS)
        WLWritsCharDB = WLWritsCharDB or {}
        WLWritsCharDB.turnedIn = WLWritsCharDB.turnedIn or {}
        -- beta.34 kept the Shopping tab's zones apart (skipZones): one list now, skip.zones
        if WLWritsCharDB.skipZones then
            WLWritsCharDB.skip = WLWritsCharDB.skip or {}
            WLWritsCharDB.skip.zones = WLWritsCharDB.skip.zones or {}
            for map in pairs(WLWritsCharDB.skipZones) do WLWritsCharDB.skip.zones[map] = true end
            WLWritsCharDB.skipZones = nil
        end
        WLWritsDB.turnedIn, WLWritsDB.factionID = nil, nil   -- were account-wide in 1.0
        WLWritsDB.spots = WLWritsDB.spots or {}
        for _, w in ipairs(ns.WRITS) do
            if w.quest then questToWrit[w.quest] = w end
            local spot = w.quest and WLWritsDB.spots[w.quest]
            if not w.map and type(spot) == "table" then ApplySpot(w, spot) end
            if not w.map and w.quest then unmapped[#unmapped + 1] = w end
        end
    elseif event == "QUEST_TURNED_IN" then
        if questToWrit[a1] then
            WLWritsCharDB.turnedIn[a1] = WP.Today()
            if turnIn and GetTime() - turnIn.t <= 5 then
                turnIn = nil   -- two writs in a row: the pouch can't be told apart, learn next time
            else
                turnIn = { tier = questToWrit[a1].tier, t = GetTime(), counts = PouchCounts() }
            end
            if WP.RefreshSoon then WP.RefreshSoon() end
        end
    elseif event == "LOOT_OPENED" then
        if opening then OnLootOpened() end
    elseif event == "LOOT_CLOSED" then
        if opening then C_Timer.After(0.5, FinishPouch) end
    elseif event == "QUEST_ACCEPTED" or event == "ZONE_CHANGED_NEW_AREA" then
        LearnSoon(1)
    elseif event == "BAG_UPDATE_DELAYED" and turnIn then
        if GetTime() - turnIn.t > 5 then turnIn = nil
        else
            local risen, rose = nil, 0
            for id, n in pairs(PouchCounts()) do
                local d = n - (turnIn.counts[id] or 0)
                if d ~= 0 then rose = rose + 1; risen = d == 1 and id or nil end
            end
            if rose == 1 and risen then WLWritsDB.pouchOfTier[turnIn.tier] = risen end
            if rose > 0 then turnIn = nil end
        end
        if WP.RefreshSoon then WP.RefreshSoon() end
    elseif event == "PLAYER_REGEN_ENABLED" or REFRESH_EVENTS[event] then
        if event == "QUEST_LOG_UPDATE" then LearnSoon(2) end
        if WP.RefreshSoon then WP.RefreshSoon() end
    end
end)

-- The Trading Post's words come through /wlh trade (Main.lua): /wlh trade gps, scan, stop, reset.

local function Help()
    WP.Print(L("Commandes des Writs :"))
    for _, line in ipairs({
        L("  /wlh trade : ouvre ou ferme les Writs"),
        L("  /wlh trade gps : lance ou arrête la tournée GPS des writs prêts à rendre"),
        L("  /wlh trade stop : arrête le GPS"),
        L("  /wlh trade scan : scanne les prix de la liste d'achat à l'HV"),
        L("  /wlh trade reset : oublie les bourses mesurées et la faction"),
    }) do print(line) end
end

-- ---------------------------------------------------------------- modules on / off
-- A module switched off listens to nothing and opens no window; switching it back on is immediate.
-- The GPS has no switch: the other modules use it.
WP.MODULES = {
    { key = "dungeons", label = "Guide de quêtes", hint = "Donjons, raids et quêtes de classe : route, flèche" },
    { key = "writs", label = "Writs", hint = "Writs, liste d'achat et remise automatique" },
    { key = "bags", label = "Sacs", hint = "Nettoyeur des objets de quête inutiles" },
    { key = "orders", label = "Commandes", hint = "Faire fabriquer par la guilde, accepter des commandes" },
    { key = "guild", label = "Guilde", hint = "Voir toute la guilde et le classement PvP" },
    { key = "events", label = "Groupes", hint = "Donjons et raids de la guilde, groupes du moment" },
    { key = "upgrades", label = "Améliorations", hint = "Flèche verte sur les objets meilleurs que les tiens" },
    { key = "keys", label = "Clés", hint = "Clés et accès des donjons et raids, et qui les a dans la guilde" },
    { key = "triage", label = "Tri du journal", hint = "Les quêtes à abandonner quand le journal est presque plein" },
}
function WP.ModuleOn(key)
    local m = WLWritsDB and WLWritsDB.modules
    return not m or m[key] ~= false
end
function WP.ModuleLabel(key)
    for _, m in ipairs(WP.MODULES) do if m.key == key then return L(m.label) end end
    return key
end
-- Says a module is off (and where to turn it on); true when it is off.
function WP.ModuleOff(key)
    if WP.ModuleOn(key) then return false end
    WP.Print(string.format(L("Le module %s est éteint. Rallume-le dans Réglages, Général, Modules."), WP.ModuleLabel(key)), true)
    return true
end
function WP.SetModule(key, on)
    WLWritsDB.modules = WLWritsDB.modules or {}
    WLWritsDB.modules[key] = on and true or false
    local G = WP.GPS
    if key == "dungeons" then
        if not on then
            if root.frame and root.frame:IsShown() then root.quietHide = true; root.frame:Hide(); root.quietHide = nil end
            if root.HidePicker then root.HidePicker() end
            if root.ClearPoints then root.ClearPoints() end   -- map points, TomTom and the arrow
            if G then G.Stop("dungeon") end
            if root.UpdateActionBar then root.UpdateActionBar() end
        elseif root.frame then
            -- back right away, as it was before
            if WLDTDB and not WLDTDB.hidden then root.frame:Show() end
            root.frame.sig = nil
            if root.Refresh then root.Refresh(true) end
            if root.UpdateActionBar then root.UpdateActionBar() end
        end
    elseif key == "writs" then
        if not on then
            if WP.HideWindow then WP.HideWindow() end
            if WLWritsCharDB then WLWritsCharDB.gps = false end
            if G then G.Stop("writs") end
        end
    elseif key == "bags" then
        if not on and WP.Cleaner and WP.Cleaner.Hide then WP.Cleaner.Hide() end
    elseif key == "guild" then
        if not on and WP.HideGuild then WP.HideGuild() end
        -- the shared dungeon quests follow the guild switch (SharedQuests.lua): their window goes too
        if not on and WP.Shared and WP.Shared.Hide then WP.Shared.Hide() end
    elseif key == "events" then
        if not on and WP.HideEvents then WP.HideEvents() end
    elseif key == "upgrades" then
        if WP.RefreshUpgrades then WP.RefreshUpgrades() end
    elseif key == "keys" then
        if not on and WP.Keys and WP.Keys.Hide then WP.Keys.Hide() end
        -- an open guild window must not stay on a keys board that no longer updates
        local gw = _G.WLHelperGuild
        if not on and gw and gw.IsShown and gw:IsShown() and WP.ShowGuildTab then WP.ShowGuildTab("members") end
    elseif key == "triage" then
        if not on and WP.Triage and WP.Triage.Hide then WP.Triage.Hide() end
    end
    if WP.RefreshHome then WP.RefreshHome() end
    if WP.SyncOptions then WP.SyncOptions() end
end

-- /wlh trade: the Trading Post's own words need the module; options, clean, idea work anyway
local WRIT_COMMANDS = { [""] = true, gps = true, stop = true, scan = true, reset = true }
function WP.Command(msg)
    local cmd = (msg or ""):lower():match("^%s*(%S*)")
    if WRIT_COMMANDS[cmd] and WP.ModuleOff("writs") then return end
    if cmd == "" then
        if WP.Toggle then WP.Toggle() end
    elseif cmd == "gps" then
        WP.ToggleGPS()
    elseif cmd == "stop" then
        WLWritsCharDB.gps = false
        WP.GPS.Stop()
        if WP.OnGPSChanged then WP.OnGPSChanged() end
    elseif cmd == "scan" then
        WP.Scan.Start(WP.ShoppingIDs())
    elseif (cmd == "idee" or cmd == "idea" or cmd == "bug") and WP.Feedback then
        WP.Feedback(cmd == "bug" and "bug" or "idea")
    elseif cmd == "clean" then
        if WP.Cleaner then WP.Cleaner.Toggle() end
    elseif cmd == "options" or cmd == "opt" then
        if WP.OpenOptions then WP.OpenOptions("comptoir") end
    elseif cmd == "reset" then
        local db = WLWritsDB
        db.pouchSamples, db.pouchById, db.pouchOfTier = {}, {}, {}
        WLWritsCharDB.factionID = nil
        WP.Print(L("Mesures des bourses et faction oubliées : elles seront relevées à nouveau."))
    else
        Help()
    end
end
SlashCmdList.WLWRITS = WP.Command
