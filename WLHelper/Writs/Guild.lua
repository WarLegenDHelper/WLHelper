-- Writs/Guild.lua: the Guild module (/wlh guild).
--
--  Members   The whole guild from the game's roster, with a search, a sort (level, name, zone, rank),
--            where the guild is right now (the busiest zones), and on each line: online dot, level,
--            class colour, zone (or when the member was last on), rank, the WL logo on those who
--            have the addon. Click: whisper. Right-click: invite. The tooltip adds the public note,
--            the professions the member shares (Orders) and the addon's version.
--  PvP       A ranking of honorable kills, as the game counts them (battlegrounds included): this
--            week, this season (one season = one calendar month) and all time. The game keeps the
--            all-time total, so it shows from day one; week and season follow from it. Each copy of
--            WL Helper tells the guild its own numbers on the addon channel; the season's podium is
--            kept when a new season starts. Kills made in the open world are counted apart.
-- The combat log is closed to addons on this client: nothing here reads it.
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
    ["Saison"] = "Season",
    ["Depuis toujours"] = "All time",
    ["VH"] = "HK",
    ["a WL Helper"] = "has WL Helper",
    ["il y a %d j"] = "%d d ago",
    ["il y a %d h"] = "%d h ago",
    ["Voir toute la guilde et le classement PvP"] = "See the whole guild and the PvP ranking",
    ["%d en ligne"] = "%d online",
    ["Tu es %de du classement de la semaine"] = "You are #%d in this week's ranking",
    ["Victoire honorable en monde ouvert (%d cette semaine)"] = "Open-world honorable kill (%d this week)",
    ["Toi : %d cette semaine · %d cette saison · %d au total"] = "You: %d this week · %d this season · %d in total",
    ["Victoires honorables comptées par le jeu, champs de bataille compris. Une saison dure un mois. Seuls les membres qui ont WL Helper apparaissent ; leurs chiffres arrivent quand ils se connectent."] =
        "Honorable kills as the game counts them, battlegrounds included. A season lasts a month. Only members who have WL Helper appear; their numbers arrive when they log in.",
    ["Personne n'a encore de victoire cette semaine."] = "Nobody has a kill this week yet.",
    ["Personne n'a encore de victoire cette saison."] = "Nobody has a kill this season yet.",
    ["Personne n'a encore de victoire."] = "Nobody has a kill yet.",
    ["dont %d en monde ouvert"] = "%d in the open world",
    ["Saison %s"] = "Season %s",
    ["Saison précédente (%s) : %s"] = "Last season (%s): %s",
    ["Chercher un nom, une zone, un rang"] = "Search a name, a zone, a rank",
    ["Niveau"] = "Level",
    ["Nom"] = "Name",
    ["Zone"] = "Zone",
    ["Rang"] = "Rank",
    ["Où est la guilde : %s"] = "Where the guild is: %s",
    ["Clic : chuchoter · clic droit ou Alt-clic : inviter"] = "Click: whisper · right-click or Alt-click: invite",
    ["Note : %s"] = "Note: %s",
    ["Métiers : %s"] = "Professions: %s",
    ["Aucun membre ne correspond."] = "No member matches.",
})

local MONTHS = {
    fr = { "janvier", "février", "mars", "avril", "mai", "juin", "juillet", "août", "septembre", "octobre", "novembre", "décembre" },
    en = { "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December" },
}
local function SeasonName(key)
    local y, m = tostring(key or ""):match("^(%d+)%-(%d+)$")
    if not y then return tostring(key or "") end
    local list = (root.lang == "en") and MONTHS.en or MONTHS.fr
    return (list[tonumber(m)] or m) .. " " .. y
end

local PREFIX = "WLHgld"
local CI = C_ChatInfo
local Register = (CI and CI.RegisterAddonMessagePrefix) or RegisterAddonMessagePrefix
local SendRaw = (CI and CI.SendAddonMessage) or SendAddonMessage
if Register then pcall(Register, PREFIX) end

local function Me() return (UnitName("player")) end
-- "Name-Realm" or "Name Realm": the name alone
local function Short(n) return n and (n:gsub("[%- ].*$", "")) end
local function Week() return date("%Y-%W") end
local function Season() return date("%Y-%m") end
local function On() return WP.ModuleOn("guild") end

