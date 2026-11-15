-- Writs/Setup.lua: the welcome screen, once, at the first login with WL Helper (and once more for
-- those who had it before the clicks went off by default). One settings row per module (name, what
-- it does, a switch), the two click shortcuts (off until you turn them on) and the minimap button.
-- Everything stays in Settings afterwards; /wlh setup opens it again. The rows scroll when the
-- screen is short; "C'est parti" always stays in view.
local ADDON, root = ...
root.Writs = root.Writs or {}
local ns = root.Writs
local WP = ns.WP
local L = ns.L
local S = ns.S
local C = S.C
local F = S.F

ns.AddEnglish({
    ["Bienvenue dans WL Helper"] = "Welcome to WL Helper",
    ["Choisis ce que tu veux utiliser. Tu pourras tout changer plus tard dans les Réglages."] =
        "Pick what you want to use. You can change all of it later in Settings.",
    ["Modules"] = "Modules",
    ["Raccourcis de clic"] = "Click shortcuts",
    ["Alt-clic pour inviter"] = "Alt-click to invite",
    ["Sur un nom dans le chat, un joueur ou un portrait. Ajoute aussi un lien [Inviter] aux demandes de groupe."] =
        "On a name in chat, a player or a portrait. Also adds an [Invite] link to group requests.",
    ["Clic droit pour tirer"] = "Right-click to shoot",
    ["Sur un ennemi : ton personnage le prend pour cible et lance ton tir à distance (arme, baguette, lancer)."] =
        "On an enemy: your character targets it and starts your ranged attack (weapon, wand, throw).",
    ["Touche à maintenir"] = "Key to hold",
    ["Avec « Aucune », le clic droit seul tire."] = "With \"None\", right-click alone shoots.",
    ["Chasseur : le clic droit seul reste ton attaque au corps-à-corps. Avec la touche, Tir automatique démarre et un second clic ne l'arrête pas : tu peux passer du tir au corps-à-corps sans rien couper."] =
        "Hunter: right-click alone stays your melee attack. With the key, Auto Shot starts and a second click never stops it: you can switch between shooting and melee freely.",
    ["Déjà géré par un autre de tes addons."] = "Already handled by another of your addons.",
    ["Bouton de la minimap"] = "Minimap button",
    ["Afficher le bouton"] = "Show the button",
    ["Un clic ouvre l'Accueil, un clic droit le menu des modules."] = "A click opens Home, a right-click the module menu.",
    ["C'est parti"] = "Let's go",
    ["Clic : fermer et commencer"] = "Click: close and start",
    ["Ouvrir le guide des gestes utiles"] = "Open the how-to guide",
    ["Clic : ouvrir Comment faire... ?"] = "Click: open How do I...?",
    ["Clic : allumer ou éteindre"] = "Click: turn on or off",
})

local W = 520
local CW = W - 32
local BAR_H = 44     -- the bottom bar: the 32 px button and its 12 px bottom pad
local win
local switches = {}

-- A settings row (design system 3.18): label 13 fg, an optional description 11 muted on its own
-- line, the control at the right edge. With a switch, the whole row is the click target.
local function Row(parent, label, desc, makeControl)
    local r = CreateFrame("Frame", nil, parent)
    r.wlOwned = true
    r.hl = S.Solid(r, "BACKGROUND", C.hoverFill); r.hl:SetAllPoints(); r.hl:SetAlpha(0)
    r.label = S.Text(r, F.body, C.fg)
    r.label:SetJustifyH("LEFT"); r.label:SetJustifyV("TOP")
    r.label:SetText(label)
    if desc then
        r.desc = S.Text(r, F.meta, C.muted)
        r.desc:SetJustifyH("LEFT"); r.desc:SetJustifyV("TOP")
        r.desc:SetText(desc)
    end
    r.control = makeControl(r)
    function r:Fit(width)
        local okW, cw = pcall(self.control.GetWidth, self.control)
        cw = (okW and type(cw) == "number") and cw or 40
        local textW = math.max(80, width - 16 - cw - 12 - 16)
        local y = 6
        local lh = math.ceil(S.FitText(self.label, 2, textW, self))
        self.label:ClearAllPoints(); self.label:SetPoint("TOPLEFT", 16, -y)
        y = y + math.max(13, lh)
        if self.desc then
            y = y + 3
            self.desc:ClearAllPoints(); self.desc:SetPoint("TOPLEFT", 16, -y)
            y = y + math.ceil(S.FitText(self.desc, 0, textW, self))
        end
        local h = math.max(36, y + 8)
        self:SetHeight(h)
        self.control:ClearAllPoints(); self.control:SetPoint("RIGHT", self, "RIGHT", -16, 0)
        return h
    end
    return r
end

