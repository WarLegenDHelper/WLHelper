-- Writs/Finder.lua: "Trouver un groupe" / "Find a group" (T-78), the first tab of the Groups window.
-- The game's group finder search, seen through WL Helper: the search starts from the guide (the
-- dungeons of your route, your dungeon quests, your next event), the guild comes first (members
-- looking for the same dungeons, members with the same quests, the event, the key), then the
-- game's groups and players, with filters, ratings and one action per row.
--
-- Written from scratch for WL Helper (CC BY-NC-SA) from docs/BACKLOG.md T-78 and the T-78 spec:
-- standard Blizzard C_LFGList usage, no Blizzard group finder template or global, no hook.
--
-- Rules this file keeps (enforced by writ/finder_test.py):
--  * C_LFGList.Search only from a click on "Chercher" or "Relancer" (never a timer, show or event;
--    a dungeons + raids route searches its raids on the next click), with an explicit non-empty
--    activity list. One 2 s cooldown for every action.

--  * Every value the game may hide (secret in instances) goes through F.R / Readable before any
--    compare, join, format, count or table key. A hidden name is only ever shown by SetText on its
--    own FontString. Filters fail open, marks fail closed, actions hide; the click checks again.
--  * Never: a CVar, a field on a Blizzard frame, a hook on a Blizzard LFG function, a Blizzard LFG
--    panel shown or hidden, the game's whisper or invite fed a hidden name, an apply-to-group call.
--  * The client holds ONE result set: a search made elsewhere (the game's finder, another addon)
--    replaces it. Our list then says so (stale banner) instead of drawing foreign results.
local ADDON, root = ...
root.Writs = root.Writs or {}
local ns = root.Writs
local WP = ns.WP
local L = ns.L
local S = ns.S
local C = S.C
local FS = S.F

local F = {}
WP.Finder = F

ns.AddEnglish({
    -- the tab, the top bar
    ["Trouver un groupe"] = "Find a group",
    ["Chercher"] = "Search",
    ["Clic : chercher ces donjons dans la recherche de groupe du jeu"] = "Click: search these dungeons in the game's group finder",
    ["Patiente 2 s entre deux recherches."] = "Wait 2 s between searches.",
    ["Patiente 2 s entre deux actions."] = "Wait 2 s between actions.",
    ["Ta route : %s"] = "Your route: %s",
    ["Ta route"] = "Your route",
    ["Tes quêtes de donjon"] = "Your dungeon quests",
    ["Événement : %s"] = "Event: %s",
    ["Tout ce qui est à mon niveau"] = "Everything at my level",
    ["Mon annonce"] = "My listing",
    ["Choisir dans la liste"] = "Pick from the list",
    ["Donjons"] = "Dungeons",
    ["1 donjon"] = "1 dungeon",
    ["%d donjons"] = "%d dungeons",
    ["1 activité"] = "1 activity",
    ["%d activités"] = "%d activities",
    ["Activités"] = "Activities",
    ["Pas dans la recherche de groupe du jeu"] = "Not in the game's group finder",
    ["Clic : choisir les donjons à chercher"] = "Click: pick the dungeons to search",
    ["Clic : choisir d'où viennent les donjons"] = "Click: pick where the dungeons come from",
    ["Tout"] = "All",
    ["Joueurs"] = "Players",
    ["Soin"] = "Healer",
    ["Clic : montrer seulement les tanks"] = "Click: show only tanks",
    ["Clic : montrer seulement les soigneurs"] = "Click: show only healers",
    ["Clic : montrer seulement les DPS"] = "Click: show only DPS",
    ["Groupes : une place libre pour ce rôle. Joueurs : ce rôle coché."] = "Groups: a free slot for this role. Players: this role ticked.",
    ["Ex. ZF, quête, débutant"] = "E.g. ZF, quest, beginner",
    -- the filters
    ["Filtres"] = "Filters",
    ["Clic : classes, niveau, langues, style de jeu"] = "Click: classes, level, languages, playstyle",
    ["Des filtres sont actifs."] = "Some filters are on.",
    ["Classes"] = "Classes",
    ["Exclure ces classes des groupes"] = "Exclude these classes from groups",
    ["Niveau"] = "Level",
    ["Min"] = "Min",
    ["Max"] = "Max",
    ["Seulement à mon niveau"] = "Only at my level",
    ["Les activités hors de ton niveau ne sont pas cherchées (sauf celles de ta route)."] = "Activities outside your level are not searched (except your route's).",
    ["Langues"] = "Languages",
    ["Style de jeu"] = "Playstyle",
    ["Tous les styles"] = "Any style",
    ["Apprendre"] = "Learning",
    ["Détente"] = "Relaxed",
    ["Sérieux"] = "Serious",
    ["Expert"] = "Expert",
    ["Places libres"] = "Open slots",
    ["Mes filtres"] = "My filters",
    ["Enregistrer ces filtres..."] = "Save these filters...",
    ["Réinitialiser les filtres"] = "Reset filters",
    ["Nom de ces filtres"] = "Name for these filters",
    ["20 lettres au plus."] = "20 letters at most.",
    ["Donne un nom à ces filtres."] = "Give these filters a name.",
    ["Enregistrer"] = "Save",
    ["Annuler"] = "Cancel",
    ["Supprimer « %s »"] = "Delete \"%s\"",
    ["Aucun filtre enregistré"] = "No saved filters",
    ["Clic : remettre ces filtres"] = "Click: use these filters again",
    -- sections, pills, rows
    ["Ta guilde"] = "Your guild",
    ["Groupes"] = "Groups",
    ["Replier"] = "Collapse",
    ["Déplier"] = "Expand",
    ["Guilde"] = "Guild",
    ["Ami"] = "Friend",
    ["Nouveau"] = "New",
    ["Toi"] = "You",
    ["Retirée"] = "Delisted",
    ["Demandé"] = "Asked",
    ["Récents"] = "Recent",
    ["Niveau ↓"] = "Level ↓",
    ["Niveau ↑"] = "Level ↑",
    ["Classe"] = "Class",
    ["Niv. %s"] = "Level %s",
    ["%d min"] = "%d min",
    ["Clic : ranger les joueurs"] = "Click: sort the players",
    -- actions and their tooltips
    ["Demander à rejoindre"] = "Ask to join",
    ["Redemander à rejoindre"] = "Ask to join again",
    ["Inviter %s"] = "Invite %s",
    ["Clic : inviter et envoyer « %s »"] = "Click: invite and send \"%s\"",
    ["Clic : inviter"] = "Click: invite",
    ["Clic : demander à rejoindre en envoyant « %s »"] = "Click: ask to join by sending \"%s\"",
    ["Clic : ouvrir un chuchotement à %s"] = "Click: open a whisper to %s",
    ["Clic droit : plus d'actions"] = "Right-click: more actions",
    ["Double-clic : la même chose"] = "Double-click: the same",
    ["Nom masqué par le jeu en donjon."] = "Name hidden by the game in dungeons.",
    ["Noter ce joueur"] = "Rate this player",
    ["Effacer la note"] = "Clear rating",
    ["Copier le nom"] = "Copy name",
    ["Ctrl+C pour copier, Échap pour fermer."] = "Ctrl+C to copy, Escape to close.",
    ["À éviter"] = "Avoid",
    ["Correct"] = "Okay",
    ["Super"] = "Great",
    ["À éviter (1 étoile)"] = "Avoid (1 star)",
    ["Correct (2 étoiles)"] = "Okay (2 stars)",
    ["Super (3 étoiles)"] = "Great (3 stars)",
    ["Ta note : %s"] = "Your rating: %s",
    ["Le jeu a bloqué cette action."] = "The game blocked this action.",
    ["Indisponible en combat"] = "Not available in combat",
    ["Vérifier les rôles"] = "Role check",
    ["Clic : demander à chacun de confirmer son rôle"] = "Click: ask everyone to confirm their role",
    ["Seul le chef ou un assistant peut vérifier les rôles."] = "Only the leader or an assistant can start a role check.",
    -- banners, empty states, footer
    ["Une autre recherche a remplacé ces résultats."] = "Another search replaced these results.",
    ["Relancer"] = "Search again",
    ["La recherche n'a pas répondu. Les résultats précédents restent affichés."] = "The search did not answer. The previous results stay on screen.",
    ["En donjon, le jeu masque les noms : les actions reviennent à la sortie."] = "In dungeons the game hides names: actions come back when you leave.",
    ["La recherche de groupe du jeu n'est pas disponible ici."] = "The game's group finder is not available here.",
    ["Aucun de ces donjons n'est dans la recherche de groupe du jeu."] = "None of these dungeons is in the game's group finder.",
    ["Pas encore de recherche"] = "No search yet",
    ["Les groupes et joueurs qui cherchent pour tes donjons apparaîtront ici."] = "Groups and players looking for your dungeons will show up here.",
    ["Personne pour l'instant"] = "Nobody yet",
    ["Personne ne cherche ces donjons dans la recherche de groupe du jeu."] = "Nobody is looking for these dungeons in the game's group finder.",
    ["Aucun résultat avec ces filtres"] = "No results with these filters",
    ["Recherche en cours"] = "Searching",
    ["Recherche à l'instant"] = "Searched just now",
    ["Recherche il y a %d min"] = "Searched %d min ago",
    ["1 résultat"] = "1 result",
    ["%d résultats"] = "%d results",
    ["Prochaine recherche possible dans %d s"] = "Next search possible in %d s",
    ["Raids : clique encore sur Chercher"] = "Raids: click Search again",
    ["Me lister dans la recherche du jeu"] = "List me in the game's finder",
    ["Ouvre la Recherche de groupe du jeu avec %s."] = "Open the game's Group Finder with %s.",
    ["Ouvre la Recherche de groupe du jeu."] = "Open the game's Group Finder.",
    ["Copier le texte de l'annonce"] = "Copy listing text",
    ["Colle ce texte dans ton annonce, dans la Recherche de groupe du jeu."] = "Paste this text into your listing in the game's Group Finder.",
    ["Quêtes : %s"] = "Quests: %s",
    -- the guild section
    ["%s cherche un groupe pour %s"] = "%s is looking for a group for %s",
    ["%s cherche un groupe"] = "%s is looking for a group",
    ["1 membre a tes quêtes de %s"] = "1 member has your %s quests",
    ["%d membres ont tes quêtes de %s"] = "%d members have your %s quests",
    ["Inviter les %d"] = "Invite all %d",
    ["Voir"] = "View",
    ["Clé de %s : personne en ligne ne l'a."] = "%s key: nobody online has it.",
    ["Ont la clé : %s"] = "Have the key: %s",
    ["Personne n'a encore dit avoir cette clé."] = "Nobody has said they have this key yet.",
    ["Voir les %d autres"] = "See %d more",
    ["Voir moins"] = "Show less",
    ["Personne de la guilde ne cherche ces donjons pour l'instant."] = "Nobody in the guild is looking for these dungeons right now.",
    ["Je cherche un groupe"] = "I'm looking for a group",
    ["Clic : te montrer à la guilde avec ton rôle et tes donjons"] = "Click: show yourself to the guild with your role and dungeons",
    ["Tu cherches un groupe : la guilde te voit."] = "You're looking for a group: the guild sees you.",
    ["Mon rôle"] = "My role",
    ["Pour quoi ?"] = "What for?",
    ["Fermer"] = "Close",
    ["Réglages"] = "Settings",
    ["Clic : ouvrir les réglages de Groupes"] = "Click: open the Groups settings",
    -- /wlh lfgtest
    ["Recherche de groupe : %s."] = "Group finder: %s.",
    ["%s : activités %s"] = "%s: activities %s",
    ["%s : pas trouvé"] = "%s: not found",
    ["%d donjons du guide trouvés dans la recherche de groupe, %d pas trouvés."] = "%d guide dungeons found in the group finder, %d not found.",
    ["Annonce : CreateListing a répondu %s."] = "Listing: CreateListing answered %s.",
    ["Annonce : le jeu a bloqué CreateListing."] = "Listing: the game blocked CreateListing.",
    ["Si une annonce a été créée, retire-la dans la Recherche de groupe du jeu."] = "If a listing was created, remove it in the game's Group Finder.",
    ["Si le jeu propose de désactiver WL Helper, c'est un refus (FORBIDDEN) : choisis Ignorer."] = "If the game offers to disable WL Helper, that is a refusal (FORBIDDEN): choose Ignore.",

})

-- ================================================================= reading what the game may hide
local function Readable(v) if root.Readable then return root.Readable(v) end return true end
F.Readable = Readable
-- v when it can be read, else fallback
function F.R(v, fallback)
    if not Readable(v) then return fallback end
    if v == nil then return fallback end
    return v
end
local R = F.R
local function Str(v) v = R(v); if type(v) == "string" and v ~= "" then return v end end
local function Int(v)
    v = R(v)
    if type(v) == "number" and v == v and v ~= math.huge and v ~= -math.huge then return v end
end
local function Bool(v) v = R(v); if v == nil then return nil end return v and true or false end
local function Tbl(v) v = R(v); if type(v) == "table" then return v end end
F.Str, F.Int, F.Bool = Str, Int, Bool
-- a saved number: a wrong type, NaN or infinity, or out of [lo, hi], gives the default
function F.Num(v, def, lo, hi)
    if type(v) ~= "number" or v ~= v or v == math.huge or v == -math.huge then return def end
    if (lo and v < lo) or (hi and v > hi) then return def end
    return v
end
local function Now() return (time and time()) or 0 end
local function Clock() return Int(GetTime and GetTime()) or 0 end
local function Me() return Str((UnitName("player"))) end
local function ULen(s)
    if strlenutf8 then local ok, n = pcall(strlenutf8, s); if ok and type(n) == "number" then return n end end
    local _, n = tostring(s):gsub("[^\128-\191]", "")
    return n
end
-- cut to `max` bytes, back to a character boundary (French letters are never split)
local function Cut(s, max)
    s = tostring(s or "")
    if #s <= max then return s end
    local cut = max
    while cut > 0 do
        local b = s:byte(cut + 1)
        if not b or b < 128 or b >= 192 then break end
        cut = cut - 1
    end
    return s:sub(1, cut)
end
F.Cut = Cut
local function Copy(t)
    if type(t) ~= "table" then return t end
    local o = {}
    for k, v in pairs(t) do o[k] = Copy(v) end
    return o
end
local function ClientFR() return GetLocale and GetLocale() == "frFR" end
local function On() return WP.ModuleOn("events") end
local function Api(name) return C_LFGList and type(C_LFGList[name]) == "function" and C_LFGList[name] or nil end
local function Call(name, ...)
    local fn = Api(name)
    if not fn then return false end
    return pcall(fn, ...)
end

-- ================================================================= saved data (WLWritsDB.finder)
local CLASSES = { "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID" }
local CLASS_SET = {}
for _, c in ipairs(CLASSES) do CLASS_SET[c] = true end
local ROLES = { "tank", "heal", "dps" }

function F.DB()
    if type(WLWritsDB) ~= "table" then return {} end
    if type(WLWritsDB.finder) ~= "table" then WLWritsDB.finder = { v = 1 } end
    return WLWritsDB.finder
end
local function DefaultFilters()
    return { kind = "all", roles = {}, classes = {}, excludeClasses = false, lvlMin = 0, lvlMax = 0, myLevel = true,
        langs = {}, playstyle = 0, slots = {}, text = "" }
end
F.DefaultFilters = DefaultFilters
-- a filter table as read from the saved data: only what is valid is kept
function F.SanitizeFilters(t)
    local f = DefaultFilters()
    if type(t) ~= "table" then return f end
    if t.kind == "groups" or t.kind == "players" or t.kind == "all" then f.kind = t.kind end
    for _, r in ipairs(ROLES) do
        if type(t.roles) == "table" and t.roles[r] == true then f.roles[r] = true end
        if type(t.slots) == "table" and t.slots[r] == true then f.slots[r] = true end
    end
    if type(t.classes) == "table" then
        for c, v in pairs(t.classes) do if CLASS_SET[c] and v == true then f.classes[c] = true end end
    end
    f.excludeClasses = t.excludeClasses == true
    f.lvlMin = math.floor(F.Num(t.lvlMin, 0, 0, 100))
    f.lvlMax = math.floor(F.Num(t.lvlMax, 0, 0, 100))
    f.myLevel = t.myLevel ~= false
    if type(t.langs) == "table" then
        for k, v in pairs(t.langs) do if type(k) == "string" and #k <= 8 and v == true then f.langs[k] = true end end
    end
    f.playstyle = math.floor(F.Num(t.playstyle, 0, 0, 4))
    if type(t.text) == "string" then f.text = Cut(t.text, 60) end
    return f
end
function F.Filters()
    if not F.filters then F.filters = F.SanitizeFilters(F.DB().last) end
    return F.filters
end
function F.SaveFilters()
    local d = F.DB()
    d.last = Copy(F.Filters())
end
function F.ResetFilters()
    F.filters = DefaultFilters()
    F.SaveFilters()
end
-- true when a filter of the popover is not at its default (the dot on the filter button)
function F.FiltersDiffer()
    local f, d = F.Filters(), DefaultFilters()
    if next(f.classes) or f.excludeClasses or f.lvlMin ~= 0 or f.lvlMax ~= 0 or f.myLevel ~= d.myLevel
        or next(f.langs) or f.playstyle ~= 0 or next(f.slots) then return true end
    return false
end
-- "My filters": 20 at most, names 20 letters at most; broken entries are skipped (never repaired)
function F.Presets()
    local out, raw = {}, F.DB().presets
    if type(raw) ~= "table" then return out end
    for _, p in ipairs(raw) do
        if type(p) == "table" and type(p.name) == "string" and p.name ~= "" and ULen(p.name) <= 20 and type(p.f) == "table" then
            out[#out + 1] = { name = p.name, f = F.SanitizeFilters(p.f) }
            if #out >= 20 then break end
        end
    end
    return out
end
-- -> true, or false and the reason (a sentence)
function F.SavePreset(name)
    name = tostring(name or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if name == "" then return false, L("Donne un nom à ces filtres.") end
    if ULen(name) > 20 then return false, L("20 lettres au plus.") end
    local list = F.Presets()
    for i = #list, 1, -1 do if list[i].name == name then table.remove(list, i) end end
    table.insert(list, 1, { name = name, f = Copy(F.Filters()) })
    while #list > 20 do table.remove(list) end
    F.DB().presets = list
    return true
end
function F.DeletePreset(name)
    local list = F.Presets()
    for i = #list, 1, -1 do if list[i].name == name then table.remove(list, i) end end
    F.DB().presets = list
end
function F.ApplyPreset(name)
    for _, p in ipairs(F.Presets()) do
        if p.name == name then F.filters = F.SanitizeFilters(p.f); F.SaveFilters(); return true end
    end
end
function F.Setting(key, def)
    local v = F.DB()[key]
    if type(v) ~= "boolean" then return def end
    return v
end
function F.SetSetting(key, v) F.DB()[key] = v and true or false end
function F.SortPlayers()
    local v = F.DB().sortPlayers
    if v == "recent" or v == "lvlDesc" or v == "lvlAsc" or v == "class" then return v end
    return "recent"
end
function F.Collapsed(k) local c = F.DB().collapsed; return type(c) == "table" and c[k] == true end
function F.SetCollapsed(k, v)
    local d = F.DB()
    if type(d.collapsed) ~= "table" then d.collapsed = {} end
    d.collapsed[k] = v and true or nil
end

-- ================================================================= ratings (by "Name-Realm")
local function MyRealm()
    local r = (GetNormalizedRealmName and Str(GetNormalizedRealmName())) or (GetRealmName and Str(GetRealmName())) or ""
    return (r:gsub("[%s%-]", ""))
end
-- "Thrall", "Thrall-Realm", "Thrall Realm" -> "Thrall-Realm" (a bare name folds to my realm)
function F.NormName(name)
    name = Str(name)
    if not name then return nil end
    local n, realm = name:match("^([^%-%s]+)[%-%s](.+)$")
    if not n then n, realm = name, MyRealm() end
    realm = realm:gsub("[%s%-]", "")
    if realm == "" then realm = MyRealm() end
    return n .. "-" .. realm
end
function F.Ratings()
    local t = F.DB().ratings
    if type(t) ~= "table" then return {} end
    return t
end
-- 1..3 or nil; only for a name we can read (a mark fails closed)
function F.RatingOf(name)
    local key = F.NormName(name)
    if not key then return nil end
    local rec = F.Ratings()[key]
    if type(rec) ~= "table" then return nil end
    local r = F.Num(rec.r, nil, 1, 3)
    return r and math.floor(r) or nil
end
function F.SetRating(name, r, guid)
    local key = F.NormName(name)
    if not key then return false end
    local d = F.DB()
    if type(d.ratings) ~= "table" then d.ratings = {} end
    if r == nil then d.ratings[key] = nil
    else
        r = math.floor(F.Num(r, 2, 1, 3))
        local old = type(d.ratings[key]) == "table" and d.ratings[key] or {}
        d.ratings[key] = { r = r, t = Now(), g = Str(guid) or (type(old.g) == "string" and old.g or nil),
            note = type(old.note) == "string" and Cut(old.note, 60) or nil }
        F.CapRatings()
    end
    if F.OnRatingChanged then pcall(F.OnRatingChanged, key) end
    return true
end
-- the saved ratings stay at MAX_RATINGS at most: the oldest (by date) go first
F.MAX_RATINGS = 1000
function F.CapRatings()
    local t = F.DB().ratings
    if type(t) ~= "table" then return end
    local keys = {}
    for k in pairs(t) do keys[#keys + 1] = k end
    if #keys <= F.MAX_RATINGS then return end
    local function When(k) local e = t[k]; return type(e) == "table" and type(e.t) == "number" and e.t == e.t and e.t or 0 end
    table.sort(keys, function(a, b)
        local ta, tb = When(a), When(b)
        if ta ~= tb then return ta < tb end
        return tostring(a) < tostring(b)
    end)
    for i = 1, #keys - F.MAX_RATINGS do t[keys[i]] = nil end
end

local RATING_WORD = { "À éviter", "Correct", "Super" }
function F.RatingWord(r) return RATING_WORD[r] and L(RATING_WORD[r]) or "" end

-- ================================================================= state kept in memory
F.asked = {}        -- [partyGUID] = true: "Demandé"
F.contacted = {}    -- [name] = time: asked or invited (the Messages tab counts their answers)
F.rows = {}         -- the last results, read once per answer
F.byId = {}
F.cooldownUntil = 0

-- ================================================================= guide key -> activity IDs
-- lowercase, apostrophes and accents out, leading article dropped, "(...)" dropped
local ACCENTS = {
    ["à"] = "a", ["â"] = "a", ["ä"] = "a", ["á"] = "a", ["é"] = "e", ["è"] = "e", ["ê"] = "e", ["ë"] = "e",
    ["î"] = "i", ["ï"] = "i", ["í"] = "i", ["ô"] = "o", ["ö"] = "o", ["ó"] = "o", ["û"] = "u", ["ü"] = "u",
    ["ù"] = "u", ["ú"] = "u", ["ç"] = "c", ["ñ"] = "n", ["À"] = "a", ["Â"] = "a", ["É"] = "e", ["È"] = "e",
    ["Ê"] = "e", ["Î"] = "i", ["Ô"] = "o", ["Û"] = "u", ["Ç"] = "c", ["’"] = "", ["‘"] = "", ["œ"] = "oe",
}
function F.Norm(s)
    s = tostring(s or "")
    for a, b in pairs(ACCENTS) do s = s:gsub(a, b) end
    s = s:lower():gsub("%b()", ""):gsub("['`]", ""):gsub("[^%w]+", " ")
    s = s:gsub("^%s+", ""):gsub("%s+$", "")
    for _, art in ipairs({ "the ", "le ", "la ", "les ", "l ", "des " }) do
        if s:sub(1, #art) == art then s = s:sub(#art + 1); break end
    end
    return (s:gsub("%s+", " "))
end
-- one activity's info, never secret (category and activity info are not)
local function ActInfo(id)
    local ok, info = Call("GetActivityInfoTable", id)
    if ok and type(info) == "table" then return info end
end
F.ActInfo = ActInfo
local function ActName(id)
    local info = ActInfo(id)
    return info and Str(info.fullName or info.shortName) or nil
end
F.ActName = ActName
-- the activity's suggested levels: min, max (0 = no limit)
local function ActLevels(info)
    if type(info) ~= "table" then return 0, 0 end
    local lo = Int(info.minLevelSuggestion) or Int(info.minLevel) or 0
    local hi = Int(info.maxLevelSuggestion) or Int(info.maxLevel) or 0
    return lo, hi
end

-- F.map = { acts = { [id] = { id, cat, name, mapID, lo, hi, keys = {} } }, byKey = { [dkey] = { ids } },
--           cats = { catID, ... } }; built once per session (activity IDs can change with patches)
function F.BuildMap(force)
    if F.map and not force then return F.map end
    local map = { acts = {}, byKey = {}, cats = {}, ok = false }
    F.map = map
    local okC, cats = Call("GetAvailableCategories")
    if not okC or type(cats) ~= "table" then return map end
    map.ok = true
    local byMap, byName = {}, {}
    for _, cat in ipairs(cats) do
        cat = Int(cat)
        if cat then
            map.cats[#map.cats + 1] = cat
            local okA, acts = Call("GetAvailableActivities", cat)
            if okA and type(acts) == "table" then
                for _, id in ipairs(acts) do
                    id = Int(id)
                    local info = id and ActInfo(id)
                    if info then
                        local lo, hi = ActLevels(info)
                        local a = { id = id, cat = Int(info.categoryID) or cat, name = Str(info.fullName or info.shortName) or tostring(id),
                            mapID = Int(info.mapID) or 0, lo = lo, hi = hi, keys = {} }
                        map.acts[id] = a
                        if a.mapID > 0 then byMap[a.mapID] = byMap[a.mapID] or {}; table.insert(byMap[a.mapID], a) end
                        local n = F.Norm(a.name)
                        if n ~= "" then byName[n] = byName[n] or {}; table.insert(byName[n], a) end
                    end
                end
            end
        end
    end
    for _, k in ipairs(root.ORDER or {}) do
        local d = root.D and root.D[k]
        if d and not d.cq then
            local found = (d.inst and byMap[d.inst]) or byName[F.Norm(d.n)] or (d.nf and byName[F.Norm(d.nf)])
            -- wings that share one map (Scarlet Monastery, Dire Maul): keep the activities named like
            -- this key, and all of them only when none matches
            if found and d.inst and found == byMap[d.inst] and #found > 1 then
                local n1, n2, same = F.Norm(d.n or ""), d.nf and F.Norm(d.nf) or nil, {}
                for _, a in ipairs(found) do
                    local an = F.Norm(a.name)
                    if an ~= "" and (an == n1 or an == n2) then same[#same + 1] = a end
                end
                if #same > 0 then found = same end
            end
            if found then
                local ids = {}
                for _, a in ipairs(found) do ids[#ids + 1] = a.id; table.insert(a.keys, k) end
                table.sort(ids)
                map.byKey[k] = ids
            end
        end
    end
    return map
end
-- the activity IDs of a guide key (empty when the game's finder does not have it)
function F.ActivityFor(dkey)
    local ids = F.BuildMap().byKey[dkey]
    local out = {}
    for _, id in ipairs(ids or {}) do out[#out + 1] = id end
    return out
end
function F.Matched(dkey) return F.BuildMap().byKey[dkey] ~= nil end
-- the guide keys of an activity
function F.KeysOfActivity(id)
    local a = F.BuildMap().acts[id]
    return a and a.keys or {}
end

-- the player's own listing: its activities (NeverSecret)
function F.MyListing()
    local ok, e = Call("GetActiveEntryInfo")
    if not ok or type(e) ~= "table" then return nil end
    local ids = {}
    local raw = e.activityIDs
    if type(raw) == "table" then for _, id in ipairs(raw) do id = Int(id); if id then ids[#ids + 1] = id end end end
    if #ids == 0 and Int(e.activityID) then ids[1] = Int(e.activityID) end
    return #ids > 0 and ids or nil
end

-- our level rule (never the game's CVar): the activity's suggested range holds my level, or the
-- guide's range of one of its dungeons does, or it is in my listing, or "only at my level" is off
function F.LevelOK(id, mine)
    if not F.Filters().myLevel then return true end
    if mine and mine[id] then return true end
    local lv = Int(UnitLevel("player")) or 0
    local a = F.BuildMap().acts[id]
    local lo, hi = 0, 0
    if a then lo, hi = a.lo, a.hi else lo, hi = ActLevels(ActInfo(id)) end
    if lo <= lv and (hi == 0 or lv <= hi) then return true end
    for _, k in ipairs(a and a.keys or {}) do
        local d = root.D and root.D[k]
        if d and d.lvl and (d.lvl[1] or 0) <= lv and lv <= (d.lvl[2] or 99) then return true end
    end
    return false
end

-- ================================================================= where the dungeons come from
local function DName(k) return root.DName and root.DName(k) or k end
local function RouteKeys()
    local out, seen = {}, {}
    local picked = root.PickedKeys and root.PickedKeys() or {}
    for _, k in ipairs(picked) do if not seen[k] then seen[k] = true; out[#out + 1] = k end end
    local run = WLDTDB and WLDTDB.run
    if type(run) == "table" then
        for _, k in ipairs(root.ORDER or {}) do if run[k] and not seen[k] then seen[k] = true; out[#out + 1] = k end end
    end
    return out
end
-- the dungeons whose quests are in my log
local function QuestKeys()
    local ok, log = pcall(root.LogEntries or function() return {} end)
    if not ok or type(log) ~= "table" then return {} end
    local out = {}
    for _, k in ipairs(root.ORDER or {}) do
        local d = root.D and root.D[k]
        if d and not d.cq and type(d.q) == "table" then
            for _, q in ipairs(d.q) do if log[q] then out[#out + 1] = k; break end end
        end
    end
    return out
end
-- my next event within 24 h (organized or signed up), with its dungeon keys
local function NextEvent()
    if not (WP.EventList and WP.EventKeys) then return nil end
    local me, now = Me(), Now()
    local ok, list = pcall(WP.EventList)
    if not ok then return nil end
    for _, e in ipairs(list) do
        if e.status == "open" and e.when and e.when > now - 3600 and e.when - now <= 86400
            and (e.by == me or (e.signups and me and e.signups[me])) then
            local keys = WP.EventKeys(e.title)
            if #keys > 0 then return e, keys end
        end
    end
end
F.NextEvent = NextEvent

local function NamesOf(keys, short)
    local t = {}
    for _, k in ipairs(keys) do
        local d = root.D and root.D[k]
        t[#t + 1] = (short and d and d.short) or DName(k)
    end
    return table.concat(t, " + ")
end
-- the sources, in order: { key, label, keys | nil } (keys nil: not from the guide)
function F.Sources()
    local out = {}
    local route = RouteKeys()
    if #route > 0 then out[#out + 1] = { key = "route", label = string.format(L("Ta route : %s"), NamesOf(route)), keys = route, short = NamesOf(route, true) } end
    local quests = QuestKeys()
    if #quests > 0 then out[#out + 1] = { key = "quests", label = L("Tes quêtes de donjon"), keys = quests } end
    local e, ekeys = NextEvent()
    if e then out[#out + 1] = { key = "event", label = string.format(L("Événement : %s"), e.title or "?"), keys = ekeys, event = e } end
    out[#out + 1] = { key = "pick", label = L("Choisir dans la liste") }
    out[#out + 1] = { key = "level", label = L("Tout ce qui est à mon niveau") }
    if F.MyListing() then out[#out + 1] = { key = "mine", label = L("Mon annonce") } end
    return out
end
local function SourceDef(key)
    for _, s in ipairs(F.Sources()) do if s.key == key then return s end end
end
-- the source in use: the one picked when it still applies, else the first that applies
local function Sig(def)
    local t = {}
    for _, k in ipairs(def and def.keys or {}) do t[#t + 1] = k end
    return (def and def.key or "") .. ":" .. table.concat(t, ",")
end
function F.Source()
    local def = F.source and SourceDef(F.source)
    if def then
        -- the route changed in the guide: the dungeon choice follows it again
        if Sig(def) ~= F.srcSig then F.Prefill() end
        return F.source
    end
    local saved = WLWritsCharDB and WLWritsCharDB.finderSource
    if type(saved) == "string" and SourceDef(saved) and F.source == nil then F.source = saved; F.Prefill(); return saved end
    F.source = F.Sources()[1].key
    F.Prefill()
    return F.source
end
-- the dungeon choice follows the source (ticked = the source's dungeons)
function F.Prefill()
    F.sel, F.selActs = {}, F.selActs or {}
    local s = F.source and SourceDef(F.source)
    F.srcSig = Sig(s)
    for _, k in ipairs(s and s.keys or {}) do F.sel[k] = true end
end
function F.SetSource(key, user)
    F.source = key
    -- the raids left from the previous choice are not searched by the next click
    F.chain, F.chainNote = nil, nil
    if user and WLWritsCharDB then WLWritsCharDB.finderSource = key end
    F.Prefill()
end
-- the guide keys this tab searches now (the K message, the guild section)
function F.SourceKeys()
    F.Source()
    local out = {}
    for _, k in ipairs(root.ORDER or {}) do if F.sel and F.sel[k] then out[#out + 1] = k end end
    return out
end

-- ================================================================= the search
-- the category of the guide's dungeons (for "everything at my level" and an empty choice)
local function DungeonCategory()
    local map = F.BuildMap()
    local count = {}
    for _, ids in pairs(map.byKey) do
        for _, id in ipairs(ids) do local a = map.acts[id]; if a then count[a.cat] = (count[a.cat] or 0) + 1 end end
    end
    local best, bn = map.cats[1], -1
    for _, c in ipairs(map.cats) do if (count[c] or 0) > bn then best, bn = c, count[c] or 0 end end
    return best
end
local function AllAtLevel(cat, mine)
    local ids = {}
    local ok, acts = Call("GetAvailableActivities", cat)
    if ok and type(acts) == "table" then
        for _, id in ipairs(acts) do id = Int(id); if id and F.LevelOK(id, mine) then ids[#ids + 1] = id end end
    end
    return ids
end
-- what one click searches: { { cat = categoryID, ids = { activityIDs } }, ... }, one per category
-- (a route of dungeons and raids makes two); nil and the reason when there is nothing to search
function F.Plan()
    if not (Api("Search") and Api("GetAvailableCategories")) then return nil, "noapi" end
    local map = F.BuildMap()
    local src = F.Source()
    local listing = F.MyListing()
    local mine = {}
    for _, id in ipairs(listing or {}) do mine[id] = true end
    local ids = {}
    if src == "mine" then
        ids = listing or {}
    elseif src == "pick" then
        for id in pairs(F.selActs or {}) do if map.acts[id] then ids[#ids + 1] = id end end
        table.sort(ids)
    elseif src ~= "level" then
        local seen = {}
        for _, k in ipairs(F.SourceKeys()) do
            for _, id in ipairs(F.ActivityFor(k)) do if not seen[id] then seen[id] = true; ids[#ids + 1] = id end end
        end
        if #ids == 0 and #F.SourceKeys() > 0 then return nil, "unmatched" end
    end
    local plans, byCat = {}, {}
    if #ids == 0 then
        -- nothing ticked: every activity of the dungeons' category that passes our level rule
        local cat = DungeonCategory()
        if not cat then return nil, "unmatched" end
        local all = AllAtLevel(cat, mine)
        if #all == 0 then return nil, "unmatched" end
        return { { cat = cat, ids = all } }
    end
    for _, id in ipairs(ids) do
        local a = map.acts[id]
        local cat = a and a.cat or (ActInfo(id) and Int(ActInfo(id).categoryID))
        if cat then
            if not byCat[cat] then byCat[cat] = { cat = cat, ids = {} }; plans[#plans + 1] = byCat[cat] end
            table.insert(byCat[cat].ids, id)
        end
    end
    if #plans == 0 then return nil, "unmatched" end
    return plans
end
-- the language filter: nil unless something beyond the locked defaults is ticked
function F.LanguageFilter()
    local f = F.Filters()
    if not next(f.langs) then return nil end
    local okD, defaults = Call("GetDefaultLanguageSearchFilter")
    local out, extra = {}, false
    if okD and type(defaults) == "table" then for k, v in pairs(defaults) do if v == true and type(k) == "string" then out[k] = true end end end
    for k in pairs(f.langs) do if not out[k] then extra = true end; out[k] = true end
    return extra and out or nil
end

function F.CooldownLeft() return math.max(0, (F.cooldownUntil or 0) - Clock()) end
function F.StartCooldown()
    F.cooldownUntil = Clock() + 2
    if C_Timer and C_Timer.After then C_Timer.After(2.05, function() if F.Render then F.Render() end end) end
end
local Register, Unregister   -- the event frame (below)

-- one search; the caller made sure it comes from a click
local function Fire(plan)
    local token = {}
    F.pending = { token = token, t = Clock(), filters = Copy(F.Filters()), plan = plan }
    F.failed, F.blocked = nil, nil
    Register("LFG_LIST_SEARCH_RESULTS_RECEIVED"); Register("LFG_LIST_SEARCH_FAILED")
    F.actAt = Clock()
    local ok = Call("Search", plan.cat, 0, 0, F.LanguageFilter(), false, nil, plan.ids)
    if not ok then
        F.pending = nil
        F.blocked = Clock()
        return false
    end
    -- the last search we sent: an answer arriving after the 15 s timeout is still ours (30 s)
    F.lastSent = { token = token, t = Clock() }
    local function TimedOut()
        if F.pending and F.pending.token == token then
            if F.lastSent and F.lastSent.token == token then F.lastSent.timedOut = true end
            F.OnFailed()
        end
    end
    if C_Timer and C_Timer.NewTimer then
        F.pending.timer = C_Timer.NewTimer(15, TimedOut)
    elseif C_Timer and C_Timer.After then
        C_Timer.After(15, TimedOut)
    end
    return true
end
-- from a click on Chercher / Relancer: -> true, or false and the reason
function F.Search()
    if F.CooldownLeft() > 0 then return false, "cooldown" end
    local plans, why
    if F.chain and #F.chain > 0 then
        -- the raids of a dungeons + raids route: this click searches them, keeping the dungeons
        plans = F.chain; F.chain = nil; F.keepRows = true
    else
        plans, why = F.Plan()
        F.keepRows = nil
    end
    F.nothing = nil
    if not plans then F.nothing = why; return false, why end
    F.chain = {}
    for i = 2, #plans do F.chain[#F.chain + 1] = plans[i] end
    F.chainNote = nil
    F.stale = nil
    -- the "Nouveau" pill compares with what the previous click found
    if not F.keepRows then F.baseGUIDs = F.prevGUIDs end
    F.StartCooldown()
    if not Fire(plans[1]) then return false, "blocked" end
    return true
end

-- ================================================================= reading the results
local function Roles(t)
    t = Tbl(t)
    if not t then return nil end
    return { tank = Bool(t.tank) == true, heal = Bool(t.healer) == true or Bool(t.heal) == true, dps = Bool(t.dps) == true or Bool(t.damager) == true }
end
-- one result as a plain table of readable values (nil fields where the game hides them)
function F.ReadRow(id)
    local ok, info = Call("GetSearchResultInfo", id)
    local row = { id = id, live = true, acts = {}, classes = {} }
    if not ok or not Readable(info) or type(info) ~= "table" then row.hidden = true; row.kind = "unknown"; return row end
    local g = info.partyGUID
    if Readable(g) and type(g) == "string" then row.guid = g end
    local raw = info.leaderName
    row.leaderRaw = raw
    row.hidden = not Readable(raw)
    row.leader = Str(raw)
    row.num = Int(info.numMembers)
    local acts = Tbl(info.activityIDs)
    if acts then for _, a in ipairs(acts) do a = Int(a); if a then row.acts[#row.acts + 1] = a end end end
    if #row.acts == 0 and Int(info.activityID) then row.acts[1] = Int(info.activityID) end
    row.age = Int(info.age)
    row.delisted = Bool(info.isDelisted) == true
    row.playstyle = Int(info.generalPlaystyle)
    if row.playstyle == 0 then row.playstyle = nil end
    row.newFriendly = Bool(info.newPlayerFriendly) == true
    row.comment = Str(info.comment)
    row.self = Bool(info.hasSelf) == true or (row.leader ~= nil and row.leader == Me())
    -- the leader, then the members
    local okL, lead = Call("GetSearchResultLeaderInfo", id)
    lead = okL and Tbl(lead) or nil
    local n = math.min(row.num or 1, 40)
    for i = 1, n do
        local okM, m = Call("GetSearchResultPlayerInfo", id, i)
        m = okM and Tbl(m) or nil
        if m then
            local cls = Str(m.classFilename)
            if cls and CLASS_SET[cls] then row.classes[cls] = true elseif row.num and row.num > 1 then row.someHidden = true end
            if i == 1 and not lead then lead = m end
        else
            row.someHidden = true
        end
    end
    if lead then
        row.cls = Str(lead.classFilename)
        if row.cls and not CLASS_SET[row.cls] and not (RAID_CLASS_COLORS and RAID_CLASS_COLORS[row.cls]) then row.cls = nil end
        row.level = Int(lead.level)
        row.zone = Str(lead.areaName)
        row.roles = Roles(lead.lfgRoles)
        if row.cls then row.classes[row.cls] = true end
    end
    local mc = Api("GetSearchResultMemberCounts")
    if mc then
        local okC, c = pcall(mc, id)
        c = okC and Tbl(c) or nil
        if c then
            local t, h, d = Int(c.TANK), Int(c.HEALER), Int(c.DAMAGER)
            if t and h and d then row.counts = { tank = t, heal = h, dps = d } end
        end
    end
    if row.num == nil then row.kind = "unknown"
    elseif row.num <= 1 then row.kind = "player"
    else row.kind = "group" end
    -- the free-text filter reads one lowercased string of what can be read
    local words = { row.leader or "", row.zone or "" }
    for _, a in ipairs(row.acts) do
        words[#words + 1] = ActName(a) or ""
        for _, k in ipairs(F.KeysOfActivity(a)) do
            local d = root.D and root.D[k]
            words[#words + 1] = d and (d.short or "") or ""
        end
    end
    if row.playstyle then words[#words + 1] = F.PlaystyleWord(row.playstyle) end
    if row.newFriendly then words[#words + 1] = "debutant beginner new" end
    if row.comment then words[#words + 1] = row.comment end
    row.search = F.Norm(table.concat(words, " "))
    -- a hidden name or comment: the text filter cannot judge this row, so it lets it through
    row.textUnknown = row.hidden or not Readable(info.comment) or nil
    return row
end

-- guild and friend marks, a rating, the tier of the order
local function IsGuild(name)
    if F.Setting("markRelations", true) == false then return false end
    local fn = C_GuildInfo and C_GuildInfo.MemberExistsByName
    if type(fn) ~= "function" then return false end
    local ok, v = pcall(fn, name)
    return ok and Bool(v) == true
end
local function IsFriend(name)
    if F.Setting("markRelations", true) == false then return false end
    local FL = C_FriendList
    if FL and type(FL.GetFriendInfo) == "function" then
        local legacy = true
        if type(FL.IsLegacyFriendSystemEnabled) == "function" then local ok, v = pcall(FL.IsLegacyFriendSystemEnabled); legacy = ok and Bool(v) ~= false end
        if legacy then
            local ok, info = pcall(FL.GetFriendInfo, name)
            if ok and Tbl(info) then return true end
        end
    end
    local short = name:match("^([^%-]+)") or name
    return F.bnet ~= nil and (F.bnet[name:lower()] or F.bnet[short:lower()]) == true
end
-- Battle.net friends' characters on this game, read once per search
local function ScanBNet()
    F.bnet = {}
    if F.Setting("markRelations", true) == false then return end
    local BN = C_BattleNet
    if not (BN and type(BN.GetFriendNumGameAccounts) == "function" and type(BN.GetFriendGameAccountInfo) == "function" and BNGetNumFriends) then return end
    local okN, n = pcall(BNGetNumFriends)
    n = okN and Int(n) or 0
    for i = 1, math.min(n, 200) do
        local okG, g = pcall(BN.GetFriendNumGameAccounts, i)
        g = okG and Int(g) or 0
        for j = 1, math.min(g, 10) do
            local okI, a = pcall(BN.GetFriendGameAccountInfo, i, j)
            a = okI and Tbl(a) or nil
            if a then
                local name = Str(a.characterName)
                local client = Str(a.clientProgram)
                local project = Int(a.wowProjectID)
                local same = (not WOW_PROJECT_ID) or project == WOW_PROJECT_ID
                if name and (client == nil or client == (BNET_CLIENT_WOW or "WoW")) and same then F.bnet[name:lower()] = true end
            end
        end
    end
end
F.ScanBNet = ScanBNet
function F.Mark(row)
    row.guild, row.friend, row.rating = false, false, nil
    if row.leader and not row.self then
        row.guild = IsGuild(row.leader)
        row.friend = not row.guild and IsFriend(row.leader)
        row.rating = F.RatingOf(row.leader)
    end
    -- own listing, friends, guild, 3 stars, everyone else, 1 star last
    if row.self then row.tier = 0
    elseif row.friend then row.tier = 1
    elseif row.guild then row.tier = 2
    elseif row.rating == 3 then row.tier = 3
    elseif row.rating == 1 then row.tier = 5
    else row.tier = 4 end
end

-- reads the whole answer (GetFilteredSearchResults: reported listings removed)
function F.ReadAll()
    local okR, a, b = Call("GetFilteredSearchResults")
    local list = okR and (type(a) == "table" and a or (type(b) == "table" and b)) or nil
    local keep = F.keepRows and F.rows or nil
    local rows, byId = {}, {}
    local cur = {}
    if keep then for _, r in ipairs(keep) do r.live = false; rows[#rows + 1] = r; if r.guid then cur[r.guid] = true end end end
    ScanBNet()
    for _, id in ipairs(list or {}) do
        id = Int(id)
        if id and not byId[id] then
            local row = F.ReadRow(id)
            if row.guid then
                cur[row.guid] = true
                row.new = F.baseGUIDs ~= nil and not F.baseGUIDs[row.guid]
                if row.delisted then F.asked[row.guid] = nil end
            end
            F.Mark(row)
            rows[#rows + 1] = row
            byId[id] = row
        end
    end
    F.prevGUIDs = cur
    F.rows, F.byId = rows, byId
    F.searchedAt = Now()
    F.ids = {}
    for id in pairs(byId) do F.ids[id] = true end
end
-- a late leader name, a delisting: one row read again, drawn in place, no new order
function F.UpdateRow(id)
    id = Int(id)
    local old = id and F.byId[id]
    if not old then return nil end
    local row = F.ReadRow(id)
    row.new = old.new
    if row.delisted and row.guid then F.asked[row.guid] = nil end
    F.Mark(row)
    row.tier = old.tier   -- no re-sort until the next search
    for i, r in ipairs(F.rows) do if r == old then F.rows[i] = row end end
    F.byId[id] = row
    return row
end

-- ================================================================= filters and order
local PLAYSTYLE = { "Apprendre", "Détente", "Sérieux", "Expert" }
function F.PlaystyleWord(p) return PLAYSTYLE[p] and L(PLAYSTYLE[p]) or "" end
-- every test fails open: a value the game hides lets the row through
local passTextRaw, passTextNorm = nil, ""
function F.Pass(row, f)

    if row.self then return true end
    f = f or F.Filters()
    if f.kind == "groups" and row.kind == "player" then return false end
    if f.kind == "players" and row.kind == "group" then return false end
    local wantRole = f.roles.tank or f.roles.heal or f.roles.dps
    if wantRole then
        if row.kind == "player" then
            if row.roles then
                local any = false
                for _, r in ipairs(ROLES) do if f.roles[r] and row.roles[r] then any = true end end
                if not any then return false end
            end
        elseif row.counts then
            local free = { tank = 1 - row.counts.tank, heal = 1 - row.counts.heal, dps = 3 - row.counts.dps }
            local any = false
            for _, r in ipairs(ROLES) do if f.roles[r] and free[r] > 0 then any = true end end
            if not any then return false end
        end
    end
    if row.kind ~= "player" and row.counts and (f.slots.tank or f.slots.heal or f.slots.dps) then
        local free = { tank = 1 - row.counts.tank, heal = 1 - row.counts.heal, dps = 3 - row.counts.dps }
        for _, r in ipairs(ROLES) do if f.slots[r] and free[r] <= 0 then return false end end
    end
    if next(f.classes) then
        if row.kind == "player" then
            if row.cls and not f.classes[row.cls] then return false end
        elseif f.excludeClasses then
            for c in pairs(row.classes) do if f.classes[c] then return false end end
        end
    end
    if row.kind == "player" and row.level and (f.lvlMin > 0 or f.lvlMax > 0) then
        local lo, hi = f.lvlMin, f.lvlMax
        if lo > 0 and hi > 0 and lo > hi then lo, hi = hi, lo end
        if lo > 0 and row.level < lo then return false end
        if hi > 0 and row.level > hi then return false end
    end
    if f.playstyle > 0 and row.playstyle and row.playstyle ~= f.playstyle then return false end
    -- the typed text is normalised once, not once per row
    if f.text ~= passTextRaw then passTextRaw = f.text; passTextNorm = F.Norm(f.text or "") end
    local text = passTextNorm
    if text ~= "" and row.search and not row.textUnknown then
        if not row.search:find(text, 1, true) then return false end
    end
    return true
end
-- tier, then the key of the order (nil keys after the others), then the result id
local SORT_KEY = {
    recent = function(r) return r.age end,
    lvlDesc = function(r) return r.level and -r.level end,
    lvlAsc = function(r) return r.level end,
    class = function(r) return r.cls and (LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[r.cls] or r.cls) end,
}
function F.Sort(list, mode)
    local key = SORT_KEY[mode or "recent"] or SORT_KEY.recent
    table.sort(list, function(a, b)
        if a.tier ~= b.tier then return (a.tier or 4) < (b.tier or 4) end
        local ka, kb = key(a), key(b)
        if (ka ~= nil) ~= (kb ~= nil) then return ka ~= nil end
        if ka ~= nil and ka ~= kb then return ka < kb end
        return a.id < b.id
    end)
    return list
end
-- -> groups, players (sorted, filtered), the number of rows read
function F.Lists()
    local groups, players = {}, {}
    local f = F.Filters()
    for _, r in ipairs(F.rows) do
        if F.Pass(r, f) then

            if r.kind == "player" then players[#players + 1] = r else groups[#groups + 1] = r end
        end
    end
    F.Sort(groups, "recent")
    F.Sort(players, F.SortPlayers())
    return groups, players, #F.rows
end

-- ================================================================= lockdown, names, actions
-- In a dungeon or an encounter, or when the chat is locked down, the game hides names: no action.
function F.Locked()
    local CI = C_ChatInfo
    if CI and type(CI.InChatMessagingLockdown) == "function" then
        local ok, v = pcall(CI.InChatMessagingLockdown)
        if ok and Bool(v) == true then return true end
    end
    if IsInInstance then
        local ok, v = pcall(IsInInstance)
        if ok and Bool(v) == true then return true end
    end
    if IsEncounterInProgress then
        local ok, v = pcall(IsEncounterInProgress)
        if ok and Bool(v) == true then return true end
    end
    return false
end
-- the name to act on, read again at the click (a name can turn secret after the row was drawn)
function F.LiveName(row)
    if not row or row.self or row.delisted then return nil, "none" end
    if F.Locked() then return nil, "locked" end
    if row.live then
        local ok, info = Call("GetSearchResultInfo", row.id)
        if ok and Readable(info) and type(info) == "table" then
            local n = Str(info.leaderName)
            if not n then return nil, "hidden" end
            return n
        end
        return nil, "hidden"
    end
    if row.leader then return row.leader end
    return nil, "hidden"
end

local function Whisper(name)
    if WP.Shared and WP.Shared.Whisper then WP.Shared.Whisper(name); return end
    if ChatFrame_OpenChat then ChatFrame_OpenChat("/w " .. name .. " ") end
end
F.OpenWhisper = Whisper
-- a whisper we send ourselves: never a hidden name or text
function F.Send(text, name)
    if not (Readable(text) and Readable(name)) or type(text) ~= "string" or type(name) ~= "string" or text == "" then return false end
    local send = (C_ChatInfo and C_ChatInfo.SendChatMessage) or SendChatMessage
    if type(send) ~= "function" then return false end
    F.actAt = Clock()
    return (pcall(send, Cut(text, 255), "WHISPER", nil, name))
end

-- the message templates (Settings > Groupes); the default follows the client's language
local DEFAULT = {
    ask = { fr = "Salut ! %class% niv. %level% (%role%), dispo pour %dungeon% si tu as une place.",
        en = "Hi! Level %level% %class% (%role%), free for %dungeon% if you have a spot." },
    invite = { fr = "Salut, je t'invite pour %dungeon%.", en = "Hi, inviting you for %dungeon%." },
}
F.DEFAULT_TEMPLATES = DEFAULT
local TEMPLATE_KEY = { ask = "finderAsk", invite = "finderInvite" }
function F.DefaultTemplate(kind) return DEFAULT[kind][ClientFR() and "fr" or "en"] end
function F.Template(kind)
    local v = WLWritsCharDB and WLWritsCharDB[TEMPLATE_KEY[kind]]
    if type(v) == "string" then return Cut(v, 200) end
    return F.DefaultTemplate(kind)
end
function F.SetTemplate(kind, text)
    if not WLWritsCharDB then return end
    text = tostring(text or ""):gsub("[\r\n]+", " ")
    if text == F.DefaultTemplate(kind) then WLWritsCharDB[TEMPLATE_KEY[kind]] = nil
    else WLWritsCharDB[TEMPLATE_KEY[kind]] = Cut(text, 200) end
end
function F.AutoSend()
    local v = WLWritsCharDB and WLWritsCharDB.finderAutoSend
    return v ~= false
end
local ROLE_WORD = { fr = { tank = "tank", heal = "soigneur", dps = "DPS" }, en = { tank = "tank", heal = "healer", dps = "DPS" } }
function F.MyRole()
    if WLWritsCharDB and (WLWritsCharDB.lfgRole == "tank" or WLWritsCharDB.lfgRole == "heal" or WLWritsCharDB.lfgRole == "dps") then return WLWritsCharDB.lfgRole end
    if WP.LFGRole then local ok, r = pcall(WP.LFGRole); if ok and type(r) == "string" then return r end end
    if C_LFGListRoles and type(C_LFGListRoles.GetRoles) == "function" then
        local ok, t = pcall(C_LFGListRoles.GetRoles)
        t = ok and Tbl(t) or nil
        if t then if Bool(t.tank) then return "tank" elseif Bool(t.healer) then return "heal" end end
    end
    return "dps"
end
-- the names of a row's activities ("Zul'Farrak + Maraudon"), else of the dungeons searched
local function DungeonText(row)
    local t, seen = {}, {}
    for _, a in ipairs(row and row.acts or {}) do
        local n = ActName(a)
        if n and not seen[n] then seen[n] = true; t[#t + 1] = n end
    end
    if #t > 0 then return table.concat(t, " + ") end
    local keys = F.SourceKeys()
    return #keys > 0 and NamesOf(keys) or ""
end
-- up to 2 quest names I have for the row's dungeons (else the dungeons searched)
function F.QuestsText(row, max)
    max = max or 2
    local keys, seen = {}, {}
    for _, a in ipairs(row and row.acts or {}) do
        for _, k in ipairs(F.KeysOfActivity(a)) do if not seen[k] then seen[k] = true; keys[#keys + 1] = k end end
    end
    if #keys == 0 then keys = F.SourceKeys() end
    local ok, log = pcall(root.LogEntries or function() return {} end)
    if not ok or type(log) ~= "table" then return "" end
    local names = {}
    for _, k in ipairs(keys) do
        local d = root.D and root.D[k]
        for _, q in ipairs(d and d.q or {}) do
            if log[q] then names[#names + 1] = root.QName and root.QName(q) or tostring(q) end
        end
    end
    local n = #names
    if n == 0 then return "" end
    local shown = {}
    for i = 1, math.min(max, n) do shown[i] = names[i] end
    local s = table.concat(shown, ", ")
    if n > max then s = s .. " +" .. (n - max) end
    return s
end
function F.Fill(template, row)
    local classLocal = Str((UnitClass("player")))
    local fr = ClientFR() and "fr" or "en"
    local talents = ""
    if WP.Weights and WP.Weights.SpecName then
        local ok, t = pcall(WP.Weights.SpecName)
        if ok and type(t) == "string" then talents = t end
    end
    local vals = {
        class = classLocal or "",
        level = tostring(Int(UnitLevel("player")) or ""),
        role = ROLE_WORD[fr][F.MyRole()] or "DPS",
        talents = talents,
        dungeon = DungeonText(row),
        quests = F.QuestsText(row),
    }
    local out = tostring(template or ""):gsub("%%(%a+)%%", function(k)
        local v = vals[k]
        if v == nil then return nil end
        return v
    end)
    out = out:gsub("[|\r\n]", " "):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
    return Cut(out, 255)
end

local function Notice(why)
    if why == "cooldown" then F.say = L("Patiente 2 s entre deux actions.")
    elseif why == "locked" or why == "hidden" then F.say = L("Nom masqué par le jeu en donjon.")
    elseif why == "blocked" then F.blocked = Clock() end
end
-- Ask to join (a group): the whisper to its leader, else the whisper box
function F.Ask(row)
    local name, why = F.LiveName(row)
    if not name then Notice(why); return false, why end
    local text = F.Fill(F.Template("ask"), row)
    if text == "" or not F.AutoSend() then
        Whisper(name)
        if row.guid then F.asked[row.guid] = true end
        F.contacted[name] = Now()
        return true, "box"
    end
    if F.CooldownLeft() > 0 then Notice("cooldown"); return false, "cooldown" end
    if not F.Send(text, name) then Notice("blocked"); return false, "blocked" end
    F.StartCooldown()
    if row.guid then F.asked[row.guid] = true end
    F.contacted[name] = Now()
    return true, "sent"
end
-- the invite whisper goes only when I am alone or the group's leader
local function SoloOrLeader()
    if not (IsInGroup and IsInGroup()) then return true end
    local ok, v = pcall(UnitIsGroupLeader, "player")
    return ok and Bool(v) == true
end
F.SoloOrLeader = SoloOrLeader
-- Invite (a player), then the invite whisper when solo or leader
function F.Invite(row)
    local name, why = F.LiveName(row)
    if not name then Notice(why); return false, why end
    if F.CooldownLeft() > 0 then Notice("cooldown"); return false, "cooldown" end
    F.actAt = Clock()
    local n = (WP.Shared and WP.Shared.Invite) and WP.Shared.Invite({ name }) or 0
    F.StartCooldown()
    if (n or 0) <= 0 then return false, "refused" end
    F.contacted[name] = Now()
    local text = F.Fill(F.Template("invite"), row)
    if text ~= "" and F.AutoSend() and SoloOrLeader() then F.Send(text, name) end
    return true, "sent"
end
-- the row's main action: invite a player, ask a group
function F.Act(row)
    if not row then return false end
    if row.kind == "player" then return F.Invite(row) end
    return F.Ask(row)
end
-- Role check (leader or assistant; a hidden answer lets the button on)
function F.CanRoleCheck()
    if not (IsInGroup and IsInGroup()) then return false end
    local function flag(fn)
        if type(fn) ~= "function" then return nil end
        local ok, v = pcall(fn, "player")
        if not ok then return nil end
        return Bool(v)
    end
    local lead, assist = flag(UnitIsGroupLeader), flag(UnitIsGroupAssistant)
    if lead == nil or assist == nil then return true end
    return lead or assist
end
function F.RoleCheck()
    if F.CooldownLeft() > 0 then return false, "cooldown" end
    if not F.CanRoleCheck() or type(InitiateRolePoll) ~= "function" then return false, "refused" end
    F.actAt = Clock()
    F.StartCooldown()
    return (pcall(InitiateRolePoll))
end

-- the text of my listing (phase 3, "Copier le texte de l'annonce"): the route's quests
function F.ListingText()
    local q = F.QuestsText(nil, 2)
    if q == "" then return DungeonText(nil) end
    return Cut(string.format(L("Quêtes : %s"), q), 120)
end

-- ================================================================= the guild first
-- lines: { icon, text, detail, names = {}, kind, event }
function F.GuildLines()
    local lines = {}
    local keys = F.SourceKeys()
    local want = {}
    for _, k in ipairs(keys) do want[k] = true end
    local me = Me()
    -- 1. members looking for the same dungeons (any dungeon when the source has none)
    if WP.LFGList then
        local ok, list = pcall(WP.LFGList)
        for _, l in ipairs(ok and list or {}) do
            if l.name ~= me then
                local match, names = #keys == 0 or #(l.keys or {}) == 0, {}
                for _, k in ipairs(l.keys or {}) do if want[k] then match = true end; names[#names + 1] = DName(k) end
                if match then
                    local what = #names > 0 and table.concat(names, ", ") or (l.what ~= "" and l.what) or nil
                    local detail = (WP.GroupsRoleText and WP.GroupsRoleText(l.role, 12) or (l.role or "")) .. "  ·  "
                        .. string.format(L("niv. %s"), l.lvl or "?") .. "  ·  " .. (WP.GroupsAgo and WP.GroupsAgo(l.t) or "")
                    lines[#lines + 1] = { icon = "group", kind = "seeker", names = { l.name }, cls = l.cls,
                        text = what and string.format(L("%s cherche un groupe pour %s"), l.name, what) or string.format(L("%s cherche un groupe"), l.name),
                        detail = detail }
                end
            end
        end
    end
    -- 2. members online with the same dungeon quests
    local Sh = WP.Shared
    if Sh and Sh.ForDungeon then
        for _, k in ipairs(keys) do
            local ok, members = pcall(Sh.ForDungeon, k)
            local online = {}
            for _, m in ipairs(ok and members or {}) do
                if m.online and m.name ~= me then online[#online + 1] = m.full or m.name end
            end
            if #online > 0 then
                local shown = {}
                for i, n in ipairs(online) do shown[i] = (n:gsub("%-.*$", "")) end
                lines[#lines + 1] = { icon = "flag", kind = "quests", names = online,
                    text = #online == 1 and string.format(L("1 membre a tes quêtes de %s"), DName(k))
                        or string.format(L("%d membres ont tes quêtes de %s"), #online, DName(k)),
                    detail = table.concat(shown, ", ") }
            end
        end
    end
    -- 3. an event within 24 h for these dungeons
    if WP.EventList and WP.EventKeys then
        local ok, list = pcall(WP.EventList)
        local now = Now()
        for _, e in ipairs(ok and list or {}) do
            if e.status == "open" and e.when and e.when > now - 1800 and e.when - now <= 86400 then
                local match = #keys == 0
                for _, k in ipairs(WP.EventKeys(e.title)) do if want[k] then match = true end end
                if match then
                    local n = WP.EventCounts and WP.EventCounts(e) or { tank = 0, heal = 0, dps = 0 }
                    local have = n.tank + n.heal + n.dps
                    local slots = (e.tank or 0) + (e.heal or 0) + (e.dps or 0)
                    local when = WP.EventWhen and WP.EventWhen(e.when, true) or ""
                    lines[#lines + 1] = { icon = "calendar", kind = "event", event = e, names = {},
                        text = string.format(L("Événement : %s"), (e.title or "?") .. " " .. when .. " · " .. have .. "/" .. slots),
                        detail = string.format(L("par %s"), e.by or "?") }
                end
            end
        end
    end
    -- 4. a key nobody in the group or online has
    if WP.Keys and WP.Keys.WhoHas then
        local online = {}
        if WP.GuildRoster then
            local ok, list = pcall(WP.GuildRoster, true)
            for _, m in ipairs(ok and type(list) == "table" and list or {}) do if m.name then online[(m.name:gsub("%-.*$", ""))] = true end end
        end
        if me then online[me] = true end
        for i = 1, 4 do
            local ok, n = pcall(UnitName, "party" .. i)
            n = ok and Str(n) or nil
            if n then online[n] = true end
        end
        local said = {}
        for _, k in ipairs(keys) do
            local ok, names, info = pcall(WP.Keys.WhoHas, k)
            if ok and type(info) == "table" and info.needed and not said[info.key or k] then
                local anyone = false
                for _, n in ipairs(type(names) == "table" and names or {}) do if online[(tostring(n):gsub("%-.*$", ""))] then anyone = true end end
                if not anyone then
                    said[info.key or k] = true
                    local holders = type(names) == "table" and #names > 0 and string.format(L("Ont la clé : %s"), table.concat(names, ", "))
                        or L("Personne n'a encore dit avoir cette clé.")
                    lines[#lines + 1] = { icon = "shield", kind = "key", names = {},
                        text = string.format(L("Clé de %s : personne en ligne ne l'a."), DName(k)), detail = holders }
                end
            end
        end
    end
    return lines
end

-- ================================================================= /wlh lfgtest
function F.Probe(arg)
    local function P(msg) WP.Print(msg) end
    local have = {}
    for _, n in ipairs({ "Search", "GetFilteredSearchResults", "GetSearchResultInfo", "GetSearchResultMemberCounts",
        "GetActiveEntryInfo", "CreateListing", "UpdateListing" }) do have[#have + 1] = n .. (Api(n) and " +" or " -") end
    P(string.format(L("Recherche de groupe : %s."), table.concat(have, ", ")))
    F.BuildMap(true)
    local found, missing = 0, 0
    for _, k in ipairs(root.ORDER or {}) do
        local d = root.D and root.D[k]
        if d and not d.cq then
            local ids = F.map.byKey[k]
            if ids then
                found = found + 1
                P(string.format(L("%s : activités %s"), DName(k), table.concat(ids, ", ")))
            else
                missing = missing + 1
                P(string.format(L("%s : pas trouvé"), DName(k)))
            end
        end
    end
    P(string.format(L("%d donjons du guide trouvés dans la recherche de groupe, %d pas trouvés."), found, missing))
    if arg == "annonce" or arg == "listing" then
        -- one activity only (the "everything at my level" source can hold dozens)
        local plans = F.Plan()
        local first = plans and plans[1] and plans[1].ids and plans[1].ids[1]
        local ids = first and { first } or {}
        -- the block events are listened to even with the tab closed, for this probe
        Register("ADDON_ACTION_BLOCKED"); Register("ADDON_ACTION_FORBIDDEN")
        F.actAt, F.blocked = Clock(), nil
        local ok, res = Call("CreateListing", ids)
        local function Report()
            if F.blocked then P(L("Annonce : le jeu a bloqué CreateListing."))
            else P(string.format(L("Annonce : CreateListing a répondu %s."), tostring(ok) .. " " .. tostring(Readable(res) and res or "?"))) end
            P(L("Si une annonce a été créée, retire-la dans la Recherche de groupe du jeu."))
            P(L("Si le jeu propose de désactiver WL Helper, c'est un refus (FORBIDDEN) : choisis Ignorer."))
            local pg = F.ui and F.ui.page
            if not (pg and pg:IsShown()) then Unregister("ADDON_ACTION_BLOCKED"); Unregister("ADDON_ACTION_FORBIDDEN") end
        end
        if C_Timer and C_Timer.After then C_Timer.After(1, Report) else Report() end
    end
end

-- ================================================================= the tab (UI)
local W, PAD = 640, 16
local CW = W - 2 * PAD
local ROW_H, LINE_H = 36, 36
local ui = {}
F.ui = ui

local function Place(obj, x, y) obj:ClearAllPoints(); obj:SetPoint("TOPLEFT", x, -y) end
local function Over(f) local ok, v = pcall(f.IsMouseOver, f); return ok and v == true end
-- the frame under the mouse is f or one of its children (a dropdown list hanging out of a popover)
local function FocusIn(f)
    local foci = {}
    if GetMouseFoci then local ok, t = pcall(GetMouseFoci); if ok and type(t) == "table" then foci = t end
    elseif GetMouseFocus then local ok, t = pcall(GetMouseFocus); if ok and t then foci = { t } end end
    for _, x in ipairs(foci) do
        local n = 0
        while x and n < 20 do
            if x == f then return true end
            local ok, p = pcall(x.GetParent, x)
            x = ok and p or nil
            n = n + 1
        end
    end
    return false
end
local function TextW(fs) return root.TextWidth and root.TextWidth(fs) or 0 end
local function ClassColor(cls)
    local c = cls and RAID_CLASS_COLORS and RAID_CLASS_COLORS[cls]
    if c then return { c.r, c.g, c.b } end
    return C.fg
end
local function ClassName(cls) return (cls and LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[cls]) or cls or "" end
local function Ago(seconds)
    if not seconds then return nil end
    local m = math.floor(seconds / 60)
    if m < 1 then return L("à l'instant") end
    return string.format(L("il y a %d min"), m)
end

-- ---------------------------------------------------------------- popups: Escape and outside clicks
-- One Escape hides every shown frame of UISpecialFrames: while one of our popups is up, the Groups
-- window leaves that list (Escape closes the popup only) and comes back a frame after the last hides.
local WIN = "WLHelperEvents"
local popups = {}
local function AnyPopup() for f in pairs(popups) do if f:IsShown() then return true end end end
local function Unlist() for k = #UISpecialFrames, 1, -1 do if UISpecialFrames[k] == WIN then table.remove(UISpecialFrames, k) end end end
local function Relist()
    if AnyPopup() then return end
    for _, v in ipairs(UISpecialFrames) do if v == WIN then return end end
    if _G[WIN] then tinsert(UISpecialFrames, WIN) end
end
local outside = CreateFrame("Frame")
local function WatchOutside(on)
    if on then pcall(outside.RegisterEvent, outside, "GLOBAL_MOUSE_DOWN")
    elseif not AnyPopup() then pcall(outside.UnregisterEvent, outside, "GLOBAL_MOUSE_DOWN") end
end
outside:SetScript("OnEvent", function()
    for f in pairs(popups) do
        if f:IsShown() and not Over(f) and not FocusIn(f) and not (f.anchor and Over(f.anchor)) then
            local child = false
            for g in pairs(popups) do if g ~= f and g:IsShown() and g.owner == f and Over(g) then child = true end end
            if not child then f:Hide() end
        end
    end
end)
local function Popup(name, width, parent)
    local f = CreateFrame("Frame", name, parent or UIParent)
    f.wlOwned = true
    f:SetWidth(width)
    f:SetFrameStrata("DIALOG")
    f:EnableMouse(true)
    f:SetClampedToScreen(true)
    S.Solid(f, "BACKGROUND", C.panel, 0.98):SetAllPoints()
    S.Border(f, C.cardEdge)
    tinsert(UISpecialFrames, name)
    popups[f] = true
    f:SetScript("OnShow", function() Unlist(); WatchOutside(true) end)
    f:SetScript("OnHide", function()
        if C_Timer and C_Timer.After then C_Timer.After(0, Relist) else Relist() end
        WatchOutside(false)
    end)
    f:Hide()
    return f
end

-- ---------------------------------------------------------------- a list popup (choices, checks)
-- items: { { text, onClick, checked = true|false|nil, disabled, tip, head, keep } }; a function
-- giving them is read again after each click of a "keep" item (the list stays open)
local plist
local function OpenList(anchor, items, width)
    if not plist then
        plist = Popup("WLHelperFinderList", 220)
        plist:SetFrameStrata("FULLSCREEN_DIALOG")
        plist.rows, plist.off = {}, 0
        plist:EnableMouseWheel(true)
        plist:SetScript("OnMouseWheel", function(self, delta)
            local max = math.max(0, #self.items - 14)
            self.off = math.max(0, math.min(max, self.off - delta))
            self:Fill()
        end)
        function plist:Fill()
            local n = math.min(14, #self.items)
            for i = 1, n do
                local r = self.rows[i]
                if not r then
                    r = CreateFrame("Button", nil, self)
                    r:SetHeight(24)
                    r:SetPoint("TOPLEFT", 1, -1 - (i - 1) * 24); r:SetPoint("TOPRIGHT", -1, -1 - (i - 1) * 24)
                    r.hl = S.Solid(r, "BACKGROUND", C.hoverFill); r.hl:SetAllPoints(); r.hl:SetAlpha(0)
                    r.box = CreateFrame("Frame", nil, r); r.box:SetSize(12, 12); r.box:SetPoint("LEFT", 8, 0)
                    r.boxEdge = S.Border(r.box, C.line or C.muted)
                    r.check = root.Icon(r, "check", 12, "ARTWORK", C.accentSoft or C.accent); r.check:SetPoint("LEFT", 8, 0)
                    r.text = S.Text(r, FS.label, C.fg); r.text:SetPoint("LEFT", 26, 0); r.text:SetPoint("RIGHT", -8, 0)
                    r.text:SetJustifyH("LEFT"); r.text:SetWordWrap(false); S.ClampLabel(r.text, nil, r)
                    r:SetScript("OnEnter", function(self)
                        if self.item and not self.item.head and not self.item.disabled then self.hl:SetAlpha(1) end
                        if self.item and self.item.tip then S.Tip(self, self.item.tip) end
                    end)
                    r:SetScript("OnLeave", function(self) self.hl:SetAlpha(0); S.HideTip() end)
                    r:SetScript("OnClick", function(self)
                        local it = self.item
                        if not it or it.head or it.disabled then return end
                        if it.onClick then it.onClick() end
                        if it.keep and plist.source then
                            plist.items = plist.source(); plist:Fill()
                        else plist:Hide() end
                    end)
                    self.rows[i] = r
                end
                local it = self.items[i + self.off]
                r.item = it
                if it then
                    r.text:SetText(it.text or "")
                    local c = it.head and C.muted or (it.disabled and C.faint or C.fg)
                    r.text:SetTextColor(c[1], c[2], c[3])
                    r.box:SetShown(it.checked ~= nil and not it.head)
                    r.check:SetShown(it.checked == true)
                    r.text:ClearAllPoints()
                    r.text:SetPoint("LEFT", it.head and 8 or 26, 0); r.text:SetPoint("RIGHT", -8, 0)
                    r:Show()
                else r:Hide() end
            end
            for i = n + 1, #self.rows do self.rows[i]:Hide() end
            self:SetHeight(n * 24 + 2)
        end
    end
    plist.source = type(items) == "function" and items or nil
    plist.items = plist.source and plist.source() or items
    plist.off = 0
    plist.anchor = anchor
    plist.owner = anchor and anchor.popOwner or nil
    plist:SetWidth(width or 220)
    plist:ClearAllPoints()
    plist:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -2)
    plist:Fill()
    plist:Show(); plist:Raise()
    return plist
end
F.OpenList = OpenList

-- ---------------------------------------------------------------- the copy box (read-only)
local copyBox
function F.ShowCopy(title, text)
    if not copyBox then
        copyBox = Popup("WLHelperFinderCopy", 320)
        copyBox:SetPoint("CENTER", UIParent, "CENTER", 0, 120)
        copyBox.title = S.Text(copyBox, FS.body, C.fg); copyBox.title:SetPoint("TOPLEFT", 12, -12)
        copyBox.box = S.Input(copyBox, 296, {})
        copyBox.box:SetPoint("TOPLEFT", 12, -36)
        copyBox.box:SetMaxLetters(255)
        copyBox.hint = S.Text(copyBox, FS.meta, C.muted); copyBox.hint:SetPoint("TOPLEFT", 12, -72)
        copyBox.hint:SetText(L("Ctrl+C pour copier, Échap pour fermer."))
        -- read-only: any typing puts the text back, selected
        copyBox.box:HookScript("OnTextChanged", function(self, user)
            if user and copyBox.text then self:SetText(copyBox.text); self:HighlightText() end
        end)
        copyBox.box:SetScript("OnEscapePressed", function() copyBox:Hide() end)
        copyBox:SetHeight(92)
    end
    copyBox.text = text
    copyBox.title:SetText(title)
    copyBox:Show(); copyBox:Raise()
    copyBox.box:SetText(text or "")
    copyBox.box:SetFocus(); copyBox.box:HighlightText()
    return copyBox
end

-- ---------------------------------------------------------------- the name of new filters
local nameBox
local function AskPresetName()
    if not nameBox then
        nameBox = Popup("WLHelperFinderName", 300)
        nameBox:SetPoint("CENTER", UIParent, "CENTER", 0, 120)
        nameBox.title = S.Text(nameBox, FS.body, C.fg); nameBox.title:SetPoint("TOPLEFT", 12, -12)
        nameBox.title:SetText(L("Nom de ces filtres"))
        local function Save()
            local ok, why = F.SavePreset(nameBox.box:GetText())
            if ok then nameBox:Hide() else nameBox.box:SetError(why) end
        end
        nameBox.box = S.Input(nameBox, 276, { onEnter = Save })
        nameBox.box:SetPoint("TOPLEFT", 12, -36)
        nameBox.box:SetMaxLetters(40)
        nameBox.box:HookScript("OnTextChanged", function(self)
            local t = self:GetText() or ""
            if ULen(t) > 20 then self:SetError(L("20 lettres au plus.")); nameBox.ok:Disable() else self:SetError(nil); nameBox.ok:Enable() end
        end)
        nameBox.ok = S.Button(nameBox, L("Enregistrer"), 0, 28, "primary", Save)
        nameBox.ok:SetPoint("BOTTOMRIGHT", -12, 12)
        nameBox.cancel = S.Button(nameBox, L("Annuler"), 0, 28, "secondary", function() nameBox:Hide() end)
        nameBox.cancel:SetPoint("RIGHT", nameBox.ok, "LEFT", -8, 0)
        nameBox:SetHeight(36 + 28 + 24 + 28 + 12)
    end
    nameBox:Show(); nameBox:Raise()
    nameBox.box:SetText(""); nameBox.box:SetError(nil); nameBox.box:SetFocus()
end

-- ---------------------------------------------------------------- the right-click menu
local function RateItems(rootDesc, name, guid)
    local cur = F.RatingOf(name)
    local sub = rootDesc:CreateButton(L("Noter ce joueur"))
    for r, label in ipairs({ L("À éviter (1 étoile)"), L("Correct (2 étoiles)"), L("Super (3 étoiles)") }) do
        if sub.CreateRadio then
            sub:CreateRadio(label, function() return cur == r end, function() F.SetRating(name, r, guid); F.Render() end)
        else
            sub:CreateButton(label, function() F.SetRating(name, r, guid); F.Render() end)
        end
    end
    if cur then sub:CreateButton(L("Effacer la note"), function() F.SetRating(name, nil); F.Render() end) end
end
-- menu for a name (rows of this tab, of Messages, of Recent players); row: a result row or nil
function F.Menu(owner, name, row, guid)
    if not (MenuUtil and MenuUtil.CreateContextMenu) then return end
    name = Str(name)
    MenuUtil.CreateContextMenu(owner, function(_, rootDesc)
        if not name then
            rootDesc:CreateTitle(L("Nom masqué par le jeu en donjon."))
            return
        end
        rootDesc:CreateTitle(name)
        local locked = F.Locked()
        local w = rootDesc:CreateButton(L("Chuchoter"), function() Whisper(name) end)
        -- a group's leader is already in a group: no invite on group rows
        local inv
        if not row or row.kind == "player" then
            inv = rootDesc:CreateButton(L("Inviter"), function()
                if row then F.Invite(row) elseif F.CooldownLeft() <= 0 and WP.Shared and WP.Shared.Invite then
                    F.actAt = Clock(); WP.Shared.Invite({ name }); F.StartCooldown(); F.contacted[name] = Now()
                end
                F.Render()
            end)
        end
        if locked then
            if w.SetEnabled then w:SetEnabled(false) end
            if inv and inv.SetEnabled then inv:SetEnabled(false) end
        end

        RateItems(rootDesc, name, guid)
        rootDesc:CreateButton(L("Copier le nom"), function() F.ShowCopy(L("Copier le nom"), name) end)
    end)
end

-- ---------------------------------------------------------------- a result row (dense, 36)
local function RoleTex(parent, role, size)
    local t = parent:CreateTexture(nil, "ARTWORK")
    t:SetSize(size, size)
    S.RoleIcon(t, role)
    return t
end
local function ActionTip(row)
    local lines = {}
    local name = row.leader
    if row.kind == "player" then
        lines[1] = string.format(L("Inviter %s"), name or "?")
        local text = F.Fill(F.Template("invite"), row)
        if text ~= "" and F.AutoSend() and SoloOrLeader() then lines[2] = string.format(L("Clic : inviter et envoyer « %s »"), text)
        else lines[2] = L("Clic : inviter") end
    else
        lines[1] = (row.guid and F.asked[row.guid]) and L("Redemander à rejoindre") or L("Demander à rejoindre")
        local text = F.Fill(F.Template("ask"), row)
        if text ~= "" and F.AutoSend() then lines[2] = string.format(L("Clic : demander à rejoindre en envoyant « %s »"), text)
        else lines[2] = string.format(L("Clic : ouvrir un chuchotement à %s"), name or "?") end
    end
    if F.CooldownLeft() > 0 then lines[#lines + 1] = { L("Patiente 2 s entre deux actions."), C.warn[1], C.warn[2], C.warn[3] } end
    lines[#lines + 1] = L("Clic droit : plus d'actions")
    return lines
end
local function ResultRow(parent)
    local r = CreateFrame("Button", nil, parent)
    r.wlOwned = true
    r:SetSize(CW, ROW_H)
    r:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    r.bg = S.Solid(r, "BACKGROUND", C.cardFill); r.bg:SetAllPoints()
    r.hl = S.Solid(r, "BORDER", C.hoverFill); r.hl:SetAllPoints(); r.hl:SetAlpha(0)
    r.cls = r:CreateTexture(nil, "ARTWORK"); r.cls:SetSize(20, 20); r.cls:SetPoint("TOPLEFT", 8, -8)
    r.name = S.Text(r, FS.label, C.fg); r.name:SetWordWrap(false); r.name:SetJustifyH("LEFT")
    r.name:SetPoint("TOPLEFT", 36, -5)
    r.pills = { S.Pill(r), S.Pill(r) }
    r.detail = S.Text(r, FS.meta, C.muted); r.detail:SetWordWrap(false); r.detail:SetJustifyH("LEFT")
    r.detail:SetPoint("TOPLEFT", 36, -(5 + FS.label + 3)); r.detail:SetWidth(CW - 36 - 196)
    S.ClampLabel(r.detail, nil, r)
    r.stars = {}
    for i = 1, 3 do
        local s = root.Icon(r, "star", 12, "ARTWORK", C.head)
        s:SetPoint("RIGHT", r, "RIGHT", -148 + (i - 3) * 13, 0)
        r.stars[i] = s
    end
    r.roleTex, r.roleCnt = {}, {}
    for i, role in ipairs(ROLES) do
        local t = RoleTex(r, role, 14)
        t:SetPoint("TOPRIGHT", r, "TOPRIGHT", -112 + (i - 1) * 18 + 14, -6)
        r.roleTex[i] = t
        local c = S.Text(r, FS.foot, C.muted); c:SetPoint("TOP", t, "BOTTOM", 0, -1); c:SetWordWrap(false)
        r.roleCnt[i] = c
    end
    r.asked = root.Icon(r, "check", 14, "ARTWORK", C.ok)
    r.asked:SetPoint("RIGHT", r, "RIGHT", -40, 0)
    r.act = S.IconButton(r, "plus", 24, function() return r.row and ActionTip(r.row) end, function()
        if r.row then F.Act(r.row); F.Render() end
    end)
    r.act:SetPoint("RIGHT", -8, 0)
    local function Hover(on) root.Tween(r, r.hov or 0, on and 1 or 0, 0.10, function(v) r.hov = v; r.hl:SetAlpha(v) end) end
    r:SetScript("OnClick", function(self, button)
        local row = self.row
        if not row then return end
        if button == "RightButton" then F.Menu(self, row.leader, row); return end
        -- alt-click invites a lone player (a group's leader is already in a group)
        if IsAltKeyDown and IsAltKeyDown() and row.kind == "player" then F.Invite(row); F.Render() end

    end)
    r:SetScript("OnDoubleClick", function(self) if self.row and self.act:IsShown() then F.Act(self.row); F.Render() end end)
    r:SetScript("OnEnter", function(self)
        Hover(true)
        local row = self.row
        if not row then return end
        local lines = {}
        if row.leader then
            local c = ClassColor(row.cls)
            lines[1] = { row.leader, c[1], c[2], c[3] }
        else lines[1] = L("Nom masqué par le jeu en donjon.") end
        local acts = {}
        for _, a in ipairs(row.acts) do acts[#acts + 1] = ActName(a) end
        if #acts > 0 then lines[#lines + 1] = table.concat(acts, ", ") end
        if row.zone then lines[#lines + 1] = row.zone end
        if row.playstyle then lines[#lines + 1] = F.PlaystyleWord(row.playstyle) end
        if row.comment then lines[#lines + 1] = row.comment end
        if row.rating then lines[#lines + 1] = string.format(L("Ta note : %s"), F.RatingWord(row.rating)) end
        if self.act:IsShown() then
            for _, l in ipairs(ActionTip(row)) do lines[#lines + 1] = l end
            lines[#lines + 1] = L("Double-clic : la même chose")
        elseif not row.self and not row.delisted and (F.Locked() or not row.leader) then
            lines[#lines + 1] = { L("En donjon, le jeu masque les noms : les actions reviennent à la sortie."), C.muted[1], C.muted[2], C.muted[3] }
        end
        S.Tip(self, lines)
    end)
    r:SetScript("OnLeave", function() Hover(false); S.HideTip() end)
    r.act:HookScript("OnEnter", function() Hover(true) end)
    r.act:HookScript("OnLeave", function() if not Over(r) then Hover(false) end end)
    function r:Paint(row)
        self.row = row
        -- class and name: a hidden name only through SetText on its own string, never joined
        if row.cls and S.ClassIcon(self.cls, row.cls) then self.cls:Show() else self.cls:Hide() end
        -- at most 2 pills, at most 2 semantic colours (set first: the name gets what they leave)
        local want = {}
        if row.self then want[#want + 1] = { L("Toi") } end
        if row.delisted then want[#want + 1] = { L("Retirée") } end
        if row.guild then want[#want + 1] = { L("Guilde"), C.ok } end
        if row.friend then want[#want + 1] = { L("Ami"), C.info } end
        if row.new and not row.self then want[#want + 1] = { L("Nouveau") } end
        local pillsW = 0
        for i, p in ipairs(self.pills) do
            local w = want[i]
            if w then p:Set(w[1], w[2]); pillsW = pillsW + 6 + (F.Int(p:GetWidth()) or 60) end
        end
        -- the name and its pills end before the rating stars (x = -196 from the right)
        local maxName = math.max(20, CW - 36 - 196 - pillsW)
        if row.leader then
            self.name:SetText(row.leader)
            local c = ClassColor(row.cls)
            self.name:SetTextColor(c[1], c[2], c[3])
            self.name:SetWidth(math.max(20, math.min(maxName, TextW(self.name) + 2)))
        elseif row.hidden then
            self.name:SetText(row.leaderRaw)
            self.name:SetTextColor(C.fg[1], C.fg[2], C.fg[3])
            self.name:SetWidth(maxName)
        else
            self.name:SetText("?")
            self.name:SetWidth(20)
        end
        local prev = self.name
        for i, p in ipairs(self.pills) do
            local w = want[i]
            if w then
                p:ClearAllPoints(); p:SetPoint("LEFT", prev, "RIGHT", 6, 0)
                p:Show(); prev = p
            else p:Hide() end
        end
        -- the detail line: only readable parts
        local parts = {}
        if row.kind == "player" then
            if row.level then parts[#parts + 1] = string.format(L("Niv. %s"), row.level) end
        else
            parts[#parts + 1] = (row.num and tostring(row.num) or "?") .. "/5"
        end
        local acts = {}
        for _, a in ipairs(row.acts) do local n = ActName(a); if n then acts[#acts + 1] = n end end
        if #acts > 0 then parts[#parts + 1] = table.concat(acts, ", ") end
        if row.zone then parts[#parts + 1] = row.zone end
        local ago = Ago(row.age)
        if ago then parts[#parts + 1] = ago end
        self.detail:SetText(table.concat(parts, " · "))
        -- rating stars (only when rated)
        for i, s in ipairs(self.stars) do
            if row.rating then
                local c = i <= row.rating and (C.star or C.head) or C.faint
                s:SetVertexColor(c[1], c[2], c[3]); s:Show()
            else s:Hide() end
        end
        -- roles: a group's counts, a player's ticked roles
        for i, role in ipairs(ROLES) do
            local t, c = self.roleTex[i], self.roleCnt[i]
            if row.kind == "player" then
                local on = row.roles and row.roles[role]
                t:SetAlpha((row.roles == nil or on) and 1 or 0.25)
                c:Hide()
            else
                local n = row.counts and row.counts[role]
                t:SetAlpha((n == nil or n > 0) and 1 or 0.25)
                c:SetText(n and tostring(n) or ""); c:SetShown(n ~= nil)
            end
        end
        self.asked:SetShown(row.guid ~= nil and F.asked[row.guid] == true and row.kind ~= "player")
        -- the one action, hidden when it cannot be done
        local can = not row.self and not row.delisted and row.leader ~= nil and not F.Locked()
        self.act:SetShown(can)
        if can then
            self.act:SetIcon(row.kind == "player" and "plus" or "mail")
            local wait = F.CooldownLeft() > 0 and (row.kind == "player" or (F.AutoSend() and F.Template("ask") ~= ""))
            -- an invite only alone, or as the leader (an assistant in a raid); a hidden answer lets it on
            local refused = row.kind == "player" and IsInGroup and IsInGroup() and WP.Shared and WP.Shared.MayInvite
                and not WP.Shared.MayInvite(IsInRaid and IsInRaid() or false)
            if wait or refused then self.act:Disable() else self.act:Enable() end
        end
        self:SetAlpha(row.delisted and 0.5 or 1)
    end
    return r
end

-- ---------------------------------------------------------------- a guild line (dense, 36)
local function GuildLine(parent)
    local r = CreateFrame("Frame", nil, parent)
    r.wlOwned = true
    r:SetSize(CW, LINE_H)
    r.bg = S.Solid(r, "BACKGROUND", C.cardFill); r.bg:SetAllPoints()
    r.icon = root.Icon(r, "group", 16, "ARTWORK", C.muted); r.icon:SetPoint("TOPLEFT", 8, -10)
    r.text = S.Text(r, FS.label, C.fg); r.text:SetWordWrap(false); r.text:SetJustifyH("LEFT")
    r.text:SetPoint("TOPLEFT", 32, -5)
    r.detail = S.Text(r, FS.meta, C.muted); r.detail:SetWordWrap(false); r.detail:SetJustifyH("LEFT")
    r.detail:SetPoint("TOPLEFT", 32, -(5 + FS.label + 3))
    r.inv = S.Button(r, L("Inviter"), 0, 24, "secondary", function(self)
        local l = r.l
        if not l or #l.names == 0 then return end
        if F.CooldownLeft() > 0 then return end
        F.actAt = Clock()
        local n = WP.Shared and WP.Shared.Invite and WP.Shared.Invite(l.names) or 0
        F.StartCooldown()
        for _, nm in ipairs(l.names) do F.contacted[nm] = Now() end
        if (n or 0) > 0 then self:Flash(L("Invité")) end
    end)
    r.inv:SetPoint("RIGHT", -8, 0)
    r.whisper = S.Button(r, L("Chuchoter"), 0, 24, "secondary", function()
        if r.l and r.l.names[1] then Whisper(r.l.names[1]) end
    end)
    r.whisper:SetPoint("RIGHT", r.inv, "LEFT", -8, 0)
    r.view = S.Button(r, L("Voir"), 0, 24, "ghost", function()
        if r.l and r.l.event and WP.ShowEvent then WP.ShowEvent(r.l.event.id) end
    end)
    r.view:SetPoint("RIGHT", -8, 0)
    function r:Paint(l)
        self.l = l
        root.SetHDIcon(self.icon, l.icon or "group", l.kind == "key" and C.warn or C.muted)
        self.text:SetText(l.text or "")
        self.detail:SetText(l.detail or "")
        local seeker, quests = l.kind == "seeker", l.kind == "quests"
        local locked = F.Locked()
        self.whisper:SetShown(seeker and not locked)
        self.inv:SetShown((seeker or quests) and not locked)
        if quests and #l.names > 1 then self.inv:SetText(string.format(L("Inviter les %d"), #l.names))
        else self.inv:SetText(L("Inviter")) end
        self.view:SetShown(l.kind == "event")
        local right = 8
        if self.inv:IsShown() then right = right + (self.inv:GetWidth() or 72) + 8 end
        if self.whisper:IsShown() then right = right + (self.whisper:GetWidth() or 84) + 8 end
        if self.view:IsShown() then right = right + (self.view:GetWidth() or 48) + 8 end
        local w = math.max(80, CW - 32 - right)
        self.text:SetWidth(w); S.ClampLabel(self.text, l.text, self)
        self.detail:SetWidth(w); S.ClampLabel(self.detail, l.detail, self)
    end
    return r
end

-- ---------------------------------------------------------------- small controls
-- three role toggles (icons only, 40 each): any number can be on
local function RoleToggles(parent, get, set, tips)
    local h = CreateFrame("Frame", nil, parent)
    h:SetSize(40 * 3, 28)
    h.border = S.Border(h, C.btnEdge)
    h.buttons = {}
    for i, role in ipairs(ROLES) do
        local b = CreateFrame("Button", nil, h)
        b:SetSize(40, 28); b:SetPoint("LEFT", (i - 1) * 40, 0)
        b.fill = S.Solid(b, "BACKGROUND", C.selFill); b.fill:SetAllPoints(); b.fill:SetAlpha(0)
        b.hl = S.Solid(b, "BACKGROUND", C.hoverFill); b.hl:SetAllPoints(); b.hl:SetAlpha(0)
        b.sel = S.Border(b, C.accent, 0)
        b.icon = RoleTex(b, role, 16); b.icon:SetPoint("CENTER")
        b:SetScript("OnClick", function() set(role, not get(role)); h:Update() end)
        b:SetScript("OnEnter", function(self) self.hl:SetAlpha(1); S.Tip(self, tips[i]) end)
        b:SetScript("OnLeave", function(self) self.hl:SetAlpha(0); S.HideTip() end)
        h.buttons[i] = b
        b.role = role
    end
    function h:Update()
        for _, b in ipairs(self.buttons) do
            local on = get(b.role) and true or false
            b.fill:SetAlpha(on and 1 or 0); b.sel(C.accent, on and 1 or 0)
            b.icon:SetAlpha(on and 1 or 0.7)
        end
    end
    h:Update()
    return h
end
-- a checkbox row (languages): 20 high, box, label
local function Check(parent, label, get, set, width)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(width or 260, 20)
    b.box = CreateFrame("Frame", nil, b); b.box:SetSize(14, 14); b.box:SetPoint("LEFT", 0, 0)
    S.Border(b.box, C.line or C.muted)
    b.check = root.Icon(b, "check", 12, "ARTWORK", C.accentSoft or C.accent); b.check:SetPoint("CENTER", b.box, "CENTER")
    b.text = S.Text(b, FS.label, C.fg); b.text:SetPoint("LEFT", 22, 0); b.text:SetText(label)
    function b:Update()
        local on, locked = get()
        self.check:SetShown(on and true or false)
        self.locked = locked
        self:SetAlpha(locked and C.disabledAlpha or 1)
    end
    b:SetScript("OnClick", function(self) if not self.locked then set(not get()); self:Update() end end)
    b:Update()
    return b
end

-- ---------------------------------------------------------------- the filter popover
local fpop
local function BuildFilters()
    local P = 12
    fpop = Popup("WLHelperFinderFilters", 300, ui.win)
    fpop.owner = nil
    local items = {}
    local function Label(text) local t = S.Text(fpop, FS.meta, C.muted); t:SetText(text); return t end
    local function Changed() F.SaveFilters(); F.Render(); if fpop.Layout then fpop:Layout() end end
    -- classes: 3 rows of 3
    fpop.classLabel = Label(L("Classes"))
    fpop.classes = {}
    for i, cls in ipairs(CLASSES) do
        local b = CreateFrame("Button", nil, fpop)
        b:SetSize(28, 28)
        b.fill = S.Solid(b, "BACKGROUND", C.selFill); b.fill:SetAllPoints(); b.fill:SetAlpha(0)
        b.sel = S.Border(b, C.accent, 0)
        b.icon = b:CreateTexture(nil, "ARTWORK"); b.icon:SetSize(20, 20); b.icon:SetPoint("CENTER")
        S.ClassIcon(b.icon, cls)
        b.cls = cls
        b:SetScript("OnClick", function(self)
            local f = F.Filters()
            f.classes[self.cls] = (not f.classes[self.cls]) or nil
            Changed()
        end)
        b:SetScript("OnEnter", function(self) S.Tip(self, { ClassName(self.cls) }) end)
        b:SetScript("OnLeave", function() S.HideTip() end)
        fpop.classes[i] = b
    end
    fpop.exclude = S.Switch(fpop, function() return F.Filters().excludeClasses end,
        function(v) F.Filters().excludeClasses = v and true or false; Changed() end)
    fpop.excludeText = S.Text(fpop, FS.label, C.fg); fpop.excludeText:SetText(L("Exclure ces classes des groupes"))
    fpop.exclude:AttachRow(nil)
    -- level range
    fpop.lvlLabel = Label(L("Niveau"))
    local function LvlBox(key, ph)
        local eb = S.Input(fpop, 56, { placeholder = ph, onChange = function(t)
            F.Filters()[key] = math.floor(F.Num(tonumber(t), 0, 0, 100)); F.SaveFilters(); F.Render()
        end })
        eb:SetMaxLetters(3)
        if eb.SetNumeric then eb:SetNumeric(true) end
        return eb
    end
    fpop.lvlMin = LvlBox("lvlMin", L("Min"))
    fpop.lvlMax = LvlBox("lvlMax", L("Max"))
    fpop.myLevel = S.Switch(fpop, function() return F.Filters().myLevel end,
        function(v) F.Filters().myLevel = v and true or false; Changed() end,
        { L("Seulement à mon niveau"), L("Les activités hors de ton niveau ne sont pas cherchées (sauf celles de ta route).") })
    fpop.myLevelText = S.Text(fpop, FS.label, C.fg); fpop.myLevelText:SetText(L("Seulement à mon niveau"))
    -- languages (built from the game's list; the locked defaults checked and greyed)
    fpop.langLabel = Label(L("Langues"))
    fpop.langs = {}
    local okA, avail = Call("GetAvailableLanguageSearchFilter")
    local okD, defaults = Call("GetDefaultLanguageSearchFilter")
    defaults = okD and type(defaults) == "table" and defaults or {}
    for _, code in ipairs(okA and type(avail) == "table" and avail or {}) do
        if type(code) == "string" then
            local name = _G["LFG_LIST_LANGUAGE_" .. code:upper()] or code
            local c = Check(fpop, name, function()
                if defaults[code] then return true, true end
                return F.Filters().langs[code] == true
            end, function(v) F.Filters().langs[code] = v and true or nil; F.SaveFilters() end)
            fpop.langs[#fpop.langs + 1] = c
        end
    end
    -- playstyle
    fpop.styleLabel = Label(L("Style de jeu"))
    fpop.style = S.Dropdown(fpop, { { 0, L("Tous les styles") }, { 1, L("Apprendre") }, { 2, L("Détente") }, { 3, L("Sérieux") }, { 4, L("Expert") } },
        function() return F.Filters().playstyle end, function(v) F.Filters().playstyle = v; Changed() end, 160)
    -- open slots
    fpop.slotLabel = Label(L("Places libres"))
    fpop.slots = RoleToggles(fpop, function(r) return F.Filters().slots[r] end,
        function(r, v) F.Filters().slots[r] = v and true or nil; Changed() end,
        { { L("Tank"), L("Places libres") }, { L("Soigneur"), L("Places libres") }, { L("DPS"), L("Places libres") } })
    -- my filters, reset
    fpop.presets = S.Button(fpop, L("Mes filtres"), 0, 28, "secondary", function(self)
        self.popOwner = fpop
        OpenList(self, function()
            local list = {}
            local presets = F.Presets()
            if #presets == 0 then list[#list + 1] = { text = L("Aucun filtre enregistré"), head = true } end
            for _, p in ipairs(presets) do
                list[#list + 1] = { text = p.name, tip = { p.name, L("Clic : remettre ces filtres") },
                    onClick = function() F.ApplyPreset(p.name); Changed() end }
            end
            for _, p in ipairs(presets) do
                list[#list + 1] = { text = string.format(L("Supprimer « %s »"), p.name), keep = true,
                    onClick = function() F.DeletePreset(p.name) end }
            end
            list[#list + 1] = { text = L("Enregistrer ces filtres..."), onClick = AskPresetName }
            return list
        end, 240)
    end)
    fpop.reset = S.Button(fpop, L("Réinitialiser les filtres"), 0, 28, "secondary", function() F.ResetFilters(); Changed() end)
    function fpop:Layout()
        local f = F.Filters()
        local y = P
        Place(self.classLabel, P, y); y = y + FS.meta + 6
        for i, b in ipairs(self.classes) do
            local col, row = (i - 1) % 3, math.floor((i - 1) / 3)
            Place(b, P + col * 32, y + row * 32)
            local on = f.classes[b.cls] == true
            b.fill:SetAlpha(on and 1 or 0); b.sel(C.accent, on and 1 or 0)
        end
        y = y + 3 * 32 + 4
        Place(self.exclude, P, y); Place(self.excludeText, P + 48, y + 3); y = y + 20 + 12
        self.exclude:Update()
        Place(self.lvlLabel, P, y); y = y + FS.meta + 6
        Place(self.lvlMin, P, y); self.lvlMax:ClearAllPoints(); self.lvlMax:SetPoint("LEFT", self.lvlMin, "RIGHT", 8, 0)
        self.lvlMin:SetText(f.lvlMin > 0 and tostring(f.lvlMin) or ""); self.lvlMax:SetText(f.lvlMax > 0 and tostring(f.lvlMax) or "")
        y = y + 28 + 8
        Place(self.myLevel, P, y); Place(self.myLevelText, P + 48, y + 3); y = y + 20 + 12
        self.myLevel:Update()
        if #self.langs > 0 then
            Place(self.langLabel, P, y); y = y + FS.meta + 6
            for _, c in ipairs(self.langs) do Place(c, P, y); c:Update(); y = y + 22 end
            y = y + 6
        else self.langLabel:Hide() end
        Place(self.styleLabel, P, y); y = y + FS.meta + 6
        Place(self.style, P, y); self.style:Update(); y = y + 28 + 12
        Place(self.slotLabel, P, y); y = y + FS.meta + 6
        Place(self.slots, P, y); self.slots:Update(); y = y + 28 + 12
        Place(self.presets, P, y); self.reset:ClearAllPoints(); self.reset:SetPoint("LEFT", self.presets, "RIGHT", 8, 0)
        y = y + 28 + P
        self:SetHeight(y)
    end
    return fpop
end
local function ToggleFilters()
    if not fpop then BuildFilters() end
    if fpop:IsShown() then fpop:Hide(); return end
    fpop.anchor = ui.filter
    fpop:ClearAllPoints()
    fpop:SetPoint("TOPRIGHT", ui.filter, "BOTTOMRIGHT", 0, -4)
    fpop:Layout()
    fpop:Show(); fpop:Raise()
end
F.ToggleFilters = ToggleFilters

-- ---------------------------------------------------------------- "Je cherche un groupe"
local lpop
local function BuildLooking()
    lpop = Popup("WLHelperFinderLooking", 300, ui.win)
    local P = 12
    lpop.switch = S.Switch(lpop, function() return WP.IsLooking and WP.IsLooking() ~= nil end, function(v)
        if v then WP.SetLooking(F.MyRole(), lpop.what:GetText(), F.SourceKeys()) else WP.SetLooking(nil) end
        F.Render()
    end)
    lpop.label = S.Text(lpop, FS.body, C.fg); lpop.label:SetText(L("Je cherche un groupe"))
    lpop.desc = S.Text(lpop, FS.meta, C.muted)
    lpop.desc:SetText(L("Les membres qui ont WL Helper te voient dans leur liste. Ta recherche s'arrête seule quand ton groupe est complet."))
    lpop.roleLabel = S.Text(lpop, FS.meta, C.muted); lpop.roleLabel:SetText(L("Mon rôle"))
    local opts = {}
    for _, role in ipairs(ROLES) do opts[#opts + 1] = { role, WP.GroupsRoleText and WP.GroupsRoleText(role, 14) or role } end
    lpop.seg = S.Segmented(lpop, opts, function() return F.MyRole() end, function(v)
        if WLWritsCharDB then WLWritsCharDB.lfgRole = v end
        if WP.IsLooking and WP.IsLooking() then WP.SetLooking(v, lpop.what:GetText(), F.SourceKeys()) end
    end, 28)
    lpop.what = S.Input(lpop, 276, { label = L("Pour quoi ?"), placeholder = L("Ex. Zul'Farrak, quêtes des Maleterres"),
        onEnter = function(text) if WP.IsLooking and WP.IsLooking() then WP.SetLooking(F.MyRole(), text, F.SourceKeys()) end end })
    lpop.what:SetMaxLetters(80)
    function lpop:Layout()
        local y = P
        Place(self.label, P, y); self.switch:ClearAllPoints(); self.switch:SetPoint("TOPRIGHT", -P, -y)
        y = y + S.FitText(self.label, 2, 300 - 2 * P - 48, self) + 3
        Place(self.desc, P, y); y = y + S.FitText(self.desc, 0, 300 - 2 * P, self) + 12
        Place(self.roleLabel, P, y); y = y + FS.meta + 6
        Place(self.seg, P, y); y = y + 28 + 12 + FS.meta + 6
        Place(self.what, P, y); y = y + 28 + P
        self.switch:Update(); self.seg:Update()
        self:SetHeight(y)
    end
    return lpop
end
local function ToggleLooking(anchor)
    if not lpop then BuildLooking() end
    if lpop:IsShown() then lpop:Hide(); return end
    lpop.anchor = anchor
    lpop:ClearAllPoints(); lpop:SetPoint("TOPRIGHT", anchor, "BOTTOMRIGHT", 0, -4)
    local _, what = WP.IsLooking and WP.IsLooking()
    -- the old free text stays, prefilled with the dungeon names
    if not what or what == "" then what = NamesOf(F.SourceKeys()) end
    lpop.what:SetText(what or "")
    lpop:Layout()
    lpop:Show(); lpop:Raise()
end

-- ---------------------------------------------------------------- the dungeons list
local function DungeonItems()
    local items = {}
    local src = F.Source()
    local map = F.BuildMap()
    if src == "pick" then
        local byCat = {}
        local okC, cats = Call("GetAvailableCategories")
        for _, cat in ipairs(okC and type(cats) == "table" and cats or {}) do
            local okI, info = Call("GetLfgCategoryInfo", cat)
            local cname = okI and type(info) == "table" and Str(info.name) or tostring(cat)
            items[#items + 1] = { text = cname, head = true }
            local list = {}
            for id, a in pairs(map.acts) do if a.cat == cat then list[#list + 1] = a end end
            table.sort(list, function(x, y) if x.lo ~= y.lo then return x.lo < y.lo end return x.name < y.name end)
            for _, a in ipairs(list) do
                items[#items + 1] = { text = a.name, checked = F.selActs[a.id] == true, keep = true,
                    onClick = function() F.selActs[a.id] = (not F.selActs[a.id]) or nil; F.Render() end }
            end
            byCat[cat] = true
        end
        return items
    end
    local lv = Int(UnitLevel("player")) or 1
    local mine, rest = {}, {}
    for _, kind in ipairs({ "dg", "raid" }) do
        for _, e in ipairs(WP.GroupInstances and WP.GroupInstances(kind) or {}) do
            local ok = lv >= e[3] - 4 and lv <= e[4] + 1
            if ok then mine[#mine + 1] = e else rest[#rest + 1] = e end
        end
    end
    local function Add(list)
        for _, e in ipairs(list) do
            local k = e[1]
            local matched = F.Matched(k)
            items[#items + 1] = { text = e[2], checked = F.sel[k] == true, keep = true, disabled = not matched,
                tip = not matched and { e[2], L("Pas dans la recherche de groupe du jeu") } or nil,
                onClick = function() F.sel[k] = (not F.sel[k]) or nil; F.Render() end }
        end
    end
    if #mine > 0 then items[#items + 1] = { text = L("Pour ton niveau"), head = true }; Add(mine) end
    if #rest > 0 then items[#items + 1] = { text = L("Autres niveaux"), head = true }; Add(rest) end
    return items
end
local function DungeonLabel()
    local n = 0
    if F.Source() == "pick" then
        for _ in pairs(F.selActs or {}) do n = n + 1 end
        if n == 0 then return L("Activités") end
        return n == 1 and L("1 activité") or string.format(L("%d activités"), n)
    end
    n = #F.SourceKeys()
    if n == 0 then return L("Donjons") end
    return n == 1 and L("1 donjon") or string.format(L("%d donjons"), n)
end

-- ---------------------------------------------------------------- build the tab
local Render
local function Build(page, win)
    ui.page, ui.win = page, win
    -- Settings > Groupes (our own Hub window: it opens in combat too)
    if win and win.AddHeaderButton and not win.wlFinderGear then
        win.wlFinderGear = win:AddHeaderButton(S.IconButton(win.header, "gear", 28,
            { L("Réglages"), L("Clic : ouvrir les réglages de Groupes") },
            function() if WP.OpenHub then WP.OpenHub("groups") end end))
    end
    -- top bar: source, dungeons, Search, filters
    ui.src = S.Dropdown(page, {}, function() return F.Source() end, function(v) F.SetSource(v, true); Render() end, 236)
    function ui.src:Update()
        local cur, label = F.Source(), ""
        local opts = {}
        for _, s in ipairs(F.Sources()) do
            opts[#opts + 1] = { s.key, s.label }
            if s.key == cur then label = s.label; ui.srcDef = s end
        end
        self.options = opts
        -- one line at 236: the full label, else the short names, else the source alone
        local tries = { string.format(L("Pour : %s"), label) }
        if ui.srcDef and ui.srcDef.short then tries[#tries + 1] = string.format(L("Pour : %s"), string.format(L("Ta route : %s"), ui.srcDef.short)) end
        if cur == "route" then tries[#tries + 1] = string.format(L("Pour : %s"), L("Ta route")) end
        for _, t in ipairs(tries) do
            self:SetText(t)
            if TextW(self.label) + 24 + 12 <= 236 then break end
        end
        self.label.wlFull = label
    end
    ui.src:HookScript("OnEnter", function(self) S.Tip(self, { self.label.wlFull or "", L("Clic : choisir d'où viennent les donjons") }) end)
    ui.src:HookScript("OnLeave", function() S.HideTip() end)
    ui.dg = S.Button(page, L("Donjons"), 180, 28, "secondary", function(self)
        if plist and plist:IsShown() and plist.anchor == self then plist:Hide(); return end
        OpenList(self, DungeonItems, 260)
    end, { L("Donjons"), L("Clic : choisir les donjons à chercher") })
    ui.dg.arrow = ui.dg.content:CreateTexture(nil, "ARTWORK")
    ui.dg.arrow:SetSize(12, 12); ui.dg.arrow:SetPoint("RIGHT", -8, 0)
    root.SetHDIcon(ui.dg.arrow, "chevron_down", C.muted)
    ui.dg.extraW = 12
    ui.dg.label:SetJustifyH("LEFT")
    function ui.dg:CustomLayout(dy)
        self.label:ClearAllPoints()
        self.label:SetPoint("LEFT", self.content, "LEFT", 8, dy)
        self.label:SetPoint("RIGHT", self.arrow, "LEFT", -4, dy)
    end
    ui.go = S.Button(page, L("Chercher"), 0, 28, "primary", function()
        F.Search(); Render()
    end, function()
        if F.CooldownLeft() > 0 then return { L("Chercher"), L("Patiente 2 s entre deux recherches.") } end
        return { L("Chercher"), L("Clic : chercher ces donjons dans la recherche de groupe du jeu") }
    end)
    ui.go:SetIcon("search")
    ui.filter = S.IconButton(page, "filter", 28, function()
        local t = { L("Filtres"), L("Clic : classes, niveau, langues, style de jeu") }
        if F.FiltersDiffer() then t[#t + 1] = { L("Des filtres sont actifs."), C.accentSoft[1], C.accentSoft[2], C.accentSoft[3] } end
        return t
    end, function() ToggleFilters() end)
    ui.filterDot = ui.filter:CreateTexture(nil, "OVERLAY")
    ui.filterDot:SetSize(6, 6); ui.filterDot:SetPoint("TOPRIGHT", -4, -4)
    root.SetHDIcon(ui.filterDot, "dot", C.accent)
    -- second bar: kind, roles, free text
    ui.kind = S.Segmented(page, { { "all", L("Tout") }, { "groups", L("Groupes") }, { "players", L("Joueurs") } },
        function() return F.Filters().kind end, function(v) F.Filters().kind = v; F.SaveFilters(); Render() end, 28)
    ui.roles = RoleToggles(page, function(r) return F.Filters().roles[r] end,
        function(r, v) F.Filters().roles[r] = v and true or nil; F.SaveFilters(); Render() end,
        { { L("Tank"), L("Clic : montrer seulement les tanks"), L("Groupes : une place libre pour ce rôle. Joueurs : ce rôle coché.") },
          { L("Soin"), L("Clic : montrer seulement les soigneurs"), L("Groupes : une place libre pour ce rôle. Joueurs : ce rôle coché.") },
          { L("DPS"), L("Clic : montrer seulement les DPS"), L("Groupes : une place libre pour ce rôle. Joueurs : ce rôle coché.") } })
    ui.text = S.Input(page, 200, { search = true, placeholder = L("Ex. ZF, quête, débutant"),
        onChange = function(t) F.Filters().text = Cut(t, 60); F.SaveFilters(); Render() end })
    ui.text:SetMaxLetters(60)
    -- banners: one with "Relancer", one without
    ui.banAct = S.Banner(page, "info", "", L("Relancer"), function() F.Search(); Render() end)
    ui.banInfo = S.Banner(page, "info", "")
    -- the scrolled list
    ui.sa = S.ScrollArea(page)
    ui.content = ui.sa.child
    ui.content:SetWidth(CW)
    ui.hGuild = S.SectionHeader(ui.content, L("Ta guilde"), nil, nil, nil, true)
    ui.look = S.Button(ui.hGuild, L("Je cherche un groupe"), 0, 24, "ghost", function(self) ToggleLooking(self) end,
        function()
            if WP.IsLooking and WP.IsLooking() then return { L("Je cherche un groupe"), L("Tu cherches un groupe : la guilde te voit.") } end
            return { L("Je cherche un groupe"), L("Clic : te montrer à la guilde avec ton rôle et tes donjons") }
        end)
    ui.look:SetPoint("BOTTOMRIGHT", 0, 0)
    ui.roleCheck = S.Button(ui.hGuild, L("Vérifier les rôles"), 0, 24, "ghost", function() F.RoleCheck(); Render() end,
        function()
            if not F.CanRoleCheck() then return { L("Vérifier les rôles"), L("Seul le chef ou un assistant peut vérifier les rôles.") } end
            return { L("Vérifier les rôles"), L("Clic : demander à chacun de confirmer son rôle") }
        end)
    ui.roleCheck:SetPoint("RIGHT", ui.look, "LEFT", -12, 0)
    ui.guildNone = S.Text(ui.content, FS.label, C.muted)
    ui.guildNone:SetText(L("Personne de la guilde ne cherche ces donjons pour l'instant."))
    ui.guildMore = S.Button(ui.content, "", 0, 24, "ghost", function() ui.guildAll = not ui.guildAll; Render() end)
    ui.hGroups = S.SectionHeader(ui.content, L("Groupes"), nil, L("Replier"), function()
        F.SetCollapsed("groups", not F.Collapsed("groups")); Render()
    end)
    ui.hPlayers = S.SectionHeader(ui.content, L("Joueurs"), nil, L("Replier"), function()
        F.SetCollapsed("players", not F.Collapsed("players")); Render()
    end)
    local SORTS = { { "recent", "Récents" }, { "lvlDesc", "Niveau ↓" }, { "lvlAsc", "Niveau ↑" }, { "class", "Classe" } }
    ui.sort = S.Button(ui.hPlayers, "", 0, 24, "ghost", function(self)
        local items = {}
        for _, s in ipairs(SORTS) do
            items[#items + 1] = { text = L(s[2]), checked = F.SortPlayers() == s[1], onClick = function() F.DB().sortPlayers = s[1]; Render() end }
        end
        OpenList(self, items, 140)
    end, { L("Récents"), L("Clic : ranger les joueurs") })
    ui.sort:SetPoint("RIGHT", ui.hPlayers.link, "LEFT", -12, 0)
    ui.SORT_LABEL = {}
    for _, s in ipairs(SORTS) do ui.SORT_LABEL[s[1]] = s[2] end
    ui.lines, ui.rows = {}, {}
    ui.empty = S.EmptyState(ui.content, "search", L("Pas encore de recherche"),
        L("Les groupes et joueurs qui cherchent pour tes donjons apparaîtront ici."))
    ui.empty:Hide()
    ui.listMe = S.Button(ui.content, L("Me lister dans la recherche du jeu"), 0, 24, "ghost", nil, function()
        local key = GetBindingKey and (GetBindingKey("TOGGLEGROUPFINDER") or GetBindingKey("TOGGLELFGPARENT"))
        if type(key) == "string" and key ~= "" then return { L("Me lister dans la recherche du jeu"), string.format(L("Ouvre la Recherche de groupe du jeu avec %s."), key) } end
        return { L("Me lister dans la recherche du jeu"), L("Ouvre la Recherche de groupe du jeu.") }
    end)
    ui.copyListing = S.Button(ui.content, L("Copier le texte de l'annonce"), 0, 24, "ghost", function()
        F.ShowCopy(L("Copier le texte de l'annonce"), F.ListingText())
    end, { L("Copier le texte de l'annonce"), L("Colle ce texte dans ton annonce, dans la Recherche de groupe du jeu.") })
    -- footer
    ui.foot = S.Text(page, FS.foot, C.muted); ui.foot:SetJustifyH("LEFT"); ui.foot:SetWordWrap(false)
    ui.foot:SetPoint("BOTTOMLEFT", PAD, 8)
    ui.footR = S.Text(page, FS.foot, C.muted); ui.footR:SetJustifyH("RIGHT"); ui.footR:SetWordWrap(false)
    ui.footR:SetPoint("BOTTOMRIGHT", -PAD, 8)
    page:HookScript("OnShow", function() F.OnShow() end)
    page:HookScript("OnHide", function() F.OnHide() end)
end

local function Line(i) local l = ui.lines[i]; if not l then l = GuildLine(ui.content); ui.lines[i] = l end; l:Show(); return l end
local function Row(i) local r = ui.rows[i]; if not r then r = ResultRow(ui.content); ui.rows[i] = r end; r:Show(); return r end

-- the banner to show: kind, text, with "Relancer"
local function BannerState()
    -- a one-time notice is used now or dropped (never shown later, out of context)
    local say = F.say
    F.say = nil
    if not (C_LFGList and Api("Search")) then return "warn", L("La recherche de groupe du jeu n'est pas disponible ici."), false end
    if F.blocked and Clock() - F.blocked < 30 then return "warn", L("Le jeu a bloqué cette action."), false end
    if F.Locked() then return "info", L("En donjon, le jeu masque les noms : les actions reviennent à la sortie."), false end
    if F.failed then return "warn", L("La recherche n'a pas répondu. Les résultats précédents restent affichés."), true end
    if F.stale then return "info", L("Une autre recherche a remplacé ces résultats."), true end
    if F.nothing == "unmatched" then return "info", L("Aucun de ces donjons n'est dans la recherche de groupe du jeu."), false end
    if say then return "info", say, false end

end

function Render()
    local page = ui.page
    if not page then return end
    if not page:IsShown() then F.dirty = true; return end
    F.dirty = false
    local win = ui.win
    -- top bar
    local y = 12
    ui.src:Update(); Place(ui.src, PAD, y)
    ui.dg:SetText(DungeonLabel()); ui.dg:ClearAllPoints(); ui.dg:SetPoint("LEFT", ui.src, "RIGHT", 8, 0)
    ui.go:ClearAllPoints(); ui.go:SetPoint("LEFT", ui.dg, "RIGHT", 8, 0)
    local cd = F.CooldownLeft()
    if F.pending or cd > 0 or not Api("Search") then ui.go:Disable() else ui.go:Enable() end
    ui.go:SetDisabledReason(cd > 0 and L("Patiente 2 s entre deux recherches.") or nil)
    ui.filter:ClearAllPoints(); ui.filter:SetPoint("TOPRIGHT", page, "TOPRIGHT", -PAD, -y)
    ui.filterDot:SetShown(F.FiltersDiffer())
    y = y + 28 + 8
    ui.kind:Update(); Place(ui.kind, PAD, y)
    ui.roles:Update(); ui.roles:ClearAllPoints(); ui.roles:SetPoint("LEFT", ui.kind, "RIGHT", 12, 0)
    ui.text:ClearAllPoints(); ui.text:SetPoint("TOPRIGHT", page, "TOPRIGHT", -PAD, -y)
    local textX = PAD + (ui.kind:GetWidth() or 212) + 12 + 120 + 12
    ui.text:SetWidth(math.max(120, W - PAD - textX))
    if (ui.text:GetText() or "") ~= (F.Filters().text or "") and not ui.text.focused then ui.text:SetText(F.Filters().text or "") end
    y = y + 28 + 12
    -- banner
    ui.banAct:Hide(); ui.banInfo:Hide()
    local bk, bt, relaunch = BannerState()
    if bk then
        local b = relaunch and ui.banAct or ui.banInfo
        b:SetText(bt, bk)
        b:SetWidth(CW)
        local h = b:Fit(CW)
        Place(b, PAD, y); b:Show()
        y = y + h + 12
    end
    local top = y
    -- the list
    local cy = 0
    -- your guild
    ui.hGuild:SetWidth(CW); Place(ui.hGuild, 0, cy); ui.hGuild:Show()
    ui.look:SetText(L("Je cherche un groupe"))
    if WP.IsLooking and WP.IsLooking() then ui.look:SetIcon("check") else ui.look:SetIcon(nil) end
    ui.roleCheck:SetShown(IsInGroup and IsInGroup() and true or false)
    if F.CanRoleCheck() and F.CooldownLeft() <= 0 then ui.roleCheck:Enable() else ui.roleCheck:Disable() end
    cy = cy + 24 + 6
    local lines = F.GuildLines()
    local maxShown = ui.guildAll and #lines or math.min(4, #lines)
    for i = 1, maxShown do
        local l = Line(i)
        l:Paint(lines[i])
        Place(l, 0, cy)
        cy = cy + LINE_H + 2
    end
    for i = maxShown + 1, #ui.lines do ui.lines[i]:Hide() end
    if #lines == 0 then
        ui.guildNone:Show(); Place(ui.guildNone, 0, cy + 2); ui.guildNone:SetWidth(CW)
        cy = cy + FS.label + 8
    else ui.guildNone:Hide() end
    if #lines > 4 then
        ui.guildMore:SetText(ui.guildAll and L("Voir moins") or string.format(L("Voir les %d autres"), #lines - 4))
        Place(ui.guildMore, 0, cy); ui.guildMore:Show(); cy = cy + 24 + 4
    else ui.guildMore:Hide() end
    cy = cy + 8
    -- the game's results
    local groups, players, total = F.Lists()
    local rowI = 0
    local function Section(h, key, list, label)
        h:SetWidth(CW)
        h:Set(label, #list)
        local collapsed = F.Collapsed(key)
        h.link:SetText(collapsed and L("Déplier") or L("Replier"))
        Place(h, 0, cy); h:Show()
        cy = cy + 32 + 6
        if collapsed then return end
        for _, row in ipairs(list) do
            rowI = rowI + 1
            local r = Row(rowI)
            r:Paint(row)
            Place(r, 0, cy)
            cy = cy + ROW_H + 2
        end
        cy = cy + 6
    end
    local f = F.Filters()
    local showEmpty
    if F.pending and #F.rows == 0 then showEmpty = { "search", L("Recherche en cours") }
    elseif not F.searchedAt and #F.rows == 0 then showEmpty = { "search", L("Pas encore de recherche"), L("Les groupes et joueurs qui cherchent pour tes donjons apparaîtront ici.") }
    elseif total == 0 then showEmpty = { "group", L("Personne pour l'instant"), L("Personne ne cherche ces donjons dans la recherche de groupe du jeu.") }
    elseif #groups + #players == 0 then showEmpty = { "filter", L("Aucun résultat avec ces filtres"), nil, L("Réinitialiser les filtres") } end
    if showEmpty then
        ui.hGroups:Hide(); ui.hPlayers:Hide()
        ui.empty:Set(showEmpty[1], showEmpty[2], showEmpty[3], showEmpty[4], function() F.ResetFilters(); Render() end, "secondary")
        ui.empty:SetWrapWidth(CW)
        ui.empty:ClearAllPoints(); ui.empty:SetPoint("TOP", ui.content, "TOPLEFT", CW / 2, -(cy + 12))
        ui.empty:Show()
        cy = cy + 12 + ui.empty:Fit() + 12
    else
        ui.empty:Hide()
        -- the kind filter hides a section, never my own listing (it ignores every filter)
        local function Own(list)
            local o = {}
            for _, r in ipairs(list) do if r.self then o[#o + 1] = r end end
            return o
        end
        local gl = f.kind ~= "players" and groups or Own(groups)
        local pl = f.kind ~= "groups" and players or Own(players)
        if f.kind ~= "players" or #gl > 0 then Section(ui.hGroups, "groups", gl, L("Groupes")) else ui.hGroups:Hide() end
        if f.kind ~= "groups" or #pl > 0 then
            Section(ui.hPlayers, "players", pl, L("Joueurs"))
            ui.sort:SetText(L(ui.SORT_LABEL[F.SortPlayers()] or "Récents"))
            ui.sort:Show()
        else ui.hPlayers:Hide() end
    end
    for i = rowI + 1, #ui.rows do ui.rows[i]:Hide() end
    -- my listing: the game's finder, or the text to paste in it
    Place(ui.listMe, 0, cy); ui.copyListing:ClearAllPoints(); ui.copyListing:SetPoint("LEFT", ui.listMe, "RIGHT", 12, 0)
    cy = cy + 24
    -- footer
    local foot = ""
    if F.searchedAt then
        local m = math.floor((Now() - F.searchedAt) / 60)
        foot = (m < 1 and L("Recherche à l'instant") or string.format(L("Recherche il y a %d min"), m)) .. " · "
            .. (total == 1 and L("1 résultat") or string.format(L("%d résultats"), total))
    end
    ui.foot:SetText(foot)
    local status = ""
    if F.pending then status = L("Recherche en cours")
    elseif F.chainNote then status = L("Raids : clique encore sur Chercher")
    elseif cd > 0 then status = string.format(L("Prochaine recherche possible dans %d s"), math.ceil(cd)) end
    ui.footR:SetText(status)
    -- place the scroll area between the bars and the footer; fit the window
    local footH = 24
    ui.sa:ClearAllPoints()
    ui.sa:SetPoint("TOPLEFT", page, "TOPLEFT", PAD, -top)
    ui.sa:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -PAD, footH + 4)
    ui.content:SetWidth(CW)
    ui.sa:SetContentHeight(cy)
    if win and win.FitHeight then win:FitHeight(top + cy + 4 + footH - 24) end
end
-- an error while drawing is kept, and reported once per session to the error handler (BugGrabber)
F.Render = function()
    local ok, err = pcall(Render)
    if not ok then
        F.lastError = err
        if not F.errorSaid and type(geterrorhandler) == "function" then
            F.errorSaid = true
            local h = geterrorhandler()
            if type(h) == "function" then pcall(h, err) end
        end
    end
end

F.RenderRaw = Render   -- the tests call it without pcall

-- ================================================================= events
local evf = CreateFrame("Frame")
local registered = {}
function Register(ev)
    if registered[ev] then return end
    if pcall(evf.RegisterEvent, evf, ev) then registered[ev] = true end
end
function Unregister(ev)
    if not registered[ev] then return end
    pcall(evf.UnregisterEvent, evf, ev)
    registered[ev] = nil
end
local WHILE_SHOWN = { "LFG_LIST_SEARCH_RESULTS_RECEIVED", "LFG_LIST_SEARCH_FAILED", "LFG_LIST_SEARCH_RESULT_UPDATED",
    "REPORT_PLAYER_RESULT", "PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA", "PLAYER_REGEN_ENABLED",
    "GROUP_ROSTER_UPDATE", "PARTY_LEADER_CHANGED", "ADDON_ACTION_BLOCKED", "ADDON_ACTION_FORBIDDEN" }
local function Shown() return ui.page and ui.page:IsShown() end
function F.OnShow()
    for _, ev in ipairs(WHILE_SHOWN) do Register(ev) end
    -- the roster, once per window open (so guild marks can be confirmed)
    if not ui.rosterAsked and C_GuildInfo and type(C_GuildInfo.GuildRoster) == "function" then
        ui.rosterAsked = true
        pcall(C_GuildInfo.GuildRoster)
    end
    -- a search made while we were hidden replaced the results: our ids are gone
    if F.ids and next(F.ids) and not F.pending then
        local okR, a, b = Call("GetFilteredSearchResults")
        local list = okR and (type(a) == "table" and a or (type(b) == "table" and b)) or nil
        if list then
            local same, n = true, 0
            for _, id in ipairs(list) do id = Int(id); n = n + 1; if id and not F.ids[id] then same = false end end
            local mine = 0
            for _ in pairs(F.ids) do mine = mine + 1 end
            if n ~= mine then same = false end
            if not same then F.stale = true end
        end
    end
    F.Render()
end
function F.OnHide()
    for _, ev in ipairs(WHILE_SHOWN) do
        if not (F.pending and (ev == "LFG_LIST_SEARCH_RESULTS_RECEIVED" or ev == "LFG_LIST_SEARCH_FAILED")) then Unregister(ev) end
    end
    if ui.win and not ui.win:IsShown() then ui.rosterAsked = nil end
    if fpop then fpop:Hide() end
    if lpop then lpop:Hide() end
end
local function EndPending()
    local p = F.pending
    F.pending = nil
    if p and p.timer and p.timer.Cancel then pcall(p.timer.Cancel, p.timer) end
    if not Shown() then Unregister("LFG_LIST_SEARCH_RESULTS_RECEIVED"); Unregister("LFG_LIST_SEARCH_FAILED") end
end
function F.OnReceived()
    local late = F.lastSent
    if not F.pending and late and late.timedOut and Clock() - late.t <= 30 then
        -- our own search, answered after the 15 s timeout
        late.timedOut = nil
        F.failed, F.stale = nil, nil
        F.ReadAll()
        if F.chain and #F.chain > 0 then F.chainNote = true end
        if Shown() then F.Render() else F.dirty = true end
        return
    end
    if not F.pending then
        -- someone else searched: our list is no longer what the client holds
        if F.searchedAt then F.stale = true end
        if Shown() then F.Render() else F.dirty = true end
        return
    end
    EndPending()
    F.failed, F.stale = nil, nil
    F.ReadAll()
    -- a route of dungeons and raids: the game only lets a click search, so the raids wait for the
    -- next click on Chercher (the footer says so; that click keeps these rows)
    if F.chain and #F.chain > 0 then
        F.chainNote = true
    else
        F.keepRows = nil
        F.chainNote = nil
    end
    if Shown() then F.Render() else F.dirty = true end
end
function F.OnFailed()
    if not F.pending then return end
    EndPending()
    F.failed = true
    if Shown() then F.Render() else F.dirty = true end
end
evf:SetScript("OnEvent", function(_, ev, a1)
    if ev == "LFG_LIST_SEARCH_RESULTS_RECEIVED" then F.OnReceived()
    elseif ev == "LFG_LIST_SEARCH_FAILED" then F.OnFailed()
    elseif ev == "LFG_LIST_SEARCH_RESULT_UPDATED" then
        local row = F.UpdateRow(a1)
        if row and Shown() then
            for _, r in ipairs(ui.rows) do if r:IsShown() and r.row and r.row.id == row.id then r:Paint(row) end end
        end
    elseif ev == "REPORT_PLAYER_RESULT" then
        -- re-read only our own, current results (not another search's, not during a search)
        if F.ids and next(F.ids) and not F.stale and not F.pending then
            F.keepRows = nil; F.ReadAll(); F.Render()
        end

    elseif ev == "ADDON_ACTION_BLOCKED" or ev == "ADDON_ACTION_FORBIDDEN" then
        if a1 == ADDON and F.actAt and Clock() - F.actAt < 2 then F.blocked = Clock(); F.Render() end
    elseif ev == "PLAYER_LOGIN" then
        -- /wlh lfg opens this tab, /wlh events and /wlh agenda the Agenda; /wlh lfgtest probes
        local orig = SlashCmdList and SlashCmdList.WLDUNGEONTOOL
        if orig then
            SlashCmdList.WLDUNGEONTOOL = function(msg, ...)
                local w, rest = tostring(msg or ""):lower():match("^%s*(%S*)%s*(.-)%s*$")
                w = (w or ""):gsub("é", "e")
                if w == "lfg" then if WP.ToggleEvents then WP.ToggleEvents("find") end return end
                if w == "events" or w == "evenements" or w == "agenda" or w == "calendar" then
                    if WP.ToggleEvents then WP.ToggleEvents("upcoming") end return
                end
                if w == "lfgtest" then F.Probe(rest); return end
                return orig(msg, ...)
            end
        end
    else
        -- lockdown and group changes: drawn again while the tab shows
        if Shown() then F.Render() end
    end
end)
pcall(evf.RegisterEvent, evf, "PLAYER_LOGIN")

-- the tab in the Groups window (Writs/Events.lua)
if WP.RegisterGroupTab then
    WP.RegisterGroupTab({ key = "find", label = "Trouver un groupe", order = 10,
        build = Build, render = function() F.Render() end,
        badge = function() if WP.LFGCount then return WP.LFGCount(true) end end })
end
