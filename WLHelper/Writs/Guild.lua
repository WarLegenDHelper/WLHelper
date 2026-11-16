-- Writs/Guild.lua: the Guild module (/wlh guild).
--
--  Members   The whole guild from the game's roster, with a search, a sort (level, name, zone, rank),
--            class and role filters (one button clears them), where the guild is right now (the
--            busiest zones, a click filters on one), and on each line: online dot, level, class
--            icon and colour, the WL logo on those who have the addon, the role of their spec, zone
--            (or when the member was last on), rank (an Invite button in its place on hover).
--            Click: whisper. Right-click: invite. The tooltip adds class and spec, the public note,
--            the professions the member shares (Orders) and the addon's version.
--            Drawn with the design system (docs/DESIGN.md): 640 wide, sized to its content; the
--            list scrolls inside the window only past 80 % of the screen.
--  Keys     "Qui a la clé ?": for each dungeon key, the members who have it (drawn by Writs/Keys.lua,
--            which also does its sharing; the tab only shows when that file is loaded).
--  PvP      A ranking of honorable kills, as the game counts them (battlegrounds included): this
--            week, this season (one season = one calendar month) and all time. The game keeps the
--            all-time total, so it shows from day one; week and season follow from it. Each copy of
--            WL Helper tells the guild its own numbers on the addon channel; the season's podium is
--            kept when a new season starts. Kills made in the open world are counted apart.
--            Each kill is put on a place (the battleground, or the zone): the top 6 per period.
--            K/D/A: battlegrounds from the player's own scoreboard row (once per match, assists =
--            HK - KB, an estimate); open world: deaths while an enemy player was around. A row
--            shows the top places, then killing blows and deaths in words ("Champs de bataille :
--            6 coups fatals, 5 morts"), in muted lines; its tooltip the whole breakdown. No "KB" or
--            "K/D/A" code on screen: "VH" is the list's unit, named once in the line above it.
-- The combat log is closed to addons on this client: nothing here reads it (no open-world KB).
-- Only counts, places, levels and the version travel; nothing else about the character.
-- Usual hours (T-66): each copy notes, from the game's guild roster, who is online at which hour of
-- the week (WLWritsDB.guildHours, the last 4 weeks, kept on this computer, never sent); the member
-- tooltip and the crafter profiles (Orders) show "Souvent là : 20h–23h".
local ADDON, root = ...
root.Writs = root.Writs or {}
local ns = root.Writs
local WP = ns.WP
local L = ns.L
local S = ns.S
local C = S.C

ns.AddEnglish({
    -- the window, its tabs and its header
    ["Guilde"] = "Guild",
    ["Membres"] = "Members",
    ["Classement PvP"] = "PvP ranking",
    ["La liste vient du jeu. Le rôle vient de la spé que chaque membre a choisie dans WL Helper."] = "The list comes from the game. The role comes from the spec each member picked in WL Helper.",
    ["Le logo WL marque les membres qui ont WL Helper."] = "The WL logo marks the members who have WL Helper.",
    ["Les victoires honorables comptées par le jeu, champs de bataille compris."] = "Honorable kills as the game counts them, battlegrounds included.",
    ["Une saison dure un mois : le podium de la saison passée reste affiché."] = "A season lasts a month: last season's podium stays on display.",
    ["Seuls les membres qui ont WL Helper apparaissent."] = "Only members who have WL Helper show up.",
    -- members: count, switch, search, sort, filters
    ["1 membre en ligne sur %d"] = "1 of %d members online",
    ["%d membres en ligne sur %d"] = "%d of %d members online",
    ["En ligne seulement"] = "Online only",
    ["Allumé, la liste cache les membres hors ligne."] = "When on, the list hides offline members.",
    ["Clic : allumer ou éteindre"] = "Click: turn on or off",
    ["Ex. Mylla, Orgrimmar, Officier"] = "E.g. Mylla, Orgrimmar, Officer",
    ["Niveau"] = "Level",
    ["Nom"] = "Name",
    ["Classe"] = "Class",
    ["Zone"] = "Zone",
    ["Rang"] = "Rank",
    ["Clic : trier par niveau"] = "Click: sort by level",
    ["Clic : trier par nom"] = "Click: sort by name",
    ["Clic : trier par classe"] = "Click: sort by class",
    ["Clic : trier par zone"] = "Click: sort by zone",
    ["Clic : trier par rang"] = "Click: sort by rank",
    ["Toutes les classes"] = "All classes",
    ["Clic : montrer toutes les classes"] = "Click: show every class",
    ["Clic : ne montrer que cette classe"] = "Click: show only this class",
    ["Tous les rôles"] = "All roles",
    ["Tank"] = "Tank", ["Soigneur"] = "Healer", ["DPS"] = "DPS",
    ["Clic : montrer tous les rôles"] = "Click: show every role",
    ["Clic : ne montrer que les tanks"] = "Click: show only tanks",
    ["Clic : ne montrer que les soigneurs"] = "Click: show only healers",
    ["Clic : ne montrer que les DPS"] = "Click: show only DPS",
    ["Où est la guilde :"] = "Where the guild is:",
    ["1 membre en ligne ici"] = "1 member online here",
    ["%d membres en ligne ici"] = "%d members online here",
    ["Clic : ne montrer que cette zone"] = "Click: show only this zone",
    ["Clic : montrer toutes les zones"] = "Click: show every zone",
    ["Rôle connu pour 1 membre sur %d : seuls ceux qui ont WL Helper et ont choisi leur spé le partagent."] = "Role known for 1 member of %d: only those who have WL Helper and picked their spec share it.",
    ["Rôle connu pour %d membres sur %d : seuls ceux qui ont WL Helper et ont choisi leur spé le partagent."] = "Role known for %d members of %d: only those who have WL Helper and picked their spec share it.",
    ["Aucun rôle connu parmi ces %d membres : seuls ceux qui ont WL Helper et ont choisi leur spé le partagent."] = "No role known among these %d members: only those who have WL Helper and picked their spec share it.",
    ["Enlever les filtres"] = "Clear filters",
    ["Niv."] = "Lv",
    ["Zone ou dernière connexion"] = "Zone or last seen",
    -- members: the rows and their tooltip
    ["Inviter"] = "Invite",
    ["Invité"] = "Invited",
    ["Niv. %s, %s"] = "Level %s, %s",
    ["En ligne : %s"] = "Online: %s",
    ["Vu %s"] = "Last seen %s",
    ["Rang : %s"] = "Rank: %s",
    ["Note : %s"] = "Note: %s",
    ["Métiers : %s"] = "Professions: %s",
    ["Utilise WL Helper"] = "Uses WL Helper",
    ["Utilise WL Helper (version %s)"] = "Uses WL Helper (version %s)",
    ["Clic : chuchoter"] = "Click: whisper",
    ["Clic droit : inviter dans ton groupe"] = "Right-click: invite to your group",
    ["il y a %d j"] = "%d days ago",
    ["il y a %d h"] = "%d h ago",
    ["il y a moins d'1 h"] = "less than 1 h ago",
    ["hier"] = "yesterday",
    -- members: empty states
    ["Aucun membre ne correspond"] = "No member matches",
    ["La recherche porte sur le nom, la zone et le rang."] = "The search looks at names, zones and ranks.",
    ["Personne d'autre n'est en ligne avec ces filtres."] = "Nobody else is online with these filters.",
    ["Tu n'es dans aucune guilde"] = "You are not in a guild",
    ["Les membres et le classement PvP apparaîtront ici dès que tu rejoins une guilde."] = "Members and the PvP ranking will show up here as soon as you join a guild.",
    -- PvP ranking
    ["Cette semaine"] = "This week",
    ["Saison"] = "Season",
    ["Depuis toujours"] = "All time",
    ["Clic : classer les victoires de cette semaine"] = "Click: rank this week's kills",
    ["Clic : classer les victoires de la saison (le mois en cours)"] = "Click: rank this season's kills (the current month)",
    ["Clic : classer toutes les victoires depuis le début"] = "Click: rank every kill since the start",
    ["Saison %s"] = "Season %s",
    ["Tes victoires honorables (VH) : %s cette semaine, %s cette saison, %s au total."] = "Your honorable kills (HK): %s this week, %s this season, %s in total.",
    ["Saison précédente (%s) : %s"] = "Last season (%s): %s",
    ["%s (toi)"] = "%s (you)",
    ["VH"] = "HK",
    ["dont %s en monde ouvert"] = "incl. %s in the open world",
    ["1 victoire honorable"] = "1 honorable kill",
    ["%s victoires honorables"] = "%s honorable kills",
    ["Aucune victoire cette semaine"] = "No kills this week",
    ["Aucune victoire cette saison"] = "No kills this season",
    ["Aucune victoire pour l'instant"] = "No kills yet",
    -- PvP ranking: where the kills come from, K/D/A
    ["Autres"] = "Other",
    ["1 mort"] = "1 death",
    ["%s morts"] = "%s deaths",
    ["1 coup fatal"] = "1 killing blow",
    ["%s coups fatals"] = "%s killing blows",
    ["Champs de bataille : %s, %s"] = "Battlegrounds: %s, %s",
    ["Monde ouvert : %s VH, %s"] = "Open world: %s HK, %s",
    ["D'où viennent les victoires :"] = "Where the kills come from:",
    ["Lieux suivis depuis la mise à jour : %s victoires sur %s."] = "Places tracked since the update: %s of %s kills.",
    ["Champs de bataille, 1 partie"] = "Battlegrounds, 1 match",
    ["Champs de bataille, %s parties"] = "Battlegrounds, %s matches",
    ["Coups fatals"] = "Killing blows",
    ["Morts"] = "Deaths",
    ["Assistances (estimation)"] = "Assists (estimate)",
    ["Coups fatals par mort"] = "Killing blows per death",
    ["Honneur gagné"] = "Honor gained",
    ["Assistances : victoires honorables moins coups fatals, lues au tableau des scores. Une estimation."] = "Assists: honorable kills minus killing blows, read from the scoreboard. An estimate.",
    ["Monde ouvert"] = "Open world",
    ["Victoires honorables"] = "Honorable kills",
    ["Morts face à un joueur"] = "Deaths to a player",
    ["Les coups fatals en monde ouvert restent invisibles aux addons."] = "Open-world killing blows stay hidden from addons.",
    ["Lieux, coups fatals et morts : visibles quand ce membre aura la dernière version de WL Helper."] = "Places, killing blows and deaths: shown once this member has the latest WL Helper.",
    ["En champ de bataille cette semaine : %s."] = "In battlegrounds this week: %s.",
    ["En champ de bataille cette saison : %s."] = "In battlegrounds this season: %s.",
    ["En champ de bataille depuis toujours : %s."] = "In battlegrounds, all time: %s.",
    ["ratio %s"] = "ratio %s",
    ["Les victoires honorables des membres qui ont WL Helper apparaîtront ici."] = "Honorable kills of the members who have WL Helper will show up here.",
    -- chat
    ["Victoire honorable en monde ouvert : la 1re de la semaine."] = "Open-world honorable kill: your first this week.",
    ["Victoire honorable en monde ouvert : ça fait %s cette semaine."] = "Open-world honorable kill: that's %s this week.",
    -- read by other windows (Home, the Writs window)
    ["Pas de guilde."] = "No guild.",
    ["%d en ligne"] = "%d online",
    ["Tous"] = "All",
    -- the keys tab (drawn by Writs/Keys.lua)
    ["Qui a la clé ?"] = "Who has the key?",
    -- T-66: usual hours
    ["Souvent là : %s"] = "Often on: %s",
    ["à toute heure"] = "at any hour",
    ["%dh"] = "%d:00",
})

local MONTHS = {
    fr = { "janvier", "février", "mars", "avril", "mai", "juin", "juillet", "août", "septembre", "octobre", "novembre", "décembre" },
    en = { "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December" },
}
local function SeasonName(key)
    local y, m = tostring(key or ""):match("^(%d+)%-(%d+)$")
    if not y then return tostring(key or "") end
    local list = (root.lang == "en") and MONTHS.en or MONTHS.fr
    return (list[tonumber(m)] or m) .. " " .. y
end

local PREFIX = "WLHgld"
local CI = C_ChatInfo
local Register = (CI and CI.RegisterAddonMessagePrefix) or RegisterAddonMessagePrefix
-- looked up at each send (not kept from load time): the same function, and tests can watch it
local function SendRaw(...)
    local f = (C_ChatInfo and C_ChatInfo.SendAddonMessage) or SendAddonMessage
    if f then return f(...) end
end
if Register then pcall(Register, PREFIX) end

local function Me() return (UnitName("player")) end
-- "Name-Realm" or "Name Realm": the name alone
local function Short(n) return n and (n:gsub("[%- ].*$", "")) end
-- The week follows the server's weekly reset (like the game's weekly kill counter), not the calendar.
-- The key is the date the current week started: the same on every client, the reset is server-wide.
local function Week()
    local ok, secs = false, nil
    if C_DateAndTime and C_DateAndTime.GetSecondsUntilWeeklyReset then ok, secs = pcall(C_DateAndTime.GetSecondsUntilWeeklyReset) end
    if ok and type(secs) == "number" and secs > 0 then
        local now = GetServerTime and GetServerTime() or time()
        return date("%Y-%m-%d", now + secs - 7 * 86400)
    end
    return date("%Y-%W")
