-- Writs/Reps.lua: "Réputations", a tab of the "Meilleur équipement" window (WP.Reps).
-- Every faction worth raising on Forever for your side (Naowh's journal: cities, Argent Dawn,
-- Timbermaw, Thorium, Cenarion Circle, the battleground factions, Forever's own): what each
-- standing unlocks (pieces, mounts, consumables and enchants, recipes), your standing and points
-- now (C_Reputation.GetFactionDataByID, else GetFactionInfoByID), the points still missing, and the
-- fastest ways to earn them with how many times to do each. The standings that unlock a piece of
-- your list (pre-BiS, BiS and PvP tabs, Naowh's simulated pick first when its BiS List is on) are
-- marked "pour ton équipement" and those factions come first. The ways:
--   * the items to hand in and the repeatable quests (Naowh Forever's Dungeon Journal factions and
--     its Discovery quest data: read live at runtime, every call in a pcall, nothing copied);
--   * the one-time quests that still give this faction points (the same quest data, the ones you
--     have not done, your side, under the quest's reputation cap);
--   * monsters, from WL Helper's own short table below, each line read on its Wowhead WoW Forever
--     NPC page. A way with no sourced number is not shown with a number.
-- Points are the game's base points (a racial bonus is not counted).
local ADDON, root = ...
local ns = root.Writs
local WP = ns.WP
local L = ns.L

local R = {}
WP.Reps = R

ns.AddEnglish({
    ["Réputations"] = "Reputations",
    ["Haï"] = "Hated", ["Hostile"] = "Hostile", ["Inamical"] = "Unfriendly", ["Neutre"] = "Neutral",
    ["Amical"] = "Friendly", ["Honoré"] = "Honored", ["Révéré"] = "Revered", ["Exalté"] = "Exalted",
    ["Les réputations utiles sur Forever : ce que chaque rang débloque, ton rang, et le plus rapide pour les monter. En tête, celles qui débloquent une pièce de ta liste (pré-BiS, BiS, PvP)."] =
        "The reputations worth raising on Forever: what each standing unlocks, your standing, and the fastest way up. First, those that unlock a piece of your list (pre-BiS, BiS, PvP).",
    ["Points de base, sans bonus de race. Sources : les données de Naowh lues en direct (paliers, objets à rendre, quêtes) et Wowhead WoW Forever pour les monstres."] =
        "Base points, no racial bonus. Sources: Naowh's data read live (standings, items to hand in, quests) and Wowhead WoW Forever for monsters.",
    ["Les paliers et les objets à rendre viennent du Journal de donjons de Naowh : active-le pour les voir ici."] =
        "Standings and items to hand in come from Naowh's Dungeon Journal: turn it on to see them here.",
    ["1 réputation"] = "1 reputation", ["%d réputations"] = "%d reputations",
    ["dont 1 pièce de ta liste"] = "including 1 piece of your list",
    ["dont %d pièces de ta liste"] = "including %d pieces of your list",
    ["Aucune réputation connue"] = "No known reputation",
    ["%s, vise %s"] = "%s, aim for %s",
    ["Atteint"] = "Reached",
    ["il manque %s"] = "%s to go",
    ["Rang actuel : %s (%s/%s)"] = "Standing now: %s (%s/%s)",
    ["Rang actuel : %s"] = "Standing now: %s",
    ["Pas encore rencontrée : ton rang n'est pas connu."] = "Not met yet: your standing is not known.",
    ["Le plus rapide"] = "Fastest",
    ["Intendant"] = "Quartermaster",
    ["%s (%s)"] = "%s (%s)",
    ["%s : %s"] = "%s: %s",
    ["Rendre %s à %s : +%d par rendu, %s."] = "Hand in %s to %s: +%d each time, %s.",
    ["Rendre %s à %s : +%d par rendu, %s. Tu en as %d."] = "Hand in %s to %s: +%d each time, %s. You have %d.",
    ["1 rendu"] = "1 hand-in", ["%s rendus"] = "%s hand-ins",
    ["Quête répétable « %s » (%s) : +%d par rendu, %s."] = "Repeatable quest \"%s\" (%s): +%d each time, %s.",
    ["Tuer %s (%s) : +%d par monstre, %s."] = "Kill %s (%s): +%d per kill, %s.",
    ["Tuer %s (%s) : +%d par monstre jusqu'à %s, %s."] = "Kill %s (%s): +%d per kill up to %s, %s.",
    ["1 monstre"] = "1 kill", ["%s monstres"] = "%s kills",
    ["1 quête pas encore faite : +%s points (%s)."] = "1 quest not done yet: +%s points (%s).",
    ["%d quêtes pas encore faites : jusqu'à +%s points (%s)."] = "%d quests not done yet: up to +%s points (%s).",
    ["Ne donne plus de points à ton rang : %s."] = "No more points at your standing: %s.",
    ["Aucune façon sourcée de gagner cette réputation ici : pas d'objet à rendre, de quête ni de monstre connus."] =
        "No sourced way to earn this reputation here: no known item to hand in, quest or monster.",
    ["Les quêtes de cette faction se chargent la première fois que l'onglet s'ouvre."] =
        "This faction's quests load the first time the tab opens.",
    ["Clic : la position de l'intendant sur la carte"] = "Click: the quartermaster's spot on the map",
    ["Ce qu'elle débloque"] = "What it unlocks",
    ["pour ton équipement"] = "for your gear",
    ["Pour ton équipement"] = "For your gear",
    ["Autres réputations"] = "Other reputations",
    ["Tout est débloqué"] = "Everything unlocked",
    ["Pas encore ouvertes sur Forever"] = "Not open on Forever yet",
    ["Pas encore ouverte sur Forever : ses récompenses sont connues, pas encore la façon de la monter."] =
        "Not open on Forever yet: its rewards are known, not yet how to raise it.",
    ["1 pièce"] = "1 piece", ["%d pièces"] = "%d pieces", ["1 monture"] = "1 mount", ["%d montures"] = "%d mounts",
    ["1 recette"] = "1 recipe", ["%d recettes"] = "%d recipes", ["1 consommable"] = "1 consumable",
    ["%d consommables"] = "%d consumables", ["1 autre objet"] = "1 other item", ["%d autres objets"] = "%d other items",
    ["+%d"] = "+%d",
})

local function Plain(v)
    if v == nil or (issecretvalue and issecretvalue(v)) then return nil end
    return v
end

-- ---------------------------------------------------------------- standings
-- the points where each standing starts, counted from Neutral (the game's own bands: Hated 36000,
-- Hostile, Unfriendly and Neutral 3000, Friendly 6000, Honored 12000, Revered 21000)
R.MIN = { [1] = -42000, [2] = -6000, [3] = -3000, [4] = 0, [5] = 3000, [6] = 9000, [7] = 21000, [8] = 42000 }
local WORD = { "Haï", "Hostile", "Inamical", "Neutre", "Amical", "Honoré", "Révéré", "Exalté" }
function R.StandingName(n)
    n = tonumber(n)
    if not n or not WORD[n] then return "?" end
    return L(WORD[n])
end
-- the standing a number of points falls in
function R.ReactionOf(points)
    local r = 1
    for i = 1, 8 do if points >= R.MIN[i] then r = i end end
    return r
end

-- your standing with a faction: reaction (1-8), points from Neutral, name; nil when not met
function R.Standing(id)
    local CR = C_Reputation
    if CR and CR.GetFactionDataByID then
        local ok, d = pcall(CR.GetFactionDataByID, id)
        if ok and type(d) == "table" then
            local react, cur = tonumber(Plain(d.reaction)), tonumber(Plain(d.currentStanding))
            if react and cur then return react, cur, Plain(d.name) end
        end
    end
    if GetFactionInfoByID then
        local ok, name, _, react, _, _, value = pcall(GetFactionInfoByID, id)
        react, value = ok and tonumber(Plain(react)), ok and tonumber(Plain(value))
        if react and value then return react, value, Plain(name) end
    end
    return nil
end

-- ---------------------------------------------------------------- monsters (Wowhead WoW Forever)
-- One line per monster, read on its Wowhead WoW Forever NPC page (wowhead.com/forever/npc=N,
-- 2026-11-22): points per kill and the standing where it stops giving any ("stops at Honored").
-- Only monsters read there are listed: nothing from Classic, no guessed number.
R.KILLS = {
    [576] = {   -- Timbermaw Hold
        { npc = 7153, name = "Deadwood Warrior", rep = 5, upto = 6, map = 1448 },
        { npc = 7440, name = "Winterfall Den Watcher", rep = 5, upto = 6, map = 1452 },
    },
    [529] = {   -- Argent Dawn
        { npc = 10390, name = "Skeletal Guardian", rep = 5, place = "Stratholme" },
        { npc = 10471, name = "Scholomance Acolyte", rep = 5, upto = 6, place = "Scholomance" },
        { npc = 8530, name = "Cannibal Ghoul", rep = 5, upto = 5, map = 1423 },
    },
    [609] = {   -- Cenarion Circle
        { npc = 11881, name = "Twilight Geolord", rep = 1, upto = 6, map = 1451 },
    },
}

-- ---------------------------------------------------------------- Naowh's data, read live
local function N()
    local n = rawget(_G, "NaowhForever")
    return type(n) == "table" and n or nil
end
local function Journal()
    local n = N()
    local J = n and n.Journal
    if type(J) == "table" and type(J.Factions) == "function" then return J end
    return nil
end
local FACTION_TABS = { "reputation", "pvp" }
-- every faction of Naowh's journal (both tabs), or {}
function R.Factions()
    local J = Journal()
    local out = {}
    if not J then return out end
    for _, tab in ipairs(FACTION_TABS) do
        local ok, list = pcall(J.Factions, tab)
        if ok and type(list) == "table" then
            for _, f in ipairs(list) do if type(f) == "table" and tonumber(f.id) then out[#out + 1] = f end end
        end
    end
    return out
end
-- item -> { faction, standing }, built once per journal
local itemIndex, indexOf
local function ItemIndex()
    local J = Journal()
    if not J then return {} end
    if indexOf == J and itemIndex then return itemIndex end
    itemIndex, indexOf = {}, J
    for _, f in ipairs(R.Factions()) do
        for _, tier in ipairs(type(f.tiers) == "table" and f.tiers or {}) do
            for _, id in ipairs(type(tier.items) == "table" and tier.items or {}) do
                if not itemIndex[id] then itemIndex[id] = { faction = f, standing = tonumber(tier.standing) } end
            end
        end
    end
    return itemIndex
end
function R.ItemFaction(id)
    local e = ItemIndex()[id]
    if e then return e.faction, e.standing end
    return nil
end

-- the quest data (Discovery's, load-on-demand: Naowh's own table loads it the first time it is
-- read). Indexed once: [faction id] = { { q, rep, repeatable } }.
local quests
local function QuestData()
    local n = N()
    local D = n and rawget(n, "CompletoQuestData")
    if type(D) ~= "table" then return nil end
    local ok, gains = pcall(function() return D.Gains end)
    if not (ok and type(gains) == "table" and next(gains)) then return nil end
    return D, gains
end
local function QuestIndex()
    if quests then return quests end
    local D, gains = QuestData()
    if not D then return nil end
    quests = {}
    local rep = type(D.Repeatable) == "table" and D.Repeatable or {}
    for q, g in pairs(gains) do
        if type(g) == "table" then
            for i = 3, #g - 1, 2 do
                local f, pts = tonumber(g[i]), tonumber(g[i + 1])
                if f and pts and pts > 0 then
                    local list = quests[f] or {}; quests[f] = list
                    list[#list + 1] = { q = q, rep = pts, repeatable = rep[q] == true }
                end
            end
        end
    end
    R._D = D
    return quests
end
R._QuestIndex = QuestIndex
function R._Reset() quests, itemIndex, indexOf, R._D = nil, nil, nil, nil end

-- ---------------------------------------------------------------- names
local function ZoneName(m)
    if not (m and C_Map and C_Map.GetMapInfo) then return nil end
    local ok, info = pcall(C_Map.GetMapInfo, m)
    return ok and type(info) == "table" and Plain(info.name) or nil
end
local function DungeonName(en)
    if type(en) ~= "string" or not root.D then return en end
    for k, d in pairs(root.D) do
        if d.n == en and not d.cq then return root.DName and root.DName(k) or en end
    end
    return en
end
local function ItemName(id)
    if GetItemInfo then
        local ok, name = pcall(GetItemInfo, id)
        name = ok and Plain(name)
        if name then return name end
    end
    if C_Item and C_Item.RequestLoadItemDataByID then pcall(C_Item.RequestLoadItemDataByID, id) end
    return nil
end
local function QuestTitle(q, fallback)
    local f = C_QuestLog and C_QuestLog.GetTitleForQuestID
    if f then
        local ok, t = pcall(f, q)
        t = ok and Plain(t)
        if type(t) == "string" and t ~= "" then return t end
    end
    return fallback or ("#" .. tostring(q))
end
local function QuestDone(q)
    local f = (C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted) or IsQuestFlaggedCompleted
    if not f then return false end
    local ok, d = pcall(f, q)
    return ok and Plain(d) == true
end
local function BagCount(id)
    local f = (C_Item and C_Item.GetItemCount) or GetItemCount
    if not f then return 0 end
    local ok, n = pcall(f, id)
    return ok and tonumber(Plain(n)) or 0
end
local function MySide()
    local s = UnitFactionGroup and Plain((UnitFactionGroup("player"))) or nil
    return s
end
local function MyLevel() return tonumber(Plain(UnitLevel and UnitLevel("player"))) or 60 end

function R.Num(n)
    n = math.floor((tonumber(n) or 0) + 0.5)
    local s = tostring(math.abs(n))
    local sep = (root.lang == "fr" or (not root.lang and GetLocale and GetLocale() == "frFR")) and " " or ","
    s = s:reverse():gsub("(%d%d%d)", "%1" .. sep):reverse()
    if s:sub(1, 1) == sep then s = s:sub(2) end
    return (n < 0 and "-" or "") .. s
end
local function Times(n, one, many) return n == 1 and L(one) or string.format(L(many), R.Num(n)) end

-- ---------------------------------------------------------------- the pieces of your list
-- { { id, name, mode } } for the first pick of each slot of the pre-BiS, BiS and PvP tabs, not
-- worn and not in your bags; second value: Best's rows were there (WL Helper Gear loaded)
function R.WantedPieces()
    local B = WP.Best
    if not (B and B.Rows and B._Slots) then return {}, false end
    local out, seen, any = {}, {}, false
    for _, m in ipairs({ "pre", "bis", "pvp" }) do
        local ok, list = pcall(B.Rows, 60, 4, m)
        if ok and type(list) == "table" then
            any = true
            if B.NaowhOverlay then pcall(B.NaowhOverlay, list, m, 60) end
            local okS, slots = pcall(B._Slots, list)
            for _, s in ipairs(okS and slots or {}) do
                local it = s.best
                if it and it.id and not seen[it.id] and s.state == "get" then
                    seen[it.id] = true
                    out[#out + 1] = { id = it.id, name = it.name, raw = it.raw, mode = m, slot = s.label }
                end
            end
        end
    end
    return out, any
end

-- ---------------------------------------------------------------- the ways
-- the most a quest can still give (its reputation cap, Discovery's MaxReputation: [q] = { faction, cap })
local function Cap(q, fid)
    local D = R._D
    local m = D and type(D.MaxReputation) == "table" and D.MaxReputation[q]
    if type(m) == "table" and tonumber(m[1]) == fid and tonumber(m[2]) then return tonumber(m[2]) end
    return nil
end
local function SideOkQuest(q, side)
    local D = R._D
    local e = D and type(D.Quests) == "table" and D.Quests[q]
    local s = type(e) == "table" and tonumber(e[4]) or 3
    if s == 1 then return side ~= "Horde" end
    if s == 2 then return side ~= "Alliance" end
    return true
end
local function QuestInfo(q)
    local D = R._D
    local e = D and type(D.Quests) == "table" and D.Quests[q]
    if type(e) ~= "table" then return nil end
    return { name = e[1], level = tonumber(e[2]), min = tonumber(e[3]), map = tonumber(e[7]), giver = e[10] }
end

-- the ways to earn `fid` points from `cur` up to `goal` (points from Neutral):
-- { { kind, text, n, per }, ... } sorted: one-time quests first, then the fewest actions
function R.Ways(f, cur, goal)
    local fid = tonumber(f.id)
    local side = MySide()
    local out, turnQ = {}, {}
    local idx = QuestIndex()
    local function Left(cap)
        local top = goal
        if cap and cap < top then top = cap end
        return top - cur
    end
    -- items to hand in (Naowh's journal)
    for _, t in ipairs(type(f.turnins) == "table" and f.turnins or {}) do
        local pick
        for _, qd in ipairs(type(t.quests) == "table" and t.quests or {}) do
            turnQ[qd[1]] = true
            local s = qd[2]
            if not pick and (s == "B" or (s == "A" and side ~= "Horde") or (s == "H" and side ~= "Alliance")) then pick = qd end
        end
        local per = tonumber(t.rep)
        if pick and per and per > 0 then
            local cap = Cap(pick[1], fid)
            local left = Left(cap)
            local giver = type(pick[3]) == "string" and pick[3]:match("^.- %- (.-) %(") or nil
            giver = giver and root.NpcName and root.NpcName(giver) or giver
            local where = ZoneName(pick[4])
            local who = giver and (where and string.format(L("%s (%s)"), giver, where) or giver) or (where or "?")
            if left <= 0 then
                out[#out + 1] = { kind = "capped", text = string.format(L("Ne donne plus de points à ton rang : %s."), QuestTitle(pick[1], t.name)), n = math.huge }
            else
                local n = math.ceil(left / per)
                local takes, held, unknown = {}, nil, false
                local tk = type(t.takes) == "table" and t.takes or {}
                for i = 1, #tk - 1, 2 do
                    local id, k = tonumber(tk[i]), tonumber(tk[i + 1]) or 1
                    if id then
                        local nm = ItemName(id)
                        if not nm then unknown = true end
                        takes[#takes + 1] = (k > 1 and (k .. " × ") or "") .. (nm or "")
                        local have = BagCount(id)
                        if i == 1 then held = have end
                    end
                end
                -- an item the game has not read yet: the quest's name instead ("Minion's Scourgestones")
                local what = (#takes > 0 and not unknown) and table.concat(takes, " + ") or QuestTitle(pick[1], t.name)
                local count = Times(n, "1 rendu", "%s rendus")
                local text
                if held and held > 0 then
                    text = string.format(L("Rendre %s à %s : +%d par rendu, %s. Tu en as %d."), what, who, per, count, held)
                else
                    text = string.format(L("Rendre %s à %s : +%d par rendu, %s."), what, who, per, count)
                end
                out[#out + 1] = { kind = "turnin", text = text, n = n, per = per }
            end
        end
    end
    -- repeatable quests not already in the hand-ins, and one-time quests
    local once, onceSum, onceNames = 0, 0, {}
    local reps = {}
    for _, e in ipairs(idx and idx[fid] or {}) do
        if not turnQ[e.q] and SideOkQuest(e.q, side) then
            local info = QuestInfo(e.q)
            local left = Left(Cap(e.q, fid))
            if e.repeatable then
                if info and left > 0 then reps[#reps + 1] = { e = e, info = info, left = left } end
            elseif left > 0 and not QuestDone(e.q) then
                once = once + 1
                onceSum = onceSum + e.rep
                onceNames[#onceNames + 1] = { e.rep, info and QuestTitle(e.q, info.name) or QuestTitle(e.q) }
            end
        end
    end
    table.sort(reps, function(a, b) return a.e.rep > b.e.rep end)
    for i = 1, math.min(2, #reps) do
        local r = reps[i]
        local n = math.ceil(r.left / r.e.rep)
        local where = ZoneName(r.info.map) or "?"
        out[#out + 1] = { kind = "repeat", n = n, per = r.e.rep,
            text = string.format(L("Quête répétable « %s » (%s) : +%d par rendu, %s."), QuestTitle(r.e.q, r.info.name), where, r.e.rep, Times(n, "1 rendu", "%s rendus")) }
    end
    -- monsters
    for _, k in ipairs(R.KILLS[fid] or {}) do
        local cap = k.upto and R.MIN[k.upto] or nil
        local left = Left(cap)
        local nm = root.NpcName and root.NpcName(k.name) or k.name
        local where = k.place and DungeonName(k.place) or ZoneName(k.map) or "?"
        if left > 0 then
            local n = math.ceil(left / k.rep)
            local text
            if k.upto then
                text = string.format(L("Tuer %s (%s) : +%d par monstre jusqu'à %s, %s."), nm, where, k.rep, R.StandingName(k.upto), Times(n, "1 monstre", "%s monstres"))
            else
                text = string.format(L("Tuer %s (%s) : +%d par monstre, %s."), nm, where, k.rep, Times(n, "1 monstre", "%s monstres"))
            end
            out[#out + 1] = { kind = "kill", text = text, n = n, per = k.rep }
        end
    end
    table.sort(out, function(a, b)
        if (a.kind == "capped") ~= (b.kind == "capped") then return b.kind == "capped" end
        return a.n < b.n
    end)
    if once > 0 then
        table.sort(onceNames, function(a, b) return a[1] > b[1] end)
        local names = {}
        for i = 1, math.min(3, #onceNames) do names[i] = onceNames[i][2] end
        local text
        if once == 1 then text = string.format(L("1 quête pas encore faite : +%s points (%s)."), R.Num(onceSum), names[1])
        else text = string.format(L("%d quêtes pas encore faites : jusqu'à +%s points (%s)."), once, R.Num(onceSum), table.concat(names, ", ")) end
        table.insert(out, 1, { kind = "quests", text = text, n = once, sum = onceSum })
    end
    return out, idx ~= nil
end

-- ---------------------------------------------------------------- what a faction sells
-- the kind of a reward: "gear" (armor, weapon), "mount", "recipe", "use" (consumables, enchants of
-- the head or shoulders, item enhancements), "other"
function R.Kind(id)
    local f = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
    if not f then return "other" end
    local ok, _, _, _, loc, _, cls, sub = pcall(f, id)
    if not ok then return "other" end
    cls, sub, loc = tonumber(Plain(cls)), tonumber(Plain(sub)), Plain(loc)
    if cls == 9 then return "recipe" end
    if cls == 15 and sub == 5 then return "mount" end
    if (cls == 2 or cls == 4) and type(loc) == "string" and loc ~= "" and loc ~= "INVTYPE_NON_EQUIP_IGNORE" then return "gear" end
    if cls == 0 or cls == 8 then return "use" end
    return "other"
end
local KIND_ORDER = { mount = 1, gear = 2, use = 3, recipe = 4, other = 5 }
local KIND_WORDS = {
    gear = { "1 pièce", "%d pièces" }, mount = { "1 monture", "%d montures" }, recipe = { "1 recette", "%d recettes" },
    use = { "1 consommable", "%d consommables" }, other = { "1 autre objet", "%d autres objets" },
}

-- ---------------------------------------------------------------- the factions
-- Every faction of Naowh's journal for your side (cities, Argent Dawn, Timbermaw, the battleground
-- factions, Forever's own): { faction, id, name, side, unreleased, met, react, points, goal,
-- missing, ways, tiers = { { standing, reached, bis, items = { { id, kind, bis } } } },
-- pieces = { { id, name, standing, slot, reached } }, open, group }
-- group: 1 a piece of your list still to unlock ("pour ton équipement"), 2 something left to
-- earn, 3 everything unlocked, 4 not open on Forever yet. Sorted by group, then the pieces of your
-- list, then the fewest points missing. Also returns: pieces of your list found, journal on, gear on.
-- The goal: the highest standing a piece of your list needs; else the next standing that unlocks
-- something; a faction with nothing to buy (a city): Exalted.
local function GoalOf(e)
    local bisGoal
    for _, p in ipairs(e.pieces) do
        if not p.reached and (not bisGoal or p.standing > bisGoal) then bisGoal = p.standing end
    end
    if bisGoal then return bisGoal end
    local top
    for _, t in ipairs(e.tiers) do
        if not top or t.standing > top then top = t.standing end
        if e.react and t.standing > e.react then return t.standing end
    end
    return top or 8
end
function R.Collect()
    local wanted, gear = R.WantedPieces()
    local want = {}
    for _, p in ipairs(wanted) do want[p.id] = p end
    local J = Journal()
    local side = MySide()
    local out, nbis = {}, 0
    for _, f in ipairs(R.Factions()) do
        if not (f.side and side and f.side ~= side) then
            local e = { faction = f, id = tonumber(f.id), name = f.name, side = f.side, unreleased = f.unreleased == true,
                tiers = {}, pieces = {} }
            local react, pts, gameName = R.Standing(e.id)
            e.name = e.name or gameName or tostring(e.id)
            e.met, e.react, e.points = react ~= nil, react, pts
            for _, tier in ipairs(type(f.tiers) == "table" and f.tiers or {}) do
                local st = tonumber(tier.standing)
                if st then
                    local t = { standing = st, items = {}, reached = react ~= nil and react >= st }
                    for _, id in ipairs(type(tier.items) == "table" and tier.items or {}) do
                        local it = { id = id, kind = R.Kind(id), bis = want[id] ~= nil }
                        t.items[#t.items + 1] = it
                        if it.bis then
                            t.bis = true
                            local p = want[id]
                            e.pieces[#e.pieces + 1] = { id = id, name = p.name, standing = st, slot = p.slot, reached = t.reached }
                            nbis = nbis + 1
                        end
                    end
                    table.sort(t.items, function(a, b)
                        if a.bis ~= b.bis then return a.bis end
                        if KIND_ORDER[a.kind] ~= KIND_ORDER[b.kind] then return KIND_ORDER[a.kind] < KIND_ORDER[b.kind] end
                        return a.id < b.id
                    end)
                    e.tiers[#e.tiers + 1] = t
                end
            end
            table.sort(e.tiers, function(a, b) return a.standing < b.standing end)
            e.goal = GoalOf(e)
            if e.met then
                e.missing = (react >= e.goal) and 0 or math.max(0, R.MIN[e.goal] - pts)
                if e.missing > 0 and not e.unreleased then e.ways = R.Ways(f, pts, R.MIN[e.goal]) end
            end
            local open = 0
            for _, p in ipairs(e.pieces) do if not p.reached then open = open + 1 end end
            e.open = open
            if e.unreleased then e.group = 4
            elseif open > 0 then e.group = 1
            elseif e.missing == 0 then e.group = 3
            else e.group = 2 end
            out[#out + 1] = e
        end
    end
    table.sort(out, function(a, b)
        if a.group ~= b.group then return a.group < b.group end
        if a.open ~= b.open then return a.open > b.open end
        local ma, mb = a.missing or 1e9, b.missing or 1e9
        if ma ~= mb then return ma < mb end
        return tostring(a.name) < tostring(b.name)
    end)
    return out, nbis, J ~= nil, gear
end

-- ---------------------------------------------------------------- cards
local S, C = ns.S, ns.S and ns.S.C
local PAD = 12
local GROUP_WORDS = { "Pour ton équipement", "Autres réputations", "Tout est débloqué", "Pas encore ouvertes sur Forever" }

-- items whose name the game had not read yet: one redraw of the tab when they arrive
local waiting, queued = {}, false
do
    local ev = CreateFrame("Frame")
    pcall(ev.RegisterEvent, ev, "GET_ITEM_INFO_RECEIVED")
    ev:SetScript("OnEvent", function(_, _, id)
        id = tonumber(Plain(id))
        if not (id and waiting[id]) then return end
        waiting[id] = nil
        local B = WP.Best
        if queued or not (B and B.ShownMode and B.ShownMode() == "rep") then return end
        queued = true
        local function go() queued = false; if B.ShownMode() == "rep" then B.Fill() end end
        if C_Timer and C_Timer.After then C_Timer.After(0.5, go) else go() end
    end)
end
local function Name(id)
    local n = ItemName(id)
    if not n then waiting[id] = true end
    return n
end

local function OpenQuartermaster(f)
    local q = type(f) == "table" and f.quartermaster
    if type(q) ~= "table" or not (q.map and q.x and q.y) then return end
    local nm = root.NpcName and root.NpcName(q.name) or q.name
    if WP.GoTo and WP.GoTo.Go then pcall(WP.GoTo.Go, { map = q.map, x = q.x, y = q.y, label = nm, gps = nm }) end
end

local function MakeCard(parent)
    local c = CreateFrame("Button", nil, parent)
    c.bg = S.Solid(c, "BACKGROUND", C.cardFill or { 1, 1, 1, 0.03 }); c.bg:SetAllPoints()
    if S.Border then pcall(S.Border, c) end
    c.hl = S.Solid(c, "BORDER", { 1, 1, 1, 0.05 }); c.hl:SetAllPoints(); c.hl:Hide()
    c.stack = root.TextStack(c)
    c:SetScript("OnEnter", function(self)
        local q = self.entry and self.entry.faction and self.entry.faction.quartermaster
        if type(q) == "table" and q.map then
            self.hl:Show()
            S.Tip(self, { self.entry.name or "", L("Clic : la position de l'intendant sur la carte") })
        end
    end)
    c:SetScript("OnLeave", function(self) self.hl:Hide(); S.HideTip() end)
    c:SetScript("OnClick", function(self) if self.entry then OpenQuartermaster(self.entry.faction) end end)
    return c
end

local function Hex(c) return string.format("%02x%02x%02x", c[1] * 255, c[2] * 255, c[3] * 255) end

-- one standing's line: "Révéré : Ceinture X, Patron : Y, +3 (2 pièces, 4 recettes)  pour ton équipement"
function R.TierText(t)
    local names, count = {}, {}
    for _, it in ipairs(t.items) do
        count[it.kind] = (count[it.kind] or 0) + 1
        if #names < 3 then
            local nm = Name(it.id)
            if nm then
                if it.bis then nm = "|cff" .. Hex(C.gold) .. nm .. "|r" end
                names[#names + 1] = nm
            end
        end
    end
    local kinds = {}
    for _, k in ipairs({ "mount", "gear", "use", "recipe", "other" }) do
        local c = count[k]
        if c then kinds[#kinds + 1] = c == 1 and L(KIND_WORDS[k][1]) or string.format(L(KIND_WORDS[k][2]), c) end
    end
    local more = #t.items - #names
    local text = table.concat(names, ", ")
    if more > 0 and #names > 0 then text = text .. ", " .. string.format(L("+%d"), more) end
    text = text .. (text ~= "" and " " or "") .. "(" .. table.concat(kinds, ", ") .. ")"
    text = string.format(L("%s : %s"), R.StandingName(t.standing), text)
    if t.bis then text = text .. "  |cff" .. Hex(C.gold) .. L("pour ton équipement") .. "|r" end
    return text
end

-- fills one card for a faction entry at width w, returns its height
local function PaintCard(c, e, w)
    c.entry = e
    local st = c.stack
    st:Begin(PAD, PAD, w - 2 * PAD)
    st:Heading(e.name)
    local goalName = R.StandingName(e.goal)
    if e.unreleased then
        st:Muted(L("Pas encore ouverte sur Forever : ses récompenses sont connues, pas encore la façon de la monter."))
    elseif e.met then
        local base = math.min(0, e.points)
        local total = math.max(1, R.MIN[e.goal] - base)
        local done = math.max(0, math.min(total, e.points - base))
        local cnt = e.missing > 0 and string.format(L("il manque %s"), R.Num(e.missing)) or L("Atteint")
        local sub
        if e.react >= 8 then sub = string.format(L("Rang actuel : %s"), R.StandingName(e.react))
        else
            local lo, hi = R.MIN[e.react], R.MIN[e.react + 1]
            sub = string.format(L("Rang actuel : %s (%s/%s)"), R.StandingName(e.react), R.Num(e.points - lo), R.Num(hi - lo))
        end
        local label = e.react >= e.goal and R.StandingName(e.react) or string.format(L("%s, vise %s"), R.StandingName(e.react), goalName)
        st:Stat(label, done, total, { count = cnt, sub = sub })
    else
        st:Muted(L("Pas encore rencontrée : ton rang n'est pas connu."))
    end
    local q = e.faction and e.faction.quartermaster
    if type(q) == "table" and q.name then
        local nm = root.NpcName and root.NpcName(q.name) or q.name
        local z = ZoneName(q.map)
        st:Fact(L("Intendant"), z and string.format(L("%s (%s)"), nm, z) or nm)
    end
    if #e.tiers > 0 then
        st:Heading(L("Ce qu'elle débloque"))
        local lines, marks = {}, {}
        for i, t in ipairs(e.tiers) do
            lines[i] = R.TierText(t)
            marks[i] = t.reached and "check" or nil
        end
        st:Bullets(lines, { marks = marks, size = 12 })
    end
    if e.met and e.missing > 0 and not e.unreleased then
        st:Heading(L("Le plus rapide"))
        local lines = {}
        for i, wy in ipairs(e.ways or {}) do if i <= 5 then lines[#lines + 1] = wy.text end end
        if #lines > 0 then st:Bullets(lines, { size = 12 })
        else st:Muted(L("Aucune façon sourcée de gagner cette réputation ici : pas d'objet à rendre, de quête ni de monstre connus.")) end
    end
    local h = st:End() + 2 * PAD
    c:SetSize(w, h)
    return h
end

-- R.Fill(child, W, take) -> height, factions, pieces of your list, journal on, gear on: one
-- section per group, cards in two columns (one when narrow) from y = 0 of `child`;
-- take(kind, maker) gives a pooled frame
function R.Fill(child, W, take)
    local list, pieces, journal, gear = R.Collect()
    local n, colW, xs = 1, W, { 0 }
    if root.Cols then n, colW, xs = root.Cols(W, 420, 12, 2, 200) end
    local y, g = 0, nil
    local col, lineH = 1, 0
    local function CloseLine()
        if col > 1 then y = y + lineH + 12 end
        col, lineH = 1, 0
    end
    local counts = {}
    for _, e in ipairs(list) do counts[e.group] = (counts[e.group] or 0) + 1 end
    for _, e in ipairs(list) do
        if e.group ~= g then
            CloseLine()
            g = e.group
            local hd = take("heads", function(p) return S.SectionHeader(p, "", 0, nil, nil, true) end)
            hd:Set(L(GROUP_WORDS[g]), counts[g])
            hd:ClearAllPoints(); hd:SetPoint("TOPLEFT", 0, -y); hd:SetWidth(W)
            y = y + 24 + 8
        end
        local c = take("cards", MakeCard)
        local h = PaintCard(c, e, colW)
        c:ClearAllPoints(); c:SetPoint("TOPLEFT", xs[col], -y)
        if h > lineH then lineH = h end
        col = col + 1
        if col > n then y = y + lineH + 12; col, lineH = 1, 0 end
    end
    CloseLine()
    return y, #list, pieces, journal, gear
end
R._PaintCard = PaintCard
