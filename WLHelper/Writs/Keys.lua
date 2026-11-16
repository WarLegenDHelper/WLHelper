-- Writs/Keys.lua: the key passport, "Passeport des clés" / "Key passport" (/wlh keys).
--
--  Passport  Every key or attunement an instance asks for on Forever: the Skeleton Key
--            (Scholomance), the Seal of Ascension (Upper Blackrock Spire), the Drakefire Amulet
--            (Onyxia), the Molten Core and Blackwing Lair attunements, then the shortcuts and doors (Shadowforge Key,
--            Key to the City, Crescent Key, Scarlet Key, Scepter of Celebras, Workshop Key, Prison
--            Cell Key). Each row says whether this character has it, how far it is in the quest
--            chain that gives it (step N of M, from the completed quests and the quest log), or
--            where it drops. "Guide-moi" starts the quest guide on that chain alone (a one-quest
--            card, like the class quest cards), or sends the GPS to the dungeon whose boss drops it.
--  Guild     The "Qui a la clé ?" tab of the Guild window (drawn here, called by Writs/Guild.lua):
--            for each key, the members who have it. Each copy tells the guild its own keys on its
--            own addon prefix: two numbers (owned, chain started), one bit per key, well under
--            255 bytes. Only those two numbers travel.
--  Groups    WP.Keys.WhoHas(dkey) and WP.Keys.EventWarning(title, names): the group module asks
--            whether anyone signed up for a dungeon that needs a key has it.
-- The bit of a key is its `id` below: never reorder or reuse an id, add new keys at the end.
local ADDON, root = ...
root.Writs = root.Writs or {}
local ns = root.Writs
local WP = ns.WP
local L = ns.L
local S = ns.S
local C = S.C
local F = S.F

ns.AddEnglish({
    -- the window and the module
    ["Passeport des clés"] = "Key passport",
    ["Clés"] = "Keys",
    ["Clés et accès des donjons et raids, et qui les a dans la guilde"] = "Dungeon and raid keys and attunements, and who has them in the guild",
    ["Aucune clé pour l'instant (0 sur %d)"] = "No keys yet (0 of %d)",
    ["1 clé sur %d"] = "1 key of %d",
    ["%d clés sur %d"] = "%d keys of %d",
    ["Pour entrer"] = "To get in",
    ["Raccourcis et portes"] = "Shortcuts and doors",
    -- what a key opens
    ["Pour entrer dans %s"] = "Needed to enter %s",
    ["Raccourci dans %s"] = "Shortcut in %s",
    ["Ouvre les portes de %s"] = "Opens the doors of %s",
    ["Téléportation vers %s"] = "Teleport to %s",
    -- where you stand
    ["Tu l'as"] = "You have it",
    ["Accès débloqué"] = "Access unlocked",
    ["Étape %d sur %d : %s"] = "Step %d of %d: %s",
    ["Pas commencée. Première étape : %s"] = "Not started. First step: %s",
    ["%s (se prend dès le niv. %d)"] = "%s (available from level %d)",
    ["Tombe sur %s, dans %s"] = "Drops from %s in %s",
    ["Pas dans le guide pour ce personnage."] = "Not in the guide for this character.",
    ["La chaîne de l'Alliance n'est pas encore dans le guide. Elle commence dans %s."] = "The Alliance chain is not in the guide yet. It starts in %s.",
    ["Commencée. La chaîne de l'Alliance n'est pas encore dans le guide."] = "Started. The Alliance chain is not in the guide yet.",
    ["Guide-moi"] = "Guide me",
    -- row tooltips
    ["Un seul membre du groupe en a besoin."] = "Only one group member needs it.",
    ["Chaque joueur du raid a besoin de la sienne."] = "Every raid member needs their own.",
    ["La chaîne compte 1 quête."] = "The chain has 1 quest.",
    ["La chaîne compte %d quêtes."] = "The chain has %d quests.",
    ["Dans la guilde : %s"] = "In the guild: %s",
    ["Personne dans la guilde pour l'instant."] = "Nobody in the guild yet.",
    ["Clic : lancer le guide sur cette chaîne"] = "Click: start the guide on this chain",
    ["Clic : revenir au guide en cours"] = "Click: back to the guide",
    ["Clic : voir ce que la route remplace"] = "Click: see what the route replaces",
    ["Clic : le GPS te mène à l'entrée de %s"] = "Click: the GPS takes you to the entrance of %s",
    ["Le guide de quêtes est éteint."] = "The quest guide is off.",
    -- chat
    ["%s tombe sur %s, dans %s : le GPS te mène à l'entrée."] = "%s drops from %s in %s: the GPS takes you to the entrance.",
    ["%s tombe sur %s, dans %s. Le GPS guide déjà ta tournée : arrête-la pour aller à l'entrée."] =
        "%s drops from %s in %s. The GPS is busy with your tour: stop it to go to the entrance.",
    ["Pas d'entrée connue pour %s."] = "No known entrance for %s.",
    -- the header icon
    ["Qui a la clé dans la guilde ?"] = "Who has the key in the guild?",
    ["Les membres qui ont WL Helper partagent leurs clés."] = "Members who have WL Helper share their keys.",
    ["Clic : ouvrir l'onglet de la guilde"] = "Click: open the guild tab",
    -- the guild tab
    ["Qui a la clé ?"] = "Who has the key?",
    ["Les clés des membres qui ont WL Helper, ceux en ligne d'abord."] = "Keys of the members who have WL Helper, online first.",
    ["Personne pour l'instant"] = "Nobody yet",
    ["%s et %d autres"] = "%s and %d more",
    ["En ligne : %s"] = "Online: %s",
    ["Hors ligne : %s"] = "Offline: %s",
    ["Chaîne commencée : %s"] = "Chain started: %s",
    ["Clic : ouvrir ton passeport des clés"] = "Click: open your key passport",
    -- for Home and Settings (the integration step wires them)
    ["Clic : ouvrir le passeport des clés"] = "Click: open the key passport",
    ["Tu n'es dans aucune guilde"] = "You are not in a guild",
    ["Les clés de la guilde apparaîtront ici dès que tu rejoins une guilde."] = "The guild's keys will show up here as soon as you join a guild.",
    -- the setting
    ["Partager mes clés avec la guilde"] = "Share my keys with the guild",
    ["Les membres qui ont WL Helper voient quelles clés tu as, dans l'onglet Qui a la clé ? de la guilde."] =
        "Members who have WL Helper see which keys you have, in the guild's Who has the key? tab.",
    -- groups (Writs/Events.lua)
    ["Aucun inscrit n'a %s d'après WL Helper : il en faut une pour entrer."] = "No sign-up has %s, as far as WL Helper knows: one is needed to get in.",
    ["Il manque encore %s à : %s."] = "Still missing the %s: %s.",
})

