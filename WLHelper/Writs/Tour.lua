-- Writs/Tour.lua: the Welcome page of the Hub and the guided tour (T-62).
-- Welcome (WP.WelcomePage, a page of Writs/Options.lua): what is worth setting up, by activity, in
-- any order. Each line: the thing, one sentence, a button that opens the right place and lights the
-- control (Help.lua's WP.ShowMe), and a check once it is set (read from the saved settings, or a
-- "C'est fait" click, kept per character). A progress bar at the top, with the tour's button.
-- The tour (WP.Tour): coach-mark bubbles on the real frames (the Hub's nav, the guide's header
-- buttons, the GPS arrow and its cast icon, the boss portraits, the crafter card, the Writs budget,
-- the minimap button...). Each bubble: a title, one or two sentences, "n sur N", Précédent /
-- Suivant / Passer. It opens the window a step needs first, skips a step whose frame is missing or
-- hidden, never runs in combat (it waits for the end of the fight) and Escape ends it. One tour
-- per activity, or all of them in a row: from the Welcome page, the Help window, the end of the
-- quick start (Writs/Setup.lua) and /wlh visite (/wlh tour).
-- The quick start (Writs/Setup.lua, /wlh setup) stays the first screen at the first login; this page
-- is where everything is found again afterwards (/wlh bienvenue).
local ADDON, root = ...
root.Writs = root.Writs or {}
local ns = root.Writs
local WP = ns.WP
local L = ns.L
local S = ns.S
local C = S.C
local F = S.F

ns.AddEnglish({
    -- the page (its nav item, Writs/Options.lua)
    ["Bienvenue"] = "Welcome",
    ["Tout régler pas à pas, et la visite guidée."] = "Set everything up step by step, and the guided tour.",
    ["Clic : ouvrir la page Bienvenue"] = "Click: open Welcome",
    ["Ta mise en route"] = "Getting set up",
    ["Dans l'ordre que tu veux. Une étape se coche toute seule quand c'est réglé, ou avec « C'est fait »."] = "In any order. A step ticks itself once it's set, or with \"Done\".",
    ["Tout est réglé. La visite reste là si tu veux revoir où est chaque chose."] = "All set. The tour is still here if you want to see where everything is again.",
    ["Rouvrir l'écran de bienvenue"] = "Reopen the welcome screen",
    ["Clic : rouvrir l'écran de bienvenue (modules, spé, clics)"] = "Click: reopen the welcome screen (modules, spec, clicks)",
    ["C'est fait"] = "Done",
    ["Clic : cocher cette étape"] = "Click: tick this step",
    ["Décocher"] = "Untick",
    ["Clic : remettre cette étape à faire"] = "Click: put this step back on the list",
    ["Réglé"] = "Set",
    ["Visiter"] = "Tour it",
    ["Refaire la visite"] = "Take the tour again",
    ["Mots connus après /wlh visite : %s."] = "Words known after /wlh tour: %s.",
    ["debut, quetes, gps, objets, guilde"] = "start, quests, travel, items, guild",
    ["Clic : la visite de cette activité"] = "Click: the tour of this activity",
    ["Clic : ouvrir et montrer où régler"] = "Click: open it and show where to set it",
    -- the bubble
    ["Précédent"] = "Back",
    ["Suivant"] = "Next",
    ["%d sur %d"] = "%d of %d",
    ["Clic : arrêter la visite (Échap aussi)"] = "Click: stop the tour (Escape too)",
    -- chat lines
    ["La visite commencera à la fin du combat."] = "The tour will start when the fight is over.",
    ["Visite en pause pendant le combat : elle reprend à la fin du combat."] = "Tour paused for the fight: it picks up again when the fight is over.",
    ["Visite terminée. La page Bienvenue de la fenêtre WL Helper reprend chaque réglage pas à pas."] = "Tour finished. The Welcome page of the WL Helper window goes through every setting step by step.",
    ["Visite arrêtée. Tape /wlh visite pour la refaire."] = "Tour stopped. Type /wlh tour to take it again.",
    ["Rien à montrer pour l'instant dans cette activité. Allume son module ou ouvre ses fenêtres, puis relance la visite."] = "Nothing to show in this activity yet. Switch its module on or open its windows, then start the tour again.",
    -- the steps: getting started
    ["Le menu"] = "The menu",
    ["À gauche, l'Accueil puis chaque activité avec ses réglages. Bienvenue, juste dessous, reprend la mise en route."] = "On the left, Home, then each activity with its settings. Welcome, just below, goes through the setup again.",
    ["Tout ce qui s'ouvre"] = "Everything you can open",
    ["Une carte par activité : où tu en es, un bouton pour continuer, puis ses fenêtres. Un clic ouvre, un clic droit ouvre les réglages."] = "One card per activity: where you stand, a button to carry on, then its windows. Click to open, right-click for settings.",
    ["Chercher un réglage"] = "Find a setting",
    ["Tape un mot, par exemple « flèche » : le réglage s'affiche et s'allume."] = "Type a word, \"arrow\" for example: the setting shows up and lights up.",
    ["Les gestes utiles pas à pas, avec le bon bouton qui s'allume. La visite se relance aussi d'ici."] = "Handy how-tos step by step, with the right button lit up. You can restart the tour from here too.",
    ["Le bouton de la minimap"] = "The minimap button",
    ["Un clic ouvre l'Accueil, un clic droit le menu des modules. Fais-le glisser pour le déplacer autour de la minimap."] = "Click to open Home, right-click for the module menu. Drag it to move it around the minimap.",
    -- quests and dungeons
    ["Plusieurs donjons donnent une seule route, depuis là où tu es. Les raids et les quêtes de classe sont là aussi."] = "Several dungeons make one route, from where you stand. Raids and class quests are there too.",
    ["La vue d'ensemble du donjon"] = "The dungeon overview",
    ["Les quêtes, l'entrée, les boss et ce qu'il faut avant d'entrer, sur une seule page."] = "The quests, the entrance, the bosses and what you need before going in, on one page.",
    ["Le bouton de l'étape"] = "The step's button",
    ["Il fait l'action de l'étape en cours : lancer le GPS, choisir un guide, entrer dans le donjon."] = "It does the current step's action: start the GPS, pick a guide, enter the dungeon.",
    ["Les portraits des boss"] = "The boss portraits",
    ["Un clic cible le boss et le marque. Un clic droit le coche tué à la main, ou le décoche."] = "Click to target and mark the boss. Right-click to tick it as killed by hand, or untick it.",
    -- getting around
    ["Où veux-tu aller ?"] = "Where do you want to go?",
    ["Tape un lieu, un service ou un PNJ (banque, HV, Forgefer) : Entrée lance le GPS."] = "Type a place, a service or an NPC (bank, AH, Ironforge): Enter starts the GPS.",
    ["La flèche GPS"] = "The GPS arrow",
    ["Elle montre où aller et à quelle distance, et devient verte dans la bonne direction. Fais-la glisser pour la déplacer."] = "It shows where to go and how far, and turns green when you head the right way. Drag it to move it.",
    ["Le sort du trajet"] = "The route's spell",
    ["Quand le trajet passe par une téléportation ou ta pierre de foyer, son icône est ici : un clic la lance."] = "When the route uses a teleport or your Hearthstone, its icon is here: click it to cast.",
    ["Les réglages du GPS"] = "GPS settings",
    ["Le chemin à pied en points, le repère dans le monde, la taille de la flèche."] = "The walking path as dots, the marker in the world, the arrow's size.",
    -- items and crafting
    ["Ton budget"] = "Your budget",
    ["Ici, dis à la guilde si tu es disponible pour fabriquer. Les artisans de la guilde sont juste à côté, par métier."] = "Here you tell the guild whether you're available to craft. The guild's crafters are right next to it, by profession.",
    ["La spé évaluée"] = "The rated spec",
    ["Les flèches vertes comparent les objets pour cette spé. Change-la si le jeu ne lit pas tes talents."] = "The green arrows compare items for this spec. Change it if the game can't read your talents.",
    -- guild and groups
    ["La guilde"] = "The guild",
    ["Les membres, le classement PvP, et qui a la clé qu'il te faut."] = "The members, the PvP ranking, and who has the key you need.",
    ["Les événements de la guilde et qui cherche un groupe. L'onglet Créer organise un donjon."] = "The guild's events and who is looking for a group. The Create tab sets up a dungeon run.",
})

