-- Writs/Events.lua: the Events module (/wlh events): the guild's own calendar and LFG.
--
--  Upcoming  A member plans a dungeon or a raid: a name, a day and an hour, places per role (tanks,
--            healers, damage) and a note. Others sign up with a role, or step out. 15 minutes before,
--            those signed up get a reminder; the organizer invites everyone in one click.
--  Now       "I'm looking for a group": your role and what for; the list of members looking right
--            now (click: whisper, right-click or Alt-click: invite). An entry fades after 30 minutes.
-- Everything goes on the guild's addon channel; every copy keeps what it saw. Only members who have
-- WL Helper see it. Only names, roles, class, level, times and the texts typed travel.
local ADDON, root = ...
root.Writs = root.Writs or {}
local ns = root.Writs
local WP = ns.WP
local L = ns.L
local S = ns.S
local C = S.C

ns.AddEnglish({
    ["Événements"] = "Events",
    ["Donjon"] = "Dungeon", ["Raid"] = "Raid", ["Quête"] = "Quest", ["Autre"] = "Other",
    ["Donjons et raids de la guilde, groupes du moment"] = "Guild dungeons and raids, groups right now",
    ["À venir"] = "Upcoming",
    ["Créer"] = "Create",
    ["Groupe maintenant"] = "Group now",
    ["Tank"] = "Tank", ["Soins"] = "Healer", ["DPS"] = "Damage",
    ["Me désinscrire"] = "Step out",
    ["Inviter les inscrits"] = "Invite everyone",
    ["Annuler l'événement"] = "Cancel the event",
    ["par %s"] = "by %s",
    ["Aucun événement prévu. Crée le premier dans l'onglet Créer."] = "No event planned. Create the first one in the Create tab.",
    ["Quoi"] = "What",
    ["Zul'Farrak, Onyxia, farm de cuir..."] = "Zul'Farrak, Onyxia, leather farming...",
    ["Jour"] = "Day",
    ["Heure"] = "Time",
    ["Places"] = "Places",
    ["Note"] = "Note",
    ["Publier l'événement"] = "Publish the event",
    ["Donne un nom à l'événement."] = "Give the event a name.",
    ["Heure invalide : écris par exemple 20:30."] = "Invalid time: write for example 20:30.",
    ["Cette heure est déjà passée."] = "That time is already past.",
    ["Nouvel événement : %s, %s (par %s). /wlh events"] = "New event: %s, %s (by %s). /wlh events",
    ["Rappel : %s commence dans 15 min."] = "Reminder: %s starts in 15 min.",
    ["%s commence maintenant."] = "%s starts now.",
    ["Aujourd'hui"] = "Today", ["Demain"] = "Tomorrow",
    ["annulé"] = "cancelled",
    ["Je cherche un groupe"] = "I'm looking for a group",
    ["Pour quoi ?"] = "What for?",
    ["Personne ne cherche de groupe en ce moment."] = "Nobody is looking for a group right now.",
    ["Mon rôle"] = "My role",
    ["il y a %d min"] = "%d min ago",
    ["Seuls les membres qui ont WL Helper voient les événements et les recherches de groupe."] = "Only members who have WL Helper see the events and group searches.",
    ["%d inscrits"] = "%d signed up",
    ["complet"] = "full",
    ["%d événements à venir"] = "%d upcoming events",
    ["Prochain : %s, %s"] = "Next: %s, %s",
    ["Rien de prévu"] = "Nothing planned",
    ["%d cherchent un groupe"] = "%d looking for a group",
    ["niv. %s"] = "lv %s",
    ["%d objets meilleurs que les tiens dans tes sacs"] = "%d items in your bags better than yours",
    ["Rien de mieux dans tes sacs"] = "Nothing better in your bags",
    ["Spé, seuil et poids dans les réglages"] = "Spec, threshold and weights in the settings",
})

local PREFIX = "WLHevt"
local CI = C_ChatInfo
local Register = (CI and CI.RegisterAddonMessagePrefix) or RegisterAddonMessagePrefix
local SendRaw = (CI and CI.SendAddonMessage) or SendAddonMessage
if Register then pcall(Register, PREFIX) end

local function Me() return (UnitName("player")) end
local function Short(n) return n and (n:gsub("[%- ].*$", "")) end
local function On() return WP.ModuleOn("events") end
local function Clean(s, max) s = tostring(s or ""):gsub("[|~\n]", " "); if max and #s > max then s = s:sub(1, max) end; return s end
local ROLES = { "tank", "heal", "dps" }
local ROLE_LABEL = { tank = "Tank", heal = "Soins", dps = "DPS" }
-- the game's role icons (64 x 64 sheet): shield, cross, sword
local ROLE_ICON = "Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES"
local ROLE_TC = { tank = { 0, 19, 22, 41 }, heal = { 20, 39, 1, 20 }, dps = { 20, 39, 22, 41 } }
local function RoleIcon(role, size)
    local t = ROLE_TC[role]
    if not t then return "" end
    size = size or 16
    return string.format("|T%s:%d:%d:0:0:64:64:%d:%d:%d:%d|t", ROLE_ICON, size, size, t[1], t[2], t[3], t[4])