local K = {}
WP.Keys = K

-- ---------------------------------------------------------------- the keys
-- id: the key's bit in the guild message (fixed for ever). dg: the instances it is for, the first
-- one names it. Items, quests and bosses come from Curated.lua's ns.KEYS (Naowh's table checked in
-- LibForeverData); `opt` there says whether the key is needed to get in or only a shortcut.
-- each: every player needs their own (Onyxia's amulet); otherwise one in the group is enough.
local LIST = {
    -- quest: the Horde chain; aq: the Alliance one. The guide's data has only the Horde chains of the
    -- Skeleton Key and the Drakefire Amulet for now: until the Alliance ones come in, `ac` (their
    -- quest ids) tells started from not started, and `am` is the map where the chain begins.
    { id = 1, k = "scholo", item = 13704, name = "Skeleton Key", quest = 5511, dg = { "Scholomance" },
      aq = 5505, am = 1422, ac = { 5092, 5097, 5533, 5537, 5538, 5801, 5803, 5505 } },
    { id = 2, k = "ubrs", item = 12344, name = "Seal of Ascension", quest = 4743, dg = { "UpperBlackrockSpire" } },
    { id = 3, k = "ony", item = 16309, name = "Drakefire Amulet", quest = 6602, dg = { "OnyxiasLair" }, each = true,
      aq = 6502, am = 1428, ac = { 4182, 4183, 4184, 4185, 4186, 4223, 4224, 4241, 4242, 4264, 4282, 4322, 6402, 6403, 6501, 6502 } },
    -- no item: the attunement is the turned-in quest. Molten Core is not in the guide's data yet.
    { id = 4, k = "mc", quest = 7848, dg = { "MoltenCore" }, attune = true, opt = "shortcut", icon = "Interface\\Icons\\Spell_Fire_LavaSpawn" },
    { id = 5, k = "brd", item = 11000, name = "Shadowforge Key", quest = 3802, dg = { "BlackrockDepths" } },
    { id = 6, k = "strat", item = 12382, name = "Key to the City", boss = 10435, bossn = "Magistrate Barthilas", src = "StratholmeUndead", dg = { "StratholmeLiving", "StratholmeUndead" } },
    { id = 7, k = "dm", item = 18249, name = "Crescent Key", boss = 14354, bossn = "Pusillin", src = "DireMaulEast", dg = { "DireMaulWest", "DireMaulNorth" } },
    { id = 8, k = "scarlet", item = 7146, name = "The Scarlet Key", boss = 6487, bossn = "Arcanist Doan", src = "ScarletMonasteryLibrary", dg = { "ScarletMonasteryArmory", "ScarletMonasteryCathedral" } },
    { id = 9, k = "mara", item = 17191, name = "Scepter of Celebras", quest = 7046, dg = { "Maraudon" } },
    { id = 10, k = "gnome", item = 6893, name = "Workshop Key", boss = 6235, bossn = "Electrocutioner 6000", src = "Gnomeregan", dg = { "Gnomeregan" } },
    { id = 11, k = "prison", item = 11140, name = "Prison Cell Key", boss = 9018, bossn = "High Interrogator Gerstahn", src = "BlackrockDepths", dg = { "BlackrockDepths" } },
    -- Blackwing Lair: Blackhand's Command (quest 7761, the orb in Upper Blackrock Spire) is the
    -- attunement; the quest is in the guide's data, so "Guide-moi" works for both factions.
    { id = 12, k = "bwl", quest = 7761, dg = { "BlackwingLair" }, attune = true, each = true, icon = "Interface\\Icons\\INV_Misc_Head_Dragon_Black" },
}
-- shown in this order: by level inside each section
local SHOW = { "scarlet", "gnome", "mara", "brd", "prison", "dm", "strat", "scholo", "ubrs", "bwl", "mc", "ony" }
local BY = {}
for _, k in ipairs(LIST) do BY[k.k] = k end
local NBITS = 24   -- room for new keys; anything above is ignored when received
local MAXMASK = 2 ^ NBITS - 1

-- the data of Curated.lua wins over the table above (items, bosses, whether it is a shortcut)
for _, k in ipairs(LIST) do
    for _, e in ipairs(root.KEYS and root.KEYS[k.dg[1]] or {}) do
        if k.item and e.item == k.item then
            k.opt = e.opt
            k.quest = k.quest or e.quest
            k.boss, k.bossn, k.src = k.boss or e.boss, k.bossn or e.bossn, k.src or e.src
        end
    end
    k.need = k.opt == nil
end
K.LIST, K.BY = LIST, BY

-- the raids the guide's data does not have yet
local RAID_NAME = { MoltenCore = { "Molten Core", "Cœur du Magma" }, BlackwingLair = { "Blackwing Lair", "Repaire de l'Aile noire" } }
local function DName(dkey)
    local rn = RAID_NAME[dkey]
    if rn and not (root.D and root.D[dkey]) then return (GetLocale and GetLocale() == "frFR") and rn[2] or rn[1] end
    return root.DName and root.DName(dkey) or dkey
end
K.DName = DName

local function Call(f, ...)
    if type(f) ~= "function" then return end
    local r = { pcall(f, ...) }
    if r[1] then return unpack(r, 2) end
end
local function Secret(v) return issecretvalue ~= nil and issecretvalue(v) == true end
local function Num(v) if type(v) == "number" and not Secret(v) then return v end end

-- the chain this character's faction does (an Alliance character has its own for two keys)
local function Alliance()
    local f = Call(UnitFactionGroup, "player")
    return type(f) == "string" and not Secret(f) and f == "Alliance"
end
local function QuestOf(k)
    if k.aq and Alliance() then return k.aq end
    return k.quest
end
K.QuestOf = QuestOf

-- the key's name as the game writes it (the client's language), the English one until it is cached
function K.Name(k)
    if k.attune then return root.QName and root.QName(k.quest) or tostring(k.quest) end
    local n = (C_Item and Call(C_Item.GetItemNameByID, k.item)) or Call(GetItemInfo, k.item)
    if type(n) == "string" and not Secret(n) and n ~= "" then return n end
    return k.name
