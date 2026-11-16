-- Writs/Hub.lua: the catalogue of the WL Helper window (T-55), data only, no frame. Every window
-- WL Helper can open, grouped by activity: the Hub's Home page draws one line per entry, the
-- minimap menu lists them in the same order, and a right-click on a line opens its settings page.
-- One list instead of five (WP.MODULES, Home's cards, the minimap menu, Settings' pages): a new
-- window is added here once.
-- The open/available functions read WP.* when they run: Home, Options, GoTo and the module files
-- that provide them load after this one (or not at all, in the offline tests).
local ADDON, root = ...
root.Writs = root.Writs or {}
local ns = root.Writs
local WP = ns.WP

ns.AddEnglish({
    ["Quêtes et donjons"] = "Quests & dungeons",
    ["Déplacements"] = "Getting around",
    ["Objets et métiers"] = "Items & crafting",
    ["Guilde et groupes"] = "Guild & groups",
})

-- The activities, in the order of the nav, Home and the minimap menu. Labels are French keys.
WP.HUB_GROUPS = {
    { key = "quests", label = "Quêtes et donjons" },
    { key = "travel", label = "Déplacements" },
    { key = "items", label = "Objets et métiers" },
    { key = "guild", label = "Guilde et groupes" },
}

local function OpenGuide()
    if root.GuideStatus and root.GuideStatus() then root.ShowGuide() elseif root.ShowPicker then root.ShowPicker() end
end
local function Has(...)
    local t = WP
    for _, k in ipairs({ ... }) do
        t = type(t) == "table" and t[k] or nil
        if t == nil then return false end
    end
    return true
end

-- One entry per line on Home:
--   key       the line's key (Home's win.cards[key], the minimap menu's buttons[key])
--   group     a WP.HUB_GROUPS key
--   label     the window's name (French key)
--   icon      a key of WP.MODULE_ICON (Home.lua), a tool icon key of Home ("city", "keys", ...),
--             or { hd = glyph }
--   module    the WP.MODULES key it belongs to (dimmed with "Éteint" when that module is off)
--   isOn/turnOn  its own switch when it is not a module (the city tour)
--   available -> true when the files behind it are loaded
--   open      opens the window
--   settings  the Hub page with its settings (right-click); anchor: the section there (French key)
WP.HUB = {
    { key = "dungeons", group = "quests", label = "Guide de quêtes", icon = "dungeons", module = "dungeons",
      available = function() return root.ShowGuide ~= nil or root.ShowPicker ~= nil end,
      open = OpenGuide, settings = "dungeons" },
    { key = "keys", group = "quests", label = "Passeport des clés", icon = "keys", module = "keys",
      available = function() return Has("Keys") and Has("ToggleKeys") end,
      open = function() if WP.ToggleKeys then WP.ToggleKeys() end end, settings = "guild", anchor = "Partage" },
    { key = "shared", group = "quests", label = "Quêtes en commun", icon = "shared", module = "guild",
      available = function() return Has("Shared", "Show") end,
      open = function() if WP.Shared then WP.Shared.Show() end end, settings = "guild", anchor = "Partage" },
    { key = "triage", group = "quests", label = "Tri du journal", icon = "triage", module = "triage",
      available = function() return Has("Triage", "Show") end,
      open = function() if WP.Triage then WP.Triage.Show() end end, settings = "dungeons", anchor = "Journal de quêtes" },
    { key = "goto", group = "travel", label = "Aller à", icon = { hd = root.ARROW },
      available = function() return Has("GoTo", "Show") end,
      open = function() if WP.GoTo then WP.GoTo.Show("") end end, settings = "gps" },
    { key = "city", group = "travel", label = "Tournée en ville", icon = "city",
      isOn = function() local CT = WP.CityTour; return not (CT and CT.IsOn) or CT.IsOn() and true or false end,
      turnOn = function() local CT = WP.CityTour; if CT and CT.SetOn then CT.SetOn(true) end end,
      available = function() return Has("CityTour", "Show") end,
      open = function() if WP.CityTour then WP.CityTour.Show() end end, settings = "gps", anchor = "En ville" },
    { key = "writs", group = "items", label = "Writs", icon = "writs", module = "writs",
      available = function() return Has("Open") end,
      open = function() WP.Open("writs") end, settings = "comptoir" },
    { key = "favor", group = "items", label = "Faveur du marchand", icon = "favor", module = "writs",
      available = function() return Has("Open") end,
      open = function() WP.Open("favor") end, settings = "comptoir" },
    { key = "orders", group = "items", label = "Commandes", icon = "orders", module = "orders",
      available = function() return Has("ToggleOrders") end,
      open = function() if WP.ToggleOrders then WP.ToggleOrders() end end, settings = "orders" },
    { key = "bags", group = "items", label = "Sacs", icon = "bags", module = "bags",
      available = function() return Has("Cleaner") end,
      open = function() if WP.Cleaner then WP.Cleaner.Toggle() end end, settings = "bags" },
    { key = "upgrades", group = "items", label = "Améliorations", icon = "upgrades", module = "upgrades",
      available = function() return true end,
      open = function() if WP.OpenHub then WP.OpenHub("upgrades") end end, settings = "upgrades", inHub = true },
    { key = "guild", group = "guild", label = "Guilde", icon = "guild", module = "guild",
      available = function() return Has("ToggleGuild") end,
      open = function() if WP.ToggleGuild then WP.ToggleGuild() end end, settings = "guild" },
    { key = "events", group = "guild", label = "Groupes", icon = "events", module = "events",
      available = function() return Has("ToggleEvents") end,
      open = function() if WP.ToggleEvents then WP.ToggleEvents() end end, settings = "groups" },
}

