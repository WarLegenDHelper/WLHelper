-- Writs/Trail.lua: the walking path (WP.Trail), shared by every guide the GPS serves (dungeon guide
-- steps, the Writs tour, the city tour, /way...). When a walking leg of the GPS (Route.lua: a "ride" leg,
-- or the straight line when no route is planned) ends 60 to 3000 yards away on your continent, and
-- the walking router WLHelper_Nav (a separate GPL addon, load on demand) has maps for it, the router is
-- asked for a real path round hills and through gates. The arrow then points at the end of the path's
-- segment you walk along (the next corner once you are within 20 yards of it), and its distance is
-- what is left to walk from your place on the path. You stray more than 40 yards from it: the path is
-- asked again (at most every 10 seconds, once you moved 30 yards), the old one kept meanwhile; failed
-- questions wait 30, 60, 120 seconds, and stop after 3.
-- Flights, boats, zeppelins and teleports stay as Route.lua plans them: a path is only for walking.
-- The router is never loaded nor asked in combat: the question waits for the end of the fight. It is
-- loaded on the frame after the first question (not inside the arrow's update), once a session.
--
-- The path is drawn as dots ringed in black on the world map (for the map shown, refreshed twice a
-- second while it is open, and on each zoom) and on the minimap (10 times a second, rotating minimap,
-- zoom and indoor scale honoured, round or square), fading a little near you, with a pin on the exact
-- destination. A dot keeps its size on screen whatever the map's zoom (its canvas size is worked out
-- from the canvas's and UIParent's effective scales), and the dots sit about GAP diameters apart on
-- screen too (on the world map in steps of sqrt(2), so a small zoom does not move them); never under
-- MIN_SHARE of their size at 1080p and UI scale 1, however small the UI scale.
-- "Aller à" (GoTo.lua) still follows its own trail: its trail is drawn here, it is not asked twice.
--
-- API: WP.Trail.For(target) -> trail | nil (target: { map, x, y } in percent or { cont, wx, wy });
-- WP.Trail.Clear(); WP.Trail.Current() -> nil | { cont, pts = { { cont, wx, wy }, ... }, at, target,
-- yards }; WP.Trail.OnReady(fn) (fn(trail) when a path arrives); WP.Trail.Apply(now) (GPS.Now calls it);
-- WP.Trail.WalkCost(a, b, fn) -> asked? (fn(yards) | fn(nil, reason)): a walk's real length, for Route.lua's plans.
-- Settings: WLWritsDB.trail = { map = true, minimap = true, mapSize, minimapSize = "small" | "medium" |
-- "large", color = "accent" | "yellow" | "cyan" }: Trail.MapOn / SetMap, MinimapOn / SetMinimap,
-- MapSize / SetMapSize, MinimapSize / SetMinimapSize, Color / SetColor.
local ADDON, root = ...
root.Writs = root.Writs or {}
local ns = root.Writs
local WP = ns.WP
local GPS = WP.GPS
local S = ns.S
local C = S and S.C or {}

local Trail = {}
WP.Trail = Trail

ns.AddEnglish({
    ["Chemin à pied sur la carte"] = "Walking path on the map",
    ["Sur la minimap"] = "On the minimap",
    ["Des points sur la carte du monde montrent le chemin à pied jusqu'au point du GPS, avec une épingle sur l'endroit exact (WL Helper Nav)."] =
        "Dots on the world map show the walking path to the GPS point, with a pin on the exact spot (WL Helper Nav).",
    ["Les mêmes points sur la minimap, autour de toi."] = "The same dots on the minimap, around you.",
    ["Taille des points sur la carte"] = "Dot size on the map",
    ["Taille des points sur la minimap"] = "Dot size on the minimap",
    ["Couleur du chemin"] = "Path colour",
    ["Petits"] = "Small",
    ["Moyens"] = "Medium",
    ["Grands"] = "Large",
    ["Rouge"] = "Red",
    ["Jaune"] = "Yellow",
    ["Cyan"] = "Cyan",
})

