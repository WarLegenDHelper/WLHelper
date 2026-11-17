-- Writs/QuestFacts.lua: what the game really shows for the guide's quests, noted as you play (the way
-- the Wowhead Client learns Forever's data), to check and fix Data.lua.
-- For a quest of the guide (root.Q) it notes:
--   g    who gives it: { npc id or 0, kind ("n" creature, "o" object, "i" item, "?"), map, x, y, name }
--   f    who takes it back: the same shape
--   lvl  the quest's level (quest log)
--   xp   { xp received (QUEST_TURNED_IN), your level then, the quest's level }: only a turn-in with no
--        level penalty (the quest at most 5 levels under yours) gives the quest's full Forever XP
--   nopre { [id] = true }: a prerequisite Data.lua lists that you had NOT done when you took the quest
--        (so the game does not need it)
-- Kept in WLWritsDB.qfacts[quest] (every character of the account), with n = how many times seen.
-- Guild: each new fact is sent once (prefix WLHqf, "G|quest|kind|npc|map|x|y", "F|...", "X|quest|xp|
-- level|quest level", "L|quest|level", "N|quest|prereq"); a guild mate's fact fills what we lack and
-- counts as one more sighting when it agrees. "/wlh diag quetes" lists what differs from Data.lua.
-- Nothing is read or sent in combat-locked ways: plain events, secret values skipped.
local ADDON, root = ...
local ns = root.Writs
local WP = ns.WP
local L = ns.L

ns.AddEnglish({
    ["Relevés de quêtes : %d quêtes du guide vues en jeu (%d par la guilde)."] = "Quest records: %d guide quests seen in game (%d from the guild).",
    ["Aucune différence avec les données du guide pour l'instant."] = "No difference with the guide's data so far.",
    ["%d différence(s) avec les données du guide (détail dans WLWritsDB.qfactsDiff) :"] = "%d difference(s) with the guide's data (details in WLWritsDB.qfactsDiff):",
})

local PREFIX = "WLHqf"
local QF = {}
WP.QuestFacts = QF

local function IsSecret(v) return issecretvalue ~= nil and issecretvalue(v) == true end
local function Num(v) if type(v) == "number" and v == v and v ~= math.huge and v ~= -math.huge and not IsSecret(v) then return v end end
local function Str(v) if type(v) == "string" and not IsSecret(v) and v ~= "" then return v end end

local function DB()
    if type(WLWritsDB) ~= "table" then return nil end
    if type(WLWritsDB.qfacts) ~= "table" then WLWritsDB.qfacts = {} end
    return WLWritsDB.qfacts
end
local function Known(qid) return qid and root.Q and root.Q[qid] ~= nil end
local function Row(qid)
    local db = DB(); if not db then return nil end
    local r = db[qid]
    if type(r) ~= "table" then r = {}; db[qid] = r end
    return r
end

-- the unit "npc" (the quest window's giver): id and kind from its GUID ("Creature-0-...-<id>-...")
local function Who(unit)
    local guid = UnitGUID and UnitGUID(unit)
    guid = Str(guid)
    local name = Str(UnitName and UnitName(unit))
    if not guid then return 0, "?", name end
    local kind, id = guid:match("^(%a+)%-%d+%-%d+%-%d+%-%d+%-(%d+)")
    if kind == "Creature" or kind == "Vehicle" then return tonumber(id) or 0, "n", name end
    if kind == "GameObject" then return tonumber(id) or 0, "o", name end
    if kind == "Player" then return 0, "p", name end
    if kind == "Item" then return 0, "i", name end
    return 0, "?", name
end
local function Here()
    local m = C_Map and C_Map.GetBestMapForUnit and Num(C_Map.GetBestMapForUnit("player"))
    if not m then return nil end
    local pos = C_Map.GetPlayerMapPosition and C_Map.GetPlayerMapPosition(m, "player")
    if not pos then return m end
    local x, y = pos.GetXY and pos:GetXY()
    x, y = Num(x), Num(y)
    if not (x and y) then return m end
    return m, math.floor(x * 1000 + 0.5) / 10, math.floor(y * 1000 + 0.5) / 10
end
local function PlayerLevel() return Num(UnitLevel and UnitLevel("player")) end
local function QuestLevel(qid)
    local Q = C_QuestLog
    if Q and Q.GetLogIndexForQuestID and Q.GetInfo then
        local i = Q.GetLogIndexForQuestID(qid)
        local info = i and Q.GetInfo(i)
        if type(info) == "table" then return Num(info.level) end
    end
    if GetNumQuestLogEntries and GetQuestLogTitle then
        for i = 1, GetNumQuestLogEntries() or 0 do
            local _, lvl, _, _, _, _, _, id = GetQuestLogTitle(i)
            if Num(id) == qid then return Num(lvl) end
        end
    end
end
local function Done(qid)
    local Q = C_QuestLog
    if Q and Q.IsQuestFlaggedCompleted then return Q.IsQuestFlaggedCompleted(qid) == true end
    return nil
end

-- ---------------------------------------------------------------- guild
local send
local function Share(msg)
    if not (IsInGuild and IsInGuild()) then return end
    if WLWritsDB and WLWritsDB.qfactsShare == false then return end
    send = send or (C_ChatInfo and C_ChatInfo.SendAddonMessage) or SendAddonMessage
    if send then pcall(send, PREFIX, msg, "GUILD") end
end
do
    local Register = (C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix) or RegisterAddonMessagePrefix
    if Register then pcall(Register, PREFIX) end
end

-- ---------------------------------------------------------------- noting
-- a place fact (g / f): the first one is kept; the same NPC again counts one more sighting; another
-- NPC is kept apart (alt) for the diag to show
local function SamePlace(a, b)
    if a[1] ~= 0 and b[1] ~= 0 then return a[1] == b[1] end
    return a[6] ~= nil and a[6] == b[6]
end
local function NotePlace(qid, key, fact, guild)
    local r = Row(qid); if not r then return false end
    local cur = r[key]
    if type(cur) ~= "table" then
        fact.n, fact.guild = 1, guild or nil
        r[key] = fact
        return true
    end
    if SamePlace(cur, fact) then cur.n = (cur.n or 1) + 1; return false end
    r[key .. "alt"] = fact
    return false
end

function QF.NoteGiver(qid, npc, kind, m, x, y, name, guild)
    if not Known(qid) then return false end
    local new = NotePlace(qid, "g", { npc or 0, kind or "?", m, x, y, name }, guild)
    if new and not guild then Share(string.format("G|%d|%s|%d|%s|%s|%s", qid, kind or "?", npc or 0, m or "", x or "", y or "")) end
    return new
end
function QF.NoteTurnIn(qid, npc, kind, m, x, y, name, guild)
    if not Known(qid) then return false end
    local new = NotePlace(qid, "f", { npc or 0, kind or "?", m, x, y, name }, guild)
    if new and not guild then Share(string.format("F|%d|%s|%d|%s|%s|%s", qid, kind or "?", npc or 0, m or "", x or "", y or "")) end
    return new
end
function QF.NoteLevel(qid, lvl, guild)
    if not (Known(qid) and Num(lvl)) then return false end
    local r = Row(qid)
    if r.lvl == lvl then r.lvln = (r.lvln or 1) + 1; return false end
    if r.lvl then return false end
    r.lvl, r.lvln = lvl, 1
    if not guild then Share(string.format("L|%d|%d", qid, lvl)) end
    return true
end
-- full XP only: no level penalty (quest level >= player level - 5)
function QF.NoteXP(qid, xp, plvl, qlvl, guild)
    if not (Known(qid) and Num(xp) and xp > 0 and Num(plvl)) then return false end
    qlvl = Num(qlvl) or (root.Q[qid] and root.Q[qid].l)
    if not qlvl or plvl - qlvl > 5 or plvl >= 60 then return false end
    local r = Row(qid)
    if type(r.xp) == "table" then
        if r.xp[1] == xp then r.xp.n = (r.xp.n or 1) + 1 end
        return false
    end
    r.xp = { xp, plvl, qlvl, n = 1 }
    if not guild then Share(string.format("X|%d|%d|%d|%d", qid, xp, plvl, qlvl)) end
    return true
end
function QF.NoteNoPrereq(qid, pid, guild)
    if not (Known(qid) and Num(pid)) then return false end
    local r = Row(qid)
    r.nopre = r.nopre or {}
    if r.nopre[pid] then return false end
    r.nopre[pid] = true
    if not guild then Share(string.format("N|%d|%d", qid, pid)) end
    return true
end

-- a guild mate's message; true when something was noted
function QF.OnShare(msg)
    if type(msg) ~= "string" or IsSecret(msg) or #msg > 80 then return false end
    local t = {}
    for v in (msg .. "|"):gmatch("([^|]*)|") do t[#t + 1] = v end
    local verb, qid = t[1], tonumber(t[2])
    if not Known(qid) then return false end
    if verb == "G" or verb == "F" then
        local kind = (t[3] == "n" or t[3] == "o" or t[3] == "i" or t[3] == "p") and t[3] or "?"
        local fn = verb == "G" and QF.NoteGiver or QF.NoteTurnIn
        return fn(qid, tonumber(t[4]) or 0, kind, tonumber(t[5]), tonumber(t[6]), tonumber(t[7]), nil, true)
    elseif verb == "L" then return QF.NoteLevel(qid, tonumber(t[3]), true)
    elseif verb == "X" then return QF.NoteXP(qid, tonumber(t[3]), tonumber(t[4]), tonumber(t[5]), true)
    elseif verb == "N" then return QF.NoteNoPrereq(qid, tonumber(t[3]), true) end
    return false
end

-- ---------------------------------------------------------------- events
local detail, complete = {}, {}
local function OnDetail()
    local qid = Num(GetQuestID and GetQuestID())
    if not Known(qid) then return end
    local npc, kind, name = Who("npc")
    if kind == "p" then return end                 -- shared by a group member: not the giver
    local m, x, y = Here()
    detail[qid] = { npc, kind, m, x, y, name }
end
local function OnAccepted(qid)
    if not Known(qid) then return end
    local d = detail[qid]; detail[qid] = nil
    if d then QF.NoteGiver(qid, d[1], d[2], d[3], d[4], d[5], d[6]) end
    QF.NoteLevel(qid, QuestLevel(qid))
    -- a listed prerequisite not done: the game did not need it
    for _, pid in ipairs(root.Q[qid].p or {}) do
        if Done(pid) == false then QF.NoteNoPrereq(qid, pid) end
    end
end
local function OnComplete()
    local qid = Num(GetQuestID and GetQuestID())
    if not Known(qid) then return end
    local npc, kind, name = Who("npc")
    local m, x, y = Here()
    complete[qid] = { npc, kind, m, x, y, name, QuestLevel(qid) }
end
local function OnTurnedIn(qid, xp)
    if not Known(qid) then return end
    local c = complete[qid]; complete[qid] = nil
    if c then QF.NoteTurnIn(qid, c[1], c[2], c[3], c[4], c[5], c[6]) end
    -- the level up a turn-in may bring comes later: UnitLevel is still the level it was earned at
    QF.NoteXP(qid, Num(xp), PlayerLevel(), c and c[7])
end
QF._OnDetail, QF._OnAccepted, QF._OnComplete, QF._OnTurnedIn = OnDetail, OnAccepted, OnComplete, OnTurnedIn

local f = CreateFrame("Frame")
for _, e in ipairs({ "QUEST_DETAIL", "QUEST_ACCEPTED", "QUEST_COMPLETE", "QUEST_TURNED_IN", "CHAT_MSG_ADDON" }) do
    pcall(f.RegisterEvent, f, e)
end
f:SetScript("OnEvent", function(_, event, a1, a2, a3, a4)
    local ok = pcall(function()
        if event == "QUEST_DETAIL" then OnDetail()
        elseif event == "QUEST_ACCEPTED" then OnAccepted(Num(a2) or Num(a1))   -- classic: (index, id)
        elseif event == "QUEST_COMPLETE" then OnComplete()
        elseif event == "QUEST_TURNED_IN" then OnTurnedIn(Num(a1), a2)
        elseif event == "CHAT_MSG_ADDON" then
            if a1 == PREFIX and a3 == "GUILD" then
                local me = UnitName and UnitName("player")
                local who = Str(a4)
                if who and me and who:gsub("%-.*$", "") == me then return end
                QF.OnShare(a2)
            end
        end
    end)
    return ok
end)

-- ---------------------------------------------------------------- what differs from Data.lua
local function Norm(s) return (tostring(s or ""):lower():gsub("[^%w]", "")) end
function QF.Differences()
    local db, out = DB() or {}, {}
    for qid, r in pairs(db) do
        local q = root.Q and root.Q[qid]
        if q and type(r) == "table" then
            local function add(what, ours, game) out[#out + 1] = { qid, q.n, what, ours, game } end
            if r.lvl and q.l and r.lvl ~= q.l then add("level", q.l, r.lvl) end
            -- names: only on an English client (Data.lua's names are English; the npc ids are read offline)
            local en = ns.English == nil or ns.English() == true
            if en and type(r.g) == "table" and r.g[6] and q.s and q.s.n and not q.s.i and Norm(r.g[6]) ~= Norm(q.s.n) and Norm(r.g[6]) ~= Norm(root.LN and root.LN("npc", q.s.n)) then
                add("giver", q.s.n, r.g[6])
            end
            if en and type(r.f) == "table" and r.f[6] and q.f and q.f.n and not q.f.i and Norm(r.f[6]) ~= Norm(q.f.n) and Norm(r.f[6]) ~= Norm(root.LN and root.LN("npc", q.f.n)) then
                add("turn-in", q.f.n, r.f[6])
            end
            if type(r.xp) == "table" and q.xp and math.abs(r.xp[1] - q.xp) > 60 then add("xp", q.xp, r.xp[1]) end
            for pid in pairs(r.nopre or {}) do add("not a prerequisite", pid, "not done when taken") end
        end
    end
    table.sort(out, function(a, b) if a[1] ~= b[1] then return a[1] < b[1] end return a[3] < b[3] end)
    return out
end
function QF.Diag()
    local db = DB() or {}
    local n, g = 0, 0
    for _, r in pairs(db) do
        n = n + 1
        if (type(r.g) == "table" and r.g.guild) or (type(r.f) == "table" and r.f.guild) then g = g + 1 end
    end
    local p = WP.Print or print
    p(string.format(L("Relevés de quêtes : %d quêtes du guide vues en jeu (%d par la guilde)."), n, g))
    local d = QF.Differences()
    if WLWritsDB then WLWritsDB.qfactsDiff = d end
    if #d == 0 then p(L("Aucune différence avec les données du guide pour l'instant.")); return d end
    p(string.format(L("%d différence(s) avec les données du guide (détail dans WLWritsDB.qfactsDiff) :"), #d))
    for i = 1, math.min(#d, 15) do
        local e = d[i]
        p(string.format("  %d %s : %s %s -> %s", e[1], tostring(e[2]), e[3], tostring(e[4]), tostring(e[5])))
    end
    return d
end