end
local function RoleText(role, size) return RoleIcon(role, size) .. " " .. L(ROLE_LABEL[role] or "?") end

local function DB()
    WLWritsDB.events = WLWritsDB.events or {}
    local d = WLWritsDB.events
    d.list, d.lfg, d.reminded = d.list or {}, d.lfg or {}, d.reminded or {}
    return d
end

-- ---------------------------------------------------------------- dates
local DAYS = { fr = { "dim.", "lun.", "mar.", "mer.", "jeu.", "ven.", "sam." }, en = { "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat" } }
local function DayStart(t) local d = date("*t", t); d.hour, d.min, d.sec = 0, 0, 0; return time(d) end
local function When(t)
    local d = date("*t", t)
    local today = DayStart(time())
    local day
    if DayStart(t) == today then day = L("Aujourd'hui")
    elseif DayStart(t) == today + 86400 then day = L("Demain")
    else day = ((root.lang == "en") and DAYS.en or DAYS.fr)[d.wday] .. " " .. string.format("%02d/%02d", d.day, d.month) end
    return day .. " " .. string.format("%02d:%02d", d.hour, d.min)
end
WP.EventWhen = When

-- ---------------------------------------------------------------- sending
local outbox, pumping = {}, false
local function Pump()
    local m = table.remove(outbox, 1)
    if not m then pumping = false; return end
    if SendRaw then pcall(SendRaw, PREFIX, m, "GUILD") end
    C_Timer.After(1, Pump)
