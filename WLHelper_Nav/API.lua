-- WLHelper_Nav: WL Helper's walking router (main file).
-- A modified copy, made on 2026-11-15, of Polestar Nav 0.3.7.2 (Copyright (c) 2026 The Polestar authors), whose router
-- started from Shortest Path Forever v1.16.0 by Cillian Berragan (Copyright (C) 2026 Cillian Berragan,
-- https://github.com/cjber/shortest-path-forever, used with his permission). This program is free software: you can
-- redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software
-- Foundation, either version 3 of the License, or (at your option) any later version. It is distributed WITHOUT ANY
-- WARRANTY; see the GNU General Public License in this folder's LICENSE. NOTICE.md lists the changes, CREDITS.md is
-- Polestar's own credits page.
--
-- Same algorithm, same costs, same map bytes as Polestar Nav: only the globals are renamed (PolestarPathData ->
-- WLHelperNavData, Polestar_NavEngine -> WLHelperNav, Polestar_NavCosts -> WLHelperNavCosts, PolestarNavChokepoints
-- -> WLHelperNavChokepoints) and the part addons (WLHelper_Nav_EK, WLHelper_Nav_Kalimdor), so both load together.
-- Nothing is needed from the Polestar addon.
--
-- Loading: WLHelper_Nav is LoadOnDemand (C_AddOns.LoadAddOn("WLHelper_Nav"), never in combat: it builds a few MB of
-- packed strings). A continent's walking maps ship in their own LoadOnDemand addon (WLHelper_Nav_EK for map 0,
-- WLHelper_Nav_Kalimdor for map 1), which the router loads itself the first time a search on that map runs
-- (Routing/PathGrid.lua EnsurePart; out of combat). Zephras Isle (2991) is small and ships here.
--
-- Public API: the global WLHelperNav (the router's Path table). Points are in UnitPosition's frame: { x = north,
-- y = west, z = height or nil }; map is the instance map ID (0 Eastern Kingdoms, 1 Kalimdor, 2991 Zephras Isle).
--
--   WLHelperNav.Available(map) -> boolean
--     walking routes can be searched on map (its data is present; its part addon may still be unloaded).
--   WLHelperNav.Find(map, from, to, callback, opts) -> job
--     async (sliced over frames, Path.budget = 3 ms a frame). callback(points, cost, job) with points
--     { { map, x, y, z }, ... } from start to goal (points.wet = yards over water, job.yards = drawn length,
--     job.hubs = hostile towns entered), or callback(nil, reason, job), reason "nodata" | "outside" | "offmesh" |
--     "unreachable" | "error". opts is the waterWalking boolean or { waterWalking, profile = "Alliance" | "Horde" |
--     nil, style = "fastest" | "balanced" | "roads" | nil, danger = { [uiMapID] = mult >= 1 } | nil, homeHub = true |
--     nil } (Routing/Path.lua options()). Set job.urgent = true on the walk an arrow follows.
--   WLHelperNav.FindCost(map, from, to, callback, opts) -> job        as Find, cost only (no geometry).
--   WLHelperNav.FindMany(map, from, targets, callback, opts, reverse, progress) -> job    costs to many targets.
--   WLHelperNav.FindCoarse(map, from, to, callback, opts, whole) -> job   the route's shape at once.
--   WLHelperNav.Cancel(job)            drops a queued or running search (its callback never runs).
--   WLHelperNav.Busy() -> boolean      a search ran or is queued since the last call.
--   WLHelperNav.Sight(map, x1, y1, z1, x2, y2, z2, profile) -> boolean | nil
--     can a player walk straight from one point to the other (decoded clusters only, nil otherwise).
--   WLHelperNav.HubAt(map, x, y, profile), ZoneAt(map, x, y), FindSync(...) (tests): Polestar's, unchanged.
--
-- Added for WL Helper (below Polestar's API.lua, at the end of this file):
--   WLHelperNav.PlayerPosition() -> map, x, y, z | nil      the player in the router's frame (UnitPosition).
--   WLHelperNav.MapToWorld(uiMap, x, y) -> map, wx, wy | nil  a UI map point (0..1, or 0..100) in the router's frame.
--   WLHelperNav.WorldToMap(map, wx, wy, uiMap?) -> uiMap, x, y | nil   back to a UI map point (0..1).
--   WLHelperNav.WalkTo(uiMap, x, y, callback, opts) -> job | nil
--     a walk from the player to the UI map point (x, y in 0..1 as C_Map, or 0..100) on the player's continent, priced
--     as Polestar prices the arrow's walk: the player's faction (UnitFactionGroup), style "balanced" (Polestar's
--     default), homeHub when the walk starts or ends in a town of the other faction. callback(waypoints, cost, job)
--     with waypoints = { { uiMap, x, y, wx = north, wy = west, z = height | nil }, ... } (uiMap, x, y: the zone map
--     each point lies in and its 0..1 position, for a trail on the world map or minimap; opts.uiMap projects every
--     point on that one map instead), waypoints.yards (drawn length), waypoints.cost, waypoints.map (instance map),
--     waypoints.wet; or callback(nil, reason, job), reason as Find's or "nomap" (the UI map point has no world
--     position), "noplayer", "continent" (the point is on another continent), "nodata". opts: { waterWalking,
--     profile (false: none), style, danger, z (goal height), uiMap }. Returns Find's job (nil when it answered at once).
--     As Polestar's Nav/Walk.lua: waterWalking defaults to UnitIsGhost("player") (a ghost walks on water), and danger
--     to Danger.lua's table at UnitLevel("player") without the walk's start and goal zones (a zone 4+ levels above
--     costs 3x, 10+ above 20x); danger = false prices no zone.

-- Polestar Nav's original API.lua notes, unchanged but for the renamed globals (upstream the global is
-- Polestar_NavEngine and the maps PolestarPathData; Polestar's own addon, not copied here, keeps it as ns.Nav.Path and
-- its Nav/Follow.lua and docs/ARCHITECTURE.md are named below). WL Helper's API is documented above.
--
-- Polestar_Nav's handoff to Polestar: the global Polestar_NavEngine (WLHelperNav here) is the
-- walking router's Path table (Routing/, Polestar's router, started from
-- Shortest Path Forever v1.16.0 by Cillian Berragan), which Polestar's Nav
-- keeps as ns.Nav.Path. Its calls are Shortest Path Forever's: Find(map, from,
-- to, callback, opts), FindCost, FindMany, Cancel(job), Busy(), where opts is
-- the waterWalking flag or { waterWalking, profile } (Routing/Path.lua), with
-- points in UnitPosition's frame (x north, y west, z optional) and map the
-- instance map ID (0 Eastern Kingdoms, 1 Kalimdor, 2991 Zephras Isle). The
-- maps are Polestar's own (`nav pack`, PACK.json: maps format 2, 128 cells a
-- tile, 4.17 yd). The engine reads only WLHelperNavData, our own copy
-- of the maps, never an installed Shortest Path Forever's tables (its engine
-- evicts decoded entries while ours may be searching them). Added here:
--
--   Path.Available(map) -> true when walking routes can be found on that map
--   Path.Sight(map, x1, y1, z1, x2, y2, z2, profile) -> can a player walk
--     straight from one point to the other (Routing/PathGrid.lua; decoded
--     clusters only, nil otherwise): the arrow beside its path (Nav/Follow.lua)
--
-- Memory ceilings (docs/ARCHITECTURE.md, "In-game walking routes"). A
-- decoded cluster is a few byte strings (Routing/PathGrid.lua): 0.2-0.45 MB
-- on Leffe's maps (2-10 MB as tables before, 2026-10-25), so 8 MB of grids
-- hold a long walk's clusters (a 3,000 yd walk decodes about 10) without
-- evicting one mid-search, and stay held between searches until the router
-- has rested a minute (Routing/PathJobs.lua, Path.restSeconds). The decoded graph (entrance lists and each
-- cluster's graph string, about 40 KB a cluster on his maps) may grow to 16
-- MB while a search runs (a batch of walks 3,000 yd round the Trade District
-- reads 209 clusters' graphs: about 9 MB) and is trimmed to 1 MB at rest.
local _, ns = ...
local Path = ns.Path

Path.cacheKB = 8 * 1024
Path.graphKB = 16 * 1024
Path.graphRestKB = 1024

function Path.Available(map)
	return map ~= nil and Path.HasData(map)
end

-- A map is used whole or not at all: one whose packed tables do not hold the
-- entries its `counts` promise (a part file missing from the folder, or one
-- that failed to load) is dropped, and so is every map when the client lacks
-- C_EncodingUtil's DecodeBase64 or DecompressString (the engine would raise
-- a Lua error decoding the first cluster). Path.HasData is then false for
-- that map and Polestar's arrow points straight. A part's bytes are not
-- checked here: the shipped files are pinned by sha256. A map whose parts ship in
-- their own load-on-demand addon (D.part, maps format 5) is checked the same
-- way once that addon loads (Routing/PathGrid.lua EnsurePart).
local enc = C_EncodingUtil
local decodes = type(enc) == "table" and type(enc.DecodeBase64) == "function" and type(enc.DecompressString) == "function"
for map, D in pairs(type(WLHelperNavData) == "table" and WLHelperNavData or {}) do
	local whole = decodes and type(D) == "table"
	if whole and not D.part and type(D.packed) == "table" and type(D.counts) == "table" then
		for field, want in pairs(D.counts) do
			local n = 0
			for _ in pairs(D.packed[field] or {}) do
				n = n + 1
			end
			if n ~= want then
				whole = false
				break
			end
		end
	end
	if not whole then
		WLHelperNavData[map] = nil
	end
end


---------------------------------------------------------------------------
-- WL Helper additions (2026-11-15): coordinates and WalkTo. Copyright (c) 2026 WaR LegenD, GPL-3.0-or-later.
---------------------------------------------------------------------------

local function vec(x, y)
	if CreateVector2D then
		return CreateVector2D(x, y)
	end
	return { x = x, y = y }
end

local function readable(v)
	if issecretvalue and issecretvalue(v) then
		return nil
	end
	return v
end

local function xyOf(pos)
	if pos == nil then
		return nil
	end
	local ok, x, y = pcall(function()
		if pos.GetXY then
			return pos:GetXY()
		end
		return pos.x, pos.y
	end)
	x, y = ok and readable(x), ok and readable(y)
	if type(x) ~= "number" or type(y) ~= "number" then
		return nil
	end
	return x, y
end

-- The player in the router's frame: instance map, x (north), y (west), z (nil when unread; Forever's client has
-- given exactly 0 where the ground is not, so 0 is unread too). UnitPosition first, else the player's map position.
function Path.PlayerPosition()
	if UnitPosition then
		local ok, x, y, z, instance = pcall(UnitPosition, "player")
		if ok then
			x, y, z, instance = readable(x), readable(y), readable(z), readable(instance)
			if type(x) == "number" and type(y) == "number" and instance ~= nil then
				return instance, x, y, (type(z) == "number" and z ~= 0) and z or nil
			end
		end
	end
	if C_Map and C_Map.GetBestMapForUnit and C_Map.GetPlayerMapPosition then
		local ok, m = pcall(C_Map.GetBestMapForUnit, "player")
		local pos = ok and m and C_Map.GetPlayerMapPosition(m, "player")
		local px, py = xyOf(pos)
		-- (0, 0) is what the client gives when it has no position (Polestar's Compat.GetPlayerMapPosition).
		if px and not (px == 0 and py == 0) then
			local c, wx, wy = Path.MapToWorld(m, px, py)
			if c then
				return c, wx, wy, nil
			end
		end
	end
	return nil
end

-- A UI map point (x, y in 0..1 as C_Map's; above 1 (+1e-6, a map edge's rounding) the pair is read as percent) -> instance map, x (north), y (west).
function Path.MapToWorld(uiMap, x, y)
	if not (uiMap and x and y and C_Map and C_Map.GetWorldPosFromMapPos) then
		return nil
	end
	if x > 1 + 1e-6 or y > 1 + 1e-6 then
		x, y = x / 100, y / 100
	end
	local ok, c, pos = pcall(C_Map.GetWorldPosFromMapPos, uiMap, vec(x, y))
	local wx, wy = xyOf(ok and pos or nil)
	if not (ok and c and wx) then
		return nil
	end
	return c, wx, wy
