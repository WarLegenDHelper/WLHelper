-- Writs/Way.lua: "/way" through WL Helper's GPS (Route.lua, Arrow.lua).
--   /way 52.4 31.2                 a point in the zone you stand in
--   /way Tanaris 52,4 31,2 Gadget  a zone (French or English, accents optional), then a label
--   /way #1446 52 31               a uiMapID, as TomTom writes it
--   /way  or  /way clear           stops it
-- TomTom's syntax, so the macros and guides players already have keep working. The point goes to our
-- arrow (source "way") and to the world map's pin. When TomTom, WayDirect, Polestar or another addon
-- already answers /way, we leave it alone: /wlway and /wlh way work, and a Settings switch
-- (WLWritsDB.wayTake) lets the player give /way to WL Helper anyway.
local ADDON, root = ...
root.Writs = root.Writs or {}
local ns = root.Writs
local WP = ns.WP
local L = ns.L

local Way = {}
WP.Way = Way

ns.AddEnglish({
    ["GPS : en route vers %s %s %s."] = "GPS: on the way to %s %s %s.",
    ["GPS : en route vers %s (%s %s %s)."] = "GPS: on the way to %s (%s %s %s).",
    ["GPS arrêté."] = "GPS stopped.",
    ["Aucun point /way en cours : rien à arrêter."] = "No /way point running: nothing to stop.",
    ["Tu y es : %s."] = "You're there: %s.",
    ["Zone inconnue : %s. Écris son nom comme sur la carte, par exemple /way Tanaris 52,4 31,2."] =
        "Unknown zone: %s. Type its name as the map shows it, for example /way Tanaris 52.4 31.2.",
    ["Plusieurs zones possibles : %s. Écris le nom en entier."] = "Several zones match: %s. Type the full name.",
    ["Je ne sais pas dans quelle zone tu es : ajoute son nom, par exemple /way Tanaris 52,4 31,2."] =
        "I can't tell which zone you're in: add its name, for example /way Tanaris 52.4 31.2.",
    ["Exemple : /way Tanaris 52,4 31,2, ou /way 52,4 31,2 dans ta zone. /way seul arrête le GPS."] =
        "Example: /way Tanaris 52.4 31.2, or /way 52.4 31.2 in your zone. /way alone stops the GPS.",
    ["Impossible de guider vers ce point : la carte de cette zone n'est pas lisible."] =
        "Can't guide you there: this zone's map can't be read.",
    ["Le GPS de WL Helper n'est pas chargé. Tape /reload pour recharger l'interface, puis réessaie."] =
        "WL Helper's GPS isn't loaded. Type /reload to reload the interface, then try again.",
    ["un autre addon"] = "another addon",
})

local SOURCE = "way"

-- ---------------------------------------------------------------- names

-- Accents typed or not, capitals or not: "Féralas", "feralas" and "FERALAS" are the same zone.
-- One table for the addon: GoTo.lua folds its names with it too (Way.FOLD).
local FOLD = {}
do
    local function add(chars, to) for c in chars:gmatch("[\192-\223][\128-\191]") do FOLD[c] = to end end
    add("àáâãäåÀÁÂÃÄÅ", "a"); add("çÇ", "c"); add("èéêëÈÉÊË", "e"); add("ìíîïÌÍÎÏ", "i")
    add("ñÑ", "n"); add("òóôõöøÒÓÔÕÖØ", "o"); add("ùúûüÙÚÛÜ", "u"); add("ýÿÝ", "y")
    add("œŒ", "oe"); add("æÆ", "ae"); add("ß", "ss")
end
Way.FOLD = FOLD
-- Leading articles the player may or may not type: "Les Tarides" = "Tarides", "The Barrens" = "Barrens".
local ARTICLES = { "the", "les", "le", "la", "l" }

