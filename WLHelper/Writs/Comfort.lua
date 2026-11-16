-- Writs/Comfort.lua: the Comptoir's little helps, each one a switch in the options (comfort.*):
--   autoAccept  accept the writ's quest as soon as the envelope is opened;
--   autoTurnIn  hand writs in by themselves at the NPC (gossip, progress and reward windows);
--   reminder    one chat line at login: writs ready, envelopes to open;
--   tooltip     on an envelope: reputation, the requested item, where it goes, done today or not.
-- Only writ quests are touched; every other quest goes through the game as usual.
local ADDON, root = ...
root.Writs = root.Writs or {}
local ns = root.Writs
local WP = ns.WP
local L = ns.L
local S = ns.S

ns.AddEnglish({
    ["1 writ prêt à rendre"] = "1 writ ready to turn in",
    ["%d writs prêts à rendre"] = "%d writs ready to turn in",
    ["1 enveloppe à ouvrir"] = "1 envelope to open",
    ["%d enveloppes à ouvrir"] = "%d envelopes to open",
    ["WL Helper : writ %s, %d points de réputation"] = "WL Helper: %s writ, %d reputation",
    ["Objet demandé : %s, dans tes sacs"] = "Requested item: %s, in your bags",
    ["Objet demandé : %s, environ %s à l'HV"] = "Requested item: %s, about %s at the AH",
    ["Objet demandé : %s"] = "Requested item: %s",
    ["À rendre à %s, %s %.0f, %.0f"] = "Turn in to %s, %s %.0f, %.0f",
    ["À rendre : %s %.0f, %.0f"] = "Turn in: %s %.0f, %.0f",
    ["Tu as %s et %s. Tape /wlh trade pour ouvrir les Writs."] = "You have %s and %s. Type /wlh trade to open the trading post.",
    ["Tu as %s. Tape /wlh trade gps pour lancer la tournée."] = "You have %s. Type /wlh trade gps to start the tour.",
    ["Tu as %s. Tape /wlh trade pour ouvrir les Writs."] = "You have %s. Type /wlh trade to open the trading post.",
    ["Déjà rendu aujourd'hui"] = "Already turned in today",
    ["Réservé à l'autre faction"] = "Other faction only",
})

local function Count(n, one, many) return n == 1 and L(one) or string.format(L(many), n) end

local function On(key)
    local c = WLWritsDB and WLWritsDB.comfort
    return not c or c[key] ~= false
end

-- writ item ID -> writ, quest ID -> writ
local byItem, byQuest = {}, {}
local function Index()
    if next(byItem) then return end
    for _, w in ipairs(ns.WRITS) do
        byItem[w.writ] = w
        if w.quest then byQuest[w.quest] = w end
    end
end

-- ---------------------------------------------------------------- accept and turn in

local function CurrentQuestID()
    return GetQuestID and GetQuestID() or 0
end

-- Envelope names, as the NPC's greeting lists them (the client's real names, plus the English data
-- names); kept for the session only once every real name has loaded.
local titles
local function WritTitles()
    if titles then return titles end
    local t, complete = {}, true
    local getName = C_Item and C_Item.GetItemNameByID or GetItemInfo
    for _, w in ipairs(ns.WRITS) do
        local ok, real = false, nil
        if getName then ok, real = pcall(getName, w.writ) end
        if ok and real then t[real] = w else complete = false end
        if w.writName then t[w.writName] = t[w.writName] or w end
    end
    if complete then titles = t end
    return t
end

local reminded = false

-- "A Sealed Crate": the quests that take a Supply Shipment at the Inventory Intake NPCs
-- (Dokimi in the Barrens, Marcy Baker in Redridge), one per shipment.
local CRATE_QUESTS = { [91899] = true, [91900] = true, [91901] = true, [91902] = true, [91903] = true, [91904] = true, [91905] = true }
local CRATE_NPCS = { [256386] = true, [256390] = true }
local function AtIntake()
    local guid = UnitGUID and UnitGUID("npc")
    -- inside instances the NPC's GUID comes back secret: no reading it (the title test still works)
    if type(guid) ~= "string" or (issecretvalue and issecretvalue(guid)) then return false end
    local id = tonumber(guid:match("%-(%d+)%-%x+$"))
    return id and CRATE_NPCS[id] or false
end
local function CrateQuest(id) return id and CRATE_QUESTS[id] or false end

