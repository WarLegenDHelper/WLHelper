-- Writs/Options.lua: the WL Helper window, "the Hub" (T-55, DESIGN 3.20): one window for Home and
-- every settings page. The workspace size (70 % x 78 % of the screen, 900 x 620 to 1400 x 900),
-- resizable from its bottom-right grip (size saved), each page scrolls inside it. At the left a nav:
-- the settings search, Home, then the activities (Writs/Hub.lua WP.HUB_GROUPS) with their settings
-- pages; at the bottom Settings (General, About), "How do I...?", "What's new", "Write to us" and
-- the version. At the right the page: a fixed header (title, one sentence) over its scrolled
-- content. Home is built by Writs/Home.lua (WP.HomePage) into its page; the settings pages are
-- cards of rows (S.SettingRow: label and one line of description on the left, control on the
-- right) in 2 columns, 3 on a wide window (S.SettingsCard). Built the first time it opens; a new
-- size only lays the page out again.
-- WLHelperHome and WLHelperOptions (the two windows it replaced) are aliases of WLHelperHub.
-- No secure frame lives here: the Hub may open, close and change in combat.
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
    ["La flèche suit un vrai chemin autour des collines et par les portes, pour tous les guides (WL Helper Nav). Sans lui, elle va tout droit."] =
        "The arrow follows a real path around hills and through gates, for every guide (WL Helper Nav). Without it, it goes straight.",
    -- profession cooldowns (Writs page)
    ["Recharges de métier"] = "Profession cooldowns",
    ["Prix de revient (HV)"] = "Cost price (AH)",
    ["Retenir mes prix d'achat"] = "Remember what I pay",
    ["Retient ce que tu paies à l'HV (moyenne sur 60 jours), l'affiche dans l'infobulle et prévient si tu vends en dessous."] = "Remembers what you pay at the AH (60-day average), shows it in the item tooltip and warns when you list below it.",
    ["Prévenir quand une recharge est prête"] = "Tell me when a cooldown is ready",
    ["Transmutations, Étoffe lunaire, Salière : une ligne dans le chat, pour tous tes personnages. Leur temps restant est sur l'Accueil."] =
        "Transmutes, Mooncloth, Salt Shaker: one line in chat, for all your characters. Their time left is on Home.",
    -- window, nav and search
    ["Réglages"] = "Settings",
    ["Accueil"] = "Home",
    ["Où tu en es, et tout ce que WL Helper peut ouvrir."] = "Where you stand, and everything WL Helper can open.",
    ["Chercher un réglage"] = "Search settings",
    ["Quoi de neuf"] = "What's new",
    ["Clic : ouvrir « Quoi de neuf »"] = "Click: open What's new",
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
    ["Le guide des quêtes de donjon, de raid et de classe, avec la route et la flèche."] =
        "The dungeon, raid and class quest guide, with the route and the arrow.",
    ["Les Writs à faire, la liste d'achat et la remise automatique."] = "The Writs to do, the shopping list and automatic turn-in.",
    ["Repère les objets de quête qui ne servent plus et libère de la place."] = "Finds quest items you no longer need and frees up space.",
    ["Demande un objet à un artisan de la guilde, ou prends les commandes des autres."] =
        "Ask a guild crafter for an item, or take other people's orders.",
    ["Toute la guilde, le classement PvP et les quêtes en commun."] = "The whole guild, the PvP ranking and the shared quests.",
    ["Tes clés et accès de donjons et de raids, et qui les a dans la guilde."] =
        "Your dungeon and raid keys and attunements, and who in the guild has them.",
    ["Les quêtes à abandonner quand ton journal est presque plein."] = "The quests to abandon when your quest log is nearly full.",
    -- the Orders and Guild pages
    ["Les alertes des commandes : favoris, recettes surveillées, son."] = "Order alerts: favourites, watched recipes, sound.",
    ["Ce que tu partages avec la guilde."] = "What you share with the guild.",
    ["Alertes"] = "Alerts",
    ["Partage"] = "Sharing",
    ["En ville"] = "In town",
    ["Journal de quêtes"] = "Quest log",
    ["Les deux alertes se règlent aussi sur ta fiche d'artisan, dans la fenêtre Commandes."] =
        "Both alerts can also be set on your crafter profile, in the Orders window.",
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
    ["Garde-la enfoncée, puis fais un clic droit sur l'ennemi. Avec « Aucune », le clic droit seul tire : pratique avec une baguette."] =
        "Hold it, then right-click the enemy. With \"None\", right-click alone shoots: handy with a wand.",
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
    ["GPS et alertes"] = "GPS and alerts", ["Quêtes montrées"] = "Quests shown",
    ["Flèche du guide"] = "Guide arrow",
    ["Le GPS te mène à la prochaine étape du guide."] = "The GPS leads you to the guide's next step.",
    ["Alerte des monstres rares"] = "Rare monster alert",
    ["Dans un donjon, un message et un son quand un monstre rare apparaît."] = "In a dungeon, a message and a sound when a rare monster shows up.",
    ["Points GPS à chaque étape"] = "GPS points at each step",
    ["Suivi du guide"] = "Guide tracker",
    ["Une petite fenêtre avec l'action à faire, quand la fenêtre du guide est fermée."] =
        "A small window with what to do now, while the guide window is closed.",
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
    ["Rappels et infobulles"] = "Reminders and tooltips",
    ["En parlant au PNJ. Garde Maj enfoncée pour le faire à la main."] = "When you talk to the NPC. Hold Shift to do it by hand.",
    ["Rappel à la connexion"] = "Reminder on login",
    ["Par exemple : « 3 Writs prêts à rendre, 1 enveloppe à ouvrir »."] = "For example: \"3 Writs ready to turn in, 1 envelope to open\".",
    ["Détails dans l'infobulle des enveloppes"] = "Details in envelope tooltips",
    ["Réputation, coût, à qui la rendre, et si tu l'as déjà rendue."] = "Reputation, cost, who to hand it to, and whether you already turned it in.",
    ["Plan d'achat"] = "Shopping plan",
    ["Objectif de réputation"] = "Reputation goal",
    ["Le plan achète les Writs qu'il faut pour l'atteindre."] = "The plan buys the Writs needed to reach it.",
    ["Rang suivant"] = "Next standing",
    ["Masquer les zones trop hautes"] = "Hide zones above your level",
    ["Les zones au-dessus de ton niveau sortent du plan."] = "Zones above your level leave the plan.",
    ["Zones du plan"] = "Zones in the plan",
    ["dès le niv. %d"] = "from level %d",
    ["Pour écarter un seul Writ : clic droit dessus dans l'onglet « %s » de la fenêtre Writs."] =
        "To set aside a single Writ: right-click it in the Writs window's \"%s\" tab.",
    -- GPS
    ["Itinéraire"] = "Route",
    ["Envoyer les destinations à la flèche de Zygor"] = "Send destinations to Zygor's arrow",
    ["Envoyer les destinations à Shortest Path"] = "Send destinations to Shortest Path",
    ["Son trajet sur la carte, les vols et les bateaux avec leur départ."] = "Its route on the map, flights and boats with their departures.",
    ["Shortest Path Forever calcule le trajet (chemins, vols, bateaux avec l'heure de départ, portails) et le montre sur la carte avec sa flèche. La flèche de WL Helper, son chemin et ses pointillés se cachent pendant ce temps. Les étapes du guide, les repères de la carte et /way passent par lui."] =
        "Shortest Path Forever works out the trip (paths, flights, boats with their departure times, portals) and shows it on the map with its arrow. WL Helper's arrow, path and dots hide meanwhile. The guide's steps, map pins and /way go through it.",
    ["Pour ceux qui préfèrent la flèche de Zygor."] = "For those who prefer Zygor's arrow.",
    ["Zygor calcule le trajet et le montre avec sa flèche. La flèche de WL Helper, son chemin et ses pointillés se cachent pendant ce temps."] =
        "Zygor plans the trip and shows it with its arrow. WL Helper's arrow, path and dots step aside meanwhile.",
    ["Trajet"] = "Travel",
    ["Utiliser mes téléportations"] = "Use my teleports",
    ["Tes sorts de téléportation (mage, druide), quand ils sont prêts."] = "Your teleport spells (mage, druid), when they are ready.",
    ["Choisir le vol automatiquement"] = "Pick the flight automatically",
    ["Chez le maître de vol, le bon trajet est choisi pour toi."] = "At the flight master, the right route is picked for you.",
    ["Partager les horaires des zeppelins"] = "Share zeppelin and boat times",
    ["Avec la guilde, quand tu en prends un."] = "With the guild, when you take one.",
    ["Quand tu prends un zeppelin ou un bateau, son heure d'arrivée part à la guilde (un court message) : le GPS de chacun sait alors quand il repart. Les horaires reçus de la guilde servent toujours."] =
        "When you take a zeppelin or a boat, its arrival time goes to the guild (a short message): everyone's GPS then knows when it leaves again. Times received from the guild are always used.",
    ["Toujours si plus rapide"] = "Always when faster",
    ["Seulement si elle fait gagner au moins 3 min"] = "Only if it saves at least 3 min",
    ["Une heure de recharge : à garder pour un vrai gain."] = "An hour's cooldown: keep it for a real gain.",
    ["La pierre de foyer a une heure de recharge : par défaut, le GPS ne la propose que si elle fait gagner au moins 3 minutes sur le meilleur trajet sans elle. Le Rappel astral du chaman suit le même réglage ; les téléportations du mage, sans recharge, ne sont pas concernées. Le trajet écarté reste dans la bulle d'aide de la flèche (Alt-clic pour le prendre)."] =
        "The Hearthstone has an hour's cooldown: by default the GPS only suggests it when it saves at least 3 minutes over the best route without it. The shaman's Astral Recall follows the same setting; the mage's teleports, with no cooldown, are not affected. The route set aside stays in the arrow's tooltip (Alt-click to take it).",
    ["Points de vol connus"] = "Known flight paths",
    ["Ceux que ce personnage a déjà découverts."] = "Already discovered by this character.",
    ["Royaumes de l'Est %s · Kalimdor %s"] = "Eastern Kingdoms %s · Kalimdor %s",
    ["Ceux que ce personnage a déjà découverts, par continent. « ? » : aucune carte de maître de vol ouverte sur ce continent, ouvre-en une pour que le GPS connaisse tes vols."] =
        "Already discovered by this character, per continent. \"?\": no flight master's map opened on that continent yet, open one so the GPS learns your flight paths.",
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
    ["Le nettoyeur ne propose jamais un objet qui lance une quête. Pour libérer une place à la main, tape /wlh place."] =
        "The cleaner never offers an item that starts a quest. To free a slot by hand, type /wlh free.",
    -- Upgrades
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
    ["Poids utilisés (WL Helper Gear) : %s, niveau %d"] = "Weights used (WL Helper Gear): %s, level %d",
    ["Puissance des sorts"] = "Spell power", ["Dégâts des sorts (seuls)"] = "Spell damage only",
    ["Score de critique"] = "Crit rating", ["Score de toucher"] = "Hit rating", ["Score de hâte"] = "Haste rating",
    ["Score d'expertise"] = "Expertise rating", ["Score d'esquive"] = "Dodge rating", ["Score de parade"] = "Parry rating",
    ["Score de blocage"] = "Block rating", ["Dégâts de feu"] = "Fire damage", ["Dégâts de givre"] = "Frost damage",
    ["Dégâts d'ombre"] = "Shadow damage", ["Dégâts des arcanes"] = "Arcane damage", ["Dégâts de nature"] = "Nature damage",
    ["Dégâts du sacré"] = "Holy damage", ["Pénétration des sorts"] = "Spell penetration",
    ["Ces poids sont ceux de WL Helper Gear, qui juge tes objets : ta spé, ton niveau et ce que tu portes, en points de ta stat principale (puissance des sorts ; soins pour un soigneur, puissance d'attaque en physique, endurance pour un tank). Les plafonds sont comptés : le toucher ne vaut presque plus rien une fois le plafond atteint (5 % des sorts, 6 % en mêlée contre les monstres jusqu'à 2 niveaux au-dessus ; 17 % et 8 % en raid), la défense d'un tank jusqu'à son plafond."] =
        "These are WL Helper Gear's weights, the ones that judge your items: your spec, your level and what you wear, in points of your main stat (spell power; healing for a healer, attack power for physical specs, Stamina for a tank). Caps are counted: hit is worth almost nothing once capped (5% spells, 6% melee against mobs up to 2 levels above; 17% and 8% in raids), a tank's defense up to its cap.",
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
    -- T-80: the Orders alerts (the Commandes page)
    ["Un favori se connecte"] = "A favourite logs in",
    ["Une alerte quand un artisan de tes favoris arrive en ligne, au plus toutes les 30 min pour chacun."] =
        "An alert when one of your favourite crafters comes online, at most every 30 min for each.",
    ["Une recette surveillée est apprise"] = "A watched recipe is learned",
    ["Une alerte quand un membre de la guilde apprend une recette que tu surveilles, une fois par membre et par recette."] =
        "An alert when a guild member learns a recipe you watch, once per member and per recipe.",
    ["Son quand quelqu'un sait le faire"] = "Sound when someone can make it",
    ["Avec « Me prévenir quand quelqu'un sait le faire » sur la page Demande : un son avec la ligne du chat."] =
        "With \"Tell me when someone can make it\" on the Request page: a sound with the chat line.",
    -- game settings and EllesmereUI
    ["Le guide de quêtes, les Writs, le GPS et les outils de la guilde WaR LegenD."] =
        "The quest guide, the Writs window, the GPS and the WaR LegenD guild tools.",
    ["Ouvrir les réglages"] = "Open settings",
    ["Les réglages les plus utilisés. Tous les autres sont dans la fenêtre Réglages de WL Helper."] =
        "The most used settings. All the others are in WL Helper's Settings window.",
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
    -- one-line descriptions of the settings rows (UI width rework: the full text is in the tooltip)
    ["Déjà fait par un autre addon."] = "Another addon already does it.",
    ["Dans le monde ou depuis son portrait."] = "In the world or from their portrait.",
    ["Sur les messages « inv » du chat."] = "On \"inv\" messages in chat.",
    ["Sur un ennemi : ton tir à distance."] = "On an enemy: your ranged shot.",
    ["Sur un objet de tes sacs."] = "On an item in your bags.",
    ["À garder enfoncée avant le clic droit."] = "Hold it down, then right-click.",
    ["Automatique suit la langue du jeu."] = "Automatic follows the game's language.",
    ["Même fermé avant de te déconnecter."] = "Even if closed when you logged out.",
    ["Une alerte quand un de tes favoris arrive."] = "An alert when a favorite logs in.",
    ["Une alerte quand un membre l'apprend."] = "An alert when a member learns it.",
    ["Un son avec la ligne du chat."] = "A sound with the chat line.",
    ["Visibles dans « Qui a la clé ? »."] = "Shown in \"Who has the key?\".",
    ["Pour grouper. Rien d'autre n'est envoyé."] = "To group up. Nothing else is sent.",
    ["Un message et un son, dans un donjon."] = "A message and a sound, in a dungeon.",
    ["Posés tout seuls à chaque nouvelle étape."] = "Set on their own at each new step.",
    ["Une petite fenêtre, guide fermé."] = "A small window when the guide is closed.",
    ["Seulement les quêtes de ta route."] = "Only the quests on your route.",
    ["Quand il n'y a pas de récompense à choisir."] = "When there's no reward to pick.",
    ["Une fois, hors combat."] = "Once, out of combat.",
    ["La meilleure amélioration pour ta spé."] = "The best upgrade for your spec.",
    ["Masquées, elles sortent de la route."] = "Hidden, they leave the route.",
    ["Quand ton journal est presque plein."] = "When your quest log is almost full.",
    ["En parlant au PNJ. Maj : à la main."] = "When talking to the NPC. Shift: by hand.",
    ["Fenêtre Writs ouverte, prix de plus d'1 h."] = "Writs window open, prices over 1 h old.",
    ["Ex. « 3 Writs prêts à rendre »."] = "E.g. \"3 Writs ready to hand in\".",
    ["Réputation, coût, à qui la rendre."] = "Reputation, cost, who to hand it to.",
    ["Une ligne dans le chat, pour chaque perso."] = "A chat line, for each character.",
    ["Moyenne sur 60 jours, dans l'infobulle."] = "60-day average, in the tooltip.",
    ["Le plan achète de quoi l'atteindre."] = "The plan buys what it takes to get there.",
    ["Au-dessus de ton niveau : hors du plan."] = "Above your level: left out of the plan.",
    ["Mage, druide : quand elles sont prêtes."] = "Mage, druid: when they're ready.",
    ["Chez le maître de vol."] = "At the flight master.",
    ["La flèche contourne collines et murs."] = "The arrow goes around hills and walls.",
    ["Des points sur la carte du monde."] = "Dots on the world map.",
    ["Les mêmes points, autour de toi."] = "The same dots, around you.",
    ["Lieu, distance et temps, dans le monde."] = "Place, distance and time, in the world.",
    ["/way envoie le point au GPS de WL Helper."] = "/way sends the point to WL Helper's GPS.",
    ["Une fiche en arrivant dans une capitale."] = "A card when you arrive in a capital.",
    ["Sacs pleins : jeter l'objet le moins cher."] = "Bags full: drop the cheapest item.",
    ["Un autre addon les vend déjà."] = "Another addon already sells them.",
    ["Auto : l'arbre où tu as le plus de points."] = "Auto: the tree with the most points.",
    ["Toujours sur la première ligne."] = "Always on the first line.",
    ["Une ligne de plus dans les infobulles."] = "One more line in item tooltips.",
    ["L'infobulle dit quelle spé gagne."] = "The tooltip says which spec wins.",
    ["Le gain minimum pour la flèche."] = "The minimum gain for the arrow.",
    ["Le gain ou la perte pour ta spé."] = "The gain or loss for your spec.",
    ["Si ton addon d'équipement l'affiche déjà."] = "If your gear addon already shows it.",
    ["Le GPS te mène à l'étape suivante."] = "The GPS takes you to the next step.",
    ["Aussi fait par %s."] = "Also done by %s.",
    ["Fait par %s."] = "Done by %s.",
    -- key bindings (Settings > Quest guide > Raccourcis, T-83)
    ["Raccourcis"] = "Key bindings",
    ["Aucun"] = "None",
    ["Effacer"] = "Clear",
    ["Ouvrir"] = "Open",
    ["Appuie sur une touche... (Échap : annuler)"] = "Press a key... (Esc: cancel)",
    ["%s sert à « %s » : clique encore pour remplacer"] = "%s is used by “%s”: click again to replace",
    ["Indisponible en combat"] = "Not available in combat",
    ["Touches : %s"] = "Keys: %s",
    ["Aussi : %s"] = "Also: %s",
    ["Clic : choisir une touche."] = "Click: choose a key.",
    ["Clic : changer la touche."] = "Click: change the key.",
    ["Enlève les touches de cette action."] = "Removes this action's keys.",
    ["Tout régler dans le jeu"] = "Set everything in the game",
    ["La fenêtre des raccourcis du jeu."] = "The game's key bindings window.",
    ["Ouvre les raccourcis du jeu (section AddOns)."] = "Opens the game's key bindings (AddOns section).",
})

