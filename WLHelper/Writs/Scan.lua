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

ns.AddEnglish({
    ["%s : plus en vente, je passe au suivant."] = "%s: no longer for sale, moving on.",
})

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

-- A queue of items to buy one after the other (a writ's envelope, then its item, or the whole
-- shopping list): the next buy page opens by itself once a purchase goes through. The player still
-- clicks the game's own Buy button each time; nothing is bought by the addon.
local queue = {}
local queueTotal, queuePos, lastPop = 0, 0, 0

local function QueueChanged()
    if WP.OnScanProgress then WP.OnScanProgress() end
end

-- Opens the buy page of item, or skips it when the last scan (under 30 min) saw none for sale.
local OpenNext
OpenNext = function(item)
    if not item then queueTotal, queuePos = 0, 0; QueueChanged(); return end
    local _, q, age = S.Get(item.id)
    if q == 0 and age and age < 1800 then
        WP.Print(string.format(L("%s : plus en vente, je passe au suivant."), WP.ItemName(item.id) or "?"))
        queuePos = queuePos + 1
        local nxt = table.remove(queue, 1)
        if not nxt then queueTotal, queuePos = 0, 0 end
        QueueChanged()
        if nxt then OpenNext(nxt) end
        return
    end
    S.OpenToBuy(item.id, item.qty)
end

function S.BuyQueue(list)
    queue = {}
    for _, e in ipairs(list) do queue[#queue + 1] = e end
    queueTotal, queuePos = #queue, 1
    local first = table.remove(queue, 1)
    if not first then queueTotal, queuePos = 0, 0 end
    QueueChanged()
    if first then OpenNext(first) end
end
-- Items still waiting after the open buy page; the place in the queue ("2 of 9"), 0, 0 when idle.
function S.QueueLeft() return #queue end
function S.QueueState() return queuePos, queueTotal end
function S.ClearQueue()
    queue = {}
    queueTotal, queuePos = 0, 0
    QueueChanged()
end
local qf = CreateFrame("Frame")
for _, e in ipairs({ "COMMODITY_PURCHASE_SUCCEEDED", "AUCTION_HOUSE_PURCHASE_COMPLETED", "AUCTION_HOUSE_CLOSED" }) do pcall(qf.RegisterEvent, qf, e) end
qf:SetScript("OnEvent", function(_, e)
    if e == "AUCTION_HOUSE_CLOSED" then S.ClearQueue(); return end
    if queueTotal == 0 then return end
    -- both purchase events can fire for one buy: count it once, or a long queue skips an item
    if GetTime() - lastPop < 1 then return end
    lastPop = GetTime()
    local nxt = table.remove(queue, 1)
    if nxt then
        queuePos = queuePos + 1
        C_Timer.After(0.6, function() OpenNext(nxt) end)
    else
        queueTotal, queuePos = 0, 0
    end
    QueueChanged()
end)

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
pcall(f.RegisterEvent, f, "AUCTION_HOUSE_BROWSE_RESULTS_UPDATED")
pcall(f.RegisterEvent, f, "AUCTION_HOUSE_BROWSE_RESULTS_ADDED")
pcall(f.RegisterEvent, f, "AUCTION_HOUSE_BROWSE_FAILURE")
pcall(f.RegisterEvent, f, "AUCTION_HOUSE_SHOW")
pcall(f.RegisterEvent, f, "AUCTION_HOUSE_CLOSED")
f:SetScript("OnEvent", function(_, event)
    if event == "AUCTION_HOUSE_CLOSED" then
        S.Stop()
    elseif event == "AUCTION_HOUSE_BROWSE_FAILURE" then
        S.SkipBatch()
    elseif event == "AUCTION_HOUSE_SHOW" then
        -- Last-minute prices, only when they are needed: the Trading Post window is open, and
        -- some item of the shopping list has no price or one older than an hour.
        -- The Writs window already open with something to buy: straight to the Shopping tab.
        if WP.WindowShown and WP.WindowShown() and WP.WritsMode and WP.WritsMode() and WP.ShoppingIDs
            and #(WP.ShoppingIDs() or {}) > 0 and WP.ShowTab then
            WP.ShowTab("shop")
        end
        if WLWritsDB and WLWritsDB.autoRescan and WP.ShoppingIDs and WP.ModuleOn("writs") then
            -- After Blizzard's own favourites search has had its turn.
            C_Timer.After(4, function()
                if not (WP.WindowShown and WP.WindowShown()) then return end
                local ids = WP.ShoppingIDs()
                if not ids or #ids == 0 or state then return end
                local stale = false
                for _, id in ipairs(ids) do
                    local e = Book()[id]
                    if not (type(e) == "table" and e.t and time() - e.t < 3600) then stale = true; break end
                end
                if stale then S.Start(ids) end
            end)
        end
    else
        OnResults()
    end
end)
