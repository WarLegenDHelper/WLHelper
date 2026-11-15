-- Writs/Guild.lua: the Guild module (/wl guild).
--
--  Members   The whole guild from the game's roster: online first, class colour, level, where they
--            are (or when they were last on), rank, and a mark on those who have WL Helper.
--  PvP       A ranking of open-world kills. Each copy of WL Helper counts its own player's killing
--            blows on enemy players outside battlegrounds and arenas (this week and in total), with
--            the game's lifetime honorable kills when the client gives them, and tells the guild on
--            its addon channel. Only members who have the addon appear in the ranking.
-- Only counts, levels and the version travel; nothing else about the character.
local ADDON, root = ...
root.Writs = root.Writs or {}
local ns = root.Writs
local WP = ns.WP
local L = ns.L
local S = ns.S
local C = S.C

ns.AddEnglish({
    ["Guilde"] = "Guild",
    ["Membres"] = "Members",
    ["Classement PvP"] = "PvP ranking",
    ["En ligne seulement"] = "Online only",
    ["%d en ligne sur %d"] = "%d online of %d",
    ["Pas de guilde."] = "No guild.",
    ["Cette semaine"] = "This week",
    ["Depuis toujours"] = "All time",
    ["victimes"] = "kills",
    ["VH"] = "HK",
    ["Toi : %d cette semaine · %d au total"] = "You: %d this week · %d in total",
    ["Victimes tuées de ta main en monde ouvert (pas en champ de bataille ni en arène), comptées par WL Helper. Seuls les membres qui ont l'addon apparaissent."] =
        "Enemy players you landed the killing blow on in the open world (not in battlegrounds or arenas), counted by WL Helper. Only members who have the addon appear.",
    ["Personne n'a encore de victime cette semaine."] = "Nobody has a kill this week yet.",
    ["Personne n'a encore de victime."] = "Nobody has a kill yet.",
    ["a WL Helper"] = "has WL Helper",
    ["il y a %d j"] = "%d d ago",
    ["il y a %d h"] = "%d h ago",
    ["Voir toute la guilde et le classement PvP"] = "See the whole guild and the PvP ranking",
    ["%d en ligne"] = "%d online",
    ["Tu es %de du classement de la semaine"] = "You are #%d in this week's ranking",
    ["Victime en monde ouvert : %s (%d cette semaine)"] = "Open-world kill: %s (%d this week)",
})

local PREFIX = "WLHgld"
local CI = C_ChatInfo
local Register = (CI and CI.RegisterAddonMessagePrefix) or RegisterAddonMessagePrefix
local SendRaw = (CI and CI.SendAddonMessage) or SendAddonMessage
if Register then pcall(Register, PREFIX) end

local function Me() return (UnitName("player")) end
local function Short(n) return n and (n:gsub("%-.*$", "")) end
local function Week() return date("%Y-%W") end
local function On() return WP.ModuleOn("guild") end

-- ---------------------------------------------------------------- my counts
local function Mine()
    WLWritsCharDB.pvp = WLWritsCharDB.pvp or { kb = 0, week = 0, wk = Week() }
    local p = WLWritsCharDB.pvp
    if p.wk ~= Week() then p.wk, p.week = Week(), 0 end
    return p
end
local function LifetimeHK()
    if GetPVPLifetimeStats then
        local ok, hk = pcall(GetPVPLifetimeStats)
        if ok and type(hk) == "number" then return hk end
    end
    return 0
end

local function Board()
    WLWritsDB.guild = WLWritsDB.guild or {}
    return WLWritsDB.guild
end