-- WP.HubEntries(group) -> the entries of that activity whose files are loaded, in the list's order
-- (every activity when group is nil)
function WP.HubEntries(group)
    local out = {}
    for _, e in ipairs(WP.HUB) do
        if group == nil or e.group == group then
            local ok, v = pcall(e.available)
            if ok and v then out[#out + 1] = e end
        end
    end
    return out
end

-- WP.HubEntryOn(e) -> false when the entry's module (or its own switch) is off
function WP.HubEntryOn(e)
    if e.isOn then local ok, v = pcall(e.isOn); return not ok or v ~= false end
    if e.module and WP.ModuleOn then return WP.ModuleOn(e.module) end
    return true
end

-- WP.HubTurnOn(e): turns the entry's module (or its own switch) back on
function WP.HubTurnOn(e)
    if e.turnOn then pcall(e.turnOn)
    elseif e.module and WP.SetModule then WP.SetModule(e.module, true) end
end

-- ---------------------------------------------------------------- the Welcome checklist (T-62)
-- The Hub's Welcome page (Writs/Tour.lua draws it) lists what is worth setting up, by activity, in
-- any order. One entry per thing to set:
--   key       saved in WLWritsCharDB.welcome.done[key] when ticked by hand ("C'est fait")
--   group     "start" or a WP.HUB_GROUPS key (its mini tour has the same key)
--   title, text  French keys: the thing, then one sentence on what it changes
--   button    the verb of the button that opens the right place (French key)
--   shown()   false: not listed and not counted (its module is off, nothing to ask)
--   done()    true when the saved settings already say it is set (ticked by itself)
--   open()    opens the right window or Settings section and lights the control
-- The functions read WP.* when they run: nothing here needs the other files loaded.
WP.WELCOME_GROUPS = {
    { key = "start", label = "Pour commencer" },
    { key = "quests", label = "Quêtes et donjons" },
    { key = "travel", label = "Déplacements" },
    { key = "items", label = "Objets et métiers" },
    { key = "guild", label = "Guilde et groupes" },
}

local function On(key) return not WP.ModuleOn or WP.ModuleOn(key) end
local function CharDB() if type(WLWritsCharDB) ~= "table" then WLWritsCharDB = {} end; return WLWritsCharDB end
local function Word(s) return ns.L and ns.L(s) or s end
local function Glow(open, winName, targets)
    if WP.ShowMe then WP.ShowMe(open, function() return _G[winName] end, targets)
    else pcall(open) end
end
-- a Settings row or section of the Hub: scrolled to, flashed and lit
local function Setting(page, anchor)
    return function()
        Glow(function() if WP.OpenHub then WP.OpenHub(page, anchor) end end, "WLHelperHub",
            { function() return WP.HubAnchor and WP.HubAnchor() end })
    end
end
-- a button in the Hub that opens another window closes the Hub (DESIGN 3.20)
local function CloseHub() if WP.CloseHub then WP.CloseHub() end end

WP.WELCOME = {
    { key = "modules", group = "start", title = "Choisir tes modules",
      text = "Garde seulement ce qui t'intéresse : un module éteint disparaît partout, sauf sa ligne grisée sur l'Accueil.",
      button = "Voir les modules",
      -- the quick start's "what interests you" was gone through to the end
      -- (welcomeEnd is the last way it was left: reopened and closed again it reads "close", so
      -- the first time it was gone through is kept in welcomeDone, Writs/Setup.lua)
      done = function()
          if not WLWritsDB then return false end
          local e = WLWritsDB.welcomeEnd
          if e == "finish" or e == "card" then WLWritsDB.welcomeDone = true end
          return WLWritsDB.welcomeDone == true
      end,
      open = Setting("general", "Modules") },
    { key = "clicks", group = "start", title = "Les raccourcis de clic",
      text = "Alt-clic sur un joueur pour l'inviter, une touche + clic droit sur un ennemi pour tirer. Éteints au départ : allume ceux qui te servent.",
      button = "Régler les clics",
      shown = function() return WP.ClicksDB ~= nil end,
      done = function()
          local ok, d = pcall(WP.ClicksDB)
          return ok and type(d) == "table" and (d.chat or d.world or d.link or d.shoot) and true or false
      end,
      open = Setting("general", "Clics") },
    { key = "guide", group = "quests", title = "Choisir un premier guide",
      text = "Un donjon, un raid ou tes quêtes de classe : la route part de là où tu es, dans le bon ordre.",
      button = "Choisir un guide",
      shown = function() return On("dungeons") and root.ShowPicker ~= nil end,
      -- a first guide: once picked it stays ticked when the route is finished or cleared
      done = function()
          local db = CharDB()
          db.welcome = type(db.welcome) == "table" and db.welcome or {}
          if db.welcome.guided then return true end
          local ok, v = pcall(function() return root.GuideStatus and root.GuideStatus() end)
          if ok and v ~= nil and v ~= false then db.welcome.guided = true; return true end
          return false
      end,
      open = function()
          CloseHub()
          Glow(function() root.ShowPicker() end, "WLDTPicker", { function() return _G.WLDTPicker and _G.WLDTPicker.go end })
      end },
    { key = "gps", group = "travel", title = "Régler le GPS",
      text = "Le chemin à pied en points sur la carte, le repère dans le monde, et la pierre de foyer : quand le trajet la prend, un clic sur son icône près de la flèche la lance.",
      button = "Régler le GPS",
      open = Setting("gps", "Trajet") },
    { key = "spec", group = "items", title = "Ta spé pour les améliorations",
      text = "Le jeu ne laisse pas lire tes talents : WL Helper a pris la spé la plus courante de ta classe. Vérifie-la, les flèches vertes en dépendent.",
      button = "Choisir ma spé",
      shown = function()
          if not On("upgrades") then return false end
          local Wt = WP.Weights
          local ok, guessed = pcall(function() return Wt and Wt.SpecGuessed and Wt.SpecGuessed() end)
          local db = CharDB()
          db.welcome = type(db.welcome) == "table" and db.welcome or {}
          -- once asked, the line stays (picking a spec ticks it, it does not vanish)
          if ok and guessed then db.welcome.specAsked = true end
          return db.welcome.specAsked == true
      end,
      done = function()
          local Wt = WP.Weights
          local ok, guessed = pcall(function() return Wt and Wt.SpecGuessed and Wt.SpecGuessed() end)
          return ok and guessed == false
      end,
      open = function() if WP.Help and WP.Help.ShowMe then WP.Help.ShowMe("upgrades") end end },
    { key = "budget", group = "items", title = "Ton budget pour les Writs",
      text = "Le plan d'achat dépense au plus cette somme, sur les Writs qui rapportent le plus de réputation.",
      button = "Choisir un budget",
      shown = function() return On("writs") and WP.Open ~= nil end,
      done = function() return WLWritsDB ~= nil and WLWritsDB.budget ~= nil end,
      open = function()
          CloseHub()
          Glow(function() WP.Open("writs"); if WP.ShowTab then WP.ShowTab("shop") end end, "WLHelperComptoir",
              { function()
                  -- the budget's segmented control: the parent of its "Sans limite" segment
                  local b = WP.FindIn and WP.FindIn(_G.WLHelperComptoir, { Word("Sans limite") })
                  return b and b.GetParent and b:GetParent() or b
              end })
      end },
    { key = "crafter", group = "items", title = "Ta fiche d'artisan",
      text = "Dis à la guilde si tu es disponible pour fabriquer, avec une note si tu veux (horaires, ce que tu fournis).",
      button = "Voir ma fiche",
      shown = function() return On("orders") and WP.ShowOrdersTab ~= nil end,
      done = function()
          if CharDB().crafterStatus ~= nil then return true end
          -- the note is account-wide, in the orders profile (Writs/Orders.lua O.SetNote)
          local o = type(WLWritsDB) == "table" and WLWritsDB.orders
          local pr = type(o) == "table" and o.profile
          return type(pr) == "table" and type(pr.note) == "string" and pr.note ~= ""
      end,
      open = function()
          CloseHub()
          Glow(function() WP.ShowOrdersTab("find") end, "WLHelperOrders",
              { { Word("Ma fiche"), Word("Ma fiche d'artisan"), Word("Partager mes recettes") } })
      end },
    { key = "shared", group = "guild", title = "Les quêtes en commun",
      text = "Qui dans la guilde a les mêmes quêtes de donjon que toi, pour grouper. Le partage se règle dans Réglages, Guilde.",
      button = "Voir les quêtes",
      shown = function() return On("guild") and WP.Shared ~= nil and WP.Shared.Show ~= nil end,
      open = function() CloseHub(); WP.Shared.Show() end },
    { key = "keys", group = "guild", title = "Le passeport des clés",
      text = "Les clés de donjon que tu as, et qui dans la guilde a celles qui te manquent.",
      button = "Ouvrir le passeport",
      shown = function() return On("keys") and WP.ToggleKeys ~= nil end,
      open = function() CloseHub(); WP.ToggleKeys() end },
}

ns.AddEnglish({
    ["Pour commencer"] = "To start with",
    ["Choisir tes modules"] = "Pick your modules",
    ["Garde seulement ce qui t'intéresse : un module éteint disparaît partout, sauf sa ligne grisée sur l'Accueil."] = "Keep only what you care about: a module you switch off disappears everywhere, except its greyed line on Home.",
    ["Voir les modules"] = "See the modules",
    ["Les raccourcis de clic"] = "Click shortcuts",
    ["Alt-clic sur un joueur pour l'inviter, une touche + clic droit sur un ennemi pour tirer. Éteints au départ : allume ceux qui te servent."] = "Alt-click a player to invite them, a key + right-click an enemy to shoot. They start off: switch on the ones you'll use.",
    ["Régler les clics"] = "Set up clicks",
    ["Choisir un premier guide"] = "Pick a first guide",
    ["Un donjon, un raid ou tes quêtes de classe : la route part de là où tu es, dans le bon ordre."] = "A dungeon, a raid or your class quests: the route starts where you are, in the right order.",
    ["Régler le GPS"] = "Set up the GPS",
    ["Le chemin à pied en points sur la carte, le repère dans le monde, et la pierre de foyer : quand le trajet la prend, un clic sur son icône près de la flèche la lance."] = "The walking path as dots on the map, the marker in the world, and your Hearthstone: when the route uses it, click its icon by the arrow to cast it.",
    ["Ta spé pour les améliorations"] = "Your spec for upgrades",
    ["Le jeu ne laisse pas lire tes talents : WL Helper a pris la spé la plus courante de ta classe. Vérifie-la, les flèches vertes en dépendent."] = "The game doesn't let us read your talents, so WL Helper took your class's most common spec. Check it: the green arrows depend on it.",
    ["Choisir ma spé"] = "Pick my spec",
    ["Ton budget pour les Writs"] = "Your Writs budget",
    ["Le plan d'achat dépense au plus cette somme, sur les Writs qui rapportent le plus de réputation."] = "The shopping plan spends at most this much, on the Writs that bring the most reputation.",
    ["Choisir un budget"] = "Set a budget",
    ["Ta fiche d'artisan"] = "Your crafter card",
    ["Dis à la guilde si tu es disponible pour fabriquer, avec une note si tu veux (horaires, ce que tu fournis)."] = "Tell the guild whether you're available to craft, with a note if you like (hours, what you provide).",
    ["Voir ma fiche"] = "See my card",
    ["Les quêtes en commun"] = "Shared quests",
    ["Qui dans la guilde a les mêmes quêtes de donjon que toi, pour grouper. Le partage se règle dans Réglages, Guilde."] = "Who in the guild has the same dungeon quests as you, to group up. Sharing is set in Settings, Guild.",
    ["Voir les quêtes"] = "See the quests",
    ["Le passeport des clés"] = "The key passport",
    ["Les clés de donjon que tu as, et qui dans la guilde a celles qui te manquent."] = "The dungeon keys you have, and who in the guild has the ones you're missing.",
    ["Ouvrir le passeport"] = "Open the passport",
})

-- WP.WelcomeItems([group]) -> the entries listed, in the list's order, each with .auto (the saved
-- settings say it is set), .ticked (ticked by hand) and .isDone (either).
-- WP.WelcomeTick(key, on) ticks or unticks one by hand (per character).
local function Ticks()
    local db = CharDB()
    db.welcome = type(db.welcome) == "table" and db.welcome or {}
    db.welcome.done = type(db.welcome.done) == "table" and db.welcome.done or {}
    return db.welcome.done
end
function WP.WelcomeItems(group)
    local out, ticks = {}, Ticks()
    for _, e in ipairs(WP.WELCOME) do
        if group == nil or e.group == group then
            local okS, shown = true, true
            if e.shown then okS, shown = pcall(e.shown) end
            if okS and shown then
                local auto = false
                if e.done then local okD, v = pcall(e.done); auto = okD and v == true end
                e.auto, e.ticked = auto, ticks[e.key] == true
                e.isDone = auto or e.ticked
                out[#out + 1] = e
            end
        end
    end
    return out
end
function WP.WelcomeTick(key, on) Ticks()[key] = on and true or nil end
-- -> done, total over every activity
function WP.WelcomeProgress()
    local n, total = 0, 0
    for _, e in ipairs(WP.WelcomeItems()) do total = total + 1; if e.isDone then n = n + 1 end end
    return n, total
end