end
function K.Icon(k)
    if k.icon then return k.icon end
    local ic = (C_Item and Call(C_Item.GetItemIconByID, k.item)) or Call(GetItemIcon, k.item)
    if ic and not Secret(ic) then return ic end
    local d = root.D and root.D[k.dg[1]]
    return d and d.icon or "Interface\\Icons\\INV_Misc_Key_03"
end

-- bags, key ring and bank
local function Count(item)
    local f = (C_Item and C_Item.GetItemCount) or GetItemCount
    return Num(Call(f, item, true)) or 0
end

-- ---------------------------------------------------------------- where you stand
-- { state = "have" | "prog" | "todo" | "na", step, total, next = quest id, lvl = level it asks }
-- "na": the chain is not one this character can do (faction, class, race) or not in the data.
local function Chain(qid)
    local q = root.Q and root.Q[qid]
    if not q then return nil end
    if root.FactionOK and not root.FactionOK(q.fa) then return nil end
    local _, cls = UnitClass("player")
    if root.ClassOK and not root.ClassOK(q.c, cls) then return nil end
    return root.FullChain and root.FullChain(qid, cls) or nil
end
-- a chain the guide's data does not have (the Alliance side of two keys): started or not, from the
-- completed quests and the quest log; no steps, since the guide cannot name them
local function Unguided(k, log)
    for _, pid in ipairs(k.ac or {}) do
        if log[pid] or (root.IsDone and root.IsDone(pid)) then return { state = "prog", unguided = true } end
    end
    return { state = "todo", unguided = true }
end
function K.Status(k)
    local quest = QuestOf(k)
    if quest and root.IsDone and root.IsDone(quest) then return { state = "have" } end
    if k.item and Count(k.item) > 0 then return { state = "have" } end
    if not quest then return { state = "todo" } end
    local log = root.LogEntries and root.LogEntries() or {}
    local chain = Chain(quest)
    if not chain then
        if quest ~= k.quest and not (root.Q and root.Q[quest]) then return Unguided(k, log) end
        return { state = "na" }
    end
    local done, inLog, nextQ = 0, false, nil
    for _, pid in ipairs(chain) do
        if root.IsDone(pid) then done = done + 1
        else
            if log[pid] then inLog = true end
            nextQ = nextQ or pid
        end
    end
    nextQ = nextQ or quest
    if log[quest] then inLog = true end
    local total = #chain + 1
    local q = root.Q[nextQ]
    local st = { step = math.min(done + 1, total), total = total, next = nextQ, lvl = q and q.r }
    st.state = (done > 0 or inLog) and "prog" or "todo"
    return st
end

-- ---------------------------------------------------------------- the guide on one chain
-- A one-quest card, like the class quest cards (Picker.lua): a pseudo-dungeon whose only quest is
-- the key's, so the route walks its whole chain and nothing else. cq = "KEY" keeps it out of the
-- picker, the boss panel, the dungeon-entry offer and the group dungeon list, which all skip cq
-- cards; it goes in ORDER because the route's label is built from it.
local function CardKey(k, quest)
    quest = quest or QuestOf(k)
    return quest and ("KEY" .. quest) or nil
end
-- one card per chain in the data, both factions (an account has characters of both)
local function MakeCard(k, quest)
    local key, q = CardKey(k, quest), quest and root.Q[quest]
    if key and q and not root.D[key] then
        local dd = root.D[q.d] or {}
        root.D[key] = { key = key, n = k.attune and q.n or k.name, nf = k.attune and q.nf or nil,
            lvl = { q.r or q.l or 1, q.l or q.r or 60 }, art = dd.art, nart = dd.nart, icon = K.Icon(k),
            e = dd.e, ed = dd.ed, inst = dd.inst, cq = "KEY", kc = k.k, home = q.d, q = { quest } }
        table.insert(root.ORDER, key)
    end
end
local function MakeCards()
    if not (root.D and root.Q and root.ORDER) then return end
    for _, k in ipairs(LIST) do
        if k.quest then MakeCard(k, k.quest) end
        if k.aq then MakeCard(k, k.aq) end
    end
end
-- at load: a route saved on a key card has to find it at login
MakeCards()
K.CardKey = CardKey

local function OnlyCard(sel, key)
    local n = 0
    for x, v in pairs(sel or {}) do if v then n = n + 1; if x ~= key then return false end end end
    return n == 1
