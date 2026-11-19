-- Ajouts vérifiés à la main : le Mallet of Zul'Farrak (objet, pas une quête) et ses étapes.
local ADDON, ns = ...

-- Pseudo-quête : le maillet pour invoquer Gahz'rilla (Sacred Mallet sur Qiaga, puis l'autel de Jintha'Alor).
local MALLET = -97100
ns.Q[MALLET] = {
  n = "Mallet of Zul'Farrak", nf = "Maillet de Zul'Farrak", l = 45, r = 40, fa = "Both", d = "ZulFarrak", ds = { "ZulFarrak" },
  role = "main", extra = true,
  oe = "Kill Qiaga the Keeper at the Altar of Zul for the Sacred Mallet, then use it at the altar on top of Jintha'Alor to make the Mallet of Zul'Farrak. Needed by one group member to summon Gahz'rilla.",
  ne = "The Hinterlands trolls around Jintha'Alor are level 45-50: bring a friend for the altar.",
  of = "Tue Qiaga the Keeper à l'Altar of Zul (Hinterlands) pour obtenir le Sacred Mallet, puis utilise-le sur l'autel au sommet de Jintha'Alor pour fabriquer le Mallet of Zul'Farrak. Un seul membre du groupe en a besoin pour invoquer Gahz'rilla.",
}
ns.TR["The Hinterlands trolls around Jintha'Alor are level 45-50: bring a friend for the altar."] =
  "Les trolls autour de Jintha'Alor (Hinterlands) sont niveau 45-50 : viens à deux pour l'autel."

-- Conseils ajoutés (FR/EN) pour les quêtes sans note dans les bases de données.
local NOTES = {
  [3520] = { "In Feralas, kill a Vale Screecher or Rogue Vale Screecher, use Yeh'kinya's Bramble on its corpse, then talk to the spirit that appears. Repeat 3 times.",
             "À Feralas, tue un Vale Screecher ou Rogue Vale Screecher, utilise Yeh'kinya's Bramble sur le cadavre, puis parle à l'esprit qui apparaît. À faire 3 fois." },
  [2284] = { "The Remains of a Paladin lie early in Uldaman, before the big hall. Right after, leave the dungeon: Jarkal Mossmeld in Kargath translates the journal and gives \"Find the Gems and Power Source\", whose gems drop inside (Grimlok, Archaedas, an urn, a cache). The instance stays as you left it if you come back within about 30 minutes.",
             "Les Restes d'un paladin sont au début d'Uldaman, avant la grande salle. Juste après, ressors du donjon : Jarkal Mossmeld, à Kargath, traduit le journal et donne « Trouver les Gemmes et la Source d'énergie », dont les gemmes sont dans le donjon (Grimlok, Archaedas, une urne, une cache). L'instance reste comme tu l'as laissée si tu reviens dans la demi-heure environ." },
  [2318] = { "Leave Uldaman now, before the rest of the dungeon: Kargath is close. Jarkal's next quest needs gems from Grimlok and Archaedas; killed before you have it, they do not drop.",
             "Ressors d'Uldaman maintenant, avant la suite du donjon : Kargath est tout près. La quête suivante de Jarkal demande des gemmes de Grimlok et d'Archaedas ; tués avant de l'avoir, ils ne les donnent pas." },
  [98325] = { "Accept this quest, then talk to Warlord Goretooth again and answer all his questions: he puts an item, Warlord Goretooth's Command, in your bags. Click it to start Warlord's Command. (Wowhead Forever, player comments.)",
              "Accepte cette quête, puis reparle à Warlord Goretooth et réponds à toutes ses questions : il met un objet, Warlord Goretooth's Command, dans tes sacs. Clique dessus pour démarrer « Ordre du chef de guerre ». (Wowhead Forever, commentaires de joueurs.)" },
  [2933] = { "The Venom Bottle is an object lying in the Witherbark troll camps of the Hinterlands: right-click it to get the quest.",
             "La Venom Bottle est un objet posé dans les camps des trolls Witherbark des Hinterlands : clic droit dessus pour obtenir la quête." },
}
for id, t in pairs(NOTES) do
  local q = ns.Q[id]
  if q and not q.ne then q.ne = t[1]; ns.TR[t[1]] = t[2] end
end
local zf = ns.D.ZulFarrak
if zf then table.insert(zf.q, MALLET) end

