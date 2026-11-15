# Changelog

Toutes les versions de WL Helper. Format : [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/),
numéros : [SemVer](https://semver.org/lang/fr/) (voir « Versions » dans le README).
*All WL Helper versions. Format: Keep a Changelog; numbers: SemVer (see "Versions" in the README).*

## [Unreleased]

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

[Unreleased]: https://github.com/NEM3S15/WLHelper/compare/v1.0.0-beta.2...HEAD
[1.0.0-beta.2]: https://github.com/NEM3S15/WLHelper/compare/v1.0.0-beta.1...v1.0.0-beta.2
[1.0.0-beta.1]: https://github.com/NEM3S15/WLHelper/releases/tag/v1.0.0-beta.1
