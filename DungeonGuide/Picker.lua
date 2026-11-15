-- Sélecteur de donjons : cartes avec image, niveau, progression ; plusieurs donjons = une route perso.
local ADDON, ns = ...
local L, T = ns.L, ns.T_
local Text, Tex, Button, Hex = ns.Text, ns.Tex, ns.Button, ns.Hex

local p, qp
local COLS, CW, CH, GAP = 4, 168, 112, 8
local PW = COLS * CW + (COLS - 1) * GAP + 28

-- Écrans de chargement du jeu pour les donjons Classic qui n'ont pas d'image dans les journaux
-- (mêmes fichiers que ForeverDungeonJournal utilise : ce sont les images du jeu lui-même)
local LS = "Interface\\Glues\\LoadingScreens\\"
local GAME_ART = {
  RagefireChasm = LS .. "LoadScreenRagefireChasm", WailingCaverns = LS .. "LoadScreenWailingCaverns",
  ShadowfangKeep = LS .. "LoadScreenShadowFangKeep", TheDeadmines = LS .. "LoadScreenDeadmines",
  BlackfathomDeeps = LS .. "LoadScreenBlackFathomDeeps", Gnomeregan = LS .. "LoadScreenGnomeregan",
  TheStockade = 131870, RazorfenKraul = 131865,
}
local function Art(tex, d, c)
  if c then c.bigIcon:Hide() end
  if d.art and ns.IsLoaded("ForeverDungeonJournal") then
    tex:SetTexture("Interface\\AddOns\\ForeverDungeonJournal\\Media\\" .. d.art); tex:SetTexCoord(0, 1, 0.1, 0.9); return true
  end
  local key = d.home or d.key
  if GAME_ART[key] then tex:SetTexture(GAME_ART[key]); tex:SetTexCoord(0.02, 0.98, 0.3, 0.75); return true end
  if d.nart then tex:SetTexture(d.nart); tex:SetTexCoord(0, 1, 0.3, 0.7); return true end
  -- pas d'image : fond sombre + icône du donjon au centre (au lieu d'une icône étirée)
  tex:SetColorTexture(0.10, 0.11, 0.13, 1)
  if c then c.bigIcon:SetTexture(d.icon or "Interface\\Icons\\INV_Misc_Map_01"); c.bigIcon:Show() end
  return false
end

local function Counts(dkey)
  local _, cls = UnitClass("player")
  local qs = ns.DungeonQuests(dkey, cls)
  local done = 0
  for _, qid in ipairs(qs) do if ns.IsDone(qid) then done = done + 1 end end
  return #qs, done
end

local function LevelOK(d)
  local lv = UnitLevel("player")
  local lo, hi = d.lvl and d.lvl[1] or 1, d.lvl and d.lvl[2] or 60
  return lv >= lo - 4 and lv <= hi + 1
end

local function Selected() return WLDTDB.sel end

-- Quêtes de classe : une carte par quête (liées aux donjons), créées à la volée
function ns.EnsureClassCards()
  if ns._cq then return end
  ns._cq = true
  local ids = {}
  for qid, q in pairs(ns.Q) do
    if q.c and q.role == "main" and q.fa ~= "Alliance" and not q.unk and qid > 0 then table.insert(ids, qid) end
  end
  table.sort(ids)
  for _, qid in ipairs(ids) do
    local q, dd = ns.Q[qid], ns.D[ns.Q[qid].d] or {}
    local key = "CQ" .. qid
    ns.D[key] = { key = key, n = q.n, nf = q.nf, lvl = { q.r or q.l or 1, q.l or q.r or 60 },
       art = dd.art, nart = dd.nart, icon = dd.icon, e = dd.e, ed = dd.ed, inst = dd.inst,
      cq = q.c, home = q.d, q = { qid } }
    table.insert(ns.ORDER, key)
  end
end

local function ClassMatch(d)
  local _, me = UnitClass("player")
  for tok in (d.cq or ""):gmatch("[^,]+") do if tok == me then return true end end
  return false
end

local function TabOf(d) return d.cq and "cls" or d.raid and "raid" or "dg" end
local function CurTab() return WLDTDB.tab or "dg" end

-- icône de classe officielle (atlas des cercles de classe)
local function SetClassIcon(tex, cls)
  local c = CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[cls]
  if c then tex:SetTexture("Interface\\TargetingFrame\\UI-Classes-Circles"); tex:SetTexCoord(c[1], c[2], c[3], c[4]); tex:Show()
  else tex:Hide() end
end
ns.SetClassIcon = SetClassIcon

