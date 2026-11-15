# WL Helper (bêta / beta)

Addon pour **World of Warcraft: Forever** (client 1.60.1). FR / EN.
*Addon for **World of Warcraft: Forever** (client 1.60.1). French / English — English below.*

## Français

**Guide de donjons**
- Toutes les quêtes de donjon Horde, pas à pas : choix des donjons, route sur plusieurs donjons depuis ta position, check-list avant d'entrer.
- Points de passage, boutons cibler / marquer et objet de quête, partage des quêtes au groupe.

**Craftsman's Writs** (réputation des comptoirs : Durotar Supply and Logistics / Azeroth Commerce Authority)
- Les writs que tu peux faire, avec leur prix : scan de l'hôtel des ventes intégré, ou Auctionator / TSM s'ils sont là.
- État du jour (rendu, prêt, objet manquant), plan d'achat pour le rang suivant, liste d'achat avec rescan au moment d'acheter.
- Valeur des Coin Pouch mesurée quand tu les ouvres, writs réservés à l'autre faction masqués.

**GPS intégré**
- Le chemin le plus rapide jusqu'au PNJ ou au donjon : monture, points de vol connus, zeppelins, bateaux, téléportations de mage.
- Une flèche à l'écran avec l'étape en cours ; boutons « Prendre le vol » et « Lancer la téléportation ».
- Ouvre une carte de vol une fois pour que le GPS apprenne tes points de vol.

**Commandes**

| Commande | Effet |
|---|---|
| `/wl` | ouvre ou ferme le guide de donjons (`/dg` marche aussi) |
| `/wl pick` | choisir les donjons |
| `/wl writs` | panneau des writs (`/writs`) |
| `/wl writs gps` | tournée GPS des writs prêts à rendre |
| `/wl writs scan` | scanne la liste d'achat (HV ouvert) |
| `/wl lang fr` / `en` | langue |
| `/wl help` | toutes les commandes |

Bouton de la minimap : clic = guide, clic droit = donjons, Maj-clic = writs.

## English

**Dungeon guide**: every Horde dungeon quest step by step — dungeon picker, multi-dungeon route from where you stand, ready check, waypoints, target/mark and quest item buttons, quest sharing.

**Craftsman's Writs** (trade company reputation): writ prices from the built-in auction house scan (or Auctionator / TSM), today's state, a buying plan to the next standing, a shopping list rescanned when you buy, measured Coin Pouch values, other-faction writs hidden.

**Built-in GPS**: fastest way to the NPC or the dungeon using your mount, known flight paths, zeppelins, boats and mage teleports, with an on-screen arrow and "take flight" / "cast teleport" buttons. Open a flight map once so it learns your flight paths.

Commands: `/wl`, `/wl pick`, `/wl writs`, `/wl writs gps`, `/wl writs scan`, `/wl lang fr|en`, `/wl help`. Minimap button: click = guide, right-click = dungeons, Shift-click = writs.

## Installation

**WowUp**: *Get Addons* → *Install from URL* → colle / paste `https://github.com/NEM3S15/WLHelper` → *Import*. Les mises à jour arrivent ensuite toutes seules / updates then come automatically.

**À la main / manually**: télécharge le zip de la dernière [release](https://github.com/NEM3S15/WLHelper/releases/latest) et décompresse-le dans `World of Warcraft\_forever_\Interface\AddOns` (le dossier `DungeonGuide` doit se retrouver directement dans `AddOns`).

## Versions

Numéros [SemVer](https://semver.org/lang/fr/) : `MAJEUR.MINEUR.CORRECTIF`, avec `-beta.N` tant que c'est en test.
- **CORRECTIF** (1.0.**1**) : corrections, données mises à jour.
- **MINEUR** (1.**1**.0) : nouvelles fonctions, rien ne casse.
- **MAJEUR** (**2**.0.0) : un changement qui casse quelque chose (réglages remis à zéro, commande retirée…).

Le numéro vient d'un seul endroit, le `## Version` de `DungeonGuide/DungeonGuide.toc` ; chaque version a son
tag `vX.Y.Z`, sa release GitHub avec le zip, et son entrée dans le [CHANGELOG](CHANGELOG.md). En jeu : `/wl help`.
*SemVer numbers; the toc's version is the only source; each version has its `vX.Y.Z` tag, a GitHub release with the zip and a CHANGELOG entry.*

## Crédits / Credits

Voir / see [`DungeonGuide/CREDITS.txt`](DungeonGuide/CREDITS.txt): LibForeverData (CC BY 4.0), RestedXP Guides (CC BY-NC-SA 4.0), Naowh Forever, ForeverDungeonJournal, Wowhead (via Waylaid Crate and Writs Helper), TradeSkillMaster, wow.gg, Zygor (coordinates only).

## Licence / License

[CC BY-NC-SA 4.0](LICENSE) — gratuit, non commercial, mêmes conditions de partage (imposé par les parties reprises de RestedXP). *Free, non-commercial, share-alike (required by the parts adapted from RestedXP).*
