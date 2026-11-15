-- Fenêtre du guide : une étape à la fois, liste des étapes, boutons de ciblage / objet / GPS.
local ADDON, ns = ...
local L, T = ns.L, ns.T_
local Text, Tex, Button, Hex = ns.Text, ns.Tex, ns.Button, ns.Hex

-- 520: the design system's two-column width; the grip changes it between 420 and 640.
local W, PAD, MAXROWS = 520, 16, 30
local CARD_MAX = 2000                 -- the card's height cap (older saves); the screen cap applies first
local W0, CARD0 = 520, 2000
local LISTW, LISTROWS, LISTH = 272, 30, 28
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

-- Modern icons: the game's atlases when this client has them, else a file every vanilla-era client
-- ships (Interface\Icons\* cropped, or the old quest / skull / ready-check files). A missing path
-- draws a green square, a missing atlas draws nothing: the atlas is checked with GetAtlas.
local noAtlas = {}
local function SetIcon(tex, atlases, file, crop)
  if type(atlases) == "string" then atlases = { atlases } end
  for _, a in ipairs(atlases or {}) do
    if not noAtlas[a] then
      local ok = tex.SetAtlas and pcall(tex.SetAtlas, tex, a, false)
      local got = ok and tex.GetAtlas and tex:GetAtlas()
      if type(got) == "string" and got:lower() == a:lower() then return true end
      noAtlas[a] = true
    end
  end
  tex:SetTexture(file or "Interface\\Icons\\INV_Misc_QuestionMark")
  if crop then tex:SetTexCoord(0.08, 0.92, 0.08, 0.92) else tex:SetTexCoord(0, 1, 0, 1) end
  return false
end
ns.GuideSetIcon = SetIcon
ns.SetIcon = ns.SetIcon or SetIcon

-- the guide's icons by meaning: HD interface icons (Media/Icons) tinted with a token, and the
-- game's own quest marks (a "thing" of the game, like a painted icon)
local ICON = {
  done  = { hd = "check", c = T.ok },
  take  = { { "QuestNormal" }, "Interface\\GossipFrame\\AvailableQuestIcon" },
  turn  = { { "QuestTurnin" }, "Interface\\GossipFrame\\ActiveQuestIcon" },
  boss  = { hd = "skull", c = T.fg },     -- neutral: red stays for blocked lines
  map   = { hd = "flag", c = T.info },
  check = { hd = "flag", c = T.muted },
  pin   = { hd = "pin", c = T.fg },
  miss  = { hd = "warning", c = T.warn },
  nokey = { hd = "warning", c = T.bad },
  gear  = { hd = "gear", c = T.muted },
}
local function Icon(tex, name)
  local d = ICON[name]
  if d.hd then ns.SetHDIcon(tex, d.hd, d.c); return true end
  tex:SetVertexColor(1, 1, 1)
  return SetIcon(tex, d[1], d[2], d[3])
end
ns.GuideIcon = Icon

-- Chat lines carry the addon tag once, then one sentence (design system 5.4).
function ns.Print(msg) print("|cffce1918WL|r " .. tostring(msg)) end

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

