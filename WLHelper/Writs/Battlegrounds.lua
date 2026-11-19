-- Writs/Battlegrounds.lua: the battlegrounds view of the PvP guide ("/wlh pvp", "/wlh bg").
-- One workspace window (DESIGN 3.1, like Help): a card for this week's bonus battleground, one card
-- per battleground (its reputation, the points left to Exalted, how many games that still takes, the
-- nearest battlemaster with a GPS button), then the PvP set card (PvP.Lines(), Writs/PvP.lua).
--
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

-- { title, levels, stat = { label, done, total, count, sub }, estimate, source, master, others, unsure }
function BG.CardText(key)
    local b = BG.BY[key]
    local side = BG.Side()
    local t = { title = L(b.name), levels = b.levels }
    local r = BG.Rep(b.faction[side])
    if r then
        local s = BG.StandingOf(r.value)
        local lo, hi = STANDING_MIN[s], STANDING_MIN[s + 1]
        local count = BG.StandingWord(s)
        if hi then count = count .. "  " .. Int(r.value - lo) .. " / " .. Int(hi - lo) end
        local fromNeutral = math.max(0, math.min(EXALTED, r.value))
        local sub = r.value >= EXALTED and L("Exalté atteint.") or string.format(L("Encore %s points jusqu'à Exalté."), Int(EXALTED - r.value))
        t.stat = { label = r.name or L(b.name), done = fromNeutral, total = EXALTED, count = count, sub = sub }
        if r.value < EXALTED then
            local wins, losses, p = BG.Estimate(key, r.value)
            if wins and losses then t.estimate = string.format(L("Environ %d victoires ou %d défaites."), wins, losses)
            elseif wins then t.estimate = string.format(L("Environ %d victoires."), wins)
            elseif losses then t.estimate = string.format(L("Environ %d défaites."), losses) end
            if p.src == "measured" then
                t.source = p.n == 1 and L("Mesuré sur ta dernière partie.") or string.format(L("Mesuré sur tes %d dernières parties."), p.n)
            elseif p.src == "default" then
                t.source = L("Ordre de grandeur de Classic, pas encore confirmé sur Forever : joue une partie pour le mesurer.")
            else
                t.source = L("Joue une partie : WL Helper mesurera la réputation qu'elle rapporte.")
            end
        end
    else
        t.stat = { label = L(b.name), done = 0, total = EXALTED, count = L("Pas encore rencontrée"),
            sub = string.format(L("Encore %s points jusqu'à Exalté."), Int(EXALTED)) }
        t.source = L("Joue une partie : WL Helper mesurera la réputation qu'elle rapporte.")
    end
    local m, others = BG.Master(key, side)
    if m then
        t.master = string.format(L("Maître de guerre : %s, %s"), m[1], L(BG.CITY[m[2]][1]))
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

-- ---------------------------------------------------------------- the window

local win, CW
local PAD = 12
local CARD_GRID = { minW = 300, gap = 12, rowGap = 12, maxCols = 2, minPx = 200, equal = true }

local function CardBase(parent)
    local c = CreateFrame("Frame", nil, parent)
    c.wlOwned = true
    S.Solid(c, "BACKGROUND", C.cardFill):SetAllPoints()
    S.Border(c, C.cardEdge)
    c.stack = root.TextStack(c)
    return c
end

local function WeekCard(parent)
    local c = CardBase(parent)
    function c:Fit(width)
        local stk = self.stack
        stk:Begin(PAD, PAD, math.min(width - 2 * PAD, 480))
        stk:Heading(L("Cette semaine"))
        stk:Body(win and win.weekText or (BG.WeekText()))
        stk:Muted(L("Lu dans le calendrier du jeu (l'icône en haut à droite de la minicarte). Forever ne publie pas de rotation fixe."))
        stk:Muted(L("Une victoire donne 3 marques, une défaite 1. Les marques s'échangent aussi contre de la réputation."))
        local h = math.ceil(PAD + stk:End() + PAD)
        self:SetHeight(h)
        return h
    end
    return c
end