local function secret(v) return root.IsSecret and root.IsSecret(v) end
local function num(v) return type(v) == "number" and not secret(v) and v or nil end
local function Visible(f)
    if not f then return false end
    local ok, v = pcall(function() return f:IsVisible() end)
    return ok and v == true
end
local function Shown(f)
    if not f then return false end
    local ok, v = pcall(function() return f:IsShown() end)
    return ok and v == true
end
local function On(key) return not WP.ModuleOn or WP.ModuleOn(key) end
local function CharDB() if type(WLWritsCharDB) ~= "table" then WLWritsCharDB = {} end; return WLWritsCharDB end
local function Hub() return _G.WLHelperHub end
local function IsButton(f)
    local ok, t = pcall(function() return f:GetObjectType() end)
    return ok and t == "Button"
end
-- the first visible frame under rootFrame for which test(frame) is true (depth first)
local function FindUnder(rootFrame, test, depth)
    depth = depth or 0
    if not rootFrame or depth > 20 then return nil end
    local ok, kids = pcall(function() return { rootFrame:GetChildren() } end)
    if not ok then return nil end
    for _, c in ipairs(kids) do
        if Visible(c) then
            local okT, hit = pcall(test, c)
            if okT and hit then return c end
            local deeper = FindUnder(c, test, depth + 1)
            if deeper then return deeper end
        end
    end
    return nil
end
local function NavItem(key)
    return FindUnder(Hub(), function(f) return IsButton(f) and f.key == key and f.Paint ~= nil end)
end
local function GuideWord(key)
    local ok, v = pcall(function() return root.L and root.L[key] end)
    return ok and type(v) == "string" and v or ""
end
-- opens a window by its toggle, only when it is not on screen yet (a toggle would close it)
local function Ensure(name, toggle)
    return function()
        if Shown(_G[name]) then return end
        if type(toggle) == "function" then toggle() end
    end
end
local function OpenHubOn(page) return function() if WP.OpenHub then WP.OpenHub(page) end end end
local function CloseHub() if WP.CloseHub then WP.CloseHub() end end
local function G(name) return function() return _G[name] end end

