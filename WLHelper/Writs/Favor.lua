-- Writs/Favor.lua: the Merchant's Favor planner (the Comptoir's "Favor" tab).
-- A Waylaid Crate, filled with one of the material bundles it accepts, becomes a Supply Shipment
-- that is handed in for Merchant's Favor. For each crate: crate price + the cheapest bundle (what
-- you already hold is free), divided by the Favor it gives = the price of one Favor. "I want 300"
-- then takes the cheapest crates until the Favor you miss is covered, and lists what to buy.
--
-- Which bundles a crate takes is read live from Naowh Forever when it is loaded (its data is not
-- copied here). The Favor a crate gives: what you learned yourself handing one in, then
-- Mastercraft's own learning, then the values known so far; marked "~" until confirmed.
local ADDON, root = ...
root.Writs = root.Writs or {}
local ns = root.Writs
local WP = ns.WP
local L = ns.L
local S = ns.S
local C = S.C

ns.AddEnglish({
    ["Favor"] = "Favor",
    ["Merchant's Favor : %s"] = "Merchant's Favor: %s",
    ["Objectif"] = "Goal",
    ["Il te manque %s Favor."] = "You need %s more Favor.",
    ["Objectif atteint : tu as déjà assez de Favor."] = "Goal reached: you already have enough Favor.",
    ["%d caisses · %s · %s la Favor"] = "%d crates · %s · %s per Favor",
    [" la Favor"] = " per Favor",
    ["~%d Favor"] = "~%d Favor",
    ["Scan %d / %d · clic pour arrêter"] = "Scan %d / %d · click to stop",
    ["Le plan, de la moins chère"] = "The plan, cheapest first",
    ["Toutes les caisses, par prix de la Favor"] = "Every crate, by price per Favor",
    ["Caisses : ~ veut dire une Favor estimée, confirmée à ta première remise."] = "Crates: ~ means an estimated Favor, confirmed at your first hand-in.",
    ["Ce planificateur a besoin de Naowh Forever.\nC'est lui qui connaît les lots de chaque caisse : active-le."] =
        "This planner needs Naowh Forever.\nIt knows each crate's bundles: turn it on.",
    ["Scanner les prix (HV)"] = "Scan prices (AH)",
    ["Ouvre l'hôtel des ventes pour scanner"] = "Open the auction house to scan",
    ["%d Favor"] = "%d Favor",
    ["~%d Favor (à confirmer)"] = "~%d Favor (to confirm)",
    ["Favor inconnue : rends-en une pour l'apprendre"] = "Favor unknown: hand one in to learn it",
    ["prix inconnu : scanne l'HV"] = "price unknown: scan the AH",
    ["Clic : acheter la caisse · Maj-clic : le lot"] = "Click: buy the crate · Shift-click: the bundle",
    ["Clic : acheter les caisses à l'HV"] = "Click: buy the crates at the AH",
    ["%d Favor · à remplir avec %d× %s chacune"] = "%d Favor · fill each with %d× %s",
    ["tu en as %d"] = "you have %d",
    ["Rendre les caisses"] = "Turn crates in",
    ["Dokimi, Inventory Intake : The Barrens, porte ouest de la Croisée (50, 29)"] = "Dokimi, Inventory Intake: The Barrens, west gate of the Crossroads (50, 29)",
    ["Marcy Baker, Inventory Intake : Redridge, Three Corners (10, 71)"] = "Marcy Baker, Inventory Intake: Redridge, Three Corners (10, 71)",
    ["déjà là"] = "already have",
    ["Prix réels : %d objets restants"] = "Real prices: %d items left",
    ["Prix à jour · à l'instant"] = "Prices up to date · just now",
    ["Prix d'il y a %d min · rescanner"] = "Prices from %d min ago · rescan",
    ["Prix d'il y a %d min · ouvre l'HV pour rescanner"] = "Prices from %d min ago · open the AH to rescan",
    ["%d Favor · un lot par caisse : %s"] = "%d Favor · one bundle per crate: %s",
    ["pour %d caisses"] = "for %d crates",
    ["Prix réels de l'HV, offre par offre."] = "Real AH prices, listing by listing.",
    ["Prix réels de l'HV, mais pas assez en vente pour tout."] = "Real AH prices, but not enough for sale for all of it.",
    ["~ prix estimé : ouvre l'HV pour le prix réel, offre par offre."] = "~ estimated: open the AH for the real price, listing by listing.",
    ["(dont %d en banque)"] = "(%d in the bank)",
    ["ou "] = "or ",
    [" ou "] = " or ",
    ["Clic : l'acheter à l'HV"] = "Click: buy it at the AH",
    ["à acheter : %d"] = "to buy: %d",
    ["dans tes sacs : %d"] = "in your bags: %d",
    ["Favor apprise : %s donne %d."] = "Favor learned: %s gives %d.",
    ["par Favor"] = "per Favor",
})

