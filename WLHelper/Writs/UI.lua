-- Writs/UI.lua: the Comptoir window (400×600) with three tabs:
--   Aujourd'hui    reputation, then the writs to hand in now grouped by zone, one primary action
--                  (the GPS tour);
--   Achats         what to buy for today's plan, grouped by turn-in place, a click opens the
--                  auction house's buy page;
--   Tous les writs every writ, cheapest first, then those for later and those done today.
-- Built from Style.lua's widgets; frames are pooled and filled again on each refresh.
local ADDON, root = ...
root.Writs = root.Writs or {}
local ns = root.Writs
local WP = ns.WP
local L = ns.L
local S = ns.S
local C = S.C

ns.AddEnglish({
    ["nouveaux writs dans %d min"] = "new writs in %d min",
    -- zones left out (Shopping tab)
    ["Exclure"] = "Leave out",
    ["%d pa"] = "%ds",
    ["%d po"] = "%dg",
    ["Zone"] = "Zone",
    ["Toutes les zones"] = "All zones",
    ["Clic : déplier la zone"] = "Click: unfold the zone",
    ["Clic : replier la zone"] = "Click: fold the zone",
    ["absent de l'HV"] = "not on the AH",
    ["(objet seul)"] = "(item only)",
    ["Clic : acheter l'enveloppe et l'objet · Maj-clic : Auctionator"] = "Click: buy the envelope and the item · Shift-click: Auctionator",
    ["Remettre"] = "Put back",
    ["Laisser cette zone de côté : le plan prend d'autres writs, ailleurs."] = "Leave this zone out: the plan takes other writs elsewhere.",
    ["Remettre cette zone dans le plan."] = "Put this zone back in the plan.",
    ["Zones laissées de côté"] = "Zones left out",
    ["Zone exclue : %s"] = "Zone left out: %s",
    ["Zone laissée de côté : remets-la dans l'onglet Achats."] = "Zone left out: put it back from the Shopping tab.",
    -- buying the whole list in a row
    ["Rescanner les prix de la liste"] = "Rescan the list's prices",
    ["Ouvre l'hôtel des ventes pour acheter"] = "Open the auction house to buy",
    ["Tout acheter à la suite (%d)"] = "Buy everything in a row (%d)",
    ["Achat %d sur %d · clic pour arrêter"] = "Purchase %d of %d · click to stop",
    ["%d objets absents de l'HV : rescanne plus tard ou exclus leur zone."] = "%d items not for sale: rescan later or leave their zone out.",
    ["Pour %d writs, qui rapportent %d points de réputation."] = "For %d writs, worth %d reputation.",
    ["Clic : acheter seulement celui-ci (enveloppe + objet) · Maj-clic : Auctionator"] = "Click: buy only this one (envelope + item) · Shift-click: Auctionator",
    -- Today tab: the next useful thing
    ["Lancer la tournée GPS (%d à rendre)"] = "Start the GPS tour (%d to hand in)",
    ["Acheter %d writs"] = "Buy %d writs",
    ["Acheter les objets manquants (%d)"] = "Buy the missing items (%d)",
    ["Rien à faire aujourd'hui"] = "Nothing to do today",
    ["manque · %s"] = "missing · %s",
    ["Objet manquant : achète-le avant d'y aller."] = "Item missing: buy it before you go.",
    ["Clic : acheter l'objet"] = "Click: buy the item",
    ["%d writs dépassent ton prix max : monte-le dans l'onglet Achats."] = "%d writs are above your max price: raise it in the Shopping tab.",
    ["Plus tard : %d writs dans des zones trop hautes pour ton niveau"] = "Later: %d writs in zones above your level",
    -- wording
    ["Réglages des Writs"] = "Writs settings",
    ["Objectif atteint. Pour continuer, choisis un rang plus haut dans les réglages (la roue en haut)."] = "Goal reached. To go on, pick a higher standing in the settings (the gear at the top).",
    ["%s dans %s points"] = "%s in %s points",
    ["%d points de réputation · %s %.0f, %.0f"] = "%d reputation · %s %.0f, %.0f",
    ["%d writs · %s · %d points de réputation"] = "%d writs · %s · %d reputation",
    ["pts"] = "pts",
    ["Réputation introuvable : ouvre ta fenêtre de personnage, onglet Réputation, une fois."] = "Reputation not found: open your character window, Reputation tab, once.",
    ["Enveloppe %s · objet %s · bourse rendue -%s"] = "Envelope %s · item %s · pouch refund -%s",
    ["%s une fois les bourses ouvertes · l'onglet Achats suit tes coches"] = "%s once the pouches are opened · the Shopping tab follows your ticks",
    ["Rien à cocher si tu veux : sans coche, WL Helper choisit les moins chers pour ton objectif."] = "Ticking is optional: with none ticked, WL Helper picks the cheapest for your goal.",
})

local W, H, PAD = 400, 600, 14
local frame, tabs, pages = nil, nil, {}
local data, plan, shop, shopTotal = {}, {}, {}, 0
local need, pending, readyRep = nil, 0, 0

-- ---------------------------------------------------------------- shared bits

