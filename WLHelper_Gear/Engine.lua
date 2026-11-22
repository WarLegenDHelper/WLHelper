-- Geared Forever: best items per slot for a class, spec, and level range.
-- (Upstream: /geared opens the window. Removed in WL Helper Gear, which has no UI.)
--
-- Copyright (C) 2026 Nathan. Free software under the GNU General Public License
-- version 3, see LICENSE.txt. Quest, drop, and recipe data comes from QuestieDB
-- by the Questie team (https://github.com/Questie/Questie), also GPLv3.
--
-- WL Helper Gear: this file is the scoring part of Geared Forever 1.2's Core.lua,
-- modified by WaR LegenD on 2026-11-15, 2026-11-16 and 2026-11-20 (see NOTICE.md). Still GPLv3.
-- Modifications copyright (C) 2026 WaR LegenD, GPLv3.
--   * The window, tooltips, minimap button, slash commands, starred items, zone
--     reminder and saved settings were removed: this is an engine with no UI.
--   * No globals: everything lives in the addon's private table (ns.engine). The
--     public API is in Api.lua (global WLHelperGear), so it never clashes with
--     Geared Forever when both are loaded.
--   * Changes to the maths are marked "WL Helper change:". With no talent data,
--     no hit on the character and no enchant they give Geared Forever's numbers.

local ADDON, ns = ...

local GetInstant = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
local GetInfo    = (C_Item and C_Item.GetItemInfo) or GetItemInfo
local GetStats   = (C_Item and C_Item.GetItemStats) or GetItemStats

local MAX_LEVEL = 60

-- WL Helper change: secret values (Midnight-era engines) are never read as numbers.
local function Secret(v)
    return issecretvalue ~= nil and issecretvalue(v) == true
end
local function Num(v)
    if v == nil or Secret(v) or type(v) ~= "number" then return nil end
    return v
end

-- Gear view sections.
local SECTIONS = {
    "Head", "Neck", "Shoulder", "Back", "Chest", "Wrist", "Hands", "Waist", "Legs", "Feet",
    "Ring", "Trinket", "Two-Hand", "Main Hand", "Off Hand", "Shield", "Ranged",
}
local SEC_TWOHAND, SEC_MAINHAND, SEC_OFFHAND, SEC_SHIELD, SEC_RANGED = 13, 14, 15, 16, 17

-- Data slot -> which sections the item can show in.
local SLOT_SECTIONS = {
    [1] = {1}, [2] = {2}, [3] = {3}, [4] = {4}, [5] = {5}, [6] = {6}, [7] = {7}, [8] = {8},
    [9] = {9}, [10] = {10}, [11] = {11}, [12] = {12},
    [13] = {13},      -- two-hand
    [14] = {14, 15},  -- one-hand: main or off hand
    [15] = {14},      -- main hand only
    [16] = {15},      -- off hand only
    [17] = {16},      -- shield
    [18] = {17},      -- ranged and wands
    [19] = {17},      -- libram, idol, totem (they use the ranged slot)
    [20] = {15},      -- held in off hand
}

local KIND_NAME = {
    [1] = "Cloth", [2] = "Leather", [3] = "Mail", [4] = "Plate",
    [10] = "Axe", [11] = "Axe", [12] = "Bow", [13] = "Gun", [14] = "Mace", [15] = "Mace",
    [16] = "Polearm", [17] = "Sword", [18] = "Sword", [20] = "Staff", [23] = "Fist",
    [25] = "Dagger", [26] = "Thrown", [28] = "Crossbow", [29] = "Wand",
    [31] = "Libram", [32] = "Idol", [33] = "Totem",
}

------------------------------------------------------------------------
-- Classes and specs
------------------------------------------------------------------------

-- Stat order in the data, st[1] to st[28].
local NUM_STATS = 28
local STAT = {
    armor = 1, str = 2, agi = 3, sta = 4, ap = 5, crit = 6, hit = 7, haste = 8, exp = 9, def = 10,
    dodge = 11, parry = 12, block = 13, bv = 14, int = 15, spi = 16, sp = 17, heal = 18, sdmg = 19,
    mp5 = 20, rap = 21, fire = 22, frost = 23, shadow = 24, arcane = 25, nature = 26, holy = 27, spen = 28,
}

-- A full weight list from just the stats a spec cares about.
local function W(t)
    local w = {}
    for i = 1, NUM_STATS do w[i] = 0 end
    for k, v in pairs(t) do w[STAT[k]] = v end
    return w
end

------------------------------------------------------------------------
-- Stat weights
--
-- Every weight is worked out from WoW Forever's own numbers (launch client
-- 1.60.1.70707, via ForeverDB) instead of picked by hand:
--   ratings: 14 crit, 10 hit, 10 haste, 10 expertise = 1%; 12 dodge, 15 parry, 5 block = 1%
--   hit caps vs raid bosses: 8% melee and ranged, 17% spells (5% and 4% vs your own level)
--   Agility and Intellect per 1% crit for each class, at level 30 and 60
--   Strength and Agility to attack power for each class; 14 attack power = 1 weapon DPS
--   Agility gives armor (2 per point), crit and dodge (20 per 1%; Rogue 14.5, Hunter 26)
-- 1.2 (Nov 18): every number above checked against Wowhead Forever item tooltips, Icy Veins,
-- Warcraft Tavern and Mobalytics. Where the guides disagree, the most common answer wins.
-- Talents that turn one stat into another are counted for the spec that takes them
-- (Mental Dexterity, Careful Aim, Champion of the Light, Spiritual Guidance, Bloom...).
-- Physical specs score in attack power, casters in spell power, healers in healing,
-- tanks in Stamina. Only the order inside one spec matters.
------------------------------------------------------------------------

-- Agility and Intellect needed for 1% crit at level 30 and 60.
local CONV = {
    WARRIOR = { agi = { 10.4, 20.0 }, strAP = 2, pct = 1.4 },
    -- Paladin Intellect: 54 per 1% at 60 (Icy Veins Holy Paladin, Warcraft Tavern: "Paladins requiring the least").
    PALADIN = { agi = { 10.7, 19.8 }, int = { 28.8, 54.0 }, strAP = 2, pct = 1.35 },
    HUNTER  = { agi = { 24.0, 52.9 }, int = { 32.9, 60.6 }, strAP = 1, agiAP = 1, agiRAP = 2, pct = 2.0 },
    ROGUE   = { agi = { 13.0, 29.0 }, strAP = 1, agiAP = 1, pct = 1.05 },
    PRIEST  = { int = { 26.9, 59.5 } },
    SHAMAN  = { agi = { 11.5, 19.7 }, int = { 28.2, 59.2 }, strAP = 2, pct = 1.3 },
    MAGE    = { int = { 27.3, 59.5 } },
    WARLOCK = { int = { 28.2, 60.6 } },
    DRUID   = { agi = { 11.2, 20.0 }, int = { 28.4, 59.9 }, strAP = 2 },
}

-- Points per 1% crit at a level. The WoW Forever client only gives 30 and 60, so
-- below 30 this is an estimate: it falls toward about a third of the level 30 value.
local function PerPct(pair, level)
    local v30, v60 = pair[1], pair[2]
    if level <= 30 then return v30 * (0.35 + 0.65 * (level - 1) / 29) end
    return v30 + (v60 - v30) * (math.min(level, 60) - 30) / 30
end

