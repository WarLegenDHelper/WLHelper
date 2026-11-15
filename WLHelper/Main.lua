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
  for _, k in ipairs(ns.ORDER) do if sel[k] then table.insert(names, ns.D[k].short or ns.DName(k)) end end
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
  "PLAYER_LEVEL_UP", "PLAYER_REGEN_ENABLED", "ZONE_CHANGED_NEW_AREA" }) do ev:RegisterEvent(e) end
pcall(ev.RegisterEvent, ev, "BAG_UPDATE_DELAYED")
local pending
-- the dungeon guide can be switched off (Settings > General > Modules)
local function GuideOn()
  local WP = ns.Writs and ns.Writs.WP
  return not (WP and WP.ModuleOn) or WP.ModuleOn("dungeons")
end
ns.GuideOn = GuideOn
ev:SetScript("OnEvent", function(_, e)
  if e ~= "PLAYER_LOGIN" and not GuideOn() then return end
  if e == "PLAYER_LOGIN" then
    DB()
    ns.BuildMain(); ns.BuildNav(); ns.ApplyLooks()
    C_Timer.After(2, function()
      ns.Assemble(false)
      local f = ns.frame
      if WLDTDB.view then f.view = WLDTDB.view end
      -- the guide never opens by itself at login or /reload: /wl, the home page or the minimap open it
      if GuideOn() then ns.Refresh(true) end
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
--  Commandes : /wl (et /dg, /dguide, /wldt, /zfg pour l'habitude) ; /wl comptoir ... pour le Comptoir (writs)
-- =====================================================================
SLASH_WLDUNGEONTOOL1 = "/wl"
SLASH_WLDUNGEONTOOL5 = "/dg"
SLASH_WLDUNGEONTOOL2 = "/dguide"
SLASH_WLDUNGEONTOOL3 = "/wldt"
SLASH_WLDUNGEONTOOL4 = "/zfg"
SlashCmdList.WLDUNGEONTOOL = function(msg)
  if not ns.frame then return end
  -- « réglages », « idée » typed with accents: accents out before lower(), which may touch UTF-8 bytes
  msg = (msg or ""):gsub("é", "e"):gsub("É", "e"):gsub("è", "e"):gsub("È", "e")
  msg = msg:lower():gsub("^%s+", ""):gsub("%s+$", "")
  local cmd, arg = msg:match("^(%S*)%s*(.*)$")
  local WP = ns.Writs and ns.Writs.WP
  -- one root, French and English words; the old ones (clean, writs, comptoir, dj) still work
  if cmd == "" or cmd == "home" or cmd == "accueil" then if WP and WP.ToggleHome then WP.ToggleHome() else ns.ToggleMain() end
  elseif cmd == "donjons" or cmd == "dungeons" or cmd == "guide" then ns.ToggleMain()
  elseif cmd == "choisir" or cmd == "pick" or cmd == "dj" then ns.ShowPicker()
  elseif cmd == "trade" or cmd == "comptoir" or cmd == "c" or cmd == "writs" or cmd == "writ" then if WP then WP.Command(arg) end
  elseif cmd == "sacs" or cmd == "bags" or cmd == "clean" then if WP and WP.Cleaner then WP.Cleaner.Toggle() end
  elseif cmd == "commandes" or cmd == "orders" or cmd == "cmd" then if WP and WP.ToggleOrders then WP.ToggleOrders() end
  elseif cmd == "gps" then if WP and WP.StopOrStartGPS then WP.StopOrStartGPS() end
  elseif cmd == "reglages" or cmd == "options" or cmd == "settings" or cmd == "opt" then if WP and WP.ShowOptionsPage then WP.ShowOptionsPage() end
  elseif cmd == "idee" or cmd == "idea" or cmd == "bug" then if WP and WP.Feedback then WP.Feedback(cmd == "bug" and "bug" or "idea") end
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
  else ns.Print(L.UNKNOWN_CMD:format(cmd)) end
end

-- =====================================================================
--  Raccourcis clavier (Échap > Options > Raccourcis > AddOns > WLDT)
-- =====================================================================
BINDING_HEADER_WLDT = "|cffce1918WL|r Helper"
BINDING_NAME_WLDT_TOGGLE = ns.L.B_TOGGLE
BINDING_NAME_WLDT_PICK = ns.L.B_PICK
BINDING_NAME_WLDT_NEXT = ns.L.B_NEXT
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