local f = CreateFrame("Frame")
pcall(f.RegisterEvent, f, "QUEST_DETAIL")
pcall(f.RegisterEvent, f, "QUEST_PROGRESS")
pcall(f.RegisterEvent, f, "QUEST_COMPLETE")
pcall(f.RegisterEvent, f, "GOSSIP_SHOW")
pcall(f.RegisterEvent, f, "QUEST_GREETING")
pcall(f.RegisterEvent, f, "PLAYER_ENTERING_WORLD")
f:SetScript("OnEvent", function(_, event, a1, a2)
    if not WP.ModuleOn("writs") then return end
    Index()
    if IsShiftKeyDown() and event ~= "PLAYER_ENTERING_WORLD" then return end   -- Shift: do it by hand
    -- only the crate quest itself (by ID; by title at the Intake when the ID reads 0), never
    -- another quest those NPCs may give
    local qid = CurrentQuestID()
    local crate = On("autoCrates") and (CrateQuest(qid)
        or (qid == 0 and AtIntake() and GetTitleText and (GetTitleText() or ""):find("Sealed Crate", 1, true) ~= nil))
    if event == "QUEST_DETAIL" then
        if (On("autoAccept") and byQuest[CurrentQuestID()]) or crate then AcceptQuest() end
    elseif event == "QUEST_PROGRESS" then
        if ((On("autoTurnIn") and byQuest[CurrentQuestID()]) or crate) and IsQuestCompletable and IsQuestCompletable() then CompleteQuest() end
    elseif event == "QUEST_COMPLETE" then
        if ((On("autoTurnIn") and byQuest[CurrentQuestID()]) or crate) and (GetNumQuestChoices() or 0) <= 1 then GetQuestReward(1) end
    elseif event == "GOSSIP_SHOW" then
        -- at the Inventory Intake: hand in a shipment (the quest is offered once per crate you hold)
        if On("autoCrates") and AtIntake() and C_GossipInfo then
            for _, q in ipairs(C_GossipInfo.GetActiveQuests and C_GossipInfo.GetActiveQuests() or {}) do
                if q.isComplete and (CrateQuest(q.questID) or (q.title or ""):find("Sealed Crate", 1, true)) then C_GossipInfo.SelectActiveQuest(q.questID); return end
            end
            for _, q in ipairs(C_GossipInfo.GetAvailableQuests and C_GossipInfo.GetAvailableQuests() or {}) do
                if CrateQuest(q.questID) or (q.title or ""):find("Sealed Crate", 1, true) then C_GossipInfo.SelectAvailableQuest(q.questID); return end
            end
        end
        if not On("autoTurnIn") then return end
        if C_GossipInfo and C_GossipInfo.GetActiveQuests then
            for _, q in ipairs(C_GossipInfo.GetActiveQuests() or {}) do
                if q.isComplete and byQuest[q.questID] then C_GossipInfo.SelectActiveQuest(q.questID); return end
            end
        end
    elseif event == "QUEST_GREETING" then
        if not On("autoTurnIn") or not GetNumActiveQuests then return end
        local titles = WritTitles()
        for i = 1, GetNumActiveQuests() do
            local title, complete = GetActiveTitle(i)
            if complete and title and titles[title] then SelectActiveQuest(i); return end
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        -- at login, not after a /reload; a client that sends no flags gets it once per session
        local login = a1 == nil and a2 == nil or a1 == true
        if login and not reminded and On("reminder") then
            reminded = true
            -- once per login, a few seconds in so the quest log is there
            C_Timer.After(6, function()
                local ready, bag = 0, 0
                for _, r in ipairs(WP.Rows()) do
                    if r.state == "ready" then ready = ready + 1 elseif r.state == "bag" then bag = bag + 1 end
                end
                local r = Count(ready, "1 writ prêt à rendre", "%d writs prêts à rendre")
                local b = Count(bag, "1 enveloppe à ouvrir", "%d enveloppes à ouvrir")
                if ready > 0 and bag > 0 then WP.Print(string.format(L("Tu as %s et %s. Tape /wlh trade pour ouvrir les Writs."), r, b), true)
                elseif ready > 0 then WP.Print(string.format(L("Tu as %s. Tape /wlh trade gps pour lancer la tournée."), r), true)
                elseif bag > 0 then WP.Print(string.format(L("Tu as %s. Tape /wlh trade pour ouvrir les Writs."), b), true) end
            end)
        end
    end
end)

-- ---------------------------------------------------------------- envelope tooltip

local function AddLines(tooltip, itemID)
    if not On("tooltip") or not itemID or not WP.ModuleOn("writs") then return end
    Index()
    local w = byItem[itemID]
    if not w then return end
    local mySide = UnitFactionGroup("player") == "Alliance" and 1 or 2
    local C = S.C
    tooltip:AddLine(" ")
    tooltip:AddLine(string.format(L("WL Helper : writ %s, %d points de réputation"), WP.Tier(w.tier), w.rep), C.accentSoft[1], C.accentSoft[2], C.accentSoft[3])
    if w.side and w.side ~= mySide then
        tooltip:AddLine(L("Réservé à l'autre faction"), C.bad[1], C.bad[2], C.bad[3])
        return
    end
    local have = (C_Item and C_Item.GetItemCount and C_Item.GetItemCount(w.item)) or 0
    local need = w.count or 1
    local item = WP.ItemName(w.item, w.itemName) .. (need > 1 and (" x" .. need) or "")
    if have >= need then
        tooltip:AddLine(string.format(L("Objet demandé : %s, dans tes sacs"), item), C.ok[1], C.ok[2], C.ok[3], true)
    else
        local price = WP.Price(w.item, w.snapItem)
        tooltip:AddLine(price and string.format(L("Objet demandé : %s, environ %s à l'HV"), item, S.Money(price * (need - have)))
            or string.format(L("Objet demandé : %s"), item), C.text[1], C.text[2], C.text[3], true)
    end
    if w.map then
        if w.npcName then
            tooltip:AddLine(string.format(L("À rendre à %s, %s %.0f, %.0f"), w.npcName, WP.ZoneName(w.map), w.x, w.y), C.muted[1], C.muted[2], C.muted[3], true)
        else
            tooltip:AddLine(string.format(L("À rendre : %s %.0f, %.0f"), WP.ZoneName(w.map), w.x, w.y), C.muted[1], C.muted[2], C.muted[3], true)
        end
    end
    if w.quest and WP.State(w) == "done" then
        tooltip:AddLine(L("Déjà rendu aujourd'hui"), C.warn[1], C.warn[2], C.warn[3])
    end
    tooltip:Show()
end

if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip, info)
        if tooltip ~= GameTooltip and tooltip ~= ItemRefTooltip then return end
        AddLines(tooltip, info and info.id)
    end)
elseif GameTooltip and GameTooltip.HookScript then
    GameTooltip:HookScript("OnTooltipSetItem", function(tooltip)
        local _, link = tooltip:GetItem()
        AddLines(tooltip, link and tonumber(link:match("item:(%d+)")))
    end)
end
