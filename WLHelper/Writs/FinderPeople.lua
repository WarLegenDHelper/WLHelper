-- Writs/FinderPeople.lua: the people of "Trouver un groupe" (T-78, steps 2 and 3), two tabs of the
-- Groups window and one settings page.
--
--  Messages        The whispers you get and send, one line per person (in memory only, 200 lines at
--                  most, never written to disk: payloads can be secret and they are private). Kept
--                  from login while the module and "Garder les chuchotements" are on. A whisper the
--                  game hides (in a dungeon) is one line with only "Retirer". The tab counts unread
--                  answers from players you asked or invited, or found in your last search.
--  Joueurs récents The last 10 players of your parties (saved per character) and the game's recent
--                  allies (read as they are, never requested), with your 1-3 star rating and a note.
--                  A player rated 1 star joining your party gets one red chat line; someone leaving
--                  gets one line offering to rate (at most once per 5 minutes). Both default off when
--                  another group-finder addon that says the same is loaded.
--  Settings        Settings > Groupes: the two whisper templates and the switches of these tabs.
-- Written from scratch for WL Helper (CC BY-NC-SA); see Writs/Finder.lua for the rules on secrets.
local ADDON, root = ...
root.Writs = root.Writs or {}
local ns = root.Writs
local WP = ns.WP
local L = ns.L
local S = ns.S
local C = S.C
local FS = S.F
local F = WP.Finder
if not F then return end

ns.AddEnglish({
    ["Messages"] = "Messages",
    ["Joueurs récents"] = "Recent players",
    ["Message reçu en donjon (illisible)"] = "Message received in a dungeon (unreadable)",
    ["Retirer"] = "Remove",
    ["Aucun message"] = "No messages",
    ["Les réponses à tes demandes apparaîtront ici."] = "Replies to your requests will show up here.",
    ["Noter"] = "Rate",
    ["Clic : afficher la conversation"] = "Click: show the conversation",
    ["Clic : replier la conversation"] = "Click: hide the conversation",
    ["Clic : retirer de la liste"] = "Click: remove from the list",
    ["Aucun joueur récent"] = "No recent players",
    ["Les joueurs de tes derniers groupes apparaîtront ici."] = "Players from your last groups will show up here.",
    ["hier"] = "yesterday",
    ["il y a %d h"] = "%d h ago",
    ["il y a %d j"] = "%d d ago",
    ["Clic : noter %d sur 3 (%s)"] = "Click: rate %d of 3 (%s)",
    ["Clic : effacer la note"] = "Click: clear the rating",
    ["Reprendre tes %d notes"] = "Import your %d ratings",
    ["Tes notes d'un autre outil de groupe, lues une seule fois. Rien n'y est écrit."] = "Your ratings from another group tool, read once. Nothing is written there.",
    ["%d notes reprises."] = "%d ratings imported.",
    ["%s est dans ton groupe : tu l'as noté %s."] = "%s is in your party: you rated them %s.",
    ["Clique ici pour revoir ta note."] = "Click here to review your rating.",
    ["Quelqu'un a quitté le groupe."] = "Someone left the party.",
    ["Clique ici pour noter tes coéquipiers."] = "Click here to rate your teammates.",
    -- Settings > Groupes
    ["Messages, chuchotements et notes de Trouver un groupe."] = "Messages, whispers and ratings of Find a group.",
    ["Message pour demander à rejoindre"] = "Message to ask to join",
    ["Message d'invitation"] = "Invite message",
    ["Remplacés à l'envoi : %class%, %level%, %role%, %talents%, %dungeon%, %quests%. Vide : la fenêtre de chuchotement s'ouvre à la place."] = "Replaced when sent: %class%, %level%, %role%, %talents%, %dungeon%, %quests%. Empty: the whisper box opens instead.",
    ["Remettre le message de départ"] = "Restore the default message",
    ["Envoyer le message tout seul"] = "Send the message by itself",
    ["Sinon, la fenêtre de chuchotement s'ouvre avec le nom, et tu écris toi-même."] = "Otherwise the whisper box opens with the name and you type yourself.",
    ["Garder les chuchotements dans Groupes"] = "Keep whispers in Groups",
    ["Gardés en mémoire jusqu'à la déconnexion, jamais écrits sur le disque."] = "Kept in memory until you log out, never written to disk.",
    ["Marquer la guilde et les amis"] = "Mark guild members and friends",
    ["Dans les résultats : Guilde, Ami, et l'ordre qui les met en premier."] = "In the results: Guild, Friend, and the order that puts them first.",
    ["Avertir quand un joueur noté À éviter rejoint"] = "Warn when a player rated Avoid joins",
    ["Une ligne dans le chat, une fois par joueur et par session."] = "One chat line, once per player per session.",
    ["Proposer de noter après un départ"] = "Offer to rate after someone leaves",
    ["Une ligne dans le chat, au plus une fois toutes les 5 minutes."] = "One chat line, at most once every 5 minutes.",
})