local CURRENCY = 3402   -- Merchant's Favor (Wowhead Forever)

-- Favor per crate known so far (Wowhead Forever / guides); learned values replace them.
local KNOWN = {
    [248686] = 10, [248688] = 10,                               -- Journeyman herbs, textiles
    [248690] = 15, [248691] = 15, [248692] = 15, [248693] = 15, -- Expert herbs, ore, textiles
    [248705] = 20, [248706] = 20,                               -- Journeyman fabrics, ingots
    [248708] = 30, [248709] = 30, [248710] = 30,                -- Expert fabrics, ingots, parts
}

local function safe(f, ...)
    if not f then return nil end
    local ok, a, b, c, d = pcall(f, ...)
    if ok then return a, b, c, d end
end

local function Bundles()
    local N = rawget(_G, "NaowhForever")
    local t = type(N) == "table" and N.WaylaidCrates
    return type(t) == "table" and t or nil
end

-- Bags and bank: what is in the bank does not need to be bought.
local function Count(id)
    if WP.OwnedCount then return WP.OwnedCount(id) end
    return safe(C_Item and C_Item.GetItemCount, id, true) or safe(GetItemCount, id, true) or 0
end

local function ItemLevel(id)
    local _, _, _, lvl = safe(C_Item and C_Item.GetItemInfo or GetItemInfo, id)
    return lvl
end

function WP.FavorNow()
    local info = C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo and safe(C_CurrencyInfo.GetCurrencyInfo, CURRENCY)
    return info and info.quantity or nil
end

-- Favor of one crate, and whether it is confirmed (learned) or estimated.
function WP.CrateFavor(id)
    local db = WLWritsDB
    local learned = db and db.favorByCrate and db.favorByCrate[id]
    if learned then return learned, true end
    local lvl = ItemLevel(id)
    local mine = lvl and db and db.favorByLevel and db.favorByLevel[lvl]
    if mine then return mine, true end
    local mc = rawget(_G, "MastercraftDB")
    local theirs = lvl and type(mc) == "table" and type(mc.favorByLevel) == "table" and mc.favorByLevel[lvl]
    if theirs then return theirs, true end
    return KNOWN[id], false
end