-- Returns the compact key ("valleedestrangleronce") and its words ({ "vallee", "de", ... }).
local function Norm(s)
    if type(s) ~= "string" then return "", {} end
    s = s:gsub("[\192-\223][\128-\191]", function(c) return FOLD[c] or c end):lower()
    s = s:gsub("[^%w]+", " ")
    for _, a in ipairs(ARTICLES) do
        local rest = s:match("^%s*" .. a .. "%s+(.+)$")
        if rest then s = rest; break end
    end
    local words = {}
    for w in s:gmatch("%w+") do words[#words + 1] = w end
    return table.concat(words), words
end
Way.Norm = Norm

-- Every classic zone in English and in French: the client only knows its own language's names, and a
-- guide copied from an English site must work on a French client (and the reverse). The addon's one
-- copy: GoTo.lua reads it (Way.ZONES), so a fixed French name lands in both.
local ZONES = {
    [1411] = { "Durotar", "Durotar" }, [1412] = { "Mulgore", "Mulgore" },
    [1413] = { "The Barrens", "Les Tarides" }, [1414] = { "Kalimdor", "Kalimdor" },
    [1415] = { "Eastern Kingdoms", "Royaumes de l'Est" }, [1416] = { "Alterac Mountains", "Montagnes d'Alterac" },
    [1417] = { "Arathi Highlands", "Hautes-terres d'Arathi" }, [1418] = { "Badlands", "Terres ingrates" },
    [1419] = { "Blasted Lands", "Terres foudroyées" }, [1420] = { "Tirisfal Glades", "Clairières de Tirisfal" },
    [1421] = { "Silverpine Forest", "Forêt des Pins-Argentés" }, [1422] = { "Western Plaguelands", "Maleterres de l'Ouest" },
    [1423] = { "Eastern Plaguelands", "Maleterres de l'Est" }, [1424] = { "Hillsbrad Foothills", "Contreforts de Hautebrande" },
    [1425] = { "The Hinterlands", "Les Hinterlands" }, [1426] = { "Dun Morogh", "Dun Morogh" },
    [1427] = { "Searing Gorge", "Gorge des Vents brûlants" }, [1428] = { "Burning Steppes", "Steppes ardentes" },
    [1429] = { "Elwynn Forest", "Forêt d'Elwynn" }, [1430] = { "Deadwind Pass", "Défilé de Deuillevent" },
    [1431] = { "Duskwood", "Bois de la Pénombre" }, [1432] = { "Loch Modan", "Loch Modan" },
    [1433] = { "Redridge Mountains", "Les Carmines" }, [1434] = { "Stranglethorn Vale", "Vallée de Strangleronce" },
    [1435] = { "Swamp of Sorrows", "Marais des Chagrins" }, [1436] = { "Westfall", "Marche de l'Ouest" },
    [1437] = { "Wetlands", "Les Paluns" }, [1438] = { "Teldrassil", "Teldrassil" },
    [1439] = { "Darkshore", "Sombrivage" }, [1440] = { "Ashenvale", "Orneval" },
    [1441] = { "Thousand Needles", "Mille pointes" }, [1442] = { "Stonetalon Mountains", "Les Serres-Rocheuses" },
    [1443] = { "Desolace", "Désolace" }, [1444] = { "Feralas", "Féralas" },
    [1445] = { "Dustwallow Marsh", "Marécage d'Âprefange" }, [1446] = { "Tanaris", "Tanaris" },
    [1447] = { "Azshara", "Azshara" }, [1448] = { "Felwood", "Gangrebois" },
    [1449] = { "Un'Goro Crater", "Cratère d'Un'Goro" }, [1450] = { "Moonglade", "Reflet-de-Lune" },
    [1451] = { "Silithus", "Silithus" }, [1452] = { "Winterspring", "Berceau-de-l'Hiver" },
    [1453] = { "Stormwind City", "Hurlevent" }, [1454] = { "Orgrimmar", "Orgrimmar" },
    [1455] = { "Ironforge", "Forgefer" }, [1456] = { "Thunder Bluff", "Les Pitons-du-Tonnerre" },
    [1457] = { "Darnassus", "Darnassus" }, [1458] = { "Undercity", "Fossoyeuse" },
}
Way.ZONES = ZONES
-- Short names guides and players use; matched whole only ("if" must not catch "Ifrit").
local ALIASES = {
    stv = 1434, sw = 1453, stormwind = 1453, org = 1454, orgri = 1454, ["if"] = 1455, tb = 1456,
    uc = 1458, epl = 1423, wpl = 1422, ungoro = 1449, hillsbrad = 1424, tirisfal = 1420,
    stranglethorn = 1434, dustwallow = 1445, thousandneedles = 1441, barrens = 1413, hinterlands = 1425,
}

local index   -- { { key = "tanaris", words = {...}, map = 1446 }, ... } built once, on first use

local function MapInfo(id)
    if not (C_Map and type(C_Map.GetMapInfo) == "function") then return nil end
    local ok, info = pcall(C_Map.GetMapInfo, id)
    if ok and type(info) == "table" then return info end
end

local function Add(name, map)
    if type(name) ~= "string" or name == "" or type(map) ~= "number" then return end
    local key, words = Norm(name)
    if key == "" then return end
    for _, e in ipairs(index) do if e.key == key and e.map == map then return end end
    index[#index + 1] = { key = key, words = words, map = map }
end

-- The client's own names first (they are what the player reads on the map), then the table above.
local function BuildIndex()
    index = {}
    local conts = {}
    local seen = {}
    local function cont(id) if type(id) == "number" and not seen[id] then seen[id] = true; conts[#conts + 1] = id end end
    local getChildren = C_Map and type(C_Map.GetMapChildrenInfo) == "function" and C_Map.GetMapChildrenInfo
    if getChildren then
        local ok, list = pcall(getChildren, 947)
        if ok and type(list) == "table" then
            for _, c in ipairs(list) do if c and c.mapType == 2 then cont(c.mapID) end end
        end
    end
    cont(1414); cont(1415)
    if getChildren then
        for _, c in ipairs(conts) do
            local info = MapInfo(c)
            if info then Add(info.name, c) end
            local ok, list = pcall(getChildren, c, nil, true)
            if ok and type(list) == "table" then
                for _, z in ipairs(list) do
                    if z and (z.mapType == 2 or z.mapType == 3) then Add(z.name, z.mapID) end
                end
            end
        end
    end
    for map, names in pairs(ZONES) do
        -- a uiMapID this client doesn't know is left out (GetMapInfo says nil)
        if not C_Map or type(C_Map.GetMapInfo) ~= "function" or MapInfo(map) then
            Add(names[1], map); Add(names[2], map)
        end
    end
end

-- The zone's name as this client writes it (else French or English from the table).
function Way.ZoneName(map)
    local info = MapInfo(map)
    if info and type(info.name) == "string" and info.name ~= "" then return info.name end
    local z = ZONES[map]
    if z then return ns.English and ns.English() and z[1] or z[2] end
    return "#" .. tostring(map)
end

-- Zone text -> uiMapID. Whole name first, then a known short name, then the start of a word when
-- only one zone fits ("strangle" -> Stranglethorn). Returns nil and the candidates when unsure.
function Way.FindZone(text)
    local key = Norm(text)
    if key == "" then return nil end
    if not index then BuildIndex() end
    for _, e in ipairs(index) do if e.key == key then return e.map end end
    if ALIASES[key] then return ALIASES[key] end
    local found, order = {}, {}
    for _, e in ipairs(index) do
        local hit = e.key:sub(1, #key) == key
        if not hit then
            -- from any word on: "pins" finds "Forêt des Pins-Argentés"
            for i = 2, #e.words do
                if table.concat(e.words, "", i):sub(1, #key) == key then hit = true; break end
            end
        end
        if hit and not found[e.map] then found[e.map] = true; order[#order + 1] = e.map end
    end
    if #order == 1 then return order[1] end
    if #order > 1 then return nil, order end
    return nil
end

-- ---------------------------------------------------------------- parsing (pure)

-- compared after Norm: "Arrêter", "arreter" and "ARRÊTER" are one word
local CLEAR = { clear = true, reset = true, stop = true, off = true, effacer = true, stopper = true, arreter = true }
local HELP = { help = true, aide = true, ["?"] = true }

local function IsNum(t) return type(t) == "string" and t:match("^%d+[.,]?%d*$") ~= nil and t:match("%d") ~= nil end
local function ToNum(t) return tonumber((t:gsub(",", "."))) end

-- "/way" text -> { clear = true } | { help = true } | { x, y, zone, mapID, desc }, or nil and "usage".
-- x and y are percent (0-100). zone is the text before the numbers, mapID the "#1446" form.
-- "52,4 31,2" is a French decimal pair; "52,31" alone and "52.4,31.2" are x,y with a comma between.
function Way.Parse(msg)
    msg = type(msg) == "string" and msg:gsub("^%s+", ""):gsub("%s+$", "") or ""
    if msg == "" then return { clear = true } end
    local low = msg:lower()
    if CLEAR[Norm(msg)] or low:match("^reset%s") or low:match("^clear%s") then return { clear = true } end
    if HELP[low] then return { help = true } end

    local raw = {}
    for t in msg:gmatch("%S+") do raw[#raw + 1] = t end
    local toks = {}
    for i, t in ipairs(raw) do
        local core = t:gsub(",+$", "")   -- "52.4," then "31.2": TomTom's comma between numbers
        local a, b = core:match("^(%d+%.?%d*),(%d+%.?%d*)$")
        local nextNum = IsNum((raw[i + 1] or ""):gsub(",+$", ""))
        local prevNum = i > 1 and IsNum((raw[i - 1] or ""):gsub(",+$", ""))
        if a and (a:find(".", 1, true) or b:find(".", 1, true) or not (nextNum or prevNum)) then
            toks[#toks + 1] = a; toks[#toks + 1] = b
        elseif core ~= "" then
            toks[#toks + 1] = core
        end
    end

    local at
    for i = 1, #toks - 1 do
        if IsNum(toks[i]) and IsNum(toks[i + 1]) then at = i; break end
    end
    if not at then return nil, "usage" end
    local x, y = ToNum(toks[at]), ToNum(toks[at + 1])
    if not (x and y) or x < 0 or x > 100 or y < 0 or y > 100 then return nil, "usage" end

    local r = { x = x, y = y }
    if at > 1 then
        local zone = table.concat(toks, " ", 1, at - 1)
        local id = zone:match("^#(%d+)$")
        if id then r.mapID = tonumber(id) else r.zone = zone end
    end
    if at + 2 <= #toks then
        local desc = table.concat(toks, " ", at + 2)
        if desc ~= "" then r.desc = desc end
    end
    return r
end

-- 52.4 -> "52,4" in French, "52.4" in English; 52.0 -> "52".
function Way.Coord(v)
    v = math.floor((tonumber(v) or 0) * 10 + 0.5) / 10
    local s = (v == math.floor(v)) and string.format("%d", v) or string.format("%.1f", v)
    if not (ns.English and ns.English()) then s = s:gsub("%.", ",") end
    return s
end

-- ---------------------------------------------------------------- guiding

local pin       -- the world map pin we placed: { map, x, y } (0-1), so we never clear the player's own
local watcher   -- ticker that ends the trip on arrival, only while our point is on
local trip = 0  -- one number per point: an arrival's delayed stop never ends a newer point
local STAY = 6  -- seconds the arrow says "Tu y es" before it goes (as "Aller à" does)

local function ClearPin()
    if not pin then return end
    local mine = pin
    pin = nil
    if not (C_Map and type(C_Map.ClearUserWaypoint) == "function") then return end
    local ok, p = true, nil
    if type(C_Map.GetUserWaypoint) == "function" then ok, p = pcall(C_Map.GetUserWaypoint) end
    local pos = ok and p and p.position
    if not (ok and p) or (pos and p.uiMapID == mine.map and math.abs(pos.x - mine.x) < 0.001 and math.abs(pos.y - mine.y) < 0.001) then
        pcall(C_Map.ClearUserWaypoint)
    end
end

local function SetPin(map, x, y)
    -- WL Helper's in-world marker (WorldPin.lua) places the map pin itself, on the leg you follow, and
    -- tracks it for its label: a pin of ours, untracked, would hide that label for the whole trip
    local WPn = WP.WorldPin
    if WPn and type(WPn.Wanted) == "function" then
        local ok, wanted = pcall(WPn.Wanted)
        if ok and wanted then
            if WPn.Sync then pcall(WPn.Sync) end
            return
        end
    end
    if not (C_Map and type(C_Map.SetUserWaypoint) == "function" and UiMapPoint and type(UiMapPoint.CreateFromCoordinates) == "function") then return end
    if type(C_Map.CanSetUserWaypointOnMap) == "function" then
        local ok, can = pcall(C_Map.CanSetUserWaypointOnMap, map)
        if not ok or not can then return end
    end
    local ok, point = pcall(UiMapPoint.CreateFromCoordinates, map, x / 100, y / 100)
    if not (ok and point) then return end
    if pcall(C_Map.SetUserWaypoint, point) then
        pin = { map = map, x = x / 100, y = y / 100 }
        -- our arrow guides: the game's yellow marker would be a second arrow on screen
        if C_SuperTrack and type(C_SuperTrack.SetSuperTrackedUserWaypoint) == "function" then
            pcall(C_SuperTrack.SetSuperTrackedUserWaypoint, false)
        end
    end
end

local function StopWatch()
    if watcher then watcher:Cancel(); watcher = nil end
end

local function Mine() return WP.GPS and WP.GPS.Source() == SOURCE end

-- Every second while our point is on: arrived, it ends (as TomTom does) after the arrow showed
-- "Tu y es" a few seconds; taken over by the dungeon guide or a writ tour, our pin goes.
local function Watch()
    if not Mine() then StopWatch(); ClearPin(); return end
    local ok, now = pcall(WP.GPS.Now)
    if ok and now and now.source == SOURCE and now.arrived then
        local name = WP.GPS.DestName()
        StopWatch()
        WP.Print(string.format(L("Tu y es : %s."), name or "?"))
        local my = trip
        local function done()
            if my ~= trip then return end
            if Mine() then WP.GPS.Stop(SOURCE) end
            ClearPin()
        end
        if C_Timer and C_Timer.After then C_Timer.After(STAY, done) else done() end
    end
end

-- Guides to (map, x, y) in percent. label: what the arrow says (the zone and coordinates when nil).
-- quiet: no confirmation line. Returns true when the GPS took the point.
function Way.Go(map, x, y, label, quiet)
    local GPS = WP.GPS
    if not (GPS and GPS.GoPoint) then WP.Print(L("Le GPS de WL Helper n'est pas chargé. Tape /reload pour recharger l'interface, puis réessaie.")); return false end
    map, x, y = tonumber(map), tonumber(x), tonumber(y)
    if not (map and x and y) or x < 0 or x > 100 or y < 0 or y > 100 then
        WP.Print(L("Exemple : /way Tanaris 52,4 31,2, ou /way 52,4 31,2 dans ta zone. /way seul arrête le GPS."))
        return false
    end
    local where = Way.ZoneName(map) .. " " .. Way.Coord(x) .. " " .. Way.Coord(y)
    if type(label) ~= "string" or label == "" then label = nil end
    -- the player typed it: it goes before a writ tour (GoPoint never takes over a tour on its own)
    if GPS.Source() == "writs" then
        if WLWritsCharDB then WLWritsCharDB.gps = false end
        GPS.Stop("writs")
        if WP.OnGPSChanged then pcall(WP.OnGPSChanged) end
    end
    ClearPin()
    trip = trip + 1
    GPS.GoPoint(map, x, y, label or where, SOURCE)
    if not Mine() then
        WP.Print(L("Impossible de guider vers ce point : la carte de cette zone n'est pas lisible."))
        return false
    end
    SetPin(map, x, y)
    if not watcher and C_Timer and C_Timer.NewTicker then watcher = C_Timer.NewTicker(1, Watch) end
    if not quiet then
        local zone, cx, cy = Way.ZoneName(map), Way.Coord(x), Way.Coord(y)
        -- the place first when the player named it: "GPS : en route vers Camp Mojache (Féralas 30,5 40)."
        if label then WP.Print(string.format(L("GPS : en route vers %s (%s %s %s)."), label, zone, cx, cy))
        else WP.Print(string.format(L("GPS : en route vers %s %s %s."), zone, cx, cy)) end
    end
    return true
end

-- Stops our point (the dungeon guide's or a writ tour's arrow is left alone, so "GPS arrêté" is
-- said only when our point was the one running).
function Way.Clear(quiet)
    StopWatch()
    trip = trip + 1
    local was = Mine()
    if was then WP.GPS.Stop(SOURCE) end
    ClearPin()
    if not quiet then WP.Print(was and L("GPS arrêté.") or L("Aucun point /way en cours : rien à arrêter.")) end
    return was
end

local function PlayerMap()
    if not (C_Map and type(C_Map.GetBestMapForUnit) == "function") then return nil end
    local ok, m = pcall(C_Map.GetBestMapForUnit, "player")
    if ok and type(m) == "number" and not (issecretvalue and issecretvalue(m)) then return m end
end

-- What /way, /wlway and /wlh way run.
function Way.Command(msg)
    local r = Way.Parse(msg)
    if not r or r.help then
        WP.Print(L("Exemple : /way Tanaris 52,4 31,2, ou /way 52,4 31,2 dans ta zone. /way seul arrête le GPS."))
        return
    end
    if r.clear then Way.Clear(); return end
    local map = r.mapID
    if not map and r.zone then
        local found, several = Way.FindZone(r.zone)
        if not found then
            if several then
                local names = {}
                for i = 1, math.min(#several, 4) do names[#names + 1] = Way.ZoneName(several[i]) end
                WP.Print(string.format(L("Plusieurs zones possibles : %s. Écris le nom en entier."), table.concat(names, ", ")))
            else
                WP.Print(string.format(L("Zone inconnue : %s. Écris son nom comme sur la carte, par exemple /way Tanaris 52,4 31,2."), r.zone))
            end
            return
        end
        map = found
    end
    map = map or PlayerMap()
    if not map then WP.Print(L("Je ne sais pas dans quelle zone tu es : ajoute son nom, par exemple /way Tanaris 52,4 31,2.")); return end
    Way.Go(map, r.x, r.y, r.desc)
end

-- ---------------------------------------------------------------- /way: ours, or left to its owner

SlashCmdList = SlashCmdList or {}
SLASH_WLHWAY1 = "/wlway"
SlashCmdList.WLHWAY = function(msg) Way.Command(msg) end

-- The /way owners players have, by their SlashCmdList key, in the order they are named
local KNOWN_ORDER = { "TOMTOM_WAY", "WAYDIRECT", "POLESTARWAY", "EUIWAY" }
local KNOWN = { TOMTOM_WAY = "TomTom", WAYDIRECT = "WayDirect", POLESTARWAY = "Polestar", EUIWAY = "EllesmereUI" }

local function AnswersWay(key)
    if key == "WLHWAY" or SlashCmdList[key] == nil then return false end
    for i = 1, 10 do
        local s = _G["SLASH_" .. key .. i]
        if type(s) == "string" and s:lower() == "/way" then return true end
    end
    return false
end

-- The SlashCmdList key of another addon that answers /way, or nil. Known addons first, in a fixed
-- order, then the others by name: the same answer every time (pairs() has no order).
function Way.OtherOwner()
    for _, key in ipairs(KNOWN_ORDER) do
        if AnswersWay(key) then return key end
    end
    local keys = {}
    for key in pairs(SlashCmdList) do if type(key) == "string" then keys[#keys + 1] = key end end
    table.sort(keys)
    for _, key in ipairs(keys) do
        if AnswersWay(key) then return key end
    end
    local h = type(hash_SlashCmdList) == "table" and hash_SlashCmdList["/WAY"]
    if h and h ~= SlashCmdList.WLHWAY then return "?" end
end

-- A readable name for that owner ("TomTom", else the key itself).
function Way.OtherOwnerName()
    local k = Way.OtherOwner()
    if not k then return nil end
    if KNOWN[k] then return KNOWN[k] end
    if k == "?" then return L("un autre addon") end
    return (k:gsub("_WAY$", ""))
end

local owned = false
local before   -- what /WAY did before we took it, given back if the player switches it off

-- WLWritsDB.wayTake: nil = take /way only when it is free; true = take it anyway; false = never.
function Way.WantsWay()
    local v = WLWritsDB and WLWritsDB.wayTake
    if v == nil then return Way.OtherOwner() == nil end
    return v and true or false
end

function Way.Takes() return owned end

function Way.Apply()
    local hash = type(hash_SlashCmdList) == "table" and hash_SlashCmdList or nil
    local fn = SlashCmdList.WLHWAY
    if Way.WantsWay() then
        SLASH_WLHWAY2 = "/way"
        if hash then
            if hash["/WAY"] ~= fn then before = hash["/WAY"] end
            -- the chat box reads this table: set it so /way is ours whatever order the lists merged in
            hash["/WAY"] = fn
        end
        owned = true
    else
        SLASH_WLHWAY2 = nil
        if hash and hash["/WAY"] == fn then
            local other = Way.OtherOwner()
            hash["/WAY"] = before or (other and SlashCmdList[other]) or nil
        end
        owned = false
    end
end

-- For the Settings switch "Prendre /way".
function Way.SetTake(on)
    WLWritsDB = WLWritsDB or {}
    WLWritsDB.wayTake = on and true or false
    Way.Apply()
end

-- TomTom and the others register /way while loading: decide once everything is in, a moment after login.
local f = CreateFrame("Frame")
pcall(f.RegisterEvent, f, "PLAYER_LOGIN")
f:SetScript("OnEvent", function()
    if C_Timer and C_Timer.After then C_Timer.After(3, function() pcall(Way.Apply) end) else pcall(Way.Apply) end
end)
-- Stopped from the arrow's close button or elsewhere: our pin goes with it.
if type(hooksecurefunc) == "function" and WP.GPS and WP.GPS.Stop then
    hooksecurefunc(WP.GPS, "Stop", function() if not Mine() then StopWatch(); ClearPin() end end)
end
