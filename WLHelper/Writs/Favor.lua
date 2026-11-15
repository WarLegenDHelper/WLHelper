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
local F = S.F

ns.AddEnglish({
    ["Faveur du marchand"] = "Merchant's Favor",
    ["Tu as %d Faveur"] = "You have %d Favor",
    ["%d Faveur, 1 caisse"] = "%d Favor, 1 crate",
    ["%d Faveur, %d caisses"] = "%d Favor, %d crates",
    ["Une Faveur te coûte %s, au prix réel des offres de l'HV."] = "One Favor costs you %s, at the real AH listing prices.",
    ["Une Faveur te coûte %s, au prix réel des offres de l'HV, mais il n'y en a pas assez en vente pour tout."] =
        "One Favor costs you %s, at the real AH listing prices, but not enough is for sale for all of it.",
    ["Une Faveur te coûte environ %s : ouvre l'HV pour lire les offres une par une."] = "One Favor costs you about %s: open the AH to read the listings one by one.",
    ["Une caisse remplie de niveau %d rapporte %d Faveur : le plan en tient compte."] = "A level %d Supply Shipment gives %d Favor: the plan now uses it.",
    ["Les lots des caisses sont inconnus."] = "The crate bundles are unknown.",
    ["Les lots de chaque caisse viennent d'un addon de métiers : active-le dans la liste des addons, puis rouvre cette page."] =
        "Each crate's bundles come from a professions addon: turn it on in the addon list, then open this page again.",
    ["Dokimi : les Tarides, porte ouest de la Croisée (50, 29). Elle prend les caisses remplies."] =
        "Dokimi: The Barrens, west gate of the Crossroads (50, 29). She takes the filled crates.",
    ["Marcy Baker : les Carmines, Trois-Chemins (10, 71). Elle prend les caisses remplies."] =
        "Marcy Baker: Redridge Mountains, Three Corners (10, 71). She takes the filled crates.",
    ["Clic : guider vers %s"] = "Click: guide me to %s",
    ["Objectif"] = "Goal",
    ["Ex. 300"] = "E.g. 300",
    ["Écris ton objectif de Faveur : le plan des caisses les moins chères apparaîtra."] =
        "Type your Favor goal: the plan of the cheapest crates will show up.",
    ["Objectif atteint : tu as déjà assez de Faveur."] = "Goal reached: you already have enough Favor.",
    ["Il te manque %d Faveur : 1 caisse, %s."] = "You need %d more Favor: 1 crate, %s.",
    ["Il te manque %d Faveur : %d caisses, %s."] = "You need %d more Favor: %d crates, %s.",
    ["%s la Faveur"] = "%s per Favor",
    ["Prix scannés à l'instant"] = "Prices scanned just now",
    ["Prix scannés il y a %d min"] = "Prices scanned %d min ago",
    ["Prix scannés il y a %d h"] = "Prices scanned %d h ago",
    ["Le plan, la moins chère d'abord"] = "The plan, cheapest first",
    ["Toutes les caisses, par prix de la Faveur"] = "Every crate, by price per Favor",
    ["Lots des caisses inconnus"] = "Crate bundles unknown",
    ["Scanner l'HV"] = "Scan the AH",
    ["Arrêter le scan (%d sur %d)"] = "Stop the scan (%d of %d)",
    ["Lecture des offres (1 restante)"] = "Reading listings (1 left)",
    ["Lecture des offres (%d restantes)"] = "Reading listings (%d left)",
    ["Clic : arrêter le scan"] = "Click: stop the scan",
    ["Clic : scanner les prix des caisses et des lots"] = "Click: scan the prices of the crates and bundles",
    ["L'hôtel des ventes est fermé."] = "The auction house is closed.",
    ["Guider vers %s"] = "Guide me to %s",
    ["%d Faveur"] = "%d Favor",
    ["~%d Faveur"] = "~%d Favor",
    ["%d Faveur par caisse"] = "%d Favor per crate",
    ["~%d Faveur par caisse, à confirmer"] = "~%d Favor per crate, to confirm",
    ["Faveur inconnue : rends une caisse pour l'apprendre."] = "Favor unknown: turn in a crate to learn it.",
    ["Prix inconnu : scanne l'HV."] = "Price unknown: scan the AH.",
    ["Clic : l'acheter à l'HV"] = "Click: buy it at the AH",
    ["Clic : acheter les caisses à l'HV"] = "Click: buy the crates at the AH",
    ["Pour 1 caisse"] = "For 1 crate",
    ["Pour %d caisses"] = "For %d crates",
    ["tu en as %d"] = "you have %d",
    ["(dont %d en banque)"] = "(%d in the bank)",
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
                    -- no listing read (or none for sale): the scan price, short when nobody sells it
                    if unit then return unit * buy, false, all ~= false end
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
    if not old then WP.Print(string.format(L("Une caisse remplie de niveau %d rapporte %d Faveur : le plan en tient compte."), removedLevel, gain)) end
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

-- ---------------------------------------------------------------- the page
-- In the Comptoir window (Writs/UI.lua gives the page, its scroll area and page:Fit): the Favor you
-- have and your goal, one summary, then the plan and every crate as list rows, and two actions.
local INSET, LIST_W = 16, 420 - 32

local function num(v) return type(v) == "number" and not (root.IsSecret and root.IsSecret(v)) and v or nil end
local function Height(fs, minH)
    local ok, h = pcall(fs.GetStringHeight, fs)
    return math.max(ok and num(h) or 0, minH or 0)
end

-- "Waylaid Crate: Journeyman Ingots" -> "Journeyman Ingots" (the section header already says crates)
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
    local r = S.ListRow(parent, { density = "dense", onClick = function(self)
        local e = self.entry
        if not e or not WP.Scan then return end
        if e.mat then WP.Scan.OpenToBuy(e.mat, math.max(1, e.buy or 1))
        else WP.Scan.OpenToBuy(e.row.id, math.max(1, e.crates or 1)) end
    end })
    r.valueW = 110
    r.tip = function(self)
        local e = self.entry
        if not e then return nil end
        local row = e.row
        local lines = { WP.ItemName(e.mat or row.id) }
        if not e.mat then
            lines[#lines + 1] = row.favor and (row.sure and string.format(L("%d Faveur par caisse"), row.favor) or string.format(L("~%d Faveur par caisse, à confirmer"), row.favor))
                or L("Faveur inconnue : rends une caisse pour l'apprendre.")
            for _, b in ipairs(row.bundles or {}) do
                local p = WP.Price(b[1])
                local best = row.bundle and row.bundle.item == b[1]
                local c = best and C.fg or C.muted
                lines[#lines + 1] = { b[2] .. " x " .. WP.ItemName(b[1]) .. "  " .. (p and S.Money(p * b[2]) or "?"), c[1], c[2], c[3] }
            end
        end
        lines[#lines + 1] = e.mat and L("Clic : l'acheter à l'HV") or L("Clic : acheter les caisses à l'HV")
        return lines
    end
    return r
end

function WP.BuildFavor(p)
    ui.page = p
    ui.now = S.Text(p, F.heading, C.fg)
    ui.now:SetPoint("TOPLEFT", INSET, -18)
    S.ClampLabel(ui.now, nil, p)
    -- the goal: a short number field at the right, its label left of it
    ui.box = S.Input(p, 84, { placeholder = L("Ex. 300") })
    ui.box:SetPoint("TOPRIGHT", -INSET, -12)
    if ui.box.SetNumeric then ui.box:SetNumeric(true) end
    if ui.box.SetMaxLetters then ui.box:SetMaxLetters(6) end
    ui.box:SetJustifyH("RIGHT")
    ui.box:HookScript("OnTextChanged", function(self, user)
        if not user then return end
        WLWritsCharDB.favorGoal = tonumber(self:GetText() or "") or 0
        if WP.RefreshSoon then WP.RefreshSoon(0.3) end
    end)
    local goalLabel = S.Text(p, F.label, C.muted)
    goalLabel:SetWordWrap(false)
    goalLabel:SetPoint("RIGHT", ui.box, "LEFT", -8, 0)
    goalLabel:SetText(L("Objectif"))
    ui.goalLabel = goalLabel
    ui.summary = S.Text(p, F.body, C.text)
    ui.summary:SetJustifyH("LEFT"); ui.summary:SetJustifyV("TOP")
    ui.detail = S.Text(p, F.meta, C.muted)
    ui.detail:SetJustifyH("LEFT"); ui.detail:SetJustifyV("TOP")

    local child = p.sa.child
    ui.heads = Pool(child, function(parent) return S.SectionHeader(parent, "") end)
    ui.rows = Pool(child, MakeRow)
    ui.empty = S.EmptyState(child, "info", L("Lots des caisses inconnus"),
        L("Les lots de chaque caisse viennent d'un addon de métiers : active-le dans la liste des addons, puis rouvre cette page."))
    ui.empty:Hide()

    ui.scan = S.Button(p, L("Scanner l'HV"), 0, 32, "secondary", function()
        if WP.Scan.Busy() then WP.Scan.Stop() else WP.Scan.Start(WP.FavorScanIDs()) end
    end, function()
        if WP.Scan.Busy() then return { ui.scan:GetText(), L("Clic : arrêter le scan") } end
        if ui.scan:IsEnabled() == false then return nil end
        return { L("Scanner l'HV"), L("Clic : scanner les prix des caisses et des lots") }
    end)
    ui.scan:SetIcon("refresh")
    ui.scan:SetDisabledReason(L("L'hôtel des ventes est fermé."))
    ui.scan:SetPoint("BOTTOMLEFT", INSET, 12)
    -- the Inventory Intake NPC who takes the filled crates (Supply Shipments)
    local horde = UnitFactionGroup("player") ~= "Alliance"
    local npc = horde and "Dokimi" or "Marcy Baker"
    ui.go = S.Button(p, string.format(L("Guider vers %s"), npc), 0, 32, "secondary", function()
        if WP.GPS and WP.GPS.GoPoint then
            if horde then WP.GPS.GoPoint(1413, 50.13, 29.37, "Dokimi", "writs")
            else WP.GPS.GoPoint(1433, 9.71, 70.86, "Marcy Baker", "writs") end
        end
    end, function() return { string.format(L("Guider vers %s"), npc), horde
        and L("Dokimi : les Tarides, porte ouest de la Croisée (50, 29). Elle prend les caisses remplies.")
        or L("Marcy Baker : les Carmines, Trois-Chemins (10, 71). Elle prend les caisses remplies."),
        string.format(L("Clic : guider vers %s"), npc) } end)
    ui.go:SetIcon("flag")
    ui.go:SetPoint("BOTTOMRIGHT", -INSET, 12)
end

function WP.RenderFavor()
    if not ui.page then return end
    local p = ui.page
    local now = WP.FavorNow()
    ui.now:SetText(string.format(L("Tu as %d Faveur"), now or 0))
    ui.now:SetWidth(math.max(60, LIST_W - 84 - 8 - 60 - 12))
    local goal = WLWritsCharDB.favorGoal or 0
    if not ui.box:HasFocus() then ui.box:SetText(goal > 0 and tostring(goal) or "") end
    local rows = WP.FavorRows()
    local y = 12 + 28
    local ly, hi, ri = 0, 0, 0
    ui.heads.HideFrom(1); ui.rows.HideFrom(1)

    local busy = WP.Scan and WP.Scan.Busy()
    local done, tot = WP.Scan and WP.Scan.Progress()
    if done and tot and tot > 0 then
        ui.scan:SetText(string.format(L("Arrêter le scan (%d sur %d)"), done, tot)); ui.scan:SetIcon("close")
    elseif WP.LadderBusy and WP.LadderBusy() then
        local left = WP.LadderLeft()
        ui.scan:SetText(left == 1 and L("Lecture des offres (1 restante)") or string.format(L("Lecture des offres (%d restantes)"), left)); ui.scan:SetIcon("clock")
    else
        ui.scan:SetText(L("Scanner l'HV")); ui.scan:SetIcon("refresh")
    end
    ui.scan:SetDisabledReason(L("L'hôtel des ventes est fermé."))
    ui.scan:SetEnabled((busy or WP.AuctionHouseOpen()) and true or false)
    -- the two bottom buttons grow with their labels: when they no longer fit side by side, the
    -- guide button goes under the scan button
    local bottomH = 32
    ui.scan:ClearAllPoints(); ui.go:ClearAllPoints()
    if (num(ui.scan:GetWidth()) or 0) + 8 + (num(ui.go:GetWidth()) or 0) > LIST_W then
        ui.go:SetPoint("BOTTOMLEFT", INSET, 12)
        ui.scan:SetPoint("BOTTOMLEFT", INSET, 12 + 32 + 8)
        bottomH = 72
    else
        ui.scan:SetPoint("BOTTOMLEFT", INSET, 12)
        ui.go:SetPoint("BOTTOMRIGHT", -INSET, 12)
    end

    if not rows then
        -- without the crates' bundles there is nothing to scan for this page
        if not busy then
            ui.scan:SetDisabledReason(L("Les lots des caisses sont inconnus."))
            ui.scan:Disable()
        end
        ui.summary:Hide(); ui.detail:Hide()
        ui.empty:Show()
        ui.empty:SetWrapWidth(LIST_W)
        ui.empty:ClearAllPoints(); ui.empty:SetPoint("TOP", p.sa.child, "TOP", 0, -12)
        p:Fit(28, 12 + ui.empty:Fit() + 12, bottomH)
        return
    end
    ui.empty:Hide()
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

    -- one sentence for the goal, one muted line for the prices
    local sentence, detail
    if goal <= 0 then
        sentence = L("Écris ton objectif de Faveur : le plan des caisses les moins chères apparaîtra.")
    elseif missing <= 0 then
        sentence = L("Objectif atteint : tu as déjà assez de Faveur.")
    else
        local crates = 0
        for _, e in ipairs(plan) do crates = crates + e.n end
        local cost = (exact and "" or "~") .. S.Money(total)
        sentence = (crates == 1 and string.format(L("Il te manque %d Faveur : 1 caisse, %s."), missing, cost)
            or string.format(L("Il te manque %d Faveur : %d caisses, %s."), missing, crates, cost))
        local per = S.Money(got > 0 and math.floor(total / got) or 0)
        if not exact then
            detail = string.format(L("Une Faveur te coûte environ %s : ouvre l'HV pour lire les offres une par une."), per)
        elseif short then
            detail = string.format(L("Une Faveur te coûte %s, au prix réel des offres de l'HV, mais il n'y en a pas assez en vente pour tout."), per)
        else
            detail = string.format(L("Une Faveur te coûte %s, au prix réel des offres de l'HV."), per)
        end
    end
    local newest
    for _, id in ipairs(WP.FavorScanIDs()) do
        local _, _, ago = WP.Scan.Get(id)
        if ago and (not newest or ago < newest) then newest = ago end
    end
    if newest then
        local m = math.floor(newest / 60)
        local age = m < 1 and L("Prix scannés à l'instant") or (m < 60 and string.format(L("Prix scannés il y a %d min"), m)
            or string.format(L("Prix scannés il y a %d h"), math.floor(m / 60)))
        detail = detail and (detail .. " " .. age .. ".") or (age .. ".")
    end
    y = y + 12
    ui.summary:Show()
    ui.summary:SetText(sentence)
    ui.summary:ClearAllPoints(); ui.summary:SetPoint("TOPLEFT", INSET, -y)
    y = y + math.max(S.FitText(ui.summary, 2, LIST_W, p), F.body + 2)
    ui.detail:SetShown(detail ~= nil)
    if detail then
        y = y + 4
        ui.detail:SetText(detail)
        ui.detail:ClearAllPoints(); ui.detail:SetPoint("TOPLEFT", INSET, -y)
        y = y + math.max(S.FitText(ui.detail, 3, LIST_W, p), F.meta + 2)
    end
    local topH = y - 12

    local function head(text, count)
        hi = hi + 1
        local h = ui.heads.Get(hi)
        if ly > 0 then ly = ly + 8 end
        h:ClearAllPoints(); h:SetPoint("TOPLEFT", 0, -ly); h:SetPoint("TOPRIGHT", 0, -ly)
        h:Set(text, count)
        ly = ly + 32 + 4
    end
    local function row(e, cost, sub)
        ri = ri + 1
        local r = ui.rows.Get(ri)
        r.entry = e
        local rr = e.row
        local x = e.mat and 24 or 0
        r:ClearAllPoints(); r:SetPoint("TOPLEFT", x, -ly); r:SetPoint("TOPRIGHT", 0, -ly)
        local name, value
        if e.mat then
            name = string.format("%d x %s", e.total, WP.ItemName(e.mat))
        else
            name = (e.n and (e.n .. " x ") or "") .. CrateName(rr.id)
            if rr.per then sub = sub .. " · " .. string.format(L("%s la Faveur"), S.Money(math.floor(rr.per))) end
        end
        value = cost and ((cost == 0) and L("Dans le sac") or S.Money(cost)) or "?"
        r:Set({ icon = S.ItemIcon(e.mat or rr.id), name = name, detail = sub, value = value })
        ly = ly + r:Fit(LIST_W - x) + 2
    end
    if #plan > 0 then
        head(L("Le plan, la moins chère d'abord"), #plan)
        for _, e in ipairs(plan) do
            local r = e.row
            -- every bundle the crate accepts is in the row's tooltip; the rows under it show the ones used
            row(e, e.crateCost, e.n == 1 and string.format(L("%d Faveur, 1 caisse"), r.favor)
                or string.format(L("%d Faveur, %d caisses"), e.n * r.favor, e.n))
            for _, o in ipairs(e.used) do
                local bank = WP.InBank and WP.InBank(o.item) or 0
                local sub = o.crates == 1 and L("Pour 1 caisse") or string.format(L("Pour %d caisses"), o.crates)
                if o.owned > 0 then
                    sub = sub .. " · " .. string.format(L("tu en as %d"), o.owned)
                        .. (bank > 0 and (" " .. string.format(L("(dont %d en banque)"), bank)) or "")
                end
                row({ row = r, mat = o.item, total = o.taken, buy = o.buy }, o.cost, sub)
            end
        end
    end
    head(L("Toutes les caisses, par prix de la Faveur"), #rows)
    for _, r in ipairs(rows) do
        local sub
        if not r.favor then sub = L("Faveur inconnue : rends une caisse pour l'apprendre.")
        elseif not r.per then sub = L("Prix inconnu : scanne l'HV.")
        else
            sub = string.format("%d x %s · %s", r.bundle.qty, WP.ItemName(r.bundle.item),
                r.sure and string.format(L("%d Faveur"), r.favor) or string.format(L("~%d Faveur"), r.favor))
        end
        row({ row = r }, r.total, sub)
    end
    if ly > 0 then ly = ly - 2 end
    p:Fit(topH, ly, bottomH)
end
