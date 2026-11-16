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
-- GPS.Itinerary() / GPS.ItinerarySummary() say the whole way in one line ("Pierre de foyer > vol
-- jusqu'à Kargath > 300 m jusqu'à Tabetha"); GPS.TripSummary() the short plan for a card
-- ("Téléport : Orgrimmar, puis 690 m").
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
    -- the walk or ride of a leg says where it goes, never how ("690 m ride" read as "take a flight")
    ["%s jusqu'à %s"] = "%s to %s",
    ["%s jusqu'au maître de vol"] = "%s to the flight master",
    ["%s jusqu'au bateau"] = "%s to the boat",
    ["%s jusqu'au zeppelin"] = "%s to the zeppelin",
    ["%s après l'atterrissage"] = "%s after landing",
    ["%s sur place"] = "%s on arrival",
    -- GPS.TripSummary: "Téléport : Orgrimmar, puis 690 m"
    ["Téléport : %s"] = "Teleport: %s",
    ["Vol jusqu'à %s"] = "Flight to %s",
    ["Bateau pour %s"] = "Boat to %s",
    ["Zeppelin pour %s"] = "Zeppelin to %s",
    ["%s, puis %s"] = "%s, then %s",
    -- the runner-up (the arrow's tooltip, the guide card): "Autre trajet : zeppelin pour Grom'gol, puis vol
    -- jusqu'à Kargath (~10 min)"
    ["Autre trajet : %s (%s)"] = "Other route: %s (%s)",
    ["Ce trajet : %s"] = "This route: %s",
    ["pierre de foyer jusqu'à %s"] = "Hearthstone to %s",
    ["rappel astral jusqu'à %s"] = "Astral Recall to %s",
    ["à pied"] = "on foot",
    ["sur ta monture"] = "on your mount",
    ["Trajet changé : %s"] = "Route changed: %s",
    -- the arrow's line when the plan rides far with no flight (T-89)
    ["À cheval : ouvre la carte d'un maître de vol pour que le GPS connaisse tes vols"] =
        "On your mount: open a flight master's map so the GPS learns your flight paths",
    ["À cheval : tu ne connais pas encore le vol de %s"] = "On your mount: you don't know the flight path at %s yet",
    ["À cheval : pas de maître de vol plus près"] = "On your mount: no flight master closer",
    -- a flight path guessed on a continent where no flight map was opened yet
    ["Vol supposé connu : ouvre la carte du maître de vol pour vérifier"] =
        "Flight path assumed known: open the flight master's map to check",
    ["(vol supposé)"] = "(assumed flight)",
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

-- Zeppelins and boats: both ends (uiMapID, x, y in percent), what it is, who may take it; id: the ship
-- in Transports.lua (when it leaves, from NaowhForever_QoL, our own sightings or the guild).
local LINKS = {
    { a = { 1420, 60.70, 58.76 }, b = { 1411, 50.82, 13.81 }, mode = "zeppelin", side = "Horde", nameA = "Undercity", nameB = "Orgrimmar", id = "uc-org" },
    { a = { 1420, 61.88, 59.10 }, b = { 1434, 31.53, 29.15 }, mode = "zeppelin", side = "Horde", nameA = "Undercity", nameB = "Grom'gol", id = "uc-grom" },
    { a = { 1411, 50.57, 12.66 }, b = { 1434, 31.35, 30.12 }, mode = "zeppelin", side = "Horde", nameA = "Orgrimmar", nameB = "Grom'gol", id = "org-grom" },
    { a = { 1434, 25.92, 73.15 }, b = { 1413, 63.66, 38.65 }, mode = "boat", nameA = "Booty Bay", nameB = "Ratchet", id = "bb-rat" },
    { a = { 1453, 22.60, 56.13 }, b = { 1439, 30.76, 41.00 }, mode = "boat", side = "Alliance", nameA = "Stormwind", nameB = "Auberdine", id = "sw-aub" },
    { a = { 1437, 5.08, 63.40 }, b = { 1445, 71.54, 56.34 }, mode = "boat", side = "Alliance", nameA = "Menethil Harbor", nameB = "Theramore", id = "men-ther" },
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
-- The Hearthstone's (and Astral Recall's) policy, WLWritsDB.gpsOpts.hearth (Settings > GPS):
-- "always" when faster, "gain" (the default) only when it saves at least HEARTH_GAIN seconds over the
-- best way without it (its hour of cooldown is worth keeping for a real gain), "never". Old values:
-- false = "never", true = the default. A mage's teleports have no long cooldown: not concerned.
local HEARTH_GAIN = 180
-- The runner-up shown beside the plan: another first leg, at most 50% slower.
local ALT_SPAN = 1.5

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
local LINK_TIME, TELEPORT_TIME = 150, 15   -- LINK_TIME: a zeppelin or boat whose timing is unknown (wait + ride)
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

-- "always" | "gain" | "never" (see HEARTH_GAIN)
local function HearthPolicy()
    local v = Opt("hearth")
    if v == false or v == "never" then return "never" end
    if v == "always" then return "always" end
    return "gain"
end
GPS.HearthPolicy = HearthPolicy

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
    local seenNow = {}
    for _, n in ipairs(nodes) do
        if n.nodeID and n.position and n.position.GetXY then
            local x, y = n.position:GetXY()
            if n.state ~= unreachable and not db.taxi[n.nodeID] then
                db.taxi[n.nodeID] = { name = n.name, map = mapID, x = x * 100, y = y * 100 }
                added = true
            end
            -- the flight map is the last word: its continent is "seen"
            local okW, cont = pcall(World, mapID, x, y)
            if okW and type(cont) == "number" then
                db.taxiSeen = db.taxiSeen or {}
                if db.taxiSeen[cont] ~= "map" then db.taxiSeen[cont] = "map"; added = true end
                seenNow[cont] = true
            end
        end
    end
    if added then fixed, knownCount = nil, nil end
    -- the guesses there are over: a master this map does not show as known is never guessed again
    for cont in pairs(seenNow) do pcall(GPS._ForgetGuesses, cont) end
end
GPS._RecordTaxi = RecordTaxi

-- ---------------------------------------------------------------- flight paths read anywhere (T-89)
-- Without a flight map opened on a continent since the install, the GPS knew none of its flight paths
-- (Erril rode 3.6 km from Grom'gol to Stonard). C_TaxiMap.GetTaxiNodesForMap lists the flight masters
-- of a world map with isUndiscovered (and on some clients state): read on login, on a zone change
-- and every few minutes. It is trusted for a continent only when it tells found from not found (at
-- least one of your side's masters undiscovered): WoW Forever's world map lists them all as found,
-- learned or not (OpenMap, ForeverDungeonJournal), and then only a flight map tells. A continent with
-- neither a trusted read nor a flight map opened is "unseen": the GPS guesses there (Guessed, below).
local TAXI_MAPS = { 1415, 1414, 1463, 1464 }   -- the continents' world maps, then Forever's flight maps
local BOOT_NEAR = 300                          -- yards: the master you stand at is guessed, whatever his zone
local masters = {}       -- [continent] = every flight master of your side the client lists, known or not
local mastersRead        -- a read was made (GPS.ReadTaxiNodes)

local function Readable(v) return v ~= nil and not IsSecret(v) end

function GPS.ReadTaxiNodes()
    mastersRead = true
    if not (C_TaxiMap and C_TaxiMap.GetTaxiNodesForMap and WLWritsCharDB) then return end
    local db = WLWritsCharDB
    local side = UnitFactionGroup and UnitFactionGroup("player")
    local FF = Enum and Enum.FlightPathFaction
    local neutral = FF and FF.Neutral or 0
    local mine = side == "Horde" and (FF and FF.Horde or 1) or side == "Alliance" and (FF and FF.Alliance or 2) or nil
    local unreachable = Enum and Enum.FlightPathState and Enum.FlightPathState.Unreachable or 2
    local per, seenID = {}, {}
    for _, mapID in ipairs(TAXI_MAPS) do
        local ok, nodes = pcall(C_TaxiMap.GetTaxiNodesForMap, mapID)
        if ok and type(nodes) == "table" then
            for _, n in ipairs(nodes) do
                local id = type(n) == "table" and n.nodeID
                local name = type(n) == "table" and n.name
                if type(id) == "number" and Readable(id) and not seenID[id] and type(name) == "string" and Readable(name)
                    and not name:find("^zz") and type(n.position) == "table"
                    and (not Readable(n.faction) or n.faction == neutral or n.faction == mine) then
                    local x, y = n.position.x, n.position.y
                    if (x == nil or y == nil) and n.position.GetXY then x, y = n.position:GetXY() end
                    if type(x) == "number" and type(y) == "number" and Readable(x) and Readable(y)
                        and x >= 0 and x <= 1 and y >= 0 and y <= 1 then
                        local cont, wx, wy = World(mapID, x, y)
                        if cont then
                            seenID[id] = true
                            local c = per[cont] or { all = {}, found = {}, hidden = 0 }
                            per[cont] = c
                            local m = { kind = "taxi", nodeID = id, name = name, map = mapID, x = x * 100, y = y * 100,
                                cont = cont, wx = wx, wy = wy }
                            c.all[#c.all + 1] = m
                            local found
                            if Readable(n.isUndiscovered) then found = n.isUndiscovered == false end
                            if type(n.state) == "number" and Readable(n.state) then
                                found = (found ~= false) and n.state ~= unreachable
                            end
                            if found == false then c.hidden = c.hidden + 1 elseif found then c.found[#c.found + 1] = m end
                        end
                    end
                end
            end
        end
    end
    local added = false
    db.taxi = db.taxi or {}
    for cont, c in pairs(per) do
        masters[cont] = c.all
        if c.hidden > 0 and #c.found > 0 then
            for _, m in ipairs(c.found) do
                if not db.taxi[m.nodeID] then
                    db.taxi[m.nodeID] = { name = m.name, map = m.map, x = m.x, y = m.y }
                    added = true
                end
            end
            db.taxiSeen = db.taxiSeen or {}
            if not db.taxiSeen[cont] then db.taxiSeen[cont] = "api"; added = true end
        end
    end
    if added then fixed, knownCount = nil, nil end
end

-- The flight masters of your side the client listed on a continent (known or not), for the arrow's
-- explanation and the guess. Read them, don't change them.
function GPS._Masters(cont)
    if not mastersRead then pcall(GPS.ReadTaxiNodes) end
    return masters[cont] or {}
end

-- tests: the fixed points built again (faction, class, flight paths changed)
function GPS._ResetFixed() fixed, knownCount = nil, nil; masters, mastersRead = {}, nil end

function GPS.KnownFlights()
    if not knownCount then
        knownCount = 0
        for _ in pairs(WLWritsCharDB.taxi or {}) do knownCount = knownCount + 1 end
    end
    return knownCount
end

-- Flight paths known on a continent (0 Eastern Kingdoms, 1 Kalimdor).
function GPS.KnownFlightsOn(cont)
    if not fixed then BuildFixed() end
    local k = 0
    for _, p in ipairs(fixed.taxi) do if p.cont == cont then k = k + 1 end end
    return k
end

-- A continent whose flight paths the GPS cannot know: no flight map opened there, no trusted read,
-- no flight path recorded on it.
function GPS.Unseen(cont)
    local db = WLWritsCharDB
    if db and db.taxiSeen and db.taxiSeen[cont] then return false end
    return GPS.KnownFlightsOn(cont) == 0
end

-- The guess on an unseen continent (Erril, 55, never opened a flight map in the Eastern Kingdoms: the
-- GPS sent him by teleport and two zeppelins from the Hinterlands to Stonard): every flight master of
-- your side whose zone starts GUESS_GAP levels or more below yours (you have very likely been there and
-- talked to him), plus the one you stand at (BOOT_NEAR yards). Such a node is p.guess: a flight from or
-- to it costs GUESS_COST more (a sure way wins a near tie), GUESS_FAR more again when you get there by a
-- cast or a ship (you could not check it before going); the arrow and the card say the flight is
-- supposed known. Opening a flight map tells the truth (RecordTaxi: the continent is seen, its guesses
-- are over, a master it does not show as known is never guessed again, WLWritsCharDB.taxiNoGuess).
local GUESS_GAP = 5
local GUESS_COST, GUESS_FAR = 60, 180

-- The zones' first levels (uiMapID, level, names in English and French, without "The"/"Les"): the
-- zone of a master is the end of his name ("Stonard, Swamp of Sorrows") or his map (LibForeverData).
local ZONE_LEVELS = {
    { 1429, 1, "Elwynn Forest", "Forêt d'Elwynn", "Elwynn" }, { 1426, 1, "Dun Morogh" }, { 1420, 1, "Tirisfal Glades", "Clairières de Tirisfal", "Tirisfal" },
    { 1453, 1, "Stormwind City", "Stormwind", "Hurlevent", "Cité de Hurlevent" }, { 1455, 1, "Ironforge", "Forgefer" },
    { 1458, 1, "Undercity", "Fossoyeuse" },
    { 1436, 10, "Westfall", "Marche de l'Ouest" }, { 1432, 10, "Loch Modan" }, { 1421, 10, "Silverpine Forest", "Forêt des Pins-Argentés", "Silverpine", "Pins-Argentés" },
    { 1433, 15, "Redridge Mountains", "Carmines", "Les Carmines", "Montagnes des Carmines", "Redridge" },
    { 1431, 18, "Duskwood", "Bois de la Pénombre" }, { 1437, 20, "Wetlands", "Paluns", "Les Paluns" },
    { 1424, 20, "Hillsbrad Foothills", "Contreforts de Hautebrande", "Hillsbrad", "Hautebrande" }, { 1416, 30, "Alterac Mountains", "Montagnes d'Alterac", "Alterac" },
    { 1417, 30, "Arathi Highlands", "Hautes-terres d'Arathi", "Arathi" },
    { 1434, 30, "Stranglethorn Vale", "Stranglethorn", "Vallée de Strangleronce", "Strangleronce" },
    { 1418, 35, "Badlands", "Terres ingrates", "Les Terres ingrates" }, { 1435, 35, "Swamp of Sorrows", "Marais des Chagrins" },
    { 1425, 40, "Hinterlands", "The Hinterlands", "Les Hinterlands" }, { 1427, 43, "Searing Gorge", "Gorge des Vents brûlants" },
    { 1419, 45, "Blasted Lands", "Terres foudroyées" }, { 1428, 50, "Burning Steppes", "Steppes ardentes" },
    { 1422, 51, "Western Plaguelands", "Maleterres de l'Ouest" }, { 1423, 53, "Eastern Plaguelands", "Maleterres de l'Est" },
    { 1430, 55, "Deadwind Pass", "Défilé de Deuillevent" },
    { 1411, 1, "Durotar" }, { 1412, 1, "Mulgore" }, { 1438, 1, "Teldrassil" }, { 1454, 1, "Orgrimmar" },
    { 1456, 1, "Thunder Bluff", "Pitons-du-Tonnerre", "Les Pitons-du-Tonnerre" }, { 1457, 1, "Darnassus" },
    { 1413, 10, "Barrens", "The Barrens", "Tarides", "Les Tarides", "Northern Barrens", "Tarides du Nord" },
    { 1439, 10, "Darkshore", "Sombrivage" }, { 1442, 15, "Stonetalon Mountains", "Serres-Rocheuses", "Les Serres-Rocheuses" },
    { 1440, 18, "Ashenvale", "Orneval" }, { 1441, 25, "Thousand Needles", "Mille pointes" }, { 1443, 30, "Desolace", "Désolace" },
    { 1445, 35, "Dustwallow Marsh", "Marécage d'Âprefange" }, { 1444, 40, "Feralas", "Féralas" }, { 1446, 40, "Tanaris" },
    { 1447, 45, "Azshara" }, { 1448, 48, "Felwood", "Gangrebois" }, { 1449, 48, "Un'Goro Crater", "Cratère d'Un'Goro" },
    { 1451, 55, "Silithus" }, { 1452, 55, "Winterspring", "Berceau-de-l'Hiver" }, { 1450, 55, "Moonglade", "Reflet-de-Lune" },
}
local zoneByName, zoneByMap
local function ZoneKey(s)
    s = tostring(s):lower():gsub("^%s+", ""):gsub("%s+$", "")
    s = s:gsub("^the ", ""):gsub("^les ", ""):gsub("^le ", ""):gsub("^la ", ""):gsub("^l'", "")
    return s
end
-- The first level of a master's zone, nil when unknown (never guessed then).
local function ZoneMin(name, map)
    if not zoneByName then
        zoneByName, zoneByMap = {}, {}
        for _, z in ipairs(ZONE_LEVELS) do
            zoneByMap[z[1]] = z[2]
            for i = 3, #z do zoneByName[ZoneKey(z[i])] = z[2] end
        end
    end
    if type(map) == "number" and zoneByMap[map] then return zoneByMap[map] end
    if type(name) ~= "string" then return nil end
    local zone = name:match(".*,%s*(.-)%s*$")
    return zoneByName[ZoneKey(zone or name)]
end
GPS._ZoneMin = ZoneMin

local function PlayerLevel()
    local ok, l = pcall(UnitLevel, "player")
    if ok and type(l) == "number" and not IsSecret(l) and l > 0 then return l end
end

-- A master's key in WLWritsCharDB.taxiNoGuess: his node, else (LibForeverData) his place.
local function GuessKey(m)
    if m.nodeID then return "n" .. m.nodeID end
    return "l" .. tostring(m.cont) .. ":" .. math.floor(m.wx / 20 + 0.5) .. ":" .. math.floor(m.wy / 20 + 0.5)
end

-- The masters of a continent to guess from: the client's list, else LibForeverData's flight masters
-- of your side (GoTo.FlightMasters: the same places the "Aller à" window finds).
local function GuessPool(cont)
    local all = GPS._Masters(cont)
    if #all == 0 and WP.GoTo and WP.GoTo.FlightMasters then
        local ok, t = pcall(WP.GoTo.FlightMasters, cont)
        if ok and type(t) == "table" then all = t end
    end
    return all
end

local function Guessed(cont, px, py)
    if not GPS.Unseen(cont) then return nil end
    local all = GuessPool(cont)
    if #all == 0 then return nil end
    local no = WLWritsCharDB and WLWritsCharDB.taxiNoGuess or {}
    local near, nd
    if px and py then
        for _, m in ipairs(all) do
            local d = math.sqrt((m.wx - px) ^ 2 + (m.wy - py) ^ 2)
            if d <= BOOT_NEAR and (not nd or d < nd) then near, nd = m, d end
        end
    end
    local lvl = PlayerLevel()
    local out = {}
    for _, m in ipairs(all) do
        if not no[GuessKey(m)] then
            local minL = ZoneMin(m.name, m.zoneMap)
            if m == near or (lvl and minL and minL <= lvl - GUESS_GAP) then
                out[#out + 1] = { kind = "taxi", guess = true, nodeID = m.nodeID, name = m.name,
                    cont = m.cont, wx = m.wx, wy = m.wy, map = m.map, x = m.x, y = m.y }
            end
        end
    end
    return #out > 0 and out or nil
end
GPS._Guessed = Guessed

-- A flight map was opened on `cont` (RecordTaxi): every master of it the map does not show as known
-- (not recorded, nor within 60 yards of a recorded node) is never guessed again.
function GPS._ForgetGuesses(cont)
    local db = WLWritsCharDB
    if not db then return end
    local known, knownID = {}, {}
    for id, t in pairs(db.taxi or {}) do
        local p = type(t) == "table" and Point(t.map, t.x, t.y)
        if p and p.cont == cont then known[#known + 1] = p; knownID[id] = true end
    end
    db.taxiNoGuess = db.taxiNoGuess or {}
    for _, m in ipairs(GuessPool(cont)) do
        local ok = m.nodeID and knownID[m.nodeID]
        if not ok then
            for _, p in ipairs(known) do
                if math.sqrt((p.wx - m.wx) ^ 2 + (p.wy - m.wy) ^ 2) < 60 then ok = true; break end
            end
        end
        if not ok then db.taxiNoGuess[GuessKey(m)] = true end
    end
end

-- The plan flies a supposed flight path (a guessed master at one end of a flight).
function GPS.GuessedFlight(legs)
    for _, l in ipairs(type(legs) == "table" and legs or {}) do
        if l.kind == "fly" and ((l.from and l.from.guess) or (l.to and l.to.guess)) then return true end
    end
    return false
end

-- Flight masters' places in English and French (the short name of a node, "Stonard, Swamp of Sorrows"
-- -> "Stonard"), for the arrow's explanation when the client names them in the other language.
local FLIGHT_NAMES = {
    { "Stonard", "Pierrêche" }, { "Booty Bay", "Baie-du-Butin" }, { "Hammerfall", "Trépas-d'Orgrim" },
    { "Tarren Mill", "Moulin-de-Tarren" }, { "Undercity", "Fossoyeuse" }, { "The Sepulcher", "Le Sépulcre" },
    { "Revantusk Village", "Village des Vengebroches" }, { "Light's Hope Chapel", "Chapelle de l'Espoir de Lumière" },
    { "Thorium Point", "Halte du Thorium" }, { "Stormwind", "Hurlevent" }, { "Ironforge", "Forgefer" },
    { "Sentinel Hill", "Colline des Sentinelles" }, { "Lakeshire", "Comté-du-Lac" }, { "Darkshire", "Sombre-Comté" },
    { "Menethil Harbor", "Port de Menethil" }, { "Southshore", "Austrivage" }, { "Aerie Peak", "Nid-de-l'Aigle" },
    { "Chillwind Camp", "Camp du Noroît" }, { "Thunder Bluff", "Les Pitons-du-Tonnerre" },
    { "Crossroads", "La Croisée" }, { "The Crossroads", "La Croisée" }, { "Ratchet", "Cabestan" },
    { "Splintertree Post", "Poste de Bois-Brisé" }, { "Zoram'gar Outpost", "Avant-poste de Zoram'gar" },
    { "Sun Rock Retreat", "Retraite de Roche-Soleil" }, { "Freewind Post", "Poste de Librevent" },
    { "Everlook", "Long-Guet" }, { "Cenarion Hold", "Fort cénarien" }, { "Moonglade", "Reflet-de-Lune" },
    { "Nijel's Point", "Pointe de Nijel" }, { "Feathermoon Stronghold", "Bastion de Pennelune" },
    { "Talrendis Point", "Pointe de Talrendis" }, { "Rut'theran Village", "Village de Rut'theran" },
    { "Stonetalon Peak", "Pic des Serres-Rocheuses" },
}
local function PlaceIn(name)
    local short = GPS.ShortPlace(name)
    local en = ns.English and ns.English()
    for _, r in ipairs(FLIGHT_NAMES) do
        if r[1] == short or r[2] == short then return en and r[1] or r[2] end
    end
    return short
end
GPS._PlaceIn = PlaceIn

-- The arrow's one muted line when the plan rides far (more than RIDE_NOTE yards) on a continent with
-- no flight in the plan: why ("ouvre la carte d'un maître de vol", "tu ne connais pas encore le vol de
-- Pierrêche", "pas de maître de vol plus près"). nil when the plan flies or rides little; a plan that
-- flies a guessed flight path says so ("Vol supposé connu : ouvre la carte du maître de vol pour vérifier").
local RIDE_NOTE = 1500
function GPS.RideNote(legs)
    if type(legs) ~= "table" then return nil end
    if GPS.GuessedFlight(legs) then return L("Vol supposé connu : ouvre la carte du maître de vol pour vérifier") end
    local long
    for _, l in ipairs(legs) do
        if l.kind == "fly" then return nil end
        if l.kind == "ride" and l.from and l.to and l.from.cont == l.to.cont and l.from.wx and l.to.wx then
            local d = Dist(l.from, l.to)
            if d > RIDE_NOTE and (not long or d > long.d) then long = { leg = l, d = d } end
        end
    end
    if not long then return nil end
    local to, cont = long.leg.to, long.leg.to.cont
    if GPS.Unseen(cont) then return L("À cheval : ouvre la carte d'un maître de vol pour que le GPS connaisse tes vols") end
    if not fixed then BuildFixed() end
    local known = {}
    for _, p in ipairs(fixed.taxi) do if p.nodeID then known[p.nodeID] = true end end
    local best, bd
    for _, m in ipairs(GPS._Masters(cont)) do
        local d = Dist(m, to)
        if not bd or d < bd then best, bd = m, d end
    end
    if best and not known[best.nodeID] and bd < long.d * 0.5 then
        return string.format(L("À cheval : tu ne connais pas encore le vol de %s"), PlaceIn(best.name))
    end
    return L("À cheval : pas de maître de vol plus près")
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

-- C_SpellBook first, then the old globals (Writs/Locale.lua)
local function SpellKnown(id) return ns.SpellKnown(id) end

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
local function HearthWay(dead, pol)
    if dead or (pol or HearthPolicy()) == "never" then return nil end
    local useStone = HearthReady()
    local useRecall = not useStone and Opt("teleports", true) and SpellReady(ASTRAL_RECALL)
    if not (useStone or useRecall) then return nil end
    local inn = GPS.InnPoint()
    if not inn then return nil end
    if useStone then return inn, "item" end
    return inn, ASTRAL_RECALL
end

-- What a zeppelin or boat costs when you reach its dock `base` seconds from now: the real wait for the
-- next departure plus the crossing when the ship is timed (Transports.lua), else the flat LINK_TIME; a
-- druid's flight home: its flight time. sNow: the server time of "now" (one per search). follow: the
-- plan you follow (a ship missed by a few seconds still counts as caught: no flip-flop, Transports.Cost).
local function LinkCost(a, b, base, sNow, follow)
    local l = a.link
    if l.mode == "flight" then return FlyCost(Dist(a, b)) end
    local T = WP.Transports
    if T and T.Cost and l.id then
        local ok, c = pcall(T.Cost, l, a.start == true, (sNow or T._Now()) + (base or 0), follow)
        if ok and type(c) == "number" then return c end
    end
    return LINK_TIME
end
local function ServerNow()
    local T = WP.Transports
    return T and T._Now and T._Now() or nil
end

-- A ship leg says when it leaves, as planned (Transports.lua): leg.wait (seconds at the dock), leg.ride,
-- leg.conf ("naowh" | "synced" | "estimated"), leg.departAt (server time; nil when estimated).
local function NoteDeparture(leg, base, sNow, follow)
    local l = leg.from and leg.from.link
    local T = WP.Transports
    if not (l and l.id and T and T.Next and l.mode ~= "flight") then return end
    local at = (sNow or T._Now()) + (base or 0)
    local ok, total, conf, wait, ride = pcall(T.Cost, l, leg.from.start == true, at, follow)
    if not ok or not total then return end
    leg.conf, leg.wait, leg.ride = conf, wait, ride
    leg.departAt = wait and (at + wait) or nil
end

-- On board the ship of a plan's first leg (Transports.Aboard: you stood at its dock until it left):
-- the seconds of the crossing left, else nil.
local function Aboard(leg)
    local T = WP.Transports
    local d = leg and leg.kind == "link" and leg.from
    if not (d and d.link and d.link.id and T and T.Aboard) then return nil end
    local ok, left = pcall(T.Aboard, d.link, d.start == true, d)
    return ok and type(left) == "number" and left or nil
end

-- One Dijkstra over every pair of points (a few dozen), from where you stand. With `firstOnly` it
-- stops at the nearest of `dests`; otherwise it prices every destination. `exclude`: points left out
-- (the next best plans).
local function Excluded(exclude, p)
    return exclude ~= nil and (exclude[p] or exclude[NodeKey(p)]) and true or false
end

local function Search(dests, firstOnly, exclude, pol)
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
        if Excluded(exclude, p) then return end
        p._key = NodeKey(p)
        nodes[#nodes + 1] = p
    end
    for _, d in ipairs(dests) do d._key = NodeKey(d); nodes[#nodes + 1] = d; isDest[#nodes] = true end
    if not dead then
        for _, p in ipairs(fixed.taxi) do Add(p) end
        -- an unseen continent: the flight masters you very likely know, guessed (Guessed)
        local have = {}
        for _, p in ipairs(fixed.taxi) do if p.nodeID then have[p.nodeID] = true end end
        local conts = { [0] = true, [1] = true }
        conts[cont] = true
        for c in pairs(conts) do
            local okG, guess = pcall(Guessed, c, c == cont and px or nil, c == cont and py or nil)
            if okG and guess then
                for _, p in ipairs(guess) do if not (p.nodeID and have[p.nodeID]) then Add(p) end end
            end
        end
    end
    for _, p in ipairs(fixed.docks) do Add(p) end
    if Opt("teleports", true) and not dead then
        local hasRune = BagCount(RUNE) > 0
        for _, p in ipairs(fixed.ports) do
            if (not p.rune or hasRune) and SpellReady(p.spell) then Add(p) end
        end
    end
    local inn, via = HearthWay(dead, pol)
    if inn and Excluded(exclude, inn) then inn = nil end
    if inn then Add(inn) end

    local n, speed = #nodes, RideSpeed()
    local sNow = ServerNow()
    local cost, prev, how, done = {}, {}, {}, {}
    local far = {}         -- [i]: reached by a cast or a ship (a guessed flight there could not be checked)
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
                        -- a supposed flight path: a sure way wins a near tie
                        if a.guess or b.guess then f = f + GUESS_COST + (far[u] and GUESS_FAR or 0) end
                        if f < c then c, kind = f, "fly" end
                    end
                end
                if a.kind == "dock" and a.other == b and (a.start or not a.link.oneWay) then
                    local lt = LinkCost(a, b, base, sNow)
                    if lt < c then c, kind = lt, "link" end
                end
                if u == 1 and b.kind == "port" and TELEPORT_TIME < c then c, kind = TELEPORT_TIME, "teleport" end
                if u == 1 and b == inn and HEARTH_TIME < c then c, kind = HEARTH_TIME, "hearth" end
                if kind and base + c < cost[v] then
                    cost[v], prev[v], how[v] = base + c, u, kind
                    far[v] = far[u] or kind == "link" or kind == "teleport" or kind == "hearth"
                end
            end
        end
    end
    return nodes, cost, prev, how, reached, via
end

-- Seconds to each of `dests` from where you stand (nil when unreachable), in one search.
function GPS.CostsTo(dests)
    local pol = HearthPolicy()
    local _, cost, _, _, _, via = Search(dests, false, nil, pol)
    -- "gain": the way without the Hearthstone too, kept unless the stone saves HEARTH_GAIN seconds
    local cost2
    if cost and via and pol == "gain" then _, cost2 = Search(dests, false, nil, "never") end
    local out = {}
    if cost then
        for i = 1, #dests do
            local c = cost[i + 1]
            local c2 = cost2 and cost2[i + 1]
            if c2 and c2 < math.huge and (not c or c2 - c < HEARTH_GAIN) then c = c2 end
            if c and c < math.huge then out[i] = c end
        end
    end
    return out
end

-- Fastest way from where you stand to the nearest of `dests` (Points). Returns the legs
-- { kind = "ride"|"fly"|"link"|"teleport"|"hearth", from, to, seconds }, the seconds it takes and the
-- destination reached. A "hearth" leg says how: item = 6948 (the Hearthstone) or spell = 556 (Astral
-- Recall). `exclude`: points the way may not use.
local function PathWith(dests, exclude, pol)
    local nodes, cost, prev, how, reached, via = Search(dests, true, exclude, pol)
    if not reached then return nil end
    local legs, v = {}, reached
    local sNow = ServerNow()
    while prev[v] do
        local leg = { kind = how[v], from = nodes[prev[v]], to = nodes[v], seconds = cost[v] - cost[prev[v]] }
        if leg.kind == "link" then NoteDeparture(leg, cost[prev[v]], sNow) end
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

-- The plan under a Hearthstone policy: with "gain", a plan that starts with the Hearthstone (or Astral
-- Recall) gives way to the best one without it unless the cast saves HEARTH_GAIN seconds.
local function PathPol(dests, exclude, pol)
    local legs, eta, reached = PathWith(dests, exclude, pol)
    if legs and pol == "gain" and legs[1] and legs[1].kind == "hearth" then
        local l2, e2, r2 = PathWith(dests, exclude, "never")
        if l2 and e2 - eta < HEARTH_GAIN then return l2, e2, r2 end
    end
    return legs, eta, reached
end

function GPS.FindPath(dests, exclude)
    return PathPol(dests, exclude, HearthPolicy())
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
    local sNow = ServerNow()
    local total, at = 0, start
    local farNow          -- a cast or a ship before: a guessed flight then costs GUESS_FAR more (Search)
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
            local aboard = i == 1 and k == "link" and Aboard(leg)
            if aboard then
                -- on the ship already: the crossing left, not the walk back nor the next departure
                total = total + aboard
            elseif i == 1 then
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
                if (from.guess or leg.to.guess) then
                    -- a flight map opened since: the guess is over, a new plan
                    if not GPS.Unseen(leg.to.cont) then return nil end
                    total = total + GUESS_COST + (farNow and GUESS_FAR or 0)
                end
            elseif k == "link" and not aboard then
                if from.link then
                    NoteDeparture(leg, total, sNow, true)
                    total = total + LinkCost(from, leg.to, total, sNow, true)
                else
                    total = total + LINK_TIME
                end
            end
        end
        if k == "link" or k == "teleport" or k == "hearth" then farNow = true end
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
            -- where the walk goes, not how: "690 m jusqu'à Dran Droffers" ("690 m ride" after a
            -- teleport was read as a flight to take)
            local text
            local link = to.kind == "dock" and to.link
            if to.kind == "taxi" or (link and link.mode == "flight") then
                text = string.format(L("%s jusqu'au maître de vol"), d)
            elseif link then
                text = string.format(link.mode == "boat" and L("%s jusqu'au bateau") or L("%s jusqu'au zeppelin"), d)
            elseif type(to.name) == "string" and to.name ~= "" then
                -- no distance known (a point on another continent): the name alone, "Puis Tabetha"
                text = yards and string.format(L("%s jusqu'à %s"), d, P) or UpperFirst(P)
            else
                local before = legs[i - 1]
                local landed = before and (before.kind == "fly" or before.kind == "link")
                text = string.format(landed and L("%s après l'atterrissage") or L("%s sur place"), d)
            end
            item = { kind = onFoot and "walk" or "ride", yards = yards, text = text }
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

-- Between two legs of a way told in one line. Plain ASCII: the game's fonts (FRIZQT, ARIALN) have no
-- arrow glyph (U+2192 drew as a box on the French client), and U+203A may be missing too.
GPS.SEP = " > "

-- The whole way in one line: "Pierre de foyer > vol jusqu'à Kargath > 300 m jusqu'à Tabetha" (first word in
-- capital). Empty when there is no plan.
function GPS.ItinerarySummary(legs)
    local parts = {}
    for i, it in ipairs(GPS.Itinerary(legs)) do
        parts[#parts + 1] = i == 1 and UpperFirst(it.text) or it.text
    end
    return table.concat(parts, GPS.SEP)
end

-- The next legs in a few words, for a line with no room for the whole way: of `items` (GPS.Itinerary),
-- the casts, flights and crossings and the last walk (the one to the place), at most `max` (3) of them:
-- "vol jusqu'à Orgrimmar", "zeppelin pour Undercity", "vol jusqu'à Moulin-de-Tarren". The walks between
-- two of them ("610 m jusqu'au zeppelin") are left to the tooltip, which lists every leg. `skip(it)`:
-- true for an item not to tell (the leg under way). Returns the kept texts (a list, maybe empty).
function GPS.NextLegs(items, max, skip)
    max = max or 3
    local left = {}
    for _, it in ipairs(type(items) == "table" and items or {}) do
        if type(it.text) == "string" and it.text ~= "" and not (skip and skip(it)) then left[#left + 1] = it end
    end
    local out = {}
    for i, it in ipairs(left) do
        if not (it.kind == "walk" or it.kind == "ride") or i == #left then
            if #out >= max then break end
            out[#out + 1] = it.text
        end
    end
    return out
end

-- The planned trip in one short sentence, for a card that names the place and its distance itself:
-- "Téléport : Orgrimmar, puis 690 m", "Vol jusqu'à Kargath, puis 300 m", "Zeppelin pour Orgrimmar,
-- puis 1,2 km". `dest`: a GPS point (GPS.Point) or map, x, y in percent (and a name). When the GPS
-- guides there, the plan the arrow follows (the card and the arrow say the same); else the best way
-- now (kept 8 seconds per place). nil when there is no way, or no flight, boat or cast on it (only a
-- ride: the card's distance says it). Then the legs, the trip's time ("~4 min") and its runner-up's line
-- ("Autre trajet : zeppelin pour Grom'gol, puis vol jusqu'à Kargath (~6 min)", or nil).
local tripCache, tripCount = {}, 0
-- The plan to a place for a card: the legs, its time ("~4 min") and its runner-up's line ("Autre trajet :
-- ...", or nil). When the GPS guides there, the arrow's own plan and runner-up.
local function TripPlan(dest, x, y, name)
    local p
    if type(dest) == "table" and dest.cont and dest.wx and dest.wy then
        p = dest
    elseif type(dest) == "number" and type(x) == "number" and type(y) == "number" then
        p = Point(dest, x, y, { kind = "dest", name = name })
    end
    if not p then return nil end
    local d = state.dest
    if d and not state.zygor and type(state.legs) == "table" and d.cont == p.cont and d.wx and Dist(d, p) < NEAR then
        local alt = GPS.Alternative and GPS.Alternative()
        return state.legs, GPS.TripMinutes(), alt and alt.text or nil
    end
    local key = tostring(p.cont) .. ":" .. math.floor(p.wx + 0.5) .. ":" .. math.floor(p.wy + 0.5)
    local c = tripCache[key]
    if not (c and Clock() - c.at < REPLAN_EVERY) then
        local ok, found, eta = pcall(GPS.FindPath, { p })
        local legs = ok and found or false
        local altText
        if legs and type(eta) == "number" then
            local okA, alt = pcall(GPS._Alternative, p, legs, eta)
            if okA and alt then
                local w, m = GPS.WayWords(alt.legs), GPS.Minutes(alt.eta)
                if w and m then altText = string.format(L("Autre trajet : %s (%s)"), w, m) end
            end
        end
        if tripCount >= 20 then tripCache, tripCount = {}, 0 end
        if not c then tripCount = tripCount + 1 end
        c = { at = Clock(), legs = legs, minutes = legs and GPS.Minutes(eta) or nil, alt = altText }
        tripCache[key] = c
    end
    return c.legs, c.minutes, c.alt
end

function GPS.TripSummary(dest, x, y, name)
    local legs, minutes, alt = TripPlan(dest, x, y, name)
    if type(legs) ~= "table" or #legs == 0 then return nil end
    local parts, last = {}, nil
    for _, it in ipairs(GPS.Itinerary(legs)) do
        local to = it.leg and it.leg.to or {}
        local P = GPS.ShortPlace(to.name)
        local first = #parts == 0
        local part
        if it.kind == "teleport" then
            part = string.format(L("Téléport : %s"), P)
        elseif it.kind == "hearth" then
            part = string.format(it.leg.item and L("Pierre de foyer : %s") or L("Rappel astral : %s"), P)
        elseif it.kind == "fly" then
            part = string.format(first and L("Vol jusqu'à %s") or L("vol jusqu'à %s"), P)
        elseif it.kind == "boat" then
            part = string.format(first and L("Bateau pour %s") or L("bateau pour %s"), P)
        elseif it.kind == "zeppelin" then
            part = string.format(first and L("Zeppelin pour %s") or L("zeppelin pour %s"), P)
        else
            last = it      -- a walk or a ride: the one after the last flight or cast is the "puis"
        end
        -- a timed ship says when it leaves: "Zeppelin pour Grom'gol (départ dans ~3 min)"
        if part and (it.kind == "boat" or it.kind == "zeppelin") and WP.Transports and WP.Transports.CardPart then
            local okC, p2 = pcall(WP.Transports.CardPart, part, it.leg)
            if okC and type(p2) == "string" then part = p2 end
        end
        if part then parts[#parts + 1] = part; last = nil end
    end
    if #parts == 0 then return nil end
    local s = table.concat(parts, ", ")
    if last and last.yards then s = string.format(L("%s, puis %s"), s, DistanceText(last.yards)) end
    if GPS.GuessedFlight(legs) then s = s .. " " .. L("(vol supposé)") end
    return s, legs, minutes, alt
end

-- ---------------------------------------------------------------- the runner-up

-- "~10 min" (at least 1)
function GPS.Minutes(seconds)
    if type(seconds) ~= "number" or seconds ~= seconds or seconds == math.huge then return nil end
    return string.format(L("~%d min"), math.max(1, math.floor(seconds / 60 + 0.5)))
end

-- A plan in a few words, its casts, flights and crossings only: "zeppelin pour Grom'gol, puis vol jusqu'à
-- Kargath"; a plan of rides only: "à pied" / "sur ta monture".
function GPS.WayWords(legs)
    local parts = {}
    local walks = 0
    for _, it in ipairs(GPS.Itinerary(legs)) do
        local P = GPS.ShortPlace(it.leg and it.leg.to and it.leg.to.name)
        local part
        if it.kind == "hearth" then
            part = string.format(it.leg.item and L("pierre de foyer jusqu'à %s") or L("rappel astral jusqu'à %s"), P)
        elseif it.kind == "teleport" or it.kind == "fly" or it.kind == "boat" or it.kind == "zeppelin" then
            part = it.text
        else
            walks = walks + 1
        end
        if part then parts[#parts + 1] = part end
    end
    if #parts == 0 then
        if walks == 0 then return nil end
        return RideSpeed() <= RUN and L("à pied") or L("sur ta monture")
    end
    local s = parts[1]
    for i = 2, #parts do s = string.format(L("%s, puis %s"), s, parts[i]) end
    return s
end

-- The runner-up of a plan to `dest`: { legs, eta, choice } when a way with another first leg exists at
-- most ALT_SPAN times as long; choice: what Replan follows once it is taken (the stop to avoid, and the
-- Hearthstone allowed even under "gain": the player picked it). While the player follows such a choice
-- (`chosen`), the runner-up is the plan the settings make (taking it drops the choice).
function GPS._Alternative(dest, legs, eta, chosen)
    if not dest or type(legs) ~= "table" or not legs[1] or type(eta) ~= "number" then return nil end
    local first = legs[1].to
    if not first or first == dest or first.kind == "dest" then return nil end
    local pol = HearthPolicy()
    local a, aEta, choice
    if chosen then
        a, aEta = PathPol({ dest }, nil, pol)
        choice = false
    else
        local altPol = pol == "never" and "never" or "always"
        a, aEta = PathPol({ dest }, { [first] = true }, altPol)
        choice = { avoid = { [NodeKey(first)] = true }, pol = altPol }
    end
    if not (a and a[1] and a[1].to and aEta) then return nil end
    if a[1].to == first or NodeKey(a[1].to) == NodeKey(first) then return nil end
    -- the way back to the plan the settings make is always offered; a new runner-up only when close
    if not chosen and aEta > eta * ALT_SPAN then return nil end
    -- the same words as the plan (another flight master next to it, then the same flight): no choice
    local okW, w1, w2 = pcall(function() return GPS.WayWords(a), GPS.WayWords(legs) end)
    if okW and w1 and w1 == w2 then return nil end
    if choice then choice.dest = dest end
    return { legs = a, eta = aEta, choice = choice }
end

-- The runner-up of the trip the arrow follows: { legs, eta, text = "Autre trajet : ... (~6 min)" }, or nil.
function GPS.Alternative()
    local alt = state.dest and not state.zygor and state.alt
    if not alt then return nil end
    if alt.text == nil then
        local w = GPS.WayWords(alt.legs)
        local m = GPS.Minutes(alt.eta)
        alt.text = (w and m) and string.format(L("Autre trajet : %s (%s)"), w, m) or false
    end
    if not alt.text then return nil end
    return alt
end

-- The trip the arrow follows, its time now: "~4 min" (nil when unknown).
function GPS.TripMinutes()
    if not state.dest or state.zygor or type(state.legs) ~= "table" then return nil end
    local ok, c = pcall(PlanCost, state.legs)
    return GPS.Minutes(ok and c or state.eta)
end

-- Takes the runner-up: the arrow follows it until the destination changes (taken again: back to the
-- plan the settings make). True when it changed.
function GPS.TakeAlternative()
    local alt = GPS.Alternative()
    if not (alt and state.dest) then return false end
    state.choice = alt.choice or nil
    state.legs, state.eta, state.planFor = alt.legs, alt.eta, state.dest
    state.legs.total = #state.legs + (state.doneLegs or 0)
    local okA, nextAlt = pcall(GPS._Alternative, state.dest, state.legs, state.eta, state.choice)
    state.alt = okA and nextAlt or nil
    state.plannedAt = GetTime()
    if WP.Trail and WP.Trail.Clear then pcall(WP.Trail.Clear) end
    if WP.Print then
        local w = GPS.WayWords(state.legs)
        if w then WP.Print(string.format(L("Trajet changé : %s"), w)) end
    end
    if GPS.OnChanged then GPS.OnChanged() end
    if WP.RefreshHome then WP.RefreshHome() end
    return true
end

-- A setting that changes the plans (the Hearthstone's policy): the plan is made again from scratch.
function GPS.ResetPlan()
    tripCache, tripCount = {}, 0
    if not state.dest or state.zygor then return end
    state.legs, state.choice, state.alt = nil, nil, nil
    GPS.Replan()
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
    -- on a zeppelin or boat of the plan: it holds until you land (a plan from mid-air is no plan)
    if state.legs and Aboard(state.legs[1]) then state.plannedAt = GetTime(); return end
    -- the other trip the player took (Alt-click on the arrow) holds until the destination changes
    local choice = state.choice
    if choice and choice.dest ~= state.dest then choice = nil; state.choice = nil end
    local legs, eta
    if choice then
        legs, eta = PathPol({ state.dest }, choice.avoid, choice.pol or HearthPolicy())
        if not legs then state.choice = nil end
    end
    if not legs then legs, eta = GPS.FindPath({ state.dest }) end
    local old = state.legs
    if legs and old and #old > 0 and state.planFor == state.dest and Signature(legs) ~= Signature(old) then
        local oldCost = PlanCost(old)
        -- the Hearthstone's "gain" policy holds against the plan you follow too: a stone that saves less
        -- than HEARTH_GAIN over it does not replace it (a ship's countdown moving would flip the two)
        local function Stone(l) return l[1] and l[1].kind == "hearth" end
        local gainHeld = oldCost and Stone(legs) and not Stone(old)
            and ((choice and choice.pol) or HearthPolicy()) == "gain" and oldCost - eta < HEARTH_GAIN
        if oldCost and (eta >= oldCost * (1 - SWITCH) or gainHeld) then legs, eta = old, oldCost end
    end
    state.legs, state.eta, state.planFor = legs, eta, state.dest
    -- "step 2 of 4" keeps counting across plans: legs already done plus the legs left
    if state.legs then state.legs.total = #state.legs + (state.doneLegs or 0) end
    -- the runner-up (another first leg, at most 50% slower): told in the tooltip, Alt-click takes it
    local okA, alt = pcall(GPS._Alternative, state.dest, state.legs, eta, state.choice)
    state.alt = okA and alt or nil
    state.plannedAt = GetTime()
    Changed()
    -- then the real walks of the best ways, asked in the background (never in combat)
    if state.legs then pcall(AskWalks, state.dest) end
end

-- Zygor's arrow, when the player turned on "Send destinations to Zygor's arrow" (provider "zygor").
local function Zygor()
    local Z = rawget(_G, "ZGV")
    if type(Z) == "table" and type(Z.Pointer) == "table" and Z.Pointer.SetWaypoint and Z.Pointer.ArrowFrame then return Z end
end
function GPS.UseZygor()
    local Z = Zygor()
    if not Z then return false end
    -- only when the player asked for it: our point replaces the waypoint of the Zygor guide the
    -- player follows, and our own arrow, path and dots step aside
    return Opt("provider") == "zygor"
end

-- beta.74: the 3-way choice ("auto" | "wl" | "zygor") is one switch; "auto" and "wl" both meant
-- our GPS since beta.73, so they become nil (off). Only "zygor" is kept.
function GPS.MigrateProvider()
    local o = WLWritsDB and WLWritsDB.gpsOpts
    if type(o) == "table" and o.provider ~= nil and o.provider ~= "zygor" then o.provider = nil end
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
    state.choice, state.alt = nil, nil
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
    state.choice, state.alt = nil, nil
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

GPS._Here = Here
-- The dock points of the zeppelins and boats, for Transports.lua's watcher: your side's once the GPS
-- has planned, else every ship's (built once, without touching the GPS's own list). Read them, don't
-- change them.
local shipDocks
function GPS._Docks()
    if fixed then return fixed.docks end
    if shipDocks then return shipDocks end
    local out = {}
    for _, l in ipairs(LINKS) do
        if l.id and l.a and l.b then
            local a = Point(l.a[1], l.a[2], l.a[3], { kind = "dock", name = l.nameA, link = l, start = true })
            local b = Point(l.b[1], l.b[2], l.b[3], { kind = "dock", name = l.nameB, link = l })
            if a and b then a.other, b.other = b, a; out[#out + 1] = a; out[#out + 1] = b end
        end
    end
    if #out > 0 then shipDocks = out end
    return out
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
    if event == "PLAYER_LOGIN" or event == "ZONE_CHANGED_NEW_AREA" then
        -- the flight paths you know, read anywhere (T-89); again every 5 minutes
        pcall(GPS.ReadTaxiNodes)
        if event == "PLAYER_LOGIN" and C_Timer and C_Timer.NewTicker then
            pcall(C_Timer.NewTicker, 300, function() pcall(GPS.ReadTaxiNodes) end)
        end
    end
    if event == "PLAYER_LOGIN" then
        pcall(GPS.MigrateProvider)
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