-- One line per crate: price of the crate, best bundle, total, Favor, price per Favor.
function WP.FavorRows()
    local B = Bundles()
    if not B then return nil end
    local rows = {}
    for id, bundles in pairs(B) do
        local favor, sure = WP.CrateFavor(id)
        local cratePrice = WP.Price(id)
        local best
        for _, b in ipairs(bundles) do
            local item, qty = b[1], b[2]
            local p = WP.Price(item)
            if p then
                local need = math.max(0, qty - Count(item))
                local cost = p * need
                if not best or cost < best.cost then best = { item = item, qty = qty, unit = p, cost = cost } end
            end
        end
        local r = { id = id, favor = favor, sure = sure, cratePrice = cratePrice, bundle = best, bundles = bundles,
            haveCrate = Count(id) }
        if favor and favor > 0 and best and (cratePrice or r.haveCrate > 0) then
            r.total = (r.haveCrate > 0 and 0 or cratePrice) + best.cost
            r.per = r.total / favor
        end
        rows[#rows + 1] = r
    end
    table.sort(rows, function(a, b)
        if a.per and b.per then return a.per < b.per end
        if a.per or b.per then return a.per ~= nil end
        return a.id < b.id
    end)
    return rows
end

-- The cheapest crates until `missing` Favor is covered. Each line: crate, how many, bundle, cost.
function WP.FavorPlan(missing, rows)
    local plan, total, favor = {}, 0, 0
    if not rows or missing <= 0 then return plan, 0, 0 end
    for _, r in ipairs(rows) do
        if favor >= missing then break end
        if r.per then
            local n = math.ceil((missing - favor) / r.favor)
            -- no more than the crates you hold plus those for sale at the last scan (when scanned)
            local _, listed, ago = nil, nil, nil
            if WP.Scan and WP.Scan.Get then _, listed, ago = WP.Scan.Get(r.id) end
            if listed and ago and ago < 3600 then n = math.min(n, r.haveCrate + listed) end
            if n > 0 then
                local crates = math.max(0, n - r.haveCrate)
                -- the real price when the listings were read (Ladder.lua), else the lowest price x n
                local crateCost, crateAll = WP.CostFor and WP.CostFor(r.id, crates)
                local exact = crateCost ~= nil
                crateCost = crateCost or crates * (r.cratePrice or 0)
                -- Each crate takes ONE bundle, but crates may use different ones: crate by crate, the
                -- bundle whose next units cost least (what you own is free; the real listings when read).
                local opts = {}
                for _, b in ipairs(r.bundles or {}) do
                    opts[#opts + 1] = { item = b[1], qty = b[2], owned = Count(b[1]), taken = 0, crates = 0 }
                end
                local function upto(o, units)   -- cost of having `units` of this material
                    local buy = math.max(0, units - o.owned)
                    local c, all = nil, true
                    if WP.CostFor then c, all = WP.CostFor(o.item, buy) end
                    if c then return c, true, all end
                    local unit = WP.Price(o.item)
                    if unit then return unit * buy, false, true end
                end
                local matCost, matExact, matAll, ok = 0, true, true, true
                for _ = 1, n do
                    local best, bestStep
                    for _, o in ipairs(opts) do
                        local before = upto(o, o.taken)
                        local after = upto(o, o.taken + o.qty)
                        if before and after and (not best or after - before < bestStep) then best, bestStep = o, after - before end
                    end
                    if not best then ok = false; break end
                    best.taken, best.crates = best.taken + best.qty, best.crates + 1
                end
                local used = {}
                if ok then
                    for _, o in ipairs(opts) do
                        if o.crates > 0 then
                            local c, ex, all = upto(o, o.taken)
                            o.cost, o.buy = c, math.max(0, o.taken - o.owned)
                            matCost = matCost + c
                            matExact = matExact and ex
                            matAll = matAll and all
                            used[#used + 1] = o
                        end
                    end
                end
                if ok and #used > 0 then
                    local cost = crateCost + matCost
                    plan[#plan + 1] = { row = r, n = n, crates = crates, used = used, opts = opts,
                        crateCost = crateCost, matCost = matCost, cost = cost,
                        exact = exact and matExact, short = crateAll == false or not matAll }
                    total = total + cost
                    favor = favor + n * r.favor
                end
            end
        end
    end
    return plan, total, favor
end

-- Every item the planner prices: the crates and every bundle's material.
function WP.FavorScanIDs()
    local ids = {}
    for id, bundles in pairs(Bundles() or {}) do
        ids[#ids + 1] = id
        for _, b in ipairs(bundles) do ids[#ids + 1] = b[1] end
    end
    return ids
end

-- ---------------------------------------------------------------- learning the Favor of a crate
-- A Supply Shipment leaves your bags and Merchant's Favor goes up within a few seconds: that
-- amount is what a shipment of that item level gives (the smallest seen: a bonus may double one).
local shipments, removedAt, removedLevel, gainAt, gain, lastFavor
local function CountShipments()
    local counts = {}
    if not (C_Container and C_Container.GetContainerNumSlots) then return counts end
    for bag = 0, NUM_BAG_SLOTS or 4 do
        for slot = 1, safe(C_Container.GetContainerNumSlots, bag) or 0 do
            local info = safe(C_Container.GetContainerItemInfo, bag, slot)
            local link = info and info.hyperlink
            local name = link and link:match("%[(.-)%]")
            if name and name:lower():find("supply shipment", 1, true) then
                local lvl = ItemLevel(link)
                if lvl then counts[lvl] = (counts[lvl] or 0) + (info.stackCount or 1) end
            end
        end
    end
    return counts
end
local function Learn()
    if not (removedAt and gainAt and math.abs(removedAt - gainAt) < 8 and gain and gain > 0) then return end
    local db = WLWritsDB
    db.favorByLevel = db.favorByLevel or {}
    local old = db.favorByLevel[removedLevel]
    db.favorByLevel[removedLevel] = old and math.min(old, gain) or gain
    if not old then WP.Print(string.format(L("Favor apprise : %s donne %d."), "Supply Shipment (" .. removedLevel .. ")", gain)) end
    removedAt, gainAt = nil, nil
end

local ev = CreateFrame("Frame")
pcall(ev.RegisterEvent, ev, "PLAYER_ENTERING_WORLD")
pcall(ev.RegisterEvent, ev, "BAG_UPDATE_DELAYED")
pcall(ev.RegisterEvent, ev, "CURRENCY_DISPLAY_UPDATE")
ev:SetScript("OnEvent", function(_, e)
    if not WP.ModuleOn("writs") or not WLWritsDB then return end
    if e == "PLAYER_ENTERING_WORLD" then
        lastFavor = WP.FavorNow(); shipments = CountShipments()
    elseif e == "BAG_UPDATE_DELAYED" then
        local now = CountShipments()
        for lvl, n in pairs(shipments or {}) do
            if (now[lvl] or 0) < n then removedAt, removedLevel = GetTime(), lvl end
        end
        shipments = now
        Learn()
    else
        local f = WP.FavorNow()
        if f and lastFavor and f > lastFavor then gainAt, gain = GetTime(), f - lastFavor; Learn() end
        lastFavor = f or lastFavor
        if WP.RefreshSoon then WP.RefreshSoon(0.5) end
    end
end)

-- ---------------------------------------------------------------- the tab
local W, PAD, ROW = 400, 14, 44

-- "Waylaid Crate: Journeyman Ingots" -> "Journeyman Ingots" (the header already says crates)
local function CrateName(id)
    local n = WP.ItemName(id)
    return (n:match("^[^:]+:%s*(.+)$")) or n
end
local ui = {}

local function Pool(parent, make)
    local p = { items = {} }
    function p.Get(i) local f = p.items[i]; if not f then f = make(parent); p.items[i] = f end; f:Show(); return f end
    function p.HideFrom(i) for j = i, #p.items do p.items[j]:Hide() end end
    return p
end

local function MakeRow(parent)
    local r = CreateFrame("Button", nil, parent)
    r:SetSize(W - 2 * PAD, ROW)
    r:RegisterForClicks("LeftButtonUp")
    S.Solid(r, "BACKGROUND", C.card):SetAllPoints()
    S.Border(r, C.border)
    S.Solid(r, "HIGHLIGHT", { 1, 1, 1 }, 0.05):SetAllPoints()
    r.icon = r:CreateTexture(nil, "ARTWORK")
    r.icon:SetSize(20, 20); r.icon:SetPoint("LEFT", 10, 0); r.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    r.cost = S.Text(r, 14, C.text)
    r.cost:SetPoint("TOPRIGHT", -10, -6); r.cost:SetJustifyH("RIGHT")
    r.per = S.Text(r, 12, C.dim)
    r.per:SetPoint("BOTTOMRIGHT", -10, 6); r.per:SetJustifyH("RIGHT")
    r.name = S.Text(r, 14, C.text)
    r.name:SetPoint("TOPLEFT", 40, -6); r.name:SetPoint("RIGHT", r.cost, "LEFT", -8, 0)
    r.name:SetJustifyH("LEFT"); r.name:SetWordWrap(false)
    r.sub = S.Text(r, 12, C.dim)
    r.sub:SetPoint("BOTTOMLEFT", 40, 6); r.sub:SetPoint("RIGHT", r.per, "LEFT", -8, 0)
    r.sub:SetJustifyH("LEFT"); r.sub:SetWordWrap(false)
    r:SetScript("OnClick", function(self)
        local e = self.entry
        if not e or not WP.Scan then return end
        if e.mat then WP.Scan.OpenToBuy(e.mat, math.max(1, e.buy or 1))
        else WP.Scan.OpenToBuy(e.row.id, math.max(1, e.crates or 1)) end
    end)
    r:SetScript("OnEnter", function(self)
        local e = self.entry
        if not e then return end
        local row = e.row
        local lines = { WP.ItemName(row.id) }
        lines[#lines + 1] = row.favor and (row.sure and string.format(L("%d Favor"), row.favor) or string.format(L("~%d Favor (à confirmer)"), row.favor))
            or L("Favor inconnue : rends-en une pour l'apprendre")
        for _, b in ipairs(row.bundles or {}) do
            local p = WP.Price(b[1])
            lines[#lines + 1] = { b[2] .. "× " .. WP.ItemName(b[1]) .. "  " .. (p and S.Money(p * b[2]) or "?"),
                (row.bundle and row.bundle.item == b[1]) and 1 or 0.7, (row.bundle and row.bundle.item == b[1]) and 1 or 0.7, (row.bundle and row.bundle.item == b[1]) and 1 or 0.7 }
        end
        lines[#lines + 1] = { e.mat and L("Clic : l'acheter à l'HV") or L("Clic : acheter les caisses à l'HV"), 0.6, 0.6, 0.6 }
        S.Tip(self, lines)
    end)
    r:SetScript("OnLeave", S.HideTip)
    return r
end

function WP.BuildFavor(p)
    ui.page = p
    ui.now = S.Text(p, 15, C.text, true)
    ui.now:SetPoint("TOPLEFT", PAD, -14)
    local goalLabel = S.Text(p, 14, C.dim)
    goalLabel:SetPoint("TOPRIGHT", -PAD - 92, -16)
    goalLabel:SetText(L("Objectif"))
    local box = CreateFrame("EditBox", nil, p)
    box:SetSize(84, 28); box:SetPoint("TOPRIGHT", -PAD, -10)
    box:SetAutoFocus(false); box:SetNumeric(true); box:SetMaxLetters(6)
    local probe = S.Text(p, 14, C.text)
    local font, size, flags = probe:GetFont(); probe:Hide()
    if font then box:SetFont(font, size or 14, flags or "") else box:SetFontObject(ChatFontNormal) end
    box:SetTextColor(C.text[1], C.text[2], C.text[3]); box:SetJustifyH("RIGHT"); box:SetTextInsets(8, 8, 0, 0)
    S.Solid(box, "BACKGROUND", C.card):SetAllPoints()
    S.Border(box, C.border)
    box:SetScript("OnTextChanged", function(self, user)
        if not user then return end
        WLWritsCharDB.favorGoal = tonumber(self:GetText() or "") or 0
        if WP.RefreshSoon then WP.RefreshSoon(0.3) end
    end)
    box:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    ui.box = box
    ui.summary = S.Text(p, 13, C.dim)
    ui.summary:SetPoint("TOPLEFT", PAD, -46); ui.summary:SetPoint("TOPRIGHT", -PAD, -46)
    ui.summary:SetJustifyH("LEFT"); ui.summary:SetWordWrap(true)

    local sf = CreateFrame("ScrollFrame", nil, p)
    sf:SetPoint("TOPLEFT", PAD, -108); sf:SetPoint("BOTTOMRIGHT", -PAD, 62)
    local content = CreateFrame("Frame", nil, sf); content:SetSize(W - 2 * PAD, 10); sf:SetScrollChild(content)
    sf:EnableMouseWheel(true)
    sf:SetScript("OnMouseWheel", function(self, d)
        local max = math.max(0, content:GetHeight() - self:GetHeight())
        self:SetVerticalScroll(math.max(0, math.min(max, self:GetVerticalScroll() - d * 40)))
    end)
    ui.content = content
    ui.heads = Pool(content, function(parent) return S.Text(parent, 13, C.dim) end)
    ui.rows = Pool(content, MakeRow)
    ui.missing = S.Text(content, 13, C.warn)
    ui.missing:SetPoint("TOPLEFT", 2, -8); ui.missing:SetPoint("RIGHT", -2, 0); ui.missing:SetJustifyH("LEFT"); ui.missing:SetWordWrap(true)

    local foot = CreateFrame("Frame", nil, p)
    foot:SetPoint("BOTTOMLEFT"); foot:SetPoint("BOTTOMRIGHT"); foot:SetHeight(60)
    local line = S.Solid(foot, "BORDER", C.divider); line:SetPoint("TOPLEFT"); line:SetPoint("TOPRIGHT"); line:SetHeight(1)
    ui.scan = S.Button(foot, L("Scanner les prix (HV)"), W - 2 * PAD, 36, "primary", function()
        if WP.Scan.Busy() then WP.Scan.Stop() else WP.Scan.Start(WP.FavorScanIDs()) end
    end, function()
        return WP.AuctionHouseOpen() and { L("Scanner les prix (HV)") } or { L("Ouvre l'hôtel des ventes pour scanner") }
    end)
    ui.scan:SetWidth(W - 2 * PAD - 128)
    ui.scan:SetPoint("LEFT", PAD, 0)
    -- the Inventory Intake NPC who takes the filled crates (Supply Shipments)
    ui.go = S.Button(foot, L("Rendre les caisses"), 120, 36, "secondary", function()
        local horde = UnitFactionGroup("player") ~= "Alliance"
        if WP.GPS and WP.GPS.GoPoint then
            if horde then WP.GPS.GoPoint(1413, 50.13, 29.37, "Dokimi", "writs")
            else WP.GPS.GoPoint(1433, 9.71, 70.86, "Marcy Baker", "writs") end
        end
    end, function() return { L("Rendre les caisses"), UnitFactionGroup("player") ~= "Alliance"
        and L("Dokimi, Inventory Intake : The Barrens, porte ouest de la Croisée (50, 29)")
        or L("Marcy Baker, Inventory Intake : Redridge, Three Corners (10, 71)") } end)
    ui.go:SetPoint("RIGHT", -PAD, 0)
    ui.bar = CreateFrame("Frame", nil, foot)
    ui.bar:SetPoint("BOTTOMLEFT", ui.scan, "TOPLEFT", 0, 4); ui.bar:SetPoint("BOTTOMRIGHT", ui.scan, "TOPRIGHT", 0, 4)
    ui.bar:SetHeight(3)
    S.Solid(ui.bar, "BACKGROUND", C.divider):SetAllPoints()
    ui.barFill = S.Solid(ui.bar, "ARTWORK", C.ready)
    ui.barFill:SetPoint("TOPLEFT"); ui.barFill:SetPoint("BOTTOMLEFT")
    ui.bar:Hide()
end

function WP.RenderFavor()
    if not ui.page then return end
    local now = WP.FavorNow()
    ui.now:SetText(string.format(L("Merchant's Favor : %s"), now and tostring(now) or "?"))
    local goal = WLWritsCharDB.favorGoal or 0
    if not ui.box:HasFocus() then ui.box:SetText(goal > 0 and tostring(goal) or "") end
    local rows = WP.FavorRows()
    local y, hi, ri = 0, 0, 0
    ui.heads.HideFrom(1); ui.rows.HideFrom(1)
    if not rows then
        ui.summary:SetText("")
        ui.missing:SetText(L("Ce planificateur a besoin de Naowh Forever.\nC'est lui qui connaît les lots de chaque caisse : active-le."))
        ui.missing:Show()
        ui.content:SetHeight(60)
        return
    end
    ui.missing:Hide()
    local missing = math.max(0, goal - (now or 0))
    local plan, total, got = WP.FavorPlan(missing, rows)
    local exact, short = #plan > 0, false
    for _, e in ipairs(plan) do exact = exact and e.exact; short = short or e.short end
    -- at the auction house, the plan's items get their real prices (once each per 10 min)
    if #plan > 0 and not exact and WP.AuctionHouseOpen() and WP.LadderFetch and not WP.LadderBusy()
        and not (WP.Scan and WP.Scan.Busy()) then
        local ids = {}
        for _, e in ipairs(plan) do
            ids[#ids + 1] = e.row.id
            for _, b in ipairs(e.row.bundles or {}) do ids[#ids + 1] = b[1] end
        end
        WP.LadderFetch(ids, function() if WP.RefreshSoon then WP.RefreshSoon(0.2) end end)
    end
    if goal <= 0 then
        ui.summary:SetText("")
    elseif missing <= 0 then
        ui.summary:SetText(L("Objectif atteint : tu as déjà assez de Favor."))
    else
        local crates = 0
        for _, e in ipairs(plan) do crates = crates + e.n end
        ui.summary:SetText(string.format(L("Il te manque %s Favor."), missing) .. "\n" ..
            string.format(L("%d caisses · %s · %s la Favor"), crates, (exact and "" or "~") .. S.Money(total), S.Money(got > 0 and math.floor(total / got) or 0))
            .. "\n" .. (exact and (short and L("Prix réels de l'HV, mais pas assez en vente pour tout.") or L("Prix réels de l'HV, offre par offre."))
                or L("~ prix estimé : ouvre l'HV pour le prix réel, offre par offre.")))
    end
    local function head(text)
        hi = hi + 1
        local h = ui.heads.Get(hi)
        h:ClearAllPoints(); h:SetPoint("TOPLEFT", 2, -y - 6); h:SetText(text)
        y = y + 28
    end
    local function row(e, cost, sub)
        ri = ri + 1
        local r = ui.rows.Get(ri)
        r.entry = e
        local rr = e.row
        r:ClearAllPoints(); r:SetPoint("TOPLEFT", e.mat and 22 or 0, -y); r:SetPoint("RIGHT", ui.content, "RIGHT", 0, 0)
        r.icon:SetTexture(S.ItemIcon(e.mat or rr.id))
        if e.mat then
            r.name:SetText(string.format("%d× %s", e.total, WP.ItemName(e.mat)))
            r.per:SetText("")
        else
            r.name:SetText((e.n and (e.n .. "× ") or "") .. CrateName(rr.id))
            r.per:SetText(rr.per and (S.Money(math.floor(rr.per)) .. L(" la Favor")) or "")
        end
        r.sub:SetText(sub)
        r.cost:SetText(cost and ((cost == 0 and e.mat) and L("déjà là") or S.Money(cost)) or "?")
        y = y + ROW + (e.mat and 10 or 4)
    end
    if #plan > 0 then
        head(L("Le plan, de la moins chère"))
        for _, e in ipairs(plan) do
            local r = e.row
            local alts = {}
            for _, o in ipairs(r.bundles or {}) do alts[#alts + 1] = string.format("%d× %s", o[2], WP.ItemName(o[1])) end
            row(e, e.crateCost, string.format(L("%d Favor · un lot par caisse : %s"), e.n * r.favor, table.concat(alts, L(" ou "))))
            for _, o in ipairs(e.used) do
                local bank = WP.InBank and WP.InBank(o.item) or 0
                local sub = string.format(L("pour %d caisses"), o.crates)
                if o.owned > 0 then
                    sub = sub .. " · " .. string.format(L("tu en as %d"), o.owned)
                        .. (bank > 0 and (" " .. string.format(L("(dont %d en banque)"), bank)) or "")
                end
                row({ row = r, mat = o.item, total = o.taken, buy = o.buy }, o.cost, sub)
            end
        end
    end
    head(L("Toutes les caisses, par prix de la Favor"))
    for _, r in ipairs(rows) do
        local sub
        if not r.favor then sub = L("Favor inconnue : rends-en une pour l'apprendre")
        elseif not r.per then sub = L("prix inconnu : scanne l'HV")
        else
            sub = string.format("%d× %s · %s", r.bundle.qty, WP.ItemName(r.bundle.item),
                r.sure and string.format(L("%d Favor"), r.favor) or string.format(L("~%d Favor"), r.favor))
        end
        row({ row = r }, r.total, sub)
    end
    ui.content:SetHeight(math.max(10, y))
    local busy = WP.Scan and WP.Scan.Busy()
    ui.scan:SetEnabled(busy or WP.AuctionHouseOpen())
    -- what the button says: scanning, reading listings, or how fresh the prices are
    local done, tot = WP.Scan and WP.Scan.Progress()
    local newest
    for _, id in ipairs(WP.FavorScanIDs()) do
        local _, _, ago = WP.Scan.Get(id)
        if ago and (not newest or ago < newest) then newest = ago end
    end
    if done and tot and tot > 0 then
        ui.scan.label:SetText(string.format(L("Scan %d / %d · clic pour arrêter"), done, tot))
        ui.bar:Show()
        ui.barFill:SetWidth(math.max(1, (W - 2 * PAD) * done / tot))
    elseif WP.LadderBusy and WP.LadderBusy() then
        ui.scan.label:SetText(string.format(L("Prix réels : %d objets restants"), WP.LadderLeft()))
        ui.bar:Show()
        ui.barFill:SetWidth((W - 2 * PAD) * 0.5)
    elseif newest then
        local mins = math.floor(newest / 60)
        ui.scan.label:SetText(mins < 1 and L("Prix à jour · à l'instant") or string.format(L("Prix d'il y a %d min · rescanner"), mins))
        ui.bar:Hide()
    else
        ui.scan.label:SetText(WP.AuctionHouseOpen() and L("Scanner les prix (HV)") or L("Ouvre l'hôtel des ventes pour scanner"))
        ui.bar:Hide()
    end
    if not WP.AuctionHouseOpen() and not (done and tot) then
        ui.scan.label:SetText(newest and string.format(L("Prix d'il y a %d min · ouvre l'HV pour rescanner"), math.floor(newest / 60))
            or L("Ouvre l'hôtel des ventes pour scanner"))
    end
end
