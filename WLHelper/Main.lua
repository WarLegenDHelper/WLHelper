-- Démarrage, route (création / recalcul / sauvegarde), événements et commandes.
local ADDON, ns = ...
local L = ns.L

local function DB()
  WLDTDB = WLDTDB or {}
  local db = WLDTDB
  db.sel = db.sel or {}; db.off = db.off or {}; db.manual = db.manual or {}
  if db.autoWay == nil then db.autoWay = true end
  if db.lang then ns.lang = db.lang end
  return db
end

local function Label(sel)
  local names = {}
  -- full names: "Zul'Farrak", not "ZF"
  for _, k in ipairs(ns.ORDER) do if sel[k] then table.insert(names, ns.DName(k)) end end
  return table.concat(names, " + ")
end

local function StepKeys(steps)
  for i, st in ipairs(steps) do
    if st.gate then
      local nxt = steps[i + 1]
      -- the next step's own key (a boss step's bkey: it may hold no quest line), never the index,
      -- which moves on a replan
      st.key = "g:" .. st.gate .. ":" .. ((nxt and (nxt.bkey or (nxt.acts[1] and nxt.acts[1].key)
        or (nxt.run and nxt.ins and ("r:" .. nxt.ins)))) or i)
    elseif st.bkey then
      -- a boss step keeps its key whatever quest lines it holds (its "done" survives a replan)
      st.key = st.bkey
    elseif st.run and #st.acts == 0 then
      -- a run in a dungeon with no boss list: one step, the same key across replans
      st.key = "r:" .. st.ins
    else
      st.key = st.acts[1] and st.acts[1].key or ("s" .. i)
    end
  end
end

