-- Writs/Options.lua: WL Helper's options window (/wlh options), one place for the dungeon guide, the
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
    ["Général"] = "General", ["Donjons"] = "Dungeons", ["Writs & Favor"] = "Writs & Favor", ["GPS"] = "GPS",
    ["Sacs"] = "Bags", ["À propos"] = "About",
    ["Rendre les caisses automatiquement"] = "Hand in crates automatically",
    ["Dokimi / Marcy Baker"] = "Dokimi / Marcy Baker",
    ["Clics"] = "Clicks",
    ["Alt-clic pour inviter (chat)"] = "Alt-click to invite (chat)",
    ["Alt-clic pour inviter (monde, portraits)"] = "Alt-click to invite (world, portraits)",
    ["Lien [Inviter] sur les demandes"] = "[Invite] link on requests",
    ["Clic droit pour tirer"] = "Right-click to shoot",
    ["Touche à tenir"] = "Key to hold",
    ["Déjà fait par %s"] = "Already done by %s",
    ["Chercher un réglage"] = "Search settings",
    ["Effacer la recherche"] = "Clear search",
    ["Aucun réglage ne correspond à « %s »."] = "No setting matches \"%s\".",
    ["%d réglages · flèches haut / bas pour choisir, Entrée pour ouvrir"] = "%d settings · up / down arrows to choose, Enter to open",
    ["1 réglage · Entrée pour l'ouvrir"] = "1 setting · Enter to open it",
    ["Ce module est éteint : Général › Modules pour le rallumer."] = "This module is off: General › Modules to turn it back on.",
    ["Modules"] = "Modules",
    ["Guide des quêtes de donjon, route, flèche"] = "Dungeon quest guide, route, arrow",
    ["Craftsman's Writs, liste d'achat, remise auto"] = "Craftsman's Writs, shopping list, auto turn-in",
    ["Nettoyeur des objets de quête inutiles"] = "Cleaner for quest items you no longer need",
    ["Faire fabriquer par la guilde, accepter des commandes"] = "Have the guild craft for you, take orders",
    ["Le GPS reste toujours actif : les autres modules s'en servent.\nRallumer un module est immédiat, sans /reload."] =
        "The GPS always stays on: the other modules use it.\nTurning a module back on is immediate, no /reload.",
    ["le module %s est éteint : Réglages › Général › Modules."] = "the %s module is off: Settings › General › Modules.",
    ["éteint"] = "off",
    ["Allumer"] = "Turn on",
    ["Zones où je vais"] = "Zones I go to",
    ["Un writ précis : clic droit dessus dans « Tous les writs »."] = "A single writ: right-click it in \"All writs\".",
    ["Formulaire GitHub prérempli"] = "Prefilled GitHub form",
    -- General
    ["Langue"] = "Language", ["Automatique"] = "Automatic", ["Français"] = "Français", ["English"] = "English",
    ["Auto suit la langue du client.\nLes fenêtres déjà ouvertes changent après un /reload."] =
        "Auto follows the client's language.\nWindows already open change after a /reload.",
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
    ["Rescanner la liste d'achat en ouvrant l'HV (Comptoir ouvert, prix de plus d'une heure)"] = "Rescan the shopping list when the AH opens (Trading Post open, prices over an hour old)",
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
    ["Commandes du chat"] = "Chat commands",
    ["Quêtes de donjon"] = "Dungeon quests",
    ["Améliorations"] = "Upgrades",
    ["Spé"] = "Spec",
    ["Calcul"] = "Calculation",
    ["Geared Forever si installé"] = "Geared Forever if installed",
    ["Geared Forever classe plus finement (par tranche de niveaux et par spé) : quand il est installé, son verdict est lu directement"] = "Geared Forever ranks more finely (per level range and spec): when it is installed, its verdict is read directly",
    ["Affichage"] = "Display",
    ["Flèche à partir de"] = "Arrow from",
    ["Le gain minimum pour montrer la flèche dans les sacs"] = "The smallest gain that shows the arrow in your bags",
    ["Ligne dans les infobulles d'objet"] = "Line in item tooltips",
    ["Poids utilisés (%s, niveaux %s)"] = "Weights used (%s, levels %s)",
    ["Dégâts des sorts"] = "Spell damage", ["Soins"] = "Healing", ["Intelligence"] = "Intellect", ["Esprit"] = "Spirit",
    ["Endurance"] = "Stamina", ["Force"] = "Strength", ["Agilité"] = "Agility", ["Puissance d'attaque"] = "Attack power",
    ["Puissance d'attaque à distance"] = "Ranged attack power", ["Critique (1 %)"] = "Crit (1%)",
    ["Critique des sorts (1 %)"] = "Spell crit (1%)", ["Toucher (1 %)"] = "Hit (1%)", ["Toucher des sorts (1 %)"] = "Spell hit (1%)",
    ["Mana toutes les 5 s"] = "Mana per 5 s", ["Armure"] = "Armor", ["Défense"] = "Defense", ["Esquive (1 %)"] = "Dodge (1%)",
    ["Parade (1 %)"] = "Parry (1%)", ["Blocage (1 %)"] = "Block (1%)", ["Valeur de blocage"] = "Block value",
    ["Dégâts par seconde de l'arme"] = "Weapon damage per second",
    ["Les poids sont ceux de WL Helper : par classe et par spé, ajustés à ta tranche de niveaux (1-20, 21-40, 41-59, 60). Les dégâts d'une école de magie comptent selon ta spé. Un objet que ta classe ne peut pas porter n'a pas de flèche."] =
        "These are WL Helper's weights: per class and spec, adjusted to your level bracket (1-20, 21-40, 41-59, 60). One school's spell damage counts for your spec. An item your class can't wear gets no arrow.",
    ["Police"] = "Font",
    ["Du jeu"] = "The game's",
    ["Celle d'EllesmereUI peut laisser des textes vides sur certaines installations"] = "EllesmereUI's may leave some texts blank on some installs",
    ["Spé jugée"] = "Spec judged",
    ["Auto : l'arbre de talents où tu as le plus de points"] = "Auto: the talent tree with the most points",
    ["Auto"] = "Auto",
    ["Alerte des monstres rares"] = "Rare monster alert",
    ["Dans un donjon, un message et un son quand un monstre rare apparaît"] = "In a dungeon, a message and a sound when a rare monster shows up",
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
    if ns.WP and ns.WP.ModuleOff and ns.WP.ModuleOff("dungeons") then return end
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
-- A page scrolls when it is taller than the window (the zone list of the Trading Post page).
-- p is the scrolled content; showing or hiding it shows or hides its scroll frame.
local function NewPage(parent)
    local sf = CreateFrame("ScrollFrame", nil, parent)
    sf:SetAllPoints()
    sf:Hide()
    local p = CreateFrame("Frame", nil, sf)
    p:SetSize(WIN_W - NAV_W - 2, 10)
    sf:SetScrollChild(p)
    sf:EnableMouseWheel(true)
    -- a thin thumb on the right says there is more below
    local thumb = S.Solid(sf, "OVERLAY", C.muted, 0.8)
    thumb:SetWidth(3)
    local function Thumb()
        local view, total = sf:GetHeight(), p:GetHeight()
        if not view or view <= 0 or total <= view + 1 then thumb:Hide(); return end
        local h = math.max(24, view * view / total)
        local off = sf:GetVerticalScroll() / (total - view)
        thumb:ClearAllPoints()
        thumb:SetPoint("TOPRIGHT", sf, "TOPRIGHT", -3, -(view - h) * off)
        thumb:SetHeight(h); thumb:Show()
    end
    sf:SetScript("OnMouseWheel", function(self, delta)
        local max = math.max(0, p:GetHeight() - self:GetHeight())
        self:SetVerticalScroll(math.max(0, math.min(max, self:GetVerticalScroll() - delta * 40)))
        Thumb()
    end)
    sf:SetScript("OnShow", Thumb)
    sf:SetScript("OnSizeChanged", Thumb)
    p.sf = sf
    function p:Show() sf:SetVerticalScroll(0); sf:Show() end
    function p:Hide() sf:Hide() end
    function p:SetShown(v) if v then self:Show() else sf:Hide() end end
    function p:IsShown() return sf:IsShown() end
    p.y, p.controls, p.first = -PAD_TOP, {}, true
    p:SetScript("OnShow", function(self)
        for _, c in ipairs(self.controls) do
            if c.Sync then c:Sync() elseif c.Update then c:Update() end
        end
    end)
    return p
