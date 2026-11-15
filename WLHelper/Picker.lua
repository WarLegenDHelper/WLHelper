-- Sélecteur de donjons : cartes avec image, niveau, progression ; plusieurs donjons = une route perso.
local ADDON, ns = ...
local L, T = ns.L, ns.T_
local Text, Tex, Button, Hex = ns.Text, ns.Tex, ns.Button, ns.Hex

local p, qp
-- two columns of wide cards, the dungeon's picture in full
local COLS, CW, CH, GAP = 2, 384, 132, 10
local PW = COLS * CW + (COLS - 1) * GAP + 28

-- The game's own loading screens (files of the client, nothing shipped with the addon).
-- Sure ones first (also used by Forever Dungeon Journal); the others are tried and dropped when the
-- client has no such file. A dungeon with no picture gets a dark card and its icon.
local LS = "Interface\\Glues\\LoadingScreens\\"
local GAME_ART = {
  RagefireChasm = LS .. "LoadScreenRagefireChasm", WailingCaverns = LS .. "LoadScreenWailingCaverns",
  ShadowfangKeep = LS .. "LoadScreenShadowFangKeep", TheDeadmines = LS .. "LoadScreenDeadmines",
  BlackfathomDeeps = LS .. "LoadScreenBlackFathomDeeps", Gnomeregan = LS .. "LoadScreenGnomeregan",
  TheStockade = 131870, RazorfenKraul = 131865, ExcavationSiteWetlands = 7963777, CityofDalaran = 7963775,
  ScarletMonasteryGraveyard = LS .. "LoadScreenScarletMonastery2",
}
local MAYBE_ART = {
  RazorfenDowns = "LoadScreenRazorfenDowns", Uldaman = "LoadScreenUldaman", ZulFarrak = "LoadScreenZulFarrak",
  Maraudon = "LoadScreenMaraudon", SunkenTemple = "LoadScreenSunkenTemple", BlackrockDepths = "LoadScreenBlackrockDepths",
  LowerBlackrockSpire = "LoadScreenBlackrockSpire", UpperBlackrockSpire = "LoadScreenBlackrockSpire",
  DireMaulEast = "LoadScreenDireMaul", DireMaulWest = "LoadScreenDireMaul", DireMaulNorth = "LoadScreenDireMaul",
  StratholmeLiving = "LoadScreenStratholme", StratholmeUndead = "LoadScreenStratholme", Scholomance = "LoadScreenScholomance",
  ScarletMonasteryLibrary = "LoadScreenScarletMonastery", ScarletMonasteryArmory = "LoadScreenScarletMonastery",
  ScarletMonasteryCathedral = "LoadScreenScarletMonastery",
}
local missing = {}   -- paths the client does not have, tried once per session
local function TrySet(tex, path)
  if missing[path] then return false end
  local ok = tex:SetTexture(path)
  local id = tex.GetTextureFileID and tex:GetTextureFileID()
  if ok == false or (tex.GetTextureFileID and (not id or id == 0)) then missing[path] = true; return false end
  return true
end
local function Art(tex, d, c)
  if c then c.bigIcon:Hide() end
  tex:SetDesaturated(false)
  if d.art and ns.IsLoaded("ForeverDungeonJournal") then
    tex:SetTexture("Interface\\AddOns\\ForeverDungeonJournal\\Media\\" .. d.art); tex:SetTexCoord(0, 1, 0.12, 0.88); return true
  end
  local key = d.home or d.key
  if GAME_ART[key] then tex:SetTexture(GAME_ART[key]); tex:SetTexCoord(0.02, 0.98, 0.26, 0.74); return true end
  if MAYBE_ART[key] and TrySet(tex, LS .. MAYBE_ART[key]) then tex:SetTexCoord(0.02, 0.98, 0.26, 0.74); return true end
  if d.nart then tex:SetTexture(d.nart); tex:SetTexCoord(0, 1, 0.3, 0.7); return true end
  -- no picture: a dark card with the dungeon's icon (not a stretched icon)
  tex:SetColorTexture(0.10, 0.11, 0.13, 1)
  if c then c.bigIcon:SetTexture(d.icon or "Interface\\Icons\\INV_Misc_Map_01"); c.bigIcon:Show() end
  return false
end

