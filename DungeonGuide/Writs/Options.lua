-- Writs/Options.lua: WL Helper's options window (/wlo), one place for the dungeon guide, the
-- Comptoir (Craftsman's Writs), the GPS and the bag cleaner. A 720x600 window: pages listed on the
-- left, rows of "label left, control right" on the right, built lazily the first time it opens.
-- Also registers WL Helper in the game's own settings (Esc > Options > AddOns) and, when present,
-- as an EllesmereUI plugin, both pointing back to this window.
local ADDON, root = ...
root.Writs = root.Writs or {}
local ns = root.Writs
local L = ns.L
local S = ns.S
local C = S.C

ns.AddEnglish({
    -- window and pages
    ["Options"] = "Options",
    ["Général"] = "General", ["Donjons"] = "Dungeons", ["Comptoir"] = "Comptoir", ["GPS"] = "GPS",
    ["Sacs"] = "Bags", ["À propos"] = "About",
    ["Formulaire GitHub prérempli"] = "Prefilled GitHub form",
    ["/wl idee : proposer une idée ou signaler un bug"] = "/wl idea: suggest an idea or report a bug",
    -- General
    ["Langue"] = "Language", ["Automatique"] = "Automatic", ["Français"] = "Français", ["English"] = "English",
    ["Auto suit la langue du client. Les fenêtres déjà ouvertes se mettent à jour après un /reload."] =
        "Auto follows the client's language. Windows already open update after a /reload.",
    ["Fenêtres"] = "Windows",
    ["Bouton de la minimap"] = "Minimap button",
    ["Rouvrir le guide au chargement"] = "Reopen the guide on login",
    ["même si tu l'avais fermé"] = "even if you closed it",
    -- Dungeons
    ["Guide"] = "Guide",
    ["Flèche des donjons"] = "Dungeon arrow",
    ["Guide automatique des points"] = "Automatic waypoint guide",
    ["Toutes les quêtes ou seulement les utiles"] = "All quests or only the useful ones",
    ["Toutes"] = "All", ["Utiles"] = "Useful",
    -- Comptoir
    ["Automatismes"] = "Automation",
    ["Rendre les writs automatiquement"] = "Turn in writs automatically",
    ["Accepter la quête en ouvrant l'enveloppe"] = "Accept the quest when opening the envelope",
    ["Rescanner la liste d'achat en ouvrant l'HV"] = "Rescan the shopping list when the AH opens",
    ["Infos"] = "Info",
    ["Rappel à la connexion"] = "Reminder on login",
    ["« 3 prêts, 1 enveloppe à ouvrir »"] = "\"3 ready, 1 envelope to open\"",
    ["Infobulle des enveloppes"] = "Envelope tooltip",
    ["rép, coût, PNJ, déjà rendu"] = "rep, cost, NPC, already turned in",
    ["Plan"] = "Plan",
    ["Objectif"] = "Goal", ["Rang suivant"] = "Next standing",
    ["Masquer les zones trop hautes"] = "Hide zones too high",
    -- GPS
    ["Itinéraire"] = "Route",
    ["WL Helper"] = "WL Helper", ["Zygor"] = "Zygor", ["Zygor, absent"] = "Zygor, not installed",
    ["Automatique prend Zygor s'il est installé, sinon notre GPS."] = "Automatic uses Zygor when it is installed, otherwise our GPS.",
    ["Trajet"] = "Travel",
    ["Utiliser mes téléportations"] = "Use my teleports",
    ["Choisir le vol automatiquement"] = "Pick the flight automatically",
    ["Points de vol"] = "Flight paths", [" connus"] = " known",
    ["Flèche"] = "Arrow",
    ["Taille"] = "Size", ["Opacité du fond"] = "Background opacity",
    ["Masquer en combat"] = "Hide in combat",
    ["Position"] = "Position", ["Déplacer la flèche"] = "Move the arrow",
    -- Bags
    ["Nettoyage"] = "Cleanup",
    ["Objets de quête inutiles"] = "Useless quest items", ["Voir"] = "Show",
    ["Les objets qui lancent une quête ne sont jamais proposés."] = "Items that start a quest are never offered.",
    -- About
    ["Version"] = "Version", ["Auteur"] = "Author", ["Logo"] = "Logo",
    ["WaR LegenD (War Legend Raid Tool)"] = "WaR LegenD (War Legend Raid Tool)",
    ["Crédits"] = "Credits",
    ["Sources et remerciements : voir CREDITS.txt dans le dossier de l'addon."] =
        "Sources and thanks: see CREDITS.txt in the addon's folder.",
    ["GitHub"] = "GitHub", ["Clique puis Ctrl+C pour copier"] = "Click, then Ctrl+C to copy",
    ["Commandes"] = "Commands",
    ["/wl : ouvre ou ferme le guide des donjons"] = "/wl: open or close the dungeon guide",
    ["/comptoir ou /wl comptoir : fenêtre du Comptoir"] = "/comptoir or /wl comptoir: the Comptoir window",
    ["/wl gps : lance ou arrête la tournée GPS"] = "/wl gps: start or stop the GPS tour",
    ["/wlo : ces options"] = "/wlo: these options",
    -- game settings and EllesmereUI
    ["Guide des donjons, Craftsman's Writs et GPS intégré."] = "Dungeon guide, Craftsman's Writs and a built-in GPS.",
    ["Ouvrir les options"] = "Open the options",
    ["Réglages principaux. Le reste est dans la fenêtre d'options de WL Helper."] =
        "Main settings. Everything else is in WL Helper's options window.",
    ["Utiliser Zygor si présent"] = "Use Zygor when installed",
    ["Masquer la flèche en combat"] = "Hide the arrow in combat",
})

-- ---------------------------------------------------------------- settings access

local function Writs() return WLWritsDB or {} end
local function Gps() local db = Writs(); db.gpsOpts = db.gpsOpts or {}; return db.gpsOpts end
local function Comfort() local db = Writs(); db.comfort = db.comfort or {}; return db.comfort end
local function Guide() WLDTDB = WLDTDB or {}; return WLDTDB end

local function ZygorPresent() return (ZGV and ZGV.Pointer) and true or false end

-- After a change: redraw what depends on it, each call only if that module provides it.
local function RefreshWrits() if ns.WP and ns.WP.Refresh then ns.WP.Refresh() end end
local function ApplyLook()
    local G = ns.WP and ns.WP.GPS
    if G and G.ApplyLook then G.ApplyLook() end
end
local function RefreshGuide()
    if root.frame then root.frame.sig = nil end
    if root.Refresh and root.frame then root.Refresh() end
end

-- The dungeon guide's arrow: root.ToggleArrow flips WLDTDB.arrow (and stops the arrow when off).
local function SetGuideArrow(on)
    if (Guide().arrow ~= false) == on then return end
    if root.ToggleArrow then root.ToggleArrow() else Guide().arrow = on end
    if root.Render then root.Render() end
end

local function SetMinimap(shown)
    Guide().hideMinimap = not shown
    if WLDTMinimapButton then WLDTMinimapButton:SetShown(shown) end
end

local function SetComfort(key) return function(v) Comfort()[key] = v; RefreshWrits() end end
local function SetGps(key) return function(v) Gps()[key] = v; ApplyLook() end end

-- ---------------------------------------------------------------- page layout

local WIN_W, WIN_H, NAV_W = 720, 600, 170
local CONTENT_W = WIN_W - 2 - NAV_W - 1   -- window border, nav, nav divider
local PAD_X, PAD_TOP, ROW_H, SECTION_GAP = 22, 18, 48, 20

-- A page is a frame filling the content area; rows are stacked from the top with p.y as cursor.
-- Every control added with Row() is re-synced (:Update or :Sync) when the page is shown.
local function NewPage(parent)
    local p = CreateFrame("Frame", nil, parent)
    p:SetAllPoints()
    p:Hide()
    p.y, p.controls, p.first = -PAD_TOP, {}, true
    p:SetScript("OnShow", function(self)
        for _, c in ipairs(self.controls) do
            if c.Sync then c:Sync() elseif c.Update then c:Update() end
        end
    end)
    return p
end

-- The last row of a section has no divider under it.
local function CloseSection(p)
    if p.lastRow then p.lastRow.divider:Hide(); p.lastRow = nil end
end

local function Section(p, text)
    CloseSection(p)
    if not p.first then p.y = p.y - SECTION_GAP end
    p.first = false
    local fs = S.Section(p, text)
    fs:SetPoint("TOPLEFT", PAD_X, p.y)
    p.y = p.y - 18
end

-- One dim line (or a few, wrapped) under the cursor.
local function Note(p, text, gapBefore)
    if gapBefore then p.y = p.y - gapBefore end
    local fs = S.Text(p, 13, C.dim)
    fs:SetPoint("TOPLEFT", PAD_X, p.y)
    fs:SetWidth(CONTENT_W - 2 * PAD_X)   -- a fixed width so the wrapped height is known right away
    fs:SetJustifyH("LEFT")
    fs:SetJustifyV("TOP")
    fs:SetWordWrap(true)
    fs:SetText(text)
    p.y = p.y - math.max(16, math.ceil(fs:GetStringHeight() or 16)) - 2
    p.first = false
    return fs
end

-- A 48 px row: label on the left, an optional dim hint just left of the control.
local function Row(p, label, hint)
    local row = CreateFrame("Frame", nil, p)
    row:SetHeight(ROW_H)
    row:SetPoint("TOPLEFT", PAD_X, p.y)
    row:SetPoint("TOPRIGHT", -PAD_X, p.y)
    row.label = S.Text(row, 14, C.text)
    row.label:SetPoint("LEFT", 0, 0)
    row.label:SetJustifyH("LEFT")
    row.label:SetText(label)
    row.divider = S.Solid(row, "BORDER", C.divider)
    row.divider:SetPoint("BOTTOMLEFT"); row.divider:SetPoint("BOTTOMRIGHT"); row.divider:SetHeight(1)
    if hint then
        row.hint = S.Text(row, 13, C.dim)
        row.hint:SetJustifyH("RIGHT")
        row.hint:SetText(hint)
    end
    p.y = p.y - ROW_H
    p.lastRow = row
    p.first = false
    return row
end

-- Anchors a control at the row's right edge (xOff leaves room for e.g. a slider's value text).
local function Place(p, row, control, xOff)
    control:ClearAllPoints()
    control:SetPoint("RIGHT", row, "RIGHT", -(xOff or 0), 0)
    if row.hint then row.hint:SetPoint("RIGHT", control, "LEFT", -10, 0) end
    p.controls[#p.controls + 1] = control
    return control
end

local function SwitchRow(p, label, get, set, hint)
    local row = Row(p, label, hint)
    return Place(p, row, S.Switch(row, get, set))
end

-- A slider shown in percent for a value stored as a fraction (1 = 100 %).
local function PercentSlider(p, label, min, max, getFrac, setFrac)
    local row = Row(p, label)
    local s = S.Slider(row, min, max, 5,
        function() return math.floor((getFrac() or 1) * 100 + 0.5) end,
        function(v) setFrac(v / 100) end,
        function(v) return v .. " %" end, 180)
    s.value:SetJustifyH("RIGHT")
    function s:Sync() self:SetValue(math.floor((getFrac() or 1) * 100 + 0.5)) end
    return Place(p, row, s, 58)
end

-- ---------------------------------------------------------------- pages

local PAGES = {
    { key = "general",  label = "Général" },
    { key = "dungeons", label = "Donjons" },
    { key = "comptoir", label = "Comptoir" },
    { key = "gps",      label = "GPS" },
    { key = "bags",     label = "Sacs" },
    { key = "about",    label = "À propos" },
}

local Rebuild   -- defined with the window: rebuilds every page after a language change

local BUILD = {}

function BUILD.general(p)
    Section(p, L("Langue"))
    local row = Row(p, L("Langue"))
    Place(p, row, S.Segmented(row, {
        { "auto", L("Automatique") }, { "fr", L("Français") }, { "en", L("English") },
    }, function() return Guide().lang or "auto" end, function(v)
        if v == "auto" then
            -- Follow the client right away; nil in the saved variables keeps following it.
            if root.SetLang then root.SetLang((GetLocale() == "frFR") and "fr" or "en") end
            Guide().lang = nil
        elseif root.SetLang then
            root.SetLang(v)
        end
        if root.Render then root.Render() end
        if root.RenderPicker then root.RenderPicker() end
        RefreshWrits()
        -- Rebuild once the click has finished: this very control belongs to the old pages.
        C_Timer.After(0, function() if Rebuild then Rebuild() end end)
    end))
    CloseSection(p)
    Note(p, L("Auto suit la langue du client. Les fenêtres déjà ouvertes se mettent à jour après un /reload."), 8)

    Section(p, L("Fenêtres"))
    SwitchRow(p, L("Bouton de la minimap"), function() return not Guide().hideMinimap end, SetMinimap)
    SwitchRow(p, L("Rouvrir le guide au chargement"), function() return Guide().reopenGuide == true end,
        function(v) Guide().reopenGuide = v end, L("même si tu l'avais fermé"))
    CloseSection(p)
end

function BUILD.dungeons(p)
    Section(p, L("Guide"))
    SwitchRow(p, L("Flèche des donjons"), function() return Guide().arrow ~= false end, SetGuideArrow)
    SwitchRow(p, L("Guide automatique des points"), function() return Guide().autoWay and true or false end,
        function(v) Guide().autoWay = v; RefreshGuide() end)
    local row = Row(p, L("Toutes les quêtes ou seulement les utiles"))
    Place(p, row, S.Segmented(row, { { false, L("Toutes") }, { true, L("Utiles") } },
        function() return Guide().useful ~= false end,
        function(v)
            if (Guide().useful ~= false) == v then return end
            Guide().useful = v
            if root.Recalc and root.frame then root.Recalc() end
            if root.RenderPicker then root.RenderPicker() end
        end))
    CloseSection(p)
end

function BUILD.comptoir(p)
    Section(p, L("Automatismes"))
    SwitchRow(p, L("Rendre les writs automatiquement"), function() return Comfort().autoTurnIn end, SetComfort("autoTurnIn"))
    SwitchRow(p, L("Accepter la quête en ouvrant l'enveloppe"), function() return Comfort().autoAccept end, SetComfort("autoAccept"))
    SwitchRow(p, L("Rescanner la liste d'achat en ouvrant l'HV"), function() return Writs().autoRescan end,
        function(v) Writs().autoRescan = v; RefreshWrits() end)

    Section(p, L("Infos"))
    SwitchRow(p, L("Rappel à la connexion"), function() return Comfort().reminder end, SetComfort("reminder"),
        L("« 3 prêts, 1 enveloppe à ouvrir »"))
    SwitchRow(p, L("Infobulle des enveloppes"), function() return Comfort().tooltip end, SetComfort("tooltip"),
        L("rép, coût, PNJ, déjà rendu"))

    Section(p, L("Plan"))
    local row = Row(p, L("Objectif"))
    Place(p, row, S.Segmented(row, {
        { 0, L("Rang suivant") }, { 6, L("Honoré") }, { 7, L("Révéré") },
    }, function() return Writs().goal or 0 end, function(v) Writs().goal = v; RefreshWrits() end))
    SwitchRow(p, L("Masquer les zones trop hautes"), function() return Writs().hideHigh end,
        function(v) Writs().hideHigh = v; RefreshWrits() end)
    CloseSection(p)
end

function BUILD.gps(p)
    Section(p, L("Itinéraire"))
    local seg = S.Segmented(p, {
        { "auto", L("Automatique") },
        { "wl", L("WL Helper") },
        { "zygor", ZygorPresent() and L("Zygor") or L("Zygor, absent"), not ZygorPresent() },
    }, function() return Gps().provider or "auto" end, SetGps("provider"), 30)
    seg:SetPoint("TOPLEFT", PAD_X, p.y - 4)
    -- Zygor can finish loading after the window was built: re-check each time the page shows.
    function seg:Sync() self:SetDisabled("zygor", not ZygorPresent()) end
    p.controls[#p.controls + 1] = seg
    p.y = p.y - 42
    Note(p, L("Automatique prend Zygor s'il est installé, sinon notre GPS."))

    Section(p, L("Trajet"))
    SwitchRow(p, L("Utiliser mes téléportations"), function() return Gps().teleports end, SetGps("teleports"))
    SwitchRow(p, L("Choisir le vol automatiquement"), function() return Gps().autoFlight end, SetGps("autoFlight"))
    local row = Row(p, L("Points de vol"))
    local known = S.Text(row, 14, C.text)
    known:SetJustifyH("RIGHT")
    function known:Sync()
        local G = ns.WP and ns.WP.GPS
        local ok, n = pcall(function() return G and G.KnownFlights and G.KnownFlights() end)
        self:SetText((ok and n or 0) .. L(" connus"))
    end
    Place(p, row, known)

    Section(p, L("Flèche"))
    PercentSlider(p, L("Taille"), 70, 150, function() return Gps().scale end, SetGps("scale"))
    PercentSlider(p, L("Opacité du fond"), 0, 100, function() return Gps().alpha end, SetGps("alpha"))
    SwitchRow(p, L("Masquer en combat"), function() return Gps().hideCombat end, SetGps("hideCombat"))
    row = Row(p, L("Position"))
    local move = S.Button(row, L("Déplacer la flèche"), 150, 30, "secondary", function()
        local G = ns.WP and ns.WP.GPS
        if G and G.UnlockArrow then G.UnlockArrow() end
    end)
    function move:Sync()
        local G = ns.WP and ns.WP.GPS
        self:SetEnabled(G and G.UnlockArrow and true or false)
    end
    Place(p, row, move)
    CloseSection(p)
end

function BUILD.bags(p)
    Section(p, L("Nettoyage"))
    local row = Row(p, L("Objets de quête inutiles"))
    local show = S.Button(row, L("Voir"), 90, 30, "secondary", function()
        local Cl = ns.WP and ns.WP.Cleaner
        if Cl and Cl.Toggle then Cl.Toggle() end
    end)
    function show:Sync()
        local Cl = ns.WP and ns.WP.Cleaner
        self:SetEnabled(Cl and Cl.Toggle and true or false)
    end
    Place(p, row, show)
    CloseSection(p)
    Note(p, L("Les objets qui lancent une quête ne sont jamais proposés."), 8)
end

local function Version()
    local meta = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
    local ok, v = pcall(meta or function() end, ADDON, "Version")
    return ok and v or "?"
end

local GITHUB = "https://github.com/NEM3S15/WLHelper"
local TITLE = "WaR " .. S.Hex(C.danger) .. "LegenD|r Helper"

-- Selectable, read-only text: an EditBox that puts its text back if typed into.
local function CopyBox(parent, text, width)
    local eb = CreateFrame("EditBox", nil, parent)
    eb:SetSize(width, 26)
    eb:SetAutoFocus(false)
    local probe = S.Text(parent, 13, C.text)   -- borrows the theme's font
    local font, size, flags = probe:GetFont()
    probe:Hide()
    if font then eb:SetFont(font, size or 13, flags or "") else eb:SetFontObject(ChatFontNormal) end
    eb:SetTextColor(C.info[1], C.info[2], C.info[3])
    eb:SetTextInsets(8, 8, 0, 0)
    S.Solid(eb, "BACKGROUND", C.card):SetAllPoints()
    S.Border(eb, C.border)
    eb:SetText(text)
    eb:SetCursorPosition(0)
    eb:SetScript("OnTextChanged", function(self, user) if user then self:SetText(text); self:HighlightText() end end)
    eb:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
    eb:SetScript("OnMouseUp", function(self) self:SetFocus(); self:HighlightText() end)
    eb:SetScript("OnEscapePressed", function(self) self:HighlightText(0, 0); self:ClearFocus() end)
    eb:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    eb:SetScript("OnEnter", function(self) S.Tip(self, { L("Clique puis Ctrl+C pour copier") }) end)
    eb:SetScript("OnLeave", S.HideTip)
    return eb
end

function BUILD.about(p)
    local logo = p:CreateTexture(nil, "ARTWORK")
    logo:SetSize(56, 56)
    logo:SetPoint("TOPLEFT", PAD_X, p.y)
    logo:SetTexture(S.LOGO)
    local title = S.Text(p, 18, C.text, true)
    title:SetPoint("TOPLEFT", logo, "TOPRIGHT", 14, -6)
    title:SetText(TITLE)
    local ver = S.Text(p, 13, C.dim)
    ver:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    ver:SetText(L("Version") .. " " .. Version())
    p.y = p.y - 56 - 4
    p.first = false

    local function info(label, value)
        local row = Row(p, label)
        local v = S.Text(row, 14, C.text)
        v:SetJustifyH("RIGHT")
        v:SetText(value)
        Place(p, row, v)
    end
    Section(p, L("À propos"))
    info(L("Auteur"), "Alandir (WarLegend)")
    info(L("Logo"), L("WaR LegenD (War Legend Raid Tool)"))
    local row = Row(p, L("GitHub"))
    Place(p, row, CopyBox(row, GITHUB, 300))
    CloseSection(p)
    Note(p, L("Sources et remerciements : voir CREDITS.txt dans le dossier de l'addon."), 6)

    Section(p, L("Une idée, un bug ?"))
    local fb = Row(p, L("Formulaire GitHub prérempli"))
    local bIdea = S.Button(fb, L("Proposer une idée"), 150, 30, "primary", function() if WP.Feedback then WP.Feedback("idea") end end)
    local bBug = S.Button(fb, L("Signaler un bug"), 130, 30, "secondary", function() if WP.Feedback then WP.Feedback("bug") end end)
    bBug:SetPoint("RIGHT", fb, "RIGHT", 0, 0)
    Place(p, fb, bIdea)
    bIdea:ClearAllPoints(); bIdea:SetPoint("RIGHT", bBug, "LEFT", -8, 0)
    CloseSection(p)

    Section(p, L("Commandes"))
    Note(p, table.concat({
        L("/wl : ouvre ou ferme le guide des donjons"),
        L("/comptoir ou /wl comptoir : fenêtre du Comptoir"),
        L("/wl gps : lance ou arrête la tournée GPS"),
        L("/wlo : ces options"),
        L("/wl idee : proposer une idée ou signaler un bug"),
    }, "\n"))
end

-- ---------------------------------------------------------------- the window

local win, body, current

-- Builds the nav and every page into a fresh body frame (again after a language change).
local function BuildBody()
    body = CreateFrame("Frame", nil, win)
    body:SetPoint("TOPLEFT", 1, -39)
    body:SetPoint("BOTTOMRIGHT", -1, 1)

    local nav = CreateFrame("Frame", nil, body)
    nav:SetPoint("TOPLEFT"); nav:SetPoint("BOTTOMLEFT"); nav:SetWidth(NAV_W)
    local edge = S.Solid(body, "BORDER", C.divider)
    edge:SetPoint("TOPLEFT", NAV_W, 0); edge:SetPoint("BOTTOMLEFT", NAV_W, 0); edge:SetWidth(1)

    local content = CreateFrame("Frame", nil, body)
    content:SetPoint("TOPLEFT", NAV_W + 1, 0); content:SetPoint("BOTTOMRIGHT")

    body.pages, body.tabs = {}, {}
    for i, def in ipairs(PAGES) do
        local b = CreateFrame("Button", nil, nav)
        b:SetHeight(38)
        b:SetPoint("TOPLEFT", 0, -10 - (i - 1) * 38)
        b:SetPoint("TOPRIGHT", 0, -10 - (i - 1) * 38)
        b.bg = S.Solid(b, "BACKGROUND", C.card)
        b.bg:SetAllPoints()
        b.hover = S.Solid(b, "BACKGROUND", C.hover)
        b.hover:SetAllPoints()
        b.hover:Hide()
        b.bar = S.Solid(b, "ARTWORK", C.brand)
        b.bar:SetPoint("TOPLEFT"); b.bar:SetPoint("BOTTOMLEFT"); b.bar:SetWidth(3)
        b.label = S.Text(b, 15, C.dim)
        b.label:SetPoint("LEFT", 16, 0)
        b.label:SetText(L(def.label))
        b.key = def.key
        b:SetScript("OnEnter", function(self) if self.key ~= current then self.hover:Show() end end)
        b:SetScript("OnLeave", function(self) self.hover:Hide() end)
        b:SetScript("OnClick", function(self) ns.WP.ShowOptionsPage(self.key) end)
        body.tabs[i] = b

        local p = NewPage(content)
        BUILD[def.key](p)
        CloseSection(p)
        body.pages[def.key] = p
    end
end

-- Selected page: card background, 3 px brand bar, bright semi-bold label.
local function PaintNav()
    for _, b in ipairs(body.tabs) do
        local on = b.key == current
        b.bg:SetShown(on)
        b.bar:SetShown(on)
        if on then b.hover:Hide() end
        local c = on and C.text or C.dim
        b.label:SetTextColor(c[1], c[2], c[3])
        if b.label._bold ~= on and root.SetFont then b.label._bold = on; pcall(root.SetFont, b.label) end
    end
end

local function BuildWindow()
    win = S.Window("WLHelperOptions", WIN_W, WIN_H, TITLE, L("Options"), WLWritsDB, "optionsPos")
    BuildBody()
end

Rebuild = function()
    if not win then return end
    local keep = current
    body:Hide()
    body:SetParent(nil)   -- the old frames stay orphaned; a language change is rare
    BuildBody()
    win.subtitle:SetText(L("Options"))
    current = nil
    ns.WP.ShowOptionsPage(keep or "general")
end

-- Shows the window on a page (builds it the first time).
local function ShowPage(key)
    if not body or not body.pages[key] then key = "general" end
    current = key
    for k, p in pairs(body.pages) do p:SetShown(k == key) end
    -- OnShow re-syncs the controls even when the page was already visible.
    local p = body.pages[key]
    local onShow = p:GetScript("OnShow")
    if p:IsShown() and onShow then onShow(p) end
    PaintNav()
end

ns.WP = ns.WP or {}

function ns.WP.ShowOptionsPage(key)
    if not win then BuildWindow() end
    ShowPage(key or current or "general")
    win:Show()
end

-- Opens the options on a page ("general"|"dungeons"|"comptoir"|"gps"|"bags"|"about"); closes them
-- when they are already open on that page (or on any page when no page is given).
function ns.WP.OpenOptions(pageKey)
    if win and win:IsShown() and (pageKey == nil or pageKey == current) then
        win:Hide()
        return
    end
    ns.WP.ShowOptionsPage(pageKey)
end

SLASH_WLHELPEROPTIONS1 = "/wlo"
SlashCmdList.WLHELPEROPTIONS = function() ns.WP.OpenOptions() end

-- ---------------------------------------------------------------- the game's settings panel

-- The game's settings sit above our window: close them before opening it.
local function CloseGameSettings()
    if SettingsPanel and SettingsPanel:IsShown() then
        if HideUIPanel then pcall(HideUIPanel, SettingsPanel) else SettingsPanel:Hide() end
    end
    if InterfaceOptionsFrame and InterfaceOptionsFrame:IsShown() then
        if HideUIPanel then pcall(HideUIPanel, InterfaceOptionsFrame) else InterfaceOptionsFrame:Hide() end
    end
end

local function OpenFromOutside()
    CloseGameSettings()
    ns.WP.ShowOptionsPage(current or "general")
end

-- A small canvas: logo, title, one line and a button that opens our own window.
local function RegisterGameSettings()
    local panel = CreateFrame("Frame")
    panel.name = "WL Helper"
    local logo = panel:CreateTexture(nil, "ARTWORK")
    logo:SetSize(64, 64)
    logo:SetPoint("TOPLEFT", 16, -16)
    logo:SetTexture(S.LOGO)
    local title = S.Text(panel, 20, C.text, true)
    title:SetPoint("TOPLEFT", logo, "TOPRIGHT", 14, -8)
    title:SetText(TITLE)
    local desc = S.Text(panel, 14, C.dim)
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
    desc:SetText(L("Guide des donjons, Craftsman's Writs et GPS intégré.") .. "   v" .. Version())
    local open = S.Button(panel, L("Ouvrir les options"), 200, 32, "primary", OpenFromOutside)
    open:SetPoint("TOPLEFT", logo, "BOTTOMLEFT", 0, -20)

    if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
        local ok, category = pcall(Settings.RegisterCanvasLayoutCategory, panel, panel.name)
        if ok and category then
            pcall(Settings.RegisterAddOnCategory, category)
            return
        end
    end
    if InterfaceOptions_AddCategory then pcall(InterfaceOptions_AddCategory, panel) end
end

-- ---------------------------------------------------------------- EllesmereUI plugin

-- One page with the settings people change most, through EUI's documented widgets only, and a
-- button to our full window.
local function RegisterEllesmere()
    if not (EllesmereUI and EllesmereUI.RegisterPlugin) then return end
    if EllesmereUI.IsPluginRegistered and EllesmereUI.IsPluginRegistered("WLHelper") then return end
    pcall(EllesmereUI.RegisterPlugin, "WLHelper", {
        label = "WL Helper",
        modules = {
            {
                key = "Main",
                title = "WL Helper",
                description = L("Réglages principaux. Le reste est dans la fenêtre d'options de WL Helper."),
                pages = { L("Options") },
                buildPage = function(pageName, parent, yOffset)
                    local W = EllesmereUI.Widgets
                    local y = yOffset
                    local _, h
                    local function toggle(label, get, set)
                        _, h = W:Toggle(parent, label, y, get, set); y = y - h
                    end
                    _, h = W:SectionHeader(parent, L("Général"), y); y = y - h
                    toggle(L("Bouton de la minimap"), function() return not Guide().hideMinimap end, SetMinimap)
                    toggle(L("Flèche des donjons"), function() return Guide().arrow ~= false end, SetGuideArrow)

                    _, h = W:SectionHeader(parent, L("Comptoir"), y); y = y - h
                    toggle(L("Rendre les writs automatiquement"), function() return Comfort().autoTurnIn end, SetComfort("autoTurnIn"))
                    toggle(L("Accepter la quête en ouvrant l'enveloppe"), function() return Comfort().autoAccept end, SetComfort("autoAccept"))

                    _, h = W:SectionHeader(parent, L("GPS"), y); y = y - h
                    toggle(L("Utiliser Zygor si présent"), function() return Gps().provider ~= "wl" end,
                        function(v) SetGps("provider")(v and "auto" or "wl") end)
                    toggle(L("Utiliser mes téléportations"), function() return Gps().teleports end, SetGps("teleports"))
                    toggle(L("Masquer la flèche en combat"), function() return Gps().hideCombat end, SetGps("hideCombat"))

                    -- Our own button (not indexed by EUI's search); no frames during the search pre-build.
                    y = y - 16
                    local prebuild = EllesmereUI.IsSearchPrebuild and EllesmereUI.IsSearchPrebuild()
                    if not prebuild then
                        local b = S.Button(parent, L("Ouvrir les options"), 200, 30, "primary", OpenFromOutside)
                        b:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, y)
                    end
                    y = y - 30 - 16
                    return math.abs(y)
                end,
            },
        },
    })
end

-- ---------------------------------------------------------------- login

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:SetScript("OnEvent", function(self)
    self:UnregisterEvent("PLAYER_LOGIN")
    -- Main.lua shows the guide two seconds after login unless WLDTDB.hidden: clearing it here
    -- (this file loads last, so this runs after Main's handler) reopens a closed guide.
    if WLDTDB and WLDTDB.reopenGuide then WLDTDB.hidden = false end
    local ok, err = pcall(RegisterGameSettings)
    if not ok and geterrorhandler then geterrorhandler()(err) end
    ok, err = pcall(RegisterEllesmere)
    if not ok and geterrorhandler then geterrorhandler()(err) end
end)
