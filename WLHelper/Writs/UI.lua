-- Writs/UI.lua: the Comptoir (Writs), 420 wide, sized to its content, with three tabs:
--   Aujourd'hui    the reputation goal, then the writs to turn in now grouped by zone, and one
--                  primary action (the GPS tour, or buying the plan);
--   Achats         what to buy for today's plan, grouped by turn-in zone; a click opens the
--                  auction house's buy page;
--   Tous les writs every writ, cheapest first, then those for later and those done today.
-- The Merchant's Favor page (Favor.lua) lives in the same window, without tabs.
-- Built from Style.lua's components; frames are pooled and filled again on each refresh. Each page
-- measures its top block, its list and its bottom row; the window then fits them (and the list
-- scrolls once the window reaches 80 % of the screen height).
local ADDON, root = ...
root.Writs = root.Writs or {}
local ns = root.Writs
local WP = ns.WP
local L = ns.L
local S = ns.S
local C = S.C
local F = S.F

ns.AddEnglish({
    -- window and tabs
    ["Writs"] = "Writs",
    ["Aujourd'hui"] = "Today",
    ["Achats"] = "Shopping",
    ["Tous les writs"] = "All writs",
    ["Réglages des Writs"] = "Writs settings",
    -- review 9
    ["Rends ton writ prêt, puis achètes-en %d de plus."] = "Turn in your ready writ, then buy %d more.",
    ["Il te faut encore 1 writ."] = "You need 1 more writ.",
    ["Il te faut encore %d writs."] = "You need %d more writs.",
    ["Il te faut encore 1 writ, pour environ %s."] = "You need 1 more writ, for about %s.",
    ["Il te faut encore %d writs, pour environ %s."] = "You need %d more writs, for about %s.",
    ["1 writ dépasse ton prix max : monte-le dans l'onglet Achats."] = "1 writ is above your max price: raise it in the Shopping tab.",
    ["Voir les achats"] = "See what to buy",
    ["Clic : voir l'onglet Achats"] = "Click: see the Shopping tab",
    ["Clic : guider vers %s"] = "Click: guide me to %s",
    ["Clic : guider vers le premier writ de la zone"] = "Click: guide me to the zone's first writ",
    ["le PNJ"] = "the NPC",
    ["Aucun writ sous ton prix max"] = "No writ under your max price",
    ["Monte le prix max dans l'onglet Achats pour en voir plus."] = "Raise the max price in the Shopping tab to see more.",
    ["Monte le prix max ci-dessus pour en voir plus."] = "Raise the max price above to see more.",
    ["Aucun writ n'est en vente pour ton objectif : scanne l'HV à nouveau plus tard."] = "No writ is for sale for your goal: scan the AH again later.",
    ["1 writ pour plus tard"] = "1 writ for later",
    ["%d writs pour plus tard"] = "%d writs for later",
    ["Zones trop hautes pour ton niveau."] = "Zones too high for your level.",
    ["Clic : voir ces writs"] = "Click: see these writs",
    ["Sans"] = "None",
    ["1 objet n'est pas en vente à l'HV : scanne à nouveau plus tard ou laisse sa zone de côté."] = "1 item is not for sale at the AH: scan again later or set its zone aside.",
    ["%d objets ne sont pas en vente à l'HV : scanne à nouveau plus tard ou laisse leur zone de côté."] = "%d items are not for sale at the AH: scan again later or set their zones aside.",
    ["Enveloppe %s, objet %s, moins la bourse rendue (%s)"] = "Envelope %s, item %s, minus the pouch refund (%s)",
    ["Soit %s une fois les bourses ouvertes."] = "That is %s once the pouches are opened.",
    ["L'onglet Achats suit tes coches."] = "The Shopping tab follows your ticks.",
    ["1 writ n'a pas encore de prix."] = "1 writ has no price yet.",
    ["%d writs n'ont pas encore de prix."] = "%d writs have no price yet.",

    ["Clic : ouvrir les réglages des Writs"] = "Click: open the trading post settings",
    ["Scan de l'HV : %d sur %d"] = "AH scan: %d of %d",
    -- Today
    ["%s dans %s points"] = "%s in %s points",
    ["%s atteint"] = "%s reached",
    ["Réputation introuvable"] = "Reputation not found",
    ["Ouvre ta fenêtre de personnage, onglet Réputation, une fois : WL Helper la lira ensuite."] =
        "Open your character window, Reputation tab, once: the trading post will read it from then on.",
    ["Objectif atteint. Pour continuer, choisis un rang plus haut dans les réglages des Writs."] =
        "Goal reached. To go on, pick a higher standing in the trading post settings.",
    ["Rends ton writ prêt et c'est bon."] = "Turn in your ready writ and you're done.",
    ["Rends tes %d writs prêts et c'est bon."] = "Turn in your %d ready writs and you're done.",
    ["Rends tes writs prêts, puis achètes-en %d de plus."] = "Turn in your ready writs, then buy %d more.",
    ["%d writs dépassent ton prix max : monte-le dans l'onglet Achats."] = "%d writs are above your max price: raise it in the Shopping tab.",
    ["Aucun writ abordable aujourd'hui : les offres changent demain."] = "No affordable writ today: the offers change tomorrow.",
    ["Nouveaux writs dans %d min"] = "New writs in %d min",
    ["Nouveaux writs dans %d h"] = "New writs in %d h",
    ["À rendre maintenant"] = "To turn in now",
    ["Y aller"] = "Go there",
    ["Prêt à rendre à %s"] = "Ready to turn in to %s",
    ["Prêt à rendre, %.0f, %.0f"] = "Ready to turn in, %.0f, %.0f",
    ["Dans le sac, mais l'objet manque"] = "In bags, but the item is missing",
    ["En cours : objet manquant, %s à l'HV"] = "In progress: item missing, %s at the AH",
    ["En cours : objet manquant"] = "In progress: item missing",
    ["Ouvrir l'enveloppe"] = "Open the envelope",
    ["Clic : ouvrir l'enveloppe et prendre la quête"] = "Click: open the envelope and take the quest",
    ["%d points de réputation · %s %.0f, %.0f"] = "%d reputation · %s %.0f, %.0f",
    ["À rendre à %s"] = "Turn in to %s",
    ["Lieu de remise sur la carte"] = "Turn-in spot on the map",
    ["Objet manquant : achète-le avant d'y aller."] = "Item missing: buy it before you go.",
    ["Clic : acheter l'objet"] = "Click: buy the item",
    ["Aucun writ en main"] = "No writ in hand",
    ["Les writs que tu achètes et ouvres apparaîtront ici, groupés par zone."] = "The writs you buy and open will show up here, grouped by zone.",
    ["Tout est rendu pour aujourd'hui"] = "Everything is turned in for today",
    ["De nouveaux writs arrivent à la réinitialisation quotidienne."] = "New writs arrive at the daily reset.",
    ["Lancer la tournée GPS (%d à rendre)"] = "Start the GPS tour (%d to turn in)",
    ["Arrêter la tournée GPS"] = "Stop the GPS tour",
    ["Scanner l'HV"] = "Scan the AH",
    ["Arrêter le scan"] = "Stop the scan",
    ["Clic : scanner les prix de la liste d'achat"] = "Click: scan the shopping list's prices",
    ["Clic : arrêter le scan"] = "Click: stop the scan",
    ["Ouvre l'hôtel des ventes pour scanner."] = "Open the auction house to scan.",
    ["Prix scannés à l'instant"] = "Prices scanned just now",
    ["Prix scannés il y a %d min"] = "Prices scanned %d min ago",
    ["Prix scannés il y a %d h"] = "Prices scanned %d h ago",
    -- Shopping
    ["Rien à acheter"] = "Nothing to buy",
    ["Tes writs suffisent pour ton objectif du jour."] = "Your writs are enough for today's goal.",
    ["Pour 1 writ, qui rapporte %d points de réputation."] = "For 1 writ, worth %d reputation.",
    ["Pour %d writs, qui rapportent %d points de réputation."] = "For %d writs, worth %d reputation.",
    ["Prix max pour 100 points"] = "Max price per 100 points",
    ["%d pa"] = "%ds",
    ["%d po"] = "%dg",
    ["Zone"] = "Zone",
    ["Toutes les zones"] = "All zones",
    ["1 writ"] = "1 writ",
    ["%d writs"] = "%d writs",
    ["Clic : replier la zone"] = "Click: fold the zone",
    ["Clic : afficher ces writs"] = "Click: show these writs",
    ["Clic : masquer ces writs"] = "Click: hide these writs",
    ["Clic : déplier la zone"] = "Click: unfold the zone",
    ["Exclure"] = "Leave out",
    ["Laisser cette zone de côté : le plan prend d'autres writs, ailleurs."] = "Leave this zone out: the plan takes other writs elsewhere.",
    ["Clic : laisser la zone de côté"] = "Click: leave the zone out",
    ["Enveloppe et objet"] = "Envelope and item",
    ["Objet seul"] = "Item only",
    ["Dans tes sacs"] = "In your bags",
    ["Pas en vente à l'HV"] = "Not for sale at the AH",
    ["Peu en vente : pas assez pour tout"] = "Few for sale: not enough for all",
    ["Enveloppe"] = "Envelope",
    ["Dans tes sacs : %d sur %d"] = "In your bags: %d of %d",
    ["En vente au dernier scan : %d"] = "For sale at the last scan: %d",
    ["Clic : acheter l'enveloppe et l'objet"] = "Click: buy the envelope and the item",
    ["Maj-clic : chercher à l'HV"] = "Shift-click: search at the AH",
    ["Zones laissées de côté"] = "Zones left out",
    ["Hors du plan"] = "Out of the plan",
    ["Remettre"] = "Put back",
    ["Clic : remettre la zone dans le plan"] = "Click: put the zone back in the plan",
    ["Acheter l'objet"] = "Buy the item",
    ["Acheter les %d objets"] = "Buy the %d items",
    ["Arrêter les achats (%d sur %d)"] = "Stop buying (%d of %d)",
    ["L'hôtel des ventes est fermé."] = "The auction house is closed.",
    ["Ouvre chaque page d'achat à la suite : tu cliques sur Acheter à chaque fois."] =
        "Opens each buy page in a row: you click Buy each time.",
    ["Clic : ouvrir la première page d'achat"] = "Click: open the first buy page",
    ["Clic : arrêter la suite d'achats"] = "Click: stop the buying run",
    -- All writs
    ["Ex. Potion, Tanaris"] = "E.g. Potion, Tanaris",
    ["Tous"] = "All",
    ["À faire, le moins cher d'abord"] = "To do, cheapest first",
    ["Plus tard : zones trop hautes ou lieu inconnu"] = "Later: zones too high or spot unknown",
    ["Rendus aujourd'hui"] = "Turned in today",
    ["Aucun writ ne correspond"] = "No writ matches",
    ["Essaie un autre nom d'objet ou de zone."] = "Try another item or zone name.",
    ["Lieu inconnu"] = "Spot unknown",
    [", niv. %d+"] = ", level %d+",
    ["Mis de côté"] = "Set aside",
    ["%s · %s · %d points"] = "%s · %s · %d points",
    ["Tu sais le fabriquer"] = "You can craft it",
    ["Rendu"] = "Turned in",
    ["Prêt"] = "Ready",
    ["possédée"] = "owned",
    ["possédé"] = "owned",
    ["Clic droit : le remettre dans le plan"] = "Right-click: put it back in the plan",
    ["Clic droit : ne pas le faire"] = "Right-click: skip it",
    ["Zone laissée de côté : remets-la depuis l'onglet Achats."] = "Zone left out: put it back from the Shopping tab.",
    ["Clic : le cocher pour ton plan"] = "Click: tick it for your plan",
    ["Clic : le décocher"] = "Click: untick it",
    ["Coche les writs que tu veux faire"] = "Tick the writs you want to do",
    ["Sans coche, le plan prend les moins chers pour ton objectif."] = "With none ticked, the plan takes the cheapest for your goal.",
    ["1 writ coché · %s · %d points"] = "1 writ ticked · %s · %d points",
    ["%d writs cochés · %s · %d points"] = "%d writs ticked · %s · %d points",
    ["(%d sans prix)"] = "(%d without a price)",
    ["Tout décocher"] = "Untick all",
    -- Favor mode
    ["Faveur du marchand"] = "Merchant's Favor",
})