-- Once every step is done, the "route finished" card sits one place after the last step
-- (index #steps + 1): "<" and the step list still reach every step, the last one included.
local function FinIndex() return #Steps() + 1 end
local function RouteFinished() return f and f.auto ~= nil and f.auto == FinIndex() end

-- The route's dungeon you stand in right now (several wings may share one instance).
local function InsideKey()
  if not ns.InstanceKeys then return nil end
  local keys = ns.InstanceKeys()
  for _, k in ipairs(keys or {}) do
    for _, st in ipairs(Steps()) do if st.ins == k and not st.gate then return k end end
  end
  return nil
end
ns.InsideKey = InsideKey

-- What a check-list still misses: quests not in the log, and whether a needed key is missing.
local function ReadyState(log, st)
  local miss, total = 0, 0
  for _, nd in ipairs(st.checks or {}) do
    total = total + 1
    if not ns.NodeOK(log, nd) then miss = miss + 1 end
  end
  local keyMissing = false
  for _, k in ipairs(ns.KeyLines and ns.KeyLines(st.gate or st.ins) or {}) do if k[3] and not k[2] then keyMissing = true end end
  return miss, total, keyMissing
end

-- The check-list step the "Check-list" button opens: the one of the dungeon on screen,
-- else the next one ahead, else the first one.
local function ReadyTarget()
  local steps = Steps()
  local cur = steps[f and f.view or 1]
  local dkey = cur and (cur.gate or cur.ins or cur.d)
  local first, ahead
  for i, st in ipairs(steps) do
    if st.gate then
      first = first or i
      if st.gate == dkey then return i end
      if not ahead and f and f.auto and i >= f.auto then ahead = i end
    end
  end
  return ahead or first
end

-- Live progress of one objective ("3/5"), from the quest log; nil when unknown.
local function plainNum(v) return type(v) == "number" and not (issecretvalue and issecretvalue(v)) end
local function LiveCount(log, qid, oi, oname, nobj)
  local e = log and log[qid]
  if not e then return nil end
  local CQL = C_QuestLog
  if CQL and CQL.GetQuestObjectives then
    local ok, objs = pcall(CQL.GetQuestObjectives, qid)
    if ok and type(objs) == "table" then
      local pick
      if oname then for _, o in ipairs(objs) do if type(o) == "table" and type(o.text) == "string" and o.text:find(oname, 1, true) then pick = o break end end end
      -- by position only when the game lists as many objectives as the data (French client: other names)
      if not pick and oi and nobj == #objs then pick = objs[oi] end
      if type(pick) == "table" and plainNum(pick.numFulfilled) and plainNum(pick.numRequired) and pick.numRequired > 0 then
        return pick.numFulfilled, pick.numRequired, pick.finished and true or false
      end
    end
  end
  if e.index and GetNumQuestLeaderBoards and GetQuestLogLeaderBoard then
    local okN, n = pcall(GetNumQuestLeaderBoards, e.index)
    if not okN or not plainNum(n) then return nil end
    local function read(j)
      local okT, text, _, finished = pcall(GetQuestLogLeaderBoard, j, e.index)
      if not okT or type(text) ~= "string" then return nil end
      local a, b = text:match("(%d+)%s*/%s*(%d+)")
      if a then return tonumber(a), tonumber(b), finished and true or false end
    end
    if oname then
      for j = 1, n do
        local okT, text = pcall(GetQuestLogLeaderBoard, j, e.index)
        if okT and type(text) == "string" and text:find(oname, 1, true) then return read(j) end
      end
    end
    if oi and nobj == n then return read(oi) end
  end
  return nil
end
ns.LiveCount = LiveCount

-- Where the game itself shows a quest's objective on a map (its blue area), when the quest is in
-- the log: Forever moved some spawns, so the game's own marker wins over the database.
local function GamePOI(qid, map)
  local f = C_QuestLog and C_QuestLog.GetQuestsOnMap
  if not (f and qid and map) then return nil end
  local ok, list = pcall(f, map)
  if not ok or type(list) ~= "table" then return nil end
  for _, q in ipairs(list) do
    if type(q) == "table" and q.questID == qid and not q.isQuestStart then
      local okN, x, y = pcall(function()
        if type(q.x) == "number" and type(q.y) == "number" and q.x > 0 and q.y > 0 then return q.x * 100, q.y * 100 end
      end)
      if okN and x then return math.floor(x * 10 + 0.5) / 10, math.floor(y * 10 + 0.5) / 10 end
    end
  end
end
ns.GamePOI = GamePOI

local function StepPoints(log, st, all)
  local pts, seen = {}, {}
  if st.gate then
    -- a missing check-list quest first: the GPS goes to its giver, then to the entrance
    if not all then
      for _, n in ipairs(st.acts) do
        if n.kind == "h" and n.loc and n.loc.m and not ns.NodeOK(log, n) then
          local k = ns.PKey(n.loc.m, n.loc.x, n.loc.y)
          if not seen[k] then seen[k] = true; table.insert(pts, { n.loc.m, n.loc.x, n.loc.y, n.npc or ns.QName(n.q) }) end
        end
      end
      if #pts > 0 then return pts end
    end
    local d = ns.D[st.gate]
    if d and d.e and d.e.m then table.insert(pts, { d.e.m, d.e.x, d.e.y, ns.DName(st.gate) }) end
    return pts
  end
  for _, n in ipairs(st.acts) do
    if n.loc and n.loc.m and (all or not ns.NodeOK(log, n)) then
      local x, y = n.loc.x, n.loc.y
      if n.kind == "o" then
        local gx, gy = GamePOI(n.q, n.loc.m)
        if gx then x, y = gx, gy end
      end
      local k = ns.PKey(n.loc.m, x, y)
      if not seen[k] then seen[k] = true; table.insert(pts, { n.loc.m, x, y, n.npc or ns.QName(n.q) }) end
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

-- noZone: the card already shows the zone in its "Outside: Mulgore" chip
local function StepTitle(st, noZone)
  if st.gate then return L.GATE_T:format(ns.DName(st.gate)) end
  if st.split then
    local pr = st.parts and st.parts > 1 and ("  (" .. st.part .. "/" .. st.parts .. ")") or ""
    if st.bossIdx == 0 then return L.IN_START .. pr end
    if st.bossIdx == 999 then return L.IN_TRASH .. pr end
    return L.BOSS_STEP:format(st.bossName or "?") .. pr
  end
  if st.ins then
    local dn = ns.DName(st.ins)
    if st.inner then return dn end
    local allOuter = true
    for _, n in ipairs(st.acts) do if n.kind ~= "c" or n.outer == false then allOuter = false end end
    return allOuter and L.INSIDE_OUTER_T:format(dn) or dn
  end
  local names, seen = {}, {}
  for _, n in ipairs(st.acts) do
    local nm = n.npc and n.npc:gsub(",.*$", "")
    if nm and not seen[nm] then seen[nm] = true; table.insert(names, nm) end
  end
  local zone = st.loc and ZoneName(st.loc.m) or ""
  -- every name: the card's title wraps, the list row shows the full title in its tooltip
  local who = table.concat(names, ", ")
  if zone ~= "" and not noZone then return zone .. L.COLON .. who end
  return who
end
ns.StepTitle = StepTitle

-- =====================================================================
--  Fenêtre (design system: header 44, content inset 16, card, footer that sticks to the content)
-- =====================================================================
local KTAG = { a = "TAKE", c = "DO", o = "OUTSIDE", t = "TURNIN", h = "HAVE", i = "ITEM" }
local SLABEL = { none = "S_NONE", on = "S_ON", ready = "S_READY", done = "S_DONE" }
-- a quest's state and a line's kind, each in one token colour (design system 5.5)
local SCOL = { none = T.warn, on = T.fg, ready = T.ok, done = T.ok }   -- "in progress" is neutral; info is the info icon only
local KCOL = { a = T.gold, c = T.fg, o = T.fg, t = T.ok, h = T.fg, i = T.muted }

local HEADER, GAP, CI = 44, 12, 12           -- header, gap between blocks, card padding
local FOOT_H, FOOT_SMALL = 68, 32           -- footer: big button + row of buttons / big button only
local Render

local function num(v) return type(v) == "number" and not (issecretvalue and issecretvalue(v)) and v or nil end
local function ScreenCap() return math.floor((num(UIParent:GetHeight()) or 768) * 0.80) end
local function CardW() return W - 2 * PAD - 2 end      -- inside the card's 1 px edge
local function TextW() return CardW() - 2 * CI end
-- y of the content under the header, with or without the progress row (24) and bar (4)
local function TopBase(hasRoute) return HEADER + 1 + GAP + (hasRoute and (24 + 6 + 4 + GAP) or 0) end
-- The design system (Writs/Style.lua) is required: without it the guide stops with a clear error
-- instead of half-built widgets.
local function SW()
  local S = ns.Writs and ns.Writs.S
  if not S then error("WL Helper: Writs/Style.lua missing") end
  return S
end

-- An HD icon button (header, footer).
local function IconBtn(parent, icon, tip, onClick)
  return SW().IconButton(parent, icon, 28, tip, onClick)
end
-- A labelled button (secondary unless kind says "primary"), never narrower than its words.
local function LabelBtn(parent, label, h, kind, onClick, tip)
  return SW().Button(parent, label, 0, h, kind or "secondary", onClick, tip)
end
local function Pill(parent)
  return SW().Pill(parent)
end

-- A text's size from the type scale (kept when the looks change: ns.ApplyLooks reads fs._size).
local function Size(fs, size) if fs._size ~= size then fs._size = size; ns.SetFont(fs) end end

-- The step's points on the map and the arrow (the big button, the Actions menu, the key binding).
-- Without TomTom, a second press goes to the step's next point.
function ns.PlacePoints()
  if not f then return end
  if ns.GuideOn and not ns.GuideOn() then return end
  local log, st = ns.LogEntries(), Steps()[f.view]; if not st then return end
  local pts = StepPoints(log, st, false)
  if #pts == 0 then pts = StepPoints(log, st, true) end
  local key = f.view
  if f.wpKey == key and not ns.HasTomTom() and #pts > 0 then f.wpIdx = (f.wpIdx % #pts) + 1 else f.wpIdx = 1 end
  f.wpKey = key
  ns.SetPoints(pts, false, f.wpIdx); Render()
end
-- "Guide me to the step": the arrow comes back on if it was turned off
local function GoPoints()
  if WLDTDB.arrow == false then WLDTDB.arrow = true end
  ns.PlacePoints()
end
local function GoBack() if f and f.auto then ns.GoTo(f.auto) end end
local function ScrollTop() if f and f.scroll and f.scroll.ScrollTo then f.scroll:ScrollTo(0, true) end end

function ns.GoTo(i)
  if ns.GuideOn and not ns.GuideOn() then return end
  local n = #Steps()
  if n == 0 then return end
  -- every step done: one more place after the last step, the "route finished" card
  f.view = math.max(1, math.min(RouteFinished() and FinIndex() or n, i))
  ScrollTop()
  if f.menu then f.menu:Hide() end
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

-- log (optional): each objective starts with its live count from the quest log ("3/5", green when done)
local function ObjectiveLines(n, log)
  local q = ns.Q[n.q]; if not q then return {} end
  local lines = {}
  local objs = q.o or {}
  if n.kind == "o" and n.obj then objs = { n.obj } end
  if n.oneObj then objs = { n.oneObj } end
  local pos = {}
  for k, o in ipairs(q.o or {}) do pos[o] = k end
  for _, o in ipairs(objs) do
    local s = (o.c and o.c > 1 and (o.c .. " x ") or "") .. (o.n or "")
    if log then
      local a, b, fin = LiveCount(log, n.q, pos[o], o.n, #(q.o or {}))
      if a and b then
        s = Hex(fin and T.ok or T.fg) .. a .. "/" .. b .. "|r  " .. (o.n or "")
      end
    end
    if o.src and o.src[1] then
      local srcs = {}
      for _, x in ipairs(o.src) do
        table.insert(srcs, x[1] .. ((x[2] and x[2] > 0 and x[2] < 100) and (" " .. math.floor(x[2] + 0.5) .. " %") or ""))
      end
      s = s .. "  " .. Hex(T.muted) .. "(" .. L.TT_DROPS:format(table.concat(srcs, ", ")) .. ")|r"
    end
    if s ~= "" then table.insert(lines, s) end
  end
  return lines
end

-- the game's own icon for each kind of line (quest marks), HD icons for the rest
local KICON = { a = "take", t = "turn", c = "boss", o = "map", h = "take" }
local function SetKindIcon(tex, nd)
  if nd.kind == "i" then
    local id = nd.items and nd.items[1]
    tex:SetVertexColor(1, 1, 1)
    SetIcon(tex, nil, (id and GetItemIcon and GetItemIcon(id)) or "Interface\\Icons\\INV_Misc_Bag_10", true)
    return true
  end
  if not KICON[nd.kind] then return false end
  Icon(tex, KICON[nd.kind])
  return true
end

-- =====================================================================
--  Step list (beside the guide): one dense row per step, the step on screen selected.
-- =====================================================================
local function BuildList()
  local l = CreateFrame("Frame", nil, f)
  l.wlOwned = true
  l:SetWidth(LISTW)
  -- its own height (its rows), top-aligned with the guide
  l:SetPoint("TOPRIGHT", f, "TOPLEFT", -4, 0); l:SetHeight(200)
  ns.Flat(l, T.bg, T.cardEdge)
  l.head = CreateFrame("Frame", nil, l)
  l.head:SetPoint("TOPLEFT"); l.head:SetPoint("TOPRIGHT"); l.head:SetHeight(HEADER)
  l.title = Text(l.head, ns.F.heading, T.fg); l.title:SetPoint("LEFT", 16, 0); l.title:SetPoint("RIGHT", -12, 0); l.title:SetJustifyV("MIDDLE")
  l.title:SetText(L.STEPS)
  ns.ClampLabel(l.title, nil, l.head)
  l.rule = ns.Rule(l, T.line); l.rule:SetPoint("TOPLEFT", 0, -HEADER); l.rule:SetPoint("TOPRIGHT", 0, -HEADER)
  l.rows, l.offset = {}, 0
  for r = 1, LISTROWS do
    local row = CreateFrame("Button", nil, l)
    row:SetHeight(LISTH)
    local y = -(HEADER + 1 + 4 + (r - 1) * LISTH)
    row:SetPoint("TOPLEFT", 4, y); row:SetPoint("TOPRIGHT", -4, y)
    row.sel = Tex(row, "BACKGROUND", T.selFill); row.sel:SetAllPoints(); row.sel:Hide()
    row.hl = Tex(row, "HIGHLIGHT", T.hoverFill); row.hl:SetAllPoints()
    row.press = Tex(row, "ARTWORK", T.pressFill); row.press:SetAllPoints(); row.press:Hide()
    -- done: a check; the current step: a chevron; nothing else (no coloured edge)
    row.check = ns.Icon(row, "check", 14, "OVERLAY", T.ok); row.check:SetPoint("LEFT", 6, 0)
    row.num = Text(row, ns.F.meta, T.muted); row.num:SetPoint("LEFT", 22, 0); row.num:SetWidth(24); row.num:SetJustifyH("RIGHT"); row.num:SetJustifyV("MIDDLE")
    row.kind = row:CreateTexture(nil, "ARTWORK"); row.kind:SetSize(16, 16); row.kind:SetPoint("LEFT", 52, 0)
    row.txt = Text(row, ns.F.label, T.text); row.txt:SetPoint("LEFT", 76, 0); row.txt:SetPoint("RIGHT", -8, 0); row.txt:SetJustifyV("MIDDLE")
    row:SetScript("OnClick", function(self) ns.GoTo(self.i) end)
    row:SetScript("OnMouseDown", function(self) self.press:Show() end)
    row:SetScript("OnMouseUp", function(self) self.press:Hide() end)
    row:SetScript("OnEnter", function(self)
      local st = Steps()[self.i]; if not st then return end
      local lines = { StepTitle(st) }
      if self.state then table.insert(lines, self.state) end
      table.insert(lines, L.TT_LISTROW)
      ns.ShowTip(self, lines)
    end)
    row:SetScript("OnLeave", ns.HideTip)
    -- one line: a long step name shows in full in the row's tooltip
    ns.ClampLabel(row.txt, nil, row)
    l.rows[r] = row
  end
  -- more steps than rows: how many are above / below (the wheel scrolls)
  l.hint = Text(l, ns.F.foot, T.muted); l.hint:SetPoint("BOTTOMLEFT", 16, 8); l.hint:SetPoint("BOTTOMRIGHT", -12, 8)
  l.hint:SetJustifyV("MIDDLE"); l.hint:Hide()
  ns.ClampLabel(l.hint, nil, l)
  l:EnableMouseWheel(true)
  l:SetScript("OnMouseWheel", function(self, delta)
    local max = math.max(0, #Steps() - (self.visible or 1))
    self.offset = math.max(0, math.min(max, self.offset - delta * 3))
    Render()
  end)
  f.list = l
end

local function ListKindIcon(tex, st)
  if st.gate then ns.SetHDIcon(tex, "flag", T.muted)
  elseif st.split and st.bossIdx and st.bossIdx >= 1 and st.bossIdx <= 998 then Icon(tex, "boss")
  elseif st.ins then tex:SetVertexColor(1, 1, 1); ns.SetPainted(tex, (ns.D[st.ins] and ns.D[st.ins].icon) or "Interface\\Icons\\INV_Misc_Map_01")
  else
    local has, itemNode = {}, nil
    for _, nd in ipairs(st.acts) do has[nd.kind] = true; if nd.kind == "i" and not itemNode then itemNode = nd end end
    if has.a then Icon(tex, "take") elseif itemNode then SetKindIcon(tex, itemNode) elseif has.o then Icon(tex, "map") else Icon(tex, "turn") end
  end
end

local function RenderList(log)
  local l = f.list
  if not l:IsShown() then return end
  local steps = Steps()
  -- as many rows as steps, up to what the screen holds (at least 10); the wheel scrolls the rest
  local avail = math.max(10, math.floor((ScreenCap() - (HEADER + 1 + 4) - 8 - 20) / LISTH))
  l.visible = math.max(1, math.min(avail, LISTROWS, #steps))
  local max = math.max(0, #steps - l.visible)
  -- the step on screen stays in the list when it changes (done steps above stay reachable with the wheel)
  if f.view ~= l.lastView then
    l.lastView = f.view
    local v = math.min(f.view or 1, #steps)
    if v <= l.offset then l.offset = math.max(0, v - 2)
    elseif v > l.offset + l.visible then l.offset = v - l.visible + 1 end
  end
  if l.offset > max then l.offset = max end
  if l.offset < 0 then l.offset = 0 end
  if #steps > l.visible then
    l.hint:SetText(L.LIST_MORE:format(l.offset, math.max(0, #steps - l.offset - l.visible))); l.hint:Show()
  else l.hint:Hide() end
  local doneCount = 0
  for k = 1, #steps do if IsStepDone(log, k) then doneCount = doneCount + 1 end end
  l.title:SetText(L.STEPS_N:format(doneCount, #steps))
  l:SetHeight(HEADER + 1 + 4 + l.visible * LISTH + (l.hint:IsShown() and 20 or 0) + 8)
  for r, row in ipairs(l.rows) do
    local i = l.offset + r
    local st = steps[i]
    if st and r <= l.visible then
      row.i = i; row:Show()
      local done = IsStepDone(log, i)
      local cur = (i == f.auto)
      row.num:SetText(i)
      row.txt:SetText(StepTitle(st))
      ListKindIcon(row.kind, st)
      row.kind:SetAlpha(done and 0.45 or 1)
      row.sel:SetShown(i == f.view)
      if done then ns.SetHDIcon(row.check, "check", T.ok); row.check:Show()
      elseif cur then ns.SetHDIcon(row.check, "chevron_right", T.accentSoft); row.check:Show()
      else row.check:Hide() end
      local nc = cur and T.accentSoft or T.muted
      row.num:SetTextColor(nc[1], nc[2], nc[3])
      local tc = (i == f.view) and T.fg or (done and T.muted or T.text)
      row.txt:SetTextColor(tc[1], tc[2], tc[3])
      row.state = done and L.B_DONE or (cur and L.B_CUR) or ((f.auto and i < f.auto) and L.B_LATE) or L.B_NEXT
    else
      row:Hide()
    end
  end
end

-- =====================================================================
--  A line of the step card: icon, kind, quest name, state or NPC, GPS button, detail lines.
-- =====================================================================
local ROW_NAME_X = 100
local function MakeRow(parent)
  local row = CreateFrame("Button", nil, parent)
  row.wpOn = Tex(row, "BACKGROUND", T.selFill); row.wpOn:SetAllPoints(); row.wpOn:Hide()
  row.hl = Tex(row, "HIGHLIGHT", T.hoverFill); row.hl:SetAllPoints()
  row.press = Tex(row, "ARTWORK", T.pressFill); row.press:SetAllPoints(); row.press:Hide()
  row.icon = ns.Icon(row, "check", 16, "ARTWORK", T.ok); row.icon:SetPoint("TOPLEFT", 8, -9)
  row.kicon = row:CreateTexture(nil, "ARTWORK", nil, 1); row.kicon:SetSize(16, 16); row.kicon:SetPoint("TOPLEFT", 8, -9)
  row.tag = Text(row, ns.F.meta, T.muted); row.tag:SetPoint("TOPLEFT", 32, -12); row.tag:SetWidth(ROW_NAME_X - 32 - 6)
  row.name = Text(row, ns.F.body, T.fg); row.name:SetPoint("TOPLEFT", ROW_NAME_X, -10)
  row.npc = Text(row, ns.F.meta, T.muted); row.npc:SetJustifyH("RIGHT")
  row.sub = Text(row, ns.F.meta, T.muted); row.sub:SetPoint("TOPLEFT", ROW_NAME_X, -28); row.sub:SetSpacing(3)   -- placed in Render
  row.sep = ns.Rule(row, T.divider); row.sep:SetPoint("BOTTOMLEFT", 8, 0); row.sep:SetPoint("BOTTOMRIGHT", -8, 0)
  -- the secure buttons (target / item) live in the action bar outside this window, so the window
  -- stays usable in combat. GPS: a secondary button with the pin.
  local gb
  gb = LabelBtn(row, "GPS", 24, "secondary", function(self) local n = self.row.node; if n and n.loc then ns.SetOne(n) end end,
    function()
      local n = gb and gb.row and gb.row.node
      if not (n and n.loc) then return nil end
      return { L.TT_GPS:format(n.npc or ns.QName(n.q), n.loc.x, n.loc.y), L.TT_GPS_CLICK }
    end)
  if gb.SetIcon then gb:SetIcon("pin") end
  gb.row = row
  row.gb = gb
  row:SetScript("OnClick", function(self) local n = self.node; if n and n.loc then ns.SetOne(n) end end)
  row:SetScript("OnMouseDown", function(self) if self.node and self.node.loc then self.press:Show() end end)
  row:SetScript("OnMouseUp", function(self) self.press:Hide() end)
  row:SetScript("OnEnter", function(self) ns.RowTip(self) end)
  row:SetScript("OnLeave", ns.HideTip)
  ns.ClampLabel(row.tag, nil, row)
  ns.ClampLabel(row.npc, nil, row)
  return row
end

function ns.SetOne(n)
  ns.SetPoints({ { n.loc.m, n.loc.x, n.loc.y, n.npc or ns.QName(n.q) } })
  Render()
end

-- A quest line's tooltip: name, facts (muted), the state colours of the design system, the mouse line.
function ns.RowTip(row)
  local n = row.node
  if not n then
    -- a boss header: its name and tip (cut labels first)
    if row.bossName then ns.ShowTip(row, { row.bossName, row.bossTip }) end
    return
  end
  local q = ns.Q[n.q] or {}
  local lines = { ns.QName(n.q) }
  if GetLocale and GetLocale() == "frFR" and q.n then table.insert(lines, q.n)
  elseif ns.lang == "fr" and q.nf then table.insert(lines, q.nf) end
  local kc = KCOL[n.kind] or T.text
  local kt = ({ a = L.TT_TAKE, c = L.TT_DO, o = L.TT_OUT, t = L.TT_TURN, h = L.TT_HAVE, i = L.TT_ITEM })[n.kind]
  if kt then table.insert(lines, { kt, kc[1], kc[2], kc[3] }) end
  if n.pre then table.insert(lines, L.PRE) end
  table.insert(lines, n.ins and L.TT_INSIDE or L.TT_OUTSIDE)
  if q.c then
    for tok in q.c:gmatch("[^,]+") do local cn, cc = ns.ClassInfo(tok); table.insert(lines, { L.CLASSQ:format(cn), cc[1], cc[2], cc[3] }) end
  end
  if n.npc then table.insert(lines, n.npc) end
  if n.loc then table.insert(lines, ("%s  %.1f, %.1f"):format(ZoneName(n.loc.m), n.loc.x, n.loc.y)) end
  local obj = (ns.lang == "fr" and q.of) or ns.T(q.oe)
  if obj then table.insert(lines, { obj, T.text[1], T.text[2], T.text[3] }) end
  for _, s in ipairs(ObjectiveLines(n, ns.LogEntries())) do table.insert(lines, "- " .. s) end
  if q.ne then table.insert(lines, ns.T(q.ne)) end
  for _, r in ipairs(q.req or {}) do
    if r[3] then table.insert(lines, r[1] .. L.COLON .. ns.T(r[3])) end
  end
  if q.si then table.insert(lines, q.si .. (q.sih and (L.COLON .. ns.T(q.sih)) or "")) end
  if q.pi then table.insert(lines, q.pi .. (q.pih and (L.COLON .. ns.T(q.pih)) or "")) end
  local rw = q.rw and q.rw ~= "" and q.rw or nil
  if q.ri and q.ri[1] then rw = (rw and (rw .. " ; ") or "") .. table.concat(q.ri, q.rc and " / " or ", ") end
  if rw then table.insert(lines, { L.TT_REWARD:format(rw), T.gold[1], T.gold[2], T.gold[3] }) end
  if q.xp and q.xp > 0 then table.insert(lines, L.TT_XP:format(q.xp)) end
  local pb = n.kind == "a" and ns.PrereqProblem(n.q)
  if pb then table.insert(lines, { L.BLOCKED:format(pb), T.bad[1], T.bad[2], T.bad[3] }) end
  if q.conf then table.insert(lines, L.TT_CONFLICT) end
  table.insert(lines, n.loc and L.TT_CLICK or (n.ins and L.TT_NOPOINT or L.TT_NOPOINT_UNK))
  ns.ShowTip(row, lines)
end

-- =====================================================================
--  Build
-- =====================================================================
local function Build()
  f = CreateFrame("Frame", "WLDTFrame", UIParent)
  f.wlOwned = true
  f:SetSize(W, 300); f:SetFrameStrata("MEDIUM")
  local pos = WLDTDB.pos
  if pos then f:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4]) else f:SetPoint("RIGHT", -60, 40) end
  f:SetMovable(true); f:EnableMouse(true); f:SetClampedToScreen(true)
  ns.Flat(f, T.bg, T.cardEdge)
  f:SetScript("OnMouseDown", function(self) self:Raise() end)

  -- header: home, logo, title + the route as subtitle, then pick / settings / collapse / close
  local h = CreateFrame("Frame", nil, f)
  h:SetPoint("TOPLEFT", 0, 0); h:SetPoint("TOPRIGHT", 0, 0); h:SetHeight(HEADER)
  h:EnableMouse(true); h:RegisterForDrag("LeftButton")
  h:SetScript("OnMouseDown", function() f:Raise() end)
  h:SetScript("OnDragStart", function() f:StartMoving() end)
  h:SetScript("OnDragStop", function()
    f:StopMovingOrSizing()
    ns.PinTopLeft()
    if ns.UpdateActionBar then ns.UpdateActionBar() end
  end)
  h.rule = ns.Rule(f, T.line); h.rule:SetPoint("TOPLEFT", 0, -HEADER); h.rule:SetPoint("TOPRIGHT", 0, -HEADER)
  local function GoHome()
    local WP = ns.Writs and ns.Writs.WP
    if WP and WP.OpenHome then WP.OpenHome() end
  end
  f.homeBtn = IconBtn(h, "home", { L.HOME, L.TT_HOME }, GoHome)
  f.homeBtn:SetPoint("TOPLEFT", 8, -8)
  h.logo = h:CreateTexture(nil, "ARTWORK"); h.logo:SetSize(28, 28); h.logo:SetPoint("TOPLEFT", 40, -8)
  h.logo:SetTexture(ns.LOGO or ("Interface\\AddOns\\" .. ADDON .. "\\Media\\Logo64"))
  h.title = Text(h, ns.F.title, T.fg); h.title:SetText(L.DUNGEONS)
  h.sub = Text(h, ns.F.meta, T.muted)
  ns.ClampLabel(h.title, nil, h); ns.ClampLabel(h.sub, nil, h)
  f.header = h
  local close = IconBtn(h, "close", function() return { L.TT_HCLOSE, L.TT_HCLOSE2, L.TT_HCLOSE_CLICK } end,
    function() f:Hide(); WLDTDB.hidden = true; ns.SetArrow(nil); if ns.UpdateActionBar then ns.UpdateActionBar() end end)
  close:SetPoint("TOPRIGHT", -8, -8)
  f.closeBtn = close
  f.miniBtn = IconBtn(h, "minus", function()
    if f.mini then return { L.TT_HMAX, L.TT_HMAX_CLICK } end
    return { L.TT_HMIN, L.TT_HMIN_CLICK }
  end, function() f.mini = not f.mini; WLDTDB.mini = f.mini; Render() end)
  f.miniBtn:SetPoint("RIGHT", close, "LEFT", -4, 0)
  f.gearBtn = IconBtn(h, "gear", { L.SETTINGS, L.TT_SETTINGS }, function()
    local WP = ns.Writs and ns.Writs.WP
    if WP and WP.OpenOptions then WP.OpenOptions("dungeons") end
  end)
  f.gearBtn:SetPoint("RIGHT", f.miniBtn, "LEFT", -4, 0)
  f.pickBtn = IconBtn(h, "portal", { L.TT_HPICK, L.TT_PICKBTN }, function() ns.TogglePicker() end)
  f.pickBtn:SetPoint("RIGHT", f.gearBtn, "LEFT", -4, 0)
  -- title and subtitle stop before the four header icons (full text in the header's tooltip)
  function f.LayoutTitle(hasSub)
    h.title:ClearAllPoints(); h.sub:ClearAllPoints()
    local right = -(8 + 4 * 28 + 3 * 4 + 8)
    if hasSub then
      h.title:SetPoint("TOPLEFT", 76, -7); h.title:SetPoint("TOPRIGHT", right, -7)
      h.sub:SetPoint("TOPLEFT", h.title, "BOTTOMLEFT", 0, -2); h.sub:SetPoint("TOPRIGHT", h.title, "BOTTOMRIGHT", 0, -2)
      h.sub:Show()
    else
      h.title:SetPoint("LEFT", h, "LEFT", 76, 0); h.title:SetPoint("RIGHT", h, "RIGHT", right, 0)
      h.sub:Hide()
    end
  end
  f.LayoutTitle(false)

  -- progress: "Step 3 / 26 · 23 left", the percentage, the step list button, a thin bar
  local y0 = HEADER + 1 + GAP
  f.prog = CreateFrame("Frame", nil, f)
  f.prog:SetPoint("TOPLEFT", PAD, -y0); f.prog:SetPoint("TOPRIGHT", -PAD, -y0); f.prog:SetHeight(24)
  f.listToggle = LabelBtn(f.prog, L.LIST, 24, "secondary", function()
    f.list:SetShown(not f.list:IsShown()); WLDTDB.list = f.list:IsShown(); Render()
  end, function() return { L.M_LIST, L.TT_HLIST } end)
  if f.listToggle.SetIcon then f.listToggle:SetIcon("chevron_left") end
  f.listToggle:SetPoint("RIGHT", 0, 0)
  f.progPct = Text(f.prog, ns.F.meta, T.muted); f.progPct:SetPoint("RIGHT", f.listToggle, "LEFT", -12, 0); f.progPct:SetJustifyH("RIGHT"); f.progPct:SetJustifyV("MIDDLE")
  ns.ClampLabel(f.progPct, nil, f.prog)
  f.progLabel = Text(f.prog, ns.F.body, T.text); f.progLabel:SetPoint("LEFT", 0, 0); f.progLabel:SetPoint("RIGHT", f.progPct, "LEFT", -12, 0); f.progLabel:SetJustifyV("MIDDLE")
  ns.ClampLabel(f.progLabel, nil, f.prog)
  local bar = CreateFrame("StatusBar", nil, f)
  bar:SetPoint("TOPLEFT", PAD, -(y0 + 24 + 6)); bar:SetPoint("TOPRIGHT", -PAD, -(y0 + 24 + 6)); bar:SetHeight(4)
  bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
  bar.bg = Tex(bar, "BACKGROUND", T.divider); bar.bg:SetAllPoints()
  bar:SetMinMaxValues(0, 1)
  f.bar = bar

  -- inside a dungeon that is not in the route: one click adds it (Main.lua sets ns.instOffer)
  f.instBtn = LabelBtn(f, "", 28, "secondary", function()
    local k = ns.instOffer; if not k then return end
    ns.instOffer = nil; ns.instIn = k; WLDTDB.sel[k] = true; ns.Assemble(true); f.auto, f.sig = nil, nil; ns.Refresh(true)
    for i, st in ipairs(ns.route and ns.route.steps or {}) do if st.ins == k and not st.gate then ns.GoTo(i) break end end
  end)
  if f.instBtn.SetIcon then f.instBtn:SetIcon("plus") end
  f.instBtn:Hide()

  -- inside one of the route's dungeons: a band above the card says so ("Inside the dungeon: ZF"),
  -- with its icon, where you are in its steps, the quests finished here and the next boss.
  -- A click shows the first open step inside. Leaving the instance hides it.
  local band = CreateFrame("Button", nil, f)
  band:SetHeight(56)
  band.bg = Tex(band, "BACKGROUND", T.cardFill); band.bg:SetAllPoints()
  band.tint = Tex(band, "BACKGROUND", { T.info[1], T.info[2], T.info[3], 0.10 }); band.tint:SetAllPoints()
  band.edge = ns.Outline(band, T.info, 0.4)
  band.hl = Tex(band, "HIGHLIGHT", T.hoverFill); band.hl:SetAllPoints()
  band.icon = band:CreateTexture(nil, "ARTWORK"); band.icon:SetSize(32, 32); band.icon:SetPoint("TOPLEFT", 12, -12)
  band.title = Text(band, ns.F.heading, T.fg); band.title:SetPoint("TOPLEFT", 56, -10)
  band.sub = Text(band, ns.F.meta, T.text); band.sub:SetPoint("TOPLEFT", band.title, "BOTTOMLEFT", 0, -3); band.sub:SetSpacing(3)
  band.chev = ns.Icon(band, "chevron_right", 16, "ARTWORK", T.muted); band.chev:SetPoint("RIGHT", -12, 0)
  band:SetScript("OnClick", function(self) if self.go then ns.GoTo(self.go) end end)
  band:SetScript("OnEnter", function(self) self.chev:SetVertexColor(T.fg[1], T.fg[2], T.fg[3]); ns.ShowTip(self, { self.title:GetText() or "", L.INB_TT, L.INB_BACK }) end)
  band:SetScript("OnLeave", function(self) self.chev:SetVertexColor(T.muted[1], T.muted[2], T.muted[3]); ns.HideTip() end)
  band:Hide()
  f.inBand = band

  -- the step card: card fill, 1 px edge, scrolls inside itself only when the screen is too short
  local holder = CreateFrame("Frame", nil, f)
  ns.Flat(holder, T.cardFill, T.cardEdge)
  local S = SW()
  local sa = S.ScrollArea(holder)
  sa:SetPoint("TOPLEFT", 1, -1); sa:SetPoint("BOTTOMRIGHT", -1, 1)
  local card = sa.child
  card:SetWidth(CardW())
  card.fade = card:CreateAnimationGroup()
  local an = card.fade:CreateAnimation("Alpha"); an:SetFromAlpha(0.4); an:SetToAlpha(1); an:SetDuration(0.15); an:SetSmoothing("OUT")
  f.holder, f.scroll, f.card = holder, sa, card

  -- top line: where the step happens, the class (class quests), and the step's state on the right
  card.where = Pill(card)
  card.clsChip = Pill(card)
  card.badgePill = Pill(card)
  card.badge = card.badgePill.text
  card.zone = card.where.text   -- older name
  -- 3D portrait of the boss (the dungeon journal's model)
  card.modelBg = card:CreateTexture(nil, "BACKGROUND"); card.modelBg:SetColorTexture(0, 0, 0, 0.35)
  card.modelBg:SetSize(76, 76); card.modelBg:Hide()
  card.model = CreateFrame("PlayerModel", nil, card)
  card.model:SetSize(74, 74); card.model:SetPoint("CENTER", card.modelBg, "CENTER"); card.model:Hide()
  -- empty, finished: one centred block (icon 32, title, sentence)
  card.bigIcon = ns.Icon(card, "portal", 32, "ARTWORK", T.muted); card.bigIcon:Hide()
  card.title = Text(card, ns.F.title, T.fg)
  card.travelIcon = ns.Icon(card, "info", 14, "ARTWORK", T.info); card.travelIcon:Hide()
  card.travel = Text(card, ns.F.label, T.text)
  -- check-list status: a banner (tint of its colour, 1 px edge, HD icon) with state, why, what next
  card.readyBox = CreateFrame("Frame", nil, card)
  card.readyBg = Tex(card.readyBox, "BACKGROUND", { T.ok[1], T.ok[2], T.ok[3], 0.16 }); card.readyBg:SetAllPoints()
  card.readyEdge = ns.Outline(card.readyBox, T.ok, 0.4)
  card.readyIcon = ns.Icon(card.readyBox, "check", 16, "ARTWORK", T.ok); card.readyIcon:SetPoint("TOPLEFT", 12, -10)
  card.ready = Text(card.readyBox, ns.F.label, T.fg); card.ready:SetPoint("TOPLEFT", 36, -10); card.ready:SetSpacing(3)
  card.readyBox:Hide()
  card.note = Text(card, ns.F.label, T.text); card.note:SetSpacing(3)
  -- under the rows (check-list: key, entrance, group)
  card.after = Text(card, ns.F.label, T.text); card.after:SetSpacing(3); card.after:Hide()
  card.rows = {}
  for r = 1, MAXROWS do card.rows[r] = MakeRow(card) end
  card.shareBtn = LabelBtn(card, L.SHARE_SHORT, 28, "secondary", function() ns.ShareQuests() end, function() return { L.M_SHARE, L.TT_FSHARE } end)
  if card.shareBtn.SetIcon then card.shareBtn:SetIcon("group") end
  card.shareBtn:Hide()

  -- footer, under the card: the one main action, then previous / next / check-list / actions
  local foot = CreateFrame("Frame", nil, f)
  foot:SetHeight(FOOT_H)
  f.foot = foot
  f.go = LabelBtn(foot, L.GO, 32, "primary", function(self) if self.action then self.action() end end)
  f.prev = IconBtn(foot, "chevron_left", { L.B_PREV, L.TT_PREV_CLICK }, function() ns.GoTo(f.view - 1) end)
  f.prev.edge = ns.Outline(f.prev, T.btnEdge)
  f.prev:SetPoint("BOTTOMLEFT")
  f.moreBtn = LabelBtn(foot, L.MORE_BTN, 28, "secondary", function() f.menu:SetShown(not f.menu:IsShown()) end,
    function() return { L.MORE, L.TT_MORE } end)
  if f.moreBtn.SetIcon then f.moreBtn:SetIcon("chevron_up") end
  f.moreBtn:SetPoint("BOTTOMRIGHT")
  f.next = LabelBtn(foot, L.NEXT2, 28, "secondary", function() ns.GoTo(f.view + 1) end, function() return { L.NEXT2, L.TT_NEXT, L.TT_NEXT_CLICK } end)
  if f.next.SetIcon then f.next:SetIcon("chevron_right") end
  f.next:SetPoint("LEFT", f.prev, "RIGHT", 4, 0)
  -- "Checklist": straight to the before-entering check of the dungeon on screen (quests to take, key).
  -- Its icon tells the state (check = ready, warning = something first); its tooltip says it in words.
  f.readyBtn = LabelBtn(foot, L.B_READY, 28, "secondary", function() if ns.GoReady then ns.GoReady() end end, function()
    local t = { L.B_READY_T, L.TT_READY }
    if f.readyTip then table.insert(t, f.readyTip) end
    table.insert(t, L.TT_READY_CLICK)
    return t
  end)
  if f.readyBtn.SetIcon then f.readyBtn:SetIcon("check") end
  f.readyBtn:SetPoint("RIGHT", f.moreBtn, "LEFT", -4, 0)

  -- the Actions menu: everything that used to be a row of small buttons. Toggles show a check.
  local menu = CreateFrame("Frame", nil, f)
  menu:SetSize(256, 10); menu:SetFrameStrata("FULLSCREEN_DIALOG"); menu:SetToplevel(true); menu:SetPoint("BOTTOMRIGHT", f.moreBtn, "TOPRIGHT", 0, 4)
  ns.Flat(menu, { T.panel[1], T.panel[2], T.panel[3], 0.98 }, T.cardEdge)
  menu:EnableMouse(true); menu:Hide()
  f.menu = menu
  local items = {}
  local function Item(onClick, tip)
    local b = CreateFrame("Button", nil, menu)
    b:SetHeight(24)
    local y = -4 - #items * 24
    b:SetPoint("TOPLEFT", 4, y); b:SetPoint("TOPRIGHT", -4, y)
    b.hl = Tex(b, "HIGHLIGHT", T.hoverFill); b.hl:SetAllPoints()
    b.press = Tex(b, "ARTWORK", T.pressFill); b.press:SetAllPoints(); b.press:Hide()
    b.check = ns.Icon(b, "check", 12, "ARTWORK", T.accentSoft); b.check:SetPoint("LEFT", 8, 0); b.check:Hide()
    b.label = Text(b, ns.F.label, T.fg); b.label:SetPoint("LEFT", 26, 0); b.label:SetPoint("RIGHT", -8, 0); b.label:SetJustifyV("MIDDLE")
    b:SetScript("OnClick", function(...) onClick(...); menu:Hide() end)
    b:SetScript("OnMouseDown", function(self) if self:IsEnabled() ~= false then self.press:Show() end end)
    b:SetScript("OnMouseUp", function(self) self.press:Hide() end)
    b:SetScript("OnEnter", function(self) ns.ShowTip(self, tip()) end)
    b:SetScript("OnLeave", ns.HideTip)
    b:SetScript("OnEnable", function(self) self:SetAlpha(1) end)
    b:SetScript("OnDisable", function(self) self:SetAlpha(T.disabledAlpha) end)
    ns.ClampLabel(b.label, nil, b)
    function b:SetOn(on) self.check:SetShown(on and true or false) end
    items[#items + 1] = b
    menu:SetHeight(8 + #items * 24)
    return b
  end
  f.share = Item(ns.ShareQuests, function() return { L.M_SHARE, L.TT_FSHARE } end)
  f.share.disabledReason = L.NOGROUP_TIP
  f.recalc = Item(function() ns.Recalc() end, function() return { L.M_RECALC, L.RECALC_TT } end)
  f.way = Item(function() ns.PlacePoints() end, function() return { L.M_POINTS, L.TT_FPOINTS } end)
  f.done = Item(function()
    local st = Steps()[f.view]; if not st then return end
    SetManual(st, not Manual(st)); ns.Refresh()
  end, function() return { L.M_SKIP, L.TT_FDONE } end)
  f.arrowBtn = Item(function() ns.ToggleArrow(); Render() end, function() return { L.M_ARROW, L.TT_FARROW } end)
  f.autoBtn = Item(function() WLDTDB.autoWay = not WLDTDB.autoWay; f.sig = nil; ns.Refresh() end, function() return { L.M_AUTO, L.TT_FAUTO } end)
  f.listBtn = Item(function() f.list:SetShown(not f.list:IsShown()); WLDTDB.list = f.list:IsShown(); Render() end, function() return { L.M_LIST, L.TT_HLIST } end)
  f.journal = Item(function() if ns.OpenJournal then ns.OpenJournal() end end, function() return { L.M_JOURNAL, L.TT_JOURNAL } end)
  f.journal.disabledReason = L.NOJOURNAL_TIP
  f:HookScript("OnHide", function() menu:Hide() end)
  -- closes once the mouse has been away from it (and its button) for a moment
  menu:SetScript("OnUpdate", function(self, dt)
    if self:IsMouseOver() or f.moreBtn:IsMouseOver() then self.away = 0; return end
    self.away = (self.away or 0) + dt
    if self.away > 1.5 then self:Hide() end
  end)
  menu:SetScript("OnShow", function(self) self.away = 0 end)

  f.footBig = { f.go }
  f.footSmall = {}

  -- width grip (bottom-right corner): the height always follows the content
  local grip = CreateFrame("Button", nil, f)
  grip:SetSize(16, 16); grip:SetPoint("BOTTOMRIGHT", 0, 0); grip:SetFrameLevel((f:GetFrameLevel() or 1) + 10)
  grip.icon = ns.Icon(grip, "chevron_right", 12, "OVERLAY", T.faint); grip.icon:SetPoint("CENTER", 1, -1)
  if grip.icon.SetRotation then pcall(grip.icon.SetRotation, grip.icon, -math.pi / 4) end
  grip:SetScript("OnEnter", function(self) self.icon:SetVertexColor(T.fg[1], T.fg[2], T.fg[3]); ns.ShowTip(self, { L.TT_RESIZE, L.TT_RESIZE2, L.TT_RESIZE3 }) end)
  grip:SetScript("OnLeave", function(self) self.icon:SetVertexColor(T.faint[1], T.faint[2], T.faint[3]); ns.HideTip() end)
  grip:SetScript("OnMouseDown", function(self)
    ns.PinTopLeft()
    local sc = f:GetEffectiveScale()
    local cx = GetCursorPosition()
    self.start = { cx / sc, W }
    self:SetScript("OnUpdate", function(me)
      local x = GetCursorPosition()
      x = x / sc
      local nw = math.floor(math.max(420, math.min(640, me.start[2] + (x - me.start[1]))))
      if nw ~= W then ns.Relayout(nw); Render() end
    end)
  end)
  grip:SetScript("OnMouseUp", function(self)
    self:SetScript("OnUpdate", nil)
    WLDTDB.size = { W }   -- the width only: the height always follows the content
  end)
  grip:SetScript("OnDoubleClick", function()
    ns.Relayout(W0, CARD0); WLDTDB.size = nil; Render()
  end)
  f.grip = grip

  -- collapsed: one line with the step on screen
  f.miniRow = CreateFrame("Frame", nil, f)
  f.miniRow:SetPoint("TOPLEFT", PAD, -(HEADER + 1 + 8)); f.miniRow:SetPoint("TOPRIGHT", -PAD, -(HEADER + 1 + 8)); f.miniRow:SetHeight(24)
  f.miniText = Text(f.miniRow, ns.F.body, T.fg); f.miniText:SetPoint("LEFT"); f.miniText:SetPoint("RIGHT"); f.miniText:SetJustifyV("MIDDLE")
  ns.ClampLabel(f.miniText, nil, f.miniRow)
  BuildList()
  f:SetScript("OnShow", function() ns.Refresh() end)
  f.mini = WLDTDB.mini
  f.list:SetShown(WLDTDB.list ~= false)
  -- a new frame is visible: closed at first; Main.lua reopens it at login if it was open before.
  -- Every way of opening or closing it (close, Escape, /wlh, home, minimap) is remembered here,
  -- except when the Dungeons module is switched off (ns.quietHide), which is not your choice.
  f:Hide()
  f:HookScript("OnShow", function() WLDTDB.hidden = false end)
  f:HookScript("OnHide", function() if not ns.quietHide then WLDTDB.hidden = true end end)
  ns.frame = f
  if ns.RegisterWindow then ns.RegisterWindow(f) end
  -- older saves kept a card height that capped the card for good: only the width is kept now
  if WLDTDB.size then WLDTDB.size[2] = nil; ns.Relayout(WLDTDB.size[1]) end
  -- Escape closes the guide like every window (OnHide above remembers it)
  tinsert(UISpecialFrames, "WLDTFrame")
end
ns.BuildMain = Build

-- Width of the guide (the grip in the bottom-right corner). The height follows the content;
-- nh caps the card's height when given (the reset only; saves keep the width alone).
function ns.Relayout(nw, nh)
  W = math.max(420, math.min(640, nw or W0))
  if nh then CARD_MAX = math.max(160, nh) end
  if not f then return end
  f:SetWidth(W)
  f.card:SetWidth(CardW())
end

-- =====================================================================
--  Rendu
-- =====================================================================
local function SetSecureRow() end

-- =====================================================================
--  Ordre dans le donjon : objectifs rangés boss par boss, dans l'ordre du journal de donjon
--  (« Partout » en premier pour le butin des monstres). Une ligne par objectif.
-- =====================================================================
-- BossOrder / ObjDone live in Engine.lua (ns.BossOrder, ns.ObjDone).

function ns.StepView(st, log)
  if not st or st.gate or not st.ins or st.split then return st and st.acts or {} end
  local bo = ns.BossOrder(st.ins)
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
          local v = setmetatable({ oneObj = o, firstOfQuest = first, vok = ns.ObjDone(log, nd.q, o) }, { __index = nd })
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
  -- SplitOne leaves a step unsplit only when no boss matched: keep it a plain list then
  local any = false
  for _, it in ipairs(items) do if it.boss > 0 then any = true end end
  if not bo or not any then
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

-- The "inside the dungeon" band: icon, name, where you are in its steps, quests finished here,
-- the next boss. Returns its height (0 = hidden).
function ns.RenderInsideBand(k, log)
  local band = f.inBand
  local d = ns.D[k] or {}
  band.icon:SetVertexColor(1, 1, 1)
  if d.icon then ns.SetPainted(band.icon, d.icon) else ns.SetHDIcon(band.icon, "portal", T.info) end
  band.title:SetText(L.INB_T:format(ns.DName(k) or ""))
  local nIn, doneIn, firstOpen, firstIn, viewPos, openPos, nextBoss = 0, 0, nil, nil, nil, nil, nil
  local qseen, qT, qD = {}, 0, 0
  for i2, s2 in ipairs(Steps()) do
    if s2.ins == k and not s2.gate then
      nIn = nIn + 1; firstIn = firstIn or i2
      if i2 == f.view then viewPos = nIn end
      if IsStepDone(log, i2) then doneIn = doneIn + 1
      else
        if not firstOpen then firstOpen = i2; openPos = nIn end
        if not nextBoss and s2.split and s2.bossName and s2.bossIdx and s2.bossIdx >= 1 and s2.bossIdx <= 998 then nextBoss = s2.bossName end
      end
      for _, nd in ipairs(s2.acts) do
        if nd.q and nd.q > 0 and not qseen[nd.q] and (nd.kind == "a" or nd.kind == "c" or nd.kind == "t") then
          qseen[nd.q] = true; qT = qT + 1
          local s = ns.State(log, nd.q)
          if s == "ready" or s == "done" then qD = qD + 1 end
        end
      end
    end
  end
  if nIn == 0 then band:Hide() return 0 end
  local lines = {}
  if doneIn == nIn then
    table.insert(lines, Hex(T.ok) .. L.INB_DONE .. "|r")
  else
    table.insert(lines, L.INB_STEP:format(viewPos or openPos or 1, nIn) .. "  " .. Hex(T.muted) .. "·|r  " .. L.INB_Q:format(qD, qT))
    if nextBoss then table.insert(lines, L.INB_BOSS:format(nextBoss)) end
    if not viewPos then table.insert(lines, Hex(T.accentSoft) .. L.INB_BACK .. "|r") end
  end
  band.sub:SetText(table.concat(lines, "\n"))
  band.go = firstOpen or firstIn
  band:Show()
  local tw = (W - 2 * PAD) - 56 - 36
  local th = ns.FitText(band.title, 2, tw, band)
  local sh = ns.FitText(band.sub, 0, tw, band)
  local h = math.max(56, math.ceil(10 + th + 3 + sh + 10))
  band:SetHeight(h)
  return h
end

-- The footer's "Checklist" button: its icon says the state of the check-list it opens
-- (check = ready, warning = quests to take or no key); its tooltip says it in words.
function ns.RenderReadyBtn(log)
  local b = f.readyBtn
  b:SetText(L.B_READY)
  local ti = ReadyTarget()
  local st = ti and Steps()[ti]
  if not st then
    b:SetEnabled(false); if b.SetIcon then b:SetIcon("check") end
    b.disabledReason = L.NO_READY
    f.readyTip = { L.NO_READY, T.muted[1], T.muted[2], T.muted[3] }
    return
  end
  b:SetEnabled(true)
  local miss, _, keyMissing = ReadyState(log, st)
  local dn = ns.DName(st.gate) or ""
  if miss == 0 and not keyMissing then
    if b.SetIcon then b:SetIcon("check") end
    f.readyTip = { L.TT_READY_OK:format(dn), T.ok[1], T.ok[2], T.ok[3] }
  elseif miss == 0 then
    if b.SetIcon then b:SetIcon("warning") end
    f.readyTip = { L.TT_READY_KEY:format(dn), T.warn[1], T.warn[2], T.warn[3] }
  else
    if b.SetIcon then b:SetIcon("warning") end
    f.readyTip = { ns.Plural(miss, "TT_READY_MISS1", "TT_READY_MISS", dn, miss), T.warn[1], T.warn[2], T.warn[3] }
  end
end

-- Footer: the big button on its own line, then previous / next / checklist / actions.
local function LayoutFoot(full, centred)
  local CW = W - 2 * PAD
  f.go:ClearAllPoints()
  if centred then
    f.go:SetPoint("TOP", f.foot, "TOP", 0, 0); f.go:SetWidth(0)
  else
    f.go:SetPoint("TOPLEFT", f.foot, "TOPLEFT", 0, 0); f.go:SetWidth(CW)
  end
  for _, b in ipairs({ f.prev, f.next, f.readyBtn, f.moreBtn }) do b:SetShown(full) end
  if full then
    local rw, mw = num(f.readyBtn:GetWidth()) or 100, num(f.moreBtn:GetWidth()) or 90
    f.next:SetWidth(math.max(80, CW - 28 - rw - mw - 12))
  end
  local fh = full and FOOT_H or FOOT_SMALL
  f.foot:SetHeight(fh)
  return fh
end

-- The card's height, the footer under it, the window's height: never taller than the content.
local function FitGuide(TOP, contentH, footH)
  local holder = f.holder
  local cap = math.max(120, math.min(CARD_MAX, ScreenCap() - TOP - GAP - footH - PAD))
  local hh = math.min(math.ceil(contentH), cap)
  holder:ClearAllPoints(); holder:SetPoint("TOPLEFT", PAD, -TOP); holder:SetPoint("TOPRIGHT", -PAD, -TOP)
  holder:SetHeight(hh + 2)
  f.card:SetWidth(CardW())
  f.card:SetHeight(contentH)
  f.scroll:SetContentHeight(contentH)
  f.foot:ClearAllPoints()
  f.foot:SetPoint("TOPLEFT", holder, "BOTTOMLEFT", 0, -GAP); f.foot:SetPoint("TOPRIGHT", holder, "BOTTOMRIGHT", 0, -GAP)
  f:SetHeight(TOP + hh + 2 + GAP + footH + PAD)
end

local function HideStepParts(card)
  card.where:Hide(); card.clsChip:Hide(); card.badgePill:Hide()
  card.travel:Hide(); card.travelIcon:Hide(); card.readyBox:Hide(); card.after:Hide(); card.shareBtn:Hide()
  card.model:Hide(); card.modelBg:Hide()
  for _, row in ipairs(card.rows) do row.node = nil; row:Hide() end
end

-- An empty or finished card: one centred block (icon, title, sentence); returns its height.
local function CentredBlock(card, icon, color, title, text)
  local w = math.min(320, TextW())
  card.bigIcon:ClearAllPoints(); card.bigIcon:SetPoint("TOP", card, "TOP", 0, -24)
  ns.SetHDIcon(card.bigIcon, icon, color); card.bigIcon:Show()
  Size(card.title, ns.F.heading); card.title:SetJustifyH("CENTER")
  card.title:SetText(title)
  card.title:ClearAllPoints(); card.title:SetPoint("TOP", card, "TOP", 0, -(24 + 32 + 8))
  local y = 24 + 32 + 8 + ns.FitText(card.title, 2, w, card)
  card.note:SetJustifyH("CENTER"); card.note:SetTextColor(T.muted[1], T.muted[2], T.muted[3])
  card.note:SetText(text or "")
  if text and text ~= "" then
    card.note:ClearAllPoints(); card.note:SetPoint("TOP", card, "TOP", 0, -(y + 4)); card.note:Show()
    y = y + 4 + ns.FitText(card.note, 0, w, card)
  else card.note:Hide() end
  return y + 24
end

Render = function()
  if not f then return end
  f.pending = false
  local log = ns.LogEntries()
  local steps = Steps()
  local h = f.header
  h.title:SetText(L.DUNGEONS)
  local sub = ns.route and ns.route.label or ""
  h.sub:SetText(sub); f.LayoutTitle(sub ~= "")
  if f.miniBtn.SetIcon then f.miniBtn:SetIcon(f.mini and "plus" or "minus") end
  f:SetWidth(W)
  local card = f.card
  local TW = TextW()
  card.bigIcon:Hide()
  Size(card.title, ns.F.title); card.title:SetJustifyH("LEFT")
  card.note:SetJustifyH("LEFT"); card.note:SetTextColor(T.text[1], T.text[2], T.text[3])
  local hasRoute = #steps > 0
  -- inside a dungeon that is not in the route: a button above the card adds it
  local offerKey = ns.instOffer
  local offer = offerKey and ns.InstLeft and not f.mini and hasRoute
  -- inside one of the route's dungeons: the "inside the dungeon" band (takes the offer's place)
  local inKey = (hasRoute and not f.mini) and InsideKey() or nil
  if inKey then offer = false end
  local bandH = inKey and ns.RenderInsideBand(inKey, log) or 0
  local TOP = TopBase(hasRoute)
  if offer then
    local nLeft = ns.InstLeft(offerKey)
    f.instBtn:SetText(ns.Plural(nLeft, "INST_ADD1", "INST_ADD", ns.DName(offerKey), nLeft))
    f.instBtn:ClearAllPoints(); f.instBtn:SetPoint("TOPLEFT", PAD, -TOP); f.instBtn:SetWidth(W - 2 * PAD); f.instBtn:Show()
    TOP = TOP + 28 + 8
  else f.instBtn:Hide() end
  if bandH > 0 then
    f.inBand:ClearAllPoints(); f.inBand:SetPoint("TOPLEFT", PAD, -TOP); f.inBand:SetPoint("TOPRIGHT", -PAD, -TOP)
    TOP = TOP + bandH + 8
  else f.inBand:Hide() end
  f.prog:SetShown(hasRoute and not f.mini); f.bar:SetShown(hasRoute)
  f.listToggle:SetText(L.LIST)
  if f.listToggle.SetIcon then f.listToggle:SetIcon(f.list:IsShown() and "chevron_right" or "chevron_left") end

  if not hasRoute then
    -- no route yet: what is missing, why, and the one action (centred under the block)
    f.miniRow:Hide(); f.holder:Show(); f.foot:Show()
    HideStepParts(card)
    local title, text = L.NOROUTE_T2, L.NOROUTE_TXT
    f.go:SetText(L.PICK_FIRST); if f.go.SetIcon then f.go:SetIcon("portal") end
    f.go.action = ns.ShowPicker; f.go:SetEnabled(true)
    if offerKey and ns.InstLeft then
      -- no route, but you stand in a dungeon with quests: start its guide in one click
      local name, nLeft = ns.DName(offerKey), ns.InstLeft(offerKey)
      title, text = L.INST_T:format(name), ns.Plural(nLeft, "INST_TXT1", "INST_TXT", nLeft)
      f.go:SetText(L.INST_GO); if f.go.SetIcon then f.go:SetIcon("plus") end
      f.go.action = function()
        local kk = ns.instOffer; if not kk then return end
        for k2 in pairs(WLDTDB.sel) do WLDTDB.sel[k2] = nil end; WLDTDB.sel[kk] = true; ns.instOffer = nil; ns.instIn = kk; ns.StartGuide()
      end
    end
    local ch = CentredBlock(card, "portal", T.muted, title, text)
    for _, b in ipairs({ f.prev, f.next, f.moreBtn, f.readyBtn }) do b:SetEnabled(false) end
    f.readyTip = nil
    f.menu:Hide()
    f.list:Hide()
    FitGuide(TOP, ch, LayoutFoot(false, true))
    ns.UpdateActionBar()
    return
  end

  -- the "route finished" card is one place after the last step (only once every step is done)
  f.view = math.max(1, math.min(RouteFinished() and FinIndex() or #steps, f.view or 1))
  local i = f.view
  local st = steps[i]
  local done = IsStepDone(log, i)
  local n, total = 0, #steps
  for k = 1, #steps do if IsStepDone(log, k) then n = n + 1 end end
  f.bar:SetValue(total > 0 and n / total or 0)
  f.bar:SetStatusBarColor(T.ok[1], T.ok[2], T.ok[3])
  -- the route's names are already in the header: the step and what is left
  f.progLabel:SetText(L.STEP_LEFT:format(math.min(i, total), total, total - n))
  f.progPct:SetText(L.PCT:format(total > 0 and math.floor(n / total * 100 + 0.5) or 0))
  -- every step done and the card after the last step on screen: the "route finished" card
  -- (previous and the step list still show every step, done ones included)
  local finished = total > 0 and n == total and (st == nil)
  if not st and not finished then f.view = total; i = total; st = steps[i]; done = IsStepDone(log, i) end

  if f.mini then
    f.menu:Hide()
    f.holder:Hide(); f.foot:Hide(); f.prog:Hide(); f.list:Hide(); f.instBtn:Hide(); f.inBand:Hide()
    if finished then f.miniText:SetText(Hex(T.ok) .. L.FIN_T .. "|r")
    else f.miniText:SetText(("%s%d.|r %s"):format(Hex(T.muted), i, StepTitle(st))) end
    f.miniRow:Show()
    f.bar:ClearAllPoints(); f.bar:SetPoint("BOTTOMLEFT", 1, 1); f.bar:SetPoint("BOTTOMRIGHT", -1, 1); f.bar:SetHeight(2)
    f:SetHeight(HEADER + 1 + 8 + 24 + 8 + 2)
    ns.UpdateActionBar()
    return
  end
  f.miniRow:Hide(); f.holder:Show(); f.foot:Show(); f.prog:Show()
  f.bar:ClearAllPoints()
  f.bar:SetPoint("TOPLEFT", PAD, -(HEADER + 1 + GAP + 24 + 6)); f.bar:SetPoint("TOPRIGHT", -PAD, -(HEADER + 1 + GAP + 24 + 6)); f.bar:SetHeight(4)
  f.list:SetShown(WLDTDB.list ~= false)

  if finished then
    f.progLabel:SetText(ns.Plural(#steps, "FIN_PROG1", "FIN_PROG", #steps)); f.progPct:SetText(L.PCT:format(100))
    f.bar:SetValue(1)
    HideStepParts(card)
    local ch = CentredBlock(card, "check", T.ok, L.FIN_T, L.FIN_TXT:format(ns.route.label or ""))
    ScrollTop()
    f.menu:Hide()
    f.prev:SetEnabled(true); f.next:SetEnabled(false); f.moreBtn:SetEnabled(true)
    ns.RenderReadyBtn(log)
    f.go:SetText(L.PICK_MORE); if f.go.SetIcon then f.go:SetIcon("portal") end
    f.go.action = ns.ShowPicker; f.go:SetEnabled(true)
    FitGuide(TOP, ch, LayoutFoot(true, false))
    WLDTDB.view = i
    RenderList(log)
    ns.UpdateActionBar()
    return
  end

  local dkey = st.d or st.gate or st.ins
  -- top line: state pill on the right, where (and class) on the left
  if done then card.badgePill:Set(L.B_DONE, T.ok, "check")
  elseif i == f.auto then card.badgePill:Set(L.B_CUR, T.accentSoft)
  elseif f.auto and i < f.auto then card.badgePill:Set(L.B_LATE, T.warn)
  else card.badgePill:Set(L.B_NEXT, T.fg) end
  card.badgePill:ClearAllPoints(); card.badgePill:SetPoint("TOPRIGHT", card, "TOPRIGHT", -CI, -CI)

  local hasModel = false
  if st.bossModel and card.model.SetDisplayInfo then
    if card.modelShown == st.bossModel then hasModel = true
    else
      hasModel = pcall(card.model.SetDisplayInfo, card.model, st.bossModel)
      card.modelShown = hasModel and st.bossModel or nil
    end
    if hasModel and card.model.SetPortraitZoom then pcall(card.model.SetPortraitZoom, card.model, 0.85) end
  end
  -- room for the pills: the text width minus the state pill
  local avail = TW - (num(card.badgePill:GetWidth()) or 60) - 8
  local dn = ns.DName(dkey) or ""
  card.where:Show()
  if st.gate then
    -- the title already says "Before entering X": the pill gives the entrance's zone, or nothing
    local zn = (st.loc and ZoneName(st.loc.m)) or ""
    if zn ~= "" then card.where:Set(L.OUT:format(zn), T.fg) else card.where:Hide() end
  elseif st.ins then
    local allOuter = true
    for _, nd in ipairs(st.acts) do if nd.kind ~= "c" or nd.outer == false then allOuter = false end end
    if allOuter then card.where:Set(L.OUTER:format(dn), T.fg) else card.where:Set(L.IN_DUNGEON:format(dn), T.info, "portal") end
  else
    card.where:Set(L.OUT:format((st.loc and ZoneName(st.loc.m)) or ""), T.fg)
  end
  card.where:ClearAllPoints(); card.where:SetPoint("TOPLEFT", card, "TOPLEFT", CI, -CI)
  local cls
  local allCls = #st.acts > 0
  for _, nd in ipairs(st.acts) do local q = ns.Q[nd.q]; if not (q and q.c) then allCls = false else cls = q.c end end
  card.clsChip:Hide()
  if allCls and cls then
    local tok = cls:match("^[^,]+"); local cn, cc = ns.ClassInfo(tok)
    card.clsChip:Set(ns.ClassIconText(tok, 12) .. L.CLASSQ:format(cn), cc)
    card.clsChip:ClearAllPoints(); card.clsChip:SetPoint("LEFT", card.where, "RIGHT", 6, 0)
    -- no room on the line: the class goes into the rows' detail lines instead (never cut)
    if (num(card.where:GetWidth()) or 0) + 6 + (num(card.clsChip:GetWidth()) or 0) > avail then card.clsChip:Hide() end
  end
  local y = CI + 18 + 8

  card.model:SetShown(hasModel); card.modelBg:SetShown(hasModel)
  if hasModel then card.modelBg:ClearAllPoints(); card.modelBg:SetPoint("TOPRIGHT", card, "TOPRIGHT", -CI, -y) end
  card.title:SetText(StepTitle(st, not st.gate and not st.ins))
  card.title:ClearAllPoints(); card.title:SetPoint("TOPLEFT", card, "TOPLEFT", CI, -y)
  y = y + ns.FitText(card.title, 0, hasModel and (TW - 84) or TW, card)
  if hasModel then y = math.max(y, CI + 18 + 8 + 76) end

  -- the check-list "before entering": a banner (state, why, what next).
  -- Inside the dungeon it is over: the "inside the dungeon" band above the card takes its place.
  local checks = st.checks
  local isCL = checks and #checks > 0 and not (st.ins and InInstanceOf(st.ins))
  -- every quest but no key: the banner says it, the key section then skips its own warning
  local readyNoKey, clMiss, clTotal = false, 0, 0
  local clDn = ns.DName(st.gate or st.ins) or ""
  if isCL then
    local miss, tot, keyMissing = ReadyState(log, st)
    clMiss, clTotal = miss, tot
    local head, why, nxt, col, icon
    if miss == 0 and not keyMissing then
      head, why, nxt, col, icon = L.CL_OK_H:format(clDn), L.CL_OK_T, L.CL_OK_NEXT, T.ok, "check"
    elseif miss == 0 then
      readyNoKey = true
      head, why, nxt, col, icon = L.CL_KEY_H, L.CL_KEY_T:format(clDn), L.CL_KEY_NEXT, T.warn, "warning"
    else
      head = (miss == 1) and L.CL_MISS_H1 or L.CL_MISS_HN:format(miss)
      why, nxt, col, icon = L.CL_MISS_T:format(clDn), L.CL_MISS_NEXT, T.warn, "warning"
    end
    card.readyBg:SetColorTexture(col[1], col[2], col[3], 0.16); card.readyEdge(col, 0.4)
    ns.SetHDIcon(card.readyIcon, icon, col)
    card.ready:SetText(Hex(T.fg) .. head .. "|r\n" .. Hex(T.text) .. why .. "|r\n" .. Hex(T.muted) .. nxt .. "|r")
    card.ready:Show(); card.readyIcon:Show()
  else card.ready:Hide(); card.readyIcon:Hide(); card.readyBox:Hide() end

  card.travelIcon:Hide()
  if done and f.auto and i ~= f.auto then
    -- a finished step looked at again: say so (the big button goes back to the current one)
    card.travel:SetText(L.DONE_VIEW); card.travel:SetTextColor(T.text[1], T.text[2], T.text[3])
    ns.SetHDIcon(card.travelIcon, "check", T.ok)
  elseif st.travel then
    card.travel:SetText(L[st.travel]); card.travel:SetTextColor(T.text[1], T.text[2], T.text[3])
    ns.SetHDIcon(card.travelIcon, "info", T.info)
  else card.travel:SetText("") end
  if card.travel:GetText() and card.travel:GetText() ~= "" then
    y = y + 8
    card.travelIcon:ClearAllPoints(); card.travelIcon:SetPoint("TOPLEFT", card, "TOPLEFT", CI, -(y + 1)); card.travelIcon:Show()
    card.travel:ClearAllPoints(); card.travel:SetPoint("TOPLEFT", card, "TOPLEFT", CI + 20, -y); card.travel:Show()
    y = y + ns.FitText(card.travel, 0, TW - 20, card)
  else card.travel:Hide() end
  if card.ready:IsShown() then
    y = y + GAP
    card.readyBox:ClearAllPoints(); card.readyBox:SetPoint("TOPLEFT", card, "TOPLEFT", CI, -y); card.readyBox:SetWidth(TW)
    local rh = ns.FitText(card.ready, 0, TW - 36 - 12, card.readyBox)
    local boxH = math.ceil(10 + math.max(16, rh) + 10)
    card.readyBox:SetHeight(boxH); card.readyBox:Show()
    y = y + boxH
  end
  card.shareBtn:Hide()
  local note, after
  -- grouped at a gate: the "Group" block under the rows ends with the share button
  local shareAfter = st.gate and IsInGroup() and true or false
  local H1 = Hex(T.fg)
  if st.gate then
    -- the quests counter over the rows (the footer button's tooltip says what the check-list
    -- checks), then key / entrance / group under them
    note = H1 .. L.CL_QUESTS:format(clTotal - clMiss, clTotal) .. "|r"
    local parts = {}
    local kl = ns.KeyLines and ns.KeyLines(st.gate) or {}
    if #kl > 0 then
      local t, warn = {}, false
      for _, k in ipairs(kl) do table.insert(t, k[1]); if k[3] and not k[2] then warn = true end end
      if warn and not readyNoKey then table.insert(t, Hex(T.warn) .. L.KEY_WARN .. "|r") end
      table.insert(parts, H1 .. L.CL_KEY .. "|r\n" .. table.concat(t, "\n"))
    end
    local d = ns.D[st.gate]
    if d and d.ed then table.insert(parts, H1 .. L.CL_ENTRY .. "|r\n" .. ns.T(d.ed)) end
    -- in a group: the header, then the share button; alone: why sharing waits
    table.insert(parts, H1 .. L.CL_GROUP .. "|r" .. (shareAfter and "" or ("\n" .. L.GATE_N)))
    after = table.concat(parts, "\n\n")
  end
  if st.split then
    -- a tip, then "on the way" as a list
    local blocks = {}
    local tips = ns.STEP_TIPS and ns.STEP_TIPS[st.ins]
    local mine = tips and tips[(st.bossIdx == 0 and "*start") or (st.bossIdx == 999 and "*trash") or st.bossEn or ""]
    local tipLines = {}
    if mine then table.insert(tipLines, ns.T(mine[1])) end
    if st.bossTip then table.insert(tipLines, Hex(T.muted) .. st.bossTip .. "|r") end
    if #tipLines > 0 then table.insert(blocks, H1 .. L.H_TIP .. "|r\n" .. table.concat(tipLines, "\n\n")) end
    if st.trash then
      local names, seen = {}, {}
      for _, nd in ipairs(st.trash) do
        if not ns.NodeOK(log, nd) then
          local o = nd.oneObj
          local nm = o and ((o.c and o.c > 1 and (o.c .. " x ") or "") .. (o.n or "")) or ns.QName(nd.q)
          if nm ~= "" and not seen[nm] then seen[nm] = true; table.insert(names, "-  " .. nm) end
        end
      end
      if #names > 0 then table.insert(blocks, H1 .. L.H_ALSO .. "|r\n" .. table.concat(names, "\n")) end
    end
    if #blocks > 0 then note = table.concat(blocks, "\n\n") end
  end
  if note then
    y = y + GAP
    card.note:ClearAllPoints(); card.note:SetPoint("TOPLEFT", card, "TOPLEFT", CI, -y); card.note:SetText(note); card.note:Show()
    y = y + ns.FitText(card.note, 0, TW, card)
  else card.note:Hide() end
  y = y + 8

  local rowW = CardW() - 8
  local subW = rowW - ROW_NAME_X - 12
  local view = ns.StepView(st, log)
  local mt = Hex(T.muted)
  for r, row in ipairs(card.rows) do
    local nd = view[r]
    row:SetWidth(rowW)
    if nd and nd.kind == "b" then
      -- boss header: skull, "Boss 2", the boss, "Done" once every line under it is done
      row.node = nil
      row.bossName = nd.bossIdx > 0 and nd.bossName or L.ALLDUNGEON
      row.bossTip = nd.tip
      row.tag:SetText(nd.bossIdx > 0 and L.BOSS_N:format(nd.bossIdx) or L.ALLDUNGEON_T); row.tag:SetTextColor(T.muted[1], T.muted[2], T.muted[3])
      row.name:SetText(row.bossName)
      local nc = nd.allOk and T.muted or T.fg
      row.name:SetTextColor(nc[1], nc[2], nc[3])
      row.npc:SetText(nd.allOk and (Hex(T.ok) .. L.S_DONE .. "|r") or "")
      row.npc:ClearAllPoints(); row.npc:SetPoint("TOPRIGHT", row, "TOPRIGHT", -12, -12)
      local npcW = math.min((num(row.npc:GetStringWidth()) or 0) + 2, 140)
      row.npc:SetWidth(npcW)
      row.gb:Hide(); row.wpOn:Hide(); row.icon:Hide()
      if nd.bossIdx > 0 then Icon(row.kicon, "boss") else ns.SetHDIcon(row.kicon, "flag", T.muted) end
      row.kicon:SetAlpha(nd.allOk and 0.5 or 1); row.kicon:Show()
      local nameH = ns.FitText(row.name, 2, math.max(80, rowW - ROW_NAME_X - 12 - npcW - 8), row)
      local sub = (not nd.allOk and nd.tip) and nd.tip or ""
      row.sub:SetText(sub); row.sub:SetShown(sub ~= "")
      local subTop = 10 + nameH + 3
      row.sub:ClearAllPoints(); row.sub:SetPoint("TOPLEFT", row, "TOPLEFT", ROW_NAME_X, -subTop)
      local subH = (sub ~= "") and (ns.FitText(row.sub, 0, subW, row)) or 0
      local rh = math.max(36, math.ceil(subTop + subH + 8))
      row:SetHeight(rh); row:ClearAllPoints(); row:SetPoint("TOPLEFT", card, "TOPLEFT", 4, -y)
      y = y + rh
      row:Show()
    elseif nd then
      row.node = nd; row.bossName = nil
      local q = ns.Q[nd.q] or {}
      local s = ns.State(log, nd.q)
      local ok = (nd.vok ~= nil) and nd.vok or ns.NodeOK(log, nd)
      local kc = KCOL[nd.kind] or T.text
      row.tag:SetText(L[KTAG[nd.kind]] or ""); row.tag:SetTextColor(kc[1], kc[2], kc[3])
      row.name:SetText(nd.label or ns.QName(nd.q))
      -- the NPC on the right, unless the step's title already names it (then the quest's state);
      -- a check-list row keeps its state ("To take"): its detail line already names the giver
      local npcShort = nd.npc and not nd.ins and nd.kind ~= "h" and nd.npc:gsub(",.*$", "")
      local title = card.title:GetText() or ""
      if npcShort and title:find(npcShort, 1, true) then npcShort = nil end
      local sc = SCOL[s] or T.muted
      local right = npcShort or (Hex(sc) .. L[SLABEL[s] or "S_NONE"] .. "|r")
      -- check-list row: plainly "In your log" (green) or "To take" (orange)
      if nd.kind == "h" then right = ok and (Hex(T.ok) .. L.CL_HAVE .. "|r") or (Hex(T.warn) .. L.CL_TAKE .. "|r") end
      row.npc:SetText(right)
      SetSecureRow(row, nd, ok)
      row.gb:SetShown(nd.loc ~= nil)
      local isActive = nd.loc and ns.active[ns.PKey(nd.loc.m, nd.loc.x, nd.loc.y)] and not ok
      row.wpOn:SetShown(isActive and true or false)
      local x = -12
      if nd.loc then
        -- followed: the row is selected and the button says so
        row.gb:SetText(isActive and (L.GPS_ON or "GPS") or "GPS")
        row.gb:ClearAllPoints(); row.gb:SetPoint("TOPRIGHT", row, "TOPRIGHT", x, -5)
        x = x - (num(row.gb:GetWidth()) or 60) - 8
      end
      row.npc:ClearAllPoints(); row.npc:SetPoint("TOPRIGHT", row, "TOPRIGHT", x, -12)
      -- the name keeps 120 px at least; the NPC (or state) gets what is left, up to 140 px, and
      -- goes to the start of the detail lines when less than 60 px would remain for it
      local room = rowW - ROW_NAME_X + x - 8
      local npcW = math.min((num(row.npc:GetStringWidth()) or 0) + 2, 140, math.max(0, room - 120))
      local npcInSub = (right ~= "" and npcW < 60) and right or nil
      row.npc:SetShown(not npcInSub)
      if npcInSub then npcW = 0 end
      row.npc:SetWidth(math.max(1, npcW))
      local nameW = math.max(40, room - npcW)
      if ok then
        row.icon:Show(); row.kicon:Hide(); row.name:SetTextColor(T.muted[1], T.muted[2], T.muted[3]); row.tag:SetAlpha(0.5)
      else
        row.icon:Hide()
        row.kicon:SetAlpha(1)
        row.kicon:SetShown(SetKindIcon(row.kicon, nd))
        row.name:SetTextColor(T.fg[1], T.fg[2], T.fg[3]); row.tag:SetAlpha(1)
      end
      -- detail lines
      local parts = {}
      local tags = {}
      if nd.d and nd.d ~= dkey then table.insert(tags, mt .. ns.DName(nd.d) .. "|r") end
      if nd.pre then table.insert(tags, mt .. L.PRE .. "|r") end
      -- the class, unless the card's "Class quest" pill already says it
      if q.c and not card.clsChip:IsShown() then
        local tok = q.c:match("^[^,]+"); local cn, cc = ns.ClassInfo(tok)
        table.insert(tags, ns.ClassIconText(tok, 12) .. Hex(cc) .. L.CLASS_TAG:format(cn) .. "|r")
      end
      if #tags > 0 then table.insert(parts, table.concat(tags, mt .. "  ·  |r")) end
      local tx = Hex(T.text)
      if not ok then
        if nd.kind == "a" and s == "none" then
          local pb = ns.PrereqProblem(nd.q)
          if pb then table.insert(parts, Hex(T.bad) .. L.BLOCKED:format(pb) .. "|r") end
        end
        if nd.kind == "h" then
          local A = q.s and q.s.n or q.st
          if A then table.insert(parts, tx .. L.GIVER:format(A) .. "|r") end
        elseif nd.kind ~= "t" then
          local obj = (ns.lang == "fr" and q.of) or ns.T(q.oe)
          local lines = (nd.kind == "c" or nd.kind == "o") and ObjectiveLines(nd, log) or {}
          if obj and (nd.kind == "a" or #lines == 0) then table.insert(parts, tx .. obj .. "|r") end
          if nd.kind == "c" or nd.kind == "o" then
            for _, l2 in ipairs(lines) do table.insert(parts, tx .. "- " .. l2 .. "|r") end
          end
          if nd.kind == "a" and q.si then table.insert(parts, q.si .. (q.sih and (L.COLON .. ns.T(q.sih)) or "")) end
          if q.ne and (nd.firstOfQuest ~= false) and (nd.kind == "c" or nd.kind == "o" or (nd.kind == "a" and not q.o)) then table.insert(parts, ns.T(q.ne)) end
          if nd.extra then table.insert(parts, nd.extra) end
          if nd.kind == "c" and ns.BossLines and not nd.oneObj then
            for _, bl in ipairs(ns.BossLines(nd.q) or {}) do
              table.insert(parts, tx .. L.BOSS .. L.COLON .. bl[1] .. "|r" .. (bl[2] and ("  " .. bl[2]) or ""))
            end
          end
        end
        if nd.kind == "t" and s == "on" then
          -- quest not finished yet when it is time to turn it in: what is left to do
          local obj = (ns.lang == "fr" and q.of) or ns.T(q.oe)
          if obj then table.insert(parts, tx .. obj .. "|r") end
        end
        if (nd.kind == "t" and s == "on") or (nd.kind == "c" and #ObjectiveLines(nd) == 0) then
          for _, r2 in ipairs(q.req or {}) do
            table.insert(parts, "- " .. r2[1] .. (r2[2] and r2[2] > 1 and (" x" .. r2[2]) or "") .. (r2[3] and (L.COLON .. ns.T(r2[3])) or ""))
          end
        end
        if nd.unknown then table.insert(parts, L.TRAVEL_UNK) end
        if (nd.kind == "h" or nd.kind == "c" or nd.kind == "a") and ns.PartyLine and nd.firstOfQuest ~= false then
          local pl = ns.PartyLine(nd.q)
          if pl then table.insert(parts, Hex(T.info) .. pl .. "|r") end
        end
      end
      if npcInSub then table.insert(parts, 1, npcInSub) end
      local sub = table.concat(parts, "\n")
      local nameH = ns.FitText(row.name, 2, nameW, row)
      row.sub:SetText(sub); row.sub:SetShown(sub ~= "")
      -- the detail lines start under the name, and under the GPS button (y 5 to 29) when it shows
      local subTop = 10 + nameH + 3
      if nd.loc then subTop = math.max(subTop, 5 + 24 + 4) end
      row.sub:ClearAllPoints(); row.sub:SetPoint("TOPLEFT", row, "TOPLEFT", ROW_NAME_X, -subTop)
      local subH = (sub ~= "") and (ns.FitText(row.sub, 0, subW, row)) or 0
      local rh = math.max(36, math.ceil(subTop + subH + 8))
      row:SetHeight(rh)
      row:ClearAllPoints(); row:SetPoint("TOPLEFT", card, "TOPLEFT", 4, -y)
      y = y + rh
      row:Show()
    else
      row.node = nil; row.bossName = nil; row:Hide()
    end
  end
  if after then
    y = y + GAP
    card.after:ClearAllPoints(); card.after:SetPoint("TOPLEFT", card, "TOPLEFT", CI, -y); card.after:SetText(after); card.after:Show()
    y = y + ns.FitText(card.after, 0, TW, card)
  else card.after:Hide() end
  if shareAfter then
    y = y + 8
    card.shareBtn:SetText(L.SHARE_SHORT)
    card.shareBtn:ClearAllPoints(); card.shareBtn:SetPoint("TOPLEFT", card, "TOPLEFT", CI, -y); card.shareBtn:Show()
    y = y + 28
  end
  y = y + CI

  -- the last step, route finished: next goes on to the "route finished" card
  f.prev:SetEnabled(i > 1); f.next:SetEnabled(i < #steps or RouteFinished()); f.moreBtn:SetEnabled(true)
  ns.RenderReadyBtn(log)
  -- count the points PlacePoints cycles through: the unfinished ones, else all of them
  local np = #StepPoints(log, st, false)
  if np == 0 then np = #StepPoints(log, st, true) end
  -- the big button: back to the current step when looking elsewhere, else "guide me there"
  local cycling = not ns.HasTomTom() and np > 1 and f.wpKey == i
  if f.auto and i ~= f.auto then
    f.go:SetText(RouteFinished() and L.BACK_FIN or L.BACK_CUR); if f.go.SetIcon then f.go:SetIcon("chevron_left") end
    f.go.action = GoBack; f.go:SetEnabled(true)
  elseif np > 0 then
    local label = L.GO
    if cycling then label = L.NEXTPOINT .. (" (%d / %d)"):format((f.wpIdx or 1) % np + 1, np)
    elseif st.gate and i == f.auto then
      -- the check-list: first the missing quests' givers, then the entrance
      local missLoc = 0
      for _, nd in ipairs(st.checks or {}) do if nd.loc and not ns.NodeOK(log, nd) then missLoc = missLoc + 1 end end
      label = missLoc > 0 and L.GO_MISSING or L.GO_ENTRANCE
    end
    f.go:SetText(label); if f.go.SetIcon then f.go:SetIcon("pin") end
    f.go.action = GoPoints; f.go:SetEnabled(true)
  else
    f.go:SetText(L.NOPOINT_S); if f.go.SetIcon then f.go:SetIcon("info") end
    f.go.action = nil; f.go:SetEnabled(false)
    f.go.disabledReason = L.NOPOINT
  end
  f.way:SetEnabled(np > 0)
  f.way.label:SetText(cycling and L.NEXTPOINT or L.M_POINTS)
  f.share.label:SetText(L.M_SHARE); f.share:SetEnabled(IsInGroup() and true or false)
  f.recalc.label:SetText(L.M_RECALC)
  f.done:SetEnabled(true)
  f.done.label:SetText(Manual(st) and L.M_UNSKIP or L.M_SKIP)
  f.arrowBtn.label:SetText(L.M_ARROW); f.arrowBtn:SetOn(WLDTDB.arrow ~= false)
  f.autoBtn.label:SetText(L.M_AUTO); f.autoBtn:SetOn(WLDTDB.autoWay)
  f.listBtn.label:SetText(L.M_LIST); f.listBtn:SetOn(f.list:IsShown())
  f.journal.label:SetText(L.M_JOURNAL); f.journal:SetEnabled(ns.JournalAvailable and ns.JournalAvailable() or false)

  FitGuide(TOP, y, LayoutFoot(true, false))
  WLDTDB.view = i
  RenderList(log)
  if not f.pinned and not InCombatLockdown() then f.pinned = true; ns.PinTopLeft() end
  ns.UpdateActionBar()
  if f.lastShown ~= i then f.lastShown = i; card.fade:Stop(); card.fade:Play() end
end
ns.Render = function() if f and f:IsShown() then Render() end end

-- =====================================================================
--  Suivi de l'étape en cours
-- =====================================================================
function ns.Refresh(silent)
  if not f then return end
  if ns.GuideOn and not ns.GuideOn() then return end
  local steps = Steps()
  if #steps == 0 then f.wasFin = nil; Render() return end
  local log = ns.LogEntries()
  local auto = FirstOpen(log)
  -- the whole route is done: points cleared, one sound and one message; the guide then shows the
  -- "route finished" card, one place after the last step (every step stays reachable with "<")
  local fin = (auto == #steps) and IsStepDone(log, auto)
  if fin then auto = #steps + 1 end
  if auto ~= f.auto then
    local follow = (f.view == nil) or (f.view == f.auto)
    local was = f.auto
    f.auto = auto
    if follow then f.view = auto; ScrollTop() end
    if was and auto > was and not silent and not fin then
      PlaySound(SOUNDKIT and SOUNDKIT.IG_QUEST_LIST_COMPLETE or 878)
      local t = StepTitle(steps[auto])
      if UIErrorsFrame then UIErrorsFrame:AddMessage("WL Helper" .. L.COLON .. t, T.fg[1], T.fg[2], T.fg[3]) end
      ns.Print(L.NEXT_STEP:format(t))
    end
  end
  if fin and not f.wasFin and not silent then
    ns.ClearPoints(); f.sig = nil
    PlaySound(SOUNDKIT and SOUNDKIT.IG_QUEST_LIST_COMPLETE or 878)
    if UIErrorsFrame then UIErrorsFrame:AddMessage("WL Helper" .. L.COLON .. L.FIN_T, T.ok[1], T.ok[2], T.ok[3]) end
    ns.Print(L.FIN_MSG:format(ns.route.label or ""))
  end
  f.wasFin = fin
  if WLDTDB.autoWay and not fin then
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
    body = "/run print('|cffce1918WL|r " .. L.MACRO_NONE:gsub("'", "\\'") .. "')"
  end
  if body == macroBody and GetMacroIndexByName(MACRO) > 0 then return end
  macroBody = body
  local idx = GetMacroIndexByName(MACRO)
  if idx and idx > 0 then
    pcall(EditMacro, idx, MACRO, nil, body)
  else
    -- a character macro, or an account one when the character's are full
    local nAcc, nChar = GetNumMacros()
    local maxChar = MAX_CHARACTER_MACROS or 18
    local maxAcc = MAX_ACCOUNT_MACROS or 120
    local perChar = true
    if nChar and nChar >= maxChar then
      if nAcc and nAcc < maxAcc then perChar = false
      else
        if not macroWarned then macroWarned = true; ns.Print(L.MACRO_FULL) end
        return
      end
    end
    local ok = pcall(CreateMacro, MACRO, "INV_Misc_QuestionMark", body, perChar)
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
  abar.wlWorld = true   -- drawn over the 3D world: its text keeps a shadow
  abar.label = Text(abar, ns.F.foot, T.muted, false, "SHADOW"); abar.label:SetPoint("LEFT", 2, 0); abar.label:SetText(L.AB_LABEL)
  abar.btns = {}
  for k = 1, AB_N do
    local b = CreateFrame("Button", "WLDTAction" .. k, abar, "SecureActionButtonTemplate")
    b:SetSize(AB_S, AB_S); b:RegisterForClicks("AnyUp", "AnyDown")
    ns.Flat(b, T.panel, T.cardEdge)
    b.icon = b:CreateTexture(nil, "ARTWORK"); b.icon:SetPoint("TOPLEFT", 2, -2); b.icon:SetPoint("BOTTOMRIGHT", -2, 2)
    b.hl = Tex(b, "HIGHLIGHT", T.hoverFill); b.hl:SetAllPoints()
    b.num = Text(b, ns.F.label, T.fg, true, "OUTLINE"); b.num:SetPoint("BOTTOMRIGHT", -1, 1)
    b:SetScript("OnEnter", function(self)
      local a = self.action
      if not a then return end
      if a.item then
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        if GameTooltip.SetItemByID then GameTooltip:SetItemByID(a.item) end
        GameTooltip:AddLine(L.TT_USE, T.accentSoft[1], T.accentSoft[2], T.accentSoft[3]); GameTooltip:Show()
      else
        ns.ShowTip(self, { L.TT_TARGET, L.TT_TARGET2:format(table.concat(a.names, " / ")), L.TT_RAID, L.TT_TARGET_CLICK })
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

-- For WL Helper's home and the minimap: the route's dungeons, the current step and how many there are.
-- The check-list step ("ready?") of the dungeon the step on screen belongs to
function ns.GoReady()
  local ti = ReadyTarget()
  if ti then ns.GoTo(ti) else ns.Print(L.NO_READY) end
end

function ns.GuideStatus()
  local steps = Steps()
  if #steps == 0 then return nil end
  local log = ns.LogEntries()
  local cur = FirstOpen(log)
  local finished = cur == #steps and IsStepDone(log, cur)
  -- full names ("Zul'Farrak", not "ZF"), the route's dungeons in order
  local names = {}
  for k in pairs(ns.route and ns.route.sel or {}) do names[#names + 1] = ns.DName(k) or k end
  table.sort(names)
  local label = #names > 0 and table.concat(names, ", ") or (ns.route and ns.route.label or "")
  return label, cur, #steps, finished, StepTitle(steps[cur])
end

-- Opens the guide (never closes it).
function ns.ShowGuide()
  if f and not f:IsShown() then ns.ToggleMain() end
end

local function GuideOff()
  local WP = ns.Writs and ns.Writs.WP
  return WP and WP.ModuleOff and WP.ModuleOff("dungeons")
end

function ns.ToggleMain()
  if not f then return end
  if not f:IsShown() and GuideOff() then return end
  f:SetShown(not f:IsShown()); WLDTDB.hidden = not f:IsShown()
  if WLDTDB.hidden then ns.SetArrow(nil) else f.sig = nil; ns.Refresh() end
  if ns.UpdateActionBar then ns.UpdateActionBar() end
end