-- WL Helper change: scoring options (SetOptions in the API).
--   neutral = true turns off every change dated 2026-11-15 (v2) below: proc and use
--     effects, set bonuses, split hit caps, defense cap, proc enchants... Used by the tests
--     to check the rest still gives Geared Forever's numbers.
--   raid = true / false forces raid hit caps (17% spell, 8% melee) at 58+; nil = automatic:
--     at level 60 once WoW Forever's raids are open (December 9, 2026).
--   WL Helper change (1.4.0): wand = how much the wand counts (1 often, 0.5 sometimes, 0.1
--     never: the player's own answer); lighter = true: armor lighter than the best your class
--     wears is not compared from level 40 (Compare and Score say canUse "lighter").
local opts = { neutral = false, raid = nil, wand = 1, lighter = false }
local RAIDS_OPEN = 20261209
local function Today()
    local d = (type(date) == "function" and date) or (os and os.date)
    if not d then return nil end
    local ok, v = pcall(d, "%Y%m%d")
    return ok and tonumber(v) or nil
end
local function RaidCaps(level)
    if level < 58 then return false end
    if opts.raid ~= nil then return opts.raid == true end
    -- WL Helper change (v3): inside a raid instance the raid caps apply whatever the date.
    if IsInInstance then
        local ok, inside, kind = pcall(IsInInstance)
        if ok and inside and kind == "raid" then return true end
    end
    local today = Today()
    return level >= 60 and today ~= nil and today >= RAIDS_OPEN
end

-- Hit cap at a level: dungeon and quest mobs a couple of levels up while leveling,
-- raid bosses (+3) at 58 and up.
-- WL Helper change (v2): spells and melee have different caps below raid level. Against
-- mobs up to 2 levels above you spells miss 6% at most (cap 5%), melee about 7% (cap 6%,
-- as upstream). Raid caps (17% / 8%) apply only when RaidCaps() says so, not to every 58+
-- player still doing dungeons.
local function HitCap(level, spell)
    if opts.neutral then
        if level >= 58 then return spell and 17 or 8 end
        return 6
    end
    if RaidCaps(level) then return spell and 17 or 8 end
    return spell and 5 or 6
end

-- What 1% hit is worth, as a share of 1% damage. Each 1% hit removes a miss, so it's
-- worth a bit more than 1% damage all the way to the cap (1 / hit chance), then
-- nothing. Talent and racial hit count toward the cap; the last few points fade out
-- because gear usually covers some of it.
local function HitValue(level, spell, have)
    local cap = HitCap(level, spell)
    local left = cap - have
    if left <= 0 then return 0.05 end
    -- WL Helper change: never below the over-cap value. Upstream only passed talent hit
    -- (0 to 6), which never lands just under a cap; real hit does, and without the floor
    -- 5.99% hit would be worth less than 6%.
    return math.max(0.05, math.min(1, left / 3) / (1 - cap / 100))
end

-- Straight-line lookup between level points.
local function Curve(points, level)
    if level <= points[1][1] then return points[1][2] end
    for i = 2, #points do
        local a, b = points[i - 1], points[i]
        if level <= b[1] then return a[2] + (b[2] - a[2]) * (level - a[1]) / (b[1] - a[1]) end
    end
    return points[#points][2]
end
-- What 1% more damage is worth in attack power at a level: top weapon DPS for the
-- level (x14) plus the attack power you'd have, plus a bit for abilities. Each class
-- scales it (CONV pct) to match MythicSim's WoW Forever sims at 60: rogues use it as is,
-- warriors, paladins and shamans get more from abilities, hunters much more (ammo,
-- shot bonuses and the pet don't grow with attack power).
local PHYS_PCT = { { 1, 1.5 }, { 10, 2.7 }, { 20, 5 }, { 30, 7.5 }, { 40, 10.3 }, { 50, 15 }, { 60, 21.6 } }
local function PhysPct(level) return Curve(PHYS_PCT, level) end
-- What 1% more spell damage is worth in spell power: each class's main nuke at the
-- level (base damage / WoW Forever's coefficient) plus the spell power you'd have.
-- WoW Forever raised spell coefficients a lot (low ranks get less, but far more than
-- before). At 60 it's set for dungeon and pre-raid gear, checked against MythicSim's
-- WoW Forever sims (client 1.60.1.70707), which put 1% crit at about 9 to 11 spell power.
local SPELL_PCT = { { 1, 0.35 }, { 10, 0.5 }, { 20, 0.9 }, { 30, 1.6 }, { 40, 2.6 }, { 50, 4.5 }, { 55, 6.5 }, { 60, 8.5 } }
local function SpellPct(level) return Curve(SPELL_PCT, level) end
-- Same for healing, with mid ranks of the main heals and the healing you'd have.
local HEAL_PCT = { { 1, 1 }, { 10, 1.45 }, { 20, 2.3 }, { 30, 4.5 }, { 40, 6.5 }, { 50, 9.6 }, { 60, 15.6 } }
local function HealPct(level) return Curve(HEAL_PCT, level) end

local RACE_HIT = { Dwarf = 1 }

------------------------------------------------------------------------
-- WL Helper change: talents and hit read from the game.
--
-- Geared Forever writes each spec's talents into its numbers (Precision +3% hit,
-- Ice Shards +100% crit damage...), as if every player took them. Here, when the
-- weights are for your own class, each of those talents is looked up in your talent
-- trees: taken at full rank it counts as upstream, partly taken it counts its share,
-- not taken it doesn't count. A talent that can't be found by name (another client
-- language, a renamed talent) keeps the upstream value, so the result is never
-- further from Geared Forever than the talents prove.
--
-- Hit: Geared Forever counts only talent and racial hit toward the cap. Here the hit
-- the character already has (gear, enchants, talents: GetHitModifier /
-- GetSpellHitModifier plus hit rating) counts too when it is higher, so hit loses
-- value as you get close to the cap.
------------------------------------------------------------------------

-- Talent names: English and French. names[1] is the English one.
-- field: the spec option it feeds; full: its value at full rank; up: what Geared
-- Forever counts for it (defaults to full). The option becomes
-- value - up + full * rank / maxRank.
local TALENT_MODS = {
    WARRIOR = {
        arms = { { names = { "Impale", "Empaler" }, field = "critBonus", full = 0.1 } },
    },
    PALADIN = {
        holy = { { names = { "Divine Intellect", "Intelligence divine" }, field = "intPct", full = 0.1 } },
        prot = {
            { names = { "Precision", "Précision" }, field = "hit", full = 3 },
            { names = { "Toughness", "Robustesse" }, field = "armor", full = 0.007 },
        },
        ret = {
            { names = { "Divine Strength", "Force divine" }, field = "strPct", full = 0.1 },
            { names = { "Champion of the Light", "Champion de la Lumière" }, field = "intAP", full = 0.6 * 2.2 },
        },
    },
    HUNTER = {
        -- WL Helper change (1.5.0): upstream 1.2 gives Beast Mastery Careful Aim too (intAP 1).
        bm = { { names = { "Careful Aim", "Visée prudente" }, field = "intAP", full = 1 } },
        mm = {
            { names = { "Careful Aim", "Visée prudente" }, field = "intAP", full = 1 },
            { names = { "Mortal Shots", "Tirs mortels" }, field = "critBonus", full = 0.15 },
        },
        surv = {
            { names = { "Surefooted", "Pied sûr" }, field = "hit", full = 3 },
            { names = { "Lightning Reflexes", "Réflexes de l'éclair", "Réflexes éclair" }, field = "agiPct", full = 0.15 },
        },
    },
    ROGUE = {
        combat = { { names = { "Precision", "Précision" }, field = "hit", full = 3 } },
    },
    PRIEST = {
        disc = { { names = { "Mental Strength", "Force mentale" }, field = "intPct", full = 0.1 } },
        holy = { { names = { "Spiritual Guidance", "Direction spirituelle", "Guide spirituel" }, field = "spiHeal", full = 0.25 } },
        shadow = { { names = { "Shadow Focus", "Focalisation de l'ombre" }, field = "hit", full = 5 } },
    },
    SHAMAN = {
        ele = { { names = { "Elemental Fury", "Fureur élémentaire" }, field = "crit", full = 1 } },
        enh = {
            { names = { "Mental Dexterity", "Dextérité mentale" }, field = "intAP", full = 1.0 },
            -- Upstream 1.1.1: spell power is 0.8 up to 50 and fades to 1.4 at 60, so the talent's
            -- 30% of it follows (full is a function of the spec's options).
            { names = { "Mental Quickness", "Rapidité mentale", "Vivacité mentale" }, field = "intAP",
              full = function(o) return 0.3 * (o.sp or 1.4) end },
            { names = { "Ancestral Knowledge", "Savoir ancestral" }, field = "intPct", full = 0.1 },
        },
    },
    MAGE = {
        -- Upstream counts 2% hit for Arcane and Fire ("the couple of points their usual
        -- builds put there"); with the trees readable the real ranks count instead.
        -- Arcane keeps upstream's 2%: an Arcane build gets its hit from Arcane Focus (arcane
        -- spells only), not Elemental Precision, and its Forever ranks aren't confirmed yet.
        arcane = {
            { names = { "Arcane Mind", "Esprit des arcanes" }, field = "crit", full = 1 },
            { names = { "Arcane Mind", "Esprit des arcanes" }, field = "intPct", full = 0.1 },
        },
        fire = {
            { names = { "Elemental Precision", "Precision", "Précision élémentaire", "Précision" }, field = "hit", full = 6, up = 2 },
        },
        frost = {
            { names = { "Ice Shards", "Éclats de glace" }, field = "crit", full = 1 },
            { names = { "Elemental Precision", "Precision", "Précision élémentaire", "Précision" }, field = "hit", full = 6 },
        },
    },
    WARLOCK = {
        affli = {
            { names = { "Suppression" }, field = "hit", full = 5 },
            { names = { "Pandemic", "Pandémie" }, field = "crit", full = 1 },
        },
        destro = { { names = { "Ruin", "Ruine" }, field = "crit", full = 1 } },
    },
    DRUID = {
        balance = {
            { names = { "Vengeance" }, field = "crit", full = 1 },
            { names = { "Nature's Reach", "Allonge de la nature" }, field = "hit", full = 4 },
        },
        feral = {
            { names = { "Heart of the Wild", "Cœur sauvage" }, field = "strPct", full = 0.1 },
            { names = { "Natural Instinct", "Instinct naturel" }, field = "critBonus", full = 0.1 },
        },
        bear = { { names = { "Heart of the Wild", "Cœur sauvage" }, field = "staPct", full = 0.2 } },
        resto = {
            { names = { "Living Spirit", "Esprit vivant" }, field = "spiPct", full = 0.15 },
            { names = { "Bloom", "Floraison" }, field = "spiHeal", full = 0.5 },
        },
    },
}

-- Talent trees, read once and again when talents change (Api.lua clears the cache).
-- Returns { points = { tab1, tab2, ... }, ranks = { [lowercase name] = { rank, maxRank } } }
-- or nil when the client can't tell.
local talentCache

-- Forever (modern engine): no GetNumTalentTabs, talents live in C_ClassTalents + C_Traits.
-- Several trees: one tab per tree. A single tree: its nodes split into three bands by posX,
-- left to right like the old tabs (same rule as WLHelper/Writs/Weights.lua). Names come from
-- the node's entry -> definition -> spell.
local function TraitName(cfg, ni)
    local entry = (type(ni.activeEntry) == "table" and Num(ni.activeEntry.entryID))
        or (type(ni.entryIDs) == "table" and Num(ni.entryIDs[1]))
    if not entry or not (C_Traits.GetEntryInfo and C_Traits.GetDefinitionInfo) then return nil end
    local okE, ei = pcall(C_Traits.GetEntryInfo, cfg, entry)
    local def = okE and type(ei) == "table" and Num(ei.definitionID)
    if not def then return nil end
    local okD, di = pcall(C_Traits.GetDefinitionInfo, def)
    local spell = okD and type(di) == "table" and (Num(di.spellID) or Num(di.overriddenSpellID))
    if not spell then return nil end
    local okS, name
    if C_Spell and C_Spell.GetSpellName then okS, name = pcall(C_Spell.GetSpellName, spell)
    elseif GetSpellInfo then okS, name = pcall(GetSpellInfo, spell) end
    if okS and type(name) == "string" and not Secret(name) and name ~= "" then return name end
    return nil
end

local function ScanTraits()
    if not (C_ClassTalents and C_ClassTalents.GetActiveConfigID and C_Traits and C_Traits.GetConfigInfo
        and C_Traits.GetTreeNodes and C_Traits.GetNodeInfo) then return nil end
    local ok, cfg = pcall(C_ClassTalents.GetActiveConfigID)
    cfg = ok and Num(cfg)
    if not cfg then return nil end
    local okI, info = pcall(C_Traits.GetConfigInfo, cfg)
    local trees = okI and type(info) == "table" and info.treeIDs
    if type(trees) ~= "table" or #trees == 0 then return nil end
    local scan = { points = {}, ranks = {} }
    local nodes = {}
    for t, tid in ipairs(trees) do
        local okN, list = pcall(C_Traits.GetTreeNodes, tid)
        if okN and type(list) == "table" then
            for _, nid in ipairs(list) do
                local okD, ni = pcall(C_Traits.GetNodeInfo, cfg, nid)
                if okD and type(ni) == "table" then
                    local r = Num(ni.ranksPurchased) or Num(ni.currentRank) or 0
                    local max = Num(ni.maxRanks)
                    nodes[#nodes + 1] = { tree = t, r = r, x = Num(ni.posX) }
                    local name = max and max > 0 and TraitName(cfg, ni)
                    if name then
                        local key = name:lower()
                        local seen = scan.ranks[key]
                        -- Same name twice in one class: keep the one with points in it.
                        if not seen or r > seen[1] then scan.ranks[key] = { r, max } end
                    end
                end
            end
        end
    end
    if #nodes == 0 then return nil end
    if #trees >= 2 then
        for t = 1, #trees do scan.points[t] = 0 end
        for _, n in ipairs(nodes) do scan.points[n.tree] = scan.points[n.tree] + n.r end
    else
        local lo, hi
        for _, n in ipairs(nodes) do if n.x then lo = math.min(lo or n.x, n.x); hi = math.max(hi or n.x, n.x) end end
        scan.points = { 0, 0, 0 }
        for _, n in ipairs(nodes) do
            if n.r > 0 then
                local band = 1
                if n.x and lo and hi > lo then band = math.min(3, math.floor((n.x - lo) / (hi - lo + 1) * 3) + 1) end
                scan.points[band] = scan.points[band] + n.r
            end
        end
    end
    return scan
end

local function ScanTalents()
    if talentCache ~= nil then return talentCache or nil end
    talentCache = false
    local traits = ScanTraits()
    if traits then talentCache = traits; return traits end
    if not (GetNumTalentTabs and GetNumTalents and GetTalentInfo) then return nil end
    local ok, numTabs = pcall(GetNumTalentTabs)
    numTabs = ok and Num(numTabs)
    if not numTabs or numTabs < 1 then return nil end
    local scan = { points = {}, ranks = {} }
    local any = false
    for tab = 1, numTabs do
        scan.points[tab] = 0
        local okN, n = pcall(GetNumTalents, tab)
        n = okN and Num(n) or 0
        for i = 1, n do
            local okT, name, _, _, _, rank, maxRank = pcall(GetTalentInfo, tab, i)
            rank, maxRank = Num(rank), Num(maxRank)
            if okT and type(name) == "string" and not Secret(name) and rank and maxRank and maxRank > 0 then
                any = true
                scan.points[tab] = scan.points[tab] + rank
                local key = name:lower()
                local seen = scan.ranks[key]
                -- Same name twice in one class: keep the one with points in it.
                if not seen or rank > seen[1] then scan.ranks[key] = { rank, maxRank } end
            end
        end
    end
    if not any then return nil end
    talentCache = scan
    return scan
end

local function ClearTalentCache() talentCache = nil end

-- Rank share (0 to 1) of the first name found, or nil when none is in the trees.
local function TalentShare(scan, names)
    for _, name in ipairs(names) do
        local r = scan.ranks[name:lower()]
        if r then return r[1] / r[2] end
    end
    return nil
end

-- Hit the character already has, in percent: melee, ranged or spell.
local CR_MELEE = CR_HIT_MELEE or 6
local CR_RANGED = CR_HIT_RANGED or 7
local CR_SPELL = CR_HIT_SPELL or 8
local hitOverride   -- tests and the API can set { melee =, ranged =, spell = }
local function OwnedHit(kind)
    if hitOverride then return hitOverride[kind] or 0 end
    local total = 0
    local mod = (kind == "spell") and GetSpellHitModifier or GetHitModifier
    if mod then
        local ok, v = pcall(mod)
        v = ok and Num(v)
        if v then total = total + v end
    end
    if GetCombatRatingBonus then
        local cr = (kind == "spell" and CR_SPELL) or (kind == "ranged" and CR_RANGED) or CR_MELEE
        local ok, v = pcall(GetCombatRatingBonus, cr)
        v = ok and Num(v)
        if v then total = total + v end
    end
    if total < 0 then total = 0 elseif total > 40 then total = 40 end
    return total
end

-- Set while weights are worked out for the player's own class and spec:
-- { mods = TALENT_MODS row or nil, talents = scan or nil, own = true }
local ctx

-- WL Helper change: the spec's options, with the talents you really have.
local function Adjust(o)
    if not (ctx and ctx.mods and ctx.talents) then return o end
    local copy
    for _, m in ipairs(ctx.mods) do
        local share = TalentShare(ctx.talents, m.names)
        if share then
            if not copy then
                copy = {}
                for k, v in pairs(o) do copy[k] = v end
            end
            -- WL Helper change (1.3.0): full can depend on the spec's options (Mental Quickness).
            local full = type(m.full) == "function" and m.full(o) or m.full
            local v = (copy[m.field] or 0) - (m.up or full) + full * share
            if math.abs(v) < 1e-9 then v = 0 end
            -- Physical() only adds Intellect attack power when intAP is set.
            if m.field == "intAP" and v <= 0 then v = nil end
            copy[m.field] = v
        end
    end
    return copy or o
end

-- WL Helper change: hit toward the cap is the talent and racial hit Geared Forever
-- counts, or what the character really has when that is higher.
local function HitHave(o, race, kind)
    local have = (o.hit or 0) + (RACE_HIT[race] or 0)
    if ctx and ctx.own then
        local real = OwnedHit(kind) + (RACE_HIT[race] or 0)
        if real > have then have = real end
    end
    return have
end

-- Leveling (below 60) you fight alone and stop to eat, so Stamina counts for more
-- than raid sims say. At 60 the raid numbers take over.
-- 1.1.1: no hard switch at 60. Leveling weights count in full up to 50, then fade evenly
-- into the level 60 weights (55 = half). So a 60 BiS item you can wear at 56 still ranks
-- near the top instead of losing to a Stamina item.
local function LevelFade(level)
    level = level or 60
    if level <= 50 then return 1 end
    if level >= 60 then return 0 end
    return (60 - level) / 10
end
ns.LevelFade = LevelFade

local function Blend(level, endgame, leveling)
    local t = LevelFade(level)
    return endgame + (leveling - endgame) * t
end

local function LevelingSta(level, base, solo)
    return Blend(level, base, math.max(base, solo))
end

-- Leveling overrides (below 60): o.lvl = { stat = value } replaces the raid number.
-- From the WoW Forever leveling guides (Warcraft Tavern, Nov 2026): Stamina right after the
-- main stat, Spirit for mana classes, wands for casters.
local function ApplyLeveling(level, w, lvl)
    if not lvl or LevelFade(level) == 0 then return end
    for k, v in pairs(lvl) do w[k] = Blend(level, w[k] or 0, v) end
end

local HUNTER_RANGED = { statsOnly = { [26] = true } }   -- 26 = thrown

-- Physical damage dealers. o: the spec's details.
--   critBonus: extra crit damage from talents (Impale +20% -> 1.1)
--   hit: talent hit; strPct, agiPct: talents that raise the stat
--   intAP: attack power per Intellect (Mental Dexterity, Careful Aim)
--   mh, oh, rg: weapon DPS weights as multiples of 14 attack power
--   ranged: score ranged attack power and Agility for ranged attacks
--   hitMult: hit's value next to crit. MythicSim's sims carry some hit already, so they rate it
--     low; every Forever guide (Icy Veins, wow.gg, Warcraft Tavern) puts hit to the cap first.
--     Nov 11: raised to 0.8-0.9 so hit sits with or above crit per point, as the guides say.
--   haste, exp: what 1% haste or expertise is worth as a share of 1% damage
local function Physical(level, race, cls, o)
    o = Adjust(o)   -- WL Helper change: talents you really have
    local c = CONV[cls]
    local pct = PhysPct(level) * (c.pct or 1)
    local critVal = pct * (o.critBonus or 1)
    local w = {}
    local strAP = (c.strAP or 0) * (1 + (o.strPct or 0))
    local agiAP = o.ranged and (c.agiRAP or 0) or (o.agiAP or c.agiAP or 0)
    w.str = o.ranged and 0.1 or strAP
    w.agi = (agiAP + critVal / PerPct(c.agi, level)) * (1 + (o.agiPct or 0)) + 2 * 0.01
    -- Plain "+Attack Power" on gear counts for melee and ranged alike, so hunters get it in full.
    -- Only "+ranged Attack Power" (rap) is ranged only.
    w.ap = 1
    w.rap = o.ranged and 1 or 0
    w.crit = critVal / 14
    local hitHave = HitHave(o, race, o.ranged and "ranged" or "melee")   -- WL Helper change: real hit
    w.hit = pct * (o.hitMult or 1) * HitValue(level, false, hitHave) / 10
    w.haste = pct * (o.haste or 0.55) / 10
    -- Behind the target nothing can parry, so 1% expertise only removes 1% dodges: worth what
    -- 1% hit is worth before talents (Icy Veins: "getting past 6.5%" from behind). exp = "hit" does that.
    if o.exp == "hit" then
        -- expRel: the guides break the tie. Warriors, Ret, Enhancement and Feral: Hit > Expertise.
        -- Rogues: Expertise > Hit (Icy Veins).
        w.exp = pct * (o.hitMult or 1) / (1 - HitCap(level, false) / 100) / 10 * (o.expRel or 1)
    else
        w.exp = pct * (o.exp or 0.8) / 10
    end
    -- Armor matters when you're the one getting hit, which is every pull while leveling.
    w.armor = Blend(level, 0.01, 0.03)
    w.sta = LevelingSta(level, o.sta or 0.3, 0.8)
    if o.intAP then w.int = o.intAP * (1 + (o.intPct or 0)) + 0.1 end
    w.int = (w.int or 0) + (o.int or 0)
    w.spi = o.spi
    w.sp, w.sdmg = o.sp, o.sp
    if o.school then w[o.school] = o.sp end
    ApplyLeveling(level, w, o.lvl)
    -- WL Helper change (v2): role and the worth of 1% melee damage, for proc effects.
    local wt = W(w)
    wt.role, wt.mdmg = "phys", o.ranged and 0 or pct
    return o.mh * 14, (o.oh or 0) * 14, (o.rg or 0.05) * 14, o.slow, wt, o.prefer
end

-- Damage casters: spell power counts in full, plus their school's spell damage.
--   crit: crit damage bonus multiplier from talents (Ice Shards, Ruin... -> 2 means +100%)
--   intSP: spell power per Intellect from talents; mana: how much the spec needs mana
local function Caster(level, race, cls, o)
    o = Adjust(o)   -- WL Helper change: talents you really have
    local c = CONV[cls]
    local pct = SpellPct(level)
    local critVal = pct * 0.5 * (o.crit or 1)      -- spell crits do +50% before talents
    local w = { sp = 1, sdmg = 1 }
    for _, s in ipairs(o.schools) do w[s[1]] = s[2] end
    -- 15 mana per Intellect. Over a fight that's about half as much damage as 1 spell power gives,
    -- a bit less while leveling (shorter fights, more drinking).
    local manaVal = (0.25 + 0.002 * level) * (o.mana or 1)
    if race == "Gnome" then manaVal = manaVal * 1.05 end
    w.int = (critVal / PerPct(c.int, level) + manaVal + (o.intSP or 0)) * (1 + (o.intPct or 0))
    w.crit = critVal / 14
    local hitHave = HitHave(o, race, "spell")   -- WL Helper change: real hit
    w.hit = pct * HitValue(level, true, hitHave) / 10 * (o.hitW or 1)
    w.haste = pct * (o.haste or 0.8) / 10
    w.spi = (o.spi or 0.1) * (race == "Human" and 1.1 or 1)
    -- WL Helper change (beta.156): 1 mana per 5 s is ~24 mana over a 2-minute fight, more than the
    -- 15 of 1 Intellect: worth 1.6 times Intellect's mana (it was a flat 0.25, under Intellect)
    w.mp5 = o.mp5 or 0.25
    if not o.mp5 and not opts.neutral then w.mp5 = math.max(0.25, manaVal * 1.6) end
    w.sta = LevelingSta(level, o.sta or 0.15, 0.4)
    -- Spell penetration matters against raid bosses; leveling mobs barely resist.
    w.spen = o.spen or (level >= 58 and 0.3 or 0.05)
    -- Leveling: Intellect and Spirit keep you casting instead of drinking, and the wand
    -- does a big share of the damage (priests, warlocks, early mages). Fades out 50 to 60.
    w.int = Blend(level, w.int, math.max(w.int, o.lvlInt or 0.55))
    w.spi = Blend(level, w.spi or 0, math.max(w.spi or 0, o.lvlSpi or 0.35))
    ApplyLeveling(level, w, o.lvl)
    local wand = o.wand or 1.2
    if o.wand ~= 0 then wand = Blend(level, wand, math.max(wand, 2)) end
    -- 1.2: level 60 values set to the guides' order, faded in from 50 like healers.
    if o.at60 then
        for k, v in pairs(o.at60) do w[k] = Blend(level, v, w[k] or 0) end
    end
    local wt = W(w)
    wt.role, wt.mdmg = "caster", 0   -- WL Helper change (v2): for proc effects
    return 0, 0, wand, false, wt
end

-- Healers: healing power and spell power count in full.
--   intHeal: healing per Intellect from talents; spiHeal: healing per Spirit
--   regen: how much of Spirit's regen keeps going while casting
local function Healer(level, race, cls, o)
    o = Adjust(o)   -- WL Helper change: talents you really have
    local c = CONV[cls]
    local pct = HealPct(level)
    local critVal = pct * 0.5 * (o.crit or 1)
    local w = { heal = 1, sp = 1, sdmg = o.sdmg or 0 }
    -- 15 mana per Intellect: about 30 healing over a fight at 60, against 35 to 50 from 1 healing power.
    local manaVal = 0.45 + 0.0067 * level
    if race == "Gnome" then manaVal = manaVal * 1.05 end
    w.int = (critVal / PerPct(c.int, level) + manaVal + (o.intHeal or 0)) * (1 + (o.intPct or 0))
    w.crit = critVal / 14
    w.haste = pct * 0.6 / 10
    local spi = (o.regen or 0.3) * 0.9 + (o.spiHeal or 0)
    w.spi = spi * (1 + (o.spiPct or 0)) * (race == "Human" and 1.1 or 1)
    w.mp5 = o.mp5 or 0.9
    w.sta = LevelingSta(level, 0.1, 0.3)
    w.armor = o.armor
    -- 1.2: level 60 order set to the guides' stat priority (o.at60). Below 50 the math above
    -- counts in full; 50 to 60 it fades into the guide order, like the leveling fade.
    if o.at60 then
        for k, v in pairs(o.at60) do w[k] = Blend(level, v, w[k] or 0) end
    end
    local wt = W(w)
    wt.role, wt.mdmg = "healer", 0   -- WL Helper change (v2): for proc effects
    return 0, 0, 1, false, wt
end

-- WL Helper change (v2): defense the character has, in skill points, and how many skill
-- points one point of the item "defense" stat gives (nil when the client can't tell).
local CR_DEFENSE = CR_DEFENSE_SKILL or 2
local defOverride   -- tests and the API can set { skill =, ratio = }
local function OwnedDefense()
    if defOverride then return defOverride.skill, defOverride.ratio end
    local skill, ratio, bonus
    if GetCombatRating and GetCombatRatingBonus then
        local ok1, rating = pcall(GetCombatRating, CR_DEFENSE)
        local ok2, b = pcall(GetCombatRatingBonus, CR_DEFENSE)
        rating, bonus = ok1 and Num(rating), ok2 and Num(b)
        if rating and rating > 0 and bonus and bonus > 0 then ratio = bonus / rating end
    end
    if UnitDefense then
        local ok, base, mod = pcall(UnitDefense, "player")
        base, mod = ok and Num(base), ok and Num(mod)
        -- The modifier holds talents and +Defense; on rating clients the rating bonus may be
        -- apart from it, so take the larger of the two rather than adding them.
        if base then skill = base + math.max(mod or 0, bonus or 0) end
    end
    return skill, ratio
end

-- Tanks score in Stamina: what each stat is worth in effective health.
--   avoid: Stamina per 1% less damage taken, grows with your health pool
local function Tank(level, race, cls, o)
    o = Adjust(o)   -- WL Helper change: talents you really have
    local c = CONV[cls]
    local avoid = math.max(0.6, 0.1 * level - 0.4)
    local w = {}
    w.sta = (1 + (o.staPct or 0)) * (race == "Tauren" and 1.05 or 1)
    w.armor = o.armor or 0.07
    -- Agility: 2 armor, dodge (about as much Agility per 1% as crit), plus a little threat from crit.
    w.agi = 2 * (o.armor or 0.07) + 0.15 + (c.agi and avoid / PerPct(c.agi, level) or 0)
    w.def = (avoid * 0.16 + 0.35) * (o.defMult or 1)   -- 0.04% each to miss, dodge, parry, block + crit protection
    w.dodge = avoid / 12
    w.parry = avoid * 0.9 / 15
    w.block = avoid * (o.blockVal or 0.5) / 5
    w.bv = o.bv or 0.3
    w.str = o.str or 0.4
    w.ap = (o.str or 0.4) / 2
    -- Threat stats, in Stamina. o.threat: how much the spec's guides push threat (Icy Veins and
    -- Mobalytics both put Expertise and Hit above Agility for Prot Warriors).
    local pct = PhysPct(level) * 0.04 * (o.threat or 1)
    w.hit = pct * 1.5 * HitValue(level, false, HitHave(o, race, "melee")) / 10   -- WL Helper change: real hit
    w.exp = pct * (o.expW or 1.5) / 10
    w.crit = pct * 0.6 / 14
    w.haste = pct * 0.5 / 10
    w.sp, w.sdmg, w.holy = o.sp, o.sp, o.sp
    w.int = o.int
    ApplyLeveling(level, w, o.lvl)
    if not opts.neutral then
        -- WL Helper change (v2): bears can't parry or block, so defense only adds miss and dodge.
        if o.bear then
            w.parry = 0
            w.def = avoid * 0.08 + 0.35
        end
        -- WL Helper change (v2): the crit-immunity cap. A raid boss (level + 3) crits a tank for
        -- 5% + 0.04% per point of its weapon skill above the tank's defense, so 440 defense at 60
        -- (5 x (level + 3) + 125) removes crits. Below it each point is worth twice its avoidance
        -- value (a cap-priority heuristic, not a mean-damage derivation: being crit-immune
        -- comes first); above it only
        -- the avoidance part counts. The last 10 points fade. Needs the character's own defense
        -- (UnitDefense), so only for your own class at 58+.
        local have, ratio = nil, nil
        if ctx and ctx.own and level >= 58 then have, ratio = OwnedDefense() end
        if have then
            local share = o.bear and 0.08 or 0.16
            local cap = 5 * (level + 3) + 125
            local left = cap - have
            local crit = left > 0 and avoid * 0.16 * math.min(1, left / 10) or 0
            -- WL Helper change (1.5.0): upstream 1.2's defense multiplier (defMult, Protection
            -- warrior and paladin) scales the avoidance part, as upstream; the crit-immunity
            -- part below the cap is ours and stays whole.
            w.def = avoid * share * (o.defMult or 1) + crit
            -- WL Helper change (v3): the weight is per defense skill point. Data.lua's def values
            -- are skill points ("+N Defense"), so no ratio here; LiveItem turns a client's
            -- defense rating into skill points instead.
        end
    end
    local wt = W(w)
    -- WL Helper change (v2): for proc effects (threat). WL Helper change (v3): half, like haste.
    wt.role, wt.mdmg = "tank", pct * 0.5
    return o.mh or 3, 0, 0.1, false, wt
end

-- Each spec returns: main-hand DPS weight, off-hand DPS weight, ranged DPS weight,
-- whether slow weapons get a bonus, stat weights, and favorite weapon types
-- (KIND_NAME keys, as a damage multiplier).
local SPECS = {
    WARRIOR = {
        -- Weaponmaster: axes and polearms +5% crit, maces and staves ignore 15% armor, swords 5% chance of an
        -- extra attack (Wowhead Forever talent calc, Nov 17). Impale +20% crit damage.
        { key = "arms", label = "Arms", weights = function(level, race)
            return Physical(level, race, "WARRIOR", { critBonus = 1.1, mh = 1, rg = 0.03, slow = true, haste = 0.65, exp = "hit", hitMult = 0.85, expRel = 0.97,
                lvl = { sta = 1.3 },   -- leveling: Strength > Stamina > Agility
                prefer = { [11] = 1.06, [16] = 1.06, [15] = 1.04, [20] = 1.04, [10] = 1.06, [14] = 1.04, [17] = 1.05, [18] = 1.05 } })
        end },
        -- Dual Wield Specialization +25% off-hand damage, Furious Precision +10% off-hand hit.
        -- Nov 3: Flurry is 30% attack speed after a crit and no longer needs Death Wish, so crit is worth more.
        { key = "fury", label = "Fury", weights = function(level, race)
            return Physical(level, race, "WARRIOR", { mh = 1, oh = 0.62, rg = 0.03, slow = true, haste = 0.6, exp = "hit", hitMult = 0.8, expRel = 0.97,
                critBonus = 1.15, lvl = { sta = 1.3 } })
        end },
        -- Shield Slam scales with block value; Revenge with attack power. Anticipation +20 Defense.
        { key = "prot", label = "Protection", weights = function(level, race)
            -- 1.2: Stamina first (Icy Veins and Mobalytics). Defense under it (Mobalytics 2nd, Icy Veins
            -- last). Expertise > Hit > Agility > Strength for threat (both guides).
            return Tank(level, race, "WARRIOR", { str = 0.45, bv = 0.45, blockVal = 0.6, armor = 0.07, mh = 2.5,
                threat = 5, expW = 1.75, defMult = 0.68 })
        end },
    },
    PALADIN = {
        -- Spirit regen keeps going while casting (Reverence 30%, Wowhead Forever talent calc).
        -- Divine Intellect +10% (Prot tree; Icy Veins' Holy build takes it).
        -- Nov 3: Holy Power raises critical healing by up to 50%, so crits heal for double.
        { key = "holy", label = "Holy", weights = function(level, race)
            -- 1.2: at 60, Icy Veins' order: Healing > Intellect > Spirit > Mp5 > Crit.
            return Healer(level, race, "PALADIN", { crit = 2, regen = 0.3, intPct = 0.1, mp5 = 1, armor = 0.003,
                at60 = { int = 0.95, spi = 0.55, mp5 = 0.5, crit = 0.45, haste = 0.4 } })
        end },
        -- Threat is mostly Holy damage (Righteous Fury, Holy Shield, Consecration, Holy Strike).
        -- Precision +3% hit, Toughness +10% item armor.
        { key = "prot", label = "Protection", weights = function(level, race)
            -- Leveling (Warcraft Tavern, Mobalytics): Spell Power > Stamina > Intellect > Strength.
            -- 1.2, level 60: Stamina > Defense > Spell Power > Intellect > Strength (Icy Veins), Spell Power
            -- the main threat stat (Warcraft Tavern), "always take Hit and Block" (Mobalytics).
            return Tank(level, race, "PALADIN", { str = 0.35, bv = 0.4, blockVal = 0.7, armor = 0.077, hit = 3, sp = 0.9, int = 0.55, mh = 2,
                threat = 4, defMult = 0.76,
                lvl = { sp = 1.2, sdmg = 1.2, holy = 1.2, sta = 1.0, int = 0.6, str = 0.4 } })
        end },
        -- Champion of the Light: 60% of Intellect as spell damage. Divine Strength +10% Strength.
        -- Two-Handed Weapon Specialization +6% physical damage. Seal of Command: Holy damage from the weapon.
        { key = "ret", label = "Retribution", weights = function(level, race)
            -- Nov 3: Vengeance stacks 5 times (15% Physical and Holy after a crit); Two-Handed Weapon
            -- Specialization also adds 6% Holy damage.
            -- Spell power: Seal of Righteousness (up to 12% per swing), Judgement and Holy Strike (42.9% each,
            -- 10 sec cooldowns). MythicSim's Forever sim puts 1 spell power at about 2.2 attack power and
            -- haste above crit. Its high expertise came from parries; from behind it's dodge only (Nov 11).
            return Physical(level, race, "PALADIN", { mh = 1.05, slow = true, strPct = 0.1, sp = 2.1, school = "holy", critBonus = 1.1,
                intAP = 0.6 * 2.2, intPct = 0, int = 0.08, sta = 0.3, haste = 0.85, exp = "hit", hitMult = 0.85, expRel = 0.97,
                -- Leveling: Strength and Spell Power about even (Icy Veins: Spell Power "one of your most
                -- effective stats"; Wowhead: "aim for both"), Stamina right after (Warcraft Tavern).
                lvl = { sta = 1.3, sp = 1.8, sdmg = 1.8, holy = 1.8, int = 0.6 },
                prefer = { [11] = 1.06, [15] = 1.06, [16] = 1.06, [18] = 1.06 } })
        end },
    },
    HUNTER = {
        { key = "bm", label = "Beast Mastery", weights = function(level, race)
            -- Intellect: Careful Aim (Mobalytics' BM build takes it) gives 1 attack power per point, plus mana.
            -- 1.2: was 1.8, above attack power; Icy Veins and Mobalytics both rank it under Agility.
            return Physical(level, race, "HUNTER", { ranged = true, prefer = HUNTER_RANGED, mh = 0.15, oh = 0.07, rg = 1, intAP = 1, int = 0.2, exp = 0.55, haste = 0.45,
                lvl = { int = 1.0, spi = 0.8, sta = 0.6 } })   -- leveling: Agility > AP > Crit > Int > Spirit > Stamina
        end },
        -- Careful Aim: attack power equal to 100% of Intellect. Mortal Shots +30% ranged crit damage.
        { key = "mm", label = "Marksmanship", weights = function(level, race)
            return Physical(level, race, "HUNTER", { ranged = true, prefer = HUNTER_RANGED, mh = 0.15, oh = 0.07, rg = 1.05, critBonus = 1.15,
                intAP = 1, int = 0.4, haste = 0.66, exp = 0.45, lvl = { spi = 0.8, sta = 0.6 } })
        end },
        -- Melee and ranged. Surefooted +3% hit, Lightning Reflexes +15% Agility, Predator's Edge +50% off-hand damage.
        { key = "surv", label = "Survival", weights = function(level, race)
            local mh, oh, rg, slow, w = Physical(level, race, "HUNTER", { mh = 0.7, oh = 0.5, rg = 0.5, hit = 3,
                agiPct = 0.15, critBonus = 1.15, int = 1.2, haste = 0.7, exp = 0.75,
                lvl = { int = 0.8, spi = 0.6, sta = 0.6 } })   -- Nov 3: Lightning Reflexes +15% Agility
            w[STAT.rap] = 0.5
            w[STAT.ap] = w[STAT.ap] + 0.5    -- plain attack power also feeds the bow
            w[STAT.agi] = w[STAT.agi] + 1     -- Agility feeds both melee and ranged attack power
            return mh, oh, rg, slow, w, HUNTER_RANGED
        end },
    },
    ROGUE = {
        -- Mutilate needs a dagger in each hand.
        { key = "assa", label = "Assassination", weights = function(level, race)
            -- Nov 3: Mutilate 90% weapon damage per hand, Shank uses the off hand, Seal Fate 100%, Lethality 20%.
            return Physical(level, race, "ROGUE", { mh = 1, oh = 0.8, critBonus = 1.15, haste = 0.75, exp = "hit", hitMult = 0.9, expRel = 1.03,
                prefer = { [25] = 1.25 } })
        end },
        -- Hack and Slash: axes and swords 5% extra attacks, daggers and fist weapons +5% crit, maces ignore 15%
        -- armor (Wowhead Forever talent calc, Nov 17). Precision +3% hit.
        { key = "combat", label = "Combat", weights = function(level, race)
            return Physical(level, race, "ROGUE", { mh = 1, oh = 0.67, hit = 3, haste = 0.75, exp = "hit", hitMult = 0.9, expRel = 1.03,   -- Shank
                prefer = { [10] = 1.05, [17] = 1.05, [14] = 1.04, [23] = 1.05, [25] = 1.05 } })
        end },
        -- Ghostly Strike and Hemorrhage hit much harder with a dagger.
        { key = "sub", label = "Subtlety", weights = function(level, race)
            -- Nov 3: the dagger bonus on Ghostly Strike and Hemorrhage was cut; Shank uses the off hand.
            return Physical(level, race, "ROGUE", { mh = 1, oh = 0.6, critBonus = 1.1, haste = 0.75, exp = "hit", hitMult = 0.9, expRel = 1.03,
                prefer = { [25] = 1.08 } })
        end },
    },
    PRIEST = {
        -- Mental Strength +10% Intellect; Meditation 50% regen while casting; Smite and Penance use spell damage.
        { key = "disc", label = "Discipline", weights = function(level, race)
            -- 1.2, level 60: Healing > Mp5 > Spirit > Intellect > Crit (Icy Veins).
            return Healer(level, race, "PRIEST", { crit = 1.2, regen = 0.5, intPct = 0.1, sdmg = 0.15,
                at60 = { mp5 = 0.9, spi = 0.8, int = 0.75, crit = 0.5, haste = 0.4 } })
        end },
        -- Spiritual Guidance: healing equal to 25% of Spirit.
        { key = "holy", label = "Holy", weights = function(level, race)
            -- 1.2, level 60: Healing first and Crit last on Icy Veins and Warcraft Tavern; they split on
            -- Intellect vs Mp5, so those two sit close.
            return Healer(level, race, "PRIEST", { regen = 0.5, spiHeal = 0.25,
                at60 = { mp5 = 0.9, int = 0.88, spi = 0.8, crit = 0.5, haste = 0.4 } })
        end },
        -- Shadow Focus +5% hit; Dark Inspiration +15% Spirit; Spiritual Guidance 8% of Spirit as spell damage.
        { key = "shadow", label = "Shadow", weights = function(level, race)
            -- Shadow damage over time can crit in WoW Forever; sims rank crit right behind spell power, haste ~0.
            return Caster(level, race, "PRIEST", { schools = { { "shadow", 1 } }, crit = 2, hit = 5, spi = 0.25, mp5 = 0.3, mana = 0.6,
                haste = 0.1 })
        end },
    },
    SHAMAN = {
        -- Elemental Fury +100% crit damage.
        { key = "ele", label = "Elemental", weights = function(level, race)
            -- Nov 3: Lava Burst removed, Lightning Overload 30%: Nature matters more, Fire less.
            return Caster(level, race, "SHAMAN", { schools = { { "nature", 0.9 }, { "fire", 0.25 }, { "frost", 0.1 } },
                crit = 2, mp5 = 0.4, spi = 0.05, wand = 0, haste = 0.7, hitW = 0.95 })   -- 1.2: Spell Power > Hit (Icy Veins)
        end },
        -- Mental Dexterity: attack power equal to 100% of Intellect. Mental Quickness: 30% of Intellect as
        -- spell damage. Ancestral Knowledge +10% Intellect. No dual wield in WoW Forever.
        { key = "enh", label = "Enhancement", weights = function(level, race)
            -- Nov 10 hotfix: Mental Dexterity 100% of Intellect (was 150%); Stormstrike 100% weapon damage
            -- every 8 sec (was 150% every 6); Maelstrom Weapon procs 6 to 10 times a minute (was 20).
            -- Blizzard's goal: Strength is Enhancement's best stat again, Intellect and spell power after it.
            -- Spell power drops to about 1.4 attack power with far fewer instant Lightning Bolts.
            -- Leveling solo you rarely have the mana for Lightning Bolts, so spell power counts
            -- for less until 60 (Nov 15, from player feedback: cloth caster gear ranked too high).
            local sp = Blend(level, 1.4, 0.8)
            return Physical(level, race, "SHAMAN", { mh = 1.1, slow = true, intAP = 1.0 + 0.3 * sp, intPct = 0.1,
                sp = sp, school = "nature", haste = 0.9, exp = "hit", hitMult = 0.85, expRel = 0.97, sta = 0.3 })
        end },
        -- Mindfulness 50% regen while casting; Tidal Focus.
        { key = "resto", label = "Restoration", weights = function(level, race)
            -- 1.2, level 60: Healing > Crit > Intellect > Spirit > Mp5 (Icy Veins). Warcraft Tavern: Spirit
            -- "highly sought after", crit good (HoTs crit, Water Shield), and Water Shield gives no mp5.
            return Healer(level, race, "SHAMAN", { crit = 1.1, regen = 0.5, mp5 = 1,
                at60 = { crit = 0.8, int = 0.75, spi = 0.65, mp5 = 0.5, haste = 0.4 } })
        end },
    },
    MAGE = {
        -- Arcane Blast: 12% of Intellect as spell damage per stack (up to 4). Arcane Mind +10% Intellect and
        -- +100% Arcane crit damage. Precision (6% hit) is a Frost talent, so Arcane and Fire count only
        -- the couple of points their usual builds put there.
        { key = "arcane", label = "Arcane", weights = function(level, race)
            return Caster(level, race, "MAGE", { schools = { { "arcane", 1 }, { "fire", 0.15 }, { "frost", 0.15 } },
                crit = 2, intSP = level >= 20 and 0.48 or 0, intPct = 0.1, mana = 0.8, hit = 2, haste = 0.75, lvlSpi = 0.5, lvlInt = 0.9,
                at60 = { int = 0.55 } })   -- 1.2: Hit > Spell Power > Crit > Intellect (Icy Veins, Mobalytics)
        end },
        { key = "fire", label = "Fire", weights = function(level, race)
            return Caster(level, race, "MAGE", { schools = { { "fire", 1 } }, crit = 2, hit = 2, haste = 0.8,
                at60 = { spi = 0.3 } })   -- 1.2: Spirit above Mp5 (Icy Veins: Mage Armor and Arcane Meditation keep it going)
        end },
        -- Ice Shards +100% Frost crit damage. Precision +6% hit.
        { key = "frost", label = "Frost", weights = function(level, race)
            -- Forever sims rank haste second for Frost (more Frostbolts and Ice Lances).
            return Caster(level, race, "MAGE", { schools = { { "frost", 1 } }, crit = 2, hit = 6, haste = 1.25, mana = 0.7 })
        end },
    },
    WARLOCK = {
        -- Damage over time can crit in WoW Forever; Pandemic +100% crit damage on them. Suppression +5% hit.
        -- Life Tap scales with Spirit.
        { key = "affli", label = "Affliction", weights = function(level, race)
            return Caster(level, race, "WARLOCK", { schools = { { "shadow", 1 } }, crit = 2, hit = 5, spi = 0.3, sta = 0.2, lvlSpi = 0.6,
                haste = 0.65 })
        end },
        -- Demonic Embrace +15% Stamina. Nov 3: pets get 2 health per Stamina (was 7.5).
        { key = "demo", label = "Demonology", weights = function(level, race)
            -- Crit as valued by MythicSim's Forever sim of a Demonic Pact build.
            return Caster(level, race, "WARLOCK", { schools = { { "shadow", 1 }, { "fire", 0.35 } }, crit = 2, spi = 0.3, sta = 0.2, lvlSpi = 0.6,
                haste = 0.65 })   -- 1.2: Crit > Haste (Icy Veins)
        end },
        -- Ruin +100% Destruction crit damage.
        { key = "destro", label = "Destruction", weights = function(level, race)
            return Caster(level, race, "WARLOCK", { schools = { { "shadow", 0.75 }, { "fire", 0.6 } }, crit = 2, spi = 0.25, lvlSpi = 0.5, lvlInt = 0.7,
                haste = 0.95 })
        end },
    },
    DRUID = {
        -- Vengeance +100% crit damage; Nature's Reach +4% hit.
        { key = "balance", label = "Balance", weights = function(level, race)
            -- Forever sims: haste does almost nothing for Moonkin.
            return Caster(level, race, "DRUID", { schools = { { "arcane", 0.6 }, { "nature", 0.6 } }, crit = 2, hit = 4,
                mp5 = 0.35, wand = 0, haste = 0.1 })
        end },
        -- WoW Forever: forms use the weapon's DPS, enchants and on-hit effects (Icy Veins, wow.gg).
        -- Shred 200% and Claw 140% weapon damage (Nov 4). Cat swings at a fixed speed, so no slow bonus.
        -- Heart of the Wild +10% Strength in Cat Form.
        -- Natural Instinct +20% crit damage. Agility gives 1 attack power in Cat Form.
        { key = "feral", label = "Feral", weights = function(level, race)
            return Physical(level, race, "DRUID", { mh = 1.1, strPct = 0.1, critBonus = 1.1, haste = 0.45, agiAP = 1, exp = "hit", hitMult = 1, expRel = 0.97 })   -- 1.2: Hit > Agility > Strength (Icy Veins)
        end },
        -- Heart of the Wild +20% Stamina in bear; Thick Hide and bear form armor.
        { key = "bear", label = "Feral Tank", weights = function(level, race)
            -- WL Helper change (v2): bear = true (no parry or block).
            return Tank(level, race, "DRUID", { staPct = 0.2, armor = 0.12, str = 0.4, bv = 0, blockVal = 0, mh = 2.5, bear = true })   -- Nov 11: bear uses weapon DPS
        end },
        -- Living Spirit +15% Spirit; Bloom heals for 100% of Spirit; Reflection 50% regen while casting.
        { key = "resto", label = "Restoration", weights = function(level, race)
            -- 1.2, level 60: Healing > Intellect > Spirit > Mp5 > Crit (Icy Veins; Mobalytics: Intellect and
            -- Stamina first, then Healing, then Spirit and Mp5).
            return Healer(level, race, "DRUID", { regen = 0.5, spiPct = 0.15, spiHeal = 0.5, intPct = 0.1,
                at60 = { int = 0.9, spi = 0.85, mp5 = 0.7, crit = 0.45, haste = 0.4 } })
        end },
    },
}

local function Set(list)
    local s = {}
    for v in list:gmatch("%d+") do s[tonumber(v)] = true end
    return s
end

-- armor: best armor type (4 = plate). early: best armor before level 40.
-- Weapon numbers are KIND_NAME keys.
local CLASSES = {
    { token = "WARRIOR", name = "Warrior", color = "c79c6e", bit = 1, armor = 4, early = 3, shield = true, dual = true,
      weapons = Set("10 11 12 13 14 15 16 17 18 20 23 25 26 28") },
    { token = "PALADIN", name = "Paladin", color = "f58cba", bit = 2, armor = 4, early = 3, shield = true, relic = 31,
      weapons = Set("10 11 14 15 16 17 18") },
    -- No thrown (26): Auto Shot and Hunter shots need a bow, gun or crossbow, and a thrown
    -- weapon in the ranged slot means no bow at all.
    { token = "HUNTER", name = "Hunter", color = "abd473", bit = 4, armor = 3, early = 2, dual = true,
      weapons = Set("10 11 12 13 16 17 18 20 23 25 28") },
    { token = "ROGUE", name = "Rogue", color = "fff569", bit = 8, armor = 2, dual = true,
      weapons = Set("10 12 13 14 17 23 25 26 28") },
    { token = "PRIEST", name = "Priest", color = "ffffff", bit = 16, armor = 1, weapons = Set("14 20 25 29") },
    { token = "SHAMAN", name = "Shaman", color = "0070de", bit = 64, armor = 3, early = 2, shield = true, relic = 33,
      weapons = Set("10 11 14 15 20 23 25") },
    { token = "MAGE", name = "Mage", color = "69ccf0", bit = 128, armor = 1, weapons = Set("17 20 25 29") },
    { token = "WARLOCK", name = "Warlock", color = "9482c9", bit = 256, armor = 1, weapons = Set("17 20 25 29") },
    { token = "DRUID", name = "Druid", color = "ff7d0a", bit = 1024, armor = 2, relic = 32,
      weapons = Set("14 15 16 20 23 25") },   -- WoW Forever: druids can use polearms
}
local CLASS_BY_TOKEN = {}
for i, c in ipairs(CLASSES) do
    c.index, c.specs = i, SPECS[c.token]
    CLASS_BY_TOKEN[c.token] = c
end

local function FindSpec(cls, key)
    for _, spec in ipairs(cls.specs) do
        if spec.key == key then return spec end
    end
    return cls.specs[1]
end

local playerRace      -- race token ("Human", "Dwarf"...), read by ReadPlayer()
local playerClassToken
local playerFaction = ""  -- "A" or "H"

-- Upstream sets these at PLAYER_LOGIN; the engine reads them when first needed.
-- WL Helper change: race and faction are read again while still unknown (a first call
-- made before the faction is known would otherwise skip the faction filter all session).
local function ReadPlayer()
    if not playerClassToken then
        local token = UnitClass and select(2, UnitClass("player"))
        if type(token) ~= "string" or Secret(token) or not CLASS_BY_TOKEN[token] then return end
        playerClassToken = token
    end
    if playerRace == nil and UnitRace then
        local ok, _, race = pcall(UnitRace, "player")
        playerRace = (ok and type(race) == "string" and not Secret(race)) and race or nil
    end
    if playerFaction == "" and UnitFactionGroup then
        local ok, faction = pcall(UnitFactionGroup, "player")
        if not ok or Secret(faction) then faction = nil end
        playerFaction = (faction == "Alliance" and "A") or (faction == "Horde" and "H") or ""
    end
end

-- Racials only count when you look at your own class.
local function RaceFor(cls)
    return cls and cls.token == playerClassToken and playerRace or nil
end

-- WL Helper change: for your own class the spec's talents and your real hit count
-- (see Adjust and HitHave above). Other classes get Geared Forever's weights as is.
local function Weights(cls, key, level)
    ReadPlayer()
    local own = cls and cls.token == playerClassToken
    ctx = nil
    if own then
        local talents = ScanTalents()
        ctx = { own = true, talents = talents, mods = TALENT_MODS[cls.token] and TALENT_MODS[cls.token][key] }
    end
    local ok, mh, oh, rg, slow, w, prefer = pcall(FindSpec(cls, key).weights, level, RaceFor(cls))
    ctx = nil
    if not ok then error(mh, 0) end
    -- WL Helper change (1.4.0): the wand's DPS as much as the player says he uses it (only the
    -- wand classes: their ranged slot holds a wand), for the player's own class only
    if not opts.neutral and own and cls.weapons and cls.weapons[29] and type(opts.wand) == "number"
        and type(rg) == "number" then
        rg = rg * opts.wand
    end
    return mh, oh, rg, slow, w, prefer
end


local armorPick = 0       -- armor type filter: 0 = all (the engine never filters armor)

-- Where an item comes from, for the source filter.
-- WoW Forever's raids. They open December 9, 2026.
local RAIDS = { ["Onyxia's Lair"] = true, ["Hyjal Summit"] = true, ["Barrow Deeps"] = true }
local DUNGEONS  -- every dungeon and raid name, built on first use

local function Category(item)
    local src = item.source or ""
    if src:find("^PvP") then return "pvp" end
    if src:find("^Raid") then return "raid" end
    -- WL Helper change: SourceData.lua isn't shipped, so its tables may be missing.
    if (ns.itemQuests and ns.itemQuests[item.id]) or src:find("^Quest") then return "quest" end
    if (ns.itemRecipe and ns.itemRecipe[item.id]) or src:find("^Crafted") then return "crafted" end
    -- World drops can also come off a boss now and then; that doesn't make them dungeon loot.
    if src:find("^World drop") then return "world" end
    if not DUNGEONS then
        DUNGEONS = {}
        for _, zone in pairs(ns.questZones or {}) do
            if zone[1] == 0 then DUNGEONS[zone[2]] = true end
        end
        for name in pairs(RAIDS) do DUNGEONS[name] = true end
    end
    local vendor = src:find("^Reputation") or src:find("^Vendor") or src:find("^Sold by")
    for _, row in ipairs((ns.itemSources and ns.itemSources[item.id]) or {}) do
        local zone = row[3] and ns.questZones[row[3]]
        if row[1] == "d" and zone and zone[1] == 0 then
            return RAIDS[zone[2]] and "raid" or "dungeon"
        end
        if row[1] == "v" then vendor = true end
    end
    -- Looked-up sources name the place: "Drop: Boss (Dungeon)" or "Drop: Dungeon".
    if src:find("^Drop") then
        local place = src:match("%(([^)]+)%)%s*$") or src:match("^Drop: (.+)$")
        if place and RAIDS[place] then return "raid" end
        if place and DUNGEONS[place] then return "dungeon" end
    end
    if vendor then return "vendor" end
    if src:find("^Dungeon") then
        return (item.q >= 4 and item.lvl >= 58) and "raid" or "dungeon"
    end
    return "world"
end

local ARMOR_SLOT = { [1] = true, [3] = true, [5] = true, [6] = true, [7] = true, [8] = true, [9] = true, [10] = true }

-- WL Helper change (1.4.0): armor lighter than the best your class wears (cloth or leather for a
-- shaman or hunter, anything but plate for a warrior or paladin, cloth for a druid or rogue),
-- from level 40, when the lighter option is on. Cloaks, rings, shields... never.
local function Lighter(item, cls, level)
    if opts.neutral or not opts.lighter or not (item and cls) then return false end
    if (level or 0) < 40 or not ARMOR_SLOT[item.slot] then return false end
    local kind = item.kind or 0
    return kind >= 1 and kind <= 4 and kind < (cls.armor or 1)
end

-- The window's filters past the level range: armor type and unknown sources.
-- Necks, rings, cloaks, trinkets, and weapons always pass the armor filter.
local function PassesFilters(item, show)
    if item.unknown and show.unknown == false then return false end
    if armorPick ~= 0 and ARMOR_SLOT[item.slot] and item.kind ~= armorPick then return false end
    return true
end

-- Can this class use the item in this section? hi is the top of the level
-- range, for classes that only get mail or plate at 40.
local function Usable(item, sec, cls, hi)
    if item.cls ~= 0 and bit.band(item.cls, cls.bit) == 0 then return false end
    -- The other faction's PvP, reputation, and quest gear.
    if item.fac and item.fac ~= "" and playerFaction ~= "" and item.fac ~= playerFaction then return false end
    local slot, kind = item.slot, item.kind
    if ARMOR_SLOT[slot] then
        return kind <= ((hi >= 40 or not cls.early) and cls.armor or cls.early)
    elseif slot == 17 then
        return cls.shield == true
    elseif slot == 19 then
        return kind == cls.relic
    elseif slot == 20 then
        return true
    elseif kind >= 10 then
        if not cls.weapons[kind] then return false end
        if sec == SEC_OFFHAND then return cls.dual == true end
    end
    return true
end

------------------------------------------------------------------------
-- Scoring
------------------------------------------------------------------------

-- Slow weapons hit harder with instant attacks, so melee specs get a small bonus for them.
-- WL Helper note: kept as upstream on purpose. The main hand keeps its speed bonus; the
-- off hand stays neutral (1), since WoW Forever's Shank strikes with the off hand.
local function SpeedBonus(sec, speed)
    if speed <= 0 then return 1 end
    local m
    if sec == SEC_TWOHAND then
        m = 1 + 0.05 * (speed - 3.3)
    elseif sec == SEC_MAINHAND then
        m = 1 + 0.06 * (speed - 2.3)
    else
        return 1
    end
    if m < 0.94 then return 0.94 elseif m > 1.06 then return 1.06 end
    return m
end

-- WL Helper change (v4): rewards by quest, for WLHelperGear.QuestRewards. QuestData.lua is
-- freed once parsed (below), so the lists are kept first, built the first time they are
-- needed (the first QuestRewards call or Parse, whichever comes first): one compact string
-- per quest ("60,3070,6076"), from the quest's own reward list (ns.quests[id][11], every
-- item in the quest's order) plus ns.itemQuests inverted (an item it misses). About 1,200
-- strings. A quest's list becomes a table only when asked for, then is cached.
local questRewardStr, questRewardNames, questRewardAsked = nil, nil, {}

local function KeepQuestRewards()
    if questRewardStr then return end
    if not (ns.itemQuests or ns.quests) then return end
    local lists, base = {}, {}
    for qid, q in pairs(ns.quests or {}) do
        local rw = type(q) == "table" and q[11]
        if type(rw) == "table" and #rw > 0 then
            local t = {}
            for i, id in ipairs(rw) do t[i] = id end
            lists[qid], base[qid] = t, #t
        end
    end
    for itemID, quests in pairs(ns.itemQuests or {}) do
        for _, qid in ipairs(quests) do
            local t = lists[qid]
            if not t then t = {} lists[qid], base[qid] = t, 0 end
            local has = false
            for _, id in ipairs(t) do if id == itemID then has = true break end end
            if not has then t[#t + 1] = itemID end
        end
    end
    questRewardStr = {}
    for qid, t in pairs(lists) do
        -- the items added from ns.itemQuests come in table order: sorted, so the list is stable
        local n = base[qid] or 0
        if #t > n + 1 then
            local tail = {}
            for i = n + 1, #t do tail[#tail + 1] = t[i] end
            table.sort(tail)
            for i, id in ipairs(tail) do t[n + i] = id end
        end
        questRewardStr[qid] = table.concat(t, ",")
    end
    -- names of the reward items that are not in Data.lua (about 150)
    questRewardNames = {}
    for id, name in pairs(ns.rewardNames or {}) do questRewardNames[id] = name end
end

-- { itemID, ... } for a quest (a new table each call), or nil when no reward is known.
local function QuestRewards(qid)
    qid = tonumber(qid)
    if not qid then return nil end
    local list = questRewardAsked[qid]
    if list == nil then
        KeepQuestRewards()
        local s = questRewardStr and questRewardStr[qid]
        list = false
        if s then
            list = {}
            for id in s:gmatch("%d+") do list[#list + 1] = tonumber(id) end
        end
        questRewardAsked[qid] = list
    end
    if not list then return nil end
    local out = {}
    for i, id in ipairs(list) do out[i] = id end
    return out
end

-- The English name of a reward item (Data.lua or QuestData.lua), or nil.
local function RewardName(id)
    local item = ns.byId and ns.byId[id]
    if item and item.name then return item.name end
    return questRewardNames and questRewardNames[id] or nil
end

-- WL Helper change (v5, report: "Gear takes 28 MB"): an item keeps only what is not a default. Its
-- stats hold the non-zero ones (the zeros come from ZEROS), its other fields their default from
-- ITEM_DEF (bind 0, kind 0, no weapon speed or DPS, every class, both factions, no flags). About
-- 9,700 items: 20 MB down to about 11 MB, read exactly as before.
local ZEROS = {}
for k = 1, NUM_STATS do ZEROS[k] = 0 end
local STAT_META = { __index = ZEROS }
local ITEM_DEF = { bind = 0, kind = 0, spd = 0, dps = 0, cls = 0, fac = "" }
local ITEM_META = { __index = ITEM_DEF }
ns.ITEM_META = ITEM_META
local function NZ(v) v = tonumber(v); if v and v ~= 0 then return v end return nil end

function ns.Parse()
    if ns.items then return end
    -- WL Helper change (v4): keep the rewards by quest before QuestData.lua is freed.
    KeepQuestRewards()
    local items = {}
    for i, line in ipairs(ns.raw) do
        local f = { strsplit(";", line, 42) }
        local source, guessed = f[41], false
        if source and source:sub(1, 1) == "~" then
            guessed = true
            source = source:sub(2)
        end
        local st = setmetatable({}, STAT_META)
        for k = 1, NUM_STATS do
            local v = f[12 + k]
            if v ~= "" and v ~= nil then v = tonumber(v); if v and v ~= 0 then st[k] = v end end
        end
        local fac = f[12]
        items[i] = setmetatable({
            id = tonumber(f[1]), slot = tonumber(f[2]), lvl = tonumber(f[3]), est = f[4] == "1" or nil, noreq = f[5] == "1" or nil,
            q = tonumber(f[6]), bind = NZ(f[7]), kind = NZ(f[8]), spd = NZ(f[9]),
            dps = NZ(f[10]), cls = NZ(f[11]), fac = (fac ~= "" and fac) or nil, st = st, source = source,
            guessed = guessed or nil, name = f[42],
        }, ITEM_META)
    end
    for _, item in ipairs(items) do
        item.cat = Category(item)
        -- No quest, drop, vendor, or recipe data, just a guess from the item
        -- itself. PvP rank gear is easy to spot, so it doesn't count.
        -- WL Helper change: SourceData.lua isn't shipped (no source lists here).
        local linked = (ns.itemQuests and ns.itemQuests[item.id]) or (ns.itemSources and ns.itemSources[item.id])
            or (ns.itemRecipe and ns.itemRecipe[item.id])
        local src = item.source or ""
        item.unknown = (not linked and item.cat ~= "pvp"
            and (item.guessed or src == "" or src:find("^Not listed") ~= nil)) or nil
        -- Rewards from one faction's quests only belong to that faction.
        local quests = item.fac == "" and ns.itemQuests and ns.itemQuests[item.id]
        if quests then
            local fac
            for _, id in ipairs(quests) do
                local f = ns.quests and ns.quests[id] and ns.quests[id][4] or ""
                if f == "" or (fac and fac ~= f) then fac = false break end
                fac = f
            end
            if fac then item.fac = fac end
        end
    end
    ns.items = items
    ns.byId = {}
    for _, item in ipairs(items) do ns.byId[item.id] = item end
    ns.raw = nil
    -- WL Helper change: QuestData.lua is only shipped to tell which faction a quest
    -- reward belongs to. That's done now, so free it.
    ns.questZones, ns.itemQuests, ns.quests, ns.rewardNames = nil, nil, nil, nil
end

local function Better(aItem, aScore, bItem, bScore)
    if aScore ~= bScore then return aScore > bScore end
    if aItem.q ~= bItem.q then return aItem.q > bItem.q end
    return aItem.id < bItem.id
end

------------------------------------------------------------------------
-- WL Helper change (v2): proc and use effects.
--
-- Data.lua only has flat stats, so "Chance on hit" and "Use:" items scored their stats
-- alone (Hand of Justice 12 AP) or nothing (Earthstrike, 0). Each item below turns its
-- effect into stats the spec already weighs:
--   stat keys (ap, str, sp, mp5, crit...): the average stat the effect gives
--     (Use: amount x duration / cooldown x 0.8 for timing; procs: amount x uptime)
--   mdmg: % more melee damage (extra attacks, damage procs, armor reduction), valued at
--     the spec's worth of 1% damage (0 for casters, healers and ranged hunters). An extra
--     attack is a white swing, about 60% of melee damage: HoJ's 2% chance = 1.2.
--   role: only for that kind of spec ("phys", "caster", "healer", "tank")
-- Values are vanilla mechanics, kept on the low side; a Forever rework the table doesn't
-- know about is not guessed. Items not in the table: Compare reads their "Use:" line from
-- the tooltip (ItemEffects below) and flags procs it can't value.
------------------------------------------------------------------------
local PROCS = {
    [11815] = { mdmg = 1.2, note = "extra attacks (2% chance on hit)" },          -- Hand of Justice
    [21180] = { ap = 37, rap = 37, note = "Use: +280 attack power, 20 s / 2 min" }, -- Earthstrike
    [11684] = { mdmg = 3.5, note = "2 extra attacks on hit" },                    -- Ironfoe
    [871]   = { mdmg = 2.5, note = "extra attack on hit" },                       -- Flurry Axe
    [17705] = { mdmg = 2.5, note = "extra attack on hit" },                       -- Thrash Blade
    [12798] = { mdmg = 3, note = "armor reduction on hit" },                    -- Annihilator
    [12790] = { str = 40, note = "Strength proc on hit" },                      -- Arcanite Champion
    [870]   = { mdmg = 2, note = "fire damage on hit" },                        -- Fiery War Axe
    [1728]  = { mdmg = 2, note = "fire damage on hit" },                        -- Teebu's Blazing Longsword
    [14541] = { mdmg = 1, note = "shadow drain on hit" },                     -- Barovian Family Sword
    [13361] = { mdmg = 1, note = "life drain on hit" },                       -- Skullforge Reaver
    [19288] = { mp5 = 20, note = "regen proc on cast" },                        -- Darkmoon Card: Blue Dragon
    [18646] = { crit = 28, role = "healer", note = "+2% Holy crit" },           -- The Eye of Divinity
    [19958] = { haste = 27, role = "healer", note = "Use: faster heals, 15 s / 3 min" }, -- Hazza'rah's Charm of Healing
    [22678] = { sp = 15, heal = 10, note = "Use: stacking spell power" },       -- Talisman of Ascendance
    [18820] = { sp = 23, note = "Use: +175 spell power, 15 s / 90 s" },         -- Talisman of Ephemeral Power
}

local function ProcScore(p, w)
    if p.role and w.role and p.role ~= w.role then return 0 end
    local s = (p.mdmg or 0) * (w.mdmg or 0)
    for k, v in pairs(p) do
        local i = STAT[k]
        if i and type(v) == "number" then s = s + v * w[i] end
    end
    return s
end

-- Score from stats alone. Weapon damage is added per section below.
-- WL Helper change (v3): percent hit, crit and haste lines are kept apart by kind:
-- st.spell (spell hit, spell crit, casting speed) counts for casters and healers only,
-- st.melee (chance to hit, critical strike, attack speed) for the other specs only.
local function SplitScore(st, w)
    local b
    if w.role == "caster" or w.role == "healer" then b = st.spell else b = st.melee end
    local s = 0
    if b then for k, v in pairs(b) do s = s + v * (w[k] or 0) end end
    return s
end
local function MergeSplit(dst, src, f)
    for _, kind in ipairs({ "spell", "melee" }) do
        if src[kind] then
            dst[kind] = dst[kind] or {}
            for k, v in pairs(src[kind]) do dst[kind][k] = (dst[kind][k] or 0) + v * (f or 1) end
        end
    end
end

local function BaseScore(item, w)
    local base, st = 0, item.st
    for k = 1, NUM_STATS do
        local v = st[k]
        if v ~= 0 then base = base + v * w[k] end
    end
    base = base + SplitScore(st, w)   -- WL Helper change (v3)
    -- WL Helper change (v2): proc and use effects from the table above.
    local p = not opts.neutral and PROCS[item.id]
    if p then base = base + ProcScore(p, w) end
    return base
end

local function SectionScore(item, sec, base, mh, oh, rg, slowBonus, prefer)
    local dpsWeight = (sec == SEC_RANGED and rg) or (sec == SEC_OFFHAND and oh) or mh
    local dps = item.dps
    -- Hunters can equip thrown weapons, but Auto Shot and their shots only work with
    -- bows, guns and crossbows. So a thrown weapon is just its stats for them.
    if prefer and prefer.statsOnly and prefer.statsOnly[item.kind] then dps = 0 end
    if slowBonus then dps = dps * SpeedBonus(sec, item.spd) end
    local score = base + dps * dpsWeight
    if prefer and prefer[item.kind] then score = score * prefer[item.kind] end
    return score
end

-- Returns a list per section: { {item=..., score=...}, ... } best first.
-- includeQuest = false leaves out quest rewards that have no level requirement.
function ns.Rank(cls, specKey, lo, hi, includeQuest, topN, show)
    ns.Parse()
    local mh, oh, rg, slowBonus, w, prefer = Weights(cls, specKey, hi)
    local out = {}
    for i = 1, #SECTIONS do out[i] = {} end

    for _, item in ipairs(ns.items) do
        if item.lvl >= lo and item.lvl <= hi and (includeQuest or not item.noreq) and show[item.cat] ~= false
            and PassesFilters(item, show) then
            local base
            for _, sec in ipairs(SLOT_SECTIONS[item.slot]) do
                if Usable(item, sec, cls, hi) then
                    base = base or BaseScore(item, w)
                    local score = SectionScore(item, sec, base, mh, oh, rg, slowBonus, prefer)
                    if score > 0 then
                        local list = out[sec]
                        local pos = #list + 1
                        while pos > 1 and Better(item, score, list[pos - 1].item, list[pos - 1].score) do
                            pos = pos - 1
                        end
                        if pos <= topN then
                            table.insert(list, pos, { item = item, score = score })
                            list[topN + 1] = nil
                        end
                    end
                end
            end
        end
    end
    return out
end

local function Clamp(n)
    n = tonumber(n) or 1
    if n < 1 then return 1 end
    if n > MAX_LEVEL then return MAX_LEVEL end
    return math.floor(n)
end

-- Section -> character slots to compare against.
local INV_SLOTS = {
    [1] = { 1 }, [2] = { 2 }, [3] = { 3 }, [4] = { 15 }, [5] = { 5 }, [6] = { 9 }, [7] = { 10 }, [8] = { 6 },
    [9] = { 7 }, [10] = { 8 }, [11] = { 11, 12 }, [12] = { 13, 14 },
    [SEC_TWOHAND] = { 16 }, [SEC_MAINHAND] = { 16 }, [SEC_OFFHAND] = { 17 }, [SEC_SHIELD] = { 17 }, [SEC_RANGED] = { 18 },
}
local EQUIP_SLOT = {
    INVTYPE_HEAD = 1, INVTYPE_NECK = 2, INVTYPE_SHOULDER = 3, INVTYPE_CLOAK = 4, INVTYPE_CHEST = 5, INVTYPE_ROBE = 5,
    INVTYPE_WRIST = 6, INVTYPE_HAND = 7, INVTYPE_WAIST = 8, INVTYPE_LEGS = 9, INVTYPE_FEET = 10, INVTYPE_FINGER = 11,
    INVTYPE_TRINKET = 12, INVTYPE_2HWEAPON = 13, INVTYPE_WEAPON = 14, INVTYPE_WEAPONMAINHAND = 15,
    INVTYPE_WEAPONOFFHAND = 16, INVTYPE_SHIELD = 17, INVTYPE_RANGED = 18, INVTYPE_RANGEDRIGHT = 18, INVTYPE_THROWN = 18,
    INVTYPE_RELIC = 19, INVTYPE_HOLDABLE = 20,
}

-- An item from the built-in list, or one read from the game for items the
-- list doesn't have (random-stat greens, for example).
-- Random-suffix items ("of the Owl") share their base item's ID, so their stats
-- have to come from the link. The suffix ID is the 7th field of the item string.
local function HasSuffix(link)
    if type(link) ~= "string" then return false end
    local suffix = link:match("item:%-?%d+:%-?%d*:%-?%d*:%-?%d*:%-?%d*:%-?%d*:(%-?%d*)")
    return suffix ~= nil and suffix ~= "" and suffix ~= "0"
end

-- Some random-stat items ("of Healing") put their spell power in an Equip line that
-- GetItemStats doesn't report. Read it off the item's own tooltip instead.
local liveCache = {}
local scanTip

-- WL Helper change (1.3.0): true on an English client (Data.lua's names are English).
local function EnglishClient()
    local ok, loc = pcall(GetLocale or function() return "enUS" end)
    return not ok or type(loc) ~= "string" or loc:sub(1, 2) == "en"
end
local function TooltipLines(link)
    local lines = {}
    if C_TooltipInfo and C_TooltipInfo.GetHyperlink then
        local data = C_TooltipInfo.GetHyperlink(link)
        for _, line in ipairs((data and data.lines) or {}) do
            local text = line.leftText
            -- WL Helper change: secret or non-string text is skipped.
            if type(text) == "string" and not Secret(text) then lines[#lines + 1] = text end
        end
        if #lines > 0 then return lines end
    end
    if not scanTip then
        scanTip = CreateFrame("GameTooltip", "WLHelperGearScanTip", nil, "GameTooltipTemplate")
    end
    scanTip:SetOwner(WorldFrame, "ANCHOR_NONE")
    scanTip:ClearLines()
    scanTip:SetHyperlink(link)
    for i = 1, scanTip:NumLines() do
        local fs = _G["WLHelperGearScanTipTextLeft" .. i]
        local text = fs and fs:GetText()
        if type(text) == "string" and not Secret(text) then lines[#lines + 1] = text end
    end
    scanTip:Hide()
    return lines
end

-- WL Helper change (v3): a "Use:" line ("Utiliser :", also with a no-break space) gives
-- stats for a few seconds only. TooltipEffects and PROCS average it over its cooldown.
-- The no-break space is replaced before lower(): lower() may change its bytes.
local function NoNbsp(text)
    return (text:gsub("\194\160", " "))
end
local function IsUseLine(text)
    local t = NoNbsp(text):lower()
    return t:find("^use%s*:") or t:find("^utiliser%s*:")
end

-- Returns spell power for both, extra healing, extra damage (the list's sp / heal / sdmg).
local function SpellStatsFromLines(lines)
    local both, heal, dmg = 0, 0, 0
    for _, text in ipairs(lines) do
        local t = text:lower()
        if opts.neutral or not IsUseLine(text) then   -- WL Helper change (v3)
        local n = t:match("damage and healing done by magical spells and effects by up to (%d+)")
            or t:match("^%+(%d+) spell power") or t:match("^%+(%d+) damage and healing")
            -- WL Helper change: the French client's line, matched without accented letters
            -- (lower() may change their bytes).
            or t:match("et les soins produits par les sorts et effets magiques de (%d+)")
            or t:match("^%+(%d+) %S+ la puissance des sorts")
        if n then both = both + tonumber(n) end
        n = t:match("healing done by up to (%d+)") or t:match("healing done by spells and effects by up to (%d+)")
            or t:match("^%+(%d+) healing")
        if n then heal = heal + tonumber(n) end
        n = t:match("and damage done by up to (%d+)") or t:match("^%+(%d+) damage spells")
        if n then dmg = dmg + tonumber(n) end
        end
    end
    -- "healing up to 17 and damage up to 6": 6 counts for both, 11 is healing only.
    if heal > 0 and dmg > 0 then
        local shared = math.min(heal, dmg)
        both, heal, dmg = both + shared, heal - shared, dmg - shared
    end
    return both, heal, dmg
end

-- WL Helper change: true when the client has the item's data. When it doesn't, asks for
-- it (GET_ITEM_INFO_RECEIVED follows). With neither API present, assumes it has.
local function ItemDataReady(id, link)
    local isCached = C_Item and C_Item.IsItemDataCachedByID
    local ready
    if isCached then
        local ok, v = pcall(isCached, id)
        if ok and type(v) == "boolean" then ready = v end
    end
    if ready == nil and GetInfo then
        local ok, name = pcall(GetInfo, link or id)
        if ok then ready = name ~= nil end
    end
    if ready == false then
        local request = C_Item and C_Item.RequestLoadItemDataByID
        if request then pcall(request, id) end
        return false
    end
    return true
end

-- WL Helper change (beta.93): random suffixes outside the suffix field. suffixMemo[link] is
-- true when the link's stats have one the list's copy lacks (read live), false otherwise.
local suffixMemo = {}
local SUFFIX_KEYS = {
    ITEM_MOD_STRENGTH_SHORT = 2, ITEM_MOD_AGILITY_SHORT = 3, ITEM_MOD_STAMINA_SHORT = 4,
    ITEM_MOD_ATTACK_POWER_SHORT = 5, ITEM_MOD_CRIT_RATING_SHORT = 6, ITEM_MOD_HIT_RATING_SHORT = 7,
    ITEM_MOD_DEFENSE_SKILL_RATING_SHORT = 10, ITEM_MOD_DODGE_RATING_SHORT = 11,
    ITEM_MOD_INTELLECT_SHORT = 15, ITEM_MOD_SPIRIT_SHORT = 16, ITEM_MOD_SPELL_POWER_SHORT = 17,
    ITEM_MOD_SPELL_HEALING_DONE_SHORT = 18, ITEM_MOD_MANA_REGENERATION_SHORT = 20,
}
local function ExtraStats(known, live)
    for key, k in pairs(SUFFIX_KEYS) do
        local v = live[key]
        if type(v) == "number" and not Secret(v) and v > 0 and (known.st[k] or 0) == 0 then return true end
    end
    return false
end
local function NoStatsButArmor(known)
    for k = 2, NUM_STATS do if known.st[k] ~= 0 then return false end end
    return true
end

local function LiveItem(id, link)
    ns.Parse()
    local known = ns.byId[id]
    if known and not HasSuffix(link) then
        -- Forever can put the random suffix ("of Agility") somewhere else in the link, so
        -- also read it live when the list's copy has no stats or the name is longer.
        -- Weapons with damage but no stats (Black Menace, Meteor Shard) aren't bare.
        local bare = (known.dps or 0) == 0
        for k = 1, NUM_STATS do if known.st[k] ~= 0 then bare = false break end end
        local linkName = type(link) == "string" and link:match("|h%[(.-)%]|h")
        -- WL Helper change (1.3.0): the list's names are English, so the name test only runs
        -- on English clients; elsewhere (frFR) every name would differ and every item would
        -- be read live instead of from the checked list.
        local renamed = linkName and known.name and linkName ~= known.name and EnglishClient()
        if not bare and not renamed then
            -- WL Helper change (beta.93): on other clients a random-suffix item whose suffix
            -- is not in the suffix field ("Heaume de champion de force") was read from the list
            -- (armor only), so what you wear lost its stats and the gains came out huge
            -- (+1128 %). The link's own stats are read once: a stat the list does not have
            -- means a suffix, and the item is read live (below).
            if not link or not GetStats or suffixMemo[link] == false then return known end
            if suffixMemo[link] == nil then
                if not ItemDataReady(id, link) then
                    -- not loaded yet: a list item with nothing but armor may carry a suffix,
                    -- so it waits ("unknown", retried); any other list item is read as listed
                    if (known.q or 0) >= 2 and NoStatsButArmor(known) then return nil end
                    return known
                end
                local live = GetStats(link)
                suffixMemo[link] = type(live) == "table" and ExtraStats(known, live) or false
                if not suffixMemo[link] then return known end
            end
        end
        if not link then return known end
    end
    if not link or not GetStats then return known end
    if liveCache[link] then return liveCache[link] end
    -- WL Helper change: an item the client hasn't loaded yet gives empty stats. Ask for it
    -- and return nil ("unknown"); the caller retries after GET_ITEM_INFO_RECEIVED.
    if not ItemDataReady(id, link) then return nil end
    local _, _, _, equipLoc, _, classID, subClassID = GetInstant(id)
    local slot = EQUIP_SLOT[equipLoc or ""]
    local stats = slot and GetStats(link)
    if not stats then return nil end
    local function g(key) return stats[key] or 0 end
    local kind = 0
    if classID == 2 then
        kind = (subClassID or 0) + 10
    elseif classID == 4 and equipLoc ~= "INVTYPE_CLOAK" and subClassID and subClassID >= 1 and subClassID <= 4 then
        kind = subClassID
    end
    local item = {
        id = id, slot = slot, q = 0, lvl = 0, spd = 0, live = true, kind = kind, cls = 0,
        dps = g("ITEM_MOD_DAMAGE_PER_SECOND_SHORT"),
        st = { g("RESISTANCE0_NAME"), g("ITEM_MOD_STRENGTH_SHORT"), g("ITEM_MOD_AGILITY_SHORT"), g("ITEM_MOD_STAMINA_SHORT"),
               g("ITEM_MOD_ATTACK_POWER_SHORT") + g("ITEM_MOD_MELEE_ATTACK_POWER_SHORT"),
               g("ITEM_MOD_CRIT_RATING_SHORT"), g("ITEM_MOD_HIT_RATING_SHORT"), g("ITEM_MOD_HASTE_RATING_SHORT"),
               g("ITEM_MOD_EXPERTISE_RATING_SHORT"), g("ITEM_MOD_DEFENSE_SKILL_RATING_SHORT"),
               g("ITEM_MOD_DODGE_RATING_SHORT"), g("ITEM_MOD_PARRY_RATING_SHORT"), g("ITEM_MOD_BLOCK_RATING_SHORT"),
               g("ITEM_MOD_BLOCK_VALUE_SHORT"),
               g("ITEM_MOD_INTELLECT_SHORT"), g("ITEM_MOD_SPIRIT_SHORT"), g("ITEM_MOD_SPELL_POWER_SHORT"),
               g("ITEM_MOD_SPELL_HEALING_DONE_SHORT"), g("ITEM_MOD_SPELL_DAMAGE_DONE_SHORT"),
               g("ITEM_MOD_MANA_REGENERATION_SHORT") + g("ITEM_MOD_POWER_REGEN0_SHORT"),
               g("ITEM_MOD_RANGED_ATTACK_POWER_SHORT"), g("ITEM_MOD_FIRE_DAMAGE_DONE_SHORT"),
               g("ITEM_MOD_FROST_DAMAGE_DONE_SHORT"), g("ITEM_MOD_SHADOW_DAMAGE_DONE_SHORT"),
               g("ITEM_MOD_ARCANE_DAMAGE_DONE_SHORT"), g("ITEM_MOD_NATURE_DAMAGE_DONE_SHORT"),
               g("ITEM_MOD_HOLY_DAMAGE_DONE_SHORT"), g("ITEM_MOD_SPELL_PENETRATION_SHORT") },
    }
    -- WL Helper change: the stats API may report "damage and healing done by magical spells" as
    -- healing only (Rotgrip Mantle: +13 counted as healing, so a frost mage saw -14 %). With no
    -- plain spell power from the API, the tooltip is read too: a "damage and healing" line is
    -- spell power for both, and only the rest stays healing.
    local apiHeal, apiDmg = item.st[STAT.heal], item.st[STAT.sdmg]
    if item.st[STAT.sp] == 0 then
        local ok, lines = pcall(TooltipLines, link)
        if ok and lines then
            -- WL Helper change: read inside pcall, like the tooltip itself.
            pcall(function()
                local both, heal, dmg = SpellStatsFromLines(lines)
                if both == 0 and heal == 0 and dmg == 0 then heal, dmg = apiHeal, apiDmg end
                if both > 0 then heal = math.max(heal, apiHeal - both, 0); dmg = math.max(dmg, apiDmg - both, 0) end
                item.st[STAT.sp], item.st[STAT.heal], item.st[STAT.sdmg] = both, heal, dmg
                -- "of Fiery Wrath" and friends: one school only.
                for _, text in ipairs(lines) do
                    local school, n = text:lower():match("damage done by (%a+) spells and effects by up to (%d+)")
                    if school and not opts.neutral and IsUseLine(text) then school = nil end   -- WL Helper change (v3)
                    if school and STAT[school] and item.st[STAT[school]] == 0 then item.st[STAT[school]] = tonumber(n) end
                end
            end)
        end
    end
    -- WL Helper change (v3): the client's defense rating turned into skill points, the unit
    -- Data.lua and the defense weight use. Only when the client gives a ratio.
    if not opts.neutral and item.st[STAT.def] > 0 and stats.ITEM_MOD_DEFENSE_SKILL_RATING_SHORT then
        local _, ratio = OwnedDefense()
        if ratio and ratio > 0 and math.abs(ratio - 1) > 0.01 then item.st[STAT.def] = item.st[STAT.def] * ratio end
    end
    if known then
        -- Same stats as the list's copy: it's the list's item after all, so keep its rank.
        local same = true
        for k = 1, NUM_STATS do
            if (item.st[k] or 0) ~= (known.st[k] or 0) and not (k == STAT.sp or k == STAT.heal or k == STAT.sdmg) then same = false break end
        end
        if same then
            liveCache[link] = known
            return known
        end
        -- Keep what the list knows (level, speed, weapon type, hidden spell power) and use the
        -- link's stats on top.
        local merged = setmetatable({}, getmetatable(known))
        for k, v in pairs(known) do merged[k] = v end
        merged.st = {}
        for k = 1, NUM_STATS do merged.st[k] = item.st[k] end
        for _, k in ipairs({ STAT.sp, STAT.heal, STAT.sdmg }) do
            merged.st[k] = math.max(merged.st[k] or 0, known.st[k] or 0)
        end
        merged.live = true
        item = merged
    end
    -- WL Helper change: empty stats are not cached (the item may still be loading).
    -- WL Helper change (1.3.0): a listed item with no stats (effect-only trinket, relic) is
    -- final once its data is loaded (ItemDataReady passed above), so it is cached too.
    if next(stats) ~= nil or known then liveCache[link] = item end
    return item
end


------------------------------------------------------------------------
-- WL Helper change: enchants on equipped items.
--
-- Geared Forever scores the item as it drops, so a new item is compared against
-- your equipped one without its enchant. Here the enchant on the equipped item is
-- read and counted, so the new (unenchanted) item has to beat the item plus its
-- enchant. The enchant is found by reading the tooltip of the equipped link and of
-- the same link with the enchant field cleared: the extra lines are the enchant.
------------------------------------------------------------------------

-- The enchant ID is the 2nd field of the item string ("item:id:enchant:...").
local function EnchantID(link)
    if type(link) ~= "string" then return nil end
    local e = tonumber(link:match("item:%-?%d+:(%-?%d*)") or "")
    if e and e > 0 then return e end
    return nil
end

local function StripEnchant(link)
    return (link:gsub("(item:%-?%d+:)%-?%d*", "%10", 1))
end

-- Words on an enchant line -> stats. Lowercase, English and French; checked in order,
-- so "attack power" wins over "power" and "spell damage" over "damage".
local ENCHANT_WORDS = {
    { "all stats", { "str", "agi", "sta", "int", "spi" } },
    { "toutes les caractéristiques", { "str", "agi", "sta", "int", "spi" } },
    { "weapon damage", "wdmg" }, { "aux armes", "wdmg" }, { "dégâts de l'arme", "wdmg" },
    { "ranged attack power", "rap" }, { "puissance d'attaque à distance", "rap" },
    { "attack power", "ap" }, { "puissance d'attaque", "ap" },
    { "spell power", "sp" }, { "puissance des sorts", "sp" },
    { "damage and healing", "sp" }, { "spell damage", "sp" }, { "dégâts des sorts", "sp" },
    { "healing", "heal" }, { "soins", "heal" },
    { "mana every 5", "mp5" }, { "mana toutes les 5", "mp5" }, { "mp5", "mp5" },
    { "spell hit", "hit" }, { "hit", "hit" }, { "toucher", "hit" },
    { "critical", "crit" }, { "critique", "crit" },
    { "haste", "haste" }, { "hâte", "haste" },
    { "defense", "def" }, { "défense", "def" },
    { "dodge", "dodge" }, { "esquive", "dodge" },
    { "parry", "parry" }, { "parade", "parry" },
    { "block value", "bv" }, { "valeur de blocage", "bv" },
    { "block", "block" }, { "blocage", "block" },
    { "agility", "agi" }, { "agilité", "agi" },
    { "strength", "str" }, { "force", "str" },
    { "stamina", "sta" }, { "endurance", "sta" },
    { "intellect", "int" }, { "intelligence", "int" },
    { "spirit", "spi" }, { "esprit", "spi" },
    { "armor", "armor" }, { "armure", "armor" },
}

-- WL Helper change (v2): percent lines turned into rating (Forever: 14 crit, 10 hit,
-- 10 haste, 12 dodge, 15 parry, 5 block = 1%). Checked in order.
-- WL Helper change (v3): hit needs "chance to hit"; spell lines and melee lines are kept
-- apart (st.spell / st.melee, see SplitScore).
local PCT_WORDS = {
    { "attack speed", "haste", 10 }, { "vitesse d'attaque", "haste", 10 },
    { "casting speed", "haste", 10, "spell" }, { "vitesse d'incantation", "haste", 10, "spell" },
    { "critical", "crit", 14 }, { "critique", "crit", 14 },
    { "chance to hit", "hit", 10 }, { "chances de toucher", "hit", 10 }, { "chance de toucher", "hit", 10 },
    { "% hit", "hit", 10 }, { "% toucher", "hit", 10 }, { "% au toucher", "hit", 10 },
    { "dodge", "dodge", 12 }, { "esquive", "dodge", 12 },
    { "parry", "parry", 15 }, { "parade", "parry", 15 },
    { "block", "block", 5 }, { "blocage", "block", 5 },
}

-- One enchant line: adds to st (stat array) and returns extra weapon damage.
local function ParseEnchantLine(text, st)
    local t = text:lower():gsub("^enchanted:%s*", ""):gsub("^enchanté%s*:%s*", "")
    if t:find("%%") then
        if opts.neutral then return 0 end         -- "+1% dodge" and the like: not a flat stat
        -- WL Helper change (v2): "+2% hit", "Increases attack speed by 3%" -> rating.
        local p = tonumber(t:match("(%d+)%s*%%") or "")
        if not p then return 0 end
        -- WL Helper change (v3): "2% chance on melee hit to ..." is a proc, not a stat.
        if t:find("chance on", 1, true) or t:find("chances quand", 1, true) or t:find("chance quand", 1, true) then return 0 end
        for _, row in ipairs(PCT_WORDS) do
            if t:find(row[1], 1, true) then
                local k = row[2]
                if k == "hit" or k == "crit" or k == "haste" then
                    local kind = row[4] or ((t:find("spell", 1, true) or t:find("sort", 1, true)) and "spell" or "melee")
                    st[kind] = st[kind] or {}
                    st[kind][STAT[k]] = (st[kind][STAT[k]] or 0) + p * row[3]
                else
                    st[STAT[k]] = st[STAT[k]] + p * row[3]
                end
                return 0
            end
        end
        return 0
    end
    local n = tonumber(t:match("%+%s*(%d+)") or "")
    -- WL Helper change (v2): set bonuses and Use lines say "by N" ("de N") instead of "+N".
    if not n and not opts.neutral then n = tonumber(t:match("by up to (%d+)") or t:match("by (%d+)") or t:match(" de (%d+)") or "") end
    if not n then return 0 end
    for _, row in ipairs(ENCHANT_WORDS) do
        if t:find(row[1], 1, true) then
            local what = row[2]
            if what == "wdmg" then return n end
            if type(what) == "table" then
                for _, k in ipairs(what) do st[STAT[k]] = st[STAT[k]] + n end
            else
                st[STAT[what]] = st[STAT[what]] + n
            end
            return 0
        end
    end
    -- WL Helper change (v2): scopes read "+7 Damage": weapon damage.
    if not opts.neutral and (t:find("damage", 1, true) or t:find("dégâts", 1, true)) then return n end
    return 0
end

-- WL Helper change (v2): enchants whose line has no number to read (procs, or a bare
-- name like "Crusader"), as average stats. Crusader: 100 Strength for 15 s at about
-- 1 proc a minute (~22% uptime, a bit more with haste) -> 25 Strength.
local ENCHANT_IDS = {
    [1900] = { str = 25, note = "Crusader" },
    [803]  = { ap = 25, note = "Fiery Weapon" },
    [1898] = { ap = 15, note = "Lifestealing" },
    [1894] = { ap = 10, note = "Icy Chill" },
    [34]   = { haste = 30, note = "Iron Counterweight (+3% attack speed)" },
    [2523] = { hit = 30, note = "Biznicks Accurascope (+3% hit)" },
}

local enchantCache = {}

-- WL Helper change: a tooltip still loading ("Retrieving item information", or too few
-- lines to hold an enchant) is not read, so it can't be cached as "no enchant".
local RETRIEVING = (type(RETRIEVING_ITEM_INFO) == "string" and RETRIEVING_ITEM_INFO) or "Retrieving item information"
local function TooltipReady(lines, minLines)
    if not lines or #lines < minLines then return false end
    for _, text in ipairs(lines) do
        if text == RETRIEVING or text == "Retrieving item information" then return false end
    end
    return true
end

-- Stats added by the enchant on a link: { st = {28 numbers}, wdmg = weapon damage, id = enchant ID }
-- or nil when there's no enchant or it can't be read.
-- WL Helper change: only a loaded tooltip is cached; one still loading (or a read error)
-- is tried again on the next call. The cache is also cleared on GET_ITEM_INFO_RECEIVED
-- and PLAYER_EQUIPMENT_CHANGED (Api.lua).
local function EnchantStats(link)
    if not EnchantID(link) then return nil end
    local cached = enchantCache[link]
    if cached ~= nil then return cached or nil end
    -- WL Helper change (v2): known proc enchants come from ENCHANT_IDS, no tooltip needed.
    local known = not opts.neutral and ENCHANT_IDS[EnchantID(link)]
    if known then
        local st = {}
        for k = 1, NUM_STATS do st[k] = 0 end
        for k, v in pairs(known) do
            if STAT[k] then st[STAT[k]] = v end
        end
        local result = { st = st, wdmg = 0, id = EnchantID(link), note = known.note }
        enchantCache[link] = result
        return result
    end
    local ok1, withLines = pcall(TooltipLines, link)
    local ok2, bareLines = pcall(TooltipLines, StripEnchant(link))
    -- An enchanted tooltip has at least the name, the slot and the enchant line.
    if not (ok1 and ok2 and TooltipReady(withLines, 3) and TooltipReady(bareLines, 1)) then return nil end
    enchantCache[link] = false
    local bare = {}
    for _, text in ipairs(bareLines) do
        if type(text) == "string" and not Secret(text) then bare[text] = (bare[text] or 0) + 1 end
    end
    local st, wdmg, any = {}, 0, false
    for k = 1, NUM_STATS do st[k] = 0 end
    for _, text in ipairs(withLines) do
        if type(text) == "string" and not Secret(text) then
            if bare[text] and bare[text] > 0 then
                bare[text] = bare[text] - 1
            else
                local before = 0
                for k = 1, NUM_STATS do before = before + st[k] end
                local splitBefore = (st.spell and 1 or 0) + (st.melee and 1 or 0)   -- WL Helper change (v3)
                wdmg = wdmg + ParseEnchantLine(text, st)
                local after = 0
                for k = 1, NUM_STATS do after = after + st[k] end
                if (st.spell and 1 or 0) + (st.melee and 1 or 0) ~= splitBefore then after = after + 1 end
                if after ~= before or wdmg > 0 then any = true end
            end
        end
    end
    if not any then return nil end
    local result = { st = st, wdmg = wdmg, id = EnchantID(link) }
    enchantCache[link] = result
    return result
end

-- A copy of item with the enchant on link added.
local function WithEnchant(item, link)
    local ench = EnchantStats(link)
    if not ench then return item, nil end
    local copy = setmetatable({}, getmetatable(item))
    for k, v in pairs(item) do copy[k] = v end
    copy.st = {}
    for k = 1, NUM_STATS do copy.st[k] = (item.st[k] or 0) + ench.st[k] end
    MergeSplit(copy.st, item.st) MergeSplit(copy.st, ench.st)   -- WL Helper change (v3)
    if ench.wdmg > 0 and (item.spd or 0) > 0 then
        copy.dps = (item.dps or 0) + ench.wdmg / item.spd
    end
    copy.enchant = ench
    return copy, ench
end

local function Zeros()
    local st = {}
    for k = 1, NUM_STATS do st[k] = 0 end
    return st
end

local function Dot(st, w)
    local s = 0
    for k = 1, NUM_STATS do
        if st[k] ~= 0 then s = s + st[k] * w[k] end
    end
    return s + SplitScore(st, w)   -- WL Helper change (v3)
end

------------------------------------------------------------------------
-- WL Helper change (v2): "Use:" and proc lines read from the tooltip, for items the
-- PROCS table doesn't know. "Use: Increases attack power by 200 for 20 sec. (2 Min
-- Cooldown)" counts as 200 x 20 / 120 x 0.8 attack power. A proc line that can't be
-- valued ("Chance on hit:") is reported in notes instead of silently scoring 0.
------------------------------------------------------------------------
local effectCache = {}
-- WL Helper change (v3): a link whose tooltip isn't loaded yet is not scanned again for a
-- second (every tooltip refresh calls Compare). Needs GetTime; without it, no wait.
local notReady = {}
local function RecentlyNotReady(link)
    local t = notReady[link]
    return t ~= nil and GetTime ~= nil and GetTime() - t < 1
end
local function MarkNotReady(link)
    if GetTime then notReady[link] = GetTime() end
end

-- WL Helper change (v3): cooldown in seconds from "(1 Min, 30 Sec Cooldown)", "(2 Min
-- Cooldown)", "(Recharge : 2 min)", "(Recharge : 1 min 30 s)", "(1 Hour Cooldown)".
local function Cooldown(use)
    local c = use:match("%(([^%)]*cooldown)%)") or use:match("%((recharge[^%)]*)%)")
    if not c then return nil end
    c = c .. " "
    local h = tonumber(c:match("(%d+)%s*hour") or c:match("(%d+)%s*heure") or c:match("(%d+)%s*h[%s,]") or "") or 0
    local m = tonumber(c:match("(%d+)%s*min") or "") or 0
    local s = tonumber(c:match("(%d+)%s*sec") or c:match("(%d+)%s*s[%s,]") or "") or 0
    local cd = h * 3600 + m * 60 + s
    return cd > 0 and cd or nil
end

local function TooltipEffects(link)
    local cached = effectCache[link]
    if cached ~= nil then return cached end
    if RecentlyNotReady(link) then return nil end
    local ok, lines = pcall(TooltipLines, link)
    if not ok or not TooltipReady(lines, 2) then MarkNotReady(link) return nil end
    local st, notes, any = Zeros(), {}, false
    for _, text in ipairs(lines) do
        -- WL Helper change (v3): "Utiliser :" with a no-break space, and French cooldowns.
        local t = NoNbsp(text):lower()
        local use = t:match("^use%s*:%s*(.+)") or t:match("^utiliser%s*:%s*(.+)")
        if use then
            local dur = tonumber(use:match("for (%d+) sec") or use:match("pendant (%d+) s") or "")
            local cd = Cooldown(use)
            local tmp = Zeros()
            if dur and cd and cd > 0 then ParseEnchantLine(use, tmp) end
            local sum = 0
            for k = 1, NUM_STATS do sum = sum + tmp[k] end
            if tmp.spell or tmp.melee then sum = sum + 1 end
            if sum > 0 then
                local f = math.min(1, dur / cd) * 0.8
                for k = 1, NUM_STATS do st[k] = st[k] + tmp[k] * f end
                MergeSplit(st, tmp, f)
                any = true
                notes[#notes + 1] = "use effect averaged over its cooldown"
            else
                notes[#notes + 1] = "use effect not scored"
            end
        elseif t:find("^chance on hit") or t:find("^chances quand vous touchez") or t:find("^chance on hit:")
            or (t:find("^equip:") and t:find("chance on")) or (t:find("^équipé") and t:find("chances")) then
            notes[#notes + 1] = "proc not counted"
        end
    end
    local result = { st = st, any = any, notes = notes }
    effectCache[link] = result
    return result
end

-- A copy of item ready for Compare/Score: its link, tooltip effects added. Returns
-- item, notes. Same item back in neutral mode.
local function Prepare(item, link)
    if opts.neutral or not item then return item, {} end
    local copy = setmetatable({}, getmetatable(item))
    for k, v in pairs(item) do copy[k] = v end
    copy.link = link
    local notes = {}
    local p = PROCS[item.id]
    if p then
        notes[#notes + 1] = "effect counted: " .. (p.note or "proc")
    elseif link then
        local fx = TooltipEffects(link)
        if fx then
            if fx.any then
                copy.st = {}
                for k = 1, NUM_STATS do copy.st[k] = (item.st[k] or 0) + fx.st[k] end
                MergeSplit(copy.st, item.st) MergeSplit(copy.st, fx.st)   -- WL Helper change (v3)
            end
            for _, n in ipairs(fx.notes) do notes[#notes + 1] = n end
        end
    end
    return copy, notes
end

-- Suffix ID of a random-suffix link (7th field), or nil.
local function SuffixID(link)
    if type(link) ~= "string" then return nil end
    local s = tonumber(link:match("item:%-?%d+:%-?%d*:%-?%d*:%-?%d*:%-?%d*:%-?%d*:(%-?%d*)") or "")
    if s and s ~= 0 then return s end
    return nil
end

------------------------------------------------------------------------
-- WL Helper change (v2): set bonuses in Compare. The set comes from GetItemInfo's
-- setID (16th return) and its bonuses from the tooltip's "(N) Set:" lines, read with the
-- enchant parser ("+50 Attack Power", "Increases your chance to hit by 2%" -> 20 hit).
-- Compare adds the bonuses a new item would complete and takes off the ones it would
-- break. Bonuses that aren't stats are named in notes, not scored.
------------------------------------------------------------------------
local setCache = {}
local function SetInfo(link)
    if type(link) ~= "string" or not GetInfo then return nil end
    local cached = setCache[link]
    if cached ~= nil then return cached or nil end
    if RecentlyNotReady(link) then return nil end
    -- WL Helper change (v3): "no set" is cached only once the item info is loaded (a name
    -- came back); before that, nil and ask again later.
    local ok, name, setID = pcall(function() local t = { GetInfo(link) } return t[1], t[16] end)
    setID = ok and Num(setID)
    if not setID or setID <= 0 then
        if ok and name ~= nil then setCache[link] = false else MarkNotReady(link) end
        return nil
    end
    local okL, lines = pcall(TooltipLines, link)
    if not okL or not TooltipReady(lines, 2) then MarkNotReady(link) return nil end
    local bonuses = {}
    for _, text in ipairs(lines) do
        local n, rest = text:match("^%((%d+)%)%s*[^:]+:%s*(.+)$")
        if n then
            local st = Zeros()
            ParseEnchantLine(rest, st)
            bonuses[#bonuses + 1] = { n = tonumber(n), st = st, text = rest }
        end
    end
    local info = { id = setID, bonuses = bonuses }
    setCache[link] = info
    return info
end

local wornSets   -- WL Helper change (v3): { time, before, infos, bySlot } of the last read
-- Score gained (new set bonuses) and lost (broken ones) when target replaces the items in
-- invSlots. Returns gain, lost, notes.
local function SetDelta(target, invSlots, w)
    local notes = {}
    if opts.neutral or not GetInventoryItemLink then return 0, 0, notes end
    -- WL Helper change (v3): the worn sets are read once per frame (one Compare calls this
    -- for each section), not 19 links per call. Without GetTime, every call.
    local now = GetTime and GetTime()
    local worn = now and wornSets and wornSets.time == now and wornSets
    if not worn then
        worn = { time = now, before = {}, infos = {}, bySlot = {} }
        for s = 1, 19 do
            local l = GetInventoryItemLink("player", s)
            local info = l and SetInfo(l)
            if info then
                worn.before[info.id] = (worn.before[info.id] or 0) + 1
                worn.infos[info.id], worn.bySlot[s] = info, info
            end
        end
        wornSets = worn
    end
    local before, infos, bySlot = worn.before, {}, worn.bySlot
    for id, info in pairs(worn.infos) do infos[id] = info end
    local after = {}
    for id, c in pairs(before) do after[id] = c end
    for _, s in ipairs(invSlots) do
        local info = bySlot[s]
        if info then after[info.id] = after[info.id] - 1 end
    end
    local ti = target.link and SetInfo(target.link)
    if ti then
        after[ti.id] = (after[ti.id] or 0) + 1
        infos[ti.id] = infos[ti.id] or ti
    end
    local gain, lost = 0, 0
    for id, info in pairs(infos) do
        local b, a = before[id] or 0, after[id] or 0
        for _, bonus in ipairs(info.bonuses) do
            local had, has = b >= bonus.n, a >= bonus.n
            if had ~= has then
                local v = Dot(bonus.st, w)
                if has then
                    gain = gain + v
                    notes[#notes + 1] = string.format("set bonus (%d) %s: +%.1f", bonus.n, bonus.text, v)
                else
                    lost = lost + v
                    notes[#notes + 1] = string.format("breaks set bonus (%d) %s: -%.1f", bonus.n, bonus.text, v)
                end
            end
        end
    end
    return gain, lost, notes
end

-- Score of what's in a character slot. 0 = empty, nil = can't read it.
-- WL Helper change: returns the link too, and counts the equipped item's enchant.
-- WL Helper change (beta.93): a slot is empty only when neither its item ID nor its link
-- nor its icon says otherwise; a worn item that can't be read (secret, no ID yet) is nil
-- ("unknown", retried), never an empty slot.
local function EquippedScore(invSlot, mh, oh, rg, slowBonus, w, prefer)
    local id = GetInventoryItemID("player", invSlot)
    local link = GetInventoryItemLink and GetInventoryItemLink("player", invSlot)
    if Secret(id) or Secret(link) then return nil end
    if type(link) ~= "string" then link = nil end
    if not id and link then id = tonumber(link:match("item:(%d+)")) end
    if not id then
        local tex = GetInventoryItemTexture and GetInventoryItemTexture("player", invSlot)
        if tex ~= nil and not Secret(tex) then return nil end
        return 0
    end
    -- an item ID but no link yet: a listed green or better with nothing but armor may carry a
    -- random suffix only its link shows, so it waits ("unknown", retried) rather than being read
    -- without its stats
    if not link and not opts.neutral then
        ns.Parse()
        local known = ns.byId[id]
        if known and (known.q or 0) >= 2 and NoStatsButArmor(known) then return nil end
    end
    local item = LiveItem(id, link)
    if not item then return nil end
    item = WithEnchant(item, link)
    item = Prepare(item, link)   -- WL Helper change (v2): use effects of what you wear
    local sec
    if invSlot == 17 then
        sec = (item.slot == 17) and SEC_SHIELD or SEC_OFFHAND
    else
        sec = SLOT_SECTIONS[item.slot][1]
    end
    local score = SectionScore(item, sec, BaseScore(item, w), mh, oh, rg, slowBonus, prefer)
    return score > 0 and score or 0, item, link
end

-- Upstream's Upgrade() returned tooltip text ("+24%"); WL Helper change: it returns data.
-- { pct, pctExact, old, new, invSlot, equippedLink, offLink, empty, equipped, blocked, unknown }
local function Upgrade(target, sec, newScore, mh, oh, rg, slowBonus, w, prefer)
    local r = { new = newScore }
    if not GetInventoryItemID then r.unknown = true return r end
    -- Something worth a little even when it has none of the spec's stats: its weapon
    -- damage (casters melee early on) and armor. Lets every comparison show a percent.
    local function Floor(item)
        return item and ((item.dps or 0) * 0.1 + (item.st[1] or 0) * 0.005) or 0
    end
    local old
    local neutral = opts.neutral
    r.notes = {}
    -- WL Helper change (v2): a worn item with no score (a use or proc trinket nothing can
    -- value) is not an empty slot. With two slots the weaker scored one is compared.
    local unscoredSlot, unscoredLink
    local allWorn = true   -- WL Helper change (beta.93): every compared slot holds an item
    for _, invSlot in ipairs(INV_SLOTS[sec]) do
        local score, item, link = EquippedScore(invSlot, mh, oh, rg, slowBonus, w, prefer)
        if not score then r.unknown = true return r end
        if not item then allWorn = false end
        -- WL Helper change (v2): same base item with another random suffix ("of the Bear" vs
        -- "of the Monkey") is a different item.
        if item and item.id == target.id and (neutral or not target.link or SuffixID(link) == SuffixID(target.link)) then
            r.equipped, r.invSlot, r.equippedLink, r.pct, r.pctExact, r.old = true, invSlot, link, 0, 0, score
            return r
        end
        if item and score <= 0 then score = Floor(item) end
        if not neutral and item and score <= 0 then
            unscoredSlot, unscoredLink = unscoredSlot or invSlot, unscoredLink or link
        -- Two ring and trinket slots: compare against the weaker one.
        elseif not old or score < old then
            old, r.invSlot, r.equippedLink = score, invSlot, link
            r.enchantNote = not neutral and item and item.enchant and item.enchant.note or nil
        end
    end
    if r.enchantNote then r.notes[#r.notes + 1] = "your enchant counted: " .. r.enchantNote end
    if not old then
        if unscoredSlot then
            r.unscored, r.invSlot, r.equippedLink, r.old = true, unscoredSlot, unscoredLink, 0
            r.notes[#r.notes + 1] = "the item you wear has an effect that isn't scored"
            return r
        end
        old = 0
    end
    local replaced = { r.invSlot }
    if sec == SEC_TWOHAND then
        -- A two-hander replaces both hands.
        local off, offItem, offLink = EquippedScore(17, mh, oh, rg, slowBonus, w, prefer)
        if not off then r.unknown = true return r end
        if offItem and off <= 0 then off = Floor(offItem) end
        old = old + off
        r.offLink = offLink
        replaced[2] = 17
    elseif sec == SEC_OFFHAND or sec == SEC_SHIELD then
        -- Can't use an off hand with a two-hander equipped.
        local mainID = GetInventoryItemID("player", 16)
        local main = mainID and LiveItem(mainID, GetInventoryItemLink("player", 16))
        if main and main.slot == 13 then r.blocked = "twohand" return r end
    end
    -- WL Helper change (v2): set bonuses the swap completes or breaks.
    if not neutral then
        local gain, lost, notes = SetDelta(target, replaced, w)
        newScore, old = newScore + gain, old + lost
        r.new, r.setGain, r.setLost = newScore, gain, lost
        for _, n in ipairs(notes) do r.notes[#r.notes + 1] = n end
    end
    r.old = old
    if old <= 0 then
        -- WL Helper change (beta.93): something is worn there, so it is not an empty slot:
        -- no percent rather than "empty slot" (neutral mode keeps Geared Forever's answer).
        if allWorn and r.invSlot and not neutral then
            r.unscored = true
            r.notes[#r.notes + 1] = "the item you wear has no score"
            return r
        end
        r.empty = true return r
    end
    r.pctExact = (newScore - old) / old * 100
    r.pct = math.floor(r.pctExact + 0.5)
    return r
end

-- Why the player can't use an item in a section, or true. Same rules as Usable(),
-- with the reason spelled out for the API.
local function CanUse(item, sec, cls, level)
    ReadPlayer()
    if item.cls and item.cls ~= 0 and bit.band(item.cls, cls.bit) == 0 then return "class" end
    if item.fac and item.fac ~= "" and playerFaction ~= "" and item.fac ~= playerFaction then return "faction" end
    if not Usable(item, sec, cls, MAX_LEVEL) then
        if sec == SEC_OFFHAND and (item.kind or 0) >= 10 and cls.weapons[item.kind] then return "dualwield" end
        return (ARMOR_SLOT[item.slot] and "armor") or (item.slot == 17 and "shield") or (item.slot == 19 and "relic") or "weapon"
    end
    if not Usable(item, sec, cls, level) then return "level40" end
    if item.lvl and item.lvl > level and not item.noreq and not item.est then return "level" end
    return true
end

-- WL Helper change: the engine's pieces for Api.lua (no globals).
ns.engine = {
    MAX_LEVEL = MAX_LEVEL, NUM_STATS = NUM_STATS, STAT = STAT, SECTIONS = SECTIONS, KIND_NAME = KIND_NAME,
    SLOT_SECTIONS = SLOT_SECTIONS, INV_SLOTS = INV_SLOTS, EQUIP_SLOT = EQUIP_SLOT, CLASS_BY_TOKEN = CLASS_BY_TOKEN,
    SEC_TWOHAND = SEC_TWOHAND, SEC_MAINHAND = SEC_MAINHAND, SEC_OFFHAND = SEC_OFFHAND, SEC_SHIELD = SEC_SHIELD,
    SEC_RANGED = SEC_RANGED, ARMOR_SLOT = ARMOR_SLOT,
    Clamp = Clamp, FindSpec = FindSpec, Weights = Weights, BaseScore = BaseScore, SectionScore = SectionScore,
    Usable = Usable, CanUse = CanUse, Lighter = Lighter, LiveItem = LiveItem, Upgrade = Upgrade, EquippedScore = EquippedScore,
    EnchantStats = EnchantStats, WithEnchant = WithEnchant, ParseEnchantLine = ParseEnchantLine,
    ScanTalents = ScanTalents, ClearTalentCache = ClearTalentCache, OwnedHit = OwnedHit,
    -- WL Helper change (v2)
    PROCS = PROCS, ENCHANT_IDS = ENCHANT_IDS, Prepare = Prepare, SetInfo = SetInfo, SetDelta = SetDelta,
    TooltipEffects = TooltipEffects, HitCap = HitCap, OwnedDefense = OwnedDefense,
    SetDefenseOverride = function(t) defOverride = t end,
    Options = function() return opts end,
    SetOptions = function(t)
        if type(t) ~= "table" then return end
        if t.neutral ~= nil then opts.neutral = t.neutral == true end
        if t.raidAuto then opts.raid = nil elseif t.raid ~= nil then opts.raid = t.raid == true end
        -- WL Helper change (1.4.0)
        if t.wand ~= nil then opts.wand = tonumber(t.wand) or 1 end
        if t.lighter ~= nil then opts.lighter = t.lighter == true end
        for k in pairs(enchantCache) do enchantCache[k] = nil end
        for k in pairs(effectCache) do effectCache[k] = nil end
        for k in pairs(setCache) do setCache[k] = nil end
        for k in pairs(notReady) do notReady[k] = nil end
        wornSets = nil
    end,
    ReadPlayer = ReadPlayer, Parse = ns.Parse, Rank = ns.Rank,
    QuestRewards = QuestRewards, RewardName = RewardName,   -- WL Helper change (v4)
    PlayerClassToken = function() ReadPlayer() return playerClassToken end,
    PlayerRace = function() ReadPlayer() return playerRace end,
    SetHitOverride = function(t) hitOverride = t end,
    GetHitOverride = function() return hitOverride end,
    -- ClearCaches(false): talents only. ClearCaches("items"): items and enchants only.
    -- ClearCaches(true): everything.
    ClearCaches = function(all)
        if all ~= "items" then talentCache = nil end
        if all then
            for k in pairs(enchantCache) do enchantCache[k] = nil end
            for k in pairs(liveCache) do liveCache[k] = nil end
            -- WL Helper change (v2): tooltip effects and set bonuses are read again too.
            for k in pairs(effectCache) do effectCache[k] = nil end
            for k in pairs(setCache) do setCache[k] = nil end
            for k in pairs(notReady) do notReady[k] = nil end   -- WL Helper change (v3)
            for k in pairs(suffixMemo) do suffixMemo[k] = nil end   -- WL Helper change (beta.93)
            wornSets = nil
        end
    end,
}
