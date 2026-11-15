-- Writs/Setup.lua: the welcome, once, at the first login with WL Helper; /wlh setup opens it again.
-- A short onboarding, one decision per screen: hello (what WL Helper does), what interests you (six
-- cards that switch the modules), your spec (only when the game does not let us read the talents),
-- the two click shortcuts (off until you turn them on) and the minimap button, then where to start.
-- Every choice is saved as it is made, so closing early keeps it; everything stays in Settings.
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
    ["Étape %d sur %d"] = "Step %d of %d",
    -- hello
    ["Salut %s !"] = "Hi %s!",
    ["Salut !"] = "Hi!",
    ["WL Helper te guide dans tes quêtes de donjon et t'aide à monter ta Faveur du marchand, avec toute la guilde."] =
        "WL Helper guides you through your dungeon quests and helps you raise your Merchant's Favor, with the whole guild.",
    ["Les quêtes de tes donjons, dans le bon ordre, avec une flèche."] = "Your dungeon quests in the right order, with an arrow.",
    ["Les Writs les moins chers et où les rendre."] = "The cheapest Writs and where to turn them in.",
    ["Les événements de la guilde et les commandes aux artisans."] = "Guild events and orders to crafters.",
    ["Une minute pour tout régler. Tout se change ensuite dans les Réglages."] =
        "One minute to set it up. You can change everything later in Settings.",
    ["Passer"] = "Skip",
    ["Garde les réglages conseillés."] = "Keeps the recommended settings.",
    ["Clic : fermer"] = "Click: close",
    ["Commencer"] = "Get started",
    ["Retour"] = "Back",
    ["Continuer"] = "Continue",
    ["Terminer"] = "Finish",
    -- interests
    ["Qu'est-ce qui t'intéresse ?"] = "What are you interested in?",
    ["Tout est allumé, c'est conseillé. Éteins seulement ce que tu ne veux pas voir."] =
        "Everything is on, which we recommend. Switch off only what you don't want to see.",
    ["Allume ce qui te sert, éteins le reste."] = "Switch on what you use, switch off the rest.",
    ["Ce que tu éteins se cache. Tout se rallume dans les Réglages."] =
        "What you switch off is hidden. Everything can be switched back on in Settings.",
    ["Guide de quêtes"] = "Quest guide",
    ["Donjons, raids et quêtes de classe, avec une flèche qui te guide."] = "Dungeons, raids and class quests, with an arrow that guides you.",
    ["Writs et Faveur"] = "Writs and Favor",
    ["Les Writs (contrats des marchands) les moins chers et les caisses de la Faveur du marchand."] =
        "The cheapest Writs (merchant contracts) and the Merchant's Favor crates.",
    ["Sacs"] = "Bags",
    ["Une place libre en un clic, et les objets gris vendus chez le marchand."] = "A free slot in one click, and grey items sold at the vendor.",
    ["Commandes"] = "Orders",
    ["Demande un objet aux artisans de la guilde, ou fabrique pour eux."] = "Ask the guild's crafters for an item, or craft for them.",
    ["Guilde et événements"] = "Guild and events",
    ["Les membres, le classement PvP, les événements prévus et qui cherche un groupe."] =
        "Members, the PvP ranking, planned events and who is looking for a group.",
    ["Améliorations"] = "Upgrades",
    ["Une flèche verte sur les objets meilleurs que les tiens."] = "A green arrow on items better than yours.",
    ["Clic : allumer ou éteindre"] = "Click: turn on or off",
    -- spec
    ["Quelle spé joues-tu ?"] = "Which spec do you play?",
    ["Le jeu ne nous laisse pas lire tes talents. Les flèches vertes des Améliorations dépendent de ta spé."] =
        "The game doesn't let us read your talents. The green Upgrades arrows depend on your spec.",
    ["Pas encore de talents ? Choisis ce que tu comptes jouer."] = "No talents yet? Pick what you plan to play.",
    ["Clic : juger les objets pour cette spé"] = "Click: judge items for this spec",
    ["Je ne sais pas encore"] = "I don't know yet",
    ["WL Helper prendra la spé la plus courante de ta classe. Tu pourras la changer dans Réglages, Améliorations."] =
        "WL Helper will use your class's most common spec. You can change it in Settings, Upgrades.",
    ["Tank"] = "Tank",
    ["Soigneur"] = "Healer",
    ["DPS"] = "DPS",
    ["Tank ou DPS"] = "Tank or DPS",
    -- comfort
    ["Raccourcis de clic"] = "Click shortcuts",
    ["Deux gestes pratiques, éteints au départ. Ils changent ce que fait un clic : allume-les seulement si tu en as envie."] =
        "Two handy shortcuts, off to start with. They change what a click does, so switch them on only if you want them.",
    ["Alt-clic pour inviter"] = "Alt-click to invite",
    ["Alt + clic sur un nom dans le chat ou sur un joueur : il reçoit une invitation de groupe. Un lien [Inviter] s'ajoute aussi aux messages qui demandent une invitation."] =
        "Alt + click a name in chat or a player: they get a group invite. An [Invite] link is also added to messages asking for an invite.",
    ["Clic droit pour tirer"] = "Right-click to shoot",
    ["Clic droit sur un ennemi : tu le prends pour cible et tu tires (arc, fusil, arbalète, baguette ou arme de jet)."] =
        "Right-click an enemy: you target it and shoot (bow, gun, crossbow, wand or thrown weapon).",
    ["%s + clic droit sur un ennemi : tu le prends pour cible et tu tires (arc, fusil, arbalète, baguette ou arme de jet)."] =
        "%s + right-click an enemy: you target it and shoot (bow, gun, crossbow, wand or thrown weapon).",
    ["Touche à maintenir"] = "Key to hold",
    ["Avec « Aucune », le clic droit seul tire."] = "With \"None\", right-click alone shoots.",
    ["Chasseur : le clic droit seul reste ton attaque au corps-à-corps, %s + clic droit lance Tir automatique, et un second clic ne l'arrête pas : tu passes de l'un à l'autre sans rien couper."] =
        "Hunter: right-click alone stays your melee attack, %s + right-click starts Auto Shot, and a second click never stops it: you can switch between the two without breaking anything.",
    ["Chasseur : avec « Aucune », le clic droit tire toujours et ne lance plus ton attaque au corps-à-corps. Garde plutôt une touche, Maj par exemple."] =
        "Hunter: with \"None\", right-click always shoots and no longer starts your melee attack. Better keep a key, Shift for example.",
    ["Déjà géré par un autre de tes addons."] = "Already handled by another of your addons.",
    ["Ces raccourcis sont déjà gérés par un autre de tes addons."] = "These shortcuts are already handled by another of your addons.",
    ["Bouton de la minimap"] = "Minimap button",
    ["Afficher le bouton"] = "Show the button",
    ["Un clic ouvre l'Accueil, un clic droit le menu de WL Helper."] = "A click opens Home, a right-click the WL Helper menu.",
    -- ready
    ["C'est prêt !"] = "You're all set!",
    ["Par quoi veux-tu commencer ?"] = "Where do you want to start?",
    ["Choisir les donjons"] = "Pick dungeons",
    ["Le guide te donne leurs quêtes dans le bon ordre."] = "The guide gives you their quests in the right order.",
    ["Les moins chers à l'HV et la Faveur qu'ils rapportent."] = "The cheapest at the AH and the Favor they bring.",
    ["Comment faire... ?"] = "How do I...?",
    ["Les gestes utiles pas à pas, avec le bon bouton qui s'allume."] = "Handy how-tos step by step, with the right button lit up.",
    ["Ouvrir l'Accueil"] = "Open Home",
    ["Tout ce que tu as allumé, en un coup d'œil."] = "Everything you switched on, at a glance.",
    ["Clic : ouvrir le choix des donjons"] = "Click: open dungeon picking",
    ["Clic : ouvrir Comment faire... ?"] = "Click: open How do I...?",
    ["Clic : ouvrir l'Accueil"] = "Click: open Home",
    ["Pour tout retrouver"] = "To find it all again",
    ["Le bouton WL de la minimap ouvre l'Accueil."] = "The WL button on the minimap opens Home.",
    ["Le bouton de la minimap est caché : Réglages, Général pour le remettre."] = "The minimap button is hidden: Settings, General brings it back.",
    ["Tape /wlh dans le chat pour ouvrir l'Accueil."] = "Type /wlh in chat to open Home.",
    ["Tout se change dans les Réglages, et /wlh setup rouvre cet écran de bienvenue."] =
        "Everything can be changed in Settings, and /wlh setup opens this welcome again.",
    ["Écran de bienvenue fermé : tes choix sont gardés. Tape /wlh setup pour le rouvrir."] =
        "Welcome closed: your choices are kept. Type /wlh setup to open it again.",
    ["L'écran de bienvenue s'ouvrira à la fin du combat."] = "The welcome will open once combat ends.",
    -- "Voir les Writs" and "Clic : ouvrir les Writs" come from Home.lua (same words everywhere)
})

