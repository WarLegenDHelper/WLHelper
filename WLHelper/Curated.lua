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
function ns.KeyLines(dkey)
  local out = {}
  for _, k in ipairs(KEYS[dkey] or {}) do
    local name = (GetItemInfo and GetItemInfo(k.item)) or k.name
    local have = (GetItemCount and GetItemCount(k.item) or 0) > 0 or (k.quest and ns.IsDone(k.quest))
    local how
    if k.quest then how = ns.L.KEY_QUEST:format(ns.QName(k.quest))
    elseif k.boss then how = ns.L.KEY_BOSS:format(BossName(k.boss, k.bossn), k.src and ns.DName(k.src) or "") end
    local label = k.opt == "doors" and ns.L.KEY_DOORS or k.opt == "shortcut" and ns.L.KEY_SHORT or ns.L.KEY_REQ
    local Tk = ns.T_
    local txt = label .. ns.L.COLON .. name .. " · " .. (have and (ns.Hex(Tk.ok) .. ns.L.KEY_HAVE .. "|r") or (ns.Hex(Tk.warn) .. ns.L.KEY_MISSING .. "|r"))
    -- the key's own icon from the game, to spot it in the bags
    local ic = GetItemIcon and GetItemIcon(k.item)
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
  ZulFarrak = { "Antu'sul", "Theka the Martyr", "Witch Doctor Zum'rah", "Nekrum Gutchewer", "Shadowpriest Sezz'ziz", "Sergeant Bly", "Chief Ukorz Sandscalp", "Hydromancer Velratha", "Gahz'rilla", "Zerillis" },
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