end

-- A point of the router's frame on instance map -> the UI map it lies in (or uiMap when given), x, y in 0..1.
function Path.WorldToMap(map, wx, wy, uiMap)
	if not (map and wx and wy and C_Map and C_Map.GetMapPosFromWorldPos) then
		return nil
	end
	local ok, m, pos = pcall(C_Map.GetMapPosFromWorldPos, map, vec(wx, wy), uiMap)
	local x, y = xyOf(ok and pos or nil)
	if not (ok and m and x) then
		return nil
	end
	return m, x, y
end

local function faction()
	local f = readable(UnitFactionGroup and UnitFactionGroup("player"))
	return (f == "Alliance" or f == "Horde") and f or nil
end

function Path.WalkTo(uiMap, x, y, callback, opts)
	opts = type(opts) == "table" and opts or {}
	local function answer(points, why, job)
		if callback then
			callback(points, why, job)
		end
	end
	local tc, tx, ty = Path.MapToWorld(uiMap, x, y)
	if not tc then
		answer(nil, "nomap")
		return nil
	end
	local pc, px, py, pz = Path.PlayerPosition()
	if not pc then
		answer(nil, "noplayer")
		return nil
	end
	if pc ~= tc then
		answer(nil, "continent")
		return nil
	end
	if not Path.Available(tc) then
		answer(nil, "nodata")
		return nil
	end
	-- Polestar's Nav/Walk.lua opts(): faction, route style, and homeHub when the walk starts or ends in a town of
	-- the other faction (it then takes the town's own streets and gate).
	local profile = opts.profile
	if profile == nil then
		profile = faction()
	elseif profile == false then
		profile = nil
	end
	local home
	if profile and Path.HubAt then
		home = Path.HubAt(tc, px, py, profile) or Path.HubAt(tc, tx, ty, profile)
	end
	local water = opts.waterWalking
	if water == nil then
		water = UnitIsGhost and readable(UnitIsGhost("player")) == true or false
	end
	local danger = opts.danger
	if danger == nil then
		local D = ns.Danger
		local level = D and D.Level()
		danger = level and D.Table(level, D.ZoneAt(tc, px, py), D.ZoneAt(tc, tx, ty)) or nil
	elseif danger == false then
		danger = nil
	end
	local find = {
		waterWalking = water and true or false,
		profile = profile,
		style = opts.style or "balanced",
		danger = danger,
		homeHub = home and true or nil,
	}
	return Path.Find(tc, { x = px, y = py, z = pz }, { x = tx, y = ty, z = opts.z }, function(points, cost, job)
		if not points then
			return answer(nil, cost, job)
		end
		local out = { map = tc, cost = cost, yards = job and job.yards, wet = points.wet, hubs = job and job.hubs }
		for i = 1, #points do
			local p = points[i]
			local m, mx, my = Path.WorldToMap(tc, p.x, p.y, opts.uiMap)
			if not m and not opts.uiMap then
				m, mx, my = Path.WorldToMap(tc, p.x, p.y, uiMap)
			end
			out[#out + 1] = { m, mx, my, wx = p.x, wy = p.y, z = p.z }
		end
		answer(out, cost, job)
	end, find)
end

WLHelperNav = Path
