-- WhatsNew.lua: generated from CHANGELOG.md by the release (make_whatsnew.py; do not edit by hand).
-- Per version: v, date, items = { { s = "add"|"chg"|"fix", fr = { title, text }, en = { title, text } } }
local _, ns = ...
ns.WHATSNEW = {
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
  { v = "1.0.0-beta.96", date = "2026-11-17", items = {
    { s = "add", fr = { "Donjon conseillé bien visible", "La première carte de « À faire à ton niveau » porte le badge « Conseillé pour toi » quand elle convient nettement mieux que la suivante ; son infobulle dit pourquoi (« De ton côté, à ton niveau, à ~12 min »)." }, en = { "A \"Suggested for you\" badge on the clear best dungeon at your level.", "" } },
    { s = "chg", fr = { "Quêtes grises facultatives décochées", "Dans la vue d'ensemble, une quête grise pour toi (8 niveaux ou plus sous toi, la moitié de l'XP ou moins) dont le donjon n'a pas besoin est décochée d'office (« Décochée : quête grise facultative (peu d'XP) ») ; un clic la remet. Tes choix à la main restent tels quels." }, en = { "Grey optional quests start unticked; one click adds them back.", "" } },
  } },
  { v = "1.0.0-beta.95", date = "2026-11-17", items = {
    { s = "chg", fr = { "Première connexion plus calme", "Seul l'écran de bienvenue s'ouvre ; la carte de la tournée en ville, le rappel des Writs et la ligne « spé supposée » attendent qu'il soit fermé." }, en = { "Only the welcome opens at the first login.", "" } },
    { s = "chg", fr = { "Donjon conseillé", "« À faire à ton niveau » met d'abord le donjon de ton côté, au milieu de ta tranche de niveau et le plus proche (ex. Gouffre de Ragefeu pour un Horde à Orgrimmar, plus La salle des Thanes sous Forgefer)." }, en = { "Picker suggests a dungeon that fits your faction, level and position.", "" } },
    { s = "chg", fr = { "Une seule liste de commandes", "/wlh help et la fenêtre « Comment faire... ? » montrent les mêmes mots (donjons, choisir, Writs, sacs, commandes, guilde, groupes, reglages, idee, suivi, aide) ; /wlh help ouvre la fenêtre, /wlh help chat donne la liste dans le chat." }, en = { "One command list; /wlh help opens the window.", "" } },
    { s = "chg", fr = { "Écran de bienvenue plus clair", "Ce que le guide et les Writs font tout seuls est écrit, « avec toute la guilde » seulement si tu en as une, les Writs expliqués." }, en = { "Clearer welcome texts.", "" } },
    { s = "chg", fr = { "Visite guidée", "Le compte suit les bulles vraiment montrées." }, en = { "Tour count without gaps.", "" } },
  } },
  { v = "1.0.0-beta.94", date = "2026-11-17", items = {
    { s = "fix", fr = { "Check-list du Temple englouti", "Les objectifs de la chaîne du Sceptre des Sables changeants (Tête du seigneur des couvées Lanistaire, Fragments de carapace silithide, quêtes de raid de niveau 60) ne s'affichent plus ; une quête que tu ne peux pas encore prendre n'ajoute plus d'objectif « à finir dehors »." }, en = { "Sunken Temple checklist no longer lists the level 60 raid chain.", "" } },
    { s = "fix", fr = { "Données de quêtes vérifiées", "" }, en = { "", "" } },
    { s = "fix", fr = { "", "L'Ichor de non-mort se farme sur les Highborne du sud-ouest d'Azshara (plus Nathanos) ou s'achète à l'HV." }, en = { "", "" } },
    { s = "fix", fr = { "", "Calice spectral et Nogg : rubis et barres sans point fixe (mines, fonte ou HV)." }, en = { "", "" } },
    { s = "fix", fr = { "", "Souvenir de la mémoire : le bon point à Stromgarde." }, en = { "", "" } },
    { s = "fix", fr = { "", "Test de toxicité : zone des trois chemins des Diablosaures." }, en = { "", "" } },
    { s = "fix", fr = { "", "Unending Torment : le sérum s'utilise à l'étage près d'Othmar." }, en = { "", "" } },
    { s = "fix", fr = { "", "La corruption de Vylelangue ajoutée côté Alliance (Talendria)." }, en = { "", "" } },
    { s = "fix", fr = { "", "Powering the Pylons : note précisée (Tamis à mana en 45.9, 78.2)." }, en = { "Quest data checked against two sources; Alliance Vyletongue Corruption added.", "" } },
  } },
  { v = "1.0.0-beta.93", date = "2026-11-17", items = {
    { s = "add", fr = { "Zones sur la carte", "Quand les objets ou monstres d'un objectif sont éparpillés (ex. Artefacts atal'ai dans l'eau autour de l'île du bassin des larmes), une zone est dessinée sur la carte du monde et la minimap, la flèche mène au plus proche, et l'étiquette dit « Dans la zone » ; 49 objectifs de 39 quêtes." }, en = { "Quest zones drawn for scattered targets; arrow to the nearest one.", "" } },
    { s = "add", fr = { "Horaires des zeppelins et bateaux", "« Zeppelin pour Grom'gol dans 1:20 » / « à quai, part dans 0:35 » ; horaires de NaowhForever s'il est installé, sinon relevés en jeu et partagés dans la guilde (et ceux de NauticusClassic / ForeverTransport) ; le GPS compte la vraie attente." }, en = { "Zeppelin and boat departure timers, used by the route planner.", "" } },
    { s = "add", fr = { "Vols connus", "Si le GPS ne connaît pas encore tes vols sur un continent, il suppose connus ceux des zones bien en dessous de ton niveau (« Vol supposé connu : ouvre la carte du maître de vol pour vérifier ») ; ouvrir une carte de vol corrige tout. La flèche explique quand elle te met à cheval." }, en = { "Assumed known flights until a flight map is opened; ride reasons explained.", "" } },
    { s = "add", fr = { "Pourquoi d'abord là-bas", "« D'abord à Feralas : il faut « Le Temple englouti » avant de parler à Marvon Rivetseeker à Tanaris. »" }, en = { "The card says why the route goes elsewhere first.", "" } },
    { s = "add", fr = { "Améliorations", "Une ligne courte dit pourquoi (« Surtout : DPS de baguette en plus, moins de dégâts de givre ») ; Maj pour le détail chiffré. Réglages « J'utilise ma baguette » (automatique : parfois dès le niv. 40 pour mage, démoniste, prêtre) et « Ignorer les armures plus légères que la mienne (dès le niv. 40) »." }, en = { "Upgrade reasons, wand usage and lighter-armor settings.", "" } },
    { s = "add", fr = { "Maraudon", "Les gemmes des Khans pour « Les instructions du paria » (Prophète sans nom, Kolk, Gelk, Magra dehors ; Veng et Maraudos dedans), et où remplir la fiole de « La corruption de Vylelangue »." }, en = { "Pariah's Instructions step by step.", "" } },
    { s = "chg", fr = { "Ordre des boss de Maraudon", "Corrigé, selon l'aile où tu entres (orange ou violette)." }, en = { "Maraudon boss order by wing.", "" } },
    { s = "chg", fr = { "Liste « En chemin » dans le donjon", "Seulement ce qui se fait sur le chemin de ce boss, avec où et combien ; « Carte du donjon » au lieu du bouton grisé." }, en = { "Per-boss on-the-way lists.", "" } },
    { s = "chg", fr = { "Moins d'allers-retours", "Ce qui se fait sur place passe avant de partir (40 % d'allers-retours en moins)." }, en = { "Fewer back-and-forth trips.", "" } },
    { s = "chg", fr = { "Textes des cartes du guide relus", "Distances et « change de continent » cohérents, « Avant / Après le donjon » justes, listes avec verbe et compte." }, en = { "Guide card texts proofread.", "" } },
    { s = "chg", fr = { "Trajet sur la flèche", "« Puis vol jusqu'à Orgrimmar > zeppelin pour Fossoyeuse > vol jusqu'à Moulin-de-Tarren » (plus de carrés), détail dans l'infobulle." }, en = { "Readable itinerary line.", "" } },
    { s = "chg", fr = { "Pierre de foyer", "La carte du guide donne aussi la durée et l'autre trajet." }, en = { "Trip time on the card.", "" } },
    { s = "fix", fr = { "XP des quêtes grises", "Ce que Forever donne vraiment (chiffre du jeu, sinon courbe apprise, sinon 80/60/50 %) ; ex. 1 900 XP au lieu de 380." }, en = { "Grey quest XP matches Forever.", "" } },
    { s = "fix", fr = { "Objets portés à suffixe", "Lus avec leurs vraies stats : fini les +1128 % et « Emplacement vide » à tort." }, en = { "Random-suffix worn items read correctly.", "" } },
    { s = "fix", fr = { "Spam « Aucun joueur nommé... »", "WL Helper ne chuchote qu'aux joueurs en ligne, et la ligne est masquée sinon." }, en = { "No more \"player not found\" spam from WL Helper.", "" } },
    { s = "fix", fr = { "Partage des quêtes en combat", "Attend la fin du combat au lieu d'être bloqué par le jeu." }, en = { "Quest sharing waits for the end of combat.", "" } },
    { s = "fix", fr = { "Check-list", "Une quête dont la chaîne n'est pas faite (« Rot and Regret ») est « Bloquée » en gris au lieu de « Requise » ; la chaîne ajoutée après coup se place avant le donjon." }, en = { "Locked quests no longer block the checklist.", "" } },
    { s = "fix", fr = { "Fenêtres opaques", ", la dernière cliquée passe devant." }, en = { "Opaque windows, last clicked on top.", "" } },
  } },
}
