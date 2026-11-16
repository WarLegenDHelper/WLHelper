-- WhatsNew.lua: generated from CHANGELOG.md by the release (make_whatsnew.py; do not edit by hand).
-- Per version: v, date, items = { { s = "add"|"chg"|"fix", fr = { title, text }, en = { title, text } } }
local _, ns = ...
ns.WHATSNEW = {
  { v = "1.0.0-beta.75", date = "2026-11-16", items = {
    { s = "fix", fr = { "Le guide se fermait encore après un téléport", "Le jeu ferme ses fenêtres avant que l'addon regarde si le guide était ouvert. Le moment de la fermeture est maintenant retenu : un guide ouvert revient après un téléport, un portail ou un /reload." }, en = { "The guide no longer closes after a teleport, a portal or a /reload.", "" } },
  } },
  { v = "1.0.0-beta.74", date = "2026-11-16", items = {
    { s = "add", fr = { "Fenêtre WL Helper façon Naowh", "Une seule fenêtre avec, à gauche, une recherche et les activités (Quêtes & donjons, Objets & métiers, Guilde & groupes, Voyage) et leurs réglages ; à droite, l'accueil en deux colonnes. La minimap, /wlh et les boutons retour l'ouvrent sur la bonne page." }, en = { "WL Helper hub like Naowh", "One window, sidebar grouped by activity with search, Home in two columns, settings next to each activity." } },
    { s = "add", fr = { "Chemin à pied comme Polestar", "La flèche suit le vrai chemin, virage après virage, pour toutes les destinations ; la distance est celle qu'il reste à marcher ; des points sur la carte du monde et la minimap, une épingle sur l'endroit exact." }, en = { "Walking path like Polestar for every destination, drawn on the map and minimap.", "" } },
    { s = "add", fr = { "La meilleure route", "La pierre de foyer, le Rappel astral et Reflet-de-Lune comptent dans le calcul, avec les vrais temps à pied ; l'itinéraire complet s'affiche (« Pierre de foyer → vol jusqu'à Kargath → 300 m à pied »)." }, en = { "Best route", "Hearthstone and class teleports, real walking times, full itinerary." } },
    { s = "add", fr = { "Repère dans le monde", "Une étiquette au-dessus de la destination (lieu, distance, temps restant), seulement si aucun autre addon ne le fait déjà. Réglages › GPS." }, en = { "In-world marker over the destination, only when no other addon already shows one.", "" } },
    { s = "chg", fr = { "Flèche GPS façon Zygor", "En haut l'action (l'icône du sort ou de l'objet à cliquer pour un téléport ou la pierre de foyer), puis quoi faire, où, et « 550 m · 1:10 »." }, en = { "GPS arrow organised like Zygor", "Clickable spell or item icon, what, where, distance and time." } },
    { s = "chg", fr = { "Carte de l'étape du guide refaite", "L'action en titre, le lieu avec la distance, une ligne pour la chaîne, les détails repliés ; plus aucune info répétée. Une étape « prendre la quête » ne montre plus le texte de la quête comme si c'était à faire." }, en = { "Guide step card rebuilt", "Action first, place and distance, folded details, nothing repeated." } },
    { s = "chg", fr = { "Noms", "« Overview » / « Vue d'ensemble » et « Pick a guide » / « Choisir un guide »." }, en = { "Names", "Overview and Pick a guide." } },
    { s = "chg", fr = { "Commandes avec beaucoup d'artisans", "Au-delà de 8, une liste « Artisans : 3 en ligne · 24 en tout » avec recherche ; deux noms au plus sur les lignes d'objets." }, en = { "Orders scale to many crafters", "Searchable list, two names per item row." } },
    { s = "chg", fr = { "Quoi de neuf", "Plus lisible, **Aller à…** avec distances en direct, bouton retour sur toutes les fenêtres." }, en = { "Clearer What's new, live Go-to distances, back buttons everywhere.", "" } },
    { s = "chg", fr = { "Interface et textes", "Revus fenêtre par fenêtre : vocabulaire, niveaux, nombres, icônes." }, en = { "Interface and texts reviewed window by window.", "" } },
    { s = "fix", fr = { "Prérequis de quêtes", "169 liens entre maillons de chaîne ajoutés (LibForeverData, et Naowh pour les quêtes propres à Forever) ; Rot and Regret n'arrive plus avant Word of the Woods." }, en = { "Quest prerequisites", "169 missing chain links added." } },
    { s = "fix", fr = { "Le guide se fermait", "Après un téléport ou un /reload." }, en = { "The guide no longer closes after a loading screen.", "" } },
    { s = "fix", fr = { "Marques de raid", "Le jeu ne laisse pas un addon poser une marque ; les boutons ciblent seulement, plus d'erreur." }, en = { "Raid markers", "Targeting only, no more blocked-action error." } },
    { s = "fix", fr = { "Erreurs dans les donjons", "Valeurs cachées par le jeu (PNJ des caisses, alerte des rares)." }, en = { "Secret-value errors inside dungeons.", "" } },
    { s = "fix", fr = { "Icônes de récompense", "Manquantes et améliorations plus lisibles." }, en = { "Missing reward icons and clearer upgrades.", "" } },
  } },
  { v = "1.0.0-beta.73", date = "2026-11-16", items = {
    { s = "fix", fr = { "Zygor", "La flèche de WL Helper ne prend plus la place de celle de ton guide Zygor. En « Automatique », c'est le GPS de WL Helper (avec son bouton pour l'arrêter) ; Zygor seulement si tu le choisis dans Réglages › GPS. Pour arrêter le GPS : /wlh gps." }, en = { "WL Helper no longer takes over your Zygor guide's arrow; Zygor only when you pick it.", "" } },
  } },
  { v = "1.0.0-beta.72", date = "2026-11-16", items = {
    { s = "add", fr = { "Tournée en ville", "En arrivant dans une capitale, une fiche liste ce qu'il y a à y faire (maître de classe, courrier, réparations, quêtes à rendre, composants à sortir de la banque pour une commande, achats des Writs, munitions) dans l'ordre de marche ; chaque tâche se coche toute seule et la flèche va de l'une à l'autre." }, en = { "City tour", "What to do in a capital, in walking order, ticked automatically." } },
    { s = "add", fr = { "Passeport des clés", "Chaque clé ou accès (Scholomance, UBRS, Onyxia...) possédé, en cours (étape N sur M) ou pas commencé, avec « Guide-moi » ; onglet « Qui a la clé ? » dans la Guilde ; alerte sur un groupe si personne n'a la clé." }, en = { "Key passport, who has the key in the guild, LFG warning.", "" } },
    { s = "add", fr = { "Quêtes en commun", "Les membres de la guilde qui ont les mêmes quêtes de donjon que toi, avec Grouper et Chuchoter." }, en = { "Shared dungeon quests with guild members.", "" } },
    { s = "add", fr = { "Tri du journal", "Quand le journal est presque plein, des conseils d'abandon avec la raison ; les quêtes de tes donjons, de clés et de classe sont protégées." }, en = { "Quest log triage when the log is nearly full.", "" } },
    { s = "add", fr = { "/way", "« /wlway Tanaris 52,4 31,2 » envoie la flèche de WL Helper au point (et /way quand aucun autre addon ne l'a)." }, en = { "A /way point straight into WL Helper's arrow.", "" } },
    { s = "add", fr = { "Alt + clic dans les sacs", "Désenchanter (enchanteurs) et crocheter (voleurs) en un clic." }, en = { "Alt-click to disenchant or pick a lock.", "" } },
    { s = "add", fr = { "Carte du donjon", "Un bouton dans la fenêtre des boss ouvre la meilleure carte installée (OpenMap, Naowh, FDJ, sinon la carte du monde)." }, en = { "Dungeon map button in the boss panel.", "" } },
    { s = "add", fr = { "Aller à…", "Cherche une destination (banque, HV, maître de classe, PNJ, zone, entrée de donjon) ; la flèche suit un vrai chemin à pied grâce à WLHelper_Nav, livré à côté (addon GPL séparé, tiré de Polestar Nav et de Shortest Path Forever, crédités)." }, en = { "Go to", "Search a destination, walking trail from WLHelper_Nav (shipped alongside, GPL)." } },
    { s = "add", fr = { "Classement PvP de la guilde", "D'où viennent les victoires honorables (zones, champs de bataille) et un K/D/A en champ de bataille ; morts face aux joueurs en monde ouvert." }, en = { "Guild PvP", "Where HKs come from, battleground K/D/A." } },
    { s = "chg", fr = { "Résumé du donjon refait", "Bannière « Conseillé niv. 38 à 48 · tu es niv. 41 », puis Entrée, Clé, Avant d'entrer et Tu gagnes ; sur chaque quête, la difficulté en mots, le niveau où elle se prend, l'XP que tu gagnes vraiment (réduite pour une quête grise) et une seule façon de dire son état." }, en = { "Summary redesign", "Suggested level, real XP, plain difficulty words, one state vocabulary." } },
    { s = "chg", fr = { "Icônes", "Une icône a désormais un seul sens dans toutes les fenêtres ; les icônes décoratives sur les boutons sont retirées." }, en = { "Icons", "One meaning each, decorative ones removed." } },
    { s = "chg", fr = { "Bouton « Choisir les donjons »", "Dans le guide." }, en = { "\"Pick dungeons\" button in the guide.", "" } },
    { s = "fix", fr = { "Images des raids", "Onyxia, Hyjal et Barrow Deeps ont une image tirée du jeu." }, en = { "Raid cards get a picture from the game.", "" } },
    { s = "fix", fr = { "Icône de récompense", "Quand le serveur ne connaît pas le numéro donné par la base de quêtes." }, en = { "Reward icon fallback through LibForeverData.", "" } },
  } },
  { v = "1.0.0-beta.71", date = "2026-11-15", items = {
    { s = "add", fr = { "Prêt pour le donjon ?", "En haut du résumé, sous l'entrée : « Prêt : tu as les 7 quêtes à prendre dehors », ou « Il te manque 2 quêtes à prendre avant d'entrer » avec leurs noms (survol : qui la donne et où ; clic : le GPS y va), celles qui attendent une autre quête ou un niveau, et combien se prennent dans le donjon. Chaque carte dit aussi « À prendre » ou « Dans le donjon »." }, en = { "Ready to go in? The summary says whether every quest to pick up outside is in your log, and which are missing.", "" } },
    { s = "add", fr = { "Artisans en haut des commandes", "Dans un métier, une ligne de pastilles sous son nom (« Fallanx · 38 », point vert en ligne) ; un clic ouvre ses recettes ; ceux qui n'ont rien partagé sont en gris avec l'explication au survol. La section du bas disparaît." }, en = { "Crafters shown as pills at the top of a profession's catalogue.", "" } },
    { s = "add", fr = { "Clic droit sur un portrait de boss", "Le marque tué ou pas tué, pour les boss que l'addon n'a pas vus mourir." }, en = { "Right-click a boss portrait to mark it killed or not.", "" } },
    { s = "fix", fr = { "Zul'Farrak", "Ukorz Sandscalp est le dernier boss, juste après Ruuzlu ; Velratha et Gahz'rilla passent avant." }, en = { "Zul'Farrak", "Ruuzlu and Chief Ukorz last." } },
    { s = "fix", fr = { "Boss morts non cochés", "Une mort se voit aussi sur la barre de nom du boss et, en fin de combat, sur les cibles du groupe." }, en = { "Boss kills also seen on nameplates and the group's targets.", "" } },
    { s = "fix", fr = { "Points d'interrogation à la place des récompenses", "Un objet connu seulement par son nom retrouve son numéro dans LibForeverData (vraie icône, qualité, comparaison)." }, en = { "Reward icons", "Names matched to item ids through LibForeverData." } },
    { s = "fix", fr = { "Commander", "Quand un seul artisan sait fabriquer l'objet, l'infobulle le dit simplement, sans la ligne Maj-clic." }, en = { "Order tooltip", "No shift-click line when only one crafter can make it." } },
    { s = "fix", fr = { "Étape « prêt ? » du guide", "Une quête qu'on rend dans le donjon compte aussi parmi celles à prendre avant d'entrer." }, en = { "The guide's ready step also counts quests turned in inside.", "" } },
  } },
  { v = "1.0.0-beta.70", date = "2026-11-15", items = {
    { s = "fix", fr = { "Marque sur le boss", "Un clic sur un portrait ciblait bien le boss mais ne posait pas la marque. La marque passe maintenant par la commande du jeu /tm, faite pour les macros (le script utilisé avant est bloqué sur ce client). Pareil pour le bouton de ciblage du guide et sa touche." }, en = { "Boss mark", "Clicking a portrait now also puts the marker on (game /tm command instead of a blocked script)." } },
  } },
  { v = "1.0.0-beta.69", date = "2026-11-15", items = {
    { s = "add", fr = { "Recherche dans le choix des donjons", "Tape un nom de donjon (ou ZF, BRD, SM), une zone, une quête ou la personne qui la donne ; la recherche couvre tous les onglets et tous les niveaux, sans tenir compte des accents." }, en = { "Search box in the dungeon picker", "Dungeon, short name, zone, quest or quest giver, across every tab and level." } },
    { s = "add", fr = { "Guide d'un donjon déjà fini", "Quand toutes ses quêtes sont rendues, le résumé propose « Me guider dans le donjon » : trajet jusqu'à l'entrée, puis boss par boss (tactiques, butin) jusqu'au dernier. Une route de quêtes s'arrête toujours une fois les quêtes finies." }, en = { "Guide me through the dungeon even when every quest is turned in: entrance, then boss by boss.", "" } },
    { s = "add", fr = { "Objets en récompense dans le résumé", "Jusqu'à 4 icônes par quête, avec la flèche verte et le pourcentage d'amélioration calculés au niveau de la quête ; le meilleur choix est entouré en or ; le total dit « 3 objets dont 2 améliorations »." }, en = { "Reward items in the summary with upgrade arrows and the best choice ringed in gold.", "" } },
    { s = "add", fr = { "Clic droit simple = baguette", "Pour les mages, prêtres et démonistes (ou toute classe avec une baguette), un clic droit seul sur un ennemi lance Tir. Proposé à l'accueil quand tu actives le tir, réglable dans Réglages › Général › Clics." }, en = { "Plain right-click = wand, offered to wand classes, in Settings too.", "" } },
    { s = "fix", fr = { "Zul'Farrak", "Theka le Martyr passe avant Antu'sul dans la visite boss par boss." }, en = { "Zul'Farrak", "Theka the Martyr now comes before Antu'sul." } },
    { s = "fix", fr = { "Fenêtre des boss", "Un boss mort ou hors de vue ne remplace plus son portrait par un rond blanc." }, en = { "Boss panel", "No more white disc portraits from dead or unseen bosses." } },
  } },
  { v = "1.0.0-beta.68", date = "2026-11-15", items = {
    { s = "add", fr = { "Quoi de neuf", "Après chaque mise à jour, une fenêtre liste une fois ce qui a changé depuis la version que tu avais (que l'addon ait été mis à jour par WowUp, CurseForge ou à la main). /wlh nouveautes la rouvre." }, en = { "What's new", "After each update a window lists the changes since your last version, once; /wlh news reopens it." } },
  } },
  { v = "1.0.0-beta.67", date = "2026-11-15", items = {
    { s = "fix", fr = { "Clic sur un portrait de boss sans effet", "Le portrait réagit maintenant à l'appui comme au relâchement, comme les boutons de téléportation et du guide qui marchent sur ce client. Si le boss n'est pas ciblé après le clic, un message le dit dans le chat avec le nom cherché." }, en = { "Boss portraits", "Click now registered like the working buttons; a chat line says when the boss was not targeted." } },
  } },
  { v = "1.0.0-beta.66", date = "2026-11-15", items = {
    { s = "fix", fr = { "Fenêtre des boss", "Les portraits sont rognés et découpés en rond pour que leur bord gris ne dépasse plus ; plus d'icône décorative à côté du nom du donjon." }, en = { "Boss panel", "Portraits cropped round, no decorative header icon." } },
  } },
  { v = "1.0.0-beta.65", date = "2026-11-15", items = {
    { s = "fix", fr = { "Fenêtre des boss", "Plus de croissant gris à droite des portraits (l'anneau n'est gardé que pour les rares, en argent) ; le survol éclaircit doucement au lieu de blanchir le portrait ; la fenêtre se place par défaut en haut à droite de l'écran (comme le minuteur Mythique+), l'épingle la colle au guide si tu préfères." }, en = { "Boss panel", "No grey crescents, softer hover, top-right by default." } },
  } },
  { v = "1.0.0-beta.64", date = "2026-11-15", items = {
    { s = "chg", fr = { "Fenêtre des boss façon Dungeon Journal", "En haut, la sortie en cours (Temps, XP, Or) avec « Nouveau run » ; puis les boss en **portraits ronds**, 5 par ligne, dans l'ordre du donjon (tués : grisés avec une coche) ; puis les **Rares** en silhouettes grises tant que tu ne les as pas vus, en couleur avec un anneau argenté ensuite. Chaque créature a un vrai visage (modèle du jeu, portrait vu en jeu, ou icône de sa famille). Un clic sur un portrait le cible et le marque. /wlh boss." }, en = { "Boss panel like Dungeon Journal", "Run stats, round portraits, rares greyed until seen." } },
    { s = "chg", fr = { "Bilan de sortie", "En quittant le donjon, une ligne dans le chat (« Zul'Farrak : 32 min · 38 200 XP · 12 po · 7/7 boss »)." }, en = { "", "" } },
  } },
  { v = "1.0.0-beta.63", date = "2026-11-15", items = {
    { s = "chg", fr = { "Résumé du donjon plus lisible", "Bouton **« Lancer la route »** en bas à droite (ou « Mettre à jour la route » / « Retour à la route » quand une route tourne déjà) ; les quêtes déjà rendues sont repliées en bas ; quand tout est fait, « Tu as déjà rendu toutes les quêtes de … » avec « Choisir un autre donjon » ; une ligne par quête avec niveau, XP et argent ; le total de ta sélection en haut." }, en = { "Clearer dungeon summary with a Start the route button.", "" } },
    { s = "chg", fr = { "Vue groupe", "Des colonnes seulement pour les membres dont on connaît l'état (WL Helper ou réponse au partage), une icône par case ; les autres en une ligne « Sans WL Helper : … »." }, en = { "", "" } },
  } },
  { v = "1.0.0-beta.62", date = "2026-11-15", items = {
    { s = "add", fr = { "Visite du donjon boss par boss", "Dans le donjon, une étape par boss dans l'ordre (« Boss 3 sur 7 · Glutton »), avec les objectifs de quête qui s'y rattachent, la tactique (conseils de Naowh lus en direct quand il est installé, sinon nos notes), le chemin et le butin intéressant pour toi (flèche verte et %). L'étape passe toute seule quand le boss meurt (fin de rencontre ou cible morte) et que ses objectifs sont faits ; les boss facultatifs sont passés quand tu avances. Les morts sont gardées pour la sortie en cours (un retour rapide après une mort ne remet rien à zéro)." }, en = { "Dungeon walkthrough boss by boss, auto-advance on kill.", "" } },
    { s = "add", fr = { "Plusieurs spés dans l'infobulle", "Réglages › Améliorations › « Spés à comparer » ; une ligne par spé (« Protection +6 % », « Fureur −3 % »), et la flèche des sacs au choix pour ta spé principale ou n'importe laquelle." }, en = { "Several specs in the upgrade tooltip.", "" } },
  } },
  { v = "1.0.0-beta.61", date = "2026-11-15", items = {
    { s = "chg", fr = { "Le petit suivi est désactivé par défaut", "Le guide et son bouton « – » (mode réduit) suffisent. Pour le retrouver : /wlh suivi." }, en = { "The small tracker is now opt-in (/wlh suivi).", "" } },
  } },
}
