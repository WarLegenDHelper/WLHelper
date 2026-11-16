# Changelog

Toutes les versions de WL Helper. Format : [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/),
numéros : [SemVer](https://semver.org/lang/fr/) (voir « Versions » dans le README).
*All WL Helper versions. Format: Keep a Changelog; numbers: SemVer (see "Versions" in the README).*

## [Unreleased]

## [1.0.0-beta.78] — 2026-11-16

### Corrigé / Fixed
- **Échap ne ferme plus le guide** : on le suit en jouant, il se ferme avec sa croix. Ça règle aussi pour de bon sa fermeture après un téléport.
  *Escape no longer closes the guide; close it with its X.*

## [1.0.0-beta.77] — 2026-11-16

### Corrigé / Fixed
- **Centaur Pariah (Maraudon)** : il fait des allers-retours sur le chemin au sud du Convent de Mannoroc. Le repère est maintenant au milieu de son trajet, et l'étape dit de suivre le chemin vers l'ouest s'il n'est pas là.
  *Centaur Pariah patrols: the marker is now mid-path, with a note to follow the path.*

## [1.0.0-beta.76] — 2026-11-16

### Corrigé / Fixed
- **« Le jeu a bloqué SetRaidTarget() »** : la macro « DG_Cible » créée par une ancienne version gardait sa ligne de marque de raid ; elle est nettoyée à la connexion et ne fait plus que cibler.
  *The old "DG_Cible" macro is cleaned at login: targeting only, no more blocked marker error.*

## [1.0.0-beta.75] — 2026-11-16

### Corrigé / Fixed
- **Le guide se fermait encore après un téléport** : le jeu ferme ses fenêtres avant que l'addon regarde si le guide était ouvert. Le moment de la fermeture est maintenant retenu : un guide ouvert revient après un téléport, un portail ou un /reload.
  *The guide no longer closes after a teleport, a portal or a /reload.*

## [1.0.0-beta.74] — 2026-11-16

### Ajouté / Added
- **Fenêtre WL Helper façon Naowh** (T-55) : une seule fenêtre avec, à gauche, une recherche et les activités (Quêtes & donjons, Objets & métiers, Guilde & groupes, Voyage) et leurs réglages ; à droite, l'accueil en deux colonnes. La minimap, /wlh et les boutons retour l'ouvrent sur la bonne page.
  *WL Helper hub like Naowh: one window, sidebar grouped by activity with search, Home in two columns, settings next to each activity.*
- **Chemin à pied comme Polestar** (T-43) : la flèche suit le vrai chemin, virage après virage, pour toutes les destinations ; la distance est celle qu'il reste à marcher ; des points sur la carte du monde et la minimap, une épingle sur l'endroit exact.
  *Walking path like Polestar for every destination, drawn on the map and minimap.*
- **La meilleure route** (T-44) : la pierre de foyer, le Rappel astral et Reflet-de-Lune comptent dans le calcul, avec les vrais temps à pied ; l'itinéraire complet s'affiche (« Pierre de foyer → vol jusqu'à Kargath → 300 m à pied »).
  *Best route: hearthstone and class teleports, real walking times, full itinerary.*
- **Repère dans le monde** (T-51) : une étiquette au-dessus de la destination (lieu, distance, temps restant), seulement si aucun autre addon ne le fait déjà. Réglages › GPS.
  *In-world marker over the destination, only when no other addon already shows one.*

### Modifié / Changed
- **Flèche GPS façon Zygor** (T-52) : en haut l'action (l'icône du sort ou de l'objet à cliquer pour un téléport ou la pierre de foyer), puis quoi faire, où, et « 550 m · 1:10 ».
  *GPS arrow organised like Zygor: clickable spell or item icon, what, where, distance and time.*
- **Carte de l'étape du guide refaite** (T-37, T-42) : l'action en titre, le lieu avec la distance, une ligne pour la chaîne, les détails repliés ; plus aucune info répétée. Une étape « prendre la quête » ne montre plus le texte de la quête comme si c'était à faire.
  *Guide step card rebuilt: action first, place and distance, folded details, nothing repeated.*
- **Noms** (T-38, T-39) : « Overview » / « Vue d'ensemble » et « Pick a guide » / « Choisir un guide ».
  *Names: Overview and Pick a guide.*
- **Commandes avec beaucoup d'artisans** (T-53) : au-delà de 8, une liste « Artisans : 3 en ligne · 24 en tout » avec recherche ; deux noms au plus sur les lignes d'objets.
  *Orders scale to many crafters: searchable list, two names per item row.*
- **Quoi de neuf** plus lisible (T-34), **Aller à…** avec distances en direct (T-36), bouton retour sur toutes les fenêtres (T-35).
  *Clearer What's new, live Go-to distances, back buttons everywhere.*
- **Interface et textes** revus fenêtre par fenêtre (T-21) : vocabulaire, niveaux, nombres, icônes.
  *Interface and texts reviewed window by window.*

### Corrigé / Fixed
- **Prérequis de quêtes** (T-45) : 169 liens entre maillons de chaîne ajoutés (LibForeverData, et Naowh pour les quêtes propres à Forever) ; Rot and Regret n'arrive plus avant Word of the Woods.
  *Quest prerequisites: 169 missing chain links added.*
- **Le guide se fermait** après un téléport ou un /reload (T-41).
  *The guide no longer closes after a loading screen.*
- **Marques de raid** (T-47) : le jeu ne laisse pas un addon poser une marque ; les boutons ciblent seulement, plus d'erreur.
  *Raid markers: targeting only, no more blocked-action error.*
- **Erreurs dans les donjons** (T-48) : valeurs cachées par le jeu (PNJ des caisses, alerte des rares).
  *Secret-value errors inside dungeons.*
- **Icônes de récompense** manquantes et améliorations plus lisibles (T-40).
  *Missing reward icons and clearer upgrades.*

## [1.0.0-beta.73] — 2026-11-16

### Corrigé / Fixed
- **Zygor** : la flèche de WL Helper ne prend plus la place de celle de ton guide Zygor. En « Automatique », c'est le GPS de WL Helper (avec son bouton pour l'arrêter) ; Zygor seulement si tu le choisis dans Réglages › GPS. Pour arrêter le GPS : `/wlh gps`.
  *WL Helper no longer takes over your Zygor guide's arrow; Zygor only when you pick it.*

## [1.0.0-beta.72] — 2026-11-16

### Ajouté / Added
- **Tournée en ville** (T-02) : en arrivant dans une capitale, une fiche liste ce qu'il y a à y faire (maître de classe, courrier, réparations, quêtes à rendre, composants à sortir de la banque pour une commande, achats des Writs, munitions) dans l'ordre de marche ; chaque tâche se coche toute seule et la flèche va de l'une à l'autre.
  *City tour: what to do in a capital, in walking order, ticked automatically.*
- **Passeport des clés** (T-03) : chaque clé ou accès (Scholomance, UBRS, Onyxia...) possédé, en cours (étape N sur M) ou pas commencé, avec « Guide-moi » ; onglet « Qui a la clé ? » dans la Guilde ; alerte sur un groupe si personne n'a la clé.
  *Key passport, who has the key in the guild, LFG warning.*
- **Quêtes en commun** (T-04) : les membres de la guilde qui ont les mêmes quêtes de donjon que toi, avec Grouper et Chuchoter.
  *Shared dungeon quests with guild members.*
- **Tri du journal** (T-05) : quand le journal est presque plein, des conseils d'abandon avec la raison ; les quêtes de tes donjons, de clés et de classe sont protégées.
  *Quest log triage when the log is nearly full.*
- **/way** (T-06) : « /wlway Tanaris 52,4 31,2 » envoie la flèche de WL Helper au point (et /way quand aucun autre addon ne l'a).
  *A /way point straight into WL Helper's arrow.*
- **Alt + clic dans les sacs** (T-07) : désenchanter (enchanteurs) et crocheter (voleurs) en un clic.
  *Alt-click to disenchant or pick a lock.*
- **Carte du donjon** (T-08) : un bouton dans la fenêtre des boss ouvre la meilleure carte installée (OpenMap, Naowh, FDJ, sinon la carte du monde).
  *Dungeon map button in the boss panel.*
- **Aller à…** (T-09) : cherche une destination (banque, HV, maître de classe, PNJ, zone, entrée de donjon) ; la flèche suit un vrai chemin à pied grâce à WLHelper_Nav, livré à côté (addon GPL séparé, tiré de Polestar Nav et de Shortest Path Forever, crédités).
  *Go to: search a destination, walking trail from WLHelper_Nav (shipped alongside, GPL).*
- **Classement PvP de la guilde** (T-11) : d'où viennent les victoires honorables (zones, champs de bataille) et un K/D/A en champ de bataille ; morts face aux joueurs en monde ouvert.
  *Guild PvP: where HKs come from, battleground K/D/A.*

### Modifié / Changed
- **Résumé du donjon refait** (T-01) : bannière « Conseillé niv. 38 à 48 · tu es niv. 41 », puis Entrée, Clé, Avant d'entrer et Tu gagnes ; sur chaque quête, la difficulté en mots, le niveau où elle se prend, l'XP que tu gagnes vraiment (réduite pour une quête grise) et une seule façon de dire son état.
  *Summary redesign: suggested level, real XP, plain difficulty words, one state vocabulary.*
- **Icônes** (T-10) : une icône a désormais un seul sens dans toutes les fenêtres ; les icônes décoratives sur les boutons sont retirées.
  *Icons: one meaning each, decorative ones removed.*
- **Bouton « Choisir les donjons »** (T-12) dans le guide.
  *"Pick dungeons" button in the guide.*

### Corrigé / Fixed
- **Images des raids** (T-13) : Onyxia, Hyjal et Barrow Deeps ont une image tirée du jeu.
  *Raid cards get a picture from the game.*
- **Icône de récompense** (T-14) quand le serveur ne connaît pas le numéro donné par la base de quêtes.
  *Reward icon fallback through LibForeverData.*

## [1.0.0-beta.71] — 2026-11-15

### Ajouté / Added
- **Prêt pour le donjon ?** En haut du résumé, sous l'entrée : « Prêt : tu as les 7 quêtes à prendre dehors », ou « Il te manque 2 quêtes à prendre avant d'entrer » avec leurs noms (survol : qui la donne et où ; clic : le GPS y va), celles qui attendent une autre quête ou un niveau, et combien se prennent dans le donjon. Chaque carte dit aussi « À prendre » ou « Dans le donjon ».
  *Ready to go in? The summary says whether every quest to pick up outside is in your log, and which are missing.*
- **Artisans en haut des commandes** : dans un métier, une ligne de pastilles sous son nom (« Fallanx · 38 », point vert en ligne) ; un clic ouvre ses recettes ; ceux qui n'ont rien partagé sont en gris avec l'explication au survol. La section du bas disparaît.
  *Crafters shown as pills at the top of a profession's catalogue.*
- **Clic droit sur un portrait de boss** : le marque tué ou pas tué, pour les boss que l'addon n'a pas vus mourir.
  *Right-click a boss portrait to mark it killed or not.*

### Corrigé / Fixed
- **Zul'Farrak** : Ukorz Sandscalp est le dernier boss, juste après Ruuzlu ; Velratha et Gahz'rilla passent avant.
  *Zul'Farrak: Ruuzlu and Chief Ukorz last.*
- **Boss morts non cochés** (Nekrum, Sezz'ziz, Bly) : une mort se voit aussi sur la barre de nom du boss et, en fin de combat, sur les cibles du groupe.
  *Boss kills also seen on nameplates and the group's targets.*
- **Points d'interrogation à la place des récompenses** : un objet connu seulement par son nom retrouve son numéro dans LibForeverData (vraie icône, qualité, comparaison).
  *Reward icons: names matched to item ids through LibForeverData.*
- **Commander** : quand un seul artisan sait fabriquer l'objet, l'infobulle le dit simplement, sans la ligne Maj-clic.
  *Order tooltip: no shift-click line when only one crafter can make it.*
- **Étape « prêt ? » du guide** : une quête qu'on rend dans le donjon compte aussi parmi celles à prendre avant d'entrer.
  *The guide's ready step also counts quests turned in inside.*

## [1.0.0-beta.70] — 2026-11-15

### Corrigé / Fixed
- **Marque sur le boss** : un clic sur un portrait ciblait bien le boss mais ne posait pas la marque. La marque passe maintenant par la commande du jeu /tm, faite pour les macros (le script utilisé avant est bloqué sur ce client). Pareil pour le bouton de ciblage du guide et sa touche.
  *Boss mark: clicking a portrait now also puts the marker on (game /tm command instead of a blocked script).*

## [1.0.0-beta.69] — 2026-11-15

### Ajouté / Added
- **Recherche dans le choix des donjons** : tape un nom de donjon (ou ZF, BRD, SM), une zone, une quête ou la personne qui la donne ; la recherche couvre tous les onglets et tous les niveaux, sans tenir compte des accents.
  *Search box in the dungeon picker: dungeon, short name, zone, quest or quest giver, across every tab and level.*
- **Guide d'un donjon déjà fini** : quand toutes ses quêtes sont rendues, le résumé propose « Me guider dans le donjon » : trajet jusqu'à l'entrée, puis boss par boss (tactiques, butin) jusqu'au dernier. Une route de quêtes s'arrête toujours une fois les quêtes finies.
  *Guide me through the dungeon even when every quest is turned in: entrance, then boss by boss.*
- **Objets en récompense dans le résumé** : jusqu'à 4 icônes par quête, avec la flèche verte et le pourcentage d'amélioration calculés au niveau de la quête ; le meilleur choix est entouré en or ; le total dit « 3 objets dont 2 améliorations ».
  *Reward items in the summary with upgrade arrows and the best choice ringed in gold.*
- **Clic droit simple = baguette** : pour les mages, prêtres et démonistes (ou toute classe avec une baguette), un clic droit seul sur un ennemi lance Tir. Proposé à l'accueil quand tu actives le tir, réglable dans Réglages › Général › Clics.
  *Plain right-click = wand, offered to wand classes, in Settings too.*

### Corrigé / Fixed
- **Zul'Farrak** : Theka le Martyr passe avant Antu'sul dans la visite boss par boss.
  *Zul'Farrak: Theka the Martyr now comes before Antu'sul.*
- **Fenêtre des boss** : un boss mort ou hors de vue ne remplace plus son portrait par un rond blanc.
  *Boss panel: no more white disc portraits from dead or unseen bosses.*

## [1.0.0-beta.68] — 2026-11-15

### Ajouté / Added
- **Quoi de neuf** : après chaque mise à jour, une fenêtre liste une fois ce qui a changé depuis la version que tu avais (que l'addon ait été mis à jour par WowUp, CurseForge ou à la main). `/wlh nouveautes` la rouvre.
  *What's new: after each update a window lists the changes since your last version, once; /wlh news reopens it.*

## [1.0.0-beta.67] — 2026-11-15

### Corrigé / Fixed
- **Clic sur un portrait de boss sans effet** : le portrait réagit maintenant à l'appui comme au relâchement, comme les boutons de téléportation et du guide qui marchent sur ce client. Si le boss n'est pas ciblé après le clic, un message le dit dans le chat avec le nom cherché.
  *Boss portraits: click now registered like the working buttons; a chat line says when the boss was not targeted.*

## [1.0.0-beta.66] — 2026-11-15

### Corrigé / Fixed
- **Fenêtre des boss** : les portraits sont rognés et découpés en rond pour que leur bord gris ne dépasse plus ; plus d'icône décorative à côté du nom du donjon.
  *Boss panel: portraits cropped round, no decorative header icon.*

## [1.0.0-beta.65] — 2026-11-15

### Corrigé / Fixed
- **Fenêtre des boss** : plus de croissant gris à droite des portraits (l'anneau n'est gardé que pour les rares, en argent) ; le survol éclaircit doucement au lieu de blanchir le portrait ; la fenêtre se place par défaut en haut à droite de l'écran (comme le minuteur Mythique+), l'épingle la colle au guide si tu préfères.
  *Boss panel: no grey crescents, softer hover, top-right by default.*

## [1.0.0-beta.64] — 2026-11-15

### Modifié / Changed
- **Fenêtre des boss façon Dungeon Journal** : en haut, la sortie en cours (Temps, XP, Or) avec « Nouveau run » ; puis les boss en **portraits ronds**, 5 par ligne, dans l'ordre du donjon (tués : grisés avec une coche) ; puis les **Rares** en silhouettes grises tant que tu ne les as pas vus, en couleur avec un anneau argenté ensuite. Chaque créature a un vrai visage (modèle du jeu, portrait vu en jeu, ou icône de sa famille). Un clic sur un portrait le cible et le marque. `/wlh boss`.
  *Boss panel like Dungeon Journal: run stats, round portraits, rares greyed until seen.*
- **Bilan de sortie** : en quittant le donjon, une ligne dans le chat (« Zul'Farrak : 32 min · 38 200 XP · 12 po · 7/7 boss »).

## [1.0.0-beta.63] — 2026-11-15

### Modifié / Changed
- **Résumé du donjon plus lisible** : bouton **« Lancer la route »** en bas à droite (ou « Mettre à jour la route » / « Retour à la route » quand une route tourne déjà) ; les quêtes déjà rendues sont repliées en bas ; quand tout est fait, « Tu as déjà rendu toutes les quêtes de … » avec « Choisir un autre donjon » ; une ligne par quête avec niveau, XP et argent ; le total de ta sélection en haut.
  *Clearer dungeon summary with a Start the route button.*
- **Vue groupe** : des colonnes seulement pour les membres dont on connaît l'état (WL Helper ou réponse au partage), une icône par case ; les autres en une ligne « Sans WL Helper : … ».

## [1.0.0-beta.62] — 2026-11-15

### Ajouté / Added
- **Visite du donjon boss par boss** : dans le donjon, une étape par boss dans l'ordre (« Boss 3 sur 7 · Glutton »), avec les objectifs de quête qui s'y rattachent, la tactique (conseils de Naowh lus en direct quand il est installé, sinon nos notes), le chemin et le butin intéressant pour toi (flèche verte et %). L'étape passe toute seule quand le boss meurt (fin de rencontre ou cible morte) et que ses objectifs sont faits ; les boss facultatifs sont passés quand tu avances. Les morts sont gardées pour la sortie en cours (un retour rapide après une mort ne remet rien à zéro).
  *Dungeon walkthrough boss by boss, auto-advance on kill.*
- **Plusieurs spés dans l'infobulle** : Réglages › Améliorations › « Spés à comparer » ; une ligne par spé (« Protection +6 % », « Fureur −3 % »), et la flèche des sacs au choix pour ta spé principale ou n'importe laquelle.
  *Several specs in the upgrade tooltip.*

## [1.0.0-beta.61] — 2026-11-15

### Modifié / Changed
- **Le petit suivi est désactivé par défaut** : le guide et son bouton « – » (mode réduit) suffisent. Pour le retrouver : `/wlh suivi`.
  *The small tracker is now opt-in (/wlh suivi).*

## [1.0.0-beta.60] — 2026-11-15

### Corrigé / Fixed
- **« Me guider dans le donjon »** : le choix des donjons se ferme et le résumé s'ouvre à sa place (il restait ouvert par-dessus).
  *The dungeon picker closes when the summary opens.*

## [1.0.0-beta.59] — 2026-11-15

### Ajouté / Added
- **Têtes des boss à côté du guide** (façon Dungeon Journal) : une petite colonne de portraits à droite, les boss dans l'ordre du donjon puis les rares (cadre argenté, grisés tant que tu ne les as pas vus) ; un clic sur une tête la cible et la marque (crâne pour un boss, étoile pour un rare) ; les boss tués sont grisés avec une coche. Déplaçable, repliable.
  *Boss heads beside the guide: click a head to target and mark it.*
- **Alerte des rares**, partout : son et bandeau « Rare : Nom (niv. N) » avec un bouton pour le cibler et le marquer (hors combat), au plus une fois toutes les 10 minutes par rare.
  *Rare alert with a target-and-mark button.*

### Modifié / Changed
- **Guide compact dans les donjons** : le bandeau « Dans le donjon » tient sur une ligne et les descriptions sont raccourcies (le détail dans l'infobulle).
- **Petit suivi replié** : il affiche l'action à faire maintenant au lieu du seul titre du chapitre, et son infobulle explique ce qu'il est.

## [1.0.0-beta.58] — 2026-11-15

### Modifié / Changed
- **Nouvel écran de bienvenue**, en 4 ou 5 étapes courtes avec points de progression, Retour et Passer : à quoi sert WL Helper ; les modules qui t'intéressent (cartes avec icône et une ligne, interrupteur) ; ta spé (seulement si le jeu ne la donne pas) ; le confort (clics éteints par défaut, avertissement pour les chasseurs) ; « C'est prêt » avec de gros boutons pour démarrer et où tout retrouver. `/wlh setup` le rouvre.
  *New welcome flow: short steps, modules, spec, comfort, ready.*

## [1.0.0-beta.57] — 2026-11-15

### Corrigé / Fixed
- **Erreur « forbidden object » (Upgrades.lua)** avec EllesmereUI : la recherche des boutons de sac ne touche plus les cadres protégés des autres addons.
  *Upgrades: no more "forbidden object" error when scanning bag buttons.*
- **Tu n'apparais plus dans « membres sans la quête »**, quelle que soit la forme de ton nom (avec ou sans royaume).

## [1.0.0-beta.56] — 2026-11-15

### Ajouté / Added
- **Résumé du donjon** au lancement d'une route : une case par quête avec l'XP de la quête, l'XP de toute sa chaîne, l'argent, les objets en récompense et les pastilles Élite, Chaîne, Autre donjon, Niveau trop haut ; le total de ta sélection se met à jour en direct ; « Lancer la route » construit le guide avec ce que tu as coché.
  *Dungeon summary: tick quests and chains with their XP, rewards and warnings.*
- **Vue groupe** dans le résumé : qui a chaque quête, qui l'a finie, qui doit la prendre, quel prérequis manque ; « Partager » par quête et « Tout partager ».
  *Group view: who has what, missing prerequisites, share buttons.*

### Modifié / Changed
- **Carte d'étape** : une seule action en grand (icône, verbe, quête, PNJ et lieu, objectifs, position dans la chaîne), puis « Ensuite chez <PNJ> » en petit. Fini les longues descriptions répétées.
  *Step card: one current action, the rest in a short list.*
- **Objectifs et texte du jeu** affichés pour les quêtes de ton journal (« Ancient Mana Crystal : 0/8 »), note de ForeverDungeonJournal quand il est activé, et d'où vient la flèche (« La flèche suit la zone de quête du jeu »).
- **Infobulle d'étape** réorganisée en blocs, sans doublons ; **panneau Étapes** ouvert du côté où il y a de la place.
- **En-têtes** : logo seulement sur l'accueil ; ailleurs une flèche retour. Le bouton « Donjons » remplace l'icône incomprise.
- **Texte coupé** : une seule mesure de texte fiable partout.

## [1.0.0-beta.55] — 2026-11-15

### Modifié / Changed
- **Accueil** : le bandeau du haut ne répète plus la prochaine étape du guide (la carte « Guide de quêtes » la montre déjà) ; il ne sert qu'à ce qui attend vraiment ailleurs (commande à répondre, Writs prêts, enveloppes, événement qui commence).
  *Home: the top strip no longer repeats the quest guide's next step.*

## [1.0.0-beta.54] — 2026-11-15

### Modifié / Changed
- **Infobulles** : les lignes « Clic : … » sont en gris-bleu discret au lieu du rouge, qui faisait penser à une alerte.
  *Click hints in tooltips are a calm grey-blue instead of red.*

## [1.0.0-beta.53] — 2026-11-15

### Ajouté / Added
- **Quêtes récentes de Forever mieux guidées** : 55 quêtes des routes (chaînes de Shen'dralas et des pylônes, Krol'dok, Riverglades, prison d'Alcaz, Drowned City, Legashi, Blackmaw, Ruins of Lordaeron, Dalaran…) ont maintenant une marche à suivre en étapes, et leurs objectifs un point sur la carte quand on le connaît. Infos tirées de Wowhead Forever, réécrites, en français et en anglais.
  *55 recent Forever quests get how-to notes and objective places.*
- **`/wlh diag`** : enregistre ce que le client propose aux addons (talents, quêtes, carte, métiers…) pour nous aider à corriger les bugs sans te faire taper de commandes.

## [1.0.0-beta.52] — 2026-11-15

### Corrigé / Fixed
- **Spé mal détectée** (un guerrier Protection vu en Armes, un mage Givre vu en Arcanes par hasard) : Forever range les talents dans le système moderne ; WL Helper y lit maintenant les points dépensés par arbre. Si la spé ne peut pas être lue, l'infobulle l'indique (« spé à choisir ») et un message dit où la régler, au lieu de supposer la première.
  *Spec read from Forever's modern talent system; a guessed spec is now flagged.*
- **Powering the Pylons** : la marche à suivre (Tamis à mana au dernier étage du temple, 8 de mana sur les orbes arcaniques, 4 de mana par pylône en 43, 35 et 73, 24).

## [1.0.0-beta.51] — 2026-11-15

### Corrigé / Fixed
- **Flèche GPS cachée sous les cadres de personnage** (EllesmereUI et autres) : elle passe au-dessus, avec son bouton de téléportation.
  *The GPS arrow now draws above unit frames.*

## [1.0.0-beta.50] — 2026-11-15

### Corrigé / Fixed
- **Un seul affichage à la fois** : le petit suivi s'efface quand la grande fenêtre du guide est ouverte, et revient quand tu la fermes.
  *The tracker hides while the big guide window is open.*
- **« Membres du groupe sans la quête »** ne te compte plus toi-même.

## [1.0.0-beta.49] — 2026-11-15

### Corrigé / Fixed
- **Chaînes : on voit où on en est.** Chaque étape d'un prérequis dit « Étape 3 sur 9 avant « Agamaggan's Blood » ».
  *Chain steps say where you are and what they lead to.*
- **Plus de rendu juste après la prise** pour les quêtes dont nos données n'ont que le texte (ex. Powering the Pylons) : une étape « objectifs » s'intercale et se coche quand le jeu dit la quête terminée. Les quêtes « va parler à… » n'en ont pas.
- **Sources de butin sur leur propre ligne** sous l'objectif (« Tombe sur : … »).

## [1.0.0-beta.48] — 2026-11-15

### Ajouté / Added
- **Suivi compact** à l'écran (façon RXP) : le chapitre en cours (« Avant le donjon : Uldaman 3/7 »), l'action à faire avec son icône (prendre, rendre, tuer, ramasser, utiliser, aller…), les barres de progression des objectifs et les 2 actions suivantes. Clic : ouvre le guide sur l'étape ; Maj-clic : marquer faite ; déplaçable, repliable. `/wlh suivi`.
  *Compact on-screen tracker with the chapter, the current action, objective bars and the next two actions.*
- **Trois chapitres par donjon** : Avant le donjon, Dans le donjon, Après le donjon, avec leur progression.
- **Vue d'ensemble du donjon** (depuis le choix des donjons et le guide) : image, niveaux, entrée avec GPS, clé, quêtes classées avant / dans / après, prérequis faits ou non, chaînes, niveau requis, et un interrupteur par quête pour la garder ou la retirer de la route.
  *Dungeon overview with prerequisites, chains and a per-quest switch.*
- **Boss et rares du donjon** (lus en direct dans LibForeverData) avec un bouton « Cibler et marquer ».
- **Partager les quêtes (n)** bien visible en groupe ; **raccourci clavier** « Cibler et marquer la cible de l'étape » (Échap › Options › Raccourcis › AddOns).

### Corrigé / Fixed
- **Objectifs suivis un par un** : l'étape passe à l'objectif suivant dès qu'un objectif est rempli.
- **Rendu placé avant les objectifs** (ex. Fragments of the Pylons) quand nos données ne connaissaient pas le lieu des objectifs : une étape d'objectifs est ajoutée, et la flèche suit la zone de quête du jeu.
  *A turn-in no longer comes before objectives whose place we did not know.*

## [1.0.0-beta.47] — 2026-11-15

### Corrigé / Fixed
- **Images manquantes dans le choix des donjons** (ailes du Monastère écarlate, Stratholme) : les images de ForeverDungeonJournal sont lues dès qu'il est installé, même désactivé ; sinon les ailes du Monastère prennent l'image du jeu.
  *Missing dungeon pictures (Scarlet Monastery wings, Stratholme).*

## [1.0.0-beta.46] — 2026-11-15

### Corrigé / Fixed
- **La flèche ne suivait pas un objectif rempli** quand la fenêtre du guide était fermée : l'étape et la flèche se mettent maintenant à jour même avec seulement la flèche à l'écran.
  *The arrow now moves on when an objective is done, even with the guide window closed.*

## [1.0.0-beta.45] — 2026-11-15

### Corrigé / Fixed
- **Flèche GPS : distance coupée** (« 4... m ») : le nombre est mesuré en entier, puis remesuré une fois la police chargée.
  *GPS arrow: the distance is no longer cut.*

## [1.0.0-beta.44] — 2026-11-15

### Modifié / Changed
- **Commandes, catalogue des métiers** : « Commander » passe la commande à **toute la guilde** (le premier artisan qui accepte s'en charge) ; Maj-clic pour la passer à un seul artisan. Les objets sont rangés comme dans la fenêtre de métier : catégories repliables (Armes, Armure par emplacement, Sacs, Consommables, Composants, Enchantements…), triés par niveau requis (« Niv. 24 ») puis par qualité.
  *Orders catalogue: Order goes to the whole guild; items grouped by category, sorted by level.*

## [1.0.0-beta.43] — 2026-11-15

### Corrigé / Fixed
- **Badges encore coupés** (« In... ») : leur largeur est mesurée avec la police exacte, puis remesurée une fois la police chargée.
  *Pills measured with their exact font: no more "In...".*

## [1.0.0-beta.42] — 2026-11-15

### Modifié / Changed
- **En-tête des fenêtres** : un seul bouton « ‹ + logo » pour revenir à l'accueil, à la place de la maison et du logo côte à côte.
  *Window header: one "< + logo" back button instead of a house icon next to the logo.*

### Corrigé / Fixed
- **Badges coupés** (« In progr... ») : ils prennent la largeur de leurs mots.
  *Pills are no longer cut.*

## [1.0.0-beta.41] — 2026-11-15

### Corrigé / Fixed
- **Guide : la route se réorganise toute seule.** Dès qu'une quête change d'état (objectifs finis, prise, rendue), la suite de la route est recalculée depuis ta position : un rendu tout proche qui débloque la quête suivante passe en premier au lieu d'un détour (ex. Les réactifs des Terres ingrates à Kargath avant Uldaman). Les étapes déjà faites restent visibles en haut. Pas pendant un combat ni dans un donjon.
  *Guide: the rest of the route is planned again from where you stand when a quest changes state.*

## [1.0.0-beta.40] — 2026-11-15

(La bêta.39 n'a pas été publiée : son numéro de version était faux.)

### Modifié / Changed
- **Refonte visuelle complète** : un guide de style commun (couleurs, tailles, espacements, boutons avec survol et appui, onglets, cartes, états vides), des icônes HD dessinées pour l'addon, des fenêtres qui s'ajustent à leur contenu, plus de texte coupé ni de traits colorés sur le côté, et tous les textes réécrits en contexte, en français et en anglais.
  *Full visual redesign: one design system, HD icons, windows sized to content, no cut text, every text rewritten.*
- **« Comment faire… ? »** remplace le guide de démarrage : une fiche par besoin avec les clics dans l'ordre, un bouton « Montre-moi » qui ouvre la bonne fenêtre et fait briller le bon bouton, une FAQ et les commandes.
  *"How do I...?" task guide with Show me buttons, FAQ and commands.*
- **Noms** : « Writs » et « LFG » partout.
- **WL Helper Gear v2** : effets « Chance au toucher » et « Utiliser : » comptés (Hand of Justice, Ironfoe, Earthstrike…), enchantements à effet (Crusader, Fiery…), bonus de set, plafonds de toucher donjon/raid, plafond de défense des tanks ; l'infobulle explique ce qui n'est pas compté.
  *Gear scoring v2: procs, use effects, proc enchants, set bonuses, hit and defense caps.*

### Ajouté / Added
- **`/wlh textes`** : liste les textes coupés dans les fenêtres ouvertes (pour nous aider à les corriger).

### Corrigé / Fixed
- **Prérequis des quêtes** vérifiés contre la base de Forever (234 quêtes) : chaîne manquante de Blackfathom Deeps ajoutée (Trouble in the Deeps), fausses étapes obligatoires retirées, classes, niveaux et faction corrigés. Le guide suit maintenant toute la chaîne, tient compte de ta faction et de ta race, et ne propose plus une quête dont un prérequis t'est impossible.
  *Quest prerequisites checked against Forever's data; the guide follows whole chains and respects faction and race.*

## [1.0.0-beta.38] — 2026-11-15

### Corrigé / Fixed
- **Améliorations : mauvaise spé avec WL Helper Gear** (un mage Givre jugé Arcane, d'où des % faux comme +88 %). Le sous-addon reçoit maintenant la spé que voit WL Helper (tes talents, ou ton choix dans Réglages › Améliorations).
  *Upgrades: WL Helper Gear now uses the spec WL Helper detects (a frost mage was judged as arcane).*

## [1.0.0-beta.37] — 2026-11-15

### Ajouté / Added
- **WL Helper Gear**, un sous-addon livré dans le même téléchargement : le moteur de calcul de Geared Forever (de Nathan, GPLv3, crédité), amélioré pour WL Helper. Il tient compte de ton vrai toucher (plafond), des talents que tu as vraiment pris et de l'enchantement de l'objet que tu portes. Les flèches et le % des Améliorations l'utilisent en premier ; Geared Forever n'est plus nécessaire.
  *WL Helper Gear sub-addon: Geared Forever's engine (by Nathan, GPLv3, credited) with real hit, talents and enchants; used first by Upgrades.*

## [1.0.0-beta.36] — 2026-11-15

### Ajouté / Added
- **Commandes, grille des métiers et catalogue de la guilde** : l'onglet Artisans s'ouvre sur une grille (une grande icône par métier, nombre d'artisans, d'objets, qui est en ligne). Un clic montre tout ce que la guilde sait fabriquer dans ce métier, avec qui peut le faire, une recherche, un filtre « en ligne » et un bouton « Demander ».
  *Orders: profession grid and the guild's craftable items per profession.*
- **Commandes, onglet « Demander »** : demande un objet par son nom ou un lien, choisis le métier (ou « je ne sais pas »), la quantité et le prix ; les artisans de ce métier reçoivent l'alerte, le premier qui accepte la prend. Compatible avec les anciennes versions.
  *Orders: a Request tab for any item, even one nobody has shared.*
- **Groupes, sélecteur de donjons en images** : « Choisir le donjon » ouvre de grandes cartes avec l'écran de chargement, le nom et les niveaux ; plusieurs choix possibles.
  *LFG: dungeon picker with loading-screen art, multi-select.*
- **Carte des vols** : un anneau doré qui pulse autour de la destination prévue, avec son nom.
  *Flight map: a pulsing ring on the planned landing.*
- **Guide, dans le donjon** : un bandeau « DANS LE DONJON : … » avec la progression des quêtes à l'intérieur et le boss suivant ; un clic ramène à l'étape du donjon.
  *Guide: a clear "inside the dungeon" band.*

### Modifié / Changed
- **Flèche GPS** redessinée en haute définition ; dorée, elle passe au vert quand tu es dans l'axe.
  *New HD GPS arrow.*
- **Distances en mètres et km** dans toutes les langues (yards en option dans Réglages › GPS).
  *Distances in meters and km everywhere; yards as an option.*
- **Bouton de téléportation** : il s'enfonce au clic, montre « Téléportation en cours » et une barre d'incantation, dit si c'est interrompu.
  *Teleport button: pressed look and cast progress.*
- **« Prêt ? » devient « Check-list »** avec une icône d'état et une explication claire de ce qui est vérifié.
  *"Ready?" is now a clear Checklist.*
- **Étapes terminées** : la liste des étapes est affichée par défaut, les étapes faites restent visibles et se rouvrent, même après la fin de la route.
  *Finished steps stay visible and can be reopened.*
- **Objectifs des quêtes** : le GPS suit la zone du jeu quand la quête est dans le journal ; progression « 2/5 » en direct.
- **Infobulles d'objet** : le bloc Geared Forever est masqué puisque notre ligne donne le même % (réglable).
  *Tooltips: Geared Forever's block hidden, our line shows the same %.*
- **Icônes plus nettes** un peu partout (icônes de classe et de rôle modernes, boutons de fermeture, coches).

## [1.0.0-beta.35] — 2026-11-15

### Ajouté / Added
- **Guide de démarrage** dans l'addon : une tuile sur l'accueil et `/wlh aide` présentent chaque module, avec un bouton pour l'ouvrir.
  *Quick start guide inside the addon (home tile, /wlh help).*
- **Sacs, « Libérer une place »** : quand les sacs sont pleins, un bandeau propose de jeter en un clic l'objet le moins cher (gris, ou arme et armure blanches ; rien d'autre). Chez un marchand il est vendu. Aussi `/wlh free`.
  *Bags: "Free a slot" throws away the cheapest junk in one click when the bags are full.*
- **Vente des objets gris** chez les marchands (réglable), sauf si EllesmereUI le fait déjà.
  *Grey items sold at merchants, unless EllesmereUI already does it.*
- **Accueil, « À faire maintenant »** : une ligne en haut avec la prochaine chose utile et son bouton.
  *Home: a "to do now" line with the next useful thing.*
- **Groupes** : récapitulatif à la connexion, rappel 1 h avant, bandeau d'invitation pour l'organisateur, acceptation automatique de l'invitation (réglable), annonce d'une annulation.
  *LFG: login recap, 1 h reminder, organizer banner, auto-accept, cancellation notice.*

### Modifié / Changed
- **Writs, onglet Achats** : une seule ligne par writ (l'enveloppe et son objet, prix additionnés ; le détail dans l'infobulle), un filtre par zone, des zones repliables d'un clic (« Exclure » est un bouton à part), « absent de l'HV », la monnaie dans la langue du jeu (20s / 40s / 1g en anglais), « Tout acheter à la suite ».
  *Writs Shopping tab: one line per writ, zone filter, foldable zones, money in the game's language, buy everything in a row.*
- **« Quêtes de donjon » devient « Guide de quêtes »** (donjons, raids, quêtes de classe).
  *"Dungeon quests" is now "Quest guide".*
- **Guide** : quand la quête est dans ton journal, le GPS suit la zone bleue du jeu pour les objectifs (Forever a déplacé certains monstres, comme les invocateurs de l'Orbe infernal du mage). Bouton « GPS » clair sur chaque étape, plus de traits de couleur sur le côté, flèche GPS plus propre. Check-list « Prêt ? » qui guide vers les donneurs de quêtes manquants, fin de route, entrée d'instance.
  *Guide: objectives follow the game's own quest area; clear GPS button; no side stripes; cleaner arrow; better ready check.*
- **Commandes** : icône et couleur de l'objet, « ce qu'il faut faire maintenant » sur chaque carte, composants en banque, « Acheter le manquant (n) » achète tout à la suite, « J'ai reçu », pourboire, livraison vue toute seule par les sacs ou l'échange, classe des artisans.
  *Orders: clearer cards, next step, bank reagents, buy all missing, receipt, automatic delivery.*
- **Guilde** : les anciens doublons du classement PvP (« Nom Royaume ») sont fusionnés ; le texte du bas ne déborde plus.
  *Guild: PvP ranking duplicates merged; bottom note fits.*
- **Améliorations et Nettoyeur** : flèche posée sur l'icône, spé affichée, objets que tu ne peux pas encore porter signalés ; le nettoyeur nomme l'objet qu'il va prendre.

### Corrigé / Fixed
- **Erreur « secret number » dans Route.lua** (temps de recharge des téléportations) : plus d'erreur en boucle.
  *Fixed the "secret number" error in Route.lua.*
- **Bouton de téléportation et « Ouvrir l'enveloppe »** : ils réagissent quel que soit le réglage « lancer à l'appui ».
  *Teleport and envelope buttons work with "cast on key down".*

## [1.0.0-beta.34] — 2026-11-15

### Ajouté / Added
- **Writs, zones à exclure** : dans Achats, un clic sur une zone (« À rendre en Les Paluns ») la laisse de côté, le plan prend d'autres writs, toujours les moins chers et le moins de zones ; les zones exclues restent en bas, un clic les remet.
  *Writs: click a zone in the Shopping tab to leave it out of the plan.*
- **Guilde, filtres par classe et par rôle** : les icônes officielles des classes et des rôles (tank, soins, dégâts, d'après la spé partagée par WL Helper ; un druide farouche compte comme tank et dégâts), et l'icône de classe devant chaque nom.
  *Guild: class and role filters with the game's icons; class icon on each member.*

## [1.0.0-beta.33] — 2026-11-15

### Modifié / Changed
- **Writs, onglet Achats : l'enveloppe et son objet d'un seul clic.** Un clic sur l'un ou l'autre ouvre la page d'achat de l'enveloppe ; dès que l'achat passe, celle de l'objet s'ouvre seule. Maj-clic envoie les deux à Auctionator.
  *Writs Shopping tab: one click buys the envelope then its item; shift-click sends both to Auctionator.*

## [1.0.0-beta.32] — 2026-11-15

### Modifié / Changed
- **Writs et Faveur du marchand séparés** : deux tuiles sur l'accueil et deux fenêtres. **Writs** (réputation avec Durotar Supply and Logistics : Aujourd'hui, Achats, Tous) et **Faveur du marchand** (les caisses). L'onglet Achats dit « Coût » puis « pour 29 writs, qui rapportent 3 025 points de réputation » au lieu de « +3025 rép ».
  *Writs and Merchant's Favor split into two tiles and two windows; clearer cost and reputation wording.*
- **Prix max pour 100 points de réputation** réglable dans Achats (20 pa, 40 pa, 1 po, sans) : le plan prend les writs les moins chers et le moins de zones possible sous ce plafond.
  *A price cap per 100 reputation in the Shopping tab.*
- **Commandes, le circuit de bout en bout** :
  - en commandant un objet (Maj-clic), les **artisans possibles** : recette connue, ou métier compatible avec le type d'objet (potion → Alchimie, tissu → Couture, plaque → Forge...), en ligne d'abord, avec leurs étoiles ; « À lui » pour lui commander directement ;
  - dès qu'un artisan prend la commande, le client reçoit dans le chat **ce qu'il doit envoyer** et ce qui lui manque ; sur la commande : « À envoyer à X » avec ce que tu as (sacs et banque), **Acheter le manquant** à l'HV, **Préparer le courrier** à la boîte aux lettres ;
  - **automatique** : un échange avec l'autre côté marque les composants remis ou la commande livrée ; l'objet qui apparaît dans les sacs de l'artisan marque la commande fabriquée ; le courrier envoyé était déjà suivi.
  *Orders end to end: possible crafters, what to send and buy, mail prep, automatic steps on trade and craft.*

## [1.0.0-beta.31] — 2026-11-15

### Ajouté / Added
- **Commandes, le processus complet** :
  - onglet **Ouvertes** : toutes les commandes ouvertes de la guilde, filtre « Ce que je sais fabriquer », Accepter ou Masquer ;
  - **n'importe quel objet** : Maj-clic sur un objet (ou son lien) dans la recherche, puis Commander, même si personne n'a partagé la recette (la note dit qui fournit quoi) ;
  - **historique** des étapes sur chaque commande (ouverte, acceptée, fabriquée, livrée, avec l'heure) ;
  - **messages** entre le client et l'artisan (bouton Message, une ligne dans le chat à l'arrivée) ;
  - **Merci ★** après la livraison : une étoile sur le nom de l'artisan, vue par toute la guilde ;
  - **Recommander** en un clic une commande livrée, annulée, refusée ou expirée (quantité, commission, note reprises) ;
  - **coût des composants** à l'HV et **commission conseillée** (10 %, au moins 1 po) en créant la commande ;
  - **alerte** à l'écran et un son quand une commande arrive pour toi.
  *Orders, the full process: guild board, any item by link, history, messages, thanks, order again, reagent cost and suggested fee, alerts.*

## [1.0.0-beta.30] — 2026-11-15

### Corrigé / Fixed
- Améliorations : la ligne « WL Helper · spé : % » revient dans les infobulles avec Geared Forever installé, y compris le pourcentage négatif en rouge quand l'objet est moins bien (son chiffre, lu dans les deux sens).
  *Upgrades: the tooltip line is back with Geared Forever installed, negative percent included.*

## [1.0.0-beta.29] — 2026-11-15

### Corrigé / Fixed
- **Spam « Aucun joueur nommé X ne joue actuellement »** : les Commandes demandaient les recettes par message privé, au nom sans royaume. Plus aucun message privé : la demande passe par le canal de guilde et seul le propriétaire répond.
  *"No player named X" spam: recipe requests no longer go by whisper.*
- **Passe complète sur tout l'addon** (audit par module, chaque défaut contre-vérifié avant correction) : textes coupés ou superposés dans le Comptoir, la flèche GPS (plus large), le guide, le sélecteur, la Guilde, le LFG, les Commandes, l'accueil, les réglages et l'écran de bienvenue ; prix de l'HV qui pouvaient compter 0 à tort ; objectif de réputation mal lu ; épingle de carte effacée à tort ; noms de writs en français reconnus ; classement PvP et événements séparés par guilde ; semaines PvP alignées sur la remise à zéro du jeu ; invitations LFG au-delà de 5 (passage en raid) ; inscription reçue avant l'événement ; flèches d'amélioration plus légères ; un deux-mains n'est plus comparé à la main gauche ; bouton « Publier la commande » qui cachait le réglage de paiement ; raisons de refus traduites chez chacun ; et d'autres.
  *A full audit pass: dozens of layout, logic and text fixes, each one checked before being fixed.*

### Ajouté / Added
- **Commandes, onglet Artisans** : les artisans groupés par métier avec l'icône du métier et son nom dans ta langue ; « Recettes » montre ce qu'un artisan sait fabriquer, avec Commander sur chaque objet.
- **Guide** : bouton **Prêt ?** en bas, qui ouvre la check-list de l'instance ; bouton **Partager** sur la check-list quand tu es en groupe ; la classe et le PNJ ne sont plus répétés sur la ligne de quête.
- Réglages › Quêtes de donjon : « Quêtes répétables et de métiers que tu n'as pas : Masquer / Afficher » remplace « Toutes / Utiles ».

## [1.0.0-beta.28] — 2026-11-15

### Modifié / Changed
- **Commandes : chacun partage ses métiers dès la connexion**, avec leur niveau, sans ouvrir de fenêtre (comme WaR LegenD RaidTool). Les recettes viennent en plus : de la fenêtre de métier, ou de Mastercraft s'il les a déjà lues. Sans recherche, l'onglet Artisans liste les artisans de la guilde par métier (bouton Chuchoter).
  *Orders: everyone shares their professions and levels at login; recipes also come from Mastercraft; crafters listed by profession.*
- **LFG** (ancien « Événements ») : icônes de rôle du jeu (tank, soins, dégâts) ; dans Créer, choix d'un ou plusieurs donjons ou raids dans la liste du guide, ou une quête ou autre chose à écrire.
  *LFG (formerly Events): the game's role icons; pick one or more dungeons or raids when creating.*
- **Accueil en grille** : les Quêtes de donjon en haut, les autres modules en tuiles sur deux colonnes.
- Réglages : les explications ne passent plus sous les boutons ; le tableau des poids est aligné en deux colonnes.

## [1.0.0-beta.27] — 2026-11-15

### Ajouté / Added
- **Événements** (nouveau module, `/wlh events`, carte sur l'accueil) : le calendrier et le LFG de la guilde. Un membre propose un donjon ou un raid (jour, heure, places tank / soins / DPS, note) ; les autres s'inscrivent avec un rôle ou se désinscrivent ; rappel 15 min avant ; l'organisateur invite tous les inscrits en un clic. Onglet **Groupe maintenant** : « je cherche un groupe » avec ton rôle et pour quoi, et la liste de ceux qui cherchent (clic : chuchoter, clic droit ou Alt-clic : inviter).
  *Events: the guild's own calendar and LFG.*
- **Améliorations** a sa carte sur l'accueil (spé, nombre d'objets meilleurs dans tes sacs). **Calcul** : quand Geared Forever est installé, son verdict est lu directement (réglable) ; sinon les poids de WL Helper.
  *Upgrades: home card; Geared Forever's verdict is read when it is installed.*

### Modifié / Changed
- Noms : « Comptoir / Trading Post » devient **Writs & Favor** ; le guide s'appelle **Quêtes de donjon**.
- Armes : la vitesse compte (main droite lente, main gauche rapide pour les classes à deux armes), et une arme à une main est comparée aux deux mains.
  *Weapon speed counts (slow main hand, fast off hand); one-hand weapons are compared in both hands.*

## [1.0.0-beta.26] — 2026-11-15

### Ajouté / Added
- **Guilde : la spé de chacun** (pour les membres qui ont WL Helper : celle que juge leur module Améliorations) à côté du nom, et le **tri par classe**, puis par spé, en plus du niveau, du nom, de la zone et du rang.
  *Guild: each member's spec (members with WL Helper) next to the name, and sorting by class then spec.*

## [1.0.0-beta.25] — 2026-11-15

### Modifié / Changed
- **La commande devient `/wlh`** : WaR LegenD RaidTool utilise déjà `/wl`. `/wl` ouvre encore WL Helper quand RaidTool n'est pas installé. **Le logo passe en or** pour ne pas le confondre avec celui de RaidTool.
  *The command is now /wlh (RaidTool owns /wl); /wl still works without RaidTool. Gold logo, to tell it from RaidTool's.*
- **Guilde, classement PvP** : les victoires honorables comptées par le jeu (champs de bataille compris), donc ton total s'affiche tout de suite ; **cette semaine**, **saison** (un mois) et **depuis toujours** ; le podium de la saison passée est gardé. Les victoires en monde ouvert restent affichées à part.
  *PvP ranking: the game's honorable kills (week, monthly season, all time), last season's podium kept.*
- **Guilde, membres** : recherche (nom, zone, rang), tri (niveau, nom, zone, rang), « où est la guilde » (les zones les plus remplies), clic pour chuchoter, clic droit ou Alt-clic pour inviter, note publique et métiers dans l'infobulle.
  *Members: search, sort, busiest zones, click to whisper, right-click to invite, note and professions in the tooltip.*
- **Améliorations** : une page à elle dans les Réglages (spé, seuil de la flèche, ligne d'infobulle, tableau des poids utilisés) ; les poids changent avec ta tranche de niveaux (1-20, 21-40, 41-59, 60).
  *Upgrades: its own settings page; weights adjusted by level bracket.*
- **Flèches d'amélioration** dans les sacs du jeu (séparés ou combinés) et dans EllesmereUI Bags, en plus de Baganator.
  *Upgrade arrows in the game's bags (separate or combined) and EllesmereUI Bags, besides Baganator.*
- **Nettoyeur** : tous les objets se cochent (les gris jamais d'office) puisque le jeu demande confirmation ; un objet nommé comme une quête de ton journal n'est plus proposé (The Pariah's Instructions).
- **Hôtel des ventes** : le scan automatique ne part que si la fenêtre du Comptoir est ouverte et que des prix ont plus d'une heure.
- Bouton Accueil plus sobre (la pierre de foyer) ; la fenêtre Commandes montre les métiers que ton addon a lus.

## [1.0.0-beta.24] — 2026-11-15

### Corrigé / Fixed
- **« WLHelper a été bloqué » au chargement** : le module Guilde s'abonnait au journal de combat, fermé aux addons sur ce client. Le classement PvP compte maintenant les victoires honorables du jeu gagnées en monde ouvert.
  *"WLHelper has been blocked" at login: the Guild module no longer uses the combat log; the PvP ranking counts the game's honorable kills in the open world.*
- **Commandes : personne ne voyait les artisans.** Un événement inconnu de ce client (TRADE_SKILL_UPDATE) arrêtait tout le module, et les recettes étaient lues avec l'ancienne interface des métiers. Le module lit maintenant les métiers comme ce client les donne. Tous les événements de l'addon sont désormais demandés sans risque : un événement inconnu ne peut plus arrêter un module.
  *Orders: crafters never showed (an unknown event stopped the module; recipes are now read with the modern profession API).*
- **Nettoyeur de sacs** : ce client refuse qu'un addon détruise un objet. L'objet coché est mis sur ton curseur ; un clic dans le monde ouvre la confirmation du jeu.
  *Bag cleaner: the ticked item goes on your cursor; the game's own box destroys it.*
- **Améliorations** : les dégâts d'une école de magie (« +24 aux sorts de Givre ») comptent selon ta spé. Une Frostweave Tunic n'est plus vue comme bien pire qu'une Robe of Power.
  *Upgrades: one school's spell damage counts for your spec.*
- **Textes invisibles** chez certains joueurs : la police du jeu est utilisée par défaut ; celle d'EllesmereUI se choisit dans Réglages › Général.
- **GPS** : plus de flèches en double (losange jaune du jeu, TomTom, Naowh) quand la flèche de WL Helper est allumée, et plus de fond gris sous la flèche.
- Guide : les noms complets (« Zul'Farrak », plus « ZF »), l'étape en premier sur la ligne de progression, la zone plus répétée dans le titre de l'étape, une épingle de carte pour aller au point.
- La macro DG_Cible va dans les macros de compte quand celles du personnage sont pleines.
- Ton nom n'apparaît plus deux fois dans le classement de guilde.

### Ajouté / Added
- **Bouton « Accueil »** dans l'en-tête de chaque fenêtre, guide des donjons et sélecteur compris.

## [1.0.0-beta.23] — 2026-11-15

### Ajouté / Added
- **« WL Helper a été bloqué »** : quand le jeu bloque une action de l'addon, une ligne dans le chat dit laquelle (le message du jeu ne le dit pas), et le formulaire de bug de `/wl idea` la contient déjà.
  *When the game blocks an action, the chat says which function, and the bug form already includes it.*

### Modifié / Changed
- La ligne d'amélioration dans les infobulles ne redessine plus l'infobulle elle-même (moins de risque de gêner l'interface du jeu).

## [1.0.0-beta.22] — 2026-11-15

### Corrigé / Fixed
- **Commandes : les artisans n'apparaissaient pas** chez un membre connecté après eux. L'addon demande maintenant les recettes à la guilde à la connexion et à l'ouverture de la fenêtre Commandes ; chacun répond, et les listes manquantes arrivent seules. Le message « aucune recette » rappelle que chacun, toi compris, doit ouvrir une fois sa fenêtre de métier.
  *Orders: crafters now show for members who log in later (recipes are asked for at login and when the window opens).*

## [1.0.0-beta.21] — 2026-11-15

### Corrigé / Fixed
- **Nettoyeur de sacs** : les explications ne sont plus coupées (« à détruire à… ») : plus courtes, fenêtre plus large, deux lignes si besoin. Le Marteau de Zul'Farrak et les autres objets à garder ne sont plus listés. Quand rien ne peut être coché, le bouton le dit (« Rien que l'addon puisse détruire ») et l'intro explique les objets grisés : les glisser hors du sac pour les détruire soi-même.
  *Bag cleaner: no more cut-off texts; items to keep are no longer listed; clearer when nothing can be ticked.*

## [1.0.0-beta.20] — 2026-11-15

### Ajouté / Added
- **Retour à l'accueil partout** : un « ‹ » en haut à gauche de chaque fenêtre (Comptoir, Commandes, Guilde, Sacs, Réglages, sélecteur de donjons...), et le logo fait de même.
  *A "‹" back-to-home button (and the logo) in every window.*

### Corrigé / Fixed
- **Textes invisibles chez certains joueurs** : avec une autre version d'EllesmereUI, la police qu'on lui emprunte pouvait manquer et les textes disparaissaient (boutons, lignes d'étape). L'addon vérifie maintenant que la police s'affiche, sinon il prend celle du jeu.
  *Invisible texts with another EllesmereUI version: the borrowed font is checked, the game's font is used otherwise.*
- Comptoir : « reset dans 14 h » devient « nouveaux writs dans 14 h », et « Rends les 0 writs prêts » devient « Achète 8 writs dans l'onglet Achats ».
  *Trading Post: no more English "reset", no more "hand in the 0 ready writs".*

## [1.0.0-beta.19] — 2026-11-15

### Ajouté / Added
- **Guilde** (nouveau module, `/wl guild`, carte sur l'accueil) : toute la guilde, en ligne d'abord, avec la couleur de classe, le niveau, la zone (ou depuis quand le membre n'est pas venu), le rang, et le logo WL sur ceux qui ont l'addon. Onglet **Classement PvP** : les victimes tuées de ta main en monde ouvert (pas en champ de bataille ni en arène), cette semaine et depuis toujours, avec les victoires honorables quand le jeu les donne. Chaque copie de l'addon compte pour son joueur et le partage à la guilde.
  *Guild module: the whole roster and an open-world PvP kill ranking (week / all time), counted by each member's addon.*

## [1.0.0-beta.18] — 2026-11-15

### Modifié / Changed
- **Améliorations avec nos propres poids de stats** : par classe et par spé (l'arbre de talents le plus rempli, ou la spé choisie dans Réglages › Sacs), en comptant l'arme pour les emplacements qui s'en servent. Plus besoin de Geared Forever. Une ligne « WL Helper · Givre : +12% » dans chaque infobulle d'objet ; les objets que ta classe ne peut pas porter sont ignorés.
  *Upgrades use WL Helper's own stat weights per class and spec; a line in every item tooltip; Geared Forever no longer needed.*
- **Clic droit pour tirer sans touche** : le choix « Aucune » tire au clic droit seul sur un ennemi (baguette des mages, prêtres, démonistes : c'est leur réglage de départ). La touche est retenue par classe.
  *Right-click to shoot with no key ("None"), the default for wand users; the key is kept per class.*
- **Raids** : Barrow Deeps (10 joueurs) et le Sommet d'Hyjal (20) rejoignent Onyxia (40), marqués « À venir » jusqu'au 9 décembre 2026.
  *Raids: Barrow Deeps and Hyjal Summit join Onyxia, marked upcoming until 9 December 2026.*

### Corrigé / Fixed
- Sélecteur : les donjons sous ton niveau avaient leur place dans « Plus tard » ; ils ont maintenant leur section « Sous ton niveau ».
  *Picker: dungeons below your level get their own section.*
- « Maj » s'affiche « Shift » en anglais.

## [1.0.0-beta.17] — 2026-11-15

### Modifié / Changed
- **Commandes rangées** : une seule commande, `/wl`, et un seul mot anglais par action, le même en français : `dungeons`, `pick`, `trade`, `bags`, `orders`, `gps`, `options`, `setup`, `idea`, `help`. Les anciens mots (`/wl reglages`, `/wl sacs`...) marchent encore mais ne sont plus affichés. `/comptoir`, `/writs`, `/wlo`, `/dg`, `/dguide`, `/wldt` et `/zfg` sont retirés.
  *One command, /wl, one English word per action in every language; the old extra slash commands are gone.*
- **Sélecteur de donjons** refait : grandes cartes sur deux colonnes avec l'écran de chargement du donjon (les fichiers du jeu), le nom en haut, « 5/6 quêtes » et l'emblème de faction à droite, une coche verte quand tout est fait, les niveaux en bas. Les donjons trop hauts pour toi sont en gris.
  *Dungeon picker redone: wide picture cards, quest count, levels; too-high dungeons in grey.*

## [1.0.0-beta.16] — 2026-11-15

### Ajouté / Added
- **Écran de bienvenue** à la première connexion : chaque module avec son interrupteur, les clics et le bouton de la minimap. `/wl bienvenue` le rouvre.
  *Welcome screen at first login: modules, clicks, minimap button. /wl welcome reopens it.*

### Modifié / Changed
- **Les clics sont désactivés par défaut** (Alt-clic pour inviter, touche + clic droit pour tirer) : ils changent ce que fait un clic, chacun choisit. Ceux qui avaient une bêta précédente les retrouvent éteints et l'écran de bienvenue leur propose.
  *Clicks are off by default; the welcome screen offers them.*
- Chasseur : le clic droit seul reste l'attaque au corps-à-corps ; avec la touche, Tir automatique démarre sans jamais s'arrêter sur un second clic (weaving).
  *Hunters: right-click alone stays melee; with the key, Auto Shot never toggles off (weaving).*

## [1.0.0-beta.15] — 2026-11-15

### Modifié / Changed
- Améliorations : dans Baganator, les flèches reprennent les réglages de Geared Arrows (mêmes coins), qu'il n'est plus nécessaire d'installer.
  *Upgrades: Baganator keeps your Geared Arrows corner settings; Geared Arrows is no longer needed.*

## [1.0.0-beta.14] — 2026-11-15

### Ajouté / Added
- **Améliorations** (nouveau module) : une flèche verte et le gain (« +24% ») sur les objets de tes sacs meilleurs que ce que tu portes, selon Geared Forever et la spé choisie dans /geared. Sacs du jeu et Baganator. Reprend Geared Arrows : s'il est encore installé, c'est lui qui s'en charge.
  *Upgrades: a green arrow and the gain on bag items better than yours, judged by Geared Forever.*
- **Journal du donjon** dans le menu « … » du guide : boss et butin du donjon de l'étape, dans Naowh Dungeon Journal ou Forever Dungeon Journal.
  *Dungeon journal in the guide's "..." menu.*
- **Alerte des monstres rares** dans les donjons : un message à l'écran et un son, une fois par monstre (Réglages › Donjons).
  *Rare monster alert inside dungeons.*

### Corrigé / Fixed
- Quel'Serrar : les deux quêtes de Lydros sont dans le même donjon (Hache-Tripes Nord, par l'Athenaeum).
  *Quel'Serrar: both Lydros quests in the same wing.*
- Alt-clic sur un PNJ amical le cible de nouveau (l'invitation ne concerne que les joueurs).
  *Alt-click on a friendly NPC targets it again.*

## [1.0.0-beta.13] — 2026-11-15

### Modifié / Changed
- La fenêtre des donjons revient après un /reload ou une connexion si elle était ouverte quand tu es parti, et reste fermée si tu l'avais fermée.
  *The dungeon window comes back after /reload or login only if it was open when you left.*

### Corrigé / Fixed
- En anglais, la carte de l'accueil et le menu de la minimap disaient « Commands » au lieu de « Orders ».
  *English: the Orders card and minimap entry read "Commands".*

## [1.0.0-beta.12] — 2026-11-15

### Corrigé / Fixed
- La fenêtre des donjons ne s'ouvre plus toute seule à la connexion ni après un /reload : `/wl`, l'accueil ou la minimap l'ouvrent.
  *The dungeon window no longer opens by itself at login or after /reload.*

## [1.0.0-beta.11] — 2026-11-15

### Ajouté / Added
- **Commandes** (nouveau module, `/wl commandes`) : faire fabriquer un objet par la guilde ou par un artisan précis, comme les commandes d'artisanat de retail. Tu choisis qui fournit chaque composant, la commission, un pourboire et la durée ; l'artisan accepte ou refuse avec une raison, puis marque « fabriqué » et « livré ». L'addon lit la boîte aux lettres pour dire si l'artisan a bien reçu les composants et l'argent, et remplit le courrier pour toi (pièces jointes, argent ou contre-remboursement). Les recettes de chacun sont partagées dans la guilde quand il ouvre son métier (désactivable).
  *Orders (new module): guild or one-crafter crafting orders like retail; accept/decline with a reason, fee and tip, who provides each reagent, inbox check of what the crafter received, mail filled for you.*
- **Clics** (Réglages > Général) : Alt-clic sur un nom, un joueur ou un portrait pour l'inviter, lien [Inviter] sur les messages qui le demandent (repris d'Alt-Click Invite) ; Maj + clic droit sur un ennemi pour tirer (arme à distance, baguette ou lancer ; touche au choix). Si l'addon d'origine est encore chargé, la fonction reste chez lui.
  *Clicks: Alt-click invite (from Alt-Click Invite) and modifier + right-click to shoot.*
- **Caisses rendues automatiquement** chez Dokimi (Tarides) ou Marcy Baker (Les Carmines) ; Maj pour l'empêcher, interrupteur dans Réglages > Comptoir.
  *Crates handed in automatically at the Inventory Intake.*
- Favor : bouton « Rendre les caisses » qui lance le GPS jusqu'à ce PNJ.
  *Favor: a "Turn crates in" button with GPS.*

## [1.0.0-beta.10] — 2026-11-15

### Modifié / Changed
- Favor : le bouton dit où en est le scan (« Scan 12 / 48 », « Prix réels : 3 objets restants », « Prix à jour · à l'instant », « Prix d'il y a 8 min · rescanner ») ; un composant que tu as déjà s'affiche « déjà là » au lieu de « 0 ».
  *Favor: the scan button tells its state and how fresh prices are; owned materials read "already have".*

## [1.0.0-beta.9] — 2026-11-15

### Modifié / Changed
- Accueil : les donjons portent leur nom complet (« Zul'Farrak », plus « ZF ») ; plus de barre rouge à côté d'une carte, le bouton suffit ; « Maintenant : » au lieu de « Ensuite : » pour l'étape en cours.
  *Home: full dungeon names, no red edge, "Now:" for the current step.*

## [1.0.0-beta.8] — 2026-11-15

### Corrigé / Fixed
- **Nettoyeur de sacs : il pouvait faire perdre une quête.** Un objet d'une quête propre à Forever (absente de LibForeverData) était classé « aucune quête ne le demande », et le jeu abandonne une quête dont on détruit l'objet. Désormais le nettoyeur ne détruit que ce qu'il peut prouver inutile : un objet lié à des quêtes que tu as toutes rendues. Le reste est seulement listé, « à détruire à la main ». Il lit aussi le texte complet de chaque quête du journal pour y repérer les objets.
  *Bag cleaner could make you lose a quest: it now only destroys items tied to quests you turned in; anything unproven is listed only.*
- Nettoyeur : un objet détruit par clic (le jeu n'en accepte qu'un) ; le bouton dit combien il en reste.
  *One item per click; the button says how many are left.*

### Modifié / Changed
- **Favor** : le plan montre les caisses puis, sur sa propre ligne, le lot à acheter (« 60× Silver Bar ») avec les autres lots possibles (« ou 120× Iron Bar ») ; un clic achète ce que la ligne montre. Noms raccourcis (« Journeyman Ingots »), lignes qui ne se chevauchent plus.
  *Favor plan: crates and their bundle on separate clickable rows, with the other bundles; shorter names, no overlapping text.*
- **Scan de l'HV** : une barre de progression sous les onglets du Comptoir et « Scan 12 / 48 », sur tous les onglets.
  *AH scan progress bar under the Trading Post tabs.*
- En-tête du Comptoir allégé (le titre seul).
- **Prix réels à l'HV** : avec l'hôtel des ventes ouvert, le plan de Favor lit toutes les offres de chaque caisse et de chaque composant (offre par offre, du moins cher au plus cher) et calcule le vrai coût pour la quantité voulue ; il dit quand il n'y en a pas assez en vente. Sans l'HV, le prix est marqué « ~ estimé ».
  *Real AH prices: with the auction house open, the Favor plan reads every listing and computes the true cost.*
- **Lots mélangés** : un lot par caisse, mais les caisses peuvent prendre des lots différents ; le plan choisit caisse par caisse le moins cher (il passe aux Iron Bar quand les Silver Bar bon marché sont épuisés).
  *Bundles mixed across crates, crate by crate, cheapest first.*
- **La banque compte** : ce que tu as en banque n'est plus à racheter (liste d'achat, writs, Favor) ; la liste dit « 2 en banque ».
  *Your bank counts: items in the bank are not bought again.*
- Le guide ne s'ouvre plus jamais tout seul à la connexion ou au /reload : `/wl`, l'accueil ou la minimap l'ouvrent.
  *The guide never opens by itself at login or /reload.*

## [1.0.0-beta.7] — 2026-11-15

### Ajouté / Added
- **Rappel de mise à jour** : chaque copie de l'addon annonce discrètement sa version à ta guilde et à ton groupe. Si quelqu'un a plus récent que toi, un message te le dit une fois, et l'accueil et l'infobulle de la minimap affichent « Mise à jour disponible : … · WowUp › Update ». Seul le numéro de version est envoyé. Ça marche à partir de cette version : il faut que d'autres joueurs l'aient aussi.
  *Update reminder: copies tell each other their version on the guild and group channels; a newer one shows on the home page and the minimap tooltip.*

### Modifié / Changed
- Accueil : la carte Donjons dit l'étape et ce qu'il faut faire ensuite ; la carte Comptoir montre ta Merchant's Favor ; la ligne GPS n'apparaît que pendant un guidage.
  *Home: the next step on the Dungeons card, your Favor on the Trading Post card, the GPS line only while guiding.*

## [1.0.0-beta.6] — 2026-11-15

### Ajouté / Added
- **Planificateur de Merchant's Favor** (onglet « Favor » du Comptoir) : tu tapes combien de Favor tu veux ; il prend les Waylaid Crates les moins chères (caisse + le lot de composants le moins cher, ce que tu as déjà est gratuit), tient compte de ce qui est en vente au dernier scan, et liste quoi acheter. Clic : acheter la caisse ; Maj-clic : le lot. La Favor de chaque caisse s'apprend quand tu en rends une. Les lots sont lus dans Naowh Forever.
  *Merchant's Favor planner: type the Favor you want; the cheapest Waylaid Crates and bundles, what to buy, one click at the AH.*
- **Choisir ses writs** : dans « Tous », une case par writ ; le total (prix, prix après Coin Pouch, réputation) se met à jour à chaque coche, et la liste d'achat suit ta sélection. Sans coche, le plan automatique reste.
  *Tick the writs you want in "All": live total of cost and reputation; the shopping list follows your pick.*

### Modifié / Changed
- **Choix des donjons** rangé en sections : à ton niveau, plus tard, terminés (coche verte, barre verte), sans quête Horde (avec « Tous »).
  *Dungeon picker in sections, with a green check on finished dungeons.*
- Titre « WaR LegenD Helper » dans l'infobulle de la minimap et sur l'accueil.
- Liste d'achat : groupes « À rendre en <zone> · N writs », enveloppes écrites « Enveloppe · objet » ; bouton « Liste Auctionator » retiré (l'achat est intégré).
  *Shopping list groups and names are clearer; the Auctionator list button is gone.*
- Textes : paragraphes coupés en lignes courtes ; « Une idée, un bug ? » en trois étapes numérotées.
  *Texts split into short lines; the feedback window in three steps.*

### Corrigé / Fixed
- Le guide ne s'ouvre plus tout seul au /reload quand il n'y a pas de route.
  *The guide no longer opens by itself at /reload without a route.*
- Nettoyeur : le Mallet of Zul'Farrak (invoque Gahz'rilla) n'est jamais proposé ; un objet utilisable est signalé « lis son infobulle avant de le jeter ».
  *Cleaner: the Mallet of Zul'Farrak is kept; usable items are flagged.*
- Accueil : le texte de la carte Donjons ne déborde plus.

## [1.0.0-beta.5] — 2026-11-15

### Ajouté / Added
- **Chercher dans les réglages** : une barre en haut des réglages (aussi Ctrl+F). Les résultats arrivent pendant que tu tapes, rangés par page ; les pages sans résultat s'estompent. ↑ ↓ et Entrée pour choisir ; le réglage choisi s'ouvre et clignote. Ça trouve en français et en anglais, avec ou sans accents, et par mots-clés (« arrow » trouve la flèche).
  *Search the settings (also Ctrl+F): live results grouped by page, keyboard navigation, the picked setting opens and flashes; French and English, accents optional, keywords.*
- **Modules** : Réglages › Général › Modules permet d'éteindre les Donjons, le Comptoir ou les Sacs. Un module éteint n'écoute plus rien et n'ouvre plus de fenêtre ; sur l'accueil il devient une carte grise avec « Allumer ». Le rallumer est immédiat, sans /reload. Le GPS reste toujours actif.
  *Modules: turn the Dungeons, Trading Post or Bags module off; an off module does nothing and shows a dimmed "Turn on" card on the home page; turning it back on is immediate.*

### Modifié / Changed
- Le dépôt a déménagé : **github.com/WarLegenDHelper/WLHelper**, avec le logo War Legend. L'ancienne adresse redirige.
  *The repository moved to github.com/WarLegenDHelper/WLHelper; the old address redirects.*

### Corrigé / Fixed
- `/wl réglages` et `/wl idée` tapés avec les accents.
  *Commands typed with French accents.*
- Relecture Fable 5.2 : la recherche ne recouvre plus une page ouverte depuis la barre de gauche ; en combat, la fenêtre des réglages ne bloque plus le clavier ; un module éteint ne laisse plus de flèche, de points sur la carte, de scan à l'HV ni de tournée ; rallumer les Donjons réaffiche le guide tout de suite ; `/comptoir options` marche même Comptoir éteint.
  *Review fixes: search vs. page, no keyboard capture in combat, a switched-off module leaves nothing running, Dungeons come back at once.*

## [1.0.0-beta.4] — 2026-11-15

### Modifié / Changed
- **Le dossier de l'addon s'appelle maintenant `WLHelper`** (avant : `DungeonGuide`), et son titre dans la liste des addons du jeu est « WaR LegenD Helper ». Le jeu range les réglages par nom de dossier : ils repartent de zéro une fois (donjons choisis, points de vol appris, valeur des Coin Pouch, zones mises de côté). Si l'ancien dossier `DungeonGuide` est encore là, l'addon le désactive et te dit de le supprimer.
  *The addon's folder is now `WLHelper` (it was `DungeonGuide`), titled "WaR LegenD Helper" in the game's addon list. Settings are stored by folder name, so they start over once. If the old folder is still there, the addon turns it off and tells you to delete it.*
- Icône de l'addon : le logo War Legend.
  *Addon icon: the War Legend logo.*

### Corrigé / Fixed
- Le menu du clic droit sur la minimap passait derrière les barres de boutons de minimap (EllesmereUI…) ; le menu « ... » du guide aussi peut passer devant tout.
  *The minimap right-click menu no longer opens behind minimap button bars; same for the guide's "..." menu.*

## [1.0.0-beta.3] — 2026-11-15

Une interface rangée : un accueil, un guide allégé, une minimap et des commandes claires.
*A tidy interface: a home page, a lighter guide, a clear minimap button and commands.*

### Ajouté / Added
- **Accueil** (`/wl`, clic sur la minimap) : une carte par module avec où tu en es (donjon et étape, writs prêts, objets à jeter), le GPS en cours avec un bouton pour l'arrêter, « Une idée, un bug ? » et les réglages.
  *Home page: one card per module with where you stand, the running GPS, feedback and settings.*
- **Choisir ses writs** : clic droit sur un writ dans « Tous les writs » pour le mettre de côté ; Réglages › Comptoir › « Zones où je vais » pour écarter des zones entières. Le plan d'achat n'achète plus ce qui est écarté.
  *Pick your writs: right-click a writ to set it aside, or turn whole zones off in the settings; the buying plan skips them.*
- Minimap : clic droit, un menu vers chaque module ; l'infobulle dit où tu en es.
  *Minimap right-click menu to each module; the tooltip shows where you stand.*

### Modifié / Changed
- **Guide des donjons** : en-tête avec le logo (retour à l'accueil), « Choisir » et les réglages ; en bas, un seul gros bouton selon l'étape (« Y aller », « Revenir à l'étape en cours », « Choisir des donjons »), puis précédente / suivante et un menu « ... » (partager, recalculer, points, étape faite, flèche, points auto, liste).
  *Dungeon guide: logo back to home, Pick and settings in the header; one big contextual button, previous / next and a "..." menu below.*
- **Commandes** sous `/wl`, en français et en anglais : `donjons`/`dungeons`, `choisir`/`pick`, `comptoir`/`trade`, `sacs`/`bags`, `gps`, `reglages`/`options`, `idee`/`idea`, `aide`/`help`. Les anciennes marchent encore.
  *Commands under /wl in French and English; the old ones still work.*
- Le Comptoir s'appelle **Trading Post** en anglais. Le bouton de minimap prend le logo War Legend. Les messages du chat commencent par « WL Helper ». « Réglages » partout.
  *The Comptoir is the Trading Post in English; War Legend logo on the minimap button; one chat prefix; "Settings" everywhere.*

### Corrigé / Fixed
- Deux fenêtres ouvertes ne se mélangent plus (les interrupteurs des réglages passaient à travers le Comptoir).
  *Two open windows no longer mix.*
- Survoler une ligne du Comptoir ne cache plus son texte.
  *Hovering a Comptoir row no longer hides its text.*
- Infobulles des writs sans PNJ connu : les lignes « Clic : GPS » manquaient.
  *Tooltips of writs without a known NPC lost their click hints.*
- « Arrêter le GPS » arrête vraiment la flèche, qu'elle vienne du guide ou du Comptoir ; `/wl gps` l'arrête ou la relance.
  *"Stop the GPS" really stops it, whoever started it.*
- Les pages de réglages défilent quand elles sont longues.
  *Long settings pages scroll.*

## [1.0.0-beta.2] — 2026-11-15

Refonte complète de l'interface aux couleurs de War Legend, page d'options, GPS plus fin.
*Full redesign in War Legend colours, an options page, a sharper GPS.*

### Ajouté / Added
- **Options** (`/wl options`, `/wlo`, aussi dans les options du jeu et dans EllesmereUI) : pages Général, Donjons, Comptoir, GPS, Sacs, À propos.
  *Options page (`/wl options`, `/wlo`, also in the game settings and in EllesmereUI).*
- **Nettoyeur de sacs** (`/wl clean`) : liste les objets de quête devenus inutiles et les détruit en un clic ; ce qui peut servir à une quête suivante est signalé, les objets rares restent à la main. Demandé par Eksipump.
  *Bag cleaner: lists quest items you no longer need and deletes them in one click; items a later quest may need are flagged.*
- **Confort du Comptoir**, chacun désactivable : acceptation et remise automatiques des writs (Maj pour l'empêcher), rappel à la connexion, infobulle des enveloppes (réputation, objet demandé, prix, lieu, déjà rendu).
  *Writ comforts, each one a switch: auto-accept and auto turn-in (hold Shift to skip), login reminder, envelope tooltip.*
- **GPS** : une seule recherche vers tous les arrêts de la tournée, étapes « 2 sur 5 », temps estimé par zone, prise du vol automatique en option, flèche Zygor utilisable à la place de la nôtre (option « auto » si son pathfinding est actif).
  *GPS: one search to every stop, "step 2 of 5", time per zone, optional auto flight, Zygor's arrow can guide instead of ours.*
- **Chaînes longues** dans le guide : amulette de Lord Valthalak (une pièce par donjon, au choix), Quel'Serrar, Eranikus et sa chaîne d'Ahn'Qiraj, Dead Man's Plea complète pour toutes les classes ; une quête faisable dans plusieurs donjons se place dans celui que tu as choisi.
  *Long chains: Lord Valthalak's amulet (one piece per dungeon, your pick), Quel'Serrar, Eranikus with its Ahn'Qiraj chain, Dead Man's Plea for every class; a quest doable in several dungeons goes to the one you picked.*
- **Une idée, un bug ?** (`/wl idee`, options › À propos) : le jeu ne laisse pas un addon aller sur internet, alors l'addon prépare le lien d'un formulaire GitHub déjà rempli avec ta version, à coller dans le navigateur.
  *An idea, a bug? (`/wl idea`): a prefilled GitHub form link to paste in your browser.*
- Flèche : icône du moyen de transport (wyverne ou griffon, sort de téléportation), état « en combat », taille et transparence réglables, déplaçable depuis les options.
  *Arrow: transport icon, in-combat state, scale and alpha settings, movable from the options.*

### Modifié / Changed
- Le module Writs s'appelle maintenant **Comptoir** ; nouvelle fenêtre avec les onglets Aujourd'hui, Achats, Tous : cartes par zone, bouton « Y aller », ouverture de l'enveloppe depuis la liste, total de la liste d'achat en pièces.
  *The Writs module is now the Comptoir, with Today, Shopping and All tabs.*
- Logo et rouge War Legend dans tout l'addon (le guide ne suit plus la couleur d'EllesmereUI).
  *War Legend logo and red throughout.*
- La liste d'achat déduit les objets déjà dans les sacs.
  *The shopping list subtracts items already in your bags.*
- Commandes : `/comptoir` devient la commande du Comptoir (`/wl comptoir`, `/writs` reste en alias) ; nouvelles `/wl options`, `/wl clean`.
  *Commands: `/comptoir` is the Comptoir's command (`/writs` still works); new `/wl options`, `/wl clean`.*

### Supprimé / Removed
- Le calculateur de coût des writs (remplacé par le plan du jour).
  *The writ cost calculator (the day plan replaces it).*

### Corrigé / Fixed
- Le guide et sa flèche restent fermés après un /reload s'ils l'étaient ; rouvrir le guide ou rallumer la flèche la repointe.
  *The guide and its arrow stay closed after /reload; reopening points the arrow again.*
- Le bouton « Prendre le vol » s'affiche bien à la carte de vol ; le guide de donjon ne remplace plus une tournée du Comptoir.
  *The Take flight button shows at the flight map; the dungeon guide no longer overrides a Comptoir tour.*
- Moins de travail quand le guide est fermé (pas de rafraîchissement, modèle du boss rechargé seulement s'il change, synchro de groupe groupée).
  *Less work while the guide is closed.*
- **Guide de donjons, données revérifiées** contre LibForeverData et Naowh Forever : pré-quêtes manquantes ou dans le désordre (baguette de mage à SM, chaînes de classe du Temple englouti, A Taste of Flame et The Challenge à BRD, The Restless Souls et Dead Man's Plea à Stratholme, destrier du démoniste), quête Alliance montrée à la Horde (Hall of Thanes), clé d'UBRS, Rocknot's Ale (n'envoie plus à Duskwood), niveaux minimum, noms de PNJ ; 28 quêtes ajoutées (dont l'Œil de l'Emberseer).
  *Dungeon data re-checked against LibForeverData and Naowh Forever: missing or out-of-order prerequisites, an Alliance quest shown to Horde, the UBRS key, Rocknot's Ale, minimum levels, NPC names; 28 quests added.*
- **Nettoyeur de sacs plus sûr** : ne propose plus un objet utilisé par une quête du journal (même sous une zone repliée) ni l'objet qu'une quête donne à utiliser ; sans LibForeverData rien n'est coché ; rien n'est détruit si la liste a changé juste avant le clic.
  *Safer bag cleaner: never offers items an active quest uses; nothing checked without LibForeverData; nothing destroyed if the list just changed.*
- **Combat** : la flèche et la fenêtre du Comptoir ne bloquent plus le jeu (ADDON_ACTION_BLOCKED) ; le bouton de téléportation ne reste plus affiché après la fin du trajet ; la macro et la barre d'action du guide se mettent à jour après le combat même guide fermé.
  *Combat: no more blocked actions from the arrow or the Comptoir; the teleport button no longer lingers; the guide's macro and bar catch up after combat.*
- **GPS** : après un détour du Comptoir, la flèche revient sur l'étape de donjon ; « Dans le donjon » à l'intérieur ; pas de vol ni de téléport proposé en fantôme ; la flèche de Zygor s'efface à l'arrêt.
  *GPS: back to the dungeon step after a Comptoir detour; "Inside the dungeon" in instances; no flight or teleport as a ghost; Zygor's waypoint cleared on stop.*
- **Performances** : la flèche ne redessine que ce qui change ; le GPS ne tourne plus sans trajet ; une seule recherche pour toutes les zones du Comptoir ; le journal de quêtes est lu une fois par rafraîchissement ; le guide fermé ne se redessine plus à chaque message du groupe.
  *Performance: the arrow redraws only what changes; no GPS ticker without a route; one search for every Comptoir zone; the guide no longer redraws while closed.*
- Synchro de groupe : seuls les membres du groupe sont écoutés. Maj empêche la remise automatique à toutes les étapes. Le rappel du Comptoir ne revient plus à chaque /reload.
  *Group sync only listens to your group; Shift stops auto turn-in at every step; the Comptoir reminder no longer fires on every /reload.*

## [1.0.0-beta.1] — 2026-11-15

Première version de WL Helper (bêta). WL Dungeon Guide devient **WL Helper**.
*First WL Helper release (beta). WL Dungeon Guide becomes WL Helper.*

### Ajouté / Added

- **Craftsman's Writs** : nouveau panneau (bouton « Writs », `/wl writs`, `/writs`, Maj-clic sur la minimap) — prix par le scan intégré de l'HV, Auctionator ou TSM ; état du jour ; plan d'achat pour le rang suivant ; liste d'achat avec rescan à l'ouverture de l'HV et achat direct ; valeur des Coin Pouch mesurée ; writs de l'autre faction masqués ; lieux de remise appris depuis le journal de quêtes.
- **GPS intégré**, partagé par le guide de donjons et les writs : monture, points de vol connus, zeppelins, bateaux, téléportations de mage ; flèche avec l'étape en cours, boutons « Prendre le vol » et « Lancer la téléportation ». La flèche du guide passe par ce GPS.
- Commandes : `/wl` en commande principale, `/wl gps` ; la version s'affiche au chargement et dans `/wl help`.

### Modifié / Changed
- Titre : WL Dungeon Guide devient WL Helper. `/dg`, `/dguide`, `/wldt` et `/zfg` restent.
- Le dossier reste `DungeonGuide` : la mise à jour remplace WL Dungeon Guide sans doublon.
- Crédits complétés (`DungeonGuide/CREDITS.txt`).

## Avant / before

WL Dungeon Guide jusqu'à la 3.3 : guide des quêtes de donjon Horde pas à pas (versions partagées
à la main, avant ce dépôt).

[Unreleased]: https://github.com/WarLegenDHelper/WLHelper/compare/v1.0.0-beta.10...HEAD
[1.0.0-beta.10]: https://github.com/WarLegenDHelper/WLHelper/compare/v1.0.0-beta.9...v1.0.0-beta.10
[1.0.0-beta.9]: https://github.com/WarLegenDHelper/WLHelper/compare/v1.0.0-beta.8...v1.0.0-beta.9
[1.0.0-beta.8]: https://github.com/WarLegenDHelper/WLHelper/compare/v1.0.0-beta.7...v1.0.0-beta.8
[1.0.0-beta.7]: https://github.com/WarLegenDHelper/WLHelper/compare/v1.0.0-beta.6...v1.0.0-beta.7
[1.0.0-beta.6]: https://github.com/WarLegenDHelper/WLHelper/compare/v1.0.0-beta.5...v1.0.0-beta.6
[1.0.0-beta.5]: https://github.com/WarLegenDHelper/WLHelper/compare/v1.0.0-beta.4...v1.0.0-beta.5
[1.0.0-beta.4]: https://github.com/WarLegenDHelper/WLHelper/compare/v1.0.0-beta.3...v1.0.0-beta.4
[1.0.0-beta.3]: https://github.com/WarLegenDHelper/WLHelper/compare/v1.0.0-beta.2...v1.0.0-beta.3
[1.0.0-beta.2]: https://github.com/WarLegenDHelper/WLHelper/compare/v1.0.0-beta.1...v1.0.0-beta.2
[1.0.0-beta.1]: https://github.com/WarLegenDHelper/WLHelper/releases/tag/v1.0.0-beta.1
