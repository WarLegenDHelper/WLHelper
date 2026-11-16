-- Writs/GuideQuests.lua: the guide's quests taken, handed in and shared by themselves, the same way
-- the Comptoir does it for the writs (Writs/Comfort.lua). Four switches (Settings > Quests &
-- dungeons > Guide quests), read from WLDTDB:
--   questAutoAccept   at an NPC, accept the quests of the current route (on by default);
--   questAutoTurnIn   hand them in: progress window, and the reward when there is no choice (on);
--   questAutoShare    once in a group, share a route quest just accepted, once per quest per group (on);
--   questAutoReward   several rewards: take the best upgrade for your spec (off: one chat line says
--                     which one is best and the choice stays yours).
-- Only the quests of the current route (ns.route: ticked dungeons, not unticked in the overview,
-- WLDTDB.off) are touched; every other quest goes through the game as usual. Shift held = by hand.
-- Other addons that automate quests (Questie, Zygor, Leatrix Plus, Naowh QoL, Polestar,
-- Factoruide, EllesmereUI Quest Tracker): our action waits a moment and is dropped when the
-- window was already handled (closed, or another quest on it); sharing is left to Naowh QoL when
-- its own sharing is on. The settings name who else does it.
local ADDON, root = ...
root.Writs = root.Writs or {}
local ns = root.Writs
local WP = ns.WP
local L = ns.L

ns.AddEnglish({
    -- settings
    ["Quêtes du guide"] = "Guide quests",
    ["Prendre les quêtes du guide tout seul"] = "Pick up the guide's quests by themselves",
    ["En parlant au PNJ, seulement les quêtes de ta route. Garde Maj enfoncée pour le faire à la main."] =
        "When you talk to the NPC, only the quests of your route. Hold Shift to do it by hand.",
    ["Rendre les quêtes du guide tout seul"] = "Turn in the guide's quests by themselves",
    ["La récompense est prise toute seule quand il n'y a pas de choix. Garde Maj enfoncée pour le faire à la main."] =
        "The reward is taken by itself when there is no choice. Hold Shift to do it by hand.",
    ["Partager les quêtes du guide avec le groupe"] = "Share the guide's quests with the group",
    ["Une quête de ta route que tu prends en groupe est partagée une fois, hors combat."] =
        "A quest of your route you pick up in a group is shared once, out of combat.",
    ["Choisir la récompense tout seul (la meilleure amélioration)"] = "Pick the reward by itself (the best upgrade)",
    ["Quand une quête du guide offre un choix, la meilleure amélioration pour ta spé est prise. Éteint, un message te dit laquelle choisir."] =
        "When a guide quest offers a choice, the best upgrade for your spec is taken. Off, a message tells you which one to pick.",
    ["Aussi fait par %s : WL Helper ne fait rien si la fenêtre est déjà réglée."] =
        "Also done by %s: WL Helper does nothing when the window was already handled.",
    ["Fait par %s : WL Helper le lui laisse."] = "Done by %s: WL Helper leaves it to it.",
    -- rewards
    ["Choisis ta récompense : la meilleure pour toi est %s (+%d %%)."] = "Pick your reward: the best for you is %s (+%d%%).",
    ["Choisis ta récompense : la meilleure pour toi est %s (emplacement vide)."] = "Pick your reward: the best for you is %s (empty slot).",
    ["Choisis ta récompense : aucune n'est une amélioration pour toi."] = "Pick your reward: none of them is an upgrade for you.",
    ["Choisis ta récompense."] = "Pick your reward.",
    ["Choisis ta récompense : objets pas encore chargés par le jeu."] = "Pick your reward: the game has not loaded the items yet.",
    ["Récompense choisie : %s (+%d %%)."] = "Reward picked: %s (+%d%%).",
    ["Récompense choisie : %s (emplacement vide)."] = "Reward picked: %s (empty slot).",
})

local GQ = {}
WP.GuideQuests = GQ

local DELAY = 0.15      -- seconds: another addon's handler of the same event runs first
local SHARE_GAP = 1.5   -- seconds between two pushes

