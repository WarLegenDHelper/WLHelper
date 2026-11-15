-- Writs/Route.lua: WL Helper's GPS, shared by the dungeon guide (source "dungeon") and the Comptoir
-- (source "writs"). It finds the fastest way from where you stand: riding, the flight paths you know,
-- zeppelins, boats and a mage's city teleports, then guides you one leg at a time (Arrow.lua).
-- The plan is made again every few seconds, when a flight map opens, after a flight, a boat or a
-- loading screen, and the first leg is dropped as soon as you reach its end.
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
local NEAR = 15                    -- yards: a leg's end reached
local REPLAN_EVERY = 8             -- seconds between two plans while guiding

local function Opt(key, default)
    local o = WLWritsDB and WLWritsDB.gpsOpts
    local v = o and o[key]
    if v == nil then return default end
    return v
end

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

-- ---------------------------------------------------------------- fixed points, kept

local fixed   -- { taxi = {...}, docks = {...}, ports = {...} } for this faction, built once
local knownCount   -- flight paths recorded, counted once

local function BuildFixed()
    local side = UnitFactionGroup("player")
    fixed = { taxi = {}, docks = {}, ports = {} }
    for id, t in pairs(WLWritsCharDB.taxi or {}) do
        local p = Point(t.map, t.x, t.y, { kind = "taxi", name = t.name, nodeID = id })
        if p then fixed.taxi[#fixed.taxi + 1] = p end
    end
    for _, l in ipairs(LINKS) do
        if not l.side or l.side == side then
            local a = Point(l.a[1], l.a[2], l.a[3], { kind = "dock", name = l.nameA, link = l })
            local b = Point(l.b[1], l.b[2], l.b[3], { kind = "dock", name = l.nameB, link = l })
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

function GPS.KnownFlights()
    if not knownCount then
        knownCount = 0
        for _ in pairs(WLWritsCharDB.taxi or {}) do knownCount = knownCount + 1 end
    end
    return knownCount
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

-- One Dijkstra over every pair of points (a few dozen), from where you stand. With `firstOnly` it
-- stops at the nearest of `dests`; otherwise it prices every destination.
local function Search(dests, firstOnly)
    local cont, px, py = PlayerWorld()
    if not cont or not dests or #dests == 0 then return nil end
    if not fixed then BuildFixed() end
    -- a ghost runs to its corpse: no flight, no teleport
    local dead = UnitIsDeadOrGhost and UnitIsDeadOrGhost("player")
    local nodes = { { cont = cont, wx = px, wy = py, kind = "start" } }
    local isDest = {}
    for _, d in ipairs(dests) do nodes[#nodes + 1] = d; isDest[#nodes] = true end
    if not dead then
        for _, p in ipairs(fixed.taxi) do nodes[#nodes + 1] = p end
    end
    for _, p in ipairs(fixed.docks) do nodes[#nodes + 1] = p end
    if Opt("teleports", true) and not dead then
        local hasRune = BagCount(RUNE) > 0
        for _, p in ipairs(fixed.ports) do
            if (not p.rune or hasRune) and SpellReady(p.spell) then nodes[#nodes + 1] = p end
        end
    end

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
                    local d = Dist(a, b)
                    c, kind = d * TERRAIN / speed, "ride"
                    if a.kind == "taxi" and b.kind == "taxi" then
                        local f = d * FLY_DETOUR / FLY + FLY_STOP
                        if f < c then c, kind = f, "fly" end
                    end
                end
                if a.kind == "dock" and a.other == b and LINK_TIME < c then c, kind = LINK_TIME, "link" end
                if u == 1 and b.kind == "port" and TELEPORT_TIME < c then c, kind = TELEPORT_TIME, "teleport" end
                if kind and base + c < cost[v] then cost[v], prev[v], how[v] = base + c, u, kind end
            end
        end
    end
    return nodes, cost, prev, how, reached
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
-- { kind = "ride"|"fly"|"link"|"teleport", from, to }, the seconds it takes and the destination reached.
function GPS.FindPath(dests)
    local nodes, cost, prev, how, reached = Search(dests, true)
    if not reached then return nil end
    local legs, v = {}, reached
    while prev[v] do
        table.insert(legs, 1, { kind = how[v], from = nodes[prev[v]], to = nodes[v] })
        v = prev[v]
    end
    -- A ride of a few yards (you already stand at the flight master or the dock) is no step.
    local out = {}
    for _, leg in ipairs(legs) do
        if not (leg.kind == "ride" and Dist(leg.from, leg.to) < NEAR and leg.to.kind ~= "dest") then out[#out + 1] = leg end
    end
    return out, cost[reached], nodes[reached]
end

-- ---------------------------------------------------------------- guidance

local state = {}   -- dest, source, legs, eta, plannedAt

function GPS.Describe(leg)
    if not leg then return "" end
    local to = leg.to
    if leg.kind == "ride" then
        if to.kind == "taxi" then return string.format(L("Maître de vol, %s"), to.name) end
        if to.kind == "dock" then
            return string.format(to.link.mode == "boat" and L("Bateau pour %s") or L("Zeppelin pour %s"), to.other.name)
        end
        return to.name or "?"
    elseif leg.kind == "fly" then
        return string.format(L("Prends le vol pour %s"), to.name)
    elseif leg.kind == "link" then
        return string.format(leg.from.link.mode == "boat" and L("Prends le bateau pour %s") or L("Prends le zeppelin pour %s"), to.name)
    elseif leg.kind == "teleport" then
        return string.format(L("Téléportation : %s"), to.name)
    end
    return ""
end

local function Changed()
    if GPS.OnChanged then GPS.OnChanged() end
    if WP.RefreshHome then WP.RefreshHome() end
end

function GPS.Replan()
    if not state.dest or state.zygor then return end
    if UnitOnTaxi and UnitOnTaxi("player") then return end
    state.legs, state.eta = GPS.FindPath({ state.dest })
    -- "step 2 of 4" keeps counting across plans: legs already done plus the legs left
    if state.legs then state.legs.total = #state.legs + (state.doneLegs or 0) end
    state.plannedAt = GetTime()
    Changed()
end

-- Zygor's travel system, when the options ask for it (or "auto" and it is on).
local function Zygor()
    local Z = rawget(_G, "ZGV")
    if type(Z) == "table" and type(Z.Pointer) == "table" and Z.Pointer.SetWaypoint and Z.Pointer.ArrowFrame then return Z end
end
function GPS.UseZygor()
    local Z = Zygor()
    if not Z then return false end
    local p = Opt("provider", "auto")
    if p == "zygor" then return true end
    if p == "auto" then return Z.db and Z.db.profile and Z.db.profile.pathfinding and true or false end
    return false
end

-- Several events in a row (a loading screen fires a few) make one plan.
local replanQueued = false
local function ReplanSoon(delay)
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
    -- a Comptoir detour keeps the dungeon guide's point, given back when the detour ends
    if source == "writs" and state.source == "dungeon" and state.dest then
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
        if w then WP.Print(L("lieu de remise inconnu pour ") .. WP.ItemName(w.writ, w.writName)) end
        return
    end
    local dest = Point(w.map, w.x, w.y, { kind = "dest", name = w.npcName or WP.ItemName(w.item, w.itemName), writ = w })
    if not dest then
        WP.Print(L("impossible de poser un point sur cette carte."))
        return
    end
    Start(dest, "writs")
    if C_Map and C_Map.SetUserWaypoint and UiMapPoint then
        pcall(C_Map.SetUserWaypoint, UiMapPoint.CreateFromCoordinates(w.map, w.x / 100, w.y / 100))
    end
    if GPS.KnownFlights() == 0 then WP.Print(L("ouvre une carte de vol une fois : le GPS apprendra tes points de vol.")) end
end

-- Guides you to any point (the dungeon guide's steps): map, x, y in percent, a label. The same point
-- again changes nothing, so the guide may call it as often as it likes; it never takes over a writ tour.
function GPS.GoPoint(map, x, y, label, source)
    if state.source == "writs" and state.dest and source ~= "writs" then return end
    local d = state.dest
    if d and d.map == map and d.x == x and d.y == y and state.source == source then return end
    local dest = Point(map, x, y, { kind = "dest", name = label })
    if not dest then GPS.Stop(source); return end
    Start(dest, source)
end

-- Stops the GPS; with a source, only if the GPS is guiding for that source.
function GPS.Stop(source)
    if source and state.source ~= source then return end
    local resume = state.source == "writs" and state.suspended
    if state.zygor then
        local Z = Zygor()
        if Z and Z.Pointer.ClearWaypoints then pcall(Z.Pointer.ClearWaypoints, Z.Pointer, "manual") end
    end
    state.dest, state.source, state.legs, state.eta, state.zygor, state.suspended = nil, nil, nil, nil, nil, nil
    if ticker then ticker:Cancel(); ticker = nil end
    if GPS.Hide then GPS.Hide() end
    -- back to the dungeon step the detour interrupted, if the guide still wants its arrow
    if resume and WLDTDB and WLDTDB.arrow ~= false and not WLDTDB.hidden then Start(resume, "dungeon") end
end

function GPS.Active() return state.dest ~= nil end
function GPS.DestName() return state.dest and state.dest.name end
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

function GPS.TeleportLeg()
    local leg = state.legs and state.legs[1]
    return leg and leg.kind == "teleport" and leg or nil
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

-- /wl gps: stops the GPS when it guides; otherwise the dungeon arrow comes back if a route is
-- running, else the Comptoir's tour starts.
function WP.StopOrStartGPS()
    if GPS.Active() then WP.StopGPS(); return end
    if root.GuideStatus and root.GuideStatus() and WLDTDB and WLDTDB.arrow == false and root.ToggleArrow then
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
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("QUEST_TURNED_IN")
f:RegisterEvent("TAXIMAP_OPENED")
f:RegisterEvent("ZONE_CHANGED_NEW_AREA")
f:RegisterEvent("PLAYER_CONTROL_GAINED")
f:RegisterEvent("LOADING_SCREEN_DISABLED")
f:SetScript("OnEvent", function(_, event, a1)
    if event == "PLAYER_LOGIN" then
        -- A tour does not survive a reload: start it again from the button.
        if WLWritsCharDB then WLWritsCharDB.gps = false end
    elseif event == "TAXIMAP_OPENED" then
        RecordTaxi()
        GPS.Replan()
        if Opt("autoFlight", false) and GPS.FlightLeg() then C_Timer.After(0.3, GPS.TakeFlight) end
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