-- ---------------------------------------------------------------- settings access

local function Writs() return WLWritsDB or {} end
local function Gps() local db = Writs(); db.gpsOpts = db.gpsOpts or {}; return db.gpsOpts end
local function Comfort() local db = Writs(); db.comfort = db.comfort or {}; return db.comfort end
local function Guide() WLDTDB = WLDTDB or {}; return WLDTDB end

local function ZygorPresent() return (ZGV and ZGV.Pointer) and true or false end
local function SPFPresent()
    local s = rawget(_G, "ShortestPathForever")
    return (type(s) == "table" and type(s.API) == "table" and s.API.Navigate) and true or false
end
-- what the GPS page was built with: Zygor and Shortest Path can finish loading after it
local function Providers() return (ZygorPresent() and "z" or "") .. (SPFPresent() and "s" or "") end
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
-- which GPS guides: the trip under way follows at once (GPS.SetProvider)
local function SetProvider(v)
    local G = ns.WP and ns.WP.GPS
    if G and G.SetProvider then G.SetProvider(v) else Gps().provider = v end
    Gps().spfAsked = true
    ApplyLook()
end

-- "1,5" in French, "1.5" in English
local function Decimal(v)
    local s = string.format("%.2f", v)
    if not (ns.English and ns.English()) then s = s:gsub("%.", ",") end
    return s
end

-- ---------------------------------------------------------------- layout constants

-- DESIGN 3.1 / 3.20: the workspace size rule (ns.WinSize "workspace": 70 % x 78 % of the screen,
-- 900 x 620 at least, 1400 x 900 at most), the same on every page (the nav would jump otherwise).
-- The grip at the bottom right resizes it (size saved in WLWritsDB.hubPosSize, double-click: back
-- to the default); a new screen size or UI scale re-applies the rule (Writs/Style.lua). The pages
-- lay out again at the new width (OnResize), nothing is rebuilt.
local NAV_W = 199                          -- the nav, then its 1 px rule
local INSET = 16                           -- one left edge, one right edge
local NAV_ITEM_H, NAV_GAP, NAV_TOP = 32, 2, 12 + 28 + 12
local HEADER_H = 44
local PAGE_HEAD_H = 60                     -- a page's fixed header (title, sentence), its rule under it
local NOTE_W = 480                         -- a running sentence never runs wider (4.2)
local WIN_W, WIN_H, CONTENT_W, CARD_W
local win, body, current                   -- the window, its nav and pages, the page shown

-- The window's size: what it has once built (dragged or saved), else the rule's default. A size the
-- client cannot give (secret, or under the rule's minimum) reads as the default.
local function Dims()
    local defW, defH, minW, minH = root.WinSize("workspace")
    local w, h = defW, defH
    if win then
        local cw, ch = num(win:GetWidth()), num(win:GetHeight())
        if cw and cw >= minW - 0.5 then w = math.floor(cw + 0.5) end
        if ch and ch >= minH - 0.5 then h = math.floor(ch + 0.5) end
    end
    WIN_W, WIN_H = w, h
    CONTENT_W = WIN_W - NAV_W - 1          -- the content column, right of the nav and its rule
    CARD_W = CONTENT_W - 2 * INSET         -- a settings card, Home's activity lines
end
local function HubW() Dims(); return WIN_W end
local function HubH() Dims(); return WIN_H end
Dims()
ns.WP = ns.WP or {}
ns.WP.HubW, ns.WP.HubH = HubW, HubH
-- -> the content column and the card width the pages use now (the offline tests)
ns.WP.HubDims = function() return CONTENT_W, CARD_W, WIN_W, WIN_H end

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
    teleport = "teleportation portail mage", zygor = "guide pointeur fleche itineraire", shortest = "itineraire bateau vol trajet", tooltip = "infobulle",
    raccourci = "touche keybind binding bind", touche = "raccourci keybind binding", keybind = "raccourci touche binding",
    infobulle = "tooltip", writ = "enveloppe comptoir", minimap = "carte bouton", langue = "language english francais",
    language = "langue", sac = "bags clean nettoyeur", bags = "sacs nettoyeur", reglage = "settings options",
    commande = "orders artisan metier", orders = "commandes", guilde = "guild classement pvp",
    groupe = "lfg events evenement donjon raid", lfg = "groupes events", spe = "spec talents poids amelioration",
    spec = "spe talents", stuff = "ameliorations upgrades equipement", son = "sound alerte", alerte = "rare sound son",
    caisse = "crates faveur favor", faveur = "favor caisses", hv = "hotel des ventes auction scan prix",
    prix = "price scan hv", police = "font", font = "police", comptoir = "Writs trading post",
    invite = "inviter inv clic", inviter = "invite inv", tir = "shoot tirer", shoot = "tirer tir",
}

-- hint: the row's one line (shown under the result); long: its tooltip text, searched too
local function Register(p, row, label, hint, long)
    local section = p.section or ""
    local text = table.concat({ label or "", OtherLanguage(label), hint or "", OtherLanguage(hint),
        long or "", OtherLanguage(long),
        section, OtherLanguage(section), p.pageLabel or "", OtherLanguage(p.pageLabel) }, " ")
    INDEX[#INDEX + 1] = { page = p.key, pageLabel = p.pageLabel, pageIcon = p.pageIcon, section = section,
        label = label, hint = hint, row = row,
        labelFold = Fold((label or "") .. " " .. OtherLanguage(label)), all = Fold(text) }
end

-- ---------------------------------------------------------------- pages
-- A page fills the content column: a fixed header (title 16 fg at 16,-16, one sentence 11 muted
-- under it, cut with the full text in its tooltip, a 1 px rule at y=-60), then a scroll area from
-- y=-61 whose child is the page itself. Its items (section headers, settings cards, notes, module
-- card, free blocks) are stacked by p:Layout(), which measures every text at its width and sets
-- the scrolled height. The window never changes height for a page.

local function NewPage(parent, def)
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetAllPoints()
    holder:Hide()
    local head = CreateFrame("Frame", nil, holder)
    head:SetPoint("TOPLEFT", 0, 0); head:SetPoint("TOPRIGHT", 0, 0); head:SetHeight(PAGE_HEAD_H)
    head:EnableMouse(true)
    head.title = S.Text(head, F.title, T.fg, true)
    head.title:SetJustifyH("LEFT")
    head.title:SetPoint("TOPLEFT", INSET, -16); head.title:SetPoint("RIGHT", -INSET, 0)
    head.title:SetText(L(def.label))
    S.ClampLabel(head.title, nil, head)
    head.desc = S.Text(head, F.meta, T.muted)
    head.desc:SetJustifyH("LEFT")
    head.desc:SetPoint("TOPLEFT", head.title, "BOTTOMLEFT", 0, -2); head.desc:SetPoint("RIGHT", -INSET, 0)
    head.desc:SetText(L(def.desc))
    S.ClampLabel(head.desc, nil, head)
    local rule = S.Rule(holder)
    rule:SetPoint("TOPLEFT", 0, -PAGE_HEAD_H); rule:SetPoint("TOPRIGHT", 0, -PAGE_HEAD_H)
    local sa = S.ScrollArea(holder)
    sa:SetPoint("TOPLEFT", 0, -(PAGE_HEAD_H + 1)); sa:SetPoint("BOTTOMRIGHT", 0, 0)
    local p = sa.child
    p:SetWidth(CONTENT_W)
    p.sa, p.holder, p.head = sa, holder, head
    p.items, p.controls, p.anchors = {}, {}, {}
    function p:Show() holder:Show(); sa:Show(); sa:ScrollTo(0, true) end
    function p:Hide() holder:Hide() end
    function p:SetShown(v) if v then self:Show() else holder:Hide() end end
    function p:IsShown() return holder:IsShown() end
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
            if it.kind ~= "card" then it.frame.pageY = y end
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
    p.anchors[text] = h   -- WP.OpenHub(page, anchor) scrolls here
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
        -- a running sentence stays readable on a wide page (4.2): 480 at most
        local h = root.FitText(fs, 0, math.min(width, NOTE_W), holder)
        h = math.max(h, size and size + 2 or 13)
        holder:SetHeight(h)
        return h
    end, "note", 8)
    return fs
end

-- The current settings card of the page (a new one after a section header or a note): an
-- S.SettingsCard, its rows in 2 columns from 652 px of card, 3 from 984 (ns.GRID.settings).
-- grid: another standard grid (the Writs zones: ns.GRID.toggles).
local function Card(p, grid)
    if p.card and p.card.wlGridName == grid then return p.card end
    local card = S.SettingsCard(p, grid and { grid = root.GRID[grid] } or nil)
    card.wlGridName = grid
    p.card = card
    Add(p, card, function(width, top)
        local h = card:Fit(width)
        -- where each row sits on the page: the search scrolls to it, the anchors light it
        for _, c in ipairs(card.grid.cells) do c.frame.pageY = top + c.y end
        return h
    end, "card", 0)
    return card
end

-- A settings row (3.18, S.SettingRow): label 13 fg, one line of description 11 muted (cut, its
-- full text in the tooltip), the control at the right; long: more text for the tooltip only.
-- opts.wide: the row takes a whole line of the card (a wide control goes under the texts).
-- opts.grid: the card's grid (Card).
local function Row(p, label, desc, long, opts)
    opts = opts or {}
    local card = Card(p, opts.grid)
    local row = card:AddRow({ label = label, desc = desc, long = long, wide = opts.wide })
    Register(p, row, label, (desc and desc ~= "") and desc or long, (desc and desc ~= "") and long or nil)
    return row
end

-- Gives the row its control (S.SettingRow places it at the right); it is re-synced each time the
-- page shows.
local function Place(p, row, control)
    row.control = control
    if control.GetParent and control:GetParent() ~= row and control.SetParent then control:SetParent(row) end
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

-- A segmented control; S.SettingRow turns it into a dropdown when its labels would leave the
-- row's texts less than 120 px (a paired row) or the row's width (a wide row). The dropdown is as
-- wide as its longest choice and its list opens above the page (LiftList).
-- wide: the row takes a whole line (3 or more long choices).
local function Choice(p, row, options, get, set, wide)
    local seg = S.Segmented(row, options, get, set)
    if wide then row.wide = true end
    local setMax = seg.SetMaxWidth
    seg.SetMaxWidth = function(self, w)
        setMax(self, w)
        local d = self.dropdown
        if d and d:IsShown() then
            local longest = 0
            for _, b in ipairs(self.buttons or {}) do
                longest = math.max(longest, root.TextWidth(b.label))
            end
            -- the button's own measure (label + 24, chevron and its gap + 12): the longest choice fits
            local cap = math.max(120, w or 200)
            d:SetWidth(math.max(120, math.min(cap, math.ceil(longest) + 24 + 12)))
            self:SetWidth(num(d:GetWidth()) or 120)
            if not d.wlLifted then d.wlLifted = true; LiftList(d, p.sa) end
        end
    end
    return Place(p, row, seg)
