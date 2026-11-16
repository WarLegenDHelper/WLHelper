-- Writs/Options.lua: WL Helper's Settings window (/wlh options): one place for the quest guide, the
-- trading post (Writs), the GPS, the bags and the upgrades. A 640 px window: pages listed on the
-- left under a search box, settings cards on the right (label and description on the left, control
-- on the right), built lazily the first time it opens. The window fits the page it shows.
-- Also registers WL Helper in the game's own settings (Esc > Options > AddOns) and, when present,
-- as an EllesmereUI plugin, both pointing back to this window.
local ADDON, root = ...
root.Writs = root.Writs or {}
local ns = root.Writs
local L = ns.L
local S = ns.S
local T = S.C
local F = root.F

ns.AddEnglish({
    -- window, nav and search
    ["Réglages"] = "Settings",
    ["Général"] = "General", ["Donjons"] = "Dungeons", ["Writs"] = "Writs", ["GPS"] = "GPS",
    ["Sacs"] = "Bags", ["Améliorations"] = "Upgrades", ["À propos"] = "About",
    ["Modules, clics, langue et fenêtres."] = "Modules, clicks, language and windows.",
    ["La flèche, les alertes et les quêtes que montre le guide."] = "The guide's arrow, its alerts and the quests it shows.",
    ["Remise des Writs, rappels, objectif et zones."] = "Writ turn-in, reminders, goal and zones.",
    ["Itinéraire, vols, téléportations et flèche."] = "Route, flights, teleports and the arrow.",
    ["Place dans les sacs et vente des objets gris."] = "Bag space and selling grey items.",
    ["Calcul, spé et affichage des améliorations."] = "How upgrades are judged, the spec and the display.",
    ["Version, crédits, contact et commandes du chat."] = "Version, credits, contact and chat commands.",
    ["Clic : afficher ces réglages"] = "Click: show these settings",
    ["Ex. flèche"] = "E.g. arrow",
    ["Effacer la recherche"] = "Clear search",
    ["Aucun réglage pour « %s »"] = "No setting for \"%s\"",
    ["Essaie un autre mot, en français ou en anglais."] = "Try another word, in English or in French.",
    ["1 réglage trouvé"] = "1 setting found",
    ["%d réglages trouvés"] = "%d settings found",
    ["Entrée pour l'ouvrir."] = "Press Enter to open it.",
    ["Flèches haut et bas pour choisir, Entrée pour ouvrir."] = "Up and down arrows to choose, Enter to open.",
    ["Clic : afficher ce réglage"] = "Click: show this setting",
    ["Clic : activer"] = "Click: turn on",
    ["Clic : désactiver"] = "Click: turn off",
    -- module cards
    ["Ouvrir le guide"] = "Open the guide",
    ["Ouvrir les Writs"] = "Open the Writs window",
    ["Allumer le module"] = "Turn the module on",
    ["Éteint : il ne montre plus rien. Tes réglages sont gardés."] = "Off: it shows nothing. Your settings are kept.",
    ["Groupes de la guilde"] = "Guild groups",
    ["Le guide des quêtes de donjon, de raid et de classe, avec la route et la flèche."] =
        "The dungeon, raid and class quest guide, with the route and the arrow.",
    ["Les Writs à faire, la liste d'achat et la remise automatique."] = "The Writs to do, the shopping list and automatic turn-in.",
    ["Repère les objets de quête qui ne servent plus et libère de la place."] = "Finds quest items you no longer need and frees up space.",
    ["Demande un objet à un artisan de la guilde, ou prends les commandes des autres."] =
        "Ask a guild crafter for an item, or take other people's orders.",
    ["Toute la guilde et le classement PvP."] = "The whole guild and the PvP ranking.",
    ["Les événements de la guilde et les groupes du moment."] = "Guild events and the groups forming now.",
    ["Une flèche verte sur les objets meilleurs que ceux que tu portes."] = "A green arrow on items better than the ones you wear.",
    -- General
    ["Modules"] = "Modules",
    ["Le GPS reste toujours allumé : les autres modules s'en servent. Un module rallumé revient tout de suite, sans /reload."] =
        "The GPS always stays on: the other modules use it. A module turned back on comes back right away, no /reload needed.",
    ["Clics"] = "Clicks",
    ["Alt-clic sur un nom dans le chat"] = "Alt-click a name in chat",
    ["Invite ce joueur dans ton groupe."] = "Invites that player to your group.",
    ["Alt-clic sur un joueur ou un portrait"] = "Alt-click a player or a portrait",
    ["Invite le joueur, dans le monde ou depuis son portrait."] = "Invites that player, in the world or from their portrait.",
    ["Lien [Inviter] dans le chat"] = "[Invite] link in chat",
    ["Ajouté aux messages qui demandent une invitation, comme « inv »."] = "Added to messages that ask for an invite, like \"inv\".",
    ["Clic droit pour tirer"] = "Right-click to shoot",
    ["Sur un ennemi, lance ton tir à distance : arc, fusil, arbalète, arme de jet ou baguette."] =
        "On an enemy, starts your ranged attack: bow, gun, crossbow, thrown weapon or wand.",
    ["Touche pour tirer"] = "Key to shoot",
    ["Garde-la enfoncée, puis fais un clic droit sur l'ennemi. Avec « Aucune », le clic droit seul tire."] =
        "Hold it down, then right-click the enemy. With \"None\", right-click alone shoots.",
    ["Un autre addon le fait déjà : ce réglage reste sans effet."] = "Another addon already does this: this setting has no effect.",
    ["Langue"] = "Language",
    ["Langue de l'addon"] = "Addon language",
    ["Automatique"] = "Automatic", ["Français"] = "Français", ["English"] = "English",
    ["Automatique suit la langue du jeu. Les fenêtres déjà ouvertes changent après un /reload."] =
        "Automatic follows the game's language. Windows already open change after a /reload.",
    ["Police"] = "Font",
    ["Police des textes"] = "Text font",
    ["Police du jeu"] = "Game font",
    ["Si des textes restent vides, reviens à celle du jeu."] = "If some texts stay blank, go back to the game's font.",
    ["Fenêtres"] = "Windows",
    ["Bouton de la minimap"] = "Minimap button",
    ["Ouvre l'Accueil de WL Helper d'un clic."] = "Opens the WL Helper Home in one click.",
    ["Rouvrir le guide à la connexion"] = "Reopen the guide on login",
    ["Même si tu l'avais fermé avant de te déconnecter."] = "Even if you closed it before logging out.",
    -- Dungeons
    ["Guide de quêtes"] = "Quest guide",
    ["Réglages du guide"] = "Guide settings",
    ["Flèche du guide"] = "Guide arrow",
    ["Le GPS te mène à la prochaine étape du guide."] = "The GPS leads you to the guide's next step.",
    ["Alerte des monstres rares"] = "Rare monster alert",
    ["Dans un donjon, un message et un son quand un monstre rare apparaît."] = "In a dungeon, a message and a sound when a rare monster shows up.",
    ["Points GPS à chaque étape"] = "GPS points at each step",
    ["Les points de l'étape en cours sont posés tout seuls quand une nouvelle étape commence."] =
        "The current step's points are set on their own when a new step starts.",
    ["Quêtes répétables ou d'un autre métier"] = "Repeatable or other-profession quests",
    ["Masquées, elles sortent de la route et du compte de quêtes de chaque donjon."] =
        "When hidden, they leave the route and each dungeon's quest count.",
    ["Masquer"] = "Hide", ["Afficher"] = "Show",
    -- Writs
    ["Automatismes"] = "Automation",
    ["Rendre les Writs automatiquement"] = "Turn in Writs automatically",
    ["Rendre les caisses automatiquement"] = "Turn in crates automatically",
    ["En parlant à Dokimi ou à Marcy Baker."] = "When you talk to Dokimi or Marcy Baker.",
    ["Accepter la quête en ouvrant l'enveloppe"] = "Accept the quest when opening the envelope",
    ["Scanner l'HV à son ouverture"] = "Scan the AH when it opens",
    ["Seulement si la fenêtre Writs est ouverte et que les prix ont plus d'une heure."] =
        "Only when the Writs window is open and prices are over an hour old.",
    ["Infos"] = "Info",
    ["Rappel à la connexion"] = "Reminder on login",
    ["Par exemple : « 3 Writs prêts à rendre, 1 enveloppe à ouvrir »."] = "For example: \"3 Writs ready to turn in, 1 envelope to open\".",
    ["Détails dans l'infobulle des enveloppes"] = "Details in envelope tooltips",
    ["Réputation, coût, à qui la rendre, et si tu l'as déjà rendue."] = "Reputation, cost, who to hand it to, and whether you already turned it in.",
    ["Plan"] = "Plan",
    ["Objectif de réputation"] = "Reputation goal",
    ["Le plan achète les Writs qu'il faut pour l'atteindre."] = "The plan buys the Writs needed to reach it.",
    ["Rang suivant"] = "Next standing",
    ["Masquer les zones trop hautes"] = "Hide zones above your level",
    ["Les zones au-dessus de ton niveau sortent du plan."] = "Zones above your level leave the plan.",
    ["Zones du plan"] = "Zones in the plan",
    ["niv. %d+"] = "lvl %d+",
    ["Pour écarter un seul Writ : clic droit dessus dans l'onglet « Tous les writs » des Writs."] =
        "To set aside a single Writ: right-click it in the Writs window's \"All writs\" tab.",
    -- GPS
    ["Itinéraire"] = "Route",
    ["Calcul de l'itinéraire"] = "Route planner",
    ["WL Helper"] = "WL Helper", ["Zygor"] = "Zygor",
    ["Pas installé"] = "Not installed",
    ["Automatique prend Zygor quand il est installé, sinon le GPS de WL Helper."] =
        "Automatic uses Zygor when it is installed, otherwise the WL Helper GPS.",
    ["Trajet"] = "Travel",
    ["Utiliser mes téléportations"] = "Use my teleports",
    ["Choisir le vol automatiquement"] = "Pick the flight automatically",
    ["Chez le maître de vol, le bon trajet est choisi pour toi."] = "At the flight master, the right route is picked for you.",
    ["Points de vol connus"] = "Known flight paths",
    ["Ceux que ce personnage a déjà découverts."] = "The ones this character has already discovered.",
    ["Distances en yards"] = "Distances in yards",
    ["Sinon en mètres et en kilomètres."] = "Otherwise in meters and kilometers.",
    ["Flèche"] = "Arrow",
    ["Taille de la flèche"] = "Arrow size",
    ["Opacité du fond"] = "Background opacity",
    ["%d %%"] = "%d%%",
    ["Masquer en combat"] = "Hide in combat",
    ["Position de la flèche"] = "Arrow position",
    ["Fais-la glisser où tu veux à l'écran."] = "Drag it anywhere on the screen.",
    ["Déplacer la flèche"] = "Move the arrow",
    -- Bags
    ["Place dans les sacs"] = "Bag space",
    ["Proposer de libérer une place"] = "Offer to free a slot",
    ["Quand tes sacs sont pleins, WL Helper propose de jeter l'objet le moins cher : un gris, ou une arme ou une armure blanche."] =
        "When your bags are full, WL Helper offers to throw away the cheapest item: a grey, or a white weapon or armor.",
    ["Vendre les gris chez les marchands"] = "Sell greys at merchants",
    ["Dès que tu ouvres la fenêtre d'un marchand."] = "As soon as you open a merchant's window.",
    ["Un autre de tes addons les vend déjà : WL Helper le laisse faire."] = "Another of your addons already sells them: WL Helper lets it.",
    ["Le nettoyeur ne propose jamais un objet qui lance une quête. Pour libérer une place à la main, tape /wlh free."] =
        "The cleaner never offers an item that starts a quest. To free a slot by hand, type /wlh free.",
    -- Upgrades
    ["Calcul"] = "Calculation",
    ["Méthode de calcul"] = "Method",
    ["Poids WL Helper"] = "WL Helper weights",
    ["Prend les classements de ton addon d'équipement s'il y en a un, sinon les poids de WL Helper."] =
        "Uses your gear addon's rankings when you have one, otherwise WL Helper's weights.",
    ["Spé"] = "Spec",
    ["Spé évaluée"] = "Rated spec",
    ["Auto"] = "Auto",
    ["Auto : l'arbre de talents où tu as le plus de points."] = "Auto: the talent tree with the most points.",
    ["Spés à comparer"] = "Specs to compare",
    ["Spé principale"] = "Main spec",
    ["Celle de tes talents, ou celle choisie plus haut. Toujours sur la première ligne."] =
        "The one from your talents, or the one picked above. Always on the first line.",
    ["Comparer aussi : %s"] = "Also compare: %s",
    ["Une ligne de plus dans les infobulles d'objet pour cette spé."] = "One more line in item tooltips for this spec.",
    ["Flèche pour"] = "Arrow for",
    ["Ma spé principale"] = "My main spec",
    ["N'importe laquelle de mes spés"] = "Any of my specs",
    ["Avec plusieurs spés, l'infobulle dit laquelle gagne."] = "With several specs, the tooltip says which one gains.",
    ["Affichage"] = "Display",
    ["Flèche à partir de"] = "Show the arrow from",
    ["Le gain minimum pour mettre la flèche sur un objet."] = "The smallest gain that puts the arrow on an item.",
    ["Ligne dans les infobulles d'objet"] = "Line in item tooltips",
    ["Le gain ou la perte pour ta spé, et l'objet qu'il remplacerait."] = "The gain or loss for your spec, and the item it would replace.",
    ["Masquer le bloc en double des infobulles"] = "Hide the duplicate tooltip block",
    ["Quand ton addon d'équipement affiche déjà le même pourcentage."] = "When your gear addon already shows the same percentage.",
    ["Poids utilisés : %s, niveaux %s"] = "Weights used: %s, levels %s",
    ["Dégâts des sorts"] = "Spell damage", ["Soins"] = "Healing", ["Intelligence"] = "Intellect", ["Esprit"] = "Spirit",
    ["Endurance"] = "Stamina", ["Force"] = "Strength", ["Agilité"] = "Agility", ["Puissance d'attaque"] = "Attack power",
    ["Puissance d'attaque à distance"] = "Ranged attack power", ["Critique (1 %)"] = "Crit (1%)",
    ["Critique des sorts (1 %)"] = "Spell crit (1%)", ["Toucher (1 %)"] = "Hit (1%)", ["Toucher des sorts (1 %)"] = "Spell hit (1%)",
    ["Mana toutes les 5 s"] = "Mana per 5 s", ["Armure"] = "Armor", ["Défense"] = "Defense", ["Esquive (1 %)"] = "Dodge (1%)",
    ["Parade (1 %)"] = "Parry (1%)", ["Blocage (1 %)"] = "Block (1%)", ["Valeur de blocage"] = "Block value",
    ["Dégâts par seconde de l'arme"] = "Weapon damage per second",
    ["Ces poids sont ceux de WL Helper, par classe et par spé, ajustés à ta tranche de niveaux (1-20, 21-40, 41-59, 60). Les dégâts d'une école de magie comptent selon ta spé. Un objet que ta classe ne peut pas porter n'a pas de flèche."] =
        "These are WL Helper's weights, per class and spec, adjusted to your level range (1-20, 21-40, 41-59, 60). One school's spell damage counts according to your spec. An item your class can't wear gets no arrow.",
    -- About
    ["Version %s"] = "Version %s",
    ["Pour la guilde WaR LegenD."] = "For the WaR LegenD guild.",
    ["Crédits"] = "Credits",
    ["Auteur"] = "Author", ["Logo"] = "Logo",
    ["WaR LegenD (War Legend Raid Tool)"] = "WaR LegenD (War Legend Raid Tool)",
    ["Code source"] = "Source code",
    ["Clique sur le lien, puis Ctrl+C pour le copier."] = "Click the link, then Ctrl+C to copy it.",
    ["Clic : sélectionner le lien"] = "Click: select the link",
    ["Sources et remerciements : le fichier CREDITS.txt dans le dossier de l'addon."] =
        "Sources and thanks: the CREDITS.txt file in the addon's folder.",
    ["Dis-nous ce qui manque ou ce qui coince. Chaque bouton t'affiche un lien à ouvrir dans ton navigateur."] =
        "Tell us what's missing or broken. Each button gives you a link to open in your browser.",
    ["Commandes du chat"] = "Chat commands",
    -- game settings and EllesmereUI
    ["Le guide de quêtes, les Writs, le GPS et les outils de la guilde WaR LegenD."] =
        "The quest guide, the Writs window, the GPS and the WaR LegenD guild tools.",
    ["Ouvrir les réglages"] = "Open settings",
    ["Les réglages les plus utilisés. Tous les autres sont dans la fenêtre Réglages de WL Helper."] =
        "The most used settings. All the others are in WL Helper's Settings window.",
    ["Utiliser Zygor quand il est installé"] = "Use Zygor when it is installed",
    ["Masquer la flèche en combat"] = "Hide the arrow in combat",
    -- names read through WP.MODULES (Core.lua) and older keys other windows still use
    ["Guide des quêtes de donjon, route, flèche"] = "Dungeon quest guide, route, arrow",
    ["Donjons, raids et quêtes de classe : route, flèche"] = "Dungeons, raids and class quests: route, arrow",
    ["Craftsman's Writs, liste d'achat, remise auto"] = "Craftsman's Writs, shopping list, auto turn-in",
    ["Nettoyeur des objets de quête inutiles"] = "Cleaner for quest items you no longer need",
    ["Faire fabriquer par la guilde, accepter des commandes"] = "Have the guild craft for you, take orders",
    ["Writs et Faveur du marchand"] = "Writs & Merchant's Favor",
    ["Writs et Faveur"] = "Writs & Favor",
    ["éteint"] = "off",
    ["Allumer"] = "Turn on",
    ["Options"] = "Options",
    ["Donjons · Raids · Classe"] = "Dungeons · Raids · Class",
    ["Version"] = "Version", ["Voir"] = "Show",
    ["Writs & Favor"] = "Writs & Favor",
    -- the tools' rows (their own strings live in their files)
    ["Prendre /way"] = "Take /way",
    ["Allumé, /way envoie le point au GPS de WL Helper. Éteint, /way reste à l'addon qui l'avait (TomTom par exemple) et /wlway fait la même chose."] =
        "When on, /way sends the point to WL Helper's GPS. When off, /way stays with the addon that had it (TomTom, for example) and /wlway does the same.",
    ["/way est à %s."] = "/way belongs to %s.",
})

