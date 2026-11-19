-- Suivi du guide : un petit cadre toujours à l'écran (déplaçable, repliable) qui suit la route action
-- par action. En haut le chapitre (avant / dans / après le donjon, avec l'avancée), puis l'action en
-- cours avec son icône, les barres de ses objectifs, et les deux actions suivantes en grisé.
-- Clic : ouvre le guide sur l'étape. Maj-clic : marque l'étape comme faite.
-- Public: WLHelperTracker.Refresh(), .Toggle(), .SetShown(on), .IsOn(), .Collapse(on), .Model().
local ADDON, ns = ...
local L, T, F = ns.L, ns.Tok, ns.F

-- 300: a compact overlay, the one width outside the window set (docs/DESIGN.md 3.1)
-- v2 after RestedXP's and Polestar's step cards (report: "nothing like RestedXP"): a header with
-- the dungeon, its levels, the step and the percent; the current step in a card ("ÉTAPE 8 · AVANT LE
-- DONJON", the action in 16 px with its names in colour, each objective with its count and a green
-- bar); "Ensuite" and the next 3 actions in plain text; the guide's progress bar at the bottom.
local W, PAD, ICON, GAP = 340, 12, 18, 8        -- width, inner pad, action icon, icon-to-text
local NEXT_H, NEXT_ICON, BAR_H = 24, 16, 3      -- next-action line, its icon, objective bar
local HEAD_H, MAX_BARS, MAX_NEXT = 34, 4, 3
local CARD_PAD = 10                              -- inside the current step's card
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
  if n.kind == "a" then
    a.kind, a.text, a.sub = "take", L.TR_TAKE:format(qn), Where(n)
    -- a quest that starts from an item: which one (report: "I did The Essence of Eranikus already",
    -- the second quest of that name starts from the Oathstone in the bags)
    local qq = ns.Q[n.q]
    local it = qq and qq.s and qq.s.i == 1 and (qq.si or qq.s.n)
    if it and L.TR_FROM_ITEM then a.text = a.text .. "  " .. Hex(T.muted) .. L.TR_FROM_ITEM:format((ns.LN and ns.LN("item", it)) or it) .. "|r" end
  elseif n.kind == "t" then a.kind, a.text, a.sub = "turn", L.TR_TURN:format(qn), Where(n)
  elseif n.kind == "h" then a.kind, a.text, a.sub = "have", L.TR_HAVE:format(qn), Where(n)
  elseif n.kind == "i" then
    local nm = n.label and (ns.T(n.label) or n.label) or qn
    a.kind, a.text, a.sub = "item", L.TR_ITEM:format(nm), Where(n)
  elseif o then
    a.obj = o
    a.kind = OBJ_KIND[o.k] or "go"
    local nm = o.k ~= "text" and o.n and (ns.T(o.n) or o.n) or nil
    if nm and log and ns.ObjDisplayName then
      local ok, g = pcall(ns.ObjDisplayName, n, o, log)
      if ok and type(g) == "string" and g ~= "" then nm = g end
    end
    if nm then a.text = L[(ns.ObjVerbKey and ns.ObjVerbKey(o, nm)) or OBJ_TEXT[a.kind]]:format(nm)
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

-- A quest to take that starts from an item you do not have (the Oathstone of Ysera's Dragonflight
-- after the Essence of Eranikus): nothing to do here, so it is not offered as a next action (report:
-- "I put the essence in the font, then nothing")
local function MissingStartItem(a)
  if not (a and a.kind == "take" and a.node and a.node.q) then return false end
  local q = ns.Q[a.node.q]
  local sid = q and q.s and q.s.i == 1 and q.sid
  if not sid then return false end
  local count = (C_Item and C_Item.GetItemCount) or GetItemCount
  if not count then return false end
  local ok, n = pcall(count, sid, true)
  return ok and type(n) == "number" and n == 0
end
TR._MissingStartItem = MissingStartItem

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
  -- no guide, or every step done: a card that says so with the way to the next guide, never an
  -- empty screen (report: "I finished a guide in the modern view and the guide picker is gone")
  if not (steps and #steps > 0 and ns.CurrentStepIndex) then
    return { finished = true, none = true, title = L.TR_NONE_T, stepN = 1, stepTotal = nil }
  end
  local log = ns.LogEntries()
  local idx, st = ns.CurrentStepIndex(log)
  if not (idx and st) then
    if not TR.browse then return { finished = true, idx = #steps + 1, stepN = #steps + 1, pct = 100, title = L.TR_DONE_T } end
    idx, st = #steps + 1, nil                     -- past the end: the step browsed back to below
  end
  -- the step browsed with the header's arrows (TR.browse), else the current one
  local curIdx = idx
  if TR.browse then
    TR.browse = math.max(1, math.min(#steps, TR.browse))
    if TR.browse == curIdx then TR.browse = nil else idx, st = TR.browse, steps[TR.browse] end
  end
  local m = { idx = idx, st = st, curIdx = curIdx, browsing = idx ~= curIdx }
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
  m.phaseText = L["PH_" .. ph:upper() .. "_S"]
  m.name = dk and ns.D[dk] and ns.DName(dk) or nil
  local d = dk and ns.D[dk]
  if d and d.lvl and d.lvl[1] then m.lvl = (d.lvl[2] and d.lvl[2] ~= d.lvl[1]) and (d.lvl[1] .. "-" .. d.lvl[2]) or tostring(d.lvl[1]) end
  m.stepN, m.stepTotal = idx, #steps
  local nDone = 0
  for j = 1, #steps do if ns.IsStepDone(log, j) then nDone = nDone + 1 end end
  m.pct = math.floor(nDone * 100 / math.max(1, #steps) + 0.5)
  -- the current action: the first one not done in the step (the gate: entering)
  local acts = TR.StepActions(idx, st, log)
  local cur, curPos
  for k, a in ipairs(acts) do if not a.done then cur, curPos = a, k break end end
  -- a browsed step all done: its first line, as it was
  if not cur and m.browsing and acts[1] then cur, curPos = acts[1], 1 end
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
  -- an objective with its bar: the bar says what to do and how many ("Loot: Magenta Fungus Cap
  -- 1/12"), the title says the quest (report: "we can't see the quest's name well, it should be the
  -- most important thing since there is already an objective bar")
  if cur.obj and cur.node and cur.node.q and m.bars[1] and m.bars[1].o == cur.obj then
    local qn = ns.QName(cur.node.q)
    if type(qn) == "string" and qn ~= "" then
      m.qTitle = qn
      m.bars[1].label = cur.text
    end
  end
  -- everything the guide window's card says about this action (report: "Polestar keeps the same
  -- level of information as our other view, only nicer"): where and how far, why now, the drops,
  -- the other objectives, the details (what it asks, the reward, our notes, the game's text); on a
  -- boss, its tactics and the loot for you. The window's own model (ns.FocusModel), nothing redone.
  if cur.node and ns.FocusModel then
    local okF, M = pcall(ns.FocusModel, cur.node, log, dk, cur.st or st)
    if okF and type(M) == "table" then m.focus = M end
  end
  local bst = (cur.st and cur.st.bossStep) and cur.st or (st.bossStep and st or nil)
  if bst then
    if ns.BossTacticText then local okT, t = pcall(ns.BossTacticText, bst); if okT and type(t) == "string" then m.tactic = t end end
    if ns.BossLootText then local okL, t = pcall(ns.BossLootText, bst); if okL and type(t) == "string" then m.loot = t end end
  end
  -- the route's steps around the one shown, when the list is open (WLDTDB.trackerSteps): every
  -- step's title, done or not, a click shows it here
  if WLDTDB.trackerSteps then
    m.stepList = {}
    local from = math.max(1, idx - 4)
    local to = math.min(#steps, from + 11)
    from = math.max(1, to - 11)
    for i = from, to do
      local okT, title = pcall(ns.StepTitle, steps[i])
      m.stepList[#m.stepList + 1] = { i = i, title = okT and title or tostring(i), done = ns.IsStepDone(log, i) and true or false,
        cur = (i == curIdx), view = (i == idx) }
    end
  end
  -- travel hint (long trip, other continent) on the current step
  if st.travel == "TRAVEL_FAR" or st.travel == "TRAVEL_CONT" then m.travel = L[st.travel] end
  -- the next actions: the rest of this step, then the steps after it
  m.nexts = {}
  for k = curPos + 1, #acts do
    if #m.nexts >= MAX_NEXT then break end
    if not acts[k].done and not MissingStartItem(acts[k]) then m.nexts[#m.nexts + 1] = acts[k] end
  end
  local j = idx + 1
  while #m.nexts < MAX_NEXT and j <= #steps do
    if not ns.IsStepDone(log, j) then
      for _, a in ipairs(TR.StepActions(j, steps[j], log)) do
        if #m.nexts >= MAX_NEXT then break end
        if not a.done and not MissingStartItem(a) and not (ahead and a.node == ahead and a.text == cur.text) then m.nexts[#m.nexts + 1] = a end
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
  -- the window itself (the menu's "window" entry): never back to this view
  if ns.ShowWindow then ns.ShowWindow() elseif ns.ShowGuide then ns.ShowGuide() end
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

-- line k of the card's information (made the first time it is needed)
local function InfoLine(k)
  local fs = f.info[k]
  if not fs then
    fs = ns.Text(f, F.label, T.text)
    fs:SetJustifyH("LEFT"); fs:SetJustifyV("TOP"); fs:SetWordWrap(true)
    fs:SetWidth(TEXT_W)
    f.info[k] = fs
  end
  return fs
end

-- the action's names in colour: what is quoted (« Name », "Name") or what follows "Verb: "
local function Rich(text)
  if type(text) ~= "string" or text == "" then return text end
  local NAME = Hex(T.info)
  local out, n = text:gsub("«(.-)»", function(x) return "«" .. NAME .. x .. "|r»" end)
  if n == 0 then out, n = text:gsub('"(.-)"', function(x) return '"' .. NAME .. x .. '|r"' end) end
  if n == 0 then out, n = text:gsub("^(.-:%s+)(.+)$", function(a, b) return a .. NAME .. b .. "|r" end) end
  return out
end
TR._Rich = Rich

-- the links under the bar: { label, action } for this model
local function Links(m)
  local dk = m and m.dk
  local out = {
    { (m and m.finished) and L.TR_M_PICK or L.TR_L_PICK, function() if ns.ShowPicker then ns.ShowPicker() end end },
  }
  if dk and ns.ShowOverview then out[#out + 1] = { L.TR_L_OVERVIEW, function() ns.ShowOverview(dk) end } end
  if dk and ns.ToggleBosses then out[#out + 1] = { L.TR_L_BOSSES, function() ns.ToggleBosses(dk) end } end
  if dk and ns.OpenDungeonMap then out[#out + 1] = { L.TR_L_MAP, function() ns.OpenDungeonMap(dk) end } end
  if ns.ShareQuests then out[#out + 1] = { L.TR_L_SHARE, function() ns.ShareQuests() end } end
  return out
end
local function LinkBtn(k)
  local b = f.links[k]
  if not b then
    b = CreateFrame("Button", nil, f)
    b:SetHeight(18)
    b.text = ns.Text(b, F.meta, T.accentSoft)
    b.text:SetPoint("LEFT", 0, 0); b.text:SetWordWrap(false)
    b:SetScript("OnEnter", function(self) self.text:SetTextColor(T.fg[1], T.fg[2], T.fg[3]) end)
    b:SetScript("OnLeave", function(self) local c = T.accentSoft; self.text:SetTextColor(c[1], c[2], c[3]) end)
    b:SetScript("OnClick", function(self) if self.fn then pcall(self.fn) end; TR.Refresh() end)
    f.links[k] = b
  end
  return b
end

-- row k of the steps list
local function StepRow(k)
  local r = f.stepRows[k]
  if not r then
    r = CreateFrame("Button", nil, f)
    r:SetHeight(20)
    r.hl = ns.Tex(r, "HIGHLIGHT", T.hoverFill); r.hl:SetAllPoints()
    r.text = ns.Text(r, F.label, T.text)
    r.text:SetPoint("LEFT", 4, 0); r.text:SetPoint("RIGHT", -4, 0)
    r.text:SetJustifyH("LEFT"); r.text:SetWordWrap(false)
    r:SetScript("OnClick", function(self)
      if not self.i then return end
      if IsShiftKeyDown and IsShiftKeyDown() then TR.MarkDone(self.i) else TR.browse = self.i; if ns.Refresh then ns.Refresh() end; TR.Refresh() end
    end)
    f.stepRows[k] = r
  end
  return r
end

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
  -- the step shown here, in the modern view (the window only from the menu)
  if IsShiftKeyDown and IsShiftKeyDown() then TR.MarkDone(a.i) else TR.browse = a.i; if ns.Refresh then ns.Refresh() end; TR.Refresh() end
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
  if ns.RegisterWindow then ns.RegisterWindow(f) end
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
  head:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  head:SetScript("OnDragStart", function() f:StartMoving() end)
  head:SetScript("OnDragStop", function() f:StopMovingOrSizing(); SavePos() end)
  head.title = ns.Text(head, F.title, T.fg)
  head.title:SetWidth(W - PAD * 2 - 24 - GAP)
  head.title:SetWordWrap(false)
  Anchor(head.title, "TOPLEFT", head, "TOPLEFT", PAD, -9)
  -- the dungeon's levels (gold), the step and the percent (blue), at the right of the title, between
  -- the arrows that browse the steps (report: "previous / next step with small arrows"); then the
  -- menu button and the fold button
  local function SmallBtn(icon, tip, onClick)
    local b = CreateFrame("Button", nil, f)
    b:SetSize(20, 24)
    b:SetFrameLevel(head:GetFrameLevel() + 2)
    b.icon = b:CreateTexture(nil, "ARTWORK"); b.icon:SetSize(14, 14); b.icon:SetPoint("CENTER")
    ns.SetHDIcon(b.icon, icon, T.muted)
    b.hl = ns.Tex(b, "BACKGROUND", T.hoverFill); b.hl:SetAllPoints(); b.hl:Hide()
    b:SetScript("OnEnter", function(self) self.hl:Show(); ns.SetHDIcon(self.icon, icon, T.fg); ns.ShowTip(self, type(tip) == "function" and tip() or tip) end)
    b:SetScript("OnLeave", function(self) self.hl:Hide(); ns.SetHDIcon(self.icon, icon, self.off and T.faint or T.muted); if ns.HideTip then ns.HideTip() end end)
    b:SetScript("OnClick", function(self, btn) if not self.off then onClick(self, btn) end end)
    function b:SetOff(off) self.off = off; ns.SetHDIcon(self.icon, icon, off and T.faint or T.muted) end
    return b
  end
  f.menuBtn = SmallBtn("gear", { L.TR_MENU, L.TR_MENU_TIP }, function(self) TR.ToggleMenu(self) end)
  f.menuBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -(PAD - 6 + 24 + 22), -2)
  f.nextBtn = SmallBtn("chevron_right", { L.TR_NEXT }, function() TR.Browse(1) end)
  f.nextBtn:SetPoint("TOPRIGHT", f.menuBtn, "TOPLEFT", -2, 0)
  head.meta = ns.Text(head, F.label, T.muted)
  head.meta:SetJustifyH("RIGHT"); head.meta:SetWordWrap(false)
  head.meta:SetPoint("RIGHT", f.nextBtn, "LEFT", -2, 0)
  f.prevBtn = SmallBtn("chevron_left", { L.TR_PREV }, function() TR.Browse(-1) end)
  f.prevBtn:SetPoint("RIGHT", head.meta, "LEFT", -2, 0)
  Feedback(head, { head.title })
  head:SetScript("OnEnter", function(self)
    self.hl:Show()
    ns.ShowTip(self, { L.TR_WHAT or L.TR_TITLE, (f.model and f.model.title) or L.TR_TITLE, L.TR_TIP_CLICK, L.TR_TIP_DRAG,
      WLDTDB.trackerCollapsed and L.TR_EXPAND or L.TR_COLLAPSE })
  end)
  head:SetScript("OnLeave", function(self) self.hl:Hide(); if ns.HideTip then ns.HideTip() end end)
  head:SetScript("OnClick", function(self, btn)
    if btn == "RightButton" then TR.ToggleMenu(self) return end
    -- a left-click on the title: nothing but the drag (the window is in the menu)
  end)
  f.head = head
  -- the row-action size: 24 px hit area, 16 px icon; hover fill, press fill and a 1 px nudge
  local col = CreateFrame("Button", nil, f)
  col:SetSize(24, 24)
  col:SetPoint("TOPRIGHT", f, "TOPRIGHT", -PAD + 6 - 22, -2)
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
  -- close (report: "the modern view has no button to close it"): the guide hides, as the window's
  -- close does; the minimap button, /wlh or a guide button bring it back
  f.closeBtn = SmallBtn("close", { L.TR_CLOSE or CLOSE or "Close", L.TR_CLOSE_TIP }, function() TR.Close() end)
  f.closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -PAD + 6, -2)
  -- body
  -- the current step's card: a lighter fill and a 1 px edge, as RestedXP's
  f.card = CreateFrame("Frame", nil, f)
  f.card.fill = ns.Tex(f.card, "BACKGROUND", { 1, 1, 1, 0.06 }); f.card.fill:SetAllPoints()
  if ns.Outline then pcall(ns.Outline, f.card, { 1, 1, 1, 0.10 }) end
  f.card:SetFrameLevel(f:GetFrameLevel() + 1)
  f.stepLabel = ns.Text(f, F.meta, T.warn)
  f.stepLabel:SetWordWrap(false)
  f.backBtn = CreateFrame("Button", nil, f)
  f.backBtn:SetAllPoints(f.stepLabel)
  f.backBtn:SetFrameLevel(f:GetFrameLevel() + 4)
  f.backBtn:SetScript("OnClick", function() TR.browse = nil; if ns.Refresh then ns.Refresh() end; TR.Refresh() end)
  f.backBtn:Hide()
  f.cur = MakeRow(f, ICON, F.title, T.fg)
  f.cur:SetFrameLevel(f.card:GetFrameLevel() + 1)
  f.cur.sub = ns.Text(f.cur, F.label, T.muted)
  f.cur.sub:SetWidth(TEXT_W)
  table.insert(f.cur.content, f.cur.sub)
  f.travel = ns.Text(f, F.label, T.muted)
  f.travel:SetWidth(TEXT_W)
  f.travelIcon = f:CreateTexture(nil, "ARTWORK"); f.travelIcon:SetSize(NEXT_ICON, NEXT_ICON)
  ns.SetHDIcon(f.travelIcon, ns.ARROW, T.muted)
  f.bars = {}
  for k = 1, MAX_BARS do
    local b = CreateFrame("Frame", nil, f)
    b:SetSize(TEXT_W, 18)
    b:SetFrameLevel(f.card:GetFrameLevel() + 1)
    b.label = ns.Text(b, F.body, T.text); b.label:SetWidth(TEXT_W - 56)
    b.label:SetPoint("TOPLEFT", b, "TOPLEFT", 0, 0)
    b.count = ns.Text(b, F.body, T.fg); b.count:SetWidth(52); b.count:SetJustifyH("RIGHT"); b.count:SetWordWrap(false)
    b.count:SetPoint("TOPRIGHT", b, "TOPRIGHT", 0, 0)
    b.track = ns.Tex(b, "ARTWORK", T.divider); b.track:SetHeight(BAR_H)
    b.fill = ns.Tex(b, "OVERLAY", T.text); b.fill:SetHeight(BAR_H)
    f.bars[k] = b
  end
  -- the card's other lines (where, why, drops, objectives, details, tactics, loot): made as needed
  f.info = {}
  f.thenLabel = ns.Text(f, F.meta, T.muted)
  f.thenLabel:SetText(L.TR_THEN or "Ensuite")
  f.nexts = {}
  for k = 1, MAX_NEXT do
    local r = MakeRow(f, NEXT_ICON, F.body, T.text)
    f.nexts[k] = r
  end
  -- the steps list: a toggle line, then up to 12 rows (made as needed)
  f.stepsToggle = CreateFrame("Button", nil, f)
  f.stepsToggle:SetHeight(20)
  f.stepsToggle.text = ns.Text(f.stepsToggle, F.meta, T.muted)
  f.stepsToggle.text:SetPoint("LEFT", 0, 0)
  f.stepsToggle:SetScript("OnClick", function() WLDTDB.trackerSteps = not WLDTDB.trackerSteps or nil; TR.Refresh() end)
  f.stepRows = {}
  -- the guide's progress, at the bottom (Polestar's bar and percent)
  f.prog = ns.Tex(f, "ARTWORK", T.divider); f.prog:SetHeight(4)
  f.progFill = ns.Tex(f, "OVERLAY", T.info); f.progFill:SetHeight(4)
  f.progText = ns.Text(f, F.meta, T.muted); f.progText:SetJustifyH("RIGHT")
  -- always on screen under the bar, the ways out of the guide's step (report: "the dungeon picker
  -- and the like must be found somehow from the modern view"): small text links
  f.links = {}
  Place()
  f:Hide()
  return f
end

-- Frameless, as Polestar draws its guide (report: "the frameless version, Polestar style"): no
-- backdrop, no edge, no card; every line keeps a shadow to stay readable over the world. On by
-- default (WLDTDB.trackerFrameless = false: the framed card, RestedXP's).
function TR.Frameless() return not (WLDTDB and WLDTDB.trackerFrameless == false) end
local function ApplyFrameless(on)
  if f.frameless == on then return end
  f.frameless = on
  if f._bg then f._bg:SetShown(not on) end
  for _, e in pairs(f._edges or {}) do if e and e.SetShown then e:SetShown(not on) end end
  local texts = { f.head.title, f.head.meta, f.stepLabel, f.cur.text, f.cur.sub, f.thenLabel, f.progText, f.travel }
  for _, b in ipairs(f.bars) do texts[#texts + 1] = b.label; texts[#texts + 1] = b.count end
  for _, r in ipairs(f.nexts) do texts[#texts + 1] = r.text end
  for _, fs in ipairs(texts) do if fs and ns.Shadow then ns.Shadow(fs, on) end end
end
function TR.SetFrameless(on)
  if not WLDTDB then return end
  if on == false then WLDTDB.trackerFrameless = false else WLDTDB.trackerFrameless = nil end
  TR.Refresh()
end

local function Wanted()
  -- off unless asked for (/wlh suivi or Settings): the guide window and its "-" mini mode are the
  -- usual way; two small views of the same step confused players
  if not WLDTDB or WLDTDB.tracker ~= true then return false end
  if WLDTDB.trackerClosed then return false end
  if ns.GuideOn and not ns.GuideOn() then return false end
  -- one view at a time: the small tracker while you play, the big guide window when you open it
  if ns.frame and ns.frame:IsShown() then return false end
  -- no guide loaded: still on, to offer the guide picker (TR.Model's "finished" card)
  return true
end

local PlaceLinks
-- Draws the model; the tracker's height follows its content.
local function Draw(m)
  local head = f.head
  ApplyFrameless(TR.Frameless())
  local collapsed = WLDTDB.trackerCollapsed
  -- folded: the action to do now on the one line, so the folded tracker still says something
  -- useful ("Rendre « Powering the Pylons » · 1/9"); open: the chapter title
  local title = m.title or L.TR_TITLE
  if collapsed and m.cur and m.cur.text then
    local prog = (m.title or ""):match("(%d+/%d+)%s*$")
    title = m.cur.text .. (prog and ("  " .. Hex(T.muted) .. prog .. "|r") or "")
  end
  -- open: the dungeon's name (else the phase), its levels, the step and the percent on the right
  local meta = ""
  if not collapsed then
    title = m.name or m.phaseText or title
    local parts = {}
    if m.lvl then parts[#parts + 1] = Hex(T.gold) .. m.lvl .. "|r" end
    if m.stepN and m.stepTotal then parts[#parts + 1] = Hex(T.text) .. m.stepN .. "/" .. m.stepTotal .. "|r" end
    if m.pct then parts[#parts + 1] = Hex(T.info) .. m.pct .. " %|r" end
    meta = table.concat(parts, "  ")
  end
  head.meta:SetText(meta)
  local metaW = 0
  if meta ~= "" then local okW, mw = pcall(head.meta.GetStringWidth, head.meta); metaW = (okW and type(mw) == "number" and not secret(mw)) and mw or 90 end
  head.title:SetWidth(math.max(80, W - PAD * 2 - 24 - 22 - 24 - 20 - 20 - GAP - metaW - (metaW > 0 and 8 or 0)))
  -- the arrows: off at either end, hidden when folded
  local nSteps = ns.route and ns.route.steps and #ns.route.steps or 0
  f.prevBtn:SetShown(not collapsed); f.nextBtn:SetShown(not collapsed)
  f.closeBtn:Show(); f.menuBtn:Show()
  f.prevBtn:SetOff((m.stepN or 1) <= 1); f.nextBtn:SetOff((m.stepN or 1) >= nSteps)
  head.title:SetText(title)
  local headH = math.max(HEAD_H, TextH(head.title, F.title) + 18)
  head:SetHeight(headH)
  ns.SetHDIcon(f.col.icon, collapsed and "chevron_down" or "chevron_up", T.muted)
  local y = headH
  local function hideBody()
    for _, fs in ipairs(f.info or {}) do fs:Hide() end
    if f.backBtn then f.backBtn:Hide() end
    if f.stepsToggle then f.stepsToggle:Hide() end
    for _, b in ipairs(f.links or {}) do b:Hide() end
    for _, r in ipairs(f.stepRows or {}) do r:Hide() end
    f.cur:Hide(); f.travel:Hide(); f.travelIcon:Hide()
    f.card:Hide(); f.stepLabel:Hide(); f.thenLabel:Hide(); f.prog:Hide(); f.progFill:Hide(); f.progText:Hide()
    for _, b in ipairs(f.bars) do b:Hide() end
    for _, r in ipairs(f.nexts) do r:Hide() end
  end
  if collapsed then hideBody(); f:SetHeight(y) return end
  -- the guide is over (or none is loaded): a line, then the links (the guide picker first)
  if m.finished then
    hideBody()
    f.stepLabel:SetText(m.none and L.TR_NONE_SUB or L.TR_DONE_SUB)
    if ns.Shadow then ns.Shadow(f.stepLabel, f.frameless) end
    f.stepLabel:ClearAllPoints(); f.stepLabel:SetPoint("TOPLEFT", f, "TOPLEFT", PAD, -(y + 8)); f.stepLabel:SetWidth(W - PAD * 2)
    f.stepLabel:Show()
    y = y + 8 + TextH(f.stepLabel, F.meta) + 8
    f:SetHeight(PlaceLinks(m, y) + 8)
    return
  end
  -- the current step's card: "ÉTAPE 8 · AVANT LE DONJON" in orange, then the action
  local cardTop = y + 4
  y = cardTop + CARD_PAD
  local lbl = string.format(L.TR_STEP or "ÉTAPE %d", m.stepN or 0)
  if m.phaseText then lbl = lbl .. "  ·  " .. m.phaseText end
  lbl = string.upper(lbl)
  if m.browsing then lbl = lbl .. "  " .. Hex(T.accentSoft) .. L.TR_BACK .. "|r" end
  f.stepLabel:SetText(lbl)
  f.stepLabel:ClearAllPoints(); f.stepLabel:SetPoint("TOPLEFT", f, "TOPLEFT", PAD + CARD_PAD - 4, -y)
  f.stepLabel:Show()
  f.backBtn:SetShown(m.browsing and true or false)
  y = y + TextH(f.stepLabel, F.meta) + 2
  local cur = f.cur
  cur.action = m.cur
  SetActIcon(cur.icon, m.cur.kind, false)
  local text
  if m.qTitle then text = Hex(T.gold) .. m.qTitle .. "|r"
  else
    text = Rich(m.cur.text or "")
    if m.cur.count then text = text .. "  " .. Hex(T.muted) .. m.cur.count .. "|r" end
  end
  cur.text:SetText(text)
  local h = 4 + TextH(cur.text, F.title)
  -- the card's own place line (with the distance) replaces this one: never the place twice
  if m.cur.sub and not (m.focus and m.focus.where) and not (m.qTitle and m.cur.sub == m.qTitle) then
    -- the place in colour, as Polestar writes it
    cur.sub:SetText(Hex(T.accentSoft) .. m.cur.sub .. "|r"); cur.sub:Show()
    Anchor(cur.sub, "TOPLEFT", cur, "TOPLEFT", PAD + ICON + GAP, -(h + 3))
    h = h + 3 + TextH(cur.sub, F.label)
  else cur.sub:Hide() end
  h = h + 6
  cur:ClearAllPoints(); cur:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -y); cur:SetHeight(h); cur:Show()
  y = y + h
  -- long trip hint
  if m.travel then
    f.travel:SetText(m.travel); f.travel:Show(); f.travelIcon:Show()
    f.travelIcon:ClearAllPoints(); f.travelIcon:SetPoint("TOPLEFT", f, "TOPLEFT", PAD + (ICON - NEXT_ICON) / 2, -(y + 1))
    f.travel:ClearAllPoints(); f.travel:SetPoint("TOPLEFT", f, "TOPLEFT", PAD + ICON + GAP, -y)
    y = y + TextH(f.travel, F.label) + 4
  else f.travel:Hide(); f.travelIcon:Hide() end
  -- objective bars
  for k, b in ipairs(f.bars) do
    local d = m.bars[k]
    if d then
      b.label:SetText(d.label)
      b.count:SetText(d.have .. "/" .. d.need)
      local c = d.fin and T.ok or T.fg
      b.count:SetTextColor(c[1], c[2], c[3])
      local lc = d.fin and T.muted or T.fg
      b.label:SetTextColor(lc[1], lc[2], lc[3])
      local lh = math.max(TextH(b.label, F.body), F.body + 2)
      b.track:ClearAllPoints(); b.track:SetPoint("TOPLEFT", b, "TOPLEFT", 0, -(lh + 3)); b.track:SetWidth(TEXT_W)
      local frac = (d.need > 0) and math.min(1, math.max(0, d.have / d.need)) or 0
      b.fill:ClearAllPoints(); b.fill:SetPoint("TOPLEFT", b.track, "TOPLEFT", 0, 0)
      b.fill:SetWidth(math.max(1, TEXT_W * frac)); b.fill:SetShown(frac > 0)
      -- green as it fills (RestedXP's line under each objective)
      local fc = T.ok
      b.fill:SetColorTexture(fc[1], fc[2], fc[3], d.fin and 1 or 0.85)
      local bh = lh + 3 + BAR_H
      b:SetHeight(bh)
      b:ClearAllPoints(); b:SetPoint("TOPLEFT", f, "TOPLEFT", PAD + ICON + GAP, -y)
      b:Show()
      y = y + bh + 6
    else b:Hide() end
  end
  -- the rest of the guide card's information, inside the card
  local nInfo = 0
  local function Put(text, size, color, gap, heading)
    if type(text) ~= "string" or text == "" then return end
    nInfo = nInfo + 1
    local fs = InfoLine(nInfo)
    if fs._size ~= size then fs._size = size; if ns.SetFont then ns.SetFont(fs) end end
    local c = color or T.text
    fs:SetTextColor(c[1], c[2], c[3])
    fs:SetText(heading and string.upper(text) or text)
    if ns.Shadow then ns.Shadow(fs, f.frameless) end
    y = y + (gap or 4)
    fs:ClearAllPoints(); fs:SetPoint("TOPLEFT", f, "TOPLEFT", PAD + ICON + GAP, -y)
    fs:Show()
    y = y + TextH(fs, size)
  end
  local M = m.focus
  if M then
    if M.lead and M.lead ~= m.cur.sub then Put(M.lead, F.label, T.muted, 2) end
    if M.where then Put(M.where, F.label, T.accentSoft, 2) end
    for k, w in ipairs(M.why or {}) do
      if k == 1 and m.qTitle and type(w) == "string" then
        local function Plain(str, a, b)
          local i, j = str:find(a, 1, true)
          if i then return str:sub(1, i - 1) .. b .. str:sub(j + 1) end
          return str
        end
        w = Plain(w, L.CARD_WHY_MAIN:format(m.qTitle), L.CARD_WHY_MAIN_S)
        w = Plain(w, L.CARD_WHY_MAIN:format(m.qTitle):gsub("^%l", string.upper), L.CARD_WHY_MAIN_S)
        local q1 = L.CARD_WHY_Q:format(m.qTitle)
        w = Plain(w, q1, ""); w = Plain(w, (q1:gsub("^%l", string.upper)), "")
        w = w:gsub("^(|c%x%x%x%x%x%x%x%x)%s*·%s*", "%1"):gsub("^%s*·%s*", "")
      end
      if not (type(w) == "string" and w:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):match("^%s*$")) then Put(w, F.label, T.muted, 3) end
    end
    if M.drops then Put(M.drops, F.label, T.text, 4) end
    -- the other objectives, unless the bars above already count them
    if #(m.bars or {}) == 0 then for _, o in ipairs(M.objs or {}) do Put(o, F.label, T.text, 3) end end
    for _, b in ipairs(M.detBlocks or {}) do
      Put(b.h or L.TR_NOTE, F.meta, T.gold, 8, true)
      if b.list then Put(table.concat(b.list, "\n"), F.label, T.text, 2)
      elseif b.body then Put(table.concat(b.body, "\n"), F.label, T.text, 2) end
    end
  end
  if m.tactic then Put(L.H_TACTIC, F.meta, T.gold, 8, true); Put(m.tactic, F.label, T.text, 2) end
  if m.loot then Put(L.H_LOOT, F.meta, T.gold, 8, true); Put(m.loot, F.label, T.text, 2) end
  for k = nInfo + 1, #f.info do f.info[k]:Hide() end
  -- the card closes under the step's last line
  y = y + CARD_PAD - 6
  f.card:ClearAllPoints()
  f.card:SetPoint("TOPLEFT", f, "TOPLEFT", PAD - 4, -cardTop)
  f.card:SetPoint("TOPRIGHT", f, "TOPRIGHT", -(PAD - 4), -cardTop)
  f.card:SetHeight(y - cardTop); f.card:SetShown(not f.frameless)
  y = y + 8
  -- "Ensuite", then the next actions in plain text (Polestar's list)
  if #m.nexts > 0 then
    f.thenLabel:SetText(string.upper(L.TR_THEN or "Ensuite"))
    f.thenLabel:ClearAllPoints(); f.thenLabel:SetPoint("TOPLEFT", f, "TOPLEFT", PAD, -y); f.thenLabel:Show()
    y = y + TextH(f.thenLabel, F.meta) + 2
  else f.thenLabel:Hide() end
  for k, r in ipairs(f.nexts) do
    local a = m.nexts[k]
    if a then
      r.action = a
      SetActIcon(r.icon, a.kind, false)
      r.text:SetText(Rich(a.text or ""))
      local rh = math.max(NEXT_H, TextH(r.text, F.body) + 8)
      r:SetHeight(rh)
      r:ClearAllPoints(); r:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -y)
      r:Show()
      y = y + rh
    else r:Hide(); r.action = nil end
  end
  -- the steps list (its toggle always; its rows when open)
  y = y + 6
  local open = WLDTDB.trackerSteps and m.stepList
  f.stepsToggle.text:SetText(string.upper(open and L.TR_STEPS_HIDE or L.TR_STEPS_SHOW))
  if ns.Shadow then ns.Shadow(f.stepsToggle.text, f.frameless) end
  f.stepsToggle:ClearAllPoints(); f.stepsToggle:SetPoint("TOPLEFT", f, "TOPLEFT", PAD, -y); f.stepsToggle:SetWidth(W - PAD * 2)
  f.stepsToggle:Show()
  y = y + 20
  local nRows = 0
  for k, e in ipairs(open and m.stepList or {}) do
    nRows = k
    local r = StepRow(k)
    r.i = e.i
    local mark = e.done and (Hex(T.ok) .. "✓|r ") or (e.cur and (Hex(T.warn) .. "▶|r ") or (Hex(T.muted) .. "•|r "))
    local col = e.view and Hex(T.fg) or (e.done and Hex(T.muted) or Hex(T.text))
    r.text:SetText(mark .. Hex(T.muted) .. e.i .. "|r  " .. col .. Rich(tostring(e.title)) .. "|r")
    if ns.Shadow then ns.Shadow(r.text, f.frameless) end
    r:ClearAllPoints(); r:SetPoint("TOPLEFT", f, "TOPLEFT", PAD, -y); r:SetWidth(W - PAD * 2)
    r:Show()
    y = y + 20
  end
  for k = nRows + 1, #f.stepRows do f.stepRows[k]:Hide() end
  -- the guide's progress
  y = y + 8
  local frac = math.min(1, math.max(0, (m.pct or 0) / 100))
  local barW = W - PAD * 2 - 44
  f.prog:ClearAllPoints(); f.prog:SetPoint("TOPLEFT", f, "TOPLEFT", PAD, -(y + 5)); f.prog:SetWidth(barW); f.prog:Show()
  f.progFill:ClearAllPoints(); f.progFill:SetPoint("TOPLEFT", f.prog, "TOPLEFT", 0, 0)
  f.progFill:SetWidth(math.max(1, barW * frac)); f.progFill:SetShown(frac > 0)
  f.progText:SetText((m.pct or 0) .. " %")
  f.progText:ClearAllPoints(); f.progText:SetPoint("TOPRIGHT", f, "TOPRIGHT", -PAD, -y); f.progText:Show()
  y = y + 14
  f:SetHeight(PlaceLinks(m, y) + 8)
end

-- the links, on one line (two when they do not fit), from y; -> the y under them
PlaceLinks = function(m, y)
  y = y + 6
  local x, used = PAD, 0
  for k, it in ipairs(Links(m)) do
    local b = LinkBtn(k)
    b.fn = it[2]
    b.text:SetText(it[1])
    if ns.Shadow then ns.Shadow(b.text, f.frameless) end
    local okW, tw = pcall(b.text.GetStringWidth, b.text)
    tw = (okW and type(tw) == "number" and not secret(tw)) and math.ceil(tw) or 60
    if x + tw > W - PAD and x > PAD then x = PAD; y = y + 18 end
    b:SetWidth(tw); b:ClearAllPoints(); b:SetPoint("TOPLEFT", f, "TOPLEFT", x, -y)
    b:Show()
    x = x + tw + 14
    used = k
  end
  for k = used + 1, #f.links do f.links[k]:Hide() end
  return y + 18
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

-- the header's arrows: one step back or ahead (TR.browse), the current step again past it
function TR.Browse(delta)
  local m = f and f.model
  if not m then return end
  TR.browse = (m.idx or m.curIdx or 1) + delta
  if ns.Refresh then ns.Refresh() end
  TR.Refresh()
end

-- the menu (the gear, or a right-click on the title): the guide window's actions here
local menu
local function MenuItems()
  local m = f and f.model
  local dk = m and m.dk
  local items = {
    { L.TR_M_PICK, function() if ns.ShowPicker then ns.ShowPicker() end end },
    { L.TR_M_WINDOW, function() TR.OpenGuide(m and m.idx) end },
    { L.TR_M_GO, function() if WLDTDB.arrow == false then WLDTDB.arrow = true end; if ns.PlacePoints then ns.PlacePoints() end end },
    { L.TR_M_DONE, function() if m then TR.MarkDone(m.idx) end end },
    { L.TR_M_SHARE, function() if ns.ShareQuests then ns.ShareQuests() end end },
  }
  local bst = m and m.st and m.st.bossStep and m.st
  if bst and ns.AnnounceTactics then items[#items + 1] = { L.TR_M_TACTICS, function() ns.AnnounceTactics(bst) end } end
  if dk and ns.ToggleBosses then items[#items + 1] = { L.TR_M_BOSSES, function() ns.ToggleBosses(dk) end } end
  if dk and ns.OpenDungeonMap then items[#items + 1] = { L.TR_M_MAP, function() ns.OpenDungeonMap(dk) end } end
  if dk and ns.ShowOverview then items[#items + 1] = { L.TR_M_OVERVIEW, function() ns.ShowOverview(dk) end } end
  items[#items + 1] = { TR.Frameless() and L.TR_M_FRAMED or L.TR_M_FRAMELESS, function() TR.SetFrameless(not TR.Frameless()) end }
  items[#items + 1] = { L.TR_M_OPTIONS, function()
    local WP = ns.Writs and ns.Writs.WP
    if WP and WP.OpenOptions then WP.OpenOptions("dungeons") end
  end }
  items[#items + 1] = { L.TR_M_STOP, function() if ns.StopRoute then ns.StopRoute() end end, confirm = true }
  items[#items + 1] = { L.TR_M_HIDE, function() TR.SetShown(false) end }
  return items
end
function TR.ToggleMenu(anchor)
  if menu and menu:IsShown() then menu:Hide() return end
  if not menu then
    menu = CreateFrame("Frame", "WLDTTrackerMenu", UIParent)
    menu:SetFrameStrata("DIALOG")
    menu:SetClampedToScreen(true)
    ns.Flat(menu, T.panel or T.bg, T.cardEdge)
    menu.rows = {}
    tinsert(UISpecialFrames, "WLDTTrackerMenu")
  end
  local items = MenuItems()
  local w = 220
  for k, it in ipairs(items) do
    local r = menu.rows[k]
    if not r then
      r = CreateFrame("Button", nil, menu)
      r:SetHeight(24)
      r.hl = ns.Tex(r, "HIGHLIGHT", T.hoverFill); r.hl:SetAllPoints()
      r.text = ns.Text(r, F.label, T.fg); r.text:SetPoint("LEFT", 10, 0); r.text:SetPoint("RIGHT", -10, 0)
      r.text:SetJustifyH("LEFT"); r.text:SetWordWrap(false)
      menu.rows[k] = r
    end
    r:ClearAllPoints(); r:SetPoint("TOPLEFT", 4, -4 - (k - 1) * 24); r:SetPoint("TOPRIGHT", -4, -4 - (k - 1) * 24)
    r.text:SetText(it[1]); r.text:SetTextColor(T.fg[1], T.fg[2], T.fg[3])
    r.armed = nil
    r:SetScript("OnClick", function(self)
      -- "Stop this guide": a second click confirms
      if it.confirm and not self.armed then
        self.armed = true
        self.text:SetText(L.RESTART_CONFIRM); self.text:SetTextColor(T.warn[1], T.warn[2], T.warn[3])
        return
      end
      menu:Hide()
      pcall(it[2])
      TR.Refresh()
    end)
    r:Show()
  end
  for k = #items + 1, #menu.rows do menu.rows[k]:Hide() end
  menu:SetSize(w, 8 + #items * 24)
  menu:ClearAllPoints()
  menu:SetPoint("TOPRIGHT", anchor or f, "BOTTOMRIGHT", 0, -2)
  menu:Show()
end
TR._Menu = function() return menu end

-- The guide's "-": the window gives way to the tracker (open, not folded); a click on the tracker
-- brings the whole guide back (TR.OpenGuide).
function TR.Close()
  if not WLDTDB then return end
  WLDTDB.trackerClosed = true
  WLDTDB.hidden = true          -- a reload or a loading screen does not bring it back
  if f then f:Hide() end
  if TR.menuFrame and TR.menuFrame.Hide then TR.menuFrame:Hide() end
  if ns.SetArrow then ns.SetArrow(nil) end
  if ns.UpdateActionBar then ns.UpdateActionBar() end
end
function TR.IsClosed() return WLDTDB ~= nil and WLDTDB.trackerClosed == true end

function TR.Compact()
  if not WLDTDB then return end
  local first = WLDTDB.tracker ~= true
  WLDTDB.trackerClosed = nil
  WLDTDB.tracker = true
  WLDTDB.trackerCollapsed = nil
  -- the window gives way, but the guide stays open (its arrow too): not a "closed" hide
  if ns.frame and ns.frame:IsShown() then
    local q = ns.quietHide
    ns.quietHide = true
    ns.frame:Hide()
    ns.quietHide = q
  end
  WLDTDB.hidden = false
  TR.Refresh()
  if first and L.TR_COMPACT then ns.Print(L.TR_COMPACT) end
end

function TR.SetShown(on)
  if not WLDTDB then return end
  WLDTDB.tracker = on and true or false
  -- hidden from its menu: the guide is closed, as with the window's close button (its arrow too)
  if not on and not (ns.frame and ns.frame:IsShown()) then
    WLDTDB.hidden = true
    if ns.SetArrow then ns.SetArrow(nil) end
  end
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
