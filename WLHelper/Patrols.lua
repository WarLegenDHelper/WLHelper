-- Patrols.lua: the path of an NPC whose quest point is set after Data.lua (Curated.lua gives every
-- Rexxar quest one shared point at the Feralas end of his round). Same form as s.sp / f.sp in
-- Data.lua: { {x, y}, ... } in path order on the point's map, a third value for another map.
-- Engine.lua (ns.PatrolSpots) and the GPS (Writs/Route.lua) read them.
local _, ns = ...

local PATHS = {
  -- Rexxar: his spawn at the north end of the Desolace road (Stonetalon border), then northern Feralas
  Rexxar = { m = 1444, sp = { { 54, 2, 1443 }, { 44.8, 7.4 }, { 46.4, 18.2 } } },
}

for _, q in pairs(ns.Q or {}) do
  for _, w in ipairs({ "s", "f" }) do
    local p = q[w]
    local P = type(p) == "table" and p.n and PATHS[p.n]
    if P and p.m == P.m and not p.sp then p.sp = P.sp end
  end
end
