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
--  Looking   "I'm looking for a group" (WP.SetLooking): your role (from your spec by default), what
--            for and the guide's dungeon keys (K message, T-78). Your search is renewed while you
--            stay on and withdrawn when your group is full or you log out; other entries fade after
--            30 minutes. A new search in the guild gets one line in the chat. Shown and switched in
--            the "Trouver un groupe" tab (Writs/Finder.lua), which replaced the "Groupe maintenant" tab.
-- Everything goes on the guild's addon channel; every copy keeps what it saw. Only members who have
-- WL Helper see it. Only names, roles, class, level, times, dungeon keys and the texts typed travel.
--
-- The window is the Groups window ("Groupes" / "Groups"): other files add their tabs before Agenda
-- and Créer through WP.RegisterGroupTab (Writs/Finder.lua: Trouver un groupe; Writs/FinderPeople.lua:
-- Messages, Joueurs récents).
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
    ["Trouver un groupe n'envoie un message privé que quand tu cliques sur Demander à rejoindre ou Inviter, avec le texte montré dans la bulle."] = "Find a group only whispers when you click Ask to join or Invite, with the text shown in the tooltip.",
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
    ["T'inscrire comme"] = "Sign up as",
    ["Ton rôle"] = "Your role",
    ["Me désinscrire"] = "Cancel sign-up",
    ["Inviter les inscrits"] = "Invite sign-ups",
    ["Invitations envoyées"] = "Invites sent",
    ["Hors ligne, pas invités : %s."] = "Offline, not invited: %s.",
    ["Tous les inscrits sont déjà dans ton groupe."] = "Everyone signed up is already in your group.",
    ["Personne d'autre n'est inscrit pour l'instant."] = "Nobody else has signed up yet.",
    ["Annuler l'événement"] = "Cancel event",
    ["Confirmer l'annulation"] = "Confirm cancel",
    ["De 30 min avant à 30 min après le début."] = "30 min before to 30 min after the start.",
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
    -- Agenda in two columns: the list on the left, the chosen event on the right
    ["Choisis un événement à gauche."] = "Pick an event on the left.",
    ["Clic : voir cet événement"] = "Click: show this event",
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
    ["niv. %s à %s"] = "level %s-%s",
    -- the same, at the start of a tooltip line
    ["Niv. %s à %s"] = "Level %s-%s",
    ["Niv. %s"] = "Level %s",
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
    ["%s, niv. %s"] = "%s, level %s",
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
    ["Nouvel événement de %s : %s, %s."] = "New event by %s: %s, %s.",
    ["S'inscrire"] = "Sign up",
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
    ["%s cherche un groupe pour %s (%s, niv. %s)."] = "%s is looking for a group for %s (%s, level %s).",
    ["%s cherche un groupe (%s, niv. %s)."] = "%s is looking for a group (%s, level %s).",
    ["Ton groupe est complet : ta recherche de groupe s'arrête."] = "Your group is full: your group search has stopped.",
    ["Les autres inscrits seront invités dès que le groupe passe en raid."] = "The other sign-ups will be invited as soon as the group becomes a raid.",
    -- read by other windows (Home, the module list, the Writs window, the buttons)
    ["Donjons et raids de la guilde, groupes du moment"] = "Guild dungeons and raids, groups right now",
    ["%d événements à venir"] = "%d upcoming events",
    ["Prochain : %s, %s"] = "Next: %s, %s",
    ["Rien de prévu"] = "Nothing planned",
    ["%d cherchent un groupe"] = "%d looking for a group",
    ["niv. %s"] = "level %s",
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
    for name, l in pairs(DB().lfg) do
        local keys = {}
        if type(l.keys) == "table" then for _, k in ipairs(l.keys) do if type(k) == "string" then keys[#keys + 1] = k end end end
        out[#out + 1] = { name = name, role = l.role, cls = l.cls, lvl = l.lvl, what = l.what, t = l.t or 0, keys = keys }
    end
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
-- the guild's lines come in bursts (every copy answers "Q"): one redraw for the lot; clicks stay immediate
local refreshPending = false
local function RefreshSoon()
    if not (C_Timer and C_Timer.After) then Refresh(); return end
    if refreshPending then return end
    refreshPending = true
    C_Timer.After(0.3, function() refreshPending = false; Refresh() end)
end
-- "[text]" at the end of a chat line, a link that opens the place (FinderPeople.lua reads it)
local function Link(text, kind, arg) return WP.AddonLink and (" " .. WP.AddonLink(text, kind, arg)) or "" end

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

-- One invite: WP.Shared.Invite checks leader or assistant, members already grouped and free slots
-- (T-78: the bare InviteUnit invited from a party where we were not the leader).
local function InviteName(name)
    if type(name) ~= "string" or (root.Readable and not root.Readable(name)) then return end
    if WP.Shared and WP.Shared.Invite then WP.Shared.Invite({ name }); return end
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
-- name -> online, read once from the guild roster (a value the game hides is left out: unknown)
local function OnlineMap()
    local map = {}
    if not (GetNumGuildMembers and GetGuildRosterInfo) then return map end
    local secret = root.IsSecret
    local n = GetNumGuildMembers()
    if type(n) ~= "number" or (secret and secret(n)) then return map end
    for i = 1, n do
        local name, _, _, _, _, _, _, _, isOnline = GetGuildRosterInfo(i)
        if type(name) == "string" and not (secret and (secret(name) or secret(isOnline))) then
            map[Short(name)] = isOnline and true or false
        end
    end
    return map
end
local function Grouped(name)
    local function yes(v) return v and not (root.IsSecret and root.IsSecret(v)) end
    return yes(UnitInParty and UnitInParty(name)) or yes(UnitInRaid and UnitInRaid(name))
end
-- Invites the sign-ups who are online (the offline ones are named in the chat). Returns how many
-- invites go out and, when none, why ("none", "offline", "lead", "full"): the chat always says it.
function WP.InviteSignups(e)
    local names, off, all, grouped = {}, {}, 0, 0
    local online = OnlineMap()
    for name in pairs(e.signups or {}) do
        if name ~= Me() then
            if Grouped(name) then grouped = grouped + 1
            else
                all = all + 1
                -- not in the roster (not read yet): the game decides
                if online[name] == false then off[#off + 1] = name else names[#names + 1] = name end
            end
        end
    end
    if all == 0 then
        Say(grouped > 0 and L("Tous les inscrits sont déjà dans ton groupe.") or L("Personne d'autre n'est inscrit pour l'instant."))
        return 0, "none"
    end
    table.sort(names); table.sort(off)
    if #off > 0 then Say(string.format(L("Hors ligne, pas invités : %s."), table.concat(off, ", "))) end
    if #names == 0 then return 0, "offline" end
    -- in a group without being its leader (or a raid assistant): the game would refuse every invite
    local Sh = WP.Shared
    if IsInGroup() and Sh and Sh.MayInvite and not Sh.MayInvite(IsInRaid()) then
        Say(IsInRaid() and L("Seul le chef du raid ou un assistant peut inviter : demande au chef de te passer assistant.")
            or string.format(L("Seul le chef du groupe peut inviter : demande-lui d'inviter %s ou de te passer chef."), table.concat(names, ", ")))
        return 0, "lead"
    end
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
    -- only the invites that go out now (a full party waits for the raid: the chat line says it)
    return #now, (#now == 0 and "full" or nil)
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
        -- no group icon on the button: the toast's own icon already shows it (icon audit, LFG)
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

WP.LFGRole = MyRole

-- The guide's dungeon keys of a search (K message): 4 at most, plain ASCII words only.
local function CleanKeys(keys)
    local out, seen = {}, {}
    if type(keys) ~= "table" then return out end
    for _, k in ipairs(keys) do
        if type(k) == "string" and k:match("^[%w_]+$") and #k <= 40 and not seen[k] then
            seen[k] = true; out[#out + 1] = k
            if #out >= 4 then break end
        end
    end
    return out
end
WP.LFGCleanKeys = CleanKeys
-- N (every version reads it) first, then K with the dungeon keys (new versions; older ones skip a
-- kind letter they do not know). Sent in that order, one a second: K always lands after N.
local function LookingMsgs(l)
    local n = table.concat({ "N", l.role, l.cls or "", l.lvl or 0, l.what or "" }, "|")
    local k = table.concat({ "K", l.role, l.cls or "", l.lvl or 0, table.concat(CleanKeys(l.keys), ","), l.what or "" }, "|")
    return n, k
end

-- keys: the guide's dungeon keys; nil = the "Trouver un groupe" tab's current dungeons
function WP.SetLooking(role, what, keys)
    local d = DB()
    local _, cls = UnitClass("player")
    if role then
        if keys == nil and WP.Finder and WP.Finder.SourceKeys then
            local ok, k = pcall(WP.Finder.SourceKeys)
            keys = ok and k or nil
        end
        local l = { role = role, cls = cls, lvl = UnitLevel("player"), what = Clean(what, 80), t = time(), keys = CleanKeys(keys) }
        d.lfg[Me()] = l
        local n, k = LookingMsgs(l)
        Send(n); Send(k)
    else
        d.lfg[Me()] = nil
        Send("N|x|||")
    end
    Refresh()
end
function WP.IsLooking() local l = DB().lfg[Me()]; return l and l.role, l and l.what, l and l.keys end

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
            Say(string.format(L("Nouvel événement de %s : %s, %s."), sender, cur.title, When(cur.when, true)) .. Link(L("S'inscrire"), "event", id))
        end
        -- an event I signed up for is cancelled: in the chat and on screen
        if wasOpen and status == "cancelled" and cur.signups and cur.signups[Me()] and On() then
            local m = string.format(L("Événement annulé par %s : %s, %s."), sender, cur.title or "?", When(cur.when, true))
            Say(m)
            if RaidNotice_AddMessage and RaidWarningFrame then RaidNotice_AddMessage(RaidWarningFrame, m, { r = 0.81, g = 0.1, b = 0.09 }) end
        end
        RefreshSoon()
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
        RefreshSoon()
    elseif kind == "N" then
        local role, cls, lvl, what = msg:match("^N|(%a+)|(%u*)|(%d*)|(.*)$")
        if not role then return end
        local was = d.lfg[sender]
        if role == "x" then d.lfg[sender] = nil
        else
            -- the keys a K message gave stay (N is sent again at each renewal, its K follows)
            d.lfg[sender] = { role = role, cls = cls, lvl = tonumber(lvl), what = what, t = time(), keys = was and was.keys or nil }
            -- a new search: one line in the chat (not the answers to my own question at login)
            if not was and On() and GetTime() - askedAt > 20 then
                local who, rl, lv = ClassHex(cls) .. sender .. "|r", L(ROLE_LABEL[role] or "DPS"), lvl ~= "" and lvl or "?"
                if what ~= "" then
                    Say(string.format(L("%s cherche un groupe pour %s (%s, niv. %s)."), who, what, rl, lv) .. Link(L("Voir"), "finder", "find"))
                else
                    Say(string.format(L("%s cherche un groupe (%s, niv. %s)."), who, rl, lv) .. Link(L("Voir"), "finder", "find"))
                end
            end
        end
        RefreshSoon()
    elseif kind == "K" then
        -- "K|role|cls|lvl|key1,key2|what": the same search with the guide's dungeon keys; the N sent
        -- with it already said the news in the chat
        local role, cls, lvl, keys, what = msg:match("^K|(%a+)|(%u*)|(%d*)|([%w_,]*)|(.*)$")
        if not role then return end
        if role == "x" then d.lfg[sender] = nil; RefreshSoon(); return end
        local list = {}
        for k in keys:gmatch("[%w_]+") do list[#list + 1] = k end
        local l = d.lfg[sender] or { t = time() }
        l.role, l.cls, l.lvl, l.what = role, cls, tonumber(lvl), what
        l.keys = CleanKeys(list)
        l.t = time()
        d.lfg[sender] = l
        RefreshSoon()
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
        if l then local n, k = LookingMsgs(l); Send(n); Send(k) end
    end
end

-- ---------------------------------------------------------------- reminders
local function Remind()
    if not (WLWritsDB and On()) then return end
    -- my search for a group stays fresh for the others while it is on (their copies drop it after 30 min)
    local l = DB().lfg[Me()]
    if l and time() - (l.t or 0) > 1200 then WP.SetLooking(l.role, l.what, l.keys or {}) end
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
-- "Groupes" / "LFG": a workspace window (DESIGN 3.1: ~70 % of the screen, resizable, size saved);
-- its pages scroll inside. Every width is read from the window at layout time (Dims):
-- Agenda: the events on the left (LIST_W = 30 % of the content, 240-340), a 1 px rule, the chosen
-- event on the right (DW = the rest): 16 + LIST_W + 16 + 1 + 15 + DW + 16 = W.
-- Create: two columns (ns.Columns(CW, 2, 24)), its fields 480 wide at most (DESIGN 4.2).
local PAD = 16
local W, CW, FW                 -- window, content, form field width (set by Dims)
local LIST_W, DW                -- Agenda: the list, the detail
local RULE_X, DET_X
local COL2_X                    -- Create: the x of the right column
local ROW_H = 52                -- an event line of the list
local LBL = S.F.meta + 2 + 4    -- a field label (11 px) and its 4 px gap
local F = S.F
local win, tabs, current = nil, nil, nil
local pages, ui = {}, {}
local draft = { day = 0, tank = 1, heal = 1, dps = 3 }

local function Num(v) return type(v) == "number" and not (root.IsSecret and root.IsSecret(v)) and v or nil end
local function Clamp(v, lo, hi) return math.max(lo, math.min(hi, v)) end
-- the widths of the window as it is now (a window not built yet, or a size not readable: the rule's
-- default for this screen)
local function Dims()
    local w = win and Num(win:GetWidth())
    if not w or w < 320 then w = (ns.WinSize and ns.WinSize("workspace")) or 956 end
    W = math.floor(w)
    CW = W - 2 * PAD
    LIST_W = Clamp(math.floor(CW * 0.30), 240, 340)
    DW = CW - LIST_W - 32
    RULE_X = PAD + LIST_W + 16
    DET_X = RULE_X + 1 + 15
    local xs, colW = ns.Columns(CW, 2, 24)
    FW = math.min(480, colW)
    COL2_X = PAD + xs[2]
    return W, CW
end
Dims()
-- read by Writs/Finder.lua and Writs/FinderPeople.lua at render time (they draw tabs of this window)
function WP.EventsDims()
    Dims()
    return { W = W, CW = CW, PAD = PAD, LIST_W = LIST_W, DW = DW, FW = FW, COL2_X = COL2_X }
end
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
-- the painted icon of the event: the first dungeon or raid of its name; nil for anything else
-- (the card then shows the HD calendar: "an event", not a war-cry icon that meant nothing)
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
    return nil
end

-- ---------------------------------------------------------------- the event card
local function EventCard(parent, width)
    local c = CreateFrame("Frame", nil, parent)
    c.wlOwned = true
    c.w = width or DW
    c:SetWidth(c.w)
    S.Solid(c, "BACKGROUND", C.cardFill):SetAllPoints()
    S.Border(c, C.cardEdge)
    c.iconFrame = CreateFrame("Frame", nil, c)
    c.iconFrame:SetSize(32, 32); c.iconFrame:SetPoint("TOPLEFT", 12, -12)
    c.icon = c.iconFrame:CreateTexture(nil, "ARTWORK"); c.icon:SetAllPoints()
    c.iconEdge = S.Border(c.iconFrame, C.cardEdge)
    c.title = S.Text(c, F.heading, C.fg)
    c.pill = S.Pill(c)
    c.meta = S.Text(c, F.meta, C.muted)
    c.roles = S.Text(c, F.label, C.text)
    c.who = S.Text(c, F.meta, C.muted)
    -- a dungeon that needs a key nobody signed up has (Keys.lua, from what members' copies shared)
    c.keyWarn = S.Text(c, F.meta, C.warn)
    c.keyWarn:Hide()
    c.note = S.Text(c, F.label, C.text)
    -- signing up is one segmented choice: no role yet, or the role you came with (a click changes it);
    -- a label above says which ("T'inscrire comme", then "Ton rôle")
    c.segLabel = S.Text(c, F.meta, C.muted); c.segLabel:SetWordWrap(false)
    local opts = {}
    for _, role in ipairs(ROLES) do opts[#opts + 1] = { role, RoleText(role, 14) } end
    c.seg = S.Segmented(c, opts, function() local m = c.e and WP.MySignup(c.e); return m and m.role end,
        function(v) if c.e then WP.SignUp(c.e, v) end end, 24)
    local segTips = { L("Clic : t'inscrire comme tank"), L("Clic : t'inscrire comme soigneur"), L("Clic : t'inscrire comme DPS") }
    for i, b in ipairs(c.seg.buttons) do b.tip = { L(ROLE_LABEL[ROLES[i]]), segTips[i] } end
    c.out = S.Button(c, L("Me désinscrire"), 0, 24, "secondary", function() if c.e then WP.SignUp(c.e, nil) end end)
    c.invite = S.Button(c, L("Inviter les inscrits"), 0, 24, "secondary", function(self)
        if not c.e then return end
        -- the flash (a check mark) only when invites went out; otherwise the chat line says why
        if (WP.InviteSignups(c.e) or 0) > 0 then self:Flash(L("Invitations envoyées")) end
    end)
    -- labelled: no icon (icon audit G3); the trash stays on the cancel, a destructive action
    -- cancel in two clicks: the first asks (the label becomes the confirmation), the second cancels
    c.cancel = S.Button(c, L("Annuler l'événement"), 0, 24, "danger", function() if c.e then WP.CancelEvent(c.e) end end)
    c.cancel:SetIcon("trash")
    c.cancel:SetConfirm(L("Confirmer l'annulation"))
    function c:Fit()
        local pad, w = 12, self.w
        local x = pad + 32 + 8
        local textW = w - x - pad
        local pillW = self.pill:IsShown() and ((Num(self.pill:GetWidth()) or 0) + 8) or 0
        self.pill:ClearAllPoints(); self.pill:SetPoint("TOPRIGHT", -pad, -pad)
        Place(self.title, x, pad)
        local th = S.FitText(self.title, 2, textW - pillW, self)
        Place(self.meta, x, pad + th + 3)
        local mh = S.FitText(self.meta, 2, textW, self)
        local y = pad + math.max(32, th + 3 + mh) + 8
        -- the organizer's note is a fact about the event: right under when and who, before the places
        if self.note:IsShown() then
            Place(self.note, pad, y)
            y = y + S.FitText(self.note, 0, w - 2 * pad, self) + 8
        end
        Place(self.roles, pad, y)
        y = y + S.FitText(self.roles, 2, w - 2 * pad, self)
        if self.who:IsShown() then
            y = y + 4; Place(self.who, pad, y)
            y = y + S.FitText(self.who, 0, w - 2 * pad, self)
        end
        if self.keyWarn:IsShown() then
            y = y + 4; Place(self.keyWarn, pad, y)
            y = y + S.FitText(self.keyWarn, 0, w - 2 * pad, self)
        end
        -- two controls side by side when they fit the card, else the second one goes under the first
        local function Pair(a, b, top)
            Place(a, pad, top)
            if not b:IsShown() then return top + 24 end
            local aw, bw = Num(a:GetWidth()) or 0, Num(b:GetWidth()) or 0
            if aw + 8 + bw <= w - 2 * pad then
                b:ClearAllPoints(); b:SetPoint("LEFT", a, "RIGHT", 8, 0)
                return top + 24
            end
            Place(b, pad, top + 24 + 8)
            return top + 24 + 8 + 24
        end
        if self.seg:IsShown() then
            y = y + 12; Place(self.segLabel, pad, y); y = y + LBL
            y = Pair(self.seg, self.out, y)
        end
        if self.invite:IsShown() then
            y = Pair(self.invite, self.cancel, y + 8)
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
    local path = EventIcon(e.title)
    if path then
        S.Painted(c.icon, path); c.icon:SetVertexColor(1, 1, 1); c.iconEdge(C.cardEdge)
    else
        S.HDIcon(c.icon, "calendar", C.muted); c.iconEdge(C.cardEdge, 0)
    end
    if c.icon.SetDesaturated then pcall(c.icon.SetDesaturated, c.icon, cancelled) end
    c.title:SetText(e.title or "?")
    local tc = cancelled and C.muted or C.fg
    c.title:SetTextColor(tc[1], tc[2], tc[3])
    if cancelled then c.pill:Set(L("Annulé"), C.bad)
    elseif organizer then c.pill:Set(L("Organisateur"))
    -- a word pill: the check only repeated "Inscrit"
    elseif mine then c.pill:Set(L("Inscrit"), C.ok)
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
    -- the organizer and those signed up: does one of them have the key to get in?
    local warn
    if not cancelled and WP.Keys and WP.Keys.EventWarning then
        local who = { e.by }
        for name in pairs(e.signups or {}) do if name ~= e.by then who[#who + 1] = name end end
        local ok, w = pcall(WP.Keys.EventWarning, e.title, who)
        if ok and type(w) == "string" and w ~= "" then warn = w end
    end
    c.keyWarn:SetText(warn and (S.IconMarkup("warning", 12, C.warn) .. " " .. warn) or "")
    c.keyWarn:SetShown(warn ~= nil)
    c.note:SetText(e.note or ""); c.note:SetShown((e.note or "") ~= "")
    -- sign up / change role / step out; the organizer invites or cancels
    c.seg:SetShown(not cancelled); c.seg:Update()
    c.segLabel:SetText(mine and L("Ton rôle") or L("T'inscrire comme")); c.segLabel:SetShown(not cancelled)
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

local function AgoText(t)
    local mins = math.max(0, math.floor((time() - (t or time())) / 60))
    if mins < 1 then return L("à l'instant") end
    return string.format(L("il y a %d min"), mins)
end
-- read by the Trouver un groupe tab (Writs/Finder.lua): the same words, the same instance lists
WP.GroupsAgo = AgoText
WP.GroupsRoleText = RoleText
WP.GroupInstances = Instances
-- the guide's keys of an event title "Zul'Farrak + Maraudon" (the names EventIcon matches)
function WP.EventKeys(title)
    local out = {}
    for part in (tostring(title or "") .. " + "):gmatch("(.-)%s+%+%s+") do
        for _, kind in ipairs({ "dg", "raid" }) do
            for _, e in ipairs(Instances(kind)) do
                local d = root.D and root.D[e[1]]
                if e[2] == part or (d and (d.n == part or d.nf == part)) then out[#out + 1] = e[1] end
            end
        end
    end
    return out
end

-- ---------------------------------------------------------------- an event line of the Agenda list
-- 240 x 52: the title 13 fg, when 11 muted, the number of sign-ups in a pill at the right (or
-- "Annulé"). The chosen line is in selFill, no side band. The whole line is the click target.
local selId                     -- the chosen event, kept for the session
local RenderUpcoming
local function EventRow(parent)
    local r = CreateFrame("Button", nil, parent)
    r.wlOwned = true
    r:SetSize(LIST_W, ROW_H)
    r.bg = S.Solid(r, "BACKGROUND", C.cardFill); r.bg:SetAllPoints()
    r.sel = S.Solid(r, "BORDER", C.selFill); r.sel:SetAllPoints(); r.sel:Hide()
    r.hl = S.Solid(r, "ARTWORK", C.hoverFill); r.hl:SetAllPoints(); r.hl:SetAlpha(0)
    r.press = S.Solid(r, "ARTWORK", C.pressFill); r.press:SetAllPoints(); r.press:Hide()
    r.title = S.Text(r, F.body, C.fg); r.title:SetWordWrap(false); r.title:SetJustifyH("LEFT")
    r.when = S.Text(r, F.meta, C.muted); r.when:SetWordWrap(false); r.when:SetJustifyH("LEFT")
    r.pill = S.Pill(r)
    r.pill:SetPoint("RIGHT", -12, 0)
    local function Hover(on)
        root.Tween(r, r.hov or 0, on and 1 or 0, 0.10, function(v) r.hov = v; r.hl:SetAlpha(v) end)
    end
    r:SetScript("OnClick", function(self)
        if not self.e then return end
        -- another event: its card opens at the top, not where the last one was scrolled
        if selId ~= self.e.id and ui.detail and ui.detail.sa then ui.detail.sa:ScrollTo(0, true) end
        selId = self.e.id
        if RenderUpcoming then RenderUpcoming() end
    end)
    r:SetScript("OnEnter", function(self)
        Hover(true)
        local e = self.e
        if not e then return end
        local lines = { e.title or "?", When(e.when) .. "  ·  " .. string.format(L("par %s"), e.by or "?"),
            SignupsText(CountSignups(e)) }
        if e.status ~= "open" then lines[#lines + 1] = { L("Annulé"), C.bad[1], C.bad[2], C.bad[3] } end
        if selId ~= e.id then lines[#lines + 1] = L("Clic : voir cet événement") end
        S.Tip(self, lines)
    end)
    r:SetScript("OnLeave", function() Hover(false); S.HideTip() end)
    r:SetScript("OnMouseDown", function(self) self.press:Show() end)
    r:SetScript("OnMouseUp", function(self) self.press:Hide() end)
    function r:Paint(e, on)
        self.e = e
        local cancelled = e.status ~= "open"
        if cancelled then self.pill:Set(L("Annulé"), C.bad)
        else self.pill:Set(tostring(CountSignups(e)), nil, "group") end
        self:SetWidth(LIST_W)
        local right = 12 + (Num(self.pill:GetWidth()) or 24) + 8
        local tw = LIST_W - 12 - right
        local tc = cancelled and C.muted or C.fg
        self.title:SetTextColor(tc[1], tc[2], tc[3])
        self.title:ClearAllPoints(); self.title:SetPoint("TOPLEFT", 12, -11); self.title:SetWidth(tw)
        self.title:SetText(e.title or "?")
        S.ClampLabel(self.title, e.title, self)
        self.when:ClearAllPoints(); self.when:SetPoint("TOPLEFT", 12, -(11 + F.body + 3)); self.when:SetWidth(tw)
        self.when:SetText(When(e.when))
        S.ClampLabel(self.when, nil, self)
        self.sel:SetShown(on and true or false)
        self.on = on and true or false
    end
    return r
end

-- ---------------------------------------------------------------- Agenda
-- One column of the Agenda: a scroll area at x, `w` wide, from y = 12 down to the page bottom.
local function PlaceCol(l, page, x, w)
    l.sa:ClearAllPoints()
    l.sa:SetPoint("TOPLEFT", page, "TOPLEFT", x, -12)
    l.sa:SetPoint("BOTTOMLEFT", page, "BOTTOMLEFT", x, 12)
    l.sa:SetWidth(w)
    l.sa.child:SetWidth(w)
end
-- the chosen event: the one picked this session while it is listed, else the next open one
local function Chosen(list)
    for _, e in ipairs(list) do if e.id == selId then return e end end
    for _, e in ipairs(list) do if e.status == "open" then selId = e.id; return e end end
    selId = nil
    return nil
end
function RenderUpcoming()
    if not (win and win:IsShown() and current == "upcoming") then return end
    local p = pages.upcoming
    local list = WP.EventList()
    if #list == 0 then
        ui.events.sa:Hide(); ui.detail.sa:Hide(); ui.split:Hide()
        ui.noEvents:Show()
        ui.noEvents:ClearAllPoints(); ui.noEvents:SetPoint("TOP", p, "TOPLEFT", math.floor(W / 2), -24)
        win:FitHeight(12 + ui.noEvents:Fit())
        return
    end
    ui.noEvents:Hide(); ui.events.sa:Show(); ui.detail.sa:Show(); ui.split:Show()
    local chosen = Chosen(list)
    -- the list: one line per event, 2 px apart
    local listH = 0
    for i, e in ipairs(list) do
        local r = ui.events.Get(i)
        r:Paint(e, chosen and e.id == chosen.id)
        Place(r, 0, listH)
        listH = listH + ROW_H + 2
    end
    listH = listH - 2
    ui.events.HideFrom(#list + 1)
    -- the detail: the chosen event's card, or one sentence when none is chosen
    local y = 0
    ui.card.w = DW; ui.card:SetWidth(DW)
    if chosen then
        ui.noPick:Hide()
        ui.card:Show()
        local h = PaintEvent(ui.card, chosen)
        Place(ui.card, 0, 0)
        y = h + 12
    else
        ui.card:Hide()
        ui.noPick:Show()
        Place(ui.noPick, 0, 24)
        y = 24 + S.FitText(ui.noPick, 0, DW, ui.detail.content) + 24
    end
    -- the organizer's invite, accepted by itself: a setting that belongs right under the event
    ui.autoRow:Update()
    Place(ui.autoRow, 0, y)
    y = y + ui.autoRow:Fit(DW)
    PlaceCol(ui.events, p, PAD, LIST_W)
    PlaceCol(ui.detail, p, DET_X, DW)
    ui.split:ClearAllPoints()
    ui.split:SetPoint("TOPLEFT", p, "TOPLEFT", RULE_X, -12); ui.split:SetPoint("BOTTOMLEFT", p, "BOTTOMLEFT", RULE_X, 12)
    ui.events.sa:SetContentHeight(listH)
    ui.detail.sa:SetContentHeight(y)
    win:FitHeight(math.max(listH, y))
end
-- the event shown on the right of the Agenda (read by the tests)
function WP.EventsSelected() return selId end

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
-- Cards with the loading-screen art of the guide's picker, 2 to 4 columns (ns.Cols, cards of 220
-- at least) across a panel window; several can be ticked.
-- The choice is kept aside (sel) until the main button: closing the window changes nothing.
local PGAP = 8
local PCH = 88
local PCWW, PCW, PN, PXS = 544, 268, 2, { 0, 276 }   -- the picker's content width, card width, columns
local function PickerDims(f)
    local w = f and Num(f:GetWidth())
    if not w or w < 320 then w = (ns.WinSize and ns.WinSize("panel")) or 576 end
    PCWW = math.floor(w) - 2 * PAD
    PN, PCW, PXS = ns.Cols(PCWW, 220, PGAP, 4, 200)
end
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
        S.Tip(self, { self.fullName or "", self.lvTip or nil,
            sel[self.key] and L("Clic : décocher") or L("Clic : cocher") })
    end)
    c:SetScript("OnLeave", S.HideTip)
    return c
end

local function BuildPicker()
    local f = S.Window("WLHelperEventsPicker", (ns.WinSize and ns.WinSize("panel")) or 576, 420, L("Choisir les donjons"), nil,
        WLWritsDB, "eventsPickerPos", { header = S.HEADER_H, minH = 240, strata = "DIALOG", noHome = true, size = "panel" })
    -- a new width (the grip, a screen change): the same cards, laid out again
    f.OnResize = function(self) if self.parts and self.Layout then self:Layout() end end
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
    -- the cards of f.parts in ns.Cols columns, the hint, the grid (scrolls past the height cap), the bar
    function f:Layout()
        PickerDims(self)
        local parts = self.parts or {}
        for _, c in ipairs(self.cards) do c:Hide() end
        for _, h in ipairs(self.heads) do h:Hide() end
        local y, i, hi = 0, 0, 0
        for pi, part in ipairs(parts) do
            if part[1] then
                hi = hi + 1
                local h = self.heads[hi]
                if not h then h = S.SectionHeader(self.content, "", nil, nil, nil, true); self.heads[hi] = h end
                h:SetWidth(PCWW)
                if pi > 1 then y = y + 8 end
                Place(h, 0, y)
                h:Set(part[1], #part[2]); h:Show()
                y = y + 24 + 8
            end
            for j, e in ipairs(part[2]) do
                i = i + 1
                local c = self.cards[i] or PickCard(self.content); self.cards[i] = c
                local col, row = (j - 1) % PN, math.floor((j - 1) / PN)
                c:SetSize(PCW, PCH)
                c.name:SetWidth(PCW - 20); c.lv:SetWidth(PCW - 20)
                Place(c, PXS[col + 1], y + row * (PCH + PGAP))
                c.key = e[1]
                if root.DungeonArt then
                    root.DungeonArt(c.art, e[1], c.icon)
                else
                    c.art:SetColorTexture(0.10, 0.11, 0.13, 1)
                end
                c.fullName = e[2]
                FitCardName(c.name, e[2], PCW - 20)
                -- "niv. 35 à 45" / "level 35-45", the summary window's words
                c.lvText = e[3] == e[4] and string.format(L("niv. %s"), e[3]) or string.format(L("niv. %s à %s"), e[3], e[4])
                c.lv:SetText(c.lvText)
                c.lvTip = e[3] == e[4] and string.format(L("Niv. %s"), e[3]) or string.format(L("Niv. %s à %s"), e[3], e[4])
                PaintPickCard(c)
                c:Show()
            end
            y = y + math.ceil(#part[2] / PN) * (PCH + PGAP) - PGAP
        end
        local top = S.HEADER_H + 1 + 12
        Place(self.hint, PAD, top)
        local hh = S.FitText(self.hint, 2, PCWW, self)
        local gridTop = top + hh + 12
        local barH = 12 + 1 + 12 + 28
        self.sa:ClearAllPoints()
        self.sa:SetPoint("TOPLEFT", self, "TOPLEFT", PAD, -gridTop)
        self.sa:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -PAD, barH + 12)
        self.content:SetWidth(PCWW)
        self.sa:SetContentHeight(y)
        self.UpdateOk()
        self:FitHeight(hh + 12 + y + barH)
        return y
    end
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
    picker.parts = parts
    if win then picker:ClearAllPoints(); picker:SetPoint("TOP", win, "TOP", 0, -24) end
    picker:Show(); picker:Raise()
    picker:Layout()
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
    ui.pick = S.Button(p, "", FW, 32, "secondary", function() WP.OpenEventPicker() end, function()
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
            lb:SetWidth(FW - 36 - 34); lb:SetWordWrap(false)
            lb:SetText(draft.kind == "raid" and L("Choisir les raids") or L("Choisir les donjons"))
            S.Painted(ui.pick.thing, draft.kind == "raid" and "Interface\\Icons\\INV_Misc_Head_Dragon_01" or "Interface\\Icons\\INV_Misc_Map_01")
        else
            FitNames(lb, names, FW - 36 - 34)
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
    ui.title = S.Input(p, FW, { label = L("Nom de l'événement"), placeholder = L(PLACEHOLDER[draft.kind]),
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
        if ui.dayLong then ui.dayLong:Hide() end
        if ui.dayShort then ui.dayShort:Hide() end
        ui.dayLong = S.Segmented(p, DayChoices(), function() return draft.day end, DaySet, 28)
        ui.dayShort = S.Segmented(p, DayChoices(true), function() return draft.day end, DaySet, 28)
        ui.day = nil
        ui.ChooseDay()
    end
    -- as wide as the form's other fields at most (FW), its right edge in line with theirs; the day
    -- numbers that do not fit seven times: the day names alone (chosen again when FW changes)
    function ui.ChooseDay()
        local long = (Num(ui.dayLong.natural) or Num(ui.dayLong:GetWidth()) or 0) <= FW
        local pick = long and ui.dayLong or ui.dayShort
        local other = long and ui.dayShort or ui.dayLong
        other:Hide()
        if ui.day ~= pick or ui.dayW ~= FW then
            ui.day, ui.dayW = pick, FW
            pick:SetMaxWidth(FW)
        end
        pick:Show()
        pick:Update()
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
    ui.note = S.Input(p, FW, { label = L("Note (facultatif)"), placeholder = L("Ex. niveau 45 minimum, rendez-vous à Gadgetzan") })
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
        local made = WP.CreateEvent(title, when, N("tank"), N("heal"), N("dps"), ui.note:GetText())
        -- the Agenda opens on the event just published, at the top of its card
        if made then
            selId = made.id
            if ui.detail and ui.detail.sa then ui.detail.sa:ScrollTo(0, true) end
        end
        ui.title:SetText(""); ui.note:SetText(""); wipe(picked); lastBuilt = ""; PickUpdate()
        ui.title:SetError(nil); ui.hour:SetError(nil)
        placesTouched = false
        Recap()
        WP.ShowEventsTab("upcoming")
    end)
    -- an error sentence under a narrow field spans the whole form
    local function ErrH(box)
        if not box.err:IsShown() then return 0 end
        return 4 + S.FitText(box.err, 0, FW, box)
    end
    -- two columns (DESIGN 3.22: ns.Columns(CW, 2, 24), fields FW = 480 at most): what (kind, the
    -- dungeons, name, note) on the left; when and who (day, hour, places) and the recap on the
    -- right; Publish under both
    function ui.LayoutCreate()
        Dims()
        ui.ChooseDay()
        ui.pick:SetWidth(FW); PickUpdate()
        ui.title:SetWidth(FW); ui.note:SetWidth(FW)
        local L1, L2 = PAD, COL2_X
        local y = 12
        Place(ui.kindLabel, L1, y); y = y + LBL
        Place(ui.kind, L1, y); y = y + 28 + 12
        if ui.pick:IsShown() then Place(ui.pick, L1, y); y = y + 32 + 12 end
        y = y + LBL
        Place(ui.title, L1, y); y = y + 28 + ErrH(ui.title) + 12
        y = y + LBL
        Place(ui.note, L1, y); y = y + 28
        local left = y
        y = 12
        Place(ui.dayLabel, L2, y); y = y + LBL
        Place(ui.day, L2, y); y = y + 28 + 12
        y = y + LBL
        Place(ui.hour, L2, y); y = y + 28 + ErrH(ui.hour) + 12
        y = y + LBL
        for i, role in ipairs(ROLES) do Place(ui["n_" .. role], L2 + (i - 1) * 132, y) end
        y = y + 28
        local recap = ui.recap:GetText()
        if recap and recap ~= "" then
            ui.recap:Show()
            y = y + 12
            Place(ui.recap, L2, y)
            y = y + S.FitText(ui.recap, 2, FW, p)
        else
            ui.recap:Hide()
        end
        y = math.max(left, y) + 20
        Place(ui.go, L1, y); y = y + 32
        return y - 12
    end
    ui.recapNow = Recap
    PickUpdate()
    Recap()
end

local function InfoTip()
    return { L("Groupes"), L("Seuls les membres qui ont WL Helper voient les événements et les recherches de groupe."),
        L("Trouver un groupe n'envoie un message privé que quand tu cliques sur Demander à rejoindre ou Inviter, avec le texte montré dans la bulle.") }
end

-- Tabs other files add before Agenda and Créer (WP.RegisterGroupTab, before the window is built):
-- def = { key, label (a French L() key), order, build(page, win), render(), badge() -> n, urgent }.
-- render() draws the tab and fits the window (win:FitHeight). Agenda is 40, Créer 50.
local extraTabs = {}
function WP.RegisterGroupTab(def)
    if type(def) ~= "table" or type(def.key) ~= "string" then return end
    for i, d in ipairs(extraTabs) do if d.key == def.key then extraTabs[i] = def; return end end
    extraTabs[#extraTabs + 1] = def
end
local function TabDef(k) for _, d in ipairs(extraTabs) do if d.key == k then return d end end end
-- old names: "now" (Groupe maintenant) became Trouver un groupe
local ALIAS = { now = "find" }
local function Resolve(k)
    k = ALIAS[k] or k
    if k == "upcoming" or k == "create" then return k end
    if k and TabDef(k) then return k end
    return TabDef("find") and "find" or "upcoming"
end

local function Build()
    local dw, dh = ns.WinSize("workspace")
    win = S.Window("WLHelperEvents", dw or W, dh or 480, L("Groupes"), GetGuildInfo and GetGuildInfo("player") or nil, WLWritsDB, "eventsPos",
        { header = S.HEADER_H, minH = 240, size = "workspace" })
    Dims()
    -- a new size (the grip, a screen change): the shown tab laid out again at the new widths
    win.OnResize = function() Dims(); WP.RefreshEvents() end
    win:AddHeaderButton(S.IconButton(win.header, "info", 28, InfoTip))
    local defs = {}
    for _, d in ipairs(extraTabs) do defs[#defs + 1] = d end
    defs[#defs + 1] = { key = "upcoming", label = "Agenda", order = 40 }
    defs[#defs + 1] = { key = "create", label = "Créer", order = 50 }
    table.sort(defs, function(a, b) return (a.order or 0) < (b.order or 0) end)
    local list = {}
    for _, d in ipairs(defs) do list[#list + 1] = { d.key, L(d.label) } end
    tabs = S.Tabs(win, list,
        function() return current end, function(k) WP.ShowEventsTab(k) end, function(k)
            if k == "upcoming" then local n = #WP.EventList(); return n > 0 and n or nil end
            local d = TabDef(k)
            if d and d.badge then
                local ok, n, urgent = pcall(d.badge)
                if ok and type(n) == "number" and n > 0 then return n, urgent end
            end
        end)
    tabs:SetPoint("TOPLEFT", 0, -(S.HEADER_H + 1)); tabs:SetPoint("TOPRIGHT", 0, -(S.HEADER_H + 1))
    for _, d in ipairs(defs) do
        local p = CreateFrame("Frame", nil, win)
        p:SetPoint("TOPLEFT", 0, -win:ContentTop()); p:SetPoint("BOTTOMRIGHT")
        p:Hide(); pages[d.key] = p
    end
    -- Agenda: the list on the left, a 1 px rule, the chosen event on the right
    ui.events = List(pages.upcoming, EventRow)
    ui.detail = List(pages.upcoming, function(parent) return EventCard(parent, DW) end)
    ui.card = ui.detail.Get(1)
    ui.split = S.Solid(pages.upcoming, "BORDER", C.divider)
    ui.split:SetPoint("TOPLEFT", RULE_X, -12); ui.split:SetPoint("BOTTOMLEFT", RULE_X, 12); ui.split:SetWidth(1)
    if root.PixelLine then root.PixelLine(pages.upcoming, ui.split, false) end
    ui.noPick = S.Text(ui.detail.content, F.label, C.muted)
    ui.noPick:SetWordWrap(true); ui.noPick:SetJustifyH("CENTER")
    ui.noPick:SetText(L("Choisis un événement à gauche."))
    ui.noPick:Hide()
    ui.noEvents = S.EmptyState(pages.upcoming, "calendar", L("Aucun événement prévu"),
        L("Les donjons et raids prévus par la guilde apparaîtront ici."), L("Créer un événement"),
        function() WP.ShowEventsTab("create") end, "primary")
    ui.noEvents:Hide()
    ui.autoRow = S.SettingRow(ui.detail.content, { label = L("Accepter l'invitation de l'organisateur"),
        desc = L("De 30 min avant à 30 min après le début."),
        long = L("Quand tu es inscrit, son invitation est acceptée pour toi, de 30 min avant le début à 30 min après."),
        control = "switch",
        get = function() return WLWritsDB.eventsAutoAccept ~= false end, set = function(v) WLWritsDB.eventsAutoAccept = v end })
    BuildCreate(pages.create)
    for _, d in ipairs(extraTabs) do
        if d.build then
            local ok, err = pcall(d.build, pages[d.key], win)
            if not ok then
                -- a tab that failed to build is left out, the rest of the window works
                if WP.Print then WP.Print("Groupes: " .. tostring(err), true) end
            end
        end
    end
    -- the picker belongs to the Create tab: it goes when the tab or the window goes
    pages.create:HookScript("OnHide", function() if picker then picker:Hide() end end)
    win:HookScript("OnHide", function() if picker then picker:Hide() end end)
    win:SetScript("OnShow", function() WP.AskEvents(); WP.RefreshEvents() end)
end

function WP.ShowEventsTab(k)
    if not win then Build() end
    current = Resolve(k or current)
    for key, pg in pairs(pages) do pg:SetShown(key == current) end
    win.subtitle:SetText(GetGuildInfo and GetGuildInfo("player") or "")
    win:Show(); win:Raise()
    WP.RefreshEvents()
    -- wrapped text measures right only once its width is applied: once more on the next frame
    if C_Timer and C_Timer.After then C_Timer.After(0, function() WP.RefreshEvents() end) end
end
-- the tab shown (or shown last), the window; read by the other tabs and the tests
function WP.EventsTab() return current end
function WP.GroupsWindow() return win end
function WP.RefreshEvents()
    if not (win and win:IsShown()) then return end
    Dims()
    tabs:Update()
    local d = TabDef(current)
    if current == "upcoming" then RenderUpcoming()
    elseif d then
        if d.render then d.render() end
    elseif ui.LayoutCreate then
        if ui.MakeDay and ui.dayBuiltFor ~= DayStart(time()) then ui.MakeDay(); if ui.recapNow then ui.recapNow() end end
        win:FitHeight(ui.LayoutCreate())
    end
end
-- k: the tab to open (/wlh lfg -> "find", /wlh agenda -> "upcoming"); nil: the last one shown.
-- Open on another tab: that tab; open on the same tab (or no tab given): closes.
function WP.ToggleEvents(k)
    if win and win:IsShown() and (k == nil or Resolve(k) == current) then win:Hide(); return end
    if WP.ModuleOff and WP.ModuleOff("events") then return end
    WP.ShowEventsTab(k or current)
end
-- the Agenda on one event (Home's "Voir l'événement"): always opens, never toggles closed
function WP.ShowEvent(id)
    if WP.ModuleOff and WP.ModuleOff("events") then return end
    if id and id ~= selId then
        selId = id
        if ui.detail and ui.detail.sa then ui.detail.sa:ScrollTo(0, true) end
    end
    WP.ShowEventsTab("upcoming")
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
