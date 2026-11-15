-- Bosses.lua: the bosses and rares of a dungeon, in a panel under the guide (or on its own).
-- Data read LIVE from LibForeverData (optional dependency, never copied): every NPC whose spawns
-- sit on the dungeon's instance map (ns.D[k].inst = the client Map id LibForeverData stores for
-- instance spawns), ranked boss (3) or rare (2 rare elite, 4 rare), plus the bosses of the walk
-- order (ns.WALK / ns.BossOrder: most 5-player bosses are only "elite" in the data).
-- Each row: portrait, name, level, rare frame, killed check, quest link, a secure "Target and mark"
-- button (macro) and the marker it puts. Secure buttons are created, moved, shown and given their
-- macro out of combat only; changes in combat wait for PLAYER_REGEN_ENABLED.
-- API: ns.DungeonMobs(dkey[, sync]) -> { bosses = {...}, rares = {...}, loading, source }
--      ns.ShowBosses(dkey), ns.HideBosses(), ns.ToggleBosses(dkey), ns.AttachBosses(parentFrame),
--      ns.RefreshBosses(), ns.BossesShown()
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

local function Finish()
  building = false
  indexReady = true
  scanIds = nil
  for k in pairs(mobsCache) do mobsCache[k] = nil end
  local list = onReady
  onReady = {}
  for _, fn in ipairs(list) do pcall(fn) end
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

-- ---------------------------------------------------------------- kills (this visit)
local function Kills()
  local db = DB()
  db.bossKills = db.bossKills or { names = {}, ids = {} }
  return db.bossKills
end
local function CurrentInstance()
  if not GetInstanceInfo then return nil end
  local ok, _, kind, _, _, _, _, _, id = pcall(GetInstanceInfo)
  if not ok or (kind ~= "party" and kind ~= "raid") then return nil end
  return num(id)
end
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
-- Entering an instance: a different one, or the same after 4 hours, starts a new visit.
local function NewVisitCheck()
  local iid = CurrentInstance()
  if not iid then return end
  local k = Kills()
  local now = (GetServerTime and GetServerTime()) or (time and time()) or 0
  if k.iid ~= iid or not k.t or now - k.t > 4 * 3600 then
    k.iid, k.names, k.ids = iid, {}, {}
    k.objs = KillSnapshot()
  end
  k.t = now
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

-- Fills rec.quests ({ qid, item, kind }) and rec.killed for every row.
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
    for _, qid in ipairs(pool) do
      local q = ns.Q[qid]
      if q and q.o and not ns.IsDone(qid) then
        for oi, o in ipairs(q.o) do
          if Names(o)[rec.en] then
            local done = false
            local okD, v = pcall(ns.ObjDone, log, qid, o)
            if okD then done = v end
            -- finished now but not when the visit started: killed during this visit
            if o.k == "kill" and done and log[qid] and fresh and k.objs and not k.objs[qid .. ":" .. oi] then rec.killed = true end
            if not done then
              table.insert(rec.quests, { qid = qid, kind = o.k == "item" and "item" or "kill", item = o.n })
            end
          end
        end
      end
    end
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

-- ---------------------------------------------------------------- panel
local P               -- the panel
local parentFrame     -- the guide window it hangs under
local pending = {}    -- what waits for the end of combat
local dismissed = {}  -- instance IDs whose panel you closed during this visit
local ROW_GAP, PAD, HEAD = 2, 16, 44
local rowsN = 0

local function Marker(rec)
  local db = DB()
  db.bossMarks = db.bossMarks or {}
  return db.bossMarks[rec.en] or (rec.rare and MARK_DEFAULT_RARE or MARK_DEFAULT_BOSS)
end

local function MacroFor(rec)
  local m = Marker(rec)
  return "/cleartarget\n/tar " .. (rec.name or rec.en) ..
    "\n/run if UnitExists'target' and GetRaidTargetIndex'target'~=" .. m .. " then SetRaidTarget('target'," .. m .. ") end"
