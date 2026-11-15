-- Writs/Version.lua: "a newer version exists". An addon cannot reach the internet, so each copy of
-- WL Helper tells the others its version, quietly, on the guild's and the group's addon channel
-- (at login, when you join a group, and in answer to an older version). The newest version seen
-- is kept: one chat line per session, and a line on the home page, until you update.
-- Only the version number is sent: nothing about the character.
local ADDON, root = ...
root.Writs = root.Writs or {}
local ns = root.Writs
local WP = ns.WP
local L = ns.L

ns.AddEnglish({
    -- the chat line, once per session
    ["La version %s de WL Helper est sortie (tu as la %s). Mets-la à jour dans WowUp, puis tape /reload pour la charger."] =
        "WL Helper %s is out (you have %s). Update it in WowUp, then type /reload to load it.",
    -- the home page banner and the minimap tooltip
    ["La version %s est sortie. Mets à jour WL Helper dans WowUp, puis tape /reload pour la charger."] =
        "Version %s is out. Update WL Helper in WowUp, then type /reload to load it.",
})

-- The sentence that tells about a newer version (home page banner, minimap tooltip).
function WP.UpdateText(version)
    return string.format(L("La version %s est sortie. Mets à jour WL Helper dans WowUp, puis tape /reload pour la charger."), tostring(version))
end

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

-- The newest version another player has, when it is newer than yours (else nil).
function WP.UpdateAvailable()
    local seen = WLWritsDB and WLWritsDB.newestVersion
    if seen and WP.NewerVersion(seen, Mine()) then return seen end
    return nil
end

local lastSent = {}
local function Announce(channel)
    if not Send or not channel then return end
    if lastSent[channel] and GetTime() - lastSent[channel] < 60 then return end   -- once a minute at most
    lastSent[channel] = GetTime()
    pcall(Send, PREFIX, "V:" .. Mine(), channel)
end
local function GroupChannel()
    if IsInRaid and IsInRaid() then return "RAID" end
    if IsInGroup and IsInGroup() then return "PARTY" end
end

local told = false
local function Seen(version, channel)
    local mine = Mine()
    if WP.NewerVersion(version, mine) then
        if not WLWritsDB.newestVersion or WP.NewerVersion(version, WLWritsDB.newestVersion) then
            WLWritsDB.newestVersion = version
        end
        if not told then
            told = true
            WP.Print(string.format(L("La version %s de WL Helper est sortie (tu as la %s). Mets-la à jour dans WowUp, puis tape /reload pour la charger."), version, mine))
        end
        if WP.RefreshHome then WP.RefreshHome() end
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
        -- the version you updated to is no longer "newer": forget it
        if WLWritsDB and WLWritsDB.newestVersion and not WP.NewerVersion(WLWritsDB.newestVersion, Mine()) then
            WLWritsDB.newestVersion = nil
        end
        C_Timer.After(15, function()
            if IsInGuild and IsInGuild() then Announce("GUILD") end
            Announce(GroupChannel())
        end)
    elseif e == "GROUP_JOINED" then
        C_Timer.After(3, function() Announce(GroupChannel()) end)
    elseif prefix == PREFIX and type(msg) == "string" and WLWritsDB then
        local me = UnitName("player")
        if sender and me and sender:gsub("%-.*$", "") == me then return end
        if channel ~= "GUILD" and channel ~= "PARTY" and channel ~= "RAID" and channel ~= "INSTANCE_CHAT" then return end
        local v = msg:match("^V:(.+)$")
        if v and Parse(v) then Seen(v, channel) end
    end
end)
