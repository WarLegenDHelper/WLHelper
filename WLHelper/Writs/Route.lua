-- Writs/Route.lua: WL Helper's GPS, shared by the dungeon guide (source "dungeon") and the Comptoir
-- (source "writs"). It finds the fastest way from where you stand: riding, the flight paths you know,
-- zeppelins, boats, a mage's city teleports, the druid's Moonglade (and its flight home), the
-- Hearthstone and a shaman's Astral Recall to your inn, then guides you one leg at a time (Arrow.lua).
-- The plan is made again every few seconds, when a flight map opens, after a flight, a boat or a
-- loading screen, and the first leg is dropped as soon as you reach its end.
--
-- Walking legs are priced on the straight line (x TERRAIN) first; then, out of combat and when the
-- walking router WLHelper_Nav is there (Trail.lua's WalkCost), the walking legs of the 3 best plans
-- are asked for their real length (3 questions at a time, 12 per destination, each pair once a
-- session) and the plan is made again as answers come: it changes only when the new best is more
-- than 10% faster than the plan you follow, so the arrow does not flip between two equal ways.
-- GPS.Itinerary() / GPS.ItinerarySummary() say the whole way in one line ("Pierre de foyer → vol
-- jusqu'à Kargath → 300 m à pied").
--
-- Positions are world coordinates (yards) from C_Map.GetWorldPosFromMapPos. The fixed points
-- (docks, teleport landings, your flight masters) are converted once and kept.
local ADDON, root = ...
root.Writs = root.Writs or {}
local ns = root.Writs
local WP = ns.WP
local L = ns.L

local GPS = {}
WP.GPS = GPS

ns.AddEnglish({
    ["Va au maître de vol de %s"] = "Go to the flight master at %s",
    ["Va au bateau pour %s"] = "Go to the boat to %s",
    ["Va au zeppelin pour %s"] = "Go to the zeppelin to %s",
    ["Rejoins %s"] = "Go to %s",
    ["Prends le vol pour %s"] = "Take the flight to %s",
    ["Prends le bateau pour %s"] = "Take the boat to %s",
    ["Prends le zeppelin pour %s"] = "Take the zeppelin to %s",
    ["Téléportation : %s"] = "Teleport: %s",
    ["Puis le maître de vol de %s"] = "Then the flight master at %s",
    ["Puis le bateau pour %s"] = "Then the boat to %s",
    ["Puis le zeppelin pour %s"] = "Then the zeppelin to %s",
    ["Puis le vol pour %s"] = "Then the flight to %s",
    ["Puis la téléportation : %s"] = "Then teleport: %s",
    ["Puis %s"] = "Then %s",
    ["Lieu de remise inconnu pour %s : ouvre l'enveloppe pour voir sa quête."] = "Turn-in spot unknown for %s: open the envelope to see its quest.",
    ["Impossible de guider vers ce point : la carte de cette zone n'est pas lisible."] = "Can't guide you there: this zone's map can't be read.",
    ["Le GPS ne connaît pas encore tes points de vol : parle à un maître de vol pour qu'il les apprenne."] =
        "The GPS doesn't know your flight paths yet: talk to a flight master so it can learn them.",
    ["Tournée GPS terminée : plus aucun Writ prêt à rendre."] = "GPS tour finished: no Writ left to turn in.",
    ["GPS : en route vers %s (%s %.0f, %.0f) pour rendre %s."] = "GPS: on the way to %s (%s %.0f, %.0f) to turn in %s.",
    ["le lieu de remise"] = "the turn-in spot",
    ["C'est le dernier Writ à rendre."] = "It's the last Writ to turn in.",
    ["%d Writs à rendre en tout."] = "%d Writs to turn in altogether.",
    ["Ouvre son enveloppe avant d'arriver."] = "Open its envelope before you get there.",
    ["Pierre de foyer"] = "Hearthstone",
    ["Rappel astral"] = "Astral Recall",
    ["Pierre de foyer : %s"] = "Hearthstone: %s",
    ["Rappel astral : %s"] = "Astral Recall: %s",
    ["Puis la pierre de foyer : %s"] = "Then the Hearthstone: %s",
    ["Puis le rappel astral : %s"] = "Then Astral Recall: %s",
    ["vol jusqu'à %s"] = "flight to %s",
    ["bateau pour %s"] = "boat to %s",
    ["zeppelin pour %s"] = "zeppelin to %s",
    ["téléportation à %s"] = "teleport to %s",
    ["%s à pied"] = "%s on foot",
    ["%s en monture"] = "%s ride",
})

-- "Brackenwall Village, Dustwallow Marsh" -> "Brackenwall Village": the place without its zone, for
-- the lines that must stay short (the full name stays in the arrow's tooltip).
function GPS.ShortPlace(name)
    if type(name) ~= "string" then return name or "?" end
    return name:match("^(.-),%s") or name
end
-- First letter in capital (also an accented one), for a name that starts a line.
local function UpperFirst(s)
    if type(s) ~= "string" or s == "" then return s or "" end
    if s:sub(1, 2) == "\195\169" then return "\195\137" .. s:sub(3) end
    return (s:gsub("^%l", string.upper))
end
GPS.UpperFirst = UpperFirst

-- Zeppelins and boats: both ends (uiMapID, x, y in percent), what it is, who may take it.
local LINKS = {
    { a = { 1420, 60.70, 58.76 }, b = { 1411, 50.82, 13.81 }, mode = "zeppelin", side = "Horde", nameA = "Undercity", nameB = "Orgrimmar" },
    { a = { 1420, 61.88, 59.10 }, b = { 1434, 31.53, 29.15 }, mode = "zeppelin", side = "Horde", nameA = "Undercity", nameB = "Grom'gol" },
    { a = { 1411, 50.57, 12.66 }, b = { 1434, 31.35, 30.12 }, mode = "zeppelin", side = "Horde", nameA = "Orgrimmar", nameB = "Grom'gol" },
    { a = { 1434, 25.92, 73.15 }, b = { 1413, 63.66, 38.65 }, mode = "boat", nameA = "Booty Bay", nameB = "Ratchet" },
    { a = { 1453, 22.60, 56.13 }, b = { 1439, 30.76, 41.00 }, mode = "boat", side = "Alliance", nameA = "Stormwind", nameB = "Auberdine" },
    { a = { 1437, 5.08, 63.40 }, b = { 1445, 71.54, 56.34 }, mode = "boat", side = "Alliance", nameA = "Menethil Harbor", nameB = "Theramore" },
    -- a druid's flight home from Moonglade (one way, gossip with the NPC): ends in world yards (continent,
    -- north, west), from LibForeverData 2026.11.1's spawns of Bunthen Plainswind / Silva Fil'naveth
    -- (Moonglade) and Tal (Thunder Bluff) / Vesprystus (Rut'theran Village)
    { wa = { 1, 7785.5, -2403.5 }, wb = { 1, -1197.5, 23.5 }, mode = "flight", side = "Horde", class = "DRUID", oneWay = true,
      nameA = "Moonglade", nameB = "Thunder Bluff" },
    { wa = { 1, 7795.5, -2400.5 }, wb = { 1, 8640.5, 841.0 }, mode = "flight", side = "Alliance", class = "DRUID", oneWay = true,
      nameA = "Moonglade", nameB = "Rut'theran Village" },
}
-- Teleports: spell, where it lands; a mage's need a Rune of Teleportation.
local TELEPORTS = {
    { spell = 3567, map = 1454, x = 38.57, y = 85.95, side = "Horde", name = "Orgrimmar", rune = true },
    { spell = 3563, map = 1458, x = 84.65, y = 16.32, side = "Horde", name = "Undercity", rune = true },
    { spell = 3566, map = 1456, x = 22.35, y = 16.52, side = "Horde", name = "Thunder Bluff", rune = true },
    { spell = 3561, map = 1453, x = 38.01, y = 80.84, side = "Alliance", name = "Stormwind", rune = true },
    { spell = 3562, map = 1455, x = 25.52, y = 8.41, side = "Alliance", name = "Ironforge", rune = true },
    { spell = 3565, map = 1457, x = 40.13, y = 81.83, side = "Alliance", name = "Darnassus", rune = true },
    { spell = 18960, map = 1450, x = 56.26, y = 32.46, name = "Moonglade" },
}
local RUNE = 17031
-- The Hearthstone (item, and the spell it casts) and a shaman's Astral Recall: both to your inn.
local HEARTH_ITEM, HEARTH_SPELL, ASTRAL_RECALL = 6948, 8690, 556
local HEARTH_COOLDOWN = 3600       -- seconds: the Hearthstone's cooldown, when the client hides it

-- The inns: innkeeper's NPC id, continent, world yards (north, west), then the names GetBindLocation
-- gives for that inn (its subzone; English, then French). Positions: LibForeverData 2026.11.1 (forever-db,
-- client 1.60.1.70532), every NPC whose subName is "Innkeeper" with a spawn (offline extract:
-- writ/inn_extract2.py + writ/inn_table.py). Names: only those known for sure; an inn without a name
-- here (the Forever ones) is still found once you bind there or come back by Hearthstone (learned,
-- WLWritsCharDB.hearthSpot). A bind location that matches nothing: no Hearthstone in the plans.
local INNS = {
    { 295, 0, -9462, 16, "Goldshire", "Comté-de-l'Or" },
    { 1247, 0, -5602, -532, "Kharanos" },
    { 1464, 0, -3828, -832, "Menethil Harbor", "Port de Menethil" },
    { 2352, 0, -857, -571, "Southshore", "Austrivage" },
    { 2388, 0, -6, -942, "Tarren Mill", "Moulin-de-Tarren" },
    { 3934, 1, -407, -2646, "The Crossroads", "Crossroads", "La Croisée" },
    { 5111, 0, -4840, -857, "Ironforge", "Forgefer" },
    { 5688, 0, 2270, 244, "Brill" },
    { 5814, 0, -12434, 212, "Grom'gol Base Camp", "Grom'gol", "Camp de base de Grom'gol", "Campement Grom'gol" },
    { 6272, 1, -3616, -4471, "Theramore Isle", "Theramore", "Île de Theramore" },
    { 6727, 0, -9224, -2157, "Lakeshire", "Comté-du-Lac" },
    { 6734, 0, -5378, -2974, "Thelsamar" },
    { 6735, 1, 10128, 2226, "Darnassus" },
    { 6736, 1, 9802, 982, "Dolanaar" },
    { 6737, 1, 6406, 516, "Auberdine" },
    { 6738, 1, 2781, -433, "Astranaar" },
    { 6739, 0, 511, 1636, "The Sepulcher", "Le Sépulcre" },
    { 6740, 0, -8868, 674, "Stormwind City", "Stormwind", "Trade District", "Hurlevent", "Cité de Hurlevent", "Quartier commerçant" },
    { 6741, 0, 1636, 224, "Undercity", "Fossoyeuse" },
    { 6746, 1, -1300, 39, "Thunder Bluff", "Les Pitons-du-Tonnerre", "Pitons-du-Tonnerre" },
    { 6747, 1, -2365, -348, "Bloodhoof Village", "Village de Sabot-de-Sang" },
    { 6790, 0, -10516, -1161, "Darkshire", "Sombre-Comté" },
    { 6791, 1, -1050, -3665, "Ratchet", "Cabestan" },
    { 6807, 0, -14458, 496, "Booty Bay", "Baie-du-Butin" },
    { 6928, 1, 340, -4686, "Razor Hill", "Tranchecolline" },
    { 6929, 1, 1634, -4440, "Orgrimmar", "Valley of Strength", "Vallée de la Force" },
    { 6930, 0, -10488, -3259, "Stonard", "Pierrêche" },
    { 7714, 1, -2376, -1996, "Camp Taurajo" },
    { 7731, 1, 894, 928, "Sun Rock Retreat", "Retraite de Roche-Soleil" },
    { 7733, 1, -7159, -3842, "Gadgetzan" },
    { 7736, 1, -4382, 3290, "Feathermoon Stronghold", "Bastion de Pennelune" },
    { 7737, 1, -4460, 243, "Camp Mojache" },
    { 7744, 0, 400, -2120, "Aerie Peak", "Nid-de-l'Aigle" },
    { 8931, 0, -10653, 1166, "Sentinel Hill", "Colline des Sentinelles" },
    { 9356, 0, -6650, -2150, "Kargath" },
    { 9501, 0, -912, -3525, "Hammerfall", "Trépas-d'Orgrim" },
    { 11103, 1, 256, 1254, "Nijel's Point", "Pointe de Nijel", "Point de Nijel" },
    { 11106, 1, -1593, 3150, "Shadowprey Village" },
    { 11116, 1, -5478, -2460, "Freewind Post", "Poste de Librevent" },
    { 11118, 1, 6696, -4673, "Everlook", "Long-Guet" },
    { 12196, 1, 2342, -2567, "Splintertree Post", "Poste de Bois-Brisé" },
    { 14731, 0, -622, -4584, "Revantusk Village", "Village des Vengebroches" },
    { 15174, 1, -6868, 730, "Cenarion Hold", "Fort cénarien" },
    { 16256, 0, 2301, -5345, "Light's Hope Chapel", "Chapelle de l'Espoir de Lumière" },
    { 16458, 1, 2730, 1498, "Stonetalon Peak", "Pic des Serres-Rocheuses" },
    -- WoW Forever's own inns (no name in the data: learned in game)
    { 28687, 0, 257, 270 }, { 32413, 0, 262, 443 }, { 240482, 1, 2728, -3916 }, { 243815, 1, 5112, -3383 },
    { 244512, 1, 5082, -1374 }, { 252691, 1, -2889, 1123 }, { 254089, 2991, 3298, 1908 }, { 255894, 0, -8216, -5712 },
    { 255940, 2991, 2233, 774 }, { 256675, 0, -7922, -4704 }, { 257595, 0, -9190, -5028 }, { 258380, 1, 5138, -1464 },
}
GPS._INNS = INNS

local RUN, MOUNT = 7, 11.2         -- yards a second on foot and on a 60% mount
local TERRAIN = 1.3                -- roads and hills: a ride is longer than the straight line
local FLY, FLY_DETOUR, FLY_STOP = 30, 1.25, 20
local LINK_TIME, TELEPORT_TIME = 150, 15
local HEARTH_TIME = 25             -- 10 s cast, the loading screen, a few seconds to get going
local NEAR = 15                    -- yards: a leg's end reached
local REPLAN_EVERY = 8             -- seconds between two plans while guiding
local BIND_SNAP = 60               -- yards: binding this near a known inn takes that inn's spot
local CAST_NEAR = 100              -- yards: a teleport's or the Hearthstone's landing reached (the leg is done)
-- the router's walking lengths (Trail.WalkCost): legs from 60 to 3000 yards, 3 asked at a time, 12 per
-- destination; a new plan replaces the one you follow only when more than 10% faster
local WALK_MIN, WALK_MAX, WALK_PENDING, WALK_PER_DEST = 60, 3000, 3, 12
local WALK_CELL = 150              -- yards: where you stand, rounded, for the walks from you
local SWITCH = 0.10
local CANDIDATES, CANDIDATE_SPAN = 3, 2   -- plans whose walks are asked; slower than 2x the best: not asked

local function Opt(key, default)
    local o = WLWritsDB and WLWritsDB.gpsOpts
    local v = o and o[key]
    if v == nil then return default end
    return v
end

-- ---------------------------------------------------------------- positions

-- One map vector reused for every question (the arrow asks 20 times a second, the router once per
-- point): the game only reads it during the call, so no new table each time.
local scratchVec
local function World(map, x, y)   -- x, y from 0 to 1
    if not (C_Map and C_Map.GetWorldPosFromMapPos and CreateVector2D and map) then return end
    local v = scratchVec
    if v then
        if v.SetXY then v:SetXY(x, y) else v.x, v.y = x, y end
    else
        v = CreateVector2D(x, y)
        if type(v) == "table" then scratchVec = v end
    end
    local ok, cont, pos = pcall(C_Map.GetWorldPosFromMapPos, map, v)
    if ok and cont and pos and pos.GetXY then
        local wx, wy = pos:GetXY()
        return cont, wx, wy
    end
end

local function PlayerMapPos()
    local map = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
    if not map then return end
    local ok, pos = pcall(C_Map.GetPlayerMapPosition, map, "player")
    if not (ok and pos and pos.GetXY) then return end
    local x, y = pos:GetXY()
    return map, x, y
end

local function PlayerWorld()
    local map, x, y = PlayerMapPos()
    if map then return World(map, x, y) end
end

local function Dist(a, b)
    local dx, dy = a.wx - b.wx, a.wy - b.wy
    return math.sqrt(dx * dx + dy * dy)
end

local function Point(map, x, y, extra)   -- x, y in percent
    local cont, wx, wy = World(map, x / 100, y / 100)
    if not cont then return nil end
    local p = extra or {}
    p.cont, p.wx, p.wy, p.map, p.x, p.y = cont, wx, wy, map, x, y
    return p
end
GPS.Point = Point

-- A point already in world yards (continent, north, west).
local function WorldPoint(w, extra)
    if not w then return nil end
    local p = extra or {}
    p.cont, p.wx, p.wy = w[1], w[2], w[3]
    return p
end

local function IsSecret(v) return issecretvalue ~= nil and issecretvalue(v) end
local function InCombat() return InCombatLockdown and InCombatLockdown() and true or false end
local function Clock() return GetTime and GetTime() or 0 end

-- ---------------------------------------------------------------- fixed points, kept

local fixed   -- { taxi = {...}, docks = {...}, ports = {...} } for this faction, built once
local knownCount   -- flight paths recorded, counted once

local function PlayerClass()
    if not UnitClass then return nil end
    local ok, _, cls = pcall(UnitClass, "player")
    if ok and type(cls) == "string" and not IsSecret(cls) then return cls end
end

local function BuildFixed()
    local side = UnitFactionGroup("player")
    local cls = PlayerClass()
    fixed = { taxi = {}, docks = {}, ports = {} }
    for id, t in pairs(WLWritsCharDB.taxi or {}) do
        local p = Point(t.map, t.x, t.y, { kind = "taxi", name = t.name, nodeID = id })
        if p then fixed.taxi[#fixed.taxi + 1] = p end
    end
    for _, l in ipairs(LINKS) do
        if (not l.side or l.side == side) and (not l.class or l.class == cls) then
            local a, b
            if l.wa then
                a = WorldPoint(l.wa, { kind = "dock", name = l.nameA, link = l })
                b = WorldPoint(l.wb, { kind = "dock", name = l.nameB, link = l })
            else
                a = Point(l.a[1], l.a[2], l.a[3], { kind = "dock", name = l.nameA, link = l })
                b = Point(l.b[1], l.b[2], l.b[3], { kind = "dock", name = l.nameB, link = l })
            end
            if a then a.start = true end   -- the end you board at (a one-way link goes from here only)
            if a and b then
                a.other, b.other = b, a
                fixed.docks[#fixed.docks + 1] = a
                fixed.docks[#fixed.docks + 1] = b
            end
        end
    end
    for _, t in ipairs(TELEPORTS) do
        if not t.side or t.side == side then
            local p = Point(t.map, t.x, t.y, { kind = "port", name = t.name, spell = t.spell, rune = t.rune })
            if p then fixed.ports[#fixed.ports + 1] = p end
        end
    end
end

-- ---------------------------------------------------------------- flight paths you know

-- Recorded each time you open a flight map: every node it shows as reachable or current.
local function RecordTaxi()
    if not (C_TaxiMap and C_TaxiMap.GetAllTaxiNodes and GetTaxiMapID) then return end
    local mapID = GetTaxiMapID()
    local ok, nodes = pcall(C_TaxiMap.GetAllTaxiNodes, mapID)
    if not ok or type(nodes) ~= "table" then return end
    local unreachable = Enum and Enum.FlightPathState and Enum.FlightPathState.Unreachable or 2
    local db = WLWritsCharDB
    db.taxi = db.taxi or {}
    local added = false
    for _, n in ipairs(nodes) do
        if n.nodeID and n.position and n.position.GetXY and n.state ~= unreachable and not db.taxi[n.nodeID] then
            local x, y = n.position:GetXY()
            db.taxi[n.nodeID] = { name = n.name, map = mapID, x = x * 100, y = y * 100 }
            added = true
        end
    end
    if added then fixed, knownCount = nil, nil end
end

-- tests: the fixed points built again (faction, class, flight paths changed)
function GPS._ResetFixed() fixed, knownCount = nil, nil end

function GPS.KnownFlights()
    if not knownCount then
        knownCount = 0
        for _ in pairs(WLWritsCharDB.taxi or {}) do knownCount = knownCount + 1 end
    end
    return knownCount
end

-- ---------------------------------------------------------------- the route

local state = {}   -- dest, source, legs, eta, plannedAt, planFor (the guidance, below)

-- A cooldown's state from C_Spell.GetSpellCooldown (or the old GetSpellCooldown): true when ready,
-- false when cooling down, nil when the client tells nothing readable.
local function SpellCooldownReady(id)
    local start, duration
    if C_Spell and C_Spell.GetSpellCooldown then
        local ok, cd = pcall(C_Spell.GetSpellCooldown, id)
        if not (ok and type(cd) == "table") then return nil end
        -- the client may hide the numbers ("secret" values): its plain isActive flag tells then
        -- (the global cooldown is never long enough to matter for a teleport)
        if issecretvalue and (issecretvalue(cd.startTime) or issecretvalue(cd.duration)) then
            local okA, ready = pcall(function()
                if issecretvalue(cd.isActive) or cd.isActive == nil then return nil end
                local gcd = cd.isOnGCD
                if gcd ~= nil and issecretvalue(gcd) then gcd = false end
                return not (cd.isActive and not gcd)
            end)
            if okA then return ready end
            return nil
        end
        start, duration = cd.startTime, cd.duration
    elseif GetSpellCooldown then
        local ok, s, d = pcall(GetSpellCooldown, id)
        if ok then start, duration = s, d end
    end
    if start == nil or duration == nil then return nil end
    local ok, onCD = pcall(function() return start > 0 and duration > 1.5 end)
    if not ok then return nil end
    return not onCD
end

local function SpellKnown(id)
    local ok, known = pcall(function()
        return (IsPlayerSpell and IsPlayerSpell(id)) or (IsSpellKnown and IsSpellKnown(id))
    end)
    return ok and known and not IsSecret(known) and true or false
end

local function SpellReady(id)
    if not SpellKnown(id) then return false end
    -- unreadable: as before, a known spell counts as ready
    return SpellCooldownReady(id) ~= false
end
GPS._SpellReady = SpellReady

local function BagCount(id)
    local f = (C_Item and C_Item.GetItemCount) or GetItemCount
    if not f then return 0 end
    local ok, n = pcall(f, id)
    if not ok or type(n) ~= "number" or IsSecret(n) then return 0 end
    return n
end

-- The Hearthstone in your bags and off cooldown. Its item cooldown first (numbers may be secret on this
-- client: then unread), then the spell it casts (C_Spell's plain isActive), then the last time we saw you
-- use it (an hour). Unknown everywhere: ready (the game says so on the click).
local function HearthReady()
    if BagCount(HEARTH_ITEM) <= 0 then return false end
    local fn = (C_Container and C_Container.GetItemCooldown) or GetItemCooldown
    if fn then
        local ok, s, d = pcall(fn, HEARTH_ITEM)
        if ok and type(s) == "number" and type(d) == "number" and not IsSecret(s) and not IsSecret(d) then
            return not (s > 0 and d > 1.5)
        end
    end
    -- a use we saw beats the spell's answer: its cooldown may not follow the item's on this client
    local used = WLWritsCharDB and WLWritsCharDB.hearthUsed
    local nowT = time and time() or 0
    if type(used) == "number" and nowT - used < HEARTH_COOLDOWN then return false end
    local r = SpellCooldownReady(HEARTH_SPELL)
    if r ~= nil then return r end
    return true
end
GPS._HearthReady = HearthReady

local function RideSpeed()
    return (UnitLevel("player") or 1) >= 40 and MOUNT or RUN
end

-- ---------------------------------------------------------------- your inn

-- "The Crossroads" and "Crossroads", "Fort Cénarien" and "Fort cénarien" are the same inn.
local function Norm(s)
    if type(s) ~= "string" then return nil end
    s = s:lower():gsub("^%s+", ""):gsub("%s+$", "")
    s = s:gsub("^the%s+", ""):gsub("^la%s+", ""):gsub("^le%s+", ""):gsub("^les%s+", ""):gsub("^l'", "")
    return s
end

local innByName
local function InnByName(name)
    if not innByName then
        innByName = {}
        for _, t in ipairs(INNS) do
            for i = 5, #t do
                local k = Norm(t[i])
                if k and not innByName[k] then innByName[k] = t end
            end
        end
    end
    local k = Norm(name)
    return k and innByName[k]
end

local function BindName()
    if not GetBindLocation then return nil end
    local ok, name = pcall(GetBindLocation)
    if not ok or type(name) ~= "string" or IsSecret(name) or name == "" then return nil end
    return name
end

-- Where the Hearthstone takes you: the spot learned for this bind location (where you landed after a
-- Hearthstone, or the innkeeper you bound at), else the inn of that name in INNS. Unknown: nil.
local innPoint, innKey
function GPS.InnPoint()
    local name = BindName()
    if not name then return nil end
    local db = WLWritsCharDB
    local spot = db and db.hearthSpot
    local w
    if type(spot) == "table" and spot.bind == name and spot.cont and spot.wx and spot.wy then
        w = { spot.cont, spot.wx, spot.wy }
    else
        local bind = db and db.hearthBinder
        if type(bind) == "table" and bind.bind == name and bind.cont and bind.wx and bind.wy then
            w = { bind.cont, bind.wx, bind.wy }
        else
            local t = InnByName(name)
            if t then w = { t[2], t[3], t[4] } end
        end
    end
    if not w then return nil end
    local key = name .. ":" .. w[1] .. ":" .. w[2] .. ":" .. w[3]
    if innKey ~= key then
        innKey = key
        innPoint = WorldPoint(w, { kind = "inn", name = name })
    end
    return innPoint
end

-- The inn of INNS nearest to a world point, within `within` yards.
local function NearestInn(cont, wx, wy, within)
    local best, bestD
    for _, t in ipairs(INNS) do
        if t[2] == cont then
            local dx, dy = t[3] - wx, t[4] - wy
            local d = math.sqrt(dx * dx + dy * dy)
            if d <= within and (not bestD or d < bestD) then best, bestD = t, d end
        end
    end
    return best
end
GPS._NearestInn = NearestInn

-- ---------------------------------------------------------------- walking lengths (WLHelper_Nav)

-- walk[fromKey][toKey] = the walk's length over the straight line (>= 1), or false (the router could
-- not walk it: the straight line x TERRAIN stays). Kept for the session.
local walk = {}
local walkAsked = {}         -- fromKey .. ">" .. toKey -> true once asked (each pair once)
local walkPending, walkAsks, walkDirty, scheduling = 0, 0, false, false
local walkSentAt = 0          -- when the newest ask went out: answers lost for a minute free the slots

local function NodeKey(p)
    if p.kind == "start" then
        return "s" .. p.cont .. ":" .. math.floor(p.wx / WALK_CELL) .. ":" .. math.floor(p.wy / WALK_CELL)
    end
    if p._wk and p._wkx == p.wx and p._wky == p.wy then return p._wk end
    p._wk = p.cont .. ":" .. math.floor(p.wx + 0.5) .. ":" .. math.floor(p.wy + 0.5)
    p._wkx, p._wky = p.wx, p.wy
    return p._wk
end

local function WalkFactor(a, b)
    local row = walk[a._key or NodeKey(a)]
    local f = row and row[b._key or NodeKey(b)]
    return f or nil
end

-- Seconds to ride (or run) from a to b on one continent, and the straight yards.
local function RideCost(a, b, speed)
    local d = Dist(a, b)
    local f = WalkFactor(a, b)
    return d * (f or TERRAIN) / (speed or RideSpeed()), d
end

local function FlyCost(d) return d * FLY_DETOUR / FLY + FLY_STOP end

-- What the Hearthstone (or Astral Recall) may do now: the inn and how ("item" / spell id), or nil.
local function HearthWay(dead)
    if dead then return nil end
    local useStone = Opt("hearth", true) and HearthReady()
    local useRecall = not useStone and Opt("teleports", true) and SpellReady(ASTRAL_RECALL)
    if not (useStone or useRecall) then return nil end
    local inn = GPS.InnPoint()
    if not inn then return nil end
    if useStone then return inn, "item" end
    return inn, ASTRAL_RECALL
end

-- One Dijkstra over every pair of points (a few dozen), from where you stand. With `firstOnly` it
-- stops at the nearest of `dests`; otherwise it prices every destination. `exclude`: points left out
-- (the next best plans).
local function Search(dests, firstOnly, exclude)
    local cont, px, py = PlayerWorld()
    if not cont or not dests or #dests == 0 then return nil end
    if not fixed then BuildFixed() end
    -- a ghost runs to its corpse: no flight, no teleport
    local dead = UnitIsDeadOrGhost and UnitIsDeadOrGhost("player")
    local start = { cont = cont, wx = px, wy = py, kind = "start" }
    start._key = NodeKey(start)
    local nodes = { start }
    local isDest = {}
    local function Add(p)
        if exclude and exclude[p] then return end
        p._key = NodeKey(p)
        nodes[#nodes + 1] = p
    end
    for _, d in ipairs(dests) do d._key = NodeKey(d); nodes[#nodes + 1] = d; isDest[#nodes] = true end
    if not dead then
        for _, p in ipairs(fixed.taxi) do Add(p) end
    end
    for _, p in ipairs(fixed.docks) do Add(p) end
    if Opt("teleports", true) and not dead then
        local hasRune = BagCount(RUNE) > 0
        for _, p in ipairs(fixed.ports) do
            if (not p.rune or hasRune) and SpellReady(p.spell) then Add(p) end
        end
    end
    local inn, via = HearthWay(dead)
    if inn and exclude and exclude[inn] then inn = nil end
    if inn then Add(inn) end

    local n, speed = #nodes, RideSpeed()
    local cost, prev, how, done = {}, {}, {}, {}
    for i = 1, n do cost[i] = math.huge end
    cost[1] = 0
    local reached
    for _ = 1, n do
        local u, best = nil, math.huge
        for i = 1, n do if not done[i] and cost[i] < best then u, best = i, cost[i] end end
        if not u then break end
        if firstOnly and isDest[u] then reached = u; break end
        done[u] = true
        local a = nodes[u]
        local base = cost[u]
        for v = 1, n do
            if not done[v] then
                local b = nodes[v]
                local c, kind = math.huge, nil
                if a.cont == b.cont then
                    local d
                    c, d = RideCost(a, b, speed)
                    kind = "ride"
                    if a.kind == "taxi" and b.kind == "taxi" then
                        local f = FlyCost(d)
                        if f < c then c, kind = f, "fly" end
                    end
                end
                if a.kind == "dock" and a.other == b and (a.start or not a.link.oneWay) then
                    local lt = a.link.mode == "flight" and FlyCost(Dist(a, b)) or LINK_TIME
                    if lt < c then c, kind = lt, "link" end
                end
                if u == 1 and b.kind == "port" and TELEPORT_TIME < c then c, kind = TELEPORT_TIME, "teleport" end
                if u == 1 and b == inn and HEARTH_TIME < c then c, kind = HEARTH_TIME, "hearth" end
                if kind and base + c < cost[v] then cost[v], prev[v], how[v] = base + c, u, kind end
            end
        end
    end
    return nodes, cost, prev, how, reached, via
end

-- Seconds to each of `dests` from where you stand (nil when unreachable), in one search.
function GPS.CostsTo(dests)
    local _, cost = Search(dests, false)
    local out = {}
    if cost then
        for i = 1, #dests do
            local c = cost[i + 1]
            if c and c < math.huge then out[i] = c end
        end
    end
    return out
end

-- Fastest way from where you stand to the nearest of `dests` (Points). Returns the legs
-- { kind = "ride"|"fly"|"link"|"teleport"|"hearth", from, to, seconds }, the seconds it takes and the
-- destination reached. A "hearth" leg says how: item = 6948 (the Hearthstone) or spell = 556 (Astral
-- Recall). `exclude`: points the way may not use.
function GPS.FindPath(dests, exclude)
    local nodes, cost, prev, how, reached, via = Search(dests, true, exclude)
    if not reached then return nil end
    local legs, v = {}, reached
    while prev[v] do
        local leg = { kind = how[v], from = nodes[prev[v]], to = nodes[v], seconds = cost[v] - cost[prev[v]] }
        if leg.kind == "hearth" then
            if via == "item" then leg.item = HEARTH_ITEM else leg.spell = via end
        end
        table.insert(legs, 1, leg)
        v = prev[v]
    end
    -- A ride of a few yards (you already stand at the flight master or the dock) is no step.
    local out = {}
    for _, leg in ipairs(legs) do
        if not (leg.kind == "ride" and Dist(leg.from, leg.to) < NEAR and leg.to.kind ~= "dest") then out[#out + 1] = leg end
    end
    return out, cost[reached], nodes[reached]
end

-- What a plan costs now, from where you stand and with what is known now (the walks priced since,
-- a teleport gone on cooldown): nil when it can no longer be followed.
local function PlanCost(legs)
    if not legs or #legs == 0 then return nil end
    local cont, px, py = PlayerWorld()
    if not cont then return nil end
    local start = { cont = cont, wx = px, wy = py, kind = "start" }
    start._key = NodeKey(start)
    local dead = UnitIsDeadOrGhost and UnitIsDeadOrGhost("player")
    local speed = RideSpeed()
    local total, at = 0, start
    for i, leg in ipairs(legs) do
        local k = leg.kind
        if k == "teleport" or k == "hearth" then
            if i ~= 1 or dead then return nil end
            -- you stand at its landing: cast already, this plan is over (the new one starts here)
            if at.cont == leg.to.cont and Dist(at, leg.to) < CAST_NEAR then return nil end
            if k == "teleport" then
                if not (Opt("teleports", true) and SpellReady(leg.to.spell)) then return nil end
                if leg.to.rune and BagCount(RUNE) <= 0 then return nil end
                total = total + TELEPORT_TIME
            else
                local inn = HearthWay(dead)
                if not inn or inn ~= leg.to then return nil end
                total = total + HEARTH_TIME
            end
        else
            local from = leg.from
            if i == 1 then
                if k == "ride" then
                    from = at        -- the first ride starts where you stand now
                else
                    -- a flight or a boat first: you still have to reach its start
                    if at.cont ~= leg.from.cont then return nil end
                    if Dist(at, leg.from) >= NEAR then total = total + RideCost(at, leg.from, speed) end
                end
            end
            if k == "ride" then
                if from.cont ~= leg.to.cont then return nil end
                total = total + RideCost(from, leg.to, speed)
            elseif k == "fly" then
                total = total + FlyCost(Dist(from, leg.to))
            elseif k == "link" then
                total = total + (from.link and from.link.mode == "flight" and FlyCost(Dist(from, leg.to)) or LINK_TIME)
            end
        end
        at = leg.to
    end
    return total
end
GPS._PlanCost = PlanCost

local function Signature(legs)
    if not legs then return "" end
    local t = {}
    for i, leg in ipairs(legs) do t[i] = leg.kind .. "@" .. NodeKey(leg.to) end
    return table.concat(t, "|")
end

-- The walking legs of the best plans, asked to the router (Trail.WalkCost) out of combat: 3 at a time,
-- 12 per destination, each pair once a session. An answer prices the walk (its length over the straight
-- line) and the plan is made again (GPS.Replan keeps the plan you follow unless the new one is 10% faster).
local walkDest            -- the destination the asks count for
local function WalkLegs(legs, out)
    for _, leg in ipairs(legs or {}) do
        if leg.kind == "ride" and leg.from and leg.to and leg.from.cont == leg.to.cont then
            local d = Dist(leg.from, leg.to)
            if d >= WALK_MIN and d <= WALK_MAX then out[#out + 1] = leg end
        end
    end
end

local ReplanSoon
-- The walk the arrow follows is asked by Trail.lua already (its path): its length is kept here too, so
-- the leg you walk is never asked twice.
local trailHooked = false
local function HookTrail()
    if trailHooked or not (WP.Trail and WP.Trail.OnReady) then return end
    trailHooked = true
    WP.Trail.OnReady(function(t)
        if type(t) ~= "table" or not t.target or not t.askX or type(t.yards) ~= "number" then return end
        local tg = t.target
        if not (tg.cont and tg.wx and tg.wy) then return end
        local from = { cont = t.cont, wx = t.askX, wy = t.askY, kind = "start" }
        local straight = Dist(from, tg)
        if straight < WALK_MIN then return end
        local fk, tk = NodeKey(from), tg._key or NodeKey(tg)
        local r = walk[fk] or {}
        walk[fk] = r
        if r[tk] == nil then
            r[tk] = math.max(1, math.min(6, t.yards / straight))
            if ReplanSoon then ReplanSoon(0.1) end
        end
    end)
end

local function AskWalks(dest)
    HookTrail()
    if walkPending > 0 and Clock() - walkSentAt > 60 then walkPending = 0 end
    if not dest or walkPending >= WALK_PENDING or InCombat() then return end
    if walkDest ~= dest then walkDest, walkAsks = dest, 0 end
    if walkAsks >= WALK_PER_DEST then return end
    local T = WP.Trail
    if not (T and T.WalkCost) then return end
    if UnitIsDeadOrGhost and UnitIsDeadOrGhost("player") then return end
    -- the best plans: the best, then the best without its first stop, and so on
    local plans, exclude, best = {}, {}, nil
    for _ = 1, CANDIDATES do
        local legs, c = GPS.FindPath({ dest }, exclude)
        if not legs then break end
        if not best then best = c elseif c > best * CANDIDATE_SPAN then break end
        plans[#plans + 1] = legs
        local first = legs[1] and legs[1].to
        if not first or first == dest or first.kind == "dest" or exclude[first] then break end
        exclude[first] = true
    end
    local wanted = {}
    for _, legs in ipairs(plans) do WalkLegs(legs, wanted) end
    -- the first walk of the plan you follow: the arrow's own path (Trail.lua) measures it
    local following = state.legs and state.legs[1]
    if following and following.kind == "ride" and following.from and following.from.kind == "start" then
        for i = #wanted, 1, -1 do
            local w = wanted[i]
            if w.from.kind == "start" and (w.to == following.to) then table.remove(wanted, i) end
        end
    end
    scheduling = true
    for _, leg in ipairs(wanted) do
        if walkPending >= WALK_PENDING or walkAsks >= WALK_PER_DEST then break end
        local fromKey, toKey = leg.from._key or NodeKey(leg.from), leg.to._key or NodeKey(leg.to)
        local pair = fromKey .. ">" .. toKey
        local row = walk[fromKey]
        if not walkAsked[pair] and not (row and row[toKey] ~= nil) then
            walkAsked[pair] = true
            walkAsks, walkPending = walkAsks + 1, walkPending + 1
            walkSentAt = Clock()
            local straight = Dist(leg.from, leg.to)
            local from = { cont = leg.from.cont, wx = leg.from.wx, wy = leg.from.wy }
            local to = { cont = leg.to.cont, wx = leg.to.wx, wy = leg.to.wy }
            local answered = false
            local function Done(yards, why)
                if answered then return end
                answered = true
                walkPending = math.max(0, walkPending - 1)
                local r = walk[fromKey] or {}
                walk[fromKey] = r
                if type(yards) == "number" and not IsSecret(yards) and yards > 0 and straight > 0 then
                    r[toKey] = math.max(1, math.min(6, yards / straight))
                elseif why == "combat" or why == "nonav" or why == "busy" then
                    walkAsked[pair] = nil        -- not the walk's fault: asked again later
                else
                    r[toKey] = false
                end
                if scheduling then walkDirty = true else ReplanSoon(0.1) end
            end
            local ok, asked = pcall(T.WalkCost, from, to, Done)
            if not ok or not asked then
                -- the router is not there (or refused): nothing pending, nothing more asked this time
                if not answered then
                    answered = true
                    walkPending = math.max(0, walkPending - 1)
                    walkAsks = walkAsks - 1
                    walkAsked[pair] = nil
                end
                break
            end
        end
    end
    scheduling = false
    if walkDirty then walkDirty = false; ReplanSoon(0.1) end
end
function GPS._WalkReset() walk, walkAsked, walkPending, walkAsks, walkDest = {}, {}, 0, 0, nil end
function GPS._WalkState() return walk, walkPending, walkAsks end

-- ---------------------------------------------------------------- guidance

-- (state: declared with the route, above)

-- One leg in words ("Prends le vol pour Brackenwall Village"). full: keep the zone after a flight
-- master's name (for the tooltip); the arrow's lines use the short place.
local function LinkMode(leg)
    local l = (leg.from and leg.from.link) or (leg.to and leg.to.link)
    return l and l.mode
end
function GPS.Describe(leg, full)
    if not leg then return "" end
    local to = leg.to
    local function P(n) return full and (n or "?") or GPS.ShortPlace(n) end
    if leg.kind == "ride" then
        if to.kind == "taxi" then return string.format(L("Va au maître de vol de %s"), P(to.name)) end
        if to.kind == "dock" then
            if to.link.mode == "flight" then return string.format(L("Va au maître de vol de %s"), P(to.name)) end
            return string.format(to.link.mode == "boat" and L("Va au bateau pour %s") or L("Va au zeppelin pour %s"), P(to.other.name))
        end
        return string.format(L("Rejoins %s"), UpperFirst(to.name or "?"))
    elseif leg.kind == "fly" then
        return string.format(L("Prends le vol pour %s"), P(to.name))
    elseif leg.kind == "link" then
        local mode = LinkMode(leg)
        if mode == "flight" then return string.format(L("Prends le vol pour %s"), P(to.name)) end
        return string.format(mode == "boat" and L("Prends le bateau pour %s") or L("Prends le zeppelin pour %s"), P(to.name))
    elseif leg.kind == "teleport" then
        return string.format(L("Téléportation : %s"), P(to.name))
    elseif leg.kind == "hearth" then
        return string.format(leg.item and L("Pierre de foyer : %s") or L("Rappel astral : %s"), P(to.name))
    end
    return ""
end

-- The leg after the current one, as a line of its own: "Puis Tabetha", "Puis le vol pour Ratchet".
-- Names keep their capital letter.
function GPS.DescribeNext(leg)
    if not leg then return "" end
    local to = leg.to
    local P = GPS.ShortPlace
    if leg.kind == "ride" then
        if to.kind == "taxi" then return string.format(L("Puis le maître de vol de %s"), P(to.name)) end
        if to.kind == "dock" then
            if to.link.mode == "flight" then return string.format(L("Puis le maître de vol de %s"), P(to.name)) end
            return string.format(to.link.mode == "boat" and L("Puis le bateau pour %s") or L("Puis le zeppelin pour %s"), P(to.other.name))
        end
        return string.format(L("Puis %s"), UpperFirst(to.name or "?"))
    elseif leg.kind == "fly" then
        return string.format(L("Puis le vol pour %s"), P(to.name))
    elseif leg.kind == "link" then
        local mode = LinkMode(leg)
        if mode == "flight" then return string.format(L("Puis le vol pour %s"), P(to.name)) end
        return string.format(mode == "boat" and L("Puis le bateau pour %s") or L("Puis le zeppelin pour %s"), P(to.name))
    elseif leg.kind == "teleport" then
        return string.format(L("Puis la téléportation : %s"), P(to.name))
    elseif leg.kind == "hearth" then
        return string.format(leg.item and L("Puis la pierre de foyer : %s") or L("Puis le rappel astral : %s"), P(to.name))
    end
    return ""
end

-- ---------------------------------------------------------------- the itinerary

-- A distance as the arrow writes it ("300 m", "1,2 km", or yards when chosen): Arrow.lua's GPS.Distance.
local function DistanceText(yards)
    if GPS.Distance then
        local ok, t = pcall(GPS.Distance, yards)
        if ok and type(t) == "string" then return t end
    end
    local m = yards * 0.9144
    if m >= 1000 then
        local t = string.format("%.1f km", m / 1000)
        if ns.English and not ns.English() then t = t:gsub("%.", ",") end
        return t
    end
    if m >= 100 then m = math.floor(m / 10 + 0.5) * 10 end
    return string.format("%d m", math.floor(m + 0.5))
end

-- The whole way, leg by leg: { { kind = "walk"|"ride"|"fly"|"boat"|"zeppelin"|"teleport"|"hearth", text,
-- seconds, yards, leg }, ... }. `legs`: the plan to tell (default: the one followed now). The first walk
-- is measured from where you stand; a walk the router measured counts its real length.
function GPS.Itinerary(legs)
    legs = legs or state.legs
    local out = {}
    if type(legs) ~= "table" then return out end
    local cont, px, py = PlayerWorld()
    local speed = RideSpeed()
    for i, leg in ipairs(legs) do
        local to = leg.to or {}
        local P = GPS.ShortPlace(to.name)
        local item
        if leg.kind == "ride" then
            local yards, factor
            local from = leg.from
            if from and from.wx and to.wx and from.cont == to.cont then factor = WalkFactor(from, to) end
            if i == 1 and cont and to.cont == cont and to.wx then from = { cont = cont, wx = px, wy = py } end
            if from and from.wx and to.wx and from.cont == to.cont then
                yards = Dist(from, to) * (factor or 1)
            end
            local onFoot = speed <= RUN or (yards ~= nil and yards < 150)
            local d = yards and DistanceText(yards) or "?"
            item = { kind = onFoot and "walk" or "ride", yards = yards,
                text = string.format(onFoot and L("%s à pied") or L("%s en monture"), d) }
        elseif leg.kind == "fly" then
            item = { kind = "fly", text = string.format(L("vol jusqu'à %s"), P) }
        elseif leg.kind == "link" then
            local mode = LinkMode(leg)
            if mode == "flight" then
                item = { kind = "fly", text = string.format(L("vol jusqu'à %s"), P) }
            elseif mode == "boat" then
                item = { kind = "boat", text = string.format(L("bateau pour %s"), P) }
            else
                item = { kind = "zeppelin", text = string.format(L("zeppelin pour %s"), P) }
            end
        elseif leg.kind == "teleport" then
            item = { kind = "teleport", text = string.format(L("téléportation à %s"), P) }
        elseif leg.kind == "hearth" then
            item = { kind = "hearth", text = leg.item and L("Pierre de foyer") or L("Rappel astral") }
        end
        if item then
            item.seconds = type(leg.seconds) == "number" and leg.seconds or nil
            item.leg = leg
            out[#out + 1] = item
        end
    end
    return out
end

-- The whole way in one line: "Pierre de foyer → vol jusqu'à Kargath → 300 m à pied" (first word in
-- capital). Empty when there is no plan.
function GPS.ItinerarySummary(legs)
    local parts = {}
    for i, it in ipairs(GPS.Itinerary(legs)) do
        parts[#parts + 1] = i == 1 and UpperFirst(it.text) or it.text
    end
    return table.concat(parts, " \226\134\146 ")
end

local function Changed()
    if GPS.OnChanged then GPS.OnChanged() end
    if WP.RefreshHome then WP.RefreshHome() end
end

-- A new plan. The plan you follow stays unless the new one is more than 10% faster (both priced from
-- where you stand now, with every walk the router measured): two ways of about the same time do not
-- swap back and forth. A plan that can no longer be followed (a teleport gone on cooldown) is replaced.
function GPS.Replan()
    if not state.dest or state.zygor then return end
    if UnitOnTaxi and UnitOnTaxi("player") then return end
    local legs, eta = GPS.FindPath({ state.dest })
    local old = state.legs
    if legs and old and #old > 0 and state.planFor == state.dest and Signature(legs) ~= Signature(old) then
        local oldCost = PlanCost(old)
        if oldCost and eta >= oldCost * (1 - SWITCH) then legs, eta = old, oldCost end
    end
    state.legs, state.eta, state.planFor = legs, eta, state.dest
    -- "step 2 of 4" keeps counting across plans: legs already done plus the legs left
    if state.legs then state.legs.total = #state.legs + (state.doneLegs or 0) end
    state.plannedAt = GetTime()
    Changed()
    -- then the real walks of the best ways, asked in the background (never in combat)
    if state.legs then pcall(AskWalks, state.dest) end
end

-- Zygor's travel system, when the options ask for it (or "auto" and it is on).
local function Zygor()
    local Z = rawget(_G, "ZGV")
    if type(Z) == "table" and type(Z.Pointer) == "table" and Z.Pointer.SetWaypoint and Z.Pointer.ArrowFrame then return Z end
end
function GPS.UseZygor()
    local Z = Zygor()
    if not Z then return false end
    -- only when the player picked Zygor: on "auto" our point used to replace the waypoint of the
    -- Zygor guide the player was following, and our stop button was hidden with our arrow
    return Opt("provider", "auto") == "zygor"
end

-- Several events in a row (a loading screen fires a few) make one plan.
local replanQueued = false
function ReplanSoon(delay)
    if replanQueued or not state.dest then return end
    replanQueued = true
    C_Timer.After(delay or 0.5, function() replanQueued = false; GPS.Replan() end)
end

-- The replan clock runs only while guiding.
local ticker
local function Tick()
    if state.dest and not state.zygor and not (UnitOnTaxi and UnitOnTaxi("player"))
        and GetTime() - (state.plannedAt or 0) >= REPLAN_EVERY then
        GPS.Replan()
    end
end

local function Start(dest, source)
    -- a place the player chose (a Comptoir detour, /way, "Aller à", a key) keeps the dungeon guide's
    -- point, given back when it ends
    if source ~= "dungeon" and state.source == "dungeon" and state.dest then
        state.suspended = state.dest
    elseif source == "dungeon" then
        state.suspended = nil
    end
    state.dest, state.source, state.doneLegs, state.zygor = dest, source, 0, nil
    if not ticker then ticker = C_Timer.NewTicker(2, Tick) end
    if GPS.UseZygor() then
        local Z = Zygor()
        local ok = pcall(Z.Pointer.SetWaypoint, Z.Pointer, dest.map, dest.x / 100, dest.y / 100, {
            title = dest.name, type = "manual", cleartype = true, findpath = true,
            onminimap = "always", overworld = true, showonedge = true,
        }, true)
        if ok then
            state.zygor = true
            if GPS.Hide then GPS.Hide() end
            Changed()
            return
        end
    end
    GPS.Replan()
    if GPS.Show then GPS.Show() end
end

-- Guides you to a writ's turn-in spot (the Comptoir).
function GPS.Go(w)
    if not (w and w.map) then
        if w then WP.Print(string.format(L("Lieu de remise inconnu pour %s : ouvre l'enveloppe pour voir sa quête."), WP.ItemName(w.writ, w.writName))) end
        return
    end
    local dest = Point(w.map, w.x, w.y, { kind = "dest", name = w.npcName or WP.ItemName(w.item, w.itemName), writ = w })
    if not dest then
        WP.Print(L("Impossible de guider vers ce point : la carte de cette zone n'est pas lisible."))
        return
    end
    Start(dest, "writs")
    if C_Map and C_Map.SetUserWaypoint and UiMapPoint then
        pcall(C_Map.SetUserWaypoint, UiMapPoint.CreateFromCoordinates(w.map, w.x / 100, w.y / 100))
        -- remembered so GPS.Stop clears this pin (and not one the player placed since)
        state.pin = { map = w.map, x = w.x / 100, y = w.y / 100 }
    end
    if GPS.KnownFlights() == 0 then WP.Print(L("Le GPS ne connaît pas encore tes points de vol : parle à un maître de vol pour qu'il les apprenne.")) end
end

-- The guide's step while the player follows a place of their own choice: kept for later (GPS.Stop
-- gives it back), never put over theirs. True when the point was kept aside.
local function Waiting(map, x, y, label, source)
    if source ~= "dungeon" or not state.dest or not state.source or state.source == "dungeon" then return false end
    local p = Point(map, x, y, { kind = "dest", name = label, waited = true })
    if p then state.suspended = p end
    return true
end
GPS._Waiting = Waiting

-- Guides you to any point (the dungeon guide's steps): map, x, y in percent, a label. The same point
-- again changes nothing, so the guide may call it as often as it likes; it never takes over a place
-- the player chose (writ tour, /way, "Aller à", a key): it waits until that one ends.
function GPS.GoPoint(map, x, y, label, source)
    if Waiting(map, x, y, label, source) then return end
    local d = state.dest
    if d and d.map == map and d.x == x and d.y == y and state.source == source then return end
    local dest = Point(map, x, y, { kind = "dest", name = label })
    if not dest then GPS.Stop(source); return end
    Start(dest, source)
end

-- Stops the GPS; with a source, only if the GPS is guiding for that source.
function GPS.Stop(source)
    if source and state.source ~= source then
        -- the guide closed while the player's place runs: its waiting step goes too
        if source == "dungeon" then state.suspended = nil end
        return
    end
    local resume = state.source ~= "dungeon" and state.suspended
    if state.zygor then
        local Z = Zygor()
        if Z and Z.Pointer.ClearWaypoints then pcall(Z.Pointer.ClearWaypoints, Z.Pointer, "manual") end
    end
    if state.pin and C_Map and C_Map.ClearUserWaypoint then
        local ok, p = pcall(C_Map.GetUserWaypoint or function() end)
        local pos = ok and p and p.position
        if not (ok and p) or (pos and p.uiMapID == state.pin.map and math.abs(pos.x - state.pin.x) < 0.001
            and math.abs(pos.y - state.pin.y) < 0.001) then
            pcall(C_Map.ClearUserWaypoint)
        end
    end
    state.pin = nil
    state.dest, state.source, state.legs, state.eta, state.zygor, state.suspended = nil, nil, nil, nil, nil, nil
    -- the walking path and its dots go with it
    if WP.Trail and WP.Trail.Clear then WP.Trail.Clear() end
    if ticker then ticker:Cancel(); ticker = nil end
    if GPS.Hide then GPS.Hide() end
    -- back to the dungeon step the detour interrupted, if the guide still wants its arrow
    if resume and WLDTDB and WLDTDB.arrow ~= false and not WLDTDB.hidden then
        -- a step that waited is asked again as the guide asked it (an NPC's marker walks its path again)
        if resume.waited then GPS.GoPoint(resume.map, resume.x, resume.y, resume.name, "dungeon")
        else Start(resume, "dungeon") end
    end
end

function GPS.Active() return state.dest ~= nil end
function GPS.DestName() return state.dest and state.dest.name end
-- The point guided to (map, x, y in percent, name), or nil: read it, do not change it.
function GPS.Dest() return state.dest end
function GPS.Source() return state.source end

-- What the arrow shows now. The first leg is dropped once you reach its end. The answer is one
-- table, filled again on each call (the arrow asks several times a second): read it, don't keep it.
local now = {}
local function DistFrom(cont, px, py, p)
    if p and cont and cont == p.cont then
        local dx, dy = p.wx - px, p.wy - py
        return math.sqrt(dx * dx + dy * dy)
    end
end
function GPS.Now()
    if not state.dest or state.zygor then return nil end
    local map, mx, my = PlayerMapPos()
    local cont, px, py
    if map then cont, px, py = World(map, mx, my) end
    local legs = state.legs
    local leg = legs and legs[1]
    if leg and leg.kind == "ride" and #legs > 1 then
        local d = DistFrom(cont, px, py, leg.to)
        if d and d < NEAR then
            table.remove(legs, 1)
            state.doneLegs = (state.doneLegs or 0) + 1
            leg = legs[1]
            Changed()
        end
    end
    -- a teleport or the Hearthstone cast: you stand at its landing, the leg is done (no button again)
    if leg and (leg.kind == "teleport" or leg.kind == "hearth") and #legs > 1 then
        local d = DistFrom(cont, px, py, leg.to)
        if d and d < CAST_NEAR then
            table.remove(legs, 1)
            state.doneLegs = (state.doneLegs or 0) + 1
            leg = legs[1]
            Changed()
        end
    end
    local target
    if not leg then target = state.dest
    elseif leg.kind == "ride" then target = leg.to
    elseif leg.kind == "fly" or leg.kind == "link" then target = leg.from end
    local dist = DistFrom(cont, px, py, target)
    local last = not legs or #legs == 0 or (#legs == 1 and leg.kind == "ride")
    now.leg, now.legs, now.target, now.dist, now.eta = leg, legs, target, dist, state.eta
    now.dest, now.source = state.dest, state.source
    now.arrived = last and dist ~= nil and dist < NEAR
    now.map, now.cont, now.px, now.py = map, cont, px, py   -- for GPS.Bearing, no second lookup
    -- a walking leg with a path from the walking router (Trail.lua): the arrow points at the path's
    -- next corner and the distance is the walk left along it (now.straight keeps the straight line)
    now.trail, now.straight = nil, dist
    if WP.Trail and WP.Trail.Apply then WP.Trail.Apply(now) end
    return now
end

-- North and east on a map, as world vectors: constant per map, so kept.
local axes = {}
local function Axes(map)
    local a = axes[map]
    if a == nil then
        local c0, x0, y0 = World(map, 0.5, 0.5)
        local _, xn, yn = World(map, 0.5, 0.49)
        local _, xe, ye = World(map, 0.51, 0.5)
        a = false
        if c0 and xn and xe then
            local nx, ny, ex, ey = xn - x0, yn - y0, xe - x0, ye - y0
            local nl, el = math.sqrt(nx * nx + ny * ny), math.sqrt(ex * ex + ey * ey)
            if nl > 0 and el > 0 then a = { nx / nl, ny / nl, ex / el, ey / el } end
        end
        axes[map] = a
    end
    return a or nil
end

-- Heading from you to a world point against your facing (radians, counter-clockwise). `at` may
-- carry your position already (GPS.Now's answer: map, cont, px, py).
function GPS.Bearing(target, at)
    local map, c0, x0, y0
    if at and at.map then
        map, c0, x0, y0 = at.map, at.cont, at.px, at.py
    else
        local x, y
        map, x, y = PlayerMapPos()
        if map then c0, x0, y0 = World(map, x, y) end
    end
    if not (map and target) then return nil end
    local a = Axes(map)
    if not (a and c0) or c0 ~= target.cont then return nil end
    local facing = GetPlayerFacing and GetPlayerFacing()
    if not facing then return nil end
    local dx, dy = target.wx - x0, target.wy - y0
    local north = dx * a[1] + dy * a[2]
    local east = dx * a[3] + dy * a[4]
    return math.atan2(-east, north) - facing
end

function GPS.FlightLeg()
    local leg = state.legs and state.legs[1]
    return leg and leg.kind == "fly" and leg or nil
end

-- The first leg when it is cast (a teleport, the Hearthstone, Astral Recall), else nil.
function GPS.TeleportLeg()
    local leg = state.legs and state.legs[1]
    return leg and (leg.kind == "teleport" or leg.kind == "hearth") and leg or nil
end

-- What a cast leg uses: "item", 6948 (the Hearthstone) or "spell", id (a teleport, Astral Recall).
function GPS.CastOf(leg)
    if not leg then return nil end
    if leg.kind == "hearth" then
        if leg.item then return "item", leg.item end
        return "spell", leg.spell
    end
    if leg.kind == "teleport" and leg.to then return "spell", leg.to.spell end
end

-- Takes the planned flight while the flight map is open (the arrow's button, or by itself).
function GPS.TakeFlight()
    local leg = GPS.FlightLeg()
    if not (leg and C_TaxiMap and GetTaxiMapID and TakeTaxiNode) then return end
    local ok, nodes = pcall(C_TaxiMap.GetAllTaxiNodes, GetTaxiMapID())
    if not ok or type(nodes) ~= "table" then return end
    for _, n in ipairs(nodes) do
        if n.nodeID == leg.to.nodeID and n.slotIndex then TakeTaxiNode(n.slotIndex); return end
    end
end

-- The planned landing on the flight map: a pulsing gold ring around its node and its name, so
-- the player sees where to click (the game's own map, nothing of it replaced).
local ring
local function TaxiTarget()
    local leg = GPS.FlightLeg()
    if not (leg and C_TaxiMap and GetTaxiMapID) then return end
    local ok, nodes = pcall(C_TaxiMap.GetAllTaxiNodes, GetTaxiMapID())
    if not ok or type(nodes) ~= "table" then return end
    for _, n in ipairs(nodes) do
        if n.nodeID == leg.to.nodeID and n.slotIndex then return n.slotIndex, n.name end
    end
end
local function TaxiButtonFor(slot)
    -- the classic flight map: TaxiButton1..n; the modern one: pins that carry the node's data
    local b = _G["TaxiButton" .. slot]
    if b and b:IsShown() then return b end
    if FlightMapFrame and FlightMapFrame:IsShown() and FlightMapFrame.EnumerateAllPins then
        for pin in FlightMapFrame:EnumerateAllPins() do
            local d = pin.taxiNodeData
            if d and d.slotIndex == slot then return pin end
        end
    end
end
function GPS.MarkTaxi()
    if ring then ring:Hide() end
    local slot, name = TaxiTarget()
    local btn = slot and TaxiButtonFor(slot)
    if not btn then return end
    if not ring then
        ring = CreateFrame("Frame", nil, UIParent)
        ring:SetSize(46, 46)
        ring.t = ring:CreateTexture(nil, "OVERLAY")
        ring.t:SetAllPoints()
        ring.t:SetTexture("Interface\\AddOns\\WLHelper\\Media\\Icons\\ring")
        ring.t:SetVertexColor(1, 0.82, 0.25)
        ring.label = ring:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        ring.label:SetPoint("TOP", ring, "BOTTOM", 0, 2)
        ring.label:SetTextColor(1, 0.86, 0.35)
        ring.label:SetShadowOffset(1, -1)
        local ag = ring:CreateAnimationGroup(); ag:SetLooping("BOUNCE")
        local a1 = ag:CreateAnimation("Alpha"); a1:SetFromAlpha(1); a1:SetToAlpha(0.35); a1:SetDuration(0.7)
        local s1 = ag:CreateAnimation("Scale"); s1:SetScaleFrom(1, 1); s1:SetScaleTo(1.15, 1.15); s1:SetDuration(0.7)
        ring.anim = ag
    end
    ring:SetParent(btn); ring:SetFrameStrata("DIALOG")
    ring:ClearAllPoints(); ring:SetPoint("CENTER", btn, "CENTER")
    ring.label:SetText(name and (name:gsub(",.*$", "")) or "")
    ring:Show(); ring.anim:Play()
end
function GPS.UnmarkTaxi() if ring then ring.anim:Stop(); ring:Hide() end end

-- ---------------------------------------------------------------- the GPS tour

-- Writs to hand in now: ready ones, and envelopes still to open whose items you hold,
-- on a known spot in a zone your level can reach.
function WP.Stops(rows)
    local stops = {}
    for _, r in ipairs(rows or WP.Rows()) do
        local w = r.w
        if w.map and not r.tooHigh and (r.state == "ready" or (r.state == "bag" and r.ownItem)) then
            stops[#stops + 1] = r
        end
    end
    return stops
end

-- The stop the route reaches soonest: one search toward all of them.
function WP.NextStop(rows)
    local stops = WP.Stops(rows)
    if #stops == 0 then return nil, 0 end
    local dests, byDest = {}, {}
    for _, r in ipairs(stops) do
        local p = Point(r.w.map, r.w.x, r.w.y, { kind = "dest" })
        if p then dests[#dests + 1] = p; byDest[p] = r end
    end
    local _, _, reached = GPS.FindPath(dests)
    return reached and byDest[reached] or stops[1], #stops
end

function WP.GoNext()
    local stop, count = WP.NextStop()
    if not stop then
        WLWritsCharDB.gps = false
        GPS.Stop("writs")
        WP.Print(L("Tournée GPS terminée : plus aucun Writ prêt à rendre."))
        if WP.OnGPSChanged then WP.OnGPSChanged() end
        return
    end
    local w = stop.w
    GPS.Go(w)
    local msg = string.format(L("GPS : en route vers %s (%s %.0f, %.0f) pour rendre %s."), w.npcName or L("le lieu de remise"),
        WP.ZoneName(w.map), w.x, w.y, WP.ItemName(w.item, w.itemName))
    msg = msg .. " " .. (count == 1 and L("C'est le dernier Writ à rendre.") or string.format(L("%d Writs à rendre en tout."), count))
    if stop.state == "bag" then msg = msg .. " " .. L("Ouvre son enveloppe avant d'arriver.") end
    WP.Print(msg)
end

function WP.ToggleGPS()
    if not WLWritsCharDB.gps and WP.ModuleOff("writs") then return end
    local db = WLWritsCharDB
    db.gps = not db.gps
    if db.gps then WP.GoNext() else GPS.Stop("writs") end
    if WP.OnGPSChanged then WP.OnGPSChanged() end
end

-- Stops whatever the GPS is guiding to. A dungeon point: the guide's arrow is turned off (the
-- guide's menu shows it, and the next step does not bring it back). A writ: the tour stops too.
function WP.StopGPS()
    if GPS.Source() == "dungeon" then
        if root.ToggleArrow and WLDTDB and WLDTDB.arrow ~= false then root.ToggleArrow() else GPS.Stop() end
    else
        if WLWritsCharDB then WLWritsCharDB.gps = false end
        GPS.Stop()
        if WP.OnGPSChanged then WP.OnGPSChanged() end
    end
    if WP.RefreshHome then WP.RefreshHome() end
    if root.Render then root.Render() end
end

-- /wlh gps: stops the GPS when it guides; otherwise the dungeon arrow comes back if a route is
-- running, else the Comptoir's tour starts.
function WP.StopOrStartGPS()
    if GPS.Active() then WP.StopGPS(); return end
    local guideOn = not root.GuideOn or root.GuideOn()
    if guideOn and root.GuideStatus and root.GuideStatus() and WLDTDB and WLDTDB.arrow == false and root.ToggleArrow then
        root.ToggleArrow()
        if root.Render then root.Render() end
    else
        WP.ToggleGPS()
    end
end

-- A click on a writ: the GPS to that writ alone.
function WP.TravelTo(w)
    GPS.Go(w)
end

-- ---------------------------------------------------------------- events

local writOfQuest   -- quest ID -> writ, built on the first turn-in
local f = CreateFrame("Frame")
pcall(f.RegisterEvent, f, "PLAYER_LOGIN")
pcall(f.RegisterEvent, f, "QUEST_TURNED_IN")
pcall(f.RegisterEvent, f, "TAXIMAP_OPENED")
pcall(f.RegisterEvent, f, "TAXIMAP_CLOSED")
pcall(f.RegisterEvent, f, "ZONE_CHANGED_NEW_AREA")
pcall(f.RegisterEvent, f, "PLAYER_CONTROL_GAINED")
pcall(f.RegisterEvent, f, "LOADING_SCREEN_DISABLED")
-- your inn: learned where you bind (CONFIRM_BINDER: the innkeeper's question, with the inn's name) and
-- where a Hearthstone or Astral Recall lands you
pcall(f.RegisterEvent, f, "CONFIRM_BINDER")
pcall(f.RegisterUnitEvent or f.RegisterEvent, f, "UNIT_SPELLCAST_SUCCEEDED", "player")
pcall(f.RegisterEvent, f, "PLAYER_REGEN_ENABLED")

-- Where you stand, as a world point with no secret in it.
local function Here()
    local cont, wx, wy = PlayerWorld()
    if not cont or IsSecret(cont) or IsSecret(wx) or IsSecret(wy) then return nil end
    return cont, wx, wy
end

-- You talk to an innkeeper about binding: the inn nearest to you (or where you stand) for that name,
-- used once GetBindLocation gives that name.
function GPS._OnBinder(area)
    if type(area) ~= "string" or IsSecret(area) or area == "" or not WLWritsCharDB then return end
    local cont, wx, wy = Here()
    if not cont then return end
    local t = NearestInn(cont, wx, wy, BIND_SNAP)
    if t then cont, wx, wy = t[2], t[3], t[4] end
    WLWritsCharDB.hearthBinder = { bind = area, cont = cont, wx = wx, wy = wy }
end

-- After a Hearthstone or Astral Recall: where you landed is your inn for this bind location.
local landing
local castCont, castX, castY    -- where the Hearthstone or Astral Recall was cast
function GPS._OnLanded()
    if not landing or not WLWritsCharDB then return end
    if Clock() - landing > 120 then landing = nil; return end
    if UnitOnTaxi and UnitOnTaxi("player") then return end
    local name = BindName()
    local cont, wx, wy = Here()
    if not (name and cont) then return end
    -- still where you cast (the loading screen not over, the old map still reported): wait
    if castCont and castCont == cont and math.sqrt((wx - castX) ^ 2 + (wy - castY) ^ 2) < CAST_NEAR then return end
    landing = nil
    WLWritsCharDB.hearthSpot = { bind = name, cont = cont, wx = wx, wy = wy }
end

local function OnCast(spell)
    if type(spell) ~= "number" or IsSecret(spell) then return end
    if spell ~= HEARTH_SPELL and spell ~= ASTRAL_RECALL then return end
    if spell == HEARTH_SPELL and WLWritsCharDB then WLWritsCharDB.hearthUsed = time and time() or nil end
    landing = Clock()
    castCont, castX, castY = Here()
    -- the cast ends with the teleport: you stand at the inn a moment later (or after the loading screen)
    if C_Timer and C_Timer.After then
        C_Timer.After(3, function() pcall(GPS._OnLanded) end)
        C_Timer.After(10, function() pcall(GPS._OnLanded) end)   -- a long loading screen: once more
    end
    ReplanSoon(3.5)
end
GPS._OnCast = OnCast

f:SetScript("OnEvent", function(_, event, a1, a2, a3)
    if event == "CONFIRM_BINDER" then
        pcall(GPS._OnBinder, a1)
        return
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        if a1 == "player" then pcall(OnCast, a3) end
        return
    elseif event == "PLAYER_REGEN_ENABLED" then
        -- the walks that waited for the end of the fight
        if state.dest and not state.zygor then pcall(AskWalks, state.dest) end
        return
    end
    if event == "LOADING_SCREEN_DISABLED" and landing then
        if C_Timer and C_Timer.After then C_Timer.After(1, function() pcall(GPS._OnLanded) end) end
    end
    if event == "PLAYER_LOGIN" then
        -- A tour does not survive a reload: start it again from the button.
        if WLWritsCharDB then WLWritsCharDB.gps = false end
    elseif event == "TAXIMAP_OPENED" then
        RecordTaxi()
        GPS.Replan()
        C_Timer.After(0.1, function() pcall(GPS.MarkTaxi) end)
        if Opt("autoFlight", false) and GPS.FlightLeg() then C_Timer.After(0.3, GPS.TakeFlight) end
    elseif event == "TAXIMAP_CLOSED" then
        GPS.UnmarkTaxi()
    elseif event == "QUEST_TURNED_IN" then
        local db = WLWritsCharDB
        if not writOfQuest then
            writOfQuest = {}
            for _, w in ipairs(ns.WRITS) do if w.quest then writOfQuest[w.quest] = w end end
        end
        if db and db.gps then
            if writOfQuest[a1] then C_Timer.After(1.5, WP.GoNext) end
        elseif state.source == "writs" and state.dest and state.dest.writ and state.dest.writ.quest == a1 then
            GPS.Stop("writs")   -- the single writ guided to is handed in
        end
    else
        ReplanSoon(1)
    end
end)

-- ---------------------------------------------------------------- NPCs that walk a path
-- A guide point whose NPC patrols (s.sp / f.sp in Data.lua, root.PatrolAt in Engine.lua): the GPS goes
-- to the spot of his path nearest to you rather than to the marker, and each time you reach a spot
-- (NEAR yards) it moves on to the next spot along the path, round again after the last one. The
-- guide keeps the step until the quest is taken or handed in, so meeting him ends it the usual way.
-- The guide may call GPS.GoPoint with the marker as often as it likes: the walk along the path goes on.
local patrol         -- { map, x, y (the marker), source, label, spots, idx, dest (the spot guided to) }
local patrolTicker
local plainGoPoint = GPS.GoPoint

local function HereWorld()
    local cont, wx, wy = Here()
    if cont then return { cont, wx, wy } end
end

local function PatrolStop()
    patrol = nil
    if patrolTicker then patrolTicker:Cancel(); patrolTicker = nil end
end

local function PatrolGo()
    local s = patrol.spots[patrol.idx]
    plainGoPoint(s[1], s[2], s[3], patrol.label, patrol.source)
    patrol.dest = state.dest
end

local function PatrolTick()
    if not patrol then return end
    -- a place the player chose: the spot comes back when it ends
    if state.source ~= "dungeon" and state.suspended and state.suspended == patrol.dest then return end
    -- the GPS stopped or guides somewhere else
    if not state.dest or state.dest ~= patrol.dest then PatrolStop(); return end
    local here = HereWorld()
    if here and root.PatrolReached and root.PatrolReached(patrol.spots, patrol.idx, here, NEAR) then
        patrol.idx = root.PatrolNext(patrol.spots, patrol.idx)
        PatrolGo()
    end
end
GPS.PatrolTick = PatrolTick

function GPS.GoPoint(map, x, y, label, source)
    local spots = root.PatrolAt and root.PatrolAt(map, x, y)
    if not spots then return plainGoPoint(map, x, y, label, source) end
    -- the same marker again while its walk waits behind the player's place: the spot it waits on stays
    -- (kept aside as a plain marker, PatrolTick would drop the walk)
    if patrol and patrol.map == map and patrol.x == x and patrol.y == y and patrol.source == source
        and state.source ~= "dungeon" and state.suspended and state.suspended == patrol.dest then return end
    -- the player's own place goes first: the marker waits (a plain point, the walk starts again later)
    if Waiting(map, x, y, label, source) then return end
    if patrol and patrol.map == map and patrol.x == x and patrol.y == y and patrol.source == source
        and state.dest and state.dest == patrol.dest then return end
    patrol = { map = map, x = x, y = y, source = source, label = label, spots = spots }
    patrol.idx = root.PatrolNearest(spots, HereWorld()) or 1
    PatrolGo()
    if not patrolTicker and C_Timer and C_Timer.NewTicker then
        patrolTicker = C_Timer.NewTicker(1, function() pcall(PatrolTick) end)
    end
end

-- The patrol the GPS follows now ({ spots, idx, label, ... }), or nil: read it, do not change it.
function GPS.Patrol() return patrol end