-- ---------------------------------------------------------------- my numbers
local function LifetimeHK()
    if GetPVPLifetimeStats then
        local ok, hk = pcall(GetPVPLifetimeStats)
        if ok and type(hk) == "number" then return hk end
    end
    return 0
end
-- this week's honorable kills from the game when it gives them (nil otherwise)
local function GameWeekHK()
    if GetPVPThisWeekStats then
        local ok, hk = pcall(GetPVPThisWeekStats)
        if ok and type(hk) == "number" then return hk end
    end
end

local function Mine()
    WLWritsCharDB.pvp = WLWritsCharDB.pvp or {}
    local p = WLWritsCharDB.pvp
    p.kb, p.week = p.kb or 0, p.week or 0                    -- open world: total, this week
    p.weekBase, p.seasonBase = p.weekBase or {}, p.seasonBase or {}
    if p.wk ~= Week() then p.wk, p.week = Week(), 0 end
    return p
end

-- { hk, week, season } from the game's total and the starting points of the week and the season
local function Numbers()
    local p = Mine()
    local hk = LifetimeHK()
    local wk, sk = Week(), Season()
    local gw = GameWeekHK()
    if not p.weekBase[wk] then p.weekBase[wk] = hk - (gw or 0) end
    -- a season seen for the first time starts with this week's kills (the best guess of what came before)
    if not p.seasonBase[sk] then p.seasonBase[sk] = hk - (gw or 0) end
    local week = gw or math.max(0, hk - p.weekBase[wk])
    local season = math.max(week, hk - p.seasonBase[sk])
    return hk, week, season
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
    local hk, week, season = Numbers()
    local meta = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
    local ver = meta and meta(ADDON, "Version") or "?"
    local lvl = UnitLevel("player") or 0
    -- "P" for the copies before 1.0.0-beta.25, "S" with the week and the season
    pcall(SendRaw, PREFIX, table.concat({ "P", p.kb, p.week, p.wk, hk, lvl, ver }, "|"), "GUILD")
    pcall(SendRaw, PREFIX, table.concat({ "S", Week(), week, Season(), season, hk, p.kb, p.week, lvl, ver }, "|"), "GUILD")
    Board()[Me()] = { wk = Week(), w = week, sk = Season(), s = season, hk = hk, kb = p.kb, week = p.week, lvl = lvl, ver = ver, t = time() }
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
    elseif kind == "S" then
        local wk, w, sk, s, hk, kb, owk, lvl, ver = msg:match("^S|([%d%-]+)|(%d+)|([%d%-]+)|(%d+)|(%d+)|(%d+)|(%d+)|(%d+)|([^|]*)")
        if wk then
            Board()[sender] = { wk = wk, w = tonumber(w), sk = sk, s = tonumber(s), hk = tonumber(hk), kb = tonumber(kb),
                week = tonumber(owk), lvl = tonumber(lvl), ver = ver, t = time() }
            if WP.RefreshGuild then WP.RefreshGuild() end
        end
    elseif kind == "P" then
        -- an older copy: all-time total and open-world counts only (an "S" from the same player wins)
        local kb, week, wk, hk, lvl, ver = msg:match("^P|(%d+)|(%d+)|([%d%-]+)|(%d+)|(%d+)|([^|]*)$")
        local cur = Board()[sender]
        if kb and not (cur and cur.sk) then
            Board()[sender] = { kb = tonumber(kb), week = tonumber(week), wk = wk, hk = tonumber(hk), lvl = tonumber(lvl), ver = ver, t = time() }
            if WP.RefreshGuild then WP.RefreshGuild() end
        end
    end
end

-- ---------------------------------------------------------------- open-world kills
-- When the game's total goes up outside a battleground or an arena, the difference is open world.
local function InWorld()
    local _, kind = IsInInstance()
    return kind ~= "pvp" and kind ~= "arena"