local function Str(v) return F.Str(v) end
local function Int(v) return F.Int(v) end
local function Readable(v) return F.Readable(v) end
local function Now() return (time and time()) or 0 end
local function Clock() return Int(GetTime and GetTime()) or 0 end
local function Me() return Str((UnitName("player"))) end
local function On() return WP.ModuleOn("events") end
local function Place(obj, x, y) obj:ClearAllPoints(); obj:SetPoint("TOPLEFT", x, -y) end
local function ClassColor(cls)
    local c = cls and RAID_CLASS_COLORS and RAID_CLASS_COLORS[cls]
    if c then return { c.r, c.g, c.b } end
    return C.fg
end
local function Short(n) return n and (n:gsub("%-.*$", "")) or n end
local function AgoLong(t)
    local s = math.max(0, Now() - (t or Now()))
    if s < 60 then return L("à l'instant") end
    if s < 3600 then return string.format(L("il y a %d min"), math.floor(s / 60)) end
    if s < 86400 then return string.format(L("il y a %d h"), math.floor(s / 3600)) end
    if s < 2 * 86400 then return L("hier") end
    return string.format(L("il y a %d j"), math.floor(s / 86400))
end

-- ================================================================= settings (defaults, coexistence)
-- another group-finder addon that already says these two chat lines: ours default off
local otherFinder = false
function F.WarnAvoidOn() return F.Setting("warnAvoid", not otherFinder) end
function F.LeaverPromptOn() return F.Setting("leaverPrompt", not otherFinder) end
function F.KeepWhispersOn() return F.Setting("keepWhispers", true) end

-- ================================================================= the whisper log (memory only)
local MAX_LINES, THREAD_LINES = 200, 20
F.whispers = { threads = {}, order = {}, total = 0 }
local W = F.whispers
local function Trim()
    while W.total > MAX_LINES do
        -- the oldest line of the thread whose first line is the oldest
        local oldest, ot
        for _, th in pairs(W.threads) do
            local l = th.lines[1]
            if l and (not ot or l.t < ot) then oldest, ot = th, l.t end
        end
        if not oldest then break end
        table.remove(oldest.lines, 1)
        W.total = W.total - 1
        if #oldest.lines == 0 then
            W.threads[oldest.key] = nil
            for i, k in ipairs(W.order) do if k == oldest.key then table.remove(W.order, i); break end end
        end
    end
end
local function Touch(key)
    for i, k in ipairs(W.order) do if k == key then table.remove(W.order, i); break end end
    table.insert(W.order, 1, key)
