-- Writs/Weights.lua: WL Helper's own stat weights, and the score of an item for your spec.
--
-- One table per class and spec, written for levelling and dungeons in Classic (values relative to the
-- spec's main stat = 1; a % of crit or hit is worth about a dozen points of it). The spec is the
-- talent tree with the most points, or the one picked in Settings > Upgrades. An item's score is the sum
-- of its stats times their weights, plus the weapon's damage per second for the slots that use it;
-- the gain is its score against what you wear in the same slot (the weaker of two rings or trinkets).
local ADDON, root = ...
root.Writs = root.Writs or {}
local ns = root.Writs
local WP = ns.WP
local L = ns.L

local W = {}
WP.Weights = W

-- the client's stat keys (GetItemStats) -> short codes
local KEYS = {
    ITEM_MOD_STRENGTH_SHORT = "STR", ITEM_MOD_AGILITY_SHORT = "AGI", ITEM_MOD_STAMINA_SHORT = "STA",
    ITEM_MOD_INTELLECT_SHORT = "INT", ITEM_MOD_SPIRIT_SHORT = "SPI", RESISTANCE0_NAME = "ARMOR",
    ITEM_MOD_ATTACK_POWER_SHORT = "AP", ITEM_MOD_RANGED_ATTACK_POWER_SHORT = "RAP",
    ITEM_MOD_SPELL_POWER_SHORT = "SP", ITEM_MOD_SPELL_DAMAGE_DONE_SHORT = "SP", ITEM_MOD_SPELL_HEALING_DONE_SHORT = "HEAL",
    ITEM_MOD_CRIT_RATING_SHORT = "CRIT", ITEM_MOD_CRIT_MELEE_RATING_SHORT = "CRIT", ITEM_MOD_CRIT_RANGED_RATING_SHORT = "CRIT",
    ITEM_MOD_CRIT_SPELL_RATING_SHORT = "SCRIT",
    ITEM_MOD_HIT_RATING_SHORT = "HIT", ITEM_MOD_HIT_MELEE_RATING_SHORT = "HIT", ITEM_MOD_HIT_RANGED_RATING_SHORT = "HIT",
    ITEM_MOD_HIT_SPELL_RATING_SHORT = "SHIT",
    ITEM_MOD_MANA_REGENERATION_SHORT = "MP5", ITEM_MOD_POWER_REGEN0_SHORT = "MP5",
    ITEM_MOD_DEFENSE_SKILL_RATING_SHORT = "DEF", ITEM_MOD_DODGE_RATING_SHORT = "DODGE", ITEM_MOD_PARRY_RATING_SHORT = "PARRY",
    ITEM_MOD_BLOCK_RATING_SHORT = "BLOCK", ITEM_MOD_BLOCK_VALUE_SHORT = "BLOCKV",
    ITEM_MOD_DAMAGE_PER_SECOND_SHORT = "DPS",
}

-- [class] = { { key, French, English, weights }, ... } in talent tab order
local MELEE_DPS = { STR = 1, AGI = 0.7, STA = 0.35, AP = 0.5, CRIT = 12, HIT = 12, ARMOR = 0.01, DPS = 5 }
local CASTER = { SP = 1, INT = 0.55, SPI = 0.3, STA = 0.3, SCRIT = 10, SHIT = 12, MP5 = 1.2, ARMOR = 0.005, DPS = 1 }
local HEALER = { INT = 1, HEAL = 0.9, SP = 0.8, SPI = 0.5, MP5 = 2, STA = 0.3, SCRIT = 8, ARMOR = 0.005, DPS = 0.5 }
local TANK = { STA = 1, ARMOR = 0.05, DEF = 1.2, DODGE = 12, PARRY = 10, BLOCK = 6, BLOCKV = 0.4, STR = 0.6, AGI = 0.6, HIT = 6, AP = 0.2, DPS = 2 }
local function With(base, extra)
    local t = {}
    for k, v in pairs(base) do t[k] = v end
    for k, v in pairs(extra or {}) do t[k] = v end
    return t
end
local SPECS = {
    WARRIOR = { { "arms", "Armes", "Arms", MELEE_DPS }, { "fury", "Fureur", "Fury", MELEE_DPS }, { "prot", "Protection", "Protection", TANK } },
    PALADIN = { { "holy", "Sacré", "Holy", HEALER }, { "prot", "Protection", "Protection", With(TANK, { INT = 0.3, SP = 0.4 }) },
        { "ret", "Vindicte", "Retribution", With(MELEE_DPS, { AGI = 0.6, INT = 0.25, SP = 0.3, CRIT = 11, HIT = 11 }) } },
    HUNTER = (function()
        local h = { AGI = 1, RAP = 0.45, AP = 0.4, INT = 0.3, STA = 0.3, SPI = 0.1, CRIT = 13, HIT = 13, ARMOR = 0.005, DPS = 4 }
        return { { "bm", "Maîtrise des bêtes", "Beast Mastery", h }, { "mm", "Précision", "Marksmanship", h }, { "surv", "Survie", "Survival", h } }
    end)(),
    ROGUE = (function()
        local r = { AGI = 1, STR = 0.55, AP = 0.5, CRIT = 12, HIT = 14, STA = 0.3, ARMOR = 0.005, DPS = 5 }
        return { { "assa", "Assassinat", "Assassination", r }, { "combat", "Combat", "Combat", r }, { "sub", "Finesse", "Subtlety", r } }
    end)(),
    PRIEST = { { "disc", "Discipline", "Discipline", HEALER }, { "holy", "Sacré", "Holy", HEALER },
        { "shadow", "Ombre", "Shadow", With(CASTER, { INT = 0.5, SPI = 0.4, STA = 0.35, SCRIT = 8, MP5 = 1 }) } },
    SHAMAN = { { "ele", "Élémentaire", "Elemental", CASTER },
        { "enh", "Amélioration", "Enhancement", With(MELEE_DPS, { INT = 0.3, SP = 0.2 }) },
        { "resto", "Restauration", "Restoration", With(HEALER, { MP5 = 2.2, SPI = 0.3 }) } },
    MAGE = { { "arcane", "Arcanes", "Arcane", CASTER }, { "fire", "Feu", "Fire", CASTER }, { "frost", "Givre", "Frost", CASTER } },
    WARLOCK = (function()
        local w = With(CASTER, { STA = 0.45, INT = 0.4, SCRIT = 7, MP5 = 0.8 })
        return { { "aff", "Affliction", "Affliction", w }, { "demo", "Démonologie", "Demonology", w }, { "destro", "Destruction", "Destruction", w } }
    end)(),
    DRUID = { { "balance", "Équilibre", "Balance", With(CASTER, { SPI = 0.35, SCRIT = 9, SHIT = 11 }) },
        { "feral", "Combat farouche", "Feral", { AGI = 1, STR = 0.9, AP = 0.45, CRIT = 12, HIT = 12, STA = 0.35, ARMOR = 0.02 } },
        { "resto", "Restauration", "Restoration", With(HEALER, { SPI = 0.6 }) } },
}
W.SPECS = SPECS

local function Class() local _, c = UnitClass("player"); return c end
local function French() return (root.lang == "fr") or (GetLocale and GetLocale() == "frFR" and root.lang ~= "en") end

-- Points spent per talent tree through the modern talent system (Forever: C_ClassTalents +
-- C_Traits, no GetTalentTabInfo). Several trees in the config: one per tab. A single tree: its
-- nodes are split into three columns by their position, left to right like the old tabs.
local function Num(v) return type(v) == "number" and not (issecretvalue and issecretvalue(v)) and v or nil end
local function TraitsPoints()
    if not (C_ClassTalents and C_ClassTalents.GetActiveConfigID and C_Traits and C_Traits.GetConfigInfo
        and C_Traits.GetTreeNodes and C_Traits.GetNodeInfo) then return nil end
    local ok, cfg = pcall(C_ClassTalents.GetActiveConfigID)
    if not ok or not Num(cfg) then return nil end
    local okI, info = pcall(C_Traits.GetConfigInfo, cfg)
    local trees = okI and type(info) == "table" and info.treeIDs
    if type(trees) ~= "table" or #trees == 0 then return nil end
    local function Nodes(tid)
        local okN, nodes = pcall(C_Traits.GetTreeNodes, tid)
        local out = {}
        if okN and type(nodes) == "table" then
            for _, nid in ipairs(nodes) do
                local okD, ni = pcall(C_Traits.GetNodeInfo, cfg, nid)
                if okD and type(ni) == "table" then
                    local r = Num(ni.ranksPurchased) or Num(ni.currentRank) or 0
                    out[#out + 1] = { r = r, x = Num(ni.posX) }
                end
            end
        end
        return out
    end
    local pts = {}
    if #trees >= 2 then
        for i, tid in ipairs(trees) do
            local sum = 0
            for _, n in ipairs(Nodes(tid)) do sum = sum + n.r end
            pts[i] = sum
        end
        return pts
    end
    local nodes = Nodes(trees[1])
    local lo, hi
    for _, n in ipairs(nodes) do if n.x then lo = math.min(lo or n.x, n.x); hi = math.max(hi or n.x, n.x) end end
    if not (lo and hi) or hi <= lo then return nil end
    pts = { 0, 0, 0 }
    for _, n in ipairs(nodes) do
        if n.x and n.r > 0 then
            local band = math.min(3, math.floor((n.x - lo) / (hi - lo + 1) * 3) + 1)
            pts[band] = pts[band] + n.r
        end
    end
    return pts
end

-- talent tab with the most points; the first damage spec before level 10
local function TalentSpec(class)
    local best, bestPts = nil, 0
    local tp = TraitsPoints()
    if tp then
        for i = 1, 3 do if (tp[i] or 0) > bestPts then best, bestPts = i, tp[i] end end
    end
    if not best and GetTalentTabInfo then
        for i = 1, 3 do
            local r = { pcall(GetTalentTabInfo, i) }
            if r[1] then
                local pts = (type(r[6]) == "number" and r[6]) or (type(r[4]) == "number" and r[4]) or 0
                if pts > bestPts then best, bestPts = i, pts end
            end
        end
    end
    if best then W.guessed = false; return best end
    -- this client may not give the talent trees (Forever: no GetNumTalentTabs, and the modern
    -- specialization answers 1 whatever the talents): a default, flagged so the player is asked
    W.guessed = true
    local default = { WARRIOR = 1, PALADIN = 3, HUNTER = 2, ROGUE = 2, PRIEST = 3, SHAMAN = 2, MAGE = 3, WARLOCK = 1, DRUID = 2 }
    return default[class] or 1
end

function W.Spec()
    local class = Class()
    local list = SPECS[class]
    if not list then return nil end
    local pick = WLWritsDB and WLWritsDB.upgradeSpec and WLWritsDB.upgradeSpec[class]
    if pick and pick ~= "auto" then
        for _, s in ipairs(list) do if s[1] == pick then W.guessed = false; return s end end
    end
    return list[TalentSpec(class)] or list[1]
end
-- true when the spec is a default (talents not readable and no choice made in the settings)
function W.SpecGuessed() W.Spec(); return W.guessed == true end
function W.SpecName(s)
    s = s or W.Spec()
    if not s then return "" end
    return French() and s[2] or s[3]
end
-- a spec name written by another addon ("frost", "Beast Mastery") in your language when it is one of
-- your class's specs; any other text is given back as is
function W.SpecNameFor(text)
    if type(text) ~= "string" or text == "" then return W.SpecName() end
    local norm = (text:lower():gsub("[%s%-_]", ""))
    for _, s in ipairs(SPECS[Class()] or {}) do
        if s[1] == norm or (s[3]:lower():gsub("[%s%-_]", "")) == norm then return W.SpecName(s) end
    end
    return text
end
-- the key ("frost", "prot") of one of your class's specs written by another addon ("Frost",
-- "Protection", "affli"), or nil
function W.SpecKeyFor(text)
    if type(text) ~= "string" or text == "" then return nil end
    local function N(x) return (x:lower():gsub("[%s%-_]", "")) end
    local norm = N(text)
    local list = SPECS[Class()] or {}
    for _, s in ipairs(list) do
        if s[1] == norm or N(s[3]) == norm or N(s[2]) == norm then return s[1] end
    end
    -- a shortened or longer key ("affli" for "aff"): the start of the name
    for _, s in ipairs(list) do
        if #norm >= 3 and (N(s[3]):sub(1, #norm) == norm or norm:sub(1, #s[1]) == s[1]) then return s[1] end
    end
    return nil
end
-- ---------------------------------------------------------------- several specs (dual or triple spec)
-- Settings > Upgrades > Specs to compare: the main spec (above) is always judged, first; the other
-- specs of the class ticked there are judged too. Saved per class: WLWritsDB.upgradeExtra[class][key].
function W.SpecByKey(key)
    for _, s in ipairs(SPECS[Class()] or {}) do if s[1] == key then return s end end
    return nil
end
local function ExtraDB(create)
    if not WLWritsDB then return nil end
    local class = Class()
    if create then
        WLWritsDB.upgradeExtra = WLWritsDB.upgradeExtra or {}
        WLWritsDB.upgradeExtra[class] = WLWritsDB.upgradeExtra[class] or {}
    end
    return WLWritsDB.upgradeExtra and WLWritsDB.upgradeExtra[class]
end
function W.ExtraOn(key) local db = ExtraDB(); return db and db[key] == true or false end
function W.SetExtra(key, on)
    local db = ExtraDB(true)
    if db then db[key] = on and true or nil end
end
-- the specs judged: { main, extra... } (class order for the extras, the main spec never twice)
function W.CompareSpecs()
    local main = W.Spec()
    if not main then return {} end
    local out = { main }
    for _, s in ipairs(SPECS[Class()] or {}) do
        if s ~= main and W.ExtraOn(s[1]) then out[#out + 1] = s end
    end
    return out
end
-- true when at least one extra spec is ticked (the tooltip then shows one line per spec)
function W.MultiSpec() return #W.CompareSpecs() > 1 end
-- the class's specs other than the main one: { spec, ... } (the settings' check list)
function W.OtherSpecs()
    local main = W.Spec()
    local out = {}
    for _, s in ipairs(SPECS[Class()] or {}) do if s ~= main then out[#out + 1] = s end end
    return out
end

-- { { "auto", label }, { key, label }... } for a segmented choice
function W.SpecChoices()
    local out = { { "auto", L("Auto") } }
    for _, s in ipairs(SPECS[Class()] or {}) do out[#out + 1] = { s[1], French() and s[2] or s[3] } end
    return out
end

-- ---------------------------------------------------------------- who can wear what
local ARMOR_OK = {   -- [class] = { [armor subclass] = from level }
    WARRIOR = { [1] = 1, [2] = 1, [3] = 1, [4] = 40, [6] = 1 }, PALADIN = { [1] = 1, [2] = 1, [3] = 1, [4] = 40, [6] = 1, [7] = 1 },
    HUNTER = { [1] = 1, [2] = 1, [3] = 40 }, ROGUE = { [1] = 1, [2] = 1 }, PRIEST = { [1] = 1 },
    SHAMAN = { [1] = 1, [2] = 1, [3] = 40, [6] = 1, [9] = 1 }, MAGE = { [1] = 1 }, WARLOCK = { [1] = 1 },
    DRUID = { [1] = 1, [2] = 1, [8] = 1 },
}
-- weapon subclasses: 0 axe, 1 2h axe, 2 bow, 3 gun, 4 mace, 5 2h mace, 6 polearm, 7 sword, 8 2h sword,
-- 10 staff, 13 fist, 15 dagger, 16 thrown, 18 crossbow, 19 wand
local function Set(...) local t = {}; for _, v in ipairs({ ... }) do t[v] = true end; return t end
local WEAPON_OK = {
    WARRIOR = Set(0, 1, 2, 3, 4, 5, 6, 7, 8, 10, 13, 15, 16, 18), PALADIN = Set(0, 1, 4, 5, 6, 7, 8),
    HUNTER = Set(0, 1, 2, 3, 6, 7, 8, 10, 13, 15, 16, 18), ROGUE = Set(2, 3, 4, 7, 13, 15, 16, 18),
    PRIEST = Set(4, 10, 15, 19), SHAMAN = Set(0, 1, 4, 5, 10, 13, 15), MAGE = Set(7, 10, 15, 19),
    WARLOCK = Set(7, 10, 15, 19), DRUID = Set(4, 5, 10, 13, 15),
}
local DUAL = { WARRIOR = 20, ROGUE = 10, HUNTER = 20 }   -- dual wield from this level

-- inventory type -> slots it goes in
local SLOTS = {
    INVTYPE_HEAD = { 1 }, INVTYPE_NECK = { 2 }, INVTYPE_SHOULDER = { 3 }, INVTYPE_CHEST = { 5 }, INVTYPE_ROBE = { 5 },
    INVTYPE_WAIST = { 6 }, INVTYPE_LEGS = { 7 }, INVTYPE_FEET = { 8 }, INVTYPE_WRIST = { 9 }, INVTYPE_HAND = { 10 },
    INVTYPE_FINGER = { 11, 12 }, INVTYPE_TRINKET = { 13, 14 }, INVTYPE_CLOAK = { 15 },
    INVTYPE_WEAPON = { 16 }, INVTYPE_2HWEAPON = { 16 }, INVTYPE_WEAPONMAINHAND = { 16 },
    INVTYPE_WEAPONOFFHAND = { 17 }, INVTYPE_SHIELD = { 17 }, INVTYPE_HOLDABLE = { 17 },
    INVTYPE_RANGED = { 18 }, INVTYPE_RANGEDRIGHT = { 18 }, INVTYPE_THROWN = { 18 }, INVTYPE_RELIC = { 18 },
}
W.SLOTS = SLOTS

local function Info(link)
    local GetInfo = (C_Item and C_Item.GetItemInfo) or GetItemInfo
    local name, _, _, _, minLevel, _, _, _, equipLoc, _, _, classID, subID = GetInfo(link)
    return name, minLevel, equipLoc, classID, subID
end

-- false when your class can't use it; false, "level", N when only your level stops you (N: the
-- level it can be worn from); nil when the item is not loaded yet
function W.CanWear(link)
    local name, minLevel, equipLoc, classID, subID = Info(link)
    if not name then return nil end
    if not SLOTS[equipLoc] then return false end
    local class, level = Class(), UnitLevel("player")
    local need = minLevel or 0
    if classID == 4 then
        -- rings, necks, trinkets and cloaks: anyone
        if not (subID == 0 or equipLoc == "INVTYPE_CLOAK") then
            local from = ARMOR_OK[class] and ARMOR_OK[class][subID]
            if from == nil then return false end
            need = math.max(need, from)
        end
    elseif classID == 2 then
        if not (WEAPON_OK[class] and WEAPON_OK[class][subID]) then return false end
        if equipLoc == "INVTYPE_WEAPONOFFHAND" then
            if DUAL[class] == nil then return false end
            need = math.max(need, DUAL[class])
        end
    else
        return false
    end
    if need > (level or 0) then return false, "level", need end
    return true
end

-- ---------------------------------------------------------------- scores
local scoreCache = {}
local function Stats(link)
    local get = (C_Item and C_Item.GetItemStats) or GetItemStats
    local ok, t = pcall(get, link)
    return ok and type(t) == "table" and t or {}
end

-- ---------------------------------------------------------------- one school's spell damage
-- "+24 Frost spell damage" is not among the stats the client gives addons: it is read from the
-- item's "Equip:" lines (English and French clients), once per item.
local SCHOOL_WORD = {
    frost = "frost", givre = "frost", fire = "fire", feu = "fire", arcane = "arcane", arcanes = "arcane",
    shadow = "shadow", ombre = "shadow", nature = "nature", holy = "holy", ["sacré"] = "holy",
}
-- the share of a spec's spell damage that each school is worth
local SCHOOL_SHARE = {
    MAGE = { arcane = { arcane = 1, frost = 0.3, fire = 0.3 }, fire = { fire = 1, arcane = 0.2 }, frost = { frost = 1, arcane = 0.2 } },
    WARLOCK = { aff = { shadow = 1, fire = 0.2 }, demo = { shadow = 1, fire = 0.3 }, destro = { shadow = 0.8, fire = 0.6 } },
    PRIEST = { shadow = { shadow = 1 }, disc = { holy = 0.3 }, holy = { holy = 0.5 } },
    SHAMAN = { ele = { nature = 1, fire = 0.35, frost = 0.2 }, enh = { nature = 0.3, fire = 0.2 } },
    DRUID = { balance = { nature = 0.7, arcane = 0.5 } },
    PALADIN = { holy = { holy = 0.3 }, ret = { holy = 0.3 } },
}
local schoolCache = {}
local scan
local function SchoolDamage(link)
    local c = schoolCache[link]
    if c then return c end
    c = {}
    if not scan then scan = CreateFrame("GameTooltip", "WLHelperWeightsTip", nil, "GameTooltipTemplate") end
    scan:SetOwner(WorldFrame, "ANCHOR_NONE")
    scan:ClearLines()
    if pcall(scan.SetHyperlink, scan, link) then
        for i = 2, scan:NumLines() do
            local fs = _G["WLHelperWeightsTipTextLeft" .. i]
            local t = fs and fs:GetText()
            -- the weapon's speed is on the right of its damage line
            local rs = _G["WLHelperWeightsTipTextRight" .. i]
            local rt = rs and rs:GetText()
            if rt then
                local sp = rt:lower():match("(%d+[%.,]%d+)")
                if sp and (rt:lower():find("speed", 1, true) or rt:lower():find("vitesse", 1, true)) then c.speed = tonumber((sp:gsub(",", "."))) end
            end
            if t then
                t = t:lower()
                -- "increases damage done by frost spells and effects by up to 24"
                local w, n = t:match("damage done by (%a+) spells and effects by up to (%d+)")
                -- "augmente les dégâts infligés par les sorts et effets de givre de 24 au maximum"
                if not w then w, n = t:match("sorts et effets d[e']%s*(%S+) de (%d+)") end
                local school = w and SCHOOL_WORD[w]
                if school then c[school] = (c[school] or 0) + tonumber(n) end
                -- "Speed 2.70" / "Vitesse 2,70": the weapon's speed
                local sp = t:match("^speed%s+(%d+[%.,]%d+)") or t:match("^vitesse%s+(%d+[%.,]%d+)")
                    or t:match("%s+speed%s+(%d+[%.,]%d+)") or t:match("%s+vitesse%s+(%d+[%.,]%d+)")
                if sp then c.speed = tonumber((sp:gsub(",", "."))) end
            end
        end
    end
    scan:Hide()
    schoolCache[link] = c
    return c
end

-- ---------------------------------------------------------------- by level
-- What a stat is worth changes while levelling: spell damage counts less early (small spells, short
-- fights), Intellect, Spirit and Stamina more (drinking and resting time), the weapon more, hit little
-- (low-level mobs rarely resist); at 60, hit counts most. Four brackets, a multiplier per stat.
local BRACKETS = {
    { to = 20, label = "1-20" }, { to = 40, label = "21-40" }, { to = 59, label = "41-59" }, { to = 60, label = "60" },
}
local LEVEL_MULT = {        -- [stat] = { 1-20, 21-40, 41-59, 60 }
    SP = { 0.5, 0.75, 0.9, 1 }, HEAL = { 0.5, 0.75, 0.9, 1 },
    INT = { 1.3, 1.15, 1, 0.95 }, SPI = { 1.5, 1.3, 1, 0.8 }, STA = { 1.3, 1.15, 1, 1 },
    HIT = { 0.5, 0.7, 0.85, 1.2 }, SHIT = { 0.5, 0.7, 0.85, 1.2 },
    CRIT = { 0.8, 0.9, 1, 1 }, SCRIT = { 0.8, 0.9, 1, 1 },
    DPS = { 1.4, 1.25, 1.1, 1 }, MP5 = { 0.7, 0.85, 1, 1.1 }, ARMOR = { 1.5, 1.2, 1, 1 },
}
local function Bracket(level)
    level = level or UnitLevel("player") or 60
    for i, b in ipairs(BRACKETS) do if level <= b.to then return i, b.label end end
    return #BRACKETS, BRACKETS[#BRACKETS].label
end
W.Bracket = Bracket
-- a stat's weight for this spec at your level
function W.WeightOf(spec, code)
    local base = spec and spec[4][code]
    if not base then return nil end
    local m = LEVEL_MULT[code]
    return base * (m and m[(Bracket())] or 1)
end
-- the stats a spec weighs, heaviest first: { { code, weight }, ... } (for the settings page)
function W.Table(spec)
    spec = spec or W.Spec()
    local t = {}
    for code in pairs(spec and spec[4] or {}) do t[#t + 1] = { code, W.WeightOf(spec, code) } end
    table.sort(t, function(a, b) return a[2] > b[2] end)
    return t
end

-- ---------------------------------------------------------------- the wand, as much as you use it
-- Settings > Upgrades > "I use my wand": often (default), sometimes, never. The wand's DPS counts
-- in full, half or a tenth (a better wand stays a little better). Only the wand classes.
local WAND_CLASSES = { MAGE = true, PRIEST = true, WARLOCK = true }
local WAND_FACTOR = { often = 1, sometimes = 0.5, never = 0.1 }
W.WAND_FACTOR = WAND_FACTOR
W.WAND_AUTO_LEVEL = 40
function W.WandClass() return WAND_CLASSES[Class()] == true end
-- true when no choice was made in Settings: the automatic one applies (often below level 40,
-- sometimes from 40, when your spells matter more); a choice made in Settings always wins
function W.WandAuto()
    local v = WLWritsDB and WLWritsDB.upgradeWand
    return not WAND_FACTOR[v]
end
-- "often", "sometimes" or "never" (the automatic one at your level when none was chosen)
function W.WandUse(level)
    local v = WLWritsDB and WLWritsDB.upgradeWand
    if WAND_FACTOR[v] then return v end
    level = level or UnitLevel("player") or 0
    return level < W.WAND_AUTO_LEVEL and "often" or "sometimes"
end
function W.WandFactor()
    if not W.WandClass() then return 1 end
    return WAND_FACTOR[W.WandUse()]
end

-- ---------------------------------------------------------------- lighter armor (T-88)
-- Settings > Upgrades > "Ignore armor lighter than mine (from level 40)", on by default: from 40,
-- a shaman or hunter gets no % for leather or cloth, a warrior or paladin for mail, leather or
-- cloth, a druid or rogue for cloth. Armor slots only (not cloaks, rings, shields).
local ARMOR_TOP = { WARRIOR = 4, PALADIN = 4, HUNTER = 3, SHAMAN = 3, DRUID = 2, ROGUE = 2 }
local ARMOR_LOCS = {
    INVTYPE_HEAD = true, INVTYPE_SHOULDER = true, INVTYPE_CHEST = true, INVTYPE_ROBE = true, INVTYPE_WAIST = true,
    INVTYPE_LEGS = true, INVTYPE_FEET = true, INVTYPE_WRIST = true, INVTYPE_HAND = true,
}
function W.LighterOn() return not (WLWritsDB and WLWritsDB.upgradeLighter == false) end
-- true when the item is armor lighter than yours and the setting ignores it; nil when not loaded
function W.Lighter(link, level)
    if not W.LighterOn() or type(link) ~= "string" then return false end
    level = level or UnitLevel("player") or 0
    if level < 40 then return false end
    local top = ARMOR_TOP[Class()]
    if not top then return false end
    local name, _, equipLoc, classID, subID = Info(link)
    if not name then
        local Instant = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
        if not Instant then return nil end
        local _, _, _, loc, _, cid, sid = Instant(link)
        if not loc then return nil end
        equipLoc, classID, subID = loc, cid, sid
    end
    return classID == 4 and ARMOR_LOCS[equipLoc or ""] == true and type(subID) == "number"
        and subID >= 1 and subID <= 4 and subID < top or false
end

-- the parts of an item's score in a slot for a spec: { [code] = { amount, score } } (code: one of
-- KEYS' codes, a school "frost"..., "DPS"), and the score
local function Parts(link, slot, spec)
    local w = spec[4]
    local parts, s = {}, 0
    local function add(code, amount, v)
        local p = parts[code]
        if not p then p = { 0, 0 }; parts[code] = p end
        p[1], p[2] = p[1] + amount, p[2] + v
        s = s + v
    end
    for k, v in pairs(Stats(link)) do
        local code = KEYS[k]
        if code and code ~= "DPS" and w[code] and type(v) == "number" then add(code, v, W.WeightOf(spec, code) * v) end
    end
    -- one school's spell damage, worth the spec's spell damage times the school's share
    local shares = SCHOOL_SHARE[Class()] and SCHOOL_SHARE[Class()][spec[1]]
    if shares and w.SP then
        for school, n in pairs(SchoolDamage(link)) do
            if shares[school] then add(school, n, W.WeightOf(spec, "SP") * shares[school] * n) end
        end
    end
    -- weapon damage per second: main hand and ranged in full, off hand half
    local dps = Stats(link).ITEM_MOD_DAMAGE_PER_SECOND_SHORT
    if dps and w.DPS then
        local f = (slot == 17 and 0.5) or 1
        if slot == 18 and Class() ~= "HUNTER" and not (spec[4] == CASTER or w.SP) then f = 0.3 end
        -- a wand: as much as you use it
        if slot == 18 then
            local _, _, _, classID, subID = Info(link)
            if classID == 2 and subID == 19 then f = f * W.WandFactor() end
        end
        -- the speed, for melee: a slow main hand hits harder with each special attack (Sinister
        -- Strike, Mortal Strike, Seal of Command, Windfury), a fast off hand lands more hits and
        -- poisons; in Classic special attacks use the weapon's own swing, not a normalized one
        local speed = SchoolDamage(link).speed
        if speed and w.DPS >= 4 and Class() ~= "HUNTER" then
            if slot == 16 then f = f * math.max(0.8, math.min(1.3, 1 + 0.15 * (speed - 2.4)))
            elseif slot == 17 then f = f * math.max(0.8, math.min(1.3, 1 + 0.2 * (1.9 - speed))) end
        end
        add("DPS", dps, W.WeightOf(spec, "DPS") * dps * f)
    end
    return parts, s
end

-- the item's score in a slot for a spec
function W.Score(link, slot, spec)
    spec = spec or W.Spec()
    if not (link and spec) then return 0 end
    local key = link .. "|" .. (slot or 0) .. "|" .. spec[1] .. "|" .. (Bracket()) .. "|" .. W.WandFactor()
    if scoreCache[key] then return scoreCache[key] end
    local _, s = Parts(link, slot, spec)
    scoreCache[key] = s
    return s
end

local function Equipped(slot) return GetInventoryItemLink("player", slot) end
-- true when something is worn in the slot although its link or its data can't be read now (secret
-- value, not loaded yet): the slot is not empty, the gain waits ("pending")
local function WornUnread(slot, cur)
    local function secret(v) return issecretvalue ~= nil and issecretvalue(v) == true end
    if cur ~= nil and (secret(cur) or type(cur) ~= "string") then return true end
    if cur then return Info(cur) == nil end
    return (GetInventoryItemID and GetInventoryItemID("player", slot)) ~= nil
end

-- Gain of an item against what you wear: percent (number), "empty" for an empty slot, "pending" when
-- something is worn there but can't be read yet (its data is asked for: GET_ITEM_INFO_RECEIVED);
-- nil when it is not for you / not better. Second value: the slot compared. spec: one of W.SPECS
-- (default: the main spec).
function W.Gain(link, spec)
    spec = spec or W.Spec()
    if not spec then return nil end
    local can = W.CanWear(link)
    if not can then return nil end
    local _, _, equipLoc = Info(link)
    local slots = SLOTS[equipLoc]
    if equipLoc == "INVTYPE_WEAPON" and DUAL[Class()] and UnitLevel("player") >= DUAL[Class()] then slots = { 16, 17 } end
    -- a two-hander in the main hand blocks the off hand: slot 17 is not an empty slot then
    local mh = Equipped(16)
    local mhLoc = mh and select(3, Info(mh))
    local twoHanded = mhLoc == "INVTYPE_2HWEAPON"
    local bestGain, bestSlot, waitSlot
    for _, slot in ipairs(slots) do
        if not (slot == 17 and twoHanded) then
            local new = W.Score(link, slot, spec)
            local cur = Equipped(slot)
            if WornUnread(slot, cur) then
                -- its data is asked for only when the client does not have it (a cached item
                -- whose link is missing would answer at once, over and over)
                local id = GetInventoryItemID and GetInventoryItemID("player", slot)
                local Req = C_Item and C_Item.RequestLoadItemDataByID
                local Cached = C_Item and C_Item.IsItemDataCachedByID
                if type(id) == "number" and Req then
                    local okC, cached = true, false
                    if Cached then okC, cached = pcall(Cached, id) end
                    if not (okC and cached == true) then pcall(Req, id) end
                end
                -- the other ring or trinket slot may still be empty: that answer wins
                waitSlot = waitSlot or slot
            else
                local old
                if equipLoc == "INVTYPE_2HWEAPON" then
                    old = (cur and W.Score(cur, 16, spec) or 0) + (Equipped(17) and W.Score(Equipped(17), 17, spec) or 0)
                else
                    old = cur and W.Score(cur, slot, spec) or 0
                end
                if cur and cur == link then return nil end
                local g
                if new <= 0 then g = nil
                elseif not cur and old == 0 then g = "empty"
                elseif old > 0 then g = (new - old) / old * 100 end
                if g == "empty" then return "empty", slot end
                if g and (not bestGain or g > bestGain) then bestGain, bestSlot = g, slot end
            end
        end
    end
    -- one slot can't be read: which one you'd replace is not known yet
    if waitSlot then return "pending", waitSlot end
    return bestGain, bestSlot
end

-- Why W.Gain gives its percent: { pct, old, rows = { { stat, amount, pct }, ... } }, biggest first
-- (stat: WL Helper Gear's names, "dps" for weapon damage; amount: the new item minus what it
-- replaces; the rows' pct add up to pct). nil when there is no percent.
local STAT_OF = {
    STR = "str", AGI = "agi", STA = "sta", INT = "int", SPI = "spi", ARMOR = "armor", AP = "ap", RAP = "rap",
    SP = "sp", HEAL = "heal", CRIT = "crit", SCRIT = "crit", HIT = "hit", SHIT = "hit", MP5 = "mp5", DEF = "def",
    DODGE = "dodge", PARRY = "parry", BLOCK = "block", BLOCKV = "bv", DPS = "dps",
}
function W.Explain(link, spec)
    spec = spec or W.Spec()
    if not (spec and type(link) == "string") then return nil end
    local gain, slot = W.Gain(link, spec)
    if type(gain) ~= "number" or not slot then return nil end
    local _, _, equipLoc = Info(link)
    local acc = {}
    local function take(l, sl, sign)
        local parts = Parts(l, sl, spec)
        for code, p in pairs(parts) do
            local stat = STAT_OF[code] or code
            local r = acc[stat]
            if not r then r = { stat = stat, amount = 0, score = 0 }; acc[stat] = r end
            r.amount, r.score = r.amount + sign * p[1], r.score + sign * p[2]
        end
    end
    take(link, slot, 1)
    local old = 0
    local cur = Equipped(slot)
    if cur then take(cur, slot, -1); old = W.Score(cur, slot, spec) end
    if equipLoc == "INVTYPE_2HWEAPON" and Equipped(17) then
        take(Equipped(17), 17, -1); old = old + W.Score(Equipped(17), 17, spec)
    end
    if old <= 0 then return nil end
    local rows = {}
    for _, r in pairs(acc) do
        if math.abs(r.score) > 1e-6 then rows[#rows + 1] = { stat = r.stat, amount = r.amount, pct = r.score / old * 100 } end
    end
    table.sort(rows, function(a, b)
        if math.abs(a.pct) ~= math.abs(b.pct) then return math.abs(a.pct) > math.abs(b.pct) end
        return a.stat < b.stat
    end)
    return { pct = gain, old = old, rows = rows }
end

function W.Reset() wipe(scoreCache); wipe(schoolCache) end
