-- Writs/Home.lua: the Home page of the WL Helper window (the Hub, Writs/Options.lua), and the
-- minimap button's tooltip and menu.
-- From the top: "Où veux-tu aller ?" (a search field on WP.GoTo: Enter guides you to the first place);
-- "now", only what a line cannot do (start the Writs tour, an event about to start, the city tour,
-- a nearly full log, a running GPS; hidden when nothing waits); a line when a newer version exists;
-- "Cette semaine" (beta.197): the weekly reset, then two cards side by side, the PvE weekly (the
-- Undermine Satchel: where you stand, what, where, the reward, "Y aller" and its guide) and the PvP
-- weekly (the battleground in bonus, Field of Honor, the reward, the guild ranking, "Y aller" and
-- the battlegrounds window);
-- then one large card per activity of WP.HUB_GROUPS (beta.173, report: "too many small logos, PvP
-- is hard to see") but PvP (its weekly card) and "Aide et retours" (a thin strip at the very
-- bottom), 2 a line (ns.GRID.homeCards): the activity's icon and name,
-- one useful sentence (where the guide stands, the Writs to turn in...), one button that does it,
-- then a compact line per window of the activity (S.HubRow compact: name, where you stand, a dot
-- when it has something to do now, a right-click opens its settings; a card with one window shows
-- no line, its button opens it); last, "Recharges"
-- (WP.Cooldowns: one card per character with its profession cooldowns and the time left, ready in
-- green, 2 or 3 cards a line; hidden when none is known). The lines never move. Opened by /wlh, a click on the minimap
-- button and the "<" of every window.
local ADDON, root = ...
root.Writs = root.Writs or {}
local ns = root.Writs
local WP = ns.WP
local L = ns.L
local S = ns.S
local C = S.C
local F = S.F

ns.AddEnglish({
    ["%s, niv. %d"] = "%s, level %d",
    -- the search field
    ["Où veux-tu aller ?"] = "Where do you want to go?",
    ["Voir tous les résultats"] = "See all results",
    ["Ouvrir « Aller à »"] = "Open Go to",
    -- the lines of Home
    ["Outils"] = "Tools",
    ["Un lieu, un PNJ, une ville : le GPS t'y mène"] = "A place, an NPC, a city: the GPS takes you there",
    ["Clic : ouvrir « Aller à »"] = "Click: open Go to",
    ["Clic droit : réglages"] = "Right-click: settings",
    ["Aucune clé pour l'instant (%d en tout)"] = "No keys yet (%d in all)",
    ["Il te faut %s pour entrer dans %s."] = "You need %s to get into %s.",
    ["Ce qu'il y a à faire en arrivant dans une capitale"] = "What there is to do when you arrive in a capital",
    ["1 chose à faire dans cette ville"] = "1 thing to do in this city",
    ["%d choses à faire dans cette ville"] = "%d things to do in this city",
    ["Clic : ouvrir la tournée en ville"] = "Click: open the city tour",
    ["Les membres qui font les mêmes donjons que toi"] = "Members doing the same dungeons as you",
    ["Clic : voir les quêtes en commun"] = "Click: see the shared quests",
    ["Journal : %d quêtes sur %d"] = "Log: %d of %d quests",
    ["1 quête à abandonner"] = "1 quest to abandon",
    ["%d quêtes à abandonner"] = "%d quests to abandon",
    ["Clic : voir les quêtes à abandonner"] = "Click: see the quests you can abandon",
    ["1 chose à faire dans cette ville."] = "1 thing to do in this city.",
    ["%d choses à faire dans cette ville."] = "%d things to do in this city.",
    ["Voir la tournée"] = "See the tour",
    ["Ton journal de quêtes est presque plein."] = "Your quest log is nearly full.",
    ["Réglages"] = "Settings",
    ["Clic : ouvrir les réglages"] = "Click: open settings",
    ["Une idée, un bug ?"] = "An idea, a bug?",
    ["Clic : ouvrir le formulaire pour nous écrire"] = "Click: open the form to write to us",
    -- "now"
    ["Le GPS te guide vers %s."] = "The GPS is guiding you to %s.",
    ["Le GPS te guide."] = "The GPS is guiding you.",
    ["Arrêter le GPS"] = "Stop the GPS",
    ["1 Writ est prêt à rendre."] = "1 Writ is ready to turn in.",
    ["%d Writs sont prêts à rendre."] = "%d Writs are ready to turn in.",
    ["Voir les Writs"] = "See Writs",
    ["%s commence dans %d min."] = "%s starts in %d min.",
    ["%s a commencé."] = "%s has started.",
    ["Voir l'événement"] = "See the event",
    ["Prochaine étape : %s"] = "Next step: %s",
    ["Reprendre le guide"] = "Resume guide",
    ["Nettoyer les sacs"] = "Clean bags",
    -- the cards
    ["Guide de quêtes"] = "Quest guide",
    ["Étape %d sur %d"] = "Step %d of %d",
    ["Choisis ton prochain guide."] = "Pick your next guide.",
    ["Aucun guide choisi"] = "No guide picked",
    ["Donjons, raids et quêtes de classe, depuis là où tu es."] = "Dungeons, raids and class quests, from where you are.",
    ["Terminée"] = "Finished",
    ["Clic : ouvrir le guide"] = "Click: open the guide",
    ["Clic : tous les guides"] = "Click: every guide",
    ["Clic : choisir un guide"] = "Click: pick a guide",
    ["Writs"] = "Writs",
    ["Encore 1 point avant %s"] = "1 more point to %s",
    ["Encore %s points avant %s"] = "%s more points to %s",
    ["%s atteint"] = "%s reached",
    ["Faction pas encore vue"] = "Faction not seen yet",
    ["Parle à un PNJ de cette faction pour qu'elle apparaisse."] = "Talk to one of the faction's NPCs to unlock it.",
    ["1 Writ prêt à rendre"] = "1 Writ ready to turn in",
    ["%d Writs prêts à rendre"] = "%d Writs ready to turn in",
    ["1 enveloppe à ouvrir"] = "1 envelope to open",
    ["%d enveloppes à ouvrir"] = "%d envelopes to open",
    ["Rien à rendre pour l'instant"] = "Nothing to turn in yet",
    ["Clic : ouvrir les Writs"] = "Click: open the Writs window",
    ["Faveur du marchand"] = "Merchant's Favor",
    ["1 point de Faveur"] = "1 Favor",
    ["%s points de Faveur"] = "%s Favor",
    ["Pas encore de Faveur"] = "No Favor yet",
    ["Les caisses les moins chères et où les rendre"] = "The cheapest crates and where to turn them in",
    ["Clic : voir les caisses"] = "Click: see the crates",
    ["Sacs"] = "Bags",
    ["1 objet de quête à jeter"] = "1 quest item to throw away",
    ["%d objets de quête à jeter"] = "%d quest items to throw away",
    ["Rien à jeter"] = "Nothing to throw away",
    ["Clic : voir les objets à jeter"] = "Click: see the items to throw away",
    ["Commandes"] = "Orders",
    ["1 commande à accepter"] = "1 order to accept",
    ["%d commandes à accepter"] = "%d orders to accept",
    ["Aucune commande en cours"] = "No order in progress",
    ["Faire fabriquer par la guilde"] = "Get things crafted by the guild",
    ["Tu as 1 commande en cours"] = "You have 1 order in progress",
    ["Tu as %d commandes en cours"] = "You have %d orders in progress",
    ["Clic : ouvrir les commandes"] = "Click: open orders",
    ["Guilde"] = "Guild",
    ["1 membre en ligne"] = "1 member online",
    ["%d membres en ligne"] = "%d members online",
    ["Tu es 1er au classement PvP de la semaine"] = "You are #1 in this week's PvP ranking",
    ["Tu es %de au classement PvP de la semaine"] = "You are #%d in this week's PvP ranking",
    ["Pas encore classé en PvP cette semaine"] = "Not in this week's PvP ranking yet",
    ["Tu n'es pas dans une guilde"] = "You are not in a guild",
    ["Clic : ouvrir la guilde"] = "Click: open the guild",
    ["Aucun événement prévu"] = "No events planned",
    ["Retours"] = "Feedback",
    ["Nous écrire"] = "Write to us",
    ["Un bug, une idée, une suggestion : sans compte"] = "A bug, an idea, a suggestion: no account",
    ["Clic : écrire à l'équipe WL Helper"] = "Click: write to the WL Helper team",
    ["Rapports des joueurs"] = "Players' reports",
    ["Aucun rapport reçu"] = "No report received",
    ["1 rapport reçu"] = "1 report received",
    ["%d rapports reçus"] = "%d reports received",
    ["1 nouveau"] = "1 new",
    ["%d nouveaux"] = "%d new",
    ["Clic : lire les rapports"] = "Click: read the reports",
    ["1 joueur cherche un groupe"] = "1 player looking for a group",
    ["%d joueurs cherchent un groupe"] = "%d players looking for a group",
    ["1 événement à venir"] = "1 upcoming event",
    ["%d événements à venir"] = "%d upcoming events",
    ["1 autre événement à venir"] = "1 more upcoming event",
    ["%d autres événements à venir"] = "%d more upcoming events",
    ["Aucun autre événement prévu"] = "No other event planned",
    ["Clic : ouvrir Groupes"] = "Click: open Groups",
    ["Améliorations"] = "Upgrades",
    ["1 amélioration dans tes sacs"] = "1 upgrade in your bags",
    ["%d améliorations dans tes sacs"] = "%d upgrades in your bags",
    ["Rien de mieux dans tes sacs"] = "Nothing better in your bags",
    ["Selon ta spé %s"] = "Based on your %s spec",
    ["Clic : choisir ta spé et voir tes améliorations"] = "Click: pick your spec and see your upgrades",
    ["Comment faire... ?"] = "How do I...?",
    ["Les gestes utiles, pas à pas"] = "Common tasks, step by step",
    ["Clic : ouvrir « Comment faire... ? »"] = "Click: open How do I...?",
    ["Module éteint"] = "Module off",
    -- the activity cards (beta.173)
    ["Ouvrir les champs de bataille"] = "Open battlegrounds",
    ["Voir les commandes"] = "See orders",
    ["Voir les groupes"] = "See groups",
    ["Le guide de quêtes est éteint."] = "The quest guide is off.",
    ["Allumer le guide"] = "Turn the guide on",
    ["Rien à faire pour l'instant."] = "Nothing to do right now.",
    ["Tous les guides"] = "Every guide",
    ["Clic : allumer le module"] = "Click: turn the module on",
    -- what each module does (home card tooltips, welcome window)
    ["Les quêtes de tes donjons dans le bon ordre, avec le GPS."] = "Your dungeon quests in the right order, with the GPS.",
    ["Les Writs les moins chers, la liste d'achat, la tournée de remise et la Faveur du marchand."] = "The cheapest Writs, the shopping list, the turn-in tour and Merchant's Favor.",
    ["Les objets de quête qui ne servent plus, et une place libre en un clic."] = "Quest items you no longer need, and a free slot in one click.",
    ["Faire fabriquer par la guilde, ou fabriquer pour elle."] = "Get things crafted by the guild, or craft for it.",
    ["Les membres, leurs métiers et le classement PvP."] = "Members, their professions and the PvP ranking.",
    ["Les donjons et raids prévus par la guilde, et qui cherche un groupe."] = "Dungeons and raids the guild plans, and who is looking for a group.",
    ["Une flèche verte sur les objets meilleurs que les tiens."] = "A green arrow on items better than yours.",
    -- minimap button
    ["Éteint"] = "Off",
    ["Éteinte"] = "Off",
    ["Clic : la rallumer"] = "Click: turn it back on",
    ["Rien à rendre"] = "Nothing to turn in",
    ["%s, étape %d sur %d"] = "%s, step %d of %d",
    ["%s, terminée"] = "%s, finished",
    ["1 Writ prêt"] = "1 Writ ready",
    ["%d Writs prêts"] = "%d Writs ready",
    ["%d à jeter"] = "%d to throw away",
    ["%d à accepter"] = "%d to accept",
    ["1 cherche un groupe"] = "1 looking for a group",
    ["%d cherchent un groupe"] = "%d looking for a group",
    ["Clic : ouvrir l'Accueil"] = "Click: open Home",
    ["Clic droit : ouvrir un module"] = "Right-click: open a module",
    ["Glisser : déplacer le bouton"] = "Drag: move the button",
    ["Aucun trajet GPS en cours."] = "No GPS route running.",
    ["Nous écrire"] = "Write to us",
    ["Clic : ouvrir le guide de quêtes"] = "Click: open the quest guide",
    ["Clic : choisir parmi tous les guides"] = "Click: pick among every guide",
    ["Clic : arrêter le GPS"] = "Click: stop the GPS",
    -- T-80: my crafter status in the minimap menu
    ["Artisan : %s"] = "Crafter: %s",
    ["Artisan"] = "Crafter",
    ["Clic : passer à %s"] = "Click: switch to %s",
    ["Ce que la guilde voit dans les Commandes."] = "What the guild sees in Orders.",
    ["Automatique pour l'instant : %s."] = "Automatic for now: %s.",
    ["absent (AFK)"] = "away (AFK)",
    ["en file d'attente"] = "queued",
    ["en donjon"] = "in a dungeon",
})

