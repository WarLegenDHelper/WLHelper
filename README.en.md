<p align="center">
  <img src="docs/logo.png" width="96" height="96" alt="War Legend">
</p>

<h1 align="center">WL Helper</h1>

<p align="center">
  Dungeon quest guide, Craftsman's Writs planner and built-in GPS for <b>World of Warcraft: Forever</b>.<br>
  English and French, following your game client's language.
</p>

<p align="center">
  <a href="https://github.com/WarLegenDHelper/WLHelper/releases/latest"><img alt="Latest version" src="https://img.shields.io/github/v/release/WarLegenDHelper/WLHelper?label=version&color=CE1918"></a>
  <a href="LICENSE"><img alt="License" src="https://img.shields.io/badge/license-CC%20BY--NC--SA%204.0-555"></a>
  <a href="README.md"><img alt="Français" src="https://img.shields.io/badge/lire%20en-fran%C3%A7ais-555"></a>
</p>

---

## Install

**With WowUp**: *Get Addons* → *Install from URL* → paste `https://github.com/WarLegenDHelper/WLHelper` → *Import*.
Updates then arrive by themselves.

**Manually**: download the zip of the [latest version](https://github.com/WarLegenDHelper/WLHelper/releases/latest) and
unzip it into `World of Warcraft\_forever_\Interface\AddOns`. The `WLHelper` folder must sit directly in `AddOns`.

## What it does

### Dungeons
Every Horde dungeon quest, step by step.
- Pick one or several dungeons; the addon plans a single route from where you stand, prerequisites included.
- A ready check before you go in, map points, buttons to target, mark and use the quest item.
- Quest sharing with your group, and the progress of group members who also run the addon.
- Long chains too: keys and attunements, Dead Man's Plea, the Valthalak amulet, Quel'Serrar.

### Trading Post
Craftsman's Writs and the trade company reputation (Durotar Supply and Logistics, Azeroth Commerce Authority).
- The cheapest writs for your next standing, with auction house prices (built-in scan, or Auctionator / TSM).
- The shopping list, today's state (ready, envelope to open, item missing) and a GPS tour to the turn-in NPCs.
- Auto accept and turn-in of writs, a login reminder, an envelope tooltip.

### GPS
The fastest way to the NPC or the dungeon.
- Mount, known flight paths, zeppelins, boats and mage teleports.
- An arrow with the current step, plus "Fly → …" and "Cast the teleport" buttons.
- If you have Zygor, its arrow can guide instead (option).

### Bags
The cleaner finds quest items you no longer need. It only deletes the ones it can prove useless
(all their quests turned in); the others are listed only.

### Orders
Have the guild or one crafter make an item, like retail crafting orders.
- Who provides each reagent, fee, tip, duration; the crafter accepts or declines with a reason.
- Inbox check of what the crafter received, mail filled for you.

### Upgrades
A green arrow on bag items better than yours, judged by Geared Forever (game bags and Baganator).

### Clicks
Alt-click to invite (chat, world, portraits) and Shift + right-click to shoot an enemy.

## Commands

| Command | What it does |
|---|---|
| `/wl` | Home |
| `/wl dungeons` | The dungeon guide |
| `/wl pick` | Pick dungeons |
| `/wl trade` | Open or close the Trading Post |
| `/wl gps` | Stop or restart guidance |
| `/wl bags` | Bag cleaner |
| `/wl orders` | Crafting orders |
| `/wl welcome` | Welcome screen: modules and clicks |
| `/wl options` | Settings (also `/wlo`) |
| `/wl idea` | Suggest an idea or report a bug |
| `/wl help` | Every command |

Minimap button: click for home, right-click for a menu to each module.

## An idea, a bug?

Open an [issue](https://github.com/WarLegenDHelper/WLHelper/issues/new/choose): idea, bug or wrong quest data.
In game, `/wl idea` gives you the link already filled with your version.

## Good to know

- **The folder is named `WLHelper`** since 1.0.0-beta.4 (it was `DungeonGuide`). If you installed an older
  version by hand, delete the `DungeonGuide` folder. If it is still there, the addon turns
  it off and tells you.
- **Versions**: `1.0.0-beta.16` means a beta of 1.0. Every version is detailed in the [CHANGELOG](CHANGELOG.md).

## Credits and license

Data and ideas from other projects, all listed in [`CREDITS.txt`](WLHelper/CREDITS.txt): LibForeverData,
RestedXP Guides, Naowh Forever, ForeverDungeonJournal, Wowhead, TradeSkillMaster, wow.gg, Zygor (coordinates
only). Logo: War Legend Raid Tool.

License [CC BY-NC-SA 4.0](LICENSE): non-commercial use, same license for modified versions.
Author: Alandir (WarLegend).
