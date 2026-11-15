-- Navigation : points (TomTom, Naowh Forever comme /way, sinon point de carte), flèche (le GPS de WL Helper), bouton de minimap.
local ADDON, ns = ...
local L, T = ns.L, ns.T_

-- =====================================================================
--  Points de passage
-- =====================================================================
local handles = {}
ns.active = {}
function ns.PKey(m, x, y) return m .. ":" .. x .. ":" .. y end
function ns.HasTomTom() return TomTom and TomTom.AddWaypoint and true or false end

local function Clear()
  if TomTom and TomTom.RemoveWaypoint then
    for _, h in ipairs(handles) do pcall(TomTom.RemoveWaypoint, TomTom, h) end
  end
  wipe(handles); wipe(ns.active)
end

local function Add(m, x, y, label, first)
  if ns.HasTomTom() then
    local ok, h = pcall(TomTom.AddWaypoint, TomTom, m, x / 100, y / 100,
      { title = label, persistent = false, minimap = true, world = true, from = ADDON })
    if ok and h then table.insert(handles, h) end
    return true
  end
  if not first then return end
  local NF = _G.NaowhForever
  if NF and NF.PlaceWaypoint and pcall(NF.PlaceWaypoint, label, m, x, y, nil) then return true end
  if C_Map and C_Map.SetUserWaypoint and UiMapPoint and (not C_Map.CanSetUserWaypointOnMap or C_Map.CanSetUserWaypointOnMap(m)) then
    C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(m, x / 100, y / 100))
    if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then C_SuperTrack.SetSuperTrackedUserWaypoint(true) end
    return true
  end
end

-- pts = { {m,x,y,label}, ... } ; sans TomTom un seul point (n° idx)
function ns.SetPoints(pts, quiet, idx)
  Clear()
  if #pts == 0 then
    if not quiet then ns.Print(L.NOPOINT) end
    ns.SetArrow(nil)
    return
  end
  if ns.HasTomTom() then
    for _, p in ipairs(pts) do Add(p[1], p[2], p[3], p[4]); ns.active[ns.PKey(p[1], p[2], p[3])] = true end
    ns.SetArrow(pts[1])
  else
    idx = math.max(1, math.min(#pts, idx or 1))
    local p = pts[idx]
    Add(p[1], p[2], p[3], p[4], true)
    ns.active[ns.PKey(p[1], p[2], p[3])] = true
    ns.SetArrow(p)
    if not quiet and #pts > 1 then
      ns.Print(L.POINT_N:format(idx, #pts, p[4] or "", p[2], p[3], L.POINT_MORE))
    end
  end
end

-- =====================================================================
--  Flèche : le GPS de WL Helper (Writs/Route.lua, Writs/Arrow.lua), partagé avec les writs.
--  Il passe par les vols connus, les zeppelins, les bateaux et les téléportations.
-- =====================================================================
local function GPS() return ns.Writs and ns.Writs.WP and ns.Writs.WP.GPS end

-- Pas de flèche pour les donjons quand le guide est fermé ou la flèche coupée (bouton « Flèche »
-- ou le x de la flèche) : ça tient après un /reload.
function ns.SetArrow(p)
  local G = GPS()
  if not G then return end
  if p and WLDTDB.arrow ~= false and not WLDTDB.hidden then
    G.GoPoint(p[1], p[2], p[3], p[4], "dungeon")
  else
    G.Stop("dungeon")
  end
end


function ns.ToggleArrow()
  WLDTDB.arrow = not (WLDTDB.arrow ~= false)
  if WLDTDB.arrow == false then
    local G = GPS()
    if G then G.Stop("dungeon") end
  elseif ns.frame then
    ns.frame.sig = nil   -- the guide points its current step again
    ns.Refresh()
  end
end

-- =====================================================================
--  Bouton de minimap
-- =====================================================================
local function BuildMinimap()
  local b = CreateFrame("Button", "WLDTMinimapButton", Minimap)
  b:SetSize(32, 32); b:SetFrameStrata("MEDIUM"); b:SetFrameLevel(8)
  b:RegisterForClicks("LeftButtonUp", "RightButtonUp"); b:RegisterForDrag("LeftButton")
  b.bg = b:CreateTexture(nil, "BACKGROUND"); b.bg:SetSize(22, 22); b.bg:SetPoint("CENTER")
  b.bg:SetColorTexture(0.05, 0.06, 0.07, 0.95)
  b.icon = b:CreateTexture(nil, "ARTWORK"); b.icon:SetSize(20, 20); b.icon:SetPoint("CENTER")
  b.icon:SetTexture("Interface\\AddOns\\" .. ADDON .. "\\Media\\Logo64")   -- the War Legend skull
  b.ring = b:CreateTexture(nil, "OVERLAY"); b.ring:SetSize(54, 54); b.ring:SetPoint("TOPLEFT")
  b.ring:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
  b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
  local function place()
    local a = math.rad(WLDTDB.mmAngle or 200)
    local r = (Minimap:GetWidth() / 2) + 6
    b:ClearAllPoints(); b:SetPoint("CENTER", Minimap, "CENTER", math.cos(a) * r, math.sin(a) * r)
  end
  place()
  b:SetScript("OnDragStart", function(self)
    self:SetScript("OnUpdate", function()
      local mx, my = Minimap:GetCenter()
      local cx, cy = GetCursorPosition()
      local s = Minimap:GetEffectiveScale()
      WLDTDB.mmAngle = math.deg(math.atan2(cy / s - my, cx / s - mx))
      place()
    end)
  end)
  b:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
  -- click: WL Helper's home; right-click: a menu to each module; Shift-click: the Trading Post
  b:SetScript("OnClick", function(self, btn)
    local WP = ns.Writs and ns.Writs.WP
    if not (WP and WP.ToggleHome) then ns.ToggleMain(); return end
    if IsShiftKeyDown() then WP.Toggle()
    elseif btn == "RightButton" then WP.MinimapMenu(self)
    else WP.ToggleHome() end
  end)
  b:SetScript("OnEnter", function(self)
    local WP = ns.Writs and ns.Writs.WP
    if WP and WP.MinimapTooltip then WP.MinimapTooltip(self)
    else ns.ShowTip(self, { "WL Helper", { L.MM_TT3, 0.6, 0.6, 0.6 } }) end
  end)
  b:SetScript("OnLeave", ns.HideTip)
  b:SetShown(not WLDTDB.hideMinimap)
end

function ns.BuildNav()
  BuildMinimap()
end