-- "Cette semaine" (beta.197, report: "the weeklies should be on the homepage, weekly PvE and weekly
-- PvP, where to go and what there is this week; the homepage is not balanced any more")
ns.AddEnglish({
    ["Cette semaine"] = "This week",
    ["remise à zéro dans %d j %d h"] = "resets in %d d %d h",
    ["remise à zéro dans %d h"] = "resets in %d h",
    ["remise à zéro dans moins d'une heure"] = "resets in less than an hour",
    ["Hebdo PvE"] = "Weekly PvE",
    ["Hebdo PvP"] = "Weekly PvP",
    ["Sac de l'Undermine"] = "Undermine Satchel",
    ["Quoi"] = "What",
    ["Où"] = "Where",
    ["Rapporte"] = "Reward",
    ["Quête"] = "Quest",
    ["À faire cette semaine"] = "To do this week",
    ["Faite cette semaine"] = "Done this week",
    ["Dès le niveau 60"] = "From level 60",
    ["En cours : %d objet sur %d"] = "In progress: %d of %d items",
    ["En cours : %d objets sur %d"] = "In progress: %d of %d items",
    ["Les 3 objets sont là : rends la quête"] = "All 3 items found: turn the quest in",
    ["Un objet du dernier boss de chaque aile de Hache-Tripes : Alzzin (Est), Tortheldrin (Ouest), le roi Gordok (Nord)."] =
        "One item from the last boss of each Dire Maul wing: Alzzin (East), Tortheldrin (West), King Gordok (North).",
    ["Pix Xizzix, Baie-du-Butin, puis Hache-Tripes"] = "Pix Xizzix, Booty Bay, then Dire Maul",
    ["Baie-du-Butin"] = "Booty Bay",
    ["Un sac de l'Undermine : un objet en or qui se vend 10 à 100 po"] = "An Undermine Satchel: a gold item that sells for 10 to 100 gold",
    ["Voir le guide"] = "See the guide",
    ["Clic : le guide de l'hebdo, étape par étape"] = "Click: the weekly's guide, step by step",
    ["Clic : la flèche du GPS t'emmène à Pix Xizzix"] = "Click: the GPS arrow takes you to Pix Xizzix",
    ["Champs de bataille"] = "Battlegrounds",
    ["En bonus aujourd'hui"] = "Bonus today",
    ["En bonus demain"] = "Bonus tomorrow",
    ["En bonus dans %d jours"] = "Bonus in %d days",
    ["Aucun bonus annoncé dans le calendrier du jeu"] = "No bonus announced in the game's calendar",
    ["%s, %s"] = "%s, %s",
    ["Field of Honor : Wizzik Dustfizz, Gadgetzan, dès le niveau 60"] = "Field of Honor: Wizzik Dustfizz, Gadgetzan, from level 60",
    ["3 marques par victoire, 1 par défaite ; Field of Honor : 300 honneur et 500 points de rang"] =
        "3 marks a win, 1 a loss; Field of Honor: 300 honor and 500 rank points",
    ["Clic : la flèche du GPS t'emmène au maître de guerre"] = "Click: the GPS arrow takes you to the battlemaster",
    ["Clic : la flèche du GPS t'emmène à Wizzik Dustfizz"] = "Click: the GPS arrow takes you to Wizzik Dustfizz",
    -- the reputations guide (the "Réputations" tab of Meilleur équipement)
    ["Ce que chaque réputation débloque, ton rang et le plus rapide pour la monter."] =
        "What each reputation unlocks, your standing and the fastest way to raise it.",
    ["Clic : ouvrir le guide des réputations"] = "Click: open the reputations guide",
    ["Ce qu'elles débloquent et comment les monter"] = "What they unlock and how to raise them",
})

local GAP = 12             -- between blocks (search, now, the activities)
-- the activity cards: ns.GRID.homeCards (320 at least), 2 a line at most since beta.197 (four
-- cards, two lines of two: the page stays balanced on a wide window), the same height on a line
local function CardsGrid()
    local g = root.GRID and root.GRID.homeCards or {}
    return { minW = g.minW or 320, gap = g.gap or 16, rowGap = g.rowGap or 16, maxCols = 2,
        minPx = g.minPx or 200, equal = true }
end
-- the weekly cards: PvE and PvP side by side, one under the other on a narrow window
local function WeekGrid()
    local g = root.GRID and root.GRID.homeCards or {}
    return { minW = 280, gap = g.gap or 16, rowGap = g.rowGap or 16, maxCols = 2, minPx = g.minPx or 200, equal = true }
end
-- the activities Home does not draw as a card: PvP is the "Cette semaine" PvP card, "Aide et
-- retours" a thin strip at the bottom (its own layout, below)
local HOME_SKIP = { pvp = true, feedback = true }
-- the level 60 weekly (QuestGuides.lua, QG_Weekly): Pix Xizzix in Booty Bay
local WEEKLY_Q, WEEKLY_GUIDE = 96076, "QG_Weekly"
local PIX = { m = 1434, x = 28.5, y = 75.9 }
local CARD_PAD = 16
local LINE_H = 30          -- S.HUBLINE_H
local SEARCH_ROWS = 3

local function Version()
    local meta = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
    return meta and meta(ADDON, "Version") or "?"
end
-- 12500 -> "12 500" in French, "12,500" in English (DESIGN 4.3): the summary's formatter
-- (root.BigNumber, a no-break space chosen by the addon's language), so every window agrees
local function Thousands(n)
    n = tonumber(n) or 0
    if root.BigNumber then return root.BigNumber(n) end
    local s = tostring(math.floor(math.abs(n) + 0.5))
    local sep = (ns.English and ns.English()) and "," or "\194\160"
    -- a 1-byte mark while the string is reversed, so the 2-byte no-break space keeps its byte order
    local out = s:reverse():gsub("(%d%d%d)", "%1\001"):reverse()
    if out:sub(1, 1) == "\001" then out = out:sub(2) end
    out = out:gsub("\001", sep)
    return (n < 0 and "-" or "") .. out
end
-- "1 objet" / "3 objets": the singular key when n == 1
local function N(n, one, many) return n == 1 and L(one) or string.format(L(many), n) end

-- Each module's name and what it does, in the words of the glossary (home card tooltips, welcome window).
local MODULE_COPY = {
    dungeons = { "Guide de quêtes", "Les quêtes de tes donjons dans le bon ordre, avec le GPS." },
    writs    = { "Writs", "Les Writs les moins chers, la liste d'achat, la tournée de remise et la Faveur du marchand." },
    bags     = { "Sacs", "Les objets de quête qui ne servent plus, et une place libre en un clic." },
    orders   = { "Commandes", "Faire fabriquer par la guilde, ou fabriquer pour elle." },
    guild    = { "Guilde", "Les membres, leurs métiers et le classement PvP." },
    events   = { "Groupes", "Les donjons et raids prévus par la guilde, et qui cherche un groupe." },
    upgrades = { "Améliorations", "Une flèche verte sur les objets meilleurs que les tiens." },
}
-- WP.ModuleCopy(key) -> name, description (translated); unknown keys fall back to WP.MODULES.
function WP.ModuleCopy(key)
    local c = MODULE_COPY[key]
    if c then return L(c[1]), L(c[2]) end
    for _, m in ipairs(WP.MODULES or {}) do if m.key == key then return L(m.label), L(m.hint or "") end end
    return key, ""
end

-- ---------------------------------------------------------------- what each module has to say

local function DungeonState()
    if not root.GuideStatus then return nil end
    return root.GuideStatus()   -- five values: never through "a and f()", which keeps only one
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

-- orders placed for you that nobody has accepted yet
local function OrdersOpen()
    if not WP.Orders then return 0 end
    local _, forMe = WP.Orders.Lists()
    local open = 0
    for _, o in ipairs(forMe or {}) do if o.status == "open" then open = open + 1 end end
    return open
end

local function OpenGuide()
    if root.ShowPicker then root.ShowPicker() else root.ShowGuide() end
end

-- ---------------------------------------------------------------- the page

-- The Hub (Writs/Options.lua) builds this page into its content column: win is the Hub window,
-- win.inner the page (the scroll child), win.scroll its scroll area. The fields keep the names the
-- old Home window had (win.search, win.now, win.upd, win.cards), the offline tests read them.
local win
local cards = {}         -- one HubRow per WP.HUB entry, by key
local tiles = {}         -- the rows of the smaller tools (city, keys, shared, triage), same frames
local heads = {}         -- one section title per activity, by group key
local CW, COL_W = 628, 306
local groupCards = {}    -- one activity card per WP.HUB_GROUPS key (heads[key] is the same frame)
local cardGrid           -- the activity cards' ns.Grid
local cdGrid             -- the cooldown cards' ns.Grid

local function Close() if WP.CloseHub then WP.CloseHub() elseif win then win:Hide() end end
local function Visible() return win ~= nil and WP.HubShows ~= nil and WP.HubShows("home") end

-- -> true when the client knows this texture, false when it does not, nil when it cannot tell (no
-- file ids): the TrySet test of Picker.lua
local function Known(path)
    local f = CreateFrame and CreateFrame("Frame")
    local tex = f and f.CreateTexture and f:CreateTexture()
    if not (tex and tex.GetTextureFileID) then return nil end
    local ok = pcall(tex.SetTexture, tex, path)
    local okI, id = pcall(tex.GetTextureFileID, tex)
    return ok and okI and type(id) == "number" and id ~= 0
end

-- One icon per module, the same on the Home rows, the minimap menu, Settings and the welcome
-- window, so a player learns it once (icon audit G5). Modules are things: painted game icons
-- (design system 2.2). LFG is a group (the battle shout read as a war cry). Upgrades is the one HD
-- glyph: the green arrow the module puts on better items, so its line teaches that very mark.
local ICONS = "Interface\\Icons\\"
WP.MODULE_ICON = {
    dungeons = ICONS .. "INV_Misc_Map_01", writs = ICONS .. "INV_Letter_15", favor = ICONS .. "INV_Crate_04",
    bags = ICONS .. "INV_Misc_Bag_08", orders = ICONS .. "Trade_BlackSmithing", guild = ICONS .. "INV_BannerPVP_01",
    events = ICONS .. "INV_Misc_GroupNeedMore", upgrades = { hd = "arrow_up", color = C.ok },
    help = ICONS .. "INV_Misc_Book_09",
}
-- INV_Misc_GroupNeedMore may be missing on this client: an empty square would then show on Home,
-- the minimap menu, Settings and the welcome window. Probe it once and fall back to the earlier
-- battle shout, but only when the fallback itself is known: a client that cannot tell keeps the
-- group icon
do
    local okP, has = pcall(Known, WP.MODULE_ICON.events)
    if okP and has == false then
        local alt = ICONS .. "Ability_Warrior_BattleShout"
        local okA, altHas = pcall(Known, alt)
        if okA and altHas then WP.MODULE_ICON.events = alt end
    end
end
-- The tools' icons: painted recognition aids (what the tool is about), each with the HD glyph of
-- the tool's own empty state when the client lacks the painted one. Not modules: not in MODULE_ICON.
local function ToolIcon(path, hd)
    local okK, has = pcall(Known, path)
    if okK and has == false then return { hd = hd } end
    return path
end
local TOOL_ICON
local function ToolIcons()
    if TOOL_ICON then return TOOL_ICON end
    local okF, fac = pcall(UnitFactionGroup, "player")
    local capital = (okF and fac == "Alliance") and "Spell_Arcane_TeleportStormWind" or "Spell_Arcane_TeleportOrgrimmar"
    TOOL_ICON = {
        city = ToolIcon(ICONS .. capital, "flag"),
        keys = ToolIcon(ICONS .. "INV_Misc_Key_03", "ring"),
        shared = ToolIcon(ICONS .. "INV_Scroll_03", "group"),
        triage = ToolIcon(ICONS .. "INV_Misc_Note_01", "check"),
    }
    return TOOL_ICON
end
-- One icon per activity card, painted, 32 px: the only icons on Home (the lines have none). Each
-- falls back on an HD glyph when the client lacks the painted one.
local GROUP_ICON
local function GroupIcon(key)
    if not GROUP_ICON then
        GROUP_ICON = {
            quests = WP.MODULE_ICON.dungeons,
            pvp = ToolIcon(ICONS .. "INV_Sword_27", "sword"),
            items = ToolIcon(ICONS .. "INV_Misc_Coin_02", "coin"),
            guild = WP.MODULE_ICON.guild,
            travel = ToolIcon(ICONS .. "INV_Misc_Map02", "pin"),
            feedback = { hd = "mail" },
        }
    end
    return GROUP_ICON[key] or { hd = "dot" }
end
WP.HomeGroupIcon = GroupIcon

-- WP.PaintModuleIcon(tex, icon): a painted path (white, cropped) or { hd, color } (an HD glyph in
-- its colour). -> true when it drew an HD glyph (the caller insets it in its box)
function WP.PaintModuleIcon(tex, icon)
    if type(icon) == "table" then
        root.SetHDIcon(tex, icon.hd, icon.color or C.fg)
        return true
    end
    S.Painted(tex, icon); tex:SetVertexColor(1, 1, 1)
    return false
end
-- WP.HubIcon(entry) -> the entry's icon: { hd } as given, else a module icon, else a tool icon
function WP.HubIcon(e)
    if type(e.icon) == "table" then return e.icon end
    return WP.MODULE_ICON[e.icon] or ToolIcons()[e.icon] or { hd = "dot" }
end

-- What a click on each line does (the row's tooltip, the minimap menu).
local CLICK_HINT = {
    dungeons = "Clic : choisir parmi tous les guides", keys = "Clic : ouvrir le passeport des clés",
    shared = "Clic : voir les quêtes en commun", triage = "Clic : voir les quêtes à abandonner",
    ["goto"] = "Clic : ouvrir « Aller à »", city = "Clic : ouvrir la tournée en ville",
    writs = "Clic : ouvrir les Writs", favor = "Clic : voir les caisses", orders = "Clic : ouvrir les commandes",
    bags = "Clic : voir les objets à jeter", upgrades = "Clic : choisir ta spé et voir tes améliorations",
    guild = "Clic : ouvrir la guilde", events = "Clic : ouvrir Groupes",
    pvp = "Clic : ouvrir les champs de bataille", reps = "Clic : ouvrir le guide des réputations",
}
function WP.HubClickHint(key) return CLICK_HINT[key] and L(CLICK_HINT[key]) or nil end

-- "Now": one sentence that may wrap, and the view's one primary button. No icon: it only repeated
-- the icon of the module line right below (icon audit, Home).
local function BuildNow()
    local t = CreateFrame("Frame", nil, win.inner)
    t.wlOwned = true
    S.Solid(t, "BACKGROUND", C.cardFill):SetAllPoints()
    S.Border(t, C.cardEdge)
    t.text = S.Text(t, F.body, C.fg)
    t.text:SetJustifyH("LEFT"); t.text:SetJustifyV("MIDDLE")
    t.text:SetPoint("LEFT", t, "LEFT", 12, 0)
    t.go = S.Button(t, "", 0, 28, "primary", function() if t.fn then t.fn() end end)
    t.go:SetPoint("RIGHT", -12, 0)
    -- t:Set(text, label, fn, kind)
    function t:Set(text, label, fn, kind)
        self.text:SetText(text)
        self.go:SetText(label)
        self.go:SetKind(kind or "primary")
        self.fn = fn
    end
    function t:Fit(width)
        local okW, bw = pcall(self.go.GetWidth, self.go)
        bw = (okW and type(bw) == "number") and bw or 100
        local th = S.FitText(self.text, 2, math.max(80, width - 12 - 12 - bw - 12), self)
        local h = math.ceil(math.max(28, th) + 24)
        self:SetHeight(h)
        return h
    end
    return t
end

-- One activity card (beta.173): the activity's painted icon 32 and its name (heading), one sentence
-- on where you stand (body, up to 2 lines), a detail (meta, muted), one secondary button that does
-- the useful thing now, then a compact line per window of the activity. Its height is the grid's.
--   c:SetMain{ text, color, detail, label, fn, tip }   (label nil: no button)
--   c:Fit(width) -> height
local function BuildGroupCard(g)
    local c = CreateFrame("Frame", nil, win.inner)
    c.wlOwned = true
    c.key = g.key
    S.Solid(c, "BACKGROUND", C.cardFill):SetAllPoints()
    S.Border(c, C.cardEdge)
    c.iconFrame = CreateFrame("Frame", nil, c)
    c.iconFrame:SetSize(32, 32)
    S.Border(c.iconFrame, C.cardEdge)
    c.icon = c.iconFrame:CreateTexture(nil, "ARTWORK")
    if WP.PaintModuleIcon(c.icon, GroupIcon(g.key)) then c.icon:SetSize(20, 20); c.icon:SetPoint("CENTER")
    else c.icon:SetAllPoints() end
    c.title = S.Text(c, F.heading, C.fg)
    c.title:SetJustifyH("LEFT"); c.title:SetWordWrap(false)
    c.title:SetText(L(g.label))
    c.label = c.title         -- a section header's name, for the callers that read heads[key].label
    c.state = S.Text(c, F.body, C.fg)
    c.state:SetJustifyH("LEFT"); c.state:SetJustifyV("TOP")
    c.detail = S.Text(c, F.meta, C.muted)
    c.detail:SetJustifyH("LEFT"); c.detail:SetJustifyV("TOP")
    c.go = S.Button(c, "", 0, 28, "secondary", function(self, button)
        if button == "RightButton" then
            if c.onRight then c.onRight() end
        elseif c.fn then c.fn() end
    end)
    c.go:SetScript("OnEnter", function(self) if c.tip then S.Tip(self, c.tip) end end)
    c.go:SetScript("OnLeave", S.HideTip)
    c.lines = {}
    function c:SetMain(o)
        o = o or {}
        self.state:SetText(o.text or "")
        self.state:SetShown(o.text ~= nil and o.text ~= "")
        local col = o.color or C.fg
        self.state:SetTextColor(col[1], col[2], col[3])
        self.detail:SetText(o.detail or "")
        self.detail:SetShown(o.detail ~= nil and o.detail ~= "")
        self.fn, self.tip = o.fn, o.tip
        if o.label then self.go:SetText(o.label); self.go:Show() else self.go:Hide() end
    end
    function c:Fit(width)
        local pad = CARD_PAD
        -- a strip (Aide et retours, one window): icon, name and sentence on one band, the button
        -- at the right
        if self.slim and self.single then
            local okW, bw = pcall(self.go.GetWidth, self.go)
            bw = (self.go:IsShown() and okW and type(bw) == "number") and bw or 0
            local x = pad + 32 + 12
            local textW = math.max(80, width - x - pad - (bw > 0 and bw + 12 or 0))
            self.title:ClearAllPoints(); self.title:SetPoint("TOPLEFT", x, -12)
            self.title:SetWidth(textW); S.ClampLabel(self.title, nil, self)
            local h = 18
            if self.state:IsShown() then
                self.state:ClearAllPoints(); self.state:SetPoint("TOPLEFT", x, -(12 + 20))
                h = 20 + (tonumber(S.FitText(self.state, 2, textW, self)) or 14)
            end
            self.detail:Hide()
            local H = math.ceil(math.max(32, h) + 24)
            self.iconFrame:ClearAllPoints(); self.iconFrame:SetPoint("LEFT", pad, 0)
            if self.go:IsShown() then self.go:ClearAllPoints(); self.go:SetPoint("RIGHT", -pad, 0) end
            self:SetHeight(H)
            return H
        end
        local textW = math.max(80, width - 2 * pad)
        self.iconFrame:ClearAllPoints(); self.iconFrame:SetPoint("TOPLEFT", pad, -pad)
        self.title:ClearAllPoints()
        self.title:SetPoint("LEFT", self.iconFrame, "RIGHT", 12, 0)
        self.title:SetWidth(math.max(40, textW - 44))
        S.ClampLabel(self.title, nil, self)
        local y = pad + 32 + 12
        if self.state:IsShown() then
            self.state:ClearAllPoints(); self.state:SetPoint("TOPLEFT", pad, -y)
            y = y + (tonumber(S.FitText(self.state, 2, textW, self)) or 16)
        end
        if self.detail:IsShown() then
            y = y + 4
            self.detail:ClearAllPoints(); self.detail:SetPoint("TOPLEFT", pad, -y)
            y = y + (tonumber(S.FitText(self.detail, 2, textW, self)) or 14)
        end
        if self.go:IsShown() then
            y = y + 12
            self.go:ClearAllPoints(); self.go:SetPoint("TOPLEFT", pad, -y)
            y = y + 28
        end
        local n = 0
        for _, r in ipairs(self.lines) do
            if r:IsShown() then
                if n == 0 then y = y + 12 end
                n = n + 1
                r:ClearAllPoints(); r:SetPoint("TOPLEFT", self, "TOPLEFT", 6, -y)
                r:SetWidth(width - 12); r:Arrange(width - 12)
                y = y + LINE_H
            end
        end
        y = y + (n > 0 and 6 or pad)
        self:SetHeight(y)
        return y
    end
    return c
end

-- One "Cette semaine" card (beta.197): a kicker ("Hebdo PvE"), the painted icon 32 and the name,
-- where you stand (coloured), then the facts (Quoi, Où, Rapporte...: a muted label column, the
-- value wrapping), a muted detail, and two buttons: go there, open the full window or guide.
--   w:Set{ icon, kicker, title, state, color, facts = { { label, value } }, detail,
--          go = { label, fn, tip }, more = { label, fn, tip } }
--   w:Fit(width) -> height
local FACT_MAX = 4
local function BuildWeekCard(key)
    local c = CreateFrame("Frame", nil, win.inner)
    c.wlOwned = true
    c.key = key
    S.Solid(c, "BACKGROUND", C.cardFill):SetAllPoints()
    S.Border(c, C.cardEdge)
    c.iconFrame = CreateFrame("Frame", nil, c)
    c.iconFrame:SetSize(32, 32)
    S.Border(c.iconFrame, C.cardEdge)
    c.icon = c.iconFrame:CreateTexture(nil, "ARTWORK")
    c.kicker = S.Text(c, F.meta, C.gold)
    c.kicker:SetJustifyH("LEFT"); c.kicker:SetWordWrap(false)
    c.title = S.Text(c, F.heading, C.fg)
    c.title:SetJustifyH("LEFT"); c.title:SetWordWrap(false)
    c.state = S.Text(c, F.body, C.fg)
    c.state:SetJustifyH("LEFT"); c.state:SetJustifyV("TOP")
    c.factL, c.factV = {}, {}
    for i = 1, FACT_MAX do
        c.factL[i] = S.Text(c, F.meta, C.muted)
        c.factL[i]:SetJustifyH("LEFT"); c.factL[i]:SetWordWrap(false)
        c.factV[i] = S.Text(c, F.meta, C.text or C.fg)
        c.factV[i]:SetJustifyH("LEFT"); c.factV[i]:SetJustifyV("TOP")
    end
    c.detail = S.Text(c, F.meta, C.muted)
    c.detail:SetJustifyH("LEFT"); c.detail:SetJustifyV("TOP")
    local function Btn(field, kind)
        local b = S.Button(c, "", 0, 28, kind, function() local o = c[field]; if o and o.fn then o.fn() end end)
        b:SetScript("OnEnter", function(self) local o = c[field]; if o and o.tip then S.Tip(self, o.tip) end end)
        b:SetScript("OnLeave", S.HideTip)
        return b
    end
    c.goBtn = Btn("goO", "secondary")
    c.moreBtn = Btn("moreO", "ghost")
    c.nFacts = 0
    function c:Set(o)
        o = o or {}
        if o.icon and o.icon ~= self.iconPath then
            self.iconPath = o.icon
            self.icon:ClearAllPoints()
            if WP.PaintModuleIcon(self.icon, o.icon) then self.icon:SetSize(20, 20); self.icon:SetPoint("CENTER")
            else self.icon:SetAllPoints() end
        end
        self.kicker:SetText(o.kicker or "")
        self.title:SetText(o.title or "")
        self.state:SetText(o.state or "")
        self.state:SetShown(o.state ~= nil and o.state ~= "")
        local col = o.color or C.fg
        self.state:SetTextColor(col[1], col[2], col[3])
        local facts = o.facts or {}
        self.nFacts = math.min(#facts, FACT_MAX)
        for i = 1, FACT_MAX do
            local f = i <= self.nFacts and facts[i]
            self.factL[i]:SetText(f and f[1] or ""); self.factV[i]:SetText(f and f[2] or "")
            self.factL[i]:SetShown(f and true or false); self.factV[i]:SetShown(f and true or false)
        end
        self.detail:SetText(o.detail or "")
        self.detail:SetShown(o.detail ~= nil and o.detail ~= "")
        self.goO, self.moreO = o.go, o.more
        if o.go then self.goBtn:SetText(o.go.label); self.goBtn:Show() else self.goBtn:Hide() end
        if o.more then self.moreBtn:SetText(o.more.label); self.moreBtn:Show() else self.moreBtn:Hide() end
    end
    function c:Fit(width)
        local pad = CARD_PAD
        local textW = math.max(80, width - 2 * pad)
        self.iconFrame:ClearAllPoints(); self.iconFrame:SetPoint("TOPLEFT", pad, -pad)
        local x = pad + 32 + 12
        self.kicker:ClearAllPoints(); self.kicker:SetPoint("TOPLEFT", x, -pad)
        self.kicker:SetWidth(math.max(40, textW - 44)); S.ClampLabel(self.kicker, nil, self)
        self.title:ClearAllPoints(); self.title:SetPoint("TOPLEFT", x, -(pad + 14))
        self.title:SetWidth(math.max(40, textW - 44)); S.ClampLabel(self.title, nil, self)
        local y = pad + 32 + 12
        if self.state:IsShown() then
            self.state:ClearAllPoints(); self.state:SetPoint("TOPLEFT", pad, -y)
            y = y + (tonumber(S.FitText(self.state, 2, textW, self)) or 16)
        end
        -- the facts' labels in one column, as wide as the widest (a third of the card at most)
        local lw = 0
        for i = 1, self.nFacts do
            local w = root.TextWidth and root.TextWidth(self.factL[i]) or 40
            if type(w) == "number" and w > lw then lw = w end
        end
        lw = math.min(math.ceil(lw) + 8, math.floor(textW / 3))
        for i = 1, self.nFacts do
            y = y + 6
            local fl, fv = self.factL[i], self.factV[i]
            fl:ClearAllPoints(); fl:SetPoint("TOPLEFT", pad, -y); fl:SetWidth(lw)
            fv:ClearAllPoints(); fv:SetPoint("TOPLEFT", pad + lw, -y)
            y = y + math.max(14, tonumber(S.FitText(fv, 3, math.max(60, textW - lw), self)) or 14)
        end
        if self.detail:IsShown() then
            y = y + 8
            self.detail:ClearAllPoints(); self.detail:SetPoint("TOPLEFT", pad, -y)
            y = y + (tonumber(S.FitText(self.detail, 2, textW, self)) or 14)
        end
        if self.goBtn:IsShown() or self.moreBtn:IsShown() then
            y = y + 12
            local bx = pad
            if self.goBtn:IsShown() then
                self.goBtn:ClearAllPoints(); self.goBtn:SetPoint("TOPLEFT", bx, -y)
                local okW, bw = pcall(self.goBtn.GetWidth, self.goBtn)
                bx = bx + ((okW and type(bw) == "number") and bw or 80) + 8
            end
            if self.moreBtn:IsShown() then self.moreBtn:ClearAllPoints(); self.moreBtn:SetPoint("TOPLEFT", bx, -y) end
            y = y + 28
        end
        y = math.ceil(y + pad)
        self:SetHeight(y)
        return y
    end
    return c
end

-- ---------------------------------------------------------------- "Où veux-tu aller ?"

local Layout, LayoutCooldowns
local searchRes = {}     -- the last search's results (WP.GoTo.Search), the first 3 shown
local searchState        -- nil (fewer than 2 letters: nothing under the field), "list" or "none"
local pending            -- the debounce timer
local distTicker         -- while results are listed: their distances and nearest places, twice a second

local function Letters(text)
    local G = WP.GoTo
    local okN, n = pcall(G and G.Norm or tostring, text or "")
    if not (okN and type(n) == "string") then n = tostring(text or "") end
    return #(n:gsub("%s", ""))
end

local StartDist, StopDist

local function RunSearch()
    if not (win and win.search) then return end
    local text = win.search:GetText() or ""
    searchRes, searchState = {}, nil
    if Letters(text) >= 2 then
        local ok, res = pcall(WP.GoTo.Search, text)
        searchRes = (ok and type(res) == "table") and res or {}
        searchState = #searchRes > 0 and "list" or "none"
    end
    for i, row in ipairs(win.searchRows) do
        local r = searchState == "list" and searchRes[i]
        row.result = r or nil
        if r then
            local dist = r.dist and WP.GPS and WP.GPS.Distance and WP.GPS.Distance(r.dist) or nil
            row:Set({ name = r.label, detail = r.detail, value = dist })
        end
        row:SetShown(r and true or false)
    end
    local more = win.searchMore
    if searchState == "none" then more:SetText(L("Ouvrir « Aller à »"))
    else more:SetText(L("Voir tous les résultats")) end
    more:SetShown(searchState == "none" or (searchState == "list" and #searchRes > SEARCH_ROWS))
    win.searchEmpty:SetShown(searchState == "none")
    if searchState == "list" then StartDist() else StopDist() end
    Layout()
end

-- Measures the listed results again as you walk: the distance follows you, and a service or an NPC
-- may move to a nearer place (its detail line then names it). The page is laid out again only when
-- a row changed shape. Stops as soon as Home is not on screen.
local function DistTick()
    if not (win and Visible() and searchState == "list") then StopDist(); return end
    local G = WP.GoTo
    if not (G and G.Repick) then return end
    local relayout = false
    for i, row in ipairs(win.searchRows) do
        local r = row:IsShown() and row.result
        if r and r == searchRes[i] then
            local okR, moved = pcall(G.Repick, r)
            local dist = r.dist and WP.GPS and WP.GPS.Distance and WP.GPS.Distance(r.dist) or nil
            local had = row.value:IsShown() and true or false
            if (okR and moved) or (dist ~= nil) ~= had then
                row:Set({ name = r.label, detail = r.detail, value = dist })
                relayout = true
            elseif dist then
                row.value:SetText(dist)
            end
        end
    end
    if relayout then Layout() end
end
StartDist = function()
    if distTicker or not (C_Timer and C_Timer.NewTicker) then return end
    distTicker = C_Timer.NewTicker(0.5, DistTick)
end
StopDist = function()
    if distTicker then distTicker:Cancel(); distTicker = nil end
end

local function SearchSoon()
    if pending then pending:Cancel(); pending = nil end
    if C_Timer and C_Timer.NewTimer then
        pending = C_Timer.NewTimer(0.15, function() pending = nil; RunSearch() end)
    else
        RunSearch()
    end
end

-- the whole Go to window, with what was typed
local function OpenGoTo(text)
    Close()
    if WP.GoTo and WP.GoTo.Show then WP.GoTo.Show(text or "") end
end

local function SearchEnter(text)
    if pending then pending:Cancel(); pending = nil end
    RunSearch()
    if Letters(text) == 0 then OpenGoTo("") return end           -- recent places, nearest services
    if searchState ~= "list" then OpenGoTo(text) return end       -- 1 letter, or nothing found
    -- a map that cannot be read keeps Home open: GoTo already printed why
    if WP.GoTo.Go(searchRes[1]) then Close() end
end

local function BuildSearch()
    win.search = S.Input(win.inner, CW, { search = true, label = L("Où veux-tu aller ?"),
        placeholder = WP.GoToExample and WP.GoToExample() or L("Ex. banque, HV, Mortemines, Forgefer"),
        onChange = function() SearchSoon() end,
        onEnter = SearchEnter })
    win.search:SetScript("OnEnter", function(self) S.Tip(self, { L("Aller à"), L("Entrée : aller au premier résultat") }) end)
    win.search:SetScript("OnLeave", S.HideTip)
    win.searchRows = {}
    for i = 1, SEARCH_ROWS do
        local row = S.ListRow(win.inner, { density = "dense", onClick = function(self)
            if self.result and WP.GoTo.Go(self.result) then Close() end
        end, tip = function(self)
            local r = self.result
            if not r then return nil end
            local t = { r.label }
            if r.detail and r.detail ~= "" then t[#t + 1] = r.detail end
            t[#t + 1] = L("Clic : y aller avec le GPS")
            return t
        end })
        row.valueW = 64
        row:Hide()
        win.searchRows[i] = row
    end
    win.searchMore = S.Button(win.inner, L("Voir tous les résultats"), 0, 24, "ghost", function()
        OpenGoTo(win.search:GetText() or "")
    end)
    win.searchMore:Hide()
    win.searchEmpty = S.Text(win.inner, F.meta, C.muted)
    win.searchEmpty:SetJustifyH("LEFT")
    win.searchEmpty:SetText(L("Aucun lieu trouvé"))
    win.searchEmpty:Hide()
end

local function ClearSearch()
    if pending then pending:Cancel(); pending = nil end
    StopDist()
    if not (win and win.search) then return end
    win.search:SetText(""); win.search:ClearFocus()
    if win.search.Paint then win.search.Paint() end
    searchRes, searchState = {}, nil
    for _, row in ipairs(win.searchRows) do row.result = nil; row:Hide() end
    win.searchMore:Hide(); win.searchEmpty:Hide()
end

-- ---------------------------------------------------------------- layout

-- Stacks what is shown: the search at the top, "now", the update line, then each activity (its
-- title, then its lines 2 or 3 a row, left to right, in the registry's order: a line never moves).
Layout = function()
    if not (win and win.inner) then return end
    local inner = win.inner
    local y = 0
    local function Place(f, h, x, w)
        f:ClearAllPoints()
        f:SetPoint("TOPLEFT", inner, "TOPLEFT", 16 + (x or 0), -(12 + y))
        f:SetWidth(w or CW)
        f:SetHeight(h)
    end
    -- where to go: always at the top, so the field never moves when the strip comes and goes
    if win.search then
        y = y + 17; Place(win.search, 28); y = y + 28
        if searchState == "list" then
            y = y + 8
            local n = 0
            for _, row in ipairs(win.searchRows) do
                if row:IsShown() then
                    if n > 0 then y = y + 2 end
                    local h = row:Fit(CW); Place(row, h); y = y + h
                    n = n + 1
                end
            end
            if win.searchMore:IsShown() then
                y = y + 4
                win.searchMore:ClearAllPoints()
                win.searchMore:SetPoint("TOPRIGHT", inner, "TOPLEFT", 16 + CW, -(12 + y))
                y = y + 24
            end
        elseif searchState == "none" then
            y = y + 8
            local okW, bw = pcall(win.searchMore.GetWidth, win.searchMore)
            bw = (okW and type(bw) == "number") and bw or 100
            local th = S.FitText(win.searchEmpty, 2, math.max(80, CW - bw - 12), inner)
            local h = math.max(24, tonumber(th) or 14)
            win.searchEmpty:ClearAllPoints()
            win.searchEmpty:SetPoint("LEFT", inner, "TOPLEFT", 16, -(12 + y + h / 2))
            win.searchMore:ClearAllPoints()
            win.searchMore:SetPoint("TOPRIGHT", inner, "TOPLEFT", 16 + CW, -(12 + y + (h - 24) / 2))
            y = y + h
        end
        y = y + GAP
    end
    if win.now:IsShown() then
        local h = win.now:Fit(CW); Place(win.now, h); y = y + h + GAP
    end
    if win.upd:IsShown() then
        local h = win.upd:Fit(CW); Place(win.upd, h); y = y + h + GAP
    end
    -- this week: the PvE weekly and the PvP weekly, side by side
    if win.weekHead and win.weekHead:IsShown() then
        Place(win.weekHead, 24); y = y + 24 + 8
        win.weekGrid = win.weekGrid or root.Grid()
        win.weekGrid:Begin(inner, 16, 12 + y, CW, WeekGrid())
        for _, w in ipairs(win.weekCards) do
            if w:IsShown() then win.weekGrid:Add(w, function(f, wd) return f:Fit(wd) end) end
        end
        local wh = win.weekGrid:End()
        y = y + wh + GAP + 8
    end
    -- the activities: one card each, in the order of WP.HUB_GROUPS (a card never moves)
    local first = true
    cardGrid = cardGrid or root.Grid()
    win.cardGrid = cardGrid
    cardGrid:Begin(inner, 16, 12 + y, CW, CardsGrid())
    local any = false
    for _, g in ipairs(WP.HUB_GROUPS or {}) do
        local c = groupCards[g.key]
        if c and HOME_SKIP[g.key] then
            if c ~= groupCards.feedback then c:Hide() end
            for _, r in ipairs(c.lines) do if c ~= groupCards.feedback then r:Hide() end end
        elseif c then
            -- a card with one window: its button opens it, no line under it (unless switched off:
            -- the line says so and turns it back on); a right-click on the button opens its settings
            local shown = {}
            for _, r in ipairs(c.lines) do if r.wantShown then shown[#shown + 1] = r end end
            local single = #shown == 1 and not shown[1].off and c.go:IsShown()
            for _, r in ipairs(c.lines) do r:SetShown(r.wantShown and not single and true or false) end
            c.single = single
            local only = shown[1]
            c.onRight = (single and only.onRightClick) and function() only.onRightClick(only) end or nil
            c.go:RegisterForClicks(c.onRight and "AnyUp" or "LeftButtonUp")
            local on = #shown > 0
            c:SetShown(on)
            if on then
                any = true
                cardGrid:Add(c, function(f, w) return f:Fit(w) end)
            end
        end
    end
    local gh, _, colW = cardGrid:End()
    COL_W = colW
    if any then y = y + gh; first = false end
    -- profession cooldowns on every character: one card per character, in the cards grid
    if win.cdHead and win.cdHead:IsShown() then
        if not first then y = y + GAP end
        first = false
        Place(win.cdHead, 24); y = y + 24 + 8
        local h = LayoutCooldowns()
        Place(win.cdBox, math.max(1, h)); y = y + h
    end
    -- Aide et retours: a thin strip across the page (a card when the reports line shows too)
    local fb = groupCards.feedback
    if fb then
        local shown = {}
        for _, r in ipairs(fb.lines) do if r.wantShown then shown[#shown + 1] = r end end
        local single = #shown == 1 and not shown[1].off and fb.go:IsShown()
        for _, r in ipairs(fb.lines) do r:SetShown(r.wantShown and not single and true or false) end
        fb.single, fb.slim = single, true
        local only = shown[1]
        fb.onRight = (single and only.onRightClick) and function() only.onRightClick(only) end or nil
        fb.go:RegisterForClicks(fb.onRight and "AnyUp" or "LeftButtonUp")
        fb:SetShown(#shown > 0)
        if #shown > 0 then
            if not first then y = y + GAP + 4 end
            first = false
            fb:ClearAllPoints(); fb:SetPoint("TOPLEFT", inner, "TOPLEFT", 16, -(12 + y)); fb:SetWidth(CW)
            local h = fb:Fit(CW); y = y + h
        end
    end
    y = math.ceil(y + 12)
    win.homeH = y
    if win.scroll then win.scroll:SetContentHeight(y + 12) end
end

local upN, bagsDirty = 0, true   -- the upgrades line's bag scan, redone only after the bags changed

-- Home's only event listener: the quest log, the bags, the reputations, the guild roster and a
-- level-up, refreshed half a second later; registered while the Home page shows, never on a hidden
-- page. A 30 s ticker runs beside it while Home shows: the cooldowns count down (and turn "Prête"),
-- "starts in N min" moves, the online counts follow.
local homeEv = CreateFrame("Frame")
local homeQueued = false
local homeTicker
homeEv:SetScript("OnEvent", function(self, event)
    if event == "BAG_UPDATE_DELAYED" then bagsDirty = true end
    if homeQueued or not Visible() then return end
    homeQueued = true
    C_Timer.After(0.5, function() homeQueued = false; WP.RefreshHome() end)
end)
local function HomeEvents(on)
    homeEv:UnregisterAllEvents()
    if homeTicker then homeTicker:Cancel(); homeTicker = nil end
    if not on then return end
    pcall(homeEv.RegisterEvent, homeEv, "QUEST_LOG_UPDATE")
    pcall(homeEv.RegisterEvent, homeEv, "BAG_UPDATE_DELAYED")
    pcall(homeEv.RegisterEvent, homeEv, "UPDATE_FACTION")
    pcall(homeEv.RegisterEvent, homeEv, "GUILD_ROSTER_UPDATE")
    pcall(homeEv.RegisterEvent, homeEv, "PLAYER_LEVEL_UP")
    if C_Timer and C_Timer.NewTicker then
        homeTicker = C_Timer.NewTicker(30, function()
            if Visible() then WP.RefreshHome() elseif homeTicker then homeTicker:Cancel(); homeTicker = nil end
        end)
    end
end
WP.HomeTicker = function() return homeTicker end   -- the offline tests

-- Builds Home into the Hub's page p (again after a language change): the search, "now", the update
-- line, the activity titles and one HubRow per entry of WP.HUB whose files are loaded.
local function Build(p, width, hub)
    win = hub
    CW = math.floor((width or 660) - 32)
    COL_W = math.floor(((width or 660) - 32 - 16) / 2)
    cardGrid, cdGrid = nil, nil
    win.scroll, win.inner = p.sa, p
    -- the Hub lays its pages out through p:Layout()
    function p:Layout() Layout(); return win.homeH end
    cards, tiles, heads, groupCards = {}, {}, {}, {}
    searchRes, searchState = {}, nil
    StopDist()

    -- no focus on open: a focused box would eat the movement keys
    win.search = nil
    if WP.GoTo and WP.GoTo.Search and WP.GoTo.Go then BuildSearch() end

    win.now = BuildNow()
    win.now:Hide()
    win.upd = S.Banner(win.inner, "info", "")
    win.upd:Hide()

    -- "Cette semaine": the PvE weekly and the PvP weekly
    win.weekHead = S.SectionHeader(win.inner, L("Cette semaine"), nil, nil, nil, true)
    win.weekGrid = nil
    win.weekCards = { BuildWeekCard("pve"), BuildWeekCard("pvp") }
    win.weekPvE, win.weekPvP = win.weekCards[1], win.weekCards[2]

    for _, g in ipairs(WP.HUB_GROUPS or {}) do
        local c = BuildGroupCard(g)
        c:Hide()
        groupCards[g.key], heads[g.key] = c, c
    end
    local order = {}
    for _, e in ipairs(WP.HUB and WP.HubEntries() or {}) do
        order[#order + 1] = e
        local c = groupCards[e.group]
        local r = S.HubRow(c or win.inner, function()
            if e.inHub then e.open() else Close(); e.open() end
        end, { compact = true })
        if c then c.lines[#c.lines + 1] = r end
        r.key, r.module, r.entry = e.key, e.module, e
        r:SetIcon(WP.HubIcon(e))
        if e.module or e.key == "favor" then
            local _, desc = WP.ModuleCopy(e.key)
            r.desc = desc ~= "" and desc or nil
        end
        if e.key == "favor" then r.desc = L("Les caisses les moins chères et où les rendre") end
        r.onTurnOn = function() WP.HubTurnOn(e); WP.RefreshHome() end
        if e.settings then
            r:SetOnRightClick(function() WP.OpenHub(e.settings, e.anchor) end, L("Clic droit : réglages"))
        end
        r:Set(L(e.label), "", WP.HubClickHint(e.key))
        cards[e.key] = r
        if e.key == "city" or e.key == "keys" or e.key == "shared" or e.key == "triage" then tiles[e.key] = r end
    end
    win.hubOrder = order
    win.cards, win.tiles, win.heads, win.groupCards = cards, tiles, heads, groupCards

    -- "Recharges": one block per character (its name, then a cooldown and its time left per line)
    win.cdHead = S.SectionHeader(win.inner, L("Recharges"), nil, nil, nil, true)
    win.cdHead:Hide()
    win.cdBox = CreateFrame("Frame", nil, win.inner)
    win.cdBox:Hide()
    win.cdCards, win.cdGroups = {}, {}
    win.cdMeasure = S.Text(win.cdBox, 12, C.muted)   -- the fact labels' size, to line the times up
    win.cdMeasure:Hide()
    win.cdH = 0

    if not win.homeHooked then
        win.homeHooked = true
        win:HookScript("OnHide", function() ClearSearch() end)
    end
    -- the states change with the quest log, the bags and the reputations: one listener for the
    -- session (a rebuild never adds one), its events registered only while this page shows
    homeEv:UnregisterAllEvents()
    local holder = p.holder or p
    holder:HookScript("OnShow", function() if win and win.inner == p then HomeEvents(true) end end)
    holder:HookScript("OnHide", function() if win and win.inner == p then HomeEvents(false) end end)
    if Visible() then HomeEvents(true) end
end

-- The key a dungeon you picked asks for and you do not have yet. -> the reason line, and whether
-- any picked dungeon asks for a key at all
local function KeyNeeded(K)
    local sel = WLDTDB and WLDTDB.sel
    if not (K and K.KeysFor and K.Status and type(sel) == "table") then return nil, false end
    local any, reason = false, nil
    local keys = {}
    for dkey, on in pairs(sel) do
        if on and root.D and root.D[dkey] and not root.D[dkey].cq then keys[#keys + 1] = dkey end
    end
    table.sort(keys)
    for _, dkey in ipairs(keys) do
        local okF, list = pcall(K.KeysFor, dkey)
        local k = okF and type(list) == "table" and list[1]
        if k then
            any = true
            if k.need and not reason then
                local okS, st = pcall(K.Status, k)
                local state = okS and type(st) == "table" and st.state
                -- "na": a chain this character cannot do; nothing to ask of the player
                if state and state ~= "have" and state ~= "na" then
                    local okN, kn = pcall(K.Name, k)
                    local okD, dn = pcall(K.DName, dkey)
                    reason = string.format(L("Il te faut %s pour entrer dans %s."),
                        (okN and type(kn) == "string") and kn or "?", (okD and type(dn) == "string") and dn or dkey)
                end
            end
        end
    end
    return reason, any
end

-- ---------------------------------------------------------------- "Cette semaine"

local function Call(f, ...)
    if type(f) ~= "function" then return nil end
    local ok, a, b = pcall(f, ...)
    if ok then return a, b end
    return nil
end
-- the weekly reset, in words ("remise à zéro dans 3 j 4 h"), nil when the game does not say
local function ResetText()
    local D = C_DateAndTime
    local s = tonumber((Call(D and D.GetSecondsUntilWeeklyReset)))
    if not s or s < 0 then return nil end
    local d, h = math.floor(s / 86400), math.floor((s % 86400) / 3600)
    if d > 0 then return string.format(L("remise à zéro dans %d j %d h"), d, h) end
    if h > 0 then return string.format(L("remise à zéro dans %d h"), h) end
    return L("remise à zéro dans moins d'une heure")
end
local function QuestDone(id)
    local CQL = C_QuestLog
    if CQL and CQL.IsQuestFlaggedCompleted then return Call(CQL.IsQuestFlaggedCompleted, id) and true or false end
    return Call(IsQuestFlaggedCompleted, id) and true or false
end
-- -> the objectives done, their number, when the quest is in the log; nil otherwise
local function QuestProgress(id)
    local CQL = C_QuestLog
    local idx = Call((CQL and CQL.GetLogIndexForQuestID) or GetQuestLogIndexByID, id)
    if not (tonumber(idx) and idx > 0) then return nil end
    local objs = CQL and Call(CQL.GetQuestObjectives, id)
    local n, done = 0, 0
    for _, o in ipairs(type(objs) == "table" and objs or {}) do
        if type(o) == "table" then n = n + 1; if o.finished then done = done + 1 end end
    end
    return done, n
end
WP.HomeQuestDone, WP.HomeQuestProgress = QuestDone, QuestProgress   -- the offline tests

-- the PvE weekly: In Demand - Ancient Elven Curiosities (QuestGuides.lua), the Undermine Satchel
local function WeekPvE(Away)
    local w = win.weekPvE
    local q = root.Q and root.Q[WEEKLY_Q]
    local s = q and q.s
    local spot = { m = s and s.m or PIX.m, x = s and s.x or PIX.x, y = s and s.y or PIX.y }
    local level = UnitLevel and UnitLevel("player") or 0
    local state, color
    local done, n = QuestProgress(WEEKLY_Q)
    if QuestDone(WEEKLY_Q) then state, color = L("Faite cette semaine"), C.ok
    elseif done then
        if n > 0 and done >= n then state, color = L("Les 3 objets sont là : rends la quête"), C.ok
        else state, color = string.format(L(done == 1 and "En cours : %d objet sur %d" or "En cours : %d objets sur %d"), done, n > 0 and n or 3), C.gold end
    elseif level < 60 then state, color = L("Dès le niveau 60"), C.muted
    else state, color = L("À faire cette semaine"), C.gold end
    local guide = root.D and root.D[WEEKLY_GUIDE] and (root.ShowOverview or root.ShowSummary)
    w:Set({ icon = "Interface\\Icons\\INV_Misc_Bag_10_Black", kicker = L("Hebdo PvE"), title = L("Sac de l'Undermine"),
        state = state, color = color,
        facts = {
            { L("Quoi"), L("Un objet du dernier boss de chaque aile de Hache-Tripes : Alzzin (Est), Tortheldrin (Ouest), le roi Gordok (Nord).") },
            { L("Où"), L("Pix Xizzix, Baie-du-Butin, puis Hache-Tripes") },
            { L("Rapporte"), L("Un sac de l'Undermine : un objet en or qui se vend 10 à 100 po") },
        },
        go = (WP.GoTo and WP.GoTo.Go) and { label = L("Y aller"), tip = { L("Y aller"), L("Clic : la flèche du GPS t'emmène à Pix Xizzix") },
            fn = function()
                if WP.GoTo.Go({ kind = "npc", label = "Pix Xizzix", detail = L("Baie-du-Butin"), map = spot.m, x = spot.x, y = spot.y, gps = "Pix Xizzix" }) then Close() end
            end } or nil,
        more = guide and { label = L("Voir le guide"), tip = { L("Voir le guide"), L("Clic : le guide de l'hebdo, étape par étape") },
            fn = Away(function()
                if root.ShowOverview then root.ShowOverview(WEEKLY_GUIDE) else root.ShowSummary({ WEEKLY_GUIDE }) end
            end) } or nil })
    w:Show()
end

-- the PvP weekly: the battleground in bonus (the game's calendar), Field of Honor, the guild ranking
local function WeekPvP(Away)
    local w = win.weekPvP
    local BG = WP.BG
    if not (BG and BG.Toggle) then w:Hide(); return end
    local found = BG.Bonus and Call(BG.Bonus)
    found = type(found) == "table" and BG.BY and BG.BY[found.key] and found or nil
    local title, state, color, where = L("Champs de bataille"), nil, C.muted, nil
    if found then
        title = L(BG.BY[found.key].name)
        state = found.days == 0 and L("En bonus aujourd'hui") or found.days == 1 and L("En bonus demain")
            or string.format(L("En bonus dans %d jours"), found.days)
        color = C.gold
        local m = BG.Master and Call(BG.Master, found.key)
        if type(m) == "table" and BG.CITY and BG.CITY[m[2]] then where = string.format(L("%s, %s"), m[1], L(BG.CITY[m[2]][1])) end
    else
        state = L("Aucun bonus annoncé dans le calendrier du jeu")
    end
    local rank
    if IsInGuild and IsInGuild() and WP.GuildRanking then
        local pos
        local list = Call(WP.GuildRanking, true)
        for i, e in ipairs(type(list) == "table" and list or {}) do if e.name == UnitName("player") then pos = i end end
        rank = pos and (pos == 1 and L("Tu es 1er au classement PvP de la semaine") or string.format(L("Tu es %de au classement PvP de la semaine"), pos))
            or L("Pas encore classé en PvP cette semaine")
    end
    local facts = {}
    if where then facts[#facts + 1] = { L("Où"), where } end
    facts[#facts + 1] = { L("Quête"), L("Field of Honor : Wizzik Dustfizz, Gadgetzan, dès le niveau 60") }
    facts[#facts + 1] = { L("Rapporte"), L("3 marques par victoire, 1 par défaite ; Field of Honor : 300 honneur et 500 points de rang") }
    local go
    if found and BG.GoMaster then
        go = { label = L("Y aller"), tip = { L("Y aller"), L("Clic : la flèche du GPS t'emmène au maître de guerre") },
            fn = function() if BG.GoMaster(found.key) then Close() end end }
    elseif BG.GoFoh then
        go = { label = L("Y aller"), tip = { L("Y aller"), L("Clic : la flèche du GPS t'emmène à Wizzik Dustfizz") },
            fn = function() if BG.GoFoh() then Close() end end }
    end
    w:Set({ icon = GroupIcon("pvp"), kicker = L("Hebdo PvP"), title = title, state = state, color = color,
        facts = facts, detail = rank, go = go,
        more = { label = L("Champs de bataille"), tip = { L("Champs de bataille"), L("Clic : ouvrir les champs de bataille") },
            fn = Away(function() BG.Toggle(nil, true) end) } })
    w:Show()
end

local function RefreshWeek(Away)
    if not (win and win.weekHead) then return end
    win.weekHead:Set(L("Cette semaine"), ResetText())
    local okE, errE = pcall(WeekPvE, Away)
    if not okE then win.weekPvE:Hide() end
    local okP = pcall(WeekPvP, Away)
    if not okP then win.weekPvP:Hide() end
    win.weekHead:SetShown(win.weekPvE:IsShown() or win.weekPvP:IsShown())
    win.weekErr = not okE and errE or nil
end

-- a row's call, when the row exists (its files may not be loaded)
local function Put(key, method, ...)
    local r = cards[key]
    if r then r[method](r, ...) end
end

-- "Recharges": each character's cooldowns (WP.Cooldowns.Rows), yours first; one card per
-- character (ns.GRID.cards: 2 a line at 668-724 px, 3 from 1112), its name as the card's heading,
-- then one fact per cooldown, the time left or "Prête" in green. Every card uses the same label
-- column, so the times line up across the cards of a line.
local function CdCard(i)
    win.cdCards = win.cdCards or {}
    local c = win.cdCards[i]
    if c then return c end
    c = CreateFrame("Frame", nil, win.cdBox)
    c.wlOwned = true
    S.Solid(c, "BACKGROUND", C.cardFill):SetAllPoints()
    S.Border(c, C.cardEdge)
    c.stack = root.TextStack(c)
    win.cdCards[i] = c
    return c
end

local function RefreshCooldowns()
    if not (win and win.cdBox) then return end
    local CDm = WP.Cooldowns
    local ok, rows = false, nil
    if CDm and CDm.Rows then ok, rows = pcall(CDm.Rows) end
    rows = (ok and type(rows) == "table") and rows or {}
    win.cdGroups = {}
    if #rows == 0 then
        win.cdHead:Hide(); win.cdBox:Hide(); win.cdH = 0
        for _, c in ipairs(win.cdCards or {}) do c:Hide() end
        return
    end
    -- one label column for every line, so the times line up
    local labelW = 0
    for _, r in ipairs(rows) do
        local w = root.TextWidth(win.cdMeasure, r.label)
        if type(w) == "number" and w > labelW then labelW = w end
    end
    win.cdLabelW = math.ceil(labelW) + 4
    local myRealm = GetRealmName and GetRealmName() or ""
    local last, grp
    for _, r in ipairs(rows) do
        if r.key ~= last then
            last = r.key
            local who = r.name
            if r.realm ~= "" and r.realm ~= myRealm then who = who .. " - " .. r.realm end
            grp = { who = who, facts = {} }
            win.cdGroups[#win.cdGroups + 1] = grp
        end
        local ready = (r.left or 0) <= 0
        grp.facts[#grp.facts + 1] = { r.label, CDm.FormatLeft(r.left), ready }
    end
    for i = #win.cdGroups + 1, #(win.cdCards or {}) do win.cdCards[i]:Hide() end
    win.cdHead:Show(); win.cdBox:Show()
end

-- the cards at the width of now (Layout) -> the block's height
LayoutCooldowns = function()
    local groups = win.cdGroups or {}
    cdGrid = cdGrid or root.Grid()
    local go = root.GRID.cards
    cdGrid:Begin(win.cdBox, 0, 0, CW, { minW = go.minW, gap = go.gap, rowGap = go.rowGap, maxCols = go.maxCols,
        minPx = go.minPx, equal = true })
    local _, colW = root.Cols(CW, go.minW, go.gap, go.maxCols, go.minPx)
    local labelW = math.min(win.cdLabelW or 0, math.floor((colW - 24) * 0.6))
    for i, grp in ipairs(groups) do
        local c = CdCard(i)
        c:Show()
        cdGrid:Add(c, function(f, w)
            local stk = f.stack
            stk:Begin(12, 12, w - 24)
            stk:Heading(grp.who)
            for _, ft in ipairs(grp.facts) do
                stk:Fact(ft[1], ft[2], { labelW = labelW, valueColor = ft[3] and "ok" or nil })
            end
            return math.ceil(12 + stk:End() + 12)
        end)
    end
    local h = math.ceil(cdGrid:End())
    win.cdH = h
    win.cdGrid = cdGrid
    return h
end

local function Refresh()
    if not win then return end
    local On = WP.ModuleOn
    win.subtitle:SetText(string.format(L("%s, niv. %d"), UnitName("player") or "", UnitLevel("player") or 0))

    -- 1. every state first: the strip and the lines share them

    local dLabel, cur, total, dFinished, nextStep = DungeonState()
    local need, goal, ready, bag = WritState()
    ready, bag = ready or 0, bag or 0
    local favor = WP.FavorNow and WP.FavorNow()
    local nBag = On("bags") and BagCount() or 0
    local open, running = 0, 0
    if WP.Orders then
        open = OrdersOpen()
        for _, o in ipairs(WP.Orders.Lists() or {}) do
            if o.status == "open" or o.status == "accepted" or o.status == "crafted" then running = running + 1 end
        end
    end
    local lfg, nEvents, nextE = 0, 0, nil
    if WP.EventList then
        local list = WP.EventList()
        nEvents = #list
        for _, e in ipairs(list) do if e.status == "open" and e.when >= time() - 1800 then nextE = e; break end end
        lfg = WP.LFGList and #WP.LFGList() or 0
    end

    -- the tools: every call is guarded, a broken tool only loses its state line
    local CT = WP.CityTour
    local cityOpen, inCity = 0, false
    if CT and CT.CurrentCity and CT.Tasks then
        local ok, city = pcall(CT.CurrentCity)
        if ok and city and CT.IsOn and CT.IsOn() then
            inCity = true
            local okT, _, n = pcall(CT.Tasks)
            cityOpen = (okT and type(n) == "number") and n or 0
        end
    end
    local tourOn = false
    if CT and CT.TourOn then local okR, v = pcall(CT.TourOn); tourOn = okR and v and true or false end
    local K = WP.Keys
    local keyLine
    if K and K.Summary then
        -- the passport's own line: one count, said the same way in both places
        local ok, s = pcall(K.Summary)
        if ok and type(s) == "string" then keyLine = s end
    elseif K and K.LIST and K.Status then
        local ok, have = pcall(function()
            local n = 0
            for _, k in ipairs(K.LIST) do if K.Status(k).state == "have" then n = n + 1 end end
            return n
        end)
        if ok then
            keyLine = have == 0 and string.format(L("Aucune clé pour l'instant (%d en tout)"), #K.LIST)
                or have == 1 and string.format(L("1 clé sur %d"), #K.LIST) or string.format(L("%d clés sur %d"), have, #K.LIST)
        end
    end
    local Sh = WP.Shared
    local nShared = 0
    if Sh and Sh.Dungeons then
        local ok, list = pcall(Sh.Dungeons)
        nShared = (ok and type(list) == "table") and #list or 0
    end
    local Tr = WP.Triage
    local triageN, logN, logMax = 0, 0, 0
    if Tr and On("triage") then
        local ok, n, max = pcall(Tr.LogCount)
        if ok then logN, logMax = tonumber(n) or 0, tonumber(max) or 0 end
        local okC, c = pcall(Tr.Count)
        triageN = (okC and type(c) == "number") and c or 0
    end
    local triageSoon = triageN > 0 and logMax > 0 and logMax - logN <= 2

    -- 2. "now": only what a line cannot do (start the GPS, act before a time, open a tool)

    local nowKey
    if On("writs") and ready > 0 then nowKey = "writs"
    elseif On("events") and nextE and nextE.when - time() < 3600 then nowKey = "event"
    elseif cityOpen > 0 and not tourOn then nowKey = "city"
    elseif triageSoon then nowKey = "triage"
    elseif WP.GPS and WP.GPS.Active() then nowKey = "gps" end
    local t = win.now
    if nowKey == "writs" then
        t:Set(N(ready, "1 Writ est prêt à rendre.", "%d Writs sont prêts à rendre."), L("Y aller"), function()
            Close()
            -- the tour already runs: on to the next stop; otherwise start it
            if WLWritsCharDB and WLWritsCharDB.gps then WP.GoNext() else WP.ToggleGPS() end
        end)
    elseif nowKey == "event" then
        local mins = math.ceil((nextE.when - time()) / 60)
        t:Set(mins > 0 and string.format(L("%s commence dans %d min."), nextE.title, mins) or string.format(L("%s a commencé."), nextE.title),
            L("Voir l'événement"), function() Close(); if WP.ToggleEvents then WP.ToggleEvents() end end)
    elseif nowKey == "city" then
        t:Set(N(cityOpen, "1 chose à faire dans cette ville.", "%d choses à faire dans cette ville."), L("Voir la tournée"),
            function() Close(); WP.CityTour.Show() end)
    elseif nowKey == "triage" then
        t:Set(L("Ton journal de quêtes est presque plein."), L("Trier le journal"),
            function() Close(); WP.Triage.Show() end)
    elseif nowKey == "gps" then
        -- only a running GPS: a quiet line, its stop is not the main thing to do
        local dest = WP.GPS.DestName and WP.GPS.DestName()
        t:Set((type(dest) == "string" and dest ~= "") and string.format(L("Le GPS te guide vers %s."), dest) or L("Le GPS te guide."), L("Arrêter le GPS"),
            function() WP.StopGPS(); WP.RefreshHome() end, "secondary")
    end
    t:SetShown(nowKey ~= nil)

    -- 3. the lines: state only, each fact said once on the page

    if dLabel and not dFinished then
        Put("dungeons", "Show2", { title = L("Guide de quêtes"), line1 = L("Tous les guides"),
            line2 = (nextStep and nextStep ~= "") and string.format(L("Prochaine étape : %s"), nextStep) or nil,
            hint = L("Clic : tous les guides") })
    elseif dLabel then
        Put("dungeons", "Show2", { title = L("Guide de quêtes"), line1 = L("Tous les guides"), line2 = L("Choisis ton prochain guide."),
            hint = L("Clic : choisir un guide") })
    else
        Put("dungeons", "Show2", { title = L("Guide de quêtes"), line1 = L("Aucun guide choisi"),
            line2 = L("Donjons, raids et quêtes de classe, depuis là où tu es."), hint = L("Clic : choisir un guide") })
    end

    -- Writs: what waits first (the strip says the ready ones when it shows), then the reputation
    if need then
        local rep = need > 0 and (need == 1 and string.format(L("Encore 1 point avant %s"), WP.Reaction(goal))
            or string.format(L("Encore %s points avant %s"), Thousands(need), WP.Reaction(goal)))
            or string.format(L("%s atteint"), WP.Reaction(goal))
        local parts = {}
        if ready > 0 and nowKey ~= "writs" then parts[#parts + 1] = N(ready, "1 Writ prêt à rendre", "%d Writs prêts à rendre") end
        if bag > 0 then parts[#parts + 1] = N(bag, "1 enveloppe à ouvrir", "%d enveloppes à ouvrir") end
        if #parts > 0 then
            Put("writs", "Show2", { title = L("Writs"), line1 = table.concat(parts, " · "), lineColor = C.ok, line2 = rep,
                hint = L("Clic : ouvrir les Writs") })
        else
            Put("writs", "Show2", { title = L("Writs"), line1 = rep, line2 = ready == 0 and L("Rien à rendre pour l'instant") or nil,
                hint = L("Clic : ouvrir les Writs") })
        end
    else
        Put("writs", "Show2", { title = L("Writs"), line1 = L("Faction pas encore vue"), line2 = L("Parle à un PNJ de cette faction pour qu'elle apparaisse."),
            lineColor = C.muted, hint = L("Clic : ouvrir les Writs") })
    end

    Put("favor", "Show2", { title = L("Faveur du marchand"),
        line1 = favor and (favor == 1 and L("1 point de Faveur") or string.format(L("%s points de Faveur"), Thousands(favor))) or L("Pas encore de Faveur"),
        hint = L("Clic : voir les caisses") })

    Put("bags", "Show2", { title = L("Sacs"),
        line1 = nBag > 0 and N(nBag, "1 objet de quête à jeter", "%d objets de quête à jeter") or L("Rien à jeter"),
        lineColor = nBag > 0 and C.warn or C.muted, hint = L("Clic : voir les objets à jeter") })

    local runLine = running > 0 and N(running, "Tu as 1 commande en cours", "Tu as %d commandes en cours") or nil
    if open > 0 then
        Put("orders", "Show2", { title = L("Commandes"), line1 = N(open, "1 commande à accepter", "%d commandes à accepter"),
            lineColor = C.warn, line2 = runLine, hint = L("Clic : ouvrir les commandes") })
    else
        Put("orders", "Show2", { title = L("Commandes"), line1 = runLine or L("Aucune commande en cours"),
            lineColor = C.muted, hint = L("Clic : ouvrir les commandes") })
    end

    -- guild: who is on, and where you stand in this week's PvP ranking
    if IsInGuild and IsInGuild() and WP.GuildRoster then
        local _, online = WP.GuildRoster(true)
        online = online or 0
        local pos
        for i, e in ipairs(WP.GuildRanking and WP.GuildRanking(true) or {}) do if e.name == UnitName("player") then pos = i end end
        Put("guild", "Show2", { title = L("Guilde"), line1 = N(online, "1 membre en ligne", "%d membres en ligne"),
            line2 = pos and (pos == 1 and L("Tu es 1er au classement PvP de la semaine") or string.format(L("Tu es %de au classement PvP de la semaine"), pos))
                or L("Pas encore classé en PvP cette semaine"),
            hint = L("Clic : ouvrir la guilde") })
    else
        Put("guild", "Show2", { title = L("Guilde"), line1 = L("Tu n'es pas dans une guilde"), lineColor = C.muted, hint = L("Clic : ouvrir la guilde") })
    end

    -- events: the next one, and who looks for a group now; the strip already names an event about
    -- to start, so the line says what comes after it
    local lfgLine = lfg > 0 and N(lfg, "1 joueur cherche un groupe", "%d joueurs cherchent un groupe") or nil
    if nowKey == "event" then
        local l1 = lfgLine or (nEvents > 1 and N(nEvents - 1, "1 autre événement à venir", "%d autres événements à venir")) or nil
        Put("events", "Show2", { title = L("Groupes"), line1 = l1 or L("Aucun autre événement prévu"),
            lineColor = C.muted, hint = L("Clic : ouvrir Groupes") })
    else
        Put("events", "Show2", { title = L("Groupes"),
            line1 = nextE and (tostring(nextE.title) .. " · " .. WP.EventWhen(nextE.when)) or L("Aucun événement prévu"),
            lineColor = C.muted,
            line2 = lfgLine or (nEvents > 0 and N(nEvents, "1 événement à venir", "%d événements à venir") or nil),
            hint = L("Clic : ouvrir Groupes") })
    end

    -- feedback: a bug, an idea, a suggestion, and the reports received (the account that gets them)
    Put("feedback", "Show2", { title = L("Nous écrire"), line1 = L("Un bug, une idée, une suggestion : sans compte"),
        lineColor = C.muted, hint = L("Clic : écrire à l'équipe WL Helper") })
    if WP.Reports and WP.Reports.Counts then
        local okC, nIn, nNew = pcall(WP.Reports.Counts)
        if okC then
            Put("reports", "Show2", { title = L("Rapports des joueurs"),
                line1 = (nIn or 0) == 0 and L("Aucun rapport reçu") or N(nIn, "1 rapport reçu", "%d rapports reçus"),
                lineColor = (nNew or 0) > 0 and C.warn or C.muted,
                line2 = (nNew or 0) > 0 and N(nNew, "1 nouveau", "%d nouveaux") or nil,
                hint = L("Clic : lire les rapports") })
        end
    end

    -- upgrades: how many bag items are better than what you wear, for which spec
    local Wt = WP.Weights
    if Wt then
        local GetLink = C_Container and C_Container.GetContainerItemLink
        if bagsDirty and GetLink and WP.UpgradeCheck then
            -- every bag slot is checked: only after the bags changed, not on every refresh
            upN = 0
            for bagID = 0, NUM_BAG_SLOTS or 4 do
                for slot = 1, (C_Container.GetContainerNumSlots(bagID) or 0) do
                    local link = GetLink(bagID, slot)
                    if link and WP.UpgradeCheck(link).up then upN = upN + 1 end
                end
            end
            bagsDirty = false
        end
        local okS, specName = pcall(Wt.SpecName)
        specName = (okS and type(specName) == "string" and specName ~= "") and specName or nil
        Put("upgrades", "Show2", { title = L("Améliorations"),
            line1 = upN > 0 and N(upN, "1 amélioration dans tes sacs", "%d améliorations dans tes sacs") or L("Rien de mieux dans tes sacs"),
            lineColor = upN > 0 and C.ok or C.muted,
            line2 = specName and string.format(L("Selon ta spé %s"), specName) or nil,
            hint = L("Clic : choisir ta spé et voir tes améliorations") })
    else
        Put("upgrades", "Show2", { title = L("Améliorations"), line1 = L("Rien de mieux dans tes sacs"), hint = L("Clic : choisir ta spé et voir tes améliorations") })
    end

    -- battlegrounds: the bonus of the day, else what the window holds
    if WP.BG and WP.BG.HomeLine then
        local okB, bgLine = pcall(WP.BG.HomeLine)
        Put("pvp", "Set", L("Champs de bataille"), okB and bgLine or "", L("Clic : ouvrir les champs de bataille"))
    end

    Put("reps", "Set", L("Réputations"), L("Ce qu'elles débloquent et comment les monter"), L("Clic : ouvrir le guide des réputations"))

    -- the tools: a dot when one has something to do now
    Put("goto", "Set", L("Aller à"), L("Un lieu, un PNJ, une ville : le GPS t'y mène"), L("Clic : ouvrir « Aller à »"))
    local cityDot = cityOpen > 0 and not tourOn
    Put("city", "Set", L("Tournée en ville"),
        cityOpen > 0 and N(cityOpen, "1 chose à faire dans cette ville", "%d choses à faire dans cette ville")
            or L("Ce qu'il y a à faire en arrivant dans une capitale"), L("Clic : ouvrir la tournée en ville"),
        cityDot, N(cityOpen, "1 chose à faire dans cette ville", "%d choses à faire dans cette ville"))
    local keyReason
    if K and On("keys") then keyReason = KeyNeeded(K) end
    Put("keys", "Set", L("Passeport des clés"), keyLine, L("Clic : ouvrir le passeport des clés"), keyReason ~= nil, keyReason)
    Put("shared", "Set", L("Quêtes en commun"),
        nShared > 0 and (nShared == 1 and L("1 donjon en commun") or string.format(L("%d donjons en commun"), nShared))
            or L("Les membres qui font les mêmes donjons que toi"), L("Clic : voir les quêtes en commun"))
    local triLine = string.format(L("Journal : %d quêtes sur %d"), logN, logMax)
    if triageN > 0 then triLine = N(triageN, "1 quête à abandonner", "%d quêtes à abandonner") .. " · " .. triLine end
    local triDot = triageSoon or (logMax > 0 and logN >= logMax)
    Put("triage", "Set", L("Tri du journal"), triLine, L("Clic : voir les quêtes à abandonner"),
        triDot, L("Ton journal de quêtes est presque plein."))

    -- 4. the activity cards: one sentence on where you stand, one button that does it
    local GC = groupCards
    local function Main(key, o) if GC[key] then GC[key]:SetMain(o) end end
    local function Away(fn) return function() Close(); fn() end end

    -- Progresser: the guide you follow, and the button that takes you back to it
    if not On("dungeons") then
        Main("quests", { text = L("Le guide de quêtes est éteint."), color = C.muted, label = L("Allumer le guide"),
            fn = function() WP.SetModule("dungeons", true); WP.RefreshHome() end })
    elseif dLabel and not dFinished then
        Main("quests", { text = string.format(L("%s, étape %d sur %d"), dLabel, cur or 1, total or 1),
            detail = (nextStep and nextStep ~= "") and string.format(L("Prochaine étape : %s"), nextStep) or nil,
            label = L("Reprendre le guide"), tip = { L("Reprendre le guide"), L("Clic : ouvrir le guide") },
            fn = Away(function() if root.ShowGuide then root.ShowGuide() else OpenGuide() end end) })
    elseif dLabel then
        Main("quests", { text = string.format(L("%s, terminée"), dLabel), color = C.ok, detail = L("Choisis ton prochain guide."),
            label = L("Choisir un guide"), tip = { L("Choisir un guide"), L("Clic : choisir parmi tous les guides") },
            fn = Away(OpenGuide) })
    else
        Main("quests", { text = L("Aucun guide choisi"), detail = L("Donjons, raids et quêtes de classe, depuis là où tu es."),
            label = L("Choisir un guide"), tip = { L("Choisir un guide"), L("Clic : choisir parmi tous les guides") },
            fn = Away(OpenGuide) })
    end

    -- PvP: no card of its own on Home any more (HOME_SKIP): "Cette semaine" has the PvP weekly
    if WP.BG and WP.BG.Toggle then
        Main("pvp", { text = L("Réputation, maîtres de guerre et ton set PvP"), label = L("Ouvrir les champs de bataille"),
            tip = { L("Champs de bataille"), L("Clic : ouvrir les champs de bataille") },
            fn = Away(function() WP.BG.Toggle(nil, true) end) })
    end

    -- Cette semaine: the reset, the PvE weekly, the PvP weekly
    RefreshWeek(Away)

    -- Argent et métiers: what waits first (Writs to turn in, orders, bags), else the reputation
    local repLine
    if need then
        repLine = need > 0 and (need == 1 and string.format(L("Encore 1 point avant %s"), WP.Reaction(goal))
            or string.format(L("Encore %s points avant %s"), Thousands(need), WP.Reaction(goal)))
            or string.format(L("%s atteint"), WP.Reaction(goal))
    end
    if On("writs") and ready > 0 and nowKey ~= "writs" then
        Main("items", { text = N(ready, "1 Writ prêt à rendre", "%d Writs prêts à rendre"), color = C.ok, detail = repLine,
            label = L("Y aller"), tip = { L("Writs"), L("Clic : ouvrir les Writs") }, fn = function()
                Close()
                if WLWritsCharDB and WLWritsCharDB.gps then WP.GoNext() else WP.ToggleGPS() end
            end })
    elseif On("orders") and open > 0 and WP.ToggleOrders then
        Main("items", { text = N(open, "1 commande à accepter", "%d commandes à accepter"), color = C.warn, detail = repLine,
            label = L("Voir les commandes"), fn = Away(WP.ToggleOrders) })
    elseif nBag > 0 and WP.Cleaner then
        Main("items", { text = N(nBag, "1 objet de quête à jeter", "%d objets de quête à jeter"), color = C.warn, detail = repLine,
            label = L("Nettoyer les sacs"), fn = Away(function() WP.Cleaner.Toggle() end) })
    elseif On("writs") and WP.Open then
        Main("items", { text = repLine or L("Faction pas encore vue"), color = repLine and C.fg or C.muted,
            detail = repLine and (bag > 0 and N(bag, "1 enveloppe à ouvrir", "%d enveloppes à ouvrir") or L("Rien à rendre pour l'instant"))
                or L("Parle à un PNJ de cette faction pour qu'elle apparaisse."),
            label = L("Ouvrir les Writs"), fn = Away(function() WP.Open("writs") end) })
    else
        Main("items", { text = L("Rien à faire pour l'instant."), color = C.muted })
    end

    -- Guilde et groupes: the next event (the strip names one about to start), who is on
    local inGuild = IsInGuild and IsInGuild() and WP.GuildRoster and true or false
    local onlineLine
    if inGuild then
        local _, online = WP.GuildRoster(true)
        onlineLine = N(online or 0, "1 membre en ligne", "%d membres en ligne")
    end
    local lfgLine = lfg > 0 and N(lfg, "1 joueur cherche un groupe", "%d joueurs cherchent un groupe") or nil
    if On("events") and nextE and nowKey ~= "event" and WP.ToggleEvents then
        Main("guild", { text = tostring(nextE.title) .. " · " .. WP.EventWhen(nextE.when), detail = lfgLine or onlineLine,
            label = L("Voir l'événement"), fn = Away(WP.ToggleEvents) })
    elseif inGuild and On("guild") and WP.ToggleGuild then
        Main("guild", { text = onlineLine, detail = lfgLine or (nEvents > 0 and N(nEvents, "1 événement à venir", "%d événements à venir"))
            or L("Aucun événement prévu"), label = L("Ouvrir la guilde"), fn = Away(WP.ToggleGuild) })
    elseif On("events") and WP.ToggleEvents then
        Main("guild", { text = inGuild and onlineLine or L("Tu n'es pas dans une guilde"), color = inGuild and C.fg or C.muted,
            detail = lfgLine, label = L("Voir les groupes"), fn = Away(WP.ToggleEvents) })
    else
        Main("guild", { text = inGuild and onlineLine or L("Tu n'es pas dans une guilde"), color = C.muted })
    end

    -- Voyager: the GPS that runs, the city's errands, else Go to
    local gpsOn = WP.GPS and WP.GPS.Active and WP.GPS.Active()
    if gpsOn and nowKey ~= "gps" then
        local dest = WP.GPS.DestName and WP.GPS.DestName()
        Main("travel", { text = (type(dest) == "string" and dest ~= "") and string.format(L("Le GPS te guide vers %s."), dest) or L("Le GPS te guide."),
            label = L("Arrêter le GPS"), fn = function() WP.StopGPS(); WP.RefreshHome() end })
    elseif cityOpen > 0 and nowKey ~= "city" and CT and CT.Show then
        Main("travel", { text = N(cityOpen, "1 chose à faire dans cette ville.", "%d choses à faire dans cette ville."),
            label = L("Voir la tournée"), fn = Away(function() CT.Show() end) })
    elseif WP.GoTo and WP.GoTo.Show then
        Main("travel", { text = L("Un lieu, un PNJ, une ville : le GPS t'y mène"), label = L("Ouvrir « Aller à »"),
            tip = { L("Aller à"), L("Clic : ouvrir « Aller à »") }, fn = function() OpenGoTo("") end })
    else
        Main("travel", { text = L("Ce qu'il y a à faire en arrivant dans une capitale"), color = C.muted })
    end

    -- Aide et retours: write to us; the reports received (the account that gets them) as a line
    if WP.Feedback then
        Main("feedback", { text = L("Un bug, une idée, une suggestion : sans compte"), color = C.muted, label = L("Nous écrire"),
            tip = { L("Nous écrire"), L("Clic : écrire à l'équipe WL Helper") }, fn = Away(function() WP.Feedback("bug") end) })
    else
        Main("feedback", {})
    end

    -- switched off: dimmed with "Éteint", a click turns it back on; every line keeps its place
    for _, e in ipairs(win.hubOrder or {}) do
        local r = cards[e.key]
        if r then
            r.wantShown = true
            r:Show()
            if not WP.HubEntryOn(e) then
                -- the city tour is not a module: its own words
                if e.module then r:ShowOff(L(e.label))
                else r:ShowOff(L(e.label), L("Éteinte"), L("Clic : la rallumer")) end
            end
        end
    end

    -- a newer version seen on another player's copy
    local newer = WP.UpdateAvailable and WP.UpdateAvailable()
    if newer and WP.UpdateText then win.upd:SetText(WP.UpdateText(newer), "info") end
    win.upd:SetShown(newer ~= nil and WP.UpdateText ~= nil)

    RefreshCooldowns()
    Layout()
end

-- The Hub's Home page (Writs/Options.lua calls it): Build(p, width, hub) once per build of the
-- Hub, Refresh(opening) each time Home shows (opening: the bags are scanned again), Layout().
WP.HomePage = {
    Build = Build,
    Refresh = function(opening)
        if opening then bagsDirty = true; HomeEvents(Visible()) end
        Refresh()
    end,
    Layout = function() Layout() end,
    -- the Hub's content column got a new width (the window was resized): used by the next Layout
    SetWidth = function(width)
        CW = math.floor((width or 660) - 32)
        COL_W = math.floor((CW - 16) / 2)
    end,
}

-- Redraws Home's states, only while Home is on screen (never for a hidden page).
function WP.RefreshHome()
    if not Visible() then return end
    Refresh()
    -- wrapped lines measure right once their width is applied: once more on the next frame
    if C_Timer and C_Timer.After then C_Timer.After(0, function() if Visible() then Layout() end end) end
end

function WP.OpenHome()
    if WP.OpenHub then WP.OpenHub("home") end
end

-- /wlh and the minimap button: Home, or closes the window when Home already shows.
function WP.ToggleHome()
    if Visible() then Close() else WP.OpenHome() end
end

-- ---------------------------------------------------------------- minimap button

-- My crafter status (Orders, T-60): what the guild sees, and the status a click picks next
-- (Available, Busy, Away, round). nil when the Orders module is off or not loaded.
local NEXT_STATUS = { a = "b", b = "o", o = "a" }
local WHY_AUTO = { afk = "absent (AFK)", queue = "en file d'attente", inst = "en donjon" }
local function CrafterStatus()
    local O = WP.Orders
    if not (O and O.MyStatus and O.StatusWord and O.BaseStatus and O.CycleStatus) or not WP.ModuleOn("orders") then return nil end
    local ok, s, why = pcall(O.MyStatus)
    if not ok then return nil end
    local base = O.BaseStatus()
    return O.StatusWord(s) or O.StatusWord(base) or "?", O.StatusWord(NEXT_STATUS[base] or "a"), why and L(WHY_AUTO[why] or "") or nil, s
end
local STATUS_COLOR = { a = "ok", b = "warn", d = "info", o = "faint" }

-- Tooltip: where you stand first, then what the mouse does.
function WP.MinimapTooltip(owner)
    local tt = GameTooltip
    tt:SetOwner(owner, "ANCHOR_LEFT")
    tt:AddLine("WL Helper", C.fg[1], C.fg[2], C.fg[3])
    local function Row(label, value, col)
        col = col or C.fg
        tt:AddDoubleLine(label, value, C.muted[1], C.muted[2], C.muted[3], col[1], col[2], col[3])
    end
    local label, cur, total, finished = DungeonState()
    if not WP.ModuleOn("dungeons") then Row(L("Guide de quêtes"), L("Éteint"), C.faint)
    elseif label then Row(L("Guide de quêtes"), finished and string.format(L("%s, terminée"), label) or string.format(L("%s, étape %d sur %d"), label, cur or 1, total or 1))
    else Row(L("Guide de quêtes"), L("Aucun guide choisi"), C.muted) end
    local need, _, ready = WritState()
    if not WP.ModuleOn("writs") then Row(L("Writs"), L("Éteint"), C.faint)
    elseif need then Row(L("Writs"), ready > 0 and N(ready, "1 Writ prêt", "%d Writs prêts") or L("Rien à rendre"), ready > 0 and C.ok or C.fg) end
    if not WP.ModuleOn("bags") then Row(L("Sacs"), L("Éteint"), C.faint)
    else
        local n = BagCount()
        Row(L("Sacs"), n > 0 and string.format(L("%d à jeter"), n) or L("Rien à jeter"), n > 0 and C.warn or C.fg)
    end
    local open = WP.ModuleOn("orders") and OrdersOpen() or 0
    if open > 0 then Row(L("Commandes"), string.format(L("%d à accepter"), open), C.ok) end
    local word, _, _, st = CrafterStatus()
    if word then Row(L("Artisan"), word, C[STATUS_COLOR[st] or "fg"] or C.fg) end
    local lfg = WP.ModuleOn("events") and WP.LFGList and #WP.LFGList() or 0
    if lfg > 0 then Row(L("Groupes"), N(lfg, "1 cherche un groupe", "%d cherchent un groupe")) end
    local newer = WP.UpdateAvailable and WP.UpdateAvailable()
    if newer and WP.UpdateText then
        tt:AddLine(" ")
        tt:AddLine(WP.UpdateText(newer), C.info[1], C.info[2], C.info[3], true)
    end
    tt:AddLine(" ")
    local a = C.accentSoft
    tt:AddLine(L("Clic : ouvrir l'Accueil"), a[1], a[2], a[3])
    tt:AddLine(L("Clic droit : ouvrir un module"), a[1], a[2], a[3])
    tt:AddLine(L("Glisser : déplacer le bouton"), a[1], a[2], a[3])
    tt:Show()
end

-- Right-click menu: straight to a module. A list in the dropdown style (24 px rows, icons).
local menu
local function MenuRow(parent, y, icon, text, onClick, disabledReason, hint)
    local b = CreateFrame("Button", nil, parent)
    b.wlOwned = true
    b:SetHeight(24)
    b:SetPoint("TOPLEFT", 1, y); b:SetPoint("TOPRIGHT", -1, y)
    b.hl = S.Solid(b, "BACKGROUND", C.hoverFill); b.hl:SetAllPoints(); b.hl:SetAlpha(0)
    b.press = S.Solid(b, "BORDER", C.pressFill); b.press:SetAllPoints(); b.press:Hide()
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetSize(16, 16); b.icon:SetPoint("LEFT", 8, 0)
    b.hd = type(icon) == "table"
    -- a glyph with its own colour (the upgrades arrow) keeps it; the others are muted, fg on hover
    b.hdColor = b.hd and icon.color or nil
    if b.hd then root.SetHDIcon(b.icon, icon.hd, b.hdColor or C.muted) else S.Painted(b.icon, icon) end
    b.label = S.Text(b, F.label, C.fg)
    b.label:SetPoint("LEFT", b.icon, "RIGHT", 8, 0); b.label:SetPoint("RIGHT", -8, 0)
    b.label:SetJustifyH("LEFT")
    b.label:SetText(text)
    S.ClampLabel(b.label, text, b)
    b.disabledReason = disabledReason
    local function Paint()
        local on = b:IsEnabled() ~= false
        b:SetAlpha(on and (b.off and 0.45 or 1) or C.disabledAlpha)
        if b.hd and not b.hdColor then local c = (b.hov and on) and C.fg or C.muted; b.icon:SetVertexColor(c[1], c[2], c[3]) end
    end
    b:SetScript("OnEnter", function(self)
        self.hov = true
        if self:IsEnabled() ~= false then root.Tween(self, 0, 1, 0.10, function(v) self.hl:SetAlpha(v) end) end
        Paint()
        if self:IsEnabled() == false then
            if self.disabledReason then S.Tip(self, { text, self.disabledReason }) end
        elseif self.off then
            S.Tip(self, { text, L("Module éteint"), L("Clic : allumer le module") })
        elseif hint then
            S.Tip(self, { text, hint })
        end
    end)
    b:SetScript("OnLeave", function(self)
        self.hov = nil
        root.Tween(self, 1, 0, 0.10, function(v) self.hl:SetAlpha(v) end)
        Paint(); S.HideTip()
    end)
    b:SetScript("OnMouseDown", function(self) if self:IsEnabled() ~= false then self.press:Show() end end)
    b:SetScript("OnMouseUp", function(self) self.press:Hide() end)
    b:SetScript("OnEnable", Paint); b:SetScript("OnDisable", Paint)
    b:SetScript("OnClick", function(self)
        if self.keep then onClick(self); return end
        menu:Hide()
        if self.off then
            if self.entry then WP.HubTurnOn(self.entry) elseif self.module then WP.SetModule(self.module, true) end
        end
        onClick()
    end)
    function b:SetOff(off) self.off = off and true or nil; Paint() end
    Paint()
    return b
end

function WP.MinimapMenu(owner)
    -- built in the language of its first opening: built again after a language change
    if menu and menu.lang ~= L("Réglages") then
        menu:Hide(); menu:SetScript("OnUpdate", nil); menu = nil
    end
    if not menu then
        menu = CreateFrame("Frame", "WLHelperMinimapMenu", UIParent)
        menu.wlOwned = true
        -- above minimap button bars and every window
        menu:SetFrameStrata("TOOLTIP"); menu:SetFrameLevel(50); menu:SetClampedToScreen(true); menu:EnableMouse(true)
        S.Solid(menu, "BACKGROUND", C.panel, 0.98):SetAllPoints()
        S.Border(menu, C.cardEdge)
        if not tContains or not tContains(UISpecialFrames, "WLHelperMinimapMenu") then
            tinsert(UISpecialFrames, "WLHelperMinimapMenu")
        end
        -- { icon, label, onClick, module (dimmed when off), key in menu.buttons, why disabled, click
        -- hint, hub entry }: the Hub's windows by activity (WP.HUB, the order of Home), a rule
        -- between activities, then the GPS, help, settings and contact
        local items = {}
        -- my crafter status: a click picks the next one, the menu stays open
        if WP.Orders and WP.Orders.CycleStatus then
            items[#items + 1] = { { hd = "hammer" }, string.format(L("Artisan : %s"), "?"), function(self)
                -- turned on from the menu (module off): the module only, no status change
                if not self then return end
                pcall(WP.Orders.CycleStatus)
                if self.Sync then self:Sync(); if self.tipLines then S.Tip(self, self.tipLines) end end
            end, nil, "crafter" }
            items[#items + 1] = false
        end
        for _, g in ipairs(WP.HUB_GROUPS or {}) do
            local list = WP.HubEntries and WP.HubEntries(g.key) or {}
            if #list > 0 and #items > 0 then items[#items + 1] = false end
            for _, e in ipairs(list) do
                items[#items + 1] = { WP.HubIcon(e), L(e.label), e.open, e.module, e.key, nil, WP.HubClickHint(e.key), e }
            end
        end
        if #items > 0 then items[#items + 1] = false end
        items[#items + 1] = { { hd = root.ARROW }, L("Arrêter le GPS"), function() WP.StopGPS() end, nil, "gps", L("Aucun trajet GPS en cours."), L("Clic : arrêter le GPS") }
        items[#items + 1] = { WP.MODULE_ICON.help, L("Comment faire... ?"), function() if WP.Help then WP.Help.Toggle() end end, nil, nil, nil, L("Clic : ouvrir « Comment faire... ? »") }
        items[#items + 1] = { { hd = "gear" }, L("Réglages"), function() if WP.OpenHub then WP.OpenHub("general") end end, nil, nil, nil, L("Clic : ouvrir les réglages") }
        items[#items + 1] = { { hd = "mail" }, L("Nous écrire"), function() if WP.Feedback then WP.Feedback("idea") end end, nil, nil, nil, L("Clic : ouvrir le formulaire pour nous écrire") }
        local y = -4
        menu.buttons, menu.rows = {}, {}
        for _, it in ipairs(items) do
            if it then
                local b = MenuRow(menu, y, it[1], it[2], it[3], it[6], it[7])
                b.module, b.entry = it[4], it[8]
                menu.rows[#menu.rows + 1] = b
                local key = it[5] or it[4]
                if key then menu.buttons[key] = b end
                y = y - 24
            else
                local line = S.Rule(menu)
                line:SetPoint("TOPLEFT", 8, y - 4); line:SetPoint("TOPRIGHT", -8, y - 4)
                y = y - 9
            end
        end
        menu:SetSize(208, -y + 4)
        menu.lang = L("Réglages")
        local cb = menu.buttons.crafter
        if cb then
            cb.keep = true
            function cb:Sync()
                local word, nxt, why = CrafterStatus()
                local text = string.format(L("Artisan : %s"), word or L("Éteint"))
                self.label:SetText(text)
                self.label.wlFull = text
                self.tipLines = { text, L("Ce que la guilde voit dans les Commandes.") }
                if why then self.tipLines[#self.tipLines + 1] = string.format(L("Automatique pour l'instant : %s."), why) end
                if word and nxt then self.tipLines[#self.tipLines + 1] = string.format(L("Clic : passer à %s"), nxt) end
            end
            -- its tooltip follows the status (the row's own one has no hint)
            cb:HookScript("OnEnter", function(self)
                if not self.off and self:IsEnabled() ~= false and self.tipLines then S.Tip(self, self.tipLines) end
            end)
        end
        -- closes when the mouse has left it for a moment
        menu:SetScript("OnUpdate", function(self, dt)
            if self:IsMouseOver() or (self.owner and self.owner:IsMouseOver()) then self.away = 0; return end
            self.away = (self.away or 0) + dt
            if self.away > 1.5 then self:Hide() end
        end)
    end
    if menu:IsShown() then menu:Hide(); return end
    menu.owner = owner; menu.away = 0
    menu.buttons.gps:SetEnabled(WP.GPS.Active() and true or false)
    if menu.buttons.crafter then
        local on = WP.ModuleOn("orders")
        menu.buttons.crafter:SetOff(not on)
        menu.buttons.crafter.keep = on and true or nil
        menu.buttons.crafter.module = (not on) and "orders" or nil
        menu.buttons.crafter:Sync()
    end
    for _, b in ipairs(menu.rows) do
        if b.entry then b:SetOff(not WP.HubEntryOn(b.entry))
        elseif b.module then b:SetOff(not WP.ModuleOn(b.module)) end
    end
    menu:ClearAllPoints()
    menu:SetPoint("TOPRIGHT", owner, "BOTTOMLEFT", 4, 4)
    GameTooltip:Hide()
    menu:Show()
end