end

-- A switch row: the whole row is the click target; its tooltip says what the click does.
-- opts: as Row (grid, wide).
local function SwitchRow(p, label, get, set, desc, long, opts)
    opts = opts or {}
    local card = Card(p, opts.grid)
    local row = card:AddRow({ label = label, desc = desc, long = long, control = "switch", get = get, set = set,
        wide = opts.wide })
    Register(p, row, label, (desc and desc ~= "") and desc or long, (desc and desc ~= "") and long or nil)
    local sw = row.switch
    p.controls[#p.controls + 1] = sw
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
    local row = Row(p, label, nil, nil, { wide = true })
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
-- on the Home rows); Home is the HD house; General is the HD settings gear, as everywhere else
-- Settings opens; GPS is the addon's GPS arrow, as on the HUD and in the minimap menu; About is the
-- neutral "info" glyph (the question mark read as Help).
-- An icon is a painted path or { hd = glyph name or path }.
-- group: the activity (WP.HUB_GROUPS) the page sits under in the nav; "settings" for the bottom
-- block; nil for Home (first, alone). The keys never change: /wlh, the gears and the tests use them.
local MI = ns.WP.MODULE_ICON or {}
local PAGES = {
    { key = "home",     label = "Accueil",       icon = { hd = "home" },                              desc = "Où tu en es, et tout ce que WL Helper peut ouvrir." },
    { key = "welcome",  label = "Bienvenue",     icon = { hd = "flag" },                              desc = "Tout régler pas à pas, et la visite guidée." },
    { key = "dungeons", label = "Guide de quêtes", group = "quests", icon = MI.dungeons or "Interface\\Icons\\INV_Misc_Map_01", desc = "La flèche, les alertes et les quêtes que montre le guide." },
    { key = "gps",      label = "GPS",           group = "travel", icon = { hd = root.ARROW },        desc = "Itinéraire, vols, téléportations et flèche." },
    { key = "comptoir", label = "Writs",         group = "items", icon = MI.writs or "Interface\\Icons\\INV_Letter_15", desc = "Remise des Writs, rappels, objectif et zones." },
    { key = "bags",     label = "Sacs",          group = "items", icon = MI.bags or "Interface\\Icons\\INV_Misc_Bag_08", desc = "Place dans les sacs et vente des objets gris." },
    { key = "upgrades", label = "Améliorations", group = "items", icon = MI.upgrades or { hd = "arrow_up", color = T.ok }, desc = "Calcul, spé et affichage des améliorations." },
    { key = "orders",   label = "Commandes",     group = "items", icon = MI.orders or "Interface\\Icons\\Trade_BlackSmithing", desc = "Les alertes des commandes : favoris, recettes surveillées, son." },
    { key = "guild",    label = "Guilde",        group = "guild", icon = MI.guild or "Interface\\Icons\\INV_BannerPVP_01", desc = "Ce que tu partages avec la guilde." },
    { key = "groups",   label = "Groupes",       group = "guild", icon = { hd = "group" },             desc = "Messages, chuchotements et notes de Trouver un groupe." },
    { key = "general",  label = "Général",       group = "settings", icon = { hd = "gear" },          desc = "Modules, clics, langue et fenêtres." },
    { key = "about",    label = "À propos",      group = "settings", icon = { hd = "info" },          desc = "Version, crédits, contact et commandes du chat." },
}
local PaintIcon = S.PaintIcon

-- What each module does, written for the Settings rows and the module card of its page.
local MODULE_DESC = {
    dungeons = "Le guide des quêtes de donjon, de raid et de classe, avec la route et la flèche.",
    writs = "Les Writs à faire, la liste d'achat et la remise automatique.",
    bags = "Repère les objets de quête qui ne servent plus et libère de la place.",
    orders = "Demande un objet à un artisan de la guilde, ou prends les commandes des autres.",
    guild = "Toute la guilde, le classement PvP et les quêtes en commun.",
    events = "Les événements de la guilde et les groupes du moment.",
    upgrades = "Une flèche verte sur les objets meilleurs que ceux que tu portes.",
    keys = "Tes clés et accès de donjons et de raids, et qui les a dans la guilde.",
    triage = "Les quêtes à abandonner quand ton journal est presque plein.",
}
local MODULE_ICON = {
    dungeons = MI.dungeons or "Interface\\Icons\\INV_Misc_Map_01", writs = MI.writs or "Interface\\Icons\\INV_Letter_15",
    bags = MI.bags or "Interface\\Icons\\INV_Misc_Bag_08", upgrades = MI.upgrades or { hd = "arrow_up", color = T.ok },
    orders = MI.orders or "Interface\\Icons\\Trade_BlackSmithing", guild = MI.guild or "Interface\\Icons\\INV_BannerPVP_01",
}

-- A module's name, the one its window and its Home card show: "Groupes" (as WP.MODULES),
-- "Writs" (WP.MODULES says "Writs & Favor" for the trading post) and "Passeport des clés" (Home,
-- Welcome and the tour: WP.MODULES says "Clés").
local function ModLabel(m)
    if m.key == "events" then return L("Groupes") elseif m.key == "writs" then return L("Writs")
    elseif m.key == "keys" then return L("Passeport des clés") end
    return L(m.label)
end
local function ModDesc(m)
    return MODULE_DESC[m.key] and L(MODULE_DESC[m.key]) or L(m.hint or "")
end

local Rebuild   -- defined with the window: rebuilds every page after a language change
local RebuildPage   -- defined with the window: rebuilds one settings page (a new spec, a new bracket)
local Relayout  -- defined with the window: re-measures the page shown and fits the window
local Resized   -- defined with the window: the window got a new size

local BUILD = {}
local CommandTable   -- defined with the About page

-- the Groups page: Writs/FinderPeople.lua draws it (templates and switches of Trouver un groupe)
-- A page drawn by another file gets the content width at Build; p.hubWidth is the width now
-- (set before each p:Layout). A page that follows p.hubWidth itself sets p.wlResizes; any other is
-- built again at the new width once the size stops changing (ApplyWidths).
function BUILD.groups(p)
    if ns.WP.GroupsPage then ns.WP.GroupsPage.Build(p, CONTENT_W) end
    p.builtW = CONTENT_W
end

-- the Welcome page: Writs/Tour.lua draws it (the checklist of Writs/Hub.lua and the guided tour)
function BUILD.welcome(p)
    if ns.WP.WelcomePage then ns.WP.WelcomePage.Build(p, CONTENT_W) end
    p.builtW = CONTENT_W
end

-- The modules: one tile each (painted icon 28, name, switch; what it does in the tooltip) in the
-- module tiles grid (ns.GRID.moduleTiles: 3 a line at 668-724 px, 4 from 860). The whole tile is
-- the click target.
local TILE_H = 52
local function ModuleTiles(p)
    p.card = nil
    local holder = CreateFrame("Frame", nil, p)
    holder.tiles = {}
    holder.grid = root.Grid()
    p.moduleTiles = holder
    for _, m in ipairs(ns.WP.MODULES) do
        local t = CreateFrame("Frame", nil, holder)
        t.wlOwned = true
        t.key = m.key
        t.bg = S.Solid(t, "BACKGROUND", T.cardFill); t.bg:SetAllPoints()
        S.Border(t, T.cardEdge)
        t.hl = S.Solid(t, "BACKGROUND", T.hoverFill); t.hl:SetAllPoints(); t.hl:SetAlpha(0)
        t.iconFrame = CreateFrame("Frame", nil, t)
        t.iconFrame:SetSize(28, 28)
        t.icon = t.iconFrame:CreateTexture(nil, "ARTWORK"); t.icon:SetAllPoints()
        local icon = MODULE_ICON[m.key] or (ns.WP.MODULE_ICON or {})[m.key] or { hd = "gear" }
        if PaintIcon(t.icon, icon, T.fg) then
            t.icon:ClearAllPoints(); t.icon:SetPoint("TOPLEFT", 5, -5); t.icon:SetPoint("BOTTOMRIGHT", -5, 5)
        end
        S.Border(t.iconFrame, T.cardEdge)
        t.label = S.Text(t, F.body, T.fg)
        t.label:SetJustifyH("LEFT"); t.label:SetJustifyV("MIDDLE")
        t.label:SetText(ModLabel(m))
        local get = function() return ns.WP.ModuleOn(m.key) end
        t.switch = S.Switch(t, get, function(v) ns.WP.SetModule(m.key, v) end)
        t.switch:AttachRow(t)
        t:EnableMouse(true)
        local function Tip()
            S.Tip(t, { ModLabel(m), ModDesc(m), get() and L("Clic : désactiver") or L("Clic : activer") })
        end
        local function Over(f) local ok, v = pcall(f.IsMouseOver, f); return ok and v end
        local function Enter() root.Tween(t.hl, num(t.hl:GetAlpha()) or 0, 1, 0.10, function(v) t.hl:SetAlpha(v) end); Tip() end
        local function Leave() root.Tween(t.hl, num(t.hl:GetAlpha()) or 0, 0, 0.10, function(v) t.hl:SetAlpha(v) end); S.HideTip() end
        t:HookScript("OnEnter", Enter)
        t:HookScript("OnLeave", function() if not Over(t.switch) then Leave() end end)
        t.switch:HookScript("OnEnter", Enter)
        t.switch:HookScript("OnLeave", function() if not Over(t) then Leave() end end)
        t.switch:HookScript("OnClick", function()
            local ok, owner = pcall(function() return GameTooltip:IsShown() and GameTooltip:GetOwner() end)
            if ok and owner == t then Tip() end
        end)
        function t:Update()
            self.switch:Update()
            self.iconFrame:SetAlpha(get() and 1 or 0.5)
        end
        -- name between the icon and the switch: two lines when it does not fit (never cut)
        function t:Fit(width)
            self.iconFrame:ClearAllPoints(); self.iconFrame:SetPoint("LEFT", self, "LEFT", 12, 0)
            self.switch:ClearAllPoints(); self.switch:SetPoint("RIGHT", self, "RIGHT", -12, 0)
            local textW = math.max(40, width - 12 - 28 - 10 - 12 - 40 - 12)
            self.label:ClearAllPoints(); self.label:SetPoint("LEFT", self, "LEFT", 12 + 28 + 10, 0)
            local lh = math.max(15, root.FitText(self.label, 2, textW, self))
            self.textW = textW
            local h = math.max(TILE_H, math.ceil(12 + lh + 12))
            self:SetHeight(h)
            return h
        end
        holder.tiles[#holder.tiles + 1] = t
        p.controls[#p.controls + 1] = t
        Register(p, t, ModLabel(m), ModDesc(m))
    end
    Add(p, holder, function(width, top)
        local g = holder.grid
        local go = root.GRID.moduleTiles
        g:Begin(holder, 0, 0, width, { minW = go.minW, gap = go.gap, rowGap = go.rowGap, maxCols = go.maxCols,
            minPx = go.minPx, equal = true })
        for _, t in ipairs(holder.tiles) do g:Add(t, function(f, w) return f:Fit(w) end) end
        local h = math.max(1, (g:End()))
        for _, c in ipairs(g.cells) do c.frame.pageY = top + c.y end
        holder:SetHeight(h)
        return h
    end, "tiles", 0)
    return holder
end

function BUILD.general(p)
    Section(p, L("Modules"))
    ModuleTiles(p)
    Note(p, L("Le GPS reste toujours allumé : les autres modules s'en servent. Un module rallumé revient tout de suite, sans /reload."))

    if ns.WP.ClicksDB then
        Section(p, L("Clics"))
        local function Clicks() return ns.WP.ClicksDB() end
        local function setClick(k) return function(v) Clicks()[k] = v; if ns.WP.ApplyClicks then ns.WP.ApplyClicks() end end end
        local taken = L("Un autre addon le fait déjà : ce réglage reste sans effet.")
        local takenShort = L("Déjà fait par un autre addon.")
        local inviteBy = ns.WP.ClickOwner and ns.WP.ClickOwner("invite")
        local shootBy = ns.WP.ClickOwner and ns.WP.ClickOwner("shoot")
        local function Two(by, short, long) if by then return takenShort, taken end return L(short), long and L(long) or nil end
        SwitchRow(p, L("Alt-clic sur un nom dans le chat"), function() return Clicks().chat end, setClick("chat"),
            Two(inviteBy, "Invite ce joueur dans ton groupe."))
        SwitchRow(p, L("Alt-clic sur un joueur ou un portrait"), function() return Clicks().world end, setClick("world"),
            Two(inviteBy, "Dans le monde ou depuis son portrait.", "Invite le joueur, dans le monde ou depuis son portrait."))
        SwitchRow(p, L("Lien [Inviter] dans le chat"), function() return Clicks().link end, setClick("link"),
            Two(inviteBy, "Sur les messages « inv » du chat.", "Ajouté aux messages qui demandent une invitation, comme « inv »."))
        SwitchRow(p, L("Clic droit pour tirer"), function() return Clicks().shoot end, setClick("shoot"),
            Two(shootBy, "Sur un ennemi : ton tir à distance.", "Sur un ennemi, lance ton tir à distance : arc, fusil, arbalète, arme de jet ou baguette."))
        local mrow = Row(p, L("Touche pour tirer"), L("À garder enfoncée avant le clic droit."),
            L("Garde-la enfoncée, puis fais un clic droit sur l'ennemi. Avec « Aucune », le clic droit seul tire : pratique avec une baguette."))
        -- OfferWand first, so the welcome step never overrides the key chosen here
        Choice(p, mrow, ns.WP.ShootKeys(), function() return Clicks().shootMod end, function(v)
            if ns.WP.OfferWand then ns.WP.OfferWand() end
            setClick("shootMod")(v)
        end, true)
        local AC = ns.WP.AltClick
        if AC and AC.On and AC.SetOn then
            SwitchRow(p, L("Alt-clic pour désenchanter / crocheter"), function() return AC.On() end, function(v) AC.SetOn(v) end,
                L("Sur un objet de tes sacs."),
                L("Alt + clic gauche sur un objet de tes sacs : désenchanter (enchanteur), crocheter un coffret (voleur), déchiffrer un parchemin (mage)."))
        end
    end

    Section(p, L("Langue"))
    local row = Row(p, L("Langue de l'addon"), L("Automatique suit la langue du jeu."),
        L("Automatique suit la langue du jeu. Les fenêtres déjà ouvertes changent après un /reload."))
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
    end, true)

    -- the font: the game's own (sure to show everywhere) or EllesmereUI's when it is installed
    if root.IsLoaded and root.IsLoaded("EllesmereUI") then
        Section(p, L("Police"))
        local frow = Row(p, L("Police des textes"), nil, L("Si des textes restent vides, reviens à celle du jeu."))
        Choice(p, frow, { { "game", L("Police du jeu") }, { "eui", "EllesmereUI" } },
            function() return WLWritsDB.font == "eui" and "eui" or "game" end,
            function(v) WLWritsDB.font = v; if root.ApplyLooks then root.ApplyLooks() end end, true)
    end

    Section(p, L("Fenêtres"))
    SwitchRow(p, L("Bouton de la minimap"), function() return not Guide().hideMinimap end, SetMinimap,
        L("Ouvre l'Accueil de WL Helper d'un clic."))
    SwitchRow(p, L("Rouvrir le guide à la connexion"), function() return Guide().reopenGuide == true end,
        function(v) Guide().reopenGuide = v end, L("Même fermé avant de te déconnecter."),
        L("Même si tu l'avais fermé avant de te déconnecter."))
end

-- the Orders page (T-80 alerts): the first two are also on my crafter profile
function BUILD.orders(p)
    if not ns.WP.Orders then return end
    Section(p, L("Alertes"))
    SwitchRow(p, L("Un favori se connecte"), function() return Writs().ordersAlertFav ~= false end,
        function(v) Writs().ordersAlertFav = v and true or false end,
        L("Une alerte quand un de tes favoris arrive."),
        L("Une alerte quand un artisan de tes favoris arrive en ligne, au plus toutes les 30 min pour chacun."))
    SwitchRow(p, L("Une recette surveillée est apprise"), function() return Writs().ordersAlertWatch ~= false end,
        function(v) Writs().ordersAlertWatch = v and true or false end,
        L("Une alerte quand un membre l'apprend."),
        L("Une alerte quand un membre de la guilde apprend une recette que tu surveilles, une fois par membre et par recette."))
    SwitchRow(p, L("Son quand quelqu'un sait le faire"), function() return Writs().ordersKnownSound ~= false end,
        function(v) Writs().ordersKnownSound = v and true or false end,
        L("Un son avec la ligne du chat."),
        L("Avec « Me prévenir quand quelqu'un sait le faire » sur la page Demande : un son avec la ligne du chat."))
    Note(p, L("Les deux alertes se règlent aussi sur ta fiche d'artisan, dans la fenêtre Commandes."))
end

-- the Guild page: what this copy tells the guild's copies, each one can be kept private
function BUILD.guild(p)
    local K, Sh = ns.WP.Keys, ns.WP.Shared
    if not ((K and K.ShareOn) or (Sh and Sh.GetShare)) then return end
    Section(p, L("Partage"))
    if K and K.ShareOn and K.SetShare then
        SwitchRow(p, L("Partager mes clés avec la guilde"), function() return K.ShareOn() end, function(v) K.SetShare(v) end,
            L("Visibles dans « Qui a la clé ? »."),
            L("Les membres qui ont WL Helper voient quelles clés tu as, dans l'onglet Qui a la clé ? de la guilde."))
    end
    if Sh and Sh.GetShare and Sh.SetShare then
        SwitchRow(p, L("Partager mes quêtes de donjon"), function() return Sh.GetShare() end, function(v) Sh.SetShare(v) end,
            L("Pour grouper. Rien d'autre n'est envoyé."),
            L("Les membres de la guilde qui ont WL Helper voient quelles quêtes de donjon tu as, pour grouper. Rien d'autre n'est envoyé."))
    end
end

-- ---------------------------------------------------------------- key bindings (T-83)
-- The guide's keys (Bindings.xml), set from here rather than the game's menu. One row per binding:
-- its name, a button with its key ("Aucun" without one) and "Effacer". A click on the key waits for
-- the next key (with Alt-, Ctrl-, Maj-; mouse buttons 4 and 5 too; Échap cancels); a key another
-- action uses is offered on the row's line first, a second click within 5 s takes it. A new key
-- replaces the action's old ones. Bindings are protected: out of combat only (the buttons are
-- disabled in combat). The rows re-read the keys on UPDATE_BINDINGS while the page shows.
local BINDINGS = { "WLDT_TOGGLE", "WLDT_PICK", "WLDT_NEXT", "WLDT_PREV", "WLDT_POINTS", "WLDT_ARROW", "WLDT_TARGET", "WLDT_ITEM" }
ns.KEY_BINDINGS = BINDINGS
local MODKEYS = { LSHIFT = true, RSHIFT = true, LCTRL = true, RCTRL = true, LALT = true, RALT = true,
    LMETA = true, RMETA = true, SHIFT = true, CTRL = true, ALT = true, META = true }
