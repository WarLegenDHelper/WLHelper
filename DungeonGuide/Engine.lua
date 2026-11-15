-- Moteur : état des quêtes, calcul de la route (plusieurs donjons, depuis la position du joueur), étapes.
local ADDON, ns = ...
local CQL = C_QuestLog
local L = ns.L

-- =====================================================================
--  État des quêtes
-- =====================================================================
function ns.IsDone(id)
  if CQL and CQL.IsQuestFlaggedCompleted then return CQL.IsQuestFlaggedCompleted(id) end
  return IsQuestFlaggedCompleted and IsQuestFlaggedCompleted(id)
end
local IsDone = ns.IsDone

function ns.LogEntries()
  local list = {}
  if GetQuestLogTitle then
    local n = (GetNumQuestLogEntries and GetNumQuestLogEntries()) or 0
    for i = 1, n do
      local title, _, _, isHeader, _, isComplete, _, questID = GetQuestLogTitle(i)
      if not isHeader and questID then
        list[questID] = { index = i, title = title, complete = (isComplete == 1 or isComplete == true) }
      end
    end
  elseif CQL and CQL.GetNumQuestLogEntries and CQL.GetInfo then
    for i = 1, CQL.GetNumQuestLogEntries() do
      local info = CQL.GetInfo(i)
      if info and not info.isHeader and info.questID then
        local done = CQL.IsComplete and CQL.IsComplete(info.questID)
        list[info.questID] = { index = i, title = info.title, complete = done and true or false }
      end
    end
  end
  return list
end

function ns.State(log, id)
  if not id or id < 0 then return "none" end
  if ns.IsDone(id) then return "done" end
  local e = log[id]
  if e then return e.complete and "ready" or "on" end
  if CQL and CQL.IsOnQuest and CQL.IsOnQuest(id) then return "on" end
  return "none"
end
local State = ns.State

function ns.HasItem(ids)
  local count = (C_Item and C_Item.GetItemCount) or GetItemCount
  if not count or not ids then return false end
  for _, id in ipairs(ids) do
    local ok, n = pcall(count, id)
    if ok and n and n > 0 then return true end
  end
  return false
end

-- Une action (nœud) est-elle faite ?
function ns.NodeOK(log, n)
  if n.kind == "i" then return ns.HasItem(n.items) end
  if n.oneObj then return ns.ObjDone(log, n.q, n.oneObj) end
  local s = State(log, n.q)
  if s == "done" then return true end
  if n.kind == "a" or n.kind == "h" then return s ~= "none" end
  if n.kind == "c" or n.kind == "o" then return s == "ready" end
  return false
end

local function ClassOK(c, cls)
  if not c then return true end
  for tok in c:gmatch("[^,]+") do if tok == cls then return true end end
  return false
end
ns.ClassOK = ClassOK

function ns.PrereqProblem(qid)
  local q = ns.Q[qid]; if not q then return nil end
  local msgs = {}
  if q.r and UnitLevel("player") < q.r then table.insert(msgs, L.LVL_REQ:format(q.r)) end
  if msgs[1] then return table.concat(msgs, ", ") end
end

function ns.QName(qid)
  local q = ns.Q[qid]
  if not q then return tostring(qid) end
  if GetLocale and GetLocale() == "frFR" and q.nf then return q.nf end
  return q.n or tostring(qid)
end

function ns.DName(dkey)
  local d = ns.D[dkey]; if not d then return dkey or "" end
  -- les noms propres suivent la langue du client (ce qui est écrit en jeu), pas celle de l'interface
  if GetLocale and GetLocale() == "frFR" and d.nf then return d.nf end
  return d.n
end

-- Quêtes d'un donjon que ce personnage peut faire (faction Horde, classe).
-- métiers du personnage (noms anglais et français)
local PROF = { MINING = { "Mining", "Minage" }, BLACKSMITHING = { "Blacksmithing", "Forge" },
  ENGINEERING = { "Engineering", "Ingénierie" }, LEATHERWORKING = { "Leatherworking", "Travail du cuir" },
  TAILORING = { "Tailoring", "Couture" }, ALCHEMY = { "Alchemy", "Alchimie" }, ENCHANTING = { "Enchanting", "Enchantement" },
  HERBALISM = { "Herbalism", "Herboristerie" }, SKINNING = { "Skinning", "Dépeçage" } }
