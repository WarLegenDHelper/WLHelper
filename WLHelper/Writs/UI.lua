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

local ICON_CHECK = "Interface\\RaidFrame\\ReadyCheck-Ready"
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
    b:RegisterForClicks("AnyUp")
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
        r.name:SetWidth(200)
        r.right = S.Text(r, 13, C.dim)
        r.right:SetPoint("RIGHT", -10, 0)
        r.right:SetJustifyH("RIGHT")
        envRows[#envRows + 1] = r
        r:SetScript("OnClick", function(self) if self.writ then WP.TravelTo(self.writ) end end)
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
    today.laterText = S.Text(today.later, 13, C.dim)
    today.laterText:SetPoint("LEFT", 2, 0)
    today.later:SetScript("OnClick", function() WP.ShowTab("all") end)
    today.empty = S.Text(sc.content, 14, C.dim)
    today.empty:SetPoint("TOPLEFT", 2, -8)
    today.empty:SetWidth(W - 2 * PAD - 4)
    today.empty:SetWordWrap(true)

    local foot = CreateFrame("Frame", nil, p)
    foot:SetPoint("BOTTOMLEFT"); foot:SetPoint("BOTTOMRIGHT"); foot:SetHeight(60)
    local line = S.Solid(foot, "BORDER", C.divider)
    line:SetPoint("TOPLEFT"); line:SetPoint("TOPRIGHT"); line:SetHeight(1)
    today.tour = S.Button(foot, L("Lancer la tournée GPS"), W - 2 * PAD - 44, 36, "primary", function() WP.ToggleGPS() end)
    today.tour:SetPoint("LEFT", PAD, 0)
    today.scan = S.Button(foot, "", 36, 36, "secondary", function()
        if WP.Scan.Busy() then WP.Scan.Stop() else WP.Scan.Start(WP.ShoppingIDs()) end
    end, function()
        return WP.AuctionHouseOpen() and { L("Scanner les prix de la liste d'achat") } or { L("Ouvre l'hôtel des ventes pour scanner") }
    end)
    today.scan:SetPoint("LEFT", today.tour, "RIGHT", 8, 0)
    local ic = today.scan:CreateTexture(nil, "ARTWORK")
    ic:SetSize(16, 16); ic:SetPoint("CENTER"); ic:SetTexture("Interface\\Buttons\\UI-RefreshButton")
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

local function RenderToday()
    local name, reaction, inStanding, size, total = WP.Reputation()
    if not name then
        today.hero:SetText(L("Comptoir"))
        today.standing:SetText("")
        today.message:SetText(L("Faction introuvable : ouvre l'onglet Réputation une fois (touche U)."))
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
            today.hero:SetText(string.format(L("%s atteint"), WP.Reaction(reaction)))
            today.message:SetText(L("Choisis un objectif plus haut dans les options du Comptoir."))
        else
            today.hero:SetText(string.format(L("%s dans %d rép"), WP.Reaction(goal), need))
            local ready = 0
            for _, r in ipairs(data) do if r.state == "ready" and r.w.map and not r.tooHigh then ready = ready + 1 end end
            if pending >= need then
                today.message:SetText(string.format(L("Rends tes %d writs et c'est bon."), ready))
            elseif #plan > 0 then
                today.message:SetText(string.format(L("Rends les %d writs prêts, achète-en %d de plus."), ready, #plan))
            else
                today.message:SetText(L("Aucun writ abordable aujourd'hui : reviens après le reset."))
            end
        end
    end
    local secs = WP.SecondsToReset()
    today.reset:SetText(string.format(L("reset dans %d h"), math.floor(secs / 3600)))

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
        local ry = 40
        for j, r in ipairs(z.rows) do
            local row = c.rows.Get(j)
            row:ClearAllPoints(); row:SetPoint("TOPLEFT", 1, -ry)
            local w = r.w
            row.writ = w
            row.icon:SetTexture(S.ItemIcon(w.item))
            row.name:SetText(WP.ItemName(w.item, w.itemName) .. ((w.count or 1) > 1 and (" ×" .. w.count) or ""))
            SetColor(row.name, S.QualityColor(w.item))
            row.envItem = nil
            if r.state == "ready" then
                row.status:SetTexture(ICON_CHECK); row.status:SetVertexColor(1, 1, 1)
                row.right:SetText(string.format("%.0f, %.0f", w.x, w.y)); SetColor(row.right, C.dim)
            elseif r.state == "bag" then
                row.status:SetTexture(ICON_MAIL); row.status:SetVertexColor(1, 1, 1)
                row.envItem = w.writ   -- PlaceEnvelopes lays the secure button over this text
                row.right:SetText(L("Ouvrir l'enveloppe")); SetColor(row.right, C.warn)
            else
                row.status:SetTexture(ICON_WARN); row.status:SetVertexColor(1, 1, 1)
                row.right:SetText(L("objet manquant")); SetColor(row.right, C.warn)
            end
            row.tip = { WP.ItemName(w.writ, w.writName), string.format(L("%d rép · %s %.0f, %.0f"), w.rep, z.name, w.x, w.y),
                w.npcName and string.format(L("À rendre à %s"), w.npcName) or L("lieu de remise sur la carte"), { L("Clic : GPS jusqu'au PNJ"), 0.6, 0.6, 0.6 } }
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
    today.laterText:SetText(string.format(L("> Plus tard : %d writs dans des zones trop hautes"), later))
    if later > 0 then y = y + 32 end
    today.scroll.content:SetHeight(math.max(y, 10))

    today.tour.label:SetText(WLWritsCharDB.gps and L("Arrêter la tournée GPS") or L("Lancer la tournée GPS"))
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
    local sc = Scroller(p)
    sc:SetPoint("TOPLEFT", PAD, -70); sc:SetPoint("BOTTOMRIGHT", -PAD, 62)
    buy.scroll = sc
    buy.heads = Pool(function()
        local t = S.Text(sc.content, 13, C.dim)
        t:SetWidth(W - 2 * PAD)
        return t
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
        r.name:SetPoint("LEFT", r.icon, "RIGHT", 10, 0)
        r.name:SetWidth(230)
        r.price = S.Text(r, 13, C.text)
        r.price:SetPoint("RIGHT", -12, 0)
        r.price:SetJustifyH("RIGHT")
        r:SetScript("OnClick", function(self)
            local e = self.entry
            if not e then return end
            if IsShiftKeyDown() then WP.SearchList({ e }) else WP.Scan.OpenToBuy(e.id, math.max(1, e.need - e.have)) end
        end)
        r:SetScript("OnEnter", function(self)
            local e = self.entry
            if not e then return end
            local lines = { e.name, string.format(L("Dans tes sacs : %d / %d"), e.have, e.need) }
            if e.listed then lines[#lines + 1] = string.format(L("En vente (dernier scan) : %d"), e.listed) end
            if e.maxPrice then lines[#lines + 1] = string.format(L("Plafond de recherche : %s"), S.Money(e.maxPrice)) end
            lines[#lines + 1] = { L("Clic : acheter à l'HV · Maj-clic : Auctionator"), 0.6, 0.6, 0.6 }
            S.Tip(self, lines)
        end)
        r:SetScript("OnLeave", S.HideTip)
        return r
    end)
    buy.empty = S.Text(sc.content, 14, C.dim)
    buy.empty:SetPoint("TOPLEFT", 2, -8)
    buy.empty:SetWidth(W - 2 * PAD - 4)
    buy.empty:SetWordWrap(true)

    local foot = CreateFrame("Frame", nil, p)
    foot:SetPoint("BOTTOMLEFT"); foot:SetPoint("BOTTOMRIGHT"); foot:SetHeight(60)
    local line = S.Solid(foot, "BORDER", C.divider)
    line:SetPoint("TOPLEFT"); line:SetPoint("TOPRIGHT"); line:SetHeight(1)
    buy.rescan = S.Button(foot, L("Rescanner"), 110, 32, "secondary", function()
        if WP.Scan.Busy() then WP.Scan.Stop(); return end
        local ids = {}
        for _, e in ipairs(shop) do if not e.done then ids[#ids + 1] = e.id end end
        WP.Scan.Start(ids)
    end)
    buy.rescan:SetPoint("LEFT", PAD, 0)
    buy.age = S.Text(foot, 13, C.dim)
    buy.age:SetPoint("LEFT", buy.rescan, "RIGHT", 10, 0)
    buy.auct = S.Button(foot, L("Liste Auctionator"), 120, 32, "ghost", function() WP.SaveAuctionatorList(shop) end)
    buy.auct:SetPoint("RIGHT", -PAD, 0)
end

local function RenderShop()
    local left, rep = 0, 0
    for _, e in ipairs(shop) do if not e.done then left = left + 1 end end
    for _, r in ipairs(plan) do rep = rep + r.w.rep end
    if left == 0 then
        buy.total:SetText(L("Rien à acheter"))
        buy.sub:SetText(#data > 0 and L("Tes writs suffisent pour l'objectif.") or "")
    else
        buy.total:SetText(S.Money(shopTotal))
        buy.sub:SetText(string.format(L("pour %d writs, +%d rép. Clique un objet pour l'acheter à l'HV."), #plan, rep))
    end
    -- groups: one per turn-in zone, in the order the list gives
    local groups, order = {}, {}
    for _, e in ipairs(shop) do
        local key = e.zone or "?"
        if not groups[key] then groups[key] = {}; order[#order + 1] = key end
        table.insert(groups[key], e)
    end
    local y, hi, ri = 0, 0, 0
    for _, key in ipairs(order) do
        hi = hi + 1
        local h = buy.heads.Get(hi)
        h:ClearAllPoints(); h:SetPoint("TOPLEFT", 2, -y)
        h:SetText(string.format(L("%s, à rendre là-bas"), key))
        y = y + 22
        for idx, e in ipairs(groups[key]) do
            ri = ri + 1
            local r = buy.rows.Get(ri)
            r.entry = e
            r:ClearAllPoints(); r:SetPoint("TOPLEFT", 0, -(y - (idx > 1 and 1 or 0)))
            r.icon:SetTexture(S.ItemIcon(e.id))
            local qty = (e.need > 1) and (" ×" .. e.need) or ""
            r.name:SetText((e.isWrit and L("Enveloppe : ") or "") .. e.name .. qty)
            SetColor(r.name, e.isWrit and C.text or S.QualityColor(e.id))
            local leftN = e.need - e.have
            if e.done then
                r:SetAlpha(0.4); r.price:SetText(L("dans tes sacs")); SetColor(r.price, C.dim)
            else
                r:SetAlpha(1)
                if e.src == "Absent" then r.price:SetText(L("absent")); SetColor(r.price, C.danger)
                elseif e.listed and e.listed < leftN then r.price:SetText(string.format(L("%s, %d seul"), S.Money(e.price), e.listed)); SetColor(r.price, C.warn)
                else r.price:SetText(e.price and S.Money(e.price) or "?"); SetColor(r.price, C.text) end
            end
            y = y + 37
        end
        y = y + 12
    end
    buy.heads.HideFrom(hi + 1)
    buy.rows.HideFrom(ri + 1)
    buy.empty:SetShown(#shop == 0)
    buy.empty:SetText(L("Ton plan du jour est couvert."))
    buy.scroll.content:SetHeight(math.max(y, 10))

    local done, tot = WP.Scan.Progress()
    buy.rescan.label:SetText(done and string.format(L("Scan %d/%d"), done, tot) or L("Rescanner"))
    if done or WP.AuctionHouseOpen() then buy.rescan:Enable() else buy.rescan:Disable() end
    local newest
    for _, e in ipairs(shop) do
        local _, _, ago = WP.Scan.Get(e.id)
        if ago and (not newest or ago < newest) then newest = ago end
    end
    buy.age:SetText(newest and string.format(L("prix d'il y a %d min"), math.floor(newest / 60)) or (WP.AuctionHouseOpen() and "" or L("ouvre l'HV pour scanner")))
    buy.auct:SetShown(Auctionator and Auctionator.API and #shop > 0 and true or false)
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
    glass:SetSize(14, 14); glass:SetPoint("LEFT", 9, 0); glass:SetTexture("Interface\\Common\\UI-Searchbox-Icon")
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
    sc:SetPoint("TOPLEFT", PAD, -84); sc:SetPoint("BOTTOMRIGHT", -PAD, 8)
    all.scroll = sc
    all.heads = Pool(function()
        local b = CreateFrame("Button", nil, sc.content)
        b:SetSize(W - 2 * PAD, 30)
        b.text = S.Text(b, 13, C.dim)
        b.text:SetPoint("LEFT", 2, 0)
        b:SetScript("OnClick", function(self) if self.key then all.open[self.key] = not all.open[self.key]; WP.Refresh() end end)
        return b
    end)
    all.rows = Pool(function()
        local r = CreateFrame("Button", nil, sc.content)
        r:SetSize(W - 2 * PAD, 46)
        S.Solid(r, "HIGHLIGHT", { 1, 1, 1 }, 0.05):SetAllPoints()   -- above the text: must stay see-through
        r.icon = r:CreateTexture(nil, "ARTWORK")
        r.icon:SetSize(20, 20); r.icon:SetPoint("LEFT", 4, 0); r.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        r.name = S.Text(r, 14, C.text)
        r.name:SetPoint("TOPLEFT", 34, -7)
        r.name:SetWidth(260)
        r.sub = S.Text(r, 12, C.dim)
        r.sub:SetPoint("TOPLEFT", 34, -26)
        r.sub:SetWidth(260)
        r.cost = S.Text(r, 13, C.text)
        r.cost:SetPoint("RIGHT", -6, 0)
        r.cost:SetJustifyH("RIGHT")
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
                string.format(L("Enveloppe %s · objet %s · Coin Pouch -%s"), x.ownWrit and L("possédée") or S.Money(x.writPrice),
                    (x.ownItem or x.state == "ready") and L("possédé") or S.Money(x.itemPrice and x.itemPrice * (w.count or 1)), S.Money((WP.PouchValue(w.tier)))) }
            if w.npcName then lines[#lines + 1] = string.format(L("À rendre à %s"), w.npcName) end
            lines[#lines + 1] = { L("Clic : GPS · Maj-clic : chercher à l'HV"), 0.6, 0.6, 0.6 }
            if w.map and WP.IsSkipped("zones", w.map) then
                lines[#lines + 1] = { L("Zone mise de côté : Réglages › Comptoir"), C.warn[1], C.warn[2], C.warn[3] }
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
        y = y + 30
    end
    local function row(r)
        ri = ri + 1
        local b = all.rows.Get(ri)
        b.row = r
        b:ClearAllPoints(); b:SetPoint("TOPLEFT", 0, -y)
        local w = r.w
        b.icon:SetTexture(S.ItemIcon(w.item))
        local craft = Craftable(w.item) and (" " .. S.Hex(C.info) .. L("· tu le fabriques") .. "|r") or ""
        b.name:SetText(WP.ItemName(w.item, w.itemName) .. ((w.count or 1) > 1 and (" ×" .. w.count) or "") .. craft)
        SetColor(b.name, S.QualityColor(w.item))
        local where = w.map and string.format("%s %.0f, %.0f", r.zone, w.x, w.y) or L("lieu inconnu")
        if r.tooHigh and r.zoneMin then where = where .. string.format(L(", niv. %d+"), r.zoneMin) end
        b.sub:SetText((r.skipped and (S.Hex(C.warn) .. L("mis de côté") .. "|r · ") or "") .. string.format("%s · %s, %d %s", where, WP.Tier(w.tier), w.rep, L("rép")))
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
        head(string.format("%s %s : %d", all.open.later and "v" or ">", L("Plus tard, zones trop hautes ou lieu inconnu"), #later), "later")
        if all.open.later then for _, r in ipairs(later) do row(r) end end
    end
    if #done > 0 then
        head(string.format("%s %s : %d", all.open.done and "v" or ">", L("Rendus aujourd'hui"), #done), "done")
        if all.open.done then for _, r in ipairs(done) do row(r) end end
    end
    all.heads.HideFrom(hi + 1)
    all.rows.HideFrom(ri + 1)
    all.scroll.content:SetHeight(math.max(y, 10))
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
    frame = S.Window("WLHelperComptoir", W, H, L("Comptoir"), nil, db, "point")
    local opts = S.IconButton(frame.header, "Interface\\Buttons\\UI-OptionsButton", 28, { L("Options du Comptoir") }, function()
        if WP.OpenOptions then WP.OpenOptions("comptoir") end
    end)
    opts:SetPoint("RIGHT", frame.close, "LEFT", 0, 0)
    tabs = S.Tabs(frame, { { "today", L("Aujourd'hui") }, { "shop", L("Achats") }, { "all", L("Tous les writs") } },
        function() return current end, WP.ShowTab, function(key)
            if key ~= "shop" then return nil end
            local n = 0
            for _, e in ipairs(shop) do if not e.done then n = n + 1 end end
            return n
        end)
    tabs:SetPoint("TOPLEFT", 1, -39); tabs:SetPoint("TOPRIGHT", -1, -39)
    for _, key in ipairs({ "today", "shop", "all" }) do
        local p = CreateFrame("Frame", nil, frame)
        p:SetPoint("TOPLEFT", 0, -76); p:SetPoint("BOTTOMRIGHT")
        pages[key] = p
    end
    BuildToday(pages.today)
    BuildShop(pages.shop)
    BuildAll(pages.all)
    frame:SetScript("OnShow", function() WP.Refresh() end)
    frame:HookScript("OnHide", HideEnvelopes)
    -- the envelope buttons follow the window: off while it moves, laid again where it lands
    frame.header:HookScript("OnDragStart", HideEnvelopes)
    frame.header:HookScript("OnDragStop", PlaceEnvelopes)
    local ev = CreateFrame("Frame")
    ev:RegisterEvent("PLAYER_REGEN_DISABLED")
    ev:RegisterEvent("PLAYER_REGEN_ENABLED")
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
    frame.subtitle:SetText(name or "")
    data = WP.Rows()
    for _, r in ipairs(data) do r.inPlan = nil end
    plan, need, pending, readyRep = WP.Plan(data)
    pending = pending or 0
    shop, shopTotal = WP.ShoppingList(data)
    tabs:Update()
    if current == "today" then RenderToday()
    elseif current == "shop" then RenderShop()
    else RenderAll() end
    -- once the new layout has its sizes
    C_Timer.After(0, PlaceEnvelopes)
end

local queued = false
function WP.RefreshSoon(delay)
    if not frame or not frame:IsShown() or queued or InCombatLockdown() then return end
    queued = true
    C_Timer.After(delay or 1, function() queued = false; if not InCombatLockdown() then WP.Refresh() end end)
end

function WP.OnScanProgress()
    if frame and frame:IsShown() then WP.RefreshSoon(0.3) end
end

function WP.OnGPSChanged()
    if frame and frame:IsShown() and current == "today" then
        today.tour.label:SetText(WLWritsCharDB.gps and L("Arrêter la tournée GPS") or L("Lancer la tournée GPS"))
    end
end

function WP.Open()
    if not frame then Build() end
    frame:Show(); frame:Raise()
end

function WP.Toggle()
    if not frame then Build() end
    frame:SetShown(not frame:IsShown())
end

