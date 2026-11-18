# Changelog

Toutes les versions de WL Helper. Format : [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/),
numéros : [SemVer](https://semver.org/lang/fr/) (voir « Versions » dans le README).
*All WL Helper versions. Format: Keep a Changelog; numbers: SemVer (see "Versions" in the README).*

## [Unreleased]

## [1.0.0-beta.121] — 2026-11-18

### Modifié / Changed
- **Guide, la route suit ta position** : toutes les 5 secondes, si tu es à plus de 400 mètres de l'endroit d'où la route a été calculée, les étapes restantes sont remises dans l'ordre depuis là où tu es (toujours en respectant l'ordre obligatoire des quêtes, puis le chemin le plus court). Ça couvre la pierre de foyer, un portail, un bateau ou une longue course dans la même zone, qui ne déclenchaient rien. Pas en combat, pas en vol, pas en donjon ; pas à chaque pas, pour que la flèche ne saute pas d'une étape à l'autre.
  *The guide re-orders the steps left from where you are once you are 400 yards from where the route was planned (hearthstone, portal, boat, long ride).*

## [1.0.0-beta.120] — 2026-11-18

### Corrigé / Fixed
- **Guide, après un vol** : le guide remet les étapes dans l'ordre à l'atterrissage. Avant, une route calculée au départ (par exemple à Camp Mojache en Féralas, en prenant « The Sunken Temple ») restait telle quelle après le vol : arrivé à Gadgetzan, le GPS t'envoyait chez Larion à Un'Goro au lieu de te faire rendre la quête à Marvon, tout près.
  *The guide re-orders its steps when a flight lands (a route planned in Feralas no longer sends you to Un'Goro past Marvon's turn-in).*

### Ajouté / Added
- **Chaîne d'Anthion côté Alliance** : les quêtes de Deliana à Forgefer (An Earnest Proposition, A Supernatural Device, Return to Deliana, Just Compensation, In Search of Anthion, Anthion's Parting Words, Bodley's Unfortunate Fate), une par classe dont le paladin, lues sur Wowhead Forever. La version Alliance demande 15 Winterspring Blood Sample (Frostsaber de Berceau-de-l'Hiver), pas le venin de Silithus. Les quêtes communes (The Challenge, Dead Man's Plea, les morceaux d'amulette de Valthalak) s'ouvrent maintenant aussi pour l'Alliance, avec la version de ta faction et de ta classe.
  *The Alliance Anthion chain (Deliana, Ironforge), every class including paladin; the shared Valthalak quests now open for the Alliance.*

## [1.0.0-beta.119] — 2026-11-18

### Modifié / Changed
- **Trouver un groupe, résultats plus lisibles** : chaque ligne est plus haute, le nom plus grand, et les détails (niveau ou places, donjon, zone, depuis quand) juste en dessous dans une taille lisible, au lieu d'une petite colonne au milieu. Les rôles s'affichent en 5 grosses icônes : pour un groupe, une par place (tank, soigneur, 3 dégâts), allumée si elle est prise, pâle si elle est libre, comme dans LFG Forever ; pour un joueur, les rôles qu'il propose.
  *Find a group: taller rows, bigger names, details under them, and 5 big role slots (taken bright, free faint).*

## [1.0.0-beta.118] — 2026-11-18

### Ajouté / Added
- **GPS, repères de la carte** : un repère posé sur la carte du monde lance le GPS de WL Helper jusque-là (flèche et chemin à pied), qu'il soit posé par toi (Ctrl-clic) ou par un autre addon qui pose le repère du jeu, comme les livres, coffres et rares de Naowh Forever (« Click for a waypoint »). Repère enlevé : le GPS s'arrête. Jamais les repères que WL Helper pose lui-même, rien en donjon. Réglages > GPS > « Suivre les repères de la carte » pour l'éteindre.
  *GPS follows map pins (yours or another addon's, like Naowh's books); Settings > GPS to turn it off.*

## [1.0.0-beta.117] — 2026-11-18

### Corrigé / Fixed
- **Guide, étapes de boss** : une étape de boss dont toutes les quêtes sont rendues compte comme faite, même si le guide n'a pas vu le boss mourir (tué avant un /reload ou une déconnexion). Avant, l'onglet « Dans le donjon » pouvait rester à 8 sur 9 alors que tout était fait (Prison d'Alcaz, Tidemistress Ca'zass).
  *Boss steps whose quests are all turned in count as done, even without a kill seen this session.*

## [1.0.0-beta.116] — 2026-11-18

### Ajouté / Added
- **Meilleur pour toi** : tape « /wlh bis » (ou « /wlh bis 60 » pour un autre niveau). Pour chaque emplacement, les 3 meilleures pièces que tu peux porter, classées par WL Helper Gear pour ta spé avec tes vraies stats, tes talents et tes plafonds de toucher ; le gain sur ce que tu portes, et d'où vient la pièce (donjon et boss, quête, métier, réputation ; les pièces PvP renvoient à « /wlh pvp »). Les raids sont laissés de côté tant qu'ils ne sont pas ouverts. La liste est calculée, pas recopiée d'un guide : Forever a changé beaucoup d'objets.
  *Best for you (/wlh bis [level]): the top 3 pieces per slot for your spec, computed by WL Helper Gear, with the gain and the source.*

## [1.0.0-beta.115] — 2026-11-18

### Corrigé / Fixed
- **XP des quêtes** : 128 quêtes affichaient l'XP de base, sans le bonus de Forever (souvent x1,75 à x2,7). Elles ont maintenant l'XP réelle, celle de Wowhead Forever, la même qu'en jeu (Blood Red Bandanas : 9 700 XP). Les totaux d'XP du guide et de la vue d'ensemble sont donc bien plus justes.
  *Quest XP: 128 quests showed the base XP without Forever's bonus; they now show the real XP (Wowhead Forever, as in game).*
- **Quêtes ajoutées** : An Ambassador of Evil (Alliance, Ironforge, avant The Lost Tablets of Will à Uldaman) et Elven Legends côté Alliance (Scholar Runethorn, Feathermoon) ; les librams de Hache-tripes s'ouvrent maintenant aussi à l'Alliance.
  *Added An Ambassador of Evil and the Alliance Elven Legends (Dire Maul librams open to the Alliance).*

## [1.0.0-beta.114] — 2026-11-17

