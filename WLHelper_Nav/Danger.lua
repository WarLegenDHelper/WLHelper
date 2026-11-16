-- WLHelper_Nav: zone danger for WalkTo (how much dearer a walk through a zone far above the character is).
-- Adapted on 2026-11-15 for WL Helper from Polestar 0.3.7.2's Nav/Danger.lua (Danger.Mult, Danger.Table, Danger.Level,
-- Danger.ZoneAt) and the zone levels of its Maps/ZoneLevels.lua (min and max only; Polestar generated them from
-- pfQuest's data, MIT). Copyright (c) 2026 The Polestar authors. The Polestar addon is licensed under the GNU General
-- Public License, version 3 only (GPL-3.0-only), so this file is too; see this folder's LICENSE. WL Helper's changes:
-- the zone levels are a local table here instead of ns.Maps, the level is read from UnitLevel("player") (through
-- issecretvalue) and PLAYER_LEVEL_UP is not watched (WalkTo reads the level for each walk), Danger.Along (the journey
-- planner's straight walks) is not copied.
--
-- Polestar's rule, unchanged: a zone is dangerous for a character of level L when its lowest level is at least L + 4
-- (x3 per step), far above when it is more than L + 10 (x20, the other faction's towns' strength); a zone without a
-- level range never counts, nor do the zones the walk starts and ends in. The router (Routing/Path.lua) takes the
-- table as opts.danger; no zone is ever closed. The zone danger idea and its 4-level threshold come from Ding! by
-- Yendi (ding-travel 2bccf01, its dangerAbove), as Polestar's file says.
--
--   Danger.Level() -> level | nil                 the player's (UnitLevel, nil when unread or secret).
--   Danger.ZoneAt(map, x, y) -> uiMapID | nil     the zone of a world point on map (Path.ZoneAt).
--   Danger.Mult(level, uiMapID) -> 1 | 3 | 20
--   Danger.Table(level, startZone, goalZone) -> { [uiMapID] = 3 | 20 } | nil, signature
--     built once per level and zone pair (the router keys its caches by the table's entries).

local _, ns = ...
local Path = ns.Path

local type, ipairs, sort, concat, pcall, next = type, ipairs, table.sort, table.concat, pcall, next

local DANGEROUS = 4 -- a zone's lowest level at least this far above: x DANGEROUS_MULT
local FAR_ABOVE = 10 -- more than this far above: x FAR_MULT
local DANGEROUS_MULT = 3
local FAR_MULT = 20

-- [uiMapID] = { minLevel, maxLevel } (Polestar 0.3.7.2, Maps/ZoneLevels.lua)
local levels = {
	[1411] = { 1, 10 }, -- Durotar
	[1412] = { 3, 27 }, -- Mulgore
	[1413] = { 8, 28 }, -- The Barrens
	[1416] = { 24, 39 }, -- Alterac Mountains
	[1417] = { 31, 39 }, -- Arathi Highlands
	[1418] = { 36, 43 }, -- Badlands
	[1419] = { 45, 54 }, -- Blasted Lands
	[1420] = { 1, 10 }, -- Tirisfal Glades
	[1421] = { 11, 19 }, -- Silverpine Forest
	[1422] = { 51, 57 }, -- Western Plaguelands
	[1423] = { 54, 59 }, -- Eastern Plaguelands
	[1424] = { 21, 33 }, -- Hillsbrad Foothills
	[1425] = { 42, 51 }, -- The Hinterlands
	[1426] = { 2, 10 }, -- Dun Morogh
	[1427] = { 45, 56 }, -- Searing Gorge
	[1428] = { 50, 56 }, -- Burning Steppes
	[1429] = { 1, 10 }, -- Elwynn Forest
	[1430] = { 55, 60 }, -- Deadwind Pass
	[1431] = { 21, 39 }, -- Duskwood
	[1432] = { 10, 18 }, -- Loch Modan
	[1433] = { 16, 25 }, -- Redridge Mountains
	[1434] = { 32, 45 }, -- Stranglethorn Vale
	[1435] = { 36, 45 }, -- Swamp of Sorrows
	[1436] = { 10, 18 }, -- Westfall
	[1437] = { 21, 29 }, -- Wetlands
	[1438] = { 1, 10 }, -- Teldrassil
	[1439] = { 10, 20 }, -- Darkshore
	[1440] = { 19, 41 }, -- Ashenvale
	[1441] = { 25, 34 }, -- Thousand Needles
	[1442] = { 16, 26 }, -- Stonetalon Mountains
	[1443] = { 31, 38 }, -- Desolace
	[1444] = { 41, 51 }, -- Feralas
	[1445] = { 36, 43 }, -- Dustwallow Marsh
	[1446] = { 42, 50 }, -- Tanaris
	[1447] = { 47, 54 }, -- Azshara
	[1448] = { 48, 54 }, -- Felwood
	[1449] = { 49, 54 }, -- Un'Goro Crater
	[1450] = { 23, 60 }, -- Moonglade
	[1451] = { 55, 60 }, -- Silithus
	[1452] = { 54, 59 }, -- Winterspring
	[2482] = { 56, 60 }, -- Mount Hyjal
	[2521] = { 2, 10 }, -- Zephras Isle
	[2548] = { 37, 57 }, -- Riverglades
}

local Danger = {}
ns.Danger = Danger

local function readable(v)
	if issecretvalue and issecretvalue(v) then
		return nil
	end
	return v
end

function Danger.Level()
	if not UnitLevel then
		return nil
	end
	local ok, level = pcall(UnitLevel, "player")
	level = ok and readable(level) or nil
	return type(level) == "number" and level > 0 and level or nil
end

function Danger.ZoneAt(map, x, y)
	if not (Path and Path.ZoneAt and map and x and y) then
		return nil
	end
	local ok, zone = pcall(Path.ZoneAt, map, x, y)
	return ok and zone or nil
end

function Danger.Mult(level, uiMapID)
	local v = uiMapID and levels[uiMapID]
	if type(level) ~= "number" or not v then
		return 1
	end
	local lo = v[1]
	if lo > level + FAR_ABOVE then
		return FAR_MULT
	end
	if lo >= level + DANGEROUS then
		return DANGEROUS_MULT
	end
	return 1
end

local cache, cacheLevel = {}, nil -- [startZone:goalZone] = { table | false, signature } at cacheLevel

function Danger.Table(level, startZone, goalZone)
	if type(level) ~= "number" then
		return nil, ""
	end
	if cacheLevel ~= level then
		cache, cacheLevel = {}, level
	end
	local key = (startZone or 0) .. ":" .. (goalZone or 0)
	local e = cache[key]
	if not e then
		local t, ids = {}, {}
		for id in next, levels do
			if id ~= startZone and id ~= goalZone then
				local m = Danger.Mult(level, id)
				if m > 1 then
					t[id], ids[#ids + 1] = m, id
				end
			end
		end
		sort(ids)
		for i, id in ipairs(ids) do
			ids[i] = id .. "=" .. t[id]
		end
		e = { #ids > 0 and t or false, concat(ids, ",") }
		cache[key] = e
	end
	return e[1] or nil, e[2]
end