end
local function Send(msg)
    if not (IsInGuild and IsInGuild()) then return end
    outbox[#outbox + 1] = msg
    if not pumping then pumping = true; C_Timer.After(0.1, Pump) end
end

local function EventMsg(e)
    local head = table.concat({ "E", e.id, e.by, e.when, e.tank, e.heal, e.dps, e.status }, "|")
    local room = 248 - #head - 2
    local title = Clean(e.title, math.min(60, room))
    local note = Clean(e.note, math.max(0, room - #title))
    return head .. "|" .. title .. "|" .. note
end
local function SignupMsg(id, name, s) return table.concat({ "J", id, s.role or "x", s.cls or "", s.lvl or 0, name }, "|") end

-- ---------------------------------------------------------------- the data
local function Prune()
    local d, now = DB(), time()
    for id, e in pairs(d.list) do if (e.when or 0) < now - 6 * 3600 then d.list[id] = nil; d.reminded[id] = nil end end
    for name, l in pairs(d.lfg) do if (l.t or 0) < now - 1800 then d.lfg[name] = nil end end
end

-- upcoming events, soonest first
function WP.EventList()
    Prune()
    local out = {}
    for _, e in pairs(DB().list) do out[#out + 1] = e end
    table.sort(out, function(a, b) return (a.when or 0) < (b.when or 0) end)
    return out
end
function WP.EventCounts(e)
    local n = { tank = 0, heal = 0, dps = 0 }
    for _, s in pairs(e.signups or {}) do if n[s.role] then n[s.role] = n[s.role] + 1 end end
    return n
end
function WP.LFGList()
    Prune()
    local out = {}
    for name, l in pairs(DB().lfg) do out[#out + 1] = { name = name, role = l.role, cls = l.cls, lvl = l.lvl, what = l.what, t = l.t } end
    table.sort(out, function(a, b) return a.t > b.t end)
    return out
end

local function Refresh() if WP.RefreshEvents then WP.RefreshEvents() end; if WP.RefreshHome then WP.RefreshHome() end end

function WP.CreateEvent(title, when, tank, heal, dps, note)
    local e = { id = Me() .. "-" .. time() .. "-" .. math.random(100, 999), by = Me(), when = when, tank = tank, heal = heal, dps = dps,
        status = "open", title = Clean(title, 60), note = Clean(note, 120), signups = {} }
    DB().list[e.id] = e
    Send(EventMsg(e))
    Refresh()
    return e
end
function WP.CancelEvent(e)
    if e.by ~= Me() then return end
    e.status = "cancelled"
    Send(EventMsg(e))
    Refresh()
end
-- role nil: step out
function WP.SignUp(e, role)
    local _, cls = UnitClass("player")
    e.signups = e.signups or {}
    local s = { role = role or "x", cls = cls, lvl = UnitLevel("player"), t = time() }
    if role then e.signups[Me()] = s else e.signups[Me()] = nil end
    Send(SignupMsg(e.id, Me(), s))
    Refresh()
end
function WP.MySignup(e) return e.signups and e.signups[Me()] end

local function InviteName(name)
    local invite = (C_PartyInfo and C_PartyInfo.InviteUnit) or InviteUnit
    if invite then pcall(invite, name) end
end
function WP.InviteSignups(e)
    local names = {}
    for name in pairs(e.signups or {}) do if name ~= Me() then names[#names + 1] = name end end
    if #names >= 5 and not IsInRaid() then
        local convert = (C_PartyInfo and C_PartyInfo.ConvertToRaid) or ConvertToRaid
        if convert and IsInGroup() then pcall(convert) end
    end
    for i, name in ipairs(names) do C_Timer.After(0.2 * i, function() InviteName(name) end) end
end

function WP.SetLooking(role, what)
    local d = DB()
    local _, cls = UnitClass("player")
    if role then
        d.lfg[Me()] = { role = role, cls = cls, lvl = UnitLevel("player"), what = Clean(what, 80), t = time() }
        Send(table.concat({ "N", role, cls or "", UnitLevel("player") or 0, Clean(what, 80) }, "|"))
    else
        d.lfg[Me()] = nil
        Send("N|x|||")
    end
    Refresh()
end
function WP.IsLooking() local l = DB().lfg[Me()]; return l and l.role, l and l.what end

-- ---------------------------------------------------------------- receiving
local function OnMessage(msg, sender)
    local d = DB()
    local kind = msg:match("^(%u)")
    if kind == "E" then
        local id, by, when, tank, heal, dps, status, title, note = msg:match("^E|([^|]+)|([^|]+)|(%d+)|(%d+)|(%d+)|(%d+)|(%a+)|([^|]*)|?(.*)$")
        if not id or Short(by) ~= sender then return end
        local cur = d.list[id]
        local isNew = not cur
        cur = cur or { signups = {} }
        cur.id, cur.by, cur.when, cur.tank, cur.heal, cur.dps = id, sender, tonumber(when), tonumber(tank), tonumber(heal), tonumber(dps)
        cur.status, cur.title, cur.note = status, title, note
        d.list[id] = cur
        if isNew and status == "open" and cur.when > time() and On() then
            WP.Print(string.format(L("Nouvel événement : %s, %s (par %s). /wlh events"), cur.title, When(cur.when), sender))
        end
        Refresh()
    elseif kind == "J" then
        local id, role, cls, lvl, name = msg:match("^J|([^|]+)|(%a+)|(%u*)|(%d+)|([^|]+)$")
        local e = id and d.list[id]
        if not e or Short(name) ~= sender then return end
        e.signups = e.signups or {}
        if role == "x" then e.signups[sender] = nil
        else e.signups[sender] = { role = role, cls = cls, lvl = tonumber(lvl), t = time() } end
        Refresh()
    elseif kind == "N" then
        local role, cls, lvl, what = msg:match("^N|(%a+)|(%u*)|(%d*)|(.*)$")
        if not role then return end
        if role == "x" then d.lfg[sender] = nil
        else d.lfg[sender] = { role = role, cls = cls, lvl = tonumber(lvl), what = what, t = time() } end
        Refresh()
    elseif kind == "Q" then
        -- someone logged in: what I organize, what I signed up for, whether I'm looking
        for _, e in pairs(d.list) do
            if e.by == Me() and (e.when or 0) > time() - 3600 then Send(EventMsg(e)) end
            local s = e.signups and e.signups[Me()]
            if s and (e.when or 0) > time() then Send(SignupMsg(e.id, Me(), s)) end
        end
        local l = d.lfg[Me()]
        if l then Send(table.concat({ "N", l.role, l.cls or "", l.lvl or 0, l.what or "" }, "|")) end
    end
end

-- ---------------------------------------------------------------- reminders
local function Remind()
    if not (WLWritsDB and On()) then return end
    local d, now = DB(), time()
    for id, e in pairs(d.list) do
        local mine = e.by == Me() or (e.signups and e.signups[Me()])
        if mine and e.status == "open" then
            local left = (e.when or 0) - now
            local r = d.reminded[id] or 0
            if left <= 900 and left > 0 and r < 1 then
                d.reminded[id] = 1
                local msg = string.format(L("Rappel : %s commence dans 15 min."), e.title)
                WP.Print(msg)
                if RaidNotice_AddMessage and RaidWarningFrame then RaidNotice_AddMessage(RaidWarningFrame, msg, { r = 0.81, g = 0.1, b = 0.09 }) end
                if PlaySound and SOUNDKIT and SOUNDKIT.RAID_WARNING then pcall(PlaySound, SOUNDKIT.RAID_WARNING, "Master") end
            elseif left <= 0 and left > -600 and r < 2 then
                d.reminded[id] = 2
                WP.Print(string.format(L("%s commence maintenant."), e.title))
            end
        end
    end
end

-- ---------------------------------------------------------------- the window
local W, H, PAD = 560, 620, 16
local win, tabs, current = nil, nil, "upcoming"
local pages, ui = {}, {}
local draft = { day = 0, tank = 1, heal = 1, dps = 3 }

local function Box(parent, w, hint, numeric)
    local eb = CreateFrame("EditBox", nil, parent)
    eb:SetSize(w, 28); eb:SetAutoFocus(false)
    if numeric then eb:SetNumeric(true); eb:SetMaxLetters(2) end
    local probe = S.Text(parent, 13, C.text)
    local font, size, flags = probe:GetFont(); probe:Hide()
    if font then eb:SetFont(font, size or 13, flags or "") else eb:SetFontObject(ChatFontNormal) end
    eb:SetTextColor(C.text[1], C.text[2], C.text[3]); eb:SetTextInsets(10, 10, 0, 0)
    S.Solid(eb, "BACKGROUND", C.card):SetAllPoints(); S.Border(eb, C.border)
    if hint then
        local h = S.Text(eb, 13, C.muted); h:SetPoint("LEFT", 10, 0); h:SetText(hint)
        eb:HookScript("OnTextChanged", function(self) h:SetShown(self:GetText() == "") end)
    end
    eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    eb:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    return eb
end

local function List(parent, top, bottom, make, step)
    local sf = CreateFrame("ScrollFrame", nil, parent)
    sf:SetPoint("TOPLEFT", PAD, top); sf:SetPoint("BOTTOMRIGHT", -PAD, bottom)
    local content = CreateFrame("Frame", nil, sf); content:SetSize(W - 2 * PAD, 10); sf:SetScrollChild(content)
    sf:EnableMouseWheel(true)
    sf:SetScript("OnMouseWheel", function(self, dlt)
        local max = math.max(0, content:GetHeight() - self:GetHeight())
        self:SetVerticalScroll(math.max(0, math.min(max, self:GetVerticalScroll() - dlt * (step or 60))))
    end)
    local l = { sf = sf, content = content, items = {} }
    function l.Get(i) local f = l.items[i]; if not f then f = make(content); l.items[i] = f end; f:Show(); return f end
    function l.HideFrom(i) for j = i, #l.items do l.items[j]:Hide() end end
    return l
end

local function ClassHex(cls)
    local c = cls and RAID_CLASS_COLORS and RAID_CLASS_COLORS[cls]
    return c and string.format("|cff%02x%02x%02x", c.r * 255, c.g * 255, c.b * 255) or S.Hex(C.text)
end

local function EventCard(parent)
    local c = CreateFrame("Frame", nil, parent)
    c:SetWidth(W - 2 * PAD)
    S.Solid(c, "BACKGROUND", C.card):SetAllPoints(); S.Border(c, C.border)
    c.when = S.Text(c, 12, C.brandSoft, true); c.when:SetPoint("TOPLEFT", 12, -10)
    c.title = S.Text(c, 16, C.text, true); c.title:SetPoint("TOPLEFT", 12, -28); c.title:SetPoint("RIGHT", -12, 0); c.title:SetJustifyH("LEFT"); c.title:SetWordWrap(false)
    c.by = S.Text(c, 12, C.dim); c.by:SetPoint("TOPRIGHT", -12, -10)
    c.roles = S.Text(c, 13, C.text); c.roles:SetPoint("TOPLEFT", 12, -52)
    c.who = S.Text(c, 12, C.dim); c.who:SetPoint("TOPLEFT", 12, -72); c.who:SetPoint("RIGHT", -12, 0); c.who:SetJustifyH("LEFT"); c.who:SetWordWrap(true)
    c.note = S.Text(c, 12, C.muted); c.note:SetPoint("TOPLEFT", c.who, "BOTTOMLEFT", 0, -4); c.note:SetPoint("RIGHT", -12, 0); c.note:SetJustifyH("LEFT"); c.note:SetWordWrap(true)
    c.btns = {}
    for i, role in ipairs(ROLES) do
        local b = S.Button(c, RoleText(role, 14), 92, 26, "secondary", function() if c.e then WP.SignUp(c.e, role) end end)
        b.role = role
        c.btns[i] = b
    end
    c.out = S.Button(c, L("Me désinscrire"), 130, 26, "secondary", function() if c.e then WP.SignUp(c.e, nil) end end)
    c.invite = S.Button(c, L("Inviter les inscrits"), 150, 26, "primary", function() if c.e then WP.InviteSignups(c.e) end end)
    c.cancel = S.Button(c, L("Annuler l'événement"), 150, 26, "warn", function() if c.e then WP.CancelEvent(c.e) end end)
    return c
end

local function PaintEvent(c, e)
    c.e = e
    local cancelled = e.status ~= "open"
    c.when:SetText(When(e.when) .. (cancelled and ("  ·  " .. L("annulé")) or ""))
    c.title:SetText(e.title or "?")
    c.title:SetTextColor((cancelled and C.dim or C.text)[1], (cancelled and C.dim or C.text)[2], (cancelled and C.dim or C.text)[3])
    c.by:SetText(string.format(L("par %s"), e.by or "?"))
    local n = WP.EventCounts(e)
    local parts = {}
    for _, role in ipairs(ROLES) do
        local want = e[role] or 0
        if want > 0 or n[role] > 0 then
            local col = (n[role] >= want and want > 0) and C.ready or C.text
            parts[#parts + 1] = RoleIcon(role, 16) .. " " .. S.Hex(col) .. n[role] .. "/" .. want .. "|r"
        end
    end
    c.roles:SetText(table.concat(parts, "   "))
    local names = {}
    for name, s in pairs(e.signups or {}) do names[#names + 1] = { name, s } end
    table.sort(names, function(a, b) return a[1] < b[1] end)
    local t = {}
    for _, p in ipairs(names) do t[#t + 1] = RoleIcon(p[2].role, 12) .. ClassHex(p[2].cls) .. p[1] .. "|r" end
    c.who:SetText(#t > 0 and table.concat(t, ", ") or "")
    c.note:SetText(e.note or "")
    -- buttons: sign up with a role / step out; the organizer invites or cancels
    local mine = WP.MySignup(e)
    local x, y = 12, 10
    for _, b in ipairs(c.btns) do
        b:SetShown(not cancelled and not mine)
        b:ClearAllPoints(); b:SetPoint("BOTTOMLEFT", x, y); x = x + 90
    end
    c.out:SetShown(not cancelled and mine ~= nil); c.out:ClearAllPoints(); c.out:SetPoint("BOTTOMLEFT", 12, y)
    local organizer = e.by == Me() and not cancelled
    c.invite:SetShown(organizer); c.cancel:SetShown(organizer)
    c.cancel:ClearAllPoints(); c.cancel:SetPoint("BOTTOMRIGHT", -12, y)
    c.invite:ClearAllPoints(); c.invite:SetPoint("RIGHT", c.cancel, "LEFT", -8, 0)
    local h = 82 + math.max(0, (c.who:GetStringHeight() or 0)) + ((e.note and e.note ~= "") and ((c.note:GetStringHeight() or 14) + 6) or 0) + 44
    c:SetHeight(h)
    return h
end

local function LookRow(parent)
    local r = CreateFrame("Button", nil, parent)
    r:SetSize(W - 2 * PAD, 30)
    r:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    r.bg = S.Solid(r, "BACKGROUND", C.card); r.bg:SetAllPoints()
    r.name = S.Text(r, 14, C.text, true); r.name:SetPoint("LEFT", 10, 0); r.name:SetWidth(150); r.name:SetJustifyH("LEFT")
    r.role = S.Text(r, 12, C.brandSoft, true); r.role:SetPoint("LEFT", 166, 0); r.role:SetWidth(60); r.role:SetJustifyH("LEFT")
    r.what = S.Text(r, 13, C.text); r.what:SetPoint("LEFT", 230, 0); r.what:SetPoint("RIGHT", -80, 0); r.what:SetJustifyH("LEFT"); r.what:SetWordWrap(false)
    r.ago = S.Text(r, 12, C.muted); r.ago:SetPoint("RIGHT", -10, 0)
    r:SetScript("OnClick", function(self, button)
        local who = self.who
        if not who or who == Me() then return end
        if button == "RightButton" or IsAltKeyDown() then InviteName(who)
        elseif ChatFrame_OpenChat then ChatFrame_OpenChat("/w " .. who .. " ") end
    end)
    r:SetScript("OnEnter", function(self) if self.who and self.who ~= Me() then S.Tip(self, { self.who, L("Clic : chuchoter · clic droit ou Alt-clic : inviter") }) end end)
    r:SetScript("OnLeave", S.HideTip)
    return r
end

local function RenderUpcoming()
    local list = WP.EventList()
    local y = 0
    for i, e in ipairs(list) do
        local c = ui.events.Get(i)
        c:ClearAllPoints(); c:SetPoint("TOPLEFT", 0, -y)
        y = y + PaintEvent(c, e) + 10
    end
    ui.events.HideFrom(#list + 1)
    ui.events.content:SetHeight(math.max(10, y))
    ui.noEvents:SetShown(#list == 0)
end

local function RenderNow()
    local role, what = WP.IsLooking()
    ui.lookSwitch:Update()
    local list = WP.LFGList()
    for i, l in ipairs(list) do
        local r = ui.looking.Get(i)
        r:ClearAllPoints(); r:SetPoint("TOPLEFT", 0, -(i - 1) * 32)
        r.bg:SetAlpha(i % 2 == 0 and 0.6 or 1)
        r.who = l.name
        r.name:SetText(ClassHex(l.cls) .. l.name .. "|r " .. S.Hex(C.muted) .. (l.lvl or "") .. "|r")
        r.role:SetText(RoleText(l.role, 14))
        r.what:SetText(l.what or "")
        r.ago:SetText(string.format(L("il y a %d min"), math.max(0, math.floor((time() - l.t) / 60))))
    end
    ui.looking.HideFrom(#list + 1)
    ui.looking.content:SetHeight(math.max(10, #list * 32))
    ui.noLooking:SetShown(#list == 0)
end

local function DayChoices()
    local out = {}
    for i = 0, 6 do
        local t = DayStart(time()) + i * 86400
        local d = date("*t", t)
        local label = (i == 0 and L("Aujourd'hui")) or (i == 1 and L("Demain")) or ((root.lang == "en") and DAYS.en or DAYS.fr)[d.wday]
        out[#out + 1] = { i, label }
    end
    return out
end

-- the dungeons and raids of the guide, for the "What" picker: { { key, name, lvlFrom, raid } }
local function Instances(kind)
    local out = {}
    for _, k in ipairs(root.ORDER or {}) do
        local d = root.D and root.D[k]
        if d and not d.cq and ((kind == "raid") == (d.raid == true)) then
            out[#out + 1] = { k, root.DName and root.DName(k) or d.n, d.lvl and d.lvl[1] or 0 }
        end
    end
    table.sort(out, function(a, b) if a[3] ~= b[3] then return a[3] < b[3] end return a[2] < b[2] end)
    return out
end
local picked = {}
local function PickedTitle()
    local t = {}
    for _, e in ipairs(Instances(draft.kind == "raid" and "raid" or "dg")) do if picked[e[1]] then t[#t + 1] = e[2] end end
    return table.concat(t, " + ")
end

local function BuildCreate(p)
    local y = -12
    local function Label(text) local t = S.Text(p, 13, C.dim, true); t:SetPoint("TOPLEFT", PAD, y); t:SetText(text); y = y - 22; return t end
    draft.kind = draft.kind or "dg"
    -- the kind, then the instances of that kind as chips (several can be picked)
    local chips = CreateFrame("ScrollFrame", nil, p)
    local inner = CreateFrame("Frame", nil, chips)
    local function Chips()
        for _, c in ipairs(inner.items or {}) do c:Hide() end
        inner.items = inner.items or {}
        local list = (draft.kind == "dg" or draft.kind == "raid") and Instances(draft.kind) or {}
        local cw, ch, cols = math.floor((W - 2 * PAD - 18) / 3), 26, 3
        for i, e in ipairs(list) do
            local c = inner.items[i]
            if not c then
                c = CreateFrame("Button", nil, inner)
                c:SetSize(cw, ch)
                c.bg = S.Solid(c, "BACKGROUND", C.card); c.bg:SetAllPoints()
                c.edge = S.Border(c, C.border)
                c.t = S.Text(c, 12, C.text); c.t:SetPoint("LEFT", 8, 0); c.t:SetPoint("RIGHT", -6, 0); c.t:SetJustifyH("LEFT"); c.t:SetWordWrap(false)
                c:SetScript("OnClick", function(self)
                    picked[self.key] = not picked[self.key] or nil
                    ui.title:SetText(PickedTitle())
                    Chips()
                end)
                inner.items[i] = c
            end
            c.key = e[1]
            c:ClearAllPoints(); c:SetPoint("TOPLEFT", ((i - 1) % cols) * (cw + 6), -math.floor((i - 1) / cols) * (ch + 6))
            c.t:SetText(e[2] .. "  " .. S.Hex(C.muted) .. e[3] .. "|r")
            local on = picked[e[1]]
            c.bg:SetColorTexture((on and C.brandBg or C.card)[1], (on and C.brandBg or C.card)[2], (on and C.brandBg or C.card)[3], 1)
            c.edge(on and C.brand or C.border)
            c:Show()
        end
        inner:SetSize(W - 2 * PAD, math.max(10, math.ceil(#list / cols) * (ch + 6)))
        chips:SetShown(#list > 0)
    end
    local kind = S.Segmented(p, { { "dg", L("Donjon") }, { "raid", L("Raid") }, { "quest", L("Quête") }, { "other", L("Autre") } },
        function() return draft.kind end, function(v) draft.kind = v; wipe(picked); ui.title:SetText(""); Chips() end, 28)
    kind:SetPoint("TOPLEFT", PAD, y); y = y - 38
    chips:SetPoint("TOPLEFT", PAD, y); chips:SetSize(W - 2 * PAD, 124); chips:SetScrollChild(inner)
    chips:EnableMouseWheel(true)
    chips:SetScript("OnMouseWheel", function(self, dlt)
        local max = math.max(0, inner:GetHeight() - self:GetHeight())
        self:SetVerticalScroll(math.max(0, math.min(max, self:GetVerticalScroll() - dlt * 32)))
    end)
    y = y - 132
    Label(L("Quoi"))
    ui.title = Box(p, W - 2 * PAD, L("Zul'Farrak, Onyxia, farm de cuir..."))
    ui.title:SetPoint("TOPLEFT", PAD, y); ui.title:SetMaxLetters(60); y = y - 40
    Chips()
    Label(L("Jour"))
    ui.day = S.Segmented(p, DayChoices(), function() return draft.day end, function(v) draft.day = v end, 28)
    ui.day:SetPoint("TOPLEFT", PAD, y); y = y - 40
    Label(L("Heure") .. "                    " .. L("Places"))
    ui.hour = Box(p, 90, "20:30"); ui.hour:SetPoint("TOPLEFT", PAD, y); ui.hour:SetMaxLetters(5)
    local x = PAD + 150
    for _, role in ipairs(ROLES) do
        local t = S.Text(p, 13, C.text); t:SetPoint("TOPLEFT", x, y - 4); t:SetText(RoleIcon(role, 20))
        local b = Box(p, 50, nil, true); b:SetPoint("TOPLEFT", x + 28, y)
        b:SetText(tostring(draft[role])); ui["n_" .. role] = b
        x = x + 96
    end
    y = y - 40
    Label(L("Note"))
    ui.note = Box(p, W - 2 * PAD, nil); ui.note:SetPoint("TOPLEFT", PAD, y); ui.note:SetMaxLetters(120); y = y - 40
    ui.err = S.Text(p, 12, C.danger); ui.err:SetPoint("TOPLEFT", PAD, y + 6)
    local go = S.Button(p, L("Publier l'événement"), W - 2 * PAD, 36, "primary", function()
        local title = ui.title:GetText()
        if not title or title:gsub("%s", "") == "" then ui.err:SetText(L("Donne un nom à l'événement.")); return end
        local hh, mm = (ui.hour:GetText() or ""):match("^%s*(%d%d?)[:hH]?(%d?%d?)%s*$")
        hh, mm = tonumber(hh), tonumber(mm ~= "" and mm or "0")
        if not hh or hh > 23 or not mm or mm > 59 then ui.err:SetText(L("Heure invalide : écris par exemple 20:30.")); return end
        local when = DayStart(time()) + draft.day * 86400 + hh * 3600 + mm * 60
        if when < time() - 60 then ui.err:SetText(L("Cette heure est déjà passée.")); return end
        local function N(role) return tonumber(ui["n_" .. role]:GetText()) or 0 end
        WP.CreateEvent(title, when, N("tank"), N("heal"), N("dps"), ui.note:GetText())
        ui.err:SetText(""); ui.title:SetText(""); ui.note:SetText(""); wipe(picked); Chips()
        WP.ShowEventsTab("upcoming")
    end)
    go:SetPoint("BOTTOMLEFT", PAD, PAD)
end

local function BuildNow(p)
    local role = WLWritsCharDB and WLWritsCharDB.lfgRole or "dps"
    local t = S.Text(p, 14, C.text, true); t:SetPoint("TOPLEFT", PAD, -16); t:SetText(L("Je cherche un groupe"))
    ui.lookSwitch = S.Switch(p, function() return WP.IsLooking() ~= nil end, function(v)
        if v then WP.SetLooking(WLWritsCharDB.lfgRole or "dps", ui.what:GetText()) else WP.SetLooking(nil) end
    end)
    ui.lookSwitch:SetPoint("TOPRIGHT", -PAD, -12)
    local rl = S.Text(p, 13, C.dim); rl:SetPoint("TOPLEFT", PAD, -52); rl:SetText(L("Mon rôle"))
    local seg = S.Segmented(p, { { "tank", RoleText("tank", 14) }, { "heal", RoleText("heal", 14) }, { "dps", RoleText("dps", 14) } },
        function() return WLWritsCharDB.lfgRole or "dps" end, function(v)
            WLWritsCharDB.lfgRole = v
            if WP.IsLooking() then WP.SetLooking(v, ui.what:GetText()) end
        end, 28)
    seg:SetPoint("TOPLEFT", PAD + 80, -46)
    ui.what = Box(p, W - 2 * PAD, L("Pour quoi ?")); ui.what:SetPoint("TOPLEFT", PAD, -86); ui.what:SetMaxLetters(80)
    ui.what:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
        if WP.IsLooking() then WP.SetLooking(WLWritsCharDB.lfgRole or "dps", self:GetText()) end
    end)
    ui.looking = List(p, -128, 40, LookRow, 32)
    ui.noLooking = S.Text(ui.looking.content, 13, C.dim); ui.noLooking:SetPoint("TOPLEFT", 2, -8); ui.noLooking:SetText(L("Personne ne cherche de groupe en ce moment."))
    local note = S.Text(p, 12, C.muted); note:SetPoint("BOTTOMLEFT", PAD, 14); note:SetPoint("RIGHT", -PAD, 0); note:SetJustifyH("LEFT"); note:SetWordWrap(true)
    note:SetText(L("Seuls les membres qui ont WL Helper voient les événements et les recherches de groupe."))
end

local function Build()
    win = S.Window("WLHelperEvents", W, H, "LFG", GetGuildInfo and GetGuildInfo("player") or nil, WLWritsDB, "eventsPos")
    tabs = S.Tabs(win, { { "upcoming", L("À venir") }, { "create", L("Créer") }, { "now", L("Groupe maintenant") } },
        function() return current end, function(k) WP.ShowEventsTab(k) end, function(k)
            if k == "upcoming" then local n = #WP.EventList(); return n > 0 and n or nil end
            if k == "now" then local n = #WP.LFGList(); return n > 0 and n or nil end
        end)
    tabs:SetPoint("TOPLEFT", 1, -39); tabs:SetPoint("TOPRIGHT", -1, -39)
    for _, k in ipairs({ "upcoming", "create", "now" }) do
        local p = CreateFrame("Frame", nil, win)
        p:SetPoint("TOPLEFT", 0, -76); p:SetPoint("BOTTOMRIGHT")
        p:Hide(); pages[k] = p
    end
    ui.events = List(pages.upcoming, -12, PAD, EventCard, 80)
    ui.noEvents = S.Text(ui.events.content, 13, C.dim); ui.noEvents:SetPoint("TOPLEFT", 2, -8); ui.noEvents:SetText(L("Aucun événement prévu. Crée le premier dans l'onglet Créer."))
    BuildCreate(pages.create)
    BuildNow(pages.now)
    win:SetScript("OnShow", function() WP.AskEvents(); WP.RefreshEvents() end)
end

function WP.ShowEventsTab(k)
    if not win then Build() end
    current = k
    for key, pg in pairs(pages) do pg:SetShown(key == k) end
    win:Show(); win:Raise()
    WP.RefreshEvents()
end
function WP.RefreshEvents()
    if not (win and win:IsShown()) then return end
    tabs:Update()
    if current == "upcoming" then RenderUpcoming() elseif current == "now" then RenderNow() end
end
function WP.ToggleEvents()
    if win and win:IsShown() then win:Hide(); return end
    if WP.ModuleOff and WP.ModuleOff("events") then return end
    WP.ShowEventsTab(current)
end
function WP.HideEvents() if win then win:Hide() end end

local askedAt = -60
function WP.AskEvents()
    if GetTime() - askedAt < 60 then return end
    askedAt = GetTime()
    Send("Q")
end

-- ---------------------------------------------------------------- events
local ev = CreateFrame("Frame")
pcall(ev.RegisterEvent, ev, "PLAYER_LOGIN")
pcall(ev.RegisterEvent, ev, "CHAT_MSG_ADDON")
ev:SetScript("OnEvent", function(_, e, prefix, msg, channel, sender)
    if not WLWritsDB then return end
    if e == "PLAYER_LOGIN" then
        pcall(Prune)
        C_Timer.After(30, function() if On() then WP.AskEvents() end end)
        if C_Timer.NewTicker then C_Timer.NewTicker(30, Remind) end
    elseif prefix == PREFIX and channel == "GUILD" and type(msg) == "string" and sender then
        local who = Short(sender)
        if who ~= Me() then OnMessage(msg, who) end
    end
end)
