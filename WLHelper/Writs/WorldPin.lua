-- Writs/WorldPin.lua: the in-world marker. While WL Helper's GPS guides you (any source: the dungeon
-- guide, the Comptoir, GoTo, the city tour...) and the point of the leg you walk is on your continent,
-- the game's own map pin is set there and tracked, so the game draws its navigation marker in the 3D
-- world; our label rides on it: a small dark panel with the place (line 1) and, big in the soft
-- accent, the distance left (the walking path when WL Helper Nav found one) with a small muted time
-- estimate from your real speed (line 2); under it the accent pin, a 1 px stem and a small flat ring
-- on the ground at the exact spot. The stem shortens as you come near (40 px far, 16 px close).
-- The idea is the same as Naowh Forever's Waypoint Pin; the code and the look are our own.
--
-- It steps in only when no other addon already does this job (Auto, the default): Naowh's Waypoint
-- Pin turned on, Waypoint UI, TomTom, Polestar's game waypoint option, Zygor's "use the game's
-- waypoint" option. WLWritsDB.worldPin: "auto" (default), "always", "never".
--
-- Rules: the map pin is set only where there is none, where the pin is ours, or where it is the
-- GPS's own writ pin (Route.lua's GPS.Go); a pin the player placed is never moved or cleared, and
-- one we set is cleared when the GPS stops, arrives, or the point leaves your continent. The target
-- is the end of the leg you follow (the step, the flight master, the boat), never a corner of the
-- walking path. Inside instances, on a taxi and while another addon owns it: nothing at all.
--
-- Cost: no frame update without a GPS target. While the label shows, its alpha (on screen, at the
-- edge) is checked 20 times a second and its text (and the stem length) 4 times a second, redrawn
-- only when it changes. The marker hangs on the game's navigation frame: no per-frame placement.
-- The map pin is never moved in combat (not protected, but the move waits for the end of the fight).
local ADDON, root = ...
root.Writs = root.Writs or {}
local ns = root.Writs
local WP = ns.WP
local L = ns.L
local T = root.Tok or (ns.S and ns.S.C) or {}
local GPS = WP.GPS

local WorldPin = {}
WP.WorldPin = WorldPin

ns.AddEnglish({
    ["Maître de vol de %s"] = "Flight master at %s",
    ["Zeppelin pour %s"] = "Zeppelin to %s",
    ["< 1 min"] = "< 1 min",
    ["~%d min"] = "~%d min",
    -- the Settings row (Options.lua, GPS page)
    ["Repère dans le monde"] = "In-world marker",
    ["Toujours"] = "Always",
    ["Jamais"] = "Never",
    ["Une étiquette dans le monde, sur le point du GPS : le lieu, la distance et le temps qu'il reste. En automatique, elle ne s'affiche que si aucun autre addon ne le fait déjà."] =
        "A label in the world, on the GPS point: the place, the distance and the time left. On Automatic, it shows only when no other addon already does.",
    ["Si tu as déjà posé un repère sur la carte, il est gardé et l'étiquette ne s'affiche pas."] =
        "If you already placed a map pin, it is kept and the label stays hidden.",
    ["Déjà fait par %s."] = "Already done by %s.",
    -- in the area of an objective spread over a zone (Engine.lua ns.AreaAt), in place of the distance
    ["Dans la zone"] = "In the area",
})

local UPDATE_EVERY, TEXT_EVERY, SYNC_EVERY = 0.05, 0.25, 1
local SAME = 0.0005          -- map fraction: the same pin (about half a yard on a zone map)
local EDGE_ALPHA = 0.40      -- the label at the edge of the screen (the point is behind or off screen)
local FADE = 0.5             -- share of the gap closed per update (about 0.10 s at 20 updates a second)
local STILL = 0.1            -- yards a second: below, you stand still and the time is hidden
local SMOOTH = 0.35          -- moving average of the speed (one sample per text update)
local PAD, GAP, LINE_GAP = 8, 6, 2
local NAME_W, MIN_W = 200, 72
local NAME_SIZE, DIST_SIZE, ETA_SIZE = 12, 16, 11
local PIN_SIZE, LIFT = 20, 4
local STEM_W, STEM_ALPHA = 1, 0.6
local STEM_FAR, STEM_NEAR = 40, 16        -- px: the stem at FAR_YD and beyond, at NEAR_YD and closer
local FAR_YD, NEAR_YD = 150, 15
local RING_W, RING_H, RING_ALPHA = 24, 8, 0.9   -- the ring on the ground: the HD ring drawn flat
local GAME_PARTS = { "Icon", "IconBorder", "DistanceText" }   -- the game's marker art; its edge arrow stays

