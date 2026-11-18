-- WhatsNew.lua: generated from CHANGELOG.md by the release (make_whatsnew.py; do not edit by hand).
-- Per version: v, date, items = { { s = "add"|"chg"|"fix", fr = { title, text }, en = { title, text } } }
local _, ns = ...
ns.WHATSNEW = {
  { v = "1.0.0-beta.141", date = "2026-11-18", items = {
    { s = "chg", fr = { "La vue moderne, sans cadre comme Polestar", "Le guide « compact » s'appelle maintenant la **vue moderne**. C'est le même guide, avec les mêmes étapes, affiché autrement. Le bouton « Compact » de la fenêtre devient « Moderne »." }, en = { "", "" } },
    { s = "chg", fr = { "", "Par défaut, la vue n'a plus ni fond, ni bordure, ni carte : le texte est posé directement sur le jeu, avec une ombre pour rester lisible." }, en = { "", "" } },
    { s = "chg", fr = { "", "Les couleurs marquent l'important : les noms en bleu, le lieu en saumon, les niveaux en doré, l'étape en orange, les barres d'objectifs en vert." }, en = { "", "" } },
    { s = "chg", fr = { "", "Pour retrouver la carte sur fond sombre comme RestedXP, désactive « Vue moderne sans cadre » (Options > Donjons), ou tape /wlh cadre." }, en = { "The compact guide is now the \"modern view\", frameless by default like Polestar (names, places, levels and step in colour); \"Frameless modern view\" in Options, or /wlh cadre, brings the framed card back.", "" } },
    { s = "fix", fr = { "Décocher « Flèche GPS » ne coupait pas la flèche", "Quand la flèche menait à ton cadavre par-dessus l'étape du guide, décocher Actions > Flèche GPS la laissait affichée. Elle s'arrête maintenant aussi." }, en = { "Unticking the GPS arrow also stops the arrow to your corpse.", "" } },
    { s = "fix", fr = { "Arrêter un guide", "Nouvel **Actions > Arrêter ce guide** (un second clic confirme), ou /wlh stop. Les donjons sont décochés, plus de route ni de flèche ; « Choisir un guide » en lance un autre." }, en = { "Actions > \"Stop this guide\" (or /wlh stop) ends the current route.", "" } },
    { s = "fix", fr = { "Temple englouti, l'œuf d'Hakkar", "La tactique de l'Avatar d'Hakkar dit maintenant tout l'événement, étape par étape. Vérifié sur Wowhead Forever (la quête 3528 et les commentaires des joueurs de Forever) :" }, en = { "", "" } },
    { s = "fix", fr = { "", "rangez familiers et totems avant de commencer, sinon l'Avatar ne vient pas sur Forever ;" }, en = { "", "" } },
    { s = "fix", fr = { "", "utilise l'Egg of Hakkar au milieu du Sanctum of the Fallen God ;" }, en = { "", "" } },
    { s = "fix", fr = { "", "tue les Hakkari Bloodkeeper et ramasse leur Hakkari Blood ;" }, en = { "", "" } },
    { s = "fix", fr = { "", "verse le sang sur les 4 Eternal Flame, et n'éteins la 4e qu'une fois tous les monstres morts ;" }, en = { "", "" } },
    { s = "fix", fr = { "", "restez dans le cercle intérieur, puis utilise l'œuf sur l'Avatar mort. La quête « Le dieu Hakkar » le dit aussi." }, en = { "Sunken Temple", "The Avatar of Hakkar's tactics tell the Egg of Hakkar event step by step, with Forever's pets-and-totems bug." } },
    { s = "fix", fr = { "Itharius", "Il était placé sur une autre carte. Il est dans le Marais des Chagrins, en 13.6, 71.5 (Wowhead Forever)." }, en = { "Itharius is in the Swamp of Sorrows (13.6, 71.5), not on another map.", "" } },
    { s = "fix", fr = { "Les quêtes qui commencent avec un objet", "Disent comment les prendre, sur leur ligne d'étape : « Commence avec l'objet « Serment... » : clic droit dessus dans tes sacs. »" }, en = { "A quest that starts from an item says \"right-click it in your bags\" on its step row.", "" } },
    { s = "fix", fr = { "Deux réglages des améliorations ne se coupaient pas", "« Expliquer le pourcentage » et « Ignorer les armures plus légères » restaient toujours activés, quoi qu'on choisisse." }, en = { "Two upgrade settings (\"Explain the percent\", \"Ignore lighter armor\") could not be turned off.", "" } },
  } },
  { v = "1.0.0-beta.140", date = "2026-11-18", items = {
    { s = "fix", fr = { "Temple englouti, « L'Essence d'Eranikus »", "La quête était la toute première étape dans le donjon (« En chemin »), alors que l'objet qui la donne tombe sur l'Ombre d'Eranikus, l'avant-dernier boss. Elle se prend et se rend maintenant à l'étape de l'Ombre d'Eranikus (le Réceptacle d'essence est juste à côté)." }, en = { "Sunken Temple", "\"The Essence of Eranikus\" is taken and turned in at the Shade of Eranikus' step, no longer first inside." } },
  } },
  { v = "1.0.0-beta.139", date = "2026-11-18", items = {
    { s = "fix", fr = { "La carte du donjon sur M", "Dans un donjon, la carte du Journal des donjons de Naowh (le plan avec les boss en portraits numérotés) s'affichait une fraction de seconde, puis la carte de la zone extérieure la remplaçait. Le Journal de Naowh retire sa carte dès que la carte du monde change de zone, et un autre addon (ou le jeu) la change juste après l'ouverture. WL Helper repose maintenant la carte de Naowh une fois, juste après ce changement : elle reste sur M. Rien n'est modifié dans Naowh ni dans OpenMap." }, en = { "M inside a dungeon", "Naowh's dungeon map no longer flashes away to the zone outside; WL Helper lays it again once after the map is turned." } },
  } },
  { v = "1.0.0-beta.138", date = "2026-11-18", items = {
    { s = "chg", fr = { "La carte du donjon : celle de Naowh d'abord", "Le bouton de carte du panneau des boss et /wlh carte ouvrent maintenant la carte du Journal des donjons de Naowh (le plan avec chaque boss en portrait numéroté), dans sa propre fenêtre, avant celle d'OpenMap. Sur la carte du monde, sa version par-dessus disparaissait dès qu'OpenMap remettait la zone extérieure ; sa fenêtre à elle reste." }, en = { "The dungeon map button and /wlh carte open Naowh's dungeon map (numbered boss portraits) in its own window first, before OpenMap's.", "" } },
  } },
  { v = "1.0.0-beta.137", date = "2026-11-18", items = {
    { s = "chg", fr = { "Le guide compact, refait comme RestedXP et Polestar", "Le petit suivi n'était qu'une boîte grise de trois lignes. Il montre maintenant :" }, en = { "", "" } },
    { s = "chg", fr = { "", "en haut, le nom du donjon, ses niveaux en doré, l'étape (8/43) et le pourcentage du guide ;" }, en = { "", "" } },
    { s = "chg", fr = { "", "l'étape en cours dans une carte, avec « ÉTAPE 8 · AVANT LE DONJON » en orange et l'action en gros (16 px), ses noms en couleur ;" }, en = { "", "" } },
    { s = "chg", fr = { "", "chaque objectif avec son compteur et une barre verte ;" }, en = { "", "" } },
    { s = "chg", fr = { "", "« ENSUITE » et les 3 actions suivantes en texte normal ;" }, en = { "", "" } },
    { s = "chg", fr = { "", "la barre de progression du guide en bas, avec le pourcentage." }, en = { "The compact guide redone after RestedXP and Polestar", "Header with levels, step and percent; the step's card with its orange label, coloured names and green objective bars; \"Then\" and the next 3 actions; the guide's progress bar." } },
    { s = "chg", fr = { "Un vrai bouton « Compact »", "À la place du « − » dans la fenêtre du guide : il passe au guide compact. Un clic sur le titre du guide compact ramène la grande fenêtre." }, en = { "A labelled \"Compact\" button replaces the guide window's \"−\".", "" } },
  } },
  { v = "1.0.0-beta.136", date = "2026-11-18", items = {
    { s = "add", fr = { "Quel donjon farmer pour ton équipement", "Chaque donjon compte ce que son butin a pour toi. D'abord les objets de ta liste BiS de Naowh (1er et 2e choix), puis les améliorations d'au moins 5 % selon WL Helper (cap de toucher, défense, montée de niveau). Les objets que tu as déjà (portés, sacs, banque) et ceux à plus de 4 niveaux au-dessus de toi ne comptent pas. Ça s'affiche en doré sur les cartes du choix de donjon du guide (« 3 BiS pour toi · 2 améliorations ») et sur celles de Trouver un groupe (« Ta route · 3 BiS »). /wlh farm donne dans le chat les 5 meilleurs donjons à ton niveau. Le décompte se refait quand ton équipement, tes sacs, ton niveau ou ta liste Naowh changent." }, en = { "Which dungeon to farm", "Each dungeon counts your Naowh BiS picks and WL Helper's upgrades of 5 % or more in its loot; shown on the dungeon cards, and /wlh farm lists the best 5." } },
  } },
  { v = "1.0.0-beta.135", date = "2026-11-18", items = {
    { s = "add", fr = { "GPS avec Shortest Path, tes portails de mage", "Shortest Path ne connaît pas les portails que tu ouvres toi-même (Rune des portails). Quand notre GPS trouve un trajet qui commence par ta téléportation ou ton portail et qui fait gagner au moins 2 minutes sur celui de Shortest Path, la flèche le propose avec le bouton pour le lancer et dit combien tu gagnes (« Plus rapide que le trajet de Shortest Path : ~25 min de moins »). Une fois arrivé, Shortest Path refait son trajet depuis là." }, en = { "GPS with Shortest Path's route", "A mage teleport or portal of ours that saves 2+ minutes is offered with its cast button." } },
  } },
  { v = "1.0.0-beta.134", date = "2026-11-18", items = {
    { s = "fix", fr = { "GPS avec Shortest Path, le bouton de la pierre de foyer", "Quand le trajet de Shortest Path commence par ta pierre de foyer, Rappel astral ou une téléportation de mage, notre flèche affiche maintenant le bouton pour la lancer, comme sur notre propre trajet. La ligne d'en dessous dit la suite (« Puis Walk to Grom'gol... »). Shortest Path ne donne pas le sort par son API : WL Helper le reconnaît au texte de l'étape." }, en = { "GPS with Shortest Path's route", "The Hearthstone, Astral Recall or a mage teleport gets our cast button." } },
  } },
  { v = "1.0.0-beta.133", date = "2026-11-18", items = {
    { s = "add", fr = { "Taille des fenêtres", "Un seul réglage pour la taille de toutes les fenêtres de WL Helper (le guide, le suivi, le Comptoir, les groupes, la guilde, les réglages), de 60 % à 150 %. Dans Options > Général, sous la langue (« Taille de toutes les fenêtres »), ou en commande : /wlh taille 90, /wlh taille +, /wlh taille - (10 % de plus ou de moins). Chaque fenêtre garde son coin haut-gauche à sa place. En combat, le changement attend la fin du combat. La flèche du GPS garde son propre réglage (page GPS)." }, en = { "Window size", "One setting for every WL Helper window, 60 % to 150 % (Options > General, or /wlh size 90 / + / -)." } },
  } },
  { v = "1.0.0-beta.132", date = "2026-11-18", items = {
    { s = "fix", fr = { "Guide, dans la zone c'est dans la zone", "Dans une zone de monstres aux apparitions espacées (les Sirènes Fouette-bile d'Azshara pour « Le corail des sirènes »), la flèche t'envoyait encore à l'apparition la plus proche, à 100 m, alors que tu étais au milieu. Dans la zone, la flèche dit maintenant que tu y es tant qu'une apparition est à moins de 120 m (avant : 40). Le bassin des larmes garde 40 m : son île au milieu n'a pas de monstre." }, en = { "Guide", "Inside a mob area, you are \"there\" within 120 yd of a spawn (was 40); the Pool of Tears' island keeps 40." } },
  } },
  { v = "1.0.0-beta.131", date = "2026-11-18", items = {
    { s = "chg", fr = { "GPS, une seule flèche avec Shortest Path", "Avec « Avec la flèche de WL Helper », la flèche de Shortest Path et ses étapes dans le suivi des objectifs se coupent toutes seules (dans ses réglages). Tes réglages reviennent quand tu enlèves l'option ou que tu choisis un autre GPS. Plus rien à couper à la main." }, en = { "GPS", "Shortest Path's own arrow and journey tracker are turned off while our arrow shows its route, and given back after." } },
  } },
  { v = "1.0.0-beta.130", date = "2026-11-18", items = {
    { s = "add", fr = { "GPS, le trajet de Shortest Path avec notre flèche", "Avec « Envoyer les destinations à Shortest Path », la nouvelle option « Avec la flèche de WL Helper » (activée par défaut) garde notre flèche. Shortest Path calcule le trajet ; notre flèche vise son prochain point et dit son étape en cours, puis la suivante, les étapes d'après, la destination et le temps restant. Pour n'avoir que notre flèche, coupe celle de Shortest Path et son suivi de trajet dans ses propres réglages (Interface : la flèche ; Guidance : les étapes dans le suivi des objectifs). Option coupée : l'interface de Shortest Path, comme avant." }, en = { "GPS", "Shortest Path's route shown by WL Helper's arrow (new option, on by default)." } },
  } },
  { v = "1.0.0-beta.129", date = "2026-11-18", items = {
    { s = "add", fr = { "GPS, retour au cadavre", "Mort et libéré (fantôme), la flèche t'emmène à ton cadavre (« Ton cadavre »). Une fois ressuscité, elle reprend l'étape du guide ou le trajet que tu suivais. Ça marche aussi après un /reload en fantôme." }, en = { "GPS", "As a ghost, the arrow takes you to your corpse, then back to the step or trip you followed." } },
  } },
  { v = "1.0.0-beta.128", date = "2026-11-18", items = {
    { s = "fix", fr = { "GPS, la tour de l'archimage Xylem (Azshara)", "Aucun chemin ne monte en haut de sa tour, et la flèche partait dans les falaises. Elle t'envoie maintenant à Sanath Lim-yo, au pied de la tour (28.1, 50.1) : parle-lui, il te téléporte en haut. Une fois en haut, la flèche passe à Xylem. Les étapes des quêtes de mage de Xylem le disent aussi." }, en = { "GPS", "Archmage Xylem's tower has no path up: the arrow goes to Sanath Lim-yo at its foot, who teleports you up." } },
  } },
  { v = "1.0.0-beta.127", date = "2026-11-18", items = {
    { s = "add", fr = { "GPS, choisir entre Shortest Path et WL Helper", "Si Shortest Path est installé, une fenêtre demande une seule fois quel GPS suivre. « Shortest Path » : il prend tes destinations (son trajet sur la carte, ses vols, ses bateaux avec leurs départs, sa flèche) et notre flèche s'efface. « WL Helper » : notre GPS, comme avant. Le choix se change dans Options > GPS (« Envoyer les destinations à Shortest Path »), et le trajet en cours passe tout de suite à celui choisi." }, en = { "GPS", "With Shortest Path installed, asked once which GPS to follow; switching moves the trip under way at once." } },
  } },
}
