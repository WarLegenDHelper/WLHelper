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
      open = function() if WP.ToggleKeys then WP.ToggleKeys() end end, settings = "general", anchor = "Guilde" },
    { key = "shared", group = "quests", label = "Quêtes en commun", icon = "shared", module = "guild",
      available = function() return Has("Shared", "Show") end,
      open = function() if WP.Shared then WP.Shared.Show() end end, settings = "general", anchor = "Guilde" },
    { key = "triage", group = "quests", label = "Tri du journal", icon = "triage", module = "triage",
      available = function() return Has("Triage", "Show") end,
      open = function() if WP.Triage then WP.Triage.Show() end end, settings = "general", anchor = "Outils" },
    { key = "goto", group = "travel", label = "Aller à", icon = { hd = root.ARROW },
      available = function() return Has("GoTo", "Show") end,
      open = function() if WP.GoTo then WP.GoTo.Show("") end end, settings = "gps" },
    { key = "city", group = "travel", label = "Tournée en ville", icon = "city",
      isOn = function() local CT = WP.CityTour; return not (CT and CT.IsOn) or CT.IsOn() and true or false end,
      turnOn = function() local CT = WP.CityTour; if CT and CT.SetOn then CT.SetOn(true) end end,
      available = function() return Has("CityTour", "Show") end,
      open = function() if WP.CityTour then WP.CityTour.Show() end end, settings = "general", anchor = "Outils" },
    { key = "writs", group = "items", label = "Writs", icon = "writs", module = "writs",
      available = function() return Has("Open") end,
      open = function() WP.Open("writs") end, settings = "comptoir" },
    { key = "favor", group = "items", label = "Faveur du marchand", icon = "favor", module = "writs",
      available = function() return Has("Open") end,
      open = function() WP.Open("favor") end, settings = "comptoir" },
    { key = "orders", group = "items", label = "Commandes", icon = "orders", module = "orders",
      available = function() return Has("ToggleOrders") end,
      open = function() if WP.ToggleOrders then WP.ToggleOrders() end end },
    { key = "bags", group = "items", label = "Sacs", icon = "bags", module = "bags",
      available = function() return Has("Cleaner") end,
      open = function() if WP.Cleaner then WP.Cleaner.Toggle() end end, settings = "bags" },
    { key = "upgrades", group = "items", label = "Améliorations", icon = "upgrades", module = "upgrades",
      available = function() return true end,
      open = function() if WP.OpenHub then WP.OpenHub("upgrades") end end, settings = "upgrades", inHub = true },
    { key = "guild", group = "guild", label = "Guilde", icon = "guild", module = "guild",
      available = function() return Has("ToggleGuild") end,
      open = function() if WP.ToggleGuild then WP.ToggleGuild() end end },
    { key = "events", group = "guild", label = "LFG", icon = "events", module = "events",
      available = function() return Has("ToggleEvents") end,
      open = function() if WP.ToggleEvents then WP.ToggleEvents() end end },
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