-- ---------------------------------------------------------------- settings access

local function Writs() return WLWritsDB or {} end
local function Gps() local db = Writs(); db.gpsOpts = db.gpsOpts or {}; return db.gpsOpts end
local function Comfort() local db = Writs(); db.comfort = db.comfort or {}; return db.comfort end
local function Guide() WLDTDB = WLDTDB or {}; return WLDTDB end

local function ZygorPresent() return (ZGV and ZGV.Pointer) and true or false end
local function secret(v) return root.IsSecret and root.IsSecret(v) end
local function num(v) return type(v) == "number" and not secret(v) and v or nil end

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

-- "1,5" in French, "1.5" in English
local function Decimal(v)
    local s = string.format("%.2f", v)
    if not (ns.English and ns.English()) then s = s:gsub("%.", ",") end
    return s
end

-- ---------------------------------------------------------------- layout constants

local WIN_W, NAV_W = 640, 168
local CONTENT_W = WIN_W - NAV_W - 1        -- the content column, right of the nav and its rule
local INSET = 16                           -- one left edge, one right edge
local CARD_W = CONTENT_W - 2 * INSET       -- a settings card
local NAV_ITEM_H, NAV_GAP, NAV_TOP = 32, 2, 12 + 28 + 12
local PAGE_COUNT = 7
local NAV_H = NAV_TOP + PAGE_COUNT * NAV_ITEM_H + (PAGE_COUNT - 1) * NAV_GAP + 12
local HEADER_H = 44

-- ---------------------------------------------------------------- search index
-- Every row registers its page, section, label and description while the pages are built. Text is
-- matched lower-cased and without accents, in both languages (the French key and its English text),
-- plus a few keywords, so "arrow", "fleche" and "flèche" all find the arrow settings.
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
    infobulle = "tooltip", writ = "enveloppe comptoir", minimap = "carte bouton", langue = "language english francais",
    language = "langue", sac = "bags clean nettoyeur", bags = "sacs nettoyeur", reglage = "settings options",
    commande = "orders artisan metier", orders = "commandes", guilde = "guild classement pvp",
    groupe = "lfg events evenement donjon raid", lfg = "groupes events", spe = "spec talents poids amelioration",
    spec = "spe talents", stuff = "ameliorations upgrades equipement", son = "sound alerte", alerte = "rare sound son",
    caisse = "crates faveur favor", faveur = "favor caisses", hv = "hotel des ventes auction scan prix",
    prix = "price scan hv", police = "font", font = "police", comptoir = "writs trading post",
    invite = "inviter inv clic", inviter = "invite inv", tir = "shoot tirer", shoot = "tirer tir",
}

local function Register(p, row, label, hint)
    local section = p.section or ""
    local text = table.concat({ label or "", OtherLanguage(label), hint or "", OtherLanguage(hint),
        section, OtherLanguage(section), p.pageLabel or "", OtherLanguage(p.pageLabel) }, " ")
    INDEX[#INDEX + 1] = { page = p.key, pageLabel = p.pageLabel, pageIcon = p.pageIcon, section = section,
        label = label, hint = hint, row = row,
        labelFold = Fold((label or "") .. " " .. OtherLanguage(label)), all = Fold(text) }
end

