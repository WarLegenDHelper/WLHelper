# WL Helper : suivi des tickets

Chaque demande devient une ligne ici. Statuts : **À faire**, **En cours**, **Prêt** (fait et testé hors jeu, pas encore publié), **À vérifier en jeu** (publié, en attente de ton retour), **Fait**.
Numéros fixes : `T-NN`. Le CHANGELOG cite le ticket quand il le ferme.

## En cours

| Ticket | Sujet | Où | Notes |
|---|---|---|---|
| T-45 | Prérequis entre maillons de chaîne (ex. Necklace Recovery Take 2 sans Take 1 ; Rot and Regret sans Word of the Woods, confirmé sur Discord) : ajoutés depuis LibForeverData (liens obligatoires / au choix / facultatifs) et Naowh pour les quêtes propres à Forever ; désaccords listés, pas ajoutés | Data.lua | Prêt : Naowh en priorité pour les quêtes Forever et les désaccords (+20 liens) ; 711 routes vérifiées, 0 erreur |
 Construction lancée |
| T-55 | Hub façon Naowh : une seule fenêtre WL Helper, nav groupée par activité, Accueil en 2 colonnes, réglages rangés par activité, roue dentée dans chaque module | Writs/Hub.lua, Options.lua, Home.lua, Style.lua | V1 faite hors jeu (le Hub, l'Accueil dedans en 2 colonnes, les réglages dans la nav, clic droit sur une ligne = ses réglages) ; à voir en jeu : tailles 860 x 80 %, défilement de la nav, `/wlh textes` sans coupure. Restent V2 (réglages regroupés, sections en 2 colonnes, pages Modules / Clics / Guilde et LFG), V3 (roue dentée dans chaque fenêtre), V4 (LFG en liste et détail) |

## Prêt (pas encore publié)

| Ticket | Sujet |
|---|---|
| T-41 | Le guide se fermait après un écran de chargement (téléport, portail, /reload) : il revient tout seul s'il était ouvert |
| T-21/T-22 | Passe interface et textes sur toutes les fenêtres (vocabulaire, niveaux « niv. », nombres, icônes, aide, guilde, commandes, réglages, boss) |
| T-43 | Chemin à pied comme Polestar pour toutes les destinations : la flèche suit le chemin coin après coin, distance à pied restante, points sur la carte du monde et la minimap, épingle précise, réglages carte / minimap |
| T-47 | Marques de raid : le jeu interdit à un addon de poser une marque (même /tm dans une macro écrite par l'addon → ADDON_ACTION_FORBIDDEN). Nos boutons et la macro ne font plus que cibler ; textes « Cibler » |
| T-48 | Erreurs BugSack : GUID secret au PNJ des caisses (Comfort.lua:80) et alerte des rares (Journal.lua) protégés |
| T-40 | Vue d'ensemble : icônes de récompense qui manquaient (Restorative Potion, Platinum Discs) lues sans attendre le serveur (GetItemInfoInstant + LibForeverData) ; amélioration plus lisible (flèche verte sur l'icône, « +44 % » plus grand) |
| T-32 | Fenêtre « Quoi de neuf » refaite : version et date, changements groupés (Nouveau / Amélioré / Corrigé), titre + une phrase, point de couleur |

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
| T-33 | Accueil : remplacer la carte « Comment faire ? » (aide dans un « ? » de l'en-tête), « Où veux-tu aller ? » (Aller à…) en haut, outils en grille compacte avec repli « Tous les outils », outils de contexte en premier (Tournée en ville dans une capitale, Tri quand le journal est plein) | Prêt |
| T-35 | Bouton retour (chevron vers l'accueil) sur les fenêtres des nouveaux modules : Tournée en ville, et vérifier Passeport des clés, Quêtes en commun, Tri du journal, Aller à… | Prêt |
| T-36 | Aller à… : les distances de la liste se mettent à jour pendant que tu bouges (et les « plus proches » changent de ville/zone avec toi) | Prêt |
| T-37 | Guide, carte de l'étape à refaire : ce qu'il faut faire en premier (« Ramasser le collier brisé · 0 sur 1 » au lieu de « - 0/1 Shattered Necklace »), où (zone · distance, GPS), pourquoi (quête, étape 1 sur 6) en une ligne discrète, détails repliés (butins, texte) ; plus aucune info répétée (« En cours » ×2, le PNJ ×3, la zone ×2, prérequis ×3) ; de l'air entre les groupes | Prêt |
| T-42 | Étape « Prendre la quête » : la carte montrait le texte de la quête (« Venture to Maraudon… ») comme si c'était à faire maintenant ; elle doit dire « Va voir Woodwyrd à Shen'dralas et prends Rot and Regret », le texte de la quête replié en « Ce qu'elle demandera ensuite » | Prêt |
| T-38 | Renommer « Summary » en « Overview » (français : « Vue d'ensemble ») partout : bouton du guide, titre de la fenêtre, boutons « Voir le résumé », aide | Prêt |
| T-39 | Renommer « Pick dungeons » en « Pick a guide » (français : « Choisir un guide ») : bouton du guide et titre de la fenêtre de choix (elle couvre donjons, raids et quêtes de classe) | Prêt |
| T-34 | « Quoi de neuf » : retrouver les couleurs par type (Nouveau / Amélioré / Corrigé) et le point devant chaque changement | Prêt |
| T-23 | Notes de boss et butin au-delà des Mortemines, d'Ombrecroc et des Cavernes | |
| T-26 | Vérifier en jeu la réduction d'XP des quêtes grises sur le serveur Forever | Règle classique supposée (80/60/40/20/10 %) |
| T-25 | Tickets sur GitHub (Issues) au lieu de ce fichier ? | Décision à toi : public sur le dépôt |
| T-56 | Passeport des clés en grille (moins de défilement vertical dans la fenêtre) | Après T-55 |
| T-57 | Commandes : métiers à gauche, catalogue à droite (maître-détail) | Après T-55 |
| T-58 | Writs, onglet Aujourd'hui en 2 colonnes | Après T-55 |

## Fait (récent)

| Ticket | Sujet | Version |
|---|---|---|
| T-24 | Nom d'auteur GitHub : on garde WarLegenDHelper | décision du 16/11 |
| T-01 à T-14, T-20 | Résumé refait, 4 modules (ville, clés, quêtes en commun, tri), /way, Alt + clic, carte du donjon, Aller à… + WLHelper_Nav, icônes, PvP (origine des HK, K/D/A), images des raids | beta.72 |
| — | Prêt pour le donjon, artisans en pastilles, Zul'Farrak (ordre, Ruuzlu), vraies icônes de récompense | beta.71 |
| — | Marque par /tm | beta.70 |
| — | Recherche des donjons, donjon déjà fini, récompenses, baguette | beta.69 |
| — | Quoi de neuf | beta.68 |
