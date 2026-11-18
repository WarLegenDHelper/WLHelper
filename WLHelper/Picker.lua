-- Choisir les donjons : cartes avec image, niveau, progression ; plusieurs donjons = une route.
-- Built with the design system (docs/DESIGN.md): header 44, tabs, a workspace window (3.1: its size
-- from the screen, resizable, the size kept; the cards scroll inside), a footer with the one main
-- action.
local ADDON, ns = ...
local L, T = ns.L, ns.T_
local Text, Tex, Hex = ns.Text, ns.Tex, ns.Hex

local p, qp
-- 2 to 4 columns of picture cards (inset 16, 12 between cards) as the window allows: less
-- scrolling. The window has the workspace size (ns.WinSize: 70 % of the screen, 900 to 1400 units)
-- or the size the player dragged it to; the cards keep at least MIN_CW of width (ns.Cols).
-- UIParent's width is in UI units: a small UI scale makes it larger, so the columns are also held
-- to MIN_PX real screen pixels per card (at UI scale 0.64: 4 cards of 146 px become 3).
local PAD, GAP, MIN_CW, MIN_PX = 16, 12, 220, 200
local PW, COLS, CW = 956, 4, 222
local SMALL = false     -- UI scale under 0.8: the small muted lines of a card go up to 12
local function snum(v) return type(v) == "number" and not (issecretvalue and issecretvalue(v)) and v or nil end
local function EffScale()
  local ok, e = pcall(function() return UIParent:GetEffectiveScale() end)
  if not ok or type(e) ~= "number" or (issecretvalue and issecretvalue(e)) or e <= 0 then return 1 end
  return e
end
-- A tiered window's size now: what it was given (the rule or the player's drag), or the rule's
-- default while the frame cannot tell (not laid out yet).
local function WinSize(win, tier)
  local defW, defH, minW, minH
  if win and win.SizeRule then defW, defH, minW, minH = win:SizeRule()
  elseif ns.WinSize then defW, defH, minW, minH = ns.WinSize(tier) end
  defW, minW = defW or 900, minW or 0
  local w = win and snum(win:GetWidth())
  if not w or w < minW - 1 then w = defW end
  local h = win and snum(win:GetHeight())
  if minH and (not h or h < minH - 1) then h = defH end
  return math.floor(w), h and math.floor(h) or nil
end
local function Dims()
  local eff = EffScale()
  PW = WinSize(p, "workspace")
  local cw = PW - 2 * PAD
  local n, colW = 2, math.floor((cw - GAP) / 2)
  if ns.Cols then n, colW = ns.Cols(cw, MIN_CW, GAP, 4, MIN_PX) end
  -- 2 columns at least, as before (a very small window or UI scale)
  if n < 2 then n, colW = 2, math.floor((cw - GAP) / 2) end
  COLS, CW = n, colW
  SMALL = eff < 0.8