-- Items the player can craft (Mastercraft's saved recipes), cached until the next refresh.
local craftable
local function Craftable(itemID)
    if craftable == nil then
        craftable = {}
        local db = rawget(_G, "MastercraftDB")
        local mine = type(db) == "table" and type(db.recipes) == "table" and db.recipes[UnitGUID("player")]
        if type(mine) == "table" then
            for _, prof in pairs(mine) do
                local list = type(prof) == "table" and prof.list
                if type(list) == "table" then
                    for _, rec in ipairs(list) do
                        if type(rec) == "table" and rec.learned and rec.output then craftable[rec.output] = true end
                    end
                end
            end
        end
    end
    return craftable[itemID]
end

local function SetColor(fs, c, a) fs:SetTextColor(c[1], c[2], c[3], a or 1) end

-- A scrollable content area: content:SetHeight() decides how far it scrolls.
local function Scroller(parent)
    local sf = CreateFrame("ScrollFrame", nil, parent)
    local content = CreateFrame("Frame", nil, sf)
    content:SetSize(W - 2 * PAD, 10)
    sf:SetScrollChild(content)
    sf:EnableMouseWheel(true)
    sf:SetScript("OnMouseWheel", function(self, delta)
        local max = math.max(0, content:GetHeight() - self:GetHeight())
        self:SetVerticalScroll(math.max(0, math.min(max, self:GetVerticalScroll() - delta * 40)))
    end)
    sf.content = content
    return sf
end

-- Pools of frames: Get(i) returns the i-th, creating it with make() when needed; HideFrom(i) hides the rest.
local function Pool(make)
    local p = { items = {} }
    function p.Get(i)
        local f = p.items[i]
        if not f then f = make(); p.items[i] = f end
        f:Show()
        return f
    end
    function p.HideFrom(i) for j = i, #p.items do p.items[j]:Hide() end end
    return p
end

local ICON_CHECK = "Interface\\RaidFrame\\ReadyCheck-Ready"   -- fallback of the modern tick
local ATLAS_CHECK = { "common-icon-checkmark" }
local ATLAS_WARN = { "services-icon-warning" }
local REFRESH = { atlases = { "uitools-icon-refresh", "UI-RefreshButton" }, path = "Interface\\Buttons\\UI-RefreshButton" }
local ICON_MAIL = "Interface\\Icons\\INV_Letter_15"
local ICON_WARN = "Interface\\DialogFrame\\UI-Dialog-Icon-AlertNew"

-- ---------------------------------------------------------------- Aujourd'hui

local today = {}

-- "Open the envelope" buttons. Using an item is protected, so they are secure buttons; to keep the
-- Comptoir window an ordinary frame (it may open, close and redraw in combat), they are parented and
-- anchored to UIParent and laid over their row out of combat. Combat hides them; the row then reads
-- "Ouvrir l'enveloppe" as plain text until combat ends.
local envelopes, envRows = {}, {}
local function EnvelopeButton(i)
    local b = envelopes[i]
    if b then return b end
    b = CreateFrame("Button", "WLHelperEnvelope" .. i, UIParent, "SecureActionButtonTemplate")
    b:SetSize(132, 24)
    b:RegisterForClicks("AnyUp", "AnyDown")   -- press or release, as the game is set
    b:SetAttribute("type", "item")
    S.Solid(b, "BACKGROUND", C.card):SetAllPoints()
    S.Border(b, C.warn, 0.45)
    b.label = S.Text(b, 12, C.warn)
    b.label:SetPoint("CENTER")
    b.label:SetText(L("Ouvrir l'enveloppe"))
    b:Hide()
    envelopes[i] = b
    return b
end

local function HideEnvelopes()
    if InCombatLockdown() then return end
    for _, b in ipairs(envelopes) do b:Hide() end
end

-- Lays a button over each envelope row that is visible in the scrolled list. Out of combat only.
local function PlaceEnvelopes()
    if InCombatLockdown() then return end
    local n = 0
    local sc = today.scroll
    local top, bottom = sc and sc:GetTop(), sc and sc:GetBottom()
    if frame and frame:IsShown() and today.page and today.page:IsShown() and top and bottom then
        local ratio = sc:GetEffectiveScale() / UIParent:GetEffectiveScale()
        for _, row in ipairs(envRows) do
            local rt, rb, rr = row:GetTop(), row:GetBottom(), row:GetRight()
            if row:IsVisible() and row.envItem and rt and rb and rr and rb >= bottom - 1 and rt <= top + 1 then
                n = n + 1
                local b = EnvelopeButton(n)
                b:SetScale(ratio)
                b:SetFrameStrata(frame:GetFrameStrata())
                b:SetFrameLevel(frame:GetFrameLevel() + 50)
                b:SetAttribute("item", "item:" .. row.envItem)
                b:ClearAllPoints()
                b:SetPoint("RIGHT", UIParent, "BOTTOMLEFT", rr - 6, (rt + rb) / 2)
                b:Show()
            end
        end
    end
    for i = n + 1, #envelopes do envelopes[i]:Hide() end
end

local function MakeZoneCard(parent)
    local c = CreateFrame("Frame", nil, parent)
    c:SetWidth(W - 2 * PAD)
    S.Solid(c, "BACKGROUND", C.card):SetAllPoints()
    S.Border(c, C.border)
    c.name = S.Text(c, 15, C.text, true)
    c.name:SetPoint("TOPLEFT", 12, -12)
    c.level = CreateFrame("Frame", nil, c)
    c.level:SetSize(40, 16)
    c.level:SetPoint("LEFT", c.name, "RIGHT", 8, 0)
    c.levelBorder = S.Border(c.level, C.dim, 0.5)
    c.levelText = S.Text(c.level, 11, C.dim)
    c.levelText:SetPoint("CENTER")
    c.go = S.Button(c, L("Y aller"), 70, 28, "secondary", function() if c.first then WP.TravelTo(c.first) end end)
    c.go:SetPoint("TOPRIGHT", -6, -6)
    c.eta = S.Text(c, 13, C.dim)
    c.eta:SetPoint("RIGHT", c.go, "LEFT", -8, 0)
    c.rows = Pool(function()
        local r = CreateFrame("Button", nil, c)
        r:SetSize(W - 2 * PAD - 2, 34)
        local line = S.Solid(r, "BORDER", C.divider)
        line:SetPoint("TOPLEFT"); line:SetPoint("TOPRIGHT"); line:SetHeight(1)
        S.Solid(r, "HIGHLIGHT", { 1, 1, 1 }, 0.05):SetAllPoints()   -- above the text: must stay see-through
        r.status = r:CreateTexture(nil, "ARTWORK")
        r.status:SetSize(14, 14); r.status:SetPoint("LEFT", 12, 0)
        r.icon = r:CreateTexture(nil, "ARTWORK")
        r.icon:SetSize(18, 18); r.icon:SetPoint("LEFT", r.status, "RIGHT", 8, 0)
        r.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        r.name = S.Text(r, 14, C.text)
        r.name:SetPoint("LEFT", r.icon, "RIGHT", 8, 0)
        r.name:SetWidth(164)   -- set again per row: up to the envelope button or the right text
        r.right = S.Text(r, 13, C.dim)
        r.right:SetPoint("RIGHT", -10, 0)
        r.right:SetJustifyH("RIGHT")
        envRows[#envRows + 1] = r
        r:SetScript("OnClick", function(self)
            -- a writ still waiting for its item: buy the item (or show the Shopping tab away from the AH)
            if self.r and self.r.state == "log" and self.writ then
                if WP.AuctionHouseOpen() then
                    WP.Scan.OpenToBuy(self.writ.item, math.max(1, (self.writ.count or 1) - (self.r.haveItems or 0)))
                else
                    WP.ShowTab("shop")
                end
                return
            end
            if self.writ then WP.TravelTo(self.writ) end
        end)
        r:SetScript("OnEnter", function(self) if self.tip then S.Tip(self, self.tip) end end)
        r:SetScript("OnLeave", S.HideTip)
        return r
    end)
    return c
end

local function BuildToday(p)
    today.hero = S.Text(p, 22, C.text, true)
    today.hero:SetPoint("TOPLEFT", PAD, -14)
    today.standing = S.Text(p, 13, C.dim)
    today.standing:SetPoint("TOPRIGHT", -PAD, -20)
    today.standing:SetJustifyH("RIGHT")
    local bar = CreateFrame("Frame", nil, p)
    bar:SetPoint("TOPLEFT", PAD, -46); bar:SetPoint("TOPRIGHT", -PAD, -46); bar:SetHeight(6)
    S.Solid(bar, "BACKGROUND", C.divider):SetAllPoints()
    today.barFill = S.Solid(bar, "ARTWORK", C.brand)
    today.barFill:SetPoint("TOPLEFT"); today.barFill:SetPoint("BOTTOMLEFT")
    today.barPending = S.Solid(bar, "ARTWORK", { 0.42, 0.114, 0.106 })
    today.barPending:SetPoint("TOPLEFT", today.barFill, "TOPRIGHT"); today.barPending:SetPoint("BOTTOMLEFT", today.barFill, "BOTTOMRIGHT")
    today.bar = bar
    today.message = S.Text(p, 13, C.dim)
    today.message:SetPoint("TOPLEFT", PAD, -60)
    today.message:SetPoint("TOPRIGHT", -PAD, -60)
    today.message:SetWordWrap(true)
    today.message:SetJustifyH("LEFT")

    today.label = S.Text(p, 13, C.dim)
    today.label:SetPoint("TOPLEFT", PAD, -94)
    today.label:SetText(L("À rendre maintenant"))
    today.reset = S.Text(p, 13, C.dim)
    today.reset:SetPoint("TOPRIGHT", -PAD, -94)
    today.reset:SetJustifyH("RIGHT")

    local sc = Scroller(p)
    sc:SetPoint("TOPLEFT", PAD, -116); sc:SetPoint("BOTTOMRIGHT", -PAD, 62)
    sc:HookScript("OnVerticalScroll", PlaceEnvelopes)
    today.scroll = sc
    today.page = p
    today.cards = Pool(function() return MakeZoneCard(sc.content) end)
    today.later = CreateFrame("Button", nil, sc.content)
    today.later:SetSize(W - 2 * PAD, 30)
    today.laterIcon = S.Glyph(today.later, "right", 10, C.dim)
    today.laterIcon:SetPoint("LEFT", 3, 0)
    today.laterText = S.Text(today.later, 13, C.dim)
    today.laterText:SetPoint("LEFT", today.laterIcon, "RIGHT", 6, 0)
    today.later:SetScript("OnClick", function() WP.ShowTab("all") end)
    today.empty = S.Text(sc.content, 14, C.dim)
    today.empty:SetPoint("TOPLEFT", 2, -8)
    today.empty:SetWidth(W - 2 * PAD - 4)
    today.empty:SetWordWrap(true)

    local foot = CreateFrame("Frame", nil, p)
    foot:SetPoint("BOTTOMLEFT"); foot:SetPoint("BOTTOMRIGHT"); foot:SetHeight(60)
    local line = S.Solid(foot, "BORDER", C.divider)
    line:SetPoint("TOPLEFT"); line:SetPoint("TOPRIGHT"); line:SetHeight(1)
    today.tour = S.Button(foot, L("Lancer la tournée GPS"), W - 2 * PAD - 44, 36, "primary", function()
        if today.tour.action == "gps" then WP.ToggleGPS() elseif today.tour.action == "shop" then WP.ShowTab("shop") end
    end)
    today.tour:SetPoint("LEFT", PAD, 0)
    today.scan = S.Button(foot, "", 36, 36, "secondary", function()
        if WP.Scan.Busy() then WP.Scan.Stop() else WP.Scan.Start(WP.ShoppingIDs()) end
    end, function()
        return WP.AuctionHouseOpen() and { L("Scanner les prix de la liste d'achat") } or { L("Ouvre l'hôtel des ventes pour scanner") }
    end)
    today.scan:SetPoint("LEFT", today.tour, "RIGHT", 8, 0)
    local ic = today.scan:CreateTexture(nil, "ARTWORK")
    ic:SetSize(16, 16); ic:SetPoint("CENTER"); S.SetIcon(ic, REFRESH.atlases, REFRESH.path)
    today.scanIcon = ic
end

-- Minutes the GPS needs to reach each zone's first writ, for the cards: one search for all of them.
local function MinutesTo(order)
    local out = {}
    local G = WP.GPS
    if not (G and G.CostsTo and G.Point) then return out end
    local dests, idx = {}, {}
    for i, z in ipairs(order) do
        local w = z.rows[1].w
        local p = G.Point(w.map, w.x, w.y, { kind = "dest" })
        if p then dests[#dests + 1] = p; idx[#dests] = i end
    end
    if #dests == 0 then return out end
    for j, t in pairs(G.CostsTo(dests)) do out[idx[j]] = math.max(1, math.floor(t / 60 + 0.5)) end
    return out
end

-- The big button does the next useful thing: stop the tour, start it when there is something to
-- hand in, else buy the plan, else buy the items still missing.
local function TourAction()
    if WLWritsCharDB.gps then return "gps", L("Arrêter la tournée GPS"), true end
    local ready, bagOwned, missing = 0, 0, 0
    for _, r in ipairs(data) do
        if r.w.map and not r.tooHigh then
            if r.state == "ready" then ready = ready + 1
            elseif r.state == "bag" and r.ownItem then bagOwned = bagOwned + 1
            elseif r.state == "log" or r.state == "bag" then missing = missing + 1 end
        end
    end
    if ready + bagOwned > 0 then return "gps", string.format(L("Lancer la tournée GPS (%d à rendre)"), ready + bagOwned), true end
    if #plan > 0 then return "shop", string.format(L("Acheter %d writs"), #plan), true end
    if missing > 0 then return "shop", string.format(L("Acheter les objets manquants (%d)"), missing), true end
    return nil, L("Rien à faire aujourd'hui"), false
end

local function PaintTour()
    local a, txt, on = TourAction()
    today.tour.action = a
    today.tour.label:SetText(txt)
    if on then today.tour:Enable() else today.tour:Disable() end
end

local function RenderToday()
    local name, reaction, inStanding, size, total = WP.Reputation()
    if not name then
        today.hero:SetText(L("Writs"))
        today.standing:SetText("")
        today.message:SetText(L("Réputation introuvable : ouvre ta fenêtre de personnage, onglet Réputation, une fois."))
        today.barFill:SetWidth(0.01); today.barPending:SetWidth(0.01)
    else
        local _, goal = WP.RepNeeded()
        local barW = today.bar:GetWidth() > 0 and today.bar:GetWidth() or (W - 2 * PAD)
        local frac = (size and size > 0) and (inStanding / size) or 0
        today.barFill:SetWidth(math.max(0.01, barW * frac))
        local pend = (size and size > 0) and math.min(1 - frac, pending / size) or 0
        today.barPending:SetWidth(math.max(0.01, barW * pend))
        today.standing:SetText(string.format("%s / %s", BreakUpLargeNumbers and BreakUpLargeNumbers(inStanding) or inStanding, BreakUpLargeNumbers and BreakUpLargeNumbers(size) or size))
        if not need or need <= 0 then
            today.hero:SetText(string.format(L("%s atteint"), WP.Reaction(goal or reaction)))
            today.message:SetText(L("Objectif atteint. Pour continuer, choisis un rang plus haut dans les réglages (la roue en haut)."))
        else
            today.hero:SetText(string.format(L("%s dans %s points"), WP.Reaction(goal),
                BreakUpLargeNumbers and BreakUpLargeNumbers(need) or tostring(need)))
            local ready = 0
            for _, r in ipairs(data) do if r.state == "ready" and r.w.map and not r.tooHigh then ready = ready + 1 end end
            if pending >= need then
                today.message:SetText(string.format(L("Rends tes %d writs et c'est bon."), ready))
            elseif #plan > 0 and ready > 0 then
                today.message:SetText(string.format(L("Rends les %d writs prêts, achète-en %d de plus."), ready, #plan))
            elseif #plan > 0 then
                today.message:SetText(string.format(L("Achète %d writs dans l'onglet Achats."), #plan))
            else
                -- nothing planned: say so when the price cap is what keeps writs out
                local capped, cap = 0, WLWritsDB.maxPer100 or 0
                if cap > 0 then
                    for _, r in ipairs(data) do
                        if r.show and r.state == "buy" and r.per100 and r.w.map and not r.tooHigh and not r.skipped
                            and r.per100 > cap then capped = capped + 1 end
                    end
                end
                if capped > 0 then
                    today.message:SetText(string.format(L("%d writs dépassent ton prix max : monte-le dans l'onglet Achats."), capped))
                else
                    today.message:SetText(L("Aucun writ abordable aujourd'hui : reviens demain, quand ils changent."))
                end
            end
        end
    end
    local secs = WP.SecondsToReset()
    if secs < 3600 then
        today.reset:SetText(string.format(L("nouveaux writs dans %d min"), math.max(1, math.floor(secs / 60))))
    else
        today.reset:SetText(string.format(L("nouveaux writs dans %d h"), math.floor(secs / 3600)))
    end

    -- Cards: writs you hold, by zone, closest first is not known cheaply: biggest first.
    local zones, order, later = {}, {}, 0
    for _, r in ipairs(data) do
        local held = r.state == "ready" or r.state == "bag" or r.state == "log"
        if held and r.w.map and not r.tooHigh then
            local z = zones[r.w.map]
            if not z then z = { map = r.w.map, name = r.zone, rows = {}, rep = 0 }; zones[r.w.map] = z; order[#order + 1] = z end
            z.rows[#z.rows + 1] = r
            z.rep = z.rep + r.w.rep
        elseif held then
            later = later + 1
        end
    end
    table.sort(order, function(a, b) if a.rep ~= b.rep then return a.rep > b.rep end return a.name < b.name end)
    local y = 0
    local minutes = MinutesTo(order)
    for i, z in ipairs(order) do
        local c = today.cards.Get(i)
        c:ClearAllPoints(); c:SetPoint("TOPLEFT", 0, -y)
        c.name:SetWidth(0)   -- back to the text's own width before measuring it
        c.name:SetText(z.name)
        local lo = WP.ZoneMin(z.map)
        if lo then
            c.levelText:SetText(lo .. "-" .. (lo + 10))
            local col = S.LevelColor(lo + 5)
            SetColor(c.levelText, col); c.levelBorder(col, 0.5)
            c.level:SetWidth(c.levelText:GetStringWidth() + 10); c.level:Show()
        else
            c.level:Hide()
        end
        c.first = z.rows[1].w
        local mins = minutes[i]
        c.eta:SetText(mins and string.format(L("~%d min"), mins) or "")
        -- a long zone name stops before the level badge and "~N min" (left of the 70 px button)
        local room = (W - 2 * PAD) - 12 - 84 - c.eta:GetStringWidth() - 8 - (c.level:IsShown() and (c.level:GetWidth() + 8) or 0)
        c.name:SetWidth(math.max(40, math.min(c.name:GetStringWidth() + 2, room)))
        local ry = 40
        for j, r in ipairs(z.rows) do
            local row = c.rows.Get(j)
            row:ClearAllPoints(); row:SetPoint("TOPLEFT", 1, -ry)
            local w = r.w
            row.writ = w
            row.r = r
            row.icon:SetTexture(S.ItemIcon(w.item))
            row.name:SetText(WP.ItemName(w.item, w.itemName) .. ((w.count or 1) > 1 and (" ×" .. w.count) or ""))
            SetColor(row.name, S.QualityColor(w.item))
            row.envItem = nil
            if r.state == "ready" then
                S.SetIcon(row.status, ATLAS_CHECK, ICON_CHECK); row.status:SetVertexColor(1, 1, 1)
                row.right:SetText(string.format("%.0f, %.0f", w.x, w.y)); SetColor(row.right, C.dim)
            elseif r.state == "bag" then
                S.SetIcon(row.status, nil, ICON_MAIL, { 0.08, 0.92, 0.08, 0.92 })
                -- the item is still missing: the envelope tinted amber
                if r.ownItem then row.status:SetVertexColor(1, 1, 1) else row.status:SetVertexColor(C.warn[1], C.warn[2], C.warn[3]) end
                row.envItem = w.writ   -- PlaceEnvelopes lays the secure button over this text
                row.right:SetText(L("Ouvrir l'enveloppe")); SetColor(row.right, C.warn)
            else
                S.SetIcon(row.status, ATLAS_WARN, ICON_WARN); row.status:SetVertexColor(1, 1, 1)
                local missingN = math.max(1, (w.count or 1) - (r.haveItems or 0))
                row.right:SetText(r.itemPrice and string.format(L("manque · %s"), S.Money(r.itemPrice * missingN)) or L("objet manquant"))
                SetColor(row.right, C.warn)
            end
            -- the name stops before the envelope button (132 px + gaps) or the right text
            local rowW = W - 2 * PAD - 2
            row.name:SetWidth(row.envItem and (rowW - 60 - 146) or math.max(60, rowW - 60 - 10 - row.right:GetStringWidth() - 8))
            row.tip = { WP.ItemName(w.writ, w.writName), string.format(L("%d points de réputation · %s %.0f, %.0f"), w.rep, z.name, w.x, w.y),
                w.npcName and string.format(L("À rendre à %s"), w.npcName) or L("lieu de remise sur la carte") }
            if r.state == "bag" and not r.ownItem then
                row.tip[#row.tip + 1] = { L("Objet manquant : achète-le avant d'y aller."), C.warn[1], C.warn[2], C.warn[3] }
            end
            row.tip[#row.tip + 1] = { r.state == "log" and L("Clic : acheter l'objet") or L("Clic : GPS jusqu'au PNJ"), 0.6, 0.6, 0.6 }
            ry = ry + 34
        end
        c.rows.HideFrom(#z.rows + 1)
        c:SetHeight(ry + 1)
        y = y + ry + 1 + 10
    end
    today.cards.HideFrom(#order + 1)
    today.empty:SetShown(#order == 0)
    if #order == 0 then
        today.empty:SetText(#plan > 0 and L("Aucun writ en main. Achète ceux de l'onglet Achats, puis ouvre les enveloppes.")
            or L("Tout est rendu pour aujourd'hui."))
        y = 40
    end
    today.later:ClearAllPoints(); today.later:SetPoint("TOPLEFT", 0, -y)
    today.later:SetShown(later > 0)
    today.laterText:SetText(string.format(L("Plus tard : %d writs dans des zones trop hautes pour ton niveau"), later))
    if later > 0 then y = y + 32 end
    today.scroll.content:SetHeight(math.max(y, 10))

    PaintTour()
    local done, tot = WP.Scan.Progress()
    if done then today.scan:Enable() elseif WP.AuctionHouseOpen() then today.scan:Enable() else today.scan:Disable() end
    today.scanIcon:SetDesaturated(not today.scan:IsEnabled())
end

-- ---------------------------------------------------------------- Achats

local buy = {}

local function BuildShop(p)
    buy.total = S.Text(p, 22, C.text, true)
    buy.total:SetPoint("TOPLEFT", PAD, -14)
    buy.sub = S.Text(p, 13, C.dim)
    buy.sub:SetPoint("TOPLEFT", PAD, -42)
    buy.sub:SetPoint("TOPRIGHT", -PAD, -42)
    buy.sub:SetWordWrap(true)
    -- the price cap: writs costing more than this per 100 reputation points are left out of the plan
    -- (net of the Coin Pouch they give back); the route then groups what is left by turn-in zone
    local capLabel = S.Text(p, 12, C.dim); capLabel:SetPoint("TOPLEFT", PAD, -78); capLabel:SetText(L("Prix max pour 100 points"))
    buy.cap = S.Segmented(p, { { 2000, string.format(L("%d pa"), 20) }, { 4000, string.format(L("%d pa"), 40) }, { 10000, string.format(L("%d po"), 1) }, { 0, L("sans") } },
        function() return WLWritsDB.maxPer100 or 4000 end,
        function(v) WLWritsDB.maxPer100 = v; WP.Refresh() end, 24)
    buy.cap:SetPoint("TOPRIGHT", -PAD, -72)
    -- zone filter: every zone, or a single one (a small list opens under the button)
    local zl = S.Text(p, 12, C.dim); zl:SetPoint("TOPLEFT", PAD, -112); zl:SetText(L("Zone"))
    buy.zoneBtn = S.Button(p, "", W - 2 * PAD - 60, 24, "secondary", function()
        if buy.zoneMenu:IsShown() then buy.zoneMenu:Hide() else buy.OpenZoneMenu() end
    end)
    buy.zoneBtn:SetPoint("TOPRIGHT", -PAD, -106)
    local menu = CreateFrame("Frame", nil, p)
    menu:SetFrameStrata("DIALOG"); menu:SetWidth(W - 2 * PAD - 60)
    menu:SetPoint("TOPRIGHT", buy.zoneBtn, "BOTTOMRIGHT", 0, -2)
    S.Solid(menu, "BACKGROUND", C.bg or C.card):SetAllPoints()
    S.Border(menu, C.border)
    menu:EnableMouse(true); menu:Hide()
    menu.items = {}
    buy.zoneMenu = menu
    function buy.OpenZoneMenu()
        local keys = { false }
        for _, k in ipairs(buy.zoneKeys or {}) do keys[#keys + 1] = k end
        for i, k in ipairs(keys) do
            local it = menu.items[i]
            if not it then
                it = CreateFrame("Button", nil, menu)
                it:SetHeight(22); it:SetPoint("LEFT", 1, 0); it:SetPoint("RIGHT", -1, 0)
                S.Solid(it, "HIGHLIGHT", { 1, 1, 1 }, 0.08):SetAllPoints()
                it.t = S.Text(it, 13, C.text); it.t:SetPoint("LEFT", 10, 0); it.t:SetPoint("RIGHT", -10, 0); it.t:SetJustifyH("LEFT"); it.t:SetWordWrap(false)
                it:SetScript("OnClick", function(self) WLWritsCharDB.shopZone = self.key or nil; menu:Hide(); WP.Refresh() end)
                menu.items[i] = it
            end
            it:ClearAllPoints(); it:SetPoint("TOPLEFT", 1, -(1 + (i - 1) * 22)); it:SetPoint("TOPRIGHT", -1, -(1 + (i - 1) * 22))
            it.key = k
            it.t:SetText(k and k or L("Toutes les zones"))
            if (k or nil) == WLWritsCharDB.shopZone then SetColor(it.t, C.brand) else SetColor(it.t, C.text) end
            it:Show()
        end
        for i = #keys + 1, #menu.items do menu.items[i]:Hide() end
        menu:SetHeight(#keys * 22 + 2)
        menu:Show()
    end
    p:HookScript("OnHide", function() menu:Hide() end)
    local sc = Scroller(p)
    sc:SetPoint("TOPLEFT", PAD, -140); sc:SetPoint("BOTTOMRIGHT", -PAD, 62)
    buy.scroll = sc
    -- zone heads: the zone's name, and on the right an explicit Exclure / Remettre button
    -- (one list with the settings and the right-click: WLWritsCharDB.skip.zones); a head with no
    -- map (the "left out" section title) has no button
    buy.heads = Pool(function()
        local b = CreateFrame("Button", nil, sc.content)
        b:SetSize(W - 2 * PAD - 2, 22)
        b.fold = S.Glyph(b, "right", 10, C.dim); b.fold:SetPoint("LEFT", 2, 0)
        b.t = S.Text(b, 13, C.dim); b.t:SetPoint("LEFT", 18, 0); b.t:SetPoint("RIGHT", -78, 0); b.t:SetJustifyH("LEFT"); b.t:SetWordWrap(false)
        function b:SetText(text) self.t:SetText(text) end
        b:SetScript("OnClick", function(self)
            if not self.foldKey then return end
            WLWritsCharDB.shopFold = WLWritsCharDB.shopFold or {}
            WLWritsCharDB.shopFold[self.foldKey] = not WLWritsCharDB.shopFold[self.foldKey] or nil
            WP.Refresh()
        end)
        b:SetScript("OnEnter", function(self)
            if self.foldKey then self.t:SetTextColor(1, 1, 1); S.Tip(self, { self.folded and L("Clic : déplier la zone") or L("Clic : replier la zone") }) end
        end)
        b:SetScript("OnLeave", function(self) self.t:SetTextColor(C.dim[1], C.dim[2], C.dim[3]); S.HideTip() end)
        b.btn = S.Button(b, L("Exclure"), 70, 18, "secondary", function()
            if b.map then WP.SetSkipped("zones", b.map, not b.excluded) end
        end, function()
            return { b.excluded and L("Remettre cette zone dans le plan.") or L("Laisser cette zone de côté : le plan prend d'autres writs, ailleurs.") }
        end)
        b.btn:SetPoint("RIGHT", 0, 0)
        return b
    end)
    buy.rows = Pool(function()
        local r = CreateFrame("Button", nil, sc.content)
        r:SetSize(W - 2 * PAD, 38)
        r:RegisterForClicks("LeftButtonUp")
        S.Solid(r, "BACKGROUND", C.card):SetAllPoints()
        S.Border(r, C.border)
        S.Solid(r, "HIGHLIGHT", { 1, 1, 1 }, 0.05):SetAllPoints()   -- above the text: must stay see-through
        r.icon = r:CreateTexture(nil, "ARTWORK")
        r.icon:SetSize(18, 18); r.icon:SetPoint("LEFT", 12, 0); r.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        r.name = S.Text(r, 14, C.text)
        r.price = S.Text(r, 13, C.text)
        r.price:SetPoint("RIGHT", -12, 0)
        r.price:SetWidth(120)   -- stable, so the name truncates at the same place on every row
        r.price:SetJustifyH("RIGHT")
        r.name:SetPoint("LEFT", r.icon, "RIGHT", 10, 0)
        r.name:SetPoint("RIGHT", r.price, "LEFT", -8, 0)
        r:SetScript("OnClick", function(self)
            local e = self.entry
            if not e then return end
            -- the envelope and its item go together: one click opens the first, the other follows
            local pair, entries = {}, {}
            for _, x in ipairs(shop) do
                if x.group == e.group and not x.done then
                    pair[#pair + 1] = { id = x.id, qty = math.max(1, x.need - x.have), order = x.order or 0 }
                    entries[#entries + 1] = x
                end
            end
            if IsShiftKeyDown() then WP.SearchList(#entries > 0 and entries or { e }); return end
            table.sort(pair, function(a, b) return a.order < b.order end)
            if #pair == 0 then pair = { { id = e.id, qty = math.max(1, e.need - e.have) } } end
            WP.Scan.BuyQueue(pair)
        end)
        r:SetScript("OnEnter", function(self)
            local e = self.entry
            if not e then return end
            local lines = { self.title or e.name }
            for _, x in ipairs(self.entries or { e }) do
                local left = math.max(0, x.need - x.have)
                local price = x.done and L("dans tes sacs") or (x.src == "Absent" and L("absent de l'HV"))
                    or (x.price and (S.Money(x.price * left) .. (left > 1 and (" (" .. left .. " × " .. S.Money(x.price) .. ")") or "")) or "?")
                lines[#lines + 1] = { (x.isWrit and L("Enveloppe") or x.name) .. " : " .. price, 1, 1, 1 }
                local sub = string.format(L("Dans tes sacs : %d / %d"), x.have, x.need)
                if x.listed then sub = sub .. " · " .. string.format(L("En vente (dernier scan) : %d"), x.listed) end
                lines[#lines + 1] = { "   " .. sub, 0.7, 0.7, 0.7 }
            end
            lines[#lines + 1] = { L("Clic : acheter l'enveloppe et l'objet · Maj-clic : Auctionator"), 0.6, 0.6, 0.6 }
            S.Tip(self, lines)
        end)
        r:SetScript("OnLeave", S.HideTip)
        return r
    end)
    buy.absent = S.Text(sc.content, 13, C.warn)
    buy.absent:SetPoint("TOPLEFT", 2, 0)
    buy.absent:SetWidth(W - 2 * PAD - 4)
    buy.absent:SetWordWrap(true)
    buy.absent:SetJustifyH("LEFT")
    buy.empty = S.Text(sc.content, 14, C.dim)
    buy.empty:SetPoint("TOPLEFT", 2, -8)
    buy.empty:SetWidth(W - 2 * PAD - 4)
    buy.empty:SetWordWrap(true)

    local foot = CreateFrame("Frame", nil, p)
    foot:SetPoint("BOTTOMLEFT"); foot:SetPoint("BOTTOMRIGHT"); foot:SetHeight(60)
    local line = S.Solid(foot, "BORDER", C.divider)
    line:SetPoint("TOPLEFT"); line:SetPoint("TOPRIGHT"); line:SetHeight(1)
    -- one primary button opens every buy page in a row; the player still clicks the game's own Buy
    -- button each time (the addon buys nothing by itself)
    buy.all = S.Button(foot, "", W - 2 * PAD - 44, 36, "primary", function()
        local pos = WP.Scan.QueueState()
        if (pos or 0) > 0 or WP.Scan.QueueLeft() > 0 then WP.Scan.ClearQueue(); return end
        local list = {}
        for _, e in ipairs(buy.order or {}) do
            if not e.done and e.src ~= "Absent" then list[#list + 1] = { id = e.id, qty = math.max(1, e.need - e.have) } end
        end
        if #list > 0 then WP.Scan.BuyQueue(list) end
    end)
    buy.all:SetPoint("LEFT", PAD, 0)
    buy.rescan = S.Button(foot, "", 36, 36, "secondary", function()
        if WP.Scan.Busy() then WP.Scan.Stop(); return end
        local ids = {}
        for _, e in ipairs(shop) do if not e.done then ids[#ids + 1] = e.id end end
        WP.Scan.Start(ids)
    end, function()
        if not WP.AuctionHouseOpen() then return { L("Ouvre l'hôtel des ventes pour scanner") } end
        return { L("Rescanner les prix de la liste"), buy.ageText }
    end)
    buy.rescan:SetPoint("RIGHT", -PAD, 0)
    local ic = buy.rescan:CreateTexture(nil, "ARTWORK")
    ic:SetSize(16, 16); ic:SetPoint("CENTER"); S.SetIcon(ic, REFRESH.atlases, REFRESH.path)
    buy.rescanIcon = ic
end

local function RenderShop()
    local left, rep = 0, 0
    for _, e in ipairs(shop) do if not e.done then left = left + 1 end end
    for _, r in ipairs(plan) do rep = rep + r.w.rep end
    if left == 0 then
        buy.total:SetText(L("Rien à acheter"))
        buy.sub:SetText(#data > 0 and L("Tes writs suffisent pour l'objectif.") or "")
    else
        buy.total:SetText(L("Coût") .. "  " .. S.Money(shopTotal))
        buy.sub:SetText(string.format(L("Pour %d writs, qui rapportent %d points de réputation."), #plan, rep))
    end
    local absent = 0
    for _, e in ipairs(shop) do if not e.done and e.src == "Absent" then absent = absent + 1 end end
    -- groups: one per turn-in zone, in the order the list gives
    local groups, order = {}, {}
    for _, e in ipairs(shop) do
        local key = e.zone or "?"
        if not groups[key] then groups[key] = {}; order[#order + 1] = key end
        table.insert(groups[key], e)
    end
    local y, hi, ri = 0, 0, 0
    -- items the last scan found nowhere: said once, at the top of the list
    buy.absent:SetShown(absent > 0)
    if absent > 0 then
        buy.absent:SetText(string.format(L("%d objets absents de l'HV : rescanne plus tard ou exclus leur zone."), absent))
        y = math.ceil(buy.absent:GetStringHeight() or 16) + 10
    end
    buy.order = {}   -- the entries as shown, for "Tout acheter à la suite"
    local function head(text, map, excluded, label)
        hi = hi + 1
        local h = buy.heads.Get(hi)
        h.map, h.excluded = map, excluded
        h.foldKey, h.folded = nil, nil
        h.fold:Hide()
        h:SetText(text)
        h.btn.label:SetText(label or "")
        h.btn:SetShown(map ~= nil)
        return h
    end
    buy.zoneKeys = order
    local only = WLWritsCharDB.shopZone
    if only and not groups[only] then only = nil; WLWritsCharDB.shopZone = nil end
    buy.zoneBtn.label:SetText(only or L("Toutes les zones"))
    local fold = WLWritsCharDB.shopFold or {}
    for _, key in ipairs(order) do
      if not only or key == only then
        -- the writs of the zone: an envelope and its item make one line
        local cards, byGroup = {}, {}
        for _, e in ipairs(groups[key]) do
            local g = e.group or e.id
            local c = byGroup[g]
            if not c then c = { entries = {} }; byGroup[g] = c; cards[#cards + 1] = c end
            c.entries[#c.entries + 1] = e
            if e.isWrit then c.writ = e else c.item = c.item or e end
            buy.order[#buy.order + 1] = e
        end
        local writs, zoneCost = 0, 0
        for _, c in ipairs(cards) do
            c.cost, c.absent, c.done, c.short = 0, false, true, false
            for _, e in ipairs(c.entries) do
                if not e.done then
                    c.done = false
                    if e.src == "Absent" then c.absent = true
                    elseif e.price then c.cost = c.cost + e.price * (e.need - e.have)
                    else c.unknown = true end
                    if e.listed and e.listed < e.need - e.have then c.short = true end
                end
            end
            zoneCost = zoneCost + c.cost
            if c.writ then writs = writs + 1 end
        end
        local folded = fold[key]
        local h = head(string.format(L("À rendre en %s · %d writs"), key, writs) .. "  " .. S.Hex(C.muted) .. S.Money(zoneCost) .. "|r",
            groups[key][1] and groups[key][1].map, false, L("Exclure"))
        h.foldKey, h.folded = key, folded
        h.fold:SetKind(folded and "right" or "down")
        h.fold:Show()
        h:ClearAllPoints(); h:SetPoint("TOPLEFT", 2, -y)
        y = y + 24
        if not folded then
          for idx, c in ipairs(cards) do
            ri = ri + 1
            local r = buy.rows.Get(ri)
            local main = c.writ or c.item
            r.entry, r.entries = main, c.entries
            r:ClearAllPoints(); r:SetPoint("TOPLEFT", 0, -(y - (idx > 1 and 1 or 0)))
            r.icon:SetTexture(S.ItemIcon(main.id))
            -- "Envelope: Craftsman's Writ: Iridescent Hammer" reads "Iridescent Hammer"; the item's count follows
            local short = c.writ and (c.writ.name:match(".*:%s*(.+)$") or c.writ.name) or main.name
            local n = c.item and c.item.need or 1
            r.title = short .. (n > 1 and (" ×" .. n) or "")
            r.name:SetText(r.title .. (c.writ and "" or ("  " .. S.Hex(C.muted) .. L("(objet seul)") .. "|r")))
            SetColor(r.name, c.item and S.QualityColor(c.item.id) or C.text)
            if c.done then
                r:SetAlpha(0.45); r.price:SetText(L("dans tes sacs")); SetColor(r.price, C.dim)
            else
                r:SetAlpha(1)
                if c.absent then r.price:SetText(L("absent de l'HV")); SetColor(r.price, C.danger)
                elseif c.unknown and c.cost == 0 then r.price:SetText("?"); SetColor(r.price, C.dim)
                else r.price:SetText(S.Money(c.cost)); SetColor(r.price, c.short and C.warn or C.text) end
            end
            y = y + 37
          end
        end
        y = y + 10
      end
    end
    -- the zones left out, to bring back
    local out = {}
    for map in pairs((WLWritsCharDB.skip and WLWritsCharDB.skip.zones) or {}) do out[#out + 1] = map end
    table.sort(out, function(a, b) return WP.ZoneName(a) < WP.ZoneName(b) end)
    if #out > 0 then
        local h = head(S.Hex(C.dim) .. L("Zones laissées de côté") .. "|r")
        h:ClearAllPoints(); h:SetPoint("TOPLEFT", 2, -(y + 6))
        y = y + 28
        for _, map in ipairs(out) do
            h = head(S.Hex(C.warn) .. string.format(L("Zone exclue : %s"), WP.ZoneName(map)) .. "|r", map, true, L("Remettre"))
            h:ClearAllPoints(); h:SetPoint("TOPLEFT", 2, -y)
            y = y + 24
        end
    end
    buy.heads.HideFrom(hi + 1)
    buy.rows.HideFrom(ri + 1)
    buy.empty:SetShown(#shop == 0)
    buy.empty:SetText(L("Ton plan du jour est couvert."))
    buy.scroll.content:SetHeight(math.max(y, 10))

    -- the rescan icon stays clickable while a scan runs (a click stops it)
    local done = WP.Scan.Progress()
    if done or WP.AuctionHouseOpen() then buy.rescan:Enable() else buy.rescan:Disable() end
    buy.rescanIcon:SetDesaturated(not buy.rescan:IsEnabled())
    local newest
    for _, e in ipairs(shop) do
        local _, _, ago = WP.Scan.Get(e.id)
        if ago and (not newest or ago < newest) then newest = ago end
    end
    buy.ageText = newest and string.format(L("prix d'il y a %d min"), math.floor(newest / 60)) or nil

    local n = 0
    for _, e in ipairs(buy.order) do if not e.done and e.src ~= "Absent" then n = n + 1 end end
    local pos, total = WP.Scan.QueueState()
    if not WP.AuctionHouseOpen() then
        buy.all.label:SetText(L("Ouvre l'hôtel des ventes pour acheter")); buy.all:Disable()
    elseif (pos or 0) > 0 then
        buy.all.label:SetText(string.format(L("Achat %d sur %d · clic pour arrêter"), pos, total)); buy.all:Enable()
    else
        buy.all.label:SetText(string.format(L("Tout acheter à la suite (%d)"), n))
        if n > 0 then buy.all:Enable() else buy.all:Disable() end
    end
end

-- ---------------------------------------------------------------- Tous les writs

local all = { search = "", rank = "all", open = {} }

local function BuildAll(p)
    local box = CreateFrame("EditBox", nil, p)
    box:SetPoint("TOPLEFT", PAD, -12); box:SetPoint("TOPRIGHT", -PAD, -12); box:SetHeight(30)
    box:SetAutoFocus(false)
    box:SetFontObject(ChatFontNormal)
    box:SetTextInsets(28, 8, 0, 0)
    S.Solid(box, "BACKGROUND", C.card):SetAllPoints()
    S.Border(box, C.border)
    local glass = box:CreateTexture(nil, "ARTWORK")
    glass:SetSize(14, 14); glass:SetPoint("LEFT", 9, 0)
    S.SetIcon(glass, { "common-search-magnifyingglass" }, "Interface\\Common\\UI-Searchbox-Icon")
    box.hint = S.Text(box, 13, C.muted)
    box.hint:SetPoint("LEFT", 28, 0)
    box.hint:SetText(L("Objet ou zone"))
    box:SetScript("OnTextChanged", function(self)
        all.search = (self:GetText() or ""):lower()
        self.hint:SetShown(all.search == "")
        WP.RefreshSoon(0.2)
    end)
    box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    box:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)

    local rank = S.Text(p, 13, C.dim)
    rank:SetPoint("TOPLEFT", PAD, -54)
    rank:SetText(L("Rang"))
    all.seg = S.Segmented(p, { { "all", L("Tous") }, { "Journeyman", WP.Tier("Journeyman") }, { "Expert", WP.Tier("Expert") }, { "Artisan", WP.Tier("Artisan") } },
        function() return all.rank end, function(v) all.rank = v; WP.Refresh() end, 26)
    all.seg:SetPoint("LEFT", rank, "RIGHT", 10, 0)

    local sc = Scroller(p)
    sc:SetPoint("TOPLEFT", PAD, -84); sc:SetPoint("BOTTOMRIGHT", -PAD, 66)
    all.scroll = sc
    local foot = CreateFrame("Frame", nil, p)
    foot:SetPoint("BOTTOMLEFT"); foot:SetPoint("BOTTOMRIGHT"); foot:SetHeight(60)
    local fl = S.Solid(foot, "BORDER", C.divider); fl:SetPoint("TOPLEFT"); fl:SetPoint("TOPRIGHT"); fl:SetHeight(1)
    all.pickLine = S.Text(foot, 15, C.text, true)
    all.pickLine:SetPoint("TOPLEFT", PAD, -12); all.pickLine:SetPoint("RIGHT", -110, 0); all.pickLine:SetJustifyH("LEFT")
    all.pickSub = S.Text(foot, 12, C.dim)
    all.pickSub:SetPoint("TOPLEFT", all.pickLine, "BOTTOMLEFT", 0, -4); all.pickSub:SetPoint("RIGHT", -110, 0); all.pickSub:SetJustifyH("LEFT")
    all.pickSub:SetJustifyV("TOP"); all.pickSub:SetWordWrap(true)
    if all.pickSub.SetMaxLines then all.pickSub:SetMaxLines(2) end
    all.clear = S.Button(foot, L("Tout décocher"), 92, 30, "secondary", function() WP.ClearPicked() end)
    all.clear:SetPoint("RIGHT", -PAD, 0)
    all.heads = Pool(function()
        local b = CreateFrame("Button", nil, sc.content)
        b:SetSize(W - 2 * PAD, 30)
        b.text = S.Text(b, 13, C.dim)
        b.text:SetPoint("LEFT", 2, 0)
        -- a drawn chevron for the sections that fold (no font glyph: the game font may lack them)
        b.fold = S.Glyph(b, "right", 10, C.dim)
        b.fold:SetPoint("LEFT", 2, 0)
        b:SetScript("OnClick", function(self) if self.key then all.open[self.key] = not all.open[self.key]; WP.Refresh() end end)
        return b
    end)
    all.rows = Pool(function()
        local r = CreateFrame("Button", nil, sc.content)
        r:SetSize(W - 2 * PAD, 46)
        S.Solid(r, "HIGHLIGHT", { 1, 1, 1 }, 0.05):SetAllPoints()   -- above the text: must stay see-through
        r.icon = r:CreateTexture(nil, "ARTWORK")
        -- the tick box: your own list of writs to do
        r.box = CreateFrame("Button", nil, r)
        r.box:SetSize(18, 18); r.box:SetPoint("LEFT", 4, 0)
        r.box.fill = S.Solid(r.box, "BACKGROUND", C.brand, 0); r.box.fill:SetAllPoints()
        r.box.border = S.Border(r.box, C.border)
        r.box.check = S.Glyph(r.box, "check", 12, { 1, 1, 1 })
        r.box.check:SetPoint("CENTER")
        r.box:SetScript("OnClick", function(self)
            local x = self:GetParent().row
            if x and x.state ~= "done" then WP.SetPicked(x.w, not WP.IsPicked(x.w)) end
        end)
        r.icon:SetSize(20, 20); r.icon:SetPoint("LEFT", 30, 0); r.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        r.cost = S.Text(r, 13, C.text)
        r.cost:SetPoint("RIGHT", -6, 0)
        r.cost:SetWidth(80)
        r.cost:SetJustifyH("RIGHT")
        -- name and sub stop before the cost column
        r.name = S.Text(r, 14, C.text)
        r.name:SetPoint("TOPLEFT", 58, -7)
        r.name:SetPoint("RIGHT", r.cost, "LEFT", -8, 0)
        r.sub = S.Text(r, 12, C.dim)
        r.sub:SetPoint("TOPLEFT", 58, -26)
        r.sub:SetPoint("RIGHT", r.cost, "LEFT", -8, 0)
        r:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        r:SetScript("OnClick", function(self, button)
            local x = self.row
            if not x then return end
            if button == "RightButton" then
                -- a writ set aside with its whole zone comes back from the zone list in the settings
                if not (x.w.map and WP.IsSkipped("zones", x.w.map)) then
                    WP.SetSkipped("writs", x.w.writ, not WP.IsSkipped("writs", x.w.writ))
                    if self:IsMouseOver() and self:GetScript("OnEnter") then self:GetScript("OnEnter")(self) end
                end
            elseif IsShiftKeyDown() then WP.Search({ x }) else WP.TravelTo(x.w) end
        end)
        r:SetScript("OnEnter", function(self)
            local x = self.row
            if not x then return end
            local w = x.w
            local lines = { WP.ItemName(w.writ, w.writName),
                string.format(L("Enveloppe %s · objet %s · bourse rendue -%s"), x.ownWrit and L("possédée") or S.Money(x.writPrice),
                    (x.ownItem or x.state == "ready") and L("possédé") or S.Money(x.itemPrice and x.itemPrice * (w.count or 1)), S.Money((WP.PouchValue(w.tier)))) }
            if w.npcName then lines[#lines + 1] = string.format(L("À rendre à %s"), w.npcName) end
            lines[#lines + 1] = { L("Clic : GPS · Maj-clic : chercher à l'HV"), 0.6, 0.6, 0.6 }
            if w.map and WP.IsSkipped("zones", w.map) then
                lines[#lines + 1] = { L("Zone laissée de côté : remets-la dans l'onglet Achats."), C.warn[1], C.warn[2], C.warn[3] }
            else
                lines[#lines + 1] = { WP.IsSkipped("writs", w.writ) and L("Clic droit : le remettre dans le plan") or L("Clic droit : ne pas le faire"), 0.6, 0.6, 0.6 }
            end
            S.Tip(self, lines)
        end)
        r:SetScript("OnLeave", S.HideTip)
        return r
    end)
end

local function Matches(r)
    if all.rank ~= "all" and r.w.tier ~= all.rank then return false end
    if all.search == "" then return true end
    local s = all.search
    local nm = WP.ItemName(r.w.item, r.w.itemName):lower()
    return nm:find(s, 1, true) or (r.zone or ""):lower():find(s, 1, true)
end

local function RenderAll()
    all.seg:Update()
    local todo, later, done = {}, {}, {}
    for _, r in ipairs(data) do
        if Matches(r) then
            if r.state == "done" then done[#done + 1] = r
            elseif r.tooHigh or not r.w.map then later[#later + 1] = r
            else todo[#todo + 1] = r end
        end
    end
    local function byCost(a, b) return (a.per100 or math.huge) < (b.per100 or math.huge) end
    table.sort(todo, byCost); table.sort(later, byCost)
    local y, hi, ri = 0, 0, 0
    local function head(text, key)
        hi = hi + 1
        local h = all.heads.Get(hi)
        h.key = key
        h:ClearAllPoints(); h:SetPoint("TOPLEFT", 0, -y)
        h.text:SetText(text)
        h.text:ClearAllPoints()
        if key then
            h.fold:SetKind(all.open[key] and "down" or "right")
            h.fold:Show(); h.text:SetPoint("LEFT", 18, 0)
        else
            h.fold:Hide(); h.text:SetPoint("LEFT", 2, 0)
        end
        y = y + 30
    end
    local function row(r)
        ri = ri + 1
        local b = all.rows.Get(ri)
        b.row = r
        local on = WP.IsPicked(r.w) and r.state ~= "done"
        b.box:SetShown(r.state ~= "done")
        b.box.fill:SetAlpha(on and 1 or 0)
        b.box.border(on and C.brand or C.border)
        b.box.check:SetShown(on)
        b:ClearAllPoints(); b:SetPoint("TOPLEFT", 0, -y)
        local w = r.w
        b.icon:SetTexture(S.ItemIcon(w.item))
        local craft = Craftable(w.item) and (" " .. S.Hex(C.info) .. L("· tu le fabriques") .. "|r") or ""
        b.name:SetText(WP.ItemName(w.item, w.itemName) .. ((w.count or 1) > 1 and (" ×" .. w.count) or "") .. craft)
        SetColor(b.name, S.QualityColor(w.item))
        local where = w.map and string.format("%s %.0f, %.0f", r.zone, w.x, w.y) or L("lieu inconnu")
        if r.tooHigh and r.zoneMin then where = where .. string.format(L(", niv. %d+"), r.zoneMin) end
        b.sub:SetText((r.skipped and (S.Hex(C.warn) .. L("mis de côté") .. "|r · ") or "") .. string.format("%s · %s, %d %s", where, WP.Tier(w.tier), w.rep, L("pts")))
        if r.state == "done" then b.cost:SetText(L("rendu")); SetColor(b.cost, C.dim)
        elseif r.state == "ready" then b.cost:SetText(L("prêt")); SetColor(b.cost, C.ready)
        elseif r.net then
            local per = r.net
            b.cost:SetText(per < 0 and ("+" .. S.Money(-per)) or S.Money(per))
            SetColor(b.cost, per < 0 and C.ready or C.text)
        else b.cost:SetText("?"); SetColor(b.cost, C.dim) end
        b:SetAlpha((r.state == "done" or r.skipped) and 0.5 or 1)
        y = y + 46
    end
    head(L("À faire, le moins cher d'abord"))
    for _, r in ipairs(todo) do row(r) end
    if #later > 0 then
        head(string.format("%s : %d", L("Plus tard, zones trop hautes ou lieu inconnu"), #later), "later")
        if all.open.later then for _, r in ipairs(later) do row(r) end end
    end
    if #done > 0 then
        head(string.format("%s : %d", L("Rendus aujourd'hui"), #done), "done")
        if all.open.done then for _, r in ipairs(done) do row(r) end end
    end
    all.heads.HideFrom(hi + 1)
    all.rows.HideFrom(ri + 1)
    all.scroll.content:SetHeight(math.max(y, 10))
    local n, cost, net, rep, unknown = WP.PickTotals(data)
    if n == 0 then
        all.pickLine:SetText(L("Coche les writs que tu veux faire"))
        all.pickSub:SetText(L("Rien à cocher si tu veux : sans coche, WL Helper choisit les moins chers pour ton objectif."))
        all.clear:Hide()
    else
        all.pickLine:SetText(string.format(L("%d writs · %s · %d points de réputation"), n, S.Money(cost), rep))
        all.pickSub:SetText(string.format(L("%s une fois les bourses ouvertes · l'onglet Achats suit tes coches"), S.Money(net))
            .. (unknown > 0 and ("  " .. string.format(L("(%d sans prix)"), unknown)) or ""))
        all.clear:Show()
    end
end

-- ---------------------------------------------------------------- window

local current = "today"

function WP.ShowTab(key)
    current = key
    for k, p in pairs(pages) do p:SetShown(k == key) end
    tabs:Update()
    WP.Refresh()
end

local function Build()
    local db = WLWritsDB
    frame = S.Window("WLHelperComptoir", W, H, L("Writs"), nil, db, "point")
    local opts = S.IconButton(frame.header, { atlases = { "QuestLog-icon-setting" }, path = "Interface\\Buttons\\UI-OptionsButton" }, 28, { L("Réglages des Writs") }, function()
        if WP.OpenOptions then WP.OpenOptions("comptoir") end
    end)
    opts:SetPoint("RIGHT", frame.close, "LEFT", 0, 0)
    tabs = S.Tabs(frame, { { "today", L("Aujourd'hui") }, { "shop", L("Achats") }, { "all", L("Tous") } },
        function() return current end, WP.ShowTab, function(key)
            if key ~= "shop" then return nil end
            local n = 0
            for _, e in ipairs(shop) do if not e.done then n = n + 1 end end
            return n
        end)
    tabs:SetPoint("TOPLEFT", 1, -39); tabs:SetPoint("TOPRIGHT", -1, -39)
    -- an auction house scan in progress, whatever the tab: a thin bar under the tabs and "12 / 48"
    frame.scanBar = CreateFrame("Frame", nil, frame)
    frame.scanBar:SetPoint("TOPLEFT", 1, -75); frame.scanBar:SetPoint("TOPRIGHT", -1, -75); frame.scanBar:SetHeight(2)
    S.Solid(frame.scanBar, "BACKGROUND", C.divider):SetAllPoints()
    frame.scanFill = S.Solid(frame.scanBar, "ARTWORK", C.ready)
    frame.scanFill:SetPoint("TOPLEFT"); frame.scanFill:SetPoint("BOTTOMLEFT")
    frame.scanText = S.Text(frame, 12, C.ready)
    frame.scanText:SetPoint("RIGHT", frame, "TOPRIGHT", -12, -57)
    frame.scanBar:Hide()
    for _, key in ipairs({ "today", "shop", "all", "favor" }) do
        local p = CreateFrame("Frame", nil, frame)
        p:SetPoint("TOPLEFT", 0, -76); p:SetPoint("BOTTOMRIGHT")
        pages[key] = p
    end
    BuildToday(pages.today)
    BuildShop(pages.shop)
    BuildAll(pages.all)
    if WP.BuildFavor then WP.BuildFavor(pages.favor) end
    frame:SetScript("OnShow", function() WP.Refresh() end)
    frame:HookScript("OnHide", HideEnvelopes)
    -- the envelope buttons follow the window: off while it moves, laid again where it lands
    frame.header:HookScript("OnDragStart", HideEnvelopes)
    frame.header:HookScript("OnDragStop", PlaceEnvelopes)
    local ev = CreateFrame("Frame")
    pcall(ev.RegisterEvent, ev, "PLAYER_REGEN_DISABLED")
    pcall(ev.RegisterEvent, ev, "PLAYER_REGEN_ENABLED")
    ev:SetScript("OnEvent", function(_, e)
        if e == "PLAYER_REGEN_DISABLED" then HideEnvelopes() else PlaceEnvelopes() end
    end)
    -- At the auction house the prices move while you scan: a light refresh every few seconds.
    frame:SetScript("OnUpdate", function(self, dt)
        self.acc = (self.acc or 0) + dt
        if self.acc < 5 then return end
        self.acc = 0
        if WP.AuctionHouseOpen() and not InCombatLockdown() then WP.Refresh() end
    end)
    WP.ShowTab("today")
end

function WP.Refresh()
    if not frame or not frame:IsShown() then return end
    craftable = nil
    local name = WP.Reputation()
    frame.subtitle:SetText("")
    data = WP.Rows()
    for _, r in ipairs(data) do r.inPlan = nil end
    plan, need, pending, readyRep = WP.Plan(data)
    pending = pending or 0
    shop, shopTotal = WP.ShoppingList(data)
    tabs:Update()
    if current == "today" then RenderToday()
    elseif current == "shop" then RenderShop()
    elseif current == "favor" then if WP.RenderFavor then WP.RenderFavor() end
    else RenderAll() end
    WP.PaintScan()
    -- once the new layout has its sizes
    C_Timer.After(0, PlaceEnvelopes)
end

local queued = false
function WP.RefreshSoon(delay)
    if not frame or not frame:IsShown() or queued or InCombatLockdown() then return end
    queued = true
    C_Timer.After(delay or 1, function() queued = false; if not InCombatLockdown() then WP.Refresh() end end)
end

function WP.PaintScan()
    if not frame then return end
    local done, tot = WP.Scan and WP.Scan.Progress()
    if done and tot and tot > 0 then
        frame.scanBar:Show()
        frame.scanFill:SetWidth(math.max(1, (W - 2) * done / tot))
        frame.scanText:SetText(string.format(L("Scan %d / %d"), done, tot))
    else
        frame.scanBar:Hide(); frame.scanText:SetText("")
    end
end

function WP.OnScanProgress()
    WP.PaintScan()
    if frame and frame:IsShown() then WP.RefreshSoon(0.3) end
end

function WP.OnGPSChanged()
    if frame and frame:IsShown() and current == "today" then
        PaintTour()
    end
end

function WP.HideWindow() if frame then frame:Hide() end end
function WP.WindowShown() return frame and frame:IsShown() or false end
-- true while the window shows the writs (not the Merchant's Favor page)
function WP.WritsMode() return current ~= "favor" end

-- Two separate things share this window: the Craftsman's Writs (reputation with Durotar Supply and
-- Logistics) and the Merchant's Favor (the currency of the Waylaid Crates). mode "favor" shows only the
-- Favor page, with its own title; anything else shows the writs and their three tabs.
function WP.Open(mode)
    if WP.ModuleOff("writs") then return end
    if not frame then Build() end
    if mode == "favor" then
        frame.title:SetText(L("Faveur du marchand"))
        tabs:Hide()
        WP.ShowTab("favor")
    else
        frame.title:SetText(L("Writs"))
        tabs:Show()
        if current == "favor" then WP.ShowTab("today") end
    end
    frame:Show(); frame:Raise()
end

function WP.Toggle()
    if frame and frame:IsShown() then frame:Hide(); return end
    WP.Open("writs")
end
function WP.OpenFavor() WP.Open("favor") end

