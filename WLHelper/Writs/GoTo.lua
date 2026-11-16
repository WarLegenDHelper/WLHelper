-- Writs/GoTo.lua: "Aller à..." / "Go to...". A search box where a lost player types where they want to
-- go: a city service ("banque", "HV", "boîte aux lettres", "maître de vol", "maître de classe", a
-- profession trainer), a dungeon entrance, a zone, a quest or an NPC of the guide (ns.Q), or any NPC
-- LibForeverData knows. Up to 8 results, accent-insensitive, French and English names alike.
-- A click starts WL Helper's own GPS (WP.GPS, source "goto"): the flights, boats and teleports it plans
-- stay in charge of long trips. For a trip on foot, when the walking router (the separate GPL addon
-- WLHelper_Nav, load on demand) is installed, it is loaded out of combat and asked for a real path round
-- hills and through gates; the arrow then follows that trail one corner at a time (the GPS has no
-- "via" list, so this file moves its target to the next corner once you are within 20 yards).
-- Without the router, the arrow points straight at the place.
-- While the window is open, the list follows you: every half second, once you walked a few yards, each
-- result is measured again and a service or an NPC moves to its nearest place (another bank, another
-- flight master) among the places read when the list was made (no new search); the rows are sorted
-- again only when their order changed.
--
-- Services are found in LibForeverData (an optional dependency) by the NPC's title ("Banker",
-- "Gryphon Master"...): its 13,000 NPCs are read once, a few milliseconds a frame, the first time the
-- window opens or a search runs. Without it, the flight masters the GPS learnt still work, and so do
-- the dungeons, zones and the guide's own NPCs.
--
-- WP.GoTo.Show(text), WP.GoTo.Search(text) -> results (no side effect but the lazy index),
-- WP.GoTo.Go(result). Saved: WLWritsDB.gotoPos (window), WLWritsDB.gotoWalk (false: no walking
-- router), WLWritsCharDB.gotoRecent (the last 3 places).
local ADDON, root = ...
root.Writs = root.Writs or {}
local ns = root.Writs
local WP = ns.WP
local L = ns.L
local S = ns.S
local C = S.C
local F = S.F
local GPS = WP.GPS

local GoTo = {}
WP.GoTo = GoTo

ns.AddEnglish({
    ["Aller à"] = "Go to",
    ["Tape un lieu, un service ou un PNJ : la flèche t'y emmène."] = "Type a place, a service or an NPC: the arrow takes you there.",
    ["Ex. banque, HV, Mortemines, Forgefer"] = "E.g. bank, AH, Deadmines, Ironforge",
    ["Aucun lieu trouvé"] = "No place found",
    ["Essaie un autre mot : une zone, un donjon, un PNJ ou « banque »."] = "Try another word: a zone, a dungeon, an NPC or \"bank\".",
    ["La liste complète des PNJ n'est pas chargée : seuls les donjons, les zones, les PNJ du guide et tes maîtres de vol sont connus."] =
        "The full NPC list isn't loaded: only dungeons, zones, the guide's NPCs and your flight masters are known.",
    ["Tape au moins 2 lettres."] = "Type at least 2 letters.",
    ["Derniers lieux"] = "Recent places",
    ["Services les plus proches"] = "Nearest services",
    ["Clic : y aller avec le GPS"] = "Click: go there with the GPS",
    ["Entrée : aller au premier résultat"] = "Enter: go to the first result",
    ["Chemins à pied par WL Helper Nav."] = "Walking paths by WL Helper Nav.",
    ["Sans WL Helper Nav, la flèche va tout droit."] = "Without WL Helper Nav, the arrow points straight there.",
    ["Chargement des PNJ : %d %%"] = "Loading NPCs: %d%%",
    -- the kinds of places, in the detail line
    ["Le plus proche : %s"] = "Nearest: %s",
    ["Maître de métier le plus proche : %s"] = "Nearest trainer: %s",
    ["Entrée de donjon · %s"] = "Dungeon entrance · %s",
    ["Entrée de donjon"] = "Dungeon entrance",
    ["Zone · centre de la carte"] = "Zone · middle of the map",
    ["Pour prendre la quête : %s"] = "To pick up the quest: %s",
    ["Pour rendre la quête : %s"] = "To turn in the quest: %s",
    ["PNJ du guide · %s"] = "Guide NPC · %s",
    ["PNJ · %s"] = "NPC · %s",
    ["%s, %s"] = "%s, %s",
    -- the services
    ["Banque"] = "Bank",
    ["Hôtel des ventes"] = "Auction house",
    ["Boîte aux lettres"] = "Mailbox",
    ["Maître de vol"] = "Flight master",
    ["Auberge"] = "Inn",
    ["Maître de classe"] = "Class trainer",
    ["Maître des écuries"] = "Stable master",
    ["Maître d'armes"] = "Weapon master",
    ["Alchimie"] = "Alchemy",
    ["Forge"] = "Blacksmithing",
    ["Travail du cuir"] = "Leatherworking",
    ["Couture"] = "Tailoring",
    ["Ingénierie"] = "Engineering",
    ["Enchantement"] = "Enchanting",
    ["Cuisine"] = "Cooking",
    ["Pêche"] = "Fishing",
    ["Secourisme"] = "First aid",
    ["Minage"] = "Mining",
    ["Herboristerie"] = "Herbalism",
    ["Dépeçage"] = "Skinning",
    -- chat
    ["GPS : en route vers %s."] = "GPS: on the way to %s.",
    ["Tu y es : %s."] = "You're there: %s.",
    ["Impossible de guider vers ce point : la carte de cette zone n'est pas lisible."] = "Can't guide you there: this zone's map can't be read.",
    -- the setting (Settings > GPS)
    ["Chemins à pied"] = "Walking paths",
    ["Pour « Aller à », la flèche suit un vrai chemin autour des collines et par les portes (WL Helper Nav). Sans lui, elle va tout droit."] =
        "For \"Go to\", the arrow follows a real path round hills and through gates (WL Helper Nav). Without it, it points straight there.",
})

local W = 420                 -- a single list (design system: 420)
local INSET = 16
local CW = W - 2 * INSET
local MAX = 8                 -- results shown
local RECENT_MAX = 3
local ADVANCE = 20            -- yards: next corner of the trail (the GPS says "you're here" at 15)
local THIN = 12               -- yards: corners closer than this to the previous one are dropped
local OFF_TRAIL = 40          -- yards farther than your best: the path is asked again
local NAV_ADDON = "WLHelper_Nav"

local function IsSecret(v) return issecretvalue ~= nil and issecretvalue(v) end
local function Num(v) if type(v) == "number" and not IsSecret(v) then return v end end
local function InCombat() return InCombatLockdown and InCombatLockdown() and true or false end
local function Safe(f, ...)
    if type(f) ~= "function" then return nil end
    local ok, a, b, c, d = pcall(f, ...)
    if ok then return a, b, c, d end
end

-- ---------------------------------------------------------------- names, folded

-- Accents, case and punctuation do not count: "Forêt", "foret" and "FORET" are the same word, and
-- "Zul'Farrak" is found by "zul farrak" and by "zulfarrak". The accents table is Way.lua's (one copy).
local FOLD = (WP.Way and WP.Way.FOLD) or {}
local function Norm(s)
    if type(s) ~= "string" or IsSecret(s) then return "" end
    s = s:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    s = s:gsub("[\192-\223][\128-\191]", function(c) return FOLD[c] or " " end)
    s = s:gsub("[\224-\239][\128-\191][\128-\191]", " "):gsub("[\240-\247][\128-\191][\128-\191][\128-\191]", " ")
    s = s:lower():gsub("[^%w]+", " ")
    return (s:gsub("^ +", ""):gsub(" +$", ""))
