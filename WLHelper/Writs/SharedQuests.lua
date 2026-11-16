-- Writs/SharedQuests.lua: "Quêtes en commun" / "Shared quests".
--
-- Guild members who have WL Helper tell the guild which DUNGEON quests (ns.Q entries with a
-- dungeon) sit in their quest log, as a compact list of quest ids on our own addon prefix. The
-- window lists, per dungeon where you have quests, the members who have quests of that dungeon
-- too: online first, with "Grouper" (invites the online ones) and "Chuchoter" on each member.
--
-- Why only dungeon quests: they are what a group is formed for, and the list stays tiny (a quest
-- log holds at most a few dozen quests, a dungeon quest id is 4-5 digits).
-- Privacy: a switch "Partager mes quêtes de donjon" (on by default, in Settings); turning it off
-- sends an empty list once so the guild forgets yours. Nothing else about the character travels.
-- The whole module follows the Guild module's switch (WP.ModuleOn("guild")).
--
-- Protocol (prefix "WLHshq", GUILD channel only, every message < 255 bytes):
--   Q|seq|i|n|id,id,...   part i of n of my list (n <= 8); n = 1 with no ids = "I have none"
--   R                     "tell me your lists" (sent once after login)
-- Unknown kinds and extra fields are ignored; ids are kept only when they are dungeon quests of
-- this addon's data, at most MAX_IDS per member.
--
-- Hooks for other modules (the dungeon picker, the summary):
--   WP.Shared.ForDungeon(dkey) -> members { name, online, class, level, zone, quests, common, t }
--   WP.Shared.Count(dkey)      -> total, online
--   WP.Shared.Dungeons()       -> the window's list
--   WP.Shared.OnChange(fn)     -> fn() after a list arrives or changes
--   WP.Shared.Show(), Hide(), Toggle(), Refresh(), GetShare(), SetShare(on)
local ADDON, root = ...
root.Writs = root.Writs or {}
local ns = root.Writs
local WP = ns.WP
local L = ns.L
local S = ns.S
local C = S.C
local F = S.F

ns.AddEnglish({
    -- the window
    ["Quêtes en commun"] = "Shared quests",
    ["1 donjon en commun"] = "1 shared dungeon",
    ["%d donjons en commun"] = "%d shared dungeons",
    ["Grouper"] = "Group up",
    ["Invités"] = "Invited",
    ["Chuchoter"] = "Whisper",
    ["Personne de ce donjon n'est en ligne."] = "Nobody from this dungeon is online.",
    ["Hors ligne : ton message ne partirait pas."] = "Offline: your message would not go through.",
    ["Invite dans ton groupe : %s."] = "Invites to your group: %s.",
    ["%s fait aussi des quêtes de ce donjon."] = "%s is also doing quests in this dungeon.",
    ["%s font aussi des quêtes de ce donjon."] = "%s are also doing quests in this dungeon.",
    [" et "] = " and ",
    [" et 1 autre"] = " and 1 other",
    [" et %d autres"] = " and %d others",
    ["1 quête en commun"] = "1 quest in common",
    ["%d quêtes en commun"] = "%d quests in common",
    ["D'autres quêtes de ce donjon"] = "Other quests in this dungeon",
    ["Hors ligne"] = "Offline",
    ["En ligne"] = "Online",
    ["Ses quêtes de ce donjon :"] = "Their quests in this dungeon:",
    ["%s (toi aussi)"] = "%s (you too)",
    ["Liste reçue %s."] = "List received %s.",
    ["à l'instant"] = "just now",
    ["il y a %d min"] = "%d min ago",
    ["il y a %d h"] = "%d h ago",
    ["hier"] = "yesterday",
    ["il y a %d j"] = "%d days ago",
    ["Invité"] = "Invited",
    -- empty states
    ["Tu n'es dans aucune guilde"] = "You are not in a guild",
    ["Les quêtes de donjon de la guilde apparaîtront ici dès que tu rejoins une guilde."] =
        "Your guild's dungeon quests will show up here as soon as you join a guild.",
    ["Aucune quête de donjon dans ton journal"] = "No dungeon quests in your log",
    ["Prends une quête de donjon : les membres qui ont la même apparaîtront ici."] = "Pick up a dungeon quest: members who have it too will show up here.",
    ["Personne d'autre n'a ces quêtes pour l'instant"] = "Nobody else has these quests yet",
    ["Seuls les membres qui ont WL Helper partagent leurs quêtes de donjon."] = "Only members who have WL Helper share their dungeon quests.",
    -- footer and settings
    ["Tu partages tes quêtes de donjon avec la guilde."] = "You share your dungeon quests with the guild.",
    ["Tu ne partages pas tes quêtes de donjon (Réglages > Général > Guilde)."] = "You don't share your dungeon quests (Settings > General > Guild).",
    ["Partager mes quêtes de donjon"] = "Share my dungeon quests",
    ["Les membres de la guilde qui ont WL Helper voient quelles quêtes de donjon tu as, pour grouper. Rien d'autre n'est envoyé."] =
        "Guild members who have WL Helper see which dungeon quests you have, to group up. Nothing else is sent.",
    -- invites (the same words as the click helpers)
    ["%s est déjà dans ton groupe."] = "%s is already in your group.",
    ["Seul le chef du raid ou un assistant peut inviter : demande au chef de te passer assistant."] =
        "Only the raid leader or an assistant can invite: ask the leader to make you an assistant.",
    ["Seul le chef du groupe peut inviter : demande-lui d'inviter %s ou de te passer chef."] =
        "Only the party leader can invite: ask them to invite %s or to make you leader.",
    ["Ton groupe est plein : passe-le en raid pour inviter plus de monde."] = "Your party is full: convert it to a raid to invite more people.",
})

