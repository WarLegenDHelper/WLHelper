-- Writs/Home.lua: WL Helper's home page and the minimap button's tooltip and menu.
-- One card per module with where you stand (dungeon route, writs, bag items), the GPS line, then
-- "An idea, a bug?" and the settings. Opened by /wl and a click on the minimap button.
local ADDON, root = ...
root.Writs = root.Writs or {}
local ns = root.Writs
local WP = ns.WP
local L = ns.L
local S = ns.S
local C = S.C

ns.AddEnglish({
    ["%s · niv. %d"] = "%s · lvl %d",
    ["en cours"] = "in progress",
    ["Reprendre"] = "Resume",
    ["Choisir"] = "Pick",
    ["étape %d sur %d"] = "step %d of %d",
    ["Choisis un ou plusieurs donjons : la route part de ta position."] = "Pick one or several dungeons: the route starts where you stand.",
    ["%d writs prêts à rendre"] = "%d writs ready to hand in",
    ["%d enveloppes à ouvrir"] = "%d envelopes to open",
    ["Rien à rendre pour l'instant"] = "Nothing to hand in yet",
    ["Faction pas encore vue"] = "Faction not seen yet",
    ["Sacs"] = "Bags",
    ["%d objets de quête qui ne servent plus"] = "%d quest items you no longer need",
    ["Rien à jeter"] = "Nothing to throw away",
    ["vers %s"] = "to %s",
    ["Arrêter"] = "Stop",
    ["Réglages"] = "Settings",
    ["GPS"] = "GPS",
    ["Donjons"] = "Dungeons",
    ["Clic : accueil · Clic droit : menu"] = "Click: home · Right-click: menu",
    ["Glisser pour déplacer"] = "Drag to move",
    ["Arrêter le GPS"] = "Stop the GPS",
    ["%d / %d"] = "%d / %d",
    ["%d prêts"] = "%d ready",
    ["%d à jeter"] = "%d to throw away",
    ["aucun"] = "none",
    ["terminé"] = "done",
    ["Route terminée"] = "Route finished",
    ["Aucun donjon choisi"] = "No dungeon picked",
    ["Craftsman's Writs"] = "Craftsman's Writs",
    ["Zone mise de côté : Réglages › Comptoir"] = "Zone set aside: Settings › Trading Post",
    ["lieu de remise sur la carte"] = "turn-in spot on the map",
    ["niv. %d+"] = "lvl %d+",
    ["mis de côté"] = "set aside",
    ["Clic droit : ne pas le faire"] = "Right-click: skip it",
    ["Clic droit : le remettre dans le plan"] = "Right-click: back in the plan",
})

local W, PAD, CARD_H = 400, 14, 78

local function Guide() return root end
local function Version()
    local meta = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
    return meta and meta(ADDON, "Version") or "?"
end

-- ---------------------------------------------------------------- what each module has to say

local function DungeonState()
    if not root.GuideStatus then return nil end
    return root.GuideStatus()   -- three values: never through "a and f()", which keeps only one
end

local function WritState()
    local name = WP.Reputation()
    if not name then return nil end
    local need, goal = WP.RepNeeded()
    local ready, bag = 0, 0
    for _, r in ipairs(WP.Rows()) do
        if r.state == "ready" then ready = ready + 1 elseif r.state == "bag" then bag = bag + 1 end
    end
    return need, goal, ready, bag
end

local function BagCount()
    return WP.Cleaner and WP.Cleaner.Count and WP.Cleaner.Count() or 0
end

-- ---------------------------------------------------------------- the window

local win
local cards = {}