end
-- what the button does for this key: "guide" (start), "back" (this route runs), "summary" (another
-- route runs: the summary shows what changes), "gps" (a boss drop), or nil
function K.GuideMode(k)
    local key = CardKey(k)
    if key and root.D and root.D[key] and Chain(QuestOf(k)) then
        local sel = WLDTDB and WLDTDB.sel
        if root.route and sel and sel[key] and OnlyCard(sel, key) then return "back" end
        if root.route and sel and next(sel) then return "summary" end
        return "guide"
    end
    if k.src and root.D and root.D[k.src] and root.D[k.src].e then return "gps" end
end
function K.Guide(k)
    local mode = K.GuideMode(k)
    if not mode then return end
    if mode == "gps" then
        local d = root.D[k.src]
        local G = WP.GPS
        if G and G.GoPoint and d.e and d.e.m then
            -- a Writs or city tour keeps the arrow (GoPoint gives way to it): say so instead
            if G.Source and G.Source() == "writs" and G.Active and G.Active() then
                WP.Print(string.format(L("%s tombe sur %s, dans %s. Le GPS guide déjà ta tournée : arrête-la pour aller à l'entrée."), K.Name(k), k.bossn or "?", DName(k.src)))
                return mode
            end
            G.GoPoint(d.e.m, d.e.x, d.e.y, DName(k.src), "keys")
            WP.Print(string.format(L("%s tombe sur %s, dans %s : le GPS te mène à l'entrée."), K.Name(k), k.bossn or "?", DName(k.src)))
        else
            WP.Print(string.format(L("Pas d'entrée connue pour %s."), DName(k.src)))
        end
        return mode
    end
    if WP.ModuleOff and WP.ModuleOff("dungeons") then return end
    local key = CardKey(k)
    -- the card shows the key's name in the client's language once the game has it
    local d = root.D[key]
    if not k.attune then d.n = K.Name(k); d.nf = nil end
    if mode == "back" then
        if root.ShowGuide then root.ShowGuide() end
    elseif mode == "summary" then
        -- another route runs: its summary says what starting this one replaces, and starts it
        if root.ShowSummary then root.ShowSummary({ key }, true) end
    else
        WLDTDB.sel = WLDTDB.sel or {}
        for x in pairs(WLDTDB.sel) do WLDTDB.sel[x] = nil end
        WLDTDB.sel[key] = true
        if root.StartGuide then root.StartGuide() end
    end
    if K.Hide then K.Hide() end
    return mode
end

-- ---------------------------------------------------------------- sharing with the guild
local PREFIX = "WLHkey"
local CI = C_ChatInfo
local Register = (CI and CI.RegisterAddonMessagePrefix) or RegisterAddonMessagePrefix
local SendRaw = (CI and CI.SendAddonMessage) or SendAddonMessage
if Register then pcall(Register, PREFIX) end

local function Me() return (UnitName("player")) end
local function Short(n) return n and (n:gsub("[%- ].*$", "")) end
local function On() return not WP.ModuleOn or WP.ModuleOn("keys") end
function K.ShareOn() return WLWritsDB and WLWritsDB.keysShare ~= false end
function K.SetShare(v)
    WLWritsDB.keysShare = v and true or false
    if v then K.Share(true); return end
    -- sharing off: tell the guild once that we have nothing, so the members' tabs drop our name
    -- now rather than after 90 days (every copy, old ones included, reads this line)
    if IsInGuild and IsInGuild() and SendRaw then pcall(SendRaw, PREFIX, "H|1|0|0", "GUILD") end
end

local function Bit(id) return 2 ^ (id - 1) end
local function Has(mask, id) return math.floor((tonumber(mask) or 0) / Bit(id)) % 2 == 1 end
K.Has = Has
-- my keys as two numbers: owned, chain started
function K.Masks()
    local o, p = 0, 0
    for _, k in ipairs(LIST) do
        local st = K.Status(k)
        if st.state == "have" then o = o + Bit(k.id) elseif st.state == "prog" then p = p + Bit(k.id) end
    end
    return o, p
end
-- the message this copy sends: "H|1|owned|started" (1 = the format; fields added later are ignored)
function K.Message()
    local o, p = K.Masks()
    return string.format("H|1|%d|%d", o, p)
end

-- the board of the current guild (WLWritsDB is account-wide: alts can be in other guilds)
local function Board()
    local g = GetGuildInfo and GetGuildInfo("player")
    if not g or Secret(g) then return {}, false end
    local key = g .. "-" .. (GetRealmName and GetRealmName() or "")
    WLWritsDB.keysBy = WLWritsDB.keysBy or {}
    WLWritsDB.keysBy[key] = WLWritsDB.keysBy[key] or {}
    return WLWritsDB.keysBy[key], true
end
K.Board = Board

-- a mask has at most 8 digits (2^24 - 1 has 8): anything longer did not come from WL Helper
local function Clamp(v)
    if type(v) ~= "string" or #v > 8 then return nil end
    v = tonumber(v)
    if not v or v ~= v or v < 0 then return nil end
    v = math.floor(v)
    if v > MAXMASK then v = v % (MAXMASK + 1) end
    return v
end
-- a line from another member; anything that does not look right is dropped
function K.OnMessage(msg, sender)
    if type(msg) ~= "string" or #msg > 250 or type(sender) ~= "string" then return end
    sender = Short(sender)
    if not sender or sender == "" or #sender > 48 or sender:find("[|%c]") then return end
    if msg == "R" then
        -- every copy in the guild hears the same request: answering a few seconds apart spreads them
        if C_Timer and C_Timer.After then C_Timer.After(2 + math.random() * 6, function() K.Share() end) else K.Share() end
        return
    end
    local o, p = msg:match("^H|%d+|(%d+)|(%d+)")
    if not o then return end
    o, p = Clamp(o), Clamp(p)
    if not (o and p) then return end
    local b, known = Board()
    if not known then return end
    b[sender] = { o = o, p = p, t = time() }
    if K.Refresh then K.Refresh() end