local NAV_ADDON = "WLHelper_Nav"
local ASK_FROM = 60          -- yards: a target nearer than this needs no path (the arrow goes straight)
local ADVANCE = 20           -- yards: the next corner once you are this near
local LOOKAHEAD = 6          -- corners checked ahead (a shortcut skips the ones between)
local OFF_TRAIL = 40         -- yards from the path: asked again
local REASK_EVERY = 10       -- seconds between two questions for the same target
local RETRY_AFTER = 30       -- seconds before a failed question is asked again (60, then 120; 3 failures: never)
local GIVE_UP = 3            -- failed questions for one target before it is never asked again
local LOST_AFTER = 60        -- seconds: a question never answered (the router dropped it) counts as failed
local MOVED = 30             -- yards you must move from where the path was last asked before it is asked again
local MAX_ASK = 3000         -- yards: a target further than this is not asked (the arrow goes straight until nearer)
local MARGIN = 3             -- yards: a later segment must be this much nearer to be the one you walk along
-- the continents WLHelper_Nav has walking maps for (checked before loading it; once loaded, Available decides)
local NAV_CONTS = { [0] = true, [1] = true, [2991] = true }
local SIMPLIFY = 2.5         -- yards: corners that do not bend the path by this much are dropped
local THIN = 8               -- yards: a corner this near the previous one is dropped
local MAP_EVERY, MM_EVERY = 0.5, 0.1
local MAP_CAP, MM_CAP = 400, 120                       -- most dots drawn
-- Dot sizes (the disc's width): world map in UIParent units (x1.4 = pixels at 1080p, UI scale 1),
-- minimap in the minimap's units; the pin's head likewise.
local SIZES = {
    map = { small = 6, medium = 8, large = 11 },
    minimap = { small = 4, medium = 5, large = 7 },
}
local PINS = {
    map = { small = 13, medium = 16, large = 20 },
    minimap = { small = 9, medium = 11, large = 13 },
}
local RING = { map = 1.5, minimap = 1 }  -- the black ring's width round a dot, same units
local RING_ALPHA = 0.85
local GAP = 2.5               -- dots this many diameters apart on screen
local MIN_STEP = 2            -- yards: the world map's dots never nearer than this (steps of sqrt(2) above)
local MM_MIN_STEP = 3         -- yards: the minimap's
local REF_PX = 1080 / 768     -- physical pixels per UI unit at 1080p and UI scale 1
local MIN_SHARE = 0.8         -- a dot never shows under this share of its size there, whatever the UI scale
local MAP_UI = 1000           -- the map's width in UI units when no canvas says it (tests)
-- dot.tga's disc (half opacity) spans 48 of its 128 px, pin.tga's head 64: the textures are drawn this
-- much bigger than the disc wanted (the old 7 px dot texture showed a 2.6 px disc)
local DOT_FILL, PIN_FILL = 48 / 128, 64 / 128
local PIN_TIP = 14 / 128      -- pin.tga's tip sits on its row 113 of 128
local FADE = 45              -- yards: the dots fade a little over this distance from you
local NEAR_ALPHA = 0.5       -- the opacity of a dot under your feet (1 from FADE yards on)
local COLORS = { yellow = { 1, 0.82, 0.15 }, cyan = { 0.25, 0.85, 1 } }   -- "accent": the theme's red
local MEDIA = "Interface\\AddOns\\WLHelper\\Media\\Icons\\"
-- the minimap's diameter in yards per zoom level, for a client without C_Minimap.GetViewRadius
local OUTDOOR = { [0] = 466 + 2 / 3, 400, 333 + 1 / 3, 266 + 2 / 3, 200, 133 + 1 / 3 }
local INDOOR = { [0] = 300, 240, 180, 120, 80, 50 }

local function IsSecret(v) return issecretvalue ~= nil and issecretvalue(v) end
local function Num(v) if type(v) == "number" and not IsSecret(v) then return v end end
local function InCombat() return InCombatLockdown and InCombatLockdown() and true or false end
local function Clock() return GetTime and GetTime() or 0 end
local function Yards(ax, ay, bx, by)
    local dx, dy = ax - bx, ay - by
    return math.sqrt(dx * dx + dy * dy)
end

-- ---------------------------------------------------------------- settings

local function Opts()
    local db = WLWritsDB
    if not db then return {} end
    if type(db.trail) ~= "table" then db.trail = { map = true, minimap = true } end
    return db.trail
end
function Trail.MapOn() return Opts().map ~= false end
function Trail.MinimapOn() return Opts().minimap ~= false end
function Trail.SetMap(on) Opts().map = on and true or false; Trail.Refresh() end
function Trail.SetMinimap(on) Opts().minimap = on and true or false; Trail.Refresh() end
local SIZE_OK = { small = true, medium = true, large = true }
local COLOR_OK = { accent = true, yellow = true, cyan = true }
local function Pick(key, ok, default)
    local v = Opts()[key]
    return ok[v] and v or default
end
function Trail.MapSize() return Pick("mapSize", SIZE_OK, "medium") end
function Trail.MinimapSize() return Pick("minimapSize", SIZE_OK, "medium") end
function Trail.Color() return Pick("color", COLOR_OK, "accent") end
local function Setter(key, ok)
    return function(v) if ok[v] then Opts()[key] = v; if Trail.Refresh then Trail.Refresh() end end end
end
Trail.SetMapSize = Setter("mapSize", SIZE_OK)
Trail.SetMinimapSize = Setter("minimapSize", SIZE_OK)
Trail.SetColor = Setter("color", COLOR_OK)
-- the walking router may be turned off in the options ("Chemins à pied", WLWritsDB.gotoWalk)
local function WalkOn() return not (WLWritsDB and WLWritsDB.gotoWalk == false) end

-- ---------------------------------------------------------------- the router

local navTried = false
local function NavInstalled()
    if type(rawget(_G, "WLHelperNav")) == "table" then return true end
    local A = C_AddOns
    local info = A and A.GetAddOnInfo or rawget(_G, "GetAddOnInfo")
    if type(info) ~= "function" then return false end
    local ok, name, _, _, loadable, reason = pcall(info, NAV_ADDON)
    return ok and name ~= nil and reason ~= "MISSING" and (loadable or reason == "DEMAND_LOADED") and true or false
end

-- The router, loaded on first use, never in combat (it builds a few MB of strings as it loads).
local function Nav()
    local N = rawget(_G, "WLHelperNav")
    if type(N) == "table" and (type(N.WalkTo) == "function" or type(N.Find) == "function") then return N end
    if navTried or InCombat() or not NavInstalled() then return nil end
    navTried = true     -- one try a session: a router that failed to load is not asked again
    local load = (C_AddOns and C_AddOns.LoadAddOn) or rawget(_G, "LoadAddOn")
    if type(load) ~= "function" then return nil end
    pcall(load, NAV_ADDON)
    N = rawget(_G, "WLHelperNav")
    if type(N) == "table" and (type(N.WalkTo) == "function" or type(N.Find) == "function") then return N end
end
function Trail._ResetNav() navTried = false end

-- ---------------------------------------------------------------- positions

local function PlayerWorld()
    local map = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
    if not map then return nil end
    local ok, pos = pcall(C_Map.GetPlayerMapPosition, map, "player")
    if not (ok and pos and pos.GetXY) then return nil end
    local x, y = pos:GetXY()
    x, y = Num(x), Num(y)
    if not x then return nil end
    local p = GPS.Point(map, x * 100, y * 100)
    if p then return p.cont, p.wx, p.wy end
end

-- The target's key, kept on the target while its world point stays (GPS.Now asks several times a second).
local function Key(t)
    if t._wlKey and t._wlKx == t.wx and t._wlKy == t.wy and t._wlKc == t.cont then return t._wlKey end
    local k = t.cont .. ":" .. math.floor(t.wx + 0.5) .. ":" .. math.floor(t.wy + 0.5)
    t._wlKey, t._wlKx, t._wlKy, t._wlKc = k, t.wx, t.wy, t.cont
    return k
end

-- A target as a world point (cont, wx, wy), from map percent when it has no world position yet.
local function AsWorld(t)
    if type(t) ~= "table" then return nil end
    if t.cont and Num(t.wx) and Num(t.wy) then return t end
    if t.map and Num(t.x) and Num(t.y) then
        local p = GPS.Point(t.map, t.x, t.y)
        if p then t.cont, t.wx, t.wy = p.cont, p.wx, p.wy; return t end
    end
end

-- ---------------------------------------------------------------- the path

local cur          -- the trail being followed: { key, cont, target, pts, at, job, askedAt, ... }
local token = 0
local listeners = {}
local external     -- GoTo's own trail, drawn here (it follows it itself)

local function Cancel(t)
    if t and t.job then
        local N = rawget(_G, "WLHelperNav")
        if N and N.Cancel then pcall(N.Cancel, t.job) end
        t.job = nil
    end
end

-- Distance from (px, py) to the segment a-b, and how far along it (0..1) the nearest point is.
local function SegDist(px, py, ax, ay, bx, by)
    local dx, dy = bx - ax, by - ay
    local l2 = dx * dx + dy * dy
    local k = 0
    if l2 > 0 then k = math.max(0, math.min(1, ((px - ax) * dx + (py - ay) * dy) / l2)) end
    return Yards(px, py, ax + k * dx, ay + k * dy), k
end

-- A failed question: asked again later and later (30, 60, 120 s), never after GIVE_UP failures.
local function Failed(t)
    t.failedAt = Clock()
    t.fails = (t.fails or 0) + 1
    if t.fails >= GIVE_UP then t.none = true end
end
local function RetryWait(t) return RETRY_AFTER * 2 ^ math.max(0, (t.fails or 1) - 1) end

-- The router's points (every few yards) as the arrow's corners: the ones that do not bend the path by
-- SIMPLIFY yards go (Douglas-Peucker), and so does a corner a few yards from the previous one; the
-- first (where you stood) and the last (the place) always stay.
local function Simplify(raw)
    local n = #raw
    if n <= 2 then return raw end
    local keep = { [1] = true, [n] = true }
    local stack = { 1, n }
    while #stack > 0 do
        local b = table.remove(stack); local a = table.remove(stack)
        local best, at = 0, nil
        local A, B = raw[a], raw[b]
        for i = a + 1, b - 1 do
            local d = SegDist(raw[i].wx, raw[i].wy, A.wx, A.wy, B.wx, B.wy)
            if d > best then best, at = d, i end
        end
        if at and best > SIMPLIFY then
            keep[at] = true
            stack[#stack + 1] = a; stack[#stack + 1] = at
            stack[#stack + 1] = at; stack[#stack + 1] = b
        end
    end
    local out, last = {}, nil
    for i = 1, n do
        if keep[i] then
            local p = raw[i]
            if i == 1 or i == n or not last or Yards(last.wx, last.wy, p.wx, p.wy) >= THIN then
                out[#out + 1] = p; last = p
            end
        end
    end
    return out
end
Trail._Simplify = Simplify

local function Fire(t)
    for _, fn in ipairs(listeners) do pcall(fn, t) end
    if Trail.Refresh then Trail.Refresh() end
end

-- The router's answer, for this question only (a newer one makes it stale).
local function Answer(t, my, points, why)
    if cur ~= t or t.token ~= my then return end
    t.job, t.waiting = nil, nil
    -- a failure keeps the path you had (a question asked again off the path)
    if type(points) ~= "table" then
        Failed(t)
        -- no map here, another continent, a point off the maps: never again for this target
        if why == "nodata" or why == "continent" or why == "nomap" or why == "outside" then t.none = true end
        return
    end
    local raw = {}
    for _, p in ipairs(points) do
        -- WalkTo gives wx (north), wy (west); Find gives x (north), y (west)
        local wx, wy = Num(p.wx), Num(p.wy)
        if not wx then wx, wy = Num(p.x), Num(p.y) end
        if wx and wy then raw[#raw + 1] = { cont = t.cont, wx = wx, wy = wy } end
    end
    if #raw == 0 then Failed(t); return end
    local pts = Simplify(raw)
    local yards = 0
    for i = 2, #pts do yards = yards + Yards(pts[i - 1].wx, pts[i - 1].wy, pts[i].wx, pts[i].wy) end
    t.pts, t.at, t.yards, t.failedAt, t.fails = pts, 1, Num(points.yards) or yards, nil, nil
    Fire(t)
end

local Ask
-- The router loads outside GPS.Now (the arrow's OnUpdate): on the next frame, then the question.
local function LoadThenAsk(t, px, py)
    t.loading = true
    C_Timer.After(0, function()
        t.loading = nil
        if cur ~= t or InCombat() then if cur == t and InCombat() then t.queued = true end; return end
        if not Nav() then t.none = true; return end
        Ask(t, px, py)
    end)
end

-- (px, py): where you stand, kept so a path is not asked again before you move MOVED yards.
function Ask(t, px, py)
    if not t or t.none or t.job or t.waiting or t.loading then return end
    if InCombat() then t.queued = true; return end
    t.queued = nil
    if not px then local pc; pc, px, py = PlayerWorld(); if pc ~= t.cont then px, py = nil, nil end end
    local loaded = rawget(_G, "WLHelperNav")
    if type(loaded) ~= "table" then
        -- not loaded yet: only for a continent it has maps for, and not inside the arrow's update
        if navTried or not NAV_CONTS[t.cont] or not NavInstalled() then t.none = true; return end
        if C_Timer and C_Timer.After then LoadThenAsk(t, px, py); return end
    end
    local N = Nav()
    if not N then t.none = true; return end
    if N.Available then
        local ok, yes = pcall(N.Available, t.cont)
        if ok and yes == false then t.none = true; return end
    end
    token = token + 1
    local my = token
    t.token, t.askedAt, t.waiting = my, Clock(), true
    t.askX, t.askY = px, py
    local target = t.target
    local ok, job
    if target.map and Num(target.x) and Num(target.y) and type(N.WalkTo) == "function" then
        ok, job = pcall(N.WalkTo, target.map, target.x / 100, target.y / 100, function(points, why)
            Answer(t, my, points, why)
        end, {})
    elseif type(N.Find) == "function" then
        local pc, fx, fy, pz
        if N.PlayerPosition then ok, pc, fx, fy, pz = pcall(N.PlayerPosition) end
        if not (pc and Num(fx) and Num(fy)) then pc, fx, fy = PlayerWorld() end
        if pc ~= t.cont then t.waiting = nil; t.none = true; return end
        local side = UnitFactionGroup and UnitFactionGroup("player")
        if IsSecret(side) or (side ~= "Alliance" and side ~= "Horde") then side = nil end
        ok, job = pcall(N.Find, t.cont, { x = fx, y = fy, z = pz }, { x = target.wx, y = target.wy },
            function(points, why) Answer(t, my, points, why) end,
            { waterWalking = UnitIsGhost and UnitIsGhost("player") == true or false, profile = side, style = "balanced" })
    else
        t.waiting = nil; t.none = true; return
    end
    if not ok then t.waiting = nil; Failed(t); return end
    if t.waiting and t.token == my then
        -- still waiting (the answer may have come at once): the arrow's walk goes first
        if type(job) == "table" then job.urgent = true; t.job = job end
    end
end

-- Forgets the trail (no redraw: Apply runs inside GPS.Now, which the drawing reads).
local function Drop()
    if cur then Cancel(cur) end
    cur, external = nil, nil
    token = token + 1
end
function Trail.Clear()
    Drop()
    if Trail.Refresh then Trail.Refresh() end
end

-- The trail to this target: kept while the target stays, asked once you are more than ASK_FROM yards
-- from it. Returns the trail when the router answered, else nil (the arrow goes straight meanwhile).
local function For(target, pc, px, py)
    if not WalkOn() then if cur then Drop() end; return nil end
    target = AsWorld(target)
    if not target then return nil end
    local key = Key(target)
    if not (cur and cur.key == key) then
        if cur then Cancel(cur) end
        cur = { key = key, cont = target.cont, target = target }
    end
    local t = cur
    -- a question the router never answered (dropped by an error in its search): failed
    if t.waiting and Clock() - (t.askedAt or 0) > LOST_AFTER then
        Cancel(t); t.waiting = nil; Failed(t)
    end
    if t.pts or t.none or t.waiting or t.queued or t.loading then return t.pts and t or nil end
    if not pc then pc, px, py = PlayerWorld() end
    if pc ~= t.cont then return nil end
    local far = Yards(px, py, target.wx, target.wy)
    -- near: straight; across a continent: straight until nearer (no huge search)
    if far <= ASK_FROM or far > MAX_ASK then return nil end
    if t.failedAt and Clock() - t.failedAt < RetryWait(t) then return nil end
    Ask(t, px, py)
    return t.pts and t or nil
end
function Trail.For(target) return For(target) end

function Trail.Current() return cur and cur.pts and cur or nil end

-- How far the walk from a to b really is, for the route's plans (Route.lua prices its walking legs with
-- it): the router's FindCost (no geometry), else Find. a, b: world points ({ cont, wx, wy }) or map points.
-- fn(yards) when it answers, fn(nil, reason) when it cannot ("unreachable", "nodata"..., "combat" or
-- "nonav" when it was not the walk's fault). Returns true when asked (the answer comes later, or at once),
-- false when not asked at all: in combat, the walking paths turned off, another continent, no router.
-- Never inside the arrow's update: the router, not loaded yet, loads on the next frame.
local function AskCost(N, a, b, fn)
    if N.Available then
        local ok, yes = pcall(N.Available, a.cont)
        if ok and yes == false then return false end
    end
    local side = UnitFactionGroup and UnitFactionGroup("player")
    if IsSecret(side) or (side ~= "Alliance" and side ~= "Horde") then side = nil end
    local opts = { waterWalking = UnitIsGhost and UnitIsGhost("player") == true or false, profile = side, style = "balanced" }
    local from, to = { x = a.wx, y = a.wy }, { x = b.wx, y = b.wy }
    local ok, job
    if type(N.FindCost) == "function" then
        ok, job = pcall(N.FindCost, a.cont, from, to, function(cost, why, j)
            local yards = type(j) == "table" and Num(j.yards) or nil
            if not yards then yards = Num(cost) end
            if yards then fn(yards) else fn(nil, type(why) == "string" and why or "unreachable") end
        end, opts)
    elseif type(N.Find) == "function" then
        ok, job = pcall(N.Find, a.cont, from, to, function(points, why, j)
            if type(points) ~= "table" then fn(nil, type(why) == "string" and why or "unreachable"); return end
            local yards = Num(points.yards) or (type(j) == "table" and Num(j.yards)) or nil
            if not yards then
                yards = 0
                local last
                for _, p in ipairs(points) do
                    local x, y = Num(p.wx) or Num(p.x), Num(p.wy) or Num(p.y)
                    if x and y then
                        if last then yards = yards + Yards(last[1], last[2], x, y) end
                        last = { x, y }
                    end
                end
            end
            fn(yards)
        end, opts)
    else
        return false
    end
    return ok and true or false
end
function Trail.WalkCost(a, b, fn)
    if type(fn) ~= "function" or not WalkOn() or InCombat() then return false end
    a, b = AsWorld(a), AsWorld(b)
    if not (a and b) or a.cont ~= b.cont then return false end
    local N = rawget(_G, "WLHelperNav")
    if type(N) == "table" and (type(N.FindCost) == "function" or type(N.Find) == "function") then
        return AskCost(N, a, b, fn)
    end
    -- not loaded yet: only for a continent it has maps for, loaded on the next frame (never in combat)
    if navTried or not NAV_CONTS[a.cont] or not NavInstalled() or not (C_Timer and C_Timer.After) then return false end
    C_Timer.After(0, function()
        if InCombat() then fn(nil, "combat"); return end
        local M = Nav()
        if not (M and AskCost(M, a, b, fn)) then fn(nil, "nonav") end
    end)
    return true
end

function Trail.OnReady(fn) if type(fn) == "function" then listeners[#listeners + 1] = fn end end

-- Where the arrow points on the trail: the next corner (the target itself after the last one) and
-- what is left to walk. As Polestar does, you are placed on the segment you walk along (the nearest
-- one around the corner pointed at, a later one only when clearly nearer): the arrow points at its
-- end, or further once you are within ADVANCE yards of a corner, and the walk left is counted from
-- your place on the path. More than OFF_TRAIL yards from it: asked again (throttled, the old path
-- kept meanwhile).
local function Follow(t, px, py)
    local pts = t.pts
    local n = #pts
    local tg = t.target
    if n < 2 then return tg, Yards(px, py, tg.wx, tg.wy) end
    local at = math.max(1, math.min(n, t.at or 1))
    local from = at
    -- corners near you: the next one
    for j = at, math.min(n - 1, at + LOOKAHEAD) do
        if Yards(px, py, pts[j].wx, pts[j].wy) < ADVANCE then at = j + 1 end
    end
    -- the segment you walk along, and how far you are from the path
    local best, bestD, bestK, off = nil, math.huge, 0, math.huge
    for k = math.max(1, from - 1), math.min(n - 1, from + LOOKAHEAD) do
        local a, b = pts[k], pts[k + 1]
        local d, u = SegDist(px, py, a.wx, a.wy, b.wx, b.wy)
        if d < off then off = d end
        if not best or d + MARGIN < bestD then best, bestD, bestK = k, d, u end
    end
    if best then
        if best + 1 > at then at = best + 1 end
        -- past the end of that segment: the next corner
        if bestK >= 0.999 and best + 2 <= n and best + 2 > at then at = best + 2 end
    end
    t.at = at
    if off > OFF_TRAIL and not t.none and not t.waiting and not t.loading
        and Clock() - (t.askedAt or 0) >= REASK_EVERY
        and not (t.failedAt and Clock() - t.failedAt < RetryWait(t))
        -- a path that starts away from you (you stand off the walking maps): not again before you move
        and not (t.askX and Yards(px, py, t.askX, t.askY) < MOVED) then
        if InCombat() then
            t.queued = true        -- asked again after the fight; the old trail stays meanwhile
        else
            Ask(t, px, py)         -- the old path stays until the new one comes
        end
    end
    if at >= n then
        return tg, Yards(px, py, tg.wx, tg.wy)
    end
    -- the walk left: to your place on the path, then along it
    local a, b = pts[best], pts[best + 1]
    local qx, qy = a.wx + (b.wx - a.wx) * bestK, a.wy + (b.wy - a.wy) * bestK
    local left = bestD + Yards(qx, qy, b.wx, b.wy)
    for k = best + 1, n - 1 do left = left + Yards(pts[k].wx, pts[k].wy, pts[k + 1].wx, pts[k + 1].wy) end
    local last = pts[n]
    left = left + Yards(last.wx, last.wy, tg.wx, tg.wy)
    return pts[at], left
end
Trail._Follow = Follow

-- GoTo ("Aller à") follows its own trail for now: true while it has a trip.
local function GoToTrip(now)
    if now.source ~= "goto" then return nil end
    local G = WP.GoTo
    local trip = G and G.Trip and G.Trip()
    return trip
end

-- Called by GPS.Now (Route.lua) on each answer: on a walking leg with a trail, the arrow's target and
-- distance become the next corner and the walk left. "You're here" stays GPS.Now's own (straight
-- distance to the place).
local minimapTicker
local function StartMinimap()
    if minimapTicker or not Trail.MinimapOn() or not (C_Timer and C_Timer.NewTicker) then return end
    minimapTicker = C_Timer.NewTicker(MM_EVERY, function() Trail.RefreshMinimap() end)
end
local applying = false
local lastError = -math.huge
local function Apply(now)
    now.trail, now.straight = nil, now.dist
    external = nil
    if now.arrived or not now.cont or not now.px then return end
    local leg, goal = now.leg, nil
    if not leg then goal = now.dest
    elseif leg.kind == "ride" then goal = leg.to
    else
        -- flight, boat, zeppelin, teleport: no walking path
        if cur then Drop() end
        return
    end
    if not goal or goal.cont ~= now.cont then if cur then Drop() end; return end
    local trip = GoToTrip(now)
    if trip then
        if cur then Cancel(cur); cur = nil end
        if trip.trail then external = trip end
        StartMinimap()
        return
    end
    StartMinimap()
    local t = For(goal, now.cont, now.px, now.py)
    if not t then return end
    local corner, left = Follow(t, now.px, now.py)
    if corner then now.target, now.dist, now.trail = corner, left, t end
end
function Trail.Apply(now)
    if not now or applying then return end
    applying = true
    local ok, err = pcall(Apply, now)
    applying = false
    -- reported once a minute at most (GPS.Now runs at the arrow's rate)
    if not ok and geterrorhandler and Clock() - lastError >= 60 then
        lastError = Clock()
        geterrorhandler()(err)
    end
end

-- After the fight: the question that waited.
local ev = CreateFrame("Frame")
pcall(ev.RegisterEvent, ev, "PLAYER_REGEN_ENABLED")
pcall(ev.RegisterEvent, ev, "PLAYER_LOGIN")

-- ---------------------------------------------------------------- what is drawn

-- The line to draw now: player first, then the corners left, then the place; the continent; the
-- destination pin (the GPS's own destination, the end of the whole trip).
local gotoDest = setmetatable({}, { __mode = "k" })   -- GoTo's destination -> its world point
local function Line()
    -- a router answering at once, inside GPS.Now: drawn on the next refresh
    if applying or not (GPS.Active and GPS.Active()) then return nil end
    local ok, now = pcall(GPS.Now)
    if not (ok and now and now.cont and now.px) then return nil end
    local cont, px, py = now.cont, now.px, now.py
    local line = { { wx = px, wy = py } }
    local dest = now.dest
    if external and external.trail then
        local tr = external.trail
        for i = external.at or 1, #tr do
            local p = tr[i]
            if Num(p.wx) and Num(p.wy) then line[#line + 1] = { wx = p.wx, wy = p.wy } end
        end
        local d = external.dest
        if d and d.map then
            local wp = gotoDest[d]
            if wp == nil then wp = GPS.Point(d.map, d.x, d.y) or false; gotoDest[d] = wp end
            if wp then dest = wp end
        end
    elseif cur and cur.pts and now.trail == cur then
        for i = cur.at or 1, #cur.pts do line[#line + 1] = cur.pts[i] end
        line[#line + 1] = cur.target
    end
    if #line < 2 then line = nil end
    if dest and dest.cont ~= cont then dest = nil end
    return cont, line, dest, px, py
end

-- Dots `spacing` yards apart along the line, counted back from its end (they keep their place as you
-- walk), the end itself left to the pin, none within 4 yards of you. Each dot: { wx, wy, along = yards from you along the line }.
-- At most `cap` dots (wider apart on a long line). With (cx, cy, r): only the dots within r yards of
-- (cx, cy) are made (the minimap: no table for the rest of the path).
function Trail.Dots(line, spacing, cap, cx, cy, r)
    local out = {}
    if not line or #line < 2 then return out end
    local seg, total = {}, 0
    for i = 2, #line do
        local l = Yards(line[i - 1].wx, line[i - 1].wy, line[i].wx, line[i].wy)
        seg[i] = l; total = total + l
    end
    if total <= 0 then return out end
    if cap and total / spacing > cap then spacing = total / cap end
    -- walk back from the end
    local fromEnd = 0      -- yards from the end to line[i]
    local d = spacing      -- the next dot, in yards from the end
    for i = #line, 2, -1 do
        local l = seg[i]
        local a, b = line[i - 1], line[i]
        if r and l > 0 and SegDist(cx, cy, a.wx, a.wy, b.wx, b.wy) > r then
            -- the whole segment is out of view: skip its dots, keep the count
            while d <= fromEnd + l do d = d + spacing end
        end
        while d <= fromEnd + l and l > 0 do
            local k = (d - fromEnd) / l         -- from b back toward a
            -- none under your feet
            if total - d >= 4 then
                local wx, wy = b.wx + (a.wx - b.wx) * k, b.wy + (a.wy - b.wy) * k
                if not r or Yards(wx, wy, cx, cy) <= r then
                    out[#out + 1] = { wx = wx, wy = wy, along = total - d }
                end
            end
            d = d + spacing
        end
        fromEnd = fromEnd + l
    end
    return out
end

local function Fade(along)
    return NEAR_ALPHA + (1 - NEAR_ALPHA) * math.min(1, math.max(0, (along or FADE) / FADE))
end

local function Color()
    local c = COLORS[Trail.Color()]
    if c then return c[1], c[2], c[3] end
    local a = C.accent or { 0.808, 0.098, 0.094 }
    return a[1], a[2], a[3]
end

-- A frame's effective scale, nil when unknown (0 or a secret).
local function Eff(f)
    if type(f) ~= "table" or not f.GetEffectiveScale then return nil end
    local ok, s = pcall(f.GetEffectiveScale, f)
    s = ok and Num(s) or nil
    if s and s > 0 then return s end
end

-- Physical pixels per unit of a frame whose effective scale is `eff`, nil when unknown.
local function PxPerUnit(eff)
    if not (eff and GetPhysicalScreenSize) then return nil end
    local ok, _, h = pcall(GetPhysicalScreenSize)
    h = ok and Num(h) or nil
    if h and h > 0 then return eff * h / 768 end
end

-- A dot's width for `kind` ("map": UIParent units, "minimap": the minimap's), from the setting; raised
-- so it shows at least MIN_SHARE of the pixels it has at 1080p and UI scale 1 (eff: the frame's scale).
local function DotSize(kind, eff)
    local size = SIZES[kind][kind == "map" and Trail.MapSize() or Trail.MinimapSize()]
    local px = PxPerUnit(eff)
    if px then size = math.max(size, size * REF_PX * MIN_SHARE / px) end
    return size
end
-- The pin's head, grown with the dot when the UI scale raised it.
local function PinSize(kind, dot)
    local key = kind == "map" and Trail.MapSize() or Trail.MinimapSize()
    return PINS[kind][key] * dot / SIZES[kind][key]
end
Trail._DotSize = DotSize

-- Yards between two world map dots: GAP diameters on screen, in steps of sqrt(2) from MIN_STEP (a zoom
-- within a step keeps the dots in place). size: the dot (UI units), mapUI: the map's width on screen
-- (UI units), yards: the map's width in yards.
local LOG_STEP = math.log(math.sqrt(2))
local function MapStep(size, mapUI, yards)
    local raw = GAP * size * yards / mapUI
    if raw <= MIN_STEP then return MIN_STEP end
    return MIN_STEP * math.sqrt(2) ^ math.floor(math.log(raw / MIN_STEP) / LOG_STEP + 0.5)
end
Trail._MapStep = MapStep

-- A map's rectangle in world yards (constant, kept): world -> map 0..1 is affine on every zone map.
local rects = {}
local function Rect(map)
    local r = rects[map]
    if r == nil then
        -- a zone or continent map only (the world and cosmic maps span several continents)
        local info = C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(map)
        local kind = info and Num(info.mapType)
        local floor = Enum and Enum.UIMapType and Num(Enum.UIMapType.Continent) or 2
        if kind and kind < floor then rects[map] = false; return nil end
        local a, b = GPS.Point(map, 0, 0), GPS.Point(map, 100, 100)
        r = (a and b and a.cont == b.cont and a.wx ~= b.wx and a.wy ~= b.wy) and { cont = a.cont, a = a, b = b } or false
        rects[map] = r
    end
    return r or nil
end
local function ToMap(r, wx, wy)
    return (wy - r.a.wy) / (r.b.wy - r.a.wy), (wx - r.a.wx) / (r.b.wx - r.a.wx)
end

-- The world map's dots for map `map`: { { x, y (0..1), alpha }, ... }, the pin { x, y } or nil, and the
-- spacing in yards. view (optional): { size = the dot (UI units), mapUI = the map's width on screen (UI
-- units), clip = { x0, y0, x1, y1 } the part of the map in view (0..1) }; without it, a medium dot on
-- a MAP_UI-wide map, all of it in view. Zoomed in, only the dots in view (and a margin) are made.
function Trail.MapDots(map, view)
    local dots, pin = {}, nil
    if not (map and Trail.MapOn()) then return dots, pin end
    local cont, line, dest = Line()
    local r = cont and Rect(map)
    if not (r and r.cont == cont) then return dots, pin end
    local spacing
    if line then
        view = view or {}
        local width = math.abs(r.b.wy - r.a.wy)
        spacing = MapStep(view.size or SIZES.map.medium, view.mapUI or MAP_UI, width)
        local c = view.clip
        local x0, y0, x1, y1 = 0, 0, 1, 1
        local list
        if c and (c[3] - c[1] < 0.95 or c[4] - c[2] < 0.95) then
            -- zoomed in: the view and a fifth of it again round it, the dots made only in a circle round that
            local mx, my = (c[3] - c[1]) * 0.2, (c[4] - c[2]) * 0.2
            x0, y0, x1, y1 = c[1] - mx, c[2] - my, c[3] + mx, c[4] + my
            local wyA, wyB = r.a.wy + x0 * (r.b.wy - r.a.wy), r.a.wy + x1 * (r.b.wy - r.a.wy)
            local wxA, wxB = r.a.wx + y0 * (r.b.wx - r.a.wx), r.a.wx + y1 * (r.b.wx - r.a.wx)
            list = Trail.Dots(line, spacing, nil, (wxA + wxB) / 2, (wyA + wyB) / 2, Yards(wxA, wyA, wxB, wyB) / 2)
            x0, y0, x1, y1 = math.max(0, x0), math.max(0, y0), math.min(1, x1), math.min(1, y1)
        else
            list = Trail.Dots(line, spacing, MAP_CAP)
        end
        for _, d in ipairs(list) do
            local x, y = ToMap(r, d.wx, d.wy)
            if x >= x0 and x <= x1 and y >= y0 and y <= y1 then
                dots[#dots + 1] = { x = x, y = y, alpha = Fade(d.along) }
                if #dots >= MAP_CAP then break end
            end
        end
    end
    if dest then
        local x, y = ToMap(r, dest.wx, dest.wy)
        if x >= 0 and x <= 1 and y >= 0 and y <= 1 then pin = { x = x, y = y } end
    end
    return dots, pin, spacing
end

-- What the minimap shows: radius in yards, its half width in pixels, facing (rotating) or nil, square.
local function MinimapView()
    local radius
    if C_Minimap and C_Minimap.GetViewRadius then
        local ok, v = pcall(C_Minimap.GetViewRadius)
        if ok and Num(v) and v > 0 then radius = v end
    end
    if not radius then
        local zoom = Minimap and Minimap.GetZoom and Minimap:GetZoom() or 0
        local indoors = IsIndoors and IsIndoors()
        radius = ((indoors and INDOOR or OUTDOOR)[zoom] or OUTDOOR[0]) / 2
    end
    local half = Minimap and Minimap.GetWidth and Num(Minimap:GetWidth()) or 140
    half = half / 2
    local facing, blind
    if GetCVar and GetCVar("rotateMinimap") == "1" then
        local ignored = C_Minimap and C_Minimap.IsRotateMinimapIgnored and C_Minimap.IsRotateMinimapIgnored()
        if not ignored then
            facing = GetPlayerFacing and Num(GetPlayerFacing())
            -- the minimap turns but your facing is unknown (secret, nil): dots would be misplaced
            if not facing then blind = true end
        end
    end
    local square = GetMinimapShape and GetMinimapShape() == "SQUARE"
    return radius, half, facing, square, blind
end
Trail._MinimapView = MinimapView

-- Pixels from the minimap's centre for a world point, given you at (px, py).
local function Project(wx, wy, px, py, radius, half, facing)
    local k = half / radius
    local x, y = -(wy - py) * k, (wx - px) * k        -- east, north
    if facing then
        local c, s = math.cos(facing), math.sin(facing)
        x, y = x * c + y * s, -x * s + y * c
    end
    return x, y
end
Trail._Project = Project

local function Inside(x, y, lim, square)
    if square then return math.abs(x) <= lim and math.abs(y) <= lim end
    return x * x + y * y <= lim * lim
end

-- The minimap's dots: { { x, y (pixels from its centre), alpha }, ... }, the pin { x, y } or nil, the
-- dot's width (minimap units) and the spacing in yards (GAP diameters at this zoom).
local mmLive = false     -- the last MinimapDots had a GPS answer (else its timer stops)
function Trail.MinimapDots()
    local dots, pin = {}, nil
    mmLive = false
    if not Trail.MinimapOn() then return dots, pin end
    local cont, line, dest, px, py = Line()
    if not cont then return dots, pin end
    mmLive = true
    local radius, half, facing, square, blind = MinimapView()
    if blind then return dots, pin end
    local size = DotSize("minimap", Eff(rawget(_G, "Minimap")))
    local spacing = math.max(MM_MIN_STEP, GAP * size * radius / half)
    if line then
        local lim = half - size / 2 - RING.minimap - 1
        for _, d in ipairs(Trail.Dots(line, spacing, nil, px, py, radius * 1.5)) do
            local x, y = Project(d.wx, d.wy, px, py, radius, half, facing)
            if Inside(x, y, lim, square) then
                dots[#dots + 1] = { x = x, y = y, alpha = Fade(d.along) }
                if #dots >= MM_CAP then break end
            end
        end
    end
    if dest then
        local x, y = Project(dest.wx, dest.wy, px, py, radius, half, facing)
        if Inside(x, y, half - PinSize("minimap", size) / 2, square) then pin = { x = x, y = y } end
    end
    return dots, pin, size, spacing
end

-- ---------------------------------------------------------------- textures

local drawn = { map = 0, mapPin = false, minimap = 0, minimapPin = false }
function Trail._Drawn() return drawn end

-- n dots on `host`: a disc `size` wide over a black ring `ring` wider on each side (both from dot.tga,
-- in the host's units); textures made once and kept, restyled only when the size or colour changes.
local function Pool(host, list, n, size, ring, r, g, b)
    local tex, back = size / DOT_FILL, (size + 2 * ring) / DOT_FILL
    for i = 1, n do
        local t = list[i]
        if not t then
            t = host:CreateTexture(nil, "OVERLAY", nil, 2)
            t:SetTexture(MEDIA .. "dot")
            local k = host:CreateTexture(nil, "OVERLAY", nil, 1)
            k:SetTexture(MEDIA .. "dot")
            k:SetVertexColor(0, 0, 0)
            k:SetPoint("CENTER", t, "CENTER", 0, 0)
            t.wlRing = k
            list[i] = t
        end
        if t.wlTex ~= tex or t.wlBack ~= back then
            t:SetSize(tex, tex); t.wlRing:SetSize(back, back)
            t.wlTex, t.wlBack = tex, back
        end
        if t.wlR ~= r or t.wlG ~= g or t.wlB ~= b then
            t:SetVertexColor(r, g, b)
            t.wlR, t.wlG, t.wlB = r, g, b
        end
    end
    for i = n + 1, #list do list[i]:Hide(); list[i].wlRing:Hide() end
end
local function PlaceDot(t, rel, point, x, y, alpha)
    t:ClearAllPoints()
    t:SetPoint("CENTER", rel, point, x, y)
    t:SetAlpha(alpha)
    t.wlRing:SetAlpha(alpha * RING_ALPHA)
    t:Show(); t.wlRing:Show()
end

-- The destination pin and its black shadow (a bigger pin behind it).
local function MakePin(host)
    local p = host:CreateTexture(nil, "OVERLAY", nil, 7)
    p:SetTexture(MEDIA .. "pin")
    local k = host:CreateTexture(nil, "OVERLAY", nil, 6)
    k:SetTexture(MEDIA .. "pin")
    k:SetVertexColor(0, 0, 0)
    k:SetPoint("CENTER", p, "CENTER", 0, 0)
    p.wlRing = k
    return p
end
-- The pin's tip on (x, y) from rel's `point`; head: its head's width, ring: the shadow's (host units).
local function ShowPin(p, rel, point, x, y, head, ring, r, g, b)
    local s, k = head / PIN_FILL, (head + 2 * ring) / PIN_FILL
    p:SetSize(s, s); p.wlRing:SetSize(k, k)
    p:SetVertexColor(r, g, b)
    p:ClearAllPoints()
    -- pin.tga's tip is PIN_TIP of its height above its bottom edge: the texture goes down that much
    p:SetPoint("BOTTOM", rel, point, x, y - s * PIN_TIP)
    p.wlRing:SetAlpha(RING_ALPHA)
    p:Show(); p.wlRing:Show()
end
local function HidePin(p) if p then p:Hide(); p.wlRing:Hide() end end

-- World map: one frame over the map canvas, textures placed in canvas units. A dot's canvas size is its
-- UI size times UIParent's effective scale over the canvas's: the same on screen at every zoom.
local wm = { dots = {} }
local function Canvas()
    local W = rawget(_G, "WorldMapFrame")
    if not W then return nil end
    local c = W.GetCanvas and W:GetCanvas()
    local sc = rawget(W, "ScrollContainer") or W.ScrollContainer
    if type(c) ~= "table" and type(sc) == "table" then c = sc.Child end
    if type(c) ~= "table" then c = nil end
    return W, c
end

-- UI units per canvas unit: the effective scales, else the scroll container's canvas scale.
local function CanvasK(W, canvas)
    local ce, ue = Eff(canvas), Eff(rawget(_G, "UIParent"))
    if ce and ue then return ce / ue end
    local sc = W and W.ScrollContainer
    if type(sc) == "table" and sc.GetCanvasScale then
        local ok, s = pcall(sc.GetCanvasScale, sc)
        if ok and Num(s) and s > 0 then return s end
    end
    return 1
end

-- The part of the canvas its scroll frame shows, 0..1 of the map: { x0, y0, x1, y1 }, or nil (unknown).
local function ViewClip(canvas, w, h)
    local frame = canvas.GetParent and canvas:GetParent()
    if type(frame) ~= "table" or not frame.GetLeft or w <= 0 or h <= 0 then return nil end
    local cs, fs = Eff(canvas), Eff(frame)
    local cl, ct = Num(canvas:GetLeft()), Num(canvas:GetTop())
    local fl, ft, fr, fb = Num(frame:GetLeft()), Num(frame:GetTop()), Num(frame:GetRight()), Num(frame:GetBottom())
    if not (cs and fs and cl and ct and fl and ft and fr and fb) or fr <= fl or ft <= fb then return nil end
    local kx, ky = 1 / (w * cs), 1 / (h * cs)
    return { (fl * fs - cl * cs) * kx, (ct * cs - ft * fs) * ky, (fr * fs - cl * cs) * kx, (ct * cs - fb * fs) * ky }
end

function Trail.RefreshMap()
    local W, canvas = Canvas()
    local shown = W and W.IsShown and W:IsShown()
    local map = shown and W.GetMapID and W:GetMapID()
    local dots, pin = {}, nil
    local w, h = Num(canvas and canvas:GetWidth()) or 0, Num(canvas and canvas:GetHeight()) or 0
    local k = canvas and CanvasK(W, canvas) or 1
    local size = DotSize("map", Eff(rawget(_G, "UIParent")))
    if map and canvas then
        local okC, clip = pcall(ViewClip, canvas, w, h)
        dots, pin = Trail.MapDots(map, { size = size, mapUI = w > 0 and w * k or nil, clip = okC and clip or nil })
    end
    if not wm.frame then
        if not canvas or (#dots == 0 and not pin) then drawn.map, drawn.mapPin = 0, false; return end
        wm.frame = CreateFrame("Frame", nil, canvas)
        wm.frame:SetAllPoints(canvas)
        wm.frame:SetFrameLevel((canvas.GetFrameLevel and canvas:GetFrameLevel() or 1) + 2000)
        wm.pin = MakePin(wm.frame)
    end
    local f = wm.frame
    local r, g, b = Color()
    local dot, ring = size / k, RING.map / k             -- canvas units
    Pool(f, wm.dots, #dots, dot, ring, r, g, b)
    for i, d in ipairs(dots) do PlaceDot(wm.dots[i], f, "TOPLEFT", d.x * w, -d.y * h, d.alpha) end
    -- kept for the tests: the dot's width in canvas units and on screen (UI units)
    drawn.mapDot, drawn.mapDotUI = dot, size
    if pin then
        ShowPin(wm.pin, f, "TOPLEFT", pin.x * w, -pin.y * h, PinSize("map", size) / k, ring, r, g, b)
    else
        HidePin(wm.pin)
    end
    drawn.map, drawn.mapPin = #dots, pin ~= nil
end

-- The world map tells us when its map, zoom or data change (a data provider, as the game's own pins);
-- while it is open the dots follow you twice a second.
local mapTicker
local function MapShown()
    if mapTicker or not (C_Timer and C_Timer.NewTicker) then return end
    mapTicker = C_Timer.NewTicker(MAP_EVERY, function()
        local W = rawget(_G, "WorldMapFrame")
        if not (W and W:IsShown()) then if mapTicker then mapTicker:Cancel(); mapTicker = nil end end
        pcall(Trail.RefreshMap)
    end)
    pcall(Trail.RefreshMap)
end
local function MapHidden()
    if mapTicker then mapTicker:Cancel(); mapTicker = nil end
end
local hooked = false
local function HookMap()
    if hooked then return end
    local W = rawget(_G, "WorldMapFrame")
    if not W then return end
    hooked = true
    if type(rawget(_G, "MapCanvasDataProviderMixin")) == "table" and CreateFromMixins and W.AddDataProvider then
        local p = CreateFromMixins(MapCanvasDataProviderMixin)
        function p:RefreshAllData() pcall(Trail.RefreshMap) end
        function p:RemoveAllData() end
        function p:OnMapChanged() pcall(Trail.RefreshMap) end
        function p:OnCanvasScaleChanged() pcall(Trail.RefreshMap) end
        -- zoomed in, only the dots in view are made: a pan brings the rest, once per 0.15 s at most
        local panWait = false
        function p:OnCanvasPanChanged()
            if panWait or not (C_Timer and C_Timer.After) then return end
            panWait = true
            C_Timer.After(0.15, function() panWait = false; pcall(Trail.RefreshMap) end)
        end
        pcall(W.AddDataProvider, W, p)
    end
    if W.HookScript then
        W:HookScript("OnShow", MapShown)
        W:HookScript("OnHide", MapHidden)
    end
    if W:IsShown() then MapShown() end
end
Trail._HookMap = HookMap

-- Minimap: one frame over it, textures from its centre in its own units.
local mm = { dots = {} }
function Trail.RefreshMinimap()
    local dots, pin, size = Trail.MinimapDots()
    -- nothing to follow (GPS stopped, Zygor guiding, the switch off): the timer stops; Apply starts it again
    if minimapTicker and (not mmLive or not (GPS.Active and GPS.Active())) then
        minimapTicker:Cancel(); minimapTicker = nil
    end
    local M = rawget(_G, "Minimap")
    if not M then drawn.minimap, drawn.minimapPin = 0, false; return end
    if not mm.frame then
        if #dots == 0 and not pin then drawn.minimap, drawn.minimapPin = 0, false; return end
        mm.frame = CreateFrame("Frame", nil, M)
        mm.frame:SetAllPoints(M)
        mm.frame:SetFrameLevel((M.GetFrameLevel and M:GetFrameLevel() or 1) + 5)
        mm.pin = MakePin(mm.frame)
    end
    size = size or DotSize("minimap", Eff(M))
    local r, g, b = Color()
    Pool(mm.frame, mm.dots, #dots, size, RING.minimap, r, g, b)
    for i, d in ipairs(dots) do PlaceDot(mm.dots[i], M, "CENTER", d.x, d.y, d.alpha) end
    drawn.minimapDot = size
    if pin then
        ShowPin(mm.pin, M, "CENTER", pin.x, pin.y, PinSize("minimap", size), RING.minimap, r, g, b)
    else
        HidePin(mm.pin)
    end
    drawn.minimap, drawn.minimapPin = #dots, pin ~= nil
end

function Trail.Refresh()
    HookMap()
    pcall(Trail.RefreshMap)
    pcall(Trail.RefreshMinimap)
end

ev:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        HookMap()
    elseif event == "PLAYER_REGEN_ENABLED" and cur and cur.queued then
        cur.queued = nil
        Ask(cur)                         -- asked again from where the fight left you; the old path stays meanwhile
    end
end)
