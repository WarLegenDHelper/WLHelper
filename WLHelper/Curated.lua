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
  [2933] = { "The Venom Bottle is an object lying in the Witherbark troll camps of the Hinterlands: right-click it to get the quest.",
             "La Venom Bottle est un objet posé dans les camps des trolls Witherbark des Hinterlands : clic droit dessus pour obtenir la quête." },
}
for id, t in pairs(NOTES) do
  local q = ns.Q[id]
  if q and not q.ne then q.ne = t[1]; ns.TR[t[1]] = t[2] end
end
local zf = ns.D.ZulFarrak
if zf then table.insert(zf.q, MALLET) end

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
    elseif k.boss then how = ns.L.KEY_BOSS:format(BossName(k.boss, k.bossn), k.src and ns.DName(k.src) or "") end
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
    q.o = { { k = "item", n = "Hissing Serum", c = 1, w = { m = 1458, x = 48.8, y = 69.3, n = "Hissing Serum" } } }
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
  Maraudon = { "Lord Vyletongue", "Noxxion", "Razorlash", "Meshlok the Harvester", "Celebras the Cursed", "Landslide", "Princess Theradras", "Rotgrip", "Tinkerer Gizlock" },
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

-- =====================================================================
--  Rangement dans les étapes du donjon : corrections à la main
-- =====================================================================
ns.GROUP_OBJ = {   -- objectif ramassé un peu partout (pas sur un boss)
  ["Troll Temper"] = "*", ["Uncracked Scarab Shell"] = "*",
  ["Dentrium Power Stone"] = "*", ["An'Alleum Power Stone"] = "*", ["Tablet of Ryun'eh"] = "*",
  ["Theradric Crystal Carving"] = "*",
}
ns.GROUP_QUEST = { -- toute la quête se fait au même boss
  [7066] = "Princess Theradras",   -- l'esprit de Zaetar apparaît après Theradras
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
    ["Shade of Eranikus"] = { { "all", "Puts players to sleep and breathes acid: tank faces him away.", "Endort des joueurs et souffle de l'acide : le tank le tourne loin du groupe." } },
    ["Avatar of Hakkar"] = { { "all", "Egg of Hakkar on the altar: kill the Nightmare Suppressors fast, use Hakkari Blood on the four flames.", "Egg of Hakkar sur l'autel : tue vite les Nightmare Suppressors, verse le Hakkari Blood sur les quatre flammes." },
      { "all", "He mind-controls a player: crowd-control them.", "Il contrôle l'esprit d'un joueur : neutralise-le." } },
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
