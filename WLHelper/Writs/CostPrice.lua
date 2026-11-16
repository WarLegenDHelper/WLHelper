-- Writs/CostPrice.lua: what an item really cost you (WP.CostPrice).
--   Purchases: every auction house buy is written down, a moving average of the unit price paid per
--     item: WLWritsDB.costs[itemID] = { n = units counted, avg = copper per unit, t = last buy }.
--     Commodities: StartCommoditiesPurchase / COMMODITY_PRICE_UPDATED (the price the game confirms)
--     / ConfirmCommoditiesPurchase, kept on COMMODITY_PURCHASE_SUCCEEDED. Items: PlaceBid at the
--     listing's buyout, kept on AUCTION_HOUSE_PURCHASE_COMPLETED. A client without those events
--     keeps the buy as soon as it is confirmed. Entries untouched for 60 days are dropped.
--   Crafted items: no buy of its own, the sum of its reagents' cost (recipes read from the guild
--     orders data, WP.Orders.Reagents, read only), when every reagent has a cost.
--   Shown: one tooltip line "Prix de revient : 1po 20pa" when known; posting an auction under it
--     (C_AuctionHouse.PostItem / PostCommodity) prints one warning line.
-- Switch: WLWritsDB.costPrice (on unless false); off, nothing is recorded, shown or warned.
local ADDON, root = ...
root.Writs = root.Writs or {}
local ns = root.Writs
local WP = ns.WP
local L = ns.L
local S = ns.S

local CP = {}
WP.CostPrice = CP

ns.AddEnglish({
    ["Prix de revient : %s"] = "Cost price: %s",
    ["Prix de revient (composants, par fabrication) : %s"] = "Cost price (reagents, per craft): %s",
    ["Attention : %s mis en vente à %s l'unité, sous ton prix de revient (%s)."] = "Careful: %s listed at %s each, below your cost price (%s).",
})

local KEEP = 60 * 86400   -- an item not bought for 60 days is forgotten
local WEIGHT = 50         -- the average follows roughly the last 50 units bought
local DEPTH = 3           -- reagents of reagents, at most this deep

local function secret(v) return issecretvalue and issecretvalue(v) or false end
-- A usable positive number, or nil (secret values and junk are never read).
local function num(v)
    if v == nil or secret(v) or type(v) ~= "number" or v ~= v or v <= 0 then return nil end
    return v
end
local function Now() return time and time() or 0 end

function CP.On() return not (WLWritsDB and WLWritsDB.costPrice == false) end

local function Book()
    if not WLWritsDB then return nil end
    WLWritsDB.costs = WLWritsDB.costs or {}
    return WLWritsDB.costs
end

function CP.Prune()
    local b = Book()
    if not b then return 0 end
    local now, n = Now(), 0
    for id, e in pairs(b) do
        if type(e) ~= "table" or not num(e.avg) or not num(e.t) or now - e.t > KEEP then b[id] = nil; n = n + 1 end
    end
    return n
end

-- Writes a purchase: qty units of item id at unit copper each.
function CP.Record(id, qty, unit)
    id, qty, unit = num(id), num(qty), num(unit)
    if not (id and qty and unit) or not CP.On() then return end
    local b = Book()
    if not b then return end
    local e = b[id]
    if type(e) ~= "table" or not num(e.avg) or not num(e.n) or Now() - (num(e.t) or 0) > KEEP then e = { n = 0, avg = 0 } end
    local n = math.min(e.n, WEIGHT)
    e.avg = (e.avg * n + unit * qty) / (n + qty)
    e.n = math.min(n + qty, WEIGHT)
    e.t = Now()
    b[id] = e
end

-- Copper per unit, and how it is known ("bought" or "crafted"); nil when unknown.
local function Cost(id, depth, seen)
    local b = WLWritsDB and WLWritsDB.costs
    local e = b and b[id]
    if type(e) == "table" and num(e.avg) and Now() - (num(e.t) or 0) <= KEEP then return e.avg, "bought" end
    if depth >= DEPTH or seen[id] then return nil end
    local O = WP.Orders
    if not (O and O.Reagents) then return nil end
    local ok, reagents = pcall(O.Reagents, id)
    if not ok or type(reagents) ~= "table" or #reagents == 0 then return nil end
    seen[id] = true
    local sum = 0
    for _, r in ipairs(reagents) do
        local rid, n = num(r[1]), num(r[2])
        local c = rid and n and Cost(rid, depth + 1, seen)
        if not c then seen[id] = nil; return nil end
        sum = sum + c * n
    end
    seen[id] = nil
    return sum, "crafted"
end
function CP.Get(id)
    id = num(id)
    if not id or not CP.On() then return nil end
    return Cost(id, 0, {})
end

-- ---------------------------------------------------------------- purchases
local api = C_AuctionHouse
local commodity            -- { id, qty, unit } between Start and the purchase result
local bids = {}            -- [auctionID] = { id, qty, unit }
local itemKeys = {}        -- the last item searches, to find which item an auction is
local hasCommodityEvent, hasItemEvent = false, false

local function Field(t, k)
    local ok, v = pcall(function() return t[k] end)
    if ok then return v end
