# WL Helper Gear

WL Helper Gear is the gear scoring engine used by WL Helper, the addon of the guild
WaR LegenD on WoW Forever. It has no window, tooltip, slash command or chat message
of its own: WL Helper calls its public API (`WLHelperGear`, documented at the top of
`Api.lua`).

It is a modified version of **Geared Forever** by **Nathan**, version **1.1**
(Geared Forever's `## Version: 1.1`), and is distributed under the same licence,
the **GNU General Public License version 3** (full text in `LICENSE.txt`).

WL Helper itself is a separate addon under its own licence (CC BY-NC-SA 4.0). It
contains no code from Geared Forever and only calls this addon's API. The two are
shipped in the same zip as two separate addon folders ("mere aggregation", GPLv3
section 5).

## Credits

- **Geared Forever** by Nathan: stat weights, spec models, scoring, item list.
  Copyright (C) 2026 Nathan, GPLv3. The unmodified original (version 1.1) is
  distributed by its author Nathan as the `GearedForever` addon.
- **ForeverDB**: item data from the WoW Forever launch client (1.60.1.70707), as
  compiled by Geared Forever (`Data.lua`).
- **QuestieDB** by the Questie team and contributors (https://github.com/Questie/QuestieDB),
  GPLv3: quest data (`QuestData.lua`), WoW Forever data set, commit 4dde6c4.
- **Wowhead Forever**: item stats, weapon damage and sources checked by Geared Forever.

## Modifications (GPLv3 section 5a)

All changes made by WaR LegenD on **2026-11-15**, starting from Geared Forever 1.1.

Files:

- `Data.lua`, `QuestData.lua`: copied unchanged, with one credit line added at the top.
- `Engine.lua`: the scoring part of Geared Forever's `Core.lua` (class and spec tables,
  stat weights, hit caps and curves, `Physical` / `Caster` / `Healer` / `Tank`,
  `SpeedBonus`, item parsing, ranking, live item reading, equipped comparison).
- `Api.lua`: new, the public API.
- `SourceData.lua`, `Details.lua`, `Settings.lua`, `Motd.lua`, `Version.lua` and `Media/`
  are not included.

Changes:

1. **Removed**: the window, the item tooltip lines and hooks, the minimap button, the
   slash commands (`/geared`, `/gf`), starred items, the zone reminder, the update
   messages (MOTD and version sharing) and the saved settings. No saved variables.
2. **Renamed**: no global names from Geared Forever are used. The engine lives in the
   addon's private table, the API in the global `WLHelperGear`, the hidden scanning
   tooltip is `WLHelperGearScanTip`. Both addons can be loaded at the same time.
3. **Source data**: `SourceData.lua` (drop, vendor and recipe lists) is not shipped; the
   source category of an item comes from `Data.lua`'s source text and `QuestData.lua`.
   `QuestData.lua` is used only to tell which faction a quest reward belongs to, then
   freed from memory.
4. **Talents read in game** (marked "WL Helper change:"): the spec is picked from the
   talent tree with the most points (overridable). The talent effects Geared Forever
   counts for every player of a spec (Precision, Ice Shards, Elemental Fury, Careful Aim,
   Heart of the Wild...) are counted at the rank you really have. A talent that can't be
   found by name keeps Geared Forever's value.
5. **Hit already owned** (marked "WL Helper change:"): the hit you have from gear,
   enchants and talents (`GetHitModifier` / `GetSpellHitModifier` plus hit rating, read
   with `pcall` and secret values ignored) counts toward the hit cap when it is higher
   than the talent and racial hit Geared Forever counts, so hit loses value as you get
   close to the cap.
6. **Enchants on equipped items** (marked "WL Helper change:"): the enchant on the item
   you wear is read (enchant field of the item link, stats from its tooltip lines) and
   added to it, so a new unenchanted item is compared fairly.
7. **Comparison returns data** instead of tooltip text (percent, slot, equipped link,
   empty, equipped, can use).
8. Off-hand weapon speed stays neutral and the main-hand speed bonus is kept, as upstream
   (WoW Forever's Shank uses the off hand).
9. **Hit just under the cap** (marked "WL Helper change:"): `HitValue` never goes below its
   over-cap value (0.05). Upstream's talent hit never lands just under a cap, so this only
   matters with real hit (change 5): without it 5.99% hit was worth less than 6%.
10. **Items still loading** (marked "WL Helper change:"): an item the client hasn't loaded
    yet is requested (`C_Item.RequestLoadItemDataByID`) and reported as unknown instead
    of being scored and cached with no stats; an enchant tooltip still loading is not
    cached as "no enchant". Item and enchant caches are cleared on `GET_ITEM_INFO_RECEIVED`
    and `PLAYER_EQUIPMENT_CHANGED`. Secret tooltip text is skipped.
11. **Player race and faction** are read again while still unknown, so a first call made
    before the faction is known doesn't turn the faction filter off for the session.
12. **Arcane mage hit** keeps upstream's 2%: Arcane builds get their hit from Arcane Focus,
    not Elemental Precision, so Elemental Precision is not read for Arcane.
13. **API extras**: `Compare` also returns the other hand's result for a one-hander
    (`result.other`), and a feral druid in caster form keeps the last feral form seen
    (cat or bear) instead of falling back to cat.

With no talent data, no hit on the character and no enchant, the scores are the same
as Geared Forever 1.1's.
