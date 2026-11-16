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
      INST_IN_TRACK = "(clic sur le suivi pour ouvrir le guide)",
      INST_OFFER_TRACK = "Tu es dans %s : ouvre le guide pour l'ajouter à ta route.",
      LOCK_PRE = "il faut d'abord « %s » (%s)",
      LOCK_LVL = "niveau %d requis",
      LOCK_HIGH = "la chaîne monte au niveau %d",
      LOCK_LONG = "chaîne longue : %d quêtes avant",
      LOCK_OTHERDG = "elle passe par %s",
      LOCK_BAD = "chaîne impossible pour ce personnage",
    },
    en = {
      SHARE_GO1 = "Sharing 1 quest with the group", SHARE_GO = "Sharing %d quests with the group",
      SHARE_SKIP1 = "%d cannot be shared", SHARE_SKIP = "%d cannot be shared",
      SHARE_BUSY = "Already sharing: wait until it ends before sharing again.",
      SHARE_NONE = "No quest of your log for this route can be shared.",
      INST_IN_TRACK = "(click the tracker to open the guide)",
      INST_OFFER_TRACK = "You are in %s: open the guide to add it to your route.",
      LOCK_PRE = "first needs \"%s\" (%s)",
      LOCK_LVL = "level %d required",
      LOCK_HIGH = "the chain goes up to level %d",
      LOCK_LONG = "long chain: %d quests before",
      LOCK_OTHERDG = "it goes through %s",
      LOCK_BAD = "chain this character cannot do",
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
-- skill line ids (7th return of GetProfessionInfo)
local PROF_LINE = { MINING = 186, BLACKSMITHING = 164, ENGINEERING = 202, LEATHERWORKING = 165, TAILORING = 197,
  ALCHEMY = 171, ENCHANTING = 333, HERBALISM = 182, SKINNING = 393 }
function ns.HasProf(code)
  -- Forever (modern engine): no skill list, professions come from GetProfessions
  if GetProfessions and GetProfessionInfo then
    local list = { pcall(GetProfessions) }
    if list[1] then
      local want, names = PROF_LINE[code], PROF[code]
      if not want then return true end
      for i = 2, 7 do
        local idx = list[i]
        if idx then
          local ok, nm, _, _, _, _, line = pcall(GetProfessionInfo, idx)
          if ok and (line == want or (nm and names and (nm == names[1] or nm == names[2]))) then return true end
        end
      end
      return false
    end
  end
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
      if not (pq and FactionOK(pq.fa) and ClassOK(pq.c, cls) and RaceOK(pq.race)) then return nil end
      if not FullChain(pid, cls, out, seen, depth + 1) then return nil end
      out[#out + 1] = pid
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
  for _, pid in ipairs(chain) do
    if not ns.IsDone(pid) then
      local pq = ns.Q[pid] or {}
      plan.left[#plan.left + 1] = pid
      if log[pid] or (onQ and onQ(pid)) then plan.started = true end
      if not plan.first then plan.first = pid; plan.need = pq.r or 0 end
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
-- Can the chain go into the route now? -> ok, cause ("lvl" | "high" | "long" | "bad")
local function ChainOK(plan, lvl)
  if not plan then return true end
  if plan.bad then return false, "bad" end
  if #plan.left == 0 or plan.started then return true end
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
          area = o.outer and OuterNear(o, q.od or home) and NotedOutside(q) and (q.od or home) or nil }))
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
    elseif real == 0 and not inside and (isPre or q.noin) and q.oe and not ns.TalkQuest(q) then
      -- nothing but the quest's text ("Acquire the Mana Sieve ... collect Ancient Mana Crystals"):
      -- one "do the objectives" step that ends when the game says the quest is complete
      real = 1
      table.insert(outs, add({ kind = "o", q = qid, sub = 1, unknown = true, npc = ns.QName(qid), obj = { k = "text", n = q.oe, unk = true },
        noLoc = true, mapHint = q.s and not q.s.i and q.s.m or nil, d = home, pre = isPre, deps = { A } }))
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
      if not (WLDTDB.off and WLDTDB.off[qid]) and not q.extra and InRoute(qid, cls, lvl, dkey) then
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
function ns.BuildRoute(sel, startPos)
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
    for _, n in ipairs(ready) do
      local cost
      if n.unknown then cost = 0
      elseif n.ins and inDungeon == n.ins then cost = 0
      else
        local np = NodePos(n)
        cost = (np and pos) and Dist(pos, np) or 50
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
  return order, byKey
end

-- =====================================================================
--  Étapes : on regroupe les nœuds consécutifs au même endroit
-- =====================================================================
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
  return steps
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
    local line = "/targetexact " .. nm
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
  if ns.pushBusy then P(L.SHARE_BUSY) return end
  local queue, skip = ShareQueue()
  if #queue == 0 then P(skip > 0 and L.SHARE_NONE or L.NOSHARE) return end
  local GQ = GuideQuests()
  if GQ and GQ.MarkShared then for _, id in ipairs(queue) do GQ.MarkShared(id) end end
  local line = ns.Plural(#queue, "SHARE_GO1", "SHARE_GO", #queue)
  if skip > 0 then line = line .. " · " .. ns.Plural(skip, "SHARE_SKIP1", "SHARE_SKIP", skip) end
  P(line)
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
  local trash = {}
  for _, g in ipairs(groups) do
    if g.boss == 999 then for _, n in ipairs(g.acts) do table.insert(trash, n) end end
  end
  local out = {}
  for k, g in ipairs(groups) do
    local s2 = { ins = st.ins, d = st.d, pos = st.pos, inner = st.inner, q = st.q, acts = g.acts, npcs = st.npcs,
      split = true, part = k, parts = #groups, bossIdx = g.boss, trash = (g.boss ~= 999) and trash or nil,
      phase = "inside", dk = st.ins or st.dk, bossN = #bo.list, run = run or nil }
    local whole = g.boss == math.floor(g.boss)
    local B = whole and bo.list[g.boss]
    if B then
      s2.bossName, s2.bossEn, s2.bossTip, s2.bossModel, s2.bossNpc = B.name, B.en, B.tip, B.model, B.npc
      s2.bossStep, s2.bossEnc, s2.bossFlag = true, B.enc, (B.rare and "rare") or (B.optional and "optional") or nil
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
        out[#out + 1] = { id = it.id, name = name or ("#" .. tostring(it.id)), link = link, icon = icon, up = up, text = text, bis = bis }
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