### Ajouté / Added
- **Guide PvP** : tape « /wlh pvp ». Pour ta classe, chaque pièce du set PvP bleu « Premier » (niveau d'objet 60, dès le niveau 55) avec son prix en honneur et en marques, ce qu'il te manque d'après ton honneur et tes marques, le total pour le set, et le champ de bataille à faire en premier (celui dont il te manque le plus de marques). Quand une classe a plusieurs sets (druide, chaman, prêtre, paladin), WL Helper Gear choisit le meilleur pour ta spé et nomme les autres. Puis la quête Field of Honor (Wizzik Dustfizz à Gadgetzan) et les sceaux « Emboldened » qui rendent une pièce épique plus tard.
  Prix lus sur Wowhead Forever (vendeur Lady Palanseer) : tête 9 000 honneur + 15 marques d'Alterac, torse 9 350 + 15 Arathi, jambes 9 000 + 15 Goulet, épaules 6 350 + 10 Arathi, mains 7 500 + 10 Goulet, pieds 7 500 + 10 Îles Darkspear, taille 6 000 + 10 Arathi, poignets 4 500 + 10 Goulet.
  *PvP guide (/wlh pvp): the rare PvP set for your class, its Forever prices (Wowhead), what you still miss, which battleground first, Field of Honor.*

## [1.0.0-beta.113] — 2026-11-17

### Ajouté / Added
- **Trouver un groupe, raccourci clavier** : « Ouvrir Trouver un groupe » dans Échap > Options > Raccourcis > AddOns > WL Helper.
  *Find a group: a key binding.*
- **Trouver un groupe, joueurs qui quittent** : clic droit sur un nom > « A quitté un donjon en cours ». La marque se cumule ; elle s'affiche dans la bulle du joueur dans les résultats, et une ligne dans le chat te prévient quand il rejoint ton groupe. Le jeu cache les noms en donjon, donc l'addon ne devine jamais qui est parti : c'est toi qui marques.
  *Find a group: mark players who left a dungeon mid-run (by hand; names are hidden in instances).*

### Corrigé / Fixed
- **Prérequis par classe** (chaînes d'Anthion et de Lord Valthalak, Stratholme et Blackrock) : quand une quête demande « la version de ta classe » d'une autre (An Earnest Proposition, Just Compensation, Anthion's Parting Words), seule celle de ta classe compte. Avant, ces quêtes restaient fermées pour tout le monde. A Supernatural Device, In Search of Anthion et Bodley's Unfortunate Fate ont leurs prérequis de Wowhead Forever.
  *Class-variant prerequisites: only your class's version counts (Anthion and Valthalak chains open again).*

## [1.0.0-beta.112] — 2026-11-17

### Modifié / Changed
- **Améliorations, « Presque pareil »** : seulement sous 10 %. À partir de 10 %, le pourcentage reste affiché en vert ou en rouge (« +12 % » est une vraie amélioration), avec en dessous l'écart réel en points (« Écart réel : ~2 de puissance des sorts seulement. »).
  *Upgrades: "About the same" only under 10 %; from 10 % the percent stays, with the real gap in points under it.*

## [1.0.0-beta.111] — 2026-11-17

### Corrigé / Fixed
- **Quêtes du guide vérifiées sur Wowhead Forever** : les 526 quêtes du guide ont été lues une à une sur Wowhead Forever et comparées à nos données. 82 corrections :
  - faction : 14 quêtes réservées à la Horde ou à l'Alliance étaient données pour les deux (ou l'inverse, comme Da Voodoo) ;
  - niveau et niveau requis : 17 quêtes (Ruines de Lordaeron, Horn of Xelthos, Blood Red Bandanas...) ;
  - partage en groupe : 36 quêtes ;
  - noms de Forever : The Great Ezra Grimm (au lieu de Fras Siabi), Pip Quickwit (au lieu de Finkle Einhorn), Velarok Windblade, Scarshield Infiltrator, The Eastern Kingdoms, Connery's Trunk ;
  - qui donne la quête : The Key to Scholomance (Apothecary Dithers), Heed My Call (Rau Cliffrunner, Freewind Post) ;
  - prérequis : The Stone Circle, Grark Lorkrub, Lord Banehollow.
  *All 526 guide quests checked page by page on Wowhead Forever: 82 fixes (factions, levels, sharing, Forever names, givers, prerequisites).*

## [1.0.0-beta.110] — 2026-11-17

### Modifié / Changed
- **Choisir un guide** : un clic sur une carte ouvre la vue d'ensemble de ce donjon, et « Lancer le guide » y remplace le guide en cours. Pour enchaîner plusieurs donjons en une seule route, coche la case de chaque carte puis « Combiner les N guides » en bas. Le guide en cours n'est plus coché d'office : sa carte a un contour vert et sa bulle dit « Guide en cours ».
  *Pick a guide: click a card to open it alone; tick boxes to combine several.*

### Corrigé / Fixed
- **Améliorations (WL Helper Gear), le toucher** : le toucher de l'objet porté n'est plus compté deux fois. Avant, échanger deux colliers pouvait donner +46 % dans un sens et -1 % dans l'autre ; les deux pièces sont maintenant jugées depuis ton toucher sans l'une ni l'autre.
  *Gear: the worn piece's hit no longer skews the comparison (same swap, same verdict both ways).*
- **Prison d'Alcaz, « More Valuable Than Gold »** : plus d'étape « Faire » dans le donjon ; le trésor de Mason se trouve sous le plancher de l'auberge de Moonbrook, l'étape « Rendre » y mène.
  *Alcaz Prison: no inside "do" step for Mason's treasure.*

## [1.0.0-beta.109] — 2026-11-17

### Modifié / Changed
- **Guide, étapes dans le donjon** : beaucoup moins de texte répété. Pour chaque quête, la place dans la suite (« Étape 5 sur 6 avant... »), la phrase d'objectif et la note ne s'affichent plus que sur sa première ligne de l'étape ; « À prendre » n'est plus répété sur ses lignes « Faire » et « Rendre » (la ligne « Accepter » le dit déjà). L'étape tient en bien moins de hauteur.
  *Guide, dungeon steps: chain place, objective and note shown once per quest; no repeated "To take".*

## [1.0.0-beta.108] — 2026-11-17

### Corrigé / Fixed
- **Aperçu du donjon, bulle d'une récompense** : l'amélioration n'apparaît plus deux fois avec deux pourcentages différents. La ligne « WL Helper » de l'objet suffit ; quand la quête est d'un niveau plus haut que toi, une ligne dit le gain à ce niveau (« Au niveau 53 (celui de la quête) : +51 % »), le chiffre affiché sous l'icône.
  *Dungeon overview: the reward tooltip no longer repeats the upgrade with two different percents.*
- **Items of Power (Mage, quête 1948)** : demande la quête 1951, comme sur Wowhead Forever.
  *Quest 1948 now needs 1951, as on Wowhead Forever.*

## [1.0.0-beta.107] — 2026-11-17

### Ajouté / Added
- **Trouver un groupe, langues** : deux boutons « Toutes » et « Aucune » au-dessus des langues dans les filtres, pour voir les groupes de toutes les langues d'un clic (celles que le jeu impose restent cochées).
  *Group finder: "All" / "None" for the languages.*

## [1.0.0-beta.106] — 2026-11-17

### Ajouté / Added
- **Relevés en jeu, suite** : WL Helper note aussi où un objectif de quête du guide avance vraiment (l'endroit où le compteur monte, dedans ou dehors l'instance ; 12 endroits au plus par objectif), les récompenses que la fenêtre de quête propose, et l'ordre dans lequel les boss meurent dans chaque donjon (les 5 dernières sorties). Ça sert à corriger les points sur la carte et l'ordre des boss du guide.
  *Records where objectives really progress, the quest rewards offered, and boss kill order per dungeon.*

## [1.0.0-beta.105] — 2026-11-17

### Ajouté / Added
- **Relevés de quêtes en jeu** : comme le Wowhead Client, WL Helper note ce que le jeu montre vraiment pour les quêtes du guide (qui la donne et où, qui la reprend, son niveau, l'XP reçue sans pénalité de niveau, et les prérequis listés que tu n'avais pas faits quand tu l'as prise). Ces relevés sont partagés avec la guilde et servent à corriger les données du guide. « /wlh diag quetes » montre ce qui diffère.
  *In-game quest records (giver, turn-in, level, full XP, unneeded prerequisites), shared with the guild; /wlh diag quests.*

### Corrigé / Fixed
- **Le Temple englouti (Alliance)** : 3 650 XP, comme sur Wowhead Forever (pas 6 550, la valeur de la version Horde).
  *Alliance "The Sunken Temple": 3,650 XP.*

## [1.0.0-beta.104] — 2026-11-17

### Corrigé / Fixed
- **Temple englouti côté Alliance** : « Dans les profondeurs » et « Le secret du cercle » demandaient la quête Horde de Feralas (Docteur sorcier Uzer'i), donc l'Alliance ne les voyait jamais. Chaque faction a maintenant sa propre quête d'accroche : Uzer'i (Camp Mojache) pour la Horde, Angelas Moonbreeze (Forteresse de Pennelune, Feralas) pour l'Alliance.
  *Sunken Temple: each faction gets its own lead-in quest.*

### Ajouté / Added
- **Quêtes Alliance manquantes** (vérifiées avec les données du jeu et Naowh) : Uldaman (Rechercher les composants à Uldaman et sa suite, Des Trésors à recouvrer, La Chambre secrète, la chaîne du collier de Talvash, La tablette de volonté), Maraudon (Fragments d'Ombréclat pour Theramore, Corruption de la terre et de la graine pour la Pointe de Nijel), Temple englouti (La brume du mal et ses deux étapes).
  *Missing Alliance quests in Uldaman, Maraudon and Sunken Temple.*

## [1.0.0-beta.103] — 2026-11-17

### Modifié / Changed
- **« Presque pareil »** : quand deux objets ne diffèrent que de quelques points de ta stat principale (5 de puissance des sorts, 8 de soins, 10 de puissance d'attaque, 5 d'endurance pour un tank), l'infobulle dit « Presque pareil (-14 %) » en gris et « Seulement ~4 de puissance des sorts d'écart : garde celui que tu préfères », au lieu d'un pourcentage rouge qui fait peur.
  *Near ties read "About the same (-14%)" with the gap in points of your main stat.*
- **Réglages > Améliorations, les vrais poids** : quand WL Helper Gear juge tes objets, la page montre ses poids (ta spé, ton niveau, ce que tu portes, plafonds de toucher compris), pas les poids de secours de WL Helper.
  *Settings show WL Helper Gear's weights when it judges.*

## [1.0.0-beta.102] — 2026-11-17

### Corrigé / Fixed
- **Bonus aux sorts mieux lus (WLHelper Gear)** : sur un objet que la liste ne connaît pas (ou avec un suffixe), « Augmente les dégâts et les soins produits par les sorts » compte pour les dégâts et les soins, même sur un client français, au lieu de compter parfois comme des soins seulement.
  *"Damage and healing" spell power is read as spell power for both, French client too.*

## [1.0.0-beta.101] — 2026-11-17

### Modifié / Changed
- **Vrai réseau de vols** : le GPS connaît maintenant le réseau des maîtres de vol de Forever et la durée mesurée de chaque saut (données de Shortest Path Forever, sous GPL, dans le module WLHelper Nav). Un vol passe par les maîtres de vol que tu connais, avec son vrai temps, au lieu d'une ligne droite ; deux maîtres de vol non reliés ne sont plus proposés.
  *Real flight network with measured times (from Shortest Path Forever, GPL, in WLHelper Nav).*

## [1.0.0-beta.100] — 2026-11-17

### Modifié / Changed
- **Route réordonnée selon ta position** : quand tu arrives dans une nouvelle zone (à pied, après un vol ou un téléport), les étapes qui restent sont remises dans l'ordre depuis là où tu es, pour éviter les allers-retours. Pas pendant un vol ni dans un donjon, au plus une fois toutes les 30 s.
  *Remaining steps are reordered from your position when you enter a new zone.*

## [1.0.0-beta.99] — 2026-11-17

### Corrigé / Fixed
- **La flèche suit l'étape affichée** : « Étape suivante », les flèches ‹ › ou un clic dans la liste des étapes déplacent aussi le GPS ; « Revenir à l'étape en cours » le ramène.
  *The arrow follows the step on screen.*

## [1.0.0-beta.98] — 2026-11-17

### Corrigé / Fixed
- **GPS dans un donjon** : une étape dans l'instance n'envoie plus vers un point de la carte du dehors (le repère tombait sur un mur et la flèche disait « Tu y es · Maraudon ») ; sans point sur la carte du donjon, le grand bouton propose « Carte du donjon ».
  *Inside a dungeon, the GPS no longer points at an outdoor spot.*

## [1.0.0-beta.97] — 2026-11-17

### Corrigé / Fixed
- **Quête qui commence avec un objet** (ex. « L'Essence d'Eranikus » à rendre à Itharius) : si elle n'est pas dans ton journal, la carte dit quel objet l'ouvre (« utilise-le dans tes sacs ; si tu ne l'as pas, passe cette étape ») au lieu de « prends-la d'abord ».
  *Item-started quests say which item opens them.*
- **Quêtes grises facultatives** : aussi laissées de côté quand la route est calculée sans ouvrir la vue d'ensemble.
  *Grey optional quests stay out of every route.*

## [1.0.0-beta.96] — 2026-11-17

### Ajouté / Added
- **Donjon conseillé bien visible** : la première carte de « À faire à ton niveau » porte le badge « Conseillé pour toi » quand elle convient nettement mieux que la suivante ; son infobulle dit pourquoi (« De ton côté, à ton niveau, à ~12 min »).
  *A "Suggested for you" badge on the clear best dungeon at your level.*

### Modifié / Changed
- **Quêtes grises facultatives décochées** : dans la vue d'ensemble, une quête grise pour toi (8 niveaux ou plus sous toi, la moitié de l'XP ou moins) dont le donjon n'a pas besoin est décochée d'office (« Décochée : quête grise facultative (peu d'XP) ») ; un clic la remet. Tes choix à la main restent tels quels.
  *Grey optional quests start unticked; one click adds them back.*

## [1.0.0-beta.95] — 2026-11-17

### Modifié / Changed
- **Première connexion plus calme** : seul l'écran de bienvenue s'ouvre ; la carte de la tournée en ville, le rappel des Writs et la ligne « spé supposée » attendent qu'il soit fermé.
  *Only the welcome opens at the first login.*
- **Donjon conseillé** : « À faire à ton niveau » met d'abord le donjon de ton côté, au milieu de ta tranche de niveau et le plus proche (ex. Gouffre de Ragefeu pour un Horde à Orgrimmar, plus La salle des Thanes sous Forgefer).
  *Picker suggests a dungeon that fits your faction, level and position.*
- **Une seule liste de commandes** : `/wlh help` et la fenêtre « Comment faire... ? » montrent les mêmes mots (donjons, choisir, Writs, sacs, commandes, guilde, groupes, reglages, idee, suivi, aide) ; `/wlh help` ouvre la fenêtre, `/wlh help chat` donne la liste dans le chat.
  *One command list; /wlh help opens the window.*
- **Écran de bienvenue plus clair** : ce que le guide et les Writs font tout seuls est écrit, « avec toute la guilde » seulement si tu en as une, les Writs expliqués.
  *Clearer welcome texts.*
- **Visite guidée** : le compte suit les bulles vraiment montrées.
  *Tour count without gaps.*

## [1.0.0-beta.94] — 2026-11-17

### Corrigé / Fixed
- **Check-list du Temple englouti** : les objectifs de la chaîne du Sceptre des Sables changeants (Tête du seigneur des couvées Lanistaire, Fragments de carapace silithide, quêtes de raid de niveau 60) ne s'affichent plus ; une quête que tu ne peux pas encore prendre n'ajoute plus d'objectif « à finir dehors ».
  *Sunken Temple checklist no longer lists the level 60 raid chain.*
- **Données de quêtes vérifiées** :
  - L'Ichor de non-mort se farme sur les Highborne du sud-ouest d'Azshara (plus Nathanos) ou s'achète à l'HV.
  - Calice spectral et Nogg : rubis et barres sans point fixe (mines, fonte ou HV).
  - Souvenir de la mémoire : le bon point à Stromgarde.
  - Test de toxicité : zone des trois chemins des Diablosaures.
  - Unending Torment : le sérum s'utilise à l'étage près d'Othmar.
  - La corruption de Vylelangue ajoutée côté Alliance (Talendria).
  - Powering the Pylons : note précisée (Tamis à mana en 45.9, 78.2).
  *Quest data checked against two sources; Alliance Vyletongue Corruption added.*

## [1.0.0-beta.93] — 2026-11-17

### Ajouté / Added
- **Zones sur la carte** (T-90) : quand les objets ou monstres d'un objectif sont éparpillés (ex. Artefacts atal'ai dans l'eau autour de l'île du bassin des larmes), une zone est dessinée sur la carte du monde et la minimap, la flèche mène au plus proche, et l'étiquette dit « Dans la zone » ; 49 objectifs de 39 quêtes.
  *Quest zones drawn for scattered targets; arrow to the nearest one.*
- **Horaires des zeppelins et bateaux** : « Zeppelin pour Grom'gol dans 1:20 » / « à quai, part dans 0:35 » ; horaires de NaowhForever s'il est installé, sinon relevés en jeu et partagés dans la guilde (et ceux de NauticusClassic / ForeverTransport) ; le GPS compte la vraie attente.
  *Zeppelin and boat departure timers, used by the route planner.*
- **Vols connus** : si le GPS ne connaît pas encore tes vols sur un continent, il suppose connus ceux des zones bien en dessous de ton niveau (« Vol supposé connu : ouvre la carte du maître de vol pour vérifier ») ; ouvrir une carte de vol corrige tout. La flèche explique quand elle te met à cheval.
  *Assumed known flights until a flight map is opened; ride reasons explained.*
- **Pourquoi d'abord là-bas** : « D'abord à Feralas : il faut « Le Temple englouti » avant de parler à Marvon Rivetseeker à Tanaris. »
  *The card says why the route goes elsewhere first.*
- **Améliorations** : une ligne courte dit pourquoi (« Surtout : DPS de baguette en plus, moins de dégâts de givre ») ; Maj pour le détail chiffré. Réglages « J'utilise ma baguette » (automatique : parfois dès le niv. 40 pour mage, démoniste, prêtre) et « Ignorer les armures plus légères que la mienne (dès le niv. 40) ».
  *Upgrade reasons, wand usage and lighter-armor settings.*
- **Maraudon** : les gemmes des Khans pour « Les instructions du paria » (Prophète sans nom, Kolk, Gelk, Magra dehors ; Veng et Maraudos dedans), et où remplir la fiole de « La corruption de Vylelangue ».
  *Pariah's Instructions step by step.*

### Modifié / Changed
- **Ordre des boss de Maraudon** corrigé, selon l'aile où tu entres (orange ou violette).
  *Maraudon boss order by wing.*
- **Liste « En chemin » dans le donjon** : seulement ce qui se fait sur le chemin de ce boss, avec où et combien ; « Carte du donjon » au lieu du bouton grisé.
  *Per-boss on-the-way lists.*
- **Moins d'allers-retours** : ce qui se fait sur place passe avant de partir (40 % d'allers-retours en moins).
  *Fewer back-and-forth trips.*
- **Textes des cartes du guide relus** (3589 cartes) : distances et « change de continent » cohérents, « Avant / Après le donjon » justes, listes avec verbe et compte.
  *Guide card texts proofread.*
- **Trajet sur la flèche** : « Puis vol jusqu'à Orgrimmar > zeppelin pour Fossoyeuse > vol jusqu'à Moulin-de-Tarren » (plus de carrés), détail dans l'infobulle.
  *Readable itinerary line.*
- **Pierre de foyer** : la carte du guide donne aussi la durée et l'autre trajet.
  *Trip time on the card.*

### Corrigé / Fixed
- **XP des quêtes grises** : ce que Forever donne vraiment (chiffre du jeu, sinon courbe apprise, sinon 80/60/50 %) ; ex. 1 900 XP au lieu de 380.
  *Grey quest XP matches Forever.*
- **Objets portés à suffixe** (« de force », « de l'ours ») lus avec leurs vraies stats : fini les +1128 % et « Emplacement vide » à tort.
  *Random-suffix worn items read correctly.*
- **Spam « Aucun joueur nommé... »** : WL Helper ne chuchote qu'aux joueurs en ligne, et la ligne est masquée sinon.
  *No more "player not found" spam from WL Helper.*
- **Partage des quêtes en combat** : attend la fin du combat au lieu d'être bloqué par le jeu.
  *Quest sharing waits for the end of combat.*
- **Check-list** : une quête dont la chaîne n'est pas faite (« Rot and Regret ») est « Bloquée » en gris au lieu de « Requise » ; la chaîne ajoutée après coup se place avant le donjon.
  *Locked quests no longer block the checklist.*
- **Fenêtres opaques**, la dernière cliquée passe devant.
  *Opaque windows, last clicked on top.*

## [1.0.0-beta.92] — 2026-11-16

### Ajouté / Added
- **Facultatif ou requis** (T-87) : les étapes faites dehors d'une quête de donjon disent clairement « Facultatif : le donjon se fait sans · sur le chemin du portail » (ex. Fragments d'Ombréclat à Maraudon), « Requis pour « X » (dans le donjon) » quand une suite en dépend, ou « Requis : la clé pour entrer dans le donjon ».
  *Outside steps say whether they are optional or required.*
- **Bouton « Passer »** sur les étapes facultatives : deux clics retirent la quête de la route (elle reste dans ton journal), à recocher dans la vue d'ensemble.
  *Skip button for optional quests.*

### Corrigé / Fixed
- **« Requis pour » faux** : une quête n'est plus dite « dans le donjon » quand elle se fait dehors ou dans un autre donjon.
  *Wrong "required for" labels fixed.*

## [1.0.0-beta.91] — 2026-11-16

### Ajouté / Added
- **« Quoi de neuf » en grand** : fenêtre large et redimensionnable (largeur et hauteur, taille retenue), versions à gauche avec un point sur celles pas encore vues, changements en cartes sur 2 ou 3 colonnes avec « Voir plus », résumé à la connexion, filtres Tout / Nouveau / Changé / Corrigé, et « Ne plus afficher à la connexion ».
  *Wide, resizable What's new with a version list, card grid, filters.*
- **Pierre de foyer** (Réglages > GPS) : par défaut, la pierre de foyer et le Rappel astral ne sont utilisés que s'ils font gagner au moins 3 min (sinon le GPS prend par exemple le zeppelin d'Orgrimmar pour Grom'gol). La flèche et la carte du guide donnent la durée du trajet et un « Autre trajet » ; Alt-clic sur la flèche pour le prendre.
  *Hearthstone policy (default: only if it saves 3 min), trip time and an alternative route.*
- **Commandes** : survoler un objet affiche l'infobulle du jeu avec ses statistiques (Maj : comparaison), partout dans les Commandes.
  *Item tooltips with stats everywhere in Orders.*
- **`/wlh diag carte`** : dit pourquoi le chemin s'affiche ou non sur la carte du monde.
  *New map diagnostic command.*

### Modifié / Changed
- **GPS et Zygor** : le choix Automatique / WL Helper / Zygor devient un seul interrupteur « Envoyer les destinations à la flèche de Zygor », visible seulement si Zygor est installé, désactivé par défaut.
  *One Zygor switch, off by default.*
- **Liste des étapes** : une croix pour la fermer, et le bouton « Étapes » devient « Fermer les étapes » quand elle est ouverte.
  *Close button on the step list.*

### Corrigé / Fixed
- **Pointillés sur la carte du monde avec OpenMap** : ils étaient dessinés sous la carte assemblée d'OpenMap ; ils passent maintenant au-dessus (chemin à pied et patrouilles).
  *World map path dots now draw above OpenMap's stitched map.*
- **Accueil des Commandes** : la liste des artisans en ligne restait affichée par-dessus les tuiles en revenant à l'accueil.
  *Orders home no longer shows the online list over the tiles.*
- **Fenêtres hors de l'écran** : une position enregistrée hors de l'écran est ramenée ; la barre de titre reste toujours visible.
  *Windows saved off-screen are brought back.*
- **Messages de guilde renforcés** : un message mal formé ne peut plus casser les Commandes, l'Agenda ou l'Accueil (les données abîmées sont nettoyées) ; seul l'organisateur peut modifier ou annuler son événement ; on ne peut plus inventer d'étoiles ; un homonyme d'un autre royaume n'écrase plus les données d'un membre ; moins d'annonces et de rafraîchissements quand beaucoup de messages arrivent.
  *Guild sync hardened against malformed messages, spoofing and floods.*

## [1.0.0-beta.90] — 2026-11-16

### Corrigé / Fixed
- **Sorts appris reconnus sur Forever** : le GPS propose de nouveau tes sorts de voyage (téléports, Rappel astral), les recharges de métier sont suivies, et le tir automatique du chasseur est bien utilisé.
  *Known spells detected on Forever: travel spells, profession cooldowns, hunter Auto Shot.*
- **Clés de donjon** : la clé a son nom en jeu, son icône, et « possédée » quand elle est dans tes sacs.
  *Dungeon keys show their name, icon and "owned" again.*
- **Butin des boss et récompenses** : nom, lien et icône des objets s'affichent de nouveau ; les icônes des étapes « objet » aussi.
  *Boss loot and reward items show name, link and icon again.*
- **Invitation en Alt-clic** : ne peut plus provoquer d'erreur selon le réglage « action à l'appui ».
  *Alt-click invite no longer errors.*

## [1.0.0-beta.89] — 2026-11-16

### Corrigé / Fixed
- **Talents dans le score d'équipement** : WL Helper Gear lit maintenant les talents sur Forever (le système de talents du client) : ta spé est détectée toute seule et les talents comme Cœur sauvage ou Instinct naturel changent les poids.
  *Gear now reads talents on Forever: spec detected, talent modifiers applied.*
- **Quêtes de métier** : elles sont de nouveau masquées pour les personnages qui n'ont pas le métier, avec le filtre « quêtes utiles ».
  *Profession quests hidden again for characters without the profession.*
- **Commandes** : cliquer sur un objet dans les résultats ne provoque plus d'erreur, et Maj-clic sur un objet du sac le place de nouveau dans la recherche ou la demande.
  *Orders: item clicks no longer error; Shift-click from bags works again.*
- **Commandes du chat** : WL Helper ne touche plus à la liste des commandes du jeu (risque d'action bloquée).
  *No more write to the game's slash command list.*

## [1.0.0-beta.88] — 2026-11-16

### Corrigé / Fixed
- **Guide dans le donjon** : la route n'est plus recalculée depuis ta position à chaque quête prise ou rendue à l'intérieur (elle te renvoyait parfois à une étape du dehors) ; elle attend ta sortie.
  *The route no longer rebuilds from your position while you are inside a dungeon.*
- **Étapes de boss** : une quête ajoutée à une étape de boss déjà cochée (boss tué ou passé) n'est plus cachée, et le guide ne saute plus au rendu avant d'avoir fait l'objectif.
  *A quest line added to an already ticked boss step is no longer hidden.*
- **Rendus dans le donjon** : un rendu ne passe plus avant ses propres objectifs (Ombrecroc, Gouffre de Ragefeu, Temple englouti, Salle des Thanes...).
  *Turn-ins inside a dungeon no longer come before their objectives.*
- **Avant d'entrer** : le guide ne t'envoie plus dans le donjon tant qu'une étape faisable dehors reste ouverte (Scholomance, Brassenoire, Zul'Farrak, Kraal de Tranchebauge...), et un rendu prêt n'attend plus derrière une étape du donjon.
  *No entering while doable outside steps are left.*
- **Quêtes de race** : les quêtes réservées à une race ne sont plus proposées aux autres races.
  *Race-restricted quests are no longer offered to other races.*
- **Groupe et HV** : la classe des membres du groupe est bien lue (couleurs, Groupe), la progression du scan de l'hôtel des ventes s'affiche, et le texte de ta recherche de groupe est retenu.
  *Party member classes, AH scan progress and the saved group-finder text work again.*

## [1.0.0-beta.87] — 2026-11-16

### Ajouté / Added
- **Fenêtres plus larges et redimensionnables** (T-81) : taille proportionnelle à ton écran, poignée en bas à droite, taille retenue ; réglages en 2 ou 3 colonnes, listes en grilles, profil d'artisan des Commandes en 2 colonnes.
  *Wider, resizable windows sized to your screen; settings and lists in columns.*
- **Guide : onglets « Dehors · Dans le donjon · Après »** et mode consultation : reviens sur n'importe quelle étape, même faite, sans changer ton étape en cours ; « Voir où en est ... » pour un membre du groupe qui a WL Helper (T-86).
  *Guide part tabs, browse any step, see where a group member is.*
- **« Recommencer la route »** dans le menu Actions et la liste des étapes, confirmé par un second clic (T-84).
  *Restart the route button.*
- **Vue d'ensemble, onglet « Groupe »** : quêtes × coéquipiers, même sans WL Helper chez eux ; la raison au survol (niveau trop bas, déjà faite, prérequis, ne se partage pas...), « 2/3 l'ont », bouton « Vérifier » (T-82).
  *Overview Group tab: who has each quest and why not, even without WL Helper.*
- **Raccourcis dans les réglages** (Réglages > Guide de quêtes > Raccourcis) : clique puis appuie sur une touche, conflit signalé, Effacer ; nouvelle touche « Utiliser l'objet de quête de l'étape » (T-83).
  *Key bindings inside the settings, plus a quest item key.*
- **Étapes avant le donjon** : « Élite » ou « Non élite », et pourquoi la faire avant (« la suite se fait dans le donjon ») ou « Facultatif ».
  *Elite marks and why-before line on pre-dungeon steps.*

### Modifié / Changed
- **Route** : une chaîne de prérequis faisable entre dans la route avant le donjon ; une chaîne trop haute ou trop longue est expliquée en gris dans la vue d'ensemble, et la cocher la remet. Les objectifs au même endroit se font en un seul passage (à Uldaman : collier, champignons, tablette, pierres et coffre dans l'excavation, avant d'entrer).
  *Prerequisite chains routed or explained; same-spot objectives in one pass.*
- **Flèche** : « Puis 690 m jusqu'à Dran Droffers » au lieu de « 690 m en monture » ; la carte du guide donne le même trajet (« Téléport : Orgrimmar, puis 690 m ») au lieu de « change de continent : zeppelin ou bateau ».
  *Arrow says where the last walk goes; the guide card matches it.*
- **Check-list** : le bouton devient « Fermer la check-list » quand elle est affichée, et elle liste ce qu'il reste à finir dehors avant d'entrer (T-85).
  *Checklist button toggles; lists outside objectives left.*
- **Première ouverture du guide** : au centre, liste des étapes fermée ; une position hors de l'écran est ramenée.
  *Guide first opens centred with the step list closed.*

### Corrigé / Fixed
- **Fausse étape « dans le donjon »** : après avoir ramassé un objet devant l'entrée (tablette de Solution to Doom), le guide sautait à « Baelog » alors que tu étais dehors.
  *Guide no longer jumps inside the dungeon after an item looted at the entrance.*
- **Pointillés sur la carte du monde** : ils s'affichent aussi avec OpenMap, et une carte n'est plus bloquée « sans points » pour la session.
  *World map trail dots show with OpenMap.*
- **Titre « Guide de quêtes » et « Partager 4 quêtes »** ne sont plus coupés en français.
  *French titles no longer truncated.*

## [1.0.0-beta.86] — 2026-11-16

### Corrigé / Fixed
- **Points de la route vérifiés** contre LibForeverData, NaowhForever et Questie pour les 439 quêtes du guide : 6 points d'objectif déplacés vers le camp principal (Fledgling Chillwind, Burning Blade Summoner, Young Wavethrasher, Crag Coyote, Pathstrider, Cliff Breaker), Bath'rah the Windwatcher suit son chemin, et Nazeer Bloodpike porte son vrai nom.
  *Route points checked against 3 sources for all 439 guide quests: 6 objective points moved to the main camp, one more patrolling NPC, one name fixed.*

### Modifié / Changed
- **Textes relus dans toute l'interface** : « Writ » toujours avec une majuscule, chemins des réglages écrits d'une seule façon (« Réglages > Général > Modules »), noms de fenêtres entre « », et deux renvois corrigés.
  *French text proofread across the UI.*
- **Moins de travail en jeu** : moins de calculs à chaque barre de nom et sur ta cible, la flèche crée moins de déchets mémoire, et les anciens prix de l'HV ne restent plus dans la sauvegarde.
  *Less work in game: nameplates, arrow, saved AH prices.*

## [1.0.0-beta.85] — 2026-11-16

### Ajouté / Added
- **GPS en vol** : la flèche affiche « En vol vers Kargath », l'étape suivante et le temps restant.
  *In flight, the arrow shows the destination, next step and time left.*
- **Aller à** : chaque lieu affiche le temps du trajet (vols et téléports compris), et l'infobulle donne le chemin (« Pierre de foyer → vol jusqu'à Kargath → 300 m à pied »).
  *Go to shows trip time and the itinerary.*
- **Messages du chat cliquables** : nouvel événement, joueur qui cherche un groupe, nouvelle commande, commande livrée ou refusée : un lien [S'inscrire], [Voir], [Remercier] ou [Répondre] ouvre directement le bon onglet.
  *Clickable chat links open the right tab.*
- **Accueil vivant** : il se met à jour tout seul quand il est ouvert (recharges, événements, membres en ligne, niveau).
  *Home refreshes itself while open.*

### Modifié / Changed
- **Choisir un guide** : cocher ou décocher puis fermer ne change plus la route en cours ; seule « Lancer la route » la change.
  *Picker changes apply only with "Start route".*
- **Partager les quêtes** : seulement celles qui se partagent, en une ligne ; bouton « Partage en cours » pendant le partage, plus de double partage.
  *Quest sharing: shareable ones only, one line, no double share.*
- **Moins de saccades** : le guide lit le journal de quêtes une fois par objectif ; les réponses de la guilde qui arrivent ensemble ne redessinent la fenêtre qu'une fois.
  *Fewer stutters in the guide and guild windows.*
- **Aujourd'hui (Writs)** : la phrase dit quoi faire (acheter les objets manquants, ouvrir les enveloppes, rendre) ou que c'est ton budget qui bloque.
  *Writs Today explains what to do or that the budget is the limit.*
- **Tournée en ville** : démarre même pendant la tournée des Writs (mise en pause, une ligne le dit).
  *City tour pauses the writs tour.*

### Corrigé / Fixed
- **Combat** : le bouton de téléportation ne réagit plus aux clics en combat ; avec « Cacher en combat », la flèche ne capte plus la souris.
  *Teleport button ignores clicks in combat; hidden arrow no longer takes the mouse.*
- **Prérequis** : une quête faite sous une autre version (Seigneur Valthalak, quêtes à deux numéros, le Maillet) compte comme faite partout.
  *Quests done under another ID count as done everywhere.*
- **Achats** : un objet dont il manque des exemplaires n'est plus « Dans le sac » ; les quantités et prix ne comptent que ce qui manque.
  *Shopping counts only what is missing.*
- **Clés** : « personne en ligne ne l'a » ne dépend plus des filtres de la fenêtre Guilde ; un membre qui se connecte reçoit bien tes clés.
  *Keys: online check ignores guild filters; newcomers get your keys.*
- **Nous écrire** : l'aide du formulaire « Un bug » dit ce qui est vraiment envoyé.
  *Bug form hint is accurate.*

## [1.0.0-beta.84] — 2026-11-16

### Ajouté / Added
- **Clic droit sur Commandes, Guilde ou Groupes** à l'Accueil : ouvre directement leurs réglages. Nouvelle commande `/wlh groupes`.
  *Right-click Orders, Guild or Groups on Home to open their settings; new /wlh groupes.*
- **/way** : le repère dans le monde (lieu, distance, temps) s'affiche aussi pour tes points /way.
  *The world label also shows for /way points.*
- **Commandes** : si le client annule une commande que tu as acceptée, ou si un autre artisan la prend en même temps, une ligne dans le chat te prévient.
  *Orders: a chat line when an accepted order is cancelled or taken by someone else.*

### Modifié / Changed
- **GPS** : l'étape du guide n'écrase plus ton /way, « Aller à... » ou une clé ; elle attend et revient quand ta destination est atteinte ou arrêtée. « Aller à... » vise le vrai lieu, avec le même chemin à pied que le guide. Fermer la flèche arrête la tournée en ville.
  *The guide no longer overrides your /way or Go to; Go to aims at the real place; closing the arrow stops the city tour.*
- **GPS d'un objectif** : le bouton GPS mène à la zone de quête du jeu (celle de la carte), et un objectif placé seulement par le jeu a aussi son bouton.
  *Objective GPS goes to the game's quest area.*
- **Vue d'ensemble** : cocher ou décocher une quête met la route à jour sans message dans le chat et garde l'étape que tu regardes.
  *Ticking quests in the Overview updates the route quietly.*
- **Guide fermé** : plus redessiné en arrière-plan, plus de son « Étape suivante » quand rien n'est affiché ; la flèche suit toujours.
  *A closed guide no longer redraws or plays sounds in the background.*
- **Le module de groupes s'appelle « Groupes » partout.** « Inviter les inscrits » n'invite que les inscrits en ligne et dit pourquoi une invitation ne part pas ; idem pour « Inviter » dans la liste de la guilde.
  *"Groups" everywhere; invites explain why they did not go out.*
- **Classement PvP de la guilde** : l'addon n'envoie ses chiffres que quand ils changent.
  *Guild PvP sync sends only on change.*

### Corrigé / Fixed
- **« Le jeu a bloqué SetRaidTarget() »** : WL Helper ne pose aucune marque ; ce message vient d'une macro d'un autre addon (RXPTargeting de RestedXP ajoute « /tm !7 »). Le message nomme maintenant la macro au lieu de demander de le signaler.
  *The blocked raid-marker message now names the macro responsible (RestedXP's RXPTargeting).*
- **Recharges** : les transmutations et l'Étoffe lunaire sont enregistrées à l'ouverture de la fenêtre de métier, même quand le jeu cache les temps.
  *Transmute and Mooncloth cooldowns are recorded from the profession window.*
- **Writs** : le calcul des trajets ne fige plus l'écran à l'HV ; une enveloppe sans son objet ouvre l'achat de l'objet ; les caisses sans prix connu ne comptent plus comme gratuites.
  *Writs: no freeze at the AH, unpriced crates no longer free.*
- **Prix de revient** : l'interrupteur se rallume bien ; la ligne d'infobulle n'entraîne plus d'alerte « bloqué » en combat.
  *Cost price switch turns back on; no blocked alert in combat.*
- **Récompense choisie toute seule** : réessaie quand les objets ne sont pas encore chargés, puis le dit clairement.
  *Auto reward waits for item data, then says so.*
- **Quoi de neuf** s'affiche aussi après un combat et repart de ta dernière version ; dans l'aide, /wlh commun ouvre bien les quêtes en commun.
  *What's new after combat; help link fixed.*

## [1.0.0-beta.83] — 2026-11-16

### Modifié / Changed
- **GPS à pied à jour avec Polestar 0.4.0** : départs corrigés sous les rues des villes (quartier des Nains de Hurlevent), des milliers de nouveaux passages entre étages sur les deux continents, nouveaux villages relais, et danger des Montagnes d'Alterac recalé (niveau 30).
  *Walking GPS updated to Polestar Nav 0.4.0: better city starts, many more floor links, Alterac danger floor.*

## [1.0.0-beta.82] — 2026-11-16

### Ajouté / Added
- **Recharges de métier** (T-63) : l'Accueil affiche les recharges (transmutations, Étoffe lunaire, Salière) de tous tes personnages, et une ligne dans le chat te prévient quand l'une d'elles est prête.
  *Profession cooldowns of all your characters on Home, with a chat line when one is ready.*
- **Prix de revient à l'HV** (T-64) : WL Helper retient ce que tu paies à l'hôtel des ventes (et le coût des composants pour ce que tu fabriques), l'affiche dans l'infobulle et te prévient si tu mets en vente en dessous.
  *Cost price from your AH purchases in the tooltip, with a warning when you list below it.*
- **« Fabricable par 3 artisans de la guilde (1 en ligne) »** (T-65) dans l'infobulle des objets.
  *Item tooltip: how many guild crafters can make it, and how many are online.*
- **Heures habituelles** (T-66) : « Souvent là : 20h–23h » sur les fiches d'artisan, appris en voyant la guilde en ligne.
  *Usual online hours on crafter cards.*
- **Notes de boss pour tous les donjons** (T-23) : tactique et conseil, plus seulement les Mortemines, Ombrecroc et les Cavernes.
  *Boss notes for every dungeon of the guide.*

### Modifié / Changed
- **Butin des boss** : un objet BiS pour ta spé apparaît même quand ce n'est pas une amélioration, en premier. Les badges sous les icônes sont plus courts (« BiS 40 », « 2e »).
  *BiS items show in boss loot even when not an upgrade; shorter badges under icons.*
- **Avis de nouvelle version** (T-67) : il faut maintenant au moins 2 membres de la guilde avec la même version plus récente.
  *The new-version notice needs at least 2 guild members reporting it.*

## [1.0.0-beta.81] — 2026-11-16

### Modifié / Changed
- **Liste des addons** : WL Helper Gear et les trois WL Helper Nav ont maintenant le logo WL Helper et un nom aligné (« WaR LegenD Helper - Gear », « - Nav »...), regroupés sous WL Helper quand le jeu le permet.
  *Gear and Nav sub-addons now show the WL Helper logo and matching names in the addon list.*

## [1.0.0-beta.80] — 2026-11-16

### Ajouté / Added
- **Badges BiS sur le butin** : les récompenses de quête de la vue d'ensemble et le butin des boss affichent « BiS ★ » ou « 2e choix » quand Naowh classe l'objet pour ta spé.
  *BiS / 2nd choice badges on quest rewards and boss loot, from Naowh.*
- **BiS même sans liste remplie** : si tu n'as jamais rempli ta liste BiS dans Naowh, WL Helper prend l'équipement que Naowh conseille pour ton niveau (« BiS niv. 40 » avant 60, son classement au 60). Ta propre liste passe toujours en premier.
  *No Naowh list filled? Naowh's gear for your level is used ("BiS lvl 40"), its ranking at 60.*
- **Statut d'artisan dans la minimap** : « Artisan : Disponible » dans le menu, un clic passe à Occupé ou Absent.
  *Crafter status in the minimap menu, click to change it.*
- **« Me prévenir quand quelqu'un sait le faire »** sur la page Demander : un message (et un son) quand un membre de la guilde apprend la recette.
  *Get told when a guild member learns the recipe you asked for.*
- **Alertes des commandes** dans Réglages › Général › Commandes : favori qui se connecte, recette surveillée apprise, son.
  *Orders alerts in Settings.*

## [1.0.0-beta.79] — 2026-11-16

### Ajouté / Added
- **Trouver un groupe** (T-78) : la fenêtre Groupes a un onglet de recherche de groupe pensé pour ton guide (donjons de ta route, de tes quêtes, de ton niveau), avec la guilde en premier : membres qui cherchent le même donjon, qui ont les mêmes quêtes, événement prévu. Filtres (rôle, classe, niveau, langue), notes des joueurs, messages groupés par personne, joueurs récents. `/wlh lfg`.
  *Group finder in the Groups window, built around your guide and your guild: filters, player ratings, whispers by person, recent players.*
- **Bienvenue et visite guidée** (T-62) : une page Bienvenue avec les réglages à faire pas à pas, et une visite qui montre chaque fonction à l'écran. `/wlh bienvenue`, `/wlh visite`.
  *Welcome page with step-by-step setup and a replayable guided tour.*
- **Quêtes du guide automatiques** : accepter, rendre et partager les quêtes du guide tout seul (Réglages › Quêtes du guide).
  *Auto accept, turn in and share the guide's quests.*
- **Les PNJ qui patrouillent** : leur chemin est tracé sur la carte et la carte du guide dit « Il se déplace le long d'un chemin ».
  *Patrolling NPCs: their path is drawn on the map.*
- **Budget des Writs** (T-70) : indique le maximum à dépenser, le plan choisit les Writs les plus rentables et les plus proches dans ce budget.
  *Writs budget: set a max spend, the plan picks the best and nearest writs within it.*
- **Accueil des commandes** façon Mastercraft (T-60) : fiche artisan, recherche, tuiles par métier, top de la semaine.
  *Orders home: crafter card, search, profession tiles, weekly top.*
- **Marques BiS de Naowh** (T-79) : si NaowhForever est installé, ses listes BiS servent pour les marques ; ses poids de stats ne servent que pour une spé dont tu as changé les poids dans Naowh (mention « poids Naowh »). Sinon le % reste celui de notre outil (caps de toucher et défense, montée de niveau).
  *Naowh BiS lists used when installed; Naowh stat weights only for specs you customized there.*

### Modifié / Changed
- **Portraits** : le bouton Cibler montre le visage du PNJ (ou une caisse pour un objet) au lieu d'une tête de mort.
  *Target button shows the NPC portrait instead of a skull.*
- **Menu Actions** réduit à 4 entrées : étape faite, recalculer, flèche, boss du donjon.
  *Actions menu down to 4 entries.*
- **Chaîne de quêtes en frise** dans la vue d'ensemble : numéros, trait, état, une ligne d'infos, détails au clic.
  *Overview chain as a timeline.*
- **Choisir un guide** en 3 ou 4 colonnes selon l'écran ; **modules du Hub** en deux colonnes ; **textes** mieux structurés (titres, puces) partout.
  *Guide picker in 3-4 columns, hub modules in two columns, better text structure.*
- **Points du chemin** plus visibles et réglables (taille carte, minimap, couleur) ; **étiquette dans le monde** plus soignée (tige, anneau, grande distance).
  *Bigger, configurable path dots; polished world label.*
- **Équipement** : WL Helper Gear suit Geared Forever 1.1.1. Le réglage « baguette » est fusionné en un seul, et le choix « Méthode » des améliorations disparaît (automatique).
  *Gear synced to Geared Forever 1.1.1; wand settings merged; upgrade method is automatic.*

### Corrigé / Fixed
- **Budget des Writs** : un Writ trop cher pour ce qui restait ne fait plus sauter les Writs moins chers de la même zone.
  *Writs budget no longer skips cheaper writs behind a too-dear one.*
- Les messages des commandes ne peuvent plus boucler quand beaucoup partent d'un coup.
  *Orders messages can no longer loop when many are sent at once.*

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
- **Noms** (T-38, T-39) : « vue d'ensemble » / « Vue d'ensemble » et « Pick a guide » / « Choisir un guide ».
  *Names: Overview and Pick a guide.*
- **Commandes avec beaucoup d'artisans** (T-53) : au-delà de 8, une liste « Artisans : 3 en ligne · 24 en tout » avec recherche ; deux noms au plus sur les lignes d'objets.
  *Orders scale to many crafters: searchable list, two names per item row.*
- **Quoi de neuf** plus lisible (T-34), **Aller à...** avec distances en direct (T-36), bouton retour sur toutes les fenêtres (T-35).
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
- **Aller à...** (T-09) : cherche une destination (banque, HV, maître de classe, PNJ, zone, entrée de donjon) ; la flèche suit un vrai chemin à pied grâce à WLHelper_Nav, livré à côté (addon GPL séparé, tiré de Polestar Nav et de Shortest Path Forever, crédités).
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
- **Résumé du donjon plus lisible** : bouton **« Lancer la route »** en bas à droite (ou « Mettre à jour la route » / « Retour à la route » quand une route tourne déjà) ; les quêtes déjà rendues sont repliées en bas ; quand tout est fait, « Tu as déjà rendu toutes les quêtes de ... » avec « Choisir un autre donjon » ; une ligne par quête avec niveau, XP et argent ; le total de ta sélection en haut.
  *Clearer dungeon summary with a Start the route button.*
- **Vue groupe** : des colonnes seulement pour les membres dont on connaît l'état (WL Helper ou réponse au partage), une icône par case ; les autres en une ligne « Sans WL Helper : ... ».

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
- **Infobulles** : les lignes « Clic : ... » sont en gris-bleu discret au lieu du rouge, qui faisait penser à une alerte.
  *Click hints in tooltips are a calm grey-blue instead of red.*

## [1.0.0-beta.53] — 2026-11-15

### Ajouté / Added
- **Quêtes récentes de Forever mieux guidées** : 55 quêtes des routes (chaînes de Shen'dralas et des pylônes, Krol'dok, Riverglades, prison d'Alcaz, Drowned City, Legashi, Blackmaw, Ruins of Lordaeron, Dalaran...) ont maintenant une marche à suivre en étapes, et leurs objectifs un point sur la carte quand on le connaît. Infos tirées de Wowhead Forever, réécrites, en français et en anglais.
  *55 recent Forever quests get how-to notes and objective places.*
- **`/wlh diag`** : enregistre ce que le client propose aux addons (talents, quêtes, carte, métiers...) pour nous aider à corriger les bugs sans te faire taper de commandes.

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
- **Plus de rendu juste après la prise** pour les quêtes dont nos données n'ont que le texte (ex. Powering the Pylons) : une étape « objectifs » s'intercale et se coche quand le jeu dit la quête terminée. Les quêtes « va parler à... » n'en ont pas.
- **Sources de butin sur leur propre ligne** sous l'objectif (« Tombe sur : ... »).

## [1.0.0-beta.48] — 2026-11-15

### Ajouté / Added
- **Suivi compact** à l'écran (façon RXP) : le chapitre en cours (« Avant le donjon : Uldaman 3/7 »), l'action à faire avec son icône (prendre, rendre, tuer, ramasser, utiliser, aller...), les barres de progression des objectifs et les 2 actions suivantes. Clic : ouvre le guide sur l'étape ; Maj-clic : marquer faite ; déplaçable, repliable. `/wlh suivi`.
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
- **Commandes, catalogue des métiers** : « Commander » passe la commande à **toute la guilde** (le premier artisan qui accepte s'en charge) ; Maj-clic pour la passer à un seul artisan. Les objets sont rangés comme dans la fenêtre de métier : catégories repliables (Armes, Armure par emplacement, Sacs, Consommables, Composants, Enchantements...), triés par niveau requis (« Niv. 24 ») puis par qualité.
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
- **« Comment faire... ? »** remplace le guide de démarrage : une fiche par besoin avec les clics dans l'ordre, un bouton « Montre-moi » qui ouvre la bonne fenêtre et fait briller le bon bouton, une FAQ et les commandes.
  *"How do I...?" task guide with Show me buttons, FAQ and commands.*
- **Noms** : « Writs » et « LFG » partout.
- **WL Helper Gear v2** : effets « Chance au toucher » et « Utiliser : » comptés (Hand of Justice, Ironfoe, Earthstrike...), enchantements à effet (Crusader, Fiery...), bonus de set, plafonds de toucher donjon/raid, plafond de défense des tanks ; l'infobulle explique ce qui n'est pas compté.
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
- **Guide, dans le donjon** : un bandeau « DANS LE DONJON : ... » avec la progression des quêtes à l'intérieur et le boss suivant ; un clic ramène à l'étape du donjon.
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
- **Writs, onglet Achats** : une seule ligne par Writ (l'enveloppe et son objet, prix additionnés ; le détail dans l'infobulle), un filtre par zone, des zones repliables d'un clic (« Exclure » est un bouton à part), « absent de l'HV », la monnaie dans la langue du jeu (20s / 40s / 1g en anglais), « Tout acheter à la suite ».
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
- **Writs, zones à exclure** : dans Achats, un clic sur une zone (« À rendre en Les Paluns ») la laisse de côté, le plan prend d'autres Writs, toujours les moins chers et le moins de zones ; les zones exclues restent en bas, un clic les remet.
  *Writs: click a zone in the Shopping tab to leave it out of the plan.*
- **Guilde, filtres par classe et par rôle** : les icônes officielles des classes et des rôles (tank, soins, dégâts, d'après la spé partagée par WL Helper ; un druide farouche compte comme tank et dégâts), et l'icône de classe devant chaque nom.
  *Guild: class and role filters with the game's icons; class icon on each member.*

## [1.0.0-beta.33] — 2026-11-15

### Modifié / Changed
- **Writs, onglet Achats : l'enveloppe et son objet d'un seul clic.** Un clic sur l'un ou l'autre ouvre la page d'achat de l'enveloppe ; dès que l'achat passe, celle de l'objet s'ouvre seule. Maj-clic envoie les deux à Auctionator.
  *Writs Shopping tab: one click buys the envelope then its item; shift-click sends both to Auctionator.*

## [1.0.0-beta.32] — 2026-11-15

### Modifié / Changed
- **Writs et Faveur du marchand séparés** : deux tuiles sur l'accueil et deux fenêtres. **Writs** (réputation avec Durotar Supply and Logistics : Aujourd'hui, Achats, Tous) et **Faveur du marchand** (les caisses). L'onglet Achats dit « Coût » puis « pour 29 Writs, qui rapportent 3 025 points de réputation » au lieu de « +3025 rép ».
  *Writs and Merchant's Favor split into two tiles and two windows; clearer cost and reputation wording.*
- **Prix max pour 100 points de réputation** réglable dans Achats (20 pa, 40 pa, 1 po, sans) : le plan prend les Writs les moins chers et le moins de zones possible sous ce plafond.
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
- **Passe complète sur tout l'addon** (audit par module, chaque défaut contre-vérifié avant correction) : textes coupés ou superposés dans le Comptoir, la flèche GPS (plus large), le guide, le sélecteur, la Guilde, le LFG, les Commandes, l'accueil, les réglages et l'écran de bienvenue ; prix de l'HV qui pouvaient compter 0 à tort ; objectif de réputation mal lu ; épingle de carte effacée à tort ; noms de Writs en français reconnus ; classement PvP et événements séparés par guilde ; semaines PvP alignées sur la remise à zéro du jeu ; invitations LFG au-delà de 5 (passage en raid) ; inscription reçue avant l'événement ; flèches d'amélioration plus légères ; un deux-mains n'est plus comparé à la main gauche ; bouton « Publier la commande » qui cachait le réglage de paiement ; raisons de refus traduites chez chacun ; et d'autres.
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
- **Nettoyeur de sacs** : les explications ne sont plus coupées (« à détruire à... ») : plus courtes, fenêtre plus large, deux lignes si besoin. Le Marteau de Zul'Farrak et les autres objets à garder ne sont plus listés. Quand rien ne peut être coché, le bouton le dit (« Rien que l'addon puisse détruire ») et l'intro explique les objets grisés : les glisser hors du sac pour les détruire soi-même.
  *Bag cleaner: no more cut-off texts; items to keep are no longer listed; clearer when nothing can be ticked.*

## [1.0.0-beta.20] — 2026-11-15

### Ajouté / Added
- **Retour à l'accueil partout** : un « ‹ » en haut à gauche de chaque fenêtre (Comptoir, Commandes, Guilde, Sacs, Réglages, sélecteur de donjons...), et le logo fait de même.
  *A "‹" back-to-home button (and the logo) in every window.*

### Corrigé / Fixed
- **Textes invisibles chez certains joueurs** : avec une autre version d'EllesmereUI, la police qu'on lui emprunte pouvait manquer et les textes disparaissaient (boutons, lignes d'étape). L'addon vérifie maintenant que la police s'affiche, sinon il prend celle du jeu.
  *Invisible texts with another EllesmereUI version: the borrowed font is checked, the game's font is used otherwise.*
- Comptoir : « reset dans 14 h » devient « nouveaux Writs dans 14 h », et « Rends les 0 Writs prêts » devient « Achète 8 Writs dans l'onglet Achats ».
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
- **Commandes rangées** : une seule commande, `/wl`, et un seul mot anglais par action, le même en français : `dungeons`, `pick`, `trade`, `bags`, `orders`, `gps`, `options`, `setup`, `idea`, `help`. Les anciens mots (`/wl reglages`, `/wl sacs`...) marchent encore mais ne sont plus affichés. `/comptoir`, `/Writs`, `/wlo`, `/dg`, `/dguide`, `/wldt` et `/zfg` sont retirés.
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
- **Journal du donjon** dans le menu « ... » du guide : boss et butin du donjon de l'étape, dans Naowh Dungeon Journal ou Forever Dungeon Journal.
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
- **La banque compte** : ce que tu as en banque n'est plus à racheter (liste d'achat, Writs, Favor) ; la liste dit « 2 en banque ».
  *Your bank counts: items in the bank are not bought again.*
- Le guide ne s'ouvre plus jamais tout seul à la connexion ou au /reload : `/wl`, l'accueil ou la minimap l'ouvrent.
  *The guide never opens by itself at login or /reload.*

## [1.0.0-beta.7] — 2026-11-15

### Ajouté / Added
- **Rappel de mise à jour** : chaque copie de l'addon annonce discrètement sa version à ta guilde et à ton groupe. Si quelqu'un a plus récent que toi, un message te le dit une fois, et l'accueil et l'infobulle de la minimap affichent « Mise à jour disponible : ... · WowUp › Update ». Seul le numéro de version est envoyé. Ça marche à partir de cette version : il faut que d'autres joueurs l'aient aussi.
  *Update reminder: copies tell each other their version on the guild and group channels; a newer one shows on the home page and the minimap tooltip.*

### Modifié / Changed
- Accueil : la carte Donjons dit l'étape et ce qu'il faut faire ensuite ; la carte Comptoir montre ta Merchant's Favor ; la ligne GPS n'apparaît que pendant un guidage.
  *Home: the next step on the Dungeons card, your Favor on the Trading Post card, the GPS line only while guiding.*

## [1.0.0-beta.6] — 2026-11-15

### Ajouté / Added
- **Planificateur de Merchant's Favor** (onglet « Favor » du Comptoir) : tu tapes combien de Favor tu veux ; il prend les Waylaid Crates les moins chères (caisse + le lot de composants le moins cher, ce que tu as déjà est gratuit), tient compte de ce qui est en vente au dernier scan, et liste quoi acheter. Clic : acheter la caisse ; Maj-clic : le lot. La Favor de chaque caisse s'apprend quand tu en rends une. Les lots sont lus dans Naowh Forever.
  *Merchant's Favor planner: type the Favor you want; the cheapest Waylaid Crates and bundles, what to buy, one click at the AH.*
- **Choisir ses Writs** : dans « Tous », une case par Writ ; le total (prix, prix après Coin Pouch, réputation) se met à jour à chaque coche, et la liste d'achat suit ta sélection. Sans coche, le plan automatique reste.
  *Tick the writs you want in "All": live total of cost and reputation; the shopping list follows your pick.*

### Modifié / Changed
- **Choix des donjons** rangé en sections : à ton niveau, plus tard, terminés (coche verte, barre verte), sans quête Horde (avec « Tous »).
  *Dungeon picker in sections, with a green check on finished dungeons.*
- Titre « WaR LegenD Helper » dans l'infobulle de la minimap et sur l'accueil.
- Liste d'achat : groupes « À rendre en <zone> · N Writs », enveloppes écrites « Enveloppe · objet » ; bouton « Liste Auctionator » retiré (l'achat est intégré).
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
- Le menu du clic droit sur la minimap passait derrière les barres de boutons de minimap (EllesmereUI...) ; le menu « ... » du guide aussi peut passer devant tout.
  *The minimap right-click menu no longer opens behind minimap button bars; same for the guide's "..." menu.*

## [1.0.0-beta.3] — 2026-11-15

Une interface rangée : un accueil, un guide allégé, une minimap et des commandes claires.
*A tidy interface: a home page, a lighter guide, a clear minimap button and commands.*

### Ajouté / Added
- **Accueil** (`/wl`, clic sur la minimap) : une carte par module avec où tu en es (donjon et étape, Writs prêts, objets à jeter), le GPS en cours avec un bouton pour l'arrêter, « Une idée, un bug ? » et les réglages.
  *Home page: one card per module with where you stand, the running GPS, feedback and settings.*
- **Choisir ses Writs** : clic droit sur un Writ dans « Tous les Writs » pour le mettre de côté ; Réglages › Comptoir › « Zones où je vais » pour écarter des zones entières. Le plan d'achat n'achète plus ce qui est écarté.
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
- Infobulles des Writs sans PNJ connu : les lignes « Clic : GPS » manquaient.
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
- **Confort du Comptoir**, chacun désactivable : acceptation et remise automatiques des Writs (Maj pour l'empêcher), rappel à la connexion, infobulle des enveloppes (réputation, objet demandé, prix, lieu, déjà rendu).
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
- Commandes : `/comptoir` devient la commande du Comptoir (`/wl comptoir`, `/Writs` reste en alias) ; nouvelles `/wl options`, `/wl clean`.
  *Commands: `/comptoir` is the Comptoir's command (`/writs` still works); new `/wl options`, `/wl clean`.*

### Supprimé / Removed
- Le calculateur de coût des Writs (remplacé par le plan du jour).
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

- **Craftsman's Writs** : nouveau panneau (bouton « Writs », `/wl Writs`, `/Writs`, Maj-clic sur la minimap) — prix par le scan intégré de l'HV, Auctionator ou TSM ; état du jour ; plan d'achat pour le rang suivant ; liste d'achat avec rescan à l'ouverture de l'HV et achat direct ; valeur des Coin Pouch mesurée ; Writs de l'autre faction masqués ; lieux de remise appris depuis le journal de quêtes.
- **GPS intégré**, partagé par le guide de donjons et les Writs : monture, points de vol connus, zeppelins, bateaux, téléportations de mage ; flèche avec l'étape en cours, boutons « Prendre le vol » et « Lancer la téléportation ». La flèche du guide passe par ce GPS.
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
