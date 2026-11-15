-- Vue d'ensemble d'un donjon : l'image, l'entrée (GPS), la clé, la taille du groupe, puis ses quêtes
-- pour ta classe, ta faction et ta race, rangées en trois temps (avant d'entrer, dans le donjon, à
-- rendre après). Chaque quête dit son état, ses prérequis, sa place dans la chaîne, ses objectifs et
-- ses récompenses, avec un interrupteur pour la garder ou la retirer de la route.
-- Ouverte depuis le choix des donjons (bouton de la carte, clic droit) et depuis le guide
-- (ns.ShowOverview(dkey)). Design system: docs/DESIGN.md (520 px window sized to its content).
local ADDON, ns = ...
local L, T = ns.L, ns.T_

-- (its strings live in Locale.lua, OV_*)

-- =====================================================================
--  Sizes (design system: window 520, inset 16, card pad 12, pills 18, kind icon 16)
-- =====================================================================
local W, PAD = 520, 16
local CW = W - 2 * PAD          -- content width
local HERO_H = 96
local ROW_GAP = 4
local MAX_OBJ, MAX_REWARDS = 3, 8

local function SW()
  local S = ns.Writs and ns.Writs.S
  if not S then error("WL Helper: Writs/Style.lua missing") end
  return S
end
local function num(v) return type(v) == "number" and not (issecretvalue and issecretvalue(v)) and v or nil end
local function Cls() local _, c = UnitClass("player"); return c end
local function Level() return num(UnitLevel("player")) or 1 end
local function Mark(name, color, size) return SW().IconMarkup(name, size or 12, color) end
local function ZoneName(m)
  if not (m and C_Map and C_Map.GetMapInfo) then return "" end
  local ok, info = pcall(C_Map.GetMapInfo, m)
  return (ok and type(info) == "table" and type(info.name) == "string") and info.name or ""
end
-- A FontString's measured height, never less than one line of its size (unmeasured text).
local function LineH(fs, size, width, owner, maxLines)
  local h = ns.FitText(fs, maxLines or 2, width, owner)
  if not h or h < size then h = size + 2 end
  return h
end

-- =====================================================================
--  Quest facts shared with the picker (state, prerequisites, chain)
-- =====================================================================
-- done / ready / on / none; pseudo-quests (negative ids, e.g. the Mallet) use ns.IsDone
local function QState(log, qid)
  if ns.IsDone(qid) then return "done" end
  return ns.State(log, qid)
end
ns.QuestState = QState

