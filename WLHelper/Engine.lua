-- Moteur : état des quêtes, calcul de la route (plusieurs donjons, depuis la position du joueur), étapes.
local ADDON, ns = ...
-- BEGIN NPC_ELITE (baked by bake_elite.py from LibForeverData Npcs.lua rank: 1 elite / rare elite / boss, 0 normal / rare)
ns.NPC_ELITE = {["Alina"]=0,["Ambassador Malcin"]=1,["Amnennar the Coldbringer"]=1,["Andorhal Tower Four"]=0,["Andorhal Tower One"]=0,["Andorhal Tower Three"]=0,["Andorhal Tower Two"]=0,["Anguished Highborne"]=0,["Anvilrage Footman"]=1,["Anvilrage Guardsman"]=1,["Anvilrage Medic"]=1,["Anvilrage Officer"]=1,["Anvilrage Soldier"]=1,["Anvilrage Warden"]=1,["Archaedas"]=1,["Archivist Galford"]=1,["Archmage Arugal"]=1,["Arugal"]=1,["Atal'ai Warrior"]=1,["Atal'ai Witch Doctor"]=1,["Atal'alarion"]=1,["Avalanchion"]=1,["Axtroz"]=1,["Balnazzar"]=1,["Baron Aquanis"]=1,["Baron Charr"]=1,["Baron Geddon"]=1,["Baron Kazum"]=1,["Baron Rivendare"]=1,["Baroness Anastari"]=1,["Bazzalan"]=1,["Bile Spewer"]=1,["Black Drake"]=1,["Blackbreath Crony"]=1,["Blackfathom Tide Priestess"]=1,["Blackhand Assassin"]=1,["Blackhand Dreadweaver"]=1,["Blackhand Elite"]=1,["Blackhand Incarcerator"]=0,["Blackhand Iron Guard"]=1,["Blackhand Summoner"]=1,["Bleeding Horror"]=0,["Blood Elf Reclaimer"]=0,["Blood Elf Surveyor"]=0,["Blood Wraith"]=0,["Bloodaxe Evoker"]=1,["Bloodpetal Flayer"]=0,["Bloodpetal Lasher"]=0,["Bloodpetal Thresher"]=0,["Bloodpetal Trapper"]=0,["Borelgore"]=1,["Burning Blade Apprentice"]=0,["Burning Blade Fanatic"]=0,["Burning Blade Summoner"]=0,["Buzzard"]=0,["Cannon Master Willey"]=1,["Carrion Devourer"]=0,["Carrion Grub"]=0,["Carrion Lurker"]=0,["Carrion Vulture"]=0,["Caverndeep Ambusher"]=0,["Caverndeep Burrower"]=1,["Caverndeep Invader"]=1,["Charlga Razorflank"]=1,["Chieftain Bloodmaw"]=0,["Chillwind Chimaera"]=0,["Chillwind Ravager"]=0,["Cho'Rush the Observer"]=1,["Chronalis"]=1,["Cliff Breaker"]=1,["Cliff Thunderer"]=1,["Cliff Walker"]=1,["Coast Strider"]=1,["Commander Gor'shak"]=1,["Crag Coyote"]=0,["Crazed Owlbeast"]=0,["Crimson Battle Mage"]=1,["Crimson Defender"]=1,["Crimson Initiate"]=1,["Crimson Inquisitor"]=1,["Crimson Monk"]=1,["Crimson Priest"]=1,["Crimson Sorcerer"]=1,["Crypt Beast"]=1,["Crypt Crawler"]=1,["Cursed Atal'ai"]=1,["Cursed Centaur"]=0,["Cursed Justicar"]=1,["Cursed Paladin"]=1,["Cyrus Therepentous"]=1,["Dalaran Summoner"]=0,["Dark Iron Taskmaster"]=0,["Dark Shade"]=1,["Deadwood Gardener"]=0,["Death Knight Darkreaver"]=1,["Death Talon Captain"]=1,["Death Talon Seether"]=1,["Death's Head Cultist"]=1,["Deathstalker Agent"]=1,["Deep Lurker"]=1,["Demon of the Orb"]=1,["Dermot"]=0,["Desert Rumbler"]=0,["Deviate Coiler"]=1,["Deviate Creeper"]=1,["Deviate Dreadfang"]=1,["Deviate Ravager"]=1,["Deviate Shambler"]=1,["Deviate Stinglash"]=1,["Deviate Viper"]=1,["Devilsaur"]=1,["Devouring Ectoplasm"]=1,["Discordant Surge"]=0,["Diseased Black Bear"]=0,["Diseased Grizzly"]=0,["Doctor Theolen Krastinov"]=1,["Doomguard Commander"]=1,["Doomguard Minion"]=0,["Dreamroarer"]=1,["Duskwing"]=1,["Dust Stormer"]=0,["Dustwraith"]=1,["El Pollo Grande"]=0,["Elder Crag Coyote"]=0,["Elder Lake Creeper"]=0,["Elder Lake Skulker"]=0,["Eldreth Apparition"]=1,["Eldreth Sorcerer"]=1,["Eldreth Spirit"]=1,["Elemental Slave"]=0,["Emperor Dagran Thaurissan"]=1,["Enraged Rock Elemental"]=0,["Evolving Ectoplasm"]=1,["Eyeless Watcher"]=0,["Ezra Grimm"]=1,["Faldrim Anvilmar"]=1,["Felcular"]=1,["Feral Crag Coyote"]=0,["Ferocious Grizzled Bear"]=0,["Fineous Darkvire"]=1,["Firebrand Dreadweaver"]=1,["Firebrand Legionnaire"]=1,["Firebrand Pyromancer"]=1,["Fledgling Chillwind"]=0,["Fleshflayer Ghoul"]=1,["Frenzied Black Drake"]=1,["Frenzied Plaguehound"]=0,["Frostmaul Giant"]=1,["Frostmaul Preserver"]=1,["Gahz'rilla"]=1,["Gasher"]=1,["General Angerforge"]=1,["General Drakkisath"]=1,["Ghoul Ravener"]=1,["Giant Buzzard"]=0,["Giant Grizzled Bear"]=0,["Gizrul the Slavener"]=1,["Goblin Woodcarver"]=1,["Golem Lord Argelmach"]=1,["Golemagg the Incinerator"]=1,["Gordok Bushwacker"]=1,["Gordok Reaver"]=1,["Gorishi Hive Guard"]=0,["Gorishi Hive Queen"]=0,["Gorishi Wasp"]=0,["Great Wavethrasher"]=0,["Greater Healing Ward"]=0,["Greater Kraul Bat"]=1,["Greater Obsidian Elemental"]=0,["Greater Rock Elemental"]=0,["Grenka Bloodscreech"]=0,["Grimlok"]=1,["Guard Fengus"]=1,["Guard Slip'kik"]=1,["Gyth"]=1,["Halycon"]=1,["Hearthsinger Forresten"]=1,["Heavy War Golem"]=0,["Helboar"]=0,["Herod"]=1,["High Inquisitor Whitemane"]=1,["Highlord Omokk"]=1,["Hillsbrad Miner"]=0,["Hive'Ashi Defender"]=1,["Hive'Ashi Stinger"]=1,["Hive'Ashi Worker"]=1,["Hive'Regal Ambusher"]=1,["Hive'Regal Burrower"]=1,["Hive'Regal Spitfire"]=1,["Houndmaster Loksey"]=1,["Hukku"]=1,["Hurley Blackbreath"]=1,["Hydromancer Velratha"]=1,["Hydrospawn"]=1,["Illyanna Ravenoak"]=1,["Immol'thar"]=1,["Instructor Malicia"]=1,["Irontree Stomper"]=0,["Irontree Wanderer"]=0,["Isalien"]=1,["Ishamuhale"]=0,["J'eevee"]=0,["Jammal'an the Prophet"]=1,["Jandice Barov"]=1,["Jarien"]=1,["Jergosh the Invoker"]=1,["Kalaran Windblade"]=1,["Kegan Darkmar"]=0,["Kharan Mighthammer"]=1,["Kirtonos the Herald"]=1,["Kormok"]=1,["Kraul Bat"]=1,["Krethis Shadowspinner"]=0,["Lady Anacondra"]=1,["Lady Illucia Barov"]=1,["Lake Creeper"]=0,["Lake Skulker"]=0,["Lesser Rock Elemental"]=0,["Lethtendris"]=1,["Lorax"]=0,["Lord Cobrahn"]=1,["Lord Incendius"]=1,["Lord Kazzak"]=1,["Lord Pythas"]=1,["Lord Serpentis"]=1,["Lord Skwol"]=1,["Lord Valthalak"]=1,["Lord Vyletongue"]=1,["Lore Keeper of Norgannon"]=0,["Lorekeeper Polkelt"]=1,["Lorgus Jett"]=1,["Loro"]=1,["Mad Magglish"]=1,["Magister Kalendris"]=1,["Magma Lord Bokk"]=0,["Maleki the Pallid"]=1,["Malfunctioning Reaver"]=0,["Mana Remnant"]=1,["Mangled Cadaver"]=1,["Master Feardred"]=0,["Masterwork Target Dummy"]=0,["Mekgineer Thermaplugg"]=1,["Mercutio Filthgorger"]=0,["Mijan"]=1,["Mist Creeper"]=0,["Monstrous Plaguebat"]=0,["Mor Grayhoof"]=1,["Morphaz"]=1,["Moss Stalker"]=0,["Mosshoof Courser"]=0,["Mother Smolderweb"]=1,["Murk Worm"]=1,["Nancy Vishas"]=1,["Nathanos Blightcaller"]=1,["Neeru Fireblade"]=0,["Nerub'enkan"]=1,["Nightmare Ectoplasm"]=0,["Noxious Plaguebat"]=0,["Noxxion"]=1,["Noxxion's Spawn"]=0,["Noxxious Scion"]=0,["Oasis Snapjaw"]=0,["Obsidian Sentinel"]=1,["Old Vicejaw"]=0,["Ott"]=0,["Overlord Wyrmthalak"]=1,["Overmaster Pyron"]=1,["Patchwork Horror"]=1,["Pathstrider"]=0,["Petrified Treant"]=1,["Plague Ghoul"]=1,["Plaguebat"]=0,["Plagued Hatchling"]=0,["Plaguehound"]=0,["Plaguehound Runt"]=0,["Postmaster Malown"]=1,["Prince Skaldrenox"]=1,["Prince Tortheldrin"]=1,["Princess Tempestria"]=1,["Princess Theradras"]=1,["Pusillin"]=1,["Putridus Satyr"]=1,["Putridus Trickster"]=1,["Pyroguard Emberseer"]=1,["Rage Talon Dragon Guard"]=1,["Rage Talon Dragonspawn"]=1,["Rage Talon Fire Tongue"]=1,["Rage Talon Flamescale"]=1,["Ragefire Shaman"]=1,["Ragefire Trogg"]=1,["Ragereaver Golem"]=1,["Ragged John"]=0,["Ragged Owlbeast"]=0,["Raging Owlbeast"]=0,["Ramstein the Gorger"]=1,["Ranger"]=0,["Ras Frostwhisper"]=1,["Rath'mael"]=1,["Rattlegore"]=1,["Ravaged Cadaver"]=1,["Razorfen Battleguard"]=1,["Razorfen Thornweaver"]=1,["Restless Soul"]=0,["Ribbly Screwspigot"]=1,["Ricter"]=0,["Risen Construct"]=1,["Rok'Alim the Pounder"]=1,["Roogug"]=1,["Rookery Guardian"]=1,["Rumbling Exile"]=0,["Sandarr Dunereaver"]=1,["Saturated Ooze"]=1,["Scald"]=0,["Scarab"]=0,["Scarlet Commander Mograine"]=1,["Scarlet Magician"]=1,["Scarlet Praetorian"]=1,["Scarlet Preserver"]=1,["Scarlet Scout"]=1,["Scarshield Grunt"]=1,["Scarshield Legionnaire"]=1,["Scarshield Sentry"]=1,["Scarshield Spellbinder"]=1,["Scholomance Adept"]=1,["Scholomance Handler"]=1,["Scholomance Necromancer"]=1,["Scholomance Occultist"]=1,["Scholomance Student"]=1,["Scooty"]=0,["Screecher Spirit"]=0,["Scryer"]=1,["Searing Blade Cultist"]=1,["Searing Blade Warlock"]=1,["Sergeant Bly"]=1,["Shade of Eranikus"]=1,["Shadow Hunter Vosh'gajin"]=1,["Shadowfang Darksoul"]=1,["Shadowforge Digger"]=1,["Shadowforge Ruffian"]=1,["Shadowforge Surveyor"]=1,["Shadowshard Rumbler"]=1,["Shadowshard Smasher"]=1,["Shadowsworn Adept"]=0,["Shadowsworn Cultist"]=0,["Shadowsworn Thug"]=0,["Shore Strider"]=1,["Shrieking Banshee"]=1,["Silithid Creeper"]=0,["Silithid Grub"]=0,["Silithid Swarmer"]=0,["Singe"]=1,["Skeletal Flayer"]=0,["Skeletal Sorcerer"]=0,["Skeletal Terror"]=0,["Smolderthorn Axe Thrower"]=1,["Smolderthorn Berserker"]=1,["Smolderthorn Headhunter"]=1,["Smolderthorn Mystic"]=1,["Smolderthorn Seer"]=1,["Smolderthorn Shadow Hunter"]=1,["Smolderthorn Shadow Priest"]=1,["Smolderthorn Witch Doctor"]=1,["Solakar Flamewreath"]=1,["Somnus"]=1,["Sothos"]=1,["Spectral Teacher"]=1,["Spirestone Battle Mage"]=1,["Spirestone Mystic"]=1,["Spitelash Siren"]=0,["Starving Buzzard"]=0,["Stomper Kreeg"]=1,["Stonelash Flayer"]=0,["Stonelash Pincer"]=0,["Stonelash Scorpid"]=0,["Strashaz Serpent Guard"]=1,["Strashaz Sorceress"]=1,["Strashaz Warrior"]=1,["Suffering Highborne"]=0,["Summoned Blackhand Dreadweaver"]=1,["Sunscale Scytheclaw"]=0,["Swirling Vortex"]=0,["Tainted Ooze"]=0,["Takk the Leaper"]=1,["Tar Creeper"]=0,["Taragaman the Hungerer"]=1,["The Duke of Cynders"]=1,["The Ravenian"]=1,["The Unforgiven"]=1,["Theka the Martyr"]=1,["Theka the Martyr Shapeshift"]=1,["Theldren"]=1,["Theldren Kill Credit"]=0,["Thunderhead Patriarch"]=0,["Thunderhead Skystormer"]=0,["Thunderhead Stagwing"]=0,["Thuzadin Necromancer"]=1,["Thuzadin Shadowcaster"]=1,["Timbermaw Shaman"]=0,["Tink Sprocketwhistle"]=0,["Tirion Fordring"]=1,["Torn Screamer"]=0,["Tortured Druid"]=0,["Tortured Sentinel"]=0,["Twilight Acolyte"]=1,["Twilight Lord Kelris"]=1,["Ulathek"]=0,["Unseen Servant"]=0,["Urok Doomhowl"]=1,["Vectus"]=1,["Venom Belcher"]=1,["Venom Mist Lurker"]=0,["Veteran Commando"]=1,["Vile Fin Oracle"]=0,["Vile Fin Shredder"]=0,["Vile Fin Tidehunter"]=0,["Vilebranch Witch Doctor"]=0,["Wailing Banshee"]=1,["Wandering Spirit"]=0,["War Master Voone"]=1,["War Reaver"]=0,["Warbringer Construct"]=1,["Warchief Rend Blackhand"]=1,["Warden Belamoore"]=0,["Wavethrasher"]=0,["Weldon Barov"]=1,["Whirlwind Shredder"]=0,["Whirlwind Stormwalker"]=0,["Windshear Digger"]=0,["Windshear Tunnel Rat"]=0,["Windshear Vermin"]=0,["Witherbark Broodguard"]=0,["Withered Protector"]=0,["Woodsman"]=0,["Wrath Hammer Construct"]=1,["Writhing Mage"]=1,["Xorothian Dreadsteed"]=1,["Young Wavethrasher"]=0,["Ysida Harmon"]=0,["Zerillis"]=1,["Zolo"]=1,["Zul'Lor"]=1}
-- END NPC_ELITE
local CQL = C_QuestLog
local L = ns.L