end
Dims()
ns.PickerDims = function() Dims(); return PW, COLS, CW end   -- for the offline tests
-- Card height: at least CH_MIN; every render takes the tallest card's need (2-line name on top,
-- the level line, the quests stat and its prerequisite line at the bottom), so a row stays even
-- and nothing is cut, in French as in English, down to MIN_CW.
local CH_MIN = 124
local CH = CH_MIN
local BAND_PAD = 10     -- top and bottom padding of the bottom band
local ART_GAP = 20      -- the picture stays visible between the two bands (32 with a class icon)
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
-- Raids (no picture in ForeverDungeonJournal or Naowh): the game's own art, first one this client
-- has wins (journal art of the modern client, then loading screens; Kalimdor's as the last resort).
local EJ = "Interface\\EncounterJournal\\"
local RAID_ART = {
  OnyxiasLair = { EJ .. "UI-EJ-LOREBG-OnyxiasLair", EJ .. "UI-EJ-BACKGROUND-OnyxiasLair", LS .. "LoadScreenOnyxiasLair",
    LS .. "LoadScreenOnyxia", LS .. "LoadScreenDustwallowMarsh", LS .. "LoadScreenKalimdor" },
  HyjalSummit = { EJ .. "UI-EJ-LOREBG-TheBattleforMountHyjal", EJ .. "UI-EJ-BACKGROUND-TheBattleforMountHyjal",
    EJ .. "UI-EJ-LOREBG-HyjalSummit", LS .. "LoadScreenHyjal", LS .. "LoadScreenCavernsTimeHyjal", EJ .. "UI-EJ-LOREBG-Firelands",
    LS .. "LoadScreenKalimdor2", LS .. "LoadScreenKalimdor" },
  BarrowDeeps = { EJ .. "UI-EJ-LOREBG-TheEmeraldNightmare", EJ .. "UI-EJ-BACKGROUND-TheEmeraldNightmare", LS .. "LoadScreenMoonglade",
    LS .. "LoadScreenHyjal", LS .. "LoadScreenKalimdor2", LS .. "LoadScreenKalimdor" },
}
-- the game's journal, when this client has its functions: the instance's own lore picture
local function JournalArt(d)
  if not (EJ_GetNumTiers and EJ_SelectTier and EJ_GetInstanceByIndex) then return nil end
  local want = { [d.n or ""] = true, [d.nf or ""] = true }
  local okN, nt = pcall(EJ_GetNumTiers)
  if not okN or type(nt) ~= "number" then return nil end
  -- selecting a tier moves the game's own Adventure Guide: put the player's tier back after
  local okC, before = false, nil
  if EJ_GetCurrentTier then okC, before = pcall(EJ_GetCurrentTier) end
  local found
  for tier = 1, nt do
    pcall(EJ_SelectTier, tier)
    for _, raid in ipairs({ true, false }) do
      for i = 1, 60 do
        local ok, id, name, _, bg, _, lore = pcall(EJ_GetInstanceByIndex, i, raid)
        if not ok or not id then break end
        if type(name) == "string" and want[name] then found = lore or bg; break end
      end
      if found then break end
    end
    if found then break end
  end
  if okC and type(before) == "number" then pcall(EJ_SelectTier, before) end
  return found
end
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
  if RAID_ART[key] or d.raid then
    if d.jart == nil then d.jart = JournalArt(d) or false end
    if d.jart and TrySet(tex, d.jart) then tex:SetTexCoord(0, 1, 0.1, 0.9); return true end
    for _, path in ipairs(RAID_ART[key] or {}) do
      if TrySet(tex, path) then
        if path:find("EncounterJournal", 1, true) then tex:SetTexCoord(0, 1, 0.1, 0.9) else tex:SetTexCoord(0.02, 0.98, 0.26, 0.74) end
        return true
      end
    end
  end
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

-- How well a dungeon suits you now, lower is better (the order of "at your level"):
--   an entrance inside the other faction's capital goes last;
--   then how far your level is from the middle of its range (a dungeon you are about to outlevel
--   is not the first idea);
--   then the trip: about one level per 1000 yards on your continent, six for another continent.
-- Without positions (no map data) only the level counts.
local ENEMY_CAPITAL = { Alliance = { [1454] = true, [1456] = true, [1458] = true, [1954] = true },
                        Horde = { [1453] = true, [1455] = true, [1457] = true, [1947] = true } }
function ns.PickerFit(k)
  local d = ns.D[k]
  if not d then return 9999 end
  local score = 0
  local side = UnitFactionGroup and UnitFactionGroup("player")
  local e = d.e
  if side and e and e.m and ENEMY_CAPITAL[side] and ENEMY_CAPITAL[side][e.m] then score = score + 1000 end
  local lv = UnitLevel("player") or 1
  if d.lvl and d.lvl[1] then
    local lo, hi = d.lvl[1], d.lvl[2] or d.lvl[1]
    score = score + math.abs(lv - (lo + hi) / 2)
  end
  if e and e.m and e.x and e.y and ns.World and ns.PlayerWorld then
    local okW, w = pcall(ns.World, e.m, e.x, e.y)
    local okP, pw = pcall(ns.PlayerWorld)
    if okW and okP and type(w) == "table" and type(pw) == "table" then
      if w[1] ~= pw[1] then score = score + 6
      else
        local dx, dy = (w[2] or 0) - (pw[2] or 0), (w[3] or 0) - (pw[3] or 0)
        score = score + math.min(6, math.sqrt(dx * dx + dy * dy) / 1000)
      end
    end
  end
  return score
end

-- "Conseillé pour toi": the first "at your level" card gets the badge only when its fit beats the
-- second one's by FIT_MARGIN (about two levels, or 2000 yards of trip): two close fits get none.
local FIT_MARGIN = 2
-- The badge's one-line reason: "De ton côté, à ton niveau, à ~12 min" (the GPS's trip time when it
-- finds one, else "close by").
function ns.PickerAdvisedWhy(k)
  local d = ns.D[k]
  local e = d and d.e
  local WP = ns.Writs and ns.Writs.WP
  local GPS = WP and WP.GPS
  if e and e.m and e.x and e.y and GPS and GPS.TripSummary then
    local ok, _, _, mins = pcall(GPS.TripSummary, e.m, e.x, e.y)
    if ok and type(mins) == "string" and mins ~= "" then return L.PICK_FIT_WHY:format(mins) end
  end
  return L.PICK_FIT_WHY0
end

local function LevelOK(d)
  local lv = UnitLevel("player")
  local lo, hi = d.lvl and d.lvl[1] or 1, d.lvl and d.lvl[2] or 60
  return lv >= lo - 4 and lv <= hi + 1
end

-- The picker's ticks are a draft: they change the running route only through the summary's
-- "start" (or StartGuide), never on their own when the window closes. Until the first tick the
-- picker shows the route's own choice; the first tick copies it, the copy is kept across a hide
-- and dropped when a guide starts.
local draft
local function Selected() return draft or {} end
local function Draft()
  if not draft then draft = {} end
  return draft
