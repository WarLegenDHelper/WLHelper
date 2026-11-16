# WL Helper : suivi des tickets

Chaque demande devient une ligne ici. Statuts : **À faire**, **En cours**, **Prêt** (fait et testé hors jeu, pas encore publié), **À vérifier en jeu** (publié, en attente de ton retour), **Fait**.
Numéros fixes : `T-NN`. Le CHANGELOG cite le ticket quand il le ferme.

## En cours

| Ticket | Sujet | Où | Notes |
|---|---|---|---|
| — | (rien en ce moment) | | |

## Prêt (pas encore publié)

| Ticket | Sujet |
|---|---|
| — | (rien) |

## À vérifier en jeu (publié, ton retour attendu)

| Ticket | Sujet | Version | Ce qu'il faut regarder |
|---|---|---|---|
| T-15 | Marque sur le boss par `/tm` | beta.70 | Le crâne se pose-t-il au clic sur un portrait ? Sinon, `/tm 8` à la main marche-t-il ? |
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
| T-21 | Passe complète sur l'interface, la mise en forme du texte et l'architecture de l'information, fenêtre par fenêtre (accueil, guide, suivi, boss, commandes, guilde, groupes, réglages, accueil des nouveaux) | Après T-01 et T-10 ; s'appuie sur l'audit (problèmes par fenêtre classés par impact) |
| T-22 | Icônes et clarté de la fenêtre des boss (épingle, en-tête) | Laissé hors de T-10 car T-08 modifie Bosses.lua |
| T-23 | Notes de boss et butin au-delà des Mortemines, d'Ombrecroc et des Cavernes | |
| T-26 | Vérifier en jeu la réduction d'XP des quêtes grises sur le serveur Forever | Règle classique supposée (80/60/40/20/10 %) |
| T-24 | Nom de l'auteur dans WowUp (renommer le compte GitHub) | Décision à toi : quel nom ? |
| T-25 | Tickets sur GitHub (Issues) au lieu de ce fichier ? | Décision à toi : public sur le dépôt |

## Fait (récent)

| Ticket | Sujet | Version |
|---|---|---|
| T-01 à T-14, T-20 | Résumé refait, 4 modules (ville, clés, quêtes en commun, tri), /way, Alt + clic, carte du donjon, Aller à… + WLHelper_Nav, icônes, PvP (origine des HK, K/D/A), images des raids | beta.72 |
| — | Prêt pour le donjon, artisans en pastilles, Zul'Farrak (ordre, Ruuzlu), vraies icônes de récompense | beta.71 |
| — | Marque par /tm | beta.70 |
| — | Recherche des donjons, donjon déjà fini, récompenses, baguette | beta.69 |
| — | Quoi de neuf | beta.68 |
