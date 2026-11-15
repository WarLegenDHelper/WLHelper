-- Writs/Setup.lua: the welcome screen, once, at the first login with WL Helper (and once more for
-- those who had it before the clicks went off by default). It shows each module with a switch, the
-- two click helpers (off until you turn them on) and the minimap button. Everything stays in
-- Settings afterwards; /wl setup opens it again.
local ADDON, root = ...
root.Writs = root.Writs or {}
local ns = root.Writs
local WP = ns.WP
local L = ns.L
local S = ns.S
local C = S.C

ns.AddEnglish({
    ["Bienvenue"] = "Welcome",
    ["Choisis ce que tu veux utiliser. Tout se change ensuite dans les Réglages (/wl options)."] = "Pick what you want to use. You can change all of it later in Settings (/wl options).",
    ["Modules"] = "Modules",
    ["Clics (désactivés par défaut)"] = "Clicks (off by default)",
    ["Alt-clic pour inviter"] = "Alt-click to invite",
    ["Sur un nom dans le chat, un joueur ou un portrait ; lien [Inviter] sur les demandes"] = "On a name in chat, a player or a portrait; [Invite] link on requests",
    ["Touche + clic droit pour tirer"] = "Key + right-click to shoot",
    ["Sur un ennemi : le cible et lance ton tir à distance (arme, baguette, lancer)"] = "On an enemy: targets it and starts your ranged attack (weapon, wand, throw)",
    ["Chasseur : le clic droit seul reste ton attaque au corps-à-corps. Avec la touche, Tir automatique démarre et ne s'arrête jamais sur un second clic : alterne librement pour le weaving."] =
        "Hunter: right-click alone stays your melee attack. With the key, Auto Shot starts and a second click never stops it: alternate freely for weaving.",
    ["Bouton de la minimap"] = "Minimap button",
    ["C'est parti"] = "Let's go",
    ["Déjà fait par %s"] = "Already done by %s",
})

local W, PAD = 480, 18
local win
local rows = {}

local function Line(parent, y, title, hint, get, set, disabledBy)
    local r = CreateFrame("Frame", nil, parent)
    r:SetPoint("TOPLEFT", PAD, y); r:SetPoint("TOPRIGHT", -PAD, y)
    r:SetHeight(hint and 42 or 28)
    r.title = S.Text(r, 14, C.text, true); r.title:SetPoint("TOPLEFT", 0, -2); r.title:SetText(title)
    if hint then
        r.hint = S.Text(r, 12, C.dim); r.hint:SetPoint("TOPLEFT", 0, -22); r.hint:SetPoint("RIGHT", -56, 0)
        r.hint:SetJustifyH("LEFT"); r.hint:SetText(disabledBy and string.format(L("Déjà fait par %s"), disabledBy) or hint)
    end
    r.switch = S.Switch(r, get, set)
    r.switch:SetPoint("TOPRIGHT", 0, -2)
    if disabledBy then r.switch:Disable(); r.switch:SetAlpha(0.4) end
    rows[#rows + 1] = r.switch
    return r, y - (hint and 48 or 34)
end

local function Section(parent, y, text)
    local t = S.Text(parent, 12, C.brandSoft, true)
    t:SetPoint("TOPLEFT", PAD, y); t:SetText(root.Upper and root.Upper(text) or text:upper())
    local line = S.Solid(parent, "BORDER", C.divider)
    line:SetPoint("TOPLEFT", PAD, y - 18); line:SetPoint("TOPRIGHT", -PAD, y - 18); line:SetHeight(1)
    return y - 28
end

local function Build()
    win = S.Window("WLHelperWelcome", W, 600, "WaR |cffce1918LegenD|r Helper", L("Bienvenue"), nil, nil)
    win:SetFrameStrata("DIALOG")
    local y = -54
    local intro = S.Text(win, 13, C.text)
    intro:SetPoint("TOPLEFT", PAD, y); intro:SetPoint("RIGHT", -PAD, 0)
    intro:SetJustifyH("LEFT"); intro:SetWordWrap(true)
    intro:SetText(L("Choisis ce que tu veux utiliser. Tout se change ensuite dans les Réglages (/wl options)."))
    y = y - 44

    y = Section(win, y, L("Modules"))
    for _, m in ipairs(WP.MODULES) do
        local key = m.key
        local _
        _, y = Line(win, y, L(m.label), L(m.hint), function() return WP.ModuleOn(key) end, function(v) WP.SetModule(key, v) end)
    end

    y = Section(win, y - 4, L("Clics (désactivés par défaut)"))
    local d = WP.ClicksDB and WP.ClicksDB()
    if d then
        local function apply() if WP.ApplyClicks then WP.ApplyClicks() end; if WP.SyncOptions then WP.SyncOptions() end end
        local _
        _, y = Line(win, y, L("Alt-clic pour inviter"), L("Sur un nom dans le chat, un joueur ou un portrait ; lien [Inviter] sur les demandes"),
            function() return d.chat or d.world or d.link end,
            function(v) d.chat, d.world, d.link = v, v, v; apply() end, WP.ClickOwner and WP.ClickOwner("invite"))
        local shootRow
        shootRow, y = Line(win, y, L("Touche + clic droit pour tirer"), L("Sur un ennemi : le cible et lance ton tir à distance (arme, baguette, lancer)"),
            function() return d.shoot end, function(v) d.shoot = v; apply() end, WP.ClickOwner and WP.ClickOwner("shoot"))
        local seg = S.Segmented(win, { { "SHIFT", "Maj" }, { "CTRL", "Ctrl" }, { "ALT", "Alt" } },
            function() return d.shootMod end, function(v) d.shootMod = v; apply() end, 26)
        seg:SetPoint("TOPLEFT", PAD, y + 2)
        y = y - 34
        local _, class = UnitClass("player")
        if class == "HUNTER" then
            local note = S.Text(win, 12, C.warn)
            note:SetPoint("TOPLEFT", PAD, y); note:SetPoint("RIGHT", -PAD, 0)
            note:SetJustifyH("LEFT"); note:SetWordWrap(true)
            note:SetText(L("Chasseur : le clic droit seul reste ton attaque au corps-à-corps. Avec la touche, Tir automatique démarre et ne s'arrête jamais sur un second clic : alterne librement pour le weaving."))
            y = y - 48
        end
    end

    y = Section(win, y - 4, L("Bouton de la minimap"))
    local _
    _, y = Line(win, y, L("Bouton de la minimap"), nil,
        function() return not (WLDTDB and WLDTDB.hideMinimap) end,
        function(v) WLDTDB.hideMinimap = not v; if WLDTMinimapButton then WLDTMinimapButton:SetShown(v) end end)

    local go = S.Button(win, L("C'est parti"), W - 2 * PAD, 36, "primary", function() win:Hide() end)
    go:SetPoint("TOPLEFT", PAD, y - 10)
    win:SetHeight(-(y - 10) + 36 + PAD)
    win:HookScript("OnHide", function() WLWritsDB.welcomed = 1 end)
end

function WP.ShowWelcome()
    if InCombatLockdown() then return end
    if not win then Build() end
    for _, sw in ipairs(rows) do sw:Update() end
    win:Show(); win:Raise()
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:SetScript("OnEvent", function()
    if WLWritsDB and not WLWritsDB.welcomed then
        C_Timer.After(4, function() if not WLWritsDB.welcomed then WP.ShowWelcome() end end)
    end
end)
