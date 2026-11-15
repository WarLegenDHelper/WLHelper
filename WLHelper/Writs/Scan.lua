-- Scan.lua: the addon's own auction house scan, so prices need neither Auctionator nor TSM.
-- Items are asked by item ID through C_AuctionHouse.SearchForItemKeys, twenty keys a request,
-- the call Blizzard's own favourites search makes; each answer is a browse result per listed item
-- (minPrice, totalQuantity). An item missing from a full answer is not for sale. Results go into
-- WLWritsDB.ah[itemID] = { p = lowest unit price, q = quantity listed, t = time() }.
-- The browse list in Blizzard's window shows each batch as it comes back.
local ADDON, root = ...
-- The Writs module of WL Helper keeps its own table inside the addon's namespace.
root.Writs = root.Writs or {}
local ns = root.Writs
local WP = ns.WP
local L = ns.L

local S = {}
WP.Scan = S

local BATCH = 20      -- item keys per request
local TIMEOUT = 10    -- seconds to wait for an answer before moving on
local api = C_AuctionHouse

local state   -- nil while idle: { queue, pos, total, done, listed, batch, want, token }

local function Available()
    return api and api.SearchForItemKeys and api.MakeItemKey and api.GetBrowseResults and true or false
end
S.Available = Available

local sorts
local function Sorts()
    if not sorts then
        local price = Enum and Enum.AuctionHouseSortOrder and Enum.AuctionHouseSortOrder.Price or 0
        sorts = { { sortOrder = price, reverseSort = false } }
    end
    return sorts
end

local function Ready()
    if api.IsThrottledMessageSystemReady then
        local ok, ready = pcall(api.IsThrottledMessageSystemReady)
        return not ok or ready ~= false
    end
    return true
end

local function IsEquipment(id)
    local GetInfo = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
    if not GetInfo then return false end
    local ok, _, _, _, equipLoc = pcall(GetInfo, id)
    return ok and type(equipLoc) == "string" and equipLoc ~= "" and equipLoc ~= "INVTYPE_NON_EQUIP_IGNORE"
end

local function Book()
    local db = WLWritsDB
    db.ah = db.ah or {}
    return db.ah
end

function S.Busy() return state ~= nil end
function S.Progress() if state then return state.done, state.total end end

local function Changed()
    if WP.OnScanProgress then WP.OnScanProgress() end
end

local function Finish()
    local st = state
    state = nil
    Changed()
    if WP.RefreshSoon then WP.RefreshSoon() end
    if st then WP.Print(string.format(L("scan terminé : %d objets, %d en vente."), st.total, st.listed)) end
end

local SendNext

local function OnResults()
    if not state or not state.batch then return end
    if api.HasFullBrowseResults and not api.HasFullBrowseResults() then
        if api.RequestMoreBrowseResults then pcall(api.RequestMoreBrowseResults) end
        return
    end
    local ok, results = pcall(api.GetBrowseResults)
    if not ok or type(results) ~= "table" then return end
    -- Only an answer that names at least one item of this batch is ours: the player's own
    -- searches, Blizzard's favourites and other addons fill the same browse list.
    local ours = false
    for _, r in ipairs(results) do
        local id = type(r) == "table" and r.itemKey and r.itemKey.itemID
        if id and state.want[id] then ours = true; break end
    end
    if not ours then return end
    local seen = {}
    for _, r in ipairs(results) do
        local id = type(r) == "table" and r.itemKey and r.itemKey.itemID
        if id and state.want[id] then
            local price, qty = tonumber(r.minPrice), tonumber(r.totalQuantity) or 0
            local prev = seen[id]
            if not prev then
                seen[id] = { p = price, q = qty }
            else
                if price and (not prev.p or price < prev.p) then prev.p = price end
                prev.q = prev.q + qty
            end
        end
    end
    local book, now = Book(), time()
    for _, id in ipairs(state.batch) do
        local v = seen[id]
        if v then
            book[id] = { p = v.p, q = v.q, t = now }
            if v.q > 0 then state.listed = state.listed + 1 end
        elseif not IsEquipment(id) then
            -- Missing from an answer about this batch: not for sale. Equipment is left as it was,
            -- since a bare item key may not match listings that carry an item level.
            book[id] = { q = 0, t = now }
        end
    end
    state.done = state.done + #state.batch
    state.batch, state.want, state.token = nil, nil, nil
    Changed()
    C_Timer.After(0.2, SendNext)
end