local Render

local function MakeCard(parent)
  local c = CreateFrame("Button", nil, parent)
  c:SetSize(CW, CH)
  c:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  ns.Flat(c, { 0.08, 0.085, 0.095, 1 })
  c.art = c:CreateTexture(nil, "ARTWORK"); c.art:SetPoint("TOPLEFT", 1, -1); c.art:SetPoint("BOTTOMRIGHT", -1, 1)
  c.shade = c:CreateTexture(nil, "ARTWORK", nil, 2); c.shade:SetPoint("TOPLEFT", 1, -1); c.shade:SetPoint("BOTTOMRIGHT", -1, 1)
  c.shade:SetColorTexture(0, 0, 0, 0.55)
  c.hl = Tex(c, "HIGHLIGHT", { 1, 1, 1, 0.08 }); c.hl:SetAllPoints()
  c.selBorder = {}
  for _, side in ipairs({ "TOP", "BOTTOM", "LEFT", "RIGHT" }) do
    local e = c:CreateTexture(nil, "OVERLAY")
    if side == "TOP" or side == "BOTTOM" then e:SetPoint(side .. "LEFT"); e:SetPoint(side .. "RIGHT"); e:SetHeight(2)
    else e:SetPoint("TOP" .. side); e:SetPoint("BOTTOM" .. side); e:SetWidth(2) end
    ns.Accent(e); c.selBorder[side] = e
  end
  c.check = c:CreateTexture(nil, "OVERLAY"); c.check:SetSize(20, 20); c.check:SetPoint("TOPRIGHT", -6, -6)
  c.check:SetTexture("Interface\\RAIDFRAME\\ReadyCheck-Ready")
  c.name = Text(c, 14, T.text, true); c.name:SetPoint("BOTTOMLEFT", 8, 30); c.name:SetWidth(CW - 16); c.name:SetWordWrap(true)
  c.lvl = Text(c, 11, T.accent, true); c.lvl:SetPoint("TOPLEFT", 8, -8)
  c.info = Text(c, 11, T.dim); c.info:SetPoint("BOTTOMLEFT", 8, 10); c.info:SetWidth(CW - 16); c.info:SetWordWrap(false)
  c.bar = Tex(c, "OVERLAY", T.accent); c.bar:SetPoint("BOTTOMLEFT", 1, 1); c.bar:SetHeight(3); ns.Accent(c.bar)
  c.bigIcon = c:CreateTexture(nil, "ARTWORK", nil, 1); c.bigIcon:SetSize(40, 40); c.bigIcon:SetPoint("TOP", 0, -14); c.bigIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92); c.bigIcon:Hide()
  c.dicon = c:CreateTexture(nil, "OVERLAY"); c.dicon:SetSize(22, 22); c.dicon:SetPoint("TOPRIGHT", -30, -5); c.dicon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  c.cicon = c:CreateTexture(nil, "OVERLAY"); c.cicon:SetSize(24, 24); c.cicon:SetPoint("TOPRIGHT", -56, -4)
  c:SetScript("OnClick", function(self, btn)
    if btn == "RightButton" then ns.OpenQuests(self.dkey) return end
    Selected()[self.dkey] = not Selected()[self.dkey] or nil
    PlaySound(SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or 856)
    Render()
  end)
  c:SetScript("OnDoubleClick", function(self)
    wipe(Selected()); Selected()[self.dkey] = true; ns.StartGuide()
  end)
  c:SetScript("OnEnter", function(self)
    local d = ns.D[self.dkey]
    local n, done = Counts(self.dkey)
    local lines = { ns.DName(self.dkey), { (GetLocale and GetLocale() == "frFR" and d.locf) or ns.T(d.loc) or "", 0.7, 0.7, 0.7 },
      { L.PICK_QUESTS:format(n) .. "  ·  " .. L.PICK_DONE:format(done), 0.9, 0.9, 0.9 } }
    if d.cq and d.home then table.insert(lines, { L.CQ_IN:format(ns.DName(d.home)), T.accent[1], T.accent[2], T.accent[3] }) end
    if d.ed then table.insert(lines, { ns.T(d.ed), 0.85, 0.85, 0.85 }) end
    for _, k in ipairs(ns.KeyLines and ns.KeyLines(self.dkey) or {}) do table.insert(lines, { k[1], 0.9, 0.9, 0.9 }) end
    table.insert(lines, { " ", 1, 1, 1 })
    table.insert(lines, { L.PICK_HINT, T.accent[1], T.accent[2], T.accent[3] })
    table.insert(lines, { L.PICK_CUSTOM .. " : clic droit / right click", 0.6, 0.6, 0.6 })
    ns.ShowTip(self, lines)
  end)
  c:SetScript("OnLeave", ns.HideTip)
  return c
