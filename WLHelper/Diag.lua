-- Diag.lua: /wlh diag. One look at what this client offers to addons (functions present, what
-- the talent, quest, map, profession, auction and mail functions answer), saved in
-- WLDTDB.diag so it can be read from the SavedVariables file after a /reload, instead of asking
-- players to paste /run lines. Nothing is sent anywhere; nothing is changed in the game.
local ADDON, ns = ...

local function secret(v) return issecretvalue ~= nil and issecretvalue(v) end
local function show(v)
  if secret(v) then return "<secret>" end
  local t = type(v)
  if t == "table" then
    local n, keys = 0, {}
    for k in pairs(v) do n = n + 1; if #keys < 8 then keys[#keys + 1] = tostring(k) end end
    return "{" .. n .. ": " .. table.concat(keys, ",") .. "}"
  end
  return tostring(v)
end
local function call(f, ...)
  if type(f) ~= "function" then return "absent" end
  local r = { pcall(f, ...) }
  if not r[1] then return "error: " .. tostring(r[2]):sub(1, 80) end
  local out = {}
  for i = 2, math.min(#r, 9) do out[#out + 1] = show(r[i]) end
  return table.concat(out, " | ")
end

local PRESENT = {
  "GetNumTalentTabs", "GetTalentTabInfo", "GetTalentInfo", "GetSpecialization", "GetPrimaryTalentTree",
  "C_ClassTalents", "C_Traits", "C_SpecializationInfo", "C_TradeSkillUI", "GetProfessions", "GetProfessionInfo",
  "C_QuestLog", "GetQuestLogTitle", "GetQuestLogLeaderBoard", "C_Map", "C_TaxiMap", "C_AuctionHouse", "QueryAuctionItems",
  "C_Item", "C_Container", "C_Spell", "GetSpellCooldown", "C_EncodingUtil", "C_ChatInfo", "C_AddOns", "C_Timer",
  "C_TooltipInfo", "C_PlayerInfo", "C_LFGList", "C_Calendar", "C_GuildInfo", "GetGuildRosterInfo", "C_Reputation",
  "C_CurrencyInfo", "C_PvP", "GetPVPLifetimeStats", "DeleteCursorItem", "C_NewItems", "C_Transmog", "C_EquipmentSet",
  "SetPortraitTextureFromCreatureDisplayID", "UnitPosition", "GetInstanceInfo", "issecretvalue",
}

function ns.Diag()
  local lines = {}
  local function add(k, v) lines[#lines + 1] = k .. " = " .. tostring(v) end
  add("build", call(GetBuildInfo))
  add("locale", GetLocale and GetLocale())
  add("player", call(UnitClass, "player") .. " / " .. call(UnitRace, "player") .. " / " .. call(UnitFactionGroup, "player") .. " / lvl " .. call(UnitLevel, "player"))
  for _, name in ipairs(PRESENT) do add("has " .. name, _G[name] ~= nil) end
  -- talents
  local cfg
  if C_ClassTalents and C_ClassTalents.GetActiveConfigID then cfg = select(2, pcall(C_ClassTalents.GetActiveConfigID)) end
  add("talents.config", show(cfg))
  if cfg and C_Traits and C_Traits.GetConfigInfo then
    local ok, info = pcall(C_Traits.GetConfigInfo, cfg)
    if ok and type(info) == "table" then
      add("talents.treeIDs", show(info.treeIDs))
      for i, tid in ipairs(info.treeIDs or {}) do
        local okN, nodes = pcall(C_Traits.GetTreeNodes, tid)
        local sum, n = 0, 0
        if okN and type(nodes) == "table" then
          for _, nid in ipairs(nodes) do
            local okD, ni = pcall(C_Traits.GetNodeInfo, cfg, nid)
            if okD and type(ni) == "table" and not secret(ni.ranksPurchased) then n = n + 1; sum = sum + (ni.ranksPurchased or 0) end
          end
        end
        add("talents.tree" .. i, "id " .. tostring(tid) .. ", nodes " .. n .. ", points " .. sum)
      end
    end
  end
  if C_SpecializationInfo then add("spec.GetSpecialization", call(C_SpecializationInfo.GetSpecialization)) end
  local W = ns.Writs and ns.Writs.WP and ns.Writs.WP.Weights
  if W then add("wlhelper.spec", (W.SpecName and W.SpecName() or "?") .. (W.SpecGuessed and W.SpecGuessed() and " (guessed)" or "")) end
  -- quests and maps
  local here = C_Map and C_Map.GetBestMapForUnit and select(2, pcall(C_Map.GetBestMapForUnit, "player"))
  add("map.here", show(here))
  if here and C_QuestLog and C_QuestLog.GetQuestsOnMap then
    local ok, list = pcall(C_QuestLog.GetQuestsOnMap, here)
    add("quests.onMap", ok and type(list) == "table" and (#list .. " quests") or "error")
  end
  if C_QuestLog then
    add("quests.numEntries", call(C_QuestLog.GetNumQuestLogEntries))
    add("quests.GetQuestObjectives", type(C_QuestLog.GetQuestObjectives))
    add("quests.IsQuestFlaggedCompleted", type(C_QuestLog.IsQuestFlaggedCompleted))
    -- 93404 Rot and Regret, 93594 Word of the Woods: done? (a test of the game's own answers)
    add("quests.done.93594", call(C_QuestLog.IsQuestFlaggedCompleted, 93594))
  end
  -- the game's own list of quests you can pick up here (the "!" on the map): if this client has it,
  -- the guide can ask the game instead of trusting the data
  add("has C_QuestLine", C_QuestLine ~= nil)
  if C_QuestLine and here then
    for _, fn in ipairs({ "GetAvailableQuestLines", "GetQuestLineQuests", "RequestQuestLinesForMap", "GetQuestLineInfo" }) do
      add("questline." .. fn, type(C_QuestLine[fn]))
    end
    if C_QuestLine.RequestQuestLinesForMap then pcall(C_QuestLine.RequestQuestLinesForMap, here) end
    if C_QuestLine.GetAvailableQuestLines then
      local ok, lines = pcall(C_QuestLine.GetAvailableQuestLines, here)
      if ok and type(lines) == "table" then
        local ids = {}
        for i, l in ipairs(lines) do if i <= 12 and type(l) == "table" then ids[#ids + 1] = tostring(l.questID or l.questLineID or "?") .. ":" .. tostring(l.questName or l.questLineName or "") end end
        add("questline.available", #lines .. " | " .. table.concat(ids, ", "))
      else add("questline.available", ok and type(lines) or ("error " .. tostring(lines))) end
    end
  end
  add("has C_TaskQuest", C_TaskQuest ~= nil)
  if C_QuestLog and C_QuestLog.GetQuestsOnMap and here then
    local ok, list = pcall(C_QuestLog.GetQuestsOnMap, here)
    if ok and type(list) == "table" then
      local ids = {}
      for i, q in ipairs(list) do if i <= 12 and type(q) == "table" then ids[#ids + 1] = tostring(q.questID) end end
      add("quests.onMap.ids", table.concat(ids, ","))
    end
  end
  -- spells and cooldowns (the hearthstone spell 8690)
  if C_Spell and C_Spell.GetSpellCooldown then
    local ok, cd = pcall(C_Spell.GetSpellCooldown, 8690)
    add("cooldown.8690", ok and type(cd) == "table" and ("start " .. show(cd.startTime) .. ", duration " .. show(cd.duration) .. ", isActive " .. show(cd.isActive)) or "error")
  end
  -- professions
  add("professions", call(GetProfessions))
  if C_TradeSkillUI then add("tradeskill.GetAllRecipeIDs", type(C_TradeSkillUI.GetAllRecipeIDs)) end
  -- other addons that matter
  local isLoaded = (C_AddOns and C_AddOns.IsAddOnLoaded) or IsAddOnLoaded
  for _, a in ipairs({ "LibForeverData", "GearedForever", "WLHelper_Gear", "WLHelper_Nav", "Polestar", "ForeverDungeonJournal",
    "NaowhForever", "EllesmereUI", "TomTom", "Questie", "RXPGuides", "ZygorGuidesViewerForever", "Auctionator", "TradeSkillMaster" }) do
    add("addon " .. a, isLoaded and select(2, pcall(isLoaded, a)) and "loaded" or "no")
  end
  WLDTDB.diag = { time = time and time() or 0, lines = lines }
  print("|cffce1918WL|r Helper: diag saved (" .. #lines .. " lines). /reload to write it to disk.")
  return lines
end

-- "/wlh diag": wraps the /wlh handler once the addon is loaded (the other words go through)
local hook = CreateFrame("Frame")
pcall(hook.RegisterEvent, hook, "PLAYER_LOGIN")
hook:SetScript("OnEvent", function()
  local orig = SlashCmdList and SlashCmdList.WLDUNGEONTOOL
  if not orig then return end
  SlashCmdList.WLDUNGEONTOOL = function(msg, ...)
    local w = (msg or ""):match("^%s*(%S+)")
    if w and w:lower() == "diag" then ns.Diag(); return end
    return orig(msg, ...)
  end
end)
