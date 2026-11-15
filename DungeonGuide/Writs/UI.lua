-- Writs/UI.lua: the Writs window of WL Helper, drawn in EllesmereUI's look (dark warm panel, faint white
-- borders, accent colour, Expressway) and falling back to plain colours when EUI is not loaded.
local ADDON, root = ...
-- The Writs module of WL Helper keeps its own table inside the addon's namespace.
root.Writs = root.Writs or {}
local ns = root.Writs
local WP = ns.WP
local L = ns.L

-- ---------------------------------------------------------------- style

local EUI_FONT = "Interface\\AddOns\\EllesmereUI\\media\\fonts\\Expressway.TTF"
local BG = { 0.069, 0.058, 0.047, 0.97 }
local ROW_ODD, ROW_EVEN = 0.10, 0.20
local BORDER_A = 0.05

local function Accent()
    local g = EllesmereUI and EllesmereUI.ELLESMERE_GREEN
    if type(g) == "table" and g.r then return g.r, g.g, g.b end
    return 12 / 255, 210 / 255, 157 / 255
end

local function FontPath()
    if EllesmereUI and EllesmereUI.GetFontPath then
        local ok, p = pcall(EllesmereUI.GetFontPath)
        if ok and type(p) == "string" then return p end
    end
    return EUI_FONT
end