end
-- the running route's dungeons (shown "In progress" on their card, never ticked for it)
local function Running(k) return ns.route and ns.route.sel and ns.route.sel[k] and true or false end
-- one dungeon alone: its overview, where "Start the guide" replaces the running route
local function OpenOne(k)
  draft = nil
  if ns.ShowSummary then
    local left, top = p:GetLeft(), p:GetTop()
    local sum = ns.ShowSummary({ k })
    if sum then
      p:Hide()
      if left and top and sum.ClearAllPoints then sum:ClearAllPoints(); sum:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top) end
      return
    end
  end
  WLDTDB.sel = WLDTDB.sel or {}
  wipe(WLDTDB.sel); WLDTDB.sel[k] = true
  ns.StartGuide()
end
-- the draft's dungeons, in the picker's order
local function DraftKeys()
  local out, sel = {}, Selected()
  for _, k in ipairs(ns.ORDER or {}) do if sel[k] then out[#out + 1] = k end end
  return out
end
function ns.PickerResetDraft() draft = nil end
function ns.PickerSetDraft(t) draft = {}; for k, v in pairs(t or {}) do if v then draft[k] = true end end end
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

-- Search: lower case, accents dropped, so "zul farrak", "Mossmeld" or "geme" all find something.
local FOLD = { ["à"]="a", ["â"]="a", ["ä"]="a", ["á"]="a", ["ç"]="c", ["é"]="e", ["è"]="e", ["ê"]="e", ["ë"]="e",
  ["î"]="i", ["ï"]="i", ["í"]="i", ["ô"]="o", ["ö"]="o", ["ó"]="o", ["ù"]="u", ["û"]="u", ["ü"]="u", ["ú"]="u",
  ["ÿ"]="y", ["œ"]="oe", ["æ"]="ae", ["’"]="'", ["É"]="e", ["È"]="e", ["Ê"]="e", ["À"]="a", ["Ç"]="c", ["Î"]="i", ["Ô"]="o" }
local function Fold(t)
  t = tostring(t or "")
  t = t:gsub("[\194-\244][\128-\191]+", function(c) return FOLD[c] or c end)
  t = t:gsub("[A-Z]", string.lower)   -- ASCII only: a locale-aware lower() can break UTF-8
  return (t:gsub("[%s%-_:,%.']+", " "))
end
local function Query() return p and p.query and Fold(p.query):match("^%s*(.-)%s*$") or "" end
-- what a dungeon answers to: its names (both languages), short name, zone, quests and who gives them
local hay = {}
local function Haystack(k)
  if hay[k] then return hay[k] end
  local d = ns.D[k] or {}
  local parts = { k, d.n, d.nf, d.short, d.loc, ns.DName(k) }
  for _, qid in ipairs(d.q or {}) do
    local q = ns.Q[qid]
    if q then parts[#parts + 1] = q.n; parts[#parts + 1] = q.nf; parts[#parts + 1] = q.s and q.s.n end
  end
  local _, cls = UnitClass("player")
  for _, qid in ipairs(ns.DungeonQuests and (select(2, pcall(ns.DungeonQuests, k, cls))) or {}) do
    local q = ns.Q[qid]
    if q then parts[#parts + 1] = q.n; parts[#parts + 1] = q.nf; parts[#parts + 1] = q.s and q.s.n end
  end
  local out = {}
  for _, v in pairs(parts) do if v then out[#out + 1] = Fold(v) end end
  hay[k] = " " .. table.concat(out, " | ") .. " "
  return hay[k]
end
local function Matches(k, query)
  local h = Haystack(k)
  for word in query:gmatch("%S+") do
    if not h:find(word, 1, true) then return false end
  end
  return true
end
ns.PickerMatches = function(k, text) return Matches(k, Fold(text)) end
ns.PickerFold = Fold

-- icône de classe officielle (atlas des cercles de classe)
local function SetClassIcon(tex, cls)
  local c = CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[cls]
  if c then tex:SetTexture("Interface\\TargetingFrame\\UI-Classes-Circles"); tex:SetTexCoord(c[1], c[2], c[3], c[4]); tex:Show()
  else tex:Hide() end
end
ns.SetClassIcon = SetClassIcon

local Render

-- A card: the dungeon's picture, a dark band behind each block of text (the picture stays bright),
-- the name on top (up to 2 lines, beside the Overview button or under it when it needs the room),
-- the bottom band built from the text-structure pieces (DESIGN 3.21): the level line (body), then
-- the quests stat ("Quêtes rendues 5/6" and its thin bar) and, only when some wait on a prerequisite, a muted
-- line saying how many. Picked: accent border, accent tint and a filled check badge.
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
  -- the bottom band: a frame (no mouse: the card stays the one click target) holding the text
  -- stack, so its pieces are placed from the band's top whatever the card's height
  c.body = CreateFrame("Frame", nil, c)
  c.body:SetPoint("BOTTOMLEFT", 1, 1); c.body:SetPoint("BOTTOMRIGHT", -1, 1); c.body:SetHeight(30)
  c.body.wlWorld = true   -- text over the picture keeps a shadow
  -- darker than the top band: it carries the small muted words
  c.botBand = c:CreateTexture(nil, "ARTWORK", nil, 3); c.botBand:SetPoint("TOPLEFT", c.body, "TOPLEFT", 0, 0); c.botBand:SetPoint("BOTTOMRIGHT", c.body, "BOTTOMRIGHT", 0, 0)
  c.botBand:SetColorTexture(0, 0, 0, 0.80)   -- the muted words keep 4.5:1 over a bright picture
  c.stk = ns.TextStack(c.body)
  -- picked: the selected tint over the whole card (above the picture and the bands)
  c.selFill = c:CreateTexture(nil, "ARTWORK", nil, 5); c.selFill:SetPoint("TOPLEFT", 1, -1); c.selFill:SetPoint("BOTTOMRIGHT", -1, 1)
  c.selFill:SetColorTexture(T.selFill[1], T.selFill[2], T.selFill[3], T.selFill[4]); c.selFill:Hide()
  c.hl = Tex(c, "HIGHLIGHT", T.hoverFill); c.hl:SetAllPoints()
  c.press = Tex(c, "OVERLAY", T.pressFill); c.press:SetAllPoints(); c.press:Hide()
  c.selEdge = ns.Outline(c, T.accent, 0, "OVERLAY")
  -- picked: a filled accent check badge on the bottom band's top edge, right side. Filled and
  -- white, unlike the bare green check of a finished dungeon (top right, beside Overview)
  c.selBox = c.body:CreateTexture(nil, "OVERLAY", nil, 1); c.selBox:SetSize(18, 18)
  c.selBox:SetPoint("CENTER", c.body, "TOPRIGHT", -20, 0)
  c.selBox:SetColorTexture(T.accent[1], T.accent[2], T.accent[3], 1); c.selBox:Hide()
  c.selTick = c.body:CreateTexture(nil, "OVERLAY", nil, 2); c.selTick:SetSize(12, 12)
  ns.SetHDIcon(c.selTick, "check", T.fg); c.selTick:SetPoint("CENTER", c.selBox, "CENTER", 0, 0); c.selTick:Hide()
  -- the box to tick to combine dungeons into one route: always there, empty when not ticked
  c.chk = CreateFrame("Button", nil, c)
  c.chk:SetSize(26, 26); c.chk:SetPoint("CENTER", c.selBox, "CENTER", 0, 0)
  c.chk:SetFrameLevel((c:GetFrameLevel() or 1) + 3)
  c.chk.box = c.chk:CreateTexture(nil, "OVERLAY", nil, 0); c.chk.box:SetSize(18, 18); c.chk.box:SetPoint("CENTER")
  c.chk.box:SetColorTexture(0, 0, 0, 0.75)
  c.chk.edge = ns.Outline(c.chk, T.fg, 1, "OVERLAY")
  c.chk:SetScript("OnClick", function(self)
    local k = c.dkey; if not k then return end
    local d = Draft()
    d[k] = not d[k] or nil
    PlaySound(SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or 856)
    Render()
  end)
  c.chk:SetScript("OnEnter", function(self) ns.ShowTip(self, { L.PICK_CHK, L.PICK_CHK_TT }) end)
  c.chk:SetScript("OnLeave", ns.HideTip)
  -- text drawn over a picture keeps a shadow
  c.wlWorld = true
  -- the summary button at the card's top-right corner; the check of a finished dungeon left of
  -- it. A word, not the info icon: "info" only means neutral information (icon audit G1), and the
  -- check beside an info icon read as one cluster. A short word ("Résumé"): every name keeps its
  -- place beside it, so the names of one row line up
  c.ov = S.Button(c, L.OV_BTN, 0, 24, "secondary", function() if ns.ShowOverview then ns.ShowOverview(c.dkey) end end,
    function() return { L.OV_T, L.OV_CLICK } end)
  c.ov:SetPoint("TOPRIGHT", -6, -6)
  c.ov:SetFrameLevel((c:GetFrameLevel() or 1) + 3)
  c.doneMark = ns.Icon(c, "check", 14, "OVERLAY", T.ok); c.doneMark:SetPoint("RIGHT", c.ov, "LEFT", -2, 0)
  c.name = Text(c, ns.F.heading, T.fg, false, "SHADOW"); c.name:SetPoint("TOPLEFT", 12, -10)
  c.name:SetJustifyH("LEFT")
  c.cicon = c:CreateTexture(nil, "OVERLAY"); c.cicon:SetSize(20, 20); c.cicon:SetPoint("TOPLEFT", 12, -42)
  c.bigIcon = c:CreateTexture(nil, "ARTWORK", nil, 1); c.bigIcon:SetSize(40, 40); c.bigIcon:SetPoint("CENTER", 0, -2); c.bigIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92); c.bigIcon:Hide()
  c.dicon = c:CreateTexture(nil, "OVERLAY"); c.dicon:Hide()
  -- "Conseillé pour toi": an accent pill over the picture, under the top band (no mouse: the card
  -- stays the one click target; its tooltip says why)
  c.fitBadge = S.Pill(c, L.PICK_FIT, T.accentSoft)
  c.fitBadge.dark = c.fitBadge:CreateTexture(nil, "BACKGROUND", nil, -1); c.fitBadge.dark:SetAllPoints()
  c.fitBadge.dark:SetColorTexture(0, 0, 0, 0.75)
  c.fitBadge:SetFrameLevel((c:GetFrameLevel() or 1) + 2)
  c.fitBadge:Hide()
  c:SetScript("OnClick", function(self, btn)
    if btn == "RightButton" then
      if ns.ShowOverview then ns.ShowOverview(self.dkey) else ns.OpenQuests(self.dkey) end
      return
    end
    OpenOne(self.dkey)
  end)
  -- a double-click is two clicks: the first already opened the overview
  c:SetScript("OnMouseDown", function(self) self.press:Show() end)
  c:SetScript("OnMouseUp", function(self) self.press:Hide() end)
  c:SetScript("OnEnter", function(self)
    local d = ns.D[self.dkey]
    local n, done = Counts(self.dkey)
    local lines = { ns.DName(self.dkey) }
    if Running(self.dkey) then table.insert(lines, { L.PICK_RUNNING, T.ok[1], T.ok[2], T.ok[3] }) end
    if Selected()[self.dkey] then table.insert(lines, { L.PICK_PICKED, T.accentSoft[1], T.accentSoft[2], T.accentSoft[3] }) end
    if self.advised then
      table.insert(lines, { ns.PickerAdvisedWhy(self.dkey), T.accentSoft[1], T.accentSoft[2], T.accentSoft[3] })
    end
    for _, v in ipairs({ (GetLocale and GetLocale() == "frFR" and d.locf) or ns.T(d.loc) or "",
      ns.Plural(n, "PICK_QUESTS1", "PICK_QUESTS", n) .. "  ·  " .. ns.Plural(done, "PICK_DONE1", "PICK_DONE", done) }) do
      table.insert(lines, v)
    end
    if d.cq and d.home then table.insert(lines, L.CQ_IN:format(ns.DName(d.home))) end
    if d.ed then table.insert(lines, ns.T(d.ed)) end
    for _, k in ipairs(ns.KeyLines and ns.KeyLines(self.dkey) or {}) do table.insert(lines, k[1]) end
    table.insert(lines, L.PICK_CLICK)
    table.insert(lines, ns.ShowOverview and L.OV_RCLICK or L.PICK_RCLICK)
    table.insert(lines, L.PICK_CHK_TT)
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
  Dims()
  p:SetSize(PW, 600); p:SetPoint("CENTER"); p:SetFrameStrata("HIGH")
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
  -- search over every tab, whatever the level filter
  p.search = S.Input(p.tabBar, 168, { search = true, placeholder = L.PICK_SEARCH, onChange = function(t)
    p.query = t
    if p.sa then p.sa:ScrollTo(0, true) end
    Render()
  end, onEnter = function() end })
  p.search:SetHeight(24)
  p.search:SetPoint("RIGHT", p.filter, "LEFT", -8, 0)
  p.search:SetScript("OnEscapePressed", function(self)
    if (self:GetText() or "") ~= "" then self:SetText(""); p.query = ""; Render() else self:ClearFocus() end
  end)
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
    local keys = DraftKeys()
    -- only stale keys ticked (a dungeon no longer in the list): nothing to start, the route stays
    if #keys == 0 then return end
    local sum = ns.ShowSummary and ns.ShowSummary(keys)
    if sum then
      p:Hide()
      if left and top and sum.ClearAllPoints then
        sum:ClearAllPoints(); sum:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
      end
      return
    end
    -- no summary: the draft becomes the route's choice here
    WLDTDB.sel = WLDTDB.sel or {}
    wipe(WLDTDB.sel)
    for _, k in ipairs(keys) do WLDTDB.sel[k] = true end
    ns.StartGuide()
  end, function() return { p.go:GetText(), L.SUM_PICK_GO_TT } end)
  p.go:SetPoint("RIGHT", 0, 0)
  p.go:SetDisabledReason(L.PICK_GO_WHY)
  p.none = S.Button(p.foot, L.PICK_NONE, 0, 28, "secondary", function() wipe(Draft()); Render() end)
  p.none:SetPoint("RIGHT", p.go, "LEFT", -8, 0)
  p.selText = Text(p.foot, ns.F.body, T.text); p.selText:SetPoint("LEFT", 0, 0); p.selText:SetPoint("RIGHT", p.none, "LEFT", -12, 0)
  p.selText:SetJustifyV("MIDDLE")
  ns.ClampLabel(p.selText, nil, p.foot)
  tinsert(UISpecialFrames, "WLDTPicker")
  if ns.RegisterWindow then ns.RegisterWindow(p) end
  -- the workspace size rule (DESIGN 3.1): size from the screen, a grip, the size kept
  if S.MakeResizable then
    S.MakeResizable(p, "workspace", WLDTDB, "pick")
    p.OnResize = function() Render() end
  end
  p:Hide()
end

-- Fills one card for dungeon `k` in section `sec` and returns the card height it needs.
local function FillCard(c, k, sec, advised)
  local d = ns.D[k]
  c.section, c.dkey = sec, k
  c.advised = advised or nil
  Art(c.art, d, c)
  c.dicon:Hide()
  if d.cq then SetClassIcon(c.cicon, (d.cq:match("^[^,]+"))) else c.cicon:Hide() end
  local soon = d.up and time() < d.up
  local n, done = Counts(k)
  local finished = n > 0 and done >= n
  c.doneMark:SetShown(finished)
  -- the name: 2 lines beside the Overview button (and the finished check); when it needs more
  -- there, it goes under the button at the card's full width, still 2 lines at most
  c.name:SetText(ns.DName(k))
  local line = ns.F.heading
  local ovW = num(c.ov:GetWidth()) or 64
  local besideW = CW - 12 - 6 - ovW - 8 - (finished and 16 or 0)
  local nameY, nameW = 10, besideW
  local needH = ns.FitText(c.name, 0, besideW, c)
  if besideW < 64 or needH > 2 * line + 4 then nameY, nameW = 6 + 24 + 6, CW - 24 end
  c.name:ClearAllPoints(); c.name:SetPoint("TOPLEFT", 12, -nameY)
  local nameH = ns.FitText(c.name, 2, nameW, c)
  if nameH < line then nameH = line + 3 end
  local topH = math.max(36, math.ceil(nameY + nameH + 8))
  c.topBand:SetHeight(topH)
  c.cicon:ClearAllPoints(); c.cicon:SetPoint("TOPLEFT", 12, -(topH + 6))
  -- the advised badge: under the top band, right of a class icon
  local gap = d.cq and 32 or ART_GAP
  if advised then
    c.fitBadge:Set(L.PICK_FIT, T.accentSoft)
    c.fitBadge:ClearAllPoints(); c.fitBadge:SetPoint("TOPLEFT", d.cq and (12 + 20 + 6) or 12, -(topH + 7))
    c.fitBadge:Show()
    gap = math.max(gap, 32)
  else c.fitBadge:Hide() end
  -- the bottom band: level (and raid size / opening date), then the quests stat
  local later = sec == "later" or sec == "below"
  local dateTop = soon and n == 0   -- a coming raid without quests: its date takes the quests' place
  local parts = {}
  if d.lvl and d.lvl[1] then
    local lo, hi2 = d.lvl[1], d.lvl[2] or d.lvl[1]
    parts[#parts + 1] = lo == hi2 and L.PICK_LV1:format(lo) or L.PICK_LV:format(lo, hi2)
  end
  if d.raid then parts[#parts + 1] = L.RAID .. (d.size and (" · " .. L.PICK_SIZE:format(d.size)) or "") end
  if soon and not dateTop then parts[#parts + 1] = L.PICK_OPENS:format(date(L.PICK_DATE, d.up)) end
  local st = c.stk
  st:Begin(11, BAND_PAD, CW - 24)
  -- the level line is body (13): it is the first thing read, above the 12 px stat row
  st:Body(table.concat(parts, "  ·  "), later and T.muted or T.text)
  if n > 0 then
    local npre = (n > done) and PreCount(k) or 0
    st:Stat(L.PICK_STAT, done, n, { sub = npre > 0 and ns.Plural(npre, "OV_CARD_PRE1", "OV_CARD_PRE", npre) or nil,
      subSize = SMALL and ns.F.label or nil })
  else
    st:Body(dateTop and (L.PICK_SOON .. " · " .. date(L.PICK_DATE, d.up)) or L.PICK_NOQ, later and T.muted or T.text)
  end
  -- what it has for your gear (Naowh's BiS, WL Helper's upgrades): one gold line
  local gtxt = ns.DungeonGearText and ns.DungeonGearText(k)
  if gtxt then st:Body(gtxt, T.gold) end
  local bandH = BAND_PAD + st:End() + BAND_PAD
  c.body:SetHeight(bandH)
  c.bandH, c.topH = bandH, topH
  -- picked: accent border, tint and the filled check badge
  local sel = Selected()[k] and true or false
  c.sel = sel
  c.selEdge(sel and T.accent or T.ok, (sel or Running(k)) and 1 or 0)
  c.selFill:SetShown(sel); c.selBox:SetShown(sel); c.selTick:SetShown(sel)
  if c.chk then c.chk.box:SetShown(not sel); c.chk:Show() end
  -- later, below, no quest, coming soon: greyed; to do and done: the picture as it is
  c.art:SetDesaturated(later or sec == "noq" or sec == "upcoming")
  c.shade:SetColorTexture(0, 0, 0, (sec == "todo" or sec == "done" or sel) and 0.12 or 0.45)
  return 1 + topH + gap + bandH + 1
end

Render = function()
  if not p then return end
  ns.EnsureClassCards()
  local S = SW()
  -- Sections, in this order: to do at your level, later (too high), below, done, coming soon,
  -- then (All) no quest. "My level" shows the first, done and coming soon; "All" every section.
  local tab = CurTab()
  local query = Query()
  local searching = query ~= ""
  local secs = { todo = {}, later = {}, below = {}, done = {}, noq = {}, upcoming = {} }
  local list = {}
  local tooHigh = function(d) return d.lvl and d.lvl[1] and UnitLevel("player") < d.lvl[1] - 4 end
  for _, k in ipairs(ns.ORDER) do
    local d = ns.D[k]
    local inTab = searching and (not d.cq or ClassMatch(d)) and Matches(k, query)
      or (not searching and TabOf(d) == tab and (tab ~= "cls" or ClassMatch(d)))
    if inTab then
      local n, done = Counts(k)
      local sec
      if n == 0 then sec = (d.up and time() < d.up) and "upcoming" or (tab == "raid" and "todo" or "noq")
      elseif done >= n then sec = "done"
      elseif tooHigh(d) then sec = "later"
      elseif not LevelOK(d) then sec = "below"
      else sec = "todo" end
      local show = searching or WLDTDB.pickAll or sec == "todo" or sec == "done" or sec == "upcoming"
      if show then table.insert(secs[sec], k); table.insert(list, k) end
    end
  end
  p.tabBar:Update()
  p.filter:Update()
  -- the window's width (the screen's rule or the player's drag): columns and card size follow it
  Dims()
  for _, c in ipairs(p.cards or {}) do c:SetWidth(CW) end
  local contentW = PW - 2 * PAD
  if searching then p.hint:SetText(L.PICK_HINT_SEARCH:format(p.query))
  else p.hint:SetText(tab == "cls" and L.PICK_HINT_CLS or tab == "raid" and L.PICK_HINT_RAID or L.PICK_HINT) end
  local hintH = ns.FitText(p.hint, 0, contentW, p)
  local top = HEADER + 1 + 32 + 12 + hintH + 12
  local function byLevel(a, b)
    local la, lb = ns.D[a].lvl and ns.D[a].lvl[1] or 0, ns.D[b].lvl and ns.D[b].lvl[1] or 0
    if la ~= lb then return la < lb end
    return a < b
  end
  -- "at your level": the best fit first (ns.PickerFit: your side's entrance, your level, close by)
  local fit = {}
  local function byFit(a, b)
    fit[a] = fit[a] or ns.PickerFit(a); fit[b] = fit[b] or ns.PickerFit(b)
    if fit[a] ~= fit[b] then return fit[a] < fit[b] end
    return byLevel(a, b)
  end
  -- first pass: fill every card and take the tallest one's need as the card height
  local SECS = { { "todo", L.SEC_TODO }, { "later", L.SEC_LATER }, { "below", L.SEC_BELOW }, { "done", L.SEC_DONE }, { "upcoming", L.SEC_UP }, { "noq", L.SEC_NOQ } }
  local i, need = 0, CH_MIN
  for _, s in ipairs(SECS) do
    local keys = secs[s[1]]
    table.sort(keys, s[1] == "todo" and byFit or byLevel)
    -- the first "at your level" card is advised when it clearly beats the second (FIT_MARGIN)
    local advised
    if s[1] == "todo" and not searching and tab ~= "raid" and #keys >= 2 then
      local f1, f2 = fit[keys[1]] or ns.PickerFit(keys[1]), fit[keys[2]] or ns.PickerFit(keys[2])
      if f1 < 1000 and f2 - f1 >= FIT_MARGIN then advised = keys[1] end
    end
    if s[1] == "todo" then p.advised = advised end
    for _, k in ipairs(keys) do
      i = i + 1
      local c = p.cards[i] or MakeCard(p.grid); p.cards[i] = c
      need = math.max(need, FillCard(c, k, s[1], k == advised))
    end
  end
  CH = math.ceil(need)
  -- second pass: section headers (DESIGN 3.10, as in every other window: 13 fg, the count 11
  -- muted, a 1 px rule) and the cards under them
  p.heads = p.heads or {}
  for _, hd in ipairs(p.heads) do hd:Hide() end
  local y, hi = 0, 0
  i = 0
  for _, s in ipairs(SECS) do
    local keys = secs[s[1]]
    if #keys > 0 then
      hi = hi + 1
      local hd = p.heads[hi] or S.SectionHeader(p.grid, s[2], #keys); p.heads[hi] = hd
      hd:Set(s[2], #keys)
      hd.secText, hd.n = s[2], #keys
      -- 16 above a section header (8 left by the cards above + 8), 0 above the first one
      if hi > 1 then y = y + 8 end
      hd.top = y
      hd:ClearAllPoints(); hd:SetPoint("TOPLEFT", p.grid, "TOPLEFT", 0, -y); hd:SetWidth(contentW); hd:Show()
      y = y + 32 + 8
      for j in ipairs(keys) do
        i = i + 1
        local c = p.cards[i]
        local col, row = (j - 1) % COLS, math.floor((j - 1) / COLS)
        c:SetSize(CW, CH)
        c:ClearAllPoints(); c:SetPoint("TOPLEFT", p.grid, "TOPLEFT", col * (CW + GAP), -(y + row * (CH + GAP)))
        c:Show()
      end
      y = y + math.ceil(#keys / COLS) * (CH + GAP) - GAP + 8
    end
  end
  for j = i + 1, #p.cards do p.cards[j]:Hide() end
  if #list == 0 then
    local eh = searching and p.empty:Set(L.PICK_EMPTY_SEARCH_T:format(p.query), L.PICK_EMPTY_SEARCH)
      or (tab == "cls") and p.empty:Set(L.PICK_EMPTY_CLS_T, L.PICK_EMPTY_CLS) or p.empty:Set(L.PICK_EMPTY_T, L.PICK_EMPTY)
    p.empty:Show()
    y = 24 + eh + 24
  else p.empty:Hide() end
  local gridH = math.max(10, y)
  -- a workspace window keeps its height (DESIGN 0.4): the grid scrolls inside, the footer at the bottom
  local footH = 12 + 32 + PAD
  local _, winH = WinSize(p, "workspace")
  local viewH = math.max(160, (winH or ScreenCap()) - top - footH)
  p.sa:ClearAllPoints()
  p.sa:SetPoint("TOPLEFT", PAD, -top); p.sa:SetPoint("TOPRIGHT", -PAD, -top); p.sa:SetHeight(viewH)
  p.grid:SetWidth(contentW)
  p.sa:SetContentHeight(gridH)
  p.foot:ClearAllPoints()
  p.foot:SetPoint("TOPLEFT", p.sa, "BOTTOMLEFT", 0, -12); p.foot:SetPoint("TOPRIGHT", p.sa, "BOTTOMRIGHT", 0, -12)

  local nSel = SelCount()
  p.selText:SetText(nSel == 0 and L.PICK_SEL0 or ns.Plural(nSel, "PICK_SEL1", "PICK_SEL", nSel))
  -- no pin: this button opens the summary, it starts no GPS (the pin means GPS, icon audit G1)
  -- the count is already in the footer ("12 donjons choisis"): the button says what it does
  p.go:SetText(nSel >= 2 and L.PICK_GO_N:format(nSel) or L.PICK_GO)
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
-- A panel window (DESIGN 3.1: its width from the screen, the width can be dragged and is kept, the
-- height fits the list). QW and QTXT_W follow its width at every render.
local QROWS, QH, QW = 22, 28, 560
local QSTATUS = 130                       -- the status column ("Prerequisites done" at 11 px fits)
local QLV_W = 40                          -- the level column, with its unit ("niv. 30")
local QTXT_X = 32 + QLV_W + 4
local QTXT_W = (QW - 16) - QTXT_X - 8 - QSTATUS - 8   -- the quest name: up to the status column
local function QDims()
  QW = WinSize(qp, "panel")
  QTXT_W = (QW - 16) - QTXT_X - 8 - QSTATUS - 8
end
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
    row.lvl = Text(row, ns.F.meta, T.muted); row.lvl:SetPoint("LEFT", 32, 0); row.lvl:SetWidth(QLV_W); row.lvl:SetJustifyV("MIDDLE")
    -- the prerequisite status, right-aligned in a fixed column: none, N, done, level needed
    row.status = Text(row, ns.F.meta, T.muted); row.status:SetPoint("RIGHT", -8, 0); row.status:SetWidth(QSTATUS)
    row.status:SetJustifyH("RIGHT"); row.status:SetJustifyV("MIDDLE")
    ns.ClampLabel(row.status, nil, row)
    -- the name wraps to 2 lines; the row grows with it
    row.txt = Text(row, ns.F.label, T.fg); row.txt:SetPoint("LEFT", QTXT_X, 0); row.txt:SetWidth(QTXT_W); row.txt:SetJustifyV("MIDDLE")
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
      -- the chain in order, one line per quest with its state in words, the same four words as
      -- everywhere (To take / In your log / Ready to turn in / Turned in): no dots to decode
      local pre = ns.QuestPreInfo and ns.QuestPreInfo(self.qid)
      if pre and pre.total > 0 then
        table.insert(lines, { L.OV_CHAIN_TT, T.fg[1], T.fg[2], T.fg[3] })
        for i, pid in ipairs(pre.chain) do
          local s = pre.states[i]
          local word = (s == "done" and L.S_DONE) or (s == "ready" and L.S_READY) or (s == "on" and L.CL_HAVE) or L.S_NONE
          -- "to take" is a normal state, not an alert: gold, like the tracker's take line
          local wc = (s == "done" and T.muted) or (s == "ready" and T.ok) or (s == "on" and T.fg) or T.gold
          local pq = ns.Q[pid] or {}
          -- the quest's level in the summary's words ("niv. 30")
          local txt = ns.QName(pid) .. " · " .. Hex(wc) .. word .. "|r" .. (pq.l and (" · " .. L.PICK_QLV:format(pq.l)) or "")
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
  if S.MakeResizable then
    qp.minH = 120
    S.MakeResizable(qp, "panel", WLDTDB, "pickQuests")
    qp.OnResize = function() if qp.dkey then ns.OpenQuests(qp.dkey, true) end end
  end
  qp:Hide()
end

function ns.OpenQuests(dkey, keep)
  if not qp then BuildQuests() end
  local _, cls = UnitClass("player")
  qp.dkey = dkey
  qp.title:SetText(L.PICK_CUSTOM_T:format(ns.DName(dkey))); qp.hint:SetText(L.PICK_CUSTOM_H)
  QDims()
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
      row.lvl:SetText(q.l and L.PICK_QLV:format(q.l) or "")
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
      row.txt:SetWidth(QTXT_W)
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
