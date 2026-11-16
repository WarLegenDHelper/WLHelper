-- Quêtes du groupe, même sans WL Helper chez les autres : qui a la quête, qui l'a déjà rendue, qui
-- ne peut pas la prendre et pourquoi. Trois sources, la plus récente l'emporte pour un même
-- (membre, quête) :
--  1. le jeu : C_QuestLog.IsUnitOnQuest(unité, quête) pour les quêtes de TON journal (il ne répond
--     que pour celles-là), relu sur GROUP_ROSTER_UPDATE, QUEST_LOG_UPDATE, UNIT_QUEST_LOG_CHANGED
--     (0,5 s au plus souvent) ;
--  2. les réponses du jeu à un partage (« X a déjà terminé cette quête », « X n'est pas éligible »...),
--     rattachées à la quête partagée (QuestLogPushQuest suivi, réponse attendue 10 s, 60 s pour un clic) ;
--  3. les messages de WL Helper chez les membres qui l'ont (Sync.lua, ns.party).
-- Puis une raison en mots, calculée sans message : niveau trop bas, quête qui ne se partage pas
-- (où la prendre), quête d'avant qui manque, quête qui se prend dans le donjon, ou inconnu.
-- ns.PartyQuests : Members(), State(name, qid, dkey), Summary(qid, dkey), Known(name), OnChange(fn), Reset().
-- States (the Overview's CELL words): on, ready, done, take, low, pre, na, invalid, declined, full,
-- busy, far, sent, unknown. Sources: "sync" (WL Helper), "push" (the game's answer to a share),
-- "game" (IsUnitOnQuest), "data" (computed from the guide's data), nil (nothing known).
local ADDON, ns = ...
local PQ = {}
ns.PartyQuests = PQ

-- =====================================================================
--  Strings (kept here: French for a frFR client, English otherwise)
-- =====================================================================
local STR = {
  fr = {
    ON = "a la quête dans son journal", ACCEPTED = "a accepté ta quête", READY = "a fini la quête : prête à rendre",
    DONE = "a déjà rendu cette quête",
    LOW = "niveau trop bas (%d, il faut %d)", LOW_NOLVL = "niveau trop bas (il faut %d)",
    NOSHARE = "ne se partage pas : à prendre auprès de %s",
    INSIDE = "se prend dans le donjon", ITEM = "commence avec l'objet %s",
    PRE = "a besoin de « %s » avant", PRE_MAYBE = "pas éligible : il lui manque peut-être « %s »",
    INVALID = "pas éligible (classe, faction, race ou quête d'avant)", INVALID_WHY = "pas éligible : %s",
    NA = "pas pour ce personnage (classe, faction ou race)",
    DECLINED = "a refusé ta quête", FULL = "journal de quêtes plein", BUSY = "occupé : partage de nouveau",
    FAR = "trop loin pour la recevoir", EXPIRED = "n'a pas répondu à temps : partage de nouveau",
    NOTPARTY = "n'est plus dans le groupe", NOTDAILY = "ne peut plus prendre de quête journalière aujourd'hui",
    DIFFSERVER = "journalière d'un autre royaume : ne peut pas la prendre",
    SENT = "envoyée : en attente de sa réponse",
    TAKE = "ne l'a pas : partage-la", TAKE_AT = "ne l'a pas : à prendre auprès de %s",
    UNKNOWN = "inconnu : partage la quête pour savoir",
    UNKNOWN_NOLOG = "inconnu : prends la quête puis partage-la pour savoir",
    OFFLINE = "hors ligne", SOMEONE = "son donneur",
  },
  en = {
    ON = "has the quest in their log", ACCEPTED = "accepted your quest", READY = "finished the quest: ready to turn in",
    DONE = "already turned this quest in",
    LOW = "level too low (%d, needs %d)", LOW_NOLVL = "level too low (needs %d)",
    NOSHARE = "cannot be shared: take it from %s",
    INSIDE = "taken inside the dungeon", ITEM = "starts from the item %s",
    PRE = "needs \"%s\" first", PRE_MAYBE = "not eligible: maybe missing \"%s\"",
    INVALID = "not eligible (class, faction, race or an earlier quest)", INVALID_WHY = "not eligible: %s",
    NA = "not for this character (class, faction or race)",
    DECLINED = "declined your quest", FULL = "quest log full", BUSY = "busy: share again",
    FAR = "too far away to receive it", EXPIRED = "did not answer in time: share again",
    NOTPARTY = "no longer in the group", NOTDAILY = "cannot take more daily quests today",
    DIFFSERVER = "daily quest from another realm: cannot take it",
    SENT = "sent: waiting for their answer",
    TAKE = "does not have it: share it", TAKE_AT = "does not have it: take it from %s",
    UNKNOWN = "unknown: share the quest to find out",
    UNKNOWN_NOLOG = "unknown: take the quest, then share it to find out",
    OFFLINE = "offline", SOMEONE = "its quest giver",
  },
}
PQ.STR = STR
local function S()
  local loc = GetLocale and GetLocale()
  return (loc == "frFR") and STR.fr or STR.en
end

-- =====================================================================
--  Small helpers
-- =====================================================================
local function secret(v) return issecretvalue ~= nil and issecretvalue(v) and true or false end
local function Now() local t = GetTime and GetTime(); return (type(t) == "number" and not secret(t)) and t or 0 end
local function Num(v) return (type(v) == "number" and not secret(v)) and v or nil end
local function Str(v) return (type(v) == "string" and not secret(v)) and v or nil end
-- "Bob-Realm" / "|cff..Bob|r" / "|Hplayer:Bob|h[Bob]|h" -> "Bob"
local function Short(name)
  name = Str(name)
  if not name then return nil end
  name = name:gsub("|H.-|h(.-)|h", "%1"):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("[%[%]]", "")
  name = name:match("^%s*(.-)%s*$")
  name = name:gsub("%-.*$", "")
  return name ~= "" and name or nil
end
local function Me() return Short(UnitName and UnitName("player")) end

local QUICK, SLOW = 10, 60      -- seconds an answer to a share can still come (at once / after a click)
local THROTTLE = 0.5            -- the game's IsUnitOnQuest is read at most this often
local MAXPUSH = 40              -- answers kept per member

-- state tables, only for the current group
local game = {}     -- [name][qid] = { v = bool, t = time the answer last changed }
local push = {}     -- [name][qid] = { s = state, kind, extra, t }
local pushQ = {}    -- [name] = { { qid, t }, ... } shares still waiting for this member's answer
local lastPush      -- { qid, t }: the quest shared last
local syncSeen, syncAt = {}, {}   -- the table ns.party[name] last seen, and when it arrived
local watchers = {}

-- =====================================================================
--  Change notifications (coalesced)
-- =====================================================================
local notifyQueued = false
local function Fire()
  notifyQueued = false
  for _, fn in ipairs(watchers) do pcall(fn) end
end
local function Changed()
  if notifyQueued then return end
  notifyQueued = true
  if C_Timer and C_Timer.After then C_Timer.After(0.2, Fire) else Fire() end
end
function PQ.OnChange(fn)
  if type(fn) ~= "function" then return end
  for _, f in ipairs(watchers) do if f == fn then return end end
  watchers[#watchers + 1] = fn
end

-- =====================================================================
--  Members
-- =====================================================================
local function RawMembers()
  if ns.GroupMembers then
    local ok, list = pcall(ns.GroupMembers)
    if ok and type(list) == "table" then return list end
  end
  local out = {}
  local n = Num(GetNumGroupMembers and GetNumGroupMembers()) or 0
  if n == 0 then return out end
  local raid = IsInRaid and IsInRaid()
  local me = Me()
  for k = 1, raid and n or math.min(4, n) do
    local unit = (raid and "raid" or "party") .. k
    local nm = Short(UnitName and UnitName(unit))
    if nm and nm ~= me then
      -- "a and f()" keeps only f's first value: the class token is the second
      local cls
      if UnitClass then cls = select(2, UnitClass(unit)) end
      out[#out + 1] = { name = nm, unit = unit, class = Str(cls) }
    end
  end
  return out
end

local memCache, memAt
-- -> { { name, unit, class, level, hasAddon } } in party / raid order (you are not in it)
function PQ.Members()
  local t = Now()
  if memCache and memAt == t then return memCache end
  local out = {}
  for _, m in ipairs(RawMembers()) do
    local lvl = m.unit and UnitLevel and Num(UnitLevel(m.unit))
    if lvl and lvl <= 0 then lvl = nil end
    out[#out + 1] = { name = m.name, unit = m.unit, class = m.class, level = lvl,
      hasAddon = (ns.HasHelper and ns.HasHelper(m.name)) and true or false }
  end
  memCache, memAt = out, t
  return out
end
local function MemberOf(name)
  for _, m in ipairs(PQ.Members()) do if m.name == name then return m end end
end
-- false only when the game plainly says offline (a secret or missing answer counts as online)
local function Online(unit)
  if not (unit and UnitIsConnected) then return true end
  local ok, c = pcall(UnitIsConnected, unit)
  if not ok or secret(c) then return true end
  return c ~= false
end

-- Sync.lua replaces ns.party[name] with a new table on each full message: stamp it when it changes
local function StampSync(name, list)
  if syncSeen[name] ~= list then syncSeen[name] = list; syncAt[name] = Now() end
end

-- =====================================================================
--  Source 1: the game's IsUnitOnQuest, for the quests of my log
-- =====================================================================
local lastPoll = -100
local function MyLogQuests()
  local out = {}
  local ok, log = pcall(ns.LogEntries or function() return {} end)
  if not ok or type(log) ~= "table" then return out, {} end
  for id in pairs(log) do if type(id) == "number" and id > 0 and ns.Q and ns.Q[id] then out[#out + 1] = id end end
  return out, log
end

function PQ.Refresh(force)
  local now = Now()
  if not force and now - lastPoll < THROTTLE then return end
  lastPoll = now
  local CQL = C_QuestLog
  local check = CQL and CQL.IsUnitOnQuest
  if type(check) ~= "function" then return end
  local qids = MyLogQuests()
  local inLog = {}
  for _, id in ipairs(qids) do inLog[id] = true end
  local changed = false
  local keep = {}
  for _, m in ipairs(PQ.Members()) do
    keep[m.name] = true
    local list = ns.party and ns.party[m.name]
    if type(list) == "table" then StampSync(m.name, list) end
    local online = Online(m.unit)
    local g = game[m.name]
    if not g then g = {}; game[m.name] = g end
    -- quests that left my log: the game no longer answers for them
    for id in pairs(g) do if not inLog[id] then g[id] = nil end end
    if online then
      for _, id in ipairs(qids) do
        local ok, v = pcall(check, m.unit, id)
        if ok and type(v) == "boolean" and not secret(v) then
          local e = g[id]
          if not e or e.v ~= v then g[id] = { v = v, t = now }; changed = true end
        end
      end
    end
  end
  for name in pairs(game) do if not keep[name] then game[name] = nil end end
  if changed then Changed() end
end

local pollQueued = false
local function PollSoon()
  if pollQueued then return end
  pollQueued = true
  -- forced: a lazy read just before must not swallow the change this event announced
  local fn = function() pollQueued = false; PQ.Refresh(true) end
  if C_Timer and C_Timer.After then C_Timer.After(THROTTLE, fn) else fn() end
end

-- =====================================================================
--  Source 2: the game's answers to a share
-- =====================================================================
-- global, state, kind, waits for the member's click
local PUSH = {
  { "ERR_QUEST_PUSH_ACCEPTED_S", "on", "accepted", true },
  { "ERR_QUEST_PUSH_ONQUEST_S", "on", "on" },
  { "ERR_QUEST_PUSH_ALREADY_DONE_S", "done", "done" },
  { "ERR_QUEST_PUSH_INVALID_S", "invalid", "invalid" },
  { "ERR_QUEST_PUSH_INVALID2_S", "invalid", "invalid" },
  { "ERR_QUEST_PUSH_INVALID_TO_RECIPIENT_S", "invalid", "invalid" },
  { "ERR_QUEST_PUSH_NOT_ALLOWED_S", "invalid", "invalid" },
  { "ERR_QUEST_PUSH_DECLINED_S", "declined", "declined", true },
  { "ERR_QUEST_PUSH_LOG_FULL_S", "full", "full" },
  { "ERR_QUEST_PUSH_BUSY_S", "busy", "busy" },
  { "ERR_QUEST_PUSH_TOO_FAR_S", "far", "far" },
  { "ERR_QUEST_PUSH_NOT_IN_PARTY_S", "busy", "notparty" },
  { "ERR_QUEST_PUSH_TIMER_EXPIRED_S", "busy", "expired", true },
  { "ERR_QUEST_PUSH_NOT_DAILY_S", "invalid", "notdaily" },
  { "ERR_QUEST_PUSH_DIFFERENT_SERVER_DAILY_S", "invalid", "diffserver" },
}
-- "%s has completed that quest." -> "^(.-) has completed that quest%.$" (%s and %1$s become captures).
-- order[i] = the argument the i-th capture holds (a French "%2$s ... %1$s" puts the name second).
-- A sentence with fewer than 4 letters of its own would match any line: not used.
local function PatternOf(fmt)
  local n, order = 0, {}
  local p = fmt:gsub("%%(%d?)%$?s", function(d) n = n + 1; order[n] = tonumber(d) or n; return "\1" end)
  if n == 0 then return nil end
  local lit = #(p:gsub("\1", ""))
  if lit < 4 then return nil end
  p = p:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1"):gsub("\1", "(.-)")
  return "^" .. p .. "$", lit, order
end
local patterns
local function Patterns()
  if patterns then return patterns end
  patterns = {}
  for _, e in ipairs(PUSH) do
    local fmt = _G[e[1]]
    if type(fmt) == "string" and not secret(fmt) then
      local pat, len, order = PatternOf(fmt)
      if pat then patterns[#patterns + 1] = { pat = pat, len = len, order = order, s = e[2], kind = e[3], slow = e[4] } end
    end
  end
  -- the most specific sentence first ("...: %s" before "...")
  table.sort(patterns, function(a, b) return a.len > b.len end)
  return patterns
end
function PQ._ResetPatterns() patterns = nil end

local function Take(who, slow)
  local q = pushQ[who]
  if not q then return nil end
  local now = Now()
  for i = #q, 1, -1 do if now - q[i].t > SLOW then table.remove(q, i) end end
  local pick = slow and 1 or #q
  local e = q[pick]
  if not e then return nil end
  if not slow and now - e.t > QUICK then return nil end
  table.remove(q, pick)
  return e.qid
end

local function Record(who, qid, s, kind, extra)
  local p = push[who]
  if not p then p = {}; push[who] = p end
  p[qid] = { s = s, kind = kind, extra = extra, t = Now() }
  -- bounded: the oldest answers go
  local n, oldest, oid = 0, nil, nil
  for id, e in pairs(p) do n = n + 1; if not oldest or e.t < oldest then oldest, oid = e.t, id end end
  if n > MAXPUSH and oid then p[oid] = nil end
end

-- One system line; true when it was a share answer we could attribute.
function PQ.OnSystemMessage(text)
  text = Str(text)
  if not text then return false end
  for _, p in ipairs(Patterns()) do
    local caps = { text:match(p.pat) }
    if caps[1] ~= nil then
      local arg = {}
      for i, a in ipairs(p.order) do arg[a] = caps[i] end
      local who, extra = Short(arg[1]), arg[2]
      if not who then return false end
      local qid = Take(who, p.slow)
      -- a member who was not in the list at the share (joined since): the quest shared last.
      -- Only for members: a stranger's name never gets a record.
      if not qid and not pushQ[who] and lastPush and MemberOf(who)
        and Now() - lastPush.t <= (p.slow and SLOW or QUICK) then qid = lastPush.qid end
      if not qid then return false end
      Record(who, qid, p.s, p.kind, Str(extra))
      Changed()
      return true
    end
  end
  return false
end

-- The quest being shared: the quest log's selection (classic index or questID), else the last
-- selection we saw.
local lastSel
local function QidOfIndex(i)
  i = Num(i)
  if not i or i <= 0 then return nil end
  if GetQuestLogTitle then
    local ok, _, _, _, isHeader, _, _, _, qid = pcall(GetQuestLogTitle, i)
    if ok and not isHeader and Num(qid) and qid > 0 then return qid end
  end
  local ok, log = pcall(ns.LogEntries or function() return {} end)
  if ok and type(log) == "table" then for id, e in pairs(log) do if e.index == i then return id end end end
end
local function SelectedQuest()
  if GetQuestLogSelection then
    local ok, i = pcall(GetQuestLogSelection)
    local qid = ok and QidOfIndex(i)
    if qid then return qid end
  end
  local CQL = C_QuestLog
  if CQL and CQL.GetSelectedQuest then
    local ok, qid = pcall(CQL.GetSelectedQuest)
    qid = ok and Num(qid)
    if qid and qid > 0 then return qid end
  end
  if lastSel and Now() - lastSel.t <= 2 then return lastSel.qid end
end

-- A share went out (QuestLogPushQuest): remember it per member, until they answer.
function PQ.OnPushed(qid)
  qid = Num(qid) or SelectedQuest()
  if not qid or not (ns.Q and ns.Q[qid]) then return end
  local now = Now()
  lastPush = { qid = qid, t = now }
  for _, m in ipairs(PQ.Members()) do
    -- an offline member gets nothing and never answers
    if Online(m.unit) then
      local q = pushQ[m.name] or {}
      pushQ[m.name] = q
      q[#q + 1] = { qid = qid, t = now }
      while #q > 12 do table.remove(q, 1) end
      -- "sent" until the game answers, unless we already know they have it or turned it in
      local s = PQ.State(m.name, qid)
      if s ~= "on" and s ~= "ready" and s ~= "done" then Record(m.name, qid, "sent", "sent") end
    end
  end
  Changed()
end

local function Hook(tbl, name, fn)
  if tbl then
    if type(tbl[name]) == "function" and hooksecurefunc then pcall(hooksecurefunc, tbl, name, fn) end
  elseif type(_G[name]) == "function" and hooksecurefunc then pcall(hooksecurefunc, name, fn) end
end
Hook(nil, "QuestLogPushQuest", function(arg)
  -- a number here is a log index on clients that take one
  local qid = arg and QidOfIndex(arg) or nil
  PQ.OnPushed(qid)
end)
Hook(nil, "SelectQuestLogEntry", function(i)
  local qid = QidOfIndex(i)
  if qid then lastSel = { qid = qid, t = Now() } end
end)
-- Sync.lua falls back to C_QuestLog.PushQuest when the client has no QuestLogPushQuest
if C_QuestLog and type(QuestLogPushQuest) ~= "function" then
  Hook(C_QuestLog, "PushQuest", function(arg) PQ.OnPushed(Num(arg)) end)
end
if C_QuestLog then
  Hook(C_QuestLog, "SetSelectedQuest", function(qid)
    qid = Num(qid)
    if qid and qid > 0 then lastSel = { qid = qid, t = Now() } end
  end)
end

-- =====================================================================
--  Merge: newest wins, the more telling of two answers that agree
-- =====================================================================
-- what "has it in the log" (game true) and "not in the log" (game false) agree with
local AGREE_ON = { on = true, ready = true }
local AGREE_OFF = { take = true, low = true, pre = true, na = true, invalid = true, declined = true,
  full = true, busy = true, far = true, done = true }

local function SyncCand(name, qid, dkey)
  local list = ns.party and ns.party[name]
  if type(list) ~= "table" then return nil end
  StampSync(name, list)
  local s = list[qid]
  if s then
    return { s = s, src = "sync", t = syncAt[name] or 0, pre = ns.partyPre and ns.partyPre[name] and ns.partyPre[name][qid] }
  end
  if dkey and ns.partyKeys and ns.partyKeys[name] and ns.partyKeys[name][dkey] then
    return { s = "na", src = "sync", t = syncAt[name] or 0 }
  end
end

local function Merged(name, qid, dkey)
  local best = SyncCand(name, qid, dkey)
  local p = push[name] and push[name][qid]
  if p and not (p.s == "sent" and Now() - p.t > SLOW) then
    if not best or p.t > best.t then best = { s = p.s, src = "push", t = p.t, kind = p.kind, extra = p.extra } end
  end
  local g = game[name] and game[name][qid]
  if g then
    local gs = g.v and "on" or "take"
    if not best then
      best = { s = gs, src = "game", t = g.t }
    elseif best.s == "sent" then
      -- a share waiting for its answer: only a newer change of the game's answer replaces it
      if g.t > best.t then best = { s = gs, src = "game", t = g.t } end
    elseif (g.v and AGREE_ON[best.s]) or (not g.v and AGREE_OFF[best.s]) then
      -- they agree: keep the more telling answer (ready, done, declined...), "on"/"take" from the game
      if best.s == gs and g.t > best.t then best = { s = gs, src = "game", t = g.t } end
    elseif g.t > best.t then
      -- they disagree: the newer one (a tie goes to WL Helper's message or the share's answer)
      best = { s = gs, src = "game", t = g.t }
    end
  end
  return best
end

-- =====================================================================
--  Source 3: reasons from the guide's data
-- =====================================================================
local function ZoneName(m)
  if not (m and C_Map and C_Map.GetMapInfo) then return nil end
  local ok, info = pcall(C_Map.GetMapInfo, m)
  local n = ok and type(info) == "table" and Str(info.name)
  return (n and n ~= "") and n or nil
end
local function QName(id)
  if ns.QName then local ok, n = pcall(ns.QName, id); if ok and n then return n end end
  return tostring(id)
end
local function Inside(q) return (q.s and q.s.i) or (q.si and not (q.s and q.s.m)) end
-- "Rahauro (Thunder Bluff)", "Rahauro" or the giver words
local function Giver(q)
  local s, L = q.s, S()
  if q.si and (not s or s.i) then return nil, L.ITEM:format(q.si) end
  if s and s.n then
    local z = not s.i and ZoneName(s.m)
    return z and (s.n .. " (" .. z .. ")") or s.n
  end
  return L.SOMEONE
end
local function InMyLog(qid)
  local ok, log = pcall(ns.LogEntries or function() return {} end)
  return ok and type(log) == "table" and log[qid] ~= nil, ok and log or {}
end
local function Shareable(qid, log)
  local q = ns.Q and ns.Q[qid]
  if q and q.sh == false then return false end
  local CQL = C_QuestLog
  if log[qid] and CQL and CQL.IsPushableQuest then
    local ok, v = pcall(CQL.IsPushableQuest, qid)
    if ok and type(v) == "boolean" and not secret(v) then return v end
  end
  return true
end
-- the member is in the log of one of the quest's prerequisites (the game said so): it is missing
local function OnPrereq(name, q)
  local g = game[name]
  if not g then return nil end
  for _, pid in ipairs(q.p or {}) do local e = g[pid]; if e and e.v then return pid end end
end

local REASON = { declined = "DECLINED", full = "FULL", busy = "BUSY", far = "FAR", expired = "EXPIRED",
  notparty = "NOTPARTY", notdaily = "NOTDAILY", diffserver = "DIFFSERVER", sent = "SENT", na = "NA" }

-- -> state, reason text, source, missing prerequisite id
function PQ.State(name, qid, dkey)
  local L = S()
  name = Short(name)
  qid = Num(qid)
  if not (name and qid) then return "unknown", L.UNKNOWN, nil end
  -- a lazy read of the game's answers: throttled, and nothing when nothing changed
  PQ.Refresh()
  local q = (ns.Q and ns.Q[qid]) or {}
  local m = MemberOf(name)
  local lvl = m and m.level
  local need = Num(q.r)
  local low = lvl and need and lvl < need
  local inLog, log = InMyLog(qid)
  local c = Merged(name, qid, dkey)
  local s, src = c and c.s or "unknown", c and c.src
  local function lowText() return lvl and L.LOW:format(lvl, need) or L.LOW_NOLVL:format(need or 0) end
  -- why a member cannot have it from my share
  local function howToGet(st)
    if Inside(q) then return L.INSIDE end
    local g, itemText = Giver(q)
    if itemText then return itemText end
    if not Shareable(qid, log) then return L.NOSHARE:format(g) end
    if not inLog then return st == "take" and L.TAKE_AT:format(g) or L.UNKNOWN_NOLOG end
  end

  if s == "on" then return "on", (c.kind == "accepted") and L.ACCEPTED or L.ON, src end
  if s == "ready" then return "ready", L.READY, src end
  if s == "done" then return "done", L.DONE, src end
  if s == "low" then return "low", lowText(), src end
  if s == "pre" then
    local pid = c.pre or OnPrereq(name, q) or (q.p and q.p[1])
    return "pre", pid and L.PRE:format(QName(pid)) or L.INVALID, src, pid
  end
  if s == "invalid" then
    if low then return "invalid", lowText(), src end
    local pid = OnPrereq(name, q)
    if pid then return "invalid", L.PRE:format(QName(pid)), src, pid end
    if c.extra and c.extra ~= "" then return "invalid", L.INVALID_WHY:format(c.extra), src end
    if REASON[c.kind or ""] then return "invalid", L[REASON[c.kind]], src end
    pid = q.p and q.p[1]
    if pid then return "invalid", L.PRE_MAYBE:format(QName(pid)), src, pid end
    return "invalid", L.INVALID, src
  end
  if s == "na" then return "na", L.NA, src end
  if s == "sent" then
    -- the answer will say no: say why now
    if low then return "low", lowText(), "data" end
    local pid = OnPrereq(name, q)
    if pid then return "pre", L.PRE:format(QName(pid)), "game", pid end
    return "sent", L.SENT, src
  end
  if REASON[c and c.kind or ""] and s ~= "take" then return s, L[REASON[c.kind]], src end
  if s == "take" then
    if low then return "low", lowText(), "data" end
    local pid = OnPrereq(name, q)
    if pid then return "pre", L.PRE:format(QName(pid)), "game", pid end
    return "take", howToGet("take") or L.TAKE, src
  end
  if s ~= "unknown" then return s, L.UNKNOWN, src end
  -- nothing from the game nor WL Helper
  if low then return "low", lowText(), "data" end
  local pid = OnPrereq(name, q)
  if pid then return "pre", L.PRE:format(QName(pid)), "game", pid end
  if m and not Online(m.unit) then return "unknown", L.OFFLINE, nil end
  local why = howToGet("unknown")
  if why then return "unknown", why, "data" end
  return "unknown", L.UNKNOWN, nil
end

-- What the group stands at on one quest.
local BUCKET = { on = "has", ready = "has", done = "done", low = "cannot", pre = "cannot", invalid = "cannot", na = "cannot",
  take = "missing", declined = "missing", full = "missing", busy = "missing", far = "missing", sent = "unknown", unknown = "unknown" }
function PQ.Summary(qid, dkey)
  local out = { has = 0, done = 0, cannot = 0, missing = 0, unknown = 0, total = 0, names = { has = {}, done = {}, cannot = {}, missing = {}, unknown = {} } }
  for _, m in ipairs(PQ.Members()) do
    local s = PQ.State(m.name, qid, dkey)
    local b = BUCKET[s] or "unknown"
    out[b] = out[b] + 1
    out.total = out.total + 1
    local l = out.names[b]; l[#l + 1] = m.name
  end
  return out
end

-- Something is known of this member's quests (WL Helper, the game's IsUnitOnQuest, or a share's answer).
function PQ.Known(name)
  name = Short(name)
  if not name then return false end
  if ns.HasHelper and ns.HasHelper(name) then return true end
  PQ.Refresh()
  if next(game[name] or {}) then return true end
  for _, e in pairs(push[name] or {}) do if e.s ~= "sent" then return true end end
  return false
end

function PQ.Reset()
  local had = lastPush ~= nil
  for _, t in ipairs({ game, push, pushQ, syncSeen, syncAt }) do
    if next(t) then had = true end
    for k in pairs(t) do t[k] = nil end
  end
  lastPush, lastSel, memCache, memAt = nil, nil, nil, nil
  lastPoll = -100
  if had then Changed() end
end

local function Prune()
  local keep = {}
  for _, m in ipairs(PQ.Members()) do keep[m.name] = true end
  for _, t in ipairs({ game, push, pushQ, syncSeen, syncAt }) do
    for who in pairs(t) do if not keep[who] then t[who] = nil end end
  end
end

-- =====================================================================
--  Events
-- =====================================================================
local ev = CreateFrame("Frame")
PQ.frame = ev
for _, e in ipairs({ "GROUP_ROSTER_UPDATE", "QUEST_LOG_UPDATE", "UNIT_QUEST_LOG_CHANGED", "CHAT_MSG_SYSTEM",
  "PLAYER_ENTERING_WORLD" }) do pcall(ev.RegisterEvent, ev, e) end
ev:SetScript("OnEvent", function(_, e, ...)
  if e == "CHAT_MSG_SYSTEM" then pcall(PQ.OnSystemMessage, (...)) return end
  if e == "GROUP_ROSTER_UPDATE" or e == "PLAYER_ENTERING_WORLD" then
    memCache, memAt = nil, nil
    if IsInGroup and not IsInGroup() then PQ.Reset() return end
    Prune()
  end
  PollSoon()
end)
