-- Writs/Patrol.lua: the route of an NPC that walks (WP.Patrol). Some quest givers do not stand still:
-- the Centaur Pariah (quest 7067, southern Desolace) walks up and down a path. A single waypoint is
-- then not enough: while the dungeon guide's GPS points at such an NPC (the step's line to accept on
-- his start, or to turn in on his end), his whole path is drawn as a dotted line between his spots,
-- in their order, on the world map (with "Centaur Pariah's route" at its middle) and on the minimap
-- (round or square, rotating or not, as Trail.lua does). The dots are smaller than the walking path's
-- and of another colour (amber; violet when the walking path is yellow), so the two never mix.
-- Nothing is drawn once the GPS stops, guides elsewhere, or the line is done; the walking path's
-- switches (WLWritsDB.trail.map / .minimap) and dot sizes count here too.
-- The world map is drawn again only when it opens, changes map or zooms (and when the path changes);
-- the minimap 10 times a second, only while a route is shown.
--
-- Spots: q.s.sp / q.f.sp = { { x, y }, ... } (percent, on q.s.m / q.f.m) in the guide's data, else the
-- small table KNOWN below.
-- API: Patrol.Spots(qid, which) -> spots, map, name | nil (which: "s" = start, "f" = end, default "s");
-- Patrol.Active() -> nil | { q, which, map, spots, name }; Patrol.CardText(qid, which) -> the guide
-- card's line ("Il se déplace le long d'un chemin") | nil; Patrol.Update() (looks again, redraws when it
-- changed); Patrol.Refresh() (redraws); Patrol.MapDots(map, view), Patrol.MinimapDots() (for the tests).
local ADDON, root = ...
root.Writs = root.Writs or {}
local ns = root.Writs
local WP = ns.WP
local GPS = WP.GPS

local Patrol = {}
WP.Patrol = Patrol

local function L(s) return ns.L and ns.L(s) or s end

ns.AddEnglish({
    ["Trajet du %s"] = "%s's route",
    ["Trajet de %s"] = "%s's route",
    ["Il se déplace le long d'un chemin"] = "He walks along a path",
})

-- NPCs that walk, when the data has no spots for them: quest -> { s = spots, f = spots, m = map, n = name }
local DESOLACE_PARIAH = { { 50.42, 86.65 }, { 47.53, 87.15 }, { 45.27, 86.33 } }
local KNOWN = {
    [7067] = { m = 1443, n = "Centaur Pariah", s = DESOLACE_PARIAH, f = DESOLACE_PARIAH },
}
Patrol.KNOWN = KNOWN

local MEDIA = "Interface\\AddOns\\WLHelper\\Media\\Icons\\"
local DOT_FILL = 48 / 128      -- dot.tga's disc spans 48 of its 128 px (Trail.lua)
local SHARE = 0.75             -- a patrol dot: this share of the walking path's dot
local GAP = 2                  -- dots this many diameters apart on screen
local RING = { map = 1.25, minimap = 0.9 }
local RING_ALPHA = 0.85
local ALPHA = 0.95
local MAP_CAP, MM_CAP = 300, 80
local LABEL_SIZE = 11
local LABEL_LIFT = 10          -- UI units above the path's middle
local NEAR_DEST = 20           -- yards: the GPS point counts as this NPC's when this near his path
local MM_EVERY = 0.1
local CHECK_EVERY = 10         -- minimap ticks between two looks at the guide's step (1 s)
local AMBER, VIOLET = { 1, 0.62, 0.12 }, { 0.78, 0.45, 1 }
local SIZES = { map = { small = 6, medium = 8, large = 11 }, minimap = { small = 4, medium = 5, large = 7 } }

local function IsSecret(v) return issecretvalue ~= nil and issecretvalue(v) end
local function Num(v) if type(v) == "number" and not IsSecret(v) then return v end end
local function Trail() return WP.Trail end

-- ---------------------------------------------------------------- the spots