-- A module card: icon square, title, two lines, an optional bar, and a button or a chevron.
local function Card(parent, y, icon, tint, onClick)
    local c = CreateFrame("Button", nil, parent)
    c:SetHeight(CARD_H)
    c:SetPoint("TOPLEFT", PAD, y); c:SetPoint("TOPRIGHT", -PAD, y)
    S.Solid(c, "BACKGROUND", C.card):SetAllPoints()
    c.border = S.Border(c, C.border)
    c.edge = S.Solid(c, "ARTWORK", C.border)
    c.edge:SetPoint("TOPLEFT"); c.edge:SetPoint("BOTTOMLEFT"); c.edge:SetWidth(3)
    local hl = S.Solid(c, "HIGHLIGHT", { 1, 1, 1 }, 0.04); hl:SetAllPoints()

    local box = CreateFrame("Frame", nil, c)
    box:SetSize(46, 46); box:SetPoint("LEFT", 14, 0)
    S.Solid(box, "BACKGROUND", { tint[1] * 0.25, tint[2] * 0.25, tint[3] * 0.25 }):SetAllPoints()
    S.Border(box, { tint[1] * 0.55, tint[2] * 0.55, tint[3] * 0.55 })
    c.icon = box:CreateTexture(nil, "ARTWORK")
    c.icon:SetPoint("TOPLEFT", 3, -3); c.icon:SetPoint("BOTTOMRIGHT", -3, 3)
    c.icon:SetTexture(icon); c.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    c.title = S.Text(c, 18, C.text, true)
    c.title:SetPoint("TOPLEFT", box, "TOPRIGHT", 12, 1)
    c.tag = S.Text(c, 13, C.dim)
    c.tag:SetPoint("BOTTOMLEFT", c.title, "BOTTOMRIGHT", 8, 1)
    c.line1 = S.Text(c, 14, { 0.79, 0.8, 0.82 })
    c.line1:SetPoint("TOPLEFT", c.title, "BOTTOMLEFT", 0, -5)
    c.line1:SetPoint("RIGHT", c, "RIGHT", -40, 0); c.line1:SetJustifyH("LEFT"); c.line1:SetWordWrap(false)
    c.line2 = S.Text(c, 13, C.ready)
    c.line2:SetPoint("TOPLEFT", c.line1, "BOTTOMLEFT", 0, -4)
    c.line2:SetPoint("RIGHT", c, "RIGHT", -40, 0); c.line2:SetJustifyH("LEFT"); c.line2:SetWordWrap(false)
    c.bar = CreateFrame("Frame", nil, c)
    c.bar:SetHeight(4)
    c.bar:SetPoint("TOPLEFT", c.line2, "BOTTOMLEFT", 0, -6); c.bar:SetPoint("RIGHT", c, "RIGHT", -110, 0)
    S.Solid(c.bar, "BACKGROUND", C.divider):SetAllPoints()
    c.fill = S.Solid(c.bar, "ARTWORK", C.brand)
    c.fill:SetPoint("TOPLEFT"); c.fill:SetPoint("BOTTOMLEFT")

    -- a switched-off module: the card turns it back on
    local function Click()
        if c.off then return end   -- a switched-off card: only its button acts
        onClick()
    end
    c.action = S.Button(c, "", 86, 30, "primary", function()
        if c.off then WP.SetModule(c.key, true) else onClick() end
    end)
    c.action:SetPoint("RIGHT", -12, 0)
    c.chev = S.Text(c, 18, C.muted, true)
    c.chev:SetPoint("RIGHT", -14, 0); c.chev:SetText(">")
    c:SetScript("OnClick", Click)
    -- with a button on the right, the text stops before it
    function c:Narrow(on)
        local r = on and -110 or -40
        self.line1:SetPoint("RIGHT", self, "RIGHT", r, 0)
        self.line2:SetPoint("RIGHT", self, "RIGHT", r, 0)
    end
    return c
end

local function SetActive(c, on)
    local e = on and C.brand or C.border
    c.edge:SetColorTexture(e[1], e[2], e[3], 1)
end

local function Close() if win then win:Hide() end end