-- Prerequisites of a quest (the full chain, in order) and where the player stands in it:
-- { chain, total, done, inLog, states[i], nextPid, nextIdx }.
function ns.QuestPreInfo(qid, log, cls)
  log = log or ns.LogEntries()
  cls = cls or Cls()
  local chain = ns.FullChain(qid, cls) or {}
  local out = { chain = chain, total = #chain, done = 0, inLog = 0, states = {} }
  for i, pid in ipairs(chain) do
    local s = QState(log, pid)
    out.states[i] = s
    if s == "done" then out.done = out.done + 1
    else
      if s ~= "none" then out.inLog = out.inLog + 1 end
      if not out.nextPid then out.nextPid, out.nextIdx = pid, i end
    end
  end
  return out
end

-- The level the next thing to take needs, when the player is below it (nil otherwise).
local function LowLevel(q, st, pre, lvl)
  if st ~= "none" then return nil end
  local need = q.r
  if pre.nextPid then
    local pq = ns.Q[pre.nextPid]
    if pq and ns.State(ns.LogEntries(), pre.nextPid) ~= "none" then return nil end
    need = pq and pq.r
  end
  if need and lvl < need then return need end
  return nil
end

-- An objective with a place outside the dungeon, not done yet.
local function OutsideLeft(log, qid, q)
  for _, o in ipairs(q.o or {}) do
    if o.w and not o.ins and not o.outer and not ns.ObjDone(log, qid, o) then return o end
  end
end

-- Where the quest's next action happens: before (outside, before going in), inside, after; a
-- quest already turned in has its own last part.
local function SectionOf(log, qid, q, st, pre)
  if st == "done" then return "done" end
  if st == "ready" then return (q.f and q.f.i) and "inside" or "after" end
  if st == "on" then
    if OutsideLeft(log, qid, q) then return "before" end
    if q.noin then return "after" end
    return "inside"
  end
  if pre.done < pre.total then return "before" end
  if (q.s and q.s.i) or (q.si and not (q.s and q.s.m)) then return "inside" end
  return "before"
end

-- The point the quest's GPS leads to: the next prerequisite's giver (or its turn-in), the quest
-- giver, the outside objective, the turn-in. { m, x, y, label } or nil (inside, or unknown).
local function PointFor(log, qid, q, st, pre)
  local function at(l, fallback) if l and l.m and l.x and l.y then return { l.m, l.x, l.y, l.n or fallback } end end
  if pre.nextPid then
    local pq = ns.Q[pre.nextPid]
    if not pq then return nil end
    local ps = QState(log, pre.nextPid)
    if ps == "none" then return at(pq.s, ns.QName(pre.nextPid)) end
    if ps == "ready" then return at(pq.f, ns.QName(pre.nextPid)) end
    local o = OutsideLeft(log, pre.nextPid, pq)
    return o and at(o.w, o.n)
  end
  if st == "none" then return at(q.s, ns.QName(qid)) end
  if st == "ready" then return at(q.f, ns.QName(qid)) end
  if st == "on" then
    local o = OutsideLeft(log, qid, q)
    return o and at(o.w, o.n)
  end
  return nil
end

local function GoPoint(p)
  if not p then return end
  if ns.SetPoints then ns.SetPoints({ p }, true) end
  -- the guide's arrow follows the points only while the guide is open and its arrow on:
  -- a click on a GPS button starts the arrow anyway
  local G = ns.Writs and ns.Writs.WP and ns.Writs.WP.GPS
  if G and G.GoPoint and WLDTDB and (WLDTDB.hidden or WLDTDB.arrow == false) then
    pcall(G.GoPoint, p[1], p[2], p[3], p[4], "dungeon")
  end
  if PlaySound then PlaySound(SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or 856) end
end

-- Who gives the quest and where; once its objectives are done, who takes it back.
local function GiverText(q, st)
  local s, fmt, txt = q.s, L.OV_GIVER, q.st
  if st == "ready" and (q.f or q.ft) then s, fmt, txt = q.f, L.OV_FINISHER, q.ft
  elseif q.si and (not s or s.i) then return L.OV_ITEM_START:format(q.si) end
  if s and s.i then return fmt:format((s.n or "?") .. ", " .. L.OV_IN_DG) end
  if s and s.m then
    local z = ZoneName(s.m)
    if s.n and z ~= "" then return fmt:format(s.n .. ", " .. z) end
    return fmt:format(s.n or z)
  end
  if txt then return fmt:format(ns.T(txt)) end
  return nil
end

-- Rewards: item ids read live from LibForeverData when it is loaded; else the item names of the data.
local function Rewards(qid, q)
  local out = {}
  local lib = _G.LibForeverData
  if type(lib) == "table" and type(lib.Quest) == "function" and qid > 0 then
    local ok, rec = pcall(lib.Quest, qid)
    if ok and type(rec) == "table" and type(rec.rewards) == "table" then
      for _, rw in ipairs(rec.rewards) do
        if type(rw) == "table" and (rw.kind == "item" or rw.kind == "choice") and rw.id then
          out[#out + 1] = { id = rw.id, choice = rw.kind == "choice", count = rw.count }
        end
      end
    end
  end
  if #out == 0 and q.ri then for _, n in ipairs(q.ri) do out[#out + 1] = { name = n, choice = q.rc } end end
  return out
end

local function ItemInfo(rw)
  local key = rw.id or rw.name
  local icon, link
  if rw.id then
    local ok, ic = pcall(function() return (C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(rw.id)) or (GetItemIcon and GetItemIcon(rw.id)) end)
    if ok then icon = ic end
    if not icon and C_Item and C_Item.RequestLoadItemDataByID then pcall(C_Item.RequestLoadItemDataByID, rw.id) end
  end
  if GetItemInfo and key then
    local ok, _, l, _, _, _, _, _, _, _, tex = pcall(GetItemInfo, key)
    if ok then link = l; icon = icon or tex end
  end
  return icon or "Interface\\Icons\\INV_Misc_QuestionMark", link
end

local function Upgrade(link)
  local WP = ns.Writs and ns.Writs.WP
  if not (link and WP and WP.UpgradeCheck) then return nil end
  local ok, r = pcall(WP.UpgradeCheck, link)
  if ok and type(r) == "table" and r.up then return r.text or "" end
  return nil
end

-- =====================================================================
--  Window
-- =====================================================================
local f
local Render

local function RouteHas(qid)
  for k in pairs(WLDTDB.sel or {}) do
    for _, x in ipairs(ns.D[k] and ns.D[k].q or {}) do if x == qid then return true end end
    local _, cls = UnitClass("player")
    for _, x in ipairs(ns.DungeonQuests(k, cls)) do
      for _, pid in ipairs(ns.FullChain(x, cls) or {}) do if pid == qid then return true end end
    end
  end
  return false
end

local function SetOff(qid, off)
  if not qid then return end
  WLDTDB.off = WLDTDB.off or {}
  WLDTDB.off[qid] = off and true or nil
  if ns.route and ns.frame and ns.Recalc and RouteHas(qid) then ns.Recalc() end
  if ns.RenderPicker then ns.RenderPicker() end
  Render()
end

local function RowTip(r)
  local qid = r.qid
  local q = qid and ns.Q[qid]
  if not q then return end
  local lines = { ns.QName(qid) }
  if GetLocale and GetLocale() == "frFR" and q.n and q.n ~= lines[1] then table.insert(lines, q.n)
  elseif ns.lang == "fr" and q.nf and q.nf ~= lines[1] then table.insert(lines, q.nf) end
  local obj = (ns.lang == "fr" and q.of) or ns.T(q.oe)
  if obj then table.insert(lines, { obj, T.text[1], T.text[2], T.text[3] }) end
  local pre = r.pre
  if pre and pre.total > 0 then
    table.insert(lines, { L.OV_CHAIN_TT, T.fg[1], T.fg[2], T.fg[3] })
    local log = ns.LogEntries()
    local function step(id, i, s)
      local mark = s == "done" and Mark("check", T.ok) or (s ~= "none" and Mark("dot", T.info) or Mark("dot", T.faint))
      local sq = ns.Q[id] or {}
      local txt = mark .. " " .. (id == qid and (ns.QName(id) .. " (" .. L.OV_THIS .. ")") or ns.QName(id))
      if sq.l then txt = txt .. " · " .. L.PICK_LV1:format(sq.l) end
      if i == 1 and sq.s and sq.s.m then
        local z = ZoneName(sq.s.m)
        if z ~= "" then txt = txt .. " · " .. z end
      end
      local c = s == "done" and T.muted or T.text
      table.insert(lines, { txt, c[1], c[2], c[3] })
    end
    for i, pid in ipairs(pre.chain) do step(pid, i, pre.states[i]) end
    step(qid, pre.total + 1, QState(log, qid))
  end
  if r.moreObj then for _, s in ipairs(r.moreObj) do table.insert(lines, s) end end
  if q.ne then table.insert(lines, ns.T(q.ne)) end
  local rw = q.rw and q.rw ~= "" and q.rw or nil
  if rw then table.insert(lines, { L.TT_REWARD:format(rw), T.gold[1], T.gold[2], T.gold[3] }) end
  if r.low then table.insert(lines, { L.ST_LOW:format(r.low), T.warn[1], T.warn[2], T.warn[3] }) end
  if WLDTDB.off and WLDTDB.off[qid] then table.insert(lines, L.PICK_QOFF) end
  if r.point then table.insert(lines, L.OV_ROW_CLICK:format(r.point[4] or "")) end
  ns.ShowTip(r, lines)
end

local function MakeReward(parent)
  local b = CreateFrame("Button", nil, parent)
  b:SetSize(20, 20)
  b.wlOwned = true
  b.tex = b:CreateTexture(nil, "ARTWORK"); b.tex:SetPoint("TOPLEFT", 1, -1); b.tex:SetPoint("BOTTOMRIGHT", -1, 1)
  b.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  ns.Outline(b, T.cardEdge)
  b.up = ns.Icon(b, "arrow_up", 12, "OVERLAY", T.ok); b.up:SetPoint("BOTTOMRIGHT", 4, -4); b.up:Hide()
  b:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:ClearLines()
    local shown = false
    if self.link and GameTooltip.SetHyperlink then shown = pcall(GameTooltip.SetHyperlink, GameTooltip, self.link)
    elseif self.id and GameTooltip.SetItemByID then shown = pcall(GameTooltip.SetItemByID, GameTooltip, self.id) end
    if not shown then GameTooltip:AddLine(self.name or "?", T.fg[1], T.fg[2], T.fg[3], true) end
    if self.choice then GameTooltip:AddLine(L.OV_CHOICE, T.muted[1], T.muted[2], T.muted[3], true) end
    if self.upText then GameTooltip:AddLine(L.OV_UPGRADE .. (self.upText ~= "" and (" " .. self.upText) or ""), T.ok[1], T.ok[2], T.ok[3], true) end
    if self.link then GameTooltip:AddLine(L.TT_SHIFT_LINK, T.muted[1], T.muted[2], T.muted[3], true) end
    GameTooltip:Show()
  end)
  b:SetScript("OnLeave", function() GameTooltip:Hide() end)
  b:SetScript("OnClick", function(self)
    if self.link and HandleModifiedItemClick then pcall(HandleModifiedItemClick, self.link) end
  end)
  return b
end

local function MakeRow(parent)
  local S = SW()
  local r = CreateFrame("Button", nil, parent)
  r.wlOwned = true
  r:SetWidth(CW)
  r.bg = ns.Tex(r, "BACKGROUND", T.cardFill); r.bg:SetAllPoints()
  ns.Outline(r, T.cardEdge)
  -- hover and press only on a row whose click does something (a point to guide to)
  r.hl = ns.Tex(r, "BORDER", T.hoverFill); r.hl:SetAllPoints(); r.hl:Hide()
  r.press = ns.Tex(r, "ARTWORK", T.pressFill); r.press:SetAllPoints(); r.press:Hide()
  r.icon = ns.Icon(r, "mail", 16, "ARTWORK", T.text); r.icon:SetPoint("TOPLEFT", 8, -8)
  r.name = ns.Text(r, ns.F.body, T.fg)
  r.name:SetPoint("TOPLEFT", 32, -6)
  r.lines, r.rewards = {}, {}
  r.pill = S.Pill(r); r.pill:SetPoint("TOPRIGHT", -12, -8)
  r.swTip = {}
  r.switch = S.Switch(r, function() return not (WLDTDB.off and r.qid and WLDTDB.off[r.qid]) end,
    function(v) SetOff(r.qid, not v) end, r.swTip)
  r.gps = S.IconButton(r, "pin", 24, function()
    return { L.OV_GPS_T:format(r.point and r.point[4] or ""), L.OV_GPS_CLICK }
  end, function() GoPoint(r.point) end)
  r:SetScript("OnClick", function(self) if self.point then GoPoint(self.point) end end)
  -- pressed: the fill and the content 1 px down
  local function nudge(self, dy)
    self.name:ClearAllPoints(); self.name:SetPoint("TOPLEFT", 32, -6 - dy)
    self.icon:ClearAllPoints(); self.icon:SetPoint("TOPLEFT", 8, -8 - dy)
  end
  r:SetScript("OnMouseDown", function(self) if self.point then self.press:Show(); nudge(self, 1) end end)
  r:SetScript("OnMouseUp", function(self) self.press:Hide(); nudge(self, 0) end)
  r:SetScript("OnEnter", function(self) if self.point then self.hl:Show() end RowTip(self) end)
  r:SetScript("OnLeave", function(self) self.hl:Hide(); self.press:Hide(); nudge(self, 0); ns.HideTip() end)
  return r
end

-- state -> icon, icon colour, pill label, pill colour, pill icon
local LOOK = {
  none  = { "mail", T.text, "S_NONE", T.fg },
  on    = { "clock", T.info, "S_ON", T.info },
  ready = { "flag", T.ok, "S_READY", T.ok },
  done  = { "check", T.ok, "S_DONE", T.muted, "check" },
}

-- Fills one quest row; returns its height.
local function FillRow(r, qid, ctx)
  local q = ns.Q[qid]
  local log = ctx.log
  local st = QState(log, qid)
  local off = WLDTDB.off and WLDTDB.off[qid] and true or false
  local pre = ns.QuestPreInfo(qid, log, ctx.cls)
  local low = LowLevel(q, st, pre, ctx.lvl)
  r.qid, r.st, r.pre, r.low = qid, st, pre, low
  r.point = (st ~= "done") and PointFor(log, qid, q, st, pre) or nil
  local look = LOOK[st] or LOOK.none
  -- the icon says the state; a quest out of reach or left out says that first
  if off and st ~= "done" then ns.SetHDIcon(r.icon, "minus", T.faint)
  elseif low then ns.SetHDIcon(r.icon, "warning", T.warn)
  else ns.SetHDIcon(r.icon, look[1], look[2]) end
  if off and st ~= "done" then r.pill:Set(L.OV_ST_OFF, T.muted) else r.pill:Set(L[look[3]], look[4], look[5]) end
  local pillW = num(r.pill:GetWidth()) or 0
  local clusterW = math.max(72, pillW)
  local tw = CW - 32 - 8 - clusterW - 12

  r.name:SetText(ns.QName(qid))
  local nc = (off or st == "done") and T.muted or T.fg
  r.name:SetTextColor(nc[1], nc[2], nc[3])
  local y = 6 + LineH(r.name, ns.F.body, tw, r)

  -- the lines under the name: detail, prerequisites and chain, reach, objectives
  local lines = {}
  local detail = {}
  if q.l then table.insert(detail, L.PICK_LV1:format(q.l)) end
  if st ~= "done" then local g = GiverText(q, st); if g then table.insert(detail, g) end end
  if #detail > 0 then table.insert(lines, { table.concat(detail, " · "), T.muted }) end
  r.moreObj = nil
  if st ~= "done" then
    if pre.total == 0 then
      table.insert(lines, { L.CH_NONE, T.muted })
    else
      local names = {}
      for i, pid in ipairs(pre.chain) do if i <= 2 then names[#names + 1] = ns.QName(pid) end end
      local s = table.concat(names, ", ")
      if pre.total > 2 then s = s .. " " .. L.OV_MORE:format(pre.total - 2) end
      local word, col
      if pre.done == pre.total then word, col = (pre.total == 1 and L.OV_PRE_DONE1 or L.OV_PRE_DONE), T.ok
      elseif pre.done == 0 then word, col = (pre.total == 1 and L.OV_PRE_TODO1 or L.OV_PRE_TODO), T.warn
      else word, col = L.OV_PRE_PART:format(pre.done, pre.total), T.warn end
      table.insert(lines, { ns.Plural(pre.total, "OV_PRE1", "OV_PRE", s .. " (" .. word .. ")"), col })
      table.insert(lines, { L.OV_CHAIN:format(pre.nextIdx or (pre.total + 1), pre.total + 1), T.muted })
    end
    if low then table.insert(lines, { L.ST_LOW:format(low), T.warn }) end
    local objs = q.o or {}
    for i, o in ipairs(objs) do
      if o.n then
        local a, b, fin
        if st == "ready" then fin, a, b = true, o.c, o.c
        elseif st == "on" then
          if ns.LiveCount then a, b, fin = ns.LiveCount(log, qid, i, o.n, #objs) end
          if not fin and ns.ObjDone(log, qid, o) then fin = true; a = a or o.c; b = b or o.c end
        end
        local txt = ((o.c and o.c > 0) and (("%d/%d "):format(a or 0, b or o.c)) or "") .. o.n
        if i <= MAX_OBJ then
          if fin then table.insert(lines, { Mark("check", T.ok) .. " " .. txt, T.ok })
          else table.insert(lines, { txt, T.text }) end
        else
          r.moreObj = r.moreObj or {}
          table.insert(r.moreObj, "- " .. txt)
        end
      end
    end
  end
  for i, ln in ipairs(lines) do
    local fs = r.lines[i] or ns.Text(r, ns.F.meta, T.muted); r.lines[i] = fs
    fs:SetText(ln[1])
    local c = ln[2] or T.muted
    fs:SetTextColor(c[1], c[2], c[3])
    fs:ClearAllPoints(); fs:SetPoint("TOPLEFT", 32, -(y + 3))
    fs:Show()
    y = y + 3 + LineH(fs, ns.F.meta, tw, r)
  end
  for i = #lines + 1, #r.lines do r.lines[i]:Hide() end
  r.nLines = #lines

  -- rewards: item icons (20 px) with their tooltip, an arrow on an upgrade
  local n = 0
  if st ~= "done" then
    for _, rw in ipairs(Rewards(qid, q)) do
      if n >= MAX_REWARDS then break end
      n = n + 1
      local b = r.rewards[n] or MakeReward(r); r.rewards[n] = b
      local icon, link = ItemInfo(rw)
      b.id, b.name, b.link, b.choice = rw.id, rw.name, link, rw.choice
      b.tex:SetTexture(icon)
      b.upText = Upgrade(link)
      b.up:SetShown(b.upText ~= nil)
      b:ClearAllPoints(); b:SetPoint("TOPLEFT", 32 + (n - 1) * 24, -(y + 6))
      b:Show()
    end
  end
  for i = n + 1, #r.rewards do r.rewards[i]:Hide() end
  if n > 0 then y = y + 6 + 20 end

  -- right cluster: the pill, then the route switch and the GPS button
  local route = st ~= "done"
  r.swTip[1] = off and L.PICK_QOFF or L.OV_ON_T
  r.swTip[2] = off and L.OV_OFF_CLICK or L.OV_ON_CLICK
  r.swTip[3] = nil
  r.switch:ClearAllPoints(); r.switch:SetPoint("TOPRIGHT", -12, -34)
  r.switch:SetShown(route)
  if route then r.switch:Update() end
  r.gps:ClearAllPoints()
  if route then r.gps:SetPoint("RIGHT", r.switch, "LEFT", -8, 0) else r.gps:SetPoint("TOPRIGHT", -12, -32) end
  r.gps:SetShown(r.point ~= nil)
  local clusterH = route and (34 + 20 + 2 + 8) or ((r.point and 56 or 26) + 8)
  local h = math.ceil(math.max(y + 8, clusterH))
  r:SetHeight(h)
  return h
end

local function Build()
  local S = SW()
  f = S.Window("WLHelperOverview", W, 300, "", L.OV_T, WLDTDB, "ovPos", { header = 44, minH = 120, strata = "HIGH" })
  f.sa = S.ScrollArea(f)
  f.child = f.sa.child
  f.child:SetWidth(CW)
  local c = f.child

  -- hero: the dungeon's picture, a dark band with the level, the group size and the place
  local hero = CreateFrame("Frame", nil, c)
  hero.wlWorld = true
  hero:SetSize(CW, HERO_H)
  hero:SetPoint("TOPLEFT", 0, 0)
  ns.Flat(hero, T.panel, T.cardEdge)
  hero.art = hero:CreateTexture(nil, "ARTWORK"); hero.art:SetPoint("TOPLEFT", 1, -1); hero.art:SetPoint("BOTTOMRIGHT", -1, 1)
  hero.big = hero:CreateTexture(nil, "ARTWORK", nil, 1); hero.big:SetSize(40, 40); hero.big:SetPoint("CENTER", 0, 12); hero.big:Hide()
  hero.band = hero:CreateTexture(nil, "ARTWORK", nil, 3); hero.band:SetPoint("BOTTOMLEFT", 1, 1); hero.band:SetPoint("BOTTOMRIGHT", -1, 1)
  hero.band:SetColorTexture(unpack(T.scrim))
  hero.loc = ns.Text(hero, ns.F.meta, T.text, false, "SHADOW"); hero.loc:SetPoint("BOTTOMLEFT", 12, 8)
  hero.lvl = ns.Text(hero, ns.F.label, T.fg, false, "SHADOW"); hero.lvl:SetPoint("BOTTOMLEFT", hero.loc, "TOPLEFT", 0, 3)
  f.hero = hero

  -- the facts under the picture: entrance (with its GPS), keys, the summary
  f.info = {}
  f.entryGps = S.IconButton(c, "pin", 24, function()
    return { L.OV_GPS_T:format(L.OV_ENTRY_T), L.OV_GPS_CLICK }
  end, function() GoPoint(f.entryPoint) end)
  f.summary = ns.Text(c, ns.F.body, T.text)

  f.goBtn = S.Button(c, L.OV_GO, 0, 28, "primary", function()
    local dkey = f.dkey
    if not dkey then return end
    wipe(WLDTDB.sel); WLDTDB.sel[dkey] = true
    f:Hide()
    ns.StartGuide()
  end, { L.OV_GO, L.OV_GO_TT })
  f.goBtn:SetDisabledReason(L.OV_GO_WHY)
  f.pickBtn = S.Button(c, L.OV_PICK, 0, 28, "secondary", function()
    local dkey = f.dkey
    if not dkey then return end
    WLDTDB.sel[dkey] = not WLDTDB.sel[dkey] or nil
    if ns.RenderPicker then ns.RenderPicker() end
    Render()
  end, function() return { f.pickBtn:GetText(), WLDTDB.sel[f.dkey] and L.OV_UNPICK_TT or L.OV_PICK_TT } end)
  f.pickBtn:SetPoint("RIGHT", f.goBtn, "LEFT", -8, 0)

  f.heads, f.rows = {}, {}
  f.empty = S.EmptyState(c, "portal", L.OV_EMPTY_T, L.OV_EMPTY)
  f.empty:Hide()

  -- the overview follows the quest log, the level and the bags while it is open
  local ev = CreateFrame("Frame", nil, f)
  for _, e in ipairs({ "QUEST_LOG_UPDATE", "QUEST_TURNED_IN", "PLAYER_LEVEL_UP", "BAG_UPDATE_DELAYED", "GET_ITEM_INFO_RECEIVED" }) do
    pcall(ev.RegisterEvent, ev, e)
  end
  local queued = false
  ev:SetScript("OnEvent", function()
    if queued or not f:IsShown() then return end
    queued = true
    local fn = function() queued = false; if f:IsShown() then Render() end end
    if C_Timer and C_Timer.After then C_Timer.After(0.3, fn) else fn() end
  end)
end

-- A line of the facts block: HD icon 14 at the left edge, body text at 22.
local function InfoLine(i, icon, color, text, textColor, width)
  local c = f.child
  local it = f.info[i]
  if not it then
    it = { icon = ns.Icon(c, "dot", 14, "ARTWORK", T.muted), fs = ns.Text(c, ns.F.body, T.text) }
    f.info[i] = it
  end
  ns.SetHDIcon(it.icon, icon, color)
  it.fs:SetText(text)
  local tc = textColor or T.text
  it.fs:SetTextColor(tc[1], tc[2], tc[3])
  it.icon:Show(); it.fs:Show()
  return it, width
end

Render = function()
  if not (f and f.dkey) then return end
  local S = SW()
  local dkey = f.dkey
  local d = ns.D[dkey]
  if not d then f:Hide(); return end
  local log = ns.LogEntries()
  local cls, lvl = Cls(), Level()
  local ctx = { log = log, cls = cls, lvl = lvl, dkey = dkey }
  f.title:SetText(ns.DName(dkey))
  f.subtitle:SetText(L.OV_T)
  local c = f.child

  -- hero
  local hero = f.hero
  if ns.DungeonArt then ns.DungeonArt(hero.art, dkey, hero.big) end
  local parts = {}
  if d.lvl and d.lvl[1] then
    local lo, hi = d.lvl[1], d.lvl[2] or d.lvl[1]
    table.insert(parts, lo == hi and L.PICK_LV1:format(lo) or L.PICK_LV:format(lo, hi))
  end
  table.insert(parts, L.OV_GROUP:format(d.size or 5))
  hero.lvl:SetText(table.concat(parts, " · "))
  local loc = (GetLocale and GetLocale() == "frFR" and d.locf) or ns.T(d.loc) or ""
  if d.cq and d.home then loc = L.CQ_IN:format(ns.DName(d.home)) end
  hero.loc:SetText(loc)
  local locH = loc ~= "" and LineH(hero.loc, ns.F.meta, CW - 24, hero) or 0
  local lvlH = LineH(hero.lvl, ns.F.label, CW - 24, hero, 1)
  hero.band:SetHeight(math.min(HERO_H - 2, 8 + locH + (locH > 0 and 3 or 0) + lvlH + 8))
  local y = HERO_H + 12

  -- facts: entrance, keys
  local i = 0
  local function place(it, w, extra)
    it.icon:ClearAllPoints(); it.icon:SetPoint("TOPLEFT", c, "TOPLEFT", 0, -(y + 1))
    it.fs:ClearAllPoints(); it.fs:SetPoint("TOPLEFT", c, "TOPLEFT", 22, -y)
    local h = LineH(it.fs, ns.F.body, w, c, 0)
    y = y + math.max(h, extra or 0) + 6
  end
  f.entryPoint = d.e and d.e.m and { d.e.m, d.e.x, d.e.y, ns.DName(dkey) } or nil
  local entry = ns.T(d.ed) or loc
  if entry and entry ~= "" then
    i = i + 1
    local it, w = InfoLine(i, "portal", T.muted, L.OV_ENTRANCE:format(entry), T.text, CW - 22 - (f.entryPoint and 32 or 0))
    f.entryGps:ClearAllPoints(); f.entryGps:SetPoint("TOPRIGHT", c, "TOPRIGHT", 0, -(y - 5))
    place(it, w, f.entryPoint and 14 or 0)
  end
  f.entryGps:SetShown(f.entryPoint ~= nil and entry ~= nil and entry ~= "")
  local keys = ns.KeyLines and ns.KeyLines(dkey) or {}
  if #keys == 0 then
    i = i + 1
    place(InfoLine(i, "check", T.muted, L.OV_KEY_NONE, T.muted, CW - 22), CW - 22)
  else
    for _, k in ipairs(keys) do
      i = i + 1
      local icon, col = "check", T.ok
      if not k[2] then if k[3] then icon, col = "warning", T.warn else icon, col = "info", T.muted end end
      place(InfoLine(i, icon, col, k[1], T.text, CW - 22), CW - 22)
    end
  end
  for j = i + 1, #f.info do f.info[j].icon:Hide(); f.info[j].fs:Hide() end
  f.nInfo = i

  -- the quests, their state, and the summary over them
  local qs = ns.DungeonQuests(dkey, cls)
  local secs = { before = {}, inside = {}, after = {}, done = {} }
  local inLog, offN, missing, seenPre = 0, 0, 0, {}
  local info = {}
  for _, qid in ipairs(qs) do
    local q = ns.Q[qid]
    local st = QState(log, qid)
    local pre = ns.QuestPreInfo(qid, log, cls)
    info[qid] = { st = st, l = q.l or 0 }
    if st == "on" or st == "ready" then inLog = inLog + 1 end
    if WLDTDB.off and WLDTDB.off[qid] and st ~= "done" then offN = offN + 1 end
    if st ~= "done" then
      for k, pid in ipairs(pre.chain) do
        if pre.states[k] ~= "done" and not seenPre[pid] then seenPre[pid] = true; missing = missing + 1 end
      end
    end
    table.insert(secs[SectionOf(log, qid, q, st, pre)], qid)
  end
  local sum = { ns.Plural(#qs, "OV_SUM_Q1", "OV_SUM_Q", #qs), ns.Plural(inLog, "OV_SUM_LOG1", "OV_SUM_LOG", inLog),
    missing == 0 and L.OV_SUM_PRE0 or ns.Plural(missing, "OV_SUM_PRE1", "OV_SUM_PRE", missing) }
  if offN > 0 then table.insert(sum, ns.Plural(offN, "OV_SUM_OFF1", "OV_SUM_OFF", offN)) end
  -- no quest: the empty block below says it, the summary would only repeat "0 quests"
  if #qs > 0 then
    f.summary:SetText(table.concat(sum, " · "))
    f.summary:ClearAllPoints(); f.summary:SetPoint("TOPLEFT", c, "TOPLEFT", 0, -(y + 2))
    f.summary:Show()
    y = y + 2 + LineH(f.summary, ns.F.body, CW, c) + 12
  else
    f.summary:SetText(""); f.summary:Hide()
    y = y + 6
  end

  -- the actions: guide me through this dungeon (primary), pick / unpick it. No quest at all: the
  -- empty block below stands alone, without them. Every quest turned in: nothing to guide.
  local picked = WLDTDB.sel and WLDTDB.sel[dkey]
  f.pickBtn:SetText(picked and L.OV_UNPICK or L.OV_PICK)
  if f.pickBtn.SetIcon then f.pickBtn:SetIcon(picked and "minus" or "plus") end
  if f.goBtn.SetIcon then f.goBtn:SetIcon("pin") end
  if #qs > 0 then
    local open = #qs - #secs.done
    f.goBtn:SetDisabledReason(L.OV_GO_DONE)
    f.goBtn:SetEnabled(open > 0)
    f.goBtn:ClearAllPoints(); f.goBtn:SetPoint("TOPRIGHT", c, "TOPRIGHT", 0, -y)
    f.goBtn:Show(); f.pickBtn:Show()
    y = y + 28
  else
    f.goBtn:Hide(); f.pickBtn:Hide()
  end

  -- three sections; a section with no quest is left out
  for _, h in ipairs(f.heads) do h:Hide() end
  local ri, hi = 0, 0
  local function order(a, b)
    local ia, ib = info[a], info[b]
    local da, db = ia.st == "done", ib.st == "done"
    if da ~= db then return db end
    if ia.l ~= ib.l then return ia.l < ib.l end
    return a < b
  end
  -- the same words as the guide's chapters and the tracker, then the quests turned in
  for _, s in ipairs({ { "before", L.PH_BEFORE_S }, { "inside", L.PH_INSIDE_S }, { "after", L.PH_AFTER_S }, { "done", L.OV_SEC_DONE } }) do
    local list = secs[s[1]]
    if #list > 0 then
      table.sort(list, order)
      hi = hi + 1
      local h = f.heads[hi] or S.SectionHeader(c, s[2], #list); f.heads[hi] = h
      h:Set(s[2], #list)
      y = y + (hi == 1 and 8 or 16)
      h:ClearAllPoints(); h:SetPoint("TOPLEFT", c, "TOPLEFT", 0, -y); h:SetWidth(CW); h:Show()
      y = y + 32 + 8
      for _, qid in ipairs(list) do
        ri = ri + 1
        local r = f.rows[ri] or MakeRow(c); f.rows[ri] = r
        r:ClearAllPoints(); r:SetPoint("TOPLEFT", c, "TOPLEFT", 0, -y)
        local h2 = FillRow(r, qid, ctx)
        r:Show(); r.shownNow = true
        y = y + h2 + ROW_GAP
      end
      y = y - ROW_GAP
    end
  end
  for j = ri + 1, #f.rows do f.rows[j]:Hide(); f.rows[j].shownNow = nil end

  if #qs == 0 then
    local up = d.up and time() < d.up
    local why = L.OV_EMPTY
    if up then why = L.OV_EMPTY_UP elseif #(d.q or {}) == 0 then why = L.OV_EMPTY_NONE end
    f.empty:ClearAllPoints(); f.empty:SetPoint("TOP", c, "TOP", 0, -(y + 24))
    f.empty:SetWrapWidth(CW)
    local eh = f.empty:Set("portal", L.OV_EMPTY_T, why)
    f.empty:Show()
    y = y + 24 + (num(eh) or 80)
  else
    f.empty:Hide()
  end

  -- the window fits its content up to 80 % of the screen; past that, the content scrolls
  local contentH = math.ceil(y)
  local top = f:ContentTop() + 12
  local cap = math.floor((num(UIParent:GetHeight()) or 768) * 0.80) - top - 12
  local viewH = math.max(60, math.min(contentH, cap))
  f.sa:ClearAllPoints()
  f.sa:SetPoint("TOPLEFT", f, "TOPLEFT", PAD, -top); f.sa:SetPoint("TOPRIGHT", f, "TOPRIGHT", -PAD, -top)
  f.sa:SetHeight(viewH)
  f.child:SetWidth(CW)
  f.sa:SetContentHeight(contentH)
  f:FitHeight(viewH)
end
ns.RenderOverview = function() if f and f:IsShown() then Render() end end

local function GuideOff()
  local WP = ns.Writs and ns.Writs.WP
  return WP and WP.ModuleOff and WP.ModuleOff("dungeons")
end

-- The dungeon the guide is on (inside it, or its first picked dungeon), for a call without a key.
local function DefaultKey()
  local here = ns.InstanceKeys and ns.InstanceKeys() or {}
  if here[1] then return here[1] end
  for _, k in ipairs(ns.ORDER or {}) do if WLDTDB.sel and WLDTDB.sel[k] then return k end end
end

-- Opens the overview of a dungeon (dkey from ns.D); without a key, the guide's dungeon.
function ns.ShowOverview(dkey)
  if GuideOff() then return end
  if ns.EnsureClassCards then ns.EnsureClassCards() end
  dkey = dkey or DefaultKey()
  if not (dkey and ns.D[dkey]) then return end
  if not f then Build() end
  if f.dkey ~= dkey and f.sa then f.sa:ScrollTo(0, true) end
  f.dkey = dkey
  f:Show(); f:Raise()
  Render()
  -- wrapped text has its real height once the font and width are applied: measure again
  if C_Timer and C_Timer.After then C_Timer.After(0, function() if f:IsShown() then Render() end end) end
end
function ns.HideOverview() if f then f:Hide() end end