-- ---------------------------------------------------------------- pages
-- A page is the scrolled child of a scroll area filling the content column. Its items (section
-- headers, settings cards, notes, module card, free blocks) are stacked by p:Layout(), which measures
-- every text at its width and returns the page height; the window then fits it.

local function NewPage(parent)
    local sa = S.ScrollArea(parent)
    sa:SetAllPoints()
    sa:Hide()
    local p = sa.child
    p:SetWidth(CONTENT_W)
    p.sa = sa
    p.items, p.controls = {}, {}
    function p:Show() sa:Show(); sa:ScrollTo(0, true) end
    function p:Hide() sa:Hide() end
    function p:SetShown(v) if v then self:Show() else sa:Hide() end end
    function p:IsShown() return sa:IsShown() end
    -- every control re-reads its value when the page shows
    function p:Sync()
        for _, c in ipairs(self.controls) do
            if c.Sync then c:Sync() elseif c.Update then c:Update() end
        end
    end
    function p:Layout()
        local y = 0
        for i, it in ipairs(self.items) do
            local gap = it.gap
            if gap == nil then gap = 12 end
            if i == 1 then gap = (it.kind == "head") and 8 or 12 end
            y = y + gap
            it.frame:ClearAllPoints()
            it.frame:SetPoint("TOPLEFT", self, "TOPLEFT", INSET, -y)
            it.frame:SetWidth(CARD_W)
            it.y = y
            y = y + (it.Layout(CARD_W, y) or 0)
        end
        y = math.ceil(y + 16)
        self.contentH = y
        sa:SetContentHeight(y)
        return y
    end
    return p
end