local W, INSET = 420, 16
local LIST_W = W - 2 * INSET
local frame, tabs, pages = nil, nil, {}
local data, plan, shop, shopTotal = {}, {}, {}, 0
local need, pending, readyRep = nil, 0, 0

local function num(v) return type(v) == "number" and not (root.IsSecret and root.IsSecret(v)) and v or nil end
local function Height(fs, minH)
    local ok, h = pcall(fs.GetStringHeight, fs)
    h = ok and num(h) or 0
    return math.max(h, minH or 0)
end
local function Width(fs) return root.TextWidth(fs) end
local function Big(n) return BreakUpLargeNumbers and BreakUpLargeNumbers(n) or tostring(n) end

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

-- A page: a top block (measured), a scroll area for the list, a bottom row (measured).
-- page:Fit(topH, listH, bottomH) places the list between them and sizes the window.
local function Page(key)
    local p = CreateFrame("Frame", nil, frame)
    p.sa = S.ScrollArea(p)
    p.sa.child:SetWidth(LIST_W)
    function p:Fit(topH, listH, bottomH)
        local top = 12 + topH + (topH > 0 and 12 or 0)
        local bottom = 12 + bottomH + (bottomH > 0 and 12 or 0)
        self.sa:ClearAllPoints()
        self.sa:SetPoint("TOPLEFT", INSET, -top)
        self.sa:SetPoint("BOTTOMRIGHT", -INSET, bottom)
        self.sa.child:SetWidth(LIST_W)
        self.sa:SetContentHeight(listH)
        local content = topH + (topH > 0 and 12 or 0) + listH + (bottomH > 0 and 12 or 0) + bottomH
        frame:FitHeight(content)
        frame.lastContent = content
    end
    pages[key] = p
    return p
end

-- A fold head of a list: chevron, label 13 fg, count 11 muted, optional ghost link at the right.
local function FoldHead(parent, onClick, linkLabel, onLink)
    local b = CreateFrame("Button", nil, parent)
    b.wlOwned = true
    b:SetHeight(32)
    b.hl = S.Solid(b, "BACKGROUND", C.hoverFill); b.hl:SetAllPoints(); b.hl:SetAlpha(0)
    b.chev = S.Icon(b, "chevron_down", 12, "ARTWORK", C.muted)
    b.chev:SetPoint("BOTTOMLEFT", 0, 8)
    b.label = S.Text(b, F.body, C.fg)
    b.label:SetPoint("BOTTOMLEFT", 18, 6)
    S.ClampLabel(b.label, nil, b)
    b.count = S.Text(b, F.meta, C.muted)
    b.count:SetPoint("BOTTOMLEFT", b.label, "BOTTOMRIGHT", 6, 0)
    b.count:SetWordWrap(false)
    b.rule = S.Rule(b); b.rule:SetPoint("BOTTOMLEFT"); b.rule:SetPoint("BOTTOMRIGHT")
    if linkLabel then
        b.link = S.Button(b, linkLabel, 0, 24, "ghost", function() if onLink then onLink(b) end end,
            function() return b.linkTip end)
        b.link:SetPoint("BOTTOMRIGHT", 0, 3)
    end
    b:SetScript("OnClick", function(self) if self.foldable and onClick then onClick(self) end end)
    b:SetScript("OnEnter", function(self)
        if not self.foldable then return end
        self.hl:SetAlpha(1); self.chev:SetVertexColor(C.fg[1], C.fg[2], C.fg[3])
        S.Tip(self, { self.label:GetText(), self.folded and (self.tipOpen or L("Clic : déplier la zone")) or (self.tipClose or L("Clic : replier la zone")) })
    end)
    b:SetScript("OnLeave", function(self) self.hl:SetAlpha(0); self.chev:SetVertexColor(C.muted[1], C.muted[2], C.muted[3]); S.HideTip() end)
    function b:Set(text, count, foldable, folded)
        self.label:SetText(text or "")
        self.count:SetText(count or ""); self.count:SetShown(count ~= nil)
        self.foldable, self.folded = foldable, folded
        self.chev:SetShown(foldable and true or false)
        if foldable then S.HDIcon(self.chev, folded and "chevron_right" or "chevron_down", C.muted) end
        self.label:ClearAllPoints(); self.label:SetPoint("BOTTOMLEFT", foldable and 18 or 0, 6)
        local right = self.link and self.link:IsShown() and ((num(self.link:GetWidth()) or 60) + 12) or 0
        local countW = count and (Width(self.count) + 6) or 0
        self.label:SetWidth(math.max(40, math.min(Width(self.label) + 1, LIST_W - (foldable and 18 or 0) - countW - right)))
    end
    return b
end

-- The scan's refresh icon, for the bottom rows: stops a running scan, else scans `ids()`.
local function ScanAge(ids)
    local newest
    for _, id in ipairs(ids) do
        local _, _, ago = WP.Scan.Get(id)
        if ago and (not newest or ago < newest) then newest = ago end
    end
    if not newest then return nil end
    local m = math.floor(newest / 60)
    if m < 1 then return L("Prix scannés à l'instant") end
    if m < 60 then return string.format(L("Prix scannés il y a %d min"), m) end
    return string.format(L("Prix scannés il y a %d h"), math.floor(m / 60))