end

local lastSent, lastMsg, queued = 0, nil, false
function K.Share(force)
    if not (On() and K.ShareOn() and IsInGuild and IsInGuild() and SendRaw) then return end
    local msg = K.Message()
    local b, known = Board()
    if known then
        local o, p = msg:match("^H|%d+|(%d+)|(%d+)")
        b[Me()] = { o = tonumber(o), p = tonumber(p), t = time() }
    end
    if not force and msg == lastMsg and GetTime() - lastSent < 300 then return end
    if not force and GetTime() - lastSent < 20 then
        if not queued and C_Timer and C_Timer.After then
            queued = true
            C_Timer.After(21 - (GetTime() - lastSent), function() queued = false; K.Share(true) end)
        end
        return
    end
    lastSent, lastMsg = GetTime(), msg
    pcall(SendRaw, PREFIX, msg, "GUILD")
end
local askedAt = -1000
function K.Ask()
    if not (On() and IsInGuild and IsInGuild() and SendRaw) or GetTime() - askedAt < 60 then return end
    askedAt = GetTime()
    pcall(SendRaw, PREFIX, "R", "GUILD")
end

-- the guild's roster by name: { class, online } (empty until the game sent it)
local function Roster()
    local out = {}
    if not (IsInGuild and IsInGuild() and GetNumGuildMembers and GetGuildRosterInfo) then return out end
    for i = 1, (Num(Call(GetNumGuildMembers)) or 0) do
        local name, _, _, _, _, _, _, _, online, _, class = GetGuildRosterInfo(i)
        if type(name) == "string" and not Secret(name) then
            out[Short(name)] = { class = class, online = (not Secret(online)) and online and true or false }
        end
    end
    return out
