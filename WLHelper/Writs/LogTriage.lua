-- Writs/LogTriage.lua: "Tri du journal" (quest log triage).
-- The quest log holds a fixed number of quests (20 on this client unless the game says otherwise).
-- When it is nearly full, one calm chat line offers to review it; the window lists the quests that
-- can go, each with its reason:
--   grey      far below the player's level (the game's own difficulty colour): almost no XP left
--   group     an elite or group quest at least 3 levels above the player (red): not doable alone now.
--             Dungeon quests the guide knows are never offered this way: picking them up early is
--             how the guide works.
--   dungeon   a quest of a dungeon the player has outgrown (above its top level), when a dungeon
--             selection exists and that dungeon is not in it nor on the current route
-- It never offers: the quests of the selected dungeons and their whole chains (WLDTDB.sel,
-- root.DungeonQuests, root.FullChain), the key and raid attunement chains (root.KEYS, raids,
-- a few well-known attunements), class quests (root.Q[id].c, or the log's own class header), the
-- Craftsman's Writs, quests ready to turn in, and the ones the player chose to keep.
-- Abandoning uses the game's own calls (select the quest, SetAbandonQuest, AbandonQuest), after the
-- design system's two-step confirm. If the game refuses, the quest log opens on that quest and the
-- player clicks its Abandon button.
local ADDON, root = ...
root.Writs = root.Writs or {}
local ns = root.Writs
local WP = ns.WP
local L = ns.L
local S = ns.S
local C = S.C
local F = S.F

ns.AddEnglish({
    ["Tri du journal"] = "Quest log cleanup",
    ["Trier le journal"] = "Clean up the log",
    ["%d quêtes sur %d"] = "%d of %d quests",
    -- the window
    ["Ton journal est presque plein. Tu peux abandonner ces quêtes sans rien perdre d'important."] =
        "Your quest log is nearly full. You can abandon these quests without losing anything important.",
    ["Ton journal est plein. Tu peux abandonner ces quêtes sans rien perdre d'important."] =
        "Your quest log is full. You can abandon these quests without losing anything important.",
    ["Tu peux abandonner ces quêtes sans rien perdre d'important."] =
        "You can abandon these quests without losing anything important.",
    ["Jamais proposées : les quêtes de tes donjons choisis, les clés et les accès de raid, les quêtes de classe, les Writs, celles prêtes à rendre et celles que tu gardes."] =
        "Never offered: the quests of your chosen dungeons, keys and raid attunements, class quests, Writs, quests ready to turn in and the ones you keep.",
    ["Quête niv. %d"] = "Level %d quest",
    ["Abandonner"] = "Abandon",
    ["Confirmer l'abandon"] = "Confirm abandon",
    ["Garder"] = "Keep",
    ["La quête quitte ton journal. Tu pourras la reprendre chez celui qui la donne."] =
        "The quest leaves your log. You can take it again from its quest giver.",
    ["Clic : demander confirmation, puis abandonner au deuxième clic"] = "Click: ask to confirm, then abandon on the second click",
    ["Elle ne sera plus proposée ici."] = "It will no longer be offered here.",
    ["Clic : la garder"] = "Click: keep it",
    ["Clic : ouvrir la quête dans ton journal"] = "Click: open the quest in your log",
    ["1 quête gardée n'est plus proposée."] = "1 kept quest is no longer offered.",
    ["%d quêtes gardées ne sont plus proposées."] = "%d kept quests are no longer offered.",
    ["Les proposer à nouveau"] = "Offer them again",
    ["Clic : proposer à nouveau les quêtes que tu as gardées"] = "Click: offer the quests you kept again",
    -- the reasons
    ["Grise : trop basse pour toi, elle donne très peu d'XP."] = "Grey: too low for you, it gives very little XP.",
    ["Quête de groupe (%s) : trop dure seul à ton niveau."] = "Group quest (%s): too hard alone at your level.",
    ["Quête de groupe : trop dure seul à ton niveau."] = "Group quest: too hard alone at your level.",
    ["Quête de %s : tu as dépassé ce donjon et il n'est pas dans tes donjons choisis."] =
        "A quest for %s: you have outgrown this dungeon and it is not one of your chosen dungeons.",
    -- the empty state
    ["Rien à abandonner"] = "Nothing to abandon",
    ["Toutes tes quêtes servent encore."] = "All your quests are still useful.",
    ["Ton journal a encore 1 place libre."] = "Your log still has 1 free slot.",
    ["Ton journal a encore %d places libres."] = "Your log still has %d free slots.",
    -- chat
    ["Ton journal de quêtes est presque plein (%d sur %d). Clique sur %s pour voir les quêtes à abandonner."] =
        "Your quest log is nearly full (%d of %d). Click %s to see which quests can go.",
    ["Ton journal de quêtes est plein (%d sur %d). Clique sur %s pour voir les quêtes à abandonner."] =
        "Your quest log is full (%d of %d). Click %s to see which quests can go.",
    ["Quête abandonnée : %s."] = "Quest abandoned: %s.",
    ["Le jeu ne laisse pas l'addon abandonner « %s » : elle est ouverte dans ton journal, clique sur Abandonner."] =
        "The game does not let the addon abandon \"%s\": it is open in your quest log, click Abandon.",
    ["Impossible en combat : réessaie une fois le combat fini."] = "Not possible in combat: try again once the fight is over.",
    -- for the integration (module list, options, /wlh help)
    ["Les quêtes à abandonner quand le journal est presque plein"] = "Quests to abandon when the log is nearly full",
    ["Proposer le tri du journal"] = "Offer to sort the quest log",
    ["Quand ton journal de quêtes est presque plein, une ligne dans le chat propose de voir les quêtes à abandonner."] =
        "When your quest log is nearly full, a chat line offers to show the quests you can abandon.",
    ["  /wlh tri : les quêtes à abandonner quand le journal est presque plein"] = "  /wlh triage: the quests to abandon when the log is nearly full",
})

-- ---------------------------------------------------------------- helpers

local function secret(v) return root.IsSecret and root.IsSecret(v) or (issecretvalue and issecretvalue(v)) or false end
local function num(v) return type(v) == "number" and not secret(v) and v or nil end
local function str(v) return type(v) == "string" and not secret(v) and v or nil end

local function safe(f, ...)
    if type(f) ~= "function" then return nil end
    local ok, a, b, c, d, e, g, h, i, j = pcall(f, ...)
    if ok then return a, b, c, d, e, g, h, i, j end
end

local NEAR = 2                 -- the notice comes when 2 slots or fewer are left
local FALLBACK_MAX = 20        -- the classic quest log

-- A few attunement chains the data may not list as a dungeon's quest: they are never offered
-- (Molten Core, Upper Blackrock Spire, Blackwing Lair, Onyxia and the Skeleton Key for both
-- factions). The key passport's own list (Writs/Keys.lua) is added when it is loaded.
local ATTUNE = { [7848] = true, [4743] = true, [7761] = true, [6602] = true, [6502] = true, [5511] = true, [5505] = true }

-- Tags the game puts on quests that need a group (classic tag ids: Group, Raid, Dungeon, Heroic,
-- Raid 10, Raid 25), and the tag names when only the text is given.
local GROUP_TAG = { [1] = true, [62] = true, [81] = true, [85] = true, [88] = true, [89] = true }
local GROUP_WORDS = { "elite", "élite", "group", "groupe", "dungeon", "donjon", "raid" }

local function MaxQuests()
    local CQL = C_QuestLog
    local v = num(CQL and safe(CQL.GetMaxNumQuestsCanAccept))
    if v and v >= 10 and v <= 50 then return v end
    v = num(MAX_QUESTLOG_QUESTS) or num(MAX_QUESTS)
    if v and v >= 10 and v <= 50 then return v end
    return FALLBACK_MAX
end

-- Difficulty band of a quest level for the player: the game's own colour table first, then the
-- same thresholds the game uses (grey past the green range).
local function IsGrey(ql, plvl)
    if not (ql and plvl) or ql <= 0 then return false end
    if type(GetQuestDifficultyColor) == "function" and type(QuestDifficultyColors) == "table" then
        local ok, c = pcall(GetQuestDifficultyColor, ql)
        if ok and c and QuestDifficultyColors.trivial then
            for k, v in pairs(QuestDifficultyColors) do
                if v == c then return k == "trivial" end
            end
        end
    end
    local d = plvl - ql
    if d < 3 then return false end
    local g = num(type(GetQuestGreenRange) == "function" and safe(GetQuestGreenRange))
    g = g or (plvl <= 5 and 5 or plvl < 40 and 5 + math.floor(plvl / 10) or 1 + math.floor(plvl / 5))
    return d > g
end

local function TagOf(qid, rawTag)
    -- the classic log gives the tag as a word ("Elite", "Dungeon"); newer clients a group size
    local name = str(rawTag)
    local group = name and name ~= "" or (num(rawTag) or 0) > 1
    local CQL = C_QuestLog
    local info = CQL and safe(CQL.GetQuestTagInfo, qid)
    local tagID, tagName
    if type(info) == "table" then tagID, tagName = num(info.tagID), str(info.tagName)
    else tagID, tagName = safe(GetQuestTagInfo, qid); tagID, tagName = num(tagID), str(tagName) end
    if tagID and GROUP_TAG[tagID] then group = true end
    name = (tagName and tagName ~= "") and tagName or name
    if name and not group then
        local low = name:lower()
        for _, w in ipairs(GROUP_WORDS) do if low:find(w, 1, true) then group = true end end
    end
    return group and true or false, (name and name ~= "") and name or nil
end

-- The quest log, read once: each quest with its log index, level, zone (the header above it),
-- group tag and state. Collapsed zones hide their quests from the game's list; the count still
-- comes from the game's own total.
local function ReadLog()
    local list, count = {}, nil
    local n, nq
    local CQL = C_QuestLog
    if type(GetNumQuestLogEntries) == "function" then n, nq = safe(GetNumQuestLogEntries)
    elseif CQL then n, nq = safe(CQL.GetNumQuestLogEntries) end
    n, count = num(n) or 0, num(nq)
    local zone
    local legacy = type(GetQuestLogTitle) == "function"
    for i = 1, n do
        local title, level, tag, header, complete, qid
        if legacy then
            local t, lv, tg, isHeader, _, isComplete, _, id = safe(GetQuestLogTitle, i)
            title, level, tag, header, complete, qid = t, lv, tg, isHeader, isComplete, id
        elseif CQL then
            local info = safe(CQL.GetInfo, i)
            if type(info) == "table" then
                title, level, tag, header, qid = info.title, info.level, info.suggestedGroup, info.isHeader, info.questID
                complete = num(qid) and safe(CQL.IsComplete, qid)
            end
        end
        title = str(title)
        local isHeader = not secret(header) and (header == true or header == 1)
        if isHeader then
            zone = title or zone
        elseif not secret(header) then
            qid = num(qid)
            if qid and qid > 0 then
                local group, tagName = TagOf(qid, tag)
                list[#list + 1] = {
                    qid = qid, index = i, title = title or (root.QName and root.QName(qid)) or tostring(qid),
                    level = num(level), zone = zone, group = group, tag = tagName,
                    complete = (complete == 1 or complete == true),
                }
            end
        end
    end
    return list, count or #list
end

local function InLog(qid)
    local CQL = C_QuestLog
    if CQL and type(CQL.GetLogIndexForQuestID) == "function" then
        local i = num(safe(CQL.GetLogIndexForQuestID, qid))
        return i ~= nil and i > 0
    end
    for _, e in ipairs((ReadLog())) do if e.qid == qid then return true end end
    return false
end

-- ---------------------------------------------------------------- what is protected

local function KeepDB()
    if type(WLWritsCharDB) ~= "table" then return {} end
    WLWritsCharDB.triageKeep = WLWritsCharDB.triageKeep or {}
    return WLWritsCharDB.triageKeep
end

local function AddChain(set, qid, cls, why)
    if not qid then return end
    set[qid] = set[qid] or why
    if root.FullChain then
        local ok, chain = pcall(root.FullChain, qid, cls)
        if ok and type(chain) == "table" then for _, p in ipairs(chain) do set[p] = set[p] or why end end
    end
end

-- Every quest that must never be offered, with why: "dungeon", "route", "key", "writ".
local function ProtectedSet()
    local set = {}
    local _, cls = UnitClass("player")
    local Q, D = root.Q or {}, root.D or {}
    local sel = type(WLDTDB) == "table" and type(WLDTDB.sel) == "table" and WLDTDB.sel or {}
    -- the selected dungeons: their quests and every step before them
    for k, on in pairs(sel) do
        if on and D[k] then
            local ok, qs = pcall(root.DungeonQuests or function() return {} end, k, cls)
            for _, qid in ipairs(ok and qs or {}) do AddChain(set, qid, cls, "dungeon") end
            for _, qid in ipairs(D[k].q or {}) do AddChain(set, qid, cls, "dungeon") end
        end
    end
    -- the current route (it can hold quests picked one by one)
    local route = root.route
    for _, st in ipairs(route and route.steps or {}) do
        if num(st.q) then set[st.q] = set[st.q] or "route" end
        for _, a in ipairs(st.acts or {}) do if num(a.q) then set[a.q] = set[a.q] or "route" end end
    end
    -- keys and raid attunements
    for _, list in pairs(root.KEYS or {}) do
        for _, k in ipairs(list) do if k.quest then AddChain(set, k.quest, cls, "key") end end
    end
    for _, d in pairs(D) do
        if type(d) == "table" and d.raid then for _, qid in ipairs(d.q or {}) do AddChain(set, qid, cls, "key") end end
    end
    for qid in pairs(ATTUNE) do AddChain(set, qid, cls, "key") end
    -- the key passport: both factions' chains, including the steps the guide's data lacks
    for _, k in ipairs(WP.Keys and WP.Keys.LIST or {}) do
        if k.quest then AddChain(set, k.quest, cls, "key") end
        if k.aq then AddChain(set, k.aq, cls, "key") end
        for _, qid in ipairs(k.ac or {}) do set[qid] = set[qid] or "key" end
    end
    -- the Craftsman's Writs
    for _, w in ipairs(ns.WRITS or {}) do if w.quest then set[w.quest] = set[w.quest] or "writ" end end
    return set, sel
end

-- The set walks every key, raid and selected dungeon chain: it is kept until the log gains or loses
-- a quest, the level changes, or the selection or the route changes (read from their signature).
local setCache, setSig
local function Signature()
    local sel = type(WLDTDB) == "table" and type(WLDTDB.sel) == "table" and WLDTDB.sel or {}
    local keys = {}
    for k, on in pairs(sel) do if on then keys[#keys + 1] = tostring(k) end end
    table.sort(keys)
    return table.concat(keys, ",") .. "|" .. tostring(root.route) .. "|" .. tostring(WP.Keys ~= nil)
end
local function Protected()
    local sig = Signature()
    if not setCache or sig ~= setSig then
        local set, sel = ProtectedSet()
        setCache, setSig = { set, sel }, sig
    end
    return setCache[1], setCache[2]
end
local function ForgetProtected() setCache = nil end

-- A quest title that names a key or an attunement is kept even when the data does not know it.
local function KeyTitle(title)
    local low = (title or ""):lower()
    if low:find("%f[%a]key%f[%A]") or low:find("%f[%a]keys%f[%A]") then return true end
    for _, w in ipairs({ "clé", "attunement", "harmonisation" }) do
        if low:find(w, 1, true) then return true end
    end
    return false
end

-- The classic log files class quests under a header named after the class.
local function ClassHeader(zone)
    if not zone then return false end
    local loc, tok = UnitClass("player")
    if str(loc) == zone then return true end
    for _, t in ipairs({ LOCALIZED_CLASS_NAMES_MALE, LOCALIZED_CLASS_NAMES_FEMALE }) do
        if type(t) == "table" and tok and t[tok] == zone then return true end
    end
    return false
end

local function DungeonOf(q)
    if not q then return nil end
    if type(q.ds) == "table" and q.ds[1] then return q.ds end
    if q.d then return { q.d } end
end

-- The player is above the top level of every dungeon the quest is for (an unknown range never counts).
local function Outgrown(ds, plvl)
    if not (ds and ds[1] and plvl) then return false end
    for _, k in ipairs(ds) do
        local d = root.D and root.D[k]
        local top = d and type(d.lvl) == "table" and num(d.lvl[2])
        if not top or plvl <= top then return false end
    end
    return true
end

-- Why a quest of the log is protected (a word), or nil.
local function Protection(e, set)
    if e.complete then return "complete" end
    if KeepDB()[e.qid] then return "kept" end
    local q = root.Q and root.Q[e.qid]
    if q and q.c then return "class" end
    if ClassHeader(e.zone) then return "class" end
    if set[e.qid] then return set[e.qid] end
    if KeyTitle(e.title) or (q and KeyTitle(q.n)) then return "key" end
    return nil
end

-- ---------------------------------------------------------------- suggestions

local ORDER = { grey = 1, group = 2, dungeon = 3 }

local function Suggest()
    local log, count = ReadLog()
    local plvl = num(UnitLevel("player"))
    local set, sel = Protected()
    -- a real dungeon selection: the one-quest cards (class quests, keys) are not one
    local anySel = false
    for k, on in pairs(sel) do if on and root.D and root.D[k] and not root.D[k].cq then anySel = true end end
    local out = {}
    -- forget kept quests that left the log (abandoned or turned in): the table stays small. Quests
    -- under a collapsed zone are missing from the list, so the game is asked by quest when it can;
    -- otherwise the list is trusted only when it holds the whole log.
    local keep, here = KeepDB(), {}
    for _, e in ipairs(log) do here[e.qid] = true end
    local CQL = C_QuestLog
    local byId = CQL and type(CQL.GetLogIndexForQuestID) == "function"
    if #log > 0 and (byId or #log >= count) then
        for qid in pairs(keep) do
            if not here[qid] and not (byId and InLog(qid)) then keep[qid] = nil end
        end
    end
    for _, e in ipairs(log) do
        if not Protection(e, set) then
            local q = root.Q and root.Q[e.qid]
            local ql = e.level or (q and num(q.l))
            local s
            if plvl and ql and IsGrey(ql, plvl) then
                -- the level is on the row's meta line ("Quête niv. 20 · Zone"): the reason says why only
                s = { kind = "grey", reason = L("Grise : trop basse pour toi, elle donne très peu d'XP.") }
            elseif plvl and ql and e.group and not (q and q.d) and ql >= plvl + 3 then
                s = { kind = "group", reason = e.tag
                    and string.format(L("Quête de groupe (%s) : trop dure seul à ton niveau."), e.tag)
                    or L("Quête de groupe : trop dure seul à ton niveau.") }
            elseif anySel and q then
                local ds = DungeonOf(q)
                local inSel = false
                for _, k in ipairs(ds or {}) do if sel[k] then inSel = true end end
                if ds and not inSel and Outgrown(ds, plvl) then
                    local dname = root.DName and root.DName(ds[1]) or ds[1]
                    s = { kind = "dungeon", reason = string.format(L("Quête de %s : tu as dépassé ce donjon et il n'est pas dans tes donjons choisis."), dname) }
                end
            end
            if s then
                s.qid, s.index, s.title, s.level, s.zone = e.qid, e.index, e.title, ql, e.zone or (q and DungeonOf(q) and root.DName and root.DName(DungeonOf(q)[1]))
                out[#out + 1] = s
            end
        end
    end
    table.sort(out, function(a, b)
        if ORDER[a.kind] ~= ORDER[b.kind] then return ORDER[a.kind] < ORDER[b.kind] end
        if (a.level or 0) ~= (b.level or 0) then return (a.level or 0) < (b.level or 0) end
        return a.qid < b.qid
    end)
    return out, count
end

-- ---------------------------------------------------------------- abandoning

local function SelectedQuestID()
    local CQL = C_QuestLog
    if CQL and type(CQL.GetSelectedQuest) == "function" then return num(safe(CQL.GetSelectedQuest)) end
    local i = num(safe(GetQuestLogSelection))
    if i and i > 0 and type(GetQuestLogTitle) == "function" then return num(select(8, safe(GetQuestLogTitle, i))) end
end

local function IndexOf(qid)
    local CQL = C_QuestLog
    if CQL and type(CQL.GetLogIndexForQuestID) == "function" then
        local i = num(safe(CQL.GetLogIndexForQuestID, qid))
        if i then return i end
    end
    for _, e in ipairs((ReadLog())) do if e.qid == qid then return e.index end end
end

local function SelectQuest(qid)
    local CQL = C_QuestLog
    if CQL and type(CQL.SetSelectedQuest) == "function" then
        return pcall(CQL.SetSelectedQuest, qid)
    end
    local i = IndexOf(qid)
    if i and type(SelectQuestLogEntry) == "function" then return pcall(SelectQuestLogEntry, i) end
    return false
end

-- Opens the game's quest log on that quest (the player then clicks its Abandon button).
local function OpenLogOn(qid)
    if type(QuestMapFrame_OpenToQuestDetails) == "function" then
        if pcall(QuestMapFrame_OpenToQuestDetails, qid) then return true end
    end
    local i = IndexOf(qid)
    if QuestLogFrame and not (QuestLogFrame.IsShown and QuestLogFrame:IsShown()) then
        if type(ShowUIPanel) == "function" then pcall(ShowUIPanel, QuestLogFrame)
        elseif type(ToggleQuestLog) == "function" then pcall(ToggleQuestLog) end
    elseif not QuestLogFrame and type(ToggleQuestLog) == "function" then
        pcall(ToggleQuestLog)
    end
    if i then
        if type(QuestLog_SetSelection) == "function" then pcall(QuestLog_SetSelection, i)
        else SelectQuest(qid) end
        if type(QuestLog_Update) == "function" then pcall(QuestLog_Update) end
    end
    return true
end

local Refresh   -- the window's render, set below

-- The game's own abandon flow on one quest; checked half a second later: if the quest is still in
-- the log the game refused, so the log opens on it for the player's own click.
local function Abandon(qid, title)
    if InCombatLockdown and InCombatLockdown() then
        WP.Print(L("Impossible en combat : réessaie une fois le combat fini."), true)
        return false
    end
    local CQL = C_QuestLog
    local before = SelectedQuestID()
    local ok = SelectQuest(qid)
    if ok then
        if CQL and type(CQL.SetAbandonQuest) == "function" and type(CQL.AbandonQuest) == "function" then
            ok = pcall(CQL.SetAbandonQuest) and pcall(CQL.AbandonQuest)
        elseif type(SetAbandonQuest) == "function" and type(AbandonQuest) == "function" then
            ok = pcall(SetAbandonQuest) and pcall(AbandonQuest)
        else
            ok = false
        end
    end
    -- the player's own selection in the log comes back (by quest, the indexes moved)
    if before and before ~= qid then SelectQuest(before) end
    local name = title or (root.QName and root.QName(qid)) or tostring(qid)
    C_Timer.After(0.6, function()
        if ok and not InLog(qid) then
            WP.Print(string.format(L("Quête abandonnée : %s."), name))
        else
            OpenLogOn(qid)
            WP.Print(string.format(L("Le jeu ne laisse pas l'addon abandonner « %s » : elle est ouverte dans ton journal, clique sur Abandonner."), name))
        end
        if Refresh then Refresh() end
    end)
    return ok
end

local function SetKept(qid, on)
    KeepDB()[qid] = on and true or nil
    if Refresh then Refresh() end
end

-- ---------------------------------------------------------------- the window

local INSET = 16
local LIST_W = 614 - 2 * INSET   -- the list width, read again by Dims() at every layout
local win
-- The width from the window (a panel, DESIGN 3.1: 576 to 860 from the screen, the player can drag
-- it); not sized yet: the rule's default.
local function WinW()
    local w = win and win:GetWidth()
    if type(w) ~= "number" or (root.IsSecret and root.IsSecret(w)) or w < 300 then
        w = (root.WinSize and root.WinSize("panel")) or 614
    end
    return math.floor(w)
end
local function Dims() LIST_W = WinW() - 2 * INSET; return LIST_W end
local rows = {}
local current, currentCount = {}, 0

local function KeptCount()
    local n = 0
    for _ in pairs(KeepDB()) do n = n + 1 end
    return n
end

-- One row: the quest name in its difficulty colour, "Quête niv. 24 · Zone" (meta, muted), the reason
-- (meta, text colour), and on the right Garder then Abandonner (danger, two-step).
local function MakeRow(parent)
    local row = CreateFrame("Button", nil, parent)
    row.wlOwned = true
    row:SetHeight(52)
    row.bg = S.Solid(row, "BACKGROUND", C.cardFill); row.bg:SetAllPoints()
    row.hl = S.Solid(row, "BORDER", C.hoverFill); row.hl:SetAllPoints(); row.hl:SetAlpha(0)
    row.press = S.Solid(row, "BORDER", C.pressFill); row.press:SetAllPoints(); row.press:Hide()
    row.name = S.Text(row, F.label, C.fg)
    row.name:SetJustifyH("LEFT"); row.name:SetJustifyV("TOP")
    row.meta = S.Text(row, F.meta, C.muted)
    row.meta:SetJustifyH("LEFT"); row.meta:SetJustifyV("TOP")
    row.reason = S.Text(row, F.meta, C.text)
    row.reason:SetJustifyH("LEFT"); row.reason:SetJustifyV("TOP")

    row.abandon = S.Button(row, L("Abandonner"), 0, 24, "danger", function()
        local e = row.entry
        if e then Abandon(e.qid, e.title) end
    end, function()
        return { L("Abandonner"), L("La quête quitte ton journal. Tu pourras la reprendre chez celui qui la donne."),
            L("Clic : demander confirmation, puis abandonner au deuxième clic") }
    end)
    row.abandon:SetIcon("trash")
    row.abandon:SetConfirm(L("Confirmer l'abandon"))
    -- as wide as its confirmation label, so arming it never pushes "Garder" over the text
    row.abandon:SetText(L("Confirmer l'abandon"))
    local armedW = num(row.abandon:GetWidth())
    row.abandon:SetText(L("Abandonner"))
    if armedW then row.abandon:SetWidth(armedW) end
    row.keep = S.Button(row, L("Garder"), 0, 24, "secondary", function()
        local e = row.entry
        if e then SetKept(e.qid, true) end
    end, function() return { L("Garder"), L("Elle ne sera plus proposée ici."), L("Clic : la garder") } end)

    row:SetScript("OnEnter", function(self)
        root.Tween(self, self.hov or 0, 1, 0.10, function(v) self.hov = v; self.hl:SetAlpha(v) end)
        local e = self.entry
        if e then
            local meta = self.meta:IsShown() and self.meta:GetText() or nil
            local t = { e.title or "?" }
            if type(meta) == "string" and meta ~= "" then t[#t + 1] = meta end
            t[#t + 1] = e.reason
            t[#t + 1] = L("Clic : ouvrir la quête dans ton journal")
            S.Tip(self, t)
        end
    end)
    row:SetScript("OnLeave", function(self)
        root.Tween(self, self.hov or 0, 0, 0.10, function(v) self.hov = v; self.hl:SetAlpha(v) end)
        S.HideTip()
    end)
    row:SetScript("OnMouseDown", function(self) self.press:Show() end)
    row:SetScript("OnMouseUp", function(self) self.press:Hide() end)
    row:SetScript("OnClick", function(self) if self.entry then OpenLogOn(self.entry.qid) end end)
    return row
end

local function Paint(row, e)
    row.entry = e
    row.abandon:Disarm()
    row.name:SetText(e.title or "?")
    local c = e.level and S.LevelColor(e.level) or C.fg
    row.name:SetTextColor(c[1], c[2], c[3])
    local parts = {}
    if e.level then parts[#parts + 1] = string.format(L("Quête niv. %d"), e.level) end
    if e.zone and e.zone ~= "" then parts[#parts + 1] = e.zone end
    row.meta:SetText(table.concat(parts, " · "))
    row.meta:SetShown(#parts > 0)
    row.reason:SetText(e.reason or "")
end

-- Measured row: the texts wrap left of the two buttons; the row grows with them.
local function FitRow(row)
    local bw = (num(row.abandon:GetWidth()) or 120) + 8 + (num(row.keep:GetWidth()) or 72)
    local textW = LIST_W - 12 - bw - 12 - 12
    row.name:ClearAllPoints(); row.name:SetPoint("TOPLEFT", 12, -8)
    local h = 8 + math.max(S.FitText(row.name, 2, textW, row), F.label + 2)
    local anchor = row.name
    if row.meta:IsShown() then
        row.meta:ClearAllPoints(); row.meta:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -3)
        h = h + 3 + math.max(S.FitText(row.meta, 2, textW, row), F.meta + 2)
        anchor = row.meta
    end
    row.reason:ClearAllPoints(); row.reason:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -3)
    h = h + 3 + math.max(S.FitText(row.reason, 2, textW, row), F.meta + 2) + 8
    h = math.max(52, math.ceil(h))
    row:SetHeight(h)
    row.abandon:ClearAllPoints(); row.abandon:SetPoint("RIGHT", row, "RIGHT", -12, 0)
    row.keep:ClearAllPoints(); row.keep:SetPoint("RIGHT", row.abandon, "LEFT", -8, 0)
    return h
end

Refresh = function()
    if not (win and win:IsShown()) then return end
    current, currentCount = Suggest()
    local max = MaxQuests()
    win.subtitle:SetText(string.format(L("%d quêtes sur %d"), currentCount, max))
    local free = max - currentCount
    local intro
    -- the count is the subtitle ("18 quêtes sur 20"): the intro says what it means and what the list is
    if free <= 0 then intro = L("Ton journal est plein. Tu peux abandonner ces quêtes sans rien perdre d'important.")
    elseif free <= NEAR then intro = L("Ton journal est presque plein. Tu peux abandonner ces quêtes sans rien perdre d'important.")
    else intro = L("Tu peux abandonner ces quêtes sans rien perdre d'important.") end
    win.intro:SetText(intro)

    local child = win.list.child
    for i, e in ipairs(current) do
        local row = rows[i]
        if not row then row = MakeRow(child); rows[i] = row end
        Paint(row, e)
        row:Show()
    end
    for i = #current + 1, #rows do rows[i]:Hide(); rows[i].entry = nil end
    win.PlaceRows()

    local kept = KeptCount()
    if kept > 0 then
        win.kept:SetText(kept == 1 and L("1 quête gardée n'est plus proposée.") or string.format(L("%d quêtes gardées ne sont plus proposées."), kept))
    end
    win.kept:SetShown(kept > 0); win.unkeep:SetShown(kept > 0)

    if #current == 0 then
        local sub
        if free > NEAR then
            sub = free == 1 and L("Ton journal a encore 1 place libre.") or string.format(L("Ton journal a encore %d places libres."), free)
        else
            sub = L("Toutes tes quêtes servent encore.")
        end
        win.empty:Set("check", L("Rien à abandonner"), sub)
    end
    win.Fit()
end

local function Build()
    win = S.Window("WLHelperTriage", (root.WinSize("panel")) or 614, 300, L("Tri du journal"), "", WLWritsDB, "triagePos",
        { header = S.HEADER_H, minH = 200, size = "panel" })
    local top = win:ContentTop() + 12
    win.intro = S.Text(win, F.body, C.text)
    win.intro:SetPoint("TOPLEFT", INSET, -top)
    win.intro:SetJustifyH("LEFT"); win.intro:SetJustifyV("TOP"); win.intro:SetWordWrap(true)
    win.list = S.ScrollArea(win)
    win.note = S.Text(win, F.meta, C.muted)
    win.note:SetJustifyH("LEFT"); win.note:SetJustifyV("TOP"); win.note:SetWordWrap(true)
    win.note:SetText(L("Jamais proposées : les quêtes de tes donjons choisis, les clés et les accès de raid, les quêtes de classe, les Writs, celles prêtes à rendre et celles que tu gardes."))
    win.kept = S.Text(win, F.meta, C.muted)
    win.kept:SetJustifyH("LEFT"); win.kept:SetJustifyV("MIDDLE")
    win.unkeep = S.Button(win, L("Les proposer à nouveau"), 0, 24, "ghost", function()
        if type(WLWritsCharDB) == "table" then WLWritsCharDB.triageKeep = {} end
        Refresh()
    end, { L("Les proposer à nouveau"), L("Clic : proposer à nouveau les quêtes que tu as gardées") })
    win.empty = S.EmptyState(win, "check", L("Rien à abandonner"), L("Toutes tes quêtes servent encore."))
    win.empty:ClearAllPoints(); win.empty:SetPoint("TOP", win, "TOP", 0, -(top + 12))
    win.empty:Hide()

    -- The rows of the list at the window's width (layout only: a resize calls it with the same rows).
    function win.PlaceRows()
        Dims()
        local y = 0
        for i = 1, #current do
            local row = rows[i]
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", 0, -y); row:SetPoint("TOPRIGHT", 0, -y)
            row:SetWidth(LIST_W)
            y = y + FitRow(row) + 2
        end
        win.listH = math.max(0, y - 2)
    end
    win.OnResize = function() win.PlaceRows(); win.Fit() end

    -- Sizes the window: the intro, the list (scrolls only past 80 % of the screen), then the note
    -- and the kept line, which stick to the bottom.
    function win.Fit()
        local empty = #current == 0
        local keptH = win.kept:IsShown() and 24 or 0
        local noteH = math.ceil(S.FitText(win.note, 0, LIST_W, win))
        if empty then
            win.intro:Hide(); win.list:Hide(); win.note:Hide(); win.empty:Show()
            local h = win.empty:Fit() + 12
            win.kept:ClearAllPoints(); win.kept:SetPoint("TOPLEFT", INSET, -(top + h))
            win.unkeep:ClearAllPoints(); win.unkeep:SetPoint("RIGHT", win, "TOPRIGHT", -INSET, -(top + h + 12))
            win:FitHeight(h + keptH)
            return
        end
        win.empty:Hide(); win.intro:Show(); win.list:Show(); win.note:Show()
        local introH = math.max(math.ceil(S.FitText(win.intro, 0, LIST_W, win)), F.body + 2)
        local bottomH = noteH + (keptH > 0 and (8 + keptH) or 0)
        win:FitHeight(introH + 12 + (win.listH or 0) + 12 + bottomH)
        -- bottom up: the kept line, then the note, then the list takes what is left
        local b = 12
        if keptH > 0 then
            win.unkeep:ClearAllPoints(); win.unkeep:SetPoint("BOTTOMRIGHT", -INSET, b)
            win.kept:ClearAllPoints()
            win.kept:SetPoint("BOTTOMLEFT", INSET, b); win.kept:SetPoint("RIGHT", win.unkeep, "LEFT", -12, 0)
            win.kept:SetHeight(24)
            b = b + keptH + 8
        end
        win.note:ClearAllPoints(); win.note:SetPoint("BOTTOMLEFT", INSET, b); win.note:SetWidth(LIST_W)
        b = b + noteH + 12
        win.list:ClearAllPoints()
        win.list:SetPoint("TOPLEFT", INSET, -(top + introH + 12))
        win.list:SetPoint("BOTTOMRIGHT", -INSET, b)
        win.list.child:SetWidth(LIST_W)
        win.list:SetContentHeight(win.listH or 0)
    end

    win:SetScript("OnShow", function()
        win.list:ScrollTo(0, true)
        Refresh()
        -- wrapped text measures right once its width is applied
        C_Timer.After(0, function() if win:IsShown() then win.Fit() end end)
    end)
end

-- ---------------------------------------------------------------- the notice

-- One chat line with a link, when the log comes within NEAR slots of full (once per crossing), or
-- when the game refuses a quest because the log is full (at most every 5 minutes). Only when there
-- is something to offer; never in combat (it waits for the end of the fight).
local TRIAGE_LINK = "addon:wlhelpertriage"
local loginAt = GetTime and GetTime() or 0
local noticed, lastFull, waiting = false, -1000, false

local function NoticeOn()
    return WP.ModuleOn("triage") and not (WLWritsDB and WLWritsDB.triageNotice == false)
end

local function Notice(force)
    if not NoticeOn() or (win and win:IsShown()) then return end
    if InCombatLockdown and InCombatLockdown() then waiting = (force or waiting == "force") and "force" or true; return end
    -- the count alone first (this runs after every objective kill): the suggestion pass only near full
    local max = MaxQuests()
    local _, count = ReadLog()
    if max - count > NEAR then noticed = false; return end
    if noticed and not force then return end
    if GetTime() - loginAt < 10 and not force then return end
    local list
    list, count = Suggest()
    local free = max - count
    if #list == 0 then return end
    noticed = true
    local link = S.Hex(C.accentSoft) .. "|H" .. TRIAGE_LINK .. "|h[" .. L("Trier le journal") .. "]|h|r"
    local fmt = free <= 0 and L("Ton journal de quêtes est plein (%d sur %d). Clique sur %s pour voir les quêtes à abandonner.")
        or L("Ton journal de quêtes est presque plein (%d sur %d). Clique sur %s pour voir les quêtes à abandonner.")
    WP.Print(string.format(fmt, count, max, link), true)
end

-- The modern client sends "addon:" links to EventRegistry's "SetItemRef" callback; the hook on
-- SetItemRef covers clients that do not. Show twice in a row only refreshes the window.
local function OnLink(link)
    if type(link) ~= "string" or secret(link) then return end
    if link == TRIAGE_LINK and WP.Triage then WP.Triage.Show() end
end
if type(EventRegistry) == "table" and type(EventRegistry.RegisterCallback) == "function" then
    pcall(EventRegistry.RegisterCallback, EventRegistry, "SetItemRef", function(_, link) OnLink(link) end, "WLHelperTriage")
end
if SetItemRef then
    hooksecurefunc("SetItemRef", function(link) OnLink(link) end)
end

local pending = false
local ev = CreateFrame("Frame")
for _, e in ipairs({ "QUEST_ACCEPTED", "QUEST_REMOVED", "QUEST_TURNED_IN", "QUEST_LOG_UPDATE", "PLAYER_LEVEL_UP",
    "UI_ERROR_MESSAGE", "PLAYER_REGEN_ENABLED" }) do
    pcall(ev.RegisterEvent, ev, e)
end
ev:SetScript("OnEvent", function(_, e, a1, a2)
    if not WLWritsDB or not WP.ModuleOn("triage") then return end
    if e == "UI_ERROR_MESSAGE" then
        local full = ERR_QUEST_LOG_FULL
        if not full or secret(a1) or secret(a2) then return end
        if (a2 == full or a1 == full) and GetTime() - lastFull > 300 then
            lastFull = GetTime()
            Notice(true)
        end
        return
    end
    if e == "PLAYER_REGEN_ENABLED" then
        if waiting then local force = waiting == "force"; waiting = false; Notice(force) end
        return
    end
    if e == "QUEST_ACCEPTED" or e == "QUEST_REMOVED" or e == "QUEST_TURNED_IN" or e == "PLAYER_LEVEL_UP" then ForgetProtected() end
    if pending then return end
    pending = true
    -- the log fires many updates in a row: one read half a second later
    C_Timer.After(0.5, function()
        pending = false
        if win and win:IsShown() then Refresh() end
        if e == "QUEST_ACCEPTED" or e == "QUEST_LOG_UPDATE" then Notice(false) end
    end)
end)

-- ---------------------------------------------------------------- API

WP.Triage = {
    -- The quests the window offers to abandon: { qid, index, title, level, zone, kind, reason },
    -- grey first, then group quests, then quests of dungeons not selected.
    Suggestions = function() return (Suggest()) end,
    -- quests in the log, and how many it can hold
    LogCount = function() local _, n = ReadLog(); return n, MaxQuests() end,
    Count = function() if not WP.ModuleOn("triage") then return 0 end; return #(Suggest()) end,
    Show = function()
        if WP.ModuleOff("triage") then return end
        if not win then Build() end
        if win:IsShown() then Refresh() else win:Show() end
    end,
    Toggle = function()
        if win and win:IsShown() then win:Hide(); return end
        WP.Triage.Show()
    end,
    Hide = function() if win then win:Hide() end end,
    Keep = SetKept,
    IsKept = function(qid) return KeepDB()[qid] and true or false end,
    Abandon = Abandon,
    OpenLog = OpenLogOn,
    MaxQuests = MaxQuests,
    Notice = Notice,
}