-- { x, y [, map] } or { x = , y = [, m = ] } -> x, y, map (nil: the point's own map)
local function XY(p)
    if type(p) ~= "table" then return nil end
    local x, y = Num(p[1] or p.x), Num(p[2] or p.y)
    if x and y then return x, y, Num(p[3] or p.m) end
end

-- A spot may carry a third value, another map (a path across a zone border, as Data.lua's Rexxar).
local function Clean(list)
    if type(list) ~= "table" then return nil end
    local out = {}
    for _, p in ipairs(list) do
        local x, y, m = XY(p)
        if x then out[#out + 1] = { x, y, m } end
    end
    if #out >= 2 then return out end
end

local cleaned = setmetatable({}, { __mode = "k" })   -- data's sp table -> its clean copy
function Patrol.Spots(qid, which)
    which = (which == "f") and "f" or "s"
    local Q = root.Q
    local q = Q and qid and Q[qid]
    local loc = type(q) == "table" and q[which] or nil
    if type(loc) == "table" and type(loc.sp) == "table" and loc.m then
        local c = cleaned[loc.sp]
        if c == nil then c = Clean(loc.sp) or false; cleaned[loc.sp] = c end
        if c then return c, loc.m, loc.n end
    end
    local k = qid and KNOWN[qid]
    local list = k and k[which]
    if list and #list >= 2 then
        -- the built-in spots are on the built-in map, whatever map the data's marker uses
        return list, k.m, (type(loc) == "table" and loc.n) or k.n
    end
    return nil
end

function Patrol.CardText(qid, which)
    if Patrol.Spots(qid, which) then return L("Il se déplace le long d'un chemin") end
    return nil
end

-- French: "du" before a title ("Trajet du Centaur Pariah"), "de" before a name ("Trajet de Rexxar").
local WITH_DU = { ["Centaur Pariah"] = true }
local function LabelText(name)
    name = name or "?"
    return string.format(L(WITH_DU[name] and "Trajet du %s" or "Trajet de %s"), name)
end
Patrol._LabelText = LabelText

-- ---------------------------------------------------------------- what the guide follows

local ACTS = { a = "s", h = "s", t = "f" }

local World    -- spots -> world points (below)

-- Distance in yards from the world point (x, y) to the path (world points).
local function PathDist(pts, x, y)
    local best = math.huge
    for i = 1, #pts - 1 do
        local ax, ay, bx, by = pts[i].wx, pts[i].wy, pts[i + 1].wx, pts[i + 1].wy
        local dx, dy = bx - ax, by - ay
        local l2 = dx * dx + dy * dy
        local k = 0
        if l2 > 0 then k = math.max(0, math.min(1, ((x - ax) * dx + (y - ay) * dy) / l2)) end
        local ex, ey = ax + k * dx - x, ay + k * dy - y
        local d = math.sqrt(ex * ex + ey * ey)
        if d < best then best = d end
    end
    return best
end

-- The GPS guides to this line's NPC: its point is the line's place, or on his path (the GPS walks
-- from spot to spot, Route.lua; in world yards, so a path across a zone border counts too).
local function DestOn(dest, n, spots, map)
    local dx, dy = Num(dest.x), Num(dest.y)
    if not dx then return false end
    local loc = n.loc
    if type(loc) == "table" and dest.map == loc.m and Num(loc.x) and Num(loc.y)
        and math.abs(dx - loc.x) < 0.15 and math.abs(dy - loc.y) < 0.15 then return true end
    local wx, wy = Num(dest.wx), Num(dest.wy)
    local pts = wx and wy and World(spots, map)
    return pts and dest.cont == pts[1].cont and PathDist(pts, wx, wy) <= NEAR_DEST or false
end

local function Compute()
    if not (GPS and GPS.Active and GPS.Active()) then return nil end
    if GPS.Source and GPS.Source() ~= "dungeon" then return nil end
    local dest = GPS.Dest and GPS.Dest()
    if type(dest) ~= "table" or not dest.map then return nil end
    local steps = root.route and root.route.steps
    local f = root.frame
    if type(steps) ~= "table" or type(f) ~= "table" then return nil end
    local log
    local seen = {}
    for _, i in ipairs({ f.view or false, f.auto or false }) do
        local st = i and steps[i]
        if st and not seen[st] and type(st.acts) == "table" then
            seen[st] = true
            for _, n in ipairs(st.acts) do
                local which = ACTS[n.kind]
                if which and n.q then
                    local spots, map, name = Patrol.Spots(n.q, which)
                    if spots and DestOn(dest, n, spots, map) then
                        if log == nil then
                            local ok, l = pcall(function() return root.LogEntries and root.LogEntries() end)
                            log = ok and l or false
                        end
                        local okD, done = pcall(function() return root.NodeOK and log and root.NodeOK(log, n) end)
                        if not (okD and done) then
                            return { q = n.q, which = which, map = map, spots = spots, name = name or n.npc }
                        end
                    end
                end
            end
        end
    end
    return nil
end

local active, activeKey
function Patrol.Active() return active end

-- ---------------------------------------------------------------- geometry

local function Opts()
    local db = WLWritsDB
    return db and type(db.trail) == "table" and db.trail or {}
end
local function MapOn() local T = Trail(); if T and T.MapOn then return T.MapOn() end return Opts().map ~= false end
local function MinimapOn() local T = Trail(); if T and T.MinimapOn then return T.MinimapOn() end return Opts().minimap ~= false end

local function Color()
    local T = Trail()
    local c = T and T.Color and T.Color() or Opts().color
    local p = (c == "yellow") and VIOLET or AMBER
    return p[1], p[2], p[3]
end
Patrol._Color = Color

local function Eff(f)
    if type(f) ~= "table" or not f.GetEffectiveScale then return nil end
    local ok, s = pcall(f.GetEffectiveScale, f)
    s = ok and Num(s) or nil
    if s and s > 0 then return s end
end

-- The patrol dot's width, from the walking path's dot (its size setting and UI scale floor).
local function DotSize(kind, eff)
    local T = Trail()
    local size
    if T and T._DotSize then
        local ok, v = pcall(T._DotSize, kind, eff)
        size = ok and Num(v) or nil
    end
    if not size then
        local key = Opts()[kind == "map" and "mapSize" or "minimapSize"]
        size = SIZES[kind][key] or SIZES[kind].medium
    end
    return size * SHARE
end
Patrol._DotSize = DotSize

-- The spots as world points (kept per spots table): a spot's own map (third value) else `map`. A path
-- whose spots lie on two continents is no path.
local worldOf = setmetatable({}, { __mode = "k" })
function World(spots, map)
    local w = worldOf[spots]
    if w and w.map == map then return w.pts or nil end
    local pts = {}
    for _, p in ipairs(spots) do
        local wp = GPS.Point and GPS.Point(p[3] or map, p[1], p[2])
        if not wp then return nil end                  -- the map not readable yet: asked again later
        if pts[1] and wp.cont ~= pts[1].cont then pts = false; break end
        pts[#pts + 1] = { cont = wp.cont, wx = wp.wx, wy = wp.wy }
    end
    worldOf[spots] = { map = map, pts = pts }
    return pts or nil
end

-- A map's rectangle in world yards (as Trail.lua): zone and continent maps only.
local rects = {}
local function Rect(map)
    local r = rects[map]
    if r == nil then
        local info = C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(map)
        local kind = info and Num(info.mapType)
        local floor = Enum and Enum.UIMapType and Num(Enum.UIMapType.Continent) or 2
        if kind and kind < floor then rects[map] = false; return nil end
        local a, b = GPS.Point(map, 0, 0), GPS.Point(map, 100, 100)
        -- a failed lookup is not kept: asked again on the next draw
        if not (a and b and a.cont == b.cont and a.wx ~= b.wx and a.wy ~= b.wy) then return nil end
        r = { cont = a.cont, a = a, b = b }
        rects[map] = r
    end
    return r or nil
end
local function ToMap(r, wx, wy)
    return (wy - r.a.wy) / (r.b.wy - r.a.wy), (wx - r.a.wx) / (r.b.wx - r.a.wx)
end

-- Points every `step` along the line { { x, y }, ... } (any unit), both ends included; at most cap.
local function Densify(line, step, cap)
    local out = {}
    if #line < 2 then return out end
    local total = 0
    for i = 2, #line do
        local dx, dy = line[i][1] - line[i - 1][1], line[i][2] - line[i - 1][2]
        total = total + math.sqrt(dx * dx + dy * dy)
    end
    if total <= 0 then return out end
    if not step or step <= 0 then step = total end
    if cap and total / step > cap - 1 then step = total / (cap - 1) end
    -- evenly spread: a whole number of steps from end to end
    local n = math.max(1, math.floor(total / step + 0.5))
    step = total / n
    local i, from, segL = 2, 0, nil
    for k = 0, n do
        local d = k * step
        while i <= #line do
            local dx, dy = line[i][1] - line[i - 1][1], line[i][2] - line[i - 1][2]
            segL = math.sqrt(dx * dx + dy * dy)
            if d <= from + segL + 1e-9 or i == #line then break end
            from = from + segL; i = i + 1
        end
        local a, b = line[i - 1], line[i]
        local t = segL > 0 and math.min(1, math.max(0, (d - from) / segL)) or 0
        out[#out + 1] = { a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t }
    end
    return out
end
Patrol._Densify = Densify

-- The point halfway along the line.
local function Middle(line)
    local total, seg = 0, {}
    for i = 2, #line do
        local dx, dy = line[i][1] - line[i - 1][1], line[i][2] - line[i - 1][2]
        seg[i] = math.sqrt(dx * dx + dy * dy); total = total + seg[i]
    end
    local half, acc = total / 2, 0
    for i = 2, #line do
        if acc + seg[i] >= half and seg[i] > 0 then
            local t = (half - acc) / seg[i]
            return line[i - 1][1] + (line[i][1] - line[i - 1][1]) * t, line[i - 1][2] + (line[i][2] - line[i - 1][2]) * t
        end
        acc = acc + seg[i]
    end
    return line[1][1], line[1][2]
end

-- How the route's points land on map `map`'s canvas: Trail.lua's projection (its OpenMap stitching
-- too: the canvas then shows past 0..1, the second value true), else the map's own rectangle.
local function Projection(map, cont)
    local T = Trail()
    if T and T._Projection then return T._Projection(map, cont) end
    local r = Rect(map)
    if not (r and r.cont == cont) then return nil end
    return function(c, wx, wy) if c == r.cont then return ToMap(r, wx, wy) end end, false
end

-- The world map's dots for map `map`: { { x, y (canvas 0..1) }, ... } and the label's place { x, y }.
-- view (optional): { w, h = the canvas's size (canvas units), k = UI units per canvas unit, size = the
-- dot (UI units) }; without it a 1000 x 1000 map, k = 1. With OpenMap stitching, past 0..1 too.
function Patrol.MapDots(map, view)
    local dots = {}
    local a = active
    if not (a and map and MapOn()) then return dots, nil end
    local pts = World(a.spots, a.map)
    if not (pts and pts[1]) then return dots, nil end
    local cont = pts[1].cont
    local proj, stitched = Projection(map, cont)
    if not proj then return dots, nil end
    local lo, hi = 0, 1
    if stitched then lo, hi = -1, 2 end
    view = view or {}
    local w, h, k = view.w or 1000, view.h or 1000, view.k or 1
    local size = view.size or DotSize("map", nil)
    -- the line in canvas units, the dots GAP diameters apart on screen
    local line = {}
    for _, p in ipairs(pts) do
        local x, y = proj(p.cont, p.wx, p.wy)
        if not x then return dots, nil end
        line[#line + 1] = { x * w, y * h }
    end
    for _, p in ipairs(Densify(line, GAP * size / k, MAP_CAP)) do
        local x, y = p[1] / w, p[2] / h
        if x >= lo and x <= hi and y >= lo and y <= hi then dots[#dots + 1] = { x = x, y = y } end
    end
    local mx, my = Middle(line)
    local label = { x = mx / w, y = my / h }
    if label.x < lo or label.x > hi or label.y < lo or label.y > hi then label = nil end
    return dots, label
end

-- ---------------------------------------------------------------- minimap

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

local function MinimapView()
    local T = Trail()
    if T and T._MinimapView then return T._MinimapView() end
    local radius = 200 / 2 * 1.5
    if C_Minimap and C_Minimap.GetViewRadius then
        local ok, v = pcall(C_Minimap.GetViewRadius)
        if ok and Num(v) and v > 0 then radius = v end
    end
    local half = (Minimap and Minimap.GetWidth and Num(Minimap:GetWidth()) or 140) / 2
    local facing, blind
    if GetCVar and GetCVar("rotateMinimap") == "1" then
        facing = GetPlayerFacing and Num(GetPlayerFacing())
        if not facing then blind = true end
    end
    return radius, half, facing, GetMinimapShape and GetMinimapShape() == "SQUARE", blind
end

local function Project(wx, wy, px, py, radius, half, facing)
    local T = Trail()
    if T and T._Project then return T._Project(wx, wy, px, py, radius, half, facing) end
    local k = half / radius
    local x, y = -(wy - py) * k, (wx - px) * k
    if facing then
        local c, s = math.cos(facing), math.sin(facing)
        x, y = x * c + y * s, -x * s + y * c
    end
    return x, y
end

local function Inside(x, y, lim, square)
    if square then return math.abs(x) <= lim and math.abs(y) <= lim end
    return x * x + y * y <= lim * lim
end

-- The minimap's dots: { { x, y (pixels from its centre) }, ... } and the dot's width (minimap units).
function Patrol.MinimapDots()
    local dots = {}
    local a = active
    if not (a and MinimapOn()) then return dots end
    local pts = World(a.spots, a.map)
    if not pts then return dots end
    local cont, px, py = PlayerWorld()
    if not cont or cont ~= pts[1].cont then return dots end
    local radius, half, facing, square, blind = MinimapView()
    if blind or not (radius and half) then return dots end
    local size = DotSize("minimap", Eff(rawget(_G, "Minimap")))
    local spacing = math.max(2, GAP * size * radius / half)       -- yards
    local line = {}
    for _, p in ipairs(pts) do line[#line + 1] = { p.wx, p.wy } end
    -- the path far off the minimap: nothing to make
    local near = false
    for i = 1, #line - 1 do
        local ax, ay, bx, by = line[i][1], line[i][2], line[i + 1][1], line[i + 1][2]
        local dx, dy = bx - ax, by - ay
        local l2 = dx * dx + dy * dy
        local t = l2 > 0 and math.max(0, math.min(1, ((px - ax) * dx + (py - ay) * dy) / l2)) or 0
        local ex, ey = ax + t * dx - px, ay + t * dy - py
        if ex * ex + ey * ey <= (radius * 1.5) ^ 2 then near = true; break end
    end
    if not near then return dots, size end
    local lim = half - size / 2 - RING.minimap - 1
    for _, p in ipairs(Densify(line, spacing, 2000)) do
        local x, y = Project(p[1], p[2], px, py, radius, half, facing)
        if Inside(x, y, lim, square) then
            dots[#dots + 1] = { x = x, y = y }
            if #dots >= MM_CAP then break end
        end
    end
    return dots, size
end

-- ---------------------------------------------------------------- textures

local drawn = { map = 0, minimap = 0, label = nil }
function Patrol._Drawn() return drawn end

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
local function Place(t, rel, point, x, y)
    t:ClearAllPoints()
    t:SetPoint("CENTER", rel, point, x, y)
    t:SetAlpha(ALPHA)
    t.wlRing:SetAlpha(ALPHA * RING_ALPHA)
    t:Show(); t.wlRing:Show()
end

local function Canvas()
    local W = rawget(_G, "WorldMapFrame")
    if not W then return nil end
    local c = W.GetCanvas and W:GetCanvas()
    local sc = rawget(W, "ScrollContainer") or W.ScrollContainer
    if type(c) ~= "table" and type(sc) == "table" then c = sc.Child end
    if type(c) ~= "table" then c = nil end
    return W, c
end
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

local wm = { dots = {} }
local function MakeLabel(host)
    local fs = host:CreateFontString(nil, "OVERLAY")
    -- a font from the start: SetText on a font string without one is an error
    local fo = rawget(_G, "GameFontNormalSmall")
    if fo and fs.SetFontObject then pcall(fs.SetFontObject, fs, fo) end
    if fs.SetShadowOffset then fs:SetShadowOffset(1, -1) end
    if fs.SetShadowColor then fs:SetShadowColor(0, 0, 0, 1) end
    if fs.SetJustifyH then fs:SetJustifyH("CENTER") end
    return fs
end
local function FontPath()
    return (root.Tok and root.Tok.font) or rawget(_G, "STANDARD_TEXT_FONT") or "Fonts\\FRIZQT__.TTF"
end

function Patrol.RefreshMap()
    local W, canvas = Canvas()
    local shown = W and W.IsShown and W:IsShown()
    local map = shown and W.GetMapID and W:GetMapID()
    local dots, label = {}, nil
    local w, h = Num(canvas and canvas:GetWidth()) or 0, Num(canvas and canvas:GetHeight()) or 0
    local k = canvas and CanvasK(W, canvas) or 1
    local size = DotSize("map", Eff(rawget(_G, "UIParent")))
    if map and canvas and w > 0 and h > 0 then
        dots, label = Patrol.MapDots(map, { w = w, h = h, k = k, size = size })
    end
    if not wm.frame then
        if not canvas or #dots == 0 then drawn.map, drawn.label = 0, nil; return end
        wm.frame = CreateFrame("Frame", nil, canvas)
        wm.frame:SetAllPoints(canvas)
        if wm.frame.EnableMouse then pcall(wm.frame.EnableMouse, wm.frame, false) end
        wm.label = MakeLabel(wm.frame)
    end
    local f = wm.frame
    -- one level under the walking path's dots (Trail.MapLevel: canvas + 2000, or over OpenMap's
    -- stitched art once it is built), asked again on every draw
    if canvas then
        local T = Trail()
        local want = (T and T.MapLevel and T.MapLevel(canvas)
            or ((canvas.GetFrameLevel and Num(canvas:GetFrameLevel()) or 1) + 2000)) - 1
        if f.wlLevel ~= want and not (f.wlLevel and InCombatLockdown and InCombatLockdown()) then
            if pcall(f.SetFrameLevel, f, want) then f.wlLevel = want end
        end
    end
    local r, g, b = Color()
    local dot, ring = size / k, RING.map / k
    Pool(f, wm.dots, #dots, dot, ring, r, g, b)
    for i, d in ipairs(dots) do Place(wm.dots[i], f, "TOPLEFT", d.x * w, -d.y * h) end
    drawn.map, drawn.mapDot, drawn.mapDotUI, drawn.color = #dots, dot, size, { r, g, b }
    local fs = wm.label
    if label and #dots > 0 then
        local text = LabelText(active and active.name)
        local fsz = LABEL_SIZE / k
        if fs.wlSize ~= fsz then
            if pcall(fs.SetFont, fs, FontPath(), fsz, "") then fs.wlSize = fsz end
        end
        local m = root.Tok and root.Tok.muted or { 0.604, 0.620, 0.651 }
        fs:SetTextColor(m[1], m[2], m[3], 1)
        fs:SetText(text)
        fs:ClearAllPoints()
        fs:SetPoint("BOTTOM", f, "TOPLEFT", label.x * w, -label.y * h + LABEL_LIFT / k)
        fs:Show()
        drawn.label, drawn.labelSize = text, LABEL_SIZE
    else
        fs:Hide()
        drawn.label = nil
    end
end

local mm = { dots = {} }
function Patrol.RefreshMinimap()
    local M = rawget(_G, "Minimap")
    local dots, size = Patrol.MinimapDots()
    if not M then drawn.minimap = 0; return end
    if not mm.frame then
        if #dots == 0 then drawn.minimap = 0; return end
        mm.frame = CreateFrame("Frame", nil, M)
        mm.frame:SetAllPoints(M)
        mm.frame:SetFrameLevel((M.GetFrameLevel and M:GetFrameLevel() or 1) + 4)
    end
    size = size or DotSize("minimap", Eff(M))
    local r, g, b = Color()
    Pool(mm.frame, mm.dots, #dots, size, RING.minimap, r, g, b)
    for i, d in ipairs(dots) do Place(mm.dots[i], M, "CENTER", d.x, d.y) end
    drawn.minimap, drawn.minimapDot = #dots, size
end

local HookMap
function Patrol.Refresh()
    if HookMap then pcall(HookMap) end
    pcall(Patrol.RefreshMap)
    pcall(Patrol.RefreshMinimap)
end

-- ---------------------------------------------------------------- when to draw

local ticker, ticks = nil, 0
local function StopTicker() if ticker then ticker:Cancel(); ticker = nil end end
local Update
local function StartTicker()
    if ticker or not (C_Timer and C_Timer.NewTicker) then return end
    ticks = 0
    ticker = C_Timer.NewTicker(MM_EVERY, function()
        ticks = ticks + 1
        if ticks % CHECK_EVERY == 0 then Update() end
        if not active then StopTicker(); return end
        if MinimapOn() then pcall(Patrol.RefreshMinimap) end
    end)
end

local updating = false
function Update()
    if updating then return end
    updating = true
    local ok, a = pcall(Compute)
    updating = false
    a = ok and a or nil
    local key = a and (a.q .. ":" .. a.which .. ":" .. tostring(a.map)) or nil
    if key ~= activeKey then
        active, activeKey = a, key
        Patrol.Refresh()
    end
    if active then StartTicker() else StopTicker() end
end
Patrol.Update = Update

-- After a function of a table runs (the GPS's start and stop, the walking path's redraws).
local function After(tbl, name, fn)
    local o = type(tbl) == "table" and tbl[name]
    if type(o) ~= "function" then return end
    tbl[name] = function(...)
        local r1, r2, r3, r4 = o(...)
        pcall(fn)
        return r1, r2, r3, r4
    end
end
After(GPS, "GoPoint", Update)
After(GPS, "Go", Update)          -- a writ tour takes the arrow
After(GPS, "Stop", Update)
-- The walking path's switches, sizes and colour call Trail.Refresh, and so does each new walking path
-- (often, while you walk): redrawn only when one of the settings changed.
local lastSig
local function Settings()
    local T = Trail()
    local function v(f) return T and f and tostring(f()) or "" end
    return table.concat({ tostring(MapOn()), tostring(MinimapOn()), v(T and T.MapSize), v(T and T.MinimapSize),
        v(T and T.Color) }, "|")
end
After(WP.Trail, "Refresh", function()
    local before = activeKey
    Update()
    local sig = Settings()
    if sig ~= lastSig then
        lastSig = sig
        if activeKey == before then Patrol.Refresh() end    -- Update already drew a new route
    end
end)

-- OpenMap's stitched view moving: once, and again on ADDON_LOADED "OpenMap" (it may load after the map hook)
local openMapHooked = false
local function HookOpenMap()
    if openMapHooked then return end
    local O = rawget(_G, "OpenMapAPI")
    if type(O) ~= "table" or type(O.RegisterCallback) ~= "function" then return end
    openMapHooked = true
    local function again() pcall(Patrol.RefreshMap); local Z = Patrol.Zones; if Z then pcall(Z.RefreshMap) end end
    pcall(O.RegisterCallback, "WLHelperPatrol", "OpenMap_ViewChanged", again)
    pcall(O.RegisterCallback, "WLHelperPatrol", "OpenMap_StitchedChanged", again)
end

-- The world map: drawn when it opens, changes map or zooms.
local hooked = false
function HookMap()
    if hooked then return end
    local W = rawget(_G, "WorldMapFrame")
    if not W then return end
    hooked = true
    local function zones() local Z = Patrol.Zones; if Z then pcall(Z.Update); pcall(Z.RefreshMap) end end
    local function redraw() Update(); pcall(Patrol.RefreshMap); zones() end
    if type(rawget(_G, "MapCanvasDataProviderMixin")) == "table" and CreateFromMixins and W.AddDataProvider then
        local p = CreateFromMixins(MapCanvasDataProviderMixin)
        function p:RefreshAllData() redraw() end
        function p:RemoveAllData() end
        function p:OnMapChanged() redraw() end
        function p:OnCanvasScaleChanged() pcall(Patrol.RefreshMap); local Z = Patrol.Zones; if Z then pcall(Z.RefreshMap) end end
        pcall(W.AddDataProvider, W, p)
    end
    -- the map's own "map set" signal, and OpenMap's stitched view moving (Trail.lua does the same)
    local R = rawget(_G, "EventRegistry")
    if type(R) == "table" and R.RegisterCallback then
        pcall(R.RegisterCallback, R, "MapCanvas.MapSet", redraw, Patrol)
    end
    HookOpenMap()
    if W.HookScript then W:HookScript("OnShow", redraw) end
end
Patrol._HookMap = HookMap

local ev = CreateFrame("Frame")
pcall(ev.RegisterEvent, ev, "PLAYER_LOGIN")
pcall(ev.RegisterEvent, ev, "ADDON_LOADED")      -- the world map, when the client loads it on demand
ev:SetScript("OnEvent", function(_, event, name)
    if event == "ADDON_LOADED" then
        if name == "Blizzard_WorldMap" then HookMap() elseif name == "OpenMap" then HookOpenMap() end
        return
    end
    HookMap()
    Update()
end)

-- ---------------------------------------------------------------- zones
-- The current step's objectives whose spawns spread over an area (o.area: a ring round an island,
-- several camps, a wide field; Engine.lua ns.AreaOf): each camp's outline as a dotted line in the
-- objective colour, on the world map (on the walking path's frame logic: Trail.MapLevel - 2, under
-- the patrol path) and on the minimap. Only the unfinished objectives of the step the guide is on
-- (frame.auto), cleared when that step changes or the guide closes. While one shows, the arrow's
-- spot follows you (root.AreaRefollow, UI.lua: picked again once you moved 30 yd), every second.
-- API: Zones.Active() -> nil | { { area, q, oi }, ... }; Zones.Update(); Zones.MapDots(map, view);
-- Zones.MinimapDots(); Zones.RefreshMap(); Zones.RefreshMinimap(); Zones._Drawn() (for the tests).
local Zones = {}
Patrol.Zones = Zones

local ZONE_SHARE = 0.8         -- a zone dot: this share of the patrol dot
local ZONE_ALPHA = 0.8
local ZONE_CAP = 300           -- dots at most on the world map, all camps together (as MAP_CAP)

local zActive, zKey
function Zones.Active() return zActive end

local function ZoneColor()
    local c = root.Tok and root.Tok.fg or { 0.941, 0.945, 0.953 }
    return c[1], c[2], c[3]
end

local function ZCompute()
    local f, steps = root.frame, root.route and root.route.steps
    if type(f) ~= "table" or type(steps) ~= "table" then return nil end
    if root.GuideOn and not root.GuideOn() then return nil end
    local st = f.auto and steps[f.auto]
    if not (st and type(st.acts) == "table") then return nil end
    local list, log
    for _, n in ipairs(st.acts) do
        local a = root.AreaOf and root.AreaOf(n)
        if a then
            if log == nil then
                local ok, l = pcall(function() return root.LogEntries and root.LogEntries() end)
                log = ok and l or false
            end
            local okD, done = pcall(function() return log and root.NodeOK and root.NodeOK(log, n) end)
            if not (okD and done) then
                list = list or {}
                list[#list + 1] = { area = a, q = n.q, oi = n.oi }
            end
        end
    end
    return list, f.auto
end

-- The camps as closed world lines { { {wx, wy}, ... }, ... } and their continent.
local function Lines()
    local out, cont = {}, nil
    for _, z in ipairs(zActive or {}) do
        local w = root.AreaWorld and root.AreaWorld(z.area)
        if w and (not cont or w.cont == cont) then
            cont = w.cont
            for _, poly in ipairs(w.polys) do
                local line = {}
                for _, p in ipairs(poly) do line[#line + 1] = { p[1], p[2] } end
                if #line >= 3 then line[#line + 1] = { poly[1][1], poly[1][2] } end
                out[#out + 1] = line
            end
        end
    end
    return out, cont
end

-- The world map's dots for map `map`: { { x, y (canvas 0..1) }, ... } (view: as Patrol.MapDots).
function Zones.MapDots(map, view)
    local dots = {}
    if not (zActive and map and MapOn()) then return dots end
    local lines, cont = Lines()
    if not cont then return dots end
    local proj, stitched = Projection(map, cont)
    if not proj then return dots end
    local lo, hi = 0, 1
    if stitched then lo, hi = -1, 2 end
    view = view or {}
    local w, h, k = view.w or 1000, view.h or 1000, view.k or 1
    local size = view.size or DotSize("map", nil) * ZONE_SHARE
    -- every camp's outline on the canvas, then one spacing for all: zoomed in, the cap widens the
    -- gaps of every camp alike (never the first camps taking every dot and the others none)
    local cls, total = {}, 0
    for _, line in ipairs(lines) do
        local cl = {}
        for _, p in ipairs(line) do
            local x, y = proj(cont, p[1], p[2])
            if not x then cl = nil; break end
            cl[#cl + 1] = { x * w, y * h }
        end
        if cl then
            cls[#cls + 1] = cl
            for i = 2, #cl do total = total + math.sqrt((cl[i][1] - cl[i - 1][1]) ^ 2 + (cl[i][2] - cl[i - 1][2]) ^ 2) end
        end
    end
    local step = GAP * size / k
    local room = ZONE_CAP - 2 * #cls
    if room > 0 and step > 0 and total / step > room then step = total / room end
    for _, cl in ipairs(cls) do
        local pts = #cl == 1 and { cl[1] } or Densify(cl, step, ZONE_CAP)
        for _, p in ipairs(pts) do
            local x, y = p[1] / w, p[2] / h
            if x >= lo and x <= hi and y >= lo and y <= hi and #dots < ZONE_CAP then dots[#dots + 1] = { x = x, y = y } end
        end
    end
    return dots
end

-- The minimap's dots: { { x, y (pixels from its centre) }, ... } and the dot's width.
function Zones.MinimapDots()
    local dots = {}
    if not (zActive and MinimapOn()) then return dots end
    local lines, cont = Lines()
    local pc, px, py = PlayerWorld()
    if not (cont and pc == cont) then return dots end
    local radius, half, facing, square, blind = MinimapView()
    if blind or not (radius and half) then return dots end
    local size = DotSize("minimap", Eff(rawget(_G, "Minimap"))) * ZONE_SHARE
    local spacing = math.max(2, GAP * size * radius / half)
    local lim = half - size / 2 - RING.minimap - 1
    local reach2 = (radius * 1.5) ^ 2
    for _, line in ipairs(lines) do
        local near = false
        for i = 1, #line do
            local a, b = line[i], line[i + 1] or line[i]
            local dx, dy = b[1] - a[1], b[2] - a[2]
            local l2 = dx * dx + dy * dy
            local t = l2 > 0 and math.max(0, math.min(1, ((px - a[1]) * dx + (py - a[2]) * dy) / l2)) or 0
            local ex, ey = a[1] + t * dx - px, a[2] + t * dy - py
            if ex * ex + ey * ey <= reach2 then near = true; break end
        end
        if near then
            local pts = #line == 1 and { line[1] } or Densify(line, spacing, 2000)
            for _, p in ipairs(pts) do
                local x, y = Project(p[1], p[2], px, py, radius, half, facing)
                if Inside(x, y, lim, square) and #dots < MM_CAP then dots[#dots + 1] = { x = x, y = y } end
            end
        end
    end
    return dots, size
end

local zdrawn = { map = 0, minimap = 0 }
function Zones._Drawn() return zdrawn end
local zwm, zmm = { dots = {} }, { dots = {} }

local function ZPlace(t, rel, point, x, y)
    Place(t, rel, point, x, y)
    t:SetAlpha(ZONE_ALPHA)
    t.wlRing:SetAlpha(ZONE_ALPHA * RING_ALPHA)
end

function Zones.RefreshMap()
    local W, canvas = Canvas()
    local shown = W and W.IsShown and W:IsShown()
    local map = shown and W.GetMapID and W:GetMapID()
    local w, h = Num(canvas and canvas:GetWidth()) or 0, Num(canvas and canvas:GetHeight()) or 0
    local k = canvas and CanvasK(W, canvas) or 1
    local size = DotSize("map", Eff(rawget(_G, "UIParent"))) * ZONE_SHARE
    local dots = {}
    if map and canvas and w > 0 and h > 0 then dots = Zones.MapDots(map, { w = w, h = h, k = k, size = size }) end
    if not zwm.frame then
        if not canvas or #dots == 0 then zdrawn.map = 0; return end
        zwm.frame = CreateFrame("Frame", nil, canvas)
        zwm.frame:SetAllPoints(canvas)
        if zwm.frame.EnableMouse then pcall(zwm.frame.EnableMouse, zwm.frame, false) end
    end
    local f = zwm.frame
    -- two levels under the walking path's dots (Trail.MapLevel), one under the patrol path
    if canvas then
        local T = Trail()
        local want = (T and T.MapLevel and T.MapLevel(canvas)
            or ((canvas.GetFrameLevel and Num(canvas:GetFrameLevel()) or 1) + 2000)) - 2
        if f.wlLevel ~= want and not (f.wlLevel and InCombatLockdown and InCombatLockdown()) then
            if pcall(f.SetFrameLevel, f, want) then f.wlLevel = want end
        end
        zdrawn.level = f.wlLevel
    end
    local r, g, b = ZoneColor()
    Pool(f, zwm.dots, #dots, size / k, RING.map / k, r, g, b)
    for i, d in ipairs(dots) do ZPlace(zwm.dots[i], f, "TOPLEFT", d.x * w, -d.y * h) end
    zdrawn.map, zdrawn.mapDot, zdrawn.color, zdrawn.frame = #dots, size / k, { r, g, b }, f
end

function Zones.RefreshMinimap()
    local M = rawget(_G, "Minimap")
    local dots, size = Zones.MinimapDots()
    if not M then zdrawn.minimap = 0; return end
    if not zmm.frame then
        if #dots == 0 then zdrawn.minimap = 0; return end
        zmm.frame = CreateFrame("Frame", nil, M)
        zmm.frame:SetAllPoints(M)
        zmm.frame:SetFrameLevel((M.GetFrameLevel and M:GetFrameLevel() or 1) + 3)
    end
    size = size or DotSize("minimap", Eff(M)) * ZONE_SHARE
    local r, g, b = ZoneColor()
    Pool(zmm.frame, zmm.dots, #dots, size, RING.minimap, r, g, b)
    for i, d in ipairs(dots) do ZPlace(zmm.dots[i], M, "CENTER", d.x, d.y) end
    zdrawn.minimap = #dots
end

local zTicker, zTicks = nil, 0
local function ZStop() if zTicker then zTicker:Cancel(); zTicker = nil end end
local ZUpdate
local function ZStart()
    if zTicker or not (C_Timer and C_Timer.NewTicker) then return end
    zTicks = 0
    zTicker = C_Timer.NewTicker(MM_EVERY, function()
        zTicks = zTicks + 1
        if zTicks % CHECK_EVERY == 0 then
            ZUpdate()
            if zActive and root.AreaRefollow then pcall(root.AreaRefollow) end
        end
        if not zActive then ZStop(); return end
        if MinimapOn() then pcall(Zones.RefreshMinimap) end
    end)
end

local zBusy = false
function ZUpdate()
    if zBusy then return end
    zBusy = true
    local ok, list, at = pcall(ZCompute)
    zBusy = false
    list = ok and list or nil
    local key
    if list then
        local parts = { tostring(at) }
        for _, z in ipairs(list) do parts[#parts + 1] = tostring(z.q) .. ":" .. tostring(z.oi) end
        key = table.concat(parts, "|")
    end
    if key ~= zKey then
        zActive, zKey = list, key
        if HookMap then pcall(HookMap) end
        pcall(Zones.RefreshMap)
        pcall(Zones.RefreshMinimap)
    end
    if zActive then ZStart() else ZStop() end
end
Zones.Update = ZUpdate

-- the guide's step moves (Refresh, PlacePoints, GoTo), the GPS starts or stops, the trail's settings
After(root, "Refresh", ZUpdate)
After(root, "PlacePoints", ZUpdate)
After(root, "GoTo", ZUpdate)
After(GPS, "GoPoint", ZUpdate)
After(GPS, "Stop", ZUpdate)
After(WP.Trail, "Refresh", function() if zActive then pcall(Zones.RefreshMap); pcall(Zones.RefreshMinimap) end end)
local zev = CreateFrame("Frame")
pcall(zev.RegisterEvent, zev, "PLAYER_LOGIN")
zev:SetScript("OnEvent", function() ZUpdate() end)
