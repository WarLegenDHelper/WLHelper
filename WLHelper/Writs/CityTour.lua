-- Writs/CityTour.lua: the city tour. When you reach a capital of your faction, a small card lists
-- what there is to do there, in walking order, each stop with a GPS button and ticked by itself:
--   new spells at your class trainer (you reached a new even level since your last visit, or a
--     spell you could not pay for is now affordable: read at the trainer itself, no spell list),
--   mail waiting (HasNewMail), repairs (an equipped item under 35 % durability),
--   quests of your log ready to turn in to someone in this city (the guide's data, then
--     LibForeverData when it is loaded),
--   reagents to take out of the bank for an accepted guild order (Orders), the Writs' auction
--     house purchases (only the writs you hold or ticked yourself: never the automatic plan),
--   arrows or bullets for a hunter running low.
-- Quiet: the card shows only when something is to do; closed, it stays closed for this visit.
--
-- The places (bankers, auctioneers, mailboxes, armor and ammo merchants, class trainers) come from
-- LibForeverData's spawn tables, read offline (uiMap percent). A place we do not know gives a stop
-- with no GPS button: nothing here is guessed. Armor merchants are the repair stops: the data has
-- no repair flag, but the game's armor merchants repair.
local ADDON, root = ...
root.Writs = root.Writs or {}
local ns = root.Writs
local WP = ns.WP
local L = ns.L
local S = ns.S
local C = S.C
local F = root.F

local CT = {}
WP.CityTour = CT

ns.AddEnglish({
    ["Tournée en ville"] = "City tour",
    ["Lancer la tournée"] = "Start the tour",
    ["Arrêter la tournée"] = "Stop the tour",
    ["Le GPS te mène d'une étape à l'autre, la plus proche d'abord. Chaque étape se coche toute seule."] =
        "The GPS takes you from one stop to the next, nearest first. Each stop is ticked off when you reach it.",
    ["Le GPS s'arrête ; les étapes restent dans la liste."] = "The GPS stops; the stops stay in the list.",
    ["1 chose à faire ici, dans l'ordre du chemin."] = "1 thing to do here, in walking order.",
    ["%d choses à faire ici, dans l'ordre du chemin."] = "%d things to do here, in walking order.",
    ["Tout est fait ici. Bonne route !"] = "All done here. Safe travels!",
    ["Tu n'es pas dans une capitale"] = "You're not in a capital city",
    ["La tournée s'ouvre toute seule quand tu arrives dans une capitale de ta faction."] =
        "The tour opens by itself when you reach one of your faction's capitals.",
    ["Rien à faire ici"] = "Nothing to do here",
    ["Pas de courrier, rien à réparer ni à rendre."] = "No mail, nothing to repair or turn in.",
    -- the stops
    ["Apprendre tes nouveaux sorts"] = "Learn your new spells",
    ["Tu as pris un niveau depuis ta dernière visite."] = "You gained a level since your last visit.",
    ["1 sort que tu peux maintenant payer."] = "1 spell you can now afford.",
    ["%d sorts que tu peux maintenant payer."] = "%d spells you can now afford.",
    ["Ton maître de classe est dans une autre capitale : %s."] = "Your class trainer is in another capital: %s.",
    ["Pas de maître de ta classe dans cette ville."] = "No trainer for your class in this city.",
    ["Lire ton courrier"] = "Read your mail",
    ["Réparer ton équipement"] = "Repair your gear",
    ["Objet le plus usé : %d %%"] = "Most worn item: %d%%",
    ["Rendre « %s »"] = "Turn in \"%s\"",
    ["Prendre des composants à la banque"] = "Take reagents from the bank",
    ["Pour la commande de %s."] = "For %s's order.",
    ["Pour les commandes de %s."] = "For the orders of %s.",
    ["Pour la commande que tu fabriques."] = "For the order you are crafting.",
    ["Acheter pour tes Writs à l'HV"] = "Buy for your Writs at the AH",
    ["1 objet à acheter"] = "1 item to buy",
    ["%d objets à acheter"] = "%d items to buy",
    ["Racheter des flèches"] = "Buy more arrows",
    ["Racheter des balles"] = "Buy more bullets",
    ["Il t'en reste %d."] = "%d left.",
    ["Tu n'en as plus."] = "You have none left.",
    ["Fait"] = "Done",
    ["Passée"] = "Skipped",
    -- the places (GPS labels)
    ["Banque"] = "Bank",
    ["Hôtel des ventes"] = "Auction house",
    ["Boîte aux lettres"] = "Mailbox",
    ["Réparations"] = "Repairs",
    ["Flèches"] = "Arrows",
    ["Balles"] = "Bullets",
    ["Maître de classe"] = "Class trainer",
    ["PNJ : %s"] = "NPC: %s",
    -- tooltips and chat
    ["Clic : guider vers %s"] = "Click: guide me to %s",
    ["Clic droit : passer cette étape"] = "Right-click: skip this stop",
    ["Pas de point connu pour cette étape."] = "No known spot for this stop.",
    ["Tournée en ville terminée : tout est fait."] = "City tour finished: everything is done.",
    ["Tournée des Writs mise en pause : relance-la depuis la fenêtre Writs."] =
        "Writs tour paused: start it again from the Writs window.",
    -- settings
    ["En arrivant dans une capitale, une petite fiche liste ce qu'il y a à faire : courrier, réparations, maître de classe, quêtes à rendre."] =
        "When you reach a capital, a small card lists what to do there: mail, repairs, class trainer, quests to turn in.",
    -- city names, when the game does not give the map's name
    ["Hurlevent"] = "Stormwind", ["Forgefer"] = "Ironforge", ["Darnassus"] = "Darnassus",
    ["Orgrimmar"] = "Orgrimmar", ["Fossoyeuse"] = "Undercity", ["Les Pitons-du-Tonnerre"] = "Thunder Bluff",
})

