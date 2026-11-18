-- Writs/Reports.lua: a bug or an idea written in the game, no account anywhere ("GitHub needs an
-- account, I don't want to step in"). "/wlh bug <text>" or "/wlh idee <text>" makes a report with
-- what it needs to be understood (version, client language, zone and position, the guide's step and
-- dungeon, level and class, the last Lua error BugGrabber kept), keeps it in WLWritsDB.reports.out and
-- sends it over the guild's addon channel (prefix WLHbug), cut in chunks.
-- The inbox: the guild master's characters (any character of an account where one logged in once),
-- or one turned on with "/wlh rapports on". It stores every report in WLWritsDB.reports.inbox (the
-- account's saved variables, on disk at logout or /reload, where the addon's author reads them) and
-- answers "A|id": the sender marks it delivered. An inbox says hello as it logs in and every 15
-- minutes ("H", the only message on the guild channel); whoever has undelivered reports sends them
-- then. Reports and acks go by addon whisper to the inbox alone, never to the whole guild (report:
-- "it must go to me only, not spam the network"): to the inbox that said hello, else the guild
-- master when the roster shows them online. Nothing leaves the guild.
--   "R|id|i|n|chunk"  a report's i-th chunk of n (id: sender key and time)
--   "A|id"            delivered
--   "H"               an inbox is here
local ADDON, root = ...
local ns = root.Writs
local WP = ns.WP
local L = ns.L

ns.AddEnglish({
    ["Merci ! Ton rapport est parti à l'équipe WL Helper (par la guilde)."] = "Thanks! Your report went to the WL Helper team (through the guild).",
    ["Ton rapport est gardé : il partira dès qu'un responsable de la guilde sera connecté."] = "Your report is kept: it will go as soon as a guild officer is online.",
    ["Rapport reçu de %s : %s"] = "Report from %s: %s",
    ["Écris ton message après la commande : /wlh bug la flèche reste affichée quand..."] = "Write your message after the command: /wlh bug the arrow stays when...",
    ["Rapports reçus : %d (dans WLWritsDB.reports.inbox). En attente d'envoi ici : %d."] = "Reports received: %d (in WLWritsDB.reports.inbox). Waiting to be sent from here: %d.",
    ["Boîte de réception des rapports : %s"] = "Report inbox: %s",
    ["activée"] = "on",
    ["coupée"] = "off",
})

local PREFIX = "WLHbug"
local CHUNK = 200              -- bytes of a report per message (the channel takes 255 with the header)
local MAX_TEXT = 500
local HELLO_EVERY = 15 * 60
local SEND_GAP = 0.25          -- seconds between two chunks (the channel's own pace)
local R = {}
WP.Reports = R

local function IsSecret(v) return issecretvalue ~= nil and issecretvalue(v) == true end
local function Str(v) if type(v) == "string" and not IsSecret(v) and v ~= "" then return v end end
local function Num(v) if type(v) == "number" and not IsSecret(v) and v == v then return v end end

local function DB()
    if type(WLWritsDB) ~= "table" then return nil end
    local r = WLWritsDB.reports
    if type(r) ~= "table" then r = {}; WLWritsDB.reports = r end
    r.out = type(r.out) == "table" and r.out or {}
    r.inbox = type(r.inbox) == "table" and r.inbox or {}
    return r
end

local function MeKey()
    local n = Str(UnitName and UnitName("player")) or "?"
    local realm = Str(GetNormalizedRealmName and GetNormalizedRealmName())
    return realm and (n .. "-" .. realm) or n
end

-- this account receives the reports: a guild master logged in here once, or turned on by hand
function R.IsInbox()
    local d = DB()
    if not d then return false end
    if IsGuildLeader and IsInGuild and IsInGuild() then
        local ok, gm = pcall(IsGuildLeader)
        if ok and gm == true and d.inboxOn == nil then d.inboxOn = true end
    end
    return d.inboxOn == true
end
function R.SetInbox(on)
    local d = DB()
    if d then d.inboxOn = on and true or false end
end

-- ---------------------------------------------------------------- one report, on a line
-- fields "k=v" joined by \30; \30, \31 and "|" never inside a value (the channel's separator)
local function Clean(v)
    v = tostring(v or "")
    return (v:gsub("[\30\31|\r\n]", " "))
end
local FIELDS = { "id", "at", "from", "kind", "text", "shot", "v", "loc", "zone", "m", "x", "y", "step", "dk", "lvl", "cls", "err" }
local function Encode(rec)
    local parts = {}
    for _, k in ipairs(FIELDS) do
        if rec[k] ~= nil then parts[#parts + 1] = k .. "=" .. Clean(rec[k]) end
    end
    return table.concat(parts, "\30")
end
local function Decode(s)
    local rec = {}
    for pair in (s .. "\30"):gmatch("(.-)\30") do
        local k, v = pair:match("^(%w+)=(.*)$")
        if k then rec[k] = v end
    end
    if not rec.id then return nil end
    rec.at = tonumber(rec.at) or rec.at
    rec.m, rec.x, rec.y, rec.lvl = tonumber(rec.m), tonumber(rec.x), tonumber(rec.y), tonumber(rec.lvl)
    return rec
end
R._Encode, R._Decode = Encode, Decode

-- ---------------------------------------------------------------- what the report says by itself
local function LastError()
    local BG = rawget(_G, "BugGrabber")
    if type(BG) ~= "table" or type(BG.GetDB) ~= "function" then return nil end
    local ok, db = pcall(BG.GetDB)
    if not ok or type(db) ~= "table" or #db == 0 then return nil end
    local e = db[#db]
    local msg = type(e) == "table" and Str(e.message)
    return msg and msg:sub(1, 200) or nil
end
local function Context(rec)
    rec.v = root.VERSION or "?"
    rec.loc = GetLocale and GetLocale() or nil
    local okZ, z = pcall(GetRealZoneText or function() end)
    rec.zone = okZ and Str(z) or nil
    if C_Map and C_Map.GetBestMapForUnit then
        local m = Num(C_Map.GetBestMapForUnit("player"))
        if m then
            rec.m = m
            local okP, p = pcall(C_Map.GetPlayerMapPosition, m, "player")
            if okP and p and p.GetXY then
                local x, y = p:GetXY()
                if Num(x) and Num(y) then rec.x, rec.y = math.floor(x * 1000 + 0.5) / 10, math.floor(y * 1000 + 0.5) / 10 end
            end
        end
    end
    rec.lvl = Num(UnitLevel and UnitLevel("player"))
    local _, cls = UnitClass and UnitClass("player")
    rec.cls = Str(cls)
    -- the guide's step and dungeon, when a route runs
    if root.route and root.route.steps and root.CurrentStepIndex then
        local okS, idx, st = pcall(root.CurrentStepIndex, root.LogEntries and root.LogEntries() or nil)
        if okS and st then
            rec.step = (root.StepTitle and select(2, pcall(root.StepTitle, st))) or idx
            if type(rec.step) ~= "string" and type(rec.step) ~= "number" then rec.step = idx end
            rec.dk = root.StepDungeon and select(2, pcall(root.StepDungeon, st)) or nil
            if type(rec.dk) ~= "string" then rec.dk = nil end
        end
    end
    rec.err = LastError()
    return rec
end

-- ---------------------------------------------------------------- the channel
local queue, sending = {}, false
local function Raw(msg, channel, target)
    local send = (C_ChatInfo and C_ChatInfo.SendAddonMessage) or SendAddonMessage
    if not send then return false end
    return (pcall(send, PREFIX, msg, channel or "GUILD", target))
end
local function Pump()
    if #queue == 0 then sending = false; return end
    sending = true
    local m = table.remove(queue, 1)
    Raw(m[1], m[2], m[3])
    if C_Timer and C_Timer.After then C_Timer.After(SEND_GAP, Pump) else Pump() end
end
local function Queue(msg, channel, target)
    queue[#queue + 1] = { msg, channel or "GUILD", target }
    if not sending then Pump() end
end
R._Queue = function() return queue end

-- the guild's members online: { [name or name-realm] = true }, and the guild master's name if online
local function Online()
    local on, gm = {}, nil
    local count = GetNumGuildMembers and select(1, GetNumGuildMembers()) or 0
    count = Num(count) or 0
    for i = 1, count do
        local ok, name, _, rankIndex, _, _, _, _, _, online = pcall(GetGuildRosterInfo, i)
        name = ok and Str(name)
        if name and online then
            on[name] = true
            on[name:match("^([^%-]+)") or name] = true
            if rankIndex == 0 then gm = name end
        end
    end
    return on, gm
end
function R.Target()
    local d = DB()
    if not (d and IsInGuild and IsInGuild()) then return nil end
    local on, gm = Online()
    local box = Str(d.inboxName)
    if box and on[box] then return box end
    return gm
end

local function SendReport(rec, target)
    target = target or R.Target()
    if not target then return false end
    local line = Encode(rec)
    local n = math.max(1, math.ceil(#line / CHUNK))
    for i = 1, n do
        Queue("R|" .. rec.id .. "|" .. i .. "|" .. n .. "|" .. line:sub((i - 1) * CHUNK + 1, i * CHUNK), "WHISPER", target)
    end
    return true
end

-- every report not delivered yet, again (an inbox said hello)
function R.SendPending(target)
    local d = DB()
    if not d then return 0 end
    target = target or R.Target()
    if not target then return 0 end
    local n = 0
    for _, rec in pairs(d.out) do
        if not rec.delivered then SendReport(rec, target); n = n + 1 end
    end
    return n
end

-- "/wlh bug <text>", "/wlh idee <text>", the form's Send. kind: "bug" | "idea" | "quest"; shot: the
-- link of a screenshot the player put online (Discord, imgur...), or nil. -> the report, or nil
local KINDS = { bug = true, idea = true, quest = true }
function R.New(kind, text, shot)
    text = Str(text and (text:gsub("^%s+", ""):gsub("%s+$", "")))
    if not text then WP.Print(L("Écris ton message après la commande : /wlh bug la flèche reste affichée quand...")); return nil end
    local d = DB()
    if not d then return nil end
    local now = (time and time()) or 0
    shot = Str(shot and (shot:gsub("^%s+", ""):gsub("%s+$", "")))
    local rec = Context({ id = MeKey() .. ":" .. now, at = now, from = MeKey(), kind = KINDS[kind] and kind or "bug",
        text = text:sub(1, MAX_TEXT), shot = shot and shot:sub(1, 200) or nil })
    d.out[rec.id] = rec
    -- an inbox on this very account (the guild master writing): kept at once
    if R.IsInbox() then d.inbox[rec.id] = rec; rec.delivered = true; WP.Print(L("Merci ! Ton rapport est parti à l'équipe WL Helper (par la guilde).")); return rec end
    SendReport(rec)
    WP.Print(L("Ton rapport est gardé : il partira dès qu'un responsable de la guilde sera connecté."))
    return rec
end

-- ---------------------------------------------------------------- receiving
local parts = {}   -- [id] = { n = total, got = count, [i] = chunk }
function R.OnMessage(msg, sender)
    if type(msg) ~= "string" or IsSecret(msg) then return end
    local d = DB()
    if not d then return end
    local kind = msg:sub(1, 1)
    -- an inbox is here: remembered, and what waits goes to it, by whisper
    if kind == "H" then
        if Str(sender) then d.inboxName = sender end
        R.SendPending(sender)
        return
    end
    if kind == "A" then
        local id = msg:match("^A|(.+)$")
        local rec = id and d.out[id]
        if rec and not rec.delivered then
            rec.delivered = true
            WP.Print(L("Merci ! Ton rapport est parti à l'équipe WL Helper (par la guilde)."))
        end
        return
    end
    if kind ~= "R" or not R.IsInbox() then return end
    local id, i, n, chunk = msg:match("^R|([^|]+)|(%d+)|(%d+)|(.*)$")
    i, n = tonumber(i), tonumber(n)
    if not (id and i and n and n >= 1 and n <= 20 and i >= 1 and i <= n) then return end
    if d.inbox[id] then Queue("A|" .. id, "WHISPER", sender); return end
    local p = parts[id]
    if not p or p.n ~= n then p = { n = n, got = 0 }; parts[id] = p end
    if not p[i] then p[i] = chunk; p.got = p.got + 1 end
    if p.got < n then return end
    local line = table.concat(p, "", 1, n)
    parts[id] = nil
    local rec = Decode(line)
    if not rec then return end
    rec.got = (time and time()) or 0
    rec.via = Str(sender)
    d.inbox[id] = rec
    Queue("A|" .. id, "WHISPER", sender)
    WP.Print(string.format(L("Rapport reçu de %s : %s"), tostring(rec.from or sender or "?"), tostring(rec.text or ""):sub(1, 80)))
end

-- /wlh rapports [on|off]
function R.Command(arg)
    local d = DB()
    if not d then return end
    if arg == "on" or arg == "off" then
        R.SetInbox(arg == "on")
        WP.Print(string.format(L("Boîte de réception des rapports : %s"), arg == "on" and L("activée") or L("coupée")))
        if arg == "on" then Queue("H") end
        return
    end
    local nIn, nOut = 0, 0
    for _ in pairs(d.inbox) do nIn = nIn + 1 end
    for _, rec in pairs(d.out) do if not rec.delivered then nOut = nOut + 1 end end
    WP.Print(string.format(L("Rapports reçus : %d (dans WLWritsDB.reports.inbox). En attente d'envoi ici : %d."), nIn, nOut))
end

-- ---------------------------------------------------------------- events
local f = CreateFrame("Frame")
pcall(f.RegisterEvent, f, "PLAYER_LOGIN")
pcall(f.RegisterEvent, f, "CHAT_MSG_ADDON")
pcall(f.RegisterEvent, f, "GUILD_ROSTER_UPDATE")
local helloTicker
local rosterTry = -1e9   -- the last time the roster was looked at for a guild master online
f:SetScript("OnEvent", function(_, event, a1, a2, a3, a4)
    if event == "PLAYER_LOGIN" then
        local Register = (C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix) or RegisterAddonMessagePrefix
        if Register then pcall(Register, PREFIX) end
        -- the roster, asked once: who is online (the guild master receives the reports)
        if C_GuildInfo and C_GuildInfo.GuildRoster then pcall(C_GuildInfo.GuildRoster) elseif GuildRoster then pcall(GuildRoster) end
        if C_Timer and C_Timer.After then
            C_Timer.After(20, function()
                if R.IsInbox() then
                    Queue("H")
                    if C_Timer.NewTicker and not helloTicker then helloTicker = C_Timer.NewTicker(HELLO_EVERY, function() Queue("H") end) end
                end
            end)
        end
    elseif event == "GUILD_ROSTER_UPDATE" then
        -- undelivered reports and the guild master online: sent, at most once every 10 minutes
        local now = GetTime and GetTime() or 0
        if now - rosterTry < 600 then return end
        local d = DB()
        local any = false
        for _, rec in pairs(d and d.out or {}) do if not rec.delivered then any = true; break end end
        if not any or R.IsInbox() then return end
        rosterTry = now
        R.SendPending()
    elseif event == "CHAT_MSG_ADDON" and a1 == PREFIX then
        -- our own messages come back too: an inbox ignores its own reports (kept at once), a sender
        -- its own "H" (it has nothing to send to itself)
        local me = Str(UnitName and UnitName("player"))
        local from = Str(a4)
        if from and me and (from == me or from:match("^([^%-]+)") == me) then return end
        R.OnMessage(a2, from)
    end
end)
