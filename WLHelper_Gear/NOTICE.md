# WL Helper Gear

WL Helper Gear is the gear scoring engine used by WL Helper, the addon of the guild
WaR LegenD on WoW Forever. It has no window, tooltip, slash command or chat message
of its own: WL Helper calls its public API (`WLHelperGear`, documented at the top of
`Api.lua`).

It is a modified version of **Geared Forever** by **Nathan**, version **1.1.1**
(Geared Forever's `## Version: 1.1.1`, released 2026-11-16; the fork was first made
from version 1.1), and is distributed under the same licence,
the **GNU General Public License version 3** (full text in `LICENSE.txt`).

WL Helper itself is a separate addon under its own licence (CC BY-NC-SA 4.0). It
contains no code from Geared Forever and only calls this addon's API. The two are
shipped in the same zip as two separate addon folders ("mere aggregation", GPLv3
section 5).

## Credits

- **Geared Forever** by Nathan: stat weights, spec models, scoring, item list.
  Copyright (C) 2026 Nathan, GPLv3. The unmodified original (version 1.1.1) is
  distributed by its author Nathan as the `GearedForever` addon.
- **ForeverDB**: item data from the WoW Forever launch client (1.60.1.70707), as
  compiled by Geared Forever (`Data.lua`).
- **QuestieDB** by the Questie team and contributors (https://github.com/Questie/QuestieDB),
  GPLv3: quest data (`QuestData.lua`), WoW Forever data set, commit 4dbb824 (as shipped
  with Geared Forever 1.1.1).
- **Wowhead Forever**: item stats, weapon damage and sources checked by Geared Forever.

## Modifications (GPLv3 section 5a)

Changes 1 to 34 made by WaR LegenD on **2026-11-15**, starting from Geared Forever 1.1;
changes 35 to 37 on **2026-11-16**, when Geared Forever 1.1.1 was ported (see the last
section).

Files:

- `Data.lua`, `QuestData.lua`: copied unchanged from Geared Forever 1.1.1, with one credit
  line added at the top.
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
   freed from memory (its rewards by quest are kept first, see change 34).
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

### Scoring changes, version 2 (2026-11-15)

Also made by WaR LegenD on **2026-11-15**, marked "WL Helper change (v2)" in `Engine.lua`
and `Api.lua`. `WLHelperGear.SetOptions({ neutral = true })` turns all of them off.

14. **Proc and use effects** (`PROCS` table in `Engine.lua`): Hand of Justice, Earthstrike,
    Ironfoe, Flurry Axe, Thrash Blade, Annihilator, Arcanite Champion, Fiery War Axe, Teebu's
    Blazing Longsword, Barovian Family Sword, Skullforge Reaver, Darkmoon Card: Blue Dragon,
    The Eye of Divinity, Hazza'rah's Charm of Healing, Talisman of Ascendance and Talisman of
    Ephemeral Power get their effect as average stats or as a share of melee damage, in
    `Best` lists and comparisons. Values follow vanilla mechanics, on the low side.
15. **Use lines read from the tooltip** in `Compare` and `Score` for items not in that table
    ("Use: Increases attack power by 200 for 20 sec. (2 Min Cooldown)" = amount x duration /
    cooldown x 0.8). Proc lines that can't be valued are reported ("proc not counted").
16. **Worn items with no score** (use or proc trinkets) are no longer reported as an empty
    slot: `Compare` returns `unscored = true` and no percent, or compares against the other
    ring or trinket slot when that one has a score.
17. **Proc and percent enchants**: Crusader, Fiery Weapon, Lifestealing, Icy Chill, Iron
    Counterweight and Biznicks Accurascope on worn items are counted by enchant ID; "+2% hit",
    "attack speed by 3%" and similar lines become rating (10 hit, 10 haste, 14 crit, 12 dodge,
    15 parry, 5 block = 1%); scope "+N Damage" counts as weapon damage.
18. **Set bonuses** in `Compare`: the set (GetItemInfo setID) and its "(N) Set:" lines are read;
    a bonus the new item completes is added to it, a bonus it breaks is added to what you wear.
19. **Hit caps split by kind**: below raid level spells cap at 5% and melee at 6%; the raid caps
    (17% / 8%) apply at level 60 once WoW Forever's raids open (December 9, 2026), or when
    forced with `SetOptions({ raid = true })` (58+). Before, every 58+ character used raid caps.
20. **Tank defense cap**: for your own class at 58+, with the defense read from the game
    (`UnitDefense`, combat rating), defense below the crit-immunity cap (440 at 60) is worth
    about twice its avoidance value, above it only the avoidance part; item defense is scaled
    by the rating-to-skill ratio when the client gives one. No reading: upstream's value.
21. **Bear tanks**: no parry value, and defense counts only miss and dodge.
22. **Random suffixes**: the same base item with another suffix is no longer reported as the
    item you wear.
23. **API**: `Compare` returns `notes` (effects counted, set bonuses, enchant counted),
    `unscored`, `setGain` and `setLost`; `Score` returns `details.notes`; `Weights` returns
    `hitCap` and `defense`; new `SetOptions` / `Options`.

### Scoring fixes, version 3 (2026-11-15)

Also made by WaR LegenD on **2026-11-15**, marked "WL Helper change (v3)" in `Engine.lua`
and `Api.lua`. `SetOptions({ neutral = true })` turns them off as well.

24. **Use lines are not worn stats**: an item read from its link no longer takes the spell
    power of a "Use:" line ("by up to 175 for 15 sec") as permanent spell power. Talisman
    of Ephemeral Power counted 175 + 23 spell power; it now counts its 23 average only.
25. **Cooldowns**: "(1 Min, 30 Sec Cooldown)" is 90 s (was 60 s); French tooltips
    ("Utiliser :" with a normal or no-break space, "(Recharge : 2 min)", "1 min 30 s") are read.
26. **Percent lines**: hit needs "chance to hit" or "+N% hit"; "chance on hit" lines are procs,
    not stats. Spell hit, spell crit and casting speed count only for casters and healers,
    melee hit, crit and attack speed only for the other specs.
27. **Set info**: "no set" is remembered only once the item info is loaded, so set bonuses
    are found for items seen right after login.
28. **Compare**: `score` now includes `setGain` like `old` includes `setLost`, so
    `(score - old) / old` is the percent.
29. **Tanks**: extra-attack procs are worth half their damage share, like haste.
30. **Defense cap**: the below-cap value (about twice the avoidance value) is a cap-priority
    heuristic, not a mean-damage derivation. Data.lua defense is skill points and is no longer
    scaled; only defense rating read from a link is turned into skill points (ratio from the
    client). To be checked in game.
31. **Random suffixes**: an item with no link (Data.lua) is compared by ID as before.
32. **Raid caps**: inside a raid instance (`IsInInstance`) the raid hit caps apply. Outside,
    the automatic switch still uses a fixed date (December 9, 2026) and the client date; if
    WoW Forever moves the raid opening, use `SetOptions({ raid = true })`, which is not saved
    between sessions.
33. **Speed**: a tooltip not loaded yet is not scanned again for 1 second, and the worn set
    items are read once per frame instead of once per `Compare` section.

### Quest rewards, version 4 (2026-11-15)

Also made by WaR LegenD on **2026-11-15**, marked "WL Helper change (v4)" in `Engine.lua`
and `Api.lua`. Scores are not affected.

34. **Rewards by quest**: new `WLHelperGear.QuestRewards(questID)` returns the items a quest
    gives, `{ itemID, ... }`, plus their English names (`Data.lua` or `QuestData.lua`), so
    WL Helper's dungeon summary can show the reward items and compare them. The list is the
    quest's own reward list from `QuestData.lua` (`ns.quests[id]` rewards) followed by
    `ns.itemQuests` inverted for the gear items that list misses. It is built once, on the
    first `QuestRewards` call or the first parse (before `QuestData.lua` is freed), as one
    compact string per quest (about 1,200); a quest's table is made only when asked for.
    The data does not say which rewards are a choice: WL Helper uses its own data for that.

### Geared Forever 1.1.1 ported, version 1.3.0 (2026-11-16)

Every change from Geared Forever 1.1 to 1.1.1 (2026-11-16) in its scoring and data was
ported (checked against Geared Forever 1.1.1 itself: same item list, same weights for every
spec and level). Its window, tooltip and settings changes
(starred items and Starred tab, per-character level ranges, window scale, Shift-only
tooltip, "special effect, not rated" tooltip line, minimap right-click, settings command)
are not, as this addon has none of those.

Ported from Geared Forever 1.1.1 (Nathan's work, unchanged):

- **Leveling weights fade 50 to 60** (`LevelFade`, `Blend`, `LevelingSta`, `ApplyLeveling`):
  leveling numbers count in full up to 50 and fade evenly into the level 60 numbers (55 = half).
  Stamina is worth more while leveling for every role (physical 0.8, casters 0.4, healers 0.3),
  armor 0.03 for physical specs (0.01 at 60); casters get Intellect 0.55 and Spirit 0.35 at
  least, and their wand weight 2 (was 1.2).
- **Per-spec leveling overrides** (`lvl`): Arms and Fury Stamina 1.3; Protection paladin spell
  power 1.2, Stamina 1.0, Intellect 0.6, Strength 0.4; Retribution Stamina 1.3, spell power 1.8,
  Intellect 0.6; Beast Mastery Intellect 1.0, Spirit 0.8, Stamina 0.6; Marksmanship Spirit 0.8,
  Stamina 0.6; Survival Intellect 0.8, Spirit 0.6, Stamina 0.6; Arcane Spirit 0.5 and
  Intellect 0.9; Affliction and Demonology Spirit 0.6; Destruction Spirit 0.5, Intellect 0.7.
- **Enhancement shaman**: spell power 0.8 while leveling, fading to 1.4 at 60 (and the
  Intellect attack power that follows it).
- **Hunters**: plain "+Attack Power" counts in full (1, was 0.1); Survival gets +0.5 more for
  the bow; thrown weapons count their stats only (no DPS), as hunter shots need a bow, gun or
  crossbow (`HUNTER_RANGED`, `prefer.statsOnly` in `SectionScore`).
- **Live items**: an item from the list is also read from its link when the list has no stats
  for it or the link's name differs (random suffix placed elsewhere in the link).
- **Data**: `Data.lua` from 1.1.1 (stats, weapon damage and new gear checked against Wowhead
  Forever on Nov 15: placeholder and removed items dropped, new Blackmaw Hold and dungeon drops,
  stat fixes) and `QuestData.lua` from 1.1.1 (QuestieDB commit 4dbb824).

Our changes for this port (marked "WL Helper change (1.3.0)"):

35. **Mental Quickness** (talent read in game, change 4) now follows the enhancement spell
    power value, which fades with the level: its full value is 30% of that spell power.
    As in 1.1.1, up to level 50 a leveling override (`lvl`) replaces the weight it sets, so
    the "talents you really have" adjustment of that weight (for example Retribution
    Intellect and Champion of the Light) only fades in from 50.
36. **Live items on non-English clients**: the "name differs" test above only runs on English
    clients. `Data.lua`'s names are English, so on a French client every item would differ and
    be read live instead of from the checked list. Items with no stats in the list are still
    read live on every client. Once the client has their data, such items are kept in the
    live cache like any other (upstream caches every live read), so an effect-only trinket is
    read once, not on every compare. While the client is still loading an item read live,
    it is "unknown" for a moment (change 10), where 1.2.0 showed the list's copy.
37. **API**: `WLHelperGear.VERSION` is "1.3.0" and `UPSTREAM` "Geared Forever 1.1.1";
    `Weights()` returns `statsOnly` (`{ Thrown = true }` for hunters) and `prefer` holds only
    the damage multipliers.

With no talent data, no hit on the character and no enchant, and with
`SetOptions({ neutral = true })`, the scores are the same as Geared Forever 1.1.1's.