local CONFIRM_S = 5
local keyCombat = false          -- PLAYER_REGEN_DISABLED comes before InCombatLockdown() turns true
local keyCapture                 -- the one frame that listens for the key

local function KeysLocked() return keyCombat or ((InCombatLockdown and InCombatLockdown()) and true or false) end

-- the keys of a binding (strings, in the game's order)
local function BindingKeys(name)
    local out = {}
    if type(GetBindingKey) ~= "function" then return out end
    local t = { pcall(GetBindingKey, name) }
    if not t[1] then return out end
    for i = 2, 3 do
        local k = t[i]
        if type(k) == "string" and k ~= "" and not secret(k) then out[#out + 1] = k end
    end
    return out
end

-- what a key reads like ("Maj-F" on a French client), the key itself when the game says nothing
local function KeyLabel(key)
    if type(GetBindingText) == "function" then
        local ok, t = pcall(GetBindingText, key)
        if ok and type(t) == "string" and t ~= "" and not secret(t) then return t end
    end
    return key
end

-- the name of a binding command, from its BINDING_NAME_ global
local function ActionLabel(action)
    local t = rawget(_G, "BINDING_NAME_" .. tostring(action))
    if type(t) == "string" and t ~= "" then return t end
    return tostring(action)
end

local function KeyOwner(key)
    if type(GetBindingAction) ~= "function" then return nil end
    local ok, a = pcall(GetBindingAction, key)
    if ok and type(a) == "string" and a ~= "" and not secret(a) then return a end
    return nil
end

local function SaveKeys()
    if type(SaveBindings) ~= "function" then return end
    local set = 1
    if type(GetCurrentBindingSet) == "function" then
        local ok, s = pcall(GetCurrentBindingSet)
        if ok and num(s) then set = s end
    end
    pcall(SaveBindings, set)
end

-- the key pressed with its modifiers, in the game's order (ALT-CTRL-SHIFT-F)
local function WithModifiers(key)
    local p = ""
    if IsAltKeyDown and IsAltKeyDown() then p = p .. "ALT-" end
    if IsControlKeyDown and IsControlKeyDown() then p = p .. "CTRL-" end
    if IsShiftKeyDown and IsShiftKeyDown() then p = p .. "SHIFT-" end
    return p .. key
end

-- A screen-wide frame that takes the next key or mouse button for one row (its target).
local function KeyCapture()
    if keyCapture then return keyCapture end
    local c = CreateFrame("Frame", nil, UIParent)
    c:SetAllPoints(UIParent)
    c:SetFrameStrata("FULLSCREEN_DIALOG")
    c:EnableMouse(true)
    c:Hide()
    c:SetScript("OnKeyDown", function(self, key)
        local t = self.target
        if t then t:OnKey(key) end
    end)
    c:SetScript("OnMouseDown", function(self, button)
        local t = self.target
        if not t then return end
        if button == "Button4" or button == "Button5" then t:OnKey(string.upper(button))
        else t:Cancel() end
    end)
    function c:Stop()
        self.target = nil
        pcall(self.EnableKeyboard, self, false)
        self.wlKeys = false
        self:Hide()
    end
    -- hidden any other way (the UI reloaded, a parent hidden): it never keeps the keyboard
    c:SetScript("OnHide", function(self)
        local t = self.target
        self.target = nil
        pcall(self.EnableKeyboard, self, false)
        self.wlKeys = false
        if t and t.Cancel then t:Cancel() end
    end)
    keyCapture = c; ns.keyCapture = c   -- the tests drive it
    return c
end

-- One binding's control: [key] [Effacer], right-aligned in its row.
local function BindingControl(p, row, name)
    local holder = CreateFrame("Frame", nil, row)
    holder:SetHeight(24)
    holder.name = name
    local st = {}            -- state: nil, "capture" or "conflict" (key, action, t, token)
    holder.st = st
    local keyB, clr

    local function Sync() holder:Sync() end
    local function Reset() st.state, st.key, st.action, st.t, st.token = nil, nil, nil, nil, nil end

    -- binds key to this action (its old keys freed), saved in the current binding set
    local function Apply(key)
        Reset()
        if KeysLocked() or type(SetBinding) ~= "function" then Sync() return end
        for _, old in ipairs(BindingKeys(name)) do
            if old ~= key then pcall(SetBinding, old) end
        end
        pcall(SetBinding, key, name)
        SaveKeys()
        Sync()
    end

    function holder:Cancel()
        local c = keyCapture
        if c and c.target == self then c:Stop() end
        Reset()
        Sync()
    end

    function holder:OnKey(key)
        if type(key) ~= "string" or key == "" then return end
        if key == "ESCAPE" then self:Cancel() return end
        if MODKEYS[key] then return end            -- a lone modifier: wait for the key
        local c = keyCapture
        if c and c.target == self then c:Stop() end
        if KeysLocked() then Reset(); Sync() return end
        local full = WithModifiers(key)
        local owner = KeyOwner(full)
        if owner == name then Reset(); Sync() return end   -- already this action's key
        if owner then
            local token = {}
            st.state, st.key, st.action, st.t, st.token = "conflict", full, owner, GetTime(), token
            C_Timer.After(CONFIRM_S, function()
                if st.token == token then Reset(); Sync() end
            end)
            Sync()
            return
        end
        Apply(full)
    end

    local function Start()
        local c = KeyCapture()
        if c.target and c.target ~= holder then c.target:Cancel() end
        Reset()
        st.state = "capture"
        -- a focused edit box (the Hub's search) would take the key before the capture does
        if type(GetCurrentKeyBoardFocus) == "function" then
            local okF, f = pcall(GetCurrentKeyBoardFocus)
            if okF and type(f) == "table" and f.ClearFocus then pcall(f.ClearFocus, f) end
        end
        c.target = holder
        c:Show()
        if c.Raise then pcall(c.Raise, c) end
        -- above the Hub (FULLSCREEN_DIALOG) and not passed on: Échap cancels here, the game's
        -- Escape (UISpecialFrames) never sees it and the Hub stays open
        if c.SetPropagateKeyboardInput then pcall(c.SetPropagateKeyboardInput, c, false) end
        pcall(c.EnableKeyboard, c, true)
        c.wlKeys = true
        Sync()
    end

    local function KeyClick()
        if KeysLocked() then return end
        if st.state == "conflict" then
            if GetTime() - (st.t or 0) <= CONFIRM_S then Apply(st.key) else Reset(); Sync() end
            return
        end
        if st.state == "capture" then holder:Cancel() return end
        Start()
    end

    local function Clear()
        if KeysLocked() or type(SetBinding) ~= "function" then return end
        holder:Cancel()
        local keys = BindingKeys(name)
        if #keys == 0 then return end
        for _, k in ipairs(keys) do pcall(SetBinding, k) end
        SaveKeys()
        Sync()
    end

    local function KeyTip()
        if KeysLocked() then return { L("Indisponible en combat") } end
        local keys = BindingKeys(name)
        local t = { ActionLabel(name) }
        if #keys > 0 then
            local names = {}
            for i, k in ipairs(keys) do names[i] = KeyLabel(k) end
            t[#t + 1] = string.format(L("Touches : %s"), table.concat(names, ", "))
        end
        t[#t + 1] = L("Clic : choisir une touche.")
        return t
    end
    local function ClearTip()
        if KeysLocked() then return { L("Indisponible en combat") } end
        return { L("Effacer"), L("Enlève les touches de cette action.") }
    end

    keyB = S.Button(holder, L("Aucun"), 84, 24, "secondary", KeyClick, KeyTip)
    clr = S.Button(holder, L("Effacer"), 0, 24, "ghost", Clear, ClearTip)
    keyB:SetDisabledReason(L("Indisponible en combat"))
    clr:SetDisabledReason(L("Indisponible en combat"))
    clr:SetPoint("RIGHT", holder, "RIGHT", 0, 0)
    keyB:SetPoint("RIGHT", clr, "LEFT", -8, 0)
    holder.keyB, holder.clr = keyB, clr

    -- the button's text, the row's line, what can be clicked; a new width lays the page out again
    function holder:Sync()
        local locked = KeysLocked()
        if locked and st.state then
            local c = keyCapture
            if c and c.target == self then c:Stop() end
            Reset()
        end
        local keys = BindingKeys(name)
        local text, desc
        if st.state == "capture" then
            text, desc = "...", L("Appuie sur une touche... (Échap : annuler)")
        elseif st.state == "conflict" then
            text = KeyLabel(st.key) .. " ?"
            desc = string.format(L("%s sert à « %s » : clique encore pour remplacer"), KeyLabel(st.key), ActionLabel(st.action))
        else
            text = (#keys > 0) and KeyLabel(keys[1]) or L("Aucun")
            if #keys > 1 then text = text .. " +" .. (#keys - 1) end
            if locked then desc = L("Indisponible en combat")
            elseif #keys > 1 then
                local more = {}
                for i = 2, #keys do more[#more + 1] = KeyLabel(keys[i]) end
                desc = string.format(L("Aussi : %s"), table.concat(more, ", "))
            elseif #keys == 1 then desc = L("Clic : changer la touche.")
            else desc = L("Clic : choisir une touche.") end
        end
        keyB:SetText(text)
        row:SetDesc(desc)
        if locked then keyB:Disable(); clr:Disable() else keyB:Enable(); clr:Enable() end
        if not locked and #keys == 0 and st.state == nil then clr:Disable() end
        if keyB.Paint then keyB.Paint() end
        if clr.Paint then clr.Paint() end
        local w = math.ceil((num(keyB:GetWidth()) or 84) + 8 + (num(clr:GetWidth()) or 60))
        local old = num(self:GetWidth()) or 0
        self:SetWidth(w)
        if old > 0 and old ~= w and p.holder and p.holder:IsShown() and p.contentH then p:Layout() end
    end
    holder:Sync()
    return holder
end

-- Settings > Quest guide > "Raccourcis": the rows, the game's own window, the events while shown.
local function KeyBindingsSection(p)
    Section(p, L("Raccourcis"))
    p.keyRows = {}
    for _, name in ipairs(BINDINGS) do
        local row = Row(p, ActionLabel(name), L("Clic : choisir une touche."))
        local ctl = BindingControl(p, row, name)
        Place(p, row, ctl)
        p.keyRows[#p.keyRows + 1] = ctl
    end
    local row = Row(p, L("Tout régler dans le jeu"), L("La fenêtre des raccourcis du jeu."))
    local open = S.Button(row, L("Ouvrir"), 0, 28, "secondary", function()
        if KeysLocked() then return end
        local opened
        if root.OpenKeyBindings then
            opened = root.OpenKeyBindings()
        else
            local St = rawget(_G, "Settings")
            if type(St) == "table" and type(St.OpenToCategory) == "function" and St.KEYBINDINGS_CATEGORY_ID ~= nil then
                opened = pcall(St.OpenToCategory, St.KEYBINDINGS_CATEGORY_ID)
            end
            if not opened then
                if not rawget(_G, "KeyBindingFrame") and type(rawget(_G, "KeyBindingFrame_LoadUI")) == "function" then
                    pcall(KeyBindingFrame_LoadUI)
                end
                local K = rawget(_G, "KeyBindingFrame")
                if K and type(ShowUIPanel) == "function" then opened = pcall(ShowUIPanel, K) end
            end
        end
        -- a button of the Hub that opens another window closes the Hub (3.20)
        if opened and win then win:Hide() end
    end, function()
        if KeysLocked() then return { L("Indisponible en combat") } end
        return { L("Tout régler dans le jeu"), L("Ouvre les raccourcis du jeu (section AddOns).") }
    end)
    open:SetDisabledReason(L("Indisponible en combat"))
    function open:Sync() if KeysLocked() then self:Disable() else self:Enable() end end
    Place(p, row, open)
    p.keyOpen = open

    local function SyncAll()
        for _, c in ipairs(p.keyRows) do c:Sync() end
        open:Sync()
    end
    p.SyncKeys = SyncAll
    local ev = CreateFrame("Frame")
    p.keyEvents = ev
    local EVENTS = { "UPDATE_BINDINGS", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED" }
    local function Arm(on)
        for _, e in ipairs(EVENTS) do
            pcall(on and ev.RegisterEvent or ev.UnregisterEvent, ev, e)
        end
    end
    ev:SetScript("OnEvent", function(_, e)
        -- shown: the page, and the Hub (a hidden page has no event, 3.20)
        if not (p.holder:IsShown() and win and win:IsShown()) then Arm(false) return end
        if e == "PLAYER_REGEN_DISABLED" then keyCombat = true
        elseif e == "PLAYER_REGEN_ENABLED" then keyCombat = false end
        SyncAll()
    end)
    p.holder:HookScript("OnShow", function()
        keyCombat = (InCombatLockdown and InCombatLockdown()) and true or false
        Arm(true)
        SyncAll()
    end)
    local function StopCapture()
        local c = keyCapture
        if c and c.target then c.target:Cancel() end
    end
    p.holder:HookScript("OnHide", function()
        Arm(false)
        StopCapture()
    end)
    -- the Hub closed mid-capture: the screen-wide frame (a child of UIParent) goes with it
    if win and win.HookScript then win:HookScript("OnHide", StopCapture) end
    if p.holder:IsShown() and win and win:IsShown() then Arm(true) end
end

function BUILD.dungeons(p)
    -- the module card above names the guide: the sections say what their rows are about
    Section(p, L("GPS et alertes"))
    SwitchRow(p, L("Flèche du guide"), function() return Guide().arrow ~= false end, SetGuideArrow,
        L("Le GPS te mène à l'étape suivante."), L("Le GPS te mène à la prochaine étape du guide."))
    SwitchRow(p, L("Alerte des monstres rares"), function() return Guide().rareAlert ~= false end, function(v) Guide().rareAlert = v end,
        L("Un message et un son, dans un donjon."),
        L("Dans un donjon, un message et un son quand un monstre rare apparaît."))
    SwitchRow(p, L("Points GPS à chaque étape"), function() return Guide().autoWay and true or false end,
        function(v) Guide().autoWay = v; RefreshGuide() end,
        L("Posés tout seuls à chaque nouvelle étape."),
        L("Les points de l'étape en cours sont posés tout seuls quand une nouvelle étape commence."))
    -- the guide tracker (Tracker.lua): its switch left the guide's Actions menu (T-74), it lives here
    SwitchRow(p, L("Suivi du guide"), function() return Guide().tracker == true end,
        function(v)
            local TR = _G.WLHelperTracker
            if TR and TR.SetShown then TR.SetShown(v) else Guide().tracker = v and true or false end
        end,
        L("Une petite fenêtre, guide fermé."),
        L("Une petite fenêtre avec l'action à faire, quand la fenêtre du guide est fermée."))
    -- the route's quests taken, handed in and shared by themselves (Writs/GuideQuests.lua)
    local GQ = ns.WP and ns.WP.GuideQuests
    if GQ then
        local function Desc(text, kind)
            local ok, note = pcall(GQ.OwnerNote, kind)
            return (ok and note) and (text .. " " .. note) or text
        end
        -- another addon that does it too is named on the row's one line (its full note in the tooltip)
        local function Short(text, kind)
            local okW, who = pcall(GQ.Owners, kind)
            if okW and type(who) == "table" and #who > 0 then
                return string.format(kind == "share" and L("Fait par %s.") or L("Aussi fait par %s."), table.concat(who, ", "))
            end
            return text
        end
        local function Sw(label, key, desc, long)
            SwitchRow(p, L(label), function() return GQ.On(key) end, function(v) GQ.Set(key, v) end, desc, long)
        end
        Section(p, L("Quêtes du guide"))
        Sw("Prendre les quêtes du guide tout seul", "questAutoAccept", Short(L("Seulement les quêtes de ta route."), "accept"),
            Desc(L("En parlant au PNJ, seulement les quêtes de ta route. Garde Maj enfoncée pour le faire à la main."), "accept"))
        Sw("Rendre les quêtes du guide tout seul", "questAutoTurnIn", Short(L("Quand il n'y a pas de récompense à choisir."), "turnin"),
            Desc(L("La récompense est prise toute seule quand il n'y a pas de choix. Garde Maj enfoncée pour le faire à la main."), "turnin"))
        Sw("Partager les quêtes du guide avec le groupe", "questAutoShare", Short(L("Une fois, hors combat."), "share"),
            Desc(L("Une quête de ta route que tu prends en groupe est partagée une fois, hors combat."), "share"))
        Sw("Choisir la récompense tout seul (la meilleure amélioration)", "questAutoReward",
            L("La meilleure amélioration pour ta spé."),
            L("Quand une quête du guide offre un choix, la meilleure amélioration pour ta spé est prise. Éteint, un message te dit laquelle choisir."))
    end
    -- "useful" hides the repeatable reputation quests and the quests of professions you don't have
    Section(p, L("Quêtes montrées"))
    local row = Row(p, L("Quêtes répétables ou d'un autre métier"), L("Masquées, elles sortent de la route."),
        L("Masquées, elles sortent de la route et du compte de quêtes de chaque donjon."))
    Choice(p, row, { { true, L("Masquer") }, { false, L("Afficher") } },
        function() return Guide().useful ~= false end,
        function(v)
            if (Guide().useful ~= false) == v then return end
            Guide().useful = v
            if root.Recalc and root.frame then root.Recalc() end
            if root.RenderPicker then root.RenderPicker() end
        end)
    -- the quest log triage (Writs/LogTriage.lua): its chat offer
    if ns.WP.Triage then
        Section(p, L("Journal de quêtes"))
        SwitchRow(p, L("Proposer le tri du journal"), function() return WLWritsDB.triageNotice ~= false end,
            function(v) WLWritsDB.triageNotice = v and true or false end,
            L("Quand ton journal est presque plein."),
            L("Quand ton journal de quêtes est presque plein, une ligne dans le chat propose de voir les quêtes à abandonner."))
    end
    -- the guide's keys, set here (T-83)
    KeyBindingsSection(p)
end

function BUILD.comptoir(p)
    Section(p, L("Automatismes"))
    SwitchRow(p, L("Rendre les Writs automatiquement"), function() return Comfort().autoTurnIn end, SetComfort("autoTurnIn"),
        L("En parlant au PNJ. Maj : à la main."), L("En parlant au PNJ. Garde Maj enfoncée pour le faire à la main."))
    SwitchRow(p, L("Rendre les caisses automatiquement"), function() return Comfort().autoCrates ~= false end, SetComfort("autoCrates"),
        L("En parlant à Dokimi ou à Marcy Baker."))
    SwitchRow(p, L("Accepter la quête en ouvrant l'enveloppe"), function() return Comfort().autoAccept end, SetComfort("autoAccept"))
    SwitchRow(p, L("Scanner l'HV à son ouverture"), function() return Writs().autoRescan end,
        function(v) Writs().autoRescan = v; RefreshWrits() end,
        L("Fenêtre Writs ouverte, prix de plus d'1 h."),
        L("Seulement si la fenêtre Writs est ouverte et que les prix ont plus d'une heure."))

    Section(p, L("Rappels et infobulles"))
    SwitchRow(p, L("Rappel à la connexion"), function() return Comfort().reminder end, SetComfort("reminder"),
        L("Ex. « 3 Writs prêts à rendre »."), L("Par exemple : « 3 Writs prêts à rendre, 1 enveloppe à ouvrir »."))
    SwitchRow(p, L("Détails dans l'infobulle des enveloppes"), function() return Comfort().tooltip end, SetComfort("tooltip"),
        L("Réputation, coût, à qui la rendre."), L("Réputation, coût, à qui la rendre, et si tu l'as déjà rendue."))
    -- profession cooldowns (Writs/Cooldowns.lua): the chat line when one is ready (a reminder too:
    -- its own section header cost a line on a wide page)
    SwitchRow(p, L("Prévenir quand une recharge est prête"),
        function() local CDm = ns.WP.Cooldowns; return not CDm or CDm.AlertOn() end,
        function(v) local CDm = ns.WP.Cooldowns; if CDm then CDm.SetAlert(v) end end,
        L("Une ligne dans le chat, pour chaque perso."),
        L("Transmutations, Étoffe lunaire, Salière : une ligne dans le chat, pour tous tes personnages. Leur temps restant est sur l'Accueil."))

    -- cost price at the AH (Writs/CostPrice.lua)
    Section(p, L("Prix de revient (HV)"))
    SwitchRow(p, L("Retenir mes prix d'achat"),
        function() local C = ns.WP.CostPrice; return not C or C.On() end,
        -- on = nil (the default), off = false ("v and nil or false" was always false)
        function(v) if v then WLWritsDB.costPrice = nil else WLWritsDB.costPrice = false end end,
        L("Moyenne sur 60 jours, dans l'infobulle."),
        L("Retient ce que tu paies à l'HV (moyenne sur 60 jours), l'affiche dans l'infobulle et prévient si tu vends en dessous."))

    Section(p, L("Plan d'achat"))
    local row = Row(p, L("Objectif de réputation"), L("Le plan achète de quoi l'atteindre."),
        L("Le plan achète les Writs qu'il faut pour l'atteindre."))
    Choice(p, row, {
        { 0, L("Rang suivant") }, { 6, L("Honoré") }, { 7, L("Révéré") },
    }, function() return Writs().goal or 0 end, function(v) Writs().goal = v; RefreshWrits() end)
    SwitchRow(p, L("Masquer les zones trop hautes"), function() return Writs().hideHigh end,
        function(v) Writs().hideHigh = v; RefreshWrits() end, L("Au-dessus de ton niveau : hors du plan."),
        L("Les zones au-dessus de ton niveau sortent du plan."))

    -- zones: the plan only buys writs of the zones left on (a single writ: right-click in "All writs");
    -- one compact toggle per zone (name, "from level N"), 3 or 4 a line (ns.GRID.toggles)
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
    -- how to leave out a single writ: in each zone's tooltip (a note under 24 toggles was one more
    -- line to scroll past)
    local one = string.format(L("Pour écarter un seul Writ : clic droit dessus dans l'onglet « %s » de la fenêtre Writs."), L("Tous les Writs"))
    for _, map in ipairs(maps) do
        local lo = WP.ZoneMin(map)
        local _, zr = SwitchRow(p, WP.ZoneName(map), function() return not WP.IsSkipped("zones", map) end,
            function(v) WP.SetSkipped("zones", map, not v) end,
            lo and string.format(L("dès le niv. %d"), lo) or nil, nil, { grid = "toggles" })
        zr:SetLong(one)   -- tooltip only: not searched (24 hits for "writ" otherwise)
    end
end

function BUILD.gps(p)
    -- Zygor's arrow (provider "zygor", nil = ours): a row only for players who have Zygor
    -- Shortest Path Forever (provider "spf"): the same, through its public API. One outside arrow at
    -- a time: turning one on turns the other off.
    local zygorBuilt = Providers()
    if zygorBuilt ~= "" then Section(p, L("Itinéraire")) end
    if ZygorPresent() then
        SwitchRow(p, L("Envoyer les destinations à la flèche de Zygor"), function() return Gps().provider == "zygor" end,
            function(v) SetGps("provider")(v and "zygor" or nil) end, L("Pour ceux qui préfèrent la flèche de Zygor."),
            L("Zygor calcule le trajet et le montre avec sa flèche. La flèche de WL Helper, son chemin et ses pointillés se cachent pendant ce temps."))
    end
    if SPFPresent() then
        SwitchRow(p, L("Envoyer les destinations à Shortest Path"), function() return Gps().provider == "spf" end,
            function(v) SetProvider(v and "spf" or nil) end, L("Son trajet sur la carte, les vols et les bateaux avec leur départ."),
            L("Shortest Path Forever calcule le trajet (chemins, vols, bateaux avec l'heure de départ, portails) et le montre sur la carte avec sa flèche. La flèche de WL Helper, son chemin et ses pointillés se cachent pendant ce temps. Les étapes du guide, les repères de la carte et /way passent par lui."))
    end
    -- Zygor can finish loading after the window was built (or be gone): the page is rebuilt once
    -- when it shows and the row no longer matches
    local rebuilding = false
    p.controls[#p.controls + 1] = { Sync = function()
        if rebuilding or Providers() == zygorBuilt then return end
        rebuilding = true
        if C_Timer and C_Timer.After and ns.WP.RebuildHubPage then
            C_Timer.After(0, function() ns.WP.RebuildHubPage("gps") end)
        end
    end }

    Section(p, L("Trajet"))
    SwitchRow(p, L("Utiliser mes téléportations"), function() return Gps().teleports end, SetGps("teleports"),
        L("Mage, druide : quand elles sont prêtes."), L("Tes sorts de téléportation (mage, druide), quand ils sont prêts."))
    SwitchRow(p, L("Choisir le vol automatiquement"), function() return Gps().autoFlight end, SetGps("autoFlight"),
        L("Chez le maître de vol."), L("Chez le maître de vol, le bon trajet est choisi pour toi."))
    -- Transports.lua: an arrival seen goes to the guild (nil = on)
    SwitchRow(p, L("Partager les horaires des zeppelins"), function() return Gps().shipShare ~= false end, SetGps("shipShare"),
        L("Avec la guilde, quand tu en prends un."),
        L("Quand tu prends un zeppelin ou un bateau, son heure d'arrivée part à la guilde (un court message) : le GPS de chacun sait alors quand il repart. Les horaires reçus de la guilde servent toujours."))
    -- the Hearthstone's policy (Route.lua HearthPolicy): "always" | "gain" (default, nil) | "never"
    Choice(p, Row(p, L("Pierre de foyer"), L("Une heure de recharge : à garder pour un vrai gain."),
        L("La pierre de foyer a une heure de recharge : par défaut, le GPS ne la propose que si elle fait gagner au moins 3 minutes sur le meilleur trajet sans elle. Le Rappel astral du chaman suit le même réglage ; les téléportations du mage, sans recharge, ne sont pas concernées. Le trajet écarté reste dans la bulle d'aide de la flèche (Alt-clic pour le prendre)."),
        { wide = true }), {
        { "always", L("Toujours si plus rapide") },
        { "gain", L("Seulement si elle fait gagner au moins 3 min") },
        { "never", L("Jamais") },
    }, function()
        local G = ns.WP and ns.WP.GPS
        return G and G.HearthPolicy and G.HearthPolicy() or "gain"
    end, function(v)
        Gps().hearth = (v ~= "gain") and v or nil
        local G = ns.WP and ns.WP.GPS
        if G and G.ResetPlan then pcall(G.ResetPlan) end
    end, true)
    row = Row(p, L("Points de vol connus"), L("Ceux que ce personnage a déjà découverts."),
        L("Ceux que ce personnage a déjà découverts, par continent. « ? » : aucune carte de maître de vol ouverte sur ce continent, ouvre-en une pour que le GPS connaisse tes vols."))
    local known = ValueText(row, 260)
    -- per continent (T-89): "Royaumes de l'Est 12 · Kalimdor ?" (? = unseen: no flight map opened there)
    function known:Sync()
        local G = ns.WP and ns.WP.GPS
        local function On(cont)
            local ok, n, unseen = pcall(function()
                if not (G and G.KnownFlightsOn) then return G and G.KnownFlights and G.KnownFlights() or 0, false end
                return G.KnownFlightsOn(cont), G.Unseen and G.Unseen(cont)
            end)
            if not ok then return "0" end
            if unseen then return "?" end
            return tostring(tonumber(n) or 0)
        end
        self:SetText(string.format(L("Royaumes de l'Est %s · Kalimdor %s"), On(0), On(1)))
    end
    known:Sync()
    Place(p, row, known)
    SwitchRow(p, L("Distances en yards"), function() return Gps().yards end, SetGps("yards"), L("Sinon en mètres et en kilomètres."))
    local GT, Way = ns.WP.GoTo, ns.WP.Way
    if GT and GT.WalkOn and GT.SetWalk then
        SwitchRow(p, L("Chemins à pied"), function() return GT.WalkOn() end, function(v) GT.SetWalk(v) end,
            L("La flèche contourne collines et murs."),
            L("La flèche suit un vrai chemin autour des collines et par les portes, pour tous les guides (WL Helper Nav). Sans lui, elle va tout droit."))
    end
    local TR = ns.WP.Trail
    if TR and TR.MapOn and TR.SetMap then
        SwitchRow(p, L("Chemin à pied sur la carte"), function() return TR.MapOn() end, function(v) TR.SetMap(v) end,
            L("Des points sur la carte du monde."),
            L("Des points sur la carte du monde montrent le chemin à pied jusqu'au point du GPS, avec une épingle sur l'endroit exact (WL Helper Nav)."))
        SwitchRow(p, L("Sur la minimap"), function() return TR.MinimapOn() end, function(v) TR.SetMinimap(v) end,
            L("Les mêmes points, autour de toi."), L("Les mêmes points sur la minimap, autour de toi."))
        if TR.SetMapSize and TR.SetMinimapSize and TR.SetColor then
            local function Sizes()
                return { { "small", L("Petits") }, { "medium", L("Moyens") }, { "large", L("Grands") } }
            end
            Choice(p, Row(p, L("Taille des points sur la carte")), Sizes(),
                function() return TR.MapSize() end, function(v) TR.SetMapSize(v) end)
            Choice(p, Row(p, L("Taille des points sur la minimap")), Sizes(),
                function() return TR.MinimapSize() end, function(v) TR.SetMinimapSize(v) end)
            Choice(p, Row(p, L("Couleur du chemin")),
                { { "accent", L("Rouge") }, { "yellow", L("Jaune") }, { "cyan", L("Cyan") } },
                function() return TR.Color() end, function(v) TR.SetColor(v) end)
        end
    end
    local WPn = ns.WP and ns.WP.WorldPin
    if WPn and WPn.SetMode then
        local desc = L("Une étiquette dans le monde, sur le point du GPS : le lieu, la distance et le temps qu'il reste. En automatique, elle ne s'affiche que si aucun autre addon ne le fait déjà.")
            .. " " .. L("Si tu as déjà posé un repère sur la carte, il est gardé et l'étiquette ne s'affiche pas.")
        local okO, who = pcall(WPn.Owner)
        if okO and type(who) == "string" then desc = desc .. " " .. string.format(L("Déjà fait par %s."), who) end
        local pinRow = Row(p, L("Repère dans le monde"), L("Lieu, distance et temps, dans le monde."), desc)
        Choice(p, pinRow, {
            { "auto", L("Automatique") },
            { "always", L("Toujours") },
            { "never", L("Jamais") },
        }, function() return WPn.Mode() end, function(v) WPn.SetMode(v) end)
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
        SwitchRow(p, L("Prendre /way"), wants, function(v) Way.SetTake(v) end,
            L("/way envoie le point au GPS de WL Helper."), desc)
    end
    if Way and Way.SetFollow then
        SwitchRow(p, L("Suivre les repères de la carte"), function() return Way.FollowOn() end, function(v) Way.SetFollow(v) end,
            L("Un repère posé sur la carte lance le GPS."),
            L("Un repère posé sur la carte du monde, par toi (Ctrl-clic) ou par un autre addon (les livres, coffres et rares de Naowh Forever : « Click for a waypoint »), lance le GPS de WL Helper jusque-là, avec la flèche et le chemin à pied. Le repère enlevé, le GPS s'arrête."))
    end

    -- the city tour (Writs/CityTour.lua): its card when you arrive in a capital
    local CT = ns.WP.CityTour
    if CT and CT.IsOn and CT.SetOn then
        Section(p, L("En ville"))
        SwitchRow(p, L("Tournée en ville"), function() return CT.IsOn() end, function(v) CT.SetOn(v) end,
            L("Une fiche en arrivant dans une capitale."),
            L("En arrivant dans une capitale, une petite fiche liste ce qu'il y a à faire : courrier, réparations, maître de classe, quêtes à rendre."))
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
        L("Sacs pleins : jeter l'objet le moins cher."),
        L("Quand tes sacs sont pleins, WL Helper propose de jeter l'objet le moins cher : un gris, ou une arme ou une armure blanche."))
    local other = ns.WP.Junk and ns.WP.Junk.OtherSeller and ns.WP.Junk.OtherSeller()
    SwitchRow(p, L("Vendre les gris chez les marchands"),
        function() return WLWritsDB.sellGreys ~= false end, function(v) WLWritsDB.sellGreys = v end,
        other and L("Un autre addon les vend déjà.") or L("Dès que tu ouvres la fenêtre d'un marchand."),
        other and L("Un autre de tes addons les vend déjà : WL Helper le laisse faire.") or nil)
    Note(p, L("Le nettoyeur ne propose jamais un objet qui lance une quête. Pour libérer une place à la main, tape /wlh place."))
end

-- Upgrades: the spec judged, the weights it uses at your level, when an arrow shows, the tooltip line.
local STAT_NAMES = {
    SP = "Dégâts des sorts", HEAL = "Soins", INT = "Intelligence", SPI = "Esprit", STA = "Endurance",
    STR = "Force", AGI = "Agilité", AP = "Puissance d'attaque", RAP = "Puissance d'attaque à distance",
    CRIT = "Critique (1 %)", SCRIT = "Critique des sorts (1 %)", HIT = "Toucher (1 %)", SHIT = "Toucher des sorts (1 %)",
    MP5 = "Mana toutes les 5 s", ARMOR = "Armure", DEF = "Défense", DODGE = "Esquive (1 %)", PARRY = "Parade (1 %)",
    BLOCK = "Blocage (1 %)", BLOCKV = "Valeur de blocage", DPS = "Dégâts par seconde de l'arme",
}
-- WL Helper Gear's stat keys (WLHelperGear.Weights().stats)
local GEAR_STAT_NAMES = {
    sp = "Puissance des sorts", heal = "Soins", sdmg = "Dégâts des sorts (seuls)", int = "Intelligence", spi = "Esprit",
    sta = "Endurance", str = "Force", agi = "Agilité", ap = "Puissance d'attaque", rap = "Puissance d'attaque à distance",
    crit = "Score de critique", hit = "Score de toucher", haste = "Score de hâte", exp = "Score d'expertise",
    def = "Défense", dodge = "Score d'esquive", parry = "Score de parade", block = "Score de blocage",
    bv = "Valeur de blocage", mp5 = "Mana toutes les 5 s", armor = "Armure", fire = "Dégâts de feu",
    frost = "Dégâts de givre", shadow = "Dégâts d'ombre", arcane = "Dégâts des arcanes", nature = "Dégâts de nature",
    holy = "Dégâts du sacré", spen = "Pénétration des sorts",
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
    -- the judge is not a setting: WL Helper Gear when loaded, else WL Helper's weights (Upgrades.lua)
    -- the spec rated, then for dual or triple spec the other specs of the class ticked here
    Section(p, L("Spés à comparer"))
    local srow = Row(p, L("Spé évaluée"), L("Auto : l'arbre où tu as le plus de points."),
        L("Auto : l'arbre de talents où tu as le plus de points."))
    Choice(p, srow, Wt.SpecChoices(),
        function() local db, c = SpecDB(); return db[c] or "auto" end,
        function(v)
            local db, c = SpecDB(); db[c] = v; Refresh()
            -- this page only, once the click has finished (this very control belongs to the old page)
            if RebuildPage then C_Timer.After(0, function() RebuildPage("upgrades") end) end
        end, true)
    local mrow = Row(p, L("Spé principale"), L("Toujours sur la première ligne."),
        L("Celle de tes talents, ou celle choisie plus haut. Toujours sur la première ligne."))
    local mainName = ValueText(mrow, 200)
    function mainName:Sync() self:SetText(Wt.SpecName()) end
    mainName:Sync()
    Place(p, mrow, mainName)
    for _, spec in ipairs(Wt.OtherSpecs and Wt.OtherSpecs() or {}) do
        local key = spec[1]
        SwitchRow(p, string.format(L("Comparer aussi : %s"), Wt.SpecName(spec)),
            function() return Wt.ExtraOn(key) end, function(v) Wt.SetExtra(key, v); Refresh() end,
            L("Une ligne de plus dans les infobulles."), L("Une ligne de plus dans les infobulles d'objet pour cette spé."))
    end
    local arow = Row(p, L("Flèche pour"), L("L'infobulle dit quelle spé gagne."),
        L("Avec plusieurs spés, l'infobulle dit laquelle gagne."))
    Choice(p, arow, { { "main", L("Ma spé principale") }, { "any", L("N'importe laquelle de mes spés") } },
        function() return WLWritsDB.upgradeArrowFor == "any" and "any" or "main" end,
        function(v) WLWritsDB.upgradeArrowFor = (v == "any") and "any" or nil; Refresh() end, true)

    Section(p, L("Affichage"))
    local trow = Row(p, L("Flèche à partir de"), L("Le gain minimum pour la flèche."),
        L("Le gain minimum pour mettre la flèche sur un objet."))
    local function pct(n) return string.format(L("%d %%"), n) end
    Choice(p, trow, { { 1, pct(1) }, { 3, pct(3) }, { 5, pct(5) }, { 10, pct(10) } },
        function() return WLWritsDB.upgradeMin or 1 end, function(v) WLWritsDB.upgradeMin = v; Refresh() end)
    SwitchRow(p, L("Ligne dans les infobulles d'objet"), function() return WLWritsDB.upgradeTip ~= false end,
        function(v) WLWritsDB.upgradeTip = v; ApplyTip() end, L("Le gain ou la perte pour ta spé."),
        L("Le gain ou la perte pour ta spé, et l'objet qu'il remplacerait."))
    SwitchRow(p, L("Masquer le bloc en double des infobulles"), function() return WLWritsDB.hideGFTip ~= false end,
        function(v) WLWritsDB.hideGFTip = v; ApplyTip() end, L("Si ton addon d'équipement l'affiche déjà."),
        L("Quand ton addon d'équipement affiche déjà le même pourcentage."))

    -- the grey line under the percent: the stats behind it (strings in Upgrades.lua)
    SwitchRow(p, L("Expliquer le pourcentage"), function() return WLWritsDB.upgradeWhy ~= false end,
        function(v) WLWritsDB.upgradeWhy = (not v) and false or nil; Refresh() end,
        L("Pourquoi, en mots. Maj : les chiffres."),
        L("Sous le pourcentage, une ligne grise dit en mots ce qui le fait le plus : « Surtout : DPS de baguette en plus, moins de dégâts de givre ». Garde Maj enfoncée pour les chiffres : « +12,8 DPS baguette (+30 %) · -4 dégâts de givre (-5 %) »."))

    -- what counts: the wand (wand classes only) and lighter armor (strings in Upgrades.lua)
    Section(p, L("Calcul"))
    if Wt.WandClass and Wt.WandClass() then
        -- Automatique (nothing stored): often below level 40, sometimes from 40 (Weights.lua)
        local wrow = Row(p, L("J'utilise ma baguette"), L("Ce que vaut le DPS d'une baguette."),
            L("Automatique : souvent avant le niveau 40, parfois ensuite (tes sorts comptent plus). Souvent : son DPS compte en entier. Parfois : à moitié. Jamais : presque pas, une meilleure baguette reste un peu meilleure."))
        Choice(p, wrow, { { "bylevel", L("Automatique (souvent avant 40, parfois après)") }, { "often", L("Souvent") },
                { "sometimes", L("Parfois") }, { "never", L("Jamais") } },
            function() return (Wt.WandAuto and Wt.WandAuto()) and "bylevel" or Wt.WandUse() end,
            function(v) WLWritsDB.upgradeWand = (v ~= "bylevel") and v or nil; Refresh() end, true)
    end
    SwitchRow(p, L("Ignorer les armures plus légères que la mienne (dès le niv. 40)"),
        function() return WLWritsDB.upgradeLighter ~= false end,
        function(v) WLWritsDB.upgradeLighter = (not v) and false or nil; Refresh() end,
        L("Ni % ni flèche sur une armure plus légère."),
        L("Dès le niveau 40 : chaman et chasseur sans cuir ni tissu, guerrier et paladin sans mailles, cuir ni tissu, druide et voleur sans tissu. L'infobulle dit « Armure plus légère que la tienne »."))

    local _, label = Wt.Bracket()
    -- built once: a level-up across a bracket or a respec on Auto rebuilds this page when shown
    local built = Wt.SpecName() .. label
    p.controls[#p.controls + 1] = { Sync = function()
        local _, l = Wt.Bracket()
        if Wt.SpecName() .. l ~= built and RebuildPage then
            built = Wt.SpecName() .. l   -- once: the new page carries the new name
            C_Timer.After(0, function() RebuildPage("upgrades") end)
        end
    end }
    -- the weights that judge: WL Helper Gear's when it does, ours otherwise
    local gearRows, gearWt
    if ns.WP.UpgradeGearWeights then
        local okG, r, w = pcall(ns.WP.UpgradeGearWeights)
        if okG and r and #r > 0 then gearRows, gearWt = r, w end
    end
    if gearRows then
        Section(p, string.format(L("Poids utilisés (WL Helper Gear) : %s, niveau %d"), Wt.SpecName(), gearWt.level or UnitLevel("player")))
    else
        Section(p, string.format(L("Poids utilisés : %s, niveaux %s"), Wt.SpecName(), label))
    end
    -- the weights: one cell per stat (name at the left, weight at the right) in the compact grid
    -- (ns.GRID.toggles, 3 or 4 a line), a zebra per line
    local list = CreateFrame("Frame", nil, p)
    local lines = {}
    for i, e in ipairs(gearRows or Wt.Table()) do
        local line = CreateFrame("Frame", nil, list)
        line.zebra = S.Solid(line, "BACKGROUND", T.zebraA); line.zebra:SetAllPoints()
        line.name = S.Text(line, F.label, T.text)
        line.name:SetJustifyH("LEFT")
        line.name:SetText(L((gearRows and GEAR_STAT_NAMES[e[1]]) or STAT_NAMES[e[1]] or e[1]))
        line.value = S.Text(line, F.label, T.fg)
        line.value:SetJustifyH("RIGHT")
        S.ClampLabel(line.value, nil, line)
        line.value:SetText(Decimal(e[2]))
        lines[i] = line
    end
    list.lines = lines
    list.grid = root.Grid()
    p.weights = list
    Add(p, list, function(width)
        local g = list.grid
        local go = root.GRID.toggles
        g:Begin(list, 0, 0, width, { minW = go.minW, gap = go.gap, rowGap = 0, maxCols = go.maxCols, minPx = go.minPx, equal = true })
        for _, line in ipairs(lines) do
            g:Add(line, function(f, w)
                f.value:ClearAllPoints(); f.value:SetPoint("TOPRIGHT", -12, -7); f.value:SetWidth(56)
                f.name:ClearAllPoints(); f.name:SetPoint("TOPLEFT", 8, -7)
                return math.max(28, 7 + math.max(15, root.FitText(f.name, 2, w - 8 - 12 - 56 - 8, f)) + 6)
            end)
        end
        local h = g:End()
        for _, c in ipairs(g.cells) do
            local z = (c.line % 2 == 0) and T.zebraB or T.zebraA
            c.frame.zebra:SetColorTexture(z[1], z[2], z[3], z[4] or 1)
            c.frame.zebraLine = c.line
        end
        list:SetHeight(math.max(1, h))
        return h
    end, "list", 4)
    if gearRows then
        Note(p, L("Ces poids sont ceux de WL Helper Gear, qui juge tes objets : ta spé, ton niveau et ce que tu portes, en points de ta stat principale (puissance des sorts ; soins pour un soigneur, puissance d'attaque en physique, endurance pour un tank). Les plafonds sont comptés : le toucher ne vaut presque plus rien une fois le plafond atteint (5 % des sorts, 6 % en mêlée contre les monstres jusqu'à 2 niveaux au-dessus ; 17 % et 8 % en raid), la défense d'un tank jusqu'à son plafond."))
        return
    end
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

-- The chat commands as a table: "/wlh x : what it does" (FR) or "/wlh x: what it does" (EN), one
-- per line of the text; a line without a colon is a command alone.
local CMD_W = 132
local function SplitCommand(line)
    local cmd, what = line:match("^(.-)%s*:%s+(.+)$")
    if not cmd or cmd == "" then return line, "" end
    return cmd, what
end
CommandTable = function(p, text)
    p.card = nil
    local holder = CreateFrame("Frame", nil, p)
    holder.cells = {}
    holder.grid = root.Grid()
    p.commands = holder
    for line in (text or ""):gmatch("[^\n]+") do
        local cmd, what = SplitCommand(line)
        local c = CreateFrame("Frame", nil, holder)
        c.cmd = S.Text(c, F.label, T.fg)
        c.cmd:SetJustifyH("LEFT"); c.cmd:SetJustifyV("TOP")
        c.cmd:SetText(cmd)
        c.what = S.Text(c, F.label, T.muted)
        c.what:SetJustifyH("LEFT"); c.what:SetJustifyV("TOP")
        c.what:SetText(what)
        holder.cells[#holder.cells + 1] = c
    end
    Add(p, holder, function(width)
        local g = holder.grid
        g:Begin(holder, 0, 0, width, { minW = 380, gap = 16, rowGap = 6, maxCols = 2, minPx = 200 })
        for _, c in ipairs(holder.cells) do
            g:Add(c, function(f, w)
                f.cmd:ClearAllPoints(); f.cmd:SetPoint("TOPLEFT", 0, 0)
                local ch = root.FitText(f.cmd, 0, CMD_W, f)
                f.what:ClearAllPoints(); f.what:SetPoint("TOPLEFT", CMD_W + 12, 0)
                local wh = root.FitText(f.what, 0, math.max(40, w - CMD_W - 12), f)
                return math.max(14, ch, wh)
            end)
        end
        local h = math.max(1, (g:End()))
        holder:SetHeight(h)
        return h
    end, "commands", 8)
    return holder
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
        local v = ValueText(row, 200)
        v:SetText(value)
        Place(p, row, v)
    end
    Section(p, L("Crédits"))
    info(L("Auteur"), "Alandir (WaR LegenD)")
    info(L("Logo"), L("WaR LegenD (War Legend Raid Tool)"))
    -- the link under its label, across a whole line of the card: never cut
    local row = Row(p, L("Code source"), L("Clique sur le lien, puis Ctrl+C pour le copier."), nil, { wide = true })
    local link = CopyBox(row, GITHUB, 320)
    Place(p, row, link)
    local fit = row.Fit
    function row:Fit(width)
        width = math.floor(width or 0)
        link:SetWidth(math.max(120, math.min(NOTE_W, width - 2 * 12)))
        if (num(link:GetHeight()) or 0) <= 0 then link:SetHeight(28) end
        -- wider than half the row: S.SettingRow puts it under the texts, else beside them
        return fit(self, width)
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
        local h = math.max(15, root.FitText(say, 0, math.min(width, NOTE_W), fb))
        bIdea:ClearAllPoints(); bIdea:SetPoint("TOPLEFT", 0, -(h + 12))
        bBug:ClearAllPoints(); bBug:SetPoint("LEFT", bIdea, "RIGHT", 8, 0)
        h = math.ceil(h + 12 + 28)
        fb:SetHeight(h)
        return h
    end, "block", 8)
    Register(p, fb, L("Une idée, un bug ?"), L("Proposer une idée") .. " " .. L("Signaler un bug"))

    Section(p, L("Commandes du chat"))
    -- the same list as /wlh help, in the guide's language: one cell per command (the command 12 fg
    -- in a column of 132, what it does 12 muted beside it), 2 a line from 784 px (minW 380)
    CommandTable(p, root.L and root.L.HELP or "/wlh")
end

-- ---------------------------------------------------------------- the window

-- A module page's first card: the module's painted icon, its name, what it does and a button to
-- open it; when it is switched off, a sentence that says so and the button that turns it back on.
-- A button that opens a window closes the Hub first (the window would open under it otherwise).
local OPEN = {
    dungeons = { "Ouvrir le guide", function()
        if win then win:Hide() end
        if root.GuideStatus and root.GuideStatus() then root.ShowGuide() elseif root.ShowPicker then root.ShowPicker() end
    end },
    comptoir = { "Ouvrir les Writs", function() if win then win:Hide() end; ns.WP.Open("writs") end },
    bags = { "Nettoyer les sacs", function() if win then win:Hide() end; if ns.WP.Cleaner then ns.WP.Cleaner.Toggle() end end },
    orders = { "Ouvrir les commandes", function() if win then win:Hide() end; if ns.WP.ToggleOrders then ns.WP.ToggleOrders() end end },
    guild = { "Ouvrir la guilde", function() if win then win:Hide() end; if ns.WP.ToggleGuild then ns.WP.ToggleGuild() end end },
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

-- A settings page is built the first time it shows: its module card (a module page), then its rows.
local PAGE_MODULE = { dungeons = "dungeons", comptoir = "writs", bags = "bags", upgrades = "upgrades",
    orders = "orders", guild = "guild" }
local function NewSettingsPage(p, def)
    p.built = false
    function p:Build()
        if self.built then return end
        self.built = true
        local mod = PAGE_MODULE[def.key]
        if mod then ModuleCard(self, def.key, mod) end
        BUILD[def.key](self)
    end
end

-- Builds the nav and every page into a fresh body frame (again after a language change or a new
-- width). The nav, from the top: the settings search (175 x 28 at 12,-12), Home, then each
-- activity that has a page (its title 24 px, its pages 32 px, 2 apart); that part scrolls when the
-- screen is short. Anchored at the bottom: "Settings" (General, About), then a 28 px row with
-- "How do I...?", "What's new", "Write to us" and the version.
local function BuildBody()
    for i = #INDEX, 1, -1 do INDEX[i] = nil end
    body = CreateFrame("Frame", nil, win)
    body:SetPoint("TOPLEFT", 0, -(HEADER_H + 1))
    body:SetPoint("BOTTOMRIGHT", 0, 0)

    local nav = CreateFrame("Frame", nil, body)
    nav:SetPoint("TOPLEFT"); nav:SetPoint("BOTTOMLEFT"); nav:SetWidth(NAV_W)
    body.nav = nav
    local edge = S.Solid(body, "BORDER", T.divider)
    edge:SetPoint("TOPLEFT", NAV_W, 0); edge:SetPoint("BOTTOMLEFT", NAV_W, 0); edge:SetWidth(1)
    root.PixelLine(body, edge, false)

    local content = CreateFrame("Frame", nil, body)
    content:SetPoint("TOPLEFT", NAV_W + 1, 0); content:SetPoint("BOTTOMRIGHT")
    body.content = content

    -- the bottom row: two icons and the version ("How do I...?" is the header's "?": one way, not
    -- two, and the info glyph stays About's)
    local foot = CreateFrame("Frame", nil, nav)
    foot:SetHeight(28)
    foot:SetPoint("BOTTOMLEFT", 0, 12); foot:SetPoint("BOTTOMRIGHT", 0, 12)
    body.foot = foot
    local WP = ns.WP
    local function Away(fn) return function() if win then win:Hide() end; fn() end end
    foot.news = S.IconButton(foot, "star", 28, { L("Quoi de neuf"), L("Clic : ouvrir « Quoi de neuf »") },
        Away(function() if root.ShowWhatsNew then root.ShowWhatsNew(WLDTDB and WLDTDB.newsFrom) end end))
    foot.news:SetPoint("LEFT", 12, 0)
    foot.mail = S.IconButton(foot, "mail", 28,
        { L("Nous écrire"), L("Une idée, un bug ?"), L("Clic : ouvrir le formulaire pour nous écrire") },
        Away(function() if WP.Feedback then WP.Feedback("idea") end end))
    foot.mail:SetPoint("LEFT", 44, 0)
    -- the version alone: "WL Helper 1.0.0-beta.72" would not fit beside the icons (full in the tooltip)
    foot.version = S.Text(foot, F.foot, T.muted)
    foot.version:SetJustifyH("RIGHT")
    foot.version:SetPoint("RIGHT", -12, 0); foot.version:SetPoint("LEFT", 44 + 28 + 8, 0)
    foot.version:SetText(Version())
    S.ClampLabel(foot.version, "WL Helper " .. Version(), foot)
    foot:EnableMouse(true)
    foot:SetScript("OnEnter", function(self) S.Tip(self, { "WL Helper " .. Version() }) end)
    foot:SetScript("OnLeave", S.HideTip)

    body.pages, body.tabs = {}, {}
    local function PaintNavLater() if body.PaintNav then body.PaintNav() end end
    local function Item(parent, def, y)
        local b = S.NavItem(parent, {
            key = def.key, label = L(def.label), icon = def.icon,
            tip = { L(def.label), L(def.desc), def.key == "home" and L("Clic : ouvrir l'Accueil")
                or def.key == "welcome" and L("Clic : ouvrir la page Bienvenue") or L("Clic : afficher ces réglages") },
            onClick = function(self) ns.WP.OpenHub(self.key) end,
            onHover = PaintNavLater,
        })
        b:SetPoint("TOPLEFT", 8, y); b:SetPoint("TOPRIGHT", -8, y)
        body.tabs[#body.tabs + 1] = b
        return b
    end

    -- the pages by activity, in the order of WP.HUB_GROUPS; a page whose activity is unknown (the
    -- registry not loaded) still gets its item, after the others
    local byGroup, order, known = {}, {}, {}
    for _, g in ipairs(ns.WP.HUB_GROUPS or {}) do known[g.key] = true end
    for _, def in ipairs(PAGES) do
        local g = def.group or "home"
        if not byGroup[g] then byGroup[g] = {}; order[#order + 1] = g end
        table.insert(byGroup[g], def)
    end

    -- bottom block: "Settings" and its pages, above the bottom row
    local settings = byGroup.settings or {}
    local itemsH = #settings * NAV_ITEM_H + math.max(0, #settings - 1) * NAV_GAP
    local bottomH = 12 + 28 + 8 + itemsH + (#settings > 0 and 24 or 0)
    if #settings > 0 then
        local head = S.NavHeader(nav, L("Réglages"))
        head:SetPoint("BOTTOMLEFT", nav, "BOTTOMLEFT", 0, bottomH - 24)
        head:SetPoint("BOTTOMRIGHT", nav, "BOTTOMRIGHT", 0, bottomH - 24)
        body.settingsHead = head
        local holder = CreateFrame("Frame", nil, nav)
        holder:SetPoint("BOTTOMLEFT", 0, 12 + 28 + 8); holder:SetPoint("BOTTOMRIGHT", 0, 12 + 28 + 8)
        holder:SetHeight(itemsH)
        body.settingsBlock = holder
    end
    body.navBottomH = bottomH

    -- top part: Home and the activities, scrolled when the screen is short
    local top = S.ScrollArea(nav)
    top:SetPoint("TOPLEFT", 0, -NAV_TOP)
    top:SetPoint("BOTTOMRIGHT", nav, "BOTTOMRIGHT", 0, bottomH + 4)
    local list = top.child
    list:SetWidth(NAV_W)
    body.navScroll = top
    body.navHeads = {}
    local y = 0
    local function Group(gkey, label)
        local defs = byGroup[gkey]
        if not defs or #defs == 0 then return end   -- an activity without a page is not drawn
        if label then
            local h = S.NavHeader(list, label)
            h:SetPoint("TOPLEFT", 0, -y); h:SetPoint("TOPRIGHT", 0, -y)
            h.key = gkey
            body.navHeads[#body.navHeads + 1] = h
            y = y + 24
        end
        for _, def in ipairs(defs) do
            Item(list, def, -y)
            y = y + NAV_ITEM_H + NAV_GAP
        end
    end
    Group("home")
    for _, g in ipairs(ns.WP.HUB_GROUPS or {}) do Group(g.key, L(g.label)) end
    for _, g in ipairs(order) do
        if g ~= "home" and g ~= "settings" and not known[g] then Group(g) end
    end
    body.navTopH = math.max(0, y - NAV_GAP)
    top:SetContentHeight(body.navTopH)

    if body.settingsBlock then
        local sy = 0
        for _, def in ipairs(settings) do
            Item(body.settingsBlock, def, -sy)
            sy = sy + NAV_ITEM_H + NAV_GAP
        end
    end

    -- the pages, in the PAGES order (Home first). Home is built at once; a settings page only the
    -- first time it shows (the minimap click opens Home, and should not pay for every settings row),
    -- or all of them the first time the search box is used (its index needs every row).
    for _, def in ipairs(PAGES) do
        local p = NewPage(content, def)
        p.key, p.pageLabel, p.pageIcon = def.key, L(def.label), def.icon
        if def.key == "home" then
            if ns.WP.HomePage then ns.WP.HomePage.Build(p, CONTENT_W, win) end
            p.built = true
        else
            NewSettingsPage(p, def)
        end
        body.pages[def.key] = p
    end
    -- every settings page, in the nav's order (the search index)
    function body.BuildAll()
        for _, def in ipairs(PAGES) do
            local p = body.pages[def.key]
            if p and not p.built and p.Build then p:Build() end
        end
    end

    -- Selected page: selection fill and bright label; hover: soft fill and bright label.
    function body.PaintNav()
        for _, b in ipairs(body.tabs) do b:Paint(b.key == current) end
    end
    BuildSearch(nav, content)
end

local function PaintNav() if body and body.PaintNav then body.PaintNav() end end

-- Lays the page shown (or the search results) out again; the window keeps its size.
Relayout = function(later)
    if not (win and body) then return end
    local function go()
        if body.results and body.results:IsShown() then
            if body.LayoutResults then body.LayoutResults() end
        else
            local p = body.pages[current]
            if p then p:Layout() end
        end
    end
    go()
    -- wrapped text measures right once its width is applied: once more on the next frame
    if later ~= false and C_Timer and C_Timer.After then
        C_Timer.After(0, function()
            if not (win and win:IsShown()) then return end
            go()
            -- a section just shown (ShowAnchor): scrolled to again, now that the rows above it are measured
            local a = body.anchorPending
            body.anchorPending = nil
            local p = body.pages[current]
            if a and p and p:IsShown() and not (body.results and body.results:IsShown()) then
                p.sa:ScrollTo(math.max(0, (a.pageY or 0) - 8), true)
            end
        end)
    end
end

-- Every page (and the search results) at the content width of now. Home and Welcome follow it
-- (their SetWidth); a page drawn elsewhere that does not (p.wlResizes) is built again at the new
-- width, once the size has stopped changing.
local rebuildTimer
local function ApplyWidths()
    if not body then return end
    local function Stale(k, pg)
        return k ~= "home" and k ~= "welcome" and pg.built and pg.builtW and pg.builtW ~= CONTENT_W
            and not pg.wlResizes
    end
    local stale = false
    for key, p in pairs(body.pages) do
        p:SetWidth(CONTENT_W)
        p.hubWidth = CONTENT_W
        if key == "home" then
            if ns.WP.HomePage and ns.WP.HomePage.SetWidth then ns.WP.HomePage.SetWidth(CONTENT_W) end
        elseif key == "welcome" then
            if ns.WP.WelcomePage and ns.WP.WelcomePage.SetWidth then ns.WP.WelcomePage.SetWidth(CONTENT_W) end
        elseif Stale(key, p) then
            stale = true
        end
    end
    -- one timer for every stale page, each checked again when it fires
    if stale then
        if rebuildTimer and rebuildTimer.Cancel then rebuildTimer:Cancel() end
        local function go()
            rebuildTimer = nil
            if not (body and RebuildPage) then return end
            local keys = {}
            for k, pg in pairs(body.pages) do if Stale(k, pg) then keys[#keys + 1] = k end end
            for _, k in ipairs(keys) do RebuildPage(k) end
        end
        if C_Timer and C_Timer.NewTimer then rebuildTimer = C_Timer.NewTimer(0.25, go) else go() end
    end
    if body.results and body.results.child then body.results.child:SetWidth(CONTENT_W) end
end

-- The window got a new size (dragged, saved, a new screen): new widths, then the page shown laid
-- out again (layout only, nothing rebuilt). widthsOnly: no layout (ShowPage lays out after).
Resized = function(later, widthsOnly)
    local oldW, oldH = WIN_W, WIN_H
    Dims()
    if WIN_W ~= oldW or not body or body.appliedW ~= CONTENT_W then
        ApplyWidths()
        if body then body.appliedW = CONTENT_W end
    end
    if widthsOnly then return end
    if win and win:IsShown() and (WIN_W ~= oldW or WIN_H ~= oldH or later ~= nil) then Relayout(later) end
end

local function PlayerLine()
    local okN, n = pcall(UnitName, "player")
    local okL, lv = pcall(UnitLevel, "player")
    n = (okN and type(n) == "string" and not secret(n)) and n or ""
    lv = (okL and num(lv)) or 0
    return string.format(L("%s, niv. %d"), n, lv)
end

-- The saved places of the two windows the Hub replaced: Home's place is kept for the Hub.
local function Migrate()
    local db = WLWritsDB
    if type(db) ~= "table" then return end
    db.hubPos = db.hubPos or db.homePos
    db.homePos, db.optionsPos, db.homeToolsOpen = nil, nil, nil
end

local function BuildWindow()
    Migrate()
    Dims()
    -- the workspace tier (Writs/Style.lua S.MakeResizable): the rule's size or the saved one, the
    -- grip, the bounds; OnResize lays the page shown out again at the new width (once a frame)
    win = S.Window("WLHelperHub", WIN_W, WIN_H, "WL Helper", PlayerLine(), WLWritsDB, "hubPos",
        { header = HEADER_H, logo = true, size = "workspace" })
    win.OnResize = function() if Resized then Resized(false) end end
    -- "?": how do I...? (DESIGN 2.1: the info glyph), one click from every page
    if ns.WP.Help then
        -- the tip is read on hover: it follows a language change
        win.help = S.IconButton(win.header, "info", 28, function()
            return { L("Comment faire... ?"), L("Les gestes utiles, pas à pas"), L("Clic : ouvrir « Comment faire... ? »") }
        end, function()
            win:Hide(); if ns.WP.Help then ns.WP.Help.Toggle() end
        end)
        win:AddHeaderButton(win.help)
    end
    -- the names of the two windows it replaced
    _G.WLHelperOptions = win
    _G.WLHelperHome = win
    BuildBody()
end

Rebuild = function()
    if not win then return end
    local keep = current
    body:Hide()
    body:SetParent(nil)   -- the old frames stay orphaned; a language change is rare
    BuildBody()
    win.title:SetText("WL Helper")
    current = nil
    ns.WP.OpenHub(keep or "home")
end

-- One settings page built again (a new spec or level bracket on Améliorations): only its holder is
-- orphaned, its search entries replaced; the nav, Home, the other pages, the search and, when it is
-- the page shown, its scroll position are kept.
RebuildPage = function(key)
    if not (win and body and body.pages and body.pages[key]) or key == "home" then return end
    local def
    for _, d in ipairs(PAGES) do if d.key == key then def = d end end
    if not def then return end
    local old = body.pages[key]
    local scroll = (current == key and old.sa and old.sa:GetScroll()) or 0
    for i = #INDEX, 1, -1 do
        if INDEX[i].page == key then table.remove(INDEX, i) end
    end
    old:Hide()
    old.holder:SetParent(nil)
    local p = NewPage(body.content, def)
    p.key, p.pageLabel, p.pageIcon = def.key, L(def.label), def.icon
    NewSettingsPage(p, def)
    if old.built then p:Build() end
    body.pages[key] = p
    local searching = body.results and body.results:IsShown()
    if searching then
        if body.SearchUpdate then body.SearchUpdate() end
    elseif current == key and win:IsShown() then
        p:Show(); p:Sync(); p:Layout()
        p.sa:ScrollTo(math.max(0, num(scroll) or 0), true)
        Relayout()
    end
end
ns.WP.RebuildHubPage = function(key) if RebuildPage then RebuildPage(key) end end
ns.WP.HubIndex = function() return INDEX end   -- the offline tests

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
    if Resized then Resized(nil, true) end   -- the size may have changed while hidden: widths only
    local p = body.pages[key]
    if not p.built and p.Build then p:Build() end
    for k, pg in pairs(body.pages) do pg:SetShown(k == key) end
    p:Sync()
    PaintNav()
    if key == "home" and ns.WP.HomePage then ns.WP.HomePage.Refresh(true) end
    Relayout()
end

-- Scrolls a page to a section (or a row) and makes it flash in the selection colour for 1.5 s
-- (the search's "Click: show this setting").
local function Flash(f)
    if not f then return end
    if not f.flash then f.flash = S.Solid(f, "BACKGROUND", T.selFill); f.flash:SetAllPoints() end
    f.flash:SetAlpha(1)
    root.Tween(f.flash, 1, 0, 1.5, function(v) f.flash:SetAlpha(v) end)
end
local function ShowAnchor(key, anchor)
    local p = body and body.pages[key]
    if not (p and anchor) then return end
    local want = L(anchor)
    local target, also = p.anchors and p.anchors[want], nil
    if target then
        -- the section header and the card under it
        for i, it in ipairs(p.items) do
            if it.frame == target then
                local nx = p.items[i + 1]
                also = nx and nx.kind == "card" and nx.frame or nil
            end
        end
    else
        for _, e in ipairs(INDEX) do
            if e.page == key and e.label == want then target = e.row; break end
        end
    end
    if not target then return end
    p.sa:ScrollTo(math.max(0, (target.pageY or 0) - 8), true)
    Flash(target); Flash(also)
    body.anchorShown, body.anchorPending = target, target
end

-- ---------------------------------------------------------------- search

BuildSearch = function(nav, content)
    local box = S.Input(nav, NAV_W - 24, { search = true, placeholder = L("Ex. flèche") })
    box:SetPoint("TOPLEFT", 12, -12)
    body.searchBox = box
    ns.WP.searchBox = box   -- for a key binding, and the offline tests
    box.wlBody = body
    box:HookScript("OnEnter", function(self) S.Tip(self, { L("Chercher un réglage"), L("Ex. flèche") }) end)
    box:HookScript("OnLeave", S.HideTip)
    -- the index needs every settings page: built when the box takes the focus (or on the first search)
    box:HookScript("OnEditFocusGained", function() if body.BuildAll then body.BuildAll() end end)

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
        if #q >= 2 and body.BuildAll then body.BuildAll() end
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

    body.SearchUpdate = Update   -- a page built again (RebuildPage) re-runs the search shown
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

-- After a module is switched elsewhere (a Home line, the minimap menu), the open page shows it.
function ns.WP.SyncOptions()
    if win and win:IsShown() and body and body.pages[current] then
        body.pages[current]:Sync()
        Relayout()
    end
end

-- WP.OpenHub(page, anchor): shows the Hub on a page ("home", "dungeons", "gps", "comptoir",
-- "bags", "upgrades", "orders", "guild", "groups", "general", "about"; Home by default, or the page it was on), built the first
-- time. anchor: a section or a row label of that page (French key): scrolled to and flashed.
function ns.WP.OpenHub(page, anchor)
    if not win then BuildWindow() end
    win.subtitle:SetText(PlayerLine())
    win:Show()
    ShowPage(page or current or "home")
    if anchor then ShowAnchor(current, anchor) end
    if win.Raise then win:Raise() end
end

function ns.WP.CloseHub() if win then win:Hide() end end

-- -> the section or row WP.OpenHub(page, anchor) last scrolled to (the Welcome page lights it)
function ns.WP.HubAnchor() return body and body.anchorShown or nil end

-- -> the key of the page the Hub shows (or showed last), nil before it was opened
function ns.WP.HubPage() return current end

-- -> true when the Hub is on screen on that page (IsVisible: the window and the page shown)
function ns.WP.HubShows(key)
    if not (win and body and current == key) then return false end
    local p = body.pages[key]
    if not p then return false end
    local ok, v = pcall(p.holder.IsVisible, p.holder)
    if ok and type(v) == "boolean" then return v end
    return win:IsShown() and p:IsShown()   -- clients (and test stubs) without IsVisible
end

-- The Settings page (Home is not one): the page given, else the settings page shown last.
function ns.WP.ShowOptionsPage(key)
    ns.WP.OpenHub(key or (current ~= "home" and current) or "general")
end

-- Opens the Hub on a settings page; closes it when it is already open on that page (or on any
-- settings page when no page is given; from Home it goes to the settings).
function ns.WP.OpenOptions(pageKey)
    if win and win:IsShown() and (pageKey == current or (pageKey == nil and current ~= "home")) then
        win:Hide()
        return
    end
    ns.WP.ShowOptionsPage(pageKey)
end

-- A new screen size or UI scale: Writs/Style.lua re-applies the size rule to every tiered window
-- (0.25 s after the last event) and the window's OnResize lays the page out at the new width.
-- Called directly too (the offline tests, a client that sends no OnSizeChanged).
local function OnScreenChanged()
    if not win then return end
    if win.ApplySize then win:ApplySize() end
    Resized()
end
ns.WP.HubScreenChanged = OnScreenChanged

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
    ns.WP.OpenHub("general")
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
                    if ZygorPresent() then
                        toggle(L("Envoyer les destinations à la flèche de Zygor"), function() return Gps().provider == "zygor" end,
                            function(v) SetGps("provider")(v and "zygor" or nil) end)
                    end
                    if SPFPresent() then
                        toggle(L("Envoyer les destinations à Shortest Path"), function() return Gps().provider == "spf" end,
                            function(v) SetProvider(v and "spf" or nil) end)
                    end
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
ev:SetScript("OnEvent", function(self, event)
    if event ~= "PLAYER_LOGIN" then return end
    self:UnregisterEvent("PLAYER_LOGIN")
    Migrate()
    -- Main.lua shows the guide two seconds after login unless WLDTDB.hidden: clearing it here
    -- (this file loads last, so this runs after Main's handler) reopens a closed guide.
    if WLDTDB and WLDTDB.reopenGuide then WLDTDB.hidden = false end
    local ok, err = pcall(RegisterGameSettings)
    if not ok and geterrorhandler then geterrorhandler()(err) end
    ok, err = pcall(RegisterEllesmere)
    if not ok and geterrorhandler then geterrorhandler()(err) end
end)
