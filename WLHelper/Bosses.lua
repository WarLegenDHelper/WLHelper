-- Bosses.lua: the bosses and rares of a dungeon as a small panel beside the guide (or on its own).
-- Data read LIVE from LibForeverData (optional dependency, never copied): every NPC whose spawns
-- sit on the dungeon's instance map (ns.D[k].inst = the client Map id LibForeverData stores for
-- instance spawns), ranked boss (3) or rare (2 rare elite, 4 rare), plus the bosses of the walk
-- order (ns.WALK / ns.BossOrder: most 5-player bosses are only "elite" in the data).
-- The panel: a 44 px header like the guide's (the dungeon's name, "Bosses and rares" under it; on
-- the right the dungeon's map, a "new run" button during the run, close), the current run's numbers
-- (time since entering, XP and gold gained inside; one sentence instead before the run starts),
-- then a grid of ROUND creature portraits, five per row in dungeon order, and the rares under a
-- "Rares" label. Moved away from the guide, a "Dock to the guide" text link sits under the grid
-- (a word, not the pin: the pin means GPS only). Every creature gets a face: its display
-- id (the dungeon journal's model, the game's encounter journal, or a one-time hidden model lookup
-- made outside instances and kept in WLDTDB.bossDisplay) drawn with
-- SetPortraitTextureFromCreatureDisplayID; once the creature is seen as a unit its live portrait;
-- else its creature family's painted icon, cropped round. Forever paints a creature portrait as a
-- black square until its model has loaded: portraits are drawn off screen first and moved in once
-- ready (one texture per creature, kept for the session).
-- Killed: greyed, veiled, a check. A rare not seen yet: a grey silhouette (seen = its nameplate,
-- your target or your mouse met it once, kept in WLDTDB.raresSeen); seen: full colour, silver ring.
-- The name, level, quests and the click line live in the tooltip. Each portrait IS a secure button
-- (macro: target and mark), created, moved, shown and given its macro out of combat only; changes
-- in combat wait for PLAYER_REGEN_ENABLED (only colours and texts change in combat).
-- Run numbers (WLDTDB.bossKills: xp, money, at, lastKill, dkey): XP from PLAYER_XP_UPDATE deltas and
-- gold from PLAYER_MONEY gains while inside the run's copy. Leaving keeps them in WLDTDB.lastRun
-- and prints a one-line report.
-- Rare alert (inside a dungeon, WLDTDB.rareAlert ~= false; the open world too when
-- WLDTDB.rareAlertWorld is true): a rare shows up -> a sound and a small banner with a secure
-- "Target and mark" button (made out of combat), at most once per 10 min per rare.
-- API: ns.DungeonMobs(dkey[, sync]) -> { bosses = {...}, rares = {...}, loading, source }
--      ns.ShowBosses(dkey), ns.HideBosses(), ns.ToggleBosses(dkey), ns.AttachBosses(parentFrame),
--      ns.RefreshBosses(), ns.BossesShown(), ns.RareSeen(npcId), ns.RareAlert(unit),
--      ns.NewBossRun(), ns.BossCommand(), ns.BossRunStats(dkey)
--      ns.OpenDungeonMap(dkey), ns.DungeonMapSource(dkey) -> kind, label (OpenMap, Naowh, FDJ, world map)
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
  if ns.BossWatchReset then ns.BossWatchReset() end
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
  -- the run's numbers: XP and gold gained inside, when each boss died, the dungeon it is
  k.xp, k.money, k.at, k.lastKill, k.dkey, k.reported = 0, 0, {}, nil, nil, nil
  -- the panel's right-click: marked killed by hand / marked not killed by hand
  k.manual, k.off = nil, nil
  -- the wing the run started in, per dungeon (ns.WALK_WINGS)
  k.wing = nil
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
          rare = (rk == 2 or rk == 4) or (jb ~= nil and jb.rare == true), order = mine[r.name] or (jb and jb._i and 200 + jb._i) or nil,
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
      local rare = (jb ~= nil and jb.rare == true)
      local rec = { id = jb and jb.npc, en = nm, rank = rare and 4 or 1, rare = rare, order = mine[nm],
        model = jb and num(jb.model) or nil, journal = jb }
      Add(rec, rare and res.rares or res.bosses)
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
    local oa, ob = a.order or 10000, b.order or 10000
    if oa ~= ob then return oa < ob end
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
            -- (unless marked "not killed" by hand on the panel)
            if o.k == "kill" and done and log[qid] and fresh and k.objs and not k.objs[qid .. ":" .. oi]
              and not (k.off and k.off[rec.en]) then
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
    if ready or not hasLib then
      mobsCache[dkey] = res
      -- the death checks pick up the new list (NPC ids)
      if ns.BossWatchReset then ns.BossWatchReset() end
    end
  end
  res.loading = (hasLib and not ready) or nil
  res.noLib = (not hasLib) or nil
  for _, rec in ipairs(res.bosses) do rec.name = LocalName(rec.id, rec.en, rec.journal) end
  for _, rec in ipairs(res.rares) do rec.name = LocalName(rec.id, rec.en, rec.journal) end
  Dynamic(res)
  return res
end

-- ---------------------------------------------------------------- the guide's walkthrough
-- A boss's name as this client writes it (the panel's list when built, else the English name).
function ns.BossLocalName(dkey, en)
  local res = dkey and mobsCache[dkey]
  if res then
    for _, list in ipairs({ res.bosses, res.rares }) do
      for _, r in ipairs(list) do if r.en == en then return LocalName(r.id, r.en, r.journal) end end
    end
  end
  return en
end
-- The NPC ids of a boss on the dungeon's map (LibForeverData, once the index is ready).
function ns.BossNpcIds(dkey, en)
  local res = dkey and mobsCache[dkey]
  if res then
    for _, list in ipairs({ res.bosses, res.rares }) do
      for _, r in ipairs(list) do if r.en == en then return r.ids end end
    end
  end
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

-- ---------------------------------------------------------------- what a dungeon has for your gear
-- Which dungeon to farm (report: "a gearing guide, which dungeon to farm for my BiS"): every boss's
-- loot of a dungeon (BOSS_LOOT), counted for you. bis: Naowh's BiS list ranks it 1 for your spec,
-- alt: its 2nd pick (ns.BisBadge, Naowh read live, nothing copied); up: not on its list, but WL
-- Helper's own gear check (hit and defense caps, leveling) calls it an upgrade of GEAR_MIN % or more.
-- Owned items (worn, bags, bank) and items you are GEAR_LEVELS levels or more from wearing do not
-- count. -> { bis, alt, up, total } (total: bis + alt + up). Kept until your gear, bags, level or
-- Naowh's list change; an item not loaded yet leaves the count open (asked again next time).
do
local GEAR_MIN, GEAR_LEVELS = 5, 4
local gearCache = {}
local function GearReset() wipe(gearCache) end
ns.DungeonGearReset = GearReset
do
  local gf = CreateFrame("Frame")
  for _, e in ipairs({ "PLAYER_EQUIPMENT_CHANGED", "BAG_UPDATE_DELAYED", "PLAYER_LEVEL_UP", "PLAYER_SPECIALIZATION_CHANGED", "CHARACTER_POINTS_CHANGED" }) do
    pcall(gf.RegisterEvent, gf, e)
  end
  gf:SetScript("OnEvent", GearReset)
end
local naowhHooked = false
function ns.DungeonGear(k)
  if not naowhHooked then
    local WP = ns.Writs and ns.Writs.WP
    local NB = WP and WP.NaowhBiS
    if NB and NB.OnChange then naowhHooked = true; pcall(NB.OnChange, GearReset) end
  end
  local c = gearCache[k]
  if c then return c end
  local r = { bis = 0, alt = 0, up = 0, total = 0 }
  local loot = ns.BOSS_LOOT and ns.BOSS_LOOT[k]
  if type(loot) ~= "table" then gearCache[k] = r; return r end
  local WP = ns.Writs and ns.Writs.WP
  local lv = (UnitLevel and UnitLevel("player")) or 1
  local open, seen = false, {}
  for _, ids in pairs(loot) do
    for _, id in ipairs(type(ids) == "table" and ids or {}) do
      if not seen[id] then
        seen[id] = true
        if not (ns.OwnsItem and ns.OwnsItem(id)) then
          local okI, _, link, _, _, minLv, _, _, _, equipLoc = pcall(ns.ItemInfo, id)
          if not (okI and link) then
            open = true
            if C_Item and C_Item.RequestLoadItemDataByID then pcall(C_Item.RequestLoadItemDataByID, id) end
          elseif type(equipLoc) == "string" and equipLoc ~= "" and not (type(minLv) == "number" and minLv > lv + GEAR_LEVELS) then
            local rk
            if ns.BisBadge then local okB, x = pcall(ns.BisBadge, link); if okB then rk = x end end
            if rk == 1 then r.bis = r.bis + 1
            elseif rk == 2 then r.alt = r.alt + 1
            elseif WP and WP.UpgradeCheck then
              local okU, u = pcall(WP.UpgradeCheck, link)
              if okU and type(u) == "table" and u.up and (u.n or 0) >= GEAR_MIN then r.up = r.up + 1 end
            end
          end
        end
      end
    end
  end
  r.total = r.bis + r.alt + r.up
  if not open then gearCache[k] = r end
  return r
