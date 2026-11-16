-- Writs/Home.lua: the Home page of the WL Helper window (the Hub, Writs/Options.lua), and the
-- minimap button's tooltip and menu.
-- From the top: "Où veux-tu aller ?" (a search field on WP.GoTo: Enter guides you to the first place);
-- "now", only what a line cannot do (start the Writs tour, an event about to start, the city tour,
-- a nearly full log, a running GPS; hidden when nothing waits); a line when a newer version exists;
-- then each activity of WP.HUB_GROUPS with its windows, two lines a row (S.HubRow: icon, name, where
-- you stand; what the window does is in the tooltip; a dot when it has something to do now; a
-- right-click opens its settings). The lines never move. Opened by /wlh, a click on the minimap
-- button and the "<" of every window.
local ADDON, root = ...
root.Writs = root.Writs or {}
local ns = root.Writs
local WP = ns.WP
local L = ns.L
local S = ns.S
local C = S.C
local F = S.F

ns.AddEnglish({
    ["%s, niv. %d"] = "%s, level %d",
    -- the search field
    ["Où veux-tu aller ?"] = "Where do you want to go?",
    ["Voir tous les résultats"] = "See all results",
    ["Ouvrir Aller à"] = "Open Go to",
    -- the lines of Home
    ["Outils"] = "Tools",
    ["Un lieu, un PNJ, une ville : le GPS t'y mène"] = "A place, an NPC, a city: the GPS takes you there",
    ["Clic : ouvrir Aller à"] = "Click: open Go to",
    ["Clic droit : réglages"] = "Right-click: settings",
    ["Aucune clé pour l'instant (%d en tout)"] = "No keys yet (%d in all)",
    ["Il te faut %s pour entrer dans %s."] = "You need %s to get into %s.",
    ["Ce qu'il y a à faire en arrivant dans une capitale"] = "What there is to do when you arrive in a capital",
    ["1 chose à faire dans cette ville"] = "1 thing to do in this city",
    ["%d choses à faire dans cette ville"] = "%d things to do in this city",
    ["Clic : ouvrir la tournée en ville"] = "Click: open the city tour",
    ["Les membres qui font les mêmes donjons que toi"] = "Members doing the same dungeons as you",
    ["Clic : voir les quêtes en commun"] = "Click: see the shared quests",
    ["Journal : %d quêtes sur %d"] = "Log: %d of %d quests",
    ["1 quête à abandonner"] = "1 quest to abandon",
    ["%d quêtes à abandonner"] = "%d quests to abandon",
    ["Clic : voir les quêtes à abandonner"] = "Click: see the quests you can abandon",
    ["1 chose à faire dans cette ville."] = "1 thing to do in this city.",
    ["%d choses à faire dans cette ville."] = "%d things to do in this city.",
    ["Voir la tournée"] = "See the tour",
    ["Ton journal de quêtes est presque plein."] = "Your quest log is nearly full.",
    ["Réglages"] = "Settings",
    ["Clic : ouvrir les réglages"] = "Click: open settings",
    ["Une idée, un bug ?"] = "An idea, a bug?",
    ["Clic : ouvrir le formulaire pour nous écrire"] = "Click: open the form to write to us",
    -- "now"
    ["Le GPS te guide vers %s."] = "The GPS is guiding you to %s.",
    ["Le GPS te guide."] = "The GPS is guiding you.",
    ["Arrêter le GPS"] = "Stop the GPS",
    ["1 Writ est prêt à rendre."] = "1 Writ is ready to turn in.",
    ["%d Writs sont prêts à rendre."] = "%d Writs are ready to turn in.",
    ["Voir les Writs"] = "See Writs",
    ["%s commence dans %d min."] = "%s starts in %d min.",
    ["%s a commencé."] = "%s has started.",
    ["Voir l'événement"] = "See the event",
    ["Prochaine étape : %s"] = "Next step: %s",
    ["Reprendre le guide"] = "Resume guide",
    ["Nettoyer les sacs"] = "Clean bags",
    -- the cards
    ["Guide de quêtes"] = "Quest guide",
    ["Étape %d sur %d"] = "Step %d of %d",
    ["Choisis ton prochain guide."] = "Pick your next guide.",
    ["Aucun guide choisi"] = "No guide picked",
    ["Donjons, raids et quêtes de classe, depuis là où tu es."] = "Dungeons, raids and class quests, from where you are.",
    ["Terminée"] = "Finished",
    ["Clic : ouvrir le guide"] = "Click: open the guide",
    ["Clic : choisir un guide"] = "Click: pick a guide",
    ["Writs"] = "Writs",
    ["Encore 1 point avant %s"] = "1 more point to %s",
    ["Encore %s points avant %s"] = "%s more points to %s",
    ["%s atteint"] = "%s reached",
    ["Faction pas encore vue"] = "Faction not seen yet",
    ["Parle à un PNJ de cette faction pour qu'elle apparaisse."] = "Talk to one of the faction's NPCs to unlock it.",
    ["1 Writ prêt à rendre"] = "1 Writ ready to turn in",
    ["%d Writs prêts à rendre"] = "%d Writs ready to turn in",
    ["1 enveloppe à ouvrir"] = "1 envelope to open",
    ["%d enveloppes à ouvrir"] = "%d envelopes to open",
    ["Rien à rendre pour l'instant"] = "Nothing to turn in yet",
    ["Clic : ouvrir les Writs"] = "Click: open the Writs window",
    ["Faveur du marchand"] = "Merchant's Favor",
    ["1 point de Faveur"] = "1 Favor",
    ["%s points de Faveur"] = "%s Favor",
    ["Pas encore de Faveur"] = "No Favor yet",
    ["Les caisses les moins chères et où les rendre"] = "The cheapest crates and where to turn them in",
    ["Clic : voir les caisses"] = "Click: see the crates",
    ["Sacs"] = "Bags",
    ["1 objet de quête à jeter"] = "1 quest item to throw away",
    ["%d objets de quête à jeter"] = "%d quest items to throw away",
    ["Rien à jeter"] = "Nothing to throw away",
    ["Clic : voir les objets à jeter"] = "Click: see the items to throw away",
    ["Commandes"] = "Orders",
    ["1 commande à accepter"] = "1 order to accept",
    ["%d commandes à accepter"] = "%d orders to accept",
    ["Aucune commande en cours"] = "No order in progress",
    ["Faire fabriquer par la guilde"] = "Get things crafted by the guild",
    ["Tu as 1 commande en cours"] = "You have 1 order in progress",
    ["Tu as %d commandes en cours"] = "You have %d orders in progress",
    ["Clic : ouvrir les commandes"] = "Click: open orders",
    ["Guilde"] = "Guild",
    ["1 membre en ligne"] = "1 member online",
    ["%d membres en ligne"] = "%d members online",
    ["Tu es 1er au classement PvP de la semaine"] = "You are #1 in this week's PvP ranking",
    ["Tu es %de au classement PvP de la semaine"] = "You are #%d in this week's PvP ranking",
    ["Pas encore classé en PvP cette semaine"] = "Not in this week's PvP ranking yet",
    ["Tu n'es pas dans une guilde"] = "You are not in a guild",
    ["Clic : ouvrir la guilde"] = "Click: open the guild",
    ["LFG"] = "LFG",
    ["Aucun événement prévu"] = "No events planned",
    ["1 joueur cherche un groupe"] = "1 player looking for a group",
    ["%d joueurs cherchent un groupe"] = "%d players looking for a group",
    ["1 événement à venir"] = "1 upcoming event",
    ["%d événements à venir"] = "%d upcoming events",
    ["1 autre événement à venir"] = "1 more upcoming event",
    ["%d autres événements à venir"] = "%d more upcoming events",
    ["Aucun autre événement prévu"] = "No other event planned",
    ["Clic : ouvrir le LFG"] = "Click: open events",
    ["Améliorations"] = "Upgrades",
    ["1 amélioration dans tes sacs"] = "1 upgrade in your bags",
    ["%d améliorations dans tes sacs"] = "%d upgrades in your bags",
    ["Rien de mieux dans tes sacs"] = "Nothing better in your bags",
    ["Selon ta spé %s"] = "Based on your %s spec",
    ["Clic : choisir ta spé et voir tes améliorations"] = "Click: pick your spec and see your upgrades",
    ["Comment faire... ?"] = "How do I...?",
    ["Les gestes utiles, pas à pas"] = "Common tasks, step by step",
    ["Clic : ouvrir Comment faire... ?"] = "Click: open How do I...?",
    ["Module éteint"] = "Module off",
    ["Clic : allumer le module"] = "Click: turn the module on",
    -- what each module does (home card tooltips, welcome window)
    ["Les quêtes de tes donjons dans le bon ordre, avec le GPS."] = "Your dungeon quests in the right order, with the GPS.",
    ["Les Writs les moins chers, la liste d'achat, la tournée de remise et la Faveur du marchand."] = "The cheapest Writs, the shopping list, the turn-in tour and Merchant's Favor.",
    ["Les objets de quête qui ne servent plus, et une place libre en un clic."] = "Quest items you no longer need, and a free slot in one click.",
    ["Faire fabriquer par la guilde, ou fabriquer pour elle."] = "Get things crafted by the guild, or craft for it.",
    ["Les membres, leurs métiers et le classement PvP."] = "Members, their professions and the PvP ranking.",
    ["Les donjons et raids prévus par la guilde, et qui cherche un groupe."] = "Dungeons and raids the guild plans, and who is looking for a group.",
    ["Une flèche verte sur les objets meilleurs que les tiens."] = "A green arrow on items better than yours.",
    -- minimap button
    ["Éteint"] = "Off",
    ["Éteinte"] = "Off",
    ["Clic : la rallumer"] = "Click: turn it back on",
    ["Rien à rendre"] = "Nothing to turn in",
    ["%s, étape %d sur %d"] = "%s, step %d of %d",
    ["%s, terminée"] = "%s, finished",
    ["1 Writ prêt"] = "1 Writ ready",
    ["%d Writs prêts"] = "%d Writs ready",
    ["%d à jeter"] = "%d to throw away",
    ["%d à accepter"] = "%d to accept",
    ["1 cherche un groupe"] = "1 looking for a group",
    ["%d cherchent un groupe"] = "%d looking for a group",
    ["Clic : ouvrir l'Accueil"] = "Click: open Home",
    ["Clic droit : ouvrir un module"] = "Right-click: open a module",
    ["Glisser : déplacer le bouton"] = "Drag: move the button",
    ["Aucun trajet GPS en cours."] = "No GPS route running.",
    ["Nous écrire"] = "Write to us",
    ["Clic : ouvrir le guide de quêtes"] = "Click: open the quest guide",
    ["Clic : arrêter le GPS"] = "Click: stop the GPS",
    -- T-80: my crafter status in the minimap menu
    ["Artisan : %s"] = "Crafter: %s",
    ["Artisan"] = "Crafter",
    ["Clic : passer à %s"] = "Click: switch to %s",
    ["Ce que la guilde voit dans les Commandes."] = "What the guild sees in Orders.",
    ["Automatique pour l'instant : %s."] = "Automatic for now: %s.",
    ["absent (AFK)"] = "away (AFK)",
    ["en file d'attente"] = "queued",
    ["en donjon"] = "in a dungeon",
})

