-- Fenêtre du guide : une étape à la fois, liste des étapes, boutons de ciblage / objet / GPS.
local ADDON, ns = ...
local L, T = ns.L, ns.T_
local Text, Tex, Button, Hex = ns.Text, ns.Tex, ns.Button, ns.Hex

local W, PAD, MAXROWS = 480, 14, 30
local CARD_MAX = 470
local W0, CARD0 = 480, 470
local LISTW, LISTROWS, LISTH = 270, 30, 20
local f
ns.route = nil   -- { steps = {...}, sel = {...} }

local DCOL = {}
local PALETTE = { { 1.00, 0.62, 0.25 }, { 0.45, 0.72, 1.00 }, { 0.72, 0.48, 1.00 }, { 0.40, 0.90, 0.55 }, { 1.00, 0.45, 0.55 }, { 0.95, 0.85, 0.35 } }
local function DColor(dkey)
  if not dkey then return T.accent end
  if not DCOL[dkey] then
    local n = 0; for _ in pairs(DCOL) do n = n + 1 end
    DCOL[dkey] = PALETTE[(n % #PALETTE) + 1]
  end
  return DCOL[dkey]
end
ns.DColor = DColor

function ns.Print(msg) print("|cff0cd29dDG|r " .. tostring(msg)) end

-- =====================================================================
--  État des étapes
-- =====================================================================
local function Steps() return ns.route and ns.route.steps or {} end
local function Manual(st) return WLDTDB.manual[st.key] end
local function SetManual(st, v) WLDTDB.manual[st.key] = v or nil end

local function InInstanceOf(dkey)
  local d = ns.D[dkey]
  if not (d and GetInstanceInfo) then return false end
  local _, _, _, _, _, _, _, id = GetInstanceInfo()
  return id ~= nil and id == d.inst
end

local function StepAuto(log, st)
  if #st.acts == 0 then return false end
  for _, n in ipairs(st.acts) do if not ns.NodeOK(log, n) then return false end end
  return true
end

local function IsStepDone(log, i)
  local st = Steps()[i]
  if not st then return false end
  if Manual(st) then return true end
  if st.gate then
    if InInstanceOf(st.gate) then SetManual(st, true) return true end
    local nxt = Steps()[i + 1]
    if nxt and StepAuto(log, nxt) then return true end
    return StepAuto(log, st)
  end
  return StepAuto(log, st)
end
ns.IsStepDone = IsStepDone

local function FirstOpen(log)
  local s = Steps()
  for i = 1, #s do if not IsStepDone(log, i) then return i end end
  return #s
end

local function StepPoints(log, st, all)
  local pts, seen = {}, {}
  if st.gate then
    local d = ns.D[st.gate]
    if d and d.e and d.e.m then table.insert(pts, { d.e.m, d.e.x, d.e.y, ns.DName(st.gate) }) end
    return pts
  end
  for _, n in ipairs(st.acts) do
    if n.loc and n.loc.m and (all or not ns.NodeOK(log, n)) then
      local k = ns.PKey(n.loc.m, n.loc.x, n.loc.y)
      if not seen[k] then seen[k] = true; table.insert(pts, { n.loc.m, n.loc.x, n.loc.y, n.npc or ns.QName(n.q) }) end
    end
  end
  if #pts == 0 and st.ins then
    local d = ns.D[st.ins]
    if d and d.e and d.e.m and not InInstanceOf(st.ins) then table.insert(pts, { d.e.m, d.e.x, d.e.y, ns.DName(st.ins) }) end
  end
  return pts
end
ns.StepPoints = StepPoints

-- =====================================================================
--  Textes d'une étape
-- =====================================================================
local function ZoneName(m)
  local info = C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(m)
  return info and info.name or ""
end

local function StepTitle(st)
  if st.gate then return L.GATE_T:format(ns.DName(st.gate)) end
  if st.split then
    local pr = st.parts and st.parts > 1 and ("  (" .. st.part .. "/" .. st.parts .. ")") or ""
    if st.bossIdx == 0 then return L.IN_START .. pr end
    if st.bossIdx == 999 then return L.IN_TRASH .. pr end
    return L.BOSS_STEP:format(st.bossName or "?") .. pr
  end
  if st.ins then
    local dn = ns.DName(st.ins)
    if st.inner then return ns.Upper(dn) end
    local allOuter = true
    for _, n in ipairs(st.acts) do if n.kind ~= "c" or n.outer == false then allOuter = false end end
    return allOuter and L.INSIDE_OUTER_T:format(dn) or ns.Upper(dn)
  end
  local names, seen = {}, {}
  for _, n in ipairs(st.acts) do
    local nm = n.npc and n.npc:gsub(",.*$", "")
    if nm and not seen[nm] then seen[nm] = true; table.insert(names, nm) end
  end
  local zone = st.loc and ZoneName(st.loc.m) or ""
  local who = table.concat(names, ", ")
  if #who > 60 then who = who:sub(1, 57) .. "..." end
  if zone ~= "" then return zone .. " : " .. who end
  return who
end
ns.StepTitle = StepTitle

-- =====================================================================
--  Fenêtre
-- =====================================================================
local KTAG = { a = "TAKE", c = "DO", o = "OUTSIDE", t = "TURNIN", h = "HAVE", i = "ITEM" }
local SLABEL = { none = "S_NONE", on = "S_ON", ready = "S_READY", done = "S_DONE" }
local SCOL = { none = "|cffff9933", on = "|cff66b3ff", ready = "|cff59e67a", done = "|cff59e67a" }

local Render

function ns.GoTo(i)
  local n = #Steps()
  if n == 0 then return end
  f.view = math.max(1, math.min(n, i))
  f.scroll.offset = 0
  Render()
end

local function NodeTargets(n)
  if n.tgt then return n.tgt end
  if n.kind == "b" then return n.targets end
  if n.kind == "i" then return nil end
  local q = ns.Q[n.q]
  if n.kind == "a" or n.kind == "t" or n.kind == "h" then
    if n.npc and not n.ins then return { (n.npc:gsub(" %(.*%)", ""):gsub(",.*$", "")) } end
    if n.kind == "t" and n.ins and n.npc then return { n.npc } end
    return nil
  end
  local out, seen = {}, {}
  local objs = q and q.o or {}
  if n.kind == "o" and n.obj then objs = { n.obj } end
  if n.oneObj then objs = { n.oneObj } end
  for _, o in ipairs(objs) do
    if n.kind == "c" and o.w and not o.ins and not o.outer then
      -- objectif fait dehors : pas de cible dans le donjon
    else
    for _, t in ipairs(o.t or {}) do if not seen[t] then seen[t] = true; table.insert(out, t) end end
    for _, s in ipairs(o.src or {}) do if s[1] and not seen[s[1]] and #out < 4 then seen[s[1]] = true; table.insert(out, s[1]) end end
    end
  end
  return out[1] and out or nil
end

local function ObjectiveLines(n)
  local q = ns.Q[n.q]; if not q then return {} end
  local lines = {}
  local objs = q.o or {}
  if n.kind == "o" and n.obj then objs = { n.obj } end
  if n.oneObj then objs = { n.oneObj } end
  for _, o in ipairs(objs) do
    local s = (o.c and o.c > 1 and (o.c .. " x ") or "") .. (o.n or "")
    if o.src and o.src[1] then
      local srcs = {}
      for _, x in ipairs(o.src) do
        table.insert(srcs, x[1] .. ((x[2] and x[2] > 0 and x[2] < 100) and (" " .. math.floor(x[2] + 0.5) .. "%") or ""))
      end
      s = s .. "  |cff9a9a9a(" .. L.TT_DROPS:format(table.concat(srcs, ", ")) .. ")|r"
    end
    if s ~= "" then table.insert(lines, s) end
  end
  return lines
end

local function BuildList()
  local l = CreateFrame("Frame", nil, f)
  l:SetWidth(LISTW)
  l:SetPoint("TOPRIGHT", f, "TOPLEFT", -4, 0); l:SetPoint("BOTTOMRIGHT", f, "BOTTOMLEFT", -4, 0)
  ns.Flat(l, T.bg)
  l.head = Tex(l, "ARTWORK", T.header); l.head:SetPoint("TOPLEFT", 1, -1); l.head:SetPoint("TOPRIGHT", -1, -1); l.head:SetHeight(28)
  l.title = Text(l, 12, T.dim, true); l.title:SetPoint("LEFT", l.head, "LEFT", 10, 0); l.title:SetText(L.STEPS)
  l.rows, l.offset = {}, 0
  for r = 1, LISTROWS do
    local row = CreateFrame("Button", nil, l)
    row:SetHeight(LISTH)
    row:SetPoint("TOPLEFT", 1, -30 - (r - 1) * LISTH); row:SetPoint("TOPRIGHT", -1, -30 - (r - 1) * LISTH)
    row.sel = Tex(row, "BACKGROUND", { 1, 1, 1, 0.06 }); row.sel:SetAllPoints()
    row.bar = Tex(row, "ARTWORK", T.accent); row.bar:SetPoint("TOPLEFT"); row.bar:SetPoint("BOTTOMLEFT"); row.bar:SetWidth(2); ns.Accent(row.bar)
    row.hl = Tex(row, "HIGHLIGHT", { 1, 1, 1, 0.05 }); row.hl:SetAllPoints()
    row.pip = Tex(row, "ARTWORK", { 1, 1, 1 }); row.pip:SetSize(6, 6); row.pip:SetPoint("LEFT", 10, 0)
    row.check = row:CreateTexture(nil, "OVERLAY"); row.check:SetSize(13, 13); row.check:SetPoint("LEFT", 7, 0)
    row.check:SetTexture("Interface\\RAIDFRAME\\ReadyCheck-Ready")
    row.num = Text(row, 11, T.dim); row.num:SetPoint("LEFT", 22, 0); row.num:SetWidth(24); row.num:SetJustifyH("RIGHT"); row.num:SetJustifyV("MIDDLE")
    row.txt = Text(row, 12, T.text); row.txt:SetPoint("LEFT", 52, 0); row.txt:SetPoint("RIGHT", -6, 0)
    row.txt:SetWordWrap(false); row.txt:SetJustifyV("MIDDLE")
    row:SetScript("OnClick", function(self) ns.GoTo(self.i) end)
    l.rows[r] = row
  end
  l:EnableMouseWheel(true)
  l:SetScript("OnMouseWheel", function(self, delta)
    local max = math.max(0, #Steps() - (self.visible or 1))
    self.offset = math.max(0, math.min(max, self.offset - delta * 3))
    Render()
  end)
  f.list = l
end

local function RenderList(log)
  local l = f.list
  if not l:IsShown() then return end
  local steps = Steps()
  local avail = math.max(1, math.floor((f:GetHeight() - 34) / LISTH))
  l.visible = math.min(avail, LISTROWS)
  local max = math.max(0, #steps - l.visible)
  if l.offset > max then l.offset = max end
  for r, row in ipairs(l.rows) do
    local i = l.offset + r
    local st = steps[i]
    if st and r <= l.visible then
      row.i = i; row:Show()
      local done = IsStepDone(log, i)
      row.num:SetText(i)
      local pre = st.gate and "|cffffcc40?|r " or (st.ins and "|cffff5555>|r " or "")
      row.txt:SetText(pre .. StepTitle(st))
      row.sel:SetShown(i == f.view); row.bar:SetShown(i == f.auto)
      row.check:SetShown(done); row.pip:SetShown(not done)
      local c = DColor(st.d or st.gate or st.ins)
      row.pip:SetColorTexture(c[1], c[2], c[3], 1)
      row.txt:SetTextColor(unpack(done and T.dim or T.text))
    else
      row:Hide()
    end
  end
end

-- icônes officielles du jeu pour chaque type de ligne
local KICON = {
  a = "Interface\\GossipFrame\\AvailableQuestIcon", t = "Interface\\GossipFrame\\ActiveQuestIcon",
  c = "Interface\\TargetingFrame\\UI-TargetingFrame-Skull", o = "Interface\\Icons\\INV_Misc_Map_01",
  h = "Interface\\RAIDFRAME\\ReadyCheck-Waiting",
}
local function KindIcon(nd)
  if nd.kind == "i" then
    local id = nd.items and nd.items[1]
    return (id and GetItemIcon and GetItemIcon(id)) or "Interface\\Icons\\INV_Misc_Bag_10"
  end
  return KICON[nd.kind]
end

local function MakeRow(parent, CW)
  local row = CreateFrame("Button", nil, parent)
  row:SetWidth(CW + 8)
  row.hl = Tex(row, "HIGHLIGHT", { 1, 1, 1, 0.05 }); row.hl:SetAllPoints()
  row.wpOn = Tex(row, "BACKGROUND", T.accent); row.wpOn:SetAllPoints(); ns.Accent(row.wpOn, 0.10)
  row.wpBar = Tex(row, "ARTWORK", T.accent); row.wpBar:SetPoint("TOPLEFT"); row.wpBar:SetPoint("BOTTOMLEFT"); row.wpBar:SetWidth(2); ns.Accent(row.wpBar)
  row.icon = row:CreateTexture(nil, "ARTWORK"); row.icon:SetSize(16, 16); row.icon:SetPoint("TOPLEFT", 2, -4)
  row.icon:SetTexture("Interface\\RAIDFRAME\\ReadyCheck-Ready")
  row.pip = Tex(row, "ARTWORK", { 1, 1, 1 }); row.pip:SetSize(8, 8); row.pip:SetPoint("TOPLEFT", 6, -8)
  row.kicon = row:CreateTexture(nil, "ARTWORK", nil, 1); row.kicon:SetSize(16, 16); row.kicon:SetPoint("TOPLEFT", 2, -4)
  row.tag = Text(row, 10, T.text, true); row.tag:SetPoint("TOPLEFT", 22, -6); row.tag:SetWidth(70); row.tag:SetWordWrap(false)
  row.name = Text(row, 13, T.text); row.name:SetPoint("TOPLEFT", 94, -4); row.name:SetWordWrap(false)
  row.npc = Text(row, 12, T.dim); row.npc:SetJustifyH("RIGHT"); row.npc:SetWordWrap(false)
  row.sub = Text(row, 12, T.dim); row.sub:SetPoint("TOPLEFT", 94, -24); row.sub:SetWidth(CW - 90); row.sub:SetSpacing(3)
  row.sep = Tex(row, "BACKGROUND", { 1, 1, 1, 0.05 }); row.sep:SetPoint("BOTTOMLEFT", 4, -4); row.sep:SetPoint("BOTTOMRIGHT", -4, -4); row.sep:SetHeight(1)
  -- les boutons sécurisés (cibler / objet) sont dans la barre d'actions, hors de cette fenêtre,
  -- pour que la fenêtre reste utilisable en combat
  -- GPS
  local gb = CreateFrame("Button", nil, row)
  gb:SetSize(20, 20)
  gb.icon = gb:CreateTexture(nil, "ARTWORK"); gb.icon:SetAllPoints()
  gb.hl = Tex(gb, "HIGHLIGHT", { 1, 1, 1, 0.2 }); gb.hl:SetAllPoints()
  gb.row = row
  gb:SetScript("OnClick", function(self) local n = self.row.node; if n and n.loc then ns.SetOne(n) end end)
  gb:SetScript("OnEnter", function(self)
    local n = self.row.node
    if n and n.loc then ns.ShowTip(self, { "GPS", L.TT_GPS:format(n.npc or ns.QName(n.q), n.loc.x, n.loc.y) }) end
  end)
  gb:SetScript("OnLeave", ns.HideTip)
  row.gb = gb
  row:SetScript("OnClick", function(self) local n = self.node; if n and n.loc then ns.SetOne(n) end end)
  row:SetScript("OnEnter", function(self) ns.RowTip(self) end)
  row:SetScript("OnLeave", ns.HideTip)
  return row
end

function ns.SetOne(n)
  ns.SetPoints({ { n.loc.m, n.loc.x, n.loc.y, n.npc or ns.QName(n.q) } })
  Render()
end

function ns.RowTip(row)
  local n = row.node; if not n then return end
  local q = ns.Q[n.q] or {}
  local lines = { ns.QName(n.q) }
  if GetLocale and GetLocale() == "frFR" and q.n then table.insert(lines, { q.n, 0.6, 0.6, 0.6 })
  elseif ns.lang == "fr" and q.nf then table.insert(lines, { q.nf, 0.6, 0.6, 0.6 }) end
  local kc = T.kind[n.kind] or T.text
  local kt = ({ a = L.TT_TAKE, c = L.TT_DO, o = L.TT_OUT, t = L.TT_TURN, h = L.TT_HAVE, i = L.TT_ITEM })[n.kind]
  table.insert(lines, { kt, kc[1], kc[2], kc[3] })
  if n.pre then table.insert(lines, { L.PRE, 0.75, 0.75, 0.75 }) end
  table.insert(lines, n.ins and { L.TT_INSIDE, 1, 0.45, 0.45 } or { L.TT_OUTSIDE, 0.75, 0.78, 0.82 })
  if q.c then
    for tok in q.c:gmatch("[^,]+") do local cn, cc = ns.ClassInfo(tok); table.insert(lines, { L.CLASSQ:format(cn), cc[1], cc[2], cc[3] }) end
  end
  if n.npc then table.insert(lines, n.npc) end
  if n.loc then table.insert(lines, { ("%s  %.1f, %.1f"):format(ZoneName(n.loc.m), n.loc.x, n.loc.y), 0.6, 0.6, 0.6 }) end
  local obj = (ns.lang == "fr" and q.of) or ns.T(q.oe)
  if obj then table.insert(lines, { obj, 0.95, 0.95, 0.95 }) end
  for _, s in ipairs(ObjectiveLines(n)) do table.insert(lines, { "- " .. s, 0.8, 0.8, 0.8 }) end
  if q.ne then table.insert(lines, { ns.T(q.ne), 1, 0.82, 0.5 }) end
  for _, r in ipairs(q.req or {}) do
    if r[3] then table.insert(lines, { r[1] .. " : " .. ns.T(r[3]), 1, 0.82, 0.5 }) end
  end
  if q.si then table.insert(lines, { q.si .. (q.sih and (" : " .. ns.T(q.sih)) or ""), 1, 0.82, 0.5 }) end
  if q.pi then table.insert(lines, { q.pi .. (q.pih and (" : " .. ns.T(q.pih)) or ""), 1, 0.82, 0.5 }) end
  local rw = q.rw and q.rw ~= "" and q.rw or nil
  if q.ri and q.ri[1] then rw = (rw and (rw .. " ; ") or "") .. table.concat(q.ri, q.rc and " / " or ", ") end
  if rw then table.insert(lines, { L.TT_REWARD:format(rw), 0.4, 0.85, 0.45 }) end
  if q.xp and q.xp > 0 then table.insert(lines, { L.TT_XP:format(q.xp), 0.6, 0.6, 1 }) end
  local pb = n.kind == "a" and ns.PrereqProblem(n.q)
  if pb then table.insert(lines, { L.BLOCKED:format(pb), 1, 0.35, 0.35 }) end
  if q.conf then table.insert(lines, { L.TT_CONFLICT, 0.55, 0.55, 0.55 }) end
  table.insert(lines, { " ", 1, 1, 1 })
  table.insert(lines, n.loc and { L.TT_CLICK, T.accent[1], T.accent[2], T.accent[3] } or { L.TT_NOPOINT, 0.5, 0.5, 0.5 })
  ns.ShowTip(row, lines)
end

local function Build()
  f = CreateFrame("Frame", "WLDTFrame", UIParent)
  f:SetSize(W, 300); f:SetFrameStrata("MEDIUM")
  local pos = WLDTDB.pos
  if pos then f:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4]) else f:SetPoint("RIGHT", -60, 40) end
  f:SetMovable(true); f:EnableMouse(true); f:SetClampedToScreen(true)
  ns.Flat(f, T.bg)

  local h = CreateFrame("Frame", nil, f)
  h:SetPoint("TOPLEFT", 1, -1); h:SetPoint("TOPRIGHT", -1, -1); h:SetHeight(30)
  h.bg = Tex(h, "BACKGROUND", T.header); h.bg:SetAllPoints()
  h.line = Tex(h, "ARTWORK", T.accent); h.line:SetPoint("BOTTOMLEFT"); h.line:SetPoint("BOTTOMRIGHT"); h.line:SetHeight(1); ns.Accent(h.line, 0.6)
  h:EnableMouse(true); h:RegisterForDrag("LeftButton")
  h:SetScript("OnDragStart", function() f:StartMoving() end)
  h:SetScript("OnDragStop", function()
    f:StopMovingOrSizing()
    ns.PinTopLeft()
    if ns.UpdateActionBar then ns.UpdateActionBar() end
  end)
  h.mark = Tex(h, "ARTWORK", T.accent); h.mark:SetSize(3, 15); h.mark:SetPoint("LEFT", 10, 0); ns.Accent(h.mark); h.mark:Hide()
  h.logo = h:CreateTexture(nil, "ARTWORK"); h.logo:SetSize(22, 22); h.logo:SetPoint("LEFT", 4, -1)
  h.logo:SetTexture("Interface\\TargetingFrame\\UI-PVP-Horde"); h.logo:SetTexCoord(0.08, 0.58, 0.03, 0.6)
  h.title = Text(h, 13, T.text, true); h.title:SetPoint("LEFT", 28, 0); h.title:SetText(L.TITLE)
  f.header = h
  local close = Button(h, 22, 20, "x", function() f:Hide(); WLDTDB.hidden = true; ns.SetArrow(nil); if ns.UpdateActionBar then ns.UpdateActionBar() end end, function() return { L.TT_HCLOSE } end)
  close:SetPoint("RIGHT", -4, 0)
  f.miniBtn = Button(h, 22, 20, "-", function() f.mini = not f.mini; WLDTDB.mini = f.mini; Render() end, function() return { L.TT_HMIN } end)
  f.miniBtn:SetPoint("RIGHT", close, "LEFT", -4, 0)
  f.langBtn = Button(h, 30, 20, "FR", function() ns.SetLang(ns.lang == "fr" and "en" or "fr"); ns.Print(L.LANG); Render() end, function() return { L.TT_HLANG } end)
  f.langBtn:SetPoint("RIGHT", f.miniBtn, "LEFT", -4, 0)
  f.listBtn = Button(h, 56, 20, L.LIST, function()
    f.list:SetShown(not f.list:IsShown()); WLDTDB.list = f.list:IsShown(); Render()
  end, function() return { L.TT_HLIST } end)
  f.listBtn:SetPoint("RIGHT", f.langBtn, "LEFT", -4, 0)
  f.pickBtn = Button(h, 76, 20, L.PICK, function() ns.TogglePicker() end, function() return { L.TT_HPICK } end)
  f.pickBtn:SetPoint("RIGHT", f.listBtn, "LEFT", -4, 0)
  ns.Primary(f.pickBtn)
  f.writsBtn = Button(h, 56, 20, L.WRITS, function() if ns.Writs and ns.Writs.WP then ns.Writs.WP.Toggle() end end,
    function() return { L.WRITS, L.TT_HWRITS } end)
  f.writsBtn:SetPoint("RIGHT", f.pickBtn, "LEFT", -4, 0)

  f.progLabel = Text(f, 11, T.dim, true); f.progLabel:SetPoint("TOPLEFT", PAD, -40); f.progLabel:SetWordWrap(false); f.progLabel:SetWidth(W - 2 * PAD - 60)
  f.progPct = Text(f, 11, T.text, true); f.progPct:SetPoint("TOPRIGHT", -PAD, -40); f.progPct:SetJustifyH("RIGHT")
  local bar = CreateFrame("StatusBar", nil, f)
  bar:SetPoint("TOPLEFT", PAD, -57); bar:SetPoint("TOPRIGHT", -PAD, -57); bar:SetHeight(4)
  bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
  bar.bg = Tex(bar, "BACKGROUND", { 1, 1, 1, 0.08 }); bar.bg:SetAllPoints()
  bar:SetMinMaxValues(0, 1)
  f.bar = bar

  -- carte avec défilement
  local holder = CreateFrame("Frame", nil, f)
  holder:SetPoint("TOPLEFT", PAD, -70); holder:SetPoint("TOPRIGHT", -PAD, -70)
  ns.Flat(holder, T.card, { 1, 1, 1, 0.06 })
  holder.stripe = Tex(holder, "ARTWORK", T.accent); holder.stripe:SetPoint("TOPLEFT", 1, -1); holder.stripe:SetPoint("BOTTOMLEFT", 1, 1); holder.stripe:SetWidth(3)
  local sf = CreateFrame("ScrollFrame", nil, holder)
  sf:SetPoint("TOPLEFT", 4, -1); sf:SetPoint("BOTTOMRIGHT", -6, 1)
  local card = CreateFrame("Frame", nil, sf)
  card:SetWidth(W - 2 * PAD - 10); card:SetHeight(100)
  sf:SetScrollChild(card)
  sf.offset = 0
  sf:EnableMouseWheel(true)
  sf:SetScript("OnMouseWheel", function(self, delta)
    local max = math.max(0, card:GetHeight() - self:GetHeight())
    self.offset = math.max(0, math.min(max, (self.offset or 0) - delta * 40))
    self:SetVerticalScroll(self.offset)
    Render()
  end)
  -- barre de défilement : poignée qu'on peut tirer (la molette marche aussi)
  local sb = CreateFrame("Button", nil, holder)
  sb:SetWidth(10); sb:SetFrameLevel((holder:GetFrameLevel() or 1) + 5)
  sb.tex = Tex(sb, "OVERLAY", T.accent); sb.tex:SetPoint("TOPRIGHT", -1, 0); sb.tex:SetPoint("BOTTOMRIGHT", -1, 0); sb.tex:SetWidth(4); ns.Accent(sb.tex, 0.7)
  sb:SetScript("OnEnter", function(self) self.tex:SetAlpha(1) end)
  sb:SetScript("OnLeave", function(self) self.tex:SetAlpha(0.7) end)
  sb:SetScript("OnMouseDown", function(self)
    local sc = self:GetEffectiveScale()
    local _, cy = GetCursorPosition()
    self.drag = { cy / sc, sf.offset or 0 }
    self:SetScript("OnUpdate", function(me)
      local _, y2 = GetCursorPosition(); y2 = y2 / sc
      local over, track = holder.over or 0, holder.track or 1
      if over <= 0 or track <= 0 then return end
      local off = me.drag[2] + (me.drag[1] - y2) * over / track
      sf.offset = math.max(0, math.min(over, off)); sf:SetVerticalScroll(sf.offset)
      Render()
    end)
  end)
  sb:SetScript("OnMouseUp", function(self) self:SetScript("OnUpdate", nil) end)
  holder.sbar = sb
  card.fade = card:CreateAnimationGroup()
  local an = card.fade:CreateAnimation("Alpha"); an:SetFromAlpha(0.25); an:SetToAlpha(1); an:SetDuration(0.2); an:SetSmoothing("OUT")
  f.holder, f.scroll, f.card = holder, sf, card
  local CW = W - 2 * PAD - 40

  card.zone = Text(card, 11, T.dim, true); card.zone:SetPoint("TOPLEFT", 14, -10); card.zone:SetWordWrap(false); card.zone:SetWidth(CW - 90)
  card.badge = Text(card, 11, T.text, true); card.badge:SetPoint("TOPRIGHT", -10, -10); card.badge:SetJustifyH("RIGHT")
  -- portrait 3D du boss (modèle du journal de Naowh)
  card.modelBg = card:CreateTexture(nil, "BACKGROUND"); card.modelBg:SetColorTexture(0, 0, 0, 0.35)
  card.modelBg:SetSize(76, 76); card.modelBg:SetPoint("TOPRIGHT", -8, -26); card.modelBg:Hide()
  card.model = CreateFrame("PlayerModel", nil, card)
  card.model:SetSize(74, 74); card.model:SetPoint("CENTER", card.modelBg, "CENTER"); card.model:Hide()
  card.where = ns.Chip(card); card.where:SetPoint("TOPLEFT", card.zone, "BOTTOMLEFT", 0, -6)
  card.clsChip = ns.Chip(card); card.clsChip:SetPoint("LEFT", card.where, "RIGHT", 6, 0)
  card.title = Text(card, 18, T.text, true); card.title:SetPoint("TOPLEFT", card.where, "BOTTOMLEFT", 0, -8); card.title:SetWidth(CW)
  card.travel = Text(card, 12, T.accent); card.travel:SetPoint("TOPLEFT", card.title, "BOTTOMLEFT", 0, -6); card.travel:SetWidth(CW)
  card.readyBg = card:CreateTexture(nil, "ARTWORK")
  card.ready = Text(card, 13, T.text, true); card.ready:SetWidth(CW - 12); card.ready:SetSpacing(3)
  card.note = Text(card, 13, { 0.86, 0.87, 0.90 }); card.note:SetWidth(CW); card.note:SetSpacing(3)
  card.rows = {}
  for r = 1, MAXROWS do card.rows[r] = MakeRow(card, CW) end
  f.footBig, f.footSmall = {}, {}

  local foot = CreateFrame("Frame", nil, f)
  foot:SetPoint("BOTTOMLEFT", PAD, PAD); foot:SetPoint("BOTTOMRIGHT", -PAD, PAD); foot:SetHeight(56)
  f.foot = foot
  local BW = (W - PAD * 2 - 8) / 3
  f.prev = Button(foot, BW, 24, L.PREV, function() ns.GoTo(f.view - 1) end); f.prev:SetPoint("TOPLEFT")
  f.cur = Button(foot, BW, 24, L.CURRENT, function() ns.GoTo(f.auto or 1) end); f.cur:SetPoint("LEFT", f.prev, "RIGHT", 4, 0)
  f.next = Button(foot, BW, 24, L.NEXT, function() ns.GoTo(f.view + 1) end); f.next:SetPoint("LEFT", f.cur, "RIGHT", 4, 0)
  ns.Primary(f.next)
  local SW = (W - PAD * 2 - 20) / 6
  f.way = Button(foot, SW, 24, L.POINTS, function()
    local log, st = ns.LogEntries(), Steps()[f.view]; if not st then return end
    local pts = StepPoints(log, st, false)
    if #pts == 0 then pts = StepPoints(log, st, true) end
    local key = f.view
    if f.wpKey == key and not ns.HasTomTom() and #pts > 0 then f.wpIdx = (f.wpIdx % #pts) + 1 else f.wpIdx = 1 end
    f.wpKey = key
    ns.SetPoints(pts, false, f.wpIdx); Render()
  end, function() return { L.POINTS, L.TT_FPOINTS } end)
  f.way:SetPoint("BOTTOMLEFT")
  f.share = Button(foot, SW, 24, L.SHARE, ns.ShareQuests, function() return { L.SHARE, L.TT_FSHARE } end); f.share:SetPoint("LEFT", f.way, "RIGHT", 4, 0)
  f.done = Button(foot, SW, 24, L.DONE, function()
    local st = Steps()[f.view]; if not st then return end
    SetManual(st, not Manual(st)); ns.Refresh()
  end, function() return { L.DONE, L.TT_FDONE } end)
  f.done:SetPoint("LEFT", f.share, "RIGHT", 4, 0)
  f.autoBtn = Button(foot, SW, 24, "Auto", function() WLDTDB.autoWay = not WLDTDB.autoWay; f.sig = nil; ns.Refresh() end, function() return { "Auto", L.TT_FAUTO } end)
  f.autoBtn:SetPoint("LEFT", f.done, "RIGHT", 4, 0)
  f.arrowBtn = Button(foot, SW, 24, L.ARROW, function() ns.ToggleArrow(); Render() end, function() return { L.ARROW, L.TT_FARROW } end); f.arrowBtn:SetPoint("LEFT", f.autoBtn, "RIGHT", 4, 0)
  f.recalc = Button(foot, SW, 24, L.RECALC, function() ns.Recalc() end, function() return { L.RECALC, L.RECALC_TT } end)
  f.recalc:SetPoint("LEFT", f.arrowBtn, "RIGHT", 4, 0)

  f.footBig = { f.prev, f.cur, f.next }
  f.footSmall = { f.way, f.share, f.done, f.autoBtn, f.arrowBtn, f.recalc }

  -- poignée de redimensionnement (coin bas-droit)
  local grip = CreateFrame("Button", nil, f)
  grip:SetSize(14, 14); grip:SetPoint("BOTTOMRIGHT", 0, 0); grip:SetFrameLevel((f:GetFrameLevel() or 1) + 10)
  grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
  grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
  grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
  grip:SetScript("OnEnter", function(self) ns.ShowTip(self, { L.TT_RESIZE }) end)
  grip:SetScript("OnLeave", ns.HideTip)
  grip:SetScript("OnMouseDown", function(self)
    ns.PinTopLeft()
    local sc = f:GetEffectiveScale()
    local cx, cy = GetCursorPosition()
    self.start = { cx / sc, cy / sc, W, CARD_MAX }
    self:SetScript("OnUpdate", function(me)
      local x, y = GetCursorPosition()
      x, y = x / sc, y / sc
      local nw = math.floor(math.max(380, math.min(900, me.start[3] + (x - me.start[1]))))
      local nh = math.floor(math.max(160, math.min(1000, me.start[4] - (y - me.start[2]))))
      if nw ~= W or nh ~= CARD_MAX then ns.Relayout(nw, nh); Render() end
    end)
  end)
  grip:SetScript("OnMouseUp", function(self)
    self:SetScript("OnUpdate", nil)
    WLDTDB.size = { W, CARD_MAX }
  end)
  grip:SetScript("OnDoubleClick", function()
    ns.Relayout(W0, CARD0); WLDTDB.size = nil; Render()
  end)
  f.grip = grip

  f.miniText = Text(f, 13, T.text, true); f.miniText:SetPoint("TOPLEFT", PAD, -40); f.miniText:SetPoint("TOPRIGHT", -PAD, -40); f.miniText:SetWordWrap(false)
  BuildList()
  f:SetScript("OnShow", function() ns.Refresh() end)
  f.mini = WLDTDB.mini
  f.list:SetShown(WLDTDB.list and true or false)
  ns.frame = f
  if WLDTDB.size then ns.Relayout(WLDTDB.size[1], WLDTDB.size[2]) end
end
ns.BuildMain = Build

-- Largeur / hauteur de la fenêtre (poignée en bas à droite)
function ns.Relayout(nw, nh)
  W, CARD_MAX = nw, nh
  if not f then return end
  local card = f.card
  local CW = W - 2 * PAD - 40
  f:SetWidth(W)
  f.progLabel:SetWidth(W - 2 * PAD - 60)
  card:SetWidth(W - 2 * PAD - 10)
  card.zone:SetWidth(CW - 90); card.title:SetWidth(CW); card.travel:SetWidth(CW)
  card.ready:SetWidth(CW - 12); card.note:SetWidth(CW)
  for _, row in ipairs(card.rows) do row:SetWidth(CW + 8); row.sub:SetWidth(CW - 90) end
  local BW = (W - PAD * 2 - 8) / 3
  local SW = (W - PAD * 2 - 20) / 6
  for _, b in ipairs(f.footBig or {}) do b:SetWidth(BW) end
  for _, b in ipairs(f.footSmall or {}) do b:SetWidth(SW) end
end

-- =====================================================================
--  Rendu
-- =====================================================================
local function SetSecureRow() end

-- =====================================================================
--  Ordre dans le donjon : objectifs rangés boss par boss, dans l'ordre du journal de Naowh
--  (« Pendant tout le donjon » en premier pour le butin des trash). Une ligne par objectif.
-- =====================================================================
local NKEY = { TheDeadmines = "Deadmines", TheStockade = "Stockade", HallofThanes = "HallOfThanes",
  RuinsofLordaeron = "RuinsOfLordaeron", ExcavationSiteWetlands = "ExcavationSite", CityofDalaran = "Dalaran",
  TheDrownedCity = "DrownedCity", KroldokStronghold = "Kroldok", DireMaulEast = "DireMaul", DireMaulWest = "DireMaul",
  DireMaulNorth = "DireMaul", StratholmeLiving = "Stratholme", StratholmeUndead = "Stratholme" }
local bossCache = {}
local function BossOrder(dkey)
  if bossCache[dkey] ~= nil then return bossCache[dkey] end
  local out = false
  local N = _G.NaowhForever
  local J = N and N.Journal
  if J and J.Get then
    local ok, d = pcall(J.Get, NKEY[dkey] or dkey)
    if ok and d and d.wings then
      out = { list = {}, idx = {} }
      for _, wing in ipairs(d.wings) do
        for _, b in ipairs(wing.bosses or {}) do
          if b.npc and not b.trash and not b.chest then
            local en = b.english or b.name
            table.insert(out.list, { en = en, name = b.name or en, tip = J.Tip and J.Tip(b) or nil })
            out.idx[en] = #out.list
            for tok in en:gmatch("[^%s,]+") do
              tok = tok:gsub("'s$", "")
              if #tok > 4 then
                local k = "#" .. tok
                if out.idx[k] == nil then out.idx[k] = #out.list elseif out.idx[k] ~= #out.list then out.idx[k] = false end
              end
            end
          end
        end
      end
    end
  end
  bossCache[dkey] = out
  return out
end

local function ObjDone(log, q, qid, o)
  local s = ns.State(log, qid)
  if s == "done" or s == "ready" then return true end
  local e = log[qid]
  if e and e.index and GetNumQuestLeaderBoards and GetQuestLogLeaderBoard and o.n then
    for j = 1, (GetNumQuestLeaderBoards(e.index) or 0) do
      local text, _, finished = GetQuestLogLeaderBoard(j, e.index)
      if text and text:find(o.n, 1, true) then return finished and true or false end
    end
  end
  return false
end

function ns.StepView(st, log)
  if not st or st.gate or not st.ins or st.split then return st and st.acts or {} end
  local bo = BossOrder(st.ins)
  local function BossOf(names)
    if not bo then return nil end
    for _, nm in ipairs(names) do
      if nm and bo.idx[nm] then return bo.idx[nm] end
    end
    for _, nm in ipairs(names) do
      for tok in (nm or ""):gmatch("[^%s,]+") do
        tok = tok:gsub("'s$", "")
        local v = bo.idx["#" .. tok]
        if v then return v end
      end
    end
  end
  local items = {}
  local order = 0
  for _, nd in ipairs(st.acts) do
    order = order + 1
    local q = ns.Q[nd.q] or {}
    if nd.kind == "c" and q.o and #q.o > 0 then
      local first = true
      for _, o in ipairs(q.o) do
        if not (o.w and not o.ins and not o.outer) then
          local names = {}
          for _, t in ipairs(o.t or {}) do table.insert(names, t) end
          for _, x in ipairs(o.src or {}) do if x[1] then table.insert(names, x[1]) end end
          if o.n then table.insert(names, o.n) end
          if q.oe then table.insert(names, q.oe) end
          local v = setmetatable({ oneObj = o, firstOfQuest = first, vok = ObjDone(log, q, nd.q, o) }, { __index = nd })
          first = false
          order = order + 0.01
          table.insert(items, { node = v, boss = BossOf(names) or 0, ord = order })
        end
      end
    else
      local names = {}
      if nd.npc then table.insert(names, nd.npc) end
      if nd.kind == "c" and q.oe then table.insert(names, q.oe) end
      table.insert(items, { node = nd, boss = BossOf(names) or 0, ord = order })
    end
  end
  if not bo then
    local out = {}
    for _, it in ipairs(items) do table.insert(out, it.node) end
    return out
  end
  table.sort(items, function(a, b) if a.boss ~= b.boss then return a.boss < b.boss end return a.ord < b.ord end)
  local out, cur = {}, nil
  for _, it in ipairs(items) do
    if it.boss ~= cur then
      cur = it.boss
      local B = bo.list[cur]
      local targets = {}
      if B then targets = { B.en } end
      table.insert(out, { kind = "b", q = it.node.q, bossIdx = cur, bossName = B and B.name, tip = B and B.tip, targets = (#targets > 0) and targets or nil })
    end
    table.insert(out, it.node)
  end
  -- en-têtes : fait quand toutes leurs lignes sont faites
  local hdr
  for _, n in ipairs(out) do
    if n.kind == "b" then hdr = n; hdr.allOk = true
    elseif hdr then
      local ok = (n.vok ~= nil) and n.vok or ns.NodeOK(log, n)
      if not ok then hdr.allOk = false end
    end
  end
  return out
end

Render = function()
  if not f then return end
  f.pending = false
  local log = ns.LogEntries()
  local steps = Steps()
  f.langBtn.label:SetText(ns.lang == "fr" and "FR" or "EN"); f.pickBtn.label:SetText(L.PICK); f.listBtn.label:SetText(L.LIST)
  f.listBtn.label:SetTextColor(unpack(f.list:IsShown() and T.accent or T.text))
  f.miniBtn.label:SetText(f.mini and "+" or "-")
  local card, holder = f.card, f.holder

  if #steps == 0 then
    f.progLabel:SetText(L.NOROUTE); f.progPct:SetText("")
    f.bar:SetValue(0)
    card.zone:SetText(""); card.badge:SetText(""); card.where:Hide(); card.clsChip:Hide()
    card.title:SetText(L.NOROUTE); card.travel:Hide(); card.ready:Hide(); card.readyBg:Hide()
    card.note:ClearAllPoints(); card.note:SetPoint("TOPLEFT", 14, -60); card.note:SetText(L.NOROUTE_TXT); card.note:Show()
    for _, row in ipairs(card.rows) do row.node = nil; row:Hide() end
    card:SetHeight(140); holder:SetHeight(140); holder.sbar:Hide()
    f.foot:Show(); f:SetHeight(70 + 140 + 12 + 56 + PAD)
    for _, b in ipairs({ f.prev, f.cur, f.next, f.way, f.done }) do b:SetEnabled(false) end
    f.list:Hide()
    ns.UpdateActionBar()
    return
  end

  f.view = math.max(1, math.min(#steps, f.view or 1))
  local i = f.view
  local st = steps[i]
  local done = IsStepDone(log, i)
  local n, total = 0, #steps
  for k = 1, #steps do if IsStepDone(log, k) then n = n + 1 end end
  f.bar:SetValue(total > 0 and n / total or 0)
  f.bar:SetStatusBarColor(T.accent[1], T.accent[2], T.accent[3])
  f.progLabel:SetText((ns.route.label or "") .. "   ·   " .. L.STEP:format(i, total))
  f.progPct:SetText(("%d %%"):format(total > 0 and math.floor(n / total * 100 + 0.5) or 0))

  if f.mini then
    holder:Hide(); f.foot:Hide(); f.progLabel:Hide(); f.progPct:Hide(); f.list:Hide()
    local c = DColor(st.d or st.gate or st.ins)
    f.miniText:SetText(("%s%d.|r %s"):format(Hex(c), i, StepTitle(st))); f.miniText:Show()
    f.bar:ClearAllPoints(); f.bar:SetPoint("BOTTOMLEFT", 1, 1); f.bar:SetPoint("BOTTOMRIGHT", -1, 1); f.bar:SetHeight(2)
    f:SetHeight(64)
    ns.UpdateActionBar()
    return
  end
  f.miniText:Hide(); holder:Show(); f.foot:Show(); f.progLabel:Show(); f.progPct:Show()
  f.bar:ClearAllPoints(); f.bar:SetPoint("TOPLEFT", PAD, -57); f.bar:SetPoint("TOPRIGHT", -PAD, -57); f.bar:SetHeight(4)
  f.list:SetShown(WLDTDB.list and true or false)

  local dkey = st.d or st.gate or st.ins
  local dc = DColor(dkey)
  holder.stripe:SetColorTexture(dc[1], dc[2], dc[3], 1)
  card.zone:SetText(("%s%s|r"):format(Hex(dc), ns.Upper(ns.DName(dkey) or "")))
  if done then card.badge:SetText(Hex({ 0.35, 0.9, 0.48 }) .. L.B_DONE .. "|r")
  elseif i == f.auto then card.badge:SetText(Hex(T.accent) .. L.B_CUR .. "|r")
  elseif f.auto and i < f.auto then card.badge:SetText(Hex({ 1, 0.6, 0.2 }) .. L.B_LATE .. "|r")
  else card.badge:SetText(Hex(T.dim) .. L.B_NEXT .. "|r") end

  -- où
  local dn = ns.Upper(ns.DName(dkey))
  if st.gate then ns.SetChip(card.where, L.GATE:format(dn), dc)
  elseif st.ins then
    local allOuter = true
    for _, nd in ipairs(st.acts) do if nd.kind ~= "c" or nd.outer == false then allOuter = false end end
    if allOuter then ns.SetChip(card.where, L.OUTER:format(dn), dc) else ns.SetChip(card.where, L.IN_DUNGEON:format(dn), dc) end
  else
    ns.SetChip(card.where, L.OUT:format(ns.Upper((st.loc and ZoneName(st.loc.m)) or "")), { 0.75, 0.78, 0.82 })
  end
  local cls
  local allCls = #st.acts > 0
  for _, nd in ipairs(st.acts) do local q = ns.Q[nd.q]; if not (q and q.c) then allCls = false else cls = q.c end end
  if allCls and cls then
    local tok = cls:match("^[^,]+"); local cn, cc = ns.ClassInfo(tok)
    ns.SetChip(card.clsChip, ns.ClassIconText(tok, 13) .. L.CLASSQ:format(ns.Upper(cn)), cc)
  else card.clsChip:Hide() end

  local hasModel = false
  if st.bossModel and card.model.SetDisplayInfo then
    hasModel = pcall(card.model.SetDisplayInfo, card.model, st.bossModel)
    if hasModel and card.model.SetPortraitZoom then pcall(card.model.SetPortraitZoom, card.model, 0.85) end
  end
  card.model:SetShown(hasModel); card.modelBg:SetShown(hasModel)
  card.title:SetWidth(hasModel and (W - 2 * PAD - 40 - 84) or (W - 2 * PAD - 40))
  card.title:SetText(StepTitle(st))
  local y = 10 + card.zone:GetStringHeight() + 6 + 19 + 8 + card.title:GetStringHeight()
  if hasModel then y = math.max(y, 26 + 76 + 4) end

  -- check-list « prêt ? »
  local checks = st.checks
  if checks and #checks > 0 then
    local miss = 0
    for _, nd in ipairs(checks) do if not ns.NodeOK(log, nd) then miss = miss + 1 end end
    local dn2 = ns.DName(st.gate or st.ins)
    if miss == 0 then
      card.ready:SetText("|cff59e67a" .. L.READY:format(dn2) .. "|r"); card.readyBg:SetColorTexture(0.35, 0.9, 0.48, 0.12)
    else
      card.ready:SetText("|cffff9933" .. L.NOTREADY:format(miss, dn2) .. "|r"); card.readyBg:SetColorTexture(1, 0.6, 0.2, 0.12)
    end
    card.ready:Show(); card.readyBg:Show()
  else card.ready:Hide(); card.readyBg:Hide() end

  if st.travel then
    card.travel:SetText("> " .. L[st.travel]); card.travel:SetTextColor(T.accent[1], T.accent[2], T.accent[3]); card.travel:Show()
    y = y + 6 + card.travel:GetStringHeight()
  else card.travel:Hide() end
  if card.ready:IsShown() then
    card.ready:ClearAllPoints(); card.ready:SetPoint("TOPLEFT", 20, -(y + 14))
    card.readyBg:ClearAllPoints(); card.readyBg:SetPoint("TOPLEFT", card.ready, "TOPLEFT", -6, 6); card.readyBg:SetPoint("BOTTOMRIGHT", card.ready, "BOTTOMRIGHT", 6, -6)
    y = y + 14 + card.ready:GetStringHeight() + 6
  end
  local note
  if st.gate then
    note = L.GATE_N
    local d = ns.D[st.gate]
    if d and d.ed then note = ns.T(d.ed) .. "\n" .. note end
    local kl = ns.KeyLines and ns.KeyLines(st.gate) or {}
    if #kl > 0 then
      local t, warn = {}, false
      for _, k in ipairs(kl) do table.insert(t, k[1]); if k[3] and not k[2] then warn = true end end
      if warn then table.insert(t, "|cffff9933" .. L.KEY_WARN .. "|r") end
      note = table.concat(t, "\n") .. "\n" .. note
    end
  end
  if st.split then
    -- blocs aérés : conseil, puis « en chemin » en liste
    local blocks = {}
    local acc = Hex(T.accent)
    local tips = ns.STEP_TIPS and ns.STEP_TIPS[st.ins]
    local mine = tips and tips[(st.bossIdx == 0 and "*start") or (st.bossIdx == 999 and "*trash") or st.bossEn or ""]
    local tipLines = {}
    if mine then table.insert(tipLines, "|cffe8eaed" .. ns.T(mine[1]) .. "|r") end
    if st.bossTip then table.insert(tipLines, "|cffb8bcc4" .. st.bossTip .. "|r") end
    if #tipLines > 0 then table.insert(blocks, acc .. L.H_TIP .. "|r\n" .. table.concat(tipLines, "\n\n")) end
    if st.trash then
      local names, seen = {}, {}
      for _, n in ipairs(st.trash) do
        if not ns.NodeOK(log, n) then
          local o = n.oneObj
          local nm = o and ((o.c and o.c > 1 and (o.c .. " x ") or "") .. (o.n or "")) or ns.QName(n.q)
          if nm ~= "" and not seen[nm] then seen[nm] = true; table.insert(names, "|cffe6c48a-  " .. nm .. "|r") end
        end
      end
      if #names > 0 then table.insert(blocks, acc .. L.H_ALSO .. "|r\n" .. table.concat(names, "\n")) end
    end
    if #blocks > 0 then note = table.concat(blocks, "\n\n") end
  end
  if note then
    card.note:ClearAllPoints(); card.note:SetPoint("TOPLEFT", 14, -(y + 8)); card.note:SetText(note); card.note:Show()
    y = y + 8 + card.note:GetStringHeight() + 6
  else card.note:Hide() end
  y = y + 10

  local CW = W - 2 * PAD - 40
  local view = ns.StepView(st, log)
  for r, row in ipairs(card.rows) do
    local nd = view[r]
    if nd and nd.kind == "b" then
      -- en-tête de boss
      row.node = nil
      row.tag:SetText(nd.bossIdx > 0 and L.BOSS_N:format(nd.bossIdx) or L.ALLDUNGEON_T); row.tag:SetTextColor(1, 0.45, 0.45); row.tag:SetAlpha(nd.allOk and 0.5 or 1)
      row.name:SetText(nd.bossIdx > 0 and nd.bossName or L.ALLDUNGEON); row.name:SetTextColor(unpack(nd.allOk and T.dim or { 1, 0.62, 0.62 }))
      row.npc:SetText(nd.allOk and ("|cff59e67a" .. L.S_DONE .. "|r") or ""); row.npc:ClearAllPoints(); row.npc:SetPoint("TOPRIGHT", -6, -5)
      row.gb:Hide(); row.wpOn:Hide(); row.wpBar:Hide(); row.pip:Hide(); row.icon:Hide()
      row.kicon:SetTexture(nd.bossIdx > 0 and "Interface\\TargetingFrame\\UI-TargetingFrame-Skull" or "Interface\\Icons\\INV_Misc_Map_01")
      row.kicon:SetTexCoord(0, 1, 0, 1); row.kicon:Show()
      row.name:SetWidth(CW - 160)
      local sub = (not nd.allOk and nd.tip) and ("|cffa8acb4" .. nd.tip .. "|r") or ""
      row.sub:SetText(sub); row.sub:SetShown(sub ~= "")
      local rh = (sub ~= "") and (24 + row.sub:GetStringHeight() + 6) or 26
      row:SetHeight(rh); row:ClearAllPoints(); row:SetPoint("TOPLEFT", 6, -y)
      y = y + rh + 2
      row:Show()
    elseif nd then
      row.node = nd
      local q = ns.Q[nd.q] or {}
      local s = ns.State(log, nd.q)
      local ok = (nd.vok ~= nil) and nd.vok or ns.NodeOK(log, nd)
      local kc = T.kind[nd.kind] or T.text
      row.tag:SetText(L[KTAG[nd.kind]] or ""); row.tag:SetTextColor(kc[1], kc[2], kc[3])
      row.name:SetText(nd.label or ns.QName(nd.q))
      local right = nd.npc and not nd.ins and nd.npc:gsub(",.*$", "") or (SCOL[s] .. L[SLABEL[s]] .. "|r")
      row.npc:SetText(right)
      SetSecureRow(row, nd, ok)
      row.gb:SetShown(nd.loc ~= nil)
      local isActive = nd.loc and ns.active[ns.PKey(nd.loc.m, nd.loc.x, nd.loc.y)] and not ok
      row.wpOn:SetShown(isActive and true or false); row.wpBar:SetShown(isActive and true or false)
      if nd.loc then
        row.gb.icon:SetTexture(ns.IsLoaded("EllesmereUI") and "Interface\\AddOns\\EllesmereUI\\media\\icons\\eui-directions.png" or "Interface\\Minimap\\MiniMap-QuestArrow")
        if isActive then row.gb.icon:SetVertexColor(T.accent[1], T.accent[2], T.accent[3]) else row.gb.icon:SetVertexColor(0.85, 0.87, 0.9) end
      end
      local x = -4
      for _, b in ipairs({ row.gb }) do
        if b:IsShown() then b:ClearAllPoints(); b:SetPoint("TOPRIGHT", x, -2); x = x - 24 end
      end
      row.npc:ClearAllPoints(); row.npc:SetPoint("TOPRIGHT", x - 2, -5)
      local npcW = math.min(row.npc:GetStringWidth() + 2, 150)
      row.npc:SetWidth(npcW)
      row.name:SetWidth(math.max(80, CW - 90 - npcW + x))
      if ok then
        row.icon:Show(); row.pip:Hide(); row.kicon:Hide(); row.name:SetTextColor(unpack(T.dim)); row.tag:SetAlpha(0.5)
      else
        row.icon:Hide()
        local ki = KindIcon(nd)
        if ki then row.kicon:SetTexture(ki); row.kicon:SetTexCoord(0, 1, 0, 1); if nd.kind == "i" or nd.kind == "o" then row.kicon:SetTexCoord(0.08, 0.92, 0.08, 0.92) end; row.kicon:Show(); row.pip:Hide()
        else row.kicon:Hide(); row.pip:Show(); row.pip:SetColorTexture(kc[1], kc[2], kc[3], 1) end
        row.name:SetTextColor(unpack(T.text)); row.tag:SetAlpha(1)
      end
      -- sous-lignes
      local parts = {}
      local tags = ""
      if nd.d and nd.d ~= dkey then local c2 = DColor(nd.d); tags = tags .. Hex(c2) .. "[" .. ns.DName(nd.d) .. "]|r " end
      if nd.pre then tags = tags .. "|cffb0b0b0[" .. L.PRE .. "]|r " end
      if q.c then local cn, cc = ns.ClassInfo(q.c:match("^[^,]+")); tags = tags .. ns.ClassIconText(q.c:match("^[^,]+"), 12) .. Hex(cc) .. "[" .. L.CLASS_TAG:format(cn) .. "]|r " end
      if tags ~= "" then table.insert(parts, (tags:gsub("%s+$", ""))) end
      if not ok then
        if nd.kind == "a" and s == "none" then
          local pb = ns.PrereqProblem(nd.q)
          if pb then table.insert(parts, "|cffff6060" .. L.BLOCKED:format(pb) .. "|r") end
        end
        if nd.kind == "h" then
          local A = q.s and q.s.n or q.st
          if A then table.insert(parts, "|cffe6c48a" .. L.GIVER:format(A) .. "|r") end
        elseif nd.kind ~= "t" then
          local obj = (ns.lang == "fr" and q.of) or ns.T(q.oe)
          local lines = (nd.kind == "c" or nd.kind == "o") and ObjectiveLines(nd) or {}
          if obj and (nd.kind == "a" or #lines == 0) then table.insert(parts, "|cffd8dbe0" .. obj .. "|r") end
          if nd.kind == "c" or nd.kind == "o" then
            for _, l2 in ipairs(ObjectiveLines(nd)) do table.insert(parts, "|cffb8bcc4- " .. l2 .. "|r") end
          end
          if nd.kind == "a" and q.si then table.insert(parts, "|cffe6c48a" .. q.si .. (q.sih and (" : " .. ns.T(q.sih)) or "") .. "|r") end
          if q.ne and (nd.firstOfQuest ~= false) and (nd.kind == "c" or nd.kind == "o" or (nd.kind == "a" and not q.o)) then table.insert(parts, "|cffe6c48a" .. ns.T(q.ne) .. "|r") end
          if nd.extra then table.insert(parts, "|cffe6c48a" .. nd.extra .. "|r") end
          if nd.kind == "c" and ns.BossLines and not nd.oneObj then
            for _, bl in ipairs(ns.BossLines(nd.q) or {}) do
              table.insert(parts, "|cffff7070" .. L.BOSS .. " : " .. bl[1] .. "|r" .. (bl[2] and ("  |cffa8acb4" .. bl[2] .. "|r") or ""))
            end
          end
        end
        if nd.kind == "t" and s == "on" then
          -- quête pas encore terminée au moment de la rendre : rappeler quoi faire
          local obj = (ns.lang == "fr" and q.of) or ns.T(q.oe)
          if obj then table.insert(parts, "|cffd8dbe0" .. obj .. "|r") end
        end
        if (nd.kind == "t" and s == "on") or (nd.kind == "c" and #ObjectiveLines(nd) == 0) then
          for _, r in ipairs(q.req or {}) do
            table.insert(parts, "|cffb8bcc4- " .. r[1] .. (r[2] and r[2] > 1 and (" x" .. r[2]) or "") .. (r[3] and (" : " .. ns.T(r[3])) or "") .. "|r")
          end
        end
        if nd.unknown then table.insert(parts, "|cff9a9a9a" .. L.TRAVEL_UNK .. "|r") end
        if (nd.kind == "h" or nd.kind == "c" or nd.kind == "a") and ns.PartyLine and nd.firstOfQuest ~= false then
          local pl = ns.PartyLine(nd.q)
          if pl then table.insert(parts, "|cff9fd8ff" .. pl .. "|r") end
        end
      end
      local sub = table.concat(parts, "\n")
      row.sub:SetText(sub); row.sub:SetShown(sub ~= "")
      local rh = (sub ~= "") and (24 + row.sub:GetStringHeight() + 6) or 26
      row:SetHeight(rh)
      row:ClearAllPoints(); row:SetPoint("TOPLEFT", 6, -y)
      y = y + rh + 9
      row:Show()
    else
      row.node = nil; row:Hide()
    end
  end
  card:SetHeight(y + 6)
  local hh = math.min(y + 8, CARD_MAX)
  holder:SetHeight(hh)
  local over = y + 8 - hh
  if over > 0 then
    holder.sbar:ClearAllPoints()
    local frac = hh / (y + 8)
    holder.sbar:SetHeight(math.max(20, hh * frac))
    local off = (f.scroll.offset or 0) / over
    holder.sbar:SetPoint("TOPRIGHT", 0, -2 - (hh - holder.sbar:GetHeight() - 4) * math.min(1, off))
    holder.over, holder.track = over, hh - holder.sbar:GetHeight() - 4
    holder.sbar:Show()
  else holder.sbar:Hide(); f.scroll.offset = 0 end
  f.scroll:SetVerticalScroll(math.min(f.scroll.offset or 0, math.max(0, over)))

  f.prev:SetEnabled(i > 1); f.next:SetEnabled(i < #steps)
  f.cur:SetEnabled(f.auto ~= nil and i ~= f.auto)
  local np = #StepPoints(log, st, true)
  f.way:SetEnabled(np > 0)
  f.way.label:SetText((not ns.HasTomTom() and np > 1 and f.wpKey == i) and L.NEXTPOINT or L.POINTS)
  f.share:SetEnabled(IsInGroup() and true or false)
  f.done:SetEnabled(true)
  f.done.label:SetText(Manual(st) and L.UNDO or L.DONE)
  f.autoBtn.label:SetText(WLDTDB.autoWay and L.AUTO_ON or L.AUTO_OFF)
  f.arrowBtn.label:SetTextColor(unpack(WLDTDB.arrow ~= false and T.accent or T.dim))

  f:SetHeight(70 + hh + 12 + 56 + PAD)
  WLDTDB.view = i
  RenderList(log)
  if not f.pinned and not InCombatLockdown() then f.pinned = true; ns.PinTopLeft() end
  ns.UpdateActionBar()
  if f.lastShown ~= i then f.lastShown = i; card.fade:Stop(); card.fade:Play() end
end
ns.Render = function() if f then Render() end end

-- =====================================================================
--  Suivi de l'étape en cours
-- =====================================================================
function ns.Refresh(silent)
  if not f then return end
  local steps = Steps()
  if #steps == 0 then Render() return end
  local log = ns.LogEntries()
  local auto = FirstOpen(log)
  if auto ~= f.auto then
    local follow = (f.view == nil) or (f.view == f.auto)
    local was = f.auto
    f.auto = auto
    if follow then f.view = auto; f.scroll.offset = 0 end
    if was and auto > was and not silent then
      PlaySound(SOUNDKIT and SOUNDKIT.IG_QUEST_LIST_COMPLETE or 878)
      local t = StepTitle(steps[auto])
      if UIErrorsFrame then UIErrorsFrame:AddMessage("DG : " .. t, T.accent[1], T.accent[2], T.accent[3]) end
      ns.Print(L.NEXT_STEP:format(t))
    end
  end
  if WLDTDB.autoWay then
    local pts = StepPoints(log, steps[auto], false)
    local sig = auto .. ":" .. #pts
    for _, p in ipairs(pts) do sig = sig .. p[2] .. p[3] end
    if sig ~= f.sig then f.sig = sig; f.wpKey = nil; ns.SetPoints(pts, true) end
  end
  Render()
  ns.UpdateMacro()
end

-- =====================================================================
--  Macro « DG_Cible » : cible + crâne sur les mobs / PNJ de l'étape en cours,
--  mise à jour automatique à chaque étape (hors combat : le jeu bloque les macros en combat).
-- =====================================================================
local MACRO = "DG_Cible"
local macroPending, macroBody, macroWarned
function ns.UpdateMacro()
  if WLDTDB.macro == false or not (CreateMacro and EditMacro and GetMacroIndexByName) then return end
  if InCombatLockdown and InCombatLockdown() then macroPending = true return end
  macroPending = false
  local steps = Steps()
  local log = ns.LogEntries()
  local st = f and f.auto and steps[f.auto]
  local names, seen = {}, {}
  if st then
    for _, n in ipairs(st.acts) do
      if not ns.NodeOK(log, n) then
        for _, nm in ipairs(NodeTargets(n) or {}) do
          if not seen[nm] then seen[nm] = true; table.insert(names, nm) end
        end
      end
    end
  end
  local tail = "/run if UnitExists'target'and GetRaidTargetIndex'target'~=8 then SetRaidTarget('target',8)end"
  local body
  if #names > 0 then
    local m = { "/cleartarget" }
    local len = #m[1] + #tail + 2
    for _, nm in ipairs(names) do
      local line = "/targetexact " .. nm
      if len + #line + 1 > 255 then break end
      table.insert(m, line); len = len + #line + 1
    end
    table.insert(m, tail)
    body = table.concat(m, "\n")
  else
    body = "/run print('|cff0cd29dDG|r " .. L.MACRO_NONE:gsub("'", "\\'") .. "')"
  end
  if body == macroBody and GetMacroIndexByName(MACRO) > 0 then return end
  macroBody = body
  local idx = GetMacroIndexByName(MACRO)
  if idx and idx > 0 then
    pcall(EditMacro, idx, MACRO, nil, body)
  else
    local _, nChar = GetNumMacros()
    local maxChar = MAX_CHARACTER_MACROS or 18
    if nChar and nChar >= maxChar then
      if not macroWarned then macroWarned = true; ns.Print(L.MACRO_FULL) end
      return
    end
    local ok = pcall(CreateMacro, MACRO, "INV_Misc_QuestionMark", body, true)
    if ok then ns.Print(L.MACRO_MADE:format(MACRO)) end
  end
end
function ns.MacroPending() return macroPending end

-- =====================================================================
--  Fenêtre ancrée par son coin haut-gauche : sa hauteur peut changer (même en combat)
--  sans qu'elle bouge, et la barre d'actions reste collée au-dessus.
-- =====================================================================
function ns.PinTopLeft()
  if not f or not f:GetLeft() then return end
  local s = f:GetEffectiveScale() / UIParent:GetEffectiveScale()
  local x, y = f:GetLeft() * s, f:GetTop() * s
  f:ClearAllPoints(); f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x / s, y / s)
  WLDTDB.pos = { "TOPLEFT", "BOTTOMLEFT", x / s, y / s }
end

-- =====================================================================
--  Barre d'actions (boutons sécurisés) : cibler + crâne, utiliser l'objet de quête.
--  Fenêtre à part, attachée à l'écran : utilisable en combat ; son contenu se met à jour hors combat.
-- =====================================================================
local abar, abPending
local AB_N, AB_S = 8, 30
local function BuildActionBar()
  abar = CreateFrame("Frame", "WLDTActionBar", UIParent)
  abar:SetSize(AB_S, AB_S); abar:SetFrameStrata("MEDIUM")
  abar.label = Text(abar, 10, T.dim, true); abar.label:SetPoint("LEFT", 2, 0); abar.label:SetText(L.AB_LABEL)
  abar.btns = {}
  for k = 1, AB_N do
    local b = CreateFrame("Button", "WLDTAction" .. k, abar, "SecureActionButtonTemplate")
    b:SetSize(AB_S, AB_S); b:RegisterForClicks("AnyUp", "AnyDown")
    ns.Flat(b, { 0.06, 0.065, 0.075, 0.95 })
    b.icon = b:CreateTexture(nil, "ARTWORK"); b.icon:SetPoint("TOPLEFT", 2, -2); b.icon:SetPoint("BOTTOMRIGHT", -2, 2)
    b.hl = Tex(b, "HIGHLIGHT", { 1, 1, 1, 0.25 }); b.hl:SetAllPoints()
    b.num = Text(b, 12, { 1, 1, 1 }, true, "OUTLINE"); b.num:SetPoint("BOTTOMRIGHT", -1, 1)
    b:SetScript("OnEnter", function(self)
      local a = self.action
      if not a then return end
      if a.item then
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        if GameTooltip.SetItemByID then GameTooltip:SetItemByID(a.item) end
        GameTooltip:AddLine(L.TT_USE, T.accent[1], T.accent[2], T.accent[3]); GameTooltip:Show()
      else
        ns.ShowTip(self, { L.TT_TARGET, { L.TT_TARGET2:format(table.concat(a.names, " / ")), 0.85, 0.85, 0.85 }, { L.TT_RAID, 0.6, 0.6, 0.6 } })
      end
    end)
    b:SetScript("OnLeave", ns.HideTip)
    b:Hide()
    abar.btns[k] = b
  end
  abar:Hide()
end

function ns.UpdateActionBar()
  if not f then return end
  if not abar then BuildActionBar() end
  if InCombatLockdown() then abPending = true return end
  abPending = false
  local steps = Steps()
  local st = steps[f.view or 0]
  local acts, seen = {}, {}
  if st and f:IsShown() and not f.mini then
    local log = ns.LogEntries()
    local count = (C_Item and C_Item.GetItemCount) or GetItemCount
    local view = ns.StepView(st, log)
    local grouped = false
    for _, n in ipairs(view) do if n.kind == "b" then grouped = true break end end
    if st.split then
      grouped = true
      local cur = { names = {}, nseen = {}, num = (st.bossIdx and st.bossIdx > 0 and st.bossIdx < 999) and tostring(st.bossIdx) or "*" }
      if st.bossEn then cur.nseen[st.bossEn] = true; table.insert(cur.names, st.bossEn) end
      for _, n in ipairs(st.acts) do
        if not ns.NodeOK(log, n) then
          for _, t in ipairs(NodeTargets(n) or {}) do
            if not cur.nseen[t] and #cur.names < 4 then cur.nseen[t] = true; table.insert(cur.names, t) end
          end
          local q = ns.Q[n.q] or {}
          for _, id in ipairs(n.items or q.use or {}) do
            if not seen["i" .. id] and count and (count(id) or 0) > 0 then seen["i" .. id] = true; table.insert(acts, { item = id }) end
          end
        end
      end
      if #cur.names > 0 then table.insert(acts, 1, cur) end
      view = {}
    end
    if grouped then
      -- un crâne par boss (numéroté comme dans la liste), dans l'ordre du donjon
      local cur
      for _, n in ipairs(view) do
        if n.kind == "b" then
          cur = nil
          if not n.allOk then
            cur = { names = {}, num = n.bossIdx > 0 and tostring(n.bossIdx) or "*", nseen = {} }
            for _, t in ipairs(n.targets or {}) do cur.nseen[t] = true; table.insert(cur.names, t) end
            table.insert(acts, cur)
          end
        elseif cur and not ((n.vok ~= nil) and n.vok or ns.NodeOK(log, n)) then
          for _, t in ipairs(NodeTargets(n) or {}) do
            if not cur.nseen[t] and #cur.names < 4 then cur.nseen[t] = true; table.insert(cur.names, t) end
          end
        end
        if n.kind ~= "b" then
          local q = ns.Q[n.q] or {}
          for _, id in ipairs(n.items or q.use or {}) do
            if not seen["i" .. id] and count and (count(id) or 0) > 0 then seen["i" .. id] = true; table.insert(acts, { item = id }) end
          end
        end
      end
      for k = #acts, 1, -1 do if acts[k].names and #acts[k].names == 0 then table.remove(acts, k) end end
    end
    for _, n in ipairs(grouped and {} or st.acts) do
      if not ns.NodeOK(log, n) then
        local q = ns.Q[n.q] or {}
        for _, id in ipairs(n.items or q.use or {}) do
          if not seen["i" .. id] and count and (count(id) or 0) > 0 then seen["i" .. id] = true; table.insert(acts, { item = id }) end
        end
        for _, id in ipairs(n.useItems or {}) do
          if not seen["i" .. id] and count and (count(id) or 0) > 0 then seen["i" .. id] = true; table.insert(acts, { item = id }) end
        end
        local names = NodeTargets(n)
        if names and #names > 0 then
          local key = "t" .. table.concat(names, ",")
          if not seen[key] then seen[key] = true; table.insert(acts, { names = names }) end
        end
      end
    end
  end
  local labelW = abar.label:GetStringWidth() + 8
  for k = 1, AB_N do
    local b, a = abar.btns[k], acts[k]
    b.action = a
    if a then
      if a.item then
        b:SetAttribute("type", "item"); b:SetAttribute("item", "item:" .. a.item); b:SetAttribute("macrotext", nil)
        local icon = (C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(a.item)) or (GetItemIcon and GetItemIcon(a.item))
        b.icon:SetTexture(icon or "Interface\\Icons\\INV_Misc_QuestionMark"); b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
      else
        local m = { "/cleartarget" }
        for _, nm in ipairs(a.names) do table.insert(m, "/targetexact " .. nm) end
        table.insert(m, "/run if UnitExists('target') and GetRaidTargetIndex('target') ~= 8 then SetRaidTarget('target', 8) end")
        b:SetAttribute("type", "macro"); b:SetAttribute("macrotext", table.concat(m, "\n")); b:SetAttribute("item", nil)
        b.icon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_8"); b.icon:SetTexCoord(0, 1, 0, 1)
      end
      b.num:SetText(a.num or "")
      b:ClearAllPoints(); b:SetPoint("LEFT", labelW + (k - 1) * (AB_S + 4), 0); b:Show()
    else b:Hide() end
  end
  if #acts > 0 and f:IsShown() and f:GetLeft() then
    abar:SetSize(labelW + math.min(#acts, AB_N) * (AB_S + 4), AB_S)
    abar:ClearAllPoints()
    abar:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", f:GetLeft(), f:GetTop() + 4)
    abar:Show()
  else abar:Hide() end
end
function ns.ActionBarPending() return abPending end

function ns.ToggleMain()
  if not f then return end
  f:SetShown(not f:IsShown()); WLDTDB.hidden = not f:IsShown()
  if WLDTDB.hidden then ns.SetArrow(nil) end
  if ns.UpdateActionBar then ns.UpdateActionBar() end
end
