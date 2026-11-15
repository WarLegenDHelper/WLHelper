-- Writs/Ladder.lua: the real price of buying N of an item. The scan (Scan.lua) only knows the lowest
-- price; buying six crates walks up the listings (42 s, then 1 g, then 2 g...). With the auction
-- house open, this asks the item's own search (every listing, cheapest first) and keeps the price
-- tiers: WLWritsDB.ladder[itemID] = { t = time(), tiers = { { unit price, quantity }, ... } }.
-- WP.CostFor(id, n) then sums the cheapest n units; it says when fewer than n are for sale.
local ADDON, root = ...
root.Writs = root.Writs or {}
local ns = root.Writs
local WP = ns.WP
local L = ns.L

local api = C_AuctionHouse
local FRESH = 600      -- seconds a ladder stays valid
local TIMEOUT = 6

local function Book()
    WLWritsDB.ladder = WLWritsDB.ladder or {}
    return WLWritsDB.ladder
end

local function Available()
    return api and api.SendSearchQuery and api.MakeItemKey and true or false
end

-- Price tiers of an item, when fresh.
function WP.Ladder(id)
    local e = WLWritsDB and WLWritsDB.ladder and WLWritsDB.ladder[id]
    if e and e.t and time() - e.t < FRESH then return e.tiers end
end

-- Cost of the cheapest n units for sale, and whether n were found. nil without a fresh ladder.
function WP.CostFor(id, n)
    if n <= 0 then return 0, true end
    local tiers = WP.Ladder(id)
    if not tiers then return nil end
    local left, cost = n, 0
    for _, t in ipairs(tiers) do
        local take = math.min(left, t[2])
        cost = cost + take * t[1]
        left = left - take
        if left <= 0 then break end
    end
    if left > 0 then
        -- not enough for sale: the missing ones at the last price seen
        local last = tiers[#tiers]
        cost = cost + left * (last and last[1] or 0)
        return cost, false
    end
    return cost, true
end

-- ---------------------------------------------------------------- the queue
local queue, current, onDone = {}, nil, nil
local sorts

local function Finish(id, tiers)
    if tiers then Book()[id] = { t = time(), tiers = tiers } end
    current = nil
    C_Timer.After(0.3, function()
        if #queue > 0 then WP.LadderNext() elseif onDone then local cb = onDone; onDone = nil; cb() end
    end)
end

local function ReadCommodity(id)
    if not (api.GetNumCommoditySearchResults and api.GetCommoditySearchResultInfo) then return nil end
    local n = select(2, pcall(api.GetNumCommoditySearchResults, id)) or 0
    if n == 0 then return nil end
    local tiers = {}
    for i = 1, n do
        local ok, r = pcall(api.GetCommoditySearchResultInfo, id, i)
        if ok and r and r.unitPrice and r.quantity then tiers[#tiers + 1] = { r.unitPrice, r.quantity } end
    end
    return tiers
end

local function ReadItem(key)
    if not (api.GetNumItemSearchResults and api.GetItemSearchResultInfo) then return nil end
    local n = select(2, pcall(api.GetNumItemSearchResults, key)) or 0
    if n == 0 then return nil end
    local tiers = {}
    for i = 1, n do
        local ok, r = pcall(api.GetItemSearchResultInfo, key, i)
        if ok and r and r.buyoutAmount and r.buyoutAmount > 0 then
            local q = r.quantity or 1
            tiers[#tiers + 1] = { math.floor(r.buyoutAmount / q), q }
        end
    end
    table.sort(tiers, function(a, b) return a[1] < b[1] end)
    return tiers
end

function WP.LadderNext()
    if current or #queue == 0 then return end
    if not WP.AuctionHouseOpen() or (WP.Scan and WP.Scan.Busy()) then queue = {}; return end
    local id = table.remove(queue, 1)
    local ok, key = pcall(api.MakeItemKey, id)
    if not ok or not key then return WP.LadderNext() end
    current = { id = id, key = key, at = GetTime() }
    if not sorts then
        local price = Enum and Enum.AuctionHouseSortOrder and Enum.AuctionHouseSortOrder.Price or 0
        sorts = { { sortOrder = price, reverseSort = false } }
    end
    pcall(api.SendSearchQuery, key, sorts, true)
    local mine = current
    C_Timer.After(TIMEOUT, function()
        if current == mine then Finish(mine.id, ReadCommodity(mine.id) or ReadItem(mine.key) or {}) end
    end)
    if WP.OnScanProgress then WP.OnScanProgress() end
end

-- Asks the ladders of these items (already fresh ones are skipped); cb when all are in.
function WP.LadderFetch(ids, cb)
    if not Available() then return false end
    if not WP.AuctionHouseOpen() then WP.Print(L("ouvre l'hôtel des ventes d'abord.")); return false end
    local seen = {}
    for _, id in ipairs(ids) do
        if id and not seen[id] and not WP.Ladder(id) then seen[id] = true; queue[#queue + 1] = id end
    end
    onDone = cb
    if #queue == 0 then if cb then cb() end; onDone = nil; return true end
    WP.LadderNext()
    return true
end
function WP.LadderBusy() return current ~= nil or #queue > 0 end
function WP.LadderLeft() return #queue + (current and 1 or 0) end

local f = CreateFrame("Frame")
f:RegisterEvent("COMMODITY_SEARCH_RESULTS_UPDATED")
f:RegisterEvent("ITEM_SEARCH_RESULTS_UPDATED")
f:RegisterEvent("AUCTION_HOUSE_CLOSED")
f:SetScript("OnEvent", function(_, e, a1)
    if e == "AUCTION_HOUSE_CLOSED" then queue = {}; current = nil; return end
    if not current then return end
    if e == "COMMODITY_SEARCH_RESULTS_UPDATED" and a1 == current.id then
        Finish(current.id, ReadCommodity(current.id) or {})
    elseif e == "ITEM_SEARCH_RESULTS_UPDATED" and type(a1) == "table" and a1.itemID == current.id then
        Finish(current.id, ReadItem(current.key) or {})
    end
end)
