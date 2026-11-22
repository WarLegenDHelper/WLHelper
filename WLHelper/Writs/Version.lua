-- Writs/Version.lua: "a newer version exists". An addon cannot reach the internet, so each copy of
-- WL Helper tells the others its version, quietly, on the guild's and the group's addon channel
-- (at login, when you join a group, and in answer to an older version).
-- A newer version is believed only once at least 2 different guild members have reported that same
-- version (one sender alone can be wrong or lying); the reports are kept 3 weeks, across sessions.
-- Then: one chat line per session, and a line on the home page, until you update. Malformed versions
-- and absurd ones (a major more than one above yours) are ignored.
-- Only the version number is sent: nothing about the character.
local ADDON, root = ...
root.Writs = root.Writs or {}
local ns = root.Writs
local WP = ns.WP
local L = ns.L

ns.AddEnglish({
    -- the chat line, once per session
    ["La version %s de WL Helper est sortie, vue chez %d membres (tu as la %s). Mets-la à jour dans WowUp, puis tape /reload pour la charger."] =
        "WL Helper %s is out, seen on %d members (you have %s). Update it in WowUp, then type /reload to load it.",
    -- the home page banner and the minimap tooltip
    ["La version %s est sortie, vue chez %d membres. Mets à jour WL Helper dans WowUp, puis tape /reload pour la charger."] =
        "Version %s is out, seen on %d members. Update WL Helper in WowUp, then type /reload to load it.",
})

local NEEDED = 2                  -- different guild members reporting the same version
local KEEP = 21 * 24 * 3600       -- a report is forgotten after 3 weeks
local MAX_VERSIONS = 10           -- versions kept in the saved reports
local MAX_SENDERS = 40            -- senders kept per version

local function Secret(v) return issecretvalue and issecretvalue(v) end
local function Now() return (time and time()) or 0 end

local PREFIX = "WLHver"
local CI = C_ChatInfo
local Register = (CI and CI.RegisterAddonMessagePrefix) or RegisterAddonMessagePrefix
local Send = (CI and CI.SendAddonMessage) or SendAddonMessage
if Register then pcall(Register, PREFIX) end

local function Mine()
    local meta = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
    return meta and meta(ADDON, "Version") or "0"
end

-- "1.0.0-beta.6" -> comparable numbers: 1, 0, 0, stage (alpha 1, beta 2, rc 3, release 4), 6
local STAGE = { alpha = 1, beta = 2, rc = 3 }
local function Parse(v)
    local a, b, c, rest = tostring(v or ""):match("^(%d+)%.(%d+)%.(%d+)(.*)$")
    if not a then return nil end
    local stage, n = rest:match("^%-(%a+)%.(%d+)$")
    return { tonumber(a), tonumber(b), tonumber(c), stage and (STAGE[stage] or 0) or 4, tonumber(n) or 0 }
end
-- true when version x is newer than y
function WP.NewerVersion(x, y)
    local a, b = Parse(x), Parse(y)
    if not (a and b) then return false end
    for i = 1, 5 do
        if a[i] ~= b[i] then return a[i] > b[i] end
    end
    return false
end

-- A version worth counting: well formed ("1.2.3" or "1.2.3-beta.4", nothing else), a known stage,
-- small numbers, and a major at most one above yours.
local function Sane(v)
    if type(v) ~= "string" or #v > 24 then return false end
    if not (v:match("^%d+%.%d+%.%d+$") or v:match("^%d+%.%d+%.%d+%-%a+%.%d+$")) then return false end
    local p = Parse(v)
    if not p or p[4] == 0 then return false end
    for i = 1, 5 do if p[i] > 999 then return false end end
    local m = Parse(Mine())
    if m and p[1] > m[1] + 1 then return false end
    return true
end
WP.SaneVersion = Sane

-- Saved reports: WLWritsDB.versionSeen[version][sender] = time of the last report.
local function Reports()
    if not WLWritsDB then return nil end
    if type(WLWritsDB.versionSeen) ~= "table" then WLWritsDB.versionSeen = {} end
    return WLWritsDB.versionSeen
end