end

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
local function QuestLine(qn)
  local qname = ns.QName(qn.qid)
  if qn.kind == "item" then return L.BOSS_ITEM:format(ns.T(qn.item) or qn.item or qname) end
  return L.BOSS_KILLQ:format(qname)
end
local function DetailText(rec)
  local parts = {}
  local lv = LevelText(rec)
  if lv then parts[#parts + 1] = lv end
  local q = rec.quests and rec.quests[1]
  if q then
    local s = QuestLine(q)
    if #rec.quests > 1 then s = L.BOSS_MORE:format(s, #rec.quests - 1) end
    parts[#parts + 1] = s
  end
  return table.concat(parts, " · ")
end

local function RowTip(row)
  local rec = row.rec
  if not rec then return end
  local lines = { rec.name or rec.en }
  local sub = RankWord(rec)
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
  if rec.killed then lines[#lines + 1] = { L.BOSS_KILLED, T.ok[1], T.ok[2], T.ok[3] } end
  ns.ShowTip(row, lines)
end

-- painted portrait: the creature's display (journal), its type icon, else the HD skull / star
local function SetPortrait(row, rec)
  local tex, hd = row.port, row.portHD
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
  row.portEdge(rec.rare and T.silver or T.cardEdge, rec.rare and 0.9 or T.cardEdge[4])
end

-- the secure button's look (a secondary button, 24 tall) and its tooltip
local function MakeTargetButton(row, i)
  local b = CreateFrame("Button", "WLBossTarget" .. i, row, "SecureActionButtonTemplate")
  b:SetHeight(24)
  b:RegisterForClicks("AnyUp", "AnyDown")
  b:SetAttribute("type", "macro")
  ns.Flat(b, T.btnFill, T.btnEdge)
  b.hl = ns.Tex(b, "BACKGROUND", T.hoverFill); b.hl:SetAllPoints(); b.hl:SetAlpha(0)
  b.press = ns.Tex(b, "ARTWORK", T.pressFill); b.press:SetAllPoints(); b.press:Hide()
  b.icon = b:CreateTexture(nil, "OVERLAY"); b.icon:SetSize(14, 14); b.icon:SetPoint("LEFT", 8, 0)
  ns.SetHDIcon(b.icon, "skull", T.muted)
  b.label = ns.Text(b, ns.F.label, T.fg, false)
  b.label:SetPoint("LEFT", b.icon, "RIGHT", 6, 0); b.label:SetJustifyV("MIDDLE"); b.label:SetWordWrap(false)
  b.label:SetText(L.BOSS_TARGET)
  b.label:SetTextColor(T.fg[1], T.fg[2], T.fg[3], 0.85)
  b.Fit = function(self)
    local okW, sw = pcall(self.label.GetStringWidth, self.label)
    sw = okW and num(sw) or 0
    if sw <= 0 then sw = 96 end
    self:SetWidth(math.ceil(8 + 14 + 6 + sw + 12))
  end
  b:Fit()
  b:SetScript("OnEnter", function(self)
    self.hl:SetAlpha(1); self._edgeSet(T.btnEdgeHover); self.label:SetTextColor(T.fg[1], T.fg[2], T.fg[3], 1)
    ns.SetHDIcon(self.icon, "skull", T.fg)
    local rec = row.rec
    if not rec then return end
    local lines = { L.BOSS_TARGET, L.BOSS_TT_TARGET:format(rec.name or rec.en, MarkName(Marker(rec))) }
    if row.stale then lines[#lines + 1] = { L.BOSS_WAIT, T.warn[1], T.warn[2], T.warn[3] } end
    lines[#lines + 1] = L.BOSS_TT_CLICK
    ns.ShowTip(self, lines)
  end)
  b:SetScript("OnLeave", function(self)
    self.hl:SetAlpha(0); self._edgeSet(T.btnEdge); self.label:SetTextColor(T.fg[1], T.fg[2], T.fg[3], 0.85)
    ns.SetHDIcon(self.icon, "skull", T.muted)
    ns.HideTip()
  end)
  b:HookScript("OnMouseDown", function(self) self.press:Show() end)
  b:HookScript("OnMouseUp", function(self) self.press:Hide() end)
  return b
end

local function MakeRow(i)
  local row = CreateFrame("Frame", nil, P.content)
  row.bg = ns.Tex(row, "BACKGROUND", T.cardFill); row.bg:SetAllPoints()
  row.hl = ns.Tex(row, "BACKGROUND", T.hoverFill); row.hl:SetAllPoints(); row.hl:SetAlpha(0)
  row:EnableMouse(true)
  row:SetScript("OnEnter", function(self) self.hl:SetAlpha(1); RowTip(self) end)
  row:SetScript("OnLeave", function(self) self.hl:SetAlpha(0); ns.HideTip() end)
  -- portrait 28 px, 1 px edge (silver for a rare)
  row.portBox = CreateFrame("Frame", nil, row)
  row.portBox:SetSize(28, 28); row.portBox:SetPoint("TOPLEFT", 8, -6)
  local pbg = ns.Tex(row.portBox, "BACKGROUND", T.cardFill); pbg:SetAllPoints()
  row.portEdge = ns.Outline(row.portBox, T.cardEdge)
  row.port = row.portBox:CreateTexture(nil, "ARTWORK"); row.port:SetPoint("TOPLEFT", 1, -1); row.port:SetPoint("BOTTOMRIGHT", -1, 1)
  row.portHD = ns.Icon(row.portBox, "skull", 16, "ARTWORK", T.muted); row.portHD:SetPoint("CENTER")
  -- right cluster: target button, marker, killed check
  row.btn = MakeTargetButton(row, i)
  row.btn:SetPoint("RIGHT", row, "RIGHT", -12, 0)
  row.mark = CreateFrame("Button", nil, row)
  row.mark:SetSize(24, 24); row.mark:SetPoint("RIGHT", row.btn, "LEFT", -4, 0)
  row.mark.hl = ns.Tex(row.mark, "BACKGROUND", T.hoverFill); row.mark.hl:SetAllPoints(); row.mark.hl:SetAlpha(0)
  row.mark.icon = row.mark:CreateTexture(nil, "ARTWORK"); row.mark.icon:SetSize(16, 16); row.mark.icon:SetPoint("CENTER")
  row.mark:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  row.mark:SetScript("OnEnter", function(self)
    self.hl:SetAlpha(1)
    local rec = row.rec
    if not rec then return end
    local lines = { L.BOSS_MARK_TT:format(MarkName(Marker(rec))) }
    if InCombat() then lines[#lines + 1] = { L.BOSS_COMBAT, T.warn[1], T.warn[2], T.warn[3] }
    else lines[#lines + 1] = L.BOSS_MARK_CLICK; lines[#lines + 1] = L.BOSS_MARK_RCLICK end
    ns.ShowTip(self, lines)
  end)
  row.mark:SetScript("OnLeave", function(self) self.hl:SetAlpha(0); ns.HideTip() end)
  row.mark:SetScript("OnClick", function(self, button)
    local rec = row.rec
    if not rec or InCombat() then return end
    local db = DB()
    db.bossMarks = db.bossMarks or {}
    if button == "RightButton" then db.bossMarks[rec.en] = nil
    else db.bossMarks[rec.en] = (Marker(rec) % 8) + 1 end
    if PlaySound then PlaySound(SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or 856) end
    ns.RefreshBosses()
    local s = self:GetScript("OnEnter"); if s then s(self) end
  end)
  row.check = ns.Icon(row, "check", 16, "ARTWORK", T.ok)
  row.check:SetPoint("RIGHT", row.mark, "LEFT", -8, 0)
  row.check:SetAlpha(0)
  -- name and detail
  row.name = ns.Text(row, ns.F.label, T.fg, false)
  row.name:SetPoint("TOPLEFT", 44, -6)
  row.detail = ns.Text(row, ns.F.meta, T.muted, false)
  row.detail:SetPoint("TOPLEFT", row.name, "BOTTOMLEFT", 0, -3)
  return row
end

-- what may change in combat: colours and the check (regions only, nothing secure)
local function PaintRow(row)
  local rec = row.rec
  if not rec then return end
  local c = rec.killed and T.muted or T.fg
  row.name:SetTextColor(c[1], c[2], c[3])
  row.check:SetAlpha(rec.killed and 1 or 0)
  row.mark.icon:SetTexture(MarkTexture(Marker(rec)))
  row.mark.icon:SetAlpha(row.mark:IsEnabled() == false and T.disabledAlpha or 1)
end

local function Measure(fs, w, lines)
  return ns.FitText(fs, lines or 2, w, fs:GetParent())
end

local function FillRow(row, rec, w)
  row.rec = rec
  row.stale = nil
  row:SetWidth(w)
  row.name:SetText(rec.name or rec.en)
  -- the font may have changed (looks): the button follows its label (FillRow runs out of combat)
  row.btn.label:SetText(L.BOSS_TARGET)
  row.btn:Fit()
  local det = DetailText(rec)
  row.detail:SetText(det)
  row.detail:SetShown(det ~= "")
  local right = 12 + row.btn:GetWidth() + 4 + 24 + 8 + 16 + 8
  local tw = math.max(60, w - 44 - right)
  local h1 = Measure(row.name, tw, 2)
  local h2 = det ~= "" and Measure(row.detail, tw, 2) or 0
  local h = 6 + math.max(h1, 12) + (det ~= "" and (3 + math.max(h2, 11)) or 0) + 8
  h = math.max(40, math.ceil(h))
  row:SetHeight(h)
  SetPortrait(row, rec)
  row.btn:SetAttribute("macrotext", MacroFor(rec))
  row.btn:SetAttribute("type", "macro")
  PaintRow(row)
  return h
end

local function Width()
  local db = DB()
  if P.attached and parentFrame then
    local okW, pw = pcall(parentFrame.GetWidth, parentFrame)
    local okS, ps = pcall(parentFrame.GetEffectiveScale, parentFrame)
    local ms = P:GetEffectiveScale()
    pw, ps, ms = okW and num(pw), okS and num(ps), num(ms)
    if pw and ps and ms and ms > 0 and pw > 0 then return math.max(360, math.min(640, math.floor(pw * ps / ms + 0.5))) end
  end
  return db.bossW or 420
end

local function Build()
  if P then return P end
  if InCombat() then return nil end
  local S = ns.S
  P = CreateFrame("Frame", "WLBossPanel", UIParent)
  P:SetSize(420, 200)
  P:SetFrameStrata("MEDIUM")
  P:SetClampedToScreen(true)
  P:SetMovable(true)
  P:EnableMouse(true)
  P:Hide()
  if ns.RegisterWindow then ns.RegisterWindow(P) end
  local bg = ns.Tex(P, "BACKGROUND", T.bg); bg:SetAllPoints()
  ns.Outline(P, T.cardEdge)
  -- header 44: logo, title, subtitle (the dungeon), attach and close at the right
  local h = CreateFrame("Frame", nil, P)
  h:SetPoint("TOPLEFT"); h:SetPoint("TOPRIGHT"); h:SetHeight(HEAD)
  h:EnableMouse(true)
  h:RegisterForDrag("LeftButton")
  h:SetScript("OnMouseDown", function() if not InCombat() then P:Raise() end end)
  h:SetScript("OnDragStart", function() if not InCombat() then P.wlMoving = true; P:StartMoving() end end)
  h:SetScript("OnDragStop", function()
    if not P.wlMoving then return end
    P.wlMoving = nil
    if not InCombat() then P:StopMovingOrSizing() end
    P.SavePos()
  end)
  h:SetScript("OnEnter", function(self) ns.ShowTip(self, { L.BOSS_TITLE, L.BOSS_DRAG }) end)
  h:SetScript("OnLeave", ns.HideTip)
  local rule = ns.Tex(P, "BORDER", T.line)
  rule:SetPoint("TOPLEFT", 0, -HEAD); rule:SetPoint("TOPRIGHT", 0, -HEAD)
  ns.PixelLine(P, rule, true)
  -- no logo here (it stays on the home page): a zero-width anchor keeps the title's place code
  P.logo = h:CreateTexture(nil, "ARTWORK"); P.logo:SetSize(1, 28); P.logo:SetPoint("TOPLEFT", 6, -8)
  P.logo:SetAlpha(0)
  P.close = S.CloseButton(h, 28, function() ns.HideBosses(true) end)
  P.close:SetPoint("TOPRIGHT", -8, -8)
  P.attach = S.IconButton(h, "pin", 28, { L.BOSS_ATTACH, L.BOSS_ATTACH_CLICK }, function()
    if InCombat() then return end
    DB().bossDetached = nil
    P.attached = parentFrame ~= nil
    ns.RefreshBosses()
  end)
  P.attach:SetPoint("RIGHT", P.close, "LEFT", -4, 0)
  P.title = ns.Text(h, ns.F.title, T.fg, true)
  P.title:SetPoint("TOPLEFT", 14, -6); P.title:SetPoint("RIGHT", P.attach, "LEFT", -8, 0)
  ns.ClampLabel(P.title, nil, h)
  P.sub = ns.Text(h, ns.F.meta, T.muted, false)
  P.sub:SetPoint("TOPLEFT", P.title, "BOTTOMLEFT", 0, -2); P.sub:SetPoint("RIGHT", P.attach, "LEFT", -8, 0)
  ns.ClampLabel(P.sub, nil, h)
  P.title:SetText(L.BOSS_TITLE)
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
  -- content: scrolls once the panel reaches its height cap (no scrolling in combat: the panel
  -- holds secure buttons)
  P.sa = S.ScrollArea(P)
  P.sa:SetPoint("TOPLEFT", 0, -(HEAD + 1)); P.sa:SetPoint("TOPRIGHT", 0, -(HEAD + 1)); P.sa:SetHeight(10)
  local wheel = P.sa:GetScript("OnMouseWheel")
  P.sa:SetScript("OnMouseWheel", function(self, delta) if not InCombat() and wheel then wheel(self, delta) end end)
  P.content = P.sa.child
  P.secBoss = S.SectionHeader(P.content, L.BOSS_SEC)
  P.secRare = S.SectionHeader(P.content, L.BOSS_RARES, nil, L.BOSS_HIDE, function()
    if InCombat() then return end
    local db = DB()
    db.bossRaresOpen = not P.raresOpen
    ns.RefreshBosses()
  end)
  P.empty = S.EmptyState(P.content, "skull", L.BOSS_EMPTY_T, nil)
  P.empty:Hide()
  P.rows = {}
  -- attached: follow the guide when it moves or changes height (out of combat)
  P:SetScript("OnUpdate", function()
    if not (P.attached and parentFrame) or InCombat() then return end
    local l, b = num(parentFrame:GetLeft()), num(parentFrame:GetBottom())
    local w = num(parentFrame:GetWidth())
    if l ~= P.lastL or b ~= P.lastB then ns.SnapBosses() end
    if w and w ~= P.lastW then P.lastW = w; ns.RefreshBosses() end
  end)
  return P
end

-- Puts the panel 4 px under the guide (absolute position: no anchor to the guide, so the guide
-- never becomes a protected frame and keeps resizing in combat).
function ns.SnapBosses()
  if not P then return end
  if InCombat() then pending.snap = true return end
  if P.attached and parentFrame then
    local l, b = num(parentFrame:GetLeft()), num(parentFrame:GetBottom())
    local okS, ps = pcall(parentFrame.GetEffectiveScale, parentFrame)
    ps = okS and num(ps)
    local ms = num(P:GetEffectiveScale())
    if l and b and ps and ms and ms > 0 then
      P:ClearAllPoints()
      P:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", l * ps / ms, b * ps / ms - 4)
      P.lastL, P.lastB = l, b
      return
    end
  end
  local pos = DB().bossPos
  P:ClearAllPoints()
  if pos and pos[1] then P:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", pos[1], pos[2])
  else P:SetPoint("CENTER", UIParent, "CENTER", 0, 0) end
end

local function Render()
  if not P then return end
  if InCombat() then
    pending.render = true
    -- what can change now: the killed checks
    if P.dkey and P:IsShown() then
      local res = ns.DungeonMobs(P.dkey)
      local by = {}
      for _, r in ipairs(res.bosses) do by[r.en] = r end
      for _, r in ipairs(res.rares) do by[r.en] = r end
      for _, row in ipairs(P.rows) do
        if row.rec and by[row.rec.en] then row.rec.killed = by[row.rec.en].killed; row.stale = true; PaintRow(row) end
      end
    end
    return
  end
  pending.render = nil
  local dkey = P.dkey
  local db = DB()
  P.attached = (parentFrame ~= nil and not db.bossDetached and parentFrame:IsShown()) and true or false
  local W = Width()
  P:SetWidth(W)
  P.lastW = parentFrame and num(parentFrame:GetWidth()) or nil
  P.attach:SetShown(parentFrame ~= nil and db.bossDetached == true)
  P.sub:SetText(dkey and ns.DName(dkey) or "")
  local res = dkey and ns.DungeonMobs(dkey) or { bosses = {}, rares = {} }
  P.res = res
  local cw = W - 2 * PAD
  local y = 4
  local used = 0
  local function place(rec)
    used = used + 1
    local row = P.rows[used]
    if not row then row = MakeRow(used); P.rows[used] = row; rowsN = used end
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", P.content, "TOPLEFT", PAD, -y)
    local h = FillRow(row, rec, cw)
    row:Show()
    y = y + h + ROW_GAP
  end
  local nb, nr = #res.bosses, #res.rares
  if nb + nr == 0 then
    P.secBoss:Hide(); P.secRare:Hide()
    local title, text = L.BOSS_EMPTY_T, L.BOSS_EMPTY_NONE
    if res.loading then title, text = L.BOSS_LOADING_T, L.BOSS_LOADING
    elseif res.noLib then text = L.BOSS_EMPTY_NOLIB end
    P.empty:SetWrapWidth(cw)
    local eh = P.empty:Set(res.loading and "clock" or "skull", title, text, nil)
    P.empty:ClearAllPoints(); P.empty:SetPoint("TOP", P.content, "TOP", 0, -24)
    P.empty:Show()
    y = 24 + (num(eh) or 80)
  else
    P.empty:Hide()
    if nb > 0 then
      P.secBoss:ClearAllPoints()
      P.secBoss:SetPoint("TOPLEFT", P.content, "TOPLEFT", PAD, -y); P.secBoss:SetPoint("TOPRIGHT", P.content, "TOPRIGHT", -PAD, -y)
      P.secBoss:Set(L.BOSS_SEC, tostring(nb)); P.secBoss:Show()
      y = y + 32 + 4
      for _, rec in ipairs(res.bosses) do place(rec) end
    else P.secBoss:Hide() end
    if nr > 0 then
      if nb > 0 then y = y + 16 - ROW_GAP end
      local open = db.bossRaresOpen
      if open == nil then open = nr <= 4 end
      P.raresOpen = open
      P.secRare:ClearAllPoints()
      P.secRare:SetPoint("TOPLEFT", P.content, "TOPLEFT", PAD, -y); P.secRare:SetPoint("TOPRIGHT", P.content, "TOPRIGHT", -PAD, -y)
      P.secRare:Set(L.BOSS_RARES, tostring(nr)); P.secRare:Show()
      if P.secRare.link then P.secRare.link:SetText(open and L.BOSS_HIDE or L.BOSS_SHOW) end
      y = y + 32 + 4
      if open then for _, rec in ipairs(res.rares) do place(rec) end end
    else P.secRare:Hide() end
    y = y - ROW_GAP
  end
  for i = used + 1, #P.rows do P.rows[i]:Hide(); P.rows[i].rec = nil end
  local contentH = math.ceil(y)
  -- the view: the content up to 80 % of the screen; attached, up to the room left under the guide
  local okH, screen = pcall(UIParent.GetHeight, UIParent)
  screen = okH and num(screen) or 768
  local cap = math.floor(screen * 0.8) - HEAD - 1 - PAD
  if P.attached and parentFrame then
    local b = num(parentFrame:GetBottom())
    local okS, ps = pcall(parentFrame.GetEffectiveScale, parentFrame)
    ps = okS and num(ps)
    local ms = num(P:GetEffectiveScale())
    if b and ps and ms and ms > 0 then
      local room = math.floor(b * ps / ms - 4 - 8) - HEAD - 1 - PAD
      if room >= 120 then cap = math.min(cap, room) end
    end
  end
  local viewH = math.max(60, math.min(contentH, cap))
  P.sa:SetHeight(viewH)
  P.sa:SetContentHeight(contentH)
  P:SetHeight(math.max(120, HEAD + 1 + viewH + PAD))
  ns.SnapBosses()
end
ns.RenderBosses = Render

function ns.RefreshBosses()
  if not P then return end
  if InCombat() then Render() return end
  if P:IsShown() then Render() end
end

function ns.BossesShown() return P ~= nil and P:IsShown() end

-- Opens the panel on a dungeon (from the guide, the overview or on entering it).
function ns.ShowBosses(dkey, auto)
  if not (dkey and ns.D and ns.D[dkey]) then return end
  if InCombat() then pending.show = dkey; pending.showAuto = auto; pending.hide = nil return end
  if not Build() then return end
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
  if InCombat() then pending.hide = true; pending.show = nil return end
  P:Hide()
end

function ns.ToggleBosses(dkey)
  if P and P:IsShown() and (not dkey or P.dkey == dkey) then ns.HideBosses(true) else ns.ShowBosses(dkey or (P and P.dkey)) end
end

-- The guide window the panel hangs under (UI.lua calls it once the guide is built).
function ns.AttachBosses(parent)
  if not parent then return end
  parentFrame = parent
  if not parent.wlBossHooked and parent.HookScript then
    parent.wlBossHooked = true
    pcall(parent.HookScript, parent, "OnHide", function()
      if P and P:IsShown() and P.attached then P.hiddenWithGuide = true; ns.HideBosses() end
    end)
    pcall(parent.HookScript, parent, "OnShow", function()
      if P and P.hiddenWithGuide and P.dkey then P.hiddenWithGuide = nil; ns.ShowBosses(P.dkey, P.auto) end
    end)
  end
  if P then ns.RefreshBosses() end
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
  NewVisitCheck()
  local dkey, iid = DungeonHere()
  if not iid then
    -- out of the dungeon: the panel opened for it goes away
    if P and P:IsShown() and P.auto then ns.HideBosses() end
    for k in pairs(dismissed) do dismissed[k] = nil end
    return
  end
  if Lib() then StartIndex(false) end
  local guideOn = (not ns.GuideOn) or ns.GuideOn()
  if dkey and guideOn and DB().bossAuto ~= false and not dismissed[iid] then
    if not (P and P:IsShown() and P.dkey == dkey) then ns.ShowBosses(dkey, true) end
  end
end

local function MarkKilled(name, id)
  if not CurrentInstance() then return end
  NewVisitCheck()
  local k = Kills()
  local hit = false
  if name and name ~= "" then k.names[name] = true; hit = true end
  if id then k.ids[id] = true; hit = true end
  if hit then ns.RefreshBosses() end
end

local function NpcIdOf(unit)
  if not UnitGUID then return nil end
  local okG, guid = pcall(UnitGUID, unit)
  guid = okG and str(guid)
  if not guid then return nil end
  local kind, id = guid:match("^(%a+)%-%d+%-%d+%-%d+%-%d+%-(%d+)")
  if kind == "Creature" or kind == "Vehicle" then return tonumber(id) end
  return nil
end

local function TargetCheck()
  if not (P and P:IsShown() and P.res) then return end
  if not (UnitExists and UnitExists("target")) then return end
  local id = NpcIdOf("target")
  local okN, nm = pcall(UnitName, "target")
  nm = okN and str(nm)
  local rec
  for _, list in ipairs({ P.res.bosses, P.res.rares }) do
    for _, r in ipairs(list) do
      if (nm and (r.name == nm or r.en == nm)) then rec = r end
      if id then for _, x in ipairs(r.ids or {}) do if x == id then rec = r end end end
    end
  end
  if not rec then return end
  -- learn its creature type for the painted icon
  if UnitCreatureType then
    local okT, ty = pcall(UnitCreatureType, "target")
    ty = okT and str(ty)
    if ty and TYPE_ICON[ty] then
      local db = DB()
      db.bossType = db.bossType or {}
      if db.bossType[rec.en] ~= ty then db.bossType[rec.en] = ty; pending.render = true end
    end
  end
  local okD, dead = pcall(UnitIsDead or function() return false end, "target")
  if okD and dead == true and not secret(dead) then MarkKilled(rec.en, id) end
end

local ev = CreateFrame("Frame")
for _, e in ipairs({ "PLAYER_ENTERING_WORLD", "PLAYER_REGEN_ENABLED", "PLAYER_REGEN_DISABLED", "ENCOUNTER_END", "BOSS_KILL",
  "PLAYER_TARGET_CHANGED", "QUEST_LOG_UPDATE", "QUEST_TURNED_IN" }) do
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
  elseif e == "PLAYER_REGEN_DISABLED" then
    if P and P.wlMoving then P.wlMoving = nil; P:StopMovingOrSizing(); P.SavePos() end
    if P and P.sa then P.sa:SetScript("OnUpdate", nil); if P.sa.thumb then P.sa.thumb.drag = nil; P.sa.thumb:SetScript("OnUpdate", nil) end end
  elseif e == "PLAYER_REGEN_ENABLED" then
    if pending.hide then pending.hide = nil; if P then P:Hide() end end
    if pending.show then local k, a = pending.show, pending.showAuto; pending.show, pending.showAuto = nil, nil; ns.ShowBosses(k, a) end
    if pending.render or pending.snap then pending.render, pending.snap = nil, nil; if P and P:IsShown() then Render() end end
  elseif e == "ENCOUNTER_END" then
    -- encounterID, encounterName, difficultyID, groupSize, success
    if num(a5) == 1 then MarkKilled(str(a2)) end
  elseif e == "BOSS_KILL" then
    MarkKilled(str(a2))
  elseif e == "PLAYER_TARGET_CHANGED" then
    TargetCheck()
  elseif e == "UNIT_HEALTH" then
    if a1 == "target" then TargetCheck() end
  elseif (e == "QUEST_LOG_UPDATE" or e == "QUEST_TURNED_IN") and P and P:IsShown() and not questPending then
    questPending = true
    local function go() questPending = false; ns.RefreshBosses() end
    if C_Timer and C_Timer.After then C_Timer.After(0.5, go) else go() end
  end
end)
ns.BossEvents = ev