local Sh = {}
WP.Shared = Sh

local PREFIX = "WLHshq"
local MAX_IDS = 60          -- per member: far more than a quest log holds
local MAX_PARTS = 8
local PART_BYTES = 200      -- ids per part, so "Q|seq|i|n|" + ids stays far under 255
local MIN_GAP = 15          -- seconds between two of my sends
local KEEP_DAYS = 7         -- a list nobody refreshed for a week is dropped

local CI = C_ChatInfo
local Register = (CI and CI.RegisterAddonMessagePrefix) or RegisterAddonMessagePrefix
local SendRaw = (CI and CI.SendAddonMessage) or SendAddonMessage
if Register then pcall(Register, PREFIX) end

local function Secret(v) return issecretvalue ~= nil and issecretvalue(v) end
local function Num(v) return type(v) == "number" and not Secret(v) and v or nil end
local function Str(v) return type(v) == "string" and not Secret(v) and v or nil end
local function Me() return Str((UnitName("player"))) end
-- "Name-Realm" or "Name Realm": the name alone
local function Short(n) n = Str(n); return n and (n:gsub("[%- ].*$", "")) end
local function Now() return (time and time()) or 0 end
local function Clock() return (GetTime and Num(GetTime())) or 0 end
local function InGuild() return IsInGuild and IsInGuild() and true or false end
local function ModuleOn() return WP.ModuleOn("guild") end

-- ---------------------------------------------------------------- storage
local function DB()
    WLWritsDB.shared = type(WLWritsDB.shared) == "table" and WLWritsDB.shared or {}
    local d = WLWritsDB.shared
    if d.share == nil then d.share = true end
    if type(d.board) ~= "table" then d.board = {} end   -- [name] = { t = time(), q = { ids } }
    return d
end
Sh.DB = DB

-- ---------------------------------------------------------------- quest data
-- The dungeons a quest counts for (some count for two: the same item drops in both).
local function DungeonsOf(q)
    if type(q.ds) == "table" and #q.ds > 0 then return q.ds end
    return { q.d }
end
local function IsDungeonQuest(id)
    local q = id and root.Q and root.Q[id]
    return q and q.d and true or false
end
local function DungeonName(dkey) return root.DName and root.DName(dkey) or dkey end
local function QuestName(id) return root.QName and root.QName(id) or tostring(id) end