local function SwitchRow(parent, label, desc, get, set, takenBy)
    local r = Row(parent, label, desc, function(row)
        return S.Switch(row, get, set)
    end)
    local sw = r.control
    switches[#switches + 1] = sw
    if takenBy then
        -- what it does stays on the row; who handles it goes in the tooltip
        sw:Disable()
        sw.disabledReason = L("Déjà géré par un autre de tes addons.")
        r:EnableMouse(true)
        r:SetScript("OnEnter", function(self)
            local lines = { label }
            if desc then lines[#lines + 1] = desc end
            lines[#lines + 1] = L("Déjà géré par un autre de tes addons.")
            S.Tip(self, lines)
        end)
        r:SetScript("OnLeave", S.HideTip)
    else
        r:EnableMouse(true)
        r:SetScript("OnEnter", function(self)
            root.Tween(self, self.hl:GetAlpha() or 0, 1, 0.10, function(v) self.hl:SetAlpha(v) end)
            local lines = { label }
            if desc then lines[#lines + 1] = desc end
            lines[#lines + 1] = L("Clic : allumer ou éteindre")
            S.Tip(self, lines)
        end)
        r:SetScript("OnLeave", function(self)
            root.Tween(self, self.hl:GetAlpha() or 0, 0, 0.10, function(v) self.hl:SetAlpha(v) end)
            S.HideTip()
        end)
        sw:AttachRow(r)
    end
    return r
end

-- A settings card: cardFill + 1 px edge, rows separated by 1 px dividers.
local function Group(parent, rows)
    local g = CreateFrame("Frame", nil, parent)
    g.wlOwned = true
    S.Solid(g, "BACKGROUND", C.cardFill):SetAllPoints()
    S.Border(g, C.cardEdge)
    g.rows, g.rules = rows, {}
    for i, r in ipairs(rows) do
        r:SetParent(g)
        if i > 1 then g.rules[i] = S.Rule(g) end
    end
    function g:Fit(width)
        local y = 0
        for i, r in ipairs(self.rows) do
            if self.rules[i] then
                self.rules[i]:ClearAllPoints()
                self.rules[i]:SetPoint("TOPLEFT", 16, -y); self.rules[i]:SetPoint("TOPRIGHT", -16, -y)
            end
            local h = r:Fit(width)
            r:ClearAllPoints(); r:SetPoint("TOPLEFT", 0, -y); r:SetPoint("TOPRIGHT", 0, -y)
            y = y + h
        end
        self:SetHeight(y)
        return y
    end
    return g
end

local function Layout()
    if not win then return end
    local inner = win.inner
    local y = 12
    local function Place(f, h, gap)
        f:ClearAllPoints()
        f:SetPoint("TOPLEFT", inner, "TOPLEFT", 16, -y)
        f:SetWidth(CW); f:SetHeight(h)
        y = y + h + (gap or 0)
    end
    win.intro:ClearAllPoints(); win.intro:SetPoint("TOPLEFT", inner, "TOPLEFT", 16, -y)
    y = y + math.ceil(S.FitText(win.intro, 0, CW, win)) + 8
    for i, block in ipairs(win.blocks) do
        if block.head then
            if i > 1 then y = y + 8 end   -- 16 above a section header (8 after the previous block's gap)
            Place(block.head, 32, 8)
        end
        if block.group then Place(block.group, block.group:Fit(CW), 8) end
        if block.banner then Place(block.banner, block.banner:Fit(CW), 8) end
    end
    local innerH = math.ceil(y - 8 - 12)
    win.scroll:SetContentHeight(innerH + 24)
    win:FitHeight(innerH + BAR_H)
    -- a rule over the bar only while the rows scroll under it
    win.barRule:SetShown(win.overflow and true or false)
end

local function Build()
    win = S.Window("WLHelperWelcome", W, 400, L("Bienvenue dans WL Helper"), nil, nil, nil, { header = 44, strata = "DIALOG", minH = 240 })
    local sa = S.ScrollArea(win)
    sa:SetPoint("TOPLEFT", win, "TOPLEFT", 0, -(win.headerH + 1))
    sa:SetPoint("BOTTOMRIGHT", win, "BOTTOMRIGHT", 0, BAR_H)
    win.scroll, win.inner = sa, sa.child
    local inner = sa.child

    win.intro = S.Text(inner, F.body, C.text)
    win.intro:SetJustifyH("LEFT"); win.intro:SetJustifyV("TOP"); win.intro:SetWordWrap(true)
    win.intro:SetText(L("Choisis ce que tu veux utiliser. Tu pourras tout changer plus tard dans les Réglages."))

    win.blocks = {}
    -- modules: one row each, with what it does
    local rows = {}
    for _, m in ipairs(WP.MODULES) do
        local key = m.key
        local name, desc = L(m.label), L(m.hint or "")
        if WP.ModuleCopy then name, desc = WP.ModuleCopy(key) end
        rows[#rows + 1] = SwitchRow(inner, name, desc ~= "" and desc or nil,
            function() return WP.ModuleOn(key) end, function(v) WP.SetModule(key, v) end)
    end
    win.blocks[#win.blocks + 1] = { head = S.SectionHeader(inner, L("Modules")), group = Group(inner, rows) }

    -- the click shortcuts, off by default
    local d = WP.ClicksDB and WP.ClicksDB()
    if d then
        local function apply() if WP.ApplyClicks then WP.ApplyClicks() end; if WP.SyncOptions then WP.SyncOptions() end end
        local crow = {}
        crow[#crow + 1] = SwitchRow(inner, L("Alt-clic pour inviter"),
            L("Sur un nom dans le chat, un joueur ou un portrait. Ajoute aussi un lien [Inviter] aux demandes de groupe."),
            function() return d.chat or d.world or d.link end,
            function(v) d.chat, d.world, d.link = v, v, v; apply() end, WP.ClickOwner and WP.ClickOwner("invite"))
        local shootTaken = WP.ClickOwner and WP.ClickOwner("shoot")
        crow[#crow + 1] = SwitchRow(inner, L("Clic droit pour tirer"),
            L("Sur un ennemi : ton personnage le prend pour cible et lance ton tir à distance (arme, baguette, lancer)."),
            function() return d.shoot end, function(v) d.shoot = v; apply() end, shootTaken)
        if not shootTaken and WP.ShootKeys then
            crow[#crow + 1] = Row(inner, L("Touche à maintenir"), L("Avec « Aucune », le clic droit seul tire."), function(row)
                local seg = S.Segmented(row, WP.ShootKeys(), function() return d.shootMod end, function(v) d.shootMod = v; apply() end, 28)
                if seg.SetMaxWidth then seg:SetMaxWidth(240) end
                return seg
            end)
        end
        local block = { head = S.SectionHeader(inner, L("Raccourcis de clic")), group = Group(inner, crow) }
        local _, class = UnitClass("player")
        if class == "HUNTER" and not shootTaken then
            block.banner = S.Banner(inner, "info", L("Chasseur : le clic droit seul reste ton attaque au corps-à-corps. Avec la touche, Tir automatique démarre et un second clic ne l'arrête pas : tu peux passer du tir au corps-à-corps sans rien couper."))
        end
        win.blocks[#win.blocks + 1] = block
    end

    -- the minimap button
    local mrow = SwitchRow(inner, L("Afficher le bouton"), L("Un clic ouvre l'Accueil, un clic droit le menu des modules."),
        function() return not (WLDTDB and WLDTDB.hideMinimap) end,
        function(v) WLDTDB.hideMinimap = not v; if WLDTMinimapButton then WLDTMinimapButton:SetShown(v) end end)
    win.blocks[#win.blocks + 1] = { head = S.SectionHeader(inner, L("Bouton de la minimap")), group = Group(inner, { mrow }) }

    -- the bottom bar: the task guide on the left, the one primary button on the right
    win.barRule = S.Rule(win)
    win.barRule:SetPoint("BOTTOMLEFT", 0, BAR_H); win.barRule:SetPoint("BOTTOMRIGHT", 0, BAR_H)
    win.go = S.Button(win, L("C'est parti"), 120, 32, "primary", function() win:Hide() end, { L("C'est parti"), L("Clic : fermer et commencer") })
    win.go:SetPoint("BOTTOMRIGHT", -16, 12)
    win.help = S.Button(win, L("Ouvrir le guide des gestes utiles"), 0, 32, "ghost", function()
        win:Hide(); if WP.Help then WP.Help.Toggle() end
    end, { L("Ouvrir le guide des gestes utiles"), L("Clic : ouvrir Comment faire... ?") })
    win.help:SetChevron(true)
    win.help:SetPoint("BOTTOMLEFT", 16 - 12, 12)

    win:HookScript("OnHide", function() WLWritsDB.welcomed = 1 end)
    win:SetScript("OnShow", function()
        Layout()
        if C_Timer and C_Timer.After then C_Timer.After(0, function() if win:IsShown() then Layout() end end) end
    end)
end

function WP.ShowWelcome()
    if InCombatLockdown() then return end
    if not win then Build() end
    for _, sw in ipairs(switches) do sw:Update() end
    win:Show(); win:Raise()
    Layout()
end

local ev = CreateFrame("Frame")
pcall(ev.RegisterEvent, ev, "PLAYER_LOGIN")
ev:SetScript("OnEvent", function()
    if WLWritsDB and not WLWritsDB.welcomed then
        C_Timer.After(4, function() if not WLWritsDB.welcomed then WP.ShowWelcome() end end)
    end
end)
