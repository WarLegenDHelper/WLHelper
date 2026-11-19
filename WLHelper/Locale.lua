-- Langue de l'interface : français ou anglais (automatique selon le client, modifiable avec /wlh lang).
--
-- Glossary (docs/DESIGN.md, section 6): one word per concept, in every label, tooltip and chat line.
--   WL Helper / WL Helper            the addon, never translated
--   WaR LegenD / WaR LegenD          the guild, exact capitalisation
--   Accueil / Home                   the hub window and the home button
--   Guide de quêtes / Quest guide    this guide ("le guide" / "the guide" in running text)
--   Donjon / Dungeon                 Quête de donjon / Dungeon quest
--   Choisir un guide / Pick a guide  the picker (dungeons, raids, class quests); its button says what it starts
--   Étape / Step                     Route / Route    Check-list / Checklist
--   GPS / GPS                        "Guider vers ..." / "Guide me to ..."
--   Épingler / Pin                   Réglages / Settings     Writs / Writs
--   Writ / Writ (capital W)          Faveur du marchand / Merchant's Favor
--   Événement / Event                Groupe / Group          HV / AH
--   Actions / Actions                the guide's footer menu    Cibler et objets / Target and items   the bar above the guide
--   Voir la vue d'ensemble (N donjons) / See the overview (N dungeons)   the picker's main button (it opens the overview)
--   Suivi du guide / Guide tracker   the small window with the current action ("le suivi" / "the tracker")
--   Vue d'ensemble / Overview        one dungeon's page (or the route's): entrance, quests, rewards
--   Boss et rares / Bosses and rares the panel of a dungeon's bosses and rare mobs
--   Actif / On                       a step row's GPS button while the GPS leads there (never "Suivi")
-- Status words: À prendre / To take, Dans ton journal / In your log, Prête à rendre / Ready to turn in,
-- Rendue / Turned in, Faite / Done.
-- Levels: "niv. N" / "level N" everywhere; "lvl N" (PICK_QLV) only in the picker's 40 px level column.
-- French: space before ":", "?", "!" ; plurals branch on n == 1 (two keys), never "(s)";
-- French 0 takes the singular too ("0 quête"), see ns.Plural.
local _, ns = ...

local S = {
  fr = {
    COLON = " : ", WRITS = "Writs et Faveur", TT_HWRITS = "Writs et Faveur du marchand : les Writs les moins chers, la liste d'achat et le GPS jusqu'aux PNJ.", MM_TT4 = "Maj-clic : ouvrir les Writs",
    TITLE = "WL Helper",
    -- picker
    SEC_TODO = "À faire à ton niveau", SEC_LATER = "Plus tard", SEC_BELOW = "Sous ton niveau", SEC_UP = "Bientôt", BACK_HOME = "Accueil", SEC_DONE = "Terminés", SEC_NOQ = "Sans quête pour ta faction",
    PICK_FINISHED = "Terminé", PICK_QN = "%d quêtes rendues sur %d", PICK_QN1 = "%d quête rendue sur %d", PICK_LV = "Conseillé niv. %d à %d", PICK_LV1 = "Conseillé niv. %d", PICK_PICKED = "Choisi", PICK_FIT = "Conseillé pour toi", PICK_FIT_WHY = "De ton côté, à ton niveau, à %s", PICK_FIT_WHY0 = "De ton côté, à ton niveau, tout près", PICK_SIZE = "%d joueurs", PICK_OPENS = "ouvre le %s", PICK_DATE = "%d/%m/%Y", PICK_SOON = "Bientôt",
    -- guide header and buttons
    DUNGEONS = "Guide de quêtes", GPS_ON = "Actif", HOME = "Accueil", SETTINGS = "Réglages du guide", GO = "Guider vers l'étape", BACK_CUR = "Revenir à l'étape en cours",
    NOPOINT_S = "Pas de point sur la carte", NEXT2 = "Étape suivante", MORE = "Actions", MORE_BTN = "Actions", PICK_FIRST = "Choisir un guide",
    NOROUTE_T2 = "Aucun donjon choisi",
    TT_HOME = "Clic : revenir à l'accueil", TT_SETTINGS = "Clic : ouvrir les réglages du guide",
    TT_PICKBTN = "Clic : choisir les donjons, raids ou quêtes de classe de la route", TT_MORE = "Clic : marquer l'étape, recalculer la route, flèche GPS, boss du donjon",
    -- the Actions menu
    M_SHARE = "Partager les quêtes avec le groupe", M_RECALC = "Recalculer la route d'ici", M_POINTS = "Poser les points sur la carte",
    M_SKIP = "Marquer l'étape comme faite", M_UNSKIP = "Remettre l'étape à faire", M_ARROW = "Flèche GPS", M_BOSSES = "Boss du donjon", M_AUTO = "Points posés à chaque étape",
    M_LIST = "Liste des étapes", ON = "oui", OFF = "non",
    M_JOURNAL = "Journal du donjon (boss, butin)", TT_JOURNAL = "Ouvre les boss et le butin du donjon de l'étape dans le journal de donjon installé.",
    NOJOURNAL_TIP = "Aucun journal de donjon installé.",
    NOGROUP_TIP = "Indisponible hors groupe.",
    JOURNAL_NONE = "Aucun journal de donjon n'est installé : cette action en a besoin pour montrer les boss et le butin.",
    RARE_SEEN = "Monstre rare en vue : %s",
    LOADED = "chargé : tape /wlh ou clique sur le bouton de la minimap pour ouvrir l'accueil.",
    OLD_FOLDER = "L'ancien dossier DungeonGuide est encore là et il est désactivé. Supprime-le dans Interface\\AddOns, puis tape /reload.",
    PICK = "Choisir un guide", LIST = "Étapes", PREV = "Étape précédente", NEXT = "Étape suivante", CURRENT = "Étape en cours",
    POINTS = "Points", NEXTPOINT = "Point suivant", SHARE = "Partager", DONE = "Passer", UNDO = "Annuler",
    AUTO_ON = "Points auto : oui", AUTO_OFF = "Points auto : non", ARROW = "Flèche",
    STEP = "Étape %d / %d", STEPS = "Étapes", NOROUTE = "Aucune route",
    NOROUTE_TXT = "La route part de là où tu es et passe par les quêtes de prérequis.",
    -- kind of a line, and a quest's state (design system 5.5)
    TAKE = "Prendre", DO = "Faire", TURNIN = "Rendre", HAVE = "Requise", HAVE_OPT = "Facultative", OUTSIDE = "Dehors", ITEM = "Objet",
    S_NONE = "À prendre", S_ON = "Dans ton journal", S_READY = "Prête à rendre", S_DONE = "Rendue",
    B_DONE = "Faite", B_CUR = "En cours", B_LATE = "À finir", B_NEXT = "À venir",
    IN_DUNGEON = "Dans le donjon : %s", OUTER = "Zone de %s, avant le portail", GATE = "Avant d'entrer : %s",
    CLASSQ = "Quête de classe : %s", CLASS_TAG = "Classe : %s",
    B_READY = "Check-list", TT_READY = "Ce qu'il te faut avant d'entrer : les quêtes qui se font dans le donjon mais se prennent dehors, et la clé s'il en faut une.",
    TT_READY_CLICK = "Clic : ouvrir la check-list",
    SHARE_SHORT = "Partager les quêtes", NO_READY = "Cette route n'a pas de check-list : aucune quête n'est à prendre avant d'entrer.",
    GO_MISSING = "Guider vers la quête manquante", GO_ENTRANCE = "Guider vers l'entrée",
    FIN_T = "Route terminée", FIN_PROG = "%d étapes faites", FIN_PROG1 = "%d étape faite", FIN_TXT = "Toutes les quêtes de %s sont rendues. Les étapes faites restent dans la liste si tu veux les revoir.",
    FIN_MSG = "Route terminée : %s. Bravo !", PICK_MORE = "Choisir d'autres donjons",
    TT_NEXT = "Montre l'étape suivante sans valider celle-ci. Le guide avance tout seul quand l'étape est faite.", TT_NEXT_CLICK = "Clic : voir l'étape suivante",
    TT_PREV_CLICK = "Clic : voir l'étape précédente",
    INST_ADD = "Ajouter %s au guide (%d quêtes)", INST_ADD1 = "Ajouter %s au guide (%d quête)", INST_T = "Tu es dans %s",
    INST_TXT = "%d quêtes se font ici. Le guide les range boss par boss.", INST_TXT1 = "%d quête se fait ici. Le guide la place au bon boss.",
    INST_GO = "Lancer le guide ici",
    INST_CHAT = "Tu es dans %s et %d quêtes de ta route se font ici : le guide est ouvert pour les suivre.",
    INST_PICK = "Plusieurs donjons partagent cette instance. Tape /wlh pick pour choisir le tien.",
    STEPS_N = "Étapes faites : %d sur %d", STEP_LEFT = "Étape %d sur %d", PCT = "%d %%",
    TT_LISTROW = "Clic : voir cette étape",
    -- key bindings
    B_TOGGLE = "Afficher ou cacher le guide", B_PICK = "Choisir un guide", B_NEXTSTEP = "Étape suivante", B_PREV = "Étape précédente", B_POINTS = "Poser les points du GPS", B_ARROW = "Afficher ou cacher la flèche",
    PARTY_HAS = "Dans le groupe, l'ont : %s", PARTY_MISS = "Dans le groupe, ne l'ont pas : %s",
    KEY_REQ = "Clé requise", KEY_DOORS = "Clé (portes)", KEY_SHORT = "Clé (raccourci)", KEY_HAVE = "dans le sac", KEY_MISSING = "manquante",
    KEY_QUEST = "S'obtient avec la quête « %s »", KEY_BOSS = "Butin de %s (%s)", BOSS = "Boss", RAID = "Raid",
    KEY_WARN = "Tu n'as pas la clé : quelqu'un du groupe doit l'avoir pour ouvrir.",
    GATE_T = "Avant d'entrer dans %s", GATE_N = "Tes quêtes de donjon se partagent une fois en groupe.",
    INSIDE_T = "%s", INSIDE_OUTER_T = "%s : partie extérieure",
    BLOCKED = "Bloquée : %s", LVL_REQ = "niveau %d requis", NEED = "rends d'abord %s",
    GIVER = "Se prend auprès de %s", OPT = "facultative",
    TT_TAKE = "Prendre la quête", TT_DO = "Finir les objectifs", TT_TURN = "Rendre la quête", TT_HAVE = "À avoir dans ton journal avant d'entrer",
    TT_OUT = "Objectif à faire dehors, hors de l'instance", TT_ITEM = "Objet",
    TT_REWARD = "Récompense : %s", TT_XP = "%s XP", TT_CLICK = "Clic : guider vers ce point", TT_NOPOINT = "Pas de point : c'est dans le donjon.", TT_NOPOINT_UNK = "Pas de point : lieu exact inconnu, suis ton journal de quêtes.",
    TT_INSIDE = "Dans le donjon", TT_OUTSIDE = "Hors du donjon", TT_DROPS = "Tombe sur : %s",
    TT_TARGET = "Cibler", TT_TARGET2 = "Cible %s s'il est en vue.",
    TT_RAID = "En raid, il faut être chef ou assistant pour marquer.", TT_USE = "Clic : utiliser l'objet", TT_TARGET_CLICK = "Clic : cibler",
    TT_GPS = "Guider vers %s (%.1f, %.1f)", TT_GPS_CLICK = "Clic : lancer le GPS vers ce point", TT_CONFLICT = "Position vérifiée : les sources ne s'accordaient pas, celle de la majorité est retenue.",
    TRAVEL_CONT = "Il faut changer de continent : zeppelin ou bateau.", TRAVEL_FAR = "Long trajet : prends un vol si tu peux.",
    TRAVEL_UNK = "Lieu exact inconnu : suis ton journal de quêtes.",
    NEXT_STEP = "Étape suivante : %s", SHARING = "Partage de %d quêtes avec le groupe...", SHARING1 = "Partage d'une quête avec le groupe...", SHARED = "Quête partagée : %s", NOTSHARE = "Cette quête ne se partage pas : %s",
    NOGROUP = "Tu n'es pas en groupe : invite quelqu'un, puis partage les quêtes.", NOSHARE = "Ton journal n'a aucune quête de donjon à partager.",
    INCOMBAT = "Indisponible en combat : réessaie après le combat.", NOPOINT = "Cette étape n'a pas de point sur la carte : suis ton journal de quêtes.",
    POINT_N = "Point %d sur %d : %s (%.1f, %.1f).%s", POINT_MORE = " Clique encore sur « Point suivant » pour aller au prochain.",
    MACRO_MADE = "Macro « %s » créée. Ouvre /macro, onglet de ton personnage, et glisse-la sur ta barre : elle cible le monstre ou le PNJ de l'étape et lui met une tête de mort.",
    MACRO_FULL = "Pas de place pour la macro DG_Cible : tes macros de personnage et de compte sont pleines. Libère une place, puis tape /reload.",
    MACRO_NONE = "Rien à cibler à cette étape.", MACRO_ON = "Macro de ciblage activée.", MACRO_OFF = "Macro de ciblage désactivée : elle n'est plus mise à jour.",
    USEFUL_ON = "Quêtes utiles seulement : sans les répétables ni les quêtes de métier que tu n'as pas.", USEFUL_OFF = "Toutes les quêtes sont affichées, répétables et métiers compris.",
    TT_HPICK = "Choisir un guide", TT_HLIST = "Montre ou cache la liste de toutes les étapes de la route.",
    LIST_CLOSE = "Fermer les étapes", TT_LIST_CLOSE = "Fermer la liste des étapes", TT_LIST_CLOSE_CLICK = "Clic : fermer la liste (le bouton « Étapes » du guide la rouvre)",
    TT_HLANG = "Langue de l'addon (français ou anglais).", COMPACT_BTN = "Moderne", TT_HMIN = "Passer à la vue moderne (sans cadre, comme Polestar)", TT_HMAX = "Agrandir le guide", TT_HMIN_CLICK = "Clic : le guide devient un petit cadre (l'action en cours, ses objectifs, la suite). Clic sur le cadre : le guide complet revient.", TT_HMAX_CLICK = "Clic : afficher le guide en entier",
    TT_HCLOSE = "Fermer", TT_HCLOSE2 = "Pour rouvrir le guide : /wlh dungeons ou le bouton de la minimap.", TT_HCLOSE_CLICK = "Clic : fermer le guide",
    AB_LABEL = "Cibler et objets", BOSS_N = "Boss %d", ALLDUNGEON_T = "Partout", ALLDUNGEON = "Dans tout le donjon",
    BOSS_STEP_N = "Boss %d sur %d · %s", IN_WAY = "En route vers %s", BOSS_OPT = "Facultatif", BOSS_RARE_TAG = "Rare",
    BOSS_OPT_TT = "Ni quête ni butin pour toi ici : tu peux le passer. Tuer le boss suivant le compte comme passé.",
    H_PATH = "Chemin", H_TACTIC = "Tactique", H_LOOT = "Butin pour toi", LOOT_QUEST = "objet de quête",
    BIS_1 = "BiS", BIS_2 = "2e choix", BIS_TT = "%s pour ta spé (Naowh)", BIS_2S = "2e", BIS_LVS = "BiS %d",
    ROLE_TANK = "Tank", ROLE_HEAL = "Soigneur", ROLE_ALL = "Tous", TR_BOSS_N = "Boss %d sur %d",
    BOSS_STEP = "Boss : %s", IN_START = "Sur le chemin : PNJ et objets du donjon", IN_TRASH = "À finir dans le donjon : butin des monstres", IN_TRASH_ANY = "À finir dans le donjon", NAOWH_TIP = "", H_TIP = "Conseil", H_ALSO = "En chemin, fais aussi", ALSO_TRASH = "En chemin, ramasse aussi : %s",
    ALSO_ALL = "Tout le donjon : %s", ALSO_MOBS = "(tombent sur les monstres)", ALSO_MOB = "(tombe sur les monstres)", DUNGEON_MAP = "Carte du donjon",
    TT_FPOINTS = "Pose les points de l'étape sur la carte. S'il y en a plusieurs, un deuxième clic passe au suivant.",
    TT_FSHARE = "Partage avec le groupe les quêtes de donjon de ton journal qui se partagent.",
    TT_FDONE = "Valide l'étape à la main et passe à la suivante, quand le guide ne peut pas le voir seul (quête faite avant, objet reçu d'un ami...). Un deuxième clic annule.",
    TT_FAUTO = "Le GPS se pose tout seul sur chaque nouvelle étape.",
    TT_FARROW = "Montre ou cache la flèche du GPS vers le prochain point.",
    TT_RESIZE = "Largeur du guide", TT_RESIZE2 = "Glisser : changer la largeur", TT_RESIZE3 = "Double-clic : largeur d'origine",
    TAB_DG = "Donjons", TAB_RAID = "Raids", TAB_CLS = "Quêtes de classe", CQ_IN = "Se fait dans : %s",
    TAB_QG = "Quêtes", PICK_HINT_QG = "Des chaînes de quêtes hors donjon qui rapportent un objet utile : sacs, Attracteur élémentaire. Elles se combinent avec des donjons dans une seule route.",
    PICK_EMPTY_QG_T = "Aucun guide de quête à ton niveau", PICK_EMPTY_QG = "Ceux des autres niveaux apparaissent avec le filtre « Tous ».",
    PICK_HINT_CLS = "Tes quêtes de classe liées à un donjon. Elles se combinent avec des donjons dans une seule route.",
    PICK_HINT_RAID = "Les harmonisations des raids : les quêtes à finir avant d'y entrer.",
    PICK_EMPTY_CLS_T = "Aucune quête de classe à ton niveau", PICK_EMPTY_CLS = "Celles des autres niveaux apparaissent avec le filtre « Tous ».",
    PICK_EMPTY_T = "Aucun donjon ici", PICK_EMPTY = "Ceux hors de ton niveau apparaissent avec le filtre « Tous ».",
    PICK_SEARCH = "Donjon, quête, PNJ", PICK_HINT_SEARCH = "Résultats pour « %s » dans tous les onglets et à tous les niveaux.",
    PICK_EMPTY_SEARCH_T = "Rien pour « %s »", PICK_EMPTY_SEARCH = "Cherche un nom de donjon (ou ZF, BRD, SM), une quête ou la personne qui la donne.",
    PICK_T = "Choisir un guide", PICK_HINT = "Clique sur l'image d'un donjon pour le choisir (plusieurs donjons = une seule route), puis clique sur le bouton en bas. « Vue d'ensemble » montre les quêtes d'un donjon.", PICK_RUNNING = "Guide en cours", PICK_CHK = "Combiner", PICK_CHK_TT = "Clique « + Ajouter » pour enchaîner ce donjon avec d'autres en une seule route.", PICK_ADD = "+ Ajouter", PICK_ADDED = "Ajouté", PICK_GO_N = "Combiner les %d guides",
    PICK_GO = "Voir la vue d'ensemble", PICK_GO_WHY = "Coche la case d'au moins un donjon, ou clique sur une carte.", PICK_NONE = "Tout décocher", PICK_MINE = "Mon niveau", PICK_ALL = "Tous",
    PICK_QUESTS = "%d quêtes", PICK_QUESTS1 = "%d quête", PICK_DONE = "%d rendues", PICK_DONE1 = "%d rendue", PICK_NOQ = "Aucune quête",
    GEAR_BIS1 = "%d BiS pour toi", GEAR_BIS = "%d BiS pour toi", GEAR_BIS1_S = "%d BiS", GEAR_BIS_S = "%d BiS",
    GEAR_UP1 = "%d amélioration", GEAR_UP = "%d améliorations",
    GEAR_HEAD = "Donjons à farmer pour ton équipement (BiS de Naowh, puis les améliorations de WL Helper) :",
    GEAR_NONE = "Aucun donjon à ton niveau n'a d'objet BiS ou d'amélioration pour toi (ou la liste BiS de Naowh n'est pas installée).", PICK_CUSTOM = "Quêtes", PICK_STAT = "Quêtes rendues", PICK_QLV = "niv. %d",
    PICK_SEL = "%d donjons choisis", PICK_SEL1 = "1 donjon choisi", PICK_SEL0 = "Aucun donjon choisi",
    PICK_CUSTOM_T = "Quêtes de %s", PICK_CUSTOM_H = "Décoche les quêtes que tu ne veux pas faire : la route les laisse de côté.", PICK_RCLICK = "Clic droit : choisir les quêtes", PICK_CLICK = "Clic : choisir ce donjon (ou le retirer)", PICK_DCLICK = "Double-clic : voir la vue d'ensemble de ce donjon seul",
    PICK_QCLICK = "Clic : garder ou retirer cette quête", PICK_QOFF = "Retirée de la route",
    ROUTE_BUILT = "Route calculée : %d étapes pour %s.", RECALC = "Recalculer", RECALC_TT = "Recalcule la route depuis l'endroit où tu es.",
    ARROW_FAR = "Autre continent", ARROW_IN = "Dans le donjon", YARDS = "%d m",
    LANG = "Langue : français.", BONUS = "Bonus", UNKNOWN_LOC = "lieu à confirmer",
    PRE = "Prérequis", MAIN = "Quête de donjon", DETAILS = "Détails", HIDE = "Masquer",
    MM_TT1 = "Clic : ouvrir ou fermer le guide", MM_TT2 = "Clic droit : choisir un guide", MM_TT3 = "Glisser : déplacer le bouton",
    HELP = "/wlh : ouvrir l'accueil\n/wlh donjons : ouvrir le guide de quêtes\n/wlh choisir : choisir un guide\n/wlh writs : ouvrir les Writs (Writs et Faveur)\n/wlh sacs : nettoyer les sacs\n/wlh commandes : ouvrir les commandes d'artisanat\n/wlh guilde : voir la guilde et le classement PvP\n/wlh groupes : les événements de la guilde et qui cherche un groupe\n/wlh gps : arrêter ou relancer le GPS\n/wlh aller [lieu] : la flèche t'emmène à un lieu, un service ou un PNJ\n/wlway Tanaris 52,4 31,2 : la flèche de WL Helper va à ce point (aussi /way si aucun autre addon ne l'a)\n/wlh ville : ce qu'il y a à faire dans cette capitale\n/wlh cles : le passeport des clés\n/wlh commun : les quêtes de donjon en commun avec la guilde\n/wlh tri : les quêtes à abandonner quand le journal est plein\n/wlh reglages : ouvrir les réglages\n/wlh setup : revoir l'écran de bienvenue\n/wlh bienvenue : la page Bienvenue, chaque réglage pas à pas\n/wlh visite : la visite guidée\n/wlh idee : envoyer une idée ou un bug\n/wlh suivi : afficher ou cacher le suivi du guide\n/wlh boss : afficher ou cacher les boss du donjon\n/wlh aide : ouvrir « Comment faire... ? » (/wlh aide chat : cette liste dans le chat)",
    UNKNOWN_CMD = "Commande inconnue « %s ». Tape /wlh help pour voir la liste.",
    RESET = "Étapes validées à la main et route remises à zéro.", SKIP = "Passer",
    B_READY_T = "Check-list avant d'entrer",
    TT_READY_OK = "%s : prêt, rien ne manque.",
    TT_READY_KEY = "%s : quêtes prises, mais pas la clé.",
    TT_READY_MISS = "%s : %d quêtes à prendre avant d'entrer.",
    TT_READY_MISS1 = "%s : %d quête à prendre avant d'entrer.",
    CL_OK_H = "Prêt pour %s",
    CL_OK_T = "Les quêtes requises que tu peux déjà prendre sont dans ton journal.",
    CL_OK_NEXT = "Prochaine étape : l'entrée du donjon.",
    CL_KEY_H = "Quêtes prises, mais pas la clé",
    CL_KEY_T = "Tu as toutes les quêtes de %s, mais pas la clé qui ouvre l'entrée.",
    CL_KEY_NEXT = "Quelqu'un du groupe doit l'avoir. Sinon, la partie Clé plus bas dit où la trouver.",
    CL_MISS_H1 = "Pas encore prêt : 1 quête à prendre",
    CL_MISS_HN = "Pas encore prêt : %d quêtes à prendre",
    CL_MISS_T = "Ces quêtes se prennent hors du donjon (%s) : sans elles, tes objectifs à l'intérieur ne comptent pas.",
    CL_MISS_T1 = "Cette quête se prend hors du donjon (%s) : sans elle, tes objectifs à l'intérieur ne comptent pas.",
    CL_MISS_NEXT = "Clique sur une quête « À prendre » : le GPS te guide jusqu'au PNJ qui la donne.",
    CL_WHAT_H = "Ce que vérifie la check-list",
    CL_WHAT = "Avant d'entrer dans %s : les quêtes qui se font dedans (elles se prennent dehors), puis la clé s'il en faut une.",
    RUN_GATE_N = "Aucune quête ici. Va à l'entrée et entre : le guide te mène ensuite de boss en boss.",
    CL_KEY = "Clé",
    CL_ENTRY = "Entrée",
    CL_GROUP = "Groupe",
    CL_HAVE = "Dans ton journal",
    CL_TAKE = "À prendre",
    BACK_FIN = "Revenir à la fin de la route",
    LIST_MORE = "Molette : %d au-dessus, %d en dessous",
    INB_T = "Dans le donjon : %s",
    INB_STEP = "Étape %d / %d dans le donjon",
    INB_Q = "Quêtes finies ici : %d / %d",
    INB_BOSS = "Boss suivant : %s",
    INB_DONE = "Tout est fait ici : en sortant, le guide reprend la route.",
    INB_BACK = "Clic : revenir à l'étape du donjon",
    INB_TT = "Le guide montre les étapes de ce donjon boss par boss, avec l'avancée de chaque objectif. En sortant, il reprend la route dehors.",
    INST_IN = "Tu es dans %s : le guide montre les étapes du donjon.",
    INST_LEFT = "Tu es sorti de %s : le guide reprend la route.",
    -- tracker (Tracker.lua): phase chapters, one action per line, its tooltips
    PH_BEFORE = "Avant le donjon : %s · %d sur %d", PH_INSIDE = "Dans le donjon : %s · %d sur %d", PH_AFTER = "Après le donjon : %s · %d sur %d",
    PH_BEFORE_S = "Avant le donjon", PH_INSIDE_S = "Dans le donjon", PH_AFTER_S = "Après le donjon",
    TR_WHAT = "Suivi du guide : l'action à faire maintenant", TR_TITLE = "Suivi du guide", TR_CLOSE = "Fermer", TR_CLOSE_TIP = "Clic : fermer le guide (le bouton de la minicarte ou /wlh le rouvre)", TR_DONE_T = "Guide terminé !", TR_DONE_SUB = "Bravo ! Choisis la suite :", TR_NONE_T = "Aucun guide en cours", TR_NONE_SUB = "Choisis un guide pour commencer :",
    TR_STEP = "Étape %d", TR_THEN = "Ensuite", TR_NOTE = "À savoir",
    TR_FROM_ITEM = "· objet « %s » dans tes sacs", TR_PREV = "Étape précédente", TR_NEXT = "Étape suivante",
    TR_BACK = "· revenir à l'étape en cours", TR_PAST = "ÉTAPE PASSÉE", TR_AHEAD = "ÉTAPE À VENIR", TR_ALREADY = "Déjà fait :", TR_MENU = "Menu", TR_MENU_TIP = "Clic : actions et réglages (aussi clic droit sur le titre)",
    TR_M_WINDOW = "Ouvrir la fenêtre du guide", TR_M_GO = "Guider vers l'étape", TR_M_DONE = "Marquer l'étape comme faite",
    TR_M_SHARE = "Partager les quêtes avec le groupe", TR_M_BOSSES = "Boss du donjon", TR_M_MAP = "Carte du donjon",
    TR_M_FRAMED = "Avec cadre", TR_M_FRAMELESS = "Sans cadre", TR_M_OPTIONS = "Réglages du guide",
    TR_M_STOP = "Arrêter ce guide", TR_M_HIDE = "Masquer la vue moderne", TR_G_STEP = "ÉTAPE", TR_G_DUNGEON = "CE DONJON", TR_G_GUIDES = "GUIDES", TR_G_VIEW = "AFFICHAGE",
    TR_TAKE = "Prendre « %s »", TR_TURN = "Rendre « %s »", TR_DO = "Faire « %s »", TR_HAVE = "Avoir « %s » dans ton journal",
    TR_KILL = "Tuer : %s", TR_LOOT = "Récupérer : %s", TR_USE = "Utiliser : %s", TR_TALK = "Parler à %s", TR_GO = "Aller à : %s", TR_OBJ = "Objectif : %s",
    TR_ITEM = "Obtenir : %s", TR_ENTER = "Entrer dans %s", TR_BOSS = "Boss : %s",
    TR_MISSING1 = "%d quête à prendre avant d'entrer", TR_MISSING = "%d quêtes à prendre avant d'entrer",
    TR_TIP_CLICK = "Clic : étape suivante · Clic droit : étape précédente", TR_STEPS_SHOW = "▸ Toutes les étapes", TR_STEPS_HIDE = "▾ Masquer les étapes",
    TR_M_PICK = "Choisir un guide", TR_M_OVERVIEW = "Vue d'ensemble du donjon",
    TR_L_PICK = "Guides", TR_L_OVERVIEW = "Vue d'ensemble", TR_L_BOSSES = "Boss", TR_L_MAP = "Carte", TR_L_SHARE = "Partager", TR_TIP_SHIFT = "Maj-clic : marquer l'étape comme faite",
    TR_TIP_DRAG = "Glisser le titre : déplacer le suivi",
    TR_COLLAPSE = "Replier le suivi", TR_EXPAND = "Déplier le suivi",
    TR_COMPACT = "Vue moderne : la roue dentée (ou un clic droit sur le titre) ouvre le menu ; glisse le titre pour la déplacer.",
    TR_ON = "Suivi du guide affiché. Tape /wlh tracker pour le cacher.", TR_OFF = "Suivi du guide caché. Tape /wlh tracker pour le remettre.",
    TR_NOROUTE = "Aucune route en cours. Tape /wlh pick pour choisir un guide.",
    TR_MARKED = "Étape marquée comme faite : %s",
    TR_GUIDE_OFF = "Le guide de quêtes est éteint : le suivi revient quand tu le rallumes dans Réglages > Général > Modules.",
    -- key binding: target and mark
    B_TARGET = "Cibler le PNJ ou le monstre de l'étape",
    TARGET_LATER = "Le raccourci de ciblage sera prêt à la fin du combat.",
    B_ITEM = "Utiliser l'objet de quête de l'étape", B_GROUPS = "Ouvrir Trouver un groupe",
    ITEM_LATER = "Le raccourci de l'objet sera prêt à la fin du combat.",
    ITEM_NONE = "Pas d'objet de quête à utiliser à cette étape.",
    M_KEYS = "Raccourcis clavier",
    TT_KEYS = "Clic : ouvrir les raccourcis du jeu. Les touches du guide (cibler, utiliser l'objet, étape suivante...) sont dans la section Addons > WL Helper.",
    KEY_IS = "Raccourci : %s", KEY_NONE = "Pas de raccourci : clic droit pour en mettre un",
    KEYS_HINT = "Raccourcis : Échap > Options > Raccourcis > Addons > WL Helper",
    KEYS_OPENED = "Les touches du guide sont dans la section Addons > WL Helper, en bas de la liste.",
    KEYS_COMBAT = "Les raccourcis ne s'ouvrent pas en combat : réessaie après.",
    SHARE_N1 = "Partager %d quête", SHARE_N = "Partager %d quêtes",
    -- prerequisite chains and the ranked status words (picker, list and card)
    CH_STEP = "Prérequis %d/%d", CH_BEFORE = "Étape %d sur %d avant « %s »", CH_PART = "Partie %d sur %d de la suite « %s »",
    CH_NONE = "Sans prérequis", CH_COUNT1 = "%d prérequis", CH_COUNT = "%d prérequis", CH_ALLDONE = "Prérequis faits",
    ST_PRE = "Prérequis %d/%d", ST_PRELOG = "Prérequis %d/%d en cours", ST_LOW = "Niveau %d requis",
    ST_PICKUP = "À prendre", ST_ACTIVE = "En cours", ST_READY = "Prête à rendre", ST_DONE = "Rendue",
    -- guide window: chapter headers in the step list, overview, bosses and tracker entries
    TT_CHAPTER_CLICK = "Clic : aller à la première étape à faire de cette partie", CH_PROGRESS = "Étapes faites : %d sur %d",
    OV_HDR_T = "Vue d'ensemble : %s",
    BOSS_MENU_CLICK = "Clic : afficher les boss et les rares du donjon", BOSS_MENU_NONE = "Aucun donjon dans la route pour l'instant.",
    TR_MENU_TT = "Une petite fenêtre avec l'action en cours et les deux suivantes, même guide fermé.",
    TR_MENU_CLICK = "Clic : afficher ou cacher le suivi",
    -- dungeon overview (Overview.lua)
    OV_T = "Vue d'ensemble", OV_BTN = "Résumé", OV_CLICK = "Clic : ouvrir la vue d'ensemble du donjon", OV_RCLICK = "Clic droit : vue d'ensemble du donjon",
    OV_ENTRANCE = "Entrée : %s", OV_GROUP = "Groupe de %d joueurs", OV_SUM_Q1 = "%d quête", OV_SUM_Q = "%d quêtes", OV_SUM_LOG1 = "%d dans ton journal",
    OV_SUM_LOG = "%d dans ton journal", OV_SUM_PRE1 = "%d prérequis manquant", OV_SUM_PRE = "%d prérequis manquants",
    OV_SUM_PRE0 = "aucun prérequis manquant", OV_SUM_OFF1 = "%d retirée de la route", OV_SUM_OFF = "%d retirées de la route",
    OV_PRE1 = "Prérequis : %s", OV_PRE = "Prérequis : %s", OV_PRE_DONE1 = "fait", OV_PRE_DONE = "faits", OV_PRE_TODO1 = "pas fait",
    OV_PRE_TODO = "pas faits", OV_PRE_PART = "%d sur %d faits", OV_MORE = "+%d", OV_CHAIN = "Chaîne : étape %d sur %d",
    OV_CHAIN_TT = "Chaîne de quêtes", OV_THIS = "cette quête", OV_GIVER = "Donneur : %s", OV_FINISHER = "À rendre à : %s",
    OV_IN_DG = "dans le donjon", OV_ITEM_START = "Commence avec l'objet %s", OV_CHOICE = "Récompense au choix", OV_UPGRADE = "Amélioration pour toi", OV_UPGRADE_AT = "Au niveau %d (celui de la quête) : %s",
    OV_ON_T = "Dans la route", OV_ON_CLICK = "Clic : retirer cette quête de la route", OV_OFF_CLICK = "Clic : remettre cette quête dans la route",
    OV_ST_OFF = "Retirée", OV_GPS_T = "Guider vers %s", OV_GPS_CLICK = "Clic : lancer le GPS", OV_ROW_CLICK = "Clic : guider vers %s",
    OV_ENTRY_T = "l'entrée du donjon", OV_EMPTY_T = "Aucune quête pour toi ici", OV_EMPTY = "Les quêtes de ce donjon sont pour une autre classe, faction ou race.",
    OV_EMPTY_UP = "Les quêtes arriveront à l'ouverture de ce donjon.", OV_GO = "Guider dans ce donjon", OV_GO_WHY = "Aucune quête à faire ici pour ce personnage.",
    OV_GO_TT = "Clic : lancer la route sur ce donjon seul (remplace tes donjons cochés)", OV_PICK = "Cocher ce donjon",
    OV_UNPICK = "Décocher ce donjon", OV_PICK_TT = "Clic : cocher ce donjon dans le choix du guide", OV_UNPICK_TT = "Clic : décocher ce donjon dans le choix du guide",
    OV_KEY_NONE = "Pas de clé nécessaire", OV_CARD_PRE1 = "%d en attente d'un prérequis", OV_CARD_PRE = "%d en attente d'un prérequis",
    OV_SEC_DONE = "Rendues", OV_EMPTY_NONE = "Ce donjon n'a pas de quête.", OV_GO_DONE = "Toutes les quêtes sont rendues.",
    TT_SHIFT_LINK = "Maj-clic : lier dans le chat",
    -- bosses and rares panel (Bosses.lua)
    BOSS_NOTFOUND = "Pas ciblé : %s. Il doit être en vue ; s'il l'est, dis-le-nous (le clic n'arrive peut-être pas).", BOSS_TITLE = "Boss et rares", BOSS_SEC = "Boss", BOSS_RARES = "Rares", BOSS_LVL = "niv. %d", BOSS_LVL2 = "niv. %d à %d",
    BOSS_TARGET = "Cibler",
    BOSS_TT_TARGET = "Cible %s s'il est en vue.", BOSS_TT_CLICK = "Clic : cibler",
    BOSS_WAIT = "Mis à jour après le combat",
    BOSS_KILLED = "Tué pendant cette visite", BOSS_R_BOSS = "Boss",
    BOSS_R_ELITE = "Élite", BOSS_R_RAREELITE = "Rare élite", BOSS_R_RARE = "Rare",
    BOSS_EMPTY_NOLIB = "La liste des boss n'est pas disponible sur ce client.", BOSS_EMPTY_NONE = "Aucun boss ni rare n'est connu dans ce donjon.",
    BOSS_LOADING = "La liste arrive dans un instant.", BOSS_ATTACH = "Coller au guide",
    BOSS_ATTACH_TT = "Le panneau se place à côté du guide et le suit quand il bouge.", BOSS_ATTACH_CLICK = "Clic : remettre les boss à côté du guide", BOSS_DRAG = "Glisser : détacher et déplacer",
    BOSS_FOR = "Pour « %s »", BOSS_FOR_ITEM = "%s pour « %s »",
    BOSS_MENU_HIDE = "Clic : masquer les boss et les rares",
    BOSS_UNSEEN = "Pas encore vu", BOSS_SEEN = "Déjà croisé", BOSS_TT_CLICKM = "Clic : cibler", BOSS_TT_RCLICK = "Clic droit : marquer tué / pas tué",
    BOSS_DRAG2 = "Glisser : déplacer", BOSS_CLOSE_CLICK = "Clic : masquer les boss (le bouton du guide les rouvre)",
    BOSS_KILLED_AT = "Tué à +%s du début",
    RUN_TIME = "Temps", RUN_XP = "XP", RUN_GOLD = "Or",
    RUN_STATS_TIP = "Le temps court de l'entrée jusqu'au dernier boss. L'XP compte les monstres et les quêtes rendues dans le donjon.",
    RUN_NONE = "Le temps, l'XP et l'or de ton run s'affichent ici dès l'entrée du donjon.",
    RUN_TIP_LINE = "Ce run : %s", RUN_XP_PCT = "%s XP (%d\194\160%% d'un niveau)", RUN_XP_LVN = "%s XP (environ %s niveaux)",
    RUN_KILLS = "%d boss sur %d", RUN_KILLS1 = "%d boss sur %d",
    RUN_RESET = "Nouveau run", RUN_RESET_TIP = "Remet à zéro le temps, l'XP, l'or et les boss tués de ce run.",
    RUN_RESET_CLICK = "Clic : recommencer (un second clic confirme)", RUN_RESET_CONFIRM = "Clique encore pour recommencer le run.",
    RUN_RESET_DONE = "Nouveau run : temps, XP, or et boss remis à zéro.",
    RUN_REPORT = "%s : %s · %s XP · %s · %d/%d boss", RUN_REPORT_NOXP = "%s : %s · %s · %d/%d boss",
    RUN_MIN = "%d min", RUN_HMIN = "%d h %02d", RUN_G = "%d po", RUN_S = "%d pa", RUN_C = "%d pc",
    RARE_ALERT = "Rare : %s", RARE_ALERT_LVL = "Rare : %s (niv. %d)", RARE_ALERT_HERE = "Il est tout près.",
    RARE_ALERT_COMBAT = "En combat : cible-le toi-même.",
    INB_STEP_S = "Étape %d/%d", INB_Q_S = "Quêtes %d/%d", INB_DONE_S = "Tout est fait ici",
    -- the step card: one current action, then the other actions at the same NPC
    FOCUS_A = "Prendre « %s »", FOCUS_T = "Rendre « %s »", FOCUS_C = "Faire « %s »", FOCUS_O = "Faire « %s »",
    FOCUS_H = "Avoir « %s » dans ton journal", FOCUS_I = "Obtenir : %s",
    LINE_A = "Prendre « %s »", LINE_T = "Rendre « %s »", LINE_C = "Faire « %s »", LINE_O = "Faire « %s »", LINE_H = "Avoir « %s »", LINE_I = "Obtenir : %s",
    -- the step card's own words (T-37, T-42): one form for every count ("3 sur 8")
    CARD_COUNT = "%d sur %d",
    CARD_PH_BEFORE = "Avant le donjon · %d sur %d", CARD_PH_INSIDE = "Dans le donjon · %d sur %d", CARD_PH_AFTER = "Après le donjon · %d sur %d",
    CARD_PH_BEFORE_D = "Avant le donjon : %s · %d sur %d", CARD_PH_INSIDE_D = "Dans le donjon : %s · %d sur %d",
    CARD_PH_AFTER_D = "Après le donjon : %s · %d sur %d",
    CARD_WHY_Q = "Quête « %s »", CARD_WHY_MAIN = "Quête de donjon « %s »", CARD_WHY_MAIN_S = "Quête de donjon",
    CARD_CHAIN = "étape %d sur %d avant « %s »", CARD_PART = "partie %d sur %d de la suite « %s »", CARD_PRE_N = "prérequis %d sur %d",
    CARD_ELITE = "Élite", CARD_NOELITE = "Non élite", CARD_ELITE_SOME = "En partie élite",
    CARD_BEFORE_WHY = "Requis pour « %s » (dans le donjon)", CARD_BEFORE_OPT = "Facultatif : le donjon se fait sans", CARD_BEFORE_WAY = " · sur le chemin du portail", CARD_BEFORE_KEY = "Requis pour « %s » : la clé pour entrer dans le donjon",
    WHY_FIRST = "D'abord à %s : il faut « %s » avant de parler à %s à %s.", WHY_FIRST_DO = "D'abord à %s : il faut « %s » avant « %s » à %s.",
    SKIP_Q = "Passer", SKIP_Q_CONFIRM = "Clique encore pour passer", SKIP_Q_DONE = "Quête « %s » retirée de la route : recoche-la dans la vue d'ensemble pour la remettre.",
    TT_SKIP_Q = "Retire cette quête facultative de la route, comme la décocher dans la vue d'ensemble. Elle n'est pas abandonnée : si elle est dans ton journal, elle y reste.", SKIP_Q_LOG = "Elle reste dans ton journal de quêtes.",
    CARD_PLUS = "+%d", CARD_PLUS_P = " (et %d autres quêtes)", CARD_PLUS_P1 = " (et 1 autre quête)", CARD_FOR_DG = "pour %s", CARD_TAKE_MAIN = "à faire dans le donjon : prends-la avant d'entrer",
    CARD_NOTLOG = "Pas encore dans ton journal : prends-la d'abord.",
    ROW_ITEM_START = "Commence avec l'objet « %s » : clic droit dessus dans tes sacs.",
    CARD_NOTLOG_ITEM = "Pas dans ton journal : elle commence avec l'objet « %s » (utilise-le dans tes sacs). Si tu ne l'as pas, passe cette étape.",
    CARD_NOTREADY = "Pas encore prête : il te reste ces objectifs.",
    CARD_ENTRY = "Entrée : %s",
    CARD_MORE = "Détails", CARD_LESS = "Masquer les détails",
    CARD_MORE_TT = "Clic : voir la description de la quête et les notes", CARD_LESS_TT = "Clic : replier les détails",
    CARD_ASKS = "Ce qu'elle demandera", CARD_GETS = "En la rendant",
    NEXT_AT = "Ensuite chez %s :", NEXT_PLAIN = "Ensuite :", DONE_HERE = "Déjà fait ici : %s",
    ARROW_GAME = "La flèche suit la zone de quête du jeu", ARROW_LOG = "Lieu exact inconnu : suis ton journal de quêtes",
    FDJ_NOTE = "Note de ForeverDungeonJournal", GAME_TEXT = "Texte de la quête", TT_OBJ_H = "Objectif",
    TT_OUT_L = "hors du donjon", TT_IN_L = "dans le donjon", TT_XPMONEY = "%s XP  ·  %s",
    DUNGEONS_BTN = "Choisir un guide", TT_LINE_CLICK = "Clic : guider vers ce point",
    -- guide navigation (T-84, T-85, T-86): start over, the check-list button, the parts tabs, looking around
    TAC_NONE = "Pas de tactique pour cette étape.", M_TACTICS = "Annoncer la tactique au groupe", TR_M_TACTICS = "Annoncer la tactique au groupe",
    M_STOP = "Arrêter ce guide", TT_STOP = "Décoche les donjons choisis : plus de route, plus de flèche. « Choisir un guide » en lance un autre (comme /wlh stop).",
    STOP_CLICK = "Clic : arrêter (un second clic confirme)", ROUTE_STOPPED = "Guide arrêté. « Choisir un guide » pour en lancer un autre.",
    M_RESTART = "Recommencer la route", RESTART_CONFIRM = "Clique encore pour confirmer",
    TT_RESTART = "Oublie les étapes cochées et l'ordre de la route, puis la recalcule depuis le début (comme /wlh reset).",
    RESTART_CLICK = "Clic : recommencer (un second clic confirme)",
    B_READY_CLOSE = "Fermer la check-list", TT_READY_CLOSE = "Clic : revenir à l'étape en cours",
    TT_READY_OUT1 = "%s : %d objectif à finir dehors avant d'entrer.", TT_READY_OUT = "%s : %d objectifs à finir dehors avant d'entrer.",
    CL_OUT = "À finir dehors avant d'entrer", CL_OUT_OPT = "facultatif",
    CL_OUT_H1 = "Pas encore prêt : %d objectif à finir dehors", CL_OUT_HN = "Pas encore prêt : %d objectifs à finir dehors",
    CL_OUT_T = "Tu as les quêtes, mais ces objectifs se font dehors : finis-les avant d'entrer dans %s.",
    CL_OUT_NEXT = "Les étapes « Dehors » y mènent, dans l'ordre.",
    TAB_BEFORE = "Dehors", TAB_INSIDE = "Dans le donjon", TAB_AFTER = "Après",
    TAB_TT_BEFORE = "Dehors, avant le donjon", TAB_TT_INSIDE = "Dans le donjon", TAB_TT_AFTER = "Après le donjon",
    VIEW_AT = "Tu regardes l'étape %d", TT_VIEW = "Ton étape en cours ne change pas tant que tu regardes ailleurs.",
    M_MEMBER = "Voir où en est %s", TT_MEMBER = "Ouvre son étape en cours dans ton guide, pour regarder : ton étape à toi ne change pas.",
    MEMBER_AT = "Étape %d : %s",
  },
  en = {
    COLON = ": ", WRITS = "Writs and Favor", TT_HWRITS = "Writs and Merchant's Favor: the cheapest Writs, the shopping list and the GPS to the NPCs.", MM_TT4 = "Shift-click: open the Writs window",
    TITLE = "WL Helper",
    SEC_TODO = "At your level", SEC_LATER = "Later", SEC_BELOW = "Below your level", SEC_UP = "Coming soon", BACK_HOME = "Home", SEC_DONE = "Finished", SEC_NOQ = "No quest for your faction",
    PICK_FINISHED = "Finished", PICK_QN = "%d of %d quests turned in", PICK_QN1 = "%d of %d quest turned in", PICK_LV = "Suggested level %d-%d", PICK_LV1 = "Suggested level %d", PICK_PICKED = "Picked", PICK_FIT = "Suggested for you", PICK_FIT_WHY = "Your side, your level, %s away", PICK_FIT_WHY0 = "Your side, your level, close by", PICK_SIZE = "%d players", PICK_OPENS = "opens %s", PICK_DATE = "%b %d, %Y", PICK_SOON = "Coming soon",
    DUNGEONS = "Quest guide", GPS_ON = "On", HOME = "Home", SETTINGS = "Guide settings", GO = "Guide me to the step", BACK_CUR = "Back to the current step",
    NOPOINT_S = "No map point", NEXT2 = "Next step", MORE = "Actions", MORE_BTN = "Actions", PICK_FIRST = "Pick a guide",
    NOROUTE_T2 = "No dungeon picked",
    TT_HOME = "Click: back to Home", TT_SETTINGS = "Click: open the guide settings",
    TT_PICKBTN = "Click: pick the dungeons, raids or class quests of the route", TT_MORE = "Click: mark the step, rebuild the route, GPS arrow, dungeon bosses",
    M_SHARE = "Share quests with the group", M_RECALC = "Rebuild the route from here", M_POINTS = "Put the points on the map",
    M_SKIP = "Mark the step as done", M_UNSKIP = "Mark the step as not done", M_ARROW = "GPS arrow", M_BOSSES = "Dungeon bosses", M_AUTO = "Points set at each step",
    M_LIST = "Step list", ON = "on", OFF = "off",
    M_JOURNAL = "Dungeon journal (bosses, loot)", TT_JOURNAL = "Opens the bosses and loot of the step's dungeon in the installed dungeon journal.",
    NOJOURNAL_TIP = "No dungeon journal installed.",
    NOGROUP_TIP = "Not available outside a group.",
    JOURNAL_NONE = "No dungeon journal is installed: this action needs one to show the bosses and loot.",
    RARE_SEEN = "Rare monster in sight: %s",
    LOADED = "loaded: type /wlh or click the minimap button to open Home.",
    OLD_FOLDER = "The old DungeonGuide folder is still there and is now disabled. Delete it in Interface\\AddOns, then type /reload.",
    PICK = "Pick a guide", LIST = "Steps", PREV = "Previous step", NEXT = "Next step", CURRENT = "Current step",
    POINTS = "Points", NEXTPOINT = "Next point", SHARE = "Share", DONE = "Skip", UNDO = "Undo",
    AUTO_ON = "Auto points: on", AUTO_OFF = "Auto points: off", ARROW = "Arrow",
    STEP = "Step %d / %d", STEPS = "Steps", NOROUTE = "No route",
    NOROUTE_TXT = "The route starts where you stand and includes the prerequisite quests.",
    TAKE = "Accept", DO = "Do", TURNIN = "Turn in", HAVE = "Required", HAVE_OPT = "Optional", OUTSIDE = "Outside", ITEM = "Item",
    S_NONE = "To take", S_ON = "In your log", S_READY = "Ready to turn in", S_DONE = "Turned in",
    B_DONE = "Done", B_CUR = "In progress", B_LATE = "To finish", B_NEXT = "Upcoming",
    IN_DUNGEON = "Inside the dungeon: %s", OUTER = "%s area, before the portal", GATE = "Before entering: %s",
    CLASSQ = "Class quest: %s", CLASS_TAG = "Class: %s",
    B_READY = "Checklist", TT_READY = "What you need before entering: the quests done inside the dungeon but taken outside, and the key if one is needed.",
    TT_READY_CLICK = "Click: open the checklist",
    SHARE_SHORT = "Share quests", NO_READY = "This route has no checklist: no quest has to be taken before entering.",
    GO_MISSING = "Guide me to the missing quest", GO_ENTRANCE = "Guide me to the entrance",
    FIN_T = "Route finished", FIN_PROG = "All %d steps done", FIN_PROG1 = "%d step done", FIN_TXT = "Every quest of %s is turned in. Finished steps stay in the list if you want to look back at them.",
    FIN_MSG = "Route finished: %s. Well done!", PICK_MORE = "Pick other dungeons",
    TT_NEXT = "Shows the next step without completing this one. The guide moves on by itself once the step is done.", TT_NEXT_CLICK = "Click: see the next step",
    TT_PREV_CLICK = "Click: see the previous step",
    INST_ADD = "Add %s to the guide (%d quests)", INST_ADD1 = "Add %s to the guide (%d quest)", INST_T = "You are in %s",
    INST_TXT = "%d quests are done here. The guide sorts them boss by boss.", INST_TXT1 = "%d quest is done here. The guide puts it at the right boss.",
    INST_GO = "Start the guide here",
    INST_CHAT = "You are in %s and %d quests of your route are done here: the guide is open to follow them.",
    INST_PICK = "Several dungeons share this instance. Type /wlh pick to choose yours.",
    STEPS_N = "Steps done: %d of %d", STEP_LEFT = "Step %d of %d", PCT = "%d%%",
    TT_LISTROW = "Click: see this step",
    B_TOGGLE = "Show or hide the guide", B_PICK = "Pick a guide", B_NEXTSTEP = "Next step", B_PREV = "Previous step", B_POINTS = "Set the GPS points", B_ARROW = "Show or hide the arrow",
    PARTY_HAS = "Group members who have it: %s", PARTY_MISS = "Group members missing it: %s",
    KEY_REQ = "Key needed", KEY_DOORS = "Key (doors)", KEY_SHORT = "Key (shortcut)", KEY_HAVE = "in bags", KEY_MISSING = "missing",
    KEY_QUEST = "From the quest \"%s\"", KEY_BOSS = "Dropped by %s (%s)", BOSS = "Boss", RAID = "Raid",
    KEY_WARN = "You do not have the key: someone in the group must have it to open the door.",
    GATE_T = "Before entering %s", GATE_N = "Your dungeon quests can be shared once you are in a group.",
    INSIDE_T = "%s", INSIDE_OUTER_T = "%s: outer area",
    BLOCKED = "Blocked: %s", LVL_REQ = "level %d required", NEED = "turn in %s first",
    GIVER = "Given by %s", OPT = "optional",
    TT_TAKE = "Accept the quest", TT_DO = "Complete the objectives", TT_TURN = "Turn in the quest", TT_HAVE = "Have it in your log before entering",
    TT_OUT = "Objective done outside the instance", TT_ITEM = "Item",
    TT_REWARD = "Reward: %s", TT_XP = "%s XP", TT_CLICK = "Click: guide me to this point", TT_NOPOINT = "No point: it is inside the dungeon.", TT_NOPOINT_UNK = "No point: exact place unknown, follow your quest log.",
    TT_INSIDE = "Inside the dungeon", TT_OUTSIDE = "Outside the dungeon", TT_DROPS = "Drops from: %s",
    TT_TARGET = "Target", TT_TARGET2 = "Targets %s if in sight.",
    TT_RAID = "In a raid you must be leader or assistant to mark.", TT_USE = "Click: use the item", TT_TARGET_CLICK = "Click: target",
    TT_GPS = "Guide me to %s (%.1f, %.1f)", TT_GPS_CLICK = "Click: start the GPS to this point", TT_CONFLICT = "Checked position: the sources disagreed, the majority one is used.",
    TRAVEL_CONT = "You need to change continent: zeppelin or boat.", TRAVEL_FAR = "Long trip: take a flight if you can.",
    TRAVEL_UNK = "Exact place unknown: follow your quest log.",
    NEXT_STEP = "Next step: %s", SHARING = "Sharing %d quests with the group...", SHARING1 = "Sharing 1 quest with the group...", SHARED = "Quest shared: %s", NOTSHARE = "This quest cannot be shared: %s",
    NOGROUP = "You are not in a group: invite someone, then share the quests.", NOSHARE = "Your log has no dungeon quest to share.",
    INCOMBAT = "Not available in combat: try again after the fight.", NOPOINT = "This step has no map point: follow your quest log.",
    POINT_N = "Point %d of %d: %s (%.1f, %.1f).%s", POINT_MORE = " Click \"Next point\" again for the next one.",
    MACRO_MADE = "Macro \"%s\" created. Open /macro, your character's tab, and drag it to your bar: it targets the step's mob or NPC and puts a skull on it.",
    MACRO_FULL = "No room for the DG_Cible macro: your character and account macros are full. Free a slot, then type /reload.",
    MACRO_NONE = "Nothing to target at this step.", MACRO_ON = "Targeting macro on.", MACRO_OFF = "Targeting macro off: it is no longer updated.",
    USEFUL_ON = "Useful quests only: no repeatables and no quests for professions you do not have.", USEFUL_OFF = "Every quest is shown, repeatables and professions included.",
    TT_HPICK = "Pick a guide", TT_HLIST = "Shows or hides the list of every step of the route.",
    LIST_CLOSE = "Close the steps", TT_LIST_CLOSE = "Close the step list", TT_LIST_CLOSE_CLICK = "Click: close the list (the guide's \"Steps\" button opens it again)",
    TT_HLANG = "Addon language (French or English).", COMPACT_BTN = "Modern", TT_HMIN = "Switch to the modern view (frameless, like Polestar)", TT_HMAX = "Expand the guide", TT_HMIN_CLICK = "Click: the guide becomes a small frame (the action now, its objectives, what comes next). Click the frame: the whole guide comes back.", TT_HMAX_CLICK = "Click: show the whole guide",
    TT_HCLOSE = "Close", TT_HCLOSE2 = "To reopen the guide: /wlh dungeons or the minimap button.", TT_HCLOSE_CLICK = "Click: close the guide",
    AB_LABEL = "Target and items", BOSS_N = "Boss %d", ALLDUNGEON_T = "Anywhere", ALLDUNGEON = "Throughout the dungeon",
    BOSS_STEP_N = "Boss %d of %d · %s", IN_WAY = "On the way to %s", BOSS_OPT = "Optional", BOSS_RARE_TAG = "Rare",
    BOSS_OPT_TT = "No quest and no loot for you here: you can skip it. Killing the next boss counts it as passed.",
    H_PATH = "Path", H_TACTIC = "Tactics", H_LOOT = "Loot for you", LOOT_QUEST = "quest item",
    BIS_1 = "BiS", BIS_2 = "2nd pick", BIS_TT = "%s for your spec (Naowh)", BIS_2S = "2nd", BIS_LVS = "BiS %d",
    ROLE_TANK = "Tank", ROLE_HEAL = "Healer", ROLE_ALL = "Everyone", TR_BOSS_N = "Boss %d of %d",
    BOSS_STEP = "Boss: %s", IN_START = "Along the way: dungeon NPCs and objects", IN_TRASH = "Finish in the dungeon: trash loot", IN_TRASH_ANY = "Finish in the dungeon", NAOWH_TIP = "", H_TIP = "Tip", H_ALSO = "On the way, also do", ALSO_TRASH = "On the way, also loot: %s",
    ALSO_ALL = "Throughout the dungeon: %s", ALSO_MOBS = "(drop from the monsters)", ALSO_MOB = "(drops from the monsters)", DUNGEON_MAP = "Dungeon map",
    TT_FPOINTS = "Puts the step's points on the map. When there are several, a second click moves to the next one.",
    TT_FSHARE = "Shares the dungeon quests in your log with the group (those that can be shared).",
    TT_FDONE = "Completes the step by hand and moves on, when the guide cannot see it on its own (quest done earlier, item from a friend...). A second click undoes it.",
    TT_FAUTO = "The GPS goes to each new step on its own.",
    TT_FARROW = "Shows or hides the GPS arrow to the next point.",
    TT_RESIZE = "Guide width", TT_RESIZE2 = "Drag: change the width", TT_RESIZE3 = "Double-click: original width",
    TAB_DG = "Dungeons", TAB_RAID = "Raids", TAB_CLS = "Class quests", CQ_IN = "Done in: %s",
    TAB_QG = "Quests", PICK_HINT_QG = "Quest chains outside dungeons that reward something useful: bags, the Elemental Attractor. They combine with dungeons into one single route.",
    PICK_EMPTY_QG_T = "No quest guide at your level", PICK_EMPTY_QG = "Those of other levels show up with the \"All\" filter.",
    PICK_HINT_CLS = "Your class quests tied to a dungeon. They combine with dungeons into one single route.",
    PICK_HINT_RAID = "Raid attunements: the quests to finish before you can enter.",
    PICK_EMPTY_CLS_T = "No class quest at your level", PICK_EMPTY_CLS = "Those of other levels show up with the \"All\" filter.",
    PICK_EMPTY_T = "No dungeon here", PICK_EMPTY = "Dungeons outside your level show up with the \"All\" filter.",
    PICK_SEARCH = "Dungeon, quest, NPC", PICK_HINT_SEARCH = "Results for \"%s\" across every tab and level.",
    PICK_EMPTY_SEARCH_T = "Nothing for \"%s\"", PICK_EMPTY_SEARCH = "Search a dungeon name (or ZF, BRD, SM), a quest or who gives it.",
    PICK_T = "Pick a guide", PICK_HINT = "Click a dungeon's picture to pick it (several dungeons = one route), then click the button below. \"Overview\" shows a dungeon's quests.", PICK_RUNNING = "Guide in progress", PICK_CHK = "Combine", PICK_CHK_TT = "Click \"+ Add\" to chain this dungeon with others into one route.", PICK_ADD = "+ Add", PICK_ADDED = "Added", PICK_GO_N = "Combine the %d guides",
    PICK_GO = "See the overview", PICK_GO_WHY = "Tick at least one dungeon's box, or click a card.", PICK_NONE = "Clear all", PICK_MINE = "My level", PICK_ALL = "All",
    PICK_QUESTS = "%d quests", PICK_QUESTS1 = "%d quest", PICK_DONE = "%d turned in", PICK_DONE1 = "%d turned in", PICK_NOQ = "No quest",
    GEAR_BIS1 = "%d BiS for you", GEAR_BIS = "%d BiS for you", GEAR_BIS1_S = "%d BiS", GEAR_BIS_S = "%d BiS",
    GEAR_UP1 = "%d upgrade", GEAR_UP = "%d upgrades",
    GEAR_HEAD = "Dungeons to farm for your gear (Naowh's BiS, then WL Helper's upgrades):",
    GEAR_NONE = "No dungeon at your level has a BiS item or an upgrade for you (or Naowh's BiS list is not installed).", PICK_CUSTOM = "Quests", PICK_STAT = "Quests turned in", PICK_QLV = "lvl %d",
    PICK_SEL = "%d dungeons picked", PICK_SEL1 = "1 dungeon picked", PICK_SEL0 = "No dungeon picked",
    PICK_CUSTOM_T = "%s quests", PICK_CUSTOM_H = "Untick the quests you do not want: the route leaves them out.", PICK_RCLICK = "Right-click: choose the quests", PICK_CLICK = "Click: pick this dungeon (or remove it)", PICK_DCLICK = "Double-click: see the overview of this dungeon only",
    PICK_QCLICK = "Click: keep or remove this quest", PICK_QOFF = "Left out of the route",
    ROUTE_BUILT = "Route built: %d steps for %s.", RECALC = "Rebuild", RECALC_TT = "Rebuilds the route from where you stand.",
    ARROW_FAR = "Other continent", ARROW_IN = "In the dungeon", YARDS = "%d m",
    LANG = "Language: English.", BONUS = "Bonus", UNKNOWN_LOC = "place to confirm",
    PRE = "Prerequisite", MAIN = "Dungeon quest", DETAILS = "Details", HIDE = "Hide",
    MM_TT1 = "Click: open or close the guide", MM_TT2 = "Right-click: pick a guide", MM_TT3 = "Drag: move the button",
    HELP = "/wlh: open Home\n/wlh dungeons: open the quest guide\n/wlh pick: pick a guide\n/wlh trade: open the Writs window (Writs and Favor)\n/wlh bags: clean your bags\n/wlh orders: open crafting orders\n/wlh guild: see the guild and the PvP ranking\n/wlh groups: the guild's events and who is looking for a group\n/wlh gps: stop or restart the GPS\n/wlh goto [place]: the arrow takes you to a place, a service or an NPC\n/wlway Tanaris 52.4 31.2: WL Helper's arrow goes to that point (also /way when no other addon has it)\n/wlh city: what there is to do in this capital\n/wlh keys: the key passport\n/wlh quests: dungeon quests shared with the guild\n/wlh triage: quests to abandon when the log is full\n/wlh settings: open the settings\n/wlh setup: see the welcome screen again\n/wlh welcome: the Welcome page, every setting step by step\n/wlh tour: the guided tour\n/wlh idea: send an idea or a bug\n/wlh tracker: show or hide the guide tracker\n/wlh boss: show or hide the dungeon's bosses\n/wlh help: open How do I...? (/wlh help chat: this list in chat)",
    UNKNOWN_CMD = "Unknown command \"%s\". Type /wlh help to see the list.",
    RESET = "Steps completed by hand and the route are reset.", SKIP = "Skip",
    B_READY_T = "Checklist before entering",
    TT_READY_OK = "%s: ready, nothing missing.",
    TT_READY_KEY = "%s: quests taken, but no key.",
    TT_READY_MISS = "%s: %d quests to take before entering.",
    TT_READY_MISS1 = "%s: 1 quest to take before entering.",
    CL_OK_H = "Ready for %s",
    CL_OK_T = "The required quests you can already take are in your quest log.",
    CL_OK_NEXT = "Next: the dungeon entrance.",
    CL_KEY_H = "Quests taken, but no key",
    CL_KEY_T = "You have every %s quest, but not the key that opens the entrance.",
    CL_KEY_NEXT = "Someone in the group must have it. Otherwise, the Key part below says where to get it.",
    CL_MISS_H1 = "Not ready yet: 1 quest to take",
    CL_MISS_HN = "Not ready yet: %d quests to take",
    CL_MISS_T = "These quests are taken outside the dungeon (%s): without them, your objectives inside do not count.",
    CL_MISS_T1 = "This quest is taken outside the dungeon (%s): without it, your objectives inside do not count.",
    CL_MISS_NEXT = "Click a \"To take\" quest to point the GPS at the NPC who gives it.",
    CL_WHAT_H = "What the checklist checks",
    CL_WHAT = "Before entering %s: the quests done inside (they are taken outside), then the key if one is needed.",
    RUN_GATE_N = "No quest here. Go to the entrance and step in: the guide then leads you from boss to boss.",
    CL_KEY = "Key",
    CL_ENTRY = "Entrance",
    CL_GROUP = "Group",
    CL_HAVE = "In your log",
    CL_TAKE = "To take",
    BACK_FIN = "Back to the end of the route",
    LIST_MORE = "Wheel: %d above, %d below",
    INB_T = "Inside the dungeon: %s",
    INB_STEP = "Step %d / %d in the dungeon",
    INB_Q = "Quests finished here: %d / %d",
    INB_BOSS = "Next boss: %s",
    INB_DONE = "Everything is done here: once you leave, the guide picks the route up again.",
    INB_BACK = "Click: back to the dungeon's step",
    INB_TT = "The guide shows this dungeon's steps boss by boss, with each objective's progress. Once you leave, it picks the route up outside.",
    INST_IN = "You are in %s: the guide shows the dungeon's steps.",
    INST_LEFT = "You left %s: the guide picks the route up again.",
    -- tracker (Tracker.lua): phase chapters, one action per line, its tooltips
    PH_BEFORE = "Before the dungeon: %s · %d of %d", PH_INSIDE = "In the dungeon: %s · %d of %d", PH_AFTER = "After the dungeon: %s · %d of %d",
    PH_BEFORE_S = "Before the dungeon", PH_INSIDE_S = "In the dungeon", PH_AFTER_S = "After the dungeon",
    TR_WHAT = "Guide tracker: what to do now", TR_TITLE = "Guide tracker", TR_CLOSE = "Close", TR_CLOSE_TIP = "Click: close the guide (the minimap button or /wlh opens it again)", TR_DONE_T = "Guide finished!", TR_DONE_SUB = "Well done! Pick what comes next:", TR_NONE_T = "No guide running", TR_NONE_SUB = "Pick a guide to start:",
    TR_TAKE = "Accept \"%s\"", TR_TURN = "Turn in \"%s\"", TR_DO = "Do \"%s\"", TR_HAVE = "Have \"%s\" in your log",
    TR_STEP = "Step %d", TR_THEN = "Then", TR_NOTE = "Good to know", TR_FROM_ITEM = "· item \"%s\" in your bags", TR_PREV = "Previous step", TR_NEXT = "Next step",
    TR_BACK = "· back to the current step", TR_PAST = "PAST STEP", TR_AHEAD = "COMING STEP", TR_ALREADY = "Already done:", TR_MENU = "Menu", TR_MENU_TIP = "Click: actions and settings (also right-click the title)",
    TR_M_WINDOW = "Open the guide window", TR_M_GO = "Guide me to the step", TR_M_DONE = "Mark the step as done",
    TR_M_SHARE = "Share the quests with the group", TR_M_BOSSES = "Dungeon bosses", TR_M_MAP = "Dungeon map",
    TR_M_FRAMED = "With a frame", TR_M_FRAMELESS = "Frameless", TR_M_OPTIONS = "Guide settings",
    TR_M_STOP = "Stop this guide", TR_M_HIDE = "Hide the modern view", TR_G_STEP = "STEP", TR_G_DUNGEON = "THIS DUNGEON", TR_G_GUIDES = "GUIDES", TR_G_VIEW = "DISPLAY", TR_KILL = "Kill: %s", TR_LOOT = "Loot: %s", TR_USE = "Use: %s", TR_TALK = "Talk to %s", TR_GO = "Go to: %s", TR_OBJ = "Objective: %s",
    TR_ITEM = "Get %s", TR_ENTER = "Enter %s", TR_BOSS = "Boss: %s",
    TR_MISSING1 = "%d quest to take before going in", TR_MISSING = "%d quests to take before going in",
    TR_TIP_CLICK = "Click: next step · Right-click: previous step", TR_STEPS_SHOW = "▸ All the steps", TR_STEPS_HIDE = "▾ Hide the steps",
    TR_M_PICK = "Pick a guide", TR_M_OVERVIEW = "Dungeon overview",
    TR_L_PICK = "Guides", TR_L_OVERVIEW = "Overview", TR_L_BOSSES = "Bosses", TR_L_MAP = "Map", TR_L_SHARE = "Share", TR_TIP_SHIFT = "Shift-click: mark the step as done",
    TR_TIP_DRAG = "Drag the title: move the tracker",
    TR_COLLAPSE = "Collapse the tracker", TR_EXPAND = "Expand the tracker",
    TR_COMPACT = "Modern view: the gear (or a right-click on the title) opens the menu; drag the title to move it.",
    TR_ON = "Guide tracker shown. Type /wlh tracker to hide it.", TR_OFF = "Guide tracker hidden. Type /wlh tracker to bring it back.",
    TR_NOROUTE = "No route yet. Type /wlh pick to pick a guide.",
    TR_MARKED = "Step marked as done: %s",
    TR_GUIDE_OFF = "The quest guide is turned off: the tracker comes back when you turn it on in Settings > General > Modules.",
    -- key binding: target and mark
    B_TARGET = "Target the step's NPC or mob",
    TARGET_LATER = "The targeting key will be ready after combat.",
    B_ITEM = "Use the step's quest item", B_GROUPS = "Open Find a group",
    ITEM_LATER = "The item key will be ready after combat.",
    ITEM_NONE = "No quest item to use at this step.",
    M_KEYS = "Key bindings",
    TT_KEYS = "Click: open the game's key bindings. The guide's keys (target, use the item, next step...) are in the AddOns > WL Helper section.",
    KEY_IS = "Key: %s", KEY_NONE = "No key: right-click to set one",
    KEYS_HINT = "Key bindings: Esc > Options > Keybindings > AddOns > WL Helper",
    KEYS_OPENED = "The guide's keys are in the AddOns > WL Helper section, at the bottom of the list.",
    KEYS_COMBAT = "The key bindings cannot open in combat: try again after.",
    SHARE_N1 = "Share %d quest", SHARE_N = "Share %d quests",
    -- prerequisite chains and the ranked status words (picker, list and card)
    CH_STEP = "Prerequisite %d of %d", CH_BEFORE = "Step %d of %d before \"%s\"", CH_PART = "Part %d of %d of the \"%s\" chain",
    CH_NONE = "No prerequisite", CH_COUNT1 = "%d prerequisite", CH_COUNT = "%d prerequisites", CH_ALLDONE = "Prerequisites done",
    ST_PRE = "Prerequisite %d of %d", ST_PRELOG = "Prerequisite %d of %d in progress", ST_LOW = "Level %d required",
    ST_PICKUP = "To take", ST_ACTIVE = "In progress", ST_READY = "Ready to turn in", ST_DONE = "Turned in",
    -- guide window: chapter headers in the step list, overview, bosses and tracker entries
    TT_CHAPTER_CLICK = "Click: go to the first open step of this part", CH_PROGRESS = "Steps done: %d of %d",
    OV_HDR_T = "Overview: %s",
    BOSS_MENU_CLICK = "Click: show the dungeon's bosses and rares", BOSS_MENU_NONE = "No dungeon in the route yet.",
    TR_MENU_TT = "A small window with the current action and the next two, even with the guide closed.",
    TR_MENU_CLICK = "Click: show or hide the tracker",
    -- dungeon overview (Overview.lua)
    OV_T = "Overview", OV_BTN = "Overview", OV_CLICK = "Click: open the dungeon overview", OV_RCLICK = "Right-click: dungeon overview", OV_ENTRANCE = "Entrance: %s",
    OV_GROUP = "Group of %d players", OV_SUM_Q1 = "%d quest", OV_SUM_Q = "%d quests", OV_SUM_LOG1 = "%d in your log",
    OV_SUM_LOG = "%d in your log", OV_SUM_PRE1 = "%d missing prerequisite", OV_SUM_PRE = "%d missing prerequisites",
    OV_SUM_PRE0 = "no missing prerequisite", OV_SUM_OFF1 = "%d left out of the route", OV_SUM_OFF = "%d left out of the route",
    OV_PRE1 = "Prerequisite: %s", OV_PRE = "Prerequisites: %s", OV_PRE_DONE1 = "done", OV_PRE_DONE = "done", OV_PRE_TODO1 = "not done",
    OV_PRE_TODO = "not done", OV_PRE_PART = "%d of %d done", OV_MORE = "+%d", OV_CHAIN = "Chain: step %d of %d", OV_CHAIN_TT = "Quest chain",
    OV_THIS = "this quest", OV_GIVER = "Quest giver: %s", OV_FINISHER = "Turn in to: %s", OV_IN_DG = "inside the dungeon",
    OV_ITEM_START = "Starts from the item %s", OV_CHOICE = "Reward of your choice", OV_UPGRADE = "An upgrade for you", OV_UPGRADE_AT = "At level %d (the quest's): %s",
    OV_ON_T = "In the route", OV_ON_CLICK = "Click: leave this quest out of the route", OV_OFF_CLICK = "Click: put this quest back in the route",
    OV_ST_OFF = "Left out", OV_GPS_T = "Guide me to %s", OV_GPS_CLICK = "Click: start the GPS", OV_ROW_CLICK = "Click: guide me to %s",
    OV_ENTRY_T = "the dungeon entrance", OV_EMPTY_T = "No quest for you here", OV_EMPTY = "This dungeon's quests are for another class, faction or race.",
    OV_EMPTY_UP = "Quests arrive when this dungeon opens.", OV_GO = "Guide this dungeon", OV_GO_WHY = "No quest to do here for this character.",
    OV_GO_TT = "Click: start the route with this dungeon only (replaces your picked dungeons)", OV_PICK = "Pick this dungeon",
    OV_UNPICK = "Unpick this dungeon", OV_PICK_TT = "Click: tick this dungeon in the guide picker", OV_UNPICK_TT = "Click: untick this dungeon in the guide picker",
    OV_KEY_NONE = "No key needed", OV_CARD_PRE1 = "%d waiting on a prerequisite", OV_CARD_PRE = "%d waiting on a prerequisite",
    OV_SEC_DONE = "Turned in", OV_EMPTY_NONE = "This dungeon has no quests.", OV_GO_DONE = "All quests are turned in.",
    TT_SHIFT_LINK = "Shift-click: link in chat",
    -- bosses and rares panel (Bosses.lua)
    BOSS_NOTFOUND = "Not targeted: %s. It must be in sight; if it is, tell us (the click may not reach it).", BOSS_TITLE = "Bosses and rares", BOSS_SEC = "Boss", BOSS_RARES = "Rares", BOSS_LVL = "level %d", BOSS_LVL2 = "level %d-%d",
    BOSS_TARGET = "Target", BOSS_TT_TARGET = "Targets %s if in sight.",
    BOSS_TT_CLICK = "Click: target and mark", BOSS_WAIT = "Updates after combat",
    BOSS_KILLED = "Killed during this visit", BOSS_R_BOSS = "Boss", BOSS_R_ELITE = "Elite", BOSS_R_RAREELITE = "Rare elite",
    BOSS_R_RARE = "Rare", BOSS_EMPTY_NOLIB = "The boss list is not available on this client.",
    BOSS_EMPTY_NONE = "No boss or rare is known in this dungeon.", BOSS_LOADING = "The list shows up in a moment.",
    BOSS_ATTACH = "Dock to the guide", BOSS_ATTACH_TT = "The panel sits beside the guide and follows it when it moves.", BOSS_ATTACH_CLICK = "Click: put the bosses back beside the guide", BOSS_DRAG = "Drag: detach and move",
    BOSS_FOR = "For \"%s\"", BOSS_FOR_ITEM = "%s for \"%s\"",
    BOSS_MENU_HIDE = "Click: hide the bosses and rares",
    BOSS_UNSEEN = "Not seen yet", BOSS_SEEN = "Already met", BOSS_TT_CLICKM = "Click: target", BOSS_TT_RCLICK = "Right-click: mark killed / not killed",
    BOSS_DRAG2 = "Drag: move", BOSS_CLOSE_CLICK = "Click: hide the bosses (the guide's button shows them again)",
    BOSS_KILLED_AT = "Killed at +%s",
    RUN_TIME = "Time", RUN_XP = "XP", RUN_GOLD = "Gold",
    RUN_STATS_TIP = "The time runs from the entrance to the last boss. The XP counts the mobs and the quests turned in inside the dungeon.",
    RUN_NONE = "Your run's time, XP and gold show up here once you enter the dungeon.",
    RUN_TIP_LINE = "This run: %s", RUN_XP_PCT = "%s XP (%d%% of a level)", RUN_XP_LVN = "%s XP (about %s levels)",
    RUN_KILLS = "%d of %d bosses", RUN_KILLS1 = "%d of %d boss",
    RUN_RESET = "New run", RUN_RESET_TIP = "Clears this run's time, XP, gold and killed bosses.",
    RUN_RESET_CLICK = "Click: start over (a second click confirms)", RUN_RESET_CONFIRM = "Click again to start a new run.",
    RUN_RESET_DONE = "New run: time, XP, gold and bosses cleared.",
    RUN_REPORT = "%s: %s · %s XP · %s · %d/%d bosses", RUN_REPORT_NOXP = "%s: %s · %s · %d/%d bosses",
    RUN_MIN = "%d min", RUN_HMIN = "%d h %02d", RUN_G = "%dg", RUN_S = "%ds", RUN_C = "%dc",
    RARE_ALERT = "Rare: %s", RARE_ALERT_LVL = "Rare: %s (level %d)", RARE_ALERT_HERE = "It is close by.",
    RARE_ALERT_COMBAT = "In combat: target it yourself.",
    INB_STEP_S = "Step %d/%d", INB_Q_S = "Quests %d/%d", INB_DONE_S = "All done here",
    -- the step card: one current action, then the other actions at the same NPC
    FOCUS_A = "Accept \"%s\"", FOCUS_T = "Turn in \"%s\"", FOCUS_C = "Do \"%s\"", FOCUS_O = "Do \"%s\"",
    FOCUS_H = "Have \"%s\" in your log", FOCUS_I = "Get %s",
    LINE_A = "Accept \"%s\"", LINE_T = "Turn in \"%s\"", LINE_C = "Do \"%s\"", LINE_O = "Do \"%s\"", LINE_H = "Have \"%s\"", LINE_I = "Get %s",
    -- the step card's own words (T-37, T-42): one form for every count ("3 of 8")
    CARD_COUNT = "%d of %d",
    CARD_PH_BEFORE = "Before the dungeon · %d of %d", CARD_PH_INSIDE = "In the dungeon · %d of %d", CARD_PH_AFTER = "After the dungeon · %d of %d",
    CARD_PH_BEFORE_D = "Before the dungeon: %s · %d of %d", CARD_PH_INSIDE_D = "In the dungeon: %s · %d of %d",
    CARD_PH_AFTER_D = "After the dungeon: %s · %d of %d",
    CARD_WHY_Q = "Quest \"%s\"", CARD_WHY_MAIN = "Dungeon quest \"%s\"", CARD_WHY_MAIN_S = "Dungeon quest",
    CARD_CHAIN = "step %d of %d before \"%s\"", CARD_PART = "part %d of %d of the \"%s\" chain", CARD_PRE_N = "prerequisite %d of %d",
    CARD_ELITE = "Elite", CARD_NOELITE = "Not elite", CARD_ELITE_SOME = "Partly elite",
    CARD_BEFORE_WHY = "Required for \"%s\" (in the dungeon)", CARD_BEFORE_OPT = "Optional: the dungeon can be done without it", CARD_BEFORE_WAY = " · on the way to the portal", CARD_BEFORE_KEY = "Required for \"%s\": the key to get into the dungeon",
    WHY_FIRST = "First to %s: you need \"%s\" before talking to %s in %s.", WHY_FIRST_DO = "First to %s: you need \"%s\" before \"%s\" in %s.",
    SKIP_Q = "Skip", SKIP_Q_CONFIRM = "Click again to skip", SKIP_Q_DONE = "Quest \"%s\" removed from the route: tick it again in the overview to bring it back.",
    TT_SKIP_Q = "Takes this optional quest out of the route, like unticking it in the overview. It is not abandoned: if it is in your quest log, it stays there.", SKIP_Q_LOG = "It stays in your quest log.",
    CARD_PLUS = "+%d", CARD_PLUS_P = " (and %d other quests)", CARD_PLUS_P1 = " (and 1 other quest)", CARD_FOR_DG = "for %s", CARD_TAKE_MAIN = "done in the dungeon: take it before going in",
    CARD_NOTLOG = "Not in your log yet: accept it first.",
    ROW_ITEM_START = "Starts from the item \"%s\": right-click it in your bags.",
    CARD_NOTLOG_ITEM = "Not in your log: it starts from the item \"%s\" (use it from your bags). If you don't have it, skip this step.",
    CARD_NOTREADY = "Not ready yet: these objectives are left.",
    CARD_ENTRY = "Entrance: %s",
    CARD_MORE = "Details", CARD_LESS = "Hide details",
    CARD_MORE_TT = "Click: show the quest description and notes", CARD_LESS_TT = "Click: fold the details",
    CARD_ASKS = "What it will ask", CARD_GETS = "When you turn it in",
    NEXT_AT = "Then at %s:", NEXT_PLAIN = "Then:", DONE_HERE = "Already done here: %s",
    ARROW_GAME = "The arrow follows the game's quest area", ARROW_LOG = "Exact place unknown: follow your quest log",
    FDJ_NOTE = "ForeverDungeonJournal note", GAME_TEXT = "Quest text", TT_OBJ_H = "Objective",
    TT_OUT_L = "outside the dungeon", TT_IN_L = "inside the dungeon", TT_XPMONEY = "%s XP  ·  %s",
    DUNGEONS_BTN = "Pick a guide", TT_LINE_CLICK = "Click: guide me to this point",
    -- guide navigation (T-84, T-85, T-86): start over, the checklist button, the parts tabs, looking around
    TAC_NONE = "No tactics for this step.", M_TACTICS = "Tell the group the tactics", TR_M_TACTICS = "Tell the group the tactics",
    M_STOP = "Stop this guide", TT_STOP = "Unpicks the dungeons: no route, no arrow. \"Pick a guide\" starts another one (like /wlh stop).",
    STOP_CLICK = "Click: stop (a second click confirms)", ROUTE_STOPPED = "Guide stopped. \"Pick a guide\" to start another one.",
    M_RESTART = "Start the route over", RESTART_CONFIRM = "Click again to confirm",
    TT_RESTART = "Forgets the ticked steps and the route's order, then builds it again from the start (like /wlh reset).",
    RESTART_CLICK = "Click: start over (a second click confirms)",
    B_READY_CLOSE = "Close the checklist", TT_READY_CLOSE = "Click: back to the current step",
    TT_READY_OUT1 = "%s: %d objective to finish outside before entering.", TT_READY_OUT = "%s: %d objectives to finish outside before entering.",
    CL_OUT = "To finish outside before entering", CL_OUT_OPT = "optional",
    CL_OUT_H1 = "Not ready yet: %d objective to finish outside", CL_OUT_HN = "Not ready yet: %d objectives to finish outside",
    CL_OUT_T = "You have the quests, but these objectives happen outside: finish them before entering %s.",
    CL_OUT_NEXT = "The \"Outside\" steps lead there, in order.",
    TAB_BEFORE = "Outside", TAB_INSIDE = "In the dungeon", TAB_AFTER = "After",
    TAB_TT_BEFORE = "Outside, before the dungeon", TAB_TT_INSIDE = "In the dungeon", TAB_TT_AFTER = "After the dungeon",
    VIEW_AT = "You are looking at step %d", TT_VIEW = "Your current step does not change while you look elsewhere.",
    M_MEMBER = "See where %s is", TT_MEMBER = "Opens their current step in your guide, just to look: your own step does not change.",
    MEMBER_AT = "Step %d: %s",
  },
}

ns.lang = (GetLocale and GetLocale() == "frFR") and "fr" or "en"
ns.L = setmetatable({}, { __index = function(_, k) return S[ns.lang][k] or S.en[k] or k end })
ns.LOCALE_TABLES = S   -- read by the tests: every key exists in both languages
ns.TR = ns.TR or {}  -- traductions des textes de quêtes (anglais -> français), remplies dans Texts_frFR.lua

-- n == 1 picks the singular key ("1 quête" / "2 quêtes"): ns.Plural(n, "PICK_QUESTS1", "PICK_QUESTS", ...)
-- French also takes the singular for 0 ("0 quête", "0 faite"); English does not ("0 quests").
-- French elision after "de": "auprès de Eva" -> "auprès d'Eva", "Butin de Arcanist Doan" ->
-- "Butin d'Arcanist Doan" (a vowel only: an "h" may be aspirated); English is left as is
function ns.Elide(s)
  if ns.lang ~= "fr" or type(s) ~= "string" then return s end
  local out = s:gsub("(%f[%w][dD]e) ([AEIOUYaeiouy\195])", function(de, c)
    return de:sub(1, 1) .. "'" .. c
  end)
  return out
end

function ns.Plural(n, one, many, ...)
  local single = (n == 1) or (ns.lang == "fr" and n == 0)
  local f = (single and ns.L[one]) or ns.L[many]
  return f:format(...)
end

-- Texte de données dans la langue choisie (l'anglais est la source).
function ns.T(en)
  if not en then return nil end
  if ns.lang == "fr" then return ns.TR[en] or (ns.NPCFR and ns.NPCFR[en]) or en end
  return en
end
-- an NPC's name as the guide shows it (French in French: the game's own name, NpcNames_frFR.lua)
function ns.NpcName(en)
  if type(en) ~= "string" then return en end
  if ns.lang == "fr" and ns.NPCFR then return ns.NPCFR[en] or en end
  return en
end
-- an NPC's name as the game client knows it, for /targetexact (a French client: the French name,
-- whatever language the addon speaks)
function ns.ClientNpcName(en)
  if type(en) ~= "string" then return en end
  if GetLocale and GetLocale() == "frFR" and ns.NPCFR then return ns.NPCFR[en] or en end
  return en
