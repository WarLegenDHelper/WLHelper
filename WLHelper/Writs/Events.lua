-- Writs/Events.lua: the group module, "Groupes" / "Groups" (/wlh lfg, /wlh events): the guild's own
-- calendar and its group searches. The window follows the design system (docs/DESIGN.md): 520 wide,
-- sized to its content, cards and rows from Writs/Style.lua.
--
--  Agenda    A member plans a dungeon or a raid: a name, a day and an hour, places per role (tanks,
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
    -- the window, its header and its tabs
    ["Seuls les membres qui ont WL Helper voient les événements et les recherches de groupe."] = "Only members who have WL Helper see the events and the group searches.",
    ["WL Helper n'envoie jamais de message privé : tout passe par le canal de la guilde."] = "WL Helper never whispers anyone: everything goes through the guild channel.",
    ["Agenda"] = "Upcoming",
    ["Créer"] = "Create",
    ["Groupe maintenant"] = "Group now",
    -- Agenda: the empty state, the cards, the auto-accept setting
    ["Aucun événement prévu"] = "No events planned",
    ["Les donjons et raids prévus par la guilde apparaîtront ici."] = "Dungeons and raids the guild plans will show up here.",
    ["Créer un événement"] = "Create an event",
    ["Tank"] = "Tank", ["Soigneur"] = "Healer", ["DPS"] = "DPS",
    ["Clic : t'inscrire comme tank"] = "Click: sign up as tank",
    ["Clic : t'inscrire comme soigneur"] = "Click: sign up as healer",
    ["Clic : t'inscrire comme DPS"] = "Click: sign up as DPS",
    ["Me désinscrire"] = "Cancel sign-up",
    ["Inviter les inscrits"] = "Invite sign-ups",
    ["Invitations envoyées"] = "Invites sent",
    ["Personne d'autre n'est inscrit pour l'instant."] = "Nobody else has signed up yet.",
    ["Annuler l'événement"] = "Cancel event",
    ["Confirmer l'annulation"] = "Confirm cancel",
    ["Annulé"] = "Cancelled",
    ["Organisateur"] = "Organizer",
    ["Inscrit"] = "Signed up",
    ["par %s"] = "by %s",
    ["aucun inscrit pour l'instant"] = "no sign-ups yet",
    ["1 inscrit"] = "1 sign-up",
    ["%d inscrits"] = "%d sign-ups",
    ["complet"] = "full",
    ["+%d en réserve"] = "+%d in reserve",
    ["Accepter l'invitation de l'organisateur"] = "Accept the organizer's invite",
    ["Quand tu es inscrit, son invitation est acceptée pour toi, de 30 min avant le début à 30 min après."] = "When you are signed up, their invite is accepted for you, from 30 min before the start to 30 min after.",
    -- dates and times
    ["Aujourd'hui"] = "Today", ["Demain"] = "Tomorrow",
    ["aujourd'hui"] = "today", ["demain"] = "tomorrow",
    -- Create
    ["Type"] = "Type",
    ["Donjon"] = "Dungeon", ["Raid"] = "Raid", ["Quête"] = "Quest", ["Autre"] = "Other",
    ["Choisir les donjons"] = "Pick dungeons",
    ["Choisir les raids"] = "Pick raids",
    ["Clic : choisir les donjons"] = "Click: pick dungeons",
    ["Clic : choisir les raids"] = "Click: pick raids",
    ["(+%d)"] = "(+%d)",
    ["Nom de l'événement"] = "Event name",
    ["Ex. Zul'Farrak"] = "E.g. Zul'Farrak",
    ["Ex. Onyxia"] = "E.g. Onyxia",
    ["Ex. quêtes des Maleterres"] = "E.g. Plaguelands quests",
    ["Ex. farm de cuir à Feralas"] = "E.g. leather farming in Feralas",
    ["Jour"] = "Day",
    ["Heure"] = "Time",
    ["Places tank"] = "Tank slots",
    ["Places soigneur"] = "Healer slots",
    ["Places DPS"] = "DPS slots",
    ["Note (facultatif)"] = "Note (optional)",
    ["Ex. niveau 45 minimum, rendez-vous à Gadgetzan"] = "E.g. level 45 and up, meet in Gadgetzan",
    ["Sera publié : %s, %s."] = "Will be published: %s, %s.",
    ["Publier l'événement"] = "Publish event",
    ["Donne un nom à l'événement, par exemple Zul'Farrak."] = "Give the event a name, for example Zul'Farrak.",
    ["Heure invalide : écris par exemple 20:30."] = "Invalid time: type for example 8:30 PM.",
    ["Cette heure est déjà passée aujourd'hui : choisis Demain ou une heure plus tard."] = "That time has already passed today: pick Tomorrow or a later time.",
    ["Cette heure est déjà passée."] = "That time has already passed.",
    -- the dungeon / raid picker
    ["Tu peux en cocher plusieurs : l'événement portera tous leurs noms."] = "You can tick several: the event will carry all their names.",
    ["Pour ton niveau"] = "For your level",
    ["Autres niveaux"] = "Other levels",
    ["niveau %s"] = "level %s",
    ["Clic : cocher"] = "Click: tick",
    ["Clic : décocher"] = "Click: untick",
    ["Tout décocher"] = "Untick all",
    ["Aucun donjon coché."] = "No dungeon ticked.",
    ["Aucun raid coché."] = "No raid ticked.",
    ["Continuer sans donjon"] = "Continue without a dungeon",
    ["Continuer sans raid"] = "Continue without a raid",
    ["Ajouter 1 donjon"] = "Add 1 dungeon",
    ["Ajouter %d donjons"] = "Add %d dungeons",
    ["Ajouter 1 raid"] = "Add 1 raid",
    ["Ajouter %d raids"] = "Add %d raids",
    -- Group now
    ["Je cherche un groupe"] = "I'm looking for a group",
    ["Les membres qui ont WL Helper te voient dans leur liste. Ta recherche s'arrête seule quand ton groupe est complet."] = "Guildmates with WL Helper see you in their list. Your search stops by itself when your group is full.",
    ["Mon rôle"] = "My role",
    ["Pour quoi ?"] = "What for?",
    ["Ex. Zul'Farrak, quêtes des Maleterres"] = "E.g. Zul'Farrak, Plaguelands quests",
    ["Membres qui cherchent un groupe"] = "Members looking for a group",
    ["Personne ne cherche de groupe"] = "Nobody is looking for a group",
    ["Quand un membre allume « Je cherche un groupe », il apparaît ici avec son rôle."] = "When a guildmate turns on \"I'm looking for a group\", they show up here with their role.",
    ["(toi)"] = "(you)",
    ["n'importe quel groupe"] = "any group",
    ["à l'instant"] = "just now",
    ["il y a %d min"] = "%d min ago",
    ["%s, niveau %s"] = "%s, level %s",
    ["Pour : %s"] = "For: %s",
    ["Pour n'importe quel groupe"] = "For any group",
    ["Chuchoter"] = "Whisper",
    ["Inviter"] = "Invite",
    ["Invité"] = "Invited",
    ["Clic : chuchoter"] = "Click: whisper",
    ["Clic droit : inviter dans ton groupe"] = "Right-click: invite to your group",
    -- the organizer's banner
    ["1 inscrit attend ton invitation."] = "1 sign-up is waiting for your invite.",
    ["%d inscrits attendent ton invitation."] = "%d sign-ups are waiting for your invite.",
    ["%s : commence dans %d min."] = "%s: starts in %d min.",
    ["%s : commence maintenant."] = "%s: starting now.",
    ["Plus tard"] = "Later",
    -- chat
    ["Nouvel événement : %s, %s (par %s). Tape /wlh lfg pour t'inscrire."] = "New event: %s, %s (by %s). Type /wlh lfg to sign up.",
    ["Rappel : %s commence dans 1 h."] = "Reminder: %s starts in 1 h.",
    ["Rappel : %s commence dans %d min."] = "Reminder: %s starts in %d min.",
    ["%s commence maintenant."] = "%s starts now.",   -- the same English as Home.lua's, never a second value
    ["Tu organises %s, %s. Personne n'est encore inscrit."] = "You're organizing %s, %s. Nobody has signed up yet.",
    ["Tu organises %s, %s : 1 inscrit."] = "You're organizing %s, %s: 1 sign-up.",
    ["Tu organises %s, %s : %d inscrits."] = "You're organizing %s, %s: %d sign-ups.",
    ["Tu es inscrit à %s, %s."] = "You're signed up for %s, %s.",
    ["Invitation de %s acceptée pour %s."] = "Accepted the invite from %s for %s.",
    ["Événement annulé par %s : %s, %s."] = "Event cancelled by %s: %s, %s.",
    ["%s s'inscrit à %s (%s). 1 inscrit en tout."] = "%s signed up for %s (%s). 1 sign-up so far.",
    ["%s s'inscrit à %s (%s). %d inscrits en tout."] = "%s signed up for %s (%s). %d sign-ups so far.",
    ["%s se désinscrit de %s."] = "%s is no longer signed up for %s.",
    ["%s cherche un groupe pour %s (%s, niveau %s). Tape /wlh lfg pour l'inviter."] = "%s is looking for a group for %s (%s, level %s). Type /wlh lfg to invite them.",
    ["%s cherche un groupe (%s, niveau %s). Tape /wlh lfg pour l'inviter."] = "%s is looking for a group (%s, level %s). Type /wlh lfg to invite them.",
    ["Ton groupe est complet : ta recherche de groupe s'arrête."] = "Your group is full: your group search has stopped.",
    ["Les autres inscrits seront invités dès que le groupe passe en raid."] = "The other sign-ups will be invited as soon as the group becomes a raid.",
    -- read by other windows (Home, the module list, the Writs window, the buttons)
    ["Donjons et raids de la guilde, groupes du moment"] = "Guild dungeons and raids, groups right now",
    ["%d événements à venir"] = "%d upcoming events",
    ["Prochain : %s, %s"] = "Next: %s, %s",
    ["Rien de prévu"] = "Nothing planned",
    ["%d cherchent un groupe"] = "%d looking for a group",
    ["niv. %s"] = "lv %s",
    ["%d objets meilleurs que les tiens dans tes sacs"] = "%d items in your bags better than yours",
    ["Rien de mieux dans tes sacs"] = "Nothing better in your bags",
    ["Spé, seuil et poids dans les réglages"] = "Spec, threshold and weights in the settings",
    ["Effacer"] = "Clear",
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
local ROLE_LABEL = { tank = "Tank", heal = "Soigneur", dps = "DPS" }
-- the game's role icon (modern atlas when the client has it) and the role's name
local function RoleText(role, size) return S.RoleMarkup(role, size or 14) .. " " .. L(ROLE_LABEL[role] or "DPS") end

-- The same chat line at most once every 30 s (a sign-up sent again at each login is not news).
local said = {}
local function Say(msg)
    local now = GetTime and GetTime() or 0
    if said[msg] and now - said[msg] < 30 then return end
    said[msg] = now
    WP.Print(msg)
end

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
-- 24 h in French ("21:00"), 12 h in English ("9:00 PM")
local function Clock(h, m)
    if root.lang == "en" then
        local h12 = h % 12
        if h12 == 0 then h12 = 12 end
        return string.format("%d:%02d %s", h12, m, h < 12 and "AM" or "PM")
    end
    return string.format("%02d:%02d", h, m)
end
-- "Demain 21:00", "sam. 15/11 21:00" ("Tomorrow 9:00 PM", "Sat 11/15 9:00 PM");
-- lower: inside a sentence ("demain 21:00")
local function When(t, lower)
    local d = date("*t", t)
    local today = DayStart(time())
    local day
    if DayStart(t) == today then day = lower and L("aujourd'hui") or L("Aujourd'hui")
    elseif DayStart(t) == today + 86400 then day = lower and L("demain") or L("Demain")
    elseif root.lang == "en" then day = DAYS.en[d.wday] .. " " .. string.format("%d/%d", d.month, d.day)
    else day = DAYS.fr[d.wday] .. " " .. string.format("%02d/%02d", d.day, d.month) end
    return day .. " " .. Clock(d.hour, d.min)
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
-- how many look for a group; excludeMe: the others only (a badge or a count never counts me)
function WP.LFGCount(excludeMe)
    local n = 0
    for _, l in ipairs(WP.LFGList()) do if not (excludeMe and l.name == Me()) then n = n + 1 end end
    return n
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
        Say(L("Les autres inscrits seront invités dès que le groupe passe en raid."))
        InviteLater(later)
    end
end

-- The organizer's banner when the event is near: invite everyone in one click, or later.
-- A toast-like frame at the top centre (not a StaticPopup: it never touches the game's dialogs):
-- one sentence, the event and when it starts, and two buttons. Fades in, stays 2 minutes (an action
-- waits on it, unlike the 4-6 s info toasts), fades out. It sits just above the S.Toast stack
-- (whose first toast hangs at y = -120), so both can show at once; when too tall for that room,
-- it goes below the deepest the stack can reach (two toasts).
local toast
local function HideToast()
    if not (toast and toast:IsShown()) then return end
    toast.token = nil
    root.Tween(toast, toast:GetAlpha() or 1, 0, 0.15, function(v) toast:SetAlpha(v); if v <= 0 then toast:Hide() end end)
end
local function ShowInviteToast(e, mins)
    local others = 0
    for name in pairs(e.signups or {}) do if name ~= Me() then others = others + 1 end end
    if others == 0 then return end
    local TW, TP = 320, 10
    if not toast then
        toast = CreateFrame("Frame", "WLHelperEventToast", UIParent)
        toast.wlOwned = true
        toast:SetWidth(TW); toast:SetFrameStrata("DIALOG")
        toast:EnableMouse(true)
        S.Solid(toast, "BACKGROUND", C.panel):SetAllPoints()
        S.Border(toast, C.cardEdge)
        toast.icon = S.Icon(toast, "group", 16, "ARTWORK", C.accentSoft)
        toast.icon:SetPoint("TOPLEFT", TP, -TP)
        toast.text = S.Text(toast, S.F.label, C.fg)
        toast.text:SetPoint("TOPLEFT", toast.icon, "TOPRIGHT", 8, 0)
        toast.sub = S.Text(toast, S.F.meta, C.muted)
        toast.sub:SetPoint("TOPLEFT", toast.text, "BOTTOMLEFT", 0, -3)
        toast.go = S.Button(toast, L("Inviter les inscrits"), 0, 28, "primary", function()
            if toast.e then WP.InviteSignups(toast.e) end
            HideToast()
        end)
        toast.go:SetIcon("group")
        toast.later = S.Button(toast, L("Plus tard"), 0, 28, "secondary", HideToast)
        toast.later:SetPoint("LEFT", toast.go, "RIGHT", 8, 0)
    end
    toast.e = e
    local textW = TW - TP - 16 - 8 - TP
    toast.text:SetText(others == 1 and L("1 inscrit attend ton invitation.")
        or string.format(L("%d inscrits attendent ton invitation."), others))
    toast.sub:SetText((mins and mins > 0) and string.format(L("%s : commence dans %d min."), e.title or "?", mins)
        or string.format(L("%s : commence maintenant."), e.title or "?"))
    -- never cut: the toast grows with its text
    local th = S.FitText(toast.text, 0, textW, toast)
    local sh = S.FitText(toast.sub, 0, textW, toast)
    local y = TP + th + 3 + sh + 10
    toast.go:ClearAllPoints(); toast.go:SetPoint("TOPLEFT", TP + 16 + 8, -y)
    local h = math.ceil(y + 28 + TP)
    toast:SetHeight(h)
    toast:ClearAllPoints()
    if h <= 120 - 6 - 8 then
        toast:SetPoint("BOTTOM", UIParent, "TOP", 0, -(120 - 6))
    else
        toast:SetPoint("TOP", UIParent, "TOP", 0, -(120 + 2 * (110 + 6)))
    end
    toast:SetAlpha(0); toast:Show()
    root.Tween(toast, 0, 1, 0.15, function(v) toast:SetAlpha(v) end)
    local token = {}
    toast.token = token
    C_Timer.After(120, function() if toast.token == token then HideToast() end end)
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
            Say(string.format(L("Invitation de %s acceptée pour %s."), who, ev2.title or "?"))
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
            Say(string.format(L("Nouvel événement : %s, %s (par %s). Tape /wlh lfg pour t'inscrire."), cur.title, When(cur.when, true), sender))
        end
        -- an event I signed up for is cancelled: in the chat and on screen
        if wasOpen and status == "cancelled" and cur.signups and cur.signups[Me()] and On() then
            local m = string.format(L("Événement annulé par %s : %s, %s."), sender, cur.title or "?", When(cur.when, true))
            Say(m)
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
                local n = CountSignups(e)
                Say(n == 1 and string.format(L("%s s'inscrit à %s (%s). 1 inscrit en tout."), sender, e.title or "?", L(ROLE_LABEL[role] or "DPS"))
                    or string.format(L("%s s'inscrit à %s (%s). %d inscrits en tout."), sender, e.title or "?", L(ROLE_LABEL[role] or "DPS"), n))
            elseif role == "x" and before then
                Say(string.format(L("%s se désinscrit de %s."), sender, e.title or "?"))
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
                local who, rl, lv = ClassHex(cls) .. sender .. "|r", L(ROLE_LABEL[role] or "DPS"), lvl ~= "" and lvl or "?"
                if what ~= "" then
                    Say(string.format(L("%s cherche un groupe pour %s (%s, niveau %s). Tape /wlh lfg pour l'inviter."), who, what, rl, lv))
                else
                    Say(string.format(L("%s cherche un groupe (%s, niveau %s). Tape /wlh lfg pour l'inviter."), who, rl, lv))
                end
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
            local mins = math.ceil(left / 60)
            if left <= 3600 and left > 900 and not d.reminded1h[id] then
                d.reminded1h[id] = true
                Say(left > 2700 and string.format(L("Rappel : %s commence dans 1 h."), e.title or "?")
                    or string.format(L("Rappel : %s commence dans %d min."), e.title or "?", mins))
            end
            if left <= 900 and left > 0 and r < 1 then
                d.reminded[id] = 1
                local msg = string.format(L("Rappel : %s commence dans %d min."), e.title or "?", mins)
                Say(msg)
                if RaidNotice_AddMessage and RaidWarningFrame then RaidNotice_AddMessage(RaidWarningFrame, msg, { r = 0.81, g = 0.1, b = 0.09 }) end
                if PlaySound and SOUNDKIT and SOUNDKIT.RAID_WARNING then pcall(PlaySound, SOUNDKIT.RAID_WARNING, "Master") end
                if e.by == Me() then ShowInviteToast(e, mins) end
            elseif left <= 0 and left > -600 and r < 2 then
                d.reminded[id] = 2
                Say(string.format(L("%s commence maintenant."), e.title or "?"))
                if e.by == Me() then ShowInviteToast(e, nil) end
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
                local t, w = e.title or "?", When(e.when, true)
                if count == 0 then Say(string.format(L("Tu organises %s, %s. Personne n'est encore inscrit."), t, w))
                elseif count == 1 then Say(string.format(L("Tu organises %s, %s : 1 inscrit."), t, w))
                else Say(string.format(L("Tu organises %s, %s : %d inscrits."), t, w, count)) end
            elseif e.signups and e.signups[Me()] then
                Say(string.format(L("Tu es inscrit à %s, %s."), e.title or "?", When(e.when, true)))
            end
        end
    end
end

-- ---------------------------------------------------------------- the window
-- "Groupes" / "LFG": 520 wide (one column), sized to its content (f:FitHeight); lists scroll inside
-- the window only once it reached 80 % of the screen. Three tabs: Agenda, Create, Group now.
local W, PAD = 520, 16
local CW = W - 2 * PAD          -- content width
local LBL = S.F.meta + 2 + 4    -- a field label (11 px) and its 4 px gap
local F = S.F
local win, tabs, current = nil, nil, "upcoming"
local pages, ui = {}, {}
local draft = { day = 0, tank = 1, heal = 1, dps = 3 }

local function Num(v) return type(v) == "number" and not (root.IsSecret and root.IsSecret(v)) and v or nil end
local function TextW(fs) return root.TextWidth(fs) end
local function Place(obj, x, y)
    obj:ClearAllPoints(); obj:SetPoint("TOPLEFT", x, -y)
end
local function FieldLabel(parent, text)
    local t = S.Text(parent, F.meta, C.muted)
    t:SetWordWrap(false); t:SetText(text)
    return t
end

-- A pooled list inside a scroll area: l.Get(i) gives the i-th item (made by `make` once).
local function List(parent, make)
    local sa = S.ScrollArea(parent)
    local l = { sa = sa, content = sa.child, items = {} }
    function l.Get(i) local f = l.items[i]; if not f then f = make(sa.child); l.items[i] = f end; f:Show(); return f end
    function l.HideFrom(i) for j = i, #l.items do l.items[j]:Hide() end end
    return l
end
-- Anchors a list under the fixed part of a page (y from the page top) down to the page bottom.
local function PlaceList(l, page, y)
    l.sa:ClearAllPoints()
    l.sa:SetPoint("TOPLEFT", page, "TOPLEFT", PAD, -y)
    l.sa:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -PAD, 12)
    l.sa.child:SetWidth(CW)
end

-- A settings row: label 13 on the left, switch on the right, a description on a second line.
-- The whole row is the click target.
local function SettingRow(parent, label, desc, get, set, noRule)
    local r = CreateFrame("Button", nil, parent)
    r.wlOwned = true
    if not noRule then r.rule = S.Rule(r); r.rule:SetPoint("TOPLEFT"); r.rule:SetPoint("TOPRIGHT") end
    r.label = S.Text(r, F.body, C.fg)
    r.desc = S.Text(r, F.meta, C.muted)
    r.label:SetText(label); r.desc:SetText(desc or "")
    r.switch = S.Switch(r, get, set)
    r.switch:SetPoint("TOPRIGHT", 0, -8)
    r.switch:AttachRow(r)
    function r:Fit(w)
        self:SetWidth(w)
        local textW = w - 40 - 12
        Place(self.label, 0, 8)
        local lh = S.FitText(self.label, 2, textW, self)
        local h = 8 + math.max(lh, 16)
        if desc then
            Place(self.desc, 0, 8 + lh + 3)
            h = 8 + lh + 3 + S.FitText(self.desc, 0, textW, self)
        end
        h = math.max(36, math.ceil(h + 8))
        self:SetHeight(h)
        return h
    end
    return r
end

local function SignupsText(n)
    if n == 0 then return L("aucun inscrit pour l'instant") end
    if n == 1 then return L("1 inscrit") end
    return string.format(L("%d inscrits"), n)
end

-- the dungeons and raids of the guide, for the "What" picker: { { key, name, lvlFrom, lvlTo } }
local function Instances(kind)
    local out = {}
    for _, k in ipairs(root.ORDER or {}) do
        local d = root.D and root.D[k]
        if d and not d.cq and ((kind == "raid") == (d.raid == true)) then
            local lo = d.lvl and d.lvl[1] or 0
            out[#out + 1] = { k, root.DName and root.DName(k) or d.n, lo, d.lvl and d.lvl[2] or lo }
        end
    end
    table.sort(out, function(a, b) if a[3] ~= b[3] then return a[3] < b[3] end return a[2] < b[2] end)
    return out
end
-- the painted icon of the event: the first dungeon or raid of its name, else the guild's banner
local function EventIcon(title)
    local first = tostring(title or ""):match("^(.-)%s+%+%s+") or tostring(title or "")
    for _, kind in ipairs({ "dg", "raid" }) do
        for _, e in ipairs(Instances(kind)) do
            if e[2] == first then
                local d = root.D and root.D[e[1]]
                if d and d.icon then return d.icon end
            end
        end
    end
    return "Interface\\Icons\\Ability_Warrior_BattleShout"
end

-- ---------------------------------------------------------------- the event card
local function EventCard(parent)
    local c = CreateFrame("Frame", nil, parent)
    c.wlOwned = true
    c:SetWidth(CW)
    S.Solid(c, "BACKGROUND", C.cardFill):SetAllPoints()
    S.Border(c, C.cardEdge)
    c.iconFrame = CreateFrame("Frame", nil, c)
    c.iconFrame:SetSize(32, 32); c.iconFrame:SetPoint("TOPLEFT", 12, -12)
    c.icon = c.iconFrame:CreateTexture(nil, "ARTWORK"); c.icon:SetAllPoints()
    S.Border(c.iconFrame, C.cardEdge)
    c.title = S.Text(c, F.heading, C.fg)
    c.pill = S.Pill(c)
    c.meta = S.Text(c, F.meta, C.muted)
    c.roles = S.Text(c, F.label, C.text)
    c.who = S.Text(c, F.meta, C.muted)
    c.note = S.Text(c, F.label, C.text)
    -- signing up is one segmented choice: no role yet, or the role you came with (a click changes it)
    local opts = {}
    for _, role in ipairs(ROLES) do opts[#opts + 1] = { role, RoleText(role, 14) } end
    c.seg = S.Segmented(c, opts, function() local m = c.e and WP.MySignup(c.e); return m and m.role end,
        function(v) if c.e then WP.SignUp(c.e, v) end end, 24)
    local segTips = { L("Clic : t'inscrire comme tank"), L("Clic : t'inscrire comme soigneur"), L("Clic : t'inscrire comme DPS") }
    for i, b in ipairs(c.seg.buttons) do b.tip = { L(ROLE_LABEL[ROLES[i]]), segTips[i] } end
    c.out = S.Button(c, L("Me désinscrire"), 0, 24, "secondary", function() if c.e then WP.SignUp(c.e, nil) end end)
    c.invite = S.Button(c, L("Inviter les inscrits"), 0, 24, "secondary", function(self)
        if not c.e then return end
        WP.InviteSignups(c.e)
        self:Flash(L("Invitations envoyées"))
    end)
    c.invite:SetIcon("group")
    -- cancel in two clicks: the first asks (the label becomes the confirmation), the second cancels
    c.cancel = S.Button(c, L("Annuler l'événement"), 0, 24, "danger", function() if c.e then WP.CancelEvent(c.e) end end)
    c.cancel:SetIcon("trash")
    c.cancel:SetConfirm(L("Confirmer l'annulation"))
    function c:Fit()
        local pad, w = 12, CW
        local x = pad + 32 + 8
        local textW = w - x - pad
        local pillW = self.pill:IsShown() and ((Num(self.pill:GetWidth()) or 0) + 8) or 0
        self.pill:ClearAllPoints(); self.pill:SetPoint("TOPRIGHT", -pad, -pad)
        Place(self.title, x, pad)
        local th = S.FitText(self.title, 2, textW - pillW, self)
        Place(self.meta, x, pad + th + 3)
        local mh = S.FitText(self.meta, 2, textW, self)
        local y = pad + math.max(32, th + 3 + mh) + 8
        Place(self.roles, pad, y)
        y = y + S.FitText(self.roles, 2, w - 2 * pad, self)
        if self.who:IsShown() then
            y = y + 4; Place(self.who, pad, y)
            y = y + S.FitText(self.who, 0, w - 2 * pad, self)
        end
        if self.note:IsShown() then
            y = y + 6; Place(self.note, pad, y)
            y = y + S.FitText(self.note, 0, w - 2 * pad, self)
        end
        if self.seg:IsShown() then
            y = y + 12; Place(self.seg, pad, y)
            self.out:ClearAllPoints(); self.out:SetPoint("LEFT", self.seg, "RIGHT", 8, 0)
            y = y + 24
        end
        if self.invite:IsShown() then
            y = y + 8; Place(self.invite, pad, y)
            self.cancel:ClearAllPoints(); self.cancel:SetPoint("LEFT", self.invite, "RIGHT", 8, 0)
            y = y + 24
        end
        local h = math.ceil(y + pad)
        self:SetHeight(h)
        return h
    end
    return c
end

local function PaintEvent(c, e)
    -- the card shows another event now: a pending "Confirm cancel" does not follow
    if c.e ~= e then c.cancel:Disarm() end
    c.e = e
    local cancelled = e.status ~= "open"
    local mine = WP.MySignup(e)
    local organizer = e.by == Me()
    S.Painted(c.icon, EventIcon(e.title))
    if c.icon.SetDesaturated then pcall(c.icon.SetDesaturated, c.icon, cancelled) end
    c.title:SetText(e.title or "?")
    local tc = cancelled and C.muted or C.fg
    c.title:SetTextColor(tc[1], tc[2], tc[3])
    if cancelled then c.pill:Set(L("Annulé"), C.bad)
    elseif organizer then c.pill:Set(L("Organisateur"))
    elseif mine then c.pill:Set(L("Inscrit"), C.ok, "check")
    else c.pill:Hide() end
    local count = CountSignups(e)
    -- the organizer reads "Organisateur" in the pill: the meta line does not say it again
    if organizer then
        c.meta:SetText(When(e.when) .. "  ·  " .. SignupsText(count))
    else
        c.meta:SetText(When(e.when) .. "  ·  " .. string.format(L("par %s"), e.by or "?") .. "  ·  " .. SignupsText(count))
    end
    -- places per role: 2/3, "complet" when full, "+1 en réserve" when more came than asked
    local n = WP.EventCounts(e)
    local parts = {}
    for _, role in ipairs(ROLES) do
        local want = e[role] or 0
        if want == 0 and n[role] > 0 then
            -- no slot asked for this role: the ones who came anyway are a reserve
            parts[#parts + 1] = S.RoleMarkup(role, 14) .. " " .. S.Hex(C.warn) .. string.format(L("+%d en réserve"), n[role]) .. "|r"
        elseif want > 0 then
            local full = want > 0 and n[role] >= want
            local s = S.RoleMarkup(role, 14) .. " " .. (full and S.Hex(C.ok) or "") .. n[role] .. "/" .. want
            if want > 0 and n[role] == want then s = s .. " " .. L("complet") end
            if full then s = s .. "|r" end
            if want > 0 and n[role] > want then s = s .. " " .. S.Hex(C.warn) .. string.format(L("+%d en réserve"), n[role] - want) .. "|r" end
            parts[#parts + 1] = s
        end
    end
    c.roles:SetText(table.concat(parts, "     "))
    local names = {}
    for name, s in pairs(e.signups or {}) do names[#names + 1] = { name, s } end
    table.sort(names, function(a, b) return a[1] < b[1] end)
    local t = {}
    for _, p in ipairs(names) do t[#t + 1] = S.RoleMarkup(p[2].role, 12) .. " " .. ClassHex(p[2].cls) .. p[1] .. "|r" end
    c.who:SetText(table.concat(t, "   ")); c.who:SetShown(#t > 0)
    c.note:SetText(e.note or ""); c.note:SetShown((e.note or "") ~= "")
    -- sign up / change role / step out; the organizer invites or cancels
    c.seg:SetShown(not cancelled); c.seg:Update()
    c.out:SetShown(not cancelled and mine ~= nil)
    local org = organizer and not cancelled
    c.invite:SetShown(org); c.cancel:SetShown(org)
    if org then
        -- the main action only when it is time to invite (30 min around the start)
        c.invite:SetKind(math.abs((e.when or 0) - time()) <= 1800 and "primary" or "secondary")
        local others = count - (mine and 1 or 0)
        if others > 0 then
            c.invite:Enable(); c.invite:SetDisabledReason(nil)
        else
            c.invite:Disable(); c.invite:SetDisabledReason(L("Personne d'autre n'est inscrit pour l'instant."))
        end
    end
    return c:Fit()
end

local function Whisper(name)
    if ChatFrame_OpenChat then ChatFrame_OpenChat("/w " .. name .. " ")
    elseif ChatFrameUtil and ChatFrameUtil.OpenChat then ChatFrameUtil.OpenChat("/w " .. name .. " ") end
end

local function AgoText(t)
    local mins = math.max(0, math.floor((time() - (t or time())) / 60))
    if mins < 1 then return L("à l'instant") end
    return string.format(L("il y a %d min"), mins)
end

-- A member looking for a group: class icon, name; what for (wraps, the row grows); role, level and
-- since when on the last line. Whisper and Invite on the right.
local function LookRow(parent)
    local r = CreateFrame("Button", nil, parent)
    r.wlOwned = true
    r:SetWidth(CW)
    r:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    r.bg = S.Solid(r, "BACKGROUND", C.cardFill); r.bg:SetAllPoints()
    r.hl = S.Solid(r, "BORDER", C.hoverFill); r.hl:SetAllPoints(); r.hl:SetAlpha(0)
    r.press = S.Solid(r, "BORDER", C.pressFill); r.press:SetAllPoints(); r.press:Hide()
    r.cls = r:CreateTexture(nil, "ARTWORK"); r.cls:SetSize(20, 20); r.cls:SetPoint("TOPLEFT", 8, -8)
    r.name = S.Text(r, F.label, C.fg)
    r.what = S.Text(r, F.label, C.text)
    r.detail = S.Text(r, F.meta, C.muted)
    r.inv = S.Button(r, L("Inviter"), 0, 24, "secondary", function(self)
        if r.who then InviteName(r.who); self:Flash(L("Invité")) end
    end)
    r.inv:SetIcon("plus")
    r.whisper = S.Button(r, L("Chuchoter"), 0, 24, "secondary", function() if r.who then Whisper(r.who) end end)
    local function Hover(on)
        root.Tween(r, r.hov or 0, on and 1 or 0, 0.10, function(v) r.hov = v; r.hl:SetAlpha(v) end)
    end
    r:SetScript("OnClick", function(self, button)
        local who = self.who
        if not who or who == Me() then return end
        if button == "RightButton" or IsAltKeyDown() then InviteName(who); r.inv:Flash(L("Invité")) else Whisper(who) end
    end)
    r:SetScript("OnEnter", function(self)
        Hover(true)
        if not self.l then return end
        local l = self.l
        local c = RAID_CLASS_COLORS and l.cls and RAID_CLASS_COLORS[l.cls]
        local lines = { c and { l.name, c.r, c.g, c.b } or l.name }
        lines[#lines + 1] = string.format(L("%s, niveau %s"), L(ROLE_LABEL[l.role] or "DPS"), l.lvl or "?")
        lines[#lines + 1] = (l.what and l.what ~= "") and string.format(L("Pour : %s"), l.what) or L("Pour n'importe quel groupe")
        if l.name ~= Me() then
            lines[#lines + 1] = L("Clic : chuchoter")
            lines[#lines + 1] = L("Clic droit : inviter dans ton groupe")
        end
        S.Tip(self, lines)
    end)
    r:SetScript("OnLeave", function() Hover(false); S.HideTip() end)
    r:SetScript("OnMouseDown", function(self) self.press:Show() end)
    r:SetScript("OnMouseUp", function(self) self.press:Hide() end)
    local function Out() if not r:IsMouseOver() then Hover(false) end end
    r.inv:HookScript("OnEnter", function() Hover(true) end)
    r.whisper:HookScript("OnEnter", function() Hover(true) end)
    r.inv:HookScript("OnLeave", Out)
    r.whisper:HookScript("OnLeave", Out)
    function r:Fit()
        local right = 12
        if self.inv:IsShown() then
            self.inv:ClearAllPoints(); self.inv:SetPoint("RIGHT", -12, 0)
            self.whisper:ClearAllPoints(); self.whisper:SetPoint("RIGHT", self.inv, "LEFT", -8, 0)
            right = 12 + (Num(self.inv:GetWidth()) or 72) + 8 + (Num(self.whisper:GetWidth()) or 84) + 12
        end
        local textW = math.max(60, CW - 36 - right)
        Place(self.name, 36, 6)
        local nh = math.max(F.label, S.FitText(self.name, 1, textW, self))
        local y = 6 + nh + 3
        Place(self.what, 36, y)
        y = y + S.FitText(self.what, 0, textW, self) + 3
        Place(self.detail, 36, y)
        y = y + S.FitText(self.detail, 0, textW, self)
        local h = math.max(36, math.ceil(y + 8))
        self:SetHeight(h)
        return h
    end
    return r
end

-- ---------------------------------------------------------------- Agenda
local function RenderUpcoming()
    local p = pages.upcoming
    local list = WP.EventList()
    if #list == 0 then
        ui.events.sa:Hide()
        ui.noEvents:Show()
        ui.noEvents:ClearAllPoints(); ui.noEvents:SetPoint("TOP", p, "TOPLEFT", W / 2, -24)
        win:FitHeight(12 + ui.noEvents:Fit())
        return
    end
    ui.noEvents:Hide(); ui.events.sa:Show()
    local y = 0
    for i, e in ipairs(list) do
        local c = ui.events.Get(i)
        local h = PaintEvent(c, e)
        Place(c, 0, y)
        y = y + h + 12
    end
    ui.events.HideFrom(#list + 1)
    -- the organizer's invite, accepted by itself: a setting that belongs right under the list
    ui.autoRow.switch:Update()
    Place(ui.autoRow, 0, y)
    y = y + ui.autoRow:Fit(CW)
    PlaceList(ui.events, p, 12)
    ui.events.sa:SetContentHeight(y)
    win:FitHeight(y)
end

-- ---------------------------------------------------------------- Group now
local function RenderNow()
    local p = pages.now
    ui.lookRow.switch:Update()
    ui.lookSeg:Update()
    local y = 12
    Place(ui.lookRow, PAD, y)
    y = y + ui.lookRow:Fit(CW) + 12
    Place(ui.roleLabel, PAD, y); y = y + LBL
    Place(ui.lookSeg, PAD, y); y = y + 28 + 12
    y = y + LBL
    Place(ui.what, PAD, y); y = y + 28 + 16
    local list = WP.LFGList()
    -- the header names the list; with nobody in it, the empty state alone says so
    ui.lookHead:SetShown(#list > 0)
    if #list > 0 then
        ui.lookHead:SetWidth(CW)
        ui.lookHead:Set(L("Membres qui cherchent un groupe"), #list)
        Place(ui.lookHead, PAD, y); y = y + 32 + 8
    end
    local listH = 0
    for i, l in ipairs(list) do
        local r = ui.looking.Get(i)
        r.who, r.l = l.name, l
        if not S.ClassIcon(r.cls, l.cls) then r.cls:Hide() else r.cls:Show() end
        r.name:SetText(ClassHex(l.cls) .. l.name .. "|r" .. (l.name == Me() and (" " .. S.Hex(C.muted) .. L("(toi)") .. "|r") or ""))
        r.what:SetText((l.what and l.what ~= "") and string.format(L("Pour : %s"), l.what) or L("Pour n'importe quel groupe"))
        r.detail:SetText(RoleText(l.role, 12) .. "  ·  " .. string.format(L("niveau %s"), l.lvl or "?") .. "  ·  " .. AgoText(l.t))
        local other = l.name ~= Me()
        r.whisper:SetShown(other); r.inv:SetShown(other)
        local h = r:Fit()
        Place(r, 0, listH)
        listH = listH + h + 2
    end
    ui.looking.HideFrom(#list + 1)
    if #list > 0 then listH = listH - 2 end
    ui.noLooking:SetShown(#list == 0)
    if #list == 0 then
        ui.noLooking:ClearAllPoints(); ui.noLooking:SetPoint("TOP", p, "TOPLEFT", W / 2, -(y + 4))
        PlaceList(ui.looking, p, y)
        ui.looking.sa:SetContentHeight(0)
        win:FitHeight(y - 12 + 4 + ui.noLooking:Fit())
        return
    end
    PlaceList(ui.looking, p, y)
    ui.looking.sa:SetContentHeight(listH)
    win:FitHeight(y - 12 + listH)
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

local picked = {}
-- the names picked, in level order
local function PickedNames()
    local t = {}
    for _, e in ipairs(Instances(draft.kind == "raid" and "raid" or "dg")) do if picked[e[1]] then t[#t + 1] = e[2] end end
    return t
end
local function PickedTitle() return table.concat(PickedNames(), " + ") end

-- "Maraudon, Zul'Farrak" on one line; the names that do not fit become "(+2)", never a cut name
local function FitNames(fs, names, maxW)
    local measure = function(x) return root.TextWidth(x) end
    fs:SetWidth(maxW); fs:SetWordWrap(false)
    for i = #names, 1, -1 do
        local s = table.concat(names, ", ", 1, i)
        if i < #names then s = s .. "  " .. string.format(L("(+%d)"), #names - i) end
        fs:SetText(s)
        if (measure(fs) or 0) <= maxW then return end
    end
    -- even the first name alone is too long: shorten the name ourselves so the "(+n)" count stays seen
    local suffix = #names > 1 and ("  " .. string.format(L("(+%d)"), #names - 1)) or ""
    local name = names[1]
    while #name > 1 do
        -- drop the last UTF-8 character (its continuation bytes too)
        local cut = #name
        while cut > 1 and name:byte(cut) >= 0x80 and name:byte(cut) < 0xC0 do cut = cut - 1 end
        name = (name:sub(1, cut - 1):gsub("[%s,:%-]+$", ""))
        fs:SetText(name .. "..." .. suffix)
        if (measure(fs) or 0) <= maxW then return end
    end
    fs:SetText(names[1] .. suffix)
end

-- a card name on one line, never cut: 13 px, else 12, else 11 (then the full name is in the tooltip)
local function FitCardName(fs, text, maxW)
    local measure = function(x) return root.TextWidth(x) end
    local canSize = root.SetFont and fs._size ~= nil
    for _, size in ipairs({ 13, 12, 11 }) do
        if canSize then fs._size = size; root.SetFont(fs) end
        fs:SetText(text)
        if not canSize or (measure(fs) or 0) <= maxW then return end
    end
end

-- ---------------------------------------------------------------- the dungeon / raid picker
-- Cards with the loading-screen art of the guide's picker, two columns, several can be ticked.
-- The choice is kept aside (sel) until the main button: closing the window changes nothing.
local PGAP = 8
local PCW = math.floor((CW - PGAP) / 2)   -- two cards across the content width
local PCH = 88
local picker
local sel = {}

local function PaintPickCard(c)
    local on = sel[c.key] and true or false
    c.edge(on and C.accent or C.cardEdge, 1)
    c.tint:SetShown(on)
    c.checkBg:SetShown(on); c.check:SetShown(on)
end

local function PickCard(parent)
    local c = CreateFrame("Button", nil, parent)
    c.wlOwned = true
    c:SetSize(PCW, PCH)
    c.art = c:CreateTexture(nil, "BACKGROUND")
    c.art:SetPoint("TOPLEFT", 1, -1); c.art:SetPoint("BOTTOMRIGHT", -1, 1)
    -- the dungeon's icon on a dark card when the client has no picture for it
    c.icon = c:CreateTexture(nil, "ARTWORK")
    c.icon:SetSize(40, 40); c.icon:SetPoint("CENTER", 0, 12); c.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92); c.icon:Hide()
    c.tint = S.Solid(c, "ARTWORK", C.selFill)
    c.tint:SetPoint("TOPLEFT", 1, -1); c.tint:SetPoint("BOTTOMRIGHT", -1, 1); c.tint:Hide()
    -- a dark band under the name, so the text reads on any picture
    local shade = S.Solid(c, "BORDER", { 0, 0, 0 }, 0.62)
    shade:SetPoint("BOTTOMLEFT", 1, 1); shade:SetPoint("BOTTOMRIGHT", -1, 1); shade:SetHeight(40)
    c.name = S.Text(c, F.body, C.fg)
    c.name:SetPoint("BOTTOMLEFT", 10, 21); c.name:SetWidth(PCW - 20)
    S.ClampLabel(c.name, nil, c)
    c.lv = S.Text(c, F.meta, C.muted)
    c.lv:SetPoint("BOTTOMLEFT", 10, 6); c.lv:SetWidth(PCW - 20); c.lv:SetWordWrap(false)
    c.hl = S.Solid(c, "HIGHLIGHT", C.hoverFill)
    c.hl:SetPoint("TOPLEFT", 1, -1); c.hl:SetPoint("BOTTOMRIGHT", -1, 1)
    c.press = S.Solid(c, "OVERLAY", C.pressFill)
    c.press:SetPoint("TOPLEFT", 1, -1); c.press:SetPoint("BOTTOMRIGHT", -1, 1); c.press:Hide()
    c.edge = S.Border(c, C.cardEdge)
    -- ticked: the accent edge, the selection fill and a check in the corner
    c.checkBg = S.Solid(c, "OVERLAY", C.accent)
    c.checkBg:SetSize(20, 20); c.checkBg:SetPoint("TOPRIGHT", -6, -6)
    c.check = S.Icon(c, "check", 16, "OVERLAY", C.fg)
    c.check:SetDrawLayer("OVERLAY", 2)
    c.check:SetPoint("CENTER", c.checkBg, "CENTER", 0, 0)
    c:SetScript("OnClick", function(self)
        sel[self.key] = not sel[self.key] or nil
        PaintPickCard(self)
        if picker then picker.UpdateOk() end
        if self:IsMouseOver() and self:GetScript("OnEnter") then self:GetScript("OnEnter")(self) end
    end)
    c:SetScript("OnMouseDown", function(self) self.press:Show() end)
    c:SetScript("OnMouseUp", function(self) self.press:Hide() end)
    c:SetScript("OnEnter", function(self)
        S.Tip(self, { self.fullName or "", self.lvText or nil,
            sel[self.key] and L("Clic : décocher") or L("Clic : cocher") })
    end)
    c:SetScript("OnLeave", S.HideTip)
    return c
end

local function BuildPicker()
    local f = S.Window("WLHelperEventsPicker", W, 420, L("Choisir les donjons"), nil, nil, nil,
        { header = S.HEADER_H, minH = 240, strata = "DIALOG", noHome = true })
    f:EnableMouse(true)
    f.hint = S.Text(f, F.label, C.muted)
    f.hint:SetText(L("Tu peux en cocher plusieurs : l'événement portera tous leurs noms."))
    f.sa = S.ScrollArea(f)
    f.content = f.sa.child
    f.cards, f.heads = {}, {}
    -- the bar at the bottom: untick on the left, the main action on the right
    f.rule = S.Rule(f)
    f.rule:SetPoint("BOTTOMLEFT", 0, 12 + 28 + 12); f.rule:SetPoint("BOTTOMRIGHT", 0, 12 + 28 + 12)
    f.clear = S.Button(f, L("Tout décocher"), 0, 28, "secondary", function()
        wipe(sel)
        for _, c in ipairs(f.cards) do if c:IsShown() then PaintPickCard(c) end end
        f.UpdateOk()
    end)
    f.clear:SetPoint("BOTTOMLEFT", PAD, 12)
    f.ok = S.Button(f, L("Continuer sans donjon"), 0, 28, "primary", function()
        wipe(picked)
        for k in pairs(sel) do picked[k] = true end
        f:Hide()
        if ui.onPicked then ui.onPicked() end
    end)
    f.ok:SetPoint("BOTTOMRIGHT", -PAD, 12)
    function f.UpdateOk()
        local n = 0
        for _ in pairs(sel) do n = n + 1 end
        local raid = draft.kind == "raid"
        local label
        if n == 0 then label = raid and L("Continuer sans raid") or L("Continuer sans donjon")
        elseif n == 1 then label = raid and L("Ajouter 1 raid") or L("Ajouter 1 donjon")
        else label = string.format(raid and L("Ajouter %d raids") or L("Ajouter %d donjons"), n) end
        f.ok.label:SetText(label)
        if n > 0 then f.clear:Enable() else f.clear:Disable() end
        f.clear:SetDisabledReason(raid and L("Aucun raid coché.") or L("Aucun donjon coché."))
    end
    -- One Escape hides every shown frame of UISpecialFrames, so while the picker is up the Events
    -- window leaves that list: Escape closes the picker only, the form stays open.
    local WIN = "WLHelperEvents"
    local function Unlist()
        for k = #UISpecialFrames, 1, -1 do
            if UISpecialFrames[k] == WIN then table.remove(UISpecialFrames, k) end
        end
    end
    local function Relist()
        if f:IsVisible() then return end
        for _, v in ipairs(UISpecialFrames) do if v == WIN then return end end
        tinsert(UISpecialFrames, WIN)
    end
    f:SetScript("OnShow", Unlist)
    -- put back one frame later: CloseSpecialWindows is still walking the list when the picker hides,
    -- and a name added during that walk could be hidden by the same Escape
    f:SetScript("OnHide", function()
        if C_Timer and C_Timer.After then C_Timer.After(0, Relist) else Relist() end
    end)
    f:Hide()
    return f
end

-- opens the picker on the kind of the form (dungeons or raids), the current choice already ticked
function WP.OpenEventPicker()
    if not (pages.create and (draft.kind == "dg" or draft.kind == "raid")) then return end
    picker = picker or BuildPicker()
    local raid = draft.kind == "raid"
    picker.title:SetText(raid and L("Choisir les raids") or L("Choisir les donjons"))
    wipe(sel)
    for k in pairs(picked) do sel[k] = true end
    -- the ones for your level first, then the others; each part by level
    local lv = UnitLevel("player") or 1
    local mine, rest = {}, {}
    for _, e in ipairs(Instances(raid and "raid" or "dg")) do
        local ok = lv >= e[3] - 4 and lv <= e[4] + 1
        if ok then mine[#mine + 1] = e else rest[#rest + 1] = e end
    end
    local parts
    if #mine > 0 and #rest > 0 then
        parts = { { L("Pour ton niveau"), mine }, { L("Autres niveaux"), rest } }
    else
        parts = { { nil, #mine > 0 and mine or rest } }
    end
    for _, c in ipairs(picker.cards) do c:Hide() end
    for _, h in ipairs(picker.heads) do h:Hide() end
    local y, i, hi = 0, 0, 0
    for pi, part in ipairs(parts) do
        if part[1] then
            hi = hi + 1
            local h = picker.heads[hi]
            if not h then h = S.SectionHeader(picker.content, "", nil, nil, nil, true); picker.heads[hi] = h end
            h:SetWidth(CW)
            if pi > 1 then y = y + 8 end
            Place(h, 0, y)
            h:Set(part[1], #part[2]); h:Show()
            y = y + 24 + 8
        end
        for j, e in ipairs(part[2]) do
            i = i + 1
            local c = picker.cards[i] or PickCard(picker.content); picker.cards[i] = c
            local col, row = (j - 1) % 2, math.floor((j - 1) / 2)
            Place(c, col * (PCW + PGAP), y + row * (PCH + PGAP))
            c.key = e[1]
            if root.DungeonArt then
                root.DungeonArt(c.art, e[1], c.icon)
            else
                c.art:SetColorTexture(0.10, 0.11, 0.13, 1)
            end
            c.fullName = e[2]
            FitCardName(c.name, e[2], PCW - 20)
            c.lvText = string.format(L("niveau %s"), e[3] == e[4] and tostring(e[3]) or (e[3] .. "-" .. e[4]))
            c.lv:SetText(c.lvText)
            PaintPickCard(c)
            c:Show()
        end
        y = y + math.ceil(#part[2] / 2) * (PCH + PGAP) - PGAP
    end
    -- the window: hint, the grid (scrolls past the height cap), the bar
    local top = S.HEADER_H + 1 + 12
    Place(picker.hint, PAD, top)
    local hh = S.FitText(picker.hint, 2, CW, picker)
    local gridTop = top + hh + 12
    local barH = 12 + 1 + 12 + 28
    picker.sa:ClearAllPoints()
    picker.sa:SetPoint("TOPLEFT", picker, "TOPLEFT", PAD, -gridTop)
    picker.sa:SetPoint("BOTTOMRIGHT", picker, "BOTTOMRIGHT", -PAD, barH + 12)
    picker.content:SetWidth(CW)
    picker.sa:SetContentHeight(y)
    picker.UpdateOk()
    if win then picker:ClearAllPoints(); picker:SetPoint("TOP", win, "TOP", 0, -24) end
    picker:Show(); picker:Raise()
    picker:FitHeight(hh + 12 + y + barH)
    picker.sa:ScrollTo(0, true)
    return picker
end

-- ---------------------------------------------------------------- Create
-- "21:00", "21h30", "9:00 PM", "9pm" -> hour, minute (nil when it cannot be read)
local function ParseHour(text)
    local s = tostring(text or ""):lower():gsub("%s+", "")
    local ampm = s:match("([ap])%.?m%.?$")
    if ampm then s = s:gsub("[ap]%.?m%.?$", "") end
    local hh, mm = s:match("^(%d%d?)[:h%.]?(%d?%d?)$")
    hh, mm = tonumber(hh), tonumber(mm ~= "" and mm or "0")
    if not hh or not mm or mm > 59 then return nil end
    if ampm then
        if hh < 1 or hh > 12 then return nil end
        if ampm == "p" and hh < 12 then hh = hh + 12 elseif ampm == "a" and hh == 12 then hh = 0 end
    end
    if hh > 23 then return nil end
    return hh, mm
end

local PLACEHOLDER = { dg = "Ex. Zul'Farrak", raid = "Ex. Onyxia", quest = "Ex. quêtes des Maleterres", other = "Ex. farm de cuir à Feralas" }

local function BuildCreate(p)
    draft.kind = draft.kind or "dg"
    -- the places are filled by kind until the player types one: tanks, healers, damage
    local PRESET = { raid = { 3, 8, 29 }, dg = { 1, 1, 3 }, quest = { 0, 0, 5 }, other = { 0, 0, 5 } }
    local placesTouched = false
    local function ParseWhen()
        local hh, mm = ParseHour(ui.hour:GetText())
        if not hh then return nil end
        return DayStart(time()) + draft.day * 86400 + hh * 3600 + mm * 60
    end
    local function Relayout()
        if current == "create" and win and win:IsShown() and ui.LayoutCreate then win:FitHeight(ui.LayoutCreate()) end
    end
    -- what will be published, read back above the button
    local function Recap()
        if not (ui.recap and ui.title and ui.hour) then return end
        local title = ui.title:GetText() or ""
        local when = ParseWhen()
        if title:gsub("%s", "") ~= "" and when then
            ui.recap:SetText(string.format(L("Sera publié : %s, %s."), title, When(when, true)))
        else
            ui.recap:SetText("")
        end
    end
    -- the kind
    ui.kindLabel = FieldLabel(p, L("Type"))
    -- dungeon or raid: one button opens the picker with the pictures
    ui.pick = S.Button(p, "", CW, 32, "secondary", function() WP.OpenEventPicker() end, function()
        local names = PickedNames()
        local lines = { draft.kind == "raid" and L("Choisir les raids") or L("Choisir les donjons") }
        for _, n in ipairs(names) do lines[#lines + 1] = n end
        lines[#lines + 1] = draft.kind == "raid" and L("Clic : choisir les raids") or L("Clic : choisir les donjons")
        return lines
    end)
    ui.pick.thing = ui.pick.content:CreateTexture(nil, "ARTWORK")
    ui.pick.thing:SetSize(20, 20); ui.pick.thing:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    ui.pick.next = S.Icon(ui.pick.content, "chevron_right", 16, "ARTWORK", C.muted)
    ui.pick.label:SetJustifyH("LEFT")
    function ui.pick:CustomLayout(dy)
        self.thing:ClearAllPoints(); self.thing:SetPoint("LEFT", self.content, "LEFT", 8, dy)
        self.next:ClearAllPoints(); self.next:SetPoint("RIGHT", self.content, "RIGHT", -10, dy)
        self.label:ClearAllPoints(); self.label:SetPoint("LEFT", self.content, "LEFT", 36, dy)
    end
    ui.pick:Fit()
    local function PickUpdate()
        local inst = draft.kind == "dg" or draft.kind == "raid"
        ui.pick:SetShown(inst)
        if not inst then return end
        local names = PickedNames()
        local lb = ui.pick.label
        if #names == 0 then
            lb:SetWidth(CW - 36 - 34); lb:SetWordWrap(false)
            lb:SetText(draft.kind == "raid" and L("Choisir les raids") or L("Choisir les donjons"))
            S.Painted(ui.pick.thing, draft.kind == "raid" and "Interface\\Icons\\INV_Misc_Head_Dragon_01" or "Interface\\Icons\\INV_Misc_Map_01")
        else
            FitNames(lb, names, CW - 36 - 34)
            local first
            for _, e in ipairs(Instances(draft.kind)) do if picked[e[1]] then first = e[1]; break end end
            local d = first and root.D and root.D[first]
            S.Painted(ui.pick.thing, d and d.icon or "Interface\\Icons\\INV_Misc_Map_01")
        end
    end
    -- the picker's main button: the title from the names. "Continue without" keeps a name the player
    -- typed; it only empties a name that an earlier pick built.
    local lastBuilt = ""
    ui.onPicked = function()
        local t = PickedTitle()
        local cur = ui.title:GetText() or ""
        if t ~= "" or cur == "" or cur == lastBuilt then ui.title:SetText(t) end
        lastBuilt = t
        ui.title:SetError(nil)
        PickUpdate()
        Recap()
        Relayout()
    end
    ui.kind = S.Segmented(p, { { "dg", L("Donjon") }, { "raid", L("Raid") }, { "quest", L("Quête") }, { "other", L("Autre") } },
        function() return draft.kind end, function(v)
            draft.kind = v; wipe(picked); ui.title:SetText(""); lastBuilt = ""
            ui.title:SetPlaceholder(L(PLACEHOLDER[v]))
            if picker then picker:Hide() end
            PickUpdate()
            if not placesTouched and PRESET[v] then
                for i, role in ipairs(ROLES) do
                    draft[role] = PRESET[v][i]
                    if ui["n_" .. role] then ui["n_" .. role]:SetText(tostring(PRESET[v][i])) end
                end
            end
            Recap()
            Relayout()
        end, 28)
    -- the name
    ui.title = S.Input(p, CW, { label = L("Nom de l'événement"), placeholder = L(PLACEHOLDER[draft.kind]),
        onChange = function() ui.title:SetError(nil); Recap(); Relayout() end })
    ui.title:SetMaxLetters(60)
    -- the day
    ui.dayLabel = FieldLabel(p, L("Jour"))
    local function DaySet(v) draft.day = v; ui.hour:SetError(nil); Recap(); Relayout() end
    -- built again after midnight (WP.RefreshEvents): "Demain" picked yesterday is "Aujourd'hui" now
    function ui.MakeDay()
        local today = DayStart(time())
        if ui.dayBuiltFor and ui.dayBuiltFor ~= today then
            draft.day = math.max(0, draft.day - math.floor((today - ui.dayBuiltFor) / 86400 + 0.5))
        end
        ui.dayBuiltFor = today
        if ui.day then ui.day:Hide() end
        ui.day = S.Segmented(p, DayChoices(), function() return draft.day end, DaySet, 28)
        if (Num(ui.day:GetWidth()) or 0) > CW then
            -- the day numbers do not fit seven times: the day names alone
            ui.day:Hide()
            ui.day = S.Segmented(p, DayChoices(true), function() return draft.day end, DaySet, 28)
        end
        ui.day:SetMaxWidth(CW)
        ui.day:Update()
    end
    ui.MakeDay()
    -- the hour, and four usual ones a click away
    ui.hour = S.Input(p, 88, { label = L("Heure"), placeholder = Clock(20, 30),
        onChange = function() ui.hour:SetError(nil); Recap(); Relayout() end })
    ui.hour:SetMaxLetters(8)
    ui.hour:SetText(Clock(21, 0))
    ui.quick = {}
    for i, hv in ipairs({ { 20, 0 }, { 20, 30 }, { 21, 0 }, { 21, 30 } }) do
        local txt = Clock(hv[1], hv[2])
        local hb = S.Button(p, txt, 52, 28, "secondary", function()
            ui.hour:SetText(txt); ui.hour:SetError(nil); Recap(); Relayout()
        end)
        if i == 1 then hb:SetPoint("LEFT", ui.hour, "RIGHT", 8, 0) else hb:SetPoint("LEFT", ui.quick[i - 1], "RIGHT", 4, 0) end
        ui.quick[i] = hb
    end
    -- the places per role
    local placeLabel = { tank = "Places tank", heal = "Places soigneur", dps = "Places DPS" }
    for _, role in ipairs(ROLES) do
        local b = S.Input(p, 56, { label = S.RoleMarkup(role, 12) .. " " .. L(placeLabel[role]),
            onChange = function() placesTouched = true end })
        b:SetNumeric(true); b:SetMaxLetters(2)
        b:SetText(tostring(draft[role]))
        ui["n_" .. role] = b
    end
    -- the note
    ui.note = S.Input(p, CW, { label = L("Note (facultatif)"), placeholder = L("Ex. niveau 45 minimum, rendez-vous à Gadgetzan") })
    ui.note:SetMaxLetters(120)
    ui.recap = S.Text(p, F.label, C.text)
    ui.go = S.Button(p, L("Publier l'événement"), 0, 32, "primary", function()
        local title = ui.title:GetText()
        local bad = false
        if not title or title:gsub("%s", "") == "" then ui.title:SetError(L("Donne un nom à l'événement, par exemple Zul'Farrak.")); bad = true end
        local when = ParseWhen()
        if not when then
            ui.hour:SetError(L("Heure invalide : écris par exemple 20:30.")); bad = true
        elseif when < time() - 60 then
            ui.hour:SetError(draft.day == 0 and L("Cette heure est déjà passée aujourd'hui : choisis Demain ou une heure plus tard.")
                or L("Cette heure est déjà passée.")); bad = true
        end
        if bad then Relayout(); return end
        local function N(role) return tonumber(ui["n_" .. role]:GetText()) or 0 end
        WP.CreateEvent(title, when, N("tank"), N("heal"), N("dps"), ui.note:GetText())
        ui.title:SetText(""); ui.note:SetText(""); wipe(picked); lastBuilt = ""; PickUpdate()
        ui.title:SetError(nil); ui.hour:SetError(nil)
        placesTouched = false
        Recap()
        WP.ShowEventsTab("upcoming")
    end)
    -- an error sentence under a narrow field spans the whole form
    local function ErrH(box)
        if not box.err:IsShown() then return 0 end
        return 4 + S.FitText(box.err, 0, CW, box)
    end
    function ui.LayoutCreate()
        local y = 12
        Place(ui.kindLabel, PAD, y); y = y + LBL
        Place(ui.kind, PAD, y); y = y + 28 + 12
        if ui.pick:IsShown() then Place(ui.pick, PAD, y); y = y + 32 + 12 end
        y = y + LBL
        Place(ui.title, PAD, y); y = y + 28 + ErrH(ui.title) + 12
        Place(ui.dayLabel, PAD, y); y = y + LBL
        Place(ui.day, PAD, y); y = y + 28 + 12
        y = y + LBL
        Place(ui.hour, PAD, y); y = y + 28 + ErrH(ui.hour) + 12
        y = y + LBL
        for i, role in ipairs(ROLES) do Place(ui["n_" .. role], PAD + (i - 1) * 132, y) end
        y = y + 28 + 12
        y = y + LBL
        Place(ui.note, PAD, y); y = y + 28 + 12
        local recap = ui.recap:GetText()
        if recap and recap ~= "" then
            ui.recap:Show()
            Place(ui.recap, PAD, y)
            y = y + S.FitText(ui.recap, 2, CW, p) + 8
        else
            ui.recap:Hide()
        end
        Place(ui.go, PAD, y); y = y + 32
        return y - 12
    end
    ui.recapNow = Recap
    PickUpdate()
    Recap()
end

-- ---------------------------------------------------------------- Group now
local function BuildNow(p)
    ui.lookRow = SettingRow(p, L("Je cherche un groupe"),
        L("Les membres qui ont WL Helper te voient dans leur liste. Ta recherche s'arrête seule quand ton groupe est complet."),
        function() return WP.IsLooking() ~= nil end,
        function(v) if v then WP.SetLooking(MyRole(), ui.what:GetText()) else WP.SetLooking(nil) end end, true)
    ui.roleLabel = FieldLabel(p, L("Mon rôle"))
    ui.lookSeg = S.Segmented(p, { { "tank", RoleText("tank", 14) }, { "heal", RoleText("heal", 14) }, { "dps", RoleText("dps", 14) } },
        function() return MyRole() end, function(v)
            WLWritsCharDB.lfgRole = v
            if WP.IsLooking() then WP.SetLooking(v, ui.what:GetText()) end
        end, 28)
    ui.what = S.Input(p, CW, { label = L("Pour quoi ?"), placeholder = L("Ex. Zul'Farrak, quêtes des Maleterres"),
        onEnter = function(text) if WP.IsLooking() then WP.SetLooking(MyRole(), text) end end })
    ui.what:SetMaxLetters(80)
    -- the text counts without Enter too (only sent when it changed)
    ui.what:HookScript("OnEditFocusLost", function(self)
        if WP.IsLooking() then
            local _, w = WP.IsLooking()
            if (w or "") ~= Clean(self:GetText(), 80) then WP.SetLooking(MyRole(), self:GetText()) end
        end
    end)
    ui.lookHead = S.SectionHeader(p, L("Membres qui cherchent un groupe"))
    ui.looking = List(p, LookRow)
    ui.noLooking = S.EmptyState(p, "group", L("Personne ne cherche de groupe"),
        L("Quand un membre allume « Je cherche un groupe », il apparaît ici avec son rôle."))
    ui.noLooking:Hide()
end

local function InfoTip()
    return { L("LFG"), L("Seuls les membres qui ont WL Helper voient les événements et les recherches de groupe."),
        L("WL Helper n'envoie jamais de message privé : tout passe par le canal de la guilde.") }
end

local function Build()
    win = S.Window("WLHelperEvents", W, 480, L("LFG"), GetGuildInfo and GetGuildInfo("player") or nil, WLWritsDB, "eventsPos",
        { header = S.HEADER_H, minH = 240 })
    win:AddHeaderButton(S.IconButton(win.header, "info", 28, InfoTip))
    tabs = S.Tabs(win, { { "upcoming", L("Agenda") }, { "create", L("Créer") }, { "now", L("Groupe maintenant") } },
        function() return current end, function(k) WP.ShowEventsTab(k) end, function(k)
            if k == "upcoming" then local n = #WP.EventList(); return n > 0 and n or nil end
            if k == "now" then local n = WP.LFGCount(true); return n > 0 and n or nil end
        end)
    tabs:SetPoint("TOPLEFT", 0, -(S.HEADER_H + 1)); tabs:SetPoint("TOPRIGHT", 0, -(S.HEADER_H + 1))
    for _, k in ipairs({ "upcoming", "create", "now" }) do
        local p = CreateFrame("Frame", nil, win)
        p:SetPoint("TOPLEFT", 0, -win:ContentTop()); p:SetPoint("BOTTOMRIGHT")
        p:Hide(); pages[k] = p
    end
    -- Agenda
    ui.events = List(pages.upcoming, EventCard)
    ui.noEvents = S.EmptyState(pages.upcoming, "calendar", L("Aucun événement prévu"),
        L("Les donjons et raids prévus par la guilde apparaîtront ici."), L("Créer un événement"),
        function() WP.ShowEventsTab("create") end, "primary")
    ui.noEvents:Hide()
    ui.autoRow = SettingRow(ui.events.content, L("Accepter l'invitation de l'organisateur"),
        L("Quand tu es inscrit, son invitation est acceptée pour toi, de 30 min avant le début à 30 min après."),
        function() return WLWritsDB.eventsAutoAccept ~= false end, function(v) WLWritsDB.eventsAutoAccept = v end)
    BuildCreate(pages.create)
    BuildNow(pages.now)
    -- the picker belongs to the Create tab: it goes when the tab or the window goes
    pages.create:HookScript("OnHide", function() if picker then picker:Hide() end end)
    win:HookScript("OnHide", function() if picker then picker:Hide() end end)
    win:SetScript("OnShow", function() WP.AskEvents(); WP.RefreshEvents() end)
end

function WP.ShowEventsTab(k)
    if not win then Build() end
    current = k
    for key, pg in pairs(pages) do pg:SetShown(key == k) end
    win.subtitle:SetText(GetGuildInfo and GetGuildInfo("player") or "")
    win:Show(); win:Raise()
    WP.RefreshEvents()
    -- wrapped text measures right only once its width is applied: once more on the next frame
    if C_Timer and C_Timer.After then C_Timer.After(0, function() WP.RefreshEvents() end) end
end
function WP.RefreshEvents()
    if not (win and win:IsShown()) then return end
    tabs:Update()
    if current == "upcoming" then RenderUpcoming()
    elseif current == "now" then RenderNow()
    elseif ui.LayoutCreate then
        if ui.MakeDay and ui.dayBuiltFor ~= DayStart(time()) then ui.MakeDay(); if ui.recapNow then ui.recapNow() end end
        win:FitHeight(ui.LayoutCreate())
    end
end
function WP.ToggleEvents()
    if win and win:IsShown() then win:Hide(); return end
    if WP.ModuleOff and WP.ModuleOff("events") then return end
    WP.ShowEventsTab(current)
end
function WP.HideEvents() if win then win:Hide() end end
-- the title typed or built from the picker (read by the tests)
function WP.EventDraftTitle() return ui.title and ui.title:GetText() or "", ui.title end

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
            Say(L("Ton groupe est complet : ta recherche de groupe s'arrête."))
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
