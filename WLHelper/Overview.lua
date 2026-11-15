-- Résumé d'un ou plusieurs donjons : le premier écran quand tu lances une route depuis le choix des
-- donjons, et la vue d'ensemble d'un donjon (bouton de la carte, clic droit, bouton du guide).
-- En haut : l'image du donjon (nom, niveaux, taille du groupe), l'entrée (GPS) et la clé sur deux
-- lignes courtes, puis le total de ta sélection, qui suit tes coches. Puis « Quêtes à faire » : une
-- ligne par quête (case à cocher, nom dans la couleur de difficulté, « Niv. 45 · 7 800 XP · 65 pa »,
-- des pastilles seulement quand elles disent quelque chose, la chaîne qui se déplie, jusqu'à 4
-- objets en récompense : icône 30 px bordée de sa qualité, flèche verte et « +12 % » sous l'icône
-- quand WL Helper Gear y voit une amélioration, le meilleur des choix cerclé d'or). Les quêtes
-- déjà rendues sont repliées en bas (« Déjà rendues (10) »). En groupe : une colonne d'icônes par
-- membre dont l'état est connu (WL Helper, ou la réponse du jeu à un partage) ; les autres sur une
-- seule ligne. En bas : « Lancer la route » (premier écran), « Mettre à jour la route » (la route
-- tourne et tes coches ont changé) ou « Retour à la route » (rien n'a changé), et « Fermer » (« Retour
-- au choix » quand le résumé vient du choix des donjons). Ouvert ailleurs pendant qu'une route tourne
-- sur d'autres donjons : « Lancer la route ici », confirmé par un deuxième clic.
-- Design system: docs/DESIGN.md (640 px window sized to its content, scroll past 80 % of the screen).
local ADDON, ns = ...
local L, T = ns.L, ns.T_

-- =====================================================================
--  Strings (added to the root locale tables; Locale.lua keeps the older OV_ keys)
-- =====================================================================
local STR = {
  fr = {
    SUM_T = "Résumé", SUM_ROUTE_T = "Résumé de la route", SUM_DG1 = "%d donjon", SUM_DG = "%d donjons",
    SUM_SEL = "Ta sélection : %s", SUM_SEL0 = "Aucune quête cochée pour l'instant.",
    SUM_Q1 = "%d quête", SUM_Q = "%d quêtes", SUM_XP = "%s XP",
    SUM_LV1 = "Niv. %d", SUM_LV = "Niv. %d-%d", SUM_SIZE = "Groupe de %d",
    SUM_CHAIN_LINE = "Chaîne : %d quêtes · %s XP au total",
    SUM_ELITE = "Élite", SUM_ELITE_TT = "Un objectif vise un monstre élite : viens en groupe.",
    SUM_OTHER = "Autre donjon : %s", SUM_OTHER_TT = "Un maillon de la chaîne se fait dans %s.",
    SUM_HIGH = "Niveau trop haut", SUM_HIGH_TT = "La chaîne monte jusqu'au niveau %d, plus de 5 niveaux au-dessus de toi : décochée par défaut.",
    SUM_ST_ON = "Dans ton journal", SUM_ST_READY = "Prête à rendre", SUM_ST_DONE = "Rendue",
    SUM_TICK_OFF = "Clic : retirer cette quête de la route", SUM_TICK_ON = "Clic : remettre cette quête dans la route",
    SUM_TICK_OFF_CH = "Clic : retirer cette quête et ses %d prérequis de la route",
    SUM_TICK_ON_CH = "Clic : remettre cette quête et ses %d prérequis dans la route",
    SUM_EXPAND = "Clic : voir chaque quête de la chaîne", SUM_COLLAPSE = "Clic : replier la chaîne",
    SUM_FDJ = "Note de ForeverDungeonJournal", SUM_LFD = "Étapes (LibForeverData)",
    SUM_TODO = "Quêtes à faire",
    SUM_DONE_H = "Déjà rendues (%d)", SUM_DONE_OPEN = "Clic : voir les quêtes déjà rendues", SUM_DONE_CLOSE = "Clic : replier les quêtes déjà rendues",
    SUM_ALLDONE_T = "Toutes les quêtes sont rendues : %s", SUM_ALLDONE_TN = "Tu as déjà rendu toutes les quêtes de ces donjons",
    SUM_ALLDONE_NOTE = "%s : toutes les quêtes sont déjà rendues.",
    SUM_OTHER_DG = "Choisir un autre donjon",
    SUM_RUN = "Me guider dans le donjon", SUM_RUN_N = "Me guider dans les donjons",
    SUM_RUN_TT = "Clic : ouvrir le guide, de l'entrée jusqu'au dernier boss, un boss après l'autre",
    SUM_RUN_SUB = "Le guide peut quand même te mener de l'entrée au dernier boss.",
    SUM_RUN_SUB_N = "Le guide peut quand même te mener dans chaque donjon, de boss en boss.",
    SUM_BACK_PICK = "Retour au choix", SUM_BACK_PICK_TT = "Clic : revenir au choix des donjons sans lancer la route",
    SUM_GO_HERE = "Lancer la route ici", SUM_GO_CONFIRM = "Remplacer la route ?",
    SUM_GO_HERE_TT = "Clic : remplacer la route en cours par ce donjon seul, avec les quêtes cochées (les étapes cochées à la main sont perdues ; un 2e clic confirme)",
    SUM_EXTRA1 = "Aussi dans le groupe : %s (son état est dans la bulle de chaque quête)",
    SUM_EXTRA = "Aussi dans le groupe : %s (leur état est dans la bulle de chaque quête)",
    SUM_COL_TT = "Une icône par quête : survole-la pour le détail",
    SUM_GO = "Lancer la route", SUM_GO_TT = "Clic : fermer le résumé et ouvrir le guide sur la première étape, avec les quêtes cochées",
    SUM_GO_TT1 = "Clic : lancer la route sur ce donjon seul, avec les quêtes cochées (remplace tes donjons choisis)",
    SUM_GO_WHY = "Coche au moins une quête à faire.", SUM_CLOSE = "Fermer", SUM_CLOSE_TT = "Clic : fermer le résumé sans lancer la route",
    SUM_UPDATE = "Mettre à jour la route", SUM_UPDATE_TT = "Clic : revenir au guide, la route suit tes nouvelles coches",
    SUM_BACK = "Retour à la route", SUM_BACK_TT = "Clic : revenir au guide là où tu en étais",
    SUM_SHARE = "Partager", SUM_SHARED = "Partagée", SUM_SHARE_TT = "Clic : partager « %s » avec le groupe",
    SUM_SHARE_ALL = "Tout partager", SUM_SHARE_ALL_TT = "Clic : partager avec le groupe les quêtes cochées de ton journal, une toutes les 1,5 s",
    SUM_SHARE_WHY = "Aucune quête cochée de ton journal ne se partage.", SUM_SHARING = "Partage en cours",
    SUM_NOQ = "Aucune quête pour toi dans ce donjon.",
    SUM_NOHELPER1 = "Sans WL Helper : %s (son état apparaît quand tu partages)",
    SUM_NOHELPER = "Sans WL Helper : %s (leur état apparaît quand tu partages)",
    SUM_G_ON = "L'a dans son journal", SUM_G_READY = "Prête à rendre", SUM_G_DONE = "Déjà rendue", SUM_G_TAKE = "À prendre",
    SUM_G_PRE = "Prérequis manquant", SUM_G_LOW = "Niveau trop bas", SUM_G_NA = "Pas pour ce personnage", SUM_G_INVALID = "Pas éligible",
    SUM_G_DECLINED = "Refusée", SUM_G_FULL = "Journal plein", SUM_G_BUSY = "Indisponible", SUM_G_FAR = "Trop loin",
    SUM_G_SENT = "Envoyée", SUM_G_UNKNOWN = "Pas encore de réponse", SUM_G_WAIT = "En attente",
    SUM_G_PRE_TT = "Il lui manque : %s", SUM_G_UNKNOWN_TT = "Pas encore de réponse du jeu pour %s : partage la quête pour la voir.",
    SUM_G_SENT_TT = "Quête envoyée : en attente de la réponse de %s.", SUM_G_PUSH_TT = "D'après la réponse du jeu au partage.",
    SUM_G_NA_TT = "Cette quête n'est pas pour sa classe, sa faction ou sa race.",
    SUM_G_WAIT_TT = "%s a WL Helper : sa réponse n'est pas encore arrivée.",
    SUM_OTHER_SHORT = "Autre donjon", SUM_RW_MORE = "Autres récompenses",
    SUM_PICK_GO_TT = "Clic : voir le résumé des quêtes (XP, récompenses, chaînes, groupe) avant de lancer la route",
    SUM_IT1 = "%d objet", SUM_IT = "%d objets",
    SUM_IT_UP1 = "%s dont %d amélioration", SUM_IT_UP = "%s dont %d améliorations",
    SUM_UP_PCT = "+%d\194\160%%", SUM_UP_EMPTY = "vide", SUM_UP_EMPTY_TT = "Tu n'as rien à cet emplacement.",
    SUM_BEST = "Ton meilleur choix", SUM_BEST_TT = "Le meilleur choix pour ta spécialisation parmi les récompenses au choix.",
    SUM_RDY_OK1 = "Prêt : tu as la quête à prendre dehors", SUM_RDY_OK = "Prêt : tu as les %d quêtes à prendre dehors",
    SUM_RDY_NONE = "Prêt : aucune quête à prendre dehors",
    SUM_RDY_IN1 = "%d autre se prend dans le donjon", SUM_RDY_IN = "%d autres se prennent dans le donjon",
    SUM_RDY_INALL1 = "Ta quête se prend dans le donjon", SUM_RDY_INALL = "Tes quêtes se prennent toutes dans le donjon",
    SUM_RDY_MISS1 = "Il te manque %d quête à prendre avant d'entrer", SUM_RDY_MISS = "Il te manque %d quêtes à prendre avant d'entrer",
    SUM_RDY_AFTER = "après « %s »", SUM_RDY_MORE1 = "et %d autre", SUM_RDY_MORE = "et %d autres",
    SUM_ST_TAKE = "À prendre", SUM_ST_TAKE_TT = "Elle se prend dehors : prends-la avant d'entrer dans le donjon.",
    SUM_ST_IN = "Dans le donjon", SUM_ST_IN_TT = "Elle se prend dans le donjon : rien à faire avant d'entrer.",
  },
  en = {
    SUM_T = "Summary", SUM_ROUTE_T = "Route summary", SUM_DG1 = "%d dungeon", SUM_DG = "%d dungeons",
    SUM_SEL = "Your selection: %s", SUM_SEL0 = "No quest ticked yet.",
    SUM_Q1 = "%d quest", SUM_Q = "%d quests", SUM_XP = "%s XP",
    SUM_LV1 = "Lvl %d", SUM_LV = "Lvl %d-%d", SUM_SIZE = "Group of %d",
    SUM_CHAIN_LINE = "Chain: %d quests · %s XP in all",
    SUM_ELITE = "Elite", SUM_ELITE_TT = "An objective targets an elite: bring a group.",
    SUM_OTHER = "Other dungeon: %s", SUM_OTHER_TT = "One link of the chain happens in %s.",
    SUM_HIGH = "Level too high", SUM_HIGH_TT = "The chain goes up to level %d, more than 5 levels above you: unticked by default.",
    SUM_ST_ON = "In your log", SUM_ST_READY = "Ready to turn in", SUM_ST_DONE = "Turned in",
    SUM_TICK_OFF = "Click: leave this quest out of the route", SUM_TICK_ON = "Click: put this quest back in the route",
    SUM_TICK_OFF_CH = "Click: leave this quest and its %d prerequisites out of the route",
    SUM_TICK_ON_CH = "Click: put this quest and its %d prerequisites back in the route",
    SUM_EXPAND = "Click: show each quest of the chain", SUM_COLLAPSE = "Click: fold the chain",
    SUM_FDJ = "Note from ForeverDungeonJournal", SUM_LFD = "Steps (LibForeverData)",
    SUM_TODO = "Quests to do",
    SUM_DONE_H = "Already turned in (%d)", SUM_DONE_OPEN = "Click: show the quests already turned in", SUM_DONE_CLOSE = "Click: fold the quests already turned in",
    SUM_ALLDONE_T = "Every quest turned in: %s", SUM_ALLDONE_TN = "You already turned in every quest of these dungeons",
    SUM_ALLDONE_NOTE = "%s: every quest is already turned in.",
    SUM_OTHER_DG = "Pick another dungeon",
    SUM_RUN = "Guide me through the dungeon", SUM_RUN_N = "Guide me through the dungeons",
    SUM_RUN_TT = "Click: open the guide, from the entrance to the last boss, one boss at a time",
    SUM_RUN_SUB = "The guide can still lead you from the entrance to the last boss.",
    SUM_RUN_SUB_N = "The guide can still lead you through each dungeon, boss by boss.",
    SUM_BACK_PICK = "Back to the picker", SUM_BACK_PICK_TT = "Click: go back to the dungeon picker without starting the route",
    SUM_GO_HERE = "Start the route here", SUM_GO_CONFIRM = "Replace the route?",
    SUM_GO_HERE_TT = "Click: replace the running route with this dungeon only and the ticked quests (steps marked done by hand are lost; a 2nd click confirms)",
    SUM_EXTRA1 = "Also in the group: %s (their state is in each quest's tooltip)",
    SUM_EXTRA = "Also in the group: %s (their state is in each quest's tooltip)",
    SUM_COL_TT = "One icon per quest: hover it for the detail",
    SUM_GO = "Start the route", SUM_GO_TT = "Click: close the summary and open the guide on the first step, with the ticked quests",
    SUM_GO_TT1 = "Click: start the route with this dungeon only and the ticked quests (replaces your picked dungeons)",
    SUM_GO_WHY = "Tick at least one quest to do.", SUM_CLOSE = "Close", SUM_CLOSE_TT = "Click: close the summary without starting the route",
    SUM_UPDATE = "Update the route", SUM_UPDATE_TT = "Click: go back to the guide, the route follows your new ticks",
    SUM_BACK = "Back to the route", SUM_BACK_TT = "Click: go back to the guide where you left it",
    SUM_SHARE = "Share", SUM_SHARED = "Shared", SUM_SHARE_TT = "Click: share \"%s\" with the group",
    SUM_SHARE_ALL = "Share all", SUM_SHARE_ALL_TT = "Click: share the ticked quests of your log with the group, one every 1.5 s",
    SUM_SHARE_WHY = "No ticked quest in your log can be shared.", SUM_SHARING = "Sharing",
    SUM_NOQ = "No quest for you in this dungeon.",
    SUM_NOHELPER1 = "Without WL Helper: %s (their state shows when you share)",
    SUM_NOHELPER = "Without WL Helper: %s (their state shows when you share)",
    SUM_G_ON = "Has it in their log", SUM_G_READY = "Ready to turn in", SUM_G_DONE = "Already turned in", SUM_G_TAKE = "To pick up",
    SUM_G_PRE = "Missing prerequisite", SUM_G_LOW = "Level too low", SUM_G_NA = "Not for this character", SUM_G_INVALID = "Not eligible",
    SUM_G_DECLINED = "Declined", SUM_G_FULL = "Log full", SUM_G_BUSY = "Busy", SUM_G_FAR = "Too far",
    SUM_G_SENT = "Sent", SUM_G_UNKNOWN = "No answer yet", SUM_G_WAIT = "Waiting",
    SUM_G_PRE_TT = "Missing link: %s", SUM_G_UNKNOWN_TT = "No answer from the game for %s yet: share the quest to see it.",
    SUM_G_SENT_TT = "Quest sent: waiting for %s's answer.", SUM_G_PUSH_TT = "From the game's answer to the share.",
    SUM_G_NA_TT = "This quest is not for their class, faction or race.",
    SUM_G_WAIT_TT = "%s has WL Helper: their reply has not arrived yet.",
    SUM_OTHER_SHORT = "Other dungeon", SUM_RW_MORE = "More rewards",
    SUM_PICK_GO_TT = "Click: see the quests' summary (XP, rewards, chains, group) before starting the route",
    SUM_IT1 = "%d item", SUM_IT = "%d items",
    SUM_IT_UP1 = "%s including %d upgrade", SUM_IT_UP = "%s including %d upgrades",
    SUM_UP_PCT = "+%d%%", SUM_UP_EMPTY = "empty", SUM_UP_EMPTY_TT = "You wear nothing in this slot.",
    SUM_BEST = "Your best pick", SUM_BEST_TT = "The best of the rewards to choose from for your spec.",
    SUM_RDY_OK1 = "Ready: you have the quest to pick up outside", SUM_RDY_OK = "Ready: you have all %d quests to pick up outside",
    SUM_RDY_NONE = "Ready: no quest to pick up outside",
    SUM_RDY_IN1 = "%d more is picked up inside the dungeon", SUM_RDY_IN = "%d more are picked up inside the dungeon",
    SUM_RDY_INALL1 = "Your quest is picked up inside the dungeon", SUM_RDY_INALL = "Your quests are all picked up inside the dungeon",
    SUM_RDY_MISS1 = "%d quest still to pick up before you go in", SUM_RDY_MISS = "%d quests still to pick up before you go in",
    SUM_RDY_AFTER = "after \"%s\"", SUM_RDY_MORE1 = "and %d more", SUM_RDY_MORE = "and %d more",
    SUM_ST_TAKE = "To pick up", SUM_ST_TAKE_TT = "Given outside: pick it up before you go into the dungeon.",
    SUM_ST_IN = "Inside the dungeon", SUM_ST_IN_TT = "Given inside the dungeon: nothing to do before you go in.",
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
--  Sizes (design system: window 640, inset 16, rows 8, pills 18, group cells 64)
-- =====================================================================
local W, PAD = 640, 16
local CW = W - 2 * PAD          -- content width
local HERO_H, HERO_H_MULTI = 96, 72
local ROW_GAP = 4
local TX = 32                   -- text column of a row (after the check box)
local CELLW, MAXCOLS = 64, 4    -- group columns (one icon each)
local MAX_REWARDS = 4            -- reward icons per row (the last one is "+N" when there are more)
local RW_SIZE, RW_STEP = 30, 40   -- a reward icon, and icon + gap (the "+12 %" under it fits the gap)
local RW_LABEL = 14               -- the line under an icon: arrow and gain
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

-- WL Helper Gear (the gear scoring addon), when it is loaded: its quest rewards and its comparison.
local function Gear()
  local G = _G.WLHelperGear
  return (type(G) == "table" and type(G.Compare) == "function") and G or nil
end

-- Rewards: item ids read live from LibForeverData when it is loaded (it says which are a choice).
-- Else our data's item names (q.ri, all a choice when q.rc) merged with WL Helper Gear's item ids
-- (QuestieDB): a name Gear gives for one of its ids (English, like ours) takes that id; Gear's
-- other ids follow. Gear does not say which rewards are a choice: q.rc does for every one.
local rewardCache = {}
local function GearRewards(qid)
  local G = Gear()
  if not (G and type(G.QuestRewards) == "function" and qid > 0) then return nil end
  local ok, ids, names = pcall(G.QuestRewards, qid)
  if ok and type(ids) == "table" and #ids > 0 then return ids, type(names) == "table" and names or {} end
  return nil
end
local function CachedName(id)
  if not GetItemInfo then return nil end
  local ok, n = pcall(GetItemInfo, id)
  return ok and type(n) == "string" and not secret(n) and n or nil
end
local function Loose(s) return (s:lower():gsub("[%p%s]", "")) end
-- Item name -> id from LibForeverData's item list (built once, on the first name neither source
-- matched): a reward known only by its name still gets its real icon, quality and comparison.
local libItemIds
local function LibItemId(n)
  if libItemIds == nil then
    libItemIds = false
    local lib = Lib()
    if lib and type(lib.Ids) == "function" and type(lib.Name) == "function" then
      local ok, ids = pcall(lib.Ids, "item")
      if ok and type(ids) == "table" then
        libItemIds = {}
        for _, id in ipairs(ids) do
          local okN, nm = pcall(lib.Name, "item", id)
          if okN and type(nm) == "string" and nm ~= "" then
            local k = nm:lower()
            if not libItemIds[k] then libItemIds[k] = id end
          end
        end
      end
    end
  end
  return libItemIds and libItemIds[n:lower()] or nil
end
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
  if #out == 0 then
    local ids, names = GearRewards(qid)
    ids, names = ids or {}, names or {}
    local ri = q.ri or {}
    -- by the exact name (any case), then loosely (no punctuation, no spaces): Gear's English name
    -- and the client's cached name both count
    local byName, byLoose, used = {}, {}, {}
    for _, id in ipairs(ids) do
      for _, n in ipairs({ names[id], CachedName(id) }) do
        if type(n) == "string" then
          byName[n:lower()] = byName[n:lower()] or id
          local lo = Loose(n)
          if lo ~= "" then byLoose[lo] = byLoose[lo] or id end
        end
      end
    end
    local choice = q.rc == true
    local unmatched = 0
    for i, n in ipairs(ri) do
      local id = byName[n:lower()]
      if id and used[id] then id = nil end
      if not id then id = byLoose[Loose(n)]; if id and used[id] then id = nil end end
      if id then used[id] = true else unmatched = unmatched + 1 end
      out[i] = { id = id, name = n, choice = choice }
    end
    -- as many names as ids: a name still unmatched takes the id at its place
    if unmatched > 0 and #ri == #ids then
      for i, rw in ipairs(out) do
        local id = ids[i]
        if not rw.id and not used[id] then rw.id = id; used[id] = true; unmatched = unmatched - 1 end
      end
    end
    -- still nameless of an id: LibForeverData's item list
    if unmatched > 0 then
      for _, rw in ipairs(out) do
        if not rw.id and rw.name then
          local id = LibItemId(rw.name)
          if id and not used[id] then rw.id = id; used[id] = true; unmatched = unmatched - 1 end
        end
      end
    end
    -- Gear's other ids follow, unless a name is still unmatched and Gear has no more ids than our
    -- names (that id is most likely the same item under another name: it would show twice)
    if unmatched == 0 or #ids > #ri then
      for _, id in ipairs(ids) do
        if not used[id] then used[id] = true; out[#out + 1] = { id = id, name = names[id], choice = choice } end
      end
    end
  end
  rewardCache[qid] = out
  return out
end
-- for the tests: the rewards of a quest, read again (and the item list built again) when fresh
ns.SummaryRewards = function(qid, q, fresh)
  if fresh then rewardCache[qid] = nil; libItemIds = nil end
  return Rewards(qid, q)
end
-- How many items the quest gives you (one for a reward of your choice).
local function ItemCount(qid, q)
  local n, choice = 0, false
  for _, rw in ipairs(Rewards(qid, q)) do if rw.choice then choice = true else n = n + 1 end end
  return n + (choice and 1 or 0)
end

-- Per render (wiped by Render): the item facts and the comparisons, read once even when the totals
-- and the rows both ask. pendingItems: ids whose data has not come yet (GET_ITEM_INFO_RECEIVED for
-- one of them renders again); pendingName: a reward known by name only, or an item you wear, is
-- not cached yet (any item arriving renders again).
-- requestedItems / failedItems (kept for the session): an id is asked for at most once, and one
-- the server does not know (GET_ITEM_INFO_RECEIVED with success false) is never asked again nor
-- waited for, so an unknown id cannot make the summary render over and over.
local infoCache, upCache, bestCache = {}, {}, {}
local pendingItems, pendingName = {}, false
local requestedItems, failedItems = {}, {}
local function ResetRenderCaches()
  wipe(infoCache); wipe(upCache); wipe(bestCache)
end

-- icon, link, quality of a reward (the question mark until the item is cached)
local function ItemInfo(rw)
  local key = rw.id or rw.name
  local c = key and infoCache[key]
  if c then return c[1], c[2], c[3] end
  local icon, link, quality
  if rw.id then
    local ok, ic = pcall(function() return (C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(rw.id)) or (GetItemIcon and GetItemIcon(rw.id)) end)
    if ok then icon = ic end
  end
  if GetItemInfo and key then
    local ok, _, l, qu, _, _, _, _, _, _, tex = pcall(GetItemInfo, key)
    if ok then link = type(l) == "string" and not secret(l) and l or nil; quality = num(qu); icon = icon or tex end
  end
  if not quality and rw.id and C_Item and C_Item.GetItemQualityByID then
    local ok, qu = pcall(C_Item.GetItemQualityByID, rw.id)
    if ok then quality = num(qu) end
  end
  if not link then
    if rw.id then
      if not failedItems[rw.id] then
        pendingItems[rw.id] = true
        if not requestedItems[rw.id] then
          requestedItems[rw.id] = true
          if C_Item and C_Item.RequestLoadItemDataByID then pcall(C_Item.RequestLoadItemDataByID, rw.id) end
        end
      end
    else pendingName = true end
  end
  icon = icon or "Interface\\Icons\\INV_Misc_QuestionMark"
  if key then infoCache[key] = { icon, link, quality } end
  return icon, link, quality
end

-- The quality colour of an item's border (common and poor keep the card edge).
local function QualityColor(quality)
  if not quality or quality < 2 then return nil end
  if GetItemQualityColor then
    local ok, r, g, b = pcall(GetItemQualityColor, quality)
    if ok and num(r) and num(g) and num(b) then return { r, g, b, 1 } end
  end
  local c = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality]
  if type(c) == "table" and c.r then return { c.r, c.g, c.b, 1 } end
  return nil
end

-- The gear check of the Writs module (no WL Helper Gear): { up, text }.
local function Upgrade(link)
  local WP = ns.Writs and ns.Writs.WP
  if not (link and WP and WP.UpgradeCheck) then return nil end
  local ok, r = pcall(WP.UpgradeCheck, link)
  if ok and type(r) == "table" and r.up then return r.text or "" end
  return nil
end

local function UpMin()
  local m = WLWritsDB and num(WLWritsDB.upgradeMin)
  return m and m > 0 and m or 1
end

-- Is a reward an upgrade for your spec? { up, pct, empty, text, rank, score }: rank orders the
-- choices (higher is better; nil when the item is not for you or can't be read), score is the
-- item's score for your spec when there is no comparison. WLHelperGear.Compare first (percent
-- against what you wear), else the Writs gear check.
-- The level a quest's rewards are judged at: the quest's level (else its required level) when it
-- is above yours, since you only get its items once you reach it.
local function RewardLevel(q)
  local ql = q and (num(q.l) or num(q.r)) or nil
  return math.max(Level(), ql or 0)
end

-- The gain shown under the icon is capped (a 3-digit gain would run into the next icon); the
-- tooltip keeps the exact figure.
local LABEL_MAX = 99
local NOUP = {}
local function UpInfo(rw, lvl)
  local _, link = ItemInfo(rw)
  local what = link or rw.id
  if not what then return NOUP end
  lvl = lvl or Level()
  local key = tostring(what) .. "@" .. lvl
  local c = upCache[key]
  if c then return c end
  local res = {}
  local G = Gear()
  if G then
    local ok, r = pcall(G.Compare, what, lvl)
    if ok and type(r) == "table" then
      if r.unknown then pendingName = true end   -- what you wear is not read yet: any item may be it
      local usable = r.canUse == true and not r.blocked and not r.unscored and not r.unknown and not r.equipped
      local pct = num(r.pct)
      if usable and r.empty then res.up, res.empty, res.rank = true, true, math.huge
      elseif usable and pct then
        res.rank = num(r.pctExact) or pct
        if pct >= UpMin() then res.up, res.pct = true, pct end
      end
    end
    -- a choice still needs a rank when the comparison has none: the item's score for your spec
    if res.rank == nil and rw.choice and type(G.Score) == "function" then
      local ok2, sc, d = pcall(G.Score, what, lvl)
      if ok2 and num(sc) and sc > 0 and type(d) == "table" and d.canUse == true then res.score = sc end
    end
  elseif link then
    local t = Upgrade(link)
    if t then res.up, res.text = true, t end
  end
  if res.up and not res.text then
    if res.empty then res.text = L.SUM_UP_EMPTY
    else
      local p = math.floor(res.pct + 0.5)
      res.text = L.SUM_UP_PCT:format(p)
      if p > LABEL_MAX then res.short = L.SUM_UP_PCT:format(LABEL_MAX) end
    end
  end
  upCache[key] = res
  return res
end

-- The best of a quest's rewards to choose from for you (its index in the list), or nil: the best
-- comparison, else the best score; nil with fewer than two choices or nothing for you.
local function BestChoice(qid, list, lvl)
  local c = bestCache[qid]
  if c ~= nil then return c or nil end
  local n, best, bestRank, bestScore = 0, nil, nil, nil
  for i, rw in ipairs(list) do
    if rw.choice then
      n = n + 1
      local u = UpInfo(rw, lvl)
      if u.rank and (not bestRank or u.rank > bestRank) then best, bestRank = i, u.rank
      elseif not bestRank and u.score and (not bestScore or u.score > bestScore) then best, bestScore = i, u.score end
    end
  end
  if n < 2 then best = nil end
  bestCache[qid] = best or false
  return best
end

-- How many of a quest's items are upgrades (one at most for the rewards to choose from).
local function UpCount(qid, q)
  local n, choiceUp, lvl = 0, false, RewardLevel(q)
  for _, rw in ipairs(Rewards(qid, q)) do
    if UpInfo(rw, lvl).up then if rw.choice then choiceUp = true else n = n + 1 end end
  end
  return n + (choiceUp and 1 or 0)
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

-- The guide's route runs on some picked dungeons (other than these, when RouteRuns is false).
local function RouteElsewhere()
  if not (ns.route and ns.frame and WLDTDB.sel) then return false end
  for k, v in pairs(WLDTDB.sel) do if v and ns.D[k] then return true end end
  return false
end

-- The running route walks these dungeons through (WLDTDB.run) and still has a step to do.
local function RunGoing(keys)
  local any = false
  for _, k in ipairs(keys) do if WLDTDB.run and WLDTDB.run[k] then any = true end end
  if not any or not ns.route or not ns.IsStepDone then return false end
  local log = ns.LogEntries and ns.LogEntries() or {}
  for i = 1, #ns.route.steps do if not ns.IsStepDone(log, i) then return true end end
  return false
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
  -- the running route follows at once; the main button then says "Update the route"
  if f then f.changed = true end
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
--  Group: one column per member whose state is known, the others on one line
-- =====================================================================
-- state -> word (tooltip), HD icon, colour token, a second check (ready to turn in)
local CELL = {
  on = { "SUM_G_ON", "check", "ok" }, ready = { "SUM_G_READY", "check", "gold", true }, done = { "SUM_G_DONE", "check", "faint" },
  take = { "SUM_G_TAKE", "warning", "warn" }, pre = { "SUM_G_PRE", "close", "bad" }, low = { "SUM_G_LOW", "warning", "warn" },
  na = { "SUM_G_NA", "minus", "faint" }, invalid = { "SUM_G_INVALID", "close", "bad" }, declined = { "SUM_G_DECLINED", "minus", "warn" },
  full = { "SUM_G_FULL", "warning", "warn" }, busy = { "SUM_G_BUSY", "clock", "muted" }, far = { "SUM_G_FAR", "clock", "muted" },
  sent = { "SUM_G_SENT", "clock", "muted" }, unknown = { "SUM_G_UNKNOWN", "dot", "faint" },
  wait = { "SUM_G_WAIT", "clock", "muted" },
}

local function Members()
  if not ns.GroupMembers then return {} end
  return ns.GroupMembers()
end

local function ClassColor(cls)
  if not cls then return T.fg end
  local _, c = ns.ClassInfo(cls)
  return c
end

-- Members whose quests are known (WL Helper, or the game's answers to a share) get a column (4 at
-- most); the others are named once. Known members past the 4 columns (a raid) are named on their
-- own line, their state in each quest's tooltip.
local function SplitMembers(members)
  local known, others, extra = {}, {}, {}
  for _, m in ipairs(members) do
    local k
    if ns.MemberKnown then k = ns.MemberKnown(m.name) else k = ns.HasHelper and ns.HasHelper(m.name) end
    if not k then others[#others + 1] = m
    elseif #known < MAXCOLS then known[#known + 1] = m
    else extra[#extra + 1] = m end
  end
  return known, others, extra
end

-- =====================================================================
--  Widgets
-- =====================================================================
local function MakeReward(parent)
  local b = CreateFrame("Button", nil, parent)
  b:SetSize(RW_SIZE, RW_SIZE)
  b.wlOwned = true
  b.tex = b:CreateTexture(nil, "ARTWORK"); b.tex:SetPoint("TOPLEFT", 1, -1); b.tex:SetPoint("BOTTOMRIGHT", -1, 1)
  b.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  -- 1 px border in the item's quality colour (card edge for common items)
  b.edge = ns.Outline(b, T.cardEdge)
  -- the best of the rewards to choose from: a gold ring 2 px outside the icon and a star
  b.ring = CreateFrame("Frame", nil, b); b.ring:SetPoint("TOPLEFT", -2, 2); b.ring:SetPoint("BOTTOMRIGHT", 2, -2)
  ns.Outline(b.ring, T.gold); b.ring:Hide()
  b.star = ns.Icon(b, "star", 12, "OVERLAY", T.gold); b.star:SetPoint("TOPLEFT", -4, 4); b.star:Hide()
  -- an upgrade: the green arrow and the gain under the icon ("+12 %")
  b.pct = ns.Text(b, ns.F.foot, T.ok); b.pct:SetPoint("TOP", b, "BOTTOM", 6, -2); b.pct:Hide()
  if b.pct.SetWordWrap then b.pct:SetWordWrap(false) end
  b.up = ns.Icon(b, "arrow_up", 10, "OVERLAY", T.ok); b.up:SetPoint("RIGHT", b.pct, "LEFT", -1, 0); b.up:Hide()
  b:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:ClearLines()
    local shown = false
    if self.id and GameTooltip.SetItemByID then shown = pcall(GameTooltip.SetItemByID, GameTooltip, self.id)
    elseif self.link and GameTooltip.SetHyperlink then shown = pcall(GameTooltip.SetHyperlink, GameTooltip, self.link) end
    if not shown then GameTooltip:AddLine(self.name or "?", T.fg[1], T.fg[2], T.fg[3], true) end
    if self.choice then GameTooltip:AddLine(L.OV_CHOICE, T.muted[1], T.muted[2], T.muted[3], true) end
    if self.best then GameTooltip:AddLine(L.SUM_BEST, T.gold[1], T.gold[2], T.gold[3], true) end
    if self.upText then GameTooltip:AddLine(L.OV_UPGRADE .. (self.upText ~= "" and (" " .. self.upText) or ""), T.ok[1], T.ok[2], T.ok[3], true) end
    if self.upEmpty then GameTooltip:AddLine(L.SUM_UP_EMPTY_TT, T.muted[1], T.muted[2], T.muted[3], true) end
    if self.link then GameTooltip:AddLine(L.TT_SHIFT_LINK, (T.hint or T.muted)[1], (T.hint or T.muted)[2], (T.hint or T.muted)[3], true) end
    GameTooltip:Show()
  end)
  b:SetScript("OnLeave", function() GameTooltip:Hide() end)
  b:SetScript("OnClick", function(self)
    if self.link and HandleModifiedItemClick then pcall(HandleModifiedItemClick, self.link) end
  end)
  return b
end

-- One reward icon: the item, its quality border, the upgrade (arrow and gain), the best choice.
-- Returns true when it shows a line under the icon.
local function FillReward(b, rw, best, lvl)
  local icon, link, quality = ItemInfo(rw)
  local u = UpInfo(rw, lvl)
  b.id, b.name, b.link, b.choice, b.best = rw.id, rw.name, link, rw.choice, best
  b.tex:SetTexture(icon)
  b.quality = quality
  b.edge(QualityColor(quality) or T.cardEdge)
  b.ring:SetShown(best == true); b.star:SetShown(best == true)
  b.upText, b.upEmpty = u.up and (u.text or "") or nil, u.empty == true
  if u.up then
    b.pct:SetText(u.short or u.text or ""); b.pct:Show(); b.up:Show()
  else b.pct:Hide(); b.up:Hide() end
  return u.up == true
end

-- A group cell: one HD icon (two checks when ready); the member, the state and the detail in the tooltip.
local function MakeCell(parent)
  local c = CreateFrame("Frame", nil, parent)
  c:SetSize(CELLW, 18)
  c:EnableMouse(true)
  c.icon = ns.Icon(c, "dot", 16, "ARTWORK", T.muted); c.icon:SetPoint("CENTER", 0, 0)
  c.icon2 = ns.Icon(c, "check", 16, "ARTWORK", T.gold); c.icon2:SetPoint("CENTER", 5, 0); c.icon2:Hide()
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
  -- ready to turn in: two gold checks, 10 px apart (one green check is "in the log")
  c.icon:ClearAllPoints(); c.icon:SetPoint("CENTER", look[4] and -5 or 0, 0)
  if look[4] then ns.SetHDIcon(c.icon2, "check", col) end
  c.icon2:SetShown(look[4] == true)
  c.state, c.who = s, m.name
  local cc = ClassColor(m.class)
  local tip = { { m.name, cc[1], cc[2], cc[3] }, L[look[1]] }
  if wait then tip[2] = L.SUM_G_WAIT_TT:format(m.name)
  elseif s == "unknown" then tip[2] = L.SUM_G_UNKNOWN_TT:format(m.name) end
  if s == "pre" and pid then tip[#tip + 1] = L.SUM_G_PRE_TT:format(ns.QName(pid)) end
  if s == "sent" then tip[#tip + 1] = L.SUM_G_SENT_TT:format(m.name) end
  if s == "na" then tip[#tip + 1] = L.SUM_G_NA_TT end
  if src == "push" and s ~= "sent" then tip[#tip + 1] = L.SUM_G_PUSH_TT end
  c.tip = tip
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

-- One quest still to pick up before going in: pin (or clock while it cannot be taken yet), its name
-- and what it waits on; hover for the giver and where, a click guides to the giver.
local function MakeReadyLine(parent)
  local o = CreateFrame("Button", nil, parent)
  o.wlOwned = true
  o.hl = ns.Tex(o, "BACKGROUND", T.hoverFill); o.hl:SetAllPoints(); o.hl:Hide()
  o.press = ns.Tex(o, "BORDER", T.pressFill); o.press:SetAllPoints(); o.press:Hide()
  o.icon = ns.Icon(o, "pin", 12, "ARTWORK", T.accentSoft); o.icon:SetPoint("TOPLEFT", 0, -2)
  o.text = ns.Text(o, ns.F.meta, T.text); o.text:SetPoint("TOPLEFT", 16, -1)
  o:SetScript("OnEnter", function(self)
    if self.point then self.hl:Show() end
    if self.tip then ns.ShowTip(self, self.tip) end
  end)
  o:SetScript("OnLeave", function(self) self.hl:Hide(); self.press:Hide(); self.text:SetPoint("TOPLEFT", 16, -1); ns.HideTip() end)
  o:SetScript("OnMouseDown", function(self) if self.point then self.press:Show(); self.text:SetPoint("TOPLEFT", 16, -2) end end)
  o:SetScript("OnMouseUp", function(self) self.press:Hide(); self.text:SetPoint("TOPLEFT", 16, -1) end)
  o:SetScript("OnClick", function(self) if self.point then GoPoint(self.point) end end)
  return o
end

-- What a quest given outside waits on before it can be taken: its next prerequisite, else its level.
local function TakeWhy(log, qid, q, lvl, cls)
  local pre = ns.QuestPreInfo(qid, log, cls)
  if pre.nextPid then return L.SUM_RDY_AFTER:format(ns.QName(pre.nextPid)), pre end
  if q.r and q.r > lvl then return L.ST_LOW:format(q.r), pre end
  return nil, pre
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

-- the state words of the unfolded links
local LINK_WORD = { none = "SUM_G_TAKE", on = "SUM_ST_ON", ready = "SUM_ST_READY", done = "SUM_ST_DONE" }

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
    -- the members past the 4 columns: their state here
    for _, m in ipairs(f and f.extraCols or {}) do
      local s = ns.MemberQuest and ns.MemberQuest(m.name, qid, r.dkey) or "unknown"
      local look = CELL[s] or CELL.unknown
      local cc = ClassColor(m.class)
      table.insert(lines, { m.name .. L.COLON .. L[look[1]], cc[1], cc[2], cc[3] })
    end
    if IsOff(qid) then table.insert(lines, n > 0 and L.SUM_TICK_ON_CH:format(n) or L.SUM_TICK_ON)
    else table.insert(lines, n > 0 and L.SUM_TICK_OFF_CH:format(n) or L.SUM_TICK_OFF) end
  end
  ns.ShowTip(r, lines)
end

local ROW_TOP = 8   -- the name's top inset; the check box and the group icons sit on its first line

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
  r.boxF = CreateFrame("Frame", nil, r); r.boxF:SetSize(16, 16); r.boxF:SetPoint("TOPLEFT", 8, -ROW_TOP)
  r.box = ns.Tex(r.boxF, "BACKGROUND", T.panel); r.box:SetAllPoints()
  r.boxEdge = ns.Outline(r.boxF, T.btnEdge)
  r.tick = ns.Icon(r.boxF, "check", 12, "ARTWORK", T.fg); r.tick:SetPoint("CENTER")
  r.doneIcon = ns.Icon(r, "check", 16, "ARTWORK", T.faint); r.doneIcon:SetPoint("TOPLEFT", 8, -ROW_TOP); r.doneIcon:Hide()
  r.name = ns.Text(r, ns.F.body, T.fg)
  r.detail = ns.Text(r, ns.F.meta, T.muted)
  -- the chain line: chevron + "Chain: 10 quests · 31,500 XP in all"; a click unfolds it
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
  r.more:SetSize(RW_SIZE, RW_SIZE); r.more:EnableMouse(true); r.more:Hide()
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
    self.name:SetPoint("TOPLEFT", TX, -ROW_TOP - dy)
    self.boxF:SetPoint("TOPLEFT", 8, -ROW_TOP - dy)
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

-- Hides what a row turned in does not show.
local function HideExtras(r)
  r.chain:Hide(); r.share:Hide(); r.gps:Hide(); r.more:Hide()
  for _, p in ipairs(r.pills) do p:Hide() end
  for _, b in ipairs(r.rewards) do b:Hide() end
  for _, l in ipairs(r.links) do l:Hide() end
  for _, c in ipairs(r.cells) do c:Hide() end
end

-- Fills one quest row; returns its height.
local function FillRow(r, qid, dkey, inf, ctx)
  local q = inf.q
  local log = ctx.log
  local st, pre = inf.st, inf.pre
  local done = st == "done"
  local off = IsOff(qid)
  r.qid, r.dkey, r.st, r.pre, r.low = qid, dkey, st, pre, inf.low
  r.point = (not done) and PointFor(log, qid, q, st, pre) or nil

  -- check box (a quest turned in shows a grey check instead)
  r.boxF:SetShown(not done); r.doneIcon:SetShown(done)
  r.tick:SetShown(not off)
  r.boxEdge(off and T.btnEdge or T.accent)

  -- the group's columns take the right side of a quest still to do
  local cols = done and {} or ctx.cols
  local ncol = #cols
  local right = 12 + (ncol > 0 and (ncol * CELLW + 8) or 0)
  local wide = CW - TX - right
  r.wide = wide

  -- the name in the game's quest colour against your level; muted when left out or turned in
  r.name:SetText(ns.QName(qid))
  local nc = (off or done) and T.muted or SW().LevelColor(q.l or q.r)
  r.name:SetTextColor(nc[1], nc[2], nc[3])
  r.name:ClearAllPoints(); r.name:SetPoint("TOPLEFT", TX, -ROW_TOP)
  local y = ROW_TOP + LineH(r.name, ns.F.body, wide, r)

  -- one muted line: level · XP · money
  local d = {}
  if q.l then d[#d + 1] = L.SUM_LV1:format(q.l) end
  if inf.xp > 0 then d[#d + 1] = L.SUM_XP:format(Big(inf.xp)) end
  if inf.money > 0 then d[#d + 1] = Money(inf.money) end
  if #d > 0 then
    r.detail:SetText(table.concat(d, " · "))
    r.detail:ClearAllPoints(); r.detail:SetPoint("TOPLEFT", TX, -(y + 3))
    r.detail:Show()
    y = y + 3 + LineH(r.detail, ns.F.meta, wide, r)
  else r.detail:Hide() end

  if done then
    HideExtras(r)
    local h = math.ceil(math.max(y + 8, 36))
    r:SetHeight(h)
    return h
  end

  -- pills only when they say something: in your log / ready, elite, another dungeon, too high
  local pills = {}
  if st == "on" then pills[#pills + 1] = { L.SUM_ST_ON, T.info, nil, { L.SUM_ST_ON } }
  elseif st == "ready" then pills[#pills + 1] = { L.SUM_ST_READY, T.ok, "check", { L.SUM_ST_READY } }
  elseif st == "none" and ctx.peBefore and ctx.peBefore[qid] then
    -- on the guide's "before entering" list: given outside, to pick up before going in
    local tip = { L.SUM_ST_TAKE, L.SUM_ST_TAKE_TT }
    local g = GiverText(q, st)
    if g then tip[#tip + 1] = g end
    local why = TakeWhy(log, qid, q, ctx.lvl, ctx.cls)
    if why then tip[#tip + 1] = { why, T.warn[1], T.warn[2], T.warn[3] } end
    pills[#pills + 1] = { L.SUM_ST_TAKE, T.warn, nil, tip }
  elseif st == "none" and ctx.peInside and ctx.peInside[qid] then
    pills[#pills + 1] = { L.SUM_ST_IN, T.muted, "portal", { L.SUM_ST_IN, L.SUM_ST_IN_TT } }
  end
  if inf.elite then pills[#pills + 1] = { L.SUM_ELITE, T.warn, "skull", { L.SUM_ELITE, L.SUM_ELITE_TT } } end
  if inf.other then
    local dn = ns.DName(inf.other)
    pills[#pills + 1] = { L.SUM_OTHER:format(dn), T.info, "portal", { L.SUM_OTHER:format(dn), L.SUM_OTHER_TT:format(dn) }, L.SUM_OTHER_SHORT }
  end
  if inf.high then
    local lv = inf.low or inf.maxL
    pills[#pills + 1] = { L.SUM_HIGH, T.warn, "warning", { L.SUM_HIGH, inf.low and L.ST_LOW:format(inf.low) or L.SUM_HIGH_TT:format(lv) } }
  end
  if #pills > 0 then y = PlacePills(r, pills, TX, y + 6, wide) else PlacePills(r, {}, TX, y, wide) end

  -- the chain block, unfoldable: "Chain: 10 quests · 31,500 XP in all"
  local hasChain = pre.total > 0
  if hasChain then
    r.chain.text:SetText(L.SUM_CHAIN_LINE:format(inf.chainN, Big(inf.chainXP)))
    ns.SetHDIcon(r.chain.chev, f.open[qid] and "chevron_down" or "chevron_right", T.accentSoft)
    local th = LineH(r.chain.text, ns.F.meta, wide - 16, r.chain)
    r.chain:SetSize(wide, th + 2)
    r.chain:ClearAllPoints(); r.chain:SetPoint("TOPLEFT", TX, -(y + 6))
    r.chain:Show()
    y = y + 6 + th + 2
  else r.chain:Hide() end

  -- the actions at the right (GPS, share), then up to 4 reward icons (30 px) as the room left
  -- holds; the others behind a "+N" marker
  r.shareId = ctx.grouped and ShareTarget(qid, pre, log) or nil
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
  local list = Rewards(qid, q)
  local slots = math.max(1, math.min(MAX_REWARDS, math.floor((rightX - TX + RW_STEP - RW_SIZE) / RW_STEP)))
  local showN = #list
  if showN > slots then showN = slots - 1 end
  local rwLvl = RewardLevel(q)
  local bestI = BestChoice(qid, list, rwLvl)
  local n, labels = 0, false
  for i = 1, showN do
    n = n + 1
    local b = r.rewards[n] or MakeReward(r); r.rewards[n] = b
    if FillReward(b, list[i], bestI == i, rwLvl) then labels = true end
    b:ClearAllPoints(); b:SetPoint("TOPLEFT", TX + (n - 1) * RW_STEP, -actY)
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
      if rw.id then nm = CachedName(rw.id) or nm end
      local u = UpInfo(rw, rwLvl)
      local line = "- " .. (nm or "?")
      if bestI == i then line = line .. " (" .. L.SUM_BEST .. ")" end
      if u.up then line = { line .. " " .. (u.text or ""), T.ok[1], T.ok[2], T.ok[3] } end
      names[#names + 1] = line
    end
    r.more.tip = names
    r.more:ClearAllPoints(); r.more:SetPoint("TOPLEFT", TX + showN * RW_STEP, -actY)
    r.more:Show()
  else r.more:Hide() end
  r.rwLabels = labels
  if #list > 0 then y = y + 6 + math.max(24, RW_SIZE + (labels and RW_LABEL or 0))
  elseif r.point or r.shareId then y = y + 6 + 24 end

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
        local word = L[LINK_WORD[ls] or LINK_WORD.none]
        local icon, col = "dot", T.faint
        if ls == "done" then icon, col = "check", T.faint elseif ls == "ready" then icon, col = "check", T.ok elseif ls == "on" then icon, col = "clock", T.info end
        ns.SetHDIcon(b.icon, icon, col)
        local parts = { ns.QName(id) .. (id == qid and (" (" .. L.OV_THIS .. ")") or "") }
        if lq.l then parts[#parts + 1] = L.SUM_LV1:format(lq.l) end
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

  -- one icon per known member, at the right edge, on the name's first line
  for j, m in ipairs(cols) do
    local c = r.cells[j] or MakeCell(r); r.cells[j] = c
    FillCell(c, m, qid, dkey)
    c:ClearAllPoints(); c:SetPoint("TOPLEFT", r, "TOPLEFT", CW - 12 - (ncol - j + 1) * CELLW, -(ROW_TOP - 1))
    c:Show()
  end
  for j = ncol + 1, #r.cells do r.cells[j]:Hide() end

  local h = math.ceil(math.max(y + 8, 36))
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
  hero.lvl = ns.Text(hero, ns.F.meta, T.text, false, "SHADOW"); hero.lvl:SetPoint("BOTTOMLEFT", 12, 8)
  hero.name = ns.Text(hero, ns.F.heading, T.fg, false, "SHADOW"); hero.name:SetPoint("BOTTOMLEFT", hero.lvl, "TOPLEFT", 0, 3)
  return hero
end

-- "Quests to do 7", and over the group's columns, the members' names.
local function MakeHead(parent)
  local h = CreateFrame("Frame", nil, parent)
  h:SetSize(CW, 24)
  h.label = ns.Text(h, ns.F.body, T.fg); h.label:SetPoint("BOTTOMLEFT", 0, 6)
  h.count = ns.Text(h, ns.F.meta, T.muted); h.count:SetPoint("BOTTOMLEFT", h.label, "BOTTOMRIGHT", 6, 0)
  h.rule = ns.Rule(h); h.rule:SetPoint("BOTTOMLEFT"); h.rule:SetPoint("BOTTOMRIGHT")
  h.cols = CreateFrame("Frame", nil, h); h.cols:SetAllPoints()
  h.cols.names, h.cols.hits = {}, {}
  return h
end

-- "Already turned in (10)": folded by default, a click shows the quests turned in.
local function MakeFold(parent)
  local b = CreateFrame("Button", nil, parent)
  b.wlOwned = true
  b:SetSize(CW, 28)
  b.hl = ns.Tex(b, "BACKGROUND", T.hoverFill); b.hl:SetAllPoints(); b.hl:Hide()
  b.chev = ns.Icon(b, "chevron_right", 12, "ARTWORK", T.accentSoft); b.chev:SetPoint("LEFT", 8, 0)
  b.text = ns.Text(b, ns.F.body, T.muted); b.text:SetPoint("LEFT", 26, 0); b.text:SetWidth(CW - 34)
  b.rule = ns.Rule(b); b.rule:SetPoint("BOTTOMLEFT"); b.rule:SetPoint("BOTTOMRIGHT")
  b:SetScript("OnEnter", function(self)
    self.hl:Show(); self.chev:SetVertexColor(T.fg[1], T.fg[2], T.fg[3])
    ns.ShowTip(self, { self.labelText or "", f.doneOpen[self.dkey] and L.SUM_DONE_CLOSE or L.SUM_DONE_OPEN })
  end)
  b:SetScript("OnLeave", function(self)
    self.hl:Hide(); self.chev:SetVertexColor(T.accentSoft[1], T.accentSoft[2], T.accentSoft[3]); ns.HideTip()
  end)
  b:SetScript("OnMouseDown", function(self) self.text:SetPoint("LEFT", 26, -1) end)
  b:SetScript("OnMouseUp", function(self) self.text:SetPoint("LEFT", 26, 0) end)
  b:SetScript("OnClick", function(self)
    f.doneOpen[self.dkey] = not f.doneOpen[self.dkey] or nil
    if PlaySound then PlaySound(SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or 856) end
    Render()
  end)
  return b
end

local function OpenPicker()
  if f then f:Hide() end
  if ns.ShowPicker then ns.ShowPicker() end
end

local function Build()
  local S = SW()
  f = S.Window("WLHelperOverview", W, 300, "", L.SUM_T, WLDTDB, "ovPos", { header = 44, minH = 120, strata = "HIGH" })
  f.open, f.doneOpen = {}, {}

  f.sa = S.ScrollArea(f)
  f.child = f.sa.child
  f.child:SetWidth(CW)
  local c = f.child
  f.heroes, f.info, f.gpsBtns, f.notes, f.rows, f.heads, f.folds = {}, {}, {}, {}, {}, {}, {}
  f.rdyLines, f.rdySubs = {}, {}
  -- your selection's totals (they follow your ticks), and the members without WL Helper, once
  f.totals = ns.Text(c, ns.F.body, T.fg)
  f.noHelper = ns.Text(c, ns.F.meta, T.muted)
  f.extra = ns.Text(c, ns.F.meta, T.muted)
  f.empty = S.EmptyState(c, "portal", L.OV_EMPTY_T, L.OV_EMPTY)
  f.empty:Hide()
  -- every quest turned in: the fact, and the way to another dungeon (secondary: the bar's
  -- "Guide me through the dungeon" is the one primary)
  f.allDone = S.EmptyState(c, "check", "", nil, L.SUM_OTHER_DG, OpenPicker, "secondary")
  f.allDone:Hide()

  -- pinned at the bottom: share all (in a group), close, the route button (the one primary)
  f.bar = CreateFrame("Frame", nil, f)
  f.bar:SetHeight(32)
  -- starts the route on these dungeons, or goes back to it when it already runs on them.
  -- mode: the button's ("start", "update", "back"); run: walk them through with no quest
  local function Go(mode, run)
    local keys = f.keys
    if not keys or #keys == 0 then return end
    -- the route of these dungeons already runs: back to it (the ticks already replanned it);
    -- starting again would forget the steps marked done by hand
    if mode ~= "start" then
      f:Hide()
      if ns.ShowGuide then ns.ShowGuide() end
      return
    end
    WLDTDB.sel = WLDTDB.sel or {}
    wipe(WLDTDB.sel)
    local runs = run and {} or nil
    for _, k in ipairs(keys) do
      WLDTDB.sel[k] = true
      if runs and ns.Runnable(k) then runs[k] = true end
    end
    f:Hide()
    ns.StartGuide(runs)
  end
  f.goBtn = S.Button(f.bar, L.SUM_GO, 0, 32, "primary", function() Go(f.mode) end, function()
    if f.mode == "update" then return { L.SUM_UPDATE, L.SUM_UPDATE_TT } end
    if f.mode == "back" then return { L.SUM_BACK, L.SUM_BACK_TT } end
    if f.replaces then return { L.SUM_GO_HERE, L.SUM_GO_HERE_TT } end
    return { L.SUM_GO, f.one and L.SUM_GO_TT1 or L.SUM_GO_TT }
  end)
  f.goBtn:SetPoint("RIGHT", 0, 0)
  f.goBtn:SetDisabledReason(L.SUM_GO_WHY)
  -- no quest left to do: the dungeon's walkthrough all the same (the engine then makes the route
  -- go to the entrance, then from boss to boss); it takes the route button's place
  f.runBtn = S.Button(f.bar, L.SUM_RUN, 0, 32, "primary", function() Go(f.runMode, true) end, function()
    if f.runMode ~= "start" then return { L.SUM_BACK, L.SUM_BACK_TT } end
    if f.runReplaces then return { L.SUM_GO_HERE, L.SUM_GO_HERE_TT } end
    return { f.runLabel or L.SUM_RUN, L.SUM_RUN_TT }
  end)
  f.runBtn:SetPoint("RIGHT", 0, 0)
  f.runBtn:Hide()
  -- opened from the picker (which hides itself): the way back to it; else close
  f.closeBtn = S.Button(f.bar, L.SUM_CLOSE, 0, 28, "secondary", function()
    if f.backPick then OpenPicker() else f:Hide() end
  end, function()
    if f.backPick then return { L.SUM_BACK_PICK, L.SUM_BACK_PICK_TT } end
    return { L.SUM_CLOSE, L.SUM_CLOSE_TT }
  end)
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
  f.events = ev
  for _, e in ipairs({ "QUEST_LOG_UPDATE", "QUEST_TURNED_IN", "PLAYER_LEVEL_UP", "BAG_UPDATE_DELAYED", "GET_ITEM_INFO_RECEIVED", "GROUP_ROSTER_UPDATE" }) do
    pcall(ev.RegisterEvent, ev, e)
  end
  local queued = false
  ev:SetScript("OnEvent", function(_, e, a1, a2)
    if e == "GET_ITEM_INFO_RECEIVED" then
      -- only an item the summary waits for (an id it shows, or any while a name is not cached);
      -- the many items arriving at once make one render (the 0.3 s queue below). An item the
      -- server does not know (success false) is remembered and renders nothing.
      local id = num(a1)
      if id and a2 == false then failedItems[id] = true; pendingItems[id] = nil; return end
      if not (pendingName or (id and pendingItems[id]) or not id) then return end
      if id then pendingItems[id] = nil end
      wipe(rewardCache)
    end
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
  ResetRenderCaches()
  pendingName = false
  local keys = {}
  for _, k in ipairs(f.keys) do if ns.D[k] then keys[#keys + 1] = k end end
  if #keys == 0 then f:Hide(); return end
  local log = ns.LogEntries()
  local cls, lvl = Cls(), Level()
  local members = Members()
  local cols, others, extra = SplitMembers(members)
  f.extraCols = extra
  local ctx = { log = log, cls = cls, lvl = lvl, cols = cols, grouped = #members > 0 }
  local multi = #keys > 1
  if multi then
    f.title:SetText(L.SUM_ROUTE_T)
    f.subtitle:SetText(ns.Plural(#keys, "SUM_DG1", "SUM_DG", #keys))
  else
    -- the picture below names the dungeon
    f.title:SetText(L.SUM_T)
    f.subtitle:SetText("")
  end
  local c = f.child

  -- every quest's facts first: the defaults, then the totals over the ticked ones
  local per, sel, seen = {}, {}, {}
  local routeChanged = false
  local tq, txp, tmoney, titems, tup = 0, 0, 0, 0, 0
  local nQuests, nTodo = 0, 0
  local shareList, shareSeen = {}, {}
  local function count(id)
    if seen[id] then return end
    seen[id] = true
    local q = ns.Q[id]
    tq = tq + 1
    txp = txp + QuestXP(id)
    tmoney = tmoney + QuestMoney(id)
    if q then titems = titems + ItemCount(id, q); tup = tup + UpCount(id, q) end
  end
  for _, dkey in ipairs(keys) do
    local todo, done = {}, {}
    for _, qid in ipairs(ns.DungeonQuests(dkey, cls)) do
      local inf = Info(qid, dkey, ctx)
      if ApplyDefault(qid, inf) and WLDTDB.sel and WLDTDB.sel[dkey] then routeChanged = true end
      nQuests = nQuests + 1
      if inf.st == "done" then done[#done + 1] = { qid = qid, inf = inf }
      else
        nTodo = nTodo + 1
        todo[#todo + 1] = { qid = qid, inf = inf }
      end
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
    -- to do by level, turned in by level
    local function byLevel(a, b)
      local la, lb = a.inf.q.l or 0, b.inf.q.l or 0
      if la ~= lb then return la < lb end
      return a.qid < b.qid
    end
    table.sort(todo, byLevel); table.sort(done, byLevel)
    per[dkey] = { todo = todo, done = done }
  end
  f.shareList = shareList
  -- the guide's "before entering" list (Engine PreEntry) over the ticks: what to pick up outside
  local pe, peB, peI = {}, {}, {}
  if ns.PreEntryQuests then
    local s = {}
    for _, k in ipairs(keys) do s[k] = true end
    local ok, res = pcall(ns.PreEntryQuests, s, cls)
    if ok and type(res) == "table" then pe = res end
  end
  for _, v in pairs(pe) do
    for id in pairs(v.before) do peB[id] = true end
    for id in pairs(v.inside) do peI[id] = true end
  end
  ctx.peBefore, ctx.peInside = peB, peI
  f.ready = {}
  f.totalsInfo = { quests = tq, xp = txp, money = tmoney, items = titems, upgrades = tup }
  local allDone = nQuests > 0 and nTodo == 0
  f.allDoneNow = allDone
  -- nothing left to do but a dungeon to walk through (a class-quest card is no place to run)
  local runnable = false
  if nTodo == 0 then
    for _, k in ipairs(keys) do if ns.Runnable(k) then runnable = true end end
  end
  -- a default changed (a level up) for a dungeon of the running route: the route follows, once
  if routeChanged and ns.route and ns.frame and ns.frame:IsShown() and ns.Recalc and C_Timer and C_Timer.After then
    C_Timer.After(0, function() pcall(ns.Recalc) end)
  end

  local y = 0
  local hi, ii, gi, ni, ri, hdi, fi = 0, 0, 0, 0, 0, 0, 0
  local rli, rsi = 0, 0
  local totalsShown, noHelperShown, allDoneShown, extraShown = false, false, false, false
  local noHelperText, extraText

  -- "Your selection: 7 quests · 38,900 XP · 3g 20s · 4 items including 2 upgrades", then the members without WL Helper, once
  local function TotalsBlock()
    if tq > 0 then
      local parts = { ns.Plural(tq, "SUM_Q1", "SUM_Q", tq) }
      if txp > 0 then parts[#parts + 1] = L.SUM_XP:format(Big(txp)) end
      if tmoney > 0 then parts[#parts + 1] = Money(tmoney) end
      -- "4 objets dont 2 améliorations" (one per quest at most for rewards to choose from)
      if titems > 0 then
        local it = ns.Plural(titems, "SUM_IT1", "SUM_IT", titems)
        if tup > 0 then it = ns.Plural(tup, "SUM_IT_UP1", "SUM_IT_UP", it, tup) end
        parts[#parts + 1] = it
      end
      f.totals:SetText(L.SUM_SEL:format(table.concat(parts, " · ")))
      f.totals:SetTextColor(T.fg[1], T.fg[2], T.fg[3])
    else
      f.totals:SetText(L.SUM_SEL0)
      f.totals:SetTextColor(T.muted[1], T.muted[2], T.muted[3])
    end
    f.totals:ClearAllPoints(); f.totals:SetPoint("TOPLEFT", c, "TOPLEFT", 0, -y)
    f.totals:Show(); totalsShown = true
    y = y + LineH(f.totals, ns.F.body, CW, c)
    if #others > 0 then
      local names = {}
      for _, m in ipairs(others) do names[#names + 1] = m.name end
      noHelperText = ns.Plural(#others, "SUM_NOHELPER1", "SUM_NOHELPER", table.concat(names, ", "))
      f.noHelper:SetText(noHelperText)
      f.noHelper:ClearAllPoints(); f.noHelper:SetPoint("TOPLEFT", c, "TOPLEFT", 0, -(y + 4))
      f.noHelper:Show(); noHelperShown = true
      y = y + 4 + LineH(f.noHelper, ns.F.meta, CW, c, 3)
    end
    if #extra > 0 then
      local names = {}
      for _, m in ipairs(extra) do names[#names + 1] = m.name end
      extraText = ns.Plural(#extra, "SUM_EXTRA1", "SUM_EXTRA", table.concat(names, ", "))
      f.extra:SetText(extraText)
      f.extra:ClearAllPoints(); f.extra:SetPoint("TOPLEFT", c, "TOPLEFT", 0, -(y + 4))
      f.extra:Show(); extraShown = true
      y = y + 4 + LineH(f.extra, ns.F.meta, CW, c, 3)
    end
    y = y + 8
  end
  local function AllDoneBlock(title)
    f.allDone:ClearAllPoints(); f.allDone:SetPoint("TOP", c, "TOP", 0, -(y + 12))
    f.allDone:SetWrapWidth(CW)
    local eh = f.allDone:Set("check", title, runnable and (#keys > 1 and L.SUM_RUN_SUB_N or L.SUM_RUN_SUB) or nil, L.SUM_OTHER_DG, OpenPicker, "secondary")
    f.allDone:Show(); allDoneShown = true
    y = y + 12 + (num(eh) or 80) + 12
  end

  -- "Can I go in now?": the ticked quests given outside (the guide's "before entering" list), in
  -- your log or not; the ones still to pick up by name, each with what it waits on
  local function SubLine(text)
    rsi = rsi + 1
    local fs = f.rdySubs[rsi] or ns.Text(c, ns.F.meta, T.muted); f.rdySubs[rsi] = fs
    fs:SetText(text)
    fs:SetTextColor(T.muted[1], T.muted[2], T.muted[3])
    fs:ClearAllPoints(); fs:SetPoint("TOPLEFT", c, "TOPLEFT", 22, -(y - 2))
    fs:Show()
    y = y - 2 + LineH(fs, ns.F.meta, CW - 22, c) + 6
    return fs
  end
  local MAX_MISS = 5
  local function ReadyBlock(dkey, place)
    local rd = pe[dkey]
    if not rd then return end
    local have, miss, inside = 0, {}, 0
    for id in pairs(rd.before) do
      local s = QState(log, id)
      if s == "on" or s == "ready" then have = have + 1 elseif s == "none" then miss[#miss + 1] = id end
    end
    for id in pairs(rd.inside) do
      if not rd.before[id] and QState(log, id) == "none" then inside = inside + 1 end
    end
    local nOut = have + #miss
    if nOut + inside == 0 then return end
    local info = { have = have, missing = miss, inside = inside, lines = {} }
    f.ready[dkey] = info
    if #miss == 0 then
      ii = ii + 1
      local txt = nOut == 0 and L.SUM_RDY_NONE or ns.Plural(nOut, "SUM_RDY_OK1", "SUM_RDY_OK", nOut)
      local it = InfoLine(ii, "check", T.ok, txt, T.ok)
      place(it, CW - 22)
      info.head = it.fs
      if inside > 0 then
        info.sub = SubLine(nOut == 0 and ns.Plural(inside, "SUM_RDY_INALL1", "SUM_RDY_INALL")
          or ns.Plural(inside, "SUM_RDY_IN1", "SUM_RDY_IN", inside))
      end
      return
    end
    ii = ii + 1
    local it = InfoLine(ii, "warning", T.warn, ns.Plural(#miss, "SUM_RDY_MISS1", "SUM_RDY_MISS", #miss), T.warn)
    place(it, CW - 22)
    info.head = it.fs
    table.sort(miss, function(a, b)
      local la, lb = ns.Q[a].l or 0, ns.Q[b].l or 0
      if la ~= lb then return la < lb end
      return a < b
    end)
    y = y - 2
    for i, id in ipairs(miss) do
      if i > MAX_MISS then break end
      local q = ns.Q[id]
      local why, pre = TakeWhy(log, id, q, lvl, cls)
      rli = rli + 1
      local o = f.rdyLines[rli] or MakeReadyLine(c); f.rdyLines[rli] = o
      o.qid = id
      o.point = PointFor(log, id, q, "none", pre)
      local name = ns.QName(id)
      o.text:SetText(why and (name .. " · " .. why) or name)
      local tc = why and T.muted or T.text
      o.text:SetTextColor(tc[1], tc[2], tc[3])
      ns.SetHDIcon(o.icon, why and "clock" or (o.point and "pin" or "dot"), why and T.muted or T.accentSoft)
      local tip = { name }
      local g = GiverText(q, "none")
      if g then tip[#tip + 1] = g end
      if why then tip[#tip + 1] = { why, T.warn[1], T.warn[2], T.warn[3] } end
      if o.point then
        tip[#tip + 1] = L.OV_GPS_T:format(o.point[4] or "")
        tip[#tip + 1] = L.OV_GPS_CLICK
      end
      o.tip = tip
      local th = LineH(o.text, ns.F.meta, CW - 22 - 16, o)
      o:SetSize(CW - 22, th + 3)
      o:ClearAllPoints(); o:SetPoint("TOPLEFT", c, "TOPLEFT", 22, -y)
      o:Show()
      info.lines[#info.lines + 1] = o
      y = y + th + 3 + 2
    end
    y = y + 4
    if #miss > MAX_MISS then
      info.more = SubLine(ns.Plural(#miss - MAX_MISS, "SUM_RDY_MORE1", "SUM_RDY_MORE", #miss - MAX_MISS))
    end
    if inside > 0 then
      info.sub = SubLine(ns.Plural(inside, "SUM_RDY_IN1", "SUM_RDY_IN", inside))
    end
  end

  -- the route of several dungeons: its totals (or "all turned in") first
  if multi then
    if allDone then AllDoneBlock(L.SUM_ALLDONE_TN) elseif nTodo > 0 then TotalsBlock() end
  end

  -- the dungeons, one after the other: picture, entrance and key, quests to do, quests turned in
  for di, dkey in ipairs(keys) do
    local d = ns.D[dkey]
    local todo, done = per[dkey].todo, per[dkey].done
    if di > 1 or (multi and y > 0) then y = y + 8 end
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
      table.insert(parts, lo == hi2 and L.SUM_LV1:format(lo) or L.SUM_LV:format(lo, hi2))
    end
    table.insert(parts, L.SUM_SIZE:format(d.size or 5))
    hero.lvl:SetText(table.concat(parts, " · "))
    hero.name:SetText(ns.DName(dkey))
    local lvlH = LineH(hero.lvl, ns.F.meta, CW - 24, hero, 1)
    local nameH = LineH(hero.name, ns.F.heading, CW - 24, hero, 1)
    hero.band:SetHeight(math.min(hh - 2, 8 + nameH + 3 + lvlH + 8))
    hero:Show()
    y = y + hh + 12

    local dgDone = #todo == 0 and #done > 0
    -- one dungeon, every quest turned in: say it at the top, offer another dungeon
    if not multi and dgDone then AllDoneBlock(L.SUM_ALLDONE_T:format(ns.DName(dkey))) end

    -- entrance (with its GPS) and key: two short lines, only while something is left to do
    if not dgDone then
      local function place(it, w, extra)
        it.icon:ClearAllPoints(); it.icon:SetPoint("TOPLEFT", c, "TOPLEFT", 0, -(y + 1))
        it.fs:ClearAllPoints(); it.fs:SetPoint("TOPLEFT", c, "TOPLEFT", 22, -y)
        local h = LineH(it.fs, ns.F.body, w, c)
        y = y + math.max(h, extra or 0) + 6
      end
      local point = d.e and d.e.m and { d.e.m, d.e.x, d.e.y, ns.DName(dkey) } or nil
      local loc = (GetLocale and GetLocale() == "frFR" and d.locf) or ns.T(d.loc) or ""
      if d.cq and d.home then loc = L.CQ_IN:format(ns.DName(d.home)) end
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
      ReadyBlock(dkey, place)
      y = y + 6
    end

    -- one dungeon: its totals under its facts
    if not multi and #todo > 0 then TotalsBlock() end

    if #todo == 0 and #done == 0 then
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
      if multi and dgDone and not allDone then
        ni = ni + 1
        local fs = f.notes[ni] or ns.Text(c, ns.F.body, T.muted); f.notes[ni] = fs
        fs:SetText(L.SUM_ALLDONE_NOTE:format(ns.DName(dkey)))
        fs:ClearAllPoints(); fs:SetPoint("TOPLEFT", c, "TOPLEFT", 0, -y); fs:Show()
        y = y + LineH(fs, ns.F.body, CW, c) + 8
      end
      -- quests to do: a header with the members' names over their columns, then the rows
      if #todo > 0 then
        hdi = hdi + 1
        local hd = f.heads[hdi] or MakeHead(c); f.heads[hdi] = hd
        if hdi == 1 then f.gHead = hd.cols end
        hd.label:SetText(L.SUM_TODO)
        hd.count:SetText(tostring(#todo))
        local gh = hd.cols
        for j, m in ipairs(cols) do
          local fs = gh.names[j]
          if not fs then fs = ns.Text(gh, ns.F.meta, T.fg); fs:SetJustifyH("CENTER"); gh.names[j] = fs end
          fs:SetText(m.name)
          local cc = ClassColor(m.class)
          fs:SetTextColor(cc[1], cc[2], cc[3])
          fs:SetWidth(CELLW - 4)
          fs:SetWordWrap(false)
          -- each name has its own hover area: the full class-coloured name, even when cut
          local hit = gh.hits[j]
          if not hit then
            hit = CreateFrame("Frame", nil, gh)
            hit:EnableMouse(true)
            hit:SetScript("OnEnter", function(self) if self.tip then ns.ShowTip(self, self.tip) end end)
            hit:SetScript("OnLeave", ns.HideTip)
            gh.hits[j] = hit
          end
          hit.tip = { { m.name, cc[1], cc[2], cc[3] }, L.SUM_COL_TT }
          ns.ClampLabel(fs, m.name, hit)
          local x = CW - 12 - (#cols - j + 1) * CELLW
          fs:ClearAllPoints(); fs:SetPoint("BOTTOMLEFT", gh, "BOTTOMLEFT", x + 2, 6)
          fs:Show()
          hit:SetSize(CELLW, 18)
          hit:ClearAllPoints(); hit:SetPoint("BOTTOMLEFT", gh, "BOTTOMLEFT", x, 3)
          hit:Show()
        end
        for j = #cols + 1, #gh.names do gh.names[j]:Hide() end
        for j = #cols + 1, #gh.hits do gh.hits[j]:Hide() end
        gh:SetShown(#cols > 0)
        hd:ClearAllPoints(); hd:SetPoint("TOPLEFT", c, "TOPLEFT", 0, -y)
        hd:Show()
        y = y + 24 + 8
        for _, e in ipairs(todo) do
          ri = ri + 1
          local r = f.rows[ri] or MakeRow(c); f.rows[ri] = r
          r:ClearAllPoints(); r:SetPoint("TOPLEFT", c, "TOPLEFT", 0, -y)
          local h = FillRow(r, e.qid, dkey, e.inf, ctx)
          r:Show(); r.shownNow = true
          y = y + h + ROW_GAP
        end
        y = y - ROW_GAP
      end
      -- quests turned in: folded at the bottom
      if #done > 0 then
        if #todo > 0 then y = y + 12 end
        fi = fi + 1
        local fb = f.folds[fi] or MakeFold(c); f.folds[fi] = fb
        fb.dkey = dkey
        fb.labelText = L.SUM_DONE_H:format(#done)
        fb.text:SetText(fb.labelText)
        ns.SetHDIcon(fb.chev, f.doneOpen[dkey] and "chevron_down" or "chevron_right", T.accentSoft)
        fb:ClearAllPoints(); fb:SetPoint("TOPLEFT", c, "TOPLEFT", 0, -y)
        fb:Show()
        y = y + 28
        if f.doneOpen[dkey] then
          y = y + 8
          for _, e in ipairs(done) do
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
    end
  end
  for j = hi + 1, #f.heroes do f.heroes[j]:Hide() end
  for j = ii + 1, #f.info do f.info[j].icon:Hide(); f.info[j].fs:Hide() end
  for j = gi + 1, #f.gpsBtns do f.gpsBtns[j]:Hide() end
  if gi == 0 then f.entryGps, f.entryPoint = nil, nil end
  for j = ni + 1, #f.notes do f.notes[j]:Hide() end
  for j = rli + 1, #f.rdyLines do f.rdyLines[j]:Hide() end
  for j = rsi + 1, #f.rdySubs do f.rdySubs[j]:Hide() end
  for j = ri + 1, #f.rows do f.rows[j]:Hide(); f.rows[j].shownNow = nil end
  for j = hdi + 1, #f.heads do f.heads[j]:Hide() end
  for j = fi + 1, #f.folds do f.folds[j]:Hide() end
  if hdi == 0 and f.heads[1] then f.gHead = f.heads[1].cols; f.gHead:Hide() end
  if not totalsShown then f.totals:SetText(""); f.totals:Hide() end
  if not noHelperShown then f.noHelper:SetText(""); f.noHelper:Hide() end
  f.noHelperText = noHelperText
  if not extraShown then f.extra:SetText(""); f.extra:Hide() end
  f.extraText = extraText
  if not allDoneShown then f.allDone:Hide() end
  if multi or nQuests > 0 then f.empty:Hide() end

  -- bottom bar: the route button says what it does; hidden when nothing is left to do
  local mode
  if f.first or not RouteRuns(keys) then mode = "start" elseif f.changed then mode = "update" else mode = "back" end
  f.mode = mode
  f.goBack = mode ~= "start"
  -- opened outside the picker while the route runs on other dungeons: starting here replaces that
  -- route (and its steps marked by hand), so the label says it and a second click confirms
  f.replaces = mode == "start" and not f.fromPicker and RouteElsewhere() or nil
  local label = mode == "update" and L.SUM_UPDATE or mode == "back" and L.SUM_BACK
    or (f.replaces and L.SUM_GO_HERE) or L.SUM_GO
  f.goBtn:SetConfirm(f.replaces and L.SUM_GO_CONFIRM or nil)
  if not f.replaces and f.goBtn.armed then f.goBtn:Disarm() end
  -- an armed button keeps its question until the second click (or 4 s)
  if not f.goBtn.armed then f.goBtn:SetText(label) end
  f.goLabel = label
  -- opened from the picker (it hid itself): the secondary button goes back to it
  f.backPick = f.fromPicker and nTodo > 0 or nil
  f.closeBtn:SetText(f.backPick and L.SUM_BACK_PICK or L.SUM_CLOSE)
  if f.closeBtn.SetIcon then f.closeBtn:SetIcon(f.backPick and "chevron_left" or nil) end
  if f.goBtn.SetIcon then f.goBtn:SetIcon(mode == "update" and "refresh" or mode == "back" and "chevron_left" or "pin") end
  SetOn(f.goBtn, mode ~= "start" or #sel > 0)
  f.goBtn:SetShown(nTodo > 0)
  -- nothing to do: "Guide me through the dungeon" (or back to that route when it runs)
  f.runLabel = #keys > 1 and L.SUM_RUN_N or L.SUM_RUN
  f.runBtn:SetShown(runnable)
  if runnable then
    -- back to the route only while it is an unfinished run of these dungeons: a finished one
    -- (or their finished quest route) starts afresh, without asking (nothing would be lost)
    local onThese = RouteRuns(keys)
    local runMode = "start"
    if onThese and not f.first and RunGoing(keys) then runMode = "back" end
    f.runMode = runMode
    f.runReplaces = runMode == "start" and not onThese and not f.fromPicker and RouteElsewhere() or nil
    f.runBtn:SetConfirm(f.runReplaces and L.SUM_GO_CONFIRM or nil)
    if not f.runReplaces and f.runBtn.armed then f.runBtn:Disarm() end
    if not f.runBtn.armed then
      f.runBtn:SetText(runMode ~= "start" and L.SUM_BACK or (f.runReplaces and L.SUM_GO_HERE) or f.runLabel)
    end
    if f.runBtn.SetIcon then f.runBtn:SetIcon(runMode ~= "start" and "chevron_left" or "pin") end
  end
  f.closeBtn:ClearAllPoints()
  if nTodo > 0 then f.closeBtn:SetPoint("RIGHT", f.goBtn, "LEFT", -8, 0)
  elseif runnable then f.closeBtn:SetPoint("RIGHT", f.runBtn, "LEFT", -8, 0)
  else f.closeBtn:SetPoint("RIGHT", f.bar, "RIGHT", 0, 0) end
  f.shareAll:SetShown(ctx.grouped and nTodo > 0)
  if f.shareAll:IsShown() then
    if not ns.pushBusy then f.shareAll:SetText(L.SUM_SHARE_ALL) end
    SetOn(f.shareAll, #shareList > 0 and not ns.pushBusy)
  end

  -- the window fits its content up to 80 % of the screen; past that, the content scrolls
  local contentH = math.max(1, math.ceil(y))
  local saTop = f:ContentTop() + 12
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
  f:FitHeight(viewH + barH)
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
-- Opened from the picker (or with no route on these dungeons) it is the route's first screen: its
-- main button starts the route.
function ns.ShowSummary(keys, one)
  if GuideOff() then return end
  if ns.EnsureClassCards then ns.EnsureClassCards() end
  keys = keys or PickedKeys()
  local list = {}
  for _, k in ipairs(keys) do if ns.D[k] then list[#list + 1] = k end end
  if #list == 0 then return end
  local picker = _G.WLDTPicker
  local fromPicker = picker and picker.IsShown and picker:IsShown() and true or false
  if not f then Build() end
  local sig = table.concat(list, ",")
  if f.sig ~= sig and f.sa then f.sa:ScrollTo(0, true); wipe(f.open); wipe(f.doneOpen) end
  f.sig, f.keys, f.one = sig, list, one and true or nil
  f.dkey = list[1]
  f.first = fromPicker or not RouteRuns(list)
  f.fromPicker = fromPicker or nil
  f.changed = nil
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