end
local function ScanButton(parent, ids)
    local b = S.IconButton(parent, "refresh", 28, function()
        if WP.Scan.Busy() then return { L("Arrêter le scan"), L("Clic : arrêter le scan") } end
        local lines = { L("Scanner l'HV") }
        local age = ScanAge(ids())
        if age then lines[#lines + 1] = age end
        if WP.AuctionHouseOpen() then lines[#lines + 1] = L("Clic : scanner les prix de la liste d'achat") end
        return lines
    end, function()
        if WP.Scan.Busy() then WP.Scan.Stop() else WP.Scan.Start(ids()) end
    end)
    b.disabledReason = L("Ouvre l'hôtel des ventes pour scanner.")
    function b:Update()
        if WP.Scan.Busy() or WP.AuctionHouseOpen() then self:Enable() else self:Disable() end
        self:SetToggled(WP.Scan.Busy())
    end
    return b
end

-- ---------------------------------------------------------------- Aujourd'hui

local today = {}

-- "Open the envelope" buttons. Using an item is protected, so they are secure buttons; to keep the
-- Comptoir window an ordinary frame (it may open, close and redraw in combat), they are parented and
-- anchored to UIParent and laid on their row's own button line out of combat. Combat hides them; the
-- row keeps the button's line empty until combat ends.
local ENV_W, ENV_H = 156, 24
local envelopes, envRows = {}, {}
local function EnvelopeButton(i)
    local b = envelopes[i]
    if b then return b end
    b = CreateFrame("Button", "WLHelperEnvelope" .. i, UIParent, "SecureActionButtonTemplate")
    b.wlOwned = true
    b:SetSize(ENV_W, ENV_H)
    b:RegisterForClicks("AnyUp", "AnyDown")   -- press or release, as the game is set
    b:SetAttribute("type", "item")
    S.Solid(b, "BACKGROUND", C.bg, 1):SetAllPoints()
    S.Solid(b, "BACKGROUND", C.btnFill):SetAllPoints()
    local edge = S.Border(b, C.btnEdge)
    local hl = S.Solid(b, "BORDER", C.hoverFill); hl:SetAllPoints(); hl:SetAlpha(0)
    local press = S.Solid(b, "BORDER", C.pressFill); press:SetAllPoints(); press:Hide()
    b.label = S.Text(b, F.label, C.fg)
    b.label:SetWordWrap(false)
    b.label:SetPoint("CENTER", 11, 0)
    b.label:SetText(L("Ouvrir l'enveloppe"))
    local ic = S.Icon(b, "mail", 16, "ARTWORK", C.fg)
    ic:SetPoint("RIGHT", b.label, "LEFT", -6, 0)
    b:HookScript("OnEnter", function(self)
        hl:SetAlpha(1); edge(C.btnEdgeHover)
        S.Tip(self, { L("Ouvrir l'enveloppe"), L("Clic : ouvrir l'enveloppe et prendre la quête") })
    end)
    b:HookScript("OnLeave", function() hl:SetAlpha(0); edge(C.btnEdge); S.HideTip() end)
    b:HookScript("OnMouseDown", function() press:Show(); b.label:SetPoint("CENTER", 11, -1) end)
    b:HookScript("OnMouseUp", function() press:Hide(); b.label:SetPoint("CENTER", 11, 0) end)
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
            local rt, rb, rl = row:GetTop(), row:GetBottom(), row:GetLeft()
            if row:IsVisible() and row.envItem and rt and rb and rl and rb >= bottom - 1 and rt <= top + 1 then
                n = n + 1
                local b = EnvelopeButton(n)
                b:SetScale(ratio)
                b:SetFrameStrata(frame:GetFrameStrata())
                b:SetFrameLevel(frame:GetFrameLevel() + 50)
                b:SetAttribute("item", "item:" .. row.envItem)
                b:ClearAllPoints()
                b:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", rl + 64, rt - (row.btnY or 8))
                b:Show()
            end
        end
    end
    for i = n + 1, #envelopes do envelopes[i]:Hide() end
end

-- A writ row inside a zone card: status icon (HD), the item's painted icon, its name and one detail
-- line (both wrap to two lines), and room on the right for the envelope button.
local function MakeWritRow(parent)
    local r = CreateFrame("Button", nil, parent)
    r.wlOwned = true
    r.rule = S.Rule(r); r.rule:SetPoint("TOPLEFT"); r.rule:SetPoint("TOPRIGHT")
    r.hl = S.Solid(r, "BACKGROUND", C.hoverFill); r.hl:SetAllPoints(); r.hl:SetAlpha(0)
    r.press = S.Solid(r, "BORDER", C.pressFill); r.press:SetAllPoints(); r.press:Hide()
    r.status = r:CreateTexture(nil, "ARTWORK")
    r.status:SetSize(16, 16); r.status:SetPoint("TOPLEFT", 12, -10)
    local holder = CreateFrame("Frame", nil, r)
    holder:SetSize(20, 20); holder:SetPoint("TOPLEFT", 36, -8)
    r.icon = holder:CreateTexture(nil, "ARTWORK"); r.icon:SetAllPoints()
    S.Border(holder, C.cardEdge)
    r.name = S.Text(r, F.label, C.fg)
    r.name:SetPoint("TOPLEFT", 64, -8)
    r.detail = S.Text(r, F.meta, C.muted)
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
    r:SetScript("OnEnter", function(self)
        root.Tween(self, self.hov or 0, 1, 0.10, function(v) self.hov = v; self.hl:SetAlpha(v) end)
        if self.tip then S.Tip(self, self.tip) end
    end)
    r:SetScript("OnLeave", function(self)
        root.Tween(self, self.hov or 0, 0, 0.10, function(v) self.hov = v; self.hl:SetAlpha(v) end)
        S.HideTip()
    end)
    r:SetScript("OnMouseDown", function(self) self.press:Show() end)
    r:SetScript("OnMouseUp", function(self) self.press:Hide() end)
    -- An envelope row puts its secure "Ouvrir l'enveloppe" button on its own line under the detail
    -- (row.btnY from the row's top), so the name and the detail keep the full text column.
    function r:Fit(width)
        local textW = math.max(60, width - 64 - 12)
        self.name:SetWidth(textW); S.FitText(self.name, 2, textW, self)
        local h = 8 + Height(self.name, F.label + 2)
        self.detail:ClearAllPoints(); self.detail:SetPoint("TOPLEFT", self.name, "BOTTOMLEFT", 0, -3)
        S.FitText(self.detail, 2, textW, self)
        h = h + 3 + Height(self.detail, F.meta + 2)
        if self.envItem then
            self.btnY = math.ceil(h + 6)
            h = self.btnY + ENV_H + 8
        else
            self.btnY = nil
            h = h + 8
        end
        h = math.max(36, math.ceil(h))
        self:SetHeight(h)
        return h
    end
    return r
end

local function MakeZoneCard(parent)
    local c = CreateFrame("Frame", nil, parent)
    c.wlOwned = true
    c:SetWidth(LIST_W)
    S.Solid(c, "BACKGROUND", C.cardFill):SetAllPoints()
    S.Border(c, C.cardEdge)
    c.name = S.Text(c, F.heading, C.fg)
    c.name:SetPoint("TOPLEFT", 12, -15)
    c.level = S.Pill(c)
    c.level:SetPoint("LEFT", c.name, "RIGHT", 8, 0)
    c.go = S.Button(c, L("Y aller"), 0, 24, "secondary", function() if c.first then WP.TravelTo(c.first) end end,
        function() return { L("Y aller"), L("Clic : guider vers le premier writ de la zone") } end)
    c.go:SetIcon("flag")
    c.go:SetPoint("TOPRIGHT", -12, -10)
    c.eta = S.Text(c, F.meta, C.muted)
    c.eta:SetWordWrap(false)
    c.eta:SetPoint("RIGHT", c.go, "LEFT", -8, 0)
    c.rows = Pool(function() return MakeWritRow(c) end)
    return c
end

local function BuildToday(p)
    today.page = p
    today.goal = S.Text(p, F.heading, C.fg)
    today.goal:SetPoint("TOPLEFT", INSET, -12)
    S.ClampLabel(today.goal, nil, p)
    today.standing = S.Text(p, F.meta, C.muted)
    today.standing:SetWordWrap(false)
    today.standing:SetJustifyH("RIGHT")
    today.standing:SetPoint("TOPRIGHT", -INSET, -14)
    local bar = CreateFrame("Frame", nil, p)
    bar:SetHeight(4)
    S.Solid(bar, "BACKGROUND", C.divider):SetAllPoints()
    today.barFill = S.Solid(bar, "ARTWORK", C.accent)
    today.barFill:SetPoint("TOPLEFT"); today.barFill:SetPoint("BOTTOMLEFT")
    today.barPending = S.Solid(bar, "ARTWORK", C.accent, 0.40)
    today.barPending:SetPoint("TOPLEFT", today.barFill, "TOPRIGHT"); today.barPending:SetPoint("BOTTOMLEFT", today.barFill, "BOTTOMRIGHT")
    today.bar = bar
    today.message = S.Text(p, F.body, C.text)
    today.message:SetJustifyH("LEFT"); today.message:SetJustifyV("TOP")
    today.reset = S.Text(p, F.meta, C.muted)
    today.reset:SetJustifyH("LEFT")

    local sc = p.sa
    sc:HookScript("OnVerticalScroll", PlaceEnvelopes)
    today.scroll = sc
    today.head = S.SectionHeader(sc.child, L("À rendre maintenant"))
    today.head:SetPoint("TOPLEFT", 0, 0); today.head:SetPoint("TOPRIGHT", 0, 0)
    today.cards = Pool(function() return MakeZoneCard(sc.child) end)
    today.later = S.Button(sc.child, "", 0, 24, "ghost", function()
        if WP.OpenAllFold then WP.OpenAllFold("later") end
        WP.ShowTab("all")
    end, function() return { today.later.wlText or "", L("Zones trop hautes pour ton niveau."), L("Clic : voir ces writs") } end)
    today.later:SetChevron(true)
    today.empty = S.EmptyState(sc.child, "mail", "", nil)
    today.empty:Hide()

    today.tour = S.Button(p, L("Lancer la tournée GPS"), LIST_W - 28 - 8, 32, "primary", function()
        if today.tour.action == "gps" then WP.ToggleGPS() elseif today.tour.action == "shop" then WP.ShowTab("shop") end
    end)
    today.tour:SetPoint("BOTTOMLEFT", INSET, 12)
    today.scan = ScanButton(p, function() return WP.ShoppingIDs() end)
    today.scan:SetPoint("BOTTOMRIGHT", -INSET + 2, 14)
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

-- Writs left out of the plan only because they cost more than the price cap.
local function CappedCount()
    local capped, cap = 0, WLWritsDB.maxPer100 or 0
    if cap <= 0 then return 0 end
    for _, r in ipairs(data) do
        if r.show and r.state == "buy" and r.per100 and r.w.map and not r.tooHigh and not r.skipped
            and r.per100 > cap then capped = capped + 1 end
    end
    return capped
end

-- The big button does the next useful thing: stop the tour, start it when there is something to
-- turn in, else buy the plan, else buy the items still missing.
local function TourAction()
    if WLWritsCharDB.gps then return "gps", L("Arrêter la tournée GPS"), true, "close" end
    local ready, bagOwned, missing = 0, 0, 0
    for _, r in ipairs(data) do
        if r.w.map and not r.tooHigh then
            if r.state == "ready" then ready = ready + 1
            elseif r.state == "bag" and r.ownItem then bagOwned = bagOwned + 1
            elseif r.state == "log" or r.state == "bag" then missing = missing + 1 end
        end
    end
    if ready + bagOwned > 0 then return "gps", string.format(L("Lancer la tournée GPS (%d à rendre)"), ready + bagOwned), true, "flag" end
    if #plan > 0 or missing > 0 then return "shop", L("Voir les achats"), true, "coin" end
    return nil
end

-- With nothing to do, the bottom row keeps only the scan icon: no disabled status button.
local function PaintTour()
    local a, txt, on, icon = TourAction()
    today.tour.action = a
    today.tour:SetShown(a ~= nil)
    if not a then return end
    today.tour:SetIcon(icon)
    today.tour:SetText(txt)
    if on then today.tour:Enable() else today.tour:Disable() end
end

local function RenderToday()
    local p = today.page
    local name, reaction, inStanding, size = WP.Reputation()
    local y = 12
    -- the goal line, the bar, one sentence, the reset
    if not name then
        today.goal:SetText(L("Réputation introuvable"))
        today.standing:SetText("")
        today.message:SetText(L("Ouvre ta fenêtre de personnage, onglet Réputation, une fois : WL Helper la lira ensuite."))
        today.bar:Hide()
    else
        today.bar:Show()
        local _, goal = WP.RepNeeded()
        local frac = (size and size > 0) and (inStanding / size) or 0
        local pend = (size and size > 0) and math.min(1 - frac, pending / size) or 0
        today.barFill:SetWidth(math.max(0.01, LIST_W * frac))
        today.barPending:SetWidth(math.max(0.01, LIST_W * pend))
        today.standing:SetText(string.format("%s / %s", Big(inStanding or 0), Big(size or 0)))
        if not need or need <= 0 then
            today.goal:SetText(string.format(L("%s atteint"), WP.Reaction(goal or reaction)))
            today.message:SetText(L("Objectif atteint. Pour continuer, choisis un rang plus haut dans les réglages des Writs."))
        else
            today.goal:SetText(string.format(L("%s dans %s points"), WP.Reaction(goal), Big(need)))
            local ready = 0
            for _, r in ipairs(data) do if r.state == "ready" and r.w.map and not r.tooHigh then ready = ready + 1 end end
            if pending >= need and ready > 0 then
                today.message:SetText(ready == 1 and L("Rends ton writ prêt et c'est bon.") or string.format(L("Rends tes %d writs prêts et c'est bon."), ready))
            elseif #plan > 0 and ready > 0 then
                if ready == 1 then
                    today.message:SetText(string.format(L("Rends ton writ prêt, puis achètes-en %d de plus."), #plan))
                else
                    today.message:SetText(string.format(L("Rends tes writs prêts, puis achètes-en %d de plus."), #plan))
                end
            elseif #plan > 0 then
                local cost = 0
                for _, r in ipairs(plan) do cost = cost + (r.cost or 0) end
                if cost <= 0 then
                    today.message:SetText(#plan == 1 and L("Il te faut encore 1 writ.") or string.format(L("Il te faut encore %d writs."), #plan))
                elseif #plan == 1 then
                    today.message:SetText(string.format(L("Il te faut encore 1 writ, pour environ %s."), S.Money(cost)))
                else
                    today.message:SetText(string.format(L("Il te faut encore %d writs, pour environ %s."), #plan, S.Money(cost)))
                end
            else
                -- nothing planned: say so when the price cap is what keeps writs out
                local capped = CappedCount()
                if capped == 1 then
                    today.message:SetText(L("1 writ dépasse ton prix max : monte-le dans l'onglet Achats."))
                elseif capped > 1 then
                    today.message:SetText(string.format(L("%d writs dépassent ton prix max : monte-le dans l'onglet Achats."), capped))
                else
                    today.message:SetText(L("Aucun writ abordable aujourd'hui : les offres changent demain."))
                end
            end
        end
    end
    local standW = Width(today.standing)
    today.goal:SetWidth(math.max(60, LIST_W - (standW > 0 and (standW + 12) or 0)))
    y = y + Height(today.goal, F.heading + 2)
    if today.bar:IsShown() then
        y = y + 8
        today.bar:ClearAllPoints()
        today.bar:SetPoint("TOPLEFT", INSET, -y); today.bar:SetPoint("TOPRIGHT", -INSET, -y)
        y = y + 4
    end
    y = y + 8
    today.message:ClearAllPoints(); today.message:SetPoint("TOPLEFT", INSET, -y)
    y = y + math.max(S.FitText(today.message, 3, LIST_W, p), F.body + 2)
    local secs = WP.SecondsToReset()
    if secs < 3600 then
        today.reset:SetText(string.format(L("Nouveaux writs dans %d min"), math.max(1, math.floor(secs / 60))))
    else
        today.reset:SetText(string.format(L("Nouveaux writs dans %d h"), math.floor(secs / 3600)))
    end
    y = y + 4
    today.reset:ClearAllPoints(); today.reset:SetPoint("TOPLEFT", INSET, -y)
    y = y + math.max(S.FitText(today.reset, 1, LIST_W, p), F.meta + 2)
    local topH = y - 12

    -- Cards: writs you hold, by zone, biggest first.
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
    local ly = 0
    local held = 0
    for _, z in ipairs(order) do held = held + #z.rows end
    today.head:SetShown(#order > 0)
    if #order > 0 then
        today.head:Set(L("À rendre maintenant"), held)
        ly = 32 + 8
    end
    local minutes = MinutesTo(order)
    for i, z in ipairs(order) do
        local c = today.cards.Get(i)
        c:ClearAllPoints(); c:SetPoint("TOPLEFT", 0, -ly); c:SetPoint("TOPRIGHT", 0, -ly)
        c.name:SetText(z.name)
        local lo = WP.ZoneMin(z.map)
        if lo then c.level:Set(lo .. "-" .. (lo + 10), S.LevelColor(lo + 5)) else c.level:Hide() end
        c.first = z.rows[1].w
        local mins = minutes[i]
        c.eta:SetText(mins and string.format(L("~%d min"), mins) or "")
        -- a long zone name stops before the level pill, "~N min" and the button (full name in the tooltip)
        local room = LIST_W - 12 - 12 - (num(c.go:GetWidth()) or 90) - 8 - Width(c.eta) - 8
            - (c.level:IsShown() and ((num(c.level:GetWidth()) or 40) + 8) or 0)
        -- a long zone name wraps to two lines (never cut) and pushes the rows down
        local nameH = S.FitText(c.name, 2, math.max(40, room), c)
        if Width(c.name) + 2 < room then c.name:SetWidth(Width(c.name) + 2) end
        local ry = 15 + math.max(nameH, F.heading + 2) + 13
        for j, r in ipairs(z.rows) do
            local row = c.rows.Get(j)
            row:ClearAllPoints(); row:SetPoint("TOPLEFT", 0, -ry); row:SetPoint("TOPRIGHT", 0, -ry)
            local w = r.w
            row.writ = w
            row.r = r
            S.Painted(row.icon, S.ItemIcon(w.item))
            row.name:SetText(WP.ItemName(w.item, w.itemName) .. ((w.count or 1) > 1 and (" x" .. w.count) or ""))
            SetColor(row.name, S.QualityColor(w.item))
            row.envItem = nil
            if r.state == "ready" then
                S.HDIcon(row.status, "check", C.ok)
                row.detail:SetText(w.npcName and string.format(L("Prêt à rendre à %s"), w.npcName) or string.format(L("Prêt à rendre, %.0f, %.0f"), w.x, w.y))
                SetColor(row.detail, C.muted)
            elseif r.state == "bag" then
                S.HDIcon(row.status, "mail", r.ownItem and C.muted or C.warn)
                row.envItem = w.writ   -- PlaceEnvelopes lays the secure button over this row
                row.detail:SetText(r.ownItem and L("Dans le sac") or L("Dans le sac, mais l'objet manque"))
                SetColor(row.detail, r.ownItem and C.muted or C.warn)
            else
                S.HDIcon(row.status, "warning", C.warn)
                local missingN = math.max(1, (w.count or 1) - (r.haveItems or 0))
                row.detail:SetText(r.itemPrice and string.format(L("En cours : objet manquant, %s à l'HV"), S.Money(r.itemPrice * missingN)) or L("En cours : objet manquant"))
                SetColor(row.detail, C.warn)
            end
            row.tip = { WP.ItemName(w.writ, w.writName), string.format(L("%d points de réputation · %s %.0f, %.0f"), w.rep, z.name, w.x, w.y),
                w.npcName and string.format(L("À rendre à %s"), w.npcName) or L("Lieu de remise sur la carte") }
            if r.state == "bag" and not r.ownItem then
                row.tip[#row.tip + 1] = { L("Objet manquant : achète-le avant d'y aller."), C.warn[1], C.warn[2], C.warn[3] }
            end
            if r.state == "log" then
                row.tip[#row.tip + 1] = WP.AuctionHouseOpen() and L("Clic : acheter l'objet") or L("Clic : voir l'onglet Achats")
            else
                row.tip[#row.tip + 1] = string.format(L("Clic : guider vers %s"), w.npcName or z.name)
            end
            ry = ry + row:Fit(LIST_W)
        end
        c.rows.HideFrom(#z.rows + 1)
        c:SetHeight(ry + 2)
        ly = ly + ry + 2 + 12
    end
    today.cards.HideFrom(#order + 1)
    today.empty:SetShown(#order == 0)
    if #order == 0 then
        local done = 0
        for _, r in ipairs(data) do if r.state == "done" then done = done + 1 end end
        local capped = (#plan == 0) and CappedCount() or 0
        today.empty:SetWrapWidth(LIST_W)
        today.empty:ClearAllPoints(); today.empty:SetPoint("TOP", today.scroll.child, "TOP", 0, -12)
        local eh
        if done > 0 and #plan == 0 then
            eh = today.empty:Set("check", L("Tout est rendu pour aujourd'hui"), L("De nouveaux writs arrivent à la réinitialisation quotidienne."))
        elseif capped > 0 then
            eh = today.empty:Set("coin", L("Aucun writ sous ton prix max"), L("Monte le prix max dans l'onglet Achats pour en voir plus."))
        else
            eh = today.empty:Set("mail", L("Aucun writ en main"), L("Les writs que tu achètes et ouvres apparaîtront ici, groupés par zone."))
        end
        ly = 12 + eh + 12
    elseif ly > 0 then
        ly = ly - 12
    end
    today.later:SetShown(later > 0)
    if later > 0 then
        today.later.wlText = later == 1 and L("1 writ pour plus tard") or string.format(L("%d writs pour plus tard"), later)
        today.later:SetText(later == 1 and L("1 writ pour plus tard") or string.format(L("%d writs pour plus tard"), later))
        ly = ly + 8
        today.later:ClearAllPoints(); today.later:SetPoint("TOPLEFT", 0, -ly)
        ly = ly + 24
    end

    PaintTour()
    today.scan:Update()
    p:Fit(topH, ly, 32)
end

-- ---------------------------------------------------------------- Achats

local buy = {}

local function ShopIDs()
    local ids = {}
    for _, e in ipairs(shop) do if not e.done then ids[#ids + 1] = e.id end end
    return ids
end

local function BuildShop(p)
    buy.page = p
    buy.total = S.Text(p, F.hero, C.fg)
    buy.total:SetPoint("TOPLEFT", INSET, -12)
    S.ClampLabel(buy.total, nil, p)
    buy.sub = S.Text(p, F.body, C.text)
    buy.sub:SetJustifyH("LEFT"); buy.sub:SetJustifyV("TOP")
    -- the price cap: writs costing more than this per 100 reputation points are left out of the plan
    -- (net of the Coin Pouch they give back); the route then groups what is left by turn-in zone
    buy.capLabel = S.Text(p, F.meta, C.muted)
    buy.capLabel:SetText(L("Prix max pour 100 points"))
    buy.capLabel:SetWordWrap(false)
    buy.cap = S.Segmented(p, { { 2000, string.format(L("%d pa"), 20) }, { 4000, string.format(L("%d pa"), 40) }, { 10000, string.format(L("%d po"), 1) }, { 0, L("Sans") } },
        function() return WLWritsDB.maxPer100 or 4000 end,
        function(v) WLWritsDB.maxPer100 = v; WP.Refresh() end, 28)
    -- zone filter: every zone, or a single one
    buy.zoneLabel = S.Text(p, F.meta, C.muted)
    buy.zoneLabel:SetText(L("Zone"))
    buy.zoneLabel:SetWordWrap(false)
    buy.zone = S.Dropdown(p, { { false, L("Toutes les zones") } },
        function() return WLWritsCharDB.shopZone or false end,
        function(v) WLWritsCharDB.shopZone = v or nil; WP.Refresh() end, 140)
    buy.zoneLabel:SetPoint("BOTTOMLEFT", buy.zone, "TOPLEFT", 0, 4)
    buy.absent = S.Banner(p, "warn", "")
    buy.absent:Hide()

    local sc = p.sa
    -- zone heads: fold chevron, the turn-in zone's name, the count and cost, and a ghost link at the right
    -- to leave the zone out of the plan (one list with the settings: WLWritsCharDB.skip.zones)
    buy.heads = Pool(function()
        local h = FoldHead(sc.child, function(self)
            WLWritsCharDB.shopFold = WLWritsCharDB.shopFold or {}
            WLWritsCharDB.shopFold[self.foldKey] = not WLWritsCharDB.shopFold[self.foldKey] or nil
            WP.Refresh()
        end, L("Exclure"), function(self) if self.map then WP.SetSkipped("zones", self.map, true) end end)
        h.linkTip = { L("Exclure"), L("Laisser cette zone de côté : le plan prend d'autres writs, ailleurs."), L("Clic : laisser la zone de côté") }
        return h
    end)
    buy.outHead = S.SectionHeader(sc.child, L("Zones laissées de côté"))
    buy.outHead:Hide()
    buy.outRows = Pool(function()
        local r = S.ListRow(sc.child, { density = "dense" })
        r:AddAction("plus", { L("Remettre"), L("Clic : remettre la zone dans le plan") },
            function() if r.map then WP.SetSkipped("zones", r.map, false) end end)
        r.tip = function(self) return { WP.ZoneName(self.map), L("Hors du plan"), L("Clic : remettre la zone dans le plan") } end
        r:SetScript("OnClick", function(self) if self.map then WP.SetSkipped("zones", self.map, false) end end)
        return r
    end)
    buy.rows = Pool(function()
        local r = S.ListRow(sc.child, { density = "dense", onClick = function(self)
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
        end })
        r.valueW = 110
        r.tip = function(self)
            local e = self.entry
            if not e then return nil end
            local lines = { self.title or e.name }
            for _, x in ipairs(self.entries or { e }) do
                local left = math.max(0, x.need - x.have)
                local price = x.done and L("Dans le sac") or (x.src == "Absent" and L("Pas en vente à l'HV"))
                    or (x.price and (S.Money(x.price * left) .. (left > 1 and (" (" .. left .. " x " .. S.Money(x.price) .. ")") or "")) or "?")
                lines[#lines + 1] = { (x.isWrit and L("Enveloppe") or x.name) .. " : " .. price, C.fg[1], C.fg[2], C.fg[3] }
                local sub = string.format(L("Dans tes sacs : %d sur %d"), x.have, x.need)
                if x.listed then sub = sub .. " · " .. string.format(L("En vente au dernier scan : %d"), x.listed) end
                lines[#lines + 1] = sub
            end
            lines[#lines + 1] = (self.entries and #self.entries > 1) and L("Clic : acheter l'enveloppe et l'objet") or L("Clic : acheter l'objet")
            lines[#lines + 1] = L("Maj-clic : chercher à l'HV")
            return lines
        end
        return r
    end)
    buy.empty = S.EmptyState(sc.child, "check", L("Rien à acheter"), L("Tes writs suffisent pour ton objectif du jour."))
    buy.empty:Hide()

    -- one primary button opens every buy page in a row; the player still clicks the game's own Buy
    -- button each time (the addon buys nothing by itself)
    buy.all = S.Button(p, "", LIST_W - 28 - 8, 32, "primary", function()
        local pos = WP.Scan.QueueState()
        if (pos or 0) > 0 or WP.Scan.QueueLeft() > 0 then WP.Scan.ClearQueue(); return end
        local list = {}
        for _, e in ipairs(buy.order or {}) do
            if not e.done and e.src ~= "Absent" then list[#list + 1] = { id = e.id, qty = math.max(1, e.need - e.have) } end
        end
        if #list > 0 then WP.Scan.BuyQueue(list) end
    end, function()
        local pos = WP.Scan.QueueState()
        if (pos or 0) > 0 then return { buy.all:GetText(), L("Clic : arrêter la suite d'achats") } end
        if buy.all:IsEnabled() == false then return nil end
        return { buy.all:GetText(), L("Ouvre chaque page d'achat à la suite : tu cliques sur Acheter à chaque fois."), L("Clic : ouvrir la première page d'achat") }
    end)
    buy.all:SetIcon("coin")
    buy.all:SetPoint("BOTTOMLEFT", INSET, 12)
    buy.rescan = ScanButton(p, ShopIDs)
    buy.rescan:SetPoint("BOTTOMRIGHT", -INSET + 2, 14)
end

local function RenderShop()
    local p = buy.page
    local left, rep = 0, 0
    for _, e in ipairs(shop) do if not e.done then left = left + 1 end end
    for _, r in ipairs(plan) do rep = rep + r.w.rep end
    local y = 12
    -- the cost (gold, the view's one hero number) and what it buys
    buy.total:SetShown(left > 0)
    buy.sub:SetShown(left > 0)
    if left > 0 then
        buy.total:SetText(S.Money(shopTotal))
        buy.total:SetWidth(LIST_W)
        y = y + Height(buy.total, F.hero + 2)
        buy.sub:SetText(#plan == 1 and string.format(L("Pour 1 writ, qui rapporte %d points de réputation."), rep)
            or string.format(L("Pour %d writs, qui rapportent %d points de réputation."), #plan, rep))
        y = y + 4
        buy.sub:ClearAllPoints(); buy.sub:SetPoint("TOPLEFT", INSET, -y)
        y = y + math.max(S.FitText(buy.sub, 2, LIST_W, p), F.body + 2)
        y = y + 12
    end
    -- the two controls side by side, each with its label above
    buy.capLabel:ClearAllPoints(); buy.capLabel:SetPoint("TOPLEFT", INSET, -y)

    y = y + F.meta + 2 + 4

    -- groups: one per turn-in zone, in the order the list gives
    local groups, order = {}, {}
    for _, e in ipairs(shop) do
        local key = e.zone or "?"
        if not groups[key] then groups[key] = {}; order[#order + 1] = key end
        table.insert(groups[key], e)
    end
    local only = WLWritsCharDB.shopZone
    if only and not groups[only] then only = nil; WLWritsCharDB.shopZone = nil end
    local opts = { { false, L("Toutes les zones") } }
    for _, k in ipairs(order) do opts[#opts + 1] = { k, k } end
    buy.zone.options = opts
    buy.zone:Update()
    -- the zone menu grows with the zone's name: the price choice takes what is left (it becomes a
    -- menu itself rather than cutting its labels)
    local zoneW = num(buy.zone:GetWidth()) or 140
    buy.zone:ClearAllPoints(); buy.zone:SetPoint("TOPRIGHT", -INSET, -y)
    buy.cap:ClearAllPoints(); buy.cap:SetPoint("TOPLEFT", INSET, -y)
    buy.cap:SetMaxWidth(LIST_W - zoneW - 12)
    buy.cap:Update()
    y = y + 28

    -- items the last scan found nowhere: said once, above the list
    local absent = 0
    for _, e in ipairs(shop) do if not e.done and e.src == "Absent" then absent = absent + 1 end end
    buy.absent:SetShown(absent > 0)
    if absent > 0 then
        buy.absent:SetText(absent == 1 and L("1 objet n'est pas en vente à l'HV : scanne à nouveau plus tard ou laisse sa zone de côté.")
            or string.format(L("%d objets ne sont pas en vente à l'HV : scanne à nouveau plus tard ou laisse leur zone de côté."), absent), "warn")
        y = y + 12
        buy.absent:ClearAllPoints()
        buy.absent:SetPoint("TOPLEFT", INSET, -y); buy.absent:SetPoint("TOPRIGHT", -INSET, -y)
        y = y + buy.absent:Fit(LIST_W)
    end
    local topH = y - 12

    local ly, hi, ri = 0, 0, 0
    buy.order = {}   -- the entries as shown, for the buying run
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
        hi = hi + 1
        local h = buy.heads.Get(hi)
        h.map = groups[key][1] and groups[key][1].map
        h.foldKey = key
        if h.link then h.link:SetShown(h.map ~= nil) end
        h:Set(key, (writs == 1 and L("1 writ") or string.format(L("%d writs"), writs)) .. " · " .. S.Money(zoneCost), true, folded)
        if ly > 0 then ly = ly + 8 end
        h:ClearAllPoints(); h:SetPoint("TOPLEFT", 0, -ly); h:SetPoint("TOPRIGHT", 0, -ly)
        ly = ly + 32 + 4
        if not folded then
          for _, c in ipairs(cards) do
            ri = ri + 1
            local r = buy.rows.Get(ri)
            local main = c.writ or c.item
            r.entry, r.entries = main, c.entries
            -- "Envelope: Craftsman's Writ: Iridescent Hammer" reads "Iridescent Hammer"; the item's count follows
            local short = c.writ and (c.writ.name:match(".*:%s*(.+)$") or c.writ.name) or main.name
            local n = c.item and c.item.need or 1
            r.title = short .. (n > 1 and (" x" .. n) or "")
            local detail, value, vcol = c.writ and L("Enveloppe et objet") or L("Objet seul"), nil, C.fg
            if c.done then
                detail, vcol = L("Dans le sac"), C.muted
            elseif c.absent then
                detail, value, vcol = L("Pas en vente à l'HV"), "", C.bad
            elseif c.unknown and c.cost == 0 then value = "?"
            else
                value = S.Money(c.cost)
                if c.short then detail = L("Peu en vente : pas assez pour tout"); vcol = C.warn end
            end
            r:Set({ icon = S.ItemIcon(main.id), name = r.title, nameColor = c.item and S.QualityColor(c.item.id) or C.fg,
                detail = detail, value = value })
            SetColor(r.value, vcol)
            if c.absent then SetColor(r.detail, C.bad) elseif c.short then SetColor(r.detail, C.warn) else SetColor(r.detail, C.muted) end
            r:SetAlpha(c.done and 0.5 or 1)
            r:ClearAllPoints(); r:SetPoint("TOPLEFT", 0, -ly); r:SetPoint("TOPRIGHT", 0, -ly)
            ly = ly + r:Fit(LIST_W) + 2
          end
        end
      end
    end
    buy.heads.HideFrom(hi + 1)
    buy.rows.HideFrom(ri + 1)
    -- the zones left out, to bring back
    local out = {}
    for map in pairs((WLWritsCharDB.skip and WLWritsCharDB.skip.zones) or {}) do out[#out + 1] = map end
    table.sort(out, function(a, b) return WP.ZoneName(a) < WP.ZoneName(b) end)
    buy.outHead:SetShown(#out > 0)
    if #out > 0 then
        if ly > 0 then ly = ly + 16 end
        buy.outHead:ClearAllPoints(); buy.outHead:SetPoint("TOPLEFT", 0, -ly); buy.outHead:SetPoint("TOPRIGHT", 0, -ly)
        buy.outHead:Set(L("Zones laissées de côté"), #out)
        ly = ly + 32 + 4
        for i, map in ipairs(out) do
            local r = buy.outRows.Get(i)
            r.map = map
            r:Set({ hd = "minus", name = WP.ZoneName(map), detail = L("Hors du plan") })
            r:ClearAllPoints(); r:SetPoint("TOPLEFT", 0, -ly); r:SetPoint("TOPRIGHT", 0, -ly)
            ly = ly + r:Fit(LIST_W) + 2
        end
    end
    buy.outRows.HideFrom(#out + 1)
    buy.empty:SetShown(#shop == 0)
    if #shop == 0 then
        buy.empty:SetWrapWidth(LIST_W)
        buy.empty:ClearAllPoints(); buy.empty:SetPoint("TOP", p.sa.child, "TOP", 0, -12)
        -- say why the list is empty: the goal is covered, the price cap leaves nothing, or no offer
        local capped = CappedCount()
        local eh
        if need and need > 0 and capped > 0 then
            eh = buy.empty:Set("coin", L("Aucun writ sous ton prix max"), L("Monte le prix max ci-dessus pour en voir plus."))
        elseif need and need > 0 and #plan == 0 then
            eh = buy.empty:Set("mail", L("Rien à acheter"), L("Aucun writ n'est en vente pour ton objectif : scanne l'HV à nouveau plus tard."))
        else
            eh = buy.empty:Set("check", L("Rien à acheter"), L("Tes writs suffisent pour ton objectif du jour."))
        end
        ly = ly + 12 + eh + 12
    elseif ly > 0 then
        ly = ly - 2
    end

    buy.rescan:Update()
    local n = 0
    for _, e in ipairs(buy.order) do if not e.done and e.src ~= "Absent" then n = n + 1 end end
    local pos, total = WP.Scan.QueueState()
    -- nothing left to buy: the empty state or the greyed rows say it, no "0 objects" button
    buy.all:SetShown((pos or 0) > 0 or n > 0)
    if (pos or 0) > 0 then
        buy.all:SetText(string.format(L("Arrêter les achats (%d sur %d)"), pos, total)); buy.all:SetIcon("close"); buy.all:Enable()
    elseif n > 0 then
        buy.all:SetText(n == 1 and L("Acheter l'objet") or string.format(L("Acheter les %d objets"), n))
        buy.all:SetIcon("coin")
        if not WP.AuctionHouseOpen() then
            buy.all:SetDisabledReason(L("L'hôtel des ventes est fermé.")); buy.all:Disable()
        else
            buy.all:Enable()
        end
    end
    p:Fit(topH, ly, 32)
end

-- ---------------------------------------------------------------- Tous les writs

local all = { search = "", rank = "all", open = {} }
-- Opens a fold of the "Tous les writs" tab (the Today tab's "for later" link opens "later").
function WP.OpenAllFold(key) all.open[key] = true end

-- A writ row with its tick box (your own list of writs to do).
local function MakeAllRow(parent)
    local r = S.ListRow(parent, { density = "dense" })
    r.valueW = 96
    r.box = CreateFrame("Button", nil, r)
    r.box:SetSize(24, 24); r.box:SetPoint("TOPLEFT", 4, -4)
    r.box.frame = CreateFrame("Frame", nil, r.box)
    r.box.frame:SetSize(16, 16); r.box.frame:SetPoint("CENTER")
    r.box.fill = S.Solid(r.box.frame, "BACKGROUND", C.accent); r.box.fill:SetAllPoints(); r.box.fill:SetAlpha(0)
    r.box.border = S.Border(r.box.frame, C.btnEdge)
    r.box.check = S.Icon(r.box.frame, "check", 14, "ARTWORK", C.fg)
    r.box.check:SetPoint("CENTER")
    r.box:SetScript("OnClick", function(self)
        local x = self:GetParent().row
        if x and x.state ~= "done" then WP.SetPicked(x.w, not WP.IsPicked(x.w)) end
    end)
    r.box:SetScript("OnEnter", function(self)
        local x = self:GetParent().row
        if not x then return end
        self.border(C.btnEdgeHover)
        S.Tip(self, { WP.ItemName(x.w.item, x.w.itemName), WP.IsPicked(x.w) and L("Clic : le décocher") or L("Clic : le cocher pour ton plan") })
    end)
    r.box:SetScript("OnLeave", function(self)
        local x = self:GetParent().row
        local on = x and WP.IsPicked(x.w) and x.state ~= "done"
        self.border(on and C.accent or C.btnEdge)
        S.HideTip()
    end)
    r.box.border = r.box.border
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
    r.tip = function(self)
        local x = self.row
        if not x then return nil end
        local w = x.w
        local lines = { WP.ItemName(w.writ, w.writName),
            string.format(L("Enveloppe %s, objet %s, moins la bourse rendue (%s)"), x.ownWrit and L("possédée") or S.Money(x.writPrice),
                (x.ownItem or x.state == "ready") and L("possédé") or S.Money(x.itemPrice and x.itemPrice * (w.count or 1)), S.Money((WP.PouchValue(w.tier)))) }
        if w.npcName then lines[#lines + 1] = string.format(L("À rendre à %s"), w.npcName) end
        if Craftable(w.item) then lines[#lines + 1] = { L("Tu sais le fabriquer"), C.info[1], C.info[2], C.info[3] } end
        if w.map and WP.IsSkipped("zones", w.map) then
            lines[#lines + 1] = { L("Zone laissée de côté : remets-la depuis l'onglet Achats."), C.warn[1], C.warn[2], C.warn[3] }
        end
        lines[#lines + 1] = string.format(L("Clic : guider vers %s"), w.npcName or WP.ZoneName(w.map) or L("le PNJ"))
        lines[#lines + 1] = L("Maj-clic : chercher à l'HV")
        if not (w.map and WP.IsSkipped("zones", w.map)) then
            lines[#lines + 1] = WP.IsSkipped("writs", w.writ) and L("Clic droit : le remettre dans le plan") or L("Clic droit : ne pas le faire")
        end
        return lines
    end
    -- the box sits left of the painted icon: the row's own layout starts 28 px further right
    local fit = r.Fit
    function r:Fit(width)
        local h = fit(self, width)
        local dx = 28
        if self.icon:IsShown() then
            self.icon:ClearAllPoints(); self.icon:SetPoint("TOPLEFT", 8 + dx, -8)
        end
        local x = 8 + dx + (self.icon:IsShown() and ((num(self.icon:GetWidth()) or 20) + 8) or 0)
        self.name:ClearAllPoints(); self.name:SetPoint("TOPLEFT", x, -6)
        local nw = num(self.name:GetWidth())
        if nw then
            self.name:SetWidth(math.max(40, nw - dx))
            S.FitText(self.name, 2, math.max(40, nw - dx), self)
            S.FitText(self.detail, 2, math.max(40, nw - dx), self)
            local hh = 6 + Height(self.name, F.label + 2)
            if self.detail:IsShown() then hh = hh + 3 + Height(self.detail, F.meta + 2) end
            h = math.max(self.minH, math.ceil(hh + 8))
            self:SetHeight(h)
        end
        return h
    end
    return r
end

local function BuildAll(p)
    all.page = p
    all.box = S.Input(p, LIST_W, { search = true, placeholder = L("Ex. Potion, Tanaris"), onChange = function(t)
        all.search = (t or ""):lower()
        WP.RefreshSoon(0.2)
    end })
    all.box:SetPoint("TOPLEFT", INSET, -12)
    all.seg = S.Segmented(p, { { "all", L("Tous") }, { "Journeyman", WP.Tier("Journeyman") }, { "Expert", WP.Tier("Expert") }, { "Artisan", WP.Tier("Artisan") } },
        function() return all.rank end, function(v) all.rank = v; WP.Refresh() end, 28)
    all.seg:SetPoint("TOPLEFT", INSET, -(12 + 28 + 8))
    all.seg:SetMaxWidth(LIST_W)

    local sc = p.sa
    all.heads = Pool(function()
        local h = FoldHead(sc.child, function(self) all.open[self.key] = not all.open[self.key]; WP.Refresh() end)
        h.tipOpen, h.tipClose = L("Clic : afficher ces writs"), L("Clic : masquer ces writs")
        return h
    end)
    all.rows = Pool(function() return MakeAllRow(sc.child) end)
    all.empty = S.EmptyState(sc.child, "search", L("Aucun writ ne correspond"), L("Essaie un autre nom d'objet ou de zone."))
    all.empty:Hide()

    all.pickLine = S.Text(p, F.body, C.fg)
    all.pickLine:SetJustifyH("LEFT"); all.pickLine:SetJustifyV("TOP")
    all.pickSub = S.Text(p, F.meta, C.muted)
    all.pickSub:SetJustifyH("LEFT"); all.pickSub:SetJustifyV("TOP")
    all.clear = S.Button(p, L("Tout décocher"), 0, 28, "secondary", function() WP.ClearPicked() end)
end

local function Matches(r)
    if all.rank ~= "all" and r.w.tier ~= all.rank then return false end
    if all.search == "" then return true end
    local s = all.search
    local nm = WP.ItemName(r.w.item, r.w.itemName):lower()
    return nm:find(s, 1, true) or (r.zone or ""):lower():find(s, 1, true)
end

local function RenderAll()
    local p = all.page
    all.seg:Update()
    local topH = 28 + 8 + 28
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
    local function head(text, count, key)
        hi = hi + 1
        local h = all.heads.Get(hi)
        h.key = key
        if y > 0 then y = y + 8 end
        h:ClearAllPoints(); h:SetPoint("TOPLEFT", 0, -y); h:SetPoint("TOPRIGHT", 0, -y)
        h:Set(text, count, key ~= nil, key and not all.open[key])
        y = y + 32 + 4
    end
    local function row(r)
        ri = ri + 1
        local b = all.rows.Get(ri)
        b.row = r
        local on = WP.IsPicked(r.w) and r.state ~= "done"
        b.box:SetShown(r.state ~= "done")
        b.box.fill:SetAlpha(on and 1 or 0)
        b.box.border(on and C.accent or C.btnEdge)
        b.box.check:SetShown(on)
        local w = r.w
        local where = w.map and string.format("%s %.0f, %.0f", r.zone, w.x, w.y) or L("Lieu inconnu")
        if r.tooHigh and r.zoneMin then where = where .. string.format(L(", niv. %d+"), r.zoneMin) end
        local detail = string.format(L("%s · %s · %d points"), where, WP.Tier(w.tier), w.rep)
        if r.skipped then detail = S.Hex(C.warn) .. L("Mis de côté") .. "|r · " .. detail end
        local value, vcol = "?", C.muted
        if r.state == "done" then value, vcol = L("Rendu"), C.muted
        elseif r.state == "ready" then value, vcol = L("Prêt"), C.ok
        elseif r.net then
            local per = r.net
            value = per < 0 and ("+" .. S.Money(-per)) or S.Money(per)
            vcol = per < 0 and C.ok or C.fg
        end
        local name = WP.ItemName(w.item, w.itemName) .. ((w.count or 1) > 1 and (" x" .. w.count) or "")
        if Craftable(w.item) then name = name .. " " .. S.IconMarkup("hammer", 14, C.info) end
        b:Set({ icon = S.ItemIcon(w.item), name = name, nameColor = S.QualityColor(w.item), detail = detail, value = value })
        SetColor(b.value, vcol)
        b:SetAlpha((r.state == "done" or r.skipped) and 0.5 or 1)
        b:ClearAllPoints(); b:SetPoint("TOPLEFT", 0, -y); b:SetPoint("TOPRIGHT", 0, -y)
        y = y + b:Fit(LIST_W) + 2
    end
    if #todo > 0 then
        head(L("À faire, le moins cher d'abord"), #todo)
        for _, r in ipairs(todo) do row(r) end
    end
    if #later > 0 then
        head(L("Plus tard : zones trop hautes ou lieu inconnu"), #later, "later")
        if all.open.later then for _, r in ipairs(later) do row(r) end end
    end
    if #done > 0 then
        head(L("Rendus aujourd'hui"), #done, "done")
        if all.open.done then for _, r in ipairs(done) do row(r) end end
    end
    all.heads.HideFrom(hi + 1)
    all.rows.HideFrom(ri + 1)
    local none = #todo + #later + #done == 0
    all.empty:SetShown(none)
    if none then
        all.empty:SetWrapWidth(LIST_W)
        all.empty:ClearAllPoints(); all.empty:SetPoint("TOP", p.sa.child, "TOP", 0, -12)
        y = 12 + all.empty:Fit() + 12
    elseif y > 0 then
        y = y - 2
    end

    -- the bottom row: what you ticked, and a way to untick everything
    local n, cost, net, rep, unknown = WP.PickTotals(data)
    if n == 0 then
        all.pickLine:SetText(L("Coche les writs que tu veux faire"))
        all.pickSub:SetText(L("Sans coche, le plan prend les moins chers pour ton objectif."))
        all.clear:Hide()
    else
        all.pickLine:SetText(n == 1 and string.format(L("1 writ coché · %s · %d points"), S.Money(cost), rep)
            or string.format(L("%d writs cochés · %s · %d points"), n, S.Money(cost), rep))
        local sub = string.format(L("Soit %s une fois les bourses ouvertes."), S.Money(net)) .. " " .. L("L'onglet Achats suit tes coches.")
        if unknown == 1 then sub = sub .. " " .. L("1 writ n'a pas encore de prix.")
        elseif unknown > 1 then sub = sub .. " " .. string.format(L("%d writs n'ont pas encore de prix."), unknown) end
        all.pickSub:SetText(sub)
        all.clear:Show()
    end
    local textW = LIST_W - (all.clear:IsShown() and ((num(all.clear:GetWidth()) or 100) + 12) or 0)
    local lh = math.max(S.FitText(all.pickLine, 2, textW, p), F.body + 2)
    local sh = math.max(S.FitText(all.pickSub, 3, textW, p), F.meta + 2)
    local botH = math.max(lh + 3 + sh, 28)
    all.pickLine:ClearAllPoints(); all.pickLine:SetPoint("BOTTOMLEFT", INSET, 12 + botH - lh)
    all.pickSub:ClearAllPoints(); all.pickSub:SetPoint("TOPLEFT", all.pickLine, "BOTTOMLEFT", 0, -3)
    all.clear:ClearAllPoints(); all.clear:SetPoint("BOTTOMRIGHT", -INSET, 12 + math.floor((botH - 28) / 2))
    p:Fit(topH, y, botH)
end

-- ---------------------------------------------------------------- window

local current = "today"

local function PlacePages()
    local top = frame:ContentTop()
    for _, p in pairs(pages) do
        p:ClearAllPoints()
        p:SetPoint("TOPLEFT", 0, -top); p:SetPoint("BOTTOMRIGHT", 0, 0)
    end
end

function WP.ShowTab(key)
    current = key
    for k, p in pairs(pages) do p:SetShown(k == key) end
    tabs:Update()
    WP.Refresh()
end

local function Build()
    local db = WLWritsDB
    frame = S.Window("WLHelperComptoir", W, 400, L("Writs"), nil, db, "point", { header = S.HEADER_H, minH = 240 })
    local opts = S.IconButton(frame.header, "gear", 28, { L("Réglages des Writs"), L("Clic : ouvrir les réglages des Writs") }, function()
        if WP.OpenOptions then WP.OpenOptions("comptoir") end
    end)
    frame:AddHeaderButton(opts)
    tabs = S.Tabs(frame, { { "today", L("Aujourd'hui") }, { "shop", L("Achats") }, { "all", L("Tous les writs") } },
        function() return current end, WP.ShowTab, function(key)
            if key ~= "shop" then return nil end
            local n = 0
            for _, e in ipairs(shop) do if not e.done then n = n + 1 end end
            return n
        end)
    tabs:SetPoint("TOPLEFT", 0, -(S.HEADER_H + 1)); tabs:SetPoint("TOPRIGHT", 0, -(S.HEADER_H + 1))
    -- an auction house scan in progress, whatever the tab: a 2 px bar on the tab bar's divider and
    -- the count in the window's subtitle
    frame.scanBar = CreateFrame("Frame", nil, frame)
    frame.scanBar:SetHeight(2)
    S.Solid(frame.scanBar, "BACKGROUND", C.divider):SetAllPoints()
    frame.scanFill = S.Solid(frame.scanBar, "ARTWORK", C.ok)
    frame.scanFill:SetPoint("TOPLEFT"); frame.scanFill:SetPoint("BOTTOMLEFT")
    frame.scanBar:Hide()
    for _, key in ipairs({ "today", "shop", "all", "favor" }) do Page(key) end
    PlacePages()
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

local function Subtitle()
    local done, tot = WP.Scan and WP.Scan.Progress()
    if done and tot and tot > 0 then return string.format(L("Scan de l'HV : %d sur %d"), done, tot) end
    if current == "favor" then return "" end
    local name = WP.Reputation()
    return name or ""
end

-- Draws the page of the current tab from the data WP.Refresh gathered.
local function RenderCurrent()
    if current == "today" then RenderToday()
    elseif current == "shop" then RenderShop()
    elseif current == "favor" then if WP.RenderFavor then WP.RenderFavor() end
    else RenderAll() end
end

function WP.Refresh()
    if not frame or not frame:IsShown() then return end
    craftable = nil
    data = WP.Rows()
    for _, r in ipairs(data) do r.inPlan = nil end
    plan, need, pending, readyRep = WP.Plan(data)
    pending = pending or 0
    shop, shopTotal = WP.ShoppingList(data)
    tabs:Update()
    frame.subtitle:SetText(Subtitle())
    RenderCurrent()
    WP.PaintScan()
    -- wrapped text has its real height once its width applied: draw the page once more on the next
    -- frame (measuring again), then lay the envelope buttons over the final rows
    C_Timer.After(0, function()
        if frame:IsShown() and not frame.reRendering and not InCombatLockdown() then
            frame.reRendering = true
            RenderCurrent()
            frame.reRendering = nil
        end
        PlaceEnvelopes()
    end)
end

local queued = false
function WP.RefreshSoon(delay)
    if not frame or not frame:IsShown() or queued or InCombatLockdown() then return end
    queued = true
    C_Timer.After(delay or 1, function() queued = false; if not InCombatLockdown() then WP.Refresh() end end)
end

-- Fits the window after a page was drawn outside WP.Refresh (Favor.lua uses page:Fit itself).
function WP.FitComptoir(contentH) if frame then frame:FitHeight(contentH) end end

function WP.PaintScan()
    if not frame then return end
    local done, tot = WP.Scan and WP.Scan.Progress()
    if done and tot and tot > 0 then
        local top = frame:ContentTop() - 2
        frame.scanBar:ClearAllPoints()
        frame.scanBar:SetPoint("TOPLEFT", 0, -top); frame.scanBar:SetPoint("TOPRIGHT", 0, -top)
        frame.scanBar:Show()
        frame.scanFill:SetWidth(math.max(1, W * done / tot))
    else
        frame.scanBar:Hide()
    end
    local sub = Subtitle()
    if frame.subtitle:GetText() ~= sub then frame.subtitle:SetText(sub) end
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
        PlacePages()
        WP.ShowTab("favor")
    else
        frame.title:SetText(L("Writs"))
        tabs:Show()
        PlacePages()
        if current == "favor" then WP.ShowTab("today") end
    end
    frame:Show(); frame:Raise()
end

function WP.Toggle()
    if frame and frame:IsShown() then frame:Hide(); return end
    WP.Open("writs")
end
function WP.OpenFavor() WP.Open("favor") end
