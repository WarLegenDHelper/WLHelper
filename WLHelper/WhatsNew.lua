-- WhatsNew.lua: generated from CHANGELOG.md by the release (make_whatsnew.py; do not edit by hand).
-- Per version: v, date, items = { { s = "add"|"chg"|"fix", fr = { title, text }, en = { title, text } } }
local _, ns = ...
ns.WHATSNEW = {
  { v = "1.0.0-beta.185", date = "2026-11-20", items = {
    { s = "chg", fr = { "Le guide n'a plus qu'une vue : la vue moderne.", "La grande fenêtre du guide ne s'ouvre plus, et tout ce qu'elle faisait passe par la vue moderne :" }, en = { "", "" } },
    { s = "chg", fr = { "", "la check-list ;" }, en = { "", "" } },
    { s = "chg", fr = { "", "les actions (recommencer la route, flèche GPS, raccourcis) ;" }, en = { "", "" } },
    { s = "chg", fr = { "", "la vue d'ensemble, les boss, la carte, le partage. /wlh guide, le bouton de la minicarte, l'accueil et le hub ouvrent la vue moderne, ou le choix de guide quand aucun guide n'est en cours. Le réglage « Vue moderne par défaut » disparaît." }, en = { "The guide has one view now", "The modern view. The old window never opens." } },
    { s = "fix", fr = { "WL Helper ne détourne plus les repères de Zygor", "Quand un de ces addons de guide est chargé, notre GPS ne suit plus les repères posés sur la carte, et WL Helper ne prend plus la commande /way. Tu peux remettre le suivi des repères dans les réglages du GPS (« Suivre les repères de la carte »)." }, en = { "WL Helper no longer takes over Zygor's or RestedXP's map pins and /way.", "" } },
  } },
  { v = "1.0.0-beta.184", date = "2026-11-20", items = {
    { s = "add", fr = { "Meilleur équipement, où trouver le patron", "Une pièce fabriquée dit où trouver son patron et le niveau de métier qu'il faut (« Patron : chez Qia (Berceau-de-l'Hiver) · métier 215 », « Patron : lâché par Pyromancien de Brandefeu · métier 295 », « butin aléatoire dans le monde », une quête, ou ton maître de métier). L'information vient du module Métiers de Naowh, lu en direct." }, en = { "Best gear", "Where to find a crafted piece's pattern, and the skill it needs." } },
    { s = "fix", fr = { "Meilleur équipement, des noms au lieu de numéros", "Une pièce que le jeu n'avait pas encore chargée s'affichait avec son numéro (« 18727 »). La fenêtre demande maintenant l'objet au jeu et se redessine dès qu'il arrive." }, en = { "Best gear", "Item names instead of numbers." } },
    { s = "fix", fr = { "« N choix » en gris", "Au lieu de rouge." }, en = { "\"N picks\" in grey, not red.", "" } },
  } },
  { v = "1.0.0-beta.183", date = "2026-11-20", items = {
    { s = "chg", fr = { "Vue moderne, les dernières actions de la grande fenêtre", "Son menu (roue dentée) a maintenant « Recommencer la route » (dans Guides, avec confirmation), « Flèche GPS » et « Raccourcis clavier » (dans Affichage). Tout ce que faisait le menu Actions de la grande fenêtre se fait désormais depuis la vue moderne." }, en = { "Modern view menu", "Restart the route, GPS arrow on/off, key bindings." } },
  } },
  { v = "1.0.0-beta.182", date = "2026-11-20", items = {
    { s = "chg", fr = { "La check-list dans la vue moderne", "Le lien « Check-list », sous la vue moderne et dans son menu, amène sur l'étape d'entrée du donjon dans la vue moderne elle-même, sans ouvrir la grande fenêtre. On y voit :" }, en = { "", "" } },
    { s = "chg", fr = { "", "l'état (« Prêt pour Profondeurs de Rochenoire », « Pas encore prêt : 2 quêtes à prendre », « Quêtes prises, mais pas la clé ») ;" }, en = { "", "" } },
    { s = "chg", fr = { "", "chaque quête à avoir prise avant d'entrer, marquée « Prise », « À prendre » ou « Facultative » ;" }, en = { "", "" } },
    { s = "chg", fr = { "", "la clé, s'il en faut une. Comme pour les flèches, on revient tout seul à l'étape en cours." }, en = { "The checklist is shown in the modern view itself", "State, each quest (taken / to take / optional), the key." } },
  } },
  { v = "1.0.0-beta.181", date = "2026-11-20", items = {
    { s = "fix", fr = { "Erreur « action bloquée » en combat avec la vue moderne", "») : la barre Cibler / objet de quête était accrochée à la vue moderne, ce qui la rendait protégée en combat. La vue ne pouvait plus changer de taille. La barre est maintenant placée sur l'écran, au même endroit." }, en = { "Modern view", "No more blocked-action error in combat (the target bar no longer anchors to it)." } },
  } },
  { v = "1.0.0-beta.180", date = "2026-11-20", items = {
    { s = "fix", fr = { "La check-list est de retour dans la vue moderne", "Elle vérifie que tu as bien pris toutes les quêtes à prendre avant d'entrer, et la clé s'il en faut une. Elle n'était qu'en bas de la grande fenêtre du guide, que la vue moderne remplace par défaut, et plus personne ne la trouvait. Un lien « Check-list » est maintenant sous la vue moderne et dans son menu (Ce donjon). Il ouvre le guide directement sur elle." }, en = { "The checklist is back in the modern view", "A link under it and in its menu." } },
    { s = "fix", fr = { "Vue moderne, bas de cadre plus calme", "Les liens du bas (Guides, Check-list, Vue d'ensemble, Boss, Carte, Partager) sont en gris clair, blancs au survol, au lieu d'être tous en rouge. Le carré devant « Toutes les étapes » était un caractère que la police du jeu n'affiche pas : c'est maintenant une vraie flèche." }, en = { "Modern view", "Quiet grey links instead of red; the square before \"All the steps\" is now an arrow icon." } },
  } },
  { v = "1.0.0-beta.179", date = "2026-11-20", items = {
    { s = "add", fr = { "Le butin de chaque boss, dans tous les donjons", "À chaque étape de boss, le bloc « Butin » du guide montre ce qui t'intéresse sur ce boss : ton BiS (badge BiS ou 2e choix de Naowh), tes améliorations (avec le gain), les objets de quête. Le taux de drop est affiché à côté (« 30 % de chance »). Avant, ce bloc n'avait des données que pour les Mortemines. Le butin et les taux viennent du Dungeon Journal de Naowh, lu en direct quand il est installé : rien n'est copié." }, en = { "Every dungeon boss's loot that matters to you (BiS, upgrades) with its drop chance, in the guide's boss steps, read live from Naowh's Dungeon Journal.", "" } },
    { s = "add", fr = { "Alerte quand ça tombe", "Quand un objet est jeté aux dés ou que tu ouvres un butin, un objet BiS (ou 2e choix) pour ta spé, ou une amélioration, déclenche une alerte en haut de l'écran, une ligne dans la discussion et un son (« Ton BiS est tombé ! [Spritecaster Cape] »)." }, en = { "A toast, a chat line and a sound when a BiS or an upgrade drops.", "" } },
  } },
  { v = "1.0.0-beta.178", date = "2026-11-20", items = {
    { s = "chg", fr = { "Pourcentages d'amélioration et Meilleur équipement à jour avec Geared Forever 1.2", "WL Helper Gear (1.5.0) reprend la nouvelle version de Nathan. Les poids de stats de chaque classe et spé ont été revérifiés avec les guides : au niveau 60, les soigneurs suivent l'ordre des guides (paladin Sacré, prêtres, chamans et druides Restauration), l'Intelligence du paladin compte un peu plus, l'expertise passe juste sous le toucher (au-dessus pour les voleurs), les tanks guerrier et paladin comptent plus la menace et un peu moins la défense, et la Maîtrise des bêtes compte l'Intelligence comme puissance d'attaque (Visée prudente, lue dans tes talents). Les chasseurs ne se voient plus proposer d'armes de jet. La liste des objets vient de la 1.2 (9 685 objets, nouvelles sources de quêtes)." }, en = { "Gear scores updated to Geared Forever 1.2", "Stat weights rechecked for every spec (level 60 order for healers, Paladin Intellect, expertise vs hit, Protection threat and defense, Beast Mastery Careful Aim), no thrown weapons for hunters, 1.2 item and quest data." } },
  } },
  { v = "1.0.0-beta.177", date = "2026-11-20", items = {
    { s = "add", fr = { "Trouver un groupe, un clic suffit", "Un clic sur la ligne d'un groupe envoie au chef un message tout prêt, avec ta classe, ton niveau, ton rôle, le donjon et les quêtes que tu peux partager (« Salut ! Mage niv. 53 (DPS), dispo pour Profondeurs de Rochenoire. J'ai les quêtes Le dernier élément, La révolte des machines +3 à partager. Tu as une place ? »). Maj-clic ouvre ce message dans la discussion pour le modifier avant de l'envoyer. Sur la ligne d'un joueur seul, le clic l'invite avec « Salut ! Tu veux faire Profondeurs de Rochenoire avec nous ? Je t'invite. »." }, en = { "Find a group", "One click on a line sends a ready whisper (class, level, role, dungeon, quests to share); Shift-click to edit it; a lone player is invited with a question about the activity." } },
    { s = "add", fr = { "Filtre « Déjà dans le groupe »", "N'affiche que les groupes qui ont déjà un tank, un soigneur ou des DPS." }, en = { "Filter", "Groups that already have a tank or a healer." } },
    { s = "chg", fr = { "Niveau requis bien visible", "Une quête que tu ne peux pas encore prendre le dit en rouge, sur sa propre ligne et en premier (« Pas encore pour toi : niveau 55 requis, tu es niveau 53. Passe cette étape (Maj-clic) et reviens plus tard. »). La mention inutile « aucun prérequis » disparaît." }, en = { "A quest you cannot take yet says so first, in red, on its own line.", "" } },
  } },
  { v = "1.0.0-beta.176", date = "2026-11-20", items = {
    { s = "fix", fr = { "Objectifs placés au mauvais endroit", "Vérification de tous les objectifs de donjon que les données plaçaient dehors, après « Le dernier élément ». 5 quêtes envoyaient au mauvais endroit :" }, en = { "", "" } },
    { s = "fix", fr = { "Ordre du chef de guerre", "Les documents importants de Rochenoire étaient placés dans les Carmines. Ils sont dans le Pic Rochenoire inférieur." }, en = { "", "" } },
    { s = "fix", fr = { "Sceau d'ascension (UBRS)", "Le sceau forgé était placé à Mille Pointes. Il s'obtient dans Rochenoire." }, en = { "", "" } },
    { s = "fix", fr = { "Gnomeregan", "L'objet incrusté de crasse tombe des « Caverndeep », qui sont dans le donjon." }, en = { "", "" } },
    { s = "fix", fr = { "Brassenoire", "Les saphirs d'Aku'Mai sont dans le donjon." }, en = { "", "" } },
    { s = "fix", fr = { "Libram (Hache-Tripes)", "Le diamant noir parfait n'a plus de point fixe dans la vallée d'Alterac. Il s'achète à l'hôtel des ventes ou tombe en donjon. Les autres objectifs « dehors » sont justes : Uldaman, Maraudon, Razorfen et les Cavernes des lamentations ont de vraies zones à l'extérieur du donjon." }, en = { "Five dungeon objectives were placed outside or in the wrong zone; fixed.", "" } },
  } },
  { v = "1.0.0-beta.175", date = "2026-11-20", items = {
    { s = "fix", fr = { "Le dernier élément (BRD)", "L'objectif envoyait dans la Gorge des Vents brûlants, sur « Scald », où il n'y a rien pour cette quête. Les Essences des éléments tombent des élémentaires et des golems dans les Profondeurs de Rochenoire : l'étape est maintenant dans le donjon." }, en = { "The Last Element", "The Essences drop inside Blackrock Depths, no more trip to Searing Gorge." } },
    { s = "fix", fr = { "Guide BRD qui envoyait à Stratholme", "« Le défi » (set de donjon 0.5, niveau 58, qui passe par Stratholme) ne fait plus partie du guide des Profondeurs de Rochenoire." }, en = { "The BRD guide no longer includes The Challenge (Dungeon Set 0.5) and its trip to Stratholme.", "" } },
    { s = "fix", fr = { "Tout cocher", "Le bouton ne coche plus les quêtes trop hautes pour toi, celles dont la chaîne monte 5 niveaux ou plus au-dessus du tien." }, en = { "Tick all leaves out the quests too high for you.", "" } },
  } },
  { v = "1.0.0-beta.174", date = "2026-11-20", items = {
    { s = "add", fr = { "Vue d'ensemble, Tout cocher / Tout décocher", "Un bouton en bas coche ou décoche d'un coup toutes les quêtes à faire. La route suit en une seule fois." }, en = { "Overview", "A \"Tick all / Untick all\" button." } },
    { s = "chg", fr = { "Choix de guide, un clic sur l'image choisit le donjon", "Cliquer sur la carte choisit le donjon, ou le retire. Le bouton en bas ouvre ensuite la vue d'ensemble des donjons choisis. « Vue d'ensemble », en haut de la carte, montre les quêtes d'un donjon, et le clic droit aussi. « + Ajouter » marche toujours." }, en = { "Guide picker", "Clicking a card picks the dungeon; \"Overview\" at the top shows its quests." } },
  } },
  { v = "1.0.0-beta.173", date = "2026-11-19", items = {
    { s = "chg", fr = { "Nouvel Accueil, une grande carte par activité", "Finie la grille de petites icônes. L'Accueil montre 6 cartes, rangées selon ce que tu veux faire :" }, en = { "", "" } },
    { s = "chg", fr = { "Progresser", "Guide de quêtes, Meilleur équipement, Améliorations, Passeport des clés, Tri du journal ;" }, en = { "", "" } },
    { s = "chg", fr = { "PvP", "Les champs de bataille ;" }, en = { "", "" } },
    { s = "chg", fr = { "Argent et métiers", "Writs, Faveur, Commandes, Sacs ;" }, en = { "", "" } },
    { s = "chg", fr = { "Guilde et groupes", "Guilde, Groupes, Quêtes en commun ;" }, en = { "", "" } },
    { s = "chg", fr = { "Voyager", "Aller à, Tournée en ville ;" }, en = { "", "" } },
    { s = "chg", fr = { "Aide et retours", "Nous écrire, Rapports des joueurs. Chaque carte dit en une phrase où tu en es (« Guide BRD, étape 3 sur 133 », « 2 Writs prêts à rendre ») et a un bouton pour continuer. Les fenêtres du groupe sont listées dessous. Le clic droit ouvre toujours les réglages." }, en = { "New Home", "One large card per activity (Progress, PvP, Gold & crafting, Guild & groups, Travel, Help & feedback), each with where you stand and a button to carry on." } },
    { s = "chg", fr = { "Menu de gauche, même organisation", "Les réglages sont rangés dans les mêmes groupes que l'Accueil. Le PvP y a sa propre ligne, qui ouvre la fenêtre Champs de bataille." }, en = { "The left menu uses the same groups, and PvP has its own line.", "" } },
  } },
  { v = "1.0.0-beta.172", date = "2026-11-19", items = {
    { s = "add", fr = { "Noms des PNJ en français", "639 noms de PNJ et de monstres du guide s'affichent avec leur vrai nom français, celui du jeu (« Chef de guerre Goretooth » au lieu de « Warlord Goretooth »). Sur un client français, le bouton et la touche « Cibler » utilisent aussi le nom français : /targetexact ne trouvait pas les PNJ avec le nom anglais." }, en = { "French NPC names in the guide, and French names for targeting on a French client.", "" } },
    { s = "add", fr = { "Vue moderne, bouton Cibler", "La barre d'actions (cibler le PNJ ou le monstre, utiliser l'objet de quête) s'affiche aussi au-dessus de la vue moderne quand la grande fenêtre est fermée." }, en = { "Modern view", "The target and quest item bar now shows above it too." } },
    { s = "chg", fr = { "Vue moderne, menu rangé", "Le menu (roue dentée) est groupé en Étape, Ce donjon, Guides et Affichage. « Arrêter ce guide » est à part, en rouge." }, en = { "Modern view", "The menu is grouped; \"Stop this guide\" stands apart." } },
    { s = "chg", fr = { "Textes d'étape plus clairs", "" }, en = { "", "" } },
    { s = "chg", fr = { "", "le nom du PNJ ressort en blanc ;" }, en = { "", "" } },
    { s = "chg", fr = { "", "« à ton niveau » devient « difficulté normale » ;" }, en = { "", "" } },
    { s = "chg", fr = { "", "la ligne « partie 1 sur 1 de la suite » disparaît : elle ne disait rien." }, en = { "Clearer step texts", "The NPC stands out, \"normal difficulty\", no \"part 1 of 1\"." } },
    { s = "fix", fr = { "Vue moderne, étape passée", "Quand tu regardes une autre étape que l'étape en cours, un bandeau orange « ÉTAPE PASSÉE » ou « ÉTAPE À VENIR » le dit. Une action déjà faite y est marquée « Déjà fait : ». Une étape regardée puis laissée de côté revient toute seule à l'étape en cours au bout de 2 minutes. Avant, on pouvait suivre une étape passée sans s'en rendre compte, et aller reprendre une quête déjà dans son journal." }, en = { "Modern view", "A past or coming step is clearly marked, done actions say so, and it goes back to the current step after 2 minutes." } },
    { s = "fix", fr = { "Héritage Sombrefer (BRD)", "Le guide dit enfin que Franclorn Forgewright est un fantôme. Il faut être mort pour le voir et lui parler, dans la salle du Mont Rochenoire sur le chemin de BRD et du Cœur du Magma." }, en = { "Dark Iron Legacy", "Franclorn is a ghost, you must be dead to talk to him." } },
  } },
  { v = "1.0.0-beta.171", date = "2026-11-19", items = {
    { s = "chg", fr = { "Taille du guide à part", "La taille des fenêtres ne rapetisse plus le guide. Le guide, sa vue moderne et le panneau des boss ont leur propre réglage, « Taille du guide (%) », de 70 à 150. Ça se règle aussi avec /wlh taille guide 110." }, en = { "The guide has its own size; the window size no longer shrinks it.", "" } },
    { s = "chg", fr = { "Tailles, plus de curseur", "On tape le nombre (60 à 150) puis Entrée, ou on clique sur - et +. Le curseur faisait changer la fenêtre de taille sous la souris, et la valeur partait dans tous les sens." }, en = { "Sizes are typed or stepped with - and +, no more slider.", "" } },
    { s = "chg", fr = { "Vue moderne, comme RestedXP", "Un clic gauche sur une ligne passe à l'étape suivante, un clic droit revient à la précédente. Maj-clic marque toujours l'étape comme faite." }, en = { "Modern view", "Left click next step, right click previous step." } },
    { s = "chg", fr = { "Choix de guide, plus de case minuscule", "Un vrai bouton « + Ajouter » en haut à gauche de chaque carte, qui devient « Ajouté » quand le guide est dans la route." }, en = { "Guide picker", "A \"+ Add\" button instead of the tiny box." } },
    { s = "fix", fr = { "Chaîne d'Onyxia (Horde)", "« Blood and Thunder » explique comment obtenir « Ordre du chef de guerre ». Il faut accepter la quête, reparler à Goretooth et répondre à toutes ses questions. Il donne alors l'objet « Warlord Goretooth's Command » : on clique dessus dans les sacs pour démarrer la quête. Source : Wowhead Forever, commentaires de joueurs." }, en = { "Onyxia chain", "How to get Warlord's Command (answer Goretooth, then use his Command item)." } },
  } },
}
