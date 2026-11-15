-- Writs/Events.lua: the Events module (/wlh events): the guild's own calendar and LFG.
--
--  Upcoming  A member plans a dungeon or a raid: a name, a day and an hour, places per role (tanks,
--            healers, damage) and a note. Others sign up with a role, change it, or step out. At
--            login, a line recalls what you organize or joined in the next 24 h; 1 h and 15 minutes
--            before, those signed up get a reminder; the organizer gets a banner to invite everyone
--            in one click, and the organizer's invite is accepted by itself (can be turned off).
--            A cancelled event is announced to those signed up.
--  Now       "I'm looking for a group": your role (from your spec by default) and what for; the list
--            of members looking right now, with Whisper and Invite buttons. Your search is renewed
--            while you stay on and withdrawn when your group is full or you log out; other entries
--            fade after 30 minutes. A new search in the guild gets one line in the chat.
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
    ["Les autres seront invités dès que le groupe passe en raid."] = "The others will be invited as soon as the group becomes a raid.",
    -- the day itself
    ["Tu organises : %s, %s (%d inscrits)."] = "You organize: %s, %s (%d signed up).",
    ["Tu es inscrit : %s, %s."] = "You are signed up: %s, %s.",
    ["Rappel : %s commence dans 1 h."] = "Reminder: %s starts in 1 h.",
    ["Plus tard"] = "Later",
    ["%s : %d inscrits attendent ton invitation."] = "%s: %d signed up are waiting for your invite.",
    ["Invitation de %s acceptée pour %s."] = "Invite from %s accepted for %s.",
    ["Accepter seul l'invitation de l'organisateur quand je suis inscrit"] = "Accept the organizer's invite by myself when I am signed up",
    ["Événement annulé par %s : %s (%s)."] = "Event cancelled by %s: %s (%s).",
    -- group now
    ["%s cherche un groupe (%s, niv. %s) : %s. /wlh events"] = "%s is looking for a group (%s, lv %s): %s. /wlh events",
    ["n'importe quoi"] = "anything",
    ["Ton groupe est complet : tu ne cherches plus de groupe."] = "Your group is full: you are no longer looking for a group.",
    ["Pour quoi ? (ex. Zul'Farrak, quêtes Maleterres)"] = "What for? (e.g. Zul'Farrak, Plaguelands quests)",
    ["La guilde voit ta recherche. Elle s'arrête seule quand ton groupe est complet."] = "The guild sees your search. It stops by itself when your group is full.",
    ["Allume pour apparaître dans la liste de la guilde."] = "Turn on to appear in the guild's list.",
    ["Chuchoter"] = "Whisper",
    ["Inviter"] = "Invite",
    -- the event card and the Create form
    ["Confirmer l'annulation"] = "Confirm cancel",
    ["+%d en réserve"] = "+%d on standby",
    ["%s s'inscrit à %s (%s). %d inscrits."] = "%s signed up for %s (%s). %d signed up.",
    ["%s se désinscrit de %s."] = "%s stepped out of %s.",
    ["Créer un événement"] = "Create an event",
    ["Sera publié : %s, %s"] = "Will be published: %s, %s",
    ["Cette heure est déjà passée aujourd'hui. Choisis Demain."] = "That time is already past today. Pick Tomorrow.",
})

local PREFIX = "WLHevt"
local CI = C_ChatInfo
local Register = (CI and CI.RegisterAddonMessagePrefix) or RegisterAddonMessagePrefix
local SendRaw = (CI and CI.SendAddonMessage) or SendAddonMessage
if Register then pcall(Register, PREFIX) end

local function Me() return (UnitName("player")) end
local function Short(n) return n and (n:gsub("[%- ].*$", "")) end
local function On() return WP.ModuleOn("events") end
-- max is in bytes; the cut moves back to a character boundary so French letters are never split
local function Clean(s, max)
    s = tostring(s or ""):gsub("[|~\n]", " ")
    if max and #s > max then
        local cut = max
        while cut > 0 do
            local b = s:byte(cut + 1)
            if not b or b < 128 or b >= 192 then break end   -- not a UTF-8 continuation byte
            cut = cut - 1
        end
        s = s:sub(1, cut)
    end
    return s
end
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

-- The saved data of the current guild (WLWritsDB is account-wide: alts can be in other guilds).
-- No guild (or the game does not know it yet, a few seconds after login): a throwaway table.
local function GuildSlot(tbl)
    local g = GetGuildInfo and GetGuildInfo("player")
    if not g then return {}, false end
    local k = g .. "-" .. (GetRealmName and GetRealmName() or "")
    WLWritsDB[tbl] = WLWritsDB[tbl] or {}
    local s = WLWritsDB[tbl]
    s[k] = s[k] or {}
    return s[k], true
end

local function DB()
    local d, known = GuildSlot("eventsBy")
    -- once: the events saved before they were kept per guild go to the current guild
    if known and WLWritsDB.events then
        if next(d) == nil then for k, v in pairs(WLWritsDB.events) do d[k] = v end end
        WLWritsDB.events = nil
    end
    d.list, d.lfg, d.reminded = d.list or {}, d.lfg or {}, d.reminded or {}
    -- the 1 h reminder is kept apart: d.reminded stays 1 = 15 min done, 2 = "now" done
    d.reminded1h = d.reminded1h or {}
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
    for id, e in pairs(d.list) do
        -- a stub holds signups that came before their event: an hour to get the event, then gone
        local old
        if e.stub then old = e.stub < now - 3600 else old = (e.when or 0) < now - 6 * 3600 end
        if old then d.list[id] = nil; d.reminded[id] = nil; d.reminded1h[id] = nil end
    end
    -- my own search is renewed while it is on (Remind), so it never fades here
    for name, l in pairs(d.lfg) do if name ~= Me() and (l.t or 0) < now - 1800 then d.lfg[name] = nil end end