end
local function Season() return date("%Y-%m") end
local function On() return WP.ModuleOn("guild") end

-- ---------------------------------------------------------------- my numbers
local function LifetimeHK()
    if GetPVPLifetimeStats then
        local ok, hk = pcall(GetPVPLifetimeStats)
        if ok and type(hk) == "number" then return hk end
    end
    return 0
end
-- this week's honorable kills from the game when it gives them (nil otherwise)
local function GameWeekHK()
    if GetPVPThisWeekStats then
        local ok, hk = pcall(GetPVPThisWeekStats)
        if ok and type(hk) == "number" then return hk end
    end
end

local function Mine()
    WLWritsCharDB.pvp = WLWritsCharDB.pvp or {}
    local p = WLWritsCharDB.pvp
    p.kb, p.week = p.kb or 0, p.week or 0                    -- open world: total, this week
    p.weekBase, p.seasonBase = p.weekBase or {}, p.seasonBase or {}
    if p.wk ~= Week() then p.wk, p.week = Week(), 0 end
    return p
end

-- { hk, week, season } from the game's total and the starting points of the week and the season
local function Numbers()
    local p = Mine()
    local hk = LifetimeHK()
    local wk, sk = Week(), Season()
    local gw = GameWeekHK()
    if not p.weekBase[wk] then p.weekBase[wk] = hk - (gw or 0) end
    -- a season seen for the first time starts with this week's kills (the best guess of what came before)
    if not p.seasonBase[sk] then p.seasonBase[sk] = hk - (gw or 0) end
    local week = gw or math.max(0, hk - p.weekBase[wk])
    local season = math.max(week, hk - p.seasonBase[sk])
    return hk, week, season
end

-- The saved data of the current guild (WLWritsDB is account-wide: alts can be in other guilds).
-- No guild (or the game does not know it yet, a few seconds after login): a throwaway table.
local function GuildSlot(tbl)
    local g = GetGuildInfo and GetGuildInfo("player")
    if not g then return {}, false end
    local k = g .. "-" .. (GetRealmName and GetRealmName() or "")
    WLWritsDB[tbl] = WLWritsDB[tbl] or {}
    local s = WLWritsDB[tbl]
    s[k] = s[k] or {}
    return s[k], true
end