local GAP = 12             -- between blocks (search, now, the activities)
local ROW_GAP = 6          -- between two rows of lines
local SEARCH_ROWS = 3

local function Version()
    local meta = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
    return meta and meta(ADDON, "Version") or "?"
end
-- 12500 -> "12 500" in French, "12,500" in English (DESIGN 4.3): the summary's formatter
-- (root.BigNumber, a no-break space chosen by the addon's language), so every window agrees
local function Thousands(n)
    n = tonumber(n) or 0
    if root.BigNumber then return root.BigNumber(n) end
    local s = tostring(math.floor(math.abs(n) + 0.5))
    local sep = (ns.English and ns.English()) and "," or "\194\160"
    -- a 1-byte mark while the string is reversed, so the 2-byte no-break space keeps its byte order
    local out = s:reverse():gsub("(%d%d%d)", "%1\001"):reverse()
    if out:sub(1, 1) == "\001" then out = out:sub(2) end
    out = out:gsub("\001", sep)
    return (n < 0 and "-" or "") .. out
end
-- "1 objet" / "3 objets": the singular key when n == 1
local function N(n, one, many) return n == 1 and L(one) or string.format(L(many), n) end

-- Each module's name and what it does, in the words of the glossary (home card tooltips, welcome window).
local MODULE_COPY = {
    dungeons = { "Guide de quêtes", "Les quêtes de tes donjons dans le bon ordre, avec le GPS." },
    writs    = { "Writs", "Les Writs les moins chers, la liste d'achat, la tournée de remise et la Faveur du marchand." },
    bags     = { "Sacs", "Les objets de quête qui ne servent plus, et une place libre en un clic." },
    orders   = { "Commandes", "Faire fabriquer par la guilde, ou fabriquer pour elle." },
    guild    = { "Guilde", "Les membres, leurs métiers et le classement PvP." },
    events   = { "LFG", "Les donjons et raids prévus par la guilde, et qui cherche un groupe." },
    upgrades = { "Améliorations", "Une flèche verte sur les objets meilleurs que les tiens." },
}
-- WP.ModuleCopy(key) -> name, description (translated); unknown keys fall back to WP.MODULES.
function WP.ModuleCopy(key)
    local c = MODULE_COPY[key]
    if c then return L(c[1]), L(c[2]) end
    for _, m in ipairs(WP.MODULES or {}) do if m.key == key then return L(m.label), L(m.hint or "") end end
    return key, ""
end

-- ---------------------------------------------------------------- what each module has to say

local function DungeonState()
    if not root.GuideStatus then return nil end
    return root.GuideStatus()   -- five values: never through "a and f()", which keeps only one
end

local function WritState()
    local name = WP.Reputation()
    if not name then return nil end
    local need, goal = WP.RepNeeded()
    local ready, bag = 0, 0
    for _, r in ipairs(WP.Rows()) do
        if r.state == "ready" then ready = ready + 1 elseif r.state == "bag" then bag = bag + 1 end
    end
    return need, goal, ready, bag
end

local function BagCount()
    return WP.Cleaner and WP.Cleaner.Count and WP.Cleaner.Count() or 0
end

-- orders placed for you that nobody has accepted yet
local function OrdersOpen()
    if not WP.Orders then return 0 end
    local _, forMe = WP.Orders.Lists()
    local open = 0
    for _, o in ipairs(forMe or {}) do if o.status == "open" then open = open + 1 end end
    return open
end

local function OpenGuide()
    if DungeonState() then root.ShowGuide() else root.ShowPicker() end
end

-- ---------------------------------------------------------------- the page

-- The Hub (Writs/Options.lua) builds this page into its content column: win is the Hub window,
-- win.inner the page (the scroll child), win.scroll its scroll area. The fields keep the names the
-- old Home window had (win.search, win.now, win.upd, win.cards), the offline tests read them.
local win
local cards = {}         -- one HubRow per WP.HUB entry, by key
local tiles = {}         -- the rows of the smaller tools (city, keys, shared, triage), same frames
local heads = {}         -- one section title per activity, by group key
local CW, COL_W = 628, 306

local function Close() if WP.CloseHub then WP.CloseHub() elseif win then win:Hide() end end
local function Visible() return win ~= nil and WP.HubShows ~= nil and WP.HubShows("home") end

-- -> true when the client knows this texture, false when it does not, nil when it cannot tell (no
-- file ids): the TrySet test of Picker.lua
local function Known(path)
    local f = CreateFrame and CreateFrame("Frame")
    local tex = f and f.CreateTexture and f:CreateTexture()
    if not (tex and tex.GetTextureFileID) then return nil end
    local ok = pcall(tex.SetTexture, tex, path)
    local okI, id = pcall(tex.GetTextureFileID, tex)
    return ok and okI and type(id) == "number" and id ~= 0
end

-- One icon per module, the same on the Home rows, the minimap menu, Settings and the welcome
-- window, so a player learns it once (icon audit G5). Modules are things: painted game icons
-- (design system 2.2). LFG is a group (the battle shout read as a war cry). Upgrades is the one HD
-- glyph: the green arrow the module puts on better items, so its line teaches that very mark.
local ICONS = "Interface\\Icons\\"
WP.MODULE_ICON = {
    dungeons = ICONS .. "INV_Misc_Map_01", writs = ICONS .. "INV_Letter_15", favor = ICONS .. "INV_Crate_04",
    bags = ICONS .. "INV_Misc_Bag_08", orders = ICONS .. "Trade_BlackSmithing", guild = ICONS .. "INV_BannerPVP_01",
    events = ICONS .. "INV_Misc_GroupNeedMore", upgrades = { hd = "arrow_up", color = C.ok },
    help = ICONS .. "INV_Misc_Book_09",
}
-- INV_Misc_GroupNeedMore may be missing on this client: an empty square would then show on Home,
-- the minimap menu, Settings and the welcome window. Probe it once and fall back to the earlier
-- battle shout, but only when the fallback itself is known: a client that cannot tell keeps the
-- group icon
do
    local okP, has = pcall(Known, WP.MODULE_ICON.events)
    if okP and has == false then
        local alt = ICONS .. "Ability_Warrior_BattleShout"
        local okA, altHas = pcall(Known, alt)
        if okA and altHas then WP.MODULE_ICON.events = alt end
    end
end
-- The tools' icons: painted recognition aids (what the tool is about), each with the HD glyph of
-- the tool's own empty state when the client lacks the painted one. Not modules: not in MODULE_ICON.
local function ToolIcon(path, hd)
    local okK, has = pcall(Known, path)
    if okK and has == false then return { hd = hd } end
    return path
end
local TOOL_ICON
local function ToolIcons()
    if TOOL_ICON then return TOOL_ICON end
    local okF, fac = pcall(UnitFactionGroup, "player")
    local capital = (okF and fac == "Alliance") and "Spell_Arcane_TeleportStormWind" or "Spell_Arcane_TeleportOrgrimmar"
    TOOL_ICON = {
        city = ToolIcon(ICONS .. capital, "flag"),
        keys = ToolIcon(ICONS .. "INV_Misc_Key_03", "ring"),
        shared = ToolIcon(ICONS .. "INV_Scroll_03", "group"),
        triage = ToolIcon(ICONS .. "INV_Misc_Note_01", "check"),
    }
    return TOOL_ICON
end
-- WP.PaintModuleIcon(tex, icon): a painted path (white, cropped) or { hd, color } (an HD glyph in
-- its colour). -> true when it drew an HD glyph (the caller insets it in its box)
function WP.PaintModuleIcon(tex, icon)
    if type(icon) == "table" then
        root.SetHDIcon(tex, icon.hd, icon.color or C.fg)
        return true
    end
    S.Painted(tex, icon); tex:SetVertexColor(1, 1, 1)
    return false
end
-- WP.HubIcon(entry) -> the entry's icon: { hd } as given, else a module icon, else a tool icon
function WP.HubIcon(e)
    if type(e.icon) == "table" then return e.icon end
    return WP.MODULE_ICON[e.icon] or ToolIcons()[e.icon] or { hd = "dot" }
end

-- What a click on each line does (the row's tooltip, the minimap menu).
local CLICK_HINT = {
    dungeons = "Clic : ouvrir le guide de quêtes", keys = "Clic : ouvrir le passeport des clés",
    shared = "Clic : voir les quêtes en commun", triage = "Clic : voir les quêtes à abandonner",
    ["goto"] = "Clic : ouvrir Aller à", city = "Clic : ouvrir la tournée en ville",
    writs = "Clic : ouvrir les Writs", favor = "Clic : voir les caisses", orders = "Clic : ouvrir les commandes",
    bags = "Clic : voir les objets à jeter", upgrades = "Clic : choisir ta spé et voir tes améliorations",
    guild = "Clic : ouvrir la guilde", events = "Clic : ouvrir le LFG",
}
function WP.HubClickHint(key) return CLICK_HINT[key] and L(CLICK_HINT[key]) or nil end

-- "Now": one sentence that may wrap, and the view's one primary button. No icon: it only repeated
-- the icon of the module line right below (icon audit, Home).
local function BuildNow()
    local t = CreateFrame("Frame", nil, win.inner)
    t.wlOwned = true
    S.Solid(t, "BACKGROUND", C.cardFill):SetAllPoints()
    S.Border(t, C.cardEdge)
    t.text = S.Text(t, F.body, C.fg)
    t.text:SetJustifyH("LEFT"); t.text:SetJustifyV("MIDDLE")
    t.text:SetPoint("LEFT", t, "LEFT", 12, 0)
    t.go = S.Button(t, "", 0, 28, "primary", function() if t.fn then t.fn() end end)
    t.go:SetPoint("RIGHT", -12, 0)
    -- t:Set(text, label, fn, kind)
    function t:Set(text, label, fn, kind)
        self.text:SetText(text)
        self.go:SetText(label)
        self.go:SetKind(kind or "primary")
        self.fn = fn
    end
    function t:Fit(width)
        local okW, bw = pcall(self.go.GetWidth, self.go)
        bw = (okW and type(bw) == "number") and bw or 100
        local th = S.FitText(self.text, 2, math.max(80, width - 12 - 12 - bw - 12), self)
        local h = math.ceil(math.max(28, th) + 24)
        self:SetHeight(h)
        return h
    end
    return t
end

-- ---------------------------------------------------------------- "Où veux-tu aller ?"

local Layout
local searchRes = {}     -- the last search's results (WP.GoTo.Search), the first 3 shown
local searchState        -- nil (fewer than 2 letters: nothing under the field), "list" or "none"
local pending            -- the debounce timer
local distTicker         -- while results are listed: their distances and nearest places, twice a second

local function Letters(text)
    local G = WP.GoTo
    local okN, n = pcall(G and G.Norm or tostring, text or "")
    if not (okN and type(n) == "string") then n = tostring(text or "") end
    return #(n:gsub("%s", ""))
end

local StartDist, StopDist

local function RunSearch()
    if not (win and win.search) then return end
    local text = win.search:GetText() or ""
    searchRes, searchState = {}, nil
    if Letters(text) >= 2 then
        local ok, res = pcall(WP.GoTo.Search, text)
        searchRes = (ok and type(res) == "table") and res or {}
        searchState = #searchRes > 0 and "list" or "none"
    end
    for i, row in ipairs(win.searchRows) do
        local r = searchState == "list" and searchRes[i]
        row.result = r or nil
        if r then
            local dist = r.dist and WP.GPS and WP.GPS.Distance and WP.GPS.Distance(r.dist) or nil
            row:Set({ name = r.label, detail = r.detail, value = dist })
        end
        row:SetShown(r and true or false)
    end
    local more = win.searchMore
    if searchState == "none" then more:SetText(L("Ouvrir Aller à"))
    else more:SetText(L("Voir tous les résultats")) end
    more:SetShown(searchState == "none" or (searchState == "list" and #searchRes > SEARCH_ROWS))
    win.searchEmpty:SetShown(searchState == "none")
    if searchState == "list" then StartDist() else StopDist() end
    Layout()
end

-- Measures the listed results again as you walk: the distance follows you, and a service or an NPC
-- may move to a nearer place (its detail line then names it). The page is laid out again only when
-- a row changed shape. Stops as soon as Home is not on screen.
local function DistTick()
    if not (win and Visible() and searchState == "list") then StopDist(); return end
    local G = WP.GoTo
    if not (G and G.Repick) then return end
    local relayout = false
    for i, row in ipairs(win.searchRows) do
        local r = row:IsShown() and row.result
        if r and r == searchRes[i] then
            local okR, moved = pcall(G.Repick, r)
            local dist = r.dist and WP.GPS and WP.GPS.Distance and WP.GPS.Distance(r.dist) or nil
            local had = row.value:IsShown() and true or false
            if (okR and moved) or (dist ~= nil) ~= had then
                row:Set({ name = r.label, detail = r.detail, value = dist })
                relayout = true
            elseif dist then
                row.value:SetText(dist)
            end
        end
    end
    if relayout then Layout() end
end
StartDist = function()
    if distTicker or not (C_Timer and C_Timer.NewTicker) then return end
    distTicker = C_Timer.NewTicker(0.5, DistTick)
end
StopDist = function()
    if distTicker then distTicker:Cancel(); distTicker = nil end
end

local function SearchSoon()
    if pending then pending:Cancel(); pending = nil end
    if C_Timer and C_Timer.NewTimer then
        pending = C_Timer.NewTimer(0.15, function() pending = nil; RunSearch() end)
    else
        RunSearch()
    end
end

-- the whole Go to window, with what was typed
local function OpenGoTo(text)
    Close()
    if WP.GoTo and WP.GoTo.Show then WP.GoTo.Show(text or "") end
end

local function SearchEnter(text)
    if pending then pending:Cancel(); pending = nil end
    RunSearch()
    if Letters(text) == 0 then OpenGoTo("") return end           -- recent places, nearest services
    if searchState ~= "list" then OpenGoTo(text) return end       -- 1 letter, or nothing found
    -- a map that cannot be read keeps Home open: GoTo already printed why
    if WP.GoTo.Go(searchRes[1]) then Close() end
end

local function BuildSearch()
    win.search = S.Input(win.inner, CW, { search = true, label = L("Où veux-tu aller ?"),
        placeholder = L("Ex. banque, HV, Mortemines, Forgefer"),
        onChange = function() SearchSoon() end,
        onEnter = SearchEnter })
    win.search:SetScript("OnEnter", function(self) S.Tip(self, { L("Aller à"), L("Entrée : aller au premier résultat") }) end)
    win.search:SetScript("OnLeave", S.HideTip)
    win.searchRows = {}
    for i = 1, SEARCH_ROWS do
        local row = S.ListRow(win.inner, { density = "dense", onClick = function(self)
            if self.result and WP.GoTo.Go(self.result) then Close() end
        end, tip = function(self)
            local r = self.result
            if not r then return nil end
            local t = { r.label }
            if r.detail and r.detail ~= "" then t[#t + 1] = r.detail end
            t[#t + 1] = L("Clic : y aller avec le GPS")
            return t
        end })
        row.valueW = 64
        row:Hide()
        win.searchRows[i] = row
    end
    win.searchMore = S.Button(win.inner, L("Voir tous les résultats"), 0, 24, "ghost", function()
        OpenGoTo(win.search:GetText() or "")
    end)
    win.searchMore:Hide()
    win.searchEmpty = S.Text(win.inner, F.meta, C.muted)
    win.searchEmpty:SetJustifyH("LEFT")
    win.searchEmpty:SetText(L("Aucun lieu trouvé"))
    win.searchEmpty:Hide()
end

local function ClearSearch()
    if pending then pending:Cancel(); pending = nil end
    StopDist()
    if not (win and win.search) then return end
    win.search:SetText(""); win.search:ClearFocus()
    if win.search.Paint then win.search.Paint() end
    searchRes, searchState = {}, nil
    for _, row in ipairs(win.searchRows) do row.result = nil; row:Hide() end
    win.searchMore:Hide(); win.searchEmpty:Hide()
end

-- ---------------------------------------------------------------- layout

-- Stacks what is shown: the search at the top, "now", the update line, then each activity (its
-- title, then its lines two a row, left then right, in the registry's order: a line never moves).
Layout = function()
    if not (win and win.inner) then return end
    local inner = win.inner
    local y = 0
    local function Place(f, h, x, w)
        f:ClearAllPoints()
        f:SetPoint("TOPLEFT", inner, "TOPLEFT", 16 + (x or 0), -(12 + y))
        f:SetWidth(w or CW)
        f:SetHeight(h)
    end
    -- where to go: always at the top, so the field never moves when the strip comes and goes
    if win.search then
        y = y + 17; Place(win.search, 28); y = y + 28
        if searchState == "list" then
            y = y + 8
            local n = 0
            for _, row in ipairs(win.searchRows) do
                if row:IsShown() then
                    if n > 0 then y = y + 2 end
                    local h = row:Fit(CW); Place(row, h); y = y + h
                    n = n + 1
                end
            end
            if win.searchMore:IsShown() then
                y = y + 4
                win.searchMore:ClearAllPoints()
                win.searchMore:SetPoint("TOPRIGHT", inner, "TOPLEFT", 16 + CW, -(12 + y))
                y = y + 24
            end
        elseif searchState == "none" then
            y = y + 8
            local okW, bw = pcall(win.searchMore.GetWidth, win.searchMore)
            bw = (okW and type(bw) == "number") and bw or 100
            local th = S.FitText(win.searchEmpty, 2, math.max(80, CW - bw - 12), inner)
            local h = math.max(24, tonumber(th) or 14)
            win.searchEmpty:ClearAllPoints()
            win.searchEmpty:SetPoint("LEFT", inner, "TOPLEFT", 16, -(12 + y + h / 2))
            win.searchMore:ClearAllPoints()
            win.searchMore:SetPoint("TOPRIGHT", inner, "TOPLEFT", 16 + CW, -(12 + y + (h - 24) / 2))
            y = y + h
        end
        y = y + GAP
    end
    if win.now:IsShown() then
        local h = win.now:Fit(CW); Place(win.now, h); y = y + h + GAP
    end
    if win.upd:IsShown() then
        local h = win.upd:Fit(CW); Place(win.upd, h); y = y + h + GAP
    end
    -- the activities
    local first = true
    for _, g in ipairs(WP.HUB_GROUPS or {}) do
        local rows = {}
        for _, e in ipairs(win.hubOrder or {}) do
            local r = cards[e.key]
            if e.group == g.key and r and r:IsShown() then rows[#rows + 1] = r end
        end
        local head = heads[g.key]
        if head then head:SetShown(#rows > 0) end
        if head and #rows > 0 then
            if not first then y = y + GAP end
            first = false
            Place(head, 24); y = y + 24 + 8
            for i, r in ipairs(rows) do
                local left = (i % 2 == 1)
                Place(r, 46, left and 0 or (COL_W + 16), COL_W)
                if not left or i == #rows then y = y + 46 + ROW_GAP end
            end
            y = y - ROW_GAP
        end
    end
    y = math.ceil(y + 12)
    win.homeH = y
    if win.scroll then win.scroll:SetContentHeight(y + 12) end
end

local upN, bagsDirty = 0, true   -- the upgrades line's bag scan, redone only after the bags changed

-- Home's only event listener: the quest log, the bags and the reputations, refreshed half a second
-- later; registered while the Home page shows, never on a hidden page.
local homeEv = CreateFrame("Frame")
local homeQueued = false
homeEv:SetScript("OnEvent", function(self, event)
    if event == "BAG_UPDATE_DELAYED" then bagsDirty = true end
    if homeQueued or not Visible() then return end
    homeQueued = true
    C_Timer.After(0.5, function() homeQueued = false; WP.RefreshHome() end)
end)
local function HomeEvents(on)
    homeEv:UnregisterAllEvents()
    if not on then return end
    pcall(homeEv.RegisterEvent, homeEv, "QUEST_LOG_UPDATE")
    pcall(homeEv.RegisterEvent, homeEv, "BAG_UPDATE_DELAYED")
    pcall(homeEv.RegisterEvent, homeEv, "UPDATE_FACTION")
end

-- Builds Home into the Hub's page p (again after a language change): the search, "now", the update
-- line, the activity titles and one HubRow per entry of WP.HUB whose files are loaded.
local function Build(p, width, hub)
    win = hub
    CW = math.floor((width or 660) - 32)
    COL_W = math.floor(((width or 660) - 32 - 16) / 2)
    win.scroll, win.inner = p.sa, p
    -- the Hub lays its pages out through p:Layout()
    function p:Layout() Layout(); return win.homeH end
    cards, tiles, heads = {}, {}, {}
    searchRes, searchState = {}, nil
    StopDist()

    -- no focus on open: a focused box would eat the movement keys
    win.search = nil
    if WP.GoTo and WP.GoTo.Search and WP.GoTo.Go then BuildSearch() end

    win.now = BuildNow()
    win.now:Hide()
    win.upd = S.Banner(win.inner, "info", "")
    win.upd:Hide()

    for _, g in ipairs(WP.HUB_GROUPS or {}) do
        local h = S.SectionHeader(win.inner, L(g.label), nil, nil, nil, true)
        h:Hide()
        heads[g.key] = h
    end
    local order = {}
    for _, e in ipairs(WP.HUB and WP.HubEntries() or {}) do
        order[#order + 1] = e
        local r = S.HubRow(win.inner, function()
            if e.inHub then e.open() else Close(); e.open() end
        end)
        r.key, r.module, r.entry = e.key, e.module, e
        r:SetIcon(WP.HubIcon(e))
        if e.module or e.key == "favor" then
            local _, desc = WP.ModuleCopy(e.key)
            r.desc = desc ~= "" and desc or nil
        end
        if e.key == "favor" then r.desc = L("Les caisses les moins chères et où les rendre") end
        r.onTurnOn = function() WP.HubTurnOn(e); WP.RefreshHome() end
        if e.settings then
            r:SetOnRightClick(function() WP.OpenHub(e.settings, e.anchor) end, L("Clic droit : réglages"))
        end
        r:Set(L(e.label), "", WP.HubClickHint(e.key))
        cards[e.key] = r
        if e.key == "city" or e.key == "keys" or e.key == "shared" or e.key == "triage" then tiles[e.key] = r end
    end
    win.hubOrder = order
    win.cards, win.tiles, win.heads = cards, tiles, heads

    if not win.homeHooked then
        win.homeHooked = true
        win:HookScript("OnHide", function() ClearSearch() end)
    end
    -- the states change with the quest log, the bags and the reputations: one listener for the
    -- session (a rebuild never adds one), its events registered only while this page shows
    homeEv:UnregisterAllEvents()
    local holder = p.holder or p
    holder:HookScript("OnShow", function() if win and win.inner == p then HomeEvents(true) end end)
    holder:HookScript("OnHide", function() if win and win.inner == p then HomeEvents(false) end end)
    if Visible() then HomeEvents(true) end
end

-- The key a dungeon you picked asks for and you do not have yet. -> the reason line, and whether
-- any picked dungeon asks for a key at all
local function KeyNeeded(K)
    local sel = WLDTDB and WLDTDB.sel
    if not (K and K.KeysFor and K.Status and type(sel) == "table") then return nil, false end
    local any, reason = false, nil
    local keys = {}
    for dkey, on in pairs(sel) do
        if on and root.D and root.D[dkey] and not root.D[dkey].cq then keys[#keys + 1] = dkey end
    end
    table.sort(keys)
    for _, dkey in ipairs(keys) do
        local okF, list = pcall(K.KeysFor, dkey)
        local k = okF and type(list) == "table" and list[1]
        if k then
            any = true
            if k.need and not reason then
                local okS, st = pcall(K.Status, k)
                local state = okS and type(st) == "table" and st.state
                -- "na": a chain this character cannot do; nothing to ask of the player
                if state and state ~= "have" and state ~= "na" then
                    local okN, kn = pcall(K.Name, k)
                    local okD, dn = pcall(K.DName, dkey)
                    reason = string.format(L("Il te faut %s pour entrer dans %s."),
                        (okN and type(kn) == "string") and kn or "?", (okD and type(dn) == "string") and dn or dkey)
                end
            end
        end
    end
    return reason, any
end

-- a row's call, when the row exists (its files may not be loaded)
local function Put(key, method, ...)
    local r = cards[key]
    if r then r[method](r, ...) end
end

local function Refresh()
    if not win then return end
    local On = WP.ModuleOn
    win.subtitle:SetText(string.format(L("%s, niv. %d"), UnitName("player") or "", UnitLevel("player") or 0))

    -- 1. every state first: the strip and the lines share them

    local dLabel, cur, total, dFinished, nextStep = DungeonState()
    local need, goal, ready, bag = WritState()
    ready, bag = ready or 0, bag or 0
    local favor = WP.FavorNow and WP.FavorNow()
    local nBag = On("bags") and BagCount() or 0
    local open, running = 0, 0
    if WP.Orders then
        open = OrdersOpen()
        for _, o in ipairs(WP.Orders.Lists() or {}) do
            if o.status == "open" or o.status == "accepted" or o.status == "crafted" then running = running + 1 end
        end
    end
    local lfg, nEvents, nextE = 0, 0, nil
    if WP.EventList then
        local list = WP.EventList()
        nEvents = #list
        for _, e in ipairs(list) do if e.status == "open" and e.when >= time() - 1800 then nextE = e; break end end
        lfg = WP.LFGList and #WP.LFGList() or 0
    end

    -- the tools: every call is guarded, a broken tool only loses its state line
    local CT = WP.CityTour
    local cityOpen, inCity = 0, false
    if CT and CT.CurrentCity and CT.Tasks then
        local ok, city = pcall(CT.CurrentCity)
        if ok and city and CT.IsOn and CT.IsOn() then
            inCity = true
            local okT, _, n = pcall(CT.Tasks)
            cityOpen = (okT and type(n) == "number") and n or 0
        end
    end
    local tourOn = false
    if CT and CT.TourOn then local okR, v = pcall(CT.TourOn); tourOn = okR and v and true or false end
    local K = WP.Keys
    local keyLine
    if K and K.Summary then
        -- the passport's own line: one count, said the same way in both places
        local ok, s = pcall(K.Summary)
        if ok and type(s) == "string" then keyLine = s end
    elseif K and K.LIST and K.Status then
        local ok, have = pcall(function()
            local n = 0
            for _, k in ipairs(K.LIST) do if K.Status(k).state == "have" then n = n + 1 end end
            return n
        end)
        if ok then
            keyLine = have == 0 and string.format(L("Aucune clé pour l'instant (%d en tout)"), #K.LIST)
                or have == 1 and string.format(L("1 clé sur %d"), #K.LIST) or string.format(L("%d clés sur %d"), have, #K.LIST)
        end
    end
    local Sh = WP.Shared
    local nShared = 0
    if Sh and Sh.Dungeons then
        local ok, list = pcall(Sh.Dungeons)
        nShared = (ok and type(list) == "table") and #list or 0
    end
    local Tr = WP.Triage
    local triageN, logN, logMax = 0, 0, 0
    if Tr and On("triage") then
        local ok, n, max = pcall(Tr.LogCount)
        if ok then logN, logMax = tonumber(n) or 0, tonumber(max) or 0 end
        local okC, c = pcall(Tr.Count)
        triageN = (okC and type(c) == "number") and c or 0
    end
    local triageSoon = triageN > 0 and logMax > 0 and logMax - logN <= 2

    -- 2. "now": only what a line cannot do (start the GPS, act before a time, open a tool)

    local nowKey
    if On("writs") and ready > 0 then nowKey = "writs"
    elseif On("events") and nextE and nextE.when - time() < 3600 then nowKey = "event"
    elseif cityOpen > 0 and not tourOn then nowKey = "city"
    elseif triageSoon then nowKey = "triage"
    elseif WP.GPS and WP.GPS.Active() then nowKey = "gps" end
    local t = win.now
    if nowKey == "writs" then
        t:Set(N(ready, "1 Writ est prêt à rendre.", "%d Writs sont prêts à rendre."), L("Y aller"), function()
            Close()
            -- the tour already runs: on to the next stop; otherwise start it
            if WLWritsCharDB and WLWritsCharDB.gps then WP.GoNext() else WP.ToggleGPS() end
        end)
    elseif nowKey == "event" then
        local mins = math.ceil((nextE.when - time()) / 60)
        t:Set(mins > 0 and string.format(L("%s commence dans %d min."), nextE.title, mins) or string.format(L("%s a commencé."), nextE.title),
            L("Voir l'événement"), function() Close(); if WP.ToggleEvents then WP.ToggleEvents() end end)
    elseif nowKey == "city" then
        t:Set(N(cityOpen, "1 chose à faire dans cette ville.", "%d choses à faire dans cette ville."), L("Voir la tournée"),
            function() Close(); WP.CityTour.Show() end)
    elseif nowKey == "triage" then
        t:Set(L("Ton journal de quêtes est presque plein."), L("Trier le journal"),
            function() Close(); WP.Triage.Show() end)
    elseif nowKey == "gps" then
        -- only a running GPS: a quiet line, its stop is not the main thing to do
        local dest = WP.GPS.DestName and WP.GPS.DestName()
        t:Set((type(dest) == "string" and dest ~= "") and string.format(L("Le GPS te guide vers %s."), dest) or L("Le GPS te guide."), L("Arrêter le GPS"),
            function() WP.StopGPS(); WP.RefreshHome() end, "secondary")
    end
    t:SetShown(nowKey ~= nil)

    -- 3. the lines: state only, each fact said once on the page

    if dLabel and not dFinished then
        Put("dungeons", "Show2", { title = L("Guide de quêtes"), line1 = dLabel,
            line2 = (nextStep and nextStep ~= "") and string.format(L("Prochaine étape : %s"), nextStep) or nil,
            pill = string.format(L("Étape %d sur %d"), cur or 1, total or 1), hint = L("Clic : ouvrir le guide") })
    elseif dLabel then
        Put("dungeons", "Show2", { title = L("Guide de quêtes"), line1 = dLabel, line2 = L("Choisis ton prochain guide."),
            pill = L("Terminée"), lineColor = C.ok, hint = L("Clic : choisir un guide") })
    else
        Put("dungeons", "Show2", { title = L("Guide de quêtes"), line1 = L("Aucun guide choisi"),
            line2 = L("Donjons, raids et quêtes de classe, depuis là où tu es."), hint = L("Clic : choisir un guide") })
    end

    -- Writs: what waits first (the strip says the ready ones when it shows), then the reputation
    if need then
        local rep = need > 0 and (need == 1 and string.format(L("Encore 1 point avant %s"), WP.Reaction(goal))
            or string.format(L("Encore %s points avant %s"), Thousands(need), WP.Reaction(goal)))
            or string.format(L("%s atteint"), WP.Reaction(goal))
        local parts = {}
        if ready > 0 and nowKey ~= "writs" then parts[#parts + 1] = N(ready, "1 Writ prêt à rendre", "%d Writs prêts à rendre") end
        if bag > 0 then parts[#parts + 1] = N(bag, "1 enveloppe à ouvrir", "%d enveloppes à ouvrir") end
        if #parts > 0 then
            Put("writs", "Show2", { title = L("Writs"), line1 = table.concat(parts, " · "), lineColor = C.ok, line2 = rep,
                hint = L("Clic : ouvrir les Writs") })
        else
            Put("writs", "Show2", { title = L("Writs"), line1 = rep, line2 = ready == 0 and L("Rien à rendre pour l'instant") or nil,
                hint = L("Clic : ouvrir les Writs") })
        end
    else
        Put("writs", "Show2", { title = L("Writs"), line1 = L("Faction pas encore vue"), line2 = L("Parle à un PNJ de cette faction pour qu'elle apparaisse."),
            lineColor = C.muted, hint = L("Clic : ouvrir les Writs") })
    end

    Put("favor", "Show2", { title = L("Faveur du marchand"),
        line1 = favor and (favor == 1 and L("1 point de Faveur") or string.format(L("%s points de Faveur"), Thousands(favor))) or L("Pas encore de Faveur"),
        hint = L("Clic : voir les caisses") })

    Put("bags", "Show2", { title = L("Sacs"),
        line1 = nBag > 0 and N(nBag, "1 objet de quête à jeter", "%d objets de quête à jeter") or L("Rien à jeter"),
        lineColor = nBag > 0 and C.warn or C.muted, hint = L("Clic : voir les objets à jeter") })

    local runLine = running > 0 and N(running, "Tu as 1 commande en cours", "Tu as %d commandes en cours") or nil
    if open > 0 then
        Put("orders", "Show2", { title = L("Commandes"), line1 = N(open, "1 commande à accepter", "%d commandes à accepter"),
            lineColor = C.warn, line2 = runLine, hint = L("Clic : ouvrir les commandes") })
    else
        Put("orders", "Show2", { title = L("Commandes"), line1 = runLine or L("Aucune commande en cours"),
            lineColor = C.muted, hint = L("Clic : ouvrir les commandes") })
    end

    -- guild: who is on, and where you stand in this week's PvP ranking
    if IsInGuild and IsInGuild() and WP.GuildRoster then
        local _, online = WP.GuildRoster(true)
        online = online or 0
        local pos
        for i, e in ipairs(WP.GuildRanking and WP.GuildRanking(true) or {}) do if e.name == UnitName("player") then pos = i end end
        Put("guild", "Show2", { title = L("Guilde"), line1 = N(online, "1 membre en ligne", "%d membres en ligne"),
            line2 = pos and (pos == 1 and L("Tu es 1er au classement PvP de la semaine") or string.format(L("Tu es %de au classement PvP de la semaine"), pos))
                or L("Pas encore classé en PvP cette semaine"),
            hint = L("Clic : ouvrir la guilde") })
    else
        Put("guild", "Show2", { title = L("Guilde"), line1 = L("Tu n'es pas dans une guilde"), lineColor = C.muted, hint = L("Clic : ouvrir la guilde") })
    end

    -- events: the next one, and who looks for a group now; the strip already names an event about
    -- to start, so the line says what comes after it
    local lfgLine = lfg > 0 and N(lfg, "1 joueur cherche un groupe", "%d joueurs cherchent un groupe") or nil
    if nowKey == "event" then
        local l1 = lfgLine or (nEvents > 1 and N(nEvents - 1, "1 autre événement à venir", "%d autres événements à venir")) or nil
        Put("events", "Show2", { title = L("LFG"), line1 = l1 or L("Aucun autre événement prévu"),
            lineColor = C.muted, hint = L("Clic : ouvrir le LFG") })
    else
        Put("events", "Show2", { title = L("LFG"),
            line1 = nextE and (tostring(nextE.title) .. " · " .. WP.EventWhen(nextE.when)) or L("Aucun événement prévu"),
            lineColor = C.muted,
            line2 = lfgLine or (nEvents > 0 and N(nEvents, "1 événement à venir", "%d événements à venir") or nil),
            hint = L("Clic : ouvrir le LFG") })
    end

    -- upgrades: how many bag items are better than what you wear, for which spec
    local Wt = WP.Weights
    if Wt then
        local GetLink = C_Container and C_Container.GetContainerItemLink
        if bagsDirty and GetLink and WP.UpgradeCheck then
            -- every bag slot is checked: only after the bags changed, not on every refresh
            upN = 0
            for bagID = 0, NUM_BAG_SLOTS or 4 do
                for slot = 1, (C_Container.GetContainerNumSlots(bagID) or 0) do
                    local link = GetLink(bagID, slot)
                    if link and WP.UpgradeCheck(link).up then upN = upN + 1 end
                end
            end
            bagsDirty = false
        end
        local okS, specName = pcall(Wt.SpecName)
        specName = (okS and type(specName) == "string" and specName ~= "") and specName or nil
        Put("upgrades", "Show2", { title = L("Améliorations"),
            line1 = upN > 0 and N(upN, "1 amélioration dans tes sacs", "%d améliorations dans tes sacs") or L("Rien de mieux dans tes sacs"),
            lineColor = upN > 0 and C.ok or C.muted,
            line2 = specName and string.format(L("Selon ta spé %s"), specName) or nil,
            hint = L("Clic : choisir ta spé et voir tes améliorations") })
    else
        Put("upgrades", "Show2", { title = L("Améliorations"), line1 = L("Rien de mieux dans tes sacs"), hint = L("Clic : choisir ta spé et voir tes améliorations") })
    end

    -- the tools: a dot when one has something to do now
    Put("goto", "Set", L("Aller à"), L("Un lieu, un PNJ, une ville : le GPS t'y mène"), L("Clic : ouvrir Aller à"))
    local cityDot = cityOpen > 0 and not tourOn
    Put("city", "Set", L("Tournée en ville"),
        cityOpen > 0 and N(cityOpen, "1 chose à faire dans cette ville", "%d choses à faire dans cette ville")
            or L("Ce qu'il y a à faire en arrivant dans une capitale"), L("Clic : ouvrir la tournée en ville"),
        cityDot, N(cityOpen, "1 chose à faire dans cette ville", "%d choses à faire dans cette ville"))
    local keyReason
    if K and On("keys") then keyReason = KeyNeeded(K) end
    Put("keys", "Set", L("Passeport des clés"), keyLine, L("Clic : ouvrir le passeport des clés"), keyReason ~= nil, keyReason)
    Put("shared", "Set", L("Quêtes en commun"),
        nShared > 0 and (nShared == 1 and L("1 donjon en commun") or string.format(L("%d donjons en commun"), nShared))
            or L("Les membres qui font les mêmes donjons que toi"), L("Clic : voir les quêtes en commun"))
    local triLine = string.format(L("Journal : %d quêtes sur %d"), logN, logMax)
    if triageN > 0 then triLine = N(triageN, "1 quête à abandonner", "%d quêtes à abandonner") .. " · " .. triLine end
    local triDot = triageSoon or (logMax > 0 and logN >= logMax)
    Put("triage", "Set", L("Tri du journal"), triLine, L("Clic : voir les quêtes à abandonner"),
        triDot, L("Ton journal de quêtes est presque plein."))

    -- switched off: dimmed with "Éteint", a click turns it back on; every line keeps its place
    for _, e in ipairs(win.hubOrder or {}) do
        local r = cards[e.key]
        if r then
            r:Show()
            if not WP.HubEntryOn(e) then
                -- the city tour is not a module: its own words
                if e.module then r:ShowOff(L(e.label))
                else r:ShowOff(L(e.label), L("Éteinte"), L("Clic : la rallumer")) end
            end
        end
    end

    -- a newer version seen on another player's copy
    local newer = WP.UpdateAvailable and WP.UpdateAvailable()
    if newer and WP.UpdateText then win.upd:SetText(WP.UpdateText(newer), "info") end
    win.upd:SetShown(newer ~= nil and WP.UpdateText ~= nil)

    Layout()
end

-- The Hub's Home page (Writs/Options.lua calls it): Build(p, width, hub) once per build of the
-- Hub, Refresh(opening) each time Home shows (opening: the bags are scanned again), Layout().
WP.HomePage = {
    Build = Build,
    Refresh = function(opening)
        if opening then bagsDirty = true; HomeEvents(Visible()) end
        Refresh()
    end,
    Layout = function() Layout() end,
}

-- Redraws Home's states, only while Home is on screen (never for a hidden page).
function WP.RefreshHome()
    if not Visible() then return end
    Refresh()
    -- wrapped lines measure right once their width is applied: once more on the next frame
    if C_Timer and C_Timer.After then C_Timer.After(0, function() if Visible() then Layout() end end) end
end

function WP.OpenHome()
    if WP.OpenHub then WP.OpenHub("home") end
end

-- /wlh and the minimap button: Home, or closes the window when Home already shows.
function WP.ToggleHome()
    if Visible() then Close() else WP.OpenHome() end
end

-- ---------------------------------------------------------------- minimap button

-- My crafter status (Orders, T-60): what the guild sees, and the status a click picks next
-- (Available, Busy, Away, round). nil when the Orders module is off or not loaded.
local NEXT_STATUS = { a = "b", b = "o", o = "a" }
local WHY_AUTO = { afk = "absent (AFK)", queue = "en file d'attente", inst = "en donjon" }
local function CrafterStatus()
    local O = WP.Orders
    if not (O and O.MyStatus and O.StatusWord and O.BaseStatus and O.CycleStatus) or not WP.ModuleOn("orders") then return nil end
    local ok, s, why = pcall(O.MyStatus)
    if not ok then return nil end
    local base = O.BaseStatus()
    return O.StatusWord(s) or O.StatusWord(base) or "?", O.StatusWord(NEXT_STATUS[base] or "a"), why and L(WHY_AUTO[why] or "") or nil, s
end
local STATUS_COLOR = { a = "ok", b = "warn", d = "info", o = "faint" }

-- Tooltip: where you stand first, then what the mouse does.
function WP.MinimapTooltip(owner)
    local tt = GameTooltip
    tt:SetOwner(owner, "ANCHOR_LEFT")
    tt:AddLine("WL Helper", C.fg[1], C.fg[2], C.fg[3])
    local function Row(label, value, col)
        col = col or C.fg
        tt:AddDoubleLine(label, value, C.muted[1], C.muted[2], C.muted[3], col[1], col[2], col[3])
    end
    local label, cur, total, finished = DungeonState()
    if not WP.ModuleOn("dungeons") then Row(L("Guide de quêtes"), L("Éteint"), C.faint)
    elseif label then Row(L("Guide de quêtes"), finished and string.format(L("%s, terminée"), label) or string.format(L("%s, étape %d sur %d"), label, cur or 1, total or 1))
    else Row(L("Guide de quêtes"), L("Aucun guide choisi"), C.muted) end
    local need, _, ready = WritState()
    if not WP.ModuleOn("writs") then Row(L("Writs"), L("Éteint"), C.faint)
    elseif need then Row(L("Writs"), ready > 0 and N(ready, "1 Writ prêt", "%d Writs prêts") or L("Rien à rendre"), ready > 0 and C.ok or C.fg) end
    if not WP.ModuleOn("bags") then Row(L("Sacs"), L("Éteint"), C.faint)
    else
        local n = BagCount()
        Row(L("Sacs"), n > 0 and string.format(L("%d à jeter"), n) or L("Rien à jeter"), n > 0 and C.warn or C.fg)
    end
    local open = WP.ModuleOn("orders") and OrdersOpen() or 0
    if open > 0 then Row(L("Commandes"), string.format(L("%d à accepter"), open), C.ok) end
    local word, _, _, st = CrafterStatus()
    if word then Row(L("Artisan"), word, C[STATUS_COLOR[st] or "fg"] or C.fg) end
    local lfg = WP.ModuleOn("events") and WP.LFGList and #WP.LFGList() or 0
    if lfg > 0 then Row(L("LFG"), N(lfg, "1 cherche un groupe", "%d cherchent un groupe")) end
    local newer = WP.UpdateAvailable and WP.UpdateAvailable()
    if newer and WP.UpdateText then
        tt:AddLine(" ")
        tt:AddLine(WP.UpdateText(newer), C.info[1], C.info[2], C.info[3], true)
    end
    tt:AddLine(" ")
    local a = C.accentSoft
    tt:AddLine(L("Clic : ouvrir l'Accueil"), a[1], a[2], a[3])
    tt:AddLine(L("Clic droit : ouvrir un module"), a[1], a[2], a[3])
    tt:AddLine(L("Glisser : déplacer le bouton"), a[1], a[2], a[3])
    tt:Show()
end

-- Right-click menu: straight to a module. A list in the dropdown style (24 px rows, icons).
local menu
local function MenuRow(parent, y, icon, text, onClick, disabledReason, hint)
    local b = CreateFrame("Button", nil, parent)
    b.wlOwned = true
    b:SetHeight(24)
    b:SetPoint("TOPLEFT", 1, y); b:SetPoint("TOPRIGHT", -1, y)
    b.hl = S.Solid(b, "BACKGROUND", C.hoverFill); b.hl:SetAllPoints(); b.hl:SetAlpha(0)
    b.press = S.Solid(b, "BORDER", C.pressFill); b.press:SetAllPoints(); b.press:Hide()
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetSize(16, 16); b.icon:SetPoint("LEFT", 8, 0)
    b.hd = type(icon) == "table"
    -- a glyph with its own colour (the upgrades arrow) keeps it; the others are muted, fg on hover
    b.hdColor = b.hd and icon.color or nil
    if b.hd then root.SetHDIcon(b.icon, icon.hd, b.hdColor or C.muted) else S.Painted(b.icon, icon) end
    b.label = S.Text(b, F.label, C.fg)
    b.label:SetPoint("LEFT", b.icon, "RIGHT", 8, 0); b.label:SetPoint("RIGHT", -8, 0)
    b.label:SetJustifyH("LEFT")
    b.label:SetText(text)
    S.ClampLabel(b.label, text, b)
    b.disabledReason = disabledReason
    local function Paint()
        local on = b:IsEnabled() ~= false
        b:SetAlpha(on and (b.off and 0.45 or 1) or C.disabledAlpha)
        if b.hd and not b.hdColor then local c = (b.hov and on) and C.fg or C.muted; b.icon:SetVertexColor(c[1], c[2], c[3]) end
    end
    b:SetScript("OnEnter", function(self)
        self.hov = true
        if self:IsEnabled() ~= false then root.Tween(self, 0, 1, 0.10, function(v) self.hl:SetAlpha(v) end) end
        Paint()
        if self:IsEnabled() == false then
            if self.disabledReason then S.Tip(self, { text, self.disabledReason }) end
        elseif self.off then
            S.Tip(self, { text, L("Module éteint"), L("Clic : allumer le module") })
        elseif hint then
            S.Tip(self, { text, hint })
        end
    end)
    b:SetScript("OnLeave", function(self)
        self.hov = nil
        root.Tween(self, 1, 0, 0.10, function(v) self.hl:SetAlpha(v) end)
        Paint(); S.HideTip()
    end)
    b:SetScript("OnMouseDown", function(self) if self:IsEnabled() ~= false then self.press:Show() end end)
    b:SetScript("OnMouseUp", function(self) self.press:Hide() end)
    b:SetScript("OnEnable", Paint); b:SetScript("OnDisable", Paint)
    b:SetScript("OnClick", function(self)
        if self.keep then onClick(self); return end
        menu:Hide()
        if self.off then
            if self.entry then WP.HubTurnOn(self.entry) elseif self.module then WP.SetModule(self.module, true) end
        end
        onClick()
    end)
    function b:SetOff(off) self.off = off and true or nil; Paint() end
    Paint()
    return b
end

function WP.MinimapMenu(owner)
    -- built in the language of its first opening: built again after a language change
    if menu and menu.lang ~= L("Réglages") then
        menu:Hide(); menu:SetScript("OnUpdate", nil); menu = nil
    end
    if not menu then
        menu = CreateFrame("Frame", "WLHelperMinimapMenu", UIParent)
        menu.wlOwned = true
        -- above minimap button bars and every window
        menu:SetFrameStrata("TOOLTIP"); menu:SetFrameLevel(50); menu:SetClampedToScreen(true); menu:EnableMouse(true)
        S.Solid(menu, "BACKGROUND", C.panel, 0.98):SetAllPoints()
        S.Border(menu, C.cardEdge)
        if not tContains or not tContains(UISpecialFrames, "WLHelperMinimapMenu") then
            tinsert(UISpecialFrames, "WLHelperMinimapMenu")
        end
        -- { icon, label, onClick, module (dimmed when off), key in menu.buttons, why disabled, click
        -- hint, hub entry }: the Hub's windows by activity (WP.HUB, the order of Home), a rule
        -- between activities, then the GPS, help, settings and contact
        local items = {}
        -- my crafter status: a click picks the next one, the menu stays open
        if WP.Orders and WP.Orders.CycleStatus then
            items[#items + 1] = { { hd = "hammer" }, string.format(L("Artisan : %s"), "?"), function(self)
                -- turned on from the menu (module off): the module only, no status change
                if not self then return end
                pcall(WP.Orders.CycleStatus)
                if self.Sync then self:Sync(); if self.tipLines then S.Tip(self, self.tipLines) end end
            end, nil, "crafter" }
            items[#items + 1] = false
        end
        for _, g in ipairs(WP.HUB_GROUPS or {}) do
            local list = WP.HubEntries and WP.HubEntries(g.key) or {}
            if #list > 0 and #items > 0 then items[#items + 1] = false end
            for _, e in ipairs(list) do
                items[#items + 1] = { WP.HubIcon(e), L(e.label), e.open, e.module, e.key, nil, WP.HubClickHint(e.key), e }
            end
        end
        if #items > 0 then items[#items + 1] = false end
        items[#items + 1] = { { hd = root.ARROW }, L("Arrêter le GPS"), function() WP.StopGPS() end, nil, "gps", L("Aucun trajet GPS en cours."), L("Clic : arrêter le GPS") }
        items[#items + 1] = { WP.MODULE_ICON.help, L("Comment faire... ?"), function() if WP.Help then WP.Help.Toggle() end end, nil, nil, nil, L("Clic : ouvrir Comment faire... ?") }
        items[#items + 1] = { { hd = "gear" }, L("Réglages"), function() if WP.OpenHub then WP.OpenHub("general") end end, nil, nil, nil, L("Clic : ouvrir les réglages") }
        items[#items + 1] = { { hd = "mail" }, L("Nous écrire"), function() if WP.Feedback then WP.Feedback("idea") end end, nil, nil, nil, L("Clic : ouvrir le formulaire pour nous écrire") }
        local y = -4
        menu.buttons, menu.rows = {}, {}
        for _, it in ipairs(items) do
            if it then
                local b = MenuRow(menu, y, it[1], it[2], it[3], it[6], it[7])
                b.module, b.entry = it[4], it[8]
                menu.rows[#menu.rows + 1] = b
                local key = it[5] or it[4]
                if key then menu.buttons[key] = b end
                y = y - 24
            else
                local line = S.Rule(menu)
                line:SetPoint("TOPLEFT", 8, y - 4); line:SetPoint("TOPRIGHT", -8, y - 4)
                y = y - 9
            end
        end
        menu:SetSize(208, -y + 4)
        menu.lang = L("Réglages")
        local cb = menu.buttons.crafter
        if cb then
            cb.keep = true
            function cb:Sync()
                local word, nxt, why = CrafterStatus()
                local text = string.format(L("Artisan : %s"), word or L("Éteint"))
                self.label:SetText(text)
                self.label.wlFull = text
                self.tipLines = { text, L("Ce que la guilde voit dans les Commandes.") }
                if why then self.tipLines[#self.tipLines + 1] = string.format(L("Automatique pour l'instant : %s."), why) end
                if word and nxt then self.tipLines[#self.tipLines + 1] = string.format(L("Clic : passer à %s"), nxt) end
            end
            -- its tooltip follows the status (the row's own one has no hint)
            cb:HookScript("OnEnter", function(self)
                if not self.off and self:IsEnabled() ~= false and self.tipLines then S.Tip(self, self.tipLines) end
            end)
        end
        -- closes when the mouse has left it for a moment
        menu:SetScript("OnUpdate", function(self, dt)
            if self:IsMouseOver() or (self.owner and self.owner:IsMouseOver()) then self.away = 0; return end
            self.away = (self.away or 0) + dt
            if self.away > 1.5 then self:Hide() end
        end)
    end
    if menu:IsShown() then menu:Hide(); return end
    menu.owner = owner; menu.away = 0
    menu.buttons.gps:SetEnabled(WP.GPS.Active() and true or false)
    if menu.buttons.crafter then
        local on = WP.ModuleOn("orders")
        menu.buttons.crafter:SetOff(not on)
        menu.buttons.crafter.keep = on and true or nil
        menu.buttons.crafter.module = (not on) and "orders" or nil
        menu.buttons.crafter:Sync()
    end
    for _, b in ipairs(menu.rows) do
        if b.entry then b:SetOff(not WP.HubEntryOn(b.entry))
        elseif b.module then b:SetOff(not WP.ModuleOn(b.module)) end
    end
    menu:ClearAllPoints()
    menu:SetPoint("TOPRIGHT", owner, "BOTTOMLEFT", 4, 4)
    GameTooltip:Hide()
    menu:Show()
end