end

-- upcoming events, soonest first
function WP.EventList()
    Prune()
    local out = {}
    for _, e in pairs(DB().list) do if e.when then out[#out + 1] = e end end
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
-- A party holds 5 (pending invites count), and only a real group can become a raid: the first ones
-- fill the free party places, the rest wait until the group is converted to a raid (60 s at most).
local pendingInvites, inviteTicker = {}, nil
local function InviteLater(names)
    for _, n in ipairs(names) do pendingInvites[#pendingInvites + 1] = n end
    if inviteTicker or not C_Timer.NewTicker then return end
    local tries = 0
    inviteTicker = C_Timer.NewTicker(1, function()
        tries = tries + 1
        if IsInRaid() then
            local rest = pendingInvites
            pendingInvites = {}
            for i, name in ipairs(rest) do C_Timer.After(0.2 * i, function() InviteName(name) end) end
            inviteTicker:Cancel(); inviteTicker = nil
        elseif tries >= 60 then
            pendingInvites = {}
            inviteTicker:Cancel(); inviteTicker = nil
        elseif IsInGroup() and UnitIsGroupLeader and UnitIsGroupLeader("player") then
            local convert = (C_PartyInfo and C_PartyInfo.ConvertToRaid) or ConvertToRaid
            if convert then pcall(convert) end
        end
    end)
end
function WP.InviteSignups(e)
    local names = {}
    for name in pairs(e.signups or {}) do if name ~= Me() then names[#names + 1] = name end end
    local now, later = names, {}
    if not IsInRaid() then
        local free = math.max(0, 4 - (GetNumSubgroupMembers and GetNumSubgroupMembers() or 0))
        if #names > free then
            now, later = {}, {}
            for i, name in ipairs(names) do if i <= free then now[#now + 1] = name else later[#later + 1] = name end end
        end
    end
    for i, name in ipairs(now) do C_Timer.After(0.2 * i, function() InviteName(name) end) end
    if #later > 0 then
        WP.Print(L("Les autres seront invités dès que le groupe passe en raid."))
        InviteLater(later)
    end
end

-- The organizer's banner when the event is near: invite everyone in one click, or later.
-- A home-made frame (not a StaticPopup): it never touches the game's dialogs, and fades after 2 min.
local toast
local function ShowInviteToast(e)
    local others = 0
    for name in pairs(e.signups or {}) do if name ~= Me() then others = others + 1 end end
    if others == 0 then return end
    if not toast then
        toast = CreateFrame("Frame", "WLHelperEventToast", UIParent)
        toast:SetSize(340, 84); toast:SetPoint("TOP", 0, -140); toast:SetFrameStrata("DIALOG")
        S.Solid(toast, "BACKGROUND", C.card):SetAllPoints(); S.Border(toast, C.brand)
        toast.text = S.Text(toast, 13, C.text, true)
        toast.text:SetPoint("TOPLEFT", 12, -12); toast.text:SetPoint("RIGHT", -12, 0)
        toast.text:SetJustifyH("LEFT"); toast.text:SetWordWrap(true)
        toast.go = S.Button(toast, L("Inviter les inscrits"), 170, 28, "primary", function()
            if toast.e then WP.InviteSignups(toast.e) end
            toast:Hide()
        end)
        toast.go:SetPoint("BOTTOMLEFT", 12, 10)
        toast.later = S.Button(toast, L("Plus tard"), 120, 28, "secondary", function() toast:Hide() end)
        toast.later:SetPoint("BOTTOMRIGHT", -12, 10)
    end
    toast.e = e
    toast.text:SetText(string.format(L("%s : %d inscrits attendent ton invitation."), e.title or "?", others))
    toast:Show()
    local token = {}
    toast.token = token
    C_Timer.After(120, function() if toast.token == token then toast:Hide() end end)
end

-- The organizer's invite, accepted by itself when I am signed up to one of their events starting
-- within 30 minutes (before or after). The game's own dialog is only closed, never written to.
local function AutoAccept(inviter)
    if WLWritsDB.eventsAutoAccept == false or not On() or not inviter or (IsInGroup and IsInGroup()) then return end
    local who = Short(inviter)
    for _, ev2 in pairs(DB().list) do
        if ev2.status == "open" and ev2.when and ev2.by == who and ev2.signups and ev2.signups[Me()]
            and math.abs(ev2.when - time()) <= 1800 then
            if AcceptGroup then pcall(AcceptGroup) end
            C_Timer.After(0.1, function() if StaticPopup_Hide then pcall(StaticPopup_Hide, "PARTY_INVITE") end end)
            WP.Print(string.format(L("Invitation de %s acceptée pour %s."), who, ev2.title or "?"))
            return
        end
    end
end

-- My role when I look for a group: the one I picked, else the one of my spec (WL Helper's weights)
local function MyRole()
    if WLWritsCharDB and WLWritsCharDB.lfgRole then return WLWritsCharDB.lfgRole end
    local sp = WP.Weights and WP.Weights.Spec and WP.Weights.Spec()
    local k = sp and sp[1]
    if k == "prot" then return "tank" elseif k == "holy" or k == "disc" or k == "resto" then return "heal" end
    return "dps"
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
local function ClassHex(cls)
    local c = cls and RAID_CLASS_COLORS and RAID_CLASS_COLORS[cls]
    return c and string.format("|cff%02x%02x%02x", c.r * 255, c.g * 255, c.b * 255) or S.Hex(C.text)
end
local function CountSignups(e) local n = 0; for _ in pairs(e.signups or {}) do n = n + 1 end; return n end

-- when I last asked the guild (Q): the answers that follow are not news, no chat line for them
local askedAt = -60
local function OnMessage(msg, sender)
    local d = DB()
    local kind = msg:match("^(%u)")
    if kind == "E" then
        local id, by, when, tank, heal, dps, status, title, note = msg:match("^E|([^|]+)|([^|]+)|(%d+)|(%d+)|(%d+)|(%d+)|(%a+)|([^|]*)|?(.*)$")
        if not id or Short(by) ~= sender then return end
        local cur = d.list[id]
        local isNew = not cur or cur.stub ~= nil
        local wasOpen = cur and cur.stub == nil and cur.status == "open"
        cur = cur or { signups = {} }
        cur.id, cur.by, cur.when, cur.tank, cur.heal, cur.dps = id, sender, tonumber(when), tonumber(tank), tonumber(heal), tonumber(dps)
        cur.status, cur.title, cur.note = status, title, note
        cur.stub = nil   -- signups that came first are kept
        d.list[id] = cur
        if isNew and status == "open" and cur.when > time() and On() then
            WP.Print(string.format(L("Nouvel événement : %s, %s (par %s). /wlh events"), cur.title, When(cur.when), sender))
        end
        -- an event I signed up for is cancelled: in the chat and on screen
        if wasOpen and status == "cancelled" and cur.signups and cur.signups[Me()] and On() then
            local m = string.format(L("Événement annulé par %s : %s (%s)."), sender, cur.title or "?", When(cur.when))
            WP.Print(m)
            if RaidNotice_AddMessage and RaidWarningFrame then RaidNotice_AddMessage(RaidWarningFrame, m, { r = 0.81, g = 0.1, b = 0.09 }) end
        end
        Refresh()
    elseif kind == "J" then
        local id, role, cls, lvl, name = msg:match("^J|([^|]+)|(%a+)|(%u*)|(%d+)|([^|]+)$")
        local e = id and d.list[id]
        if not id or Short(name) ~= sender then return end
        -- the event itself may come a little later (each copy sends one line a second): keep the signup
        if not e then e = { id = id, signups = {}, stub = time() }; d.list[id] = e end
        e.signups = e.signups or {}
        local before = e.signups[sender]
        if role == "x" then e.signups[sender] = nil
        else e.signups[sender] = { role = role, cls = cls, lvl = tonumber(lvl), t = time() } end
        -- the organizer is told who comes and who leaves (not the repeats sent at each login)
        if not e.stub and e.by == Me() and On() then
            if role ~= "x" and not (before and before.role == role) then
                WP.Print(string.format(L("%s s'inscrit à %s (%s). %d inscrits."), sender, e.title or "?", L(ROLE_LABEL[role] or "DPS"), CountSignups(e)))
            elseif role == "x" and before then
                WP.Print(string.format(L("%s se désinscrit de %s."), sender, e.title or "?"))
            end
        end
        Refresh()
    elseif kind == "N" then
        local role, cls, lvl, what = msg:match("^N|(%a+)|(%u*)|(%d*)|(.*)$")
        if not role then return end
        local was = d.lfg[sender]
        if role == "x" then d.lfg[sender] = nil
        else
            d.lfg[sender] = { role = role, cls = cls, lvl = tonumber(lvl), what = what, t = time() }
            -- a new search: one line in the chat (not the answers to my own question at login)
            if not was and On() and GetTime() - askedAt > 20 then
                WP.Print(string.format(L("%s cherche un groupe (%s, niv. %s) : %s. /wlh events"), ClassHex(cls) .. sender .. "|r",
                    L(ROLE_LABEL[role] or "DPS"), lvl ~= "" and lvl or "?", what ~= "" and what or L("n'importe quoi")))
            end
        end
        Refresh()
    elseif kind == "Q" then
        -- someone logged in: what I organize, what I signed up for, whether I'm looking
        for _, e in pairs(d.list) do
            if e.when then
                if e.by == Me() and e.when > time() - 3600 then Send(EventMsg(e)) end
                local s = e.signups and e.signups[Me()]
                if s and e.when > time() then Send(SignupMsg(e.id, Me(), s)) end
            end
        end
        local l = d.lfg[Me()]
        if l then Send(table.concat({ "N", l.role, l.cls or "", l.lvl or 0, l.what or "" }, "|")) end
    end
end

-- ---------------------------------------------------------------- reminders
local function Remind()
    if not (WLWritsDB and On()) then return end
    -- my search for a group stays fresh for the others while it is on (their copies drop it after 30 min)
    local l = DB().lfg[Me()]
    if l and time() - (l.t or 0) > 1200 then WP.SetLooking(l.role, l.what) end
    local d, now = DB(), time()
    for id, e in pairs(d.list) do
        local mine = e.by == Me() or (e.signups and e.signups[Me()])
        if e.when and mine and e.status == "open" then
            local left = (e.when or 0) - now
            local r = d.reminded[id] or 0
            if left <= 3600 and left > 900 and not d.reminded1h[id] then
                d.reminded1h[id] = true
                WP.Print(string.format(L("Rappel : %s commence dans 1 h."), e.title or "?"))
            end
            if left <= 900 and left > 0 and r < 1 then
                d.reminded[id] = 1
                local msg = string.format(L("Rappel : %s commence dans 15 min."), e.title or "?")
                WP.Print(msg)
                if RaidNotice_AddMessage and RaidWarningFrame then RaidNotice_AddMessage(RaidWarningFrame, msg, { r = 0.81, g = 0.1, b = 0.09 }) end
                if PlaySound and SOUNDKIT and SOUNDKIT.RAID_WARNING then pcall(PlaySound, SOUNDKIT.RAID_WARNING, "Master") end
                if e.by == Me() then ShowInviteToast(e) end
            elseif left <= 0 and left > -600 and r < 2 then
                d.reminded[id] = 2
                WP.Print(string.format(L("%s commence maintenant."), e.title or "?"))
                if e.by == Me() then ShowInviteToast(e) end
            end
        end
    end
end

-- At login: what I organize or signed up for in the next 24 hours, one line each.
local function LoginRecap()
    local now = time()
    for _, e in pairs(DB().list) do
        if e.when and e.status == "open" and e.when > now and e.when - now <= 86400 then
            if e.by == Me() then
                local count = 0
                for name in pairs(e.signups or {}) do if name ~= Me() then count = count + 1 end end
                WP.Print(string.format(L("Tu organises : %s, %s (%d inscrits)."), e.title or "?", When(e.when), count))
            elseif e.signups and e.signups[Me()] then
                WP.Print(string.format(L("Tu es inscrit : %s, %s."), e.title or "?", When(e.when)))
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
        -- signed up: the same buttons change the role (WP.SignUp overwrites); mine is outlined in red
        local b = S.Button(c, RoleText(role, 14), 92, 26, "secondary", function() if c.e then WP.SignUp(c.e, role) end end)
        b.role = role
        b.sel = S.Border(b, C.brand)
        c.btns[i] = b
    end
    c.out = S.Button(c, L("Me désinscrire"), 120, 26, "secondary", function() if c.e then WP.SignUp(c.e, nil) end end)
    c.invite = S.Button(c, L("Inviter les inscrits"), 150, 26, "primary", function() if c.e then WP.InviteSignups(c.e) end end)
    -- cancel in two clicks: the first one asks, the second (within 4 s) cancels
    c.cancel = S.Button(c, L("Annuler l'événement"), 150, 26, "warn", function()
        if not c.e then return end
        if c.confirmUntil and GetTime() < c.confirmUntil then
            c.confirmUntil = nil
            c.cancel.label:SetText(L("Annuler l'événement"))
            WP.CancelEvent(c.e)
        else
            c.confirmUntil = GetTime() + 4
            c.cancel.label:SetText(L("Confirmer l'annulation"))
            C_Timer.After(4.1, function()
                if not c.confirmUntil or GetTime() >= c.confirmUntil then
                    c.confirmUntil = nil
                    c.cancel.label:SetText(L("Annuler l'événement"))
                end
            end)
        end
    end)
    return c
end

local function PaintEvent(c, e)
    if c.e ~= e then
        -- the card shows another event now: a pending "Confirm cancel" does not follow
        c.confirmUntil = nil
        c.cancel.label:SetText(L("Annuler l'événement"))
    end
    c.e = e
    local cancelled = e.status ~= "open"
    c.when:SetText(When(e.when) .. (cancelled and ("  ·  " .. L("annulé")) or ""))
    c.title:SetText(e.title or "?")
    c.title:SetTextColor((cancelled and C.dim or C.text)[1], (cancelled and C.dim or C.text)[2], (cancelled and C.dim or C.text)[3])
    c.by:SetText(string.format(L("par %s"), e.by or "?") .. "  ·  " .. string.format(L("%d inscrits"), CountSignups(e)))
    local n = WP.EventCounts(e)
    local parts = {}
    for _, role in ipairs(ROLES) do
        local want = e[role] or 0
        if want > 0 or n[role] > 0 then
            local col = (n[role] >= want and want > 0) and C.ready or C.text
            local s = RoleIcon(role, 16) .. " " .. S.Hex(col) .. n[role] .. "/" .. want
            -- full: said in words; more than asked: they stay signed up, on standby
            if want > 0 and n[role] == want then s = s .. " " .. L("complet") end
            s = s .. "|r"
            if want > 0 and n[role] > want then s = s .. " " .. S.Hex(C.warn) .. string.format(L("+%d en réserve"), n[role] - want) .. "|r" end
            parts[#parts + 1] = s
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
    -- buttons: sign up with a role (signed up: change it) / step out; the organizer invites or cancels
    -- the organizer's own sign-up buttons go on a second row, above Invite / Cancel
    local mine = WP.MySignup(e)
    local organizer = e.by == Me() and not cancelled
    local x, y = 12, 10
    local rowY = organizer and 44 or 10
    for _, b in ipairs(c.btns) do
        b:SetShown(not cancelled)
        local on = mine and mine.role == b.role
        b.sel(on and C.brand or C.border, on and 1 or 0)
        b:ClearAllPoints(); b:SetPoint("BOTTOMLEFT", x, rowY); x = x + 92 + 6
    end
    c.out:SetShown(not cancelled and mine ~= nil); c.out:ClearAllPoints(); c.out:SetPoint("BOTTOMLEFT", 12 + 3 * 98, rowY)
    c.invite:SetShown(organizer); c.cancel:SetShown(organizer)
    c.cancel:ClearAllPoints(); c.cancel:SetPoint("BOTTOMRIGHT", -12, y)
    c.invite:ClearAllPoints(); c.invite:SetPoint("RIGHT", c.cancel, "LEFT", -8, 0)
    local h = 82 + math.max(0, (c.who:GetStringHeight() or 0)) + ((e.note and e.note ~= "") and ((c.note:GetStringHeight() or 14) + 6) or 0) + 44
    h = h + (organizer and 34 or 0)
    c:SetHeight(h)
    return h
end

local function Whisper(name)
    if ChatFrame_OpenChat then ChatFrame_OpenChat("/w " .. name .. " ")
    elseif ChatFrameUtil and ChatFrameUtil.OpenChat then ChatFrameUtil.OpenChat("/w " .. name .. " ") end
end

-- two lines: class icon, name, role and how long ago; then what for. Whisper and Invite on the right.
local function LookRow(parent)
    local r = CreateFrame("Button", nil, parent)
    r:SetSize(W - 2 * PAD, 44)
    r:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    r.bg = S.Solid(r, "BACKGROUND", C.card); r.bg:SetAllPoints()
    r.cls = r:CreateTexture(nil, "OVERLAY"); r.cls:SetSize(16, 16); r.cls:SetPoint("TOPLEFT", 8, -6)
    r.cls:SetTexture("Interface\\TargetingFrame\\UI-Classes-Circles")
    r.name = S.Text(r, 14, C.text, true); r.name:SetPoint("TOPLEFT", 28, -6); r.name:SetWidth(140); r.name:SetJustifyH("LEFT"); r.name:SetWordWrap(false)
    r.role = S.Text(r, 12, C.brandSoft, true); r.role:SetPoint("TOPLEFT", 172, -7); r.role:SetJustifyH("LEFT")
    r.ago = S.Text(r, 12, C.muted); r.ago:SetPoint("TOPRIGHT", -160, -8); r.ago:SetJustifyH("RIGHT")
    r.what = S.Text(r, 13, C.text); r.what:SetPoint("BOTTOMLEFT", 28, 6); r.what:SetPoint("RIGHT", -160, 0); r.what:SetJustifyH("LEFT"); r.what:SetWordWrap(false)
    r.whisper = S.Button(r, L("Chuchoter"), 72, 22, "secondary", function() if r.who then Whisper(r.who) end end)
    r.whisper:SetPoint("RIGHT", -80, 0)
    r.inv = S.Button(r, L("Inviter"), 72, 22, "secondary", function() if r.who then InviteName(r.who) end end)
    r.inv:SetPoint("RIGHT", -4, 0)
    r:SetScript("OnClick", function(self, button)
        local who = self.who
        if not who or who == Me() then return end
        if button == "RightButton" or IsAltKeyDown() then InviteName(who) else Whisper(who) end
    end)
    r:SetScript("OnEnter", function(self)
        if not self.who then return end
        local lines = { self.who }
        -- the full text (the line may cut it); what0 because r.what is the font string
        if self.what0 and self.what0 ~= "" then lines[#lines + 1] = self.what0 end
        S.Tip(self, lines)
    end)
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
    ui.createFirst:SetShown(#list == 0)
    ui.autoAccept:Update()
end

local function RenderNow()
    local role = WP.IsLooking()
    ui.lookSwitch:Update()
    ui.lookSeg:Update()
    ui.lookState:SetText(role and L("La guilde voit ta recherche. Elle s'arrête seule quand ton groupe est complet.")
        or L("Allume pour apparaître dans la liste de la guilde."))
    local list = WP.LFGList()
    for i, l in ipairs(list) do
        local r = ui.looking.Get(i)
        r:ClearAllPoints(); r:SetPoint("TOPLEFT", 0, -(i - 1) * 46)
        r.bg:SetAlpha(i % 2 == 0 and 0.6 or 1)
        r.who, r.what0 = l.name, l.what
        local tc = CLASS_ICON_TCOORDS and l.cls and CLASS_ICON_TCOORDS[l.cls]
        if tc then r.cls:SetTexCoord(tc[1], tc[2], tc[3], tc[4]); r.cls:Show() else r.cls:Hide() end
        r.name:SetText(ClassHex(l.cls) .. l.name .. "|r " .. S.Hex(C.muted) .. (l.lvl or "") .. "|r")
        r.role:SetText(RoleText(l.role, 14))
        r.what:SetText((l.what and l.what ~= "") and l.what or S.Hex(C.muted) .. L("n'importe quoi") .. "|r")
        r.ago:SetText(string.format(L("il y a %d min"), math.max(0, math.floor((time() - l.t) / 60))))
        local other = l.name ~= Me()
        r.whisper:SetShown(other); r.inv:SetShown(other)
    end
    ui.looking.HideFrom(#list + 1)
    ui.looking.content:SetHeight(math.max(10, #list * 46))
    ui.noLooking:SetShown(#list == 0)
end

-- Today, Tomorrow, then "sam. 21" (the day of the month avoids doubts); short: the day name alone
local function DayChoices(short)
    local out = {}
    for i = 0, 6 do
        local t = DayStart(time()) + i * 86400
        local d = date("*t", t)
        local label = (i == 0 and L("Aujourd'hui")) or (i == 1 and L("Demain"))
            or ((root.lang == "en") and DAYS.en or DAYS.fr)[d.wday] .. (short and "" or (" " .. d.day))
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
    -- x: the column (PAD by default); keepY: the next label goes on the same line
    local function Label(text, x, keepY)
        local t = S.Text(p, 13, C.dim, true); t:SetPoint("TOPLEFT", x or PAD, y); t:SetText(text)
        if not keepY then y = y - 22 end
        return t
    end
    draft.kind = draft.kind or "dg"
    -- the places are filled by kind until the player types one: tanks, healers, damage
    local PRESET = { raid = { 3, 8, 29 }, dg = { 1, 1, 3 }, quest = { 0, 0, 5 }, other = { 0, 0, 5 } }
    local placesTouched = false
    -- the start time from the day and the hour typed; nil when the hour cannot be read
    local function ParseWhen()
        local hh, mm = (ui.hour:GetText() or ""):match("^%s*(%d%d?)[:hH]?(%d?%d?)%s*$")
        hh, mm = tonumber(hh), tonumber(mm ~= "" and mm or "0")
        if not hh or hh > 23 or not mm or mm > 59 then return nil end
        return DayStart(time()) + draft.day * 86400 + hh * 3600 + mm * 60
    end
    -- what will be published, read back above the button
    local function Recap()
        if not (ui.recap and ui.title and ui.hour) then return end
        local title = ui.title:GetText() or ""
        local when = ParseWhen()
        if title:gsub("%s", "") ~= "" and when then
            ui.recap:SetText(string.format(L("Sera publié : %s, %s"), title, When(when)))
        else
            ui.recap:SetText("")
        end
    end
    -- the kind, then the instances of that kind as chips (several can be picked)
    local chips = CreateFrame("ScrollFrame", nil, p)
    local inner = CreateFrame("Frame", nil, chips)
    local function Chips()
        for _, c in ipairs(inner.items or {}) do c:Hide() end
        inner.items = inner.items or {}
        local list = (draft.kind == "dg" or draft.kind == "raid") and Instances(draft.kind) or {}
        -- two columns: the full French names fit (Monastère écarlate : Cathédrale...)
        local cw, ch, cols = math.floor((W - 2 * PAD - 6) / 2), 26, 2
        for i, e in ipairs(list) do
            local c = inner.items[i]
            if not c then
                c = CreateFrame("Button", nil, inner)
                c:SetSize(cw, ch)
                c.bg = S.Solid(c, "BACKGROUND", C.card); c.bg:SetAllPoints()
                c.edge = S.Border(c, C.border)
                -- the level has its own slot on the right, so a long name is cut before it, never the level
                c.lv = S.Text(c, 12, C.muted); c.lv:SetPoint("RIGHT", -6, 0); c.lv:SetJustifyH("RIGHT")
                c.t = S.Text(c, 12, C.text); c.t:SetPoint("LEFT", 8, 0); c.t:SetPoint("RIGHT", c.lv, "LEFT", -4, 0); c.t:SetJustifyH("LEFT"); c.t:SetWordWrap(false)
                c:SetScript("OnClick", function(self)
                    picked[self.key] = not picked[self.key] or nil
                    ui.title:SetText(PickedTitle())
                    Chips()
                    Recap()
                end)
                inner.items[i] = c
            end
            c.key = e[1]
            c:ClearAllPoints(); c:SetPoint("TOPLEFT", ((i - 1) % cols) * (cw + 6), -math.floor((i - 1) / cols) * (ch + 6))
            c.t:SetText(e[2]); c.lv:SetText(e[3])
            local on = picked[e[1]]
            c.bg:SetColorTexture((on and C.brandBg or C.card)[1], (on and C.brandBg or C.card)[2], (on and C.brandBg or C.card)[3], 1)
            c.edge(on and C.brand or C.border)
            c:Show()
        end
        inner:SetSize(W - 2 * PAD, math.max(10, math.ceil(#list / cols) * (ch + 6)))
        chips:SetShown(#list > 0)
    end
    local kind = S.Segmented(p, { { "dg", L("Donjon") }, { "raid", L("Raid") }, { "quest", L("Quête") }, { "other", L("Autre") } },
        function() return draft.kind end, function(v)
            draft.kind = v; wipe(picked); ui.title:SetText(""); Chips()
            if not placesTouched and PRESET[v] then
                for i, role in ipairs(ROLES) do
                    draft[role] = PRESET[v][i]
                    if ui["n_" .. role] then ui["n_" .. role]:SetText(tostring(PRESET[v][i])) end
                end
            end
            Recap()
        end, 28)
    kind:SetPoint("TOPLEFT", PAD, y); y = y - 38
    chips:SetPoint("TOPLEFT", PAD, y); chips:SetSize(W - 2 * PAD, 104); chips:SetScrollChild(inner)
    chips:EnableMouseWheel(true)
    chips:SetScript("OnMouseWheel", function(self, dlt)
        local max = math.max(0, inner:GetHeight() - self:GetHeight())
        self:SetVerticalScroll(math.max(0, math.min(max, self:GetVerticalScroll() - dlt * 32)))
    end)
    y = y - 112
    Label(L("Quoi"))
    ui.title = Box(p, W - 2 * PAD, L("Zul'Farrak, Onyxia, farm de cuir..."))
    ui.title:SetPoint("TOPLEFT", PAD, y); ui.title:SetMaxLetters(60); y = y - 40
    ui.title:HookScript("OnTextChanged", function() Recap() end)
    Chips()
    Label(L("Jour"))
    local function DaySet(v) draft.day = v; Recap() end
    ui.day = S.Segmented(p, DayChoices(), function() return draft.day end, DaySet, 28)
    if (ui.day:GetWidth() or 0) > W - 2 * PAD then
        -- the day numbers do not fit seven times: the day names alone
        ui.day:Hide()
        ui.day = S.Segmented(p, DayChoices(true), function() return draft.day end, DaySet, 28)
    end
    ui.day:SetPoint("TOPLEFT", PAD, y); y = y - 40
    -- the hour (four usual ones a click away) on the left, the places per role on the right
    local PX = PAD + 258
    Label(L("Heure"), PAD, true); Label(L("Places"), PX)
    ui.hour = Box(p, 60, "20:30"); ui.hour:SetPoint("TOPLEFT", PAD, y); ui.hour:SetMaxLetters(5)
    ui.hour:SetText("21:00")
    ui.hour:HookScript("OnTextChanged", function() Recap() end)
    for i, hv in ipairs({ "20:00", "20:30", "21:00", "21:30" }) do
        local hb = S.Button(p, hv, 44, 28, "secondary", function() ui.hour:SetText(hv); Recap() end)
        hb:SetPoint("TOPLEFT", PAD + 66 + (i - 1) * 46, y)
    end
    local x = PX
    for _, role in ipairs(ROLES) do
        local t = S.Text(p, 13, C.text); t:SetPoint("TOPLEFT", x, y - 4); t:SetText(RoleIcon(role, 20))
        local b = Box(p, 44, nil, true); b:SetPoint("TOPLEFT", x + 24, y)
        b:SetText(tostring(draft[role])); ui["n_" .. role] = b
        b:HookScript("OnTextChanged", function(_, user) if user then placesTouched = true end end)
        local rn = S.Text(p, 11, C.muted); rn:SetPoint("TOPLEFT", x, y - 30); rn:SetText(L(ROLE_LABEL[role]))
        x = x + 88
    end
    y = y - 54
    Label(L("Note"))
    ui.note = Box(p, W - 2 * PAD, nil); ui.note:SetPoint("TOPLEFT", PAD, y); ui.note:SetMaxLetters(120); y = y - 40
    ui.err = S.Text(p, 12, C.danger); ui.err:SetPoint("BOTTOMLEFT", PAD, PAD + 62); ui.err:SetPoint("RIGHT", -PAD, 0)
    ui.err:SetJustifyH("LEFT"); ui.err:SetWordWrap(false)
    ui.recap = S.Text(p, 12, C.dim); ui.recap:SetPoint("BOTTOMLEFT", PAD, PAD + 44); ui.recap:SetPoint("RIGHT", -PAD, 0)
    ui.recap:SetJustifyH("LEFT"); ui.recap:SetWordWrap(false)
    local go = S.Button(p, L("Publier l'événement"), W - 2 * PAD, 36, "primary", function()
        local title = ui.title:GetText()
        if not title or title:gsub("%s", "") == "" then ui.err:SetText(L("Donne un nom à l'événement.")); return end
        local when = ParseWhen()
        if not when then ui.err:SetText(L("Heure invalide : écris par exemple 20:30.")); return end
        if when < time() - 60 then
            ui.err:SetText(draft.day == 0 and L("Cette heure est déjà passée aujourd'hui. Choisis Demain.") or L("Cette heure est déjà passée."))
            return
        end
        local function N(role) return tonumber(ui["n_" .. role]:GetText()) or 0 end
        WP.CreateEvent(title, when, N("tank"), N("heal"), N("dps"), ui.note:GetText())
        ui.err:SetText(""); ui.title:SetText(""); ui.note:SetText(""); wipe(picked); Chips()
        placesTouched = false
        Recap()
        WP.ShowEventsTab("upcoming")
    end)
    go:SetPoint("BOTTOMLEFT", PAD, PAD)
    Recap()
end

local function BuildNow(p)
    local t = S.Text(p, 14, C.text, true); t:SetPoint("TOPLEFT", PAD, -16); t:SetText(L("Je cherche un groupe"))
    ui.lookSwitch = S.Switch(p, function() return WP.IsLooking() ~= nil end, function(v)
        if v then WP.SetLooking(MyRole(), ui.what:GetText()) else WP.SetLooking(nil) end
    end)
    ui.lookSwitch:SetPoint("TOPRIGHT", -PAD, -12)
    -- what the switch does, in words
    ui.lookState = S.Text(p, 12, C.muted); ui.lookState:SetPoint("TOPLEFT", PAD, -36); ui.lookState:SetPoint("RIGHT", -PAD - 50, 0)
    ui.lookState:SetJustifyH("LEFT"); ui.lookState:SetWordWrap(false)
    local rl = S.Text(p, 13, C.dim); rl:SetPoint("TOPLEFT", PAD, -70); rl:SetText(L("Mon rôle"))
    ui.lookSeg = S.Segmented(p, { { "tank", RoleText("tank", 14) }, { "heal", RoleText("heal", 14) }, { "dps", RoleText("dps", 14) } },
        function() return MyRole() end, function(v)
            WLWritsCharDB.lfgRole = v
            if WP.IsLooking() then WP.SetLooking(v, ui.what:GetText()) end
        end, 28)
    ui.lookSeg:SetPoint("TOPLEFT", PAD + 80, -64)
    ui.what = Box(p, W - 2 * PAD, L("Pour quoi ? (ex. Zul'Farrak, quêtes Maleterres)")); ui.what:SetPoint("TOPLEFT", PAD, -104); ui.what:SetMaxLetters(80)
    ui.what:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
        if WP.IsLooking() then WP.SetLooking(MyRole(), self:GetText()) end
    end)
    -- the text counts without Enter too (only sent when it changed)
    ui.what:SetScript("OnEditFocusLost", function(self)
        if WP.IsLooking() then
            local _, w = WP.IsLooking()
            if (w or "") ~= Clean(self:GetText(), 80) then WP.SetLooking(MyRole(), self:GetText()) end
        end
    end)
    ui.looking = List(p, -146, 40, LookRow, 46)
    ui.noLooking = S.Text(ui.looking.content, 13, C.dim); ui.noLooking:SetPoint("TOPLEFT", 2, -8); ui.noLooking:SetText(L("Personne ne cherche de groupe en ce moment."))
    local note = S.Text(p, 12, C.muted); note:SetPoint("BOTTOMLEFT", PAD, 14); note:SetPoint("RIGHT", -PAD, 0); note:SetJustifyH("LEFT"); note:SetWordWrap(true)
    note:SetText(L("Seuls les membres qui ont WL Helper voient les événements et les recherches de groupe."))
end

local function Build()
    win = S.Window("WLHelperEvents", W, H, L("Événements"), GetGuildInfo and GetGuildInfo("player") or nil, WLWritsDB, "eventsPos")
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
    ui.events = List(pages.upcoming, -12, 44, EventCard, 80)
    ui.noEvents = S.Text(ui.events.content, 13, C.dim); ui.noEvents:SetPoint("TOPLEFT", 2, -8); ui.noEvents:SetText(L("Aucun événement prévu. Crée le premier dans l'onglet Créer."))
    ui.createFirst = S.Button(ui.events.content, L("Créer un événement"), 220, 30, "primary", function() WP.ShowEventsTab("create") end)
    ui.createFirst:SetPoint("TOPLEFT", 2, -32)
    -- the auto-accept setting, where the events are
    ui.autoAccept = S.Switch(pages.upcoming, function() return WLWritsDB.eventsAutoAccept ~= false end, function(v) WLWritsDB.eventsAutoAccept = v end)
    ui.autoAccept:SetPoint("BOTTOMLEFT", PAD, 14)
    local st = S.Text(pages.upcoming, 12, C.dim)
    st:SetPoint("LEFT", ui.autoAccept, "RIGHT", 8, 0); st:SetPoint("RIGHT", pages.upcoming, "RIGHT", -PAD, 0)
    st:SetJustifyH("LEFT"); st:SetWordWrap(false)
    st:SetText(L("Accepter seul l'invitation de l'organisateur quand je suis inscrit"))
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

-- askedAt is declared above OnMessage, which reads it
function WP.AskEvents()
    if GetTime() - askedAt < 60 then return end
    askedAt = GetTime()
    Send("Q")
end

-- ---------------------------------------------------------------- events
local ev = CreateFrame("Frame")
pcall(ev.RegisterEvent, ev, "PLAYER_LOGIN")
pcall(ev.RegisterEvent, ev, "CHAT_MSG_ADDON")
pcall(ev.RegisterEvent, ev, "PARTY_INVITE_REQUEST")
pcall(ev.RegisterEvent, ev, "GROUP_ROSTER_UPDATE")
pcall(ev.RegisterEvent, ev, "PLAYER_LOGOUT")
ev:SetScript("OnEvent", function(_, e, prefix, msg, channel, sender)
    if not WLWritsDB then return end
    if e == "PLAYER_LOGIN" then
        pcall(Prune)
        C_Timer.After(30, function()
            -- a search left on by a crash (no logout seen) is not brought back after 30 min
            local l = DB().lfg[Me()]
            if l and time() - (l.t or 0) > 1800 then DB().lfg[Me()] = nil end
            if On() then WP.AskEvents() end
        end)
        C_Timer.After(40, function() if On() then pcall(LoginRecap) end end)
        if C_Timer.NewTicker then C_Timer.NewTicker(30, Remind) end
    elseif e == "PARTY_INVITE_REQUEST" then
        -- prefix is the inviter's name for this event
        pcall(AutoAccept, prefix)
    elseif e == "GROUP_ROSTER_UPDATE" then
        if On() and WP.IsLooking() and ((IsInRaid and IsInRaid()) or (GetNumSubgroupMembers and GetNumSubgroupMembers() >= 4)) then
            WP.SetLooking(nil)
            WP.Print(L("Ton groupe est complet : tu ne cherches plus de groupe."))
        end
    elseif e == "PLAYER_LOGOUT" then
        -- sent at once: the queue (one line a second) would not run any more
        local d = DB()
        if d.lfg[Me()] then
            d.lfg[Me()] = nil
            if SendRaw and IsInGuild and IsInGuild() then pcall(SendRaw, PREFIX, "N|x|||", "GUILD") end
        end
    elseif prefix == PREFIX and channel == "GUILD" and type(msg) == "string" and sender then
        local who = Short(sender)
        if who ~= Me() then OnMessage(msg, who) end
    end
end)
