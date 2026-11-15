-- Choisir les donjons : cartes avec image, niveau, progression ; plusieurs donjons = une route.
-- Built with the design system (docs/DESIGN.md): header 44, tabs, a 640 px window that fits its
-- cards, a footer with the one main action.
local ADDON, ns = ...
local L, T = ns.L, ns.T_
local Text, Tex, Hex = ns.Text, ns.Tex, ns.Hex

local p, qp
-- two columns of picture cards inside a 640 window (inset 16, 12 between cards)
local PW, PAD, GAP = 640, 16, 12
local COLS = 2
local CW = math.floor((PW - 2 * PAD - (COLS - 1) * GAP) / COLS)
local CH = 124   -- room for a 2-line name on top and a 2-line level line at the bottom
local HEADER = 44

-- The design system (Writs/Style.lua) is required: a clear error rather than a nil index later.
local function SW()
  local S = ns.Writs and ns.Writs.S
  if not S then error("WL Helper: Writs/Style.lua missing") end
  return S
end
local function num(v) return type(v) == "number" and not (issecretvalue and issecretvalue(v)) and v or nil end
local function ScreenCap() return math.floor((num(UIParent:GetHeight()) or 768) * 0.80) end

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
-- ForeverDungeonJournal present in the AddOns folder (loaded or not)
local fdj
function ns.FDJInstalled()
  if fdj ~= nil then return fdj end
  fdj = false
  local info = (C_AddOns and C_AddOns.GetAddOnInfo) or GetAddOnInfo
  if info then
    local ok, name, _, _, _, reason = pcall(info, "ForeverDungeonJournal")
    fdj = (ok and name ~= nil and reason ~= "MISSING") and true or false
  end
  return fdj
end
local function Art(tex, d, c)
  if c then c.bigIcon:Hide() end
  tex:SetDesaturated(false)
  -- ForeverDungeonJournal's pictures are read from its folder when it is installed, even switched
  -- off (only the picture file is shown, nothing of its code runs)
  if d.art and (ns.IsLoaded("ForeverDungeonJournal") or ns.FDJInstalled()) then
    tex:SetTexture("Interface\\AddOns\\ForeverDungeonJournal\\Media\\" .. d.art); tex:SetTexCoord(0, 1, 0.12, 0.88); return true
  end
  local key = d.home or d.key
  -- the Scarlet Monastery wings share the game's one Monastery picture when there is no other
  if key and key:find("^ScarletMonastery") then key = "ScarletMonasteryGraveyard" end
  if GAME_ART[key] then tex:SetTexture(GAME_ART[key]); tex:SetTexCoord(0.02, 0.98, 0.26, 0.74); return true end
  if MAYBE_ART[key] and TrySet(tex, LS .. MAYBE_ART[key]) then tex:SetTexCoord(0.02, 0.98, 0.26, 0.74); return true end
  if d.nart then tex:SetTexture(d.nart); tex:SetTexCoord(0, 1, 0.3, 0.7); return true end
  -- no picture: a dark card with the dungeon's painted icon (not a stretched icon)
  tex:SetColorTexture(T.panel[1], T.panel[2], T.panel[3], 1)
  if c then ns.SetPainted(c.bigIcon, d.icon or "Interface\\Icons\\INV_Misc_Map_01", 40); c.bigIcon:Show() end
  return false
