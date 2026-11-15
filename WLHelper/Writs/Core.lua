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
    gpsOpts = { provider = "auto", teleports = true, autoFlight = false, scale = 1, alpha = 0.6, hideCombat = false },
    -- Comptoir comforts
    comfort = { autoTurnIn = true, autoAccept = true, reminder = true, tooltip = true },
    modules = { dungeons = true, writs = true, bags = true },   -- Settings > General > Modules       -- rescan the shopping list when the auction house opens
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
    if goal > 0 and REACTION_TOTAL[goal] and REACTION_TOTAL[goal] > total then
        return REACTION_TOTAL[goal] - total, goal
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
        if avail[id] == nil then avail[id] = BagCount(id) end
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

function WP.Plan(rows)
    local need = WP.RepNeeded()
    local plan, pending, readyRep, zones = {}, 0, 0, {}
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
    -- Candidates by zone, cheapest first inside each zone.
    local function build()
        byZone = {}
        for _, r in ipairs(rows) do
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
    for _, r in ipairs(plan) do r.inPlan = nil end
    plan = {}
    for _, r in ipairs(rows) do
        if picked[r.w.writ] and r.state == "buy" then r.inPlan = true; plan[#plan + 1] = r end
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
        e.have = BagCount(e.id)
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
        WP.Print(L("Auctionator n'est pas chargé."))
        return
    end
    local strings = {}
    for _, e in ipairs(list) do
        if not e.done then
            local s = safe(A.ConvertToSearchString, CALLER, SearchTerm(e))
            strings[#strings + 1] = s or ('"' .. e.name .. '"')
        end
    end
    if #strings == 0 then WP.Print(L("tout est déjà acheté.")); return end
    local ok, err = pcall(A.CreateShoppingList, CALLER, WP.NAME, strings)
    if ok then
        WP.Print(string.format(L("liste Auctionator « WL Helper » créée (%d objets, avec prix plafond)."), #strings))
    else
        WP.Print(tostring(err):match("Details: (.*)") or tostring(err))
    end
end

-- Searches the given entries at the auction house, filtered to at most their ceiling price.
function WP.SearchList(list)
    local A = Auctionator and Auctionator.API and Auctionator.API.v1
    if not (A and A.MultiSearchAdvanced) then
        WP.Print(L("Auctionator n'est pas chargé."))
        return
    end
    if not AuctionHouseOpen() then
        WP.Print(L("ouvre l'hôtel des ventes d'abord."))
        return
    end
    local terms = {}
    for _, e in ipairs(list) do if not e.done then terms[#terms + 1] = SearchTerm(e) end end
    if #terms == 0 then WP.Print(L("tout est déjà acheté.")); return end
    local ok, err = pcall(A.MultiSearchAdvanced, CALLER, terms)
    if not ok then
        local msg = tostring(err):match("Details: (.*)") or tostring(err)
        if msg:find("not open", 1, true) then msg = L("ouvre l'hôtel des ventes d'abord.") end
        WP.Print(msg)
    end
end

-- ---------------------------------------------------------------- actions


-- Searches the given writs and the items they ask for in Auctionator's Shopping tab.
function WP.Search(rows)
    local A = Auctionator and Auctionator.API and Auctionator.API.v1
    if not (A and A.MultiSearchExact) then
        WP.Print(L("Auctionator n'est pas chargé."))
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
        WP.Print(L("rien à chercher."))
        return
    end
    if not WP.AuctionHouseOpen() then
        WP.Print(L("ouvre l'hôtel des ventes d'abord."))
        return
    end
    local ok, err = pcall(A.MultiSearchExact, CALLER, terms)
    if not ok then
        local msg = tostring(err):match("Details: (.*)") or tostring(err)
        if msg:find("not open", 1, true) then msg = L("ouvre l'hôtel des ventes d'abord.") end
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

function WP.Print(msg) if root.Print then root.Print(msg) else print("WL Helper " .. tostring(msg)) end end   -- one chat prefix for the whole addon

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("QUEST_TURNED_IN")
f:RegisterEvent("QUEST_ACCEPTED")
f:RegisterEvent("ZONE_CHANGED_NEW_AREA")
f:RegisterEvent("QUEST_LOG_UPDATE")
f:RegisterEvent("BAG_UPDATE_DELAYED")
f:RegisterEvent("UPDATE_FACTION")
f:RegisterEvent("LOOT_OPENED")
f:RegisterEvent("LOOT_CLOSED")
f:RegisterEvent("PLAYER_REGEN_ENABLED")
f:SetScript("OnEvent", function(_, event, a1)
    if event ~= "ADDON_LOADED" and not WP.ModuleOn("writs") then return end
    if event == "ADDON_LOADED" then
        if a1 ~= ADDON then return end
        WLWritsDB = WLWritsDB or {}
        CopyDefaults(WLWritsDB, DEFAULTS)
        WLWritsCharDB = WLWritsCharDB or {}
        WLWritsCharDB.turnedIn = WLWritsCharDB.turnedIn or {}
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

-- Not /ledger: Merchant's Favor Ledger (CurseForge) already uses it.
-- /comptoir (also /writs, /wl comptoir). The language is WL Helper's (/wl lang).
SLASH_WLWRITS1 = "/comptoir"
SLASH_WLWRITS2 = "/writs"   -- old name, kept

local function Help()
    WP.Print(L("commandes :"))
    for _, line in ipairs({
        L("  /comptoir : ouvre ou ferme la fenêtre"),
        L("  /comptoir gps : lance ou arrête la tournée GPS (writs prêts à rendre)"),
        L("  /comptoir stop : arrête le GPS"),
        L("  /comptoir scan : scanne la liste d'achat à l'HV"),
        L("  /comptoir reset : oublie les bourses mesurées et la faction"),
        L("  /comptoir clean : objets de quête inutiles dans tes sacs"),
        L("  /comptoir options : les options de WL Helper"),
    }) do print(line) end
end

-- ---------------------------------------------------------------- modules on / off
-- A module switched off listens to nothing and opens no window; switching it back on is immediate.
-- The GPS has no switch: the other modules use it.
WP.MODULES = {
    { key = "dungeons", label = "Donjons", hint = "Guide des quêtes de donjon, route, flèche" },
    { key = "writs", label = "Comptoir", hint = "Craftsman's Writs, liste d'achat, remise auto" },
    { key = "bags", label = "Sacs", hint = "Nettoyeur des objets de quête inutiles" },
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
    WP.Print(string.format(L("le module %s est éteint : Réglages › Général › Modules."), WP.ModuleLabel(key)))
    return true
end
function WP.SetModule(key, on)
    WLWritsDB.modules = WLWritsDB.modules or {}
    WLWritsDB.modules[key] = on and true or false
    local G = WP.GPS
    if key == "dungeons" then
        if not on then
            if root.frame and root.frame:IsShown() then root.frame:Hide() end
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
    end
    if WP.RefreshHome then WP.RefreshHome() end
    if WP.SyncOptions then WP.SyncOptions() end
end

-- /comptoir: the Trading Post's own words need the module; options, clean, idea work anyway
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
        WP.Print(L("mesures de bourse et faction réinitialisées."))
    else
        Help()
    end
end
SlashCmdList.WLWRITS = WP.Command
