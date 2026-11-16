# WL Helper : suivi des tickets

Chaque demande devient une ligne ici. Statuts : **À faire**, **En cours**, **Prêt** (fait et testé hors jeu, pas encore publié), **À vérifier en jeu** (publié, en attente de ton retour), **Fait**.
Numéros fixes : `T-NN`. Le CHANGELOG cite le ticket quand il le ferme.

## En cours

| Ticket | Sujet | Où | Notes |
|---|---|---|---|
 Construction lancée |
| T-55 | Hub façon Naowh : une seule fenêtre WL Helper, nav groupée par activité, Accueil en 2 colonnes, réglages rangés par activité, roue dentée dans chaque module | Writs/Hub.lua, Options.lua, Home.lua, Style.lua | V1 faite hors jeu (le Hub, l'Accueil dedans en 2 colonnes, les réglages dans la nav, clic droit sur une ligne = ses réglages) ; à voir en jeu : tailles 860 x 80 %, défilement de la nav, `/wlh textes` sans coupure. Restent V2 (réglages regroupés, sections en 2 colonnes, pages Modules / Clics / Guilde et LFG), V3 (roue dentée dans chaque fenêtre), V4 (LFG en liste et détail) |

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
| T-59 | WLHelper_Gear : se remettre à jour avec Geared Forever (nouvelle version du 16/11 : poids d'armes, etc.) | Lancé |
| T-55 | Fenêtre façon Naowh, étapes 2 et 3 (modules en deux colonnes : Groupes, Commandes, Writs, Clés) | Lancé |
| T-23 | Notes de boss et butin au-delà des Mortemines, d'Ombrecroc et des Cavernes | |
| T-26 | Vérifier en jeu la réduction d'XP des quêtes grises sur le serveur Forever | Règle classique supposée (80/60/40/20/10 %) |
| T-25 | Tickets sur GitHub (Issues) au lieu de ce fichier ? | Décision à toi : public sur le dépôt |
| T-56 | Passeport des clés en grille (moins de défilement vertical dans la fenêtre) | Après T-55 |
| T-57 | Commandes : métiers à gauche, catalogue à droite (maître-détail) | Après T-55 |
| T-58 | Writs, onglet Aujourd'hui en 2 colonnes | Après T-55 |

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