-- ---------------------------------------------------------------- helpers

local function Secret(v) return issecretvalue ~= nil and issecretvalue(v) end
local function Num(v) return type(v) == "number" and not Secret(v) and v == v and v or nil end
local function Call(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, a, b = pcall(fn, ...)
    if ok then return a, b end
end
local function InCombat() return InCombatLockdown and InCombatLockdown() and true or false end
local function InInstance()
    if not IsInInstance then return false end
    local ok, inside, kind = pcall(IsInInstance)
    if not ok then return false end
    return (inside and kind ~= "none") and true or false
end
local function OnTaxi() return UnitOnTaxi and UnitOnTaxi("player") and true or false end

local function Color(c, a) c = c or { 1, 1, 1 }; return c[1], c[2], c[3], a or c[4] or 1 end

-- ---------------------------------------------------------------- the setting

function WorldPin.Mode()
    local v = WLWritsDB and WLWritsDB.worldPin
    if v == "always" or v == "never" then return v end
    return "auto"
end

-- ---------------------------------------------------------------- who already does it

-- Each check reads the other addon's own public state, never its files. A name when it owns the
-- in-world waypoint, else nil.
local OWNERS = {
    -- Naowh Forever's Waypoint Pin (NaowhForever_QoL publishes WaypointPinOn: its switch and the QoL module)
    function()
        local NF = rawget(_G, "NaowhForever")
        if type(NF) == "table" and type(NF.WaypointPinOn) == "function" and Call(NF.WaypointPinOn) then
            return "Naowh Forever"
        end
    end,
    -- Waypoint UI: draws the game's tracked target in the world
    function()
        if type(rawget(_G, "WaypointUIAPI")) == "table" then return "Waypoint UI" end
    end,
    -- TomTom: its own waypoints and crazy arrow
    function()
        local TT = rawget(_G, "TomTom")
        if type(TT) == "table" and type(TT.AddWaypoint) == "function" then return "TomTom" end
    end,
    -- Polestar: only when its "Blizzard waypoint" option sets the game's pin itself
    function()
        local P = rawget(_G, "Polestar")
        if type(P) == "table" and type(P.Get) == "function" and Call(P.Get, "nav.blizzardWaypoint") then
            return "Polestar"
        end
    end,
    -- Zygor: only when it takes over the game's waypoint ("hijack_builtin_waypoint")
    function()
        local Z = rawget(_G, "ZGV")
        local p = type(Z) == "table" and type(Z.db) == "table" and type(Z.db.profile) == "table" and Z.db.profile
        if p and p.hijack_builtin_waypoint then return "Zygor" end
    end,
}

local owner   -- the last answer, kept between two checks (login + 3 s, each addon loaded, each sync)
local function Detect()
    owner = nil
    for _, check in ipairs(OWNERS) do
        local ok, name = pcall(check)
        if ok and name then owner = name; break end
    end
    return owner
end

-- The addon that already shows the in-world waypoint (for the Settings line), or nil.
function WorldPin.Owner() return Detect() end

-- True when WL Helper places the in-world marker (the setting and the other addons agree).
function WorldPin.Wanted()
    local mode = WorldPin.Mode()
    if mode == "never" then return false end
    if mode == "auto" and Detect() then return false end
    return true
end

-- ---------------------------------------------------------------- the game's map pin

local mine        -- the pin we set: { map, x, y } (fractions), .got = what the game read back
local dismissed   -- key of a target whose pin vanished without us: not set again for that target
local placedKey   -- key of the target our pin stands for
local pending     -- a move that waits for the end of the fight

local function GetPin()
    if not (C_Map and C_Map.GetUserWaypoint) then return nil end
    local p = Call(C_Map.GetUserWaypoint)
    if type(p) ~= "table" then return nil end
    local pos = p.position
    local x, y
    if type(pos) == "table" then
        if pos.GetXY then x, y = Call(pos.GetXY, pos) else x, y = pos.x, pos.y end
    end
    return { map = p.uiMapID, x = Num(x), y = Num(y) }
end

local function Same(a, b)
    return a and b and a.map == b.map and a.x and b.x and a.y and b.y
        and math.abs(a.x - b.x) < SAME and math.abs(a.y - b.y) < SAME or false
end

-- Ours: the pin we asked for, or the one the game stored for it (it may move it to another map, a
-- parent or a floor, or round the coordinates).
local function Ours(p) return mine and p and (Same(p, mine) or Same(p, mine.got)) or false end

-- The GPS's own pin (Route.lua sets one at a writ's turn-in spot): we may move it.
local function GpsPin(p)
    local d = GPS.Dest and Call(GPS.Dest)
    if not (p and type(d) == "table" and d.map and Num(d.x) and Num(d.y)) then return false end
    return Same(p, { map = d.map, x = d.x / 100, y = d.y / 100 })