-- Reconstruit les étapes ; garde l'ordre sauvegardé si possible.
-- order/byKey: a route BuildRoute already made (Replan), so it is not built twice.
function ns.Assemble(recalc, order, byKey)
  if ns.EnsureClassCards then ns.EnsureClassCards() end
  local db = WLDTDB
  -- a new choice of dungeons (an offer taken inside, a key): the picker's closed draft follows it
  if recalc and ns.PickerResetDraft and not (_G.WLDTPicker and _G.WLDTPicker:IsShown()) then ns.PickerResetDraft() end
  local any = next(db.sel) ~= nil
  -- a run choice lasts only while its dungeon stays picked
  for k in pairs(db.run or {}) do if not db.sel[k] then db.run[k] = nil end end
  if not any then ns.route = nil; return end
  if not order then order, byKey = ns.BuildRoute(db.sel, ns.PlayerWorld()) end
  if not recalc and db.order and #db.order > 0 then
    -- BuildRoute leaves out what is done: the done steps of the saved order come back, so the
    -- list and "<" still show them (after a replan or a /reload)
    local have, log, full = {}, ns.LogEntries(), {}
    for _, n in ipairs(order) do have[n] = true; full[#full + 1] = n end
    for _, k in ipairs(db.order) do
      local n = byKey and byKey[k]
      if n and not have[n] and ns.NodeOK(log, n) then full[#full + 1] = n; have[n] = true end
    end
    order = full
    local rank = {}
    for i, k in ipairs(db.order) do rank[k] = i end
    local known, extra = {}, {}
    for _, n in ipairs(order) do if rank[n.key] then table.insert(known, n) else table.insert(extra, n) end end
    table.sort(known, function(a, b) return rank[a.key] < rank[b.key] end)
    -- respecter les dépendances après le tri (au cas où)
    order = {}
    local placed = {}
    local pending = {}
    for _, n in ipairs(known) do table.insert(pending, n) end
    for _, n in ipairs(extra) do table.insert(pending, n) end
    local inRoute = {}
    for _, n in ipairs(pending) do inRoute[n] = true end
    local guard = 0
    while #pending > 0 and guard < 10000 do
      guard = guard + 1
      local moved = false
      for idx, n in ipairs(pending) do
        local ok = true
        -- a done step never has to come first (a loot done outside before its turn-in)
        for _, d in ipairs(n.deps) do if inRoute[d] and not placed[d] and not (d.ins and ns.NodeOK(log, d)) then ok = false break end end
        if ok then table.insert(order, n); placed[n] = true; table.remove(pending, idx); moved = true; break end
      end
      if not moved then for _, n in ipairs(pending) do table.insert(order, n) end break end
    end
  end
  db.order = {}
  for _, n in ipairs(order) do table.insert(db.order, n.key) end
  local steps = ns.SplitInside(ns.MakeSteps(order))
  StepKeys(steps)
  -- a copy: the route keeps its own choice (the picker's draft or a later edit of db.sel never
  -- changes the running route behind its back)
  local sel = {}
  for k, v in pairs(db.sel) do if v then sel[k] = true end end
  ns.route = { steps = steps, sel = sel, label = Label(sel) }
end

-- run: the picked dungeons to walk through with no quest (the summary's "Guide me through the
-- dungeon"); any other start forgets it, so a plain quest route never grows a dungeon clear.
function ns.StartGuide(run)
  WLDTDB.manual = {}
  WLDTDB.run = {}
  for k in pairs(run or {}) do if WLDTDB.sel and WLDTDB.sel[k] then WLDTDB.run[k] = true end end
  ns.Assemble(true)
  if ns.PickerResetDraft then ns.PickerResetDraft() end
  ns.HidePicker()
  local f = ns.frame
  f.auto, f.view, f.sig = nil, nil, nil
  f:Show(); WLDTDB.hidden = false
  ns.Refresh(true)
  if ns.route then ns.Print(L.ROUTE_BUILT:format(#ns.route.steps, ns.route.label)) end
end

-- The rest of the route planned again from where you stand when a quest changes state (objectives
-- done, taken, turned in): a turn-in that is close and opens the next quest comes first instead of
-- after a detour. Steps already done stay at the top, in their order, so you can still look back.
local questSig
local function QuestSig()
  local log = ns.LogEntries and ns.LogEntries() or {}
  local t = {}
  for id, e in pairs(log) do t[#t + 1] = id .. ":" .. tostring(e.complete or e.state or "") end
  table.sort(t)
  return table.concat(t, ",")
end
-- Returns true when there is nothing left to do (rebuilt, or nothing to replan); false when it has
-- to wait (combat, inside an instance): the caller asks again later. Second value: rebuilt (and
-- refreshed).
local function Replan()
  local db = WLDTDB
  if not db or db.autoReplan == false or not (db.sel and next(db.sel)) or not ns.route then return true end
  if InCombatLockdown and InCombatLockdown() then return false end
  -- "a and f()" keeps only f's first value: the instance type is the second
  local kind
  if GetInstanceInfo then kind = select(2, GetInstanceInfo()) end
  if kind == "party" or kind == "raid" then return false end   -- inside, the boss order is the route
  local f = ns.frame
  if not f then return true end
  -- the step followed now, by key: indexes mean nothing across a rebuild
  local follow = (f.view == nil or f.view == f.auto)
  local old = f.auto and ns.route.steps[f.auto]
  local oldKey = old and old.key
  local seen0 = not follow and f.view and ns.route.steps[f.view]
  local viewKey = seen0 and seen0.key
  local order, byKey = ns.BuildRoute(db.sel, ns.PlayerWorld())
  local log = ns.LogEntries()
  local new, seen, held = {}, {}, {}
  for _, k in ipairs(db.order or {}) do
    local n = byKey and byKey[k]
    if n and ns.NodeOK(log, n) and not seen[n] then
      seen[n] = true
      -- a done line inside a dungeon waits for that dungeon's next visit: alone at the top it
      -- would open a visit of its own (entrance + every boss) before the steps outside
      if n.ins then held[n.ins] = held[n.ins] or {}; table.insert(held[n.ins], n); held[n] = true
      else new[#new + 1] = n end
    end
  end
  for _, n in ipairs(order) do
    if not seen[n] then
      local h = n.ins and held[n.ins]
      if h then for _, x in ipairs(h) do new[#new + 1] = x end; held[n.ins] = nil end
      new[#new + 1] = n; seen[n] = true
    end
  end
  -- nothing left in that dungeon: its done lines stay at the top, as before
  local top = {}
  for _, k in ipairs(db.order or {}) do
    local n = byKey and byKey[k]
    -- only the lines still held (a key twice in the saved order, or an open line dropped from
    -- the route, is never put back on top)
    if n and n.ins and held[n.ins] and held[n] then top[#top + 1] = n; held[n] = nil end
  end
  for j = #top, 1, -1 do table.insert(new, 1, top[j]) end
  db.order = {}
  for _, n in ipairs(new) do db.order[#db.order + 1] = n.key end
  ns.Assemble(false, order, byKey)
  f.auto, f.sig = nil, nil
  if follow then f.view = nil
  elseif viewKey and ns.route then
    -- the step you were looking at, at its new place
    local at
    for i, st in ipairs(ns.route.steps) do if st.key == viewKey then at = i break end end
    f.view = at
  end
  if f.view and ns.route and f.view > #ns.route.steps then f.view = nil end
  -- not silent: the "route finished" message still plays; f.auto is nil, so no step advance is
  -- announced there (indexes moved), only below, by key
  ns.Refresh()
  -- a new current step: the same sound and message as an advance seen by Refresh
  local i, st = ns.CurrentStepIndex()
  if oldKey and st and st.key ~= oldKey and ns.AnnounceStep then ns.AnnounceStep(i) end
  return true, true
end
function ns.Replan()
  if ns.InPass then return ns.InPass(Replan) end
  return Replan()
end

function ns.Recalc()
  ns.Assemble(true)
  local f = ns.frame
  f.auto, f.view, f.sig = nil, nil, nil
  ns.Refresh(true)
  if ns.route then ns.Print(L.ROUTE_BUILT:format(#ns.route.steps, ns.route.label)) end
end

-- "Start the route over" (/wlh reset, the guide's Actions menu and the foot of the step list):
-- the steps ticked by hand and the saved order are forgotten, the route is built from the start
function ns.ResetRoute()
  WLDTDB.manual = {}; WLDTDB.order = nil
  ns.Recalc()
  ns.Print(L.RESET)
end

-- =====================================================================
--  Événements
-- =====================================================================
local ev = CreateFrame("Frame")
for _, e in ipairs({ "PLAYER_LOGIN", "QUEST_LOG_UPDATE", "QUEST_TURNED_IN", "PLAYER_ENTERING_WORLD", "GROUP_ROSTER_UPDATE",
  "PLAYER_LEVEL_UP", "PLAYER_REGEN_ENABLED", "ZONE_CHANGED_NEW_AREA" }) do pcall(ev.RegisterEvent, ev, e) end
pcall(ev.RegisterEvent, ev, "BAG_UPDATE_DELAYED")

-- A loading screen (teleport, portal, instance, /reload) closes the game's special windows, the
-- guide with them: that hide is not the player's choice. Whether the guide was open is noted when
-- the world is left, the hide during the loading screen does not count as "closed", and the guide
-- comes back once the new world is there.
-- The game closes its special windows in its own PLAYER_LEAVING_WORLD handler, which runs before
-- ours: when we look, the guide is already hidden. So every hide is timed, and a hide in the same
-- moment as the world being left counts as "was open".
local lastHide, hooked = nil, false
local function Now() return (GetTime and GetTime()) or 0 end
local function HookHide()
  local f = ns.frame
  if hooked or not (f and f.HookScript) then return end
  hooked = true
  f:HookScript("OnHide", function() lastHide = Now() end)
end
local loading = CreateFrame("Frame")
pcall(loading.RegisterEvent, loading, "PLAYER_LOGIN")
pcall(loading.RegisterEvent, loading, "PLAYER_LEAVING_WORLD")
pcall(loading.RegisterEvent, loading, "PLAYER_ENTERING_WORLD")
loading:SetScript("OnEvent", function(_, e)
  local f = ns.frame
  if e == "PLAYER_LOGIN" then
    C_Timer.After(0, HookHide)
    -- The "DG_Cible" macro written by older versions still holds a raid-marker line (/tm or
    -- SetRaidTarget), blocked on this client (ADDON_ACTION_FORBIDDEN when pressed from a bar). It is
    -- only rewritten when the guide changes step: clean it once at login, out of combat.
    C_Timer.After(5, function()
      if InCombatLockdown and InCombatLockdown() then return end
      if not (GetMacroIndexByName and GetMacroInfo and EditMacro) then return end
      local ok, idx = pcall(GetMacroIndexByName, "DG_Cible")
      if not (ok and type(idx) == "number" and idx > 0) then return end
      local okI, name, _, body = pcall(GetMacroInfo, idx)
      if not (okI and type(body) == "string") then return end
      if not (body:find("/tm", 1, true) or body:find("SetRaidTarget", 1, true)) then return end
      local keep = {}
      for line in body:gmatch("[^\n]+") do
        if not (line:find("^/tm") or line:find("SetRaidTarget", 1, true)) then keep[#keep + 1] = line end
      end
      pcall(EditMacro, idx, name or "DG_Cible", nil, table.concat(keep, "\n"))
    end)
    return
  end
  HookHide()
  if e == "PLAYER_LEAVING_WORLD" then
    local justClosed = lastHide and (Now() - lastHide) < 1
    ns.openAtLeave = ((f and f:IsShown()) or justClosed) and true or false
    if ns.openAtLeave then
      ns.quietHide = true
      -- the hide already saved "closed": not the player's doing (a /reload must find it open too)
      if WLDTDB then WLDTDB.hidden = false end
    end
  elseif ns.openAtLeave ~= nil then
    local wasOpen = ns.openAtLeave
    ns.openAtLeave = nil
    C_Timer.After(0.5, function()
      ns.quietHide = nil
      if wasOpen and ns.frame and not ns.frame:IsShown() and WLDTDB and (not ns.GuideOn or ns.GuideOn()) then
        ns.frame:Show(); WLDTDB.hidden = false
        if ns.Refresh then ns.Refresh() end
      end
    end)
  end
end)
local pending, sawQuest, replanWanted
-- a replan that had to wait (combat, inside an instance) runs once it can
local function ReplanLater()
  if not replanWanted then return false end
  replanWanted = false
  local ok, ran = pcall(ns.Replan)
  if not (ok and ran) then replanWanted = true end
  return ok and ran
end
-- the dungeon guide can be switched off (Settings > General > Modules)
local function GuideOn()
  local WP = ns.Writs and ns.Writs.WP
  return not (WP and WP.ModuleOn) or WP.ModuleOn("dungeons")
end
ns.GuideOn = GuideOn

-- A boss died (Bosses.lua): its step completes, the guide moves on to the next boss.
function ns.OnBossKilled()
  if not (ns.route and GuideOn()) then return end
  local f = ns.frame
  if f and f:IsShown() then ns.Refresh() elseif ns.AfterRefresh then ns.AfterRefresh() end
end
-- The dungeon's NPC spawns are known (Bosses.lua): inside, the steps are placed again so the quest
-- lines tied to no boss sit between the right bosses. Done steps keep their keys.
local indexAfterCombat = false
function ns.OnBossIndexReady()
  if not (ns.route and ns.instIn and GuideOn()) then return end
  -- in combat: placed again once it ends (the index is ready only once per session)
  if InCombatLockdown and InCombatLockdown() then indexAfterCombat = true return end
  indexAfterCombat = false
  local f = ns.frame
  local follow = f and (f.view == nil or f.view == f.auto)
  ns.Assemble(false)
  if f then f.auto, f.sig = nil, nil; if follow then f.view = nil end end
  ns.Refresh(true)
end

-- The guide's dungeons that live in the instance you stand in (several wings can share one
-- instance ID: Scarlet Monastery, Dire Maul, Stratholme). Class-quest cards are left out.
function ns.InstanceKeys()
  local out = {}
  if not GetInstanceInfo then return out, nil end
  local _, kind, _, _, _, _, _, id = GetInstanceInfo()
  if kind ~= "party" and kind ~= "raid" then return out, nil end
  for _, k in ipairs(ns.ORDER) do local d = ns.D[k]; if d and d.inst == id and not d.cq then table.insert(out, k) end end
  return out, id
end
-- How many of the dungeon's quests (for your class) are not turned in yet.
function ns.InstLeft(k)
  local _, cls = UnitClass("player")
  local n = 0
  for _, qid in ipairs(ns.DungeonQuests(k, cls)) do if not ns.IsDone(qid) then n = n + 1 end end
  return n
end

-- Entering a dungeon: the guide opens on it (in the route), or offers it (not in the route).
-- Runs once per entry; leaving the instance resets it.
local OnInstanceEntry
OnInstanceEntry = function()
  local keys, iid = ns.InstanceKeys()
  if #keys == 0 then
    ns.instOffer = nil; ns.instSeen = nil
    -- out of a route dungeon: the "inside" band goes away and the guide goes back to the current step
    local was = ns.instIn
    ns.instIn = nil
    -- the bosses left behind with nothing for you count as skipped: the guide moves on
    if was and ns.SkipOptionalBosses then ns.SkipOptionalBosses(was) end
    -- out of the instance: the replan that waited for it
    ReplanLater()
    local f = ns.frame
    if was and f and f:IsShown() and ns.route then
      ns.Refresh(true)
      local cur = ns.route.steps[f.view or 0]
      if f.auto and (not cur or cur.ins == was) then ns.GoTo(f.auto) end
      ns.Print(L.INST_LEFT:format(ns.DName(was) or was))
    end
    return
  end
  if ns.instSeen and ns.instSeen == iid then return end
  -- after a /reload inside, the saved route is rebuilt a moment later: wait for it
  if not ns.route and WLDTDB.sel and next(WLDTDB.sel) then C_Timer.After(1.5, OnInstanceEntry) return end
  ns.instSeen = iid
  local f = ns.frame
  local sel = ns.route and ns.route.sel or {}
  local inRoute
  for _, k in ipairs(keys) do if sel[k] then inRoute = k break end end
  if inRoute then
    ns.instOffer = nil
    ns.instIn = inRoute
    if not f:IsShown() then f:Show(); WLDTDB.hidden = false end
    ns.Refresh(true)
    local log = ns.LogEntries()
    for i, st in ipairs(ns.route.steps) do
      if st.ins == inRoute and not st.gate and not ns.IsStepDone(log, i) then ns.GoTo(i) break end
    end
    ns.Print(L.INST_IN:format(ns.DName(inRoute) or inRoute))
  else
    local cands = {}
    for _, k in ipairs(keys) do if ns.InstLeft(k) > 0 then table.insert(cands, k) end end
    if #cands == 1 then
      ns.instOffer = cands[1]
      if not f:IsShown() then f:Show(); WLDTDB.hidden = false end
      ns.Print(L.INST_CHAT:format(ns.DName(cands[1]), ns.InstLeft(cands[1])))
    elseif #cands > 1 then ns.instOffer = nil; ns.Print(L.INST_PICK) end
  end
end
ev:SetScript("OnEvent", function(_, e)
  -- module switched off in combat: the deferred action-bar update still has to hide the bar
  if e == "PLAYER_REGEN_ENABLED" and not GuideOn() then
    -- the target button and its key still have to be made (or emptied) once combat ends
    if ns.TargetPending and ns.TargetPending() then ns.UpdateTargetButton() end
    if ns.ActionBarPending and ns.ActionBarPending() and ns.UpdateActionBar then ns.UpdateActionBar() end
    return
  end
  if e ~= "PLAYER_LOGIN" and not GuideOn() then return end
  if e == "PLAYER_LOGIN" then
    DB()
    ns.BuildMain(); ns.BuildNav(); ns.ApplyLooks()
    C_Timer.After(2, function()
      ns.Assemble(false)
      local f = ns.frame
      if WLDTDB.view then f.view = WLDTDB.view end
      -- at login or /reload the guide comes back only if it was open when you left
      if GuideOn() then
        if WLDTDB.hidden == false and ns.route and #ns.route.steps > 0 then f:Show() end
        ns.Refresh(true)
        if not f:IsShown() then ns.AfterRefresh() end
      end
    end)
    local meta = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
    ns.VERSION = meta and meta(ADDON, "Version") or "?"
    ns.Print("v" .. ns.VERSION .. " " .. L.LOADED)
    -- the addon's folder was DungeonGuide up to 1.0.0-beta.3: an old copy left next to WLHelper
    -- would run twice. It is turned off for the next login, with a word on what to do.
    local isLoaded = (C_AddOns and C_AddOns.IsAddOnLoaded) or IsAddOnLoaded
    local disable = (C_AddOns and C_AddOns.DisableAddOn) or DisableAddOn
    if ADDON ~= "DungeonGuide" and isLoaded and isLoaded("DungeonGuide") then
      if disable then pcall(disable, "DungeonGuide") end
      ns.Print(L.OLD_FOLDER)
    end
  elseif e == "PLAYER_REGEN_ENABLED" then
    if ns.TargetPending() then ns.UpdateTargetButton() end
    ReplanLater()
    if indexAfterCombat then pcall(ns.OnBossIndexReady) end
    if ns.frame and ns.frame:IsShown() then ns.Refresh()
    else
      -- the macro and the action bar wait for the end of combat even with the guide closed
      if ns.MacroPending and ns.MacroPending() then ns.UpdateMacro() end
      if ns.ActionBarPending and ns.ActionBarPending() then ns.UpdateActionBar() end
    end
  elseif e == "PLAYER_ENTERING_WORLD" then
    if ns.frame then
      C_Timer.After(1, function()
        if GuideOn() then OnInstanceEntry() end
        if ns.frame:IsShown() or (GuideOn() and ns.route) then ns.Refresh() elseif GuideOn() then ns.AfterRefresh() end
      end)
    end
  elseif ns.frame then
    -- any quest event in the 0.3 s window counts, not only the first event of the window
    if e == "QUEST_LOG_UPDATE" or e == "QUEST_TURNED_IN" then sawQuest = true end
    if pending then return end
    pending = true
    C_Timer.After(0.3, function()
      pending = false
      local quest = sawQuest
      sawQuest = false
      local refreshed
      if quest and GuideOn() then
        local sig = QuestSig()
        if questSig and sig ~= questSig then
          local ok, ran, rebuilt = pcall(ns.Replan)
          if not (ok and ran) then replanWanted = true end
          -- a rebuild refreshes the guide itself
          refreshed = ok and rebuilt
        end
        questSig = sig
      end
      if not refreshed then
        if ns.frame:IsShown() or (GuideOn() and ns.route) then ns.Refresh() elseif GuideOn() then ns.AfterRefresh() end
      end
      ns.RenderPicker()
    end)
  end
end)

-- =====================================================================
--  /wlh textes (debug): every FontString the engine cuts ("...") in the WL Helper windows open now.
--  On demand only: one walk, no OnUpdate. The last result is kept in WLDTDB.debugTexts.
-- =====================================================================
do
  local TAG = "|cffCE1918WL|r "
  local MAX_LINES = 40
  local function secret(v) return issecretvalue ~= nil and issecretvalue(v) end
  local function WL(s) local W = ns.Writs; return (W and W.L) and W.L(s) or s end
  local function Call(obj, method, ...)
    local fn = type(obj) == "table" and obj[method]
    if type(fn) ~= "function" then return nil end
    local ok, v = pcall(fn, obj, ...)
    if not ok or secret(v) then return nil end
    return v
  end
  local function Plain(s)
    if type(s) ~= "string" then return "" end
    s = s:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|T.-|t", ""):gsub("|A.-|a", ""):gsub("\n", " ")
    return s
  end

  -- true: cut by the engine; "limit": wraps to exactly its max lines (a near miss); nil otherwise.
  local function Check(fs)
    local cut
    if type(fs.IsTruncated) == "function" then
      local ok, v = pcall(fs.IsTruncated, fs)
      if ok and v ~= nil then
        if secret(v) then return nil end
        cut = (v == true)
      end
    end
    if cut == nil then
      if Call(fs, "CanWordWrap") == true then cut = false
      else
        local sw, w = ns.TextWidth(fs), Call(fs, "GetWidth")
        if type(w) ~= "number" then return nil end
        cut = w > 0 and sw > w + 1
      end
    end
    if cut then return true end
    local maxL, n = Call(fs, "GetMaxLines"), Call(fs, "GetNumLines")
    if type(maxL) == "number" and maxL > 1 and type(n) == "number" and n >= maxL then return "limit" end
    return nil
  end

  local function Forbidden(obj)
    local fn = type(obj) == "table" and obj.IsForbidden
    if type(fn) ~= "function" then return false end
    local ok, v = pcall(fn, obj)
    return ok and v == true
  end
  local function Join(path, key) return path ~= "" and (path .. "." .. key) or key end

  local function Walk(frame, root, path, depth, out)
    if depth > 25 or Call(frame, "IsShown") ~= true then return end
    if type(frame.GetRegions) == "function" then
      local regions = { pcall(frame.GetRegions, frame) }
      for i = 2, #regions do
        local r = regions[i]
        if Call(r, "GetObjectType") == "FontString" and Call(r, "IsShown") == true then
          local res = Check(r)
          if res then
            local key = ns.KeyOf and ns.KeyOf(frame, r) or nil
            out[#out + 1] = { root = root, path = Join(path, key or ("FontString#" .. (i - 1))), fs = r, limit = (res == "limit") }
          end
        end
      end
    end
    if type(frame.GetChildren) == "function" then
      local children = { pcall(frame.GetChildren, frame) }
      for i = 2, #children do
        local c = children[i]
        if type(c) == "table" and not Forbidden(c) then
          local key = ns.KeyOf and ns.KeyOf(frame, c) or nil
          Walk(c, root, Join(path, key or ((Call(c, "GetObjectType") or "Frame") .. "#" .. (i - 1))), depth + 1, out)
        end
      end
    end
  end

  local function TitleOf(f)
    for _, k in ipairs({ "titleText", "title" }) do
      local t = rawget(f, k)
      if type(t) == "table" then
        local s = Call(t, "GetText")
        if type(s) == "string" and s ~= "" then return Plain(s) end
      end
    end
    local n = Call(f, "GetName")
    return type(n) == "string" and n or "?"
  end

  -- The roots: the window registry, the guide's named frames, then any WL frame or frame the
  -- helpers marked (wlOwned) whose ancestors are not already in the set.
  local function Roots()
    local set, list = {}, {}
    local function add(f)
      if type(f) == "table" and not set[f] and not Forbidden(f) then set[f] = true; list[#list + 1] = f end
    end
    for _, f in ipairs(ns.windows or {}) do add(f) end
    for _, n in ipairs({ "WLHelperHome", "WLDTPicker", "WLDTQuestPicker", "WLDTMinimapButton", "WLGPSArrow" }) do add(_G[n]) end
    add(ns.frame)
    if type(EnumerateFrames) == "function" then
      local ok, f = pcall(EnumerateFrames)
      local guard = 0
      while ok and f and guard < 200000 do
        guard = guard + 1
        if not Forbidden(f) then
          local n = Call(f, "GetName")
          if (type(n) == "string" and n:find("^WL")) or rawget(f, "wlOwned") == true then add(f) end
        end
        ok, f = pcall(EnumerateFrames, f)
      end
    end
    local roots = {}
    for _, f in ipairs(list) do
      local p, inside, depth = Call(f, "GetParent"), false, 0
      while p and depth < 40 do
        if set[p] then inside = true break end
        p, depth = Call(p, "GetParent"), depth + 1
      end
      if not inside then roots[#roots + 1] = f end
    end
    return roots
  end

  local function LinesLabel(fs)
    local wrap, maxL = Call(fs, "CanWordWrap"), Call(fs, "GetMaxLines")
    if wrap == false or maxL == 1 then return WL("(1 ligne)") end
    if type(maxL) ~= "number" or maxL <= 0 then return WL("(sans limite)") end
    return WL("(%d lignes)"):format(maxL)
  end

  -- ns.DebugTexts(arg): arg "all" also lists the texts that fill their max lines exactly.
  -- Returns the number of hits and the report lines.
  function ns.DebugTexts(arg)
    local all = type(arg) == "string" and arg:find("all") ~= nil
    local hits, hidden = {}, 0
    for _, f in ipairs(Roots()) do
      if Call(f, "IsVisible") == true then Walk(f, f, "", 0, hits) else hidden = hidden + 1 end
    end
    -- grouped by window, in the order the windows were found
    local order, byRoot, count = {}, {}, 0
    for _, h in ipairs(hits) do
      if all or not h.limit then
        count = count + 1
        if not byRoot[h.root] then byRoot[h.root] = {}; order[#order + 1] = h.root end
        table.insert(byRoot[h.root], h)
      end
    end
    local lines = {}
    for _, r in ipairs(order) do
      local title = TitleOf(r)
      for _, h in ipairs(byRoot[r]) do
        local fs = h.fs
        local okF, _, size = pcall(fs.GetFont, fs)
        if not okF or type(size) ~= "number" or secret(size) then size = 0 end
        local w, hh = Call(fs, "GetWidth"), Call(fs, "GetHeight")
        local text = Plain(Call(fs, "GetText"))
        if #text > 80 then text = text:sub(1, 80) .. "..." end
        local info = LinesLabel(fs)
        if h.limit then info = info .. " " .. WL("(limite)") end
        lines[#lines + 1] = WL("[%s] %s %dpx %dx%d %s : %s"):format(title, h.path, math.floor(size + 0.5),
          math.floor((type(w) == "number" and w or 0) + 0.5), math.floor((type(hh) == "number" and hh or 0) + 0.5), info, text)
      end
    end
    if WLDTDB then WLDTDB.debugTexts = { time = time and time() or 0, lines = lines } end
    if count == 0 then
      print(TAG .. WL("Aucun texte coupé dans les fenêtres ouvertes."))
    else
      local head
      if count == 1 then head = WL("Texte coupé : 1 dans 1 fenêtre.")
      elseif #order == 1 then head = WL("Textes coupés : %d dans 1 fenêtre."):format(count)
      else head = WL("Textes coupés : %d dans %d fenêtres."):format(count, #order) end
      print(TAG .. head)
      for i = 1, math.min(MAX_LINES, #lines) do print("   " .. lines[i]) end
      local more = #lines - MAX_LINES
      if more == 1 then print("   " .. WL("Et 1 autre : ferme quelques fenêtres puis relance /wlh textes."))
      elseif more > 1 then print("   " .. WL("Et %d autres : ferme quelques fenêtres puis relance /wlh textes."):format(more)) end
    end
    if all and hidden > 0 then
      print("   " .. (hidden == 1 and WL("1 fenêtre cachée n'a pas été vérifiée.") or WL("%d fenêtres cachées n'ont pas été vérifiées."):format(hidden)))
    end
    return count, lines
  end
end

-- =====================================================================
--  Commandes : /wlh (et /dg, /dguide, /wldt, /zfg pour l'habitude) ; /wlh comptoir ... pour la fenêtre Writs (writs)
-- =====================================================================
-- One command, /wlh, and one English word per action (the same in French): dungeons, pick, trade,
-- bags, orders, gps, options, setup, idea, help. Older words (French, clean, comptoir...) still work.
SLASH_WLDUNGEONTOOL1 = "/wlh"
-- WaR LegenD RaidTool (Vulcan) owns /wl: WL Helper takes it only when RaidTool is not installed
do
  local isLoaded = (C_AddOns and C_AddOns.IsAddOnLoaded) or IsAddOnLoaded
  local exists = (C_AddOns and C_AddOns.GetAddOnInfo) or GetAddOnInfo
  local function RaidTool()
    if isLoaded and isLoaded("WarLegendRaidTool") then return true end
    local ok, name, _, _, loadable = pcall(exists or function() end, "WarLegendRaidTool")
    return ok and name ~= nil and loadable ~= false and SLASH_WARLEGENDRT1 ~= nil
  end
  local f = CreateFrame("Frame")
  pcall(f.RegisterEvent, f, "PLAYER_LOGIN")
  f:SetScript("OnEvent", function()
    if not RaidTool() and not SLASH_WARLEGENDRT1 then SLASH_WLDUNGEONTOOL2 = "/wl" end
  end)
end
SlashCmdList.WLDUNGEONTOOL = function(msg)
  if not ns.frame then return end
  -- « réglages », « idée » typed with accents: accents out before lower(), which may touch UTF-8 bytes
  msg = (msg or ""):gsub("é", "e"):gsub("É", "e"):gsub("è", "e"):gsub("È", "e")
  msg = msg:lower():gsub("^%s+", ""):gsub("%s+$", "")
  local cmd, arg = msg:match("^(%S*)%s*(.*)$")
  local WP = ns.Writs and ns.Writs.WP
  if cmd == "" or cmd == "home" or cmd == "accueil" then if WP and WP.ToggleHome then WP.ToggleHome() else ns.ToggleMain() end
  elseif cmd == "donjons" or cmd == "dungeons" or cmd == "guide" then ns.ToggleMain()
  elseif cmd == "choisir" or cmd == "pick" or cmd == "dj" then ns.ShowPicker()
  elseif cmd == "trade" or cmd == "comptoir" or cmd == "c" or cmd == "writs" or cmd == "writ" then if WP then WP.Command(arg) end
  elseif cmd == "sacs" or cmd == "bags" or cmd == "clean" then if WP and WP.Cleaner then WP.Cleaner.Toggle() end
  elseif cmd == "free" or cmd == "place" then if WP and WP.Junk then WP.Junk.Free() end
  elseif cmd == "commandes" or cmd == "orders" or cmd == "cmd" then if WP and WP.ToggleOrders then WP.ToggleOrders() end
  elseif cmd == "events" or cmd == "evenements" or cmd == "lfg" or cmd == "calendar" or cmd == "agenda" then if WP and WP.ToggleEvents then WP.ToggleEvents() end
  elseif cmd == "guild" or cmd == "guilde" then if WP and WP.ToggleGuild then WP.ToggleGuild() end
  elseif cmd == "boss" or cmd == "bosses" then if ns.BossCommand then ns.BossCommand() end
  elseif cmd == "gps" then if WP and WP.StopOrStartGPS then WP.StopOrStartGPS() end
  elseif cmd == "reglages" or cmd == "options" or cmd == "settings" or cmd == "opt" then if WP and WP.ShowOptionsPage then WP.ShowOptionsPage() end
  elseif cmd == "bienvenue" or cmd == "welcome" or cmd == "setup" then if WP and WP.ShowWelcome then WP.ShowWelcome() end
  elseif cmd == "idee" or cmd == "idea" or cmd == "bug" then if WP and WP.Feedback then WP.Feedback(cmd == "bug" and "bug" or "idea") end
  elseif cmd == "textes" or cmd == "texts" or cmd == "truncated" then ns.DebugTexts(arg)
  elseif cmd == "share" then ns.ShareQuests()
  elseif cmd == "tracker" or cmd == "suivi" then
    if WLHelperTracker then WLHelperTracker.Toggle() end
  elseif cmd == "next" then ns.GoTo((ns.frame.view or 1) + 1)
  elseif cmd == "prev" then ns.GoTo((ns.frame.view or 1) - 1)
  elseif cmd == "list" then ns.frame.list:SetShown(not ns.frame.list:IsShown()); WLDTDB.list = ns.frame.list:IsShown(); ns.Render()
  elseif cmd == "recalc" then ns.Recalc()
  elseif cmd == "arrow" then ns.ToggleArrow(); ns.Render()
  elseif cmd == "lang" then ns.SetLang(arg); ns.Print(L.LANG); ns.Render()
  elseif cmd == "minimap" then WLDTDB.hideMinimap = not WLDTDB.hideMinimap; if WLDTMinimapButton then WLDTMinimapButton:SetShown(not WLDTDB.hideMinimap) end
  elseif cmd == "all" or cmd == "tout" then WLDTDB.useful = (WLDTDB.useful == false); ns.Print(WLDTDB.useful and L.USEFUL_ON or L.USEFUL_OFF); ns.Recalc(); if ns.RenderPicker then ns.RenderPicker() end
  elseif cmd == "macro" then WLDTDB.macro = (WLDTDB.macro == false); ns.Print(WLDTDB.macro and L.MACRO_ON or L.MACRO_OFF); ns.UpdateMacro()
  elseif cmd == "reset" then ns.ResetRoute()
  elseif cmd == "help" or cmd == "aide" or cmd == "?" then
    ns.Print("WL Helper v" .. (ns.VERSION or "?"))
    for line in L.HELP:gmatch("[^\n]+") do print("   " .. line) end
    local WL = ns.Writs and ns.Writs.L
    print("   " .. (WL and WL("Debug : /wlh textes liste les textes coupés dans les fenêtres ouvertes (ajoute « all » pour voir aussi ceux à la limite).")
      or "Debug: /wlh texts lists the cut texts in the open windows (add \"all\" to also see those at the limit)."))
    if ns.Writs and ns.Writs.WP and ns.Writs.WP.Help then ns.Writs.WP.Help.Toggle() end
  else ns.Print(L.UNKNOWN_CMD:format(cmd)) end
end

-- =====================================================================
--  Raccourcis clavier (Échap > Options > Raccourcis > AddOns > WLDT)
-- =====================================================================
BINDING_HEADER_WLDT = "|cffce1918WL|r Helper"
BINDING_NAME_WLDT_TOGGLE = ns.L.B_TOGGLE
BINDING_NAME_WLDT_PICK = ns.L.B_PICK
BINDING_NAME_WLDT_NEXT = ns.L.B_NEXTSTEP
BINDING_NAME_WLDT_PREV = ns.L.B_PREV
BINDING_NAME_WLDT_POINTS = ns.L.B_POINTS
BINDING_NAME_WLDT_ARROW = ns.L.B_ARROW
BINDING_NAME_WLDT_TARGET = ns.L.B_TARGET
BINDING_NAME_WLDT_ITEM = ns.L.B_ITEM
function WLDT_Binding(what)
  -- the key bound to WLDT_TARGET clicks WLDTTargetButton through an override binding; this runs
  -- only while the override waits for the end of combat
  if what == "target" then
    if InCombatLockdown and InCombatLockdown() then ns.Print(L.TARGET_LATER) else ns.ApplyTargetBinding() end
    return
  end
  -- the key bound to WLDT_ITEM clicks the action bar's first quest item button (UI.lua, override
  -- binding set out of combat); this runs only while the step has no item or the bar waits
  if what == "item" then
    if InCombatLockdown and InCombatLockdown() then
      ns.Print((ns.ActionBarPending and ns.ActionBarPending()) and L.ITEM_LATER or L.ITEM_NONE)
    else
      if ns.UpdateActionBar then ns.UpdateActionBar() end
      if not (ns.ItemBindingButton and ns.ItemBindingButton()) then ns.Print(L.ITEM_NONE) end
    end
    return
  end
  if not ns.frame then return end
  if what == "toggle" then ns.ToggleMain()
  elseif what == "pick" then ns.TogglePicker()
  elseif what == "next" then ns.GoTo((ns.frame.view or 1) + 1)
  elseif what == "prev" then ns.GoTo((ns.frame.view or 1) - 1)
  elseif what == "points" then ns.PlacePoints()
  elseif what == "arrow" then ns.ToggleArrow(); ns.Render() end
end

-- The game's key bindings (Actions menu, right-click on a bar button with no key): the Settings
-- key bindings page on this client, else the old KeyBindingFrame; the path in the chat either way
-- (neither scrolls to the AddOns section). Never in combat.
function ns.OpenKeyBindings()
  if InCombatLockdown and InCombatLockdown() then ns.Print(L.KEYS_COMBAT) return false end
  local opened = false
  local S = rawget(_G, "Settings")
  if type(S) == "table" and type(S.OpenToCategory) == "function" and S.KEYBINDINGS_CATEGORY_ID ~= nil then
    opened = pcall(S.OpenToCategory, S.KEYBINDINGS_CATEGORY_ID) and true or false
    local P = rawget(_G, "SettingsPanel")
    if opened and P and P.IsShown then opened = P:IsShown() and true or false end
  end
  if not opened then
    if not rawget(_G, "KeyBindingFrame") and type(rawget(_G, "KeyBindingFrame_LoadUI")) == "function" then
      pcall(KeyBindingFrame_LoadUI)
    end
    local K = rawget(_G, "KeyBindingFrame")
    if K and type(ShowUIPanel) == "function" then
      opened = pcall(ShowUIPanel, K) and true or false
      if opened and K.IsShown then opened = K:IsShown() and true or false end
    end
  end
  ns.Print(opened and L.KEYS_OPENED or L.KEYS_HINT)
  return opened
end

-- =====================================================================
--  "Target and mark the step's target": a hidden secure button (type macro) whose text is the
--  guide's target macro (ns.TargetMacroText). Created, changed and bound out of combat only: in
--  combat the change waits for PLAYER_REGEN_ENABLED. The WLDT_TARGET key clicks it through an
--  override binding owned by the button.
-- =====================================================================
do
  local btn, pending, text, bindPending, applied, busy
  local function Locked() return InCombatLockdown and InCombatLockdown() end
  local function Ensure()
    if btn then return btn end
    if Locked() then pending = true return nil end
    btn = CreateFrame("Button", "WLDTTargetButton", UIParent, "SecureActionButtonTemplate")
    btn:SetSize(1, 1)
    btn:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -10, 10)
    btn:Hide()
    -- both directions, like the other secure buttons: the template keeps the one the game's
    -- ActionButtonUseKeyDown option asks for now (the macro does nothing more if run twice)
    btn:RegisterForClicks("AnyUp", "AnyDown")
    btn:SetAttribute("type", "macro")
    btn:SetAttribute("macrotext", "")
    return btn
  end
  function ns.TargetPending() return pending or bindPending end
  -- The key bound to WLDT_TARGET clicks the button (override binding, out of combat).
  -- Setting override bindings fires UPDATE_BINDINGS again: only rebind when the keys changed.
  function ns.ApplyTargetBinding()
    if busy then return end
    if not Ensure() then bindPending = true return end
    if Locked() then bindPending = true return end
    bindPending = false
    if not (ClearOverrideBindings and SetOverrideBindingClick and GetBindingKey) then return end
    local keys = { GetBindingKey("WLDT_TARGET") }
    local list = {}
    for _, k in ipairs(keys) do if type(k) == "string" and k ~= "" then list[#list + 1] = k end end
    local sig = table.concat(list, " ")
    if sig == applied then return end
    busy = true
    local ok, err = pcall(function()
      ClearOverrideBindings(btn)
      for _, k in ipairs(list) do SetOverrideBindingClick(btn, false, k, "WLDTTargetButton", "LeftButton") end
    end)
    busy = false
    if ok then applied = sig else error(err, 0) end
  end
  function ns.UpdateTargetButton()
    if Locked() then pending = true return end
    if not Ensure() then return end
    if bindPending then ns.ApplyTargetBinding() end
    pending = false
    -- guide switched off: no macro left behind (the key does nothing)
    local ok, body = true, ""
    if not (ns.GuideOn and not ns.GuideOn()) then ok, body = pcall(ns.TargetMacroText) end
    if not ok or type(body) ~= "string" then body = "" end
    if body ~= text then text = body; btn:SetAttribute("macrotext", body) end
  end
  local ev2 = CreateFrame("Frame")
  for _, e in ipairs({ "PLAYER_LOGIN", "UPDATE_BINDINGS" }) do pcall(ev2.RegisterEvent, ev2, e) end
  ev2:SetScript("OnEvent", function(_, e)
    if busy then return end
    if e == "PLAYER_LOGIN" then Ensure() end
    ns.ApplyTargetBinding()
    -- the bar's item key and its buttons' right-click follow the bindings too (UI.lua)
    if e == "UPDATE_BINDINGS" and ns.RefreshActionKeys then ns.RefreshActionKeys() end
  end)
end

-- After each refresh of the guide (and on quest changes while it is closed): the target button's
-- text and the tracker follow the current step.
local function AfterRefresh()
  if ns.GuideOn and not ns.GuideOn() then
    -- the target button is emptied (out of combat) so a switched-off guide leaves no live macro
    ns.UpdateTargetButton()
    if WLHelperTracker and WLHelperTracker.Refresh then pcall(WLHelperTracker.Refresh) end
    return
  end
  ns.UpdateTargetButton()
  if WLHelperTracker and WLHelperTracker.Refresh then WLHelperTracker.Refresh() end
end
-- one pass: the step states read by the target button and the tracker are those of the refresh
function ns.AfterRefresh() return ns.InPass(AfterRefresh) end
do
  local refresh = ns.Refresh
  if refresh then
    ns.Refresh = function(...)
      local args = { ... }
      ns.InPass(function()
        refresh(unpack(args))
        AfterRefresh()
      end)
    end
  end
end
