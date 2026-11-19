-- Writs/Commands.lua: the /wlh words of the smaller tools, in one place.
-- Main.lua owns /wlh. Like Diag.lua and WhatsNewUI.lua, this file wraps its handler once the addon
-- is loaded: the words below are answered here, every other word goes on to Main.lua untouched.
--   aller / goto [lieu]      Writs/GoTo.lua      "Aller à" (search box, or straight to the place)
--   way <zone> x y [nom]     Writs/Way.lua       the same as /way, for players who know /wlh only
--   cles / keys              Writs/Keys.lua      the key passport
--   ville / city / tournee   Writs/CityTour.lua  the city tour card
--   commun / quetes / quests Writs/SharedQuests  the dungeon quests shared with the guild
--   tri / triage             Writs/LogTriage     the quests that can leave a full log
--   groupes / groups         Writs/Events.lua    the Groupes window (Main.lua also takes lfg, evenements)
--   altclick                 Writs/AltClick.lua  what Alt + click does for this character
--   carte / map              Bosses.lua          the map of the dungeon you are in
--   diag carte / diag map    Writs/Trail.lua     why the walking path shows (or not) on the world map
--   diag quetes / diag quests Writs/QuestFacts   what the game showed for the guide's quests vs Data.lua
--                                                (any other "diag" goes on to Diag.lua)
-- Each tool checks its own module switch: nothing is decided twice here.
local ADDON, root = ...
local ns = root.Writs
local WP = ns.WP

-- "clés", "tournée", "quêtes" typed with accents: accents out before lower(), which may touch
-- UTF-8 bytes on some clients (the same care as Main.lua)
local function Word(w)
    w = w or ""
    for _, a in ipairs({ "é", "è", "ê", "É", "È", "Ê" }) do w = w:gsub(a, "e") end
    return w:lower()
end

local function Run(fn, ...)
    if type(fn) ~= "function" then return false end
    local ok, err = pcall(fn, ...)
    if not ok and geterrorhandler then geterrorhandler()(err) end
    return true
end

-- word -> function(rest): true when the word was ours (even if its tool is missing: the word is
-- then simply ignored rather than read as an unknown command by Main.lua)
local ROUTES = {}
local function Route(words, fn) for _, w in ipairs(words) do ROUTES[w] = fn end end

Route({ "aller", "goto" }, function(rest)
    local G = WP.GoTo
    if not G then return end
    if G.Slash then Run(G.Slash, rest) else Run(G.Show, rest ~= "" and rest or nil) end
end)
Route({ "bis", "meilleur", "best" }, function(rest)
    if WP.Best then Run(WP.Best.Show, rest) end
end)
-- the PvP guide: the battlegrounds window (Writs/Battlegrounds.lua, the set inside it);
-- "/wlh pvp chat" prints the set in the chat as before
Route({ "pvp", "jcj", "bg", "champs", "cdb", "battlegrounds" }, function(rest)
    if Word(rest or "") == "chat" or not (WP.BG and WP.BG.Toggle) then
        if WP.PvP then Run(WP.PvP.Show) end
        return
    end
    Run(WP.BG.Toggle)
end)
Route({ "way" }, function(rest)
    if WP.Way then Run(WP.Way.Command, rest) end
end)
Route({ "cles", "cle", "keys" }, function()
    Run(WP.ToggleKeys or (WP.Keys and WP.Keys.Toggle))
end)
Route({ "ville", "city", "tournee" }, function()
    if WP.CityTour then Run(WP.CityTour.Toggle) end
end)
-- no "shared": one letter from Main.lua's "share" (share quests with the party), too easy to mix up
Route({ "commun", "quetes", "quests", "partage" }, function()
    if WP.Shared then Run(WP.Shared.Toggle) end
end)
Route({ "tri", "triage" }, function()
    if WP.Triage then Run(WP.Triage.Toggle) end
end)
Route({ "groupes", "groupe", "groups" }, function()
    Run(WP.ToggleEvents)
end)
Route({ "altclick" }, function()
    if WP.AltClick then Run(WP.AltClick.Status) end
end)
Route({ "carte", "map" }, function()
    if not root.OpenDungeonMap then return end
    local inside = type(root.InsideKey) == "function" and select(2, pcall(root.InsideKey)) or nil
    Run(root.OpenDungeonMap, type(inside) == "string" and inside or nil)
end)

-- "diag carte": the walking path on the world map (Trail.lua); a route returning false passes the
-- word on (plain "diag" is Diag.lua's)
Route({ "diag" }, function(rest)
    local w = Word(rest:match("^(%S*)"))
    if w == "quetes" or w == "quests" then
        if WP.QuestFacts then Run(WP.QuestFacts.Diag) end
        return
    end
    if w ~= "carte" and w ~= "map" then return false end
    if WP.Trail and WP.Trail.DiagMap then Run(WP.Trail.DiagMap) end
end)

-- exposed for the tests and for Help.lua's clickable commands
WP.ToolCommand = function(msg)
    local w, rest = (msg or ""):match("^%s*(%S*)%s*(.-)%s*$")
    local fn = ROUTES[Word(w)]
    if not fn then return false end
    if fn(rest or "") == false then return false end
    return true
end

local hook = CreateFrame("Frame")
pcall(hook.RegisterEvent, hook, "PLAYER_LOGIN")
hook:SetScript("OnEvent", function()
    local orig = SlashCmdList and SlashCmdList.WLDUNGEONTOOL
    if not orig then return end
    SlashCmdList.WLDUNGEONTOOL = function(msg, ...)
        if WP.ToolCommand(msg) then return end
        return orig(msg, ...)
    end
    -- Diag.lua wraps /wlh at the same login and takes every "diag ...": should it come out on top of
    -- this wrapper, "diag carte" is caught once more over it, on the next frame
    if C_Timer and C_Timer.After then
        C_Timer.After(0, function()
            local top = SlashCmdList and SlashCmdList.WLDUNGEONTOOL
            if not top then return end
            SlashCmdList.WLDUNGEONTOOL = function(msg, ...)
                local w, rest = (msg or ""):match("^%s*(%S*)%s*(%S*)")
                if Word(w) == "diag" and (Word(rest) == "carte" or Word(rest) == "map" or Word(rest) == "quetes" or Word(rest) == "quests") then
                    if WP.ToolCommand(msg) then return end
                end
                return top(msg, ...)
            end
        end)
    end
end)
