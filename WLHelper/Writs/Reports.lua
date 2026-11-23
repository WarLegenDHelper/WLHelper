-- Writs/Reports.lua: a bug or an idea written in the game, no account anywhere ("GitHub needs an
-- account, I don't want to step in"). "/wlh bug <text>" or "/wlh idee <text>" makes a report with
-- what it needs to be understood (version, client language, zone and position, the guide's step and
-- dungeon, level and class, the last Lua error BugGrabber kept), keeps it in WLWritsDB.reports.out and
-- sends it over the guild's addon channel (prefix WLHbug), cut in chunks.
-- The inbox: the author's character (AUTHOR, any account it logs in on, since beta.190; the guild
-- master before),
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
    ["niveau %d"] = "level %d", ["étape du guide : "] = "guide step: ", ["%d quêtes du journal"] = "%d quests in the log",
    ["destination du GPS"] = "the GPS destination", ["ta cible : "] = "your target: ", ["la dernière erreur Lua"] = "the last Lua error",
    ["Rapports des joueurs"] = "Players' reports",
    ["Aucun rapport reçu pour l'instant. Ils arrivent ici quand un joueur utilise « Nous écrire »."] = "No report yet. They come here when a player uses \"Write to us\".",
    ["Bug"] = "Bug", ["Idée"] = "Idea", ["Erreur de quête"] = "Quest data error", ["Erreur Lua"] = "Lua error", ["Quête renumérotée"] = "Renumbered quest",
    ["nouveau"] = "new", ["Capture : "] = "Screenshot: ", ["Étape : "] = "Step: ",
    ["Envoi automatique des erreurs de WL Helper : %s"] = "Automatic sending of WL Helper's errors: %s",
    ["Envoi automatique des mesures de mémoire : %s"] = "Automatic sending of the memory measures: %s",
    ["Envoi automatique des parcours (quêtes et boss) : %s"] = "Automatic sending of the routes (quests and bosses): %s",
    ["activé"] = "on",
    ["coupé"] = "off",
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

-- Old reports go, once a session, so the saved file never grows without end: here, one delivered
-- 14 days ago (the inbox has it) or one that never found an inbox in 45 days; in an inbox, one
-- received more than 60 days ago (read by then). Delivered ones are never sent again, so nothing
-- comes back.
local OUT_KEEP, LOST_KEEP, INBOX_KEEP = 14 * 86400, 45 * 86400, 60 * 86400
local pruned = false
local function Prune(r)
    local now = (time and time()) or 0
    if now <= 0 then return end
    for id, rec in pairs(r.out) do
        local at = type(rec) == "table" and tonumber(rec.at) or 0
        if type(rec) ~= "table" or (rec.delivered and now - at > OUT_KEEP) or now - at > LOST_KEEP then r.out[id] = nil end
    end
    for id, rec in pairs(r.inbox) do
        local at = type(rec) == "table" and (tonumber(rec.got) or tonumber(rec.at)) or 0
        if type(rec) ~= "table" or now - at > INBOX_KEEP then r.inbox[id] = nil end
    end
end
R._Prune = function(r) Prune(r) end   -- tests

local function DB()
    if type(WLWritsDB) ~= "table" then return nil end
    local r = WLWritsDB.reports
    if type(r) ~= "table" then r = {}; WLWritsDB.reports = r end
    r.out = type(r.out) == "table" and r.out or {}
    r.inbox = type(r.inbox) == "table" and r.inbox or {}
    if not pruned then pruned = true; Prune(r) end
    return r
end

local function MeKey()
    local n = Str(UnitName and UnitName("player")) or "?"
    local realm = Str(GetNormalizedRealmName and GetNormalizedRealmName())
    return realm and (n .. "-" .. realm) or n
end

-- this account receives the reports: the author's character logged in here once, or turned on by hand
-- The reports go to the addon's author (report: "I never received a report... I am not the guild
-- master"): his character AUTHOR is the inbox by default, wherever it plays; any account can still be
-- turned on by hand (/wlh rapports on). The guild master is no longer the default.
local AUTHOR = "Alandir"
local function IAmGuildMaster()
    local me = Str(UnitName and UnitName("player"))
    return me ~= nil and me == AUTHOR