end

-- ---------------------------------------------------------------- search index
-- Every row registers its page, section, label and hint while the pages are built. Text is matched
-- lower-cased and without accents, in both languages (the French key and its English text), plus a
-- few keywords, so "arrow", "fleche" and "flèche" all find the arrow settings.
local INDEX = {}
local BuildSearch   -- defined after ShowPage; builds the search box into the nav

local FOLD = { ["à"] = "a", ["â"] = "a", ["ä"] = "a", ["é"] = "e", ["è"] = "e", ["ê"] = "e", ["ë"] = "e",
    ["î"] = "i", ["ï"] = "i", ["ô"] = "o", ["ö"] = "o", ["ù"] = "u", ["û"] = "u", ["ü"] = "u", ["ç"] = "c",
    ["œ"] = "oe", ["À"] = "a", ["Â"] = "a", ["É"] = "e", ["È"] = "e", ["Ê"] = "e", ["Ë"] = "e", ["Î"] = "i", ["Ï"] = "i",
    ["Ô"] = "o", ["Ù"] = "u", ["Û"] = "u", ["Ç"] = "c", ["Œ"] = "oe", ["’"] = "'" }
-- Accents first, then lower case: lower() may touch the bytes of a UTF-8 letter on some systems.
local function Fold(t)
    t = (t or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    t = t:gsub("[\195\197\226][\128-\191]+", function(ch) return FOLD[ch] or ch end)
    return (t:lower())
end

-- The other language of a text: French keys map to English in ns.EN; English needs the reverse.
local reverse
local function OtherLanguage(t)
    if not t or not ns.EN then return "" end
    if ns.EN[t] then return ns.EN[t] end
    if not reverse then reverse = {}; for k, v in pairs(ns.EN) do reverse[v] = k end end
    return reverse[t] or ""
end

-- Words people type for things the labels say differently.
local KEYWORDS = {
    arrow = "fleche pointeur", fleche = "arrow pointeur", flight = "vol taxi", vol = "flight taxi",
    teleport = "teleportation portail mage", zygor = "guide pointeur", tooltip = "infobulle",
    infobulle = "tooltip", writ = "enveloppe", minimap = "carte bouton", langue = "language english francais",
    language = "langue", sac = "bags clean nettoyeur", bags = "sacs nettoyeur", reglage = "settings options",
}

local function Register(p, row, label, hint)
    local section = p.section or ""
    local text = table.concat({ label or "", OtherLanguage(label), hint or "", OtherLanguage(hint),
        section, OtherLanguage(section), p.pageLabel or "", OtherLanguage(p.pageLabel) }, " ")
    INDEX[#INDEX + 1] = { page = p.key, pageLabel = p.pageLabel, section = section, label = label, hint = hint,
        row = row, y = -select(5, row:GetPoint(1)), labelFold = Fold(label .. " " .. OtherLanguage(label)), all = Fold(text) }
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
    p.section = text
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
    Register(p, row, label, hint)
    return row
end

-- Anchors a control at the row's right edge (xOff leaves room for e.g. a slider's value text).
local function Place(p, row, control, xOff)
    control:ClearAllPoints()
    control:SetPoint("RIGHT", row, "RIGHT", -(xOff or 0), 0)
    if row.hint then
        row.hint:SetPoint("RIGHT", control, "LEFT", -10, 0)
        -- the hint never runs over the label: it gets the room left between them, cut with "..."
        -- when longer, and the whole text shows on the row's tooltip
        local room = (CONTENT_W - 2 * PAD_X) - (control:GetWidth() or 0) - (xOff or 0) - (row.label:GetStringWidth() or 0) - 30
        row.hint:SetWordWrap(false)
        if room < 60 then row.hint:Hide() else row.hint:SetWidth(math.min(room, row.hint:GetStringWidth() + 2)) end
        local full = row.hint:GetText()
        row:EnableMouse(true)
        row:SetScript("OnEnter", function(self) S.Tip(self, { row.label:GetText() or "", full }) end)
        row:SetScript("OnLeave", S.HideTip)
    end
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
    { key = "comptoir", label = "Writs & Favor" },
    { key = "gps",      label = "GPS" },
    { key = "bags",     label = "Sacs" },
    { key = "upgrades", label = "Améliorations" },
    { key = "about",    label = "À propos" },
}