-- ---------------------------------------------------------------- data
-- uiMapID -> the city's places, x and y in map percent, with the NPC's name (English, as in the
-- data; it only shows in tooltips). From LibForeverData 2026.11.1 spawns.
local CITIES = {
    [1453] = { side = "Alliance", fr = "Hurlevent",
        bank = { { 64.3, 80.7, "Olivia Burnside" }, { 63.9, 81.1, "Newton Burnside" } },
        ah = { { 61.1, 70.7, "Auctioneer Jaxon" }, { 61.2, 71.3, "Auctioneer Fitch" } },
        mail = { { 61.6, 76.1 }, { 61.8, 70.8 }, { 54.6, 63.0 }, { 50.6, 89.8 }, { 74.5, 55.4 }, { 64.6, 37.3 },
            { 36.8, 69.2 }, { 45.5, 54.1 }, { 66.7, 65.2 }, { 57.3, 71.8 } },
        repair = { { 61.9, 67.2, "Aldric Moore" }, { 62.0, 67.5, "Lara Moore" }, { 77.2, 61.0, "Osric Strang" },
            { 53.5, 57.5, "Agustus Moulaine" }, { 71.9, 62.0, "Seoman Griffith" } },
        arrows = { { 58.4, 69.0, "Frederick Stover" } },
        bullets = { { 58.4, 69.0, "Frederick Stover" } },
        trainers = {
            WARRIOR = { 80.2, 61.3, "Ander Germaine" }, PALADIN = { 49.6, 49.8, "Arthur the Faithful" },
            HUNTER = { 67.4, 36.2, "Einris Brightspear" }, ROGUE = { 77.4, 65.3, "Osborne the Night Man" },
            PRIEST = { 49.5, 44.6, "High Priestess Laurena" }, MAGE = { 49.5, 85.8, "Jennea Cannon" },
            WARLOCK = { 39.2, 85.0, "Demisette Cloyce" }, DRUID = { 35.9, 67.4, "Sheldras Moontree" },
        } },
    [1455] = { side = "Alliance", fr = "Forgefer",
        bank = { { 35.0, 58.4, "Barnum Stonemantle" }, { 35.9, 60.1, "Bailey Stonemantle" } },
        ah = { { 23.8, 71.8, "Auctioneer Buckler" }, { 24.1, 74.6, "Auctioneer Redmuse" } },
        mail = { { 33.1, 64.7 }, { 21.1, 52.6 }, { 71.0, 72.2 }, { 72.1, 49.4 } },
        repair = { { 31.7, 58.2, "Bromiir Ormsen" }, { 32.6, 57.4, "Raena Flinthammer" },
            { 54.9, 87.4, "Olthran Craghelm" }, { 53.9, 87.9, "Dolkin Craghelm" } },
        arrows = { { 71.8, 66.7, "Skolmin Goldfury" } },
        bullets = { { 72.2, 65.2, "Bretta Goldfury" } },
        trainers = {
            WARRIOR = { 67.0, 90.2, "Kelstrum Stonebreaker" }, PALADIN = { 23.7, 5.1, "Valgar Highforge" },
            HUNTER = { 71.0, 89.8, "Daera Brightspear" }, ROGUE = { 52.0, 14.8, "Hulfdan Blackbeard" },
            PRIEST = { 24.1, 8.4, "Theodrus Frostbeard" }, MAGE = { 25.9, 6.2, "Nittlebur Sparkfizzle" },
            WARLOCK = { 51.1, 6.6, "Thistleheart" }, SHAMAN = { 47.4, 13.8, "Eldrun Stormbreaker" },
        } },
    [1457] = { side = "Alliance", fr = "Darnassus",
        bank = { { 39.4, 42.6, "Idriana" }, { 39.9, 41.6, "Lairn" } },
        ah = { { 56.4, 51.8, "Auctioneer Tolon" }, { 57.2, 53.7, "Auctioneer Silva'las" } },
        mail = { { 41.7, 41.8 }, { 67.2, 16.5 } },
        repair = { { 59.1, 46.5, "Cylania" }, { 57.1, 77.0, "Melea" }, { 60.6, 72.5, "Vinasia" } },
        arrows = { { 63.2, 66.3, "Landria" } },
        bullets = {},
        trainers = {
            WARRIOR = { 58.7, 34.9, "Arias'ta Bladesinger" }, HUNTER = { 39.9, 5.6, "Jeen'ra Nightrunner" },
            ROGUE = { 37.0, 21.9, "Syurna" }, PRIEST = { 38.4, 81.1, "Astarii Starseeker" },
            DRUID = { 35.6, 8.5, "Mathrengyl Bearwalker" },
        } },
    [1454] = { side = "Horde", fr = "Orgrimmar",
        bank = { { 49.6, 69.1, "Karus" }, { 50.0, 68.6, "Koma" } },
        ah = { { 55.9, 62.7, "Auctioneer Thathung" }, { 55.2, 61.8, "Auctioneer Grimful" } },
        mail = { { 50.7, 70.4 }, { 53.4, 66.0 }, { 51.6, 59.2 }, { 60.8, 55.6 }, { 45.5, 54.1 }, { 51.7, 46.8 },
            { 48.3, 37.8 }, { 62.2, 40.5 }, { 38.2, 74.8 }, { 81.4, 21.2 }, { 49.4, 71.4 } },
        repair = { { 56.5, 73.8, "Ollanus" }, { 56.0, 72.7, "Sana" }, { 62.9, 44.7, "Handor" },
            { 62.8, 50.5, "Tor'phan" }, { 82.6, 23.6, "Tumi" } },
        arrows = { { 78.1, 38.5, "Jin'sora" }, { 52.1, 62.1, "Kaja" } },
        bullets = { { 52.1, 62.1, "Kaja" } },
        trainers = {
            WARRIOR = { 79.8, 31.4, "Grezz Ragefist" }, HUNTER = { 66.0, 18.5, "Ormak Grimshot" },
            ROGUE = { 42.7, 51.5, "Gest" }, PRIEST = { 35.6, 87.8, "Ur'kyo" }, MAGE = { 38.5, 85.6, "Pephredo" },
            WARLOCK = { 48.5, 45.4, "Zevrost" }, SHAMAN = { 38.7, 35.9, "Sagorne Creststrider" },
        } },
    [1458] = { side = "Horde", fr = "Fossoyeuse",
        bank = { { 66.0, 43.4, "Randolph Montague" }, { 66.4, 44.0, "Mortimer Montague" } },
        ah = { { 67.6, 52.4, "Auctioneer Leeka" }, { 64.4, 52.4, "Auctioneer Epitwee" } },
        mail = { { 68.1, 38.3 }, { 71.7, 61.6 }, { 69.8, 51.7 }, { 62.1, 51.6 }, { 62.2, 36.6 }, { 69.8, 36.6 }, { 66.5, 50.1 } },
        repair = { { 62.6, 39.7, "Timothy Weldon" }, { 62.4, 38.7, "Walter Ellingson" }, { 63.8, 38.0, "Lauren Newcomb" } },
        arrows = { { 54.7, 38.7, "Abigail Sawyer" } },
        bullets = { { 62.7, 26.8, "Nicholas Atwood" } },
        trainers = {
            WARRIOR = { 47.1, 15.3, "Christoph Walker" }, PALADIN = { 47.3, 16.2, "Garen Largo" },
            ROGUE = { 83.9, 72.1, "Carolyn Ward" }, PRIEST = { 49.0, 18.1, "Aelthalyste" },
            MAGE = { 85.0, 14.1, "Kaelystia Hatebringer" }, WARLOCK = { 86.2, 15.9, "Kaal Soulreaper" },
        } },
    [1456] = { side = "Horde", fr = "Les Pitons-du-Tonnerre",
        bank = { { 47.7, 58.9, "Torn" }, { 47.1, 57.9, "Chesmu" } },
        ah = { { 40.4, 52.0, "Auctioneer Stampi" }, { 38.9, 50.2, "Auctioneer Gullem" } },
        mail = { { 45.2, 59.3 } },
        repair = { { 45.0, 56.6, "Elki" }, { 45.6, 56.6, "Hewa" }, { 45.8, 55.9, "Ahanu" }, { 42.8, 45.0, "Fela" } },
        arrows = { { 47.0, 45.7, "Kuna Thunderhorn" } },
        bullets = { { 55.5, 57.0, "Hogor Thunderhoof" } },
        trainers = {
            WARRIOR = { 57.5, 85.4, "Ker Ragetotem" }, HUNTER = { 59.0, 86.9, "Urek Thunderhorn" },
            PRIEST = { 25.1, 15.5, "Miles Welsh" }, MAGE = { 23.0, 14.5, "Archmage Shymm" },
            SHAMAN = { 22.1, 19.0, "Beram Skychaser" }, DRUID = { 76.3, 27.3, "Turak Runetotem" },
            PALADIN = { 22.6, 19.9, "Alodan the Hopeful" },
        } },
}
CT.CITIES = CITIES
-- what each list of places is, as the GPS and the rows name it
local ROLE = { bank = "Banque", ah = "Hôtel des ventes", mail = "Boîte aux lettres", repair = "Réparations",
    arrows = "Flèches", bullets = "Balles", trainer = "Maître de classe" }

