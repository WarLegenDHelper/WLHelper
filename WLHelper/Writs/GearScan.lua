-- Writs/GearScan.lua: "/wlh gearscan" reads, in your game, the items of Naowh's BiS lists that WL
-- Helper Gear does not have in its list (Forever's own sets, the Mark of Fordring, some trinkets
-- and weapons): their stats, slot, level, and the lines of their tooltip ("Use:", "Chance on hit:").
-- Saved in WLWritsDB.gearScan after a /reload, so WL Helper Gear's list and its effects table can
-- be completed with the game's own values (report: "our recommendations go against the BiS lists").
-- Read only: nothing is sent anywhere.
local ADDON, root = ...
local ns = root.Writs
local WP = ns.WP
local L = ns.L

ns.AddEnglish({
    ["Relevé des objets BiS inconnus de WL Helper Gear : %d à lire."] = "Reading the BiS items WL Helper Gear does not know: %d to read.",
    ["Relevé terminé : %d objets lus, %d pas encore chargés. Fais /reload pour l'enregistrer."] = "Done: %d items read, %d not loaded yet. Type /reload to save it.",
    ["Rien à relever : il faut Naowh Forever (listes BiS) et WL Helper Gear."] = "Nothing to read: it needs Naowh Forever (BiS lists) and WL Helper Gear.",
})

local GS = {}
WP.GearScan = GS

-- every item id of Naowh's BiS lists (level 60 rankings, trinkets, leveling picks), read live
function GS.NaowhIDs()
    local N = rawget(_G, "NaowhForever")
    local out, seen = {}, {}
    local function add(id)
        id = tonumber(id)
        if id and id > 0 and not seen[id] then seen[id] = true; out[#out + 1] = id end
    end
    local B = N and N.BiSData
    for _, sp in ipairs(B and B.specs or {}) do
        for _, list in pairs(type(sp.slots) == "table" and sp.slots or {}) do
            if type(list) == "table" then for _, id in ipairs(list) do add(id) end end
        end
        for _, id in ipairs(type(sp.trinkets) == "table" and sp.trinkets or {}) do add(id) end
    end
    local LV = N and N.BiSLeveling
    for _, byLevel in pairs(LV and LV.specs or {}) do
        for _, byFaction in pairs(type(byLevel) == "table" and byLevel or {}) do
            for _, slots in pairs(type(byFaction) == "table" and byFaction or {}) do
                for _, id in pairs(type(slots) == "table" and slots or {}) do add(id) end
            end
        end
    end
    table.sort(out)
    return out
end

-- the ids WL Helper Gear does not list
function GS.Missing()
    local G = rawget(_G, "WLHelperGear")
    if not (G and G.Listed) then return nil end
    local out = {}
    for _, id in ipairs(GS.NaowhIDs()) do
        local ok, listed = pcall(G.Listed, id)
        if ok and listed == false then out[#out + 1] = id end
    end
    return out
end

local function Lines(link)
    local out = {}
    local TI = rawget(_G, "C_TooltipInfo")
    if not (TI and TI.GetHyperlink) then return out end
    local ok, data = pcall(TI.GetHyperlink, link)
    if not ok or type(data) ~= "table" then return out end
    for _, l in ipairs(data.lines or {}) do
        local t = l.leftText
        if type(t) == "string" and t ~= "" then out[#out + 1] = t end
    end
    return out
end

-- one item, or nil while the client has not loaded it
function GS.Read(id)
    local Info = (C_Item and C_Item.GetItemInfo) or GetItemInfo
    local name, link, q, ilvl, req, _, _, _, equipLoc, _, _, classID, subID = Info(id)
    if not (name and link) then return nil end
    local Stats = (C_Item and C_Item.GetItemStats) or GetItemStats
    local stats = {}
    local okS, st = pcall(Stats, link)
    if okS and type(st) == "table" then for k, v in pairs(st) do if type(v) == "number" then stats[k] = v end end end
    local lines = Lines(link)
    -- the tooltip of a just-loaded item can come empty: read again later
    if #lines < 2 then return nil end
    return { name = name, q = q, ilvl = ilvl, req = req, loc = equipLoc, class = classID, sub = subID, stats = stats, lines = lines }
end

local running
function GS.Run()
    local todo = GS.Missing()
    if not todo or #todo == 0 then
        WP.Print(L("Rien à relever : il faut Naowh Forever (listes BiS) et WL Helper Gear."))
        return
    end
    if running then return end
    running = true
    WLWritsDB.gearScan = WLWritsDB.gearScan or {}
    local db = WLWritsDB.gearScan
    WP.Print(string.format(L("Relevé des objets BiS inconnus de WL Helper Gear : %d à lire."), #todo))
    local Request = C_Item and C_Item.RequestLoadItemDataByID
    local pass = 0
    local function Step()
        pass = pass + 1
        local left = 0
        for _, id in ipairs(todo) do
            if not db[id] then
                local ok, r = pcall(GS.Read, id)
                if ok and r then db[id] = r
                else
                    left = left + 1
                    if Request then pcall(Request, id) end
                end
            end
        end
        if left > 0 and pass < 8 then C_Timer.After(2, Step); return end
        running = false
        local got = 0
        for _, id in ipairs(todo) do if db[id] then got = got + 1 end end
        WP.Print(string.format(L("Relevé terminé : %d objets lus, %d pas encore chargés. Fais /reload pour l'enregistrer."), got, #todo - got))
    end
    Step()
end