local Rebuild   -- defined with the window: rebuilds every page after a language change

local BUILD = {}

function BUILD.general(p)
    Section(p, L("Modules"))
    for _, m in ipairs(ns.WP.MODULES) do
        SwitchRow(p, L(m.label), function() return ns.WP.ModuleOn(m.key) end,
            function(v) ns.WP.SetModule(m.key, v) end, L(m.hint))
    end
    Note(p, L("Le GPS reste toujours actif : les autres modules s'en servent.\nRallumer un module est immédiat, sans /reload."), 6)

    if ns.WP.ClicksDB then
    Section(p, L("Clics"))
    local function Clicks() return ns.WP.ClicksDB() end
    local function setClick(k) return function(v) Clicks()[k] = v; if ns.WP.ApplyClicks then ns.WP.ApplyClicks() end end end
    local inviteBy = ns.WP.ClickOwner and ns.WP.ClickOwner("invite")
    local shootBy = ns.WP.ClickOwner and ns.WP.ClickOwner("shoot")
    SwitchRow(p, L("Alt-clic pour inviter (chat)"), function() return Clicks().chat end, setClick("chat"), inviteBy and string.format(L("Déjà fait par %s"), inviteBy))
    SwitchRow(p, L("Alt-clic pour inviter (monde, portraits)"), function() return Clicks().world end, setClick("world"))
    SwitchRow(p, L("Lien [Inviter] sur les demandes"), function() return Clicks().link end, setClick("link"))
    SwitchRow(p, L("Clic droit pour tirer"), function() return Clicks().shoot end, setClick("shoot"), shootBy and string.format(L("Déjà fait par %s"), shootBy))
    local mrow = Row(p, L("Touche à tenir"))
    Place(p, mrow, S.Segmented(mrow, ns.WP.ShootKeys(),
        function() return Clicks().shootMod end, setClick("shootMod")))
    end

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
    Note(p, L("Auto suit la langue du client.\nLes fenêtres déjà ouvertes changent après un /reload."), 8)

    -- the font: the game's own (sure to show everywhere) or EllesmereUI's when it is installed
    if root.IsLoaded and root.IsLoaded("EllesmereUI") then
        Section(p, L("Police"))
        local frow = Row(p, L("Police"), L("Celle d'EllesmereUI peut laisser des textes vides sur certaines installations"))
        Place(p, frow, S.Segmented(frow, { { "game", L("Du jeu") }, { "eui", "EllesmereUI" } },
            function() return WLWritsDB.font == "eui" and "eui" or "game" end,
            function(v) WLWritsDB.font = v; if root.ApplyLooks then root.ApplyLooks() end end))
        CloseSection(p)
    end

    Section(p, L("Fenêtres"))
    SwitchRow(p, L("Bouton de la minimap"), function() return not Guide().hideMinimap end, SetMinimap)
    SwitchRow(p, L("Rouvrir le guide au chargement"), function() return Guide().reopenGuide == true end,
        function(v) Guide().reopenGuide = v end, L("même si tu l'avais fermé"))
    CloseSection(p)
