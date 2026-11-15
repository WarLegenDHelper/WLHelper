-- Writs/Route.lua: WL Helper's GPS, shared by the dungeon guide and the writs. It finds the fastest way to a turn-in spot from where you stand,
-- riding, taking the flight paths you know, zeppelins, boats and, for a mage, the city teleports,
-- and guides you with an arrow (Arrow.lua): one step at a time, planned again every few seconds
-- and after each flight, boat or loading screen. Nothing outside the addon is needed.
--
-- Positions are world coordinates (yards) from C_Map.GetWorldPosFromMapPos; the arrow turns with
-- GetPlayerFacing against north and east measured on the map you are on, so no axis is assumed.
local ADDON, root = ...
-- The Writs module of WL Helper keeps its own table inside the addon's namespace.
root.Writs = root.Writs or {}
local ns = root.Writs
local WP = ns.WP
local L = ns.L

local GPS = {}
WP.GPS = GPS

-- Zeppelins and boats: both ends (uiMapID, x, y in percent), what it is, who may take it.
local LINKS = {
    { a = { 1420, 60.70, 58.76 }, b = { 1411, 50.82, 13.81 }, mode = "zeppelin", side = "Horde", nameA = "Undercity", nameB = "Orgrimmar" },
    { a = { 1420, 61.88, 59.10 }, b = { 1434, 31.53, 29.15 }, mode = "zeppelin", side = "Horde", nameA = "Undercity", nameB = "Grom'gol" },
    { a = { 1411, 50.57, 12.66 }, b = { 1434, 31.35, 30.12 }, mode = "zeppelin", side = "Horde", nameA = "Orgrimmar", nameB = "Grom'gol" },
    { a = { 1434, 25.92, 73.15 }, b = { 1413, 63.66, 38.65 }, mode = "boat", nameA = "Booty Bay", nameB = "Ratchet" },
    { a = { 1453, 22.60, 56.13 }, b = { 1439, 30.76, 41.00 }, mode = "boat", side = "Alliance", nameA = "Stormwind", nameB = "Auberdine" },
    { a = { 1437, 5.08, 63.40 }, b = { 1445, 71.54, 56.34 }, mode = "boat", side = "Alliance", nameA = "Menethil Harbor", nameB = "Theramore" },
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

local RUN, MOUNT = 7, 11.2         -- yards a second on foot and on a 60% mount
local TERRAIN = 1.3                -- roads and hills: a ride is longer than the straight line
local FLY, FLY_DETOUR, FLY_STOP = 30, 1.25, 20
local LINK_TIME, TELEPORT_TIME = 150, 15
local NEAR = 15                    -- yards: a step's spot reached

-- ---------------------------------------------------------------- positions

local function World(map, x, y)   -- x, y from 0 to 1
    if not (C_Map and C_Map.GetWorldPosFromMapPos and CreateVector2D and map) then return end
    local ok, cont, pos = pcall(C_Map.GetWorldPosFromMapPos, map, CreateVector2D(x, y))
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
    return math.sqrt((a.wx - b.wx) ^ 2 + (a.wy - b.wy) ^ 2)
end

local function Point(map, x, y, extra)   -- x, y in percent
    local cont, wx, wy = World(map, x / 100, y / 100)
    if not cont then return nil end
    local p = extra or {}
    p.cont, p.wx, p.wy, p.map, p.x, p.y = cont, wx, wy, map, x, y
    return p
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
    for _, n in ipairs(nodes) do
        if n.nodeID and n.position and n.position.GetXY and n.state ~= unreachable then
            local x, y = n.position:GetXY()
            db.taxi[n.nodeID] = { name = n.name, map = mapID, x = x * 100, y = y * 100 }
        end
    end
end

function GPS.KnowsFlights()
    return WLWritsCharDB.taxi ~= nil and next(WLWritsCharDB.taxi) ~= nil
end

-- ---------------------------------------------------------------- the route

local function SpellReady(id)
    local known = (IsPlayerSpell and IsPlayerSpell(id)) or (IsSpellKnown and IsSpellKnown(id))
    if not known then return false end
    local start, duration
    if C_Spell and C_Spell.GetSpellCooldown then
        local ok, cd = pcall(C_Spell.GetSpellCooldown, id)
        if ok and type(cd) == "table" then start, duration = cd.startTime, cd.duration end
    elseif GetSpellCooldown then
        start, duration = GetSpellCooldown(id)
    end
    return not (start and duration and start > 0 and duration > 1.5)
end

local function BagCount(id)
    local f = (C_Item and C_Item.GetItemCount) or GetItemCount
    local ok, n = pcall(f, id)
    return ok and n or 0
end

local function RideSpeed()
    return (UnitLevel("player") or 1) >= 40 and MOUNT or RUN
end

-- Fastest way from where you stand to `dest` (a Point): the legs, each
-- { kind = "ride"|"fly"|"link"|"teleport", from, to }, and the seconds it takes.
function GPS.FindPath(dest)
    local cont, px, py = PlayerWorld()
    if not cont or not dest then return nil end
    local side = UnitFactionGroup("player")
    local start = { cont = cont, wx = px, wy = py, kind = "start" }
    local nodes = { start, dest }
    for id, t in pairs(WLWritsCharDB.taxi or {}) do
        local p = Point(t.map, t.x, t.y, { kind = "taxi", name = t.name, nodeID = id })
        if p then nodes[#nodes + 1] = p end
    end
    for _, l in ipairs(LINKS) do
        if not l.side or l.side == side then
            local a = Point(l.a[1], l.a[2], l.a[3], { kind = "dock", name = l.nameA, link = l })
            local b = Point(l.b[1], l.b[2], l.b[3], { kind = "dock", name = l.nameB, link = l })
            if a and b then
                a.other, b.other = b, a
                nodes[#nodes + 1] = a
                nodes[#nodes + 1] = b
            end
        end
    end
    local hasRune = BagCount(RUNE) > 0
    for _, t in ipairs(TELEPORTS) do
        if (not t.side or t.side == side) and (not t.rune or hasRune) and SpellReady(t.spell) then
            local p = Point(t.map, t.x, t.y, { kind = "port", name = t.name, spell = t.spell })
            if p then nodes[#nodes + 1] = p end
        end
    end

    -- Dijkstra over every pair of points (a few dozen at most).
    local speed = RideSpeed()
    local cost, prev, how, done = {}, {}, {}, {}
    for i = 1, #nodes do cost[i] = math.huge end
    cost[1] = 0
    for _ = 1, #nodes do
        local u, best = nil, math.huge
        for i = 1, #nodes do if not done[i] and cost[i] < best then u, best = i, cost[i] end end
        if not u or u == 2 then break end
        done[u] = true
        local a = nodes[u]
        for v = 1, #nodes do
            if not done[v] then
                local b = nodes[v]
                local function relax(c, kind)
                    if cost[u] + c < cost[v] then cost[v], prev[v], how[v] = cost[u] + c, u, kind end
                end
                if a.cont == b.cont then
                    relax(Dist(a, b) * TERRAIN / speed, "ride")
                    if a.kind == "taxi" and b.kind == "taxi" then relax(Dist(a, b) * FLY_DETOUR / FLY + FLY_STOP, "fly") end
                end
                if a.kind == "dock" and a.other == b then relax(LINK_TIME, "link") end
                if u == 1 and b.kind == "port" then relax(TELEPORT_TIME, "teleport") end
            end
        end
    end
    if cost[2] == math.huge then return nil end
    local legs, v = {}, 2
    while prev[v] do
        table.insert(legs, 1, { kind = how[v], from = nodes[prev[v]], to = nodes[v] })
        v = prev[v]
    end
    -- A ride of a few yards (you already stand at the flight master or the dock) is no step.
    local out = {}
    for _, leg in ipairs(legs) do
        if not (leg.kind == "ride" and Dist(leg.from, leg.to) < NEAR and leg.to.kind ~= "dest") then out[#out + 1] = leg end
    end
    return out, cost[2]
end

-- ---------------------------------------------------------------- guidance

local state = {}   -- dest, legs, eta

local function Describe(leg)
    if not leg then return "" end
    local to = leg.to
    if leg.kind == "ride" then
        if to.kind == "taxi" then return string.format(L("Va au maître de vol : %s"), to.name) end
        if to.kind == "dock" then
            return string.format(to.link.mode == "boat" and L("Va au bateau pour %s") or L("Va au zeppelin pour %s"), to.other.name)
        end
        return string.format(L("Va à %s"), to.name or "?")
    elseif leg.kind == "fly" then
        return string.format(L("Prends le vol pour %s"), to.name)
    elseif leg.kind == "link" then
        return string.format(leg.from.link.mode == "boat" and L("Prends le bateau pour %s") or L("Prends le zeppelin pour %s"), to.name)
    elseif leg.kind == "teleport" then
        return string.format(L("Lance Téléportation : %s"), to.name)
    end
    return ""
end

-- Where the arrow points: the end of a ride, or where a flight or a boat leaves from.
local function Target()
    local leg = state.legs and state.legs[1]
    if not leg then return state.dest end
    if leg.kind == "ride" then return leg.to end
    if leg.kind == "fly" or leg.kind == "link" then return leg.from end
end

function GPS.Replan()
    if not state.dest then return end
    if UnitOnTaxi and UnitOnTaxi("player") then return end
    state.legs, state.eta = GPS.FindPath(state.dest)
    if GPS.OnChanged then GPS.OnChanged() end
end

-- Guides you to a writ's turn-in spot.
function GPS.Go(w)
    if not (w and w.map) then
        WP.Print(L("lieu de remise inconnu pour ") .. WP.ItemName(w.writ, w.writName))
        return
    end
    local dest = Point(w.map, w.x, w.y, { kind = "dest", name = w.npcName or WP.ItemName(w.item, w.itemName), writ = w })
    if not dest then
        WP.Print(L("impossible de poser un point sur cette carte."))
        return
    end
    state.dest = dest
    GPS.Replan()
    if C_Map and C_Map.SetUserWaypoint and UiMapPoint then
        pcall(C_Map.SetUserWaypoint, UiMapPoint.CreateFromCoordinates(w.map, w.x / 100, w.y / 100))
    end
    if not GPS.KnowsFlights() then WP.Print(L("ouvre une carte de vol une fois : le GPS apprendra tes points de vol.")) end
    if GPS.Show then GPS.Show() end
end

-- Guides you to any point (the dungeon guide's steps): map, x, y in percent, a label.
-- The same point again changes nothing, so a guide may call it as often as it likes.
function GPS.GoPoint(map, x, y, label, source)
    local d = state.dest
    if d and d.map == map and d.x == x and d.y == y and d.source == source then return end
    local dest = Point(map, x, y, { kind = "dest", name = label, source = source })
    if not dest then return end
    state.dest = dest
    GPS.Replan()
    if GPS.Show then GPS.Show() end
end

-- Stops the GPS; with a source, only if the GPS is guiding for that source.
function GPS.Stop(source)
    if source and not (state.dest and state.dest.source == source) then return end
    state.dest, state.legs, state.eta = nil, nil, nil
    if GPS.Hide then GPS.Hide() end
end

function GPS.Source() return state.dest and state.dest.source end

function GPS.Active() return state.dest ~= nil end

-- What the arrow shows now.
function GPS.Now()
    if not state.dest then return nil end
    local target = Target()
    local cont, px, py = PlayerWorld()
    local dist
    if target and cont and cont == target.cont then dist = math.sqrt((target.wx - px) ^ 2 + (target.wy - py) ^ 2) end
    local leg = state.legs and state.legs[1]
    local last = not state.legs or #state.legs == 0 or (#state.legs == 1 and leg.kind == "ride")
    return {
        text = leg and Describe(leg) or string.format(L("Va à %s"), state.dest.name or "?"),
        next = state.legs and state.legs[2] and Describe(state.legs[2]) or nil,
        target = target, dist = dist, eta = state.eta, leg = leg,
        arrived = last and dist ~= nil and dist < NEAR,
    }
end

-- Heading from you to a world point against your facing (radians, counter-clockwise),
-- north and east measured on the map you stand on.
function GPS.Bearing(target)
    local map, x, y = PlayerMapPos()
    if not (map and target) then return nil end
    local c0, x0, y0 = World(map, x, y)
    local _, xn, yn = World(map, x, y - 0.01)
    local _, xe, ye = World(map, x + 0.01, y)
    if not (c0 and xn and xe) or c0 ~= target.cont then return nil end
    local nx, ny, ex, ey = xn - x0, yn - y0, xe - x0, ye - y0
    local nl, el = math.sqrt(nx * nx + ny * ny), math.sqrt(ex * ex + ey * ey)
    if nl == 0 or el == 0 then return nil end
    local dx, dy = target.wx - x0, target.wy - y0
    local north = (dx * nx + dy * ny) / nl
    local east = (dx * ex + dy * ey) / el
    local facing = GetPlayerFacing and GetPlayerFacing()
    if not facing then return nil end
    return math.atan2(-east, north) - facing
end

function GPS.FlightLeg()
    local leg = state.legs and state.legs[1]
    return leg and leg.kind == "fly" and leg or nil
end

function GPS.TeleportLeg()
    local leg = state.legs and state.legs[1]
    return leg and leg.kind == "teleport" and leg or nil
end

-- Takes the planned flight while the flight map is open (a click on the arrow's button).
function GPS.TakeFlight()
    local leg = GPS.FlightLeg()
    if not (leg and C_TaxiMap and GetTaxiMapID and TakeTaxiNode) then return end
    local ok, nodes = pcall(C_TaxiMap.GetAllTaxiNodes, GetTaxiMapID())
    if not ok or type(nodes) ~= "table" then return end
    for _, n in ipairs(nodes) do
        if n.nodeID == leg.to.nodeID and n.slotIndex then TakeTaxiNode(n.slotIndex); return end
    end
end

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

-- The stop the route reaches soonest.
function WP.NextStop(rows)
    local stops = WP.Stops(rows)
    if #stops == 0 then return nil, 0 end
    local best, bestT
    for _, r in ipairs(stops) do
        local _, t = GPS.FindPath(Point(r.w.map, r.w.x, r.w.y, { kind = "dest" }))
        t = t or math.huge
        if not bestT or t < bestT then best, bestT = r, t end
    end
    return best, #stops
end

function WP.GoNext()
    local stop, count = WP.NextStop()
    if not stop then
        WLWritsCharDB.gps = false
        GPS.Stop()
        WP.Print(L("GPS : aucun writ prêt à rendre, tournée terminée."))
        if WP.OnGPSChanged then WP.OnGPSChanged() end
        return
    end
    local w = stop.w
    GPS.Go(w)
    WP.Print(string.format(L("GPS : %s, %s %.0f %.0f%s (%d à rendre)%s"), WP.ItemName(w.item, w.itemName),
        WP.ZoneName(w.map), w.x, w.y, w.npcName and (" - " .. w.npcName) or "", count,
        stop.state == "bag" and L(" · ouvre l'enveloppe d'abord") or ""))
end

function WP.ToggleGPS()
    local db = WLWritsCharDB
    db.gps = not db.gps
    if db.gps then WP.GoNext() else GPS.Stop() end
    if WP.OnGPSChanged then WP.OnGPSChanged() end
end

-- A click on a writ: the GPS to that writ alone.
function WP.TravelTo(w)
    GPS.Go(w)
end

-- ---------------------------------------------------------------- events

local f = CreateFrame("Frame")
f:RegisterEvent("QUEST_TURNED_IN")
f:RegisterEvent("TAXIMAP_OPENED")
f:RegisterEvent("ZONE_CHANGED_NEW_AREA")
f:RegisterEvent("PLAYER_CONTROL_GAINED")
f:RegisterEvent("LOADING_SCREEN_DISABLED")
f:SetScript("OnEvent", function(_, event, a1)
    if event == "TAXIMAP_OPENED" then
        RecordTaxi()
        if GPS.OnChanged then GPS.OnChanged() end
    elseif event == "QUEST_TURNED_IN" then
        local db = WLWritsCharDB
        local guided = state.dest and state.dest.writ
        if db and db.gps then
            for _, w in ipairs(ns.WRITS) do
                if w.quest == a1 then C_Timer.After(1.5, WP.GoNext); return end
            end
        elseif guided and guided.quest == a1 then
            GPS.Stop()   -- the single writ guided to is handed in
        end
    elseif state.dest then
        C_Timer.After(1, GPS.Replan)
    end
end)
