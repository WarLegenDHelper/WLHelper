-- Résumé d'un ou plusieurs donjons : le premier écran quand tu lances une route depuis le choix des
-- donjons, et la vue d'ensemble d'un donjon (bouton de la carte, clic droit, bouton du guide).
-- Pour chaque donjon, trois questions dans l'ordre : où est-ce, puis-je y aller, qu'est-ce que j'y
-- gagne. L'image du donjon (nom, « Conseillé niv. 38 à 48 · Groupe de 5 · tu es niv. 41 »), puis des
-- blocs titrés (titre doré au-dessus, texte dessous, DESIGN 3.21) : Entrée (avec son GPS), Clé, Avant
-- d'entrer (les quêtes à prendre dehors, chacune avec son GPS) et Tu gagnes (quêtes cochées, XP et
-- part d'un niveau, argent, objets). Puis « Quêtes à faire » : une carte par quête, toujours dans le
-- même ordre. Le nom (blanc) et, à droite, l'XP que tu recevras vraiment à ton niveau (grisée quand
-- elle est réduite) et l'argent. Une ligne de faits en mots : « Quête niv. 36 · facile · se prend dès
-- le niv. 30 », ou le niveau qu'il te manque. Une pastille d'état (À prendre, À prendre dedans, Dans
-- ton journal, Prête à rendre) puis Élite ou Autre donjon, avec à droite « Partager » (seulement
-- quand un membre n'a pas encore la quête) et le GPS. Jusqu'à 4 objets en récompense (icône bordée de
-- sa qualité, « +12 % » sous l'icône quand WL Helper Gear y voit une amélioration, le meilleur des
-- choix cerclé d'or). Enfin la chaîne, qui se déplie juste en dessous. Les quêtes déjà rendues sont
-- repliées en bas (« Déjà rendues (10) »). En groupe, deux onglets en haut : « Quêtes » (cette liste)
-- et « Groupe · 2 à régler » : un tableau, une ligne par quête cochée (niveau, où la prendre), une
-- colonne par membre (nom en couleur de classe, niveau), une icône par case (l'a, prête, rendue, ne
-- peut pas, inconnu) avec sa raison au survol (ns.PartyQuests, les données de WL Helper d'abord),
-- « 2/3 l'ont » et « Partager » par ligne, ce qui bloque le plus en tête et « Vérifier » (relit le
-- groupe et partage les quêtes cochées une à une). Avec plusieurs donjons, le total de toute la
-- route vient à la fin. En bas : « Lancer la route » (premier écran), « Mettre à jour la
-- route » (la route tourne et tes coches ont changé) ou « Retour à la route » (rien n'a changé), et
-- « Fermer » (« Retour au choix » quand le résumé vient du choix du guide). Ouvert ailleurs pendant
-- qu'une route tourne sur d'autres donjons : « Lancer la route ici », confirmé par un deuxième clic.
-- Design system: docs/DESIGN.md (a workspace window, 3.1: its size from the screen, resizable, the
-- size kept; the list scrolls inside; quest cards and facts side by side when it is wide, 3.22).
local ADDON, ns = ...
local L, T = ns.L, ns.T_

-- =====================================================================
--  Strings (added to the root locale tables; Locale.lua keeps the older OV_ keys)
-- =====================================================================
local STR = {
  fr = {
    SUM_T = "Vue d'ensemble", SUM_ROUTE_T = "Vue d'ensemble de la route", SUM_DG1 = "%d donjon", SUM_DG = "%d donjons",
    SUM_XP = "%s XP", SUM_XP_UNIT = "XP", SUM_SIZE = "Groupe de %d",
    SUM_CHAIN_LINE = "Chaîne de %d quêtes · %s XP en tout", SUM_CHAIN_HIGH = "monte au niv. %d",
    SUM_FACT_LV = "Quête niv. %d",
    SUM_BAND_RED = "très dure", SUM_BAND_ORANGE = "dure", SUM_BAND_YELLOW = "à ton niveau", SUM_BAND_GREEN = "facile",
    SUM_BAND_GREY = "grise, peu d'XP",
    SUM_BAND_RED_TT = "Très dure : 5 niveaux ou plus au-dessus de toi.",
    SUM_BAND_ORANGE_TT = "Dure : 3 ou 4 niveaux au-dessus de toi.",
    SUM_BAND_YELLOW_TT = "À ton niveau : de 2 niveaux sous toi à 2 au-dessus.",
    SUM_BAND_GREEN_TT = "Facile : sous ton niveau, elle donne encore de l'XP.",
    SUM_BAND_GREY_TT = "Grise : trop basse pour toi, elle donne très peu d'XP.",
    SUM_FROM = "se prend dès le niv. %d", SUM_NEED = "se prend au niv. %d, tu es niv. %d",
    SUM_NEED_PRE = "étape suivante au niv. %d, tu es niv. %d",
    SUM_XP_LESS_TT = "XP réduite : %s au lieu de %s, car tu as %d niveaux de plus que la quête.",
    SUM_XP_CAP_TT = "Tu es au niveau maximum : plus d'XP.",
    SUM_F_ENTRY = "Entrée", SUM_F_KEY = "Clé", SUM_F_READY = "Avant d'entrer", SUM_F_GAIN = "Tu gagnes",
    SUM_RDY_NOTHING = "Aucune quête à prendre dehors.", SUM_XP_LESS = "XP réduite", SUM_LINK_LV = "niv. %d",
    SUM_GQ1 = "%d quête cochée", SUM_GQ = "%d quêtes cochées", SUM_GAIN0 = "Aucune quête cochée.",
    SUM_LVPCT = "(environ %d\194\160%% d'un niveau)", SUM_LVN1 = "(environ %s niveau)", SUM_LVN = "(environ %s niveaux)",
    SUM_HERO_LV1 = "Conseillé niv. %d", SUM_HERO_LV = "Conseillé niv. %d à %d", SUM_HERO_YOU = "tu es niv. %d",
    SUM_ROUTE_H = "Toute la route", SUM_AND = " et ",
    SUM_SHARE_WHO = "Pas encore chez : %s",
    SUM_ST_ON_TT = "Tu l'as déjà : rien à prendre.", SUM_ST_READY_TT = "Objectifs faits : va la rendre.",
    SUM_ELITE = "Élite", SUM_ELITE_TT = "Un objectif vise un monstre élite : viens en groupe.",
    SUM_OTHER = "Autre donjon : %s", SUM_OTHER_TT = "Un maillon de la chaîne se fait dans %s.",
    SUM_HIGH_TT = "La chaîne monte jusqu'au niveau %d, plus de 5 niveaux au-dessus de toi : décochée par défaut.",
    SUM_ST_ON = "Dans ton journal", SUM_ST_READY = "Prête à rendre", SUM_ST_DONE = "Rendue",
    SUM_TICK_OFF = "Clic : retirer cette quête de la route", SUM_TICK_ON = "Clic : remettre cette quête dans la route",
    SUM_TICK_OFF_CH = "Clic : retirer cette quête et ses %d prérequis de la route",
    SUM_TICK_ON_CH = "Clic : remettre cette quête et ses %d prérequis dans la route",
    SUM_EXPAND = "Clic : voir chaque quête de la chaîne", SUM_COLLAPSE = "Clic : replier la chaîne",
    SUM_FDJ = "Note de ForeverDungeonJournal", SUM_LFD = "Étapes (LibForeverData)",
    SUM_TODO = "Quêtes à faire",
    SUM_DONE_H = "Déjà rendues (%d)", SUM_DONE_OPEN = "Clic : voir les quêtes déjà rendues", SUM_DONE_CLOSE = "Clic : replier les quêtes déjà rendues",
    SUM_ALLDONE_T = "Toutes les quêtes sont rendues : %s", SUM_ALLDONE_TN = "Tu as déjà rendu toutes les quêtes de ces donjons",
    SUM_ALLDONE_NOTE = "%s : toutes les quêtes sont déjà rendues.",
    SUM_OTHER_DG = "Choisir un autre donjon",
    SUM_RUN = "Me guider dans le donjon", SUM_RUN_N = "Me guider dans les donjons",
    SUM_RUN_TT = "Clic : ouvrir le guide, de l'entrée jusqu'au dernier boss, un boss après l'autre",
    SUM_RUN_SUB = "Le guide peut quand même te mener de l'entrée au dernier boss.",
    SUM_RUN_SUB_N = "Le guide peut quand même te mener dans chaque donjon, de boss en boss.",
    SUM_BACK_PICK = "Retour au choix", SUM_BACK_PICK_TT = "Clic : revenir au choix du guide sans lancer la route",
    SUM_GO_HERE = "Lancer la route ici", SUM_GO_CONFIRM = "Remplacer la route ?",
    SUM_GO_HERE_TT = "Clic : remplacer la route en cours par ce donjon seul, avec les quêtes cochées (les étapes cochées à la main sont perdues ; un 2e clic confirme)",
    SUM_GO = "Lancer la route", SUM_GO_TT = "Clic : fermer la vue d'ensemble et ouvrir le guide sur la première étape, avec les quêtes cochées",
    SUM_GO_TT1 = "Clic : lancer la route sur ce donjon seul, avec les quêtes cochées (remplace tes donjons choisis)",
    SUM_GO_WHY = "Coche au moins une quête à faire.", SUM_CLOSE = "Fermer", SUM_CLOSE_TT = "Clic : fermer la vue d'ensemble sans lancer la route",
    SUM_UPDATE = "Mettre à jour la route", SUM_UPDATE_TT = "Clic : revenir au guide, la route suit tes nouvelles coches",
    SUM_BACK = "Retour à la route", SUM_BACK_TT = "Clic : revenir au guide là où tu en étais",
    SUM_SHARE = "Partager", SUM_SHARED = "Partagée", SUM_SHARE_TT = "Clic : partager « %s » avec le groupe",
    SUM_SHARE_ALL = "Tout partager", SUM_SHARE_ALL_TT = "Clic : partager avec le groupe les quêtes cochées de ton journal, une toutes les 1,5 s",
    SUM_SHARE_WHY = "Aucune quête cochée de ton journal ne se partage.", SUM_SHARING = "Partage en cours",
    SUM_NOQ = "Aucune quête pour toi dans ce donjon.",
    SUM_TAB_Q = "Quêtes", SUM_TAB_G = "Groupe", SUM_TAB_G_N = "Groupe · %d à régler",
    SUM_G_CHECK = "Vérifier", SUM_G_CHECKING = "Vérification...",
    SUM_G_CHECK_TT = "Clic : relire le groupe et partager une à une les quêtes cochées de ton journal ; les réponses du jeu remplissent le tableau",
    SUM_G_HAVE = "%d/%d l'ont", SUM_G_CELL_TT = "Survole une case pour la raison",
    SUM_G_BLOCK_LOW1 = "%s est trop bas pour %d quête", SUM_G_BLOCK_LOW = "%s est trop bas pour %d quêtes",
    SUM_G_BLOCK_PRE1 = "Il manque à %s la quête d'avant pour %d quête", SUM_G_BLOCK_PRE = "Il manque à %s la quête d'avant pour %d quêtes",
    SUM_G_BLOCK_NO1 = "%s ne peut pas prendre %d quête", SUM_G_BLOCK_NO = "%s ne peut pas prendre %d quêtes",
    SUM_G_BLOCK_MISS1 = "%s n'a pas %d quête : partage-la", SUM_G_BLOCK_MISS = "%s n'a pas %d quêtes : partage-les",
    SUM_G_BLOCK_UNK1 = "État inconnu pour %d quête : clique sur Vérifier", SUM_G_BLOCK_UNK = "État inconnu pour %d quêtes : clique sur Vérifier",
    SUM_G_ALLOK = "Tout le groupe a les quêtes cochées.",
    SUM_G_MORE1 = "%d autre membre n'a pas de colonne.", SUM_G_MORE = "%d autres membres n'ont pas de colonne.",
    SUM_G_ON = "L'a dans son journal", SUM_G_READY = "Prête à rendre", SUM_G_DONE = "Déjà rendue", SUM_G_TAKE = "À prendre",
    SUM_G_PRE = "Prérequis manquant", SUM_G_LOW = "Niveau trop bas", SUM_G_NA = "Pas pour ce personnage", SUM_G_INVALID = "Pas éligible",
    SUM_G_DECLINED = "Refusée", SUM_G_FULL = "Journal plein", SUM_G_BUSY = "Indisponible", SUM_G_FAR = "Trop loin",
    SUM_G_SENT = "Envoyée", SUM_G_UNKNOWN = "Pas encore de réponse", SUM_G_WAIT = "En attente",
    SUM_G_PRE_TT = "Il lui manque : %s", SUM_G_UNKNOWN_TT = "Pas encore de réponse du jeu pour %s : partage la quête pour la voir.",
    SUM_G_SENT_TT = "Quête envoyée : en attente de la réponse de %s.", SUM_G_PUSH_TT = "D'après la réponse du jeu au partage.",
    SUM_G_NA_TT = "Cette quête n'est pas pour sa classe, sa faction ou sa race.",
    SUM_G_WAIT_TT = "%s a WL Helper : sa réponse n'est pas encore arrivée.",
    SUM_OTHER_SHORT = "Autre donjon", SUM_RW_MORE = "Autres récompenses",
    SUM_PICK_GO_TT = "Clic : voir la vue d'ensemble des quêtes (XP, récompenses, chaînes, groupe) avant de lancer la route",
    SUM_IT1 = "%d objet", SUM_IT = "%d objets",
    SUM_IT_UP1 = "%s dont %d amélioration", SUM_IT_UP = "%s dont %d améliorations",
    SUM_UP_PCT = "+%d\194\160%%", SUM_UP_EMPTY = "vide", SUM_UP_EMPTY_TT = "Tu n'as rien à cet emplacement.",
    SUM_BEST = "Ton meilleur choix", SUM_BEST_TT = "Le meilleur choix pour ta spé parmi les récompenses au choix.",
    SUM_RDY_OK1 = "Prêt : tu as la quête à prendre dehors", SUM_RDY_OK = "Prêt : tu as les %d quêtes à prendre dehors",
    SUM_RDY_IN1 = "%d autre se prend dans le donjon", SUM_RDY_IN = "%d autres se prennent dans le donjon",
    SUM_RDY_INALL1 = "Ta quête se prend dans le donjon", SUM_RDY_INALL = "Tes quêtes se prennent toutes dans le donjon",
    SUM_RDY_MISS1 = "Il te manque %d quête à prendre dehors", SUM_RDY_MISS = "Il te manque %d quêtes à prendre dehors",
    SUM_RDY_AFTER = "après « %s »", SUM_RDY_MORE1 = "et %d autre", SUM_RDY_MORE = "et %d autres",
    SUM_ST_TAKE = "À prendre", SUM_ST_TAKE_TT = "Elle se prend dehors : prends-la avant d'entrer dans le donjon.",
    SUM_ST_IN = "À prendre dedans", SUM_ST_IN_TT = "Elle se prend dans le donjon : rien à faire avant d'entrer.",
    SUM_LINK_UNFOLD = "Clic : afficher la description", SUM_LINK_FOLD = "Clic : replier la description",
  },
  en = {
    SUM_T = "Overview", SUM_ROUTE_T = "Route overview", SUM_DG1 = "%d dungeon", SUM_DG = "%d dungeons",
    SUM_XP = "%s XP", SUM_XP_UNIT = "XP", SUM_SIZE = "Group of %d",
    SUM_CHAIN_LINE = "Chain of %d quests · %s XP in all", SUM_CHAIN_HIGH = "goes up to level %d",
    SUM_FACT_LV = "Level %d quest",
    SUM_BAND_RED = "very hard", SUM_BAND_ORANGE = "hard", SUM_BAND_YELLOW = "at your level", SUM_BAND_GREEN = "easy",
    SUM_BAND_GREY = "grey, little XP",
    SUM_BAND_RED_TT = "Very hard: 5 or more levels above you.",
    SUM_BAND_ORANGE_TT = "Hard: 3 or 4 levels above you.",
    SUM_BAND_YELLOW_TT = "At your level: from 2 levels below you to 2 above.",
    SUM_BAND_GREEN_TT = "Easy: below your level, it still gives XP.",
    SUM_BAND_GREY_TT = "Grey: too low for you, it gives very little XP.",
    SUM_FROM = "available from level %d", SUM_NEED = "available at level %d, you are level %d",
    SUM_NEED_PRE = "next step at level %d, you are level %d",
    SUM_XP_LESS_TT = "Reduced XP: %s instead of %s, because you are %d levels above the quest.",
    SUM_XP_CAP_TT = "You are at the level cap: no more XP.",
    SUM_F_ENTRY = "Entrance", SUM_F_KEY = "Key", SUM_F_READY = "Before you go in", SUM_F_GAIN = "You get",
    SUM_RDY_NOTHING = "No quest to pick up outside.", SUM_XP_LESS = "reduced XP", SUM_LINK_LV = "level %d",
    SUM_GQ1 = "%d ticked quest", SUM_GQ = "%d ticked quests", SUM_GAIN0 = "No quest ticked.",
    SUM_LVPCT = "(about %d%% of a level)", SUM_LVN1 = "(about %s level)", SUM_LVN = "(about %s levels)",
    SUM_HERO_LV1 = "Suggested level %d", SUM_HERO_LV = "Suggested level %d-%d", SUM_HERO_YOU = "you are level %d",
    SUM_ROUTE_H = "The whole route", SUM_AND = " and ",
    SUM_SHARE_WHO = "Not yet with: %s",
    SUM_ST_ON_TT = "You already have it: nothing to pick up.", SUM_ST_READY_TT = "Objectives done: go and turn it in.",
    SUM_ELITE = "Elite", SUM_ELITE_TT = "An objective targets an elite: bring a group.",
    SUM_OTHER = "Other dungeon: %s", SUM_OTHER_TT = "One link of the chain happens in %s.",
    SUM_HIGH_TT = "The chain goes up to level %d, more than 5 levels above you: unticked by default.",
    SUM_ST_ON = "In your log", SUM_ST_READY = "Ready to turn in", SUM_ST_DONE = "Turned in",
    SUM_TICK_OFF = "Click: leave this quest out of the route", SUM_TICK_ON = "Click: put this quest back in the route",
    SUM_TICK_OFF_CH = "Click: leave this quest and its %d prerequisites out of the route",
    SUM_TICK_ON_CH = "Click: put this quest and its %d prerequisites back in the route",
    SUM_EXPAND = "Click: show each quest of the chain", SUM_COLLAPSE = "Click: fold the chain",
    SUM_FDJ = "Note from ForeverDungeonJournal", SUM_LFD = "Steps (LibForeverData)",
    SUM_TODO = "Quests to do",
    SUM_DONE_H = "Already turned in (%d)", SUM_DONE_OPEN = "Click: show the quests already turned in", SUM_DONE_CLOSE = "Click: fold the quests already turned in",
    SUM_ALLDONE_T = "Every quest turned in: %s", SUM_ALLDONE_TN = "You already turned in every quest of these dungeons",
    SUM_ALLDONE_NOTE = "%s: every quest is already turned in.",
    SUM_OTHER_DG = "Pick another dungeon",
    SUM_RUN = "Guide me through the dungeon", SUM_RUN_N = "Guide me through the dungeons",
    SUM_RUN_TT = "Click: open the guide, from the entrance to the last boss, one boss at a time",
    SUM_RUN_SUB = "The guide can still lead you from the entrance to the last boss.",
    SUM_RUN_SUB_N = "The guide can still lead you through each dungeon, boss by boss.",
    SUM_BACK_PICK = "Back to the picker", SUM_BACK_PICK_TT = "Click: go back to the guide picker without starting the route",
    SUM_GO_HERE = "Start the route here", SUM_GO_CONFIRM = "Replace the route?",
    SUM_GO_HERE_TT = "Click: replace the running route with this dungeon only and the ticked quests (steps marked done by hand are lost; a 2nd click confirms)",
    SUM_GO = "Start the route", SUM_GO_TT = "Click: close the overview and open the guide on the first step, with the ticked quests",
    SUM_GO_TT1 = "Click: start the route with this dungeon only and the ticked quests (replaces your picked dungeons)",
    SUM_GO_WHY = "Tick at least one quest to do.", SUM_CLOSE = "Close", SUM_CLOSE_TT = "Click: close the overview without starting the route",
    SUM_UPDATE = "Update the route", SUM_UPDATE_TT = "Click: go back to the guide, the route follows your new ticks",
    SUM_BACK = "Back to the route", SUM_BACK_TT = "Click: go back to the guide where you left it",
    SUM_SHARE = "Share", SUM_SHARED = "Shared", SUM_SHARE_TT = "Click: share \"%s\" with the group",
    SUM_SHARE_ALL = "Share all", SUM_SHARE_ALL_TT = "Click: share the ticked quests of your log with the group, one every 1.5 s",
    SUM_SHARE_WHY = "No ticked quest in your log can be shared.", SUM_SHARING = "Sharing",
    SUM_NOQ = "No quest for you in this dungeon.",
    SUM_TAB_Q = "Quests", SUM_TAB_G = "Group", SUM_TAB_G_N = "Group · %d to sort out",
    SUM_G_CHECK = "Check", SUM_G_CHECKING = "Checking...",
    SUM_G_CHECK_TT = "Click: read the group again and share the ticked quests of your log one by one; the game's answers fill the table",
    SUM_G_HAVE = "%d/%d have it", SUM_G_CELL_TT = "Hover a cell for the reason",
    SUM_G_BLOCK_LOW1 = "%s is too low for %d quest", SUM_G_BLOCK_LOW = "%s is too low for %d quests",
    SUM_G_BLOCK_PRE1 = "%s misses an earlier quest for %d quest", SUM_G_BLOCK_PRE = "%s misses an earlier quest for %d quests",
    SUM_G_BLOCK_NO1 = "%s cannot take %d quest", SUM_G_BLOCK_NO = "%s cannot take %d quests",
    SUM_G_BLOCK_MISS1 = "%s lacks %d quest: share it", SUM_G_BLOCK_MISS = "%s lacks %d quests: share them",
    SUM_G_BLOCK_UNK1 = "Unknown for %d quest: click Check", SUM_G_BLOCK_UNK = "Unknown for %d quests: click Check",
    SUM_G_ALLOK = "The whole group has the ticked quests.",
    SUM_G_MORE1 = "%d more member has no column.", SUM_G_MORE = "%d more members have no column.",
    SUM_G_ON = "Has it in their log", SUM_G_READY = "Ready to turn in", SUM_G_DONE = "Already turned in", SUM_G_TAKE = "To pick up",
    SUM_G_PRE = "Missing prerequisite", SUM_G_LOW = "Level too low", SUM_G_NA = "Not for this character", SUM_G_INVALID = "Not eligible",
    SUM_G_DECLINED = "Declined", SUM_G_FULL = "Log full", SUM_G_BUSY = "Busy", SUM_G_FAR = "Too far",
    SUM_G_SENT = "Sent", SUM_G_UNKNOWN = "No answer yet", SUM_G_WAIT = "Waiting",
    SUM_G_PRE_TT = "Missing link: %s", SUM_G_UNKNOWN_TT = "No answer from the game for %s yet: share the quest to see it.",
    SUM_G_SENT_TT = "Quest sent: waiting for %s's answer.", SUM_G_PUSH_TT = "From the game's answer to the share.",
    SUM_G_NA_TT = "This quest is not for their class, faction or race.",
    SUM_G_WAIT_TT = "%s has WL Helper: their reply has not arrived yet.",
    SUM_OTHER_SHORT = "Other dungeon", SUM_RW_MORE = "More rewards",
    SUM_PICK_GO_TT = "Click: see the quests' overview (XP, rewards, chains, group) before starting the route",
    SUM_IT1 = "%d item", SUM_IT = "%d items",
    SUM_IT_UP1 = "%s including %d upgrade", SUM_IT_UP = "%s including %d upgrades",
    SUM_UP_PCT = "+%d%%", SUM_UP_EMPTY = "empty", SUM_UP_EMPTY_TT = "You wear nothing in this slot.",
    SUM_BEST = "Your best pick", SUM_BEST_TT = "The best of the rewards to choose from for your spec.",
    SUM_RDY_OK1 = "Ready: you have the quest to pick up outside", SUM_RDY_OK = "Ready: you have all %d quests to pick up outside",
    SUM_RDY_IN1 = "%d more is picked up inside the dungeon", SUM_RDY_IN = "%d more are picked up inside the dungeon",
    SUM_RDY_INALL1 = "Your quest is picked up inside the dungeon", SUM_RDY_INALL = "Your quests are all picked up inside the dungeon",
    SUM_RDY_MISS1 = "%d quest still to pick up outside", SUM_RDY_MISS = "%d quests still to pick up outside",
    SUM_RDY_AFTER = "after \"%s\"", SUM_RDY_MORE1 = "and %d more", SUM_RDY_MORE = "and %d more",
    SUM_ST_TAKE = "To pick up", SUM_ST_TAKE_TT = "Given outside: pick it up before you go into the dungeon.",
    SUM_ST_IN = "To pick up inside", SUM_ST_IN_TT = "You get it inside the dungeon: nothing to do before you go in.",
    SUM_LINK_UNFOLD = "Click: show the description", SUM_LINK_FOLD = "Click: fold the description",
  },
}
do
  local S = ns.LOCALE_TABLES
  if S then
    for lang, t in pairs(STR) do
      S[lang] = S[lang] or {}
      for k, v in pairs(t) do if S[lang][k] == nil then S[lang][k] = v end end
    end
  end
end

-- =====================================================================
--  Sizes (design system: workspace window 3.1, inset 16, rows 8, pills 18)
-- =====================================================================
-- W and CW follow the window (Dims, at every render): the size rule of the workspace tier
-- (ns.WinSize), or the size the player dragged it to.
local W, PAD = 640, 16
local CW = W - 2 * PAD          -- content width
local HERO_H, HERO_H_MULTI = 96, 72
local ART_W0 = 608              -- the width the pictures' crops were chosen for (the old 640 window)
-- quest cards side by side when the window is wide (2 from 904 px of content, 3 from 1356)
local QGRID = { minW = 440, gap = 12, rowGap = 8, maxCols = 3, minPx = 200, equal = true }
-- the facts (entrance and key, before you go in, you get) side by side
local FACT_MIN, FACT_GAP, FACT_ROWGAP = 260, 24, 16
-- the Group tab: the quest column keeps GNAME_MIN, the members' columns share the rest
local GNAME_MIN, GCELL_MIN, GCELL_MAX = 300, 64, 96
local ROW_GAP = 4
local TX = 32                   -- text column of a row (after the check box)
local MAX_REWARDS = 4            -- reward icons per row (the last one is "+N" when there are more)
local RW_SIZE, RW_STEP = 32, 48   -- a reward icon, and icon + gap (the "+12 %" under it fits the gap)
local RW_LABEL = 17               -- the line under an icon: arrow and gain
local HIGH_GAP = 5              -- a chain more than 5 levels above the player is unticked by default
local XPCOL = 88                -- the XP and money column at the right of a quest card

local function SW()
  local S = ns.Writs and ns.Writs.S
  if not S then error("WL Helper: Writs/Style.lua missing") end
  return S
end
local function secret(v) return issecretvalue ~= nil and issecretvalue(v) end
local function num(v) return type(v) == "number" and not secret(v) and v or nil end
local function Cls() local _, c = UnitClass("player"); return c end
local function Level() return num(UnitLevel("player")) or 1 end
local function ZoneName(m)
  if not (m and C_Map and C_Map.GetMapInfo) then return "" end
  local ok, info = pcall(C_Map.GetMapInfo, m)
  return (ok and type(info) == "table" and type(info.name) == "string") and info.name or ""
end
-- A FontString's measured height, never less than one line of its size (unmeasured text).
local function LineH(fs, size, width, owner, maxLines)
  local h = ns.FitText(fs, maxLines or 2, width, owner)
  if not h or h < size then h = size + 2 end
  return h
end
-- 38 900 (French, a no-break space: a wrapped line never breaks inside the number) / 38,900
local function Big(n)
  local s = tostring(math.floor((n or 0) + 0.5))
  local sep = ns.lang == "fr" and "\194\160" or ","
  local k
  repeat s, k = s:gsub("^(%-?%d+)(%d%d%d)", "%1" .. sep .. "%2") until k == 0
  return s
end
ns.BigNumber = Big
local function SetOn(b, on) if on then b:Enable() else b:Disable() end end
local function Lib()
  local lib = _G.LibForeverData
  return (type(lib) == "table" and type(lib.Get) == "function") and lib or nil
end

-- =====================================================================
--  Quest facts shared with the picker (state, prerequisites, chain)
-- =====================================================================
-- done / ready / on / none; pseudo-quests (negative ids, e.g. the Mallet) use ns.IsDone
local function QState(log, qid)
  if ns.IsDone(qid) then return "done" end
  return ns.State(log, qid)
end
ns.QuestState = QState

-- Prerequisites of a quest (the full chain, in order) and where the player stands in it:
-- { chain, total, done, inLog, states[i], nextPid, nextIdx }.
function ns.QuestPreInfo(qid, log, cls)
  log = log or ns.LogEntries()
  cls = cls or Cls()
  local chain = ns.FullChain(qid, cls) or {}
  local out = { chain = chain, total = #chain, done = 0, inLog = 0, states = {} }
  for i, pid in ipairs(chain) do
    local s = QState(log, pid)
    out.states[i] = s
    if s == "done" then out.done = out.done + 1
    else
      if s ~= "none" then out.inLog = out.inLog + 1 end
      if not out.nextPid then out.nextPid, out.nextIdx = pid, i end
    end
  end
  return out
end

-- The level the next thing to take needs, when the player is below it (nil otherwise).
local function LowLevel(log, q, st, pre, lvl)
  if st ~= "none" then return nil end
  local need = q.r
  if pre.nextPid then
    local pq = ns.Q[pre.nextPid]
    if pq and ns.State(log, pre.nextPid) ~= "none" then return nil end
    need = pq and pq.r
  end
  if need and lvl < need then return need end
  return nil
end

-- An objective with a place outside the dungeon, not done yet.
local function OutsideLeft(log, qid, q)
  for _, o in ipairs(q.o or {}) do
    if o.w and not o.ins and not o.outer and not ns.ObjDone(log, qid, o) then return o end
  end
end

local function at(l, fallback) if l and l.m and l.x and l.y then return { l.m, l.x, l.y, l.n or fallback } end end
-- Where one quest's next action is: its giver, its outside objective, its turn-in.
local function PointOf(log, qid, q, st)
  if st == "none" then return at(q.s, ns.QName(qid)) end
  if st == "ready" then return at(q.f, ns.QName(qid)) end
  if st == "on" then
    local o = OutsideLeft(log, qid, q)
    return o and at(o.w, o.n)
  end
end
-- The point the quest's GPS leads to: the next prerequisite first, then the quest itself.
local function PointFor(log, qid, q, st, pre)
  if pre.nextPid then
    local pq = ns.Q[pre.nextPid]
    return pq and PointOf(log, pre.nextPid, pq, QState(log, pre.nextPid)) or nil
  end
  return PointOf(log, qid, q, st)
end

local function GoPoint(p)
  if not p then return end
  if ns.SetPoints then ns.SetPoints({ p }, true) end
  -- the guide's arrow follows the points only while the guide is open and its arrow on:
  -- a click on a GPS button starts the arrow anyway
  local G = ns.Writs and ns.Writs.WP and ns.Writs.WP.GPS
  if G and G.GoPoint and WLDTDB and (WLDTDB.hidden or WLDTDB.arrow == false) then
    pcall(G.GoPoint, p[1], p[2], p[3], p[4], "dungeon")
  end
  if PlaySound then PlaySound(SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or 856) end
end

-- Who gives the quest and where; once its objectives are done, who takes it back.
local function GiverText(q, st)
  local s, fmt, txt = q.s, L.OV_GIVER, q.st
  if st == "ready" and (q.f or q.ft) then s, fmt, txt = q.f, L.OV_FINISHER, q.ft
  elseif q.si and (not s or s.i) then return L.OV_ITEM_START:format(q.si) end
  if s and s.i then return fmt:format((s.n or "?") .. ", " .. L.OV_IN_DG) end
  if s and s.m then
    local z = ZoneName(s.m)
    if s.n and z ~= "" then return fmt:format(s.n .. ", " .. z) end
    return fmt:format(s.n or z)
  end
  if txt then return fmt:format(ns.T(txt)) end
  return nil
end

local function ObjText(q) return (ns.lang == "fr" and q.of) or ns.T(q.oe) end

-- WL Helper Gear (the gear scoring addon), when it is loaded: its quest rewards and its comparison.
local function Gear()
  local G = _G.WLHelperGear
  return (type(G) == "table" and type(G.Compare) == "function") and G or nil
end

-- Rewards: item ids read live from LibForeverData when it is loaded (it says which are a choice).
-- Else our data's item names (q.ri, all a choice when q.rc) merged with WL Helper Gear's item ids
-- (QuestieDB): a name Gear gives for one of its ids (English, like ours) takes that id; Gear's
-- other ids follow. Gear does not say which rewards are a choice: q.rc does for every one.
local rewardCache = {}
local function GearRewards(qid)
  local G = Gear()
  if not (G and type(G.QuestRewards) == "function" and qid > 0) then return nil end
  local ok, ids, names = pcall(G.QuestRewards, qid)
  if ok and type(ids) == "table" and #ids > 0 then return ids, type(names) == "table" and names or {} end
  return nil
end
local function CachedName(id)
  if not GetItemInfo then return nil end
  local ok, n = pcall(GetItemInfo, id)
  return ok and type(n) == "string" and not secret(n) and n or nil
end
local function Loose(s) return (s:lower():gsub("[%p%s]", "")) end
-- Item name -> id from LibForeverData's item list (built once, on the first name neither source
-- matched): a reward known only by its name still gets its real icon, quality and comparison.
local libItemIds
local function LibItemId(n)
  if libItemIds == nil then
    local lib = Lib()
    -- LibForeverData not loaded yet: ask again next time (never remember "no list" for good)
    if not lib then return nil end
    libItemIds = false
    if lib and type(lib.Ids) == "function" and type(lib.Name) == "function" then
      local ok, ids = pcall(lib.Ids, "item")
      if ok and type(ids) == "table" then
        libItemIds = {}
        for _, id in ipairs(ids) do
          local okN, nm = pcall(lib.Name, "item", id)
          if okN and type(nm) == "string" and nm ~= "" then
            local k = nm:lower()
            if not libItemIds[k] then libItemIds[k] = id end
          end
        end
      end
    end
  end
  return libItemIds and libItemIds[n:lower()] or nil
end
local function Rewards(qid, q)
  if rewardCache[qid] then return rewardCache[qid] end
  local out = {}
  local lib = Lib()
  if lib and type(lib.Quest) == "function" and qid > 0 then
    local ok, rec = pcall(lib.Quest, qid)
    if ok and type(rec) == "table" and type(rec.rewards) == "table" then
      for _, rw in ipairs(rec.rewards) do
        if type(rw) == "table" and (rw.kind == "item" or rw.kind == "choice") and rw.id then
          out[#out + 1] = { id = rw.id, choice = rw.kind == "choice", count = rw.count }
        end
      end
    end
  end
  if #out == 0 then
    local ids, names = GearRewards(qid)
    ids, names = ids or {}, names or {}
    local ri = q.ri or {}
    -- by the exact name (any case), then loosely (no punctuation, no spaces): Gear's English name
    -- and the client's cached name both count
    local byName, byLoose, used = {}, {}, {}
    for _, id in ipairs(ids) do
      for _, n in ipairs({ names[id], CachedName(id) }) do
        if type(n) == "string" then
          byName[n:lower()] = byName[n:lower()] or id
          local lo = Loose(n)
          if lo ~= "" then byLoose[lo] = byLoose[lo] or id end
        end
      end
    end
    local choice = q.rc == true
    local unmatched = 0
    for i, n in ipairs(ri) do
      local id = byName[n:lower()]
      if id and used[id] then id = nil end
      if not id then id = byLoose[Loose(n)]; if id and used[id] then id = nil end end
      if id then used[id] = true else unmatched = unmatched + 1 end
      out[i] = { id = id, name = n, choice = choice }
    end
    -- as many names as ids: a name still unmatched takes the id at its place
    if unmatched > 0 and #ri == #ids then
      for i, rw in ipairs(out) do
        local id = ids[i]
        if not rw.id and not used[id] then rw.id = id; used[id] = true; unmatched = unmatched - 1 end
      end
    end
    -- still nameless of an id: LibForeverData's item list
    if unmatched > 0 then
      for _, rw in ipairs(out) do
        if not rw.id and rw.name then
          local id = LibItemId(rw.name)
          if id and not used[id] then rw.id = id; used[id] = true; unmatched = unmatched - 1 end
        end
      end
    end
    -- Gear's other ids follow, unless a name is still unmatched and Gear has no more ids than our
    -- names (that id is most likely the same item under another name: it would show twice)
    if unmatched == 0 or #ids > #ri then
      for _, id in ipairs(ids) do
        if not used[id] then used[id] = true; out[#out + 1] = { id = id, name = names[id], choice = choice } end
      end
    end
  end
  rewardCache[qid] = out
  return out
end
-- for the tests: the rewards of a quest, read again (and the item list built again) when fresh
ns.SummaryRewards = function(qid, q, fresh)
  if fresh then rewardCache[qid] = nil; libItemIds = nil end
  return Rewards(qid, q)
end
-- How many items the quest gives you (one for a reward of your choice).
local function ItemCount(qid, q)
  local n, choice = 0, false
  for _, rw in ipairs(Rewards(qid, q)) do if rw.choice then choice = true else n = n + 1 end end
  return n + (choice and 1 or 0)
end

-- Per render (wiped by Render): the item facts and the comparisons, read once even when the totals
-- and the rows both ask. pendingItems: ids whose data has not come yet (GET_ITEM_INFO_RECEIVED for
-- one of them renders again); pendingName: a reward known by name only, or an item you wear, is
-- not cached yet (any item arriving renders again).
-- requestedItems / failedItems (kept for the session): an id is asked for at most once, and one
-- the server does not know (GET_ITEM_INFO_RECEIVED with success false) is never asked again nor
-- waited for, so an unknown id cannot make the summary render over and over.
local infoCache, upCache, bestCache = {}, {}, {}
local pendingItems, pendingName = {}, false
local requestedItems, failedItems = {}, {}
local function ResetRenderCaches()
  wipe(infoCache); wipe(upCache); wipe(bestCache)
end

-- icon, link, quality of a reward (the question mark until the item is cached)
local function ItemInfo(rw)
  local key = rw.id or rw.name
  local c = key and infoCache[key]
  if c then return c[1], c[2], c[3] end
  local icon, link, quality
  -- the icon without waiting for the server: GetItemInfoInstant reads the client's own files
  local function IconOf(id)
    if not id then return nil end
    if C_Item and C_Item.GetItemInfoInstant then
      local ok, _, _, _, _, ic = pcall(C_Item.GetItemInfoInstant, id)
      if ok and ic and not secret(ic) then return ic end
    end
    if GetItemInfoInstant then
      local ok, _, _, _, _, ic = pcall(GetItemInfoInstant, id)
      if ok and ic and not secret(ic) then return ic end
    end
    local ok, ic = pcall(function() return (C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(id)) or (GetItemIcon and GetItemIcon(id)) end)
    return ok and ic or nil
  end
  icon = IconOf(rw.id)
  -- an id this client does not know (QuestieDB's), or no id: LibForeverData's id for the name
  if not icon and rw.name then
    local alt = LibItemId(rw.name)
    if alt and alt ~= rw.id then
      icon = IconOf(alt)
      if not icon and not requestedItems[alt] and C_Item and C_Item.RequestLoadItemDataByID then
        requestedItems[alt] = true; pendingItems[alt] = true
        pcall(C_Item.RequestLoadItemDataByID, alt)
      end
    end
  end
  if GetItemInfo and key then
    local ok, _, l, qu, _, _, _, _, _, _, tex = pcall(GetItemInfo, key)
    if ok then link = type(l) == "string" and not secret(l) and l or nil; quality = num(qu); icon = icon or tex end
  end
  if not quality and rw.id and C_Item and C_Item.GetItemQualityByID then
    local ok, qu = pcall(C_Item.GetItemQualityByID, rw.id)
    if ok then quality = num(qu) end
  end
  if not link then
    if rw.id then
      if not failedItems[rw.id] then
        pendingItems[rw.id] = true
        if not requestedItems[rw.id] then
          requestedItems[rw.id] = true
          if C_Item and C_Item.RequestLoadItemDataByID then pcall(C_Item.RequestLoadItemDataByID, rw.id) end
        end
      end
    else pendingName = true end
  end
  -- an id this server does not know (QuestieDB's), the name still known: LibForeverData's id for it
  if not icon and rw.name and (not rw.id or failedItems[rw.id]) then
    local alt = LibItemId(rw.name)
    if alt and alt ~= rw.id then
      local ok, ic = pcall(function() return (C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(alt)) or (GetItemIcon and GetItemIcon(alt)) end)
      if ok and ic then icon = ic end
      if not quality and C_Item and C_Item.GetItemQualityByID then
        local okQ, qu = pcall(C_Item.GetItemQualityByID, alt)
        if okQ then quality = num(qu) end
      end
    end
  end
  icon = icon or "Interface\\Icons\\INV_Misc_QuestionMark"
  if key then infoCache[key] = { icon, link, quality } end
  return icon, link, quality
end

-- The quality colour of an item's border (common and poor keep the card edge).
local function QualityColor(quality)
  if not quality or quality < 2 then return nil end
  if GetItemQualityColor then
    local ok, r, g, b = pcall(GetItemQualityColor, quality)
    if ok and num(r) and num(g) and num(b) then return { r, g, b, 1 } end
  end
  local c = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality]
  if type(c) == "table" and c.r then return { c.r, c.g, c.b, 1 } end
  return nil
end

-- The gear check of the Writs module (no WL Helper Gear): { up, text }.
local function Upgrade(link)
  local WP = ns.Writs and ns.Writs.WP
  if not (link and WP and WP.UpgradeCheck) then return nil end
  local ok, r = pcall(WP.UpgradeCheck, link)
  if ok and type(r) == "table" and r.up then return r.text or "" end
  return nil
end

local function UpMin()
  local m = WLWritsDB and num(WLWritsDB.upgradeMin)
  return m and m > 0 and m or 1
end

-- Is a reward an upgrade for your spec? { up, pct, empty, text, rank, score }: rank orders the
-- choices (higher is better; nil when the item is not for you or can't be read), score is the
-- item's score for your spec when there is no comparison. WLHelperGear.Compare first (percent
-- against what you wear), else the Writs gear check.
-- The level a quest's rewards are judged at: the quest's level (else its required level) when it
-- is above yours, since you only get its items once you reach it.
local function RewardLevel(q)
  local ql = q and (num(q.l) or num(q.r)) or nil
  return math.max(Level(), ql or 0)
end

-- The gain shown under the icon is capped (a 3-digit gain would run into the next icon); the
-- tooltip keeps the exact figure.
local LABEL_MAX = 99
local NOUP = {}
local function UpInfo(rw, lvl)
  local _, link = ItemInfo(rw)
  local what = link or rw.id
  if not what then return NOUP end
  lvl = lvl or Level()
  local key = tostring(what) .. "@" .. lvl
  local c = upCache[key]
  if c then return c end
  local res = {}
  local G = Gear()
  if G then
    local ok, r = pcall(G.Compare, what, lvl)
    if ok and type(r) == "table" then
      if r.unknown then pendingName = true end   -- what you wear is not read yet: any item may be it
      local usable = r.canUse == true and not r.blocked and not r.unscored and not r.unknown and not r.equipped
      local pct = num(r.pct)
      if usable and r.empty then res.up, res.empty, res.rank = true, true, math.huge
      elseif usable and pct then
        res.rank = num(r.pctExact) or pct
        if pct >= UpMin() then res.up, res.pct = true, pct end
      end
    end
    -- a choice still needs a rank when the comparison has none: the item's score for your spec
    if res.rank == nil and rw.choice and type(G.Score) == "function" then
      local ok2, sc, d = pcall(G.Score, what, lvl)
      if ok2 and num(sc) and sc > 0 and type(d) == "table" and d.canUse == true then res.score = sc end
    end
  elseif link then
    local t = Upgrade(link)
    if t then res.up, res.text = true, t end
  end
  if res.up and not res.text then
    if res.empty then res.text = L.SUM_UP_EMPTY
    else
      local p = math.floor(res.pct + 0.5)
      res.text = L.SUM_UP_PCT:format(p)
      if p > LABEL_MAX then res.short = L.SUM_UP_PCT:format(LABEL_MAX) end
    end
  end
  upCache[key] = res
  return res
end

-- The best of a quest's rewards to choose from for you (its index in the list), or nil: the best
-- comparison, else the best score; nil with fewer than two choices or nothing for you.
local function BestChoice(qid, list, lvl)
  local c = bestCache[qid]
  if c ~= nil then return c or nil end
  local n, best, bestRank, bestScore = 0, nil, nil, nil
  for i, rw in ipairs(list) do
    if rw.choice then
      n = n + 1
      local u = UpInfo(rw, lvl)
      if u.rank and (not bestRank or u.rank > bestRank) then best, bestRank = i, u.rank
      elseif not bestRank and u.score and (not bestScore or u.score > bestScore) then best, bestScore = i, u.score end
    end
  end
  if n < 2 then best = nil end
  bestCache[qid] = best or false
  return best
end

-- How many of a quest's items are upgrades (one at most for the rewards to choose from).
local function UpCount(qid, q)
  local n, choiceUp, lvl = 0, false, RewardLevel(q)
  for _, rw in ipairs(Rewards(qid, q)) do
    if UpInfo(rw, lvl).up then if rw.choice then choiceUp = true else n = n + 1 end end
  end
  return n + (choiceUp and 1 or 0)
end

-- XP and money of one quest: the data first, LibForeverData (live) when the data has none.
local function LibQuest(qid)
  local lib = Lib()
  if not (lib and qid > 0) then return nil end
  local ok, rec = pcall(lib.Get, "quest", qid)
  return ok and type(rec) == "table" and rec or nil
end
local function QuestXP(qid)
  local q = ns.Q[qid]
  if q and num(q.xp) then return q.xp end
  local rec = LibQuest(qid)
  return rec and num(rec.xp) or 0
end
-- "1g 80s", "65s", "7s  •  Gadgetzan +100": the money part only, in copper
local function QuestMoney(qid)
  local q = ns.Q[qid]
  if q and type(q.rw) == "string" then
    local seg = q.rw:match("^([%dgsc ]+)")
    local c = 0
    if seg then
      for n, u in seg:gmatch("(%d+)([gsc])") do
        n = tonumber(n)
        c = c + (u == "g" and n * 10000 or u == "s" and n * 100 or n)
      end
    end
    if c > 0 then return c end
    return 0
  end
  local rec = LibQuest(qid)
  return rec and num(rec.money) and rec.money > 0 and rec.money or 0
end
ns.QuestMoney, ns.QuestXP = QuestMoney, QuestXP

-- No more XP: the level cap, or XP turned off (the rule of Bosses.lua).
local function AtCap()
  if IsXPUserDisabled then
    local ok, v = pcall(IsXPUserDisabled)
    if ok and v == true then return true end
  end
  local maxL = 60
  if GetMaxPlayerLevel then
    local ok, mx = pcall(GetMaxPlayerLevel)
    maxL = ok and num(mx) or maxL
  end
  return Level() >= maxL
end
-- XP the player really gets for a quest at level plvl (vanilla rule): full up to 5 levels above
-- the quest, then 80/60/40/20 %, then 10 %; rounded like the server. 0 at the level cap.
-- If the Forever server differs on a grey quest, only XP_CUT and RoundXP change.
local XP_CUT = { [6] = 0.8, [7] = 0.6, [8] = 0.4, [9] = 0.2 }
local function RoundXP(x)
  local step = x <= 100 and 5 or x <= 500 and 10 or x <= 1000 and 25 or 50
  return math.floor(x / step + 0.5) * step
end
-- returns got, base, diff (player level minus quest level)
local function XPFor(qid, plvl)
  local base = QuestXP(qid)
  if base <= 0 or AtCap() then return 0, base, 0 end
  local q = ns.Q[qid]
  local ql = q and num(q.l)
  if not ql then return base, base, 0 end
  local d = (plvl or Level()) - ql
  if d <= 5 then return base, base, d end
  return RoundXP(base * (XP_CUT[d] or 0.1)), base, d
end
ns.QuestXPFor = XPFor

-- Difficulty band of a quest level for the player: "red", "orange", "yellow", "green", "grey".
-- The game's own colour table first (GetQuestDifficultyColor returns one of its entries), else
-- the same thresholds.
local BAND_OF = { impossible = "red", verydifficult = "orange", difficult = "yellow", standard = "green", trivial = "grey" }
local function Band(ql, plvl)
  ql = num(ql)
  if not ql then return nil end
  if GetQuestDifficultyColor and type(QuestDifficultyColors) == "table" then
    local ok, c = pcall(GetQuestDifficultyColor, ql)
    if ok and c then
      for k, v in pairs(QuestDifficultyColors) do if v == c and BAND_OF[k] then return BAND_OF[k] end end
    end
  end
  local d = ql - plvl
  if d >= 5 then return "red" elseif d >= 3 then return "orange" elseif d >= -2 then return "yellow" end
  local g
  if GetQuestGreenRange then
    local ok, v = pcall(GetQuestGreenRange)
    g = ok and num(v) or nil
  end
  g = g or (plvl <= 5 and 5 or plvl < 40 and 5 + math.floor(plvl / 10) or 1 + math.floor(plvl / 5))
  return (-d <= g) and "green" or "grey"
end

local function Money(c)
  local S = SW()
  if S.Money then return S.Money(c) end
  return tostring(c)
end

-- "(environ 80 % d'un niveau)", "(environ 1,3 niveau)", "(about 2.4 levels)": the share of the
-- XP bar; nil when the bar is not readable or at the level cap.
local function LevelShare(xp)
  if not (xp and xp > 0) or AtCap() or not UnitXPMax then return nil end
  local ok, mx = pcall(UnitXPMax, "player")
  mx = ok and num(mx) or nil
  if not mx or mx <= 0 then return nil end
  local r = xp / mx
  if r < 1 then return L.SUM_LVPCT:format(math.max(1, math.floor(r * 100 + 0.5))) end
  local s = ("%.1f"):format(r):gsub("%.0$", "")
  if ns.lang == "fr" then s = s:gsub("%.", ",") end
  local one
  if ns.lang == "fr" then one = r < 2 else one = s == "1" end
  return (one and L.SUM_LVN1 or L.SUM_LVN):format(s)
end

-- "Bob, Cara et Dino"
local function JoinNames(list)
  if #list <= 1 then return list[1] or "" end
  return table.concat(list, ", ", 1, #list - 1) .. L.SUM_AND .. list[#list]
end

-- Elite: an objective's target is elite (rank 1 or 2), read live from LibForeverData; else the
-- data's own flags (q.elite, o.elite).
local eliteCache = {}
local function IsElite(qid, q)
  if eliteCache[qid] ~= nil then return eliteCache[qid] end
  local res = q.elite and true or false
  for _, o in ipairs(q.o or {}) do if o.elite then res = true end end
  local lib = Lib()
  if not res and lib and qid > 0 then
    local rec = LibQuest(qid)
    local function rank(id)
      local ok, n = pcall(lib.Get, "npc", id)
      return ok and type(n) == "table" and num(n.rank) or nil
    end
    for _, ob in ipairs(rec and type(rec.objectives) == "table" and rec.objectives or {}) do
      if ob.kind == "npc" and ob.target then
        local r = rank(ob.target)
        if r == 1 or r == 2 then res = true end
      elseif ob.kind == "item" and ob.target then
        -- an item dropped only by elites (the first three sources)
        local ok, it = pcall(lib.Get, "item", ob.target)
        local drops = ok and type(it) == "table" and it.npcDrops
        if type(drops) == "table" and #drops > 0 then
          local all = true
          for i = 1, math.min(3, #drops) do local r = rank(drops[i]); if not (r == 1 or r == 2) then all = false end end
          if all then res = true end
        end
      end
      if res then break end
    end
  end
  eliteCache[qid] = res
  return res
end

-- A note of ForeverDungeonJournal about a quest, read live when that addon is loaded (credited).
local function FDJDetails(qid)
  if not (ns.IsLoaded and ns.IsLoaded("ForeverDungeonJournal")) then return nil end
  local F = _G.ForeverDungeonJournal_NS or _G.FDJ
  local det = type(F) == "table" and type(F.QUEST_PREREQ_DETAILS) == "table" and F.QUEST_PREREQ_DETAILS[qid]
  return type(det) == "table" and det or nil
end
local function str(t) return type(t) == "string" and not secret(t) and t ~= "" and t or nil end
-- its note (or objective), then its warning when it has one
local function FDJNote(qid)
  local det = FDJDetails(qid)
  if not det then return nil end
  local t = str(det.note) or str(det.objective) or str(det.description)
  local w = str(det.warning)
  if t and w and w ~= t then return t .. " " .. w end
  return t or w
end
-- its map spot ({ mapID, x, y in 0-1, label }) as a GPS point, for a link with no place of its own
local function FDJPoint(qid, fallback)
  local det = FDJDetails(qid)
  local m = det and det.map
  if type(m) ~= "table" then return nil end
  local id, x, y = num(m.mapID), num(m.x), num(m.y)
  if not (id and x and y) then return nil end
  if x <= 1 and y <= 1 then x, y = x * 100, y * 100 end
  return { id, x, y, str(m.targetName) or str(m.label) or fallback }
end
-- LibForeverData's steps for a quest (live, credited in the tooltip)
local function LibSteps(qid)
  local lib = Lib()
  if not (lib and type(lib.Steps) == "function" and qid > 0) then return nil end
  local ok, steps = pcall(lib.Steps, qid)
  if not (ok and type(steps) == "table" and #steps > 0) then return nil end
  local out = {}
  for i, s in ipairs(steps) do
    if i > 4 then break end
    if type(s) == "table" and type(s.text) == "string" and s.text ~= "" then out[#out + 1] = s.text end
  end
  return #out > 0 and out or nil
end

-- The dungeons each main quest belongs to (for "the chain passes through another dungeon").
local qDungeons
local function DungeonsOf(qid)
  if not qDungeons then
    qDungeons = {}
    for k, d in pairs(ns.D) do
      if not d.cq then
        for _, id in ipairs(d.q or {}) do
          qDungeons[id] = qDungeons[id] or {}
          table.insert(qDungeons[id], k)
        end
      end
    end
  end
  return qDungeons[qid]
end

-- Everything the summary says about one quest of one dungeon.
local function Info(qid, dkey, ctx)
  local q = ns.Q[qid]
  local log = ctx.log
  local st = QState(log, qid)
  local pre = ns.QuestPreInfo(qid, log, ctx.cls)
  local low = LowLevel(log, q, st, pre, ctx.lvl)
  local maxL = q.l or q.r or 0
  local xpGot, xpBase, xpDiff = XPFor(qid, ctx.lvl)
  local chainXP = xpGot
  local other
  for _, pid in ipairs(pre.chain) do
    local pq = ns.Q[pid]
    if pq and (pq.l or 0) > maxL then maxL = pq.l end
    chainXP = chainXP + (XPFor(pid, ctx.lvl))
    if not other then
      for _, k in ipairs(DungeonsOf(pid) or {}) do
        local dk = ns.D[dkey]
        if k ~= dkey and not (dk and dk.inst and ns.D[k].inst == dk.inst) then other = k; break end
      end
    end
  end
  local high = (st == "none") and (low ~= nil or maxL > ctx.lvl + HIGH_GAP) or false
  return {
    q = q, st = st, pre = pre, low = low, maxL = maxL, high = high, other = other,
    xp = xpGot, xpBase = xpBase, xpDiff = xpDiff, band = Band(q.l, ctx.lvl),
    money = QuestMoney(qid), chainN = pre.total + 1, chainXP = chainXP,
    elite = IsElite(qid, q),
  }
end

-- Ticks: WLDTDB.off[qid] leaves a quest out of the route (the engine reads it). A quest the
-- player never ticked by hand follows the default: ticked when its level allows it and its chain
-- does not go more than 5 levels above the player (WLDTDB.offPick remembers the hand-made ones).
local function IsOff(qid) return WLDTDB.off and WLDTDB.off[qid] and true or false end
-- The hand-made choices. Once, for a player who unticked quests before offPick existed: every quest
-- already left out was left out by hand (the defaults must not tick it back).
function ns.OffPick()
  WLDTDB.off = WLDTDB.off or {}
  if not WLDTDB.offPickV then
    WLDTDB.offPick = WLDTDB.offPick or {}
    for qid in pairs(WLDTDB.off) do WLDTDB.offPick[qid] = true end
    WLDTDB.offPickV = 1
  end
  WLDTDB.offPick = WLDTDB.offPick or {}
  return WLDTDB.offPick
end
local function ApplyDefault(qid, inf)
  local pick = ns.OffPick()
  if pick[qid] then return false end
  if inf.st == "done" then return false end
  local want = inf.high or nil
  if WLDTDB.off[qid] == want then return false end
  WLDTDB.off[qid] = want
  return true
end


-- =====================================================================
--  Window
-- =====================================================================
local f
local Render

-- The guide's route runs on exactly these dungeons.
local function RouteRuns(keys)
  if not (ns.route and ns.frame and keys and #keys > 0 and WLDTDB.sel) then return false end
  local n = 0
  for _, k in ipairs(keys) do if not WLDTDB.sel[k] then return false end; n = n + 1 end
  for k, v in pairs(WLDTDB.sel) do if v and ns.D[k] then n = n - 1 end end
  return n == 0
end

-- The guide's route runs on some picked dungeons (other than these, when RouteRuns is false).
local function RouteElsewhere()
  if not (ns.route and ns.frame and WLDTDB.sel) then return false end
  for k, v in pairs(WLDTDB.sel) do if v and ns.D[k] then return true end end
  return false
end

-- The running route walks these dungeons through (WLDTDB.run) and still has a step to do.
local function RunGoing(keys)
  local any = false
  for _, k in ipairs(keys) do if WLDTDB.run and WLDTDB.run[k] then any = true end end
  if not any or not ns.route or not ns.IsStepDone then return false end
  local log = ns.LogEntries and ns.LogEntries() or {}
  for i = 1, #ns.route.steps do if not ns.IsStepDone(log, i) then return true end end
  return false
end

local function RouteHas(qid)
  local _, cls = UnitClass("player")
  for k in pairs(WLDTDB.sel or {}) do
    for _, x in ipairs(ns.D[k] and ns.D[k].q or {}) do if x == qid then return true end end
    for _, x in ipairs(ns.DungeonQuests(k, cls)) do
      for _, pid in ipairs(ns.FullChain(x, cls) or {}) do if pid == qid then return true end end
    end
  end
  return false
end

-- Ticks or unticks a quest. Only the quest itself is written: the engine reads `off` for a
-- dungeon's main quests and brings their prerequisites with them, so a chain row's links follow
-- it. Writing the links would drop a link that is also another dungeon's main quest from that route.
-- The running route follows a tick, an untick or a new default, quietly and once for a burst of
-- clicks: a replan (the done steps stay on top, the step you look at stays), else the saved order
-- rebuilt as a /reload does. No chat line (the main button already says "Update the route").
local rebuildPending = false
local function RebuildRoute()
  rebuildPending = false
  if not (ns.route and ns.frame) then return end
  -- the replan's "Next step" / "route finished" announces are muted: the player is clicking here
  ns.muteAnnounce = true
  local ok, _, rebuilt = pcall(ns.Replan)
  ns.muteAnnounce = nil
  if ok and rebuilt then return end
  if not ns.Assemble then return end
  local okA = pcall(ns.Assemble, false)
  if not okA then return end
  local fr = ns.frame
  fr.auto, fr.sig = nil, nil
  if fr.view and ns.route and fr.view > #ns.route.steps then fr.view = nil end
  if ns.Refresh then ns.Refresh(true) end
end
local function RebuildRouteSoon()
  if rebuildPending then return end
  rebuildPending = true
  if C_Timer and C_Timer.After then C_Timer.After(0.3, RebuildRoute) else RebuildRoute() end
end
ns.SummaryRebuildRoute = RebuildRouteSoon

local function SetOff(qid, off)
  if not qid then return end
  local pick = ns.OffPick()
  WLDTDB.off[qid] = off and true or nil
  pick[qid] = true
  -- the running route follows; the main button then says "Update the route"
  if f then f.changed = true end
  if PlaySound then PlaySound(SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or 856) end
  if ns.route and ns.frame and RouteHas(qid) then RebuildRouteSoon() end
  if ns.RenderPicker then ns.RenderPicker() end
  Render()
end
ns.SummarySetOff = SetOff

-- The quest of a row to share: the quest itself when it is in your log, else the link of its
-- chain that is (the group does the chain together).
local function ShareTarget(qid, pre, log)
  local function ok(id)
    local q = ns.Q[id]
    return log[id] and q and q.sh ~= false and (not ns.Pushable or ns.Pushable(id, log[id]))
  end
  if ok(qid) then return qid end
  for _, pid in ipairs(pre and pre.chain or {}) do if ok(pid) then return pid end end
end

-- =====================================================================
--  Group: each member's state for a quest (WL Helper's data first, then ns.PartyQuests)
-- =====================================================================
-- state -> word (tooltip), HD icon ("?" text when nil), colour token, a second check (ready)
local CELL = {
  on = { "SUM_G_ON", "check", "ok" }, ready = { "SUM_G_READY", "check", "gold", true }, done = { "SUM_G_DONE", "check", "faint" },
  take = { "SUM_G_TAKE", "warning", "warn" }, pre = { "SUM_G_PRE", "close", "bad" }, low = { "SUM_G_LOW", "close", "bad" },
  na = { "SUM_G_NA", "close", "bad" }, invalid = { "SUM_G_INVALID", "close", "bad" }, declined = { "SUM_G_DECLINED", "warning", "warn" },
  full = { "SUM_G_FULL", "warning", "warn" }, busy = { "SUM_G_BUSY", "warning", "warn" }, far = { "SUM_G_FAR", "warning", "warn" },
  sent = { "SUM_G_SENT", "clock", "muted" }, unknown = { "SUM_G_UNKNOWN", nil, "faint" },
}
-- state -> what it means for the group: has it, turned in, cannot take it, lacks it, unknown
local BUCKET = { on = "has", ready = "has", done = "done", low = "cannot", pre = "cannot", invalid = "cannot", na = "cannot",
  take = "missing", declined = "missing", full = "missing", busy = "missing", far = "missing", sent = "unknown", unknown = "unknown" }
-- a WL Helper state -> the reason's key in ns.PartyQuests' strings
local PQ_TEXT = { on = "ON", ready = "READY", done = "DONE", take = "TAKE", na = "NA", invalid = "INVALID", declined = "DECLINED",
  full = "FULL", busy = "BUSY", far = "FAR", sent = "SENT" }

local function PQText(key, ...)
  local P = ns.PartyQuests
  local t = P and P.STR and ((GetLocale and GetLocale() == "frFR") and P.STR.fr or P.STR.en)
  local f = t and t[key]
  if type(f) ~= "string" then return nil end
  if select("#", ...) > 0 then local ok, v = pcall(string.format, f, ...); return ok and v or f end
  return f
end

-- The other members, in party / raid order: { name, unit, class, level }.
local function Members()
  if not ns.GroupMembers then return {} end
  local out = {}
  for _, m in ipairs(ns.GroupMembers()) do
    local lvl = m.unit and UnitLevel and num(UnitLevel(m.unit))
    if lvl and lvl <= 0 then lvl = nil end
    out[#out + 1] = { name = m.name, unit = m.unit, class = m.class, level = lvl }
  end
  return out
end

local function ClassColor(cls)
  if not cls then return T.fg end
  local _, c = ns.ClassInfo(cls)
  return c or T.fg
end

-- A member's state for a quest -> state, reason (words), source, missing prerequisite. WL Helper's
-- data wins when it has the quest; then the game's answers (ns.PartyQuests: IsUnitOnQuest, the
-- answers to a share); then a share answer Sync.lua heard; then the reason from the data.
local function MemberState(m, qid, dkey)
  local name = m.name
  local ms, mpid, msrc = "unknown", nil, nil
  if ns.MemberQuest then ms, mpid, msrc = ns.MemberQuest(name, qid, dkey) end
  local helper = ns.HasHelper and ns.HasHelper(name)
  local P = ns.PartyQuests
  local ps, pwhy, psrc, ppid
  if P and P.State then
    local ok, a, b, c, d = pcall(P.State, name, qid, dkey)
    if ok and type(a) == "string" then ps, pwhy, psrc, ppid = a, b, c, d end
  end
  local function why(st, pid)
    if st == "unknown" and helper then return L.SUM_G_WAIT_TT:format(name) end
    if ps == st and pwhy then return pwhy end
    if st == "pre" and pid then return PQText("PRE", ns.QName(pid)) or L.SUM_G_PRE_TT:format(ns.QName(pid)) end
    if st == "low" then
      local need = ns.Q[qid] and ns.Q[qid].r
      if need then return (m.level and PQText("LOW", m.level, need)) or PQText("LOW_NOLVL", need) or L.SUM_G_LOW end
    end
    if st == "unknown" then return L.SUM_G_UNKNOWN_TT:format(name) end
    return (PQ_TEXT[st] and PQText(PQ_TEXT[st])) or L[(CELL[st] or CELL.unknown)[1]]
  end
  if msrc == "sync" then return ms, why(ms, mpid), "sync", mpid end
  if ps and ps ~= "unknown" and (psrc == "push" or psrc == "game" or psrc == "sync") then return ps, pwhy or why(ps, ppid), psrc, ppid end
  -- Sync.lua's "sent" never expires: when ns.PartyQuests answers, its own "sent" (60 s) is the one
  if msrc == "push" and ms ~= "unknown" and not (ms == "sent" and ps) then return ms, why(ms, mpid), "push", mpid end
  if ps then return ps, why(ps, ppid), psrc, ppid end
  return ms, why(ms, mpid), msrc, mpid
end
ns.SummaryMemberState = MemberState

-- Does sharing a row's quest still help someone? Members who have not got it yet (to take, no
-- answer, declined, log full, busy, too far; or a missing prerequisite when the share is that
-- prerequisite). Returns the yes and the names.
local NEED_SHARE = { take = true, unknown = true, declined = true, full = true, busy = true, far = true }
local function NeedsShare(qid, shareId, dkey, ctx)
  local who = {}
  for _, m in ipairs(ctx.members or {}) do
    local s = MemberState(m, qid, dkey)
    if NEED_SHARE[s] or (s == "pre" and shareId ~= qid) then who[#who + 1] = m.name end
  end
  return #who > 0, who
end

-- =====================================================================
--  Widgets
-- =====================================================================
local function MakeReward(parent)
  local b = CreateFrame("Button", nil, parent)
  b:SetSize(RW_SIZE, RW_SIZE)
  b.wlOwned = true
  b.tex = b:CreateTexture(nil, "ARTWORK"); b.tex:SetPoint("TOPLEFT", 1, -1); b.tex:SetPoint("BOTTOMRIGHT", -1, 1)
  b.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  -- 1 px border in the item's quality colour (card edge for common items)
  b.edge = ns.Outline(b, T.cardEdge)
  -- the best of the rewards to choose from: a gold ring 2 px outside the icon
  b.ring = CreateFrame("Frame", nil, b); b.ring:SetPoint("TOPLEFT", -2, 2); b.ring:SetPoint("BOTTOMRIGHT", 2, -2)
  ns.Outline(b.ring, T.gold); b.ring:Hide()
  -- an upgrade: the green gain under the icon ("+12 %")
  b.pct = ns.Text(b, ns.F.label, T.ok, true); b.pct:SetPoint("TOP", b, "BOTTOM", 0, -3); b.pct:Hide()
  -- an upgrade also reads on the icon itself: a green arrow on a dark chip in its top-right corner
  b.upChip = b:CreateTexture(nil, "OVERLAY", nil, 1); b.upChip:SetSize(14, 14); b.upChip:SetPoint("TOPRIGHT", 3, 3)
  b.upChip:SetColorTexture(0.04, 0.05, 0.06, 0.92); b.upChip:Hide()
  b.upArrow = ns.Icon(b, "arrow_up", 12, "OVERLAY", T.ok); b.upArrow:SetPoint("CENTER", b.upChip, "CENTER", 0, 0)
  if b.upArrow.SetDrawLayer then b.upArrow:SetDrawLayer("OVERLAY", 2) end
  b.upArrow:Hide()
  if b.pct.SetWordWrap then b.pct:SetWordWrap(false) end
  -- Naowh's BiS list ranks the item for your spec: a star (BiS) or "2" (second choice) on a dark
  -- chip in the icon's top-left corner, its colour from NaowhBiS; the words under the icon when
  -- no gain sits there, and in the tooltip
  b.bisChip = b:CreateTexture(nil, "OVERLAY", nil, 1); b.bisChip:SetSize(14, 14); b.bisChip:SetPoint("TOPLEFT", -3, 3)
  b.bisChip:SetColorTexture(0.04, 0.05, 0.06, 0.92); b.bisChip:Hide()
  b.bisStar = b:CreateTexture(nil, "OVERLAY", nil, 2); b.bisStar:SetSize(12, 12); b.bisStar:SetPoint("CENTER", b.bisChip, "CENTER", 0, 0)
  b.bisStar:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_1"); b.bisStar:Hide()
  b.bisTwo = ns.Text(b, ns.F.foot, T.fg, true); b.bisTwo:SetPoint("CENTER", b.bisChip, "CENTER", 0, 0); b.bisTwo:SetText("2"); b.bisTwo:Hide()
  if b.bisTwo.SetDrawLayer then b.bisTwo:SetDrawLayer("OVERLAY", 3) end
  b:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:ClearLines()
    local shown = false
    if self.id and GameTooltip.SetItemByID then shown = pcall(GameTooltip.SetItemByID, GameTooltip, self.id)
    elseif self.link and GameTooltip.SetHyperlink then shown = pcall(GameTooltip.SetHyperlink, GameTooltip, self.link) end
    if not shown then GameTooltip:AddLine(self.name or "?", T.fg[1], T.fg[2], T.fg[3], true) end
    if self.choice then GameTooltip:AddLine(L.OV_CHOICE, T.muted[1], T.muted[2], T.muted[3], true) end
    if self.best then GameTooltip:AddLine(L.SUM_BEST, T.gold[1], T.gold[2], T.gold[3], true) end
    if self.bisText and not (shown and ns.BisNaowhTip and ns.BisNaowhTip(self.id or self.link, self.bisRank)) then GameTooltip:AddLine(L.BIS_TT:format(self.bisText), self.bisR or 1, self.bisG or 0.5, self.bisB or 0, true) end
    if self.upText then GameTooltip:AddLine(L.OV_UPGRADE .. (self.upText ~= "" and (" " .. self.upText) or ""), T.ok[1], T.ok[2], T.ok[3], true) end
    if self.upEmpty then GameTooltip:AddLine(L.SUM_UP_EMPTY_TT, T.muted[1], T.muted[2], T.muted[3], true) end
    if self.link then GameTooltip:AddLine(L.TT_SHIFT_LINK, (T.hint or T.muted)[1], (T.hint or T.muted)[2], (T.hint or T.muted)[3], true) end
    GameTooltip:Show()
  end)
  b:SetScript("OnLeave", function() GameTooltip:Hide() end)
  b:SetScript("OnClick", function(self)
    if self.link and HandleModifiedItemClick then pcall(HandleModifiedItemClick, self.link) end
  end)
  return b
end

-- One reward icon: the item, its quality border, the upgrade (the gain), the best choice.
-- Returns true when it shows a line under the icon.
local function FillReward(b, rw, best, lvl)
  local icon, link, quality = ItemInfo(rw)
  local u = UpInfo(rw, lvl)
  b.id, b.name, b.link, b.choice, b.best = rw.id, rw.name, link, rw.choice, best
  b.tex:SetTexture(icon)
  b.quality = quality
  b.edge(QualityColor(quality) or T.cardEdge)
  b.ring:SetShown(best == true)
  b.upText, b.upEmpty = u.up and (u.text or "") or nil, u.empty == true
  local rank, bisText, br, bg, bb, bisShort
  if ns.BisBadge then rank, bisText, br, bg, bb, bisShort = ns.BisBadge(link or rw.id, 11) end
  b.bisRank, b.bisText, b.bisR, b.bisG, b.bisB = rank, bisText, br, bg, bb
  b.bisChip:SetShown(rank ~= nil)
  b.bisStar:SetShown(rank == 1)
  b.bisTwo:SetShown(rank == 2)
  if rank == 2 then b.bisTwo:SetTextColor(br, bg, bb) end
  if u.up then
    b.pct:SetTextColor(T.ok[1], T.ok[2], T.ok[3])
    b.pct:SetText(u.short or u.text or ""); b.pct:Show()
  elseif rank then
    -- no gain to show: the badge's short words under the icon ("BiS" / "2e" / "BiS 40": the
    -- label is the icon's width), the star on the chip, the full words in the tooltip
    b.pct:SetTextColor(br, bg, bb)
    b.pct:SetText(bisShort or (rank == 1 and L.BIS_1 or L.BIS_2S)); b.pct:Show()
  else b.pct:Hide() end
  b.upChip:SetShown(u.up == true); b.upArrow:SetShown(u.up == true)
  return u.up == true or rank ~= nil
end

-- A group cell: one HD icon (two checks when ready, "?" when unknown); the member, the quest, the
-- state and its reason in the tooltip.
local GCELLW, GMAXCOLS = 72, 5   -- the group table's columns at the old 640 window (the floor)
-- The members' columns at this width: as many as fit beside a quest column of GNAME_MIN (5 at
-- least, 12 at most), each GCELL_MIN to GCELL_MAX wide. Returns the count shown and the cell width.
local function GroupCols(nMembers)
  local room = CW - 8 - GNAME_MIN
  local maxCols = math.max(GMAXCOLS, math.min(12, math.floor(room / GCELL_MIN)))
  local ncol = math.min(nMembers, maxCols)
  if ncol < 1 then return 0, GCELLW end
  local cw = math.floor(room / ncol)
  if cw > GCELL_MAX then cw = GCELL_MAX end
  if cw < GCELL_MIN then cw = GCELL_MIN end
  return ncol, cw
end
ns.OverviewGroupCols = GroupCols   -- for the offline tests
local function MakeCell(parent)
  local c = CreateFrame("Frame", nil, parent)
  c:SetSize(GCELLW, 24)
  c:EnableMouse(true)
  c.hl = ns.Tex(c, "BACKGROUND", T.hoverFill); c.hl:SetAllPoints(); c.hl:Hide()
  c.icon = ns.Icon(c, "dot", 16, "ARTWORK", T.muted); c.icon:SetPoint("CENTER", 0, 0)
  c.icon2 = ns.Icon(c, "check", 16, "ARTWORK", T.gold); c.icon2:SetPoint("CENTER", 5, 0); c.icon2:Hide()
  c.q = ns.Text(c, ns.F.body, T.faint); c.q:SetPoint("CENTER", 0, 0); c.q:SetText("?"); c.q:Hide()
  c:SetScript("OnEnter", function(self) self.hl:Show(); if self.tip then ns.ShowTip(self, self.tip) end end)
  c:SetScript("OnLeave", function(self) self.hl:Hide(); ns.HideTip() end)
  return c
end
local function FillCell(c, m, qid, dkey, st)
  -- st: the state GroupData already worked out for this cell (the counts and the cell agree)
  local s, why, src
  if st then s, why, src = st.s, st.why, st.src else s, why, src = MemberState(m, qid, dkey) end
  local look = CELL[s] or CELL.unknown
  local col = T[look[3]] or T.muted
  if look[2] then
    ns.SetHDIcon(c.icon, look[2], col)
    -- ready to turn in: two gold checks, 10 px apart (one green check is "in the log")
    c.icon:ClearAllPoints(); c.icon:SetPoint("CENTER", look[4] and -5 or 0, 0)
    c.icon:Show(); c.q:Hide()
  else
    c.icon:Hide(); c.q:SetTextColor(col[1], col[2], col[3]); c.q:Show()
  end
  if look[4] then ns.SetHDIcon(c.icon2, "check", col) end
  c.icon2:SetShown(look[4] == true)
  c.state, c.who, c.qid, c.why, c.bucket = s, m.name, qid, why, BUCKET[s] or "unknown"
  local cc = ClassColor(m.class)
  local tip = { { m.name, cc[1], cc[2], cc[3] }, ns.QName(qid), { L[look[1]], col[1], col[2], col[3] } }
  if why and why ~= "" and why ~= L[look[1]] then tip[#tip + 1] = why end
  if src == "push" and s ~= "sent" then tip[#tip + 1] = L.SUM_G_PUSH_TT end
  c.tip = tip
  return s
end

-- One link of an unfolded chain, as a timeline (T-69): a numbered dot on a line that joins the
-- links (the current one in the accent), the quest's name and its state on one line, one muted line
-- "NPC · zone · lvl N · X XP"; its description (objective, note, places with their GPS) folds
-- behind a click.
local LINK_X = 26          -- text column, after the dot
local DOT = 16             -- the numbered dot
local LINK_GAP = 6         -- between two links
local DISC = "Interface\\CharacterFrame\\TempPortraitAlphaMask"
local function MakeLink(parent)
  local b = CreateFrame("Button", nil, parent)
  b.wlOwned = true
  b.hl = ns.Tex(b, "BACKGROUND", T.hoverFill); b.hl:SetAllPoints(); b.hl:Hide()
  b.press = ns.Tex(b, "BORDER", T.pressFill); b.press:SetAllPoints(); b.press:Hide()
  -- the line behind the dots (2 px), then the dot and its number
  b.rail = b:CreateTexture(nil, "BORDER", nil, 1); b.rail:SetWidth(2)
  b.dot = b:CreateTexture(nil, "ARTWORK"); b.dot:SetTexture(DISC); b.dot:SetSize(DOT, DOT); b.dot:SetPoint("TOPLEFT", 0, -1)
  b.num = ns.Text(b, ns.F.foot, T.fg, false); b.num:SetPoint("CENTER", b.dot, "CENTER", 0, 0); b.num:SetJustifyH("CENTER")
  b.chev = ns.Icon(b, "chevron_right", 12, "ARTWORK", T.muted); b.chev:SetPoint("TOPRIGHT", -2, -3)
  b.name = ns.Text(b, ns.F.meta, T.text); b.name:SetPoint("TOPLEFT", LINK_X, -2)
  b.facts = ns.Text(b, ns.F.meta, T.muted)
  b.where = ns.Text(b, ns.F.meta, T.muted)
  b.ne = ns.Text(b, ns.F.meta, T.text)
  b.note = ns.Text(b, ns.F.meta, T.muted)
  b.objs = {}
  b:SetScript("OnEnter", function(self)
    if self.more then self.hl:Show() end
    if self.tip then ns.ShowTip(self, self.tip) end
  end)
  b:SetScript("OnLeave", function(self) self.hl:Hide(); self.press:Hide(); ns.HideTip() end)
  b:SetScript("OnMouseDown", function(self) if self.more then self.press:Show() end end)
  b:SetScript("OnMouseUp", function(self) self.press:Hide() end)
  b:SetScript("OnClick", function(self)
    if not (self.more and self.qid and f) then return end
    f.linkOpen = f.linkOpen or {}
    f.linkOpen[self.qid] = not f.linkOpen[self.qid] or nil
    ns.HideTip()
    Render()
  end)
  return b
end

-- One place of a link's objective outside the dungeon: pin, "what · where (x, y)"; a click guides there.
local function MakeObjLine(parent)
  local o = CreateFrame("Button", nil, parent)
  o.wlOwned = true
  o.hl = ns.Tex(o, "BACKGROUND", T.hoverFill); o.hl:SetAllPoints(); o.hl:Hide()
  o.press = ns.Tex(o, "BORDER", T.pressFill); o.press:SetAllPoints(); o.press:Hide()
  o.icon = ns.Icon(o, "pin", 12, "ARTWORK", T.accentSoft); o.icon:SetPoint("TOPLEFT", 0, -2)
  o.text = ns.Text(o, ns.F.meta, T.accentSoft); o.text:SetPoint("TOPLEFT", 16, -1)
  o:SetScript("OnEnter", function(self)
    self.hl:Show(); ns.SetHDIcon(self.icon, "pin", T.fg)
    if self.point then ns.ShowTip(self, { L.OV_GPS_T:format(self.point[4] or ""), L.OV_GPS_CLICK }) end
  end)
  o:SetScript("OnLeave", function(self) self.hl:Hide(); self.press:Hide(); ns.SetHDIcon(self.icon, "pin", T.accentSoft); ns.HideTip() end)
  o:SetScript("OnMouseDown", function(self) self.press:Show(); self.text:SetPoint("TOPLEFT", 16, -2) end)
  o:SetScript("OnMouseUp", function(self) self.press:Hide(); self.text:SetPoint("TOPLEFT", 16, -1) end)
  o:SetScript("OnClick", function(self) if self.point then GoPoint(self.point) end end)
  return o
end

-- One quest still to pick up before going in: its name and what it waits on, after a pin when a
-- click guides to the giver (none while it cannot be taken yet); hover for the giver and where.
local function MakeReadyLine(parent)
  local o = CreateFrame("Button", nil, parent)
  o.wlOwned = true
  o.hl = ns.Tex(o, "BACKGROUND", T.hoverFill); o.hl:SetAllPoints(); o.hl:Hide()
  o.press = ns.Tex(o, "BORDER", T.pressFill); o.press:SetAllPoints(); o.press:Hide()
  o.icon = ns.Icon(o, "pin", 12, "ARTWORK", T.accentSoft); o.icon:SetPoint("TOPLEFT", 0, -2)
  o.text = ns.Text(o, ns.F.meta, T.text); o.text:SetPoint("TOPLEFT", 16, -1)
  o:SetScript("OnEnter", function(self)
    if self.point then self.hl:Show() end
    if self.tip then ns.ShowTip(self, self.tip) end
  end)
  o:SetScript("OnLeave", function(self) self.hl:Hide(); self.press:Hide(); self.text:SetPoint("TOPLEFT", 16, -1); ns.HideTip() end)
  o:SetScript("OnMouseDown", function(self) if self.point then self.press:Show(); self.text:SetPoint("TOPLEFT", 16, -2) end end)
  o:SetScript("OnMouseUp", function(self) self.press:Hide(); self.text:SetPoint("TOPLEFT", 16, -1) end)
  o:SetScript("OnClick", function(self) if self.point then GoPoint(self.point) end end)
  return o
end

-- What a quest given outside waits on before it can be taken: its next prerequisite, else its level.
local function TakeWhy(log, qid, q, lvl, cls)
  local pre = ns.QuestPreInfo(qid, log, cls)
  if pre.nextPid then return L.SUM_RDY_AFTER:format(ns.QName(pre.nextPid)), pre end
  if q.r and q.r > lvl then return L.ST_LOW:format(q.r), pre end
  return nil, pre
end

-- The objectives of a quest with a place outside the dungeon, not done yet (4 at most).
local function OutsidePlaces(log, qid, q)
  local out = {}
  for _, o in ipairs(q.o or {}) do
    if #out >= 4 then break end
    local w = o.w
    if w and w.m and w.x and w.y and not o.ins and not o.outer and not ns.ObjDone(log, qid, o) then
      local what = o.n and ns.T(o.n) or nil
      local z = ZoneName(w.m)
      local place = w.n and ns.T(w.n) or nil
      if place and z ~= "" then place = place .. ", " .. z elseif z ~= "" then place = z end
      local txt = ("%s(%.1f, %.1f)"):format(place and (place .. " ") or "", w.x, w.y)
      if what then txt = what .. " · " .. txt end
      out[#out + 1] = { text = txt, point = { w.m, w.x, w.y, w.n or o.n } }
    end
  end
  return out
end

-- the state words of the unfolded links
local LINK_WORD = { none = "SUM_ST_TAKE", on = "SUM_ST_ON", ready = "SUM_ST_READY", done = "SUM_ST_DONE" }
local LINK_COLOR = { none = "muted", on = "info", ready = "ok", done = "muted" }

local function RowTip(r)
  local qid = r.qid
  local q = qid and ns.Q[qid]
  if not q then return end
  local lines = { ns.QName(qid) }
  if GetLocale and GetLocale() == "frFR" and q.n and q.n ~= lines[1] then table.insert(lines, q.n)
  elseif ns.lang == "fr" and q.nf and q.nf ~= lines[1] then table.insert(lines, q.nf) end
  local obj = ObjText(q)
  if obj then table.insert(lines, { obj, T.text[1], T.text[2], T.text[3] }) end
  local g = r.st ~= "done" and GiverText(q, r.st)
  if g then table.insert(lines, g) end
  local steps = LibSteps(qid)
  if steps then
    table.insert(lines, { L.SUM_LFD, T.fg[1], T.fg[2], T.fg[3] })
    for _, s in ipairs(steps) do table.insert(lines, "- " .. s) end
  end
  local fdj = FDJNote(qid)
  if fdj then
    table.insert(lines, { L.SUM_FDJ, T.fg[1], T.fg[2], T.fg[3] })
    table.insert(lines, fdj)
  end
  if q.ne then table.insert(lines, ns.T(q.ne)) end
  local rw = q.rw and q.rw ~= "" and q.rw or nil
  if rw then table.insert(lines, { L.TT_REWARD:format(rw), T.gold[1], T.gold[2], T.gold[3] }) end
  local inf = r.inf
  if inf and r.st ~= "done" then
    -- what the level word means, and why the XP is lower than the quest's
    if inf.band then table.insert(lines, L["SUM_BAND_" .. inf.band:upper() .. "_TT"]) end
    if AtCap() and (inf.xpBase or 0) > 0 then table.insert(lines, L.SUM_XP_CAP_TT)
    elseif inf.xpBase and inf.xp < inf.xpBase then
      table.insert(lines, { L.SUM_XP_LESS_TT:format(Big(inf.xp), Big(inf.xpBase), inf.xpDiff or 0), T.warn[1], T.warn[2], T.warn[3] })
    end
  end
  if r.st ~= "done" then
    local n = r.pre and r.pre.total or 0
    if IsOff(qid) then table.insert(lines, n > 0 and L.SUM_TICK_ON_CH:format(n) or L.SUM_TICK_ON)
    else table.insert(lines, n > 0 and L.SUM_TICK_OFF_CH:format(n) or L.SUM_TICK_OFF) end
  end
  ns.ShowTip(r, lines)
end

local ROW_TOP = 8   -- the name's top inset; the check box, the XP and the group icons sit on its first line
local PILL_LINE = 24 -- a line of pills (18 tall, centred) and the row's actions (24)

local function MakeRow(parent)
  local S = SW()
  local r = CreateFrame("Button", nil, parent)
  r.wlOwned = true
  r:SetWidth(CW)
  r.bg = ns.Tex(r, "BACKGROUND", T.cardFill); r.bg:SetAllPoints()
  ns.Outline(r, T.cardEdge)
  r.hl = ns.Tex(r, "BORDER", T.hoverFill); r.hl:SetAllPoints(); r.hl:Hide()
  r.press = ns.Tex(r, "ARTWORK", T.pressFill); r.press:SetAllPoints(); r.press:Hide()
  -- a drawn check box: panel fill, 1 px edge (accent when ticked), the HD check inside
  r.boxF = CreateFrame("Frame", nil, r); r.boxF:SetSize(16, 16); r.boxF:SetPoint("TOPLEFT", 8, -ROW_TOP)
  r.box = ns.Tex(r.boxF, "BACKGROUND", T.panel); r.box:SetAllPoints()
  r.boxEdge = ns.Outline(r.boxF, T.btnEdge)
  r.tick = ns.Icon(r.boxF, "check", 12, "ARTWORK", T.fg); r.tick:SetPoint("CENTER")
  r.doneIcon = ns.Icon(r, "check", 16, "ARTWORK", T.faint); r.doneIcon:SetPoint("TOPLEFT", 8, -ROW_TOP); r.doneIcon:Hide()
  r.name = ns.Text(r, ns.F.body, T.fg)
  r.detail = ns.Text(r, ns.F.meta, T.muted)
  -- why the route leaves the quest out (its chain too high, too long, a level to reach first)
  r.lock = ns.Text(r, ns.F.meta, T.muted); r.lock:Hide()
  -- the number column at the right: the XP you will get ("3 500" 13 + "XP" 11), the money under it
  r.xpUnit = ns.Text(r, ns.F.meta, T.muted); r.xpUnit:SetWordWrap(false)
  r.xpNum = ns.Text(r, ns.F.body, T.fg); r.xpNum:SetWordWrap(false)
  r.xpNum:SetPoint("BOTTOMRIGHT", r.xpUnit, "BOTTOMLEFT", -3, 0)
  r.money = ns.Text(r, ns.F.meta, T.muted); r.money:SetWordWrap(false)
  -- the chain line: chevron + "Chain of 10 quests · 31,500 XP in all"; a click unfolds it below
  r.chain = CreateFrame("Button", nil, r)
  r.chain.hl = ns.Tex(r.chain, "BACKGROUND", T.hoverFill); r.chain.hl:SetAllPoints(); r.chain.hl:Hide()
  r.chain.chev = ns.Icon(r.chain, "chevron_right", 12, "ARTWORK", T.accentSoft); r.chain.chev:SetPoint("TOPLEFT", 0, -1)
  r.chain.text = ns.Text(r.chain, ns.F.meta, T.text); r.chain.text:SetPoint("TOPLEFT", 16, 0)
  r.chain:SetScript("OnEnter", function(self)
    self.hl:Show(); self.chev:SetVertexColor(T.fg[1], T.fg[2], T.fg[3])
    local tip = { L.OV_CHAIN_TT }
    local inf = r.inf
    if inf and inf.high and not inf.low then tip[#tip + 1] = { L.SUM_HIGH_TT:format(inf.maxL), T.warn[1], T.warn[2], T.warn[3] } end
    tip[#tip + 1] = f.open[r.qid] and L.SUM_COLLAPSE or L.SUM_EXPAND
    ns.ShowTip(self, tip)
  end)
  r.chain:SetScript("OnLeave", function(self)
    self.hl:Hide(); self.chev:SetVertexColor(T.accentSoft[1], T.accentSoft[2], T.accentSoft[3]); ns.HideTip()
  end)
  r.chain:SetScript("OnMouseDown", function(self) self.text:SetPoint("TOPLEFT", 16, -1) end)
  r.chain:SetScript("OnMouseUp", function(self) self.text:SetPoint("TOPLEFT", 16, 0) end)
  r.chain:SetScript("OnClick", function()
    f.open[r.qid] = not f.open[r.qid] or nil
    Render()
  end)
  r.pills, r.rewards, r.links = {}, {}, {}
  -- share: a quiet text action, shown only while a member still lacks the quest; it brightens
  -- when the card is under the mouse
  r.share = S.Button(r, L.SUM_SHARE, 0, 24, "ghost", function(self)
    if r.shareId and ns.PushQuest and ns.PushQuest(r.shareId) then self:Flash(L.SUM_SHARED) end
  end, function()
    local tip = { L.SUM_SHARE }
    if r.shareWho and #r.shareWho > 0 then tip[#tip + 1] = L.SUM_SHARE_WHO:format(JoinNames(r.shareWho)) end
    tip[#tip + 1] = L.SUM_SHARE_TT:format(r.shareId and ns.QName(r.shareId) or "")
    return tip
  end)
  local function shareLit(on) if r.share.content then r.share.content:SetAlpha(on and 1 or 0.6) end end
  r.shareLit = shareLit
  shareLit(false)
  if r.share.HookScript then
    r.share:HookScript("OnEnter", function() shareLit(true) end)
    r.share:HookScript("OnLeave", function() shareLit(r.IsMouseOver and r:IsMouseOver() or false) end)
  end
  r.gps = S.IconButton(r, "pin", 24, function()
    return { L.OV_GPS_T:format(r.point and r.point[4] or ""), L.OV_GPS_CLICK }
  end, function() GoPoint(r.point) end)
  -- "+N": the rewards past the 4 slots, listed in its tooltip
  r.more = CreateFrame("Frame", nil, r)
  r.more:SetSize(RW_SIZE, RW_SIZE); r.more:EnableMouse(true); r.more:Hide()
  r.more.hl = ns.Tex(r.more, "BACKGROUND", T.hoverFill); r.more.hl:SetAllPoints(); r.more.hl:Hide()
  ns.Outline(r.more, T.cardEdge)
  r.more.text = ns.Text(r.more, ns.F.meta, T.muted); r.more.text:SetPoint("CENTER")
  r.more:SetScript("OnEnter", function(self) self.hl:Show(); if self.tip then ns.ShowTip(self, self.tip) end end)
  r.more:SetScript("OnLeave", function(self) self.hl:Hide(); ns.HideTip() end)
  -- the row is the check box's click target
  r:SetScript("OnClick", function(self)
    if self.st == "done" then return end
    -- a quest the route leaves out for its chain: a tick puts it back (offPick), chain and all
    if self.lockOut then SetOff(self.qid, false) return end
    SetOff(self.qid, not IsOff(self.qid))
  end)
  local function nudge(self, dy)
    self.name:SetPoint("TOPLEFT", TX, -ROW_TOP - dy)
    self.boxF:SetPoint("TOPLEFT", 8, -ROW_TOP - dy)
  end
  r:SetScript("OnMouseDown", function(self) if self.st ~= "done" then self.press:Show(); nudge(self, 1) end end)
  r:SetScript("OnMouseUp", function(self) self.press:Hide(); nudge(self, 0) end)
  r:SetScript("OnEnter", function(self) if self.st ~= "done" then self.hl:Show() end shareLit(true); RowTip(self) end)
  r:SetScript("OnLeave", function(self) self.hl:Hide(); self.press:Hide(); nudge(self, 0); shareLit(false); ns.HideTip() end)
  return r
end

-- Pills in flowing lines of 24 (each 18 tall, centred) from (x0, y) inside `width`; returns the
-- bottom of the last line.
local function PlacePills(r, list, x0, y, width)
  local x, n = 0, 0
  for i, p in ipairs(list) do
    local pill = r.pills[i] or SW().Pill(r); r.pills[i] = pill
    pill:Set(p[1], p[2], p[3])
    pill.tipLines = p[4]
    if not pill.wlTipHooked then
      pill.wlTipHooked = true
      pill:EnableMouse(true)
      pill:SetScript("OnEnter", function(self) if self.tipLines then ns.ShowTip(self, self.tipLines) end end)
      pill:SetScript("OnLeave", ns.HideTip)
    end
    local pw = num(pill:GetWidth()) or 60
    -- wider than the whole line: its short label (the full text stays in its tooltip)
    if pw > width and p[5] then pill:Set(p[5], p[2], p[3]); pw = num(pill:GetWidth()) or 60 end
    if x > 0 and x + pw > width then x = 0; y = y + PILL_LINE end
    pill:ClearAllPoints(); pill:SetPoint("TOPLEFT", r, "TOPLEFT", x0 + x, -(y + (PILL_LINE - 18) / 2))
    pill:Show()
    x = x + pw + 4
    n = i
  end
  for i = n + 1, #r.pills do r.pills[i]:Hide() end
  return n > 0 and (y + PILL_LINE) or y
end

-- Hides what a row turned in does not show.
local function HideExtras(r)
  r.chain:Hide(); r.share:Hide(); r.gps:Hide(); r.more:Hide()
  r.xpNum:Hide(); r.xpUnit:Hide(); r.money:Hide()
  for _, p in ipairs(r.pills) do p:Hide() end
  for _, b in ipairs(r.rewards) do b:Hide() end
  for _, l in ipairs(r.links) do l:Hide() end
end

-- The fact line of a card, in words: "Quête niv. 36 · facile · se prend dès le niv. 30" (the level
-- part in the game's quest colour), or the level you still need, in the warning colour.
local function FactText(q, inf, lvl)
  local seg = {}
  local lowSelf = inf.low and not inf.pre.nextPid
  if q.l then
    local band = (not lowSelf) and inf.band and L["SUM_BAND_" .. inf.band:upper()] or nil
    seg[#seg + 1] = ns.Hex(SW().LevelColor(q.l)) .. L.SUM_FACT_LV:format(q.l) .. (band and (" · " .. band) or "") .. "|r"
  end
  if inf.low then
    local fmt = lowSelf and L.SUM_NEED or L.SUM_NEED_PRE
    seg[#seg + 1] = ns.Hex(T.warn) .. fmt:format(inf.low, lvl) .. "|r"
  elseif inf.st == "none" and q.r and q.r > lvl then
    seg[#seg + 1] = ns.Hex(T.warn) .. L.SUM_NEED:format(q.r, lvl) .. "|r"
  elseif inf.st == "none" and q.r and q.r < (q.l or 0) then
    seg[#seg + 1] = L.SUM_FROM:format(q.r)
  end
  if (inf.xpBase or 0) > 0 and (inf.xp or 0) > 0 and inf.xp < inf.xpBase and inf.band ~= "grey" then
    seg[#seg + 1] = L.SUM_XP_LESS
  end
  return #seg > 0 and table.concat(seg, " · ") or nil
end

-- Fills one quest card `width` wide (the grid's cell; the content width by default); returns its height. Always the same order: name (XP and money at the
-- right), facts, state and actions, rewards, chain (its links unfold right under it).
local function FillRow(r, qid, dkey, inf, ctx, width)
  local q = inf.q
  local log = ctx.log
  local st, pre = inf.st, inf.pre
  local done = st == "done"
  local off = IsOff(qid)
  -- left out of the route for its chain (ns.LockedReason: a level to reach, too high, too long),
  -- unless ticked by hand: the box shows it unticked and a muted line says why
  local lockTxt, lockCause
  if not done and ns.LockedReason then
    local okL, t, c = pcall(ns.LockedReason, qid, ctx.lvl, ctx.cls, dkey)
    if okL and t and (c == "lvl" or c == "high" or c == "long") then lockTxt, lockCause = t, c end
  end
  local lockOut = false
  if lockTxt then
    local okR, inR = pcall(ns.ChainInRoute or function() return false end, qid, ctx.cls, ctx.lvl, dkey)
    lockOut = not (okR and inR)
  end
  if not lockOut then lockTxt = nil end
  r.lockOut = lockOut and not off or nil
  off = off or lockOut
  r.qid, r.dkey, r.st, r.pre, r.low, r.inf = qid, dkey, st, pre, inf.low, inf
  r.point = (not done) and PointFor(log, qid, q, st, pre) or nil

  -- check box (a quest turned in shows a grey check instead)
  r.boxF:SetShown(not done); r.doneIcon:SetShown(done)
  r.tick:SetShown(not off)
  r.boxEdge(off and T.btnEdge or T.accent)

  -- the XP column at the right edge (the group's state is in the Group tab)
  local colR = (width or CW) - 12
  local nameW = colR - XPCOL - 12 - TX
  local wide = colR - TX
  r.wide, r.nameW, r.colR = wide, nameW, colR

  -- line 1: the name, always white (muted when left out or turned in)
  r.name:SetText(ns.QName(qid))
  local nc = (off or done) and T.muted or T.fg
  r.name:SetTextColor(nc[1], nc[2], nc[3])
  r.name:ClearAllPoints(); r.name:SetPoint("TOPLEFT", TX, -ROW_TOP)
  local y = ROW_TOP + LineH(r.name, ns.F.body, nameW, r)
  local line2 = y + 3

  -- line 2: the facts in words
  local detail
  if done then detail = q.l and L.SUM_FACT_LV:format(q.l) or nil
  else detail = FactText(q, inf, ctx.lvl) end
  if detail then
    r.detail:SetText(detail)
    r.detail:SetTextColor(T.muted[1], T.muted[2], T.muted[3])
    r.detail:ClearAllPoints(); r.detail:SetPoint("TOPLEFT", TX, -line2)
    r.detail:Show()
    y = line2 + LineH(r.detail, ns.F.meta, nameW, r)
  else r.detail:SetText(""); r.detail:Hide() end
  if lockTxt then
    r.lock:SetText(lockTxt)
    r.lock:SetTextColor(T.muted[1], T.muted[2], T.muted[3])
    r.lock:ClearAllPoints(); r.lock:SetPoint("TOPLEFT", TX, -(y + 2))
    r.lock:Show()
    y = y + 2 + LineH(r.lock, ns.F.meta, nameW, r)
  else r.lock:SetText(""); r.lock:Hide() end

  if done then
    HideExtras(r)
    local h = math.ceil(math.max(y + 8, 36))
    r:SetHeight(h)
    return h
  end

  -- the number column: the XP you will get (muted when reduced or left out), the money under it
  if inf.xp > 0 then
    r.xpUnit:SetText(L.SUM_XP_UNIT)
    r.xpUnit:ClearAllPoints(); r.xpUnit:SetPoint("TOPRIGHT", r, "TOPLEFT", colR, -(ROW_TOP + 2))
    r.xpNum:SetText(Big(inf.xp))
    local xc = (off or (inf.xpBase and inf.xp < inf.xpBase)) and T.muted or T.fg
    r.xpNum:SetTextColor(xc[1], xc[2], xc[3])
    r.xpUnit:Show(); r.xpNum:Show()
  else r.xpUnit:Hide(); r.xpNum:Hide() end
  if inf.money > 0 then
    r.money:SetText(Money(inf.money))
    r.money:ClearAllPoints(); r.money:SetPoint("TOPRIGHT", r, "TOPLEFT", colR, -line2)
    r.money:Show()
  else r.money:Hide() end

  -- line 3: one state pill, then what is special; the actions (share, GPS) at the right
  local pills = {}
  if st == "on" then pills[#pills + 1] = { L.SUM_ST_ON, T.info, nil, { L.SUM_ST_ON, L.SUM_ST_ON_TT } }
  elseif st == "ready" then pills[#pills + 1] = { L.SUM_ST_READY, T.ok, nil, { L.SUM_ST_READY, L.SUM_ST_READY_TT } }
  else
    local before = ctx.peBefore and ctx.peBefore[qid]
    local inside = not before and ((ctx.peInside and ctx.peInside[qid])
      or (q.s and q.s.i) or (q.si and not (q.s and q.s.m))) and true or false
    if inside then
      pills[#pills + 1] = { L.SUM_ST_IN, T.fg, nil, { L.SUM_ST_IN, L.SUM_ST_IN_TT } }
    else
      local tip = { L.SUM_ST_TAKE, L.SUM_ST_TAKE_TT }
      local g = GiverText(q, st)
      if g then tip[#tip + 1] = g end
      local why = TakeWhy(log, qid, q, ctx.lvl, ctx.cls)
      if why then tip[#tip + 1] = { why, T.warn[1], T.warn[2], T.warn[3] } end
      pills[#pills + 1] = { L.SUM_ST_TAKE, off and T.fg or T.warn, nil, tip }
    end
  end
  if inf.elite then pills[#pills + 1] = { L.SUM_ELITE, T.warn, nil, { L.SUM_ELITE, L.SUM_ELITE_TT } } end
  if inf.other then
    local dn = ns.DName(inf.other)
    pills[#pills + 1] = { L.SUM_OTHER:format(dn), T.info, nil, { L.SUM_OTHER:format(dn), L.SUM_OTHER_TT:format(dn) }, L.SUM_OTHER_SHORT }
  end
  local lineY = y + 6
  r.shareId = ctx.grouped and ShareTarget(qid, pre, log) or nil
  local need, who = false, nil
  if r.shareId then need, who = NeedsShare(qid, r.shareId, dkey, ctx) end
  r.shareWho = who
  local ax = colR
  if r.point then
    r.gps:ClearAllPoints(); r.gps:SetPoint("TOPRIGHT", r, "TOPLEFT", ax, -lineY); r.gps:Show()
    ax = ax - 24 - 4
  else r.gps:Hide() end
  if r.shareId and need then
    local sw = num(r.share:GetWidth()) or 0
    if sw < 40 then sw = 70 end
    r.share:ClearAllPoints(); r.share:SetPoint("TOPRIGHT", r, "TOPLEFT", ax, -lineY); r.share:Show()
    if r.shareLit then r.shareLit(r.hl:IsShown()) end
    ax = ax - sw - 4
  else r.share:Hide() end
  y = PlacePills(r, pills, TX, lineY, math.max(60, math.min(nameW, ax - 8 - TX)))
  if y < lineY + PILL_LINE and (r.point or r.share:IsShown()) then y = lineY + PILL_LINE end

  -- line 4: up to 4 reward icons (30 px) over the card's width; the others behind a "+N" marker
  local list = Rewards(qid, q)
  local rwY = y + 6
  local slots = math.max(1, math.min(MAX_REWARDS, math.floor((wide + RW_STEP - RW_SIZE) / RW_STEP)))
  local showN = #list
  if showN > slots then showN = slots - 1 end
  local rwLvl = RewardLevel(q)
  local bestI = BestChoice(qid, list, rwLvl)
  local n, labels = 0, false
  for i = 1, showN do
    n = n + 1
    local b = r.rewards[n] or MakeReward(r); r.rewards[n] = b
    if FillReward(b, list[i], bestI == i, rwLvl) then labels = true end
    b:ClearAllPoints(); b:SetPoint("TOPLEFT", TX + (n - 1) * RW_STEP, -rwY)
    b:Show()
  end
  for i = n + 1, #r.rewards do r.rewards[i]:Hide() end
  local rest = #list - showN
  if rest > 0 then
    r.more.text:SetText(L.OV_MORE:format(rest))
    local names = { L.SUM_RW_MORE }
    for i = showN + 1, #list do
      local rw = list[i]
      local nm = rw.name
      if rw.id then nm = CachedName(rw.id) or nm end
      local u = UpInfo(rw, rwLvl)
      local line = "- " .. (nm or "?")
      if bestI == i then line = line .. " (" .. L.SUM_BEST .. ")" end
      local bis = ns.BisBadgeText and ns.BisBadgeText(rw.id, 11)
      if bis then line = line .. "  " .. bis end
      if u.up then line = { line .. " " .. (u.text or ""), T.ok[1], T.ok[2], T.ok[3] } end
      names[#names + 1] = line
    end
    r.more.tip = names
    r.more:ClearAllPoints(); r.more:SetPoint("TOPLEFT", TX + showN * RW_STEP, -rwY)
    r.more:Show()
  else r.more:Hide() end
  r.rwLabels = labels
  if #list > 0 then y = rwY + RW_SIZE + (labels and RW_LABEL or 0) end

  -- line 5: the chain, unfoldable: "Chain of 10 quests · 31,500 XP in all · goes up to level 44"
  local hasChain = pre.total > 0
  if hasChain then
    local t = L.SUM_CHAIN_LINE:format(inf.chainN, Big(inf.chainXP))
    if inf.high and not inf.low then t = t .. " · " .. ns.Hex(T.warn) .. L.SUM_CHAIN_HIGH:format(inf.maxL) .. "|r" end
    r.chain.text:SetText(t)
    ns.SetHDIcon(r.chain.chev, f.open[qid] and "chevron_down" or "chevron_right", T.accentSoft)
    local th = LineH(r.chain.text, ns.F.meta, wide - 16, r.chain)
    r.chain:SetSize(wide, th + 2)
    r.chain:ClearAllPoints(); r.chain:SetPoint("TOPLEFT", TX, -(y + 6))
    r.chain:Show()
    y = y + 6 + th + 2
  else r.chain:Hide() end

  -- the unfolded chain, right under its line: a timeline, one link per quest (and the quest itself)
  local li = 0
  if hasChain and f.open[qid] then
    y = y + 8
    local ids = {}
    for _, pid in ipairs(pre.chain) do if ns.Q[pid] then ids[#ids + 1] = pid end end
    if ns.Q[qid] then ids[#ids + 1] = qid end
    local lw = wide - LINK_X - 16
    -- the current link: the first one not turned in
    local curId
    for _, id in ipairs(ids) do if QState(log, id) ~= "done" then curId = id break end end
    f.linkOpen = f.linkOpen or {}
    for k, id in ipairs(ids) do
      local lq = ns.Q[id]
      li = li + 1
      local b = r.links[li] or MakeLink(r); r.links[li] = b
      b.qid = id
      local ls = QState(log, id)
      local cur = (id == curId)
      -- the dot: done = faint, current = accent, to come = the line's grey; its number
      local dc = cur and T.accent or (ls == "done" and T.faint) or T.trackOff
      b.dot:SetVertexColor(dc[1], dc[2], dc[3], 1)
      b.num:SetText(tostring(k))
      -- dark figure on the faint (done) dot: muted on faint was ~1.7:1, unreadable
      local nc = (ls == "done" and not cur) and T.bg or T.fg
      b.num:SetTextColor(nc[1], nc[2], nc[3])
      -- line 1: the name and its state
      local wc = (ls == "none" and not off) and T.warn or T[LINK_COLOR[ls] or "muted"] or T.muted
      b.name:SetText(ns.QName(id) .. (id == qid and (" (" .. L.OV_THIS .. ")") or "") .. " · "
        .. ns.Hex(wc) .. L[LINK_WORD[ls] or LINK_WORD.none] .. "|r")
      local tc = cur and T.fg or (ls == "done" and T.muted) or T.text
      b.name:SetTextColor(tc[1], tc[2], tc[3])
      b.name:SetWidth(lw)
      local bh = 2 + LineH(b.name, ns.F.meta, lw, b)
      -- line 2, muted: NPC · zone · lvl N · X XP
      local fl = {}
      local gs = (ls == "ready" and lq.f) or lq.s
      if type(gs) == "table" then
        if gs.n then fl[#fl + 1] = ns.T(gs.n) end
        if gs.i then fl[#fl + 1] = L.OV_IN_DG
        elseif gs.m then local z = ZoneName(gs.m); if z ~= "" then fl[#fl + 1] = z end end
      end
      if lq.l then fl[#fl + 1] = L.SUM_LINK_LV:format(lq.l) end
      local xp = XPFor(id, ctx.lvl)
      if xp > 0 then fl[#fl + 1] = L.SUM_XP:format(Big(xp)) end
      if #fl > 0 then
        b.facts:SetText(table.concat(fl, " · ")); b.facts:ClearAllPoints(); b.facts:SetPoint("TOPLEFT", LINK_X, -(bh + 2)); b.facts:Show()
        bh = bh + 2 + LineH(b.facts, ns.F.meta, lw, b, 2)
      else b.facts:Hide() end
      -- the description, folded: giver or objective, the data's note, each place outside with its
      -- GPS, the FDJ note
      local where, note, ne, places = nil, nil, nil, {}
      if ls ~= "done" then
        local w = {}
        local g = GiverText(lq, ls); if g then w[#w + 1] = g end
        local o = ObjText(lq); if o then w[#w + 1] = o end
        where = #w > 0 and table.concat(w, " · ") or nil
        local fn = FDJNote(id)
        if fn then note = L.SUM_FDJ .. L.COLON .. fn end
        ne = lq.ne and ns.T(lq.ne) or nil
        if ls == "on" or ls == "none" then places = OutsidePlaces(log, id, lq) end
      end
      local point = (ls ~= "done") and (PointOf(log, id, lq, ls) or FDJPoint(id, ns.QName(id))) or nil
      b.point = point
      b.more = (where or ne or note or point or #places > 0) and true or false
      local open = b.more and f.linkOpen[id] and true or false
      b.chev:SetShown(b.more)
      if b.more then ns.SetHDIcon(b.chev, open and "chevron_down" or "chevron_right", T.muted) end
      if open and where then
        b.where:SetText(where); b.where:ClearAllPoints(); b.where:SetPoint("TOPLEFT", LINK_X, -(bh + 4)); b.where:Show()
        bh = bh + 4 + LineH(b.where, ns.F.meta, lw, b, 3)
      else b.where:Hide() end
      if open and ne then
        b.ne:SetText(ne); b.ne:ClearAllPoints(); b.ne:SetPoint("TOPLEFT", LINK_X, -(bh + 4)); b.ne:Show()
        bh = bh + 4 + LineH(b.ne, ns.F.meta, lw, b, 6)
      else b.ne:Hide() end
      local oi = 0
      if open then
        for _, pl in ipairs(places) do
          oi = oi + 1
          local ol = b.objs[oi] or MakeObjLine(b); b.objs[oi] = ol
          ol.text:SetText(pl.text)
          ol.point = pl.point
          local oh = LineH(ol.text, ns.F.meta, lw - 16, ol)
          ol:SetSize(lw, oh + 2)
          ol:ClearAllPoints(); ol:SetPoint("TOPLEFT", b, "TOPLEFT", LINK_X, -(bh + 4))
          ol:Show()
          bh = bh + 4 + oh + 2
        end
      end
      for j = oi + 1, #b.objs do b.objs[j]:Hide() end
      -- the giver (or where to turn it in), with its GPS
      if open and point then
        local gl = b.gpsLine or MakeObjLine(b); b.gpsLine = gl
        gl.text:SetText(L.OV_GPS_T:format(point[4] or ""))
        gl.point = point
        local gh = LineH(gl.text, ns.F.meta, lw - 16, gl)
        gl:SetSize(lw, gh + 2)
        gl:ClearAllPoints(); gl:SetPoint("TOPLEFT", b, "TOPLEFT", LINK_X, -(bh + 4))
        gl:Show()
        bh = bh + 4 + gh + 2
      elseif b.gpsLine then b.gpsLine:Hide() end
      if open and note then
        b.note:SetText(note); b.note:ClearAllPoints(); b.note:SetPoint("TOPLEFT", LINK_X, -(bh + 4)); b.note:Show()
        bh = bh + 4 + LineH(b.note, ns.F.meta, lw, b, 3)
      else b.note:Hide() end
      bh = bh + 2
      -- the line joins this dot to the next one (through the gap); none above the first, none
      -- below the last
      local last = (k == #ids)
      b.rail:ClearAllPoints()
      b.rail:SetPoint("TOP", b.dot, "CENTER", 0, 0)
      if last then b.rail:SetHeight(0.001); b.rail:Hide()
      else b.rail:SetPoint("BOTTOM", b, "BOTTOMLEFT", DOT / 2, -LINK_GAP - 1); b.rail:Show() end
      local rc = (ls == "done") and T.faint or T.trackOff
      b.rail:SetColorTexture(rc[1], rc[2], rc[3], 1)
      -- the tooltip: what a click does
      local tip = { ns.QName(id) }
      local steps = LibSteps(id)
      if steps then tip[#tip + 1] = { L.SUM_LFD, T.fg[1], T.fg[2], T.fg[3] }; for _, st in ipairs(steps) do tip[#tip + 1] = "- " .. st end end
      if b.more then tip[#tip + 1] = open and L.SUM_LINK_FOLD or L.SUM_LINK_UNFOLD end
      b.tip = tip
      b:SetSize(wide, bh)
      b:ClearAllPoints(); b:SetPoint("TOPLEFT", r, "TOPLEFT", TX, -y)
      b:Show()
      y = y + bh + (last and 0 or LINK_GAP)
    end
  end
  for i = li + 1, #r.links do r.links[i]:Hide() end

  local h = math.ceil(math.max(y + 8, 36))
  r:SetHeight(h)
  return h
end

-- =====================================================================
--  Build
-- =====================================================================
local function MakeHero(parent)
  local hero = CreateFrame("Frame", nil, parent)
  hero.wlWorld = true
  hero:SetSize(CW, HERO_H)
  ns.Flat(hero, T.panel, T.cardEdge)
  hero.art = hero:CreateTexture(nil, "ARTWORK"); hero.art:SetPoint("TOPLEFT", 1, -1); hero.art:SetPoint("BOTTOMRIGHT", -1, 1)
  hero.big = hero:CreateTexture(nil, "ARTWORK", nil, 1); hero.big:SetSize(40, 40); hero.big:SetPoint("CENTER", 0, 12); hero.big:Hide()
  hero.band = hero:CreateTexture(nil, "ARTWORK", nil, 3); hero.band:SetPoint("BOTTOMLEFT", 1, 1); hero.band:SetPoint("BOTTOMRIGHT", -1, 1)
  hero.band:SetColorTexture(unpack(T.scrim))
  hero.lvl = ns.Text(hero, ns.F.meta, T.text, false, "SHADOW"); hero.lvl:SetPoint("BOTTOMLEFT", 12, 8)
  hero.name = ns.Text(hero, ns.F.heading, T.fg, false, "SHADOW"); hero.name:SetPoint("BOTTOMLEFT", hero.lvl, "TOPLEFT", 0, 3)
  return hero
end

-- "Quests to do 7".
local function MakeHead(parent)
  local h = CreateFrame("Frame", nil, parent)
  h:SetSize(CW, 24)
  h.label = ns.Text(h, ns.F.body, T.fg); h.label:SetPoint("BOTTOMLEFT", 0, 6)
  h.count = ns.Text(h, ns.F.meta, T.muted); h.count:SetPoint("BOTTOMLEFT", h.label, "BOTTOMRIGHT", 6, 0)
  h.rule = ns.Rule(h); h.rule:SetPoint("BOTTOMLEFT"); h.rule:SetPoint("BOTTOMRIGHT")
  return h
end

-- "Already turned in (10)": folded by default, a click shows the quests turned in.
local function MakeFold(parent)
  local b = CreateFrame("Button", nil, parent)
  b.wlOwned = true
  b:SetSize(CW, 28)
  b.hl = ns.Tex(b, "BACKGROUND", T.hoverFill); b.hl:SetAllPoints(); b.hl:Hide()
  b.chev = ns.Icon(b, "chevron_right", 12, "ARTWORK", T.accentSoft); b.chev:SetPoint("LEFT", 8, 0)
  b.text = ns.Text(b, ns.F.body, T.muted); b.text:SetPoint("LEFT", 26, 0); b.text:SetWidth(CW - 34)
  b.rule = ns.Rule(b); b.rule:SetPoint("BOTTOMLEFT"); b.rule:SetPoint("BOTTOMRIGHT")
  b:SetScript("OnEnter", function(self)
    self.hl:Show(); self.chev:SetVertexColor(T.fg[1], T.fg[2], T.fg[3])
    ns.ShowTip(self, { self.labelText or "", f.doneOpen[self.dkey] and L.SUM_DONE_CLOSE or L.SUM_DONE_OPEN })
  end)
  b:SetScript("OnLeave", function(self)
    self.hl:Hide(); self.chev:SetVertexColor(T.accentSoft[1], T.accentSoft[2], T.accentSoft[3]); ns.HideTip()
  end)
  b:SetScript("OnMouseDown", function(self) self.text:SetPoint("LEFT", 26, -1) end)
  b:SetScript("OnMouseUp", function(self) self.text:SetPoint("LEFT", 26, 0) end)
  b:SetScript("OnClick", function(self)
    f.doneOpen[self.dkey] = not f.doneOpen[self.dkey] or nil
    if PlaySound then PlaySound(SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or 856) end
    Render()
  end)
  return b
end

local function OpenPicker()
  if f then f:Hide() end
  if ns.ShowPicker then ns.ShowPicker() end
end

-- =====================================================================
--  The Group tab: one row per ticked quest, one column per member
-- =====================================================================
-- Where a quest is taken, in a few words: "Rahauro · Thunder Bluff", "Rahauro · in the dungeon".
local function WhereText(q)
  local s = q.s
  if q.si and (not s or s.i) then return L.OV_ITEM_START:format(q.si) end
  if s and s.i then return (s.n and (s.n .. " · ") or "") .. L.OV_IN_DG end
  if s and s.m then
    local z = ZoneName(s.m)
    if s.n and z ~= "" then return s.n .. " · " .. z end
    return s.n or (z ~= "" and z or nil)
  end
  if q.st then return ns.T(q.st) end
end

-- "Check": reads the group again (the game's IsUnitOnQuest, WL Helper's members), then shares the
-- ticked quests of my log one by one (the share queue, 1.5 s apart): the game's answers fill the cells.
local function CheckGroup()
  if not f or f.checking or ns.pushBusy then return end
  local P = ns.PartyQuests
  if P and P.Refresh then pcall(P.Refresh, true) end
  if ns.SyncAsk and f.keys then pcall(ns.SyncAsk, f.keys) end
  local list = f.shareList or {}
  if #list > 0 and ns.PushQuests then
    f.checking = true
    local n = ns.PushQuests(list, function()
      f.checking = nil
      if f:IsShown() then Render() end
      if ns.Render then ns.Render() end
    end)
    if not n or n == 0 then f.checking = nil end
  end
  if f:IsShown() then Render() end
  -- the guide's share buttons grey out while the queue runs
  if ns.Render then ns.Render() end
end

local function MakeGroupPane(gp)
  local S = SW()
  gp.block = ns.Text(gp, ns.F.body, T.fg)
  gp.check = S.Button(gp, L.SUM_G_CHECK, 0, 24, "secondary", function() CheckGroup() end,
    function() return { L.SUM_G_CHECK, L.SUM_G_CHECK_TT } end)
  gp.check:SetPoint("TOPRIGHT", gp, "TOPRIGHT", 0, 0)
  local h = CreateFrame("Frame", nil, gp)
  h:SetSize(CW, 36)
  h.label = ns.Text(h, ns.F.meta, T.muted); h.label:SetPoint("BOTTOMLEFT", 0, 6)
  h.rule = ns.Rule(h); h.rule:SetPoint("BOTTOMLEFT"); h.rule:SetPoint("BOTTOMRIGHT")
  h.names, h.lvls, h.hits = {}, {}, {}
  gp.head = h
  gp.rows = {}
  gp.more = ns.Text(gp, ns.F.meta, T.muted); gp.more:Hide()
end

local function MakeGroupRow(parent)
  local S = SW()
  local r = CreateFrame("Frame", nil, parent)
  r.wlOwned = true
  r:SetWidth(CW)
  r.bg = ns.Tex(r, "BACKGROUND", T.cardFill); r.bg:SetAllPoints()
  ns.Outline(r, T.cardEdge)
  r.name = ns.Text(r, ns.F.body, T.fg)
  r.meta = ns.Text(r, ns.F.meta, T.muted)
  r.have = ns.Text(r, ns.F.meta, T.muted); r.have:SetWordWrap(false)
  r.share = S.Button(r, L.SUM_SHARE, 0, 24, "ghost", function(self)
    if r.shareId and ns.PushQuest and ns.PushQuest(r.shareId) then self:Flash(L.SUM_SHARED) end
  end, function()
    local tip = { L.SUM_SHARE }
    if r.shareWho and #r.shareWho > 0 then tip[#tip + 1] = L.SUM_SHARE_WHO:format(JoinNames(r.shareWho)) end
    tip[#tip + 1] = L.SUM_SHARE_TT:format(r.shareId and ns.QName(r.shareId) or "")
    return tip
  end)
  r.cells = {}
  return r
end

-- The group's state on the ticked quests: rows { qid, dkey, inf, states, has, open }, the count of
-- quests to sort out (someone lacks it, cannot take it, or is unknown) and what blocks most.
local BLOCK_ORDER = { { "low", "pre", "no" }, { "miss" } }
local BLOCK_KEY = { low = "SUM_G_BLOCK_LOW", pre = "SUM_G_BLOCK_PRE", no = "SUM_G_BLOCK_NO", miss = "SUM_G_BLOCK_MISS" }
local function GroupData(members, per, keys)
  local rows, seen = {}, {}
  for _, dkey in ipairs(keys) do
    for _, e in ipairs(per[dkey].todo) do
      if not IsOff(e.qid) and not seen[e.qid] then
        seen[e.qid] = true
        rows[#rows + 1] = { qid = e.qid, dkey = dkey, inf = e.inf }
      end
    end
  end
  local blocks, todo, unk = {}, 0, 0
  for _, row in ipairs(rows) do
    row.states, row.has = {}, 0
    local open, anyUnk = false, false
    for j, m in ipairs(members) do
      local s, why, src, pid = MemberState(m, row.qid, row.dkey)
      row.states[j] = { s = s, why = why, src = src, pid = pid }
      local b = BUCKET[s] or "unknown"
      if b == "has" then row.has = row.has + 1 end
      local k = (s == "low" and "low") or (s == "pre" and "pre") or (s == "invalid" and "no")
        or (b == "missing" and "miss") or (b == "unknown" and "unk") or nil
      if k then
        local bl = blocks[m.name] or {}; blocks[m.name] = bl
        bl[k] = (bl[k] or 0) + 1
        open = true
        if k == "unk" then anyUnk = true end
      end
    end
    row.open = open
    if open then todo = todo + 1 end
    if anyUnk then unk = unk + 1 end
  end
  local g = { rows = rows, todo = todo }
  -- what blocks most: a member who cannot take quests first, then one who lacks them, then unknowns
  for _, kinds in ipairs(BLOCK_ORDER) do
    local best, bn, bk = nil, 0, nil
    for _, m in ipairs(members) do
      local bl = blocks[m.name]
      if bl then for _, k in ipairs(kinds) do if (bl[k] or 0) > bn then best, bn, bk = m, bl[k], k end end end
    end
    if best then
      g.text = ns.Plural(bn, BLOCK_KEY[bk] .. "1", BLOCK_KEY[bk], best.name, bn)
      g.kind, g.who, g.n = (bk == "miss") and "miss" or "cannot", best.name, bn
      break
    end
  end
  if not g.text then
    if unk > 0 then g.text, g.kind = ns.Plural(unk, "SUM_G_BLOCK_UNK1", "SUM_G_BLOCK_UNK", unk), "unknown"
    elseif #rows > 0 then g.text, g.kind = L.SUM_G_ALLOK, "ok"
    else g.text, g.kind = L.SUM_GAIN0, "none" end
  end
  return g
end

-- Draws the Group tab; returns its height.
local function DrawGroup(gp, g, members, ctx)
  local y = 0
  -- the header line: what blocks most, "Check" at the right
  local busy = (f.checking or ns.pushBusy) and true or false
  gp.check:SetText(busy and L.SUM_G_CHECKING or L.SUM_G_CHECK)
  SetOn(gp.check, not busy)
  local bw = num(gp.check:GetWidth()) or 0
  if bw < 40 then bw = 90 end
  gp.block:SetText(g.text)
  local bc = (g.kind == "ok" and T.ok) or (g.kind == "cannot" and T.bad) or (g.kind == "miss" and T.warn) or T.text
  gp.block:SetTextColor(bc[1], bc[2], bc[3])
  gp.block:ClearAllPoints(); gp.block:SetPoint("TOPLEFT", gp, "TOPLEFT", 0, -4)
  local bh = LineH(gp.block, ns.F.body, CW - bw - 12, gp, 3)
  y = math.max(bh + 4, 24) + 12
  gp.blockText = g.text

  local h = gp.head
  local ncol, GCELLW = GroupCols(#members)
  gp.ncol, gp.cellW = ncol, GCELLW
  local x0 = CW - 8 - ncol * GCELLW        -- the first column's left edge
  local nameW = x0 - 12 - 12
  if #g.rows == 0 then
    h:Hide()
    for _, r in ipairs(gp.rows) do r:Hide() end
    gp.more:Hide()
    return y
  end
  -- the column heads: the name in its class colour, the level under it
  h.label:SetText(L.SUM_G_CELL_TT)
  h.label:SetWidth(math.max(40, x0 - 8))
  for j = 1, ncol do
    local m = members[j]
    local cc = ClassColor(m.class)
    local nf = h.names[j]
    if not nf then nf = ns.Text(h, ns.F.meta, T.fg); nf:SetJustifyH("CENTER"); h.names[j] = nf end
    nf:SetText(m.name); nf:SetTextColor(cc[1], cc[2], cc[3])
    nf:SetWidth(GCELLW - 4); nf:SetWordWrap(false)
    local lf = h.lvls[j]
    if not lf then lf = ns.Text(h, ns.F.meta, T.muted); lf:SetJustifyH("CENTER"); h.lvls[j] = lf end
    lf:SetText(m.level and L.SUM_LINK_LV:format(m.level) or "")
    lf:SetWidth(GCELLW - 4)
    local hit = h.hits[j]
    if not hit then
      hit = CreateFrame("Frame", nil, h)
      hit:EnableMouse(true)
      hit:SetScript("OnEnter", function(self) if self.tip then ns.ShowTip(self, self.tip) end end)
      hit:SetScript("OnLeave", ns.HideTip)
      h.hits[j] = hit
    end
    hit.tip = { { m.name, cc[1], cc[2], cc[3] }, m.level and L.SUM_LINK_LV:format(m.level) or nil }
    ns.ClampLabel(nf, m.name, hit)
    local x = x0 + (j - 1) * GCELLW
    nf:ClearAllPoints(); nf:SetPoint("TOPLEFT", h, "TOPLEFT", x + 2, -2); nf:Show()
    lf:ClearAllPoints(); lf:SetPoint("TOPLEFT", h, "TOPLEFT", x + 2, -16); lf:Show()
    hit:SetSize(GCELLW, 30)
    hit:ClearAllPoints(); hit:SetPoint("TOPLEFT", h, "TOPLEFT", x, 0); hit:Show()
  end
  for j = ncol + 1, #h.names do h.names[j]:Hide(); h.lvls[j]:Hide(); h.hits[j]:Hide() end
  h:SetWidth(CW)
  h:ClearAllPoints(); h:SetPoint("TOPLEFT", gp, "TOPLEFT", 0, -y); h:Show()
  y = y + 36 + 8

  for i, row in ipairs(g.rows) do
    local r = gp.rows[i] or MakeGroupRow(gp); gp.rows[i] = r
    r:SetWidth(CW)
    local q = ns.Q[row.qid] or {}
    r.qid, r.dkey, r.row = row.qid, row.dkey, row
    r.name:SetText(ns.QName(row.qid))
    r.name:ClearAllPoints(); r.name:SetPoint("TOPLEFT", 12, -8)
    local rh = 8 + LineH(r.name, ns.F.body, nameW, r)
    local meta = {}
    if q.l then meta[#meta + 1] = L.SUM_LINK_LV:format(q.l) end
    local where = WhereText(q)
    if where then meta[#meta + 1] = where end
    if #meta > 0 then
      r.meta:SetText(table.concat(meta, " · "))
      r.meta:ClearAllPoints(); r.meta:SetPoint("TOPLEFT", 12, -(rh + 2)); r.meta:Show()
      rh = rh + 2 + LineH(r.meta, ns.F.meta, nameW, r)
    else r.meta:SetText(""); r.meta:Hide() end
    -- "2/3 l'ont", then "Share" while someone lacks it and it can be shared
    local lineY = rh + 4
    r.have:SetText(L.SUM_G_HAVE:format(row.has, #members))
    local hc = (row.has == #members) and T.ok or T.muted
    r.have:SetTextColor(hc[1], hc[2], hc[3])
    r.have:ClearAllPoints(); r.have:SetPoint("TOPLEFT", 12, -(lineY + 5)); r.have:Show()
    local shareId = ctx.grouped and ShareTarget(row.qid, row.inf.pre, ctx.log) or nil
    local who = {}
    for j, st in ipairs(row.states) do
      if NEED_SHARE[st.s] or (st.s == "pre" and shareId and shareId ~= row.qid) then who[#who + 1] = members[j].name end
    end
    r.shareId, r.shareWho = shareId, who
    if shareId and #who > 0 then
      local hw = ns.TextWidth and num(ns.TextWidth(r.have)) or 60
      r.share:ClearAllPoints(); r.share:SetPoint("TOPLEFT", r, "TOPLEFT", 12 + (hw or 60) + 8, -lineY); r.share:Show()
    else r.share:Hide() end
    rh = lineY + 24 + 8
    rh = math.ceil(math.max(rh, 52))
    r:SetHeight(rh)
    -- one cell per member, centred on the row
    for j = 1, ncol do
      local c = r.cells[j] or MakeCell(r); r.cells[j] = c
      FillCell(c, members[j], row.qid, row.dkey, row.states[j])
      c:SetWidth(GCELLW)
      c:ClearAllPoints(); c:SetPoint("TOPLEFT", r, "TOPLEFT", x0 + (j - 1) * GCELLW, -math.floor((rh - 24) / 2))
      c:Show()
    end
    for j = ncol + 1, #r.cells do r.cells[j]:Hide() end
    r:ClearAllPoints(); r:SetPoint("TOPLEFT", gp, "TOPLEFT", 0, -y); r:Show()
    y = y + rh + ROW_GAP
  end
  for i = #g.rows + 1, #gp.rows do gp.rows[i]:Hide() end
  y = y - ROW_GAP
  -- a raid: the members past the columns
  if #members > ncol then
    local n = #members - ncol
    gp.more:SetText(ns.Plural(n, "SUM_G_MORE1", "SUM_G_MORE", n))
    gp.more:ClearAllPoints(); gp.more:SetPoint("TOPLEFT", gp, "TOPLEFT", 0, -(y + 8)); gp.more:Show()
    y = y + 8 + LineH(gp.more, ns.F.meta, CW, gp)
  else gp.more:Hide() end
  return y
end

-- The window's size now: what it was given (the rule or the player's drag), or the rule's default
-- while the frame cannot tell (not laid out yet).
local function WinSize()
  local defW, defH, minW, minH = 640, 600, 600, 300
  if f.SizeRule then defW, defH, minW, minH = f:SizeRule() end
  local w, h = num(f:GetWidth()), num(f:GetHeight())
  if not w or w < (minW or 0) - 1 then w = defW end
  if not h or h < (minH or 0) - 1 then h = defH end
  return math.floor(w), math.floor(h)
end
-- W and CW from the window's width (every render reads them)
local function Dims()
  local w, h = WinSize()
  W = w
  CW = W - 2 * PAD
  return w, h
end
ns.OverviewDims = function() if f then Dims() end; return W, CW end   -- for the offline tests

-- The picture keeps its look at any width: the crop chosen for a 608 px band gets shorter (centred)
-- as the band gets wider, so the picture is never stretched.
local function CropArt(tex, w)
  if not (tex and tex.GetTexCoord and w and w > ART_W0) then return end
  local ok, l, t, _, b, r = pcall(tex.GetTexCoord, tex)
  if not (ok and type(l) == "number" and type(t) == "number" and type(b) == "number" and type(r) == "number") then return end
  if secret(l) or secret(t) or secret(b) or secret(r) or b <= t then return end
  local mid, half = (t + b) / 2, (b - t) * ART_W0 / w / 2
  tex:SetTexCoord(l, r, mid - half, mid + half)
end

local function Build()
  local S = SW()
  -- a workspace window (DESIGN 3.1): its size from the screen, resizable, the size kept
  f = S.Window("WLHelperOverview", W, 600, "", L.SUM_T, WLDTDB, "ovPos", { header = 44, minH = 120, strata = "HIGH", size = "workspace" })
  f.open, f.doneOpen = {}, {}
  -- a new size: the same content laid out again (at most once per frame while dragging)
  f.OnResize = function() if f.keys and Render then Render() end end

  f.sa = S.ScrollArea(f)
  f.child = f.sa.child
  f.child:SetWidth(CW)
  -- two panes in the scroll area: the quests (the list below) and the group's table, under tabs
  -- shown only in a group
  f.qPane = CreateFrame("Frame", nil, f.child)
  f.qPane:SetPoint("TOPLEFT", f.child, "TOPLEFT", 0, 0); f.qPane:SetSize(CW, 1)
  f.qGrid = ns.Grid()
  f.gPane = CreateFrame("Frame", nil, f.child)
  f.gPane:SetPoint("TOPLEFT", f.child, "TOPLEFT", 0, 0); f.gPane:SetSize(CW, 1); f.gPane:Hide()
  MakeGroupPane(f.gPane)
  f.tab = "quests"
  f.tabBar = S.Tabs(f, { { "quests", L.SUM_TAB_Q }, { "group", L.SUM_TAB_G } }, function() return f.tab end, function(k)
    if f.tab ~= k then
      f.tab = k
      if f.sa then f.sa:ScrollTo(0, true) end
      if PlaySound then PlaySound(SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or 856) end
    end
    Render()
  end)
  local tabY = -((f.headerH or 44) + 1)
  f.tabBar:SetPoint("TOPLEFT", f, "TOPLEFT", 0, tabY); f.tabBar:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, tabY)
  f.tabBar:Hide()
  local c = f.qPane
  f.heroes, f.gpsBtns, f.notes, f.rows, f.heads, f.folds = {}, {}, {}, {}, {}, {}
  f.rdyLines, f.rdySubs = {}, {}
  -- the facts of each dungeon: the short ones (entrance, key) as label-value rows (ns.TyFact),
  -- the long ones (before you go in, you get) as a block heading (ns.TyHeading, gold) over their
  -- values (13). factLabels: every fact's label in order, row or heading
  f.factHeads, f.factLabels, f.factValues, f.factRows = {}, {}, {}, {}
  -- several dungeons: the whole route's gains at the end
  f.routeHead = MakeHead(c); f.routeHead:Hide()
  f.routeLine = ns.Text(c, ns.F.body, T.fg); f.routeLine:Hide()
  f.empty = S.EmptyState(c, "portal", L.OV_EMPTY_T, L.OV_EMPTY)
  f.empty:Hide()
  -- every quest turned in: the fact, and the way to another dungeon (secondary: the bar's
  -- "Guide me through the dungeon" is the one primary)
  f.allDone = S.EmptyState(c, "check", "", nil, L.SUM_OTHER_DG, OpenPicker, "secondary")
  f.allDone:Hide()

  -- pinned at the bottom: share all (in a group), close, the route button (the one primary)
  f.bar = CreateFrame("Frame", nil, f)
  f.bar:SetHeight(32)
  -- starts the route on these dungeons, or goes back to it when it already runs on them.
  -- mode: the button's ("start", "update", "back"); run: walk them through with no quest
  local function Go(mode, run)
    local keys = f.keys
    if not keys or #keys == 0 then return end
    -- the route of these dungeons already runs: back to it (the ticks already replanned it);
    -- starting again would forget the steps marked done by hand
    if mode ~= "start" then
      f:Hide()
      if ns.ShowGuide then ns.ShowGuide() end
      return
    end
    WLDTDB.sel = WLDTDB.sel or {}
    wipe(WLDTDB.sel)
    local runs = run and {} or nil
    for _, k in ipairs(keys) do
      WLDTDB.sel[k] = true
      if runs and ns.Runnable(k) then runs[k] = true end
    end
    f:Hide()
    ns.StartGuide(runs)
  end
  f.goBtn = S.Button(f.bar, L.SUM_GO, 0, 32, "primary", function() Go(f.mode) end, function()
    if f.mode == "update" then return { L.SUM_UPDATE, L.SUM_UPDATE_TT } end
    if f.mode == "back" then return { L.SUM_BACK, L.SUM_BACK_TT } end
    if f.replaces then return { L.SUM_GO_HERE, L.SUM_GO_HERE_TT } end
    return { L.SUM_GO, f.one and L.SUM_GO_TT1 or L.SUM_GO_TT }
  end)
  f.goBtn:SetPoint("RIGHT", 0, 0)
  f.goBtn:SetDisabledReason(L.SUM_GO_WHY)
  -- no quest left to do: the dungeon's walkthrough all the same (the engine then makes the route
  -- go to the entrance, then from boss to boss); it takes the route button's place
  f.runBtn = S.Button(f.bar, L.SUM_RUN, 0, 32, "primary", function() Go(f.runMode, true) end, function()
    if f.runMode ~= "start" then return { L.SUM_BACK, L.SUM_BACK_TT } end
    if f.runReplaces then return { L.SUM_GO_HERE, L.SUM_GO_HERE_TT } end
    return { f.runLabel or L.SUM_RUN, L.SUM_RUN_TT }
  end)
  f.runBtn:SetPoint("RIGHT", 0, 0)
  f.runBtn:Hide()
  -- opened from the picker (which hides itself): the way back to it; else close
  f.closeBtn = S.Button(f.bar, L.SUM_CLOSE, 0, 28, "secondary", function()
    if f.backPick then OpenPicker() else f:Hide() end
  end, function()
    if f.backPick then return { L.SUM_BACK_PICK, L.SUM_BACK_PICK_TT } end
    return { L.SUM_CLOSE, L.SUM_CLOSE_TT }
  end)
  f.closeBtn:SetPoint("RIGHT", f.goBtn, "LEFT", -8, 0)
  f.shareAll = S.Button(f.bar, L.SUM_SHARE_ALL, 0, 28, "secondary", function(self)
    local list = f.shareList or {}
    if #list == 0 or not ns.PushQuests then return end
    SetOn(self, false)
    -- the guide's share buttons grey out while this runs and come back when it ends
    ns.PushQuests(list, function() if f:IsShown() then Render() end; if ns.Render then ns.Render() end end)
    if self:IsEnabled() == false and ns.pushBusy then self:SetText(L.SUM_SHARING) end
    if ns.Render then ns.Render() end
  end, function() return { L.SUM_SHARE_ALL, L.SUM_SHARE_ALL_TT } end)
  f.shareAll:SetPoint("LEFT", 0, 0)
  f.shareAll:SetDisabledReason(L.SUM_SHARE_WHY)

  -- the summary follows the quest log, the level and the bags while it is open
  local ev = CreateFrame("Frame", nil, f)
  f.events = ev
  for _, e in ipairs({ "QUEST_LOG_UPDATE", "QUEST_TURNED_IN", "PLAYER_LEVEL_UP", "BAG_UPDATE_DELAYED", "GET_ITEM_INFO_RECEIVED", "GROUP_ROSTER_UPDATE" }) do
    pcall(ev.RegisterEvent, ev, e)
  end
  local queued = false
  local function soon()
    if queued or not f:IsShown() then return end
    queued = true
    local fn = function() queued = false; if f:IsShown() then Render() end end
    if C_Timer and C_Timer.After then C_Timer.After(0.3, fn) else fn() end
  end
  -- the group's answers (IsUnitOnQuest, the answers to a share) fill the Group tab
  if ns.PartyQuests and ns.PartyQuests.OnChange then ns.PartyQuests.OnChange(soon) end
  ev:SetScript("OnEvent", function(_, e, a1, a2)
    if e == "GET_ITEM_INFO_RECEIVED" then
      -- only an item the summary waits for (an id it shows, or any while a name is not cached);
      -- the many items arriving at once make one render (the 0.3 s queue below). An item the
      -- server does not know (success false) is remembered and renders nothing.
      local id = num(a1)
      if id and a2 == false then failedItems[id] = true; pendingItems[id] = nil; return end
      if not (pendingName or (id and pendingItems[id]) or not id) then return end
      if id then pendingItems[id] = nil end
      wipe(rewardCache)
    end
    soon()
  end)
end

-- "8 quêtes cochées · 42 300 XP (environ 80 % d'un niveau) · 1 po 15 pa · 3 objets dont 1
-- amélioration": what a dungeon (or the whole route) gives for the ticked quests.
local function GainsText(a)
  local parts = { ns.Plural(a.ticked, "SUM_GQ1", "SUM_GQ", a.ticked) }
  if a.xp > 0 then
    local x = L.SUM_XP:format(Big(a.xp))
    local share = LevelShare(a.xp)
    if share then x = x .. " " .. share end
    parts[#parts + 1] = x
  end
  if a.money > 0 then parts[#parts + 1] = Money(a.money) end
  -- "4 objets dont 2 améliorations" (one per quest at most for rewards to choose from)
  if a.items > 0 then
    local it = ns.Plural(a.items, "SUM_IT1", "SUM_IT", a.items)
    if a.up > 0 then
      local single = a.up == 1 or (ns.lang == "fr" and a.up == 0)
      local fmt = (single and L.SUM_IT_UP1 or L.SUM_IT_UP):gsub("%%d", ns.Hex(T.ok) .. "%%d|r", 1)
      it = fmt:format(it, a.up)
    end
    parts[#parts + 1] = it
  end
  return table.concat(parts, " · ")
end

-- =====================================================================
--  Render
-- =====================================================================
Render = function()
  if not (f and f.keys and #f.keys > 0) then return end
  local S = SW()
  ResetRenderCaches()
  pendingName = false
  local keys = {}
  for _, k in ipairs(f.keys) do if ns.D[k] then keys[#keys + 1] = k end end
  if #keys == 0 then f:Hide(); return end
  local _, winH = Dims()
  f.qPane:SetWidth(CW); f.gPane:SetWidth(CW); f.child:SetWidth(CW)
  local log = ns.LogEntries()
  local cls, lvl = Cls(), Level()
  local members = Members()
  local ctx = { log = log, cls = cls, lvl = lvl, members = members, grouped = #members > 0 }
  local multi = #keys > 1
  f.title:SetText(multi and L.SUM_ROUTE_T or L.SUM_T)
  local c = f.qPane

  -- every quest's facts first: the defaults, then the gains of the ticked ones, per dungeon and
  -- for the whole route (a quest shared by two dungeons counts once in the route)
  local per, sel, seen = {}, {}, {}
  local routeChanged = false
  local function Acc() return { ticked = 0, q = 0, xp = 0, money = 0, items = 0, up = 0 } end
  local route, acc, seenD, facts = Acc(), {}, {}, {}
  local nQuests, nTodo = 0, 0
  local shareList, shareSeen, seenTick = {}, {}, {}
  local function add(a, id)
    local fc = facts[id]
    if not fc then
      local q = ns.Q[id]
      fc = { xp = (XPFor(id, lvl)), money = QuestMoney(id), items = q and ItemCount(id, q) or 0, up = q and UpCount(id, q) or 0 }
      facts[id] = fc
    end
    a.q = a.q + 1; a.xp = a.xp + fc.xp; a.money = a.money + fc.money
    a.items = a.items + fc.items; a.up = a.up + fc.up
  end
  local function count(id, dkey)
    if not seen[id] then seen[id] = true; add(route, id) end
    if not seenD[dkey][id] then seenD[dkey][id] = true; add(acc[dkey], id) end
  end
  for _, dkey in ipairs(keys) do
    local todo, done = {}, {}
    acc[dkey], seenD[dkey] = Acc(), {}
    for _, qid in ipairs(ns.DungeonQuests(dkey, cls)) do
      local inf = Info(qid, dkey, ctx)
      if ApplyDefault(qid, inf) and WLDTDB.sel and WLDTDB.sel[dkey] then routeChanged = true end
      nQuests = nQuests + 1
      if inf.st == "done" then done[#done + 1] = { qid = qid, inf = inf }
      else
        nTodo = nTodo + 1
        todo[#todo + 1] = { qid = qid, inf = inf }
      end
      if not IsOff(qid) and inf.st ~= "done" then
        sel[#sel + 1] = { qid = qid, dkey = dkey, st = inf.st }
        acc[dkey].ticked = acc[dkey].ticked + 1
        if not seenTick[qid] then seenTick[qid] = true; route.ticked = route.ticked + 1 end
        for k, pid in ipairs(inf.pre.chain) do if inf.pre.states[k] ~= "done" then count(pid, dkey) end end
        count(qid, dkey)
        local function addShare(id)
          local q = ns.Q[id]
          if not shareSeen[id] and log[id] and q and q.sh ~= false and (not ns.Pushable or ns.Pushable(id, log[id])) then
            shareSeen[id] = true; shareList[#shareList + 1] = id
          end
        end
        for _, pid in ipairs(inf.pre.chain) do addShare(pid) end
        addShare(qid)
      end
    end
    -- to do by level, turned in by level
    local function byLevel(a, b)
      local la, lb = a.inf.q.l or 0, b.inf.q.l or 0
      if la ~= lb then return la < lb end
      return a.qid < b.qid
    end
    table.sort(todo, byLevel); table.sort(done, byLevel)
    per[dkey] = { todo = todo, done = done }
  end
  f.shareList = shareList
  f.gains, f.routeGains = acc, route
  f.totalsInfo = { quests = route.q, xp = route.xp, money = route.money, items = route.items, upgrades = route.up }
  -- the subtitle: "2 donjons · 23 quêtes cochées · 131 970 XP" (the picture names one dungeon)
  do
    local parts = {}
    if multi then parts[#parts + 1] = ns.Plural(#keys, "SUM_DG1", "SUM_DG", #keys) end
    if multi and route.ticked > 0 then
      parts[#parts + 1] = ns.Plural(route.ticked, "SUM_GQ1", "SUM_GQ", route.ticked)
      if route.xp > 0 then parts[#parts + 1] = L.SUM_XP:format(Big(route.xp)) end
    end
    f.subtitle:SetText(table.concat(parts, " · "))
  end
  -- the guide's "before entering" list (Engine PreEntry) over the ticks: what to pick up outside
  local pe, peB, peI = {}, {}, {}
  if ns.PreEntryQuests then
    local s = {}
    for _, k in ipairs(keys) do s[k] = true end
    local ok, res = pcall(ns.PreEntryQuests, s, cls)
    if ok and type(res) == "table" then pe = res end
  end
  for _, v in pairs(pe) do
    for id in pairs(v.before) do peB[id] = true end
    for id in pairs(v.inside) do peI[id] = true end
  end
  ctx.peBefore, ctx.peInside = peB, peI
  f.ready = {}
  f.gainFs = {}
  local allDone = nQuests > 0 and nTodo == 0
  f.allDoneNow = allDone
  -- nothing left to do but a dungeon to walk through (a class-quest card is no place to run)
  local runnable = false
  if nTodo == 0 then
    for _, k in ipairs(keys) do if ns.Runnable(k) then runnable = true end end
  end
  -- a default changed (a level up) for a dungeon of the running route: the route follows, once
  if routeChanged and ns.route and ns.frame and ns.frame:IsShown() then
    RebuildRouteSoon()
  end

  local y = 0
  local hi, gi, ni, ri, hdi, fi = 0, 0, 0, 0, 0, 0
  local rli, rsi, fli, fvi, fri, fla = 0, 0, 0, 0, 0, 0
  local allDoneShown, routeShown = false, false

  local function AllDoneBlock(title)
    f.allDone:ClearAllPoints(); f.allDone:SetPoint("TOP", c, "TOP", 0, -(y + 12))
    f.allDone:SetWrapWidth(CW)
    local eh = f.allDone:Set("check", title, runnable and (#keys > 1 and L.SUM_RUN_SUB_N or L.SUM_RUN_SUB) or nil, L.SUM_OTHER_DG, OpenPicker, "secondary")
    f.allDone:Show(); allDoneShown = true
    y = y + 12 + (num(eh) or 80) + 12
  end

  -- The facts: a block heading (DESIGN 3.21: gold, 14 above unless first, 4 below) over its
  -- value lines, which start at the left edge and take the whole width.
  -- fx, fw: the column the facts go in (the whole width, or a cell of the facts' grid)
  local fx, fw, cellFirst = 0, CW, false
  local function FactLabel(text, first)
    fli = fli + 1
    local h = f.factHeads[fli] or ns.TyHeading(c); f.factHeads[fli] = h
    fla = fla + 1; f.factLabels[fla] = h.fs
    y = y + h:Place(text, fx, y, fw, { first = first or cellFirst })
    cellFirst = false
    return h.fs
  end
  -- a short fact on one row: label 12 muted in a column shared by the entrance and the key, the
  -- value 12 beside it (under the label when narrow). 4 above unless first; y moves under it
  local function FactRow(label, value, color, w, first)
    fri = fri + 1
    local fc = f.factRows[fri] or ns.TyFact(c); f.factRows[fri] = fc
    fla = fla + 1; f.factLabels[fla] = fc.label
    local lw = math.ceil(math.max(ns.TextWidth(fc.label, L.SUM_F_ENTRY) or 0, ns.TextWidth(fc.label, L.SUM_F_KEY) or 0))
    if not first then y = y + ns.TY.gap end
    local top = y
    y = y + fc:Place(label, value, fx, y, w or fw, { labelW = lw, valueColor = color })
    cellFirst = false
    return fc, top
  end
  -- one value line at y (y moves under it)
  local function FactValue(text, color, w, maxLines)
    fvi = fvi + 1
    local fs = f.factValues[fvi] or ns.Text(c, ns.F.body, T.text); f.factValues[fvi] = fs
    fs:SetText(text)
    local col = color or T.text
    fs:SetTextColor(col[1], col[2], col[3])
    fs:ClearAllPoints(); fs:SetPoint("TOPLEFT", c, "TOPLEFT", fx, -y)
    fs:Show()
    y = y + LineH(fs, ns.F.body, w or fw, c, maxLines)
    return fs
  end
  -- a detail under a value (11 muted)
  local function SubLine(text)
    rsi = rsi + 1
    local fs = f.rdySubs[rsi] or ns.Text(c, ns.F.meta, T.muted); f.rdySubs[rsi] = fs
    fs:SetText(text)
    fs:SetTextColor(T.muted[1], T.muted[2], T.muted[3])
    fs:ClearAllPoints(); fs:SetPoint("TOPLEFT", c, "TOPLEFT", fx, -(y + 3))
    fs:Show()
    y = y + 3 + LineH(fs, ns.F.meta, fw, c)
    return fs
  end

  -- "Before you go in": the ticked quests given outside (the guide's "before entering" list), in
  -- your log or not; the ones still to pick up by name, each with what it waits on
  local MAX_MISS = 5
  local function ReadyBlock(dkey)
    local rd = pe[dkey]
    local have, miss, inside = 0, {}, 0
    if rd then
      for id in pairs(rd.before) do
        local s = QState(log, id)
        if s == "on" or s == "ready" then have = have + 1 elseif s == "none" then miss[#miss + 1] = id end
      end
      for id in pairs(rd.inside) do
        if not rd.before[id] and QState(log, id) == "none" then inside = inside + 1 end
      end
    end
    local nOut = have + #miss
    if nOut + inside == 0 then FactValue(L.SUM_RDY_NOTHING, T.text); return end
    local info = { have = have, missing = miss, inside = inside, lines = {} }
    f.ready[dkey] = info
    if #miss == 0 then
      if nOut == 0 then info.head = FactValue(L.SUM_RDY_NOTHING, T.text)
      else info.head = FactValue(ns.Plural(nOut, "SUM_RDY_OK1", "SUM_RDY_OK", nOut), T.ok) end
      if inside > 0 then
        info.sub = SubLine(nOut == 0 and ns.Plural(inside, "SUM_RDY_INALL1", "SUM_RDY_INALL")
          or ns.Plural(inside, "SUM_RDY_IN1", "SUM_RDY_IN", inside))
      end
      return
    end
    info.head = FactValue(ns.Plural(#miss, "SUM_RDY_MISS1", "SUM_RDY_MISS", #miss), T.warn)
    table.sort(miss, function(a, b)
      local la, lb = ns.Q[a].l or 0, ns.Q[b].l or 0
      if la ~= lb then return la < lb end
      return a < b
    end)
    y = y + 4
    local lw = fw
    for i, id in ipairs(miss) do
      if i > MAX_MISS then break end
      local q = ns.Q[id]
      local why, pre = TakeWhy(log, id, q, lvl, cls)
      rli = rli + 1
      local o = f.rdyLines[rli] or MakeReadyLine(c); f.rdyLines[rli] = o
      o.qid = id
      o.point = PointFor(log, id, q, "none", pre)
      local name = ns.QName(id)
      o.text:SetText(why and (name .. " · " .. why) or name)
      local tc = why and T.muted or T.text
      o.text:SetTextColor(tc[1], tc[2], tc[3])
      -- the pin only where a click guides somewhere (not while it waits)
      o.icon:SetShown(o.point ~= nil and not why)
      local tip = { name }
      local g = GiverText(q, "none")
      if g then tip[#tip + 1] = g end
      if why then tip[#tip + 1] = { why, T.warn[1], T.warn[2], T.warn[3] } end
      if o.point then
        tip[#tip + 1] = L.OV_GPS_T:format(o.point[4] or "")
        tip[#tip + 1] = L.OV_GPS_CLICK
      end
      o.tip = tip
      local th = LineH(o.text, ns.F.meta, lw - 16, o)
      o:SetSize(lw, th + 3)
      o:ClearAllPoints(); o:SetPoint("TOPLEFT", c, "TOPLEFT", fx, -y)
      o:Show()
      info.lines[#info.lines + 1] = o
      y = y + th + 3 + 2
    end
    y = y - 2
    if #miss > MAX_MISS then
      info.more = SubLine(ns.Plural(#miss - MAX_MISS, "SUM_RDY_MORE1", "SUM_RDY_MORE", #miss - MAX_MISS))
    end
    if inside > 0 then
      info.sub = SubLine(ns.Plural(inside, "SUM_RDY_IN1", "SUM_RDY_IN", inside))
    end
  end
  -- one fact: its heading, then its value(s) under it; the next heading brings its own space
  local nFact = 0
  local function Fact(label, fill)
    local top = y
    FactLabel(label, nFact == 0)
    nFact = nFact + 1
    fill()
    return top
  end

  -- quest cards through the grid (3.22): one column in a narrow window, 2 or 3 side by side in a
  -- wide one (a line's cards take its tallest one's height); a card with its chain unfolded takes
  -- the whole line (the timeline reads at full width). y moves under them.
  local function Cards(list, dkey)
    local g = f.qGrid
    local n = ns.Cols(CW, QGRID.minW, QGRID.gap, QGRID.maxCols, QGRID.minPx)
    QGRID.rowGap = (n > 1) and 8 or ROW_GAP
    g:Begin(c, 0, y, CW, QGRID)
    for _, e in ipairs(list) do
      ri = ri + 1
      local r = f.rows[ri] or MakeRow(c); f.rows[ri] = r
      g:Add(r, function(fr, w) return FillRow(fr, e.qid, dkey, e.inf, ctx, w) end, f.open[e.qid] and { span = "full" } or nil)
      r:Show(); r.shownNow = true
    end
    local gh, gn, gw = g:End()
    f.qCols, f.qColW = gn, gw
    y = y + gh
  end

  -- several dungeons, every quest turned in: the fact first
  if multi and allDone then AllDoneBlock(L.SUM_ALLDONE_TN) end

  -- the dungeons, one after the other: picture, facts (entrance, key, before you go in, gains),
  -- quests to do, quests turned in
  for di, dkey in ipairs(keys) do
    local d = ns.D[dkey]
    local todo, done = per[dkey].todo, per[dkey].done
    if di > 1 then y = y + 24 elseif y > 0 then y = y + 8 end
    hi = hi + 1
    local hero = f.heroes[hi] or MakeHero(c); f.heroes[hi] = hero
    if hi == 1 then f.hero = hero end
    local hh = multi and HERO_H_MULTI or HERO_H
    hero:SetSize(CW, hh)
    hero:ClearAllPoints(); hero:SetPoint("TOPLEFT", c, "TOPLEFT", 0, -y)
    -- crop only a real picture: DungeonArt sets its coords afresh each time, the plain fallback
    -- colour does not (cropping it again at every render would shrink its coords to nothing)
    if ns.DungeonArt and ns.DungeonArt(hero.art, dkey, hero.big) then CropArt(hero.art, CW - 2) end
    -- "Conseillé niv. 38 à 48 · Groupe de 5 · tu es niv. 41" (your level in orange when below)
    local parts = {}
    local lo = d.lvl and d.lvl[1]
    if lo then
      local hi2 = d.lvl[2] or lo
      table.insert(parts, lo == hi2 and L.SUM_HERO_LV1:format(lo) or L.SUM_HERO_LV:format(lo, hi2))
    end
    table.insert(parts, L.SUM_SIZE:format(d.size or 5))
    local you = L.SUM_HERO_YOU:format(lvl)
    if lo and lvl < lo then you = ns.Hex(T.warn) .. you .. "|r" end
    table.insert(parts, you)
    hero.lvl:SetText(table.concat(parts, " · "))
    hero.name:SetText(ns.DName(dkey))
    local lvlH = LineH(hero.lvl, ns.F.meta, CW - 24, hero, 1)
    local nameH = LineH(hero.name, ns.F.heading, CW - 24, hero, 1)
    hero.band:SetHeight(math.min(hh - 2, 8 + nameH + 3 + lvlH + 8))
    hero:Show()
    y = y + hh + 12

    local dgDone = #todo == 0 and #done > 0
    -- one dungeon, every quest turned in: say it at the top, offer another dungeon
    if not multi and dgDone then AllDoneBlock(L.SUM_ALLDONE_T:format(ns.DName(dkey))) end

    -- where is it, can I go, what do I get: only while something is left to do
    nFact = 0
    if not dgDone then
      local cells = {}
      -- cell 1: where is it (with its GPS) and the key, as label-value rows
      cells[1] = function()
      local point = d.e and d.e.m and { d.e.m, d.e.x, d.e.y, ns.DName(dkey) } or nil
      local loc = (GetLocale and GetLocale() == "frFR" and d.locf) or ns.T(d.loc) or ""
      if d.cq and d.home then loc = L.CQ_IN:format(ns.DName(d.home)) end
      local entry = ns.T(d.ed) or loc
      if entry and entry ~= "" then
        nFact = nFact + 1
        local _, top = FactRow(L.SUM_F_ENTRY, entry, T.fg, fw - (point and 32 or 0), true)
        do
          if point then
            gi = gi + 1
            local g = f.gpsBtns[gi]
            if not g then
              g = S.IconButton(c, "pin", 24, function(self) return { L.OV_GPS_T:format(L.OV_ENTRY_T), L.OV_GPS_CLICK } end,
                function(self) GoPoint(self.point) end)
              f.gpsBtns[gi] = g
            end
            g.point = point
            -- the pin on the row's middle, at the right of its column; the next row clears it
            g:ClearAllPoints(); g:SetPoint("TOPRIGHT", c, "TOPLEFT", fx + fw, -(top - 6))
            g:Show()
            if gi == 1 then f.entryGps = g; f.entryPoint = point end
            y = math.max(y, top + 18)
          end
        end
      end
      do
        local kl = ns.KeyLines and ns.KeyLines(dkey, true) or {}
        local kv = {}
        for _, k in ipairs(kl) do kv[#kv + 1] = k[1] end
        FactRow(L.SUM_F_KEY, #kv == 0 and L.OV_KEY_NONE or table.concat(kv, "\n"), #kv == 0 and T.muted or T.fg, nil, nFact == 0)
        nFact = nFact + 1
      end
      end
      -- cell 2: before you go in; cell 3: what you get
      cells[2] = function() Fact(L.SUM_F_READY, function() ReadyBlock(dkey) end) end
      if #todo > 0 then
        cells[3] = function()
          Fact(L.SUM_F_GAIN, function()
            local a = acc[dkey]
            if a.ticked > 0 then f.gainFs[dkey] = FactValue(GainsText(a), T.fg, nil, 3)
            else f.gainFs[dkey] = FactValue(L.SUM_GAIN0, T.muted) end
          end)
        end
      end
      -- a wide window puts them side by side (3.22, columns of at least FACT_MIN, every cell's
      -- heading on the line's top); a narrow one keeps them one under the other
      local nc, colW, xs, lastW = ns.Cols(CW, FACT_MIN, FACT_GAP, #cells, 200)
      f.factCols = { n = nc, colW = colW, xs = xs }
      if nc <= 1 then
        for _, cell in ipairs(cells) do cell() end
      else
        local lineTop, lineBottom = y, y
        for i, cell in ipairs(cells) do
          local col = (i - 1) % nc + 1
          if col == 1 and i > 1 then lineTop = lineBottom + FACT_ROWGAP; lineBottom = lineTop end
          fx, fw = xs[col], (col == nc) and lastW or colW
          y, cellFirst = lineTop, true
          cell()
          if y > lineBottom then lineBottom = y end
        end
        y = lineBottom
        fx, fw, cellFirst = 0, CW, false
      end
      y = y + 16
    end

    if #todo == 0 and #done == 0 then
      if multi then
        ni = ni + 1
        local fs = f.notes[ni] or ns.Text(c, ns.F.body, T.muted); f.notes[ni] = fs
        fs:SetText(L.SUM_NOQ)
        fs:ClearAllPoints(); fs:SetPoint("TOPLEFT", c, "TOPLEFT", 0, -y); fs:Show()
        y = y + LineH(fs, ns.F.body, CW, c)
      else
        local up = d.up and time() < d.up
        local why = L.OV_EMPTY
        if up then why = L.OV_EMPTY_UP elseif #(d.q or {}) == 0 then why = L.OV_EMPTY_NONE end
        f.empty:ClearAllPoints(); f.empty:SetPoint("TOP", c, "TOP", 0, -(y + 12))
        f.empty:SetWrapWidth(CW)
        local eh = f.empty:Set("portal", L.OV_EMPTY_T, why)
        f.empty:Show()
        y = y + 12 + (num(eh) or 80)
      end
    else
      if multi and dgDone and not allDone then
        ni = ni + 1
        local fs = f.notes[ni] or ns.Text(c, ns.F.body, T.muted); f.notes[ni] = fs
        fs:SetText(L.SUM_ALLDONE_NOTE:format(ns.DName(dkey)))
        fs:ClearAllPoints(); fs:SetPoint("TOPLEFT", c, "TOPLEFT", 0, -y); fs:Show()
        y = y + LineH(fs, ns.F.body, CW, c) + 8
      end
      -- quests to do: a header with the members' names over their columns, then the rows
      if #todo > 0 then
        hdi = hdi + 1
        local hd = f.heads[hdi] or MakeHead(c); f.heads[hdi] = hd
        hd:SetWidth(CW)
        hd.label:SetText(L.SUM_TODO)
        hd.count:SetText(tostring(#todo))
        hd:ClearAllPoints(); hd:SetPoint("TOPLEFT", c, "TOPLEFT", 0, -y)
        hd:Show()
        y = y + 24 + 8
        Cards(todo, dkey)
      end
      -- quests turned in: folded at the bottom
      if #done > 0 then
        if #todo > 0 then y = y + 12 end
        fi = fi + 1
        local fb = f.folds[fi] or MakeFold(c); f.folds[fi] = fb
        fb:SetWidth(CW); fb.text:SetWidth(CW - 34)
        fb.dkey = dkey
        fb.labelText = L.SUM_DONE_H:format(#done)
        fb.text:SetText(fb.labelText)
        ns.SetHDIcon(fb.chev, f.doneOpen[dkey] and "chevron_down" or "chevron_right", T.accentSoft)
        fb:ClearAllPoints(); fb:SetPoint("TOPLEFT", c, "TOPLEFT", 0, -y)
        fb:Show()
        y = y + 28
        if f.doneOpen[dkey] then
          y = y + 8
          Cards(done, dkey)
        end
      end
    end
  end

  -- several dungeons with ticked quests: what the whole route gives, at the end
  if multi then
    local nWith = 0
    for _, k in ipairs(keys) do if acc[k].ticked > 0 then nWith = nWith + 1 end end
    if nWith >= 2 then
      y = y + 16
      local hd = f.routeHead
      hd:SetWidth(CW)
      hd.label:SetText(L.SUM_ROUTE_H); hd.count:SetText("")
      hd:ClearAllPoints(); hd:SetPoint("TOPLEFT", c, "TOPLEFT", 0, -y)
      hd:Show()
      y = y + 24 + 8
      f.routeLine:SetText(GainsText(route))
      f.routeLine:ClearAllPoints(); f.routeLine:SetPoint("TOPLEFT", c, "TOPLEFT", 0, -y)
      f.routeLine:Show()
      y = y + LineH(f.routeLine, ns.F.body, CW, c, 3)
      routeShown = true
    end
  end
  if not routeShown then f.routeHead:Hide(); f.routeLine:SetText(""); f.routeLine:Hide() end

  for j = hi + 1, #f.heroes do f.heroes[j]:Hide() end
  for j = fli + 1, #f.factHeads do f.factHeads[j]:Hide() end
  for j = fri + 1, #f.factRows do f.factRows[j]:Hide() end
  for j = fla + 1, #f.factLabels do f.factLabels[j] = nil end
  for j = fvi + 1, #f.factValues do f.factValues[j]:Hide() end
  for j = gi + 1, #f.gpsBtns do f.gpsBtns[j]:Hide() end
  if gi == 0 then f.entryGps, f.entryPoint = nil, nil end
  for j = ni + 1, #f.notes do f.notes[j]:Hide() end
  for j = rli + 1, #f.rdyLines do f.rdyLines[j]:Hide() end
  for j = rsi + 1, #f.rdySubs do f.rdySubs[j]:Hide() end
  for j = ri + 1, #f.rows do f.rows[j]:Hide(); f.rows[j].shownNow = nil end
  for j = hdi + 1, #f.heads do f.heads[j]:Hide() end
  for j = fi + 1, #f.folds do f.folds[j]:Hide() end
  if not allDoneShown then f.allDone:Hide() end
  if multi or nQuests > 0 then f.empty:Hide() end

  -- bottom bar: the route button says what it does; hidden when nothing is left to do
  local mode
  if f.first or not RouteRuns(keys) then mode = "start" elseif f.changed then mode = "update" else mode = "back" end
  f.mode = mode
  f.goBack = mode ~= "start"
  -- opened outside the picker while the route runs on other dungeons: starting here replaces that
  -- route (and its steps marked by hand), so the label says it and a second click confirms
  f.replaces = mode == "start" and not f.fromPicker and RouteElsewhere() or nil
  local label = mode == "update" and L.SUM_UPDATE or mode == "back" and L.SUM_BACK
    or (f.replaces and L.SUM_GO_HERE) or L.SUM_GO
  f.goBtn:SetConfirm(f.replaces and L.SUM_GO_CONFIRM or nil)
  if not f.replaces and f.goBtn.armed then f.goBtn:Disarm() end
  -- an armed button keeps its question until the second click (or 4 s)
  if not f.goBtn.armed then f.goBtn:SetText(label) end
  f.goLabel = label
  -- opened from the picker (it hid itself): the secondary button goes back to it
  f.backPick = f.fromPicker and nTodo > 0 or nil
  f.closeBtn:SetText(f.backPick and L.SUM_BACK_PICK or L.SUM_CLOSE)
  if f.closeBtn.SetIcon then f.closeBtn:SetIcon(f.backPick and "chevron_left" or nil) end
  if f.goBtn.SetIcon then f.goBtn:SetIcon(mode == "update" and "refresh" or mode == "back" and "chevron_left" or nil) end
  SetOn(f.goBtn, mode ~= "start" or #sel > 0)
  f.goBtn:SetShown(nTodo > 0)
  -- nothing to do: "Guide me through the dungeon" (or back to that route when it runs)
  f.runLabel = #keys > 1 and L.SUM_RUN_N or L.SUM_RUN
  f.runBtn:SetShown(runnable)
  if runnable then
    -- back to the route only while it is an unfinished run of these dungeons: a finished one
    -- (or their finished quest route) starts afresh, without asking (nothing would be lost)
    local onThese = RouteRuns(keys)
    local runMode = "start"
    if onThese and not f.first and RunGoing(keys) then runMode = "back" end
    f.runMode = runMode
    f.runReplaces = runMode == "start" and not onThese and not f.fromPicker and RouteElsewhere() or nil
    f.runBtn:SetConfirm(f.runReplaces and L.SUM_GO_CONFIRM or nil)
    if not f.runReplaces and f.runBtn.armed then f.runBtn:Disarm() end
    if not f.runBtn.armed then
      f.runBtn:SetText(runMode ~= "start" and L.SUM_BACK or (f.runReplaces and L.SUM_GO_HERE) or f.runLabel)
    end
    if f.runBtn.SetIcon then f.runBtn:SetIcon(runMode ~= "start" and "chevron_left" or nil) end
  end
  f.closeBtn:ClearAllPoints()
  if nTodo > 0 then f.closeBtn:SetPoint("RIGHT", f.goBtn, "LEFT", -8, 0)
  elseif runnable then f.closeBtn:SetPoint("RIGHT", f.runBtn, "LEFT", -8, 0)
  else f.closeBtn:SetPoint("RIGHT", f.bar, "RIGHT", 0, 0) end
  f.shareAll:SetShown(ctx.grouped and nTodo > 0)
  if f.shareAll:IsShown() then
    if not ns.pushBusy then f.shareAll:SetText(L.SUM_SHARE_ALL) end
    SetOn(f.shareAll, #shareList > 0 and not ns.pushBusy)
  end

  -- in a group: the tabs, "Group · 2 to sort out"; the Group tab draws its table instead of the list
  local g
  if ctx.grouped then
    g = GroupData(members, per, keys)
    local label = g.todo > 0 and L.SUM_TAB_G_N:format(g.todo) or L.SUM_TAB_G
    local tb = f.tabBar.tabs[2]
    if tb.labelText ~= label then
      tb.labelText = label
      tb.label:SetText(label)
      ns.ClampLabel(tb.label, label, tb)
    end
    f.tabBar:Show()
    f.tabBar:Update()
  else
    f.tabBar:Hide()
    f.tab = "quests"
  end
  f.group = g
  if f.tab == "group" and g then
    f.qPane:Hide(); f.gPane:Show()
    y = DrawGroup(f.gPane, g, members, ctx)
    f.gPane:SetHeight(math.max(1, math.ceil(y)))
  else
    f.gPane:Hide(); f.qPane:Show()
    f.qPane:SetHeight(math.max(1, math.ceil(y)))
  end

  -- a workspace window keeps its size (DESIGN 0.4): the list scrolls inside, the bar at the bottom
  local contentH = math.max(1, math.ceil(y))
  local saTop = f:ContentTop() + 12
  local barH = 12 + 32
  local viewH = math.max(60, winH - saTop - barH - 12)
  f.sa:ClearAllPoints()
  f.sa:SetPoint("TOPLEFT", f, "TOPLEFT", PAD, -saTop); f.sa:SetPoint("TOPRIGHT", f, "TOPRIGHT", -PAD, -saTop)
  f.sa:SetHeight(viewH)
  f.child:SetWidth(CW)
  f.sa:SetContentHeight(contentH)
  f.bar:ClearAllPoints()
  f.bar:SetPoint("TOPLEFT", f, "TOPLEFT", PAD, -(saTop + viewH + 12)); f.bar:SetPoint("TOPRIGHT", f, "TOPRIGHT", -PAD, -(saTop + viewH + 12))
  f:FitHeight(viewH + barH)
end
ns.RenderOverview = function() if f and f:IsShown() then Render() end end

local function GuideOff()
  local WP = ns.Writs and ns.Writs.WP
  return WP and WP.ModuleOff and WP.ModuleOff("dungeons")
end

-- The dungeon the guide is on (inside it, or its first picked dungeon), for a call without a key.
local function DefaultKey()
  local here = ns.InstanceKeys and ns.InstanceKeys() or {}
  if here[1] then return here[1] end
  for _, k in ipairs(ns.ORDER or {}) do if WLDTDB.sel and WLDTDB.sel[k] then return k end end
end

-- The picked dungeons, in the picker's order.
local function PickedKeys()
  local out = {}
  for _, k in ipairs(ns.ORDER or {}) do if WLDTDB.sel and WLDTDB.sel[k] then out[#out + 1] = k end end
  return out
end
ns.PickedKeys = PickedKeys

-- Opens the summary of one or several dungeons (the picked ones without `keys`). `one`: opened on
-- a single dungeon (its overview): starting the route replaces the picked dungeons with it.
-- Opened from the picker (or with no route on these dungeons) it is the route's first screen: its
-- main button starts the route.
function ns.ShowSummary(keys, one)
  if GuideOff() then return end
  if ns.EnsureClassCards then ns.EnsureClassCards() end
  keys = keys or PickedKeys()
  local list = {}
  for _, k in ipairs(keys) do if ns.D[k] then list[#list + 1] = k end end
  if #list == 0 then return end
  local picker = _G.WLDTPicker
  local fromPicker = picker and picker.IsShown and picker:IsShown() and true or false
  if not f then Build() end
  local sig = table.concat(list, ",")
  if f.sig ~= sig and f.sa then f.sa:ScrollTo(0, true); wipe(f.open); wipe(f.doneOpen) end
  f.sig, f.keys, f.one = sig, list, one and true or nil
  f.dkey = list[1]
  f.first = fromPicker or not RouteRuns(list)
  f.fromPicker = fromPicker or nil
  f.changed = nil
  f:Show(); f:Raise()
  if ns.SyncAsk then ns.SyncAsk(list) end
  Render()
  -- wrapped text has its real height once the font and width are applied: measure again
  if C_Timer and C_Timer.After then C_Timer.After(0, function() if f:IsShown() then Render() end end) end
  return f
end

-- Opens the overview of a dungeon (dkey from ns.D); without a key, the guide's dungeon. While the
-- route runs on several dungeons, the guide's button shows the whole route's summary.
function ns.ShowOverview(dkey)
  dkey = dkey or DefaultKey()
  if not (dkey and ns.D[dkey]) then return end
  if ns.route and WLDTDB.sel and WLDTDB.sel[dkey] then
    local keys = PickedKeys()
    if #keys > 1 then
      -- the guide's dungeon first
      for i, k in ipairs(keys) do if k == dkey then table.remove(keys, i); table.insert(keys, 1, dkey); break end end
      return ns.ShowSummary(keys)
    end
  end
  return ns.ShowSummary({ dkey }, not (WLDTDB.sel and WLDTDB.sel[dkey] and not next(WLDTDB.sel, next(WLDTDB.sel))))
end
function ns.HideOverview() if f then f:Hide() end end
-- redraws the open summary (its share button follows a share started from the guide)
function ns.RenderSummary() if f and f:IsShown() and Render then Render() end end