-- ---------------------------------------------------------------- sharing
local lastSent, shareQueued = 0, false
local function Share(force)
    if not (On() and IsInGuild and IsInGuild() and SendRaw) then return end
    if not force and GetTime() - lastSent < 30 then
        if not shareQueued then
            shareQueued = true
            C_Timer.After(31 - (GetTime() - lastSent), function() shareQueued = false; Share(true) end)
        end
        return
    end
    lastSent = GetTime()
    local p = Mine()
    local meta = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
    local ver = meta and meta(ADDON, "Version") or "?"
    pcall(SendRaw, PREFIX, table.concat({ "P", p.kb, p.week, p.wk, LifetimeHK(), UnitLevel("player") or 0, ver }, "|"), "GUILD")
    local b = Board()
    b[Me()] = { kb = p.kb, week = p.week, wk = p.wk, hk = LifetimeHK(), lvl = UnitLevel("player"), ver = ver, t = time() }
end

local askedAt = 0
local function Ask()
    if not (IsInGuild and IsInGuild() and SendRaw) or GetTime() - askedAt < 60 then return end
    askedAt = GetTime()
    pcall(SendRaw, PREFIX, "R", "GUILD")
end

local function OnMessage(msg, sender)
    local kind = msg:match("^(%u)")
    if kind == "R" then Share()
    elseif kind == "P" then
        local kb, week, wk, hk, lvl, ver = msg:match("^P|(%d+)|(%d+)|([%d%-]+)|(%d+)|(%d+)|([^|]*)$")
        if kb then
            Board()[sender] = { kb = tonumber(kb), week = tonumber(week), wk = wk, hk = tonumber(hk), lvl = tonumber(lvl), ver = ver, t = time() }
            if WP.RefreshGuild then WP.RefreshGuild() end
        end
    end
end

-- ---------------------------------------------------------------- counting kills
local band = bit and bit.band
local HOSTILE = COMBATLOG_OBJECT_REACTION_HOSTILE or 0x40
local function InWorld()
    local _, kind = IsInInstance()
    return kind ~= "pvp" and kind ~= "arena"
end
local function OnCombatLog()
    local _, sub, _, src, _, _, _, dst, dstName, dstFlags = CombatLogGetCurrentEventInfo()
    if sub ~= "PARTY_KILL" or src ~= UnitGUID("player") then return end
    if type(dst) ~= "string" or not dst:find("^Player%-") then return end
    if band and dstFlags and band(dstFlags, HOSTILE) == 0 then return end
    if not InWorld() then return end
    local p = Mine()
    p.kb, p.week = (p.kb or 0) + 1, (p.week or 0) + 1
    if WLWritsDB.guildToast ~= false then
        WP.Print(string.format(L("Victime en monde ouvert : %s (%d cette semaine)"), Short(dstName) or "?", p.week))
    end
    Share()
    if WP.RefreshGuild then WP.RefreshGuild() end
end

-- ---------------------------------------------------------------- the roster
local function Roster(onlineOnly)
    local out, online = {}, 0
    if not (IsInGuild and IsInGuild() and GetNumGuildMembers) then return out, 0 end
    for i = 1, (GetNumGuildMembers() or 0) do
        local name, rank, _, level, _, zone, _, _, isOnline, _, class = GetGuildRosterInfo(i)
        if name then
            if isOnline then online = online + 1 end
            if isOnline or not onlineOnly then
                local y, m, d, h = 0, 0, 0, 0
                if not isOnline and GetGuildRosterLastOnline then y, m, d, h = GetGuildRosterLastOnline(i) end
                out[#out + 1] = { name = Short(name), rank = rank, level = level or 0, zone = zone, online = isOnline and true or false,
                    class = class, away = ((y or 0) * 365 + (m or 0) * 30 + (d or 0)) * 24 + (h or 0) }
            end
        end
    end
    table.sort(out, function(a, b)
        if a.online ~= b.online then return a.online end
        if a.online then
            if a.level ~= b.level then return a.level > b.level end
            return a.name < b.name
        end
        return a.away < b.away
    end)
    return out, online
end
WP.GuildRoster = Roster

