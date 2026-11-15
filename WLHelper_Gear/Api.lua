-- WL Helper Gear: public API.
--
-- Copyright (C) 2026 WaR LegenD. Based on Geared Forever by Nathan, copyright (C) 2026
-- Nathan. Free software under the GNU General Public License version 3, see
-- LICENSE.txt and NOTICE.md. Written on 2026-11-15 for WL Helper.
--
-- This addon is WL Helper's gear scoring engine: Geared Forever's stat weights and
-- item list, with no window, tooltip, slash command or chat message of its own.
-- WL Helper (a separate addon, under its own licence) only calls the functions below.
--
-- API (global table WLHelperGear)
--
--   WLHelperGear.VERSION                      "1.1.0"
--   WLHelperGear.UPSTREAM                     "Geared Forever 1.1"
--
--   WLHelperGear.Spec() -> classToken, specKey, specName, auto
--       Your class ("MAGE"), spec key ("frost"), spec name ("Frost") and whether the
--       spec was picked from your talents (true) or set with SetSpec (false).
--       With no talent points spent it is the class's first spec, like Geared Forever.
--
--   WLHelperGear.SetSpec(key) -> ok
--       Forces a spec ("arms", "fury", "prot", "holy", "ret", "bm", "mm", "surv",
--       "assa", "combat", "sub", "disc", "shadow", "ele", "enh", "resto", "arcane",
--       "fire", "frost", "affli", "demo", "destro", "balance", "feral", "bear").
--       nil goes back to automatic. Not saved: the caller keeps it if it wants to.
--
--   WLHelperGear.Specs() -> { { key =, name = }, ... }   the specs of your class
--
--   WLHelperGear.Score(itemLinkOrID, level?) -> score, details
--       Score of an item for your class and spec at a level (default: yours).
--       score is 0 when the item has nothing for the spec; nil, "unknown" when the
--       item can't be read (not cached yet, not equippable). When the item is not
--       cached yet its data has been requested: try again after GET_ITEM_INFO_RECEIVED
--       (or a moment later). The same goes for Compare's nil, "unknown" and unknown = true.
--       details = { id, name, level, class, spec, section (name), sectionIndex,
--                   sections = { [section name] = score }, canUse = true or reason,
--                   live = true when the stats came from the game, not the list }
--
--   WLHelperGear.Compare(itemLink, level?) -> result or nil, "unknown"
--       result = { pct          signed percent vs what you wear (rounded, +24 = 24% better)
--                  pctExact     same, not rounded
--                  slot         inventory slot compared against (16 main hand, 11 ring...)
--                  section      "Main Hand", "Off Hand", "Ring"...
--                  equippedLink the item in that slot (nil when empty)
--                  empty        true when that slot is empty (pct is then nil)
--                  equipped     true when this is the item you wear (pct 0)
--                  canUse       true, or why not: "class", "faction", "armor", "shield",
--                               "relic", "weapon", "dualwield", "level40", "level"
--                  blocked      "twohand" when an off hand can't go with your two-hander
--                  score, old   the two scores compared
--                  unknown      true when what you wear can't be read yet (retry later)
--                  other        for a one-hander tried in both hands: the other hand's
--                               result (same fields), or nil }
--       Rings and trinkets compare against the weaker of the two you wear. A two-hander
--       compares against main hand plus off hand. A one-hander is tried in both hands
--       (off hand only for specs that dual wield) and the better result is kept, the other
--       one goes in result.other. An empty off hand ranks above a main-hand upgrade, so
--       look at result.other when result.empty is true.
--       Enchants on what you wear count (WL Helper change), the new item has none.
--
--   WLHelperGear.Weights(level?) -> table
--       { class, spec, level, stats = { str =, agi =, sta =, ... },
--         mainHand, offHand, ranged (weapon DPS weights), slowBonus,
--         prefer = { Axe = 1.06, ... }, hitHave = { melee, ranged, spell } }
--       stat keys: armor str agi sta ap crit hit haste exp def dodge parry block bv int spi
--                  sp heal sdmg mp5 rap fire frost shadow arcane nature holy spen
--
--   WLHelperGear.Best(slot, opts?) -> { { id, name, score, level, quality, source, kind }, ... }
--       Ranked list for a slot. slot: section name ("Head", "Ring", "Two-Hand", "Main Hand",
--       "Off Hand", "Shield", "Ranged"...) or its number (1 to 17).
--       opts = { level = top of the range (default yours), lo = bottom (default 1),
--                top = list length (default 10), quest = include quest rewards with no
--                level requirement (default true), show = { raid = false, ... } source filter }
--
--   WLHelperGear.SetOptions({ neutral =, raid =, raidAuto = })   WL Helper change (v2)
--       neutral = true: none of the v2 changes below (Geared Forever's maths plus talents,
--       real hit and enchants). raid = true/false: raid hit caps (17% spells, 8% melee) at
--       58+ or dungeon caps (5% / 6%); raidAuto = true: automatic (60 once raids open).
--   WLHelperGear.Options() -> { neutral, raid }
--
--   WLHelperGear.QuestRewards(questID) -> { itemID, ... }, names or nil   WL Helper change (v4)
--       The items a quest gives (QuestieDB, WoW Forever data set), in the quest's order:
--       its reward list, then the gear items from ns.itemQuests that list misses. A new
--       table each call; nil when the quest has no known reward. The data does not say
--       which rewards are a choice. names = { [itemID] = "English name" } (Data.lua or
--       QuestData.lua names, to match a caller's own English reward names).
--       Built once, on the first call or the first scoring call: one compact string per
--       quest (QuestData.lua is freed after that); a quest's table is made when asked for.
--
-- Compare result, v2 fields: notes = { "effect counted: extra attacks ...", "set bonus (2)
-- ...: +20.1", "breaks set bonus ...", "proc not counted", "your enchant counted: Crusader" },
-- unscored = true when the item you wear has an effect with no value (pct is then nil),
-- setGain / setLost = set bonus score added to the new item / to what you wear (v3: score
-- includes setGain and old includes setLost, so pct = (score - old) / old).
-- Score's details.notes: the same item notes.
--
-- WL Helper changes (also marked in Engine.lua): talents and real hit read from the game,
-- enchants on equipped items counted. v2 (same day): proc and use effects, set bonuses,
-- hit caps per kind (dungeon vs raid), tank defense cap, bear avoidance, proc enchants and
-- percent enchants, random suffixes, unscored worn items. With none of those present the
-- numbers are Geared Forever's.

local ADDON, ns = ...
local E = ns.engine

local API = {}
WLHelperGear = API

API.VERSION = "1.1.0"
API.UPSTREAM = "Geared Forever 1.1"

local STAT_NAMES = {}
for name, index in pairs(E.STAT) do STAT_NAMES[index] = name end

local GetInstant = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant

local specOverride   -- spec key set with SetSpec, or nil

local function PlayerClass()
    local token = E.PlayerClassToken()
    return token and E.CLASS_BY_TOKEN[token] or nil
end

local function PlayerLevel(level)
    if level then return E.Clamp(level) end
    local lvl = UnitLevel and UnitLevel("player")
    if type(lvl) ~= "number" or (issecretvalue and issecretvalue(lvl)) then lvl = E.MAX_LEVEL end
    return E.Clamp(lvl)
end

local function HasSpec(cls, key)
    for _, spec in ipairs(cls.specs) do
        if spec.key == key then return spec end
    end
    return nil
end

-- Last feral form seen ("bear" or "feral"), so caster or travel form keeps the choice.
local lastFeralForm

local function ReadFeralForm()
    if not GetShapeshiftFormID then return end
    local ok, form = pcall(GetShapeshiftFormID)
    if not ok then return end
    if form == 5 or form == 8 then lastFeralForm = "bear" elseif form == 1 then lastFeralForm = "feral" end
end

-- Spec from the talent tree with the most points. Talent tabs are in the same order as
-- Geared Forever's specs, except the druid's Feral tab (cat or bear: the current form,
-- else the last feral form seen, else cat; SetSpec overrides it) and Restoration (the
-- 4th spec).
local function DetectSpec(cls)
    local scan = E.ScanTalents()
    if not scan then return nil end
    local bestTab, bestPts = nil, 0
    for tab, pts in ipairs(scan.points) do
        if pts > bestPts then bestTab, bestPts = tab, pts end
    end
    if not bestTab then return nil end
    if cls.token == "DRUID" then
        if bestTab == 1 then return "balance" end
        if bestTab == 3 then return "resto" end
        ReadFeralForm()
        return lastFeralForm or "feral"
    end
    local spec = cls.specs[bestTab]
    return spec and spec.key or nil
end

local function CurrentSpec(cls)
    if specOverride and HasSpec(cls, specOverride) then return specOverride, false end
    return DetectSpec(cls) or cls.specs[1].key, true
end

function API.Spec()
    local cls = PlayerClass()
    if not cls then return nil end
    local key, auto = CurrentSpec(cls)
    return cls.token, key, HasSpec(cls, key).label, auto
end

function API.SetSpec(key)
    if key == nil then specOverride = nil return true end
    local cls = PlayerClass()
    if cls and not HasSpec(cls, key) then return false end
    specOverride = key
    return true
end

function API.Specs()
    local cls = PlayerClass()
    local out = {}
    for i, spec in ipairs(cls and cls.specs or {}) do out[i] = { key = spec.key, name = spec.label } end
    return out
end

local function ItemID(x)
    if type(x) == "number" then return x end
    if type(x) == "string" then return tonumber(x:match("item:(%-?%d+)") or x) end
    return nil
end

-- The item from the list or the game, plus the link to read it from.
local function ReadItem(x)
    local id = ItemID(x)
    if not id then return nil end
    local link = type(x) == "string" and x:find("item:") and x or nil
    E.Parse()
    local ok, item = pcall(E.LiveItem, id, link)
    if not ok or not item or not item.slot or not E.SLOT_SECTIONS[item.slot] then return nil end
    return item, link
end

-- Sections to try: the off hand only for specs that use it, like Geared Forever's tooltip.
local function Sections(item, cls, oh)
    local secs, out = E.SLOT_SECTIONS[item.slot], {}
    for _, sec in ipairs(secs) do
        local skip = sec == E.SEC_OFFHAND and #secs > 1 and (oh == 0 or not cls.dual)
        if not skip then out[#out + 1] = sec end
    end
    return out
end

function API.Score(x, level)
    local cls = PlayerClass()
    if not cls then return nil, "noclass" end
    local item = ReadItem(x)
    if not item then return nil, "unknown" end
    local lvl = PlayerLevel(level)
    local key = CurrentSpec(cls)
    local mh, oh, rg, slowBonus, w, prefer = E.Weights(cls, key, lvl)
    local notes
    item, notes = E.Prepare(item, type(x) == "string" and x:find("item:") and x or nil)   -- WL Helper change (v2)
    local base = E.BaseScore(item, w)
    local details = {
        notes = notes,
        id = item.id, name = item.name, level = lvl, class = cls.token, spec = key, sections = {},
        live = item.live == true,
    }
    local best, bestSec, bestUsable
    for _, sec in ipairs(E.SLOT_SECTIONS[item.slot]) do
        local s = E.SectionScore(item, sec, base, mh, oh, rg, slowBonus, prefer)
        details.sections[E.SECTIONS[sec]] = s
    end
    for _, sec in ipairs(Sections(item, cls, oh)) do
        local s = details.sections[E.SECTIONS[sec]]
        local usable = E.CanUse(item, sec, cls, lvl) == true
        -- A section you can use beats one you can't; then the higher score.
        if not best or (usable and not bestUsable) or (usable == bestUsable and s > best) then
            best, bestSec, bestUsable = s, sec, usable
        end
    end
    if not bestSec then bestSec = E.SLOT_SECTIONS[item.slot][1] best = details.sections[E.SECTIONS[bestSec]] end
    details.section, details.sectionIndex = E.SECTIONS[bestSec], bestSec
    details.canUse = E.CanUse(item, bestSec, cls, lvl)
    if best < 0 then best = 0 end
    return best, details
end

function API.Compare(link, level)
    local cls = PlayerClass()
    if not cls then return nil, "noclass" end
    local item = ReadItem(link)
    if not item then return nil, "unknown" end
    local lvl = PlayerLevel(level)
    local key = CurrentSpec(cls)
    local mh, oh, rg, slowBonus, w, prefer = E.Weights(cls, key, lvl)
    -- WL Helper change (v2): use effects from the tooltip, the link for suffix and set checks.
    local itemNotes
    item, itemNotes = E.Prepare(item, link)
    local base = E.BaseScore(item, w)
    local results = {}
    for _, sec in ipairs(Sections(item, cls, oh)) do
        local score = E.SectionScore(item, sec, base, mh, oh, rg, slowBonus, prefer)
        local r = E.Upgrade(item, sec, score, mh, oh, rg, slowBonus, w, prefer)
        local res = {
            pct = r.pct, pctExact = r.pctExact, slot = r.invSlot, section = E.SECTIONS[sec],
            equippedLink = r.equippedLink, offLink = r.offLink, empty = r.empty == true,
            equipped = r.equipped == true, blocked = r.blocked, unknown = r.unknown == true,
            -- WL Helper change (v3): score includes setGain like old includes setLost, so
            -- score - old matches pct.
            canUse = E.CanUse(item, sec, cls, lvl), score = r.new or score, old = r.old,
            -- WL Helper change (v2)
            unscored = r.unscored == true, setGain = r.setGain, setLost = r.setLost, notes = {},
        }
        for _, n in ipairs(itemNotes or {}) do res.notes[#res.notes + 1] = n end
        for _, n in ipairs(r.notes or {}) do res.notes[#res.notes + 1] = n end
        results[#results + 1] = res
    end
    -- Keep the better hand: worn beats everything, then an empty slot, then the higher percent.
    local function rankOf(t)
        if t.equipped then return 4 end
        if t.canUse ~= true or t.blocked or t.unknown or t.unscored then return 0 end
        if t.empty then return 3 end
        return 2
    end
    local best
    for _, res in ipairs(results) do
        if not best or rankOf(res) > rankOf(best)
            or (rankOf(res) == rankOf(best) and (res.pctExact or -math.huge) > (best.pctExact or -math.huge)) then
            best = res
        end
    end
    -- WL Helper change: the other hand's result too, so the caller can choose.
    if best and #results > 1 then
        for _, res in ipairs(results) do
            if res ~= best then best.other = res break end
        end
    end
    return best
end

function API.Weights(level)
    local cls = PlayerClass()
    if not cls then return nil end
    local lvl = PlayerLevel(level)
    local key = CurrentSpec(cls)
    local mh, oh, rg, slowBonus, w, prefer = E.Weights(cls, key, lvl)
    local stats = {}
    for i = 1, E.NUM_STATS do
        if w[i] and w[i] ~= 0 then stats[STAT_NAMES[i]] = w[i] end
    end
    local pref = {}
    for kind, mult in pairs(prefer or {}) do pref[E.KIND_NAME[kind] or kind] = mult end
    return {
        class = cls.token, spec = key, level = lvl, stats = stats,
        mainHand = mh, offHand = oh, ranged = rg, slowBonus = slowBonus == true, prefer = pref,
        hitHave = { melee = E.OwnedHit("melee"), ranged = E.OwnedHit("ranged"), spell = E.OwnedHit("spell") },
        -- WL Helper change (v2): the hit caps used and the defense read.
        hitCap = { melee = E.HitCap(lvl, false), spell = E.HitCap(lvl, true) },
        defense = (E.OwnedDefense()),
        talents = E.ScanTalents() ~= nil,
    }
end

-- WL Helper change (v2): scoring options. { neutral = true } turns the v2 changes off;
-- { raid = true / false } forces raid hit caps at 58+; { raidAuto = true } goes back to
-- automatic (level 60 once raids open on December 9, 2026). Not saved.
function API.SetOptions(t) E.SetOptions(t) end
function API.Options()
    local o = E.Options()
    return { neutral = o.neutral, raid = o.raid }
end

-- WL Helper change (v4): the items a quest gives, and their English names.
function API.QuestRewards(questID)
    local list = E.QuestRewards(questID)
    if not list then return nil end
    E.Parse()   -- Data.lua names (QuestRewards has kept the lists before QuestData.lua is freed)
    local names = {}
    for _, id in ipairs(list) do names[id] = E.RewardName(id) end
    return list, names
end

local SECTION_BY_NAME = {}
for i, name in ipairs(E.SECTIONS) do SECTION_BY_NAME[name:lower()] = i end
SECTION_BY_NAME["one-hand"], SECTION_BY_NAME["mainhand"], SECTION_BY_NAME["offhand"] = 14, 14, 15
SECTION_BY_NAME["twohand"], SECTION_BY_NAME["cloak"] = 13, 4

function API.Best(slot, opts)
    local cls = PlayerClass()
    if not cls then return nil end
    local sec = type(slot) == "number" and slot or SECTION_BY_NAME[tostring(slot or ""):lower()]
    if not sec or not E.SECTIONS[sec] then return nil end
    opts = opts or {}
    local hi = PlayerLevel(opts.level)
    local lo = E.Clamp(opts.lo or 1)
    local top = opts.top or 10
    local show = opts.show or { raid = false }
    local key = CurrentSpec(cls)
    local lists = E.Rank(cls, key, lo, hi, opts.quest ~= false, top, show)
    local out = {}
    for i, row in ipairs(lists[sec] or {}) do
        local it = row.item
        out[i] = { id = it.id, name = it.name, score = row.score, level = it.lvl, quality = it.q,
                   source = it.source, kind = E.KIND_NAME[it.kind] }
    end
    return out
end

-- Talents and spec change: read them again next time. Item data arriving or gear
-- changing: items and enchants are read again.
if CreateFrame then
    local f = CreateFrame("Frame")
    local ITEM_EVENTS = { GET_ITEM_INFO_RECEIVED = true, PLAYER_EQUIPMENT_CHANGED = true }
    for _, ev in ipairs({ "CHARACTER_POINTS_CHANGED", "PLAYER_TALENT_UPDATE", "ACTIVE_TALENT_GROUP_CHANGED",
                          "PLAYER_LEVEL_UP", "PLAYER_ENTERING_WORLD", "SPELLS_CHANGED",
                          "GET_ITEM_INFO_RECEIVED", "PLAYER_EQUIPMENT_CHANGED", "UPDATE_SHAPESHIFT_FORM" }) do
        pcall(f.RegisterEvent, f, ev)
    end
    f:SetScript("OnEvent", function(_, ev)
        if ev == "UPDATE_SHAPESHIFT_FORM" then ReadFeralForm() return end
        if ITEM_EVENTS[ev] then E.ClearCaches("items") return end
        E.ClearCaches(false)
    end)
end