end

-- Clears the map pin only when it is still the one we set.
local function ClearMine()
    if not mine then return end
    local cur = GetPin()
    -- without a way to read the pin back, the last one set is taken as ours (we set it)
    local readable = C_Map and C_Map.GetUserWaypoint
    if (Ours(cur) or (not readable and not cur)) and C_Map and C_Map.ClearUserWaypoint then pcall(C_Map.ClearUserWaypoint) end
    mine, placedKey = nil, nil
end

local function Settable(map)
    if not (C_Map and C_Map.CanSetUserWaypointOnMap) then return true end
    local ok, yes = pcall(C_Map.CanSetUserWaypointOnMap, map)
    return not ok or yes ~= false
end

local function Inside(x, y) return x and y and x >= 0 and x <= 1 and y >= 0 and y <= 1 end

local function Parent(map)
    local info = C_Map and C_Map.GetMapInfo and Call(C_Map.GetMapInfo, map)
    local p = type(info) == "table" and info.parentMapID
    if p and p ~= 0 and p ~= map then return p end
end

-- A world point on a map the pin may go on: its own map when it has one, else the map you stand on,
-- then the maps above it.
local function MapPointFor(target, playerMap)
    if target.map and Num(target.x) and Num(target.y) and Settable(target.map) then
        return target.map, target.x / 100, target.y / 100
    end
    if not (C_Map and C_Map.GetMapPosFromWorldPos and CreateVector2D and target.cont and target.wx) then return nil end
    local map, hops = target.map or playerMap, 0
    while map and hops < 4 do
        local ok, m, pos = pcall(C_Map.GetMapPosFromWorldPos, target.cont, CreateVector2D(target.wx, target.wy), map)
        if ok and pos then
            local x, y
            if pos.GetXY then x, y = Call(pos.GetXY, pos) else x, y = pos.x, pos.y end
            x, y = Num(x), Num(y)
            local onMap = (type(m) == "number" and m) or map
            if Inside(x, y) and Settable(onMap) then return onMap, x, y end
        end
        map, hops = Parent(map), hops + 1
    end
end

-- True unless the game says it tracks something else (a quest clicked in the tracker): the
-- navigation frame then follows that, and our label must not sit on it.
local function TrackingOurs()
    if not (C_SuperTrack and C_SuperTrack.IsSuperTrackingUserWaypoint) then return true end
    local ok, yes = pcall(C_SuperTrack.IsSuperTrackingUserWaypoint)
    return not ok or yes ~= false
end

local function Track()
    if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
        pcall(C_SuperTrack.SetSuperTrackedUserWaypoint, true)
    end
end