end
GoTo.Norm = Norm

local function Key(s)
    local n = Norm(s)
    if n == "" then return nil end
    return { norm = n, compact = n:gsub(" ", "") }
end

local function Query(text)
    local n = Norm(text)
    if #n < 2 then return nil end
    local q = { norm = n, compact = n:gsub(" ", ""), tokens = {} }
    for t in n:gmatch("%S+") do q.tokens[#q.tokens + 1] = t end
    return q
end

-- How well a name answers the query (nil: not at all). `n` is the folded name, `compact` the same
-- without spaces (nil for the long NPC list, where the spaced name does both jobs).
local function Score(q, n, compact)
    if n == q.norm then return 100 end
    if n:sub(1, #q.norm) == q.norm then return 85 end
    if (" " .. n):find(" " .. q.norm, 1, true) then return 70 end
    if #q.compact >= 3 and (compact or n):find(compact and q.compact or q.norm, 1, true) then return 50 end
    if #q.tokens > 1 then
        local spaced = " " .. n
        for _, t in ipairs(q.tokens) do
            if not spaced:find(" " .. t, 1, true) then return nil end
        end
        return 45
    end
end
local function BestScore(q, keys)
    local best
    for _, k in ipairs(keys) do
        local s = Score(q, k.norm, k.compact)
        if s and (not best or s > best) then best = s end
    end
    return best
end
GoTo.Score = function(text, name)
    local q, k = Query(text), Key(name)
    return q and k and Score(q, k.norm, k.compact) or nil
end

-- A small lift by kind, so "banque" shows the bank before an NPC called "Banque..."
local BONUS = { service = 6, dungeon = 4, zone = 4, giver = 3, quest = 1, npc = 0, taxi = 2 }

-- ---------------------------------------------------------------- where you are, how far

local function Lib()
    local lib = rawget(_G, "LibForeverData")
    if type(lib) == "table" and type(lib.Get) == "function" and type(lib.Ids) == "function" and type(lib.Spawns) == "function" then
        return lib
    end
end

-- The player in world yards (C_Map.GetWorldPosFromMapPos's frame, the one LibForeverData's spawns and
-- the walking router use): continent, x, y. Nil inside an instance or when the client hides it.
local function Here()
    local map = Safe(C_Map and C_Map.GetBestMapForUnit, "player")
    if not Num(map) then return nil end
    local pos = Safe(C_Map.GetPlayerMapPosition, map, "player")
    if not (pos and pos.GetXY) then return nil end
    local ok, x, y = pcall(pos.GetXY, pos)
    x, y = ok and Num(x), ok and Num(y)
    if not (x and y) or (x == 0 and y == 0) then return nil end
    local p = GPS.Point(map, x * 100, y * 100)
    if p then return { cont = p.cont, wx = p.wx, wy = p.wy, map = map } end
end
GoTo.Here = Here

-- World position of a map point, kept on the entry (a fixed point never moves).
local function WorldOf(e)
    if e.wp == nil then e.wp = GPS.Point(e.map, e.x, e.y) or false end
    return e.wp or nil
end
local function DistTo(here, cont, wx, wy)
    if here and cont and here.cont == cont then
        local dx, dy = here.wx - wx, here.wy - wy
        return math.sqrt(dx * dx + dy * dy)
    end
end

local function Faction()
    local f = Safe(UnitFactionGroup, "player")
    if IsSecret(f) then return nil end
    return (f == "Alliance" or f == "Horde") and f or nil
end
local function ClassToken()
    local _, c = Safe(UnitClass, "player")
    if IsSecret(c) then return nil end
    return c
end

-- NPC faction templates (FactionTemplate) that only one side may use: the capitals, their flight
-- masters and the outposts. Everything else (goblin towns, Cenarion Circle, Forever's new towns) is
-- open to both.
local SIDE_OF_TEMPLATE = {
    [11] = "Alliance", [12] = "Alliance", [55] = "Alliance", [57] = "Alliance", [79] = "Alliance", [80] = "Alliance",
    [84] = "Alliance", [123] = "Alliance", [210] = "Alliance", [534] = "Alliance", [694] = "Alliance", [875] = "Alliance",
    [894] = "Alliance", [1054] = "Alliance", [1078] = "Alliance", [1216] = "Alliance",
    [29] = "Horde", [68] = "Horde", [71] = "Horde", [83] = "Horde", [85] = "Horde", [104] = "Horde", [105] = "Horde",
    [106] = "Horde", [118] = "Horde", [126] = "Horde", [876] = "Horde", [1214] = "Horde",
    [1494] = "Horde",   -- Revantusk Village (the Hinterlands)
}
-- Some templates are shared by both sides (Moonglade's flight masters: 994). Their title then says
-- which capital they serve: "Thunder Bluff Flight Master", "Darnassus Flight Master".
local SIDE_OF_CAPITAL = {
    { "^Stormwind ", "Alliance" }, { "^Ironforge ", "Alliance" }, { "^Darnassus ", "Alliance" },
    { "^Orgrimmar ", "Horde" }, { "^Thunder Bluff ", "Horde" }, { "^Undercity ", "Horde" },
}
local function Friendly(ft, side, sub)
    local s = ft and SIDE_OF_TEMPLATE[ft]
    if not s and type(sub) == "string" then
        for _, c in ipairs(SIDE_OF_CAPITAL) do
            if sub:find(c[1]) then s = c[2]; break end
        end
    end
    return not (s and side and s ~= side)
end
GoTo.Friendly = Friendly

-- ---------------------------------------------------------------- the services

-- words: what a player may type (folded, both languages); sub: the NPC's title in LibForeverData
-- (English); name: a name pattern (auctioneers have no title). prof: a profession trainer.
local SERVICES = {
    { key = "bank", label = "Banque", words = { "banque", "banquier", "banquiere", "bank", "banker" }, sub = { "^Banker$" } },
    { key = "ah", label = "Hôtel des ventes", words = { "hotel des ventes", "hv", "encheres", "commissaire priseur",
        "auction house", "auction", "ah", "auctioneer" }, sub = { "^Auctioneer$" }, name = { "^Auctioneer " } },
    { key = "mail", label = "Boîte aux lettres", words = { "boite aux lettres", "bal", "courrier", "poste", "mailbox", "mail" },
        object = "Mailbox" },
    { key = "flight", label = "Maître de vol", words = { "maitre de vol", "vol", "griffon", "coursier du vent", "hippogriffe",
        "chauve souris", "flight master", "flight", "gryphon", "wind rider", "hippogryph", "bat handler", "taxi" },
        sub = { "Flight Master$", "^Gryphon Master$", "^Wind Rider Master$", "^Hippogryph Master$", "^Bat Handler$" }, taxi = true },
    { key = "inn", label = "Auberge", words = { "auberge", "aubergiste", "taverne", "pierre de foyer", "inn", "innkeeper",
        "tavern", "hearthstone" }, sub = { "^Innkeeper$" } },
    { key = "class", label = "Maître de classe", words = { "maitre de classe", "entraineur de classe", "sorts", "class trainer",
        "trainer", "spells" }, class = true },
    { key = "stable", label = "Maître des écuries", words = { "maitre des ecuries", "ecuries", "ecurie", "stable master", "stable" },
        sub = { "^Stable Master$" } },
    { key = "weapon", label = "Maître d'armes", words = { "maitre d armes", "armes", "weapon master", "weapon skills" },
        sub = { "^Weapon Master$" } },
    { key = "alchemy", label = "Alchimie", prof = true, words = { "alchimie", "alchimiste", "alchemy", "alchemist" },
        sub = { "Alchemist$", "^Alchemy Trainer$" } },
    { key = "blacksmith", label = "Forge", prof = true, words = { "forge", "forgeron", "blacksmithing", "blacksmith" },
        sub = { "Blacksmith$", "^Blacksmithing Trainer$" } },
    { key = "leather", label = "Travail du cuir", prof = true, words = { "travail du cuir", "travailleur du cuir", "cuir",
        "leatherworking", "leatherworker" }, sub = { "Leatherworker$", "^Leatherworking Trainer$" } },
    { key = "tailor", label = "Couture", prof = true, words = { "couture", "tailleur", "tailoring", "tailor" },
        sub = { "Tailor$", "^Tailoring Trainer$" } },
    { key = "engineer", label = "Ingénierie", prof = true, words = { "ingenierie", "ingenieur", "engineering", "engineer" },
        sub = { "Engineer$", "^Engineering Trainer$" } },
    { key = "enchant", label = "Enchantement", prof = true, words = { "enchantement", "enchanteur", "enchanting", "enchanter" },
        sub = { "Enchanter$", "^Enchanting Trainer$" } },
    { key = "cooking", label = "Cuisine", prof = true, words = { "cuisine", "cuisinier", "cooking", "cook" }, sub = { "^Cooking Trainer$" } },
    { key = "fishing", label = "Pêche", prof = true, words = { "peche", "pecheur", "fishing", "fisherman" }, sub = { "^Fishing Trainer$" } },
    { key = "firstaid", label = "Secourisme", prof = true, words = { "secourisme", "bandages", "first aid" }, sub = { "^First Aid Trainer$" } },
    { key = "mining", label = "Minage", prof = true, words = { "minage", "mineur", "mining", "miner" }, sub = { "^Mining Trainer$" } },
    { key = "herbalism", label = "Herboristerie", prof = true, words = { "herboristerie", "herboriste", "herbalism", "herbalist" },
        sub = { "^Herbalism Trainer$" } },
    { key = "skinning", label = "Dépeçage", prof = true, words = { "depecage", "depeceur", "skinning", "skinner" },
        sub = { "^Skinning Trainer$" } },
}
local SERVICE = {}
for _, s in ipairs(SERVICES) do
    SERVICE[s.key] = s
    s.keys = {}
    for _, w in ipairs(s.words) do s.keys[#s.keys + 1] = Key(w) end
    s.keys[#s.keys + 1] = Key(s.label)
    s.cands = {}           -- { kind = "npc" | "object", id, ft }, filled by the index
end
-- The services the empty box offers, in this order.
local START = { "bank", "ah", "mail", "flight", "class", "inn" }
-- A class trainer's English title per class token.
local CLASS_EN = { WARRIOR = "Warrior", PALADIN = "Paladin", HUNTER = "Hunter", ROGUE = "Rogue", PRIEST = "Priest",
    SHAMAN = "Shaman", MAGE = "Mage", WARLOCK = "Warlock", DRUID = "Druid" }
local classCands = {}      -- English class -> { cand, ... }

-- ---------------------------------------------------------------- the NPC index (LibForeverData)

-- Names that are no place to go: test, GM ("World Banker", "World Stable Master") and placeholder NPCs.
local function Junk(name)
    return name:find("^Test ") or name:find("^World ") or name:find("DEBUG") or name:find("PH>", 1, true) or name:find("[PH]", 1, true)
        or name:find("^%[") or name:find("Trigger") or name:find("Bunny") or name:find("Invisible")
end

local idx = { id = {}, name = {}, norm = {}, sub = {}, ft = {} }
local index = { state = nil, at = 1, objAt = 1 }   -- state nil | "building" | "done" | "none"

local function AddCand(list, c)
    list[#list + 1] = c
end

local function IndexNpc(lib, id)
    local rec = lib.Get("npc", id)
    local name = rec and rec.name
    if type(name) ~= "string" or not rec.spawns or Junk(name) then return end
    local n = #idx.id + 1
    idx.id[n], idx.name[n], idx.norm[n], idx.sub[n], idx.ft[n] = id, name, Norm(name), rec.subName, rec.factionTemplate
    local sub = rec.subName
    for _, s in ipairs(SERVICES) do
        local hit = false
        if sub and s.sub then
            for _, p in ipairs(s.sub) do if sub:find(p) then hit = true; break end end
        end
        if not hit and s.name then
            for _, p in ipairs(s.name) do if name:find(p) then hit = true; break end end
        end
        if hit then AddCand(s.cands, { kind = "npc", id = id, ft = rec.factionTemplate, name = name, sub = sub }) end
    end
    local cls = sub and sub:match("^(%u%l+) Trainer$")
    if cls then
        classCands[cls] = classCands[cls] or {}
        AddCand(classCands[cls], { kind = "npc", id = id, ft = rec.factionTemplate, name = name, sub = sub })
    end
end

-- One slice of the index: a few milliseconds (or 150 records where the clock is missing).
local BUDGET_MS = 4
local function IndexStep()
    local lib = Lib()
    if not lib then index.state = "none"; return true end
    if not index.npcs then
        index.npcs = lib.Ids("npc") or {}
        index.objs = lib.Ids("object") or {}
    end
    local clock = type(debugprofilestop) == "function" and debugprofilestop or nil
    local stop = clock and (clock() + BUDGET_MS)
    local count = 0
    local npcs, objs = index.npcs, index.objs
    while index.at <= #npcs or index.objAt <= #objs do
        if index.at <= #npcs then
            pcall(IndexNpc, lib, npcs[index.at])
            index.at = index.at + 1
        else
            local id = objs[index.objAt]
            index.objAt = index.objAt + 1
            local ok, name = pcall(lib.Name, "object", id)
            if ok and name == SERVICE.mail.object then AddCand(SERVICE.mail.cands, { kind = "object", id = id, name = name }) end
        end
        count = count + 1
        if clock then
            if count % 25 == 0 and clock() >= stop then break end
        elseif count >= 150 then break end
    end
    if index.at > #npcs and index.objAt > #objs then
        index.state = "done"
        index.npcs, index.objs = nil, nil
        return true
    end
    return false
end

local builder = CreateFrame("Frame")
builder:Hide()
local function IndexDone()
    builder:Hide()
    if GoTo.OnIndexed then GoTo.OnIndexed() end
end
local shownAt = 0
builder:SetScript("OnUpdate", function()
    -- a fight gets the whole frame
    if InCombat() then return end
    if IndexStep() then IndexDone(); return end
    -- the footer's "Reading NPCs: 40%", twice a second
    local t = GetTime and GetTime() or 0
    if GoTo.OnIndexStep and t - shownAt > 0.5 then shownAt = t; GoTo.OnIndexStep() end
end)

local function StartIndex()
    if index.state then return end
    if not Lib() then index.state = "none"; return end
    index.state = "building"
    builder:Show()
end
GoTo.StartIndex = StartIndex

-- Index progress, 0 to 100 (nil when there is nothing to read).
function GoTo.IndexProgress()
    if index.state ~= "building" then return nil end
    local total = (index.npcs and #index.npcs or 0) + (index.objs and #index.objs or 0)
    if total == 0 then return 0 end
    return math.floor(((index.at - 1) + (index.objAt - 1)) * 100 / total)
end

-- For the tests: the whole index at once.
function GoTo._IndexAll()
    StartIndex()
    while index.state == "building" do if IndexStep() then IndexDone() end end
end

-- ---------------------------------------------------------------- fixed places (the addon's data)

local static   -- { entry, ... } built on the first search
local guideNames = {}   -- folded names of the guide's NPCs: LibForeverData's copy is not shown twice

-- English and French names of the zones (the client adds its own name too): Way.lua's table, the
-- addon's one copy, without the two continents (a continent's middle is no place to go).
local ZONES = {}
for id, names in pairs(WP.Way and WP.Way.ZONES or {}) do
    if id ~= 1414 and id ~= 1415 then ZONES[id] = names end
end
ZONES[2548] = { "Riverglades" }
-- Forever's own zones the client may name (no French name of ours yet).
local EXTRA_ZONES = { 2482, 2521, 2652 }

-- A zone's name as the game writes it (proper names follow the client's language, as the guide's
-- do), else ours.
local zoneLabels = {}
local function ZoneLabel(map)
    if not map then return nil end
    local n = zoneLabels[map]
    if n ~= nil then return n or nil end
    local info = Safe(C_Map and C_Map.GetMapInfo, map)
    n = info and type(info.name) == "string" and not IsSecret(info.name) and info.name ~= "" and info.name or nil
    local z = ZONES[map]
    if not n and z then n = (Safe(GetLocale) == "frFR" and z[2]) or z[1] end
    zoneLabels[map] = n or false
    return n
end

-- A place's names as search keys; "The Barrens" and "Les Tarides" also without their article, so
-- "barrens" or "tarides" is an exact match.
local ARTICLE = { "the ", "les ", "le ", "la ", "l " }
local function AddKeys(e, ...)
    e.keys = e.keys or {}
    local function put(k)
        if not k then return end
        for _, o in ipairs(e.keys) do if o.norm == k.norm then return end end
        e.keys[#e.keys + 1] = k
    end
    for i = 1, select("#", ...) do
        local k = Key((select(i, ...)))
        put(k)
        if k and e.kind ~= "quest" then
            for _, a in ipairs(ARTICLE) do
                if k.norm:sub(1, #a) == a and #k.norm > #a + 2 then put(Key(k.norm:sub(#a + 1))); break end
            end
        end
    end
end

local function BuildStatic()
    if static then return end
    static = {}
    local side, class = Faction(), ClassToken()
    -- dungeons and raids: their entrance
    for key, d in pairs(root.D or {}) do
        local e = d.e
        if type(e) == "table" and e.m and e.x and e.y then
            local label = root.DName and root.DName(key) or (ns.English() and d.n) or d.nf or d.n or key
            local where = ns.English() and d.loc or (d.locf or d.loc)
            local entry = { kind = "dungeon", label = label, map = e.m, x = e.x, y = e.y, icon = d.icon,
                detail = where and string.format(L("Entrée de donjon · %s"), where) or L("Entrée de donjon"), gps = label }
            AddKeys(entry, d.n, d.nf, d.short, label)
            static[#static + 1] = entry
        end
    end
    -- zones: the middle of their map
    local zoneIds = {}
    for id in pairs(ZONES) do zoneIds[#zoneIds + 1] = id end
    for _, id in ipairs(EXTRA_ZONES) do if not ZONES[id] then zoneIds[#zoneIds + 1] = id end end
    for _, id in ipairs(zoneIds) do
        local label = ZoneLabel(id)
        if label then
            local z = ZONES[id] or {}
            local entry = { kind = "zone", label = label, map = id, x = 50, y = 50, detail = L("Zone · centre de la carte"), gps = label }
            AddKeys(entry, z[1], z[2], label)
            static[#static + 1] = entry
        end
    end
    -- the guide's quests (picked up, turned in) and its NPCs, for your side and class
    local seen = {}
    for qid, q in pairs(root.Q or {}) do
        local mine = (not q.fa or q.fa == "Both" or not side or q.fa == side) and (not q.c or not class or q.c == class)
        if mine then
            local title = root.QName and root.QName(qid) or q.nf or q.n
            for _, end_ in ipairs({ { p = q.s, how = "Pour prendre la quête : %s" }, { p = q.f, how = "Pour rendre la quête : %s" } }) do
                local p = end_.p
                if type(p) == "table" and p.m and p.x and p.y and p.n then
                    local zone = ZoneLabel(p.m)
                    local where = zone and string.format(L("%s, %s"), p.n, zone) or p.n
                    local qe = { kind = "quest", label = title, map = p.m, x = p.x, y = p.y, gps = p.n,
                        detail = string.format(L(end_.how), where) }
                    AddKeys(qe, q.n, q.nf)
                    static[#static + 1] = qe
                    -- the NPC itself, once per place
                    local k = Norm(p.n) .. "@" .. p.m .. ":" .. math.floor(p.x) .. ":" .. math.floor(p.y)
                    if not seen[k] then
                        seen[k] = true
                        local ne = { kind = "giver", label = p.n, map = p.m, x = p.x, y = p.y, gps = p.n,
                            detail = string.format(L("PNJ du guide · %s"), zone or "?") }
                        AddKeys(ne, p.n)
                        static[#static + 1] = ne
                        guideNames[Norm(p.n)] = true
                    end
                end
            end
        end
    end
end
-- For the tests: the places are read again (another faction or class).
function GoTo._Reset() static = nil; guideNames = {} end

-- ---------------------------------------------------------------- nearest spawn and service

-- The spawn of an NPC or object nearest to you: map, x, y (percent), distance (nil on another
-- continent). On another continent (or with no position) its first spawn that lies on a map.
-- A world point as a point of `map` (percent), when the map holds it. Map rectangles overlap at
-- zone borders, and LibForeverData's ToUiMap picks the smallest one: the player's own zone reads better.
local corners = {}
local function OnMap(map, cont, wx, wy)
    if not map then return nil end
    local c = corners[map]
    if c == nil then
        local a, b = GPS.Point(map, 0, 0), GPS.Point(map, 100, 100)
        c = (a and b and a.cont == b.cont and a.wx ~= b.wx and a.wy ~= b.wy) and { cont = a.cont, a = a, b = b } or false
        corners[map] = c
    end
    if not c or c.cont ~= cont then return nil end
    local x = (wy - c.a.wy) / (c.b.wy - c.a.wy) * 100
    local y = (wx - c.a.wx) / (c.b.wx - c.a.wx) * 100
    if x >= 0 and x <= 100 and y >= 0 and y <= 100 then return x, y end
end

local function MapPoint(lib, here, cont, wx, wy)
    local x, y = OnMap(here and here.map, cont, wx, wy)
    if x then return here.map, x, y end
    return Safe(lib.ToUiMap, cont, wx, wy)
end

-- Every spawn of an NPC or object as a world point { cont, wx, wy, who }, added to `into`. A result
-- keeps these points: the window picks the nearest again as you walk, without asking the library.
local function SpawnPoints(lib, kind, id, who, into)
    into = into or {}
    local ok, list = pcall(lib.Spawns, kind, id)
    if ok and type(list) == "table" then
        for _, s in ipairs(list) do
            if s.map and s.x and s.y then into[#into + 1] = { cont = s.map, wx = s.x, wy = s.y, who = who } end
        end
    end
    return into
end

-- The point of `pts` nearest to you that lies on a map: point, distance, map, x, y (percent). Nil when
-- none is on your continent. A point that no map holds is set aside (p.off) and never measured again;
-- a point that brings its own map point (a flight master the GPS learnt) is taken as it is.
local function Nearest(pts, here, lib)
    if not (here and pts) then return nil end
    while true do
        local best, bestD
        for _, p in ipairs(pts) do
            if not p.off then
                local d = DistTo(here, p.cont, p.wx, p.wy)
                if d and (not bestD or d < bestD) then best, bestD = p, d end
            end
        end
        if not best then return nil end
        if best.map then return best, bestD, best.map, best.x, best.y end
        local m, x, y
        if lib then m, x, y = MapPoint(lib, here, best.cont, best.wx, best.wy) end
        if m then return best, bestD, m, x, y end
        best.off = true
    end
end

-- The spawn of an NPC or object nearest to you: { map, x, y (percent), dist, pt }, and all its points.
-- On another continent (or with no position) its first spawn that lies on a map, without a distance.
local function NearestSpawn(lib, kind, id, here)
    local pts = SpawnPoints(lib, kind, id)
    local p, d, m, x, y = Nearest(pts, here, lib)
    if p then return { map = m, x = x, y = y, dist = d, pt = p }, pts end
    for _, q in ipairs(pts) do
        m, x, y = Safe(lib.ToUiMap, q.cont, q.wx, q.wy)
        if m then return { map = m, x = x, y = y }, pts end
    end
end

local function ServiceDetail(svc, who, map)
    local zone = ZoneLabel(map)
    -- a mailbox has no name of its own: the zone alone
    local where = (who and zone and string.format(L("%s, %s"), who, zone)) or zone or who or "?"
    if svc.prof then return string.format(L("Maître de métier le plus proche : %s"), where) end
    return string.format(L("Le plus proche : %s"), where)
end

-- Every place giving a service and open to your side, on any continent, as world points: the spawns
-- of its NPCs (or mailboxes) in LibForeverData, then the flight masters the GPS learnt
-- (WLWritsCharDB.taxi), known even without LibForeverData.
local function ServicePoints(svc)
    local lib = Lib()
    local side = Faction()
    local pts = {}
    local cands = svc.cands
    if svc.class then
        local en = CLASS_EN[ClassToken() or ""]
        cands = en and classCands[en] or {}
    end
    if lib then
        for _, c in ipairs(cands) do
            if Friendly(c.ft, side, c.sub) then SpawnPoints(lib, c.kind, c.id, c.kind ~= "object" and c.name or nil, pts) end
        end
    end
    if svc.taxi and WLWritsCharDB and type(WLWritsCharDB.taxi) == "table" then
        for _, t in pairs(WLWritsCharDB.taxi) do
            if type(t) == "table" and t.map and t.x and t.y then
                t.wp = t.wp or GPS.Point(t.map, t.x, t.y)
                local p = t.wp
                if p then pts[#pts + 1] = { cont = p.cont, wx = p.wx, wy = p.wy, map = t.map, x = t.x, y = t.y, taxi = t.name or "?" } end
            end
        end
    end
    return pts
end

-- A service result at one of its places: where, how far, what the arrow and the detail line say.
local function ServicePlace(r, svc, p, d, m, x, y)
    r.map, r.x, r.y, r.dist, r.pt = m, x, y, d, p
    if p.taxi then
        r.gps, r.detail = GPS.ShortPlace(p.taxi), string.format(L("Le plus proche : %s"), p.taxi)
    else
        r.gps, r.detail = p.who or L(svc.label), ServiceDetail(svc, p.who, m)
    end
end

-- The nearest place giving a service, on your continent and open to your side. Nil when unknown.
-- The result keeps all the places (r.pts) for the window to pick the nearest again as you walk.
local function ResolveService(svc, here)
    if not here then return nil end
    local pts = ServicePoints(svc)
    local p, d, m, x, y = Nearest(pts, here, Lib())
    if not p then return nil end
    local r = { kind = "service", svc = svc.key, label = L(svc.label), pts = pts }
    ServicePlace(r, svc, p, d, m, x, y)
    return r
end

-- An NPC's detail line: its title and the zone of the spawn shown.
local function NpcDetail(sub, map)
    local zone = ZoneLabel(map)
    local what = sub and (zone and string.format(L("%s, %s"), sub, zone) or sub) or (zone or "?")
    return string.format(L("PNJ · %s"), what)
end
GoTo.ResolveService = function(key) local s = SERVICE[key]; return s and ResolveService(s, Here()) end

-- ---------------------------------------------------------------- search

local function Copy(e, here)
    local r = { kind = e.kind, label = e.label, detail = e.detail, map = e.map, x = e.x, y = e.y, gps = e.gps, icon = e.icon }
    local p = WorldOf(e)
    r.wp = p
    r.dist = p and DistTo(here, p.cont, p.wx, p.wy) or nil
    return r
end

local function Better(a, b)
    if a.score ~= b.score then return a.score > b.score end
    if (a.dist ~= nil) ~= (b.dist ~= nil) then return a.dist ~= nil end
    if a.dist and b.dist and a.dist ~= b.dist then return a.dist < b.dist end
    return (a.label or "") < (b.label or "")
end

-- The places that answer `text`, best first (at most 8). Each result: kind ("service", "dungeon",
-- "zone", "quest", "giver", "npc"), label, detail, map, x, y (percent), dist (yards, nil when on
-- another continent or unknown), gps (the name the arrow shows), svc (a service's key).
function GoTo.Search(text)
    local q = Query(text)
    if not q then return {} end
    BuildStatic()
    StartIndex()
    local here = Here()
    local out, seen = {}, {}
    local function add(r, score)
        if not (r and r.map and r.x and r.y) then return end
        local k = (r.label or "") .. "@" .. r.map .. ":" .. math.floor(r.x + 0.5) .. ":" .. math.floor(r.y + 0.5)
        local old = seen[k]
        if old then
            if score > old.score then old.score = score end
            return
        end
        r.score = score
        seen[k] = r
        out[#out + 1] = r
    end
    -- the services
    for _, svc in ipairs(SERVICES) do
        local s = BestScore(q, svc.keys)
        if s then add(ResolveService(svc, here), s + BONUS.service) end
    end
    -- dungeons, zones, the guide's quests and NPCs
    for _, e in ipairs(static) do
        local s = BestScore(q, e.keys)
        if s then add(Copy(e, here), s + BONUS[e.kind]) end
    end
    -- LibForeverData's NPCs: the 40 best names, each at its nearest spawn
    local lib = Lib()
    if lib and #idx.id > 0 then
        local first = q.tokens[1]
        local cands = {}
        local norm = idx.norm
        for i = 1, #idx.id do
            local n = norm[i]
            if n:find(first, 1, true) and not guideNames[n] then
                local s = Score(q, n)
                if s then cands[#cands + 1] = { i = i, s = s } end
            end
        end
        table.sort(cands, function(a, b)
            if a.s ~= b.s then return a.s > b.s end
            return idx.name[a.i] < idx.name[b.i]
        end)
        local names, tried = {}, 0
        for _, c in ipairs(cands) do
            if tried >= 40 then break end
            local i = c.i
            if not names[norm[i]] then
                tried = tried + 1
                local p, pts = NearestSpawn(lib, "npc", idx.id[i], here)
                if p then
                    names[norm[i]] = true
                    local sub = idx.sub[i]
                    add({ kind = "npc", label = idx.name[i], map = p.map, x = p.x, y = p.y, dist = p.dist, gps = idx.name[i],
                        detail = NpcDetail(sub, p.map), sub = sub, pts = pts, pt = p.pt }, c.s + BONUS.npc)
                end
            end
        end
    end
    table.sort(out, Better)
    for i = #out, MAX + 1, -1 do out[i] = nil end
    return out
end

-- A result measured again from `here`: its distance and, for a service or an NPC, the nearest of the
-- places it kept (r.pts). True when it moved to another place (its detail line may name another town).
local function Repick(r, here, lib)
    if r.pts then
        local p, d, m, x, y = Nearest(r.pts, here, lib)
        if not p then r.dist = nil; return false end
        if p == r.pt then r.dist = d; return false end
        if r.kind == "service" and SERVICE[r.svc] then
            ServicePlace(r, SERVICE[r.svc], p, d, m, x, y)
        else
            r.map, r.x, r.y, r.dist, r.pt = m, x, y, d, p
            if r.kind == "npc" then r.detail = NpcDetail(r.sub, m) end
        end
        return true
    elseif r.wp then
        r.dist = DistTo(here, r.wp.cont, r.wp.wx, r.wp.wy)
    end
    return false
end
GoTo.Repick = function(r) return Repick(r, Here(), Lib()) end

-- ---------------------------------------------------------------- the walking router (WLHelper_Nav)

local navTried = false
local function NavInstalled()
    if type(rawget(_G, "WLHelperNav")) == "table" then return true end
    local A = C_AddOns
    local info = A and A.GetAddOnInfo or rawget(_G, "GetAddOnInfo")
    if type(info) ~= "function" then return false end
    local ok, name, _, _, loadable, reason = pcall(info, NAV_ADDON)
    return ok and name ~= nil and reason ~= "MISSING" and (loadable or reason == "DEMAND_LOADED") and true or false
end
GoTo.NavInstalled = NavInstalled

-- The router, loaded on first use. Never in combat: it builds a few MB of strings as it loads.
local function Nav()
    local N = rawget(_G, "WLHelperNav")
    if type(N) == "table" and type(N.WalkTo) == "function" then return N end
    if navTried or InCombat() or not NavInstalled() then return nil end
    -- one try per session: a router that failed to load (disabled, missing part) is not asked again
    navTried = true
    local load = (C_AddOns and C_AddOns.LoadAddOn) or rawget(_G, "LoadAddOn")
    if type(load) ~= "function" then return nil end
    pcall(load, NAV_ADDON)
    N = rawget(_G, "WLHelperNav")
    if type(N) == "table" and type(N.WalkTo) == "function" then return N end
end

function GoTo._ResetNav() navTried = false end

function GoTo.WalkOn() return not (WLWritsDB and WLWritsDB.gotoWalk == false) end
function GoTo.SetWalk(on)
    if WLWritsDB then WLWritsDB.gotoWalk = on and true or false end
    if GoTo.Refresh then GoTo.Refresh() end
end

-- ---------------------------------------------------------------- guiding

-- The trip in progress: dest (the result), trail (corners { map, x, y (percent), wx, wy }), at (the
-- corner the arrow points at), token (a new trip makes older router answers stale).
local trip
local ticker
local token = 0

local function Point(m, x, y, label)
    GPS.GoPoint(m, x, y, label, "goto")
end

local function EndTrip()
    if trip and trip.job then
        local N = rawget(_G, "WLHelperNav")
        if N and N.Cancel then pcall(N.Cancel, trip.job) end
    end
    trip = nil
    if ticker then ticker:Cancel(); ticker = nil end
end

local function RouterHere()
    local N = rawget(_G, "WLHelperNav")
    if N and N.PlayerPosition then
        local c, x, y = Safe(N.PlayerPosition)
        if c and Num(x) and Num(y) then return { cont = c, wx = x, wy = y } end
    end
    return Here()
end

-- Walking only: the GPS's own plan for this trip has no flight, boat or teleport.
local function OnFoot()
    local now = GPS.Now and GPS.Now()
    local legs = now and now.legs
    if not legs then return true end
    for _, leg in ipairs(legs) do if leg.kind ~= "ride" then return false end end
    return true
end

local function Yards(ax, ay, bx, by)
    local dx, dy = ax - bx, ay - by
    return math.sqrt(dx * dx + dy * dy)
end

-- The router's corners as the arrow's targets: the ones you already stand by and the ones a few
-- yards from the previous are dropped; the last (the place itself) always stays.
local function UseTrail(points)
    local here = RouterHere()
    local out, last = {}, nil
    for i, p in ipairs(points) do
        local m, x, y = p[1], Num(p[2]), Num(p[3])
        local wx, wy = Num(p.wx), Num(p.wy)
        if m and x and y and wx and wy then
            local isLast = i == #points
            local nearYou = here and Yards(here.wx, here.wy, wx, wy) < ADVANCE
            local nearLast = last and Yards(last.wx, last.wy, wx, wy) < THIN
            if isLast or not (nearYou or nearLast) then
                last = { map = m, x = x * 100, y = y * 100, wx = wx, wy = wy }
                out[#out + 1] = last
            end
        end
    end
    return out
end

local function TryTrail()
    if not trip or trip.trail or trip.job or not GoTo.WalkOn() then return end
    if GPS.UseZygor and GPS.UseZygor() then return end   -- Zygor finds its own path
    if InCombat() then trip.wantTrail = true; return end
    trip.wantTrail = nil
    if not OnFoot() then return end
    local N = Nav()
    if not N then return end
    local my = token
    trip.askedAt = GetTime and GetTime() or 0
    local d = trip.dest
    local ok, job = pcall(N.WalkTo, d.map, d.x / 100, d.y / 100, function(points)
        if not trip or my ~= token then return end
        trip.job = nil
        if GPS.Source() ~= "goto" or type(points) ~= "table" then return end
        local trail = UseTrail(points)
        if #trail < 2 then return end   -- a straight line: the arrow does it already
        trip.trail, trip.at, trip.best = trail, 1, nil
        local p = trail[1]
        Point(p.map, p.x, p.y, d.gps or d.label)
    end, {})
    if ok and type(job) == "table" then
        job.urgent = true
        if trip and my == token and trip.trail == nil then trip.job = job end
    end
end

local function Arrived()
    if not trip or trip.arrived then return end
    trip.arrived = true
    local d, my = trip.dest, token
    WP.Print(string.format(L("Tu y es : %s."), d.gps or d.label))
    -- the check stays a few seconds, then the arrow goes away by itself
    if C_Timer and C_Timer.After then
        C_Timer.After(6, function()
            if my == token and GPS.Source() == "goto" then GPS.Stop("goto") end
            if my == token then EndTrip() end
        end)
    end
end

-- Four times a second while a trip runs: the next corner when you reach one, a new path when you
-- left it, the end when another guide took the arrow or it was closed.
local function Follow()
    if not trip then return end
    if GPS.Source() ~= "goto" or not GPS.Active() then EndTrip(); return end
    if GPS.UseZygor and GPS.UseZygor() then EndTrip(); return end   -- Zygor took the arrow over
    local now = GPS.Now and GPS.Now()
    local trail = trip.trail
    if not trail then
        if now and now.arrived then Arrived(); return end
        if trip.wantTrail and not InCombat() then TryTrail() end
        return
    end
    local here = RouterHere()
    if not here then return end
    local at = trip.at
    -- any of the next corners within reach (a shortcut skips the ones between)
    local reached
    for j = at, math.min(#trail, at + 6) do
        local p = trail[j]
        local d = DistTo(here, here.cont, p.wx, p.wy)
        if d and d < ADVANCE and j < #trail then reached = j end
    end
    if reached then
        trip.at, trip.best = reached + 1, nil
        local dest = trip.dest
        if trip.at >= #trail then
            -- the last corner is the place itself: the GPS takes it from here, to the exact point
            trip.trail, trip.at = nil, nil
            Point(dest.map, dest.x, dest.y, dest.gps or dest.label)
        else
            local p = trail[trip.at]
            Point(p.map, p.x, p.y, dest.gps or dest.label)
        end
        return
    end
    -- off the path: asked again (not in combat, at most every 10 s)
    local p = trail[at]
    local d = DistTo(here, here.cont, p.wx, p.wy)
    if d then
        trip.best = math.min(trip.best or d, d)
        local t = GetTime and GetTime() or 0
        if d > trip.best + OFF_TRAIL and not InCombat() and t - (trip.askedAt or 0) > 10 then
            trip.trail, trip.at, trip.best = nil, nil, nil
            local dest = trip.dest
            Point(dest.map, dest.x, dest.y, dest.gps or dest.label)
            TryTrail()
        end
    end
end
GoTo._Follow = Follow

local function Remember(r)
    local db = WLWritsCharDB
    if not db then return end
    local list = type(db.gotoRecent) == "table" and db.gotoRecent or {}
    local keep = { { k = r.kind, l = r.label, d = r.detail, m = r.map, x = r.x, y = r.y, g = r.gps, s = r.svc } }
    for _, o in ipairs(list) do
        if type(o) == "table" then
            local same = (r.svc and o.s == r.svc) or (not r.svc and o.l == r.label and o.m == r.map)
            if not same and #keep < RECENT_MAX then keep[#keep + 1] = o end
        end
    end
    db.gotoRecent = keep
end

-- Guides you to a result of GoTo.Search (or a recent place): the GPS arrow now, and the walking
-- path as soon as the router answers.
function GoTo.Go(r)
    if type(r) ~= "table" then return false end
    -- a recent service is found again from where you stand now
    if r.svc and SERVICE[r.svc] then
        StartIndex()
        r = ResolveService(SERVICE[r.svc], Here()) or r
    end
    local map, x, y = Num(r.map), Num(r.x), Num(r.y)
    if not (map and x and y) then return false end
    -- you chose this place: a Writs tour gives the arrow up (the tour's button starts it again)
    if GPS.Source() == "writs" then WP.StopGPS() end
    EndTrip()
    token = token + 1
    local label = r.gps or r.label or "?"
    trip = { dest = { map = map, x = x, y = y, label = r.label, gps = label } }
    Point(map, x, y, label)
    if GPS.Source() ~= "goto" then
        trip = nil
        WP.Print(L("Impossible de guider vers ce point : la carte de cette zone n'est pas lisible."))
        return false
    end
    Remember(r)
    WP.Print(string.format(L("GPS : en route vers %s."), label))
    -- Zygor's arrow took the point: it finds its own path and says its own arrival (our GPS has no
    -- position to read then, so a trip of ours would tick for nothing)
    if GPS.UseZygor and GPS.UseZygor() then trip = nil; return true end
    if C_Timer and C_Timer.NewTicker then ticker = C_Timer.NewTicker(0.25, Follow) end
    TryTrail()
    return true
end

-- The trip now (for the tests and the Home page): nil, or { dest, trail, at }.
function GoTo.Trip() return trip end

-- ---------------------------------------------------------------- the window

local win, rows, heads = nil, {}, {}
local pending
local MOVE = 3             -- yards walked before the list is measured again
local TRACK = 0.5          -- seconds between two looks at where you are
local tracker, trackAt     -- the ticker while the window is shown; where the list was last measured

local function Recents()
    local out = {}
    local list = WLWritsCharDB and WLWritsCharDB.gotoRecent
    if type(list) ~= "table" then return out end
    local here = Here()
    for _, o in ipairs(list) do
        if type(o) == "table" then
            local r
            if o.s and SERVICE[o.s] then r = ResolveService(SERVICE[o.s], here) end
            if not r and Num(o.m) and Num(o.x) and Num(o.y) then
                r = { kind = o.k, label = o.l, detail = o.d, map = o.m, x = o.x, y = o.y, gps = o.g, svc = o.s }
                local p = GPS.Point(o.m, o.x, o.y)
                r.wp = p
                r.dist = p and DistTo(here, p.cont, p.wx, p.wy) or nil
            end
            if r and type(r.label) == "string" then out[#out + 1] = r end
        end
    end
    return out
end

local function RowTip(row)
    local r = row.result
    if not r then return nil end
    local t = { r.label }
    if r.detail and r.detail ~= "" then t[#t + 1] = r.detail end
    t[#t + 1] = L("Clic : y aller avec le GPS")
    return t
end

local function MakeRow(parent)
    local row = S.ListRow(parent, { density = "dense", tip = RowTip, onClick = function(self)
        if self.result and GoTo.Go(self.result) and win then win:Hide() end
    end })
    row.valueW = 64
    return row
end

-- Places the rows (and a section header above each group) in the list; returns the list height.
local function Fill(groups)
    local child = win.list.child
    local y, n, k = 0, 0, 0
    for _, g in ipairs(groups) do
        if #g.items > 0 then
            if g.title then
                k = k + 1
                local h = heads[k] or S.SectionHeader(child, "", nil, nil, nil, true)
                heads[k] = h
                if y > 0 then y = y + 8 end
                h:ClearAllPoints(); h:SetPoint("TOPLEFT", 0, -y); h:SetPoint("TOPRIGHT", 0, -y)
                h:Set(g.title); h:Show()
                y = y + 24 + 4
            end
            for _, r in ipairs(g.items) do
                n = n + 1
                local row = rows[n] or MakeRow(child)
                rows[n] = row
                row.result = r
                row:ClearAllPoints(); row:SetPoint("TOPLEFT", 0, -y); row:SetPoint("TOPRIGHT", 0, -y)
                row:Set({ name = r.label, detail = r.detail, value = r.dist and GPS.Distance(r.dist) or nil })
                row:Show()
                y = y + row:Fit(CW) + 2
            end
        end
    end
    for i = n + 1, #rows do rows[i]:Hide(); rows[i].result = nil end
    for i = k + 1, #heads do heads[i]:Hide() end
    return n > 0 and (y - 2) or 0
end

local function Layout(listH, emptyShown)
    local top = win:ContentTop() + 12
    local y = top
    win.intro:ClearAllPoints(); win.intro:SetPoint("TOPLEFT", INSET, -y)
    y = y + math.ceil(S.FitText(win.intro, 0, CW, win)) + 12
    win.box:ClearAllPoints(); win.box:SetPoint("TOPLEFT", INSET, -y)
    y = y + 28
    if win.box.err:IsShown() then y = y + 4 + 14 end
    local listTop = y + 12
    local content = listTop - top
    if emptyShown then
        win.empty:ClearAllPoints(); win.empty:SetPoint("TOP", win, "TOP", 0, -listTop)
        content = content + win.empty:Fit()
    elseif listH > 0 then
        content = content + listH
    else
        content = content - 12
    end
    local foot = (win.footer and win.footer:IsShown()) and S.FOOTER_H or 0
    win:FitHeight(content)
    win.list:ClearAllPoints()
    win.list:SetPoint("TOPLEFT", INSET, -listTop)
    win.list:SetPoint("BOTTOMRIGHT", -INSET, 12 + foot)
    win.list.child:SetWidth(CW)
    win.list:SetContentHeight(listH)
end

local function Footer()
    local note = GoTo.WalkOn() and (NavInstalled() and L("Chemins à pied par WL Helper Nav.") or L("Sans WL Helper Nav, la flèche va tout droit.")) or ""
    local pct = GoTo.IndexProgress()
    win:SetFooter(note, pct and string.format(L("Chargement des PNJ : %d %%"), pct) or "")
end

local function Render()
    if not win then return end
    local text = win.box:GetText() or ""
    local groups = {}
    local emptyShown = false
    win.box:SetError(nil)
    if Norm(text) == "" then
        local rec = Recents()
        groups[#groups + 1] = { title = L("Derniers lieux"), items = rec }
        local here = Here()
        local svc = {}
        for _, key in ipairs(START) do
            local r = ResolveService(SERVICE[key], here)
            if r then svc[#svc + 1] = r end
        end
        -- always titled: a lost player sees what the list is before reading it
        groups[#groups + 1] = { title = L("Services les plus proches"), items = svc }
    elseif #Norm(text) < 2 then
        win.box:SetError(L("Tape au moins 2 lettres."))
    else
        local res = GoTo.Search(text)
        groups[1] = { items = res, sorted = true }
        if #res == 0 then
            emptyShown = true
            win.empty:Set("search", L("Aucun lieu trouvé"), Lib() and L("Essaie un autre mot : une zone, un donjon, un PNJ ou « banque ».")
                or L("La liste complète des PNJ n'est pas chargée : seuls les donjons, les zones, les PNJ du guide et tes maîtres de vol sont connus."))
        end
    end
    win.empty:SetShown(emptyShown)
    win.groups, win.emptyShown = groups, emptyShown
    trackAt = Here()
    local listH = Fill(emptyShown and {} or groups)
    win.list:SetShown(listH > 0)
    Footer()
    Layout(listH, emptyShown)
end
GoTo.Refresh = function() if win and win:IsShown() then Render() end end

-- The same results placed again (another order, another detail line): no search.
local function Redraw()
    local listH = Fill(win.emptyShown and {} or win.groups or {})
    win.list:SetShown(listH > 0)
    Layout(listH, win.emptyShown)
end

local function StopTrack()
    if tracker then tracker:Cancel(); tracker = nil end
end

-- Twice a second while the window is shown: once you walked MOVE yards, every result is measured
-- again (a service or an NPC may move to a nearer place); the search results are sorted again only
-- when their order changed. When only the distances changed, the rows keep their place.
local function Track()
    if not (win and win:IsShown()) then StopTrack(); return end
    local here = Here()
    if not here then return end
    local a = trackAt
    if a and a.cont == here.cont and Yards(a.wx, a.wy, here.wx, here.wy) < MOVE then return end
    trackAt = here
    local lib = Lib()
    local redo = false
    for _, g in ipairs(win.groups or {}) do
        local items = g.items
        for _, r in ipairs(items) do
            if Repick(r, here, lib) then redo = true end
        end
        if g.sorted then
            local unsorted = false
            for i = 2, #items do
                if Better(items[i], items[i - 1]) then unsorted = true; break end
            end
            if unsorted then table.sort(items, Better); redo = true end
        end
    end
    if not redo then
        for _, row in ipairs(rows) do
            local r = row.result
            if r and row:IsShown() then
                local v = r.dist and GPS.Distance(r.dist) or nil
                -- a distance that appears or goes away changes the row's layout
                if (v ~= nil) ~= (row.value:IsShown() and true or false) then redo = true; break end
                if v then row.value:SetText(v) end
            end
        end
    end
    if redo then Redraw() end
end
GoTo._Track = Track

local function StartTrack()
    if tracker or not (C_Timer and C_Timer.NewTicker) then return end
    tracker = C_Timer.NewTicker(TRACK, Track)
end

-- The list follows the typing, a short moment after the last key.
local function Soon()
    if pending then pending:Cancel(); pending = nil end
    if C_Timer and C_Timer.NewTimer then
        pending = C_Timer.NewTimer(0.15, function() pending = nil; Render() end)
    else
        Render()
    end
end

local function Build()
    win = S.Window("WLHelperGoTo", W, 300, L("Aller à"), nil, WLWritsDB, "gotoPos", { header = S.HEADER_H, footer = true, minH = 160 })
    win.intro = S.Text(win, F.body, C.text)
    win.intro:SetJustifyH("LEFT"); win.intro:SetJustifyV("TOP")
    win.intro:SetText(L("Tape un lieu, un service ou un PNJ : la flèche t'y emmène."))
    win.box = S.Input(win, CW, { search = true, placeholder = L("Ex. banque, HV, Mortemines, Forgefer"),
        onChange = function() Soon() end,
        onEnter = function()
            if pending then pending:Cancel(); pending = nil; Render() end
            local first = rows[1] and rows[1]:IsShown() and rows[1].result
            if first and GoTo.Go(first) then win:Hide() end
        end })
    win.box:SetScript("OnEnter", function(self) S.Tip(self, { L("Aller à"), L("Entrée : aller au premier résultat") }) end)
    win.box:SetScript("OnLeave", S.HideTip)
    -- Escape in the box closes the window (one key for a lost player, not two)
    win.box:SetScript("OnEscapePressed", function(self) self:ClearFocus(); win:Hide() end)
    win.list = S.ScrollArea(win)
    win.empty = S.EmptyState(win, "search", L("Aucun lieu trouvé"), nil)
    win.empty:Hide()
    win:SetScript("OnShow", function() win.list:ScrollTo(0, true); Render(); StartTrack() end)
    -- the list stops following you when the window closes
    if win.HookScript then win:HookScript("OnHide", StopTrack) else win:SetScript("OnHide", StopTrack) end
end

-- Opens the window, the box focused; `text` (optional) is searched at once.
function GoTo.Show(text)
    if not win then Build() end
    BuildStatic()
    StartIndex()
    win.box:SetText(type(text) == "string" and text or "")
    if win:IsShown() then Render() else win:Show() end   -- OnShow renders
    win.box:SetFocus()
end
function GoTo.Hide() if win then win:Hide() end end
function GoTo.Toggle() if win and win:IsShown() then win:Hide() else GoTo.Show() end end

-- /wlh aller [lieu]: the window, searching what follows the word.
function GoTo.Slash(rest)
    rest = type(rest) == "string" and rest:gsub("^%s+", ""):gsub("%s+$", "") or ""
    GoTo.Show(rest)
end

function GoTo.OnIndexStep()
    if win and win:IsShown() then Footer() end
end

-- The index finished: the list may know more now (services, NPCs).
function GoTo.OnIndexed()
    if win and win:IsShown() then Render() end
end

-- ---------------------------------------------------------------- events

local ev = CreateFrame("Frame")
pcall(ev.RegisterEvent, ev, "PLAYER_REGEN_ENABLED")
ev:SetScript("OnEvent", function(_, event)
    -- the walking path waits for the end of a fight (the router never loads in combat)
    if event == "PLAYER_REGEN_ENABLED" and trip and trip.wantTrail then TryTrail() end
end)