end

local function FindAuction(auctionID)
    if not (api and api.GetNumItemSearchResults and api.GetItemSearchResultInfo) then return nil end
    for i = #itemKeys, 1, -1 do
        local key = itemKeys[i]
        local ok, n = pcall(api.GetNumItemSearchResults, key)
        n = ok and num(n) or 0
        for j = 1, n do
            local ok2, r = pcall(api.GetItemSearchResultInfo, key, j)
            if ok2 and type(r) == "table" and Field(r, "auctionID") == auctionID then return r, key end
        end
    end
end

local function KeyStr(k)
    if type(k) ~= "table" then return nil end
    local id = num(Field(k, "itemID"))
    if not id then return nil end
    local function n(f) local v = Field(k, f); return (type(v) == "number" and not secret(v)) and v or 0 end
    return id .. ":" .. n("itemLevel") .. ":" .. n("itemSuffix") .. ":" .. n("battlePetSpeciesID")
end

-- Keeps a commodity buy once (the success event, or the timer if that event never comes).
local function KeepCommodity(c)
    if not c or c.done then return end
    c.done = true
    if commodity == c then commodity = nil end
    pcall(CP.Record, c.id, c.qty, c.unit)
end

local function OnStartCommodities(itemID, quantity)
    if not CP.On() then return end
    commodity = { id = num(itemID), qty = num(quantity) }
end
local function OnConfirmCommodities(itemID, quantity)
    if not CP.On() then return end
    local c = commodity
    if not c or c.done or c.confirmed or (num(itemID) and c.id ~= itemID) then c = { id = num(itemID) } end
    c.qty = num(quantity) or c.qty
    commodity = c
    -- no unit price from COMMODITY_PRICE_UPDATED: the cheapest listings the buy walks through
    if not c.unit and c.id and c.qty and api and api.GetNumCommoditySearchResults then
        local ok, n = pcall(api.GetNumCommoditySearchResults, c.id)
        n = ok and num(n) or 0
        local left, total = c.qty, 0
        for i = 1, n do
            local ok2, r = pcall(api.GetCommoditySearchResultInfo, c.id, i)
            local p, q = ok2 and type(r) == "table" and num(Field(r, "unitPrice")), ok2 and type(r) == "table" and num(Field(r, "quantity"))
            if p and q then
                local take = math.min(left, q)
                total = total + take * p; left = left - take
                if left <= 0 then break end
            end
        end
        if left <= 0 then c.unit = total / c.qty end
    end
    c.confirmed = true
    if not hasCommodityEvent then KeepCommodity(c); return end
    -- the success event registered but may never come on this client: keep the buy after 3 s
    -- unless it succeeded or failed meanwhile
    if C_Timer and C_Timer.After then
        pcall(C_Timer.After, 3, function() if not c.failed then KeepCommodity(c) end end)
    end
end
local function OnPlaceBid(auctionID, bidAmount)
    if not CP.On() then return end
    auctionID, bidAmount = num(auctionID), num(bidAmount)
    if not (auctionID and bidAmount) then return end
    local r, key = FindAuction(auctionID)
    if not r then return end
    local buyout = num(Field(r, "buyoutAmount"))
    -- a bid under the buyout is not a buy (it may be outbid): only buyouts count
    if not buyout or bidAmount < buyout then return end
    local qty = num(Field(r, "quantity")) or 1
    local id = num(Field(key, "itemID"))
    if not id then return end
    -- the buyout is for the whole listing
    local b = { id = id, qty = qty, unit = bidAmount / qty }
    if hasItemEvent then bids[auctionID] = b else CP.Record(b.id, b.qty, b.unit) end
end

local hooked = false
local function Hook()
    api = api or C_AuctionHouse
    if hooked or not (api and hooksecurefunc) then return end
    hooked = true
    for name, fn in pairs({
        StartCommoditiesPurchase = OnStartCommodities, ConfirmCommoditiesPurchase = OnConfirmCommodities,
        PlaceBid = OnPlaceBid, PostItem = function(...) CP.OnPost("item", ...) end,
        PostCommodity = function(...) CP.OnPost("commodity", ...) end,
    }) do
        if api[name] then pcall(hooksecurefunc, api, name, function(...) pcall(fn, ...) end) end
    end
end

-- ---------------------------------------------------------------- posting under cost
local function LocationItem(loc)
    if loc == nil or secret(loc) then return nil end
    if type(loc) == "number" then return num(loc) end
    local get = C_Item and C_Item.GetItemID
    if get then
        local ok, id = pcall(get, loc)
        if ok and num(id) then return id end
    end
    local ok, id = pcall(function() return loc:GetItemID() end)
    if ok then return num(id) end
end

-- The whole stack posted: its bag slot may be empty already, so ask the sell frame what it holds.
local function SellFrameItem(kind)
    local ah = AuctionHouseFrame
    if not ah then return nil end
    local frames = kind == "commodity" and { "CommoditiesSellFrame", "ItemSellFrame" } or { "ItemSellFrame", "CommoditiesSellFrame" }
    for _, name in ipairs(frames) do
        local fr = Field(ah, name)
        if type(fr) == "table" then
            local ok, v = pcall(function() return fr.GetItem and fr:GetItem() end)
            if ok and v ~= nil and not secret(v) then
                local id = LocationItem(v)
                if id then return id end
            end
            local loc = Field(fr, "itemLocation")
            local id = loc ~= nil and LocationItem(loc)
            if id then return id end
        end
    end