-- Sets the pin for this target. True when the pin there is ours.
local function Place(key, map, x, y)
    if not (C_Map and C_Map.SetUserWaypoint and UiMapPoint and UiMapPoint.CreateFromCoordinates) then return false end
    local want = { map = map, x = x, y = y }
    local cur = GetPin()
    if mine and placedKey == key and Same(mine, want) then
        -- the game gives no way to read the pin back: ours stays ours
        if not C_Map.GetUserWaypoint then return true end
        if Ours(cur) then return true end
        -- ours vanished without us (reached, cleared by hand, replaced by a /way): left alone for this
        -- target. The GPS's own writ pin put over ours is moved back.
        if not (cur and GpsPin(cur)) then
            dismissed, mine, placedKey = key, nil, nil
            return false
        end
    end
    if dismissed == key then return false end
    -- a pin the player placed: never ours to move
    if cur and not Ours(cur) and not GpsPin(cur) then return false end
    if InCombat() then pending = true; return false end
    local point = Call(UiMapPoint.CreateFromCoordinates, map, x, y)
    if not point then return false end
    local ok = pcall(C_Map.SetUserWaypoint, point)
    if not ok then return false end
    mine, placedKey, dismissed = want, key, nil
    mine.got = GetPin()
    Track()
    return true
end

-- ---------------------------------------------------------------- what the GPS guides to

-- The end of the leg you follow: the step itself, else the flight master, the dock. Nil for a cast
-- leg (a teleport, the Hearthstone): there is nowhere to walk.
local function LegTarget(now)
    local leg = now.leg
    if not leg then return now.dest end
    if leg.kind == "ride" then return leg.to end
    if leg.kind == "fly" or leg.kind == "link" then return leg.from end
    return nil
end

local function Short(n) return GPS.ShortPlace and GPS.ShortPlace(n) or n or "?" end
local function Upper(s) return GPS.UpperFirst and GPS.UpperFirst(s) or s end

-- The label's first line: short, a name and not a sentence.
local function NameOf(now, target)
    if target == now.dest or not target then return Upper(Short(now.dest and now.dest.name)) end
    local link = target.link
    if target.kind == "taxi" or (link and link.mode == "flight") then
        return string.format(L("Maître de vol de %s"), Short(target.name))
    end
    if target.kind == "dock" and link then
        local other = target.other and target.other.name or target.name
        return string.format(link.mode == "boat" and L("Bateau pour %s") or L("Zeppelin pour %s"), Short(other))
    end
    return Upper(Short(target.name or (now.dest and now.dest.name)))
end

local function KeyOf(t)
    if t.map and t.x then return string.format("%s:%.2f:%.2f", tostring(t.map), t.x, t.y or 0) end
    return string.format("%s:%.0f:%.0f", tostring(t.cont), t.wx or 0, t.wy or 0)
end

local function DistanceText(yards)
    if GPS.Distance then
        local ok, t = pcall(GPS.Distance, yards)
        if ok and type(t) == "string" then return t end
    end
    local m = yards * 0.9144
    if m >= 1000 then
        local t = string.format("%.1f km", m / 1000)
        return ns.English and not ns.English() and (t:gsub("%.", ",")) or t
    end
    if m >= 100 then m = math.floor(m / 10 + 0.5) * 10 end
    return string.format("%d m", math.floor(m + 0.5))
end
WorldPin._Distance = DistanceText

local function EtaText(seconds)
    if not seconds then return "" end
    if seconds < 45 then return L("< 1 min") end
    return string.format(L("~%d min"), math.max(1, math.floor(seconds / 60 + 0.5)))
end
WorldPin._Eta = EtaText

-- ---------------------------------------------------------------- the label

local pin, gameFaded = nil, nil
local shown = { name = nil, dist = nil, eta = nil, key = nil }
local speed, alpha = nil, 1

local function NavFrame()
    if C_Navigation and C_Navigation.GetFrame then
        local f = Call(C_Navigation.GetFrame)
        if f then return f, true end
        return nil, true
    end
    -- older navigation: the game's tracked-marker frame alone
    local st = rawget(_G, "SuperTrackedFrame")
    if type(st) == "table" and st.IsShown and st:IsShown() then return st, false end