-- ================================================================= the tour's steps
-- One entry per bubble:
--   group     the activity (WP.WELCOME_GROUPS key): its mini tour shows its steps in this order
--   module    the step is left out while that module is off
--   can()     a quick check when the tour starts (the frame can exist at all): false leaves it out
--   win()     the window the step works in (the tour closes it again when the next step needs
--             another one, if the tour opened it)
--   open()    opens what the step needs
--   target()  the frame the bubble points at: missing or hidden, the step is skipped
--   title, text  French keys
WP.TOUR_GROUPS = { "start", "quests", "travel", "items", "guild" }
local STEPS = {
    -- getting started: the Hub
    { id = "nav", group = "start", win = Hub, open = OpenHubOn("home"),
      target = function() return NavItem("home") end,
      title = "Le menu", text = "À gauche, l'Accueil puis chaque activité avec ses réglages. Bienvenue, juste dessous, reprend la mise en route." },
    { id = "lines", group = "start", win = Hub, open = OpenHubOn("home"),
      target = function()
          local h = Hub()
          for _, e in ipairs(h and h.hubOrder or {}) do
              local r = h.cards and h.cards[e.key]
              if Visible(r) then return r end
          end
      end,
      title = "Tout ce qui s'ouvre", text = "Une carte par activité : où tu en es, un bouton pour continuer, puis ses fenêtres. Un clic ouvre, un clic droit ouvre les réglages." },
    { id = "search", group = "start", win = Hub, open = OpenHubOn("home"),
      target = function() return WP.searchBox end,
      title = "Chercher un réglage", text = "Tape un mot, par exemple « flèche » : le réglage s'affiche et s'allume." },
    { id = "help", group = "start", win = Hub, open = OpenHubOn("home"),
      target = function() local h = Hub(); return h and h.help end,
      title = "Comment faire... ?", text = "Les gestes utiles pas à pas, avec le bon bouton qui s'allume. La visite se relance aussi d'ici." },
    { id = "minimap", group = "start", win = Hub,
      can = function() return Shown(_G.WLDTMinimapButton) end,
      target = G("WLDTMinimapButton"),
      title = "Le bouton de la minimap", text = "Un clic ouvre l'Accueil, un clic droit le menu des modules. Fais-le glisser pour le déplacer autour de la minimap." },

    -- quests and dungeons: the guide window
    { id = "pick", group = "quests", module = "dungeons", win = G("WLDTFrame"),
      can = function() return root.ShowGuide ~= nil end,
      open = function() CloseHub(); if not Shown(root.frame) then (root.ShowWindow or root.ShowGuide)() end end,
      target = function() return root.frame and root.frame.pickBtn end,
      title = "Choisir un guide", text = "Plusieurs donjons donnent une seule route, depuis là où tu es. Les raids et les quêtes de classe sont là aussi." },
    { id = "overview", group = "quests", module = "dungeons", win = G("WLDTFrame"),
      can = function() return root.ShowGuide ~= nil and root.ShowOverview ~= nil end,
      open = function() CloseHub(); if not Shown(root.frame) then (root.ShowWindow or root.ShowGuide)() end end,
      target = function() return root.frame and root.frame.ovBtn end,
      title = "La vue d'ensemble du donjon", text = "Les quêtes, l'entrée, les boss et ce qu'il faut avant d'entrer, sur une seule page." },
    { id = "go", group = "quests", module = "dungeons", win = G("WLDTFrame"),
      can = function() return root.ShowGuide ~= nil end,
      open = function() CloseHub(); if not Shown(root.frame) then (root.ShowWindow or root.ShowGuide)() end end,
      target = function() return root.frame and root.frame.go end,
      title = "Le bouton de l'étape", text = "Il fait l'action de l'étape en cours : lancer le GPS, choisir un guide, entrer dans le donjon." },
    { id = "bosses", group = "quests", module = "dungeons",
      can = function() return Shown(_G.WLBossPanel) end,
      target = G("WLBossTarget1"),
      title = "Les portraits des boss", text = "Un clic cible le boss et le marque. Un clic droit le coche tué à la main, ou le décoche." },

    -- getting around: Home's search, the GPS arrow and its cast button, the GPS settings
    { id = "goto", group = "travel", win = Hub, open = OpenHubOn("home"),
      target = function() local h = Hub(); return h and h.search end,
      title = "Où veux-tu aller ?", text = "Tape un lieu, un service ou un PNJ (banque, HV, Forgefer) : Entrée lance le GPS." },
    { id = "arrow", group = "travel",
      can = function() return Shown(_G.WLGPSArrow) end,
      target = G("WLGPSArrow"),
      title = "La flèche GPS", text = "Elle montre où aller et à quelle distance, et devient verte dans la bonne direction. Fais-la glisser pour la déplacer." },
    { id = "cast", group = "travel",
      can = function() return Shown(_G.WLGPSTeleport) end,
      target = G("WLGPSTeleport"),
      title = "Le sort du trajet", text = "Quand le trajet passe par une téléportation ou ta pierre de foyer, son icône est ici : un clic la lance." },
    { id = "gps", group = "travel", win = Hub, open = OpenHubOn("gps"),
      target = function() return NavItem("gps") end,
      title = "Les réglages du GPS", text = "Le chemin à pied en points, le repère dans le monde, la taille de la flèche." },

    -- items and crafting
    { id = "budget", group = "items", module = "writs", win = G("WLHelperComptoir"),
      can = function() return WP.Open ~= nil end,
      open = function() CloseHub(); WP.Open("writs"); if WP.ShowTab then WP.ShowTab("shop") end end,
      target = function()
          local b = WP.FindIn and WP.FindIn(_G.WLHelperComptoir, { L("Sans limite") })
          return b and b.GetParent and b:GetParent() or b
      end,
      title = "Ton budget", text = "Le plan d'achat dépense au plus cette somme, sur les Writs qui rapportent le plus de réputation." },
    { id = "crafter", group = "items", module = "orders", win = G("WLHelperOrders"),
      can = function() return WP.ShowOrdersTab ~= nil end,
      open = function() CloseHub(); WP.ShowOrdersTab("find") end,
      target = function()
          return WP.FindIn and WP.FindIn(_G.WLHelperOrders, { L("Ma fiche"), L("Ma fiche d'artisan"), L("Partager mes recettes") })
      end,
      title = "Ta fiche d'artisan", text = "Ici, dis à la guilde si tu es disponible pour fabriquer. Les artisans de la guilde sont juste à côté, par métier." },
    { id = "spec", group = "items", module = "upgrades", win = Hub, open = OpenHubOn("upgrades"),
      target = function() return WP.Help and WP.Help.SpecControl and WP.Help.SpecControl() end,
      title = "La spé évaluée", text = "Les flèches vertes comparent les objets pour cette spé. Change-la si le jeu ne lit pas tes talents." },

    -- guild and groups: the windows themselves
    { id = "guild", group = "guild", module = "guild", win = G("WLHelperGuild"),
      can = function() return WP.ToggleGuild ~= nil end,
      open = function() CloseHub(); Ensure("WLHelperGuild", WP.ToggleGuild)() end,
      target = G("WLHelperGuild"),
      title = "La guilde", text = "Les membres, le classement PvP, et qui a la clé qu'il te faut." },
    { id = "shared", group = "guild", module = "guild", win = G("WLHelperShared"),
      can = function() return WP.Shared ~= nil and WP.Shared.Show ~= nil end,
      open = function() CloseHub(); if not Shown(_G.WLHelperShared) then WP.Shared.Show() end end,
      target = G("WLHelperShared"),
      title = "Les quêtes en commun", text = "Qui dans la guilde a les mêmes quêtes de donjon que toi, pour grouper. Le partage se règle dans Réglages > Guilde." },
    { id = "keys", group = "guild", module = "keys", win = G("WLHelperKeys"),
      can = function() return WP.ToggleKeys ~= nil end,
      open = function() CloseHub(); Ensure("WLHelperKeys", WP.ToggleKeys)() end,
      target = G("WLHelperKeys"),
      title = "Le passeport des clés", text = "Les clés de donjon que tu as, et qui dans la guilde a celles qui te manquent." },
    { id = "events", group = "guild", module = "events", win = G("WLHelperEvents"),
      can = function() return WP.ToggleEvents ~= nil end,
      open = function() CloseHub(); Ensure("WLHelperEvents", WP.ToggleEvents)() end,
      target = G("WLHelperEvents"),
      title = "Groupes", text = "Les événements de la guilde et qui cherche un groupe. L'onglet Créer organise un donjon." },
}
WP.TOUR_STEPS = STEPS