local LOW_DURABILITY = 0.35
local LOW_AMMO = 400          -- two stacks: a hunter burns through more than that in an evening
local SAME_VISIT = 600        -- seconds out of the city (a loading screen, a /reload) that keep the visit

-- ---------------------------------------------------------------- helpers
local function IsSecret(v) return issecretvalue ~= nil and issecretvalue(v) end
local function num(v) return type(v) == "number" and not IsSecret(v) and v or nil end
local function str(v) return type(v) == "string" and not IsSecret(v) and v or nil end
local function safe(f, ...)
    if type(f) ~= "function" then return nil end
    local ok, a, b, c, d, e, g, h, i = pcall(f, ...)
    if ok then return a, b, c, d, e, g, h, i end
end
local function N(n, one, many) return n == 1 and L(one) or string.format(L(many), n) end

local function DB()
    WLWritsDB.cityTour = WLWritsDB.cityTour or {}
    local d = WLWritsDB.cityTour
    if d.on == nil then d.on = true end
    return d
end
local function CharDB()
    WLWritsCharDB = WLWritsCharDB or {}
    WLWritsCharDB.cityTour = WLWritsCharDB.cityTour or {}
    return WLWritsCharDB.cityTour
end
CT.DB = DB

function CT.IsOn() return WLWritsDB ~= nil and DB().on ~= false end
function CT.SetOn(on)
    DB().on = on and true or false
    if not on then CT.Hide() end
end

local function CityName(map)
    local info = C_Map and safe(C_Map.GetMapInfo, map)
    local name = info and str(info.name)
    if name and name ~= "" then return name end
    return CITIES[map] and L(CITIES[map].fr) or "?"
end
CT.CityName = CityName

local function Side() return str((UnitFactionGroup("player"))) end

