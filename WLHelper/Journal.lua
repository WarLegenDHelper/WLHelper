-- Journal.lua: two things for the dungeon you are in.
--  * "Dungeon journal" in the guide's "..." menu: opens the bosses and loot of the step's dungeon in
--    Naowh Forever's Dungeon Journal, else in Forever Dungeon Journal (/dj). Read live, nothing copied.
--  * Rare alert: a rare or rare-elite monster in sight inside a dungeon (target, mouseover or
--    nameplate) gets one warning on screen and a sound, once per monster. Works without any data:
--    the game says itself which monsters are rare.
local ADDON, ns = ...
local L = ns.L

-- ---------------------------------------------------------------- the journal
local function CurrentDungeonKey()
  local f = ns.frame
  -- standing in one of the route's dungeons: that one, whatever step is on screen
  local inside = ns.InsideKey and ns.InsideKey()
  if inside then return inside end
  local steps = ns.route and ns.route.steps
  local st = steps and f and steps[f.view or f.auto or 1]
  -- the step's dungeon (Engine.lua knows it for every step, gates and prerequisites included)
  local sk = st and ns.StepDungeon and ns.StepDungeon(st)
  if sk and ns.D and ns.D[sk] then return sk end
  if st and st.d then return st.d end
  -- inside an instance with no route: by the instance's map ID
  local _, kind, _, _, _, _, _, instanceID = GetInstanceInfo()
  if kind == "party" or kind == "raid" then
    for key, d in pairs(ns.D or {}) do if d.inst == instanceID then return key end end
  end
end

local function NaowhJournal() return NaowhForever and NaowhForever.Journal end

-- Naowh's dungeon for ours: same English name, or the one whose name starts like ours
-- ("Dire Maul: West" / "Dire Maul West", "Zul'Farrak"...).
local function Simplify(s) return (tostring(s or ""):lower():gsub("^the ", ""):gsub("[^%w]", "")) end
local function NaowhDungeon(key)
  local J = NaowhJournal()
  local d = ns.D and ns.D[key]
  if not (J and J.Dungeons and d) then return nil end
  local ok, list = pcall(J.Dungeons)
  if not ok or type(list) ~= "table" then return nil end
  local want = Simplify(d.n)
  local best
  for _, dg in ipairs(list) do
    local a, b = Simplify(dg.english), Simplify(dg.name)
    if a == want or b == want then return dg end
    if not best and want ~= "" and ((a ~= "" and want:find(a, 1, true) == 1) or (a ~= "" and a:find(want, 1, true) == 1)) then best = dg end
  end
  return best
end

function ns.JournalAvailable()
  return (NaowhJournal() ~= nil) or (SlashCmdList and SlashCmdList.FOREVERDUNGEONJOURNAL ~= nil)
end

function ns.OpenJournal()
  local key = CurrentDungeonKey()
  local J = NaowhJournal()
  local dg = key and NaowhDungeon(key)
  if J and dg then
    -- Naowh shows a dungeon's page beside the world map
    if not (WorldMapFrame and WorldMapFrame:IsShown()) then
      if ToggleWorldMap then ToggleWorldMap() elseif WorldMapFrame then WorldMapFrame:Show() end
    end
    local ok, shown = pcall(J.ShowDungeonBesideMap, dg)
    if ok and shown then return end
    if J.OpenDungeonMap and pcall(J.OpenDungeonMap, dg) then return end
  end
  if SlashCmdList and SlashCmdList.FOREVERDUNGEONJOURNAL then
    SlashCmdList.FOREVERDUNGEONJOURNAL("")
    return
  end
  ns.Print(L.JOURNAL_NONE)
end

-- ---------------------------------------------------------------- rare alert
local seen = {}
local function RareOn() return WLDTDB and WLDTDB.rareAlert ~= false and (not ns.GuideOn or ns.GuideOn()) end

local function Check(unit)
  if not RareOn() or not UnitExists(unit) then return end
  -- the bosses strip (Bosses.lua) has the banner with its target button: one alert, not two
  if ns.RareAlert then pcall(ns.RareAlert, unit) return end
  local inInstance = IsInInstance and IsInInstance()
  if not inInstance then return end
  local class = UnitClassification(unit)
  if class ~= "rare" and class ~= "rareelite" then return end
  if UnitIsDead(unit) or UnitIsFriend("player", unit) then return end
  local guid = UnitGUID(unit)
  if not guid or seen[guid] then return end
  seen[guid] = true
  local name = UnitName(unit) or "?"
  local msg = L.RARE_SEEN:format(name)
  if RaidNotice_AddMessage and RaidWarningFrame then
    RaidNotice_AddMessage(RaidWarningFrame, msg, { r = 0.81, g = 0.1, b = 0.09 })
  end
  ns.Print(msg)
  if PlaySound and SOUNDKIT and SOUNDKIT.RAID_WARNING then pcall(PlaySound, SOUNDKIT.RAID_WARNING, "Master") end
end

local ev = CreateFrame("Frame")
pcall(ev.RegisterEvent, ev, "PLAYER_TARGET_CHANGED")
pcall(ev.RegisterEvent, ev, "UPDATE_MOUSEOVER_UNIT")
pcall(ev.RegisterEvent, ev, "NAME_PLATE_UNIT_ADDED")
pcall(ev.RegisterEvent, ev, "PLAYER_ENTERING_WORLD")
ev:SetScript("OnEvent", function(_, e, unit)
  if e == "PLAYER_TARGET_CHANGED" then Check("target")
  elseif e == "UPDATE_MOUSEOVER_UNIT" then Check("mouseover")
  elseif e == "NAME_PLATE_UNIT_ADDED" then if unit then Check(unit) end
  elseif e == "PLAYER_ENTERING_WORLD" then seen = {} end
end)