end

function ns.SetLang(l)
  if l ~= "fr" and l ~= "en" then return end
  ns.lang = l
  if WLDTDB then WLDTDB.lang = l end
end

-- ---------------------------------------------------------------- item lookups
-- Forever's client may lack the old item globals (GetItemInfo, GetItemCount, GetItemIcon,
-- IsEquippedItem): C_Item first, the old global as the fallback. Each returns what the old global
-- did (ns.ItemInfo: GetItemInfo's values, nil while the item is not cached).
local function Secret(v) return issecretvalue ~= nil and issecretvalue(v) end
local function Pack(...) return { n = select("#", ...), ... } end
local function Try(f, ...)
  if type(f) ~= "function" then return nil end
  local r = Pack(pcall(f, ...))
  -- a secret first value is still an answer (no comparison on it); the callers drop it
  if r[1] and (Secret(r[2]) or r[2] ~= nil) then return r end
end
function ns.ItemInfo(item)
  if item == nil then return nil end
  local r = Try(C_Item and C_Item.GetItemInfo, item) or Try(GetItemInfo, item)
  if r then return unpack(r, 2, r.n) end
end
function ns.ItemCount(item, bank)
  if item == nil then return 0 end
  for _, f in ipairs({ C_Item and C_Item.GetItemCount or false, GetItemCount or false }) do
    local r = f and Try(f, item, bank and true or false)
    local n = r and r[2]
    if type(n) == "number" and not Secret(n) then return n end
  end
  return 0
end
function ns.ItemIcon(item)
  if item == nil then return nil end
  local r = Try(C_Item and C_Item.GetItemIconByID, item) or Try(GetItemIcon, item)
  if r and not Secret(r[2]) then return r[2] end
  r = Try(C_Item and C_Item.GetItemInfoInstant, item) or Try(GetItemInfoInstant, item)
  if r and r[6] ~= nil and not Secret(r[6]) then return r[6] end
end
function ns.IsEquipped(item)
  if item == nil then return false end
  for _, f in ipairs({ C_Item and C_Item.IsEquippedItem or false, IsEquippedItem or false }) do
    local r = f and Try(f, item)
    if r and not Secret(r[2]) and r[2] then return true end
  end
  return false
end
