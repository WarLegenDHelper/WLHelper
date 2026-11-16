-- Suivi du guide : un petit cadre toujours à l'écran (déplaçable, repliable) qui suit la route action
-- par action. En haut le chapitre (avant / dans / après le donjon, avec l'avancée), puis l'action en
-- cours avec son icône, les barres de ses objectifs, et les deux actions suivantes en grisé.
-- Clic : ouvre le guide sur l'étape. Maj-clic : marque l'étape comme faite.
-- Public: WLHelperTracker.Refresh(), .Toggle(), .SetShown(on), .IsOn(), .Collapse(on), .Model().
local ADDON, ns = ...
local L, T, F = ns.L, ns.Tok, ns.F

-- 300: a compact overlay, the one width outside the window set (docs/DESIGN.md 3.1)
local W, PAD, ICON, GAP = 300, 12, 16, 8        -- width, inner pad, action icon, icon-to-text
local NEXT_H, NEXT_ICON, BAR_H = 20, 12, 4      -- next-action line, its icon, objective bar
local HEAD_H, MAX_BARS, MAX_NEXT = 28, 3, 2
local TEXT_W = W - PAD * 2 - ICON - GAP

local TR = {}
WLHelperTracker = TR
ns.Tracker = TR

local function secret(v) return issecretvalue ~= nil and issecretvalue(v) end
local function Hex(c) return ns.Hex and ns.Hex(c) or "|cffffffff" end

-- =====================================================================
--  Actions: one line per thing to do (take, turn in, kill, loot, use, talk, go, enter...)
-- =====================================================================
-- take and turn in use the game's own quest marks (SetActIcon); "have" ("keep this quest in your
-- log") gets no icon: the bag already means loot, and one icon keeps one meaning (icon audit G1).
-- No letter for a quest to take, no link icon for a trip, no flag for a quest you keep.
-- "go" (reach a place) is the flag, as in the guide: the pin means "GPS to this point" only, and a
-- click on a tracker line opens the guide, it does not start the GPS.
local AICON = { turn = "check", kill = "sword", loot = "bag", use = "hammer", talk = "user", go = "flag",
  enter = "portal", boss = "skull", item = "bag", ["do"] = "sword" }
-- the game's quest marks, used when the guide's icon helper is not there
local QUEST_MARK = { take = "Interface\\GossipFrame\\AvailableQuestIcon", turn = "Interface\\GossipFrame\\ActiveQuestIcon" }
local ACOL = { take = T.gold, turn = T.ok, enter = T.fg, boss = T.fg }
local OBJ_KIND = { kill = "kill", item = "loot", object = "use", talk = "talk", event = "go" }
local OBJ_TEXT = { kill = "TR_KILL", loot = "TR_LOOT", use = "TR_USE", talk = "TR_TALK", go = "TR_GO" }

local function Short(npc) return npc and (npc:gsub(" %(.*%)", ""):gsub(",.*$", "")) or nil end
local function ZoneName(m)
  local info = m and C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(m)
  return info and info.name or nil
end
-- "Tabetha, Dustwallow Marsh" / the dungeon's name for a node inside
local function Where(n)
  local who = Short(n.npc)
  local where = (n.ins and ns.DName(n.ins)) or (n.loc and ZoneName(n.loc.m))
  if who and where and who ~= where then return who .. ", " .. where end
  return who or where
end

-- log (optional): the quest log, so an objective has the card's name (the game's French words
-- when our data has no translation)
function TR.Action(n, st, log)
  local qn = n.q and ns.QName(n.q) or ""
  local a = { node = n, st = st }
  local o = n.oneObj or (n.kind == "o" and n.obj) or nil
  if n.kind == "a" then a.kind, a.text, a.sub = "take", L.TR_TAKE:format(qn), Where(n)
  elseif n.kind == "t" then a.kind, a.text, a.sub = "turn", L.TR_TURN:format(qn), Where(n)
  elseif n.kind == "h" then a.kind, a.text, a.sub = "have", L.TR_HAVE:format(qn), Where(n)
  elseif n.kind == "i" then
    local nm = n.label and (ns.T(n.label) or n.label) or qn
    a.kind, a.text, a.sub = "item", L.TR_ITEM:format(nm), Where(n)
  elseif o then
    a.obj = o
    a.kind = OBJ_KIND[o.k] or "go"
    local nm = o.n and (ns.T(o.n) or o.n) or nil
    if o.n and log and ns.ObjDisplayName then
      local ok, g = pcall(ns.ObjDisplayName, n, o, log)
      if ok and type(g) == "string" and g ~= "" then nm = g end
    end
    if nm then a.text = L[OBJ_TEXT[a.kind]]:format(nm)
    else a.text = L.TR_DO:format(qn) end
    a.sub = qn
  elseif n.kind == "c" then
    a.kind, a.text = "do", L.TR_DO:format(qn)
    a.sub = n.ins and ns.DName(n.ins) or nil
    local q = ns.Q[n.q]
    a.objs = {}
    for _, x in ipairs(q and q.o or {}) do
      if not (x.w and not x.ins and not x.outer) then a.objs[#a.objs + 1] = x end
    end
  else
    a.kind, a.text = "go", qn ~= "" and qn or "?"
  end
  if st and st.bossStep then a.sub = L.TR_BOSS:format(ns.BossStepName(st))
  elseif st and st.split and st.bossName then a.sub = L.TR_BOSS:format(st.bossName) end
  return a
end

-- The actions of step i, each with done = true/false. Inside a dungeon, one line per objective.
function TR.StepActions(i, st, log)
  local out = {}
  if not st then return out end
  if st.gate then
    local miss = 0
    for _, n in ipairs(st.acts or {}) do if not ns.NodeOK(log, n) then miss = miss + 1 end end
    out[1] = { kind = "enter", text = L.TR_ENTER:format(ns.DName(st.gate)), st = st, i = i, done = false,
      sub = miss > 0 and ns.Plural(miss, "TR_MISSING1", "TR_MISSING", miss) or nil }
    return out
  end
  local acts = st.acts or {}
  if st.bossStep then
    -- the boss itself first: "Kill: Gahz'rilla", Boss 4 of 8
    local killed = ns.BossStepKilled and ns.BossStepKilled(st) or false
    out[#out + 1] = { kind = "boss", text = L.TR_KILL:format(ns.BossStepName(st)), st = st, i = i, done = killed and true or false,
      sub = L.TR_BOSS_N:format(st.bossIdx, st.bossN or st.bossIdx) }
  end
  if st.ins and not st.split and ns.StepView then
    local ok, v = pcall(ns.StepView, st, log)
    if ok and type(v) == "table" then acts = v end
  end
  for _, n in ipairs(acts) do
    if n.kind ~= "b" then
      local a = TR.Action(n, st, log)
      a.i = i
      if n.vok ~= nil then a.done = n.vok and true or false else a.done = ns.NodeOK(log, n) and true or false end
      out[#out + 1] = a
    end
  end
  return out
end

-- Live count of an objective: have, need, finished (nil when the game does not show one).
local function Count(log, qid, o)
  if not (ns.ObjCount and qid and o) then return nil end
  local ok, a, b, fin = pcall(ns.ObjCount, log, qid, o)
  if not ok then return nil end
  return a, b, fin
end

-- Everything the tracker shows, without drawing: { title, cur = action, bars = {...}, nexts = {...} }
-- (nil when there is no route or the route is done).
function TR.Model()
  local steps = ns.route and ns.route.steps
  if not (steps and #steps > 0 and ns.CurrentStepIndex) then return nil end
  local log = ns.LogEntries()
  local idx, st = ns.CurrentStepIndex(log)
  if not (idx and st) then return nil end
  local m = { idx = idx, st = st }
  -- chapter: phase, dungeon, steps done in that phase
  local ph = ns.StepPhase and ns.StepPhase(st) or "before"
  local dk = ns.StepDungeon and ns.StepDungeon(st)
  local key = "PH_" .. ph:upper()
  if dk and ns.D[dk] and ns.PhaseProgress then
    local p = ns.PhaseProgress(dk)[ph] or { done = 0, total = 0 }
    m.title = L[key]:format(ns.DName(dk), p.done, p.total)
  else
    m.title = L[key .. "_S"]
  end
  m.phase, m.dk = ph, dk
  -- the current action: the first one not done in the step (the gate: entering)
  local acts = TR.StepActions(idx, st, log)
  local cur, curPos
  for k, a in ipairs(acts) do if not a.done then cur, curPos = a, k break end end
  local ahead
  if not cur and #acts > 0 then
    -- every line of the step is done (it waits on something else): never a done line as the
    -- current action, but the first thing still to do after it
    curPos = #acts
    local j = idx + 1
    while not cur and j <= #steps do
      if not ns.IsStepDone(log, j) then
        for _, a in ipairs(TR.StepActions(j, steps[j], log)) do if not a.done then cur = a; ahead = a.node break end end
      end
      j = j + 1
    end
    if not cur then cur = { kind = "turn", text = (ns.StepTitle and ns.StepTitle(st)) or "?", st = st, i = idx, done = true } end
  end
  if not cur then cur, curPos = { kind = "go", text = (ns.StepTitle and ns.StepTitle(st)) or "?", st = st, i = idx }, 0 end
  m.cur = cur
  -- objective bars: the current action's objective first, then the step's other objectives
  m.bars = {}
  local function addBar(qid, o)
    if #m.bars >= MAX_BARS or not o then return end
    for _, b in ipairs(m.bars) do if b.o == o then return end end
    local have, need, fin = Count(log, qid, o)
    if have and need then
      m.bars[#m.bars + 1] = { o = o, q = qid, have = have, need = need, fin = fin, label = ns.T(o.n) or o.n or ns.QName(qid) }
    end
  end
  if cur.obj then addBar(cur.node.q, cur.obj) end
  for _, o in ipairs(cur.objs or {}) do addBar(cur.node.q, o) end
  for _, a in ipairs(acts) do if a.obj and a.node then addBar(a.node.q, a.obj) end end
  -- "3/8" after a counted objective
  if cur.obj then
    local have, need = Count(log, cur.node.q, cur.obj)
    if have and need and need > 1 then cur.count = have .. "/" .. need end
  end
  -- travel hint (long trip, other continent) on the current step
  if st.travel == "TRAVEL_FAR" or st.travel == "TRAVEL_CONT" then m.travel = L[st.travel] end
  -- the next actions: the rest of this step, then the steps after it
  m.nexts = {}
  for k = curPos + 1, #acts do
    if #m.nexts >= MAX_NEXT then break end
    if not acts[k].done then m.nexts[#m.nexts + 1] = acts[k] end
  end
  local j = idx + 1
  while #m.nexts < MAX_NEXT and j <= #steps do
    if not ns.IsStepDone(log, j) then
      for _, a in ipairs(TR.StepActions(j, steps[j], log)) do
        if #m.nexts >= MAX_NEXT then break end
        if not a.done and not (ahead and a.node == ahead and a.text == cur.text) then m.nexts[#m.nexts + 1] = a end
      end
    end
    j = j + 1
  end
  return m
end

-- =====================================================================
--  Actions of the player on the tracker
-- =====================================================================
function TR.OpenGuide(i)
  if ns.ShowGuide then ns.ShowGuide() end
  if i and ns.GoTo and ns.frame and ns.frame:IsShown() then ns.GoTo(i) end
end

-- Shift-click: the step counts as done by hand (the guide's own manual mark).
function TR.MarkDone(i)
  local st = ns.route and ns.route.steps and ns.route.steps[i]
  if not st then return end
  if ns.SetStepManual then ns.SetStepManual(i, true)
  else
    WLDTDB.manual = WLDTDB.manual or {}
    WLDTDB.manual[st.key] = true
    if ns.frame and ns.frame:IsShown() and ns.Refresh then ns.Refresh() end
  end
  local title = (ns.StepTitle and ns.StepTitle(st)) or tostring(i)
  ns.Print(L.TR_MARKED:format(title))
  if ns.UpdateTargetButton then ns.UpdateTargetButton() end
  TR.Refresh()
end

-- =====================================================================
--  Frame
-- =====================================================================
local f

local function TextH(fs, size)
  local ok, h = pcall(fs.GetStringHeight, fs)
  if not ok or type(h) ~= "number" or secret(h) or h <= 0 then h = size + 2 end
  return math.ceil(h)
end

local function SavePos()
  local l, t = f:GetLeft(), f:GetTop()
  if type(l) == "number" and type(t) == "number" and not secret(l) and not secret(t) then
    WLDTDB.trackerPos = { math.floor(l + 0.5), math.floor(t + 0.5) }
    -- anchored by its top-left corner: a taller tracker grows downward
    f:ClearAllPoints(); f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", WLDTDB.trackerPos[1], WLDTDB.trackerPos[2])
  end
end

local function Place()
  f:ClearAllPoints()
  local p = WLDTDB and WLDTDB.trackerPos
  if type(p) == "table" and type(p[1]) == "number" and type(p[2]) == "number" then
    f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", p[1], p[2])
  else
    f:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -48, -260)
  end
end

-- hover (hoverFill) and press (pressFill, content 1 px down) on a row
local function Feedback(b, content)
  local hl = ns.Tex(b, "BACKGROUND", T.hoverFill); hl:SetAllPoints(); hl:Hide()
  local pr = ns.Tex(b, "BORDER", T.pressFill); pr:SetAllPoints(); pr:Hide()
  b.hl, b.pr = hl, pr
  b:SetScript("OnMouseDown", function()
    pr:Show()
    for _, r in ipairs(content) do r:SetPoint(r.p1, r.rel, r.p2, r.x, r.y - 1) end
  end)
  b:SetScript("OnMouseUp", function()
    pr:Hide()
    for _, r in ipairs(content) do r:SetPoint(r.p1, r.rel, r.p2, r.x, r.y) end
  end)
end
-- remembers a region's anchor so the press feedback can move it 1 px and back
local function Anchor(r, p1, rel, p2, x, y)
  r.p1, r.rel, r.p2, r.x, r.y = p1, rel, p2, x, y
  r:ClearAllPoints(); r:SetPoint(p1, rel, p2, x, y)
end

local function RowTip(self)
  local a = self.action
  if not a then return end
  local lines = { a.text }
  if a.sub then lines[#lines + 1] = a.sub end
  lines[#lines + 1] = L.TR_TIP_CLICK
  lines[#lines + 1] = L.TR_TIP_SHIFT
  ns.ShowTip(self, lines)
end

local function RowClick(self)
  local a = self.action
  if not (a and a.i) then return end
  if IsShiftKeyDown and IsShiftKeyDown() then TR.MarkDone(a.i) else TR.OpenGuide(a.i) end
end

local function SetActIcon(tex, kind, dim)
  -- an empty slot keeps the text aligned with the other rows
  if kind == "have" then tex:SetAlpha(0) return end
  if (kind == "take" or kind == "turn") and ns.GuideIcon then
    local ok = pcall(ns.GuideIcon, tex, kind)
    if ok then tex:SetAlpha(dim and 0.6 or 1) return end
  end
  if QUEST_MARK[kind] then
    tex:SetTexture(QUEST_MARK[kind]); tex:SetTexCoord(0, 1, 0, 1); tex:SetVertexColor(1, 1, 1)
    tex:SetAlpha(dim and 0.6 or 1)
    return
  end
  ns.SetHDIcon(tex, AICON[kind] or "dot", dim and T.muted or (ACOL[kind] or T.fg))
  tex:SetAlpha(1)
end

local function MakeRow(parent, iconSize, size, color)
  local b = CreateFrame("Button", nil, parent)
  b:SetWidth(W)
  b:RegisterForClicks("LeftButtonUp")
  b.icon = b:CreateTexture(nil, "ARTWORK"); b.icon:SetSize(iconSize, iconSize)
  b.text = ns.Text(b, size, color)
  b.text:SetWidth(W - PAD * 2 - iconSize - GAP)
  Anchor(b.icon, "TOPLEFT", b, "TOPLEFT", PAD, -4)
  Anchor(b.text, "TOPLEFT", b, "TOPLEFT", PAD + iconSize + GAP, -4)
  local content = { b.icon, b.text }
  b.content = content
  Feedback(b, content)
  b:SetScript("OnEnter", function(self) self.hl:Show(); RowTip(self) end)
  b:SetScript("OnLeave", function(self) self.hl:Hide(); self.pr:Hide(); if ns.HideTip then ns.HideTip() end end)
  b:SetScript("OnClick", RowClick)
  return b
end

local function Build()
  if f then return f end
  f = CreateFrame("Frame", "WLDTTracker", UIParent)
  f.wlOwned = true
  f:SetSize(W, HEAD_H)
  f:SetFrameStrata("MEDIUM")
  f:SetClampedToScreen(true)
  f:SetMovable(true)
  ns.Flat(f, T.bg, T.cardEdge)
  -- header: chapter title (drag to move, click to open the guide) and the collapse button
  local head = CreateFrame("Button", nil, f)
  head:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0); head:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
  head:SetHeight(HEAD_H)
  head:RegisterForDrag("LeftButton")
  head:RegisterForClicks("LeftButtonUp")
  head:SetScript("OnDragStart", function() f:StartMoving() end)
  head:SetScript("OnDragStop", function() f:StopMovingOrSizing(); SavePos() end)
  head.title = ns.Text(head, F.label, T.fg)
  head.title:SetWidth(W - PAD * 2 - 24 - GAP)
  Anchor(head.title, "TOPLEFT", head, "TOPLEFT", PAD, -8)
  Feedback(head, { head.title })
  head:SetScript("OnEnter", function(self)
    self.hl:Show()
    ns.ShowTip(self, { L.TR_WHAT or L.TR_TITLE, (f.model and f.model.title) or L.TR_TITLE, L.TR_TIP_CLICK, L.TR_TIP_DRAG,
      WLDTDB.trackerCollapsed and L.TR_EXPAND or L.TR_COLLAPSE })
  end)
  head:SetScript("OnLeave", function(self) self.hl:Hide(); if ns.HideTip then ns.HideTip() end end)
  head:SetScript("OnClick", function() TR.OpenGuide(f.model and f.model.idx) end)
  f.head = head
  -- the row-action size: 24 px hit area, 16 px icon; hover fill, press fill and a 1 px nudge
  local col = CreateFrame("Button", nil, f)
  col:SetSize(24, 24)
  col:SetPoint("TOPRIGHT", f, "TOPRIGHT", -PAD + 6, -2)
  col:SetFrameLevel(head:GetFrameLevel() + 2)
  col.icon = col:CreateTexture(nil, "ARTWORK"); col.icon:SetSize(16, 16); col.icon:SetPoint("CENTER")
  col.hl = ns.Tex(col, "BACKGROUND", T.hoverFill); col.hl:SetAllPoints(); col.hl:Hide()
  col.pr = ns.Tex(col, "BORDER", T.pressFill); col.pr:SetAllPoints(); col.pr:Hide()
  col:SetScript("OnMouseDown", function(self)
    self.pr:Show(); self.icon:ClearAllPoints(); self.icon:SetPoint("CENTER", 0, -1)
  end)
  col:SetScript("OnMouseUp", function(self)
    self.pr:Hide(); self.icon:ClearAllPoints(); self.icon:SetPoint("CENTER")
  end)
  col:SetScript("OnEnter", function(self)
    self.hl:Show(); ns.SetHDIcon(self.icon, self.icon.wlIcon or "chevron_up", T.fg)
    ns.ShowTip(self, { WLDTDB.trackerCollapsed and L.TR_EXPAND or L.TR_COLLAPSE })
  end)
  col:SetScript("OnLeave", function(self)
    self.hl:Hide(); self.pr:Hide(); self.icon:ClearAllPoints(); self.icon:SetPoint("CENTER"); ns.SetHDIcon(self.icon, self.icon.wlIcon or "chevron_up", T.muted)
    if ns.HideTip then ns.HideTip() end
  end)
  col:SetScript("OnClick", function() TR.Collapse(not WLDTDB.trackerCollapsed) end)
  f.col = col
  -- body
  f.cur = MakeRow(f, ICON, F.body, T.fg)
  f.cur.sub = ns.Text(f.cur, F.meta, T.muted)
  f.cur.sub:SetWidth(TEXT_W)
  table.insert(f.cur.content, f.cur.sub)
  f.travel = ns.Text(f, F.meta, T.muted)
  f.travel:SetWidth(TEXT_W)
  f.travelIcon = f:CreateTexture(nil, "ARTWORK"); f.travelIcon:SetSize(NEXT_ICON, NEXT_ICON)
  ns.SetHDIcon(f.travelIcon, ns.ARROW, T.muted)
  f.bars = {}
  for k = 1, MAX_BARS do
    local b = CreateFrame("Frame", nil, f)
    b:SetSize(TEXT_W, 18)
    b.label = ns.Text(b, F.meta, T.muted); b.label:SetWidth(TEXT_W - 56)
    b.label:SetPoint("TOPLEFT", b, "TOPLEFT", 0, 0)
    b.count = ns.Text(b, F.meta, T.fg); b.count:SetWidth(52); b.count:SetJustifyH("RIGHT"); b.count:SetWordWrap(false)
    b.count:SetPoint("TOPRIGHT", b, "TOPRIGHT", 0, 0)
    b.track = ns.Tex(b, "ARTWORK", T.divider); b.track:SetHeight(BAR_H)
    b.fill = ns.Tex(b, "OVERLAY", T.text); b.fill:SetHeight(BAR_H)
    f.bars[k] = b
  end
  f.nexts = {}
  for k = 1, MAX_NEXT do
    local r = MakeRow(f, NEXT_ICON, F.meta, T.muted)
    f.nexts[k] = r
  end
  Place()
  f:Hide()
  return f
end

local function Wanted()
  -- off unless asked for (/wlh suivi or Settings): the guide window and its "-" mini mode are the
  -- usual way; two small views of the same step confused players
  if not WLDTDB or WLDTDB.tracker ~= true then return false end
  if ns.GuideOn and not ns.GuideOn() then return false end
  -- one view at a time: the small tracker while you play, the big guide window when you open it
  if ns.frame and ns.frame:IsShown() then return false end
  return ns.route ~= nil and ns.route.steps ~= nil and #ns.route.steps > 0
end

-- Draws the model; the tracker's height follows its content.
local function Draw(m)
  local head = f.head
  local collapsed = WLDTDB.trackerCollapsed
  -- folded: the action to do now on the one line, so the folded tracker still says something
  -- useful ("Rendre « Powering the Pylons » · 1/9"); open: the chapter title
  local title = m.title or L.TR_TITLE
  if collapsed and m.cur and m.cur.text then
    local prog = (m.title or ""):match("(%d+/%d+)%s*$")
    title = m.cur.text .. (prog and ("  " .. Hex(T.muted) .. prog .. "|r") or "")
  end
  head.title:SetText(title)
  local headH = math.max(HEAD_H, TextH(head.title, F.label) + 16)
  head:SetHeight(headH)
  ns.SetHDIcon(f.col.icon, collapsed and "chevron_down" or "chevron_up", T.muted)
  local y = headH
  local function hideBody()
    f.cur:Hide(); f.travel:Hide(); f.travelIcon:Hide()
    for _, b in ipairs(f.bars) do b:Hide() end
    for _, r in ipairs(f.nexts) do r:Hide() end
  end
  if collapsed then hideBody(); f:SetHeight(y) return end
  -- current action
  local cur = f.cur
  cur.action = m.cur
  SetActIcon(cur.icon, m.cur.kind, false)
  local text = m.cur.text or ""
  if m.cur.count then text = text .. "  " .. Hex(T.muted) .. m.cur.count .. "|r" end
  cur.text:SetText(text)
  local h = 4 + TextH(cur.text, F.body)
  if m.cur.sub then
    cur.sub:SetText(m.cur.sub); cur.sub:Show()
    Anchor(cur.sub, "TOPLEFT", cur, "TOPLEFT", PAD + ICON + GAP, -(h + 3))
    h = h + 3 + TextH(cur.sub, F.meta)
  else cur.sub:Hide() end
  h = h + 6
  cur:ClearAllPoints(); cur:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -y); cur:SetHeight(h); cur:Show()
  y = y + h
  -- long trip hint
  if m.travel then
    f.travel:SetText(m.travel); f.travel:Show(); f.travelIcon:Show()
    f.travelIcon:ClearAllPoints(); f.travelIcon:SetPoint("TOPLEFT", f, "TOPLEFT", PAD + (ICON - NEXT_ICON) / 2, -(y + 1))
    f.travel:ClearAllPoints(); f.travel:SetPoint("TOPLEFT", f, "TOPLEFT", PAD + ICON + GAP, -y)
    y = y + TextH(f.travel, F.meta) + 4
  else f.travel:Hide(); f.travelIcon:Hide() end
  -- objective bars
  for k, b in ipairs(f.bars) do
    local d = m.bars[k]
    if d then
      b.label:SetText(d.label)
      b.count:SetText(d.have .. "/" .. d.need)
      local c = d.fin and T.ok or T.fg
      b.count:SetTextColor(c[1], c[2], c[3])
      local lh = math.max(TextH(b.label, F.meta), F.meta + 2)
      b.track:ClearAllPoints(); b.track:SetPoint("TOPLEFT", b, "TOPLEFT", 0, -(lh + 3)); b.track:SetWidth(TEXT_W)
      local frac = (d.need > 0) and math.min(1, math.max(0, d.have / d.need)) or 0
      b.fill:ClearAllPoints(); b.fill:SetPoint("TOPLEFT", b.track, "TOPLEFT", 0, 0)
      b.fill:SetWidth(math.max(1, TEXT_W * frac)); b.fill:SetShown(frac > 0)
      local fc = d.fin and T.ok or T.text
      b.fill:SetColorTexture(fc[1], fc[2], fc[3], 1)
      local bh = lh + 3 + BAR_H
      b:SetHeight(bh)
      b:ClearAllPoints(); b:SetPoint("TOPLEFT", f, "TOPLEFT", PAD + ICON + GAP, -y)
      b:Show()
      y = y + bh + 6
    else b:Hide() end
  end
  -- next actions, dimmed
  if #m.nexts > 0 then y = y + 2 end
  for k, r in ipairs(f.nexts) do
    local a = m.nexts[k]
    if a then
      r.action = a
      SetActIcon(r.icon, a.kind, true)
      r.text:SetText(a.text or "")
      local rh = math.max(NEXT_H, TextH(r.text, F.meta) + 8)
      r:SetHeight(rh)
      r:ClearAllPoints(); r:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -y)
      r:Show()
      y = y + rh
    else r:Hide(); r.action = nil end
  end
  f:SetHeight(y + 6)
end

function TR.Refresh()
  if not WLDTDB then return end
  if not Wanted() then if f then f:Hide() end return end
  local ok, m = pcall(TR.Model)
  if not ok then m = nil end
  if not m then if f then f:Hide() end return end
  Build()
  f.model = m
  Draw(m)
  f:Show()
end

function TR.IsOn() return WLDTDB ~= nil and WLDTDB.tracker == true end

function TR.SetShown(on)
  if not WLDTDB then return end
  WLDTDB.tracker = on and true or false
  TR.Refresh()
end

-- /wlh tracker
function TR.Toggle()
  if not WLDTDB then return end
  local on = not TR.IsOn()
  WLDTDB.tracker = on
  if on and ns.GuideOn and not ns.GuideOn() then ns.Print(L.TR_GUIDE_OFF)
  elseif on and not (ns.route and ns.route.steps and #ns.route.steps > 0) then ns.Print(L.TR_NOROUTE)
  else ns.Print(on and L.TR_ON or L.TR_OFF) end
  TR.Refresh()
end

function TR.Collapse(on)
  if not WLDTDB then return end
  WLDTDB.trackerCollapsed = on and true or nil
  TR.Refresh()
end

function TR.Frame() return f end
