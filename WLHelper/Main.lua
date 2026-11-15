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
      st.key = "g:" .. st.gate .. ":" .. (nxt and nxt.acts[1] and nxt.acts[1].key or i)
    else
      st.key = st.acts[1] and st.acts[1].key or ("s" .. i)
    end
  end
end

-- Reconstruit les étapes ; garde l'ordre sauvegardé si possible.
function ns.Assemble(recalc)
  if ns.EnsureClassCards then ns.EnsureClassCards() end
  local db = WLDTDB
  local any = next(db.sel) ~= nil
  if not any then ns.route = nil; return end
  local start = ns.PlayerWorld()
  local order = ns.BuildRoute(db.sel, start)
  if not recalc and db.order and #db.order > 0 then
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
        for _, d in ipairs(n.deps) do if inRoute[d] and not placed[d] then ok = false break end end
        if ok then table.insert(order, n); placed[n] = true; table.remove(pending, idx); moved = true; break end
      end
      if not moved then for _, n in ipairs(pending) do table.insert(order, n) end break end
    end
  end
  db.order = {}
  for _, n in ipairs(order) do table.insert(db.order, n.key) end
  local steps = ns.SplitInside(ns.MakeSteps(order))
  StepKeys(steps)
  ns.route = { steps = steps, sel = db.sel, label = Label(db.sel) }
end

function ns.StartGuide()
  WLDTDB.manual = {}
  ns.Assemble(true)
  ns.HidePicker()
  local f = ns.frame
  f.auto, f.view, f.sig = nil, nil, nil
  f:Show(); WLDTDB.hidden = false
  ns.Refresh(true)
  if ns.route then ns.Print(L.ROUTE_BUILT:format(#ns.route.steps, ns.route.label)) end
end

function ns.Recalc()
  ns.Assemble(true)
  local f = ns.frame
  f.auto, f.view, f.sig = nil, nil, nil
  ns.Refresh(true)
  if ns.route then ns.Print(L.ROUTE_BUILT:format(#ns.route.steps, ns.route.label)) end
end

-- =====================================================================
--  Événements
-- =====================================================================
local ev = CreateFrame("Frame")
for _, e in ipairs({ "PLAYER_LOGIN", "QUEST_LOG_UPDATE", "QUEST_TURNED_IN", "PLAYER_ENTERING_WORLD", "GROUP_ROSTER_UPDATE",
  "PLAYER_LEVEL_UP", "PLAYER_REGEN_ENABLED", "ZONE_CHANGED_NEW_AREA" }) do pcall(ev.RegisterEvent, ev, e) end
pcall(ev.RegisterEvent, ev, "BAG_UPDATE_DELAYED")
local pending
-- the dungeon guide can be switched off (Settings > General > Modules)
local function GuideOn()
  local WP = ns.Writs and ns.Writs.WP
  return not (WP and WP.ModuleOn) or WP.ModuleOn("dungeons")
end
ns.GuideOn = GuideOn

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
        if ns.frame:IsShown() then ns.Refresh() end
      end)
    end
  elseif ns.frame and not pending then
    pending = true
    C_Timer.After(0.3, function()
      pending = false
      if ns.frame:IsShown() then ns.Refresh() end
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
        local sw, w = Call(fs, "GetStringWidth"), Call(fs, "GetWidth")
        if type(sw) ~= "number" or type(w) ~= "number" then return nil end
        cut = w > 0 and sw > w + 0.5
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
  elseif cmd == "gps" then if WP and WP.StopOrStartGPS then WP.StopOrStartGPS() end
  elseif cmd == "reglages" or cmd == "options" or cmd == "settings" or cmd == "opt" then if WP and WP.ShowOptionsPage then WP.ShowOptionsPage() end
  elseif cmd == "bienvenue" or cmd == "welcome" or cmd == "setup" then if WP and WP.ShowWelcome then WP.ShowWelcome() end
  elseif cmd == "idee" or cmd == "idea" or cmd == "bug" then if WP and WP.Feedback then WP.Feedback(cmd == "bug" and "bug" or "idea") end
  elseif cmd == "textes" or cmd == "texts" or cmd == "truncated" then ns.DebugTexts(arg)
  elseif cmd == "share" then ns.ShareQuests()
  elseif cmd == "next" then ns.GoTo((ns.frame.view or 1) + 1)
  elseif cmd == "prev" then ns.GoTo((ns.frame.view or 1) - 1)
  elseif cmd == "list" then ns.frame.list:SetShown(not ns.frame.list:IsShown()); WLDTDB.list = ns.frame.list:IsShown(); ns.Render()
  elseif cmd == "recalc" then ns.Recalc()
  elseif cmd == "arrow" then ns.ToggleArrow(); ns.Render()
  elseif cmd == "lang" then ns.SetLang(arg); ns.Print(L.LANG); ns.Render()
  elseif cmd == "minimap" then WLDTDB.hideMinimap = not WLDTDB.hideMinimap; if WLDTMinimapButton then WLDTMinimapButton:SetShown(not WLDTDB.hideMinimap) end
  elseif cmd == "all" or cmd == "tout" then WLDTDB.useful = (WLDTDB.useful == false); ns.Print(WLDTDB.useful and L.USEFUL_ON or L.USEFUL_OFF); ns.Recalc(); if ns.RenderPicker then ns.RenderPicker() end
  elseif cmd == "macro" then WLDTDB.macro = (WLDTDB.macro == false); ns.Print(WLDTDB.macro and L.MACRO_ON or L.MACRO_OFF); ns.UpdateMacro()
  elseif cmd == "reset" then WLDTDB.manual = {}; WLDTDB.order = nil; ns.Recalc(); ns.Print(L.RESET)
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
function WLDT_Binding(what)
  if not ns.frame then return end
  if what == "toggle" then ns.ToggleMain()
  elseif what == "pick" then ns.TogglePicker()
  elseif what == "next" then ns.GoTo((ns.frame.view or 1) + 1)
  elseif what == "prev" then ns.GoTo((ns.frame.view or 1) - 1)
  elseif what == "points" then ns.PlacePoints()
  elseif what == "arrow" then ns.ToggleArrow(); ns.Render() end
end