end
-- "3 BiS pour toi · 2 améliorations", or nil when there is nothing for you
function ns.DungeonGearText(k, short)
  local g = ns.DungeonGear(k)
  if not g or g.total == 0 then return nil end
  local parts = {}
  local nb = g.bis + g.alt
  if nb > 0 then parts[#parts + 1] = ns.Plural(nb, short and "GEAR_BIS1_S" or "GEAR_BIS1", short and "GEAR_BIS_S" or "GEAR_BIS", nb) end
  if g.up > 0 then parts[#parts + 1] = ns.Plural(g.up, "GEAR_UP1", "GEAR_UP", g.up) end
  return table.concat(parts, "  ·  ")
end
-- The dungeons to farm for your gear, best first: { { key, gear }, ... } (n at most; BiS first, then
-- every upgrade; dungeons far above your level left out)
function ns.GearPlan(n)
  local out = {}
  local lv = (UnitLevel and UnitLevel("player")) or 1
  for _, k in ipairs(ns.ORDER or {}) do
    local d = ns.D[k]
    if d and not d.raid and d.lvl and (d.lvl[1] or 1) <= lv + GEAR_LEVELS then
      local g = ns.DungeonGear(k)
      if g.total > 0 then out[#out + 1] = { key = k, gear = g } end
    end
  end
  table.sort(out, function(a, b)
    local ab, bb = a.gear.bis * 3 + a.gear.alt * 2 + a.gear.up, b.gear.bis * 3 + b.gear.alt * 2 + b.gear.up
    if ab ~= bb then return ab > bb end
    return a.key < b.key
  end)
  if n then for i = #out, n + 1, -1 do out[i] = nil end end
  return out
end
-- /wlh farm: the plan in the chat
function ns.GearPlanPrint()
  local plan = ns.GearPlan(5)
  if #plan == 0 then ns.Print(L.GEAR_NONE); return end
  ns.Print(L.GEAR_HEAD)
  for i, e in ipairs(plan) do
    ns.Print(string.format("%d. %s : %s", i, ns.DName(e.key), ns.DungeonGearText(e.key) or ""))
  end
end
end

-- ---------------------------------------------------------------- the dungeon you are in
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

-- ---------------------------------------------------------------- run numbers
-- The run in progress (inside its copy) -> the kills record, else nil.
local function InRun()
  local iid = CurrentInstance()
  local k = Kills()
  if iid and k.iid == iid then return k end
  return nil
end
-- The run's dungeon, learned inside (the instance alone may hold several wings).
local function RunDungeon(k)
  if not k.dkey and CurrentInstance() == k.iid then k.dkey = DungeonHere() end
  return k.dkey
end

-- ---------------------------------------------------------------- wings (several ways in)
-- ns.WALK_WINGS (Curated.lua): a dungeon entered by several wings that meet further in (Maraudon:
-- the orange and the purple wing, then the inner caves). The run walks the wing it started in
-- first, then the other wings, then the shared part. ns.WALK[dkey] holds that order, so the
-- bosses panel and the guide's boss steps (ns.BossOrder) follow it; a kill still completes its
-- own boss's step, whichever wing it is in.
-- The wing the run started in: the wing of the first boss killed in this run, else where you
-- stand (the subzone's name, your position on the instance map, a wing boss you target; kept for
-- the run), else the data's first wing.
local Wing = { now = {} }   -- now: dkey -> the wing ns.WALK[dkey] was built for (one local: the chunk is near Lua's 200)

-- The run order with `first` (a wing key) first -> list of English names, or nil (no wings)
function ns.WingWalk(dkey, first)
  local W = ns.WALK_WINGS and ns.WALK_WINGS[dkey]
  if not W then return nil end
  local out, seen = {}, {}
  local function add(l) for _, nm in ipairs(l or {}) do if not seen[nm] then seen[nm] = true; out[#out + 1] = nm end end end
  for _, w in ipairs(W) do if w.key == first then add(w.bosses) end end
  for _, w in ipairs(W) do add(w.bosses) end
  add(W.tail)
  return out
end
-- the wing a boss (English or local name) belongs to, nil for the shared part
function Wing.Of(dkey, name)
  local W = ns.WALK_WINGS and ns.WALK_WINGS[dkey]
  if not (W and name) then return nil end
  for _, w in ipairs(W) do
    for _, en in ipairs(w.bosses or {}) do
      if en == name or (ns.BossLocalName and ns.BossLocalName(dkey, en) == name) then return w.key end
    end
  end
  return nil
end
ns.BossWingOf = Wing.Of
-- The wing you stand in: the subzone's name, else your position on the wing's instance map
-- (nil: the shared part, the entrance, outside, unknown).
function Wing.Here(dkey)
  local W = ns.WALK_WINGS and ns.WALK_WINGS[dkey]
  if not W then return nil end
  for _, fn in ipairs({ GetSubZoneText or false, GetMinimapZoneText or false }) do
    local okZ, zone = false, nil
    if fn then okZ, zone = pcall(fn) end
    zone = okZ and str(zone) or nil
    if zone and zone ~= "" then
      for _, w in ipairs(W) do
        for _, z in ipairs(w.zones or {}) do if z == zone then return w.key end end
      end
    end
  end
  if W.map and C_Map and C_Map.GetBestMapForUnit and C_Map.GetPlayerMapPosition then
    local okM, m = pcall(C_Map.GetBestMapForUnit, "player")
    if okM and num(m) == W.map then
      local okP, pos = pcall(C_Map.GetPlayerMapPosition, m, "player")
      local x, y
      if okP and type(pos) == "table" and pos.GetXY then
        local okX, a, b = pcall(pos.GetXY, pos)
        if okX then x, y = num(a), num(b) end
      end
      if x and y and not (x == 0 and y == 0) then
        local best, bd
        for _, w in ipairs(W) do
          for _, p in ipairs(w.pts or {}) do
            local dd = (p[1] - x) ^ 2 + (p[2] - y) ^ 2
            if not bd or dd < bd then best, bd = w.key, dd end
          end
        end
        if bd and bd <= (W.near or 0.2) ^ 2 then return best end
      end
    end
  end
  return nil
end
ns.BossWingHere = Wing.Here
-- when a boss of this dungeon died in this run (its names, NPC ids, encounters), nil if it did not
function Wing.KillAt(k, dkey, en)
  if not k.at or (k.off and k.off[en]) then return nil end
  local keys = { en }
  if ns.BossLocalName then keys[#keys + 1] = ns.BossLocalName(dkey, en) end
  for _, id in ipairs(ns.BossNpcIds and ns.BossNpcIds(dkey, en) or {}) do keys[#keys + 1] = "#" .. id end
  local bo = ns.BossOrder and ns.BossOrder(dkey)
  local i = bo and bo.idx and bo.idx[en]
  local B = i and bo.list[i]
  if B and B.npc then keys[#keys + 1] = "#" .. B.npc end
  for _, e in ipairs(B and B.enc or {}) do keys[#keys + 1] = "e" .. e end
  local t
  for _, key in ipairs(keys) do
    local v = key and num(k.at[key])
    if v and (not t or v < t) then t = v end
  end
  return t
end
-- The wing this run of dkey started in (see above)
function Wing.First(dkey)
  local W = ns.WALK_WINGS and ns.WALK_WINGS[dkey]
  if not (W and W[1]) then return nil end
  local k = Kills()
  local d = ns.D and ns.D[dkey]
  local thisRun = d and d.inst and k.iid == d.inst
  if thisRun then
    -- the first boss killed in a wing
    local best, bt
    for _, w in ipairs(W) do
      for _, en in ipairs(w.bosses or {}) do
        local t = Wing.KillAt(k, dkey, en)
        if t and (not bt or t < bt) then best, bt = w.key, t end
      end
    end
    if best then return best end
    -- nothing killed in a wing yet: where you stand, kept for the run
    if CurrentInstance() == k.iid then
      local here = Wing.Here(dkey)
      if here then k.wing = k.wing or {}; k.wing[dkey] = here end
    end
    if k.wing and k.wing[dkey] then return k.wing[dkey] end
  end
  return W[1].key
end
-- Build ns.WALK[dkey] for a wing -> true when the order changed
function Wing.Apply(dkey, key)
  local W = ns.WALK_WINGS and ns.WALK_WINGS[dkey]
  local list = key and ns.WingWalk(dkey, key)
  if not (W and list and ns.WALK) then return false end
  -- an objective done once two wings are: at whichever of its bosses comes later
  local rank = {}
  for i, nm in ipairs(list) do rank[nm] = i end
  for obj, bosses in pairs(W.last or {}) do
    local best
    for _, b in ipairs(bosses) do if rank[b] and (not best or rank[b] > rank[best]) then best = b end end
    if best and ns.GROUP_OBJ then ns.GROUP_OBJ[obj] = best end
  end
  if Wing.now[dkey] == key then return false end
  Wing.now[dkey] = key
  ns.WALK[dkey] = list
  mobsCache[dkey] = nil
  if ns.BossOrderReset then ns.BossOrderReset() end
  if ns.BossWatchReset then ns.BossWatchReset() end
  return true
end
-- The wing ns.WALK[dkey] follows now (nil: the dungeon has no wings)
function ns.BossWing(dkey) return Wing.now[dkey] end
-- Set the order for a wing (tests; the checks below) -> true when it changed
function ns.SetBossWing(dkey, key) return Wing.Apply(dkey, key) end
-- Inside a dungeon with wings: the order follows the wing the run started in. A change rebuilds
-- the bosses panel and the guide's steps (done steps keep their keys: they stay done).
function Wing.Check()
  if not CurrentInstance() then return end
  local dkey = DungeonHere()
  if not (dkey and ns.WALK_WINGS and ns.WALK_WINGS[dkey]) then return end
  if Wing.Apply(dkey, Wing.First(dkey)) then
    if ns.RefreshBosses then ns.RefreshBosses() end
    if ns.OnBossIndexReady then pcall(ns.OnBossIndexReady) end
  end
end
ns.BossWingCheck = Wing.Check
-- A boss of a wing in your target: that is where you are (when nothing says otherwise)
function Wing.Seen(name)
  local dkey = DungeonHere()
  local w = dkey and Wing.Of(dkey, name)
  if not w then return end
  local k = Kills()
  if CurrentInstance() ~= k.iid then return end
  k.wing = k.wing or {}
  if k.wing[dkey] ~= w and not Wing.Here(dkey) then k.wing[dkey] = w end
  Wing.Check()
end
-- at load: every wing dungeon's order starts with its first wing
for dkey, W in pairs(ns.WALK_WINGS or {}) do if W[1] then Wing.Apply(dkey, W[1].key) end end

-- XP and money seen last (session only: a loading screen sets them again, nothing counts across it)
local xpLast, xpMax, xpLvl, moneyLast
local function ReadXP()
  if not (UnitXP and UnitXPMax) then return nil end
  local okX, x = pcall(UnitXP, "player")
  local okM, m = pcall(UnitXPMax, "player")
  local okL, l = pcall(UnitLevel or function() return nil end, "player")
  return okX and num(x) or nil, okM and num(m) or nil, okL and num(l) or nil
end
local function ReadMoney()
  if not GetMoney then return nil end
  local ok, m = pcall(GetMoney)
  return ok and num(m) or nil
end
local function Baseline()
  xpLast, xpMax, xpLvl = ReadXP()
  moneyLast = ReadMoney()
end
-- PLAYER_XP_UPDATE: the gain since the last reading goes to the run. A level-up is the bar rolling
-- over (the XP read goes down): what was left of the old bar plus the new bar's XP, counted once.
-- The client may update the XP, the bar's size and the level in separate events: a level read
-- higher without a rollover adds only the XP difference, and the old bar's size is kept for the
-- rollover still to come.
local function OnXP()
  local x, m, l = ReadXP()
  if not x then return end
  local k = InRun()
  local rolled = xpLast ~= nil and x < xpLast
  if k and xpLast then
    local d
    if rolled then d = math.max(0, (xpMax or xpLast) - xpLast) + x
    else d = x - xpLast end
    if d > 0 then k.xp = (k.xp or 0) + d end
  end
  if rolled then
    xpMax = m
    xpLvl = math.max(l or 0, (xpLvl or l or 0) + 1)
  elseif l and xpLvl and l > xpLvl then
    -- the level first, the XP field later: keep the old bar's size for its rollover
    xpLvl = l
  else
    xpMax = m
    xpLvl = l or xpLvl
  end
  xpLast = x
end
-- PLAYER_MONEY: gains only (purchases and repairs inside do not count against the run)
local function OnMoney()
  local m = ReadMoney()
  if not m then return end
  local k = InRun()
  if k and moneyLast and m > moneyLast then k.money = (k.money or 0) + (m - moneyLast) end
  moneyLast = m
end

-- No XP to show at the level cap.
local function AtCap()
  if IsXPUserDisabled then
    local ok, v = pcall(IsXPUserDisabled)
    if ok and v == true then return true end
  end
  local okL, l = pcall(UnitLevel or function() return nil end, "player")
  l = okL and num(l)
  local maxL = 60
  if GetMaxPlayerLevel then
    local okM, mx = pcall(GetMaxPlayerLevel)
    maxL = okM and num(mx) or maxL
  end
  return l ~= nil and l >= maxL
end

-- 38200 -> "38 200" (fr) / "38,200" (en)
local function FmtNum(n)
  if ns.BigNumber then return ns.BigNumber(n) end   -- the summary's (no-break space), one format everywhere
  n = math.floor((n or 0) + 0.5)
  local s = tostring(n)
  local sep = ns.lang == "fr" and "94p" or ","
  local out = s:reverse():gsub("(%d%d%d)", "%1" .. sep):reverse()
  if out:sub(1, #sep) == sep then out = out:sub(#sep + 1) end
  return out
end
ns.BossFmtNum = FmtNum
-- seconds -> "4:05", "1:02:07"
local function FmtClock(sec)
  sec = math.max(0, math.floor(sec or 0))
  local h, m, s = math.floor(sec / 3600), math.floor((sec % 3600) / 60), sec % 60
  if h > 0 then return ("%d:%02d:%02d"):format(h, m, s) end
  return ("%d:%02d"):format(m, s)
end
ns.BossFmtClock = FmtClock

-- Was this head's creature killed in run k (whatever instance you are in now)?
local function RecKilled(k, rec)
  if k.names[rec.en] or (rec.name and k.names[rec.name]) then return true end
  for _, id in ipairs(rec.ids or {}) do if k.ids[id] then return true end end
  if rec.journal and type(rec.journal.enc) == "table" then
    for _, e in ipairs(rec.journal.enc) do if k.enc[e] then return true end end
  end
  return false
end
-- When it died (server time), nil when unknown.
local function KillTime(k, rec)
  local at = k.at
  if not at then return nil end
  local t = at[rec.en] or (rec.name and at[rec.name])
  for _, id in ipairs(rec.ids or {}) do t = t or at["#" .. id] end
  if rec.journal and type(rec.journal.enc) == "table" then
    for _, e in ipairs(rec.journal.enc) do t = t or at["e" .. e] end
  end
  return t
end

-- The numbers of the run shown for `dkey`: { secs, xp, money, killed, total, done } or nil when
-- the last run was in another dungeon. The time runs from the entry to the last boss's death
-- (frozen while you are outside).
function ns.BossRunStats(dkey, res)
  local k = Kills()
  if not (dkey and k.start and RunDungeon(k) == dkey) then return nil end
  res = res or (mobsCache[dkey])
  local killed, total = 0, 0
  for _, rec in ipairs(res and res.bosses or {}) do
    total = total + 1
    if RecKilled(k, rec) then killed = killed + 1 end
  end
  local done = total > 0 and killed == total and k.lastKill ~= nil
  local stop
  if done then stop = k.lastKill
  elseif CurrentInstance() == k.iid then stop = Now()
  else stop = k.left or k.t or Now() end
  return { secs = math.max(0, stop - k.start), xp = k.xp or 0, money = k.money or 0,
    killed = killed, total = total, done = done }
end

-- "Zul'Farrak : 32 min · 38 200 XP · 12 po · 7/7 boss"
local function DurWords(sec)
  local m = math.floor((sec or 0) / 60)
  if m >= 60 then return L.RUN_HMIN:format(math.floor(m / 60), m % 60) end
  return L.RUN_MIN:format(m)
end
local function MoneyWords(c)
  c = math.floor(c or 0)
  local g, s = math.floor(c / 10000), math.floor((c % 10000) / 100)
  if g > 0 then return L.RUN_G:format(g) end
  if s > 0 then return L.RUN_S:format(s) end
  return L.RUN_C:format(c % 100)
end
function ns.BossRunReport(dkey, st)
  local name = ns.DName(dkey)
  if AtCap() then
    return L.RUN_REPORT_NOXP:format(name, DurWords(st.secs), MoneyWords(st.money), st.killed, st.total)
  end
  return L.RUN_REPORT:format(name, DurWords(st.secs), FmtNum(st.xp), MoneyWords(st.money), st.killed, st.total)
end
-- Out of the dungeon: the run's numbers kept in WLDTDB.lastRun and one line in the chat, once per
-- change. Dead or a ghost (a wipe, a hearthstone after a release): the numbers are kept now and
-- the chat line waits until you are alive outside (k.reportDue).
local function RunReport()
  local k = Kills()
  local dkey = k.dkey
  if not (dkey and k.start and ns.D and ns.D[dkey]) then k.reportDue = nil return end
  local dead = false
  if UnitIsDeadOrGhost then
    local ok, d = pcall(UnitIsDeadOrGhost, "player")
    dead = ok and d == true
  end
  local okR, res = pcall(ns.DungeonMobs, dkey)
  local st = ns.BossRunStats(dkey, okR and res or nil)
  if not st or (st.killed == 0 and st.xp == 0 and st.money == 0) then k.reportDue = nil return end
  local sig = k.run .. ":" .. st.killed .. ":" .. st.xp .. ":" .. st.money
  if k.reported == sig and not k.reportDue then return end
  k.reported = sig
  DB().lastRun = { dkey = dkey, at = Now(), secs = st.secs, xp = st.xp, money = st.money,
    killed = st.killed, total = st.total, done = st.done or nil }
  if dead then k.reportDue = true return end
  k.reportDue = nil
  if ns.Print then ns.Print(ns.BossRunReport(dkey, st)) end
end
ns.BossRunReportNow = RunReport

-- ---------------------------------------------------------------- faces
-- Display ids learned once (a hidden model, outside instances): WLDTDB.bossDisplay[npcId].
local function DisplayDB()
  local db = DB()
  db.bossDisplay = db.bossDisplay or {}
  return db.bossDisplay
end

-- The game's encounter journal: the creature of an encounter (matched by NPC id, else the only one).
local ejCache = {}
local function EJDisplay(rec)
  local jb = rec.journal
  if not (jb and type(jb.enc) == "table" and EJ_GetCreatureInfo) then return nil end
  if ejCache[rec.en] ~= nil then return ejCache[rec.en] or nil end
  local want = {}
  for _, id in ipairs(rec.ids or {}) do want[id] = true end
  if rec.id then want[rec.id] = true end
  local found
  for _, enc in ipairs(jb.enc) do
    local only, count = nil, 0
    for i = 1, 8 do
      local ok, cid, _, _, disp = pcall(EJ_GetCreatureInfo, i, enc)
      if not ok then break end
      cid, disp = num(cid), num(disp)
      if not cid and not disp then break end
      count = count + 1
      only = only or disp
      if cid and want[cid] and disp and disp > 0 then found = disp break end
    end
    if not found and count == 1 and only and only > 0 then found = only end
    if found then break end
  end
  ejCache[rec.en] = found or false
  return found
end

-- The hidden model lookup: one creature at a time, outside instances and combat only (inside, a
-- hidden model load can stall the loading screen). The result is kept for good.
local lookQ, lookTried, lookBusy, lookModel = {}, {}, false, nil
local RefreshSoon
local LookNext
local function LookDone(npc, did)
  lookBusy = false
  if did then DisplayDB()[npc] = did; if RefreshSoon then RefreshSoon() end end
  if C_Timer and C_Timer.After then C_Timer.After(0.5, LookNext) end
end
local function LookModel()
  if lookModel ~= nil then return lookModel or nil end
  local ok, m = pcall(CreateFrame, "PlayerModel", nil, UIParent)
  if not (ok and m and m.SetCreature and m.GetDisplayInfo) then lookModel = false return nil end
  lookModel = m
  m:SetSize(1, 1)
  m:SetAlpha(0)
  m:SetPoint("TOPLEFT", UIParent, "TOPRIGHT", 10000, 0)
  m:Show()
  return m
end
LookNext = function()
  if lookBusy or #lookQ == 0 then return end
  if CurrentInstance() or InCombat() or not (C_Timer and C_Timer.After) then return end
  if not LookModel() then lookQ = {} return end
  local npc = table.remove(lookQ, 1)
  if DisplayDB()[npc] then return LookNext() end
  lookBusy = true
  if lookModel.ClearModel then pcall(lookModel.ClearModel, lookModel) end
  pcall(lookModel.SetCreature, lookModel, npc)
  local tries = 0
  local function poll()
    tries = tries + 1
    local ok, did = pcall(lookModel.GetDisplayInfo, lookModel)
    did = ok and num(did) or nil
    if did and did > 0 then LookDone(npc, did)
    elseif tries >= 10 or CurrentInstance() then LookDone(npc, nil)
    else C_Timer.After(0.3, poll) end
  end
  C_Timer.After(0.3, poll)
end
local function QueueLookup(npc)
  npc = num(npc)
  if not npc or lookTried[npc] or DisplayDB()[npc] then return end
  lookTried[npc] = true
  lookQ[#lookQ + 1] = npc
  LookNext()
end
-- The creature stood in front of you (nameplate, target, mouse): it is in the client's cache now,
-- so a lookup that failed before may be tried again; out of combat its display id is read from the
-- unit itself when the client allows it (its model is already loaded).
local learnAt = {}
local function LearnUnit(unit, npc)
  npc = num(npc)
  if not (npc and unit) or num(DisplayDB()[npc]) then return end
  lookTried[npc] = nil
  if InCombat() or lookBusy then return end
  -- one read per creature every 15 s at most (the mouse and the target fire often)
  local now = (GetTime and num(GetTime())) or 0
  if learnAt[npc] and now >= learnAt[npc] and now - learnAt[npc] < 15 then return end
  learnAt[npc] = now
  local m = LookModel()
  if not (m and m.SetUnit) then return end
  if not pcall(m.SetUnit, m, unit) then return end
  local ok, did = pcall(m.GetDisplayInfo, m)
  did = ok and num(did) or nil
  if m.ClearModel then pcall(m.ClearModel, m) end
  if did and did > 0 then
    DisplayDB()[npc] = did
    if RefreshSoon then RefreshSoon() end
  end
end

-- The creature's display id: the dungeon journal's model, one learned before, the encounter journal;
-- else a lookup is queued (outside) and nil for now.
local function DisplayFor(rec)
  if num(rec.model) then return rec.model end
  local db = DisplayDB()
  for _, id in ipairs(rec.ids or {}) do if num(db[id]) then return db[id] end end
  if rec.id and num(db[rec.id]) then return db[rec.id] end
  local d = EJDisplay(rec)
  if d then return d end
  if not CurrentInstance() and not InCombat() then QueueLookup(rec.id or (rec.ids and rec.ids[1])) end
  return nil
end

-- Creature type from the game's tooltip for that NPC (its second lines: "Level 45 Humanoid").
local typeTip = {}
local function TipType(id)
  if not id or not (C_TooltipInfo and C_TooltipInfo.GetHyperlink) then return nil end
  if typeTip[id] ~= nil then return typeTip[id] or nil end
  local ok, data = pcall(C_TooltipInfo.GetHyperlink, "unit:Creature-0-0-0-0-" .. id .. "-0000000000")
  local found
  if ok and type(data) == "table" and type(data.lines) == "table" then
    for i = 2, math.min(4, #data.lines) do
      local t = data.lines[i] and str(data.lines[i].leftText)
      if t then for word in pairs(TYPE_ICON) do if t:find(word, 1, true) then found = word end end end
    end
  end
  typeTip[id] = found or false
  return found
end
-- The painted icon of the creature's family (learned when you target it, or from its tooltip); a
-- plain head when the family is not known (never a question mark: an unseen rare shows it as a
-- dark silhouette).
local SILHOUETTE = "INV_Misc_Head_Human_01"
local function FamilyIcon(rec)
  local db = DB()
  local ty = db.bossType and db.bossType[rec.en]
  if not (ty and TYPE_ICON[ty]) then ty = TipType(rec.id) end
  return "Interface\\Icons\\" .. ((ty and TYPE_ICON[ty]) or SILHOUETTE)
end

-- Off-screen portraits: one texture per creature, drawn on a stage far right of the screen, moved
-- onto its head once the model had time to load (Forever paints a black square until then). They
-- are prepared ahead (outside for the route's dungeons, on entering for this one), so the grid
-- usually finds them ready.
local MASK = "Interface\\CharacterFrame\\TempPortraitAlphaMask"
local PORTRAIT_WAIT = 3
local stage
local pool = {}   -- [displayId .. ":" .. en] = { tex, ready, owner } or false
local function Stage()
  if stage then return stage end
  stage = CreateFrame("Frame", nil, UIParent)
  stage:SetSize(48, 48)
  stage:SetPoint("TOPLEFT", UIParent, "TOPRIGHT", 10000, 0)
  stage:Show()
  return stage
end
local function PoolGet(did, rec)
  if not SetPortraitTextureFromCreatureDisplayID then return nil end
  local key = did .. ":" .. rec.en
  local e = pool[key]
  if e ~= nil then return e or nil end
  local st = Stage()
  local tex = st:CreateTexture(nil, "ARTWORK")
  tex:SetAllPoints(st)
  local ok = pcall(SetPortraitTextureFromCreatureDisplayID, tex, did)
  if not ok or not tex.SetParent then pool[key] = false; tex:Hide(); return nil end
  tex:SetTexCoord(0, 1, 0, 1)
  e = { tex = tex, key = key }
  pool[key] = e
  local function ready() e.ready = true; if RefreshSoon then RefreshSoon() end end
  if C_Timer and C_Timer.After then C_Timer.After(PORTRAIT_WAIT, ready) else ready() end
  return e
end
local function Release(e)
  if not e then return end
  e.owner = nil
  pcall(e.tex.SetParent, e.tex, Stage())
  e.tex:ClearAllPoints(); e.tex:SetAllPoints(Stage())
  if e.tex.SetDesaturated then e.tex:SetDesaturated(false) end
  e.tex:SetVertexColor(1, 1, 1, 1)
end

-- ---------------------------------------------------------------- the panel
local P               -- the panel
local parentFrame     -- the guide window it sits beside
local pending = {}    -- what waits for the end of combat
local dismissed = {}  -- instance IDs whose panel you closed during this visit
local SIZE, GAP, PAD, COLS = 40, 6, 12, 5
local W = PAD + COLS * SIZE + (COLS - 1) * GAP + PAD   -- 248: fixed, like the reference panels
-- LABEL: a list's block heading (2 above its text, the text, 4 under it: 20 at 14 px)
local HEADER, STATS_Y, RULE_Y, GRID_Y, LABEL = 44, 54, 90, 98, ns.TY.head.size + 6
local ATTACH_H = 20   -- the "dock to the guide" link under the grid

local function Marker(rec)
  local db = DB()
  db.bossMarks = db.bossMarks or {}
  return db.bossMarks[rec.en] or (rec.rare and MARK_DEFAULT_RARE or MARK_DEFAULT_BOSS)
end

-- /targetexact: the exact name only, and the current target stays when nobody matches (a misclick
-- in combat never leaves you without a target); a dead target with that name is dropped first.
local function MacroText(name, m)
  return "/cleartarget [dead]\n/targetexact " .. name ..
    "\n" .. ns.MarkLine(m)
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

-- the portrait's tooltip: name; boss number or rank, level; quests; state; the click line
local function HeadTip(head)
  local rec = head.rec
  if not rec then return end
  local lines = { rec.name or rec.en }
  -- "Boss 3 of 7 · level 45": the number in the same words as the guide's tracker
  local nb = (P and P.res and P.res.bosses) and #P.res.bosses or 0
  local sub = (not rec.rare and head.n) and ((nb >= head.n) and L.TR_BOSS_N:format(head.n, nb) or L.BOSS_N:format(head.n)) or RankWord(rec)
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
  if rec.killed then
    local k = Kills()
    local t = KillTime(k, rec)
    local text = (t and k.start and t >= k.start) and L.BOSS_KILLED_AT:format(FmtClock(t - k.start)) or L.BOSS_KILLED
    lines[#lines + 1] = { text, T.ok[1], T.ok[2], T.ok[3] }
  elseif rec.rare and not rec.seen then lines[#lines + 1] = L.BOSS_UNSEEN
  elseif rec.rare then lines[#lines + 1] = { L.BOSS_SEEN, T.silver[1], T.silver[2], T.silver[3] } end
  if head.stale then lines[#lines + 1] = { L.BOSS_WAIT, T.warn[1], T.warn[2], T.warn[3] } end
  lines[#lines + 1] = L.BOSS_TT_CLICKM:format(MarkName(Marker(rec)))
  if ns.BossCanToggle and ns.BossCanToggle() then lines[#lines + 1] = L.BOSS_TT_RCLICK end
  ns.ShowTip(head, lines)
end

-- a round texture of the portrait mask, tinted (the dark disc, the veil, the hover light)
local function Disc(parent, layer, r, g, b, a, sub)
  local t = parent:CreateTexture(nil, layer, nil, sub or 0)
  t:SetTexture(MASK)
  t:SetVertexColor(r, g, b, a)
  return t
end

-- the one face shown: the pooled portrait, the live unit portrait or the painted icon
local function RoundFace(b, tex)
  if not tex or tex == b.fb then return end
  -- the game's portraits carry a grey rim, a bit off centre: crop it (each time: drawing a
  -- portrait resets the coordinates) and cut the face round (once)
  pcall(tex.SetTexCoord, tex, 0.07, 0.93, 0.07, 0.93)
  if tex.wlRound then return end
  tex.wlRound = true
  if b.face.CreateMaskTexture and tex.AddMaskTexture then
    local m = b.face:CreateMaskTexture()
    m:SetTexture(MASK, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    m:SetPoint("TOPLEFT", b.face, "TOPLEFT", 1, -1); m:SetPoint("BOTTOMRIGHT", b.face, "BOTTOMRIGHT", -1, 1)
    pcall(tex.AddMaskTexture, tex, m)
  end
end
local function ShowFace(b, cur)
  RoundFace(b, cur)
  b.fb:SetShown(cur == b.fb)
  b.live:SetShown(cur == b.live)
  if b.pooled and b.pooled.tex ~= cur then b.pooled.tex:Hide() end
  if cur then cur:Show() end
  b.cur = cur
end
-- Moves a ready pooled portrait onto the head (a plain texture: allowed in combat). False when the
-- client refuses to move it: that portrait is dropped from the pool (hidden, never left drawing on
-- the stage) and the head draws the display itself.
local function Attach(b, e)
  if b.pooled == e then return true end
  if b.pooled then Release(b.pooled); b.pooled = nil end
  if e.owner and e.owner ~= b then
    local o = e.owner
    o.pooled = nil
    if o.cur == e.tex then o.cur = nil end
  end
  local ok = pcall(e.tex.SetParent, e.tex, b.face)
  if not ok then
    e.tex:Hide()
    e.owner = nil
    if e.key then pool[e.key] = false end
    return false
  end
  e.owner = b
  b.pooled = e
  e.tex:SetDrawLayer("ARTWORK", 1)
  e.tex:ClearAllPoints()
  e.tex:SetPoint("TOPLEFT", b.face, "TOPLEFT", 1, -1)
  e.tex:SetPoint("BOTTOMRIGHT", b.face, "BOTTOMRIGHT", -1, 1)
  return true
end

-- The display drawn straight on the head's own texture (when the pool cannot serve it).
local function Direct(b, did)
  if not SetPortraitTextureFromCreatureDisplayID then return false end
  if b.directDid ~= did then
    if not pcall(SetPortraitTextureFromCreatureDisplayID, b.live, did) then return false end
    b.directDid = did
  end
  b.liveFor = nil
  ShowFace(b, b.live)
  return true
end

-- the creature's face: the pooled portrait when ready, else the live portrait, else the painted
-- icon (plain textures only: also run in combat)
local function SetPortrait(b, rec)
  local did = DisplayFor(rec)
  b.hasModel = did ~= nil
  local e = did and PoolGet(did, rec)
  if e and e.ready then
    if Attach(b, e) then
      b.liveFor = nil
      ShowFace(b, e.tex)
      return
    end
    e = nil
  end
  if b.pooled then Release(b.pooled); b.pooled = nil end
  if did and not e and pool[did .. ":" .. rec.en] == false and Direct(b, did) then return end
  if b.liveFor == rec.en then ShowFace(b, b.live) return end
  b.liveFor = nil
  ns.SetPainted(b.fb, FamilyIcon(rec))
  ShowFace(b, b.fb)
end

-- One portrait: a secure button (the click targets and marks) holding a plain frame with the looks
-- (its alpha may change in combat; the secure button's own state never does).
local function MakeHead(i)
  local b = CreateFrame("Button", "WLBossTarget" .. i, P, "SecureActionButtonTemplate")
  b:SetSize(SIZE, SIZE)
  b:RegisterForClicks("AnyUp", "AnyDown")   -- as the teleport and action-bar buttons, which work on this client
  b:SetAttribute("type", "macro")
  -- the right button runs no secure action: it marks the boss killed or not (PostClick below)
  b:SetAttribute("type2", "")
  local face = CreateFrame("Frame", nil, b)
  face:SetAllPoints()
  b.face = face
  b.disc = Disc(face, "BACKGROUND", 0.02, 0.02, 0.025, 1); b.disc:SetAllPoints()
  -- the painted icon (family), cropped round by the portrait mask
  b.fb = face:CreateTexture(nil, "ARTWORK")
  b.fb:SetPoint("TOPLEFT", 3, -3); b.fb:SetPoint("BOTTOMRIGHT", -3, 3)
  if face.CreateMaskTexture and b.fb.AddMaskTexture then
    local m = face:CreateMaskTexture()
    m:SetTexture(MASK, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    m:SetAllPoints(b.fb)
    b.fb:AddMaskTexture(m)
    b.mask = m
  end
  -- the unit's live portrait (already round)
  b.live = face:CreateTexture(nil, "ARTWORK")
  b.live:SetPoint("TOPLEFT", 1, -1); b.live:SetPoint("BOTTOMRIGHT", -1, 1)
  b.live:Hide()
  b.veil = Disc(face, "OVERLAY", 0, 0, 0, 0.55, 0); b.veil:SetPoint("TOPLEFT", 1, -1); b.veil:SetPoint("BOTTOMRIGHT", -1, 1); b.veil:Hide()
  b.press = Disc(face, "OVERLAY", 0, 0, 0, 0.35, 1); b.press:SetAllPoints(b.veil); b.press:Hide()
  b.hl = Disc(face, "OVERLAY", 1, 1, 1, 0.10, 1); b.hl:SetAllPoints(b.veil); b.hl:SetAlpha(0)
  if b.hl.SetBlendMode then b.hl:SetBlendMode("ADD") end
  -- the ring around the face (HD ring: its circle is 80/128 of the texture)
  b.ring = ns.Icon(face, "ring", math.floor(SIZE * 128 / 80 + 0.5), "OVERLAY", T.muted)
  b.ring:SetPoint("CENTER")
  -- killed: a small check on a dark disc, bottom right
  b.checkBg = Disc(face, "OVERLAY", 0, 0, 0, 0.85, 2); b.checkBg:SetSize(16, 16); b.checkBg:SetPoint("BOTTOMRIGHT", 1, -1); b.checkBg:Hide()
  b.check = ns.Icon(face, "check", 12, "OVERLAY", T.ok); b.check:SetDrawLayer("OVERLAY", 3)
  b.check:SetPoint("CENTER", b.checkBg, "CENTER", 0, 0); b.check:Hide()
  b:SetScript("OnEnter", function(self) self.hl:SetAlpha(0.18); HeadTip(self) end)
  b:SetScript("OnLeave", function(self) self.hl:SetAlpha(0); self.press:Hide(); ns.HideTip() end)
  b:HookScript("OnMouseDown", function(self) self.press:Show() end)
  b:HookScript("OnMouseUp", function(self) self.press:Hide() end)
  -- after the click: say it when the creature was not found (out of sight, or another name)
  b:HookScript("PostClick", function(self, button, down)
    -- right-click: killed / not killed by hand (plain data and textures: fine in combat too); press
    -- and release both come here, the release toggles
    if button == "RightButton" then
      if down or not self.rec then return end
      local now = GetTime and GetTime() or 0
      if self.lastRight and now - self.lastRight < 0.3 then return end
      self.lastRight = now
      if ns.BossToggleKilled then ns.BossToggleKilled(self.rec) end
      local okM, over = pcall(self.IsMouseOver, self)
      if okM and over == true then HeadTip(self) end
      return
    end
    local want = self.rec and (self.rec.name or self.rec.en)
    if not want or not C_Timer then return end
    -- press and release both come here: one check per click
    local now = GetTime and GetTime() or 0
    if self.lastPost and now - self.lastPost < 0.5 then return end
    self.lastPost = now
    C_Timer.After(0.3, function()
      local ok, cur = pcall(UnitName, "target")
      if ok and type(cur) == "string" and not secret(cur) and cur == want then return end
      ns.Print((L.BOSS_NOTFOUND or "Not found: %s (it must be in sight).") :format(want))
    end)
  end)
  return b
end

-- what may change in combat: colours, the veil, the check, the face's alpha (no secure state)
local function PaintHead(b)
  local rec = b.rec
  if not rec then return end
  local dead = rec.killed == true
  local unseen = (rec.rare and not rec.seen and not dead) and true or false
  local tex = b.cur
  if tex then
    if tex.SetDesaturated then tex:SetDesaturated(dead or unseen) end
    -- an unseen rare: its grey face, or without a face a dark silhouette on the dark disc
    local v = unseen and (tex == b.fb and 0.12 or 0.45) or (dead and 0.75 or 1)
    tex:SetVertexColor(v, v, v, 1)
  end
  b.veil:SetShown(dead)
  b.check:SetShown(dead); b.checkBg:SetShown(dead)
  if rec.rare and not unseen and not dead then b.ring:SetVertexColor(T.silver[1], T.silver[2], T.silver[3], 0.95)
  elseif rec.rare and unseen then b.ring:SetVertexColor(T.silver[1], T.silver[2], T.silver[3], 0.25)
  else b.ring:SetVertexColor(1, 1, 1, 0) end   -- bosses: no ring (it drew a grey crescent)
  local a = unseen and 0.7 or 1
  b.face:SetAlpha(a)
  b.faceAlpha = a
  b.unseen = unseen
end

local function FillHead(b, rec, n)
  b.rec, b.n, b.stale = rec, n, nil
  SetPortrait(b, rec)
  local m = MacroFor(rec)
  if b.macro ~= m then b:SetAttribute("macrotext", m); b.macro = m end
  b:SetAttribute("type", "macro")
  b:SetAttribute("type2", "")
  PaintHead(b)
end

-- The creature is in front of you (nameplate, target, mouse): a head not showing a real portrait yet
-- (no model known, or its portrait still loading) takes the unit's live portrait (its model is
-- loaded: no black square).
local function LiveFace(unit, rec)
  if not (P and P:IsShown() and rec and unit and SetPortraitTexture) then return end
  -- a corpse or a unit out of sight draws a blank white disc: only a living, visible one
  local okV, vis = pcall(UnitIsVisible, unit)
  local okD, dead = pcall(UnitIsDead, unit)
  local function plain(v) return not (issecretvalue and issecretvalue(v)) end
  if (okV and plain(vis) and vis == false) or (okD and plain(dead) and dead == true) then return end
  for _, b in ipairs(P.heads) do
    local real = (b.pooled ~= nil and b.cur == b.pooled.tex) or (b.cur == b.live and b.directDid ~= nil)
    if b:IsShown() and b.rec and b.rec.en == rec.en and not real and b.liveFor ~= rec.en then
      if pcall(SetPortraitTexture, b.live, unit) then
        b.liveFor = rec.en
        b.directDid = nil
        ShowFace(b, b.live)
        PaintHead(b)
      end
    end
  end
end

-- where the panel docks: the guide when it shows, else the tracker
local function Host()
  if parentFrame and parentFrame:IsShown() then return parentFrame end
  local tr = WLHelperTracker and WLHelperTracker.Frame and WLHelperTracker.Frame()
  if tr and tr:IsShown() then return tr end
  return nil
end

-- a frame's box in the panel's units (nil when the client does not know yet)
local function BoxOf(fr)
  local okS, ps = pcall(fr.GetEffectiveScale, fr)
  ps = okS and num(ps)
  local ms = num(P:GetEffectiveScale())
  local l, r, t, b = num(fr:GetLeft()), num(fr:GetRight()), num(fr:GetTop()), num(fr:GetBottom())
  if not (ps and ms and ms > 0 and l and r and t and b) then return nil end
  local k = ps / ms
  return l * k, r * k, t * k, b * k
end

-- the run is going on in this dungeon (the "new run" button shows then)
local function RunLive(dkey)
  local k = InRun()
  return k ~= nil and dkey ~= nil and RunDungeon(k) == dkey
end

-- the money in its largest coin only, like the journal: "12 [gold]", "45 [silver]", "0 [copper]"
local COIN = "|TInterface\\MoneyFrame\\UI-%sIcon:0:0:2:0|t"
local function CoinShort(c)
  c = math.max(0, math.floor(c or 0))
  local g, s = math.floor(c / 10000), math.floor((c % 10000) / 100)
  if g > 0 then return FmtNum(g) .. COIN:format("Gold") end
  if s > 0 then return s .. COIN:format("Silver") end
  return (c % 100) .. COIN:format("Copper")
end
ns.BossCoinShort = CoinShort

-- the three numbers (texts and colours only: safe in combat)
local function UpdateStats()
  if not (P and P:IsShown()) then return end
  local st = ns.BossRunStats(P.dkey, P.res)
  local s = P.stats
  if P.armed then
    for _, c in ipairs(s) do c.label:Hide(); c.value:Hide() end
    if P.noRun then P.noRun:Hide() end
    P.confirm:Show()
    return
  end
  P.confirm:Hide()
  local fg = T.fg
  -- no run here yet (outside, or the last run was elsewhere): one sentence, not three dashes
  if not st then
    for _, c in ipairs(s) do c.label:Hide(); c.value:Hide(); c.value:SetText("") end
    s[3].value.wlFull, s[3].value.wlFullAuto = nil, true
    if P.noRun then P.noRun:Show() end
    return
  end
  if P.noRun then P.noRun:Hide() end
  for i, c in ipairs(s) do
    local on = not (i == 2 and P.capXP)
    c.label:SetShown(on); c.value:SetShown(on)
  end
  local tc = st.done and T.ok or fg
  s[1].value:SetText(FmtClock(st.secs)); s[1].value:SetTextColor(tc[1], tc[2], tc[3])
  s[2].value:SetText(FmtNum(st.xp)); s[2].value:SetTextColor(fg[1], fg[2], fg[3])
  s[3].value:SetText(CoinShort(st.money)); s[3].value:SetTextColor(T.gold[1], T.gold[2], T.gold[3])
  s[3].value.wlFull = (ns.S and ns.S.Money) and ns.S.Money(st.money) or MoneyWords(st.money)
  s[3].value.wlFullAuto = false
end
ns.BossUpdateStats = UpdateStats

-- The run in one line for the panel's tooltip: "12:30 · 950 XP (18 % of a level) · 12 g · 3 of 7
-- bosses" (nil before the run). The share of a level is read from the bar's size now.
local function RunLine()
  if not P then return nil end
  local st = ns.BossRunStats(P.dkey, P.res)
  if not st then return nil end
  local parts = { FmtClock(st.secs) }
  if not AtCap() then
    local _, m = ReadXP()
    local pct = (m and m > 0) and (st.xp * 100 / m) or nil
    -- "environ 1,0 niveaux" read wrong: whole levels only from 1.95, below that the share of one
    if pct and pct >= 195 then
      local lv = ("%.1f"):format(pct / 100)
      if ns.lang == "fr" then lv = lv:gsub("%.", ",") end
      parts[#parts + 1] = L.RUN_XP_LVN:format(FmtNum(st.xp), lv)
    elseif pct and pct >= 1 then parts[#parts + 1] = L.RUN_XP_PCT:format(FmtNum(st.xp), math.floor(pct + 0.5))
    else parts[#parts + 1] = FmtNum(st.xp) .. " XP" end
  end
  parts[#parts + 1] = (ns.S and ns.S.Money) and ns.S.Money(st.money) or MoneyWords(st.money)
  if st.total > 0 then parts[#parts + 1] = ns.Plural(st.total, "RUN_KILLS1", "RUN_KILLS", st.killed, st.total) end
  return L.RUN_TIP_LINE:format(table.concat(parts, " · "))
end
ns.BossRunLine = RunLine

-- the "new run" button: the first click asks (in the panel), the second within 4 s starts over
local function Disarm()
  if not P then return end
  P.armed = nil
  if P.reset and P.reset.SetIcon then P.reset:SetIcon("refresh") end
  UpdateStats()
end
local function ResetClick()
  if P.armed then
    P.armed = nil
    if P.reset.SetIcon then P.reset:SetIcon("refresh") end
    if ns.NewBossRun then ns.NewBossRun() end
    UpdateStats()
    return
  end
  local token = {}
  P.armed = token
  if P.reset.SetIcon then P.reset:SetIcon("refresh", T.warn) end
  UpdateStats()
  if C_Timer and C_Timer.After then C_Timer.After(4, function() if P and P.armed == token then Disarm() end end) end
end

-- ---------------------------------------------------------------- the dungeon's map
-- The header's map button opens the best map of the dungeon another addon already has, read live
-- (nothing copied), in this order:
--   OpenMap: standing in the dungeon, its world map opens on the dungeon's own map by itself (it
--     has no public call to open one from outside, so only inside);
--   Naowh Forever's Dungeon Journal: its map window (J.OpenDungeonMap);
--   Forever Dungeon Journal: its map page (FDJ.OpenDungeonMap, once its window is up);
--   else the game's world map, when the client has a map of the place you stand in.
-- In combat nothing opens: the world map opened from addon code in combat can be blocked by the game
-- ("Interface action failed because of an AddOn"), and the journals' windows wait too. The M key still
-- works then (OpenMap answers it). The button is hidden when nothing has a map of this dungeon.
-- Strings: added to Locale.lua's tables from here (both languages), so /wlh lang still switches them.
do
  local LT = ns.LOCALE_TABLES
  local add = {
    fr = {
      BOSS_MAP = "Carte du donjon", BOSS_MAP_CLICK = "Clic : ouvrir la carte du donjon",
      BOSS_MAP_FROM = "Source : %s", BOSS_MAP_WORLD = "la carte du monde du jeu",
      BOSS_MAP_COMBAT = "En combat, seule la carte du monde s'ouvre.",
      BOSS_MAP_LATER = "La carte du donjon s'ouvre hors combat.",
      BOSS_MAP_NONE = "Pas de carte pour ce donjon. OpenMap ou un journal de donjon en donne une.",
      BOSS_MAP_NOWHERE = "Entre dans un donjon, ou ouvre son panneau de boss, pour voir sa carte.",
    },
    en = {
      BOSS_MAP = "Dungeon map", BOSS_MAP_CLICK = "Click: open the dungeon's map",
      BOSS_MAP_FROM = "From: %s", BOSS_MAP_WORLD = "the game's world map",
      BOSS_MAP_COMBAT = "In combat, only the world map opens.",
      BOSS_MAP_LATER = "The dungeon map opens out of combat.",
      BOSS_MAP_NONE = "No map for this dungeon. OpenMap or a dungeon journal provides one.",
      BOSS_MAP_NOWHERE = "Enter a dungeon, or open its boss panel, to see its map.",
    },
  }
  for lang, t in pairs(add) do
    local into = type(LT) == "table" and LT[lang]
    if type(into) == "table" then for k, v in pairs(t) do if into[k] == nil then into[k] = v end end end
  end
end

-- (in one block: the file's main chunk is near Lua's 200 locals; only these two leave it)
local MapIcon, MapTip
do
  -- "The Hall of Thanes" / "HallofThanes" / "Dire Maul: East" -> "hallofthanes" / "diremauleast"
  local function Simple(s) return (tostring(s or ""):lower():gsub("^the ", ""):gsub("[^%w]", "")) end
  -- 2: the same name, 1: one starts like the other (a wing of a dungeon mapped whole), 0: no
  local function Likeness(a, b)
    if a == "" or b == "" then return 0 end
    if a == b then return 2 end
    if #a >= 5 and #b >= 5 and (a:find(b, 1, true) == 1 or b:find(a, 1, true) == 1) then return 1 end
    return 0
  end
  local function Wanted(dkey)
    local d = ns.D and ns.D[dkey]
    return { Simple(d and d.n), Simple(dkey) }
  end
  local function Score(wants, ...)
    local best = 0
    for i = 1, select("#", ...) do
      local v = select(i, ...)
      if type(v) == "string" then
        local s = Simple(v)
        for _, w in ipairs(wants) do best = math.max(best, Likeness(w, s)) end
      end
    end
    return best
  end

  local function InsideOf(d) return d ~= nil and d.inst ~= nil and CurrentInstance() == d.inst end

  -- the client's own map of where you stand, when it is a dungeon's (or a part of one)
  local function ClientMapHere()
    if not (C_Map and type(C_Map.GetBestMapForUnit) == "function" and type(C_Map.GetMapInfo) == "function") then return nil end
    local ok, id = pcall(C_Map.GetBestMapForUnit, "player")
    id = ok and num(id) or nil
    if not id then return nil end
    local okI, info = pcall(C_Map.GetMapInfo, id)
    local kind = okI and type(info) == "table" and num(info.mapType) or nil
    local E = Enum and Enum.UIMapType
    if kind and E and (kind == E.Dungeon or kind == E.Micro) then return id end
    return nil
  end

  local function OpenMapOn(d)
    local OM = rawget(_G, "OpenMap")
    if type(OM) ~= "table" or not InsideOf(d) then return false end
    if type(OM.GetModule) == "function" then
      local ok, mod = pcall(OM.GetModule, OM, "worldmap")
      if ok and type(mod) == "table" then
        if mod.enabled == false then return false end
        if type(mod.db) == "table" and mod.db.dungeonMaps == false then return false end   -- its option "Dungeon maps"
      end
    end
    -- Blizzard's map, one drawn for Forever's own dungeons (by instance, or by name when the game's
    -- tables have no instance ID for it yet), or one built from the minimap pictures
    for _, k in ipairs({ "MapDungeonMaps", "MapDungeonDrawn", "MapDungeonMinimap" }) do
      local maps = rawget(OM, k)
      if type(maps) == "table" and maps[d.inst] ~= nil then return true end
    end
    local drawn = rawget(OM, "MapDungeonDrawn")
    if type(drawn) == "table" and type(GetInstanceInfo) == "function" then
      local okN, name = pcall(GetInstanceInfo)
      if okN and type(name) == "string" and not (issecretvalue and issecretvalue(name)) and drawn[name] ~= nil then return true end
    end
    return ClientMapHere() ~= nil
  end

  local function NaowhMap(dkey)
    local N = rawget(_G, "NaowhForever")
    local J = type(N) == "table" and N.Journal
    if not (type(J) == "table" and type(J.OpenDungeonMap) == "function" and type(J.Dungeons) == "function"
      and type(J.Maps) == "table") then return nil end
    local ok, list = pcall(J.Dungeons)
    if not ok or type(list) ~= "table" then return nil end
    local wants = Wanted(dkey)
    local best, bestScore = nil, 0
    for _, dg in ipairs(list) do
      if type(dg) == "table" and dg.key and J.Maps[dg.key] then
        local s = Score(wants, dg.english, dg.name, dg.key)
        if s > bestScore then best, bestScore = dg, s end
        if s == 2 then break end
      end
    end
    return best and { J = J, dg = best } or nil
  end

  local function FDJMap(dkey)
    local FDJ = rawget(_G, "ForeverDungeonJournal_NS")
    if not (type(FDJ) == "table" and type(FDJ.OpenDungeonMap) == "function" and type(FDJ.DUNGEON_MAPS) == "table") then return nil end
    local wants = Wanted(dkey)
    local names = {}
    for name in pairs(FDJ.DUNGEON_MAPS) do if type(name) == "string" then names[#names + 1] = name end end
    table.sort(names)   -- the same pick every time when two only start alike
    local best, bestScore = nil, 0
    for _, name in ipairs(names) do
      -- (its map opens only for a dungeon its journal has)
      if not (type(FDJ.DB) == "table" and FDJ.DB[name] == nil) then
        local s = Score(wants, name)
        if s > bestScore then best, bestScore = name, s end
        if s == 2 then break end
      end
    end
    if not best then return nil end
    -- its role-play mode can keep a map locked until it is earned: then it has none for us either
    if type(FDJ.IsDungeonMapLocked) == "function" then
      local okL, locked = pcall(FDJ.IsDungeonMapLocked, best)
      if okL and locked then return nil end
    end
    return { FDJ = FDJ, name = best }
  end

  local function WorldMapShown() return WorldMapFrame ~= nil and WorldMapFrame:IsShown() == true end
  -- the world map, on `mapID` when given; a second click closes it (as the map key does)
  local function OpenWorld(mapID)
    if WorldMapShown() then
      local cur = WorldMapFrame.GetMapID and WorldMapFrame:GetMapID()
      if mapID and cur ~= mapID and WorldMapFrame.SetMapID then return (pcall(WorldMapFrame.SetMapID, WorldMapFrame, mapID)) end
      if type(ToggleWorldMap) == "function" then return (pcall(ToggleWorldMap)) end
      return (pcall(HideUIPanel or WorldMapFrame.Hide, WorldMapFrame))
    end
    if mapID and type(OpenWorldMap) == "function" and pcall(OpenWorldMap, mapID) then return true end
    if type(ToggleWorldMap) == "function" then return (pcall(ToggleWorldMap)) end
    if WorldMapFrame then return (pcall(ShowUIPanel or WorldMapFrame.Show, WorldMapFrame)) end
    return false
  end

  -- The sources for a dungeon, best first: { kind, label, combat (opens in combat), open = fn }
  local function MapSources(dkey)
    local out = {}
    local d = ns.D and ns.D[dkey]
    if not d then return out end
    if OpenMapOn(d) then
      out[#out + 1] = { kind = "openmap", label = "OpenMap", combat = false, open = function() return OpenWorld(nil) end }
    end
    local nm = NaowhMap(dkey)
    if nm then
      out[#out + 1] = { kind = "naowh", label = "Naowh Forever", open = function()
        return (pcall(nm.J.OpenDungeonMap, nm.dg))
      end }
    end
    local fm = FDJMap(dkey)
    if fm then
      out[#out + 1] = { kind = "fdj", label = "Forever Dungeon Journal", open = function()
        -- its map page lives in its window: up first, then the dungeon's map in it
        local frame, toggle = rawget(_G, "ForeverDungeonJournalFrame"), rawget(_G, "ForeverDungeonJournal_Toggle")
        if not (frame and frame.IsShown and frame:IsShown()) and type(toggle) == "function" then pcall(toggle) end
        return (pcall(fm.FDJ.OpenDungeonMap, fm.name))
      end }
    end
    local here = InsideOf(d) and ClientMapHere()
    if here then
      out[#out + 1] = { kind = "world", label = L.BOSS_MAP_WORLD, combat = false, open = function() return OpenWorld(here) end }
    end
    return out
  end

  -- The source the button would use now (in combat: the first that opens in combat), or nil.
  local function MapSource(dkey, inCombat)
    for _, src in ipairs(MapSources(dkey)) do
      if not inCombat or src.combat then return src end
    end
    return nil
  end
  ns.DungeonMapSources = MapSources

  -- Has this dungeon a map anywhere? -> kind ("openmap", "naowh", "fdj", "world"), label; or nil
  function ns.DungeonMapSource(dkey)
    dkey = dkey or (P and P.dkey)
    local src = dkey and MapSource(dkey, false)
    if src then return src.kind, src.label end
    return nil
  end

  -- Opens the best map of the dungeon (dkey: the panel's dungeon when nil). Returns the source's kind
  -- when a map opened, nil (with one chat line saying why) when none could.
  function ns.OpenDungeonMap(dkey)
    dkey = dkey or (P and P.dkey)
    -- (/wlh carte outside a dungeon, no boss panel opened yet: one line rather than silence)
    if not dkey then
      if ns.Print then ns.Print(L.BOSS_MAP_NOWHERE) end
      return nil
    end
    local fight = InCombat()
    local list = MapSources(dkey)
    for _, src in ipairs(list) do
      if (not fight or src.combat) and src.open() then return src.kind end
    end
    if ns.Print then ns.Print((fight and #list > 0) and L.BOSS_MAP_LATER or L.BOSS_MAP_NONE) end
    return nil
  end

  -- the button's icon: the HD "map" glyph once Media/Icons has it, else the game's painted map
  function MapIcon()
    if ns.HD_NAMES and ns.HD_NAMES.map then return "map" end
    return "Interface\\Icons\\INV_Misc_Map_01"
  end

  function MapTip()
    local dkey = P and P.dkey
    local src = dkey and MapSource(dkey, false)
    local lines = { L.BOSS_MAP }
    if src then lines[#lines + 1] = L.BOSS_MAP_FROM:format(src.label) end
    if InCombat() and src and not src.combat then
      local alt = MapSource(dkey, true)
      lines[#lines + 1] = { alt and L.BOSS_MAP_COMBAT or L.BOSS_MAP_LATER, T.warn[1], T.warn[2], T.warn[3] }
    end
    lines[#lines + 1] = { L.BOSS_MAP_CLICK, T.hint[1], T.hint[2], T.hint[3] }
    return lines
  end
end

local function Build()
  if P then return P end
  if InCombat() then return nil end
  P = CreateFrame("Frame", "WLBossPanel", UIParent)
  P:SetSize(W, 160)
  P:SetFrameStrata("MEDIUM")
  P:SetClampedToScreen(true)
  P:SetMovable(true)
  P:EnableMouse(true)
  P:Hide()
  if ns.RegisterWindow then ns.RegisterWindow(P) end
  local bg = ns.Tex(P, "BACKGROUND", T.bg); bg:SetAllPoints()
  ns.Outline(P, T.cardEdge)
  -- drag anywhere off the portraits: the panel leaves the guide and stays where you drop it
  P:RegisterForDrag("LeftButton")
  P:SetScript("OnDragStart", function() if not InCombat() then P.wlMoving = true; P:StartMoving() end end)
  P:SetScript("OnDragStop", function()
    if not P.wlMoving then return end
    P.wlMoving = nil
    if not InCombat() then P:StopMovingOrSizing() end
    P.SavePos()
  end)
  -- the tooltip: the dungeon, what the panel is, the run in one line, how it is counted, the drag
  P:SetScript("OnEnter", function(self)
    local lines = { P.dkey and ns.DName(P.dkey) or L.BOSS_TITLE }
    if P.dkey then lines[#lines + 1] = L.BOSS_TITLE end
    local run = RunLine()
    if run then lines[#lines + 1] = { run, T.fg[1], T.fg[2], T.fg[3] } end
    lines[#lines + 1] = { L.RUN_STATS_TIP, T.muted[1], T.muted[2], T.muted[3] }
    lines[#lines + 1] = P.attached and L.BOSS_DRAG or L.BOSS_DRAG2
    ns.ShowTip(self, lines)
  end)
  P:SetScript("OnLeave", ns.HideTip)
  local S = ns.S
  -- header (44, like the guide's: the tops line up when docked): the dungeon's name, "Bosses and
  -- rares" under it so the panel says what it is, then map / new run / close on the right.
  -- No decorative icon (an invisible 1 px anchor keeps the title's place code).
  P.icon = P:CreateTexture(nil, "ARTWORK"); P.icon:SetSize(1, 16); P.icon:SetAlpha(0)
  P.icon:SetPoint("TOPLEFT", PAD - 6, -6)
  P.title = ns.Text(P, ns.F.heading, T.fg, true)
  P.title:SetPoint("LEFT", P.icon, "RIGHT", 6, 0)
  P.title:SetWordWrap(false)
  ns.ClampLabel(P.title, nil, P)
  P.sub = ns.Text(P, ns.F.meta, T.muted, false)
  P.sub:SetPoint("TOPLEFT", P.title, "BOTTOMLEFT", 0, -2)
  P.sub:SetWordWrap(false)
  P.sub:SetText(L.BOSS_TITLE)
  P.hrule = ns.Rule(P, T.line)
  P.hrule:SetPoint("TOPLEFT", P, "TOPLEFT", 0, -HEADER); P.hrule:SetPoint("TOPRIGHT", P, "TOPRIGHT", 0, -HEADER)
  P.close = S.CloseButton(P, 24, function() ns.HideBosses(true) end, { L.BOSS_TITLE, L.BOSS_CLOSE_CLICK })
  P.close:SetPoint("TOPRIGHT", -4, -10)
  -- back beside the guide after a move: a text link under the grid (T-22: the pin means GPS only)
  P.attach = S.Button(P, L.BOSS_ATTACH, 0, ATTACH_H, "ghost", function()
    if InCombat() then return end
    DB().bossDetached = false   -- docked to the guide on purpose (nil means "free, the default")
    ns.RefreshBosses()
  end, { L.BOSS_ATTACH, L.BOSS_ATTACH_TT, L.BOSS_ATTACH_CLICK })
  P.attach:Hide()
  P.reset = S.IconButton(P, "refresh", 24, function()
    if P.armed then return { L.RUN_RESET, { L.RUN_RESET_CONFIRM, T.warn[1], T.warn[2], T.warn[3] } } end
    return { L.RUN_RESET, L.RUN_RESET_TIP, { L.RUN_RESET_CLICK, T.hint[1], T.hint[2], T.hint[3] } }
  end, ResetClick)
  -- the dungeon's map (shown only when some addon or the game has one of it)
  P.map = S.IconButton(P, MapIcon(), 24, MapTip, function() ns.OpenDungeonMap(P.dkey) end)
  if not P.map.hd and P.map.icon.SetTexCoord then P.map.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) end
  P.map:Hide()
  -- the run's numbers: small label over the value, three columns (two at the level cap)
  P.stats = {}
  for i, key in ipairs({ "RUN_TIME", "RUN_XP", "RUN_GOLD" }) do
    local c = {}
    c.label = ns.Text(P, ns.F.meta, T.muted, false)
    c.label:SetWordWrap(false)
    c.label:SetText(L[key])
    -- the money in a smaller size (coin icons are wide); cut, the panel's tooltip gives it whole
    c.value = ns.Text(P, i == 3 and ns.F.label or ns.F.heading, T.fg, true)
    c.value:SetWordWrap(false)
    if i == 3 then ns.ClampLabel(c.value, nil, P) end
    P.stats[i] = c
  end
  -- before the run: what the numbers will be, in one sentence (2 lines at most)
  P.noRun = ns.Text(P, ns.F.meta, T.muted, false)
  P.noRun:SetJustifyH("LEFT")
  P.noRun:SetPoint("TOPLEFT", P, "TOPLEFT", PAD, -(STATS_Y + 2))
  P.noRun:SetText(L.RUN_NONE)
  ns.FitText(P.noRun, 2, W - 2 * PAD, P)
  P.noRun:Hide()
  P.confirm = ns.Text(P, ns.F.label, T.warn, false)
  P.confirm:SetPoint("TOPLEFT", P, "TOPLEFT", PAD, -(STATS_Y + 6))
  P.confirm:SetWidth(W - 2 * PAD)
  P.confirm:SetText(L.RUN_RESET_CONFIRM)
  P.confirm:Hide()
  P.rule = ns.Rule(P, T.divider)
  P.rule:SetPoint("TOPLEFT", P, "TOPLEFT", PAD, -RULE_Y)
  P.rule:SetPoint("TOPRIGHT", P, "TOPRIGHT", -PAD, -RULE_Y)
  -- the rares' label: a block heading (design system 3.21: 14, the heading colour). The bosses
  -- above it have none, like the game's dungeon journal (the portraits say what they are)
  P.secRare = ns.Text(P, ns.TY.head.size, T.head, true)
  ns.ClampLabel(P.secRare, nil, P)
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
  -- docked: follow the guide (or the tracker) when it moves, out of combat; the time ticks each second
  local acc, tick = 0, 0
  P:SetScript("OnUpdate", function(_, el)
    el = num(el) or 0
    tick = tick + el
    if tick >= 1 then tick = 0; UpdateStats() end
    acc = acc + el
    if acc < 0.2 or InCombat() or not P.attached then return end
    acc = 0
    local h = Host()
    if not h then return end
    local l, _, t, b = BoxOf(h)
    if h ~= P.host or l ~= P.lastL or t ~= P.lastT or b ~= P.lastB then ns.SnapBosses() end
  end)
  return P
end

-- Puts the panel 4 px right of its host, tops aligned (left of it when the screen has no room).
-- Absolute position: no anchor to the guide, so the guide never becomes a protected frame.
function ns.SnapBosses()
  if not P then return end
  -- by default the panel lives on the right of the screen (like the Mythic+ timer), not on the guide
  if DB().bossDetached == nil then DB().bossDetached = true end
  if InCombat() then pending.snap = true return end
  local h = P.attached and Host()
  if h then
    local l, r, t, b = BoxOf(h)
    if l then
      local okW, sw = pcall(UIParent.GetWidth, UIParent)
      sw = okW and num(sw) or 1920
      local x = r + 4
      if x + W > sw then x = l - 4 - W end
      P:ClearAllPoints()
      P:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, t)
      P.host, P.lastL, P.lastT, P.lastB = h, l, t, b
      return
    end
  end
  local pos = DB().bossPos
  P:ClearAllPoints()
  if pos and pos[1] then P:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", pos[1], pos[2])
  else P:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -40, -260) end   -- under the minimap, right side
end

-- the panel's height for nb bosses and nr rares (`cols` per row, 5 by default)
local function GridHeight(nb, nr, cols)
  cols = cols or COLS
  local h = GRID_Y
  local function rows(n) return math.ceil(n / cols) * (SIZE + GAP) - GAP end
  if nb > 0 then h = h + rows(nb) end
  if nr > 0 then h = h + (nb > 0 and ns.TY.head.top - 2 or 0) + LABEL + rows(nr) end
  return h + PAD
end
ns.BossGridHeight = GridHeight

local function RenderNow()
  pending.render = nil
  local dkey = P.dkey
  local db = DB()
  local host = Host()
  if db.bossDetached == nil then db.bossDetached = true end   -- free (top right) unless pinned to the guide
  P.attached = (host ~= nil and not db.bossDetached) and true or false
  local res = dkey and ns.DungeonMobs(dkey) or { bosses = {}, rares = {} }
  P.res = res
  -- the death checks read the bosses shown now
  if ns.BossWatchReset then ns.BossWatchReset() end
  local nb, nr = #res.bosses, #res.rares
  P.cols = COLS
  -- header: name and "Bosses and rares" under it, then from the right close, new run (during the
  -- run), map; the dock link (moved away from the guide) goes under the grid
  P.title:SetText(dkey and ns.DName(dkey) or L.BOSS_TITLE)
  P.sub:SetShown(dkey ~= nil)
  local showAttach = host ~= nil and db.bossDetached == true
  local live = RunLive(dkey)
  if not live and P.armed then P.armed = nil; if P.reset.SetIcon then P.reset:SetIcon("refresh") end end
  P.attach:SetShown(showAttach)
  P.reset:SetShown(live)
  -- (a source that fails to be read just hides the button: the panel draws anyway)
  local okMap, mapKind = pcall(ns.DungeonMapSource, dkey)
  local showMap = dkey ~= nil and okMap and mapKind ~= nil
  P.map:SetShown(showMap)
  local prev, right = P.close, 4 + 24
  for _, btn in ipairs({ live and P.reset or false, showMap and P.map or false }) do
    if btn then
      btn:ClearAllPoints(); btn:SetPoint("RIGHT", prev, "LEFT", -2, 0)
      prev, right = btn, right + 2 + 24
    end
  end
  P.title:SetWidth(math.max(40, W - (PAD + 16 + 6) - right - 4))
  P.sub:SetWidth(math.max(40, W - (PAD + 16 + 6) - right - 4))
  -- the numbers: three columns, or two at the level cap (no XP)
  P.capXP = AtCap()
  local cols = P.capXP and 2 or 3
  local colW = (W - 2 * PAD) / cols
  local at = 0
  for i, c in ipairs(P.stats) do
    if not (i == 2 and P.capXP) then
      local x = PAD + at * colW
      c.label:ClearAllPoints(); c.label:SetPoint("TOPLEFT", P, "TOPLEFT", x, -STATS_Y); c.label:SetWidth(colW - 4)
      c.value:ClearAllPoints(); c.value:SetPoint("TOPLEFT", P, "TOPLEFT", x, -(STATS_Y + (i == 3 and 16 or 14))); c.value:SetWidth(colW - 4)
      at = at + 1
    end
  end
  UpdateStats()
  -- the grid: row by row, five per row, in the dungeon's order; the rares under their label
  local used = 0
  local y = GRID_Y
  local function place(list, numbered)
    for i, rec in ipairs(list) do
      used = used + 1
      local b = P.heads[used]
      if not b then b = MakeHead(used); P.heads[used] = b end
      local c, r = (i - 1) % COLS, math.floor((i - 1) / COLS)
      b.col, b.row = c, r
      b:ClearAllPoints()
      b:SetPoint("TOPLEFT", P, "TOPLEFT", PAD + c * (SIZE + GAP), -(y + r * (SIZE + GAP)))
      FillHead(b, rec, numbered and i or nil)
      b:Show()
    end
    y = y + math.ceil(#list / COLS) * (SIZE + GAP) - GAP
  end
  if nb + nr == 0 then
    P.secRare:Hide()
    local text = L.BOSS_EMPTY_NONE
    if res.loading then text = L.BOSS_LOADING elseif res.noLib then text = L.BOSS_EMPTY_NOLIB end
    P.empty:SetText(text)
    P.empty:ClearAllPoints(); P.empty:SetPoint("TOPLEFT", P, "TOPLEFT", PAD, -y)
    local eh = ns.FitText(P.empty, 4, W - 2 * PAD, P)
    P.empty:Show()
    y = y + math.ceil(num(eh) or 28)
  else
    P.empty:Hide()
    if nb > 0 then place(res.bosses, true) end
    if nr > 0 then
      if nb > 0 then y = y + ns.TY.head.top - 2 end   -- 14 above the heading (it sits 2 lower)
      P.secRare:SetText(L.BOSS_RARES)
      P.secRare:ClearAllPoints(); P.secRare:SetPoint("TOPLEFT", P, "TOPLEFT", PAD, -(y + 2))
      P.secRare:SetWidth(W - 2 * PAD); P.secRare:Show()
      y = y + LABEL
      place(res.rares, false)
    else P.secRare:Hide() end
  end
  for i = used + 1, #P.heads do
    local b = P.heads[i]
    b:Hide(); b.rec = nil
    if b.pooled then Release(b.pooled); b.pooled = nil end
    b.liveFor = nil
  end
  if showAttach then
    -- the ghost label sits 12 px inside its button: the text lines up with the portraits
    y = y + 8
    P.attach:ClearAllPoints(); P.attach:SetPoint("TOPLEFT", P, "TOPLEFT", PAD - 12, -y)
    y = y + ATTACH_H
  end
  P:SetWidth(W)
  P:SetHeight(math.ceil(y + PAD))
  ns.SnapBosses()
end

local function Render()
  if not P then return end
  if P.rendering then P.again = true return end
  if InCombat() then
    pending.render = true
    -- what can change now: killed and seen, and the numbers
    if P.dkey and P:IsShown() then
      local res = ns.DungeonMobs(P.dkey)
      local by = {}
      for _, r in ipairs(res.bosses) do by[r.en] = r end
      for _, r in ipairs(res.rares) do by[r.en] = r end
      for _, b in ipairs(P.heads) do
        local r = b.rec and by[b.rec.en]
        if r then
          b.rec.killed, b.rec.seen = r.killed, r.seen; b.stale = true
          -- a portrait ready now goes on (plain textures: allowed in combat)
          pcall(SetPortrait, b, b.rec)
          PaintHead(b)
        end
      end
      UpdateStats()
    end
    return
  end
  P.rendering = true
  local ok, err = pcall(RenderNow)
  P.rendering = nil
  if P.again then P.again = nil; if ok and P:IsShown() then Render() end end
  if not ok then error(err, 0) end
end
ns.RenderBosses = Render

-- a portrait or a looked-up face is ready: one redraw a moment later
local refreshQueued = false
RefreshSoon = function()
  if refreshQueued then return end
  refreshQueued = true
  local function go()
    refreshQueued = false
    -- (in combat: the faces now, the rest after combat)
    if P and P:IsShown() then Render() end
  end
  if C_Timer and C_Timer.After then C_Timer.After(0.05, go) else go() end
end

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

-- Opens the panel on a dungeon (from the guide, the overview, /wlh boss or on entering it).
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

-- /wlh boss: the dungeon you are in, else the guide's, else the one shown last.
function ns.BossCommand()
  local dkey = DungeonHere() or ns.instIn
  if not dkey and ns.route and ns.route.sel then
    for _, k in ipairs(ns.ORDER or {}) do if ns.route.sel[k] then dkey = k break end end
  end
  dkey = dkey or (P and P.dkey)
  if not dkey then if ns.Print then ns.Print(L.BOSS_MENU_NONE) end return end
  ns.ToggleBosses(dkey)
end

-- The guide window the panel sits beside (UI.lua calls it once the guide is built). Hiding the
-- guide moves the panel beside the tracker (or to its saved place).
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

-- ---------------------------------------------------------------- portraits for other windows
-- ns.NpcPortrait(tex, name, npcId, kind): the face of the NPC or mob called `name` on a texture
-- (the guide's "Target and items" buttons). Its portrait when its display id is known (once the
-- model had time to load: until then, and with no display id, the plain head); the unit's own live
-- portrait once it is targeted, under the mouse or its nameplate shows. kind "object" (a chest,
-- an herb, an urn): the neutral object icon. Without a name the texture is let go. Textures only:
-- fine in combat.
do
  local PORTRAIT_HEAD = "Interface\\Icons\\" .. SILHOUETTE
  local PORTRAIT_OBJECT = "Interface\\Icons\\INV_Box_01"
  local wanted = setmetatable({}, { __mode = "k" })   -- [texture] = { name, id, did }
  local nameIds = {}                                   -- name -> NPC id, from the units seen
  local warm = {}                                      -- [displayId] = "loading" | "ready" | false
  local function Plain(tex, path)
    tex:SetTexture(path); tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  end
  local function WarmApply(did)
    for tex, w in pairs(wanted) do
      if w.did == did and not w.live then
        if pcall(SetPortraitTextureFromCreatureDisplayID, tex, did) then tex:SetTexCoord(0.12, 0.88, 0.12, 0.88) end
      end
    end
  end
  -- the portrait is first drawn off-screen (Forever paints a black square until the model is loaded)
  local function Warm(did)
    if warm[did] ~= nil then return warm[did] == "ready" end
    if not (SetPortraitTextureFromCreatureDisplayID and C_Timer and C_Timer.After) then warm[did] = false return false end
    local tex = Stage():CreateTexture(nil, "ARTWORK")
    tex:SetAllPoints(Stage())
    if not pcall(SetPortraitTextureFromCreatureDisplayID, tex, did) then warm[did] = false; tex:Hide() return false end
    warm[did] = "loading"
    C_Timer.After(PORTRAIT_WAIT, function() warm[did] = "ready"; tex:Hide(); WarmApply(did) end)
    return warm[did] == "ready"
  end

  function ns.NpcPortrait(tex, name, npcId, kind)
    if not tex then return end
    name = str(name)
    if not name then wanted[tex] = nil return end
    if kind == "object" then wanted[tex] = nil; Plain(tex, PORTRAIT_OBJECT) return end
    local id = num(npcId) or nameIds[name]
    local w = wanted[tex]
    -- the live portrait already on it stays while it shows the same creature
    if w and w.live and w.name == name then return end
    local did = id and DisplayFor({ en = name, name = name, id = id, ids = { id } }) or nil
    wanted[tex] = { name = name, id = id, did = did }
    if did and Warm(did) and pcall(SetPortraitTextureFromCreatureDisplayID, tex, did) then
      tex:SetTexCoord(0.12, 0.88, 0.12, 0.88)
    else
      Plain(tex, PORTRAIT_HEAD)
    end
  end

  -- a unit shows (target, mouse, nameplate): the textures waiting for that creature take its face
  local function PortraitUnit(unit)
    if not (unit and next(wanted) and SetPortraitTexture) then return end
    local id = NpcIdOf(unit)
    local okN, nm = pcall(UnitName, unit)
    nm = okN and str(nm) or nil
    if not (id or nm) then return end
    if id and nm then nameIds[nm] = id end
    local okV, vis = pcall(UnitIsVisible, unit)
    local okD, dead = pcall(UnitIsDead, unit)
    if (okV and not secret(vis) and vis == false) or (okD and not secret(dead) and dead == true) then return end
    local hit = false
    for tex, w in pairs(wanted) do
      if not w.live and ((id and w.id == id) or (nm and w.name == nm)) then
        if pcall(SetPortraitTexture, tex, unit) then
          tex:SetTexCoord(0.12, 0.88, 0.12, 0.88)
          w.live, w.id = true, w.id or id
          hit = true
        end
      end
    end
    if hit and id then LearnUnit(unit, id) end
  end
  ns.NpcPortraitUnit = PortraitUnit

  -- What a guide target is: ("npc", id) or ("object", id), from the dungeon's bosses and rares, then
  -- the quest's own start, end and objectives in LibForeverData (read live); nil when not known.
  local entCache = {}
  function ns.TargetEntity(name, qid, dkey)
    name = str(name)
    if not name then return nil end
    local key = name .. "|" .. tostring(qid or "") .. "|" .. tostring(dkey or "")
    local c = entCache[key]
    if c ~= nil then if c then return c[1], c[2] end return nil end
    local kind, id
    local res = dkey and mobsCache[dkey]
    if res then
      for _, list in ipairs({ res.bosses or {}, res.rares or {} }) do
        for _, r in ipairs(list) do
          if (r.en == name or r.name == name) and not kind then kind, id = "npc", r.ids and r.ids[1] end
        end
      end
    end
    local lib = (not kind) and num(qid) and Lib()
    local low = name:lower()
    local function same(k, x)
      local okN, n = pcall(lib.Name, k, x)
      return okN and type(n) == "string" and n:lower() == low
    end
    if lib then
      local okQ, q = pcall(lib.Get, "quest", qid)
      if okQ and type(q) == "table" then
        local cands = {}
        for _, e in ipairs(q.start or {}) do cands[#cands + 1] = e end
        for _, e in ipairs(q.finish or {}) do cands[#cands + 1] = e end
        for _, ob in ipairs(q.objectives or {}) do
          if (ob.kind == "npc" or ob.kind == "object") and ob.target then
            cands[#cands + 1] = { kind = ob.kind, id = ob.target }
          elseif ob.kind == "item" and ob.target then
            local okI, it = pcall(lib.Get, "item", ob.target)
            if okI and type(it) == "table" then
              for _, x in ipairs(it.npcDrops or {}) do cands[#cands + 1] = { kind = "npc", id = x } end
              for _, x in ipairs(it.objectDrops or {}) do cands[#cands + 1] = { kind = "object", id = x } end
            end
          end
        end
        for _, e in ipairs(cands) do
          if (e.kind == "npc" or e.kind == "object") and e.id and same(e.kind, e.id) then kind, id = e.kind, e.id break end
        end
      end
    end
    -- the bosses' list may come later (built a few hundred NPCs per frame): a miss is not kept
    if kind or not dkey or mobsCache[dkey] then entCache[key] = kind and { kind, id } or false end
    return kind, id
  end
end

local function IsRareUnit(unit)
  if not UnitClassification then return false end
  local ok, c = pcall(UnitClassification, unit)
  c = ok and str(c)
  return c == "rare" or c == "rareelite"
end

-- the panel's rare with this NPC id (nil when the panel does not list it)
local function StripRare(id)
  if not (id and P and P.res) then return nil end
  for _, r in ipairs(P.res.rares or {}) do
    for _, x in ipairs(r.ids or {}) do if x == id then return r end end
  end
  return nil
end
-- the panel's boss or rare with this NPC id
local function PanelRec(id)
  if not (id and P and P.res) then return nil end
  for _, list in ipairs({ P.res.bosses or {}, P.res.rares or {} }) do
    for _, r in ipairs(list) do
      for _, x in ipairs(r.ids or {}) do if x == id then return r end end
    end
  end
  return nil
end

-- Records a rare as seen; the panel's head lights up (colours only in combat).
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
  -- its face, for a portrait without a known model
  local rec = PanelRec(id)
  if rec then LiveFace(unit, rec); LearnUnit(unit, id) end
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
  AB:RegisterForClicks("AnyUp", "AnyDown")
  AB:SetAttribute("type", "macro")
  ns.Flat(AB, T.btnFill, T.btnEdge)
  AB.hl = ns.Tex(AB, "BACKGROUND", T.hoverFill); AB.hl:SetAllPoints(); AB.hl:SetAlpha(0)
  -- a labelled button: no star (the banner's star already says "rare", icon audit G3)
  AB.label = ns.Text(AB, ns.F.label, T.fg, false)
  AB.label:SetPoint("LEFT", 12, 0); AB.label:SetWordWrap(false)
  AB.label:SetText(L.BOSS_TARGET)
  local okW, sw = pcall(AB.label.GetStringWidth, AB.label)
  sw = okW and num(sw) or 96
  AB:SetWidth(math.ceil(12 + sw + 12))
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

-- A rare's nameplate: seen for the panel, and the alert (once per 10 minutes per rare). The alert
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

-- A dungeon's portraits prepared off screen before its panel shows (the known display ids drawn on
-- the stage now, ready to move onto their heads a few seconds later).
local function WarmPortraits(dkey)
  local okM, res = pcall(ns.DungeonMobs, dkey)
  if not (okM and type(res) == "table") then return end
  for _, list in ipairs({ res.bosses or {}, res.rares or {} }) do
    for _, rec in ipairs(list) do
      local okD, did = pcall(DisplayFor, rec)
      if okD and did then pcall(PoolGet, did, rec) end
    end
  end
end
ns.BossWarmPortraits = WarmPortraits

-- the faces of the route's dungeons, looked up and prepared outside (one creature at a time)
local function WarmFaces()
  if CurrentInstance() or InCombat() then return end
  local sel = ns.route and ns.route.sel
  for k in pairs(sel or {}) do WarmPortraits(k) end
  LookNext()
end

local function OnEntering()
  local wasIn = Kills().iid ~= nil and not Kills().left
  NewVisitCheck(true)
  Baseline()
  local dkey, iid = DungeonHere()
  if not iid then
    -- out of the dungeon: the run's report, and the panel opened for it goes away
    if wasIn or Kills().reportDue then RunReport() end
    if P and P:IsShown() and P.auto then ns.HideBosses() end
    for k in pairs(dismissed) do dismissed[k] = nil end
    -- face lookups wait a while after the loading screen
    if C_Timer and C_Timer.After then C_Timer.After(8, WarmFaces) end
    return
  end
  local k = Kills()
  -- back inside before the report of the last exit went out: it goes with the next exit
  k.reportDue = nil
  if dkey and k.iid == iid and not k.dkey then k.dkey = dkey end
  -- a dungeon with wings: the order of the wing you came in by
  Wing.Check()
  if Lib() then
    StartIndex(false)
    -- the dungeon's boss list (local names, NPC ids) is built even with the panel hidden: the
    -- guide matches kills on it (a French ENCOUNTER_END name, a boss without encounter ID)
    if dkey then
      local function warm() WarmPortraits(dkey) end
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
  if hit then
    -- a real kill overrides a "not killed" set by hand
    for _, t in ipairs({ k.off or false, k.manual or false }) do
      if t then
        if name then t[name] = nil end
        if en then t[en] = nil end
      end
    end
    -- when it died (the tooltip's "+12:34", the run's end)
    local t = Now()
    k.at = k.at or {}
    for _, key in ipairs({ name or false, en or false, id and ("#" .. id) or false, enc and ("e" .. enc) or false }) do
      if key and key ~= "" and not k.at[key] then k.at[key] = t end
    end
    k.lastKill = t
    RunDungeon(k)
    -- the first kill in a wing says which wing the run started in
    Wing.Check()
    liveIid, liveRun = k.iid, k.run; ns.RefreshBosses(); GuideAfterKill()
  end
end
ns.BossMarkKilled = MarkKilled

-- "New run" (the panel's button): inside, a fresh run now (kills, time, XP and gold from zero);
-- outside, the next entry starts one.
function ns.NewBossRun()
  local k = Kills()
  local iid = CurrentInstance()
  if iid then
    local dk = k.dkey or DungeonHere()
    NewRun(k, iid)
    k.t = Now()
    k.dkey = dk
  else
    k.reset = true
  end
  Baseline()
  if ns.Print then ns.Print(L.RUN_RESET_DONE) end
  ns.RefreshBosses()
  GuideAfterKill()
end

-- A boss counted as killed stands alive, attackable and out of combat: this is another copy of the
-- instance (reset by the group leader, or entered again after a logout), a new run.
local function AliveCheck(unit, rec, id)
  -- (the caller saw it alive: UnitIsDead gave a plain false)
  if InCombat() then return false end
  local k = Kills()
  local iid = CurrentInstance()
  if not (iid and k.iid == iid) then return false end
  if not ((id and k.ids[id]) or (rec.en and k.names[rec.en])) then return false end
  -- marked killed by hand on the panel: a mistake there never resets the run
  if k.manual and rec.en and k.manual[rec.en] then return false end
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

-- The bosses and rares of one list, merged once per list (UNIT_HEALTH asks on every hit on your
-- target): kept while the list and its two counts stay the same. Callers only read it.
local merged = { res = nil, nb = -1, nr = -1, out = nil }
local NONE = {}
local function Merged(res)
  local nb, nr = #res.bosses, #res.rares
  if merged.res ~= res or merged.nb ~= nb or merged.nr ~= nr then
    local out = {}
    for _, r in ipairs(res.bosses) do out[#out + 1] = r end
    for _, r in ipairs(res.rares) do out[#out + 1] = r end
    merged.res, merged.nb, merged.nr, merged.out = res, nb, nr, out
  end
  return merged.out
end

-- The bosses a unit may be: the panel's heads when it shows, else the dungeon's boss list (the
-- list built for the panel, or the walk order) -> list of { en, name, ids }
local function Candidates()
  if P and P:IsShown() and P.res then
    return Merged(P.res), true
  end
  local dkey = DungeonHere()
  if not dkey then return NONE, false end
  local res = mobsCache[dkey]
  if res then
    return Merged(res), false
  end
  local out = {}
  local bo = ns.BossOrder and ns.BossOrder(dkey)
  for _, b in ipairs(bo and bo.list or {}) do out[#out + 1] = { en = b.en, name = b.name, ids = b.npc and { b.npc } or {} } end
  return out, false
end

-- Your target (or the mob under the mouse) is one of the dungeon's bosses: learn its creature type,
-- and a dead one counts as killed (the panel's head and the guide's boss step).
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
  LiveFace(unit, rec)
  LearnUnit(unit, id)
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

-- The bosses of the dungeon you stand in, by NPC id and by name, for the cheap death checks
-- (nameplates, the group's targets): false outside or without a boss list, nil = to build again
-- (a loading screen, the panel drawn again).
local watch, watchRetry = nil, 0
local function Watch()
  if watch then return watch end
  -- nothing to watch (yet): asked again two seconds later at most, so the dungeon found late (its
  -- key set after the loading screen) still gets its checks without a rebuild on every health tick
  local now = GetTime and GetTime()
  if watch == false and now and now < watchRetry then return false end
  watch = false
  if now then watchRetry = now + 2 else watch = nil end
  if not CurrentInstance() then return false end
  local list = Candidates()
  if #list == 0 then return false end
  local w = { ids = {}, names = {} }
  for _, r in ipairs(list) do
    for _, x in ipairs(r.ids or {}) do w.ids[x] = r end
    local jn = r.journal and num(r.journal.npc)
    if jn then w.ids[jn] = r end
    if r.en then w.names[r.en] = r end
    if r.name then w.names[r.name] = r end
  end
  watch = w
  return watch
end
ns.BossWatchReset = function() watch, watchRetry = nil, 0 end

-- A boss unit seen dead (UnitIsDead, or no health left; a secret answer is never trusted): counted
-- as killed. No alive check here: a nameplate never starts a new run.
local function KillCheck(unit)
  local w = Watch()
  if not w then return end
  local id = NpcIdOf(unit)
  local rec = id and w.ids[id]
  if not rec then
    -- by name only when the unit's NPC id is unknown, or the boss has none on record: a trash mob,
    -- a summon or an image sharing a boss's name is not that boss
    local okN, nm = pcall(UnitName, unit)
    nm = okN and str(nm)
    local r = nm and w.names[nm]
    if r and (not id or (#(r.ids or {}) == 0 and not (r.journal and num(r.journal.npc)))) then rec = r end
  end
  if not rec then return end
  local dead = false
  local okD, d = pcall(UnitIsDead or function() return nil end, unit)
  if okD and bool(d) == true then dead = true
  elseif not (okD and secret(d)) and UnitHealth then
    local okH, hp = pcall(UnitHealth, unit)
    local okM, mx = pcall(UnitHealthMax or function() return nil end, unit)
    hp, mx = okH and num(hp), okM and num(mx)
    if hp == 0 and mx and mx > 0 then dead = true end
  end
  if not dead then return end
  local k = Kills()
  if CurrentInstance() == k.iid and ((id and k.ids[id]) or k.names[rec.en]) then return end
  MarkKilled(rec.name, id, nil, rec.en)
end
ns.BossKillCheck = KillCheck

-- the units whose health is watched for a boss's death (besides the target, see TargetCheck)
local function Watched(unit)
  if type(unit) ~= "string" or secret(unit) then return false end
  if unit:sub(1, 9) == "nameplate" or unit:sub(1, 4) == "boss" then return true end
  return unit == "focus" or unit == "mouseover"
end

-- The panel's right-click: the boss marked killed (by hand) or not killed. Not killed undoes every
-- trace of it in the run (names, NPC ids, its encounter: a boss sharing the encounter, Ruuzlu with
-- Chief Ukorz, stays killed) and the guide's boss step done only from that kill opens again.
-- Only inside a dungeon, and only on the panel of the dungeon you stand in (another dungeon's
-- bosses shown there are not this run's).
local function CanToggle()
  if not CurrentInstance() then return false end
  local k = Kills()
  local here = (CurrentInstance() == k.iid and RunDungeon(k)) or DungeonHere()
  if here and P and P.dkey and P.dkey ~= here then return false end
  return true
end
ns.BossCanToggle = CanToggle

local function ToggleKilled(rec)
  if not (rec and rec.en and CanToggle()) then return end
  NewVisitCheck()
  if not CanToggle() then return end
  local k = Kills()
  k.at = k.at or {}
  if RecKilled(k, rec) then
    local function clear(key) if key and key ~= "" then k.names[key] = nil; k.at[key] = nil end end
    clear(rec.en); clear(rec.name)
    for _, id in ipairs(rec.ids or {}) do k.ids[id] = nil; k.at["#" .. id] = nil end
    if rec.journal then
      clear(str(rec.journal.name))
      local jn = num(rec.journal.npc)
      if jn then k.ids[jn] = nil; k.at["#" .. jn] = nil end
    end
    if rec.journal and type(rec.journal.enc) == "table" then
      for _, e in ipairs(rec.journal.enc) do
        if k.enc[e] then
          local others = {}
          for _, list in ipairs({ P and P.res and P.res.bosses or {}, P and P.res and P.res.rares or {} }) do
            for _, o in ipairs(list) do
              if o ~= rec and o.en ~= rec.en and o.journal and type(o.journal.enc) == "table" then
                for _, e2 in ipairs(o.journal.enc) do if e2 == e then others[#others + 1] = o end end
              end
            end
          end
          for _, o in ipairs(others) do
            k.names[o.en] = true
            if not k.at[o.en] then k.at[o.en] = k.at["e" .. e] end
          end
          k.enc[e] = nil; k.at["e" .. e] = nil
        end
      end
    end
    if k.manual then k.manual[rec.en] = nil end
    k.off = k.off or {}
    k.off[rec.en] = true
    local dk = P and P.dkey or RunDungeon(k)
    if ns.UndoBossStepKill and dk then pcall(ns.UndoBossStepKill, dk, rec.en) end
    liveIid, liveRun = k.iid, k.run
    ns.RefreshBosses(); GuideAfterKill()
  else
    MarkKilled(rec.name, nil, nil, rec.en)
    k.manual = k.manual or {}
    k.manual[rec.en] = true
  end
end
ns.BossToggleKilled = ToggleKilled

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
  "PLAYER_TARGET_CHANGED", "QUEST_LOG_UPDATE", "QUEST_TURNED_IN", "NAME_PLATE_UNIT_ADDED", "UPDATE_MOUSEOVER_UNIT", "CHAT_MSG_SYSTEM",
  "PLAYER_XP_UPDATE", "PLAYER_MONEY", "PLAYER_UNGHOST", "PLAYER_ALIVE", "NAME_PLATE_UNIT_REMOVED", "UNIT_HEALTH",
  "ZONE_CHANGED", "ZONE_CHANGED_INDOORS", "ZONE_CHANGED_NEW_AREA" }) do
  pcall(ev.RegisterEvent, ev, e)
end
-- UNIT_HEALTH: the target (TargetCheck), and the nameplates, focus, mouseover and boss frames of
-- the dungeon's bosses (a boss dying in view counts as killed: some bosses here have no encounter)
local questPending = false
local GROUP_TARGETS = { "target", "focus", "party1target", "party2target", "party3target", "party4target", "boss1", "boss2", "boss3", "boss4", "boss5" }
ev:SetScript("OnEvent", function(_, e, a1, a2, a3, a4, a5)
  if e == "PLAYER_ENTERING_WORLD" then
    watch, watchRetry = nil, 0
    if C_Timer and C_Timer.After then C_Timer.After(2.5, OnEntering) else OnEntering() end
  elseif e == "PLAYER_XP_UPDATE" then
    if a1 == nil or a1 == "player" then OnXP(); UpdateStats() end
  elseif e == "PLAYER_MONEY" then
    OnMoney(); UpdateStats()
  elseif e == "PLAYER_UNGHOST" or e == "PLAYER_ALIVE" then
    -- alive again outside: the run's report held back while you were dead
    if Kills().reportDue and not CurrentInstance() then RunReport() end
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
    LookNext()
    -- the end of a fight: a boss the group was hitting lies dead (no encounter event for it)
    if Watch() then
      for _, u in ipairs(GROUP_TARGETS) do
        if UnitExists and UnitExists(u) then KillCheck(u) end
      end
    end
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
    ns.NpcPortraitUnit("target")
    -- a living boss of a wing in your target: you are in that wing (Maraudon)
    if UnitExists and UnitExists("target") then
      local okD, dead = pcall(UnitIsDead or function() return nil end, "target")
      local okN, nm = pcall(UnitName, "target")
      nm = okN and str(nm)
      if nm and okD and bool(dead) == false then Wing.Seen(nm) end
    end
  elseif e == "ZONE_CHANGED" or e == "ZONE_CHANGED_INDOORS" or e == "ZONE_CHANGED_NEW_AREA" then
    -- walking into a wing's subzone (Maraudon's orange or purple caves)
    Wing.Check()
  elseif e == "UPDATE_MOUSEOVER_UNIT" then
    SeenCheck("mouseover")
    TargetCheck("mouseover")
    ns.NpcPortraitUnit("mouseover")
  elseif e == "NAME_PLATE_UNIT_ADDED" then
    local unit = str(a1)
    if unit then
      SeenCheck(unit)
      ns.RareAlert(unit)
      ns.NpcPortraitUnit(unit)
    end
  elseif e == "UNIT_HEALTH" then
    -- the target always (as before); the others only while there are bosses to watch (Watch is
    -- cached, and asked again at most every two seconds while it has none)
    if a1 == "target" then TargetCheck("target")
    elseif Watched(a1) then KillCheck(a1) end
  elseif e == "NAME_PLATE_UNIT_REMOVED" then
    if Watched(a1) then KillCheck(a1) end
  elseif (e == "QUEST_LOG_UPDATE" or e == "QUEST_TURNED_IN") and P and P:IsShown() and not questPending then
    questPending = true
    local function go() questPending = false; ns.RefreshBosses() end
    if C_Timer and C_Timer.After then C_Timer.After(0.5, go) else go() end
  end
end)
ns.BossEvents = ev
Baseline()