end

local function Build()
  p = CreateFrame("Frame", "WLDTPicker", UIParent)
  p:SetSize(PW, 560); p:SetPoint("CENTER"); p:SetFrameStrata("HIGH")
  p:SetMovable(true); p:EnableMouse(true); p:SetClampedToScreen(true); p:SetToplevel(true)
  ns.Flat(p, T.bg)
  local h = CreateFrame("Frame", nil, p)
  h:SetPoint("TOPLEFT", 1, -1); h:SetPoint("TOPRIGHT", -1, -1); h:SetHeight(32)
  h.bg = Tex(h, "BACKGROUND", T.header); h.bg:SetAllPoints()
  h.line = Tex(h, "ARTWORK", T.accent); h.line:SetPoint("BOTTOMLEFT"); h.line:SetPoint("BOTTOMRIGHT"); h.line:SetHeight(1); ns.Accent(h.line, 0.6)
  h:EnableMouse(true); h:RegisterForDrag("LeftButton")
  h:SetScript("OnDragStart", function() p:StartMoving() end)
  h:SetScript("OnDragStop", function() p:StopMovingOrSizing() end)
  h.logo = h:CreateTexture(nil, "ARTWORK"); h.logo:SetSize(26, 26); h.logo:SetPoint("LEFT", 6, -1)
  h.logo:SetTexture("Interface\\AddOns\\" .. ADDON .. "\\Media\\Logo64")
  h.title = Text(h, 14, T.text, true); h.title:SetPoint("LEFT", 34, 0); h.title:SetText(L.TITLE)
  p.tabs = {}
  local prevTab
  for _, t in ipairs({ { "dg", L.TAB_DG }, { "raid", L.TAB_RAID }, { "cls", L.TAB_CLS } }) do
    local b = Button(h, 104, 22, t[2], function() WLDTDB.tab = t[1]; p.sf.off = 0; p.sf:SetVerticalScroll(0); Render() end)
    if prevTab then b:SetPoint("LEFT", prevTab, "RIGHT", 4, 0) else b:SetPoint("LEFT", h.title, "RIGHT", 16, 0) end
    b.tabKey = t[1]; table.insert(p.tabs, b); prevTab = b
  end
  local close = Button(h, 22, 20, "x", function() p:Hide() end); close:SetPoint("RIGHT", -5, 0)
  p.allBtn = Button(h, 60, 20, L.PICK_ALL, function() WLDTDB.pickAll = true; Render() end); p.allBtn:SetPoint("RIGHT", close, "LEFT", -6, 0)
  p.mineBtn = Button(h, 90, 20, L.PICK_MINE, function() WLDTDB.pickAll = false; Render() end); p.mineBtn:SetPoint("RIGHT", p.allBtn, "LEFT", -4, 0)
  p.hint = Text(p, 12, T.dim); p.hint:SetPoint("TOPLEFT", 14, -42); p.hint:SetWidth(PW - 28); p.hint:SetText(L.PICK_HINT)

  local sf = CreateFrame("ScrollFrame", nil, p)
  sf:SetPoint("TOPLEFT", 14, -64); sf:SetPoint("BOTTOMRIGHT", -14, 52)
  local grid = CreateFrame("Frame", nil, sf); grid:SetSize(PW - 28, 100); sf:SetScrollChild(grid)
  sf:EnableMouseWheel(true)
  sf:SetScript("OnMouseWheel", function(self, delta)
    local max = math.max(0, grid:GetHeight() - self:GetHeight())
    self.off = math.max(0, math.min(max, (self.off or 0) - delta * 60)); self:SetVerticalScroll(self.off)
  end)
  p.sf, p.grid, p.cards = sf, grid, {}

  p.selText = Text(p, 12, T.text, true); p.selText:SetPoint("BOTTOMLEFT", 14, 20)
  p.go = Button(p, 150, 28, L.PICK_GO, function() ns.StartGuide() end); p.go:SetPoint("BOTTOMRIGHT", -14, 12); ns.Primary(p.go)
  p.none = Button(p, 120, 28, L.PICK_NONE, function() wipe(Selected()); Render() end); p.none:SetPoint("RIGHT", p.go, "LEFT", -8, 0)
  tinsert(UISpecialFrames, "WLDTPicker")
  p:Hide()
end