end

local function Text(parent, size, color)
    if root.Text then return root.Text(parent, size, color, false, "SHADOW") end
    local fs = parent:CreateFontString(nil, "OVERLAY")
    fs:SetFont(STANDARD_TEXT_FONT, size, "")
    fs:SetTextColor(Color(color))
    return fs
end

local function Build()
    if pin then return pin end
    local f = CreateFrame("Frame", "WLGPSWorldPin", UIParent)
    f.wlWorld, f.wlOwned = true, true
    f:SetSize(MIN_W, 40)
    if f.SetFrameStrata then f:SetFrameStrata("BACKGROUND") end
    if f.EnableMouse then f:EnableMouse(false) end
    f:Hide()
    -- the ring on the ground, centred on the spot (the frame's bottom sits half a ring under it)
    local ring = f:CreateTexture(nil, "BORDER")
    ring:SetSize(RING_W, RING_H)
    if root.SetHDIcon then root.SetHDIcon(ring, "ring", T.accent, RING_ALPHA) else ring:SetColorTexture(Color(T.accent, RING_ALPHA)) end
    ring:SetPoint("BOTTOM", f, "BOTTOM", 0, 0)
    ring:Show()
    f.ring = ring
    -- the 1 px stem from the ring up to the pin's tip
    local stem = f:CreateTexture(nil, "BORDER")
    stem:SetColorTexture(Color(T.accent, STEM_ALPHA))
    stem:SetSize(STEM_W, STEM_FAR)
    stem:SetPoint("BOTTOM", ring, "CENTER", 0, 0)
    stem:Show()
    f.stem, f.stemLen = stem, STEM_FAR
    -- the accent pin, its tip on the stem
    local mark = f:CreateTexture(nil, "ARTWORK")
    mark:SetSize(PIN_SIZE, PIN_SIZE)
    if root.SetHDIcon then root.SetHDIcon(mark, "pin", T.accent) else mark:SetColorTexture(Color(T.accent)) end
    mark:SetPoint("BOTTOM", stem, "TOP", 0, 0)
    f.mark = mark
    -- the panel above it
    local card = CreateFrame("Frame", nil, f)
    card.wlWorld = true
    card:SetPoint("BOTTOM", mark, "TOP", 0, LIFT)
    card:SetSize(MIN_W, 40)
    local bg = card:CreateTexture(nil, "BACKGROUND")
    bg:SetColorTexture(Color(T.bg))
    bg:SetAllPoints()
    local fill = card:CreateTexture(nil, "BORDER")
    fill:SetColorTexture(Color(T.cardFill))
    fill:SetAllPoints()
    if root.Outline then root.Outline(card, T.cardEdge) end
    card.name = Text(card, NAME_SIZE, T.fg)
    card.name:SetPoint("TOPLEFT", card, "TOPLEFT", PAD, -PAD)
    card.name:SetWidth(NAME_W)
    if card.name.SetJustifyH then card.name:SetJustifyH("LEFT") end
    if card.name.SetWordWrap then card.name:SetWordWrap(true) end
    if card.name.SetMaxLines then card.name:SetMaxLines(2) end
    -- line 2: the distance big in the soft accent, the time small and muted on its baseline
    card.dist = Text(card, DIST_SIZE, T.accentSoft or T.accent)
    card.dist:SetPoint("TOPLEFT", card.name, "BOTTOMLEFT", 0, -LINE_GAP)
    if card.dist.SetWordWrap then card.dist:SetWordWrap(false) end
    card.eta = Text(card, ETA_SIZE, T.muted)
    card.eta:SetPoint("BOTTOMLEFT", card.dist, "BOTTOMRIGHT", GAP, 1)
    if card.eta.SetWordWrap then card.eta:SetWordWrap(false) end
    f.card = card
    pin = f
    return f
end

local function Width(fs)
    local w = root.TextWidth and Call(root.TextWidth, fs) or Call(fs.GetStringWidth, fs)
    return Num(w) or 0
end

-- Sizes the panel to its text: the name up to 200 px on two lines, the distance line under it.
local function Layout()
    local card = pin.card
    local nameW = math.min(NAME_W, Width(card.name))
    local lineW = Width(card.dist) + ((shown.eta or "") ~= "" and (GAP + Width(card.eta)) or 0)
    local w = math.max(MIN_W, math.ceil(math.max(nameW, lineW)) + 2 * PAD)
    card.name:SetWidth(math.max(1, w - 2 * PAD))
    local nameH = Num(Call(card.name.GetStringHeight, card.name)) or NAME_SIZE
    local distH = Num(Call(card.dist.GetStringHeight, card.dist)) or DIST_SIZE
    if nameH <= 0 then nameH = NAME_SIZE end
    if distH <= 0 then distH = DIST_SIZE end
    local h = math.ceil(PAD + nameH + LINE_GAP + distH + PAD)
    card:SetSize(w, h)
    card.h = h
    pin:SetSize(math.max(w, RING_W), h + LIFT + PIN_SIZE + pin.stemLen + RING_H / 2)
end

-- The stem's length for a distance: STEM_FAR at FAR_YD and beyond, STEM_NEAR at NEAR_YD and closer.
local function StemFor(yards)
    if not yards or yards >= FAR_YD then return STEM_FAR end
    if yards <= NEAR_YD then return STEM_NEAR end
    local k = (yards - NEAR_YD) / (FAR_YD - NEAR_YD)
    return math.floor(STEM_NEAR + (STEM_FAR - STEM_NEAR) * k + 0.5)
end
WorldPin._StemFor = StemFor

local function SetFS(fs, t)
    t = t or ""
    if fs.cur ~= t then fs.cur = t; fs:SetText(t); return true end
    return false
end

-- The game's own marker art under ours: faded while our pin shows, given back after.
local function FadeGame(on)
    local st = rawget(_G, "SuperTrackedFrame")
    if type(st) ~= "table" then return end
    if on and not gameFaded then
        gameFaded = {}
        for _, k in ipairs(GAME_PARTS) do
            local part = st[k]
            if type(part) == "table" and part.SetAlpha and part.GetAlpha then
                gameFaded[k] = Num(Call(part.GetAlpha, part)) or 1
                pcall(part.SetAlpha, part, 0)
            end
        end
    elseif not on and gameFaded then
        for k, a in pairs(gameFaded) do
            local part = st[k]
            if type(part) == "table" and part.SetAlpha then pcall(part.SetAlpha, part, a) end
        end
        gameFaded = nil
    end
end

local function HideLabel()
    if pin then
        pin:SetScript("OnUpdate", nil)
        pin:Hide()
    end
    FadeGame(false)
    shown.key, speed = nil, nil
end

-- The GPS guides to a spot of an objective spread over an area (a spawn of o.area, Engine.lua
-- ns.AreaAt) and you stand in that area (ns.AreaInside): the label says "Dans la zone" instead of a
-- distance (the spot is only the nearest spawn; any spawn of the area will do).
local function InZone(now)
    -- off with the farm areas (beta.214): the label gives the distance to the game's quest area
    if not WorldPin.AREAS then return false end
    local d = type(now) == "table" and now.dest
    if type(d) ~= "table" or LegTarget(now) ~= d then return false end
    local m, x, y = Num(d.map), Num(d.x), Num(d.y)
    if not (m and x and y and root.AreaAt and root.AreaInside and root.PlayerWorld) then return false end
    local a = root.AreaAt(m, x, y)
    if not a then return false end
    local ok, here = pcall(root.PlayerWorld)
    return (ok and type(here) == "table" and root.AreaInside(a, here)) and true or false
end
WorldPin._InZone = InZone

-- Distance and time from one GPS answer; the text changes only when the words do.
local function Paint(now)
    local yards = Num(now.dist) or Num(now.straight)
    local spd = GetUnitSpeed and Num((Call(GetUnitSpeed, "player")))
    if spd then
        if spd < STILL then speed = nil
        else speed = speed and speed + (spd - speed) * SMOOTH or spd end
    end
    local card = pin.card
    local changed = SetFS(card.name, shown.name)
    local zone = InZone(now)
    changed = SetFS(card.dist, zone and L("Dans la zone") or (yards and DistanceText(yards) or "")) or changed
    shown.eta = (not zone and yards and speed and spd and spd >= STILL) and EtaText(yards / speed) or ""
    changed = SetFS(card.eta, shown.eta) or changed
    local len = StemFor(yards)
    if len ~= pin.stemLen then pin.stemLen = len; pin.stem:SetHeight(len); changed = true end
    if changed then Layout() end
end
WorldPin._Paint = Paint

local Sync   -- below
local textAt, nextSync = 0, 0
local function OnUpdate(self, elapsed)
    self.acc = (self.acc or 0) + (elapsed or 0)
    if self.acc < UPDATE_EVERY then return end
    local dt = self.acc
    self.acc = 0
    local nav, modern = NavFrame()
    if not nav then HideLabel(); return end
    local target = 1
    if modern and C_Navigation.HasValidScreenPosition and not Call(C_Navigation.HasValidScreenPosition) then target = 0
    elseif modern and C_Navigation.WasClampedToScreen and Call(C_Navigation.WasClampedToScreen) then target = EDGE_ALPHA end
    alpha = alpha + (target - alpha) * FADE
    if math.abs(target - alpha) < 0.02 then alpha = target end
    self:SetAlpha(alpha)
    -- at the edge of the screen the spot is not there: no stem, no ring (changed only when it flips)
    local onSpot = target == 1
    if onSpot ~= self.onSpot then
        self.onSpot = onSpot
        self.stem:SetShown(onSpot); self.ring:SetShown(onSpot)
    end
    textAt = textAt + dt
    if textAt >= TEXT_EVERY then
        textAt = 0
        local now = GPS.Active and GPS.Active() and Call(GPS.Now)
        local tg = now and LegTarget(now)
        -- a new leg, the arrival, the GPS stopped: the decision is taken again (once, not every frame)
        if not tg or now.arrived or KeyOf(tg) ~= shown.key or not TrackingOurs() then WorldPin.Sync(); return end
        Paint(now)
    end
end
WorldPin._OnUpdate = OnUpdate

local function ShowLabel(now, target, key)
    local nav = NavFrame()
    if not nav then HideLabel(); return false end
    Build()
    if pin.anchor ~= nav then
        pin:ClearAllPoints()
        -- the ring's centre on the navigation frame's point (the spot in the world)
        pin:SetPoint("BOTTOM", nav, "CENTER", 0, -RING_H / 2)
        pin.anchor = nav
    end
    if shown.key ~= key then speed = nil end
    shown.key, shown.name = key, NameOf(now, target)
    Paint(now)
    if not pin:IsShown() then
        alpha = 1; pin:SetAlpha(1)
        pin.onSpot = true; pin.stem:Show(); pin.ring:Show()
        pin:Show()
    end
    pin:SetScript("OnUpdate", OnUpdate)
    FadeGame(true)
    return true
end

-- ---------------------------------------------------------------- the decision

-- Gives everything back: no label, our pin (only ours) cleared.
local function Release()
    HideLabel()
    ClearMine()
    pending = nil
end

local ticker
local function StopTicker() if ticker then ticker:Cancel(); ticker = nil end end
local function StartTicker()
    if ticker or not (C_Timer and C_Timer.NewTicker) then return end
    ticker = C_Timer.NewTicker(SYNC_EVERY, function() WorldPin.Sync() end)
end

-- Why the marker is not shown right now (for the tests and /wl diag): nil when it is.
local why
function WorldPin.Why() return why end

function Sync()
    local active = GPS.Active and GPS.Active()
    if not active then why = "idle"; dismissed = nil; Release(); StopTicker(); return end
    StartTicker()
    if not WorldPin.Wanted() then why = owner and "owner" or "off"; Release(); return end
    if InInstance() then why = "instance"; Release(); return end
    if OnTaxi() then why = "taxi"; HideLabel(); return end
    local now = Call(GPS.Now)
    if not now then why = "nonow"; Release(); return end
    local target = LegTarget(now)
    if not target or now.arrived then why = now.arrived and "arrived" or "cast"; Release(); return end
    if not (now.cont and target.cont == now.cont) then why = "far"; Release(); return end
    local key = KeyOf(target)
    if placedKey and placedKey ~= key and not InCombat() then ClearMine() end
    local map, x, y = MapPointFor(target, now.map)
    if not map then why = "nomap"; Release(); return end
    if not Place(key, map, x, y) then why = "taken"; HideLabel(); return end
    -- the player tracks something else (a quest): the pin stays, the label waits; never tracked back by force
    if not TrackingOurs() then why = "tracked"; HideLabel(); return end
    why = nil
    ShowLabel(now, target, key)
end
-- One decision at a time: setting or clearing the pin fires USER_WAYPOINT_UPDATED, and GPS.Now may
-- announce a new leg, both of which ask again while we decide; that ask runs right after.
local busy, again = false, false
function WorldPin.Sync()
    if busy then again = true; return end
    busy = true
    local n = 0
    repeat
        again, n = false, n + 1
        local ok, err = pcall(Sync)
        if not ok and geterrorhandler then geterrorhandler()(err) end
    until not again or n >= 3
    busy = false
end

function WorldPin.SetMode(v)
    if v ~= "always" and v ~= "never" then v = "auto" end
    WLWritsDB = WLWritsDB or {}
    WLWritsDB.worldPin = v
    WorldPin.Sync()
end

-- True while our label shows.
function WorldPin.Shown() return pin and pin:IsShown() and true or false end

-- for the tests
function WorldPin._Reset()
    HideLabel(); StopTicker()
    mine, dismissed, placedKey, pending, owner, why = nil, nil, nil, nil, nil, nil
end
-- Is the game's map pin one WL Helper set (this marker's, or the GPS's own)? Way.lua's map-pin
-- follower must not chase our own pins.
function WorldPin.IsOurs()
    local p = GetPin()
    return p ~= nil and (Ours(p) or GpsPin(p)) or false
end
function WorldPin._Mine() return mine end
function WorldPin._Frame() return pin end
function WorldPin._Alpha() return alpha end
function WorldPin._Stem() return pin and pin.stemLen end

-- ---------------------------------------------------------------- wiring

-- The GPS says when its plan changes and when it stops: the decision follows at once.
-- Without hooksecurefunc, a slow watch (every 2 s) does the same.
local function Wake() WorldPin.Sync() end
local hooked = false
if hooksecurefunc and type(GPS.OnChanged) == "function" and type(GPS.Stop) == "function" then
    hooked = pcall(hooksecurefunc, GPS, "OnChanged", Wake) and pcall(hooksecurefunc, GPS, "Stop", Wake)
end
local function Watch()
    if hooked or not (C_Timer and C_Timer.NewTicker) then return end
    C_Timer.NewTicker(2, function() if not ticker and GPS.Active and GPS.Active() then WorldPin.Sync() end end)
end

local ev = CreateFrame("Frame")
for _, e in ipairs({ "PLAYER_LOGIN", "ADDON_LOADED", "PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA",
    "PLAYER_REGEN_ENABLED", "NAVIGATION_FRAME_CREATED", "NAVIGATION_FRAME_DESTROYED", "USER_WAYPOINT_UPDATED", "SUPER_TRACKING_CHANGED" }) do
    pcall(ev.RegisterEvent, ev, e)
end
ev:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        Detect()
        Watch()
        -- addons that set up their settings after login
        if C_Timer and C_Timer.After then C_Timer.After(3, function() Detect(); WorldPin.Sync() end) end
        return
    end
    if event == "ADDON_LOADED" then Detect(); if GPS.Active and GPS.Active() then WorldPin.Sync() end; return end
    if event == "PLAYER_REGEN_ENABLED" then
        if pending then pending = nil; WorldPin.Sync() end
        return
    end
    if event == "NAVIGATION_FRAME_DESTROYED" then HideLabel() end
    if GPS.Active and GPS.Active() then WorldPin.Sync() end
end)