-- { { name, n, hk, lvl }, ... } best first; week = this week's kills
function WP.GuildRanking(week)
    local wk, out = Week(), {}
    Share()   -- my own line is fresh
    for name, e in pairs(Board()) do
        local n = week and ((e.wk == wk) and e.week or 0) or e.kb
        if (n or 0) > 0 then out[#out + 1] = { name = name, n = n, hk = e.hk or 0, lvl = e.lvl } end
    end
    table.sort(out, function(a, b) if a.n ~= b.n then return a.n > b.n end return a.name < b.name end)
    return out
end
function WP.GuildMine() local p = Mine(); return p.week, p.kb end

-- ---------------------------------------------------------------- the window
local W, H, PAD = 560, 600, 16
local win, tabs, current = nil, nil, "members"
local pages, ui = {}, {}

local function List(parent, top, bottom, make)
    local sf = CreateFrame("ScrollFrame", nil, parent)
    sf:SetPoint("TOPLEFT", PAD, top); sf:SetPoint("BOTTOMRIGHT", -PAD, bottom)
    local content = CreateFrame("Frame", nil, sf); content:SetSize(W - 2 * PAD, 10); sf:SetScrollChild(content)
    sf:EnableMouseWheel(true)
    sf:SetScript("OnMouseWheel", function(self, d)
        local max = math.max(0, content:GetHeight() - self:GetHeight())
        self:SetVerticalScroll(math.max(0, math.min(max, self:GetVerticalScroll() - d * 52)))
    end)
    local l = { sf = sf, content = content, items = {} }
    function l.Get(i) local f = l.items[i]; if not f then f = make(content); l.items[i] = f end; f:Show(); return f end
    function l.HideFrom(i) for j = i, #l.items do l.items[j]:Hide() end end
    return l
end

local function ClassColor(class)
    local c = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
    return c and { c.r, c.g, c.b } or C.text
end
local function Ago(hours)
    if hours >= 24 then return string.format(L("il y a %d j"), math.floor(hours / 24)) end
    return string.format(L("il y a %d h"), math.max(1, hours))
end

local function MemberRow(parent)
    local r = CreateFrame("Frame", nil, parent)
    r:SetSize(W - 2 * PAD, 28)
    r.bg = S.Solid(r, "BACKGROUND", C.card); r.bg:SetAllPoints()
    r.dot = S.Solid(r, "ARTWORK", C.ready); r.dot:SetSize(6, 6); r.dot:SetPoint("LEFT", 8, 0)
    r.lvl = S.Text(r, 12, C.dim, true); r.lvl:SetPoint("LEFT", 22, 0); r.lvl:SetWidth(24); r.lvl:SetJustifyH("RIGHT")
    r.name = S.Text(r, 14, C.text, true); r.name:SetPoint("LEFT", 54, 0); r.name:SetWidth(150); r.name:SetJustifyH("LEFT")
    r.logo = r:CreateTexture(nil, "OVERLAY"); r.logo:SetSize(14, 14); r.logo:SetTexture(S.LOGO); r.logo:SetPoint("LEFT", r.name, "LEFT", 0, 0)
    r.where = S.Text(r, 12, C.dim); r.where:SetPoint("LEFT", 216, 0); r.where:SetWidth(190); r.where:SetJustifyH("LEFT")
    r.rank = S.Text(r, 12, C.muted); r.rank:SetPoint("RIGHT", -10, 0); r.rank:SetWidth(110); r.rank:SetJustifyH("RIGHT")
    r:EnableMouse(true)
    r:SetScript("OnEnter", function(self) if self.addon then S.Tip(self, { self.fullName or "", L("a WL Helper") .. (self.ver and (" · v" .. self.ver) or "") }) end end)
    r:SetScript("OnLeave", S.HideTip)
    return r
end

local function RankRow(parent)
    local r = CreateFrame("Frame", nil, parent)
    r:SetSize(W - 2 * PAD, 34)
    r.bg = S.Solid(r, "BACKGROUND", C.card); r.bg:SetAllPoints()
    r.pos = S.Text(r, 16, C.dim, true); r.pos:SetPoint("LEFT", 10, 0); r.pos:SetWidth(30); r.pos:SetJustifyH("LEFT")
    r.name = S.Text(r, 14, C.text, true); r.name:SetPoint("LEFT", 46, 0); r.name:SetWidth(220); r.name:SetJustifyH("LEFT")
    r.n = S.Text(r, 16, C.text, true); r.n:SetPoint("RIGHT", -110, 0); r.n:SetJustifyH("RIGHT")
    r.unit = S.Text(r, 12, C.dim); r.unit:SetPoint("LEFT", r.n, "RIGHT", 5, -1)
    r.hk = S.Text(r, 12, C.muted); r.hk:SetPoint("RIGHT", -10, 0); r.hk:SetJustifyH("RIGHT")
    return r
end

local function RenderMembers()
    local list, online = Roster(WLWritsDB.guildOnline ~= false)
    local all = IsInGuild() and GetNumGuildMembers() or 0
    ui.count:SetText(IsInGuild() and string.format(L("%d en ligne sur %d"), online, all) or L("Pas de guilde."))
    local board = Board()
    for i, m in ipairs(list) do
        local r = ui.members.Get(i)
        r:ClearAllPoints(); r:SetPoint("TOPLEFT", 0, -(i - 1) * 30)
        r.bg:SetAlpha(i % 2 == 0 and 0.6 or 1)
        local col = ClassColor(m.class)
        r.addon = board[m.name] ~= nil
        r.ver = board[m.name] and board[m.name].ver
        r.fullName = m.name
        r.logo:SetShown(r.addon)
        r.name:ClearAllPoints(); r.name:SetPoint("LEFT", r.addon and 72 or 54, 0)
        r.logo:ClearAllPoints(); r.logo:SetPoint("LEFT", 54, 0)
        r.name:SetText(m.name); r.name:SetTextColor(col[1], col[2], col[3], m.online and 1 or 0.55)
        r.lvl:SetText(m.level)
        r.dot:SetColorTexture(m.online and C.ready[1] or 0.3, m.online and C.ready[2] or 0.32, m.online and C.ready[3] or 0.35, 1)
        r.where:SetText(m.online and (m.zone or "") or Ago(m.away))
        r.rank:SetText(m.rank or "")
    end
    ui.members.HideFrom(#list + 1)
    ui.members.content:SetHeight(math.max(10, #list * 30))
end

local function RenderPvP()
    local week = (WLWritsDB.guildRankWeek ~= false)
    local list = WP.GuildRanking(week)
    local w, total = WP.GuildMine()
    ui.mine:SetText(string.format(L("Toi : %d cette semaine · %d au total"), w or 0, total or 0))
    local medal = { { 1, 0.82, 0.3 }, { 0.82, 0.85, 0.9 }, { 0.85, 0.55, 0.3 } }
    for i, e in ipairs(list) do
        local r = ui.rank.Get(i)
        r:ClearAllPoints(); r:SetPoint("TOPLEFT", 0, -(i - 1) * 38)
        local col = medal[i] or C.dim
        r.pos:SetText("#" .. i); r.pos:SetTextColor(col[1], col[2], col[3])
        r.name:SetText(e.name .. (e.name == Me() and (" " .. S.Hex(C.brandSoft) .. "·|r") or ""))
        r.n:SetText(e.n); r.unit:SetText(L("victimes"))
        r.hk:SetText(e.hk > 0 and (e.hk .. " " .. L("VH")) or "")
    end
    ui.rank.HideFrom(#list + 1)
    ui.rank.content:SetHeight(math.max(10, #list * 38))
    ui.none:SetShown(#list == 0)
    ui.none:SetText(week and L("Personne n'a encore de victime cette semaine.") or L("Personne n'a encore de victime."))
end

local function Build()
    win = S.Window("WLHelperGuild", W, H, L("Guilde"), GetGuildInfo and GetGuildInfo("player") or nil, WLWritsDB, "guildPos")
    tabs = S.Tabs(win, { { "members", L("Membres") }, { "pvp", L("Classement PvP") } },
        function() return current end, function(k) WP.ShowGuildTab(k) end)
    tabs:SetPoint("TOPLEFT", 1, -39); tabs:SetPoint("TOPRIGHT", -1, -39)
    for _, k in ipairs({ "members", "pvp" }) do
        local p = CreateFrame("Frame", nil, win)
        p:SetPoint("TOPLEFT", 0, -76); p:SetPoint("BOTTOMRIGHT")
        p:Hide(); pages[k] = p
    end
    -- members
    local m = pages.members
    ui.count = S.Text(m, 13, C.dim); ui.count:SetPoint("TOPLEFT", PAD, -12)
    local only = S.Switch(m, function() return WLWritsDB.guildOnline ~= false end, function(v) WLWritsDB.guildOnline = v; WP.RefreshGuild() end)
    only:SetPoint("TOPRIGHT", -PAD, -8)
    local onlyText = S.Text(m, 13, C.text); onlyText:SetPoint("RIGHT", only, "LEFT", -8, 0); onlyText:SetText(L("En ligne seulement"))
    ui.members = List(m, -42, PAD, MemberRow)
    -- pvp
    local p = pages.pvp
    ui.mine = S.Text(p, 14, C.text, true); ui.mine:SetPoint("TOPLEFT", PAD, -12)
    local seg = S.Segmented(p, { { true, L("Cette semaine") }, { false, L("Depuis toujours") } },
        function() return WLWritsDB.guildRankWeek ~= false end, function(v) WLWritsDB.guildRankWeek = v; WP.RefreshGuild() end, 26)
    seg:SetPoint("TOPRIGHT", -PAD, -6)
    local note = S.Text(p, 12, C.muted); note:SetPoint("BOTTOMLEFT", PAD, 12); note:SetPoint("RIGHT", -PAD, 0)
    note:SetJustifyH("LEFT"); note:SetWordWrap(true)
    note:SetText(L("Victimes tuées de ta main en monde ouvert (pas en champ de bataille ni en arène), comptées par WL Helper. Seuls les membres qui ont l'addon apparaissent."))
    ui.rank = List(p, -44, 60, RankRow)
    ui.none = S.Text(ui.rank.content, 13, C.dim); ui.none:SetPoint("TOPLEFT", 2, -8)
    win:SetScript("OnShow", function()
        if C_GuildInfo and C_GuildInfo.GuildRoster then pcall(C_GuildInfo.GuildRoster) elseif GuildRoster then pcall(GuildRoster) end
        Ask()
        WP.RefreshGuild()
    end)
end

function WP.ShowGuildTab(k)
    if not win then Build() end
    current = k
    for key, pg in pairs(pages) do pg:SetShown(key == k) end
    win:Show(); win:Raise()
    WP.RefreshGuild()
end
function WP.RefreshGuild()
    if not (win and win:IsShown()) then return end
    tabs:Update()
    if current == "members" then RenderMembers() else RenderPvP() end
end
function WP.ToggleGuild()
    if win and win:IsShown() then win:Hide(); return end
    if WP.ModuleOff and WP.ModuleOff("guild") then return end
    WP.ShowGuildTab(current)
end
function WP.HideGuild() if win then win:Hide() end end

-- ---------------------------------------------------------------- events
local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:RegisterEvent("CHAT_MSG_ADDON")
ev:RegisterEvent("GUILD_ROSTER_UPDATE")
ev:SetScript("OnEvent", function(self, e, prefix, msg, channel, sender)
    if not WLWritsDB then return end
    if e == "PLAYER_LOGIN" then
        pcall(self.RegisterEvent, self, "COMBAT_LOG_EVENT_UNFILTERED")
        C_Timer.After(25, function() Share(true) end)
    elseif e == "COMBAT_LOG_EVENT_UNFILTERED" then
        if On() then OnCombatLog() end
    elseif e == "GUILD_ROSTER_UPDATE" then
        WP.RefreshGuild()
    elseif prefix == PREFIX and channel == "GUILD" and type(msg) == "string" and sender then
        local who = Short(sender)
        if who ~= Me() then OnMessage(msg, who) end
    end
end)