local function Add(p, frame, layout, kind, gap)
    local it = { frame = frame, Layout = layout, kind = kind, gap = gap }
    p.items[#p.items + 1] = it
    return it
end

-- Section header: label 13 fg, 1 px divider under it. A settings card follows (opened by Row).
local function Section(p, text)
    p.card = nil
    p.section = text
    local h = S.SectionHeader(p, text)
    Add(p, h, function() return 32 end, "head", 16)
end

-- One explanatory paragraph under a card: 11 muted, wraps without a line limit.
local function Note(p, text, size, color)
    p.card = nil
    local holder = CreateFrame("Frame", nil, p)
    local fs = S.Text(holder, size or F.meta, color or T.muted)
    fs:SetJustifyH("LEFT"); fs:SetJustifyV("TOP")
    fs:SetWordWrap(true)
    fs:SetPoint("TOPLEFT", 0, 0)
    fs:SetText(text)
    holder.text = fs
    Add(p, holder, function(width)
        local h = root.FitText(fs, 0, width, holder)
        h = math.max(h, size and size + 2 or 13)
        holder:SetHeight(h)
        return h
    end, "note", 8)
    return fs
end

-- The current settings card of the page (a new one after a section header or a note).
local function Card(p)
    if p.card then return p.card end
    local card = CreateFrame("Frame", nil, p)
    card.bg = S.Solid(card, "BACKGROUND", T.cardFill); card.bg:SetAllPoints()
    S.Border(card, T.cardEdge)
    card.rows = {}
    p.card = card
    Add(p, card, function(width, top)
        local y = 0
        for i, row in ipairs(card.rows) do
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", card, "TOPLEFT", 0, -y)
            row:SetWidth(width)
            local h = row:Layout(width)
            row:SetHeight(h)
            row.pageY = top + y
            row.divider:SetShown(i < #card.rows)
            y = y + h
        end
        card:SetHeight(math.max(1, y))
        return y
    end, "card", 0)
    return card
end

-- A settings row (3.18): label 13 fg at the left, an optional description 11 muted on a second
-- line, the control at the right. The row grows with its wrapped texts.
local function Row(p, label, desc)
    local card = Card(p)
    local row = CreateFrame("Frame", nil, card)
    row.label = S.Text(row, F.body, T.fg)
    row.label:SetJustifyH("LEFT"); row.label:SetJustifyV("TOP")
    row.label:SetText(label)
    row.desc = S.Text(row, F.meta, T.muted)
    row.desc:SetJustifyH("LEFT"); row.desc:SetJustifyV("TOP")
    row.desc:SetWordWrap(true)
    row.hl = S.Solid(row, "BACKGROUND", T.hoverFill); row.hl:SetAllPoints(); row.hl:SetAlpha(0)
    row.divider = S.Rule(row)
    row.divider:SetPoint("BOTTOMLEFT", INSET, 0); row.divider:SetPoint("BOTTOMRIGHT", -INSET, 0)
    function row:SetDesc(t)
        self.desc:SetText(t or "")
        self.desc:SetShown(t ~= nil and t ~= "")
    end
    row:SetDesc(desc)
    function row:Layout(width)
        local c = self.control
        local cw = c and (num(c:GetWidth()) or 0) or 0
        local textW = math.max(80, width - 2 * INSET - (cw > 0 and (cw + 12) or 0))
        local lh = math.max(15, root.FitText(self.label, 2, textW, self))
        local h
        self.label:ClearAllPoints()
        if self.desc:IsShown() then
            local dh = math.max(13, root.FitText(self.desc, 0, textW, self))
            self.label:SetPoint("TOPLEFT", INSET, -8)
            self.desc:ClearAllPoints()
            self.desc:SetPoint("TOPLEFT", self.label, "BOTTOMLEFT", 0, -3)
            h = 8 + lh + 3 + dh + 8
        else
            h = math.max(36, lh + 16)
            self.label:SetPoint("TOPLEFT", INSET, -math.floor((h - lh) / 2))
        end
        h = math.ceil(h)
        if c then c:ClearAllPoints(); c:SetPoint("RIGHT", self, "RIGHT", -INSET, 0) end
        return h
    end
    card.rows[#card.rows + 1] = row
    Register(p, row, label, desc)
    return row
end

-- Puts the control at the row's right edge; it is re-synced each time the page shows.
local function Place(p, row, control)
    row.control = control
    control:ClearAllPoints()
    control:SetPoint("RIGHT", row, "RIGHT", -INSET, 0)
    p.controls[#p.controls + 1] = control
    return control
end

-- A dropdown's list is a child of its trigger, so the page's scroll frame would clip it at the
-- window's edge: once opened, it moves to UIParent (still anchored under the trigger, kept on
-- screen) and closes when the page scrolls. The trigger's own OnHide still closes it.
local function LiftList(d, sa)
    d:HookScript("OnClick", function(self)
        if not self.wlList then
            for _, ch in ipairs({ self:GetChildren() }) do
                if type(ch) == "table" and ch.Fill and ch.rows then self.wlList = ch end
            end
        end
        local list = self.wlList
        if not (list and list:IsShown()) then return end
        if list:GetParent() ~= UIParent then list:SetParent(UIParent) end
        list:SetFrameStrata("FULLSCREEN_DIALOG")
        if list.SetClampedToScreen then list:SetClampedToScreen(true) end
        if list.Raise then list:Raise() end
    end)
    if sa and not sa.wlListHook then
        sa.wlListHook = {}
        pcall(sa.HookScript, sa, "OnVerticalScroll", function()
            for _, dd in ipairs(sa.wlListHook) do if dd.wlList then dd.wlList:Hide() end end
        end)
    end
    if sa then sa.wlListHook[#sa.wlListHook + 1] = d end
end

-- A segmented control that turns into a dropdown when its labels would leave the row's texts less
-- than 200 px. The dropdown is as wide as its longest choice.
local CHOICE_MAX = CARD_W - 2 * INSET - 12 - 200
local function Choice(p, row, options, get, set)
    local seg = S.Segmented(row, options, get, set)
    seg:SetMaxWidth(CHOICE_MAX)
    local d = seg.dropdown
    if d and d:IsShown() then
        local longest = 0
        for _, b in ipairs(seg.buttons or {}) do
            longest = math.max(longest, root.TextWidth(b.label))
        end
        -- the button's own measure (label + 24, chevron and its gap + 12): the longest choice fits
        d:SetWidth(math.max(120, math.min(CHOICE_MAX, math.ceil(longest) + 24 + 12)))
        seg:SetWidth(num(d:GetWidth()) or CHOICE_MAX)
        LiftList(d, p.sa)
    end
    return Place(p, row, seg)
end

-- A switch row: the whole row is the click target and shows what the click does.
local function SwitchRow(p, label, get, set, desc)
    local row = Row(p, label, desc)
    local sw = S.Switch(row, get, set)
    sw:AttachRow(row)
    row:EnableMouse(true)
    local function Over(f) local ok, v = pcall(f.IsMouseOver, f); return ok and v end
    local function Tip() S.Tip(row, { row.label:GetText() or "", get() and L("Clic : désactiver") or L("Clic : activer") }) end
    local function Enter()
        root.Tween(row.hl, num(row.hl:GetAlpha()) or 0, 1, 0.10, function(v) row.hl:SetAlpha(v) end)
        Tip()
    end
    local function Leave()
        root.Tween(row.hl, num(row.hl:GetAlpha()) or 0, 0, 0.10, function(v) row.hl:SetAlpha(v) end)
        S.HideTip()
    end
    -- the switch is a button over the row: moving onto it keeps the row lit and its tooltip
    row:HookScript("OnEnter", Enter)
    row:HookScript("OnLeave", function() if not Over(sw) then Leave() end end)
    sw:HookScript("OnEnter", Enter)
    sw:HookScript("OnLeave", function() if not Over(row) then Leave() end end)
    -- after a click the tooltip tells the next click
    sw:HookScript("OnClick", function()
        local ok, owner = pcall(function() return GameTooltip:IsShown() and GameTooltip:GetOwner() end)
        if ok and owner == row then Tip() end
    end)
    row.switch = sw
    Place(p, row, sw)
    return sw, row
end

-- A value shown at the right of a row (a count, a name): one line, full text in the row's tooltip.
local function ValueText(row, maxW)
    local fs = S.Text(row, F.label, T.fg)
    fs:SetJustifyH("RIGHT")
    S.ClampLabel(fs, nil, row)
    row:EnableMouse(true)
    function fs:Fit()
        self:SetWidth(math.max(24, math.min(maxW or 220, root.TextWidth(self) + 2)))
    end
    local set = fs.SetText
    fs.SetText = function(self, t) set(self, t); self.wlFull = t; self:Fit() end
    return fs
end

-- A slider shown in percent for a value stored as a fraction (1 = 100 %), its value at its right.
local function PercentSlider(p, label, min, max, getFrac, setFrac)
    local row = Row(p, label)
    local holder = CreateFrame("Frame", nil, row)
    holder:SetSize(160 + 12 + 48, 20)
    local s = S.Slider(holder, min, max, 5,
        function() return math.floor((getFrac() or 1) * 100 + 0.5) end,
        function(v) setFrac(v / 100) end,
        function(v) return string.format(L("%d %%"), v) end, 160)
    s:SetPoint("LEFT")
    s.value:SetJustifyH("RIGHT")
    function holder:Sync() s:SetValue(math.floor((getFrac() or 1) * 100 + 0.5)) end
    holder.slider = s
    return Place(p, row, holder)
end

-- ---------------------------------------------------------------- pages

-- Page icons (icon audit G5): the modules' own icons (Writs/Home.lua WP.MODULE_ICON, the same as
-- on the Home cards); General is the HD settings gear, as everywhere else Settings opens; GPS is the addon's GPS arrow, as on the HUD
-- and in the minimap menu; About is the neutral "info" glyph (the question mark read as Help).
-- An icon is a painted path or { hd = glyph name or path }.
local MI = ns.WP.MODULE_ICON or {}
local PAGES = {
    { key = "general",  label = "Général",       icon = { hd = "gear" },                            desc = "Modules, clics, langue et fenêtres." },
    { key = "dungeons", label = "Donjons",       icon = MI.dungeons or "Interface\\Icons\\INV_Misc_Map_01", desc = "La flèche, les alertes et les quêtes que montre le guide." },
    { key = "comptoir", label = "Writs",      icon = MI.writs or "Interface\\Icons\\INV_Letter_15", desc = "Remise des Writs, rappels, objectif et zones." },
    { key = "gps",      label = "GPS",           icon = { hd = root.ARROW },                          desc = "Itinéraire, vols, téléportations et flèche." },
    { key = "bags",     label = "Sacs",          icon = MI.bags or "Interface\\Icons\\INV_Misc_Bag_08", desc = "Place dans les sacs et vente des objets gris." },
    { key = "upgrades", label = "Améliorations", icon = MI.upgrades or { hd = "arrow_up", color = T.ok }, desc = "Calcul, spé et affichage des améliorations." },
    { key = "about",    label = "À propos",      icon = { hd = "info" },                              desc = "Version, crédits, contact et commandes du chat." },
}
-- Draws a page or module icon: a painted path, or an HD glyph (its own colour, else `rest`).
-- -> true for a glyph
local function PaintIcon(tex, icon, rest)
    if type(icon) == "table" then
        root.SetHDIcon(tex, icon.hd, icon.color or rest or T.muted)
        return true
    end
    S.Painted(tex, icon); tex:SetVertexColor(1, 1, 1)
    return false
end

-- What each module does, written for the Settings rows and the module card of its page.
local MODULE_DESC = {
    dungeons = "Le guide des quêtes de donjon, de raid et de classe, avec la route et la flèche.",
    writs = "Les Writs à faire, la liste d'achat et la remise automatique.",
    bags = "Repère les objets de quête qui ne servent plus et libère de la place.",
    orders = "Demande un objet à un artisan de la guilde, ou prends les commandes des autres.",
    guild = "Toute la guilde et le classement PvP.",
    events = "Les événements de la guilde et les groupes du moment.",
    upgrades = "Une flèche verte sur les objets meilleurs que ceux que tu portes.",
}
local MODULE_ICON = {
    dungeons = MI.dungeons or "Interface\\Icons\\INV_Misc_Map_01", writs = MI.writs or "Interface\\Icons\\INV_Letter_15",
    bags = MI.bags or "Interface\\Icons\\INV_Misc_Bag_08", upgrades = MI.upgrades or { hd = "arrow_up", color = T.ok },
}

-- A module's name: "Groupes" has two English texts (Events.lua says "LFG"), and WP.MODULES says
-- "Writs & Favor" for the trading post.
local function ModLabel(m)
    if m.key == "events" then return L("Groupes de la guilde") elseif m.key == "writs" then return L("Writs") end
    return L(m.label)
end
local function ModDesc(m)
    return MODULE_DESC[m.key] and L(MODULE_DESC[m.key]) or L(m.hint or "")
end

local Rebuild   -- defined with the window: rebuilds every page after a language change
local Relayout  -- defined with the window: re-measures the page shown and fits the window

local BUILD = {}

function BUILD.general(p)
    Section(p, L("Modules"))
    for _, m in ipairs(ns.WP.MODULES) do
        SwitchRow(p, ModLabel(m), function() return ns.WP.ModuleOn(m.key) end,
            function(v) ns.WP.SetModule(m.key, v) end, ModDesc(m))
    end
    Note(p, L("Le GPS reste toujours allumé : les autres modules s'en servent. Un module rallumé revient tout de suite, sans /reload."))

    if ns.WP.ClicksDB then
        Section(p, L("Clics"))
        local function Clicks() return ns.WP.ClicksDB() end
        local function setClick(k) return function(v) Clicks()[k] = v; if ns.WP.ApplyClicks then ns.WP.ApplyClicks() end end end
        local taken = L("Un autre addon le fait déjà : ce réglage reste sans effet.")
        local inviteBy = ns.WP.ClickOwner and ns.WP.ClickOwner("invite")
        local shootBy = ns.WP.ClickOwner and ns.WP.ClickOwner("shoot")
        SwitchRow(p, L("Alt-clic sur un nom dans le chat"), function() return Clicks().chat end, setClick("chat"),
            inviteBy and taken or L("Invite ce joueur dans ton groupe."))
        SwitchRow(p, L("Alt-clic sur un joueur ou un portrait"), function() return Clicks().world end, setClick("world"),
            inviteBy and taken or L("Invite le joueur, dans le monde ou depuis son portrait."))
        SwitchRow(p, L("Lien [Inviter] dans le chat"), function() return Clicks().link end, setClick("link"),
            inviteBy and taken or L("Ajouté aux messages qui demandent une invitation, comme « inv »."))
        SwitchRow(p, L("Clic droit pour tirer"), function() return Clicks().shoot end, setClick("shoot"),
            shootBy and taken or L("Sur un ennemi, lance ton tir à distance : arc, fusil, arbalète, arme de jet ou baguette."))
        local mrow = Row(p, L("Touche pour tirer"), L("Garde-la enfoncée, puis fais un clic droit sur l'ennemi. Avec « Aucune », le clic droit seul tire."))
        Choice(p, mrow, ns.WP.ShootKeys(), function() return Clicks().shootMod end, setClick("shootMod"))
        -- wand users: a plain right-click on an enemy can shoot too (OfferWand first, so the
        -- welcome step never overrides the choice made here)
        if ns.WP.WandOption and ns.WP.WandOption() then
            SwitchRow(p, L("Clic droit simple = baguette"), function() return Clicks().wandRight end, function(v)
                if ns.WP.OfferWand then ns.WP.OfferWand() end
                setClick("wandRight")(v)
            end, L("Sans touche, un clic droit sur un ennemi lance ta baguette au lieu du corps-à-corps. La touche choisie tire toujours. Maintenu sur un ennemi, il ne tourne plus la caméra."))
        end
        local AC = ns.WP.AltClick
        if AC and AC.On and AC.SetOn then
            SwitchRow(p, L("Alt-clic pour désenchanter / crocheter"), function() return AC.On() end, function(v) AC.SetOn(v) end,
                L("Alt + clic gauche sur un objet de tes sacs : désenchanter (enchanteur), crocheter un coffret (voleur), déchiffrer un parchemin (mage)."))
        end
    end

    -- the smaller tools (Home, "Outils"): each row only when its file is loaded
    local CT, Tr = ns.WP.CityTour, ns.WP.Triage
    if (CT and CT.IsOn) or Tr then
        Section(p, L("Outils"))
        if CT and CT.IsOn and CT.SetOn then
            SwitchRow(p, L("Tournée en ville"), function() return CT.IsOn() end, function(v) CT.SetOn(v) end,
                L("En arrivant dans une capitale, une petite fiche liste ce qu'il y a à faire : courrier, réparations, maître de classe, quêtes à rendre."))
        end
        if Tr then
            SwitchRow(p, L("Proposer le tri du journal"), function() return WLWritsDB.triageNotice ~= false end,
                function(v) WLWritsDB.triageNotice = v and true or false end,
                L("Quand ton journal de quêtes est presque plein, une ligne dans le chat propose de voir les quêtes à abandonner."))
        end
    end

    -- what this copy tells the guild's copies: each one can be kept private
    local K, Sh = ns.WP.Keys, ns.WP.Shared
    if (K and K.ShareOn) or (Sh and Sh.GetShare) then
        Section(p, L("Guilde"))
        if K and K.ShareOn and K.SetShare then
            SwitchRow(p, L("Partager mes clés avec la guilde"), function() return K.ShareOn() end, function(v) K.SetShare(v) end,
                L("Les membres qui ont WL Helper voient quelles clés tu as, dans l'onglet Qui a la clé ? de la guilde."))
        end
        if Sh and Sh.GetShare and Sh.SetShare then
            SwitchRow(p, L("Partager mes quêtes de donjon"), function() return Sh.GetShare() end, function(v) Sh.SetShare(v) end,
                L("Les membres de la guilde qui ont WL Helper voient quelles quêtes de donjon tu as, pour grouper. Rien d'autre n'est envoyé."))
        end
    end

    Section(p, L("Langue"))
    local row = Row(p, L("Langue de l'addon"), L("Automatique suit la langue du jeu. Les fenêtres déjà ouvertes changent après un /reload."))
    Choice(p, row, {
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
    end)

    -- the font: the game's own (sure to show everywhere) or EllesmereUI's when it is installed
    if root.IsLoaded and root.IsLoaded("EllesmereUI") then
        Section(p, L("Police"))
        local frow = Row(p, L("Police des textes"), L("Si des textes restent vides, reviens à celle du jeu."))
        Choice(p, frow, { { "game", L("Police du jeu") }, { "eui", "EllesmereUI" } },
            function() return WLWritsDB.font == "eui" and "eui" or "game" end,
            function(v) WLWritsDB.font = v; if root.ApplyLooks then root.ApplyLooks() end end)
    end

    Section(p, L("Fenêtres"))
    SwitchRow(p, L("Bouton de la minimap"), function() return not Guide().hideMinimap end, SetMinimap,
        L("Ouvre l'Accueil de WL Helper d'un clic."))
    SwitchRow(p, L("Rouvrir le guide à la connexion"), function() return Guide().reopenGuide == true end,
        function(v) Guide().reopenGuide = v end, L("Même si tu l'avais fermé avant de te déconnecter."))
end

function BUILD.dungeons(p)
    Section(p, L("Réglages du guide"))
    SwitchRow(p, L("Flèche du guide"), function() return Guide().arrow ~= false end, SetGuideArrow,
        L("Le GPS te mène à la prochaine étape du guide."))
    SwitchRow(p, L("Alerte des monstres rares"), function() return Guide().rareAlert ~= false end, function(v) Guide().rareAlert = v end,
        L("Dans un donjon, un message et un son quand un monstre rare apparaît."))
    SwitchRow(p, L("Points GPS à chaque étape"), function() return Guide().autoWay and true or false end,
        function(v) Guide().autoWay = v; RefreshGuide() end,
        L("Les points de l'étape en cours sont posés tout seuls quand une nouvelle étape commence."))
    -- "useful" hides the repeatable reputation quests and the quests of professions you don't have
    local row = Row(p, L("Quêtes répétables ou d'un autre métier"), L("Masquées, elles sortent de la route et du compte de quêtes de chaque donjon."))
    Choice(p, row, { { true, L("Masquer") }, { false, L("Afficher") } },
        function() return Guide().useful ~= false end,
        function(v)
            if (Guide().useful ~= false) == v then return end
            Guide().useful = v
            if root.Recalc and root.frame then root.Recalc() end
            if root.RenderPicker then root.RenderPicker() end
        end)
end

function BUILD.comptoir(p)
    Section(p, L("Automatismes"))
    SwitchRow(p, L("Rendre les Writs automatiquement"), function() return Comfort().autoTurnIn end, SetComfort("autoTurnIn"))
    SwitchRow(p, L("Rendre les caisses automatiquement"), function() return Comfort().autoCrates ~= false end, SetComfort("autoCrates"),
        L("En parlant à Dokimi ou à Marcy Baker."))
    SwitchRow(p, L("Accepter la quête en ouvrant l'enveloppe"), function() return Comfort().autoAccept end, SetComfort("autoAccept"))
    SwitchRow(p, L("Scanner l'HV à son ouverture"), function() return Writs().autoRescan end,
        function(v) Writs().autoRescan = v; RefreshWrits() end,
        L("Seulement si la fenêtre Writs est ouverte et que les prix ont plus d'une heure."))

    Section(p, L("Infos"))
    SwitchRow(p, L("Rappel à la connexion"), function() return Comfort().reminder end, SetComfort("reminder"),
        L("Par exemple : « 3 Writs prêts à rendre, 1 enveloppe à ouvrir »."))
    SwitchRow(p, L("Détails dans l'infobulle des enveloppes"), function() return Comfort().tooltip end, SetComfort("tooltip"),
        L("Réputation, coût, à qui la rendre, et si tu l'as déjà rendue."))

    Section(p, L("Plan"))
    local row = Row(p, L("Objectif de réputation"), L("Le plan achète les Writs qu'il faut pour l'atteindre."))
    Choice(p, row, {
        { 0, L("Rang suivant") }, { 6, L("Honoré") }, { 7, L("Révéré") },
    }, function() return Writs().goal or 0 end, function(v) Writs().goal = v; RefreshWrits() end)
    SwitchRow(p, L("Masquer les zones trop hautes"), function() return Writs().hideHigh end,
        function(v) Writs().hideHigh = v; RefreshWrits() end, L("Les zones au-dessus de ton niveau sortent du plan."))

    -- zones: the plan only buys writs of the zones left on (a single writ: right-click in "All writs")
    Section(p, L("Zones du plan"))
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
    local muted = S.Hex(T.muted)
    for _, map in ipairs(maps) do
        local lo = WP.ZoneMin(map)
        local label = WP.ZoneName(map)
        if lo then label = label .. "  " .. muted .. string.format(L("niv. %d+"), lo) .. "|r" end
        SwitchRow(p, label, function() return not WP.IsSkipped("zones", map) end,
            function(v) WP.SetSkipped("zones", map, not v) end)
    end
    Note(p, L("Pour écarter un seul Writ : clic droit dessus dans l'onglet « Tous les writs » des Writs."))
end

function BUILD.gps(p)
    Section(p, L("Itinéraire"))
    local row = Row(p, L("Calcul de l'itinéraire"), L("Automatique prend Zygor quand il est installé, sinon le GPS de WL Helper."))
    local seg = Choice(p, row, {
        { "auto", L("Automatique") },
        { "wl", L("WL Helper") },
        { "zygor", L("Zygor"), not ZygorPresent() },
    }, function() return Gps().provider or "auto" end, SetGps("provider"))
    for _, b in ipairs(seg.buttons or {}) do
        if b.value == "zygor" then b.tip = { L("Zygor"), L("Pas installé") } end
    end
    -- Zygor can finish loading after the window was built: re-check each time the page shows.
    function seg:Sync()
        self:SetDisabled("zygor", not ZygorPresent())
        for _, b in ipairs(self.buttons or {}) do
            if b.value == "zygor" then b.tip = (not ZygorPresent()) and { L("Zygor"), L("Pas installé") } or nil end
        end
    end

    Section(p, L("Trajet"))
    SwitchRow(p, L("Utiliser mes téléportations"), function() return Gps().teleports end, SetGps("teleports"))
    SwitchRow(p, L("Choisir le vol automatiquement"), function() return Gps().autoFlight end, SetGps("autoFlight"),
        L("Chez le maître de vol, le bon trajet est choisi pour toi."))
    row = Row(p, L("Points de vol connus"), L("Ceux que ce personnage a déjà découverts."))
    local known = ValueText(row, 80)
    function known:Sync()
        local G = ns.WP and ns.WP.GPS
        local ok, n = pcall(function() return G and G.KnownFlights and G.KnownFlights() end)
        self:SetText(tostring(ok and tonumber(n) or 0))
    end
    known:Sync()
    Place(p, row, known)
    SwitchRow(p, L("Distances en yards"), function() return Gps().yards end, SetGps("yards"), L("Sinon en mètres et en kilomètres."))
    local GT, Way = ns.WP.GoTo, ns.WP.Way
    if GT and GT.WalkOn and GT.SetWalk then
        SwitchRow(p, L("Chemins à pied"), function() return GT.WalkOn() end, function(v) GT.SetWalk(v) end,
            L("Pour « Aller à », la flèche suit un vrai chemin autour des collines et par les portes (WL Helper Nav). Sans lui, elle va tout droit."))
    end
    if Way and Way.SetTake then
        -- the setting itself, not who owns /way right now: /way is decided a few seconds after login
        local function wants()
            if Way.WantsWay then local ok, v = pcall(Way.WantsWay); if ok then return v and true or false end end
            return Way.Takes and Way.Takes() or false
        end
        local desc = L("Allumé, /way envoie le point au GPS de WL Helper. Éteint, /way reste à l'addon qui l'avait (TomTom par exemple) et /wlway fait la même chose.")
        local okO, other = pcall(function() return Way.OtherOwnerName and Way.OtherOwnerName() end)
        if okO and type(other) == "string" and other ~= "" then desc = desc .. " " .. string.format(L("/way est à %s."), other) end
        SwitchRow(p, L("Prendre /way"), wants, function(v) Way.SetTake(v) end, desc)
    end

    Section(p, L("Flèche"))
    PercentSlider(p, L("Taille de la flèche"), 70, 150, function() return Gps().scale end, SetGps("scale"))
    PercentSlider(p, L("Opacité du fond"), 0, 100, function() return Gps().alpha end, SetGps("alpha"))
    SwitchRow(p, L("Masquer en combat"), function() return Gps().hideCombat end, SetGps("hideCombat"))
    row = Row(p, L("Position de la flèche"), L("Fais-la glisser où tu veux à l'écran."))
    local move = S.Button(row, L("Déplacer la flèche"), 0, 28, "secondary", function()
        local G = ns.WP and ns.WP.GPS
        if G and G.UnlockArrow then G.UnlockArrow() end
    end)
    -- no arrow_up here: it read as "move up" (icon audit G3)
    function move:Sync()
        local G = ns.WP and ns.WP.GPS
        self:SetEnabled(G and G.UnlockArrow and true or false)
    end
    Place(p, row, move)
end

function BUILD.bags(p)
    Section(p, L("Place dans les sacs"))
    SwitchRow(p, L("Proposer de libérer une place"),
        function() return WLWritsDB.freeSlotPrompt ~= false end, function(v) WLWritsDB.freeSlotPrompt = v end,
        L("Quand tes sacs sont pleins, WL Helper propose de jeter l'objet le moins cher : un gris, ou une arme ou une armure blanche."))
    local other = ns.WP.Junk and ns.WP.Junk.OtherSeller and ns.WP.Junk.OtherSeller()
    SwitchRow(p, L("Vendre les gris chez les marchands"),
        function() return WLWritsDB.sellGreys ~= false end, function(v) WLWritsDB.sellGreys = v end,
        other and L("Un autre de tes addons les vend déjà : WL Helper le laisse faire.") or L("Dès que tu ouvres la fenêtre d'un marchand."))
    Note(p, L("Le nettoyeur ne propose jamais un objet qui lance une quête. Pour libérer une place à la main, tape /wlh free."))
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
    local function ApplyTip() if ns.WP.ApplyGFTip then ns.WP.ApplyGFTip() end end
    Section(p, L("Calcul"))
    local crow = Row(p, L("Méthode de calcul"), L("Prend les classements de ton addon d'équipement s'il y en a un, sinon les poids de WL Helper."))
    Choice(p, crow, { { "auto", L("Automatique") }, { "wl", L("Poids WL Helper") } },
        function() return WLWritsDB.upgradeSource == "wl" and "wl" or "auto" end,
        function(v) WLWritsDB.upgradeSource = v; Refresh() end)
    local srow = Row(p, L("Spé évaluée"), L("Auto : l'arbre de talents où tu as le plus de points."))
    Choice(p, srow, Wt.SpecChoices(),
        function() local db, c = SpecDB(); return db[c] or "auto" end,
        function(v) local db, c = SpecDB(); db[c] = v; Refresh(); if Rebuild then C_Timer.After(0, Rebuild) end end)

    -- dual or triple spec: the main spec always, the other specs of the class ticked here
    Section(p, L("Spés à comparer"))
    local mrow = Row(p, L("Spé principale"), L("Celle de tes talents, ou celle choisie plus haut. Toujours sur la première ligne."))
    local mainName = ValueText(mrow, 200)
    function mainName:Sync() self:SetText(Wt.SpecName()) end
    mainName:Sync()
    Place(p, mrow, mainName)
    for _, spec in ipairs(Wt.OtherSpecs and Wt.OtherSpecs() or {}) do
        local key = spec[1]
        SwitchRow(p, string.format(L("Comparer aussi : %s"), Wt.SpecName(spec)),
            function() return Wt.ExtraOn(key) end, function(v) Wt.SetExtra(key, v); Refresh() end,
            L("Une ligne de plus dans les infobulles d'objet pour cette spé."))
    end
    local arow = Row(p, L("Flèche pour"), L("Avec plusieurs spés, l'infobulle dit laquelle gagne."))
    Choice(p, arow, { { "main", L("Ma spé principale") }, { "any", L("N'importe laquelle de mes spés") } },
        function() return WLWritsDB.upgradeArrowFor == "any" and "any" or "main" end,
        function(v) WLWritsDB.upgradeArrowFor = (v == "any") and "any" or nil; Refresh() end)

    Section(p, L("Affichage"))
    local trow = Row(p, L("Flèche à partir de"), L("Le gain minimum pour mettre la flèche sur un objet."))
    local function pct(n) return string.format(L("%d %%"), n) end
    Choice(p, trow, { { 1, pct(1) }, { 3, pct(3) }, { 5, pct(5) }, { 10, pct(10) } },
        function() return WLWritsDB.upgradeMin or 1 end, function(v) WLWritsDB.upgradeMin = v; Refresh() end)
    SwitchRow(p, L("Ligne dans les infobulles d'objet"), function() return WLWritsDB.upgradeTip ~= false end,
        function(v) WLWritsDB.upgradeTip = v; ApplyTip() end, L("Le gain ou la perte pour ta spé, et l'objet qu'il remplacerait."))
    SwitchRow(p, L("Masquer le bloc en double des infobulles"), function() return WLWritsDB.hideGFTip ~= false end,
        function(v) WLWritsDB.hideGFTip = v; ApplyTip() end, L("Quand ton addon d'équipement affiche déjà le même pourcentage."))

    local _, label = Wt.Bracket()
    -- built once: a level-up across a bracket or a respec on Auto rebuilds the pages when shown
    local built = Wt.SpecName() .. label
    p.controls[#p.controls + 1] = { Sync = function()
        local _, l = Wt.Bracket()
        if Wt.SpecName() .. l ~= built and Rebuild then C_Timer.After(0, Rebuild) end
    end }
    Section(p, string.format(L("Poids utilisés : %s, niveaux %s"), Wt.SpecName(), label))
    -- a zebra list: stat name at the left, weight in a number column at the right
    local list = CreateFrame("Frame", nil, p)
    local lines = {}
    for i, e in ipairs(Wt.Table()) do
        local line = CreateFrame("Frame", nil, list)
        local z = (i % 2 == 0) and T.zebraB or T.zebraA
        S.Solid(line, "BACKGROUND", z):SetAllPoints()
        line.name = S.Text(line, F.label, T.text)
        line.name:SetJustifyH("LEFT")
        line.name:SetText(L(STAT_NAMES[e[1]] or e[1]))
        line.value = S.Text(line, F.label, T.fg)
        line.value:SetJustifyH("RIGHT")
        S.ClampLabel(line.value, nil, line)
        line.value:SetText(Decimal(e[2]))
        lines[i] = line
    end
    Add(p, list, function(width)
        local y = 0
        for _, line in ipairs(lines) do
            line:ClearAllPoints()
            line:SetPoint("TOPLEFT", list, "TOPLEFT", 0, -y)
            line:SetWidth(width)
            line.value:ClearAllPoints(); line.value:SetPoint("TOPRIGHT", -12, -7); line.value:SetWidth(56)
            line.name:ClearAllPoints(); line.name:SetPoint("TOPLEFT", 8, -7)
            local h = math.max(28, 7 + math.max(15, root.FitText(line.name, 2, width - 8 - 12 - 56 - 8, line)) + 6)
            line:SetHeight(h)
            y = y + h
        end
        list:SetHeight(math.max(1, y))
        return y
    end, "list", 4)
    Note(p, L("Ces poids sont ceux de WL Helper, par classe et par spé, ajustés à ta tranche de niveaux (1-20, 21-40, 41-59, 60). Les dégâts d'une école de magie comptent selon ta spé. Un objet que ta classe ne peut pas porter n'a pas de flèche."))
end

local function Version()
    local meta = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
    local ok, v = pcall(meta or function() end, ADDON, "Version")
    return ok and v or "?"
end

local GITHUB = "https://github.com/WarLegenDHelper/WLHelper"

-- Selectable, read-only link: an input that puts its text back if typed into.
local function CopyBox(parent, text, width)
    local eb = S.Input(parent, width, {})
    eb:SetTextColor(T.accentSoft[1], T.accentSoft[2], T.accentSoft[3])
    eb:SetText(text)
    eb:SetCursorPosition(0)
    eb:SetScript("OnTextChanged", function(self, user)
        if user then self:SetText(text); self:HighlightText() end
        self.Paint()
    end)
    eb:HookScript("OnEditFocusGained", function(self) self:HighlightText() end)
    eb:SetScript("OnMouseUp", function(self) self:SetFocus(); self:HighlightText() end)
    eb:SetScript("OnEscapePressed", function(self) self:HighlightText(0, 0); self:ClearFocus() end)
    eb:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    eb:SetScript("OnEnter", function(self) S.Tip(self, { text, L("Clic : sélectionner le lien") }) end)
    eb:SetScript("OnLeave", S.HideTip)
    return eb
end

function BUILD.about(p)
    -- the addon: logo, name, version, who it is for
    local head = CreateFrame("Frame", nil, p)
    local logo = head:CreateTexture(nil, "ARTWORK")
    logo:SetSize(48, 48); logo:SetPoint("TOPLEFT", 0, 0)
    logo:SetTexture(S.LOGO)
    local name = S.Text(head, F.title, T.fg, true)
    name:SetJustifyH("LEFT"); name:SetWordWrap(false)
    name:SetText("WL Helper")
    local ver = S.Text(head, F.meta, T.muted)
    ver:SetJustifyH("LEFT"); ver:SetWordWrap(false)
    ver:SetText(string.format(L("Version %s"), Version()))
    local guild = S.Text(head, F.body, T.text)
    guild:SetJustifyH("LEFT"); guild:SetJustifyV("TOP")
    guild:SetText(L("Pour la guilde WaR LegenD."))
    Add(p, head, function(width)
        name:ClearAllPoints(); name:SetPoint("TOPLEFT", logo, "TOPRIGHT", 12, -2); name:SetWidth(width - 60)
        ver:ClearAllPoints(); ver:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -3); ver:SetWidth(width - 60)
        guild:ClearAllPoints(); guild:SetPoint("TOPLEFT", ver, "BOTTOMLEFT", 0, -4)
        local nh = math.max(18, num(name:GetStringHeight()) or 0)
        local vh = math.max(13, num(ver:GetStringHeight()) or 0)
        local gh = math.max(15, root.FitText(guild, 2, width - 60, head))
        local h = math.ceil(math.max(48, 2 + nh + 3 + vh + 4 + gh))
        head:SetHeight(h)
        return h
    end, "block", 12)

    local function info(label, value)
        local row = Row(p, label)
        local v = ValueText(row, CARD_W - 2 * INSET - 120)
        v:SetText(value)
        Place(p, row, v)
    end
    Section(p, L("Crédits"))
    info(L("Auteur"), "Alandir (WaR LegenD)")
    info(L("Logo"), L("WaR LegenD (War Legend Raid Tool)"))
    -- the link under its label, across the whole row: never cut
    local row = Row(p, L("Code source"), L("Clique sur le lien, puis Ctrl+C pour le copier."))
    local link = CopyBox(row, GITHUB, CARD_W - 2 * INSET)
    function row:Layout(width)
        local textW = width - 2 * INSET
        self.label:ClearAllPoints(); self.label:SetPoint("TOPLEFT", INSET, -8)
        local lh = math.max(15, root.FitText(self.label, 2, textW, self))
        self.desc:ClearAllPoints(); self.desc:SetPoint("TOPLEFT", self.label, "BOTTOMLEFT", 0, -3)
        local dh = math.max(13, root.FitText(self.desc, 0, textW, self))
        link:ClearAllPoints(); link:SetPoint("TOPLEFT", self.desc, "BOTTOMLEFT", 0, -8)
        link:SetWidth(textW)
        local bh = num(link:GetHeight()) or 28
        if bh <= 0 then bh = 28 end
        return math.ceil(8 + lh + 3 + dh + 8 + bh + 12)
    end
    Note(p, L("Sources et remerciements : le fichier CREDITS.txt dans le dossier de l'addon."))

    -- an idea, a bug: one sentence, two buttons under it
    Section(p, L("Une idée, un bug ?"))
    local fb = CreateFrame("Frame", nil, p)
    local say = S.Text(fb, F.body, T.text)
    say:SetJustifyH("LEFT"); say:SetJustifyV("TOP")
    say:SetText(L("Dis-nous ce qui manque ou ce qui coince. Chaque bouton t'affiche un lien à ouvrir dans ton navigateur."))
    -- labelled: no star or warning beside the words (icon audit G3)
    local bIdea = S.Button(fb, L("Proposer une idée"), 0, 28, "secondary", function() if ns.WP.Feedback then ns.WP.Feedback("idea") end end)
    local bBug = S.Button(fb, L("Signaler un bug"), 0, 28, "secondary", function() if ns.WP.Feedback then ns.WP.Feedback("bug") end end)
    Add(p, fb, function(width)
        say:ClearAllPoints(); say:SetPoint("TOPLEFT", 0, 0)
        local h = math.max(15, root.FitText(say, 0, width, fb))
        bIdea:ClearAllPoints(); bIdea:SetPoint("TOPLEFT", 0, -(h + 12))
        bBug:ClearAllPoints(); bBug:SetPoint("LEFT", bIdea, "RIGHT", 8, 0)
        h = math.ceil(h + 12 + 28)
        fb:SetHeight(h)
        return h
    end, "block", 8)
    Register(p, fb, L("Une idée, un bug ?"), L("Proposer une idée") .. " " .. L("Signaler un bug"))

    Section(p, L("Commandes du chat"))
    -- the same list as /wlh help, in the guide's language
    Note(p, root.L and root.L.HELP or "/wlh", F.label, T.text)
end

-- ---------------------------------------------------------------- the window

local win, body, current

-- A module page's first card: the module's painted icon, its name, what it does and a button to
-- open it; when it is switched off, a sentence that says so and the button that turns it back on.
local OPEN = {
    dungeons = { "Ouvrir le guide", function()
        if root.GuideStatus and root.GuideStatus() then root.ShowGuide() elseif root.ShowPicker then root.ShowPicker() end
    end },
    comptoir = { "Ouvrir les Writs", function() ns.WP.Open("writs") end },
    bags = { "Nettoyer les sacs", function() if ns.WP.Cleaner then ns.WP.Cleaner.Toggle() end end },
}
local function ModuleCard(p, pageKey, mod)
    local m = { key = mod, label = mod }
    for _, x in ipairs(ns.WP.MODULES) do if x.key == mod then m = x end end
    local c = CreateFrame("Frame", nil, p)
    c.bg = S.Solid(c, "BACKGROUND", T.cardFill); c.bg:SetAllPoints()
    S.Border(c, T.cardEdge)
    c.iconFrame = CreateFrame("Frame", nil, c)
    c.iconFrame:SetSize(32, 32); c.iconFrame:SetPoint("TOPLEFT", 12, -12)
    c.icon = c.iconFrame:CreateTexture(nil, "ARTWORK"); c.icon:SetAllPoints()
    -- an HD glyph sits 6 px inside the box (as on the Home card); a painted icon fills it
    if PaintIcon(c.icon, MODULE_ICON[mod] or "Interface\\Icons\\INV_Misc_Map_01", T.fg) then
        c.icon:ClearAllPoints(); c.icon:SetPoint("TOPLEFT", 6, -6); c.icon:SetPoint("BOTTOMRIGHT", -6, 6)
    end
    S.Border(c.iconFrame, T.cardEdge)
    c.title = S.Text(c, F.heading, T.fg)
    c.title:SetJustifyH("LEFT"); c.title:SetJustifyV("TOP")
    c.title:SetText(ModLabel(m))
    c.line = S.Text(c, F.meta, T.muted)
    c.line:SetJustifyH("LEFT"); c.line:SetJustifyV("TOP")
    c.line:SetWordWrap(true)
    c.on = S.Button(c, L("Allumer le module"), 0, 28, "primary", function()
        ns.WP.SetModule(mod, true)   -- re-syncs this window too
        if ns.WP.RefreshHome then ns.WP.RefreshHome() end
    end)
    local open = OPEN[pageKey]
    if open then
        c.open = S.Button(c, L(open[1]), 0, 28, "secondary", open[2])
    end
    p.controls[#p.controls + 1] = { Sync = function()
        local on = ns.WP.ModuleOn(mod)
        c.on:SetShown(not on)
        if c.open then c.open:SetShown(on) end
        c.line:SetText(on and ModDesc(m) or L("Éteint : il ne montre plus rien. Tes réglages sont gardés."))
        local col = on and T.muted or T.warn
        c.line:SetTextColor(col[1], col[2], col[3])
        c.iconFrame:SetAlpha(on and 1 or 0.5)
    end }
    Add(p, c, function(width)
        local btn = (c.on:IsShown() and c.on) or (c.open and c.open:IsShown() and c.open) or nil
        local bw = btn and (num(btn:GetWidth()) or 0) + 12 or 0
        local textW = math.max(80, width - 52 - 12 - bw)
        c.title:ClearAllPoints(); c.title:SetPoint("TOPLEFT", 52, -12)
        local th = math.max(17, root.FitText(c.title, 2, textW, c))
        c.line:ClearAllPoints(); c.line:SetPoint("TOPLEFT", c.title, "BOTTOMLEFT", 0, -3)
        local lh = math.max(13, root.FitText(c.line, 0, textW, c))
        local inner = math.max(32, th + 3 + lh)
        local h = math.ceil(12 + inner + 12)
        c.on:ClearAllPoints(); c.on:SetPoint("RIGHT", c, "RIGHT", -12, 0)
        if c.open then c.open:ClearAllPoints(); c.open:SetPoint("RIGHT", c, "RIGHT", -12, 0) end
        c:SetHeight(h)
        return h
    end, "band", 12)
    -- found by the search as well
    Register(p, c, ModLabel(m), ModDesc(m))
    c.pageY = 12
end

-- Builds the nav and every page into a fresh body frame (again after a language change).
local function BuildBody()
    for i = #INDEX, 1, -1 do INDEX[i] = nil end
    body = CreateFrame("Frame", nil, win)
    body:SetPoint("TOPLEFT", 0, -(HEADER_H + 1))
    body:SetPoint("BOTTOMRIGHT", 0, 0)

    local nav = CreateFrame("Frame", nil, body)
    nav:SetPoint("TOPLEFT"); nav:SetPoint("BOTTOMLEFT"); nav:SetWidth(NAV_W)
    local edge = S.Solid(body, "BORDER", T.divider)
    edge:SetPoint("TOPLEFT", NAV_W, 0); edge:SetPoint("BOTTOMLEFT", NAV_W, 0); edge:SetWidth(1)
    root.PixelLine(body, edge, false)

    local content = CreateFrame("Frame", nil, body)
    content:SetPoint("TOPLEFT", NAV_W + 1, 0); content:SetPoint("BOTTOMRIGHT")
    body.content = content

    body.pages, body.tabs = {}, {}
    for i, def in ipairs(PAGES) do
        -- a nav item: painted icon 20 + label 12; selected: selection fill and bright label
        local b = CreateFrame("Button", nil, nav)
        local y = -(NAV_TOP + (i - 1) * (NAV_ITEM_H + NAV_GAP))
        b:SetHeight(NAV_ITEM_H)
        b:SetPoint("TOPLEFT", 8, y); b:SetPoint("TOPRIGHT", -8, y)
        b.sel = S.Solid(b, "BACKGROUND", T.selFill); b.sel:SetAllPoints(); b.sel:Hide()
        b.hl = S.Solid(b, "BACKGROUND", T.hoverFill); b.hl:SetAllPoints(); b.hl:SetAlpha(0)
        b.press = S.Solid(b, "BORDER", T.pressFill); b.press:SetAllPoints(); b.press:Hide()
        b.iconFrame = CreateFrame("Frame", nil, b)
        b.iconFrame:SetSize(20, 20); b.iconFrame:SetPoint("LEFT", 8, 0)
        b.icon = b.iconFrame:CreateTexture(nil, "ARTWORK")
        -- painted: 20 px in a 1 px edge; an HD glyph: 16 px, no edge, tinted like the label
        b.hdIcon = PaintIcon(b.icon, def.icon)
        b.hdColor = b.hdIcon and def.icon.color or nil
        if b.hdIcon then
            b.icon:SetSize(16, 16); b.icon:SetPoint("CENTER")
        else
            b.icon:SetAllPoints()
            S.Border(b.iconFrame, T.cardEdge)
        end
        b.count = S.Counter(b)
        b.count:SetPoint("RIGHT", -8, 0)
        b.label = S.Text(b, F.label, T.muted)
        b.label:SetPoint("LEFT", 36, 0); b.label:SetPoint("RIGHT", -8, 0)
        b.label:SetJustifyH("LEFT")
        b.label:SetText(L(def.label))
        S.ClampLabel(b.label, L(def.label), b)
        b.key = def.key
        b:SetScript("OnEnter", function(self)
            root.Tween(self.hl, num(self.hl:GetAlpha()) or 0, 1, 0.10, function(v) self.hl:SetAlpha(v) end)
            self.hover = true
            body.PaintNav()
            S.Tip(self, { L(def.label), L(def.desc), L("Clic : afficher ces réglages") })
        end)
        b:SetScript("OnLeave", function(self)
            root.Tween(self.hl, num(self.hl:GetAlpha()) or 0, 0, 0.10, function(v) self.hl:SetAlpha(v) end)
            self.hover = nil
            body.PaintNav()
            S.HideTip()
        end)
        b:SetScript("OnMouseDown", function(self) self.press:Show() end)
        b:SetScript("OnMouseUp", function(self) self.press:Hide() end)
        b:SetScript("OnClick", function(self) ns.WP.ShowOptionsPage(self.key) end)
        body.tabs[i] = b

        local p = NewPage(content)
        p.key, p.pageLabel, p.pageIcon = def.key, L(def.label), def.icon
        local mod = ({ dungeons = "dungeons", comptoir = "writs", bags = "bags", upgrades = "upgrades" })[def.key]
        if mod then ModuleCard(p, def.key, mod) end
        BUILD[def.key](p)
        body.pages[def.key] = p
    end

    -- Selected page: selection fill and bright label; hover: soft fill and bright label.
    function body.PaintNav()
        for _, b in ipairs(body.tabs) do
            local on = b.key == current
            b.sel:SetShown(on)
            local c = (on or b.hover) and T.fg or T.muted
            b.label:SetTextColor(c[1], c[2], c[3])
            if b.hdIcon and not b.hdColor then b.icon:SetVertexColor(c[1], c[2], c[3]) end
            b.iconFrame:SetAlpha((on or b.hover) and 1 or 0.8)
        end
    end
    BuildSearch(nav, content)
end

local function PaintNav() if body and body.PaintNav then body.PaintNav() end end

-- Fits the window to the page (or the search results) and the nav, whichever is taller.
local function FitNow()
    if not (win and body) then return end
    local h
    local p = body.pages[current]
    h = p and p.contentH or 0
    -- while searching, never shorter than the page: the window does not jump at each key
    if body.results and body.results:IsShown() then h = math.max(h, body.resultsH or 0) end
    local bodyH = math.max(NAV_H, h)
    win:FitHeight(bodyH - 24)   -- the window adds 12 above and 12 below the content
end

Relayout = function(later)
    if not (win and body) then return end
    local function go()
        if body.results and body.results:IsShown() then
            if body.LayoutResults then body.LayoutResults() end
        else
            local p = body.pages[current]
            if p then p:Layout() end
        end
        FitNow()
    end
    go()
    -- wrapped text measures right once its width is applied: once more on the next frame
    if later ~= false and C_Timer and C_Timer.After then
        C_Timer.After(0, function() if win and win:IsShown() then go() end end)
    end
end

local function BuildWindow()
    win = S.Window("WLHelperOptions", WIN_W, 400, L("Réglages"), "WL Helper " .. Version(), WLWritsDB, "optionsPos",
        { header = HEADER_H, minH = HEADER_H + 1 + NAV_H })
    BuildBody()
end

Rebuild = function()
    if not win then return end
    local keep = current
    body:Hide()
    body:SetParent(nil)   -- the old frames stay orphaned; a language change is rare
    BuildBody()
    win.title:SetText(L("Réglages"))
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
    local p = body.pages[key]
    p:Sync()
    PaintNav()
    Relayout()
end

-- ---------------------------------------------------------------- search

BuildSearch = function(nav, content)
    local box = S.Input(nav, NAV_W - 24, { search = true, placeholder = L("Ex. flèche") })
    box:SetPoint("TOPLEFT", 12, -12)
    body.searchBox = box
    ns.WP.searchBox = box   -- for a key binding, and the offline tests
    box.wlBody = body

    -- results, in place of the page
    local sa = S.ScrollArea(content)
    sa:SetAllPoints(); sa:Hide()
    body.results = sa
    local list = sa.child
    list:SetWidth(CONTENT_W)
    local summary = S.Text(list, F.body, T.fg)
    summary:SetJustifyH("LEFT"); summary:SetJustifyV("TOP")
    local how = S.Text(list, F.meta, T.muted)
    how:SetJustifyH("LEFT"); how:SetJustifyV("TOP")
    local empty = S.EmptyState(list, "search", "", L("Essaie un autre mot, en français ou en anglais."),
        L("Effacer la recherche"), function() box:SetText(""); box:SetFocus() end, "secondary")
    empty:Hide()
    local heads, rows, shown, sel = {}, {}, {}, 1
    local hitsN = 0

    local function Head(i)
        local h = heads[i]
        if not h then h = S.SectionHeader(list, ""); heads[i] = h end
        h:Show(); return h
    end
    local Pick
    local function ResultRow(i)
        local r = rows[i]
        if r then r:Show(); return r end
        r = S.ListRow(list, { density = "dense", onClick = function(self) Pick(self.entry) end })
        r.tip = function(self)
            local e = self.entry
            if not e then return nil end
            local t = { e.label or "" }
            if e.hint and e.hint ~= "" then t[#t + 1] = e.hint end
            t[#t + 1] = L("Clic : afficher ce réglage")
            return t
        end
        rows[i] = r
        return r
    end

    local function Paint()
        for i, r in ipairs(shown) do r:SetSelected(i == sel) end
    end

    -- The text folded like Fold(), one UTF-8 letter at a time, with the source bytes of each folded
    -- byte; only the plain part before a colour code (a zone's grey level stays as it is).
    local function FoldMap(text)
        local stop = (text:find("|c", 1, true) or (#text + 1)) - 1
        local out, map, i = {}, {}, 1
        while i <= stop do
            local b = text:byte(i)
            local len = (b >= 240 and 4) or (b >= 224 and 3) or (b >= 192 and 2) or 1
            local ch = text:sub(i, i + len - 1)
            local f = (len > 1) and (FOLD[ch] or ch) or ch:lower()
            for k = 1, #f do out[#out + 1] = f:sub(k, k); map[#out] = { i, i + len - 1 } end
            i = i + len
        end
        return table.concat(out), map
    end
    -- the found words in the link colour, in the label as shown (accents included)
    local function Mark(text, words)
        local folded, map = FoldMap(text)
        local spans = {}
        for _, w in ipairs(words) do
            local i, j = folded:find(w, 1, true)
            if i and map[i] and map[j] then spans[#spans + 1] = { map[i][1], map[j][2] } end
        end
        if #spans == 0 then return text end
        -- merge the overlaps, then insert from the right so the earlier offsets stay valid
        table.sort(spans, function(x, y) return x[1] < y[1] end)
        local merged = { spans[1] }
        for k = 2, #spans do
            local last, cur = merged[#merged], spans[k]
            if cur[1] <= last[2] + 1 then last[2] = math.max(last[2], cur[2]) else merged[#merged + 1] = cur end
        end
        local out, hex = text, S.Hex(T.accentSoft)
        for k = #merged, 1, -1 do
            local a, z = merged[k][1], merged[k][2]
            out = out:sub(1, a - 1) .. hex .. out:sub(a, z) .. "|r" .. out:sub(z + 1)
        end
        return out
    end

    local function NavCounts(counts, searching)
        for _, b in ipairs(body.tabs) do
            local n = counts and counts[b.key] or 0
            if searching and n > 0 then b.count:SetCount(n) else b.count:Hide() end
            b.label:SetPoint("RIGHT", b, "RIGHT", (searching and n > 0) and -(8 + 18 + 4) or -8, 0)
            b:SetAlpha((searching and n == 0) and T.disabledAlpha or 1)
        end
    end

    -- places the summary, the headers and the rows; returns the list height
    local layoutPlan = {}
    function body.LayoutResults()
        local width = CARD_W
        local y = 12
        if hitsN == 0 then
            summary:Hide(); how:Hide()
            empty:SetWrapWidth(width)
            empty:ClearAllPoints(); empty:SetPoint("TOP", list, "TOP", 0, -24)
            y = 24 + (empty.blockH or empty:Fit()) + 16
        else
            summary:Show(); how:Show()
            summary:ClearAllPoints(); summary:SetPoint("TOPLEFT", INSET, -y)
            y = y + math.max(15, root.FitText(summary, 2, width, list))
            how:ClearAllPoints(); how:SetPoint("TOPLEFT", INSET, -(y + 3))
            y = y + 3 + math.max(13, root.FitText(how, 2, width, list))
            for _, it in ipairs(layoutPlan) do
                if it.head then
                    y = y + 8
                    it.head:ClearAllPoints(); it.head:SetPoint("TOPLEFT", INSET, -y); it.head:SetWidth(width)
                    y = y + 32 + 4
                else
                    local r = it.row
                    r:ClearAllPoints(); r:SetPoint("TOPLEFT", INSET, -y); r:SetWidth(width)
                    r.y = y
                    y = y + r:Fit(width) + 2
                end
            end
            y = y + 14
        end
        y = math.ceil(y)
        body.resultsH = y
        sa:SetContentHeight(y)
        return y
    end

    local function Update()
        local raw = box:GetText() or ""
        local q = Fold(raw)
        if #q < 2 then
            local was = sa:IsShown()
            sa:Hide(); NavCounts(nil, false)
            local page = body.pages[current]
            if was and page and not page:IsShown() then page:Show() end
            if was then Relayout() end
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
        sa:Show(); sa:ScrollTo(0, true)
        NavCounts(counts, true)
        for _, h in ipairs(heads) do h:Hide() end
        for _, r in ipairs(rows) do r:Hide(); r.entry = nil end
        wipe(shown)
        wipe(layoutPlan)
        hitsN = #hits
        if hitsN == 0 then
            empty:Set("search", string.format(L("Aucun réglage pour « %s »"), raw), L("Essaie un autre mot, en français ou en anglais."),
                L("Effacer la recherche"), function() box:SetText(""); box:SetFocus() end, "secondary")
            empty:Show()
        else
            empty:Hide()
            summary:SetText(hitsN == 1 and L("1 réglage trouvé") or string.format(L("%d réglages trouvés"), hitsN))
            how:SetText(hitsN == 1 and L("Entrée pour l'ouvrir.") or L("Flèches haut et bas pour choisir, Entrée pour ouvrir."))
        end
        local page, hi, ri = nil, 0, 0
        for _, h in ipairs(hits) do
            local e = h.e
            if e.page ~= page then
                page = e.page
                hi = hi + 1
                local head = Head(hi)
                -- the page's name only: an icon there was decoration (icon audit, Settings)
                head:Set(e.pageLabel or "", counts[page] or 0)
                layoutPlan[#layoutPlan + 1] = { head = head }
            end
            ri = ri + 1
            local r = ResultRow(ri)
            r.entry = e
            -- the description when there is one (the page header already names the place), else the section
            local detail = (e.hint and e.hint ~= "" and e.hint)
                or (e.section ~= "" and e.section ~= e.pageLabel and e.section) or nil
            r:Set({ name = Mark(e.label or "", words), detail = detail })
            shown[#shown + 1] = r
            layoutPlan[#layoutPlan + 1] = { row = r }
        end
        sel = 1
        Paint()
        Relayout()
    end

    -- opens the page, scrolls the row into view and makes it flash
    Pick = function(e)
        if not e then return end
        sa:Hide()
        ShowPage(e.page)   -- clears the box quietly
        box:ClearFocus()
        local p = body.pages[e.page]
        local view = num(p.sa:GetHeight()) or 400
        p.sa:ScrollTo((e.row.pageY or 0) - view / 3, true)
        local row = e.row
        if not row.flash then row.flash = S.Solid(row, "BACKGROUND", T.selFill); row.flash:SetAllPoints() end
        row.flash:SetAlpha(1)
        root.Tween(row.flash, 1, 0, 1.5, function(v) row.flash:SetAlpha(v) end)
    end

    box:SetScript("OnTextChanged", function(self)
        self.Paint()
        if not body.searchSilent then Update() end
    end)
    body.ClearSearch = function()
        box.Paint(); NavCounts(nil, false)
    end
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
        local top = r.y or 0
        local view = num(sa:GetHeight()) or 400
        local cur = sa:GetScroll() or 0
        local rh = num(r:GetHeight()) or 36
        if top < cur then sa:ScrollTo(math.max(0, top - 40), true)
        elseif top + rh > cur + view then sa:ScrollTo(top + rh - view + 8, true) end
    end)

    -- Ctrl+F while the window is open: into the box. Listens only out of combat, with every other
    -- key passed on to the game.
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
        body.pages[current]:Sync()
        Relayout()
    end
end

function ns.WP.ShowOptionsPage(key)
    if not win then BuildWindow() end
    win:Show()
    ShowPage(key or current or "general")
end

-- Opens the options on a page ("general"|"dungeons"|"comptoir"|"gps"|"bags"|"upgrades"|"about");
-- closes them when they are already open on that page (or on any page when no page is given).
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

-- A small canvas: logo, name, one sentence and the button that opens our own window.
local function RegisterGameSettings()
    local panel = CreateFrame("Frame")
    panel.name = "WL Helper"
    local logo = panel:CreateTexture(nil, "ARTWORK")
    logo:SetSize(48, 48)
    logo:SetPoint("TOPLEFT", 16, -16)
    logo:SetTexture(S.LOGO)
    local title = S.Text(panel, F.title, T.fg, true)
    title:SetPoint("TOPLEFT", logo, "TOPRIGHT", 12, -2)
    title:SetWordWrap(false)
    title:SetText("WL Helper")
    local ver = S.Text(panel, F.meta, T.muted)
    ver:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -3)
    ver:SetWordWrap(false)
    ver:SetText(string.format(L("Version %s"), Version()))
    local desc = S.Text(panel, F.body, T.text)
    desc:SetPoint("TOPLEFT", logo, "BOTTOMLEFT", 0, -12)
    desc:SetWidth(480); desc:SetJustifyH("LEFT")
    desc:SetText(L("Le guide de quêtes, les Writs, le GPS et les outils de la guilde WaR LegenD."))
    local open = S.Button(panel, L("Ouvrir les réglages"), 0, 32, "primary", OpenFromOutside)
    open:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -12)

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
                description = L("Les réglages les plus utilisés. Tous les autres sont dans la fenêtre Réglages de WL Helper."),
                pages = { L("Réglages") },
                buildPage = function(pageName, parent, yOffset)
                    local W = EllesmereUI.Widgets
                    local y = yOffset
                    local _, h
                    local function toggle(label, get, set)
                        _, h = W:Toggle(parent, label, y, get, set); y = y - h
                    end
                    _, h = W:SectionHeader(parent, L("Général"), y); y = y - h
                    toggle(L("Bouton de la minimap"), function() return not Guide().hideMinimap end, SetMinimap)
                    toggle(L("Flèche du guide"), function() return Guide().arrow ~= false end, SetGuideArrow)

                    _, h = W:SectionHeader(parent, L("Writs"), y); y = y - h
                    toggle(L("Rendre les Writs automatiquement"), function() return Comfort().autoTurnIn end, SetComfort("autoTurnIn"))
                    toggle(L("Accepter la quête en ouvrant l'enveloppe"), function() return Comfort().autoAccept end, SetComfort("autoAccept"))

                    _, h = W:SectionHeader(parent, L("GPS"), y); y = y - h
                    toggle(L("Utiliser Zygor quand il est installé"), function() return Gps().provider ~= "wl" end,
                        function(v) SetGps("provider")(v and "auto" or "wl") end)
                    toggle(L("Utiliser mes téléportations"), function() return Gps().teleports end, SetGps("teleports"))
                    toggle(L("Masquer la flèche en combat"), function() return Gps().hideCombat end, SetGps("hideCombat"))

                    -- Our own button (not indexed by EUI's search); no frames during the search pre-build.
                    y = y - 16
                    local prebuild = EllesmereUI.IsSearchPrebuild and EllesmereUI.IsSearchPrebuild()
                    if not prebuild then
                        local b = S.Button(parent, L("Ouvrir les réglages"), 0, 32, "primary", OpenFromOutside)
                        b:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, y)
                    end
                    y = y - 32 - 16
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