SendNext = function()
    if not state or state.batch then return end
    if not WP.AuctionHouseOpen() then state = nil; Changed(); return end
    if state.pos > #state.queue then Finish(); return end
    if not Ready() then C_Timer.After(0.5, SendNext); return end
    local batch, keys, want = {}, {}, {}
    for i = state.pos, math.min(#state.queue, state.pos + BATCH - 1) do
        local id = state.queue[i]
        local ok, key = pcall(api.MakeItemKey, id)
        if ok and key then
            batch[#batch + 1], keys[#keys + 1], want[id] = id, key, true
        end
    end
    state.pos = state.pos + BATCH
    if #batch == 0 then SendNext(); return end
    local token = {}
    state.batch, state.want, state.token = batch, want, token
    pcall(api.SearchForItemKeys, keys, Sorts())
    -- No answer in time: leave this batch's prices as they were and go on.
    C_Timer.After(TIMEOUT, function()
        if state and state.token == token then S.SkipBatch() end
    end)
end

-- Gives up on the pending batch (timeout or a failed search) and goes on with the next one.
function S.SkipBatch()
    if not state or not state.batch then return end
    state.done = state.done + #state.batch
    state.batch, state.want, state.token = nil, nil, nil
    Changed()
    C_Timer.After(0.5, SendNext)
end

-- Scans the given item IDs (duplicates removed). The auction house must be open.
function S.Start(ids)
    if state then WP.Print(L("un scan est déjà en cours.")); return end
    if not WP.AuctionHouseOpen() then WP.Print(L("ouvre l'hôtel des ventes d'abord.")); return end
    if not Available() then WP.Print(L("le scan n'est pas disponible sur ce client.")); return end
    local queue, seen = {}, {}
    for _, id in ipairs(ids) do
        if id and not seen[id] then seen[id] = true; queue[#queue + 1] = id end
    end
    if #queue == 0 then WP.Print(L("rien à chercher.")); return end
    state = { queue = queue, pos = 1, total = #queue, done = 0, listed = 0 }
    Changed()
    SendNext()
end

function S.Stop()
    if state then state = nil; Changed() end
end

-- The latest scan of an item: price, quantity listed, seconds since; nil if never scanned.
function S.Get(id)
    local e = WLWritsDB and WLWritsDB.ah and WLWritsDB.ah[id]
    if type(e) == "table" and e.t then return e.p, e.q or 0, time() - e.t end
end

-- ---------------------------------------------------------------- buying in Blizzard's window

-- Opens an item's buy page in the auction house and, for a stackable item, fills in the quantity.
function S.OpenToBuy(id, quantity)
    local ah = AuctionHouseFrame
    if not (ah and ah:IsShown() and ah.SelectBrowseResult and api and api.MakeItemKey) then
        WP.Print(L("ouvre l'hôtel des ventes d'abord."))
        return
    end
    local ok, key = pcall(api.MakeItemKey, id)
    if not ok or not key then return end
    local price = S.Get(id)
    local function open(tries)
        -- Blizzard's page needs the item key's info cached; ask for it and try again shortly.
        if api.GetItemKeyInfo and not select(2, pcall(api.GetItemKeyInfo, key)) and tries > 0 then
            C_Timer.After(0.3, function() open(tries - 1) end)
            return
        end
        pcall(ah.SelectBrowseResult, ah, { itemKey = key, minPrice = price or 0, totalQuantity = 0 })
        if not quantity or quantity <= 1 then return end
        -- The buy page resets the quantity when its listings arrive: set it after that, and a
        -- second time only if it still shows the default, so a number the player typed stays.
        local function fill(onlyIfDefault)
            local buy = ah.CommoditiesBuyFrame
            local display = buy and buy:IsShown() and buy.BuyDisplay
            local input = display and display.QuantityInput
            if not (input and input.SetQuantity) then return end
            if onlyIfDefault and input.GetQuantity then
                local okQ, q = pcall(input.GetQuantity, input)
                if okQ and q and q > 1 then return end
            end
            pcall(input.SetQuantity, input, quantity)
            if display.SetQuantitySelected then pcall(display.SetQuantitySelected, display, quantity) end
        end
        C_Timer.After(0.6, function() fill(false) end)
        C_Timer.After(1.5, function() fill(true) end)
    end
    open(5)
end

-- ---------------------------------------------------------------- events

local f = CreateFrame("Frame")
f:RegisterEvent("AUCTION_HOUSE_BROWSE_RESULTS_UPDATED")
f:RegisterEvent("AUCTION_HOUSE_BROWSE_RESULTS_ADDED")
f:RegisterEvent("AUCTION_HOUSE_BROWSE_FAILURE")
f:RegisterEvent("AUCTION_HOUSE_SHOW")
f:RegisterEvent("AUCTION_HOUSE_CLOSED")
f:SetScript("OnEvent", function(_, event)
    if event == "AUCTION_HOUSE_CLOSED" then
        S.Stop()
    elseif event == "AUCTION_HOUSE_BROWSE_FAILURE" then
        S.SkipBatch()
    elseif event == "AUCTION_HOUSE_SHOW" then
        -- Last-minute prices: rescan the shopping list as the auction house opens.
        if WLWritsDB and WLWritsDB.autoRescan and WP.ShoppingIDs and WP.ModuleOn("writs") then
            -- After Blizzard's own favourites search has had its turn.
            C_Timer.After(4, function()
                local ids = WP.ShoppingIDs()
                if ids and #ids > 0 and not state then S.Start(ids) end
            end)
        end
    else
        OnResults()
    end
end)