-- strings of the guide's share button and of a dungeon entered with the tracker (added to the
-- root locale tables)
do
  local STR = {
    fr = {
      SHARE_GO1 = "Partage d'une quête avec le groupe", SHARE_GO = "Partage de %d quêtes avec le groupe",
      SHARE_SKIP1 = "%d ne se partage pas", SHARE_SKIP = "%d ne se partagent pas",
      SHARE_BUSY = "Partage déjà en cours : attends la fin avant de recommencer.",
      SHARE_NONE = "Aucune quête de ton journal pour cette route ne se partage.",
      SHARE_COMBAT = "Partage des quêtes après le combat", SHARE_AFTER = "Après le combat",
      SHARE_AFTER_TT = "Le jeu bloque le partage en combat : il partira à la fin du combat.",
      INST_IN_TRACK = "(clic sur le suivi pour ouvrir le guide)",
      INST_OFFER_TRACK = "Tu es dans %s : ouvre le guide pour l'ajouter à ta route.",
      LOCK_PRE = "il faut d'abord « %s » (%s)",
      LOCK_LVL = "niveau %d requis",
      LOCK_REP = "réputation %s requise : %s",
      LOCK_HIGH = "la chaîne monte au niveau %d",
      LOCK_LONG = "chaîne longue : %d quêtes avant",
      LOCK_OTHERDG = "elle passe par %s",
      LOCK_BAD = "chaîne impossible pour ce personnage",
      CL_LOCKED = "Bloquée", CL_LOCK_LINE = "Bloquée : %s · prérequis %d/%d",
      CL_LOCK_CLICK = "Clic : l'ajouter à la route avec sa chaîne de quêtes",
      WHY_FIRST = "D'abord à %s : il faut « %s » avant de parler à %s à %s.",
      WHY_FIRST_DO = "D'abord à %s : il faut « %s » avant « %s » à %s.",
    },
    en = {
      SHARE_GO1 = "Sharing 1 quest with the group", SHARE_GO = "Sharing %d quests with the group",
      SHARE_SKIP1 = "%d cannot be shared", SHARE_SKIP = "%d cannot be shared",
      SHARE_BUSY = "Already sharing: wait until it ends before sharing again.",
      SHARE_NONE = "No quest of your log for this route can be shared.",
      SHARE_COMBAT = "Sharing the quests after combat", SHARE_AFTER = "After combat",
      SHARE_AFTER_TT = "The game blocks sharing in combat: it goes out when combat ends.",
      INST_IN_TRACK = "(click the tracker to open the guide)",
      INST_OFFER_TRACK = "You are in %s: open the guide to add it to your route.",
      LOCK_PRE = "first needs \"%s\" (%s)",
      LOCK_LVL = "level %d required",
      LOCK_REP = "%s reputation required: %s",
      LOCK_HIGH = "the chain goes up to level %d",
      LOCK_LONG = "long chain: %d quests before",
      LOCK_OTHERDG = "it goes through %s",
      LOCK_BAD = "chain this character cannot do",
      CL_LOCKED = "Locked", CL_LOCK_LINE = "Locked: %s · prerequisite %d/%d",
      CL_LOCK_CLICK = "Click: add it to the route with its quest chain",
      WHY_FIRST = "First to %s: you need \"%s\" before talking to %s in %s.",
      WHY_FIRST_DO = "First to %s: you need \"%s\" before \"%s\" in %s.",
    },
  }
  local S = ns.LOCALE_TABLES
  if S then
    for lang, t in pairs(STR) do
      S[lang] = S[lang] or {}
      for k, v in pairs(t) do if S[lang][k] == nil then S[lang][k] = v end end
    end
  end
end

-- =====================================================================
--  État des quêtes
-- =====================================================================
function ns.IsDone(id)
  if CQL and CQL.IsQuestFlaggedCompleted then return CQL.IsQuestFlaggedCompleted(id) end
  return IsQuestFlaggedCompleted and IsQuestFlaggedCompleted(id)
