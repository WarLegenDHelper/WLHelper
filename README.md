<p align="center">
  <img src="docs/logo.png" width="96" height="96" alt="War Legend">
</p>

<h1 align="center">WL Helper</h1>

<p align="center">
  Guide des quêtes de donjon, Comptoir des writs et GPS intégré pour <b>World of Warcraft: Forever</b>.<br>
  Français et anglais, selon la langue de ton client.
</p>

<p align="center">
  <a href="https://github.com/WarLegenDHelper/WLHelper/releases/latest"><img alt="Dernière version" src="https://img.shields.io/github/v/release/WarLegenDHelper/WLHelper?label=version&color=CE1918"></a>
  <a href="LICENSE"><img alt="Licence" src="https://img.shields.io/badge/licence-CC%20BY--NC--SA%204.0-555"></a>
  <a href="README.en.md"><img alt="English" src="https://img.shields.io/badge/read%20in-English-555"></a>
</p>

---

## Installer

**Avec WowUp** : *Get Addons* → *Install from URL* → colle `https://github.com/WarLegenDHelper/WLHelper` → *Import*.
Les mises à jour arrivent ensuite d'elles-mêmes.

**À la main** : télécharge le zip de la [dernière version](https://github.com/WarLegenDHelper/WLHelper/releases/latest) et
décompresse-le dans `World of Warcraft\_forever_\Interface\AddOns`. Le dossier `WLHelper` doit se trouver
directement dans `AddOns`.

## Ce que fait l'addon

### Donjons
Toutes les quêtes de donjon Horde, étape par étape.
- Tu choisis un ou plusieurs donjons ; l'addon calcule une seule route depuis ta position, pré-quêtes comprises.
- Check-list avant d'entrer, points sur la carte, boutons pour cibler, marquer et utiliser l'objet de quête.
- Partage des quêtes au groupe, et suivi de l'avancée des membres qui ont l'addon.
- Les chaînes longues aussi : clés et accès, Dead Man's Plea, amulette de Valthalak, Quel'Serrar.

### Comptoir
Les Craftsman's Writs et la réputation des comptoirs (Durotar Supply and Logistics, Azeroth Commerce Authority).
- Les writs les moins chers pour ton prochain rang, avec les prix de l'hôtel des ventes (scan intégré, ou Auctionator / TSM).
- La liste d'achat, l'état du jour (prêt, enveloppe à ouvrir, objet manquant) et une tournée GPS jusqu'aux PNJ.
- Acceptation et remise automatiques des writs, rappel à la connexion, infobulle sur les enveloppes.

### GPS
Le chemin le plus rapide jusqu'au PNJ ou au donjon.
- Monture, points de vol connus, zeppelins, bateaux et téléportations de mage.
- Une flèche avec l'étape en cours, et des boutons « Vol → … » et « Lancer la téléportation ».
- Si Zygor est installé, sa flèche peut guider à la place (option).

### Sacs
Le nettoyeur repère les objets de quête qui ne servent plus et les détruit en un clic.
Ceux qui peuvent servir à une quête suivante sont signalés et ne sont pas cochés.

## Commandes

| Commande | Effet |
|---|---|
| `/wl` | Accueil |
| `/wl donjons` | Le guide des donjons |
| `/wl choisir` | Choisir les donjons |
| `/wl comptoir` | Ouvre ou ferme le Comptoir (aussi `/comptoir`) |
| `/wl gps` | Arrête ou relance le guidage |
| `/wl sacs` | Nettoyeur de sacs |
| `/wl reglages` | Réglages (aussi `/wlo`) |
| `/wl idee` | Proposer une idée ou signaler un bug |
| `/wl aide` | Toutes les commandes |

Bouton de la minimap : clic pour l'accueil, clic droit pour un menu vers chaque module.

## Une idée, un bug ?

Ouvre un [ticket](https://github.com/WarLegenDHelper/WLHelper/issues/new/choose) : idée, bug ou donnée de quête fausse.
En jeu, `/wl idee` te donne le lien déjà rempli avec ta version.

## Bon à savoir

- **Le dossier s'appelle `WLHelper`** depuis la 1.0.0-beta.4 (avant : `DungeonGuide`). Si tu avais installé une
  ancienne version à la main, supprime le dossier `DungeonGuide`. S'il traîne encore, l'addon le
  désactive tout seul et te le dit.
- **Versions** : `1.0.0-beta.8` veut dire bêta de la 1.0. Le détail de chaque version est dans le
  [CHANGELOG](CHANGELOG.md).

## Crédits et licence

Données et idées reprises d'autres projets, tous cités dans [`CREDITS.txt`](WLHelper/CREDITS.txt) :
LibForeverData, RestedXP Guides, Naowh Forever, ForeverDungeonJournal, Wowhead, TradeSkillMaster, wow.gg, Zygor
(coordonnées seulement). Logo : War Legend Raid Tool.

Licence [CC BY-NC-SA 4.0](LICENSE) : usage non commercial, même licence pour les versions modifiées.
Auteur : Alandir (WarLegend).