end
local function CheckHonor()
    local hk = LifetimeHK()
    if hk <= 0 then return end
    local p = Mine()
    if not p.lastHK or hk < p.lastHK then p.lastHK = hk; Share(); return end   -- first look: the starting point
    local gained = hk - p.lastHK
    p.lastHK = hk
    if gained <= 0 then return end
    if InWorld() then
        p.kb, p.week = (p.kb or 0) + gained, (p.week or 0) + gained
        if WLWritsDB.guildToast ~= false then
            WP.Print(string.format(L("Victoire honorable en monde ouvert (%d cette semaine)"), p.week))
        end
    end
    Share()
    if WP.RefreshGuild then WP.RefreshGuild() end
end

-- ---------------------------------------------------------------- seasons
-- When a new month starts, the podium of the one that ended is kept.
local function Ranking(mode, key)
    local out = {}
    key = key or (mode == "week" and Week() or Season())
    for name, e in pairs(Board()) do
        local n
        if mode == "week" then n = (e.wk == key) and e.w or 0
        elseif mode == "season" then n = (e.sk == key) and e.s or 0
        else n = e.hk or 0 end
        if (n or 0) > 0 then out[#out + 1] = { name = name, n = n, ow = (mode == "all") and (e.kb or 0) or ((e.wk == Week()) and e.week or 0), lvl = e.lvl } end
    end
    table.sort(out, function(a, b) if a.n ~= b.n then return a.n > b.n end return a.name < b.name end)
    return out
end
local function ArchiveSeason()
    local cur = Season()
    local last = WLWritsDB.guildSeasonKey
    if last and last ~= cur then
        WLWritsDB.guildSeasons = WLWritsDB.guildSeasons or {}
        if not WLWritsDB.guildSeasons[last] then
            local top = {}
            for i, e in ipairs(Ranking("season", last)) do if i <= 3 then top[i] = { e.name, e.n } end end
            WLWritsDB.guildSeasons[last] = top
        end
    end
    WLWritsDB.guildSeasonKey = cur
end

-- { { name, n, ow, lvl }, ... } best first. mode: "week", "season", "all" (true = week, false = all)
function WP.GuildRanking(mode)
    if mode == true then mode = "week" elseif mode == false or mode == nil then mode = "all" end
    Share()
    return Ranking(mode)
end
function WP.GuildMine() local hk, week, season = Numbers(); return week, season, hk end

-- ---------------------------------------------------------------- the roster
local function Roster(onlineOnly, filter, sort)
    local out, online, zones = {}, 0, {}
    if not (IsInGuild and IsInGuild() and GetNumGuildMembers) then return out, 0, zones end
    filter = filter and filter ~= "" and filter:lower() or nil
    for i = 1, (GetNumGuildMembers() or 0) do
        local name, rank, _, level, _, zone, note, _, isOnline, _, class = GetGuildRosterInfo(i)
        if name then
            if isOnline then
                online = online + 1
                if zone and zone ~= "" then zones[zone] = (zones[zone] or 0) + 1 end
            end
            local short = Short(name)
            local hit = not filter or short:lower():find(filter, 1, true) or (zone or ""):lower():find(filter, 1, true)
                or (rank or ""):lower():find(filter, 1, true)
            if hit and (isOnline or not onlineOnly) then
                local y, m, d, h = 0, 0, 0, 0
                if not isOnline and GetGuildRosterLastOnline then y, m, d, h = GetGuildRosterLastOnline(i) end
                out[#out + 1] = { name = short, rank = rank, level = level or 0, zone = zone, online = isOnline and true or false,
                    class = class, note = note, rankIndex = select(3, GetGuildRosterInfo(i)) or 99,
                    away = ((y or 0) * 365 + (m or 0) * 30 + (d or 0)) * 24 + (h or 0) }
            end
        end
    end
    sort = sort or "level"
    table.sort(out, function(a, b)
        if a.online ~= b.online then return a.online end
        if sort == "name" then return a.name < b.name end
        if sort == "zone" then
            local za, zb = a.online and (a.zone or "") or "", b.online and (b.zone or "") or ""
            if za ~= zb then return za < zb end
        elseif sort == "rank" then
            if a.rankIndex ~= b.rankIndex then return a.rankIndex < b.rankIndex end
        end
        if not a.online and a.away ~= b.away then return a.away < b.away end
        if a.level ~= b.level then return a.level > b.level end
        return a.name < b.name
    end)
    return out, online, zones
end
WP.GuildRoster = function(onlineOnly) local list, online = Roster(onlineOnly); return list, online end

-- ---------------------------------------------------------------- the window
local W, H, PAD = 560, 620, 16
local win, tabs, current = nil, nil, "members"
local pages, ui = {}, {}

local function List(parent, top, bottom, make, rowH)
    local sf = CreateFrame("ScrollFrame", nil, parent)
    sf:SetPoint("TOPLEFT", PAD, top); sf:SetPoint("BOTTOMRIGHT", -PAD, bottom)
    local content = CreateFrame("Frame", nil, sf); content:SetSize(W - 2 * PAD, 10); sf:SetScrollChild(content)
    sf:EnableMouseWheel(true)
    sf:SetScript("OnMouseWheel", function(self, d)
        local max = math.max(0, content:GetHeight() - self:GetHeight())
        self:SetVerticalScroll(math.max(0, math.min(max, self:GetVerticalScroll() - d * (rowH or 30) * 2)))
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
local function Professions(name)
    local d = WP.Orders and WP.Orders.DB and WP.Orders.DB()
    local profs = d and d.crafters and d.crafters[name]
    local t = {}
    for prof, p in pairs(profs or {}) do t[#t + 1] = prof .. (p.rank and p.rank > 0 and (" " .. p.rank) or "") end
    table.sort(t)
    return table.concat(t, ", ")
end

local function Whisper(name)
    if ChatFrame_OpenChat then ChatFrame_OpenChat("/w " .. name .. " ")
    elseif ChatFrameUtil and ChatFrameUtil.OpenChat then ChatFrameUtil.OpenChat("/w " .. name .. " ") end
end
local function InviteName(name)
    local invite = (C_PartyInfo and C_PartyInfo.InviteUnit) or InviteUnit
    if invite then pcall(invite, name) end
end

local function MemberRow(parent)
    local r = CreateFrame("Button", nil, parent)
    r:SetSize(W - 2 * PAD, 28)
    r:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    r.bg = S.Solid(r, "BACKGROUND", C.card); r.bg:SetAllPoints()
    r.hl = S.Solid(r, "BORDER", { 1, 1, 1 }, 0); r.hl:SetAllPoints()
    r.dot = S.Solid(r, "ARTWORK", C.ready); r.dot:SetSize(6, 6); r.dot:SetPoint("LEFT", 8, 0)
    r.lvl = S.Text(r, 12, C.dim, true); r.lvl:SetPoint("LEFT", 22, 0); r.lvl:SetWidth(24); r.lvl:SetJustifyH("RIGHT")
    r.name = S.Text(r, 14, C.text, true); r.name:SetPoint("LEFT", 54, 0); r.name:SetWidth(150); r.name:SetJustifyH("LEFT")
    r.logo = r:CreateTexture(nil, "OVERLAY"); r.logo:SetSize(14, 14); r.logo:SetTexture(S.LOGO); r.logo:SetPoint("LEFT", 54, 0)
    r.where = S.Text(r, 12, C.dim); r.where:SetPoint("LEFT", 216, 0); r.where:SetWidth(190); r.where:SetJustifyH("LEFT")
    r.rank = S.Text(r, 12, C.muted); r.rank:SetPoint("RIGHT", -10, 0); r.rank:SetWidth(110); r.rank:SetJustifyH("RIGHT")
    r:SetScript("OnEnter", function(self)
        r.hl:SetColorTexture(1, 1, 1, 0.05)
        local m = self.m
        if not m then return end
        local lines = { m.name, (m.level or "?") .. " · " .. (m.online and (m.zone or "") or Ago(m.away)) .. " · " .. (m.rank or "") }
        if m.note and m.note ~= "" then lines[#lines + 1] = string.format(L("Note : %s"), m.note) end
        local profs = Professions(m.name)
        if profs ~= "" then lines[#lines + 1] = string.format(L("Métiers : %s"), profs) end
        if self.addon then lines[#lines + 1] = L("a WL Helper") .. (self.ver and (" · v" .. self.ver) or "") end
        if m.online and m.name ~= Me() then lines[#lines + 1] = S.Hex(C.brandSoft) .. L("Clic : chuchoter · clic droit ou Alt-clic : inviter") .. "|r" end
        S.Tip(self, lines)
    end)
    r:SetScript("OnLeave", function() r.hl:SetColorTexture(1, 1, 1, 0); S.HideTip() end)
    r:SetScript("OnClick", function(self, button)
        local m = self.m
        if not (m and m.online) or m.name == Me() then return end
        if button == "RightButton" or IsAltKeyDown() then InviteName(m.name) else Whisper(m.name) end
    end)
    return r
end

local function RankRow(parent)
    local r = CreateFrame("Frame", nil, parent)
    r:SetSize(W - 2 * PAD, 34)
    r.bg = S.Solid(r, "BACKGROUND", C.card); r.bg:SetAllPoints()
    r.pos = S.Text(r, 16, C.dim, true); r.pos:SetPoint("LEFT", 10, 0); r.pos:SetWidth(36); r.pos:SetJustifyH("LEFT")
    r.name = S.Text(r, 14, C.text, true); r.name:SetPoint("LEFT", 50, 0); r.name:SetWidth(200); r.name:SetJustifyH("LEFT")
    r.n = S.Text(r, 16, C.text, true); r.n:SetPoint("RIGHT", -170, 0); r.n:SetJustifyH("RIGHT")
    r.unit = S.Text(r, 12, C.dim); r.unit:SetPoint("LEFT", r.n, "RIGHT", 5, -1)
    r.ow = S.Text(r, 12, C.muted); r.ow:SetPoint("RIGHT", -10, 0); r.ow:SetJustifyH("RIGHT")
    return r
end

local function RenderMembers()
    local list, online, zones = Roster(WLWritsDB.guildOnline ~= false, ui.search and ui.search:GetText(), WLWritsDB.guildSort)
    local all = IsInGuild() and GetNumGuildMembers() or 0
    ui.count:SetText(IsInGuild() and string.format(L("%d en ligne sur %d"), online, all) or L("Pas de guilde."))
    -- the busiest zones right now
    local z = {}
    for name, n in pairs(zones) do z[#z + 1] = { name, n } end
    table.sort(z, function(a, b) if a[2] ~= b[2] then return a[2] > b[2] end return a[1] < b[1] end)
    local parts = {}
    for i = 1, math.min(4, #z) do parts[#parts + 1] = z[i][1] .. " " .. S.Hex(C.text) .. z[i][2] .. "|r" end
    ui.zones:SetText(#parts > 0 and string.format(L("Où est la guilde : %s"), table.concat(parts, "  ·  ")) or "")
    local board = Board()
    for i, m in ipairs(list) do
        local r = ui.members.Get(i)
        r:ClearAllPoints(); r:SetPoint("TOPLEFT", 0, -(i - 1) * 30)
        r.bg:SetAlpha(i % 2 == 0 and 0.6 or 1)
        r.m = m
        local col = ClassColor(m.class)
        r.addon = board[m.name] ~= nil
        r.ver = board[m.name] and board[m.name].ver
        r.logo:SetShown(r.addon)
        r.name:ClearAllPoints(); r.name:SetPoint("LEFT", r.addon and 72 or 54, 0)
        r.name:SetText(m.name); r.name:SetTextColor(col[1], col[2], col[3], m.online and 1 or 0.55)
        r.lvl:SetText(m.level)
        r.dot:SetColorTexture(m.online and C.ready[1] or 0.3, m.online and C.ready[2] or 0.32, m.online and C.ready[3] or 0.35, 1)
        r.where:SetText(m.online and (m.zone or "") or Ago(m.away))
        r.rank:SetText(m.rank or "")
    end
    ui.members.HideFrom(#list + 1)
    ui.members.content:SetHeight(math.max(10, #list * 30))
    ui.noMatch:SetShown(#list == 0 and IsInGuild())
end

local function RenderPvP()
    ArchiveSeason()
    local mode = WLWritsDB.guildRankMode or "week"
    local list = Ranking(mode)
    Share()
    local w, s, hk = WP.GuildMine()
    ui.mine:SetText(string.format(L("Toi : %d cette semaine · %d cette saison · %d au total"), w or 0, s or 0, hk or 0))
    ui.season:SetText(string.format(L("Saison %s"), SeasonName(Season())))
    local medal = { { 1, 0.82, 0.3 }, { 0.82, 0.85, 0.9 }, { 0.85, 0.55, 0.3 } }
    for i, e in ipairs(list) do
        local r = ui.rank.Get(i)
        r:ClearAllPoints(); r:SetPoint("TOPLEFT", 0, -(i - 1) * 38)
        local col = medal[i] or C.dim
        r.pos:SetText("#" .. i); r.pos:SetTextColor(col[1], col[2], col[3])
        r.name:SetText(e.name .. (e.name == Me() and (" " .. S.Hex(C.brandSoft) .. "·|r") or ""))
        r.n:SetText(e.n); r.unit:SetText(L("VH"))
        r.ow:SetText((e.ow or 0) > 0 and string.format(L("dont %d en monde ouvert"), e.ow) or "")
    end
    ui.rank.HideFrom(#list + 1)
    ui.rank.content:SetHeight(math.max(10, #list * 38))
    ui.none:SetShown(#list == 0)
    ui.none:SetText(mode == "week" and L("Personne n'a encore de victoire cette semaine.")
        or mode == "season" and L("Personne n'a encore de victoire cette saison.") or L("Personne n'a encore de victoire."))
    -- the last season's podium
    local past, pastKey = WLWritsDB.guildSeasons, nil
    for k in pairs(past or {}) do if not pastKey or k > pastKey then pastKey = k end end
    if pastKey and #past[pastKey] > 0 then
        local t = {}
        for i, e in ipairs(past[pastKey]) do t[#t + 1] = i .. ". " .. e[1] .. " (" .. e[2] .. ")" end
        ui.past:SetText(string.format(L("Saison précédente (%s) : %s"), SeasonName(pastKey), table.concat(t, "  ")))
    else
        ui.past:SetText("")
    end
end

local function SearchBox(parent, w)
    local eb = CreateFrame("EditBox", nil, parent)
    eb:SetSize(w, 28); eb:SetAutoFocus(false)
    local probe = S.Text(parent, 13, C.text)
    local font, size, flags = probe:GetFont(); probe:Hide()
    if font then eb:SetFont(font, size or 13, flags or "") else eb:SetFontObject(ChatFontNormal) end
    eb:SetTextColor(C.text[1], C.text[2], C.text[3]); eb:SetTextInsets(10, 10, 0, 0)
    S.Solid(eb, "BACKGROUND", C.card):SetAllPoints(); S.Border(eb, C.border)
    local hint = S.Text(eb, 13, C.muted); hint:SetPoint("LEFT", 10, 0); hint:SetText(L("Chercher un nom, une zone, un rang"))
    eb:SetScript("OnTextChanged", function(self) hint:SetShown(self:GetText() == ""); WP.RefreshGuild() end)
    eb:SetScript("OnEscapePressed", function(self) self:SetText(""); self:ClearFocus() end)
    eb:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    return eb
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
    ui.count = S.Text(m, 13, C.dim); ui.count:SetPoint("TOPLEFT", PAD, -14)
    local only = S.Switch(m, function() return WLWritsDB.guildOnline ~= false end, function(v) WLWritsDB.guildOnline = v; WP.RefreshGuild() end)
    only:SetPoint("TOPRIGHT", -PAD, -10)
    local onlyText = S.Text(m, 13, C.text); onlyText:SetPoint("RIGHT", only, "LEFT", -8, 0); onlyText:SetText(L("En ligne seulement"))
    ui.search = SearchBox(m, 230)
    ui.search:SetPoint("TOPLEFT", PAD, -42)
    local sort = S.Segmented(m, { { "level", L("Niveau") }, { "name", L("Nom") }, { "zone", L("Zone") }, { "rank", L("Rang") } },
        function() return WLWritsDB.guildSort or "level" end, function(v) WLWritsDB.guildSort = v; WP.RefreshGuild() end, 28)
    sort:SetPoint("TOPRIGHT", -PAD, -42)
    ui.zones = S.Text(m, 12, C.dim); ui.zones:SetPoint("TOPLEFT", PAD, -80); ui.zones:SetPoint("RIGHT", -PAD, 0)
    ui.zones:SetJustifyH("LEFT"); ui.zones:SetWordWrap(false)
    ui.members = List(m, -100, PAD, MemberRow, 30)
    ui.noMatch = S.Text(ui.members.content, 13, C.dim); ui.noMatch:SetPoint("TOPLEFT", 2, -8); ui.noMatch:SetText(L("Aucun membre ne correspond."))
    -- pvp
    local p = pages.pvp
    ui.mine = S.Text(p, 14, C.text, true); ui.mine:SetPoint("TOPLEFT", PAD, -14)
    ui.season = S.Text(p, 12, C.brandSoft, true); ui.season:SetPoint("TOPLEFT", PAD, -46)
    local seg = S.Segmented(p, { { "week", L("Cette semaine") }, { "season", L("Saison") }, { "all", L("Depuis toujours") } },
        function() return WLWritsDB.guildRankMode or "week" end, function(v) WLWritsDB.guildRankMode = v; WP.RefreshGuild() end, 26)
    seg:SetPoint("TOPRIGHT", -PAD, -38)
    local note = S.Text(p, 12, C.muted); note:SetPoint("BOTTOMLEFT", PAD, 12); note:SetPoint("RIGHT", -PAD, 0)
    note:SetJustifyH("LEFT"); note:SetWordWrap(true)
    note:SetText(L("Victoires honorables comptées par le jeu, champs de bataille compris. Une saison dure un mois. Seuls les membres qui ont WL Helper apparaissent ; leurs chiffres arrivent quand ils se connectent."))
    ui.past = S.Text(p, 12, C.warn); ui.past:SetPoint("BOTTOMLEFT", PAD, 52); ui.past:SetPoint("RIGHT", -PAD, 0)
    ui.past:SetJustifyH("LEFT"); ui.past:SetWordWrap(false)
    ui.rank = List(p, -74, 76, RankRow, 38)
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
local refreshing = false
function WP.RefreshGuild()
    if not (win and win:IsShown()) or refreshing then return end
    refreshing = true
    tabs:Update()
    if current == "members" then RenderMembers() else RenderPvP() end
    refreshing = false
end
function WP.ToggleGuild()
    if win and win:IsShown() then win:Hide(); return end
    if WP.ModuleOff and WP.ModuleOff("guild") then return end
    WP.ShowGuildTab(current)
end
function WP.HideGuild() if win then win:Hide() end end

-- ---------------------------------------------------------------- events
local ev = CreateFrame("Frame")
pcall(ev.RegisterEvent, ev, "PLAYER_LOGIN")
pcall(ev.RegisterEvent, ev, "CHAT_MSG_ADDON")
pcall(ev.RegisterEvent, ev, "GUILD_ROSTER_UPDATE")
ev:SetScript("OnEvent", function(self, e, prefix, msg, channel, sender)
    if not WLWritsDB then return end
    if e == "PLAYER_LOGIN" then
        for _, h in ipairs({ "PLAYER_PVP_KILLS_CHANGED", "PLAYER_REGEN_ENABLED", "ZONE_CHANGED_NEW_AREA" }) do
            pcall(self.RegisterEvent, self, h)
        end
        C_Timer.After(5, function() pcall(ArchiveSeason); CheckHonor() end)
        C_Timer.After(25, function() Share(true) end)
    elseif e == "PLAYER_PVP_KILLS_CHANGED" or e == "PLAYER_REGEN_ENABLED" or e == "ZONE_CHANGED_NEW_AREA" then
        if On() then C_Timer.After(1, CheckHonor) end
    elseif e == "GUILD_ROSTER_UPDATE" then
        WP.RefreshGuild()
    elseif prefix == PREFIX and channel == "GUILD" and type(msg) == "string" and sender then
        local who = Short(sender)
        if who ~= Me() then OnMessage(msg, who) end
    end
end)