Render = function()
  if not p then return end
  ns.EnsureClassCards()
  local list = {}
  local tab = CurTab()
  for _, k in ipairs(ns.ORDER) do
    local d = ns.D[k]
    if TabOf(d) == tab then
      local n = Counts(k)
      local ok
      if tab == "cls" then ok = ClassMatch(d) and (WLDTDB.pickAll or LevelOK(d))
      elseif tab == "raid" then ok = true
      else ok = (WLDTDB.pickAll or LevelOK(d)) and (n > 0 or WLDTDB.pickAll) end
      if ok then table.insert(list, k) end
    end
  end
  for _, b in ipairs(p.tabs) do
    local on = b.tabKey == tab
    b.label:SetTextColor(unpack(on and T.accent or T.dim))
    if b.under then b.under:SetShown(on) else
      b.under = Tex(b, "OVERLAY", T.accent); b.under:SetPoint("BOTTOMLEFT", 4, 1); b.under:SetPoint("BOTTOMRIGHT", -4, 1); b.under:SetHeight(2); ns.Accent(b.under); b.under:SetShown(on)
    end
  end
  p.hint:SetText(tab == "cls" and L.PICK_HINT_CLS or tab == "raid" and L.PICK_HINT_RAID or L.PICK_HINT)
  p.empty = p.empty or Text(p.grid, 13, T.dim)
  p.empty:SetPoint("TOP", 0, -40); p.empty:SetText(#list == 0 and (tab == "cls" and L.PICK_EMPTY_CLS or L.PICK_EMPTY) or "")
  table.sort(list, function(a, b)
    local la, lb = ns.D[a].lvl and ns.D[a].lvl[1] or 0, ns.D[b].lvl and ns.D[b].lvl[1] or 0
    if la ~= lb then return la < lb end
    return a < b
  end)
  for i, k in ipairs(list) do
    local c = p.cards[i] or MakeCard(p.grid); p.cards[i] = c
    local col, row = (i - 1) % COLS, math.floor((i - 1) / COLS)
    c:ClearAllPoints(); c:SetPoint("TOPLEFT", col * (CW + GAP), -row * (CH + GAP))
    local d = ns.D[k]
    c.dkey = k
    Art(c.art, d, c)
    c.dicon:Hide()
    if d.cq then SetClassIcon(c.cicon, (d.cq:match("^[^,]+"))) else c.cicon:Hide() end
    c.name:SetText(ns.DName(k))
    c.lvl:SetText((d.raid and (L.RAID .. "  ") or "") .. (d.lvl and d.lvl[1] and (d.lvl[1] .. "-" .. (d.lvl[2] or d.lvl[1])) or ""))
    local n, done = Counts(k)
    c.info:SetText(n > 0 and (L.PICK_QUESTS:format(n) .. "  ·  " .. L.PICK_DONE:format(done)) or L.PICK_NOQ)
    c.bar:SetWidth(math.max(1, (CW - 2) * (n > 0 and done / n or 0)))
    local sel = Selected()[k] and true or false
    c.check:SetShown(sel)
    for _, e in pairs(c.selBorder) do e:SetShown(sel) end
    c.shade:SetColorTexture(0, 0, 0, sel and 0.35 or (LevelOK(d) and 0.55 or 0.75))
    c:Show()
  end
  for i = #list + 1, #p.cards do p.cards[i]:Hide() end
  p.grid:SetHeight(math.ceil(#list / COLS) * (CH + GAP))
  local ns_ = 0; for _ in pairs(Selected()) do ns_ = ns_ + 1 end
  p.selText:SetText(L.PICK_SEL:format(ns_))
  p.go:SetEnabled(ns_ > 0)
  p.mineBtn.label:SetTextColor(unpack(WLDTDB.pickAll and T.dim or T.accent))
  p.allBtn.label:SetTextColor(unpack(WLDTDB.pickAll and T.accent or T.dim))
end
ns.RenderPicker = function() if p and p:IsShown() then Render() end end

function ns.TogglePicker()
  if not p then Build() end
  if p:IsShown() then p:Hide() else Render(); p:Show(); p:Raise() end
end
-- Opens the picker (buttons that say "pick dungeons" never close it).
function ns.ShowPicker()
  if not p then Build() end
  Render(); p:Show(); p:Raise()
end
function ns.HidePicker() if p then p:Hide() end end

-- =====================================================================
--  Choix des quêtes d'un donjon
-- =====================================================================
local QROWS = 22
local function BuildQuests()
  qp = CreateFrame("Frame", "WLDTQuestPicker", UIParent)
  qp:SetSize(460, 40 + QROWS * 22 + 16); qp:SetFrameStrata("DIALOG"); qp:SetPoint("CENTER", 120, 0)
  qp:SetMovable(true); qp:EnableMouse(true); qp:SetClampedToScreen(true)
  ns.Flat(qp, T.bg)
  local h = CreateFrame("Frame", nil, qp)
  h:SetPoint("TOPLEFT", 1, -1); h:SetPoint("TOPRIGHT", -1, -1); h:SetHeight(30)
  h.bg = Tex(h, "BACKGROUND", T.header); h.bg:SetAllPoints()
  h:EnableMouse(true); h:RegisterForDrag("LeftButton")
  h:SetScript("OnDragStart", function() qp:StartMoving() end); h:SetScript("OnDragStop", function() qp:StopMovingOrSizing() end)
  qp.title = Text(h, 12, T.text, true); qp.title:SetPoint("LEFT", 10, 0); qp.title:SetWidth(400); qp.title:SetWordWrap(false)
  local close = Button(h, 22, 20, "x", function() qp:Hide() end); close:SetPoint("RIGHT", -4, 0)
  qp.rows = {}
  for r = 1, QROWS do
    local row = CreateFrame("Button", nil, qp)
    row:SetHeight(22); row:SetPoint("TOPLEFT", 8, -34 - (r - 1) * 22); row:SetPoint("TOPRIGHT", -8, -34 - (r - 1) * 22)
    row.hl = Tex(row, "HIGHLIGHT", { 1, 1, 1, 0.06 }); row.hl:SetAllPoints()
    row.box = Tex(row, "ARTWORK", { 0.2, 0.2, 0.22 }); row.box:SetSize(14, 14); row.box:SetPoint("LEFT", 4, 0)
    row.tick = Tex(row, "OVERLAY", T.accent); row.tick:SetSize(8, 8); row.tick:SetPoint("CENTER", row.box); ns.Accent(row.tick)
    row.lvl = Text(row, 11, T.dim, true); row.lvl:SetPoint("LEFT", 24, 0); row.lvl:SetWidth(26); row.lvl:SetJustifyV("MIDDLE")
    row.txt = Text(row, 12, T.text); row.txt:SetPoint("LEFT", 52, 0); row.txt:SetPoint("RIGHT", -4, 0); row.txt:SetWordWrap(false); row.txt:SetJustifyV("MIDDLE")
    row:SetScript("OnClick", function(self)
      WLDTDB.off[self.qid] = not WLDTDB.off[self.qid] or nil
      ns.OpenQuests(qp.dkey, true)
    end)
    row:SetScript("OnEnter", function(self)
      local q = ns.Q[self.qid]
      local lines = { ns.QName(self.qid) }
      local obj = (ns.lang == "fr" and q.of) or ns.T(q.oe)
      if obj then table.insert(lines, { obj, 0.9, 0.9, 0.9 }) end
      if q.p and #q.p > 0 then table.insert(lines, { L.PRE .. " : " .. #q.p, 0.7, 0.7, 0.7 }) end
      if q.ne then table.insert(lines, { ns.T(q.ne), 1, 0.82, 0.5 }) end
      ns.ShowTip(self, lines)
    end)
    row:SetScript("OnLeave", ns.HideTip)
    qp.rows[r] = row
  end
  qp:Hide()
end

function ns.OpenQuests(dkey, keep)
  if not qp then BuildQuests() end
  local _, cls = UnitClass("player")
  qp.dkey = dkey
  qp.title:SetText(L.PICK_CUSTOM_T:format(ns.DName(dkey)))
  local qs = ns.DungeonQuests(dkey, cls)
  for r, row in ipairs(qp.rows) do
    local qid = qs[r]
    if qid then
      local q = ns.Q[qid]
      row.qid = qid
      row.lvl:SetText(q.l or "")
      local tag = ""
      if q.c then local cn, cc = ns.ClassInfo(q.c:match("^[^,]+")); tag = "  " .. Hex(cc) .. "(" .. cn .. ")|r" end
      if ns.IsDone(qid) then tag = tag .. "  |cff59e67a" .. L.S_DONE .. "|r" end
      row.txt:SetText(ns.QName(qid) .. tag)
      local on = not WLDTDB.off[qid]
      row.tick:SetShown(on)
      row.txt:SetTextColor(unpack(on and T.text or T.dim))
      row:Show()
    else row:Hide() end
  end
  qp:SetHeight(40 + math.max(1, math.min(#qs, QROWS)) * 22 + 12)
  qp:Show()
end