end
R._IAmGuildMaster = IAmGuildMaster
function R.IsInbox()
    local d = DB()
    if not d then return false end
    if d.inboxOn == nil and IAmGuildMaster() then d.inboxOn = true end
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
local FIELDS = { "id", "at", "from", "kind", "text", "shot", "v", "loc", "zone", "sub", "m", "x", "y", "step", "dk", "lvl", "cls",
    "act", "sel", "ql", "gps", "tgt", "win", "err", "errs", "stack" }
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
    -- the state at that moment, what a screenshot would only half show (report: "without a screenshot
    -- it will be hard to explain"): each piece in a pcall, each kept short
    pcall(function()
        local okS, sub = pcall(GetSubZoneText or function() end)
        rec.sub = okS and Str(sub) or nil
        -- the action the guide asks now, and the step out of how many
        local TR = rawget(_G, "WLHelperTracker")
        if TR and TR.Model then
            local okM, md = pcall(TR.Model)
            if okM and md and md.cur then
                rec.act = ((md.cur.text or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")):sub(1, 120) .. " [" .. tostring(md.idx) .. "/" .. tostring(md.stepTotal) .. "]"
            end
        end
        -- the dungeons picked
        if type(WLDTDB) == "table" and type(WLDTDB.sel) == "table" then
            local sel = {}
            for k in pairs(WLDTDB.sel) do sel[#sel + 1] = k end
            table.sort(sel)
            if #sel > 0 then rec.sel = table.concat(sel, ","):sub(1, 120) end
        end
        -- the quest log: ids (and "!" when ready to turn in)
        if root.LogEntries then
            local ids = {}
            for id, e in pairs(root.LogEntries() or {}) do
                if type(id) == "number" then ids[#ids + 1] = tostring(id) .. ((type(e) == "table" and e.complete) and "!" or "") end
            end
            table.sort(ids)
            if #ids > 0 then rec.ql = table.concat(ids, ","):sub(1, 260) end
        end
        -- the GPS: where it leads and what the arrow says now
        local G = WP.GPS
        if G and G.Now then
            local okN, now = pcall(G.Now)
            if okN and now and now.dest then
                local d = now.dest
                local leg = now.leg and G.Describe and select(2, pcall(G.Describe, now.leg)) or nil
                rec.gps = (tostring(d.name or "?") .. " @" .. tostring(d.map) .. " " .. tostring(d.x) .. "," .. tostring(d.y)
                    .. " (" .. tostring(G.Source and G.Source() or "?") .. ")" .. (type(leg) == "string" and (" : " .. leg) or "")):sub(1, 160)
            end
        end
        -- the target
        local tn = Str(UnitName and UnitName("target"))
        if tn then
            local guid = Str(UnitGUID and UnitGUID("target"))
            local npc = guid and guid:match("^%a+%-%d+%-%d+%-%d+%-%d+%-(%d+)")
            rec.tgt = tn .. (npc and (" #" .. npc) or "")
        end
        -- WL Helper's windows on screen
        local open = {}
        for _, w in ipairs(root.windows or {}) do
            local okV, vis = pcall(w.IsShown, w)
            local okN2, nm = pcall(w.GetName, w)
            if okV and vis and okN2 and Str(nm) then open[#open + 1] = nm end
        end
        if #open > 0 then rec.win = table.concat(open, ","):sub(1, 160) end
        -- the last 3 Lua errors (BugGrabber)
        local BG = rawget(_G, "BugGrabber")
        if type(BG) == "table" and type(BG.GetDB) == "function" then
            local okD, db = pcall(BG.GetDB)
            if okD and type(db) == "table" and #db > 1 then
                local list = {}
                for i = #db, math.max(1, #db - 2), -1 do
                    local e = db[i]
                    local m2 = type(e) == "table" and Str(e.message)
                    if m2 then list[#list + 1] = m2:sub(1, 150) end
                end
                if #list > 1 then rec.errs = table.concat(list, " || ") end
            end
        end
    end)
    return rec
end

-- What a report would carry now, in words, for the form ("What goes with your message")
function R.Preview()
    local rec = Context({})
    local parts = {}
    parts[#parts + 1] = "WL Helper " .. tostring(rec.v or "?")
    if rec.zone then parts[#parts + 1] = rec.zone .. ((rec.x and rec.y) and string.format(" (%.1f, %.1f)", rec.x, rec.y) or "") end
    if rec.lvl then parts[#parts + 1] = string.format(L("niveau %d"), rec.lvl) .. (rec.cls and (" " .. rec.cls:lower()) or "") end
    if rec.act then parts[#parts + 1] = L("étape du guide : ") .. rec.act end
    if rec.ql then local n = select(2, rec.ql:gsub(",", ",")) + 1; parts[#parts + 1] = string.format(L("%d quêtes du journal"), n) end
    if rec.gps then parts[#parts + 1] = L("destination du GPS") end
    if rec.tgt then parts[#parts + 1] = L("ta cible : ") .. rec.tgt end
    if rec.err then parts[#parts + 1] = L("la dernière erreur Lua") end
    return table.concat(parts, "  ·  ")
end

-- ---------------------------------------------------------------- the channel
local queue, sending = {}, false
local function Raw(msg, channel, target)
    local send = (C_ChatInfo and C_ChatInfo.SendAddonMessage) or SendAddonMessage
    if not send then return false end
    return root.AddonSend(PREFIX, msg, channel or "GUILD", target, send)
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
    local on = Online()
    local box = Str(d.inboxName)
    if box and on[box] then return box end
    if on[AUTHOR] then
        -- the roster's full name (name-realm) when there is one, the whisper's own form
        local short
        for name in pairs(on) do
            if name:match("^([^%-]+)") == AUTHOR then
                if name:find("-", 1, true) then return name end
                short = name
            end
        end
        return short
    end
    return nil
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
local KINDS = { bug = true, idea = true, quest = true, error = true, mem = true, run = true, newid = true }
local seq = 0
function R.New(kind, text, shot, quiet, extra)
    text = Str(text and (text:gsub("^%s+", ""):gsub("%s+$", "")))
    if not text then WP.Print(L("Écris ton message après la commande : /wlh bug la flèche reste affichée quand...")); return nil end
    local d = DB()
    if not d then return nil end
    local now = (time and time()) or 0
    shot = Str(shot and (shot:gsub("^%s+", ""):gsub("%s+$", "")))
    seq = seq + 1
    local rec = Context({ id = MeKey() .. ":" .. now .. ":" .. seq, at = now, from = MeKey(), kind = KINDS[kind] and kind or "bug",
        text = text:sub(1, MAX_TEXT), shot = shot and shot:sub(1, 200) or nil })
    for k, v in pairs(extra or {}) do rec[k] = v end
    d.out[rec.id] = rec
    -- an inbox on this very account (the guild master writing): kept at once
    if R.IsInbox() then
        d.inbox[rec.id] = rec; rec.delivered = true
        if not quiet then WP.Print(L("Merci ! Ton rapport est parti à l'équipe WL Helper (par la guilde).")) end
        return rec
    end
    SendReport(rec)
    if not quiet then WP.Print(L("Ton rapport est gardé : il partira dès qu'un responsable de la guilde sera connecté.")) end
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
            if rec.kind ~= "error" then WP.Print(L("Merci ! Ton rapport est parti à l'équipe WL Helper (par la guilde).")) end
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

-- ---------------------------------------------------------------- WL Helper's Lua errors, by themselves
-- BugGrabber (BugSack's) catches every Lua error; one of WL Helper's (its message or stack names
-- WLHelper) goes as a report of kind "error", silently (report: "if BugSack catches bugs at the
-- players', it must send them to me"). Other addons' errors are never sent. Each error once per
-- addon version (WLWritsDB.reports.sentErr), 5 at most a session; "/wlh rapports erreurs off" stops it.
local ERR_PER_SESSION = 5
local errSent = 0
function R.AutoErrorsOn()
    local d = DB()
    return d ~= nil and d.autoErr ~= false
end
function R.OnError(err)
    if type(err) ~= "table" or not R.AutoErrorsOn() or errSent >= ERR_PER_SESSION then return nil end
    local msg = Str(err.message)
    if not msg then return nil end
    local stack = Str(err.stack) or ""
    if not (msg:find("WLHelper", 1, true) or stack:find("WLHelper", 1, true)) then return nil end
    local d = DB()
    d.sentErr = type(d.sentErr) == "table" and d.sentErr or {}
    local key = tostring(root.VERSION or "?") .. "|" .. msg:sub(1, 160)
    if d.sentErr[key] then return nil end
    d.sentErr[key] = true
    errSent = errSent + 1
    -- the stack's first lines that name an addon file, short
    local lines = {}
    for ln in stack:gmatch("[^\n]+") do
        if #lines >= 5 then break end
        lines[#lines + 1] = (ln:gsub("^%s+", ""):gsub("Interface/AddOns/", ""):gsub("Interface\\AddOns\\", "")):sub(1, 110)
    end
    return R.New("error", msg:sub(1, 300) .. ((Num(err.counter) and err.counter > 1) and (" (x" .. err.counter .. ")") or ""), nil, true,
        { stack = table.concat(lines, " | ") })
end
local errHooked = false
function R.HookErrors()
    if errHooked then return end
    local ER = rawget(_G, "EventRegistry")
    local BG = rawget(_G, "BugGrabber")
    if not (type(ER) == "table" and ER.RegisterCallback and type(BG) == "table" and BG.GetErrorByID) then return end
    errHooked = true
    ER:RegisterCallback("BugGrabber.BugGrabbed", function(_, id)
        local ok, err = pcall(BG.GetErrorByID, BG, id)
        if ok and err then
            -- out of the error's own call stack: a moment later
            if C_Timer and C_Timer.After then C_Timer.After(1, function() pcall(R.OnError, err) end) else pcall(R.OnError, err) end
        end
    end, R)
end

-- ---------------------------------------------------------------- memory, measured at the players'
-- (report: "the addon takes 110 MB: let my addon send reports, then we fix"). Once a day per
-- character, after MEM_AFTER seconds of play (the GPS and the guide have been used by then): the
-- memory of each part of WL Helper, whether its movement maps are loaded, the total of every
-- addon, the five heaviest addons, and WL Helper's slowest timings (WLWritsDB.perf). A report of
-- kind "mem", silent; "/wlh rapports memoire off" stops it. Nothing leaves the guild.
local MEM_AFTER = 20 * 60
local PARTS = { "WLHelper", "WLHelper_Gear", "WLHelper_Nav", "WLHelper_Nav_EK", "WLHelper_Nav_Kalimdor" }
function R.AutoMemOn()
    local d = DB()
    return d ~= nil and d.autoMem ~= false
end
local function MB(kb) return string.format("%.1f", (kb or 0) / 1024) end
function R.MemText()
    local upd, get = rawget(_G, "UpdateAddOnMemoryUsage"), rawget(_G, "GetAddOnMemoryUsage")
    if type(upd) ~= "function" or type(get) ~= "function" then return nil end
    pcall(upd)
    local A = C_AddOns
    local loaded = (A and A.IsAddOnLoaded) or rawget(_G, "IsAddOnLoaded")
    local count = (A and A.GetNumAddOns) or rawget(_G, "GetNumAddOns")
    local info = (A and A.GetAddOnInfo) or rawget(_G, "GetAddOnInfo")
    local ours, total, all = {}, 0, {}
    for _, name in ipairs(PARTS) do
        local label = name == "WLHelper" and "core" or (name:gsub("^WLHelper_", ""))
        local okL, isL = pcall(loaded, name)
        if okL and isL then
            local okM, kb = pcall(get, name)
            ours[#ours + 1] = label .. "=" .. ((okM and Num(kb)) and MB(kb) or "?")
        else
            ours[#ours + 1] = label .. "=-"
        end
    end
    local okC, n = pcall(count)
    for i = 1, (okC and Num(n) or 0) do
        local okI, name = pcall(info, i)
        name = okI and Str(name)
        local okL, isL = pcall(loaded, i)
        if name and okL and isL then
            local okM, kb = pcall(get, i)
            kb = okM and Num(kb) or 0
            total = total + kb
            all[#all + 1] = { name, kb }
        end
    end
    table.sort(all, function(a, b) return a[2] > b[2] end)
    local top = {}
    for i = 1, math.min(5, #all) do top[i] = all[i][1] .. "=" .. MB(all[i][2]) end
    local slow = {}
    local perf = WLWritsDB and type(WLWritsDB.perf) == "table" and WLWritsDB.perf or {}
    local list = {}
    for tag, pf in pairs(perf) do if type(pf) == "table" and Num(pf.max) then list[#list + 1] = { tag, pf.max } end end
    table.sort(list, function(a, b) return a[2] > b[2] end)
    -- the worst time and the usual one: "mapOpen=803.5ms (avg 63)". One slow opening (the first, a
    -- loading screen) is not a slow map; the average says how it feels.
    for i = 1, math.min(3, #list) do
        local pf = perf[list[i][1]]
        local avg = Num(pf.n) and pf.n > 0 and Num(pf.total) and math.floor(pf.total / pf.n + 0.5) or nil
        slow[i] = list[i][1] .. "=" .. list[i][2] .. "ms" .. (avg and (" (avg " .. avg .. ")") or "")
    end
    local upMin = math.floor(((GetTime and GetTime()) or 0) / 60)
    return string.format("MEM (MB) WLH %s | all addons %s (%d) | top %s | slowest %s | session %d min",
        table.concat(ours, " "), MB(total), #all, table.concat(top, " "), #slow > 0 and table.concat(slow, " ") or "-", upMin)
end
function R.SendMem()
    if not R.AutoMemOn() then return nil end
    local d = DB()
    if not d then return nil end
    local day = date and date("%Y-%m-%d") or "?"
    if d.memDay == day then return nil end
    local text = R.MemText()
    if not text then return nil end
    d.memDay = day
    return R.New("mem", text, nil, true)
end

-- ---------------------------------------------------------------- the inbox, in the game
-- -> received, not read yet
function R.Counts()
    local d = DB()
    if not d then return 0, 0 end
    local n, new = 0, 0
    for _, rec in pairs(d.inbox) do
        n = n + 1
        if not rec.read then new = new + 1 end
    end
    return n, new
end
-- the reports, newest first
function R.List()
    local d = DB()
    local out = {}
    for _, rec in pairs(d and d.inbox or {}) do out[#out + 1] = rec end
    table.sort(out, function(a, b) return (tonumber(a.at) or 0) > (tonumber(b.at) or 0) end)
    return out
end
local KIND_LABEL = { bug = "Bug", idea = "Idée", quest = "Erreur de quête", error = "Erreur Lua", newid = "Quête renumérotée" }
local KIND_COLOR = { bug = "warn", idea = "info", quest = "gold", error = "bad", newid = "info" }
local inboxWin
function R.ShowInbox()
    local S, C, F = ns.S, ns.S.C, ns.S.F
    if not inboxWin then
        inboxWin = S.Window("WLHelperReports", (root.WinSize and root.WinSize("panel")) or 614, 520, L("Rapports des joueurs"), nil, WLWritsDB, "reportsPos",
            { header = 44, minH = 240, size = "panel" })
        inboxWin.list = S.ScrollArea(inboxWin)
        inboxWin.rows = {}
        inboxWin.empty = S.Text(inboxWin, F.body, C.muted)
        inboxWin.empty:SetText(L("Aucun rapport reçu pour l'instant. Ils arrivent ici quand un joueur utilise « Nous écrire »."))
    end
    local w = inboxWin
    local top = w:ContentTop() + 8
    w.list:ClearAllPoints(); w.list:SetPoint("TOPLEFT", 16, -top); w.list:SetPoint("BOTTOMRIGHT", -16, 16)
    local width = math.max(300, (w:GetWidth() or 614) - 40)
    w.list.child:SetWidth(width)
    local list = R.List()
    w.empty:ClearAllPoints(); w.empty:SetPoint("TOPLEFT", 16, -top); w.empty:SetWidth(width)
    w.empty:SetShown(#list == 0)
    local y = 0
    for i, rec in ipairs(list) do
        local r = w.rows[i]
        if not r then
            r = S.Text(w.list.child, F.label, C.text)
            r:SetJustifyH("LEFT"); r:SetJustifyV("TOP"); r:SetWordWrap(true)
            w.rows[i] = r
        end
        r:SetWidth(width)
        local col = C[KIND_COLOR[rec.kind] or "fg"] or C.fg
        local when = (date and tonumber(rec.at)) and date("%d/%m %H:%M", tonumber(rec.at)) or ""
        local head = (S.Hex and S.Hex(col) or "") .. L(KIND_LABEL[rec.kind] or "Bug") .. "|r  " .. tostring(rec.from or "?") .. "  ·  " .. when
            .. ((rec.zone and ("  ·  " .. rec.zone)) or "") .. ((not rec.read) and ("  " .. (S.Hex and S.Hex(C.warn) or "") .. L("nouveau") .. "|r") or "")
        local lines = { head, tostring(rec.text or "") }
        if rec.shot then lines[#lines + 1] = L("Capture : ") .. rec.shot end
        if rec.act then lines[#lines + 1] = (S.Hex and S.Hex(C.muted) or "") .. L("Étape : ") .. rec.act .. "|r" end
        if rec.stack then lines[#lines + 1] = (S.Hex and S.Hex(C.muted) or "") .. rec.stack .. "|r" end
        r:SetText(table.concat(lines, "\n"))
        r:ClearAllPoints(); r:SetPoint("TOPLEFT", 0, -y)
        r:Show()
        local okH, h = pcall(r.GetStringHeight, r)
        y = y + ((okH and type(h) == "number") and h or 40) + 14
        rec.read = true
    end
    for i = #list + 1, #w.rows do w.rows[i]:Hide() end
    w.list:SetContentHeight(y)
    w:Show()
end

-- /wlh rapports [on|off|erreurs on|erreurs off]
function R.Command(arg)
    local d = DB()
    if not d then return end
    local pr = arg and (arg:match("^parcours (%a+)$") or arg:match("^route (%a+)$") or arg:match("^runs? (%a+)$"))
    if pr == "on" or pr == "off" then
        if pr == "off" then d.autoRun = false else d.autoRun = nil end
        WP.Print(string.format(L("Envoi automatique des parcours (quêtes et boss) : %s"), pr == "on" and L("activé") or L("coupé")))
        return
    end
    local mm = arg and (arg:match("^m[eé]moire (%a+)$") or arg:match("^memory (%a+)$") or arg:match("^mem (%a+)$"))
    if mm == "on" or mm == "off" then
        if mm == "off" then d.autoMem = false else d.autoMem = nil end
        WP.Print(string.format(L("Envoi automatique des mesures de mémoire : %s"), mm == "on" and L("activé") or L("coupé")))
        return
    end
    local e = arg and arg:match("^erreurs? (%a+)$") or (arg and arg:match("^errors? (%a+)$"))
    if e == "on" or e == "off" then
        if e == "off" then d.autoErr = false else d.autoErr = nil end
        WP.Print(string.format(L("Envoi automatique des erreurs de WL Helper : %s"), e == "on" and L("activé") or L("coupé")))
        return
    end
    if arg == "on" or arg == "off" then
        R.SetInbox(arg == "on")
        WP.Print(string.format(L("Boîte de réception des rapports : %s"), arg == "on" and L("activée") or L("coupée")))
        if arg == "on" then if R.StartInbox then pcall(R.StartInbox) else Queue("H") end end
        return
    end
    if arg == "" or arg == nil then pcall(R.ShowInbox) end
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
local rosterTry = -1e9
-- the inbox says hello (now, then every HELLO_EVERY), and its own reports that waited for an inbox
-- (written before this account knew it was the inbox) go straight into it
function R.StartInbox()
    if helloTicker or not R.IsInbox() then return end
    local d = DB()
    for id, rec in pairs(d and d.out or {}) do
        if not rec.delivered then d.inbox[id] = rec; rec.delivered = true end
    end
    Queue("H")
    if C_Timer and C_Timer.NewTicker then helloTicker = C_Timer.NewTicker(HELLO_EVERY, function() Queue("H") end) end
end   -- the last time the roster was looked at for a guild master online
f:SetScript("OnEvent", function(_, event, a1, a2, a3, a4)
    if event == "PLAYER_LOGIN" then
        local Register = (C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix) or RegisterAddonMessagePrefix
        if Register then pcall(Register, PREFIX) end
        pcall(R.HookErrors)
        -- the day's memory report, after MEM_AFTER seconds of play
        if C_Timer and C_Timer.After then C_Timer.After(MEM_AFTER, function() pcall(R.SendMem) end) end
        -- the roster, asked once: who is online (the guild master receives the reports)
        if C_GuildInfo and C_GuildInfo.GuildRoster then pcall(C_GuildInfo.GuildRoster) elseif GuildRoster then pcall(GuildRoster) end
        if C_Timer and C_Timer.After then
            C_Timer.After(20, function() pcall(R.StartInbox) end)
        end
    elseif event == "GUILD_ROSTER_UPDATE" then
        -- the roster came: the guild master is known by its rank now (the login may have been too early)
        if not helloTicker then pcall(R.StartInbox) end
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

-- ---------------------------------------------------------------- the route as players really play it
-- (report: "put the quests in the reports, to confirm the order? the boss kills?"): a small journal
-- per character (WLWritsCharDB.trail) of quests taken (+id) and turned in (=id), each with the guide's
-- step at that moment (@s12), and of the bosses killed in an instance (their time since the entry).
-- Leaving an instance sends one "run" report (the dungeon, its time, its boss order, the quests since
-- the last report); outside, the quests go once TRAIL_FLUSH of them are waiting. Kind "run", silent;
-- "/wlh rapports parcours off" stops it. Only game facts, inside the guild, to the author.
local TRAIL_FLUSH = 30
local TRAIL_MAX = 120
local function TrailDB()
    local c = WLWritsCharDB
    if type(c) ~= "table" then return nil end
    c.trail = type(c.trail) == "table" and c.trail or { ev = {} }
    c.trail.ev = type(c.trail.ev) == "table" and c.trail.ev or {}
    return c.trail
end
function R.AutoRunOn()
    local d = DB()
    return d ~= nil and d.autoRun ~= false
end
local function StepNow()
    if not (root.route and root.route.steps and root.CurrentStepIndex and root.LogEntries) then return nil end
    local ok, idx = pcall(root.CurrentStepIndex, root.LogEntries())
    return ok and Num(idx) or nil
end
local function Push(e)
    local tr = TrailDB()
    if not tr then return end
    tr.ev[#tr.ev + 1] = e
    while #tr.ev > TRAIL_MAX do table.remove(tr.ev, 1) end
end
function R.TrailQuest(kind, qid)
    qid = Num(qid)
    if not (qid and R.AutoRunOn()) then return end
    local s = StepNow()
    Push({ k = kind, q = qid, s = s })
    local tr = TrailDB()
    if tr and not tr.inst and #tr.ev >= TRAIL_FLUSH then R.SendTrail(false) end
end
function R.TrailBoss(name)
    name = Str(name)
    local tr = TrailDB()
    if not (name and tr and tr.inst and R.AutoRunOn()) then return end
    local t = (time and time()) or 0
    -- ENCOUNTER_END and BOSS_KILL both come for one kill: once
    local last = tr.ev[#tr.ev]
    if last and last.k == "b" and last.n == name:sub(1, 32) then return end
    Push({ k = "b", n = name:sub(1, 32), m = math.floor((t - (tr.inst.at or t)) / 60) })
end
-- the report's text: "RUN Blackrock Depths 47m | bosses Gerstahn 3m, Roccor 6m | q +4083@s12 =4083@s14"
function R.TrailText(run)
    local tr = TrailDB()
    if not tr then return nil end
    local bosses, quests = {}, {}
    for _, e in ipairs(tr.ev) do
        if e.k == "b" then bosses[#bosses + 1] = e.n .. " " .. (e.m or 0) .. "m"
        elseif e.k == "+" or e.k == "=" then quests[#quests + 1] = e.k .. e.q .. (e.s and ("@s" .. e.s) or "") end
    end
    if #bosses == 0 and #quests == 0 then return nil end
    local head = run and string.format("RUN %s %dm", run.name or "?", math.floor((run.secs or 0) / 60)) or "ROUTE"
    local text = head
    if #bosses > 0 then text = text .. " | bosses " .. table.concat(bosses, ", ") end
    if #quests > 0 then text = text .. " | q " .. table.concat(quests, " ") end
    -- a report holds MAX_TEXT characters: the bosses first, then the most recent quests
    if #text > MAX_TEXT then
        local keep = {}
        local room = MAX_TEXT - #head - (#bosses > 0 and (#(" | bosses " .. table.concat(bosses, ", "))) or 0) - 8
        for i = #quests, 1, -1 do
            local add = #quests[i] + 1
            if room - add < 0 then break end
            room = room - add
            table.insert(keep, 1, quests[i])
        end
        text = head .. (#bosses > 0 and (" | bosses " .. table.concat(bosses, ", ")) or "") .. " | q .. " .. table.concat(keep, " ")
        text = text:sub(1, MAX_TEXT)
    end
    return text
end
function R.SendTrail(run)
    if not R.AutoRunOn() then return nil end
    local text = R.TrailText(run)
    local tr = TrailDB()
    if tr then tr.ev = {} end
    if not text then return nil end
    return R.New("run", text, nil, true)
end
-- in and out of instances: the entry starts a run, the way out sends it
function R.TrailZone()
    local tr = TrailDB()
    if not tr then return end
    local inside, kind = false, nil
    if IsInInstance then local ok, i, k = pcall(IsInInstance); inside, kind = ok and i == true, k end
    if inside and (kind == "party" or kind == "raid") then
        if not tr.inst then
            local okN, name = pcall(GetInstanceInfo)
            tr.inst = { at = (time and time()) or 0, name = okN and Str(name) or "?" }
        end
    elseif tr.inst then
        local run = { name = tr.inst.name, secs = ((time and time()) or 0) - (tr.inst.at or 0) }
        tr.inst = nil
        -- a short visit (a wrong portal, a summon): no report, its events wait for the next one
        if run.secs >= 300 then R.SendTrail(run) end
    end
end
do
    local tf = CreateFrame("Frame")
    for _, e in ipairs({ "QUEST_ACCEPTED", "QUEST_TURNED_IN", "PLAYER_ENTERING_WORLD", "ENCOUNTER_END", "BOSS_KILL" }) do
        pcall(tf.RegisterEvent, tf, e)
    end
    tf:SetScript("OnEvent", function(_, e, a1, a2, a3, a4, a5)
        if e == "QUEST_ACCEPTED" then
            -- (questLogIndex, questID) on older clients, (questID) on newer ones
            pcall(R.TrailQuest, "+", Num(a2) or Num(a1))
        elseif e == "QUEST_TURNED_IN" then pcall(R.TrailQuest, "=", a1)
        elseif e == "PLAYER_ENTERING_WORLD" then pcall(R.TrailZone)
        elseif e == "ENCOUNTER_END" then if Num(a5) == 1 then pcall(R.TrailBoss, a2) end
        elseif e == "BOSS_KILL" then pcall(R.TrailBoss, a2) end
    end)
end

-- ---------------------------------------------------------------- a quest Forever renumbered
-- Curated.lua recognises a log quest whose number we do not know by its title (An Earnest
-- Proposition 84157 for 8915) and calls this once per number: a quiet "newid" report, sent once per
-- account, tells the team to add the number to the data (report: "make reports for these and fix
-- them automatically").
root.OnNewQuestId = function(qid, title, ids)
    local d = DB()
    if not d or type(qid) ~= "number" then return end
    d.newIdSent = d.newIdSent or {}
    if d.newIdSent[qid] then return end
    d.newIdSent[qid] = true
    local known = {}
    for _, id in ipairs(ids or {}) do known[#known + 1] = tostring(id) end
    R.New("newid", string.format("Forever quest %d \"%s\" = our %s", qid, tostring(title), table.concat(known, ",")), nil, true,
        { qid = qid })
end