end
-- one whisper in (dir "in") or out ("out"); text, name and guid may be secret
function F.AddWhisper(dir, text, name, guid)
    if not (On() and F.KeepWhispersOn()) then return end
    local n, t = Str(name), Str(text)
    local key = n or "#hidden"
    local th = W.threads[key]
    if not th then
        th = { key = key, name = n, lines = {}, hidden = n == nil }
        W.threads[key] = th
        -- class from the GUID, once per sender (accepts a secret GUID; the answer is read through R)
        if n and GetPlayerInfoByGUID then
            local ok, _, cls = pcall(GetPlayerInfoByGUID, guid)
            if ok then th.cls = Str(cls) end
        end
        if n then
            local g = guid
            if Readable(g) and type(g) == "string" then th.guid = g end
        end
    end
    if n and not th.level then
        for _, r in ipairs(F.rows or {}) do if r.leader == n and r.level then th.level = r.level; th.zone = r.zone end end
    end
    th.lines[#th.lines + 1] = { dir = dir, text = t, t = Now() }
    W.total = W.total + 1
    while #th.lines > THREAD_LINES * 2 do table.remove(th.lines, 1); W.total = W.total - 1 end
    th.last = Now()
    if dir == "in" then th.unread = true end
    Touch(key)
    Trim()
    if F.RenderMessages then F.RenderMessages(true) end
    if WP.RefreshEvents and WP.GroupsWindow and WP.GroupsWindow() and WP.GroupsWindow():IsShown() then
        local tabs = WP.GroupsWindow().wlTabs
        if tabs and tabs.Update then tabs:Update() end
    end
end
function F.RemoveThread(key)
    local th = W.threads[key]
    if not th then return end
    W.total = W.total - #th.lines
    W.threads[key] = nil
    for i, k in ipairs(W.order) do if k == key then table.remove(W.order, i); break end end
end
-- unread threads that answer something we did: a player we asked or invited, or of the last search
function F.UnreadCount()
    local seen = {}
    for _, r in ipairs(F.rows or {}) do if r.leader then seen[r.leader] = true end end
    local n = 0
    for _, th in pairs(W.threads) do
        if th.unread and th.name and (F.contacted[th.name] or seen[th.name] or F.contacted[Short(th.name)]) then n = n + 1 end
    end
    return n
end

-- ================================================================= recent players
local function Recent()
    if type(WLWritsCharDB) ~= "table" then return {} end
    local raw = WLWritsCharDB.finderRecent
    local out = {}
    if type(raw) ~= "table" then return out end
    for _, p in ipairs(raw) do
        if type(p) == "table" and type(p.name) == "string" and p.name ~= "" then
            out[#out + 1] = { name = p.name, guid = type(p.guid) == "string" and p.guid or nil,
                class = type(p.class) == "string" and p.class or nil, level = F.Num(p.level, nil, 1, 100),
                zone = type(p.zone) == "string" and p.zone or nil, t = F.Num(p.t, 0, 0, nil) }
            if #out >= 10 then break end
        end
    end
    return out
end
F.Recent = Recent
local function Remember(p)
    local list = Recent()
    for i = #list, 1, -1 do if list[i].name == p.name then table.remove(list, i) end end
    table.insert(list, 1, p)
    while #list > 10 do table.remove(list) end
    if type(WLWritsCharDB) == "table" then WLWritsCharDB.finderRecent = list end
end
-- the other members of my party (not a raid), readable only; -> list, in a raid, the number of
-- members there whose name the game hides or has not loaded yet ("Unknown")
local function PartyNow()
    local out, hidden = {}, 0
    if IsInRaid and IsInRaid() then return out, true, 0 end
    for i = 1, 4 do
        local u = "party" .. i
        local okE, ex = pcall(UnitExists, u)
        if okE and F.Bool(ex) then
            local okN, name, realm = pcall(UnitNameUnmodified or UnitName, u)
            name = okN and Str(name) or nil
            realm = okN and Str(realm) or nil
            if name and type(UNKNOWNOBJECT) == "string" and name == UNKNOWNOBJECT then name = nil end
            if not name then
                hidden = hidden + 1
            else
                local full = realm and (name .. "-" .. realm) or name
                local _, cls = UnitClass(u)
                out[#out + 1] = { name = full, guid = Str(UnitGUID and UnitGUID(u)), class = Str(cls),
                    level = Int(UnitLevel(u)), zone = Str(GetRealZoneText and GetRealZoneText()), t = Now() }
            end
        end
    end
    return out, false, hidden
end
local present = nil      -- names there at login or reload: never warned about
local lastNames, lastCount, lastHidden = {}, 0, 0
local warned = {}
local leaverAt = -1e9
local function ChatLink(sentence, linkText, tab)
    local link
    if LinkUtil and LinkUtil.FormatLink then
        local ok, l = pcall(LinkUtil.FormatLink, "addon", linkText, "WLHelper", "finder", tab)
        if ok and type(l) == "string" then link = S.Hex(C.accentSoft or C.info) .. l .. "|r" end
    end
    return S.Hex(C.bad) .. sentence .. "|r " .. (link or linkText)
end
F.ChatLink = ChatLink
function F.OnRoster(atLogin)
    local list, raid, hidden = PartyNow()
    local names = {}
    for _, p in ipairs(list) do names[p.name] = true; Remember(p) end
    local count = #list + (hidden or 0)
    if atLogin or present == nil then
        present = {}
        for n in pairs(names) do present[n] = true end
        lastNames, lastCount, lastHidden = names, count, hidden or 0
        return
    end
    -- names hidden now or just before (in a dungeon, loading): nobody can be told apart, so the
    -- baseline starts again without a warning (leaving a dungeon must not look like everyone joined)
    if (hidden or 0) > 0 or lastHidden > 0 then
        lastNames, lastCount, lastHidden = names, count, hidden or 0
        return
    end
    -- a player rated 1 star joins: one red line, once per player per session
    if F.WarnAvoidOn() and not raid then
        for n in pairs(names) do
            if not lastNames[n] and not present[n] and not warned[n] and F.RatingOf(n) == 1 then
                warned[n] = true
                WP.Print(ChatLink(string.format(L("%s est dans ton groupe : tu l'as noté %s."), Short(n), F.RatingWord(1)),
                    L("Clique ici pour revoir ta note."), "players"))
            end
        end
    end
    -- someone left (the count drops; the system line is secret in instances): offer to rate
    if F.LeaverPromptOn() and not raid and count < lastCount and count > 0 and Clock() - leaverAt >= 300 then
        leaverAt = Clock()
        WP.Print(ChatLink(L("Quelqu'un a quitté le groupe."), L("Clique ici pour noter tes coéquipiers."), "players"))
    end
    for n in pairs(present) do if not names[n] then present[n] = nil end end
    lastNames, lastCount, lastHidden = names, count, 0
end

-- the game's recent allies, as they are (never requested)
local function Allies()
    local out = {}
    local RA = C_RecentAllies
    if not (RA and type(RA.GetRecentAllies) == "function") then return out end
    if type(RA.IsSystemEnabled) == "function" then local ok, v = pcall(RA.IsSystemEnabled); if not (ok and F.Bool(v)) then return out end end
    if type(RA.IsRecentAllyDataReady) == "function" then local ok, v = pcall(RA.IsRecentAllyDataReady); if not (ok and F.Bool(v)) then return out end end
    local ok, list = pcall(RA.GetRecentAllies)
    if not ok or not Readable(list) or type(list) ~= "table" then return out end
    for _, a in ipairs(list) do
        if Readable(a) and type(a) == "table" then
            local cd = Readable(a.characterData) and type(a.characterData) == "table" and a.characterData or a
            local name = Str(cd.fullName) or Str(cd.name)
            if name then
                local cls
                local cid = Int(cd.classID)
                if cid and GetClassInfo then local okC, _, file = pcall(GetClassInfo, cid); cls = okC and Str(file) or nil end
                out[#out + 1] = { name = name, guid = Str(cd.guid), class = cls or Str(cd.classFilename), level = Int(cd.level), zone = Str(a.zone or cd.zone), t = nil, ally = true }
            end
        end
    end
    return out
end
-- recent players to show: our party record first, then the game's recent allies not in it
function F.RecentPlayers()
    local out, seen = {}, {}
    for _, p in ipairs(Recent()) do out[#out + 1] = p; seen[Short(p.name)] = true end
    for _, p in ipairs(Allies()) do
        if not seen[Short(p.name)] then seen[Short(p.name)] = true; out[#out + 1] = p end
        if #out >= 30 then break end
    end
    return out
end

-- ================================================================= ratings import (one time)
-- the player's own ratings from another group tool's saved table, read only, validated
function F.ImportableRatings()
    local db = _G.LFGForeverDB
    local raw = type(db) == "table" and db.playerRatings
    local out = {}
    if type(raw) ~= "table" then return out end
    local mine = F.Ratings()
    for name, rec in pairs(raw) do
        if type(name) == "string" and name ~= "" and #name <= 60 and type(rec) == "table" then
            local r = rec.rating or rec.r
            local t = rec.time or rec.t
            if type(r) == "number" and r == math.floor(r) and r >= 1 and r <= 3 and type(t) == "number" and t == t then
                local key = F.NormName(name)
                if key and not mine[key] then out[#out + 1] = { name = name, r = r, t = t, g = type(rec.guid) == "string" and rec.guid or nil } end
            end
        end
    end
    return out
end
function F.ImportRatings()
    local list = F.ImportableRatings()
    local d = F.DB()
    if type(d.ratings) ~= "table" then d.ratings = {} end
    for _, e in ipairs(list) do
        d.ratings[F.NormName(e.name)] = { r = e.r, t = e.t, g = e.g }
    end
    d.imported = true
    -- a large import is capped like the player's own ratings (the oldest go first)
    if F.CapRatings then F.CapRatings() end
    local kept = 0
    for _, e in ipairs(list) do if d.ratings[F.NormName(e.name)] then kept = kept + 1 end end
    return kept

end

-- ================================================================= the Messages tab
local PAD, TW = 16, 640
local CW = TW - 2 * PAD
local mui = {}
local function MsgRow(parent)
    local r = CreateFrame("Button", nil, parent)
    r.wlOwned = true
    r:SetWidth(CW)
    r:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    r.bg = S.Solid(r, "BACKGROUND", C.cardFill); r.bg:SetAllPoints()
    r.hl = S.Solid(r, "BORDER", C.hoverFill); r.hl:SetAllPoints(); r.hl:SetAlpha(0)
    r.cls = r:CreateTexture(nil, "ARTWORK"); r.cls:SetSize(20, 20); r.cls:SetPoint("TOPLEFT", 8, -8)
    r.dot = root.Icon(r, "dot", 8, "ARTWORK", C.accent); r.dot:SetPoint("TOPLEFT", 2, -4)
    r.name = S.Text(r, FS.label, C.fg); r.name:SetWordWrap(false); r.name:SetPoint("TOPLEFT", 36, -5)
    r.last = S.Text(r, FS.meta, C.muted); r.last:SetWordWrap(false); r.last:SetJustifyH("LEFT")
    r.last:SetPoint("TOPLEFT", 36, -(5 + FS.label + 3))
    r.when = S.Text(r, FS.meta, C.muted); r.when:SetWordWrap(false)
    r.remove = S.Button(r, L("Retirer"), 0, 24, "ghost", function()
        if r.th then F.RemoveThread(r.th.key); F.RenderMessages() end
    end, { L("Retirer"), L("Clic : retirer de la liste") })
    r.remove:SetPoint("TOPRIGHT", -8, -6)
    r.inv = S.Button(r, L("Inviter"), 0, 24, "secondary", function(self)
        local n = r.th and r.th.name
        if not n or F.Locked() or F.CooldownLeft() > 0 then return end
        F.actAt = Clock()
        local done = WP.Shared and WP.Shared.Invite and WP.Shared.Invite({ n }) or 0
        F.StartCooldown()
        if (done or 0) > 0 then F.contacted[n] = Now(); self:Flash(L("Invité")) end
    end)
    r.inv:SetPoint("RIGHT", r.remove, "LEFT", -8, 0)
    r.whisper = S.Button(r, L("Chuchoter"), 0, 24, "secondary", function()
        if r.th and r.th.name and not F.Locked() then F.OpenWhisper(r.th.name) end
    end)
    r.whisper:SetPoint("RIGHT", r.inv, "LEFT", -8, 0)
    r.rate = S.IconButton(r, "star", 24, { L("Noter"), L("Clic droit : plus d'actions") }, function(self)
        if r.th and r.th.name then F.Menu(self, r.th.name, nil, r.th.guid) end
    end)
    r.rate:SetPoint("RIGHT", r.whisper, "LEFT", -4, 0)
    r.lines = {}
    r:SetScript("OnClick", function(self, button)
        local th = self.th
        if not th then return end
        if button == "RightButton" then if th.name then F.Menu(self, th.name, nil, th.guid) end return end
        mui.open = (mui.open ~= th.key) and th.key or nil
        th.unread = nil
        F.RenderMessages()
    end)
    r:SetScript("OnEnter", function(self)
        self.hl:SetAlpha(1)
        if self.th then S.Tip(self, { self.th.name or L("Message reçu en donjon (illisible)"),
            mui.open == self.th.key and L("Clic : replier la conversation") or L("Clic : afficher la conversation") }) end
    end)
    r:SetScript("OnLeave", function(self) self.hl:SetAlpha(0); S.HideTip() end)
    function r:Paint(th, open)
        self.th = th
        local hidden = th.name == nil
        if th.cls and S.ClassIcon(self.cls, th.cls) then self.cls:Show() else self.cls:Hide() end
        self.dot:SetShown(th.unread == true)
        self.name:SetText(hidden and L("Message reçu en donjon (illisible)") or Short(th.name))
        local c = hidden and C.muted or ClassColor(th.cls)
        self.name:SetTextColor(c[1], c[2], c[3])
        local last = th.lines[#th.lines]
        -- a hidden text is shown by SetText alone, never joined
        if last and last.text then self.last:SetText(last.text) else self.last:SetText("") end
        self.when:SetText(AgoLong(th.last))
        local locked = F.Locked()
        self.inv:SetShown(not hidden and not locked)
        self.whisper:SetShown(not hidden and not locked)
        self.rate:SetShown(not hidden)
        local right = 8 + (self.remove:GetWidth() or 60) + 8
        if self.inv:IsShown() then right = right + (self.inv:GetWidth() or 70) + 8 + (self.whisper:GetWidth() or 84) + 8 end
        if self.rate:IsShown() then right = right + 28 end
        self.when:ClearAllPoints(); self.when:SetPoint("TOPRIGHT", -right, -8)
        local textW = math.max(80, CW - 36 - right - 70)
        self.name:SetWidth(textW); S.ClampLabel(self.name, nil, self)
        self.last:SetWidth(textW); S.ClampLabel(self.last, nil, self)
        -- the conversation: the last 20 lines, in/out marked
        local y = 36
        local shown = 0
        if open then
            local from = math.max(1, #th.lines - THREAD_LINES + 1)
            for i = from, #th.lines do
                shown = shown + 1
                local l = self.lines[shown]
                if not l then
                    l = { icon = root.Icon(self, "chevron_left", 12, "ARTWORK", C.muted), text = S.Text(self, FS.label, C.text) }
                    l.text:SetJustifyH("LEFT"); l.text:SetWordWrap(true)
                    self.lines[shown] = l
                end
                local line = th.lines[i]
                root.SetHDIcon(l.icon, line.dir == "in" and "chevron_left" or "chevron_right", line.dir == "in" and C.muted or C.accentSoft or C.muted)
                Place(l.icon, 36, y + 1)
                if line.text then l.text:SetText(line.text) else l.text:SetText(L("Message reçu en donjon (illisible)")) end
                Place(l.text, 54, y)
                l.text:SetWidth(CW - 54 - 12)
                local h = S.FitText(l.text, 0, CW - 54 - 12, self)
                l.icon:Show(); l.text:Show()
                y = y + math.max(14, h) + 4
            end
            y = y + 6
        end
        for i = shown + 1, #self.lines do self.lines[i].icon:Hide(); self.lines[i].text:Hide() end
        local h = math.max(36, y)
        self:SetHeight(h)
        return h
    end
    return r
end
local function BuildMessages(page, win)
    mui.page, mui.win = page, win
    mui.sa = S.ScrollArea(page)
    mui.content = mui.sa.child
    mui.rows = {}
    mui.empty = S.EmptyState(mui.content, "mail", L("Aucun message"), L("Les réponses à tes demandes apparaîtront ici."))
    mui.empty:Hide()
    mui.banner = S.Banner(page, "info", "")
    mui.banner:Hide()
end
-- inserted: a new line came in. The newest conversation is listed first, so the view goes back to
-- the top only if it was at the top before (a player reading further down is not moved).
function F.RenderMessages(inserted)
    local page = mui.page
    if not (page and page:IsShown()) then return end
    local atTop = true
    if inserted and mui.sa.GetScroll then
        atTop = (mui.sa:GetScroll() or 0) <= 2
    end
    local y = 12
    mui.banner:Hide()
    if F.Locked() then
        mui.banner:SetText(L("En donjon, le jeu masque les noms : les actions reviennent à la sortie."), "info")
        local h = mui.banner:Fit(CW); Place(mui.banner, PAD, y); mui.banner:Show(); y = y + h + 12
    end
    local top = y
    local cy, n = 0, 0
    for _, key in ipairs(W.order) do
        local th = W.threads[key]
        if th then
            n = n + 1
            local r = mui.rows[n]
            if not r then r = MsgRow(mui.content); mui.rows[n] = r end
            r:Show()
            local h = r:Paint(th, mui.open == key)
            if mui.open == key then th.unread = nil end
            Place(r, 0, cy)
            cy = cy + h + 2
        end
    end
    for i = n + 1, #mui.rows do mui.rows[i]:Hide() end
    if n == 0 then
        mui.empty:SetWrapWidth(CW)
        mui.empty:ClearAllPoints(); mui.empty:SetPoint("TOP", mui.content, "TOPLEFT", CW / 2, -12)
        mui.empty:Show()
        cy = 12 + mui.empty:Fit() + 12
    else mui.empty:Hide() end
    mui.sa:ClearAllPoints()
    mui.sa:SetPoint("TOPLEFT", page, "TOPLEFT", PAD, -top)
    mui.sa:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -PAD, 12)
    mui.content:SetWidth(CW)
    mui.sa:SetContentHeight(cy)
    if inserted and atTop then mui.sa:ScrollTo(0, true) end
    mui.atTop = atTop

    if mui.win and mui.win.FitHeight and not inserted then mui.win:FitHeight(top - 12 + cy) end
end

-- ================================================================= the Recent players tab
local pui = {}
local function Stars(parent, size, onPick, getName)
    local h = CreateFrame("Frame", nil, parent)
    h:SetSize(3 * 20, 20)
    h.b = {}
    local function Paint(upto)
        local cur = h.rating or 0
        for i, b in ipairs(h.b) do
            local on = upto and i <= upto or (not upto and i <= cur)
            local c = on and (C.star or C.head) or C.faint
            b.icon:SetVertexColor(c[1], c[2], c[3])
        end
    end
    for i = 1, 3 do
        local b = CreateFrame("Button", nil, h)
        b:SetSize(20, 20); b:SetPoint("LEFT", (i - 1) * 20, 0)
        b.icon = root.Icon(b, "star", size or 16, "ARTWORK", C.faint); b.icon:SetPoint("CENTER")
        b:SetScript("OnEnter", function(self)
            Paint(i)
            local word = F.RatingWord(i)
            S.Tip(self, { word, (h.rating == i) and L("Clic : effacer la note") or string.format(L("Clic : noter %d sur 3 (%s)"), i, word) })
        end)
        b:SetScript("OnLeave", function() Paint(nil); S.HideTip() end)
        b:SetScript("OnClick", function() onPick(h, h.rating == i and nil or i) end)
        h.b[i] = b
    end
    function h:Set(r) self.rating = r; Paint(nil) end
    return h
end
local function PlayerRow(parent)
    local r = CreateFrame("Button", nil, parent)
    r.wlOwned = true
    r:SetWidth(CW)
    r:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    r.bg = S.Solid(r, "BACKGROUND", C.cardFill); r.bg:SetAllPoints()
    r.hl = S.Solid(r, "BORDER", C.hoverFill); r.hl:SetAllPoints(); r.hl:SetAlpha(0)
    r.cls = r:CreateTexture(nil, "ARTWORK"); r.cls:SetSize(20, 20); r.cls:SetPoint("TOPLEFT", 8, -8)
    r.name = S.Text(r, FS.label, C.fg); r.name:SetWordWrap(false); r.name:SetPoint("TOPLEFT", 36, -5)
    r.detail = S.Text(r, FS.meta, C.muted); r.detail:SetWordWrap(false); r.detail:SetPoint("TOPLEFT", 36, -(5 + FS.label + 3))
    r.note = S.Text(r, FS.meta, C.muted); r.note:SetJustifyH("LEFT")
    r.stars = Stars(r, 16, function(_, v)
        if r.p then F.SetRating(r.p.name, v, r.p.guid); F.RenderPlayers() end
    end)
    r.stars:SetPoint("TOPRIGHT", -8, -8)
    r:SetScript("OnClick", function(self, button) if button == "RightButton" and self.p then F.Menu(self, self.p.name, nil, self.p.guid) end end)
    r:SetScript("OnEnter", function(self) self.hl:SetAlpha(1); if self.p then S.Tip(self, { self.p.name, L("Clic droit : plus d'actions") }) end end)
    r:SetScript("OnLeave", function(self) self.hl:SetAlpha(0); S.HideTip() end)
    function r:Paint(p)
        self.p = p
        if p.class and S.ClassIcon(self.cls, p.class) then self.cls:Show() else self.cls:Hide() end
        self.name:SetText(Short(p.name))
        local c = ClassColor(p.class)
        self.name:SetTextColor(c[1], c[2], c[3])
        local parts = {}
        if p.level then parts[#parts + 1] = string.format(L("Niv. %s"), p.level) end
        if p.zone then parts[#parts + 1] = p.zone end
        if p.t and p.t > 0 then parts[#parts + 1] = AgoLong(p.t) end
        self.detail:SetText(table.concat(parts, " · "))
        local w = CW - 36 - 80
        self.name:SetWidth(w); self.detail:SetWidth(w)
        self.stars:Set(F.RatingOf(p.name))
        local rec = F.Ratings()[F.NormName(p.name) or ""]
        local note = type(rec) == "table" and type(rec.note) == "string" and rec.note or nil
        local h = 36
        if note and note ~= "" then
            self.note:SetText(note); Place(self.note, 36, 36 - 4); self.note:Show()
            h = 36 + S.FitText(self.note, 2, w, self)
        else self.note:Hide() end
        self:SetHeight(h)
        return h
    end
    return r
end
local function BuildPlayers(page, win)
    pui.page, pui.win = page, win
    pui.sa = S.ScrollArea(page)
    pui.content = pui.sa.child
    pui.rows = {}
    pui.empty = S.EmptyState(pui.content, "user", L("Aucun joueur récent"), L("Les joueurs de tes derniers groupes apparaîtront ici."))
    pui.empty:Hide()
    pui.import = S.Button(page, "", 0, 28, "secondary", function(self)
        local n = F.ImportRatings()
        WP.Print(string.format(L("%d notes reprises."), n))
        F.RenderPlayers()
    end, { L("Tes notes d'un autre outil de groupe, lues une seule fois. Rien n'y est écrit.") })
    local evp = CreateFrame("Frame")
    local evs = { "RECENT_ALLIES_CACHE_UPDATE", "RECENT_ALLIES_SYSTEM_STATUS_UPDATED", "RECENT_ALLY_DATA_UPDATED" }
    evp:SetScript("OnEvent", function() F.RenderPlayers() end)
    page:HookScript("OnShow", function() for _, e in ipairs(evs) do pcall(evp.RegisterEvent, evp, e) end end)
    page:HookScript("OnHide", function() for _, e in ipairs(evs) do pcall(evp.UnregisterEvent, evp, e) end end)
end
function F.RenderPlayers()
    local page = pui.page
    if not (page and page:IsShown()) then return end
    local y = 12
    local importable = (F.DB().imported ~= true) and #F.ImportableRatings() or 0
    if importable > 0 then
        pui.import:SetText(string.format(L("Reprendre tes %d notes"), importable))
        Place(pui.import, PAD, y); pui.import:Show()
        y = y + 28 + 12
    else pui.import:Hide() end
    local top = y
    local list = F.RecentPlayers()
    local cy = 0
    for i, p in ipairs(list) do
        local r = pui.rows[i]
        if not r then r = PlayerRow(pui.content); pui.rows[i] = r end
        r:Show()
        local h = r:Paint(p)
        Place(r, 0, cy)
        cy = cy + h + 2
    end
    for i = #list + 1, #pui.rows do pui.rows[i]:Hide() end
    if #list == 0 then
        pui.empty:SetWrapWidth(CW)
        pui.empty:ClearAllPoints(); pui.empty:SetPoint("TOP", pui.content, "TOPLEFT", CW / 2, -12)
        pui.empty:Show()
        cy = 12 + pui.empty:Fit() + 12
    else pui.empty:Hide() end
    pui.sa:ClearAllPoints()
    pui.sa:SetPoint("TOPLEFT", page, "TOPLEFT", PAD, -top)
    pui.sa:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -PAD, 12)
    pui.content:SetWidth(CW)
    pui.sa:SetContentHeight(cy)
    if pui.win and pui.win.FitHeight then pui.win:FitHeight(top - 12 + cy) end
end
F.OnRatingChanged = function()
    if F.Render then F.Render() end
    if F.RenderPlayers then F.RenderPlayers() end
end

if WP.RegisterGroupTab then
    WP.RegisterGroupTab({ key = "messages", label = "Messages", order = 20, build = BuildMessages,
        render = function() F.RenderMessages() end,
        badge = function() local n = F.UnreadCount(); return n, n > 0 end })
    WP.RegisterGroupTab({ key = "players", label = "Joueurs récents", order = 30, build = BuildPlayers,
        render = function() F.RenderPlayers() end })
end

-- ================================================================= Settings > Groupes
local function Switch(parent, label, desc, get, set)
    local r = CreateFrame("Button", nil, parent)
    r.wlOwned = true
    r.rule = S.Rule(r); r.rule:SetPoint("TOPLEFT"); r.rule:SetPoint("TOPRIGHT")
    r.label = S.Text(r, FS.body, C.fg); r.label:SetText(label)
    r.desc = S.Text(r, FS.meta, C.muted); r.desc:SetText(desc or "")
    r.switch = S.Switch(r, get, set)
    r.switch:SetPoint("TOPRIGHT", 0, -8)
    r.switch:AttachRow(r)
    function r:Fit(w)
        self:SetWidth(w)
        local textW = w - 40 - 12
        Place(self.label, 0, 8)
        local lh = S.FitText(self.label, 2, textW, self)
        Place(self.desc, 0, 8 + lh + 3)
        local h = 8 + lh + 3 + S.FitText(self.desc, 0, textW, self) + 8
        h = math.max(36, math.ceil(h))
        self:SetHeight(h)
        self.switch:Update()
        return h
    end
    return r
end
local function TemplateBox(parent, kind, label)
    local b = {}
    b.label = S.Text(parent, FS.body, C.fg); b.label:SetText(label)
    local eb = CreateFrame("EditBox", nil, parent)
    eb.wlOwned = true
    eb:SetMultiLine(true)
    eb:SetAutoFocus(false)
    if eb.SetMaxBytes then eb:SetMaxBytes(201) else eb:SetMaxLetters(200) end
    local ok = pcall(eb.SetFont, eb, C.font or STANDARD_TEXT_FONT, FS.label, "")
    if not ok and eb.SetFontObject then eb:SetFontObject("ChatFontNormal") end
    eb:SetTextColor(C.fg[1], C.fg[2], C.fg[3])
    eb:SetTextInsets(8, 8, 6, 6)
    S.Solid(eb, "BACKGROUND", C.panel, 1):SetAllPoints()
    eb.border = S.Border(eb, C.line or C.muted)
    eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    eb:SetScript("OnEditFocusGained", function(self) self.border(C.accent, 1) end)
    eb:SetScript("OnEditFocusLost", function(self) self.border(C.line or C.muted, 1); F.SetTemplate(kind, self:GetText()) end)
    eb:SetScript("OnTextChanged", function(self, user) if user then F.SetTemplate(kind, self:GetText()) end end)
    b.box = eb
    b.reset = S.Button(parent, L("Remettre le message de départ"), 0, 24, "ghost", function()
        F.SetTemplate(kind, F.DefaultTemplate(kind)); eb:SetText(F.Template(kind))
    end)
    function b:Sync() eb:SetText(F.Template(kind)) end
    return b
end
WP.GroupsPage = {
    Build = function(p, width)
        local CWp = math.floor((width or 660) - 32)
        local ask = TemplateBox(p, "ask", L("Message pour demander à rejoindre"))
        local inv = TemplateBox(p, "invite", L("Message d'invitation"))
        local help = S.Text(p, FS.meta, C.muted)
        help:SetText(L("Remplacés à l'envoi : %class%, %level%, %role%, %talents%, %dungeon%, %quests%. Vide : la fenêtre de chuchotement s'ouvre à la place."))
        help:SetJustifyH("LEFT")
        local rows = {
            Switch(p, L("Envoyer le message tout seul"), L("Sinon, la fenêtre de chuchotement s'ouvre avec le nom, et tu écris toi-même."),
                function() return F.AutoSend() end, function(v) if WLWritsCharDB then WLWritsCharDB.finderAutoSend = v and true or false end end),
            Switch(p, L("Garder les chuchotements dans Groupes"), L("Gardés en mémoire jusqu'à la déconnexion, jamais écrits sur le disque."),
                function() return F.KeepWhispersOn() end, function(v) F.SetSetting("keepWhispers", v) end),
            Switch(p, L("Marquer la guilde et les amis"), L("Dans les résultats : Guilde, Ami, et l'ordre qui les met en premier."),
                function() return F.Setting("markRelations", true) end, function(v) F.SetSetting("markRelations", v) end),
            Switch(p, L("Avertir quand un joueur noté À éviter rejoint"), L("Une ligne dans le chat, une fois par joueur et par session."),
                function() return F.WarnAvoidOn() end, function(v) F.SetSetting("warnAvoid", v) end),
            Switch(p, L("Proposer de noter après un départ"), L("Une ligne dans le chat, au plus une fois toutes les 5 minutes."),
                function() return F.LeaverPromptOn() end, function(v) F.SetSetting("leaverPrompt", v) end),
        }
        local function Layout()
            local y = 16
            for _, b in ipairs({ ask, inv }) do
                b:Sync()
                Place(b.label, 16, y); y = y + FS.body + 6
                Place(b.box, 16, y); b.box:SetSize(CWp, 56); y = y + 56 + 4
                Place(b.reset, 16, y); y = y + 24 + 12
            end
            Place(help, 16, y); y = y + S.FitText(help, 0, CWp, p) + 16
            for _, r in ipairs(rows) do Place(r, 16, y); y = y + r:Fit(CWp) end
            y = math.ceil(y + 16)
            p.contentH = y
            if p.sa then p.sa:SetContentHeight(y) end
            return y
        end
        function p:Layout() return Layout() end
        Layout()
    end,
}

-- ================================================================= events
local evf = CreateFrame("Frame")
pcall(evf.RegisterEvent, evf, "PLAYER_LOGIN")
pcall(evf.RegisterEvent, evf, "PLAYER_ENTERING_WORLD")
pcall(evf.RegisterEvent, evf, "GROUP_ROSTER_UPDATE")
pcall(evf.RegisterEvent, evf, "UNIT_NAME_UPDATE")
pcall(evf.RegisterEvent, evf, "CHAT_MSG_WHISPER")
pcall(evf.RegisterEvent, evf, "CHAT_MSG_WHISPER_INFORM")
evf:SetScript("OnEvent", function(_, ev, ...)
    if not WLWritsDB then return end
    if ev == "CHAT_MSG_WHISPER" or ev == "CHAT_MSG_WHISPER_INFORM" then
        local text, name = ...
        local guid = select(12, ...)
        pcall(F.AddWhisper, ev == "CHAT_MSG_WHISPER" and "in" or "out", text, name, guid)
    elseif ev == "PLAYER_LOGIN" then
        otherFinder = (root.IsLoaded and root.IsLoaded("LFGForever")) and true or false
        -- "Clique ici": our addon links open the tab
        if EventRegistry and EventRegistry.RegisterCallback then
            pcall(EventRegistry.RegisterCallback, EventRegistry, "SetItemRef", function(_, link)
                if type(link) ~= "string" then return end
                local tab = link:match("^addon:WLHelper:finder:(%a+)")
                if tab and WP.ShowEventsTab then WP.ShowEventsTab(tab) end
            end, F)
        end
    elseif ev == "PLAYER_ENTERING_WORLD" then
        local isLogin, isReload = ...
        if On() then pcall(F.OnRoster, isLogin or isReload) end
    elseif ev == "GROUP_ROSTER_UPDATE" then
        if On() then pcall(F.OnRoster, false) end
    elseif ev == "UNIT_NAME_UPDATE" then
        -- a late name of a party member (other units are not ours)
        local unit = ...
        if On() and type(unit) == "string" and Readable(unit) and unit:match("^party%d$") then pcall(F.OnRoster, false) end
    end
end)
