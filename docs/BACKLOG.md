# WL Helper : suivi des tickets

Chaque demande devient une ligne ici. Statuts : **À faire**, **En cours**, **Prêt** (fait et testé hors jeu, pas encore publié), **À vérifier en jeu** (publié, en attente de ton retour), **Fait**.
Numéros fixes : `T-NN`. Le CHANGELOG cite le ticket quand il le ferme.

## En cours

| Ticket | Sujet | Où | Notes |
|---|---|---|---|
 Construction lancée |
| T-55 | Hub façon Naowh : une seule fenêtre WL Helper, nav groupée par activité, Accueil en 2 colonnes, réglages rangés par activité, roue dentée dans chaque module | Writs/Hub.lua, Options.lua, Home.lua, Style.lua | Livré beta.79 |

## Prêt (pas encore publié)

| Ticket | Sujet |
|---|---|

## À vérifier en jeu (publié, ton retour attendu)

| Ticket | Sujet | Version | Ce qu'il faut regarder |
|---|---|---|---|
| T-16 | Clic droit sur un portrait de boss = tué / pas tué | beta.71 | Le clic droit cible-t-il aussi le boss ? (ça ne devrait pas) |
| T-17 | Morts de boss vues sur les barres de nom (Nekrum, Sezz'ziz, Bly) | beta.71 | Cochés tout seuls ? |
| T-18 | Fenêtre « Quoi de neuf » après une mise à jour | beta.68 | S'ouvre-t-elle une fois après la prochaine mise à jour ? |
| T-27 | Tournée en ville : le maître de classe (API du formateur) et les munitions des chasseurs (emplacement des munitions) | beta.72 | La fiche s'ouvre-t-elle en arrivant à Orgrimmar ? Les tâches sont-elles justes ? |
| T-28 | Alt + clic : désenchanter / crocheter | beta.72 | Alt + clic gauche sur un objet vert dans les sacs (enchanteur) |
| T-29 | Aller à… avec chemin à pied (WLHelper_Nav) | beta.72 | La flèche suit-elle les routes ? |
| T-30 | Carte du donjon (bouton de la fenêtre des boss) | beta.72 | Quelle carte s'ouvre ? |
| T-31 | Images des raids | beta.72 | Les 3 cartes de raid ont-elles une image ? |
| T-19 | Guide d'un donjon déjà fini (« Me guider dans le donjon ») | beta.69 | Entrée puis boss par boss sur Zul'Farrak |

## À faire

| Ticket | Sujet | Notes |
|---|---|---|
| T-60 | Commandes : écran d'accueil « Artisans » inspiré de Mastercraft (organisation seulement, son code est « tous droits réservés ») : ma fiche d'artisan (disponible / occupé, note pour les acheteurs, mes métiers et niveaux), recherche joueur/objet/recette, cartes « Artisans en ligne », « Favoris » (étoile sur un artisan), « Demandes récentes », « Recettes surveillées » (prévenu quand un artisan de la guilde l'apprend), rangée des métiers avec le nombre d'artisans, « Meilleurs artisans de la semaine » (commandes livrées) ; état d'artisan Disponible / Occupé / Absent (changeable d'un clic sur la minimap), note pour les acheteurs, cacher mes rerolls, partager ma zone, mode calme en donjon (les demandes attendent, l'acheteur sait que tu es dedans et sa place dans la file), Occupé tout seul quand absent ou en file d'attente ; état vide utile (« Aucun artisan en ligne » + Faire une demande / Partager mes recettes) | Writs/Orders.lua, OrdersUI.lua | Livré beta.79 (à vérifier en jeu) |
| T-61 | Réglages des clics : « Clic droit simple = baguette » faisait doublon avec « Touche pour tirer : Aucune » → un seul réglage, migration des joueurs qui l'avaient activé | Clicks, Options, Setup | Livré beta.79 |
| T-62 | Accueil des nouveaux dans la fenêtre WL Helper : une page « Bienvenue » avec une liste de réglage pas à pas par activité (modules, spé, clics, GPS, guide, Writs, commandes) et une progression ; une visite guidée des fonctionnalités (bulles qui montrent chaque bouton dans la vraie fenêtre, Suivant / Précédent / Passer), rejouable à tout moment (page Bienvenue, aide, /wlh visite) ; reprend l'accueil actuel et les « Montre-moi » de l'aide | Setup.lua, Help.lua, Hub | Livré beta.79 (à vérifier en jeu) |
| T-63 | Suivi des temps de recharge des métiers (transmutations, Étoffe lunaire, Salière) sur tous tes personnages, avec un message quand c'est prêt | Livré beta.82 (à vérifier en jeu) |
| T-64 | Prix de revient à l'HV : ce que tu as payé tes composants, et une alerte si tu vends en dessous | Livré beta.82 (à vérifier en jeu) |
| T-65 | Infobulle des objets : « Fabricable par 3 artisans de la guilde (1 en ligne) » | Livré beta.82 (à vérifier en jeu) |
| T-66 | Heures de connexion habituelles de chaque membre (guilde et fiches d'artisan) | Livré beta.82 (à vérifier en jeu) |
| T-67 | Avis de nouvelle version confirmé par au moins 2 membres de la guilde | Livré beta.82 (à vérifier en jeu) |
| T-68 | Structure des textes partout : vrais titres de blocs (Tactique, Conseil, En chemin…), puces alignées, lignes « libellé · valeur », barre de progression des cartes ; appliqué à la carte du guide (étape boss sans trou à côté du portrait), aux cartes de Pick a guide, à l'Overview, à l'aide, à Quoi de neuf, à l'accueil | Theme.lua, DESIGN.md, UI, Bosses, Picker, Overview, Help, Setup, Home, Tracker | Livré beta.79 |
| T-69 | Overview, chaîne dépliée : en frise d'étapes (points numérotés reliés par un trait, l'étape actuelle mise en avant), une ligne par quête (nom + état), une ligne discrète « Jarkal Mossmeld · Terres Ingrates · niv. 42 · 6 750 XP », le texte de la quête replié (clic pour l'ouvrir), de l'espace entre les étapes | Overview.lua | Livré beta.79 (à vérifier en jeu) |
| T-70 | Writs › Achats avec budget maximum (« Budget : 3 po », boutons ou à taper) : choisir le meilleur ensemble de Writs à ce prix en comptant la réput gagnée ET le trajet pour les rendre (zones proches de toi et regroupées, vols et téléports du GPS), puis la tournée dans le meilleur ordre ; afficher « Avec 3 po : 6 Writs, 600 de réput, ~12 min de trajet » ; un réglage « Préférer : la réput / le moins de trajet » ; le bouton Acheter ne dépasse jamais le budget | Writs UI, Ladder/Favor (planificateur), Route (temps de trajet) | Livré beta.79 (à vérifier en jeu) |
| T-71 | Améliorations : retirer le réglage « Méthode » devenu inutile (notre outil d'équipement est toujours livré) | — | Livré beta.79 |
| T-72 | PNJ qui se déplacent (Centaur Pariah…) : dessiner leur trajet sur la carte et la minimap (pointillés d'une autre couleur entre ses points de passage), la flèche va au point le plus proche puis suit le trajet ; l'étape dit « Il se déplace » | Trail.lua, carte du guide | Livré beta.79 |
| T-73 | Quêtes du guide automatiques : prendre, rendre (récompense choisie toute seule en option, sinon « la meilleure pour toi est X »), partager avec le groupe ; Maj = à la main ; en retrait si un autre addon le fait déjà | Comfort.lua, Réglages | Livré beta.79 |
| T-74 | Menu « Actions » du guide trop chargé (10 lignes) : garder 4 actions (Marquer l'étape comme faite, Recalculer la route d'ici, Flèche GPS, Boss du donjon) ; partage auto (T-73), points sur la carte et « points à chaque étape » remplacés par le chemin/repère (ou dans Réglages), « Liste des étapes » déjà en haut (« Étapes »), journal du donjon + boss et rares fusionnés, suivi dans Réglages | UI.lua | Livré beta.79 (à vérifier en jeu) |
| T-75 | Bouton « Cible et objets » du guide : le portrait du PNJ ou du monstre à cibler (modèle du jeu, ou son portrait dès qu'il est vu) au lieu du crâne ; pour un objet du monde, une icône d'objet ; l'objet de quête garde son icône | UI.lua, Bosses.lua | Livré beta.79 (à vérifier en jeu) |
| T-76 | Points de PNJ vérifiés contre 6 sources : 515 quêtes, ~95 % à moins de 3 unités ; corrigés : Lumina Windsinger, Deathstalker Agent ; trajets : Centaur Pariah, Rexxar (Désolace → Féralas), Warosh (note) ; GPS qui va au point le plus proche du trajet puis le suit | Data, Patrols.lua, Engine, Route | Livré beta.79 |
| T-77 | À vérifier en jeu : 94744 (rendue à Da'grosh ou Krom'rosh ?), 3802 (Monument de Franclorn, entrée du Mont Rochenoire), 78699 (commence par une lettre dans une boîte aux lettres de capitale), 6981 (commence par un objet) | — | Ton retour en jeu |
| T-78 | Recherche de groupe façon LFG Forever, en mieux, dans le module Groupes : filtres rôle/classe/langue, demander à rejoindre, invitation rapide, journal des chuchotements, joueurs récents et notes ; en plus : part du guide (donjons et quêtes de ta route pré-remplis), la guilde d'abord (mêmes quêtes, clés, disponibles) | Events.lua, Finder.lua, FinderPeople.lua | Livré beta.79 (à vérifier en jeu) |
| T-79 | Naowh BiS lu en direct (rien copié) : marque « BiS ★ / 2e choix » sur le butin du résumé, des boss et du guide. Le % d'amélioration reste celui de notre outil d'équipement (plafond de toucher, montée de niveau) ; les poids de Naowh seulement si le joueur les a modifiés lui-même dans Naowh | Writs/NaowhBiS.lua, Upgrades ; marques après le chantier guide | Livré beta.79 (à vérifier en jeu) |
| T-80 | Commandes, finitions : ligne « Artisan : Disponible » dans le menu de la minimap (clic = changer d'état), les 2 alertes dans les Réglages, « Me prévenir quand quelqu'un sait le faire » sur la page Demande | Home.lua, Options, OrdersUI | Livré beta.80 |
| T-59 | WLHelper_Gear : se remettre à jour avec Geared Forever (nouvelle version du 16/11 : poids d'armes, etc.) | Livré beta.79 |
| T-55 | Fenêtre façon Naowh, étapes 2 et 3 (modules en deux colonnes : Groupes, Commandes, Writs, Clés) | Livré beta.79 |
| T-23 | Notes de boss et butin au-delà des Mortemines, d'Ombrecroc et des Cavernes | Livré beta.82 (à vérifier en jeu) |
| T-26 | Vérifier en jeu la réduction d'XP des quêtes grises sur le serveur Forever | Règle classique supposée (80/60/40/20/10 %) |
| T-25 | Tickets sur GitHub (Issues) au lieu de ce fichier ? | Décision à toi : public sur le dépôt |
| T-56 | Passeport des clés en grille (moins de défilement vertical dans la fenêtre) | Livré beta.79 |
| T-57 | Commandes : métiers à gauche, catalogue à droite (maître-détail) | Livré beta.79 |
| T-58 | Writs, onglet Aujourd'hui en 2 colonnes | Livré beta.79 |

## Fait (récent)

| Ticket | Sujet | Version |
|---|---|---|
| T-21, T-32 à T-45, T-47, T-48, T-51 à T-53, T-55 (étape 1) | Fenêtre façon Naowh, chemin à pied sur la carte, meilleure route, repère dans le monde, flèche façon Zygor, carte du guide, accueil, renommages, prérequis, marques, erreurs de donjon | beta.74 |
| T-24 | Nom d'auteur GitHub : on garde WarLegenDHelper | décision du 16/11 |
| T-01 à T-14, T-20 | Résumé refait, 4 modules (ville, clés, quêtes en commun, tri), /way, Alt + clic, carte du donjon, Aller à… + WLHelper_Nav, icônes, PvP (origine des HK, K/D/A), images des raids | beta.72 |
| — | Prêt pour le donjon, artisans en pastilles, Zul'Farrak (ordre, Ruuzlu), vraies icônes de récompense | beta.71 |
| — | Marque par /tm | beta.70 |
| — | Recherche des donjons, donjon déjà fini, récompenses, baguette | beta.69 |
| — | Quoi de neuf | beta.68 |