-- Forget old reports, versions no longer newer than yours, and anything malformed; keep 10 versions.
local function Prune()
    local seen = Reports()
    if not seen then return end
    local now, mine = Now(), Mine()
    local keep = {}
    for v, who in pairs(seen) do
        local alive = false
        if type(v) == "string" and type(who) == "table" and Sane(v) and WP.NewerVersion(v, mine) then
            for name, t in pairs(who) do
                if type(t) ~= "number" or now - t > KEEP then who[name] = nil else alive = true end
            end
        end
        if alive then keep[#keep + 1] = v else seen[v] = nil end
    end
    if #keep > MAX_VERSIONS then
        -- too many: the versions with the fewest witnesses go first, then the oldest numbers
        local count = {}
        for _, v in ipairs(keep) do
            local n = 0
            for _ in pairs(seen[v]) do n = n + 1 end
            count[v] = n
        end
        table.sort(keep, function(a, b)
            if count[a] ~= count[b] then return count[a] > count[b] end
            return WP.NewerVersion(a, b)
        end)
        for i = MAX_VERSIONS + 1, #keep do seen[keep[i]] = nil end
    end
end

-- How many different guild members reported this version (recent reports only).
function WP.VersionWitnesses(version)
    local seen = WLWritsDB and type(WLWritsDB.versionSeen) == "table" and WLWritsDB.versionSeen[version]
    if type(seen) ~= "table" then return 0 end
    local now, n = Now(), 0
    for _, t in pairs(seen) do
        if type(t) == "number" and now - t <= KEEP then n = n + 1 end
    end
    return n
end

-- The newest version at least 2 guild members have, when it is newer than yours (else nil),
-- and how many members reported it.
function WP.UpdateAvailable()
    local seen = WLWritsDB and WLWritsDB.versionSeen
    if type(seen) ~= "table" then return nil end
    local mine, best, count = Mine(), nil, 0
    for v in pairs(seen) do
        if type(v) == "string" and Sane(v) and WP.NewerVersion(v, mine) then
            local n = WP.VersionWitnesses(v)
            if n >= NEEDED and (not best or WP.NewerVersion(v, best)) then best, count = v, n end
        end
    end
    if not best then return nil end
    return best, count
end

-- The sentence that tells about a newer version (home page banner, minimap tooltip).
function WP.UpdateText(version)
    local n = math.max(WP.VersionWitnesses(version), NEEDED)
    return string.format(L("La version %s est sortie, vue chez %d membres. Mets à jour WL Helper dans WowUp, puis tape /reload pour la charger."), tostring(version), n)
end

-- Your realm, without spaces ("" when unknown or secret).
local function MyRealm()
    local r = GetNormalizedRealmName and GetNormalizedRealmName()
    if (type(r) ~= "string" or Secret(r) or r == "") and GetRealmName then
        r = GetRealmName()
        if type(r) == "string" and not Secret(r) then r = r:gsub("[%s%-]", "") end
    end
    if type(r) ~= "string" or Secret(r) then return "" end
    return r
end
-- "Name-Realm" in lower case: a name without realm is on yours. Two players of different realms
-- with the same name stay apart.
local function Full(name)
    name = tostring(name)
    if not name:find("-", 1, true) then
        local r = MyRealm()
        if r ~= "" then name = name .. "-" .. r end
    end
    return name:lower()
end

-- Guild members' full names, lower case (cached a minute), to tell whether a group sender is one.
local roster, rosterAt = nil, nil
local function InGuild(name)
    if not (IsInGuild and IsInGuild() and GetNumGuildMembers and GetGuildRosterInfo) then return false end
    local now = GetTime and GetTime() or 0
    if not roster or not rosterAt or now - rosterAt > 60 then
        roster, rosterAt = {}, now
        local ok, total = pcall(GetNumGuildMembers)
        local any = false
        for i = 1, (ok and tonumber(total) or 0) do
            local ok2, n = pcall(GetGuildRosterInfo, i)
            if ok2 and type(n) == "string" and n ~= "" and not Secret(n) then roster[Full(n)] = true; any = true end
        end
        if not any then
            -- roster not loaded yet: ask the server, and look again next time instead of caching nothing
            rosterAt = nil
            local ask = (C_GuildInfo and C_GuildInfo.GuildRoster) or GuildRoster
            if ask then pcall(ask) end
        end
    end
    return roster[Full(name)] == true
end

local lastSent = {}
local function Announce(channel)
    if not Send or not channel then return end
    if lastSent[channel] and GetTime() - lastSent[channel] < 60 then return end   -- once a minute at most
    lastSent[channel] = GetTime()
    root.AddonSend(PREFIX, "V:" .. Mine(), channel, nil, Send)
end
local function GroupChannel()
    if IsInRaid and IsInRaid() then return "RAID" end
    if IsInGroup and IsInGroup() then return "PARTY" end
end

local told = false
-- the home page is redrawn when what it shows changes (the version or its count), once per second
-- at most: a burst of reports never redraws it for each one
local shown, homeQueued = nil, false
local function HomeChanged(best, n)
    local sig = tostring(best) .. "/" .. tostring(n)
    if sig == shown or not WP.RefreshHome then return end
    shown = sig
    if homeQueued then return end
    if not (C_Timer and C_Timer.After) then WP.RefreshHome(); return end
    homeQueued = true
    C_Timer.After(1, function() homeQueued = false; if WP.RefreshHome then WP.RefreshHome() end end)
end
local function Seen(version, channel, sender)
    local mine = Mine()
    if WP.NewerVersion(version, mine) then
        if not Sane(version) then return end
        -- only guild members count: anyone on the guild channel, a group member found in the roster
        if channel ~= "GUILD" and not InGuild(sender) then return end
        local seen = Reports()
        if not seen then return end
        local who = seen[version]
        if type(who) ~= "table" then who = {}; seen[version] = who end
        local key = Full(sender)
        -- a sender counts for one version only (its latest report), so one sender cannot fill the
        -- saved reports with made-up versions and push a confirmed one out
        for v, other in pairs(seen) do
            if v ~= version and type(other) == "table" then other[key] = nil end
        end
        if who[key] == nil then
            local n = 0
            for _ in pairs(who) do n = n + 1 end
            if n >= MAX_SENDERS then return end
        end
        who[key] = Now()
        Prune()
        local best, n = WP.UpdateAvailable()
        if best and not told then
            told = true
            WP.Print(string.format(L("La version %s de WL Helper est sortie, vue chez %d membres (tu as la %s). Mets-la à jour dans WowUp, puis tape /reload pour la charger."), best, n, mine))
        end
        if best then HomeChanged(best, n) end
    elseif WP.NewerVersion(mine, version) then
        Announce(channel)   -- an older copy answered: tell it ours
    end
end

local f = CreateFrame("Frame")
pcall(f.RegisterEvent, f, "PLAYER_LOGIN")
pcall(f.RegisterEvent, f, "GROUP_JOINED")
pcall(f.RegisterEvent, f, "CHAT_MSG_ADDON")
f:SetScript("OnEvent", function(_, e, prefix, msg, channel, sender)
    if e == "PLAYER_LOGIN" then
        -- a version older copies believed from a single sender: forgotten, the reports decide now
        if WLWritsDB then WLWritsDB.newestVersion = nil end
        -- the version you updated to is no longer "newer": its reports go
        Prune()
        C_Timer.After(15, function()
            if IsInGuild and IsInGuild() then Announce("GUILD") end
            Announce(GroupChannel())
        end)
    elseif e == "GROUP_JOINED" then
        C_Timer.After(3, function() Announce(GroupChannel()) end)
    elseif e == "CHAT_MSG_ADDON" and WLWritsDB then
        if Secret(prefix) or Secret(msg) or Secret(channel) or Secret(sender) then return end
        if prefix ~= PREFIX or type(msg) ~= "string" or type(sender) ~= "string" or sender == "" then return end
        local me = UnitName("player")
        if me and not Secret(me) and Full(sender) == Full(me) then return end
        if channel ~= "GUILD" and channel ~= "PARTY" and channel ~= "RAID" and channel ~= "INSTANCE_CHAT" then return end
        local v = msg:match("^V:(.+)$")
        if v and Parse(v) then Seen(v, channel, sender) end
    end
end)
