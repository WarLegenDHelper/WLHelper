-- Writs/Battlegrounds.lua: the battlegrounds view of the PvP guide ("/wlh pvp", "/wlh bg", the Hub's
-- "Champs de bataille" line under Guilde et groupes). One workspace window (DESIGN 3.1), two tabs:
--  Champs de bataille  the week's bonus (one line, its source in the tooltip), then one card per
--                      battleground: name + "Bonus aujourd'hui" pill; the standing (coloured) with
--                      x / y and its bar; points to Exalted; ONE strong number (the wins left) with a
--                      muted line (or the losses, and where the figure comes from); the battlemaster
--                      on one line with "Y aller" at the right. Levels, other cities and sources sit
--                      in the card's tooltip.
--  Set PvP             honour held / honour the missing pieces cost, the marks per battleground with a
--                      bar, the battleground to do first; the pieces as a table (slot | piece in its
--                      quality colour | honour | marks | gain, the item tooltip, Shift-click links);
--                      Field of Honor in a folded card; the seals and the price source in one line.
--                      The data comes from WP.PvP.Data (Writs/PvP.lua).
-- Facts and where they come from (checked 2026-11-19):
--  * Forever has four battlegrounds: Warsong Gulch, Arathi Basin, Alterac Valley, Darkspear Islands
--    (Wowhead Forever, guide "PvP Overview in Forever", with the level brackets below). A win gives 3
--    marks, a loss 1.
--  * Reputation factions: Warsong Outriders 889 / Silverwing Sentinels 890, The Defilers 510 / League
--    of Arathor 509, Frostwolf Clan 729 / Stormpike Guard 730, Darkspear Raiders 2798 / Theramore
--    Expeditionary Force 2799 (Wowhead Forever faction pages). Exalted is 42,000 points above the
--    start of Neutral (Wowhead's standing table, faction=889).
--  * Battlemasters: the client's own NPC data (LibForeverData 2026.11.1, client 1.60.1.70532),
--    decoded offline; the Wowhead guide gives the same places (Orgrimmar Valley of Honor 79 30.5,
--    Undercity throne room 57 91, Thunder Bluff Hunter Rise 57 78, Stormwind Keep 80 38.5, Ironforge
--    Military Ward 70 88, Darnassus Warrior's Terrace 59 40.5, Dalaran 16 66 on the Alliance side).
--    One exception left as the client data says: Thunder Bluff's Arathi Basin battlemaster (Martin
--    Lindsey) stands at 28.5 20.9, not on the Hunter Rise. NOT CONFIRMED in game.
--  * The bonus battleground: Wowhead publishes no rotation for Forever. Players report special
--    battleground days in the game's calendar (Wowhead comment, 2026-11-17). So nothing is assumed:
--    the view reads the calendar's holidays (C_Calendar) for the next 7 days and names a battleground
--    only when a holiday's title names one. NOT CONFIRMED: the holidays' exact titles on Forever.
--  * Reputation per game: not published for Forever. The view measures it: the battleground's faction
--    is read when you enter and when you leave, with the winner (GetBattlefieldWinner), and the last
--    10 games per battleground are kept (WLWritsCharDB.bgRep). Without a measured game, two defaults
--    give an order of magnitude, from Classic 1.12 and NOT CONFIRMED on Forever: Warsong Gulch 35 per
--    flag capture (a win about 3 captures = 105, a loss about 1 = 35), Arathi Basin 10 per 200
--    resources (a win at 2,000 = 100, a loss about 1,000 = 50). Alterac Valley and Darkspear Islands
--    have no default: the card asks for one game to measure.
local ADDON, root = ...
root.Writs = root.Writs or {}
local ns = root.Writs
local WP = ns.WP
local L = ns.L
local S = ns.S
local C = S.C
local F = S.F

local BG = {}
WP.BG = BG

ns.AddEnglish({
    ["Champs de bataille"] = "Battlegrounds",
    ["Réputation, bonus de la semaine, maîtres de guerre"] = "Reputation, this week's bonus, battlemasters",
    ["Cette semaine"] = "This week",
    ["En bonus aujourd'hui : %s."] = "Bonus today: %s.",
    ["En bonus dans %d jours : %s."] = "Bonus in %d days: %s.",
    ["En bonus demain : %s."] = "Bonus tomorrow: %s.",
    ["Aucun champ de bataille en bonus dans le calendrier du jeu pour les 7 prochains jours."] =
        "No bonus battleground in the game's calendar for the next 7 days.",
    ["Le calendrier du jeu ne répond pas encore : rouvre cette fenêtre dans un moment."] =
        "The game's calendar hasn't answered yet: open this window again in a moment.",
    ["Lu dans le calendrier du jeu (l'icône en haut à droite de la minicarte). Forever ne publie pas de rotation fixe."] =
        "Read from the game's calendar (the icon at the top right of the minimap). Forever publishes no fixed rotation.",
    ["Une victoire donne 3 marques, une défaite 1. Les marques s'échangent aussi contre de la réputation."] =
        "A win gives 3 marks, a loss 1. Marks can also be traded for reputation.",
    ["Bonus aujourd'hui"] = "Bonus today",
    ["Niveaux"] = "Levels",
    ["Pas encore rencontrée"] = "Not met yet",
    ["Exalté atteint."] = "Exalted reached.",
    ["Encore %s points jusqu'à Exalté."] = "%s more points to Exalted.",
    ["Environ %d victoires ou %d défaites."] = "About %d wins or %d losses.",
    ["Environ %d victoires."] = "About %d wins.",
    ["Environ %d défaites."] = "About %d losses.",
    ["Mesuré sur tes %d dernières parties."] = "Measured over your last %d games.",
    ["Mesuré sur ta dernière partie."] = "Measured over your last game.",
    ["Ordre de grandeur de Classic, pas encore confirmé sur Forever : joue une partie pour le mesurer."] =
        "An order of magnitude from Classic, not confirmed on Forever yet: play a game to measure it.",
    ["Joue une partie : WL Helper mesurera la réputation qu'elle rapporte."] =
        "Play one game: WL Helper will measure the reputation it gives.",
    ["Maître de guerre : %s, %s"] = "Battlemaster: %s, %s",
    ["Aussi : %s"] = "Also: %s",
    ["Position des données du client, à confirmer en jeu."] = "Position from the client's data, to be confirmed in game.",
    ["Y aller"] = "Go there",
    ["Clic : la flèche du GPS t'emmène au maître de guerre"] = "Click: the GPS arrow takes you to the battlemaster",
    ["Ton set PvP"] = "Your PvP set",
    ["Réputation de %s : +%d (%s)."] = "%s reputation: +%d (%s).",
    ["victoire"] = "win", ["défaite"] = "loss",
    ["Haï"] = "Hated", ["Hostile"] = "Hostile", ["Inamical"] = "Unfriendly", ["Neutre"] = "Neutral",
    ["Amical"] = "Friendly", ["Honoré"] = "Honored", ["Révéré"] = "Revered", ["Exalté"] = "Exalted",
    ["Dalaran (Montagnes d'Alterac)"] = "Dalaran (Alterac Mountains)",
})

-- ---------------------------------------------------------------- data

local EXALTED = 42000
-- the start of each standing, absolute (Hated .. Exalted)
local STANDING_MIN = { -42000, -6000, -3000, 0, 3000, 9000, 21000, 42000 }
local STANDING_WORD = { "Haï", "Hostile", "Inamical", "Neutre", "Amical", "Honoré", "Révéré", "Exalté" }

-- cities: uiMapID -> name key, continent (1414 Kalimdor, 1415 Eastern Kingdoms)
BG.CITY = {
    [1454] = { "Orgrimmar", 1414 }, [1456] = { "Thunder Bluff", 1414 }, [1458] = { "Undercity", 1415 },
    [1453] = { "Stormwind", 1415 }, [1455] = { "Ironforge", 1415 }, [1457] = { "Darnassus", 1414 },
    [1416] = { "Dalaran (Montagnes d'Alterac)", 1415 },
}

-- key, name (French, L()), English and French words of the name (instance and calendar titles),
-- instance map id, level brackets, faction per side, battlemasters per side { npc, map, x, y [, unsure] }
-- (the first of a side is the default; the client data's order), Classic defaults (see the top).
BG.LIST = {
    { key = "wsg", name = "Goulet des Chanteguerres", words = { "warsong", "chanteguerre" }, inst = 489,
      levels = "10-19, 20-29, 30-39, 40-49, 50-59, 60",
      faction = { Horde = 889, Alliance = 890 },
      masters = {
          Horde = { { "Brakgul Deathbringer", 1454, 79.4, 30.3 }, { "Kurden Bloodclaw", 1458, 54.2, 96.1 }, { "Kergul Bloodaxe", 1456, 56.6, 76.5 } },
          Alliance = { { "Elfarran", 1453, 80.8, 39.6 }, { "Lylandris", 1455, 70.7, 88.9 }, { "Aethalas", 1457, 59.0, 37.0 },
              { "\"Techs\" Rickard Rustbolt", 1416, 16.8, 67.6 } },
      },
      default = { w = 105, l = 35 } },
    { key = "ab", name = "Bassin d'Arathi", words = { "arathi" }, inst = 529,
      levels = "20-29, 30-39, 40-49, 50-59, 60",
      faction = { Horde = 510, Alliance = 509 },
      masters = {
          Horde = { { "Deze Snowbane", 1454, 79.6, 29.1 }, { "Sir Malory Wheeler", 1458, 61.4, 93.0 }, { "Martin Lindsey", 1456, 28.5, 20.9, true } },
          Alliance = { { "Lady Hoteshem", 1453, 80.3, 36.7 }, { "Donal Osgood", 1455, 69.9, 88.9 }, { "Keras Wolfheart", 1457, 58.2, 37.3 },
              { "Minzi the Minx", 1416, 16.8, 68.1 } },
      },
      default = { w = 100, l = 50 } },
    { key = "av", name = "Vallée d'Alterac", words = { "alterac" }, inst = 30,
      levels = "51-60",
      faction = { Horde = 729, Alliance = 730 },
      masters = {
          Horde = { { "Kartra Bloodsnarl", 1454, 79.0, 31.3 }, { "Grizzle Halfmane", 1458, 56.3, 85.5 }, { "Taim Ragetotem", 1456, 59.0, 77.0 } },
          Alliance = { { "Thelman Slatefist", 1453, 79.4, 37.0 }, { "Glordrum Steelbeard", 1455, 69.9, 90.4 }, { "Brogun Stoneshield", 1457, 58.2, 44.5 },
              { "Sai", 1416, 16.9, 69.4 } },
      } },
    { key = "di", name = "Îles Darkspear", words = { "darkspear", "sombrelance" },
      levels = "30-39, 40-49, 50-59, 60",
      faction = { Horde = 2798, Alliance = 2799 },
      masters = {
          Horde = { { "Gruga Bloodblade", 1454, 79.4, 32.5 }, { "Rugbul Boomfirst", 1458, 60.9, 90.7 }, { "Borook Gallfist", 1456, 57.3, 77.2 } },
          Alliance = { { "James Battlewing", 1453, 80.3, 38.5 }, { "Sean Guardoff", 1455, 69.9, 89.7 }, { "Pherry Leftee", 1457, 58.2, 34.8 },
              { "Bimble Sparkfingers", 1416, 17.5, 67.7 } },
      } },
}
BG.BY = {}
for _, b in ipairs(BG.LIST) do BG.BY[b.key] = b end
BG.KEEP = 10

-- ---------------------------------------------------------------- reading the game

local function Secret(v) return issecretvalue ~= nil and issecretvalue(v) end
local function Plain(v) if v == nil or Secret(v) then return nil end return v end
local function Call(f, ...)
    if type(f) ~= "function" then return nil end
    local r = { pcall(f, ...) }
    if not r[1] then return nil end
    return unpack(r, 2)
end
local Int = (WP.PvP and WP.PvP.Int) or function(n) return tostring(math.floor(tonumber(n) or 0)) end

function BG.Side()
    local s = Plain((Call(UnitFactionGroup, "player")))
    return (s == "Horde" or s == "Alliance") and s or "Horde"
end

-- the battleground key in a title or name ("Call to Arms: Warsong Gulch", "Bassin d'Arathi"), or nil
function BG.KeyOfText(text)
    if type(text) ~= "string" or Secret(text) then return nil end
    local t = text:lower()
    for _, b in ipairs(BG.LIST) do
        for _, w in ipairs(b.words) do if t:find(w, 1, true) then return b.key end end
    end
end

-- a faction's standing: { value (absolute), standing 1-8, name }, nil when the game has none
function BG.Rep(id)
    local CR = C_Reputation
    if CR and CR.GetFactionDataByID then
        local t = Call(CR.GetFactionDataByID, id)
        if type(t) == "table" then
            local v = tonumber(Plain(t.currentStanding))
            if v then return { value = v, standing = tonumber(Plain(t.reaction)), name = Plain(t.name) } end
        end
    end
    if GetFactionInfoByID then
        local name, _, standing, _, _, value = Call(GetFactionInfoByID, id)
        value = tonumber(Plain(value))
        if value then return { value = value, standing = tonumber(Plain(standing)), name = Plain(name) } end
    end
    return nil
end

-- the standing (1-8) of an absolute value
function BG.StandingOf(v)
    local s = 1
    for i, m in ipairs(STANDING_MIN) do if v >= m then s = i end end
    return s
end
function BG.StandingWord(s)
    local g = _G["FACTION_STANDING_LABEL" .. tostring(s)]
    if type(g) == "string" and not Secret(g) and g ~= "" then return g end
    return L(STANDING_WORD[s] or "Neutre")
end

-- ---------------------------------------------------------------- measured games

local function Store()
    WLWritsCharDB = WLWritsCharDB or {}
    local d = WLWritsCharDB.bgRep
    if type(d) ~= "table" then d = {}; WLWritsCharDB.bgRep = d end
    d.games = type(d.games) == "table" and d.games or {}
    return d
end
BG.Store = Store

-- adds a game { g = reputation gained, w = won } (the last BG.KEEP per battleground)
function BG.Record(key, gain, won)
    if not BG.BY[key] or type(gain) ~= "number" or gain < 0 or won == nil then return end
    local d = Store()
    local list = type(d.games[key]) == "table" and d.games[key] or {}
    list[#list + 1] = { g = math.floor(gain + 0.5), w = won and true or false, t = time and time() or 0 }
    while #list > BG.KEEP do table.remove(list, 1) end
    d.games[key] = list
end

-- what a win and a loss give: { w, l (nil when unknown), n = games measured, src = "measured" | "default" | nil }
function BG.PerGame(key)
    local list = Store().games[key]
    local sw, nw, sl, nl = 0, 0, 0, 0
    for _, g in ipairs(type(list) == "table" and list or {}) do
        if type(g) == "table" and tonumber(g.g) then
            if g.w then sw, nw = sw + g.g, nw + 1 else sl, nl = sl + g.g, nl + 1 end
        end
    end
    if nw + nl > 0 then
        local w = nw > 0 and sw / nw or nil
        local l = nl > 0 and sl / nl or nil
        if w and w <= 0 then w = nil end
        if l and l <= 0 then l = nil end
        return { w = w, l = l, n = nw + nl, src = "measured" }
    end
    local def = BG.BY[key] and BG.BY[key].default
    if def then return { w = def.w, l = def.l, n = 0, src = "default" } end
    return { n = 0 }
end

-- the games left to Exalted from an absolute value: wins, losses (nil when unknown), the PerGame table
function BG.Estimate(key, value)
    local left = math.max(0, EXALTED - (tonumber(value) or 0))
    local p = BG.PerGame(key)
    local wins = p.w and math.ceil(left / p.w) or nil
    local losses = p.l and math.ceil(left / p.l) or nil
    return wins, losses, p, left
end

-- the battleground you are in (its key), nil outside one
function BG.Current()
    local inside, kind = Call(IsInInstance)
    if Secret(kind) or kind ~= "pvp" then return nil end
    local name, _, _, _, _, _, _, id = Call(GetInstanceInfo)
    id = tonumber(Plain(id))
    for _, b in ipairs(BG.LIST) do if b.inst and id == b.inst then return b.key end end
    local k = BG.KeyOfText(Plain(name)) or BG.KeyOfText(Plain((Call(GetRealZoneText))))
    -- Forever has four battlegrounds: an unknown one is Darkspear Islands (its map id is not checked)
    return k or "di"
end

-- your side's winner number (GetBattlefieldWinner: 0 Horde, 1 Alliance)
local function Won()
    local w = tonumber(Plain((Call(GetBattlefieldWinner))))
    if w ~= 0 and w ~= 1 then return nil end
    return (w == 0) == (BG.Side() == "Horde")
end

-- entering, inside and leaving a battleground: the faction before, the winner, the gain after
function BG.Track()
    local d = Store()
    local key = BG.Current()
    local cur = type(d.cur) == "table" and d.cur or nil
    local now = time and time() or 0
    if cur and now - (tonumber(cur.t) or 0) > 3 * 3600 then cur = nil; d.cur = nil end
    if key then
        if not cur or cur.k ~= key then
            local b = BG.BY[key]
            local r = BG.Rep(b.faction[BG.Side()])
            if r then d.cur = { k = key, v = r.value, t = now } end
            cur = d.cur
        end
        if cur then
            local w = Won()
            if w ~= nil then cur.w = w end
        end
        return
    end
    if cur then
        d.cur = nil
        local b = BG.BY[cur.k]
        local r = b and BG.Rep(b.faction[BG.Side()])
        if r and cur.w ~= nil and (tonumber(cur.v) or 0) < EXALTED then
            local gain = r.value - cur.v
            BG.Record(cur.k, gain, cur.w)
            if gain > 0 and WP.Print then
                WP.Print(string.format(L("Réputation de %s : +%d (%s)."), r.name or L(b.name), gain, L(cur.w and "victoire" or "défaite")))
            end
        end
        if BG.Refresh then BG.Refresh() end
    end
end

-- ---------------------------------------------------------------- the calendar

-- The holidays naming a battleground, today and the next 7 days: { key, title, days } (the nearest
-- first), or nil, why ("noapi" | "empty").
local opened = false
function BG.Bonus()
    local CC, D = C_Calendar, C_DateAndTime
    if not (CC and CC.GetNumDayEvents and CC.GetDayEvent and D and D.GetCurrentCalendarTime) then return nil, "noapi" end
    if not opened and CC.OpenCalendar then opened = true; Call(CC.OpenCalendar) end
    local now = Call(D.GetCurrentCalendarTime)
    if type(now) ~= "table" or not tonumber(now.monthDay) then return nil, "noapi" end
    -- the month the calendar shows: offsets are counted from it
    local base = 0
    if CC.GetMonthInfo then
        local mi = Call(CC.GetMonthInfo, 0)
        if type(mi) == "table" and tonumber(mi.month) and tonumber(mi.year) and tonumber(now.month) and tonumber(now.year) then
            base = (now.year * 12 + now.month) - (mi.year * 12 + mi.month)
        end
    end
    local days = 31
    if CC.GetMonthInfo then
        local mi = Call(CC.GetMonthInfo, base)
        if type(mi) == "table" and tonumber(mi.numDays) then days = mi.numDays end
    end
    local seen = 0
    for d = 0, 7 do
        local day, off = now.monthDay + d, base
        if day > days then day, off = day - days, base + 1 end
        local n = tonumber(Plain((Call(CC.GetNumDayEvents, off, day)))) or 0
        seen = seen + n
        for i = 1, n do
            local e = Call(CC.GetDayEvent, off, day, i)
            if type(e) == "table" and (e.calendarType == nil or e.calendarType == "HOLIDAY") then
                local title = Plain(e.title)
                local k = BG.KeyOfText(title)
                if k then return { key = k, title = title, days = d } end
            end
        end
    end
    return nil, seen == 0 and "empty" or nil
end

-- The nearest battlemaster for a battleground: the one in the city you are in, else the first of
-- your side on your continent, else the first of your side. Returns the entry and the other cities.
local function ContinentOf(map)
    local G = C_Map and C_Map.GetMapInfo
    for _ = 1, 8 do
        if not map then return nil end
        if map == 1414 or map == 1415 then return map end
        if BG.CITY[map] then return BG.CITY[map][2] end
        local info = G and Call(G, map)
        map = type(info) == "table" and tonumber(Plain(info.parentMapID)) or nil
    end
end
function BG.Master(key, side, here)
    local b = BG.BY[key]
    local list = b and b.masters[side or BG.Side()]
    if not list then return nil end
    if here == nil and C_Map and C_Map.GetBestMapForUnit then here = tonumber(Plain((Call(C_Map.GetBestMapForUnit, "player")))) end
    local pick
    for _, m in ipairs(list) do if m[2] == here then pick = m end end
    local cont = ContinentOf(here)
    if not pick and cont then
        for _, m in ipairs(list) do if BG.CITY[m[2]][2] == cont then pick = m; break end end
    end
    pick = pick or list[1]
    local others = {}
    for _, m in ipairs(list) do if m ~= pick then others[#others + 1] = L(BG.CITY[m[2]][1]) end end
    return pick, others
end

function BG.GoMaster(key)
    local m = BG.Master(key)
    if not (m and WP.GoTo and WP.GoTo.Go) then return false end
    local where = L(BG.CITY[m[2]][1])
    return WP.GoTo.Go({ kind = "npc", label = m[1], detail = where, map = m[2], x = m[3], y = m[4], gps = m[1] })
end

-- ---------------------------------------------------------------- the card texts (tests read them)

ns.AddEnglish({
    ["Clic : ouvrir les champs de bataille"] = "Click: open the battlegrounds",
    ["Journée spéciale aujourd'hui dans le calendrier du jeu : c'est le champ de bataille à faire."] =
        "A special day today in the game's calendar: this is the battleground to play.",
    ["Journée spéciale demain dans le calendrier du jeu."] = "A special day tomorrow in the game's calendar.",
    ["Journée spéciale dans %d jours dans le calendrier du jeu."] = "A special day in %d days in the game's calendar.",
    ["Bonus aujourd'hui : %s"] = "Bonus today: %s",
    ["Réputation, maîtres de guerre et ton set PvP"] = "Reputation, battlemasters and your PvP set",
    ["Set PvP"] = "PvP set",
    ["≈ 1 victoire"] = "≈ 1 win",
    ["≈ %s victoires"] = "≈ %s wins",
    ["≈ 1 défaite"] = "≈ 1 loss",
    ["≈ %s défaites"] = "≈ %s losses",
    ["ou 1 défaite"] = "or 1 loss",
    ["ou %s défaites"] = "or %s losses",
    ["estimation Classic"] = "Classic estimate",
    ["mesuré sur 1 partie"] = "measured over 1 game",
    ["mesuré sur %d parties"] = "measured over %d games",
    ["Joue une partie pour l'estimer"] = "Play one game to estimate it",
    ["Rien de plus à gagner"] = "Nothing more to earn",
    ["%s jusqu'à Exalté"] = "%s to Exalted",
    ["Niveaux : %s"] = "Levels: %s",
    ["Calendrier du jeu"] = "Game calendar",
    ["Clic : ouvrir le calendrier du jeu"] = "Click: open the game's calendar",
    ["Honneur"] = "Honor",
    ["Marques"] = "Marks",
    ["Gain"] = "Gain",
    ["Pièce"] = "Piece",
    ["Endurance"] = "Stamina",
    ["DPS PvE"] = "PvE DPS",
    ["%+d end."] = "%+d sta.",
    ["Endurance et DPS PvE"] = "Stamina and PvE DPS",
    ["Endurance : ce que la pièce apporte de plus (ou de moins) que celle que tu portes. C'est sa vraie force en PvP."] =
        "Stamina: how much more (or less) the piece gives than the one you wear. It is its real strength in PvP.",
    ["DPS PvE : l'écart calculé par WL Helper Gear avec tes poids de donjon. Une pièce PvP y perd souvent : c'est normal, elle est faite pour l'endurance."] =
        "PvE DPS: the difference WL Helper Gear works out with your dungeon weights. A PvP piece often loses there: that's normal, it is built for stamina.",
    ["Emplacement"] = "Slot",
    ["À toi"] = "Yours",
    ["Tout ton set est à toi."] = "Your whole set is yours.",
    ["Honneur : %s / %s"] = "Honor: %s / %s",
    ["Il te manque %s honneur."] = "You still need %s honor.",
    ["Tu as l'honneur pour tout le set."] = "You have the honor for the whole set.",
    ["À faire d'abord : %s"] = "Do first: %s",
    ["%d marques à gagner"] = "%d marks to earn",
    ["Pièces du set"] = "Set pieces",
    ["Autres choix : %s"] = "Other picks: %s",
    ["Maj-clic : le lien dans la discussion"] = "Shift-click: the link in chat",
    ["Quête hebdomadaire Field of Honor"] = "Weekly quest Field of Honor",
    ["Clic : afficher ou cacher"] = "Click: show or hide",
    ["Wizzik Dustfizz, Gadgetzan (Tanaris 51,8 27,2), dès le niveau 60."] = "Wizzik Dustfizz, Gadgetzan (Tanaris 51.8 27.2), from level 60.",
    ["Semaine 1 : gagner 10 duels."] = "Week 1: win 10 duels.",
    ["Semaine 2 : finir 3 parties au Goulet des Chanteguerres."] = "Week 2: finish 3 Warsong Gulch games.",
    ["Semaine 3 : tuer 25 joueurs adverses au Goulet des Chanteguerres."] = "Week 3: kill 25 enemy players in Warsong Gulch.",
    ["Chaque semaine : 300 honneur et 500 points de rang. Une semaine manquée se rattrape plus tard."] =
        "Each week: 300 honor and 500 rank points. A missed week can be done later.",
    ["Clic : la flèche du GPS t'emmène à Wizzik Dustfizz"] = "Click: the GPS arrow takes you to Wizzik Dustfizz",
    ["Plus tard, un sceau « Emboldened » (%s à %s honneur, avec un rang PvP) rend une pièce épique : garde tes pièces bleues."] =
        "Later, an \"Emboldened\" seal (%s to %s honor, with a PvP rank) makes a piece epic: keep your blue pieces.",
    ["Prix lus sur Wowhead Forever (vendeuse Lady Palanseer)."] = "Prices read on Wowhead Forever (vendor Lady Palanseer).",
    ["Pas de set PvP pour ta classe dans les données."] = "No PvP set for your class in the data.",
})

-- the standing's colour: red when hostile, orange unfriendly, gold neutral, green from friendly
local function StandingColor(s)
    if s <= 2 then return C.bad end
    if s == 3 then return C.warn end
    if s == 4 then return C.gold end
    return C.ok
end
local function Plural(n, one, many) return n == 1 and L(one) or string.format(L(many), Int(n)) end

-- Everything a battleground card shows:
-- { title, levels, bonus, standing, standingColor, count ("x / y" in the standing), barDone, barTotal,
--   toExalted, exalted, big, small, source (a sentence, for the tooltip), master, place, others,
--   unsure }
function BG.CardText(key, bonusKey)
    local b = BG.BY[key]
    local side = BG.Side()
    local t = { title = L(b.name), levels = b.levels, bonus = bonusKey == key }
    local r = BG.Rep(b.faction[side])
    t.faction = r and r.name or nil
    if r then
        local s = BG.StandingOf(r.value)
        local lo, hi = STANDING_MIN[s], STANDING_MIN[s + 1]
        t.standing, t.standingColor = BG.StandingWord(s), StandingColor(s)
        if hi then
            t.count = Int(r.value - lo) .. " / " .. Int(hi - lo)
            t.barDone, t.barTotal = r.value - lo, hi - lo
        else
            t.barDone, t.barTotal = 1, 1
        end
        t.exalted = r.value >= EXALTED
        if t.exalted then
            t.big, t.small = L("Exalté"), L("Rien de plus à gagner")
        else
            t.toExalted = string.format(L("%s jusqu'à Exalté"), Int(EXALTED - r.value))
            local wins, losses, p = BG.Estimate(key, r.value)
            local src = p.src == "measured" and Plural(p.n, "mesuré sur 1 partie", "mesuré sur %d parties")
                or p.src == "default" and L("estimation Classic") or nil
            if wins then
                t.big = Plural(wins, "≈ 1 victoire", "≈ %s victoires")
                local parts = {}
                if losses then parts[#parts + 1] = Plural(losses, "ou 1 défaite", "ou %s défaites") end
                if src then parts[#parts + 1] = src end
                t.small = table.concat(parts, " · ")
            elseif losses then
                t.big = Plural(losses, "≈ 1 défaite", "≈ %s défaites")
                t.small = src
            else
                t.big, t.small = "?", L("Joue une partie pour l'estimer")
            end
            if p.src == "measured" then
                t.source = p.n == 1 and L("Mesuré sur ta dernière partie.") or string.format(L("Mesuré sur tes %d dernières parties."), p.n)
            elseif p.src == "default" then
                t.source = L("Ordre de grandeur de Classic, pas encore confirmé sur Forever : joue une partie pour le mesurer.")
            else
                t.source = L("Joue une partie : WL Helper mesurera la réputation qu'elle rapporte.")
            end
        end
    else
        t.standing, t.standingColor = L("Pas encore rencontrée"), C.muted
        t.barDone, t.barTotal = 0, 1
        t.toExalted = string.format(L("%s jusqu'à Exalté"), Int(EXALTED))
        t.big, t.small = "?", L("Joue une partie pour l'estimer")
        t.source = L("Joue une partie : WL Helper mesurera la réputation qu'elle rapporte.")
    end
    local m, others = BG.Master(key, side)
    if m then
        t.master, t.place = m[1], L(BG.CITY[m[2]][1])
        if others and #others > 0 then t.others = string.format(L("Aussi : %s"), table.concat(others, ", ")) end
        t.unsure = m[5] and L("Position des données du client, à confirmer en jeu.") or nil
    end
    return t
end

function BG.WeekText()
    local found, why = BG.Bonus()
    if found then
        local name = L(BG.BY[found.key].name)
        if found.days == 0 then return string.format(L("En bonus aujourd'hui : %s."), name), found end
        if found.days == 1 then return string.format(L("En bonus demain : %s."), name), found end
        return string.format(L("En bonus dans %d jours : %s."), found.days, name), found
    end
    if why == "noapi" or why == "empty" then return L("Le calendrier du jeu ne répond pas encore : rouvre cette fenêtre dans un moment."), nil end
    return L("Aucun champ de bataille en bonus dans le calendrier du jeu pour les 7 prochains jours."), nil
end

-- the Home line: the bonus of today, else what the window holds
function BG.HomeLine()
    local found = BG.Bonus()
    if found and found.days == 0 then return string.format(L("Bonus aujourd'hui : %s"), L(BG.BY[found.key].name)) end
    return L("Réputation, maîtres de guerre et ton set PvP")
end

-- ---------------------------------------------------------------- the window

local win
local INSET, PAD = 16, 12
local CARD_GRID = { minW = 300, gap = 12, rowGap = 12, maxCols = 2, minPx = 200, equal = true }
local mode = "bg"
local SLOT_W, ICON, ROW_H, HON_W, MARK_W, STAM_W, GAIN_W = 92, 20, 40, 84, 150, 72, 72

local function Tip(owner, lines) S.Tip(owner, lines) end
-- an item's name and link from the game's cache; when it is not cached yet the game is asked to
-- load it (GET_ITEM_INFO_RECEIVED redraws) and ItemName falls back on our data (PvP.NAMES), never a number
local function Info(id)
    local name, link
    if GetItemInfo then
        local ok, n, l = pcall(GetItemInfo, id)
        if ok then name, link = Plain(n), Plain(l) end
    end
    if type(name) ~= "string" then
        name = nil
        if C_Item and C_Item.RequestLoadItemDataByID then pcall(C_Item.RequestLoadItemDataByID, id) end
    end
    return name, link
end
local function ItemName(id)
    return Info(id) or (WP.PvP and WP.PvP.NAMES and WP.PvP.NAMES[id]) or "?"
end
BG.ItemName = ItemName
-- the stamina of an item (by id or link), nil when the game cannot tell yet
local function Stamina(item)
    local link = item
    if type(item) == "number" then
        local _, l = Info(item)
        link = l
    end
    if type(link) ~= "string" then return nil end
    local f = (C_Item and C_Item.GetItemStats) or GetItemStats
    if not f then return nil end
    local ok, t = pcall(f, link)
    if not ok or type(t) ~= "table" then return nil end
    return tonumber(Plain(t.ITEM_MOD_STAMINA_SHORT)) or 0
end
-- the piece's stamina minus the one worn in its slot (PvP.lua's slot numbers are inventory slots)
function BG.StaminaDiff(id, slot)
    local mine = Stamina(id)
    if not mine then return nil end
    local worn
    if GetInventoryItemLink then
        local ok, l = pcall(GetInventoryItemLink, "player", slot)
        if ok then worn = Plain(l) end
    end
    return mine - ((worn and Stamina(worn)) or 0)
end
local function Paint(fs, c) if c then fs:SetTextColor(c[1], c[2], c[3]) end end

-- a battleground card: name and bonus pill; the standing, x / y and its bar; points to Exalted;
-- the one strong number (games left) and its muted line; a rule; the battlemaster and "Y aller".
local function BgCard(parent, key)
    local c = CreateFrame("Frame", nil, parent)
    c.wlOwned = true
    c.key = key
    S.Solid(c, "BACKGROUND", C.cardFill):SetAllPoints()
    S.Border(c, C.cardEdge)
    c:EnableMouse(true)
    c.title = S.Text(c, F.title, C.fg); c.title:SetWordWrap(false); c.title:SetJustifyH("LEFT")
    c.pill = S.Pill(c)
    c.standing = S.Text(c, F.label, C.fg); c.standing:SetWordWrap(false); c.standing:SetJustifyH("LEFT")
    c.count = S.Text(c, F.label, C.muted); c.count:SetWordWrap(false); c.count:SetJustifyH("RIGHT")
    c.track = S.Solid(c, "ARTWORK", { 1, 1, 1, 0.08 })
    c.fill = S.Solid(c, "OVERLAY", C.ok)
    c.toEx = S.Text(c, F.meta, C.muted); c.toEx:SetWordWrap(false); c.toEx:SetJustifyH("LEFT")
    c.big = S.Text(c, F.hero, C.fg); c.big:SetWordWrap(false); c.big:SetJustifyH("LEFT")
    c.small = S.Text(c, F.meta, C.muted); c.small:SetJustifyH("LEFT")
    c.rule = S.Solid(c, "ARTWORK", C.divider)
    c.pin = c:CreateTexture(nil, "ARTWORK"); c.pin:SetSize(14, 14)
    S.HDIcon(c.pin, "pin", C.muted)
    c.master = S.Text(c, F.label, C.fg); c.master:SetWordWrap(false); c.master:SetJustifyH("LEFT")
    c.go = S.Button(c, L("Y aller"), 0, 24, "secondary", function() BG.GoMaster(key) end,
        { L("Y aller"), L("Clic : la flèche du GPS t'emmène au maître de guerre") })
    c:SetScript("OnEnter", function(self)
        local t = self.t
        if not t then return end
        local lines = { t.title, string.format(L("Niveaux : %s"), t.levels) }
        if t.faction then lines[#lines + 1] = t.faction end
        if t.source then lines[#lines + 1] = t.source end
        if t.others then lines[#lines + 1] = t.others end
        if t.unsure then lines[#lines + 1] = t.unsure end
        Tip(self, lines)
    end)
    c:SetScript("OnLeave", S.HideTip)
    function c:Fit(w)
        local t = BG.CardText(self.key, win and win.bonus and win.bonus.days == 0 and win.bonus.key or nil)
        self.t = t
        local inner = w - 2 * PAD
        local y = PAD
        -- name, and the pill at the right
        local pillW = 0
        if t.bonus then
            self.pill:Set(L("Bonus aujourd'hui"), C.ok, "star")
            self.pill:ClearAllPoints(); self.pill:SetPoint("TOPRIGHT", -PAD, -(y + 1))
            pillW = (self.pill:GetWidth() or 100) + 8
        else self.pill:Hide() end
        self.title:SetText(t.title)
        self.title:ClearAllPoints(); self.title:SetPoint("TOPLEFT", PAD, -y); self.title:SetWidth(math.max(60, inner - pillW))
        y = y + 22 + 8
        -- the standing and its bar
        self.standing:SetText(t.standing); Paint(self.standing, t.standingColor)
        self.standing:ClearAllPoints(); self.standing:SetPoint("TOPLEFT", PAD, -y)
        self.count:SetText(t.count or "")
        self.count:ClearAllPoints(); self.count:SetPoint("TOPRIGHT", -PAD, -y)
        self.standing:SetWidth(math.max(40, inner - (root.TextWidth(self.count) or 60) - 8))
        y = y + 16 + 4
        self.track:ClearAllPoints(); self.track:SetPoint("TOPLEFT", PAD, -y); self.track:SetSize(inner, 6)
        local p = (t.barTotal or 0) > 0 and math.max(0, math.min(1, (t.barDone or 0) / t.barTotal)) or 0
        local fc = t.standingColor or C.ok
        self.fill:SetColorTexture(fc[1], fc[2], fc[3], 1)
        self.fill:ClearAllPoints(); self.fill:SetPoint("TOPLEFT", PAD, -y)
        self.fill:SetSize(math.max(1, math.floor(inner * p + 0.5)), 6); self.fill:SetShown(p > 0)
        y = y + 6 + 4
        self.toEx:SetText(t.toExalted or ""); self.toEx:SetShown(t.toExalted ~= nil)
        self.toEx:ClearAllPoints(); self.toEx:SetPoint("TOPLEFT", PAD, -y); self.toEx:SetWidth(inner)
        if t.toExalted then y = y + 14 end
        y = y + 12
        -- the one strong number
        self.big:SetText(t.big or "?"); Paint(self.big, t.exalted and C.ok or C.fg)
        self.big:ClearAllPoints(); self.big:SetPoint("TOPLEFT", PAD, -y); self.big:SetWidth(inner)
        y = y + 24
        self.small:SetText(t.small or "")
        self.small:ClearAllPoints(); self.small:SetPoint("TOPLEFT", PAD, -y)
        if t.small and t.small ~= "" then y = y + math.ceil(S.FitText(self.small, 2, inner, self)) end
        y = y + 12
        -- the battlemaster, the button at the right
        self.rule:ClearAllPoints(); self.rule:SetPoint("TOPLEFT", PAD, -y); self.rule:SetSize(inner, 1)
        y = y + 1 + 10
        if t.master then
            self.go:ClearAllPoints(); self.go:SetPoint("TOPRIGHT", -PAD, -y)
            local goW = self.go:GetWidth() or 80
            self.pin:ClearAllPoints(); self.pin:SetPoint("TOPLEFT", PAD, -(y + 5))
            self.master:SetText(t.master .. "  |cff" .. string.format("%02x%02x%02x", C.muted[1] * 255, C.muted[2] * 255, C.muted[3] * 255) .. "· " .. t.place .. "|r")
            self.master:ClearAllPoints(); self.master:SetPoint("TOPLEFT", PAD + 14 + 6, -(y + 5))
            self.master:SetWidth(math.max(40, inner - 20 - goW - 8))
            S.ClampLabel(self.master, t.master .. " · " .. t.place, self)
            self.go:Show(); self.pin:Show(); self.master:Show()
            y = y + 24
        else
            self.go:Hide(); self.pin:Hide(); self.master:Hide()
        end
        local h = math.ceil(y + PAD)
        self:SetHeight(h)
        return h
    end
    return c
end

-- The week's banner, full width. A bonus today or soon: a 32 px icon, the battleground's name as the
-- title (20, gold), a muted line under it, and "Y aller" to its battlemaster at the right. No bonus
-- found: one quiet line. Where it comes from is in the tooltip; a click opens the game's calendar.
local function WeekCard(parent)
    local c = CreateFrame("Button", nil, parent)
    c.wlOwned = true
    c.bg = S.Solid(c, "BACKGROUND", C.cardFill); c.bg:SetAllPoints()
    c.glow = S.Solid(c, "BORDER", { C.gold[1], C.gold[2], C.gold[3], 0.08 }); c.glow:SetAllPoints()
    c.edge = S.Border(c, C.cardEdge)
    c.iconBox = CreateFrame("Frame", nil, c); c.iconBox:SetSize(40, 40)
    c.icon = c.iconBox:CreateTexture(nil, "ARTWORK"); c.icon:SetSize(28, 28); c.icon:SetPoint("CENTER")
    c.title = S.Text(c, F.hero, C.gold); c.title:SetWordWrap(false); c.title:SetJustifyH("LEFT")
    c.sub = S.Text(c, F.label, C.muted); c.sub:SetJustifyH("LEFT")
    c.line = S.Text(c, F.body, C.text); c.line:SetWordWrap(false); c.line:SetJustifyH("LEFT")
    c.go = S.Button(c, L("Y aller"), 0, 28, "secondary", function()
        if c.key then BG.GoMaster(c.key) end
    end, { L("Y aller"), L("Clic : la flèche du GPS t'emmène au maître de guerre") })
    c:SetScript("OnEnter", function(self)
        Tip(self, { L("Calendrier du jeu"),
            L("Lu dans le calendrier du jeu (l'icône en haut à droite de la minicarte). Forever ne publie pas de rotation fixe."),
            L("Une victoire donne 3 marques, une défaite 1. Les marques s'échangent aussi contre de la réputation."),
            L("Clic : ouvrir le calendrier du jeu") })
    end)
    c:SetScript("OnLeave", S.HideTip)
    c:SetScript("OnClick", function()
        if ToggleCalendar then pcall(ToggleCalendar) end
    end)
    function c:Fit(w)
        local found = win and win.bonus
        self.key = found and found.key or nil
        if found then
            local name = L(BG.BY[found.key].name)
            self.glow:Show()
            self.icon:SetSize(28, 28)
            S.HDIcon(self.icon, "star", C.gold)
            self.iconBox:ClearAllPoints(); self.iconBox:SetPoint("LEFT", PAD, 0); self.iconBox:Show()
            self.title:SetText(name)
            self.shownTitle = name
            self.sub:SetText(found.days == 0 and L("Journée spéciale aujourd'hui dans le calendrier du jeu : c'est le champ de bataille à faire.")
                or found.days == 1 and L("Journée spéciale demain dans le calendrier du jeu.")
                or string.format(L("Journée spéciale dans %d jours dans le calendrier du jeu."), found.days))
            local goW = (self.go:GetWidth() or 90)
            self.go:ClearAllPoints(); self.go:SetPoint("RIGHT", -PAD, 0); self.go:Show()
            local x = PAD + 40 + 12
            local tw = math.max(80, w - x - goW - 2 * PAD)
            self.title:ClearAllPoints(); self.title:SetPoint("TOPLEFT", x, -PAD); self.title:SetWidth(tw); self.title:Show()
            S.ClampLabel(self.title, nil, self)
            self.sub:ClearAllPoints(); self.sub:SetPoint("TOPLEFT", x, -(PAD + 24 + 2))
            local sh = math.ceil(S.FitText(self.sub, 2, tw, self))
            self.sub:Show(); self.line:Hide()
            local h = math.max(64, PAD + 24 + 2 + sh + PAD)
            self.h = h
            self:SetHeight(h)
            return h
        end
        self.glow:Hide(); self.go:Hide(); self.title:Hide(); self.sub:Hide()
        self.shownTitle, self.h = nil, 44
        S.HDIcon(self.icon, "calendar", C.muted)
        self.iconBox:ClearAllPoints(); self.iconBox:SetPoint("LEFT", PAD - 8, 0); self.iconBox:Show()
        self.icon:SetSize(16, 16)
        self.line:SetText(win and win.weekText or (BG.WeekText()))
        self.line:ClearAllPoints(); self.line:SetPoint("LEFT", PAD + 32, 0); self.line:SetWidth(w - PAD - 32 - PAD)
        S.ClampLabel(self.line, nil, self)
        self.line:Show()
        self:SetHeight(44)
        return 44
    end
    return c
end

-- ---------------------------------------------------------------- the set tab

local function MarkWord(id) return L((WP.PvP and WP.PvP.MARKS[id]) or "?") end

local function MakeRow(parent)
    local r = CreateFrame("Button", nil, parent)
    r.wlOwned = true
    r.bg = S.Solid(r, "BACKGROUND", C.cardFill); r.bg:SetAllPoints()
    r.hl = S.Solid(r, "BORDER", C.hoverFill); r.hl:SetAllPoints(); r.hl:Hide()
    r.slot = S.Text(r, F.label, C.muted); r.slot:SetJustifyH("LEFT"); r.slot:SetWordWrap(false)
    r.icon = r:CreateTexture(nil, "ARTWORK"); r.icon:SetSize(ICON, ICON)
    r.name = S.Text(r, F.label, C.fg); r.name:SetJustifyH("LEFT"); r.name:SetWordWrap(false)
    r.honor = S.Text(r, F.label, C.fg); r.honor:SetJustifyH("RIGHT"); r.honor:SetWordWrap(false)
    r.marks = S.Text(r, F.label, C.fg); r.marks:SetJustifyH("RIGHT"); r.marks:SetWordWrap(false)
    r.gain = S.Text(r, F.label, C.ok); r.gain:SetJustifyH("RIGHT"); r.gain:SetWordWrap(false)
    r.stam = S.Text(r, F.label, C.ok); r.stam:SetJustifyH("RIGHT"); r.stam:SetWordWrap(false)
    r:SetScript("OnEnter", function(self)
        self.hl:Show()
        if not self.itemID then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        local ok = pcall(GameTooltip.SetItemByID, GameTooltip, self.itemID)
        if not ok then GameTooltip:SetText(tostring(self.itemID)) end
        if self.alts then GameTooltip:AddLine(self.alts, C.muted[1], C.muted[2], C.muted[3], true) end
        GameTooltip:AddLine(L("Maj-clic : le lien dans la discussion"), C.hint[1], C.hint[2], C.hint[3], true)
        GameTooltip:Show()
    end)
    r:SetScript("OnLeave", function(self) self.hl:Hide(); GameTooltip:Hide() end)
    r:SetScript("OnClick", function(self)
        if self.itemID and IsModifiedClick and IsModifiedClick("CHATLINK") then
            local _, link = Info(self.itemID)
            if link and ChatEdit_InsertLink then ChatEdit_InsertLink(link) end
        end
    end)
    return r
end

-- the table's head: the column names, muted, over the same columns as the rows
local function MakeHead(parent)
    local r = CreateFrame("Frame", nil, parent)
    r.wlOwned = true
    for _, k in ipairs({ "slot", "name", "honor", "marks", "stam", "gain" }) do
        r[k] = S.Text(r, F.meta, C.muted); r[k]:SetWordWrap(false)
    end
    r.slot:SetJustifyH("LEFT"); r.name:SetJustifyH("LEFT")
    r.honor:SetJustifyH("RIGHT"); r.marks:SetJustifyH("RIGHT"); r.stam:SetJustifyH("RIGHT"); r.gain:SetJustifyH("RIGHT")
    -- what the two last columns measure, in the header row's tooltip
    r:EnableMouse(true)
    r:SetScript("OnEnter", function(self)
        Tip(self, { L("Endurance et DPS PvE"),
            L("Endurance : ce que la pièce apporte de plus (ou de moins) que celle que tu portes. C'est sa vraie force en PvP."),
            L("DPS PvE : l'écart calculé par WL Helper Gear avec tes poids de donjon. Une pièce PvP y perd souvent : c'est normal, elle est faite pour l'endurance.") })
    end)
    r:SetScript("OnLeave", S.HideTip)
    return r
end

local function Columns(r, W)
    local x = 8
    r.slot:ClearAllPoints(); r.slot:SetPoint("LEFT", x, 0); r.slot:SetWidth(SLOT_W - 8)
    x = x + SLOT_W
    local right = 8
    r.gain:ClearAllPoints(); r.gain:SetPoint("RIGHT", -right, 0); r.gain:SetWidth(GAIN_W); right = right + GAIN_W + 12
    r.stam:ClearAllPoints(); r.stam:SetPoint("RIGHT", -right, 0); r.stam:SetWidth(STAM_W); right = right + STAM_W + 12
    r.marks:ClearAllPoints(); r.marks:SetPoint("RIGHT", -right, 0); r.marks:SetWidth(MARK_W); right = right + MARK_W + 12
    r.honor:ClearAllPoints(); r.honor:SetPoint("RIGHT", -right, 0); r.honor:SetWidth(HON_W); right = right + HON_W + 12
    return x, math.max(60, W - x - right)
end

local function PaintRow(r, W, row, d)
    r.itemID = row.id
    r:SetSize(W, ROW_H)
    local x, nameW = Columns(r, W)
    r.slot:SetText(L(row.word))
    r.icon:ClearAllPoints(); r.icon:SetPoint("LEFT", x, 0)
    S.Painted(r.icon, S.ItemIcon(row.id))
    r.name:SetText(ItemName(row.id))
    Paint(r.name, S.QualityColor(row.id) or C.fg)
    r.name:ClearAllPoints(); r.name:SetPoint("LEFT", x + ICON + 8, 0); r.name:SetWidth(nameW - ICON - 8)
    r.honor:SetText(Int(row.honor))
    r.marks:SetText(string.format("%d %s", row.marks, MarkWord(row.mark)))
    if row.owned then
        Paint(r.honor, C.muted); Paint(r.marks, C.muted)
        r.gain:SetText(L("À toi")); Paint(r.gain, C.ok)
        r.stam:SetText("")
    else
        local st = BG.StaminaDiff(row.id, row.slot)
        if st then
            r.stam:SetText(string.format(L("%+d end."), st)); Paint(r.stam, st > 0 and C.ok or st < 0 and C.warn or C.muted)
        else r.stam:SetText("") end
        Paint(r.honor, d.honor >= row.honor and C.ok or C.fg)
        Paint(r.marks, (d.have[row.mark] or 0) >= row.marks and C.ok or C.fg)
        if row.pct then
            local p = math.floor(row.pct + 0.5)
            r.gain:SetText(string.format("%+d %%", p)); Paint(r.gain, C.muted)
        else r.gain:SetText("") end
    end
    local alts = {}
    for _, o in ipairs(row.others or {}) do alts[#alts + 1] = ItemName(o) end
    r.alts = #alts > 0 and string.format(L("Autres choix : %s"), table.concat(alts, ", ")) or nil
end

-- Field of Honor, folded by default: one heading row (a click opens it), then its lines and a GPS button
local FOH = { m = 1446, x = 51.8, y = 27.2 }
local function FohCard(parent)
    local c = CreateFrame("Frame", nil, parent)
    c.wlOwned = true
    S.Solid(c, "BACKGROUND", C.cardFill):SetAllPoints()
    S.Border(c, C.cardEdge)
    c.head = CreateFrame("Button", nil, c)
    c.head:SetPoint("TOPLEFT"); c.head:SetPoint("TOPRIGHT"); c.head:SetHeight(40)
    c.chev = c.head:CreateTexture(nil, "ARTWORK"); c.chev:SetSize(12, 12); c.chev:SetPoint("LEFT", PAD, 0)
    c.label = S.Text(c.head, F.body, C.fg); c.label:SetWordWrap(false); c.label:SetPoint("LEFT", PAD + 12 + 8, 0)
    c.label:SetText(L("Quête hebdomadaire Field of Honor"))
    c.head:SetScript("OnEnter", function(self) Tip(self, { L("Quête hebdomadaire Field of Honor"), L("Clic : afficher ou cacher") }) end)
    c.head:SetScript("OnLeave", S.HideTip)
    c.head:SetScript("OnClick", function()
        WLWritsDB = WLWritsDB or {}
        WLWritsDB.bgFohOpen = not WLWritsDB.bgFohOpen or nil
        if BG.Refresh then BG.Refresh() end
    end)
    c.stack = root.TextStack(c)
    c.go = S.Button(c, L("Y aller"), 0, 24, "secondary", function()
        if WP.GoTo and WP.GoTo.Go then WP.GoTo.Go({ kind = "npc", label = "Wizzik Dustfizz", map = FOH.m, x = FOH.x, y = FOH.y, gps = "Wizzik Dustfizz" }) end
    end, { L("Y aller"), L("Clic : la flèche du GPS t'emmène à Wizzik Dustfizz") })
    function c:Fit(w)
        local open = WLWritsDB and WLWritsDB.bgFohOpen
        S.HDIcon(self.chev, open and "chevron_down" or "chevron_right", C.muted)
        local stk = self.stack
        stk:Begin(PAD, 40, math.min(w - 2 * PAD, 480))
        if open then
            stk:Body(L("Wizzik Dustfizz, Gadgetzan (Tanaris 51,8 27,2), dès le niveau 60."))
            stk:Bullets({ L("Semaine 1 : gagner 10 duels."), L("Semaine 2 : finir 3 parties au Goulet des Chanteguerres."),
                L("Semaine 3 : tuer 25 joueurs adverses au Goulet des Chanteguerres.") })
            stk:Muted(L("Chaque semaine : 300 honneur et 500 points de rang. Une semaine manquée se rattrape plus tard."))
        end
        local h = 40 + stk:End()
        if open then
            self.go:ClearAllPoints(); self.go:SetPoint("TOPLEFT", PAD, -(h + 8)); self.go:Show()
            h = h + 8 + 24 + PAD
        else self.go:Hide() end
        h = math.ceil(h)
        self:SetHeight(h)
        return h
    end
    return c
end

-- ---------------------------------------------------------------- layout

local pools = { rows = {}, heads = {} }
local function Take(kind, maker)
    local p = pools[kind]
    p.n = (p.n or 0) + 1
    local f = p[p.n]
    if not f then f = maker(win.inner); p[p.n] = f end
    f:Show()
    return f
end

local function Width()
    local w = win and win:GetWidth()
    if type(w) ~= "number" or Secret(w) or w < 400 then w = (root.WinSize and root.WinSize("workspace")) or 924 end
    return math.floor(w) - 2 * INSET
end

local function FillBG(W, y)
    local inner = win.inner
    win.week:ClearAllPoints(); win.week:SetPoint("TOPLEFT", inner, "TOPLEFT", INSET, -y); win.week:SetWidth(W)
    y = y + win.week:Fit(W) + 12
    local g = win.grid
    g:Begin(inner, INSET, y, W, CARD_GRID)
    for _, card in ipairs(win.cards) do card:Show(); g:Add(card, function(f, w) return f:Fit(w) end) end
    y = y + g:End()
    return y
end

local function FillSet(W, y)
    local inner = win.inner
    local d = WP.PvP and WP.PvP.Data and WP.PvP.Data()
    local s = win.setTop
    s:ClearAllPoints(); s:SetPoint("TOPLEFT", inner, "TOPLEFT", INSET, -y); s:SetWidth(W)
    local stk = win.setStack
    stk:Begin(0, 0, math.min(W, 480))
    if not d then
        stk:Body(L("Pas de set PvP pour ta classe dans les données."))
        local h = stk:End(); s:SetHeight(h)
        win.foh:Hide()
        return y + h
    end
    -- the summary: honor held / honor the missing pieces cost; marks per battleground with a bar
    win.honorBig:SetText(d.needH > 0 and string.format(L("Honneur : %s / %s"), Int(d.honor), Int(d.needH)) or L("Tout ton set est à toi."))
    win.honorBig:ClearAllPoints(); win.honorBig:SetPoint("TOPLEFT", s, "TOPLEFT", 0, 0)
    local top = 24
    stk:Begin(0, top, math.min(W, 480))
    if d.needH > 0 then
        stk:Muted(d.honor >= d.needH and L("Tu as l'honneur pour tout le set.") or string.format(L("Il te manque %s honneur."), Int(d.needH - d.honor)))
    end
    local ids = {}
    for id in pairs(d.needM) do ids[#ids + 1] = id end
    table.sort(ids)
    for _, id in ipairs(ids) do
        local need, have = d.needM[id], d.have[id] or 0
        stk:Stat(L(WP.PvP.MARKS[id]), math.min(have, need), need, { count = Int(have) .. " / " .. Int(need) })
    end
    if d.first then
        stk:Gap(4)
        stk:Body(string.format(L("À faire d'abord : %s"), L(WP.PvP.MARKS[d.first])) .. " (" .. string.format(L("%d marques à gagner"), d.firstN) .. ")")
    end
    local h = top + stk:End()
    s:SetHeight(h)
    y = y + h + 16
    -- the table
    local hd = Take("heads", function(p) return S.SectionHeader(p, "", 0, nil, nil, true) end)
    hd:Set(L("Pièces du set"), #d.rows)
    hd:ClearAllPoints(); hd:SetPoint("TOPLEFT", inner, "TOPLEFT", INSET, -y); hd:SetWidth(W)
    y = y + 24 + 6
    local th = win.tableHead
    th:ClearAllPoints(); th:SetPoint("TOPLEFT", inner, "TOPLEFT", INSET, -y); th:SetSize(W, 18); th:Show()
    Columns(th, W)
    th.slot:SetText(L("Emplacement")); th.name:SetText(L("Pièce")); th.honor:SetText(L("Honneur"))
    th.marks:SetText(L("Marques")); th.stam:SetText(L("Endurance")); th.gain:SetText(L("DPS PvE"))
    th.name:ClearAllPoints(); th.name:SetPoint("LEFT", 8 + SLOT_W, 0)
    y = y + 18 + 4
    for _, row in ipairs(d.rows) do
        local r = Take("rows", MakeRow)
        PaintRow(r, W, row, d)
        r:ClearAllPoints(); r:SetPoint("TOPLEFT", inner, "TOPLEFT", INSET, -y)
        y = y + ROW_H + 2
    end
    y = y + 14
    -- Field of Honor, folded; the seals and the source in one muted line
    win.foh:Show()
    win.foh:ClearAllPoints(); win.foh:SetPoint("TOPLEFT", inner, "TOPLEFT", INSET, -y); win.foh:SetWidth(W)
    y = y + win.foh:Fit(W) + 12
    local lo, hi
    for _, sl in ipairs(WP.PvP.SEALS or {}) do lo = math.min(lo or sl[2], sl[2]); hi = math.max(hi or sl[2], sl[2]) end
    local note = (lo and string.format(L("Plus tard, un sceau « Emboldened » (%s à %s honneur, avec un rang PvP) rend une pièce épique : garde tes pièces bleues."), Int(lo), Int(hi)) or "")
        .. " " .. L("Prix lus sur Wowhead Forever (vendeuse Lady Palanseer).")
    win.note:SetText(note)
    win.note:ClearAllPoints(); win.note:SetPoint("TOPLEFT", inner, "TOPLEFT", INSET, -y)
    y = y + math.ceil(S.FitText(win.note, 3, math.min(W, 640), inner))
    return y
end

local function Fill()
    if not (win and win:IsShown()) then return end
    for _, p in pairs(pools) do
        for i = 1, #p do p[i]:Hide() end
        p.n = 0
    end
    win.weekText, win.bonus = BG.WeekText()
    local W = Width()
    local onBG = mode ~= "set"
    win.week:SetShown(onBG)
    for _, c in ipairs(win.cards) do c:SetShown(onBG) end
    win.setTop:SetShown(not onBG); win.honorBig:SetShown(not onBG)
    win.foh:SetShown(not onBG); win.note:SetShown(not onBG); win.tableHead:SetShown(false)
    local y = 14
    if onBG then y = FillBG(W, y) else y = FillSet(W, y) end
    local innerH = math.ceil(y)
    win.lastH, win.rowsShown = innerH, pools.rows.n or 0
    win.scroll:SetContentHeight(innerH + 24)
    win:FitHeight(innerH)
    if win.tabs and win.tabs.Paint then win.tabs:Paint() end
end
BG.Refresh = Fill
BG._Fill = Fill

local function Build()
    local w0, h0 = root.WinSize("workspace")
    win = S.Window("WLHelperBattlegrounds", w0 or 924, h0 or 614, L("Champs de bataille"), nil, WLWritsDB, "bgPos",
        { header = S.HEADER_H or 44, size = "workspace" })
    local top = win:ContentTop()
    win.tabs = S.Tabs(win, { { "bg", L("Champs de bataille") }, { "set", L("Set PvP") } },
        function() return mode end, function(m) mode = m; if win.scroll.ScrollTo then win.scroll:ScrollTo(0, true) end; Fill() end)
    win.tabs:SetPoint("TOPLEFT", 0, -top); win.tabs:SetPoint("TOPRIGHT", 0, -top)
    local sa = S.ScrollArea(win)
    sa:SetPoint("TOPLEFT", win, "TOPLEFT", 0, -(top + (S.TABS_H or 32) + 1))
    sa:SetPoint("BOTTOMRIGHT", win, "BOTTOMRIGHT", 0, 0)
    win.scroll, win.inner = sa, sa.child
    win.week = WeekCard(win.inner)
    win.cards = {}
    for _, b in ipairs(BG.LIST) do win.cards[#win.cards + 1] = BgCard(win.inner, b.key) end
    win.grid = ns.Grid()
    win.setTop = CreateFrame("Frame", nil, win.inner)
    win.setStack = root.TextStack(win.setTop)
    win.honorBig = S.Text(win.setTop, F.title, C.fg); win.honorBig:SetWordWrap(false); win.honorBig:SetJustifyH("LEFT")
    win.tableHead = MakeHead(win.inner)
    win.foh = FohCard(win.inner)
    win.note = S.Text(win.inner, F.meta, C.muted); win.note:SetJustifyH("LEFT")
    win.OnResize = function() Fill() end
    win:SetScript("OnShow", function()
        Fill()
        if C_Timer and C_Timer.After then C_Timer.After(0, function() if win:IsShown() then Fill() end end) end
    end)
    win:Hide()
end

-- BG.Toggle([tab [, show]]): opens on that tab ("bg" | "set", or the last one); closes when open
-- and neither a tab nor show is asked
function BG.Toggle(m, show)
    if not win then Build() end
    if m == "bg" or m == "set" then mode = m end
    if win:IsShown() and not show and not m then win:Hide(); return end
    win:Show()
    if win.Raise then win:Raise() end
    Fill()
end
function BG.Window() return win end
function BG.Mode() return mode end

-- ---------------------------------------------------------------- events

local ev = CreateFrame("Frame")
for _, e in ipairs({ "PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA", "UPDATE_BATTLEFIELD_STATUS",
    "UPDATE_BATTLEFIELD_SCORE", "PVP_MATCH_COMPLETE", "CALENDAR_UPDATE_EVENT_LIST", "UPDATE_FACTION", "GET_ITEM_INFO_RECEIVED" }) do
    pcall(ev.RegisterEvent, ev, e)
end
ev:SetScript("OnEvent", function(_, e)
    if e == "GET_ITEM_INFO_RECEIVED" then
        -- names and stats arrive one item at a time: one redraw a moment after the first one
        if win and win:IsShown() and mode == "set" and not BG._redraw then
            BG._redraw = true
            local function go() BG._redraw = nil; if win:IsShown() then Fill() end end
            if C_Timer and C_Timer.After then C_Timer.After(0.2, go) else go() end
        end
        return
    end
    if e == "CALENDAR_UPDATE_EVENT_LIST" or e == "UPDATE_FACTION" then
        if win and win:IsShown() then Fill() end
        return
    end
    local ok, err = pcall(BG.Track)
    if not ok and geterrorhandler then geterrorhandler()(err) end
end)
