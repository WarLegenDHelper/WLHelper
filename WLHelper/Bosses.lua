-- Bosses.lua: the bosses and rares of a dungeon as a strip of heads beside the guide (or on its own).
-- Data read LIVE from LibForeverData (optional dependency, never copied): every NPC whose spawns
-- sit on the dungeon's instance map (ns.D[k].inst = the client Map id LibForeverData stores for
-- instance spawns), ranked boss (3) or rare (2 rare elite, 4 rare), plus the bosses of the walk
-- order (ns.WALK / ns.BossOrder: most 5-player bosses are only "elite" in the data).
-- The strip: one square portrait per boss in dungeon order, then the rares under a "Rares" label.
-- Killed: greyed, veiled, a check. A rare not seen yet: greyed and faded (seen = its nameplate,
-- your target or your mouse met it once, kept in WLDTDB.raresSeen). The name, level, quests and
-- the click line live in the tooltip. Each head IS a secure button (macro: target and mark),
-- created, moved, shown and given its macro out of combat only; changes in combat wait for
-- PLAYER_REGEN_ENABLED (only the colours change in combat).
-- Rare alert (inside a dungeon, WLDTDB.rareAlert ~= false; the open world too when
-- WLDTDB.rareAlertWorld is true): a rare shows up -> a sound and a small banner with a secure
-- "Target and mark" button (made out of combat), at most once per 10 min per rare.
-- API: ns.DungeonMobs(dkey[, sync]) -> { bosses = {...}, rares = {...}, loading, source }
--      ns.ShowBosses(dkey), ns.HideBosses(), ns.ToggleBosses(dkey), ns.AttachBosses(parentFrame),
--      ns.RefreshBosses(), ns.BossesShown(), ns.RareSeen(npcId), ns.RareAlert(unit)
local ADDON, ns = ...
local L = ns.L
local T = ns.Tok

-- (its strings live in Locale.lua, BOSS_*)

-- ---------------------------------------------------------------- helpers
local function secret(v) return issecretvalue ~= nil and issecretvalue(v) end
local function num(v) return type(v) == "number" and not secret(v) and v or nil end
local function str(v) return type(v) == "string" and not secret(v) and v or nil end
local function InCombat() return InCombatLockdown ~= nil and InCombatLockdown() == true end
local function DB()
  WLDTDB = WLDTDB or {}
  return WLDTDB
end

local MARK_DEFAULT_BOSS, MARK_DEFAULT_RARE = 8, 1
local MARK_EN = { "Star", "Circle", "Diamond", "Triangle", "Moon", "Square", "Cross", "Skull" }
local MARK_FR = { "Étoile", "Cercle", "Losange", "Triangle", "Lune", "Carré", "Croix", "Crâne" }
local function MarkName(i)
  local g = _G["RAID_TARGET_" .. i]
  if type(g) == "string" and g ~= "" then return g end
  return (ns.lang == "fr" and MARK_FR or MARK_EN)[i] or tostring(i)
end
local function MarkTexture(i) return "Interface\\TargetingFrame\\UI-RaidTargetingIcon_" .. i end

-- painted icon by creature type (learned when you target the NPC; English and French words)
local TYPE_ICON = {
  Beast = "Ability_Hunter_Pet_Wolf", ["Bête"] = "Ability_Hunter_Pet_Wolf",
  Humanoid = "INV_Misc_Head_Human_01", ["Humanoïde"] = "INV_Misc_Head_Human_01",
  Undead = "Spell_Shadow_RaiseDead", ["Mort-vivant"] = "Spell_Shadow_RaiseDead",
  Demon = "Spell_Shadow_SummonImp", ["Démon"] = "Spell_Shadow_SummonImp",
  Dragonkin = "INV_Misc_Head_Dragon_01", ["Draconien"] = "INV_Misc_Head_Dragon_01",
  Elemental = "Spell_Fire_Fire", ["Élémentaire"] = "Spell_Fire_Fire",
  Mechanical = "INV_Gizmo_01", ["Machine"] = "INV_Gizmo_01", ["Mécanique"] = "INV_Gizmo_01",
}

-- ---------------------------------------------------------------- LibForeverData (live, optional)
local triedLoad = false
local function Lib()
  local lib = _G.LibForeverData
  if type(lib) ~= "table" and LibStub then
    local ok, l = pcall(LibStub, "LibForeverData", true)
    if ok then lib = l end
  end
  if type(lib) ~= "table" and not triedLoad then
    triedLoad = true
    local isLoaded = (C_AddOns and C_AddOns.IsAddOnLoaded) or IsAddOnLoaded
    local load = (C_AddOns and C_AddOns.LoadAddOn) or LoadAddOn
    local okL, loaded = pcall(isLoaded or function() return false end, "LibForeverData")
    if not (okL and loaded) and load then pcall(load, "LibForeverData") end
    lib = _G.LibForeverData
  end
  if type(lib) == "table" and lib.Get and lib.Ids and lib.Spawns then return lib end
  return nil
end
ns.BossLib = Lib

-- index[instanceMap] = { npcId, ... }: every NPC with a spawn on a dungeon's map. Built once,
-- a few hundred NPCs per frame (sync = all at once).
local index, indexReady, building, scanIds, scanPos, instSet
local mobsCache = {}
local onReady = {}

local function InstSet()
  local set = {}
  for k, d in pairs(ns.D or {}) do if type(d) == "table" and num(d.inst) then set[d.inst] = true end end
  return set
end