-- a shade from transparent to dark, top or bottom of the card
local function Gradient(tex, fromTop, a)
  if tex.SetGradient and CreateColor then
    local dark, clear = CreateColor(0, 0, 0, a), CreateColor(0, 0, 0, 0)
    if pcall(tex.SetGradient, tex, "VERTICAL", fromTop and clear or dark, fromTop and dark or clear) then return end
  end
  if tex.SetGradientAlpha then
    if fromTop then tex:SetGradientAlpha("VERTICAL", 0, 0, 0, 0, 0, 0, 0, a) else tex:SetGradientAlpha("VERTICAL", 0, 0, 0, a, 0, 0, 0, 0) end
  else tex:SetAlpha(a * 0.6) end
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
  -- the picture stays bright: a light veil (darker for "later"), dark bands behind the texts only
  c.shade = c:CreateTexture(nil, "ARTWORK", nil, 2); c.shade:SetPoint("TOPLEFT", 1, -1); c.shade:SetPoint("BOTTOMRIGHT", -1, 1)
  c.shade:SetColorTexture(0, 0, 0, 0.15)
  c.topBand = c:CreateTexture(nil, "ARTWORK", nil, 3); c.topBand:SetPoint("TOPLEFT", 1, -1); c.topBand:SetPoint("TOPRIGHT", -1, -1); c.topBand:SetHeight(52)
  c.topBand:SetColorTexture(1, 1, 1, 1); Gradient(c.topBand, true, 0.8)
  c.botBand = c:CreateTexture(nil, "ARTWORK", nil, 3); c.botBand:SetPoint("BOTTOMLEFT", 1, 1); c.botBand:SetPoint("BOTTOMRIGHT", -1, 1); c.botBand:SetHeight(40)
  c.botBand:SetColorTexture(1, 1, 1, 1); Gradient(c.botBand, false, 0.85)
  c.hl = Tex(c, "HIGHLIGHT", { 1, 1, 1, 0.07 }); c.hl:SetAllPoints()
  c.selBorder = {}
  for _, side in ipairs({ "TOP", "BOTTOM", "LEFT", "RIGHT" }) do
    local e = c:CreateTexture(nil, "OVERLAY")
    if side == "TOP" or side == "BOTTOM" then e:SetPoint(side .. "LEFT"); e:SetPoint(side .. "RIGHT"); e:SetHeight(2)
    else e:SetPoint("TOP" .. side); e:SetPoint("BOTTOM" .. side); e:SetWidth(2) end
    ns.Accent(e); c.selBorder[side] = e
  end
  -- ticked for the route: red border and a check box tick; every quest done: a green check
  -- top: name on the left; quests on the right (faction emblem, "5/6 quests", green check once all done)
  c.name = Text(c, 17, T.text, true); c.name:SetPoint("TOPLEFT", 12, -10); c.name:SetPoint("RIGHT", c, "RIGHT", -150, 0)
  c.name:SetWordWrap(false); c.name:SetJustifyH("LEFT"); c.name:SetShadowOffset(1, -1); c.name:SetShadowColor(0, 0, 0, 1)
  c.info = Text(c, 13, { 1, 0.82, 0.45 }, true); c.info:SetPoint("TOPRIGHT", -12, -12); c.info:SetJustifyH("RIGHT")
  c.info:SetShadowOffset(1, -1); c.info:SetShadowColor(0, 0, 0, 1)
  c.faction = c:CreateTexture(nil, "OVERLAY"); c.faction:SetSize(24, 24); c.faction:SetPoint("RIGHT", c.info, "LEFT", -2, -1)
  c.faction:SetTexture("Interface\\TargetingFrame\\UI-PVP-Horde"); c.faction:SetTexCoord(0.06, 0.62, 0.02, 0.6)
  c.doneMark = c:CreateTexture(nil, "OVERLAY"); c.doneMark:SetSize(24, 24); c.doneMark:SetPoint("RIGHT", c.faction, "LEFT", -2, 1)
  c.doneMark:SetTexture("Interface\\RAIDFRAME\\ReadyCheck-Ready")
  c.cicon = c:CreateTexture(nil, "OVERLAY"); c.cicon:SetSize(22, 22); c.cicon:SetPoint("TOPLEFT", c.name, "BOTTOMLEFT", 0, -4)
  -- bottom: levels on the left, "Picked" on the right when ticked for the route
  c.lvl = Text(c, 12, T.text, true); c.lvl:SetPoint("BOTTOMLEFT", 12, 11)
  c.lvl:SetShadowOffset(1, -1); c.lvl:SetShadowColor(0, 0, 0, 1)
  c.check = c:CreateTexture(nil, "OVERLAY"); c.check:SetSize(22, 22); c.check:SetPoint("BOTTOMRIGHT", -8, 6)
  c.check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
  c.picked = Text(c, 12, T.text, true); c.picked:SetPoint("RIGHT", c.check, "LEFT", 0, 1)
  c.bar = Tex(c, "OVERLAY", T.accent); c.bar:SetPoint("BOTTOMLEFT", 1, 1); c.bar:SetHeight(3); ns.Accent(c.bar)
  c.bigIcon = c:CreateTexture(nil, "ARTWORK", nil, 1); c.bigIcon:SetSize(48, 48); c.bigIcon:SetPoint("CENTER", 0, -4); c.bigIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92); c.bigIcon:Hide()
  c.dicon = c:CreateTexture(nil, "OVERLAY"); c.dicon:Hide()
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
  p:SetSize(PW, 640); p:SetPoint("CENTER"); p:SetFrameStrata("HIGH")
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
  -- Sections, in this order: to do at your level, later (too high), done, then (All) no Horde quest.
  -- "My level" shows the first and the done ones; "All" shows every section.
  local tab = CurTab()
  local secs = { todo = {}, later = {}, done = {}, noq = {} }
  local list = {}
  local tooHigh = function(d) return d.lvl and d.lvl[1] and UnitLevel("player") < d.lvl[1] - 4 end
  for _, k in ipairs(ns.ORDER) do
    local d = ns.D[k]
    if TabOf(d) == tab and (tab ~= "cls" or ClassMatch(d)) then
      local n, done = Counts(k)
      local sec
      if n == 0 then sec = tab == "raid" and "todo" or "noq"
      elseif done >= n then sec = "done"
      elseif tooHigh(d) or not LevelOK(d) then sec = "later"
      else sec = "todo" end
      local show = WLDTDB.pickAll or sec == "todo" or sec == "done"
      if show then table.insert(secs[sec], k); table.insert(list, k) end
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
  local function byLevel(a, b)
    local la, lb = ns.D[a].lvl and ns.D[a].lvl[1] or 0, ns.D[b].lvl and ns.D[b].lvl[1] or 0
    if la ~= lb then return la < lb end
    return a < b
  end
  p.heads = p.heads or {}
  for _, h in ipairs(p.heads) do h:Hide() end
  local i, y, hi = 0, 0, 0
  for _, s in ipairs({ { "todo", L.SEC_TODO }, { "later", L.SEC_LATER }, { "done", L.SEC_DONE }, { "noq", L.SEC_NOQ } }) do
    local keys = secs[s[1]]
    if #keys > 0 then
      table.sort(keys, byLevel)
      hi = hi + 1
      local h = p.heads[hi] or Text(p.grid, 12, T.dim, true); p.heads[hi] = h
      h:ClearAllPoints(); h:SetPoint("TOPLEFT", 2, -y)
      h:SetText(ns.Upper(s[2]) .. "  ·  " .. #keys); h:Show()
      y = y + 22
      for j, k in ipairs(keys) do
        i = i + 1
        local c = p.cards[i] or MakeCard(p.grid); p.cards[i] = c
        local col, row = (j - 1) % COLS, math.floor((j - 1) / COLS)
        c:ClearAllPoints(); c:SetPoint("TOPLEFT", col * (CW + GAP), -(y + row * (CH + GAP)))
        c.section = s[1]
        local d = ns.D[k]
    c.dkey = k
    Art(c.art, d, c)
    c.dicon:Hide()
    if d.cq then SetClassIcon(c.cicon, (d.cq:match("^[^,]+"))) else c.cicon:Hide() end
    c.name:SetText(ns.DName(k))
    c.lvl:SetText((d.raid and (L.RAID .. "  ·  ") or "") .. (d.lvl and d.lvl[1] and (L.PICK_LV:format(d.lvl[1], d.lvl[2] or d.lvl[1])) or ""))
    local n, done = Counts(k)
    local finished = n > 0 and done >= n
    c.info:SetText(n > 0 and L.PICK_QN:format(done, n) or L.PICK_NOQ)
    local horde = UnitFactionGroup("player") ~= "Alliance"
    c.faction:SetTexture(horde and "Interface\\TargetingFrame\\UI-PVP-Horde" or "Interface\\TargetingFrame\\UI-PVP-Alliance")
    c.faction:SetShown(n > 0)
    c.bar:SetWidth(math.max(1, (CW - 2) * (n > 0 and done / n or 0)))
    if finished then c.bar:SetColorTexture(0.35, 0.86, 0.48, 1) else c.bar:SetColorTexture(T.accent[1], T.accent[2], T.accent[3], 1) end
    c.doneMark:SetShown(finished)
    c.lvl:SetTextColor(unpack(c.section == "later" and T.dim or T.text))
    local sel = Selected()[k] and true or false
    c.check:SetShown(sel)
    c.picked:SetText(sel and L.PICK_PICKED or "")
    for _, e in pairs(c.selBorder) do e:SetShown(sel) end
    -- later (too high) and done: greyed; to do: the picture as it is
    c.art:SetDesaturated(c.section == "later" or c.section == "noq")
    c.shade:SetColorTexture(0, 0, 0, (c.section == "todo" or sel) and 0.12 or 0.45)
    c:Show()
      end
      y = y + math.ceil(#keys / COLS) * (CH + GAP) + 8
    end
  end
  for j = i + 1, #p.cards do p.cards[j]:Hide() end
  p.grid:SetHeight(math.max(10, y))
  local ns_ = 0; for _ in pairs(Selected()) do ns_ = ns_ + 1 end
  p.selText:SetText(L.PICK_SEL:format(ns_))
  p.go:SetEnabled(ns_ > 0)
  p.mineBtn.label:SetTextColor(unpack(WLDTDB.pickAll and T.dim or T.accent))
  p.allBtn.label:SetTextColor(unpack(WLDTDB.pickAll and T.accent or T.dim))
end
ns.RenderPicker = function() if p and p:IsShown() then Render() end end

local function GuideOff()
  local WP = ns.Writs and ns.Writs.WP
  return WP and WP.ModuleOff and WP.ModuleOff("dungeons")
end

function ns.TogglePicker()
  if p and p:IsShown() then p:Hide(); return end
  if GuideOff() then return end
  if not p then Build() end
  if p:IsShown() then p:Hide() else Render(); p:Show(); p:Raise() end
end
-- Opens the picker (buttons that say "pick dungeons" never close it).
function ns.ShowPicker()
  if GuideOff() then return end
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