local function Build()
    win = S.Window("WLHelperHome", W, 10, "WL Helper", nil, WLWritsDB, "homePos")

    local y = -38 - PAD
    cards.dungeons = Card(win, y, "Interface\\Icons\\INV_Misc_Map_01", C.brandHi or C.brand, function()
        Close()
        if DungeonState() then root.ShowGuide() else root.ShowPicker() end
    end)
    y = y - CARD_H - 10
    cards.writs = Card(win, y, "Interface\\Icons\\INV_Letter_15", C.warn, function() Close(); WP.Open() end)
    y = y - CARD_H - 10
    cards.bags = Card(win, y, "Interface\\Icons\\INV_Misc_Bag_08", C.info, function()
        Close(); if WP.Cleaner then WP.Cleaner.Toggle() end
    end)
    y = y - CARD_H - 10

    -- the GPS line
    local gps = CreateFrame("Frame", nil, win)
    gps:SetHeight(40); gps:SetPoint("TOPLEFT", PAD, y); gps:SetPoint("TOPRIGHT", -PAD, y)
    S.Border(gps, C.divider)
    gps.text = S.Text(gps, 14, C.dim)
    gps.text:SetPoint("LEFT", 12, 0); gps.text:SetPoint("RIGHT", -84, 0); gps.text:SetJustifyH("LEFT"); gps.text:SetWordWrap(false)
    gps.stop = S.Button(gps, L("Arrêter"), 70, 26, "secondary", function()
        WP.StopGPS()
    end)
    gps.stop:SetPoint("RIGHT", -7, 0)
    win.gps = gps
    y = y - 40 - 14

    -- footer: an idea, the settings, the version
    local half = (W - 2 * PAD - 8) / 2
    local idea = S.Button(win, L("Une idée, un bug ?"), half, 34, "secondary", function()
        Close(); if WP.Feedback then WP.Feedback("idea") end
    end)
    idea:SetPoint("TOPLEFT", PAD, y)
    local set = S.Button(win, L("Réglages"), half, 34, "secondary", function()
        Close(); if WP.ShowOptionsPage then WP.ShowOptionsPage() end
    end)
    set:SetPoint("TOPRIGHT", -PAD, y)
    y = y - 34 - 8
    local ver = S.Text(win, 12, C.muted)
    ver:SetPoint("TOP", 0, y); ver:SetText("v" .. Version() .. " · /wl")
    win:SetHeight(-y + 12 + 14)

    cards.dungeons.key, cards.writs.key, cards.bags.key = "dungeons", "writs", "bags"
    win:SetScript("OnShow", function() WP.RefreshHome() end)
    local ev = CreateFrame("Frame", nil, win)
    ev:RegisterEvent("QUEST_LOG_UPDATE"); ev:RegisterEvent("BAG_UPDATE_DELAYED"); ev:RegisterEvent("UPDATE_FACTION")
    local queued = false
    ev:SetScript("OnEvent", function()
        if not win:IsShown() or queued then return end
        queued = true
        C_Timer.After(0.5, function() queued = false; WP.RefreshHome() end)
    end)
end

