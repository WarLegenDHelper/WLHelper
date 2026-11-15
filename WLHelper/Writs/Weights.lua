-- Writs/Weights.lua: WL Helper's own stat weights, and the score of an item for your spec.
--
-- One table per class and spec, written for levelling and dungeons in Classic (values relative to the
-- spec's main stat = 1; a % of crit or hit is worth about a dozen points of it). The spec is the
-- talent tree with the most points, or the one picked in Settings > Bags. An item's score is the sum
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

-- talent tab with the most points; the first damage spec before level 10
local function TalentSpec(class)
    local best, bestPts = nil, 0
    if GetTalentTabInfo then
        for i = 1, 3 do
            local r = { pcall(GetTalentTabInfo, i) }
            if r[1] then
                local pts = (type(r[6]) == "number" and r[6]) or (type(r[4]) == "number" and r[4]) or 0
                if pts > bestPts then best, bestPts = i, pts end
            end
        end
    end
    if best then return best end
    local default = { WARRIOR = 1, PALADIN = 3, HUNTER = 2, ROGUE = 2, PRIEST = 3, SHAMAN = 2, MAGE = 3, WARLOCK = 1, DRUID = 2 }
    return default[class] or 1
end

function W.Spec()
    local class = Class()
    local list = SPECS[class]
    if not list then return nil end
    local pick = WLWritsDB and WLWritsDB.upgradeSpec and WLWritsDB.upgradeSpec[class]
    if pick and pick ~= "auto" then
        for _, s in ipairs(list) do if s[1] == pick then return s end end
    end
    return list[TalentSpec(class)] or list[1]
end
function W.SpecName(s)
    s = s or W.Spec()
    if not s then return "" end
    return French() and s[2] or s[3]
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

-- false + why when your class can't use it (or not yet)
function W.CanWear(link)
    local name, minLevel, equipLoc, classID, subID = Info(link)
    if not name then return nil end
    if not SLOTS[equipLoc] then return false end
    local class, level = Class(), UnitLevel("player")
    if minLevel and minLevel > level then return false end
    if classID == 4 then
        if subID == 0 then return true end   -- rings, necks, trinkets
        local from = ARMOR_OK[class] and ARMOR_OK[class][subID]
        if equipLoc == "INVTYPE_CLOAK" then return true end
        return from ~= nil and level >= from
    elseif classID == 2 then
        if not (WEAPON_OK[class] and WEAPON_OK[class][subID]) then return false end
        if equipLoc == "INVTYPE_WEAPONOFFHAND" or (equipLoc == "INVTYPE_WEAPON" and false) then
            return DUAL[class] ~= nil and level >= DUAL[class]
        end
        return true
    end
    return false
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
            if t then
                t = t:lower()
                -- "increases damage done by frost spells and effects by up to 24"
                local w, n = t:match("damage done by (%a+) spells and effects by up to (%d+)")
                -- "augmente les dégâts infligés par les sorts et effets de givre de 24 au maximum"
                if not w then w, n = t:match("sorts et effets d[e']%s*(%S+) de (%d+)") end
                local school = w and SCHOOL_WORD[w]
                if school then c[school] = (c[school] or 0) + tonumber(n) end
            end
        end
    end
    scan:Hide()
    schoolCache[link] = c
    return c
end

-- the item's score in a slot for a spec
function W.Score(link, slot, spec)
    spec = spec or W.Spec()
    if not (link and spec) then return 0 end
    local key = link .. "|" .. (slot or 0) .. "|" .. spec[1]
    if scoreCache[key] then return scoreCache[key] end
    local w = spec[4]
    local s = 0
    for k, v in pairs(Stats(link)) do
        local code = KEYS[k]
        if code and code ~= "DPS" and w[code] and type(v) == "number" then s = s + w[code] * v end
    end
    -- one school's spell damage, worth the spec's spell damage times the school's share
    local shares = SCHOOL_SHARE[Class()] and SCHOOL_SHARE[Class()][spec[1]]
    if shares and w.SP then
        for school, n in pairs(SchoolDamage(link)) do
            if shares[school] then s = s + w.SP * shares[school] * n end
        end
    end
    -- weapon damage per second: main hand and ranged in full, off hand half
    local dps = Stats(link).ITEM_MOD_DAMAGE_PER_SECOND_SHORT
    if dps and w.DPS then
        local f = (slot == 17 and 0.5) or 1
        if slot == 18 and Class() ~= "HUNTER" and not (spec[4] == CASTER or w.SP) then f = 0.3 end
        s = s + w.DPS * dps * f
    end
    scoreCache[key] = s
    return s
end

local function Equipped(slot) return GetInventoryItemLink("player", slot) end

-- Gain of an item against what you wear: percent (number), or "empty" for an empty slot; nil when it
-- is not for you / not better. Second value: the slot compared.
function W.Gain(link)
    local spec = W.Spec()
    if not spec then return nil end
    local can = W.CanWear(link)
    if not can then return nil end
    local _, _, equipLoc = Info(link)
    local slots = SLOTS[equipLoc]
    local new = W.Score(link, slots[1], spec)
    if new <= 0 then return nil end
    local bestGain, bestSlot
    for _, slot in ipairs(slots) do
        local cur = Equipped(slot)
        local old
        if equipLoc == "INVTYPE_2HWEAPON" then
            old = (cur and W.Score(cur, 16, spec) or 0) + (Equipped(17) and W.Score(Equipped(17), 17, spec) or 0)
        else
            old = cur and W.Score(cur, slot, spec) or 0
        end
        if cur and cur == link then return nil end
        local g
        if not cur and old == 0 then g = "empty"
        elseif old > 0 then g = (new - old) / old * 100 end
        if g == "empty" then return "empty", slot end
        if g and (not bestGain or g > bestGain) then bestGain, bestSlot = g, slot end
    end
    return bestGain, bestSlot
end

function W.Reset() wipe(scoreCache); wipe(schoolCache) end
