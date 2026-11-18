-- WhatsNew.lua: generated from CHANGELOG.md by the release (make_whatsnew.py; do not edit by hand).
-- Per version: v, date, items = { { s = "add"|"chg"|"fix", fr = { title, text }, en = { title, text } } }
local _, ns = ...
ns.WHATSNEW = {
  { v = "1.0.0-beta.158", date = "2026-11-18", items = {
    { s = "chg", fr = { "Trouver un groupe, plus clair", "Sur une fenêtre assez large, les filtres ne sont plus cachés dans une fenêtre qui s'ouvre par-dessus. Ils restent visibles dans une colonne à droite de la liste, comme dans LFG Forever, avec des titres de section en couleur (classes, niveau, langues, style de jeu, places libres). L'icône filtre masque ou réaffiche cette colonne. Sur une fenêtre étroite, rien ne change." }, en = { "Find a group", "On a wide window the filters stay visible in a column right of the list; the filter icon hides or shows it." } },
  } },
  { v = "1.0.0-beta.157", date = "2026-11-18", items = {
    { s = "add", fr = { "Onglets WL Helper dans la fenêtre Recherche de groupe du jeu", "Sous les onglets de droite (et sous celui de LFG Forever), deux onglets WL Helper. Le logo ouvre « Trouver un groupe », l'enclume ouvre « Commandes d'artisanat ». Un clic ferme la fenêtre du jeu (hors combat) et ouvre la nôtre. Ces onglets ne touchent à rien dans la fenêtre du jeu." }, en = { "Two WL Helper tabs on the game's Group Finder (under LFG Forever's): Find a group and Crafting orders.", "" } },
  } },
  { v = "1.0.0-beta.156", date = "2026-11-18", items = {
    { s = "fix", fr = { "Vue moderne, guide terminé", "La vue disparaissait à la fin d'un guide et on ne pouvait plus choisir de guide. Elle affiche maintenant « Guide terminé ! » avec le lien « Choisir un guide » (et la flèche ‹ pour revoir la dernière étape). Sans aucun guide chargé : « Aucun guide en cours » avec le même lien." }, en = { "Modern view", "A finished guide (or none loaded) shows a card with \"Pick a guide\" instead of vanishing." } },
    { s = "fix", fr = { "Améliorations, bijoux", "Un bijou à +9 Endurance s'affichait « +125 % » face à Theka's Last Breath, parce que ce dernier ne vaut presque rien en stats (sa valeur est son effet « Utiliser : »). Face à un objet sans presque aucune stat, l'écart est donné en points (« Presque pareil », ou l'écart réel). La ligne « Remplace » nomme le bijou vraiment comparé, et une ligne rappelle que les effets « Utiliser : » ne sont pas comptés." }, en = { "Upgrades", "No huge percent next to an item with almost no stats; \"Replaces\" names the trinket really compared; a note that \"Use:\" effects are not counted." } },
    { s = "fix", fr = { "Régénération de mana", "Pour les lanceurs de sorts (mage, démoniste, prêtre ombre...), 1 mana toutes les 5 s valait moins que 1 Intelligence, alors qu'elle rend plus de mana sur un combat. Elle vaut maintenant environ 1,6 fois le mana de l'Intelligence." }, en = { "Mana per 5 s for casters is worth about 1.6 times Intellect's mana (it was below Intellect).", "" } },
  } },
  { v = "1.0.0-beta.155", date = "2026-11-18", items = {
    { s = "fix", fr = { "Le GPS suit la vue moderne", "La fenêtre classique fermée, la flèche GPS suivait encore l'étape où cette fenêtre était restée (par exemple une étape du donjon), au lieu de l'étape affichée dans la vue moderne. Elle suit maintenant la vue moderne, y compris quand on parcourt les étapes avec ‹ ›, avec la liste ou en cliquant une action." }, en = { "The GPS arrow follows the modern view's step (and its browsing), not a step the closed window was left on.", "" } },
    { s = "fix", fr = { "Vue moderne, un texte plus propre", "Le lieu n'est plus écrit deux fois (seule la ligne avec la distance reste), les notes sans titre ont maintenant le titre « À savoir », et la ligne « Oathstone... » en trop sur « L'Essence d'Eranikus » a disparu." }, en = { "Modern view", "The place said once (with the distance), untitled notes under \"Good to know\", the stray Oathstone line gone." } },
  } },
  { v = "1.0.0-beta.154", date = "2026-11-18", items = {
    { s = "add", fr = { "Vue moderne, des liens toujours visibles", "Sous la barre de progression, une rangée de petits liens **Guides · Vue d'ensemble · Boss · Carte · Partager**. Le choix d'un guide (avec ses cartes de donjons), la vue d'ensemble, le panneau des boss, la carte du donjon et le partage des quêtes sont à un clic, sans passer par le menu ni la fenêtre classique." }, en = { "Modern view", "Always-visible links under the progress bar: Guides (the dungeon picker), Overview, Bosses, Map, Share." } },
  } },
  { v = "1.0.0-beta.153", date = "2026-11-18", items = {
    { s = "chg", fr = { "La vue moderne se suffit à elle-même", "" }, en = { "", "" } },
    { s = "chg", fr = { "un clic gauche ne renvoie plus vers la fenêtre classique.", "Sur le titre, il ne fait rien (glisser pour déplacer). Sur une action de « Ensuite », il affiche son étape dans la vue moderne ;" }, en = { "", "" } },
    { s = "chg", fr = { "toutes les étapes, dans la vue", "« ▸ Toutes les étapes » déplie la liste des étapes autour de celle affichée (faites ✓, en cours ▶). Un clic en affiche une, Maj-clic la marque faite ;" }, en = { "", "" } },
    { s = "chg", fr = { "le menu", "Ajoute « Choisir un guide » et « Vue d'ensemble du donjon ». La fenêtre classique ne s'ouvre plus que depuis ce menu." }, en = { "The modern view stands on its own", "Left-clicks stay in it (a next action shows its step here), \"All the steps\" lists the route's steps inside it, and its menu has \"Pick a guide\" and the dungeon overview; the classic window only opens from the menu." } },
  } },
  { v = "1.0.0-beta.152", date = "2026-11-18", items = {
    { s = "chg", fr = { "Deux raccourcis clavier au lieu de neuf", "WL Helper ne propose plus que les deux qui servent en jeu, **Cibler** (la cible de l'étape) et **Utiliser l'objet de quête** (celui de l'étape). Ce sont les deux premiers boutons de la barre « Target and items ». Les 7 autres sont retirés : ouvrir le guide, choisir un guide, étape suivante, étape précédente, poser les points, flèche, groupes. Ils doublaient les boutons du guide et les commandes /wlh. Une touche que tu leur avais donnée est simplement libérée." }, en = { "Two key bindings instead of nine", "The step's target and its quest item; the other seven doubled the guide's buttons and /wlh." } },
    { s = "add", fr = { "Annoncer la tactique au groupe", "Sur une étape de boss, Actions > « Annoncer la tactique au groupe » (ou le menu de la vue moderne, ou /wlh tactique) envoie la tactique dans le chat du groupe, du raid ou de l'instance. Seul, elle s'affiche pour toi." }, en = { "Tell the group the tactics", "The boss step's tactics to the party / raid / instance chat (Actions menu, modern view menu, /wlh tactics)." } },
    { s = "add", fr = { "Ombre d'Eranikus, le sommeil", "La tactique dit maintenant comment contrer son Sommeil profond, d'après le jeu de base (rien sur Wowhead Forever pour ce boss) :" }, en = { "", "" } },
    { s = "add", fr = { "", "le Totem de séisme du chaman réveille (il retire le sommeil), un mort-vivant s'en sort avec Volonté des Réprouvés ;" }, en = { "", "" } },
    { s = "add", fr = { "", "le tank le tourne dos au groupe (Souffle acide) ;" }, en = { "", "" } },
    { s = "add", fr = { "", "garder une potion ou un temps de recharge pour le réveil. Nos notes s'affichent désormais après la phrase du journal de Naowh au lieu d'être cachées par elle." }, en = { "Shade of Eranikus", "Counters to his Deep Slumber (Tremor Totem, Will of the Forsaken); our notes now show after Naowh's tip." } },
    { s = "fix", fr = { "La suite de « L'Essence d'Eranikus »", "L'Oathstone of Ysera's Dragonflight se récupère en parlant à **Itharius** (grotte au sud-ouest du Marais des Chagrins) avec la Chained Essence dans les sacs, d'après les commentaires Classic et TBC de Wowhead (aucun commentaire Forever). Le guide envoie maintenant à Itharius pour prendre la quête, et prévient : il faut lui donner le bijou, et la chaîne s'arrête juste après, à Winterspring." }, en = { "The Essence of Eranikus follow-up", "The Oathstone comes from talking to Itharius with the Chained Essence; the guide now sends you there (you give him the trinket)." } },
  } },
  { v = "1.0.0-beta.151", date = "2026-11-18", items = {
    { s = "chg", fr = { "L'écran « Nous écrire », plus clair", "" }, en = { "", "" } },
    { s = "chg", fr = { "", "un compteur de caractères sous le message (500 au plus) ;" }, en = { "", "" } },
    { s = "chg", fr = { "", "un encadré « Ce qui part avec ton message » qui montre ce que le rapport emporte (version, zone et position, niveau, étape du guide, nombre de quêtes, cible, dernière erreur) ;" }, en = { "", "" } },
    { s = "chg", fr = { "", "un bandeau vert une fois le message envoyé (ou gardé si aucun responsable n'est connecté) ;" }, en = { "", "" } },
    { s = "chg", fr = { "", "la partie GitHub repliée derrière un bouton, pour ceux qui ont un compte." }, en = { "\"Write to us\" screen", "A letter counter, \"What goes with your message\", a green banner once sent, the GitHub part folded." } },
    { s = "add", fr = { "Journal des vérifications de boss", "Dans un donjon, WL Helper note ses 80 dernières vérifications de boss (cible, survol, plaques de nom, début et fin de rencontre) : nom, numéro de PNJ, boss reconnu ou non, mort ou non, décision. Ça sert à comprendre pourquoi un boss tué apparaît encore vivant (signalé : Ogom the Wretched au Temple englouti). En attendant, un clic droit sur son icône dans le panneau des boss le marque tué." }, en = { "A log of the boss kill checks inside dungeons (WLWritsDB.bossLog), to see why a killed boss shows alive.", "" } },
  } },
  { v = "1.0.0-beta.150", date = "2026-11-18", items = {
    { s = "fix", fr = { "Gros freeze en ouvrant la carte (M) ou le journal (L) avec OpenMap", "OpenMap envoie son signal « la vue a bougé » à chaque image pendant son animation d'ouverture, et WL Helper redessinait à chaque fois tous ses tracés sur la carte (zones de monstres, chemins, points). Il redessine maintenant au plus 5 fois par seconde, plus une dernière fois quand la vue s'arrête. Les temps passés sont notés dans les sauvegardes, pour mesurer s'il reste un freeze." }, en = { "Big freeze on M / L with OpenMap", "Its view signal comes every frame while it glides; WL Helper's map lines are now redrawn 5 times a second at most (and once when it stops)." } },
    { s = "fix", fr = { "Chaque /reload remettait la fenêtre classique", "Le guide revient maintenant dans la vue moderne (quand c'est la vue par défaut) après un /reload, un écran de chargement ou l'entrée dans un donjon. Passer en vue moderne ne compte plus comme « guide fermé », ce qui pouvait aussi couper la flèche GPS. « Masquer la vue moderne » ferme vraiment le guide." }, en = { "A /reload now brings the modern view back; switching to it no longer counts as closing the guide (which could stop the GPS arrow).", "" } },
    { s = "fix", fr = { "La carte du donjon de Naowh avec OpenMap", "OpenMap remet la carte extérieure parfois plusieurs fois pendant l'ouverture. La carte de Naowh est maintenant remise jusqu'à 3 fois dans les 2,5 secondes qui suivent." }, en = { "Naowh's dungeon map is laid again up to 3 times within 2.5 s of the map opening (OpenMap turns it outside more than once).", "" } },
  } },
  { v = "1.0.0-beta.149", date = "2026-11-18", items = {
    { s = "add", fr = { "Accueil, un groupe « Retours »", "" }, en = { "", "" } },
    { s = "add", fr = { "« Nous écrire »", ", pour tous : « Un bug, une idée, une suggestion : sans compte ». Le choix du formulaire devient « Une idée ou suggestion »." }, en = { "", "" } },
    { s = "add", fr = { "« Rapports des joueurs »", ", seulement sur le compte qui reçoit les rapports : combien en sont arrivés, et les nouveaux en orange. Le clic ouvre la liste dans le jeu, du plus récent au plus ancien : le type (bug, idée, erreur de quête, erreur Lua), l'auteur, la date, la zone, le message, le lien de la capture, l'étape du guide et la pile d'appels des erreurs. /wlh rapports l'ouvre aussi." }, en = { "Home gets a \"Feedback\" group", "\"Write to us\" for everyone, and \"Players' reports\" (count, new ones, the list in the game) on the account that receives them." } },
    { s = "fix", fr = { "Vue moderne, une quête qui commence avec un objet que tu n'as pas", "L'Oathstone of Ysera's Dragonflight (après « L'Essence d'Eranikus ») restait proposé dans « Ensuite » même sans l'objet dans les sacs. Il n'apparaît plus tant que l'objet n'y est pas." }, en = { "Modern view", "A quest that starts from an item you do not have is no longer offered as a next action." } },
  } },
  { v = "1.0.0-beta.148", date = "2026-11-18", items = {
    { s = "add", fr = { "Les erreurs de WL Helper partent toutes seules", "Quand BugSack/BugGrabber attrape une erreur Lua de WL Helper chez un joueur, elle est envoyée automatiquement et en silence au compte qui reçoit les rapports. Le rapport contient le message de l'erreur, son nombre de répétitions, le début de la pile d'appels, et la même photo de l'état que les autres rapports. Les garde-fous :" }, en = { "", "" } },
    { s = "add", fr = { "", "seules les erreurs de WL Helper partent, jamais celles des autres addons ;" }, en = { "", "" } },
    { s = "add", fr = { "", "chaque erreur part une seule fois par version, 5 au plus par session ;" }, en = { "", "" } },
    { s = "add", fr = { "", "/wlh rapports erreurs off coupe l'envoi." }, en = { "WL Helper's Lua errors caught by BugGrabber go to the report inbox by themselves, silently; never other addons' errors; once per version, 5 per session at most; /wlh reports errors off to stop.", "" } },
    { s = "fix", fr = { "Deux boutons qui ne faisaient pas ce qu'ils disaient", "" }, en = { "", "" } },
    { s = "fix", fr = { "Trouver un groupe", "Recliquer sur la note qu'on avait donnée à un joueur ne l'effaçait pas ;" }, en = { "", "" } },
    { s = "fix", fr = { "Commandes", "« Commander à nouveau » sur une commande refusée la renvoyait au même artisan au lieu de la proposer à toute la guilde." }, en = { "Two buttons fixed", "Clearing a player's rating by clicking it again, and re-ordering a declined order to the whole guild." } },
  } },
  { v = "1.0.0-beta.147", date = "2026-11-18", items = {
    { s = "add", fr = { "Les rapports emportent une « photo de l'état »", "En plus du message, de la version et de la position, chaque rapport envoyé avec « Nous écrire » (ou /wlh bug) emporte maintenant :" }, en = { "", "" } },
    { s = "add", fr = { "", "l'action que le guide demande et le numéro de l'étape ;" }, en = { "", "" } },
    { s = "add", fr = { "", "les donjons choisis ;" }, en = { "", "" } },
    { s = "add", fr = { "", "les quêtes du journal, avec celles prêtes à rendre ;" }, en = { "", "" } },
    { s = "add", fr = { "", "la destination du GPS et ce que dit la flèche ;" }, en = { "", "" } },
    { s = "add", fr = { "", "la cible (nom et numéro de PNJ) ;" }, en = { "", "" } },
    { s = "add", fr = { "", "les fenêtres WL Helper ouvertes ;" }, en = { "", "" } },
    { s = "add", fr = { "", "la sous-zone ;" }, en = { "", "" } },
    { s = "add", fr = { "", "les 3 dernières erreurs Lua. De quoi comprendre le problème sans capture." }, en = { "Reports carry a snapshot of the state", "The guide's action and step, picked dungeons, quest log, GPS destination and arrow text, target, open windows, subzone, the last 3 Lua errors." } },
  } },
  { v = "1.0.0-beta.146", date = "2026-11-18", items = {
    { s = "chg", fr = { "La vue moderne par défaut", "Lancer un guide ou ouvrir le guide affiche maintenant la vue moderne. Un clic sur son titre ouvre la fenêtre complète. Pour revenir à l'ancien comportement : Options > Donjons, « Vue moderne par défaut »." }, en = { "The modern view is the guide's default view; a click on its title opens the window (Options > Dungeons to turn it off).", "" } },
    { s = "add", fr = { "Vue moderne, étape précédente / suivante", "Des petites flèches ‹ › autour de « 33/42 » dans l'en-tête font défiler les étapes. Pendant qu'on regarde une autre étape, le libellé orange propose de revenir à l'étape en cours." }, en = { "Modern view", "‹ › arrows in the header browse the steps; a click on the label goes back to the current one." } },
    { s = "add", fr = { "Vue moderne, le menu", "La roue dentée de l'en-tête, ou un clic droit sur le titre, ouvre un menu :" }, en = { "", "" } },
    { s = "add", fr = { "", "ouvrir la fenêtre du guide, guider vers l'étape, marquer l'étape comme faite ;" }, en = { "", "" } },
    { s = "add", fr = { "", "partager les quêtes avec le groupe ;" }, en = { "", "" } },
    { s = "add", fr = { "", "boss et carte du donjon ;" }, en = { "", "" } },
    { s = "add", fr = { "", "avec ou sans cadre, réglages du guide ;" }, en = { "", "" } },
    { s = "add", fr = { "", "arrêter ce guide (second clic pour confirmer), masquer la vue moderne." }, en = { "Modern view", "The gear (or a right-click on the title) opens a menu with the window's actions and settings." } },
    { s = "fix", fr = { "Une quête qui commence avec un objet dit lequel", "Dans la vue moderne, « Prendre « The Essence of Eranikus » · objet « Oathstone of Ysera's Dragonflight » dans tes sacs ». Deux quêtes portent ce nom : la seconde commence avec ce serment." }, en = { "An item-started quest names its item in the modern view (two quests share the name \"The Essence of Eranikus\").", "" } },
    { s = "fix", fr = { "La touche L dans un donjon", "La carte du donjon de Naowh s'affichait toute petite au milieu, à côté du journal de quêtes. Elle se réajuste maintenant à la taille de la carte." }, en = { "L inside a dungeon", "Naowh's dungeon map is fitted again once the window has its size." } },
  } },
  { v = "1.0.0-beta.145", date = "2026-11-18", items = {
    { s = "chg", fr = { "Les rapports ne passent plus par toute la guilde", "Un message envoyé avec « Nous écrire » (ou /wlh bug) part maintenant en privé (chuchotement d'addon), uniquement vers le compte qui reçoit les rapports : celui qui s'est annoncé, sinon le maître de guilde s'il est connecté. L'accusé de réception revient aussi en privé. Le canal de guilde ne sert plus qu'à un petit « je suis là » du compte qui reçoit, à sa connexion puis toutes les 15 minutes. Si personne ne peut recevoir, le message est gardé et part dès que c'est possible." }, en = { "Reports go by addon whisper to the receiving account only (the one that announced itself, else the guild master online), acks too; the guild channel only carries the inbox's small \"I'm here\".", "" } },
  } },
  { v = "1.0.0-beta.144", date = "2026-11-18", items = {
    { s = "chg", fr = { "La vue moderne garde toutes les infos du guide", "Elle ne montrait que l'action en cours et ses objectifs. Elle reprend maintenant tout ce que dit la carte de la fenêtre du guide, en dessous de l'action :" }, en = { "", "" } },
    { s = "chg", fr = { "", "où aller et à quelle distance ;" }, en = { "", "" } },
    { s = "chg", fr = { "", "pourquoi maintenant (prérequis, « requise pour... », optionnelle) ;" }, en = { "", "" } },
    { s = "chg", fr = { "", "ce qui tombe, et les autres objectifs de la quête ;" }, en = { "", "" } },
    { s = "chg", fr = { "", "ce que la quête demandera, la récompense, nos notes et le texte du jeu ;" }, en = { "", "" } },
    { s = "chg", fr = { "", "sur un boss, sa tactique et le butin pour toi. C'est la même information que dans la fenêtre, avec la présentation moderne (sans cadre par défaut)." }, en = { "The modern view now shows everything the guide window's card says: where and how far, why now, drops, other objectives, what the quest asks, reward, notes, the game's text, and on a boss its tactics and loot for you.", "" } },
  } },
}