local fontStrings = {}
local function Text(parent, size, layer)
    local fs = parent:CreateFontString(nil, layer or "OVERLAY")
    if not fs:SetFont(FontPath(), size, "") then fs:SetFont(STANDARD_TEXT_FONT, size, "") end
    fs:SetShadowOffset(1, -1)
    fs:SetShadowColor(0, 0, 0, 0.8)
    fs:SetJustifyH("LEFT")
    fs:SetWordWrap(false)
    fontStrings[#fontStrings + 1] = fs
    return fs
end

local function Solid(parent, layer, r, g, b, a)
    local t = parent:CreateTexture(nil, layer or "BACKGROUND")
    t:SetColorTexture(r, g, b, a)
    return t
end

-- One-pixel border on all four sides.
local function Border(frame, r, g, b, a)
    local edges = {}
    for i, p in ipairs({ { "TOPLEFT", "TOPRIGHT" }, { "BOTTOMLEFT", "BOTTOMRIGHT" }, { "TOPLEFT", "BOTTOMLEFT" }, { "TOPRIGHT", "BOTTOMRIGHT" } }) do
        local t = Solid(frame, "BORDER", r, g, b, a)
        t:SetPoint(p[1]); t:SetPoint(p[2])
        if i <= 2 then t:SetHeight(1) else t:SetWidth(1) end
        edges[i] = t
    end
    function edges:SetColor(r2, g2, b2, a2) for _, t in ipairs(self) do t:SetColorTexture(r2, g2, b2, a2) end end
    return edges
end

-- Flat EUI-style button: dark fill, accent outline, label brightens on hover.
local function Button(parent, label, width, onClick)
    local r, g, b = Accent()
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(width, 22)
    Solid(btn, "BACKGROUND", 0.077, 0.068, 0.058, 0.92):SetAllPoints()
    local brd = Border(btn, r, g, b, 0.45)
    local lbl = Text(btn, 12)
    lbl:SetPoint("CENTER")
    lbl:SetJustifyH("CENTER")
    lbl:SetText(label)
    lbl:SetTextColor(r, g, b, 0.85)
    btn.label = lbl
    btn:SetScript("OnEnter", function() lbl:SetTextColor(r, g, b, 1); brd:SetColor(r, g, b, 1) end)
    btn:SetScript("OnLeave", function() lbl:SetTextColor(r, g, b, 0.85); brd:SetColor(r, g, b, 0.45) end)
    btn:SetScript("OnClick", onClick)
    return btn
end

-- Toggle chip bound to a getter and a setter.
local function Chip(parent, label, get, set)
    local r, g, b = Accent()
    local btn = CreateFrame("Button", nil, parent)
    btn:SetHeight(20)
    local fill = Solid(btn, "BACKGROUND", r, g, b, 0)
    fill:SetAllPoints()
    local brd = Border(btn, 1, 1, 1, 0.12)
    local lbl = Text(btn, 11)
    lbl:SetPoint("CENTER")
    lbl:SetJustifyH("CENTER")
    lbl:SetText(label)
    btn:SetWidth(lbl:GetStringWidth() + 18)
    function btn:Update()
        local on = get()
        fill:SetColorTexture(r, g, b, on and 0.22 or 0)
        brd:SetColor(on and r or 1, on and g or 1, on and b or 1, on and 0.7 or 0.12)
        lbl:SetTextColor(1, 1, 1, on and 0.95 or 0.45)
    end
    btn:SetScript("OnClick", function() set(not get()); btn:Update(); WP.Refresh() end)
    btn:Update()
    return btn
end

-- ---------------------------------------------------------------- Mastercraft: what you can craft

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

-- ---------------------------------------------------------------- window

local COLUMNS = {
    { key = "state",  title = "État",       width = 78 },
    { key = "name",   title = "Objet demandé", width = 228 },
    { key = "zone",   title = "Remise",     width = 178 },
    { key = "rep",    title = "Rép",        width = 40, right = true },
    { key = "writ",   title = "Writ",       width = 64, right = true },
    { key = "item",   title = "Objet",      width = 64, right = true },
    { key = "net",    title = "Net",        width = 64, right = true },
    { key = "per100", title = "/100 rép",   width = 66, right = true },
}
local ROW_H, ROWS = 20, 18
local WIDTH = 24
for _, c in ipairs(COLUMNS) do WIDTH = WIDTH + c.width end

local STATE_TEXT = {
    done  = { "Rendu", 0.55, 0.55, 0.55 },
    ready = { "Prêt", 0.35, 0.95, 0.45 },
    log   = { "Objet manquant", 1, 0.82, 0.25 },
    bag   = { "Dans le sac", 0.45, 0.75, 1 },
    buy   = { "", 1, 1, 1 },
}

local frame, rowsUI, header, repBar, repText, summary, pouchText, sourceText
local offset, data, visible = 0, {}, {}

local function PriceColor(src, age)
    if src == "Scan" then return 0.55, 1, 0.8 end
    if src == "Absent" then return 1, 0.4, 0.35 end
    if src == "Auctionator" then
        -- No age means Auctionator's price is older than it keeps track of: treat it as stale.
        if not age or age >= 2 then return 0.85, 0.85, 0.6 end
        return 1, 1, 1
    elseif src == "TSM" then return 0.8, 0.9, 1 end
    return 0.6, 0.6, 0.6
end

local function Per100Color(v)
    if not v then return 0.6, 0.6, 0.6 end
    if v <= 8000 then return 0.35, 0.95, 0.45 end
    if v <= 12000 then return 1, 0.82, 0.25 end
    return 1, 0.4, 0.35
end

local function SortValue(r, key)
    local w = r.w
    if key == "state" then
        local order = { ready = 1, log = 2, bag = 3, buy = 4, done = 5 }
        return (r.inPlan and 0 or order[r.state] or 9)
    elseif key == "name" then return WP.ItemName(w.item, w.itemName)
    elseif key == "zone" then return r.zone or "~"
    elseif key == "rep" then return -w.rep
    elseif key == "writ" then return r.writPrice or math.huge
    elseif key == "item" then return r.itemPrice or math.huge
    elseif key == "net" then return r.net or math.huge
    end
    return r.per100 or math.huge
end

local function Sort()
    local key, desc = WLWritsDB.sort, WLWritsDB.sortDesc
    table.sort(visible, function(a, b)
        local va, vb = SortValue(a, key), SortValue(b, key)
        if va == vb then return (a.per100 or math.huge) < (b.per100 or math.huge) end
        if type(va) ~= type(vb) then va, vb = tostring(va), tostring(vb) end
        if desc then return va > vb end
        return va < vb
    end)
end

local function Tooltip(row)
    local r = row.data
    if not r then return end
    local w = r.w
    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
    GameTooltip:SetText(WP.ItemName(w.writ, w.writName), 1, 1, 1)
    GameTooltip:AddLine(string.format(L("%s · %d de réputation · %s"), WP.Tier(w.tier), w.rep, w.prof or ""), 0.8, 0.8, 0.8)
    GameTooltip:AddLine(" ")
    local function priceLine(label, p, src, age, own, qty)
        if own then GameTooltip:AddDoubleLine(label, L("possédé"), 1, 1, 1, 0.5, 0.9, 0.5); return end
        if src == "Absent" then GameTooltip:AddDoubleLine(label, L("pas en vente (scan)"), 1, 1, 1, 1, 0.4, 0.35); return end
        local extra = src == "Scan" and string.format(L("scan, %d en vente"), qty or 0) or L(src or "")
        if age and src ~= "Scan" then extra = extra .. string.format(L(", vu il y a %d j"), age) end
        GameTooltip:AddDoubleLine(label, WP.Money(p) .. "  |cff888888(" .. extra .. ")|r", 1, 1, 1, PriceColor(src, age))
    end
    priceLine(L("Writ"), r.writPrice, r.writSrc, r.writAge, r.ownWrit, r.writQty)
    local itemLabel = WP.ItemName(w.item, w.itemName) .. ((w.count or 1) > 1 and (" x" .. w.count) or "")
    priceLine(itemLabel, r.itemPrice, r.itemSrc, r.itemAge, r.ownItem or r.state == "ready", r.itemQty)
    if w.npcName then GameTooltip:AddLine(string.format(L("À rendre à %s"), w.npcName), 1, 0.82, 0.25) end
    local pouch, _, measured = WP.PouchValue(w.tier)
    GameTooltip:AddDoubleLine(measured and L("Coin Pouch (mesurée)") or L("Coin Pouch (estimée)"), "-" .. WP.Money(pouch), 1, 1, 1, 0.35, 0.95, 0.45)
    if r.net then GameTooltip:AddDoubleLine(L("Coût net"), WP.Money(r.net), 1, 1, 1, Per100Color(r.per100)) end
    if Craftable(w.item) then GameTooltip:AddLine(L("Tu sais fabriquer cet objet (Mastercraft)."), 0.5, 0.9, 1) end
    GameTooltip:AddLine(" ")
    if w.map then
        GameTooltip:AddLine(string.format(L("Remise : %s %.1f, %.1f"), r.zone, w.x, w.y), 1, 0.82, 0.25)
        if r.tooHigh then GameTooltip:AddLine(string.format(L("Zone prévue pour le niveau %d+"), r.zoneMin), 1, 0.4, 0.35) end
    else
        GameTooltip:AddLine(L("Lieu de remise inconnu : ouvre l'enveloppe pour voir la quête."), 1, 0.4, 0.35)
    end
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(L("Clic : GPS jusqu'au PNJ"), 0.6, 0.6, 0.6)
    GameTooltip:AddLine(L("Maj-clic : chercher writ + objet à l'HV (Auctionator)"), 0.6, 0.6, 0.6)
    GameTooltip:Show()
end

local function DrawRows()
    if not frame then return end
    local n = #visible
    offset = math.max(0, math.min(offset, n - ROWS))
    local ar, ag, ab = Accent()
    for i = 1, ROWS do
        local row = rowsUI[i]
        local r = visible[i + offset]
        row.data = r
        if not r then
            row:Hide()
        else
            row:Show()
            local w = r.w
            local c = row.cells
            local st = STATE_TEXT[r.state]
            if r.inPlan then
                c.state:SetText(L("> À acheter")); c.state:SetTextColor(ar, ag, ab)
            else
                c.state:SetText(st[1] ~= "" and L(st[1]) or ""); c.state:SetTextColor(st[2], st[3], st[4])
            end
            local tierTag = ({ Journeyman = "|cff9d9d9dC|r", Expert = "|cff1eff00E|r", Artisan = "|cff0070ddA|r" })[w.tier]
            local craft = Craftable(w.item) and " |cff80c0ff(craft)|r" or ""
            c.name:SetText(tierTag .. "  " .. WP.ItemName(w.item, w.itemName) .. craft)
            if w.map then
                c.zone:SetText(string.format("%s  |cff888888%.0f, %.0f|r", r.zone, w.x, w.y))
                if r.tooHigh then c.zone:SetTextColor(1, 0.45, 0.4) else c.zone:SetTextColor(1, 1, 1, 0.85) end
            else
                c.zone:SetText("?"); c.zone:SetTextColor(0.6, 0.6, 0.6)
            end
            c.rep:SetText(w.rep)
            if r.ownWrit then c.writ:SetText(L("possédé")); c.writ:SetTextColor(0.5, 0.9, 0.5)
            else c.writ:SetText(WP.Money(r.writPrice)); c.writ:SetTextColor(PriceColor(r.writSrc, r.writAge)) end
            if r.ownItem or r.state == "ready" then c.item:SetText(L("possédé")); c.item:SetTextColor(0.5, 0.9, 0.5)
            else c.item:SetText(WP.Money(r.itemPrice)); c.item:SetTextColor(PriceColor(r.itemSrc, r.itemAge)) end
            c.net:SetText(r.net and WP.Money(r.net) or "?")
            c.per100:SetText(r.per100 and WP.Money(math.floor(r.per100)) or "?")
            c.per100:SetTextColor(Per100Color(r.per100))
            row.hl:SetShown(r.inPlan == true)
            if r.state == "done" then row:SetAlpha(0.55) else row:SetAlpha(1) end
        end
    end
    local thumbSpace = ROWS * ROW_H - 30
    if n > ROWS then
        frame.thumb:Show()
        frame.thumb:SetPoint("TOP", frame.track, "TOP", 0, -math.floor(thumbSpace * offset / (n - ROWS)))
    else
        frame.thumb:Hide()
    end
    frame.count:SetText(string.format(L("%d writs affichés"), n))
end

-- ---------------------------------------------------------------- shopping list panel

local SHOP_ROWS = 20
local shop, shopList = nil, {}

local function DrawShop(total)
    if not shop or not shop:IsShown() then return end
    local left, done = 0, 0
    for _, e in ipairs(shopList) do if e.done then done = done + 1 else left = left + 1 end end
    for i = 1, SHOP_ROWS do
        local row, e = shop.rows[i], shopList[i]
        row.data = e
        if not e then row:Hide() else
            row:Show()
            local qty = e.need > 1 and string.format(" x%d", e.need) or ""
            if e.done then
                row.mark:SetText("|cff59f273OK|r")
                row.name:SetText("|cff808080" .. e.name .. qty .. "|r")
                row.price:SetText("|cff808080" .. L("acheté") .. "|r")
            else
                row.mark:SetText(e.have > 0 and string.format("|cffffd200%d/%d|r", e.have, e.need) or "|cff808080--|r")
                row.name:SetText(e.name .. qty)
                local left = e.need - e.have
                local short = e.listed and e.listed < left
                if e.src == "Absent" then
                    row.price:SetText(L("absent"))
                elseif short then
                    row.price:SetText(string.format(L("%d en vente"), e.listed))
                elseif e.src == "Scan" then
                    row.price:SetText(WP.Money(e.price))
                else
                    row.price:SetText(e.maxPrice and (L("max ") .. WP.Money(e.maxPrice)) or "?")
                end
                if short then row.price:SetTextColor(1, 0.4, 0.35) else row.price:SetTextColor(PriceColor(e.src)) end
            end
        end
    end
    if #shopList == 0 then
        shop.empty:SetText(L("Rien à acheter : ton plan est couvert."))
    elseif #shopList > SHOP_ROWS then
        shop.empty:SetText(string.format(L("+%d autres"), #shopList - SHOP_ROWS))
    else
        shop.empty:SetText("")
    end
    shop.total:SetText(string.format(L("Reste %d objets ~ %s   ·   %d achetés"), left, WP.Money(total or 0), done))
end

local function BuildShop()
    local ar, ag, ab = Accent()
    shop = CreateFrame("Frame", nil, frame)
    shop:SetPoint("TOPLEFT", frame, "TOPRIGHT", 4, 0)
    shop:SetPoint("BOTTOMLEFT", frame, "BOTTOMRIGHT", 4, 0)
    shop:SetWidth(320)
    shop:EnableMouse(true)
    Solid(shop, "BACKGROUND", BG[1], BG[2], BG[3], BG[4]):SetAllPoints()
    Border(shop, 1, 1, 1, 0.08)
    local top = Solid(shop, "ARTWORK", ar, ag, ab, 0.9)
    top:SetPoint("TOPLEFT"); top:SetPoint("TOPRIGHT"); top:SetHeight(2)
    local title = Text(shop, 16)
    title:SetPoint("TOPLEFT", 12, -12)
    title:SetText(L("Liste d'achat"))
    title:SetTextColor(ar, ag, ab)
    local hint = Text(shop, 10)
    hint:SetPoint("TOPLEFT", 12, -34)
    hint:SetPoint("TOPRIGHT", -12, -34)
    hint:SetWordWrap(true)
    hint:SetText(L("Clic : acheter à l'HV · Maj-clic : Auctionator · se coche une fois dans tes sacs"))
    hint:SetTextColor(1, 1, 1, 0.41)
    shop.rows = {}
    for i = 1, SHOP_ROWS do
        local row = CreateFrame("Button", nil, shop)
        row:SetPoint("TOPLEFT", 8, -52 - (i - 1) * ROW_H)
        row:SetPoint("RIGHT", shop, "RIGHT", -8, 0)
        row:SetHeight(ROW_H)
        Solid(row, "BACKGROUND", 0, 0, 0, (i % 2 == 1) and ROW_ODD or ROW_EVEN):SetAllPoints()
        Solid(row, "HIGHLIGHT", 1, 1, 1, 0.06):SetAllPoints()
        row.mark = Text(row, 11)
        row.mark:SetPoint("LEFT", 4, 0)
        row.mark:SetWidth(34)
        row.name = Text(row, 12)
        row.name:SetPoint("LEFT", 40, 0)
        row.name:SetWidth(180)
        row.price = Text(row, 11)
        row.price:SetPoint("RIGHT", -4, 0)
        row.price:SetWidth(80)
        row.price:SetJustifyH("RIGHT")
        row:SetScript("OnClick", function(self)
            local e = self.data
            if not e then return end
            if IsShiftKeyDown() then WP.SearchList({ e }) else WP.Scan.OpenToBuy(e.id, math.max(1, e.need - e.have)) end
        end)
        row:SetScript("OnEnter", function(self)
            local e = self.data
            if not e then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(e.name, 1, 1, 1)
            GameTooltip:AddDoubleLine(L("Dans tes sacs"), string.format("%d / %d", e.have, e.need), 1, 1, 1, 1, 1, 1)
            if e.price then GameTooltip:AddDoubleLine(L("Prix attendu"), WP.Money(e.price) .. " (" .. L(e.src or "?") .. ")", 1, 1, 1, 1, 1, 1) end
            if e.listed then GameTooltip:AddDoubleLine(L("En vente (dernier scan)"), tostring(e.listed), 1, 1, 1, 1, 1, 1) end
            if e.maxPrice then GameTooltip:AddDoubleLine(L("Plafond de recherche"), WP.Money(e.maxPrice), 1, 1, 1, 1, 0.82, 0.25) end
            GameTooltip:AddLine(" ")
            for _, why in ipairs(e.why) do
                GameTooltip:AddLine(why == "writ" and L("Le writ lui-même") or (L("Pour ") .. why), 0.7, 0.7, 0.7)
            end
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave", function() GameTooltip:Hide() end)
        shop.rows[i] = row
    end
    shop.empty = Text(shop, 11)
    shop.empty:SetPoint("TOPLEFT", 12, -52 - SHOP_ROWS * ROW_H - 4)
    shop.empty:SetTextColor(1, 1, 1, 0.53)
    shop.total = Text(shop, 12)
    shop.total:SetPoint("BOTTOMLEFT", 12, 44)
    shop.total:SetPoint("BOTTOMRIGHT", -12, 44)
    shop.rescan = Button(shop, L("Rescanner la liste"), 142, function()
        if WP.Scan.Busy() then WP.Scan.Stop(); return end
        local ids = {}
        for _, e in ipairs(shopList) do if not e.done then ids[#ids + 1] = e.id end end
        WP.Scan.Start(ids)
    end)
    shop.rescan:SetPoint("BOTTOMLEFT", 12, 12)
    if Auctionator and Auctionator.API then
        local save = Button(shop, L("Liste Auctionator"), 142, function() WP.SaveAuctionatorList(shopList) end)
        save:SetPoint("BOTTOMRIGHT", -12, 12)
    end
    local db = WLWritsDB
    shop.auto = Chip(shop, L("Rescan à l'ouverture de l'HV"), function() return db.autoRescan end, function(v) db.autoRescan = v end)
    shop.auto:SetPoint("BOTTOMLEFT", 12, 72)
    shop:SetShown(WLWritsDB.showShop ~= false)
end

function WP.Refresh()
    if not frame or not frame:IsShown() then return end
    craftable = nil
    data = WP.Rows()
    for _, r in ipairs(data) do r.inPlan = nil end
    local plan, need, pending, readyRep, zones = WP.Plan(data)
    local shopTotal
    shopList, shopTotal = WP.ShoppingList(data)
    DrawShop(shopTotal)
    visible = {}
    for _, r in ipairs(data) do if r.show then visible[#visible + 1] = r end end
    Sort()

    -- reputation
    local name, reaction, inStanding, size = WP.Reputation()
    local ar, ag, ab = Accent()
    if name then
        repBar:SetMinMaxValues(0, math.max(size or 1, 1))
        repBar:SetValue(inStanding or 0)
        repBar:SetStatusBarColor(ar, ag, ab, 0.85)
        local goalTxt = ""
        if need then
            local _, goalReaction = WP.RepNeeded()
            goalTxt = string.format(L("   ·   %s dans %d de réputation"), WP.Reaction(goalReaction), need)
        end
        repText:SetText(string.format("%s : %s %d / %d%s", name, WP.Reaction(reaction), inStanding or 0, size or 0, goalTxt))
    else
        repBar:SetMinMaxValues(0, 1); repBar:SetValue(0)
        repText:SetText(L("Faction introuvable : ouvre l'onglet Réputation une fois (touche U)."))
    end

    -- summary
    local cost = 0
    for _, r in ipairs(plan) do cost = cost + (r.net or 0) end
    local resetH = math.floor(WP.SecondsToReset() / 3600)
    local resetM = math.floor((WP.SecondsToReset() % 3600) / 60)
    local s = string.format(L("Prêts : |cff59f273%d rép|r   ·   Déjà possédés : %d rép"), readyRep or 0, pending or 0)
    if need and need > 0 then
        if (pending or 0) >= need then
            s = s .. L("   ·   |cff59f273Rien à acheter : ce que tu as suffit|r")
        else
            s = s .. string.format(L("   ·   Plan : |cffffd200%d writs|r pour %s net"), #plan, WP.Money(cost))
        end
    end
    if zones and #zones > 0 then
        frame.route:SetText(L("Zones à visiter : ") .. table.concat(zones, "  ·  "))
    else
        frame.route:SetText("")
    end
    s = s .. string.format(L("   ·   Reset dans %d h %02d"), resetH, resetM)
    summary:SetText(s)

    -- One value per writ tier once measured; the others still use the estimate.
    local parts, any = {}, false
    for _, t in ipairs(WP.TIERS) do
        local v, n, measured = WP.PouchValue(t)
        any = any or measured
        parts[#parts + 1] = string.format("%s %s%s", WP.Tier(t), WP.Money(v), measured and string.format(" (%d)", n) or "?")
    end
    pouchText:SetText(L("Coin Pouch : ") .. table.concat(parts, "  ·  ")
        .. (any and "" or L("   (? = estimation, ouvre une bourse pour mesurer)")))

    local hasA = Auctionator and Auctionator.API and Auctionator.API.v1 and true
    local hasT = TSM_API and true
    sourceText:SetText(string.format(L("Prix : scan%s%s, sinon instantané TSM du %s   ·   turquoise = scan, blanc = Auctionator récent, jaune pâle = 2 j+, gris = instantané, rouge = pas en vente"),
        hasA and " / Auctionator" or "", hasT and " / TSM" or "", ns.SNAPSHOT_DATE))

    for _, c in ipairs(header) do
        local arrow = ""
        if WLWritsDB.sort == c.key then arrow = WLWritsDB.sortDesc and " v" or " ^" end
        c.label:SetText(L(c.title) .. arrow)
    end
    frame.chips:Update()
    DrawRows()
end

-- Scan progress on the two scan buttons.
function WP.OnScanProgress()
    if not frame then return end
    local done, total = WP.Scan.Progress()
    local text = done and string.format(L("Scan %d/%d (arrêter)"), done, total)
    frame.scan.label:SetText(text or L("Scanner les prix (HV)"))
    if shop and shop.rescan then shop.rescan.label:SetText(text or L("Rescanner la liste")) end
    if not done then WP.RefreshSoon() end
end

local pending
function WP.RefreshSoon()
    if not frame or not frame:IsShown() or pending or InCombatLockdown() then return end
    pending = true
    C_Timer.After(1, function() pending = false; if not InCombatLockdown() then WP.Refresh() end end)
end

local function Build()
    local ar, ag, ab = Accent()
    frame = CreateFrame("Frame", "WLWritsFrame", UIParent)
    frame:SetSize(WIDTH, 220 + ROWS * ROW_H)
    frame:SetFrameStrata("HIGH")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local p, _, rp, x, y = self:GetPoint()
        WLWritsDB.point = { p, rp, x, y }
    end)
    local pt = WLWritsDB.point
    if pt then frame:SetPoint(pt[1], UIParent, pt[2], pt[3], pt[4]) else frame:SetPoint("CENTER") end
    tinsert(UISpecialFrames, "WLWritsFrame")
    Solid(frame, "BACKGROUND", BG[1], BG[2], BG[3], BG[4]):SetAllPoints()
    Border(frame, 1, 1, 1, 0.08)
    local topLine = Solid(frame, "ARTWORK", ar, ag, ab, 0.9)
    topLine:SetPoint("TOPLEFT"); topLine:SetPoint("TOPRIGHT"); topLine:SetHeight(2)

    local title = Text(frame, 18)
    title:SetPoint("TOPLEFT", 14, -12)
    title:SetText(WP.NAME .. " - Writs")
    title:SetTextColor(ar, ag, ab)
    local sub = Text(frame, 11)
    sub:SetPoint("LEFT", title, "RIGHT", 10, -1)
    sub:SetText(L("Réputation des comptoirs"))
    sub:SetTextColor(1, 1, 1, 0.41)

    local close = CreateFrame("Button", nil, frame)
    close:SetSize(20, 20)
    close:SetPoint("TOPRIGHT", -8, -8)
    local x = Text(close, 16)
    x:SetPoint("CENTER"); x:SetText("x"); x:SetTextColor(1, 1, 1, 0.53)
    close:SetScript("OnEnter", function() x:SetTextColor(1, 1, 1, 1) end)
    close:SetScript("OnLeave", function() x:SetTextColor(1, 1, 1, 0.53) end)
    close:SetScript("OnClick", function() frame:Hide() end)

    -- reputation bar
    repBar = CreateFrame("StatusBar", nil, frame)
    repBar:SetPoint("TOPLEFT", 14, -40)
    repBar:SetPoint("TOPRIGHT", -14, -40)
    repBar:SetHeight(18)
    repBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    Solid(repBar, "BACKGROUND", 0, 0, 0, 0.35):SetAllPoints()
    Border(repBar, 1, 1, 1, BORDER_A * 2)
    repText = Text(repBar, 12)
    repText:SetPoint("CENTER")
    repText:SetJustifyH("CENTER")

    summary = Text(frame, 12)
    summary:SetPoint("TOPLEFT", 14, -66)
    summary:SetPoint("TOPRIGHT", -14, -66)
    summary:SetTextColor(1, 1, 1, 0.85)

    -- filters
    local db = WLWritsDB
    local chips = CreateFrame("Frame", nil, frame)
    chips:SetPoint("TOPLEFT", 14, -86)
    chips:SetSize(WIDTH - 28, 20)
    frame.chips = chips
    local list = {}
    local function add(label, get, set)
        local c = Chip(chips, label, get, set)
        if #list == 0 then c:SetPoint("LEFT") else c:SetPoint("LEFT", list[#list], "RIGHT", 6, 0) end
        list[#list + 1] = c
    end
    for _, t in ipairs(WP.TIERS) do
        add(WP.Tier(t), function() return db.tiers[t] end, function(v) db.tiers[t] = v end)
    end
    add(L("Masquer zones trop hautes"), function() return db.hideHigh end, function(v) db.hideHigh = v end)
    add(L("Masquer lieu inconnu"), function() return db.hideUnknown end, function(v) db.hideUnknown = v end)
    add(L("Masquer rendus aujourd'hui"), function() return db.hideDone end, function(v) db.hideDone = v end)
    local GOALS = { 0, 5, 6, 7 }
    local function goalText(g)
        if not g or g == 0 then return L("Objectif : rang suivant") end
        return string.format(L("Objectif : %s"), WP.Reaction(g))
    end
    local goal = Button(chips, goalText(db.goal), 150, nil)
    goal:SetHeight(20)
    goal:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -36, -10)
    goal:SetScript("OnClick", function(self)
        local i = 1
        for k, v in ipairs(GOALS) do if v == (db.goal or 0) then i = k end end
        db.goal = GOALS[i % #GOALS + 1]
        self.label:SetText(goalText(db.goal))
        WP.Refresh()
    end)
    -- GPS tour: the built-in GPS to the nearest writ ready to hand in, then the next after each one.
    frame.gps = Button(chips, "", 120, function() WP.ToggleGPS() end)
    frame.gps:SetHeight(20)
    frame.gps:SetPoint("RIGHT", goal, "LEFT", -6, 0)
    function WP.OnGPSChanged()
        frame.gps.label:SetText(WLWritsCharDB.gps and L("GPS : arrêter") or L("GPS tournée"))
    end
    WP.OnGPSChanged()
    function chips:Update() for _, c in ipairs(list) do c:Update() end end

    -- table header
    header = {}
    local hx = 12
    local headBg = Solid(frame, "ARTWORK", 1, 1, 1, 0.04)
    headBg:SetPoint("TOPLEFT", 10, -112)
    headBg:SetPoint("TOPRIGHT", -10, -112)
    headBg:SetHeight(20)
    for _, col in ipairs(COLUMNS) do
        local h = CreateFrame("Button", nil, frame)
        h:SetPoint("TOPLEFT", hx, -112)
        h:SetSize(col.width, 20)
        local lbl = Text(h, 11)
        lbl:SetAllPoints()
        lbl:SetJustifyH(col.right and "RIGHT" or "LEFT")
        lbl:SetTextColor(1, 1, 1, 0.53)
        h.label, h.title, h.key = lbl, col.title, col.key
        h:SetScript("OnClick", function()
            if db.sort == col.key then db.sortDesc = not db.sortDesc else db.sort, db.sortDesc = col.key, false end
            WP.Refresh()
        end)
        header[#header + 1] = h
        hx = hx + col.width
    end

    -- rows
    rowsUI = {}
    for i = 1, ROWS do
        local row = CreateFrame("Button", nil, frame)
        row:SetPoint("TOPLEFT", 10, -132 - (i - 1) * ROW_H)
        row:SetPoint("RIGHT", frame, "RIGHT", -18, 0)
        row:SetHeight(ROW_H)
        row:RegisterForClicks("LeftButtonUp")
        Solid(row, "BACKGROUND", 0, 0, 0, (i % 2 == 1) and ROW_ODD or ROW_EVEN):SetAllPoints()
        row.hl = Solid(row, "BORDER", ar, ag, ab, 0.10)
        row.hl:SetAllPoints()
        local hover = Solid(row, "HIGHLIGHT", 1, 1, 1, 0.06)
        hover:SetAllPoints()
        row.cells = {}
        local cx = 2
        for _, col in ipairs(COLUMNS) do
            local fs = Text(row, 12)
            fs:SetPoint("LEFT", cx, 0)
            fs:SetWidth(col.width - 6)
            fs:SetJustifyH(col.right and "RIGHT" or "LEFT")
            row.cells[col.key] = fs
            cx = cx + col.width
        end
        row:SetScript("OnEnter", Tooltip)
        row:SetScript("OnLeave", function() GameTooltip:Hide() end)
        row:SetScript("OnClick", function(self)
            if not self.data then return end
            if IsShiftKeyDown() then WP.Search({ self.data }) else WP.TravelTo(self.data.w) end
        end)
        rowsUI[i] = row
    end
    frame:EnableMouseWheel(true)
    frame:SetScript("OnMouseWheel", function(_, delta)
        offset = offset - delta * 3
        DrawRows()
    end)

    -- scroll indicator
    frame.track = Solid(frame, "ARTWORK", 1, 1, 1, 0.04)
    frame.track:SetPoint("TOPRIGHT", -10, -132)
    frame.track:SetSize(4, ROWS * ROW_H)
    frame.thumb = Solid(frame, "OVERLAY", ar, ag, ab, 0.6)
    frame.thumb:SetSize(4, 30)

    -- footer
    local footerY = -132 - ROWS * ROW_H - 8
    -- The addon's own scan: every shown writ and item not owned yet.
    frame.scan = Button(frame, L("Scanner les prix (HV)"), 170, function()
        if WP.Scan.Busy() then WP.Scan.Stop(); return end
        local ids = {}
        for _, r in ipairs(visible) do
            if r.state ~= "done" then
                if not r.ownWrit then ids[#ids + 1] = r.w.writ end
                if not r.ownItem and r.state ~= "ready" then ids[#ids + 1] = r.w.item end
            end
        end
        WP.Scan.Start(ids)
    end)
    frame.scan:SetPoint("TOPLEFT", 14, footerY)
    local shopBtn = Button(frame, L("Liste d'achat"), 110, function()
        WLWritsDB.showShop = not shop:IsShown()
        shop:SetShown(WLWritsDB.showShop)
        WP.Refresh()
    end)
    shopBtn:SetPoint("LEFT", frame.scan, "RIGHT", 6, 0)
    refresh = shopBtn
    frame.count = Text(frame, 11)
    frame.count:SetPoint("LEFT", refresh, "RIGHT", 12, 0)
    frame.count:SetTextColor(1, 1, 1, 0.41)
    pouchText = Text(frame, 11)
    pouchText:SetPoint("TOPLEFT", 14, footerY - 48)
    pouchText:SetPoint("TOPRIGHT", -14, footerY - 48)
    pouchText:SetJustifyH("LEFT")
    pouchText:SetTextColor(1, 1, 1, 0.53)
    frame.route = Text(frame, 12)
    frame.route:SetPoint("TOPLEFT", 14, footerY - 30)
    frame.route:SetPoint("TOPRIGHT", -14, footerY - 30)
    frame.route:SetTextColor(ar, ag, ab)
    sourceText = Text(frame, 10)
    sourceText:SetPoint("TOPLEFT", 14, footerY - 64)
    sourceText:SetPoint("TOPRIGHT", -14, footerY - 64)
    sourceText:SetTextColor(1, 1, 1, 0.41)

    BuildShop()
    frame:SetScript("OnShow", function() WP.Refresh() end)
    -- While the auction house is open, prices change as Auctionator scans: refresh every few seconds.
    local elapsed = 0
    frame:SetScript("OnUpdate", function(_, dt)
        elapsed = elapsed + dt
        if elapsed < 3 then return end
        elapsed = 0
        if WP.AuctionHouseOpen() and not InCombatLockdown() then
            WP.Refresh()
        end
    end)
    frame:Hide()
end

ns.Style = { Text = Text, Solid = Solid, Border = Border, Button = Button, Accent = Accent }

function WP.Toggle()
    if not frame then Build() end
    frame:SetShown(not frame:IsShown())
end
