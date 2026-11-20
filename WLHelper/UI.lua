-- Fenêtre du guide : une étape à la fois, liste des étapes, boutons de ciblage / objet / GPS.
local ADDON, ns = ...
local L, T = ns.L, ns.T_
local Text, Tex, Button, Hex = ns.Text, ns.Tex, ns.Button, ns.Hex

-- 520: the design system's two-column width; the grip changes it between 420 and 760 (hud tier,
-- UI width spec 4.7). W is the width drawn: the player's width (Wuser), widened when the header's
-- title or the footer's buttons need more (French "Guide de quêtes", "Partager 4 quêtes").
local W, PAD, MAXROWS = 520, 16, 30
local WMIN, WMAX, Wuser = 420, 760, 520
local NAV = {}   -- the navigation helpers (T-84..T-86) in one upvalue: Render is near Lua 5.1's limit
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
  map   = { hd = "flag", c = T.muted },   -- a place to reach (info stays the info icon's colour)
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
local doneMemo, doneGen, doneLog, doneSteps = {}, nil, nil, nil
local function SetManual(st, v) WLDTDB.manual[st.key] = v or nil; doneGen = nil end
-- the tracker's shift-click marks a step done (or undone) by hand
function ns.SetStepManual(i, v)
  local st = Steps()[i]; if not st then return end
  SetManual(st, v)
  if f and f:IsShown() then ns.Refresh() elseif ns.AfterRefresh then ns.AfterRefresh() end
end

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

-- Does the step's mark still count? "kill" (the boss died with every line done) and "skip" (an
-- optional boss left behind) stand for the lines the step held then: a replan that puts an open
-- quest line under the same key opens it again. A tick by hand (true) stays.
local function ManualHolds(log, st)
  local m = Manual(st)
  return m == true or (m and (#st.acts == 0 or StepAuto(log, st))) and true or false
end

local IsStepDoneRaw
local function IsStepDone(log, i)
  -- kept for the length of one refresh pass (ns.PassGen): a refresh asks for every step many times
  local g = ns.PassGen and ns.PassGen()
  if not g then return IsStepDoneRaw(log, i) end
  local steps = Steps()
  if doneGen ~= g or doneLog ~= log or doneSteps ~= steps then doneMemo, doneGen, doneLog, doneSteps = {}, g, log, steps end
  local m = doneMemo[i]
  if m == nil then m = IsStepDoneRaw(log, i) and true or false; doneMemo[i] = m end
  return m
end
-- A boss step: done once its boss died during this run and its quest lines are done (a quest item
-- that did not drop, a talk or a loot after the kill keep it open; the tracker ticks the kill
-- line meanwhile). Kept by hand afterwards, so leaving the dungeon does not undo it, but only
-- after a kill seen in this session: kills read back from an old copy never stick. An optional
-- boss (nothing for you there) is also done once a later boss of the same visit died: you went
-- past it.
local function BossStepDone(log, i, st)
  if ns.BossStepKilled(st) then
    if #st.acts > 0 and not StepAuto(log, st) then return false end
    -- ("kill": done from the kill, undone when the boss panel's right-click marks it not killed)
    if not ns.BossRunLive or ns.BossRunLive() then SetManual(st, Manual(st) or "kill") end
    return true
  end
  local steps = Steps()
  local later = false
  for j = i + 1, #steps do
    local s2 = steps[j]
    if s2.ins ~= st.ins or s2.gate then break end
    if s2.bossStep and ns.BossStepKilled(s2) then later = true break end
  end
  -- a run with no quest: a boss you went past is behind you too (no quest line waits there)
  if later and (st.run or ns.BossStepOptional(st, log)) then return true end
  -- every quest of the step already turned in (the kill was in another session, or before a
  -- /reload): nothing is left to do there, whatever the kill record says
  if #st.acts > 0 and ns.IsDone then
    local all = true
    for _, n in ipairs(st.acts) do
      if not (n.q and ns.IsDone(n.q)) then all = false; break end
    end
    if all then return true end
  end
  return false
end
ns.BossStepDone = BossStepDone
-- The boss panel's right-click marked this boss not killed: its steps done only from the kill
-- open again (a step ticked by hand stays ticked).
function ns.UndoBossStepKill(dkey, en)
  local any = false
  for _, st in ipairs(Steps()) do
    if st.bossStep and st.ins == dkey and st.bossEn == en and Manual(st) == "kill" then SetManual(st, nil); any = true end
  end
  return any
end
-- Out of a dungeon: its boss steps with nothing for you count as skipped.
function ns.SkipOptionalBosses(dkey)
  local log = ns.LogEntries()
  for _, st in ipairs(Steps()) do
    if st.bossStep and st.ins == dkey and not Manual(st) and ns.BossStepOptional(st, log) then SetManual(st, "skip") end
  end
end
-- =====================================================================
--  A boss step's lines: path, tactic (2-3 lines), loot for you
-- =====================================================================
local function Pick2(v) if type(v) ~= "table" then return v end return (ns.lang == "fr" and v[2]) or v[1] end
-- "west from the entrance, up the ramp" (ns.BOSS_PATH, our own words) or nil
function ns.BossPathText(dkey, en)
  local t = ns.BOSS_PATH and ns.BOSS_PATH[dkey]
  local v = t and en and t[en]
  return v and Pick2(v) or nil
end
-- at most n sentences of a longer text, and about MAXTIP characters (cut at a word, "..."): a
-- sentence ends at ".", "!" or "?" followed by a space and a capital, never after an abbreviation
local ABBR = { Mr = true, Mrs = true, Dr = true, St = true, Mt = true, Lt = true, Sgt = true, Capt = true, Gen = true, Jr = true, Sr = true, vs = true, etc = true, ["e.g"] = true, ["i.e"] = true }
local MAXTIP = 220
local function Sentences(text, n)
  local cut, k, pos = nil, 0, 1
  while true do
    local a, b = text:find("[%.!?]%s+", pos)
    if not a then break end
    local nextc = text:sub(b + 1, b + 1)
    local word = text:sub(1, a - 1):match("([%a%.]+)$")
    local isEnd = nextc:find("^[%u\195\197\"'(]") ~= nil
      and not (text:sub(a, a) == "." and word and ABBR[word])
    if isEnd then
      k = k + 1
      cut = a
      if k >= n then break end
    end
    pos = b + 1
  end
  local out = (cut and k >= n) and text:sub(1, cut) or text
  if #out > MAXTIP then
    local s = out:sub(1, MAXTIP)
    local sp = s:match("^.*()%s")
    if sp and sp > MAXTIP / 2 then s = s:sub(1, sp - 1) end
    -- never end inside a UTF-8 character
    s = s:gsub("[\192-\255][\128-\191]*$", "")
    out = s:gsub("[%s,;:]+$", "") .. "..."
  end
  return out
end
-- NaowhForever's tip for the boss (read live when it is loaded), else our own note
-- (ns.BOSS_NOTES: { role, English, French } per line, "{Ability}" highlighted), else nil
function ns.BossTacticText(st)
  if not (st and st.bossStep) then return nil end
  local tip = st.bossTip
  local bo = ns.BossOrder and ns.BossOrder(st.ins)
  local B = bo and bo.list and bo.list[st.bossIdx]
  if B and B.en == st.bossEn and B.tip then tip = B.tip end
  local head
  if type(tip) == "string" and tip ~= "" and not (issecretvalue and issecretvalue(tip)) then
    head = Hex(T.text) .. Sentences(tip, 3) .. "|r"
  end
  -- our own notes too, after the journal's tip: the counters it does not give (the Shade of
  -- Eranikus' sleep: "we get killed by the sleep all the time")
  local notes = ns.BOSS_NOTES and ns.BOSS_NOTES[st.ins] and ns.BOSS_NOTES[st.ins][st.bossEn]
  if not notes then return head end
  local ROLE = { tank = L.ROLE_TANK, heal = L.ROLE_HEAL, all = L.ROLE_ALL }
  local lines = {}
  for k, ln in ipairs(notes) do
    if k > 3 then break end
    local txt = (ns.lang == "fr" and ln[3]) or ln[2] or ""
    txt = txt:gsub("{([^}]+)}", function(a) return Hex(T.warn) .. a .. "|r" .. Hex(T.text) end)
    lines[#lines + 1] = Hex(T.muted) .. (ROLE[ln[1]] or L.ROLE_ALL) .. "|r  " .. Hex(T.text) .. txt .. "|r"
  end
  if #lines == 0 then return head end
  return (head and (head .. "\n") or "") .. table.concat(lines, "\n")
end
local ARROW_UP = "|TInterface\\AddOns\\WLHelper\\Media\\Icons\\arrow_up:14:14:0:-1:128:128:0:128:0:128:76:208:122|t"
-- The boss's tactics said to the group (report: "the tactics should go to the chat"): the party,
-- raid or instance channel, plain text, "[WL] Boss : ..." then one message per line, 250 letters
-- at most each; alone: printed for you only. -> true when sent
function ns.AnnounceTactics(st)
  local text = st and ns.BossTacticText and ns.BossTacticText(st)
  if type(text) ~= "string" or text == "" then ns.Print(L.TAC_NONE); return false end
  text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|T.-|t", "")
  local boss = ns.BossStepName and ns.BossStepName(st) or "?"
  local channel
  if IsInRaid and IsInRaid() then channel = "RAID"
  elseif IsInGroup and LE_PARTY_CATEGORY_INSTANCE and IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then channel = "INSTANCE_CHAT"
  elseif IsInGroup and IsInGroup() then channel = "PARTY" end
  local first = true
  for line in (text .. "\n"):gmatch("(.-)\n") do
    line = line:gsub("^%s+", ""):gsub("%s+$", "")
    if line ~= "" then
      local msg = (first and ("[WL] " .. boss .. " : ") or "") .. line
      first = false
      while #msg > 0 do
        local part = msg:sub(1, 250)
        msg = msg:sub(251)
        if channel and SendChatMessage then pcall(SendChatMessage, part, channel) else ns.Print(part) end
      end
    end
  end
  return channel ~= nil
end

-- Naowh Forever's BiS list (WP.NaowhBiS) for an item and the player's current spec: rank 1 (BiS)
-- or 2 (second choice), its short badge ("BiS" + star / "2e choix") and colour, and a shorter
-- form for the label under a 48 px icon ("BiS" / "2e" / "BiS 40"). nil when Naowh is absent or
-- switched off, the item unranked or ranked lower, or the item a secret value.
local BIS_STAR = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:%d:%d:0:0|t"
function ns.BisBadge(item, size)
  if item == nil or (issecretvalue and issecretvalue(item)) then return nil end
  local WP = ns.Writs and ns.Writs.WP
  local NB = WP and WP.NaowhBiS
  if not (NB and NB.Available and NB.Rank) then return nil end
  local okA, on = pcall(NB.Available)
  if not (okA and on) then return nil end
  -- our spec (talents or the settings' choice); a guessed default asks Naowh's own active list
  local W, spec = WP.Weights, nil
  if W and W.Spec then
    local okS, s = pcall(W.Spec)
    local okG, guessed = pcall(function() return W.SpecGuessed and W.SpecGuessed() end)
    if okS and s and not (okG and guessed) then spec = s end
  end
  local ok, rank = pcall(NB.Rank, item, spec)
  if not ok or (rank ~= 1 and rank ~= 2) then return nil end
  local r, g, b = 1, 0.5, 0
  if NB.Color then
    local okC, cr, cg, cb = pcall(NB.Color, rank)
    if okC and cr then r, g, b = cr, cg, cb end
  end
  local text = rank == 1 and L.BIS_1 or L.BIS_2
  local short = rank == 1 and L.BIS_1 or L.BIS_2S
  -- an empty Naowh list falls back on Naowh's gear for a level: "BiS niv. 40" ("BiS 40" short)
  if rank == 1 and NB.Source and NB.Label then
    local okB, _, bracket = pcall(NB.Source, item, spec)
    if okB and bracket then
      local okL, lab = pcall(NB.Label, 1, bracket)
      if okL and type(lab) == "string" and lab ~= "" then
        text = lab
        if type(bracket) == "number" and lab ~= L.BIS_1 then short = L.BIS_LVS:format(bracket) end
      end
    end
  end
  if rank == 1 then size = size or 12; text = text .. " " .. BIS_STAR:format(size, size) end
  return rank, text, r, g, b, short
end
-- true when Naowh's own item tooltip line (its active list) already says this rank
function ns.BisNaowhTip(item, rank)
  if item == nil or rank == nil or (issecretvalue and issecretvalue(item)) then return false end
  local WP = ns.Writs and ns.Writs.WP
  local NB = WP and WP.NaowhBiS
  if not (NB and NB.RankTipOn and NB.Rank) then return false end
  local okT, on = pcall(NB.RankTipOn)
  if not (okT and on) then return false end
  local ok, r = pcall(NB.Rank, item)
  return ok and r == rank
end
-- the badge as coloured chat text ("|cffff8000BiS|r [star]"), or nil
function ns.BisBadgeText(item, size)
  local rank, text, r, g, b = ns.BisBadge(item, size)
  if not rank then return nil end
  -- the word coloured, the star after it (a texture keeps its own colours)
  local word, star = text:match("^(.-)( |T.*)$")
  return Hex({ r, g, b }) .. (word or text) .. "|r" .. (star or "")
end
-- the loot that matters: BiS first, an upgrade (green arrow and its gain), a quest item; 3 lines at most
function ns.BossLootText(st)
  local ok, list = pcall(ns.BossStepLoot, st)
  if not (ok and type(list) == "table" and #list > 0) then return nil end
  local lines = {}
  for k, it in ipairs(list) do
    if k > 3 then break end
    local ic = it.icon and ("|T" .. tostring(it.icon) .. ":14:14:0:-1:64:64:5:59:5:59|t ") or ""
    local name = it.link or it.name or "?"
    local bis = ns.BisBadgeText(it.link or it.id, 12)
    if bis then name = name .. "  " .. bis end
    -- how often it drops (Naowh's Dungeon Journal)
    if it.chance then name = name .. Hex(T.muted) .. "  " .. string.format(L.LOOT_CHANCE, it.chance) .. "|r" end
    if it.up then
      lines[#lines + 1] = ic .. name .. "  " .. ARROW_UP .. Hex(T.ok) .. (it.text or "") .. "|r"
    elseif it.quest then
      lines[#lines + 1] = ic .. name .. Hex(T.muted) .. "  ·  " .. L.LOOT_QUEST .. "|r"
    else
      -- BiS without a gain over what you wear: the badge says it
      lines[#lines + 1] = ic .. name
    end
  end
  return table.concat(lines, "\n")
end

IsStepDoneRaw = function(log, i)
  local st = Steps()[i]
  if not st then return false end
  if ManualHolds(log, st) then return true end
  if st.bossStep then return BossStepDone(log, i, st) end
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

-- The dungeon the guide is about right now: the one you stand in, else the step on screen's.
local function GuideDungeon()
  local k = InsideKey()
  if k then return k end
  local st = f and Steps()[f.view or f.auto or 1]
  if not st then return nil end
  return (ns.StepDungeon and ns.StepDungeon(st)) or st.ins or st.d or st.gate
end
ns.GuideDungeon = GuideDungeon

-- How many of the route's quests in your log can be shared now (0 outside a group). Asked of the
-- game at most every quarter second: a render can run several times in a row.
local shareN, shareAt = 0, -10
local function ShareN()
  if not (IsInGroup and IsInGroup()) or not ns.ShareCount then return 0 end
  local now = (GetTime and GetTime()) or 0
  if now - shareAt > 0.25 or now < shareAt then
    shareAt = now
    local ok, n = pcall(ns.ShareCount)
    shareN = (ok and type(n) == "number") and n or 0
  end
  return shareN
end
local function ShareLabel(n)
  if n and n > 0 then return ns.Plural(n, "SHARE_N1", "SHARE_N", n) end
  return L.SHARE_SHORT
end
-- every share button (footer, inside band, Actions menu): the count in the label, greyed at 0
local function SetShareButton(b, n, withLabel)
  if not b then return end
  -- a share running (this button or the overview's): greyed, "Sharing" until it ends
  local busy = ns.pushBusy and true or false
  -- in combat the game blocks the share: « Après le combat », greyed, until combat ends
  local combat = (busy or n > 0) and ns.ShareInCombat and ns.ShareInCombat() or false
  if withLabel then b:SetText(combat and L.SHARE_AFTER or (busy and L.SUM_SHARING or ShareLabel(n))) end
  if n > 0 and not busy and not combat then b:Enable() else b:Disable() end
  b.disabledReason = combat and L.SHARE_AFTER_TT or (busy and L.SUM_SHARING or ((IsInGroup and IsInGroup()) and L.NOSHARE or L.NOGROUP_TIP))
end
local function DoShare()
  ns.ShareQuests(); shareAt = -10
  if ns.Render then ns.Render() end
  if C_Timer and C_Timer.After and ns.Render then C_Timer.After(1, ns.Render) end
end

-- Chapters of the route: before / inside / after each dungeon (Engine.lua sets the phases).
-- -> key, phase, dungeon of a step (nil when the engine has no phases)
local PH_S = { before = "PH_BEFORE_S", inside = "PH_INSIDE_S", after = "PH_AFTER_S" }
local TAB_PH = { "before", "inside", "after" }
local TAB_K = { before = "TAB_BEFORE", inside = "TAB_INSIDE", after = "TAB_AFTER" }
local function StepChapter(st)
  if not (st and ns.StepPhase) then return nil end
  local ph = ns.StepPhase(st)
  local dk = ns.StepDungeon and ns.StepDungeon(st)
  if not (ph and PH_S[ph] and dk and ns.D[dk]) then return nil end
  return ph .. "@" .. dk, ph, dk
end
-- done / total steps per chapter, counted over the whole route (the same count as ns.PhaseProgress)
local function ChapterCounts(log)
  local out = {}
  for i, st in ipairs(Steps()) do
    local key = StepChapter(st)
    if key then
      local c = out[key] or { done = 0, total = 0 }
      out[key] = c
      c.total = c.total + 1
      if IsStepDone(log, i) then c.done = c.done + 1 end
    end
  end
  return out
end

-- how many dungeons the route goes through (the chapter names its dungeon only when there are several)
local function RouteDungeons()
  local r = ns.route
  if not r then return 0 end
  if r.wlDungeons and r.wlDungeonsN == #(r.steps or {}) then return r.wlDungeons end
  local seen, n = {}, 0
  for _, st in ipairs(r.steps or {}) do
    local dk = ns.StepDungeon and ns.StepDungeon(st) or (st.d or st.gate or st.ins)
    if dk and not seen[dk] then seen[dk] = true; n = n + 1 end
  end
  r.wlDungeons, r.wlDungeonsN = n, #(r.steps or {})
  return n
end

-- What a check-list still misses: quests not in the log, and whether a needed key is missing.
-- An optional check-list quest (the dungeon is done without it, BeforeReason false): its row
-- says "Optional" and it does not hold the banner back
function ns.GuideOptionalCheck(nd, dk)
  if not (nd and nd.kind == "h" and nd.q and ns.GuideBeforeReason) then return false end
  local ok, r = pcall(ns.GuideBeforeReason, nd.q, dk)
  return ok and r == false
end

local function ReadyState(log, st)
  local miss, total, opt = 0, 0, 0
  for _, nd in ipairs(st.checks or {}) do
    total = total + 1
    if not ns.NodeOK(log, nd) then
      if ns.GuideOptionalCheck(nd, st.gate or st.ins) then opt = opt + 1 else miss = miss + 1 end
    end
  end
  local keyMissing = false
  for _, k in ipairs(ns.KeyLines and ns.KeyLines(st.gate or st.ins) or {}) do if k[3] and not k[2] then keyMissing = true end end
  return miss, total, keyMissing, opt
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

-- Live progress of one objective ("3/5"), from the quest log; nil when unknown. The card, the
-- overview, the tracker and the route all read ns.ObjCount (Engine.lua).
local function LiveCount(log, qid, oi)
  local q = ns.Q[qid]
  local o = q and q.o and q.o[oi]
  if o then return ns.ObjCount(log, qid, o) end
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
      -- an objective spread over an area (o.area): the spawn nearest to you in the nearest camp,
      -- before the game's quest area (a ring round an island has its middle there, on dry land)
      local a = n.kind == "o" and ns.AreaOf and ns.AreaOf(n)
      local am, ax, ay
      if a then am, ax, ay = ns.AreaFollow(a) end
      if am == n.loc.m and ax then x, y = ax, ay
      elseif n.kind == "o" then
        local gx, gy = GamePOI(n.q, n.loc.m)
        if gx then x, y = gx, gy end
      end
      local k = ns.PKey(n.loc.m, x, y)
      if not seen[k] then seen[k] = true; table.insert(pts, { n.loc.m, x, y, n.npc or ns.QName(n.q) }) end
    elseif n.noLoc and n.kind == "o" and (all or not ns.NodeOK(log, n)) then
      -- an objective with no place in our data: the game's own quest area, on the map you stand
      -- in first, then on the quest giver's map
      local here = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
      for _, m in ipairs({ here or false, n.mapHint or false }) do
        local gx, gy
        if m then gx, gy = GamePOI(n.q, m) end
        if gx then
          local k = ns.PKey(m, gx, gy)
          if not seen[k] then seen[k] = true; table.insert(pts, { m, gx, gy, n.npc or ns.QName(n.q) }) end
          break
        end
      end
    end
  end
  if #pts == 0 and st.ins then
    local d = ns.D[st.ins]
    if d and d.e and d.e.m and not InInstanceOf(st.ins) then table.insert(pts, { d.e.m, d.e.x, d.e.y, ns.DName(st.ins) }) end
  end
  -- inside the instance, a point on an outdoor map (the giver's spot outside, the entrance) means
  -- nothing: the arrow said "Tu y es · Maraudon" and the game's pin sat on a wall. Keep only the
  -- points on the map you stand on; with none, the big button offers the dungeon map instead.
  if st.ins and InInstanceOf(st.ins) and #pts > 0 then
    local here = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
    if issecretvalue and here ~= nil and issecretvalue(here) then here = nil end
    local keep = {}
    for _, p in ipairs(pts) do if here and p[1] == here then keep[#keep + 1] = p end end
    pts = keep
  end
  return pts
end
ns.StepPoints = StepPoints

-- =====================================================================
--  Textes d'une étape
-- =====================================================================
-- The class token a class quest shows: yours when the quest lists it ("WARRIOR,PALADIN,SHAMAN" on
-- a Paladin: PALADIN), else the first one
-- A quest's objective sentence for the card: the French one when we have it, unless it is the
-- quest's flavour text (it talks to "<nom>", "<classe>"): then the objective itself
function ns.GuideObjSentence(q)
  if not q then return nil end
  local fr = ns.lang == "fr" and q.of or nil
  if type(fr) == "string" and fr:find("<%a+>") then fr = nil end
  return fr or ns.T(q.oe)
end

-- Where a prerequisite stands in its chain: "étape 3 sur 9 avant « X »"; when the chain's quests
-- share one name, "partie 1 sur 2 de la suite « X »" (never "before X" on X itself); others it
-- also leads to: " (et 1 autre quête)". row: the row's capitalised form.
function ns.GuideChainText(nd, row)
  local lead = nd and nd.forQ and nd.forQ[1]
  if not (lead and nd.ci and nd.cn) then return nil end
  local ln = ns.QName(lead)
  local t
  -- "part 1 of 1 of X" says nothing (report: unclear): the "needed for X" line already does
  if ln == ns.QName(nd.q) and nd.cn <= 1 and #nd.forQ <= 1 then return nil end
  if ln == ns.QName(nd.q) then t = (row and L.CH_PART or L.CARD_PART):format(nd.ci, nd.cn, ln)
  else t = (row and L.CH_BEFORE or L.CARD_CHAIN):format(nd.ci, nd.cn, ln) end
  local more = #nd.forQ - 1
  if more > 0 then t = t .. ns.Plural(more, "CARD_PLUS_P1", "CARD_PLUS_P", more) end
  return t
end

function ns.GuideClassTok(c)
  if type(c) ~= "string" then return nil end
  local ok, _, mine = pcall(UnitClass, "player")
  if ok and type(mine) == "string" then
    for tok in c:gmatch("[^,]+") do if tok == mine then return tok end end
  end
  return (c:match("^[^,]+"))
end

local function ZoneName(m)
  local info = C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(m)
  return info and info.name or ""
end

-- noZone: the card says the place on its own line (the step list and the tracker keep "Zone: NPC")
local function StepTitle(st, noZone)
  if st.gate then return L.GATE_T:format(ns.DName(st.gate)) end
  if st.split then
    local pr = st.parts and st.parts > 1 and ("  (" .. st.part .. "/" .. st.parts .. ")") or ""
    if st.bossStep then return L.BOSS_STEP_N:format(st.bossIdx, st.bossN or st.bossIdx, ns.BossStepName(st)) end
    if st.way then return L.IN_WAY:format(st.wayName or "?") end
    if st.bossIdx == 0 then return L.IN_START .. pr end
    if st.bossIdx == 999 then
      -- "trash loot" only when every action is a drop; takes, turn-ins and searches: plain wording
      local loot = #(st.acts or {}) > 0
      for _, n in ipairs(st.acts or {}) do
        local o = n.oneObj or (n.kind == "o" and n.obj) or nil
        if not (n.kind == "c" or n.kind == "o") or not (o and o.k == "item" and o.src) then loot = false; break end
      end
      return (loot and L.IN_TRASH or L.IN_TRASH_ANY) .. pr
    end
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
-- the widest the guide gets: 760, never more than 96 % of the screen (UI units)
local function MaxW()
  local uw = ns.ScreenSize and ns.ScreenSize() or num(UIParent:GetWidth()) or 1366
  return math.max(WMIN, math.min(WMAX, math.floor(uw * 0.96)))
end
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

-- A quest's level in the summary's words (Overview.lua writes the same line on its cards):
-- "Quête niv. 36 · facile · se prend dès le niv. 30", or the level you still need, in orange.
-- The band follows the game's own quest colours, else the same thresholds as the summary.
local BAND_OF = { impossible = "red", verydifficult = "orange", difficult = "yellow", standard = "green", trivial = "grey" }
local function LevelBand(ql, plvl)
  if GetQuestDifficultyColor and type(QuestDifficultyColors) == "table" then
    local ok, c = pcall(GetQuestDifficultyColor, ql)
    if ok and c then
      for k, v in pairs(QuestDifficultyColors) do if v == c and BAND_OF[k] then return BAND_OF[k] end end
    end
  end
  local d = ql - plvl
  if d >= 5 then return "red" elseif d >= 3 then return "orange" elseif d >= -2 then return "yellow" end
  local g
  if GetQuestGreenRange then local ok, v = pcall(GetQuestGreenRange); g = ok and num(v) or nil end
  g = g or (plvl <= 5 and 5 or plvl < 40 and 5 + math.floor(plvl / 10) or 1 + math.floor(plvl / 5))
  return (-d <= g) and "green" or "grey"
end
-- the summary's strings are there only once Overview.lua loaded (a missing key reads as its name)
local function HasL(k) local v = L[k]; return type(v) == "string" and v ~= k end
local function LevelFact(qid, s)
  local q = ns.Q[qid]
  local ql = q and num(q.l)
  if not (ql and HasL("SUM_FACT_LV")) then return nil end
  local okL, plvl = pcall(function() return num(UnitLevel("player")) end)
  plvl = (okL and plvl) or 1
  local seg = {}
  local band = (s ~= "done") and LevelBand(ql, plvl) or nil
  local bw = band and HasL("SUM_BAND_" .. band:upper()) and L["SUM_BAND_" .. band:upper()] or nil
  local lc = SW().LevelColor and SW().LevelColor(ql) or T.text
  seg[1] = Hex(lc) .. L.SUM_FACT_LV:format(ql) .. (bw and (" · " .. bw) or "") .. "|r"
  local r = num(q.r)
  if s == "none" and r and r > plvl then
    -- said on a line of its own (report: "it is not clear at all that I do not have the level")
  elseif s == "none" and r and r < ql and HasL("SUM_FROM") then
    seg[#seg + 1] = L.SUM_FROM:format(r)
  end
  return table.concat(seg, " · ")
end
ns.GuideLevelFact = LevelFact
-- true when the level line already says "se prend au niv. N, tu es niv. M" (SUM_NEED): only then is
-- the red BLOCKED line a repeat; any other reason PrereqProblem gives still shows
local function NeedShown(qid, s)
  local q = ns.Q[qid]
  local r = q and num(q.r)
  if not (r and s == "none") then return false end
  local okL, plvl = pcall(function() return num(UnitLevel("player")) end)
  plvl = (okL and plvl) or 1
  return r > plvl
end

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
  -- the arrow goes where the step on screen is (Refresh keeps it there until you go back)
  if WLDTDB.autoWay and f.view <= n and ns.SetPoints then
    local log = ns.LogEntries()
    local pts = StepPoints(log, Steps()[f.view], false)
    local sig = f.view .. ":" .. #pts
    for _, p in ipairs(pts) do sig = sig .. p[2] .. p[3] end
    if sig ~= f.sig then f.sig = sig; f.wpKey = nil; ns.SetPoints(pts, true) end
  end
  Render()
end

-- who to target for a line (Engine.lua, shared with the tracker and the target key)
local NodeTargets = ns.NodeTargets

-- log (optional): each objective starts with its live count from the quest log ("3/5", green when done).
-- -> lines, live (true when the log gave at least one objective's state), sources (the
-- "Drops from: ..." lines alone)
local function ObjectiveLines(n, log)
  local q = ns.Q[n.q]; if not q then return {}, false, {} end
  local lines, live, srcLines = {}, false, {}
  local objs = q.o or {}
  if n.kind == "o" and n.obj then objs = { n.obj } end
  if n.oneObj then objs = { n.oneObj } end
  for _, o in ipairs(objs) do
    local s = (o.c and o.c > 1 and (o.c .. " x ") or "") .. (o.n or "")
    if log then
      local a, b, fin = ns.ObjCount(log, n.q, o)
      if fin ~= nil then live = true end
      if a and b then
        s = Hex(fin and T.ok or T.fg) .. a .. "/" .. b .. "|r  " .. (o.n or "")
      end
    end
    if o.src and o.src[1] then
      local srcs = {}
      for _, x in ipairs(o.src) do
        table.insert(srcs, x[1] .. ((x[2] and x[2] > 0 and x[2] < 100) and (" " .. math.floor(x[2] + 0.5) .. " %") or ""))
      end
      -- the sources on their own line under the objective, not glued after "0/1"
      if s ~= "" then table.insert(lines, s) end
      s = "    " .. Hex(T.muted) .. L.TT_DROPS:format(table.concat(srcs, " · ")) .. "|r"
      srcLines[#srcLines + 1] = Hex(T.muted) .. L.TT_DROPS:format(table.concat(srcs, " · ")) .. "|r"
    end
    if s ~= "" then table.insert(lines, s) end
  end
  return lines, live, srcLines
end

-- The objectives of a line as the player should read them: ours with their live count, else the
-- game's own ones when the quest is in the log (our data can be thin: "Ancient Mana Crystal: 0/8"
-- only comes from the game). -> lines (without "- "), true when they come from the game
local function ObjectiveBlock(n, log, s)
  local ours, live, srcs = ObjectiveLines(n, log)
  if (s == "on" or s == "ready") and (#ours == 0 or not live) and ns.GameObjectives then
    local game = ns.GameObjectives(n.q, log)
    if #game > 0 then
      -- a line about one objective keeps only that one: the game line naming it, else the one at
      -- the same place in our list (frFR names never match ours); none -> our own single line
      local one = n.oneObj or (n.kind == "o" and n.obj) or nil
      if one then
        local pick
        local nm = type(one.n) == "string" and one.n:lower() or nil
        if nm and nm ~= "" then
          for _, g in ipairs(game) do
            if type(g.text) == "string" and g.text:lower():find(nm, 1, true) then pick = g; break end
          end
        end
        if not pick then
          local qo = (ns.Q[n.q] or {}).o or {}
          if #qo == #game then
            for i, o in ipairs(qo) do
              if o == one or (o.n and o.n == one.n) then pick = game[i]; break end
            end
          end
        end
        game = pick and { pick } or {}
      end
    end
    if #game > 0 then
      local out = {}
      for _, g in ipairs(game) do out[#out + 1] = Hex(g.fin and T.ok or T.fg) .. g.text .. "|r" end
      for _, sl in ipairs(srcs) do out[#out + 1] = { src = sl } end
      return out, true
    end
  end
  local out = {}
  for _, l2 in ipairs(ours) do
    -- a sources line stands on its own (no "- " before it)
    if l2:sub(1, 4) == "    " then out[#out + 1] = { src = l2:sub(5) } else out[#out + 1] = l2 end
  end
  return out, false
end
ns.ObjectiveBlock = ObjectiveBlock

-- the game's own icon for each kind of line (quest marks), HD icons for the rest
-- "outside" (o) has no icon: its word ("Dehors") already says it, and a flag there meant nothing
-- more (icon audit, guide)
local KICON = { a = "take", t = "turn", c = "boss", h = "take" }
local function SetKindIcon(tex, nd)
  if nd.kind == "i" then
    local id = nd.items and nd.items[1]
    tex:SetVertexColor(1, 1, 1)
    SetIcon(tex, nil, (id and ns.ItemIcon(id)) or "Interface\\Icons\\INV_Misc_Bag_10", true)
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
  -- its own height (its rows), top-aligned with the guide, on the side with more room (PlaceList)
  l:SetPoint("TOPRIGHT", f, "TOPLEFT", -4, 0); l:SetHeight(200)
  ns.Flat(l, T.bg, T.cardEdge)
  l.head = CreateFrame("Frame", nil, l)
  l.head:SetPoint("TOPLEFT"); l.head:SetPoint("TOPRIGHT"); l.head:SetHeight(HEADER)
  -- an X at the right of its header closes it (players never found the "Steps" button to fold it)
  l.close = SW().IconButton(l.head, "close", 20, function() return { L.TT_LIST_CLOSE, L.TT_LIST_CLOSE_CLICK } end, function()
    l:Hide(); WLDTDB.list = false; Render()
  end)
  l.close:SetPoint("RIGHT", -10, 0)
  l.title = Text(l.head, ns.F.heading, T.fg); l.title:SetPoint("LEFT", 16, 0); l.title:SetPoint("RIGHT", l.close, "LEFT", -8, 0); l.title:SetJustifyV("MIDDLE")
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
    -- a chapter header (before / inside / after a dungeon): its name, its progress, a divider
    row.hdr = Text(row, ns.F.body, T.fg); row.hdr:SetPoint("BOTTOMLEFT", 8, 6); row.hdr:SetPoint("RIGHT", -52, 0)
    row.hdrN = Text(row, ns.F.meta, T.muted); row.hdrN:SetPoint("BOTTOMRIGHT", -8, 7); row.hdrN:SetWidth(44); row.hdrN:SetJustifyH("RIGHT")
    row.rule = ns.Rule(row, T.divider); row.rule:SetPoint("BOTTOMLEFT", 4, 0); row.rule:SetPoint("BOTTOMRIGHT", -4, 0)
    row.hdr:Hide(); row.hdrN:Hide(); row.rule:Hide()
    row:SetScript("OnClick", function(self) ns.GoTo(self.i or self.go) end)
    row:SetScript("OnMouseDown", function(self) self.press:Show() end)
    row:SetScript("OnMouseUp", function(self) self.press:Hide() end)
    row:SetScript("OnEnter", function(self)
      if self.chapter then
        ns.ShowTip(self, { self.chapter, self.chapterState, L.TT_CHAPTER_CLICK })
        return
      end
      local st = Steps()[self.i]; if not st then return end
      local lines = { StepTitle(st) }
      if self.state then table.insert(lines, self.state) end
      table.insert(lines, L.TT_LISTROW)
      ns.ShowTip(self, lines)
    end)
    row:SetScript("OnLeave", ns.HideTip)
    -- one line: a long step name shows in full in the row's tooltip
    ns.ClampLabel(row.txt, nil, row)
    ns.ClampLabel(row.hdr, nil, row)
    l.rows[r] = row
  end
  -- at the bottom: "Start the route over" (/wlh reset), a second click within 4 s confirms (T-84)
  l.restart = LabelBtn(l, L.M_RESTART, 24, "secondary", function() if ns.ResetRoute then ns.ResetRoute() end end,
    function() return { L.M_RESTART, L.TT_RESTART, L.RESTART_CLICK } end)
  if l.restart.SetConfirm then l.restart:SetConfirm(L.RESTART_CONFIRM) end
  l.restart:SetPoint("BOTTOMLEFT", 12, 8); l.restart:SetWidth(LISTW - 24)
  -- more steps than rows: how many are above / below (the wheel scrolls)
  l.hint = Text(l, ns.F.foot, T.muted); l.hint:SetPoint("BOTTOMLEFT", 16, 8 + 24 + 6); l.hint:SetPoint("BOTTOMRIGHT", -12, 8 + 24 + 6)
  l.hint:SetJustifyV("MIDDLE"); l.hint:Hide()
  ns.ClampLabel(l.hint, nil, l)
  l:EnableMouseWheel(true)
  l:SetScript("OnMouseWheel", function(self, delta)
    local max = math.max(0, (self.nEntries or #Steps()) - (self.visible or 1))
    self.offset = math.max(0, math.min(max, self.offset - delta * 3))
    Render()
  end)
  f.list = l
end

-- The step list opens on the side of the guide with more screen room: left or right. Asked again
-- at every render and when the guide is dropped after a move.
local function ListSide()
  if not f then return "left" end
  local fsc, usc = num(f:GetEffectiveScale()), num(UIParent:GetEffectiveScale())
  local sc = (fsc and usc and fsc > 0 and usc > 0) and (fsc / usc) or 1
  local l, r, sw = num(f:GetLeft()), num(f:GetRight()), num(UIParent:GetWidth())
  if not (l and r and sw) or sw <= 0 then return f.listSide or "left" end
  local leftRoom, rightRoom = l * sc, sw - r * sc
  return (rightRoom > leftRoom) and "right" or "left"
end
ns.GuideListSide = ListSide
local function PlaceList()
  if not (f and f.list) then return end
  local side = ListSide()
  if side == f.listSide and f.list.placed then return end
  f.listSide, f.list.placed = side, true
  f.list:ClearAllPoints()
  if side == "right" then f.list:SetPoint("TOPLEFT", f, "TOPRIGHT", 4, 0)
  else f.list:SetPoint("TOPRIGHT", f, "TOPLEFT", -4, 0) end
end
ns.PlaceGuideList = PlaceList
-- the "Steps" button's chevron points to where the list opens (or back, to close it)
local function ListChevron()
  local shown = WLDTDB.list == true
  local right = (f.listSide == "right")
  if shown then return right and "chevron_left" or "chevron_right" end
  return right and "chevron_right" or "chevron_left"
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

-- The list's entries: a chapter header each time the chapter changes (before / inside / after a
-- dungeon, with its progress), then its steps. -> entries, position of each step in entries
local function ListEntries(log)
  local steps = Steps()
  local counts = ChapterCounts(log)
  local out, pos, last = {}, {}, nil
  for i, st in ipairs(steps) do
    local key, ph, dk = StepChapter(st)
    if key and key ~= last then
      out[#out + 1] = { key = key, ph = ph, dk = dk, first = i, c = counts[key] }
    end
    last = key
    -- the header leads to the chapter's first open step (else its first step)
    local hdr = out[#out]
    if key and hdr and hdr.key == key and not hdr.go and not IsStepDone(log, i) then hdr.go = i end
    out[#out + 1] = { i = i }
    pos[i] = #out
  end
  for _, e in ipairs(out) do if e.key and not e.go then e.go = e.first end end
  return out, pos
end

local function RenderList(log)
  local l = f.list
  PlaceList()
  if not l:IsShown() then return end
  local steps = Steps()
  local entries, pos = ListEntries(log)
  l.nEntries = #entries
  -- as many rows as entries, up to what the screen holds (at least 10); the wheel scrolls the rest
  -- (32: "Start the route over" at the foot)
  local avail = math.max(10, math.floor((ScreenCap() - (HEADER + 1 + 4) - 8 - 20 - 32) / LISTH))
  l.visible = math.max(1, math.min(avail, LISTROWS, #entries))
  local max = math.max(0, #entries - l.visible)
  -- the step on screen stays in the list when it changes (done steps above stay reachable with the wheel)
  if f.view ~= l.lastView then
    l.lastView = f.view
    local v = pos[math.min(f.view or 1, #steps)] or 1
    if v <= l.offset then l.offset = math.max(0, v - 3)
    elseif v > l.offset + l.visible then l.offset = v - l.visible + 1 end
  end
  if l.offset > max then l.offset = max end
  if l.offset < 0 then l.offset = 0 end
  if #entries > l.visible then
    -- steps (not headers) above and below the rows on screen
    local above, below = 0, 0
    for k, e in ipairs(entries) do
      if e.i then
        if k <= l.offset then above = above + 1 elseif k > l.offset + l.visible then below = below + 1 end
      end
    end
    l.hint:SetText(L.LIST_MORE:format(above, below)); l.hint:Show()
  else l.hint:Hide() end
  local doneCount = 0
  for k = 1, #steps do if IsStepDone(log, k) then doneCount = doneCount + 1 end end
  l.title:SetText(L.STEPS_N:format(doneCount, #steps))
  l:SetHeight(HEADER + 1 + 4 + l.visible * LISTH + (l.hint:IsShown() and 20 or 0) + 8 + 24 + 8)
  if not l.restart.armed then l.restart:SetText(L.M_RESTART) end
  local viewKey = StepChapter(steps[f.view or 0])
  for r, row in ipairs(l.rows) do
    local e = entries[l.offset + r]
    if e and r <= l.visible and e.key then
      -- chapter header: "Before the dungeon: Zul'Farrak" and "3/18" (green once all done)
      row.i = nil; row.go = e.go; row:Show()
      local name = L[PH_S[e.ph]] .. L.COLON .. (ns.DName(e.dk) or e.dk)
      local c = e.c or { done = 0, total = 0 }
      local all = c.total > 0 and c.done == c.total
      row.chapter = name
      row.chapterState = L.CH_PROGRESS:format(c.done, c.total)
      row.hdr:SetText(name); row.hdr:Show()
      local hc = (e.key == viewKey) and T.fg or T.text
      row.hdr:SetTextColor(hc[1], hc[2], hc[3])
      row.hdrN:SetText(c.done .. "/" .. c.total); row.hdrN:Show()
      local nc = all and T.ok or T.muted
      row.hdrN:SetTextColor(nc[1], nc[2], nc[3])
      row.rule:Show()
      row.check:Hide(); row.num:Hide(); row.kind:Hide(); row.txt:Hide(); row.sel:Hide()
      row.state = nil
    elseif e and r <= l.visible then
      local i = e.i
      local st = steps[i]
      row.i = i; row.go = nil; row.chapter = nil; row:Show()
      row.hdr:Hide(); row.hdrN:Hide(); row.rule:Hide()
      row.num:Show(); row.kind:Show(); row.txt:Show()
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
      row.i = nil; row.go = nil; row.chapter = nil
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
  -- the objectives (and what a turn-in still needs) as a list under the first detail lines, then
  -- the lines that follow them (design system 3.21)
  row.list = ns.TyBullets(row)
  row.sub2 = Text(row, ns.F.meta, T.muted); row.sub2:SetSpacing(3); row.sub2:Hide()
  row.sep = ns.Rule(row, T.divider); row.sep:SetPoint("BOTTOMLEFT", 8, 0); row.sep:SetPoint("BOTTOMRIGHT", -8, 0)
  -- the secure buttons (target / item) live in the action bar outside this window, so the window
  -- stays usable in combat. GPS: a secondary button with the pin.
  local gb
  gb = LabelBtn(row, "GPS", 24, "secondary", function(self) local n = self.row.node; if ns.NodeCanGo(n) then ns.SetOne(n) end end,
    function()
      local n = gb and gb.row and gb.row.node
      local x, y
      if n then x, y = select(2, ns.NodePoint(n)) end
      if not x and n and n.loc then x, y = n.loc.x, n.loc.y end
      if not x then return nil end
      return { L.TT_GPS:format(n.npc or ns.QName(n.q), x, y), L.TT_GPS_CLICK }
    end)
  if gb.SetIcon then gb:SetIcon("pin") end
  gb.row = row
  row.gb = gb
  -- a locked check-list line (T-91): the click ticks the quest by hand, its chain joins the route
  row:SetScript("OnClick", function(self)
    local n = self.node
    if n and n.lock then if ns.GuideLockPick then ns.GuideLockPick(n.q) end return end
    if ns.NodeCanGo(n) then ns.SetOne(n) end
  end)
  row:SetScript("OnMouseDown", function(self) if (self.node and self.node.lock) or ns.NodeCanGo(self.node) then self.press:Show() end end)
  row:SetScript("OnMouseUp", function(self) self.press:Hide() end)
  row:SetScript("OnEnter", function(self) ns.RowTip(self) end)
  row:SetScript("OnLeave", ns.HideTip)
  ns.ClampLabel(row.tag, nil, row)
  ns.ClampLabel(row.npc, nil, row)
  return row
end

-- The GPS of one line: the point the arrow follows (NodePoint: the game's quest area first for an
-- objective, as the card, its distance and the tooltip say), else our database point.
function ns.SetOne(n)
  if not n then return end
  local m, x, y
  if ns.NodePoint then m, x, y = ns.NodePoint(n) end
  if not (m and x and y) and n.loc and n.loc.m then m, x, y = n.loc.m, n.loc.x, n.loc.y end
  if not (m and x and y) then return end
  ns.SetPoints({ { m, x, y, n.npc or ns.QName(n.q) } })
  Render()
end

-- A quest line's tooltip, in blocks and without repeats (design system 3.16):
--   title + pill (Prerequisite / Dungeon quest); what to do and the quest's state; NPC and place
--   ("Badlands 46.2, 13.8 · outside the dungeon"); Objective (live lines, "Drops from: ..." on its
--   own line, the quest text in grey, our note, ForeverDungeonJournal's note); XP and money;
--   the chain; the mouse line.
function ns.RowTip(row)
  local n = row.node
  if not n then
    -- a boss header: its name and tip (cut labels first)
    if row.bossName then ns.ShowTip(row, { row.bossName, row.bossTip }) end
    return
  end
  if n.lock then
    local t = { ns.QName(n.q) }
    local why = ns.CheckLockText and ns.CheckLockText(n.q, nil, n.d)
    if why then t[#t + 1] = why end
    t[#t + 1] = L.CL_LOCK_CLICK
    ns.ShowTip(row, t)
    return
  end
  local q = ns.Q[n.q] or {}
  local log = ns.LogEntries()
  local s = ns.State(log, n.q)
  local lines = {}
  local function add(x) lines[#lines + 1] = x end
  local function gap() if #lines > 0 and not (type(lines[#lines]) == "table" and lines[#lines].gap) then add({ gap = true }) end end
  local mute, txt = T.muted, T.text
  -- title and pill
  local pill, pc
  if n.pre or q.role == "pre" then pill, pc = L.PRE, T.fg elseif q.d and n.kind ~= "i" then pill, pc = L.MAIN, T.gold end
  add({ n.label or ns.QName(n.q), T.fg[1], T.fg[2], T.fg[3], right = pill, rc = pc })
  local other = (GetLocale and GetLocale() == "frFR" and q.n) or (ns.lang == "fr" and q.nf) or nil
  if other and other ~= (n.label or ns.QName(n.q)) then add(other) end
  -- what to do, and where the quest stands
  local kc = KCOL[n.kind] or T.text
  local kt = ({ a = L.TT_TAKE, c = L.TT_DO, o = L.TT_DO, t = L.TT_TURN, h = L.TT_HAVE, i = L.TT_ITEM })[n.kind]
  if kt then
    -- "Accept the quest · To take" said the same thing twice: the state only when it adds something
    local showSt = n.kind ~= "i" and SLABEL[s] and not (n.kind == "a" and s == "none")
    local st = showSt and (Hex(mute) .. "  ·  " .. L[SLABEL[s]] .. "|r") or ""
    add(Hex(kc) .. kt .. "|r" .. st)
  end
  -- the quest's level in the summary's words ("Quête niv. 36 · facile · se prend dès le niv. 30")
  if n.kind ~= "i" then
    local lf = LevelFact(n.q, s)
    if lf then add(lf) end
  end
  if q.c then
    for tok in q.c:gmatch("[^,]+") do local cn, cc = ns.ClassInfo(tok); add({ L.CLASSQ:format(cn), cc[1], cc[2], cc[3] }) end
  end
  -- NPC and place, once
  gap()
  if n.npc then add({ n.npc, txt[1], txt[2], txt[3] }) end
  local inout = n.ins and L.TT_IN_L or L.TT_OUT_L
  if n.loc then
    local zn = ZoneName(n.loc.m)
    add(("%s%.1f, %.1f  ·  %s"):format(zn ~= "" and (zn .. "  ") or "", n.loc.x, n.loc.y, inout))
  else
    add(n.ins and L.TT_INSIDE or L.TT_OUTSIDE)
  end
  -- objective
  local objs = ObjectiveBlock(n, log, s)
  local reqs = {}
  if #objs == 0 then
    for _, r in ipairs(q.req or {}) do
      reqs[#reqs + 1] = "- " .. r[1] .. (r[2] and r[2] > 1 and (" x" .. r[2]) or "") .. (r[3] and (L.COLON .. ns.T(r[3])) or "")
    end
  end
  local obj = ns.GuideObjSentence(q)
  -- the game's own description, in grey under the objectives, when our data is thin (as the card)
  local gdesc
  if ns.GameQuestText and (s == "on" or s == "ready") then
    local gd, gobj = ns.GameQuestText(n.q, log)
    if not obj then obj = gobj end
    if gd and not q.ne and not (q.o and #q.o > 0) then gdesc = gd end
  end
  -- ForeverDungeonJournal's note only when we have none of our own (each said once)
  local fdj = (not q.ne) and ns.FDJNote and ns.FDJNote(n.q) or nil
  if #objs > 0 or #reqs > 0 or obj or gdesc or q.ne or fdj or q.si or q.pi then
    gap()
    add({ L.TT_OBJ_H, T.fg[1], T.fg[2], T.fg[3] })
    for _, l2 in ipairs(objs) do
      if type(l2) == "table" then add(l2.src) else add({ "- " .. l2, txt[1], txt[2], txt[3] }) end
    end
    for _, r in ipairs(reqs) do add({ r, txt[1], txt[2], txt[3] }) end
    if obj then add(obj) end
    if gdesc then add(gdesc) end
    if q.ne then add({ ns.T(q.ne), txt[1], txt[2], txt[3] }) end
    if q.si then add(q.si .. (q.sih and (L.COLON .. ns.T(q.sih)) or "")) end
    if q.pi then add(q.pi .. (q.pih and (L.COLON .. ns.T(q.pih)) or "")) end
    if fdj then add(L.FDJ_NOTE); add({ fdj, txt[1], txt[2], txt[3] }) end
  end
  -- XP and money, reward items
  local money = q.rw and q.rw ~= "" and q.rw or nil
  -- the XP this player really gets (less on a grey quest, none at the cap), as the summary shows it
  local xp = q.xp and q.xp > 0 and q.xp or nil
  local xpWhy
  if xp and ns.QuestXPFor then
    local okL, lv = pcall(function() return tonumber(UnitLevel("player")) end)
    lv = okL and lv or 1
    local ok, got, base, diff = pcall(ns.QuestXPFor, n.q, lv)
    if ok and type(got) == "number" then
      -- why it is less than the quest's own XP (the summary's sentence)
      if got > 0 and type(base) == "number" and got < base and s ~= "done" and HasL("SUM_XP_LESS_TT") and ns.BigNumber then
        xpWhy = L.SUM_XP_LESS_TT:format(ns.BigNumber(got), ns.BigNumber(base), diff or 0)
      end
      xp = got > 0 and got or nil
    end
  end
  if xp and ns.BigNumber then xp = ns.BigNumber(xp) end
  if xp or money or (q.ri and q.ri[1]) then
    gap()
    if xp and money then add(L.TT_XPMONEY:format(xp, money))
    elseif xp then add(L.TT_XP:format(xp))
    elseif money then add({ L.TT_REWARD:format(money), T.gold[1], T.gold[2], T.gold[3] }) end
    if xpWhy then add({ xpWhy, T.warn[1], T.warn[2], T.warn[3] }) end
    if q.ri and q.ri[1] then add({ L.TT_REWARD:format(table.concat(q.ri, q.rc and " / " or ", ")), T.gold[1], T.gold[2], T.gold[3] }) end
  end
  -- the chain, what blocks it
  local chain = {}
  if n.pre and n.ci and n.cn and n.forQ and n.forQ[1] then chain[#chain + 1] = { ns.GuideChainText(n, true), txt[1], txt[2], txt[3] } end
  -- the level it needs is already in the level line under the title
  local pb = n.kind == "a" and not NeedShown(n.q, s) and ns.PrereqProblem(n.q)
  if pb then chain[#chain + 1] = { L.BLOCKED:format(pb), T.bad[1], T.bad[2], T.bad[3] } end
  if q.conf then chain[#chain + 1] = L.TT_CONFLICT end
  if #chain > 0 then gap(); for _, c in ipairs(chain) do add(c) end end
  gap()
  add(n.loc and L.TT_CLICK or (n.ins and L.TT_NOPOINT or L.TT_NOPOINT_UNK))
  ns.ShowTip(row, lines)
end

-- =====================================================================
--  Text blocks (design system 3.21): a gold heading, then sentences or a list
-- =====================================================================
-- A block: { h = heading or nil, body = { sentences }, list = { items }, listColors = { .. },
-- foot = { sentences after the list } }. BlocksText gives the plain words ("heading\nline",
-- blocks apart with an empty line): what a card says, for the tests and the tooltips.
local function BlocksText(blocks)
  local out = {}
  for _, b in ipairs(blocks or {}) do
    local t = {}
    if b.h then t[#t + 1] = b.h end
    for _, part in ipairs({ b.body or {}, b.list or {}, b.foot or {} }) do
      for _, s in ipairs(part) do t[#t + 1] = s end
    end
    if #t > 0 then out[#out + 1] = table.concat(t, "\n") end
  end
  return table.concat(out, "\n\n")
end
ns.BlocksText = BlocksText

-- A block without a heading after another block: as far from it as a heading would be
local BLOCK_GAP = ns.TY.head.top - ns.TY.gap
-- Draws the blocks with a TextStack at (x, y), width w; a block that starts above narrowTo (a y,
-- the portrait's bottom) keeps to narrowW, so the words run beside the portrait instead of
-- leaving a hole under the title. -> used height
local function DrawBlocks(stk, blocks, x, y, w, narrowTo, narrowW)
  stk:Begin(x, y, w)
  for _, b in ipairs(blocks or {}) do
    stk.w = (narrowTo and stk.y < narrowTo) and narrowW or w
    if b.h then stk:Heading(b.h)
    elseif stk.n > 0 then stk:Gap(BLOCK_GAP) end
    for _, s in ipairs(b.body or {}) do stk:Body(s, b.color) end
    if b.list and #b.list > 0 then stk:Bullets(b.list, { colors = b.listColors }) end
    for _, s in ipairs(b.foot or {}) do stk:Body(s) end
  end
  return stk:End()
end
local function HideStack(stk) if stk then stk:Begin(0, 0, 1); stk:End() end end
-- the lines of a text ("a\nb") as a table, or nil
local function Lines(s)
  if type(s) ~= "string" or s == "" then return nil end
  local t = {}
  for ln in (s .. "\n"):gmatch("([^\n]*)\n") do if ln ~= "" then t[#t + 1] = ln end end
  return #t > 0 and t or nil
end
-- a heading and its text: one line is a sentence, two or more a list
local function Block(h, text)
  local ls = Lines(text)
  if not ls then return nil end
  if #ls >= 2 then return { h = h, list = ls } end
  return { h = h, body = ls }
end

-- =====================================================================
--  The step card's current action, then the other actions at the same NPC
-- =====================================================================
local FOCUS_KEY = { a = "FOCUS_A", t = "FOCUS_T", c = "FOCUS_C", o = "FOCUS_O", h = "FOCUS_H", i = "FOCUS_I" }
local LINE_KEY = { a = "LINE_A", t = "LINE_T", c = "LINE_C", o = "LINE_O", h = "LINE_H", i = "LINE_I" }
local NEXT_MAX = 16
local FOCUS_X = 36            -- the card's text edge inside the block (icon 20 at x 8, then 8)
local SEP = "  ·  "

-- an objective's verb and icon, the tracker's words (Tracker.lua TR.Action uses the same keys)
local OBJ_KIND = { kill = "kill", item = "loot", object = "use", talk = "talk", event = "go" }
local OBJ_TEXT = { kill = "TR_KILL", loot = "TR_LOOT", use = "TR_USE", talk = "TR_TALK", go = "TR_GO" }
-- The verb key of an objective's line: its kind's own; a "go" objective that is not a place but a
-- sentence ("Find Varian Wrynn", "Explore the waters of ...") reads "Objective: ..."
function ns.ObjVerbKey(o, nm)
  local kind = OBJ_KIND[o and o.k] or "go"
  if kind == "go" and type(nm) == "string" then
    local _, words = nm:gsub("%S+", "")
    if words > 3 or nm:match("^Find ") or nm:match("[%.!]$") then return "TR_OBJ" end
  end
  return OBJ_TEXT[kind]
end
local OBJ_ICON = { kill = "sword", loot = "bag", use = "hammer", talk = "user", go = "flag" }
local CHECK_T = "|TInterface\\AddOns\\WLHelper\\Media\\Icons\\check:14:14:0:-1|t "

local function NodeName(nd) return nd.label or ns.QName(nd.q) end
local function NpcShort(nd) return nd.npc and ns.NpcName((nd.npc:gsub(",.*$", ""))) or nil end

-- the first letter up or down (a part that starts a line, or follows another one); é/É too
local function Cap(s)
  if type(s) ~= "string" or s == "" then return s end
  local c = s:match("^|c%x%x%x%x%x%x%x%x")
  if c then return c .. Cap(s:sub(#c + 1)) end
  if s:sub(1, 2) == "\195\169" then return "\195\137" .. s:sub(3) end
  return s:sub(1, 1):upper() .. s:sub(2)
end
local function Low(s)
  if type(s) ~= "string" or s == "" then return s end
  if s:sub(1, 2) == "\195\137" then return "\195\169" .. s:sub(3) end
  return s:sub(1, 1):lower() .. s:sub(2)
end

-- the current action of a step: its first unfinished line (else its last one: all done)
local function FocusIndex(st, log)
  for k, nd in ipairs(st.acts) do if not ns.NodeOK(log, nd) then return k end end
  return #st.acts
end
ns.FocusIndex = FocusIndex

-- What the arrow follows for an objective line: "game" when the game's own quest area is used
-- (GamePOI, as StepPoints does), "log" when nothing places it, nil for a line with its own place.
local function ArrowSource(nd)
  if nd.kind ~= "o" then return nil end
  if nd.loc and nd.loc.m then return GamePOI(nd.q, nd.loc.m) and "game" or nil end
  if not nd.noLoc then return nil end
  local here = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
  for _, m in ipairs({ here or false, nd.mapHint or false }) do
    if m and GamePOI(nd.q, m) then return "game" end
  end
  return "log"
end
ns.ArrowSource = ArrowSource

-- The point a line leads to, as the arrow follows it (StepPoints): the game's quest area first for
-- an objective. -> m, x, y (nil when nothing places it)
local function NodePoint(nd)
  if nd.loc and nd.loc.m then
    local a = nd.kind == "o" and ns.AreaOf and ns.AreaOf(nd)
    if a then
      local am, ax, ay = ns.AreaFollow(a)
      if am == nd.loc.m and ax then return am, ax, ay end
    end
    if nd.kind == "o" then
      local gx, gy = GamePOI(nd.q, nd.loc.m)
      if gx then return nd.loc.m, gx, gy end
    end
    return nd.loc.m, nd.loc.x, nd.loc.y
  end
  if nd.noLoc and nd.kind == "o" then
    local here = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
    for _, m in ipairs({ here or false, nd.mapHint or false }) do
      if m then
        local gx, gy = GamePOI(nd.q, m)
        if gx then return m, gx, gy end
      end
    end
  end
end
ns.NodePoint = NodePoint

-- An objective spread over an area: its spot is picked again once you moved 30 yd (ns.AreaFollow).
-- Asked every second while the current step has one (Writs/Patrol.lua, Zones): when the spot of a
-- line the arrow follows changed, the arrow goes to the new one (the whole step when the guide
-- places its points itself, else that line).
local areaSeen = setmetatable({}, { __mode = "k" })
function ns.AreaRefollow()
  if not f or (ns.GuideOn and not ns.GuideOn()) then return false end
  local st = Steps()[f.auto or 0]
  if not (st and st.acts) then return false end
  local log = ns.LogEntries()
  local moved
  for _, n in ipairs(st.acts) do
    local a = ns.AreaOf and ns.AreaOf(n)
    if a and not ns.NodeOK(log, n) then
      local m, x, y = ns.AreaFollow(a)
      if m then
        local key, was = ns.PKey(m, x, y), areaSeen[a]
        areaSeen[a] = key
        if was and was ~= key and ns.active[was] then moved = moved or n end
      end
    end
  end
  if not moved then return false end
  if WLDTDB.autoWay then f.sig = nil; ns.Refresh(true) else ns.SetOne(moved) end
  return true
end
-- a click on the line (or its GPS button) leads somewhere: its own place, or the game's quest area
function ns.NodeCanGo(nd)
  if not nd then return false end
  if nd.loc and nd.loc.m then return true end
  return NodePoint(nd) ~= nil
end
-- the line is the one the arrow follows now (its point is set)
local function NodeFollowed(nd)
  local m, x, y = NodePoint(nd)
  return (m and ns.active[ns.PKey(m, x, y)]) and true or false
end

-- How far a point is from you: "350 m", "1,2 km" (the GPS's own words), "Autre continent"; nil
-- inside an instance, with no position, or when the position is secret.
-- How far a point is from you, raw: "far" (another continent), the yards, or nil (inside an
-- instance, no position, secret position).
function ns.GuideLiveSpan(m, x, y)
  if not (m and x and y and ns.PlayerWorld and ns.World) then return nil end
  if IsInInstance then
    local okI, inst = pcall(IsInInstance)
    if okI and inst == true then return nil end
  end
  local okH, here = pcall(ns.PlayerWorld)
  local okT, there = pcall(ns.World, m, x, y)
  if not (okH and okT and type(here) == "table" and type(there) == "table") then return nil end
  local okD, far, yd = pcall(function()
    if here[1] ~= there[1] then return true, nil end
    return false, math.sqrt((here[2] - there[2]) ^ 2 + (here[3] - there[3]) ^ 2)
  end)
  if not okD then return nil end
  if far then return "far" end
  if type(yd) ~= "number" or (issecretvalue and issecretvalue(yd)) then return nil end
  return yd
end

-- The travel hint of a step, from the same spot as the distance: your live position when there
-- is one (another continent: TRAVEL_CONT; same continent, farther than 1400 yd: TRAVEL_FAR; nearer:
-- none), else the route's own hint (from the previous step). So a card never says "9 km" and
-- "change continent" at once.
function ns.GuideLiveTravelKey(st, m, x, y)
  local tr = st and st.travel
  if tr == "TRAVEL_UNK" then return tr end
  local live = ns.GuideLiveSpan(m, x, y)
  if live == "far" then return "TRAVEL_CONT" end
  if type(live) == "number" then return live > 1400 and "TRAVEL_FAR" or nil end
  return tr
end

local function DistText(m, x, y)
  local yd = ns.GuideLiveSpan(m, x, y)
  if yd == nil then return nil end
  if yd == "far" then return L.ARROW_FAR end
  -- the GPS's own format (meters or yards, as set on the GPS page); WP lives on the Writs side
  local WP = ns.Writs and ns.Writs.WP
  local GPS = WP and WP.GPS
  if GPS and GPS.Distance then
    local okG, t = pcall(GPS.Distance, yd)
    if okG and type(t) == "string" then return t end
  end
  local m2 = yd * 0.9144
  if m2 >= 1000 then
    local t = ("%.1f km"):format(m2 / 1000)
    return (ns.lang == "fr") and (t:gsub("%.", ",")) or t
  end
  return L.YARDS:format(math.floor(m2 + 0.5))
end
ns.GuideDistText = DistText

-- The travel sentence of a step: for another continent, the planned trip in short ("Zeppelin pour
-- Orgrimmar, puis 1,2 km", GPS.TripSummary) when the GPS finds one; else the generic hint
-- (TRAVEL_CONT / TRAVEL_FAR). nil when the step has no travel hint. The trip's time follows it ("(~10 min)")
-- and, on a line of its own, its runner-up ("Autre trajet : pierre de foyer jusqu'à Grom'gol, puis vol
-- jusqu'à Kargath (~7 min)", TripSummary's 3rd and 4th values) when there is one.
local function TravelText(st, m, x, y, key)
  key = key or (st and st.travel)
  if not key then return nil end
  if key == "TRAVEL_CONT" and type(m) == "number" and type(x) == "number" and type(y) == "number" then
    local WP = ns.Writs and ns.Writs.WP
    local GPS = WP and WP.GPS
    if GPS and GPS.TripSummary then
      local ok, t, _, mins, alt = pcall(GPS.TripSummary, m, x, y)
      if ok and type(t) == "string" and t ~= "" then
        if type(mins) == "string" and mins ~= "" then t = t .. " (" .. mins .. ")" end
        if type(alt) == "string" and alt ~= "" then t = t .. "\n" .. alt end
        return t
      end
    end
  end
  return L[key]
end
ns.GuideTravelText = TravelText

-- "Shadowforge Surveyor, Shadowforge Ruffian, Shadowforge Digger (8 %)" or "A 8 % · B 3 %", 3 names
local function DropsText(o)
  if not (o and o.src and o.src[1]) then return nil end
  local same, p0 = true, nil
  for k2, x in ipairs(o.src) do
    local p = x[2] and math.floor(x[2] + 0.5) or nil
    if k2 == 1 then p0 = p elseif p ~= p0 then same = false end
  end
  local names = {}
  for k2, x in ipairs(o.src) do
    if k2 > 3 then break end
    local p = x[2] and math.floor(x[2] + 0.5) or nil
    local pct = (not same and p and p > 0 and p < 100) and (" " .. p .. " %") or ""
    names[#names + 1] = x[1] .. pct
  end
  local t = table.concat(names, same and ", " or " · ")
  if #o.src > 3 then t = t .. " " .. L.CARD_PLUS:format(#o.src - 3) end
  if same and p0 and p0 > 0 and p0 < 100 then t = t .. " (" .. p0 .. " %)" end
  return L.TT_DROPS:format(t)
end

-- "Élite" / "Non élite" for the mobs of an objective done outside a dungeon (ns.NPC_ELITE, baked from
-- LibForeverData's NPC rank in Engine.lua); nil when the objective is inside or no mob is known.
local function EliteMark(o)
  local E = ns.NPC_ELITE
  if not (E and o) or o.ins or o.unk then return nil end
  local names = {}
  if o.src and o.src[1] then for _, x in ipairs(o.src) do names[#names + 1] = x[1] end
  elseif type(o.t) == "table" then for _, x in ipairs(o.t) do names[#names + 1] = x end end
  local el, no = 0, 0
  for _, nm in ipairs(names) do
    local r = E[nm]
    if r == 1 then el = el + 1 elseif r == 0 then no = no + 1 end
  end
  if el == 0 and no == 0 then return nil end
  if no == 0 then return Hex(T.warn) .. L.CARD_ELITE .. "|r" end
  if el == 0 then return L.CARD_NOELITE end
  return Hex(T.warn) .. L.CARD_ELITE_SOME .. "|r"
end
ns.GuideEliteMark = EliteMark

-- Why a step before the dungeon comes before it: the nearest later quest of its chain (p=) that is
-- done in the same dungeon (a dungeon quest, or started / finished inside) -> its id, or false when
-- nothing in the dungeon depends on it; nil when the question does not arise (no dungeon, or the
-- quest is itself done inside).
local succOf
local function Successors()
  if succOf then return succOf end
  succOf = {}
  for id, q2 in pairs(ns.Q or {}) do
    if type(q2) == "table" and type(q2.p) == "table" then
      for _, p in ipairs(q2.p) do
        if type(p) == "number" then succOf[p] = succOf[p] or {}; table.insert(succOf[p], id) end
      end
    end
  end
  -- the route's own order rules (Curated ns.AFTER: pid is taken once x is turned in)
  for pid, xs in pairs(ns.AFTER or {}) do
    for _, x in ipairs(type(xs) == "table" and xs or {}) do
      if type(x) == "number" then succOf[x] = succOf[x] or {}; table.insert(succOf[x], pid) end
    end
  end
  for _, l2 in pairs(succOf) do table.sort(l2) end
  return succOf
end
-- the instance it is done in, as Engine.lua's qnodes places it: its own dungeon (another one of its
-- list, q.ds, only for a quest done in any of them, q.anyd); the objectives in q.od when set (a
-- quest listed for Sunken Temple but done in Zul'Farrak is not done in Sunken Temple)
local function InDungeon(q2, dk)
  if not (q2 and q2.d and dk) then return false end
  local home = q2.d
  if q2.anyd and type(q2.ds) == "table" then for _, k in ipairs(q2.ds) do if k == dk then home = dk end end end
  if home == dk and ((q2.f and q2.f.i) or (q2.s and q2.s.i)) then return true end
  if (q2.od or home) ~= dk then return false end
  if q2.role == "main" then return true end
  -- a prerequisite with an objective inside (or not placed: Engine.lua makes it a node inside)
  for _, o in ipairs(type(q2.o) == "table" and q2.o or {}) do if o.ins or o.unk then return true end end
  return false
end
-- T-87: a main quest of the dungeon done outside the instance: one with nothing to do inside
-- (Curated noin: a talk, a delivery, the turn-in that follows the dungeon), or given and turned in
-- outside with every objective placed outside or in the zone around the dungeon (Shadowshard
-- Fragments in Maraudon's outer caves, the Uldaman dig site, Wailing Essence). Engine.lua makes no
-- node inside the instance for it (qnodes; InsideNode leaves the zone around out)
local function OutsideMain(q2, dk)
  if not (q2 and q2.role == "main") then return false end
  if (q2.s and q2.s.i) or (q2.f and q2.f.i) then return false end
  if q2.noin then return true end
  if ns.OuterAllNear and ns.OuterAllNear(q2, q2.od or dk) then return true end
  -- as qnodes: an objective inside or not placed (o.unk) is done inside; one with no spot at all
  -- (bought, made) adds nothing; none placed: done inside
  local placed = false
  for _, o in ipairs(type(q2.o) == "table" and q2.o or {}) do
    if o.ins or o.unk then return false end
    if o.w or o.outer then placed = true end
  end
  return placed
end
-- done in the dungeon: InDungeon, less such an outside main quest
local function DoneInside(q2, dk) return InDungeon(q2, dk) and not OutsideMain(q2, dk) end
-- the quest gives the key needed to get in (Curated ns.KEYS; a shortcut key is not needed)
local function KeyQuest(c, dk)
  for _, k in ipairs(ns.KEYS and ns.KEYS[dk] or {}) do
    if k.quest == c and k.opt ~= "shortcut" then return true end
  end
  return false
end
-- every objective's spot is on the entrance's map, within ON_WAY map units of it
local ON_WAY = 10
local function OnTheWay(q2, dk)
  local d = ns.D[(q2 and q2.od) or dk]
  local e = d and d.e
  if not (e and e.m and e.x) then return false end
  local any = false
  for _, o in ipairs(type(q2.o) == "table" and q2.o or {}) do
    local w = o.w
    if not (w and w.m == e.m and w.x and w.y) then return false end
    if math.sqrt((e.x - w.x) ^ 2 + (e.y - w.y) ^ 2) > ON_WAY then return false end
    any = true
  end
  return any
end
-- the running route: its dungeons (a class quest or key card counts as its dungeon) and its
-- quests, or nil
local rtCache, rtFor
local function RouteScope()
  local r = ns.route
  if not (r and type(r.sel) == "table") then return nil end
  if rtFor == r and rtCache then return rtCache end
  local dks, qs, cards = {}, {}, true
  for k, on in pairs(r.sel) do
    if on then
      local d = ns.D[k]
      dks[#dks + 1] = (d and d.cq and d.home) or k   -- a class quest or key card: its dungeon
      if not (d and d.cq and d.cq ~= "KEY") then cards = false end
    end
  end
  table.sort(dks)
  for _, st in ipairs(r.steps or {}) do
    for _, nd in ipairs(st.acts or {}) do if type(nd.q) == "number" then qs[nd.q] = true end end
  end
  rtCache, rtFor = { dks = dks, qs = qs, cards = cards and #dks > 0 }, r
  return rtCache
end
-- -> the id of the nearest later quest the dungeon needs (done inside, or its key; then true as
-- 2nd value for a key), or false (optional; then true as 2nd value when its spots are on the way to
-- the portal), or nil when the question does not arise. With a route running, only the route's
-- dungeons and the quests in it count: a quest of another dungeon, of another class or left out
-- of the route needs nothing here.
local function BeforeReason(qid, dk)
  local q = qid and ns.Q[qid]
  local home = (q and q.d) or dk
  if not (q and home) then return nil end
  if DoneInside(q, home) then return nil end
  -- its own objectives inside (or not placed: a boss, a mob of the dungeon): no "before" question
  for _, o in ipairs(type(q.o) == "table" and q.o or {}) do if o.ins or o.unk then return nil end end
  local R = RouteScope()
  -- a class quest card's route is that quest's chain: every step is for it (the card says so)
  if R and R.cards then return nil end
  local dks = R and R.dks or { home }
  local function Needed(c)
    if R and not R.qs[c] then return nil end
    for _, k in ipairs(dks) do
      if KeyQuest(c, k) then return true, true end
      if DoneInside(ns.Q[c], k) then return true end
    end
  end
  -- the key quest itself (The Key to Scholomance)
  for _, k in ipairs(dks) do if KeyQuest(qid, k) then return qid, true end end
  local S = Successors()
  -- breadth first, every link (no depth limit: a long chain is still required)
  local seen, frontier = { [qid] = true }, { qid }
  while #frontier > 0 do
    local nxt = {}
    for _, id in ipairs(frontier) do
      for _, c in ipairs(S[id] or {}) do
        if not seen[c] then
          seen[c] = true
          local need, key = Needed(c)
          if need then return c, key or false end
          nxt[#nxt + 1] = c
        end
      end
    end
    frontier = nxt
  end
  return false, OnTheWay(q, home)
end
ns.GuideBeforeReason = BeforeReason
-- T-87: the quest a "Skip" button takes out of the route: a quest of the dungeon's own list (the
-- Overview ticks those, WLDTDB.off) that the dungeon does not need -> qid or nil
local function SkipQuest(qid, dk)
  local q = qid and ns.Q[qid]
  local home = q and (q.d or dk)
  local d = home and ns.D[home]
  if not (d and type(d.q) == "table") then return nil end
  local listed = false
  for _, x in ipairs(d.q) do if x == qid then listed = true break end end
  if not listed then return nil end
  local ok, r = pcall(BeforeReason, qid, home)
  if not (ok and r == false) then return nil end
  -- a later quest of the route keeps it as its prerequisite: unticking it would change nothing
  local R = RouteScope()
  if R then
    for _, c in ipairs(Successors()[qid] or {}) do
      if R.qs[c] and not (WLDTDB and WLDTDB.off and WLDTDB.off[c]) then return nil end
    end
  end
  return qid
end
ns.GuideSkipQuest = SkipQuest
-- the quest a step's "Skip" button is for: the open actions outside of one optional quest, before
-- the dungeon (a turn-in, or a step after the dungeon, is not worth skipping)
function ns.GuideStepSkipQuest(st, log, dk)
  if not (st and type(st.acts) == "table") or st.gate or st.ins or st.split then return nil end
  local qid
  for _, nd in ipairs(st.acts) do
    if nd.q and not nd.ins and not ns.NodeOK(log or {}, nd) then
      if nd.kind == "t" or nd.kind == "h" or nd.phase == "after" then return nil end
      if qid and qid ~= nd.q then return nil end
      qid = nd.q
    end
  end
  return qid and SkipQuest(qid, dk) or nil
end
function ns.GuideSkipDisarm(b)
  if not (b and b.armToken) then return end
  b.armToken = nil
  b:SetText(L.SKIP_Q)
end
function ns.GuideSkipClick(b)
  local qid = b and b.qid
  if not qid then return end
  if b.armToken then
    b.armToken = nil; b:SetText(L.SKIP_Q)
    if not ns.SummarySetOff then return end
    -- the quest is only left out of the route, never abandoned: one in the log stays there
    local log = ns.LogEntries and ns.LogEntries() or {}
    -- looking at another step (T-86): that step leaves the route, back to the current one
    local fr = ns.frame
    if fr and fr.view and fr.view ~= fr.auto then fr.view = nil end
    ns.SummarySetOff(qid, true)
    ns.Print(L.SKIP_Q_DONE:format(ns.QName(qid)) .. (log[qid] and (" " .. L.SKIP_Q_LOG) or ""))
    return
  end
  local token = {}
  b.armToken = token
  b:SetText(L.SKIP_Q_CONFIRM)
  if C_Timer and C_Timer.After then
    C_Timer.After(4, function() if b.armToken == token then ns.GuideSkipDisarm(b) end end)
  end
end

-- The name of an objective as the player reads it: ours (translated), else in French the game's own
-- words when the quest is in the log and the game names the same objective.
local function ObjName(nd, o, log, s)
  -- the whole quest sentence (no objective of its own): the line says "Do « quest »" and the card
  -- shows the sentence, in French when we have it
  if o.k == "text" then return nil end
  local nm = o.n and (ns.T(o.n) or o.n) or nil
  if ns.lang == "fr" and o.n and nm == o.n and (s == "on" or s == "ready") then
    local lines, fromGame = ObjectiveBlock({ kind = "o", q = nd.q, obj = o }, log, s)
    if fromGame and type(lines[1]) == "string" then
      local g = lines[1]:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("%s*:%s*%d+%s*/%s*%d+%s*$", "")
      if g ~= "" then nm = g end
    end
  end
  return nm
end

-- the tracker names an objective the same way (Tracker.lua TR.Action)
ns.ObjDisplayName = function(nd, o, log, s)
  if s == nil and log and nd and nd.q then s = ns.State(log, nd.q) end
  return ObjName(nd, o, log, s)
end

-- "Tuer : Shadowforge Surveyor  ·  3 sur 8" (the count in green once done). A count of one says
-- nothing: the check mark already tells it is done.
local function ObjLine(nd, o, log, s)
  local kind = OBJ_KIND[o.k] or "go"
  local nm = ObjName(nd, o, log, s)
  local t = nm and L[ns.ObjVerbKey(o, nm)]:format(nm) or L.TR_DO:format(ns.QName(nd.q))
  local a, b, fin = ns.ObjCount(log, nd.q, o)
  -- not in the log yet: the count still says how many it takes ("0 sur 6")
  if not (a and b) and type(o.c) == "number" and o.c > 1 then a, b, fin = 0, o.c, false end
  if a and type(b) == "number" and b > 1 then
    t = t .. Hex(T.muted) .. SEP .. "|r" .. Hex(fin and T.ok or T.muted) .. L.CARD_COUNT:format(a, b) .. "|r"
  end
  return t, kind, nm
end

-- What is still to finish outside before entering a dungeon (T-85): the objectives of the open
-- "before" steps of the check-list's dungeon ("Collier brisé 0/1"). gi: the check-list's step.
-- -> lines, how many are needed (an optional one, BeforeReason false, does not hold you back)
local function OutsideLeft(log, gi)
  local steps = Steps()
  local g = steps[gi]
  local dk = g and g.gate
  local out, req = {}, 0
  if not (dk and ns.StepDungeon and ns.StepPhase) then return out, 0 end
  local seen = {}
  local okL, lvl = pcall(function() return tonumber(UnitLevel("player")) end)
  lvl = okL and lvl or nil
  for i, st in ipairs(steps) do
    if not st.gate and not st.split and not st.ins and ns.StepDungeon(st) == dk and ns.StepPhase(st) == "before"
      and not IsStepDone(log, i) then
      for _, nd in ipairs(st.acts or {}) do
        local o = nd.kind == "o" and not nd.ins and (nd.oneObj or nd.obj) or nil
        local k = o and (tostring(nd.q) .. ":" .. tostring(nd.oi or nd.sub or o.n))
        -- a quest the player cannot take yet (above his level, not in the log) has nothing to
        -- finish now: a level 60 chain ticked by hand lists no objective at level 55
        local s = o and ns.State(log, nd.q)
        local qd = o and ns.Q[nd.q]
        local low = lvl and qd and qd.r and qd.r > lvl and s ~= "on" and s ~= "ready"
        if o and not low and not seen[k] and not ns.NodeOK(log, nd) then
          seen[k] = true
          local nm = ObjName(nd, o, log, s) or ns.QName(nd.q)
          local a, b = ns.ObjCount(log, nd.q, o)
          if not (a and b) then a, b = 0, (type(o.c) == "number" and o.c > 0) and o.c or 1 end
          local opt = BeforeReason(nd.q, dk) == false
          if not opt then req = req + 1 end
          out[#out + 1] = nm .. " " .. a .. "/" .. b .. (opt and (Hex(T.muted) .. SEP .. L.CL_OUT_OPT .. "|r") or "")
        end
      end
    end
  end
  return out, req
end
ns.GuideOutsideLeft = OutsideLeft
NAV.OutsideLeft = OutsideLeft

-- an "Ensuite" line: the objective's own verb for an objective (as the card's title), else the kind
local function LineText(a, log)
  if (a.kind == "c" or a.kind == "o") and log then
    local o = a.oneObj or (a.kind == "o" and a.obj) or nil
    if o then
      local nm = ObjName(a, o, log, ns.State(log, a.q))
      if nm then
        local t = L[ns.ObjVerbKey(o, nm)]:format(nm)
        local ca, cb = ns.ObjCount(log, a.q, o)
        if not (ca and cb) and type(o.c) == "number" and o.c > 1 then ca, cb = 0, o.c end
        if ca and type(cb) == "number" and cb > 1 then t = t .. SEP .. L.CARD_COUNT:format(ca, cb) end
        return t
      end
    end
  end
  local lk = LINE_KEY[a.kind]
  return lk and L[lk]:format(NodeName(a)) or NodeName(a)
end
ns.GuideLineText = LineText

-- "En chemin, fais aussi" of a step inside a dungeon (T-92): st.trash = the lines on the way to this
-- step's boss (where from st.trashWhere: "Tuer : X · <où> · 0 sur 8 · Tombe sur : ..."), st.trashAll =
-- what drops everywhere, on the first step inside only ("Tout le donjon : 25 x Y (tombent sur les
-- monstres)"). Done lines are left out. (No new main-chunk local: UI.lua is at Lua's 200 limit.)
function ns.GuideAlsoLines(st, log)
  local out, seen = {}, {}
  local function add(t) if t and t ~= "" and not seen[t] then seen[t] = true; out[#out + 1] = t end end
  for _, nd in ipairs(st.trashAll or {}) do
    if not ns.NodeOK(log, nd) then
      local o = nd.oneObj
      local nm = o and ObjName(nd, o, log, ns.State(log, nd.q))
      if nm then
        local c = type(o.c) == "number" and o.c or 1
        local t = L.ALSO_ALL:format(c > 1 and (c .. " x " .. nm) or nm)
        local ca, cb = ns.ObjCount(log, nd.q, o)
        if ca and type(cb) == "number" and cb > 1 then t = t .. SEP .. L.CARD_COUNT:format(ca, cb) end
        local go = ns.GROUP_OBJ and o.n and ns.GROUP_OBJ[o.n]
        local dr = (go ~= "*") and DropsText(o) or nil
        t = t .. (dr and (SEP .. dr) or (" " .. (c > 1 and L.ALSO_MOBS or L.ALSO_MOB)))
        add(t)
      else add(LineText(nd, log)) end
    end
  end
  for _, nd in ipairs(st.trash or {}) do
    if not ns.NodeOK(log, nd) then
      local a = st.trashWhere and st.trashWhere[nd]
      local where = a and ((ns.lang == "fr") and a[3] or a[2]) or nil
      local o = nd.oneObj
      local nm = o and log and ObjName(nd, o, log, ns.State(log, nd.q))
      if nm then
        local t = L[ns.ObjVerbKey(o, nm)]:format(nm)
        if where then t = t .. SEP .. where end
        local ca, cb = ns.ObjCount(log, nd.q, o)
        if not (ca and cb) and type(o.c) == "number" and o.c > 1 then ca, cb = 0, o.c end
        if ca and type(cb) == "number" and cb > 1 then t = t .. SEP .. L.CARD_COUNT:format(ca, cb) end
        local dr = o.k == "item" and DropsText(o) or nil
        if dr then t = t .. SEP .. dr end
        add(t)
      else
        local t = LineText(nd, log)
        add(where and t and (t .. SEP .. where) or t)
      end
    end
  end
  return out
end

-- The XP and money of a quest (the summary's numbers), for the turn-in's details
local function RewardText(qid)
  local q = ns.Q[qid] or {}
  local money = q.rw and q.rw ~= "" and q.rw or nil
  local xp = q.xp and q.xp > 0 and q.xp or nil
  if xp and ns.QuestXPFor then
    local okL, lv = pcall(function() return tonumber(UnitLevel("player")) end)
    local ok, got = pcall(ns.QuestXPFor, qid, okL and lv or 1)
    if ok and type(got) == "number" then xp = got > 0 and got or nil end
  end
  if xp and ns.BigNumber then xp = ns.BigNumber(xp) end
  local out = {}
  if xp and money then out[#out + 1] = L.TT_XPMONEY:format(xp, money)
  elseif xp then out[#out + 1] = L.TT_XP:format(xp)
  elseif money then out[#out + 1] = L.TT_REWARD:format(money) end
  if q.ri and q.ri[1] then out[#out + 1] = Hex(T.gold) .. L.TT_REWARD:format(table.concat(q.ri, q.rc and " / " or ", ")) .. "|r" end
  return #out > 0 and table.concat(out, "\n") or nil
end

-- What the card says about the current action, each fact once (docs: T-37). It answers WHAT (the
-- title), WHERE (NPC for a giver or a turn-in, zone, distance), WHY (one muted line: the quest, the
-- chain), then the details, folded. -> table:
--   title, icon (HD name, nil = the kind's own mark), lead, drops, where, placeBase, pt {m,x,y},
--   noFar, travel, why {..}, objs {..}, details {..}, desc, gpsTip {..}, ok
-- The card's "first to <zone>" line of a step (ns.StepWhyFirst's text) or nil, cached per step
-- (weak keys: a rebuilt route drops its old steps) and per player's map and route
-- (in a do block: the main chunk is at Lua 5.1's 200 locals)
do
  local whyFirstCache = setmetatable({}, { __mode = "k" })
  function ns.GuideWhyFirst(st)
    if not (st and ns.StepWhyFirst) then return nil end
    local steps = ns.route and ns.route.steps
    local here = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
    local c = whyFirstCache[st]
    if c and c.here == here and c.steps == steps then return c.text end
    local okW, w = pcall(ns.StepWhyFirst, st, steps, here)
    local text = okW and type(w) == "table" and type(w.text) == "string" and w.text ~= "" and w.text or nil
    whyFirstCache[st] = { here = here, steps = steps, text = text }
    return text
  end
end

local function FocusModel(card, nd, log, dkey, st)
  local q = ns.Q[nd.q] or {}
  local s = ns.State(log, nd.q)
  local ok = ns.NodeOK(log, nd)
  local inLog = (s == "on" or s == "ready")
  local tx, mt = Hex(T.text), Hex(T.muted)
  local M = { why = {}, objs = {}, details = {}, detBlocks = {}, gpsTip = {}, ok = ok }
  local qn = nd.q and ns.QName(nd.q) or ""
  local kind = nd.kind
  local obj = ns.GuideObjSentence(q)
  local desc
  if inLog and ns.GameQuestText then
    local gdesc, gobj = ns.GameQuestText(nd.q, log)
    if not obj then obj = gobj end
    -- our data is thin (no objectives, no note): the game's own description says where to go
    if gdesc and not q.ne and not (q.o and #q.o > 0) then desc = gdesc end
  end
  M.desc = desc

  -- WHAT: the action, never the NPC
  local o, objName
  local objMoved = false
  if kind == "a" or kind == "t" or kind == "h" or kind == "i" then
    M.title = L[FOCUS_KEY[kind]]:format(NodeName(nd))
  else
    o = nd.oneObj or (kind == "o" and nd.obj) or nil
    if not o then
      for _, x in ipairs(q.o or {}) do if not ns.ObjDone(log, nd.q, x) then o = x; break end end
    end
    if o then
      local t, ok2, nm = ObjLine(nd, o, log, s)
      M.title, M.icon, objName = t, OBJ_ICON[ok2], nm
      -- the quest's whole sentence as its only objective: "Do « X »", then the sentence (French when we have it)
      if o.k == "text" and obj and not ok then M.lead = obj; objMoved = true end
    else
      local game = (inLog and ns.GameObjectives) and ns.GameObjectives(nd.q, log) or {}
      local g
      for _, x in ipairs(game) do if not x.fin then g = x; break end end
      if g then M.title = g.text
      else
        M.title = L.TR_DO:format(qn)
        -- nothing says what to do but the quest's sentence: it shows, not folded
        if obj and not ok then M.lead = obj; objMoved = true end
      end
    end
  end
  -- the drops of the objective in the title
  M.drops = o and DropsText(o) or nil
  -- elite or not, for the mobs of an objective outside a dungeon
  local em = o and EliteMark(o)
  if em then M.drops = M.drops and (M.drops .. SEP .. em) or em end

  -- WHERE: the NPC who gives or takes the quest, the zone, the distance
  local m, x, y = NodePoint(nd)
  local src = ArrowSource(nd)
  local place = {}
  local npc = NpcShort(nd)
  -- the NPC stands out (report: "the NPC's name is not shown enough"): the main text colour
  if npc and kind ~= "c" and kind ~= "o" then place[#place + 1] = Hex(T.fg) .. npc .. "|r" end
  if m then
    local zn = ZoneName(m)
    if zn ~= "" then place[#place + 1] = zn end
    M.pt = { m, x, y }
  end
  if src == "log" then
    M.placeBase = Hex(T.warn) .. L.ARROW_LOG .. "|r"
  else
    M.placeBase = table.concat(place, SEP)
  end
  local trKey = st and st.travel
  if M.pt then trKey = ns.GuideLiveTravelKey(st, m, x, y) end
  -- the place line already says the spot is unknown: the travel line does not say it again
  -- (or the WHY line says it, for an action with no known spot)
  if trKey == "TRAVEL_UNK" and (src == "log" or nd.unknown) then trKey = nil end
  M.trKey = trKey
  M.noFar = trKey == "TRAVEL_CONT" or nil
  local dist = M.pt and DistText(m, x, y) or nil
  if dist == L.ARROW_FAR and M.noFar then dist = nil end
  M.dist = dist
  if dist then
    M.where = (M.placeBase ~= "" and (M.placeBase .. SEP) or "") .. mt .. dist .. "|r"
  else
    M.where = M.placeBase ~= "" and M.placeBase or nil
  end
  M.travel = trKey and TravelText(st, m, x, y, trKey) or nil

  -- WHY: one muted line, the quest then the chain. When the title already names the quest (a
  -- turn-in, "Faire « X »"), the line keeps the fact (a dungeon quest) and not the name again.
  local why = {}
  local titleQ = qn ~= "" and type(M.title) == "string" and M.title:find(qn, 1, true) ~= nil
  if (kind == "c" or kind == "o" or kind == "t" or kind == "i") and qn ~= "" then
    local main = q.role ~= "pre" and q.d and not nd.pre
    if titleQ then
      if main then why[#why + 1] = L.CARD_WHY_MAIN_S end
    elseif main then why[#why + 1] = L.CARD_WHY_MAIN:format(qn)
    else why[#why + 1] = L.CARD_WHY_Q:format(qn) end
  elseif s == "none" then
    local lf = LevelFact(nd.q, s)
    if lf then why[#why + 1] = lf .. mt end
  end
  -- the dungeon's own quest, taken outside: why now (it is done inside)
  if kind == "a" and q.role == "main" and q.d and not nd.pre and not nd.ins and nd.phase ~= "after" and s == "none" then
    local okB, r = pcall(BeforeReason, nd.q, nd.d)
    if okB and r == nil then why[#why + 1] = L.CARD_TAKE_MAIN end
  end
  if nd.pre then
    local lead = nd.forQ and nd.forQ[1]
    -- the card also says "Requis pour « Y »" below when the dungeon needs another quest of the
    -- chain: then the chain line does not name a different end
    local okB, nx = false, nil
    if nd.q and nd.phase ~= "after" then okB, nx = pcall(BeforeReason, nd.q, nd.d) end
    if nd.ci and nd.cn and lead and okB and nx and nx ~= lead and ns.QName(nx) ~= ns.QName(lead) then
      why[#why + 1] = L.CARD_PRE_N:format(nd.ci, nd.cn)
    elseif nd.ci and nd.cn and lead then
      why[#why + 1] = ns.GuideChainText(nd)
    elseif nd.ci and nd.cn then why[#why + 1] = L.CARD_PRE_N:format(nd.ci, nd.cn)
    else why[#why + 1] = Low(L.PRE) end
  elseif kind == "a" and ns.ChainState then
    local cs = ns.ChainState(nd.q)
    if cs.total == 0 then -- "no prerequisite": nothing worth a word
    elseif cs.done >= cs.total then why[#why + 1] = Hex(T.ok) .. Low(L.CH_ALLDONE) .. "|r" .. mt
    else why[#why + 1] = Hex(T.warn) .. Low(L.ST_PRE:format(cs.done + 1, cs.total)) .. "|r" .. mt end
  end
  if nd.d and nd.d ~= dkey then why[#why + 1] = L.CARD_FOR_DG:format(ns.DName(nd.d) or nd.d) end
  if #why > 0 then
    why[1] = Cap(why[1])
    M.why[1] = mt .. table.concat(why, SEP) .. "|r"
  end
  -- a quest you cannot take yet: said first, on its own line, in red
  if kind == "a" and s == "none" then
    local rq = num(q.r)
    local okP, pl = pcall(function() return num(UnitLevel("player")) end)
    pl = (okP and pl) or nil
    if rq and pl and rq > pl then table.insert(M.why, 1, Hex(T.bad) .. L.CARD_TOO_LOW:format(rq, pl) .. "|r") end
  end
  -- every action done (the step waits on something else): the muted title and the WHY line only
  if ok then
    M.drops, M.where, M.placeBase, M.pt, M.dist, M.travel, M.lead = nil, nil, nil, nil, nil, nil, nil
    return M
  end
  -- then, each in its own colour: what blocks it, the state when it is not the expected one, the
  -- party, the class
  if kind == "a" and s == "none" and not NeedShown(nd.q, s) then
    local pb = ns.PrereqProblem(nd.q)
    if pb then M.why[#M.why + 1] = Hex(T.bad) .. L.BLOCKED:format(pb) .. "|r" end
  end
  if (kind == "c" or kind == "o" or kind == "t") and s == "none" then
    -- a quest that starts from an item in the bags (Oathstone...): say which item, not "accept it"
    local qq = ns.Q[nd.q]
    local startItem = qq and qq.s and qq.s.i == 1 and (qq.si or qq.s.n)
    if startItem and L.CARD_NOTLOG_ITEM then
      local nm = (ns.LN and ns.LN("item", startItem)) or startItem
      M.why[#M.why + 1] = Hex(T.warn) .. L.CARD_NOTLOG_ITEM:format(nm) .. "|r"
    else
      M.why[#M.why + 1] = Hex(T.warn) .. L.CARD_NOTLOG .. "|r"
    end
  elseif kind == "t" and s == "on" then
    M.why[#M.why + 1] = Hex(T.warn) .. L.CARD_NOTREADY .. "|r"
  end
  if nd.unknown and src ~= "log" then M.why[#M.why + 1] = Hex(T.warn) .. L.TRAVEL_UNK .. "|r" end
  -- a step before the dungeon: why now (its chain goes on inside) or that it is optional
  -- (T-87) and the same for a main quest of the dungeon done outside it (Shadowshard Fragments):
  -- "Optional: the dungeon can be done without it · on the way to the portal" or "Required for X";
  -- nothing on a step after the dungeon (the follow-up of a chain done inside)
  -- A step away from the player's zone that comes first because a line back here needs it
  -- (ns.StepWhyFirst, "First to Feralas: you need X before talking to Y in Tanaris"): that one
  -- line takes the place of the "Required for" / "Optional" line, never both
  local wf = ns.GuideWhyFirst(st)
  if wf then M.why[#M.why + 1] = mt .. wf .. "|r"
  elseif nd.q and nd.phase ~= "after" and (nd.pre or q.role == "pre" or (q.role == "main" and not nd.ins and kind ~= "t" and kind ~= "h")) then
    local okB, nx, way = pcall(BeforeReason, nd.q, nd.d)
    if okB and nx then M.why[#M.why + 1] = mt .. (way and L.CARD_BEFORE_KEY or L.CARD_BEFORE_WHY):format(ns.QName(nx)) .. "|r"
    elseif okB and nx == false then M.why[#M.why + 1] = mt .. L.CARD_BEFORE_OPT .. (way and L.CARD_BEFORE_WAY or "") .. "|r" end
  end
  -- the NPC who gives or takes the quest walks along a path (Writs/Patrol.lua): his point on the
  -- map is one spot of it, the card says so (warn: he may not stand where the arrow points)
  do
    local PWP = ns.Writs and ns.Writs.WP
    local which = (kind == "a" or kind == "h") and "s" or (kind == "t" and "f") or nil
    if which and nd.q and PWP and PWP.Patrol and PWP.Patrol.CardText then
      local okP, pt = pcall(PWP.Patrol.CardText, nd.q, which)
      if okP and type(pt) == "string" and pt ~= "" then M.why[#M.why + 1] = Hex(T.warn) .. pt .. "|r" end
    end
  end
  -- an objective spread over an area (o.area, Curated.lua): where to look in it, when the data says
  do
    local a = ns.AreaOf and ns.AreaOf(nd)
    if a and type(a.note) == "string" and a.note ~= "" then M.why[#M.why + 1] = tx .. ns.T(a.note) .. "|r" end
  end
  if ns.PartyLine then
    local pl = ns.PartyLine(nd.q)
    if pl then M.why[#M.why + 1] = tx .. pl .. "|r" end
  end
  if q.c and not (card and card.clsChip and card.clsChip:IsShown()) then
    local tok = ns.GuideClassTok(q.c); local cn, cc = ns.ClassInfo(tok)
    M.why[#M.why + 1] = ns.ClassIconText(tok, 12) .. Hex(cc) .. L.CLASS_TAG:format(cn) .. "|r"
  end

  -- the other objectives (2 or more), or what is left before a turn-in
  if kind == "t" and s == "on" then
    local lines = ObjectiveBlock(nd, log, s)
    for _, l2 in ipairs(lines) do if type(l2) == "string" then M.objs[#M.objs + 1] = l2 end end
    if #M.objs == 0 then
      for _, r2 in ipairs(q.req or {}) do
        M.objs[#M.objs + 1] = r2[1] .. (r2[2] and r2[2] > 1 and (" x" .. r2[2]) or "") .. (r2[3] and (L.COLON .. ns.T(r2[3])) or "")
      end
    end
  elseif (kind == "c" or kind == "o") and not (nd.oneObj or (kind == "o" and nd.obj)) then
    local list = q.o or {}
    if #list >= 2 and o then
      for _, x2 in ipairs(list) do
        if x2 ~= o then
          local t = ObjLine(nd, x2, log, s)
          if ns.ObjDone(log, nd.q, x2) then
            t = CHECK_T .. mt .. t:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "") .. "|r"
          end
          M.objs[#M.objs + 1] = t
        end
      end
    elseif #list == 0 and inLog and ns.GameObjectives then
      local game = ns.GameObjectives(nd.q, log)
      if #game >= 2 then
        for _, g in ipairs(game) do
          if g.text ~= M.title then
            M.objs[#M.objs + 1] = g.fin and (CHECK_T .. mt .. g.text .. "|r") or g.text
          end
        end
      end
    end
  end

  -- DETAILS, folded: what the quest will ask (a quest to take), the reward (a turn-in), our notes,
  -- the journal's note, the game's text
  -- M.details: one string per block (the flat list); M.detBlocks: the same blocks with their
  -- heading apart, drawn by DrawBlocks (gold heading, then the text or a list)
  local H = Hex(T.fg)
  local det, dbl = M.details, {}
  M.detBlocks = dbl
  local function Det(h, text, list)
    if list then
      det[#det + 1] = (h and (H .. h .. "|r\n") or "") .. table.concat(list, "\n")
      dbl[#dbl + 1] = { h = h, list = list }
    else
      det[#det + 1] = h and (H .. h .. "|r\n" .. text) or text
      dbl[#dbl + 1] = { h = h, body = { text } }
    end
  end
  if obj and not objMoved then
    if kind == "a" or kind == "h" then Det(L.CARD_ASKS, obj)
    elseif kind ~= "t" then Det(nil, obj) end
  end
  if kind == "t" then
    local rw = RewardText(nd.q)
    if rw then Det(L.CARD_GETS, rw) end
  end
  if q.ne and kind ~= "t" then Det(nil, ns.T(q.ne)) end
  if nd.extra then Det(nil, nd.extra) end
  if kind == "a" and q.si then Det(nil, q.si .. (q.sih and (L.COLON .. ns.T(q.sih)) or "")) end
  if kind == "c" and ns.BossLines and not nd.oneObj then
    -- the bosses that drop it: "Boss" once, then one line per boss (its name, then where)
    local bl2 = {}
    for _, bl in ipairs(ns.BossLines(nd.q) or {}) do
      bl2[#bl2 + 1] = H .. bl[1] .. "|r" .. (bl[2] and ("  " .. bl[2]) or "")
    end
    if #bl2 > 0 then Det(L.BOSS, nil, bl2) end
  end
  -- ForeverDungeonJournal's note only when we have none of our own (each said once)
  local fdj = (not q.ne) and ns.FDJNote and ns.FDJNote(nd.q) or nil
  if fdj then Det(L.FDJ_NOTE, fdj) end
  if desc then Det(L.GAME_TEXT, desc) end

  -- the GPS button's tooltip: where it leads, how the arrow finds it, the click
  if nd.loc or x then
    local who = (kind == "a" or kind == "t" or kind == "h") and (npc or qn) or (objName or npc or qn)
    M.gpsTip[1] = L.TT_GPS:format(who, x or nd.loc.x, y or nd.loc.y)
    if src == "game" then M.gpsTip[#M.gpsTip + 1] = mt .. L.ARROW_GAME .. "|r" end
    M.gpsTip[#M.gpsTip + 1] = L.TT_GPS_CLICK
  elseif src == "game" then
    M.gpsTip[1] = mt .. L.ARROW_GAME .. "|r"
  end
  return M
end
ns.FocusModel = function(nd, log, dkey, st) return FocusModel(f and f.card, nd, log, dkey, st) end

-- The old flat list (the tests read it): title, lead, drops, where, why, objectives, details, GPS
-- tooltip. -> lines, the game's description (or nil)
local function FocusParts(card, nd, log, dkey)
  local M = FocusModel(card, nd, log, dkey)
  local flat = {}
  local function add(v) if v and v ~= "" then flat[#flat + 1] = v end end
  add(M.title); add(M.lead); add(M.drops); add(M.where)
  for _, l2 in ipairs(M.why) do add(l2) end
  for _, l2 in ipairs(M.objs) do add(l2) end
  for _, l2 in ipairs(M.details) do add(l2) end
  for _, l2 in ipairs(M.gpsTip) do add(l2) end
  return flat, M.desc
end
ns.FocusParts = function(nd, log, dkey) return FocusParts(f and f.card, nd, log, dkey) end

-- the distance on the WHERE line follows you (1 s), and the card re-lays out only when that line's
-- height changes or the line appears (at most once a second; one that comes too soon waits for the
-- next tick). Text only: no secure frame, nothing else in combat.
local function FocusTick(fo, el)
  fo.tick = (fo.tick or 0) + (type(el) == "number" and el or 0)
  if fo.tick < 1 then return end
  fo.tick = 0
  local now = GetTime and GetTime() or 0
  local function Relayout()
    if not fo.relaidAt or now - fo.relaidAt >= 1 then
      fo.relaidAt = now; fo.relayoutDue = nil; ns.Render()
    else fo.relayoutDue = true end
  end
  if fo.relayoutDue then Relayout(); return end
  local M = fo.model
  if not (M and M.pt and fo.node and fo:IsShown()) then return end
  -- you crossed to or from another continent, or the 1400 yd mark: the travel line changes
  if M.trKey ~= "TRAVEL_UNK" and ns.GuideLiveSpan(M.pt[1], M.pt[2], M.pt[3]) ~= nil
    and ns.GuideLiveTravelKey(fo.step, M.pt[1], M.pt[2], M.pt[3]) ~= M.trKey and fo.step then Relayout(); return end
  local d = DistText(M.pt[1], M.pt[2], M.pt[3])
  if d == L.ARROW_FAR and M.noFar then d = nil end
  if d == M.dist then return end
  M.dist = d
  -- the line was empty (no zone name, no distance yet): the card makes room for it
  if not fo.place:IsShown() then
    if d then Relayout() end
    return
  end
  local base = M.placeBase or ""
  local t = d and ((base ~= "" and (base .. SEP) or "") .. Hex(T.muted) .. d .. "|r") or base
  local h0 = num(fo.place:GetStringHeight())
  fo.place:SetText(t)
  local h1 = ns.FitText(fo.place, 2, fo.placeW, fo.cutSink)
  if h0 and h1 and math.abs(h1 - h0) > 0.5 then Relayout() end
end

-- the check-list's entrance line ("Entrée : Terres Ingrates 42.1, 13.3 · 1,2 km") follows you the
-- same way (1 s, text only)
local function WhereTick(self, el)
  self.t = (self.t or 0) + (type(el) == "number" and el or 0)
  if self.t < 1 then return end
  self.t = 0
  local card = self.card
  local p = card and card.wlPt
  if not (p and card.whereLine and card.whereLine:IsShown()) then return end
  local d = DistText(p[1], p[2], p[3])
  if d == card.wlDist then return end
  card.wlDist = d
  local h0 = num(card.whereLine:GetStringHeight())
  card.whereLine:SetText((card.wlBase or "") .. (d and (Hex(T.muted) .. SEP .. d .. "|r") or ""))
  local h1 = ns.FitText(card.whereLine, 2, card.wlW or TextW(), card)
  if h0 and h1 and math.abs(h1 - h0) > 0.5 then ns.Render() end
end

local function MakeFocus(card)
  local fo = CreateFrame("Button", nil, card)
  -- no box inside the card: hover, press and "followed" tints only
  fo.wpOn = Tex(fo, "BACKGROUND", T.selFill); fo.wpOn:SetAllPoints(); fo.wpOn:Hide()
  fo.hl = Tex(fo, "HIGHLIGHT", T.hoverFill); fo.hl:SetAllPoints()
  fo.press = Tex(fo, "ARTWORK", T.pressFill); fo.press:SetAllPoints(); fo.press:Hide()
  fo.icon = fo:CreateTexture(nil, "ARTWORK"); fo.icon:SetSize(20, 20); fo.icon:SetPoint("TOPLEFT", 8, -8)
  fo.head = Text(fo, ns.F.title, T.fg); Size(fo.head, ns.F.title)
  fo.lead = Text(fo, ns.F.label, T.text); fo.lead:Hide()
  fo.drops = Text(fo, ns.F.meta, T.muted); fo.drops:Hide()
  fo.place = Text(fo, ns.F.body, T.text)
  fo.travel = Text(fo, ns.F.meta, T.text); fo.travel:Hide()
  fo.body = Text(fo, ns.F.meta, T.muted); fo.body:SetSpacing(3)
  -- the other objectives: a list (dot, then the words, wrapped lines under the first word)
  fo.objList = ns.TyBullets(fo)
  -- the opened details sit in their own frame: a click there reads, it does not start the GPS.
  -- Each block: a gold heading ("Ce qu'elle demandera"), then its text (design system 3.21)
  fo.detBox = CreateFrame("Frame", nil, fo); fo.detBox:EnableMouse(true); fo.detBox:Hide()
  fo.detStk = ns.TextStack(fo.detBox)
  -- older name (the game's text now sits in the details)
  fo.gtext = Text(fo, ns.F.meta, T.muted); fo.gtext:SetSpacing(2); fo.gtext:Hide()
  -- the block's tooltip (RowTip) already says the name, the place and the game's description in
  -- its own blocks: their cut labels are kept apart, not put first in the tooltip
  fo.cutSink = {}
  local gb
  gb = LabelBtn(fo, "GPS", 24, "secondary", function(self) local n = self.row.node; if ns.NodeCanGo(n) then ns.SetOne(n) end end,
    function()
      local M = gb and gb.row and gb.row.model
      if not (M and M.gpsTip and M.gpsTip[1]) then return nil end
      return M.gpsTip
    end)
  if gb.SetIcon then gb:SetIcon("pin") end
  gb.row = fo
  fo.gb = gb
  -- "Détails" (a ghost link with its chevron): the details stay open from step to step
  local more
  more = LabelBtn(fo, L.CARD_MORE, 16, "ghost", function()
    WLDTDB.cardDetails = (not WLDTDB.cardDetails) or nil
    ns.Render()
  end, function() return { WLDTDB.cardDetails and L.CARD_LESS_TT or L.CARD_MORE_TT } end)
  more:Hide()
  fo.more = more
  fo:SetScript("OnClick", function(self) local n = self.node; if ns.NodeCanGo(n) then ns.SetOne(n) end end)
  fo:SetScript("OnMouseDown", function(self) if ns.NodeCanGo(self.node) then self.press:Show() end end)
  fo:SetScript("OnMouseUp", function(self) self.press:Hide() end)
  fo:SetScript("OnEnter", function(self) ns.RowTip(self) end)
  fo:SetScript("OnLeave", ns.HideTip)
  fo:SetScript("OnUpdate", FocusTick)
  fo:Hide()
  card.focus = fo
  -- a 1 px rule, then "Then at Mordent Evenshade:" and one small line per other action
  card.nextRule = Tex(card, "ARTWORK", T.divider); card.nextRule:SetHeight(1); card.nextRule:Hide()
  card.nextHdr = Text(card, ns.F.label, T.fg); card.nextHdr:Hide()
  card.lines = {}
  for k = 1, NEXT_MAX do
    local ln = CreateFrame("Button", nil, card)
    ln:SetHeight(22)
    ln.hl = Tex(ln, "HIGHLIGHT", T.hoverFill); ln.hl:SetAllPoints()
    ln.press = Tex(ln, "ARTWORK", T.pressFill); ln.press:SetAllPoints(); ln.press:Hide()
    ln.icon = ln:CreateTexture(nil, "ARTWORK"); ln.icon:SetSize(14, 14); ln.icon:SetPoint("LEFT", 10, 0)
    ln.text = Text(ln, ns.F.label, T.text); ln.text:SetPoint("LEFT", 32, 0); ln.text:SetPoint("RIGHT", -8, 0); ln.text:SetJustifyV("MIDDLE")
    ns.ClampLabel(ln.text, nil, ln)
    ln:SetScript("OnClick", function(self) local n = self.node; if ns.NodeCanGo(n) then ns.SetOne(n) end end)
    ln:SetScript("OnMouseDown", function(self) if ns.NodeCanGo(self.node) then self.press:Show() end end)
    ln:SetScript("OnMouseUp", function(self) self.press:Hide() end)
    ln:SetScript("OnEnter", function(self) ns.RowTip(self) end)
    ln:SetScript("OnLeave", ns.HideTip)
    ln:Hide()
    card.lines[k] = ln
  end
  card.doneIcon = ns.Icon(card, "check", 14, "ARTWORK", T.ok); card.doneIcon:Hide()
  card.doneLine = Text(card, ns.F.meta, T.muted); card.doneLine:Hide()
end

local function HideFocus(card)
  if not card.focus then return end
  local fo = card.focus
  fo.node = nil; fo.model = nil; fo:Hide(); card.nextHdr:Hide(); card.nextRule:Hide(); card.doneLine:Hide(); card.doneIcon:Hide()
  for _, x in ipairs({ fo.lead, fo.drops, fo.travel, fo.detBox, fo.gtext, fo.more }) do x:Hide() end
  fo.objList:Hide(); fo.detText = nil
  for _, ln in ipairs(card.lines) do ln.node = nil; ln:Hide() end
end

-- Draws the current action at y (the block's top) and the list of the others; returns the new y.
local function RenderFocus(card, st, log, y, dkey)
  local fo = card.focus
  local rowW = CardW() - 8
  local k = FocusIndex(st, log)
  local nd = st.acts[k]
  local M = FocusModel(card, nd, log, dkey, st)
  local ok = M.ok
  fo.node, fo.model, fo.step = nd, M, st
  -- hover feedback only when a click does something (a place to follow)
  local canGo = ns.NodeCanGo(nd)
  fo.hl:SetShown(canGo)
  fo.icon:SetVertexColor(1, 1, 1)
  if ok then ns.SetHDIcon(fo.icon, "check", T.ok)
  elseif M.icon then ns.SetHDIcon(fo.icon, M.icon, T.muted)
  -- no kind icon: an empty slot (alpha 0) rather than a dot that says nothing
  elseif not SetKindIcon(fo.icon, nd) then ns.SetHDIcon(fo.icon, "dot", T.muted, 0) end
  -- the GPS button at the top right, centred on the title's first line; followed: the block is
  -- selected and the button says so
  local isActive = canGo and NodeFollowed(nd) and not ok
  fo.wpOn:SetShown(isActive and true or false)
  local gpsW = 0
  if canGo and not ok then
    fo.gb:SetText(isActive and L.GPS_ON or "GPS")
    fo.gb:ClearAllPoints(); fo.gb:SetPoint("TOPRIGHT", fo, "TOPRIGHT", -12, -6); fo.gb:Show()
    gpsW = (num(fo.gb:GetWidth()) or 60) + 8
  else fo.gb:Hide() end
  local headW = math.max(80, rowW - FOCUS_X - 12 - gpsW)
  local bodyW = rowW - FOCUS_X - 12
  local yy = 8
  fo.head:SetText(M.title or NodeName(nd))
  local hc = ok and T.muted or T.fg
  fo.head:SetTextColor(hc[1], hc[2], hc[3])
  fo.head:ClearAllPoints(); fo.head:SetPoint("TOPLEFT", fo, "TOPLEFT", FOCUS_X, -yy)
  yy = yy + ns.FitText(fo.head, 2, headW, fo.cutSink)
  if fo.gb:IsShown() then yy = math.max(yy, 6 + 24) end
  local function Put(fs, text, gap, maxLines, w)
    if text and text ~= "" then
      fs:SetText(text)
      fs:ClearAllPoints(); fs:SetPoint("TOPLEFT", fo, "TOPLEFT", FOCUS_X, -(yy + gap)); fs:Show()
      yy = yy + gap + ns.FitText(fs, maxLines, w or bodyW, fo.cutSink)
    else fs:SetText(""); fs:Hide() end
  end
  Put(fo.lead, M.lead, 4, 0)
  Put(fo.drops, M.drops, 3, 2)
  fo.placeW = bodyW
  Put(fo.place, M.where, 8, 2)
  Put(fo.travel, M.travel, 3, 0)
  Put(fo.body, table.concat(M.why, "\n"), 8, f.compactIn and 4 or 0)
  -- the other objectives (or what is left before a turn-in): a list, 12 px under the WHY lines
  if #M.objs > 0 then
    -- a done objective: its check takes the dot's place (one marker per item, the words in line)
    local items, marks = {}, {}
    for n2, l2 in ipairs(M.objs) do
      if l2:sub(1, #CHECK_T) == CHECK_T then items[n2], marks[n2] = l2:sub(#CHECK_T + 1), "check"
      else items[n2] = l2 end
    end
    yy = yy + 12 + fo.objList:Place(items, FOCUS_X, yy + 12, bodyW, { marks = marks })
  else fo.objList:Hide() end
  -- the details, folded under "Détails"
  local blocks = M.detBlocks or {}
  local hasDet = #blocks > 0
  local open = hasDet and WLDTDB.cardDetails and true or false
  if hasDet then
    fo.more:SetText(open and L.CARD_LESS or L.CARD_MORE)
    ns.SetHDIcon(fo.more.chev, open and "chevron_up" or "chevron_down", T.accentSoft); fo.more.chev:Show()
    if fo.more.Fit then fo.more:Fit() end
    if fo.more.Paint then fo.more.Paint() end
    -- the label's left edge on the text edge (the link keeps its 12 px padding)
    fo.more:ClearAllPoints(); fo.more:SetPoint("TOPLEFT", fo, "TOPLEFT", FOCUS_X - 12, -(yy + 12)); fo.more:Show()
    yy = yy + 12 + 16
  else fo.more:Hide() end
  local detTop = yy
  -- opened: each block's gold heading, then its text, inside detBox (8 px under the link)
  local detOpen = open and hasDet
  fo.detText = nil
  if detOpen then
    yy = yy + 8 + DrawBlocks(fo.detStk, blocks, FOCUS_X, 8, bodyW)
    fo.detText = BlocksText(blocks)
  end
  fo.gtext:Hide()
  local fh = math.max(44, math.ceil(yy + 10))
  fo:SetWidth(rowW); fo:SetHeight(fh)
  -- hover and press cover the part a click acts on; the opened details are text to read
  fo.hl:ClearAllPoints(); fo.press:ClearAllPoints()
  if detOpen then
    fo.detBox:ClearAllPoints()
    fo.detBox:SetPoint("TOPLEFT", fo, "TOPLEFT", 0, -detTop); fo.detBox:SetPoint("BOTTOMRIGHT", fo, "BOTTOMRIGHT", 0, 0)
    fo.detBox:Show()
    for _, x in ipairs({ fo.hl, fo.press }) do
      x:SetPoint("TOPLEFT", fo, "TOPLEFT", 0, 0); x:SetPoint("BOTTOMRIGHT", fo, "TOPRIGHT", 0, -detTop)
    end
  else
    fo.detBox:Hide()
    fo.hl:SetAllPoints(); fo.press:SetAllPoints()
  end
  fo:ClearAllPoints(); fo:SetPoint("TOPLEFT", card, "TOPLEFT", 4, -y); fo:Show()
  y = y + fh
  -- the other actions of the step: open ones under "Then at <NPC>:", finished ones on one line
  local others, done = {}, {}
  for j, a in ipairs(st.acts) do
    if j ~= k then
      if ns.NodeOK(log, a) then done[#done + 1] = a else others[#others + 1] = a end
    end
  end
  local TW = TextW()
  local npc = NpcShort(nd)
  local function atKind(a) return a.kind == "a" or a.kind == "t" or a.kind == "h" end
  local atNpc = npc and atKind(nd) and npc or nil
  -- "Then at <NPC>:" only when every open action is at that NPC; else "Then:" and each line names
  -- its own NPC
  if atNpc then
    for _, a in ipairs(others) do
      if not (atKind(a) and NpcShort(a) == atNpc) then atNpc = nil; break end
    end
  end
  if #others > 0 then
    y = y + 16
    card.nextRule:ClearAllPoints(); card.nextRule:SetPoint("TOPLEFT", card, "TOPLEFT", CI, -y); card.nextRule:SetWidth(TW); card.nextRule:Show()
    y = y + 1 + 12
    card.nextHdr:SetText(atNpc and L.NEXT_AT:format(atNpc) or L.NEXT_PLAIN)
    card.nextHdr:ClearAllPoints(); card.nextHdr:SetPoint("TOPLEFT", card, "TOPLEFT", CI, -y); card.nextHdr:Show()
    y = y + ns.FitText(card.nextHdr, 2, TW, card) + 4
  else card.nextHdr:Hide(); card.nextRule:Hide() end
  for j, ln in ipairs(card.lines) do
    local a = others[j]
    if a then
      ln.node = a
      ln.hl:SetShown(ns.NodeCanGo(a))
      ln.icon:SetVertexColor(1, 1, 1)
      if not SetKindIcon(ln.icon, a) then ns.SetHDIcon(ln.icon, "dot", T.muted, 0) end
      local t = LineText(a, log)
      -- the NPC where the line is done (a quest giver or taker); a kill or loot line's "NPC" is its
      -- own target, already in the text
      local an = atKind(a) and NpcShort(a) or nil
      if an and an ~= atNpc and not t:find(an, 1, true) then t = t .. Hex(T.muted) .. SEP .. an .. "|r" end
      ln.text:SetText(t)
      ln:SetWidth(rowW)
      ln:ClearAllPoints(); ln:SetPoint("TOPLEFT", card, "TOPLEFT", 4, -y); ln:Show()
      y = y + 22
    else ln.node = nil; ln:Hide() end
  end
  if #done > 0 then
    local names = {}
    for _, a in ipairs(done) do names[#names + 1] = LineText(a, log) end
    y = y + 8
    card.doneIcon:ClearAllPoints(); card.doneIcon:SetPoint("TOPLEFT", card, "TOPLEFT", CI, -(y + 1)); card.doneIcon:Show()
    card.doneLine:SetText(L.DONE_HERE:format(table.concat(names, ", ")))
    card.doneLine:ClearAllPoints(); card.doneLine:SetPoint("TOPLEFT", card, "TOPLEFT", CI + 20, -y); card.doneLine:Show()
    y = y + ns.FitText(card.doneLine, 3, TW - 20, card)
  else card.doneLine:Hide(); card.doneIcon:Hide() end
  return y
end

-- =====================================================================
--  Build
-- =====================================================================
-- A saved position we can use: two anchor names and two plain numbers (an old or broken one is
-- dropped, and the window opens at its first place again).
local function SavedPos(pos)
  if type(pos) ~= "table" or type(pos[1]) ~= "string" or type(pos[2]) ~= "string" then return nil end
  local x, y = pos[3], pos[4]
  if type(x) ~= "number" or type(y) ~= "number" or x ~= x or y ~= y or x == math.huge or x == -math.huge
    or y == math.huge or y == -math.huge then return nil end
  return pos
end
ns.GuideSavedPos = SavedPos
-- The first place of the guide (no saved position): left of the screen's centre, its right edge
-- 60 px from the middle and its top a little under the top of the screen, never on the right
-- where the quest tracker and the minimap are. The step list stays closed until you open it.
local function FirstPlace()
  f:ClearAllPoints(); f:SetPoint("TOPRIGHT", UIParent, "TOP", -60, -140)
end
ns.GuideFirstPlace = function() if f then FirstPlace() end end

local function Build()
  f = CreateFrame("Frame", "WLDTFrame", UIParent)
  f.wlOwned = true
  f:SetSize(W, 300); f:SetFrameStrata("MEDIUM")
  local pos = SavedPos(WLDTDB.pos)
  if pos then f:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4]) else WLDTDB.pos = nil; FirstPlace() end
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
    PlaceList()
    if f.listToggle and f.listToggle.SetIcon then f.listToggle:SetIcon(ListChevron()) end
    if ns.UpdateActionBar then ns.UpdateActionBar() end
  end)
  h.rule = ns.Rule(f, T.line); h.rule:SetPoint("TOPLEFT", 0, -HEADER); h.rule:SetPoint("TOPRIGHT", 0, -HEADER)
  local function GoHome()
    local WP = ns.Writs and ns.Writs.WP
    if WP and WP.OpenHome then WP.OpenHome() end
  end
  -- one HD "<" back to the home page (the guild logo stays on the Home window)
  f.homeBtn = (SW().BackButton or SW().BackLogo)(h, GoHome)
  f.homeBtn:SetPoint("TOPLEFT", 6, -8)
  h.title = Text(h, ns.F.title, T.fg); h.title:SetText(L.DUNGEONS)
  h.sub = Text(h, ns.F.meta, T.muted)
  ns.ClampLabel(h.title, nil, h); ns.ClampLabel(h.sub, nil, h)
  f.header = h
  local close = IconBtn(h, "close", function() return { L.TT_HCLOSE, L.TT_HCLOSE2, L.TT_HCLOSE_CLICK } end,
    function() f:Hide(); WLDTDB.hidden = true; ns.SetArrow(nil); if ns.UpdateActionBar then ns.UpdateActionBar() end end)
  close:SetPoint("TOPRIGHT", -8, -8)
  f.closeBtn = close
  -- "-": the small tracker (Tracker.lua, the step, its objective bars and what comes next) in place
  -- of the window; a click on the tracker brings the whole guide back. It replaced the one-line
  -- collapsed window, too wide for what it said and hard to read.
  -- a word, not "-": nobody guessed that the minus turned the guide into the RestedXP-like card
  -- (report: "not intuitive")
  f.miniBtn = LabelBtn(h, L.COMPACT_BTN, 24, "secondary", function()
    if ns.Tracker and ns.Tracker.Compact then ns.Tracker.Compact()
    else f.mini = not f.mini; WLDTDB.mini = f.mini; Render() end
  end, { L.TT_HMIN, L.TT_HMIN_CLICK })
  f.miniBtn:SetPoint("RIGHT", close, "LEFT", -4, 0)
  f.gearBtn = IconBtn(h, "gear", { L.SETTINGS, L.TT_SETTINGS }, function()
    local WP = ns.Writs and ns.Writs.WP
    if WP and WP.OpenOptions then WP.OpenOptions("dungeons") end
  end)
  f.gearBtn:SetPoint("RIGHT", f.miniBtn, "LEFT", -4, 0)
  -- "Dungeons": a labelled button (an icon alone was not understood); the word alone, since a
  -- map beside it only repeated it (icon audit, guide header)
  f.pickBtn = LabelBtn(h, L.DUNGEONS_BTN, 24, "secondary", function() ns.TogglePicker() end, { L.TT_HPICK, L.TT_PICKBTN })
  f.pickBtn:SetPoint("RIGHT", f.gearBtn, "LEFT", -6, 0)
  local leftmost = f.pickBtn
  -- the summary of the guide's dungeon (Overview.lua): its quests, prerequisites and rewards. A
  -- word, not the info icon: "info" only means neutral information (icon audit G1)
  if ns.ShowOverview then
    f.ovBtn = LabelBtn(h, L.OV_T, 24, "secondary", function() ns.ShowOverview(GuideDungeon()) end, function()
      local dn = ns.DName(GuideDungeon())
      return { dn and L.OV_HDR_T:format(dn) or L.OV_T, L.OV_CLICK }
    end)
    f.ovBtn:SetPoint("RIGHT", f.pickBtn, "LEFT", -4, 0)
    leftmost = f.ovBtn
  end
  -- title and subtitle: after the back button, and they stop 8 px before the header's buttons
  -- (full text in the header's tooltip)
  local TITLE_X = 6 + 28 + 6
  function f.LayoutTitle(hasSub)
    -- the leftmost header button on screen (the summary and the pick buttons hide with no route)
    leftmost = (f.ovBtn and f.ovBtn:IsShown() and f.ovBtn) or (f.pickBtn:IsShown() and f.pickBtn) or f.gearBtn
    h.title:ClearAllPoints(); h.sub:ClearAllPoints()
    if hasSub then
      -- the buttons are centred on the header: their top sits (44 - height) / 2 down
      local topOff = (HEADER - (num(leftmost:GetHeight()) or 28)) / 2
      h.title:SetPoint("TOPLEFT", TITLE_X, -7); h.title:SetPoint("TOPRIGHT", leftmost, "TOPLEFT", -8, topOff - 7)
      h.sub:SetPoint("TOPLEFT", h.title, "BOTTOMLEFT", 0, -2); h.sub:SetPoint("TOPRIGHT", h.title, "BOTTOMRIGHT", 0, -2)
      h.sub:Show()
    else
      h.title:SetPoint("LEFT", h, "LEFT", TITLE_X, 0); h.title:SetPoint("RIGHT", leftmost, "LEFT", -8, 0)
      h.sub:Hide()
    end
  end
  f.LayoutTitle(false)

  -- progress: "Step 3 / 26 · 23 left", the step list button, a thin bar
  local y0 = HEADER + 1 + GAP
  f.prog = CreateFrame("Frame", nil, f)
  f.prog:SetPoint("TOPLEFT", PAD, -y0); f.prog:SetPoint("TOPRIGHT", -PAD, -y0); f.prog:SetHeight(24)
  f.listToggle = LabelBtn(f.prog, L.LIST, 24, "secondary", function()
    WLDTDB.list = not (WLDTDB.list == true); f.list:SetShown(WLDTDB.list); Render()
  end, function()
    if WLDTDB.list == true then return { L.LIST_CLOSE, L.TT_LIST_CLOSE_CLICK } end
    return { L.M_LIST, L.TT_HLIST }
  end)
  if f.listToggle.SetIcon then f.listToggle:SetIcon("chevron_left") end
  f.listToggle:SetPoint("RIGHT", 0, 0)
  -- the list open: the button looks pressed (as the Checklist button) and says it closes it
  f.listToggle.onFill = Tex(f.listToggle, "BORDER", T.selFill); f.listToggle.onFill:SetAllPoints(); f.listToggle.onFill:Hide()
  f.listToggle.onEdge = ns.Outline(f.listToggle, T.accentSoft, 0, "OVERLAY")
  f.progPct = Text(f.prog, ns.F.meta, T.muted); f.progPct:SetPoint("RIGHT", f.listToggle, "LEFT", -12, 0); f.progPct:SetJustifyH("RIGHT"); f.progPct:SetJustifyV("MIDDLE")
  ns.ClampLabel(f.progPct, nil, f.prog)
  -- (no percentage beside it: the label and the bar already say how far the route is)
  f.progPct:Hide()
  f.progLabel = Text(f.prog, ns.F.body, T.text); f.progLabel:SetPoint("LEFT", 0, 0); f.progLabel:SetPoint("RIGHT", f.listToggle, "LEFT", -12, 0); f.progLabel:SetJustifyV("MIDDLE")
  ns.ClampLabel(f.progLabel, nil, f.prog)
  local bar = CreateFrame("StatusBar", nil, f)
  bar:SetPoint("TOPLEFT", PAD, -(y0 + 24 + 6)); bar:SetPoint("TOPRIGHT", -PAD, -(y0 + 24 + 6)); bar:SetHeight(4)
  bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
  bar.bg = Tex(bar, "BACKGROUND", T.divider); bar.bg:SetAllPoints()
  bar:SetMinMaxValues(0, 1)
  f.bar = bar

  -- the route's three parts under the bar (T-86): "Outside 2/14 · In the dungeon 0/9 · After 0/3";
  -- a click shows the part's first open step (its first step once all are done)
  f.tabs = CreateFrame("Frame", nil, f); f.tabs:SetHeight(24); f.tabs.btn = {}
  for k, ph in ipairs(TAB_PH) do
    local b = CreateFrame("Button", nil, f.tabs)
    b.ph = ph
    b.sel = Tex(b, "BACKGROUND", T.selFill); b.sel:SetAllPoints(); b.sel:Hide()
    b.hl = Tex(b, "HIGHLIGHT", T.hoverFill); b.hl:SetAllPoints()
    b.line = Tex(b, "ARTWORK", T.accentSoft); b.line:SetPoint("BOTTOMLEFT"); b.line:SetPoint("BOTTOMRIGHT"); b.line:SetHeight(2); b.line:Hide()
    b.label = Text(b, ns.F.label, T.text); b.label:SetPoint("LEFT", 6, 0); b.label:SetPoint("RIGHT", -6, 0)
    b.label:SetJustifyH("CENTER"); b.label:SetJustifyV("MIDDLE")
    ns.ClampLabel(b.label, nil, b)
    b:SetScript("OnClick", function(self) if self.go then ns.GoTo(self.go) end end)
    b:SetScript("OnEnter", function(self)
      local c = self.c or { done = 0, total = 0 }
      ns.ShowTip(self, { L["TAB_TT_" .. self.ph:upper()], L.CH_PROGRESS:format(c.done, c.total), L.TT_CHAPTER_CLICK })
    end)
    b:SetScript("OnLeave", ns.HideTip)
    f.tabs.btn[k] = b
  end
  f.tabs:Hide()

  -- looking at another step than the current one (T-86): one line says so and leads back; looking
  -- never moves the current step nor marks anything
  local vb = CreateFrame("Button", nil, f)
  vb:SetHeight(28)
  vb.bg = Tex(vb, "BACKGROUND", T.cardFill); vb.bg:SetAllPoints()
  vb.tint = Tex(vb, "BACKGROUND", { T.info[1], T.info[2], T.info[3], 0.10 }); vb.tint:SetAllPoints()
  vb.edge = ns.Outline(vb, T.info, 0.4)
  vb.hl = Tex(vb, "HIGHLIGHT", T.hoverFill); vb.hl:SetAllPoints()
  vb.icon = ns.Icon(vb, "chevron_left", 14, "ARTWORK", T.info); vb.icon:SetPoint("LEFT", 10, 0)
  vb.text = Text(vb, ns.F.label, T.fg); vb.text:SetPoint("LEFT", 30, 0); vb.text:SetPoint("RIGHT", -10, 0); vb.text:SetJustifyV("MIDDLE")
  ns.ClampLabel(vb.text, nil, vb)
  vb:SetScript("OnClick", function() GoBack() end)
  vb:SetScript("OnEnter", function(self) ns.ShowTip(self, { self.text:GetText() or "", L.TT_VIEW }) end)
  vb:SetScript("OnLeave", ns.HideTip)
  vb:Hide()
  f.viewBand = vb

  -- inside a dungeon that is not in the route: one click adds it (Main.lua sets ns.instOffer)
  f.instBtn = LabelBtn(f, "", 28, "secondary", function()
    local k = ns.instOffer; if not k then return end
    ns.instOffer = nil; ns.instIn = k; WLDTDB.sel[k] = true; ns.Assemble(true); f.auto, f.sig = nil, nil; ns.Refresh(true)
    for i, st in ipairs(ns.route and ns.route.steps or {}) do if st.ins == k and not st.gate then ns.GoTo(i) break end end
  end)
  if f.instBtn.SetIcon then f.instBtn:SetIcon("plus") end
  f.instBtn:Hide()

  -- inside one of the route's dungeons: one slim line above the card says so (its icon, the
  -- dungeon, where you are in its steps and the quests finished here; the rest in the tooltip),
  -- with share (in a group) and the bosses strip toggle at the right.
  -- A click shows the first open step inside. Leaving the instance hides it.
  local band = CreateFrame("Button", nil, f)
  band:SetHeight(36)
  band.bg = Tex(band, "BACKGROUND", T.cardFill); band.bg:SetAllPoints()
  band.tint = Tex(band, "BACKGROUND", { T.info[1], T.info[2], T.info[3], 0.10 }); band.tint:SetAllPoints()
  band.edge = ns.Outline(band, T.info, 0.4)
  band.hl = Tex(band, "HIGHLIGHT", T.hoverFill); band.hl:SetAllPoints()
  band.icon = band:CreateTexture(nil, "ARTWORK"); band.icon:SetSize(20, 20); band.icon:SetPoint("LEFT", 10, 0)
  band.title = Text(band, ns.F.label, T.fg, true); band.title:SetPoint("LEFT", 38, 0)
  ns.ClampLabel(band.title, nil, band)
  band.sub = Text(band, ns.F.meta, T.muted); band.sub:SetPoint("LEFT", band.title, "RIGHT", 8, 0)
  ns.ClampLabel(band.sub, nil, band)
  band.chev = ns.Icon(band, "chevron_right", 16, "ARTWORK", T.muted); band.chev:SetPoint("RIGHT", -10, 0)
  band:SetScript("OnClick", function(self) if self.go then ns.GoTo(self.go) end end)
  band:SetScript("OnEnter", function(self)
    self.chev:SetVertexColor(T.fg[1], T.fg[2], T.fg[3])
    ns.ShowTip(self, self.tipLines or { self.title:GetText() or "", L.INB_TT })
  end)
  band:SetScript("OnLeave", function(self) self.chev:SetVertexColor(T.muted[1], T.muted[2], T.muted[3]); ns.HideTip() end)
  -- at the right of the line: share the quests (in a group) and the bosses strip (on / off)
  -- (an icon, like the bosses toggle: the count is in its tooltip, so the band's texts keep their room;
  -- inside, the footer has no share button: this is the view's one)
  band.shareBtn = SW().IconButton(band, "group", 24, function()
    local n = ShareN()
    local t = { L.M_SHARE, L.TT_FSHARE }
    if n > 0 and ns.ShareInCombat and ns.ShareInCombat() then t[#t + 1] = { L.SHARE_AFTER_TT, T.muted[1], T.muted[2], T.muted[3] }
    elseif n > 0 then t[#t + 1] = { ShareLabel(n), T.accentSoft[1], T.accentSoft[2], T.accentSoft[3] }
    else t[#t + 1] = { (IsInGroup and IsInGroup()) and L.NOSHARE or L.NOGROUP_TIP, T.muted[1], T.muted[2], T.muted[3] } end
    return t
  end, DoShare)
  band.shareBtn:Hide()
  if ns.ToggleBosses then
    band.bossBtn = SW().IconButton(band, "skull", 24, function()
      return { L.BOSS_TITLE, (ns.BossesShown and ns.BossesShown()) and L.BOSS_MENU_HIDE or L.BOSS_MENU_CLICK }
    end, function()
      ns.ToggleBosses(ns.instIn or InsideKey())
      local b = f.inBand.bossBtn
      if b and b.SetToggled then b:SetToggled(ns.BossesShown and ns.BossesShown()) end
    end)
    band.bossBtn:Hide()
  end
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
  -- a prerequisite step: "Prerequisite 2 of 4" (its tooltip: before which quest)
  card.prePill = Pill(card)
  card.prePill:EnableMouse(true)
  card.prePill:SetScript("OnEnter", function(self) if self.tip then ns.ShowTip(self, self.tip) end end)
  card.prePill:SetScript("OnLeave", ns.HideTip)
  card.prePill:Hide()
  -- the chapter the step belongs to: "Before the dungeon: Zul'Farrak 3/18"
  card.chapter = Text(card, ns.F.meta, T.muted); card.chapter:Hide()
  card.zone = card.where.text   -- older name
  -- 3D portrait of the boss (the dungeon journal's model)
  card.modelBg = card:CreateTexture(nil, "BACKGROUND"); card.modelBg:SetColorTexture(0, 0, 0, 0.35)
  card.modelBg:SetSize(76, 76); card.modelBg:Hide()
  card.model = CreateFrame("PlayerModel", nil, card)
  card.model:SetSize(74, 74); card.model:SetPoint("CENTER", card.modelBg, "CENTER"); card.model:Hide()
  -- empty, finished: one centred block (icon 32, title, sentence)
  card.bigIcon = ns.Icon(card, "portal", 32, "ARTWORK", T.muted); card.bigIcon:Hide()
  card.title = Text(card, ns.F.title, T.fg)
  -- never shown now (the travel line is text only); kept so the code that hides it stays valid
  card.travelIcon = ns.Icon(card, "info", 14, "ARTWORK", T.info); card.travelIcon:Hide()
  card.travel = Text(card, ns.F.meta, T.text)
  -- under a check-list's or a dungeon step's title: the entrance (zone, distance), or the area
  card.whereLine = Text(card, ns.F.body, T.text); card.whereLine:Hide()
  card.wlTick = CreateFrame("Frame", nil, card); card.wlTick.card = card; card.wlTick:SetScript("OnUpdate", WhereTick)
  -- check-list status: a banner (tint of its colour, 1 px edge, HD icon) with state, why, what next
  card.readyBox = CreateFrame("Frame", nil, card)
  card.readyBg = Tex(card.readyBox, "BACKGROUND", { T.ok[1], T.ok[2], T.ok[3], 0.16 }); card.readyBg:SetAllPoints()
  card.readyEdge = ns.Outline(card.readyBox, T.ok, 0.4)
  card.readyIcon = ns.Icon(card.readyBox, "check", 16, "ARTWORK", T.ok); card.readyIcon:SetPoint("TOPLEFT", 12, -10)
  card.ready = Text(card.readyBox, ns.F.label, T.fg); card.ready:SetPoint("TOPLEFT", 36, -10); card.ready:SetSpacing(3)
  card.readyBox:Hide()
  -- the empty and finished cards' sentence (CentredBlock)
  card.note = Text(card, ns.F.label, T.text); card.note:SetSpacing(3)
  -- a step's blocks above the rows (a boss: path, tactic, loot, tip, on the way) and under them
  -- (check-list: key, entrance, group): gold heading, then the text or a list (design system 3.21)
  card.noteStk = ns.TextStack(card)
  card.afterStk = ns.TextStack(card)
  -- a boss step: "Boss 2 of 9" in small over the boss's name
  card.kicker = Text(card, ns.F.meta, T.muted); card.kicker:Hide()
  card.rows = {}
  for r = 1, MAXROWS do card.rows[r] = MakeRow(card) end
  MakeFocus(card)
  -- labelled buttons carry no icon that repeats their verb (design system 3.4, icon audit G3)
  card.shareBtn = LabelBtn(card, L.SHARE_SHORT, 28, "secondary", DoShare, function() return { L.M_SHARE, L.TT_FSHARE } end)
  card.shareBtn:Hide()
  -- T-87: "Skip" on a step of an optional quest: a first click arms it ("Click again to skip",
  -- 4 s, like Start over), the second unticks the quest as the Overview does (WLDTDB.off and
  -- offPick, Overview.lua SetOff) and the route is planned again. A plain button, no secure frame.
  card.skipBtn = LabelBtn(card, L.SKIP_Q, 24, "secondary", function(self) ns.GuideSkipClick(self) end,
    function() return { L.SKIP_Q, L.TT_SKIP_Q } end)
  card.skipBtn:Hide()

  -- footer, under the card: the one main action, then previous / next / check-list / actions
  local foot = CreateFrame("Frame", nil, f)
  foot:SetHeight(FOOT_H)
  f.foot = foot
  f.go = LabelBtn(foot, L.GO, 32, "primary", function(self) if self.action then self.action() end end)
  -- in a group: "Share 3 quests" beside the big button, greyed when none can be shared
  f.shareFoot = LabelBtn(foot, L.SHARE_SHORT, 32, "secondary", DoShare, function() return { L.M_SHARE, L.TT_FSHARE } end)
  f.shareFoot:Hide()
  f.prev = IconBtn(foot, "chevron_left", { L.B_PREV, L.TT_PREV_CLICK }, function() ns.GoTo(f.view - 1) end)
  f.prev.edge = ns.Outline(f.prev, T.btnEdge)
  f.prev:SetPoint("BOTTOMLEFT")
  f.moreBtn = LabelBtn(foot, L.MORE_BTN, 28, "secondary", function() f.menu:SetShown(not f.menu:IsShown()) end,
    function() return { L.MORE, L.TT_MORE } end)
  -- a menu takes the gear icon or none (design system 3.13): the word "Actions" says it
  f.moreBtn:SetPoint("BOTTOMRIGHT")
  f.next = LabelBtn(foot, L.NEXT2, 28, "secondary", function() ns.GoTo(f.view + 1) end, function() return { L.NEXT2, L.TT_NEXT, L.TT_NEXT_CLICK } end)
  if f.next.SetIcon then f.next:SetIcon("chevron_right") end
  f.next:SetPoint("LEFT", f.prev, "RIGHT", 4, 0)
  -- "Checklist": straight to the before-entering check of the dungeon on screen (quests to take, key).
  -- Its icon tells the state (check = ready, warning = something first); its tooltip says it in words.
  -- On the check-list itself it is pressed and says "Close the checklist": back to the current step.
  f.readyBtn = LabelBtn(foot, L.B_READY, 28, "secondary", function()
    if f.readyOn then ns.CloseReady() elseif ns.GoReady then ns.GoReady() end
  end, function()
    if f.readyOn then return { L.B_READY_CLOSE, L.TT_READY_CLOSE } end
    local t = { L.B_READY_T, L.TT_READY }
    if f.readyTip then table.insert(t, f.readyTip) end
    table.insert(t, L.TT_READY_CLICK)
    return t
  end)
  if f.readyBtn.SetIcon then f.readyBtn:SetIcon("check") end
  f.readyBtn:SetPoint("RIGHT", f.moreBtn, "LEFT", -4, 0)
  f.readyBtn.onFill = Tex(f.readyBtn, "BORDER", T.selFill); f.readyBtn.onFill:SetAllPoints(); f.readyBtn.onFill:Hide()
  f.readyBtn.onEdge = ns.Outline(f.readyBtn, T.accentSoft, 0, "OVERLAY")

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
    b:SetScript("OnClick", function(...) if onClick(...) ~= "keep" then menu:Hide() end end)
    b:SetScript("OnMouseDown", function(self) if self:IsEnabled() ~= false then self.press:Show() end end)
    b:SetScript("OnMouseUp", function(self) self.press:Hide() end)
    b:SetScript("OnEnter", function(self) ns.ShowTip(self, tip(self)) end)
    b:SetScript("OnLeave", ns.HideTip)
    b:SetScript("OnEnable", function(self) self:SetAlpha(1) end)
    b:SetScript("OnDisable", function(self) self:SetAlpha(T.disabledAlpha) end)
    ns.ClampLabel(b.label, nil, b)
    function b:SetOn(on) self.check:SetShown(on and true or false) end
    items[#items + 1] = b
    menu:SetHeight(8 + #items * 24)
    return b
  end
  -- the entries one under the other, the ones switched off (wlOff) left out
  function menu.Layout()
    local n = 0
    for _, b in ipairs(items) do
      if not b.wlOff then
        local y = -4 - n * 24
        b:ClearAllPoints(); b:SetPoint("TOPLEFT", 4, y); b:SetPoint("TOPRIGHT", -4, y)
        n = n + 1
      end
    end
    menu:SetHeight(8 + n * 24)
  end
  -- short on purpose (T-74; the key bindings entry added for the "Target and items" keys): sharing is automatic (Writs/GuideQuests.lua) and in the inside band,
  -- the points at each step are in Settings > Quests & dungeons, the step list has its "Steps"
  -- button, the tracker is in Settings and /wlh tracker; /wlh share, list, recalc, arrow, boss stay.
  f.done = Item(function()
    local st = Steps()[f.view]; if not st then return end
    -- a "kill" / "skip" mark the step outgrew (a new open line): the click ticks it
    SetManual(st, not ManualHolds(ns.LogEntries(), st)); ns.Refresh()
  end, function() return { L.M_SKIP, L.TT_FDONE } end)
  -- "Start the route over" (T-84, = /wlh reset) takes the place of "Rebuild the route from here":
  -- the route is planned again by itself when a quest changes, and /wlh recalc stays. A second
  -- click within 4 s confirms; the menu stays open in between.
  f.restartItem = Item(function(self)
    if self.armToken then
      self.armToken = nil; self.label:SetTextColor(T.fg[1], T.fg[2], T.fg[3])
      if ns.ResetRoute then ns.ResetRoute() end
      return
    end
    local token = {}
    self.armToken = token
    self.label:SetText(L.RESTART_CONFIRM); self.label:SetTextColor(T.warn[1], T.warn[2], T.warn[3])
    if C_Timer and C_Timer.After then
      C_Timer.After(4, function()
        if self.armToken == token then self.armToken = nil; self.label:SetText(L.M_RESTART); self.label:SetTextColor(T.fg[1], T.fg[2], T.fg[3]) end
      end)
    end
    return "keep"
  end, function() return { L.M_RESTART, L.TT_RESTART, L.RESTART_CLICK } end)
  f.restartItem.label:SetText(L.M_RESTART)
  f.recalc = f.restartItem   -- its older name
  menu:HookScript("OnHide", function()
    local it = f.restartItem
    if it.armToken then it.armToken = nil; it.label:SetText(L.M_RESTART); it.label:SetTextColor(T.fg[1], T.fg[2], T.fg[3]) end
  end)
  -- "Stop this guide": the dungeons unpicked, the route and its arrow gone; a second click confirms
  f.stopItem = Item(function(self)
    if self.armToken then
      self.armToken = nil; self.label:SetText(L.M_STOP); self.label:SetTextColor(T.fg[1], T.fg[2], T.fg[3])
      if ns.StopRoute then ns.StopRoute() end
      return
    end
    local token = {}
    self.armToken = token
    self.label:SetText(L.RESTART_CONFIRM); self.label:SetTextColor(T.warn[1], T.warn[2], T.warn[3])
    if C_Timer and C_Timer.After then
      C_Timer.After(4, function()
        if self.armToken == token then self.armToken = nil; self.label:SetText(L.M_STOP); self.label:SetTextColor(T.fg[1], T.fg[2], T.fg[3]) end
      end)
    end
    return "keep"
  end, function() return { L.M_STOP, L.TT_STOP, L.STOP_CLICK } end)
  f.stopItem.label:SetText(L.M_STOP)
  menu:HookScript("OnHide", function()
    local it = f.stopItem
    if it.armToken then it.armToken = nil; it.label:SetText(L.M_STOP); it.label:SetTextColor(T.fg[1], T.fg[2], T.fg[3]) end
  end)
  -- the boss's tactics to the group's chat
  f.tacItem = Item(function()
    local st = Steps()[f.view or 0]
    if st and ns.AnnounceTactics then ns.AnnounceTactics(st) end
  end, function() return { L.M_TACTICS } end)
  f.tacItem.label:SetText(L.M_TACTICS)
  f.arrowBtn = Item(function() ns.ToggleArrow(); Render() end, function() return { L.M_ARROW, L.TT_FARROW } end)
  -- the dungeon's bosses: the bosses and rares panel (Bosses.lua; its header opens the map and the
  -- installed dungeon journal), else, with no dungeon for it, the dungeon journal itself
  f.bossItem = Item(function()
    local dk = ns.instIn or GuideDungeon()
    if ns.ToggleBosses and dk then ns.ToggleBosses(dk)
    elseif ns.OpenJournal and ns.JournalAvailable and ns.JournalAvailable() then ns.OpenJournal() end
  end, function() return { L.M_BOSSES, (ns.BossesShown and ns.BossesShown()) and L.BOSS_MENU_HIDE or L.BOSS_MENU_CLICK } end)
  -- the game's key bindings (Main.lua): where the target / item / step keys are set
  f.keysItem = Item(function() if ns.OpenKeyBindings then ns.OpenKeyBindings() end end, function() return { L.M_KEYS, L.TT_KEYS } end)
  f.keysItem.label:SetText(L.M_KEYS)
  -- "See where Nyx is" (T-86): a group member with WL Helper shares the step they are at (Sync.lua);
  -- the step opens in your guide to look at, your own current step stays
  f.memberItems = {}
  for k = 1, 4 do
    local it = Item(function(self) if self.go then ns.GoTo(self.go) end end, function(self)
      local st = self and self.go and Steps()[self.go]
      local t = { self and self.label:GetText() or "", L.TT_MEMBER }
      if st then table.insert(t, 2, L.MEMBER_AT:format(self.go, StepTitle(st))) end
      return t
    end)
    ns.ClampLabel(it.label, nil, it)   -- one line, whatever the name
    it.wlOff = true; it:Hide()
    f.memberItems[k] = it
  end
  menu.Layout()
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
      local nw = math.floor(math.max(WMIN, math.min(MaxW(), me.start[2] + (x - me.start[1]))))
      if nw ~= Wuser then ns.Relayout(nw); Render() end
    end)
  end)
  grip:SetScript("OnMouseUp", function(self)
    self:SetScript("OnUpdate", nil)
    WLDTDB.size = { Wuser }   -- the width only: the height always follows the content
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
  -- the old one-line mode: its players get the small tracker
  if WLDTDB.mini then WLDTDB.mini = nil; WLDTDB.tracker = true end
  f.mini = false
  f.list:SetShown(WLDTDB.list == true)
  -- a new frame is visible: closed at first; Main.lua reopens it at login if it was open before.
  -- Every way of opening or closing it (close, Escape, /wlh, home, minimap) is remembered here,
  -- except when the Dungeons module is switched off (ns.quietHide), which is not your choice.
  f:Hide()
  f:HookScript("OnShow", function() WLDTDB.hidden = false end)
  -- the small tracker takes over when the big window closes
  f:HookScript("OnHide", function() if WLHelperTracker and WLHelperTracker.Refresh then pcall(WLHelperTracker.Refresh) end end)
  f:HookScript("OnHide", function() if not ns.quietHide then WLDTDB.hidden = true end end)
  ns.frame = f
  if ns.RegisterWindow then ns.RegisterWindow(f, "guide") end
  -- older saves kept a card height that capped the card for good: only the width is kept now
  if WLDTDB.size then WLDTDB.size[2] = nil; ns.Relayout(WLDTDB.size[1]) end
  -- Not in UISpecialFrames: the guide is followed while playing, Escape must not close it (the
  -- player closes it with its X), and the game empties that list on loading screens too
  -- the bosses and rares panel hangs under the guide (by position only: the guide stays unprotected)
  if ns.AttachBosses then ns.AttachBosses(f) end
end
ns.BuildMain = Build

-- Width of the guide (the grip in the bottom-right corner). The height follows the content;
-- nh caps the card's height when given (the reset only; saves keep the width alone).
-- the width drawn and the player's own width (tests, the debug command)
function ns.GuideWidth() return W, Wuser end
function ns.Relayout(nw, nh)
  Wuser = math.max(WMIN, math.min(MaxW(), nw or W0))
  W = Wuser
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

-- The "inside the dungeon" line: icon, the dungeon, where you are in its steps and the quests
-- finished here (the long sentences and the next boss in its tooltip). Returns its height (0 = hidden).
function ns.RenderInsideBand(k, log)
  local band = f.inBand
  local d = ns.D[k] or {}
  band.icon:SetVertexColor(1, 1, 1)
  if d.icon then ns.SetPainted(band.icon, d.icon) else ns.SetHDIcon(band.icon, "portal", T.info) end
  local nIn, doneIn, firstOpen, firstIn, viewPos, openPos, nextBoss = 0, 0, nil, nil, nil, nil, nil
  local qseen, qT, qD = {}, 0, 0
  for i2, s2 in ipairs(Steps()) do
    if s2.ins == k and not s2.gate then
      nIn = nIn + 1; firstIn = firstIn or i2
      if i2 == f.view then viewPos = nIn end
      if IsStepDone(log, i2) then doneIn = doneIn + 1
      else
        if not firstOpen then firstOpen = i2; openPos = nIn end
        if not nextBoss and s2.bossStep then nextBoss = ns.BossStepName(s2) end
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
  local name = ns.DName(k) or ""
  local tip = { L.INB_T:format(name) }
  local short
  if doneIn == nIn then
    short = Hex(T.ok) .. L.INB_DONE_S .. "|r"
    tip[#tip + 1] = { L.INB_DONE, T.ok[1], T.ok[2], T.ok[3] }
  else
    -- a run with no quest: no "Quests 0/0"
    short = L.INB_STEP_S:format(viewPos or openPos or 1, nIn) .. (qT > 0 and ("  ·  " .. L.INB_Q_S:format(qD, qT)) or "")
    tip[#tip + 1] = L.INB_STEP:format(viewPos or openPos or 1, nIn)
    if qT > 0 then tip[#tip + 1] = L.INB_Q:format(qD, qT) end
    if nextBoss then tip[#tip + 1] = L.INB_BOSS:format(nextBoss) end
  end
  tip[#tip + 1] = L.INB_TT
  -- the click brings you back only when you look at a step outside the dungeon
  if not viewPos then tip[#tip + 1] = L.INB_BACK end
  band.tipLines = tip
  band.title:SetText(name)
  band.sub:SetText(short)
  -- away from the dungeon's steps: the chevron says a click brings you back
  local cc = viewPos and T.muted or T.accentSoft
  band.chev:SetVertexColor(cc[1], cc[2], cc[3])
  band.go = firstOpen or firstIn
  band:Show()
  -- the right cluster: chevron, bosses toggle, share (in a group)
  local x = -10 - 16 - 8
  if band.bossBtn then
    if band.bossBtn.SetToggled then band.bossBtn:SetToggled(ns.BossesShown and ns.BossesShown()) end
    band.bossBtn:ClearAllPoints(); band.bossBtn:SetPoint("RIGHT", band, "RIGHT", x, 0); band.bossBtn:Show()
    x = x - 24 - 6
  end
  local inGroup = IsInGroup and IsInGroup()
  if inGroup then
    SetShareButton(band.shareBtn, ShareN(), false)
    band.shareBtn:ClearAllPoints(); band.shareBtn:SetPoint("RIGHT", band, "RIGHT", x, 0); band.shareBtn:Show()
    x = x - 24 - 6
  else band.shareBtn:Hide() end
  -- the name first, the short progress after it; both cut (full text in the tooltip) when tight
  local room = (W - 2 * PAD) - 38 + x
  local sw = math.min(ns.TextWidth(band.sub), math.max(60, math.floor(room * 0.5)))
  local tw = math.max(40, math.min(ns.TextWidth(band.title), room - 8 - sw))
  band.title:SetWidth(tw); band.sub:SetWidth(math.max(20, sw))
  band:SetHeight(36)
  return 36
end

-- The footer's "Checklist" button: its icon says the state of the check-list it opens
-- (check = ready, warning = quests to take or no key); its tooltip says it in words.
function ns.RenderReadyBtn(log)
  local b = f.readyBtn
  -- the check-list on screen: the button is pressed and closes it (T-85)
  local cur = Steps()[f.view or 0]
  f.readyOn = (cur and cur.gate) and true or false
  if b.onFill then b.onFill:SetShown(f.readyOn); b.onEdge(T.accentSoft, f.readyOn and 0.9 or 0) end
  if f.readyOn then
    b:SetText(L.B_READY_CLOSE); if b.SetIcon then b:SetIcon(nil) end
    b:SetEnabled(true); f.readyHas = true; f.readyTip = nil
    return
  end
  b:SetText(L.B_READY)
  local ti = ReadyTarget()
  local st = ti and Steps()[ti]
  -- a route with no check-list: the footer leaves the button out instead of a grey one that never works
  f.readyHas = st ~= nil
  if not st then
    b:SetEnabled(false); if b.SetIcon then b:SetIcon("check") end
    b.disabledReason = L.NO_READY
    f.readyTip = { L.NO_READY, T.muted[1], T.muted[2], T.muted[3] }
    return
  end
  b:SetEnabled(true)
  local miss, _, keyMissing = ReadyState(log, st)
  local _, outReq = OutsideLeft(log, ti)
  local dn = ns.DName(st.gate) or ""
  if miss == 0 and not keyMissing and outReq == 0 then
    if b.SetIcon then b:SetIcon("check") end
    f.readyTip = { L.TT_READY_OK:format(dn), T.ok[1], T.ok[2], T.ok[3] }
  elseif miss == 0 and outReq > 0 then
    if b.SetIcon then b:SetIcon("warning") end
    f.readyTip = { ns.Plural(outReq, "TT_READY_OUT1", "TT_READY_OUT", dn, outReq), T.warn[1], T.warn[2], T.warn[3] }
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
  -- in a group, with a route: "Share 3 quests" on the big button's line, on its right
  local share = full and not centred and not f.compactIn and IsInGroup and IsInGroup()
  if share then
    SetShareButton(f.shareFoot, ShareN(), true)
    f.shareFoot:ClearAllPoints(); f.shareFoot:SetPoint("TOPRIGHT", f.foot, "TOPRIGHT", 0, 0); f.shareFoot:Show()
  else f.shareFoot:Hide() end
  -- the big button and "Share 4 quests" side by side: the window widens when they do not fit
  f.wlFootNeed = nil
  if share then
    f.go:SetWidth(0)
    local need = (num(f.go:GetWidth()) or 120) + 8 + (num(f.shareFoot:GetWidth()) or 150)
    -- kept even when it fits: the next render would otherwise shrink the window back
    f.wlFootNeed = math.ceil(need + 2 * PAD)
  end
  if centred then
    f.go:SetPoint("TOP", f.foot, "TOP", 0, 0); f.go:SetWidth(0)
  else
    f.go:SetPoint("TOPLEFT", f.foot, "TOPLEFT", 0, 0)
    f.go:SetWidth(share and math.max(120, CW - (num(f.shareFoot:GetWidth()) or 150) - 8) or CW)
  end
  for _, b in ipairs({ f.prev, f.next, f.moreBtn }) do b:SetShown(full) end
  local ready = full and f.readyHas ~= false
  f.readyBtn:SetShown(ready)
  if full then
    -- previous (28) and next on the left, then the check-list (when the route has one) and Actions
    local rw, mw = ready and ((num(f.readyBtn:GetWidth()) or 100) + 4) or 0, num(f.moreBtn:GetWidth()) or 90
    f.next:SetWidth(math.max(80, CW - 28 - rw - mw - 8))
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
  card.where:Hide(); card.clsChip:Hide(); card.badgePill:Hide(); card.prePill:Hide(); card.chapter:Hide()
  card.travel:Hide(); card.travelIcon:Hide(); card.readyBox:Hide(); card.shareBtn:Hide(); card.skipBtn:Hide()
  card.model:Hide(); card.modelBg:Hide(); card.whereLine:Hide(); card.kicker:Hide()
  HideStack(card.noteStk); HideStack(card.afterStk); card.noteText, card.afterText = nil, nil
  for _, row in ipairs(card.rows) do row.node = nil; row:Hide() end
  HideFocus(card)
end

-- An empty or finished card: one centred block (icon, title, sentence); returns its height.
local function CentredBlock(card, icon, color, title, text)
  local w = math.min(320, TextW())
  card.bigIcon:ClearAllPoints(); card.bigIcon:SetPoint("TOP", card, "TOP", 0, -24)
  ns.SetHDIcon(card.bigIcon, icon, color); card.bigIcon:Show()
  Size(card.title, ns.F.heading); card.title:SetJustifyH("CENTER")
  card.title:SetText(title); card.title:Show()
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

-- done / total per part of the route (every dungeon's part together) and the step a tab opens:
-- the part's first open step, else its first step. nil when the route has no parts (class quests).
local function PartCounts(log)
  local out, any = {}, false
  for _, ph in ipairs(TAB_PH) do out[ph] = { done = 0, total = 0 } end
  for i, st in ipairs(Steps()) do
    local key, ph = StepChapter(st)
    local c = key and out[ph]
    if c then
      any = true
      c.total = c.total + 1
      c.first = c.first or i
      if IsStepDone(log, i) then c.done = c.done + 1 elseif not c.go then c.go = i end
    end
  end
  for _, ph in ipairs(TAB_PH) do local c = out[ph]; c.go = c.go or c.first end
  return any and out or nil
end
ns.GuidePartCounts = PartCounts

-- the tabs at y (from the window's top) -> their height (0: hidden)
local function RenderTabs(log, y)
  local tabs = f.tabs
  local parts = PartCounts(log)
  if not parts then tabs:Hide() return 0 end
  local w, gap = W - 2 * PAD, 4
  local colW = math.floor((w - 2 * gap) / 3)
  local _, viewPh = StepChapter(Steps()[f.view or 0])
  tabs:ClearAllPoints(); tabs:SetPoint("TOPLEFT", PAD, -y); tabs:SetPoint("TOPRIGHT", -PAD, -y); tabs:Show()
  for k, ph in ipairs(TAB_PH) do
    local b, c = tabs.btn[k], parts[ph]
    b:ClearAllPoints(); b:SetPoint("TOPLEFT", tabs, "TOPLEFT", (k - 1) * (colW + gap), 0)
    b:SetSize(k == 3 and (w - 2 * (colW + gap)) or colW, 24)
    b.go, b.c = c.go, c
    local nc = (c.total > 0 and c.done == c.total) and T.ok or T.muted
    -- a part with no step: its name alone, greyed (no "0/0" to read)
    b.label:SetText(c.total > 0 and (L[TAB_K[ph]] .. " " .. Hex(nc) .. c.done .. "/" .. c.total .. "|r") or L[TAB_K[ph]])
    b.on = (ph == viewPh)
    b.sel:SetShown(b.on); b.line:SetShown(b.on)
    local tc = b.on and T.fg or T.text
    b.label:SetTextColor(tc[1], tc[2], tc[3])
    b:SetEnabled(c.total > 0); b:SetAlpha(c.total > 0 and 1 or T.disabledAlpha)
    b:Show()
  end
  return 24
end

-- the width the header needs: back button, the whole title, then its buttons
local function HeaderNeed()
  local h = f.header
  local w = 6 + 28 + 6 + (ns.TextWidth(h.title, L.DUNGEONS) or 0) + 8
  -- the gear, "Compact" and the close button are always there (counted even before the first show)
  local always = { [f.gearBtn] = true, [f.miniBtn] = true, [f.closeBtn] = true }
  for _, b in ipairs({ f.ovBtn, f.pickBtn, f.gearBtn, f.miniBtn, f.closeBtn }) do
    if b and (always[b] or b:IsShown()) then w = w + (num(b:GetWidth()) or 0) + 6 end
  end
  return math.ceil(w + 8)
end
ns.GuideHeaderNeed = function() return f and HeaderNeed() or 0 end
NAV.RenderTabs = RenderTabs
-- the width the three parts tabs need: their longest name with a two-digit count, each
local function TabsNeed()
  local b1 = f.tabs and f.tabs:IsShown() and f.tabs.btn[1]
  if not b1 then return 0 end
  local mw = 0
  for _, ph in ipairs(TAB_PH) do mw = math.max(mw, ns.TextWidth(b1.label, L[TAB_K[ph]] .. " 88/88") or 0) end
  return 3 * (mw + 12) + 2 * 4 + 2 * PAD
end
-- the width drawn: the player's width, or wider when the title, the tabs or the footer need it
-- (max 760, 96 % of the screen)
function NAV.Need()
  return math.max(WMIN, math.min(MaxW(), math.max(Wuser, HeaderNeed(), TabsNeed(), f.wlFootNeed or 0)))
end
function NAV.FitWidth()
  W = NAV.Need()
  return W
end

-- the group members whose current step is in your route: { { name, i } }
function ns.MemberSteps()
  local out = {}
  if not (ns.partyStep and ns.GroupMembers) then return out end
  local steps = Steps()
  for _, m in ipairs(ns.GroupMembers()) do
    local key = ns.partyStep[m.name]
    if key then
      for i, st in ipairs(steps) do if st.key == key then out[#out + 1] = { name = m.name, i = i } break end end
    end
  end
  return out
end

local RenderNow
-- every render is one pass: the step states it reads 4-5 times (progress, chapters, list, band)
-- are asked of the quest log once (a GoTo, the wheel, the width grip render outside a refresh)
local function RenderPass() if ns.InPass then return ns.InPass(RenderNow) end return RenderNow() end
Render = function()
  RenderPass()
  -- the footer ("Share 4 quests") or the tabs measured during the pass need more width than was
  -- drawn: once more at that width (never more: the second pass draws at least that wide)
  if f and NAV.Need and NAV.Need() > W then RenderPass() end
end
RenderNow = function()
  if not f then return end
  f.pending = false
  local log = ns.LogEntries()
  local steps = Steps()
  local h = f.header
  h.title:SetText(L.DUNGEONS)
  local sub = ns.route and ns.route.label or ""
  -- no route: the empty card's one button picks the dungeons, so the header does not repeat it,
  -- and there is no dungeon to sum up yet
  local anyRoute = #steps > 0
  f.pickBtn:SetShown(anyRoute)
  if f.ovBtn then f.ovBtn:SetShown(anyRoute and GuideDungeon() ~= nil) end
  h.sub:SetText(sub); f.LayoutTitle(sub ~= "")
  -- (a labelled button now: no icon to swap)
  -- the player's width, or wider when the title or the footer needs it (never above the max)
  NAV.FitWidth()
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
  -- inside: the card keeps a few lines per action (the full text is in each line's tooltip)
  f.compactIn = inKey ~= nil
  local TOP = TopBase(hasRoute)
  local tabsH = (hasRoute and not f.mini) and NAV.RenderTabs(log, TOP) or 0
  if tabsH > 0 then TOP = TOP + tabsH + 8 else f.tabs:Hide() end
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
  -- the list open: "Close the steps", pressed; closed: "Steps"
  local listOn = WLDTDB.list == true
  f.listToggle:SetText(listOn and L.LIST_CLOSE or L.LIST)
  if f.listToggle.onFill then f.listToggle.onFill:SetShown(listOn); f.listToggle.onEdge(T.accentSoft, listOn and 0.9 or 0) end
  -- the header's labels follow a live language switch too (S.Button's SetText refits the width)
  if f.pickBtn then f.pickBtn:SetText(L.DUNGEONS_BTN) end
  PlaceList()
  if f.listToggle.SetIcon then f.listToggle:SetIcon(ListChevron()) end

  if not hasRoute then
    -- no route yet: what is missing, why, and the one action (centred under the block)
    f.miniRow:Hide(); f.holder:Show(); f.foot:Show()
    HideStepParts(card)
    local title, text = L.NOROUTE_T2, L.NOROUTE_TXT
    -- labelled: no icon ("portal" is kept for a dungeon entrance or a teleport, icon audit G1)
    f.go:SetText(L.PICK_FIRST); if f.go.SetIcon then f.go:SetIcon(nil) end
    f.go.action = ns.ShowPicker; f.go:SetEnabled(true)
    if offerKey and ns.InstLeft then
      -- no route, but you stand in a dungeon with quests: start its guide in one click
      local name, nLeft = ns.DName(offerKey), ns.InstLeft(offerKey)
      title, text = L.INST_T:format(name), ns.Plural(nLeft, "INST_TXT1", "INST_TXT", nLeft)
      f.go:SetText(L.INST_GO); if f.go.SetIcon then f.go:SetIcon(nil) end
      f.go.action = function()
        local kk = ns.instOffer; if not kk then return end
        for k2 in pairs(WLDTDB.sel) do WLDTDB.sel[k2] = nil end; WLDTDB.sel[kk] = true; ns.instOffer = nil; ns.instIn = kk; ns.StartGuide()
      end
    end
    f.viewBand:Hide()
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
  f.progLabel:SetText(L.STEP_LEFT:format(math.min(i, total), total))
  f.progPct:SetText("")
  -- every step done and the card after the last step on screen: the "route finished" card
  -- (previous and the step list still show every step, done ones included)
  local finished = total > 0 and n == total and (st == nil)
  if not st and not finished then f.view = total; i = total; st = steps[i]; done = IsStepDone(log, i) end
  -- looking at another step than the current one: the line that leads back (T-86)
  if not f.mini and not finished and f.auto and i ~= f.auto then
    local vb = f.viewBand
    vb.text:SetText(L.VIEW_AT:format(i) .. Hex(T.muted) .. SEP .. "|r" .. (RouteFinished() and L.BACK_FIN or L.BACK_CUR))
    vb:ClearAllPoints(); vb:SetPoint("TOPLEFT", PAD, -TOP); vb:SetPoint("TOPRIGHT", -PAD, -TOP); vb:Show()
    TOP = TOP + 28 + 8
  else f.viewBand:Hide() end

  if f.mini then
    f.menu:Hide()
    f.holder:Hide(); f.foot:Hide(); f.prog:Hide(); f.list:Hide(); f.instBtn:Hide(); f.inBand:Hide(); f.tabs:Hide()
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
  f.list:SetShown(WLDTDB.list == true)

  if finished then
    f.progLabel:SetText(ns.Plural(#steps, "FIN_PROG1", "FIN_PROG", #steps)); f.progPct:SetText("")
    f.bar:SetValue(1)
    HideStepParts(card)
    local ch = CentredBlock(card, "check", T.ok, L.FIN_T, L.FIN_TXT:format(ns.route.label or ""))
    ScrollTop()
    f.menu:Hide()
    f.prev:SetEnabled(true); f.next:SetEnabled(false); f.moreBtn:SetEnabled(true)
    ns.RenderReadyBtn(log)
    f.go:SetText(L.PICK_MORE); if f.go.SetIcon then f.go:SetIcon(nil) end
    f.go.action = ns.ShowPicker; f.go:SetEnabled(true)
    FitGuide(TOP, ch, LayoutFoot(true, false))
    WLDTDB.view = i
    RenderList(log)
    ns.UpdateActionBar()
    return
  end

  local dkey = st.d or st.gate or st.ins
  -- top line: the chapter on the left, then the class (class quests) or "Optional"; the step's state
  -- on the right only when this is not the current step (the current one is the normal case)
  card.where:Hide()
  local showBadge = true
  if done then card.badgePill:Set(L.B_DONE, T.ok, "check")
  elseif i == f.auto then showBadge = false
  elseif f.auto and i < f.auto then card.badgePill:Set(L.B_LATE, T.warn)
  else card.badgePill:Set(L.B_NEXT, T.fg) end
  if showBadge then
    card.badgePill:ClearAllPoints(); card.badgePill:SetPoint("TOPRIGHT", card, "TOPRIGHT", -CI, -CI); card.badgePill:Show()
  else card.badgePill:Hide() end

  local hasModel = false
  if st.bossModel and card.model.SetDisplayInfo then
    if card.modelShown == st.bossModel then hasModel = true
    else
      hasModel = pcall(card.model.SetDisplayInfo, card.model, st.bossModel)
      card.modelShown = hasModel and st.bossModel or nil
    end
    if hasModel and card.model.SetPortraitZoom then pcall(card.model.SetPortraitZoom, card.model, 0.85) end
  end
  -- room on the top line: the text width minus the state pill
  local avail = TW - (showBadge and ((num(card.badgePill:GetWidth()) or 60) + 8) or 0)
  local dn = ns.DName(dkey) or ""
  -- the chapter: "Avant le donjon · 3/18 étapes", with the dungeon's name when the route has more
  -- than one; inside, the band above the card already says it
  local chKey, chPh, chDk = StepChapter(st)
  local chText
  if chKey and bandH == 0 then
    local c = ChapterCounts(log)[chKey] or { done = 0, total = 0 }
    local K = "CARD_PH_" .. chPh:upper()
    if RouteDungeons() > 1 then chText = L[K .. "_D"]:format(ns.DName(chDk) or chDk, c.done, c.total)
    else chText = L[K]:format(c.done, c.total) end
  end
  local chips = {}
  local cls
  local allCls = #st.acts > 0
  for _, nd in ipairs(st.acts) do local q = ns.Q[nd.q]; if not (q and q.c) then allCls = false else cls = q.c end end
  card.clsChip:Hide()
  if allCls and cls then
    local tok = ns.GuideClassTok(cls); local cn, cc = ns.ClassInfo(tok)
    card.clsChip:Set(ns.ClassIconText(tok, 12) .. L.CLASSQ:format(cn), cc)
    chips[#chips + 1] = card.clsChip
  end
  -- a boss with nothing for you: "Optional" (or "Rare"), it can be skipped
  card.prePill:Hide(); card.prePill.tip = nil
  if st.bossStep and not done and (st.bossFlag == "rare" or ns.BossStepOptional(st, log)) then
    local word = st.bossFlag == "rare" and L.BOSS_RARE_TAG or L.BOSS_OPT
    card.prePill:Set(word, T.muted)
    card.prePill.tip = { word, L.BOSS_OPT_TT }
    chips[#chips + 1] = card.prePill
  end
  local function ChipsW() local w = 0; for _, c in ipairs(chips) do w = w + (num(c:GetWidth()) or 0) + 6 end return w end
  local chW0 = 0
  if chText then card.chapter:SetText(chText); chW0 = (ns.TextWidth(card.chapter) or 0) + 2 end
  -- no room on the line: the class goes into the detail lines instead (never cut)
  if chips[1] == card.clsChip and (chText and (chW0 + 6) or 0) + ChipsW() - 6 > avail then
    card.clsChip:Hide(); table.remove(chips, 1)
  end
  local topH = (showBadge or chText or #chips > 0) and 18 or 0
  local x0 = CI
  if chText then
    local cw = math.max(80, math.min(chW0, avail - ChipsW()))
    card.chapter:ClearAllPoints(); card.chapter:SetPoint("TOPLEFT", card, "TOPLEFT", CI, -(CI + 2))
    card.chapter:Show()
    local chH = ns.FitText(card.chapter, 2, cw, card)
    topH = math.max(18, math.ceil(chH + 4))
    x0 = CI + cw + 6
  else card.chapter:Hide() end
  for _, c in ipairs(chips) do
    c:ClearAllPoints(); c:SetPoint("TOPLEFT", card, "TOPLEFT", x0, -CI); c:Show()
    x0 = x0 + (num(c:GetWidth()) or 0) + 6
  end
  -- the block under the top line (or at the card's inset when the line is empty)
  local yTop = (topH > 0) and (CI + topH + 8) or CI
  local y = yTop
  -- an ordinary step (one NPC or one place): its title is the current action, in the block
  local focusMode = not st.gate and not st.ins and not st.split and #st.acts > 0

  card.model:SetShown(hasModel); card.modelBg:SetShown(hasModel)
  if hasModel then card.modelBg:ClearAllPoints(); card.modelBg:SetPoint("TOPRIGHT", card, "TOPRIGHT", -CI, -y) end
  card.whereLine:Hide(); card.wlPt, card.wlBase, card.wlDist = nil, nil, nil
  -- beside the portrait (76 + 8): the title, then every block that starts above its bottom
  local sideW = hasModel and (TW - 84) or TW
  local portBottom = hasModel and (yTop + 76) or nil
  card.kicker:Hide()
  if focusMode then card.title:SetText(""); card.title:Hide()
  else
    local title = StepTitle(st, true)
    -- a boss: "Boss 2 of 9" in small over its name (the name is what you look for)
    if st.bossStep then
      card.kicker:SetText(L.TR_BOSS_N:format(st.bossIdx, st.bossN or st.bossIdx))
      card.kicker:ClearAllPoints(); card.kicker:SetPoint("TOPLEFT", card, "TOPLEFT", CI, -y); card.kicker:Show()
      y = y + ns.FitText(card.kicker, 2, sideW, card) + 2
      title = ns.BossStepName(st)
    end
    card.title:SetText(title); card.title:Show()
    card.title:ClearAllPoints(); card.title:SetPoint("TOPLEFT", card, "TOPLEFT", CI, -y)
    y = y + ns.FitText(card.title, 0, sideW, card)
    -- under it: the entrance of a check-list (zone, distance), or the area of a dungeon step
    local wl
    local d = st.gate and ns.D[st.gate]
    if d and d.e and d.e.m then
      local zn = ZoneName(d.e.m)
      wl = L.CARD_ENTRY:format(("%s%.1f, %.1f"):format(zn ~= "" and (zn .. " ") or "", d.e.x, d.e.y))
      local dist = DistText(d.e.m, d.e.x, d.e.y)
      card.wlBase, card.wlPt, card.wlDist = wl, { d.e.m, d.e.x, d.e.y }, dist
      card.wlW = sideW
      if dist then wl = wl .. Hex(T.muted) .. SEP .. dist .. "|r" end
    elseif st.ins and not st.split and bandH == 0 then
      local allOuter = true
      for _, nd in ipairs(st.acts) do if nd.kind ~= "c" or nd.outer == false then allOuter = false end end
      wl = allOuter and L.OUTER:format(dn) or L.IN_DUNGEON:format(dn)
    end
    if wl then
      card.whereLine:SetText(wl)
      card.whereLine:ClearAllPoints(); card.whereLine:SetPoint("TOPLEFT", card, "TOPLEFT", CI, -(y + 4)); card.whereLine:Show()
      y = y + 4 + ns.FitText(card.whereLine, 2, sideW, card)
    end
  end

  -- the check-list "before entering": a banner (state, why, what next).
  -- Inside the dungeon it is over: the "inside the dungeon" band above the card takes its place.
  local checks = st.checks
  -- only on the gate itself: a step inside (whose own rows take quests there) never says "taken outside"
  local isCL = st.gate and checks and #checks > 0 and not (st.ins and InInstanceOf(st.ins))
  -- every quest but no key: the banner says it, the key section then skips its own warning
  local readyNoKey, clMiss, clTotal = false, 0, 0
  local clDn = ns.DName(st.gate or st.ins) or ""
  -- the objectives still to finish outside before entering (T-85): listed, and "Ready" waits for them
  local outList, outReq = {}, 0
  if st.gate then outList, outReq = NAV.OutsideLeft(log, i) end
  if isCL then
    local miss, tot, keyMissing = ReadyState(log, st)
    clMiss, clTotal = miss, tot
    local head, why, nxt, col, icon
    if miss == 0 and not keyMissing and outReq == 0 then
      head, why, nxt, col, icon = L.CL_OK_H:format(clDn), L.CL_OK_T, L.CL_OK_NEXT, T.ok, "check"
    elseif miss == 0 and outReq > 0 then
      head = ns.Plural(outReq, "CL_OUT_H1", "CL_OUT_HN", outReq)
      why, nxt, col, icon = L.CL_OUT_T:format(clDn), L.CL_OUT_NEXT, T.warn, "warning"
    elseif miss == 0 then
      readyNoKey = true
      head, why, nxt, col, icon = L.CL_KEY_H, L.CL_KEY_T:format(clDn), L.CL_KEY_NEXT, T.warn, "warning"
    else
      head = (miss == 1) and L.CL_MISS_H1 or L.CL_MISS_HN:format(miss)
      why, nxt, col, icon = ((miss == 1) and L.CL_MISS_T1 or L.CL_MISS_T):format(clDn), L.CL_MISS_NEXT, T.warn, "warning"
    end
    card.readyBg:SetColorTexture(col[1], col[2], col[3], 0.16); card.readyEdge(col, 0.4)
    ns.SetHDIcon(card.readyIcon, icon, col)
    card.ready:SetText(Hex(T.fg) .. head .. "|r\n" .. Hex(T.text) .. why .. "|r\n" .. Hex(T.muted) .. nxt .. "|r")
    card.ready:Show(); card.readyIcon:Show()
  else card.ready:Hide(); card.readyIcon:Hide(); card.readyBox:Hide() end

  card.travelIcon:Hide()
  -- the travel sentence is plain text (icon audit); on an ordinary step it sits in the block, and a
  -- finished step looked at again needs none (its pill says "Faite", the big button goes back)
  Size(card.travel, ns.F.meta)
  local tl = st.loc
  local trKey = st.travel
  if trKey and tl then trKey = ns.GuideLiveTravelKey(st, tl.m, tl.x, tl.y) end
  if trKey and not focusMode and not done then
    card.travel:SetText(TravelText(st, tl and tl.m, tl and tl.x, tl and tl.y, trKey) or ""); card.travel:SetTextColor(T.text[1], T.text[2], T.text[3])
  else card.travel:SetText("") end
  if card.travel:GetText() and card.travel:GetText() ~= "" then
    y = y + 8
    card.travel:ClearAllPoints(); card.travel:SetPoint("TOPLEFT", card, "TOPLEFT", CI, -y); card.travel:Show()
    y = y + ns.FitText(card.travel, 0, (portBottom and y < portBottom) and sideW or TW, card)
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
  local skipQ = ns.GuideStepSkipQuest(st, log, dkey)
  if not skipQ or card.skipBtn.qid ~= skipQ then ns.GuideSkipDisarm(card.skipBtn) end
  card.skipBtn.qid = skipQ
  card.skipBtn:Hide()
  -- the step's text blocks (design system 3.21): above the rows (note) and under them (after),
  -- each a gold heading, then its sentence or its list
  local note, after = {}, {}
  -- grouped at a gate: the "Group" block under the rows ends with the share button
  -- (in a group the footer's share button does it: the card keeps the group line only when alone)
  local shareAfter = false
  local grouped = IsInGroup and IsInGroup() and true or false
  if st.gate then
    -- the banner and the rows already count the quests: key / entrance / group under the rows
    -- a run with no quest: nothing to check, only the way in (and no quest to share)
    if st.run and clTotal == 0 then note[#note + 1] = { body = { L.RUN_GATE_N } } end
    if #outList > 0 then after[#after + 1] = { h = L.CL_OUT, list = outList } end
    local kl = ns.KeyLines and ns.KeyLines(st.gate) or {}
    if #kl > 0 then
      local t, warn = {}, false
      for _, k in ipairs(kl) do table.insert(t, k[1]); if k[3] and not k[2] then warn = true end end
      local b = (#t >= 2) and { h = L.CL_KEY, list = t } or { h = L.CL_KEY, body = t }
      if warn and not readyNoKey then b.foot = { Hex(T.warn) .. L.KEY_WARN .. "|r" } end
      after[#after + 1] = b
    end
    local d = ns.D[st.gate]
    if d and d.ed then after[#after + 1] = { h = L.CL_ENTRY, body = { ns.T(d.ed) } } end
    -- in a group: the header, then the share button; alone: why sharing waits
    -- class quests only: nothing to share with the group
    local allClsQ = #(st.checks or {}) > 0
    for _, nd in ipairs(st.checks or {}) do local q = ns.Q[nd.q]; if not (q and q.c) then allClsQ = false end end
    if not grouped and not allClsQ and not (st.run and clTotal == 0) then after[#after + 1] = { h = L.CL_GROUP, body = { L.GATE_N } } end
  end
  if st.split then
    -- a boss: where it stands, how to fight it, what it drops for you; then a tip, then "on the
    -- way" as a list
    local tips = ns.STEP_TIPS and ns.STEP_TIPS[st.ins]
    local mine = tips and tips[(st.bossIdx == 0 and "*start") or (st.bossIdx == 999 and "*trash") or st.bossEn or ""]
    local tipLines = {}
    if mine then table.insert(tipLines, ns.T(mine[1])) end
    if st.bossStep then
      local path = ns.BossPathText and ns.BossPathText(st.ins, st.bossEn)
      if path then note[#note + 1] = { h = L.H_PATH, body = { path } } end
      -- the journal's tip is a sentence; our own note one line per role: a list
      local tac = Block(L.H_TACTIC, ns.BossTacticText and ns.BossTacticText(st))
      if tac then note[#note + 1] = tac end
      local loot = Block(L.H_LOOT, ns.BossLootText and ns.BossLootText(st))
      if loot then note[#note + 1] = loot end
    elseif st.bossTip then table.insert(tipLines, Hex(T.muted) .. st.bossTip .. "|r") end
    if #tipLines > 0 then note[#note + 1] = { h = L.H_TIP, body = tipLines } end
    if st.trash or st.trashAll then
      -- only what is done on the way to THIS boss (T-92), each line with its verb, where, count and
      -- who drops it ("Tuer : Noxxious Scion · Aile orange, ... avant Noxxion · 0 sur 8"); what drops
      -- everywhere once, on the first step inside ("Tout le donjon : 25 x ... (tombent sur les monstres)")
      local names = ns.GuideAlsoLines(st, log)
      if #names > 0 then note[#note + 1] = { h = L.H_ALSO, list = names } end
    end
  end
  card.note:Hide()
  card.noteText = #note > 0 and BlocksText(note) or nil
  if #note > 0 then
    y = y + GAP
    -- a block that starts beside the boss's portrait keeps to its left
    y = y + DrawBlocks(card.noteStk, note, CI, y, TW, portBottom, sideW)
  else HideStack(card.noteStk) end
  if portBottom then y = math.max(y, portBottom) end
  y = y + 8

  -- an ordinary step (one NPC or one place): the current action big and clear, the others as a
  -- short list. Check-lists and steps inside a dungeon keep one row per line (bosses in order).
  -- (the block has its own 8 px top pad: it starts 8 px over the top line's gap)
  if focusMode then y = RenderFocus(card, st, log, yTop - 8, dkey) else HideFocus(card) end
  local rowW = CardW() - 8
  local subW = rowW - ROW_NAME_X - 12
  local view = focusMode and {} or ns.StepView(st, log)
  -- T-91: under a check-list, the quests whose chain is not done before it, greyed (st.locks)
  if not focusMode and st.gate and st.locks and #st.locks > 0 then
    local v = {}
    for _, nd in ipairs(view) do v[#v + 1] = nd end
    for _, nd in ipairs(st.locks) do v[#v + 1] = nd end
    view = v
  end
  local mt = Hex(T.muted)
  -- a quest's chain place, its note and its "To take" are said once in the card: on its first row
  local seenChain, seenNote, seenObj = {}, {}, {}
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
      local npcW = math.min(ns.TextWidth(row.npc) + 2, 140)
      row.npc:SetWidth(npcW)
      row.gb:Hide(); row.wpOn:Hide(); row.icon:Hide()
      -- the whole-dungeon header has its word only ("Tout le donjon"): no flag
      if nd.bossIdx > 0 then Icon(row.kicon, "boss"); row.kicon:SetAlpha(nd.allOk and 0.5 or 1); row.kicon:Show()
      else row.kicon:Hide() end
      local nameH = ns.FitText(row.name, 2, math.max(80, rowW - ROW_NAME_X - 12 - npcW - 8), row)
      local sub = (not nd.allOk and nd.tip) and nd.tip or ""
      row.sub:SetText(sub); row.sub:SetShown(sub ~= "")
      row.list:Hide(); row.sub2:Hide()
      local subTop = 10 + nameH + 3
      row.sub:ClearAllPoints(); row.sub:SetPoint("TOPLEFT", row, "TOPLEFT", ROW_NAME_X, -subTop)
      local subH = (sub ~= "") and (ns.FitText(row.sub, f.compactIn and 3 or 0, subW, row)) or 0
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
      -- a locked check-list line (T-91, st.locks): "Locked", greyed, never "Required"
      if nd.lock then
        row.tag:SetText(L.CL_LOCKED); row.tag:SetTextColor(T.muted[1], T.muted[2], T.muted[3])
      elseif nd.kind == "h" and ns.GuideOptionalCheck(nd, st.gate or st.ins or dkey) then
        row.tag:SetText(L.HAVE_OPT); row.tag:SetTextColor(T.muted[1], T.muted[2], T.muted[3])
      else row.tag:SetText(L[KTAG[nd.kind]] or ""); row.tag:SetTextColor(kc[1], kc[2], kc[3]) end
      row.name:SetText(nd.label or ns.QName(nd.q))
      -- the NPC on the right, unless the step's title already names it (then the quest's state);
      -- a check-list row keeps its state ("To take"): its detail line already names the giver
      local npcShort = nd.npc and not nd.ins and nd.kind ~= "h" and nd.npc:gsub(",.*$", "")
      local title = card.title:GetText() or ""
      if npcShort and title:find(npcShort, 1, true) then npcShort = nil end
      local sc = SCOL[s] or T.muted
      local right = npcShort or (((nd.kind == "a" or nd.kind == "c" or nd.kind == "o" or nd.kind == "t") and s == "none") and "" or (Hex(sc) .. L[SLABEL[s] or "S_NONE"] .. "|r"))
      -- check-list row: plainly "In your log" (green) or "To take" (orange)
      if nd.kind == "h" then right = ok and (Hex(T.ok) .. L.CL_HAVE .. "|r") or (Hex(T.warn) .. L.CL_TAKE .. "|r") end
      if nd.lock then right = "" end
      row.npc:SetText(right)
      SetSecureRow(row, nd, ok)
      local canGo = not nd.lock and ns.NodeCanGo(nd)
      row.gb:SetShown(canGo)
      local isActive = canGo and NodeFollowed(nd) and not ok
      row.wpOn:SetShown(isActive and true or false)
      local x = -12
      if canGo then
        -- followed: the row is selected and the button says so
        row.gb:SetText(isActive and (L.GPS_ON or "GPS") or "GPS")
        row.gb:ClearAllPoints(); row.gb:SetPoint("TOPRIGHT", row, "TOPRIGHT", x, -5)
        x = x - (num(row.gb:GetWidth()) or 60) - 8
      end
      row.npc:ClearAllPoints(); row.npc:SetPoint("TOPRIGHT", row, "TOPRIGHT", x, -12)
      -- the name keeps 120 px at least; the NPC (or state) gets what is left, up to 140 px, and
      -- goes to the start of the detail lines when less than 60 px would remain for it
      local room = rowW - ROW_NAME_X + x - 8
      local npcW = math.min(ns.TextWidth(row.npc) + 2, 140, math.max(0, room - 120))
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
        if nd.lock then row.kicon:SetAlpha(0.5); row.name:SetTextColor(T.muted[1], T.muted[2], T.muted[3]) end
      end
      -- detail lines
      local parts = {}
      local tags = {}
      if nd.d and nd.d ~= dkey then table.insert(tags, mt .. ns.DName(nd.d) .. "|r") end
      local preKnown = nd.pre and ((nd.ci and nd.cn) or not ((nd.kind == "a" or nd.kind == "h") and ns.ChainState))
      if preKnown and seenChain[nd.q] then preKnown = false end
      if preKnown then seenChain[nd.q] = true end
      if preKnown then
        -- where you are in the chain, and what it leads to: "Step 3 of 9 before Agamaggan's Blood"
        local lead = nd.forQ and nd.forQ[1]
        local txt = (nd.ci and nd.cn and lead) and ns.GuideChainText(nd, true)
          or (nd.ci and nd.cn) and L.CH_STEP:format(nd.ci, nd.cn) or L.PRE
        table.insert(tags, Hex(T.text) .. txt .. "|r")
      elseif (nd.kind == "a" or nd.kind == "h") and not ok and ns.ChainState then
        -- a dungeon quest to take: does it have prerequisites, and are they done?
        local cs = ns.ChainState(nd.q)
        if cs.total == 0 then table.insert(tags, mt .. L.CH_NONE .. "|r")
        elseif cs.done >= cs.total then table.insert(tags, Hex(T.ok) .. L.CH_ALLDONE .. "|r")
        else table.insert(tags, Hex(T.warn) .. L.ST_PRE:format(cs.done + 1, cs.total) .. "|r") end
      end
      -- the class, unless the card's "Class quest" pill already says it
      if q.c and not card.clsChip:IsShown() then
        local tok = ns.GuideClassTok(q.c); local cn, cc = ns.ClassInfo(tok)
        table.insert(tags, ns.ClassIconText(tok, 12) .. Hex(cc) .. L.CLASS_TAG:format(cn) .. "|r")
      end
      if #tags > 0 then table.insert(parts, table.concat(tags, mt .. "  ·  |r")) end
      local tx = Hex(T.text)
      if not ok then
        -- a quest that starts from an item (the Essence of Eranikus, an Oathstone): how to take it,
        -- in words (report: "I looted the essence and don't understand where to accept the next quest")
        if nd.kind == "a" and s == "none" and q.s and q.s.i == 1 and L.ROW_ITEM_START then
          local it = q.si or q.s.n
          if it then table.insert(parts, Hex(T.warn) .. L.ROW_ITEM_START:format((ns.LN and ns.LN("item", it)) or it) .. "|r") end
        end
        if nd.kind == "a" and s == "none" then
          local pb = ns.PrereqProblem(nd.q)
          if pb then table.insert(parts, Hex(T.bad) .. L.BLOCKED:format(pb) .. "|r") end
        end
        if nd.kind == "h" then
          local A = q.s and q.s.n or q.st
          if A then table.insert(parts, tx .. ns.Elide(L.GIVER:format(A)) .. "|r") end
        elseif nd.kind ~= "t" then
          local obj = ns.GuideObjSentence(q)
          local lines = (nd.kind == "c" or nd.kind == "o") and ObjectiveLines(nd, log) or {}
          if obj and (nd.kind == "a" or #lines == 0) and not seenObj[nd.q] then seenObj[nd.q] = true; table.insert(parts, tx .. obj .. "|r") end
          if nd.kind == "c" or nd.kind == "o" then
            for _, l2 in ipairs(lines) do
              -- a sources line ("    Drops from: ...") goes under its objective, in the same item
              local last = parts[#parts]
              if l2:sub(1, 4) == "    " and type(last) == "table" then last.li = last.li .. "\n" .. l2:sub(5)   -- already muted (ObjectiveLines)
              else table.insert(parts, { li = tx .. l2 .. "|r" }) end
            end
          end
          if nd.kind == "a" and q.si then table.insert(parts, q.si .. (q.sih and (L.COLON .. ns.T(q.sih)) or "")) end
          if q.ne and not seenNote[nd.q] and (nd.firstOfQuest ~= false) and (nd.kind == "c" or nd.kind == "o" or (nd.kind == "a" and not q.o)) then seenNote[nd.q] = true; table.insert(parts, ns.T(q.ne)) end
          if nd.extra then table.insert(parts, nd.extra) end
          if nd.kind == "c" and ns.BossLines and not nd.oneObj then
            for _, bl in ipairs(ns.BossLines(nd.q) or {}) do
              table.insert(parts, tx .. L.BOSS .. L.COLON .. bl[1] .. "|r" .. (bl[2] and ("  " .. bl[2]) or ""))
            end
          end
        end
        if nd.kind == "t" and s == "on" then
          -- quest not finished yet when it is time to turn it in: what is left to do
          local obj = ns.GuideObjSentence(q)
          if obj then table.insert(parts, tx .. obj .. "|r") end
        end
        if (nd.kind == "t" and s == "on") or (nd.kind == "c" and #ObjectiveLines(nd) == 0) then
          for _, r2 in ipairs(q.req or {}) do
            table.insert(parts, { li = r2[1] .. (r2[2] and r2[2] > 1 and (" x" .. r2[2]) or "") .. (r2[3] and (L.COLON .. ns.T(r2[3])) or "") })
          end
        end
        if nd.unknown then table.insert(parts, L.TRAVEL_UNK) end
        if (nd.kind == "h" or nd.kind == "c" or nd.kind == "a") and ns.PartyLine and nd.firstOfQuest ~= false then
          local pl = ns.PartyLine(nd.q)
          if pl then table.insert(parts, Hex(T.info) .. pl .. "|r") end
        end
      end
      -- a locked line says only why, greyed: "Locked: first needs "X" (NPC, zone) · prerequisite 4/7"
      if nd.lock then parts = { mt .. (ns.CheckLockText and ns.CheckLockText(nd.q, nil, nd.d) or L.CL_LOCKED) .. "|r" } end
      if npcInSub then table.insert(parts, 1, npcInSub) end
      -- the lines before the list, the list ({ li = text }), the lines after it
      local pre, items, post = {}, {}, {}
      for _, p in ipairs(parts) do
        if type(p) == "table" then items[#items + 1] = p.li
        elseif #items > 0 then post[#post + 1] = p
        else pre[#pre + 1] = p end
      end
      local sub, sub2 = table.concat(pre, "\n"), table.concat(post, "\n")
      local nameH = ns.FitText(row.name, 2, nameW, row)
      row.sub:SetText(sub); row.sub:SetShown(sub ~= "")
      -- the detail lines start under the name, and under the GPS button (y 5 to 29) when it shows
      local subTop = 10 + nameH + 3
      if nd.loc then subTop = math.max(subTop, 5 + 24 + 4) end
      row.sub:ClearAllPoints(); row.sub:SetPoint("TOPLEFT", row, "TOPLEFT", ROW_NAME_X, -subTop)
      local subH = (sub ~= "") and (ns.FitText(row.sub, f.compactIn and 3 or 0, subW, row)) or 0
      -- inside the dungeon the row keeps a few lines (the full text is in its tooltip)
      if f.compactIn and #items > 3 then
        -- the rest is in the row's tooltip: say how many are not shown
        local more = #items - 3
        while #items > 3 do table.remove(items) end
        local plus = mt .. "+" .. more .. "|r"
        sub2 = sub2 ~= "" and (plus .. "\n" .. sub2) or plus
      end
      if #items > 0 then
        local ly = subTop + subH + (subH > 0 and 3 or 0)
        subH = (ly - subTop) + row.list:Place(items, ROW_NAME_X, ly, subW, { size = ns.F.meta })
      else row.list:Hide() end
      if sub2 ~= "" then
        local y2 = subTop + subH + (subH > 0 and 3 or 0)
        row.sub2:SetText(sub2)
        row.sub2:ClearAllPoints(); row.sub2:SetPoint("TOPLEFT", row, "TOPLEFT", ROW_NAME_X, -y2); row.sub2:Show()
        subH = (y2 - subTop) + ns.FitText(row.sub2, f.compactIn and 2 or 0, subW, row)
      else row.sub2:SetText(""); row.sub2:Hide() end
      local rh = math.max(36, math.ceil(subTop + subH + 8))
      row:SetHeight(rh)
      row:ClearAllPoints(); row:SetPoint("TOPLEFT", card, "TOPLEFT", 4, -y)
      y = y + rh
      row:Show()
    else
      row.node = nil; row.bossName = nil; row:Hide()
    end
  end
  card.afterText = #after > 0 and BlocksText(after) or nil
  if #after > 0 then
    y = y + GAP
    y = y + DrawBlocks(card.afterStk, after, CI, y, TW)
  else HideStack(card.afterStk) end
  if shareAfter and not f.compactIn then
    y = y + 8
    -- in combat the game blocks the share: « Après le combat », greyed
    local shareCombat = ns.ShareInCombat and ns.ShareInCombat() or false
    card.shareBtn:SetText(shareCombat and L.SHARE_AFTER or L.SHARE_SHORT)
    if card.shareBtn.Disable then if shareCombat then card.shareBtn:Disable() else card.shareBtn:Enable() end end
    card.shareBtn.disabledReason = shareCombat and L.SHARE_AFTER_TT or nil
    card.shareBtn:ClearAllPoints(); card.shareBtn:SetPoint("TOPLEFT", card, "TOPLEFT", CI, -y); card.shareBtn:Show()
    if skipQ then
      card.skipBtn:ClearAllPoints(); card.skipBtn:SetPoint("LEFT", card.shareBtn, "RIGHT", 8, 0); card.skipBtn:Show()
    end
    y = y + 28
  elseif skipQ and not f.compactIn then
    y = y + 8
    card.skipBtn:ClearAllPoints(); card.skipBtn:SetPoint("TOPLEFT", card, "TOPLEFT", CI, -y); card.skipBtn:Show()
    y = y + 24
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
  elseif st.ins and not st.gate and ns.ShowBosses and ns.D[st.ins] then
    -- inside a dungeon a step has no map point (T-92): the big button opens the dungeon's map and
    -- bosses panel instead of a greyed "No map point"
    f.go:SetText(L.DUNGEON_MAP); if f.go.SetIcon then f.go:SetIcon("skull") end
    local dk = st.ins
    f.go.action = function() ns.ShowBosses(dk) end; f.go:SetEnabled(true)
  elseif st.ins and not st.gate and i < #steps then
    f.go:SetText(L.NEXT2); if f.go.SetIcon then f.go:SetIcon("chevron_right") end
    f.go.action = function() ns.GoTo(i + 1) end; f.go:SetEnabled(true)
  else
    -- disabled and labelled: its tooltip says why, an info icon added nothing
    f.go:SetText(L.NOPOINT_S); if f.go.SetIcon then f.go:SetIcon(nil) end
    f.go.action = nil; f.go:SetEnabled(false)
    f.go.disabledReason = L.NOPOINT
  end
  f.done:SetEnabled(true)
  f.done.label:SetText(ManualHolds(log, st) and L.M_UNSKIP or L.M_SKIP)
  if not f.restartItem.armToken then f.restartItem.label:SetText(L.M_RESTART) end
  if f.stopItem and not f.stopItem.armToken then f.stopItem.label:SetText(L.M_STOP) end
  local mi = 0
  for _, m in ipairs(ns.MemberSteps()) do
    local it = f.memberItems[mi + 1]
    if not it then break end
    mi = mi + 1
    it.go, it.who = m.i, m.name
    it.label:SetText(L.M_MEMBER:format(m.name)); it.wlOff = nil; it:Show()
  end
  for k = mi + 1, #f.memberItems do local it = f.memberItems[k]; it.wlOff = true; it.go = nil; it:Hide() end
  f.menu.Layout()
  f.arrowBtn.label:SetText(L.M_ARROW); f.arrowBtn:SetOn(WLDTDB.arrow ~= false)
  f.bossItem.label:SetText(L.M_BOSSES)
  if f.keysItem then f.keysItem.label:SetText(L.M_KEYS) end
  local bossDk = ns.instIn or GuideDungeon()
  f.bossItem:SetEnabled(((ns.ToggleBosses and bossDk) or (ns.JournalAvailable and ns.JournalAvailable())) and true or false)
  f.bossItem:SetOn(ns.BossesShown and ns.BossesShown())
  f.bossItem.disabledReason = L.BOSS_MENU_NONE

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
-- The guide is in front of you: its window, or the quest tracker that shows its step. A guide closed
-- with its X (and no tracker) follows quietly: no sound, no centre-screen or chat line.
local function GuideSeen()
  if f and f:IsShown() then return true end
  local TR = WLHelperTracker
  local tf = TR and TR.Frame and TR.Frame()
  return (tf and tf:IsShown()) and true or false
end
ns.GuideSeen = GuideSeen

-- "Next step: ..." with the quest sound (Refresh on an advance, Replan when the current step changed)
function ns.AnnounceStep(i)
  local st = Steps()[i]
  if not st then return end
  if not GuideSeen() or ns.muteAnnounce then return end
  PlaySound(SOUNDKIT and SOUNDKIT.IG_QUEST_LIST_COMPLETE or 878)
  local t = StepTitle(st)
  if UIErrorsFrame then UIErrorsFrame:AddMessage("WL Helper" .. L.COLON .. t, T.fg[1], T.fg[2], T.fg[3]) end
  ns.Print(L.NEXT_STEP:format(t))
end

function ns.Refresh(silent)
  if not f then return end
  if ns.GuideOn and not ns.GuideOn() then return end
  local steps = Steps()
  -- the window is drawn only when shown (OnShow refreshes); the step, the arrow and the macro
  -- still follow while it is closed (the target key and the tracker use them)
  local shown = f:IsShown()
  if #steps == 0 then f.wasFin = nil; if shown then Render() end return end
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
    if was and auto > was and not silent and not fin then ns.AnnounceStep(auto) end
    -- the group sees where you are ("See where ... is", Sync.lua)
    if ns.SyncStepChanged then ns.SyncStepChanged() end
  end
  if fin and not f.wasFin and not silent then
    ns.ClearPoints(); f.sig = nil
    if GuideSeen() and not ns.muteAnnounce then
      PlaySound(SOUNDKIT and SOUNDKIT.IG_QUEST_LIST_COMPLETE or 878)
      if UIErrorsFrame then UIErrorsFrame:AddMessage("WL Helper" .. L.COLON .. L.FIN_T, T.ok[1], T.ok[2], T.ok[3]) end
      ns.Print(L.FIN_MSG:format(ns.route.label or ""))
    end
  end
  f.wasFin = fin
  if WLDTDB.autoWay and not fin then
    -- the GPS follows the step on screen: "Étape suivante" / a click in the list moves the arrow
    -- too (the step in progress itself does not change)
    -- the window closed and the modern view on screen: the GPS follows the modern view's step (its
    -- arrows browse), not a step the window was left on (report: "it still sends me into the dungeon")
    local TRk = WLHelperTracker
    local trf = TRk and TRk.Frame and TRk.Frame()
    if not shown and trf and trf:IsShown() then f.view = TRk.browse or auto end
    local gi = (f.view and f.view >= 1 and f.view <= #steps) and f.view or auto
    local pts = StepPoints(log, steps[gi], false)
    local sig = gi .. ":" .. #pts
    for _, p in ipairs(pts) do sig = sig .. p[2] .. p[3] end
    if sig ~= f.sig then f.sig = sig; f.wpKey = nil; ns.SetPoints(pts, true) end
  end
  if shown then Render()
  else
    -- closed: what Render keeps for later is kept all the same: the step a /reload brings back
    -- (WLDTDB.view) and the action bar, hidden with the window (Escape, a loading screen)
    if f.view then WLDTDB.view = math.max(1, math.min(fin and #steps + 1 or #steps, f.view)) end
    ns.UpdateActionBar()
  end
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
  -- the same text as the target key binding (Engine.lua); false, not nil: no step means no target
  local st = f and f.auto and steps[f.auto]
  local body = ns.TargetMacroText(st or false, log)
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
  -- kept on screen (a position saved with another resolution or UI scale): the whole width when
  -- it fits, and the header always
  local sw, sh = UIParent:GetWidth(), UIParent:GetHeight()
  if type(sw) == "number" and type(sh) == "number" and sw > 0 and sh > 0 then
    local fw = (f:GetWidth() or W) * s
    x = math.max(0, math.min(x, math.max(0, sw - fw)))
    y = math.max(math.min(sh, HEADER * s), math.min(y, sh))
  end
  f:ClearAllPoints(); f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x / s, y / s)
  WLDTDB.pos = { "TOPLEFT", "BOTTOMLEFT", x / s, y / s }
end

-- =====================================================================
--  Barre d'actions (boutons sécurisés) : cibler + crâne, utiliser l'objet de quête.
--  Fenêtre à part, attachée à l'écran : utilisable en combat ; son contenu se met à jour hors combat.
-- =====================================================================
local abar, abPending
local AB_N, AB_S = 8, 30
-- the bar's keys: WLDT_ITEM clicks the first item button (override binding owned by the bar, set
-- out of combat); WLDT_TARGET (Main.lua) targets the step's target, shown on the first target button
local abItemBtn, abKeySig, abKeyBusy
local function BindKeys(cmd)
  local out = {}
  if type(GetBindingKey) ~= "function" then return out end
  for _, k in ipairs({ GetBindingKey(cmd) }) do
    if type(k) == "string" and k ~= "" then out[#out + 1] = k end
  end
  return out
end
-- "Key: F" or "No key: right-click to set one", for a command of Bindings.xml
function ns.KeyTipLine(cmd)
  local k = BindKeys(cmd)[1]
  if not k then return L.KEY_NONE end
  local t = type(GetBindingText) == "function" and GetBindingText(k, "KEY_") or nil
  if type(t) ~= "string" or t == "" then t = k end
  return L.KEY_IS:format(t)
end
function ns.ItemBindingButton() return abItemBtn end
-- out of combat: right-click on a bar button whose key is not set opens the key bindings (its
-- secure right-click then does nothing; with a key set it acts as before), and the item key
-- follows the bar's first item button. Setting override bindings fires UPDATE_BINDINGS: only
-- rebind when the button or the keys changed.
function ns.RefreshActionKeys()
  if not abar or abKeyBusy then return end
  if InCombatLockdown() then abPending = true return end
  for k = 1, AB_N do
    local b = abar.btns[k]
    local free = (b.keyCmd and b.action and BindKeys(b.keyCmd)[1] == nil) and true or false
    if free ~= (b.kbRight or false) then
      b.kbRight = free or nil
      b:SetAttribute("*type2", free and "wlhnone" or nil)
    end
  end
  if not (ClearOverrideBindings and SetOverrideBindingClick) then return end
  local keys = abItemBtn and BindKeys("WLDT_ITEM") or {}
  local sig = abItemBtn and (abItemBtn .. "|" .. table.concat(keys, " ")) or ""
  if sig == abKeySig then return end
  abKeyBusy = true
  local ok, err = pcall(function()
    ClearOverrideBindings(abar)
    for _, key in ipairs(keys) do SetOverrideBindingClick(abar, false, key, abItemBtn, "LeftButton") end
  end)
  abKeyBusy = false
  if ok then abKeySig = sig else error(err, 0) end
end
local function KeysRightClick(self, button, down)
  if button ~= "RightButton" or down or not self.kbRight then return end
  -- in combat the secure right-click does nothing: OpenKeyBindings opens nothing and says why
  -- (KEYS_COMBAT), so the click is not silently lost
  if ns.OpenKeyBindings then ns.OpenKeyBindings() end
end
-- where a target of the bar comes from: the first quest that names it (its NPC id, read live), and
-- whether it is a world object (a chest, an herb, an urn: an objective "use the object")
local function TargetSource(a, n, t)
  a.q = a.q or n.q
  local o = n.oneObj or n.obj
  local objs = o and { o } or ((ns.Q[n.q] or {}).o or {})
  for _, x in ipairs(objs) do
    local named = (x.n == t) or (x.w and x.w.n == t)
    for _, y in ipairs(x.t or {}) do if y == t then named = true end end
    if x.k == "object" and named then a.objNames = a.objNames or {}; a.objNames[t] = true end
  end
end
-- the button's face (T-75): the target's portrait (Bosses.lua), the object icon for a world
-- object; the plain head while neither is known. Textures only.
local function TargetIcon(tex, a)
  local nm = a.names[1]
  if not ns.NpcPortrait then
    tex:SetTexture("Interface\\Icons\\INV_Misc_Head_Human_01"); tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    return
  end
  local kind, id
  if a.objNames and a.objNames[nm] then kind = "object" end
  if not kind and ns.TargetEntity then kind, id = ns.TargetEntity(nm, a.q, a.dk) end
  ns.NpcPortrait(tex, nm, id, kind)
end
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
        GameTooltip:AddLine(L.TT_USE, (T.hint or T.muted)[1], (T.hint or T.muted)[2], (T.hint or T.muted)[3])
        if self.keyCmd then GameTooltip:AddLine(ns.KeyTipLine(self.keyCmd), (T.hint or T.muted)[1], (T.hint or T.muted)[2], (T.hint or T.muted)[3]) end
        GameTooltip:Show()
      else
        local t = { L.TT_TARGET, L.TT_TARGET2:format(table.concat(a.names, " / ")), L.TT_TARGET_CLICK }
        if self.keyCmd then t[#t + 1] = ns.KeyTipLine(self.keyCmd) end
        ns.ShowTip(self, t)
      end
    end)
    b:SetScript("OnLeave", ns.HideTip)
    b:SetScript("PostClick", KeysRightClick)
    b:Hide()
    abar.btns[k] = b
  end
  abar:Hide()
end

function ns.UpdateActionBar()
  if not f then return end
  if InCombatLockdown() then abPending = true return end
  if not abar then BuildActionBar() end
  abPending = false
  local steps = Steps()
  local st = steps[f.view or 0]
  local acts, seen = {}, {}
  local trOn = _G.WLDTTracker and _G.WLDTTracker:IsShown()
  if st and ((f:IsShown() and not f.mini) or trOn) then
    local log = ns.LogEntries()
    local count = (C_Item and C_Item.GetItemCount) or GetItemCount
    local view = ns.StepView(st, log)
    local grouped = false
    for _, n in ipairs(view) do if n.kind == "b" then grouped = true break end end
    if st.split then
      grouped = true
      local cur = { names = {}, nseen = {}, num = st.bossStep and tostring(st.bossIdx) or "*", dk = GuideDungeon() }
      if st.bossStep and not ns.BossStepKilled(st) then
        local bn = ns.BossStepName(st)
        cur.nseen[bn] = true; table.insert(cur.names, bn)
      end
      for _, n in ipairs(st.acts) do
        if not ns.NodeOK(log, n) then
          for _, t in ipairs(NodeTargets(n) or {}) do
            if not cur.nseen[t] and #cur.names < 4 then cur.nseen[t] = true; table.insert(cur.names, t); TargetSource(cur, n, t) end
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
            cur = { names = {}, num = n.bossIdx > 0 and tostring(n.bossIdx) or "*", nseen = {}, dk = GuideDungeon() }
            for _, t in ipairs(n.targets or {}) do cur.nseen[t] = true; table.insert(cur.names, t) end
            table.insert(acts, cur)
          end
        elseif cur and not ((n.vok ~= nil) and n.vok or ns.NodeOK(log, n)) then
          for _, t in ipairs(NodeTargets(n) or {}) do
            if not cur.nseen[t] and #cur.names < 4 then cur.nseen[t] = true; table.insert(cur.names, t); TargetSource(cur, n, t) end
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
          if not seen[key] then
            seen[key] = true
            local a = { names = names, dk = GuideDungeon() }
            for _, t in ipairs(names) do TargetSource(a, n, t) end
            table.insert(acts, a)
          end
        end
      end
    end
  end
  local labelW = ns.TextWidth(abar.label) + 8
  local firstItem, firstTarget
  abItemBtn = nil
  for k = 1, AB_N do
    local b, a = abar.btns[k], acts[k]
    b.action = a
    b.keyCmd = nil
    if a and a.item and not firstItem then firstItem = true; b.keyCmd = "WLDT_ITEM"; abItemBtn = "WLDTAction" .. k
    elseif a and not a.item and not firstTarget then firstTarget = true; b.keyCmd = "WLDT_TARGET" end
    if a then
      if a.item then
        b:SetAttribute("type", "item"); b:SetAttribute("item", "item:" .. a.item); b:SetAttribute("macrotext", nil)
        local icon = (C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(a.item)) or (GetItemIcon and GetItemIcon(a.item))
        if ns.NpcPortrait then ns.NpcPortrait(b.icon, nil) end
        b.icon:SetTexture(icon or "Interface\\Icons\\INV_Misc_QuestionMark"); b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
      else
        local m = { "/cleartarget" }
        for _, nm in ipairs(a.names) do table.insert(m, "/targetexact " .. ns.ClientNpcName(nm)) end
        table.insert(m, ns.MarkLine(8))
        b:SetAttribute("type", "macro"); b:SetAttribute("macrotext", table.concat(m, "\n")); b:SetAttribute("item", nil)
        TargetIcon(b.icon, a)
      end
      b.num:SetText(a.num or "")
      b:ClearAllPoints(); b:SetPoint("LEFT", labelW + (k - 1) * (AB_S + 4), 0); b:Show()
    else
      if ns.NpcPortrait then ns.NpcPortrait(b.icon, nil) end
      b:Hide()
    end
  end
  -- above the guide window, or above the modern view when the window is closed (report: "the
  -- modern view has no target button")
  local host = (f:IsShown() and f:GetLeft()) and f or nil
  local tr = _G.WLDTTracker
  if not host and tr and tr:IsShown() and tr:GetLeft() then host = tr end
  if #acts > 0 and host then
    abar:SetSize(labelW + math.min(#acts, AB_N) * (AB_S + 4), AB_S)
    abar:ClearAllPoints()
    -- the bar takes the host's size (scale) and sits on its top-left corner, placed on the screen
    -- (UIParent), never anchored to the host: a secure bar anchored to the modern view made that
    -- view protected, and its height could no longer change in combat (BugGrabber: "WLHelper tried
    -- to call the protected function WLDTTracker:SetHeight()")
    abar:SetScale(host:GetScale() or 1)
    abar:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", host:GetLeft(), host:GetTop() + 4)
    abar:Show()
  else abar:Hide(); abItemBtn = nil end
  ns.RefreshActionKeys()
end
function ns.ActionBarPending() return abPending end

-- For WL Helper's home and the minimap: the route's dungeons, the current step and how many there are.
-- The check-list step ("ready?") of the dungeon the step on screen belongs to
function ns.GoReady()
  local ti = ReadyTarget()
  if ti then ns.GoTo(ti) else ns.Print(L.NO_READY) end
end
-- "Close the checklist": back to the current step (the step after it when the check-list is the
-- current step itself)
function ns.CloseReady()
  if not f then return end
  if f.auto and f.auto ~= f.view then ns.GoTo(f.auto)
  else ns.GoTo((f.view or 1) + 1) end
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

local GuideOff
-- Opens the guide (never closes it): the modern view when it is the default and a route runs
-- (report: "lots of buttons like update guide send to the classic view instead of the modern one"),
-- else the window. ns.ShowWindow: the window itself (the modern view's menu, the tour).
function ns.ShowGuide()
  if not f then return end
  local TR = WLHelperTracker
  if WLDTDB.modernDefault ~= false and ns.route and #(ns.route.steps or {}) > 0 and TR and TR.Compact then
    if GuideOff() then return end
    TR.Compact()
    ns.Refresh()
    return
  end
  if not f:IsShown() then ns.ToggleMain() end
end
function ns.ShowWindow()
  if not f or f:IsShown() or GuideOff() then return end
  f:Show(); WLDTDB.hidden = false
  f.sig = nil; ns.Refresh()
  if ns.UpdateActionBar then ns.UpdateActionBar() end
end

GuideOff = function()
  local WP = ns.Writs and ns.Writs.WP
  return WP and WP.ModuleOff and WP.ModuleOff("dungeons")
end

function ns.ToggleMain()
  if not f then return end
  if not f:IsShown() and GuideOff() then return end
  -- the modern view by default: the guide opens in it when a route runs and it is not on screen
  -- (shown already: the click asks for the window)
  local TR = WLHelperTracker
  local trf = TR and TR.Frame and TR.Frame()
  if not f:IsShown() and WLDTDB.modernDefault ~= false and ns.route and TR and TR.Compact then
    -- the modern view on screen: the toggle closes it (the window is in its menu); else it opens it
    if trf and trf:IsShown() and TR.Close then TR.Close(); return end
    WLDTDB.hidden = false
    TR.Compact()
    ns.Refresh()
    return
  end
  f:SetShown(not f:IsShown()); WLDTDB.hidden = not f:IsShown()
  if WLDTDB.hidden then ns.SetArrow(nil) else f.sig = nil; ns.Refresh() end
  if ns.UpdateActionBar then ns.UpdateActionBar() end
end