local function Board()
    local b, known = GuildSlot("guildBy")
    -- once: the board saved before it was kept per guild goes to the current guild
    if known and WLWritsDB.guild then
        if next(b) == nil then for name, e in pairs(WLWritsDB.guild) do b[name] = e end end
        WLWritsDB.guild = nil
    end
    -- old entries saved as "Name Realm" or "Name-Realm": folded into the short name, newest kept
    local long = {}
    for name in pairs(b) do if Short(name) ~= name then long[#long + 1] = name end end
    for _, name in ipairs(long) do
        local e, short = b[name], Short(name)
        local cur = b[short]
        if not cur or (e.t or 0) > (cur.t or 0) then b[short] = e end
        b[name] = nil
    end
    return b
end

-- { key = the season last seen, list = { [season] = podium } } of the current guild
local function Seasons()
    local sl, known = GuildSlot("guildSeasonsBy")
    if known and (WLWritsDB.guildSeasons or WLWritsDB.guildSeasonKey) then
        if next(sl) == nil then sl.key, sl.list = WLWritsDB.guildSeasonKey, WLWritsDB.guildSeasons end
        WLWritsDB.guildSeasons, WLWritsDB.guildSeasonKey = nil, nil
    end
    sl.list = sl.list or {}
    return sl, known
end

-- ---------------------------------------------------------------- places and K/D/A
-- Where each honorable kill came from (the battleground, or the open-world zone), and the K/D/A:
-- battlegrounds from the player's own row of the scoreboard (once per match), open world deaths
-- when an enemy player was around. Kept per period: a = all time, w = this week, s = this season.
-- Killing blows in the open world would need the combat log, closed to addons here: not counted.
local OTHER = "~"             -- the places beyond the top ones, shown as "Autres"
local KEEP_PLACES = 6
local KD_M, KD_KB, KD_HK, KD_D, KD_AS, KD_HON, KD_OD = 1, 2, 3, 4, 5, 6, 7   -- e.kd.a / w / s
local function Secret(v) return issecretvalue ~= nil and issecretvalue(v) == true end
local function Clean(v) if type(v) == "string" and not Secret(v) and v ~= "" then return v end end
local function N(v) if type(v) == "number" and not Secret(v) then return v end end
local function Call(f, ...)
    if type(f) ~= "function" then return end
    local r = { pcall(f, ...) }
    if r[1] then return unpack(r, 2) end
end
-- "Goulet des Chanteguerres": no separator of the sync messages, not too long
local function SafeName(s)
    s = Clean(s)
    if not s then return nil end
    s = s:gsub("[|:;~%c]", ""):gsub("^%s+", ""):gsub("%s+$", "")
    if s == "" or #s > 60 then return nil end
    return s
end
-- a number from another member: whole, not negative, not absurd
local function Cap(v, max)
    v = tonumber(v) or 0
    if v ~= v or v < 0 then return 0 end
    return math.min(math.floor(v), max or 1000000)
end
local function InstanceKind()
    local inside, kind = Call(IsInInstance)
    if Secret(inside) or Secret(kind) then return false, nil end
    return inside, kind
end
local function InPvP() local _, kind = InstanceKind(); return kind == "pvp" end
-- the battleground's name inside one, the zone outside
local function PlaceName()
    local _, kind = InstanceKind()
    if kind == "pvp" or kind == "arena" then
        local n = SafeName((Call(GetInstanceInfo)))
        if n then return n end
    end
    local n = SafeName((Call(GetRealZoneText))) or SafeName((Call(GetZoneText)))
    if n then return n end
    if C_Map and C_Map.GetBestMapForUnit and C_Map.GetMapInfo then
        local id = N(Call(C_Map.GetBestMapForUnit, "player"))
        local info = id and Call(C_Map.GetMapInfo, id)
        n = type(info) == "table" and SafeName(info.name)
        if n then return n end
    end
    return OTHER
end

local function NewPeriod(k) return { k = k, pl = {}, bg = {}, od = 0, ow = 0 } end
local function FixPeriod(P)
    P.pl = type(P.pl) == "table" and P.pl or {}
    P.bg = type(P.bg) == "table" and P.bg or {}
    for _, f in ipairs({ "m", "kb", "hk", "d", "as", "hon" }) do P.bg[f] = tonumber(P.bg[f]) or 0 end
    P.od, P.ow = tonumber(P.od) or 0, tonumber(P.ow) or 0
    return P
end
-- p.st = { a, w, s }: saved before this existed, it starts empty; a new week or season starts over
local function Stats(p)
    p.st = type(p.st) == "table" and p.st or {}
    local st = p.st
    if type(st.a) ~= "table" then st.a = NewPeriod() end
    if type(st.w) ~= "table" or st.w.k ~= Week() then st.w = NewPeriod(Week()) end
    if type(st.s) ~= "table" or st.s.k ~= Season() then st.s = NewPeriod(Season()) end
    FixPeriod(st.a); FixPeriod(st.w); FixPeriod(st.s)
    return st
end
local function EachPeriod(p, fn) local st = Stats(p); fn(st.a); fn(st.w); fn(st.s) end

-- adds n kills to a place; past the top 6, the smallest ones go to "Autres"
local function AddPlace(pl, name, n)
    pl[name] = (pl[name] or 0) + n
    local names = {}
    for k in pairs(pl) do if k ~= OTHER then names[#names + 1] = k end end
    if #names <= KEEP_PLACES then return end
    table.sort(names, function(a, b) if pl[a] ~= pl[b] then return pl[a] > pl[b] end return a < b end)
    for i = KEEP_PLACES + 1, #names do pl[OTHER] = (pl[OTHER] or 0) + pl[names[i]]; pl[names[i]] = nil end
end
-- { { name, n }, ... } most first, "Autres" last
local function SortedPlaces(pl)
    local out, other = {}, 0
    for k, v in pairs(pl or {}) do
        v = tonumber(v) or 0
        if k == OTHER then other = other + v elseif v > 0 then out[#out + 1] = { k, v } end
    end
    table.sort(out, function(a, b) if a[2] ~= b[2] then return a[2] > b[2] end return a[1] < b[1] end)
    if other > 0 then out[#out + 1] = { OTHER, other } end
    return out
end
local function KdOf(P)
    local b = P.bg
    return { b.m, b.kb, b.hk, b.d, b.as, b.hon, P.od }
end

-- the scoreboard's row of the player: { kb, hk, d, hon } (nil when there is no scoreboard)
local function MyScore()
    local n = N(Call(GetNumBattlefieldScores)) or 0
    if n <= 0 then return nil end
    local me, guid = Me(), Clean(UnitGUID and Call(UnitGUID, "player"))
    for i = 1, math.min(n, 120) do
        local name, kb, hk, d, hon, g
        if C_PvP and C_PvP.GetScoreInfo then
            local t = Call(C_PvP.GetScoreInfo, i)
            if type(t) == "table" then name, kb, hk, d, hon, g = t.name, t.killingBlows, t.honorableKills, t.deaths, t.honorGained, t.guid end
        end
        if name == nil and GetBattlefieldScore then name, kb, hk, d, hon = Call(GetBattlefieldScore, i) end
        name, g = Clean(name), Clean(g)
        if (name and Short(name) == me) or (g and guid and g == guid) then
            return { kb = N(kb) or 0, hk = N(hk) or 0, d = N(d) or 0, hon = math.floor(N(hon) or 0) }
        end
    end
end

-- The match under way: p.cur = { inst, snap = latest numbers, applied = numbers already counted,
-- counted = the match is in the count, done = the match is over }. Only the difference between
-- the latest numbers and what was already counted is added: repeated scoreboard updates count once.
local function ApplyMatch(p)
    local c = p.cur
    if not (c and c.snap) then return end
    local s, a = c.snap, c.applied or { kb = 0, hk = 0, d = 0, hon = 0, as = 0 }
    s.as = math.max(0, (s.hk or 0) - (s.kb or 0))   -- assists: honorable kills without the killing blow, an estimate
    EachPeriod(p, function(P)
        if not c.counted then P.bg.m = P.bg.m + 1 end
        for _, f in ipairs({ "kb", "hk", "d", "hon", "as" }) do P.bg[f] = math.max(0, P.bg[f] + (s[f] or 0) - (a[f] or 0)) end
    end)
    c.counted = true
    c.applied = { kb = s.kb, hk = s.hk, d = s.d, hon = s.hon, as = s.as }
end
local function TrackScore(p)
    if not InPvP() then return end
    local s = MyScore()
    if not s then return end
    local inst = PlaceName()
    -- numbers left from another match (a crash, a log out inside): counted, then a new match
    if p.cur and (p.cur.inst ~= inst or time() - (p.cur.t0 or 0) > 3 * 3600) then ApplyMatch(p); p.cur = nil end
    p.cur = p.cur or { inst = inst, t0 = time() }
    local old = p.cur.snap or {}
    -- the scoreboard only goes up during a match: lower numbers are the next match on the same
    -- battleground (its exit was missed), so the last one is counted and a new one starts
    if s.kb + s.hk + s.d > 0 and (s.kb < (old.kb or 0) or s.hk < (old.hk or 0) or s.d < (old.d or 0)) then
        ApplyMatch(p); p.cur = { inst = inst, t0 = time() }; old = {}
    end
    p.cur.snap = { kb = math.max(s.kb, old.kb or 0), hk = math.max(s.hk, old.hk or 0), d = math.max(s.d, old.d or 0), hon = math.max(s.hon, old.hon or 0) }
    if p.cur.done then ApplyMatch(p) end
end
local function EndMatch(p)
    TrackScore(p)
    if p.cur then p.cur.done = true; ApplyMatch(p) end
end
local function LeaveMatch(p)
    if p.cur and not InPvP() then ApplyMatch(p); p.cur = nil end
end

-- an enemy player was around a moment ago (target, mouseover, focus)
local lastHostile = nil
local HOSTILE_FOR = 15
local function Hostile(u)
    if not (UnitExists and UnitIsPlayer and UnitCanAttack) then return false end
    local ex = Call(UnitExists, u)
    if Secret(ex) or not ex then return false end
    local pl, atk = Call(UnitIsPlayer, u), Call(UnitCanAttack, "player", u)
    if Secret(pl) or Secret(atk) then return false end
    return pl and atk and true or false
end
local function SeeHostile(...)
    for i = 1, select("#", ...) do
        if Hostile((select(i, ...))) then lastHostile = GetTime(); return true end
    end
    return false
end
local function RecentHostile()
    if SeeHostile("target", "mouseover", "focus") then return true end
    return lastHostile ~= nil and GetTime() - lastHostile <= HOSTILE_FOR
end

-- ---------------------------------------------------------------- sharing
-- my own places and K/D/A in the shape the guild's messages give them (e.q, e.kd)
local function OwnExtra(e)
    local st = Stats(Mine())
    e.q = { a = { l = SortedPlaces(st.a.pl) }, w = { k = st.w.k, l = SortedPlaces(st.w.pl) }, s = { k = st.s.k, l = SortedPlaces(st.s.pl) } }
    e.kd = { wk = st.w.k, sk = st.s.k, a = KdOf(st.a), w = KdOf(st.w), s = KdOf(st.s), sow = st.s.ow }
    return e
end
local function OwnEntry()
    local p = Mine()
    local hk, week, season = Numbers()
    local meta = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
    local ver = meta and meta(ADDON, "Version") or "?"
    local lvl = UnitLevel("player") or 0
    local spec = WP.Weights and WP.Weights.Spec and WP.Weights.Spec()
    local specKey = spec and spec[1] or ""
    local e = OwnExtra({ wk = Week(), w = week, sk = Season(), s = season, hk = hk, kb = p.kb, week = p.week, lvl = lvl, ver = ver, spec = specKey, t = time() })
    Board()[Me()] = e
    return e
end
-- Messages stay under 255 bytes: "Q" carries the places of one period (the ones that do not fit go
-- to "Autres"), "K" the K/D/A of the three periods. Older copies ignore both.
local MAX_MSG = 240
local function PlacesMsg(per, key, list)
    local head = "Q|" .. per .. "|" .. (key or "") .. "|"
    local parts, len, other = {}, #head, 0
    for _, x in ipairs(list or {}) do
        local item = x[1] ~= OTHER and (x[1] .. ":" .. x[2]) or nil
        if item and len + #item + 1 + 12 <= MAX_MSG then parts[#parts + 1] = item; len = len + #item + 1
        else other = other + x[2] end
    end
    if other > 0 then parts[#parts + 1] = OTHER .. ":" .. other end
    return head .. table.concat(parts, ";")
end
local function KdMsg(kd)
    local t = { "K", kd.wk, kd.sk }
    for _, per in ipairs({ "a", "w", "s" }) do
        for i = 1, 7 do t[#t + 1] = math.floor(tonumber(kd[per][i]) or 0) end
    end
    t[#t + 1] = math.floor(tonumber(kd.sow) or 0)
    return table.concat(t, "|")
end
-- the messages this copy would send about its places and K/D/A (tests, /wlh debug)
function WP.GuildPvPMessages()
    local e = OwnExtra({})
    return { PlacesMsg("a", "", e.q.a.l), PlacesMsg("w", e.q.w.k, e.q.w.l), PlacesMsg("s", e.q.s.k, e.q.s.l), KdMsg(e.kd) }
end

-- Sends my line to the guild, at most every 30 s, and only when it changed (or 10 min went by):
-- opening the Home page or the ranking no longer sends 4 to 6 messages each time.
-- An "R" from a copy that just logged in is always answered (wantReply), it has nothing yet.
-- onlyChange (the Home page, the ranking tab): nothing at all unless my line changed (a level, a spec).
local lastSent, shareQueued, lastSig, wantReply = 0, false, nil, false
-- set once the login send was tried: if it could not go out (guild not known yet), the next
-- Home or ranking redraw sends my line instead of waiting for a kill
local loginTried = false
local function Messages(e)
    -- "P" for the copies before 1.0.0-beta.25, "S" with the week and the season
    local msgs = {
        table.concat({ "P", e.kb, e.week, Mine().wk, e.hk, e.lvl, e.ver }, "|"),
        table.concat({ "S", e.wk, e.w, e.sk, e.s, e.hk, e.kb, e.week, e.lvl, e.ver, e.spec }, "|"),
    }
    -- places and K/D/A: only once there is something to tell
    for _, per in ipairs({ "a", "w", "s" }) do
        local q = e.q[per]
        if #q.l > 0 then msgs[#msgs + 1] = PlacesMsg(per, q.k, q.l) end
    end
    -- K always goes out (about 50 bytes): it also tells the others this copy knows places and K/D/A
    msgs[#msgs + 1] = KdMsg(e.kd)
    return msgs, table.concat(msgs, "\n")
end
local function Share(force, onlyChange)
    if not (On() and IsInGuild and IsInGuild()) then return end
    local e = OwnEntry()   -- my line is always up to date, even between two messages
    if onlyChange then
        -- before the login send (25 s) or with a send already queued: that one covers it
        if (lastSig == nil and not loginTried) or shareQueued then return end
        local _, sig = Messages(e)
        if sig == lastSig then return end
    end
    if not force and GetTime() - lastSent < 30 then
        if not shareQueued then
            shareQueued = true
            C_Timer.After(31 - (GetTime() - lastSent), function() shareQueued = false; Share(true) end)
        end
        return
    end
    local msgs, sig = Messages(e)
    if sig == lastSig and not wantReply and GetTime() - lastSent < 600 then return end
    lastSent, lastSig, wantReply = GetTime(), sig, false
    for _, m in ipairs(msgs) do pcall(SendRaw, PREFIX, m, "GUILD") end
end
WP._GuildShare = Share   -- tests

-- an "R" is answered after a random 2 to 8 s: the copies of a full guild do not all answer at once
local replyQueued = false
local function Reply()
    wantReply = true
    if replyQueued then return end
    replyQueued = true
    C_Timer.After(2 + math.random() * 6, function() replyQueued = false; Share() end)
end

local askedAt = 0
local function Ask()
    if not (IsInGuild and IsInGuild() and SendRaw) or GetTime() - askedAt < 60 then return end
    askedAt = GetTime()
    pcall(SendRaw, PREFIX, "R", "GUILD")
end

-- a new "S" or "P" line keeps the places and K/D/A already known for that member
local function Put(sender, e)
    local b = Board()
    local old = b[sender]
    if old then e.q, e.kd = old.q, old.kd end
    b[sender] = e
end
local function OnMessage(msg, sender)
    local kind = msg:match("^(%u)")
    if kind == "R" then Reply()
    elseif kind == "S" then
        local wk, w, sk, s, hk, kb, owk, lvl, ver = msg:match("^S|([%d%-]+)|(%d+)|([%d%-]+)|(%d+)|(%d+)|(%d+)|(%d+)|(%d+)|([^|]*)")
        if wk then
            local spec = msg:match("^S|[^|]*|[^|]*|[^|]*|[^|]*|[^|]*|[^|]*|[^|]*|[^|]*|[^|]*|(%a*)")
            Put(sender, { wk = wk, w = tonumber(w), sk = sk, s = tonumber(s), hk = tonumber(hk), kb = tonumber(kb),
                week = tonumber(owk), lvl = tonumber(lvl), ver = ver, spec = spec ~= "" and spec or nil, t = time() })
            if WP.RefreshGuild then WP.RefreshGuild() end
        end
    elseif kind == "P" then
        -- an older copy: all-time total and open-world counts only (an "S" from the same player wins)
        local kb, week, wk, hk, lvl, ver = msg:match("^P|(%d+)|(%d+)|([%d%-]+)|(%d+)|(%d+)|([^|]*)$")
        local cur = Board()[sender]
        if kb and not (cur and cur.sk) then
            Put(sender, { kb = tonumber(kb), week = tonumber(week), wk = wk, hk = tonumber(hk), lvl = tonumber(lvl), ver = ver, t = time() })
            if WP.RefreshGuild then WP.RefreshGuild() end
        end
    elseif kind == "Q" then
        -- the places of one period: "Q|w|2026-11-10|Goulet des Chanteguerres:12;Hautebrande:3;~:2"
        local per, key, body = msg:match("^Q|(%a)|([%d%-]*)|(.*)$")
        if per == "a" or per == "w" or per == "s" then
            local l = {}
            for item in body:gmatch("[^;]+") do
                local name, n = item:match("^([^:]+):(%d+)$")
                -- no colours, textures or links from someone else's message
                if name ~= OTHER then name = SafeName(name) end
                if name and #l < KEEP_PLACES + 2 then l[#l + 1] = { name, Cap(n) } end
            end
            local e = Board()[sender] or { t = time() }
            Board()[sender] = e
            e.q = type(e.q) == "table" and e.q or {}
            e.q[per] = { k = key ~= "" and key or nil, l = l }
            if WP.RefreshGuild then WP.RefreshGuild() end
        end
    elseif kind == "K" then
        -- K|week|season| then for all time, the week, the season: matches, KB, HK, deaths, assists,
        -- honor, open-world deaths; then the season's open-world kills. Fields added later are ignored.
        local wk, sk, rest = msg:match("^K|([%d%-]+)|([%d%-]+)|(.*)$")
        if wk then
            local v = {}
            for x in (rest .. "|"):gmatch("([^|]*)|") do v[#v + 1] = Cap(x) end
            if #v >= 21 then
                local function seg(i)
                    local t = {}; for j = 1, 7 do t[j] = v[i + j] end
                    t[KD_M] = math.min(t[KD_M], 100000)
                    t[KD_AS] = math.min(t[KD_AS], t[KD_HK])
                    return t
                end
                local e = Board()[sender] or { t = time() }
                Board()[sender] = e
                e.kd = { wk = wk, sk = sk, a = seg(0), w = seg(7), s = seg(14), sow = v[22] or 0 }
                if WP.RefreshGuild then WP.RefreshGuild() end
            end
        end
    end
end

-- ---------------------------------------------------------------- open-world kills
-- When the game's total goes up outside a battleground or an arena, the difference is open world.
local function InWorld()
    local _, kind = InstanceKind()
    return kind ~= "pvp" and kind ~= "arena"
end
-- 12500 -> "12 500" in French, "12,500" in English (DESIGN 4.3): the summary's helper
-- (Overview.lua, a no-break space), the local fallback only if it is missing
local function Thousands(n)
    n = tonumber(n) or 0
    if root.BigNumber then return root.BigNumber(n) end
    local s = tostring(math.floor(math.abs(n) + 0.5))
    local sep = (root.lang == "en") and "," or " "
    local out = s:reverse():gsub("(%d%d%d)", "%1" .. sep):reverse()
    if out:sub(1, 1) == sep then out = out:sub(2) end
    return (n < 0 and "-" or "") .. out
end
-- the place at the moment of the kill (the count is read a second later, maybe after a teleport)
local pendingPlace, pendingWorld = nil, nil
local function NoteKillPlace()
    if pendingPlace == nil then pendingPlace, pendingWorld = PlaceName(), InWorld() end
end
local function CheckHonor(atLogin)
    local place, world = pendingPlace, pendingWorld
    pendingPlace, pendingWorld = nil, nil
    local hk = LifetimeHK()
    if hk <= 0 then return end
    local p = Mine()
    if not p.lastHK or hk < p.lastHK then p.lastHK = hk; Share(); return end   -- first look: the starting point
    local gained = hk - p.lastHK
    p.lastHK = hk
    if gained <= 0 then return end
    -- where they came from: the battleground or the zone, for all time, the week and the season;
    -- kills from before this login have no known place
    if place == nil then
        world = InWorld()
        place = atLogin == true and OTHER or PlaceName()
    end
    EachPeriod(p, function(P)
        AddPlace(P.pl, place, gained)
        if world then P.ow = P.ow + gained end
    end)
    if world then
        p.kb, p.week = (p.kb or 0) + gained, (p.week or 0) + gained
        if WLWritsDB.guildToast ~= false then
            WP.Print(p.week == 1 and L("Victoire honorable en monde ouvert : la 1re de la semaine.")
                or string.format(L("Victoire honorable en monde ouvert : ça fait %s cette semaine."), Thousands(p.week)))
        end
    end
    Share()
    if WP.RefreshGuild then WP.RefreshGuild() end
end
-- in a battleground: ask the game for the scoreboard (UPDATE_BATTLEFIELD_SCORE answers)
local askedScore = 0
local function AskScore()
    if not (RequestBattlefieldScoreData and InPvP()) or GetTime() - askedScore < 5 then return end
    askedScore = GetTime()
    Call(RequestBattlefieldScoreData)
end
-- a death outside any instance while an enemy player was around: an open-world PvP death
local function PvPDeath()
    local inside = InstanceKind()
    if inside then AskScore(); return end
    if not RecentHostile() then return end
    EachPeriod(Mine(), function(P) P.od = P.od + 1 end)
    lastHostile = nil
    Share()
    if WP.RefreshGuild then WP.RefreshGuild() end
end

-- ---------------------------------------------------------------- seasons
-- When a new month starts, the podium of the one that ended is kept.
local PER = { week = "w", season = "s", all = "a" }
-- a member's places ({ { name, n } }) and K/D/A ({ m, kb, hk, d, as, hon, od }) for a period, when known
local function PeriodData(e, mode, key)
    local per = PER[mode] or "a"
    local q = type(e.q) == "table" and type(e.q[per]) == "table" and e.q[per] or nil
    local places = q and (per == "a" or q.k == key) and q.l or nil
    local kd, k = type(e.kd) == "table" and e.kd or nil, nil
    if kd then
        if per == "a" then k = kd.a
        elseif per == "w" and kd.wk == key then k = kd.w
        elseif per == "s" and kd.sk == key then k = kd.s end
    end
    return places, type(k) == "table" and k or nil, kd and kd.sk == key and tonumber(kd.sow) or nil
end
local function Ranking(mode, key)
    local out = {}
    key = key or (mode == "week" and Week() or Season())
    for name, e in pairs(Board()) do
        local n
        if mode == "week" then n = (e.wk == key) and e.w or 0
        elseif mode == "season" then n = (e.sk == key) and e.s or 0
        else n = e.hk or 0 end
        local places, kd, sow = PeriodData(e, mode, mode ~= "all" and key or nil)
        -- open world: the total for "all", this week's for "week"; the season's from the copies that count it
        local ow = (mode == "all") and (e.kb or 0) or (mode == "week" and e.wk == Week() and e.week)
            or (mode == "season" and sow) or 0
        if (n or 0) > 0 then out[#out + 1] = { name = name, n = n, ow = ow, lvl = e.lvl, places = places, kd = kd, known = e.q ~= nil or e.kd ~= nil } end
    end
    table.sort(out, function(a, b) if a.n ~= b.n then return a.n > b.n end return a.name < b.name end)
    return out
end
local function ArchiveSeason()
    local sl, known = Seasons()
    if not known then return end   -- the guild is not known yet: nothing to archive into
    local cur = Season()
    local last = sl.key
    if last and last ~= cur then
        if not sl.list[last] then
            local top = {}
            for i, e in ipairs(Ranking("season", last)) do if i <= 3 then top[i] = { e.name, e.n } end end
            sl.list[last] = top
        end
    end
    sl.key = cur
end

-- { { name, n, ow, lvl }, ... } best first. mode: "week", "season", "all" (true = week, false = all)
function WP.GuildRanking(mode)
    if mode == true then mode = "week" elseif mode == false or mode == nil then mode = "all" end
    -- my own line fresh; a message only if it changed (Home redraws this on every guild message)
    Share(false, true)
    return Ranking(mode)
end
function WP.GuildMine() local hk, week, season = Numbers(); return week, season, hk end

-- ---------------------------------------------------------------- the roster
local ROLE_OF = { prot = "tank", holy = "heal", disc = "heal", resto = "heal", feral = "tank,dps" }
local function HasRole(spec, role)
    if not role then return true end
    if not spec then return false end
    local roles = ROLE_OF[spec] or "dps"
    return roles:find(role, 1, true) ~= nil
end
-- role and class icons: S.RoleIcon / S.ClassIcon (modern atlases, the old sheets as fallback)
local CLASSES = { "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID" }

-- returns the list, the number online, the zones of those online, and, among the members that pass
-- the other filters (online, search, class), how many have a known role (spec shared) out of how many
local function Roster(onlineOnly, filter, sort)
    local out, online, zones, known, total = {}, 0, {}, 0, 0
    if not (IsInGuild and IsInGuild() and GetNumGuildMembers) then return out, 0, zones, 0, 0 end
    filter = filter and filter ~= "" and filter:lower() or nil
    for i = 1, (GetNumGuildMembers() or 0) do
        local name, rank, _, level, _, zone, note, _, isOnline, _, class = GetGuildRosterInfo(i)
        if name then
            if isOnline then
                online = online + 1
                if zone and zone ~= "" then zones[zone] = (zones[zone] or 0) + 1 end
            end
            local short = Short(name)
            local hit = not filter or short:lower():find(filter, 1, true) or (zone or ""):lower():find(filter, 1, true)
                or (rank or ""):lower():find(filter, 1, true)
            local b0 = Board()[short]
            local classOk = not WLWritsDB.guildClass or WLWritsDB.guildClass == class
            local roleOk = HasRole(b0 and b0.spec, WLWritsDB.guildRole)
            if hit and classOk and (isOnline or not onlineOnly) then
                total = total + 1
                if b0 and b0.spec then known = known + 1 end
            end
            if hit and classOk and roleOk and (isOnline or not onlineOnly) then
                local y, m, d, h = 0, 0, 0, 0
                if not isOnline and GetGuildRosterLastOnline then y, m, d, h = GetGuildRosterLastOnline(i) end
                local b = Board()[short]
                out[#out + 1] = { name = short, rank = rank, level = level or 0, zone = zone, online = isOnline and true or false,
                    spec = b and b.spec,
                    class = class, note = note, rankIndex = select(3, GetGuildRosterInfo(i)) or 99,
                    away = ((y or 0) * 365 + (m or 0) * 30 + (d or 0)) * 24 + (h or 0) }
            end
        end
    end
    sort = sort or "level"
    table.sort(out, function(a, b)
        if a.online ~= b.online then return a.online end
        if sort == "name" then return a.name < b.name end
        if sort == "class" then
            if (a.class or "") ~= (b.class or "") then return (a.class or "") < (b.class or "") end
            if (a.spec or "") ~= (b.spec or "") then return (a.spec or "") < (b.spec or "") end
        end
        if sort == "zone" then
            local za, zb = a.online and (a.zone or "") or "", b.online and (b.zone or "") or ""
            if za ~= zb then return za < zb end
        elseif sort == "rank" then
            if a.rankIndex ~= b.rankIndex then return a.rankIndex < b.rankIndex end
        end
        if not a.online and a.away ~= b.away then return a.away < b.away end
        if a.level ~= b.level then return a.level > b.level end
        return a.name < b.name
    end)
    return out, online, zones, known, total
end
WP.GuildRoster = function(onlineOnly) local list, online = Roster(onlineOnly); return list, online end

-- ---------------------------------------------------------------- usual hours (T-66)
-- WLWritsDB.guildHours = { obs = { [week] = hex }, m = { [name] = { [week] = hex } } }
-- A week is 168 hour buckets (Monday 0h = 0, local time), one bit each, written as 42 hex digits:
-- m = the member was seen online in that hour, obs = this computer looked at the roster in it (the
-- member could only be seen then). Only weeks with a bit set are kept; 4 weeks at most.
local HOURS_WEEKS, HOURS_EVERY = 4, 300
local HEX = "0123456789abcdef"
local EMPTY_WEEK = string.rep("0", 42)
local function HoursDB()
    WLWritsDB.guildHours = WLWritsDB.guildHours or {}
    local h = WLWritsDB.guildHours
    h.obs = h.obs or {}; h.m = h.m or {}
    return h
end
-- the local week number (Monday-based) and the bucket of the hour, for a time (default now)
local function Bucket(t)
    t = t or time()
    local d = date("*t", t)
    local days = math.floor(time({ year = d.year, month = d.month, day = d.day, hour = 12 }) / 86400)
    return math.floor((days + 3) / 7), ((days + 3) % 7) * 24 + d.hour
end
local function SetBit(hex, b)
    hex = hex or EMPTY_WEEK
    local i = math.floor(b / 4) + 1
    local v = tonumber(hex:sub(i, i), 16) or 0
    local w = 2 ^ (b % 4)
    if math.floor(v / w) % 2 == 1 then return hex end
    v = v + w
    return hex:sub(1, i - 1) .. HEX:sub(v + 1, v + 1) .. hex:sub(i + 1)
end
local function HasBit(hex, b)
    local i = math.floor(b / 4) + 1
    local v = tonumber(hex:sub(i, i), 16) or 0
    return math.floor(v / 2 ^ (b % 4)) % 2 == 1
end
local hoursGen, hoursCache = 0, {}
local function PruneHours(week)
    local h = HoursDB()
    local oldest = week - HOURS_WEEKS + 1
    for wk in pairs(h.obs) do if type(wk) ~= "number" or wk < oldest then h.obs[wk] = nil end end
    for name, weeks in pairs(h.m) do
        for wk in pairs(weeks) do if type(wk) ~= "number" or wk < oldest then weeks[wk] = nil end end
        if not next(weeks) then h.m[name] = nil end
    end
end
local lastObs, lastBucket, prunedWeek = -1e9, nil, nil
-- one look at the roster: every member online gets this hour (force: no throttle)
local function ObserveHours(force)
    if not On() then return end
    if not (IsInGuild and IsInGuild() and GetNumGuildMembers and GetGuildRosterInfo) then return end
    local now = GetTime and GetTime() or 0
    local week, b = Bucket()
    local key = week * 1000 + b
    if not force and lastBucket == key and now - lastObs < HOURS_EVERY then return end
    local n = N(Call(GetNumGuildMembers)) or 0
    if n <= 0 then return end
    lastObs, lastBucket = now, key
    local h = HoursDB()
    if prunedWeek ~= week then prunedWeek = week; PruneHours(week) end
    local changed = false
    local ob = SetBit(h.obs[week], b)
    if ob ~= h.obs[week] then h.obs[week] = ob; changed = true end
    for i = 1, n do
        local ok, name, _, _, _, _, _, _, _, online = pcall(GetGuildRosterInfo, i)
        name = ok and Clean(name)
        if name and online and not Secret(online) then
            local short = Short(name)
            local weeks = h.m[short] or {}
            h.m[short] = weeks
            local nb = SetBit(weeks[week], b)
            if nb ~= weeks[week] then weeks[week] = nb; changed = true end
        end
    end
    -- only a new bit makes the usual hours stale (most looks within an hour change nothing)
    if changed then hoursGen = hoursGen + 1 end
end
WP.GuildObserveHours = ObserveHours
-- the usual hours of a member: { { from, to } } (hours of the day, to excluded, may wrap past
-- midnight), at most 2 ranges, earliest first; "all" when every hour qualifies; nil without enough
-- data. An hour counts when the member was seen in it on 2 days or more, on at least 40 % of the
-- days this computer looked, and at least half as often as in the member's busiest hour.
-- the hours this computer looked, shared by every member: per hour of the day, how many days, and
-- the list of { week, bucket } looked at; rebuilt once per hoursGen (or when the week turns)
local obsGen, obsWeek, obsCount, obsList = -1, nil, nil, nil
local function ObsCounts(cur)
    if obsGen == hoursGen and obsWeek == cur then return obsCount, obsList end
    obsCount, obsList = {}, {}
    for hr = 0, 23 do obsCount[hr] = 0 end
    for wk, hex in pairs(HoursDB().obs) do
        if type(wk) == "number" and wk > cur - HOURS_WEEKS and type(hex) == "string" then
            for b = 0, 167 do
                if HasBit(hex, b) then
                    local hr = b % 24
                    obsCount[hr] = obsCount[hr] + 1
                    obsList[#obsList + 1] = { wk, b }
                end
            end
        end
    end
    obsGen, obsWeek = hoursGen, cur
    return obsCount, obsList
end
local function HoursRanges(name)
    if type(name) ~= "string" or Secret(name) then return nil end
    name = Short(name)
    local c = hoursCache[name]
    if c and c.gen == hoursGen then return c.r end
    local h = HoursDB()
    local weeks = h.m[name]
    local r
    if weeks then
        local seen, total, peak = {}, 0, 0
        for hr = 0, 23 do seen[hr] = 0 end
        local obs, list = ObsCounts((Bucket()))
        for _, e in ipairs(list) do
            local mine = weeks[e[1]]
            if type(mine) == "string" and HasBit(mine, e[2]) then
                local hr = e[2] % 24
                seen[hr] = seen[hr] + 1; total = total + 1
            end
        end
        for hr = 0, 23 do if seen[hr] > peak then peak = seen[hr] end end
        if total >= 3 then
            local ok, all = {}, true
            for hr = 0, 23 do
                ok[hr] = seen[hr] >= 2 and obs[hr] > 0 and seen[hr] / obs[hr] >= 0.4 and seen[hr] * 2 >= peak
                if not ok[hr] then all = false end
            end
            if all then r = "all"
            else
                -- runs of qualifying hours, around midnight too: start after a hole
                local start
                for hr = 0, 23 do if not ok[hr] then start = hr end end
                local runs, cur2 = {}, nil
                for k = 1, 24 do
                    local hr = (start + k) % 24
                    if ok[hr] then
                        if cur2 then cur2.len = cur2.len + 1 else cur2 = { from = hr, len = 1 } end
                    elseif cur2 then runs[#runs + 1] = cur2; cur2 = nil end
                end
                if cur2 then runs[#runs + 1] = cur2 end
                table.sort(runs, function(a, b) if a.len ~= b.len then return a.len > b.len end return a.from < b.from end)
                if #runs > 0 then
                    r = {}
                    for i = 1, math.min(2, #runs) do r[i] = { runs[i].from, (runs[i].from + runs[i].len) % 24 } end
                    table.sort(r, function(a, b) return a[1] < b[1] end)
                end
            end
        end
    end
    hoursCache[name] = { gen = hoursGen, r = r }
    return r
end
WP.GuildHoursRanges = HoursRanges
-- "Souvent là : 20h–23h" (EN "Often on: 20:00–23:00"), or nil
function WP.GuildHours(name)
    local r = HoursRanges(name)
    if not r then return nil end
    if r == "all" then return string.format(L("Souvent là : %s"), L("à toute heure")) end
    local parts = {}
    for i, x in ipairs(r) do
        parts[i] = string.format(L("%dh"), x[1]) .. "\226\128\147" .. string.format(L("%dh"), x[2])   -- an en dash
    end
    return string.format(L("Souvent là : %s"), table.concat(parts, ", "))
end

-- ---------------------------------------------------------------- the window
-- 640 wide (a wide tool: filters and four columns). The height follows the content (f:FitHeight);
-- the list scrolls inside the window only once it reached 80 % of the screen.
local W, PAD = 640, 16
local CW = W - 2 * PAD          -- content width
local ROW_H, ROW_GAP = 36, 0    -- zebra list: rows touch
local win, tabs, current = nil, nil, "members"
local pages, ui = {}, {}
local F = S.F

local function ClassColor(class)
    local c = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
    return c and { c.r, c.g, c.b } or C.fg
end
local function ClassName(class)
    return (LOCALIZED_CLASS_NAMES_MALE and class and LOCALIZED_CLASS_NAMES_MALE[class]) or class or ""
end
local function Ago(hours)
    if hours >= 48 then return string.format(L("il y a %d j"), math.floor(hours / 24)) end
    if hours >= 24 then return L("hier") end
    if hours < 1 then return L("il y a moins d'1 h") end
    return string.format(L("il y a %d h"), math.max(1, hours))
end
local function Professions(name)
    local d = WP.Orders and WP.Orders.DB and WP.Orders.DB()
    local profs = d and d.crafters and d.crafters[name]
    local t = {}
    for prof, p in pairs(profs or {}) do t[#t + 1] = prof .. (p.rank and p.rank > 0 and (" " .. p.rank) or "") end
    table.sort(t)
    return table.concat(t, ", ")
end

local function SpecName(class, key)
    local list = key and WP.Weights and WP.Weights.SPECS and WP.Weights.SPECS[class]
    for _, sp in ipairs(list or {}) do
        if sp[1] == key then return (root.lang == "en") and sp[3] or sp[2] end
    end
end

local function Whisper(name)
    if ChatFrame_OpenChat then ChatFrame_OpenChat("/w " .. name .. " ")
    elseif ChatFrameUtil and ChatFrameUtil.OpenChat then ChatFrameUtil.OpenChat("/w " .. name .. " ") end
end
-- through the shared invite (SharedQuests): it says in the chat why the game would refuse (not the
-- leader, party full, already grouped). Returns how many invites went out.
local function InviteName(name)
    if WP.Shared and WP.Shared.Invite then
        local ok, n = pcall(WP.Shared.Invite, { name })
        return ok and tonumber(n) or 0
    end
    local invite = (C_PartyInfo and C_PartyInfo.InviteUnit) or InviteUnit
    if invite and pcall(invite, name) then return 1 end
    return 0
end

local function Num(v) return type(v) == "number" and not (root.IsSecret and root.IsSecret(v)) and v or nil end
local function TextW(fs) return root.TextWidth(fs) end
local function Place(obj, x, y)
    obj:ClearAllPoints(); obj:SetPoint("TOPLEFT", x, -y)
end
local function Zebra(tex, i)
    local z = (i % 2 == 0) and C.zebraB or C.zebraA
    tex:SetColorTexture(z[1], z[2], z[3], z[4])
end

-- A member: online dot, level, class icon, name in the class colour, the WL logo (has the addon),
-- the role of the shared spec, zone or last seen, rank. Invite takes the rank's place on hover.
local COL = { dot = 8, lvl = 22, cls = 52, name = 80, logo = 200, role = 218, zone = 242 }
local RANK_W = 120
local ZONE_W = CW - COL.zone - 12 - RANK_W - 8

local function MemberRow(parent)
    local r = CreateFrame("Button", nil, parent)
    r.wlOwned = true
    r:SetSize(CW, ROW_H)
    r:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    r.bg = S.Solid(r, "BACKGROUND", C.zebraA); r.bg:SetAllPoints()
    r.hl = S.Solid(r, "BORDER", C.hoverFill); r.hl:SetAllPoints(); r.hl:SetAlpha(0)
    r.press = S.Solid(r, "BORDER", C.pressFill); r.press:SetAllPoints(); r.press:Hide()
    r.dot = S.Icon(r, "dot", 10, "ARTWORK", C.ok); r.dot:SetPoint("LEFT", COL.dot, 0)
    r.lvl = S.Text(r, F.label, C.muted); r.lvl:SetPoint("LEFT", COL.lvl, 0); r.lvl:SetWidth(24); r.lvl:SetJustifyH("RIGHT")
    S.ClampLabel(r.lvl, nil, r)
    r.cls = r:CreateTexture(nil, "ARTWORK"); r.cls:SetSize(20, 20); r.cls:SetPoint("LEFT", COL.cls, 0)
    r.name = S.Text(r, F.label, C.fg); r.name:SetPoint("LEFT", COL.name, 0); r.name:SetWidth(COL.logo - COL.name - 4)
    S.ClampLabel(r.name, nil, r)
    r.logo = r:CreateTexture(nil, "ARTWORK"); r.logo:SetSize(14, 14); r.logo:SetTexture(S.LOGO); r.logo:SetPoint("LEFT", COL.logo, 0)
    r.role = r:CreateTexture(nil, "ARTWORK"); r.role:SetSize(16, 16); r.role:SetPoint("LEFT", COL.role, 0)
    r.where = S.Text(r, F.label, C.muted); r.where:SetPoint("LEFT", COL.zone, 0); r.where:SetWidth(ZONE_W)
    S.ClampLabel(r.where, nil, r)
    r.rank = S.Text(r, F.label, C.muted); r.rank:SetPoint("RIGHT", -12, 0); r.rank:SetWidth(RANK_W); r.rank:SetJustifyH("RIGHT")
    S.ClampLabel(r.rank, nil, r)
    r.inv = S.Button(r, L("Inviter"), 0, 24, "secondary", function(self)
        local mm = r.m
        if mm and mm.online then
            if InviteName(mm.name) > 0 then self:Flash(L("Invité")) end
        end
    end)
    -- labelled: no plus beside "Inviter" (icon audit G3)
    r.inv:SetPoint("RIGHT", -8, 0); r.inv:Hide()
    local function Hover(on)
        root.Tween(r, r.hov or 0, on and 1 or 0, 0.10, function(v) r.hov = v; r.hl:SetAlpha(v) end)
    end
    local function Out()
        if r:IsMouseOver() then return end
        Hover(false)
        r.inv:Hide(); r.rank:Show()
    end
    r.inv:HookScript("OnLeave", Out)
    r:SetScript("OnEnter", function(self)
        Hover(true)
        local m = self.m
        if not m then return end
        local other = m.online and m.name ~= Me()
        if other then r.inv:Show(); r.rank:Hide() end
        local sp = SpecName(m.class, m.spec)
        local c = ClassColor(m.class)
        local lines = { { m.name, c[1], c[2], c[3] } }
        lines[#lines + 1] = string.format(L("Niv. %s, %s"), m.level or "?", ClassName(m.class) .. (sp and (" " .. sp) or ""))
        lines[#lines + 1] = m.online and string.format(L("En ligne : %s"), (m.zone and m.zone ~= "") and m.zone or "?")
            or string.format(L("Vu %s"), Ago(m.away))
        local usual = WP.GuildHours(m.name)
        if usual then lines[#lines + 1] = usual end
        if m.rank and m.rank ~= "" then lines[#lines + 1] = string.format(L("Rang : %s"), m.rank) end
        if m.note and m.note ~= "" then lines[#lines + 1] = string.format(L("Note : %s"), m.note) end
        local profs = Professions(m.name)
        if profs ~= "" then lines[#lines + 1] = string.format(L("Métiers : %s"), profs) end
        if self.addon then lines[#lines + 1] = self.ver and string.format(L("Utilise WL Helper (version %s)"), self.ver) or L("Utilise WL Helper") end
        if other then
            lines[#lines + 1] = L("Clic : chuchoter")
            lines[#lines + 1] = L("Clic droit : inviter dans ton groupe")
        end
        S.Tip(self, lines)
    end)
    r:SetScript("OnLeave", function() S.HideTip(); Out() end)
    r:SetScript("OnMouseDown", function(self) self.press:Show() end)
    r:SetScript("OnMouseUp", function(self) self.press:Hide() end)
    r:SetScript("OnClick", function(self, button)
        local m = self.m
        if not (m and m.online) or m.name == Me() then return end
        if button == "RightButton" or IsAltKeyDown() then
            if InviteName(m.name) > 0 then r.inv:Flash(L("Invité")) end
        else Whisper(m.name) end
    end)
    return r
end

-- A pooled list inside a scroll area: l.Get(i) gives the i-th row (made by `make` once).
local function List(parent, make)
    local sa = S.ScrollArea(parent)
    local l = { sa = sa, content = sa.child, items = {} }
    function l.Get(i) local f = l.items[i]; if not f then f = make(sa.child); l.items[i] = f end; f:Show(); return f end
    function l.HideFrom(i) for j = i, #l.items do l.items[j]:Hide() end end
    return l
end

-- Anchors a list under the fixed part of a page (y from the page top) down to the page bottom.
local function PlaceList(l, page, y)
    l.sa:ClearAllPoints()
    l.sa:SetPoint("TOPLEFT", page, "TOPLEFT", PAD, -y)
    l.sa:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -PAD, 12)
    l.sa.child:SetWidth(CW)
end

-- a zone as a pill you can click (it filters the list through the search)
local function ZoneChip(parent)
    local c = CreateFrame("Button", nil, parent)
    c.wlOwned = true
    c:SetHeight(F.meta + 7)
    c.bg = S.Solid(c, "BACKGROUND", { 1, 1, 1, 0.10 }); c.bg:SetAllPoints()
    c.edge = S.Border(c, { 1, 1, 1 }, 0.20)
    c.label = S.Text(c, F.meta, C.fg); c.label:SetPoint("LEFT", 6, 0)
    S.ClampLabel(c.label, nil, c)
    function c:Paint()
        local on, hov = self.on, self.hov
        if on then
            self.bg:SetColorTexture(C.selFill[1], C.selFill[2], C.selFill[3], C.selFill[4]); self.edge(C.accent, 1)
        else
            self.bg:SetColorTexture(1, 1, 1, hov and 0.16 or 0.10); self.edge({ 1, 1, 1 }, hov and 0.40 or 0.20)
        end
    end
    c:SetScript("OnClick", function(self)
        local cur = ui.search:GetText() or ""
        ui.search:SetText(cur == self.zone and "" or self.zone)
        WP.RefreshGuild()
    end)
    c:SetScript("OnEnter", function(self)
        self.hov = true; self:Paint()
        S.Tip(self, { self.zone, self.n == 1 and L("1 membre en ligne ici") or string.format(L("%d membres en ligne ici"), self.n),
            self.on and L("Clic : montrer toutes les zones") or L("Clic : ne montrer que cette zone") })
    end)
    c:SetScript("OnLeave", function(self) self.hov = nil; self:Paint(); S.HideTip() end)
    return c
end

local function ClearFilters()
    WLWritsDB.guildClass = nil; WLWritsDB.guildRole = nil
    if ui.search then ui.search:SetText("") end
    if ui.role then ui.role:Update() end
    WP.RefreshGuild()
end

local function RenderMembers()
    local m = pages.members
    local inGuild = IsInGuild and IsInGuild()
    -- not in a guild: one empty state, nothing else
    for _, w in ipairs(ui.memberControls) do w:SetShown(inGuild and true or false) end
    if not inGuild then
        ui.members.sa:Hide(); ui.noMatch:Hide()
        for _, c in ipairs(ui.zoneChips) do c:Hide() end
        ui.noGuild:Show()
        win:FitHeight(12 + ui.noGuild:Fit())
        return
    end
    ui.noGuild:Hide(); ui.members.sa:Show()
    -- the class buttons: the selected one has the selection fill and an accent edge
    for _, b in ipairs(ui.classBtns) do
        b.on = b.cls == WLWritsDB.guildClass
        b:Paint()
    end
    local searchText = ui.search:GetText() or ""
    local list, online, zones, known, total = Roster(WLWritsDB.guildOnline ~= false, searchText, WLWritsDB.guildSort)
    local all = GetNumGuildMembers() or 0
    ui.count:SetText(online == 1 and string.format(L("1 membre en ligne sur %d"), all)
        or string.format(L("%d membres en ligne sur %d"), online, all))
    ui.role:Update()
    local filtered = WLWritsDB.guildClass ~= nil or WLWritsDB.guildRole ~= nil or searchText ~= ""
    local roleOn = WLWritsDB.guildRole ~= nil

    -- the line under the filters: where the guild is (zones as pills), or, with a role filter, how
    -- many members have a known role; "Clear filters" on the right when a filter is on
    local y = ui.filtersBottom + 12
    -- with no match, the empty state carries "Enlever les filtres": one such button, not two
    local showClear = filtered and #list > 0
    ui.clear:SetShown(showClear)
    local rightW = showClear and (TextW(ui.clear.label) + 24 + 22 + 12) or 0
    local lineH = 0
    if roleOn then
        for _, c in ipairs(ui.zoneChips) do c:Hide() end
        ui.zonesLabel:Hide()
        ui.roleInfo:Show()
        ui.roleInfo:SetText((known or 0) == 0
            and string.format(L("Aucun rôle connu parmi ces %d membres : seuls ceux qui ont WL Helper et ont choisi leur spé le partagent."), total or 0)
            or known == 1
            and string.format(L("Rôle connu pour 1 membre sur %d : seuls ceux qui ont WL Helper et ont choisi leur spé le partagent."), total or 0)
            or string.format(L("Rôle connu pour %d membres sur %d : seuls ceux qui ont WL Helper et ont choisi leur spé le partagent."), known or 0, total or 0))
        Place(ui.roleInfo, PAD + 20, y)
        lineH = math.max(16, S.FitText(ui.roleInfo, 2, CW - 20 - rightW, ui.roleInfoOwner))
        Place(ui.roleIcon, PAD, y)
    else
        ui.roleInfo:Hide(); ui.roleIcon:Hide()
        local z = {}
        for name, n in pairs(zones) do z[#z + 1] = { name, n } end
        table.sort(z, function(a, b) if a[2] ~= b[2] then return a[2] > b[2] end return a[1] < b[1] end)
        ui.zonesLabel:SetShown(#z > 0)
        local zx = PAD
        if #z > 0 then
            Place(ui.zonesLabel, PAD, y + 3)
            zx = PAD + TextW(ui.zonesLabel) + 8
            lineH = F.meta + 7
        end
        local limit = W - PAD - rightW
        local stop = false
        for i = 1, 5 do
            local c = ui.zoneChips[i]
            if not c and z[i] then c = ZoneChip(m); ui.zoneChips[i] = c end
            if c then
                if z[i] and not stop then
                    c.zone, c.n = z[i][1], z[i][2]
                    c.label:SetText(c.zone .. "  " .. c.n)
                    local w = TextW(c.label) + 12
                    if zx + w > limit and i > 1 then
                        stop = true; c:Hide()     -- no room left on the line: the next ones stay hidden
                    else
                        w = math.min(w, limit - zx)
                        c.label:SetWidth(math.max(1, w - 12))
                        c:SetWidth(w)
                        Place(c, zx, y)
                        c.on = searchText == c.zone
                        c:Paint(); c:Show()
                        zx = zx + w + 4
                    end
                else
                    c:Hide()
                end
            end
        end
    end
    if showClear then
        ui.clear:ClearAllPoints(); ui.clear:SetPoint("TOPRIGHT", m, "TOPRIGHT", -PAD, -(y - 3))
        lineH = math.max(lineH, 18)
    end
    if lineH > 0 then y = y + lineH end
    -- column heads, then the list
    y = y + 12
    for _, h in ipairs(ui.heads) do h:ClearAllPoints() end
    ui.heads[1]:SetPoint("TOPRIGHT", m, "TOPLEFT", PAD + COL.lvl + 24, -y)
    ui.heads[2]:SetPoint("TOPLEFT", m, "TOPLEFT", PAD + COL.name, -y)
    ui.heads[3]:SetPoint("TOPLEFT", m, "TOPLEFT", PAD + COL.zone, -y)
    ui.heads[4]:SetPoint("TOPRIGHT", m, "TOPRIGHT", -PAD - 12, -y)
    y = y + F.meta + 6
    local top = y

    local board = Board()
    for i, mm in ipairs(list) do
        local r = ui.members.Get(i)
        Place(r, 0, (i - 1) * (ROW_H + ROW_GAP))
        Zebra(r.bg, i)
        r.m = mm
        local col = ClassColor(mm.class)
        r.addon = board[mm.name] ~= nil
        r.ver = board[mm.name] and board[mm.name].ver
        r.logo:SetShown(r.addon)
        if r.clsKey ~= mm.class then
            r.clsKey = mm.class
            r.clsOk = S.ClassIcon(r.cls, mm.class)
        end
        r.cls:SetShown(r.clsOk and true or false)
        r.cls:SetAlpha(mm.online and 1 or 0.55)
        r.name:SetText(mm.name)
        r.name:SetTextColor(col[1], col[2], col[3], mm.online and 1 or 0.55)
        -- the role icon of the shared spec (a feral druid shows as tank, its first role)
        if mm.spec then
            local ro = (ROLE_OF[mm.spec] or "dps"):match("^(%a+)")
            if r.roleKey ~= ro then r.roleKey = ro; S.RoleIcon(r.role, ro) end
            r.role:Show()
        else
            r.role:Hide()
        end
        r.inv:Hide(); r.rank:Show()
        r.lvl:SetText(mm.level)
        local dc = mm.online and C.ok or C.faint
        r.dot:SetVertexColor(dc[1], dc[2], dc[3])
        r.where:SetText(mm.online and (mm.zone or "") or Ago(mm.away))
        local wc = mm.online and C.text or C.muted
        r.where:SetTextColor(wc[1], wc[2], wc[3])
        r.rank:SetText(mm.rank or "")
    end
    ui.members.HideFrom(#list + 1)
    local listH = #list * (ROW_H + ROW_GAP)
    -- nobody passes the filters: an empty state where the list would be
    ui.noMatch:SetShown(#list == 0)
    if #list == 0 then
        local sub
        -- with a role filter the line above already says why (how many roles are known): not twice
        if roleOn then sub = nil
        elseif searchText ~= "" then sub = L("La recherche porte sur le nom, la zone et le rang.")
        elseif WLWritsDB.guildOnline ~= false then sub = L("Personne d'autre n'est en ligne avec ces filtres.") end
        local hasFilter = filtered
        ui.noMatch:Set("search", L("Aucun membre ne correspond"), sub, hasFilter and L("Enlever les filtres") or nil,
            hasFilter and ClearFilters or nil, "secondary")
        ui.noMatch:ClearAllPoints(); ui.noMatch:SetPoint("TOP", m, "TOPLEFT", W / 2, -(top + 12))
        listH = 12 + ui.noMatch.blockH
        for _, h in ipairs(ui.heads) do h:Hide() end
    else
        for _, h in ipairs(ui.heads) do h:Show() end
    end
    PlaceList(ui.members, m, top)
    ui.members.sa:SetContentHeight(#list * (ROW_H + ROW_GAP))
    win:FitHeight(top - 12 + listH)
end

local function RankRow(parent)
    local r = S.ListRow(parent, { density = "dense" })
    r.valueW = 56
    r:SetWidth(CW)
    return r
end

-- ---------------------------------------------------------------- places and K/D/A, in words
local SEP = " \194\183 "   -- " · "
local function PlaceLabel(name) return name == OTHER and L("Autres") or name end
local function Ratio(kb, d)
    local s = string.format("%.1f", (kb or 0) / d)
    return root.lang == "en" and s or (s:gsub("%.", ","))
end
local function Deaths(n) return n == 1 and L("1 mort") or string.format(L("%s morts"), Thousands(n)) end
local function Blows(n) return n == 1 and L("1 coup fatal") or string.format(L("%s coups fatals"), Thousands(n)) end
-- as many parts as fit on one line of `width`; a part too wide is left to the tooltip.
-- `inOrder`: stop at the first one that does not fit (places, most first)
local function FitParts(parts, width, inOrder)
    local out = {}
    for _, t in ipairs(parts) do
        local try = #out == 0 and t or (table.concat(out, SEP) .. SEP .. t)
        ui.measure:SetText(try)
        if TextW(ui.measure) <= width then out[#out + 1] = t
        elseif inOrder then break end
    end
    ui.measure:SetText("")
    return #out > 0 and table.concat(out, SEP) or nil
end
local function BgLine(kd)
    if not (kd and (kd[KD_M] or 0) > 0) then return nil end
    -- in words, no KB / K/D/A codes; the assists (an estimate) stay in the tooltip
    return string.format(L("Champs de bataille : %s, %s"), Blows(kd[KD_KB] or 0), Deaths(kd[KD_D] or 0))
end
local function WorldLine(ow, kd)
    local od = kd and kd[KD_OD] or 0
    if od > 0 then return string.format(L("Monde ouvert : %s VH, %s"), Thousands(ow or 0), Deaths(od)) end
    if (ow or 0) > 0 then return string.format(L("dont %s en monde ouvert"), Thousands(ow)) end
end
-- the row's muted lines: where the kills come from, then the K/D/A (what does not fit is in the tooltip)
local function RowDetail(e, width)
    local first, second = nil, {}
    local places = {}
    for _, x in ipairs(e.places or {}) do places[#places + 1] = PlaceLabel(x[1]) .. " " .. Thousands(x[2]) end
    local world = WorldLine(e.ow, e.kd)
    if #places > 0 then first = FitParts(places, width, true) elseif world then first = FitParts({ world }, width); world = nil end
    second[#second + 1] = BgLine(e.kd)
    second[#second + 1] = world
    local line2 = #second > 0 and FitParts(second, width) or nil
    if first and line2 then return first .. "\n" .. line2 end
    return first or line2
end
local function RowTip(e)
    local fg, mu = C.fg, C.muted
    local t = { e.name, e.n == 1 and L("1 victoire honorable") or string.format(L("%s victoires honorables"), Thousands(e.n)) }
    local places, kd = e.places or {}, e.kd
    if #places > 0 then
        t[#t + 1] = { gap = true }
        t[#t + 1] = { L("D'où viennent les victoires :"), fg[1], fg[2], fg[3] }
        local sum = 0
        for _, x in ipairs(places) do t[#t + 1] = { PlaceLabel(x[1]), mu[1], mu[2], mu[3], right = Thousands(x[2]) }; sum = sum + x[2] end
        if sum < e.n then
            t[#t + 1] = string.format(L("Lieux suivis depuis la mise à jour : %s victoires sur %s."), Thousands(sum), Thousands(e.n))
        end
    end
    if kd and (kd[KD_M] or 0) > 0 then
        local m = kd[KD_M]
        t[#t + 1] = { gap = true }
        t[#t + 1] = { m == 1 and L("Champs de bataille, 1 partie") or string.format(L("Champs de bataille, %s parties"), Thousands(m)), fg[1], fg[2], fg[3] }
        t[#t + 1] = { L("Coups fatals"), mu[1], mu[2], mu[3], right = Thousands(kd[KD_KB]) }
        t[#t + 1] = { L("Morts"), mu[1], mu[2], mu[3], right = Thousands(kd[KD_D]) }
        t[#t + 1] = { L("Assistances (estimation)"), mu[1], mu[2], mu[3], right = Thousands(kd[KD_AS]) }
        if (kd[KD_D] or 0) > 0 then t[#t + 1] = { L("Coups fatals par mort"), mu[1], mu[2], mu[3], right = Ratio(kd[KD_KB], kd[KD_D]) } end
        if (kd[KD_HON] or 0) > 0 then t[#t + 1] = { L("Honneur gagné"), mu[1], mu[2], mu[3], right = Thousands(kd[KD_HON]) } end
        t[#t + 1] = L("Assistances : victoires honorables moins coups fatals, lues au tableau des scores. Une estimation.")
    end
    local od = kd and kd[KD_OD] or 0
    if (e.ow or 0) > 0 or od > 0 then
        t[#t + 1] = { gap = true }
        t[#t + 1] = { L("Monde ouvert"), fg[1], fg[2], fg[3] }
        t[#t + 1] = { L("Victoires honorables"), mu[1], mu[2], mu[3], right = Thousands(e.ow or 0) }
        if kd then t[#t + 1] = { L("Morts face à un joueur"), mu[1], mu[2], mu[3], right = Thousands(od) } end
        t[#t + 1] = L("Les coups fatals en monde ouvert restent invisibles aux addons.")
    end
    if not e.known then
        t[#t + 1] = { gap = true }
        t[#t + 1] = L("Lieux, coups fatals et morts : visibles quand ce membre aura la dernière version de WL Helper.")
    end
    return t
end

local function RenderPvP()
    ArchiveSeason()
    local p = pages.pvp
    local mode = WLWritsDB.guildRankMode or "week"
    Share(false, true)
    local list = Ranking(mode)
    local w, s, hk = WP.GuildMine()
    -- a word pill: the calendar icon only repeated "Saison"
    ui.seasonPill:Set(string.format(L("Saison %s"), SeasonName(Season())))
    local y = 12 + 28 + 12
    Place(ui.mine, PAD, y)
    -- my numbers first (the unit named once: "VH" is the unit of the list below), then, one size
    -- down, my battlegrounds over the selected period, in words
    ui.mine:SetText(string.format(L("Tes victoires honorables (VH) : %s cette semaine, %s cette saison, %s au total."), Thousands(w), Thousands(s), Thousands(hk)))
    y = y + S.FitText(ui.mine, 2, CW, p)
    local mine = Board()[Me()]
    local _, myKd = PeriodData(mine or {}, mode, mode == "week" and Week() or mode == "season" and Season() or nil)
    if myKd and (myKd[KD_M] or 0) > 0 then
        local body = Blows(myKd[KD_KB] or 0) .. ", " .. Deaths(myKd[KD_D] or 0)
        if (myKd[KD_D] or 0) > 0 then body = body .. " (" .. string.format(L("ratio %s"), Ratio(myKd[KD_KB], myKd[KD_D])) .. ")" end
        local fmt = mode == "week" and L("En champ de bataille cette semaine : %s.")
            or mode == "season" and L("En champ de bataille cette saison : %s.") or L("En champ de bataille depuis toujours : %s.")
        ui.mineKd:SetText(string.format(fmt, body))
        y = y + 3
        Place(ui.mineKd, PAD, y)
        y = y + S.FitText(ui.mineKd, 2, CW, p)
        ui.mineKd:Show()
    else
        ui.mineKd:SetText(""); ui.mineKd:Hide()
    end
    -- the last season's podium
    local past, pastKey = Seasons().list, nil
    for k in pairs(past or {}) do if not pastKey or k > pastKey then pastKey = k end end
    if pastKey and #past[pastKey] > 0 then
        local t = {}
        for i, e in ipairs(past[pastKey]) do t[#t + 1] = i .. ". " .. e[1] .. " (" .. Thousands(e[2]) .. " " .. L("VH") .. ")" end
        -- no star before it: it was decoration (icon audit, Guild)
        ui.past:SetText(string.format(L("Saison précédente (%s) : %s"), SeasonName(pastKey), table.concat(t, ", ")))
        y = y + 4
        Place(ui.past, PAD, y)
        y = y + S.FitText(ui.past, 2, CW, p)
        ui.past:Show()
    else
        ui.past:SetText(""); ui.past:Hide()
    end
    y = y + 12
    local top = y
    local me = Me()
    local listH = 0
    for i, e in ipairs(list) do
        local r = ui.rank.Get(i)
        Zebra(r.bg, i)
        -- the text column of the row (S.ListRow: rank 8 + 24 + 4 on the left; value 56, unit and gaps on the right)
        ui.measure:SetText(L("VH"))
        local textW = CW - 36 - (12 + TextW(ui.measure) + 4 + 56 + 8)
        local detail = RowDetail(e, textW)
        r:Set({ rank = i, name = e.name == me and string.format(L("%s (toi)"), e.name) or e.name, detail = detail,
            value = Thousands(e.n), unit = L("VH"), tip = RowTip(e) })
        r:SetSelected(e.name == me)
        local h = r:Fit(CW)
        Place(r, 0, listH)
        listH = listH + h
    end
    ui.rank.HideFrom(#list + 1)
    ui.none:SetShown(#list == 0)
    if #list == 0 then
        ui.none:Set("sword", mode == "week" and L("Aucune victoire cette semaine")
            or mode == "season" and L("Aucune victoire cette saison") or L("Aucune victoire pour l'instant"),
            L("Les victoires honorables des membres qui ont WL Helper apparaîtront ici."))
        ui.none:ClearAllPoints(); ui.none:SetPoint("TOP", p, "TOPLEFT", W / 2, -(top + 12))
        PlaceList(ui.rank, p, top)
        ui.rank.sa:SetContentHeight(0)
        win:FitHeight(top - 12 + 12 + ui.none.blockH)
        return
    end
    PlaceList(ui.rank, p, top)
    ui.rank.sa:SetContentHeight(listH)
    win:FitHeight(top - 12 + listH)
end

-- the header's info icon: what the current tab shows, in words
local function InfoTip()
    if current == "keys" and WP.Keys and WP.Keys.GuildTip then return WP.Keys.GuildTip() end
    if current == "pvp" then
        return { L("Classement PvP"), L("Les victoires honorables comptées par le jeu, champs de bataille compris."),
            L("Une saison dure un mois : le podium de la saison passée reste affiché."),
            L("Seuls les membres qui ont WL Helper apparaissent.") }
    end
    return { L("Membres"), L("La liste vient du jeu. Le rôle vient de la spé que chaque membre a choisie dans WL Helper."),
        L("Le logo WL marque les membres qui ont WL Helper.") }
end

local function Build()
    win = S.Window("WLHelperGuild", W, 520, L("Guilde"), GetGuildInfo and GetGuildInfo("player") or nil, WLWritsDB, "guildPos",
        { header = S.HEADER_H, minH = 240 })
    win:AddHeaderButton(S.IconButton(win.header, "info", 28, InfoTip))
    local tabList = { { "members", L("Membres") }, { "pvp", L("Classement PvP") } }
    -- the keys tab exists only when Writs/Keys.lua is loaded (it draws the tab and shares the keys)
    if WP.Keys and WP.Keys.RenderGuildTab then tabList[#tabList + 1] = { "keys", L("Qui a la clé ?") } end
    tabs = S.Tabs(win, tabList, function() return current end, function(k) WP.ShowGuildTab(k) end)
    tabs:SetPoint("TOPLEFT", 0, -(S.HEADER_H + 1)); tabs:SetPoint("TOPRIGHT", 0, -(S.HEADER_H + 1))
    for _, t in ipairs(tabList) do
        local k = t[1]
        local p = CreateFrame("Frame", nil, win)
        p:SetPoint("TOPLEFT", 0, -win:ContentTop()); p:SetPoint("BOTTOMRIGHT")
        p:Hide(); pages[k] = p
    end

    -- members
    local m = pages.members
    ui.memberControls = {}
    local function Keep(w) ui.memberControls[#ui.memberControls + 1] = w; return w end
    -- line 1: how many are on, and the "online only" switch (the whole label is the click target)
    ui.count = Keep(S.Text(m, F.body, C.text)); ui.count:SetPoint("TOPLEFT", PAD, -18)
    ui.count:SetWidth(CW - 220); S.ClampLabel(ui.count, nil, m)
    local onlyRow = Keep(CreateFrame("Button", nil, m))
    onlyRow:SetHeight(28)
    local onlyText = S.Text(onlyRow, F.body, C.fg); onlyText:SetWordWrap(false); onlyText:SetText(L("En ligne seulement"))
    onlyText:SetPoint("LEFT", 0, 0)
    local only = S.Switch(onlyRow, function() return WLWritsDB.guildOnline ~= false end,
        function(v) WLWritsDB.guildOnline = v; WP.RefreshGuild() end,
        { L("En ligne seulement"), L("Allumé, la liste cache les membres hors ligne."), L("Clic : allumer ou éteindre") })
    only:SetPoint("RIGHT", 0, 0)
    only:AttachRow(onlyRow)
    onlyRow:SetWidth(TextW(onlyText) + 12 + 40)
    onlyRow:SetPoint("TOPRIGHT", -PAD, -12)
    -- line 2: search and sort
    local sort = Keep(S.Segmented(m, { { "level", L("Niveau") }, { "name", L("Nom") }, { "class", L("Classe") }, { "zone", L("Zone") }, { "rank", L("Rang") } },
        function() return WLWritsDB.guildSort or "level" end, function(v) WLWritsDB.guildSort = v; WP.RefreshGuild() end, 28))
    local sortTips = { L("Clic : trier par niveau"), L("Clic : trier par nom"), L("Clic : trier par classe"), L("Clic : trier par zone"), L("Clic : trier par rang") }
    for i, b in ipairs(sort.buttons) do b.tip = { b.label:GetText(), sortTips[i] } end
    sort:SetPoint("TOPRIGHT", -PAD, -52)
    ui.search = Keep(S.Input(m, math.max(160, CW - (Num(sort:GetWidth()) or 0) - 12), {
        search = true, placeholder = L("Ex. Mylla, Orgrimmar, Officier"),
        onChange = function() WP.RefreshGuild() end }))
    ui.search:SetPoint("TOPLEFT", PAD, -52)
    ui.search:HookScript("OnTextChanged", function(_, user) if not user then WP.RefreshGuild() end end)
    -- line 3: a class (the game's class icons) and a role (from the spec shared by WL Helper)
    ui.classBtns = {}
    local x = PAD
    for i, cls in ipairs({ "ALL", unpack(CLASSES) }) do
        local b = Keep(CreateFrame("Button", nil, m))
        b.wlOwned = true
        b:SetSize(28, 28); b:SetPoint("TOPLEFT", x, -92)
        b.bg = S.Solid(b, "BACKGROUND", C.btnFill); b.bg:SetAllPoints()
        b.edge = S.Border(b, C.btnEdge)
        b.icon = b:CreateTexture(nil, "ARTWORK"); b.icon:SetSize(20, 20); b.icon:SetPoint("CENTER")
        if cls == "ALL" or not S.ClassIcon(b.icon, cls) then S.HDIcon(b.icon, "group", C.fg) end
        b.cls = cls ~= "ALL" and cls or nil
        function b:Paint()
            if self.on then
                self.bg:SetColorTexture(C.selFill[1], C.selFill[2], C.selFill[3], C.selFill[4]); self.edge(C.accent, 1)
            else
                self.bg:SetColorTexture(1, 1, 1, self.hov and (C.btnFill[4] + C.hoverFill[4]) or C.btnFill[4])
                self.edge(C.btnEdge, self.hov and C.btnEdgeHover[4] or C.btnEdge[4])
            end
            self.icon:SetAlpha((self.on or self.hov or not WLWritsDB.guildClass) and 1 or 0.6)
        end
        b:SetScript("OnClick", function(self) WLWritsDB.guildClass = self.cls; WP.RefreshGuild() end)
        b:SetScript("OnMouseDown", function(self) self.icon:SetPoint("CENTER", 0, -1) end)
        b:SetScript("OnMouseUp", function(self) self.icon:SetPoint("CENTER", 0, 0) end)
        b:SetScript("OnEnter", function(self)
            self.hov = true; self:Paint()
            if self.cls then
                local c = ClassColor(self.cls)
                S.Tip(self, { { ClassName(self.cls), c[1], c[2], c[3] }, L("Clic : ne montrer que cette classe") })
            else
                S.Tip(self, { L("Toutes les classes"), L("Clic : montrer toutes les classes") })
            end
        end)
        b:SetScript("OnLeave", function(self) self.hov = nil; self:Paint(); S.HideTip() end)
        b:Paint()
        ui.classBtns[i] = b
        x = x + 28 + 4
    end
    -- "Tous" beside three role icons (the tooltip still says "Tous les rôles"): a long word next to
    -- icons read as a different kind of control (icon audit, Guild)
    ui.role = Keep(S.Segmented(m, { { "all", L("Tous") }, { "tank", S.RoleMarkup("tank", 16) }, { "heal", S.RoleMarkup("heal", 16) }, { "dps", S.RoleMarkup("dps", 16) } },
        function() return WLWritsDB.guildRole or "all" end,
        function(v) WLWritsDB.guildRole = v ~= "all" and v or nil; WP.RefreshGuild() end, 28))
    ui.role:SetPoint("TOPRIGHT", -PAD, -92)
    -- the role segments are icons: their names on hover
    local roleTips = { { L("Tous les rôles"), L("Clic : montrer tous les rôles") }, { L("Tank"), L("Clic : ne montrer que les tanks") },
        { L("Soigneur"), L("Clic : ne montrer que les soigneurs") }, { L("DPS"), L("Clic : ne montrer que les DPS") } }
    for i, b in ipairs(ui.role.buttons) do b.tip = roleTips[i] end
    ui.filtersBottom = 92 + 28
    -- line 4: where the guild is (zones as pills), or how many roles are known; clear the filters
    ui.zonesLabel = Keep(S.Text(m, F.meta, C.muted)); ui.zonesLabel:SetWordWrap(false); ui.zonesLabel:SetText(L("Où est la guilde :"))
    ui.zoneChips = {}
    ui.roleInfoOwner = m
    ui.roleIcon = Keep(S.Icon(m, "info", 14, "ARTWORK", C.info))
    ui.roleInfo = Keep(S.Text(m, F.meta, C.muted)); ui.roleInfo:Hide(); ui.roleIcon:Hide()
    ui.clear = Keep(S.Button(m, L("Enlever les filtres"), 0, 24, "ghost", ClearFilters))
    ui.clear:SetIcon("close")
    -- column heads over the list
    ui.heads = {}
    for i, t in ipairs({ L("Niv."), L("Nom"), L("Zone ou dernière connexion"), L("Rang") }) do
        local h = S.Text(m, F.meta, C.muted); h:SetWordWrap(false); h:SetText(t)
        if i == 1 or i == 4 then h:SetJustifyH("RIGHT") end
        ui.heads[i] = Keep(h)
    end
    ui.members = List(m, MemberRow)
    ui.noMatch = S.EmptyState(m, "search", L("Aucun membre ne correspond"))
    ui.noMatch:Hide()
    ui.noGuild = S.EmptyState(m, "group", L("Tu n'es dans aucune guilde"),
        L("Les membres et le classement PvP apparaîtront ici dès que tu rejoins une guilde."))
    ui.noGuild:Hide()

    -- pvp
    local p = pages.pvp
    local seg = S.Segmented(p, { { "week", L("Cette semaine") }, { "season", L("Saison") }, { "all", L("Depuis toujours") } },
        function() return WLWritsDB.guildRankMode or "week" end, function(v) WLWritsDB.guildRankMode = v; WP.RefreshGuild() end, 28)
    seg:SetPoint("TOPLEFT", PAD, -12)
    local segTips = { L("Clic : classer les victoires de cette semaine"), L("Clic : classer les victoires de la saison (le mois en cours)"),
        L("Clic : classer toutes les victoires depuis le début") }
    for i, b in ipairs(seg.buttons) do b.tip = { b.label:GetText(), segTips[i] } end
    ui.seasonPill = S.Pill(p)
    ui.seasonPill:SetPoint("RIGHT", p, "TOPRIGHT", -PAD, -26)
    ui.mine = S.Text(p, F.body, C.text)
    ui.mineKd = S.Text(p, F.meta, C.muted); ui.mineKd:Hide()
    ui.past = S.Text(p, F.meta, C.muted)
    ui.measure = S.Text(p, F.meta, C.muted); ui.measure:SetWordWrap(false); ui.measure:Hide()
    ui.rank = List(p, RankRow)
    ui.none = S.EmptyState(p, "sword", L("Aucune victoire cette semaine"))
    ui.none:Hide()
    win:SetScript("OnShow", function()
        if C_GuildInfo and C_GuildInfo.GuildRoster then pcall(C_GuildInfo.GuildRoster) elseif GuildRoster then pcall(GuildRoster) end
        Ask()
        if WP.Keys and WP.Keys.Ask then WP.Keys.Ask() end
        WP.RefreshGuild()
    end)
end

local function RenderKeys()
    if not (WP.Keys and WP.Keys.RenderGuildTab) then return end
    win:FitHeight(WP.Keys.RenderGuildTab(pages.keys, W, PAD))
end

-- the keys tab follows the "keys" module: off, it hides and the window opens on the members
local function KeysOn() return WP.Keys and WP.Keys.RenderGuildTab and (not WP.ModuleOn or WP.ModuleOn("keys")) end
function WP.ShowGuildTab(k)
    if not win then Build() end
    if not pages[k] or (k == "keys" and not KeysOn()) then k = "members" end
    current = k
    for key, pg in pairs(pages) do pg:SetShown(key == k) end
    win.subtitle:SetText(GetGuildInfo and GetGuildInfo("player") or "")
    win:Show(); win:Raise()
    WP.RefreshGuild()
    -- wrapped text measures right only once its width is applied: once more on the next frame
    if C_Timer and C_Timer.After then C_Timer.After(0, function() WP.RefreshGuild() end) end
end
local refreshing = false
function WP.RefreshGuild()
    if not (win and win:IsShown()) or refreshing then return end
    refreshing = true
    if current == "keys" and not KeysOn() then current = "members"; for key, pg in pairs(pages) do pg:SetShown(key == current) end end
    tabs:Update()
    -- the keys tab is the last one: hiding it leaves no gap in the bar
    for _, b in ipairs(tabs.tabs or {}) do if b.key == "keys" then b:SetShown(KeysOn() and true or false) end end
    local ok, err = pcall(current == "members" and RenderMembers or current == "keys" and RenderKeys or RenderPvP)
    refreshing = false
    if not ok then error(err, 0) end
end
function WP.ToggleGuild()
    if win and win:IsShown() then win:Hide(); return end
    if WP.ModuleOff and WP.ModuleOff("guild") then return end
    WP.ShowGuildTab(current)
end
function WP.HideGuild() if win then win:Hide() end end

-- ---------------------------------------------------------------- events
local ev = CreateFrame("Frame")
pcall(ev.RegisterEvent, ev, "PLAYER_LOGIN")
pcall(ev.RegisterEvent, ev, "CHAT_MSG_ADDON")
pcall(ev.RegisterEvent, ev, "GUILD_ROSTER_UPDATE")
ev:SetScript("OnEvent", function(self, e, prefix, msg, channel, sender)
    if not WLWritsDB then return end
    if e == "PLAYER_LOGIN" then
        for _, h in ipairs({ "PLAYER_PVP_KILLS_CHANGED", "PLAYER_REGEN_ENABLED", "ZONE_CHANGED_NEW_AREA", "PLAYER_ENTERING_WORLD",
            "UPDATE_BATTLEFIELD_SCORE", "UPDATE_BATTLEFIELD_STATUS", "PVP_MATCH_COMPLETE", "PLAYER_DEAD",
            "PLAYER_TARGET_CHANGED", "UPDATE_MOUSEOVER_UNIT", "PLAYER_FOCUS_CHANGED", "PLAYER_REGEN_DISABLED" }) do
            pcall(self.RegisterEvent, self, h)
        end
        C_Timer.After(5, function() pcall(ArchiveSeason); CheckHonor(true) end)
        -- usual hours: the roster is read when the game sends it; ask for it every 10 min
        if C_Timer.NewTicker then
            C_Timer.NewTicker(600, function()
                if On() and IsInGuild and IsInGuild() and C_GuildInfo and type(C_GuildInfo.GuildRoster) == "function" then pcall(C_GuildInfo.GuildRoster) end
            end)
        end
        C_Timer.After(25, function() loginTried = true; Share(true) end)
    elseif e == "PLAYER_PVP_KILLS_CHANGED" or e == "PLAYER_REGEN_ENABLED" or e == "ZONE_CHANGED_NEW_AREA" or e == "PLAYER_ENTERING_WORLD" then
        if On() then
            -- out of a battleground: its last numbers are counted; in one: ask for the scoreboard
            if e == "ZONE_CHANGED_NEW_AREA" or e == "PLAYER_ENTERING_WORLD" then LeaveMatch(Mine()) end
            if e == "PLAYER_PVP_KILLS_CHANGED" then NoteKillPlace() end
            AskScore()
            C_Timer.After(1, function() CheckHonor() end)
        end
    elseif e == "UPDATE_BATTLEFIELD_SCORE" then
        if On() then TrackScore(Mine()) end
    elseif e == "UPDATE_BATTLEFIELD_STATUS" or e == "PVP_MATCH_COMPLETE" then
        -- the match is over: its numbers count now (later updates only add what changed)
        if On() and InPvP() then
            local w = Call(GetBattlefieldWinner)
            if e == "PVP_MATCH_COMPLETE" or (w ~= nil and not Secret(w)) then EndMatch(Mine()); Share() end
        end
    elseif e == "PLAYER_DEAD" then
        if On() then PvPDeath() end
    elseif e == "PLAYER_TARGET_CHANGED" or e == "PLAYER_REGEN_DISABLED" then
        SeeHostile("target")
    elseif e == "UPDATE_MOUSEOVER_UNIT" then
        SeeHostile("mouseover")
    elseif e == "PLAYER_FOCUS_CHANGED" then
        SeeHostile("focus")
    elseif e == "GUILD_ROSTER_UPDATE" then
        pcall(ObserveHours)
        WP.RefreshGuild()
    elseif prefix == PREFIX and channel == "GUILD" and type(msg) == "string" and sender then
        local who = Short(sender)
        if who ~= Me() then OnMessage(msg, who) end
    end
end)