local function Secret(v) return issecretvalue ~= nil and issecretvalue(v) end
local function Num(v) return type(v) == "number" and not Secret(v) and v or nil end
local function Str(v) return type(v) == "string" and not Secret(v) and v or nil end

-- ---------------------------------------------------------------- settings
local DEFAULTS = { questAutoAccept = true, questAutoTurnIn = true, questAutoShare = true, questAutoReward = false }
function GQ.On(key)
    local v = WLDTDB and WLDTDB[key]
    if v == nil then return DEFAULTS[key] == true end
    return v == true
end
function GQ.Set(key, v)
    WLDTDB = WLDTDB or {}
    WLDTDB[key] = v and true or false
end
local On = GQ.On

local function GuideOn() return not root.GuideOn or root.GuideOn() end

-- ---------------------------------------------------------------- the route's quests
-- { [qid] = true } for the quests the current route takes or hands in (unticked ones left out)
function GQ.RouteSet()
    local set = {}
    local steps = root.route and root.route.steps
    if type(steps) ~= "table" then return set end
    local off = WLDTDB and WLDTDB.off
    for _, st in ipairs(steps) do
        for _, n in ipairs(st.acts or {}) do
            local q = Num(n.q)
            if q and (n.kind == "a" or n.kind == "t") and not (off and off[q]) then set[q] = true end
        end
    end
    return set
end
local function InRoute(qid)
    qid = Num(qid)
    if not qid or qid == 0 or not GuideOn() then return false end
    return GQ.RouteSet()[qid] == true
end
GQ.InRoute = InRoute

-- the route's quests by name (the NPC greeting of old quest givers lists titles only)
local function RouteByTitle(title)
    title = Str(title)
    if not title then return nil end
    for qid in pairs(GQ.RouteSet()) do
        local q = root.Q and root.Q[qid]
        if (root.QName and root.QName(qid) == title) or (q and (q.n == title or q.nf == title)) then return qid end
    end
    return nil
end

