-- Writs/Cleaner.lua: the bag cleaner. Finds quest items in your bags that no quest in your log needs
-- any more (quest turned in or abandoned) and lets you destroy them after a click on its confirm
-- button. It never offers an item that starts a quest, an item an active quest asks for, the
-- Craftsman's Writ envelopes and Coin Pouches, nor anything that is not a quest item. Items that
-- LibForeverData says a quest you have not done yet still needs are listed in amber, unchecked.
-- Rare or better items are only listed: the game would ask for a typed confirmation.
local ADDON, root = ...
-- The Writs module of WL Helper keeps its own table inside the addon's namespace.
root.Writs = root.Writs or {}
local ns = root.Writs
local WP = ns.WP
local L = ns.L

ns.AddEnglish({
    -- reasons under the "À détruire toi-même" header: they say why, not the header again
    ["Objet rare : le jeu demande une confirmation écrite"] = "Rare item: the game asks for a typed confirmation",
    ["Une quête de ton journal est inconnue : elle en a peut-être besoin"] = "A quest in your log is unknown: it may still need it",
    ["Aucune quête rendue ne l'utilise : détruis-le seulement si tu es sûr"] = "No turned-in quest uses it: destroy it only if you are sure",
    ["Ces objets ne servent plus, mais le jeu les fait détruire à la main, depuis tes sacs."] =
        "These items are no longer needed, but the game has you destroy them by hand, from your bags.",
    ["Sacs"] = "Bags",
    ["Objets de quête qui ne servent plus"] = "Quest items you no longer need",
    ["Aucune quête de ton journal n'a besoin de ces objets. Coche ceux à détruire : le jeu en détruit un par clic."] =
        "No quest in your log needs these items. Tick the ones to destroy: the game destroys one per click.",
    ["Tes sacs sont propres"] = "Your bags are clean",
    ["Les objets de quête qui ne servent plus apparaîtront ici."] = "Quest items you no longer need will show up here.",
    ["Quête rendue : %s"] = "Quest turned in: %s",
    ["Peut servir à une quête suivante"] = "May be needed for a later quest",
    ["Sans risque"] = "Safe",
    ["À vérifier"] = "Check first",
    ["À détruire toi-même"] = "Destroy by hand",
    ["Quête déjà rendue"] = "Quest already turned in",
    ["Détruire"] = "Destroy",
    ["Détruire l'objet coché"] = "Destroy the ticked item",
    ["Détruire le suivant (%d cochés)"] = "Destroy the next one (%d ticked)",
    ["Coche au moins un objet."] = "Tick at least one item.",
    ["Ces objets se détruisent à la main, depuis tes sacs."] = "These items are destroyed by hand, from your bags.",
    ["Le jeu détruit un objet par clic : %s d'abord."] = "The game destroys one item per click: %s first.",
    ["Clic : le prendre sur le curseur, puis confirmer dans le décor"] = "Click: put it on the cursor, then confirm in the world",
    ["Clic : le cocher"] = "Click: tick it",
    ["Clic : le décocher"] = "Click: untick it",
    ["À détruire toi-même, depuis tes sacs."] = "Destroy it yourself, from your bags.",
    ["%s est sur ton curseur. Clique dans le décor, hors des fenêtres, puis confirme."] = "%s is on your cursor. Click in the world, outside any window, then confirm.",
    ["%s est sur ton curseur : clique dans le décor (hors des fenêtres), puis confirme pour le détruire."] =
        "%s is on your cursor: click in the world (outside any window), then confirm to destroy it.",
    ["Nettoyer"] = "Clean up",
    ["1 objet de quête ne sert plus et prend une place dans tes sacs. Clique sur %s pour le voir."] =
        "1 quest item is no longer needed and takes a slot in your bags. Click %s to see it.",
    ["%d objets de quête ne servent plus et prennent de la place dans tes sacs. Clique sur %s pour les voir."] =
        "%d quest items are no longer needed and take room in your bags. Click %s to see them.",
    ["À garder : invoque Gahz'rilla au gong de Zul'Farrak (quête « Gahz'rilla »)"] =
        "Keep it: summons Gahz'rilla at the gong in Zul'Farrak (quest \"Gahz'rilla\")",
    ["À garder : se change en Mallet of Zul'Farrak à l'autel de Hakkar"] =
        "Keep it: becomes the Mallet of Zul'Farrak at the altar of Hakkar",
    ["Objet utilisable : lis son infobulle avant de le jeter"] = "Usable item: read its tooltip before throwing it away",
    ["La liste a changé : vérifie-la et clique encore."] = "The list changed: check it and click again.",
})