local W = 520
local CW = W - 32       -- content width
local BAR_H = 56        -- the bottom bar: 12 pad, 32 controls, 12 pad
local MIN_BODY = 260    -- the body never gets shorter than this: the bottom edge does not jump
local CARD_W = 238      -- interests: two columns of cards, 12 apart
local TILE_W = math.floor((CW - 24) / 3)
local win
local switches = {}
local texts = {}        -- every FontString of the window (the tests check none is cut)

local function Icon(name) return "Interface\\Icons\\" .. name end
local function PlayerClass() local _, c = UnitClass("player"); return c end
local function MinimapShown() return not (WLDTDB and WLDTDB.hideMinimap) end

-- a paragraph: wraps without a line limit (no cut text), sized by FitText at layout time
local function Txt(parent, size, color, justify)
    local fs = S.Text(parent, size, color)
    fs:SetJustifyH(justify or "LEFT"); fs:SetJustifyV("TOP")
    fs:SetWordWrap(true)
    texts[#texts + 1] = fs
    return fs
end

-- a painted game icon in a frame with a 1 px cardEdge border
local function PaintedIcon(parent, size, path)
    local fr = CreateFrame("Frame", nil, parent)
    fr:SetSize(size, size)
    fr.tex = fr:CreateTexture(nil, "ARTWORK"); fr.tex:SetAllPoints()
    if path then S.Painted(fr.tex, path) end
    S.Border(fr, C.cardEdge)
    return fr
end

local function Hover(frame, on)
    root.Tween(frame, frame.hl:GetAlpha() or 0, on and 1 or 0, 0.10, function(v) frame.hl:SetAlpha(v) end)
end

-- OnLeave also fires when the cursor moves onto a child (the switch): still inside means keep the
-- hover fill and the tooltip.
local function MouseStillIn(frame)
    local ok, over = pcall(frame.IsMouseOver, frame)
    return ok and over == true
end

-- the switch of a row or card: leaving it out of the row ends the row's hover too
local function KeepHoverOver(sw, row)
    if not sw.HookScript then return end
    sw:HookScript("OnLeave", function()
        if not MouseStillIn(row) then Hover(row, false); S.HideTip() end
    end)
end

-- ---------------------------------------------------------------- settings rows (comfort step)

-- A settings row (design system 3.18): label 13 fg, an optional description 11 muted on its own
-- line, the control at the right edge. With a switch, the whole row is the click target.
-- desc is a string or a function (re-read at every Fit, for a description that names a setting).
local function Row(parent, label, desc, makeControl)
    local r = CreateFrame("Frame", nil, parent)
    r.wlOwned = true
    r.hl = S.Solid(r, "BACKGROUND", C.hoverFill); r.hl:SetAllPoints(); r.hl:SetAlpha(0)
    r.label = Txt(r, F.body, C.fg)
    r.label:SetText(label)
    r.descOf = function() if type(desc) == "function" then return desc() end return desc end
    if desc then
        r.desc = Txt(r, F.meta, C.muted)
        r.desc:SetText(r.descOf())
    end
    r.control = makeControl(r)
    function r:Fit(width)
        if self.desc then self.desc:SetText(self.descOf() or "") end
        local okW, cw = pcall(self.control.GetWidth, self.control)
        cw = (okW and type(cw) == "number") and cw or 40
        local textW = math.max(80, width - 16 - cw - 12 - 16)
        local y = 6
        local lh = math.ceil(S.FitText(self.label, 0, textW, self))
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
    r.sw = sw
    switches[#switches + 1] = sw
    r:EnableMouse(true)
    if takenBy then
        -- what it does stays on the row; who handles it goes in the tooltip
        sw:Disable()
        sw.disabledReason = L("Déjà géré par un autre de tes addons.")
        r:SetScript("OnEnter", function(self)
            local lines = { label }
            if desc then lines[#lines + 1] = self.descOf() end
            lines[#lines + 1] = L("Déjà géré par un autre de tes addons.")
            S.Tip(self, lines)
        end)
        r:SetScript("OnLeave", function(self) if not MouseStillIn(self) then S.HideTip() end end)
    else
        r:SetScript("OnEnter", function(self)
            Hover(self, true)
            local lines = { label }
            if desc then lines[#lines + 1] = self.descOf() end
            lines[#lines + 1] = L("Clic : allumer ou éteindre")
            S.Tip(self, lines)
        end)
        r:SetScript("OnLeave", function(self)
            if MouseStillIn(self) then return end   -- onto the switch: keep the hover and the tip
            Hover(self, false); S.HideTip()
        end)
        sw:AttachRow(r)
        KeepHoverOver(sw, r)
    end
    return r
end

-- A settings card: cardFill + 1 px edge, rows separated by 1 px dividers. A row with wlHidden
-- set is left out (progressive disclosure) and the card shrinks.
local function Group(parent, rows)
    local g = CreateFrame("Frame", nil, parent)
    g.wlOwned = true
    S.Solid(g, "BACKGROUND", C.cardFill):SetAllPoints()
    S.Border(g, C.cardEdge)
    g.rows, g.rules = rows, {}
    for i, r in ipairs(rows) do
        r:SetParent(g)
        g.rules[i] = S.Rule(g)
    end
    function g:Fit(width)
        local y, n = 0, 0
        for i, r in ipairs(self.rows) do
            local rule = self.rules[i]
            if r.wlHidden then
                r:Hide(); rule:Hide()
            else
                n = n + 1
                r:Show()
                rule:SetShown(n > 1)
                rule:ClearAllPoints()
                rule:SetPoint("TOPLEFT", 16, -y); rule:SetPoint("TOPRIGHT", -16, -y)
                local h = r:Fit(width)
                r:ClearAllPoints(); r:SetPoint("TOPLEFT", 0, -y); r:SetPoint("TOPRIGHT", 0, -y)
                y = y + h
            end
        end
        self:SetHeight(math.max(1, y))
        return y
    end
    return g
end

-- ---------------------------------------------------------------- interests: module cards

-- A module card (238 wide): painted icon 32, switch at the top right, title 14 fg (2 lines),
-- description 11 muted. The whole card toggles; an off module's icon goes grey.
local function ModuleCard(parent, def)
    local c = CreateFrame("Frame", nil, parent)
    c.wlOwned = true
    c.def = def
    S.Solid(c, "BACKGROUND", C.cardFill):SetAllPoints()
    c.hl = S.Solid(c, "BORDER", C.hoverFill); c.hl:SetAllPoints(); c.hl:SetAlpha(0)
    S.Border(c, C.cardEdge)
    c.iconFrame = PaintedIcon(c, 32, Icon(def.icon))
    c.iconFrame:SetPoint("TOPLEFT", 12, -12)
    c.title = Txt(c, F.heading, C.fg)
    c.desc = Txt(c, F.meta, C.muted)
    c.sw = S.Switch(c, def.get, function(v)
        def.set(v)
        c:Paint()
        if win and win.Relayout then win.Relayout() end
    end)
    c.sw:SetPoint("TOPRIGHT", -12, -12)
    switches[#switches + 1] = c.sw
    c:EnableMouse(true)
    c:SetScript("OnEnter", function(self)
        Hover(self, true)
        S.Tip(self, { self.def.title(), self.def.desc(), L("Clic : allumer ou éteindre") })
    end)
    c:SetScript("OnLeave", function(self)
        if MouseStillIn(self) then return end   -- onto the switch: keep the hover and the tip
        Hover(self, false); S.HideTip()
    end)
    c.sw:AttachRow(c)
    KeepHoverOver(c.sw, c)
    function c:Paint()
        local on = self.def.get() and true or false
        if self.iconFrame.tex.SetDesaturated then self.iconFrame.tex:SetDesaturated(not on) end
        self.iconFrame:SetAlpha(on and 1 or 0.55)
    end
    function c:Fit(width)
        self.title:SetText(self.def.title())
        self.desc:SetText(self.def.desc())
        local textX = 52
        local th = math.ceil(S.FitText(self.title, 2, width - textX - 12 - 40 - 8, self))
        self.title:ClearAllPoints(); self.title:SetPoint("TOPLEFT", textX, -12)
        local dh = math.ceil(S.FitText(self.desc, 0, width - textX - 12, self))
        -- the description runs the full width, so it starts under the switch (12 + 20) as well
        local dy = math.max(12 + th + 3, 12 + 20 + 6)
        self.desc:ClearAllPoints(); self.desc:SetPoint("TOPLEFT", textX, -dy)
        self:Paint()
        return math.max(72, dy + dh + 12)
    end
    return c
end

-- ---------------------------------------------------------------- spec tiles

-- [class][spec key] = { painted icon, role }. Spec keys and names come from Weights.lua.
local SPEC_ART = {
    WARRIOR = { arms = { "Ability_Warrior_SavageBlow", "dps" }, fury = { "Ability_Warrior_InnerRage", "dps" }, prot = { "Ability_Warrior_DefensiveStance", "tank" } },
    PALADIN = { holy = { "Spell_Holy_HolyBolt", "heal" }, prot = { "Spell_Holy_DevotionAura", "tank" }, ret = { "Spell_Holy_AuraOfLight", "dps" } },
    HUNTER = { bm = { "Ability_Hunter_BeastTaming", "dps" }, mm = { "Ability_Marksmanship", "dps" }, surv = { "Ability_Hunter_SwiftStrike", "dps" } },
    ROGUE = { assa = { "Ability_Rogue_Eviscerate", "dps" }, combat = { "Ability_BackStab", "dps" }, sub = { "Ability_Stealth", "dps" } },
    PRIEST = { disc = { "Spell_Holy_WordFortitude", "heal" }, holy = { "Spell_Holy_Renew", "heal" }, shadow = { "Spell_Shadow_ShadowWordPain", "dps" } },
    SHAMAN = { ele = { "Spell_Nature_Lightning", "dps" }, enh = { "Spell_Nature_LightningShield", "dps" }, resto = { "Spell_Nature_MagicImmunity", "heal" } },
    MAGE = { arcane = { "Spell_Holy_MagicalSentry", "dps" }, fire = { "Spell_Fire_FireBolt02", "dps" }, frost = { "Spell_Frost_FrostBolt02", "dps" } },
    WARLOCK = { aff = { "Spell_Shadow_DeathCoil", "dps" }, demo = { "Spell_Shadow_Metamorphosis", "dps" }, destro = { "Spell_Shadow_RainOfFire", "dps" } },
    DRUID = { balance = { "Spell_Nature_StarFall", "dps" }, feral = { "Ability_Racial_BearForm", "feral" }, resto = { "Spell_Nature_HealingTouch", "heal" } },
}
local function RoleWord(role)
    if role == "tank" then return L("Tank") end
    if role == "heal" then return L("Soigneur") end
    if role == "feral" then return L("Tank ou DPS") end
    return L("DPS")
end

local function SpecPick(class)
    local p = WLWritsDB and WLWritsDB.upgradeSpec and WLWritsDB.upgradeSpec[class]
    return p
end
local function SaveSpec(class, key)
    WLWritsDB.upgradeSpec = WLWritsDB.upgradeSpec or {}
    WLWritsDB.upgradeSpec[class] = key
    local Wt = WP.Weights
    if Wt and Wt.Reset then Wt.Reset() end
    if WP.RefreshUpgrades then WP.RefreshUpgrades() end
end

-- A spec tile (154 wide): painted spec icon 40 centred, name 13 fg (2 lines), role line 11 muted.
-- Rest cardFill + cardEdge; hover hoverFill; selected selFill + 1 px accent border.
local function SpecTile(parent, spec, iconPath, role, class)
    local t = CreateFrame("Button", nil, parent)
    t.wlOwned = true
    t.key, t.spec, t.role = spec[1], spec, role
    S.Solid(t, "BACKGROUND", C.cardFill):SetAllPoints()
    t.sel = S.Solid(t, "BORDER", C.selFill); t.sel:SetAllPoints(); t.sel:Hide()
    t.hl = S.Solid(t, "BORDER", C.hoverFill); t.hl:SetAllPoints(); t.hl:SetAlpha(0)
    t.edge = S.Border(t, C.cardEdge)
    t.iconFrame = PaintedIcon(t, 40)
    t.iconFrame:SetPoint("TOP", 0, -12)
    local ok, loaded = pcall(t.iconFrame.tex.SetTexture, t.iconFrame.tex, Icon(iconPath))
    t.iconFrame.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    if not ok or loaded == false then S.ClassIcon(t.iconFrame.tex, class) end
    t.name = Txt(t, F.body, C.fg, "CENTER")
    t.roleIcon = t:CreateTexture(nil, "ARTWORK"); t.roleIcon:SetSize(12, 12)
    S.RoleIcon(t.roleIcon, role == "feral" and "tank" or role)
    t.roleText = Txt(t, F.meta, C.muted)
    local function Name()
        local Wt = WP.Weights
        return Wt and Wt.SpecName and Wt.SpecName(spec) or spec[2]
    end
    function t:SetSelected(on)
        self.selected = on and true or false
        self.sel:SetShown(self.selected)
        if self.selected then self.edge(C.accent, 1) else self.edge(C.cardEdge) end
    end
    function t:Fit(width)
        self.name:SetText(Name())
        self.roleText:SetText(RoleWord(role))
        local y = 12 + 40 + 8
        local nh = math.ceil(S.FitText(self.name, 2, width - 16, self))
        self.name:ClearAllPoints(); self.name:SetPoint("TOP", 0, -y)
        y = y + nh + 3
        local tw = math.min(math.ceil(root.TextWidth(self.roleText)) + 2, width - 16 - 16)
        local rh = math.ceil(S.FitText(self.roleText, 0, tw, self))
        local x0 = math.floor((width - (16 + tw)) / 2)
        self.roleIcon:ClearAllPoints(); self.roleIcon:SetPoint("TOPLEFT", x0, -(y + 1))
        self.roleText:ClearAllPoints(); self.roleText:SetPoint("TOPLEFT", x0 + 16, -y)
        return math.max(100, y + math.max(12, rh) + 12)
    end
    t:SetScript("OnEnter", function(self)
        Hover(self, true)
        S.Tip(self, { Name(), RoleWord(role), L("Clic : juger les objets pour cette spé") })
    end)
    t:SetScript("OnLeave", function(self) Hover(self, false); S.HideTip() end)
    t:SetScript("OnClick", function(self)
        if PlaySound then PlaySound(SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or 856) end
        SaveSpec(class, self.key)
        if win and win.Relayout then win.Relayout() end
    end)
    t:SetSelected(false)
    return t
end

-- ---------------------------------------------------------------- the steps

-- The spec step shows when Upgrades is on, the class has specs, and the talents cannot be read
-- (or /wlh setup reopened it after a manual pick, so the pick can change). Once shown in this
-- welcome it stays in the list, so picking a spec does not make the step vanish under you.
local function SpecWanted()
    if not WP.ModuleOn("upgrades") then return false end
    local Wt, class = WP.Weights, PlayerClass()
    if not (Wt and Wt.SPECS and class and Wt.SPECS[class]) then return false end
    if win and win.specSticky then return true end
    local want = Wt.SpecGuessed and Wt.SpecGuessed() or false
    if not want and win and win.fromCommand then
        local p = SpecPick(class)
        want = p ~= nil and p ~= "auto"
    end
    if want and win then win.specSticky = true end
    return want and true or false
end

local function Steps()
    local list = { "hello", "interests" }
    if SpecWanted() then list[#list + 1] = "spec" end
    list[#list + 1] = "comfort"
    list[#list + 1] = "ready"
    return list
end

local Go, Next, Finish
local STEPS = {}

-- D1. hello: the value first
STEPS.hello = {
    Build = function(f)
        f.logo = f:CreateTexture(nil, "ARTWORK")
        f.logo:SetSize(48, 48); f.logo:SetTexture(S.LOGO)
        f.head = Txt(f, F.title, C.fg, "CENTER")
        f.value = Txt(f, F.body, C.text, "CENTER")
        f.lines = {}
        for i, icon in ipairs({ "INV_Misc_Map_01", "INV_Letter_15", "Ability_Warrior_BattleShout" }) do
            local ln = { icon = PaintedIcon(f, 28, Icon(icon)), text = Txt(f, F.body, C.fg) }
            f.lines[i] = ln
        end
        f.foot = Txt(f, F.meta, C.muted, "CENTER")
    end,
    Layout = function(f)
        local name
        local ok, n = pcall(UnitName, "player")
        if ok and type(n) == "string" and n ~= "" and not (root.IsSecret and root.IsSecret(n)) then name = n end
        f.head:SetText(name and string.format(L("Salut %s !"), name) or L("Salut !"))
        f.value:SetText(L("WL Helper te guide dans tes quêtes de donjon et t'aide à monter ta Faveur du marchand, avec toute la guilde."))
        local words = {
            L("Les quêtes de tes donjons, dans le bon ordre, avec une flèche."),
            L("Les Writs les moins chers et où les rendre."),
            L("Les événements de la guilde et les commandes aux artisans."),
        }
        f.foot:SetText(L("Une minute pour tout régler. Tout se change ensuite dans les Réglages."))
        local BW = 400
        local y = 8
        f.logo:ClearAllPoints(); f.logo:SetPoint("TOP", f, "TOP", 0, -y)
        y = y + 48 + 12
        local function Centre(fs, gap)
            local h = math.ceil(S.FitText(fs, 0, BW, f))
            fs:ClearAllPoints(); fs:SetPoint("TOP", f, "TOP", 0, -y)
            y = y + h + (gap or 0)
        end
        Centre(f.head, 6)
        Centre(f.value, 16)
        local x0 = math.floor((CW - BW) / 2)
        for i, ln in ipairs(f.lines) do
            ln.text:SetText(words[i])
            local th = math.ceil(S.FitText(ln.text, 0, BW - 36, f))
            local rh = math.max(28, th)
            ln.icon:ClearAllPoints(); ln.icon:SetPoint("TOPLEFT", f, "TOPLEFT", x0, -(y + math.floor((rh - 28) / 2)))
            ln.text:ClearAllPoints(); ln.text:SetPoint("TOPLEFT", f, "TOPLEFT", x0 + 36, -(y + math.floor((rh - th) / 2)))
            y = y + rh + (i < #f.lines and 8 or 0)
        end
        y = y + 16
        Centre(f.foot, 0)
        return y
    end,
}

-- D2. what interests you: six cards over the seven module keys (guild and events go together)
local function ModuleDefs()
    local function one(key) return function() return WP.ModuleOn(key) end, function(v) WP.SetModule(key, v) end end
    local defs = {
        { keys = { "dungeons" }, icon = "INV_Misc_Map_01", title = function() return L("Guide de quêtes") end,
          desc = function() return L("Donjons, raids et quêtes de classe, avec une flèche qui te guide.") end },
        { keys = { "writs" }, icon = "INV_Letter_15", title = function() return L("Writs et Faveur") end,
          desc = function() return L("Les Writs (contrats des marchands) les moins chers et les caisses de la Faveur du marchand.") end },
        { keys = { "bags" }, icon = "INV_Misc_Bag_08", title = function() return L("Sacs") end,
          desc = function() return L("Une place libre en un clic, et les objets gris vendus chez le marchand.") end },
        { keys = { "orders" }, icon = "Trade_BlackSmithing", title = function() return L("Commandes") end,
          desc = function() return L("Demande un objet aux artisans de la guilde, ou fabrique pour eux.") end },
        { keys = { "guild", "events" }, icon = "Ability_Warrior_BattleShout", title = function() return L("Guilde et événements") end,
          desc = function() return L("Les membres, le classement PvP, les événements prévus et qui cherche un groupe.") end },
        { keys = { "upgrades" }, icon = "INV_Chest_Cloth_17", title = function() return L("Améliorations") end,
          desc = function() return L("Une flèche verte sur les objets meilleurs que les tiens.") end },
    }
    for _, d in ipairs(defs) do
        if #d.keys == 1 then
            d.get, d.set = one(d.keys[1])
        else
            d.get = function() return WP.ModuleOn("guild") or WP.ModuleOn("events") end
            d.set = function(v) WP.SetModule("guild", v); WP.SetModule("events", v) end
        end
    end
    return defs
end

STEPS.interests = {
    Build = function(f)
        f.title = Txt(f, F.heading, C.fg)
        f.text = Txt(f, F.body, C.text)
        f.cards = {}
        for i, def in ipairs(ModuleDefs()) do f.cards[i] = ModuleCard(f, def) end
        f.note = Txt(f, F.meta, C.muted)
    end,
    Enter = function(f) for _, c in ipairs(f.cards) do c.sw:Update() end end,
    Layout = function(f)
        local allOn = true
        for _, c in ipairs(f.cards) do if not c.def.get() then allOn = false end end
        f.title:SetText(L("Qu'est-ce qui t'intéresse ?"))
        f.text:SetText(allOn and L("Tout est allumé, c'est conseillé. Éteins seulement ce que tu ne veux pas voir.") or L("Allume ce qui te sert, éteins le reste."))
        local y = 0
        f.title:ClearAllPoints(); f.title:SetPoint("TOPLEFT", 0, -y)
        y = y + math.ceil(S.FitText(f.title, 0, CW, f)) + 4
        f.text:ClearAllPoints(); f.text:SetPoint("TOPLEFT", 0, -y)
        y = y + math.ceil(S.FitText(f.text, 0, CW, f)) + 12
        for row = 0, 2 do
            local a, b = f.cards[row * 2 + 1], f.cards[row * 2 + 2]
            local h = math.max(a:Fit(CARD_W), b:Fit(CARD_W))
            for col, c in ipairs({ a, b }) do
                c:SetSize(CARD_W, h)
                c:ClearAllPoints(); c:SetPoint("TOPLEFT", (col - 1) * (CARD_W + 12), -y)
            end
            y = y + h + (row < 2 and 12 or 0)
        end
        f.note:SetText(L("Ce que tu éteins se cache. Tout se rallume dans les Réglages."))
        y = y + 8
        f.note:ClearAllPoints(); f.note:SetPoint("TOPLEFT", 0, -y)
        y = y + math.ceil(S.FitText(f.note, 0, CW, f))
        return y
    end,
}

-- D3. your spec (only when the talents cannot be read)
STEPS.spec = {
    Build = function(f)
        f.title = Txt(f, F.heading, C.fg)
        f.text = Txt(f, F.body, C.text)
        f.classIcon = f:CreateTexture(nil, "ARTWORK"); f.classIcon:SetSize(20, 20)
        f.className = Txt(f, F.body, C.fg)
        f.tiles = {}   -- [class] = { tile, tile, tile }
        f.unsure = S.Button(f, L("Je ne sais pas encore"), 0, 24, "ghost", function()
            local class = PlayerClass()
            if class then SaveSpec(class, "auto") end
            if win and win.Relayout then win.Relayout() end
            Next()
        end, { L("Je ne sais pas encore"), L("WL Helper prendra la spé la plus courante de ta classe. Tu pourras la changer dans Réglages, Améliorations.") })
        texts[#texts + 1] = f.unsure.label
    end,
    Layout = function(f)
        local class = PlayerClass()
        local Wt = WP.Weights
        local list = Wt and Wt.SPECS and class and Wt.SPECS[class] or {}
        f.title:SetText(L("Quelle spé joues-tu ?"))
        local lvl = UnitLevel and UnitLevel("player")
        if type(lvl) == "number" and lvl < 10 then
            f.text:SetText(L("Pas encore de talents ? Choisis ce que tu comptes jouer."))
        else
            f.text:SetText(L("Le jeu ne nous laisse pas lire tes talents. Les flèches vertes des Améliorations dépendent de ta spé."))
        end
        local y = 0
        f.title:ClearAllPoints(); f.title:SetPoint("TOPLEFT", 0, -y)
        y = y + math.ceil(S.FitText(f.title, 0, CW, f)) + 4
        f.text:ClearAllPoints(); f.text:SetPoint("TOPLEFT", 0, -y)
        y = y + math.ceil(S.FitText(f.text, 0, CW, f)) + 8
        -- the class line: icon 20, the class name in its colour
        local cname = UnitClass("player")
        local cc = class and ((CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[class]) or (RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]))
        f.classIcon:SetShown(S.ClassIcon(f.classIcon, class) and true or false)
        f.className:SetText(type(cname) == "string" and cname or "")
        if cc then f.className:SetTextColor(cc.r, cc.g, cc.b) else f.className:SetTextColor(C.fg[1], C.fg[2], C.fg[3]) end
        local nh = math.ceil(S.FitText(f.className, 0, CW - 28, f))
        local lh = math.max(20, nh)
        f.classIcon:ClearAllPoints(); f.classIcon:SetPoint("TOPLEFT", 0, -(y + math.floor((lh - 20) / 2)))
        f.className:ClearAllPoints(); f.className:SetPoint("TOPLEFT", 28, -(y + math.floor((lh - nh) / 2)))
        y = y + lh + 12
        -- the tiles of this class (built once per class)
        for k, set in pairs(f.tiles) do if k ~= class then for _, t in ipairs(set) do t:Hide() end end end
        local set = class and f.tiles[class]
        if class and not set then
            set = {}
            local art = SPEC_ART[class] or {}
            for i, s in ipairs(list) do
                local a = art[s[1]] or {}
                set[i] = SpecTile(f, s, a[1] or "INV_Misc_QuestionMark", a[2] or "dps", class)
            end
            f.tiles[class] = set
        end
        set = set or {}
        local pick = class and SpecPick(class)
        local th = 0
        for _, t in ipairs(set) do th = math.max(th, t:Fit(TILE_W)) end
        for i, t in ipairs(set) do
            t:Show()
            t:SetSelected(pick ~= nil and pick ~= "auto" and pick == t.key)
            t:SetSize(TILE_W, th)
            t:ClearAllPoints(); t:SetPoint("TOPLEFT", (i - 1) * (TILE_W + 12), -y)
        end
        f.shownTiles = set
        y = y + th + 12
        f.unsure:ClearAllPoints(); f.unsure:SetPoint("TOPLEFT", -12, -y)
        y = y + 24
        return y
    end,
}

-- D4. the click shortcuts (off by default) and the minimap button

-- the name of the key held for right-click shoot ("Maj", "Ctrl"...), nil for NONE
local function ShootKeyLabel(d)
    local mod = d and d.shootMod
    if not mod or mod == "NONE" then return nil end
    for _, k in ipairs(WP.ShootKeys and WP.ShootKeys() or {}) do
        if k[1] == mod then return k[2] end
    end
    return mod
end
STEPS.comfort = {
    Build = function(f)
        f.title = Txt(f, F.heading, C.fg)
        f.text = Txt(f, F.body, C.text)
        local d = WP.ClicksDB and WP.ClicksDB()
        f.d = d
        if d then
            local function apply() if WP.ApplyClicks then WP.ApplyClicks() end; if WP.SyncOptions then WP.SyncOptions() end end
            local inviteTaken = WP.ClickOwner and WP.ClickOwner("invite")
            local shootTaken = WP.ClickOwner and WP.ClickOwner("shoot")
            f.shootTaken = shootTaken
            f.allTaken = inviteTaken and shootTaken
            local rows = {}
            f.invite = SwitchRow(f, L("Alt-clic pour inviter"),
                L("Alt + clic sur un nom dans le chat ou sur un joueur : il reçoit une invitation de groupe. Un lien [Inviter] s'ajoute aussi aux messages qui demandent une invitation."),
                function() return d.chat or d.world or d.link end,
                function(v) d.chat, d.world, d.link = v, v, v; apply() end, inviteTaken)
            rows[#rows + 1] = f.invite
            -- the description names the key to hold (Shift for most classes), so a right-click alone
            -- is not read as the shortcut
            f.shoot = SwitchRow(f, L("Clic droit pour tirer"),
                function()
                    local key = ShootKeyLabel(d)
                    if not key then
                        return L("Clic droit sur un ennemi : tu le prends pour cible et tu tires (arc, fusil, arbalète, baguette ou arme de jet).")
                    end
                    return string.format(L("%s + clic droit sur un ennemi : tu le prends pour cible et tu tires (arc, fusil, arbalète, baguette ou arme de jet)."), key)
                end,
                function() return d.shoot end,
                function(v)
                    d.shoot = v
                    -- mages, priests and warlocks: the wand line below switches on with it, once
                    if v and WP.OfferWand then WP.OfferWand() end
                    apply(); if win and win.Relayout then win.Relayout() end
                end, shootTaken)
            rows[#rows + 1] = f.shoot
            if not shootTaken and WP.ShootKeys then
                f.key = Row(f, L("Touche à maintenir"), L("Avec « Aucune », le clic droit seul tire."), function(row)
                    local seg = S.Segmented(row, WP.ShootKeys(), function() return d.shootMod end, function(v)
                        d.shootMod = v; apply()
                        if win and win.Relayout then win.Relayout() end
                    end, 28)
                    if seg.SetMaxWidth then seg:SetMaxWidth(240) end
                    return seg
                end)
                rows[#rows + 1] = f.key
                -- wand classes (and anyone with a wand): right-click alone shoots the wand
                if WP.WandOption then
                    f.wand = SwitchRow(f, L("Clic droit simple = baguette"),
                        L("Avec une baguette, un clic droit seul sur un ennemi lance Tir au lieu de ton attaque au corps-à-corps. Maintenu sur un ennemi, il ne tourne plus la caméra."),
                        function() return d.wandRight end,
                        function(v)
                            if WP.OfferWand then WP.OfferWand() end   -- your own choice wins from now on
                            d.wandRight = v and true or false; apply()
                        end)
                    rows[#rows + 1] = f.wand
                end
            end
            f.group = Group(f, rows)
            f.banner = S.Banner(f, "info", "")
            texts[#texts + 1] = f.banner.text
            f.taken = Txt(f, F.body, C.muted)
        end
        f.mmHead = S.SectionHeader(f, L("Bouton de la minimap"))
        f.mmRow = SwitchRow(f, L("Afficher le bouton"), L("Un clic ouvre l'Accueil, un clic droit le menu de WL Helper."),
            MinimapShown,
            function(v)
                WLDTDB = WLDTDB or {}
                WLDTDB.hideMinimap = not v
                if WLDTMinimapButton then WLDTMinimapButton:SetShown(v) end
            end)
        f.mmGroup = Group(f, { f.mmRow })
    end,
    Enter = function(f)
        for _, r in ipairs({ f.invite, f.shoot, f.wand, f.mmRow }) do if r and r.sw then r.sw:Update() end end
        if f.key and f.key.control.Update then f.key.control:Update() end
    end,
    Layout = function(f)
        f.title:SetText(L("Raccourcis de clic"))
        f.text:SetText(L("Deux gestes pratiques, éteints au départ. Ils changent ce que fait un clic : allume-les seulement si tu en as envie."))
        local y = 0
        f.title:ClearAllPoints(); f.title:SetPoint("TOPLEFT", 0, -y)
        y = y + math.ceil(S.FitText(f.title, 0, CW, f)) + 4
        f.text:ClearAllPoints(); f.text:SetPoint("TOPLEFT", 0, -y)
        y = y + math.ceil(S.FitText(f.text, 0, CW, f)) + 12
        local d = f.d
        if d then
            local shootOn = d.shoot and not f.shootTaken
            if f.key then f.key.wlHidden = not shootOn end
            -- the wand line: shooting on, a key held (with "None" right-click already shoots), and a
            -- wand class or a wand in the ranged slot
            if f.wand then f.wand.wlHidden = not (shootOn and d.shootMod ~= "NONE" and WP.WandOption()) end
            if f.allTaken then
                f.group:Hide()
                f.taken:SetText(L("Ces raccourcis sont déjà gérés par un autre de tes addons."))
                f.taken:Show()
                f.taken:ClearAllPoints(); f.taken:SetPoint("TOPLEFT", 0, -y)
                y = y + math.ceil(S.FitText(f.taken, 0, CW, f))
            else
                f.taken:Hide()
                f.group:Show()
                local gh = f.group:Fit(CW)
                f.group:ClearAllPoints(); f.group:SetPoint("TOPLEFT", 0, -y); f.group:SetSize(CW, gh)
                y = y + gh
            end
            local hunter = PlayerClass() == "HUNTER" and shootOn and true or false
            f.banner:SetShown(hunter)
            if hunter then
                local key = ShootKeyLabel(d)
                f.banner:SetText(key
                    and string.format(L("Chasseur : le clic droit seul reste ton attaque au corps-à-corps, %s + clic droit lance Tir automatique, et un second clic ne l'arrête pas : tu passes de l'un à l'autre sans rien couper."), key)
                    or L("Chasseur : avec « Aucune », le clic droit tire toujours et ne lance plus ton attaque au corps-à-corps. Garde plutôt une touche, Maj par exemple."))
                y = y + 8
                local bh = f.banner:Fit(CW)
                f.banner:ClearAllPoints(); f.banner:SetPoint("TOPLEFT", 0, -y); f.banner:SetSize(CW, bh)
                y = y + bh
            end
            y = y + 16
        end
        f.mmHead:ClearAllPoints(); f.mmHead:SetPoint("TOPLEFT", 0, -y); f.mmHead:SetSize(CW, 32)
        y = y + 32 + 8
        local mh = f.mmGroup:Fit(CW)
        f.mmGroup:ClearAllPoints(); f.mmGroup:SetPoint("TOPLEFT", 0, -y); f.mmGroup:SetSize(CW, mh)
        return y + mh
    end,
}

-- D5. ready: where to start, and where to find it all again
STEPS.ready = {
    Build = function(f)
        f.title = Txt(f, F.heading, C.fg)
        f.text = Txt(f, F.body, C.text)
        local function Card(onClick)
            local c = S.Card(f, { onClick = onClick })
            texts[#texts + 1] = c.title; texts[#texts + 1] = c.line2
            return c
        end
        f.first = Card(function()
            local home = f.first.isHome
            Finish("card")
            if home then
                if WP.OpenHome then WP.OpenHome() end
            elseif root.ShowPicker then root.ShowPicker() end
        end)
        f.writs = Card(function() Finish("card"); if WP.Open then WP.Open("writs") end end)
        f.help = Card(function() Finish("card"); if WP.Help and WP.Help.Toggle then WP.Help.Toggle() end end)
        f.head = S.SectionHeader(f, L("Pour tout retrouver"), nil, nil, nil, true)
        f.finds = {}
        for i, icon in ipairs({ "home", "search", "gear" }) do
            f.finds[i] = { icon = root.Icon(f, icon, 14, "ARTWORK", C.muted), text = Txt(f, F.body, C.text) }
        end
    end,
    Layout = function(f)
        f.title:SetText(L("C'est prêt !"))
        f.text:SetText(L("Par quoi veux-tu commencer ?"))
        local y = 0
        f.title:ClearAllPoints(); f.title:SetPoint("TOPLEFT", 0, -y)
        y = y + math.ceil(S.FitText(f.title, 0, CW, f)) + 4
        f.text:ClearAllPoints(); f.text:SetPoint("TOPLEFT", 0, -y)
        y = y + math.ceil(S.FitText(f.text, 0, CW, f)) + 12
        local dungeons, writs = WP.ModuleOn("dungeons"), WP.ModuleOn("writs")
        local cards = {}
        if dungeons then
            f.first.isHome = false
            f.first:SetContent({ icon = Icon("INV_Misc_Map_01"), title = L("Choisir les donjons"),
                line2 = L("Le guide te donne leurs quêtes dans le bon ordre."),
                tip = { L("Choisir les donjons"), L("Clic : ouvrir le choix des donjons") } })
            cards[#cards + 1] = f.first
        elseif not writs then
            f.first.isHome = true
            f.first:SetContent({ icon = S.LOGO, title = L("Ouvrir l'Accueil"),
                line2 = L("Tout ce que tu as allumé, en un coup d'œil."),
                tip = { L("Ouvrir l'Accueil"), L("Clic : ouvrir l'Accueil") } })
            cards[#cards + 1] = f.first
        end
        f.first:SetShown(dungeons or not writs)
        f.writs:SetShown(writs and true or false)
        if writs then
            f.writs:SetContent({ icon = Icon("INV_Letter_15"), title = L("Voir les Writs"),
                line2 = L("Les moins chers à l'HV et la Faveur qu'ils rapportent."),
                tip = { L("Voir les Writs"), L("Clic : ouvrir les Writs") } })
            cards[#cards + 1] = f.writs
        end
        f.help:SetContent({ icon = Icon("INV_Misc_Book_09"), title = L("Comment faire... ?"),
            line2 = L("Les gestes utiles pas à pas, avec le bon bouton qui s'allume."),
            tip = { L("Comment faire... ?"), L("Clic : ouvrir Comment faire... ?") } })
        f.help:Show()
        cards[#cards + 1] = f.help
        f.shownCards = cards
        for i, c in ipairs(cards) do
            local h = math.max(64, c:Fit(CW))
            c:SetSize(CW, h)
            c:ClearAllPoints(); c:SetPoint("TOPLEFT", 0, -y)
            y = y + h + (i < #cards and 8 or 0)
        end
        y = y + 16
        f.head:ClearAllPoints(); f.head:SetPoint("TOPLEFT", 0, -y); f.head:SetSize(CW, 24)
        y = y + 24 + 8
        local words = {
            MinimapShown() and L("Le bouton WL de la minimap ouvre l'Accueil.")
                or L("Le bouton de la minimap est caché : Réglages, Général pour le remettre."),
            L("Tape /wlh dans le chat pour ouvrir l'Accueil."),
            L("Tout se change dans les Réglages, et /wlh setup rouvre cet écran de bienvenue."),
        }
        for i, ln in ipairs(f.finds) do
            ln.text:SetText(words[i])
            local th = math.ceil(S.FitText(ln.text, 0, CW - 22, f))
            ln.icon:ClearAllPoints(); ln.icon:SetPoint("TOPLEFT", 0, -(y + 1))
            ln.text:ClearAllPoints(); ln.text:SetPoint("TOPLEFT", 22, -y)
            y = y + math.max(14, th) + (i < #f.finds and 6 or 0)
        end
        return y
    end,
}

-- ---------------------------------------------------------------- progress dots

-- N HD dots of 8 px, centres 16 apart: current accent, done muted, upcoming trackOff. Not clickable.
local function Dots(parent)
    local d = CreateFrame("Frame", nil, parent)
    d:SetHeight(32)
    d.dots = {}
    function d:Set(i, n)
        self.n, self.i = n, i
        for k = 1, math.max(n, #self.dots) do
            local t = self.dots[k]
            if k <= n then
                if not t then t = root.Icon(self, "dot", 8, "ARTWORK", C.trackOff); self.dots[k] = t end
                local c = (k == i) and C.accent or (k < i and C.muted or C.trackOff)
                t:SetVertexColor(c[1], c[2], c[3], 1)
                t:ClearAllPoints(); t:SetPoint("CENTER", self, "LEFT", 4 + (k - 1) * 16, 0)
                t:Show()
            elseif t then
                t:Hide()
            end
        end
        self:SetWidth(math.max(8, (n - 1) * 16 + 8))
    end
    return d
end

-- ---------------------------------------------------------------- the window

local function IndexOf(list, key)
    for i, k in ipairs(list) do if k == key then return i end end
end

-- the frame of a step, built the first time it is needed
local function StepFrame(key)
    local f = win.frames[key]
    if not f then
        f = CreateFrame("Frame", nil, win.inner)
        f:SetPoint("TOPLEFT", win.inner, "TOPLEFT", 16, -16)
        f:SetWidth(CW)
        f:Hide()
        STEPS[key].Build(f)
        win.frames[key] = f
    end
    return f
end

-- One body height for the whole welcome, so the bottom bar (and Continuer) stays put from step
-- to step: every step is laid out once and the tallest wins. Measured again when the number of
-- steps changes; a step that grows past it (the comfort key row, the hunter banner) raises it.
local function MeasureBody(steps)
    local tallest = 0
    for _, k in ipairs(steps) do
        if k ~= win.stepKey then
            local ok, h = pcall(STEPS[k].Layout, StepFrame(k))
            if ok and type(h) == "number" then tallest = math.max(tallest, math.ceil(h)) end
        end
    end
    win.bodyH, win.bodyN = tallest, #steps
end

local function Layout()
    if not (win and win.stepKey) then return end
    local key = win.stepKey
    local f = win.frames[key]
    local h = math.ceil(STEPS[key].Layout(f) or 0)
    f:SetHeight(math.max(1, h))
    win.scroll:SetContentHeight(16 + h + 16)
    local steps = Steps()
    win.steps = steps
    if not win.bodyH or win.bodyN ~= #steps then MeasureBody(steps) end
    win.bodyH = math.max(win.bodyH or 0, h)
    win:FitHeight(math.max(win.bodyH + 8, MIN_BODY) + BAR_H)
    -- a rule over the bar only while the step scrolls under it
    win.barRule:SetShown(win.overflow and true or false)
    -- the bar: where we are, and the actions of this step
    local i = IndexOf(steps, key) or 1
    win.subtitle:SetText(string.format(L("Étape %d sur %d"), i, #steps))
    win.dots:Set(i, #steps)
    win.skip:SetShown(i == 1)
    win.backBtn:SetShown(i > 1)
    if key == "hello" then win.primary:SetText(L("Commencer"))
    elseif key == "ready" then win.primary:SetText(L("Terminer"))
    else win.primary:SetText(L("Continuer")) end
end

function Go(key)
    if not (win and STEPS[key]) then return end
    local f = StepFrame(key)
    for k, fr in pairs(win.frames) do fr:SetShown(k == key) end
    win.stepKey = key
    S.HideTip()
    if STEPS[key].Enter then STEPS[key].Enter(f) end
    win.scroll:ScrollTo(0, true)
    Layout()
    root.Tween(f, 0, 1, 0.15, function(v) f:SetAlpha(v) end)
end

function Next()
    if not win then return end
    local steps = Steps()
    local i = IndexOf(steps, win.stepKey) or 0
    if steps[i + 1] then Go(steps[i + 1]) end
end

local function Back()
    if not win then return end
    local steps = Steps()
    local i = IndexOf(steps, win.stepKey) or 2
    Go(steps[math.max(1, i - 1)])
end

-- how: "finish" (Terminer), "card" (a card of the last step), "skip" (Passer); anything else
-- that hides the window (Escape, the close button) counts as "close".
function Finish(how)
    if not win then return end
    win.endHow = how
    win:Hide()
end

-- OnHide also fires when the UI is hidden (Alt-Z) while the window stays shown: that is not an
-- end. One end per opening, so the chat line is printed at most once.
local function Ended()
    if win:IsShown() or win.ended then return end
    win.ended = true
    local how = win.endHow or "close"
    win.endHow = nil
    S.HideTip()
    if not WLWritsDB then return end
    WLWritsDB.welcomed = 2
    WLWritsDB.welcomeEnd = how
    if not win.fromCommand and (how == "skip" or how == "close") then
        WP.Print(L("Écran de bienvenue fermé : tes choix sont gardés. Tape /wlh setup pour le rouvrir."))
    end
end

local function Build()
    win = S.Window("WLHelperWelcome", W, 400, L("Bienvenue dans WL Helper"), nil, nil, nil, { header = 44, strata = "DIALOG", minH = 300 })
    local sa = S.ScrollArea(win)
    sa:SetPoint("TOPLEFT", win, "TOPLEFT", 0, -(win.headerH + 1))
    sa:SetPoint("BOTTOMRIGHT", win, "BOTTOMRIGHT", 0, BAR_H)
    win.scroll, win.inner = sa, sa.child
    win.frames = {}
    win.texts = texts
    win.Relayout = Layout

    -- the bottom bar: Passer or Retour on the left, the dots in the middle, the primary on the right
    win.barRule = S.Rule(win)
    win.barRule:SetPoint("BOTTOMLEFT", 0, BAR_H); win.barRule:SetPoint("BOTTOMRIGHT", 0, BAR_H)
    win.skip = S.Button(win, L("Passer"), 0, 32, "ghost", function() Finish("skip") end,
        { L("Passer"), L("Garde les réglages conseillés."), L("Clic : fermer") })
    win.skip:SetPoint("BOTTOMLEFT", 16 - 12, 12)
    win.backBtn = S.Button(win, L("Retour"), 0, 32, "secondary", Back)
    win.backBtn:SetIcon("chevron_left")
    win.backBtn:SetPoint("BOTTOMLEFT", 16, 12)
    win.primary = S.Button(win, L("Commencer"), 120, 32, "primary", function()
        if win.stepKey == "ready" then
            Finish("finish")
            if MinimapShown() and WLDTMinimapButton and WP.Spotlight then WP.Spotlight(WLDTMinimapButton, 4) end
        else
            Next()
        end
    end)
    win.primary:SetPoint("BOTTOMRIGHT", -16, 12)
    win.dots = Dots(win)
    win.dots:SetPoint("BOTTOM", win, "BOTTOM", 0, 12)
    for _, b in ipairs({ win.skip, win.backBtn, win.primary }) do texts[#texts + 1] = b.label end

    win:HookScript("OnHide", Ended)
    win:SetScript("OnShow", function()
        Layout()
        if C_Timer and C_Timer.After then C_Timer.After(0, function() if win:IsShown() then Layout() end end) end
    end)
end

-- ---------------------------------------------------------------- opening

local ev = CreateFrame("Frame")
local queued = false
local function Queue()
    if queued then return end
    queued = true
    pcall(ev.RegisterEvent, ev, "PLAYER_REGEN_ENABLED")
end

-- /wlh setup (Main.lua) and the first login. The first time it starts at hello; reopened, it starts
-- at what interests you (Retour still reaches hello). In combat it waits for the end of the fight.
function WP.ShowWelcome(fromCommand)
    if InCombatLockdown() then
        if not queued then WP.Print(L("L'écran de bienvenue s'ouvrira à la fin du combat.")) end
        Queue(); return
    end
    if not WLWritsDB then return end
    local again = fromCommand or WLWritsDB.welcomed ~= nil
    if not win then Build() end
    win.fromCommand = again and true or false
    win.endHow = nil
    win.ended = nil
    win.specSticky = nil
    win.bodyH = nil
    for _, sw in ipairs(switches) do sw:Update() end
    Go(again and "interests" or "hello")
    win:Show(); win:Raise()
end

-- for the tests (and the help guide): show a given step of the open welcome
function WP.WelcomeGo(key) Go(key) end

-- true while the welcome is open or still to come at this first login: other modules hold their
-- first-login chat lines (the Upgrades spec guess) since the welcome asks the same question
function WP.WelcomeActive()
    if win and win:IsShown() then return true end
    return WLWritsDB ~= nil and WLWritsDB.welcomed == nil
end

pcall(ev.RegisterEvent, ev, "PLAYER_LOGIN")
ev:SetScript("OnEvent", function(self, e)
    if e == "PLAYER_LOGIN" then
        if WLWritsDB and not WLWritsDB.welcomed then
            C_Timer.After(4, function()
                -- already opened with /wlh setup in the meantime: do not send the player back to hello
                if win and win:IsShown() then return end
                if WLWritsDB and not WLWritsDB.welcomed then WP.ShowWelcome() end
            end)
        end
    elseif e == "PLAYER_REGEN_ENABLED" then
        if not queued then return end
        queued = false
        pcall(self.UnregisterEvent, self, "PLAYER_REGEN_ENABLED")
        WP.ShowWelcome()
    end
end)