-- Franclorn Forgewright is a ghost: only the dead see him (report: "you have to be dead, but the
-- guide does not say it"; Wowhead comments). Said first, whatever the data's note was.
do
  local q = ns.Q[3801]
  if q then
    local en = "Franclorn is a ghost: you only see him and talk to him when you are dead. Die (the lava is fine), release, walk back as a ghost into Blackrock Mountain to the room on the way to Blackrock Depths and the Molten Core, talk to him, then resurrect at your body."
    q.ne = en
    ns.TR[en] = "Franclorn est un fantôme : on ne le voit et on ne lui parle qu'en étant mort. Meurs (la lave fait l'affaire), libère ton esprit, reviens en fantôme dans le Mont Rochenoire jusqu'à la salle sur le chemin des Profondeurs de Rochenoire et du Cœur du Magma, parle-lui, puis ressuscite à ton corps."
  end
end

-- The Last Element: the Essence of the Elements drops inside Blackrock Depths (its elementals and
-- golems); the data put the objective outside, on "Scald" in Searing Gorge (report: "it sent me
-- there, there is nothing for this quest"). The Challenge (Dungeon Set 0.5, level 58, through
-- Stratholme and more) is no Blackrock Depths quest for the guide: it took the route to Stratholme.
for _, id in ipairs({ 7201, 3911 }) do
  local q = ns.Q[id]
  for _, o in ipairs(q and q.o or {}) do
    if o.n == "Essence of the Elements" then o.ins, o.outer, o.w = true, nil, nil end
  end
end
do
  local d = ns.D.BlackrockDepths
  for i = #(d and d.q or {}), 1, -1 do if d.q[i] == 9015 then table.remove(d.q, i) end end
end

-- The Spectral Chalice needs Mining 230 (Smelt Dark Iron): a miner below it is not offered the quest
if ns.Q[4083] then ns.Q[4083].profLv = 230 end

-- Scarlet Diversions: the objective had no spot, so the route went straight to the turn-in. The
-- Scarlet camp is between Felstone Field and Dalson's Tears (Wowhead, quest text); the Flame in a
-- Bottle comes from the box of incendiaries beside Derrington.
do
  local q = ns.Q[5096]
  if q then
    q.o = { { k = "event", n = "Burn the command tent, plant the Scourge Banner", c = 1, ins = false, unk = false,
      w = { m = 1420, x = 40.7, y = 52.2, n = "Scarlet Crusade camp" } } }
    if not q.ne then
      q.ne = "Take a Flame in a Bottle from the box of incendiaries next to Derrington, then go to the Scarlet camp between Felstone Field and Dalson's Tears: use the flame on the command tent and plant the Scourge Banner beside it."
      ns.TR[q.ne] = "Prends une Flame in a Bottle dans la caisse d'incendiaires à côté de Derrington, puis va au camp écarlate entre le champ de Felstone et les Larmes de Dalson : utilise la flamme sur la tente de commandement et plante la Scourge Banner à côté."
    end
    ns.TR["Burn the command tent, plant the Scourge Banner"] = "Brûle la tente de commandement, plante la bannière du Fléau"
    ns.TR["Scarlet Crusade camp"] = "Camp de la Croisade écarlate"
  end
end

-- Blackrock Depths: the Kargath quests whose work is in the Depths (the Dark Iron guards and
-- officials, Overmaster Pyron at the door) count as the
-- dungeon's own quests, as in Naowh's journal, instead of lead-ins done before.
local brd = ns.D.BlackrockDepths
if brd then
  for _, id in ipairs({ 3906, 4081, 4082 }) do
    local q = ns.Q[id]
    if q and q.role ~= "main" then
      q.role = "main"
      local has = false
      for _, x in ipairs(brd.q) do if x == id then has = true end end
      if not has then table.insert(brd.q, id) end
      if id ~= 3906 then for _, o in ipairs(q.o or {}) do if o.k == "kill" or o.k == "talk" then o.ins = true end end end
    end
  end
end

local isDone = ns.IsDone
ns.IsDone = function(id)
  if id == MALLET then return ns.HasItem({ 9240, 9239 }) end
  return isDone(id)
end

function ns.Extras(nodes, byKey, add, sel, cls)
  if not sel.ZulFarrak or (WLDTDB.off and WLDTDB.off[MALLET]) then return end
  local hasG = byKey["c:2770"] or byKey["a:2770"]
  local i1 = add({ kind = "i", q = MALLET, sub = 1, items = { 9241, 9239, 9240 }, npc = "Qiaga the Keeper", tgt = { "Qiaga the Keeper" },
    loc = { m = 1425, x = 48.6, y = 68.2, n = "Qiaga the Keeper" }, d = "ZulFarrak", label = "Sacred Mallet",
    extra = ns.lang == "fr" and "Tue Qiaga the Keeper en haut de l'Altar of Zul : elle donne le Sacred Mallet." or "Kill Qiaga the Keeper on top of the Altar of Zul: she drops the Sacred Mallet." })
  local i2 = add({ kind = "i", q = MALLET, sub = 2, items = { 9239, 9240 }, useItems = { 9241 }, npc = "Jintha'Alor",
    loc = { m = 1425, x = 59.7, y = 77.8, n = "Altar of Jintha'Alor" }, d = "ZulFarrak", label = "Mallet of Zul'Farrak", deps = { i1 },
    extra = ns.lang == "fr" and "Monte au sommet de Jintha'Alor et utilise le Sacred Mallet sur l'autel." or "Climb to the top of Jintha'Alor and use the Sacred Mallet on the altar." })
  i2.deps = { i1 }
  if hasG and byKey["c:2770"] then table.insert(byKey["c:2770"].deps, i2) end
end

-- Une quête qu'on prend dehors, près de l'entrée, après une étape faite dans le donjon, et dont les
-- objectifs sont de nouveau dans le donjon (Uldaman, Horde : le journal sur les Restes d'un paladin,
-- Jarkal à Kargath, puis les gemmes de Grimlok et d'Archaedas). Faite après le donjon, il faut tout
-- refaire (signalement : « je viens de finir le donjon, faut le faire une 2e fois ? »). Le reste du
-- donjon attend donc l'aller-retour, quand il est court (PNJ à moins de NEAR_OUT mètres de l'entrée) ;
-- l'instance reste comme on l'a laissée. Un PNJ loin (une capitale) : la route ne change pas.
local NEAR_OUT = 1500
local function NodeInside(n, dk) return n.ins == dk and not (n.kind == "c" and n.outer) end
local function Ancestors(n, acc)
  acc = acc or {}
  for _, p in ipairs(n.deps or {}) do
    if not acc[p] then acc[p] = true; Ancestors(p, acc) end
  end
  return acc
end
local function NearEntrance(n, dk)
  local d = ns.D[dk]
  local e, loc = d and d.e, n.loc
  if not (e and loc and loc.m and ns.World) then return false end
  local a, b = ns.World(e.m, e.x, e.y), ns.World(loc.m, loc.x, loc.y)
  if not (a and b) or a[1] ~= b[1] then return false end
  return math.sqrt((a[2] - b[2]) ^ 2 + (a[3] - b[3]) ^ 2) <= NEAR_OUT
end
-- the gates of a dungeon: the accept nodes of such quests
function ns.ReentryGates(nodes, byKey, dk)
  local gates = {}
  for _, n in ipairs(nodes) do
    if n.kind == "a" and n.q and not n.ins and (byKey["c:" .. n.q] or byKey["o:" .. n.q .. ":1"]) then
      local objIn = false
      for _, m in ipairs(nodes) do
        if m.q == n.q and (m.kind == "c" or m.kind == "o") and NodeInside(m, dk) then objIn = true break end
      end
      if objIn then
        local anc = Ancestors(n)
        local inside, ok = false, NearEntrance(n, dk)
        for p in pairs(anc) do
          if NodeInside(p, dk) then inside = true end
        end
        -- every place visited outside after the inside step is near the entrance too
        if inside and ok then
          for p in pairs(anc) do
            if not p.ins and p.loc then
              local fromInside = false
              for pp in pairs(Ancestors(p)) do if NodeInside(pp, dk) then fromInside = true break end end
              if fromInside and not NearEntrance(p, dk) then ok = false break end
            end
          end
          if ok then gates[#gates + 1] = n end
        end
      end
    end
  end
  return gates
end
local extras = ns.Extras
ns.Extras = function(nodes, byKey, add, sel, cls)
  if extras then extras(nodes, byKey, add, sel, cls) end
  for dk in pairs(sel or {}) do
    local gates = ns.ReentryGates(nodes, byKey, dk)
    if #gates > 0 then
      local free = {}
      for _, g in ipairs(gates) do free[g] = true; for p in pairs(Ancestors(g)) do free[p] = true end end
      for _, n in ipairs(nodes) do
        if NodeInside(n, dk) and not free[n] then
          n.deps = n.deps or {}
          for _, g in ipairs(gates) do table.insert(n.deps, g) end
          n.midOut = true
        end
      end
    end
  end
end

-- Nom affiché pour les pseudo-étapes
local qname = ns.QName
ns.QName = function(qid)
  if qid == MALLET then return ns.lang == "fr" and "Maillet de Zul'Farrak" or "Mallet of Zul'Farrak" end
  return qname(qid)
end

-- Quêtes « principales » sans objectif à faire dans le donjon (simple discussion / livraison / artisanat) :
-- vérifié une à une d'après le texte d'objectif officiel.
for _, id in ipairs({ 6981, 78307, 78699, 1848, 1394, 96078, 2341, 94974, 92070, 95483, 4004, 4983, 7877 }) do
  if ns.Q[id] then ns.Q[id].noin = true end
end

-- =====================================================================
--  Clé de Scholomance (chaîne Horde, vérifiée dans LibForeverData + Zygor)
-- =====================================================================
if ns.Q[5511] then ns.Q[5511].noin = true end
do
  local q = ns.Q[5802]
  if q and q.o and q.o[1] then
    -- le moule se forge dans le lac de lave au sommet du Pic de Feu (Un'Goro)
    q.o[1].ns = false; q.o[1].w = { m = 1449, x = 48.8, y = 47.2, n = "Fire Plume Ridge" }
  end
  local N = {
    [5802] = { "Stand in the lava lake at the top of Fire Plume Ridge (Un'Goro Crater) to forge the Unfinished Skeleton Key. Krinkle Goodsteel charges 15 gold.",
               "Mets-toi dans le lac de lave au sommet du Pic de Feu (cratère d'Un'Goro) pour forger la Unfinished Skeleton Key. Krinkle Goodsteel demande 15 po." },
    [5514] = { "Krinkle Goodsteel (Gadgetzan) charges 15 gold to make the mold.",
               "Krinkle Goodsteel (Gadgetzan) demande 15 po pour fabriquer le moule." },
    [5511] = { "Rewards the Skeleton Key that opens Scholomance: only one group member needs it.",
               "Donne la Skeleton Key qui ouvre Scholomance : un seul membre du groupe en a besoin." },
  }
  for id, t in pairs(N) do
    local qq = ns.Q[id]
    if qq and not qq.ne then qq.ne = t[1]; ns.TR[t[1]] = t[2] end
  end
end

-- =====================================================================
--  Accès raid : Onyxia (le raid ouvre sur Forever le 9 décembre 2026, d'après Naowh)
--  Les quêtes restent rattachées à leur donjon réel (Pic Rochenoire) ; cette entrée les regroupe.
-- =====================================================================
if ns.Q[6602] and not ns.D.OnyxiasLair then
  ns.D.OnyxiasLair = {
    key = "OnyxiasLair", n = "Onyxia's Lair", nf = "Repaire d'Onyxia", short = "Ony", raid = true,
    lvl = { 60, 60 }, loc = "Dustwallow Marsh", locf = "Marécage d'Âprefange", inst = 249,
    e = { m = 1445, x = 52.9, y = 78.2 },
    ed = "Raid attunement: the Drakefire Amulet chain (Warlord's Command, Rexxar, the Test of Skulls, General Drakkisath). The raid opens on Forever on 9 December 2026.",
    icon = "Interface\\Icons\\INV_Misc_Head_Dragon_01",
    q = { 6602 },
  }
  ns.TR[ns.D.OnyxiasLair.ed] = "Accès au raid : la chaîne de l'Amulette Feu-drake (Ordre du seigneur de guerre, Rexxar, l'Épreuve des crânes, le général Drakkisath). Le raid ouvre sur Forever le 9 décembre 2026."
  table.insert(ns.ORDER, "OnyxiasLair")
end
-- The three raids open together on Forever on 9 December 2026 (Blizzard's roadmap): Barrow Deeps
-- (10 players), Hyjal Summit (20), Onyxia's Lair (40). Molten Core comes later, no date yet.
-- Until then they show as "upcoming"; their entrances and quests come with the raids.
local RAIDS_OPEN = 1796828400   -- 9 December 2026, 15:00 UTC
if ns.D.OnyxiasLair then ns.D.OnyxiasLair.up, ns.D.OnyxiasLair.size = RAIDS_OPEN, 40 end
for _, r in ipairs({
  { key = "BarrowDeeps", n = "Barrow Deeps", nf = "Barrow Deeps", short = "Barrow", size = 10, icon = "Interface\\Icons\\Spell_Nature_Sleep" },
  { key = "HyjalSummit", n = "Hyjal Summit", nf = "Sommet d'Hyjal", short = "Hyjal", size = 20, icon = "Interface\\Icons\\Spell_Fire_Fire" },
}) do
  if not ns.D[r.key] then
    r.raid, r.lvl, r.up, r.q = true, { 60, 60 }, RAIDS_OPEN, {}
    ns.D[r.key] = r
    table.insert(ns.ORDER, r.key)
  end
end

-- =====================================================================
--  Clés d'accès (d'après la table « Keys » de Naowh, vérifiée dans LibForeverData)
-- =====================================================================
local KEYS = {
  ScarletMonasteryArmory    = { { item = 7146, name = "The Scarlet Key", boss = 6487, bossn = "Arcanist Doan", src = "ScarletMonasteryLibrary" } },
  ScarletMonasteryCathedral = { { item = 7146, name = "The Scarlet Key", boss = 6487, bossn = "Arcanist Doan", src = "ScarletMonasteryLibrary" } },
  Scholomance               = { { item = 13704, name = "Skeleton Key", quest = 5511 } },
  UpperBlackrockSpire       = { { item = 12344, name = "Seal of Ascension", quest = 4743 } },
  OnyxiasLair               = { { item = 16309, name = "Drakefire Amulet", quest = 6602 } },
  DireMaulWest              = { { item = 18249, name = "Crescent Key", boss = 14354, bossn = "Pusillin", src = "DireMaulEast", opt = "doors" } },
  DireMaulNorth             = { { item = 18249, name = "Crescent Key", boss = 14354, bossn = "Pusillin", src = "DireMaulEast", opt = "doors" } },
  StratholmeLiving          = { { item = 12382, name = "Key to the City", boss = 10435, bossn = "Magistrate Barthilas", src = "StratholmeUndead", opt = "shortcut" } },
  StratholmeUndead          = { { item = 12382, name = "Key to the City", boss = 10435, bossn = "Magistrate Barthilas", src = "StratholmeUndead", opt = "shortcut" } },
  BlackrockDepths           = { { item = 11000, name = "Shadowforge Key", quest = 3802, opt = "shortcut" },
                                { item = 11140, name = "Prison Cell Key", boss = 9018, bossn = "High Interrogator Gerstahn", src = "BlackrockDepths", opt = "doors" } },
  Gnomeregan                = { { item = 6893, name = "Workshop Key", boss = 6235, bossn = "Electrocutioner 6000", src = "Gnomeregan", opt = "shortcut" } },
  Maraudon                  = { { item = 17191, name = "Scepter of Celebras", quest = 7046, opt = "shortcut" } },
}
ns.KEYS = KEYS

local function NaowhJ()
  local N = _G.NaowhForever
  return N and N.Journal
end
local function BossName(npc, fallback)
  local J = NaowhJ()
  if J and J.Boss then
    local ok, b = pcall(J.Boss, npc)
    if ok and b and b.name then return b.name end
  end
  return fallback
end

-- lignes « clé » pour un donjon : { texte, ok }
-- bare: without the "Key needed: " prefix (the summary row is already labelled "Key"); the
-- doors / shortcut labels stay, they say what the key is for.
function ns.KeyLines(dkey, bare)
  local out = {}
  for _, k in ipairs(KEYS[dkey] or {}) do
    local name = ns.ItemInfo(k.item)
    if type(name) ~= "string" or (issecretvalue and issecretvalue(name)) then name = k.name end
    local have = ns.ItemCount(k.item) > 0 or (k.quest and ns.IsDone(k.quest))
    local how
    if k.quest then how = ns.L.KEY_QUEST:format(ns.QName(k.quest))
    elseif k.boss then how = ns.Elide(ns.L.KEY_BOSS:format(BossName(k.boss, k.bossn), k.src and ns.DName(k.src) or "")) end
    local label = k.opt == "doors" and ns.L.KEY_DOORS or k.opt == "shortcut" and ns.L.KEY_SHORT or ns.L.KEY_REQ
    local Tk = ns.T_
    local txt = ((bare and not k.opt) and "" or (label .. ns.L.COLON)) .. name .. " · " .. (have and (ns.Hex(Tk.ok) .. ns.L.KEY_HAVE .. "|r") or (ns.Hex(Tk.warn) .. ns.L.KEY_MISSING .. "|r"))
    -- the key's own icon from the game, to spot it in the bags
    local ic = ns.ItemIcon(k.item)
    if ic then txt = ("|T%s:14:14:0:0:64:64:5:59:5:59|t "):format(tostring(ic)) .. txt end
    if not have and how then txt = txt .. "\n   " .. ns.Hex(Tk.muted) .. how .. "|r" end
    table.insert(out, { txt, have, k.opt == nil })
  end
  return out
end

-- Boss liés à une quête + conseil de Naowh (lus en direct dans Naowh Forever : Dungeon Journal)
local bossByQuest
function ns.BossLines(qid)
  local J = NaowhJ()
  if not (J and J.BossQuests) then return nil end
  if not bossByQuest then
    bossByQuest = {}
    for npc, ids in pairs(J.BossQuests) do
      for _, id in ipairs(ids) do
        bossByQuest[id] = bossByQuest[id] or {}
        table.insert(bossByQuest[id], npc)
      end
    end
  end
  local list = bossByQuest[qid]
  if not list then return nil end
  local out = {}
  for _, npc in ipairs(list) do
    local ok, b = pcall(J.Boss, npc)
    if ok and b then
      local tip = J.Tip and J.Tip(b)
      table.insert(out, { b.name or "?", tip })
    end
  end
  return #out > 0 and out or nil
end

-- Rexxar patrouille sur la route de Désolace (entre les Serres-Rocheuses et Feralas) : un seul point,
-- au bout feralien de sa ronde, et une note pour le chercher sur la route.
do
  local R = { m = 1444, x = 44.8, y = 7.4, n = "Rexxar" }
  local note = { "Rexxar patrols the road through Desolace between Stonetalon Mountains and Feralas: if he is not at the point, follow the road.",
                 "Rexxar patrouille sur la route de Désolace entre les Serres-Rocheuses et Feralas : s'il n'est pas au point, suis la route." }
  ns.TR[note[1]] = note[2]
  for id, q in pairs(ns.Q) do
    local touched = false
    if q.s and q.s.n == "Rexxar" and q.s.m then q.s = R; touched = true end
    if q.f and q.f.n == "Rexxar" and q.f.m then q.f = R; touched = true end
    if touched and not q.ne then q.ne = note[1] end
  end
end
-- Warlord's Command : les Important Blackrock Documents sont dans le Pic Rochenoire inférieur
do
  local q = ns.Q[4903]
  if q and q.o then
    for _, o in ipairs(q.o) do
      if o.n == "Important Blackrock Documents" then o.w = nil; o.ins = true; o.unk = false; o.outer = false end
    end
  end
end
-- A Lesson in Literacy (mage) : deux composants se trouvent dehors (positions LibForeverData)
do
  local q = ns.Q[82084]
  if q and not q.o then
    q.o = {
      { k = "item", n = "Pristine Owlbeast Quill", c = 1, w = { m = 1425, x = 29.7, y = 55.3, n = "Vicious Owlbeast" }, t = { "Vicious Owlbeast", "Primitive Owlbeast", "Savage Owlbeast" } },
      { k = "item", n = "Zukk'ash Resin", c = 1, w = { m = 1444, x = 74.8, y = 63.1, n = "Zukk'ash Wasp" }, t = { "Zukk'ash Wasp", "Zukk'ash Worker", "Zukk'ash Stinger", "Zukk'ash Tunneler" } },
      { k = "item", n = "Farraki Papyrus", c = 1, ins = true, t = { "Zul'Farrak Zombie" } },
    }
  end
end

-- Onyxia (Horde) : Emberstrife donne Scryer, Somnus et Chronalis en même temps ; Axtroz vient après les trois.
-- Vérifié avec le guide d'harmonisation de RestedXP (CC BY-NC-SA 4.0).
ns.PARALLEL = { [6583] = 6570, [6584] = 6570 }
ns.AFTER = { [6585] = { 6582, 6583, 6584 } }

-- Unending Torment (Ruines de Lordaeron) : suite à Fossoyeuse, ordre et détails vérifiés dans le guide RestedXP
-- (CC BY-NC-SA 4.0) ; positions des PNJ : LibForeverData.
do
  for _, id in ipairs({ 97289, 97290, 97291, 97292 }) do
    local q = ns.Q[id]
    if q then q.nf = q.nf or "Tourment interminable"; q.noin = true end
  end
  local q = ns.Q[97291]
  if q and q.o then
    local W = {
      ["Toxic Skullcap"] = { m = 1458, x = 65.2, y = 49.8, n = "Tawny Grisette" },
      ["Essence of Agony"] = { m = 1458, x = 75.2, y = 51.2, n = "Ezekiel Graves" },
      ["Blisterweed"] = { m = 1458, x = 54.0, y = 49.5, n = "Martha Alliestar" },
    }
    for _, o in ipairs(q.o) do if W[o.n] then o.w = W[o.n]; o.ns = false; o.t = { W[o.n].n } end end
    local t = { "Buy the Toxic Skullcap from Tawny Grisette (she walks around the Trade Quarter) and the Essence of Agony from Ezekiel Graves; take the Blisterweed from the pot behind Martha Alliestar.",
                "Achète le Toxic Skullcap à Tawny Grisette (elle se promène dans le quartier marchand) et l'Essence of Agony à Ezekiel Graves ; prends la Blisterweed dans le pot derrière Martha Alliestar." }
    q.ne = t[1]; ns.TR[t[1]] = t[2]
  end
  q = ns.Q[97292]
  if q then
    q.o = { { k = "item", n = "Hissing Serum", c = 1, w = { m = 1458, x = 45.3, y = 63.9, n = "Railing above Othmar" } } }
    local t = { "Use the Hissing Serum next to the worm upstairs in the Apothecarium, then go back to Faranell.",
                "Utilise le Hissing Serum à côté du ver, à l'étage de l'Apothicarium, puis retourne voir Faranell." }
    q.ne = t[1]; ns.TR[t[1]] = t[2]
    q.use = q.use or {}
  end
end

-- Suites de quêtes de donjon qui donnent la vraie récompense (repérées en croisant LibForeverData,
-- position sur la bonne carte quand deux zones se chevauchent)
do
  local fix = {
    [3374] = { f = { m = 1435, x = 13.7, y = 71.7, n = "Itharius" } },
  }
  for id, v in pairs(fix) do local q = ns.Q[id]; if q and v.f then q.f = v.f end end
  local q = ns.Q[5342]
  if q and q.o and q.o[1] and q.o[1].w then q.o[1].w = { m = 1422, x = 43.4, y = 83.7, n = "Weldon Barov" } end
  for _, id in ipairs({ 5729, 5730, 2440, 8181, 3374, 1952 }) do if ns.Q[id] then ns.Q[id].noin = true end end
  local N = {
    [5342] = { "Weldon Barov is at Chillwind Camp (Western Plaguelands), among the Alliance guards.",
               "Weldon Barov est au camp du Noroît (Maleterres de l'Ouest), au milieu des gardes de l'Alliance." },
    [5730] = { "The item reward of the Hidden Enemies chain is given on this last step.",
               "La récompense (objet) de la chaîne Ennemis cachés est donnée à cette dernière étape." },
  }
  for id, t in pairs(N) do local qq = ns.Q[id]; if qq and not qq.ne then qq.ne = t[1]; ns.TR[t[1]] = t[2] end end
end

-- Même quête sous deux numéros : le jeu peut utiliser l'un ou l'autre (Questie indique que 7668 a été
-- remplacée par 8258 dans Classic). On accepte les deux pour suivre la progression.
ns.ALIAS = { [7668] = 8258 }
do
  local isDone2 = ns.IsDone
  ns.IsDone = function(id)
    if isDone2(id) then return true end
    local a = ns.ALIAS[id]
    return a and isDone2(a) or false
  end
  local log2 = ns.LogEntries
  ns.LogEntries = function()
    local list = log2()
    for a, b in pairs(ns.ALIAS) do if list[b] and not list[a] then list[a] = list[b] end end
    return list
  end
end

-- Traductions des indices d'objets (ajoutées après contrôle du mode français)
ns.TR["Dropped by Moss Stalkers and Mist Creepers in the Skittering Dark, north-west of the Sepulcher (around 35, 12)"] = "Butin des Moss Stalkers et Mist Creepers dans le Skittering Dark, au nord-ouest du Sepulcher (vers 35, 12)"
ns.TR["Rubbing of the tablet Fall of Gurubashi, in the troll ruins on the coast north of the Vile Reef (around 23, 12)"] = "Calque de la tablette Fall of Gurubashi, dans les ruines trolls sur la côte au nord du Vile Reef (vers 23, 12)"
ns.TR["Found on Berard's Bookshelf in the Pyrewood Village inn (Silverpine Forest 43, 73)"] = "Sur la bibliothèque de Berard, dans l'auberge de Pyrewood Village (Silverpine Forest 43, 73)"
ns.TR["Dropped by Lake Skulkers and Elder Lake Skulkers on the Dawning Isles in Lordamere Lake (around 72, 35)"] = "Butin des Lake Skulkers et Elder Lake Skulkers sur les Dawning Isles du lac Lordamere (vers 72, 35)"
ns.TR["Dropped by Lake Creepers and Elder Lake Creepers on the Dawning Isles in Lordamere Lake (around 77, 25)"] = "Butin des Lake Creepers et Elder Lake Creepers sur les Dawning Isles du lac Lordamere (vers 77, 25)"
ns.TR["Rare drop from Vile Fin murlocs around Lordamere Lake; the higher-level ones on the Dawning Isles and on the south-west shore behind Ambermill are the best bet"] = "Butin rare des murlocs Vile Fin autour du lac Lordamere ; les plus hauts niveaux, sur les Dawning Isles et sur la rive sud-ouest derrière Ambermill, sont le meilleur choix"
ns.TR["Dropped by Vicious, Primitive and Savage Owlbeasts in The Hinterlands"] = "Butin des Vicious, Primitive et Savage Owlbeasts dans les Hinterlands"
ns.TR["Dropped by the Zukk'ash silithid in Feralas, south of Camp Mojache (around 73, 63)"] = "Butin des silithides Zukk'ash à Feralas, au sud de Camp Mojache (vers 73, 63)"
ns.TR["Dropped by the Zul'Farrak Zombies that rise from the graves in Zul'Farrak"] = "Butin des Zul'Farrak Zombies qui sortent des tombes dans Zul'Farrak"
ns.TR["Dropped by: Plagued Hatchling"] = "Butin de : Plagued Hatchling"
ns.TR["Dropped by Brinescale Skirmishers around the Vile Reef, west of Grom'gol (around 22, 26)"] = "Butin des Brinescale Skirmishers autour du Vile Reef, à l'ouest de Grom'gol (vers 22, 26)"
ns.TR["Dropped by the Rot Hide gnolls on Fenris Isle (Rot Hide Savage, Raging Rot Hide, Rot Hide Bruiser, Snarlmane)"] = "Butin des gnolls Rot Hide sur l'île de Fenris (Rot Hide Savage, Raging Rot Hide, Rot Hide Bruiser, Snarlmane)"
ns.TR["From Veenix, Stonetalon Mountains, for a Venture Co. Work Order. Blows open the courtyard gate of Shadowfang Keep"] = "Chez Veenix (Stonetalon Mountains), contre un Venture Co. Work Order. Fait sauter la porte de la cour d'Ombrecroc"
ns.TR["Dropped by Riptear (level 13 elite) in Venomweb Vale, north-east Tirisfal Glades (around 84, 44)"] = "Butin de Riptear (élite niveau 13) dans Venomweb Vale, au nord-est de Tirisfal (vers 84, 44)"
ns.TR["From the tablet Gri'lek the Wanderer, at the bottom of the Vile Reef (around 25, 23)"] = "Sur la tablette Gri'lek the Wanderer, au fond du Vile Reef (vers 25, 23)"
-- indice numérique sans texte (données) : ignoré
for _, q in pairs(ns.Q) do for _, r in ipairs(q.req or {}) do if type(r[3]) ~= "string" or r[3]:match("^%d+$") then r[3] = nil end end end

-- Noms français officiels des donjons (client français) quand les données n'en ont pas.
-- Sources : noms du jeu relevés par Naowh (Monastère écarlate, Tranchebauge, Dalaran, Paluns) et noms Classic connus.
-- Les donjons propres à Forever sans nom français connu gardent leur nom anglais.
do
  local NF = {
    ExcavationSiteWetlands = "Excavations : les Paluns", CityofDalaran = "Cité de Dalaran",
    RazorfenKraul = "Kraal de Tranchebauge", RazorfenDowns = "Souilles de Tranchebauge",
    ScarletMonasteryGraveyard = "Monastère écarlate : Cimetière", ScarletMonasteryLibrary = "Monastère écarlate : Bibliothèque",
    ScarletMonasteryArmory = "Monastère écarlate : Armurerie", ScarletMonasteryCathedral = "Monastère écarlate : Cathédrale",
    SunkenTemple = "Le temple d'Atal'Hakkar", BlackrockDepths = "Profondeurs de Rochenoire",
    LowerBlackrockSpire = "Pic Rochenoire inférieur", UpperBlackrockSpire = "Pic Rochenoire supérieur",
    DireMaulEast = "Hache-tripes : Est", DireMaulWest = "Hache-tripes : Ouest", DireMaulNorth = "Hache-tripes : Nord",
    StratholmeLiving = "Stratholme : Vivants", StratholmeUndead = "Stratholme : Morts-vivants",
  }
  for k, v in pairs(NF) do local d = ns.D[k]; if d and not d.nf then d.nf = v end end
end
-- Ordre de passage des boss dans chaque donjon (le journal de Naowh range les boss optionnels à la fin).
-- Séquence vérifiée avec le guide de donjon de Zygor (ordre seulement, aucun texte repris).
ns.WALK = {
  RagefireChasm = { "Oggleflint", "Taragaman the Hungerer", "Jergosh the Invoker", "Bazzalan" },
  WailingCaverns = { "Kresh", "Lady Anacondra", "Lord Cobrahn", "Deviate Faerie Dragon", "Lord Pythas", "Skum", "Lord Serpentis", "Verdan the Everliving", "Mutanus the Devourer" },
  RuinsofLordaeron = { "Witherfang", "The Baron", "The Abandoned", "Viktor the Vile", "Bjork", "Rath'mael" },
  TheDeadmines = { "Rhahk'Zor", "Miner Johnson", "Sneed's Shredder", "Gilnid", "Mr. Smite", "Captain Greenskin", "Edwin VanCleef", "Cookie" },
  ShadowfangKeep = { "Rethilgore", "Razorclaw the Butcher", "Baron Silverlaine", "Commander Springvale", "Odo the Blindwatcher", "Deathsworn Captain", "Fenrus the Devourer", "Archmage Arugal" },
  ExcavationSiteWetlands = { "Saltspine", "Relic Guardian" },
  BlackfathomDeeps = { "Ghamoo-ra", "Lady Sarevess", "Gelihast", "Twilight Lord Kelris", "Old Serra'kis", "Aku'mai" },
  Gnomeregan = { "Grubbis", "Viscous Fallout", "Electrocutioner 6000", "Crowd Pummeler 9-60", "Dark Iron Ambassador", "Mekgineer Thermaplugg" },
  CityofDalaran = { "Atrexis the Grave Knight", "Lyn the Ignored", "Arcane Anomaly", "Arcanic Enigma", "Unstable Sentinel", "Fel Ancient", "Mana Devourer", "Shade of the Archmage" },
  RazorfenKraul = { "Roogug", "Aggem Thorncurse", "Death Speaker Jargba", "Overlord Ramtusk", "Agathelos the Raging", "Blind Hunter", "Earthcaller Halmgar", "Charlga Razorflank" },
  ScarletMonasteryGraveyard = { "Interrogator Vishas", "Bloodmage Thalnos", "Azshir the Sleepless", "Fallen Champion", "Ironspine" },
  ScarletMonasteryLibrary = { "Houndmaster Loksey", "Arcanist Doan" },
  ScarletMonasteryCathedral = { "Scarlet Commander Mograine", "High Inquisitor Whitemane", "High Inquisitor Fairbanks" },
  RazorfenDowns = { "Tuten'kash", "Mordresh Fire Eye", "Glutton", "Ragglesnout", "Amnennar the Coldbringer", "Plaguemaw the Rotting" },
  Uldaman = { "Baelog", "Revelosh", "Ironaya", "Obsidian Sentinel", "Ancient Stone Keeper", "Galgann Firehammer", "Grimlok", "Archaedas" },
  ZulFarrak = { "Theka the Martyr", "Antu'sul", "Witch Doctor Zum'rah", "Nekrum Gutchewer", "Shadowpriest Sezz'ziz", "Sergeant Bly", "Hydromancer Velratha", "Gahz'rilla", "Ruuzlu", "Chief Ukorz Sandscalp", "Zerillis" },
  -- the run's default: orange wing, purple wing, then the inner caves (ns.WALK_WINGS below; Bosses.lua
  -- puts the wing you start in first)
  Maraudon = { "Noxxion", "Razorlash", "Lord Vyletongue", "Meshlok the Harvester", "Celebras the Cursed", "Landslide", "Tinkerer Gizlock", "Rotgrip", "Princess Theradras" },
  SunkenTemple = { "Atal'alarion", "Jammal'an the Prophet", "Ogom the Wretched", "Dreamscythe", "Weaver", "Hazzas", "Morphaz", "Shade of Eranikus", "Avatar of Hakkar" },
  BlackrockDepths = { "High Interrogator Gerstahn", "Lord Roccor", "Houndmaster Grebmar", "Fineous Darkvire", "Lord Incendius", "Pyromancer Loregrain", "Bael'Gar", "General Angerforge", "Golem Lord Argelmach", "Phalanx", "Ambassador Flamelash", "Panzor the Invincible", "Magmus", "Emperor Dagran Thaurissan" },
  Scholomance = { "Kirtonos the Herald", "Jandice Barov", "Rattlegore", "Marduk Blackpool", "Vectus", "Ras Frostwhisper", "Instructor Malicia", "Doctor Theolen Krastinov", "Lorekeeper Polkelt", "The Ravenian", "Lord Alexei Barov", "Lady Illucia Barov", "Darkmaster Gandling" },
  StratholmeLiving = { "Skul", "Hearthsinger Forresten", "The Unforgiven", "Postmaster Malown", "Timmy the Cruel", "Malor the Zealous", "Cannon Master Willey", "Archivist Galford", "Balnazzar" },
  StratholmeUndead = { "Magistrate Barthilas", "Nerub'enkan", "Baroness Anastari", "Stonespine", "Maleki the Pallid", "Ramstein the Gorger", "Baron Rivendare" },
  DireMaulEast = { "Pusillin", "Lethtendris", "Hydrospawn", "Zevrim Thornhoof", "Alzzin the Wildshaper" },
  DireMaulNorth = { "Guard Mol'dar", "Stomper Kreeg", "Guard Fengus", "Guard Slip'kik", "Captain Kromcrush", "Cho'Rush the Observer", "King Gordok" },
  DireMaulWest = { "Tendris Warpwood", "Magister Kalendris", "Tsu'zee", "Illyanna Ravenoak", "Immol'thar", "Prince Tortheldrin" },
  LowerBlackrockSpire = { "Spirestone Butcher", "Spirestone Battle Lord", "Highlord Omokk", "Shadow Hunter Vosh'gajin", "War Master Voone", "Bannok Grimaxe", "Mother Smolderweb", "Crystal Fang", "Urok Doomhowl", "Quartermaster Zigris", "Halycon", "Gizrul the Slavener", "Overlord Wyrmthalak" },
  UpperBlackrockSpire = { "Pyroguard Emberseer", "Solakar Flamewreath", "Jed Runewatcher", "Goraluk Anvilcrack", "Warchief Rend Blackhand", "Gyth", "The Beast", "General Drakkisath" },
  HallofThanes = { "Faldrim Anvilmar", "Magmatus", "Plunder", "Durgen Dirgehammer" },
}
-- Dungeons entered by several wings that meet further in. Each wing: its bosses in walking order,
-- the subzones that are it (English and French client names), and points on its instance map
-- (uiMap `map`, 0-1 coordinates) near its bosses; `tail`: the shared part, walked after every wing;
-- `last`: an objective done at whichever of its bosses comes later in the run. The first wing is
-- the default (the one most guides take first, with most quest objectives). Bosses.lua builds
-- ns.WALK[key] from it: the wing you start in, the other wings, then the tail.
ns.WALK_WINGS = {
  Maraudon = {
    { key = "orange", bosses = { "Noxxion", "Razorlash" },
      zones = { "Foulspore Cavern", "Foulspore Caverns", "Foulspore Pools", "Maraudon - Foulspore Cavern Entrance",
        "Caverne Vilespore", "Bassins Vilespore", "Maraudon - Entrée de la caverne Vilespore" },
      pts = { { 0.358, 0.103 }, { 0.162, 0.343 } } },
    { key = "purple", bosses = { "Lord Vyletongue", "Meshlok the Harvester" },
      zones = { "The Wicked Grotto", "Vyletongue Seat", "Maraudon - The Wicked Grotto Entrance",
        "La grotte Maudite", "Siège de Vylelangue", "Maraudon - Entrée de la grotte Maudite" },
      pts = { { 0.377, 0.713 }, { 0.243, 0.708 } } },
    tail = { "Celebras the Cursed", "Landslide", "Tinkerer Gizlock", "Rotgrip", "Princess Theradras" },
    map = 280, near = 0.2,
    last = { ["Amulet of Union"] = { "Lord Vyletongue", "Noxxion" } },
  },
}

-- =====================================================================
--  Rangement dans les étapes du donjon : corrections à la main
-- =====================================================================
ns.GROUP_OBJ = {   -- objectif ramassé un peu partout (pas sur un boss)
  ["Troll Temper"] = "*", ["Uncracked Scarab Shell"] = "*",
  ["Dentrium Power Stone"] = "*", ["An'Alleum Power Stone"] = "*", ["Tablet of Ryun'eh"] = "*",
  ["Theradric Crystal Carving"] = "*",
  -- The Pariah's Instructions (7067): Maraudos in the purple wing (Vyletongue's), Veng in the orange
  -- one (Noxxion's); the five gems are combined once the second wing is done (ns.WALK_WINGS `last`:
  -- Bosses.lua moves it to whichever of the two comes later in the run)
  ["Gem of the Fourth Kahn"] = "Lord Vyletongue", ["Gem of the Fifth Kahn"] = "Noxxion",
  ["Amulet of Union"] = "Lord Vyletongue",
}
ns.GROUP_QUEST = { -- toute la quête se fait au même boss
  [7066] = "Princess Theradras",   -- l'esprit de Zaetar apparaît après Theradras
  [3447] = "Atal'alarion",         -- le cercle de statues qui invoque Atal'alarion (étage du haut)
  -- l'Essence d'Eranikus tombe sur l'Ombre d'Eranikus (avant-dernier boss) et se rend au réceptacle
  -- juste à côté : prise et rendue là, pas « en chemin » au début du donjon (report : « la première
  -- quête de ton guide mais le dernier boss du donjon »)
  [3373] = "Shade of Eranikus",
}
-- « En chemin, fais aussi » (T-92) : une ligne du donjon qui ne se fait sur aucun boss mais sur le
-- chemin d'un boss (entre le boss d'avant et lui). Clé = objectif ou id de quête ; valeur =
-- { boss, où (anglais), où (français) } ; boss « * » = dans tout le donjon (première étape dedans).
-- Une ligne absente d'ici reste à l'étape « À finir dans le donjon » seulement.
ns.ALONG_OBJ = {
  Maraudon = {
    ["Noxxious Scion"] = { "Noxxion", "Orange wing, Vylestem Vines before Noxxion", "Aile orange, vignes de Vylevrille avant Noxxion" },
    ["Vial of Earth Song Water"] = { "Rotgrip", "Earth Song Falls, the geyser in Rotgrip's pools", "Chutes de Chantterre, le geyser des bassins de Rotgrip" },
    [96776] = { "Princess Theradras", "Past Earth Song Falls, the white crystal chamber (giants)", "Après les chutes de Chantterre, la salle aux cristaux blancs (géants)" },
  },
  SunkenTemple = {
    ["Atal'ai Haze"] = { "*" },
  },
}

-- =====================================================================
--  Guide du donjon boss par boss (données et textes écrits pour l'addon)
-- =====================================================================
-- Une ligne de quête qu'aucun boss ne réclame : clé = id de quête, PNJ ou objectif ;
-- valeur = "Boss" (à ce boss) ou "<Boss" (en route vers lui). Sinon : le boss le plus proche
-- du PNJ d'après LibForeverData, sinon au début.
ns.WALK_AT = {
  ZulFarrak = { ["Tablet of Theka"] = "Theka the Martyr" },
  Maraudon = { ["Celebras the Redeemed"] = "Celebras the Cursed" },
}

-- Où trouver le boss : une courte indication de chemin { anglais, français }.
ns.BOSS_PATH = {
  TheDeadmines = {
    ["Rhahk'Zor"] = { "First big cave after the entrance tunnel, by the door to the mine.", "Première grande grotte après le tunnel d'entrée, près de la porte de la mine." },
    ["Sneed's Shredder"] = { "Lumber mill, past the door Rhahk'Zor guarded.", "La scierie, après la porte que gardait Rhahk'Zor." },
    ["Gilnid"] = { "The foundry, on the ledge along the molten channel.", "La fonderie, sur la corniche le long de la rigole de métal en fusion." },
    ["Mr. Smite"] = { "Fire the cannon at the cove gate: Mr. Smite comes with the defenders.", "Tire au canon sur la porte de la crique : Mr. Smite arrive avec les défenseurs." },
    ["Captain Greenskin"] = { "On the ship's deck.", "Sur le pont du navire." },
    ["Edwin VanCleef"] = { "Captain's cabin at the top of the ship.", "La cabine du capitaine, en haut du navire." },
    ["Cookie"] = { "In the ship's galley, below deck.", "Dans la cambuse du navire, sous le pont." },
  },
}

-- Tactique courte quand le journal de Naowh n'est pas chargé : { rôle, anglais, français } par
-- ligne (tank, heal, all), « {Capacité} » est mise en couleur. Trois lignes au plus.
ns.BOSS_NOTES = {
  RagefireChasm = {
    ["Oggleflint"] = { { "all", "{Cleave}: only the tank stands in front.", "{Enchaînement} : seul le tank reste devant." } },
    ["Taragaman the Hungerer"] = { { "all", "{Fire Nova} burns everyone near him: casters and healer stay at range.", "{Nova de feu} brûle tous ceux qui sont près de lui : lanceurs de sorts et soigneur restent à distance." } },
    ["Jergosh the Invoker"] = { { "all", "Interrupt his {Immolate}.", "Interromps son {Immolation}." },
      { "heal", "{Curse of Weakness} on the tank: decurse it.", "{Malédiction de faiblesse} sur le tank : décurse-la." } },
    ["Bazzalan"] = { { "heal", "Satyr rogue: cure his poison on the tank.", "Satyre voleur : guéris le poison qu'il met sur le tank." } },
  },
  TheDeadmines = {
    ["Rhahk'Zor"] = { { "tank", "Hits hard but has no tricks: keep him facing away from the group.", "Frappe fort mais sans piège : garde-le dos au groupe." } },
    ["Sneed's Shredder"] = { { "all", "When the Shredder breaks, Sneed jumps out: kill him too.", "Quand le Shredder casse, Sneed en sort : tue-le aussi." } },
    ["Gilnid"] = { { "all", "Clear the goblins around the foundry before pulling him.", "Nettoie les gobelins autour de la fonderie avant de l'attaquer." } },
    ["Mr. Smite"] = { { "all", "{Smite Stomp} stuns everyone twice in the fight: heal through it.", "{Piétinement de Smite} (Smite Stomp) étourdit tout le monde deux fois : soigne pendant." },
      { "tank", "He swaps weapons after each stomp and hits harder.", "Il change d'arme après chaque piétinement et frappe plus fort." } },
    ["Captain Greenskin"] = { { "all", "{Cleave}: only the tank stands in front.", "{Enchaînement} : seul le tank reste devant." } },
    ["Edwin VanCleef"] = { { "all", "Calls two Blackguards at low health: kill VanCleef first.", "Appelle deux gardes noirs quand sa vie baisse : tue VanCleef en premier." } },
    ["Cookie"] = { { "all", "He heals with his food: focus him down quickly.", "Il se soigne avec sa cuisine : tue-le vite." } },
  },
  WailingCaverns = {
    ["Kresh"] = { { "all", "Optional turtle in the water: slow, no tricks.", "Tortue optionnelle dans l'eau : lente, sans piège." } },
    ["Lady Anacondra"] = { { "all", "{Sleep}: dispel it; interrupt her {Lightning Bolt}.", "{Sommeil} : dissipe-le ; interromps son {Éclair}." } },
    ["Lord Cobrahn"] = { { "all", "Interrupt his {Lightning Bolt}; dispel {Sleep}.", "Interromps son {Éclair} ; dissipe le {Sommeil}." },
      { "heal", "At low health he turns into a serpent and poisons: cure it.", "Quand sa vie baisse, il devient serpent et empoisonne : guéris le poison." } },
    ["Deviate Faerie Dragon"] = { { "all", "Rare, not always here. Casts {Sleep}: dispel it.", "Rare, pas toujours là. Lance {Sommeil} : dissipe-le." } },
    ["Lord Pythas"] = { { "all", "Interrupt his {Healing Touch}.", "Interromps son {Toucher guérisseur}." } },
    ["Skum"] = { { "all", "His lightning jumps between players close together: spread out.", "Son éclair saute d'un joueur à l'autre quand ils sont proches : écartez-vous." } },
    ["Lord Serpentis"] = { { "all", "Interrupt his {Healing Touch}.", "Interromps son {Toucher guérisseur}." } },
    ["Verdan the Everliving"] = { { "all", "{Grasping Vines} knock down everyone near him: ranged stay back.", "Ses lianes renversent tous ceux qui sont près de lui : les distances restent loin." } },
    ["Mutanus the Devourer"] = { { "all", "Only comes if the four Fanglords (Anacondra, Cobrahn, Pythas, Serpentis) are dead: then escort the Disciple of Naralex.", "N'apparaît que si les quatre seigneurs du Croc (Anacondra, Cobrahn, Pythas, Serpentis) sont morts : escorte ensuite le disciple de Naralex." },
      { "heal", "{Naralex's Nightmare} puts a player to sleep: dispel it.", "{Cauchemar de Naralex} endort un joueur : dissipe-le." } },
  },
  ShadowfangKeep = {
    ["Rethilgore"] = { { "all", "Plain melee fight. After him, talk to the freed prisoner: he opens the courtyard door.", "Combat simple. Ensuite, parle au prisonnier libéré : il ouvre la porte de la cour." } },
    ["Razorclaw the Butcher"] = { { "tank", "Plain melee fight: keep him facing away from the group.", "Combat simple : garde-le dos au groupe." } },
    ["Baron Silverlaine"] = { { "all", "{Veil of Shadow} (curse) cuts your heals: decurse it.", "{Voile d'ombre} (malédiction) réduit tes soins : décurse-le." } },
    ["Commander Springvale"] = { { "all", "{Holy Light}: interrupt it.", "{Lumière sacrée} : interromps-la." } },
    ["Odo the Blindwatcher"] = { { "all", "{Howling Rage} makes him hit faster as his health drops: save cooldowns for the end.", "{Rage hurlante} le fait frapper plus vite quand sa vie baisse : garde tes temps de recharge pour la fin." } },
    ["Deathsworn Captain"] = { { "all", "Rare, not always here. {Cleave}: only the tank in front.", "Rare, pas toujours là. {Enchaînement} : seul le tank devant." } },
    ["Fenrus the Devourer"] = { { "heal", "{Toxic Saliva}: cure the poison.", "{Salive toxique} : guéris le poison." } },
    ["Archmage Arugal"] = { { "all", "He teleports between ledges and casts {Void Bolt}: interrupt it.", "Il se téléporte de corniche en corniche et lance {Trait du Vide} : interromps-le." } },
  },
  BlackfathomDeeps = {
    ["Ghamoo-ra"] = { { "all", "Big armored turtle: slow to kill, his {Trample} hits the melee.", "Grosse tortue cuirassée : longue à tuer, son piétinement touche les mêlées." } },
    ["Lady Sarevess"] = { { "all", "{Forked Lightning} hits a cone in front of her: only the tank in front.", "Son éclair fourchu frappe en cône devant elle : seul le tank reste devant." } },
    ["Gelihast"] = { { "all", "Clear the murlocs in his cave first; his {Net} roots the melee.", "Nettoie d'abord les murlocs de sa grotte ; son {Filet} immobilise les mêlées." } },
    ["Twilight Lord Kelris"] = { { "heal", "He puts a player to {Sleep}: dispel it.", "Il endort un joueur ({Sommeil}) : dissipe-le." },
      { "all", "Lighting the four braziers at the altar opens Aku'mai's door, each one calls a wave of adds.", "Allumer les quatre braseros de l'autel ouvre la porte d'Aku'mai, chacun appelle une vague de monstres." } },
    ["Old Serra'kis"] = { { "all", "Fought underwater: watch your breath bar.", "Combat sous l'eau : surveille ta barre de souffle." } },
    ["Aku'mai"] = { { "all", "Move out of her {Poison Cloud}; she enrages at low health: save your cooldowns.", "Sors de son nuage de poison ; elle enrage quand sa vie baisse : garde tes temps de recharge." } },
  },
  TheStockade = {
    ["Targorr the Dread"] = { { "all", "Plain melee fight; he enrages at low health.", "Combat simple ; il enrage quand sa vie baisse." } },
    ["Kam Deepfury"] = { { "all", "Plain melee fight in his cell.", "Combat simple dans sa cellule." } },
    ["Hamhock"] = { { "all", "His lightning jumps between players close together: spread out.", "Son éclair saute d'un joueur à l'autre quand ils sont proches : écartez-vous." } },
    ["Bazil Thredd"] = { { "all", "Throws bombs that stun: heal through it.", "Lance des bombes qui étourdissent : soigne pendant." } },
    ["Dextren Ward"] = { { "all", "His shout fears the group: fight him away from other packs.", "Son cri apeure le groupe : combats-le loin des autres groupes." } },
    ["Bruegal Ironknuckle"] = { { "all", "Rare, not always here. Plain melee fight.", "Rare, pas toujours là. Combat simple." } },
  },
  Gnomeregan = {
    ["Grubbis"] = { { "all", "Comes at the end of Emi Shortfuse's event: keep her alive through the trogg waves.", "Arrive à la fin de l'événement d'Emi Shortfuse : garde-la en vie pendant les vagues de troggs." } },
    ["Viscous Fallout"] = { { "all", "Optional ooze: its nature damage hits the whole group, top everyone up.", "Limon optionnel : ses dégâts de nature touchent tout le groupe, garde tout le monde en vie." } },
    ["Electrocutioner 6000"] = { { "all", "Its lightning jumps between players close together: spread out. Drops the Workshop Key.", "Son éclair saute d'un joueur à l'autre quand ils sont proches : écartez-vous. Donne la Workshop Key." } },
    ["Crowd Pummeler 9-60"] = { { "all", "{Crowd Pummel} knocks back the melee: tank it against a wall.", "Il repousse les mêlées : tanke-le dos à un mur." } },
    ["Dark Iron Ambassador"] = { { "all", "Rare, not always here. Fire caster: interrupt what you can.", "Rare, pas toujours là. Lanceur de feu : interromps ce que tu peux." } },
    ["Mekgineer Thermaplugg"] = { { "all", "Bombs walk out of the vents: press the button next to a vent to close it, kill the bombs before they reach you.", "Des bombes sortent des bouches : appuie sur le bouton à côté pour la fermer, tue les bombes avant qu'elles arrivent." },
      { "tank", "{Knock Away}: tank him against a wall.", "Il te repousse : tanke-le dos à un mur." } },
  },
  RazorfenKraul = {
    ["Roogug"] = { { "all", "Quilboar caster: interrupt him and kill him fast.", "Lanceur de sorts huran : interromps-le et tue-le vite." } },
    ["Aggem Thorncurse"] = { { "all", "Interrupt his heals; kill the boar spirit he calls.", "Interromps ses soins ; tue l'esprit de sanglier qu'il appelle." } },
    ["Death Speaker Jargba"] = { { "all", "{Dominate Mind} takes control of a player: crowd-control them, never kill them.", "Il prend le contrôle d'un joueur : neutralise-le, ne le tue pas." } },
    ["Overlord Ramtusk"] = { { "all", "Comes with guards: crowd-control or kill them first.", "Arrive avec des gardes : neutralise-les ou tue-les d'abord." } },
    ["Agathelos the Raging"] = { { "all", "His rampage hits every melee around him; he enrages at low health.", "Sa charge furieuse touche les mêlées autour de lui ; il enrage quand sa vie baisse." } },
    ["Blind Hunter"] = { { "all", "Rare, not always here: a bat, plain fight.", "Rare, pas toujours là : une chauve-souris, combat simple." } },
    ["Earthcaller Halmgar"] = { { "all", "Rare, not always here. Calls an earth elemental: off-tank it or kill it first.", "Rare, pas toujours là. Appelle un élémentaire de terre : prends-le à part ou tue-le d'abord." } },
    ["Charlga Razorflank"] = { { "all", "Interrupt her heals; kill her guards first.", "Interromps ses soins ; tue ses gardes d'abord." } },
  },
  ScarletMonasteryGraveyard = {
    ["Interrogator Vishas"] = { { "heal", "{Shadow Word: Pain} on the tank: dispel it.", "{Mot de l'ombre : Douleur} sur le tank : dissipe-le." } },
    ["Bloodmage Thalnos"] = { { "all", "Fire and shadow caster: interrupt his {Shadow Bolt}.", "Lanceur de feu et d'ombre : interromps son {Trait de l'ombre}." } },
    ["Azshir the Sleepless"] = { { "all", "Rare, not always here. He fears a player and drains life.", "Rare, pas toujours là. Il apeure un joueur et draine sa vie." } },
    ["Fallen Champion"] = { { "all", "Rare, not always here. Plain melee fight.", "Rare, pas toujours là. Combat simple." } },
    ["Ironspine"] = { { "all", "Rare, not always here. Plain melee fight.", "Rare, pas toujours là. Combat simple." } },
  },
  ScarletMonasteryLibrary = {
    ["Houndmaster Loksey"] = { { "all", "Calls hounds and casts {Bloodlust}: kill the hounds off the healer.", "Appelle des chiens et lance {Furie sanguinaire} : éloigne les chiens du soigneur." } },
    ["Arcanist Doan"] = { { "all", "When his {Arcane Bubble} goes up, run away: {Detonation} follows.", "Quand sa bulle arcanique apparaît, éloigne-toi : une détonation suit." },
      { "heal", "He polymorphs and silences: dispel the {Polymorph}.", "Il métamorphose et réduit au silence : dissipe la {Métamorphose}." } },
  },
  ScarletMonasteryArmory = {
    ["Herod"] = { { "all", "When he shouts and starts {Whirlwind}, the melee step away.", "Quand il crie et lance {Tourbillon}, les mêlées s'écartent." },
      { "all", "When he dies, a wave of Scarlet Trainees runs in: AoE them.", "À sa mort, une vague de recrues écarlates arrive : tue-les en zone." } },
  },
  ScarletMonasteryCathedral = {
    ["Scarlet Commander Mograine"] = { { "all", "When he dies Whitemane comes and raises him: kill Mograine again, then her.", "À sa mort, Whitemane arrive et le ressuscite : retue Mograine, puis elle." } },
    ["High Inquisitor Whitemane"] = { { "all", "She puts the group to {Sleep} before raising Mograine: interrupt her heals.", "Elle endort le groupe avant de relever Mograine : interromps ses soins." } },
    ["High Inquisitor Fairbanks"] = { { "all", "Priest: fears and puts players to sleep, interrupt his heals.", "Prêtre : il apeure et endort, interromps ses soins." } },
  },
  RazorfenDowns = {
    ["Tuten'kash"] = { { "all", "Ring the gong: waves come, then the spider Tuten'kash.", "Sonne le gong : des vagues arrivent, puis l'araignée Tuten'kash." },
      { "heal", "Decurse and cure his poison.", "Décurse et guéris son poison." } },
    ["Mordresh Fire Eye"] = { { "all", "Interrupt his {Fireball}; {Fire Nova} hits the melee.", "Interromps sa {Boule de feu} ; sa {Nova de feu} touche les mêlées." } },
    ["Glutton"] = { { "all", "His disease cloud hits everyone near him; he enrages at low health.", "Son nuage de maladie touche ceux qui sont près de lui ; il enrage quand sa vie baisse." } },
    ["Ragglesnout"] = { { "all", "Rare, not always here. Quilboar caster: interrupt his heals.", "Rare, pas toujours là. Lanceur huran : interromps ses soins." } },
    ["Amnennar the Coldbringer"] = { { "all", "Calls Frozen Spectres during the fight: kill them; {Frost Nova} roots the melee.", "Appelle des spectres gelés pendant le combat : tue-les ; {Nova de givre} immobilise les mêlées." } },
    ["Plaguemaw the Rotting"] = { { "heal", "Rare, not always here. Cure his diseases.", "Rare, pas toujours là. Guéris ses maladies." } },
  },
  Uldaman = {
    ["Baelog"] = { { "all", "Fights with the dwarves Eric and Olaf: take them one at a time.", "Combat avec les nains Eric et Olaf : prenez-les un par un." } },
    ["Revelosh"] = { { "all", "Interrupt his {Chain Lightning}.", "Interromps sa {Chaîne d'éclairs}." } },
    ["Ironaya"] = { { "all", "Her door opens with the Staff of Prehistoria. Melee stay behind her: {Arcing Smash} and {Knock Away}.", "Sa porte s'ouvre avec le Staff of Prehistoria. Les mêlées restent derrière elle : elle frappe en arc et repousse." } },
    ["Obsidian Sentinel"] = { { "all", "Splits off small Obsidian Shards as it is hit: kill them.", "Détache de petits éclats d'obsidienne quand on le frappe : tue-les." } },
    ["Ancient Stone Keeper"] = { { "all", "Sand storms wander the room: move out of them.", "Des tempêtes de sable traversent la salle : sors-en." } },
    ["Galgann Firehammer"] = { { "all", "Fire caster: {Fire Nova} hits the melee, interrupt his spells.", "Lanceur de feu : sa {Nova de feu} touche les mêlées, interromps ses sorts." } },
    ["Grimlok"] = { { "all", "Trogg shaman: interrupt his {Lightning Bolt}.", "Chaman trogg : interromps son {Éclair}." } },
    ["Archaedas"] = { { "all", "Started at the altar. He wakes Earthen Guardians (kill them in AoE), then Vault Warders: off-tank them.", "Lancé à l'autel. Il réveille des gardiens terrestres (tue-les en zone), puis des gardiens du caveau : prends-les à part." } },
  },
  ZulFarrak = {
    ["Theka the Martyr"] = { { "all", "Turns into a scarab at low health.", "Se change en scarabée quand sa vie baisse." },
      { "heal", "{Fevered Plague}: cure the disease.", "Peste fiévreuse : guéris la maladie." } },
    ["Antu'sul"] = { { "all", "Kill his totems; at low health basilisks join the fight.", "Tue ses totems ; quand sa vie baisse, des basilics arrivent." } },
    ["Witch Doctor Zum'rah"] = { { "all", "Zombies rise from the graves: kill them away from him; kill his {Ward of Zum'rah}.", "Des zombies sortent des tombes : tue-les loin de lui ; tue sa garde de Zum'rah." } },
    ["Nekrum Gutchewer"] = { { "all", "Comes at the end of the pyramid event with Sezz'ziz.", "Arrive à la fin de l'événement de la pyramide avec Sezz'ziz." } },
    ["Shadowpriest Sezz'ziz"] = { { "all", "Interrupt his heals; {Psychic Scream} fears the group.", "Interromps ses soins ; son {Cri psychique} apeure le groupe." } },
    ["Sergeant Bly"] = { { "all", "After the stairs his group turns on you: kill Bly, keep Weegli alive.", "Après l'escalier son groupe t'attaque : tue Bly, garde Weegli en vie." } },
    ["Hydromancer Velratha"] = { { "all", "Interrupt her {Healing Wave}.", "Interromps sa {Vague de soins}." } },
    ["Gahz'rilla"] = { { "all", "Summoned with the Mallet of Zul'Farrak at the gong. She freezes a player and slams the group.", "Invoquée avec le Mallet of Zul'Farrak au gong. Elle gèle un joueur et frappe le groupe." } },
    ["Ruuzlu"] = { { "all", "Fights together with Chief Ukorz: tank both.", "Combat avec Chief Ukorz : tanke les deux." } },
    ["Chief Ukorz Sandscalp"] = { { "all", "{Cleave}: only the tank in front; he enrages at low health.", "{Enchaînement} : seul le tank devant ; il enrage quand sa vie baisse." } },
    ["Zerillis"] = { { "all", "Rare, not always here. Plain fight.", "Rare, pas toujours là. Combat simple." } },
  },
  Maraudon = {
    ["Lord Vyletongue"] = { { "all", "Comes with satyrs and blinks around: ranged keep him in sight.", "Arrive avec des satyres et se téléporte : les distances le gardent en vue." } },
    ["Noxxion"] = { { "all", "Splits into small spawns and becomes immune: kill the spawns in AoE.", "Se divise en petits rejetons et devient insensible : tue les rejetons en zone." },
      { "heal", "Cure the poison.", "Guéris le poison." } },
    ["Razorlash"] = { { "all", "{Cleave}: only the tank in front.", "{Enchaînement} : seul le tank devant." } },
    ["Meshlok the Harvester"] = { { "all", "Rare, not always here. {War Stomp} stuns the melee.", "Rare, pas toujours là. {Choc martial} étourdit les mêlées." } },
    ["Celebras the Cursed"] = { { "all", "Calls treants and roots players: kill the treants.", "Appelle des tréants et immobilise des joueurs : tue les tréants." } },
    ["Landslide"] = { { "all", "{Knock Away} and rock adds: tank him against a wall, kill the adds.", "Il repousse et appelle des éclats de roche : tanke-le dos à un mur, tue les éclats." } },
    ["Princess Theradras"] = { { "all", "Her dust field knocks back everyone near her; she throws boulders at the ranged.", "Son champ de poussière repousse ceux qui sont près d'elle ; elle lance des rochers sur les distances." } },
    ["Rotgrip"] = { { "tank", "Big crocolisk that hits hard: plain fight.", "Gros crocilisque qui frappe fort : combat simple." } },
    ["Tinkerer Gizlock"] = { { "all", "Shoots and throws bombs from range: close in on him.", "Tire et lance des bombes à distance : colle-le." } },
  },
  SunkenTemple = {
    ["Atal'alarion"] = { { "all", "Summoned by the six statues around the pit, in order: south, north, south-west, south-east, north-west, north-east.", "Invoqué par les six statues autour de la fosse, dans l'ordre : sud, nord, sud-ouest, sud-est, nord-ouest, nord-est." },
      { "tank", "Hits hard and knocks back: tank him against a wall.", "Frappe fort et repousse : tanke-le dos à un mur." } },
    ["Jammal'an the Prophet"] = { { "all", "Kill the six troll guards on the balconies first: that drops his barrier.", "Tue d'abord les six gardes trolls des balcons : cela fait tomber sa barrière." },
      { "all", "Interrupt his {Healing Wave}; his {Hex} turns a player against you.", "Interromps sa {Vague de soins} ; son {Maléfice} retourne un joueur contre vous." } },
    ["Ogom the Wretched"] = { { "heal", "Fights with Jammal'an: decurse {Curse of Weakness}.", "Combat avec Jammal'an : décurse la {Malédiction de faiblesse}." } },
    ["Dreamscythe"] = { { "tank", "Dragon: face its breath away from the group.", "Dragon : tourne son souffle loin du groupe." } },
    ["Weaver"] = { { "tank", "Dragon: face its breath away from the group.", "Dragon : tourne son souffle loin du groupe." } },
    ["Hazzas"] = { { "tank", "Dragon: face its breath away from the group.", "Dragon : tourne son souffle loin du groupe." } },
    ["Morphaz"] = { { "tank", "Dragon: face its breath away from the group.", "Dragon : tourne son souffle loin du groupe." } },
    ["Shade of Eranikus"] = { { "all", "{Deep Slumber} sleeps the group: a Shaman's Tremor Totem wakes them (it removes Sleep), an Undead breaks it with Will of the Forsaken.", "Son {Sommeil profond} endort le groupe : le Totem de séisme du chaman réveille (il retire le sommeil), un mort-vivant s'en sort avec Volonté des Réprouvés." },
      { "tank", "Turn him away from the group: his {Acid Breath} hits everyone in front of him.", "Tourne-le dos au groupe : son {Souffle acide} touche tout ce qui est devant lui." },
      { "heal", "Keep a cooldown or a potion for the sleep: the group wakes up low on health.", "Garde un temps de recharge ou une potion pour après le sommeil : le groupe se réveille bas en vie." } },
    -- the Egg of Hakkar event (Wowhead Forever quest=3528 and its Forever comments; report: "there was
    -- no guide for the egg, so we failed")
    ["Avatar of Hakkar"] = { { "all", "First dismiss every pet and totem (on Forever the Avatar won't come otherwise), then use the Egg of Hakkar in the middle of the room.", "Rangez d'abord familiers et totems (sinon l'Avatar ne vient pas sur Forever), puis utilise l'Egg of Hakkar au milieu de la salle." },
      { "all", "Kill the Hakkari Bloodkeepers for their Hakkari Blood, use it on the 4 Eternal Flames; put out the 4th once every mob is dead.", "Tue les Hakkari Bloodkeeper pour leur Hakkari Blood, verse-le sur les 4 Eternal Flame ; éteins la 4e quand tout est mort." },
      { "all", "The Avatar comes: stay in the inner circle, he mind-controls a player. Dead, use the egg on him and bring it to Yeh'kinya.", "L'Avatar arrive : restez dans le cercle intérieur, il contrôle un joueur. Mort, utilise l'œuf sur lui (pour Yeh'kinya)." } },
  },
  BlackrockDepths = {
    ["High Interrogator Gerstahn"] = { { "all", "{Psychic Scream} fears the group: fight her away from other packs.", "Son {Cri psychique} apeure le groupe : combats-la loin des autres groupes." },
      { "heal", "Dispel {Shadow Word: Pain}.", "Dissipe le {Mot de l'ombre : Douleur}." } },
    ["Lord Roccor"] = { { "all", "{Ground Tremor} stuns those close; {Flame Shock} on the tank.", "Ses secousses étourdissent ceux qui sont proches ; {Horion de flammes} sur le tank." } },
    ["Houndmaster Grebmar"] = { { "all", "Kill or control his hounds; he casts {Bloodlust} on himself.", "Tue ou neutralise ses chiens ; il lance {Furie sanguinaire} sur lui." } },
    ["Fineous Darkvire"] = { { "all", "Paladin: interrupt his heals.", "Paladin : interromps ses soins." } },
    ["Lord Incendius"] = { { "all", "Fire storms hit everyone: spread out, fire resistance helps.", "Ses tempêtes de feu touchent tout le monde : écartez-vous, la résistance au feu aide." },
      { "heal", "Decurse {Curse of the Elemental Lord}.", "Décurse la malédiction du seigneur élémentaire." } },
    ["Pyromancer Loregrain"] = { { "all", "Fire caster: kill his totem, interrupt his spells.", "Lanceur de feu : tue son totem, interromps ses sorts." } },
    ["Bael'Gar"] = { { "all", "Fire elemental: fire spells do little, use other schools.", "Élémentaire de feu : les sorts de feu font peu, utilise d'autres écoles." } },
    ["General Angerforge"] = { { "all", "At low health he calls Anvilrage reservists: save AoE and cooldowns for the end.", "Quand sa vie baisse, il appelle des réservistes : garde la zone et les temps de recharge pour la fin." } },
    ["Golem Lord Argelmach"] = { { "all", "Clear the golems in his room first, or he wakes them.", "Nettoie d'abord les golems de sa salle, sinon il les réveille." } },
    ["Phalanx"] = { { "all", "{Fireball Volley} hits the whole group; {Thunderclap} slows the melee.", "Sa salve de boules de feu touche tout le groupe ; {Coup de tonnerre} ralentit les mêlées." } },
    ["Ambassador Flamelash"] = { { "all", "Burning spirits walk to him and make him stronger: kill them before they reach him.", "Des esprits ardents marchent vers lui et le renforcent : tue-les avant qu'ils l'atteignent." } },
    ["Panzor the Invincible"] = { { "all", "Rare, not always here. Hits hard: plain fight.", "Rare, pas toujours là. Frappe fort : combat simple." } },
    ["Magmus"] = { { "all", "His door opens when the two braziers of the Lyceum are lit.", "Sa porte s'ouvre quand les deux braseros du Lycée sont allumés." } },
    ["Emperor Dagran Thaurissan"] = { { "all", "Princess Moira heals him: interrupt or crowd-control her. Alliance: keep her alive for the Ironforge quest.", "La princesse Moira le soigne : interromps-la ou neutralise-la. Alliance : garde-la en vie pour la quête d'Ironforge." } },
  },
  LowerBlackrockSpire = {
    ["Spirestone Butcher"] = { { "all", "Rare, not always here. Plain melee fight.", "Rare, pas toujours là. Combat simple." } },
    ["Spirestone Battle Lord"] = { { "all", "Rare, not always here. Plain melee fight.", "Rare, pas toujours là. Combat simple." } },
    ["Highlord Omokk"] = { { "all", "Comes with ogre guards; {Knock Away}: tank him against a wall.", "Avec des gardes ogres ; il repousse : tanke-le dos à un mur." } },
    ["Shadow Hunter Vosh'gajin"] = { { "heal", "Dispel her {Hex} and decurse.", "Dissipe son {Maléfice} et décurse." } },
    ["War Master Voone"] = { { "all", "Throws axes at range and uses {Mortal Strike} on the tank.", "Lance des haches à distance et {Frappe mortelle} sur le tank." } },
    ["Bannok Grimaxe"] = { { "all", "Rare, not always here. Plain melee fight.", "Rare, pas toujours là. Combat simple." } },
    ["Mother Smolderweb"] = { { "all", "Spiderlings come during the fight: kill them in AoE.", "Des petites araignées arrivent pendant le combat : tue-les en zone." },
      { "heal", "Cure the poison.", "Guéris le poison." } },
    ["Crystal Fang"] = { { "heal", "Rare, not always here. Spider: cure the poison.", "Rare, pas toujours là. Araignée : guéris le poison." } },
    ["Urok Doomhowl"] = { { "all", "Summoned by putting Omokk's head on the Roughshod Pike: ogre waves come first.", "Invoqué en plantant la tête d'Omokk sur la Roughshod Pike : des vagues d'ogres arrivent d'abord." } },
    ["Quartermaster Zigris"] = { { "all", "Shoots, throws stun bombs and drinks healing potions: stay on him.", "Tire, lance des bombes étourdissantes et boit des potions de soins : reste sur lui." } },
    ["Halycon"] = { { "all", "When Halycon dies, Gizrul the Slavener arrives: be ready.", "À la mort d'Halycon, Gizrul l'esclavagiste arrive : sois prêt." } },
    ["Gizrul the Slavener"] = { { "heal", "He enrages and bites hard: heal the tank hard.", "Il enrage et mord fort : soigne bien le tank." } },
    ["Overlord Wyrmthalak"] = { { "all", "At half health two adds join him: save cooldowns for them.", "À la moitié de sa vie, deux renforts arrivent : garde tes temps de recharge pour eux." } },
  },
  UpperBlackrockSpire = {
    ["Pyroguard Emberseer"] = { { "all", "Kill the Incarcerators channeling on him first; fire resistance helps.", "Tue d'abord les geôliers qui canalisent sur lui ; la résistance au feu aide." } },
    ["Solakar Flamewreath"] = { { "all", "The Rookery: waves of whelps and handlers come before Solakar, kill them in AoE; don't step on the eggs.", "La Couveuse : des vagues de dragonnets et de dresseurs arrivent avant Solakar, tue-les en zone ; ne marche pas sur les œufs." } },
    ["Jed Runewatcher"] = { { "all", "Rare, not always here. Plain melee fight.", "Rare, pas toujours là. Combat simple." } },
    ["Goraluk Anvilcrack"] = { { "all", "Hits hard: plain fight.", "Frappe fort : combat simple." } },
    ["Warchief Rend Blackhand"] = { { "all", "Arena: waves of adds, then Rend on Gyth. When Gyth dies Rend fights on foot: {Whirlwind}.", "L'arène : vagues de monstres, puis Rend sur Gyth. À la mort de Gyth, Rend combat à pied : {Tourbillon}." } },
    ["Gyth"] = { { "tank", "Breathes fire, frost and poison: face him away from the group.", "Souffle feu, givre et poison : tourne-le loin du groupe." } },
    ["The Beast"] = { { "all", "Fears the group and knocks back: tank him against a wall, fear protection helps.", "Apeure le groupe et repousse : tanke-le dos à un mur, la protection contre la peur aide." } },
    ["General Drakkisath"] = { { "all", "Two Chromatic Elite Guards with him: off-tank them. Move out of his {Flamestrike}.", "Deux gardes d'élite chromatiques avec lui : prends-les à part. Sors de son {Choc de flammes}." } },
  },
  DireMaulEast = {
    ["Pusillin"] = { { "all", "Chase him through the wing; at the end he fights with imps and drops the Crescent Key.", "Poursuis-le dans l'aile ; à la fin il combat avec des diablotins et donne la Crescent Key." } },
    ["Lethtendris"] = { { "all", "Fights with her imp Pimgib: interrupt her {Shadow Bolt Volley}.", "Combat avec son diablotin Pimgib : interromps sa salve de traits de l'ombre." } },
    ["Hydrospawn"] = { { "all", "Water elemental: geysers throw players up and it calls small water adds.", "Élémentaire d'eau : ses geysers projettent les joueurs et il appelle de petits élémentaires." } },
    ["Zevrim Thornhoof"] = { { "heal", "He sacrifices a player: heal them fast.", "Il sacrifie un joueur : soigne-le vite." } },
    ["Alzzin the Wildshaper"] = { { "all", "Changes form during the fight and calls adds: kill the adds.", "Change de forme pendant le combat et appelle des renforts : tue les renforts." } },
  },
  DireMaulNorth = {
    ["Guard Mol'dar"] = { { "all", "Tribute run: leave him alive for more loot in King Gordok's tribute.", "Run tribut : laisse-le en vie pour plus de butin au tribut du roi Gordok." } },
    ["Stomper Kreeg"] = { { "all", "Tribute run: leave him alive; after Gordok dies he sells drinks.", "Run tribut : laisse-le en vie ; après la mort de Gordok, il vend à boire." } },
    ["Guard Fengus"] = { { "all", "Tribute run: leave him alive for more loot in the tribute.", "Run tribut : laisse-le en vie pour plus de butin au tribut." } },
    ["Guard Slip'kik"] = { { "all", "Tribute run: leave him alive for more loot in the tribute.", "Run tribut : laisse-le en vie pour plus de butin au tribut." } },
    ["Captain Kromcrush"] = { { "all", "Tribute run: leave him alive; he calls ogres for help.", "Run tribut : laisse-le en vie ; il appelle des ogres à l'aide." } },
    ["Cho'Rush the Observer"] = { { "all", "Fights with King Gordok and casts like a random class: interrupt him.", "Combat avec le roi Gordok et lance les sorts d'une classe au hasard : interromps-le." } },
    ["King Gordok"] = { { "all", "{Mortal Strike} on the tank and he knocks back. When he dies, Cho'Rush crowns the group.", "{Frappe mortelle} sur le tank et il repousse. À sa mort, Cho'Rush couronne le groupe." } },
  },
  DireMaulWest = {
    ["Tendris Warpwood"] = { { "tank", "Big treant: tank him against a wall, he knocks up and tramples.", "Grand tréant : tanke-le dos à un mur, il projette et piétine." } },
    ["Magister Kalendris"] = { { "all", "Shadow priest: interrupt his {Mind Blast}, dispel {Shadow Word: Pain}.", "Prêtre de l'ombre : interromps son {Attaque mentale}, dissipe le {Mot de l'ombre : Douleur}." } },
    ["Tsu'zee"] = { { "all", "Rare, not always here. Rogue: stuns and hits fast.", "Rare, pas toujours là. Voleuse : étourdit et frappe vite." } },
    ["Illyanna Ravenoak"] = { { "all", "Hunter with her bear Ferra: kill or control the bear.", "Chasseresse avec son ours Ferra : tue ou neutralise l'ours." } },
    ["Immol'thar"] = { { "all", "Destroy the five pylons around his prison to free him; kill his eyes.", "Détruis les cinq pylônes autour de sa prison pour le libérer ; tue ses yeux." } },
    ["Prince Tortheldrin"] = { { "all", "{Whirlwind} hits the melee; his {Counterspell} silences the casters.", "{Tourbillon} touche les mêlées ; son {Contresort} réduit les lanceurs au silence." } },
  },
  Scholomance = {
    ["Kirtonos the Herald"] = { { "all", "Summoned with the Blood of Innocents at the brazier on the balcony.", "Invoqué avec le Blood of Innocents au brasero du balcon." },
      { "heal", "He disarms and curses: decurse.", "Il désarme et maudit : décurse." } },
    ["Jandice Barov"] = { { "all", "Splits into many illusions: kill them in AoE to find the real Jandice.", "Se divise en illusions : tue-les en zone pour trouver la vraie Jandice." } },
    ["Rattlegore"] = { { "all", "Hits hard and knocks back. Drops the Viewing Room Key.", "Frappe fort et repousse. Donne la Viewing Room Key." } },
    ["Marduk Blackpool"] = { { "all", "Fights in the Viewing Room among the students: kill them in AoE.", "Combat dans la salle d'observation parmi les étudiants : tue-les en zone." } },
    ["Vectus"] = { { "all", "Fire caster among the students: {Fire Nova} hits the melee.", "Lanceur de feu parmi les étudiants : sa {Nova de feu} touche les mêlées." } },
    ["Ras Frostwhisper"] = { { "all", "Frost lich: {Frost Nova} and frost bolts, frost resistance helps.", "Liche de givre : {Nova de givre} et éclairs de givre, la résistance au givre aide." } },
    ["Instructor Malicia"] = { { "all", "One of the six around the hall: kill all six to open Gandling's room.", "Un des six autour du hall : tue les six pour ouvrir la salle de Gandling." } },
    ["Doctor Theolen Krastinov"] = { { "all", "One of the six around the hall. He enrages at low health.", "Un des six autour du hall. Il enrage quand sa vie baisse." } },
    ["Lorekeeper Polkelt"] = { { "heal", "One of the six around the hall. Cure his diseases.", "Un des six autour du hall. Guéris ses maladies." } },
    ["The Ravenian"] = { { "all", "One of the six around the hall. {Cleave}: only the tank in front.", "Un des six autour du hall. {Enchaînement} : seul le tank devant." } },
    ["Lord Alexei Barov"] = { { "all", "One of the six around the hall. Shadow and fire damage: heal through it.", "Un des six autour du hall. Dégâts d'ombre et de feu : soigne pendant." } },
    ["Lady Illucia Barov"] = { { "all", "One of the six around the hall. She fears and takes control of a player: crowd-control them.", "Une des six autour du hall. Elle apeure et contrôle un joueur : neutralise-le." } },
    ["Darkmaster Gandling"] = { { "all", "He sends players into side rooms full of ghosts: they fight their way back.", "Il envoie des joueurs dans des salles pleines de fantômes : ils reviennent en combattant." } },
  },
  StratholmeLiving = {
    ["Skul"] = { { "all", "Rare, not always here. Caster: interrupt him.", "Rare, pas toujours là. Lanceur de sorts : interromps-le." } },
    ["Hearthsinger Forresten"] = { { "all", "Rare, not always here. Plain fight.", "Rare, pas toujours là. Combat simple." } },
    ["The Unforgiven"] = { { "all", "Calls ghosts when you come close: kill them in AoE.", "Appelle des fantômes quand tu approches : tue-les en zone." } },
    ["Postmaster Malown"] = { { "all", "Comes after you open the three postboxes with the Key to the City.", "Arrive quand tu ouvres les trois boîtes aux lettres avec la Key to the City." } },
    ["Timmy the Cruel"] = { { "all", "Appears once the market square is cleared.", "Apparaît une fois la place du marché nettoyée." } },
    ["Malor the Zealous"] = { { "all", "Paladin: interrupt his heals.", "Paladin : interromps ses soins." } },
    ["Cannon Master Willey"] = { { "all", "Calls riflemen during the fight: kill them.", "Appelle des fusiliers pendant le combat : tue-les." } },
    ["Archivist Galford"] = { { "all", "Fire caster: {Fire Nova} hits the melee.", "Lanceur de feu : sa {Nova de feu} touche les mêlées." } },
    ["Balnazzar"] = { { "all", "Dathrohan becomes Balnazzar mid-fight: he fears and mind-controls players, crowd-control them.", "Dathrohan devient Balnazzar en plein combat : il apeure et contrôle des joueurs, neutralise-les." } },
  },
  StratholmeUndead = {
    ["Magistrate Barthilas"] = { { "all", "Plain melee fight near the gate.", "Combat simple près de la porte." } },
    ["Nerub'enkan"] = { { "all", "Calls scarabs: kill them in AoE.", "Appelle des scarabées : tue-les en zone." },
      { "heal", "Cure the poison.", "Guéris le poison." } },
    ["Baroness Anastari"] = { { "all", "She possesses a player: crowd-control them. Decurse her curse.", "Elle possède un joueur : neutralise-le. Décurse sa malédiction." } },
    ["Stonespine"] = { { "all", "Rare, not always here. Plain fight.", "Rare, pas toujours là. Combat simple." } },
    ["Maleki the Pallid"] = { { "all", "Frost caster: interrupt his {Frostbolt}, frost resistance helps.", "Lanceur de givre : interromps son {Éclair de givre}, la résistance au givre aide." } },
    ["Ramstein the Gorger"] = { { "all", "{Knock Away} and {Trample}. When he dies, Black Guards charge in.", "Il repousse et piétine. À sa mort, des gardes noirs chargent." } },
    ["Baron Rivendare"] = { { "all", "He raises skeletons and sacrifices them to heal: kill the skeletons in AoE.", "Il relève des squelettes et les sacrifie pour se soigner : tue les squelettes en zone." } },
  },
}

-- Butin notable des boss (objets d'équipement, ids du jeu) : l'addon n'affiche que ceux que
-- l'outil d'équipement de WL Helper juge meilleurs que les tiens.
ns.BOSS_LOOT = {
  TheDeadmines = {
    ["Rhahk'Zor"] = { 872, 5187 },
    ["Gilnid"] = { 5199 },
    ["Mr. Smite"] = { 7230 },
    ["Cookie"] = { 5197, 5198 },
    ["Edwin VanCleef"] = { 5191, 5193, 10399 },
  },
}

-- =====================================================================
--  Conseils d'étape (rédigés pour l'addon, en anglais et en français)
--  clé : nom anglais du boss, ou "*start" (sur le chemin) / "*trash" (à finir dans le donjon)
-- =====================================================================
ns.STEP_TIPS = {
  ZulFarrak = {
    ["Theka the Martyr"] = {
      "Theka turns into a giant scarab when his health gets low. The Tablet of Theka (The Spider God) is the stone tablet in his room: right-click it to read the god's name.",
      "Theka se transforme en scarabée géant quand sa vie baisse. La Tablet of Theka (Le dieu-araignée) est la tablette de pierre dans sa salle : clic droit dessus pour lire le nom du dieu." },
    ["Witch Doctor Zum'rah"] = {
      "Zum'rah stands in the graveyard. Getting close makes zombies rise from the graves: kill them away from him, then kill him for his head. Mages: these zombies drop the Farraki Papyrus.",
      "Zum'rah est dans le cimetière. En approchant, des zombies sortent des tombes : tue-les loin de lui, puis tue-le pour sa tête. Mages : ces zombies donnent le Farraki Papyrus." },
    ["Sergeant Bly"] = {
      "Pyramid event: kill the Sandfury Executioner at the top for his key, open the cages, then hold the stairs against the troll waves. After that Bly's group turns on you: kill Bly for the Divino-matic Rod. Keep Weegli alive: he blows open the door to Chief Ukorz.",
      "Événement de la pyramide : tue le Sandfury Executioner en haut pour sa clé, ouvre les cages, puis tiens l'escalier contre les vagues de trolls. Ensuite le groupe de Bly t'attaque : tue Bly pour le Divino-matic Rod. Garde Weegli en vie : il fait sauter la porte de Chief Ukorz." },
    ["Hydromancer Velratha"] = {
      "The Tiara of the Deep and the Second Mosh'aru Tablet both drop from her.",
      "La Tiara of the Deep et la deuxième tablette de Mosh'aru tombent toutes les deux sur elle." },
    ["Gahz'rilla"] = {
      "One player needs the Mallet of Zul'Farrak: use it on the gong by the pool to summon Gahz'rilla. Loot the Electrified Scale from her.",
      "Un joueur doit avoir le Mallet of Zul'Farrak : utilise-le sur le gong au bord du bassin pour invoquer Gahz'rilla. Récupère l'Electrified Scale sur elle." },
    ["Ruuzlu"] = {
      "Ruuzlu stands with Chief Ukorz Sandscalp, behind the door Weegli blows open: both fight together, the last fight of the dungeon.",
      "Ruuzlu est avec Chief Ukorz Sandscalp, derrière la porte que Weegli fait sauter : les deux combattent ensemble, c'est le dernier combat du donjon." },
    ["*trash"] = {
      "Troll Temper drops from the Sandfury trolls all over the instance, the Uncracked Scarab Shells from the scarabs.",
      "Le Troll Temper tombe sur les trolls Sandfury dans toute l'instance, les Uncracked Scarab Shells sur les scarabées." },
  },
  Uldaman = {
    ["Obsidian Sentinel"] = {
      "Mages: the Obsidian Power Source drops from the Obsidian Sentinel.",
      "Mages : l'Obsidian Power Source tombe sur l'Obsidian Sentinel." },
    ["Grimlok"] = {
      "The Shattered Necklace Sapphire drops from Grimlok.",
      "Le Shattered Necklace Sapphire tombe sur Grimlok." },
    ["Archaedas"] = {
      "The Shattered Necklace Power Source drops from Archaedas, the last boss.",
      "Le Shattered Necklace Power Source tombe sur Archaedas, le dernier boss." },
  },
  Maraudon = {
    ["*start"] = {
      "Maraudon has a purple wing (Vyletongue) and an orange wing (Noxxion) outside, and the inner part beyond. The Scepter of Celebras gives a shortcut to the inner part on later runs.",
      "Maraudon a une aile violette (Vyletongue) et une aile orange (Noxxion) à l'extérieur, puis la partie intérieure. Le sceptre de Celebras sert de raccourci vers l'intérieur pour les runs suivants." },
    ["Lord Vyletongue"] = {
      "Purple wing. The Celebrian Diamond drops from Vyletongue.",
      "Aile violette. Le Celebrian Diamond tombe sur Vyletongue." },
    ["Noxxion"] = {
      "Orange wing. The Celebrian Rod drops from Noxxion.",
      "Aile orange. Le Celebrian Rod tombe sur Noxxion." },
    ["Celebras the Cursed"] = {
      "Once Celebras the Cursed is dead, his spirit Celebras the Redeemed appears: hand him the Rod and the Diamond, then listen to his incantation for The Scepter of Celebras.",
      "Une fois Celebras the Cursed mort, son esprit Celebras the Redeemed apparaît : donne-lui le Rod et le Diamond, puis écoute son incantation pour Le sceptre de Celebras." },
    ["Princess Theradras"] = {
      "After Theradras dies, Zaetar's spirit appears and gives Seed of Life, for Keeper Remulos in Moonglade.",
      "Après la mort de Theradras, l'esprit de Zaetar apparaît et donne Seed of Life, à rendre au gardien Remulos à Reflet-de-Lune." },
    ["*trash"] = {
      "Theradric Crystal Carvings drop from the creatures all through Maraudon; Shadowshard Fragments from the Shadowshard elementals.",
      "Les Theradric Crystal Carvings tombent sur les créatures de tout Maraudon ; les Shadowshard Fragments sur les élémentaires Shadowshard." },
  },
}
for _, t in pairs(ns.STEP_TIPS) do for _, v in pairs(t) do ns.TR[v[1]] = v[2] end end

-- Quêtes au choix (Lord Valthalak) : quatre versions par étape, une seule se fait (LibForeverData : prérequis « any »).
-- Une version faite (ou dans le journal) vaut pour les quatre, pour que les chaînes en ligne droite restent justes.
ns.ANYOF = { { 8962, 8963, 8964, 8965 }, { 8966, 8967, 8968, 8969 }, { 8985, 8986, 8987, 8988 }, { 8989, 8990, 8991, 8992 } }
do
  local grp = {}
  for _, g in ipairs(ns.ANYOF) do for _, id in ipairs(g) do grp[id] = g end end
  local isDone3 = ns.IsDone
  ns.IsDone = function(id)
    if isDone3(id) then return true end
    local g = grp[id]
    if g then for _, o in ipairs(g) do if o ~= id and isDone3(o) then return true end end end
    return false
  end
  local log3 = ns.LogEntries
  ns.LogEntries = function()
    local list = log3()
    for id, g in pairs(grp) do
      if not list[id] then for _, o in ipairs(g) do if list[o] then list[id] = list[o]; break end end end
    end
    return list
  end
end

-- ZONES BEGIN (generated by zones/gen_areas.py from LibForeverData + QuestieDB spawns: do not edit by hand)
-- [quest] = { [objective] = { m = map, pts = hull (one camp) or { hull, hull, ... } (several camps),
--   sp = { { x, y, camp }, ... } spawns spread over each camp, for the GPS } }; set on o.area when the
-- objective's point is on that map (Engine.lua: ns.AreaOf, ns.AreaPick).
local ZONES = {
  [447]={[1]={m=1421,pts={{{44.5,24.6},{49,14.2},{51,14.9},{52.1,19.6},{51.9,21.6},{48.8,26.3},{46,26}},{{46.9,33.5},{47.3,33},{48.8,32.9},{54.3,38.2},{55.2,44.1},{51.3,45.4},{50.8,44.9},{50.2,43.4}},{{44.1,52},{44.2,48.1},{44.9,47.3},{47,46.5},{46.3,49.6},{45,51.9}}},sp={{50,19.9,1},{46,26,1},{49,14.2,1},{48,23.3,1},{51.3,16.6,1},{48.8,26.3,1},{51.3,38.8,2},{47.3,33,2},{55.2,44.1,2},{50.2,43.4,2},{54.3,38.2,2},{44.6,50.4,3},{47,46.5,3}}}},
  [865]={[1]={m=1413,pts={{{43.9,43.4},{44.5,43},{47.8,43.2},{56.7,47.4},{60.9,49.9},{58,53.9},{57,54.5},{50.7,51.8},{49.5,51.2},{48.1,50.3}},{{42.5,15.7},{44.1,14.4},{48.2,11.3},{47.7,12.9},{46.4,15},{46.1,15.3},{44.1,16.6}},{{55.7,5.8},{56.6,4.3},{59.3,6.2},{59.9,7.5},{60.4,8.8},{60.8,12.7}},{{60.2,32.2},{60.3,30.5},{61.3,31},{61.2,34},{60.8,33.4}},{{36.2,28.8},{36.7,26.4},{39.3,25.6},{37.6,27.5}}},sp={{51.9,48,1},{43.9,43.4,1},{60.9,49.9,1},{57,54.5,1},{56.7,47.4,1},{47.8,45.8,1},{48.1,50.3,1},{55.6,50.8,1},{50.7,51.8,1},{58.3,50,1},{45.5,14.7,2},{48.2,11.3,2},{42.5,15.7,2},{44.1,16.6,2},{59.2,7.4,3},{60.8,12.7,3},{56.6,4.3,3},{60.4,8.8,3},{61,32,4},{61.2,34,4},{37.2,26.8,5},{39.3,25.6,5}}}},
  [880]={[1]={m=1413,pts={{{45.7,39},{46.2,38.3},{47.6,39.5},{48,40},{48.1,40.6},{46.5,40.5},{45.9,40.4}},{{55,42.2},{55.6,41.5},{56,42},{56.1,42.4},{56,42.8},{55.6,43.6},{55.1,43}}},sp={{46.8,39.5,1},{48.1,40.6,1},{45.9,40.4,1},{46.2,38.3,1},{55.6,42.4,2},{55.6,43.6,2},{55.6,41.5,2}}}},
  [964]={[1]={m=1422,pts={{{35.6,56.5},{36.6,54.3},{37.5,54.1},{38.5,54},{39.3,54.9},{38.5,57.5},{37.6,59.5}},{{53.9,80.9},{54.1,79.4},{54.8,79.8},{54.8,80.9}}},sp={{37.4,56.3,1},{37.6,59.5,1},{38.5,54,1},{36.6,54.3,1},{35.6,56.5,1},{54.7,80.2,2},{53.9,80.9,2}}}},
  [1193]={[2]={m=1449,pts={{{47.2,31.9},{49.1,29.3},{49.1,33.9},{47.6,36.1}},{{58.9,29.3},{61.6,30.6},{60,32.9}}},sp={{48.6,33.1,1},{49.1,29.3,1},{59.9,30.3,2}}}},
  [1424]={[1]={m=1435,near=40,pts={{61.5,57.9},{62.4,52.9},{65.4,43.4},{69.8,40.9},{73.9,42.3},{75.8,44.7},{78.2,48.5},{76.2,63.5},{73.7,64.8},{70.6,66}},sp={{72.5,53.1,1},{70.6,66,1},{69.8,40.9,1},{61.5,57.9,1},{64.4,49.5,1},{75.4,60.4,1},{78.2,48.5,1},{67.9,57.9,1},{71.1,46.6,1},{65.4,43.4,1}}}},
  [1445]={[1]={m=1435,pts={{{73.1,47.4},{75.5,47.6},{76.6,51}},{{78.1,44},{80.9,45.4},{79.3,44.7}}},sp={{74.4,48.4,1},{79.3,44.7,2}}}},
  [1954]={[1]={m=1443,pts={{{79.5,81.3},{80.3,77},{80.7,76.3},{82.1,80.7}},{{51.5,81.9},{53.5,78.4},{53.1,80.2}}},sp={{80.5,77.8,1},{79.5,81.3,1},{53.1,80.2,2}}}},
  [2258]={[2]={m=1418,pts={{{46.7,44.1},{46.9,36},{48.5,34.5},{50.2,35.2},{58.1,46.5},{55,50},{53.2,52},{48.4,49.8},{46.9,48.3}},{{52.3,20.6},{52.9,14.6},{53.8,17.5},{54.9,24.8},{52.4,24.7}}},sp={{49.9,41.9,1},{53.2,52,1},{48.5,34.5,1},{58.1,46.5,1},{46.9,48.3,1},{53.7,48,1},{51,38.1,1},{52.3,20.6,2},{52.9,14.6,2}}}},
  [2500]={[2]={m=1418,pts={{{46.7,44.1},{46.9,36},{48.5,34.5},{50.2,35.2},{58.1,46.5},{55,50},{53.2,52},{48.4,49.8},{46.9,48.3}},{{52.3,20.6},{52.9,14.6},{53.8,17.5},{54.9,24.8},{52.4,24.7}}},sp={{49.9,41.9,1},{53.2,52,1},{48.5,34.5,1},{58.1,46.5,1},{46.9,48.3,1},{53.7,48,1},{51,38.1,1},{52.3,20.6,2},{52.9,14.6,2}}}},
  [2283]={[1]={m=1418,pts={{43.9,10.7},{44.4,9.4},{45.6,8.6},{48.2,7.2},{49.2,7.2},{49.6,7.8},{53.8,16.8},{46.2,13.8},{44.4,12.4}},sp={{48.2,11,1},{53.8,16.8,1},{43.9,10.7,1},{49.2,7.2,1},{50.6,14.8,1},{46.2,13.8,1},{46.4,8.2,1},{50.6,10.6,1},{48.6,13.6,1},{46,10.6,1}}}},
  [2418]={[1]={m=1418,pts={{43.9,10.7},{44.4,9.4},{45.6,8.6},{48.2,7.2},{49.2,7.2},{49.6,7.8},{53.8,16.8},{46.2,13.8},{44.4,12.4}},sp={{48.2,11,1},{53.8,16.8,1},{43.9,10.7,1},{49.2,7.2,1},{50.6,14.8,1},{46.2,13.8,1},{46.4,8.2,1},{50.6,10.6,1},{48.6,13.6,1},{46,10.6,1}}},[2]={m=1418,pts={{43.9,10.7},{44.4,9.4},{45.6,8.6},{48.2,7.2},{49.2,7.2},{49.6,7.8},{53.8,16.8},{46.2,13.8},{44.4,12.4}},sp={{48.2,11,1},{53.8,16.8,1},{43.9,10.7,1},{49.2,7.2,1},{50.6,14.8,1},{46.2,13.8,1},{46.4,8.2,1},{50.6,10.6,1},{48.6,13.6,1},{46,10.6,1}}}},
  [3520]={[1]={m=1444,pts={{{45.9,49.2},{46.5,47.6},{53.2,46.8},{55.7,47},{60.8,49.8},{59,51.1},{46.1,50}},{{42,36.3},{44.9,36.1},{46,37.7},{46.5,39.4},{46.5,40.7}},{{57.1,54.8},{60.2,62.1},{57.6,59.4}}},sp={{52.3,49.2,1},{60.8,49.8,1},{45.9,49.2,1},{56.9,48.1,1},{46,37.7,2},{42,36.3,2},{58.2,57.8,3}}}},
  [4145]={[2]={m=1449,pts={{{26.3,46.7},{28.6,33.2},{32.5,28.4},{39.3,30.3},{41.2,32.5},{41.9,42.8},{41.5,43.3}},{{32.8,21.5},{39.4,21.6},{40.3,23.3},{41.1,25},{39,24.6},{33.8,22.5}},{{30.8,65.9},{34.7,62.8},{36.5,68.2},{37,69.8},{32.2,72.5}},{{30.8,77.1},{37.2,75.3},{40.7,78.8},{38.2,81.7}},{{39.2,51.9},{42.3,55.9},{39.2,54.9}}},sp={{35.5,38.3,1},{26.3,46.7,1},{32.5,28.4,1},{41.2,32.5,1},{41.9,42.8,1},{28.9,39,1},{28.6,33.2,1},{36.4,23.5,2},{41.1,25,2},{33.6,69.3,3},{34.7,62.8,3},{35.5,78.9,4},{40.7,78.8,4},{40.8,54.2,5}}},[4]={m=1449,pts={{{56.4,37.3},{56.6,36},{61.1,27.6},{69.2,20.5},{70.7,27.7},{70.8,31.7},{66.9,38.9},{60.5,40.4}},{{71,39.3},{72.7,37.7},{76,45.1},{76.1,48},{74.2,50.8}},{{70.6,65.8},{71.6,64}}},sp={{63.7,33.4,1},{69.2,20.5,1},{56.4,37.3,1},{70.7,27.7,1},{61.1,27.6,1},{66.9,38.9,1},{60.5,40.4,1},{74.6,43.7,2},{74.2,50.8,2},{72.7,37.7,2},{70.6,65.8,3}}}},
  [4201]={[1]={m=1419,pts={{53.9,53.9},{55.2,50.5},{56.9,50.1},{58.8,50.2},{59.6,50.4},{61.4,52},{62.9,54.7},{62.9,55.8},{62.6,57.5}},sp={{59.6,54.6,1},{55.2,50.5,1},{59.6,50.4,1},{62.6,57.5,1}}},[2]={m=1447,pts={{{46.3,83.4},{48.5,75.7},{56.7,79.8},{60.3,81.7},{59.3,83.4},{55.3,85.1},{47.7,85.7}},{{73,16.6},{73.9,14.4},{80,14.4},{78.2,17.1},{77.2,18.6},{75.8,20.3},{74.4,18.6}}},sp={{52.4,81.7,1},{60.3,81.7,1},{48.5,75.7,1},{46.3,83.4,1},{75.7,16.2,2},{80,14.4,2},{75.8,20.3,2}}}},
  [4726]={[1]={m=1428,pts={{{84.9,31.9},{86.9,30.6},{88.3,29.8},{91.6,33.4},{91.9,38.5}},{{89.5,43.9},{90.5,45.2},{90.6,47.4},{90.5,50.9}},{{22.5,68.9},{24.3,67.4},{23.4,70.6}},{{57.6,31.6},{61.1,31.2},{59.2,32.3}},{{78.4,27.5},{81.4,26.5},{81,28.2}}},sp={{87.8,33.5,1},{91.9,38.5,1},{90.6,47.4,2},{22.5,68.9,3},{59.2,32.3,4},{81,28.2,5}}}},
  [5461]={[1]={m=1417,pts={{{17.9,69.4},{18.5,66.2},{19.4,64.5},{20.8,65.8}},{{27.6,66},{29.3,62.8},{29.3,64.9}}},sp={{18.5,66.2,1},{29.3,64.9,2}}}},
  [5518]={[1]={m=1444,pts={{{34.5,34},{38.2,35},{36.4,36.5}},{{45.5,62.3},{45.9,57.9},{46.5,59.6}},{{42.5,46.9},{44.1,50.1}}},sp={{36.5,35.8,1},{46.5,59.6,2},{42.5,46.9,3}}}},
  [5726]={[1]={m=1454,pts={{72.1,80.3},{76.9,78.4},{78.7,78.9},{80.4,85.2},{77.7,91.4},{74.7,91.3},{72.1,89.6}},sp={{77.6,85.2,1},{72.1,80.3,1},{72.1,89.6,1},{78.7,78.9,1}}}},
  [6042]={[1]={m=1423,pts={{{38.7,57.1},{39.2,54.6},{39.5,53.8},{42.3,49},{45.8,50.5},{45.9,53.2},{42.5,57.1}},{{56.6,54.7},{58.3,50.2},{65,50},{67.2,50.4},{59.5,55.9}},{{50.3,49.3},{50.9,48},{52.5,45.6},{56,49.1},{54.6,52.9}},{{46.3,41.5},{48.2,42.1},{50.2,44.1},{49.1,45.8},{46.5,42.9}},{{60.1,47.3},{62,45.6},{64.2,46.1},{60.9,47.6}}},sp={{42.3,52.3,1},{38.7,57.1,1},{45.8,50.5,1},{42.5,57.1,1},{42.3,49,1},{39.5,53.8,1},{61.4,52.6,2},{67.2,50.4,2},{56.6,54.7,2},{58.3,50.2,2},{52.5,49.8,3},{52.5,45.6,3},{54.6,52.9,3},{48.1,44.1,4},{46.3,41.5,4},{61.2,47,5},{64.2,46.1,5}}},[2]={m=1423,pts={{{37.5,34.9},{39.9,29.1},{41.8,28.2},{43.9,29.1},{48.6,34.7},{44.9,36.2}},{{52.4,24.5},{52.5,23.1},{55.4,19.7},{58.4,22.9},{59.3,26.5},{54.4,30.6},{52.9,27}},{{41.1,21.6},{42.9,18.8},{48.1,14.9},{50.3,15},{44.4,21.1}},{{25,33.9},{26.5,30.1},{28.5,31.7},{28.4,33.7},{27.8,35},{27.1,35.2}},{{15.6,29},{16.2,28.5},{18.4,29.6},{16.9,30.4}},{{15.3,18.8},{15.5,17},{17,14.3},{15.9,21.5}}},sp={{44.8,31,1},{37.5,34.9,1},{48.6,34.7,1},{54.4,22.8,2},{54.4,30.6,2},{59.3,26.5,2},{44.7,18.6,3},{50.3,15,3},{41.1,21.6,3},{28.4,33.7,4},{26.5,30.1,4},{17.9,29.7,5},{15.6,29,5},{15.5,17,6},{15.9,21.5,6}}}},
  [6626]={[1]={m=1441,pts={{35.8,16.9},{36.5,11.4},{40.4,14.1},{41.8,15.3},{42.3,16.9},{43.1,30},{40.6,29}},sp={{38.6,21.1,1},{36.5,11.4,1},{43.1,30,1},{41.8,15.3,1},{42.5,24.9,1},{35.8,16.9,1},{41.8,19.1,1},{39,16.9,1},{41.1,27.6,1}}}},
  [6805]={[1]={m=1451,pts={{{17,25.8},{18.4,20.4},{19.4,18.4},{20.4,17.4},{21.6,20.4},{22.6,23.4},{23.6,27.6},{21.6,30.6},{20.6,31.8},{19.4,32.6},{18.2,32.4},{17,28}},{{27.8,18.4},{28.4,15},{29.4,13.4},{33.4,12.4},{34.8,12.4},{35.6,13},{33.6,16.8},{29.6,22.6},{28.4,22.8}}},sp={{20.4,24.8,1},{18.2,32.4,1},{20.4,17.4,1},{17,28,1},{21.6,29.6,1},{18.4,21,1},{21.6,20.4,1},{17.4,24.4,1},{23.4,27.2,1},{22.6,23.4,1},{31,15.8,2},{28.4,22.8,2},{35.6,13,2},{27.8,18.4,2},{30.6,19.6,2},{29.4,13.4,2},{33.6,16.8,2},{32.2,13.4,2},{28.4,16.4,2},{31.8,17.8,2}}}},
  [7563]={[1]={m=1452,pts={{{37,35.6},{41.5,34.1},{49.4,35.1},{46.8,37.5},{44.8,38.3},{37.8,40.6}},{{49.7,39.9},{52.5,38.1},{54,37.2},{54.9,37.7},{51.5,39.3}},{{44.5,42.8},{47.4,42.8},{45.5,42.9}},{{28.6,48.3},{29,45}}},sp={{42.6,36.8,1},{49.4,35.1,1},{37.8,40.6,1},{37,35.6,1},{46.8,37.5,1},{52.5,38.1,2},{49.7,39.9,2},{45.5,42.9,3},{29,45,4}}}},
  [7627]={[2]={m=1428,pts={{{76,45},{76.4,43.6},{77.8,41.8},{78.4,41.3},{83.5,37.6},{84.8,48.8},{80.9,48.5},{76.3,47.4}},{{37.5,42.5},{37.7,41.2},{39.1,38.3},{44.5,33.8},{47.3,33.5},{50.3,42.9},{49,43.7},{40.3,45.2}},{{21.8,69.9},{22,63},{22.5,62.5},{28,64.5},{28.3,64.7},{25.8,71.1},{23,73.2}},{{53.7,60.5},{62.1,54.8},{65,57.9},{62.1,62.1}},{{42.2,62.1},{42.8,60.1},{43.6,59.6},{47.2,59.5},{48.5,62.3},{48.7,63.9},{42.3,63.5}},{{34.6,67.8},{34.8,66.7},{36.4,63.7},{37,62.6},{37.5,64.2},{35.3,69.6}}},sp={{80.2,43.5,1},{84.8,48.8,1},{83.5,37.6,1},{76.3,47.4,1},{83.6,41.6,1},{80.9,48.5,1},{76.4,43.6,1},{83.5,46,1},{80.3,40.7,1},{77.8,41.8,1},{44.3,40.6,2},{47.3,33.5,2},{37.5,42.5,2},{50.3,42.9,2},{41.8,44.8,2},{39.1,38.3,2},{47.3,37.7,2},{45.6,43.9,2},{23.4,67,3},{23,73.2,3},{28.3,64.7,3},{60.4,59,4},{43.6,59.6,5},{34.8,66.7,6}}}},
  [8153]={[1]={m=1447,pts={{{43.9,78.8},{46.7,74.9},{48,74.7},{58.5,76.8},{60,80.4},{60,82.6},{57.3,88.6},{47.6,85.8},{44.9,81.6}},{{47.5,26.4},{49,24.9},{52.8,24.4},{53.2,30.4},{52.1,35.4}},{{35.1,65.9},{36.1,65.8},{40.4,69.1},{43.1,71.6},{40.9,73.6},{37.7,71.2},{35.5,68.6}},{{55.2,16.9},{56.7,16.6},{58.5,17.3},{58.5,19.4},{57.6,21.4},{56.6,21.5},{55.2,19}},{{73,22.2},{75.7,22.6},{83,24.1},{81,27.2},{76.3,28.4}},{{61.2,15.7},{61.3,13.7},{63.3,16.3},{63.9,17.5},{61.8,20.6}}},sp={{51.8,80.5,1},{57.3,88.6,1},{60,80.4,1},{43.9,78.8,1},{47.6,85.8,1},{48,74.7,1},{54.6,84.6,1},{57.2,76.7,1},{58.6,84.3,1},{52,76.6,1},{51,27.8,2},{52.1,35.4,2},{52.8,24.4,2},{47.5,26.4,2},{51,31.5,2},{53.2,30.4,2},{38.2,69,3},{43.1,71.6,3},{35.1,65.9,3},{39.6,72,3},{35.5,68.6,3},{56.5,18.4,4},{78.3,25.3,5},{62.6,17.5,6}}}},
  [8234]={[1]={m=1447,pts={{40.2,19.7},{41.8,18.9},{42.8,18.4},{46.2,21.4},{48.4,31.1},{48,32.4},{43.6,27.5}},sp={{44.1,25.4,1},{48,32.4,1},{42.8,18.4,1},{46.2,21.4,1},{41.4,21.8,1},{40.2,19.7,1},{44.1,20.5,1},{47.6,30.3,1},{44.9,27.4,1},{45.6,23.3,1}}}},
  [8235]={[1]={m=1447,pts={{{35.8,44.2},{41.7,27.6},{47.7,34.8},{40.9,41.9}},{{30.8,80.9},{33.9,79.6},{36.8,84.6},{34.8,84.3}},{{16.6,79.8},{20.7,78.7},{19.1,79.4}}},sp={{43.1,36.6,1},{35.8,44.2,1},{41.7,27.6,1},{40.9,41.9,1},{34.2,82.7,2},{30.8,80.9,2},{19.1,79.4,3}}}},
  [8252]={[1]={m=1447,pts={{{43.2,45.2},{43.5,42},{46.4,39.8},{49.2,46},{49.6,53.8},{50.1,65},{48.8,66.7},{46.5,65.7},{45.2,62},{43.6,56.9}},{{34.4,55},{34.5,53},{36.3,48},{39,46.2},{39.9,47.2},{41.4,51.7},{41.1,55.8},{39.6,57},{38.1,57.2},{35,56.2}},{{38.2,60.9},{39,59.8},{40.2,61.8},{39.3,62.7}},{{41.6,63.9},{42.6,63.6},{43.6,64.7}}},sp={{47.5,52.9,1},{48.8,66.7,1},{46.4,39.8,1},{43.4,46.9,1},{46.7,60,1},{49.2,46,1},{43.6,56.9,1},{43.5,42,1},{49.4,56,1},{44.1,51.8,1},{38.1,53,2},{39,46.2,2},{35,56.2,2},{39.6,57,2},{36.1,50.1,2},{41.4,51.7,2},{34.5,53,2},{39,50.1,2},{41.1,54.2,2},{36.9,55.4,2},{38.2,60.9,3},{42.6,63.6,4}}}},
  [8255]={[1]={m=1447,pts={{{43.9,78.8},{46.7,74.9},{48,74.7},{58.5,76.8},{60,80.4},{60,82.6},{57.3,88.6},{47.6,85.8},{44.9,81.6}},{{47.5,26.4},{49,24.9},{52.8,24.4},{53.2,30.4},{52.1,35.4}},{{35.1,65.9},{36.1,65.8},{40.4,69.1},{43.1,71.6},{40.9,73.6},{37.7,71.2},{35.5,68.6}},{{55.2,16.9},{56.7,16.6},{58.5,17.3},{58.5,19.4},{57.6,21.4},{56.6,21.5},{55.2,19}},{{73,22.2},{75.7,22.6},{83,24.1},{81,27.2},{76.3,28.4}},{{61.2,15.7},{61.3,13.7},{63.3,16.3},{63.9,17.5},{61.8,20.6}}},sp={{51.8,80.5,1},{57.3,88.6,1},{60,80.4,1},{43.9,78.8,1},{47.6,85.8,1},{48,74.7,1},{54.6,84.6,1},{57.2,76.7,1},{58.6,84.3,1},{52,76.6,1},{51,27.8,2},{52.1,35.4,2},{52.8,24.4,2},{47.5,26.4,2},{51,31.5,2},{53.2,30.4,2},{38.2,69,3},{43.1,71.6,3},{35.1,65.9,3},{39.6,72,3},{35.5,68.6,3},{56.5,18.4,4},{78.3,25.3,5},{62.6,17.5,6}}}},
  [8412]={[1]={m=1422,pts={{{43.1,46.8},{43.5,40.2},{45,37.6},{51.2,30.9},{52,34.2},{51.8,47},{44.9,49.5}},{{42.5,54.1},{51.5,60.5},{52,61},{51.1,64.3},{45,59.8},{42.6,56.3}},{{46.6,29.7},{47.3,28.3},{48.8,26.1},{49.6,27.2},{48.9,28.3}}},sp={{47.4,41.3,1},{51.2,30.9,1},{44.9,49.5,1},{51.8,47,1},{50.4,36.4,1},{45.9,36.7,1},{44.8,44.8,1},{43.5,40.2,1},{48,47.3,1},{52,34.2,1},{46.4,59.9,2},{42.5,54.1,2},{51.1,64.3,2},{51.5,60.5,2},{48.9,61.9,2},{48.1,27.2,3},{46.6,29.7,3}}},[2]={m=1422,pts={{{52.7,51.7},{52.9,49.5},{53.4,48.3},{55,45.8},{65.9,44},{68,45.5},{68.1,48.5},{66.8,49.9},{60.5,54.1},{55.6,54}},{{52.5,58.4},{56.6,57.5},{57.7,58.4},{59.1,59.6},{59,61},{58.2,62.1},{55.2,64.5},{53.4,62}},{{65,53},{66.7,53.4},{67.4,55.3},{66,57.4}}},sp={{60.5,49.4,1},{68,45.5,1},{52.7,51.7,1},{55,45.8,1},{65.3,50.3,1},{57.1,53.5,1},{63.5,45.2,1},{55.8,49.6,1},{60.8,53.5,1},{68.1,48.5,1},{55.9,61,2},{52.5,58.4,2},{55.2,64.5,2},{56.6,57.5,2},{59.1,59.6,2},{53.4,62,2},{66.4,54.5,3},{66,57.4,3},{65,53,3}}}},
  [8421]={[2]={m=1448,pts={{34.2,48.5},{40.9,45.7},{41.4,45.5},{44,46.4},{43.9,48.6},{40.7,59.7}},sp={{41.4,50.2,1},{40.7,59.7,1},{34.2,48.5,1},{39.7,54.9,1},{41.4,45.5,1},{38.5,49.2,1},{43.9,48.6,1},{44,46.4,1},{41.2,47.4,1},{42.8,51.1,1}}}},
  [8423]={[1]={m=1419,pts={{{44.4,32.4},{54,35},{54.6,36.8},{55.6,43.2},{54.8,44.8},{45.4,41.2},{44.4,37.2}},{{50.2,53.6},{50.6,53.4},{52.8,52.4},{52.6,56.6},{51.2,57.6}},{{45.4,49.2},{45.8,48.2},{46.6,47.4},{48,50.2},{45.4,52.6}}},sp={{49,38.2,1},{54.8,44.8,1},{44.4,32.4,1},{54,35,1},{44.4,37.2,1},{53.4,39.6,1},{45.4,41.2,1},{48,34.4,1},{50.8,35.2,1},{53.4,42.6,1},{51.6,55,2},{52.8,52.4,2},{51.2,57.6,2},{50.2,53.6,2},{46.2,50.2,3},{46.6,47.4,3},{45.4,52.6,3},{48,50.2,3}}}},
  [8424]={[1]={m=1419,pts={{{61.8,41.1},{62.9,40.7},{64.6,46.9},{64.6,47.6},{64,48.1}},{{63.7,31.8},{67.1,29.3},{69.5,31},{64.1,35.2}}},sp={{64.1,45.7,1},{61.8,41.1,1},{64,48.1,1},{66.7,31.7,2},{64.1,35.2,2},{63.7,31.8,2}}},[2]={m=1419,pts={{{64.3,33.8},{64.8,32.5},{66,30.1},{67.3,29.9},{68.2,31.1},{66,34.5},{64.8,34.8}},{{61.8,42.1},{62.1,39.9},{63.9,40.9},{64.1,46.8},{63.2,47.1}}},sp={{66,31.7,1},{64.8,34.8,1},{68.2,31.1,1},{65,33,1},{63.2,44.5,2},{62.1,39.9,2}}},[3]={m=1419,pts={{{63.8,30.1},{67,29.5},{69.3,31.1},{65.1,34},{64.7,32.9}},{{62.6,40.8},{63.2,39.2},{63.9,39.4},{64.3,46.6},{62.9,48.5}}},sp={{66.6,31.6,1},{63.8,30.1,1},{65.1,34,1},{69.3,31.1,1},{63.9,44.1,2},{63.2,39.2,2},{62.9,48.5,2}}}},
  [9052]={[2]={m=1449,pts={{{48,14.2},{53.4,14.9},{63.5,18.1},{64.7,20.5},{48.3,17.9}},{{33.8,23.3},{38.3,19.3},{38.3,23.1},{37.9,27.8}},{{72.9,47.2},{73.9,44.3},{74.1,49.8}},{{33.5,42.7},{33.7,39.1},{33.6,45.2}}},sp={{56.2,16.7,1},{64.7,20.5,1},{48,14.2,1},{38.3,23.1,2},{37.9,27.8,2},{72.9,47.2,3},{33.5,42.7,4}}}},
  [82084]={[1]={m=1425,pts={{{25.3,53.2},{37.2,44.2},{36.1,55.3},{33.9,63.2},{31.1,63}},{{25.6,62.9},{26.8,59.6},{27.9,65.9},{26.4,68.7},{25.9,68.4}}},sp={{31,52.8,1},{33.9,63.2,1},{37.2,44.2,1},{25.3,53.2,1},{36.1,55.3,1},{35.8,50.8,1},{26.2,63.9,2},{26.4,68.7,2},{26.8,59.6,2}}}},
  [94483]={[1]={m=2548,pts={{42.9,65.6},{44.2,61.6},{44.9,60.5},{46,59.6},{46.7,59.7},{51.9,66.8},{52.8,69.2},{52.9,70.5},{52.2,75.1},{51.2,75.6},{44.2,69.2},{43.5,68}},sp={{48.1,67.6,1},{51.2,75.6,1},{46,59.6,1},{43,64.9,1},{52.9,70.5,1},{44.2,69.2,1},{48.9,71.8,1},{51.9,66.8,1},{46.2,64.5,1},{44.2,61.6,1}}},[2]={m=2548,pts={{{41.1,68.1},{42.7,57.2},{47.1,57.9},{55,67.8},{53.2,73.5},{52.2,75.1},{50.7,77},{45.9,75.7}},{{65.4,81.5},{65.5,80},{65.8,78.7},{66.5,78.8},{67,79.5},{67,80.2}}},sp={{48.4,67.9,1},{42.7,57.2,1},{50.7,77,1},{41.1,68.1,1},{55,67.8,1},{44.4,63.2,1},{45.9,74.7,1},{51.4,71.7,1},{47.1,57.9,1},{46.5,71,1},{65.9,79.6,2},{65.4,81.5,2},{67,80.2,2}}}},
  [94672]={[1]={m=2548,pts={{33.6,43.4},{34.2,43.1},{51.6,39.2},{55.6,41},{58.7,51.4},{54,60.6},{50.5,60.6},{48.1,59.4},{45.2,57.6}},sp={{49.5,50.1,1},{33.6,43.4,1},{54,60.6,1},{51.6,39.2,1},{58.7,51.4,1},{42.5,45,1},{45.2,57.6,1},{55.1,45.9,1},{42.6,51.5,1},{54,54.8,1}}},[2]={m=2548,pts={{40.3,48.7},{43.2,45.2},{50.7,41.6},{51.7,42},{52.5,42.4},{53.6,47.6},{52.4,49.2},{50.5,51.7},{49.7,52.7},{46.7,55.8},{42.8,57.4}},sp={{48.1,48.2,1},{42.8,57.4,1},{40.3,48.7,1},{52.5,42.4,1},{47.3,53.9,1},{53.6,47.6,1},{43.2,45.2,1},{47.6,43.8,1},{44.3,50.7,1},{50.5,51.7,1}}},[3]={m=2548,pts={{37.2,45},{53.7,40.5},{57.2,41.2},{54.2,58.9},{42.5,57.7}},sp={{48.3,49.4,1},{57.2,41.2,1},{37.2,45,1},{54.2,58.9,1},{42.5,57.7,1},{50.5,42.7,1},{42,49.8,1},{49,55.5,1},{44.3,44.6,1},{53.4,49.1,1}}}},
  [95140]={[1]={m=1421,pts={{{43.9,84.1},{45.4,78.6},{47.9,72.1},{50,71.7},{52.6,72.5},{52.4,86.5},{52.3,87.1},{50.6,88.9},{49.5,89.5},{48.5,88.8}},{{44.2,41.1},{44.5,40.3},{44.8,41.9}}},sp={{49.6,83.8,1},{50,71.7,1},{45.4,78.6,1},{49.5,89.5,1},{43.9,84.1,1},{50.8,78.1,1},{52.4,86.5,1},{52.5,74.3,1},{48.9,75.2,1},{48.7,86.5,1},{44.2,41.1,2}}}},
  [95773]={[1]={m=1434,pts={{{13.5,14.4},{15.2,13.3},{16.5,13.9},{28.5,21.6},{30.2,28.3},{25.5,34.3},{21.9,33},{19.5,29.7}},{{13.1,17.3},{14.7,17.7},{15.8,20.1}}},sp={{23.1,25.4,1},{13.5,14.4,1},{25.5,34.3,1},{30.2,28.3,1},{20.1,17.9,1},{28.5,21.6,1},{19.5,29.7,1},{18.9,23.5,1},{25.3,29.4,1},{23.6,20.6,1},{15.1,18.7,2}}}},
}
for qid, list in pairs(ZONES) do
  local q = ns.Q[qid]
  for i, a in pairs(list) do
    local o = q and q.o and q.o[i]
    if o and o.w and o.w.m == a.m and not o.area then o.area = a end
  end
end
-- ZONES END

-- Zones posées à la main (hors du bloc généré) : chemins de patrouille, enveloppe de chaque chemin
-- de QuestieDB (points de passage), un camp par monstre. Même forme que ZONES.
local HAND_AREAS = {
  -- Toxic Test (9051) : les trois Diablosaures du cratère (QuestieDB : apparitions 34.6,22.4 /
  -- 57.3,23.7 / 31.2,36.4 et leurs chemins ; LibForeverData : 57.3,23.7)
  [9051] = { [1] = { m = 1449, pts = { { {34.7,22.2},{36.4,33},{36.5,34.5},{36.4,35.7},{32.6,44},{31.1,45.4} },
    { {57.3,23.9},{68,24.9},{69.7,25.3},{70.6,28.1},{70.6,29.3},{69.9,30.8},{65.1,35},{58.6,28.4},{57.5,24.9} },
    { {31.1,36.4},{33.9,38.4},{36.3,41.1},{38.2,44.3},{39.2,47.3},{41.7,63.8},{39.9,61.9} } },
    sp = { {57.3,23.9,2},{69.9,30.8,2},{64,26.2,2},{34.7,22.2,1},{36.5,34.5,1},{31.1,45.4,1},{31.1,36.4,3},{39.2,48.5,3},{41.7,63.8,3} } } },
}
for qid, list in pairs(HAND_AREAS) do
  local q = ns.Q[qid]
  for i, a in pairs(list) do
    local o = q and q.o and q.o[i]
    if o and o.w and o.w.m == a.m and not o.area then o.area = a end
  end
end

-- Où chercher dans une zone (o.area ci-dessus) : la note de la carte du guide (FR/EN), quand les
-- apparitions ne disent pas tout. [quête] = { [objectif] = { anglais, français } }.
local AREA_NOTES = {
  [1424] = { [1] = { "In the water of the pool, around the temple's island", "Dans l'eau du bassin, autour de l'île du temple" } },
  [9051] = { [1] = { "The Devilsaurs walk these paths: stab the first one you meet", "Les Diablosaures parcourent ces chemins : pique le premier que tu croises" } },
}
for qid, list in pairs(AREA_NOTES) do
  local q = ns.Q[qid]
  for i, t in pairs(list) do
    local o = q and q.o and q.o[i]
    if o and o.area then o.area.note = t[1]; ns.TR[t[1]] = t[2] end
  end
end
