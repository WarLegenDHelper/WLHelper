-- WhatsNew.lua: generated from CHANGELOG.md by the release (make_whatsnew.py; do not edit by hand).
-- Per version: v, date, items = { { s = "add"|"chg"|"fix", fr = { title, text }, en = { title, text } } }
local _, ns = ...
ns.WHATSNEW = {
  { v = "1.0.0-beta.111", date = "2026-11-17", items = {
    { s = "fix", fr = { "Quêtes du guide vérifiées sur Wowhead Forever", "Les 526 quêtes du guide ont été lues une à une sur Wowhead Forever et comparées à nos données. 82 corrections :" }, en = { "", "" } },
    { s = "fix", fr = { "", "faction : 14 quêtes réservées à la Horde ou à l'Alliance étaient données pour les deux (ou l'inverse, comme Da Voodoo) ;" }, en = { "", "" } },
    { s = "fix", fr = { "", "niveau et niveau requis : 17 quêtes (Ruines de Lordaeron, Horn of Xelthos, Blood Red Bandanas...) ;" }, en = { "", "" } },
    { s = "fix", fr = { "", "partage en groupe : 36 quêtes ;" }, en = { "", "" } },
    { s = "fix", fr = { "", "noms de Forever : The Great Ezra Grimm (au lieu de Fras Siabi), Pip Quickwit (au lieu de Finkle Einhorn), Velarok Windblade, Scarshield Infiltrator, The Eastern Kingdoms, Connery's Trunk ;" }, en = { "", "" } },
    { s = "fix", fr = { "", "qui donne la quête : The Key to Scholomance (Apothecary Dithers), Heed My Call (Rau Cliffrunner, Freewind Post) ;" }, en = { "", "" } },
    { s = "fix", fr = { "", "prérequis : The Stone Circle, Grark Lorkrub, Lord Banehollow." }, en = { "All 526 guide quests checked page by page on Wowhead Forever: 82 fixes (factions, levels, sharing, Forever names, givers, prerequisites).", "" } },
  } },
  { v = "1.0.0-beta.110", date = "2026-11-17", items = {
    { s = "chg", fr = { "Choisir un guide", "Un clic sur une carte ouvre la vue d'ensemble de ce donjon, et « Lancer le guide » y remplace le guide en cours. Pour enchaîner plusieurs donjons en une seule route, coche la case de chaque carte puis « Combiner les N guides » en bas. Le guide en cours n'est plus coché d'office : sa carte a un contour vert et sa bulle dit « Guide en cours »." }, en = { "Pick a guide", "Click a card to open it alone; tick boxes to combine several." } },
    { s = "fix", fr = { "Améliorations (WL Helper Gear), le toucher", "Le toucher de l'objet porté n'est plus compté deux fois. Avant, échanger deux colliers pouvait donner +46 % dans un sens et -1 % dans l'autre ; les deux pièces sont maintenant jugées depuis ton toucher sans l'une ni l'autre." }, en = { "Gear", "The worn piece's hit no longer skews the comparison (same swap, same verdict both ways)." } },
    { s = "fix", fr = { "Prison d'Alcaz, « More Valuable Than Gold »", "Plus d'étape « Faire » dans le donjon ; le trésor de Mason se trouve sous le plancher de l'auberge de Moonbrook, l'étape « Rendre » y mène." }, en = { "Alcaz Prison", "No inside \"do\" step for Mason's treasure." } },
  } },
  { v = "1.0.0-beta.109", date = "2026-11-17", items = {
    { s = "chg", fr = { "Guide, étapes dans le donjon", "Beaucoup moins de texte répété. Pour chaque quête, la place dans la suite (« Étape 5 sur 6 avant... »), la phrase d'objectif et la note ne s'affichent plus que sur sa première ligne de l'étape ; « À prendre » n'est plus répété sur ses lignes « Faire » et « Rendre » (la ligne « Accepter » le dit déjà). L'étape tient en bien moins de hauteur." }, en = { "Guide, dungeon steps", "Chain place, objective and note shown once per quest; no repeated \"To take\"." } },
  } },
  { v = "1.0.0-beta.108", date = "2026-11-17", items = {
    { s = "fix", fr = { "Aperçu du donjon, bulle d'une récompense", "L'amélioration n'apparaît plus deux fois avec deux pourcentages différents. La ligne « WL Helper » de l'objet suffit ; quand la quête est d'un niveau plus haut que toi, une ligne dit le gain à ce niveau (« Au niveau 53 (celui de la quête) : +51 % »), le chiffre affiché sous l'icône." }, en = { "Dungeon overview", "The reward tooltip no longer repeats the upgrade with two different percents." } },
    { s = "fix", fr = { "Items of Power (Mage, quête 1948)", "Demande la quête 1951, comme sur Wowhead Forever." }, en = { "Quest 1948 now needs 1951, as on Wowhead Forever.", "" } },
  } },
  { v = "1.0.0-beta.107", date = "2026-11-17", items = {
    { s = "add", fr = { "Trouver un groupe, langues", "Deux boutons « Toutes » et « Aucune » au-dessus des langues dans les filtres, pour voir les groupes de toutes les langues d'un clic (celles que le jeu impose restent cochées)." }, en = { "Group finder", "\"All\" / \"None\" for the languages." } },
  } },
  { v = "1.0.0-beta.106", date = "2026-11-17", items = {
    { s = "add", fr = { "Relevés en jeu, suite", "WL Helper note aussi où un objectif de quête du guide avance vraiment (l'endroit où le compteur monte, dedans ou dehors l'instance ; 12 endroits au plus par objectif), les récompenses que la fenêtre de quête propose, et l'ordre dans lequel les boss meurent dans chaque donjon (les 5 dernières sorties). Ça sert à corriger les points sur la carte et l'ordre des boss du guide." }, en = { "Records where objectives really progress, the quest rewards offered, and boss kill order per dungeon.", "" } },
  } },
  { v = "1.0.0-beta.105", date = "2026-11-17", items = {
    { s = "add", fr = { "Relevés de quêtes en jeu", "Comme le Wowhead Client, WL Helper note ce que le jeu montre vraiment pour les quêtes du guide (qui la donne et où, qui la reprend, son niveau, l'XP reçue sans pénalité de niveau, et les prérequis listés que tu n'avais pas faits quand tu l'as prise). Ces relevés sont partagés avec la guilde et servent à corriger les données du guide. « /wlh diag quetes » montre ce qui diffère." }, en = { "In-game quest records (giver, turn-in, level, full XP, unneeded prerequisites), shared with the guild; /wlh diag quests.", "" } },
    { s = "fix", fr = { "Le Temple englouti (Alliance)", "3 650 XP, comme sur Wowhead Forever (pas 6 550, la valeur de la version Horde)." }, en = { "Alliance \"The Sunken Temple\"", "3,650 XP." } },
  } },
  { v = "1.0.0-beta.104", date = "2026-11-17", items = {
    { s = "fix", fr = { "Temple englouti côté Alliance", "« Dans les profondeurs » et « Le secret du cercle » demandaient la quête Horde de Feralas (Docteur sorcier Uzer'i), donc l'Alliance ne les voyait jamais. Chaque faction a maintenant sa propre quête d'accroche : Uzer'i (Camp Mojache) pour la Horde, Angelas Moonbreeze (Forteresse de Pennelune, Feralas) pour l'Alliance." }, en = { "Sunken Temple", "Each faction gets its own lead-in quest." } },
    { s = "add", fr = { "Quêtes Alliance manquantes", "Uldaman (Rechercher les composants à Uldaman et sa suite, Des Trésors à recouvrer, La Chambre secrète, la chaîne du collier de Talvash, La tablette de volonté), Maraudon (Fragments d'Ombréclat pour Theramore, Corruption de la terre et de la graine pour la Pointe de Nijel), Temple englouti (La brume du mal et ses deux étapes)." }, en = { "Missing Alliance quests in Uldaman, Maraudon and Sunken Temple.", "" } },
  } },
  { v = "1.0.0-beta.103", date = "2026-11-17", items = {
    { s = "chg", fr = { "« Presque pareil »", "Quand deux objets ne diffèrent que de quelques points de ta stat principale (5 de puissance des sorts, 8 de soins, 10 de puissance d'attaque, 5 d'endurance pour un tank), l'infobulle dit « Presque pareil (-14 %) » en gris et « Seulement ~4 de puissance des sorts d'écart : garde celui que tu préfères », au lieu d'un pourcentage rouge qui fait peur." }, en = { "Near ties read \"About the same (-14%)\" with the gap in points of your main stat.", "" } },
    { s = "chg", fr = { "Réglages > Améliorations, les vrais poids", "Quand WL Helper Gear juge tes objets, la page montre ses poids (ta spé, ton niveau, ce que tu portes, plafonds de toucher compris), pas les poids de secours de WL Helper." }, en = { "Settings show WL Helper Gear's weights when it judges.", "" } },
  } },
  { v = "1.0.0-beta.102", date = "2026-11-17", items = {
    { s = "fix", fr = { "Bonus aux sorts mieux lus (WLHelper Gear)", "Sur un objet que la liste ne connaît pas (ou avec un suffixe), « Augmente les dégâts et les soins produits par les sorts » compte pour les dégâts et les soins, même sur un client français, au lieu de compter parfois comme des soins seulement." }, en = { "\"Damage and healing\" spell power is read as spell power for both, French client too.", "" } },
  } },
  { v = "1.0.0-beta.101", date = "2026-11-17", items = {
    { s = "chg", fr = { "Vrai réseau de vols", "Le GPS connaît maintenant le réseau des maîtres de vol de Forever et la durée mesurée de chaque saut (données de Shortest Path Forever, sous GPL, dans le module WLHelper Nav). Un vol passe par les maîtres de vol que tu connais, avec son vrai temps, au lieu d'une ligne droite ; deux maîtres de vol non reliés ne sont plus proposés." }, en = { "Real flight network with measured times (from Shortest Path Forever, GPL, in WLHelper Nav).", "" } },
  } },
  { v = "1.0.0-beta.100", date = "2026-11-17", items = {
    { s = "chg", fr = { "Route réordonnée selon ta position", "Quand tu arrives dans une nouvelle zone (à pied, après un vol ou un téléport), les étapes qui restent sont remises dans l'ordre depuis là où tu es, pour éviter les allers-retours. Pas pendant un vol ni dans un donjon, au plus une fois toutes les 30 s." }, en = { "Remaining steps are reordered from your position when you enter a new zone.", "" } },
  } },
  { v = "1.0.0-beta.99", date = "2026-11-17", items = {
    { s = "fix", fr = { "La flèche suit l'étape affichée", "« Étape suivante », les flèches ‹ › ou un clic dans la liste des étapes déplacent aussi le GPS ; « Revenir à l'étape en cours » le ramène." }, en = { "The arrow follows the step on screen.", "" } },
  } },
  { v = "1.0.0-beta.98", date = "2026-11-17", items = {
    { s = "fix", fr = { "GPS dans un donjon", "Une étape dans l'instance n'envoie plus vers un point de la carte du dehors (le repère tombait sur un mur et la flèche disait « Tu y es · Maraudon ») ; sans point sur la carte du donjon, le grand bouton propose « Carte du donjon »." }, en = { "Inside a dungeon, the GPS no longer points at an outdoor spot.", "" } },
  } },
  { v = "1.0.0-beta.97", date = "2026-11-17", items = {
    { s = "fix", fr = { "Quête qui commence avec un objet", "Si elle n'est pas dans ton journal, la carte dit quel objet l'ouvre (« utilise-le dans tes sacs ; si tu ne l'as pas, passe cette étape ») au lieu de « prends-la d'abord »." }, en = { "Item-started quests say which item opens them.", "" } },
    { s = "fix", fr = { "Quêtes grises facultatives", "Aussi laissées de côté quand la route est calculée sans ouvrir la vue d'ensemble." }, en = { "Grey optional quests stay out of every route.", "" } },
  } },
}