function ns.HasProf(code)
  if not (GetNumSkillLines and GetSkillLineInfo) then return true end
  local names = PROF[code]
  if not names then return true end
  for i = 1, GetNumSkillLines() do
    local nm, isHeader = GetSkillLineInfo(i)
    if nm and not isHeader then for _, n in ipairs(names) do if nm == n then return true end end end
  end
  return false
end

-- « quêtes utiles » : sans les répétables ni les quêtes d'un métier que tu n'as pas (réglage, activé par défaut)
function ns.Useful(q)
  if WLDTDB and WLDTDB.useful == false then return true end
  if q.rep then return false end
  if q.prof and not ns.HasProf(q.prof) then return false end
  return true
end

function ns.DungeonQuests(dkey, cls)
  local d, out = ns.D[dkey], {}
  if not d then return out end
  for _, qid in ipairs(d.q or {}) do
    local q = ns.Q[qid]
    if q and q.fa ~= "Alliance" and ClassOK(q.c, cls) and not q.unk and ns.Useful(q) then table.insert(out, qid) end
  end
  return out
end

-- =====================================================================
--  Positions (coordonnées monde via l'API de carte)
-- =====================================================================
local worldCache = {}
function ns.World(m, x, y)
  if not (m and x and y) then return nil end
  local k = m .. ":" .. x .. ":" .. y
  local c = worldCache[k]
  if c ~= nil then return c or nil end
  local res = false
  if C_Map and C_Map.GetWorldPosFromMapPos and CreateVector2D then
    local ok, cont, pos = pcall(C_Map.GetWorldPosFromMapPos, m, CreateVector2D(x / 100, y / 100))
    if ok and cont and pos then res = { cont, pos.x, pos.y } end
  end
  worldCache[k] = res
  return res or nil
end

function ns.PlayerWorld()
  if not (C_Map and C_Map.GetBestMapForUnit) then return nil end
  local m = C_Map.GetBestMapForUnit("player")
  if not m then return nil end
  local p = C_Map.GetPlayerMapPosition and C_Map.GetPlayerMapPosition(m, "player")
  if not p then return nil end
  local px, py = p.x or (p.GetXY and p:GetXY()), p.y
  if p.GetXY then px, py = p:GetXY() end
  if not px then return nil end
  return ns.World(m, px * 100, py * 100), m, px * 100, py * 100
end

local function Dist(a, b)
  if not a or not b then return 0 end
  if a[1] ~= b[1] then return 6000 + math.sqrt(a[2] ^ 2 + b[2] ^ 2) * 0 end
  return math.sqrt((a[2] - b[2]) ^ 2 + (a[3] - b[3]) ^ 2)
end
ns.Dist = Dist

-- =====================================================================
--  Nœuds de la route
-- =====================================================================
-- kind : a = prendre, o = objectif dehors, c = objectifs du donjon, t = rendre, i = objet (extras)
-- loc  : {m,x,y,n}  ou  ins = clé du donjon (alors la position est l'entrée du donjon)
local function MakeNodes(sel, cls)
  local nodes, byKey = {}, {}
  local function add(n)
    n.key = n.kind .. ":" .. tostring(n.q) .. (n.sub and (":" .. n.sub) or "")
    if byKey[n.key] then return byKey[n.key] end
    n.deps = n.deps or {}
    byKey[n.key] = n; table.insert(nodes, n)
    return n
  end
  local function qnodes(qid, dkey, isPre)
    local q = ns.Q[qid]
    if not q then return nil end
    local home = q.d or dkey
    local inDg = q.od or home   -- donjon où se font les objectifs (un prérequis peut être dans un autre donjon)
    local A, T
    -- prendre
    local sl = q.s
    local startDg = home
    if sl and sl.i and sl.n then
      -- départ à l'intérieur (objet/PNJ) : même donjon que la quête qui se rend à ce même PNJ/objet
      if not ns._insideFinish then
        ns._insideFinish = {}
        for _, pq in pairs(ns.Q) do
          if pq.f and pq.f.i and pq.f.n and pq.d and pq.role == "main" then ns._insideFinish[pq.f.n] = pq.d end
        end
      end
      startDg = ns._insideFinish[sl.n] or home
    end
    if q.si and (not sl or sl.i) then
      A = add({ kind = "a", q = qid, ins = startDg, startItem = q.si, d = startDg, pre = isPre })
    elseif sl and sl.i then
      A = add({ kind = "a", q = qid, ins = startDg, npc = sl.n, d = startDg, pre = isPre })
    elseif sl then
      A = add({ kind = "a", q = qid, loc = sl, npc = sl.n, d = home, pre = isPre })
    else
      A = add({ kind = "a", q = qid, unknown = true, npc = q.st, d = home, pre = isPre })
    end
    -- objectifs
    -- objectifs : dehors (position connue), zone du donjon (« outer »), instance (connue),
    -- inconnus (pas de position dans les données) : dans le donjon pour une quête de donjon, ignorés sinon.
    local outs, inside, outer = {}, false, true
    local real = 0
    for i, o in ipairs(q.o or {}) do
      local outerHere = o.outer and not isPre
      local bg = o.w and (o.w.m == 1459 or o.w.m == 1460 or o.w.m == 1461)  -- butin de champ de bataille : pas un lieu de farm
      if o.w and o.k == "item" and o.src and not bg then
        -- composant d'artisanat / HV : la « meilleure » source n'a qu'un taux de butin anecdotique
        local best = 0
        for _, sr in ipairs(o.src) do if sr[2] and sr[2] > best then best = sr[2] end end
        if best < 3 then bg = true end
      end
      if bg then
        -- objet à acheter/échanger (HV) : pas de point
      elseif o.w and not outerHere and not o.ins then
        real = real + 1
        table.insert(outs, add({ kind = "o", q = qid, sub = i, loc = o.w, npc = o.t and o.t[1] or o.n, obj = o, d = home, pre = isPre, deps = { A } }))
      elseif o.ins or outerHere or o.unk then
        real = real + 1
        inside = true
        if not outerHere then outer = false end
      end
    end
    -- quête de donjon sans objectif connu (quêtes Forever récentes) : objectifs dans le donjon
    if not isPre and not q.noin and real == 0 and (q.o == nil or #q.o > 0 or q.ne) then inside = true; outer = false end
    local C
    if inside then C = add({ kind = "c", q = qid, ins = inDg, outer = outer, d = inDg, pre = isPre, deps = { A } }) end
    -- rendre
    local fl = q.f
    local tdeps = { A }
    for _, o in ipairs(outs) do table.insert(tdeps, o) end
    if C then table.insert(tdeps, C) end
    if fl and fl.i then T = add({ kind = "t", q = qid, ins = home, npc = fl.n, d = home, pre = isPre, deps = tdeps })
    elseif fl then T = add({ kind = "t", q = qid, loc = fl, npc = fl.n, d = home, pre = isPre, deps = tdeps })
    else T = add({ kind = "t", q = qid, unknown = true, npc = q.ft, d = home, pre = isPre, deps = tdeps }) end
    return A, T
  end
  for dkey in pairs(sel) do
    for _, qid in ipairs(ns.DungeonQuests(dkey, cls)) do
      local q = ns.Q[qid]
      if not (WLDTDB.off and WLDTDB.off[qid]) and not q.extra then
        local prevT
        local Tby = {}
        for _, pid in ipairs(q.p or {}) do
          local pq = ns.Q[pid]
          if pq and pq.fa ~= "Alliance" and ClassOK(pq.c, cls) then
            local A, T = qnodes(pid, dkey, true)
            if A then
              -- quêtes données ensemble (ex. les Épreuves des crânes) : elles dépendent de la même quête, pas l'une de l'autre
              local par = ns.PARALLEL and ns.PARALLEL[pid]
              if par and Tby[par] then table.insert(A.deps, Tby[par]) elseif prevT then table.insert(A.deps, prevT) end
              for _, x in ipairs(ns.AFTER and ns.AFTER[pid] or {}) do if Tby[x] then table.insert(A.deps, Tby[x]) end end
            end
            Tby[pid] = T
            prevT = T or prevT
          end
        end
        local A = qnodes(qid, dkey, false)
        if A and prevT then table.insert(A.deps, prevT) end
      end
    end
  end
  -- extras (maillet de Zul'Farrak...)
  if ns.Extras then ns.Extras(nodes, byKey, add, sel, cls) end
  return nodes, byKey
end

-- Position d'un nœud
local function NodePos(n)
  if n.loc then return ns.World(n.loc.m, n.loc.x, n.loc.y) end
  if n.ins then
    local d = ns.D[n.ins]
    if d and d.e and d.e.m then return ns.World(d.e.m, d.e.x, d.e.y) end
  end
  return nil
end
ns.NodePos = NodePos

-- Nœuds « avant d'entrer » : quêtes à prendre dehors avant la visite du donjon.
local function PreEntry(nodes)
  local insideOf = {}
  for _, n in ipairs(nodes) do if n.ins then insideOf[n] = n.ins end end
  -- n dépend-il (transitivement) d'un nœud intérieur du donjon d ?
  local memo = {}
  local function dependsInside(n, d)
    local k = tostring(n) .. d
    if memo[k] ~= nil then return memo[k] end
    memo[k] = false
    for _, p in ipairs(n.deps) do
      if insideOf[p] == d or dependsInside(p, d) then memo[k] = true; return true end
    end
    return false
  end
  local gate = {}
  for _, n in ipairs(nodes) do
    if n.kind == "c" and n.ins then
      for _, p in ipairs(n.deps) do
        if p.kind == "a" and not p.ins and not dependsInside(p, n.ins) then
          gate[n.ins] = gate[n.ins] or {}
          gate[n.ins][p] = true
        end
      end
    end
  end
  return gate
end

-- =====================================================================
--  Route : glouton « plus proche voisin » qui respecte les dépendances
-- =====================================================================
function ns.BuildRoute(sel, startPos)
  local _, cls = UnitClass("player")
  local nodes, byKey = MakeNodes(sel, cls)
  local log = ns.LogEntries()
  -- déjà faits : on les retire de la route
  local done = {}
  for _, n in ipairs(nodes) do
    if ns.NodeOK(log, n) then done[n] = true end
  end
  local gate = PreEntry(nodes)
  local lvl = UnitLevel("player") or 1
  local order, pos, inDungeon = {}, startPos, nil
  local remaining = 0
  for _, n in ipairs(nodes) do if not done[n] then remaining = remaining + 1 end end
  local placed = {}
  -- rendus « en attente » : si le même PNJ attend d'autres quêtes pas encore faisables,
  -- on garde ce rendu pour tout rendre en une fois (sauf s'il débloque la suite)
  local dependents = {}
  for _, n in ipairs(nodes) do for _, p in ipairs(n.deps) do dependents[p] = dependents[p] or {}; table.insert(dependents[p], n) end end
  local function Unlocks(n)
    for _, o in ipairs(dependents[n] or {}) do
      if not done[o] and not placed[o] then
        local free = true
        for _, p in ipairs(o.deps) do if p ~= n and not done[p] and not placed[p] then free = false break end end
        if free then return true end
      end
    end
    return false
  end
  local function SiblingsPending(n)
    if n.kind ~= "t" or not n.npc or Unlocks(n) then return false end
    for _, o in ipairs(nodes) do
      if o ~= n and o.kind == "t" and o.npc == n.npc and not done[o] and not placed[o] then
        for _, p in ipairs(o.deps) do if not done[p] and not placed[p] then return true end end
      end
    end
    return false
  end
  local guard = 0
  while remaining > 0 and guard < 5000 do
    guard = guard + 1
    local best, bestCost
    for _, n in ipairs(nodes) do
      if not done[n] and not placed[n] then
        local ok = true
        for _, p in ipairs(n.deps) do if not done[p] and not placed[p] then ok = false break end end
        if ok and n.ins and gate[n.ins] then
          for p in pairs(gate[n.ins]) do if not done[p] and not placed[p] then ok = false break end end
        end
        if ok then
          local cost
          if n.unknown then cost = 0
          elseif n.ins and inDungeon == n.ins then cost = 0
          else
            local np = NodePos(n)
            cost = (np and pos) and Dist(pos, np) or 50
            if n.ins then
              cost = cost + 400   -- on ne rentre dans un donjon qu'une fois tout pris autour
              local d = ns.D[n.ins]
              local lo = d and d.lvl and d.lvl[1]
              if lo and lo > lvl then cost = cost + (lo - lvl) * 600 end
            end
          end
          -- quête trop haute pour le niveau actuel : plus tard dans la route
          local q = ns.Q[n.q]
          if n.kind == "a" and q and q.r and q.r > lvl then cost = cost + (q.r - lvl) * 800 end
          if SiblingsPending(n) then cost = cost + 5000 end
          if not bestCost or cost < bestCost then best, bestCost = n, cost end
        end
      end
    end
    if not best then
      -- dépendance impossible (quête bloquée) : on ajoute ce qui reste tel quel
      for _, n in ipairs(nodes) do if not done[n] and not placed[n] then table.insert(order, n); placed[n] = true; remaining = remaining - 1 end end
      break
    end
    table.insert(order, best); placed[best] = true; remaining = remaining - 1
    inDungeon = best.ins
    pos = NodePos(best) or pos
  end
  return order, byKey
end

-- =====================================================================
--  Étapes : on regroupe les nœuds consécutifs au même endroit
-- =====================================================================
function ns.MakeSteps(order)
  local steps = {}
  local cur
  local function close() if cur then table.insert(steps, cur) end cur = nil end
  for _, n in ipairs(order) do
    local np = NodePos(n)
    local same = false
    if cur then
      if n.ins and cur.ins == n.ins then same = true
      elseif not n.ins and not cur.ins and cur.loc and n.loc and cur.loc.m == n.loc.m then
        local d = math.sqrt((cur.loc.x - n.loc.x) ^ 2 + (cur.loc.y - n.loc.y) ^ 2)
        same = d < 6 or (n.npc and cur.npcs[n.npc])
      elseif n.unknown and cur.unknown and cur.q == n.q then same = true end
    end
    if not same then
      close()
      if n.ins then
        -- étape « prêt ? » avant chaque visite de donjon
        local last = steps[#steps]
        if not (last and last.gate == n.ins) then
          table.insert(steps, { gate = n.ins, d = n.ins, acts = {}, npcs = {} })
        end
      end
      cur = { ins = n.ins, loc = n.loc, unknown = n.unknown, q = n.q, d = n.d, acts = {}, npcs = {}, pos = np }
    end
    table.insert(cur.acts, n)
    if n.npc then cur.npcs[n.npc] = true end
    if n.outer == false then cur.inner = true end
  end
  close()
  -- check-list des étapes « prêt ? » : quêtes dont les objectifs se font pendant la visite qui suit
  for i, st in ipairs(steps) do
    if st.gate then
      local visit = steps[i + 1]
      local seen = {}
      for _, n in ipairs(visit and visit.acts or {}) do
        if (n.kind == "c" or n.kind == "t") and not seen[n.q] then
          local hasOutsideA = true
          for _, n2 in ipairs(visit.acts) do if n2.kind == "a" and n2.q == n.q then hasOutsideA = false end end
          if hasOutsideA then
            seen[n.q] = true
            table.insert(st.acts, { kind = "h", q = n.q, key = "h:" .. n.q .. ":" .. i, d = n.d, pre = n.pre, deps = {} })
          end
        end
      end
      st.checks = st.acts
      if visit then visit.checks = st.acts end
    end
  end
  -- une étape « prêt ? » sans rien à vérifier n'apporte rien : on la retire
  for i = #steps, 1, -1 do
    local st = steps[i]
    if st.gate and #st.acts == 0 then
      table.remove(steps, i)
      if steps[i] then steps[i].checks = nil end
    end
  end
  -- conseils de trajet
  local prev
  for _, st in ipairs(steps) do
    local p = st.pos or (st.gate and NodePos({ ins = st.gate }))
    if prev and p then
      if prev[1] ~= p[1] then st.travel = "TRAVEL_CONT"
      elseif Dist(prev, p) > 1400 then st.travel = "TRAVEL_FAR" end
    end
    if st.unknown then st.travel = "TRAVEL_UNK" end
    prev = p or prev
  end
  return steps
end

-- =====================================================================
--  Partage des quêtes
-- =====================================================================
function ns.ShareQuests()
  local P = ns.Print
  if not IsInGroup() then P(L.NOGROUP) return end
  local log, queue = ns.LogEntries(), {}
  for id in pairs(log) do
    local q = ns.Q[id]
    if q and q.sh ~= false then table.insert(queue, id) end
  end
  if #queue == 0 then P(L.NOSHARE) return end
  local delay = 0
  for _, id in ipairs(queue) do
    C_Timer.After(delay, function()
      local e = ns.LogEntries()[id]
      if not e then return end
      if SelectQuestLogEntry then SelectQuestLogEntry(e.index)
      elseif CQL and CQL.SetSelectedQuest then CQL.SetSelectedQuest(id) end
      local pushable = (GetQuestLogPushable and GetQuestLogPushable()) or (CQL and CQL.IsPushableQuest and CQL.IsPushableQuest(id))
      if pushable then QuestLogPushQuest(); P(L.SHARED:format(e.title or id))
      else P(L.NOTSHARE:format(e.title or id)) end
    end)
    delay = delay + 1.5
  end
  P(L.SHARING:format(#queue))
end


-- =====================================================================
--  Dans le donjon : une étape par boss (ordre du journal de Naowh), une ligne par objectif.
--  « Au début » (quêtes à prendre à l'entrée) en premier, « dans tout le donjon » (butin des monstres) en dernier.
-- =====================================================================
local NKEY = { TheDeadmines = "Deadmines", TheStockade = "Stockade", HallofThanes = "HallOfThanes",
  RuinsofLordaeron = "RuinsOfLordaeron", ExcavationSiteWetlands = "ExcavationSite", CityofDalaran = "Dalaran",
  TheDrownedCity = "DrownedCity", KroldokStronghold = "Kroldok", DireMaulEast = "DireMaul", DireMaulWest = "DireMaul",
  DireMaulNorth = "DireMaul", StratholmeLiving = "Stratholme", StratholmeUndead = "Stratholme" }
local bossCache = {}
-- mots trop courants dans les noms de boss pour servir à les reconnaître
local STOP = {}
for w in ("Keeper Stone Lord Lady Master Chief Captain Commander General Princess Prince King Queen Doctor Sergeant Overlord Highlord Ancient Elder Shadow Guard Baron Baroness Magister Archmage Instructor Lorekeeper Grand Twilight Shade Avatar Spawn Hunter Mother Quartermaster Warchief Pyroguard Golem Emperor Ambassador Houndmaster Interrogator Bloodmage Scarlet Inquisitor Arcanist Death Speaker Earthcaller Blind Razorfen Spirestone Crystal Burning Viscous Crowd Mekgineer Fallen Unbound Tidemistress Overseer Slavecrusher Handler Bossman Shaman Deathsworn Gutchewer Shadowpriest Hydromancer Cannon Archivist Postmaster Magistrate Warder Pyromancer Phalanx Plugger Screwspigot Blackbreath Darkvire Thorncurse Treasure Remains"):gmatch("%S+") do STOP[w] = true end
ns.BOSS_STOP = STOP
function ns.BossOrder(dkey)
  if bossCache[dkey] ~= nil then return bossCache[dkey] end
  local out = false
  local N = _G.NaowhForever
  local J = N and N.Journal
  if J and J.Get then
    local ok, d = pcall(J.Get, NKEY[dkey] or dkey)
    if ok and d and d.wings then
      out = { list = {}, idx = {} }
      for _, wing in ipairs(d.wings) do
        for _, b in ipairs(wing.bosses or {}) do
          if b.npc and not b.trash and not b.chest then
            local en = b.english or b.name
            table.insert(out.list, { en = en, name = b.name or en, tip = J.Tip and J.Tip(b) or nil, model = b.model, npc = b.npc })
            out.idx[en] = #out.list
            for tok in en:gmatch("[^%s,]+") do
              tok = tok:gsub("'s$", "")
              if #tok > 4 and not STOP[tok] then
                local k = "#" .. tok
                if out.idx[k] == nil then out.idx[k] = #out.list elseif out.idx[k] ~= #out.list then out.idx[k] = false end
              end
            end
          end
        end
      end
      -- ordre de passage réel (ns.WALK) ; les boss absents de cette liste restent derrière leur voisin du journal
      local walk = ns.WALK and ns.WALK[dkey]
      if walk and #out.list > 0 then
        local rank = {}
        for i, nm in ipairs(walk) do rank[nm] = i end
        local last = 0
        for i, b in ipairs(out.list) do
          if rank[b.en] then last = rank[b.en]; b.rk = rank[b.en] else b.rk = last + i / 1000 end
        end
        table.sort(out.list, function(a, b) return a.rk < b.rk end)
        local idx = {}
        for i, b in ipairs(out.list) do idx[b.en] = i end
        for k, v in pairs(out.idx) do
          if k:sub(1, 1) == "#" then
            if v then out.idx[k] = idx[(out.list[v] and out.list[v].en) or ""] or v end
          end
        end
        -- recalcul propre des index après tri
        local fresh = {}
        for i, b in ipairs(out.list) do
          fresh[b.en] = i
          for tok in b.en:gmatch("[^%s,]+") do
            tok = tok:gsub("'s$", "")
            if #tok > 4 and not STOP[tok] then
              local k = "#" .. tok
              if fresh[k] == nil then fresh[k] = i elseif fresh[k] ~= i then fresh[k] = false end
            end
          end
        end
        out.idx = fresh
      end
      if #out.list == 0 then out = false end
    end
  end
  bossCache[dkey] = out
  return out
end

function ns.ObjDone(log, qid, o)
  local s = ns.State(log, qid)
  if s == "done" or s == "ready" then return true end
  local e = log[qid]
  if e and e.index and GetNumQuestLeaderBoards and GetQuestLogLeaderBoard and o.n then
    for j = 1, (GetNumQuestLeaderBoards(e.index) or 0) do
      local text, _, finished = GetQuestLogLeaderBoard(j, e.index)
      if text and text:find(o.n, 1, true) then return finished and true or false end
    end
  end
  return false
end

local function BossOf(bo, names)
  for _, nm in ipairs(names) do if bo.idx[nm] then return bo.idx[nm] end end
  for _, nm in ipairs(names) do
    for tok in nm:gmatch("[^%s,]+") do
      tok = tok:gsub("'s$", "")
      local v = bo.idx["#" .. tok]
      if v then return v end
    end
  end
end

local function SplitOne(st)
  local bo = ns.BossOrder(st.ins)
  if not bo then return { st } end
  local items, order = {}, 0
  for _, nd in ipairs(st.acts) do
    order = order + 1
    local q = ns.Q[nd.q] or {}
    if nd.kind == "c" and q.o and #q.o > 0 then
      local first = true
      for oi, o in ipairs(q.o) do
        if not (o.w and not o.ins and not o.outer) then
          local names = {}
          for _, t in ipairs(o.t or {}) do table.insert(names, t) end
          for _, x in ipairs(o.src or {}) do if x[1] then table.insert(names, x[1]) end end
          if o.n then table.insert(names, o.n) end
          if q.oe then table.insert(names, q.oe) end
          local v = setmetatable({ oneObj = o, firstOfQuest = first, key = nd.key .. ":o" .. oi, base = nd }, { __index = nd })
          first = false
          order = order + 0.01
          table.insert(items, { node = v, boss = BossOf(bo, names), ord = order })
        end
      end
    else
      local names = {}
      if nd.npc then table.insert(names, nd.npc) end
      if nd.kind == "c" and q.oe then table.insert(names, q.oe) end
      table.insert(items, { node = nd, boss = BossOf(bo, names), ord = order })
    end
  end
  -- corrections à la main : objectif ramassé partout (« * »), ou quête entière liée à un boss
  local function bossByName(nm) return nm and bo.idx[nm] end
  for _, it in ipairs(items) do
    local n = it.node
    local o = n.oneObj
    local go = o and o.n and ns.GROUP_OBJ and ns.GROUP_OBJ[o.n]
    if go == "*" then it.boss = 999 elseif go then it.boss = bossByName(go) or it.boss end
    local gq = ns.GROUP_QUEST and ns.GROUP_QUEST[n.q]
    if gq then it.boss = bossByName(gq) or it.boss end
  end
  -- même PNJ / objet = même étape ; une prise sans boss emmène ses objectifs non rattachés
  local byNpc = {}
  for _, it in ipairs(items) do
    local n = it.node
    if n.npc and it.boss then byNpc[n.npc] = byNpc[n.npc] or it.boss end
  end
  for _, it in ipairs(items) do
    local n = it.node
    if not it.boss and n.npc and byNpc[n.npc] then it.boss = byNpc[n.npc] end
  end
  local aGroup = {}
  for _, it in ipairs(items) do
    local n = it.node
    if not it.boss and (n.kind == "a" or n.kind == "t") then
      it.boss = 0
      if n.npc then byNpc[n.npc] = 0 end
    end
    if n.kind == "a" then aGroup[n.q] = it.boss end
  end
  -- groupes : 0 = sur le chemin (PNJ / objets sans boss), 1..n = boss, 999 = dans tout le donjon
  for _, it in ipairs(items) do
    if not it.boss then
      local n = it.node
      if n.npc and byNpc[n.npc] then it.boss = byNpc[n.npc]
      elseif aGroup[n.q] == 0 then it.boss = 0
      else it.boss = 999 end
    end
  end
  table.sort(items, function(a, b) if a.boss ~= b.boss then return a.boss < b.boss end return a.ord < b.ord end)
  local groups, cur = {}, nil
  for _, it in ipairs(items) do
    if not cur or cur.boss ~= it.boss then cur = { boss = it.boss, acts = {} }; table.insert(groups, cur) end
    table.insert(cur.acts, it.node)
  end
  if #groups <= 1 and (not groups[1] or groups[1].boss == 999 or groups[1].boss == 0) then return { st } end
  local trash = {}
  for _, g in ipairs(groups) do
    if g.boss == 999 then for _, n in ipairs(g.acts) do table.insert(trash, n) end end
  end
  local out = {}
  for k, g in ipairs(groups) do
    local ns_ = { ins = st.ins, d = st.d, pos = st.pos, inner = st.inner, q = st.q, acts = g.acts, npcs = st.npcs,
      split = true, part = k, parts = #groups, bossIdx = g.boss, trash = (g.boss ~= 999) and trash or nil }
    local B = bo.list[g.boss]
    if B then ns_.bossName, ns_.bossEn, ns_.bossTip, ns_.bossModel, ns_.bossNpc = B.name, B.en, B.tip, B.model, B.npc end
    if k == 1 then ns_.travel = st.travel end
    table.insert(out, ns_)
  end
  return out
end

function ns.SplitInside(steps)
  local out = {}
  for _, st in ipairs(steps) do
    if st.ins and not st.gate and not st.split then
      for _, s2 in ipairs(SplitOne(st)) do table.insert(out, s2) end
    else table.insert(out, st) end
  end
  return out
end
