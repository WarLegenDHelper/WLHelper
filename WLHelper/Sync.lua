-- Synchronisation de groupe : chaque membre qui a WL Helper envoie, sur le canal d'addon du groupe
-- (jamais en chuchotement), l'état des quêtes de son journal et de celles des donjons choisis par le
-- groupe : dans le journal, prête, rendue, à prendre, niveau trop bas, ou le maillon de chaîne qui
-- manque. Les membres sans WL Helper sont remplis par les messages du jeu après un partage de quête
-- (« X a déjà terminé cette quête », « X a accepté ta quête »...).
-- ns.party[who][qid] = "on" | "ready" | "done" | "take" | "low" | "pre"; ns.partyPre[who][qid] = id
-- of the missing link; ns.partyPush[who][qid] = what the game said after a share.
-- ns.partyStep[who] = the key of the guide step the member is at (one "@<key>" token at the end of
-- the message; older versions skip it), for the guide's "See where <member> is".
local ADDON, ns = ...
local PREFIX = "WLDT"
ns.party = {}
ns.partyPre = {}
ns.partyKeys = {}    -- [who] = { dkey = true }: dungeons whose quests the member's last message covers
ns.partyPush = {}
ns.partyStep = {}
ns.syncKeys = {}     -- dungeons the group asked about (my summary, the others' requests)

local CI = C_ChatInfo
local Register = (CI and CI.RegisterAddonMessagePrefix) or RegisterAddonMessagePrefix
if Register then pcall(Register, PREFIX) end
-- the game's sender, looked up when sending (group channels only: never a whisper)
local function SendFn() return (C_ChatInfo and C_ChatInfo.SendAddonMessage) or SendAddonMessage end
local function Send(prefix, msg, ch)
  if ch ~= "PARTY" and ch ~= "RAID" and ch ~= "INSTANCE_CHAT" then return end
  local fn = SendFn()
  if fn then return fn(prefix, msg, ch) end
end

local function secret(v) return issecretvalue ~= nil and issecretvalue(v) end
local function Now() return (GetTime and GetTime()) or 0 end

local function Channel()
  if IsInRaid and IsInRaid() then return "RAID" end
  if IsInGroup and IsInGroup() then return "PARTY" end
end

local function Short(name) return type(name) == "string" and (name:gsub("%-.*$", "")) or nil end
local function Me() return UnitName and UnitName("player") end

-- The other members of the group, in party / raid order: { { name, unit, class } }.
function ns.GroupMembers()
  local out = {}
  local n = (GetNumGroupMembers and GetNumGroupMembers()) or 0
  if n == 0 then return out end
  local raid = IsInRaid and IsInRaid()
  local me = Me()
  local last = raid and n or math.min(4, n)
  for k = 1, last do
    local unit = (raid and "raid" or "party") .. k
    local nm = UnitName and UnitName(unit)
    if type(nm) == "string" and not secret(nm) then
      nm = Short(nm)
      if nm ~= me then
        local _, cls = UnitClass and UnitClass(unit)
        out[#out + 1] = { name = nm, unit = unit, class = (type(cls) == "string" and not secret(cls)) and cls or nil }
      end
    end
  end
  return out
end

-- =====================================================================
--  What I send: my quests, for my log and the group's dungeons
-- =====================================================================
-- token = quest id + code: o in the log, r ready, d turned in, t to take, l level too low,
-- p<id> a prerequisite missing (the first link not turned in)
local function Wanted()
  local set, n = {}, 0
  for k in pairs(WLDTDB and WLDTDB.sel or {}) do if ns.D[k] and not set[k] then set[k] = true; n = n + 1 end end
  for k in pairs(ns.syncKeys) do if ns.D[k] and not set[k] and n < 12 then set[k] = true; n = n + 1 end end
  return set
end

function ns.SyncTokens()
  local log = ns.LogEntries()
  local _, cls = UnitClass("player")
  local lvl = UnitLevel and UnitLevel("player")
  lvl = (type(lvl) == "number" and not secret(lvl)) and lvl or 1
  local toks, seen = {}, {}
  local function add(qid, code) if not seen[qid] then seen[qid] = true; toks[#toks + 1] = qid .. code end end
  for id, e in pairs(log) do if ns.Q[id] and id > 0 then add(id, e.complete and "r" or "o") end end
  local keys = Wanted()
  local list = {}
  for k in pairs(keys) do list[#list + 1] = k end
  table.sort(list)
  for _, k in ipairs(list) do
    for _, qid in ipairs(ns.DungeonQuests(k, cls)) do
      if qid > 0 and not seen[qid] then
        local st = ns.State(log, qid)
        if st == "done" then add(qid, "d")
        elseif st == "ready" then add(qid, "r")
        elseif st == "on" then add(qid, "o")
        else
          local pre = ns.QuestPreInfo and ns.QuestPreInfo(qid, log, cls)
          local q = ns.Q[qid]
          if pre and pre.nextPid and pre.nextPid > 0 then add(qid, "p" .. pre.nextPid)
          elseif q and q.r and lvl < q.r then add(qid, "l")
          else add(qid, "t") end
        end
      end
    end
  end
  table.sort(toks)
  return toks, list
end

-- Messages fit the addon message limit (255 bytes): "2|i/n|keys:tok,tok" cut at 230 bytes, the
-- dungeon keys only in the first part.
local LIMIT = 230
function ns.SyncChunks(toks, keys)
  local chunks, cur = {}, ""
  local head1 = table.concat(keys or {}, ",")
  if #head1 > 120 then head1 = head1:sub(1, 120):gsub(",[^,]*$", "") end
  local function room() return LIMIT - 12 - (#chunks == 0 and #head1 or 0) end
  for _, s in ipairs(toks) do
    if cur ~= "" and #cur + #s + 1 > room() then table.insert(chunks, cur); cur = "" end
    cur = (cur == "" and s) or (cur .. "," .. s)
  end
  table.insert(chunks, cur)
  local out = {}
  for i, c in ipairs(chunks) do out[i] = ("2|%d/%d|%s:%s"):format(i, #chunks, i == 1 and head1 or "", c) end
  return out
end

local lastSent, lastAt, pending = "", -100, false
local MIN_GAP = 3
local Schedule

-- The tokens are rebuilt only when what they say can have changed: the quest log (ids and
-- completion), the level, the dungeons asked about. A mob killed (QUEST_LOG_UPDATE) costs a
-- signature, not a walk over every chain of up to 12 dungeons.
local tokSig, tokCache, keyCache
local function TokenSig()
  local t = {}
  for id, e in pairs(ns.LogEntries()) do t[#t + 1] = tostring(id) .. (e.complete and "r" or "o") end
  table.sort(t)
  local lvl = UnitLevel and UnitLevel("player")
  lvl = (type(lvl) == "number" and not secret(lvl)) and lvl or 1
  local keys = {}
  for k in pairs(Wanted()) do keys[#keys + 1] = k end
  table.sort(keys)
  return table.concat(t, ",") .. "|" .. lvl .. "|" .. table.concat(keys, ",")
end
function ns.SyncDirty() tokSig = nil end

-- the game's answer to a send: nil, true or 0 (Success) is sent; false or another code is not
local function Sent(ok, res)
  if not ok then return false end
  if res == false then return false end
  if type(res) == "number" and not secret(res) and res ~= 0 then return false end
  return true
end

-- My current guide step as one token: "@" + its key (a comma, the separator, written ";"); none
-- when the guide has no current step or the key is long (the message stays small)
local function StepToken()
  local f = ns.frame
  local steps = ns.route and ns.route.steps
  local st = f and f.auto and steps and steps[f.auto]
  local k = st and st.key
  if type(k) ~= "string" or k == "" or #k > 80 then return nil end
  return "@" .. (k:gsub(",", ";"))
end

-- fromTimer == "retry": the call that waited out the gap, it sends
function ns.SyncSend(force, fromTimer)
  if ns.GuideOn and not ns.GuideOn() then return end
  local ch = Channel()
  if not (ch and SendFn()) then return end
  local sig = TokenSig()
  if sig ~= tokSig or not tokCache then tokSig = sig; tokCache, keyCache = ns.SyncTokens() end
  local toks, keys = tokCache, keyCache
  local stp = StepToken()
  if stp then
    local t2 = {}
    for k2, v in ipairs(toks) do t2[k2] = v end
    t2[#t2 + 1] = stp
    toks = t2
  end
  local payload = table.concat(keys, ",") .. ":" .. table.concat(toks, ",")
  if payload == lastSent and not force then return end
  -- throttled, the timers too: one full message every MIN_GAP seconds at most, the parts 0.2 s apart
  local wait = MIN_GAP - (Now() - lastAt)
  if wait > 0 and not force and fromTimer ~= "retry" then Schedule(wait, true); return end
  lastSent, lastAt = payload, Now()
  local failed = false
  -- a part the game did not send: the receiver never completes the message, send it all again
  local function again()
    if failed then return end
    failed = true
    lastSent = ""
    Schedule(MIN_GAP, true)
  end
  for i, msg in ipairs(ns.SyncChunks(toks, keys)) do
    local function go()
      if failed then return end
      local c = Channel()
      if not c then return end
      if not Sent(pcall(Send, PREFIX, msg, c)) then again() end
    end
    if i == 1 or not (C_Timer and C_Timer.After) then go() else C_Timer.After((i - 1) * 0.2, go) end
  end
end

-- retry: the call comes after the gap and sends
Schedule = function(delay, retry)
  if pending then return end
  pending = true
  local fn = function() pending = false; ns.SyncSend(false, retry and "retry" or true) end
  if C_Timer and C_Timer.After then C_Timer.After(delay or 2, fn) else fn() end
end

-- The guide's current step changed: the group hears it with the next message (throttled as usual)
function ns.SyncStepChanged()
  if Channel() then Schedule(1) end
end

-- My summary is open on these dungeons: ask the group for their quests (and send mine).
local lastAsk, lastAskAt = "", -100
function ns.SyncAsk(keys)
  local ch = Channel()
  if not ch then return end
  local list = {}
  for _, k in ipairs(keys or {}) do if ns.D[k] and #list < 8 then list[#list + 1] = k; ns.syncKeys[k] = true end end
  if #list == 0 then return end
  local s = table.concat(list, ",")
  if s ~= lastAsk or Now() - lastAskAt > 30 then
    lastAsk, lastAskAt = s, Now()
    pcall(Send, PREFIX, "W:" .. s:sub(1, 240), ch)
  end
  Schedule(0.5)
end

-- =====================================================================
--  What I receive
-- =====================================================================
local CODES = { o = "on", r = "ready", d = "done", t = "take", l = "low", p = "pre" }
local function Changed()
  if ns.syncRenderQueued then return end
  ns.syncRenderQueued = true
  local fn = function()
    ns.syncRenderQueued = false
    if ns.Render then pcall(ns.Render) end
    if ns.RenderOverview then ns.RenderOverview() end
  end
  if C_Timer and C_Timer.After then C_Timer.After(0.5, fn) else fn() end
end
ns.SyncChanged = Changed

local buf = {}
local function InGroup(who)
  return (UnitInParty and UnitInParty(who)) or (UnitInRaid and UnitInRaid(who))
end
local function OnMessage(prefix, msg, channel, sender)
  if prefix ~= PREFIX or type(msg) ~= "string" or secret(msg) or secret(sender) then return end
  -- only your group's members, on the group's channels
  if channel ~= "PARTY" and channel ~= "RAID" and channel ~= "INSTANCE_CHAT" then return end
  local who = Short(sender)
  if not who or not InGroup(who) then return end
  if type(who) == "string" and (who:match("^([^%-%s]+)") or who) == ((Me() or ""):match("^([^%-%s]+)") or Me()) then return end   -- our own message, whatever the name form
  if msg == "HELLO" then lastSent = ""; Schedule(); return end
  local want = msg:match("^W:(.*)$")
  if want then
    local n = 0
    for k in want:gmatch("[^,]+") do if ns.D[k] and n < 8 then ns.syncKeys[k] = true; n = n + 1 end end
    lastSent = ""; Schedule(1)
    return
  end
  local v2 = msg:sub(1, 2) == "2|"
  local i, n, keys, body
  if v2 then i, n, keys, body = msg:match("^2|(%d+)/(%d+)|([^:]*):(.*)$")
  else i, n, body = msg:match("^(%d+)/(%d+):(.*)$") end
  if not i then return end
  i, n = tonumber(i), tonumber(n)
  if not i or not n or n > 20 or i > n or i < 1 then return end
  if i == 1 then
    buf[who] = { st = {}, pre = {}, keys = {}, v = v2 and 2 or 1 }
    for k in (keys or ""):gmatch("[^,]+") do buf[who].keys[k] = true end
  end
  local b = buf[who]
  if not b then return end   -- the first part was missed: wait for the next full message
  for tok in body:gmatch("[^,]+") do
    if tok:sub(1, 1) == "@" then
      -- the member's current guide step
      local k = tok:sub(2):gsub(";", ",")
      if k ~= "" and #k <= 80 then b.step = k end
    elseif v2 then
      local id, code, pid = tok:match("^(%d+)(%a)(%d*)$")
      id = tonumber(id)
      if id and CODES[code] then
        b.st[id] = CODES[code]
        if code == "p" then b.pre[id] = tonumber(pid) end
      end
    else
      local id, star = tok:match("^(%d+)(%*?)$")
      if id then b.st[tonumber(id)] = (star == "*") and "ready" or "on" end
    end
  end
  if i == n then
    ns.party[who], ns.partyPre[who], ns.partyKeys[who] = b.st, b.pre, b.keys
    ns.partyStep[who] = b.step
    buf[who] = nil
    Changed()
  end
end
ns.SyncReceive = OnMessage

-- =====================================================================
--  Quest sharing and the game's answers (members without WL Helper)
-- =====================================================================
-- the game's sentences, with English fallbacks: "%s" is the member's name. The 4th field: the
-- answer waits for the member's click (accepted, declined, the dialog timed out); the others come
-- back at once.
local PUSH = {
  { "ERR_QUEST_PUSH_ACCEPTED_S", "on", "%s has accepted your quest.", true },
  { "ERR_QUEST_PUSH_ONQUEST_S", "on", "%s is already on that quest." },
  { "ERR_QUEST_PUSH_ALREADY_DONE_S", "done", "%s has completed that quest." },
  { "ERR_QUEST_PUSH_INVALID_S", "invalid", "%s is not eligible for that quest." },
  { "ERR_QUEST_PUSH_INVALID_TO_RECIPIENT_S", "invalid", nil },
  { "ERR_QUEST_PUSH_DECLINED_S", "declined", "%s has declined your quest.", true },
  { "ERR_QUEST_PUSH_LOG_FULL_S", "full", "%s's quest log is full." },
  { "ERR_QUEST_PUSH_BUSY_S", "busy", "%s is busy." },
  { "ERR_QUEST_PUSH_TOO_FAR_S", "far", "%s is too far away to receive your quest." },
  { "ERR_QUEST_PUSH_NOT_IN_PARTY_S", "busy", nil },
  { "ERR_QUEST_PUSH_NOT_ALLOWED_S", "invalid", nil },
  { "ERR_QUEST_PUSH_TIMER_EXPIRED_S", "busy", nil, true },
  { "ERR_QUEST_PUSH_NOT_DAILY_S", "invalid", nil },
}
local patterns
local function Patterns()
  if patterns then return patterns end
  patterns = {}
  for _, p in ipairs(PUSH) do
    local fmt = _G[p[1]]
    if type(fmt) ~= "string" then fmt = p[3] end
    if type(fmt) == "string" and fmt:find("%%s") then
      local pat = fmt:gsub("%%%d?%$?s", "\1"):gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1"):gsub("\1", "(.+)")
      patterns[#patterns + 1] = { "^" .. pat .. "$", p[2], p[4] }
    end
  end
  return patterns
end

-- The game's answer does not name the quest. Each member keeps the shares still waiting for
-- their answer, oldest first (ns.pushQ[who] = { { qid, t } }): an answer that comes at once is for
-- the newest share, one that waits for the member's click (accepted, declined) for the oldest.
-- "Share all" sends one quest every 1.5 s, often before the member has clicked.
local QUICK, SLOW = 10, 60   -- seconds an answer can still come
ns.pushLast = nil
ns.pushQ = {}
local function Take(who, slow)
  local q = ns.pushQ[who]
  if not q then return nil end
  local now = Now()
  for i = #q, 1, -1 do if now - q[i].t > SLOW then table.remove(q, i) end end
  local pick = slow and 1 or #q
  if not q[pick] then return nil end
  if not slow and now - q[pick].t > QUICK then return nil end
  return table.remove(q, pick).qid
end
function ns.OnPushAnswer(text)
  if type(text) ~= "string" or secret(text) then return false end
  for _, p in ipairs(Patterns()) do
    local who = text:match(p[1])
    if who then
      who = Short(who:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""))
      if not who then return false end
      local qid = Take(who, p[3])
      -- a member who was not in the group list at the share: the quest pushed last
      if not qid and not ns.pushQ[who] then
        local last = ns.pushLast
        if last and Now() - last.t <= (p[3] and SLOW or QUICK) then qid = last.qid end
      end
      if not qid then return false end
      ns.partyPush[who] = ns.partyPush[who] or {}
      ns.partyPush[who][qid] = p[2]
      Changed()
      return true
    end
  end
  return false
end

-- Shares one quest of my log with the group (guarded: in a group, in the log, shareable).
function ns.PushQuest(qid)
  if not (IsInGroup and IsInGroup()) then return false end
  local e = ns.LogEntries()[qid]
  if not e then return false end
  local q = ns.Q[qid]
  if q and q.sh == false then return false end
  if ns.Pushable and not ns.Pushable(qid, e) then return false end
  if SelectQuestLogEntry and e.index then pcall(SelectQuestLogEntry, e.index)
  elseif C_QuestLog and C_QuestLog.SetSelectedQuest then pcall(C_QuestLog.SetSelectedQuest, qid) end
  local push = QuestLogPushQuest or (C_QuestLog and C_QuestLog.PushQuest)
  if not push then return false end
  local ok = pcall(push)
  if not ok then return false end
  local now = Now()
  ns.pushLast = { qid = qid, t = now }
  -- members without data: "sent", until the game answers
  for _, m in ipairs(ns.GroupMembers()) do
    local q = ns.pushQ[m.name] or {}
    ns.pushQ[m.name] = q
    q[#q + 1] = { qid = qid, t = now }
    while #q > 12 do table.remove(q, 1) end
    local pp = ns.partyPush[m.name] or {}
    ns.partyPush[m.name] = pp
    if not (ns.party[m.name] and ns.party[m.name][qid]) then pp[qid] = pp[qid] or "sent" end
  end
  Changed()
  return true
end

-- Shares a list of quests, one every 1.5 s (the game answers each one before the next).
ns.pushBusy = false
function ns.PushQuests(list, onDone)
  if ns.pushBusy or not list or #list == 0 then return 0 end
  ns.pushBusy = true
  local n = #list
  local function step(i)
    if i > n then ns.pushBusy = false; if onDone then onDone() end; return end
    ns.PushQuest(list[i])
    if C_Timer and C_Timer.After and i < n then C_Timer.After(1.5, function() step(i + 1) end) else step(i + 1) end
  end
  step(1)
  return n
end

-- A member's state for a quest: state, missing link id, source ("sync", "push" or nil).
-- state: on, ready, done, take, low, pre (sync); invalid, declined, full, busy, far, sent (push);
-- "na" (WL Helper says the quest is not for this member), "unknown".
function ns.MemberQuest(who, qid, dkey)
  local list = ns.party[who]
  local s = list and list[qid]
  local push = ns.partyPush[who] and ns.partyPush[who][qid]
  if s then
    -- a share that was just accepted is newer than the last message
    if push == "on" and (s == "take" or s == "pre" or s == "low") then return "on", nil, "push" end
    return s, ns.partyPre[who] and ns.partyPre[who][qid], "sync"
  end
  if push then return push, nil, "push" end
  if list and dkey and ns.partyKeys[who] and ns.partyKeys[who][dkey] then return "na", nil, "sync" end
  return "unknown"
end
function ns.HasHelper(who) return ns.party[who] ~= nil end
-- The summary knows this member's quests: WL Helper sent them, or the game answered a share
-- ("sent" alone is no answer: a share with no reply yet does not make a column).
function ns.MemberKnown(who)
  if ns.party[who] ~= nil then return true end
  for _, v in pairs(ns.partyPush[who] or {}) do if v ~= "sent" then return true end end
  return false
end

-- =====================================================================
--  One line for the guide: who has the quest
-- =====================================================================
-- « Bob, Ann (prête) · sans la quête : Jim » pour une quête donnée
function ns.PartyLine(qid)
  local has, miss = {}, {}
  -- you are never "missing": names compared without the realm, however they were stored
  -- ("Alandir", "Alandir-Sheeplover", "Alandir Sheeplover")
  local function Base(n) return type(n) == "string" and (n:match("^([^%-%s]+)") or n) or n end
  local me = Base(Me())
  for who, list in pairs(ns.party) do
    if Base(who) ~= me then
      local s = list[qid] or (ns.partyPush[who] and ns.partyPush[who][qid])
      if s == "ready" then table.insert(has, "|cff59e67a" .. who .. "|r")
      elseif s == "on" then table.insert(has, who)
      elseif s ~= "done" and s ~= "na" then table.insert(miss, "|cffff9933" .. who .. "|r") end
    end
  end
  if #has == 0 and #miss == 0 then return nil end
  local t = {}
  if #has > 0 then table.insert(t, ns.L.PARTY_HAS:format(table.concat(has, ", "))) end
  if #miss > 0 then table.insert(t, ns.L.PARTY_MISS:format(table.concat(miss, ", "))) end
  return table.concat(t, "  ·  ")
end

local function Prune()
  local keep = {}
  for _, m in ipairs(ns.GroupMembers()) do keep[m.name] = true end
  for _, t in ipairs({ ns.party, ns.partyPre, ns.partyKeys, ns.partyPush, ns.pushQ, ns.partyStep }) do
    for who in pairs(t) do if not keep[who] then t[who] = nil end end
  end
end

local ev = CreateFrame("Frame")
ns.SyncFrame = ev
for _, e in ipairs({ "CHAT_MSG_ADDON", "CHAT_MSG_SYSTEM", "GROUP_ROSTER_UPDATE", "QUEST_LOG_UPDATE", "QUEST_TURNED_IN",
  "PLAYER_LEVEL_UP", "PLAYER_ENTERING_WORLD" }) do pcall(ev.RegisterEvent, ev, e) end
local wasGrouped = false
ev:SetScript("OnEvent", function(_, e, ...)
  if e == "CHAT_MSG_ADDON" then OnMessage(...) return end
  if e == "CHAT_MSG_SYSTEM" then ns.OnPushAnswer((...)) return end
  local ch = Channel()
  if e == "GROUP_ROSTER_UPDATE" then
    Prune()
    if ch and not wasGrouped then pcall(Send, PREFIX, "HELLO", ch); lastSent = "" end
    wasGrouped = ch ~= nil
    if not ch then
      for _, t in ipairs({ ns.party, ns.partyPre, ns.partyKeys, ns.partyPush, ns.pushQ, ns.syncKeys, ns.partyStep }) do wipe(t) end
    end
    -- the summary and the guide follow, once per burst of roster events
    Changed()
  end
  -- what the tokens say can change without the log's ids or completion changing
  if e == "QUEST_TURNED_IN" or e == "PLAYER_LEVEL_UP" or e == "PLAYER_ENTERING_WORLD" then tokSig = nil end
  if ch then Schedule() end
end)