local S = ns.S
local C = S.C

local QUEST_CLASS = 12               -- Enum.ItemClass.Questitem
local MANUAL_QUALITY = 3             -- rare and up: the game asks to type DELETE
local COIN_POUCHES = { 284583, 284584, 284585, 284586 }

local function safe(f, ...)
    if not f then return nil end
    local ok, a, b, c, d, e, g, h, i = pcall(f, ...)
    if ok then return a, b, c, d, e, g, h, i end
end

local function Lib()
    local lib = _G.LibForeverData
    if type(lib) ~= "table" and LibStub then lib = LibStub("LibForeverData", true) end
    return type(lib) == "table" and lib.Get and lib or nil
end

local function Completed(questID)
    if C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted then return safe(C_QuestLog.IsQuestFlaggedCompleted, questID) and true or false end
    return safe(IsQuestFlaggedCompleted, questID) and true or false
end

-- ---------------------------------------------------------------- never offered

-- Writ envelopes and Coin Pouches, built on first use (ns.WRITS is filled by Data.lua).
local keep
local function Kept(id)
    if not keep then
        keep = {}
        for _, w in ipairs(ns.WRITS or {}) do if w.writ then keep[w.writ] = true end end
        for _, p in ipairs(COIN_POUCHES) do keep[p] = true end
    end
    return keep[id]
end

-- "This Item Begins a Quest" in the item's tooltip; the answer per item ID never changes.
-- Also notes a "Use:" line (usableCache): an item you can use may matter outside any quest.
local startsCache, usableCache = {}, {}
local scanTip
local function TooltipStartsQuest(bag, slot, id)
    if startsCache[id] ~= nil then return startsCache[id] end
    local needle = ITEM_STARTS_QUEST or "This Item Begins a Quest"
    local use = ITEM_SPELL_TRIGGER_ONUSE or "Use:"
    local found, read, usable = false, false, false
    if C_TooltipInfo and C_TooltipInfo.GetBagItem then
        local data = safe(C_TooltipInfo.GetBagItem, bag, slot)
        if data and data.lines and #data.lines > 0 then
            read = true
            for _, line in ipairs(data.lines) do
                local t = line.leftText
                if t and t:find(needle, 1, true) then found = true end
                if t and t:find(use, 1, true) == 1 then usable = true end
            end
        end
    end
    if not read then
        if not scanTip then
            scanTip = CreateFrame("GameTooltip", "WLHelperCleanerScanTip", nil, "GameTooltipTemplate")
        end
        scanTip:SetOwner(WorldFrame, "ANCHOR_NONE")
        scanTip:ClearLines()
        safe(scanTip.SetBagItem, scanTip, bag, slot)
        read = scanTip:NumLines() > 0
        for i = 1, scanTip:NumLines() do
            local fs = _G["WLHelperCleanerScanTipTextLeft" .. i]
            local t = fs and fs:GetText()
            if t and t:find(needle, 1, true) then found = true end
            if t and t:find(use, 1, true) == 1 then usable = true end
        end
        scanTip:Hide()
    end
    -- A tooltip that has not loaded yet proves nothing: ask again next scan.
    if read then startsCache[id] = found; usableCache[id] = usable end
    return found
end

-- Items no quest asks for but that still do something: never checked, with the reason.
local KEEP = {
    [9240] = "À garder : invoque Gahz'rilla au gong de Zul'Farrak (quête « Gahz'rilla »)",
    [9239] = "À garder : se change en Mallet of Zul'Farrak à l'autel de Hakkar",
}

-- ---------------------------------------------------------------- LibForeverData index