end
-- no local copy of ns.IsDone: Curated.lua wraps it later (aliases, Valthalak's versions, the Mallet)

-- The quest log read once per frame: a refresh asks for it several times in a row.
local logCache, logTime
function ns.LogEntries()
  local t = GetTime and GetTime()
  if logCache and t and t == logTime then return logCache end
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
  logCache, logTime = list, t
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
  if n.kind == "c" then
    -- done once its own objectives are done (the same ones the step view shows: not those done
    -- outside, which have their own "o" nodes), not only when the whole quest is ready
    if s ~= "on" then return s == "ready" end
    local q = ns.Q[n.q]
    local any
    for _, o in ipairs(q and q.o or {}) do
      if not (o.w and not o.ins and not o.outer) then
        any = true
        if not ns.ObjDone(log, n.q, o) then return false end
      end
    end
    return any and true or false
  end
  if n.kind == "o" then return s == "ready" end
  return false
end

-- One refresh pass (the guide, its tracker, the target button) reads the same quest state many
-- times: ObjCount and IsStepDone keep their answers for the length of a pass. Outside a pass,
-- nothing is kept.
local passDepth, passGen = 0, 0
function ns.PassBegin() if passDepth == 0 then passGen = passGen + 1 end passDepth = passDepth + 1 end
function ns.PassEnd() if passDepth > 0 then passDepth = passDepth - 1 end end
function ns.PassGen() return passDepth > 0 and passGen or nil end
-- runs fn inside a pass; errors still reach the caller
function ns.InPass(fn, ...)
  ns.PassBegin()
  local r = { pcall(fn, ...) }
  ns.PassEnd()
  if not r[1] then error(r[2], 0) end
  return unpack(r, 2, table.maxn(r))
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
  if GetLocale and GetLocale() == "frFR" then
    if q.nf then return q.nf end
    -- a chain whose parts share one English title (Hidden Enemies 1 to 3) but only some have a
    -- French one: the French one, so one card never names the chain in two languages
    if q.n then
      if not ns.nfByN then
        local m = {}
        for _, x in pairs(ns.Q) do
          if type(x) == "table" and x.n and x.nf then
            if m[x.n] == nil then m[x.n] = x.nf elseif m[x.n] ~= x.nf then m[x.n] = false end
          end
        end
        ns.nfByN = m
      end
      local nf = ns.nfByN[q.n]
      if nf then return nf end
    end
  end
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
-- skill line ids (7th return of GetProfessionInfo)
local PROF_LINE = { MINING = 186, BLACKSMITHING = 164, ENGINEERING = 202, LEATHERWORKING = 165, TAILORING = 197,
  ALCHEMY = 171, ENCHANTING = 333, HERBALISM = 182, SKINNING = 393 }
-- HasProf(code [, minLevel]): the character has that profession (at minLevel or more when given);
-- second value: the skill read, nil when the client does not say it (then the level is not checked)
local function Skill(v) return type(v) == "number" and not (issecretvalue and issecretvalue(v)) and v or nil end
local function LevelOK(rank, minLevel) return not minLevel or rank == nil or rank >= minLevel end
function ns.HasProf(code, minLevel)
  -- Forever (modern engine): no skill list, professions come from GetProfessions
  if GetProfessions and GetProfessionInfo then
    local list = { pcall(GetProfessions) }
    if list[1] then
      local want, names = PROF_LINE[code], PROF[code]
      if not want then return true end
      for i = 2, 7 do
        local idx = list[i]
        if idx then
          local ok, nm, _, rank, _, _, _, line = pcall(GetProfessionInfo, idx)
          if ok and (line == want or (nm and names and (nm == names[1] or nm == names[2]))) then
            rank = Skill(rank)
            return LevelOK(rank, minLevel), rank
          end
        end
      end
      return false
    end
  end
  if not (GetNumSkillLines and GetSkillLineInfo) then return true end
  local names = PROF[code]
  if not names then return true end
  for i = 1, GetNumSkillLines() do
    local nm, isHeader, _, rank = GetSkillLineInfo(i)
    if nm and not isHeader then
      for _, n in ipairs(names) do
        if nm == n then rank = Skill(rank); return LevelOK(rank, minLevel), rank end
      end
    end
  end
  return false
end

-- « quêtes utiles » : sans les répétables ni les quêtes d'un métier que tu n'as pas (réglage, activé par défaut)
function ns.Useful(q)
  -- a repeatable that opens once its first version is turned in (q.after): never before, even with
  -- every quest on ("/wlh tout")
  if q.after and not ns.IsDone(q.after) then return false end
  if WLDTDB and WLDTDB.useful == false then return true end
  if q.rep then return false end
  if q.prof and not ns.HasProf(q.prof, q.profLv) then return false end
  return true
end

-- A quest that is only a walk to someone ("Speak with...", "Locate...", "Report to..."): nothing to
-- do between taking it and handing it in, so no objective step
local TALK = { "^speak with", "^talk to", "^report to", "^locate ", "^find ", "^seek out", "^return to", "^bring .* to ", "^deliver",
  "^parle", "^rends%-toi", "^trouve", "^rapporte", "^retourne" }
function ns.TalkQuest(q)
  local t = (q.oe or ""):lower()
  for _, p in ipairs(TALK) do if t:find(p) then return true end end
  return false
end

-- the player's faction and race: a quest of the other faction, or kept for other races, is never offered
local function FactionOK(fa)
  if not fa or fa == "" or fa == "Both" then return true end
  local mine = UnitFactionGroup and UnitFactionGroup("player")
  if not mine or mine == "Neutral" then return fa ~= "Alliance" end
  return fa == mine
end
local function RaceOK(race)
  if not race then return true end
  local tok
  if UnitRace then tok = select(2, UnitRace("player")) end
  if not tok then return true end
  tok = tok:upper(); if tok == "SCOURGE" then tok = "UNDEAD" end
  for r in race:gmatch("[^,]+") do
    r = r:upper(); if r == "SCOURGE" then r = "UNDEAD" end
    if r == tok then return true end
  end
  return false
end
ns.FactionOK, ns.RaceOK = FactionOK, RaceOK
-- Every prerequisite of a quest, followed all the way down (the prerequisites of a prerequisite
-- first), each once, in order. nil when one of them cannot be done by this character (other
-- faction, class or race, or unknown): the quest itself is then left out of the route.
local function FullChain(qid, cls, out, seen, depth)
  out, seen, depth = out or {}, seen or {}, depth or 0
  local q = ns.Q[qid]
  if not q or depth > 20 then return out end
  for _, pid in ipairs(q.p or {}) do
    if not seen[pid] then
      seen[pid] = true
      local pq = ns.Q[pid]
      -- a quest both factions do can list each faction's own lead-in under the same name (3446:
      -- "The Sunken Temple", 3380 for the Horde and 3445 for the Alliance; the game takes either):
      -- the other faction's one is skipped when this faction's twin is in the list too
      -- (twins named apart, "Return to Mokvar" / "Return to Deliana", say so with tw = the other's id)
      -- the same goes for class variants (An Earnest Proposition, one per class: the game takes
      -- yours): another class's variant is skipped when yours is in the list too
      local otherSide = false
      local foreign = pq and not FactionOK(pq.fa)
      local otherCls = pq and not foreign and not (ClassOK(pq.c, cls) and RaceOK(pq.race))
      if (foreign and (not q.fa or q.fa == "" or q.fa == "Both")) or otherCls then
        for _, tid in ipairs(q.p) do
          local tq = ns.Q[tid]
          if tid ~= pid and tq and (tq.n == pq.n or tq.tw == pid or pq.tw == tid) and FactionOK(tq.fa) and ClassOK(tq.c, cls) and RaceOK(tq.race)
            and (otherCls or tq.fa ~= pq.fa) then otherSide = true break end
        end
      end
      if not otherSide then
        if not (pq and FactionOK(pq.fa) and ClassOK(pq.c, cls) and RaceOK(pq.race)) then return nil end
        if not FullChain(pid, cls, out, seen, depth + 1) then return nil end
        out[#out + 1] = pid
      end
    end
  end
  return out
end
ns.FullChain = FullChain

function ns.DungeonQuests(dkey, cls)
  local d, out = ns.D[dkey], {}
  if not d then return out end
  for _, qid in ipairs(d.q or {}) do
    local q = ns.Q[qid]
    if q and FactionOK(q.fa) and ClassOK(q.c, cls) and RaceOK(q.race) and not q.unk and ns.Useful(q) and FullChain(qid, cls) then table.insert(out, qid) end
  end
  return out
end

-- =====================================================================
--  Locked quests: a main quest behind a prerequisite chain. A chain the player can do now at a
--  bounded cost goes into the route ("before the dungeon" steps, MakeNodes); one too high or too
--  long keeps the quest out of the route by default, and the Overview lists it as locked with
--  ns.LockedReason's text (a quest ticked by hand still gets its chain).
-- =====================================================================
local CHAIN_GAP = 5     -- a chain quest more than 5 levels above the player: not now (Overview's HIGH_GAP)
local CHAIN_MAX = 14    -- work left in the chain (ChainWork) above which the chain is too long
-- Rough work of one prerequisite: the walk to its giver and back, one per spot outside, a run of
-- another dungeon (its objectives inside an instance other than dkey's)
local function ChainWork(pq, dkey)
  local w = 1
  local inside = false
  for _, o in ipairs(pq.o or {}) do
    if o.w and not o.ins then w = w + 1
    elseif o.ins or o.unk then inside = true end
  end
  if not pq.o and pq.req then w = w + #pq.req end
  local dg = pq.od or pq.d
  if inside and dg and dkey and dg ~= dkey then
    local a, b = ns.D[dg], ns.D[dkey]
    if not (a and b and a.inst and a.inst == b.inst) then w = w + 8 end
  end
  return w
end
-- A reputation the quest needs (q.rq = { factionID, standing 1-8 }, 4 = Neutral): true when the
-- character has it or it cannot be read (report: "the guide offers The Twin Bears first, I am
-- Unfriendly with Timbermaw and cannot take it")
local function Standing(fid)
  local CR = rawget(_G, "C_Reputation")
  if CR and CR.GetFactionDataByID then
    local ok, d = pcall(CR.GetFactionDataByID, fid)
    if ok and type(d) == "table" and tonumber(d.reaction) then return tonumber(d.reaction) end
  end
  local GI = rawget(_G, "GetFactionInfoByID")
  if GI then
    local ok, _, _, standing = pcall(GI, fid)
    if ok and tonumber(standing) then return tonumber(standing) end
  end
  return nil
end
ns.FactionStanding = Standing
function ns.RepOK(q)
  local rq = q and q.rq
  if not rq then return true end
  local s = Standing(rq[1])
  return s == nil or s >= rq[2]
end
-- What is left of a main quest's chain for this character.
-- -> { chain, left = { pid... }, first, need (r of the first left), top (highest l / r left),
--      work, other (another dungeon on the way), started, bad (a link this character cannot do) }
function ns.ChainPlan(qid, cls, dkey)
  local q = ns.Q[qid]
  if not q then return nil end
  if not cls then cls = select(2, UnitClass("player")) end
  local chain = FullChain(qid, cls)
  local plan = { chain = chain or {}, left = {}, work = 0, need = 0, top = 0, ql = math.max(q.l or 0, q.r or 0) }
  if not chain then plan.bad = true; return plan end
  dkey = dkey or q.d
  local log = ns.LogEntries()
  local onQ = CQL and CQL.IsOnQuest
  if log[qid] or (onQ and onQ(qid)) then plan.started = true end
  if not ns.RepOK(q) then plan.rep = qid end
  for _, pid in ipairs(chain) do
    if not ns.IsDone(pid) then
      local pq = ns.Q[pid] or {}
      plan.left[#plan.left + 1] = pid
      if log[pid] or (onQ and onQ(pid)) then plan.started = true end
      if not plan.first then plan.first = pid; plan.need = pq.r or 0 end
      if not plan.rep and not ns.RepOK(pq) then plan.rep = pid end
      local l = math.max(pq.l or 0, pq.r or 0)
      if l > plan.top then plan.top = l end
      local w = ChainWork(pq, dkey)
      plan.work = plan.work + w
      local dg = pq.od or pq.d
      if not plan.other and w >= 9 and dg and dg ~= dkey and ns.D[dg] then plan.other = dg end
    end
  end
  return plan
end
-- Can the chain go into the route now? -> ok, cause ("lvl" | "high" | "long" | "bad" | "rep")
local function ChainOK(plan, lvl)
  if not plan then return true end
  if plan.bad then return false, "bad" end
  if plan.started then return true end
  if plan.rep then return false, "rep" end
  if #plan.left == 0 then return true end
  if plan.need > lvl then return false, "lvl" end
  -- a chain no higher than the quest itself (an item that starts it, dropped in the same dungeon)
  -- does not lock it: the quest's own level is the Overview's call
  if plan.top > lvl + CHAIN_GAP and plan.top > (plan.ql or 0) then return false, "high" end
  if plan.work > CHAIN_MAX then return false, "long" end
  return true
end
function ns.ChainOK(qid, lvl, cls, dkey)
  return ChainOK(ns.ChainPlan(qid, cls, dkey), lvl or (UnitLevel and UnitLevel("player")) or 1)
end
-- "Jarkal Mossmeld, Kargath, Badlands" -> "Jarkal Mossmeld, Kargath"; a city at the end wins
-- over its district ("Dran Droffers, The Drag, Orgrimmar" -> "Dran Droffers, Orgrimmar")
local CITY = { Orgrimmar = true, Undercity = true, ["Thunder Bluff"] = true, Stormwind = true,
  ["Stormwind City"] = true, Ironforge = true, Darnassus = true }
local function GiverText(pq)
  local st = pq and pq.st
  if not st and pq and pq.s and pq.s.n then st = pq.s.n end
  if not st then return "?" end
  st = st:gsub("%s*%b()", "")
  local segs = {}
  for seg in st:gmatch("[^,]+") do segs[#segs + 1] = seg:match("^%s*(.-)%s*$") end
  if #segs <= 2 then return table.concat(segs, ", ") end
  local place = CITY[segs[#segs]] and segs[#segs] or segs[2]
  return segs[1] .. ", " .. place
end
ns.GiverText = GiverText
-- Why a main quest is out of the route although its dungeon is picked: its chain is too high, too
-- long or impossible. nil when the quest is done, started, free or its chain goes into the route.
-- -> text, cause ("lvl" | "high" | "long" | "bad"), first prerequisite left
function ns.LockedReason(qid, lvl, cls, dkey)
  local q = ns.Q[qid]
  if not q or ns.IsDone(qid) then return nil end
  lvl = lvl or (UnitLevel and UnitLevel("player")) or 1
  local plan = ns.ChainPlan(qid, cls, dkey)
  local ok, cause = ChainOK(plan, lvl)
  if ok then return nil end
  if cause == "bad" then return L.LOCK_BAD, cause end
  if cause == "rep" then
    local rq = ns.Q[plan.rep].rq
    local fname = rq[3] or ("#" .. rq[1])
    local GFI = rawget(_G, "GetFactionInfoByID")
    if GFI then local okN, n = pcall(GFI, rq[1]); if okN and type(n) == "string" and n ~= "" then fname = n end end
    local sname = rawget(_G, "FACTION_STANDING_LABEL" .. rq[2]) or tostring(rq[2])
    return L.LOCK_REP:format(fname, sname), cause, plan.rep
  end
  local first = plan.first
  local txt = L.LOCK_PRE:format(ns.QName(first), GiverText(ns.Q[first]))
  local why
  if cause == "lvl" then why = L.LOCK_LVL:format(plan.need)
  elseif cause == "high" then why = L.LOCK_HIGH:format(plan.top)
  elseif plan.other then why = L.LOCK_OTHERDG:format(ns.DName(plan.other))
  else why = L.LOCK_LONG:format(#plan.left) end
  return txt .. (GetLocale and GetLocale() == "frFR" and " : " or ": ") .. why, cause, first
end
-- in the route: free, a chain that fits, or ticked by hand (WLDTDB.offPick) whatever its chain.
-- A key or class-quest card (cq) and a raid's attunement are the chain itself: always in.
local function InRoute(qid, cls, lvl, dkey)
  local d = dkey and ns.D[dkey]
  if d and (d.cq or d.raid) then return true end
  local pick = WLDTDB and WLDTDB.offPick
  if pick and pick[qid] and not (WLDTDB.off and WLDTDB.off[qid]) then return true end
  return (ChainOK(ns.ChainPlan(qid, cls, dkey), lvl))
end
ns.ChainInRoute = InRoute
-- T-91: a check-list line for a quest whose chain is not done before the gate: "Locked: first
-- needs "X" (NPC, zone) · prerequisite 4/7" (the n/m of the guide's "Prerequisite 4/7" pill)
function ns.CheckLockText(qid, cls, dkey)
  local plan = ns.ChainPlan(qid, cls, dkey)
  local first = plan and plan.first
  if not first then return nil end
  local cs = ns.ChainState(qid)
  return L.CL_LOCK_LINE:format(L.LOCK_PRE:format(ns.QName(first), GiverText(ns.Q[first])),
    math.min(cs.done + 1, cs.total), cs.total)
end
-- A click on a locked line: the quest ticked by hand (offPick), so its chain joins the route
-- (ChainInRoute), as a tick in the Overview does
function ns.GuideLockPick(qid)
  if not qid then return end
  if ns.SummarySetOff then ns.SummarySetOff(qid, false) return end
  WLDTDB.offPick = WLDTDB.offPick or {}
  WLDTDB.offPick[qid] = true
  if WLDTDB.off then WLDTDB.off[qid] = nil end
  if ns.Replan then pcall(ns.Replan) end
end

-- =====================================================================
--  Positions (coordonnées monde via l'API de carte)
-- =====================================================================
local worldCache = {}
local function WorldRaw(m, x, y)
  if C_Map and C_Map.GetWorldPosFromMapPos and CreateVector2D then
    local ok, cont, pos = pcall(C_Map.GetWorldPosFromMapPos, m, CreateVector2D(x / 100, y / 100))
    if ok and cont and pos then return { cont, pos.x, pos.y } end
  end
  return false
end
-- Fixed points (quest givers, entrances) are kept; `live` positions (the player's) are not.
function ns.World(m, x, y, live)
  if not (m and x and y) then return nil end
  if live then return WorldRaw(m, x, y) or nil end
  local k = m .. ":" .. x .. ":" .. y
  local c = worldCache[k]
  if c ~= nil then return c or nil end
  local res = WorldRaw(m, x, y)
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
  return ns.World(m, px * 100, py * 100, true), m, px * 100, py * 100
end

local function Dist(a, b)
  if not a or not b then return 0 end
  if a[1] ~= b[1] then return 6000 end   -- other continent: far, whatever the spot
  return math.sqrt((a[2] - b[2]) ^ 2 + (a[3] - b[3]) ^ 2)
end

-- The real way there, in yards of walking: the GPS's search (Writs/Route.lua, GPS.CostsFrom: roads,
-- flight paths, boats) gives seconds, times the speed it priced them at. The route orders its steps
-- by this, as Shortest Path does, and not by the straight line: from Feralas, Un'Goro is near on the
-- map and far on foot; a flight makes a far town near. Close by, the straight line is the way.
-- Only for a step more than TRAVEL_FAR yards away or on another continent; on the same continent
-- the real trip only lowers the cost (a flight, a boat), it never raises it. nil when the GPS cannot say
-- (not loaded, a map it cannot read): the straight line then.
local TRAVEL_FAR = 1000
function ns.TravelYards(from, list)
  -- off until the order is planned zone by zone: picked step by step, a cheap flight elsewhere
  -- left a zone with work still to do there (writ/route_bounce_test). WLDTDB.travelOrder = true: on.
  if not (WLDTDB and WLDTDB.travelOrder == true) then return nil end
  local WP = ns.Writs and ns.Writs.WP
  local G = WP and WP.GPS
  if not (G and G.CostsFrom and from and list and #list > 0) then return nil end
  local ok, secs, speed = pcall(G.CostsFrom, from, list)
  if not (ok and type(secs) == "table" and type(speed) == "number" and speed > 0) then return nil end
  local out = {}
  for i = 1, #list do if secs[i] then out[i] = secs[i] * speed end end
  return out
end

-- =====================================================================
--  Nœuds de la route
-- =====================================================================
-- An objective of the zone around a dungeon ("outer") that is outside the instance and near its
-- entrance: same map, within OUTER_NEAR map units (the data's outer spots far from the entrance are
-- guesses: those stay with the dungeon visit).
local OUTER_NEAR = 15
local function OuterNear(o, dkey)
  local d = dkey and ns.D[dkey]
  local e, w = d and d.e, o.w
  if not (e and w and e.m and w.m == e.m and e.x and w.x) then return false end
  return math.sqrt((e.x - w.x) ^ 2 + (e.y - w.y) ^ 2) <= OUTER_NEAR
end
-- the quest's notes say its outer spots are outside the instance (the excavation of Uldaman, the
-- outer caves of Maraudon); an "outer" objective without such a note may be inside the instance
-- (Wailing Caverns' Mad Magglish) and stays with the dungeon visit
local OUTSIDE_NOTE = { "outside the instance", "before the instance portal", "without entering the instance",
  "dig site", "excavation" }
local function NotedOutside(q)
  local txt = (q.ne or "")
  for _, r in ipairs(q.req or {}) do txt = txt .. " " .. tostring(r[3] or "") end
  txt = txt:lower()
  for _, p in ipairs(OUTSIDE_NOTE) do if txt:find(p, 1, true) then return true end end
  return false
end
-- every objective of q has a place outside the instance and at least one is such an outer spot
local function OuterAllNear(q, dkey)
  if not NotedOutside(q) then return false end
  local any = false
  for _, o in ipairs(q.o or {}) do
    if o.ins or o.unk or not o.w then return false end
    if o.outer then
      if not OuterNear(o, dkey) then return false end
      any = true
    end
  end
  return any
end
ns.OuterAllNear = OuterAllNear

-- kind : a = prendre, o = objectif dehors, c = objectifs du donjon, t = rendre, i = objet (extras)
-- loc  : {m,x,y,n}  ou  ins = clé du donjon (alors la position est l'entrée du donjon)
local function MakeNodes(sel, cls)
  local nodes, byKey = {}, {}
  local lvl = (UnitLevel and UnitLevel("player")) or 1
  -- tag: the route dungeon the nodes serve (dk) and, for a prerequisite, the main quest it unlocks
  -- (forQ, a list: one prerequisite shared by two main quests is one node) and its place in that
  -- quest's chain (ci of cn)
  local tag
  local function Tag(n)
    if not tag then return end
    n.dk = n.dk or tag.dk
    if tag.forQ then
      n.forQ = n.forQ or {}
      local has = false
      for _, x in ipairs(n.forQ) do if x == tag.forQ then has = true break end end
      if not has then table.insert(n.forQ, tag.forQ) end
      n.ci = n.ci or tag.ci; n.cn = n.cn or tag.cn
    end
  end
  local function add(n)
    n.key = n.kind .. ":" .. tostring(n.q) .. (n.sub and (":" .. n.sub) or "")
    if byKey[n.key] then Tag(byKey[n.key]) return byKey[n.key] end
    n.deps = n.deps or {}
    Tag(n)
    byKey[n.key] = n; table.insert(nodes, n)
    return n
  end
  local function qnodes(qid, dkey, isPre)
    local q = ns.Q[qid]
    if not q then return nil end
    -- anyd : la quête se fait dans n'importe lequel de ses donjons (q.ds) ; on prend celui de la sélection
    local home = q.d or dkey
    if q.anyd and q.ds then
      for _, k in ipairs(q.ds) do if k == dkey then home = dkey; break end end
    end
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
    -- an item start dropped in the dungeon ("Item start: Glowing Shard, dropped by Mutanus"): taken
    -- there even when the data gives the turn-in NPC as the giver
    local itemStart = q.si and type(q.st) == "string" and q.st:match("^Item start") and q.st:match("dropped by") and q.d
    if q.si and (not sl or sl.i or itemStart) then
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
    local objNode = {}   -- objective index -> its outside node (o.after links)
    -- a main quest whose every objective is outside, some of them in the zone around the dungeon
    -- (the Uldaman excavation: fungus, tablet, chests, power stones) gets one outside step per
    -- objective at its spot, like a prerequisite, instead of one line after the last boss: the
    -- spot is visited once, with the other quests done there (BuildRoute, MakeSteps "area")
    local nearAll = not isPre and OuterAllNear(q, q.od or home)
    for i, o in ipairs(q.o or {}) do
      local outerHere = o.outer and not isPre and not nearAll
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
        -- one action per objective: done when that objective is done (ns.ObjDone), so the route
        -- moves on objective by objective instead of waiting for the whole quest
        table.insert(outs, add({ kind = "o", q = qid, sub = i, oi = i, loc = o.w, npc = o.t and o.t[1] or o.n, obj = o, oneObj = o, d = home, pre = isPre, deps = { A },
          area = (o.outer or o.near) and OuterNear(o, q.od or home) and NotedOutside(q) and (q.od or home) or nil }))
        objNode[i] = outs[#outs]
      elseif o.ins or outerHere or o.unk then
        real = real + 1
        inside = true
        if not outerHere then outer = false end
      end
    end
    -- objectives with no known place but a known list (q.req: "Pylon Fragment, guarded in a centaur
    -- village"): one step per item anyway, so the turn-in never comes straight after the take; the
    -- arrow then uses the game's own quest area (UI.lua GamePOI) where there is one
    if real == 0 and not inside and q.req and #q.req > 0 and (isPre or q.noin) then
      for i, r in ipairs(q.req) do
        local o = { k = "item", n = r[1], c = r[2] or 1, note = r[3], unk = true }
        real = real + 1
        table.insert(outs, add({ kind = "o", q = qid, sub = i, oi = i, unknown = true, npc = r[1], obj = o, oneObj = o,
          noLoc = true, mapHint = q.s and not q.s.i and q.s.m or nil, d = home, pre = isPre, deps = { A } }))
      end
    elseif real == 0 and not inside and A.ins and q.f and q.f.i and not q.noin then
      -- given and turned in inside the dungeon (Belnistrasz's Oathstone): what it asks with no
      -- known place is done there too, never in a step outside between two visits
      inside = true; outer = false
    elseif real == 0 and not inside and (isPre or q.noin) and q.oe and not ns.TalkQuest(q) and not q.ftask then
      -- nothing but the quest's text ("Acquire the Mana Sieve ... collect Ancient Mana Crystals"):
      -- one "do the objectives" step that ends when the game says the quest is complete
      real = 1
      table.insert(outs, add({ kind = "o", q = qid, sub = 1, unknown = true, npc = ns.QName(qid), obj = { k = "text", n = q.oe, unk = true },
        noLoc = true, mapHint = q.s and not q.s.i and q.s.m or nil, d = home, pre = isPre, deps = { A } }))
    end
    -- quête de donjon sans objectif connu (quêtes Forever récentes) : objectifs dans le donjon
    -- q.ftask: the turn-in is the task itself (Mason's treasure under a floorboard in Moonbrook):
    -- nothing to do inside, no "do" step, only the turn-in where it lies
    if not isPre and not q.noin and not q.ftask and real == 0 and (q.o == nil or #q.o > 0 or q.ne) then inside = true; outer = false end
    local C
    if inside then C = add({ kind = "c", q = qid, ins = inDg, outer = outer, d = inDg, pre = isPre, deps = { A } }) end
    -- o.after = k: this objective needs objective k first (the Amulet of Spirits before the Khans'
    -- gems): its outside step, or the dungeon's objectives (C), wait on k's outside step
    for i, o in ipairs(q.o or {}) do
      local p = o.after and objNode[o.after]
      local me = objNode[i] or C
      if p and me and me ~= p then
        local has = false
        for _, d in ipairs(me.deps) do if d == p then has = true break end end
        if not has then table.insert(me.deps, p) end
      end
    end
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
  -- a grey optional quest (ns.GreyOptional, Overview.lua) stays out unless ticked by hand
  -- (offPick), as the Overview's default untick does, even when the Overview never showed the
  -- dungeon (a slash command, a key card, a restart)
  local pick = (ns.OffPick and ns.OffPick()) or (WLDTDB and WLDTDB.offPick) or {}
  local log = ns.GreyOptional and ns.LogEntries() or nil
  local function Grey(qid, dkey)
    if pick[qid] or not ns.GreyOptional then return false end
    local d = ns.D[dkey]
    if d and (d.cq or d.raid) then return false end
    return ns.GreyOptional(qid, dkey, lvl, log)
  end
  for dkey in pairs(sel) do
    for _, qid in ipairs(ns.DungeonQuests(dkey, cls)) do
      local q = ns.Q[qid]
      if not (WLDTDB.off and WLDTDB.off[qid]) and not q.extra and InRoute(qid, cls, lvl, dkey)
        and not Grey(qid, dkey) then
        local prevT
        local Tby = {}
        local chain = FullChain(qid, cls) or {}
        for ci, pid in ipairs(chain) do
          local pq = ns.Q[pid]
          if pq then
            tag = { dk = dkey, forQ = qid, ci = ci, cn = #chain }
            local A, T = qnodes(pid, dkey, true)
            tag = nil
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
        tag = { dk = dkey }
        local A = qnodes(qid, dkey, false)
        tag = nil
        if A and prevT then table.insert(A.deps, prevT) end
      end
    end
  end
  -- extras (maillet de Zul'Farrak...)
  if ns.Extras then ns.Extras(nodes, byKey, add, sel, cls) end
  ns.AssignPhases(nodes)
  return nodes, byKey
end

-- =====================================================================
--  Phases: "before" (outside, before entering: prerequisites, takes, outside objectives, the
--  entrance), "inside" (in the instance), "after" (turn-ins and follow-ups once the dungeon is done)
-- =====================================================================
local PH_RANK = { before = 1, inside = 2, after = 3 }
ns.PHASES = { "before", "inside", "after" }
local function NodeDungeon(n) return n.dk or n.ins or n.d end
-- a node done in the instance itself: objectives of the zone around the dungeon (outer) are outside
local function InsideNode(n) return n.ins ~= nil and not (n.kind == "c" and n.outer) end
function ns.AssignPhases(nodes)
  local memo = {}
  -- does n wait (through its dependencies) on something done inside dungeon d?
  local function afterInside(n, d, depth)
    local k = tostring(n) .. "@" .. tostring(d)
    if memo[k] ~= nil then return memo[k] end
    memo[k] = false
    if depth > 60 then return false end
    for _, p in ipairs(n.deps or {}) do
      if (InsideNode(p) and p.ins == d) or afterInside(p, d, depth + 1) then memo[k] = true; return true end
    end
    return false
  end
  for _, n in ipairs(nodes) do
    if InsideNode(n) then n.phase = "inside"
    elseif afterInside(n, NodeDungeon(n), 0) then n.phase = "after"
    else n.phase = "before" end
  end
end

-- The phase of a route step (gate = before; a step with anything done in the instance = inside;
-- otherwise the earliest phase of its actions).
function ns.StepPhase(st)
  if not st then return nil end
  if st.phase then return st.phase end
  local ph
  if st.gate then ph = "before"
  elseif st.split or st.inner then ph = "inside"
  else
    for _, n in ipairs(st.acts or {}) do
      local p = n.phase or (InsideNode(n) and "inside") or "before"
      if p == "inside" then ph = "inside" break end
      if not ph or PH_RANK[p] < PH_RANK[ph] then ph = p end
    end
  end
  st.phase = ph or "before"
  return st.phase
end

-- The route dungeon a step belongs to (multi-dungeon routes count each dungeon on its own).
function ns.StepDungeon(st)
  if not st then return nil end
  if st.dk then return st.dk end
  if st.gate then return st.gate end
  local a = st.acts and st.acts[1]
  -- done in an instance: that instance (a prerequisite done in another dungeon counts there), else
  -- the route dungeon the action serves
  return (a and InsideNode(a) and a.ins) or (a and NodeDungeon(a)) or st.ins or st.d
end

-- Steps per phase for one dungeon of the route (dkey nil: the whole route).
-- -> { before = { done, total }, inside = {...}, after = {...} } (fields done / total).
function ns.PhaseProgress(dkey)
  local out = { before = { done = 0, total = 0 }, inside = { done = 0, total = 0 }, after = { done = 0, total = 0 } }
  local steps = ns.route and ns.route.steps or {}
  local log = ns.LogEntries()
  for i, st in ipairs(steps) do
    if not dkey or ns.StepDungeon(st) == dkey then
      local b = out[ns.StepPhase(st)] or out.before
      b.total = b.total + 1
      local ok
      if ns.IsStepDone then ok = ns.IsStepDone(log, i)
      else
        ok = #st.acts > 0
        for _, n in ipairs(st.acts) do if not ns.NodeOK(log, n) then ok = false break end end
      end
      if ok then b.done = b.done + 1 end
    end
  end
  return out
end

-- =====================================================================
--  Prerequisite chains: how far the player is in the chain of one main quest
-- =====================================================================
-- -> { total, done, inLog, nextPid, nextInLog, chain } (chain = the prerequisite ids in order)
function ns.ChainState(mainQid)
  local _, cls = UnitClass("player")
  local chain = FullChain(mainQid, cls) or {}
  local log = ns.LogEntries()
  local out = { total = #chain, done = 0, inLog = 0, chain = chain }
  for _, pid in ipairs(chain) do
    if ns.IsDone(pid) then out.done = out.done + 1
    else
      if log[pid] then out.inLog = out.inLog + 1 end
      if not out.nextPid then out.nextPid = pid; out.nextInLog = log[pid] ~= nil end
    end
  end
  return out
end

-- One ranked status word per quest, shared by the picker, the list and the card:
-- "done" > "ready" > "active" > "prelog" > "pre" > "low" > "pickup".
-- -> code, text (one of the ST_ strings), and for "pre"/"prelog" the ChainState.
function ns.QuestStatus(qid, log)
  log = log or ns.LogEntries()
  local s = State(log, qid)
  if s == "done" then return "done", L.ST_DONE end
  if s == "ready" then return "ready", L.ST_READY end
  if s == "on" then return "active", L.ST_ACTIVE end
  local cs = ns.ChainState(qid)
  if cs.nextPid then
    if cs.nextInLog then return "prelog", L.ST_PRELOG:format(cs.done + 1, cs.total), cs end
    return "pre", L.ST_PRE:format(cs.done + 1, cs.total), cs
  end
  local q = ns.Q[qid]
  local lvl = UnitLevel and UnitLevel("player") or 1
  if q and q.r and q.r > lvl then return "low", L.ST_LOW:format(q.r) end
  return "pickup", L.ST_PICKUP
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
-- withTurnIn (summary only): a quest turned in inside the dungeon also needs its outside pickup.
local function PreEntry(nodes, withTurnIn)
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
    if (n.kind == "c" or (withTurnIn and n.kind == "t")) and n.ins then
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

-- Read-only, for the summary: the guide's "before entering" list (PreEntry) per dungeon of sel,
-- and the quests taken inside it. -> { [dkey] = { before = { [qid] = true }, inside = { [qid] = true } } }
function ns.PreEntryQuests(sel, cls)
  if not cls then cls = select(2, UnitClass("player")) end
  local nodes = MakeNodes(sel, cls)
  local out = {}
  local function slot(d) out[d] = out[d] or { before = {}, inside = {} }; return out[d] end
  for d, set in pairs(PreEntry(nodes, true)) do
    for p in pairs(set) do if p.q and ns.Q[p.q] then slot(d).before[p.q] = true end end
  end
  for _, n in ipairs(nodes) do
    if n.kind == "a" and n.ins and n.q and ns.Q[n.q] then slot(n.ins).inside[n.q] = true end
  end
  return out
end

-- =====================================================================
--  Route : glouton « plus proche voisin » qui respecte les dépendances
-- =====================================================================
-- A dungeon the guide can walk you through with no quest: open now, a dungeon (a class-quest card
-- is no place, a raid is not a dungeon run).
function ns.Runnable(dkey)
  local d = ns.D[dkey]
  return d ~= nil and not d.cq and not d.raid and not (d.up and time() < d.up)
end

local SPOT_NEAR = 6   -- map units: objectives this close on one map are one visit
-- startMap: the player's map (ns.PlayerWorld's second value): the zone the route starts in
function ns.BuildRoute(sel, startPos, startMap)
  local _, cls = UnitClass("player")
  local nodes, byKey = MakeNodes(sel, cls)
  local log = ns.LogEntries()
  -- déjà faits : on les retire de la route
  local done = {}
  for _, n in ipairs(nodes) do
    if ns.NodeOK(log, n) then done[n] = true end
  end
  -- a dungeon the player asked to be guided through ("Guide me through the dungeon", WLDTDB.run)
  -- with no quest left for them still gets its walkthrough: one "run" node inside it, which
  -- MakeSteps turns into the entrance step and SplitInside into one step per boss. Only on that
  -- explicit choice: a quest route whose last quest is turned in must end, not turn into a clear.
  -- Quest state never completes it: the boss steps complete on their kills.
  for dkey in pairs(sel) do
    local left = false
    for _, qid in ipairs(ns.D[dkey] and ns.DungeonQuests(dkey, cls) or {}) do
      local q = ns.Q[qid]
      if not q.extra and not ns.IsDone(qid) then left = true break end
    end
    if WLDTDB.run and WLDTDB.run[dkey] and ns.Runnable(dkey) and not left and not byKey["r:" .. dkey] then
      local n = { kind = "r", key = "r:" .. dkey, ins = dkey, d = dkey, dk = dkey, phase = "inside", deps = {} }
      byKey[n.key] = n; table.insert(nodes, n)
    end
  end
  -- quests turned in inside count too: the summary's "ready" line and the guide agree
  local gate = PreEntry(nodes, true)
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
  -- Spots outside: objectives of the same place (one named area such as the Uldaman excavation,
  -- or the same map within SPOT_NEAR units of each other) are one visit. Every quest done there is
  -- picked up first (the town visit before the trip), when nothing done at that spot or inside a
  -- dungeon comes before its pick-up.
  local spotOf, spotTakes = {}, {}
  do
    local list = {}
    for _, n in ipairs(nodes) do if n.kind == "o" and n.loc and not done[n] then list[#list + 1] = n end end
    local id = {}
    local function find(i) while id[i] ~= i do i = id[i] end return i end
    for i = 1, #list do id[i] = i end
    for i = 1, #list do
      for j = 1, i - 1 do
        local a, b = list[i], list[j]
        local near = (a.area and a.area == b.area) or (a.loc.m == b.loc.m
          and ((a.loc.x - b.loc.x) ^ 2 + (a.loc.y - b.loc.y) ^ 2) < SPOT_NEAR * SPOT_NEAR)
        if near then id[find(i)] = find(j) end
      end
    end
    for i, n in ipairs(list) do spotOf[n] = find(i) end
    -- a prerequisite's objective there that another quest of the spot waits on (the buzzards of
    -- Badlands Reagent Run before Uldaman Reagent Run's fungus) is done on its own, earlier
    local inSpot = {}
    for n, r in pairs(spotOf) do inSpot[r] = inSpot[r] or {}; inSpot[r][n.q] = true end
    local early = {}
    local function mark(a, r, depth, seen)
      if seen[a] or depth > 40 then return end
      seen[a] = true
      for _, p in ipairs(a.deps or {}) do
        if not done[p] then
          if spotOf[p] == r then early[p] = true end
          mark(p, r, depth + 1, seen)
        end
      end
    end
    for r, qs in pairs(inSpot) do
      for q in pairs(qs) do
        local A = byKey["a:" .. tostring(q)]
        if A then mark(A, r, 0, {}) end
      end
    end
    for p in pairs(early) do spotOf[p] = nil end
    local quests = {}
    for n, r in pairs(spotOf) do quests[r] = quests[r] or {}; quests[r][n.q] = true end
    local function before(a, r, depth, seen)
      -- can a be placed before spot r is visited? (no dependency done at r or inside an instance)
      if seen[a] then return true end
      seen[a] = true
      if depth > 40 then return false end
      for _, p in ipairs(a.deps or {}) do
        if not done[p] then
          if spotOf[p] == r or InsideNode(p) then return false end
          if not before(p, r, depth + 1, seen) then return false end
        end
      end
      return true
    end
    for r, qs in pairs(quests) do
      local n = 0
      for _ in pairs(qs) do n = n + 1 end
      if n > 1 then
        local takes = {}
        for q in pairs(qs) do
          local A = byKey["a:" .. tostring(q)]
          local qq = ns.Q[q]
          if A and not done[A] and not A.ins and not (qq and qq.r and qq.r > lvl) and before(A, r, 0, {}) then
            takes[#takes + 1] = A
          end
        end
        if takes[1] then spotTakes[r] = takes end
      end
    end
  end
  local function TakesPending(n)
    local r = spotOf[n]
    local takes = r and spotTakes[r]
    if not takes then return false end
    for _, A in ipairs(takes) do if not placed[A] and not done[A] then return true end end
    return false
  end
  -- a main quest's turn-in nothing waits on: after the dungeon it serves (one trip back to town)
  local insideLeft = {}
  for _, n in ipairs(nodes) do
    if not done[n] and InsideNode(n) then local d = n.ins; insideLeft[d] = (insideLeft[d] or 0) + 1 end
  end
  local function TurnInLater(n)
    if n.kind ~= "t" or n.pre or n.ins or dependents[n] then return false end
    local d = n.dk or n.d
    return d and (insideLeft[d] or 0) > 0
  end
  -- does something done inside dungeon d wait (through its dependencies) on n?
  local function FeedsInside(n, d)
    local seen, todo = { [n] = true }, { n }
    while #todo > 0 do
      local x = table.remove(todo)
      for _, o in ipairs(dependents[x] or {}) do
        if not seen[o] and not done[o] then
          if InsideNode(o) and o.ins == d then return true end
          seen[o] = true; todo[#todo + 1] = o
        end
      end
    end
    return false
  end
  -- the dungeon whose door a line holds while it is left outside (a take, an outside objective, a
  -- prerequisite's turn-in, in the "before" phase, not held back by level), or false. A line on
  -- another continent that nothing inside waits on (a class quest's material) can wait. Nothing
  -- here changes while the route is built: worked out once per line.
  local doorOf = {}
  for _, n in ipairs(nodes) do
    local q = ns.Q[n.q]
    local d = false
    if not done[n] and not n.ins and n.phase == "before" and n.kind ~= "h" and not (n.kind == "t" and not n.pre)
      and not (n.kind == "a" and q and q.r and q.r > lvl) then
      d = NodeDungeon(n) or false
      if d then
        local a, b = NodePos(n), NodePos({ ins = d })
        if a and b and a[1] ~= b[1] and not FeedsInside(n, d) then d = false end
      end
    end
    doorOf[n] = d
  end
  -- a step of a quest in the zone around a dungeon's entrance (o.near: the Khans' gems and the
  -- Prophet in Maraudon's outer caves) is the last stop before its door: it waits for the dungeon's
  -- other outside lines (doorOf), except those that wait on it
  local downOf = {}
  local function Down(n)
    if downOf[n] then return downOf[n] end
    local seen, todo = { [n] = true }, { n }
    while #todo > 0 do
      local x = table.remove(todo)
      for _, o in ipairs(dependents[x] or {}) do if not seen[o] then seen[o] = true; todo[#todo + 1] = o end end
    end
    downOf[n] = seen
    return seen
  end
  local doorList = {}
  for _, x in ipairs(nodes) do
    local d = doorOf[x]
    if d then doorList[d] = doorList[d] or {}; table.insert(doorList[d], x) end
  end
  local function AreaWaits(n)
    if not (n.kind == "o" and n.area and n.oneObj and n.oneObj.near) then return false end
    local down
    for _, x in ipairs(doorList[n.area] or {}) do
      if x.area ~= n.area and not done[x] and not placed[x] then
        down = down or Down(n)
        if not down[x] then return true end
      end
    end
    return false
  end
  local guard = 0
  while remaining > 0 and guard < 5000 do
    guard = guard + 1
    local best, bestCost
    local ready = {}
    -- a dungeon with a line of its own still to do outside (doorOf), doable now: its door waits,
    -- however far that line is
    local outLeft = {}
    for _, n in ipairs(nodes) do
      if not done[n] and not placed[n] then
        local ok = true
        for _, p in ipairs(n.deps) do if not done[p] and not placed[p] then ok = false break end end
        if ok and n.ins and gate[n.ins] then
          for p in pairs(gate[n.ins]) do if not done[p] and not placed[p] then ok = false break end end
        end
        if ok then
          ready[#ready + 1] = n
          if doorOf[n] then outLeft[doorOf[n]] = true end
        end
      end
    end
    -- the far ones priced by the real way (TravelYards), in one search from here
    local road = {}
    if pos then
      local far, pts = {}, {}
      for _, n in ipairs(ready) do
        if not n.unknown and not (n.ins and inDungeon == n.ins) then
          local np = NodePos(n)
          if np and (np[1] ~= pos[1] or Dist(pos, np) > TRAVEL_FAR) then far[#far + 1] = n; pts[#pts + 1] = np end
        end
      end
      if #far > 0 then
        local y = ns.TravelYards(pos, pts)
        -- same continent: a flight or a boat may make it nearer, never farther (the walk's own
        -- detours stay out: the straight line keeps the spots and the check-lists as they were);
        -- another continent: the real trip instead of a flat 6000
        if y then
          for i, n in ipairs(far) do
            if y[i] then
              local np = pts[i]
              road[n] = (np[1] ~= pos[1]) and y[i] or math.min(y[i], Dist(pos, np))
            end
          end
        end
      end
    end
    for _, n in ipairs(ready) do
      local cost
      if n.unknown then cost = 0
      elseif n.ins and inDungeon == n.ins then cost = 0
      else
        local np = NodePos(n)
        cost = road[n] or ((np and pos) and Dist(pos, np)) or 50
        if n.ins then
          cost = cost + 400   -- on ne rentre dans un donjon qu'une fois tout pris autour
          -- outside work this dungeon still has (outLeft): its door waits, the zone around it too
          if outLeft[n.ins] then cost = cost + 1000000 end
          local d = ns.D[n.ins]
          local lo = d and d.lvl and d.lvl[1]
          if lo and lo > lvl then cost = cost + (lo - lvl) * 600 end
        end
      end
      -- quête trop haute pour le niveau actuel : plus tard dans la route
      local q = ns.Q[n.q]
      if n.kind == "a" and q and q.r and q.r > lvl then cost = cost + (q.r - lvl) * 800 end
      if SiblingsPending(n) then cost = cost + 5000 end
      if n.kind == "o" and TakesPending(n) then cost = cost + 50000 end   -- the pick-ups first, wherever they are
      if TurnInLater(n) then cost = cost + 4000 end
      if AreaWaits(n) then cost = cost + 20000 end
      if not bestCost or cost < bestCost then best, bestCost = n, cost end
    end
    if not best then
      -- dépendance impossible (quête bloquée) : on ajoute ce qui reste tel quel
      for _, n in ipairs(nodes) do if not done[n] and not placed[n] then table.insert(order, n); placed[n] = true; remaining = remaining - 1 end end
      break
    end
    table.insert(order, best); placed[best] = true; remaining = remaining - 1
    if InsideNode(best) and insideLeft[best.ins] then insideLeft[best.ins] = insideLeft[best.ins] - 1 end
    inDungeon = best.ins
    pos = NodePos(best) or pos
  end
  ns.PullLocal(order, done, startPos, startMap, function(n, placedAt)
    -- an objective waits for every pick-up of its spot (TakesPending), a pick-up for its level
    local q = ns.Q[n.q]
    if n.kind == "a" and q and q.r and q.r > lvl then return false end
    local r = spotOf[n]
    for _, A in ipairs(r and spotTakes[r] or {}) do
      if not done[A] and not placedAt(A) then return false end
    end
    return true
  end)
  return order, byKey
end

-- =====================================================================
--  No back-and-forth: when the route leaves a zone and comes back to it within two zones, the
--  lines of that return visit that could already be done before leaving (their dependencies are
--  placed, nothing inside a dungeon in between) are done before leaving, when that does not make
--  the trip longer. The start counts: the player's own zone (startMap) first.
-- =====================================================================
local function ZoneOfNode(n)
  if n.ins then local d = ns.D[n.ins]; return d and d.e and d.e.m end
  if n.unknown or not n.loc then return nil end
  return n.loc.m
end
local function Travel(order, from, a, b)
  local t, pos = 0, from
  for i = a, b do
    local p = NodePos(order[i])
    if p then t = t + Dist(pos, p); pos = p end
  end
  return t
end
-- order: changed in place. done: lines already done (not in the order). ok(n, placedAt): may n
-- move earlier (the caller's soft rules), placedAt(x) true when x sits before the new place.
local PULL_SLACK = 250   -- yards
function ns.PullLocal(order, done, startPos, startMap, ok)
  local passes = 0
  local changed = true
  while changed and passes < 6 do
    changed, passes = false, passes + 1
    local Z = startMap
    for i = 0, #order - 1 do
      if i > 0 then Z = ZoneOfNode(order[i]) or Z end
      local nx = order[i + 1]
      local zn = ZoneOfNode(nx)
      if Z and zn and zn ~= Z and not nx.ins then
        -- the next two zones after leaving: a return to Z there, before any dungeon line
        local runs, last, from, to = 1, zn, nil, nil
        for j = i + 2, #order do
          local n = order[j]
          if n.ins then break end
          local z = ZoneOfNode(n)
          if z and z ~= last then
            runs = runs + 1; last = z
            if runs > 3 then break end
            if z == Z then from = j end
            if from and z ~= Z then to = j - 1; break end
          end
          if from then to = j end
        end
        if from then
          local idx = {}
          for k, n in ipairs(order) do idx[n] = k end
          local moved, set = {}, {}
          local function placedAt(x) return set[x] or (idx[x] and idx[x] <= i) end
          for j = from, to do
            local n = order[j]
            -- a line with no place of its own in that visit (an objective with no known spot) goes too
            local zj = ZoneOfNode(n)
            if (zj == Z or (zj == nil and not n.ins)) and n.kind ~= "h" and n.kind ~= "r" then
              local free = true
              for _, p in ipairs(n.deps or {}) do
                if not done[p] and not placedAt(p) then free = false break end
              end
              if free and ok and not ok(n, placedAt) then free = false end
              if free then moved[#moved + 1] = n; set[n] = true end
            end
          end
          if moved[1] then
            local new = {}
            for k = 1, i do new[k] = order[k] end
            for _, n in ipairs(moved) do new[#new + 1] = n end
            for k = i + 1, #order do if not set[order[k]] then new[#new + 1] = order[k] end end
            local startP = startPos
            for k = i, 1, -1 do local p = NodePos(order[k]); if p then startP = p; break end end
            -- the rest of the trip from i (a line after the window with no place of its own, such as
            -- an objective with no known spot, is done where the window left you)
            local was = Travel(order, startP, i + 1, #order)
            local now = Travel(new, startP, i + 1, #order)
            -- a return visit costs a trip of its own: a little longer on the map is still better
            if startP and now <= was + PULL_SLACK then
              for k = 1, #new do order[k] = new[k] end
              changed = true
            end
          end
        end
      end
    end
  end
  return order
end

-- =====================================================================
--  Étapes : on regroupe les nœuds consécutifs au même endroit
-- =====================================================================
-- A step of a dungeon that comes after its last inside step (and before the next gate) is done
-- after the dungeon, whatever its actions' own phase says (a merged turn-in with an optional
-- outside quest, a lone turn-in): it never reads "before the dungeon" there. Also run on the
-- final step list (after SplitInside).
function ns.FixAfterPhases(steps)
  local lastIn = {}
  for i, st in ipairs(steps) do if st.phase == "inside" and st.dk then lastIn[st.dk] = i end end
  for dk, li in pairs(lastIn) do
    for i = li + 1, #steps do
      local st = steps[i]
      if st.gate then break end
      if st.dk == dk and st.phase == "before" then st.phase = "after" end
    end
  end
  -- after the route's last inside step with no gate later: nothing is left to prepare, every
  -- remaining step (a turn-in for a wing outside the route) is after the dungeon
  local last = 0
  for _, li in pairs(lastIn) do if li > last then last = li end end
  if last > 0 then
    local gateLater = false
    for i = last + 1, #steps do if steps[i].gate then gateLater = true; break end end
    if not gateLater then
      for i = last + 1, #steps do if steps[i].phase == "before" then steps[i].phase = "after" end end
    end
  end
end

function ns.MakeSteps(order)
  local steps = {}
  local cur
  -- outside, a done line never shares a step with an open one (a replan keeps the done ones
  -- first): the step would never read as done
  local log = ns.LogEntries()
  local function close() if cur then table.insert(steps, cur) end cur = nil end
  for _, n in ipairs(order) do
    local np = NodePos(n)
    local nok = ns.NodeOK(log, n) and true or false
    local same = false
    if cur then
      if n.ins and cur.ins == n.ins then same = true
      elseif not n.ins and not cur.ins and n.area and cur.area == n.area then same = (nok == cur.ok)
      elseif not n.ins and not cur.ins and cur.loc and n.loc and cur.loc.m == n.loc.m then
        local d = math.sqrt((cur.loc.x - n.loc.x) ^ 2 + (cur.loc.y - n.loc.y) ^ 2)
        local l = cur.last
        local d2 = (l and l.m == n.loc.m) and math.sqrt((l.x - n.loc.x) ^ 2 + (l.y - n.loc.y) ^ 2) or d
        same = (d < 6 or (n.kind == "o" and d2 < 6) or (n.npc and cur.npcs[n.npc])) and nok == cur.ok
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
      cur = { ins = n.ins, loc = n.loc, unknown = n.unknown, q = n.q, d = n.d, acts = {}, npcs = {}, pos = np, area = n.area, ok = nok }
    end
    table.insert(cur.acts, n)
    if n.loc and not n.ins then cur.last = n.loc end
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
        -- a run with no quest: the step still leads to the entrance and waits until you are in
        if n.kind == "r" then st.run = true end
        if (n.kind == "c" or n.kind == "t") and not seen[n.q] then
          local hasOutsideA = true
          for _, n2 in ipairs(visit.acts) do if n2.kind == "a" and n2.q == n.q then hasOutsideA = false end end
          if hasOutsideA then
            seen[n.q] = true
            local node = { kind = "h", q = n.q, key = "h:" .. n.q .. ":" .. i, d = n.d, pre = n.pre, deps = {} }
            -- the quest giver's spot outside: the check-list row gets a map pin and the GPS goes there
            local qq = ns.Q[n.q]; local sl = qq and qq.s
            if sl and sl.m and not sl.i and not qq.si then node.loc = sl; node.npc = sl.n end
            table.insert(st.acts, node)
          end
        end
      end
      st.checks = st.acts
      if visit then visit.checks = st.acts end
    end
  end
  -- T-91: one decision per quest (ns.ChainInRoute). A check-list quest whose prerequisites are
  -- not all turned in before its gate (by the route or by the player) is not "Required" and does
  -- not hold "Ready" back: it moves to st.locks, a greyed "Locked" line. So does a quest of the
  -- dungeon the route leaves out for its chain (ns.LockedReason), on the dungeon's first gate.
  -- A click on the line ticks it by hand (ns.GuideLockPick) and its chain joins the route.
  do
    local _, cls = UnitClass("player")
    local lvl = (UnitLevel and UnitLevel("player")) or 1
    local at = {}
    for i, st in ipairs(steps) do
      for _, n in ipairs(st.acts) do if n.key and not at[n.key] then at[n.key] = i end end
    end
    local gated = {}
    for i, st in ipairs(steps) do
      if st.gate and st.checks then
        local keep, locks, seen = {}, {}, {}
        for _, n in ipairs(st.acts) do
          local plan = n.kind == "h" and n.q and ns.ChainPlan(n.q, cls, st.gate)
          local late = false
          for _, pid in ipairs(plan and plan.left or {}) do
            -- turned in later than the visit that follows this gate, or not in the route at all
            local ti = at["t:" .. pid]
            if not ti or ti > i + 1 then late = true break end
          end
          if n.kind == "h" then seen[n.q] = true end
          if late then n.lock = true; locks[#locks + 1] = n else keep[#keep + 1] = n end
        end
        if not gated[st.gate] then
          gated[st.gate] = true
          for _, qid in ipairs(ns.DungeonQuests(st.gate, cls)) do
            local q = ns.Q[qid]
            if not seen[qid] and not q.extra and not ns.IsDone(qid) and not (WLDTDB.off and WLDTDB.off[qid])
              and not at["a:" .. qid] and not at["c:" .. qid] and not InRoute(qid, cls, lvl, st.gate) then
              local _, cause = ns.LockedReason(qid, lvl, cls, st.gate)
              if cause == "lvl" or cause == "high" or cause == "long" then
                locks[#locks + 1] = { kind = "h", q = qid, key = "h:" .. qid .. ":lock", d = st.gate, lock = true, deps = {} }
              end
            end
          end
        end
        if #locks > 0 then
          for j = #st.acts, 1, -1 do st.acts[j] = nil end
          for _, n in ipairs(keep) do st.acts[#st.acts + 1] = n end
          st.locks = locks
        end
      end
    end
  end
  -- une étape « prêt ? » sans rien à vérifier n'apporte rien : on la retire
  for i = #steps, 1, -1 do
    local st = steps[i]
    if st.gate and #st.acts == 0 and not st.run then
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
  -- the phase of each step (before / inside / after) and the route dungeon it serves
  for _, st in ipairs(steps) do ns.StepPhase(st); st.dk = ns.StepDungeon(st) end
  ns.FixAfterPhases(steps)
  return steps
end

-- =====================================================================
--  Why a step far away comes first: the next step back in the player's zone needs it
-- =====================================================================
local function StepZone(st)
  if not st then return nil end
  local g = st.gate or st.ins
  if g then local d = ns.D[g]; return d and d.e and d.e.m end
  if st.unknown then return nil end
  for _, n in ipairs(st.acts or {}) do if n.loc and n.loc.m and not n.ins then return n.loc.m end end
  return nil
end
ns.StepZone = StepZone
local function ZoneText(m)
  local ok, info = false, nil
  if m and C_Map and C_Map.GetMapInfo then ok, info = pcall(C_Map.GetMapInfo, m) end
  return ok and info and info.name or nil
end
-- step: a step of the route (steps: its list, ns.route.steps by default); here: the player's map
-- (C_Map.GetBestMapForUnit by default). When step is in another zone than the player's and the
-- route's next step back in the player's zone needs one of its lines (directly or through the
-- steps between), -> { q = quest of that line, qname, npc = who waits for it, zone = the step's
-- zone, there = the player's zone, step = index of the waiting step, text = the card's line
-- (L.WHY_FIRST: "D'abord à Feralas : il faut « X » avant de parler à Y à Tanaris.") }; else nil.
function ns.StepWhyFirst(step, steps, here)
  steps = steps or (ns.route and ns.route.steps)
  if not (step and steps) then return nil end
  local si
  for i, st in ipairs(steps) do if st == step then si = i break end end
  if not si then return nil end
  if not here and C_Map and C_Map.GetBestMapForUnit then here = C_Map.GetBestMapForUnit("player") end
  local z = StepZone(step)
  if not (z and here) or z == here then return nil end
  -- the lines of this step, then those of the steps up to the waiting one (a chain through them)
  local from = {}
  for _, n in ipairs(step.acts or {}) do from[n] = n end
  for j = si + 1, #steps do
    local st = steps[j]
    local zj = StepZone(st)
    for _, n in ipairs(st.acts or {}) do
      if not from[n] then
        for _, p in ipairs(n.deps or {}) do
          if from[p] then
            if zj == here and n.kind ~= "h" then
              local src = from[p]
              local who = (n.kind == "a" or n.kind == "t") and n.npc or nil
              local zt, ht = ZoneText(z) or "?", ZoneText(here) or "?"
              local qn = ns.QName(src.q)
              local text = who and L.WHY_FIRST and L.WHY_FIRST:format(zt, qn, who, ht)
                or (L.WHY_FIRST_DO and L.WHY_FIRST_DO:format(zt, qn, ns.QName(n.q), ht)) or nil
              return { q = src.q, qname = qn, npc = who, wq = n.q, zone = zt, there = ht, step = j, text = text }
            end
            from[n] = from[p]
            break
          end
        end
      end
    end
    -- only the first visit back in the player's zone
    if zj == here then return nil end
  end
  return nil
end

-- =====================================================================
--  Cibler et marquer : the step's mobs and NPCs, and the macro text that targets them
-- =====================================================================
-- The names a "target" macro looks for at one action (nil when there is nothing to target).
function ns.NodeTargets(n)
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
    -- an objective done outside has no target in the dungeon
    if not (n.kind == "c" and o.w and not o.ins and not o.outer) then
      for _, t in ipairs(o.t or {}) do if not seen[t] then seen[t] = true; table.insert(out, t) end end
      for _, x in ipairs(o.src or {}) do if x[1] and not seen[x[1]] and #out < 4 then seen[x[1]] = true; table.insert(out, x[1]) end end
    end
  end
  return out[1] and out or nil
end

-- The step the player is on: the first one not done (nil once the whole route is done).
function ns.CurrentStepIndex(log)
  local steps = ns.route and ns.route.steps or {}
  if #steps == 0 or not ns.IsStepDone then return nil end
  log = log or ns.LogEntries()
  for i = 1, #steps do if not ns.IsStepDone(log, i) then return i, steps[i] end end
  return nil
end

-- The text of the "target and mark" macro for a step (default: the current one): /targetexact on
-- each mob or NPC still to do there, then the skull on the target. Fits a macro (255 characters).
-- Returns the text and the names it targets.
function ns.TargetMacroText(st, log)
  log = log or ns.LogEntries()
  if st == nil then local _; _, st = ns.CurrentStepIndex(log) end
  local names, seen = {}, {}
  if st and st.bossStep and not ns.BossStepKilled(st) then
    local nm = ns.BossStepName(st)
    if nm and nm ~= "?" then seen[nm] = true; names[1] = nm end
  end
  if st then
    for _, n in ipairs(st.acts or {}) do
      if not ns.NodeOK(log, n) then
        for _, nm in ipairs(ns.NodeTargets(n) or {}) do
          if not seen[nm] then seen[nm] = true; table.insert(names, nm) end
        end
      end
    end
  end
  if #names == 0 then
    return "/run print('|cffce1918WL|r " .. L.MACRO_NONE:gsub("'", "\\'") .. "')", names
  end
  local tail = ns.MarkLine(8)
  local m = { "/cleartarget" }
  local len = #m[1] + #tail + 2
  for _, nm in ipairs(names) do
    local line = "/targetexact " .. ns.ClientNpcName(nm)
    if len + #line + 1 > 255 then break end
    table.insert(m, line); len = len + #line + 1
  end
  table.insert(m, tail)
  return table.concat(m, "\n"), names
end

-- =====================================================================
--  Partage des quêtes
-- =====================================================================
-- The guide's quests in your log that can be shared: those of the route when there is one
-- (otherwise every dungeon quest of the guide), unless the data marks them unshareable.
local function RouteQuests()
  if not (ns.route and ns.route.steps) then return nil end
  local set = {}
  for _, st in ipairs(ns.route.steps) do
    for _, n in ipairs(st.acts or {}) do if n.q then set[n.q] = true end end
    for _, n in ipairs(st.checks or {}) do if n.q then set[n.q] = true end end
  end
  return set
end
function ns.ShareList()
  local log, set, out = ns.LogEntries(), RouteQuests(), {}
  for id in pairs(log) do
    local q = ns.Q[id]
    if q and q.sh ~= false and (not set or set[id]) then out[#out + 1] = id end
  end
  table.sort(out, function(a, b) return (log[a].index or 0) < (log[b].index or 0) end)
  return out, log
end
-- Can this quest be shared (QuestLogPushQuest rules)? Asks the game; the log selection comes back.
local function Pushable(id, e)
  if CQL and CQL.IsPushableQuest then
    local ok, v = pcall(CQL.IsPushableQuest, id)
    if ok and type(v) == "boolean" then return v end
  end
  if SelectQuestLogEntry and GetQuestLogPushable and e and e.index then
    local prev = GetQuestLogSelection and GetQuestLogSelection()
    SelectQuestLogEntry(e.index)
    local ok, v = pcall(GetQuestLogPushable)
    if type(prev) == "number" and prev > 0 then SelectQuestLogEntry(prev) end
    return ok and (v == true or v == 1)
  end
  return true
end
ns.Pushable = Pushable
local function GuideQuests() return ns.Writs and ns.Writs.WP and ns.Writs.WP.GuideQuests end
-- The quests the share button pushes: the route's quests of your log the game lets you share, the
-- ones the auto-share already pushed to this group left out (all of them again when only those are
-- left: the click asks for it, a member may have joined since). -> list, how many cannot be shared
local function ShareQueue()
  local list, log = ns.ShareList()
  local GQ = GuideQuests()
  local fresh, again, skip = {}, {}, 0
  for _, id in ipairs(list) do
    if not Pushable(id, log[id]) then skip = skip + 1
    elseif GQ and GQ.Shared and GQ.Shared(id) then again[#again + 1] = id
    else fresh[#fresh + 1] = id end
  end
  return (#fresh > 0 and fresh or again), skip
end
-- How many quests of the route in your log can be shared now (the share button's count).
function ns.ShareCount()
  local q = ShareQueue()
  return #q
end
function ns.ShareQuests()
  local P = ns.Print
  if not (IsInGroup and IsInGroup()) then P(L.NOGROUP) return end
  if ns.pushBusy then P((ns.ShareWaiting and ns.ShareWaiting()) and L.SHARE_COMBAT or L.SHARE_BUSY) return end
  local queue, skip = ShareQueue()
  if #queue == 0 then P(skip > 0 and L.SHARE_NONE or L.NOSHARE) return end
  local GQ = GuideQuests()
  if GQ and GQ.MarkShared then for _, id in ipairs(queue) do GQ.MarkShared(id) end end
  local line = ns.Plural(#queue, "SHARE_GO1", "SHARE_GO", #queue)
  if skip > 0 then line = line .. " · " .. ns.Plural(skip, "SHARE_SKIP1", "SHARE_SKIP", skip) end
  -- in combat the queue waits and says « Partage des quêtes après le combat » itself
  if not (ns.ShareInCombat and ns.ShareInCombat()) then P(line) end
  if ns.PushQuests then
    -- the summary's "share all" greys out while this runs and comes back when it ends
    local function Redraw()
      if ns.Render then ns.Render() end
      if ns.RenderSummary then ns.RenderSummary() end
    end
    ns.PushQuests(queue, Redraw)
    if ns.RenderSummary then ns.RenderSummary() end
  end
end


-- =====================================================================
--  Dans le donjon : une étape par boss (ordre du journal de Naowh), une ligne par objectif.
--  « Au début » (quêtes à prendre à l'entrée) en premier, « dans tout le donjon » (butin des monstres) en dernier.
-- =====================================================================
local NKEY = { TheDeadmines = "Deadmines", TheStockade = "Stockade", HallofThanes = "HallOfThanes",
  RuinsofLordaeron = "RuinsOfLordaeron", ExcavationSiteWetlands = "ExcavationSite", CityofDalaran = "Dalaran",
  TheDrownedCity = "DrownedCity", KroldokStronghold = "Kroldok", DireMaulEast = "DireMaul", DireMaulWest = "DireMaul",
  DireMaulNorth = "DireMaul", StratholmeLiving = "Stratholme", StratholmeUndead = "Stratholme" }
-- keys that share one journal entry: only this key's wing (the journal's wing name), else the
-- bosses our walk order (ns.WALK) lists for it
local NWING = { DireMaulEast = "East", DireMaulWest = "West", DireMaulNorth = "North",
  StratholmeLiving = "Main Gate", StratholmeUndead = "Service Entrance" }
local bossCache, bossTried = {}, {}
-- mots trop courants dans les noms de boss pour servir à les reconnaître
local STOP = {}
for w in ("Keeper Stone Lord Lady Master Chief Captain Commander General Princess Prince King Queen Doctor Sergeant Overlord Highlord Ancient Elder Shadow Guard Baron Baroness Magister Archmage Instructor Lorekeeper Grand Twilight Shade Avatar Spawn Hunter Mother Quartermaster Warchief Pyroguard Golem Emperor Ambassador Houndmaster Interrogator Bloodmage Scarlet Inquisitor Arcanist Death Speaker Earthcaller Blind Razorfen Spirestone Crystal Burning Viscous Crowd Mekgineer Fallen Unbound Tidemistress Overseer Slavecrusher Handler Bossman Shaman Deathsworn Gutchewer Shadowpriest Hydromancer Cannon Archivist Postmaster Magistrate Warder Pyromancer Phalanx Plugger Screwspigot Blackbreath Darkvire Thorncurse Treasure Remains"):gmatch("%S+") do STOP[w] = true end
ns.BOSS_STOP = STOP
local function NaowhJournal()
  local N = _G.NaowhForever
  local J = type(N) == "table" and N.Journal
  return (type(J) == "table" and J.Get) and J or nil
end
-- the walk order alone (ns.WALK, our own data) when the dungeon journal is not loaded
local function WalkOnly(dkey)
  local walk = ns.WALK and ns.WALK[dkey]
  if not walk or #walk == 0 then return false end
  local out = { list = {}, idx = {}, src = "walk" }
  for i, en in ipairs(walk) do
    out.list[i] = { en = en, name = en }
    out.idx[en] = i
    for tok in en:gmatch("[^%s,]+") do
      tok = tok:gsub("'s$", "")
      if #tok > 4 and not STOP[tok] then
        local k = "#" .. tok
        if out.idx[k] == nil then out.idx[k] = i elseif out.idx[k] ~= i then out.idx[k] = false end
      end
    end
  end
  return out
end
-- Forget the cached boss orders (the dungeon journal loaded later; tests).
function ns.BossOrderReset() for k in pairs(bossCache) do bossCache[k] = nil end; for k in pairs(bossTried) do bossTried[k] = nil end end
-- The dungeon's bosses in walking order: { list = { { en, name, tip, model, npc, enc, optional,
-- rare } }, idx = { [en] = i, ["#token"] = i }, src = "naowh" | "walk" } or false.
-- NaowhForever's journal is read live when it is loaded (names, tips, models, encounter IDs);
-- without it, our own walk order (ns.WALK).
-- The macro line that would put a raid marker on the target: none. On this client SetRaidTarget is
-- protected, and a macro written by an addon carries its taint, so both a /run script and the game's
-- own /tm in it end in ADDON_ACTION_FORBIDDEN (seen in game). Our macros only target; the player
-- marks with the game's own key bindings (Interface > Key Bindings > Target markers).
function ns.MarkLine(m)
  return ""
end

function ns.BossOrder(dkey)
  local J = NaowhJournal()
  -- built before the journal was loaded: built again once it is
  if bossCache[dkey] ~= nil and (bossTried[dkey] or not J) then return bossCache[dkey] end
  local out = false
  bossTried[dkey] = J and true or nil
  if J and J.Get then
    local ok, d = pcall(J.Get, NKEY[dkey] or dkey)
    if ok and d and d.wings then
      out = { list = {}, idx = {} }
      -- a journal entry shared by several of our keys (Dire Maul, Stratholme): this key's wing only
      local wingOnly, walkSet = NWING[dkey], nil
      if wingOnly then
        local found = false
        for _, wing in ipairs(d.wings) do if wing.name == wingOnly then found = true end end
        if not found then
          -- the wing's name changed: our walk order says which bosses are this key's (none: the
          -- walk order alone, below)
          wingOnly, walkSet = nil, {}
          for _, nm in ipairs(ns.WALK and ns.WALK[dkey] or {}) do walkSet[nm] = true end
        end
      end
      for _, wing in ipairs(d.wings) do
        for _, b in ipairs((not wingOnly or wing.name == wingOnly) and wing.bosses or {}) do
          if b.npc and not b.trash and not b.chest and not (walkSet and not walkSet[b.english or b.name]) then
            local en = b.english or b.name
            local okT, tip = pcall(J.Tip or function() return nil end, b)
            table.insert(out.list, { en = en, name = b.name or en, tip = okT and type(tip) == "string" and tip or nil, model = b.model, npc = b.npc,
              enc = type(b.encounters) == "table" and b.encounters or nil, optional = b.optional and true or nil, rare = b.rare and true or nil })
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
      if #out.list == 0 then out = false else out.src = "naowh" end
    end
  end
  if not out then out = WalkOnly(dkey) end
  bossCache[dkey] = out
  return out
end

-- Live state of one objective of a quest in the log: have, need, finished (3, 8, false).
-- have/need are nil for an objective without a count; everything is nil when the game does not
-- list it. Found by name, or by position when the game lists as many objectives as the data
-- (a French client writes other names).
local function plainNum(v) return type(v) == "number" and not (issecretvalue and issecretvalue(v)) end
local function plainStr(v) return type(v) == "string" and not (issecretvalue and issecretvalue(v)) end
-- the objective's name without its count ("Plaguehound Runt slain: 3/20" -> "Plaguehound Runt")
local function Head(t)
  t = t:gsub("^%s*%d+%s*/%s*%d+%s*", ""):gsub("%s*:?%s*%d+%s*/%s*%d+%s*$", ""):gsub("%s+slain$", "")
  return t
end
-- the game's objective type for each kind of the data
local GTYPE = { kill = "monster", talk = "monster", item = "item", object = "object", event = "event" }
-- does the game's objective x agree with the data's o (type and count, when both are known)?
local function Agrees(x, o)
  local want = GTYPE[o.k or ""]
  if want and plainStr(x.type) and x.type ~= "" and x.type ~= want then return false end
  if o.c and plainNum(x.b) and x.b > 0 and x.b ~= o.c then return false end
  return true
end
-- Which of the game's objectives (list of { text, type, a, b, fin }) is the data's o (index oi of n)?
-- By exact name first, then by a unique name match, then by the unique objective of the same type
-- and count, then by position among those that agree. nil when nothing agrees: late, never wrong.
local function Pick(objs, o, oi, n)
  local oname = o.n
  if oname then
    local exact, found, nf = nil, nil, 0
    for _, x in ipairs(objs) do
      if plainStr(x.text) then
        if Head(x.text) == oname and not exact then exact = x end
        if x.text:find(oname, 1, true) then nf = nf + 1; found = found or x end
      end
    end
    if exact then return exact end
    if nf == 1 then return found end
  end
  local agree, posOK = {}, nil
  for j, x in ipairs(objs) do
    if Agrees(x, o) then
      agree[#agree + 1] = x
      if j == oi and #objs == n then posOK = x end
    end
  end
  if #agree == 1 and (posOK == agree[1] or (o.c and plainNum(agree[1].b)) or GTYPE[o.k or ""] and plainStr(agree[1].type)) then
    return agree[1]
  end
  return posOK
end
local memo, memoGen, memoLog = {}, nil, nil
local NIL = {}
-- Live state of one objective of a quest in the log: have, need, finished (3, 8, false).
-- have/need are nil for an objective without a count; everything is nil when the game does not
-- list it (or no listed objective agrees with the data: a French client writes other names).
function ns.ObjCount(log, qid, o)
  local e = log and log[qid]
  if not (e and o) then return nil end
  local q = ns.Q[qid]
  local list = q and q.o or {}
  local oi
  for k, x in ipairs(list) do if x == o then oi = k break end end
  local g = ns.PassGen and ns.PassGen()
  local mk
  if g then
    if memoGen ~= g or memoLog ~= log then memo, memoGen, memoLog = {}, g, log end
    mk = tostring(qid) .. ":" .. tostring(oi or o.n or o)
    local m = memo[mk]
    if m == NIL then return nil end
    if m then return m[1], m[2], m[3] end
  end
  local function result(a, b, fin)
    if not (plainNum(a) and plainNum(b) and b > 0) then a, b = nil, nil end
    if issecretvalue and issecretvalue(fin) then fin = nil end
    if fin == nil and a then fin = a >= b end
    if fin == nil then return nil end
    return a, b, fin and true or false
  end
  local function keep(a, b, fin)
    if mk then memo[mk] = (fin == nil) and NIL or { a, b, fin } end
    return a, b, fin
  end
  -- a step of ours the game does not list (o.have: the Khans' gems, the Amulet of Spirits): done
  -- while you carry one of its items (the item itself or what it is combined into)
  if o.have then
    local fin = ns.HasItem(o.have) and true or false
    return keep(fin and 1 or 0, 1, fin)
  end
  if CQL and CQL.GetQuestObjectives then
    local ok, objs = pcall(CQL.GetQuestObjectives, qid)
    if ok and type(objs) == "table" and #objs > 0 then
      local c = {}
      for _, x in ipairs(objs) do
        if type(x) == "table" then
          c[#c + 1] = { text = x.text, type = x.type, a = x.numFulfilled, b = x.numRequired, fin = x.finished }
        else c[#c + 1] = {} end
      end
      local pick = Pick(c, o, oi, #list)
      if pick then
        local a, b, fin = result(pick.a, pick.b, pick.fin)
        if fin ~= nil then return keep(a, b, fin) end
      end
    end
  end
  if e.index and GetNumQuestLeaderBoards and GetQuestLogLeaderBoard then
    local okN, n = pcall(GetNumQuestLeaderBoards, e.index)
    if not okN or not plainNum(n) then return keep(nil) end
    local c = {}
    for j = 1, n do
      local okT, text, typ, finished = pcall(GetQuestLogLeaderBoard, j, e.index)
      local x = {}
      if okT and plainStr(text) then
        local a, b = text:match("(%d+)%s*/%s*(%d+)")
        x = { text = text, type = typ, a = tonumber(a), b = tonumber(b), fin = finished and true or false }
      end
      c[#c + 1] = x
    end
    local pick = Pick(c, o, oi, #list)
    if pick and pick.text then return keep(result(pick.a, pick.b, pick.fin)) end
  end
  return keep(nil)
end

function ns.ObjDone(log, qid, o)
  local s = ns.State(log, qid)
  if s == "done" or s == "ready" then return true end
  if not (log and log[qid]) then return false end
  local _, _, fin = ns.ObjCount(log, qid, o)
  return fin == true
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

-- Where a quest line that no boss claims goes (ns.WALK_AT, our own data: "Boss" = at that boss,
-- "<Boss" = on the way to it), else beside the boss LibForeverData puts nearest to its NPC.
-- -> boss index (at it) or index - 0.5 (on the way to it), or nil
local function PlaceHint(dkey, bo, n)
  local at = ns.WALK_AT and ns.WALK_AT[dkey]
  if at then
    local o = n.oneObj
    for _, k in ipairs({ n.q or false, n.npc or false, o and o.n or false }) do
      local v = k and at[k]
      if v then
        local before = v:sub(1, 1) == "<"
        local i = bo.idx[before and v:sub(2) or v]
        if i then return before and (i - 0.5) or i end
      end
    end
  end
  if ns.BossNear and n.npc then
    local names = {}
    for _, b in ipairs(bo.list) do names[#names + 1] = b.en end
    local ok, en = pcall(ns.BossNear, dkey, n.npc, names)
    local i = ok and en and bo.idx[en]
    if i then return i - 0.5 end
  end
  return nil
end

-- One step per boss in walking order (every boss of the dungeon on its first visit of the route),
-- each holding the quest lines done at that boss; quest lines tied to no boss go "on the way"
-- between the right bosses (or at the start), loot from every monster in a last step.
-- full: list every boss (first visit of this dungeon in the route), else only those with quest lines.
-- A dungeon with no boss list: the step stays whole; a run keeps no run node in it (it holds no
-- quest line), so it is one "inside" step you mark done yourself.
local function Whole(st)
  local acts, run = {}, false
  for _, nd in ipairs(st.acts) do if nd.kind == "r" then run = true else acts[#acts + 1] = nd end end
  if run then st.acts = acts; st.run = true; st.inner = true end
  return { st }
end

local function SplitOne(st, full, visit)
  local bo = ns.BossOrder(st.ins)
  if not bo or #bo.list == 0 then return Whole(st) end
  local items, order = {}, 0
  local run = false
  -- a run lists every boss whatever the visit (a later visit would otherwise list none)
  for _, nd in ipairs(st.acts) do if nd.kind == "r" then full = true break end end
  for _, nd in ipairs(st.acts) do
    order = order + 1
    local q = ns.Q[nd.q] or {}
    if nd.kind == "r" then
      -- the run node holds no quest line: it only asks for every boss (full below)
      run = true
    elseif nd.kind == "c" and q.o and #q.o > 0 then
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
    if not it.boss then it.boss = PlaceHint(st.ins, bo, n) end
    -- a rare boss may not be there: a line that is not about the boss itself (its kill, its drop)
    -- is never pinned to it, it goes to "in the whole dungeon"
    local B = not (go or gq) and it.boss and it.boss == math.floor(it.boss) and bo.list[it.boss] or nil
    if B and ns.BossIsRare(st.ins, B) then
      local own = false
      for _, nm in ipairs({ n.npc or false, o and o.n or false }) do if nm and (nm == B.en or nm == B.name) then own = true end end
      for _, x in ipairs(o and o.src or {}) do if x[1] == B.en or x[1] == B.name then own = true end end
      for _, t in ipairs(o and o.t or {}) do if t == B.en or t == B.name then own = true end end
      if not own then it.boss = 999 end
    end
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
  -- groupes : 0 = au début, i - 0.5 = en route vers le boss i, 1..n = boss, 999 = dans tout le donjon
  for _, it in ipairs(items) do
    if not it.boss then
      local n = it.node
      if n.npc and byNpc[n.npc] then it.boss = byNpc[n.npc]
      elseif aGroup[n.q] == 0 then it.boss = 0
      else it.boss = 999 end
    end
  end
  -- a line never sits before a line it needs (a turn-in with no boss of its own went to the start,
  -- ahead of its objectives at a boss): it moves to the group of the last of them
  local groupOf = {}
  for _, it in ipairs(items) do
    local b = it.node.base or it.node
    if not groupOf[b] or it.boss > groupOf[b] then groupOf[b] = it.boss end
  end
  for _ = 1, 4 do
    local moved = false
    for _, it in ipairs(items) do
      local b = it.node.base or it.node
      for _, d in ipairs(b.deps or {}) do
        local g = groupOf[d]
        if g and d ~= b and g > it.boss then it.boss = g; moved = true end
      end
      if it.boss > (groupOf[b] or -1) then groupOf[b] = it.boss end
    end
    if not moved then break end
  end
  table.sort(items, function(a, b) if a.boss ~= b.boss then return a.boss < b.boss end return a.ord < b.ord end)
  local groups, byBoss, cur = {}, {}, nil
  for _, it in ipairs(items) do
    if not cur or cur.boss ~= it.boss then cur = { boss = it.boss, acts = {} }; table.insert(groups, cur); byBoss[it.boss] = cur end
    table.insert(cur.acts, it.node)
  end
  -- every boss gets its step on the dungeon's first visit, quest lines or not
  if full then
    for i = 1, #bo.list do if not byBoss[i] then local g = { boss = i, acts = {} }; byBoss[i] = g; table.insert(groups, g) end end
    table.sort(groups, function(a, b) return a.boss < b.boss end)
  end
  local anyBoss = false
  for _, g in ipairs(groups) do if g.boss >= 0.5 and g.boss < 999 then anyBoss = true end end
  if not anyBoss then return Whole(st) end
  -- "on the way, also do" (T-92): a line of the "whole dungeon" group shows on the step of the boss
  -- whose path it is on (ns.ALONG_OBJ, with where: trashWhere[node] = that entry); one picked up
  -- everywhere (GROUP_OBJ "*", or ALONG_OBJ "*") once, on the first step inside (trashAll); any
  -- other only on the "finish in the dungeon" step
  local along = ns.ALONG_OBJ and ns.ALONG_OBJ[st.ins] or {}
  local trashAt, trashAll, trashWhere = {}, {}, {}
  for _, g in ipairs(groups) do
    if g.boss == 999 then
      for _, n in ipairs(g.acts) do
        local o = n.oneObj
        local a = n.kind == "c" and ((o and o.n and along[o.n]) or along[n.q]) or nil
        local go = o and o.n and ns.GROUP_OBJ and ns.GROUP_OBJ[o.n]
        if (a and a[1] == "*") or (not a and go == "*") then
          table.insert(trashAll, n)
        elseif a and bossByName(a[1]) then
          local bi = bossByName(a[1])
          trashAt[bi] = trashAt[bi] or {}
          table.insert(trashAt[bi], n)
          trashWhere[n] = a
        end
      end
    end
  end
  local out = {}
  -- the lines on the way to boss i go on the "on the way to i" step when there is one, else on
  -- boss i's own step (never on both)
  local hasWay = {}
  for _, g in ipairs(groups) do if g.boss > 0 and g.boss < 999 and g.boss ~= math.floor(g.boss) then hasWay[math.ceil(g.boss)] = true end end
  for k, g in ipairs(groups) do
    local bi = (g.boss > 0 and g.boss < 999) and math.ceil(g.boss) or nil
    local tl = bi and (g.boss ~= math.floor(g.boss) or not hasWay[bi]) and trashAt[bi] or nil
    local s2 = { ins = st.ins, d = st.d, pos = st.pos, inner = st.inner, q = st.q, acts = g.acts, npcs = st.npcs,
      split = true, part = k, parts = #groups, bossIdx = g.boss, trash = tl, trashWhere = tl and trashWhere or nil,
      trashAll = (k == 1 and g.boss ~= 999 and #trashAll > 0) and trashAll or nil,
      phase = "inside", dk = st.ins or st.dk, bossN = #bo.list, run = run or nil }
    local whole = g.boss == math.floor(g.boss)
    local B = whole and bo.list[g.boss]
    if B then
      s2.bossName, s2.bossEn, s2.bossTip, s2.bossModel, s2.bossNpc = B.name, B.en, B.tip, B.model, B.npc
      s2.bossStep, s2.bossEnc, s2.bossFlag = true, B.enc, (ns.BossIsRare(st.ins, B) and "rare") or (B.optional and "optional") or nil
      -- one key per visit of the dungeon in the route (a second visit has its own steps), the
      -- same across replans
      s2.bkey = "b:" .. st.ins .. ":" .. B.en .. ((visit and visit > 1) and (":v" .. visit) or "")
    elseif not whole and g.boss > 0 and g.boss < 999 then
      -- on the way to the next boss
      local nx = bo.list[math.ceil(g.boss)]
      s2.way = true; s2.bossIdx = math.ceil(g.boss) - 0.5
      if nx then s2.wayName, s2.wayEn = nx.name, nx.en end
    end
    if k == 1 then s2.travel = st.travel end
    table.insert(out, s2)
  end
  return out
end

function ns.SplitInside(steps)
  local out, seen = {}, {}
  for i, st in ipairs(steps) do
    if st.ins and not st.gate and not st.split then
      -- a new visit unless the step before is inside the same dungeon
      local prev = steps[i - 1]
      local same = prev and prev.ins == st.ins and not prev.gate
      local visit = same and (seen[st.ins] or 1) or ((seen[st.ins] or 0) + 1)
      seen[st.ins] = visit
      for _, s2 in ipairs(SplitOne(st, visit == 1 and not same, visit)) do table.insert(out, s2) end
    else table.insert(out, st) end
  end
  return out
end

-- =====================================================================
--  Boss steps: killed during this run, optional, loot, the name a target macro looks for
-- =====================================================================
-- the boss's names (English, the journal's, this client's) and NPC ids
function ns.BossStepNames(st)
  local names = { st.bossEn, st.bossName }
  if ns.BossLocalName then
    local ok, nm = pcall(ns.BossLocalName, st.ins, st.bossEn)
    if ok and nm then names[#names + 1] = nm end
  end
  local ids = {}
  if st.bossNpc then ids[1] = st.bossNpc end
  if ns.BossNpcIds then
    local ok, l = pcall(ns.BossNpcIds, st.ins, st.bossEn)
    if ok and type(l) == "table" then for _, x in ipairs(l) do ids[#ids + 1] = x end end
  end
  return names, ids
end
-- Was this step's boss killed during the current run of the dungeon?
function ns.BossStepKilled(st)
  if not (st and st.bossStep and ns.BossKilled) then return false end
  local names, ids = ns.BossStepNames(st)
  local ok, v = pcall(ns.BossKilled, st.ins, names, ids, st.bossEnc)
  return ok and v == true
end
-- The boss's name as this client writes it
function ns.BossStepName(st)
  if not st then return "?" end
  local nm = st.bossName
  if nm == st.bossEn and ns.BossLocalName then
    local ok, l = pcall(ns.BossLocalName, st.ins, st.bossEn)
    if ok and l then nm = l end
  end
  return nm or st.bossEn or "?"
end
-- Loot of this boss that matters to you: { { id, name, link, icon, quest, up, text, bis } }. Gear
-- shows when WL Helper's gear check calls it an upgrade or Naowh's BiS list ranks it 1 or 2 for
-- your spec (ns.BisBadge, bis = that rank); quest items always (unless a quest line of the step
-- already names them). A BiS you already own (worn, bags, bank) does not count. Quest items
-- first, then BiS (rank 1, then 2), the rest in the boss's loot order.
-- you already own this item (worn, in your bags or bank): a BiS you have is no longer loot for you
local function OwnsItem(id)
  if not id then return false end
  local function plain(v) return not (issecretvalue and issecretvalue(v)) end
  if ns.IsEquipped(id) then return true end
  local count = (C_Item and C_Item.GetItemCount) or GetItemCount
  if count then
    local ok, n = pcall(count, id, true)
    if ok and type(n) == "number" and plain(n) and n > 0 then return true end
  end
  return false
end
ns.OwnsItem = OwnsItem
function ns.BossStepLoot(st)
  local out = {}
  if not (st and st.bossStep and ns.BossLoot) then return out end
  local okL, list = pcall(ns.BossLoot, st.ins, st.bossEn, st.bossNpc and { st.bossNpc } or nil)
  if not (okL and type(list) == "table") then return out end
  local named = {}
  for _, n in ipairs(st.acts or {}) do local o = n.oneObj; if o and o.n then named[o.n] = true end end
  local WP = ns.Writs and ns.Writs.WP
  for _, it in ipairs(list) do
    local name, link, icon = it.name, nil, nil
    if it.id then
      local ok, n2, l2, _, _, _, _, _, _, _, tex = pcall(ns.ItemInfo, it.id)
      if ok then
        if type(n2) == "string" and not (issecretvalue and issecretvalue(n2)) then name = n2 end
        if type(l2) == "string" and not (issecretvalue and issecretvalue(l2)) then link = l2 end
        icon = tex
      end
    end
    local bis
    if ns.BisBadge and (link or it.id) then
      local okB, rk = pcall(ns.BisBadge, link or it.id)
      if okB and (rk == 1 or rk == 2) and not OwnsItem(it.id) then bis = rk end
    end
    if it.quest then
      if not (it.name and named[it.name]) then out[#out + 1] = { id = it.id, name = name or ("#" .. tostring(it.id)), link = link, icon = icon, quest = true, bis = bis } end
    else
      local up, text
      if link and WP and WP.UpgradeCheck then
        local ok, r = pcall(WP.UpgradeCheck, link)
        if ok and type(r) == "table" and r.up then up, text = true, r.text end
      end
      if up or bis then
        out[#out + 1] = { id = it.id, name = name or ("#" .. tostring(it.id)), link = link, icon = icon, up = up, text = text, bis = bis, chance = it.chance }
      end
    end
  end
  -- with a BiS here: quest items first (they block the quest, never pushed out of the 3 lines),
  -- then BiS rank 1, rank 2, then the rest, each group in loot order (a stable sort). No BiS:
  -- the boss's loot order, as before.
  local anyBis = false
  for _, e in ipairs(out) do if e.bis then anyBis = true end end
  if not anyBis then return out end
  for i, e in ipairs(out) do e._k = i end
  local function key(e) return e.quest and 0 or e.bis or 3 end
  table.sort(out, function(a, b)
    local ra, rb = key(a), key(b)
    if ra ~= rb then return ra < rb end
    return a._k < b._k
  end)
  for _, e in ipairs(out) do e._k = nil end
  return out
end
-- A rare boss (not always there): the journal says so, or our own tactic starts "Rare".
function ns.BossIsRare(dkey, B)
  if not B then return false end
  if B.rare then return true end
  local t = ns.BOSS_NOTES and ns.BOSS_NOTES[dkey]
  local e = t and B.en and t[B.en]
  local l = type(e) == "table" and type(e[1]) == "table" and e[1][2] or nil
  return type(l) == "string" and l:match("^Rare[,:.]") ~= nil
end

-- Optional: nothing for you at this boss (no open quest line, no upgrade, no quest item).
function ns.BossStepOptional(st, log)
  if not (st and st.bossStep) then return false end
  -- a run with no quest: the bosses are the point, only the ones the data calls optional are
  if st.run then return st.bossFlag == "optional" end
  log = log or ns.LogEntries()
  for _, n in ipairs(st.acts or {}) do if not ns.NodeOK(log, n) then return false end end
  return #ns.BossStepLoot(st) == 0
end

-- =====================================================================
--  What the game itself knows about a quest in the log (its objectives, its texts), and the
--  note ForeverDungeonJournal keeps for it when that addon is loaded. Our data can be thin
--  (no objectives, no place): these fill the card and the tooltip. Everything is guarded:
--  secret values and missing functions give nothing, never an error.
-- =====================================================================
-- -> list of { text = "Ancient Mana Crystal: 0/8", fin = false } for a quest in the log, or {}
function ns.GameObjectives(qid, log)
  local out = {}
  log = log or ns.LogEntries()
  local e = qid and log and log[qid]
  if not e then return out end
  if CQL and CQL.GetQuestObjectives then
    local ok, objs = pcall(CQL.GetQuestObjectives, qid)
    if ok and type(objs) == "table" then
      for _, x in ipairs(objs) do
        if type(x) == "table" and plainStr(x.text) and x.text ~= "" then
          local fin = x.finished
          if issecretvalue and issecretvalue(fin) then fin = nil end
          out[#out + 1] = { text = x.text, fin = fin and true or false }
        end
      end
      if #out > 0 then return out end
    end
  end
  if e.index and GetNumQuestLeaderBoards and GetQuestLogLeaderBoard then
    local okN, n = pcall(GetNumQuestLeaderBoards, e.index)
    if okN and plainNum(n) then
      for j = 1, n do
        local okT, text, _, finished = pcall(GetQuestLogLeaderBoard, j, e.index)
        if okT and plainStr(text) and text ~= "" then
          if issecretvalue and issecretvalue(finished) then finished = nil end
          out[#out + 1] = { text = text, fin = finished and true or false }
        end
      end
    end
  end
  return out
end

-- -> description, objective text of a quest in the log (the game's own words), or nil
local textMemo = {}
function ns.GameQuestText(qid, log)
  log = log or ns.LogEntries()
  local e = qid and log and log[qid]
  if not (e and e.index) then return nil end
  local m = textMemo[qid]
  if m and m.index == e.index then return m.desc, m.obj end
  local desc, obj
  local get = GetQuestLogQuestText
  if get then
    -- newer clients take the log index; older ones read the selected entry: select it, read,
    -- then give the selection back
    -- a client that ignores the index returns the SELECTED entry's text: trust the indexed call
    -- only when that entry is this quest (or when there is no way to select one)
    local canSel = SelectQuestLogEntry and GetQuestLogSelection
    local okC, cur
    if GetQuestLogSelection then okC, cur = pcall(GetQuestLogSelection) end
    if not canSel or (okC and plainNum(cur) and cur == e.index) then
      local ok, d, o = pcall(get, e.index)
      if ok and plainStr(d) and d ~= "" then desc, obj = d, o end
    end
    if not desc and canSel then
      local okS, was = pcall(GetQuestLogSelection)
      if pcall(SelectQuestLogEntry, e.index) then
        local ok2, d2, o2 = pcall(get)
        if ok2 and plainStr(d2) and d2 ~= "" then desc, obj = d2, o2 end
        if okS and plainNum(was) then pcall(SelectQuestLogEntry, was) end
      end
    end
  end
  if not plainStr(obj) or obj == "" then obj = nil end
  if desc then textMemo[qid] = { index = e.index, desc = desc, obj = obj } end
  return desc, obj
end

-- The note ForeverDungeonJournal keeps for a quest (its dungeon quests and its prerequisite
-- pages), read live from its tables when it is loaded. Its text is never copied into our data:
-- the card shows it with a credit line. -> note text or nil
local fdjIndex, fdjSrc
function ns.FDJNote(qid)
  if not qid then return nil end
  if not (ns.IsLoaded and ns.IsLoaded("ForeverDungeonJournal")) then return nil end
  local FDJ = _G.ForeverDungeonJournal_NS
  if type(FDJ) ~= "table" then return nil end
  local note
  local det = type(FDJ.QUEST_PREREQ_DETAILS) == "table" and FDJ.QUEST_PREREQ_DETAILS[qid]
  if type(det) == "table" and type(det.note) == "string" and det.note ~= "" then note = det.note end
  if not note and type(FDJ.DB) == "table" then
    if fdjSrc ~= FDJ.DB then
      fdjSrc, fdjIndex = FDJ.DB, {}
      for _, dg in pairs(FDJ.DB) do
        if type(dg) == "table" and type(dg.quests) == "table" then
          for _, qq in ipairs(dg.quests) do
            if type(qq) == "table" and qq.id and type(qq.note) == "string" and qq.note ~= "" and not fdjIndex[qq.id] then
              fdjIndex[qq.id] = qq.note
            end
          end
        end
      end
    end
    note = fdjIndex[qid]
  end
  if not note then return nil end
  if type(FDJ.LocalizeQuestField) == "function" then
    local ok, t = pcall(FDJ.LocalizeQuestField, qid, "note", note)
    if ok and type(t) == "string" and t ~= "" then note = t end
  end
  return note
end

-- =====================================================================
--  NPCs that walk a path: s.sp / f.sp = { {x, y}, ... } in path order, on the point's map (a third
--  value is another map, for a path that crosses a zone border). The point's own x, y is the spot
--  nearest the middle of the path; the GPS (Writs/Route.lua) goes to the spot nearest to you, then on
--  to the next one each time you reach a spot, round the path again after the last one.
-- =====================================================================
-- The spots of a quest's giver (which = "s", the default) or turn-in ("f") as { {m, x, y}, ... },
-- and the NPC's name; nil when that NPC stands still. q: a quest id or a quest table.
function ns.PatrolSpots(q, which)
  if type(q) == "number" then q = ns.Q and ns.Q[q] end
  local p = type(q) == "table" and q[which or "s"]
  if type(p) ~= "table" or type(p.sp) ~= "table" or not p.sp[1] or not p.m then return nil end
  local out = {}
  for i, s in ipairs(p.sp) do out[i] = { s[3] or p.m, s[1], s[2] } end
  return out, p.n
end

-- The spots of the patrolling NPC whose marker is (m, x, y), or nil: what the GPS asks for a point.
local patrolAt
function ns.PatrolAt(m, x, y)
  if not (m and x and y) then return nil end
  if not patrolAt then
    patrolAt = {}
    for _, q in pairs(ns.Q or {}) do
      for _, w in ipairs({ "s", "f" }) do
        local p = q[w]
        if type(p) == "table" and p.sp and p.m and p.x and p.y then
          local k = p.m .. ":" .. p.x .. ":" .. p.y
          if not patrolAt[k] then patrolAt[k] = { ns.PatrolSpots(q, w) } end
        end
      end
    end
  end
  local e = patrolAt[m .. ":" .. x .. ":" .. y]
  if e then return e[1], e[2] end
  return nil
end

-- The spot nearest to a world position ({cont, x, y}, as ns.World gives); 1 when it is not known.
function ns.PatrolNearest(spots, here)
  if not (spots and spots[1]) then return nil end
  if not here then return 1 end
  local best, bd
  for i, s in ipairs(spots) do
    local w = ns.World(s[1], s[2], s[3])
    if w then
      local d = Dist(here, w)
      if not bd or d < bd then best, bd = i, d end
    end
  end
  return best or 1
end

-- The spot after idx along the path, back to the first after the last.
function ns.PatrolNext(spots, idx)
  local n = spots and #spots or 0
  if n == 0 then return nil end
  return ((idx or 0) % n) + 1
end

-- True when a world position stands within `within` yards (15 by default) of spot idx.
function ns.PatrolReached(spots, idx, here, within)
  local s = spots and idx and spots[idx]
  if not (s and here) then return false end
  local w = ns.World(s[1], s[2], s[3])
  if not w or w[1] ~= here[1] then return false end
  return Dist(here, w) <= (within or 15)
end

-- =====================================================================
--  Objectives spread over an area (a ring of spawns round an island, several camps, a wide field):
--  o.area = { m = map, pts = hull or { hull, hull, ... } (one per camp, {x, y} in percent),
--  sp = { {x, y, camp}, ... } (spawns spread over each camp), note = "..." (optional) }, set in
--  Curated.lua from the real spawns. The GPS goes to the spawn nearest to you in the camp nearest to
--  you (inside a camp counts as 0), picked again once you moved AREA_MOVE yards; within AREA_MARGIN
--  yards of a camp you are "in the zone" (Writs/WorldPin.lua says so instead of a distance).
--  Drawn on the maps by Writs/Patrol.lua (Zones), for the current step's objectives.
-- =====================================================================
local AREA_MOVE, AREA_MARGIN = 30, 25
-- yards: in a camp this near a spawn, the GPS spot is you (AreaPick). Mobs wander and the spawns of a
-- wide camp are far apart (Spitelash Sirens, Azshara: the nearest spawn 100 yd away while you stand among
-- them; report "you send me into the circle when I am in it already"). An area with a hole no mob
-- reaches (the Sunken Temple's island in its pool, 1424) says its own: a.near.
local AREA_NEAR_SPAWN = 120
ns.AREA_NEAR_SPAWN = AREA_NEAR_SPAWN
ns.AREA_MOVE, ns.AREA_MARGIN = AREA_MOVE, AREA_MARGIN

-- The camps of an area: { { {x, y}, ... }, ... } (one hull or a list of hulls in the data).
function ns.AreaPolys(a)
  if type(a) ~= "table" or type(a.pts) ~= "table" or type(a.pts[1]) ~= "table" then return {} end
  if type(a.pts[1][1]) == "number" then return { a.pts } end
  return a.pts
end

-- The area of a route line (an objective whose point is on the area's map), or nil.
function ns.AreaOf(n)
  if type(n) ~= "table" or n.kind ~= "o" then return nil end
  local o = n.oneObj or n.obj
  local a = type(o) == "table" and o.area
  if type(a) == "table" and a.m and type(n.loc) == "table" and n.loc.m == a.m then return a end
  return nil
end

local areaWorld = setmetatable({}, { __mode = "k" })
-- A world position back to percent on map m (ns.World is linear in x and y on one map): nil when
-- the map cannot be read.
local mapBasis = {}
function ns.WorldToMap(m, w)
  if not (m and type(w) == "table" and w[2] and w[3]) then return nil end
  local B = mapBasis[m]
  if B == nil then
    local o, ex, ey = ns.World(m, 0, 0), ns.World(m, 100, 0), ns.World(m, 0, 100)
    if o and ex and ey and o[1] == ex[1] and o[1] == ey[1] then
      local a11, a21 = (ex[2] - o[2]) / 100, (ex[3] - o[3]) / 100
      local a12, a22 = (ey[2] - o[2]) / 100, (ey[3] - o[3]) / 100
      local det = a11 * a22 - a12 * a21
      B = math.abs(det) > 1e-9 and { o = o, a11 = a11, a12 = a12, a21 = a21, a22 = a22, det = det } or false
    else B = false end
    mapBasis[m] = B
  end
  if not B or w[1] ~= B.o[1] then return nil end
  local dx, dy = w[2] - B.o[2], w[3] - B.o[3]
  local x = (B.a22 * dx - B.a12 * dy) / B.det
  local y = (B.a11 * dy - B.a21 * dx) / B.det
  return x, y
end

-- The area in world yards: { cont, polys = { { {wx, wy}, ... }, ... }, sp = { {wx, wy, camp, x, y}, ... } }.
-- A map not readable yet is asked again later (nothing kept); camps on two continents: no area.
local function AreaWorld(a)
  local w = areaWorld[a]
  if w ~= nil then return w or nil end
  local polys, cont = {}, nil
  for k, poly in ipairs(ns.AreaPolys(a)) do
    local wp = {}
    for _, p in ipairs(poly) do
      local v = ns.World(a.m, p[1], p[2])
      if not v then return nil end
      if cont and v[1] ~= cont then areaWorld[a] = false; return nil end
      cont = v[1]
      wp[#wp + 1] = { v[2], v[3] }
    end
    polys[k] = wp
  end
  if not cont then return nil end
  local sp = {}
  for _, s in ipairs(a.sp or {}) do
    local v = ns.World(a.m, s[1], s[2])
    if v and v[1] == cont then sp[#sp + 1] = { v[2], v[3], s[3] or 1, s[1], s[2] } end
  end
  w = { cont = cont, polys = polys, sp = sp }
  areaWorld[a] = w
  return w
end
ns.AreaWorld = AreaWorld

local function SegDist(px, py, ax, ay, bx, by)
  local dx, dy = bx - ax, by - ay
  local l2 = dx * dx + dy * dy
  local t = l2 > 0 and math.max(0, math.min(1, ((px - ax) * dx + (py - ay) * dy) / l2)) or 0
  local ex, ey = ax + t * dx - px, ay + t * dy - py
  return math.sqrt(ex * ex + ey * ey)
end
-- Distance from (x, y) to a camp (same units): 0 inside it, else to its edge (a camp of 1 or 2
-- spawns: to them).
local function PolyDist(poly, x, y)
  local n = #poly
  if n == 0 then return math.huge end
  if n == 1 then return math.sqrt((poly[1][1] - x) ^ 2 + (poly[1][2] - y) ^ 2) end
  if n >= 3 then
    local inside, j = false, n
    for i = 1, n do
      local xi, yi, xj, yj = poly[i][1], poly[i][2], poly[j][1], poly[j][2]
      if ((yi > y) ~= (yj > y)) and (x < (xj - xi) * (y - yi) / (yj - yi) + xi) then inside = not inside end
      j = i
    end
    if inside then return 0 end
  end
  local best = math.huge
  for i = 1, n do
    local a, b = poly[i], poly[i % n + 1]
    local d = SegDist(x, y, a[1], a[2], b[1], b[2])
    if d < best then best = d end
  end
  return best
end
ns.AreaPolyDist = PolyDist

-- Yards from a world position ({cont, x, y}) to the area (0 inside a camp), and that camp's index;
-- nil on another continent or when the map is not readable.
function ns.AreaDist(a, here)
  local w = AreaWorld(a)
  if not (w and type(here) == "table" and here[1] == w.cont) then return nil end
  local best, bk
  for k, poly in ipairs(w.polys) do
    local d = PolyDist(poly, here[2], here[3])
    if not best or d < best then best, bk = d, k end
  end
  return best, bk
end

-- True when the world position stands in the area (within `margin` yards of a camp, AREA_MARGIN by default).
function ns.AreaInside(a, here, margin)
  local d = ns.AreaDist(a, here)
  return d ~= nil and d <= (margin or AREA_MARGIN)
end

-- The spot the GPS goes to: the spawn nearest to `here` in the camp nearest to `here` -> m, x, y, camp
-- (nil without a position on the area's continent). `prefer`: the camp picked before, kept until
-- another camp is AREA_MOVE yards nearer (no flip-flop between two camps about as far).
function ns.AreaPick(a, here, prefer)
  local w = AreaWorld(a)
  if not (w and type(here) == "table" and here[1] == w.cont) then return nil end
  local campD = {}
  for k, poly in ipairs(w.polys) do campD[k] = PolyDist(poly, here[2], here[3]) end
  -- standing in a camp, its edge (spawns on the outline, or a corner) is only a walk out of it
  -- (report: "I am in the zone, why send me out"): the spot is where you stand, the arrow says you
  -- are there; the mobs are around you
  -- (with spawns listed, only near one of them: the outline is their hull, it can cover an island
  -- with no mob, writ/zones_test 1424)
  for k, d in ipairs(campD) do
    if d <= 0.5 then
      local near, any, under, ud = false, false, nil, nil
      for _, s in ipairs(w.sp) do
        if s[3] == k then
          any = true
          local d2 = (s[1] - here[2]) ^ 2 + (s[2] - here[3]) ^ 2
          local r = tonumber(a.near) or AREA_NEAR_SPAWN
          if d2 <= r * r then near = true end
          if d2 <= 25 and (not ud or d2 < ud) then under, ud = s, d2 end
        end
      end
      -- a spawn under your feet (5 yards): that spawn, as it is written
      if under then return a.m, under[4], under[5], k, true end
      if near or not any then
        local mx, my = ns.WorldToMap(a.m, here)
        if mx then return a.m, mx, my, k, true end
      end
    end
  end
  if prefer and campD[prefer] then campD[prefer] = math.max(0, campD[prefer] - AREA_MOVE) end
  local best, bc, bd
  for _, s in ipairs(w.sp) do
    local c = campD[s[3]] or math.huge
    local d = math.sqrt((s[1] - here[2]) ^ 2 + (s[2] - here[3]) ^ 2)
    if not best or c < bc - 1e-6 or (math.abs(c - bc) <= 1e-6 and d < bd) then best, bc, bd = s, c, d end
  end
  if best then return a.m, best[4], best[5], best[3] end
  -- no spawn listed: the nearest corner of the nearest camp
  local polys, bk = ns.AreaPolys(a), nil
  for k in ipairs(w.polys) do if not bk or campD[k] < campD[bk] then bk = k end end

  local poly, wp = bk and polys[bk], bk and w.polys[bk]
  if not (poly and wp) then return nil end
  local bi
  for i, p in ipairs(wp) do
    local d = (p[1] - here[2]) ^ 2 + (p[2] - here[3]) ^ 2
    if not bd or d < bd then bi, bd = i, d end
  end
  return a.m, poly[bi][1], poly[bi][2], bk
end

-- AreaPick with a memory: the same spot until you moved AREA_MOVE yards from where it was picked
-- (here: a world position, else yours). -> m, x, y | nil (no position yet and nothing picked).
local follow = setmetatable({}, { __mode = "k" })
function ns.AreaFollow(a, here)
  if type(a) ~= "table" then return nil end
  if here == nil and ns.PlayerWorld then
    local ok, h = pcall(ns.PlayerWorld)
    here = ok and type(h) == "table" and h or nil
  end
  local c = follow[a]
  if c and not c.inside and (not here or (c.here[1] == here[1] and Dist(c.here, here) <= AREA_MOVE)) then return c.m, c.x, c.y end
  if not here then return c and c.m, c and c.x, c and c.y end
  local m, x, y, camp, inside = ns.AreaPick(a, here, c and c.camp)
  if not m then
    if c then return c.m, c.x, c.y end
    return nil
  end
  -- in the camp the spot is you: asked again on every look, never kept behind you
  follow[a] = { here = { here[1], here[2], here[3] }, m = m, x = x, y = y, camp = camp, inside = inside }
  return m, x, y
end
function ns.AreaFollowReset() for k in pairs(follow) do follow[k] = nil end end

-- The area whose spot (a spawn of sp, or the objective's own point) is (m, x, y), or nil: what the
-- in-world marker asks for the GPS's point.
local areaList
function ns.AreaAt(m, x, y)
  if not (m and x and y) then return nil end
  if not areaList then
    areaList = {}
    for _, q in pairs(ns.Q or {}) do
      for _, o in ipairs(type(q) == "table" and q.o or {}) do
        if type(o) == "table" and type(o.area) == "table" and o.area.m then areaList[#areaList + 1] = { o.area, o.w } end
      end
    end
  end
  local function near(px, py) return math.abs(px - x) <= 0.06 and math.abs(py - y) <= 0.06 end
  for _, e in ipairs(areaList) do
    local a, w = e[1], e[2]
    if a.m == m then
      if type(w) == "table" and w.x and w.y and near(w.x, w.y) then return a end
      for _, s in ipairs(a.sp or {}) do if near(s[1], s[2]) then return a end end
    end
  end
  return nil
end