local Tour = {}
WP.Tour = Tour

-- Tour.Steps([group]) -> the steps that can show now (module on, can() true), in order; every
-- activity when group is nil
function Tour.Steps(group)
    local out = {}
    for _, g in ipairs(WP.TOUR_GROUPS) do
        if group == nil or group == g then
            for _, st in ipairs(STEPS) do
                if st.group == g and (not st.module or On(st.module)) then
                    local ok, can = true, true
                    if st.can then ok, can = pcall(st.can) end
                    if ok and can then out[#out + 1] = st end
                end
            end
        end
    end
    return out
end
-- true when the activity has steps at all (the Welcome page draws its "Visiter" link then)
function Tour.HasGroup(group)
    for _, st in ipairs(STEPS) do
        if st.group == group and (not st.module or On(st.module)) then return true end
    end
    return false
end

-- ---------------------------------------------------------------- the bubble

local BW, PAD = 320, 16
local bubble
local run           -- { list, i, group, opened = { [frame] = true }, cur (window), paused }
local queuedGroup   -- the tour asked for in combat: starts when the fight is over
local queued = false

local Go, Finish    -- defined below

local function BuildBubble()
    bubble = CreateFrame("Frame", "WLHelperTour", UIParent)
    bubble.wlOwned = true
    bubble:SetFrameStrata("FULLSCREEN_DIALOG")
    if bubble.SetFrameLevel then bubble:SetFrameLevel(60) end
    bubble:SetClampedToScreen(true)
    bubble:SetWidth(BW)
    bubble:EnableMouse(true)
    S.Solid(bubble, "BACKGROUND", C.panel, 0.98):SetAllPoints()
    S.Border(bubble, C.line)
    bubble.stack = root.TextStack(bubble)
    bubble.skip = S.Button(bubble, L("Passer"), 0, 28, "ghost", function() Finish("skip") end,
        { L("Passer"), L("Clic : arrêter la visite (Échap aussi)") })
    bubble.prev = S.Button(bubble, L("Précédent"), 0, 28, "secondary", function()
        if run then Go(run.i - 1, -1) end
    end)
    bubble.next = S.Button(bubble, L("Suivant"), 0, 28, "primary", function()
        if run then Go(run.i + 1, 1) end
    end)
    -- Escape ends the tour; every other key goes on to the game (never in combat: the tour pauses)
    if bubble.EnableKeyboard then bubble:EnableKeyboard(true) end
    bubble:SetScript("OnKeyDown", function(self, key)
        local esc = key == "ESCAPE"
        if not (InCombatLockdown and InCombatLockdown()) and self.SetPropagateKeyboardInput then
            pcall(self.SetPropagateKeyboardInput, self, not esc)
        end
        if esc then Finish("escape") end
    end)
    -- the window it points into was closed by hand: the bubble would float over nothing, and with
    -- it hidden Escape could not end the tour any more. Half a second gone: the tour stops.
    bubble:SetScript("OnUpdate", function(self, dt)
        self.lost = Visible(run and run.target) and 0 or (self.lost or 0) + (dt or 0)
        if self.lost > 0.5 then self.lost = 0; Finish("skip") end
    end)
    bubble:SetScript("OnShow", function(self) self.lost = 0 end)
    bubble:Hide()
end

-- Draws the step's words, the count and the buttons; returns the height.
local function Fill(st, i, n)
    local b = bubble
    local stk = b.stack
    stk:Begin(PAD, PAD, BW - 2 * PAD)
    stk:Heading(L(st.title))
    stk:Body(L(st.text))
    stk:Muted(string.format(L("%d sur %d"), i, n))
    local y = PAD + stk:End() + 12
    b.next:SetText(i >= n and L("Terminer") or L("Suivant"))
    b.next:ClearAllPoints(); b.next:SetPoint("TOPRIGHT", b, "TOPRIGHT", -PAD, -y)
    b.prev:ClearAllPoints(); b.prev:SetPoint("RIGHT", b.next, "LEFT", -8, 0)
    b.prev:SetShown(i > 1)
    -- a ghost button: its text starts on the content's left edge
    b.skip:ClearAllPoints(); b.skip:SetPoint("TOPLEFT", b, "TOPLEFT", PAD - 12, -y)
    local h = math.ceil(y + 28 + PAD)
    b:SetHeight(h)
    return h
end

-- Below the target when there is room, else above it (over the spotlight's arrow), else on it.
local function Place(target, h)
    local b = bubble
    b:ClearAllPoints()
    local okB, bottom = pcall(target.GetBottom, target)
    local okT, top = pcall(target.GetTop, target)
    bottom, top = okB and num(bottom), okT and num(top)
    local okS, ts = pcall(target.GetEffectiveScale, target)
    local okU, us = pcall(UIParent.GetEffectiveScale, UIParent)
    ts, us = okS and num(ts), okU and num(us)
    local k = (ts and us and us > 0) and ts / us or 1
    local uh = num(UIParent:GetHeight()) or 768
    if bottom and bottom * k - h - 24 > 0 then
        b:SetPoint("TOP", target, "BOTTOM", 0, -16)
    elseif top and top * k + h + 56 < uh then
        b:SetPoint("BOTTOM", target, "TOP", 0, 48)
    else
        b:SetPoint("CENTER", target, "CENTER", 0, 0)
    end
end

local function HideBubble()
    if bubble then bubble:Hide() end
    if WP.SpotlightOff then WP.SpotlightOff() end
end

local function Show(st, target)
    if not bubble then BuildBubble() end
    -- the count follows what is shown: a step skipped (its window did not open) leaves no gap,
    -- "3 sur 17" then "4 sur 16"; the total is the steps shown plus those still ahead
    run.seen = run.seen or {}
    local pos, maxI = nil, 0
    for k, j in ipairs(run.seen) do if j == run.i then pos = k end; if j > maxI then maxI = j end end
    if not pos then
        table.insert(run.seen, run.i); table.sort(run.seen)
        for k, j in ipairs(run.seen) do if j == run.i then pos = k end end
        if run.i > maxI then maxI = run.i end
    end
    local h = Fill(st, pos, #run.seen + math.max(0, #run.list - maxI))
    Place(target, h)
    run.target = target
    run.shownN = (run.shownN or 0) + 1
    bubble:Show()
    if bubble.Raise then bubble:Raise() end
    if WP.Spotlight then WP.Spotlight(target, 3600) end
end

-- the window of the last step goes away when this step works in another one (if the tour opened it)
local function Leave(nextWin)
    local cur = run.cur
    if cur and cur ~= nextWin and run.opened[cur] then
        run.opened[cur] = nil
        pcall(cur.Hide, cur)
    end
end

-- Shows step i, going in direction dir (1 or -1) past the steps whose frame is missing.
Go = function(i, dir)
    if not run then return end
    local token = run   -- a timer left by an earlier tour must not act on a new one
    if InCombatLockdown and InCombatLockdown() then
        run.paused = true; HideBubble(); return
    end
    if i < 1 then i, dir = 1, 1 end
    local st = run.list[i]
    if not st then Finish("done"); return end
    run.i, run.dir = i, dir
    local w = st.win and select(2, pcall(st.win)) or nil
    if type(w) ~= "table" then w = nil end
    Leave(w)
    local wasShown = w and Shown(w)
    if st.open then
        local ok, err = pcall(st.open)
        if not ok and geterrorhandler then geterrorhandler()(err) end
    end
    if w == nil and st.win then
        local okW, w2 = pcall(st.win); if okW and type(w2) == "table" then w = w2 end
    end
    if w and not wasShown and Shown(w) then run.opened[w] = true end
    run.cur = w or run.cur
    HideBubble()
    local function Point()
        if run ~= token or run.i ~= i or run.paused then return end
        local ok, target = pcall(st.target)
        if not (ok and type(target) == "table" and Visible(target)) then
            -- skipped: on in the same direction (going back past the first step turns forward)
            if dir < 0 and i <= 1 then Go(i + 1, 1) else Go(i + dir, dir) end
            return
        end
        Show(st, target)
    end
    -- the window is drawn on the next frames: point once it is
    if C_Timer and C_Timer.After then C_Timer.After(0.25, Point) else Point() end
end

-- how: "done" (Terminer on the last step), "skip" (Passer), "escape"
Finish = function(how)
    if not run then return end
    local shown, back = run.shownN or 0, run.back
    run = nil
    HideBubble()
    if how == "done" and shown == 0 then
        -- every step was skipped on the way (a window that did not open): nothing was seen
        WP.Print(L("Rien à montrer pour l'instant dans cette activité. Allume son module ou ouvre ses fenêtres, puis relance la visite."))
    elseif how == "done" then
        local db = CharDB()
        db.welcome = type(db.welcome) == "table" and db.welcome or {}
        db.welcome.toured = true
        WP.Print(L("Visite terminée. La page Bienvenue de la fenêtre WL Helper reprend chaque réglage pas à pas."))
    else
        WP.Print(L("Visite arrêtée. Tape /wlh visite pour la refaire."))
    end
    -- started from the Welcome page: back to it (the steps moved the Hub or closed it)
    if back and not (InCombatLockdown and InCombatLockdown()) and WP.OpenHub then
        pcall(WP.OpenHub, "welcome")
    end
    if WP.RefreshWelcome then WP.RefreshWelcome() end
end

-- Tour.Start([group]): the whole tour, or one activity's ("start", "quests", "travel", "items",
-- "guild"). In combat it waits for the end of the fight.
function Tour.Start(group)
    if InCombatLockdown and InCombatLockdown() then
        if not queued then WP.Print(L("La visite commencera à la fin du combat.")) end
        queued, queuedGroup = true, group
        return false
    end
    local list = Tour.Steps(group)
    if #list == 0 then
        WP.Print(L("Rien à montrer pour l'instant dans cette activité. Allume son module ou ouvre ses fenêtres, puis relance la visite."))
        return false
    end
    if run then HideBubble() end
    local back = (WP.HubShows and WP.HubShows("welcome")) and true or false
    -- the quick start and the help window would hide what the bubbles point at
    for _, n in ipairs({ "WLHelperWelcome", "WLHelperHelp" }) do
        local f = _G[n]
        if Shown(f) then
            -- the quick start counts as gone through, not closed (Writs/Setup.lua Ended)
            if n == "WLHelperWelcome" then f.endHow = f.endHow or "card" end
            f:Hide()
        end
    end
    run = { list = list, i = 0, group = group, opened = {}, back = back }
    Go(1, 1)
    return true
end
function Tour.Stop() Finish("skip") end
function Tour.Running() return run ~= nil end
-- for the tests: the step shown (its id), its number and the count
function Tour.Current()
    if not run then return nil end
    local st = run.list[run.i]
    return st and st.id, run.i, #run.list, run.target
end
Tour.Bubble = function() return bubble end

local ev = CreateFrame("Frame")
pcall(ev.RegisterEvent, ev, "PLAYER_REGEN_DISABLED")
pcall(ev.RegisterEvent, ev, "PLAYER_REGEN_ENABLED")
ev:SetScript("OnEvent", function(_, e)
    if e == "PLAYER_REGEN_DISABLED" then
        if run and not run.paused then
            run.paused = true
            HideBubble()
            WP.Print(L("Visite en pause pendant le combat : elle reprend à la fin du combat."))
        end
    elseif e == "PLAYER_REGEN_ENABLED" then
        if queued then
            queued = false
            local g = queuedGroup; queuedGroup = nil
            Tour.Start(g)
        elseif run and run.paused then
            run.paused = false
            Go(math.max(1, run.i), 1)
        end
    end
end)

-- ================================================================= the Welcome page

local page, CW
local intro, groups = nil, {}

local function Relayout()
    if page and page.Layout then page:Layout() end
    if C_Timer and C_Timer.After then
        C_Timer.After(0, function() if page and page:IsShown() and page.Layout then page:Layout() end end)
    end
end

-- One thing to set, as a card of the activity's grid (ns.GRID.cards: 2 a line at 668-724 px, 3
-- from 1112): a check (or an empty ring) and the title (13 fg), its sentence (12 muted, 2 lines at
-- most, the full text in the card's tooltip when cut), then on a line under the text the button that
-- opens the place and "C'est fait" (or "Décocher") as a ghost.
local TEXT_LINES = 2
local function ItemRow(parent, e)
    local r = CreateFrame("Frame", nil, parent)
    r.wlOwned = true
    r.entry = e
    S.Solid(r, "BACKGROUND", C.cardFill):SetAllPoints()
    S.Border(r, C.cardEdge)
    r.mark = root.Icon(r, "ring", 16, "ARTWORK", C.muted)
    r.title = S.Text(r, F.body, C.fg)
    r.title:SetJustifyH("LEFT"); r.title:SetJustifyV("TOP")
    r.text = S.Text(r, F.label, C.muted)
    r.text:SetJustifyH("LEFT"); r.text:SetJustifyV("TOP")
    r.go = S.Button(r, L(e.button), 0, 24, "secondary", function() if r.entry.open then r.entry.open() end end,
        { L(e.button), L("Clic : ouvrir et montrer où régler") })
    r.tick = S.Button(r, L("C'est fait"), 0, 24, "ghost", function()
        local en = r.entry
        WP.WelcomeTick(en.key, not en.ticked)
        Relayout()
    end, function()
        if r.entry.ticked then return { L("Décocher"), L("Clic : remettre cette étape à faire") } end
        return { L("C'est fait"), L("Clic : cocher cette étape") }
    end)
    -- the whole sentence (it may be cut at 2 lines)
    r:EnableMouse(true)
    r:SetScript("OnEnter", function(self)
        local en = self.entry
        S.Tip(self, { L(en.title), L(en.text) })
    end)
    r:SetScript("OnLeave", S.HideTip)
    function r:Fit(width)
        local en = self.entry
        if en.isDone then root.SetHDIcon(self.mark, "check", C.ok) else root.SetHDIcon(self.mark, "ring", C.muted) end
        -- the tick: "C'est fait" while to do, "Décocher" when ticked by hand, nothing when the
        -- settings already say it is set
        self.tick:SetShown(not en.auto)
        self.tick:SetText(en.ticked and L("Décocher") or L("C'est fait"))
        local tc = en.isDone and C.muted or C.fg
        self.title:SetTextColor(tc[1], tc[2], tc[3])
        self.title:SetText(L(en.title))
        self.text:SetText(L(en.text))
        local x = 12 + 16 + 8
        local textW = math.max(80, width - x - 12)
        self.mark:ClearAllPoints(); self.mark:SetPoint("TOPLEFT", 12, -13)
        self.title:ClearAllPoints(); self.title:SetPoint("TOPLEFT", x, -12)
        local th = math.max(15, root.FitText(self.title, 2, textW, self))
        self.text:ClearAllPoints(); self.text:SetPoint("TOPLEFT", x, -(12 + th + 4))
        if self.text.SetMaxLines then self.text:SetMaxLines(TEXT_LINES) end
        self.text:SetWidth(textW)
        self.text:SetWordWrap(true)
        local tx = math.max(14, root.FitText(self.text, TEXT_LINES, textW, self))
        local by = 12 + th + 4 + tx + 10
        self.go:ClearAllPoints(); self.go:SetPoint("TOPLEFT", self, "TOPLEFT", x, -by)
        self.tick:ClearAllPoints(); self.tick:SetPoint("LEFT", self.go, "RIGHT", 4, 0)
        local h = math.ceil(by + 24 + 12)
        self:SetHeight(h)
        return h
    end
    return r
end

-- an activity: its section header ("n/m", the "Visiter" link), then its cards in a grid
local function Group(def)
    local g = { def = def, rows = {}, grid = root.Grid() }
    -- a tight header (24 + 8): five activities on a page that should not scroll much
    g.head = S.SectionHeader(page, L(def.label), nil, L("Visiter"), function() Tour.Start(def.key) end, { tight = true })
    if g.head.link then
        g.head.link:SetScript("OnEnter", function(self) S.Tip(self, { L("Visiter"), L("Clic : la visite de cette activité") }) end)
        g.head.link:SetScript("OnLeave", S.HideTip)
    end
    -- the frame the cards sit in (no fill of its own: each thing is its own card)
    g.card = CreateFrame("Frame", nil, page)
    g.card.wlOwned = true
    return g
end

local function BuildIntro()
    local c = CreateFrame("Frame", nil, page)
    c.wlOwned = true
    S.Solid(c, "BACKGROUND", C.cardFill):SetAllPoints()
    S.Border(c, C.cardEdge)
    c.stack = root.TextStack(c)
    c.tour = S.Button(c, L("Faire la visite"), 0, 28, "primary", function() Tour.Start() end,
        { L("Faire la visite"), L("Clic : lancer la visite guidée") })
    c.quick = S.Button(c, L("Rouvrir l'écran de bienvenue"), 0, 28, "ghost", function()
        if WP.CloseHub then WP.CloseHub() end
        if WP.ShowWelcome then WP.ShowWelcome(true) end
    end, { L("Rouvrir l'écran de bienvenue"), L("Clic : rouvrir l'écran de bienvenue (modules, spé, clics)") })
    c.quick:SetShown(WP.ShowWelcome ~= nil)
    return c
end

local function Layout()
    if not page then return 0 end
    local y = 12
    local function Put(f, h)
        f:ClearAllPoints(); f:SetPoint("TOPLEFT", page, "TOPLEFT", 16, -y)
        f:SetWidth(CW); f:SetHeight(h)
        y = y + h
    end
    -- the progress, the tour
    local n, total = WP.WelcomeProgress()
    local stk = intro.stack
    stk:Begin(16, 16, math.min(CW - 32, 480))   -- a running sentence: 480 at most (4.2)
    stk:Stat(L("Ta mise en route"), n, total, { sub = (total > 0 and n >= total)
        and L("Tout est réglé. La visite reste là si tu veux revoir où est chaque chose.")
        or L("Dans l'ordre que tu veux. Une étape se coche toute seule quand c'est réglé, ou avec « C'est fait ».") })
    local ih = 16 + stk:End() + 12
    local toured = type(WLWritsCharDB) == "table" and type(WLWritsCharDB.welcome) == "table" and WLWritsCharDB.welcome.toured
    intro.tour:SetText(toured and L("Refaire la visite") or L("Faire la visite"))
    intro.tour:ClearAllPoints(); intro.tour:SetPoint("TOPLEFT", 16, -ih)
    intro.quick:ClearAllPoints(); intro.quick:SetPoint("LEFT", intro.tour, "RIGHT", 8, 0)
    Put(intro, math.ceil(ih + 28 + 16))
    -- the activities, each with its lines (an activity with nothing to set is not drawn)
    for _, def in ipairs(WP.WELCOME_GROUPS or {}) do
        local g = groups[def.key]
        local items = WP.WelcomeItems(def.key)
        if #items == 0 then
            if g then g.head:Hide(); g.card:Hide() end
        else
            if not g then g = Group(def); groups[def.key] = g end
            local done = 0
            for _, e in ipairs(items) do if e.isDone then done = done + 1 end end
            g.head:Set(L(def.label), done .. "/" .. #items)
            if g.head.link then g.head.link:SetShown(Tour.HasGroup(def.key)) end
            g.head:Show(); g.card:Show()
            y = y + 12
            Put(g.head, 24)
            y = y + 8
            local seen = {}
            local go = root.GRID.cards
            g.grid:Begin(g.card, 0, 0, CW, { minW = go.minW, gap = go.gap, rowGap = go.rowGap, maxCols = go.maxCols,
                minPx = go.minPx, equal = true })
            for _, e in ipairs(items) do
                local r = g.rows[e.key]
                if not r then r = ItemRow(g.card, e); g.rows[e.key] = r end
                r.entry = e
                seen[e.key] = true
                r:Show()
                g.grid:Add(r, function(f, w) return f:Fit(w) end)
            end
            for k, r in pairs(g.rows) do if not seen[k] then r:Hide() end end
            Put(g.card, math.max(1, math.ceil(g.grid:End())))
        end
    end
    y = math.ceil(y + 16)
    page.contentH = y
    if page.sa then page.sa:SetContentHeight(y) end
    return y
end

WP.WelcomePage = {
    -- Build(p, width): p is the Hub page (Writs/Options.lua), width its content column
    Build = function(p, width)
        page = p
        CW = math.floor((width or 660) - 32)
        groups = {}
        p.welcomeGroups = groups
        intro = BuildIntro()
        -- the Hub lays the page out each time it shows (Relayout): the checks are read again then
        function p:Layout() return Layout() end
        Layout()
    end,
    Layout = function() return Layout() end,
    -- the Hub's content column got a new width (the window was resized): used by the next Layout
    SetWidth = function(width) CW = math.floor((width or 660) - 32) end,
}

-- Redraws the page while it is on screen (after the tour, a tick elsewhere)
function WP.RefreshWelcome()
    if page and WP.HubShows and WP.HubShows("welcome") then Relayout() end
end

-- ================================================================= /wlh visite, /wlh bienvenue

-- the activity words after /wlh visite
local WORDS = {
    debut = "start", start = "start", menu = "start",
    quetes = "quests", quests = "quests", donjons = "quests", dungeons = "quests", guide = "quests",
    gps = "travel", deplacements = "travel", travel = "travel",
    objets = "items", items = "items", metiers = "items", writs = "items", commandes = "items",
    guilde = "guild", guild = "guild", groupes = "guild",
}
local function Word(w)
    w = w or ""
    for _, a in ipairs({ "é", "è", "ê", "É", "È", "Ê" }) do w = w:gsub(a, "e") end
    return w:lower()
end
-- true when the words were ours
function Tour.Command(msg)
    local w, rest = (msg or ""):match("^%s*(%S*)%s*(.-)%s*$")
    w = Word(w)
    if w == "visite" or w == "tour" or w == "visit" then
        local r = Word(rest)
        if r ~= "" and not WORDS[r] then
            WP.Print(string.format(L("Mots connus après /wlh visite : %s."), L("debut, quetes, gps, objets, guilde")))
            return true
        end
        Tour.Start(WORDS[r])
        return true
    elseif w == "bienvenue" or w == "welcome" then
        if WP.OpenHub then WP.OpenHub("welcome") end
        return true
    end
    return false
end

-- Main.lua owns /wlh: these words are answered here, every other word goes on untouched
-- (the same wrapping as Writs/Commands.lua)
local hook = CreateFrame("Frame")
pcall(hook.RegisterEvent, hook, "PLAYER_LOGIN")
hook:SetScript("OnEvent", function()
    local orig = SlashCmdList and SlashCmdList.WLDUNGEONTOOL
    if not orig then return end
    SlashCmdList.WLDUNGEONTOOL = function(msg, ...)
        if Tour.Command(msg) then return end
        return orig(msg, ...)
    end
end)
