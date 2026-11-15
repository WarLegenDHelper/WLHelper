-- Résumé d'un ou plusieurs donjons : le premier écran quand tu lances une route depuis le choix des
-- donjons (« Lancer la route »), et la vue d'ensemble d'un donjon (bouton de la carte, clic droit,
-- bouton du guide). En haut : l'image, le nom, les niveaux, l'entrée (GPS), la clé, et le total de
-- ce que tu as coché (quêtes, XP, argent, objets) qui suit tes coches. Puis une ligne par quête :
-- une case à cocher, son XP, son argent, ses récompenses, son état, ses pastilles (élite, chaîne,
-- autre donjon, niveau trop haut) ; une chaîne se déplie pour montrer chaque maillon, son XP, son
-- état et où il se fait. En groupe : une colonne par membre (synchronisée par WL Helper, ou remplie
-- par les réponses du jeu après un partage), un bouton « Partager » et un verdict sur une ligne.
-- En bas : « Lancer la route » (avec les quêtes cochées), ou « Retour à la route » quand la route de
-- ces donjons tourne déjà (les coches l'ont déjà mise à jour), et « Fermer ».
-- Design system: docs/DESIGN.md (640 px window sized to its content, scroll past 80 % of the screen).
local ADDON, ns = ...
local L, T = ns.L, ns.T_

-- =====================================================================
--  Strings (added to the root locale tables; Locale.lua keeps the older OV_ keys)
-- =====================================================================
local STR = {
  fr = {
    SUM_T = "Résumé", SUM_ROUTE_T = "Résumé de la route", SUM_DG1 = "%d donjon", SUM_DG = "%d donjons",
    SUM_SEL = "Ta sélection : %s", SUM_SEL0 = "Rien de coché : coche au moins une quête à faire.",
    SUM_Q1 = "%d quête", SUM_Q = "%d quêtes", SUM_XP = "%s XP", SUM_ITEMS1 = "%d objet", SUM_ITEMS = "%d objets",
    SUM_CHAIN_LINE = "Chaîne de %d quêtes : %s XP au total", SUM_CHAIN_PILL = "Chaîne (%d quêtes)",
    SUM_ELITE = "Élite", SUM_ELITE_TT = "Un objectif vise un monstre élite : viens en groupe.",
    SUM_OTHER = "Autre donjon : %s", SUM_OTHER_TT = "Un maillon de la chaîne se fait dans %s.",
    SUM_HIGH = "Niveau trop haut", SUM_HIGH_TT = "La chaîne monte jusqu'au niveau %d, plus de 5 niveaux au-dessus de toi : décochée par défaut.",
    SUM_ST_NONE = "À prendre", SUM_ST_ON = "Dans ton journal", SUM_ST_READY = "Prête à rendre", SUM_ST_DONE = "Rendue",
    SUM_TICK_OFF = "Clic : retirer cette quête de la route", SUM_TICK_ON = "Clic : remettre cette quête dans la route",
    SUM_TICK_OFF_CH = "Clic : retirer cette quête et ses %d prérequis de la route",
    SUM_TICK_ON_CH = "Clic : remettre cette quête et ses %d prérequis dans la route",
    SUM_EXPAND = "Clic : voir chaque quête de la chaîne", SUM_COLLAPSE = "Clic : replier la chaîne",
    SUM_FDJ = "Note de ForeverDungeonJournal", SUM_LFD = "Étapes (LibForeverData)",
    SUM_GO = "Lancer la route", SUM_GO_TT = "Clic : construire la route avec les quêtes cochées",
    SUM_GO_TT1 = "Clic : lancer la route sur ce donjon seul, avec les quêtes cochées (remplace tes donjons cochés)",
    SUM_GO_WHY = "Coche au moins une quête à faire.", SUM_CLOSE = "Fermer", SUM_CLOSE_TT = "Clic : fermer le résumé sans lancer la route",
    SUM_SHARE = "Partager", SUM_SHARED = "Partagée", SUM_SHARE_TT = "Clic : partager « %s » avec le groupe",
    SUM_SHARE_ALL = "Tout partager", SUM_SHARE_ALL_TT = "Clic : partager avec le groupe les quêtes cochées de ton journal, une toutes les 1,5 s",
    SUM_SHARE_WHY = "Aucune quête cochée de ton journal ne se partage.", SUM_SHARING = "Partage en cours",
    SUM_GROUP = "Groupe", SUM_NOQ = "Aucune quête pour toi dans ce donjon.",
    SUM_G_ON = "L'a", SUM_G_READY = "Prête", SUM_G_DONE = "Faite", SUM_G_TAKE = "À prendre", SUM_G_PRE = "Prérequis",
    SUM_G_LOW = "Niveau bas", SUM_G_NA = "Impossible", SUM_G_INVALID = "Pas éligible", SUM_G_DECLINED = "Refusée",
    SUM_G_FULL = "Journal plein", SUM_G_BUSY = "Indisponible", SUM_G_FAR = "Trop loin", SUM_G_SENT = "Envoyée", SUM_G_UNKNOWN = "?",
    SUM_G_PRE_TT = "Il lui manque : %s", SUM_G_UNKNOWN_TT = "%s n'a pas WL Helper : partage la quête, la réponse du jeu remplira cette case.",
    SUM_G_SENT_TT = "Quête envoyée : en attente de la réponse de %s.", SUM_G_PUSH_TT = "D'après la réponse du jeu au partage.",
    SUM_G_NA_TT = "Cette quête n'est pas pour sa classe, sa faction ou sa race.",
    SUM_V_ALL1 = "%d membre sur %d a toutes les quêtes", SUM_V_ALL = "%d membres sur %d ont toutes les quêtes",
    SUM_V_TAKE = "%s doit en prendre %d", SUM_V_ME = "tu dois en prendre %d", SUM_V_PRE = "%s attend un prérequis (%s)",
    SUM_V_NOHELPER = "%s n'a pas WL Helper", SUM_V_WAIT = "réponse de %s en attente", SUM_V_CANT = "%s ne peut pas en prendre %d",
    SUM_G_WAIT = "En attente", SUM_G_WAIT_TT = "%s a WL Helper : sa réponse n'est pas encore arrivée.",
    SUM_BACK = "Retour à la route", SUM_BACK_TT = "Clic : revenir au guide. Tes coches ont déjà mis la route à jour.",
    SUM_OTHER_SHORT = "Autre donjon", SUM_RW_MORE = "Autres récompenses",
    SUM_PICK_GO_TT = "Clic : voir le résumé des quêtes (XP, récompenses, chaînes, groupe) avant de lancer la route",
  },
  en = {
    SUM_T = "Summary", SUM_ROUTE_T = "Route summary", SUM_DG1 = "%d dungeon", SUM_DG = "%d dungeons",
    SUM_SEL = "Your selection: %s", SUM_SEL0 = "Nothing ticked: tick at least one quest to do.",
    SUM_Q1 = "%d quest", SUM_Q = "%d quests", SUM_XP = "%s XP", SUM_ITEMS1 = "%d item", SUM_ITEMS = "%d items",
    SUM_CHAIN_LINE = "Chain of %d quests: %s XP in all", SUM_CHAIN_PILL = "Chain (%d quests)",
    SUM_ELITE = "Elite", SUM_ELITE_TT = "An objective targets an elite: bring a group.",
    SUM_OTHER = "Other dungeon: %s", SUM_OTHER_TT = "One link of the chain happens in %s.",
    SUM_HIGH = "Level too high", SUM_HIGH_TT = "The chain goes up to level %d, more than 5 levels above you: unticked by default.",
    SUM_ST_NONE = "To take", SUM_ST_ON = "In your log", SUM_ST_READY = "Ready to turn in", SUM_ST_DONE = "Turned in",
    SUM_TICK_OFF = "Click: leave this quest out of the route", SUM_TICK_ON = "Click: put this quest back in the route",
    SUM_TICK_OFF_CH = "Click: leave this quest and its %d prerequisites out of the route",
    SUM_TICK_ON_CH = "Click: put this quest and its %d prerequisites back in the route",
    SUM_EXPAND = "Click: show each quest of the chain", SUM_COLLAPSE = "Click: fold the chain",
    SUM_FDJ = "Note from ForeverDungeonJournal", SUM_LFD = "Steps (LibForeverData)",
    SUM_GO = "Start the route", SUM_GO_TT = "Click: build the route with the ticked quests",
    SUM_GO_TT1 = "Click: start the route with this dungeon only and the ticked quests (replaces your picked dungeons)",
    SUM_GO_WHY = "Tick at least one quest to do.", SUM_CLOSE = "Close", SUM_CLOSE_TT = "Click: close the summary without starting the route",
    SUM_SHARE = "Share", SUM_SHARED = "Shared", SUM_SHARE_TT = "Click: share \"%s\" with the group",
    SUM_SHARE_ALL = "Share all", SUM_SHARE_ALL_TT = "Click: share the ticked quests of your log with the group, one every 1.5 s",
    SUM_SHARE_WHY = "No ticked quest in your log can be shared.", SUM_SHARING = "Sharing",
    SUM_GROUP = "Group", SUM_NOQ = "No quest for you in this dungeon.",
    SUM_G_ON = "Has it", SUM_G_READY = "Ready", SUM_G_DONE = "Done", SUM_G_TAKE = "To take", SUM_G_PRE = "Prerequisite",
    SUM_G_LOW = "Level low", SUM_G_NA = "Can't take", SUM_G_INVALID = "Not eligible", SUM_G_DECLINED = "Declined",
    SUM_G_FULL = "Log full", SUM_G_BUSY = "Busy", SUM_G_FAR = "Too far", SUM_G_SENT = "Sent", SUM_G_UNKNOWN = "?",
    SUM_G_PRE_TT = "Missing link: %s", SUM_G_UNKNOWN_TT = "%s doesn't have WL Helper: share the quest and the game's answer fills this cell.",
    SUM_G_SENT_TT = "Quest sent: waiting for %s's answer.", SUM_G_PUSH_TT = "From the game's answer to the share.",
    SUM_G_NA_TT = "This quest is not for their class, faction or race.",
    SUM_V_ALL1 = "%d of %d members has every quest", SUM_V_ALL = "%d of %d members have every quest",
    SUM_V_TAKE = "%s needs to take %d", SUM_V_ME = "you need to take %d", SUM_V_PRE = "%s is missing a prerequisite (%s)",
    SUM_V_NOHELPER = "%s doesn't have WL Helper", SUM_V_WAIT = "waiting for %s's reply", SUM_V_CANT = "%s can't take %d",
    SUM_G_WAIT = "Waiting", SUM_G_WAIT_TT = "%s has WL Helper: their reply has not arrived yet.",
    SUM_BACK = "Back to the route", SUM_BACK_TT = "Click: go back to the guide. Your ticks have already updated the route.",
    SUM_OTHER_SHORT = "Other dungeon", SUM_RW_MORE = "More rewards",
    SUM_PICK_GO_TT = "Click: see the quests' summary (XP, rewards, chains, group) before starting the route",
  },
}
do
  local S = ns.LOCALE_TABLES
  if S then
    for lang, t in pairs(STR) do
      S[lang] = S[lang] or {}
      for k, v in pairs(t) do if S[lang][k] == nil then S[lang][k] = v end end
    end
  end
end

-- =====================================================================
--  Sizes (design system: window 640, inset 16, rows 8 / 32, pills 18, group cells 68)
-- =====================================================================
local W, PAD = 640, 16
local CW = W - 2 * PAD          -- content width
local HERO_H, HERO_H_MULTI = 96, 72
local ROW_GAP = 4
local TX = 32                   -- text column of a row (after the check box)
local CELLW, MAXCOLS = 68, 4    -- group columns
local MAX_REWARDS = 8
local HIGH_GAP = 5              -- a chain more than 5 levels above the player is unticked by default

local function SW()
  local S = ns.Writs and ns.Writs.S
  if not S then error("WL Helper: Writs/Style.lua missing") end
  return S
end
local function secret(v) return issecretvalue ~= nil and issecretvalue(v) end
local function num(v) return type(v) == "number" and not secret(v) and v or nil end
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
-- 38 900 (French, a no-break space: a wrapped line never breaks inside the number) / 38,900
local function Big(n)
  local s = tostring(math.floor((n or 0) + 0.5))
  local sep = ns.lang == "fr" and "\194\160" or ","
  local k
  repeat s, k = s:gsub("^(%-?%d+)(%d%d%d)", "%1" .. sep .. "%2") until k == 0
  return s
end
ns.BigNumber = Big
local function SetOn(b, on) if on then b:Enable() else b:Disable() end end
local function Lib()
  local lib = _G.LibForeverData
  return (type(lib) == "table" and type(lib.Get) == "function") and lib or nil
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
local function LowLevel(log, q, st, pre, lvl)
  if st ~= "none" then return nil end
  local need = q.r
  if pre.nextPid then
    local pq = ns.Q[pre.nextPid]
    if pq and ns.State(log, pre.nextPid) ~= "none" then return nil end
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

local function at(l, fallback) if l and l.m and l.x and l.y then return { l.m, l.x, l.y, l.n or fallback } end end
-- Where one quest's next action is: its giver, its outside objective, its turn-in.
local function PointOf(log, qid, q, st)
  if st == "none" then return at(q.s, ns.QName(qid)) end
  if st == "ready" then return at(q.f, ns.QName(qid)) end
  if st == "on" then
    local o = OutsideLeft(log, qid, q)
    return o and at(o.w, o.n)
  end
end
-- The point the quest's GPS leads to: the next prerequisite first, then the quest itself.
local function PointFor(log, qid, q, st, pre)
  if pre.nextPid then
    local pq = ns.Q[pre.nextPid]
    return pq and PointOf(log, pre.nextPid, pq, QState(log, pre.nextPid)) or nil
  end
  return PointOf(log, qid, q, st)
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

local function ObjText(q) return (ns.lang == "fr" and q.of) or ns.T(q.oe) end

-- Rewards: item ids read live from LibForeverData when it is loaded; else the item names of the data.
local rewardCache = {}
local function Rewards(qid, q)
  if rewardCache[qid] then return rewardCache[qid] end
  local out = {}
  local lib = Lib()
  if lib and type(lib.Quest) == "function" and qid > 0 then
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
  rewardCache[qid] = out
  return out
end
-- How many items the quest gives you (one for a reward of your choice).
local function ItemCount(qid, q)
  local n, choice = 0, false
  for _, rw in ipairs(Rewards(qid, q)) do if rw.choice then choice = true else n = n + 1 end end
  return n + (choice and 1 or 0)
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

-- XP and money of one quest: the data first, LibForeverData (live) when the data has none.
local function LibQuest(qid)
  local lib = Lib()
  if not (lib and qid > 0) then return nil end
  local ok, rec = pcall(lib.Get, "quest", qid)
  return ok and type(rec) == "table" and rec or nil
end
local function QuestXP(qid)
  local q = ns.Q[qid]
  if q and num(q.xp) then return q.xp end
  local rec = LibQuest(qid)
  return rec and num(rec.xp) or 0
end
-- "1g 80s", "65s", "7s  •  Gadgetzan +100": the money part only, in copper
local function QuestMoney(qid)
  local q = ns.Q[qid]
  if q and type(q.rw) == "string" then
    local seg = q.rw:match("^([%dgsc ]+)")
    local c = 0
    if seg then
      for n, u in seg:gmatch("(%d+)([gsc])") do
        n = tonumber(n)
        c = c + (u == "g" and n * 10000 or u == "s" and n * 100 or n)
      end
    end
    if c > 0 then return c end
    return 0
  end
  local rec = LibQuest(qid)
  return rec and num(rec.money) and rec.money > 0 and rec.money or 0
end
ns.QuestMoney, ns.QuestXP = QuestMoney, QuestXP

local function Money(c)
  local S = SW()
  if S.Money then return S.Money(c) end
  return tostring(c)
end

-- Elite: an objective's target is elite (rank 1 or 2), read live from LibForeverData; else the
-- data's own flags (q.elite, o.elite).
local eliteCache = {}
local function IsElite(qid, q)
  if eliteCache[qid] ~= nil then return eliteCache[qid] end
  local res = q.elite and true or false
  for _, o in ipairs(q.o or {}) do if o.elite then res = true end end
  local lib = Lib()
  if not res and lib and qid > 0 then
    local rec = LibQuest(qid)
    local function rank(id)
      local ok, n = pcall(lib.Get, "npc", id)
      return ok and type(n) == "table" and num(n.rank) or nil
    end
    for _, ob in ipairs(rec and type(rec.objectives) == "table" and rec.objectives or {}) do
      if ob.kind == "npc" and ob.target then
        local r = rank(ob.target)
        if r == 1 or r == 2 then res = true end
      elseif ob.kind == "item" and ob.target then
        -- an item dropped only by elites (the first three sources)
        local ok, it = pcall(lib.Get, "item", ob.target)
        local drops = ok and type(it) == "table" and it.npcDrops
        if type(drops) == "table" and #drops > 0 then
          local all = true
          for i = 1, math.min(3, #drops) do local r = rank(drops[i]); if not (r == 1 or r == 2) then all = false end end
          if all then res = true end
        end
      end
      if res then break end
    end
  end
  eliteCache[qid] = res
  return res
end

-- A note of ForeverDungeonJournal about a quest, read live when that addon is loaded (credited).
local function FDJDetails(qid)
  if not (ns.IsLoaded and ns.IsLoaded("ForeverDungeonJournal")) then return nil end
  local F = _G.ForeverDungeonJournal_NS or _G.FDJ
  local det = type(F) == "table" and type(F.QUEST_PREREQ_DETAILS) == "table" and F.QUEST_PREREQ_DETAILS[qid]
  return type(det) == "table" and det or nil
end
local function str(t) return type(t) == "string" and not secret(t) and t ~= "" and t or nil end
-- its note (or objective), then its warning when it has one
local function FDJNote(qid)
  local det = FDJDetails(qid)
  if not det then return nil end
  local t = str(det.note) or str(det.objective) or str(det.description)
  local w = str(det.warning)
  if t and w and w ~= t then return t .. " " .. w end
  return t or w
end
-- its map spot ({ mapID, x, y in 0-1, label }) as a GPS point, for a link with no place of its own
local function FDJPoint(qid, fallback)
  local det = FDJDetails(qid)
  local m = det and det.map
  if type(m) ~= "table" then return nil end
  local id, x, y = num(m.mapID), num(m.x), num(m.y)
  if not (id and x and y) then return nil end
  if x <= 1 and y <= 1 then x, y = x * 100, y * 100 end
  return { id, x, y, str(m.targetName) or str(m.label) or fallback }
end
-- LibForeverData's steps for a quest (live, credited in the tooltip)
local function LibSteps(qid)
  local lib = Lib()
  if not (lib and type(lib.Steps) == "function" and qid > 0) then return nil end
  local ok, steps = pcall(lib.Steps, qid)
  if not (ok and type(steps) == "table" and #steps > 0) then return nil end
  local out = {}
  for i, s in ipairs(steps) do
    if i > 4 then break end
    if type(s) == "table" and type(s.text) == "string" and s.text ~= "" then out[#out + 1] = s.text end
  end
  return #out > 0 and out or nil
end

-- The dungeons each main quest belongs to (for "the chain passes through another dungeon").
local qDungeons
local function DungeonsOf(qid)
  if not qDungeons then
    qDungeons = {}
    for k, d in pairs(ns.D) do
      if not d.cq then
        for _, id in ipairs(d.q or {}) do
          qDungeons[id] = qDungeons[id] or {}
          table.insert(qDungeons[id], k)
        end
      end
    end
  end
  return qDungeons[qid]
end

-- Everything the summary says about one quest of one dungeon.
local function Info(qid, dkey, ctx)
  local q = ns.Q[qid]
  local log = ctx.log
  local st = QState(log, qid)
  local pre = ns.QuestPreInfo(qid, log, ctx.cls)
  local low = LowLevel(log, q, st, pre, ctx.lvl)
  local maxL = q.l or q.r or 0
  local chainXP = QuestXP(qid)
  local other
  for _, pid in ipairs(pre.chain) do
    local pq = ns.Q[pid]
    if pq and (pq.l or 0) > maxL then maxL = pq.l end
    chainXP = chainXP + QuestXP(pid)
    if not other then
      for _, k in ipairs(DungeonsOf(pid) or {}) do
        local dk = ns.D[dkey]
        if k ~= dkey and not (dk and dk.inst and ns.D[k].inst == dk.inst) then other = k; break end
      end
    end
  end
  local high = (st == "none") and (low ~= nil or maxL > ctx.lvl + HIGH_GAP) or false
  return {
    q = q, st = st, pre = pre, low = low, maxL = maxL, high = high, other = other,
    xp = QuestXP(qid), money = QuestMoney(qid), chainN = pre.total + 1, chainXP = chainXP,
    elite = IsElite(qid, q),
  }
end

-- Ticks: WLDTDB.off[qid] leaves a quest out of the route (the engine reads it). A quest the
-- player never ticked by hand follows the default: ticked when its level allows it and its chain
-- does not go more than 5 levels above the player (WLDTDB.offPick remembers the hand-made ones).
local function IsOff(qid) return WLDTDB.off and WLDTDB.off[qid] and true or false end
-- The hand-made choices. Once, for a player who unticked quests before offPick existed: every quest
-- already left out was left out by hand (the defaults must not tick it back).
function ns.OffPick()
  WLDTDB.off = WLDTDB.off or {}
  if not WLDTDB.offPickV then
    WLDTDB.offPick = WLDTDB.offPick or {}
    for qid in pairs(WLDTDB.off) do WLDTDB.offPick[qid] = true end
    WLDTDB.offPickV = 1
  end
  WLDTDB.offPick = WLDTDB.offPick or {}
  return WLDTDB.offPick
end
local function ApplyDefault(qid, inf)
  local pick = ns.OffPick()
  if pick[qid] then return false end
  if inf.st == "done" then return false end
  local want = inf.high or nil
  if WLDTDB.off[qid] == want then return false end
  WLDTDB.off[qid] = want
  return true
end

-- =====================================================================
--  Window
-- =====================================================================
local f
local Render

-- The guide's route runs on exactly these dungeons.
local function RouteRuns(keys)
  if not (ns.route and ns.frame and keys and #keys > 0 and WLDTDB.sel) then return false end
  local n = 0
  for _, k in ipairs(keys) do if not WLDTDB.sel[k] then return false end; n = n + 1 end
  for k, v in pairs(WLDTDB.sel) do if v and ns.D[k] then n = n - 1 end end
  return n == 0
end

local function RouteHas(qid)
  local _, cls = UnitClass("player")
  for k in pairs(WLDTDB.sel or {}) do
    for _, x in ipairs(ns.D[k] and ns.D[k].q or {}) do if x == qid then return true end end
    for _, x in ipairs(ns.DungeonQuests(k, cls)) do
      for _, pid in ipairs(ns.FullChain(x, cls) or {}) do if pid == qid then return true end end
    end
  end
  return false
end

-- Ticks or unticks a quest. Only the quest itself is written: the engine reads `off` for a
-- dungeon's main quests and brings their prerequisites with them, so a chain row's links follow
-- it. Writing the links would drop a link that is also another dungeon's main quest from that route.
local function SetOff(qid, off)
  if not qid then return end
  local pick = ns.OffPick()
  WLDTDB.off[qid] = off and true or nil
  pick[qid] = true
  if PlaySound then PlaySound(SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or 856) end
  if ns.route and ns.frame and ns.Recalc and RouteHas(qid) then ns.Recalc() end
  if ns.RenderPicker then ns.RenderPicker() end
  Render()
end
ns.SummarySetOff = SetOff

-- The quest of a row to share: the quest itself when it is in your log, else the link of its
-- chain that is (the group does the chain together).
local function ShareTarget(qid, pre, log)
  local function ok(id)
    local q = ns.Q[id]
    return log[id] and q and q.sh ~= false and (not ns.Pushable or ns.Pushable(id, log[id]))
  end
  if ok(qid) then return qid end
  for _, pid in ipairs(pre and pre.chain or {}) do if ok(pid) then return pid end end
end

-- =====================================================================
--  Group: members, cells, verdict
-- =====================================================================
local CELL = {
  on = { "SUM_G_ON", "clock", "info" }, ready = { "SUM_G_READY", "flag", "ok" }, done = { "SUM_G_DONE", "check", "muted" },
  take = { "SUM_G_TAKE", "plus", "fg" }, pre = { "SUM_G_PRE", "warning", "warn" }, low = { "SUM_G_LOW", "warning", "warn" },
  na = { "SUM_G_NA", "minus", "faint" }, invalid = { "SUM_G_INVALID", "warning", "warn" }, declined = { "SUM_G_DECLINED", "minus", "warn" },
  full = { "SUM_G_FULL", "warning", "warn" }, busy = { "SUM_G_BUSY", "clock", "muted" }, far = { "SUM_G_FAR", "clock", "muted" },
  sent = { "SUM_G_SENT", "clock", "muted" }, unknown = { "SUM_G_UNKNOWN", "info", "muted" },
  wait = { "SUM_G_WAIT", "clock", "muted" },
}
-- states that leave nothing to do before the run
local READY = { on = true, ready = true, done = true, na = true }
-- the game said the member cannot take it (class, level, chain): taking it again will not help
local CANT = { invalid = true }

local function Members()
  if not ns.GroupMembers then return {} end
  return ns.GroupMembers()
end

local function ClassColor(cls)
  if not cls then return T.fg end
  local _, c = ns.ClassInfo(cls)
  return c
end

-- "3 membres sur 5 ont toutes les quêtes · tu dois en prendre 1 · Mylla doit en prendre 2 ·
-- Bob n'a pas WL Helper", over the ticked quests you still have to do.
local function Verdict(sel, members)
  if #members == 0 then return nil end
  local okN, parts = 0, {}
  local mine = 0
  for _, it in ipairs(sel) do if it.st == "none" then mine = mine + 1 end end
  if mine == 0 then okN = okN + 1 end
  local tail = {}
  if mine > 0 then tail[#tail + 1] = L.SUM_V_ME:format(mine) end
  for _, m in ipairs(members) do
    local take, cant, prePid, known = 0, 0, nil, false
    local helper = ns.HasHelper and ns.HasHelper(m.name)
    for _, it in ipairs(sel) do
      local s, pid = ns.MemberQuest(m.name, it.qid, it.dkey)
      -- a share or a reply still on its way says nothing yet
      local waiting = s == "unknown" or s == "sent"
      if not waiting then known = true end
      if s == "pre" then prePid = prePid or pid or it.qid
      elseif CANT[s] then cant = cant + 1
      elseif not READY[s] and not waiting then take = take + 1 end
    end
    if not known then tail[#tail + 1] = (helper and L.SUM_V_WAIT or L.SUM_V_NOHELPER):format(m.name)
    elseif prePid then tail[#tail + 1] = L.SUM_V_PRE:format(m.name, ns.QName(prePid))
    elseif take > 0 then tail[#tail + 1] = L.SUM_V_TAKE:format(m.name, take)
    elseif cant > 0 then tail[#tail + 1] = L.SUM_V_CANT:format(m.name, cant)
    else okN = okN + 1 end
  end
  local total = #members + 1
  parts[1] = ns.Plural(okN, "SUM_V_ALL1", "SUM_V_ALL", okN, total)
  -- three lines at most: four members named, the others counted
  for i, s in ipairs(tail) do
    if i > 4 then parts[#parts + 1] = L.OV_MORE:format(#tail - 4); break end
    parts[#parts + 1] = s
  end
  return table.concat(parts, " · ")
end
ns.SummaryVerdict = Verdict

-- =====================================================================
--  Widgets
-- =====================================================================
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
    if self.link then GameTooltip:AddLine(L.TT_SHIFT_LINK, (T.hint or T.muted)[1], (T.hint or T.muted)[2], (T.hint or T.muted)[3], true) end
    GameTooltip:Show()
  end)
  b:SetScript("OnLeave", function() GameTooltip:Hide() end)
  b:SetScript("OnClick", function(self)
    if self.link and HandleModifiedItemClick then pcall(HandleModifiedItemClick, self.link) end
  end)
  return b
end

-- A group cell: the HD icon over one or two words, the member's name and the detail in the tooltip.
local function MakeCell(parent)
  local c = CreateFrame("Frame", nil, parent)
  c:SetSize(CELLW, 40)
  c:EnableMouse(true)
  c.icon = ns.Icon(c, "dot", 14, "ARTWORK", T.muted); c.icon:SetPoint("TOP", 0, 0)
  c.word = ns.Text(c, ns.F.meta, T.muted); c.word:SetPoint("TOP", 0, -17)
  c.word:SetJustifyH("CENTER")
  c:SetScript("OnEnter", function(self) if self.tip then ns.ShowTip(self, self.tip) end end)
  c:SetScript("OnLeave", ns.HideTip)
  return c
end
local function FillCell(c, m, qid, dkey)
  local s, pid, src = ns.MemberQuest(m.name, qid, dkey)
  -- a member with WL Helper whose reply (for this dungeon) has not come yet
  local wait = s == "unknown" and ns.HasHelper and ns.HasHelper(m.name)
  local look = (wait and CELL.wait) or CELL[s] or CELL.unknown
  local col = T[look[3]] or T.muted
  ns.SetHDIcon(c.icon, look[2], col)
  c.word:SetText(L[look[1]])
  c.word:SetTextColor(col[1], col[2], col[3])
  local h = LineH(c.word, ns.F.meta, CELLW - 4, c)
  c:SetHeight(17 + h)
  c.state = s
  local tip = { m.name, L[look[1]] ~= "?" and L[look[1]] or nil }
  if s == "pre" and pid then tip[#tip + 1] = L.SUM_G_PRE_TT:format(ns.QName(pid)) end
  if wait then tip[2] = L.SUM_G_WAIT_TT:format(m.name)
  elseif s == "unknown" then tip[2] = L.SUM_G_UNKNOWN_TT:format(m.name) end
  if s == "sent" then tip[#tip + 1] = L.SUM_G_SENT_TT:format(m.name) end
  if s == "na" then tip[#tip + 1] = L.SUM_G_NA_TT end
  if src == "push" and s ~= "sent" then tip[#tip + 1] = L.SUM_G_PUSH_TT end
  local clean = {}
  for i = 1, 4 do if tip[i] then clean[#clean + 1] = tip[i] end end
  c.tip = clean
  return 17 + h
end

-- One link of an unfolded chain: state icon, name, level, XP and state; where it happens.
local function MakeLink(parent)
  local b = CreateFrame("Button", nil, parent)
  b.wlOwned = true
  b.hl = ns.Tex(b, "BACKGROUND", T.hoverFill); b.hl:SetAllPoints(); b.hl:Hide()
  b.press = ns.Tex(b, "BORDER", T.pressFill); b.press:SetAllPoints(); b.press:Hide()
  b.icon = ns.Icon(b, "dot", 14, "ARTWORK", T.muted); b.icon:SetPoint("TOPLEFT", 4, -3)
  b.name = ns.Text(b, ns.F.meta, T.text); b.name:SetPoint("TOPLEFT", 24, -3)
  b.where = ns.Text(b, ns.F.meta, T.muted)
  b.ne = ns.Text(b, ns.F.meta, T.text)
  b.note = ns.Text(b, ns.F.meta, T.muted)
  b.objs = {}
  b:SetScript("OnEnter", function(self)
    if self.point then self.hl:Show() end
    if self.tip then ns.ShowTip(self, self.tip) end
  end)
  b:SetScript("OnLeave", function(self) self.hl:Hide(); self.press:Hide(); ns.HideTip() end)
  b:SetScript("OnMouseDown", function(self) if self.point then self.press:Show() end end)
  b:SetScript("OnMouseUp", function(self) self.press:Hide() end)
  b:SetScript("OnClick", function(self) if self.point then GoPoint(self.point) end end)
  return b
end

-- One place of a link's objective outside the dungeon: pin, "what · where (x, y)"; a click guides there.
local function MakeObjLine(parent)
  local o = CreateFrame("Button", nil, parent)
  o.wlOwned = true
  o.hl = ns.Tex(o, "BACKGROUND", T.hoverFill); o.hl:SetAllPoints(); o.hl:Hide()
  o.press = ns.Tex(o, "BORDER", T.pressFill); o.press:SetAllPoints(); o.press:Hide()
  o.icon = ns.Icon(o, "pin", 12, "ARTWORK", T.accentSoft); o.icon:SetPoint("TOPLEFT", 0, -2)
  o.text = ns.Text(o, ns.F.meta, T.accentSoft); o.text:SetPoint("TOPLEFT", 16, -1)
  o:SetScript("OnEnter", function(self)
    self.hl:Show(); ns.SetHDIcon(self.icon, "pin", T.fg)
    if self.point then ns.ShowTip(self, { L.OV_GPS_T:format(self.point[4] or ""), L.OV_GPS_CLICK }) end
  end)
  o:SetScript("OnLeave", function(self) self.hl:Hide(); self.press:Hide(); ns.SetHDIcon(self.icon, "pin", T.accentSoft); ns.HideTip() end)
  o:SetScript("OnMouseDown", function(self) self.press:Show(); self.text:SetPoint("TOPLEFT", 16, -2) end)
  o:SetScript("OnMouseUp", function(self) self.press:Hide(); self.text:SetPoint("TOPLEFT", 16, -1) end)
  o:SetScript("OnClick", function(self) if self.point then GoPoint(self.point) end end)
  return o
end

-- The objectives of a quest with a place outside the dungeon, not done yet (4 at most).
local function OutsidePlaces(log, qid, q)
  local out = {}
  for _, o in ipairs(q.o or {}) do
    if #out >= 4 then break end
    local w = o.w
    if w and w.m and w.x and w.y and not o.ins and not o.outer and not ns.ObjDone(log, qid, o) then
      local what = o.n and ns.T(o.n) or nil
      local z = ZoneName(w.m)
      local place = w.n and ns.T(w.n) or nil
      if place and z ~= "" then place = place .. ", " .. z elseif z ~= "" then place = z end
      local txt = ("%s(%.1f, %.1f)"):format(place and (place .. " ") or "", w.x, w.y)
      if what then txt = what .. " · " .. txt end
      out[#out + 1] = { text = txt, point = { w.m, w.x, w.y, w.n or o.n } }
    end
  end
  return out
end

local LOOK = {
  none  = { "SUM_ST_NONE", T.fg },
  on    = { "SUM_ST_ON", T.info },
  ready = { "SUM_ST_READY", T.ok },
  done  = { "SUM_ST_DONE", T.muted, "check" },
}

local function RowTip(r)
  local qid = r.qid
  local q = qid and ns.Q[qid]
  if not q then return end
  local lines = { ns.QName(qid) }
  if GetLocale and GetLocale() == "frFR" and q.n and q.n ~= lines[1] then table.insert(lines, q.n)
  elseif ns.lang == "fr" and q.nf and q.nf ~= lines[1] then table.insert(lines, q.nf) end
  local obj = ObjText(q)
  if obj then table.insert(lines, { obj, T.text[1], T.text[2], T.text[3] }) end
  local g = r.st ~= "done" and GiverText(q, r.st)
  if g then table.insert(lines, g) end
  local steps = LibSteps(qid)
  if steps then
    table.insert(lines, { L.SUM_LFD, T.fg[1], T.fg[2], T.fg[3] })
    for _, s in ipairs(steps) do table.insert(lines, "- " .. s) end
  end
  local fdj = FDJNote(qid)
  if fdj then
    table.insert(lines, { L.SUM_FDJ, T.fg[1], T.fg[2], T.fg[3] })
    table.insert(lines, fdj)
  end
  if q.ne then table.insert(lines, ns.T(q.ne)) end
  local rw = q.rw and q.rw ~= "" and q.rw or nil
  if rw then table.insert(lines, { L.TT_REWARD:format(rw), T.gold[1], T.gold[2], T.gold[3] }) end
  if r.low then table.insert(lines, { L.ST_LOW:format(r.low), T.warn[1], T.warn[2], T.warn[3] }) end
  if r.st ~= "done" then
    local n = r.pre and r.pre.total or 0
    if IsOff(qid) then table.insert(lines, n > 0 and L.SUM_TICK_ON_CH:format(n) or L.SUM_TICK_ON)
    else table.insert(lines, n > 0 and L.SUM_TICK_OFF_CH:format(n) or L.SUM_TICK_OFF) end
  end
  ns.ShowTip(r, lines)
end

local function MakeRow(parent)
  local S = SW()
  local r = CreateFrame("Button", nil, parent)
  r.wlOwned = true
  r:SetWidth(CW)
  r.bg = ns.Tex(r, "BACKGROUND", T.cardFill); r.bg:SetAllPoints()
  ns.Outline(r, T.cardEdge)
  r.hl = ns.Tex(r, "BORDER", T.hoverFill); r.hl:SetAllPoints(); r.hl:Hide()
  r.press = ns.Tex(r, "ARTWORK", T.pressFill); r.press:SetAllPoints(); r.press:Hide()
  -- a drawn check box: panel fill, 1 px edge (accent when ticked), the HD check inside
  r.boxF = CreateFrame("Frame", nil, r); r.boxF:SetSize(16, 16); r.boxF:SetPoint("TOPLEFT", 8, -8)
  r.box = ns.Tex(r.boxF, "BACKGROUND", T.panel); r.box:SetAllPoints()
  r.boxEdge = ns.Outline(r.boxF, T.btnEdge)
  r.tick = ns.Icon(r.boxF, "check", 12, "ARTWORK", T.fg); r.tick:SetPoint("CENTER")
  r.doneIcon = ns.Icon(r, "check", 16, "ARTWORK", T.ok); r.doneIcon:SetPoint("TOPLEFT", 8, -8); r.doneIcon:Hide()
  r.name = ns.Text(r, ns.F.body, T.fg)
  r.detail = ns.Text(r, ns.F.meta, T.muted)
  r.status = S.Pill(r)
  -- the chain line: chevron + "Chain of 10 quests: 31,500 XP in all"; a click unfolds it
  r.chain = CreateFrame("Button", nil, r)
  r.chain.hl = ns.Tex(r.chain, "BACKGROUND", T.hoverFill); r.chain.hl:SetAllPoints(); r.chain.hl:Hide()
  r.chain.chev = ns.Icon(r.chain, "chevron_right", 12, "ARTWORK", T.accentSoft); r.chain.chev:SetPoint("TOPLEFT", 0, -1)
  r.chain.text = ns.Text(r.chain, ns.F.meta, T.text); r.chain.text:SetPoint("TOPLEFT", 16, 0)
  r.chain:SetScript("OnEnter", function(self)
    self.hl:Show(); self.chev:SetVertexColor(T.fg[1], T.fg[2], T.fg[3])
    ns.ShowTip(self, { L.OV_CHAIN_TT, f.open[r.qid] and L.SUM_COLLAPSE or L.SUM_EXPAND })
  end)
  r.chain:SetScript("OnLeave", function(self)
    self.hl:Hide(); self.chev:SetVertexColor(T.accentSoft[1], T.accentSoft[2], T.accentSoft[3]); ns.HideTip()
  end)
  r.chain:SetScript("OnMouseDown", function(self) self.text:SetPoint("TOPLEFT", 16, -1) end)
  r.chain:SetScript("OnMouseUp", function(self) self.text:SetPoint("TOPLEFT", 16, 0) end)
  r.chain:SetScript("OnClick", function()
    f.open[r.qid] = not f.open[r.qid] or nil
    Render()
  end)
  r.pills, r.rewards, r.cells, r.links = {}, {}, {}, {}
  r.share = S.Button(r, L.SUM_SHARE, 0, 24, "secondary", function(self)
    if r.shareId and ns.PushQuest and ns.PushQuest(r.shareId) then self:Flash(L.SUM_SHARED) end
  end, function() return { L.SUM_SHARE, L.SUM_SHARE_TT:format(r.shareId and ns.QName(r.shareId) or "") } end)
  r.gps = S.IconButton(r, "pin", 24, function()
    return { L.OV_GPS_T:format(r.point and r.point[4] or ""), L.OV_GPS_CLICK }
  end, function() GoPoint(r.point) end)
  -- "+N": the rewards that do not fit beside the actions, listed in its tooltip
  r.more = CreateFrame("Frame", nil, r)
  r.more:SetSize(20, 20); r.more:EnableMouse(true); r.more:Hide()
  r.more.hl = ns.Tex(r.more, "BACKGROUND", T.hoverFill); r.more.hl:SetAllPoints(); r.more.hl:Hide()
  ns.Outline(r.more, T.cardEdge)
  r.more.text = ns.Text(r.more, ns.F.meta, T.muted); r.more.text:SetPoint("CENTER")
  r.more:SetScript("OnEnter", function(self) self.hl:Show(); if self.tip then ns.ShowTip(self, self.tip) end end)
  r.more:SetScript("OnLeave", function(self) self.hl:Hide(); ns.HideTip() end)
  -- the row is the check box's click target
  r:SetScript("OnClick", function(self)
    if self.st == "done" then return end
    SetOff(self.qid, not IsOff(self.qid))
  end)
  local function nudge(self, dy)
    self.name:SetPoint("TOPLEFT", TX, -6 - dy)
    self.boxF:SetPoint("TOPLEFT", 8, -8 - dy)
  end
  r:SetScript("OnMouseDown", function(self) if self.st ~= "done" then self.press:Show(); nudge(self, 1) end end)
  r:SetScript("OnMouseUp", function(self) self.press:Hide(); nudge(self, 0) end)
  r:SetScript("OnEnter", function(self) if self.st ~= "done" then self.hl:Show() end RowTip(self) end)
  r:SetScript("OnLeave", function(self) self.hl:Hide(); self.press:Hide(); nudge(self, 0); ns.HideTip() end)
  return r
end

-- Pills in a flowing line inside `width`; returns the height used.
local function PlacePills(r, list, x0, y, width)
  local x, rowH, n = 0, 0, 0
  for i, p in ipairs(list) do
    local pill = r.pills[i] or SW().Pill(r); r.pills[i] = pill
    pill:Set(p[1], p[2], p[3])
    pill.tipLines = p[4]
    if not pill.wlTipHooked then
      pill.wlTipHooked = true
      pill:EnableMouse(true)
      pill:SetScript("OnEnter", function(self) if self.tipLines then ns.ShowTip(self, self.tipLines) end end)
      pill:SetScript("OnLeave", ns.HideTip)
    end
    local pw = num(pill:GetWidth()) or 60
    -- wider than the whole line: its short label (the full text stays in its tooltip)
    if pw > width and p[5] then pill:Set(p[5], p[2], p[3]); pw = num(pill:GetWidth()) or 60 end
    if x > 0 and x + pw > width then x = 0; y = y + 18 + 4 end
    pill:ClearAllPoints(); pill:SetPoint("TOPLEFT", r, "TOPLEFT", x0 + x, -y)
    pill:Show()
    x = x + pw + 4
    rowH = 18
    n = i
  end
  for i = n + 1, #r.pills do r.pills[i]:Hide() end
  return y + rowH
end

-- Fills one quest row; returns its height.
local function FillRow(r, qid, dkey, inf, ctx)
  local q = inf.q
  local log = ctx.log
  local st, pre = inf.st, inf.pre
  local off = IsOff(qid)
  r.qid, r.dkey, r.st, r.pre, r.low = qid, dkey, st, pre, inf.low
  r.point = (st ~= "done") and PointFor(log, qid, q, st, pre) or nil

  -- check box (a quest turned in shows the check icon instead)
  local done = st == "done"
  r.boxF:SetShown(not done); r.doneIcon:SetShown(done)
  r.tick:SetShown(not off)
  r.boxEdge(off and T.btnEdge or T.accent)

  -- right side: the status pill, then the group cells
  local look = LOOK[st] or LOOK.none
  r.status:Set(L[look[1]], look[2], look[3])
  local pillW = num(r.status:GetWidth()) or 80
  local ncol = #ctx.members
  local cellsW = ncol > 0 and (ncol * CELLW + 8) or 0
  local right = 12 + cellsW
  r.status:ClearAllPoints(); r.status:SetPoint("TOPRIGHT", r, "TOPRIGHT", -right, -8)
  local tw = CW - TX - right - pillW - 8

  r.name:SetText(ns.QName(qid))
  local nc = (off or done) and T.muted or T.fg
  r.name:SetTextColor(nc[1], nc[2], nc[3])
  r.name:ClearAllPoints(); r.name:SetPoint("TOPLEFT", TX, -6)
  -- in a group the cells take the right side: the name keeps the room beside the status pill
  -- (3 lines), everything else goes under the pill at the full width
  local grouped = ncol > 0
  local y = 6 + LineH(r.name, ns.F.body, tw, r, grouped and 3 or 2)
  local wide = CW - TX - right

  -- this quest: level, XP, money, giver
  local d = {}
  if q.l then d[#d + 1] = L.PICK_LV1:format(q.l) end
  if inf.xp > 0 then d[#d + 1] = L.SUM_XP:format(Big(inf.xp)) end
  if inf.money > 0 then d[#d + 1] = Money(inf.money) end
  if not done then local g = GiverText(q, st); if g then d[#d + 1] = g end end
  if #d > 0 then
    if grouped then y = math.max(y, 8 + 18) end
    r.detail:SetText(table.concat(d, " · "))
    r.detail:ClearAllPoints(); r.detail:SetPoint("TOPLEFT", TX, -(y + 3))
    r.detail:Show()
    -- solo: beside the status pill, the same width as the name; in a group: under it
    y = y + 3 + LineH(r.detail, ns.F.meta, grouped and wide or tw, r, grouped and 3 or 2)
  else r.detail:Hide() end
  -- nothing under the name in a group: the next lines still start under the pill
  if grouped then y = math.max(y, 8 + 18) end

  -- the chain line, unfoldable
  local hasChain = pre.total > 0 and not done
  if hasChain then
    r.chain.text:SetText(L.SUM_CHAIN_LINE:format(inf.chainN, Big(inf.chainXP)))
    ns.SetHDIcon(r.chain.chev, f.open[qid] and "chevron_down" or "chevron_right", T.accentSoft)
    local th = LineH(r.chain.text, ns.F.meta, wide - 16, r.chain)
    r.chain:SetSize(wide, th + 2)
    r.chain:ClearAllPoints(); r.chain:SetPoint("TOPLEFT", TX, -(y + 3))
    r.chain:Show()
    y = y + 3 + th + 2
  else r.chain:Hide() end

  -- pills: elite, chain, another dungeon, level too high (p[5]: a shorter label when it does not fit)
  local pills = {}
  if not done then
    if inf.elite then pills[#pills + 1] = { L.SUM_ELITE, T.warn, "skull", { L.SUM_ELITE, L.SUM_ELITE_TT } } end
    if pre.total > 0 then pills[#pills + 1] = { L.SUM_CHAIN_PILL:format(inf.chainN), T.fg, nil, { L.OV_CHAIN_TT, L.SUM_CHAIN_LINE:format(inf.chainN, Big(inf.chainXP)) } } end
    if inf.other then
      local dn = ns.DName(inf.other)
      pills[#pills + 1] = { L.SUM_OTHER:format(dn), T.info, "portal", { L.SUM_OTHER:format(dn), L.SUM_OTHER_TT:format(dn) }, L.SUM_OTHER_SHORT }
    end
    if inf.high then
      local lv = inf.low or inf.maxL
      pills[#pills + 1] = { L.SUM_HIGH, T.warn, "warning", { L.SUM_HIGH, inf.low and L.ST_LOW:format(inf.low) or L.SUM_HIGH_TT:format(lv) } }
    end
  end
  if #pills > 0 then y = PlacePills(r, pills, TX, y + 6, wide) else PlacePills(r, {}, TX, y, wide) end

  -- the actions at the right (GPS, share), then as many reward icons (20 px) as the room left
  -- holds; the others behind a "+N" marker
  r.shareId = (#ctx.members > 0 and not done) and ShareTarget(qid, pre, log) or nil
  r.share:SetShown(r.shareId ~= nil)
  r.gps:SetShown(r.point ~= nil)
  local actY = y + 6
  local rightX = TX + wide
  if r.point then
    r.gps:ClearAllPoints(); r.gps:SetPoint("TOPRIGHT", r, "TOPLEFT", rightX, -actY); rightX = rightX - 24 - 4
  end
  if r.shareId then
    local sw = num(r.share:GetWidth()) or 0
    if sw < 40 then sw = 80 end
    r.share:ClearAllPoints(); r.share:SetPoint("TOPRIGHT", r, "TOPLEFT", rightX, -actY); rightX = rightX - sw - 4
  end
  local list = done and {} or Rewards(qid, q)
  local slots = math.max(1, math.min(MAX_REWARDS, math.floor((rightX - TX + 4) / 24)))
  local showN = #list
  if showN > slots then showN = slots - 1 end
  local n = 0
  for i = 1, showN do
    local rw = list[i]
    n = n + 1
    local b = r.rewards[n] or MakeReward(r); r.rewards[n] = b
    local icon, link = ItemInfo(rw)
    b.id, b.name, b.link, b.choice = rw.id, rw.name, link, rw.choice
    b.tex:SetTexture(icon)
    b.upText = Upgrade(link)
    b.up:SetShown(b.upText ~= nil)
    b:ClearAllPoints(); b:SetPoint("TOPLEFT", TX + (n - 1) * 24, -actY - 2)
    b:Show()
  end
  for i = n + 1, #r.rewards do r.rewards[i]:Hide() end
  local rest = #list - showN
  if rest > 0 then
    r.more.text:SetText(L.OV_MORE:format(rest))
    local names = { L.SUM_RW_MORE }
    for i = showN + 1, #list do
      local rw = list[i]
      local nm = rw.name
      if not nm and rw.id and GetItemInfo then local ok, v = pcall(GetItemInfo, rw.id); if ok and type(v) == "string" then nm = v end end
      names[#names + 1] = "- " .. (nm or "?")
    end
    r.more.tip = names
    r.more:ClearAllPoints(); r.more:SetPoint("TOPLEFT", TX + showN * 24, -actY - 2)
    r.more:Show()
  else r.more:Hide() end
  if #list > 0 or r.point or r.shareId then y = y + 6 + 24 end

  -- the unfolded chain: one line per link (and the quest itself), where it happens
  local li = 0
  if hasChain and f.open[qid] then
    y = y + 4
    local ids = {}
    for _, pid in ipairs(pre.chain) do ids[#ids + 1] = pid end
    ids[#ids + 1] = qid
    for _, id in ipairs(ids) do
      local lq = ns.Q[id]
      if lq then
        li = li + 1
        local b = r.links[li] or MakeLink(r); r.links[li] = b
        local ls = QState(log, id)
        local word = L[(LOOK[ls] or LOOK.none)[1]]
        local icon, col = "dot", T.faint
        if ls == "done" then icon, col = "check", T.ok elseif ls == "ready" then icon, col = "flag", T.ok elseif ls == "on" then icon, col = "clock", T.info end
        ns.SetHDIcon(b.icon, icon, col)
        local parts = { ns.QName(id) .. (id == qid and (" (" .. L.OV_THIS .. ")") or "") }
        if lq.l then parts[#parts + 1] = L.PICK_LV1:format(lq.l) end
        local xp = QuestXP(id)
        if xp > 0 then parts[#parts + 1] = L.SUM_XP:format(Big(xp)) end
        parts[#parts + 1] = word
        b.name:SetText(table.concat(parts, " · "))
        local tc = ls == "done" and T.muted or T.text
        b.name:SetTextColor(tc[1], tc[2], tc[3])
        local lw = wide - 24 - 4
        local bh = 3 + LineH(b.name, ns.F.meta, lw, b)
        -- where and what, for a link not turned in yet: giver / objective, and the FDJ note
        local where, note = nil, nil
        if ls ~= "done" then
          local w = {}
          local g = GiverText(lq, ls); if g then w[#w + 1] = g end
          local o = ObjText(lq); if o then w[#w + 1] = o end
          where = #w > 0 and table.concat(w, " · ") or nil
          local fn = FDJNote(id)
          if fn then note = L.SUM_FDJ .. L.COLON .. fn end
        end
        if where then
          b.where:SetText(where); b.where:ClearAllPoints(); b.where:SetPoint("TOPLEFT", 24, -(bh + 3)); b.where:Show()
          bh = bh + 3 + LineH(b.where, ns.F.meta, lw, b, 3)
        else b.where:Hide() end
        -- the data's note says how and where (3 lines; all of it in the tooltip)
        local ne = ls ~= "done" and lq.ne and ns.T(lq.ne) or nil
        if ne then
          b.ne:SetText(ne); b.ne:ClearAllPoints(); b.ne:SetPoint("TOPLEFT", 24, -(bh + 3)); b.ne:Show()
          bh = bh + 3 + LineH(b.ne, ns.F.meta, lw, b, 3)
        else b.ne:Hide() end
        -- each place of an objective outside, with its GPS
        local oi = 0
        if ls == "on" or ls == "none" then
          for _, pl in ipairs(OutsidePlaces(log, id, lq)) do
            oi = oi + 1
            local ol = b.objs[oi] or MakeObjLine(b); b.objs[oi] = ol
            ol.text:SetText(pl.text)
            ol.point = pl.point
            local oh = LineH(ol.text, ns.F.meta, lw - 16, ol)
            ol:SetSize(lw, oh + 2)
            ol:ClearAllPoints(); ol:SetPoint("TOPLEFT", b, "TOPLEFT", 24, -(bh + 3))
            ol:Show()
            bh = bh + 3 + oh + 2
          end
        end
        for k = oi + 1, #b.objs do b.objs[k]:Hide() end
        if note then
          b.note:SetText(note); b.note:ClearAllPoints(); b.note:SetPoint("TOPLEFT", 24, -(bh + 3)); b.note:Show()
          bh = bh + 3 + LineH(b.note, ns.F.meta, lw, b, 3)
        else b.note:Hide() end
        bh = bh + 4
        b.point = (ls ~= "done") and (PointOf(log, id, lq, ls) or FDJPoint(id, ns.QName(id))) or nil
        local tip = { ns.QName(id) }
        local o = ObjText(lq); if o then tip[#tip + 1] = o end
        local steps = LibSteps(id)
        if steps then tip[#tip + 1] = { L.SUM_LFD, T.fg[1], T.fg[2], T.fg[3] }; for _, s in ipairs(steps) do tip[#tip + 1] = "- " .. s end end
        if lq.ne then tip[#tip + 1] = ns.T(lq.ne) end
        if b.point then tip[#tip + 1] = L.OV_ROW_CLICK:format(b.point[4] or "") end
        b.tip = tip
        b:SetSize(wide, bh)
        b:ClearAllPoints(); b:SetPoint("TOPLEFT", r, "TOPLEFT", TX, -y)
        b:Show()
        y = y + bh
      end
    end
  end
  for i = li + 1, #r.links do r.links[i]:Hide() end

  -- group cells, one per member, at the right edge
  local cellH = 0
  for j, m in ipairs(ctx.members) do
    local c = r.cells[j] or MakeCell(r); r.cells[j] = c
    local h = FillCell(c, m, qid, dkey)
    c:ClearAllPoints(); c:SetPoint("TOPLEFT", r, "TOPLEFT", CW - 12 - (ncol - j + 1) * CELLW, -8)
    c:Show()
    if h > cellH then cellH = h end
  end
  for j = ncol + 1, #r.cells do r.cells[j]:Hide() end

  local h = math.ceil(math.max(y + 8, 8 + 18 + 8, 8 + cellH + 8))
  r:SetHeight(h)
  return h
end

-- =====================================================================
--  Build
-- =====================================================================
local function MakeHero(parent)
  local hero = CreateFrame("Frame", nil, parent)
  hero.wlWorld = true
  hero:SetSize(CW, HERO_H)
  ns.Flat(hero, T.panel, T.cardEdge)
  hero.art = hero:CreateTexture(nil, "ARTWORK"); hero.art:SetPoint("TOPLEFT", 1, -1); hero.art:SetPoint("BOTTOMRIGHT", -1, 1)
  hero.big = hero:CreateTexture(nil, "ARTWORK", nil, 1); hero.big:SetSize(40, 40); hero.big:SetPoint("CENTER", 0, 12); hero.big:Hide()
  hero.band = hero:CreateTexture(nil, "ARTWORK", nil, 3); hero.band:SetPoint("BOTTOMLEFT", 1, 1); hero.band:SetPoint("BOTTOMRIGHT", -1, 1)
  hero.band:SetColorTexture(unpack(T.scrim))
  hero.loc = ns.Text(hero, ns.F.meta, T.text, false, "SHADOW"); hero.loc:SetPoint("BOTTOMLEFT", 12, 8)
  hero.lvl = ns.Text(hero, ns.F.label, T.fg, false, "SHADOW"); hero.lvl:SetPoint("BOTTOMLEFT", hero.loc, "TOPLEFT", 0, 3)
  hero.name = ns.Text(hero, ns.F.heading, T.fg, false, "SHADOW"); hero.name:SetPoint("BOTTOMLEFT", hero.lvl, "TOPLEFT", 0, 3)
  return hero
end

local function Build()
  local S = SW()
  f = S.Window("WLHelperOverview", W, 300, "", L.SUM_T, WLDTDB, "ovPos", { header = 44, minH = 120, strata = "HIGH" })
  f.open = {}
  -- pinned at the top: your selection's totals, the group's verdict, the members' names
  f.top = CreateFrame("Frame", nil, f)
  f.totals = ns.Text(f.top, ns.F.body, T.fg)
  f.verdict = ns.Text(f.top, ns.F.body, T.text)
  f.gHead = CreateFrame("Frame", nil, f.top)
  f.gHead:SetSize(CW, 18)
  f.gHead.label = ns.Text(f.gHead, ns.F.meta, T.muted); f.gHead.label:SetPoint("BOTTOMLEFT", 0, 2)
  f.gHead.names = {}
  f.gHead.rule = ns.Rule(f.gHead); f.gHead.rule:SetPoint("BOTTOMLEFT"); f.gHead.rule:SetPoint("BOTTOMRIGHT")

  f.sa = S.ScrollArea(f)
  f.child = f.sa.child
  f.child:SetWidth(CW)
  f.heroes, f.info, f.gpsBtns, f.notes, f.rows = {}, {}, {}, {}, {}
  f.empty = S.EmptyState(f.child, "portal", L.OV_EMPTY_T, L.OV_EMPTY)
  f.empty:Hide()

  -- pinned at the bottom: share all (in a group), close, start the route (the one primary)
  f.bar = CreateFrame("Frame", nil, f)
  f.bar:SetHeight(32)
  f.goBtn = S.Button(f.bar, L.SUM_GO, 0, 32, "primary", function()
    local keys = f.keys
    if not keys or #keys == 0 then return end
    -- the route of these dungeons already runs: back to it (the ticks already replanned it);
    -- starting again would forget the steps marked done by hand
    if RouteRuns(keys) then
      f:Hide()
      if ns.ShowGuide then ns.ShowGuide() end
      return
    end
    WLDTDB.sel = WLDTDB.sel or {}
    wipe(WLDTDB.sel)
    for _, k in ipairs(keys) do WLDTDB.sel[k] = true end
    f:Hide()
    ns.StartGuide()
  end, function()
    if RouteRuns(f.keys) then return { L.SUM_BACK, L.SUM_BACK_TT } end
    return { L.SUM_GO, f.one and L.SUM_GO_TT1 or L.SUM_GO_TT }
  end)
  f.goBtn:SetPoint("RIGHT", 0, 0)
  f.goBtn:SetDisabledReason(L.SUM_GO_WHY)
  f.closeBtn = S.Button(f.bar, L.SUM_CLOSE, 0, 28, "secondary", function() f:Hide() end, { L.SUM_CLOSE, L.SUM_CLOSE_TT })
  f.closeBtn:SetPoint("RIGHT", f.goBtn, "LEFT", -8, 0)
  f.shareAll = S.Button(f.bar, L.SUM_SHARE_ALL, 0, 28, "secondary", function(self)
    local list = f.shareList or {}
    if #list == 0 or not ns.PushQuests then return end
    SetOn(self, false)
    ns.PushQuests(list, function() if f:IsShown() then Render() end end)
    if self:IsEnabled() == false and ns.pushBusy then self:SetText(L.SUM_SHARING) end
  end, function() return { L.SUM_SHARE_ALL, L.SUM_SHARE_ALL_TT } end)
  f.shareAll:SetPoint("LEFT", 0, 0)
  f.shareAll:SetDisabledReason(L.SUM_SHARE_WHY)

  -- the summary follows the quest log, the level and the bags while it is open
  local ev = CreateFrame("Frame", nil, f)
  for _, e in ipairs({ "QUEST_LOG_UPDATE", "QUEST_TURNED_IN", "PLAYER_LEVEL_UP", "BAG_UPDATE_DELAYED", "GET_ITEM_INFO_RECEIVED", "GROUP_ROSTER_UPDATE" }) do
    pcall(ev.RegisterEvent, ev, e)
  end
  local queued = false
  ev:SetScript("OnEvent", function(_, e)
    if e == "GET_ITEM_INFO_RECEIVED" then wipe(rewardCache) end
    if queued or not f:IsShown() then return end
    queued = true
    local fn = function() queued = false; if f:IsShown() then Render() end end
    if C_Timer and C_Timer.After then C_Timer.After(0.3, fn) else fn() end
  end)
end

-- A line of facts: HD icon 14 at the left edge, body text at 22.
local function InfoLine(i, icon, color, text, textColor)
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
  return it
end

-- =====================================================================
--  Render
-- =====================================================================
Render = function()
  if not (f and f.keys and #f.keys > 0) then return end
  local S = SW()
  local keys = {}
  for _, k in ipairs(f.keys) do if ns.D[k] then keys[#keys + 1] = k end end
  if #keys == 0 then f:Hide(); return end
  local log = ns.LogEntries()
  local cls, lvl = Cls(), Level()
  local members = Members()
  local shown = {}
  for i = 1, math.min(MAXCOLS, #members) do shown[i] = members[i] end
  local ctx = { log = log, cls = cls, lvl = lvl, members = shown }
  local multi = #keys > 1
  if multi then
    f.title:SetText(L.SUM_ROUTE_T)
    f.subtitle:SetText(ns.Plural(#keys, "SUM_DG1", "SUM_DG", #keys))
  else
    f.title:SetText(ns.DName(keys[1]))
    f.subtitle:SetText(L.SUM_T)
  end
  local c = f.child

  -- every quest's facts first: the defaults, then the totals over the ticked ones
  local per, sel, seen = {}, {}, {}
  local routeChanged = false
  local tq, txp, tmoney, titems = 0, 0, 0, 0
  local shareList, shareSeen = {}, {}
  local function count(id)
    if seen[id] then return end
    seen[id] = true
    local q = ns.Q[id]
    tq = tq + 1
    txp = txp + QuestXP(id)
    tmoney = tmoney + QuestMoney(id)
    if q then titems = titems + ItemCount(id, q) end
  end
  for _, dkey in ipairs(keys) do
    local list = {}
    for _, qid in ipairs(ns.DungeonQuests(dkey, cls)) do
      local inf = Info(qid, dkey, ctx)
      if ApplyDefault(qid, inf) and WLDTDB.sel and WLDTDB.sel[dkey] then routeChanged = true end
      list[#list + 1] = { qid = qid, inf = inf }
      if not IsOff(qid) and inf.st ~= "done" then
        sel[#sel + 1] = { qid = qid, dkey = dkey, st = inf.st }
        for k, pid in ipairs(inf.pre.chain) do if inf.pre.states[k] ~= "done" then count(pid) end end
        count(qid)
        local function addShare(id)
          local q = ns.Q[id]
          if not shareSeen[id] and log[id] and q and q.sh ~= false and (not ns.Pushable or ns.Pushable(id, log[id])) then
            shareSeen[id] = true; shareList[#shareList + 1] = id
          end
        end
        for _, pid in ipairs(inf.pre.chain) do addShare(pid) end
        addShare(qid)
      end
    end
    per[dkey] = list
  end
  f.shareList = shareList
  -- a default changed (a level up) for a dungeon of the running route: the route follows, once
  if routeChanged and ns.route and ns.frame and ns.frame:IsShown() and ns.Recalc and C_Timer and C_Timer.After then
    C_Timer.After(0, function() pcall(ns.Recalc) end)
  end

  -- pinned top: totals, verdict, member names
  local topY = 0
  if tq > 0 then
    local parts = { ns.Plural(tq, "SUM_Q1", "SUM_Q", tq) }
    if txp > 0 then parts[#parts + 1] = L.SUM_XP:format(Big(txp)) end
    if tmoney > 0 then parts[#parts + 1] = Money(tmoney) end
    if titems > 0 then parts[#parts + 1] = ns.Plural(titems, "SUM_ITEMS1", "SUM_ITEMS", titems) end
    f.totals:SetText(L.SUM_SEL:format(table.concat(parts, " · ")))
    f.totals:SetTextColor(T.fg[1], T.fg[2], T.fg[3])
  else
    f.totals:SetText(L.SUM_SEL0)
    f.totals:SetTextColor(T.muted[1], T.muted[2], T.muted[3])
  end
  f.totalsInfo = { quests = tq, xp = txp, money = tmoney, items = titems }
  f.totals:ClearAllPoints(); f.totals:SetPoint("TOPLEFT", f.top, "TOPLEFT", 0, 0)
  topY = LineH(f.totals, ns.F.body, CW, f.top)
  local verdict = Verdict(sel, members)
  if verdict then
    f.verdict:SetText(verdict)
    f.verdict:ClearAllPoints(); f.verdict:SetPoint("TOPLEFT", f.top, "TOPLEFT", 0, -(topY + 4))
    f.verdict:Show()
    topY = topY + 4 + LineH(f.verdict, ns.F.body, CW, f.top, 3)
  else f.verdict:SetText(""); f.verdict:Hide() end
  f.verdictText = verdict
  if #shown > 0 then
    local gh = f.gHead
    gh.label:SetText(L.SUM_GROUP)
    for j, m in ipairs(shown) do
      local fs = gh.names[j]
      if not fs then fs = ns.Text(gh, ns.F.meta, T.fg); fs:SetJustifyH("CENTER"); gh.names[j] = fs end
      fs:SetText(m.name)
      local cc = ClassColor(m.class)
      fs:SetTextColor(cc[1], cc[2], cc[3])
      fs:SetWidth(CELLW - 4)
      ns.ClampLabel(fs, m.name, gh)
      fs:ClearAllPoints(); fs:SetPoint("BOTTOMLEFT", gh, "BOTTOMLEFT", CW - 12 - (#shown - j + 1) * CELLW + 2, 4)
      fs:Show()
    end
    for j = #shown + 1, #gh.names do gh.names[j]:Hide() end
    gh:ClearAllPoints(); gh:SetPoint("TOPLEFT", f.top, "TOPLEFT", 0, -(topY + 8))
    gh:Show()
    topY = topY + 8 + 18
  else f.gHead:Hide() end
  topY = math.ceil(topY)

  -- the dungeons, one after the other: picture, facts, quests
  local y, hi, ii, gi, ni, ri = 0, 0, 0, 0, 0, 0
  for di, dkey in ipairs(keys) do
    local d = ns.D[dkey]
    if di > 1 then y = y + 16 end
    hi = hi + 1
    local hero = f.heroes[hi] or MakeHero(c); f.heroes[hi] = hero
    if hi == 1 then f.hero = hero end
    local hh = multi and HERO_H_MULTI or HERO_H
    hero:SetSize(CW, hh)
    hero:ClearAllPoints(); hero:SetPoint("TOPLEFT", c, "TOPLEFT", 0, -y)
    if ns.DungeonArt then ns.DungeonArt(hero.art, dkey, hero.big) end
    local parts = {}
    if d.lvl and d.lvl[1] then
      local lo, hi2 = d.lvl[1], d.lvl[2] or d.lvl[1]
      table.insert(parts, lo == hi2 and L.PICK_LV1:format(lo) or L.PICK_LV:format(lo, hi2))
    end
    table.insert(parts, L.OV_GROUP:format(d.size or 5))
    hero.lvl:SetText(table.concat(parts, " · "))
    local loc = (GetLocale and GetLocale() == "frFR" and d.locf) or ns.T(d.loc) or ""
    if d.cq and d.home then loc = L.CQ_IN:format(ns.DName(d.home)) end
    hero.loc:SetText(loc)
    hero.name:SetText(multi and ns.DName(dkey) or "")
    local locH = loc ~= "" and LineH(hero.loc, ns.F.meta, CW - 24, hero) or 0
    local lvlH = LineH(hero.lvl, ns.F.label, CW - 24, hero, 1)
    local nameH = multi and (3 + LineH(hero.name, ns.F.heading, CW - 24, hero, 1)) or 0
    hero.band:SetHeight(math.min(hh - 2, 8 + locH + (locH > 0 and 3 or 0) + lvlH + nameH + 8))
    hero:Show()
    y = y + hh + 12

    -- facts: entrance (with its GPS), keys
    local function place(it, w, extra)
      it.icon:ClearAllPoints(); it.icon:SetPoint("TOPLEFT", c, "TOPLEFT", 0, -(y + 1))
      it.fs:ClearAllPoints(); it.fs:SetPoint("TOPLEFT", c, "TOPLEFT", 22, -y)
      local h = LineH(it.fs, ns.F.body, w, c, 0)
      y = y + math.max(h, extra or 0) + 6
    end
    local point = d.e and d.e.m and { d.e.m, d.e.x, d.e.y, ns.DName(dkey) } or nil
    local entry = ns.T(d.ed) or loc
    if entry and entry ~= "" then
      ii = ii + 1
      local it = InfoLine(ii, "portal", T.muted, L.OV_ENTRANCE:format(entry), T.text)
      if point then
        gi = gi + 1
        local g = f.gpsBtns[gi]
        if not g then
          g = S.IconButton(c, "pin", 24, function(self) return { L.OV_GPS_T:format(L.OV_ENTRY_T), L.OV_GPS_CLICK } end,
            function(self) GoPoint(self.point) end)
          f.gpsBtns[gi] = g
        end
        g.point = point
        g:ClearAllPoints(); g:SetPoint("TOPRIGHT", c, "TOPRIGHT", 0, -(y - 5))
        g:Show()
        if gi == 1 then f.entryGps = g; f.entryPoint = point end
      end
      place(it, CW - 22 - (point and 32 or 0), point and 14 or 0)
    end
    local kl = ns.KeyLines and ns.KeyLines(dkey) or {}
    if #kl == 0 then
      ii = ii + 1
      place(InfoLine(ii, "check", T.muted, L.OV_KEY_NONE, T.muted), CW - 22)
    else
      for _, k in ipairs(kl) do
        ii = ii + 1
        local icon, col = "check", T.ok
        if not k[2] then if k[3] then icon, col = "warning", T.warn else icon, col = "info", T.muted end end
        place(InfoLine(ii, icon, col, k[1], T.text), CW - 22)
      end
    end
    y = y + 6

    -- the quests: to do first (by level), turned in last
    local list = per[dkey]
    table.sort(list, function(a, b)
      local da, db = a.inf.st == "done", b.inf.st == "done"
      if da ~= db then return db end
      local la, lb = a.inf.q.l or 0, b.inf.q.l or 0
      if la ~= lb then return la < lb end
      return a.qid < b.qid
    end)
    if #list == 0 then
      if multi then
        ni = ni + 1
        local fs = f.notes[ni] or ns.Text(c, ns.F.body, T.muted); f.notes[ni] = fs
        fs:SetText(L.SUM_NOQ)
        fs:ClearAllPoints(); fs:SetPoint("TOPLEFT", c, "TOPLEFT", 0, -y); fs:Show()
        y = y + LineH(fs, ns.F.body, CW, c)
      else
        local up = d.up and time() < d.up
        local why = L.OV_EMPTY
        if up then why = L.OV_EMPTY_UP elseif #(d.q or {}) == 0 then why = L.OV_EMPTY_NONE end
        f.empty:ClearAllPoints(); f.empty:SetPoint("TOP", c, "TOP", 0, -(y + 12))
        f.empty:SetWrapWidth(CW)
        local eh = f.empty:Set("portal", L.OV_EMPTY_T, why)
        f.empty:Show()
        y = y + 12 + (num(eh) or 80)
      end
    else
      for _, e in ipairs(list) do
        ri = ri + 1
        local r = f.rows[ri] or MakeRow(c); f.rows[ri] = r
        r:ClearAllPoints(); r:SetPoint("TOPLEFT", c, "TOPLEFT", 0, -y)
        local h = FillRow(r, e.qid, dkey, e.inf, ctx)
        r:Show(); r.shownNow = true
        y = y + h + ROW_GAP
      end
      y = y - ROW_GAP
    end
  end
  for j = hi + 1, #f.heroes do f.heroes[j]:Hide() end
  for j = ii + 1, #f.info do f.info[j].icon:Hide(); f.info[j].fs:Hide() end
  for j = gi + 1, #f.gpsBtns do f.gpsBtns[j]:Hide() end
  if gi == 0 then f.entryGps, f.entryPoint = nil, nil end
  for j = ni + 1, #f.notes do f.notes[j]:Hide() end
  for j = ri + 1, #f.rows do f.rows[j]:Hide(); f.rows[j].shownNow = nil end
  if multi or ri > 0 then f.empty:Hide() end

  -- bottom bar
  local back = RouteRuns(keys)
  f.goBtn:SetText(back and L.SUM_BACK or L.SUM_GO)
  if f.goBtn.SetIcon then f.goBtn:SetIcon(back and "chevron_left" or "pin") end
  SetOn(f.goBtn, back or #sel > 0)
  f.goBack = back
  local grouped = #members > 0
  f.shareAll:SetShown(grouped)
  if grouped then
    if not ns.pushBusy then f.shareAll:SetText(L.SUM_SHARE_ALL) end
    SetOn(f.shareAll, #shareList > 0 and not ns.pushBusy)
  end

  -- the window fits its content up to 80 % of the screen; past that, the quests scroll
  local contentH = math.ceil(y)
  local top = f:ContentTop() + 12
  f.top:ClearAllPoints(); f.top:SetPoint("TOPLEFT", f, "TOPLEFT", PAD, -top); f.top:SetSize(CW, math.max(1, topY))
  local saTop = top + topY + 12
  local barH = 12 + 32
  local cap = math.floor((num(UIParent:GetHeight()) or 768) * 0.80) - saTop - barH - 12
  local viewH = math.max(60, math.min(contentH, cap))
  f.sa:ClearAllPoints()
  f.sa:SetPoint("TOPLEFT", f, "TOPLEFT", PAD, -saTop); f.sa:SetPoint("TOPRIGHT", f, "TOPRIGHT", -PAD, -saTop)
  f.sa:SetHeight(viewH)
  f.child:SetWidth(CW)
  f.sa:SetContentHeight(contentH)
  f.bar:ClearAllPoints()
  f.bar:SetPoint("TOPLEFT", f, "TOPLEFT", PAD, -(saTop + viewH + 12)); f.bar:SetPoint("TOPRIGHT", f, "TOPRIGHT", -PAD, -(saTop + viewH + 12))
  f:FitHeight(topY + 12 + viewH + barH)
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

-- The picked dungeons, in the picker's order.
local function PickedKeys()
  local out = {}
  for _, k in ipairs(ns.ORDER or {}) do if WLDTDB.sel and WLDTDB.sel[k] then out[#out + 1] = k end end
  return out
end
ns.PickedKeys = PickedKeys

-- Opens the summary of one or several dungeons (the picked ones without `keys`). `one`: opened on
-- a single dungeon (its overview): starting the route replaces the picked dungeons with it.
function ns.ShowSummary(keys, one)
  if GuideOff() then return end
  if ns.EnsureClassCards then ns.EnsureClassCards() end
  keys = keys or PickedKeys()
  local list = {}
  for _, k in ipairs(keys) do if ns.D[k] then list[#list + 1] = k end end
  if #list == 0 then return end
  if not f then Build() end
  local sig = table.concat(list, ",")
  if f.sig ~= sig and f.sa then f.sa:ScrollTo(0, true); wipe(f.open) end
  f.sig, f.keys, f.one = sig, list, one and true or nil
  f.dkey = list[1]
  f:Show(); f:Raise()
  if ns.SyncAsk then ns.SyncAsk(list) end
  Render()
  -- wrapped text has its real height once the font and width are applied: measure again
  if C_Timer and C_Timer.After then C_Timer.After(0, function() if f:IsShown() then Render() end end) end
  return f
end

-- Opens the overview of a dungeon (dkey from ns.D); without a key, the guide's dungeon. While the
-- route runs on several dungeons, the guide's button shows the whole route's summary.
function ns.ShowOverview(dkey)
  dkey = dkey or DefaultKey()
  if not (dkey and ns.D[dkey]) then return end
  if ns.route and WLDTDB.sel and WLDTDB.sel[dkey] then
    local keys = PickedKeys()
    if #keys > 1 then
      -- the guide's dungeon first
      for i, k in ipairs(keys) do if k == dkey then table.remove(keys, i); table.insert(keys, 1, dkey); break end end
      return ns.ShowSummary(keys)
    end
  end
  return ns.ShowSummary({ dkey }, not (WLDTDB.sel and WLDTDB.sel[dkey] and not next(WLDTDB.sel, next(WLDTDB.sel))))
end
function ns.HideOverview() if f then f:Hide() end end