-- needBy[itemID] = { { id, name, side, classes }, ... } quests whose objectives or steps use the
-- item; starter[itemID] = true when a quest starts from it. Built once, on the first scan.
local needBy, starter
local function BuildIndex()
    if needBy then return end
    needBy, starter = {}, {}
    local lib = Lib()
    if not lib then return end
    local ids = safe(lib.Ids, "quest") or {}
    for _, qid in ipairs(ids) do
        local q = safe(lib.Get, "quest", qid)
        if q then
            local seen = {}
            local function add(item)
                if item and not seen[item] then
                    seen[item] = true
                    local list = needBy[item]
                    if not list then list = {}; needBy[item] = list end
                    list[#list + 1] = { id = qid, name = q.name, side = q.side or 0, classes = q.classes or 0 }
                end
            end
            for _, o in ipairs(q.objectives or {}) do
                if o.kind == "item" then add(o.target) end
            end
            for _, s in ipairs(q.start or {}) do
                if s.kind == "item" and s.id then starter[s.id] = true end
            end
            if lib.Steps then
                for _, st in ipairs(safe(lib.Steps, qid) or {}) do
                    if st.targetKind == "item" then add(st.target) end
                end
            end
        end
    end
end

-- A quest of the other faction or another class will never need the item.
local function Eligible(q)
    local faction = UnitFactionGroup and UnitFactionGroup("player")
    if q.side == 1 and faction == "Horde" then return false end
    if q.side == 2 and faction == "Alliance" then return false end
    if q.classes and q.classes > 0 and bit and bit.band then
        local _, _, classID = UnitClass("player")
        if classID and bit.band(q.classes, 2 ^ (classID - 1)) == 0 then return false end
    end
    return true
end

-- ---------------------------------------------------------------- quest log

-- Is the quest in the log? Asked by quest ID, so quests under a collapsed header count too.
local function OnQuest(qid)
    if C_QuestLog and C_QuestLog.IsOnQuest then return safe(C_QuestLog.IsOnQuest, qid) and true or false end
    local i = GetQuestLogIndexByID and safe(GetQuestLogIndexByID, qid)
    return (i or 0) > 0
end

-- What the quests in your log need: item IDs (LibForeverData objectives and steps, the quest's own
-- usable item) and lowercase texts (objective lines, step and note texts) an item's name is searched
-- in. The third value is false when the objective texts could not be read at all.
-- The quest's whole text (description + objectives), read by selecting it in the log; the previous
-- selection is put back.
local function QuestFullText(index)
    if not (GetQuestLogQuestText and SelectQuestLogEntry) then return nil end
    local old = GetQuestLogSelection and safe(GetQuestLogSelection)
    safe(SelectQuestLogEntry, index)
    local desc, obj = safe(GetQuestLogQuestText)
    if old then safe(SelectQuestLogEntry, old) end
    local t = (desc or "") .. " " .. (obj or "")
    return t ~= " " and t or nil
end

local function LogNeeds()
    local ids, texts, active = {}, {}, {}
    local readAny, unknownQuest = false, false
    local n = C_QuestLog and C_QuestLog.GetNumQuestLogEntries and safe(C_QuestLog.GetNumQuestLogEntries)
        or safe(GetNumQuestLogEntries) or 0
    for i = 1, n do
        local qid, header
        local info = C_QuestLog and C_QuestLog.GetInfo and safe(C_QuestLog.GetInfo, i)
        if info then qid, header = info.questID, info.isHeader
        else
            local _, _, _, isHeader, _, _, _, id = safe(GetQuestLogTitle, i)
            qid, header = id, isHeader
        end
        if qid and qid > 0 and not header then
            active[#active + 1] = qid
            -- the quest's own title: an item named like a quest in your log (its letter, its
            -- instructions) belongs to it, even when no objective names it
            local title = (info and info.title) or select(1, safe(GetQuestLogTitle, i))
            if type(title) == "string" and title ~= "" then texts[#texts + 1] = title:lower() end
            -- the item the quest gives you to use ("use the torch on ...") is never a required item
            local link = GetQuestLogSpecialItemInfo and safe(GetQuestLogSpecialItemInfo, i)
            local sid = type(link) == "string" and tonumber(link:match("item:(%d+)"))
            if sid then ids[sid] = true end
            local full = QuestFullText(i)
            if full then texts[#texts + 1] = full:lower(); readAny = true end
            -- objective lines by log index, for clients without C_QuestLog.GetQuestObjectives
            if GetNumQuestLeaderBoards and GetQuestLogLeaderBoard then
                for j = 1, (safe(GetNumQuestLeaderBoards, i) or 0) do
                    local t = safe(GetQuestLogLeaderBoard, j, i)
                    if t and t ~= "" then texts[#texts + 1] = t:lower(); readAny = true end
                end
            end
        end
    end
    local lib = Lib()
    for _, qid in ipairs(active) do
        local objs = C_QuestLog and C_QuestLog.GetQuestObjectives and safe(C_QuestLog.GetQuestObjectives, qid)
        for _, o in ipairs(objs or {}) do
            if o.text and o.text ~= "" then texts[#texts + 1] = o.text:lower(); readAny = true end
        end
        if lib then
            local q = safe(lib.Get, "quest", qid)
            if not q then unknownQuest = true end   -- a Forever quest the data does not have
            for _, o in ipairs(q and q.objectives or {}) do
                if o.kind == "item" and o.target then ids[o.target] = true end
            end
            for _, st in ipairs(lib.Steps and safe(lib.Steps, qid) or {}) do
                if st.targetKind == "item" and st.target then ids[st.target] = true end
                if st.text and st.text ~= "" then texts[#texts + 1] = st.text:lower() end
            end
            for _, nt in ipairs(lib.Notes and safe(lib.Notes, qid) or {}) do
                if nt.text and nt.text ~= "" then texts[#texts + 1] = nt.text:lower() end
            end
        end
    end
    return ids, texts, readAny or #active == 0, unknownQuest
end

local function NamedIn(texts, name)
    if not name or name == "" then return false end
    name = name:lower()
    for _, t in ipairs(texts) do
        if t:find(name, 1, true) then return true end
    end
    return false
end

-- ---------------------------------------------------------------- scan

-- The client's (localised) quest title when it knows it, else LibForeverData's English one; the
-- second value is true for the client's own title.
local function QuestTitle(q)
    local t = C_QuestLog and (C_QuestLog.GetTitleForQuestID or C_QuestLog.GetQuestInfo)
    t = t and safe(t, q.id)
    if type(t) == "string" and t ~= "" then return t, true end
    return q.name or ("#" .. q.id), false
end
local function French() return root.lang == "fr" or (GetLocale() == "frFR" and root.lang ~= "en") end

local entries = {}          -- { id, name, count, quality, slots, reason, amber, manual }
local userChecked = {}      -- itemID -> true/false once the player clicked its box
local dirty = true

local function NumBags() return NUM_BAG_SLOTS or 4 end
-- 1 safe (checked), 2 check first (amber), 3 throw away yourself (grey)
local function rank(e) return e.manual and 3 or e.amber and 2 or 1 end

local function Scan()
    if not (C_Container and C_Container.GetContainerItemInfo and C_Item and C_Item.GetItemInfoInstant) then
        entries, dirty = {}, false
        return entries
    end
    BuildIndex()
    local needIds, texts, readLog, unknownQuest = LogNeeds()
    -- Without LibForeverData or readable objectives we cannot be sure: nothing is checked by default.
    local unsure = not Lib() or not readLog
    local byId, list = {}, {}
    for bag = 0, NumBags() do
        for slot = 1, (safe(C_Container.GetContainerNumSlots, bag) or 0) do
            local info = safe(C_Container.GetContainerItemInfo, bag, slot)
            local id = info and info.itemID
            if id and not Kept(id) then
                local e = byId[id]
                if e then
                    e.count = e.count + (info.stackCount or 1)
                    e.slots[#e.slots + 1] = { bag, slot }
                else
                    local qi = C_Container.GetContainerItemQuestInfo and safe(C_Container.GetContainerItemQuestInfo, bag, slot) or {}
                    local _, _, _, _, _, classID = safe(C_Item.GetItemInfoInstant, id)
                    local questy = classID == QUEST_CLASS or qi.isQuestItem
                    local name = info.hyperlink and info.hyperlink:match("%[(.-)%]") or WP.ItemName(id)
                    if questy and not qi.questID and not starter[id] and not needIds[id]
                        and not NamedIn(texts, name) and not TooltipStartsQuest(bag, slot, id) then
                        e = { id = id, name = name, count = info.stackCount or 1, slots = { { bag, slot } },
                              quality = info.quality or safe(C_Item.GetItemQualityByID, id) or 1 }
                        local done, pending, active
                        for _, q in ipairs(needBy[id] or {}) do
                            if OnQuest(q.id) then active = true; break
                            elseif Completed(q.id) then done = done or q
                            elseif Eligible(q) then pending = true end
                        end
                        if active then
                            e = nil                      -- a quest in your log uses it
                        elseif KEEP[id] then
                            e = nil                      -- to keep (the Zul'Farrak mallet...): not listed
                        elseif e.quality >= MANUAL_QUALITY then
                            e.manual, e.reason = true, L("Objet rare : le jeu demande une confirmation écrite")
                        elseif usableCache[id] and not done then
                            -- it does something when used: maybe a summon, a key, a teleport
                            e.amber, e.reason = true, L("Objet utilisable : lis son infobulle avant de le jeter")
                        elseif pending then
                            e.amber, e.reason = true, L("Peut servir à une quête suivante")
                        elseif done then
                            -- an English title in a French sentence reads badly: just say it was done
                            local title, loc = QuestTitle(done)
                            if loc or not French() then
                                e.reason = L("Quête rendue : %s"):format(title)
                            else
                                e.reason = L("Quête déjà rendue")
                            end
                        else
                            -- no data ties it to a quest you turned in: the game abandons a quest
                            -- whose item is destroyed, so this one is only listed, never destroyed here
                            e.manual = true
                            e.reason = unknownQuest
                                and L("Une quête de ton journal est inconnue : elle en a peut-être besoin")
                                or L("Aucune quête rendue ne l'utilise : détruis-le seulement si tu es sûr")
                        end
                        if e then
                            if unsure and not e.manual then e.amber = true end
                            list[#list + 1] = e
                        else
                            e = { skip = true, count = 0, slots = {} }
                        end
                    else
                        e = { skip = true, count = 0, slots = {} }
                    end
                    byId[id] = e
                end
            end
        end
    end
    -- Checked first, then amber, then manual; by name inside each group.
    table.sort(list, function(a, b)
        if rank(a) ~= rank(b) then return rank(a) < rank(b) end
        return (a.name or "") < (b.name or "")
    end)
    entries, dirty = list, false
    return list
end

local function IsChecked(e)
    if e.manual then return false end   -- grey: never ticked, never destroyed by the addon
    local u = userChecked[e.id]
    if u ~= nil then return u end
    return not e.amber
end

-- ---------------------------------------------------------------- destroy

-- Runs only from the button's OnClick: picks up one checked stack (re-read first so a moved or
-- swapped slot is never hit); the game's own confirmation destroys it.
local Refresh
local win
local function Destroy()
    if InCombatLockdown() then WP.Print(L("Impossible en combat : réessaie une fois le combat fini."), true); return end
    -- Bags or quest log changed since the list was drawn: show the fresh list, destroy nothing.
    if dirty then
        Refresh(true)
        WP.Print(L("La liste a changé : vérifie-la et clique encore."))
        return
    end
    ClearCursor()
    -- the game allows one destruction per click: the first checked stack goes, the button then
    -- shows what is left
    local n, name = 0, nil
    for _, e in ipairs(entries) do
        if IsChecked(e) and n == 0 then
            for _, s in ipairs(e.slots) do
                local info = safe(C_Container.GetContainerItemInfo, s[1], s[2])
                if n == 0 and info and info.itemID == e.id and not info.isLocked then
                    -- this client refuses DeleteCursorItem() to addons: the stack goes on your cursor
                    -- and the game's own "Destroy?" box finishes it when you click in the world
                    C_Container.PickupContainerItem(s[1], s[2])
                    local kind, cid = GetCursorInfo()
                    if kind == "item" and cid == e.id then n = 1; name = e.name else ClearCursor() end
                end
            end
        end
    end
    if name then
        WP.Print(string.format(L("%s est sur ton curseur : clique dans le décor (hors des fenêtres), puis confirme pour le détruire."), name))
        if win and win.step then
            win.step:SetText(string.format(L("%s est sur ton curseur. Clique dans le décor, hors des fenêtres, puis confirme."), name), "warn")
            win.step:Show()
            if win.Fit then win.Fit() end
        end
    end
    dirty = true
    C_Timer.After(0.3, function() if Refresh then Refresh(true) end end)
end

-- ---------------------------------------------------------------- window
-- Sacs (Bags), 420 wide: one sentence, the list grouped by risk under section headers, the step in
-- progress as a banner, and the one action. The window fits its content (scrolls past 80 % of the
-- screen height).

local W, INSET = 420, 16
local LIST_W = W - 2 * INSET
local rows = {}
local heads = {}            -- section headers, pooled
local RANK_TITLE = { "Sans risque", "À vérifier", "À détruire toi-même" }

local function num(v) return type(v) == "number" and not (root.IsSecret and root.IsSecret(v)) and v or nil end

-- The entry Destroy picks up next: the first checked one.
local function FirstChecked()
    for _, e in ipairs(entries) do if IsChecked(e) then return e end end
end

local function Paint(row, e)
    local on = IsChecked(e)
    row.box:SetShown(not e.manual)
    row.boxFill:SetAlpha(on and 1 or 0)
    row.boxBorder(on and C.accent or C.btnEdge, on and 1 or nil)
    row.check:SetShown(on)
    S.Painted(row.icon, S.ItemIcon(e.id))
    row.icon:SetDesaturated(e.manual and true or false)
    local q = S.QualityColor(e.id)
    if e.quality and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[e.quality] then
        local c = ITEM_QUALITY_COLORS[e.quality]; q = { c.r, c.g, c.b }
    end
    row.name:SetText((e.name or "?") .. (e.count > 1 and (" x" .. e.count) or ""))
    row.name:SetTextColor(q[1], q[2], q[3])
    local rc = e.amber and C.warn or C.muted
    row.reason:SetText(e.reason or "")
    row.reason:SetTextColor(rc[1], rc[2], rc[3])
    -- the row the next click destroys carries the selection fill
    row.sel:SetShown(FirstChecked() == e)
end

-- Measured row: name (12, wraps to 2 lines) and reason (11, wraps to 2 lines) right of the icon.
local function FitRow(row)
    local textW = LIST_W - 60 - 12
    local h = 6 + S.FitText(row.name, 2, textW, row)
    h = math.max(h, 6 + S.F.label + 2)
    row.reason:ClearAllPoints(); row.reason:SetPoint("TOPLEFT", row.name, "BOTTOMLEFT", 0, -3)
    local rh = S.FitText(row.reason, 2, textW, row)
    h = h + 3 + math.max(rh, S.F.meta + 2) + 8
    h = math.max(36, math.ceil(h))
    row:SetHeight(h)
    return h
end

local function MakeRow(parent)
    local row = CreateFrame("Button", nil, parent)
    row.wlOwned = true
    row:SetHeight(44)
    row.bg = S.Solid(row, "BACKGROUND", C.cardFill); row.bg:SetAllPoints()
    row.sel = S.Solid(row, "BACKGROUND", C.selFill); row.sel:SetAllPoints(); row.sel:Hide()
    row.hl = S.Solid(row, "BORDER", C.hoverFill); row.hl:SetAllPoints(); row.hl:SetAlpha(0)
    row.press = S.Solid(row, "BORDER", C.pressFill); row.press:SetAllPoints(); row.press:Hide()

    -- the tick box: 16 px, 1 px edge; ticked: accent fill and the HD check
    row.box = CreateFrame("Frame", nil, row)
    row.box:SetSize(16, 16); row.box:SetPoint("TOPLEFT", 8, -8)
    row.boxFill = S.Solid(row.box, "BACKGROUND", C.accent); row.boxFill:SetAllPoints(); row.boxFill:SetAlpha(0)
    row.boxBorder = S.Border(row.box, C.btnEdge)
    row.check = S.Icon(row.box, "check", 14, "ARTWORK", C.fg)
    row.check:SetPoint("CENTER")

    local holder = CreateFrame("Frame", nil, row)
    holder:SetSize(20, 20); holder:SetPoint("TOPLEFT", 32, -6)
    row.icon = holder:CreateTexture(nil, "ARTWORK"); row.icon:SetAllPoints()
    S.Border(holder, C.cardEdge)

    row.name = S.Text(row, S.F.label, C.fg)
    row.name:SetPoint("TOPLEFT", 60, -6)
    row.name:SetJustifyH("LEFT"); row.name:SetJustifyV("TOP")
    row.reason = S.Text(row, S.F.meta, C.muted)
    row.reason:SetJustifyH("LEFT"); row.reason:SetJustifyV("TOP")

    row:SetScript("OnEnter", function(self)
        root.Tween(self, self.hov or 0, 1, 0.10, function(v) self.hov = v; self.hl:SetAlpha(v) end)
        local e = self.entry
        local s = e and e.slots[1]
        if s then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            safe(GameTooltip.SetBagItem, GameTooltip, s[1], s[2])
            local c = C.accentSoft
            if e.manual then
                GameTooltip:AddLine(L("À détruire toi-même, depuis tes sacs."), C.warn[1], C.warn[2], C.warn[3], true)
            else
                GameTooltip:AddLine(IsChecked(e) and L("Clic : le décocher") or L("Clic : le cocher"), c[1], c[2], c[3], true)
            end
            GameTooltip:Show()
        end
    end)
    row:SetScript("OnLeave", function(self)
        root.Tween(self, self.hov or 0, 0, 0.10, function(v) self.hov = v; self.hl:SetAlpha(v) end)
        GameTooltip:Hide()
    end)
    row:SetScript("OnMouseDown", function(self) if self.entry and not self.entry.manual then self.press:Show() end end)
    row:SetScript("OnMouseUp", function(self) self.press:Hide() end)
    row:SetScript("OnClick", function(self)
        local e = self.entry
        if not e or e.manual then return end
        userChecked[e.id] = not IsChecked(e)
        for _, r in ipairs(rows) do if r:IsShown() and r.entry then Paint(r, r.entry) end end
        win.UpdateFooter()
    end)
    return row
end

local function CheckedCount()
    local n = 0
    for _, e in ipairs(entries) do if IsChecked(e) then n = n + 1 end end
    return n
end

Refresh = function(rescan)
    if not win or not win:IsShown() then return end
    if rescan or dirty then Scan() end
    -- the item left the cursor (destroyed, put back): the step is over
    local kind = GetCursorInfo and GetCursorInfo()
    if kind ~= "item" and win.step then win.step:Hide() end
    local count = { 0, 0, 0 }
    for _, e in ipairs(entries) do count[rank(e)] = count[rank(e)] + 1 end
    local child = win.list.child
    local y, lastRank, k = 0, nil, 0
    for i, e in ipairs(entries) do
        local r = rank(e)
        if r ~= lastRank then
            -- a section header above each group: "Sans risque 3", "À vérifier 1"...
            lastRank, k = r, k + 1
            local h = heads[k]
            if not h then h = S.SectionHeader(child, ""); heads[k] = h end
            if k > 1 then y = y + 8 end
            h:ClearAllPoints()
            h:SetPoint("TOPLEFT", 0, -y); h:SetPoint("TOPRIGHT", 0, -y)
            h:Set(L(RANK_TITLE[r]), count[r])
            h:Show()
            y = y + 32 + 4
        end
        local row = rows[i]
        if not row then row = MakeRow(child); rows[i] = row end
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", 0, -y); row:SetPoint("TOPRIGHT", 0, -y)
        row.entry = e
        Paint(row, e)
        row:Show()
        y = y + FitRow(row) + 2
    end
    for i = #entries + 1, #rows do rows[i]:Hide(); rows[i].entry = nil end
    for i = k + 1, #heads do heads[i]:Hide() end
    win.listH = y
    win.list:SetShown(#entries > 0)
    win.empty:SetShown(#entries == 0)
    win.UpdateFooter()
    win.Fit()
end

local function Build()
    win = S.Window("WLHelperCleaner", W, 300, L("Sacs"), L("Objets de quête qui ne servent plus"), WLWritsDB, "cleanerPos",
        { header = S.HEADER_H, minH = 160 })
    local top = win:ContentTop() + 12

    win.intro = S.Text(win, S.F.body, C.text)
    win.intro:SetPoint("TOPLEFT", INSET, -top)
    win.intro:SetJustifyH("LEFT"); win.intro:SetJustifyV("TOP")
    win.intro:SetText(L("Aucune quête de ton journal n'a besoin de ces objets. Coche ceux à détruire : le jeu en détruit un par clic."))

    win.list = S.ScrollArea(win)
    win.empty = S.EmptyState(win, "bag", L("Tes sacs sont propres"),
        L("Les objets de quête qui ne servent plus apparaîtront ici."))
    win.empty:ClearAllPoints(); win.empty:SetPoint("TOP", win, "TOP", 0, -(top + 12))
    win.empty:Hide()

    -- the step in progress (an item on the cursor): a warning banner above the button
    win.step = S.Banner(win, "warn", "")
    win.step:Hide()

    -- destructive, so never primary: the danger button with the trash icon; the game's own box
    -- asks for the confirmation once the stack is on the cursor
    local destroy = S.Button(win, "", 0, 32, "danger", Destroy, function()
        local first = FirstChecked()
        if not first then return nil end
        return { win.destroy:GetText(), string.format(L("Le jeu détruit un objet par clic : %s d'abord."), first.name or "?"),
            L("Clic : le prendre sur le curseur, puis confirmer dans le décor") }
    end)
    destroy:SetIcon("trash")
    win.destroy = destroy

    function win.Fit()
        -- only items to destroy by hand: a sentence that says so, and no button to press
        local tickable = false
        for _, e in ipairs(entries) do if not e.manual then tickable = true end end
        win.intro:SetText(tickable
            and L("Aucune quête de ton journal n'a besoin de ces objets. Coche ceux à détruire : le jeu en détruit un par clic.")
            or L("Ces objets ne servent plus, mais le jeu les fait détruire à la main, depuis tes sacs."))
        local introH = S.FitText(win.intro, 0, LIST_W, win)
        if introH < S.F.body then introH = S.F.body + 2 end
        local listTop = top + introH + 12
        local btnH = tickable and 32 or 0
        local bottom = 12 + btnH
        local stepH = 0
        if win.step:IsShown() then stepH = win.step:Fit(LIST_W) end
        local content
        if #entries == 0 then
            win.intro:Hide()
            content = win.empty:Fit() + 12
            destroy:Hide()
            win.step:Hide()
            win:FitHeight(content)
            return
        end
        win.intro:Show(); destroy:SetShown(tickable)
        content = introH + 12 + (win.listH or 0) + (tickable and 12 or 0) + (stepH > 0 and (stepH + 8) or 0) + btnH
        win:FitHeight(content)
        -- the list takes what is left between the sentence and the bottom row (scrolls when capped)
        if stepH > 0 then
            win.step:ClearAllPoints()
            win.step:SetPoint("BOTTOMLEFT", INSET, bottom + 8); win.step:SetPoint("BOTTOMRIGHT", -INSET, bottom + 8)
            bottom = bottom + 8 + stepH
        end
        win.list:ClearAllPoints()
        win.list:SetPoint("TOPLEFT", INSET, -listTop)
        win.list:SetPoint("BOTTOMRIGHT", -INSET, bottom + (tickable and 12 or 0))
        win.list.child:SetWidth(LIST_W)
        win.list:SetContentHeight(win.listH or 0)
        destroy:ClearAllPoints(); destroy:SetPoint("BOTTOMLEFT", INSET, 12)
    end

    function win.UpdateFooter()
        local n = CheckedCount()
        if n == 0 then destroy:SetText(L("Détruire"))
        elseif n == 1 then destroy:SetText(L("Détruire l'objet coché"))
        else destroy:SetText(string.format(L("Détruire le suivant (%d cochés)"), n)) end
        local any = false
        for _, e in ipairs(entries) do if not e.manual then any = true end end
        destroy:SetDisabledReason((not any and #entries > 0) and L("Ces objets se détruisent à la main, depuis tes sacs.")
            or L("Coche au moins un objet."))
        destroy:SetEnabled(n > 0)
        destroy.Paint()
    end

    win:SetScript("OnShow", function() win.list:ScrollTo(0, true); win.step:Hide(); Refresh(true) end)
end

-- ---------------------------------------------------------------- events

-- A clickable reminder in the chat after a quest is turned in (once per new count) or when the bags
-- are full (at most every 5 minutes); nothing is saved.
local lastAnnounced, lastFull, loginAt = 0, 0, GetTime()
local CLEAN_LINK = "addon:wlhelperclean"
local function Announce(force)
    if not WP.ModuleOn("bags") or InCombatLockdown() or (win and win:IsShown()) then return end
    if GetTime() - loginAt < 10 then return end
    local n = WP.Cleaner.Count()
    if n == 0 then lastAnnounced = 0; return end
    if not force and n == lastAnnounced then return end
    lastAnnounced = n
    local link = S.Hex(C.accentSoft) .. "|H" .. CLEAN_LINK .. "|h[" .. L("Nettoyer") .. "]|h|r"
    if n == 1 then
        WP.Print(string.format(L("1 objet de quête ne sert plus et prend une place dans tes sacs. Clique sur %s pour le voir."), link), true)
    else
        WP.Print(string.format(L("%d objets de quête ne servent plus et prennent de la place dans tes sacs. Clique sur %s pour les voir."), n, link), true)
    end
end

local pending = false
local ev = CreateFrame("Frame")
pcall(ev.RegisterEvent, ev, "BAG_UPDATE_DELAYED")
pcall(ev.RegisterEvent, ev, "QUEST_LOG_UPDATE")
pcall(ev.RegisterEvent, ev, "QUEST_TURNED_IN")
pcall(ev.RegisterEvent, ev, "UI_ERROR_MESSAGE")
ev:SetScript("OnEvent", function(self, e, a1, a2)
    if e == "UI_ERROR_MESSAGE" then
        -- "Inventory is full": not a bag change, only the reminder
        if not ERR_INV_FULL or GetTime() - lastFull <= 300 then return end
        local ok, full = pcall(function() return a2 == ERR_INV_FULL or a1 == ERR_INV_FULL end)
        if ok and full then
            lastFull = GetTime()
            Announce(true)
        end
        return
    end
    if not WP.ModuleOn("bags") then return end
    dirty = true
    if e == "QUEST_TURNED_IN" then C_Timer.After(2, function() Announce(false) end) end
    if win and win:IsShown() and not pending then
        pending = true
        C_Timer.After(0.5, function() pending = false; Refresh(true) end)
    end
end)

-- the [Clean up] link of the reminder; runs after the game handled the click: nothing of
-- Blizzard's is replaced
if SetItemRef then
    hooksecurefunc("SetItemRef", function(link)
        if type(link) ~= "string" or (issecretvalue and issecretvalue(link)) then return end
        if link == CLEAN_LINK and not (win and win:IsShown()) then WP.Cleaner.Toggle() end
    end)
end

-- ---------------------------------------------------------------- API

WP.Cleaner = {
    Toggle = function()
        if win and win:IsShown() then win:Hide(); return end
        if WP.ModuleOff("bags") then return end
        if not win then Build() end
        win:Show()
    end,
    Hide = function() if win then win:Hide() end end,
    -- How many items the window offers (for the home page and the minimap tooltip).
    Count = function()
        if not WP.ModuleOn("bags") then return 0 end
        if dirty then Scan() end
        local n = 0
        for _, e in ipairs(entries) do if not e.manual then n = n + 1 end end
        return n
    end,
}