-- ---------------------------------------------------------------- other addons
-- Who else automates this, read from their own settings (each read guarded: any of them may change).
local function Try(fn) local ok, v = pcall(fn); return ok and v and true or false end
local OTHERS = {
    { "Questie",
        accept = function() return Questie.db.profile.autoAccept.enabled end,
        turnin = function() return Questie.db.profile.autocomplete end },
    { "Zygor",
        accept = function() return ZGV.db.profile.autoaccept end,
        turnin = function() return ZGV.db.profile.autoturnin end },
    { "Leatrix Plus",
        accept = function() return LeaPlusDB.AutomateQuests == "On" end,
        turnin = function() return LeaPlusDB.AutomateQuests == "On" end },
    { "Naowh QoL",
        accept = function() local S = NaowhForever.QoLSettings; return S.Get("enabled") and S.Get("questAccept") end,
        turnin = function() local S = NaowhForever.QoLSettings; return S.Get("enabled") and S.Get("questTurnIn") end,
        share = function() local S = NaowhForever.QoLSettings; return S.Get("enabled") and S.Get("questShare") end },
    { "Polestar",
        accept = function() return Polestar.Get("behavior.autoAccept") end,
        turnin = function() return Polestar.Get("behavior.autoTurnin") end },
    { "Factoruide",
        accept = function() return Factoruide:Get("autoAccept") end,
        turnin = function() return Factoruide:Get("autoTurnIn") end },
    { "EllesmereUI",
        accept = function() return EllesmereUIQuestTracker.Cfg("autoAccept") end,
        turnin = function() return EllesmereUIQuestTracker.Cfg("autoTurnIn") end },
}
GQ.OTHERS = OTHERS
-- names of the addons that do <kind> ("accept", "turnin", "share") right now
function GQ.Owners(kind)
    local out = {}
    for _, o in ipairs(OTHERS) do
        if o[kind] and Try(o[kind]) then out[#out + 1] = o[1] end
    end
    return out
end
-- the line added to a setting's description, or nil
function GQ.OwnerNote(kind)
    local who = GQ.Owners(kind)
    if #who == 0 then return nil end
    if kind == "share" then return string.format(L("Fait par %s : WL Helper le lui laisse."), table.concat(who, ", ")) end
    return string.format(L("Aussi fait par %s : WL Helper ne fait rien si la fenêtre est déjà réglée."), table.concat(who, ", "))
end

-- ---------------------------------------------------------------- acting a moment later
-- Every quest window event and every close bumps the serial: an action whose window was closed or
-- replaced in the meantime (another addon handled it) is dropped.
local serial = 0
local function Later(check, act)
    local mine = serial
    local function run()
        if serial ~= mine or IsShiftKeyDown() then return end
        if check and not check() then return end
        act()
    end
    if C_Timer and C_Timer.After then C_Timer.After(DELAY, run) else run() end
end
local function SameQuest(qid) return function() return Num(GetQuestID and GetQuestID()) == qid end end
local function InLog(qid)
    local CQL = C_QuestLog
    if CQL and CQL.GetLogIndexForQuestID then
        local ok, i = pcall(CQL.GetLogIndexForQuestID, qid)
        if ok and Num(i) and i > 0 then return true end
    end
    local log = root.LogEntries and root.LogEntries()
    return log and log[qid] ~= nil or false
end
local function MoneyAsked() return (Num(GetQuestMoneyToGet and GetQuestMoneyToGet()) or 0) > 0 end

-- ---------------------------------------------------------------- rewards
-- A reward judged for your spec: a percent (1000 = empty slot), false (not for you, worse or
-- equipped) or nil (not readable yet). WL Helper Gear first, else WL Helper's own weights.
function GQ.Judge(link)
    if type(link) ~= "string" then return nil end
    -- not something you wear (potion, bag, reagent): never an upgrade. The slot comes from the
    -- client's own item table, known even before the item is cached.
    local Instant = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
    if Instant then
        local ok, _, _, _, equipLoc = pcall(Instant, link)
        if ok and type(equipLoc) == "string" and (equipLoc == "" or equipLoc == "INVTYPE_NON_EQUIP_IGNORE"
            or equipLoc == "INVTYPE_NON_EQUIP" or equipLoc == "INVTYPE_BAG" or equipLoc == "INVTYPE_QUIVER") then
            return false
        end
    end
    local G = _G.WLHelperGear
    if type(G) == "table" and type(G.Compare) == "function" then
        local ok, r = pcall(G.Compare, link)
        if ok and type(r) == "table" then
            if r.canUse ~= true or r.blocked or r.unscored or r.equipped then return false end
            if r.empty then return 1000 end
            if r.unknown then return nil end
            return Num(r.pctExact) or Num(r.pct) or false
        end
    end
    local W = WP.Weights
    if WP.UpgradeSpecVerdict and W and W.CompareSpecs then
        local okS, specs = pcall(W.CompareSpecs)
        local spec = okS and type(specs) == "table" and specs[1]
        if spec then
            local ok, v = pcall(WP.UpgradeSpecVerdict, link, spec, true)
            if ok then
                if Num(v) then return v end
                -- nil: not loaded yet; WP.UPGRADE_WAIT: what you wear is not loaded yet
                if v == nil or v == WP.UPGRADE_WAIT then return nil end
                return false
            end
        end
    end
    return nil
end
-- a reward item the game has not loaded yet (no link, or no item info): asked for, true
local function NotLoaded(link)
    if type(link) ~= "string" then return true end
    local Info = (C_Item and C_Item.GetItemInfo) or GetItemInfo
    if not Info then return false end
    local ok, name = pcall(Info, link)
    if ok and Str(name) then return false end
    local id = tonumber(link:match("item:(%d+)"))
    local Req = C_Item and C_Item.RequestLoadItemDataByID
    if id and Req then pcall(Req, id) end
    return true
end
-- index, percent, name of the best upgrade among the choices; judged = false when one could not be
-- read; fifth value: one of them is not loaded by the game yet (worth asking again a moment later)
function GQ.BestChoice()
    local n = Num(GetNumQuestChoices and GetNumQuestChoices()) or 0
    local best, bestV, bestName, judged, missing = nil, 0, nil, true, false
    for i = 1, n do
        local link = GetQuestItemLink and GetQuestItemLink("choice", i)
        local v = GQ.Judge(link)
        if v == nil then
            judged = false
            if NotLoaded(link) then missing = true end
        elseif v and v > bestV then
            local name = GetQuestItemInfo and GetQuestItemInfo("choice", i)
            best, bestV, bestName = i, v, Str(name) or (Str(link) and link:match("%[(.-)%]")) or link
        end
    end
    if not judged then return nil, nil, nil, false, missing end
    return best, best and bestV or nil, bestName, true, false
end
local function RewardLine(fmtPct, fmtEmpty, name, pct)
    if pct >= 1000 then return string.format(L(fmtEmpty), name) end
    return string.format(L(fmtPct), name, math.floor(pct + 0.5))
end
-- Reward items never seen before are often not loaded yet when the window opens: asked again up to
-- 3 times, 0.3 s apart, while the same window is open (same serial, same quest, Shift not held).
local REWARD_TRIES, REWARD_GAP = 3, 0.3
local function TakeReward(qid, tries)
    tries = tries or 0
    local n = Num(GetNumQuestChoices and GetNumQuestChoices()) or 0
    if n <= 1 then GetQuestReward(n); return end
    local best, pct, name, judged, missing = GQ.BestChoice()
    -- only an item not loaded yet is worth the wait: a loaded one the gear check cannot judge
    -- will not change, its line comes at once
    if not judged and missing and tries < REWARD_TRIES and C_Timer and C_Timer.After then
        local mine = serial
        C_Timer.After(REWARD_GAP, function()
            if serial ~= mine or IsShiftKeyDown() or not SameQuest(qid)() then return end
            TakeReward(qid, tries + 1)
        end)
        return
    end
    if best and On("questAutoReward") then
        GetQuestReward(best)
        WP.Print(RewardLine("Récompense choisie : %s (+%d %%).", "Récompense choisie : %s (emplacement vide).", name, pct))
    elseif best then
        WP.Print(RewardLine("Choisis ta récompense : la meilleure pour toi est %s (+%d %%).",
            "Choisis ta récompense : la meilleure pour toi est %s (emplacement vide).", name, pct), true)
    elseif judged then
        WP.Print(L("Choisis ta récompense : aucune n'est une amélioration pour toi."), true)
    elseif missing then
        WP.Print(L("Choisis ta récompense : objets pas encore chargés par le jeu."), true)
    else
        WP.Print(L("Choisis ta récompense."), true)
    end
end

-- ---------------------------------------------------------------- sharing
local shared, fromGroup = {}, {}   -- [qid] = true: already pushed to this group / pushed to me
local queue, pumping = {}, false
local function InCombat() return (InCombatLockdown and InCombatLockdown()) or (UnitAffectingCombat and UnitAffectingCombat("player")) or false end
local function CanShare()
    return On("questAutoShare") and GuideOn() and IsInGroup and IsInGroup() and #GQ.Owners("share") == 0
end
local function Push(qid)
    if InCombat() then return nil end                -- never pushed in combat: tried again after
    local log = root.LogEntries and root.LogEntries() or {}
    local e = log[qid]
    if not e and not InLog(qid) then return nil end          -- not in the log yet: try again
    local qd = root.Q and root.Q[qid]
    if qd and qd.sh == false then return false end           -- the guide's data: cannot be shared
    local CQL = C_QuestLog
    local can
    if CQL and CQL.IsPushableQuest then
        local okP, v = pcall(CQL.IsPushableQuest, qid)
        if okP and type(v) == "boolean" then can = v end
    end
    if can == nil and root.Pushable then can = root.Pushable(qid, e) end
    if can == false then return false end
    local prev, prevQ
    if SelectQuestLogEntry and e and e.index then
        prev = GetQuestLogSelection and GetQuestLogSelection()
        SelectQuestLogEntry(e.index)
    elseif CQL and CQL.SetSelectedQuest then
        if CQL.GetSelectedQuest then local okG, v = pcall(CQL.GetSelectedQuest); prevQ = okG and Num(v) or nil end
        if not pcall(CQL.SetSelectedQuest, qid) then return false end
    else return false end
    if root.SharePushed then root.SharePushed() end   -- the blocked-action line stays quiet just after
    local ok = pcall(QuestLogPushQuest)
    -- the quest the player had selected comes back
    if type(prev) == "number" and prev > 0 then SelectQuestLogEntry(prev)
    elseif prevQ and prevQ > 0 and prevQ ~= qid then pcall(CQL.SetSelectedQuest, prevQ) end
    if ok and root.L and root.L.SHARED and root.Print then root.Print(root.L.SHARED:format((e and e.title) or (root.QName and root.QName(qid)) or qid)) end
    return ok
end
local lastPush, tries = nil, {}
local function Now() return Num(GetTime and GetTime()) or 0 end
local function Pump()
    if pumping then return end
    if #queue == 0 then return end
    -- the game blocks the share in combat: « Partage des quêtes après le combat », and
    -- PLAYER_REGEN_ENABLED pumps again
    if InCombat() then
        if CanShare() and root.ShareWaitSay then root.ShareWaitSay() end
        return
    end
    -- SHARE_GAP between any two pushes, also across separate accepts
    local wait = lastPush and (lastPush + SHARE_GAP - Now()) or 0
    if wait > 0 and C_Timer and C_Timer.After then
        pumping = true
        C_Timer.After(wait, function() pumping = false; Pump() end)
        return
    end
    pumping = true
    local qid = table.remove(queue, 1)
    if CanShare() and not shared[qid] and not fromGroup[qid] and InRoute(qid) then
        local r = Push(qid)
        if r then shared[qid] = true; lastPush = Now(); tries[qid] = nil
        elseif r == nil and (tries[qid] or 0) < 3 then
            -- the log does not have it yet: once more a little later
            tries[qid] = (tries[qid] or 0) + 1
            queue[#queue + 1] = qid
        else tries[qid] = nil end
    end
    local function nextOne() pumping = false; Pump() end
    if #queue > 0 and C_Timer and C_Timer.After then C_Timer.After(SHARE_GAP, nextOne) else pumping = false end
end
GQ.Pump = Pump
function GQ.Shared(qid) return shared[qid] == true end
-- a quest the guide's share button pushed: the auto-share does not push it again to this group
function GQ.MarkShared(qid)
    qid = Num(qid)
    if not qid then return end
    shared[qid] = true
    lastPush = Now()
    for i = #queue, 1, -1 do if queue[i] == qid then table.remove(queue, i) end end
end
local function Queue(qid)
    if not (QuestLogPushQuest and CanShare()) or shared[qid] or fromGroup[qid] or not InRoute(qid) then return end
    for _, q in ipairs(queue) do if q == qid then return end end
    queue[#queue + 1] = qid
    -- a moment after QUEST_ACCEPTED: the quest log has the quest by then
    if C_Timer and C_Timer.After then C_Timer.After(0.5, Pump) else Pump() end
end

-- ---------------------------------------------------------------- events
local function OnDetail()
    local qid = Num(GetQuestID and GetQuestID()) or 0
    if not On("questAutoAccept") or not InRoute(qid) or InLog(qid) then return end
    Later(SameQuest(qid), function() if not InLog(qid) then AcceptQuest() end end)
end
local function OnProgress()
    local qid = Num(GetQuestID and GetQuestID()) or 0
    if not On("questAutoTurnIn") or not InRoute(qid) or MoneyAsked() then return end
    if not (IsQuestCompletable and IsQuestCompletable()) then return end
    Later(SameQuest(qid), CompleteQuest)
end
local function OnComplete()
    local qid = Num(GetQuestID and GetQuestID()) or 0
    if not On("questAutoTurnIn") or not InRoute(qid) or MoneyAsked() then return end
    Later(SameQuest(qid), function() TakeReward(qid) end)
end
local function GossipHas(list, qid)
    return function()
        for _, q in ipairs((C_GossipInfo[list] and C_GossipInfo[list]()) or {}) do if q.questID == qid then return true end end
        return false
    end
end
local function OnGossip()
    local G = C_GossipInfo
    if not G then return end
    if On("questAutoTurnIn") and G.GetActiveQuests then
        for _, q in ipairs(G.GetActiveQuests() or {}) do
            if q.isComplete and InRoute(q.questID) then
                local id = q.questID
                Later(GossipHas("GetActiveQuests", id), function() G.SelectActiveQuest(id) end)
                return
            end
        end
    end
    if On("questAutoAccept") and G.GetAvailableQuests then
        for _, q in ipairs(G.GetAvailableQuests() or {}) do
            if InRoute(q.questID) then
                local id = q.questID
                Later(GossipHas("GetAvailableQuests", id), function() G.SelectAvailableQuest(id) end)
                return
            end
        end
    end
end
local function OnGreeting()
    if On("questAutoTurnIn") and GetNumActiveQuests then
        for i = 1, GetNumActiveQuests() or 0 do
            local title, complete = GetActiveTitle(i)
            local qid = Num(GetActiveQuestID and GetActiveQuestID(i)) or RouteByTitle(title)
            if complete and qid and InRoute(qid) then
                Later(function() return GetActiveTitle(i) == title end, function() SelectActiveQuest(i) end)
                return
            end
        end
    end
    if On("questAutoAccept") and GetNumAvailableQuests then
        for i = 1, GetNumAvailableQuests() or 0 do
            local title = GetAvailableTitle(i)
            local qid = GetAvailableQuestInfo and Num(select(5, GetAvailableQuestInfo(i))) or RouteByTitle(title)
            if qid and InRoute(qid) then
                Later(function() return GetAvailableTitle(i) == title end, function() SelectAvailableQuest(i) end)
                return
            end
        end
    end
end

local f = CreateFrame("Frame")
for _, e in ipairs({ "QUEST_DETAIL", "QUEST_PROGRESS", "QUEST_COMPLETE", "GOSSIP_SHOW", "QUEST_GREETING",
    "QUEST_FINISHED", "GOSSIP_CLOSED", "QUEST_ACCEPTED", "PLAYER_REGEN_ENABLED", "GROUP_ROSTER_UPDATE", "GROUP_LEFT" }) do
    pcall(f.RegisterEvent, f, e)
end
local WINDOW = { QUEST_DETAIL = true, QUEST_PROGRESS = true, QUEST_COMPLETE = true, GOSSIP_SHOW = true,
    QUEST_GREETING = true, QUEST_FINISHED = true, GOSSIP_CLOSED = true }
f:SetScript("OnEvent", function(_, event, a1, a2)
    if WINDOW[event] then serial = serial + 1 end
    if event == "QUEST_FINISHED" or event == "GOSSIP_CLOSED" then return end
    if event == "QUEST_DETAIL" then
        -- pushed by a group member: theirs to share, not mine
        local qid = Num(GetQuestID and GetQuestID())
        if qid and qid > 0 and UnitIsPlayer and UnitIsPlayer("npc") then fromGroup[qid] = true end
    end
    if event == "QUEST_ACCEPTED" then
        -- classic sends (log index, quest id), the modern client the quest id alone
        Queue(Num(a2) or Num(a1))
        return
    elseif event == "PLAYER_REGEN_ENABLED" then
        Pump(); return
    elseif event == "GROUP_ROSTER_UPDATE" or event == "GROUP_LEFT" then
        -- a new group: every quest can be shared again
        if not (IsInGroup and IsInGroup()) then shared, fromGroup, queue, tries = {}, {}, {}, {} end
        return
    end
    if not GuideOn() or not root.route then return end
    if IsShiftKeyDown() then return end   -- Shift: do it by hand
    if event == "QUEST_DETAIL" then OnDetail()
    elseif event == "QUEST_PROGRESS" then OnProgress()
    elseif event == "QUEST_COMPLETE" then OnComplete()
    elseif event == "GOSSIP_SHOW" then OnGossip()
    elseif event == "QUEST_GREETING" then OnGreeting() end
end)
GQ.frame = f