local function BgCard(parent, key)
    local c = CardBase(parent)
    c.key = key
    c.go = S.Button(c, L("Y aller"), 0, 28, "secondary", function() BG.GoMaster(key) end,
        { L("Y aller"), L("Clic : la flèche du GPS t'emmène au maître de guerre") })
    function c:Fit(width)
        local t = BG.CardText(self.key)
        local bonus = win and win.bonus
        local stk = self.stack
        stk:Begin(PAD, PAD, width - 2 * PAD)
        stk:Heading(t.title)
        if bonus and bonus.key == self.key and bonus.days == 0 then stk:Body(L("Bonus aujourd'hui")) end
        stk:Fact(L("Niveaux"), t.levels)
        stk:Stat(t.stat.label, t.stat.done, t.stat.total, { count = t.stat.count, sub = t.stat.sub })
        stk:Body(t.estimate)
        stk:Muted(t.source)
        stk:Body(t.master)
        stk:Muted(t.others)
        stk:Muted(t.unsure)
        local y = PAD + stk:End() + 12
        self.go:ClearAllPoints(); self.go:SetPoint("TOPLEFT", PAD, -y)
        self.go:SetShown(t.master ~= nil)
        local h = math.ceil(y + (t.master and 28 or 0) + PAD)
        self:SetHeight(h)
        return h
    end
    return c
end

local function SetCard(parent)
    local c = CardBase(parent)
    function c:Fit(width)
        local stk = self.stack
        stk:Begin(PAD, PAD, math.min(width - 2 * PAD, 900))
        stk:Heading(L("Ton set PvP"))
        local lines = (WP.PvP and WP.PvP.Lines) and WP.PvP.Lines() or {}
        stk:Bullets(lines)
        local h = math.ceil(PAD + stk:End() + PAD)
        self:SetHeight(h)
        return h
    end
    return c
end

local function Dims()
    local w = win and win:GetWidth()
    if type(w) ~= "number" or Secret(w) or w < 400 then
        w = (root.WinSize and root.WinSize("workspace")) or 924
    end
    CW = math.floor(w) - 32
    return CW
end

local function Layout()
    if not (win and win:IsShown()) then return end
    Dims()
    win.weekText, win.bonus = BG.WeekText()
    local inner = win.inner
    local y = 12
    local function Place(f, h, gap)
        f:ClearAllPoints()
        f:SetPoint("TOPLEFT", inner, "TOPLEFT", 16, -y)
        f:SetWidth(CW); f:SetHeight(h)
        y = y + h + (gap or 0)
    end
    Place(win.week, win.week:Fit(CW), 12)
    local g = win.grid
    g:Begin(inner, 16, y, CW, CARD_GRID)
    for _, card in ipairs(win.cards) do g:Add(card, function(f, w) return f:Fit(w) end) end
    y = y + g:End() + 12
    Place(win.set, win.set:Fit(CW), 0)
    local innerH = math.ceil(y)
    win.scroll:SetContentHeight(innerH + 24)
    win:FitHeight(innerH)
end
BG.Refresh = Layout

local function Build()
    local w0, h0 = root.WinSize("workspace")
    win = S.Window("WLHelperBattlegrounds", w0 or 924, h0 or 614, L("Champs de bataille"),
        L("Réputation, bonus de la semaine, maîtres de guerre"), WLWritsDB, "bgPos", { header = 44, size = "workspace" })
    local sa = S.ScrollArea(win)
    sa:SetPoint("TOPLEFT", win, "TOPLEFT", 0, -(win.headerH + 1))
    sa:SetPoint("BOTTOMRIGHT", win, "BOTTOMRIGHT", 0, 0)
    win.scroll, win.inner = sa, sa.child
    win.week = WeekCard(win.inner)
    win.cards = {}
    for _, b in ipairs(BG.LIST) do win.cards[#win.cards + 1] = BgCard(win.inner, b.key) end
    win.grid = ns.Grid()
    win.set = SetCard(win.inner)
    win.OnResize = function() Layout() end
    win:SetScript("OnShow", function()
        Layout()
        if C_Timer and C_Timer.After then C_Timer.After(0, function() if win:IsShown() then Layout() end end) end
    end)
end

function BG.Toggle()
    if win and win:IsShown() then win:Hide(); return end
    if not win then Build() end
    win:Show()
    Layout()
end
function BG.Window() return win end

-- ---------------------------------------------------------------- events

local ev = CreateFrame("Frame")
for _, e in ipairs({ "PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA", "UPDATE_BATTLEFIELD_STATUS",
    "UPDATE_BATTLEFIELD_SCORE", "PVP_MATCH_COMPLETE", "CALENDAR_UPDATE_EVENT_LIST", "UPDATE_FACTION" }) do
    pcall(ev.RegisterEvent, ev, e)
end
ev:SetScript("OnEvent", function(_, e)
    if e == "CALENDAR_UPDATE_EVENT_LIST" or e == "UPDATE_FACTION" then
        if win and win:IsShown() then Layout() end
        return
    end
    local ok, err = pcall(BG.Track)
    if not ok and geterrorhandler then geterrorhandler()(err) end
end)