end

-- PostItem(location, duration, quantity, bid, buyout): the buyout is per item (each one is its own
-- auction); PostCommodity(location, duration, quantity, unitPrice).
function CP.OnPost(kind, loc, _, quantity, a, b)
    if not CP.On() then return end
    local unit = kind == "commodity" and num(a) or num(b)
    if not unit then return end
    local id = LocationItem(loc) or SellFrameItem(kind)
    if not id then return end
    -- only a cost you paid warns: a reagent sum is per craft, and a craft can make several items
    local cost, how = CP.Get(id)
    if not cost or how ~= "bought" or unit >= cost then return end
    local name = WP.ItemName and WP.ItemName(id) or ("item:" .. id)
    WP.Print(string.format(L("Attention : %s mis en vente à %s l'unité, sous ton prix de revient (%s)."),
        name, S.Money(unit), S.Money(cost)), true)
end

-- ---------------------------------------------------------------- tooltip
function CP.TooltipText(id)
    local c, how = CP.Get(id)
    if not c then return nil end
    if how == "crafted" then return string.format(L("Prix de revient (composants, par fabrication) : %s"), S.Money(c)) end
    return string.format(L("Prix de revient : %s"), S.Money(c))
end

local function AddLine(tooltip, id)
    if not tooltip or secret(id) then return end
    local text = CP.TooltipText(id)
    if not text then return end
    local C = S.C
    -- no tooltip:Show() from here: called from an addon it can taint GameTooltip (the "blocked"
    -- popups); the game sizes the tooltip after its post-calls (as Upgrades.lua relies on)
    tooltip:AddLine(text, C.muted[1], C.muted[2], C.muted[3])
end
CP.AddLine = AddLine

if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip, info)
        if tooltip ~= GameTooltip and tooltip ~= ItemRefTooltip then return end
        pcall(AddLine, tooltip, info and Field(info, "id"))
    end)
else
    for _, tt in ipairs({ GameTooltip, ItemRefTooltip }) do
        if tt and tt.HookScript then
            pcall(tt.HookScript, tt, "OnTooltipSetItem", function(tooltip)
                local ok, _, link = pcall(tooltip.GetItem, tooltip)
                if ok and type(link) == "string" and not secret(link) then pcall(AddLine, tooltip, tonumber(link:match("item:(%d+)"))) end
            end)
        end
    end
end

-- ---------------------------------------------------------------- events
local f = CreateFrame("Frame")
hasCommodityEvent = pcall(f.RegisterEvent, f, "COMMODITY_PURCHASE_SUCCEEDED") and true or false
hasItemEvent = pcall(f.RegisterEvent, f, "AUCTION_HOUSE_PURCHASE_COMPLETED") and true or false
for _, e in ipairs({ "COMMODITY_PRICE_UPDATED", "COMMODITY_PURCHASE_FAILED", "ITEM_SEARCH_RESULTS_UPDATED",
                     "AUCTION_HOUSE_SHOW", "AUCTION_HOUSE_CLOSED", "PLAYER_LOGIN" }) do
    pcall(f.RegisterEvent, f, e)
end
f:SetScript("OnEvent", function(_, e, a1, a2)
    if e == "PLAYER_LOGIN" then pcall(CP.Prune); Hook(); return end
    if e == "AUCTION_HOUSE_SHOW" then Hook(); return end
    -- a buy may still be waiting for its result: only the searches are forgotten on close
    if e == "AUCTION_HOUSE_CLOSED" then itemKeys = {}; return end
    if e == "ITEM_SEARCH_RESULTS_UPDATED" then
        local ks = not secret(a1) and KeyStr(a1)
        if ks then
            for i = #itemKeys, 1, -1 do if KeyStr(itemKeys[i]) == ks then table.remove(itemKeys, i) end end
            itemKeys[#itemKeys + 1] = a1
            if #itemKeys > 5 then table.remove(itemKeys, 1) end
        end
    elseif e == "COMMODITY_PRICE_UPDATED" then
        -- (unit price, total price) the game asks you to confirm
        local unit, total = num(a1), num(a2)
        if commodity then
            if total and commodity.qty then commodity.unit = total / commodity.qty else commodity.unit = unit or commodity.unit end
        end
    elseif e == "COMMODITY_PURCHASE_SUCCEEDED" then
        KeepCommodity(commodity)
    elseif e == "COMMODITY_PURCHASE_FAILED" then
        if commodity then commodity.failed = true; commodity.done = true end
        commodity = nil
    elseif e == "AUCTION_HOUSE_PURCHASE_COMPLETED" then
        local id = num(a1)
        local b = id and bids[id]
        if b then bids[id] = nil; pcall(CP.Record, b.id, b.qty, b.unit) end
    end
end)
Hook()

-- test access
CP._state = function() return commodity, bids, itemKeys end