function WP.RefreshHome()
    if not (win and win:IsShown()) then return end
    local level = UnitLevel("player")
    win.subtitle:SetText(string.format(L("%s · niv. %d"), UnitName("player") or "", level or 0))

    -- dungeons
    local d = cards.dungeons
    d.title:SetText(L("Donjons"))
    local label, cur, total, finished = DungeonState()
    d.line2:SetTextColor(C.dim[1], C.dim[2], C.dim[3])
    if label and not finished then
        d.tag:SetText(L("en cours"))
        d.line1:SetText(label)
        d.line2:SetText(string.format(L("étape %d sur %d"), cur, total))
        d.bar:Show(); d.fill:SetWidth(math.max(0.01, (d.bar:GetWidth() > 0 and d.bar:GetWidth() or 200) * (cur - 1) / math.max(1, total)))
        d.action.label:SetText(L("Reprendre"))
        SetActive(d, true)
    elseif label then
        d.tag:SetText(L("terminé"))
        d.line1:SetText(label); d.line2:SetText(L("Route terminée"))
        d.bar:Hide()
        d.action.label:SetText(L("Choisir"))
        SetActive(d, false)
    else
        d.tag:SetText("")
        d.line1:SetText(L("Aucun donjon choisi"))
        d.line2:SetText(L("Choisis un ou plusieurs donjons : la route part de ta position."))
        d.line2:SetWordWrap(true)
        d.bar:Hide()
        d.action.label:SetText(L("Choisir"))
        SetActive(d, false)
    end
    d.action:Show(); d.chev:Hide(); d:Narrow(true)

    -- Trading Post
    local c = cards.writs
    c.title:SetText(L("Comptoir")); c.tag:SetText(L("Craftsman's Writs")); c.bar:Hide(); c.action:Hide(); c.chev:Show(); c:Narrow(false)
    local need, goal, ready, bag = WritState()
    if need then
        c.line1:SetText(need > 0 and string.format(L("%s dans %d rép"), WP.Reaction(goal), need) or string.format(L("%s atteint"), WP.Reaction(goal)))
        local parts = {}
        if ready > 0 then parts[#parts + 1] = string.format(L("%d writs prêts à rendre"), ready) end
        if bag > 0 then parts[#parts + 1] = string.format(L("%d enveloppes à ouvrir"), bag) end
        c.line2:SetText(#parts > 0 and table.concat(parts, " · ") or L("Rien à rendre pour l'instant"))
        c.line2:SetTextColor((#parts > 0 and C.ready or C.dim)[1], (#parts > 0 and C.ready or C.dim)[2], (#parts > 0 and C.ready or C.dim)[3])
        SetActive(c, ready > 0)
    else
        c.line1:SetText(L("Faction pas encore vue")); c.line2:SetText(""); SetActive(c, false)
    end

    -- bags
    local b = cards.bags
    b.title:SetText(L("Sacs")); b.tag:SetText(""); b.bar:Hide(); b.action:Hide(); b.chev:Show(); b.line2:SetText(""); b:Narrow(false)
    local n = BagCount()
    b.line1:SetText(n > 0 and string.format(L("%d objets de quête qui ne servent plus"), n) or L("Rien à jeter"))
    SetActive(b, false)

    -- switched-off modules: dimmed, "off", one button to turn them back on
    local hints = {}
    for _, m in ipairs(WP.MODULES) do hints[m.key] = m.hint end
    for key, card in pairs(cards) do
        card.off = not WP.ModuleOn(key)
        -- dim the card's content, never its button
        local a = card.off and 0.45 or 1
        card.icon:SetAlpha(a); card.title:SetAlpha(a); card.tag:SetAlpha(a); card.line1:SetAlpha(a); card.line2:SetAlpha(a)
        if card.off then
            card.tag:SetText(L("éteint")); card.line1:SetText(L(hints[key] or ""))
            card.line2:SetText(""); card.bar:Hide(); card.chev:Hide()
            card.action.label:SetText(L("Allumer")); card.action:Show(); card:Narrow(true)
            SetActive(card, false)
        end
    end

    -- GPS
    local g = win.gps
    if WP.GPS.Active() then
        g.text:SetText(S.Hex(C.text) .. L("GPS") .. "|r · " .. string.format(L("vers %s"), WP.GPS.DestName() or "?"))
        g.stop:Show()
    else
        g.text:SetText(L("GPS") .. " · " .. L("aucun"))
        g.stop:Hide()
    end
end

function WP.OpenHome()
    if not win then Build() end
    win:Show(); WP.RefreshHome()
end

function WP.ToggleHome()
    if not win then Build() end
    if win:IsShown() then win:Hide() else WP.OpenHome() end
end

-- ---------------------------------------------------------------- minimap button

-- Tooltip: where you stand first, then the two clicks.
function WP.MinimapTooltip(owner)
    local tt = GameTooltip
    tt:SetOwner(owner, "ANCHOR_LEFT")
    tt:AddLine("|T" .. S.LOGO .. ":16:16|t WL Helper", 1, 1, 1)
    local label, cur, total, finished = DungeonState()
    tt:AddDoubleLine(L("Donjons"), not WP.ModuleOn("dungeons") and L("éteint") or label and (label .. ", " .. (finished and L("terminé") or string.format(L("%d / %d"), cur, total))) or L("aucun"),
        C.dim[1], C.dim[2], C.dim[3], C.text[1], C.text[2], C.text[3])
    local need, _, ready = WritState()
    if not WP.ModuleOn("writs") then
        tt:AddDoubleLine(L("Comptoir"), L("éteint"), C.dim[1], C.dim[2], C.dim[3], C.dim[1], C.dim[2], C.dim[3])
    elseif need then
        local col = ready > 0 and C.ready or C.text
        tt:AddDoubleLine(L("Comptoir"), string.format(L("%d prêts"), ready), C.dim[1], C.dim[2], C.dim[3], col[1], col[2], col[3])
    end
    tt:AddDoubleLine(L("Sacs"), WP.ModuleOn("bags") and string.format(L("%d à jeter"), BagCount()) or L("éteint"),
        C.dim[1], C.dim[2], C.dim[3], C.text[1], C.text[2], C.text[3])
    tt:AddLine(" ")
    tt:AddLine(L("Clic : accueil · Clic droit : menu"), C.warn[1], C.warn[2], C.warn[3])
    tt:AddLine(L("Glisser pour déplacer"), C.dim[1], C.dim[2], C.dim[3])
    tt:Show()
end

-- Right-click menu: straight to a module.
local menu
function WP.MinimapMenu(owner)
    if not menu then
        menu = CreateFrame("Frame", "WLHelperMinimapMenu", UIParent)
        -- above minimap button bars and every window
        menu:SetFrameStrata("TOOLTIP"); menu:SetFrameLevel(50); menu:SetClampedToScreen(true); menu:EnableMouse(true)
        S.Solid(menu, "BACKGROUND", C.card):SetAllPoints()
        S.Border(menu, C.border)
        tinsert(UISpecialFrames, "WLHelperMinimapMenu")
        local items = {
            { L("Donjons"), function() if DungeonState() then root.ShowGuide() else root.ShowPicker() end end, "dungeons" },
            { L("Comptoir"), function() WP.Open() end, "writs" },
            { L("Sacs"), function() if WP.Cleaner then WP.Cleaner.Toggle() end end, "bags" },
            false,
            { L("Arrêter le GPS"), function() WP.StopGPS() end, "gps" },
            { L("Réglages"), function() if WP.ShowOptionsPage then WP.ShowOptionsPage() end end },
        }
        local y = -4
        menu.buttons = {}
        for _, it in ipairs(items) do
            if it then
                local b = S.Button(menu, it[1], 184, 26, "ghost", function() menu:Hide(); it[2]() end)
                b.label:ClearAllPoints(); b.label:SetPoint("LEFT", 10, 0)
                b:SetPoint("TOPLEFT", 4, y)
                if it[3] then menu.buttons[it[3]] = b end
                y = y - 26
            else
                local line = S.Solid(menu, "BORDER", C.divider)
                line:SetPoint("TOPLEFT", 4, y - 4); line:SetPoint("TOPRIGHT", -4, y - 4); line:SetHeight(1)
                y = y - 9
            end
        end
        menu:SetSize(192, -y + 4)
        -- closes when the mouse has left it for a moment
        menu:SetScript("OnUpdate", function(self, dt)
            if self:IsMouseOver() or (self.owner and self.owner:IsMouseOver()) then self.away = 0; return end
            self.away = (self.away or 0) + dt
            if self.away > 1.5 then self:Hide() end
        end)
    end
    if menu:IsShown() then menu:Hide(); return end
    menu.owner = owner; menu.away = 0
    menu.buttons.gps:SetEnabled(WP.GPS.Active())
    for _, k in ipairs({ "dungeons", "writs", "bags" }) do
        local b = menu.buttons[k]
        if b then b.label:SetAlpha(WP.ModuleOn(k) and 1 or 0.45) end
    end
    menu:ClearAllPoints()
    menu:SetPoint("TOPRIGHT", owner, "BOTTOMLEFT", 4, 4)
    GameTooltip:Hide()
    menu:Show()
end