end

function BUILD.dungeons(p)
    Section(p, L("Guide"))
    SwitchRow(p, L("Flèche des donjons"), function() return Guide().arrow ~= false end, SetGuideArrow)
    SwitchRow(p, L("Alerte des monstres rares"), function() return Guide().rareAlert ~= false end, function(v) Guide().rareAlert = v end,
        L("Dans un donjon, un message et un son quand un monstre rare apparaît"))
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
    SwitchRow(p, L("Rendre les caisses automatiquement"), function() return Comfort().autoCrates ~= false end, SetComfort("autoCrates"),
        L("Dokimi / Marcy Baker"))
    SwitchRow(p, L("Accepter la quête en ouvrant l'enveloppe"), function() return Comfort().autoAccept end, SetComfort("autoAccept"))
    SwitchRow(p, L("Rescanner la liste d'achat en ouvrant l'HV (Comptoir ouvert, prix de plus d'une heure)"), function() return Writs().autoRescan end,
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

    -- zones: the plan only buys writs of the zones left on (a single writ: right-click in "All writs")
    Section(p, L("Zones où je vais"))
    local maps, seen = {}, {}
    for _, w in ipairs(ns.WRITS or {}) do
        if w.map and not seen[w.map] then seen[w.map] = true; maps[#maps + 1] = w.map end
    end
    local WP = ns.WP
    table.sort(maps, function(a, b)
        local la, lb = WP.ZoneMin(a) or 0, WP.ZoneMin(b) or 0
        if la ~= lb then return la < lb end
        return WP.ZoneName(a) < WP.ZoneName(b)
    end)
    for _, map in ipairs(maps) do
        local lo = WP.ZoneMin(map)
        SwitchRow(p, WP.ZoneName(map), function() return not WP.IsSkipped("zones", map) end,
            function(v) WP.SetSkipped("zones", map, not v) end, lo and string.format(L("niv. %d+"), lo) or nil)
    end
    Note(p, L("Un writ précis : clic droit dessus dans « Tous les writs »."), 6)
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

-- Upgrades: the spec judged, the weights it uses at your level, when an arrow shows, the tooltip line.
local STAT_NAMES = {
    SP = "Dégâts des sorts", HEAL = "Soins", INT = "Intelligence", SPI = "Esprit", STA = "Endurance",
    STR = "Force", AGI = "Agilité", AP = "Puissance d'attaque", RAP = "Puissance d'attaque à distance",
    CRIT = "Critique (1 %)", SCRIT = "Critique des sorts (1 %)", HIT = "Toucher (1 %)", SHIT = "Toucher des sorts (1 %)",
    MP5 = "Mana toutes les 5 s", ARMOR = "Armure", DEF = "Défense", DODGE = "Esquive (1 %)", PARRY = "Parade (1 %)",
    BLOCK = "Blocage (1 %)", BLOCKV = "Valeur de blocage", DPS = "Dégâts par seconde de l'arme",
}
function BUILD.upgrades(p)
    local Wt = ns.WP.Weights
    if not Wt then return end
    local function SpecDB()
        WLWritsDB.upgradeSpec = WLWritsDB.upgradeSpec or {}
        local _, class = UnitClass("player")
        return WLWritsDB.upgradeSpec, class
    end
    local function Refresh() if ns.WP.RefreshUpgrades then ns.WP.RefreshUpgrades() end end
    Section(p, L("Calcul"))
    local crow = Row(p, L("Calcul"))
    Place(p, crow, S.Segmented(crow, { { "auto", L("Geared Forever si installé") }, { "wl", "WL Helper" } },
        function() return WLWritsDB.upgradeSource == "wl" and "wl" or "auto" end,
        function(v) WLWritsDB.upgradeSource = v; Refresh() end))
    CloseSection(p)
    Note(p, L("Geared Forever classe plus finement (par tranche de niveaux et par spé) : quand il est installé, son verdict est lu directement"), 4)
    Section(p, L("Spé"))
    local srow = Row(p, L("Spé jugée"))
    Place(p, srow, S.Segmented(srow, Wt.SpecChoices(),
        function() local db, c = SpecDB(); return db[c] or "auto" end,
        function(v) local db, c = SpecDB(); db[c] = v; Refresh(); if Rebuild then C_Timer.After(0, Rebuild) end end))
    CloseSection(p)
    Note(p, L("Auto : l'arbre de talents où tu as le plus de points"), 4)

    Section(p, L("Affichage"))
    local trow = Row(p, L("Flèche à partir de"))
    Place(p, trow, S.Segmented(trow, { { 1, "1 %" }, { 3, "3 %" }, { 5, "5 %" }, { 10, "10 %" } },
        function() return WLWritsDB.upgradeMin or 1 end, function(v) WLWritsDB.upgradeMin = v; Refresh() end))
    SwitchRow(p, L("Ligne dans les infobulles d'objet"), function() return WLWritsDB.upgradeTip ~= false end,
        function(v) WLWritsDB.upgradeTip = v end)
    CloseSection(p)

    local _, label = Wt.Bracket()
    Section(p, string.format(L("Poids utilisés (%s, niveaux %s)"), Wt.SpecName(), label))
    p.y = p.y - 4
    for i, e in ipairs(Wt.Table()) do
        local line = CreateFrame("Frame", nil, p)
        line:SetHeight(22)
        line:SetPoint("TOPLEFT", PAD_X, p.y); line:SetPoint("TOPRIGHT", -PAD_X, p.y)
        if i % 2 == 0 then S.Solid(line, "BACKGROUND", C.card, 0.6):SetAllPoints() end
        local name = S.Text(line, 13, C.text); name:SetPoint("LEFT", 8, 0); name:SetText(L(STAT_NAMES[e[1]] or e[1]))
        local val = S.Text(line, 13, C.brandSoft, true); val:SetPoint("RIGHT", -8, 0); val:SetText(string.format("%.2f", e[2]))
        p.y = p.y - 22
    end
    p.y = p.y - 6
    CloseSection(p)
    Note(p, L("Les poids sont ceux de WL Helper : par classe et par spé, ajustés à ta tranche de niveaux (1-20, 21-40, 41-59, 60). Les dégâts d'une école de magie comptent selon ta spé. Un objet que ta classe ne peut pas porter n'a pas de flèche."), 8)
end

local function Version()
    local meta = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
    local ok, v = pcall(meta or function() end, ADDON, "Version")
    return ok and v or "?"
end

local GITHUB = "https://github.com/WarLegenDHelper/WLHelper"
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

    Section(p, L("Commandes du chat"))
    -- the same list as /wlh help, in the guide's language
    Note(p, root.L and root.L.HELP or "/wlh")
end

-- ---------------------------------------------------------------- the window

local win, body, current

-- Builds the nav and every page into a fresh body frame (again after a language change).
local function BuildBody()
    for i = #INDEX, 1, -1 do INDEX[i] = nil end
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
        b:SetPoint("TOPLEFT", 0, -54 - (i - 1) * 38)
        b:SetPoint("TOPRIGHT", 0, -54 - (i - 1) * 38)
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
        p.key, p.pageLabel = def.key, L(def.label)
        b.count = S.Text(b, 12, C.brandSoft or C.brand, true)
        b.count:SetPoint("RIGHT", -12, 0)
        local mod = def.key == "dungeons" and "dungeons" or def.key == "comptoir" and "writs" or def.key == "bags" and "bags"
        if mod then
            local off = Note(p, L("Ce module est éteint : Général › Modules pour le rallumer."))
            off:SetTextColor(C.warn[1], C.warn[2], C.warn[3])
            p.controls[#p.controls + 1] = { Sync = function() off:SetShown(not ns.WP.ModuleOn(mod)) end }
        end
        BUILD[def.key](p)
        CloseSection(p)
        p:SetHeight(-p.y + PAD_TOP)
        body.pages[def.key] = p
    end
    BuildSearch(nav, content)
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
    win = S.Window("WLHelperOptions", WIN_W, WIN_H, TITLE, L("Réglages"), WLWritsDB, "optionsPos")
    BuildBody()
end

Rebuild = function()
    if not win then return end
    local keep = current
    body:Hide()
    body:SetParent(nil)   -- the old frames stay orphaned; a language change is rare
    BuildBody()
    win.subtitle:SetText(L("Réglages"))
    current = nil
    ns.WP.ShowOptionsPage(keep or "general")
end

-- Shows the window on a page (builds it the first time).
local ShowPage
ShowPage = function(key)
    if not body or not body.pages[key] then key = "general" end
    -- a page opened from the nav (or the window reopened) ends the search
    if body.results then body.results:Hide() end
    if body.searchBox and (body.searchBox:GetText() or "") ~= "" then
        body.searchSilent = true; body.searchBox:SetText(""); body.searchSilent = false
        if body.ClearSearch then body.ClearSearch() end
    end
    current = key
    for k, p in pairs(body.pages) do p:SetShown(k == key) end
    -- OnShow re-syncs the controls even when the page was already visible.
    local p = body.pages[key]
    local onShow = p:GetScript("OnShow")
    if p:IsShown() and onShow then onShow(p) end
    PaintNav()
end

-- ---------------------------------------------------------------- search
local RESULT_H, HEAD_H = 44, 28

BuildSearch = function(nav, content)
    local box = CreateFrame("EditBox", nil, nav)
    box:SetPoint("TOPLEFT", 10, -10); box:SetPoint("TOPRIGHT", -10, -10); box:SetHeight(32)
    box:SetAutoFocus(false)
    local probe = S.Text(nav, 14, C.text)
    local font, size, flags = probe:GetFont()
    probe:Hide()
    if font then box:SetFont(font, size or 14, flags or "") else box:SetFontObject(ChatFontNormal) end
    box:SetTextColor(C.text[1], C.text[2], C.text[3])
    box:SetTextInsets(28, 22, 0, 0)
    S.Solid(box, "BACKGROUND", C.card):SetAllPoints()
    local border = S.Border(box, C.border)
    local glass = box:CreateTexture(nil, "ARTWORK")
    glass:SetSize(14, 14); glass:SetPoint("LEFT", 8, 0); glass:SetTexture("Interface\\Common\\UI-Searchbox-Icon")
    local hint = S.Text(box, 13, C.muted)
    hint:SetPoint("LEFT", 28, 0); hint:SetText(L("Chercher un réglage"))
    local clear = CreateFrame("Button", nil, box)
    clear:SetSize(20, 20); clear:SetPoint("RIGHT", -2, 0)
    local x = S.Text(clear, 15, C.dim); x:SetPoint("CENTER"); x:SetText("×")
    clear:SetScript("OnClick", function() box:SetText(""); box:ClearFocus() end)
    clear:Hide()
    body.searchBox = box
    ns.WP.searchBox = box   -- for a key binding, and the offline tests

    -- results, in place of the page
    local sf = CreateFrame("ScrollFrame", nil, content)
    sf:SetAllPoints(); sf:Hide()
    body.results = sf
    local list = CreateFrame("Frame", nil, sf)
    list:SetSize(CONTENT_W, 10)
    sf:SetScrollChild(list)
    sf:EnableMouseWheel(true)
    sf:SetScript("OnMouseWheel", function(self, delta)
        local max = math.max(0, list:GetHeight() - self:GetHeight())
        self:SetVerticalScroll(math.max(0, math.min(max, self:GetVerticalScroll() - delta * 40)))
    end)
    local summary = S.Text(list, 13, C.dim)
    summary:SetPoint("TOPLEFT", PAD_X, -PAD_TOP); summary:SetPoint("RIGHT", -PAD_X, 0); summary:SetJustifyH("LEFT")
    local empty = S.Button(list, L("Effacer la recherche"), 170, 30, "secondary", function() box:SetText("") end)
    local heads, rows, shown, sel = {}, {}, {}, 1

    local function Head(i)
        local h = heads[i]
        if not h then h = S.Text(list, 12, C.dim, true); heads[i] = h end
        h:Show(); return h
    end
    local Pick
    local function ResultRow(i)
        local r = rows[i]
        if r then r:Show(); return r end
        r = CreateFrame("Button", nil, list)
        r:SetHeight(RESULT_H)
        r.bg = S.Solid(r, "BACKGROUND", C.brandBg or C.card, 1); r.bg:SetAllPoints(); r.bg:Hide()
        r.bar = S.Solid(r, "ARTWORK", C.brand); r.bar:SetPoint("TOPLEFT"); r.bar:SetPoint("BOTTOMLEFT"); r.bar:SetWidth(3); r.bar:Hide()
        S.Solid(r, "HIGHLIGHT", { 1, 1, 1 }, 0.04):SetAllPoints()
        r.label = S.Text(r, 15, C.text); r.label:SetPoint("TOPLEFT", 14, -6); r.label:SetPoint("RIGHT", -8, 0); r.label:SetJustifyH("LEFT")
        r.trail = S.Text(r, 13, C.dim); r.trail:SetPoint("TOPLEFT", r.label, "BOTTOMLEFT", 0, -3); r.trail:SetPoint("RIGHT", -8, 0); r.trail:SetJustifyH("LEFT")
        r:SetScript("OnClick", function(self) Pick(self.entry) end)
        rows[i] = r
        return r
    end

    local function Paint()
        for i, r in ipairs(rows) do
            local on = i == sel and r:IsShown()
            r.bg:SetShown(on); r.bar:SetShown(on)
        end
    end

    -- the found words in the brand colour, in the label as shown
    local function Mark(text, words)
        local out = text
        for _, w in ipairs(words) do
            local i, j = Fold(out):find(w, 1, true)
            if i and Fold(out) == out:lower() then
                out = out:sub(1, i - 1) .. S.Hex(C.brandSoft or C.brand) .. out:sub(i, j) .. "|r" .. out:sub(j + 1)
            end
        end
        return out
    end

    local function NavCounts(counts, searching)
        for _, b in ipairs(body.tabs) do
            local n = counts and counts[b.key] or 0
            b.count:SetText(searching and n > 0 and tostring(n) or "")
            b:SetAlpha((searching and n == 0) and 0.35 or 1)
        end
    end

    local function Update()
        local q = Fold(box:GetText() or "")
        hint:SetShown(q == ""); clear:SetShown(q ~= "")
        border(q ~= "" and C.brand or C.border)
        if #q < 2 then
            local was = sf:IsShown()
            sf:Hide(); NavCounts(nil, false)
            local page = body.pages[current]
            if was and page and not page:IsShown() then page:Show() end
            return
        end
        local words = {}
        for w in q:gmatch("%S+") do words[#words + 1] = w end
        -- every word must be found (or one of its keywords); a hit in the label ranks first
        local hits, counts = {}, {}
        for _, e in ipairs(INDEX) do
            local ok, score = true, 0
            for _, w in ipairs(words) do
                local alt = KEYWORDS[w]
                local found = e.all:find(w, 1, true)
                if not found and alt then
                    for a in alt:gmatch("%S+") do if e.all:find(a, 1, true) then found = true; break end end
                end
                if not found then ok = false; break end
                if e.labelFold:find(w, 1, true) then score = score + 2 else score = score + 1 end
            end
            if ok then hits[#hits + 1] = { e = e, score = score }; counts[e.page] = (counts[e.page] or 0) + 1 end
        end
        -- grouped by page, in the nav's order; best first inside a page
        local order = {}
        for i, t in ipairs(body.tabs) do order[t.key] = i end
        table.sort(hits, function(a, b)
            if a.e.page ~= b.e.page then return (order[a.e.page] or 99) < (order[b.e.page] or 99) end
            if a.score ~= b.score then return a.score > b.score end
            return (a.e.label or "") < (b.e.label or "")
        end)
        for _, p in pairs(body.pages) do p:Hide() end
        sf:Show(); sf:SetVerticalScroll(0)
        NavCounts(counts, true)
        for _, h in ipairs(heads) do h:Hide() end
        for _, r in ipairs(rows) do r:Hide(); r.entry = nil end
        wipe(shown)
        local y = -PAD_TOP
        summary:SetText(#hits == 0 and string.format(L("Aucun réglage ne correspond à « %s »."), box:GetText())
            or #hits == 1 and L("1 réglage · Entrée pour l'ouvrir")
            or string.format(L("%d réglages · flèches haut / bas pour choisir, Entrée pour ouvrir"), #hits))
        y = y - 26
        empty:ClearAllPoints(); empty:SetPoint("TOPLEFT", PAD_X, y); empty:SetShown(#hits == 0)
        local page, hi, ri = nil, 0, 0
        for _, h in ipairs(hits) do
            local e = h.e
            if e.page ~= page then
                page = e.page
                hi = hi + 1
                local head = Head(hi)
                head:ClearAllPoints(); head:SetPoint("TOPLEFT", PAD_X, y - 8)
                head:SetText((root.Upper and root.Upper(e.pageLabel or "") or (e.pageLabel or ""):upper()) .. " · " .. (counts[page] or 0))
                y = y - HEAD_H
            end
            ri = ri + 1
            local r = ResultRow(ri)
            r.entry = e
            r:ClearAllPoints(); r:SetPoint("TOPLEFT", PAD_X - 3, y); r:SetPoint("RIGHT", list, "RIGHT", -PAD_X, 0)
            r.label:SetText(Mark(e.label or "", words))
            local trail = (e.pageLabel or "") .. (e.section ~= "" and (" › " .. e.section) or "")
            if e.hint and e.hint ~= "" then trail = trail .. " · " .. e.hint end
            r.trail:SetText(trail)
            shown[#shown + 1] = r
            y = y - RESULT_H
        end
        list:SetHeight(-y + PAD_TOP)
        sel = 1
        Paint()
    end

    -- opens the page, scrolls the row into view and makes it flash
    local flashGen = 0
    Pick = function(e)
        if not e then return end
        sf:Hide()
        ShowPage(e.page)   -- clears the box quietly
        box:ClearFocus()
        local p = body.pages[e.page]
        local view = p.sf:GetHeight() or 400
        local max = math.max(0, p:GetHeight() - view)
        p.sf:SetVerticalScroll(math.max(0, math.min(max, (e.y or 0) - view / 3)))
        local row = e.row
        if not row.flash then row.flash = S.Solid(row, "BACKGROUND", C.brand, 0); row.flash:SetAllPoints() end
        flashGen = flashGen + 1
        local gen, t = flashGen, 0
        row.flash:SetAlpha(0.18)
        row:SetScript("OnUpdate", function(self, dt)
            t = t + dt
            if gen ~= flashGen or t >= 1.5 then self.flash:SetAlpha(0); self:SetScript("OnUpdate", nil); return end
            self.flash:SetAlpha(0.18 * (1 - t / 1.5))
        end)
    end

    box:SetScript("OnTextChanged", function() if not body.searchSilent then Update() end end)
    body.ClearSearch = function()
        hint:Show(); clear:Hide(); border(C.border); NavCounts(nil, false)
    end
    box:SetScript("OnEditFocusGained", function() border(C.brand) end)
    box:SetScript("OnEditFocusLost", function() if (box:GetText() or "") == "" then border(C.border) end end)
    box:SetScript("OnEscapePressed", function(self)
        if (self:GetText() or "") ~= "" then self:SetText("") else self:ClearFocus() end
    end)
    box:SetScript("OnEnterPressed", function(self)
        local r = shown[sel]
        if r and r.entry then Pick(r.entry) else self:ClearFocus() end
    end)
    box:SetScript("OnArrowPressed", function(_, key)
        if #shown == 0 then return end
        if key == "UP" then sel = math.max(1, sel - 1) elseif key == "DOWN" then sel = math.min(#shown, sel + 1) end
        Paint()
        -- keep the selection in view
        local r = shown[sel]
        local top = -select(5, r:GetPoint(1))
        local view = sf:GetHeight() or 400
        local cur = sf:GetVerticalScroll()
        if top < cur then sf:SetVerticalScroll(math.max(0, top - HEAD_H))
        elseif top + RESULT_H > cur + view then sf:SetVerticalScroll(top + RESULT_H - view) end
    end)

    -- Ctrl+F while the window is open: into the box (other keys go on to the game)
    -- Ctrl+F listens only out of combat, with every other key passed on to the game
    local function ArmKeys()
        if InCombatLockdown() then win:EnableKeyboard(false); return end
        win:SetPropagateKeyboardInput(true)
        win:EnableKeyboard(true)
    end
    ArmKeys()
    win:SetScript("OnKeyDown", function(_, key)
        if key == "F" and IsControlKeyDown() then box:SetFocus() end
    end)
    if not win.keysEvents then
        win.keysEvents = CreateFrame("Frame", nil, win)
        pcall(win.keysEvents.RegisterEvent, win.keysEvents, "PLAYER_REGEN_ENABLED")
        pcall(win.keysEvents.RegisterEvent, win.keysEvents, "PLAYER_REGEN_DISABLED")
    end
    win.keysEvents:SetScript("OnEvent", function(_, e)
        if e == "PLAYER_REGEN_DISABLED" then win:EnableKeyboard(false) else ArmKeys() end
    end)
end

ns.WP = ns.WP or {}

-- After a module is switched elsewhere (the home card), the open page shows it.
function ns.WP.SyncOptions()
    if win and win:IsShown() and body and body.pages[current] then
        local onShow = body.pages[current]:GetScript("OnShow")
        if onShow then onShow(body.pages[current]) end
    end
end

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

                    _, h = W:SectionHeader(parent, L("Writs & Favor"), y); y = y - h
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
pcall(ev.RegisterEvent, ev, "PLAYER_LOGIN")
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