-- My dungeon quests, from the quest log (sorted, so the same log gives the same message).
local function MyIds()
    local out = {}
    local ok, log = pcall(root.LogEntries or function() return {} end)
    if not ok or type(log) ~= "table" then return out end
    for id in pairs(log) do
        if Num(id) and IsDungeonQuest(id) then out[#out + 1] = id end
    end
    table.sort(out)
    while #out > MAX_IDS do table.remove(out) end
    return out
end
Sh.MyIds = MyIds

-- ---------------------------------------------------------------- listeners
local listeners = {}
function Sh.OnChange(fn) if type(fn) == "function" then listeners[#listeners + 1] = fn end end
local function Changed()
    if Sh.Refresh then Sh.Refresh() end
    for _, fn in ipairs(listeners) do pcall(fn) end
end

-- ---------------------------------------------------------------- sending
-- Cuts the id list in parts of whole ids, each well under the 255-byte limit.
local function Parts(ids, seq)
    local chunks, cur = {}, {}
    local len = 0
    for _, id in ipairs(ids) do
        local s = tostring(id)
        if len > 0 and len + 1 + #s > PART_BYTES then
            chunks[#chunks + 1] = table.concat(cur, ","); cur, len = {}, 0
        end
        cur[#cur + 1] = s
        len = len + (len > 0 and 1 or 0) + #s
    end
    if #cur > 0 or #chunks == 0 then chunks[#chunks + 1] = table.concat(cur, ",") end
    while #chunks > MAX_PARTS do table.remove(chunks) end
    local out = {}
    for i, c in ipairs(chunks) do out[i] = "Q|" .. seq .. "|" .. i .. "|" .. #chunks .. "|" .. c end
    return out
end
Sh.Parts = Parts

local seq = (Now() % 90000) + 1
local lastSig, lastSent = nil, -1e9
local queued = nil
local function Send(msg)
    if SendRaw and #msg < 255 then pcall(SendRaw, PREFIX, msg, "GUILD") end
end
-- Sends my list when it changed (or when forced: an answer to "R", the first send of the session).
local function SendList(force)
    if not (ModuleOn() and InGuild()) then return false end
    local ids = DB().share and MyIds() or {}
    local sig = table.concat(ids, ",")
    if not force and sig == lastSig then return false end
    lastSig, lastSent = sig, Clock()
    seq = (seq % 99999) + 1
    for _, m in ipairs(Parts(ids, seq)) do Send(m) end
    return true
end
Sh.SendList = SendList
-- One send waits at a time; two sends are at least MIN_GAP apart (the log changes in bursts:
-- accept, objective, turn in).
local function Schedule(delay, force)
    if queued then queued.force = queued.force or force; return end
    queued = { force = force }
    local wait = math.max(delay or 0, lastSent + MIN_GAP - Clock())
    C_Timer.After(math.max(0, wait), function()
        local q = queued
        queued = nil
        if q then SendList(q.force) end
    end)
end
Sh.Schedule = Schedule

-- ---------------------------------------------------------------- receiving
local pending = {}   -- [name] = { seq, n, got = {}, count, ids = {}, seen = {}, at }
local PENDING_TTL = 30   -- a list whose parts stop coming is dropped after this many seconds
local function Split(msg)
    local f = {}
    for part in (msg .. "|"):gmatch("([^|]*)|") do f[#f + 1] = part end
    return f
end
local function Int(s, lo, hi)
    local v = tonumber(s)
    if not v or v ~= math.floor(v) or v < lo or v > hi then return nil end
    return v
end
local function Commit(who, ids)
    local board = DB().board
    if #ids == 0 then board[who] = nil else board[who] = { t = Now(), q = ids } end
    Changed()
end
local lastAnswer = -1e9
local function OnMessage(msg, who)
    if #msg > 254 then return end
    local f = Split(msg)
    if f[1] == "R" then
        -- someone just logged in: tell them, at most once a minute, a little later (not all at once)
        if DB().share and Clock() - lastAnswer > 60 then
            lastAnswer = Clock()
            Schedule(2 + (math.random and math.random(0, 6) or 3), true)
        end
    elseif f[1] == "Q" then
        local s, i, n = Int(f[2], 0, 99999), Int(f[3], 1, MAX_PARTS), Int(f[4], 1, MAX_PARTS)
        if not (s and i and n and i <= n) then return end
        -- parts of a list that never finished (the sender logged out halfway) do not stay forever
        local now = Clock()
        for name, old in pairs(pending) do if now - (old.at or 0) > PENDING_TTL then pending[name] = nil end end
        local p = pending[who]
        if not p or p.seq ~= s or p.n ~= n then
            p = { seq = s, n = n, got = {}, count = 0, ids = {}, seen = {}, at = now }
            pending[who] = p
        end
        if p.got[i] then return end
        p.got[i] = true
        p.count = p.count + 1
        for tok in (f[5] or ""):gmatch("[^,]+") do
            local id = Int(tok, 1, 9999999)
            if id and not p.seen[id] and IsDungeonQuest(id) and #p.ids < MAX_IDS then
                p.seen[id] = true
                p.ids[#p.ids + 1] = id
            end
        end
        if p.count >= p.n then
            pending[who] = nil
            table.sort(p.ids)
            Commit(who, p.ids)
        end
    end
end
Sh.OnMessage = OnMessage

-- Lists older than a week go: the member has not logged in with the addon since.
local function Prune()
    local board, now = DB().board, Now()
    for name, e in pairs(board) do
        if type(e) ~= "table" or type(e.q) ~= "table" or type(e.t) ~= "number" or now - e.t > KEEP_DAYS * 86400 then
            board[name] = nil
        end
    end
end
Sh.Prune = Prune

-- ---------------------------------------------------------------- privacy switch
function Sh.GetShare() return DB().share and true or false end
function Sh.SetShare(on)
    DB().share = on and true or false
    -- off: an empty list right away, so the guild forgets mine; on: my list
    if ModuleOn() and InGuild() then SendList(true) end
    Changed()
end

-- ---------------------------------------------------------------- the data the window shows
-- name -> { online, class, level, zone, full } from the game's guild roster; `full` keeps the realm
-- ("Name-Realm"), which inviting or whispering a member of another realm needs
local function Roster()
    local out, n = {}, 0
    if not (InGuild() and GetNumGuildMembers and GetGuildRosterInfo) then return out, 0 end
    for i = 1, (Num(GetNumGuildMembers()) or 0) do
        local name, _, _, level, _, zone, _, _, isOnline, _, class = GetGuildRosterInfo(i)
        local short = Short(name)
        if short then
            n = n + 1
            out[short] = { online = (not Secret(isOnline)) and isOnline and true or false, class = Str(class), level = Num(level),
                zone = Str(zone), full = Str(name) }
        end
    end
    return out, n
end

local function MineSet()
    local set = {}
    for _, id in ipairs(MyIds()) do set[id] = true end
    return set
end

-- Every member (not me) who has at least one quest of this dungeon, online first, then the most
-- quests in common, then the name. roster/mine are passed in when the caller already read them.
local function ForDungeon(dkey, roster, mine, rosterN)
    local out = {}
    if not dkey then return out end
    if not roster then roster, rosterN = Roster() end
    mine = mine or MineSet()
    local me = Me()
    for name, e in pairs(DB().board) do
        local r = roster[name]
        -- not in the roster any more (left the guild): hidden, once the roster is known
        if name ~= me and type(e) == "table" and type(e.q) == "table" and (r or (rosterN or 0) == 0) then
            local quests, common = {}, {}
            for _, id in ipairs(e.q) do
                local q = root.Q and root.Q[id]
                if q and q.d then
                    for _, k in ipairs(DungeonsOf(q)) do
                        if k == dkey then
                            quests[#quests + 1] = id
                            if mine[id] then common[#common + 1] = id end
                            break
                        end
                    end
                end
            end
            if #quests > 0 then
                out[#out + 1] = { name = name, full = r and r.full or name, online = r and r.online or false, class = r and r.class,
                    level = r and r.level, zone = r and r.zone, quests = quests, common = common, t = e.t }
            end
        end
    end
    table.sort(out, function(a, b)
        if a.online ~= b.online then return a.online end
        if #a.common ~= #b.common then return #a.common > #b.common end
        return a.name < b.name
    end)
    return out
end
function Sh.ForDungeon(dkey) return ForDungeon(dkey) end

function Sh.Count(dkey)
    local list = ForDungeon(dkey)
    local online = 0
    for _, m in ipairs(list) do if m.online then online = online + 1 end end
    return #list, online
end

-- The dungeons where I have at least one quest and at least one member has quests too: those
-- with someone online first (the most online first), then those with only offline members.
function Sh.Dungeons()
    local roster, rosterN = Roster()
    local mine = MineSet()
    local keys, seen = {}, {}
    for id in pairs(mine) do
        for _, k in ipairs(DungeonsOf(root.Q[id])) do
            if k and not seen[k] then seen[k] = true; keys[#keys + 1] = k end
        end
    end
    local out = {}
    for _, k in ipairs(keys) do
        local members = ForDungeon(k, roster, mine, rosterN)
        if #members > 0 then
            local online = 0
            for _, m in ipairs(members) do if m.online then online = online + 1 end end
            out[#out + 1] = { key = k, name = DungeonName(k), members = members, online = online }
        end
    end
    table.sort(out, function(a, b)
        if (a.online > 0) ~= (b.online > 0) then return a.online > 0 end
        if a.online ~= b.online then return a.online > b.online end
        return a.name < b.name
    end)
    return out, #keys
end

-- ---------------------------------------------------------------- actions
local function InGroupWith(name) return (UnitInParty and UnitInParty(name)) or (UnitInRaid and UnitInRaid(name)) end

-- Invites the online members given (with their realm when they have one); says why when the game
-- would refuse.
function Sh.Invite(names)
    local invite = (C_PartyInfo and C_PartyInfo.InviteUnit) or InviteUnit
    if type(invite) ~= "function" or type(names) ~= "table" then return 0 end
    local todo = {}
    for _, n in ipairs(names) do
        if type(n) == "string" and Short(n) ~= Me() then
            if InGroupWith(n) or InGroupWith(Short(n)) then WP.Print(string.format(L("%s est déjà dans ton groupe."), Short(n)), true)
            else todo[#todo + 1] = n end
        end
    end
    if #todo == 0 then return 0 end
    -- a party has no assistants: only its leader invites; in a raid, assistants can too
    if IsInRaid and IsInRaid() then
        if not (UnitIsGroupLeader("player") or (UnitIsGroupAssistant and UnitIsGroupAssistant("player"))) then
            WP.Print(L("Seul le chef du raid ou un assistant peut inviter : demande au chef de te passer assistant."), true); return 0
        end
    elseif IsInGroup and IsInGroup() and not UnitIsGroupLeader("player") then
        local shown = {}
        for i, n in ipairs(todo) do shown[i] = Short(n) end
        WP.Print(string.format(L("Seul le chef du groupe peut inviter : demande-lui d'inviter %s ou de te passer chef."), table.concat(shown, ", ")), true)
        return 0
    end
    local free
    if IsInRaid and IsInRaid() then free = 40 - (Num(GetNumGroupMembers and GetNumGroupMembers()) or 0)
    else free = (MAX_PARTY_MEMBERS or 4) - (Num(GetNumSubgroupMembers and GetNumSubgroupMembers()) or 0) end
    local done = 0
    for _, n in ipairs(todo) do
        if done >= free then
            WP.Print(L("Ton groupe est plein : passe-le en raid pour inviter plus de monde."), true)
            break
        end
        if pcall(invite, n) then done = done + 1 end
    end
    return done
end

function Sh.Whisper(name)
    if type(name) ~= "string" then return end
    if ChatFrame_OpenChat then ChatFrame_OpenChat("/w " .. name .. " ")
    elseif ChatFrameUtil and ChatFrameUtil.OpenChat then ChatFrameUtil.OpenChat("/w " .. name .. " ") end
end

-- ---------------------------------------------------------------- words
local function JoinNames(list)
    local n = #list
    if n == 0 then return "" end
    if n == 1 then return list[1] end
    if n <= 3 then return table.concat(list, ", ", 1, n - 1) .. L(" et ") .. list[n] end
    local rest = n - 2
    return table.concat(list, ", ", 1, 2) .. (rest == 1 and L(" et 1 autre") or string.format(L(" et %d autres"), rest))
end
Sh.JoinNames = JoinNames

local function Ago(t)
    local s = math.max(0, Now() - (t or 0))
    if s < 60 then return L("à l'instant") end
    if s < 3600 then return string.format(L("il y a %d min"), math.floor(s / 60)) end
    if s < 86400 then return string.format(L("il y a %d h"), math.floor(s / 3600)) end
    if s < 2 * 86400 then return L("hier") end
    return string.format(L("il y a %d j"), math.floor(s / 86400))
end

local function Sentence(members)
    local names = {}
    for _, m in ipairs(members) do names[#names + 1] = m.name end
    local who = JoinNames(names)
    return string.format(#names == 1 and L("%s fait aussi des quêtes de ce donjon.") or L("%s font aussi des quêtes de ce donjon."), who)
end
Sh.Sentence = Sentence

local function Detail(m)
    local a = #m.common == 1 and L("1 quête en commun")
        or (#m.common > 1 and string.format(L("%d quêtes en commun"), #m.common) or L("D'autres quêtes de ce donjon"))
    local b = m.online and (m.zone and m.zone ~= "" and m.zone or L("En ligne")) or L("Hors ligne")
    return a .. " · " .. b
end
Sh.Detail = Detail

local function ClassColor(class)
    local c = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
    return c and { c.r, c.g, c.b } or C.fg
end

-- ---------------------------------------------------------------- the window
-- 420 wide (a single list). The height follows the content; past 80 % of the screen the list
-- scrolls inside the window.
local W, PAD = 420, 16
local CW = W - 2 * PAD
local ROW_GAP = 2
local win, ui = nil, {}
local RefreshSoon   -- the throttled redraw, set with the events below

local function Place(obj, x, y) obj:ClearAllPoints(); obj:SetPoint("TOPLEFT", x, -y) end

-- A member: online dot, name in the class colour, a detail line, "Chuchoter" at the right.
local function MemberRow(parent)
    local r = CreateFrame("Frame", nil, parent)
    r.wlOwned = true
    r:SetWidth(CW)
    r:EnableMouse(true)
    r.bg = S.Solid(r, "BACKGROUND", C.cardFill); r.bg:SetAllPoints()
    r.hl = S.Solid(r, "BORDER", C.hoverFill); r.hl:SetAllPoints(); r.hl:SetAlpha(0)
    r.dot = S.Icon(r, "dot", 10, "ARTWORK", C.ok)
    r.name = S.Text(r, F.label, C.fg); r.name:SetWordWrap(false)
    r.detail = S.Text(r, F.meta, C.muted)
    r.whisper = S.Button(r, L("Chuchoter"), 0, 24, "secondary", function() if r.m then Sh.Whisper(r.m.full or r.m.name) end end)
    r.whisper:SetPoint("RIGHT", -12, 0)
    r:SetScript("OnEnter", function(self)
        self.hl:SetAlpha(1)
        local m = self.m
        if not m then return end
        local c = ClassColor(m.class)
        local lines = { { m.name, c[1], c[2], c[3] }, m.online and L("En ligne") or L("Hors ligne"), L("Ses quêtes de ce donjon :") }
        local common = {}
        for _, id in ipairs(m.common) do common[id] = true end
        for _, id in ipairs(m.quests) do
            lines[#lines + 1] = common[id] and string.format(L("%s (toi aussi)"), QuestName(id)) or QuestName(id)
        end
        if m.t then lines[#lines + 1] = string.format(L("Liste reçue %s."), Ago(m.t)) end
        S.Tip(self, lines)
    end)
    r:SetScript("OnLeave", function(self) self.hl:SetAlpha(0); S.HideTip() end)
    function r:Set(m)
        self.m = m
        local c = ClassColor(m.class)
        self.dot:SetVertexColor((m.online and C.ok or C.faint)[1], (m.online and C.ok or C.faint)[2], (m.online and C.ok or C.faint)[3])
        self.name:SetText(m.name); self.name:SetTextColor(c[1], c[2], c[3], m.online and 1 or 0.6)
        self.detail:SetText(Detail(m))
        if m.online then self.whisper:Enable(); self.whisper:SetDisabledReason(nil)
        else self.whisper:Disable(); self.whisper:SetDisabledReason(L("Hors ligne : ton message ne partirait pas.")) end
        local right = (Num(self.whisper:GetWidth()) or 80) + 12 + 12
        local textW = math.max(80, CW - 24 - right)
        Place(self.dot, 8, 7)
        Place(self.name, 24, 6)
        self.name:SetWidth(textW)
        S.ClampLabel(self.name, m.name, self)
        local y = 6 + F.label + 3
        Place(self.detail, 24, y)
        y = y + S.FitText(self.detail, 2, textW, self)
        local h = math.max(36, math.ceil(y + 8))
        self:SetHeight(h)
        return h
    end
    return r
end

-- A dungeon: painted icon, name, "Grouper" at the right; the sentence; the members.
local function Block(parent)
    local b = CreateFrame("Frame", nil, parent)
    b.wlOwned = true
    b:SetWidth(CW)
    b.icon = b:CreateTexture(nil, "ARTWORK"); b.icon:SetSize(20, 20)
    b.title = S.Text(b, F.heading, C.fg); b.title:SetWordWrap(false)
    b.group = S.Button(b, L("Grouper"), 0, 24, "secondary", function(self)
        local names = {}
        for _, m in ipairs(b.members or {}) do if m.online then names[#names + 1] = m.full or m.name end end
        local n = Sh.Invite(names)
        if n > 0 then self:Flash(n == 1 and L("Invité") or L("Invités")) end
    end, function()
        local names = {}
        for _, m in ipairs(b.members or {}) do if m.online then names[#names + 1] = m.name end end
        if #names == 0 then return nil end
        return { L("Grouper"), string.format(L("Invite dans ton groupe : %s."), JoinNames(names)) }
    end)
    b.group:SetPoint("TOPRIGHT", 0, -2)
    b.rule = S.Rule(b)
    b.sentence = S.Text(b, F.body, C.text)
    b.rows = {}
    function b:Set(d)
        self.members = d.members
        local dd = root.D and root.D[d.key]
        local y = 0
        local titleX = 0
        if dd and dd.icon then
            S.Painted(self.icon, dd.icon, 20); self.icon:Show()
            Place(self.icon, 0, 4); titleX = 28
        else
            self.icon:Hide()
        end
        if d.online > 0 then self.group:Enable(); self.group:SetDisabledReason(nil)
        else self.group:Disable(); self.group:SetDisabledReason(L("Personne de ce donjon n'est en ligne.")) end
        local gw = Num(self.group:GetWidth()) or 80
        self.title:SetText(d.name)
        self.title:SetWidth(math.max(80, CW - titleX - gw - 12))
        S.ClampLabel(self.title, d.name, self)
        Place(self.title, titleX, 7)
        y = 28 + 4
        self.rule:ClearAllPoints()
        self.rule:SetPoint("TOPLEFT", 0, -y); self.rule:SetPoint("TOPRIGHT", 0, -y)
        y = y + 1 + 8
        self.sentence:SetText(Sentence(d.members))
        Place(self.sentence, 0, y)
        y = y + S.FitText(self.sentence, 0, CW, self) + 8
        for i, m in ipairs(d.members) do
            local r = self.rows[i]
            if not r then r = MemberRow(self); self.rows[i] = r end
            r:Show()
            local h = r:Set(m)
            Place(r, 0, y)
            y = y + h + ROW_GAP
        end
        for i = #d.members + 1, #self.rows do self.rows[i]:Hide() end
        y = math.ceil(y - ROW_GAP)
        self:SetHeight(y)
        return y
    end
    return b
end

local function Build()
    win = S.Window("WLHelperShared", W, 240, L("Quêtes en commun"), nil, WLWritsDB, "sharedPos",
        { header = S.HEADER_H, footer = true, minH = 200 })
    local page = CreateFrame("Frame", nil, win)
    page:SetPoint("TOPLEFT", 0, -win:ContentTop()); page:SetPoint("BOTTOMRIGHT", 0, S.FOOTER_H)
    ui.page = page
    ui.sa = S.ScrollArea(page)
    ui.sa:SetPoint("TOPLEFT", page, "TOPLEFT", PAD, -12)
    ui.sa:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -PAD, 12)
    ui.sa.child:SetWidth(CW)
    ui.blocks = {}
    ui.empty = S.EmptyState(page, "group", "")
    ui.empty:Hide()
    win:SetScript("OnShow", function()
        if C_GuildInfo and C_GuildInfo.GuildRoster then pcall(C_GuildInfo.GuildRoster) elseif GuildRoster then pcall(GuildRoster) end
        Sh.Refresh()
    end)
end

local refreshing = false
local function Render()
    win:SetFooter(DB().share and L("Tu partages tes quêtes de donjon avec la guilde.") or L("Tu ne partages pas tes quêtes de donjon (Réglages > Général > Guilde)."))
    local function Empty(icon, title, text)
        ui.sa:Hide()
        for _, b in ipairs(ui.blocks) do b:Hide() end
        win.subtitle:SetText("")
        ui.empty:Show()
        ui.empty:ClearAllPoints(); ui.empty:SetPoint("TOP", ui.page, "TOPLEFT", W / 2, -24)
        win:FitHeight(12 + ui.empty:Set(icon, title, text))
    end
    if not InGuild() then
        return Empty("group", L("Tu n'es dans aucune guilde"), L("Les quêtes de donjon de la guilde apparaîtront ici dès que tu rejoins une guilde."))
    end
    local list, myDungeons = Sh.Dungeons()
    if myDungeons == 0 then
        return Empty("group", L("Aucune quête de donjon dans ton journal"), L("Prends une quête de donjon : les membres qui ont la même apparaîtront ici."))
    end
    if #list == 0 then
        return Empty("group", L("Personne d'autre n'a ces quêtes pour l'instant"), L("Seuls les membres qui ont WL Helper partagent leurs quêtes de donjon."))
    end
    ui.empty:Hide(); ui.sa:Show()
    win.subtitle:SetText(#list == 1 and L("1 donjon en commun") or string.format(L("%d donjons en commun"), #list))
    local y = 0
    for i, d in ipairs(list) do
        local b = ui.blocks[i]
        if not b then b = Block(ui.sa.child); ui.blocks[i] = b end
        b:Show()
        if i > 1 then y = y + 16 end
        Place(b, 0, y)
        y = y + b:Set(d)
    end
    for i = #list + 1, #ui.blocks do ui.blocks[i]:Hide() end
    ui.sa:SetContentHeight(y)
    win:FitHeight(y)
end

function Sh.Refresh()
    if not (win and win:IsShown()) or refreshing then return end
    refreshing = true
    local ok, err = pcall(Render)
    refreshing = false
    if not ok then error(err, 0) end
end

function Sh.Show()
    if WP.ModuleOff and WP.ModuleOff("guild") then return end
    if not win then Build() end
    win:Show(); win:Raise()
    Sh.Refresh()
    -- wrapped text measures right only once its width is applied: once more on the next frame
    if C_Timer and C_Timer.After then C_Timer.After(0, function() Sh.Refresh() end) end
end
function Sh.Hide() if win then win:Hide() end end
function Sh.Toggle()
    if win and win:IsShown() then win:Hide() else Sh.Show() end
end
function Sh.IsShown() return win and win:IsShown() and true or false end

-- ---------------------------------------------------------------- events
-- The log and the roster fire in bursts (each kill, each roster answer): one redraw half a second
-- after the first, and none while the window is closed.
local refreshQueued = false
RefreshSoon = function()
    if refreshQueued or not (win and win:IsShown()) then return end
    if not (C_Timer and C_Timer.After) then Sh.Refresh(); return end
    refreshQueued = true
    C_Timer.After(0.5, function() refreshQueued = false; Sh.Refresh() end)
end

local ev = CreateFrame("Frame")
pcall(ev.RegisterEvent, ev, "PLAYER_LOGIN")
pcall(ev.RegisterEvent, ev, "CHAT_MSG_ADDON")
pcall(ev.RegisterEvent, ev, "GUILD_ROSTER_UPDATE")
for _, e in ipairs({ "QUEST_ACCEPTED", "QUEST_REMOVED", "QUEST_TURNED_IN", "QUEST_LOG_UPDATE" }) do
    pcall(ev.RegisterEvent, ev, e)
end
ev:SetScript("OnEvent", function(self, e, prefix, msg, channel, sender)
    if not WLWritsDB then return end
    if e == "PLAYER_LOGIN" then
        Prune()
        -- after the login burst (the guild roster, the other modules' own messages)
        C_Timer.After(20, function()
            if not (ModuleOn() and InGuild()) then return end
            SendList(true)
            Send("R")
        end)
    elseif e == "CHAT_MSG_ADDON" then
        if prefix ~= PREFIX or channel ~= "GUILD" or type(msg) ~= "string" or Secret(msg) or not ModuleOn() then return end
        local who = Short(sender)
        if not who or who == "" or #who > 48 or who:find("[|%c]") or who == Me() then return end
        OnMessage(msg, who)
    elseif e == "GUILD_ROSTER_UPDATE" then
        RefreshSoon()
    else
        -- the quest log changed: my list goes out a little later (only when it really changed)
        if ModuleOn() and InGuild() then Schedule(5) end
        RefreshSoon()
    end
end)