local function ScanBatch(lib, n)
  local stop = math.min(#scanIds, scanPos + n - 1)
  for i = scanPos, stop do
    local id = scanIds[i]
    local ok, sp = pcall(lib.Spawns, "npc", id)
    if ok and type(sp) == "table" then
      local seen
      for _, p in ipairs(sp) do
        local m = p.map
        if m and instSet[m] and not (seen and seen[m]) then
          seen = seen or {}
          seen[m] = true
          local l = index[m]
          if not l then l = {}; index[m] = l end
          l[#l + 1] = id
        end
      end
    end
  end
  scanPos = stop + 1
  return scanPos > #scanIds
end

local nearCache = {}
local function Finish()
  building = false
  indexReady = true
  scanIds = nil
  for k in pairs(mobsCache) do mobsCache[k] = nil end
  for k in pairs(nearCache) do nearCache[k] = nil end
  local list = onReady
  onReady = {}
  for _, fn in ipairs(list) do pcall(fn) end
  -- the guide places the dungeon's NPCs between the right bosses once their spawns are known
  if ns.OnBossIndexReady then pcall(ns.OnBossIndexReady) end
end

local function StartIndex(sync)
  if indexReady then return true end
  local lib = Lib()
  if not lib then return false end
  if not building then
    building = true
    index = {}
    instSet = InstSet()
    local ok, ids = pcall(lib.Ids, "npc")
    scanIds = (ok and type(ids) == "table") and ids or {}
    scanPos = 1
    if not sync then
      local function Step()
        if not building or indexReady then return end
        local l = Lib()
        if not l then building = false return end
        if ScanBatch(l, 300) then Finish() elseif C_Timer and C_Timer.After then C_Timer.After(0, Step) end
      end
      if C_Timer and C_Timer.After then C_Timer.After(0, Step) else sync = true end
    end
  end
  if sync and building and not indexReady then
    while not ScanBatch(lib, 2000) do end
    Finish()
  end
  return indexReady
end

-- Localised NPC name: the dungeon journal's name, else the client's tooltip for that creature
-- (once it has seen it), else the data's English name.
local localName = {}
local function LocalName(id, en, journal)
  if journal and journal.name and journal.name ~= "" then return journal.name end
  if localName[id] then return localName[id] end
  local loc = GetLocale and GetLocale()
  if loc == "enUS" or loc == "enGB" or not id then return en end
  if C_TooltipInfo and C_TooltipInfo.GetHyperlink then
    local ok, data = pcall(C_TooltipInfo.GetHyperlink, "unit:Creature-0-0-0-0-" .. id .. "-0000000000")
    local line = ok and type(data) == "table" and data.lines and data.lines[1]
    local t = line and str(line.leftText)
    if t and t ~= "" then localName[id] = t; return t end
  end
  return en
end

-- ---------------------------------------------------------------- kills (this run)
-- One run = one copy of the instance: GetInstanceInfo's instance ID plus a run number. A new run
-- starts when you enter another instance, when the instance was reset (the system message), when
-- you come back more than 30 minutes after leaving (a logout inside counts as leaving), when you
-- were last seen inside more than 30 minutes ago, 4 hours after the run began, or when a boss
-- counted as killed stands alive out of combat (a copy reset by someone else). Leaving and coming
-- back soon (a wipe, a corpse run, a /reload) keeps the run and its kills.
-- WLDTDB.bossKills = { iid, run, t, left, reset, names = {}, ids = {}, enc = {}, objs = {} }
local function Kills()
  local db = DB()
  local k = db.bossKills or {}
  db.bossKills = k
  k.names = k.names or {}; k.ids = k.ids or {}; k.enc = k.enc or {}
  k.run = k.run or 0
  return k
end
local function CurrentInstance()
  if not GetInstanceInfo then return nil end
  local ok, _, kind, _, _, _, _, _, id = pcall(GetInstanceInfo)
  if not ok or (kind ~= "party" and kind ~= "raid") then return nil end
  return num(id)
end
local function Now() return (GetServerTime and GetServerTime()) or (time and time()) or 0 end
-- The kill objectives already finished when the visit starts ("qid:index"): a boss killed in an
-- earlier lockout, its quest not turned in yet, is not "killed" in this fresh instance.
local function KillSnapshot()
  local snap = {}
  local log = ns.LogEntries and ns.LogEntries() or {}
  for qid in pairs(log) do
    local q = ns.Q and ns.Q[qid]
    for oi, o in ipairs(q and q.o or {}) do
      if o.k == "kill" then
        local ok, v = pcall(ns.ObjDone, log, qid, o)
        if ok and v then snap[qid .. ":" .. oi] = true end
      end
    end
  end
  return snap
end
-- the run in which a kill was seen during this session (kills read back from the saved
-- variables alone may belong to a copy that is gone: the guide keeps nothing for good on them)
local liveIid, liveRun
local function NewRun(k, iid)
  k.iid, k.names, k.ids, k.enc, k.encNpc = iid, {}, {}, {}, {}
  k.run = (k.run or 0) + 1
  k.start, k.reset, k.left = Now(), nil, nil
  k.objs = KillSnapshot()
end
-- Inside an instance: a new run when it is another instance, or the same one reset or left long ago.
-- Outside: remember when you left.
-- entering: a loading screen into the instance (a stale "last seen inside" counts only then)
local function NewVisitCheck(entering)
  local iid = CurrentInstance()
  local k = Kills()
  local now = Now()
  if not iid then
    if k.iid and not k.left then k.left = now end
    return
  end
  if k.iid ~= iid or k.reset or not k.start or now - k.start > 4 * 3600
    or (k.left and now - k.left > 30 * 60)
    or (entering and not k.left and k.t and now - k.t > 30 * 60) then
    NewRun(k, iid)
  end
  k.left = nil
  k.t = now
end
ns.BossVisitCheck = NewVisitCheck
-- still inside the run's copy: remember when (combat, logout), so a stale run is told apart
local function Touch(leaving)
  local iid = CurrentInstance()
  local k = Kills()
  if not (iid and k.iid == iid) then return end
  k.t = Now()
  if leaving then k.left = k.t end
end
ns.BossTouch = Touch
-- Was a kill of the current run seen during this session? Only then does the guide keep a boss
-- step done for good.
function ns.BossRunLive()
  local k = Kills()
  return liveRun ~= nil and liveIid == k.iid and liveRun == k.run
end
-- The run you are in (or the last one): instance ID, run number.
function ns.BossRun()
  local k = Kills()
  return k.iid, k.run
end
-- The instance was reset (the leader's reset, or a test): the next entry starts a new run.
function ns.ResetBossRun()
  local k = Kills()
  k.reset = true
  if CurrentInstance() then NewVisitCheck() end
end

-- Was this boss killed during the current run of its dungeon? names: English and local names,
-- ids: NPC ids, enc: encounter IDs (any may be nil).
function ns.BossKilled(dkey, names, ids, enc)
  local d = dkey and ns.D and ns.D[dkey]
  local k = Kills()
  if not (d and d.inst and k.iid == d.inst) then return false end
  for _, nm in ipairs(names or {}) do if nm and k.names[nm] then return true end end
  for _, id in ipairs(ids or {}) do if id and k.ids[id] then return true end end
  for _, e in ipairs(enc or {}) do if e and k.enc[e] then return true end end
  return false
end

-- ---------------------------------------------------------------- data per dungeon
local function SiblingKeys(dkey)
  local d = ns.D[dkey]
  local out = {}
  if not (d and d.inst) then return out end
  for _, k in ipairs(ns.ORDER or {}) do
    local d2 = ns.D[k]
    if k ~= dkey and d2 and d2.inst == d.inst and not d2.cq then out[#out + 1] = k end
  end
  return out
end

local function SpawnPts(lib, id)
  local ok, sp = pcall(lib.Spawns, "npc", id)
  return (ok and type(sp) == "table") and sp or {}
end
local function MinDist(a, b)
  local best
  for _, p in ipairs(a) do
    for _, q in ipairs(b) do
      if p.map == q.map and p.x and q.x then
        local dz = (p.z and q.z) and (p.z - q.z) or 0
        local dd = (p.x - q.x) ^ 2 + (p.y - q.y) ^ 2 + dz * dz
        if not best or dd < best then best = dd end
      end
    end
  end
  return best
end

local function BuildMobs(dkey)
  local d = ns.D[dkey]
  local res = { bosses = {}, rares = {}, dkey = dkey }
  if not d then return res end
  local walk = ns.WALK and ns.WALK[dkey]
  local bo = ns.BossOrder and ns.BossOrder(dkey)
  local sibs = SiblingKeys(dkey)
  local shared = #sibs > 0
  local boByEn, boById = {}, {}
  if bo and bo.list then
    for i, b in ipairs(bo.list) do
      if b.en then boByEn[b.en] = b end
      if b.npc then boById[b.npc] = b end
      b._i = i
    end
  end
  -- the wing's own bosses, in walking order
  local mine = {}
  if walk then for i, nm in ipairs(walk) do mine[nm] = i end end
  if bo and bo.list and not (shared and walk) then
    for i, b in ipairs(bo.list) do if b.en and not mine[b.en] then mine[b.en] = (walk and 100 or 0) + i end end
  end
  local other = {}
  for _, k in ipairs(sibs) do for _, nm in ipairs(ns.WALK and ns.WALK[k] or {}) do if not mine[nm] then other[nm] = k end end end

  local lib = Lib()
  local byName = {}
  local function Add(rec, list)
    local have = byName[rec.en]
    if have then
      have.minL = math.min(have.minL or rec.minL or 0, rec.minL or have.minL or 0)
      have.maxL = math.max(have.maxL or 0, rec.maxL or 0)
      have.ids[#have.ids + 1] = rec.id
      return
    end
    rec.ids = { rec.id }
    byName[rec.en] = rec
    list[#list + 1] = rec
  end
  if lib and indexReady then
    res.source = "lfd"
    local cands = {}
    for _, id in ipairs(index[d.inst] or {}) do
      local ok, r = pcall(lib.Get, "npc", id)
      if ok and type(r) == "table" and r.name then cands[#cands + 1] = r end
    end
    -- shared instance (Scarlet Monastery, Dire Maul...): an NPC no wing lists goes to the wing
    -- whose bosses stand nearest to it
    local wingPts
    if shared then
      wingPts = {}
      local names = {}
      for nm in pairs(mine) do names[nm] = dkey end
      for nm, k in pairs(other) do names[nm] = k end
      for _, r in ipairs(cands) do
        local k = names[r.name]
        if k then
          wingPts[k] = wingPts[k] or {}
          for _, p in ipairs(SpawnPts(lib, r.id)) do table.insert(wingPts[k], p) end
        end
      end
    end
    local function MyWing(r)
      if not shared or mine[r.name] then return true end
      if other[r.name] then return false end
      if not wingPts or not wingPts[dkey] then return true end
      local pts = SpawnPts(lib, r.id)
      local myD = MinDist(pts, wingPts[dkey])
      if not myD then return true end
      for k, wp in pairs(wingPts) do
        if k ~= dkey then
          local dd = MinDist(pts, wp)
          if dd and dd < myD then return false end
        end
      end
      return true
    end
    for _, r in ipairs(cands) do
      local rk = num(r.rank) or 0
      local jb = boById[r.id] or boByEn[r.name]
      local listed = mine[r.name] ~= nil or (jb ~= nil and not shared)
      if (rk == 2 or rk == 3 or rk == 4 or listed) and MyWing(r) then
        local rec = { id = r.id, en = r.name, rank = rk, minL = num(r.minLevel), maxL = num(r.maxLevel),
          rare = (rk == 2 or rk == 4), order = mine[r.name] or (jb and jb._i and 200 + jb._i) or nil,
          model = jb and num(jb.model) or nil, journal = jb, sub = str(r.subName) }
        Add(rec, rec.rare and res.rares or res.bosses)
      end
    end
  end
  -- without LibForeverData (or names it misses): the walk order and the dungeon journal
  local lists = {}
  if walk then for _, nm in ipairs(walk) do lists[#lists + 1] = nm end end
  if bo and bo.list and not (shared and walk) then for _, b in ipairs(bo.list) do lists[#lists + 1] = b.en end end
  for _, nm in ipairs(lists) do
    if nm and not byName[nm] then
      local jb = boByEn[nm]
      local rec = { id = jb and jb.npc, en = nm, rank = 1, rare = false, order = mine[nm],
        model = jb and num(jb.model) or nil, journal = jb }
      Add(rec, res.bosses)
      res.source = res.source or "journal"
    end
  end
  table.sort(res.bosses, function(a, b)
    local oa, ob = a.order or 10000, b.order or 10000
    if oa ~= ob then return oa < ob end
    local la, lb = a.maxL or 0, b.maxL or 0
    if la ~= lb then return la < lb end
    return a.en < b.en
  end)
  table.sort(res.rares, function(a, b)
    local la, lb = a.maxL or 0, b.maxL or 0
    if la ~= lb then return la < lb end
    return a.en < b.en
  end)
  return res
end

-- quests that matter: the route's, the log's, else the dungeon's own
local function QuestPool(dkey)
  local out, seen = {}, {}
  local function add(q) if q and not seen[q] and ns.Q[q] then seen[q] = true; out[#out + 1] = q end end
  local r = ns.route
  if r and r.steps then
    for _, st in ipairs(r.steps) do for _, n in ipairs(st.acts or {}) do add(n.q) end end
  end
  local okL, log = pcall(ns.LogEntries)
  if okL and type(log) == "table" then for q in pairs(log) do add(q) end end
  if #out == 0 and ns.DungeonQuests then
    local _, cls = UnitClass("player")
    for _, q in ipairs(ns.DungeonQuests(dkey, cls)) do add(q) end
  end
  return out, (okL and log or {})
end

local function Names(o)
  local t = {}
  for _, nm in ipairs(o.t or {}) do t[nm] = true end
  for _, s in ipairs(o.src or {}) do if type(s) == "table" and s[1] then t[s[1]] = true end end
  return t
end

-- Rares met once (nameplate, target, mouse): WLDTDB.raresSeen[npcId] = server time.
local function Seen()
  local db = DB()
  db.raresSeen = db.raresSeen or {}
  return db.raresSeen
end
local function IsSeen(rec)
  local s = Seen()
  for _, id in ipairs(rec.ids or {}) do if s[id] then return true end end
  return false
end

-- Fills rec.quests ({ qid, item, kind }), rec.killed and rec.seen (rares) for every head.
local function Dynamic(res)
  local pool, log = QuestPool(res.dkey)
  local k = Kills()
  local inInst = CurrentInstance()
  local fresh = inInst and k.iid == inInst
  local function each(rec)
    rec.quests = {}
    rec.killed = false
    if fresh and (k.names[rec.en] or (rec.name and k.names[rec.name])) then rec.killed = true end
    if fresh then for _, id in ipairs(rec.ids or {}) do if k.ids[id] then rec.killed = true end end end
    if fresh and rec.journal and type(rec.journal.enc) == "table" then
      for _, e in ipairs(rec.journal.enc) do if k.enc[e] then rec.killed = true end end
    end
    for _, qid in ipairs(pool) do
      local q = ns.Q[qid]
      if q and q.o and not ns.IsDone(qid) then
        for oi, o in ipairs(q.o) do
          if Names(o)[rec.en] then
            local done = false
            local okD, v = pcall(ns.ObjDone, log, qid, o)
            if okD then done = v end
            -- finished now but not when the visit started: killed during this visit
            if o.k == "kill" and done and log[qid] and fresh and k.objs and not k.objs[qid .. ":" .. oi] then
              rec.killed = true
              -- the guide's boss step reads the run's kills: this one counts too
              k.names[rec.en] = true
            end
            if not done then
              table.insert(rec.quests, { qid = qid, kind = o.k == "item" and "item" or "kill", item = o.n })
            end
          end
        end
      end
    end
    rec.seen = rec.rare and (rec.killed or IsSeen(rec)) or nil
  end
  for _, rec in ipairs(res.bosses) do each(rec) end
  for _, rec in ipairs(res.rares) do each(rec) end
end

function ns.DungeonMobs(dkey, sync)
  if not (dkey and ns.D and ns.D[dkey]) then return { bosses = {}, rares = {} } end
  local hasLib = Lib() ~= nil
  local ready = hasLib and StartIndex(sync)
  local res = mobsCache[dkey]
  if not res then
    res = BuildMobs(dkey)
    -- a list built before the index was ready is rebuilt once it is
    if ready or not hasLib then mobsCache[dkey] = res end
  end
  res.loading = (hasLib and not ready) or nil
  res.noLib = (not hasLib) or nil
  for _, rec in ipairs(res.bosses) do rec.name = LocalName(rec.id, rec.en, rec.journal) end
  for _, rec in ipairs(res.rares) do rec.name = LocalName(rec.id, rec.en, rec.journal) end
  Dynamic(res)
  return res
end

-- ---------------------------------------------------------------- the guide's walkthrough
-- A boss's name as this client writes it (the strip's list when built, else the English name).
function ns.BossLocalName(dkey, en)
  local res = dkey and mobsCache[dkey]
  if res then for _, r in ipairs(res.bosses) do if r.en == en then return LocalName(r.id, r.en, r.journal) end end end
  return en
end
-- The NPC ids of a boss on the dungeon's map (LibForeverData, once the index is ready).
function ns.BossNpcIds(dkey, en)
  local res = dkey and mobsCache[dkey]
  if res then for _, r in ipairs(res.bosses) do if r.en == en then return r.ids end end end
  return nil
end

-- name -> spawn points of every NPC on the dungeon's map (LibForeverData, once the index is ready)
local function MapSpawns(dkey)
  if nearCache[dkey] ~= nil then return nearCache[dkey] end
  local d = ns.D[dkey]
  local lib = Lib()
  if not (d and d.inst and lib and indexReady) then return nil end
  local out = {}
  for _, id in ipairs(index[d.inst] or {}) do
    local ok, nm = pcall(lib.Name or function() return nil end, "npc", id)
    if not (ok and nm) then
      local okG, r = pcall(lib.Get, "npc", id)
      nm = okG and type(r) == "table" and r.name or nil
    end
    if nm then
      local l = out[nm] or {}
      out[nm] = l
      for _, p in ipairs(SpawnPts(lib, id)) do if p.map == d.inst then l[#l + 1] = p end end
    end
  end
  nearCache[dkey] = out
  return out
end
-- The boss (English name, from `bosses`, a list of names) standing nearest to an NPC of the
-- dungeon: the guide puts that NPC's quest step on the way to this boss. nil when unknown.
function ns.BossNear(dkey, npcName, bosses)
  if not (dkey and npcName and bosses) then return nil end
  local sp = MapSpawns(dkey)
  local mine = sp and sp[(npcName:gsub(",.*$", ""))]
  if not (mine and #mine > 0) then return nil end
  local best, bestD
  for _, en in ipairs(bosses) do
    local pts = sp[en]
    local dd = pts and MinDist(mine, pts)
    if dd and (not bestD or dd < bestD) then best, bestD = en, dd end
  end
  return best
end

-- Quest items a boss drops that an open quest of your log still needs (LibForeverData, read live).
-- A quest item drops only while you have its quest, so only the log's quests are looked at: their
-- item objectives, then where each item drops. Nothing is scanned in bulk. Kept for one read of
-- the quest log (ns.LogEntries gives the same table for one frame).
-- -> npc id -> { { id, name, chance, qid } }
local needMemo, needLog
local function ItemCount(id)
  local count = (C_Item and C_Item.GetItemCount) or GetItemCount
  if not (count and id) then return 0 end
  local ok, n = pcall(count, id)
  return (ok and num(n)) or 0
end
local function QuestNeeds()
  local lib = Lib()
  local log = ns.LogEntries and ns.LogEntries() or {}
  if not lib then return {} end
  if needLog == log and needMemo then return needMemo end
  local out = {}
  local getQ = lib.Quest or function(id) return lib.Get("quest", id) end
  for qid, e in pairs(log) do
    if type(e) == "table" and not e.complete then
      local okQ, q = pcall(getQ, qid)
      for _, o in ipairs(okQ and type(q) == "table" and type(q.objectives) == "table" and q.objectives or {}) do
        -- still needed: fewer in the bags than the objective asks for
        if o.kind == "item" and num(o.target) and ItemCount(o.target) < (num(o.count) or 1) then
          local okI, it = pcall(lib.Get, "item", o.target)
          if okI and type(it) == "table" then
            for _, src in ipairs(it.sources or {}) do
              if src.kind == "npc" and src.id and (num(src.chance) or 100) >= 20 then
                local l = out[src.id] or {}
                out[src.id] = l
                l[#l + 1] = { id = it.id or o.target, name = it.name, chance = num(src.chance), qid = qid }
              end
            end
          end
        end
      end
    end
  end
  needMemo, needLog = out, log
  return out
end
ns.BossQuestNeeds = QuestNeeds

-- What a boss drops that matters to you: our own list (ns.BOSS_LOOT, gear) and the quest items it
-- drops for a quest of your log that still needs them.
-- -> { { id, name, quest = true|nil, qid } } (nil names: ask the game)
function ns.BossLoot(dkey, en, npcIds)
  local out, seen = {}, {}
  local mine = ns.BOSS_LOOT and ns.BOSS_LOOT[dkey] and ns.BOSS_LOOT[dkey][en]
  for _, id in ipairs(mine or {}) do if not seen[id] then seen[id] = true; out[#out + 1] = { id = id } end end
  local ids = npcIds or ns.BossNpcIds(dkey, en)
  if ids then
    local need = QuestNeeds()
    for _, nid in ipairs(ids) do
      for _, x in ipairs(need[nid] or {}) do
        if not seen[x.id] then seen[x.id] = true; out[#out + 1] = { id = x.id, name = x.name, quest = true, qid = x.qid } end
      end
    end
  end
  return out
end

-- ---------------------------------------------------------------- the strip of heads
local P               -- the strip
local parentFrame     -- the guide window it sits beside
local pending = {}    -- what waits for the end of combat
local dismissed = {}  -- instance IDs whose strip you closed during this visit
local SIZE, GAP, PAD, TOPBAR, LABEL = 40, 6, 8, 22, 18
local MAXCOLS = 5

local function Marker(rec)
  local db = DB()
  db.bossMarks = db.bossMarks or {}
  return db.bossMarks[rec.en] or (rec.rare and MARK_DEFAULT_RARE or MARK_DEFAULT_BOSS)
end

-- /targetexact: the exact name only, and the current target stays when nobody matches (a misclick
-- in combat never leaves you without a target); a dead target with that name is dropped first.
local function MacroText(name, m)
  return "/cleartarget [dead]\n/targetexact " .. name ..
    "\n/run if UnitExists'target' and GetRaidTargetIndex'target'~=" .. m .. " then SetRaidTarget('target'," .. m .. ") end"
end
local function MacroFor(rec) return MacroText(rec.name or rec.en, Marker(rec)) end

local function LevelText(rec)
  local a, b = rec.minL, rec.maxL
  if not a and not b then return nil end
  a = a or b; b = b or a
  if a <= 0 and b <= 0 then return nil end
  if a == b then return L.BOSS_LVL:format(a) end
  return L.BOSS_LVL2:format(a, b)
end
local function RankWord(rec)
  if rec.rank == 3 then return L.BOSS_R_BOSS
  elseif rec.rank == 2 then return L.BOSS_R_RAREELITE
  elseif rec.rank == 4 then return L.BOSS_R_RARE end
  return L.BOSS_R_ELITE
end

-- the head's tooltip: name; boss number or rank and level; quests; state; the click line
local function HeadTip(head)
  local rec = head.rec
  if not rec then return end
  local lines = { rec.name or rec.en }
  local sub = (not rec.rare and head.n) and L.BOSS_N:format(head.n) or RankWord(rec)
  local lv = LevelText(rec)
  if lv then sub = sub .. " · " .. lv end
  lines[#lines + 1] = sub
  if rec.sub then lines[#lines + 1] = rec.sub end
  if rec.name and rec.name ~= rec.en then lines[#lines + 1] = rec.en end
  for _, q in ipairs(rec.quests or {}) do
    local qname = ns.QName(q.qid)
    if q.kind == "item" then
      lines[#lines + 1] = { L.BOSS_FOR_ITEM:format(ns.T(q.item) or q.item or "?", qname), T.gold[1], T.gold[2], T.gold[3] }
    else
      lines[#lines + 1] = { L.BOSS_FOR:format(qname), T.gold[1], T.gold[2], T.gold[3] }
    end
  end
  if rec.killed then lines[#lines + 1] = { L.BOSS_KILLED, T.ok[1], T.ok[2], T.ok[3] }
  elseif rec.rare and not rec.seen then lines[#lines + 1] = L.BOSS_UNSEEN
  elseif rec.rare then lines[#lines + 1] = { L.BOSS_SEEN, T.silver[1], T.silver[2], T.silver[3] } end
  if head.stale then lines[#lines + 1] = { L.BOSS_WAIT, T.warn[1], T.warn[2], T.warn[3] } end
  lines[#lines + 1] = L.BOSS_TT_CLICKM:format(MarkName(Marker(rec)))
  ns.ShowTip(head, lines)
end

-- painted portrait: the creature's display (journal), its type icon, else the HD skull / star
local function SetPortrait(head, rec)
  local tex, hd = head.port, head.portHD
  local shown = false
  if rec.model and SetPortraitTextureFromCreatureDisplayID then
    local ok = pcall(SetPortraitTextureFromCreatureDisplayID, tex, rec.model)
    if ok then tex:SetTexCoord(0.15, 0.85, 0.15, 0.85); shown = true end
  end
  if not shown then
    local db = DB()
    local ty = db.bossType and db.bossType[rec.en]
    local icon = ty and TYPE_ICON[ty]
    if icon then ns.SetPainted(tex, "Interface\\Icons\\" .. icon); shown = true end
  end
  tex:SetShown(shown)
  hd:SetShown(not shown)
  if not shown then ns.SetHDIcon(hd, rec.rare and "star" or "skull", rec.rare and T.silver or T.muted) end
end

-- One head: a secure button (the click targets and marks) holding a plain frame with the looks
-- (its alpha may change in combat; the secure button's own state never does).
local function MakeHead(i)
  local b = CreateFrame("Button", "WLBossTarget" .. i, P, "SecureActionButtonTemplate")
  b:SetSize(SIZE, SIZE)
  b:RegisterForClicks("LeftButtonUp", "LeftButtonDown")
  b:SetAttribute("type", "macro")
  local face = CreateFrame("Frame", nil, b)
  face:SetAllPoints()
  b.face = face
  local bg = ns.Tex(face, "BACKGROUND", T.cardFill); bg:SetAllPoints()
  b.edge = ns.Outline(face, T.cardEdge)
  b.port = face:CreateTexture(nil, "ARTWORK"); b.port:SetPoint("TOPLEFT", 1, -1); b.port:SetPoint("BOTTOMRIGHT", -1, 1)
  b.portHD = ns.Icon(face, "skull", 20, "ARTWORK", T.muted); b.portHD:SetPoint("CENTER")
  b.veil = ns.Tex(face, "OVERLAY", T.scrim); b.veil:SetPoint("TOPLEFT", 1, -1); b.veil:SetPoint("BOTTOMRIGHT", -1, 1); b.veil:Hide()
  b.check = ns.Icon(face, "check", 18, "OVERLAY", T.ok); b.check:SetPoint("CENTER"); b.check:Hide()
  b.hl = ns.Tex(face, "OVERLAY", T.hoverFill); b.hl:SetAllPoints(); b.hl:SetAlpha(0)
  -- the boss's number in the dungeon (bottom left, on a dark chip)
  b.chip = ns.Tex(face, "OVERLAY", T.scrim); b.chip:SetPoint("BOTTOMLEFT", 1, 1); b.chip:SetSize(14, 13)
  b.badge = ns.Text(face, ns.F.foot, T.fg, true)
  b.badge:SetPoint("CENTER", b.chip, "CENTER", 0, 0)
  b:SetScript("OnEnter", function(self) self.hl:SetAlpha(1); HeadTip(self) end)
  b:SetScript("OnLeave", function(self) self.hl:SetAlpha(0); ns.HideTip() end)
  b:HookScript("OnMouseDown", function(self) self.port:SetPoint("TOPLEFT", 1, -2) end)
  b:HookScript("OnMouseUp", function(self) self.port:SetPoint("TOPLEFT", 1, -1) end)
  return b
end

-- what may change in combat: colours, the veil, the check, the face's alpha (no secure state)
local function PaintHead(b)
  local rec = b.rec
  if not rec then return end
  local dead = rec.killed == true
  local unseen = (rec.rare and not rec.seen and not dead) and true or false
  if b.port.SetDesaturated then b.port:SetDesaturated(dead or unseen) end
  b.veil:SetShown(dead)
  b.check:SetShown(dead)
  local e = rec.rare and T.silver or T.cardEdge
  b.edge(e, rec.rare and (unseen and 0.5 or 0.9) or T.cardEdge[4])
  local a = unseen and 0.45 or 1
  b.face:SetAlpha(a)
  b.faceAlpha = a
  local c = dead and T.muted or T.fg
  b.badge:SetTextColor(c[1], c[2], c[3])
end

local function FillHead(b, rec, n)
  b.rec, b.n, b.stale = rec, n, nil
  b.badge:SetText(n and tostring(n) or "")
  b.badge:SetShown(n ~= nil); b.chip:SetShown(n ~= nil)
  b.chip:SetWidth((n and n >= 10) and 18 or 14)
  SetPortrait(b, rec)
  local m = MacroFor(rec)
  if b.macro ~= m then b:SetAttribute("macrotext", m); b.macro = m end
  b:SetAttribute("type", "macro")
  PaintHead(b)
end

-- where the strip docks: the guide when it shows, else the tracker
local function Host()
  if parentFrame and parentFrame:IsShown() then return parentFrame end
  local tr = WLHelperTracker and WLHelperTracker.Frame and WLHelperTracker.Frame()
  if tr and tr:IsShown() then return tr end
  return nil
end

-- a frame's box in the strip's units (nil when the client does not know yet)
local function BoxOf(fr)
  local okS, ps = pcall(fr.GetEffectiveScale, fr)
  ps = okS and num(ps)
  local ms = num(P:GetEffectiveScale())
  local l, r, t, b = num(fr:GetLeft()), num(fr:GetRight()), num(fr:GetTop()), num(fr:GetBottom())
  if not (ps and ms and ms > 0 and l and r and t and b) then return nil end
  local k = ps / ms
  return l * k, r * k, t * k, b * k
end

local function Build()
  if P then return P end
  if InCombat() then return nil end
  P = CreateFrame("Frame", "WLBossPanel", UIParent)
  P:SetSize(SIZE + 2 * PAD, 120)
  P:SetFrameStrata("MEDIUM")
  P:SetClampedToScreen(true)
  P:SetMovable(true)
  P:EnableMouse(true)
  P:Hide()
  if ns.RegisterWindow then ns.RegisterWindow(P) end
  local bg = ns.Tex(P, "BACKGROUND", T.bg); bg:SetAllPoints()
  ns.Outline(P, T.cardEdge)
  -- drag anywhere off the heads: the strip leaves the guide and stays where you drop it
  P:RegisterForDrag("LeftButton")
  P:SetScript("OnDragStart", function() if not InCombat() then P.wlMoving = true; P:StartMoving() end end)
  P:SetScript("OnDragStop", function()
    if not P.wlMoving then return end
    P.wlMoving = nil
    if not InCombat() then P:StopMovingOrSizing() end
    P.SavePos()
  end)
  P:SetScript("OnEnter", function(self)
    local lines = { L.BOSS_TITLE }
    if P.dkey then lines[#lines + 1] = ns.DName(P.dkey) end
    lines[#lines + 1] = P.attached and L.BOSS_DRAG or L.BOSS_DRAG2
    ns.ShowTip(self, lines)
  end)
  P:SetScript("OnLeave", ns.HideTip)
  -- top bar: close (and "attach" once moved away)
  local S = ns.S
  P.close = S.CloseButton(P, 20, function() ns.HideBosses(true) end, { L.BOSS_TITLE, L.BOSS_CLOSE_CLICK })
  P.close:SetPoint("TOPRIGHT", -2, -2)
  P.attach = S.IconButton(P, "pin", 20, { L.BOSS_ATTACH, L.BOSS_ATTACH_CLICK }, function()
    if InCombat() then return end
    DB().bossDetached = nil
    ns.RefreshBosses()
  end)
  P.attach:SetPoint("RIGHT", P.close, "LEFT", -2, 0)
  -- section labels (11, muted; the rares' in silver)
  P.secBoss = ns.Text(P, ns.F.meta, T.muted, false)
  P.secRare = ns.Text(P, ns.F.meta, T.silver, false)
  ns.ClampLabel(P.secBoss, nil, P); ns.ClampLabel(P.secRare, nil, P)
  -- nothing to show: one short sentence
  P.empty = ns.Text(P, ns.F.meta, T.muted, false)
  P.empty:SetJustifyH("LEFT")
  P.empty:Hide()
  P.heads = {}
  -- the position after a move (the drag's end, or the start of combat)
  function P.SavePos()
    local l, t = num(P:GetLeft()), num(P:GetTop())
    if l and t then
      local db = DB()
      db.bossPos = { l, t }
      db.bossDetached = true
      P.attached = false
      if not InCombat() then P:ClearAllPoints(); P:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", l, t) end
      ns.RefreshBosses()
    end
  end
  -- docked: follow the guide (or the tracker) when it moves or changes height, out of combat
  local acc = 0
  P:SetScript("OnUpdate", function(_, el)
    acc = acc + (num(el) or 0)
    if acc < 0.2 or InCombat() or not P.attached then return end
    acc = 0
    local h = Host()
    if not h then return end
    local l, _, t, b = BoxOf(h)
    if h ~= P.host or l ~= P.lastL or t ~= P.lastT or b ~= P.lastB then ns.RefreshBosses() end
  end)
  return P
end

-- Puts the strip 4 px right of its host, tops aligned (left of it when the screen has no room).
-- Absolute position: no anchor to the guide, so the guide never becomes a protected frame.
function ns.SnapBosses()
  if not P then return end
  if InCombat() then pending.snap = true return end
  local h = P.attached and Host()
  if h then
    local l, r, t, b = BoxOf(h)
    if l then
      local okW, sw = pcall(UIParent.GetWidth, UIParent)
      sw = okW and num(sw) or 1920
      local w = num(P:GetWidth()) or SIZE
      local x = r + 4
      if x + w > sw then x = l - 4 - w end
      P:ClearAllPoints()
      P:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, t)
      P.host, P.lastL, P.lastT, P.lastB = h, l, t, b
      return
    end
  end
  local pos = DB().bossPos
  P:ClearAllPoints()
  if pos and pos[1] then P:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", pos[1], pos[2])
  else P:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -240, -220) end
end

-- the grid for `cols` columns: label, the bosses, label, the rares -> height
local function GridHeight(nb, nr, cols)
  local h = TOPBAR
  local function block(n) return LABEL + math.ceil(n / cols) * (SIZE + GAP) - GAP end
  if nb > 0 then h = h + block(nb) end
  if nr > 0 then h = h + (nb > 0 and 10 or 0) + block(nr) end
  return h + PAD
end
ns.BossGridHeight = GridHeight

local function Render()
  if not P then return end
  if InCombat() then
    pending.render = true
    -- what can change now: killed and seen
    if P.dkey and P:IsShown() then
      local res = ns.DungeonMobs(P.dkey)
      local by = {}
      for _, r in ipairs(res.bosses) do by[r.en] = r end
      for _, r in ipairs(res.rares) do by[r.en] = r end
      for _, b in ipairs(P.heads) do
        local r = b.rec and by[b.rec.en]
        if r then b.rec.killed, b.rec.seen = r.killed, r.seen; b.stale = true; PaintHead(b) end
      end
    end
    return
  end
  pending.render = nil
  local dkey = P.dkey
  local db = DB()
  local host = Host()
  P.attached = (host ~= nil and not db.bossDetached) and true or false
  P.attach:SetShown(host ~= nil and db.bossDetached == true)
  local res = dkey and ns.DungeonMobs(dkey) or { bosses = {}, rares = {} }
  P.res = res
  local nb, nr = #res.bosses, #res.rares
  -- as tall as the host at most (the screen's 80 % on its own): more columns when it is not enough.
  -- The host's height is the tallest seen for this dungeon, so the columns do not jump from one
  -- step to the next as the guide grows and shrinks.
  local okH, screen = pcall(UIParent.GetHeight, UIParent)
  screen = okH and num(screen) or 768
  local cap = math.floor(screen * 0.8)
  if P.capKey ~= dkey then P.capKey, P.capHost = dkey, nil end
  if P.attached and host then
    local _, _, t, b = BoxOf(host)
    if t and b and t - b >= 200 then P.capHost = math.max(P.capHost or 0, math.floor(t - b)) end
    if P.capHost then cap = math.min(cap, P.capHost) end
  end
  local cols = 1
  while cols < MAXCOLS and GridHeight(nb, nr, cols) > cap do cols = cols + 1 end
  P.cols = cols
  local W = PAD + cols * SIZE + (cols - 1) * GAP + PAD
  local used = 0
  local y = TOPBAR
  -- column by column (1 2 3 down the first column, then the next): the dungeon's order reads downward
  local function place(list, numbered)
    local rows = math.max(1, math.ceil(#list / cols))
    for i, rec in ipairs(list) do
      used = used + 1
      local b = P.heads[used]
      if not b then b = MakeHead(used); P.heads[used] = b end
      local c, r = math.floor((i - 1) / rows), (i - 1) % rows
      b:ClearAllPoints()
      b:SetPoint("TOPLEFT", P, "TOPLEFT", PAD + c * (SIZE + GAP), -(y + r * (SIZE + GAP)))
      FillHead(b, rec, numbered and i or nil)
      b:Show()
    end
    y = y + math.ceil(#list / cols) * (SIZE + GAP) - GAP
  end
  local function label(fs, text)
    fs:SetText(text)
    fs:ClearAllPoints(); fs:SetPoint("TOPLEFT", P, "TOPLEFT", PAD, -(y + 2))
    fs:SetWidth(W - 2 * PAD); fs:Show()
    y = y + LABEL
  end
  if nb + nr == 0 then
    P.secBoss:Hide(); P.secRare:Hide()
    W = 180
    local text = L.BOSS_EMPTY_NONE
    if res.loading then text = L.BOSS_LOADING elseif res.noLib then text = L.BOSS_EMPTY_NOLIB end
    P.empty:SetText(text)
    P.empty:ClearAllPoints(); P.empty:SetPoint("TOPLEFT", P, "TOPLEFT", PAD + 2, -TOPBAR)
    local eh = ns.FitText(P.empty, 4, W - 2 * PAD - 4, P)
    P.empty:Show()
    y = TOPBAR + math.ceil(num(eh) or 28)
  else
    P.empty:Hide()
    if nb > 0 then label(P.secBoss, L.BOSS_SEC); place(res.bosses, true) else P.secBoss:Hide() end
    if nr > 0 then
      if nb > 0 then y = y + 10 end
      label(P.secRare, L.BOSS_RARES); place(res.rares, false)
    else P.secRare:Hide() end
  end
  for i = used + 1, #P.heads do P.heads[i]:Hide(); P.heads[i].rec = nil end
  P:SetWidth(W)
  P:SetHeight(math.ceil(y + PAD))
  ns.SnapBosses()
end
ns.RenderBosses = Render

function ns.RefreshBosses()
  if not P then return end
  if InCombat() then Render() return end
  if P:IsShown() then Render() end
end

-- Shown, or about to be: in combat a show or hide waits for the end of combat, and the toggles
-- already show what was asked.
function ns.BossesShown()
  if pending.hide then return false end
  if pending.show then return true end
  return P ~= nil and P:IsShown()
end

-- Opens the strip on a dungeon (from the guide, the overview or on entering it).
function ns.ShowBosses(dkey, auto)
  if not (dkey and ns.D and ns.D[dkey]) then return end
  if InCombat() then
    pending.hide = nil
    if P then P:SetAlpha(1) end
    -- already showing this dungeon: nothing waits
    if P and P:IsShown() and P.dkey == dkey then pending.show, pending.showAuto = nil, nil return end
    pending.show = dkey; pending.showAuto = auto
    return
  end
  if not Build() then return end
  P:SetAlpha(1)
  P.dkey = dkey
  P.auto = auto and true or nil
  -- a list still being read shows itself once the data is in
  local res = ns.DungeonMobs(dkey)
  if res.loading then table.insert(onReady, function() if P and P:IsShown() then ns.RefreshBosses() end end) end
  P:Show()
  Render()
end

function ns.HideBosses(byUser)
  if not P then return end
  if byUser then
    local iid = CurrentInstance()
    if iid then dismissed[iid] = true end
  end
  if InCombat() then
    pending.show, pending.showAuto = nil, nil
    -- already hidden: nothing waits; shown: it fades now and hides after combat
    if P:IsShown() then pending.hide = true; P:SetAlpha(0.35) end
    return
  end
  pending.hide = nil
  P:SetAlpha(1)
  P:Hide()
end

function ns.ToggleBosses(dkey)
  local key = pending.show or (P and P.dkey)
  if ns.BossesShown() and (not dkey or key == dkey) then ns.HideBosses(true) else ns.ShowBosses(dkey or key) end
end

-- The guide window the strip sits beside (UI.lua calls it once the guide is built). Hiding the
-- guide moves the strip beside the tracker (or to its saved place).
function ns.AttachBosses(parent)
  if not parent then return end
  parentFrame = parent
  if not parent.wlBossHooked and parent.HookScript then
    parent.wlBossHooked = true
    local function again() if P and P:IsShown() then ns.RefreshBosses() end end
    pcall(parent.HookScript, parent, "OnHide", again)
    pcall(parent.HookScript, parent, "OnShow", again)
  end
  if P then ns.RefreshBosses() end
end

-- ---------------------------------------------------------------- rares: seen and the alert
local function NpcIdOf(unit)
  if not UnitGUID then return nil end
  local okG, guid = pcall(UnitGUID, unit)
  guid = okG and str(guid)
  if not guid then return nil end
  local kind, id = guid:match("^(%a+)%-%d+%-%d+%-%d+%-%d+%-(%d+)")
  if kind == "Creature" or kind == "Vehicle" then return tonumber(id) end
  return nil
end

local function IsRareUnit(unit)
  if not UnitClassification then return false end
  local ok, c = pcall(UnitClassification, unit)
  c = ok and str(c)
  return c == "rare" or c == "rareelite"
end

-- the strip's rare with this NPC id (nil when the strip does not list it)
local function StripRare(id)
  if not (id and P and P.res) then return nil end
  for _, r in ipairs(P.res.rares or {}) do
    for _, x in ipairs(r.ids or {}) do if x == id then return r end end
  end
  return nil
end

-- Records a rare as seen; the strip's head lights up (colours only in combat).
function ns.RareSeen(id)
  id = num(id)
  if not id then return end
  local s = Seen()
  local first = not s[id]
  s[id] = (GetServerTime and GetServerTime()) or (time and time()) or 0
  if first and StripRare(id) and P:IsShown() then Render() end
end

local function SeenCheck(unit)
  local id = NpcIdOf(unit)
  if not id then return end
  if IsRareUnit(unit) or StripRare(id) then ns.RareSeen(id) end
end

-- the banner (plain frame, fixed place) and its secure button (on UIParent at a fixed place too:
-- a secure child or anchor would make the banner protected). The button only ever shows inside
-- the banner: in combat the banner stays up while the button does, and both go after combat.
local A, AB
local alerted = {}
local ALERT_W, ALERT_H, ALERT_Y = 300, 62, -150
local SUB_W, SUB_W_BTN = ALERT_W - 44, ALERT_W - 44 - 130

local function BuildAlertButton()
  if AB or InCombat() then return AB end
  AB = CreateFrame("Button", "WLRareAlertTarget", UIParent, "SecureActionButtonTemplate")
  AB:SetFrameStrata("HIGH")
  AB:SetHeight(24)
  AB:RegisterForClicks("LeftButtonUp", "LeftButtonDown")
  AB:SetAttribute("type", "macro")
  ns.Flat(AB, T.btnFill, T.btnEdge)
  AB.hl = ns.Tex(AB, "BACKGROUND", T.hoverFill); AB.hl:SetAllPoints(); AB.hl:SetAlpha(0)
  AB.icon = AB:CreateTexture(nil, "OVERLAY"); AB.icon:SetSize(14, 14); AB.icon:SetPoint("LEFT", 8, 0)
  ns.SetHDIcon(AB.icon, "star", T.silver)
  AB.label = ns.Text(AB, ns.F.label, T.fg, false)
  AB.label:SetPoint("LEFT", AB.icon, "RIGHT", 6, 0); AB.label:SetWordWrap(false)
  AB.label:SetText(L.BOSS_TARGET)
  local okW, sw = pcall(AB.label.GetStringWidth, AB.label)
  sw = okW and num(sw) or 96
  AB:SetWidth(math.ceil(8 + 14 + 6 + sw + 12))
  AB:SetPoint("BOTTOMRIGHT", UIParent, "TOP", ALERT_W / 2 - 8, ALERT_Y - ALERT_H + 8)
  AB:SetScript("OnEnter", function(self)
    self.hl:SetAlpha(1); if self._edgeSet then self._edgeSet(T.btnEdgeHover) end
    ns.ShowTip(self, { self.who or L.BOSS_TARGET, L.BOSS_TT_TARGET:format(self.who or "?", MarkName(MARK_DEFAULT_RARE)), L.BOSS_TT_CLICK })
  end)
  AB:SetScript("OnLeave", function(self) self.hl:SetAlpha(0); if self._edgeSet then self._edgeSet(T.btnEdge) end; ns.HideTip() end)
  AB:Hide()
  return AB
end

local function BuildAlert()
  if A then return A end
  A = CreateFrame("Frame", "WLRareAlert", UIParent)
  A:SetSize(ALERT_W, ALERT_H)
  A:SetPoint("TOP", UIParent, "TOP", 0, ALERT_Y)
  A:SetFrameStrata("HIGH")
  ns.Flat(A, T.panel, T.cardEdge)
  A.icon = ns.Icon(A, "star", 16, "ARTWORK", T.silver); A.icon:SetPoint("TOPLEFT", 10, -10)
  A.text = ns.Text(A, ns.F.label, T.fg, true)
  A.text:SetPoint("TOPLEFT", A.icon, "TOPRIGHT", 8, 0); A.text:SetWidth(ALERT_W - 44)
  ns.ClampLabel(A.text, nil, A)
  A.sub = ns.Text(A, ns.F.meta, T.muted, false)
  A.sub:SetPoint("BOTTOMLEFT", 34, 14); A.sub:SetWidth(SUB_W_BTN)
  ns.ClampLabel(A.sub, nil, A)
  BuildAlertButton()
  -- a plain cover over the button's place (a child of the banner, never anchored to the button):
  -- when the button still targets an earlier rare and combat forbids changing it, the cover hides
  -- it and swallows its clicks
  A.cover = CreateFrame("Frame", nil, A)
  A.cover:SetSize(AB and num(AB:GetWidth()) or 130, 24)
  A.cover:SetPoint("BOTTOMRIGHT", A, "BOTTOMRIGHT", -8, 8)
  A.cover:SetFrameLevel(((AB and num(AB:GetFrameLevel())) or num(A:GetFrameLevel()) or 1) + 10)
  A.cover:EnableMouse(true)
  local cbg = ns.Tex(A.cover, "BACKGROUND", T.panel); cbg:SetAllPoints()
  A.cover:Hide()
  A:Hide()
  return A
end

-- the sub-line: the full width when the button is not there
local function AlertSub(text, withButton)
  A.sub:SetWidth(withButton and SUB_W_BTN or SUB_W)
  A.sub:SetText(text)
end

local function HideAlert(token)
  if not A or A.token ~= token then return end
  -- the button cannot hide in combat: the banner stays around it until combat ends
  if AB and AB:IsShown() and InCombat() then pending.alertHide = true return end
  A:Hide(); A.cover:Hide()
  if AB then AB:Hide() end
end

-- after combat: the banner's time is up (both go), or the button gets the banner's rare back
local function AlertAfterCombat()
  if pending.alertHide then
    pending.alertHide = nil
    if A then A:Hide(); A.cover:Hide() end
    if AB then AB:Hide() end
    return
  end
  if A and A:IsShown() and ns.lastRareAlert and BuildAlertButton() and (A.cover:IsShown() or not AB:IsShown()) then
    local name = ns.lastRareAlert.name
    AB.who = name
    local m = MacroText(name, MARK_DEFAULT_RARE)
    if AB.macro ~= m then AB:SetAttribute("macrotext", m); AB.macro = m end
    AB:Show(); A.cover:Hide()
    AlertSub(L.RARE_ALERT_HERE, true)
    ns.lastRareAlert.button = true
  end
end

local function ShowAlert(name, level, id)
  BuildAlert()
  ns.lastRareAlert = { name = name, level = level, id = id }
  A.text:SetText(level and L.RARE_ALERT_LVL:format(name, level) or L.RARE_ALERT:format(name))
  local withButton = false
  if not InCombat() then
    local btn = BuildAlertButton()
    if btn then
      btn.who = name
      local m = MacroText(name, MARK_DEFAULT_RARE)
      if btn.macro ~= m then btn:SetAttribute("macrotext", m); btn.macro = m end
      btn:Show()
      withButton = true
    end
    A.cover:Hide()
  elseif AB and AB:IsShown() then
    if AB.who == name then withButton = true; A.cover:Hide()
    else    -- it still targets the earlier rare: covered until combat ends
      A.cover:SetWidth((num(AB:GetWidth()) or 130) + 2)
      A.cover:Show()
    end
  end
  AlertSub(withButton and L.RARE_ALERT_HERE or L.RARE_ALERT_COMBAT, withButton)
  ns.lastRareAlert.button = withButton
  pending.alertHide = nil
  A:SetAlpha(0); A:Show()
  if ns.Tween then ns.Tween(A, 0, 1, 0.15, function(v) A:SetAlpha(v) end) else A:SetAlpha(1) end
  if PlaySound then pcall(PlaySound, (SOUNDKIT and SOUNDKIT.RAID_WARNING) or 8959, "Master") end
  local token = {}
  A.token = token
  if C_Timer and C_Timer.After then C_Timer.After(10, function() HideAlert(token) end) end
end
ns.HideRareAlert = function() if A then HideAlert(A.token) end end

-- a boolean the code may read (nil when the client hides it behind a secret value)
local function bool(v) if type(v) == "boolean" and not secret(v) then return v end return nil end

-- A rare's nameplate: seen for the strip, and the alert (once per 10 minutes per rare). The alert
-- plays inside a dungeon (WLDTDB.rareAlert ~= false); in the open world only when
-- WLDTDB.rareAlertWorld is true.
function ns.RareAlert(unit)
  if not (unit and IsRareUnit(unit)) then return false end
  local okD, dead = pcall(UnitIsDead or function() return false end, unit)
  if okD and bool(dead) == true then return false end
  if UnitCanAttack then
    local okA, can = pcall(UnitCanAttack, "player", unit)
    if okA and bool(can) == false then return false end
  end
  local id = NpcIdOf(unit)
  if id then ns.RareSeen(id) end
  local db = DB()
  if db.rareAlert == false then return false end
  if not CurrentInstance() and db.rareAlertWorld ~= true then return false end
  local okN, name = pcall(UnitName, unit)
  name = okN and str(name)
  if not name or name == "" then return false end
  local key = id or name
  local now = (GetTime and GetTime()) or 0
  if alerted[key] and now >= alerted[key] and now - alerted[key] < 600 then return false end
  alerted[key] = now
  local okL, lv = pcall(UnitLevel or function() return nil end, unit)
  lv = okL and num(lv)
  ShowAlert(name, (lv and lv > 0) and lv or nil, id)
  return true
end

-- ---------------------------------------------------------------- inside a dungeon
local function DungeonHere()
  if not ns.InstanceKeys then return nil end
  local okK, keys, iid = pcall(ns.InstanceKeys)
  if not okK or type(keys) ~= "table" or #keys == 0 then return nil, nil end
  if ns.instIn then for _, k in ipairs(keys) do if k == ns.instIn then return k, iid end end end
  local sel = ns.route and ns.route.sel
  if sel then for _, k in ipairs(keys) do if sel[k] then return k, iid end end end
  if #keys == 1 then return keys[1], iid end
  return nil, iid
end

local function OnEntering()
  NewVisitCheck(true)
  local dkey, iid = DungeonHere()
  if not iid then
    -- out of the dungeon: the strip opened for it goes away
    if P and P:IsShown() and P.auto then ns.HideBosses() end
    for k in pairs(dismissed) do dismissed[k] = nil end
    return
  end
  if Lib() then
    StartIndex(false)
    -- the dungeon's boss list (local names, NPC ids) is built even with the strip hidden: the
    -- guide matches kills on it (a French ENCOUNTER_END name, a boss without encounter ID)
    if dkey then
      local function warm() pcall(ns.DungeonMobs, dkey) end
      if indexReady then warm() else onReady[#onReady + 1] = warm end
    end
  end
  local guideOn = (not ns.GuideOn) or ns.GuideOn()
  if dkey and guideOn and DB().bossAuto ~= false and not dismissed[iid] then
    if not (P and P:IsShown() and P.dkey == dkey) then ns.ShowBosses(dkey, true) end
  end
end

-- the guide follows a kill: its boss step completes (one refresh, a moment later)
local guidePending = false
local function GuideAfterKill()
  if guidePending then return end
  guidePending = true
  local function go()
    guidePending = false
    if ns.OnBossKilled then pcall(ns.OnBossKilled) end
  end
  if C_Timer and C_Timer.After then C_Timer.After(0.3, go) else go() end
end

local function MarkKilled(name, id, enc, en)
  if not CurrentInstance() then return end
  NewVisitCheck()
  local k = Kills()
  local hit = false
  if name and name ~= "" then k.names[name] = true; hit = true end
  if en and en ~= "" then k.names[en] = true; hit = true end
  if id then k.ids[id] = true; hit = true end
  if enc then k.enc[enc] = true; hit = true end
  if hit then liveIid, liveRun = k.iid, k.run; ns.RefreshBosses(); GuideAfterKill() end
end
ns.BossMarkKilled = MarkKilled

-- A boss counted as killed stands alive, attackable and out of combat: this is another copy of the
-- instance (reset by the group leader, or entered again after a logout), a new run.
local function AliveCheck(unit, rec, id)
  -- (the caller saw it alive: UnitIsDead gave a plain false)
  if InCombat() then return false end
  local k = Kills()
  local iid = CurrentInstance()
  if not (iid and k.iid == iid) then return false end
  if not ((id and k.ids[id]) or (rec.en and k.names[rec.en])) then return false end
  local okA, atk = pcall(UnitCanAttack or function() return nil end, "player", unit)
  if not (okA and bool(atk) == true) then return false end
  local okC, fight = pcall(UnitAffectingCombat or function() return true end, unit)
  if not (okC and bool(fight) == false) then return false end
  NewRun(k, iid)
  k.t = Now()
  ns.RefreshBosses()
  GuideAfterKill()
  return true
end

-- The bosses a unit may be: the strip's heads when it shows, else the dungeon's boss list (the
-- list built for the strip, or the walk order) -> list of { en, name, ids }
local function Candidates()
  if P and P:IsShown() and P.res then
    local out = {}
    for _, list in ipairs({ P.res.bosses, P.res.rares }) do for _, r in ipairs(list) do out[#out + 1] = r end end
    return out, true
  end
  local dkey = DungeonHere()
  if not dkey then return {}, false end
  local res = mobsCache[dkey]
  if res then
    local out = {}
    for _, r in ipairs(res.bosses) do out[#out + 1] = r end
    for _, r in ipairs(res.rares) do out[#out + 1] = r end
    return out, false
  end
  local out = {}
  local bo = ns.BossOrder and ns.BossOrder(dkey)
  for _, b in ipairs(bo and bo.list or {}) do out[#out + 1] = { en = b.en, name = b.name, ids = b.npc and { b.npc } or {} } end
  return out, false
end

-- Your target (or the mob under the mouse) is one of the dungeon's bosses: learn its creature type,
-- and a dead one counts as killed (the strip's head and the guide's boss step).
local function TargetCheck(unit)
  unit = unit or "target"
  if not (UnitExists and UnitExists(unit)) then return end
  local list, strip = Candidates()
  if #list == 0 then return end
  local id = NpcIdOf(unit)
  local okN, nm = pcall(UnitName, unit)
  nm = okN and str(nm)
  local rec
  for _, r in ipairs(list) do
    if (nm and (r.name == nm or r.en == nm)) then rec = r end
    if id then for _, x in ipairs(r.ids or {}) do if x == id then rec = r end end end
  end
  if not rec then return end
  -- learn its creature type for the painted icon
  if strip and UnitCreatureType then
    local okT, ty = pcall(UnitCreatureType, unit)
    ty = okT and str(ty)
    if ty and TYPE_ICON[ty] then
      local db = DB()
      db.bossType = db.bossType or {}
      if db.bossType[rec.en] ~= ty then db.bossType[rec.en] = ty; pending.render = true end
    end
  end
  local okD, dead = pcall(UnitIsDead or function() return false end, unit)
  if okD and bool(dead) == false then AliveCheck(unit, rec, id) return end
  if okD and bool(dead) == true then
    local k = Kills()
    -- already counted: nothing to do (a dead boss under the mouse fires this often)
    if CurrentInstance() == k.iid and k.names[rec.en] then return end
    MarkKilled(rec.name, id, nil, rec.en)
  end
end
ns.BossTargetCheck = TargetCheck

-- the game's "%s has been reset." as a pattern (nil when the client has no such string)
local resetPat
local function ResetPattern()
  if resetPat == nil then
    local g = _G.INSTANCE_RESET_SUCCESS
    if type(g) == "string" and g:find("%s", 1, true) then
      resetPat = "^" .. g:gsub("([%(%)%.%+%-%*%?%[%]%^%$])", "%%%1"):gsub("%%s", ".+") .. "$"
    end
  end
  return resetPat or nil
end

local ev = CreateFrame("Frame")
for _, e in ipairs({ "PLAYER_ENTERING_WORLD", "PLAYER_REGEN_ENABLED", "PLAYER_REGEN_DISABLED", "ENCOUNTER_START", "ENCOUNTER_END", "BOSS_KILL", "PLAYER_LOGOUT",
  "PLAYER_TARGET_CHANGED", "QUEST_LOG_UPDATE", "QUEST_TURNED_IN", "NAME_PLATE_UNIT_ADDED", "UPDATE_MOUSEOVER_UNIT", "CHAT_MSG_SYSTEM" }) do
  pcall(ev.RegisterEvent, ev, e)
end
-- the target's health only (a dead boss you look at counts as killed)
if not (ev.RegisterUnitEvent and pcall(ev.RegisterUnitEvent, ev, "UNIT_HEALTH", "target")) then
  pcall(ev.RegisterEvent, ev, "UNIT_HEALTH")
end
local questPending = false
ev:SetScript("OnEvent", function(_, e, a1, a2, a3, a4, a5)
  if e == "PLAYER_ENTERING_WORLD" then
    if C_Timer and C_Timer.After then C_Timer.After(2.5, OnEntering) else OnEntering() end
  elseif e == "PLAYER_LOGOUT" then
    -- a logout (or /reload) inside counts as leaving: back much later, it is another copy
    Touch(true)
  elseif e == "ENCOUNTER_START" then
    -- encounterID, encounterName: the NPC ids of the boss frames, so its end matches the step even
    -- when the encounter's name is in another language and the journal gives no encounter ID
    local enc = num(a1)
    if enc then
      local k = Kills()
      k.encNpc = k.encNpc or {}
      local ids = {}
      for b = 1, 5 do local id = NpcIdOf("boss" .. b); if id then ids[#ids + 1] = id end end
      if #ids > 0 then k.encNpc[enc] = ids end
    end
  elseif e == "PLAYER_REGEN_DISABLED" then
    Touch()
    if P and P.wlMoving then P.wlMoving = nil; P:StopMovingOrSizing(); P.SavePos() end
  elseif e == "PLAYER_REGEN_ENABLED" then
    Touch()
    if pending.hide then pending.hide = nil; if P then P:SetAlpha(1); P:Hide() end end
    if pending.show then local k, a = pending.show, pending.showAuto; pending.show, pending.showAuto = nil, nil; ns.ShowBosses(k, a) end
    if pending.render or pending.snap then pending.render, pending.snap = nil, nil; if P and P:IsShown() then Render() end end
    AlertAfterCombat()
  elseif e == "ENCOUNTER_END" then
    -- encounterID, encounterName, difficultyID, groupSize, success
    if num(a5) == 1 then
      local enc = num(a1)
      local k = Kills()
      local ids = enc and k.encNpc and k.encNpc[enc]
      if ids then for _, id in ipairs(ids) do MarkKilled(nil, id) end end
      MarkKilled(str(a2), nil, enc)
    end
  elseif e == "BOSS_KILL" then
    -- encounterID, encounterName
    MarkKilled(str(a2), nil, num(a1))
  elseif e == "CHAT_MSG_SYSTEM" then
    -- "Zul'Farrak has been reset.": the next entry is a new run
    local msg = str(a1)
    if msg and ResetPattern() and msg:match(ResetPattern()) then ns.ResetBossRun() end
  elseif e == "PLAYER_TARGET_CHANGED" then
    Touch()
    SeenCheck("target")
    TargetCheck("target")
  elseif e == "UPDATE_MOUSEOVER_UNIT" then
    SeenCheck("mouseover")
    TargetCheck("mouseover")
  elseif e == "NAME_PLATE_UNIT_ADDED" then
    local unit = str(a1)
    if unit then
      SeenCheck(unit)
      ns.RareAlert(unit)
    end
  elseif e == "UNIT_HEALTH" then
    if a1 == "target" then TargetCheck("target") end
  elseif (e == "QUEST_LOG_UPDATE" or e == "QUEST_TURNED_IN") and P and P:IsShown() and not questPending then
    questPending = true
    local function go() questPending = false; ns.RefreshBosses() end
    if C_Timer and C_Timer.After then C_Timer.After(0.5, go) else go() end
  end
end)
ns.BossEvents = ev