end
-- the same picture for other windows (the Events page's dungeon picker): the texture, the dungeon's
-- key and, optionally, a texture that shows the dungeon's icon when there is no picture
function ns.DungeonArt(tex, dkey, bigIcon)
  local d = ns.D and ns.D[dkey]
  if not d then tex:SetColorTexture(T.panel[1], T.panel[2], T.panel[3], 1); if bigIcon then bigIcon:Hide() end; return false end
  return Art(tex, d, bigIcon and { bigIcon = bigIcon } or nil)
end

local function Counts(dkey)
  local _, cls = UnitClass("player")
  local qs = ns.DungeonQuests(dkey, cls)
  local done = 0
  for _, qid in ipairs(qs) do if ns.IsDone(qid) then done = done + 1 end end
  return #qs, done
end

-- Quests of a dungeon, not turned in yet, that still wait on a prerequisite (Overview.lua's helper).
local function PreCount(dkey)
  if not ns.QuestPreInfo then return 0 end
  local _, cls = UnitClass("player")
  local log = ns.LogEntries()
  local n = 0
  for _, qid in ipairs(ns.DungeonQuests(dkey, cls)) do
    if not ns.IsDone(qid) then
      local pre = ns.QuestPreInfo(qid, log, cls)
      if pre.done < pre.total then n = n + 1 end
    end
  end
  return n
end

local function LevelOK(d)
  local lv = UnitLevel("player")
  local lo, hi = d.lvl and d.lvl[1] or 1, d.lvl and d.lvl[2] or 60
  return lv >= lo - 4 and lv <= hi + 1
end

local function Selected() return WLDTDB.sel end
local function SelCount() local n = 0; for _ in pairs(Selected()) do n = n + 1 end; return n end

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

-- A card: the dungeon's picture, a dark band behind each line of text (the picture stays bright),
-- the name alone on top (full width, up to 2 lines), the quests and the level in the bottom band,
-- a 1 px accent border and a "Picked" pill when it is in the route, a thin bar of the quests done.
local function MakeCard(parent)
  local S = SW()
  local c = CreateFrame("Button", nil, parent)
  c:SetSize(CW, CH)
  c:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  ns.Flat(c, T.panel, T.cardEdge)
  c.art = c:CreateTexture(nil, "ARTWORK"); c.art:SetPoint("TOPLEFT", 1, -1); c.art:SetPoint("BOTTOMRIGHT", -1, 1)
  c.shade = c:CreateTexture(nil, "ARTWORK", nil, 2); c.shade:SetPoint("TOPLEFT", 1, -1); c.shade:SetPoint("BOTTOMRIGHT", -1, 1)
  c.shade:SetColorTexture(0, 0, 0, 0.15)
  c.topBand = c:CreateTexture(nil, "ARTWORK", nil, 3); c.topBand:SetPoint("TOPLEFT", 1, -1); c.topBand:SetPoint("TOPRIGHT", -1, -1); c.topBand:SetHeight(36)
  c.topBand:SetColorTexture(0, 0, 0, 0.55)
  c.botBand = c:CreateTexture(nil, "ARTWORK", nil, 3); c.botBand:SetPoint("BOTTOMLEFT", 1, 1); c.botBand:SetPoint("BOTTOMRIGHT", -1, 1); c.botBand:SetHeight(30)
  c.botBand:SetColorTexture(0, 0, 0, 0.55)
  c.hl = Tex(c, "HIGHLIGHT", T.hoverFill); c.hl:SetAllPoints()
  c.press = Tex(c, "OVERLAY", T.pressFill); c.press:SetAllPoints(); c.press:Hide()
  c.selEdge = ns.Outline(c, T.accent, 0, "OVERLAY")
  -- text drawn over a picture keeps a shadow
  c.wlWorld = true
  -- the overview button at the card's top-right corner; the check of a finished dungeon left of it
  c.ov = S.IconButton(c, "info", 24, function() return { L.OV_T, L.OV_CLICK } end,
    function() if ns.ShowOverview then ns.ShowOverview(c.dkey) end end)
  c.ov:SetPoint("TOPRIGHT", -6, -6)
  c.ov:SetFrameLevel((c:GetFrameLevel() or 1) + 3)
  c.doneMark = ns.Icon(c, "check", 14, "OVERLAY", T.ok); c.doneMark:SetPoint("RIGHT", c.ov, "LEFT", -2, 0)
  c.name = Text(c, ns.F.heading, T.fg, false, "SHADOW"); c.name:SetPoint("TOPLEFT", 12, -10)
  c.name:SetJustifyH("LEFT")
  c.cicon = c:CreateTexture(nil, "OVERLAY"); c.cicon:SetSize(20, 20); c.cicon:SetPoint("TOPLEFT", 12, -42)
  -- bottom band: the level line (bottom left), the "Picked" pill (bottom right), the quests above them
  c.picked = S.Pill(c); c.picked:SetPoint("BOTTOMRIGHT", -8, 6)
  c.lvl = Text(c, ns.F.meta, T.text, false, "SHADOW"); c.lvl:SetPoint("BOTTOMLEFT", 12, 10); c.lvl:SetJustifyH("LEFT")
  c.info = Text(c, ns.F.label, T.fg, false, "SHADOW"); c.info:SetPoint("BOTTOMLEFT", c.lvl, "TOPLEFT", 0, 3); c.info:SetJustifyH("LEFT")
  c.bar = Tex(c, "OVERLAY", T.ok); c.bar:SetPoint("BOTTOMLEFT", 1, 1); c.bar:SetHeight(2)
  c.bigIcon = c:CreateTexture(nil, "ARTWORK", nil, 1); c.bigIcon:SetSize(40, 40); c.bigIcon:SetPoint("CENTER", 0, -2); c.bigIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92); c.bigIcon:Hide()
  c.dicon = c:CreateTexture(nil, "OVERLAY"); c.dicon:Hide()
  c:SetScript("OnClick", function(self, btn)
    if btn == "RightButton" then
      if ns.ShowOverview then ns.ShowOverview(self.dkey) else ns.OpenQuests(self.dkey) end
      return
    end
    Selected()[self.dkey] = not Selected()[self.dkey] or nil
    PlaySound(SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or 856)
    Render()
  end)
  -- double-click: this dungeon alone, through its summary (the route's first screen)
  c:SetScript("OnDoubleClick", function(self)
    wipe(Selected()); Selected()[self.dkey] = true
    if ns.ShowSummary then
      Render()
      local left, top = p:GetLeft(), p:GetTop()
      local sum = ns.ShowSummary({ self.dkey })
      if sum then
        p:Hide()
        if left and top and sum.ClearAllPoints then sum:ClearAllPoints(); sum:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top) end
      end
    else ns.StartGuide() end
  end)
  c:SetScript("OnMouseDown", function(self) self.press:Show() end)
  c:SetScript("OnMouseUp", function(self) self.press:Hide() end)
  c:SetScript("OnEnter", function(self)
    local d = ns.D[self.dkey]
    local n, done = Counts(self.dkey)
    local lines = { ns.DName(self.dkey), (GetLocale and GetLocale() == "frFR" and d.locf) or ns.T(d.loc) or "",
      ns.Plural(n, "PICK_QUESTS1", "PICK_QUESTS", n) .. "  ·  " .. ns.Plural(done, "PICK_DONE1", "PICK_DONE", done) }
    if d.cq and d.home then table.insert(lines, L.CQ_IN:format(ns.DName(d.home))) end
    if d.ed then table.insert(lines, ns.T(d.ed)) end
    for _, k in ipairs(ns.KeyLines and ns.KeyLines(self.dkey) or {}) do table.insert(lines, k[1]) end
    table.insert(lines, L.PICK_CLICK)
    table.insert(lines, ns.ShowOverview and L.OV_RCLICK or L.PICK_RCLICK)
    table.insert(lines, L.PICK_DCLICK)
    ns.ShowTip(self, lines)
  end)
  c:SetScript("OnLeave", ns.HideTip)
  return c
end

-- An empty tab: icon, the fact, why (no button: the filter above is the action).
local function MakeEmpty(parent)
  local e = CreateFrame("Frame", nil, parent)
  e:SetWidth(320)
  e.icon = ns.Icon(e, "portal", 32, "ARTWORK", T.muted); e.icon:SetPoint("TOP", 0, 0)
  e.title = Text(e, ns.F.heading, T.fg); e.title:SetJustifyH("CENTER"); e.title:SetPoint("TOP", 0, -40)
  e.text = Text(e, ns.F.label, T.muted); e.text:SetJustifyH("CENTER")
  function e:Set(t, s)
    self.title:SetText(t); self.text:SetText(s or "")
    local y = 40 + ns.FitText(self.title, 2, 320, self)
    self.text:ClearAllPoints(); self.text:SetPoint("TOP", 0, -(y + 4))
    y = y + 4 + ns.FitText(self.text, 0, 320, self)
    self:SetHeight(y)
    return y
  end
  return e
end

local function Build()
  local S = SW()
  p = CreateFrame("Frame", "WLDTPicker", UIParent)
  p.wlOwned = true
  p:SetSize(PW, 400); p:SetPoint("CENTER"); p:SetFrameStrata("HIGH")
  p:SetMovable(true); p:EnableMouse(true); p:SetClampedToScreen(true); p:SetToplevel(true)
  ns.Flat(p, T.bg, T.cardEdge)
  p:SetScript("OnMouseDown", function(self) self:Raise() end)
  local h = CreateFrame("Frame", nil, p)
  h:SetPoint("TOPLEFT", 0, 0); h:SetPoint("TOPRIGHT", 0, 0); h:SetHeight(HEADER)
  h:EnableMouse(true); h:RegisterForDrag("LeftButton")
  h:SetScript("OnMouseDown", function() p:Raise() end)
  h:SetScript("OnDragStart", function() p:StartMoving() end)
  h:SetScript("OnDragStop", function() p:StopMovingOrSizing() end)
  h.rule = ns.Rule(p, T.line); h.rule:SetPoint("TOPLEFT", 0, -HEADER); h.rule:SetPoint("TOPRIGHT", 0, -HEADER)
  local function GoHome()
    p:Hide()
    local WP = ns.Writs and ns.Writs.WP
    if WP and WP.OpenHome then WP.OpenHome() end
  end
  -- back chevron only (the logo stays on the home page)
  p.back = (S.BackButton or S.HomeButton)(h, GoHome); p.back:SetPoint("TOPLEFT", 6, -8)
  h.title = Text(h, ns.F.title, T.fg); h.title:SetPoint("LEFT", h, "LEFT", 40, 0); h.title:SetPoint("RIGHT", h, "RIGHT", -48, 0)
  h.title:SetJustifyV("MIDDLE"); h.title:SetText(L.PICK_T)
  ns.ClampLabel(h.title, nil, h)
  local close = S.CloseButton(h, 28, function() p:Hide() end)
  close:SetPoint("TOPRIGHT", -8, -8)

  -- tabs (dungeons, raids, class quests) with the level filter at the right of the same bar
  p.tabBar = S.Tabs(p, { { "dg", L.TAB_DG }, { "raid", L.TAB_RAID }, { "cls", L.TAB_CLS } },
    function() return CurTab() end,
    function(k) WLDTDB.tab = k; if p.sa then p.sa:ScrollTo(0, true) end; Render() end)
  p.tabBar:SetPoint("TOPLEFT", 0, -(HEADER + 1)); p.tabBar:SetPoint("TOPRIGHT", 0, -(HEADER + 1))
  p.tabs = p.tabBar.tabs
  p.filter = S.Segmented(p.tabBar, { { false, L.PICK_MINE }, { true, L.PICK_ALL } },
    function() return WLDTDB.pickAll and true or false end,
    function(v) WLDTDB.pickAll = v and true or false; Render() end, 24)
  p.filter:SetPoint("RIGHT", -PAD, 0)
  p.hint = Text(p, ns.F.label, T.muted)
  p.hint:SetPoint("TOPLEFT", PAD, -(HEADER + 1 + 32 + 12))

  p.sa = S.ScrollArea(p)
  p.grid = p.sa.child
  p.sf = p.sa   -- older name
  p.cards = {}
  p.empty = MakeEmpty(p.grid); p.empty:SetPoint("TOP", p.grid, "TOP", 0, -24); p.empty:Hide()

  -- footer: what is picked, then clear and the one main action
  p.foot = CreateFrame("Frame", nil, p); p.foot:SetHeight(32)
  -- the main action opens the route's summary first: tick the quests seeing XP, rewards and
  -- chains, then start the route from there
  p.go = S.Button(p.foot, L.PICK_GO, 0, 32, "primary", function()
    -- the picker gives way to the summary, opened at the same place on the screen
    local left, top = p:GetLeft(), p:GetTop()
    local sum = ns.ShowSummary and ns.ShowSummary()
    if sum then
      p:Hide()
      if left and top and sum.ClearAllPoints then
        sum:ClearAllPoints(); sum:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
      end
      return
    end
    ns.StartGuide()
  end, function() return { p.go:GetText(), L.SUM_PICK_GO_TT } end)
  p.go:SetPoint("RIGHT", 0, 0)
  p.go:SetDisabledReason(L.PICK_GO_WHY)
  p.none = S.Button(p.foot, L.PICK_NONE, 0, 28, "secondary", function() wipe(Selected()); Render() end)
  p.none:SetPoint("RIGHT", p.go, "LEFT", -8, 0)
  p.selText = Text(p.foot, ns.F.body, T.text); p.selText:SetPoint("LEFT", 0, 0); p.selText:SetPoint("RIGHT", p.none, "LEFT", -12, 0)
  p.selText:SetJustifyV("MIDDLE")
  ns.ClampLabel(p.selText, nil, p.foot)
  tinsert(UISpecialFrames, "WLDTPicker")
  if ns.RegisterWindow then ns.RegisterWindow(p) end
  p:Hide()
end

Render = function()
  if not p then return end
  ns.EnsureClassCards()
  local S = SW()
  -- Sections, in this order: to do at your level, later (too high), below, done, coming soon,
  -- then (All) no quest. "My level" shows the first, done and coming soon; "All" every section.
  local tab = CurTab()
  local secs = { todo = {}, later = {}, below = {}, done = {}, noq = {}, upcoming = {} }
  local list = {}
  local tooHigh = function(d) return d.lvl and d.lvl[1] and UnitLevel("player") < d.lvl[1] - 4 end
  for _, k in ipairs(ns.ORDER) do
    local d = ns.D[k]
    if TabOf(d) == tab and (tab ~= "cls" or ClassMatch(d)) then
      local n, done = Counts(k)
      local sec
      if n == 0 then sec = (d.up and time() < d.up) and "upcoming" or (tab == "raid" and "todo" or "noq")
      elseif done >= n then sec = "done"
      elseif tooHigh(d) then sec = "later"
      elseif not LevelOK(d) then sec = "below"
      else sec = "todo" end
      local show = WLDTDB.pickAll or sec == "todo" or sec == "done" or sec == "upcoming"
      if show then table.insert(secs[sec], k); table.insert(list, k) end
    end
  end
  p.tabBar:Update()
  p.filter:Update()
  local contentW = PW - 2 * PAD
  p.hint:SetText(tab == "cls" and L.PICK_HINT_CLS or tab == "raid" and L.PICK_HINT_RAID or L.PICK_HINT)
  local hintH = ns.FitText(p.hint, 0, contentW, p)
  local top = HEADER + 1 + 32 + 12 + hintH + 12
  local function byLevel(a, b)
    local la, lb = ns.D[a].lvl and ns.D[a].lvl[1] or 0, ns.D[b].lvl and ns.D[b].lvl[1] or 0
    if la ~= lb then return la < lb end
    return a < b
  end
  p.heads = p.heads or {}
  for _, hd in ipairs(p.heads) do hd:Hide() end
  local i, y, hi = 0, 0, 0
  for _, s in ipairs({ { "todo", L.SEC_TODO }, { "later", L.SEC_LATER }, { "below", L.SEC_BELOW }, { "done", L.SEC_DONE }, { "upcoming", L.SEC_UP }, { "noq", L.SEC_NOQ } }) do
    local keys = secs[s[1]]
    if #keys > 0 then
      table.sort(keys, byLevel)
      hi = hi + 1
      local hd = p.heads[hi] or S.SectionHeader(p.grid, s[2], #keys); p.heads[hi] = hd
      hd:Set(s[2], #keys)
      -- 16 above a section header (8 left by the cards above + 8), 0 above the first one
      if hi > 1 then y = y + 8 end
      hd:ClearAllPoints(); hd:SetPoint("TOPLEFT", p.grid, "TOPLEFT", 0, -y); hd:SetWidth(contentW); hd:Show()
      y = y + 32 + 8
      for j, k in ipairs(keys) do
        i = i + 1
        local c = p.cards[i] or MakeCard(p.grid); p.cards[i] = c
        local col, row = (j - 1) % COLS, math.floor((j - 1) / COLS)
        c:ClearAllPoints(); c:SetPoint("TOPLEFT", p.grid, "TOPLEFT", col * (CW + GAP), -(y + row * (CH + GAP)))
        c.section = s[1]
        local d = ns.D[k]
        c.dkey = k
        Art(c.art, d, c)
        c.dicon:Hide()
        if d.cq then SetClassIcon(c.cicon, (d.cq:match("^[^,]+"))) else c.cicon:Hide() end
        c.name:SetText(ns.DName(k))
        local soon = d.up and time() < d.up
        local n, done = Counts(k)
        local finished = n > 0 and done >= n
        -- the name wraps to 2 lines over the whole width (less the check); the band follows it
        local nameH = ns.FitText(c.name, 2, CW - 12 - 36 - (finished and 16 or 0), c)
        if nameH < 14 then nameH = 17 end
        local topH = 10 + nameH + 8
        c.topBand:SetHeight(topH)
        c.cicon:ClearAllPoints(); c.cicon:SetPoint("TOPLEFT", 12, -(topH + 6))
        -- a coming raid without quests shows its opening date on the quests line, so the level line stays short
        local dateTop = soon and n == 0
        local parts = {}
        if d.raid then table.insert(parts, L.RAID .. (d.size and (" · " .. L.PICK_SIZE:format(d.size)) or "")) end
        if d.lvl and d.lvl[1] then
          local lo, hi2 = d.lvl[1], d.lvl[2] or d.lvl[1]
          table.insert(parts, lo == hi2 and L.PICK_LV1:format(lo) or L.PICK_LV:format(lo, hi2))
        end
        if soon and not dateTop then table.insert(parts, L.PICK_OPENS:format(date(L.PICK_DATE, d.up))) end
        c.lvl:SetText(table.concat(parts, "  ·  "))
        local qline = n > 0 and ns.Plural(n, "PICK_QN1", "PICK_QN", done, n)
        -- how many of the quests left need earlier quests ("5 quests · 2 with prerequisites")
        local npre = (n > done) and PreCount(k) or 0
        if qline and npre > 0 then qline = qline .. " · " .. ns.Plural(npre, "OV_CARD_PRE1", "OV_CARD_PRE", npre) end
        c.info:SetText(qline or (dateTop and (L.PICK_SOON .. " · " .. date(L.PICK_DATE, d.up))) or L.PICK_NOQ)
        c.bar:SetWidth(math.max(1, (CW - 2) * (n > 0 and done / n or 0)))
        c.bar:SetShown(n > 0 and done > 0)
        c.doneMark:SetShown(finished)
        local lc = (c.section == "later" or c.section == "below") and T.muted or T.text
        c.lvl:SetTextColor(lc[1], lc[2], lc[3])
        local sel = Selected()[k] and true or false
        if sel then c.picked:Set(L.PICK_PICKED, T.accentSoft, "check"); c.picked:Show() else c.picked:Hide() end
        -- the level line leaves room for the pill only while it shows; it wraps to 2 lines
        local pillW = sel and ((num(c.picked:GetWidth()) or 80) + 8) or 0
        local lvlH = ns.FitText(c.lvl, 2, CW - 24 - pillW, c)
        if lvlH < 11 then lvlH = 13 end
        local infoH = ns.FitText(c.info, 1, CW - 24, c)
        if infoH < 12 then infoH = 15 end
        c.botBand:SetHeight(math.max(30, 10 + lvlH + 3 + infoH + 6))
        c.selEdge(T.accent, sel and 1 or 0)
        -- later, below, no quest, coming soon: greyed; to do and done: the picture as it is
        c.art:SetDesaturated(c.section == "later" or c.section == "below" or c.section == "noq" or c.section == "upcoming")
        c.shade:SetColorTexture(0, 0, 0, (c.section == "todo" or c.section == "done" or sel) and 0.12 or 0.45)
        c:Show()
      end
      y = y + math.ceil(#keys / COLS) * (CH + GAP) - GAP + 8
    end
  end
  for j = i + 1, #p.cards do p.cards[j]:Hide() end
  if #list == 0 then
    local eh = (tab == "cls") and p.empty:Set(L.PICK_EMPTY_CLS_T, L.PICK_EMPTY_CLS) or p.empty:Set(L.PICK_EMPTY_T, L.PICK_EMPTY)
    p.empty:Show()
    y = 24 + eh + 24
  else p.empty:Hide() end
  local gridH = math.max(10, y)
  -- the window fits the cards, up to 80 % of the screen; the grid scrolls past that
  local footH = 12 + 32 + PAD
  local cap = math.max(160, ScreenCap() - top - footH)
  local viewH = math.min(gridH, cap)
  p.sa:ClearAllPoints()
  p.sa:SetPoint("TOPLEFT", PAD, -top); p.sa:SetPoint("TOPRIGHT", -PAD, -top); p.sa:SetHeight(viewH)
  p.grid:SetWidth(contentW)
  p.sa:SetContentHeight(gridH)
  p.foot:ClearAllPoints()
  p.foot:SetPoint("TOPLEFT", p.sa, "BOTTOMLEFT", 0, -12); p.foot:SetPoint("TOPRIGHT", p.sa, "BOTTOMRIGHT", 0, -12)
  -- keep the top edge where it is: the window grows downward
  local l, t = num(p:GetLeft()), num(p:GetTop())
  if l and t and p:GetPoint() ~= "TOPLEFT" then p:ClearAllPoints(); p:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", l, t) end
  p:SetHeight(top + viewH + footH)

  local nSel = SelCount()
  p.selText:SetText(nSel == 0 and L.PICK_SEL0 or ns.Plural(nSel, "PICK_SEL1", "PICK_SEL", nSel))
  p.go:SetText(nSel == 0 and L.PICK_GO or ns.Plural(nSel, "PICK_GO1", "PICK_GON", nSel))
  if p.go.SetIcon then p.go:SetIcon("pin") end
  p.go:SetEnabled(nSel > 0)
  p.none:SetEnabled(nSel > 0)
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
--  Choix des quêtes d'un donjon : une liste à cocher (cases dessinées, coche HD)
-- =====================================================================
local QROWS, QH, QW = 22, 28, 420
local QSTATUS = 130                       -- the status column ("Prerequisites done" at 11 px fits)
local QTXT_W = (QW - 16) - 60 - 8 - QSTATUS - 8   -- the quest name: from x 60 to the status column
local function BuildQuests()
  local S = SW()
  qp = CreateFrame("Frame", "WLDTQuestPicker", UIParent)
  qp.wlOwned = true
  qp:SetSize(QW, 200); qp:SetFrameStrata("DIALOG"); qp:SetPoint("CENTER", 120, 0)
  qp:SetMovable(true); qp:EnableMouse(true); qp:SetClampedToScreen(true); qp:SetToplevel(true)
  ns.Flat(qp, T.bg, T.cardEdge)
  local h = CreateFrame("Frame", nil, qp)
  h:SetPoint("TOPLEFT", 0, 0); h:SetPoint("TOPRIGHT", 0, 0); h:SetHeight(HEADER)
  h:EnableMouse(true); h:RegisterForDrag("LeftButton")
  h:SetScript("OnDragStart", function() qp:StartMoving() end); h:SetScript("OnDragStop", function() qp:StopMovingOrSizing() end)
  h.rule = ns.Rule(qp, T.line); h.rule:SetPoint("TOPLEFT", 0, -HEADER); h.rule:SetPoint("TOPRIGHT", 0, -HEADER)
  qp.title = Text(h, ns.F.title, T.fg); qp.title:SetPoint("LEFT", PAD, 0); qp.title:SetPoint("RIGHT", -48, 0); qp.title:SetJustifyV("MIDDLE")
  ns.ClampLabel(qp.title, nil, h)
  local close = S.CloseButton(h, 28, function() qp:Hide() end); close:SetPoint("TOPRIGHT", -8, -8)
  qp.hint = Text(qp, ns.F.label, T.muted); qp.hint:SetPoint("TOPLEFT", PAD, -(HEADER + 1 + 12))
  qp.hint:SetJustifyH("LEFT"); qp.hint:SetText(L.PICK_CUSTOM_H)
  qp.rows = {}
  for r = 1, QROWS do
    local row = CreateFrame("Button", nil, qp)
    row:SetHeight(QH)
    row.hl = Tex(row, "HIGHLIGHT", T.hoverFill); row.hl:SetAllPoints()
    row.press = Tex(row, "ARTWORK", T.pressFill); row.press:SetAllPoints(); row.press:Hide()
    -- a drawn check box: panel fill, 1 px edge (accent when ticked), the HD check inside
    row.boxF = CreateFrame("Frame", nil, row); row.boxF:SetSize(16, 16); row.boxF:SetPoint("LEFT", 8, 0)
    row.box = Tex(row.boxF, "BACKGROUND", T.panel); row.box:SetAllPoints()
    row.boxEdge = ns.Outline(row.boxF, T.btnEdge)
    row.tick = ns.Icon(row.boxF, "check", 12, "ARTWORK", T.fg); row.tick:SetPoint("CENTER")
    row.lvl = Text(row, ns.F.meta, T.muted); row.lvl:SetPoint("LEFT", 32, 0); row.lvl:SetWidth(24); row.lvl:SetJustifyV("MIDDLE")
    -- the prerequisite status, right-aligned in a fixed column: none, N, done, level needed
    row.status = Text(row, ns.F.meta, T.muted); row.status:SetPoint("RIGHT", -8, 0); row.status:SetWidth(QSTATUS)
    row.status:SetJustifyH("RIGHT"); row.status:SetJustifyV("MIDDLE")
    ns.ClampLabel(row.status, nil, row)
    -- the name wraps to 2 lines; the row grows with it
    row.txt = Text(row, ns.F.label, T.fg); row.txt:SetPoint("LEFT", 60, 0); row.txt:SetWidth(QTXT_W); row.txt:SetJustifyV("MIDDLE")
    row:SetScript("OnClick", function(self)
      -- ticked by hand: the summary's level default no longer applies to it (OffPick first: it
      -- keeps the older unticks as hand-made before this one is added)
      local pick = ns.OffPick and ns.OffPick() or WLDTDB.offPick or {}
      WLDTDB.offPick = pick
      WLDTDB.off = WLDTDB.off or {}
      WLDTDB.off[self.qid] = not WLDTDB.off[self.qid] or nil
      pick[self.qid] = true
      ns.OpenQuests(qp.dkey, true)
      if ns.RenderOverview then ns.RenderOverview() end
    end)
    row:SetScript("OnMouseDown", function(self) self.press:Show() end)
    row:SetScript("OnMouseUp", function(self) self.press:Hide() end)
    row:SetScript("OnEnter", function(self)
      local q = ns.Q[self.qid]
      local lines = { ns.QName(self.qid) }
      local obj = (ns.lang == "fr" and q.of) or ns.T(q.oe)
      if obj then table.insert(lines, obj) end
      -- the chain in order, one line per quest: done (check), in the log (dot), to do (faint dot)
      local pre = ns.QuestPreInfo and ns.QuestPreInfo(self.qid)
      if pre and pre.total > 0 then
        local S = SW()
        table.insert(lines, { L.OV_CHAIN_TT, T.fg[1], T.fg[2], T.fg[3] })
        for i, pid in ipairs(pre.chain) do
          local s = pre.states[i]
          local mark = s == "done" and S.IconMarkup("check", 12, T.ok) or S.IconMarkup("dot", 12, s ~= "none" and T.info or T.faint)
          local pq = ns.Q[pid] or {}
          local txt = mark .. " " .. ns.QName(pid) .. (pq.l and (" · " .. L.PICK_LV1:format(pq.l)) or "")
          if i == 1 and pq.s and pq.s.m and C_Map and C_Map.GetMapInfo then
            local ok, mi = pcall(C_Map.GetMapInfo, pq.s.m)
            if ok and type(mi) == "table" and mi.name then txt = txt .. " · " .. mi.name end
          end
          local c = s == "done" and T.muted or T.text
          table.insert(lines, { txt, c[1], c[2], c[3] })
        end
      elseif q.p and #q.p > 0 then table.insert(lines, L.PRE .. L.COLON .. #q.p) end
      if q.ne then table.insert(lines, ns.T(q.ne)) end
      if WLDTDB.off[self.qid] then table.insert(lines, L.PICK_QOFF) end
      table.insert(lines, L.PICK_QCLICK)
      ns.ShowTip(self, lines)
    end)
    row:SetScript("OnLeave", ns.HideTip)
    qp.rows[r] = row
  end
  tinsert(UISpecialFrames, "WLDTQuestPicker")
  if ns.RegisterWindow then ns.RegisterWindow(qp) end
  qp:Hide()
end

function ns.OpenQuests(dkey, keep)
  if not qp then BuildQuests() end
  local _, cls = UnitClass("player")
  qp.dkey = dkey
  qp.title:SetText(L.PICK_CUSTOM_T:format(ns.DName(dkey))); qp.hint:SetText(L.PICK_CUSTOM_H)
  local hintH = ns.FitText(qp.hint, 0, QW - 2 * PAD, qp)
  local top = HEADER + 1 + 12 + hintH + 8
  local qs = ns.DungeonQuests(dkey, cls)
  local log = ns.LogEntries()
  local shown, y = 0, 0
  for r, row in ipairs(qp.rows) do
    local qid = qs[r]
    if qid then
      local q = ns.Q[qid]
      row.qid = qid
      row.lvl:SetText(q.l or "")
      local tag = ""
      if q.c then local cn, cc = ns.ClassInfo(q.c:match("^[^,]+")); tag = "  " .. Hex(cc) .. cn .. "|r" end
      if ns.IsDone(qid) then tag = tag .. "  " .. Hex(T.ok) .. L.S_DONE .. "|r" end
      row.txt:SetText(ns.QName(qid) .. tag)
      -- status cell: level needed (warn), no prerequisite, prerequisites done (ok), N prerequisites
      local stx, scol = "", T.muted
      local pre = ns.QuestPreInfo and ns.QuestPreInfo(qid, log, cls)
      local need = q.r
      if pre and pre.nextPid and ns.Q[pre.nextPid] then need = ns.Q[pre.nextPid].r end
      if not ns.IsDone(qid) and need and UnitLevel("player") < need then stx, scol = L.ST_LOW:format(need), T.warn
      elseif pre and pre.total == 0 then stx = L.CH_NONE
      elseif pre and pre.done >= pre.total then stx, scol = L.CH_ALLDONE, T.ok
      elseif pre then stx = ns.Plural(pre.total, "CH_COUNT1", "CH_COUNT", pre.total) end
      row.status:SetText(stx); row.status.wlFull = stx
      row.status:SetTextColor(scol[1], scol[2], scol[3])
      local on = not WLDTDB.off[qid]
      row.tick:SetShown(on)
      row.boxEdge(on and T.accent or T.btnEdge)
      local tc = on and T.fg or T.muted
      row.txt:SetTextColor(tc[1], tc[2], tc[3])
      local th = ns.FitText(row.txt, 2, QTXT_W, row)
      local rh = math.max(QH, math.ceil(th) + 12)
      row:SetHeight(rh)
      row:ClearAllPoints()
      row:SetPoint("TOPLEFT", 8, -(top + y)); row:SetPoint("TOPRIGHT", -8, -(top + y))
      row:Show()
      shown = shown + 1
      y = y + rh
    else row:Hide() end
  end
  qp:SetHeight(top + math.max(QH, y) + 12)
  qp:Show(); qp:Raise()
end