end
-- { have = { names }, prog = { names } } for one key, online members first, then by name; members
-- who left the guild are skipped once the roster is known
local function Holders(k, roster)
    roster = roster or Roster()
    local rosterKnown = next(roster) ~= nil
    local have, prog = {}, {}
    local b = Board()
    local me = Me()
    -- my own line is read live, not from the last message
    local mine = K.Status(k).state
    if mine == "have" then have[#have + 1] = me elseif mine == "prog" then prog[#prog + 1] = me end
    for name, e in pairs(b) do
        if name ~= me and type(e) == "table" and (not rosterKnown or roster[name]) then
            if Has(e.o, k.id) then have[#have + 1] = name elseif Has(e.p, k.id) then prog[#prog + 1] = name end
        end
    end
    local function on(n) return n == me or (roster[n] and roster[n].online) end
    local function sort(a, b2)
        local oa, ob = on(a) and true or false, on(b2) and true or false
        if oa ~= ob then return oa end
        return a < b2
    end
    table.sort(have, sort); table.sort(prog, sort)
    return { have = have, prog = prog }, roster
end
K.Holders = Holders

-- the keys an instance asks for (the one that gets you in first)
local function KeysFor(dkey)
    local out = {}
    for _, k in ipairs(LIST) do
        for _, d in ipairs(k.dg) do if d == dkey then out[#out + 1] = k end end
    end
    table.sort(out, function(a, b) if a.need ~= b.need then return a.need end return a.id < b.id end)
    return out
end
K.KeysFor = KeysFor

-- Who in the guild (with WL Helper, you included) has the key of an instance.
-- -> { names }, { needed = the key is needed to get in, each = every player needs their own,
--      key = its name, k = the entry } ; nil when the instance asks for no key
function WP.Keys.WhoHas(dkey)
    local k = KeysFor(dkey)[1]
    if not k then return nil end
    local h = Holders(k)
    return h.have, { needed = k.need, each = k.each and true or false, key = K.Name(k), k = k }
end

-- One line for a group of the group module: title "Scholomance" or "Scholomance + Stratholme"
-- (dungeon names as the guide writes them), names = the organizer and those signed up.
-- Speaks only of the keys needed to get in, and only from what the members' copies told.
function WP.Keys.EventWarning(title, names)
    if type(title) ~= "string" or type(names) ~= "table" then return nil end
    local parts = {}
    for p in (title .. " + "):gmatch("(.-)%s+%+%s+") do parts[#parts + 1] = p end
    local seen = {}
    for _, part in ipairs(parts) do
        local dkey
        for key, d in pairs(root.D or {}) do
            if not d.cq and (DName(key) == part or d.n == part or d.nf == part) then dkey = key; break end
        end
        local k = dkey and KeysFor(dkey)[1]
        if k and k.need and not seen[k.k] then
            seen[k.k] = true
            local h = Holders(k)
            local has = {}
            for _, n in ipairs(h.have) do has[n] = true end
            if k.each then
                local missing = {}
                for _, n in ipairs(names) do if type(n) == "string" and not has[n] then missing[#missing + 1] = n end end
                table.sort(missing)
                if #missing > 0 then return string.format(L("Il manque encore %s à : %s."), K.Name(k), table.concat(missing, ", ")) end
            else
                local any = false
                for _, n in ipairs(names) do if has[n] then any = true end end
                if not any and #names > 0 then return string.format(L("Aucun inscrit n'a %s d'après WL Helper : il en faut une pour entrer."), K.Name(k)) end
            end
        end
    end
    return nil
end

-- ---------------------------------------------------------------- in words
local function WhatText(k)
    local d = DName(k.dg[1])
    if k.attune then return string.format(L("Téléportation vers %s"), d) end
    if k.need then return string.format(L("Pour entrer dans %s"), d) end
    if k.opt == "doors" then return string.format(L("Ouvre les portes de %s"), d) end
    return string.format(L("Raccourci dans %s"), d)
end
local function StepName(qid, lvl)
    local n = root.QName and root.QName(qid) or tostring(qid)
    local mine = Num(UnitLevel and UnitLevel("player")) or 60
    if lvl and lvl > mine then return string.format(L("%s (se prend dès le niv. %d)"), n, lvl) end
    return n
end
-- the status line and its colour
function K.StateText(k, st)
    st = st or K.Status(k)
    if st.state == "have" then return k.attune and L("Accès débloqué") or L("Tu l'as"), C.ok end
    if st.state == "na" then return L("Pas dans le guide pour ce personnage."), C.muted end
    if st.unguided then
        if st.state == "prog" then return L("Commencée. La chaîne de l'Alliance n'est pas encore dans le guide."), C.text end
        local info = k.am and C_Map and Call(C_Map.GetMapInfo, k.am)
        local zone = type(info) == "table" and type(info.name) == "string" and not Secret(info.name) and info.name or "?"
        return string.format(L("La chaîne de l'Alliance n'est pas encore dans le guide. Elle commence dans %s."), zone), C.muted
    end
    if st.state == "prog" then return string.format(L("Étape %d sur %d : %s"), st.step, st.total, StepName(st.next, st.lvl)), C.text end
    if k.quest then return string.format(L("Pas commencée. Première étape : %s"), StepName(st.next, st.lvl)), C.muted end
    return string.format(L("Tombe sur %s, dans %s"), k.bossn or "?", DName(k.src or k.dg[1])), C.muted
end

-- ---------------------------------------------------------------- the passport window
-- 420 wide (a single list), sized to its content (DESIGN 3.2).
local W, PAD = 420, 16
local CW = W - 2 * PAD
local win, sa, rows, heads, measure = nil, nil, {}, {}, nil

local function GuideTip(k)
    local mode = K.GuideMode(k)
    if mode == "back" then return L("Clic : revenir au guide en cours") end
    if mode == "summary" then return L("Clic : voir ce que la route remplace") end
    if mode == "gps" then return string.format(L("Clic : le GPS te mène à l'entrée de %s"), DName(k.src)) end
    return L("Clic : lancer le guide sur cette chaîne")
end
local function GuildLine(k)
    local h = Holders(k)
    local others = {}
    for _, n in ipairs(h.have) do if n ~= Me() then others[#others + 1] = n end end
    if #others == 0 then return L("Personne dans la guilde pour l'instant.") end
    return string.format(L("Dans la guilde : %s"), table.concat(others, ", "))
end
local function RowTip(r)
    local k = r.k
    if not k then return nil end
    local t = { K.Name(k), WhatText(k) }
    local st = K.Status(k)
    t[#t + 1] = (K.StateText(k, st))
    if k.need then t[#t + 1] = k.each and L("Chaque joueur du raid a besoin de la sienne.") or L("Un seul membre du groupe en a besoin.") end
    if st.total then t[#t + 1] = st.total == 1 and L("La chaîne compte 1 quête.") or string.format(L("La chaîne compte %d quêtes."), st.total) end
    if IsInGuild and IsInGuild() then t[#t + 1] = GuildLine(k) end
    if r.btn:IsShown() then t[#t + 1] = GuideTip(k) end
    return t
end

local function KeyRow(parent)
    local r = CreateFrame("Button", nil, parent)
    r.wlOwned = true
    r:SetWidth(CW)
    r.bg = S.Solid(r, "BACKGROUND", C.cardFill); r.bg:SetAllPoints()
    r.hl = S.Solid(r, "BORDER", C.hoverFill); r.hl:SetAllPoints(); r.hl:SetAlpha(0)
    S.Border(r, C.cardEdge)
    r.iconFrame = CreateFrame("Frame", nil, r)
    r.iconFrame:SetSize(30, 30); r.iconFrame:SetPoint("TOPLEFT", 8, -8)
    r.icon = r.iconFrame:CreateTexture(nil, "ARTWORK"); r.icon:SetAllPoints()
    S.Border(r.iconFrame, C.cardEdge)
    r.name = S.Text(r, F.body, C.fg)
    r.what = S.Text(r, F.meta, C.muted)
    r.state = S.Text(r, F.meta, C.text)
    r.btn = S.Button(r, L("Guide-moi"), 0, 24, "secondary", function() if r.k then K.Guide(r.k) end end,
        function() return r.k and { L("Guide-moi"), GuideTip(r.k) } end)
    r:SetScript("OnEnter", function(self)
        root.Tween(self, self.hov or 0, 1, 0.10, function(v) self.hov = v; self.hl:SetAlpha(v) end)
        local t = RowTip(self)
        if t then S.Tip(self, t) end
    end)
    r:SetScript("OnLeave", function(self)
        root.Tween(self, self.hov or 0, 0, 0.10, function(v) self.hov = v; self.hl:SetAlpha(v) end)
        S.HideTip()
    end)
    r:SetScript("OnClick", function(self) if self.k and self.btn:IsShown() then K.Guide(self.k) end end)
    function r:Set(k)
        self.k = k
        S.Painted(self.icon, K.Icon(k))
        local st = K.Status(k)
        self.name:SetText(K.Name(k))
        self.what:SetText(WhatText(k))
        local txt, col = K.StateText(k, st)
        self.state:SetText(txt)
        self.state:SetTextColor(col[1], col[2], col[3])
        local have = st.state == "have"
        self.btn:SetShown(not have and K.GuideMode(k) ~= nil)
        if self.icon.SetDesaturated then pcall(self.icon.SetDesaturated, self.icon, not have and st.state ~= "prog") end
    end
    function r:Fit()
        local x = 8 + 30 + 8
        local right = 12
        if self.btn:IsShown() then
            local bw = Num(self.btn:GetWidth()) or 90
            self.btn:ClearAllPoints(); self.btn:SetPoint("RIGHT", -12, 0)
            right = right + bw + 8
        end
        local tw = CW - x - right
        local y = 8
        self.name:ClearAllPoints(); self.name:SetPoint("TOPLEFT", x, -y)
        y = y + S.FitText(self.name, 2, tw, self)
        y = y + 3
        self.what:ClearAllPoints(); self.what:SetPoint("TOPLEFT", x, -y)
        y = y + S.FitText(self.what, 2, tw, self)
        y = y + 3
        self.state:ClearAllPoints(); self.state:SetPoint("TOPLEFT", x, -y)
        y = y + S.FitText(self.state, 2, tw, self)
        local h = math.max(8 + 30 + 8, math.ceil(y + 8))
        self:SetHeight(h)
        return h
    end
    return r
end

local function Subtitle()
    local n = 0
    for _, k in ipairs(LIST) do if K.Status(k).state == "have" then n = n + 1 end end
    if n == 0 then return string.format(L("Aucune clé pour l'instant (0 sur %d)"), #LIST) end
    if n == 1 then return string.format(L("1 clé sur %d"), #LIST) end
    return string.format(L("%d clés sur %d"), n, #LIST)
end

local function Render()
    if not (win and win:IsShown()) then return end
    win.subtitle:SetText(Subtitle())
    local y, i = 0, 0
    for s, sec in ipairs({ { true, L("Pour entrer") }, { false, L("Raccourcis et portes") } }) do
        local h = heads[s]
        h:ClearAllPoints(); h:SetPoint("TOPLEFT", 0, -y); h:SetPoint("TOPRIGHT", sa.child, "TOPRIGHT", 0, -y)
        y = y + (Num(h:GetHeight()) or 32) + 8
        for _, key in ipairs(SHOW) do
            local k = BY[key]
            if k.need == sec[1] then
                i = i + 1
                local r = rows[i]
                if not r then r = KeyRow(sa.child); rows[i] = r end
                r:Set(k); r:Show()
                r:ClearAllPoints(); r:SetPoint("TOPLEFT", 0, -y)
                y = y + r:Fit() + 2
            end
        end
        if s == 1 then y = y + 16 - 2 end
    end
    for j = i + 1, #rows do rows[j]:Hide() end
    sa.child:SetWidth(CW)
    sa:SetContentHeight(y)
    win:FitHeight(y)
end
K.Render = Render

local function Build()
    win = S.Window("WLHelperKeys", W, 400, L("Passeport des clés"), nil, WLWritsDB, "keysPos",
        { header = S.HEADER_H, minH = 200 })
    -- who has which key in the guild: the Guild window's tab
    win:AddHeaderButton(S.IconButton(win.header, "group", 28,
        function() return { L("Qui a la clé dans la guilde ?"), L("Les membres qui ont WL Helper partagent leurs clés."), L("Clic : ouvrir l'onglet de la guilde") } end,
        function() K.ShowGuild() end))
    sa = S.ScrollArea(win)
    sa:SetPoint("TOPLEFT", PAD, -(win:ContentTop() + 12))
    sa:SetPoint("BOTTOMRIGHT", -PAD, 12)
    heads[1] = S.SectionHeader(sa.child, L("Pour entrer"), nil, nil, nil, true)
    heads[2] = S.SectionHeader(sa.child, L("Raccourcis et portes"), nil, nil, nil, true)
    win:SetScript("OnShow", function()
        K.Ask()
        Render()
        if C_Timer and C_Timer.After then C_Timer.After(0, Render) end
    end)
end

function K.Show()
    if WP.ModuleOff and WP.ModuleOff("keys") then return end
    if not win then Build() end
    win:Show(); win:Raise()
    Render()
end
function K.Hide() if win then win:Hide() end end
function K.Toggle()
    if win and win:IsShown() then win:Hide() else K.Show() end
end
function K.ShowGuild()
    if WP.ModuleOff and WP.ModuleOff("guild") then return end
    if WP.ShowGuildTab then WP.ShowGuildTab("keys") end
end
WP.ToggleKeys = K.Toggle

-- ---------------------------------------------------------------- the guild tab
-- Drawn into the page Guild.lua gives (its own tab); returns the content height for FitHeight.
local gt = {}
local function NameHex(name, roster)
    local r = roster[name]
    if name == Me() then
        local _, cls = UnitClass("player")
        r = { class = cls, online = true }
    end
    local c = r and r.class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[r.class]
    if r and r.online and c then return string.format("|cff%02x%02x%02x", math.floor(c.r * 255), math.floor(c.g * 255), math.floor(c.b * 255)) .. name .. "|r" end
    return S.Hex(C.muted) .. name .. "|r"
end
-- as many names as fit on about two lines of `width`, then "and N more"
local function NamesLine(names, roster, width)
    if #names == 0 then return nil end
    local shown = {}
    for i, n in ipairs(names) do
        local try = table.concat(shown, ", ") .. (#shown > 0 and ", " or "") .. NameHex(n, roster)
        local rest = #names - i
        local full = rest > 0 and string.format(L("%s et %d autres"), try, rest) or try
        gt.measure:SetText(full)
        if #shown > 0 and root.TextWidth(gt.measure) > width * 1.8 then break end
        shown[#shown + 1] = NameHex(n, roster)
    end
    gt.measure:SetText("")
    local s = table.concat(shown, ", ")
    if #shown < #names then s = string.format(L("%s et %d autres"), s, #names - #shown) end
    return s
end
local function GuildRowTip(k, h, roster)
    local t = { K.Name(k), WhatText(k) }
    local on, off = {}, {}
    for _, n in ipairs(h.have) do
        if n == Me() or (roster[n] and roster[n].online) then on[#on + 1] = n else off[#off + 1] = n end
    end
    if #h.have == 0 then t[#t + 1] = L("Personne pour l'instant") end
    if #on > 0 then t[#t + 1] = string.format(L("En ligne : %s"), table.concat(on, ", ")) end
    if #off > 0 then t[#t + 1] = string.format(L("Hors ligne : %s"), table.concat(off, ", ")) end
    if #h.prog > 0 then t[#t + 1] = string.format(L("Chaîne commencée : %s"), table.concat(h.prog, ", ")) end
    if k.need then t[#t + 1] = k.each and L("Chaque joueur du raid a besoin de la sienne.") or L("Un seul membre du groupe en a besoin.") end
    t[#t + 1] = L("Clic : ouvrir ton passeport des clés")
    return t
end

function K.RenderGuildTab(page, width, pad)
    width, pad = width or 640, pad or 16
    local cw = width - 2 * pad
    if not gt.built then
        gt.built = true
        gt.intro = S.Text(page, F.body, C.text)
        gt.measure = S.Text(page, F.meta, C.muted); gt.measure:SetWordWrap(false); gt.measure:Hide()
        gt.sa = S.ScrollArea(page)
        gt.rows = {}
        gt.none = S.EmptyState(page, "group", L("Tu n'es dans aucune guilde"),
            L("Les clés de la guilde apparaîtront ici dès que tu rejoins une guilde."))
        gt.none:Hide()
    end
    if not (IsInGuild and IsInGuild()) then
        gt.intro:Hide(); gt.sa:Hide()
        gt.none:Show()
        return 12 + gt.none:Fit()
    end
    gt.none:Hide(); gt.intro:Show(); gt.sa:Show()
    gt.intro:SetText(L("Les clés des membres qui ont WL Helper, ceux en ligne d'abord."))
    gt.intro:ClearAllPoints(); gt.intro:SetPoint("TOPLEFT", pad, -12)
    local y = 12 + S.FitText(gt.intro, 2, cw, page) + 12
    local roster = Roster()
    local list = {}
    for _, key in ipairs(SHOW) do if BY[key].need then list[#list + 1] = BY[key] end end
    for _, key in ipairs(SHOW) do if not BY[key].need then list[#list + 1] = BY[key] end end
    local listH = 0
    for i, k in ipairs(list) do
        local r = gt.rows[i]
        if not r then
            r = S.ListRow(gt.sa.child, { density = "reading", onClick = function() K.Show() end })
            r.valueW = 32
            gt.rows[i] = r
        end
        local h = Holders(k, roster)
        local names = NamesLine(h.have, roster, cw - 8 - 30 - 8 - 12 - 32 - 8)
        r:Set({ icon = K.Icon(k), name = K.Name(k) .. "  " .. S.Hex(C.muted) .. WhatText(k) .. "|r",
            detail = names or L("Personne pour l'instant"), value = tostring(#h.have),
            tip = GuildRowTip(k, h, roster) })
        r:SetWidth(cw)
        r:ClearAllPoints(); r:SetPoint("TOPLEFT", 0, -listH)
        r:Show()
        listH = listH + r:Fit(cw) + 2
    end
    for j = #list + 1, #gt.rows do gt.rows[j]:Hide() end
    gt.sa:ClearAllPoints()
    gt.sa:SetPoint("TOPLEFT", page, "TOPLEFT", pad, -y)
    gt.sa:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -pad, 12)
    gt.sa.child:SetWidth(cw)
    gt.sa:SetContentHeight(listH)
    return y - 12 + listH
end
function K.GuildTip()
    return { L("Qui a la clé ?"), L("Les clés des membres qui ont WL Helper, ceux en ligne d'abord."),
        L("Les membres qui ont WL Helper partagent leurs clés.") }
end

local function RefreshAll()
    Render()
    if WP.RefreshGuild then WP.RefreshGuild() end
end
K.Refresh = RefreshAll

-- ---------------------------------------------------------------- events
local ev = CreateFrame("Frame")
pcall(ev.RegisterEvent, ev, "PLAYER_LOGIN")
pcall(ev.RegisterEvent, ev, "CHAT_MSG_ADDON")
local pending = false
-- bags and quests change often: one look a second later is enough
local function Changed()
    if pending then return end
    pending = true
    local function go()
        pending = false
        if win and win:IsShown() then Render() end
        K.Share()
    end
    if C_Timer and C_Timer.After then C_Timer.After(1, go) else go() end
end
ev:SetScript("OnEvent", function(self, e, prefix, msg, channel, sender)
    if not WLWritsDB then return end
    if e == "PLAYER_LOGIN" then
        MakeCards()
        for _, x in ipairs({ "BAG_UPDATE_DELAYED", "QUEST_TURNED_IN", "QUEST_ACCEPTED", "QUEST_REMOVED", "GUILD_ROSTER_UPDATE" }) do
            pcall(self.RegisterEvent, self, x)
        end
        -- members gone quiet for 90 days are forgotten
        for _, b in pairs(WLWritsDB.keysBy or {}) do
            for name, x in pairs(b) do if type(x) ~= "table" or time() - (tonumber(x.t) or 0) > 90 * 86400 then b[name] = nil end end
        end
        if C_Timer and C_Timer.After then
            C_Timer.After(20, function() K.Share(true) end)
            C_Timer.After(30, function() K.Ask() end)
        end
    elseif e == "CHAT_MSG_ADDON" then
        if prefix == PREFIX and channel == "GUILD" and type(sender) == "string" then
            local who = Short(sender)
            if who ~= Me() and On() then K.OnMessage(msg, who) end
        end
    elseif e == "GUILD_ROSTER_UPDATE" then
        -- the Guild window refreshes itself on this event
    elseif On() then
        Changed()
    end
end)