-- The capital the player stands in (one of his faction's), or nil. A sub-zone's map climbs to its
-- city through the parent maps; the zone's name is the last resort.
local function CurrentCity()
    local side = Side()
    local map = C_Map and num(safe(C_Map.GetBestMapForUnit, "player"))
    for _ = 1, 4 do
        if not map then break end
        local c = CITIES[map]
        if c then return c.side == side and map or nil end
        local info = safe(C_Map.GetMapInfo, map)
        map = info and num(info.parentMapID)
    end
    local zone = str(safe(GetRealZoneText))
    if zone and zone ~= "" then
        for id, c in pairs(CITIES) do
            if c.side == side and zone == CityName(id) then return id end
        end
    end
end
CT.CurrentCity = CurrentCity

-- The player on the city's map, in percent (nil outside it or unreadable).
local function PlayerXY(city)
    if not (C_Map and C_Map.GetPlayerMapPosition) then return end
    local pos = safe(C_Map.GetPlayerMapPosition, city, "player")
    if not (pos and pos.GetXY) then return end
    local x, y = safe(pos.GetXY, pos)
    x, y = num(x), num(y)
    if x and y and (x > 0 or y > 0) then return x * 100, y * 100 end
end

-- Walking distance between two points of the same map: world yards when the GPS can convert them
-- (a city map is not square), else map percent.
-- Only the fixed places are cached (a few dozen per city); the player's own point changes at every
-- step and is converted each time.
local worldCache = {}
local function World(map, x, y, nocache)
    local key = map .. ":" .. x .. ":" .. y
    local w = not nocache and worldCache[key] or nil
    if w == nil then
        local p = WP.GPS and WP.GPS.Point and safe(WP.GPS.Point, map, x, y)
        w = (p and num(p.wx) and num(p.wy)) and { p.wx, p.wy } or false
        if not nocache then worldCache[key] = w end
    end
    return w
end
local function Dist(map, ax, ay, bx, by, fromPlayer)
    local a, b = World(map, ax, ay, fromPlayer), World(map, bx, by)
    if a and b then return math.sqrt((a[1] - b[1]) ^ 2 + (a[2] - b[2]) ^ 2) end
    return math.sqrt((ax - bx) ^ 2 + (ay - by) ^ 2)
end

-- Places of a list as { x, y, n (NPC), role }
local function Places(list, role)
    local out = {}
    for _, p in ipairs(list or {}) do out[#out + 1] = { x = p[1], y = p[2], npc = p[3], role = role } end
    return out
end

-- ---------------------------------------------------------------- the trainer, read at his window
-- What the class trainer still had to teach at the last visit: the level then, the spells left
-- (the ones you could not pay) and the cheapest of them.
-- TRAINER_SHOW also opens weapon masters, pet trainers and riding trainers: their window must not
-- count as a class trainer visit. The trainer is ours when his name is one of our class trainers
-- (the data's English names), or when what he teaches belongs to one of our spellbook's class tabs.
-- When the client gives neither, the old reading stands.
local classWindow = false   -- the trainer window open now is the class trainer's
local function ClassTrainerOpen(n)
    local _, class = UnitClass("player")
    local npc = str((UnitName("npc")))
    if npc and class then
        for _, c in pairs(CITIES) do
            local tr = c.trainers[class]
            if tr and tr[3] == npc then return true end
        end
    end
    if type(GetTrainerServiceSkillLine) ~= "function" or type(GetSpellTabInfo) ~= "function" then return true end
    local tabs, anyTab = {}, false
    local nt = num(safe(GetNumSpellTabs)) or 4
    -- tab 1 is "General" (shared by everyone): the class tabs follow
    for i = 2, math.min(nt, 8) do
        local name = str((safe(GetSpellTabInfo, i)))
        if name and name ~= "" then tabs[name] = true; anyTab = true end
    end
    if not anyTab then return true end
    local anyLine = false
    for i = 1, n do
        local line = str((safe(GetTrainerServiceSkillLine, i)))
        if line and line ~= "" then
            anyLine = true
            if tabs[line] then return true end
        end
    end
    return not anyLine
end
CT.ClassTrainerOpen = ClassTrainerOpen

local function ReadTrainer()
    if type(GetNumTrainerServices) ~= "function" or type(GetTrainerServiceInfo) ~= "function" then return end
    if type(IsTradeskillTrainer) == "function" and safe(IsTradeskillTrainer) then return end
    local n = num(safe(GetNumTrainerServices)) or 0
    if n <= 0 then return end   -- closed or filtered out: keep the last reading
    classWindow = ClassTrainerOpen(n)
    if not classWindow then return end
    local left, cheapest = 0, nil
    for i = 1, n do
        local _, _, category = safe(GetTrainerServiceInfo, i)
        if category == "available" then
            left = left + 1
            local cost = num(safe(GetTrainerServiceCost, i))
            if cost and (not cheapest or cost < cheapest) then cheapest = cost end
        end
    end
    local level = num(UnitLevel("player"))
    if not level then return end
    CharDB().trainer = { level = level, left = left, cheapest = cheapest or 0 }
end
CT.ReadTrainer = ReadTrainer

-- Why the trainer is worth a visit now, or nil. Without a reading yet the current level counts as
-- seen: a guild member who just installed the addon is not sent to his trainer for nothing.
local function TrainerReason()
    local level = num(UnitLevel("player"))
    if not level then return nil end
    local d = CharDB()
    local rec = d.trainer
    if type(rec) ~= "table" or not num(rec.level) then
        d.trainer = { level = level, left = 0, cheapest = 0 }
        return nil
    end
    -- most classes get their ranks at even levels
    if math.floor(level / 2) > math.floor(rec.level / 2) then return L("Tu as pris un niveau depuis ta dernière visite.") end
    local money = num(safe(GetMoney)) or 0
    if (rec.left or 0) > 0 and level == rec.level and money >= (rec.cheapest or 0) and (rec.money or -1) < (rec.cheapest or 0) then
        return N(rec.left, "1 sort que tu peux maintenant payer.", "%d sorts que tu peux maintenant payer.")
    end
end

-- ---------------------------------------------------------------- the quest log
local function QuestLog()
    local out = {}
    local Q = C_QuestLog
    if Q and type(Q.GetNumQuestLogEntries) == "function" and type(Q.GetInfo) == "function" then
        local n = num(safe(Q.GetNumQuestLogEntries)) or 0
        for i = 1, n do
            local info = safe(Q.GetInfo, i)
            local id = info and num(info.questID)
            if id and id > 0 and not info.isHeader then
                local done
                if type(Q.IsComplete) == "function" then done = safe(Q.IsComplete, id) else done = info.isComplete end
                if not IsSecret(done) and done == true then out[#out + 1] = { id = id, title = str(info.title) } end
            end
        end
        return out
    end
    if type(GetNumQuestLogEntries) ~= "function" or type(GetQuestLogTitle) ~= "function" then return out end
    local n = num(safe(GetNumQuestLogEntries)) or 0
    for i = 1, n do
        local title, _, _, isHeader, _, isComplete, _, id = safe(GetQuestLogTitle, i)
        id = num(id)
        if id and not isHeader and num(isComplete) == 1 then out[#out + 1] = { id = id, title = str(title) } end
    end
    return out
end

-- Where a quest is turned in, in this city: the guide's data first, then LibForeverData.
local lfdCache = {}
local function TurnIn(id, city)
    local q = root.Q and root.Q[id]
    local f = q and q.f
    if f and f.m == city and num(f.x) and num(f.y) then
        return { { x = f.x, y = f.y, npc = f.n, role = f.n } }, q
    end
    local lib = LibForeverData
    if type(lib) ~= "table" or type(lib.Quest) ~= "function" or type(lib.Get) ~= "function" then return nil, q end
    local key = id .. ":" .. city
    if lfdCache[key] ~= nil then return lfdCache[key] or nil, q end
    local places = false
    local rec = safe(lib.Quest, id)
    for _, e in ipairs(rec and rec.finish or {}) do
        if e.kind == "npc" and e.id then
            local npc = safe(lib.Get, "npc", e.id)
            local pts = npc and npc.spawns and npc.spawns[city]
            if pts and num(pts[1]) and num(pts[2]) then
                places = places or {}
                places[#places + 1] = { x = pts[1], y = pts[2], npc = npc.name, role = npc.name }
            end
        end
    end
    lfdCache[key] = places
    return places or nil, q
end

-- ---------------------------------------------------------------- the stops
local function ItemList(list)
    local t = {}
    for _, e in ipairs(list) do t[#t + 1] = string.format("%s ×%d", WP.ItemName and WP.ItemName(e.id) or ("item " .. e.id), e.n) end
    return table.concat(t, ", ")
end

-- Reagents of accepted orders that are in the bank and not yet in the bags: as the customer (still
-- to send) and as the crafter (the ones the crafter provides).
-- The same reagent in several orders is added up before the bags are counted once.
-- -> { { id, n } }, { customers = { names }, crafter = true when an order is one you craft }
local function BankReagents()
    local O = WP.Orders
    if not (O and O.DB and O.Decode and WP.ModuleOn and WP.ModuleOn("orders")) then return nil end
    local me = UnitName("player")
    local total, order, who, named = {}, {}, { customers = {} }, {}
    local function add(id, n, kind, name)
        if not (num(id) and num(n) and n > 0) then return end
        if not total[id] then total[id] = 0; order[#order + 1] = id end
        total[id] = total[id] + n
        if kind == "customer" and type(name) == "string" and not named[name] then
            named[name] = true; who.customers[#who.customers + 1] = name
        elseif kind == "crafter" then
            who.crafter = true
        end
    end
    for _, o in pairs(O.DB().list or {}) do
        if o.status == "accepted" then
            if o.from == me and not o.sentGive then
                for _, r in ipairs(O.Decode(o.give)) do add(r[1], r[2] * (o.qty or 1), "customer", o.by) end
            elseif o.by == me then
                for _, r in ipairs(O.Decode(o.crafter)) do add(r[1], r[2] * (o.qty or 1), "crafter") end
            end
        end
    end
    local want = {}
    for _, id in ipairs(order) do
        local owned = WP.OwnedCount and WP.OwnedCount(id) or 0
        local bank = WP.InBank and WP.InBank(id) or 0
        local take = math.min(bank, total[id] - (owned - bank))
        if take > 0 then want[#want + 1] = { id = id, n = take } end
    end
    if #want == 0 then return nil end
    table.sort(who.customers)
    return want, who
end

-- What the Writs still need from the auction house: the items missing for writs you hold, and the
-- writs you ticked yourself. The automatic plan stays in the Comptoir: it is a suggestion, and the
-- card would otherwise speak of it in every city.
-- It rebuilds the whole Writs plan, so it is read again only after the bags change, the auction
-- house closes or a writ quest is turned in (or a minute later), not on every refresh of the card.
local buyCache, buyAt = nil, -1e9
local BUY_TTL = 60
function CT.ForgetWrits() buyCache = nil end
local function WritsToBuyNow()
    if not (WP.ModuleOn and WP.ModuleOn("writs") and WP.Rows and WP.Plan and WP.ShoppingList) then return 0 end
    local ok, n = pcall(function()
        local rows = WP.Rows()
        WP.Plan(rows)
        local list = WP.ShoppingList(rows)
        local picked = WLWritsCharDB and WLWritsCharDB.picked and next(WLWritsCharDB.picked) ~= nil
        local count = 0
        for _, e in ipairs(list) do
            local held = type(e.group) == "string" and e.group:sub(1, 1) == " "
            if not e.done and (picked or held) then count = count + 1 end
        end
        return count
    end)
    return ok and n or 0
end
local function WritsToBuy()
    local now = GetTime and GetTime() or 0
    if buyCache == nil or now - buyAt > BUY_TTL then buyCache, buyAt = WritsToBuyNow(), now end
    return buyCache
end

-- The worst durability of the equipped items, 0 to 1, and that item's icon.
local function WorstDurability()
    if type(GetInventoryItemDurability) ~= "function" then return nil end
    local worst, icon
    for slot = 1, 18 do
        local cur, max = safe(GetInventoryItemDurability, slot)
        cur, max = num(cur), num(max)
        if cur and max and max > 0 then
            local r = cur / max
            if not worst or r < worst then worst = r; icon = safe(GetInventoryItemTexture, "player", slot) end
        end
    end
    return worst, icon
end

-- A hunter's ammo: "arrows" or "bullets" for the ranged weapon, and how many are left.
local function Ammo()
    local _, class = UnitClass("player")
    if class ~= "HUNTER" then return nil end
    local slot = INVSLOT_RANGED or 18
    local id = num(safe(GetInventoryItemID, "player", slot))
    if not id then return nil end
    local getInfo = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
    local _, _, _, _, _, classID, subID = safe(getInfo, id)
    if num(classID) ~= 2 then return nil end
    local kind = (subID == 2 or subID == 18) and "arrows" or (subID == 3 and "bullets") or nil
    if not kind then return nil end
    -- projectiles (item class 6): subclass 2 arrows, 3 bullets
    local want = kind == "arrows" and 2 or 3
    local ammoSlot = INVSLOT_AMMO or 0
    local slotCount, bagCount, icon
    if num(safe(GetInventoryItemID, "player", ammoSlot)) then
        slotCount = num(safe(GetInventoryItemCount, "player", ammoSlot))
        icon = safe(GetInventoryItemTexture, "player", ammoSlot)
    end
    -- the bags themselves (the slot can read nothing on this client): every stack of that kind
    local Ct = C_Container
    if Ct and type(Ct.GetContainerNumSlots) == "function" and type(Ct.GetContainerItemInfo) == "function" then
        local readable = false
        bagCount = 0
        for bag = 0, (NUM_BAG_SLOTS or 4) do
            local nslots = num(safe(Ct.GetContainerNumSlots, bag)) or 0
            if nslots > 0 then readable = true end
            for slotIndex = 1, nslots do
                local info = safe(Ct.GetContainerItemInfo, bag, slotIndex)
                local id2 = type(info) == "table" and num(info.itemID)
                if id2 then
                    local _, _, _, _, ic, cls, sub = safe(getInfo, id2)
                    if num(cls) == 6 and num(sub) == want then
                        bagCount = bagCount + (num(info.stackCount) or 0)
                        icon = icon or ic
                    end
                end
            end
        end
        if not readable then bagCount = nil end
    end
    -- neither the slot nor the bags could be read: no stop rather than "none left" in every city
    if not slotCount and not bagCount then return nil end
    local count = math.max(slotCount or 0, bagCount or 0)
    return kind, count, icon or safe(GetInventoryItemTexture, "player", slot)
end

-- Every stop of this city now: { key, name, fact, icon, class, places, tip }.
local visit   -- this visit: { map, at, dismissed, skipped = {}, mailSeen, seen = {}, doneOrder = {}, tour }
local function Collect(city)
    local c = CITIES[city]
    local out = {}
    if not c then return out end
    local function add(t) out[#out + 1] = t end

    local reason = TrainerReason()
    if reason then
        local _, class = UnitClass("player")
        local tr = class and c.trainers[class]
        local t = { key = "trainer", name = L("Apprendre tes nouveaux sorts"), fact = reason, class = class, tip = { reason } }
        if tr then
            t.places = { { x = tr[1], y = tr[2], npc = tr[3], role = ROLE.trainer } }
        else
            local elsewhere = {}
            for id, o in pairs(CITIES) do
                if id ~= city and o.side == c.side and class and o.trainers[class] then elsewhere[#elsewhere + 1] = CityName(id) end
            end
            table.sort(elsewhere)
            t.fact = #elsewhere > 0 and string.format(L("Ton maître de classe est dans une autre capitale : %s."), table.concat(elsewhere, ", "))
                or L("Pas de maître de ta classe dans cette ville.")
            t.tip = { reason, t.fact }
        end
        add(t)
    end

    if not (visit and visit.mailSeen) and safe(HasNewMail) == true then
        add({ key = "mail", name = L("Lire ton courrier"), hd = "mail", places = Places(c.mail, ROLE.mail) })
    end

    local worst, icon = WorstDurability()
    if worst and worst < LOW_DURABILITY then
        add({ key = "repair", name = L("Réparer ton équipement"), icon = icon,
            fact = string.format(L("Objet le plus usé : %d %%"), math.floor(worst * 100 + 0.5)), places = Places(c.repair, ROLE.repair) })
    end

    for _, q in ipairs(QuestLog()) do
        local places, data = TurnIn(q.id, city)
        if places then
            local title = q.title or (data and (ns.English() and data.n or data.nf or data.n)) or tostring(q.id)
            add({ key = "quest:" .. q.id, name = string.format(L("Rendre « %s »"), title), places = places })
        end
    end

    local want, who = BankReagents()
    if want then
        local first = safe((C_Item and C_Item.GetItemIconByID) or GetItemIcon, want[1].id)
        local tip = { ItemList(want) }
        local cs = who and who.customers or {}
        if #cs == 1 then tip[#tip + 1] = string.format(L("Pour la commande de %s."), cs[1])
        elseif #cs > 1 then tip[#tip + 1] = string.format(L("Pour les commandes de %s."), table.concat(cs, ", ")) end
        if who and who.crafter then tip[#tip + 1] = L("Pour la commande que tu fabriques.") end
        add({ key = "bank", name = L("Prendre des composants à la banque"), fact = ItemList(want), icon = first,
            places = Places(c.bank, ROLE.bank), tip = tip })
    end

    local buy = WritsToBuy()
    if buy > 0 then
        add({ key = "ah", name = L("Acheter pour tes Writs à l'HV"), fact = N(buy, "1 objet à acheter", "%d objets à acheter"),
            places = Places(c.ah, ROLE.ah) })
    end

    local kind, count, ammoIcon = Ammo()
    if kind and count < LOW_AMMO then
        add({ key = "ammo", name = kind == "arrows" and L("Racheter des flèches") or L("Racheter des balles"),
            fact = count > 0 and string.format(L("Il t'en reste %d."), count) or L("Tu n'en as plus."), icon = ammoIcon,
            places = Places(c[kind], ROLE[kind]) })
    end
    return out
end
CT.Collect = Collect

-- Walking order: nearest stop first from where you stand, then nearest from that stop; a stop
-- with several places (mailboxes, auctioneers) takes the one nearest the stop before it. Stops
-- without a known place go last, in their order.
local function Order(tasks, city)
    local px, py = PlayerXY(city)
    local fromPlayer = true
    local open, rest, out = {}, {}, {}
    for _, t in ipairs(tasks) do
        if t.places and #t.places > 0 then open[#open + 1] = t else rest[#rest + 1] = t end
    end
    while #open > 0 do
        local bi, bp, bd
        for i, t in ipairs(open) do
            for _, p in ipairs(t.places) do
                local d = px and Dist(city, px, py, p.x, p.y, fromPlayer) or 0
                if not bd or d < bd then bi, bp, bd = i, p, d end
            end
        end
        local t = table.remove(open, bi)
        t.place = bp
        px, py, fromPlayer = bp.x, bp.y, false
        out[#out + 1] = t
    end
    for _, t in ipairs(rest) do out[#out + 1] = t end
    return out
end

-- ---------------------------------------------------------------- the visit

local function SaveVisit()
    if not visit then CharDB().visit = nil; return end
    CharDB().visit = { map = visit.map, at = time(), dismissed = visit.dismissed or nil, skipped = visit.skipped,
        mailSeen = visit.mailSeen or nil }
end

-- Starts, keeps or ends the visit from where the player is. A /reload or a loading screen inside
-- the same city keeps it (what was closed stays closed).
local function UpdateVisit()
    local city = CurrentCity()
    if visit and visit.map == city then
        -- still here: the saved visit stays fresh, so a /reload later in the visit keeps it
        visit.at = time()
        local saved = CharDB().visit
        if type(saved) == "table" and saved.map == city then saved.at = visit.at end
        return false
    end
    local changed = (visit and visit.map) ~= city
    if not city then
        if visit then SaveVisit() end
        visit = nil
        return changed
    end
    local saved = CharDB().visit
    visit = { map = city, at = time(), skipped = {}, seen = {}, doneOrder = {} }
    if type(saved) == "table" and saved.map == city and time() - (saved.at or 0) < SAME_VISIT then
        visit.dismissed = saved.dismissed
        visit.skipped = type(saved.skipped) == "table" and saved.skipped or {}
        visit.mailSeen = saved.mailSeen
    end
    SaveVisit()
    return changed
end

-- The stops of this visit: the open ones in walking order, then the ones done since you arrived
-- (ticked by themselves or skipped), in the order they were done.
function CT.Tasks()
    if not (WLWritsDB and visit) then return {}, 0 end
    local list = Order(Collect(visit.map), visit.map)
    local now, open = {}, {}
    for _, t in ipairs(list) do
        now[t.key] = t
        if visit.skipped[t.key] then
            if not visit.seen[t.key] or not visit.seen[t.key].done then
                t.done, t.skipped = true, true
                visit.seen[t.key] = t
                visit.doneOrder[#visit.doneOrder + 1] = t.key
            end
        else
            visit.seen[t.key] = t
            open[#open + 1] = t
        end
    end
    for key, t in pairs(visit.seen) do
        if not now[key] and not t.done then
            t.done = true
            visit.doneOrder[#visit.doneOrder + 1] = key
        end
    end
    local out = {}
    for _, t in ipairs(open) do t.done = nil; out[#out + 1] = t end
    local nOpen = #out
    local listed = {}
    for _, key in ipairs(visit.doneOrder) do
        local t = visit.seen[key]
        if t and t.done and not listed[key] and not (now[key] and not visit.skipped[key]) then
            listed[key] = true
            out[#out + 1] = t
        end
    end
    return out, nOpen
end

function CT.Skip(key)
    if not (visit and key) then return end
    visit.skipped[key] = true
    SaveVisit()
    CT.Refresh()
end

-- ---------------------------------------------------------------- GPS
local current   -- the stop the GPS leads to: { key, map, x, y, label }

local function Label(t)
    local p = t.place
    return p and (p.role and L(p.role) or p.npc) or t.name
end
local function Ours()
    local G = WP.GPS
    return current and G and G.Active and G.Active() and G.DestName and G.DestName() == current.label
end

-- Guides to one stop. The GPS's "writs" source is the one that lends the arrow for a detour: the
-- dungeon guide's point comes back when this one stops (as the Favor tab does). The player's click
-- wins over a running Writs tour, as /way and "Aller à" do: the tour pauses, one line says so.
local going = false     -- CT.Go is moving the arrow itself: its own GPS.Stop is no "arrow closed"
function CT.Go(t)
    local G = WP.GPS
    if not (t and t.place and visit and G and G.GoPoint) then return false end
    local paused = false
    local label = Label(t)
    -- the flag always comes down, even if the GPS errors: else no closed arrow would refresh the card
    going = true
    local ok, err = pcall(function()
        if G.Active() and G.Source and G.Source() == "writs" and WLWritsCharDB and WLWritsCharDB.gps and not Ours() then
            WLWritsCharDB.gps = false
            paused = true
            if G.Stop then G.Stop("writs") end
            if WP.OnGPSChanged then pcall(WP.OnGPSChanged) end
        end
        G.GoPoint(visit.map, t.place.x, t.place.y, label, "writs")
    end)
    going = false
    if paused then WP.Print(L("Tournée des Writs mise en pause : relance-la depuis la fenêtre Writs.")) end
    if not ok then error(err, 0) end
    current = { key = t.key, map = visit.map, x = t.place.x, y = t.place.y, label = label }
    return true
end

function CT.StopTour()
    if visit then visit.tour = nil end
    if Ours() and WP.GPS.Stop then WP.GPS.Stop("writs") end
    current = nil
    CT.Refresh()
end

-- The next open stop with a place, from where you stand now.
function CT.GoNext()
    local list, nOpen = CT.Tasks()
    for i = 1, nOpen do
        local t = list[i]
        if t.place then
            visit.tour = true
            if CT.Go(t) then CT.Refresh() return true end
            visit.tour = nil
            CT.Refresh()
            return false
        end
    end
    if visit and visit.tour then WP.Print(L("Tournée en ville terminée : tout est fait.")) end
    CT.StopTour()
    return false
end
function CT.StartTour() return CT.GoNext() end
function CT.TourOn() return visit ~= nil and visit.tour == true end

-- ---------------------------------------------------------------- the card
local W = 360
local CW = W - 32
local win, rows = nil, {}
local quietHide = false

local function RowTip(r)
    local t = r.task
    if not t then return nil end
    local lines = { t.name }
    if t.place and t.place.npc then lines[#lines + 1] = string.format(L("PNJ : %s"), t.place.npc) end
    for _, l in ipairs(t.tip or (t.fact and { t.fact }) or {}) do lines[#lines + 1] = l end
    if t.done then return lines end
    if t.place then lines[#lines + 1] = string.format(L("Clic : guider vers %s"), Label(t))
    else lines[#lines + 1] = L("Pas de point connu pour cette étape.") end
    lines[#lines + 1] = L("Clic droit : passer cette étape")
    return lines
end

local function Row(i)
    local r = rows[i]
    if r then return r end
    r = S.ListRow(win)
    r:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    r:SetScript("OnClick", function(self, button)
        local t = self.task
        if not t or t.done then return end
        if button == "RightButton" then CT.Skip(t.key) else CT.Go(t) end
    end)
    r.tip = RowTip
    rows[i] = r
    return r
end

local function Build()
    win = S.Window("WLHelperCityTour", W, 200, L("Tournée en ville"), nil, WLWritsDB, "cityTourPos",
        { header = 44, minH = 120 })
    if not (WLWritsDB and WLWritsDB.cityTourPos) then
        win:ClearAllPoints()
        win:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -220, -200)
    end
    win.intro = S.Text(win, F.body, C.text)
    win.intro:SetJustifyH("LEFT"); win.intro:SetJustifyV("TOP")
    win.empty = S.EmptyState(win, "flag", "", nil, nil, nil)
    win.empty:SetWrapWidth(CW)
    win.button = S.Button(win, L("Lancer la tournée"), 0, 32, "primary", function()
        if CT.TourOn() then CT.StopTour() else CT.StartTour() end
    end, function()
        if CT.TourOn() then return { L("Arrêter la tournée"), L("Le GPS s'arrête ; les étapes restent dans la liste.") } end
        return { L("Lancer la tournée"), L("Le GPS te mène d'une étape à l'autre, la plus proche d'abord. Chaque étape se coche toute seule.") }
    end)
    -- closed by the player: not again for this visit
    win:SetScript("OnHide", function()
        if quietHide then return end
        if UIParent and UIParent.IsShown and not UIParent:IsShown() then return end
        if visit then visit.dismissed = true; SaveVisit() end
    end)
end

local function Render(list, nOpen)
    if not win then return end
    local top = win:ContentTop() + 12
    if not list then list, nOpen = CT.Tasks() end
    win.subtitle:SetText(visit and CityName(visit.map) or "")
    for _, r in ipairs(rows) do r:Hide(); r.task = nil end
    if not visit or #list == 0 then
        win.intro:Hide(); win.button:Hide()
        if visit then
            win.empty:Set("check", L("Rien à faire ici"), L("Pas de courrier, rien à réparer ni à rendre."))
        else
            win.empty:Set("flag", L("Tu n'es pas dans une capitale"), L("La tournée s'ouvre toute seule quand tu arrives dans une capitale de ta faction."))
        end
        win.empty:ClearAllPoints(); win.empty:SetPoint("TOP", win, "TOP", 0, -(top + 12))
        win.empty:Show()
        win:FitHeight(12 + win.empty:Fit())
        return
    end
    win.empty:Hide()
    local y = 0
    win.intro:ClearAllPoints(); win.intro:SetPoint("TOPLEFT", 16, -(top + y))
    win.intro:SetText(nOpen == 0 and L("Tout est fait ici. Bonne route !")
        or N(nOpen, "1 chose à faire ici, dans l'ordre du chemin.", "%d choses à faire ici, dans l'ordre du chemin."))
    win.intro:Show()
    y = y + S.FitText(win.intro, 2, CW, win) + 12
    local anyPlace = false
    for i, t in ipairs(list) do
        local r = Row(i)
        r.task = t
        if t.done then
            r:Set({ hd = "check", hdColor = C.ok, name = t.name, nameColor = C.muted, detail = t.skipped and L("Passée") or L("Fait") })
            r.icon:SetAlpha(1)
        else
            local where = t.place and Label(t)
            local detail = (where and t.fact) and (where .. " · " .. t.fact) or where or t.fact
            r:Set({ icon = (not t.hd and not t.class) and t.icon or nil, hd = t.hd, name = t.name, detail = detail })
            if t.class and S.ClassIcon(r.icon, t.class) then r.icon:SetSize(20, 20); r.icon:Show() end
            -- rows without an icon keep an empty slot of the same width: every name starts at the same x
            if r.icon:IsShown() then r.icon:SetAlpha(1)
            else r.icon:SetTexture(nil); r.icon:SetSize(20, 20); r.icon:SetAlpha(0); r.icon:Show() end
            anyPlace = anyPlace or t.place ~= nil
        end
        r:ClearAllPoints(); r:SetPoint("TOPLEFT", 16, -(top + y))
        r:SetWidth(CW)
        y = y + r:Fit(CW) + 2
        r:Show()
    end
    y = y - 2
    if anyPlace then
        local on = CT.TourOn()
        win.button:SetKind(on and "secondary" or "primary")
        win.button:SetText(on and L("Arrêter la tournée") or L("Lancer la tournée"))
        win.button:ClearAllPoints(); win.button:SetPoint("TOPLEFT", 16, -(top + y + 12))
        win.button:Show()
        y = y + 12 + 32
    else
        win.button:Hide()
    end
    win:FitHeight(y)
    win:FitHeightLater(y)
end

-- Opens the card (also outside a city: it then says when it comes by itself).
function CT.Show()
    if not WLWritsDB then return end
    UpdateVisit()
    if not win then Build() end
    win.auto = nil
    win:Show()
    Render()
end
function CT.Hide()
    if win and win:IsShown() then quietHide = true; win:Hide(); quietHide = false end
end
function CT.Toggle()
    if win and win:IsShown() then win:Hide() else CT.Show() end
end
function CT.IsShown() return win ~= nil and win:IsShown() end

-- After anything that may change a stop: tick it, follow the tour, show or hide the card.
local pendingShow = false
function CT.Refresh()
    if not WLWritsDB then return end
    local changed = UpdateVisit()
    if changed and not visit then
        -- out of the city: the card was about it; opened by hand, it now says so
        if win and win:IsShown() then
            if win.auto then CT.Hide() else Render() end
        end
        if current and Ours() then WP.GPS.Stop("writs") end
        current = nil
        return
    end
    if not visit then
        if win and win:IsShown() then Render() end
        return
    end
    -- the arrow closed (its X, /wlh gps) or taken by another place (/way, "Aller à"): the tour ends
    -- there, and never starts the GPS again by itself on the next stop ticked
    if visit.tour and current and not Ours() then visit.tour, current = nil, nil end
    -- nothing would show the stops: no card, no tour, and the card will not open by itself
    local shown = win and win:IsShown()
    if not shown and not (visit.tour and current) and (visit.dismissed or not CT.IsOn()) then return end
    local list, nOpen = CT.Tasks()
    -- the tour: the stop it leads to is done, on to the next
    if visit.tour and current then
        local stillOpen = false
        for i = 1, nOpen do if list[i].key == current.key then stillOpen = true end end
        if not stillOpen then CT.GoNext(); return end
    end
    if win and win:IsShown() then Render(list, nOpen); return end
    if nOpen > 0 and CT.IsOn() and not visit.dismissed then
        if InCombatLockdown and InCombatLockdown() then pendingShow = true; return end
        if not win then Build() end
        win.auto = true
        win:Show()
        Render(list, nOpen)
    end
end

-- ---------------------------------------------------------------- events
local ev = CreateFrame("Frame")
local queued = false
local function Soon(delay)
    if queued then return end
    queued = true
    local fn = function() queued = false; CT.Refresh() end
    if C_Timer and C_Timer.After then C_Timer.After(delay or 0.5, fn) else fn() end
end
CT.Soon = Soon

for _, e in ipairs({ "PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA", "ZONE_CHANGED", "ZONE_CHANGED_INDOORS",
    "UPDATE_PENDING_MAIL", "MAIL_SHOW", "UPDATE_INVENTORY_DURABILITY", "QUEST_LOG_UPDATE", "QUEST_TURNED_IN",
    "BAG_UPDATE_DELAYED", "BANKFRAME_CLOSED", "TRAINER_SHOW", "TRAINER_UPDATE", "TRAINER_CLOSED",
    "PLAYER_LEVEL_UP", "PLAYER_REGEN_ENABLED", "AUCTION_HOUSE_CLOSED", "MERCHANT_CLOSED" }) do
    pcall(ev.RegisterEvent, ev, e)
end
ev:SetScript("OnEvent", function(_, e)
    if not WLWritsDB then return end
    if e == "TRAINER_SHOW" or e == "TRAINER_UPDATE" then
        ReadTrainer()
        if C_Timer and C_Timer.After then C_Timer.After(0.3, ReadTrainer) end
    elseif e == "TRAINER_CLOSED" then
        -- what was left unpaid is now waiting for gold: note the money you had then (only when
        -- this window was the class trainer's: ReadTrainer just stamped it)
        ReadTrainer()
        local rec = CharDB().trainer
        if classWindow and type(rec) == "table" then rec.money = num(safe(GetMoney)) end
        classWindow = false
    elseif e == "MAIL_SHOW" then
        if visit then visit.mailSeen = true; SaveVisit() end
    elseif e == "BAG_UPDATE_DELAYED" or e == "AUCTION_HOUSE_CLOSED" or e == "QUEST_TURNED_IN" then
        CT.ForgetWrits()
    elseif e == "PLAYER_REGEN_ENABLED" then
        if not pendingShow then return end
        pendingShow = false
    end
    -- a new zone: let the map settle before reading where we are
    local zone = e == "PLAYER_ENTERING_WORLD" or e == "ZONE_CHANGED_NEW_AREA"
    Soon(zone and 2 or 0.5)
end)

-- The arrow closed (its X, /wlh gps, "Tu y es"): the card's button says so at once, not at the next
-- bag or zone event.
if hooksecurefunc and WP.GPS and WP.GPS.Stop then
    hooksecurefunc(WP.GPS, "Stop", function() if not going then Soon(0.1) end end)
end
