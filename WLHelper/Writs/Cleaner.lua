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
    ["Objet rare : à détruire toi-même"] = "Rare item: destroy it yourself",
    ["Quête inconnue dans ton journal : à détruire toi-même"] = "Unknown quest in your log: destroy it yourself",
    ["Pas lié à une quête rendue : à détruire toi-même si tu es sûr"] = "Not tied to a turned-in quest: destroy it yourself if you are sure",
    ["Objets de quête qu'aucune quête de ton journal ne demande.\nCochés : sans risque. Orange : lis la raison avant de cocher. Gris : objets rares ou sans quête connue, à jeter toi-même depuis tes sacs."] =
        "Quest items no quest in your log asks for.\nTicked: safe. Orange: read the reason before ticking. Grey: rare items or no known quest, throw them away yourself from your bags.",
    ["Rien que l'addon puisse détruire"] = "Nothing the addon can destroy",
    ["Objets de quête inutiles"] = "Useless quest items",
    ["Quête rendue : %s"] = "Quest turned in: %s",
    ["Aucune quête ne le demande"] = "No quest asks for it",
    ["Peut servir à une quête suivante"] = "May be needed for a later quest",
    ["Détruire : %s"] = "Destroy: %s",
    ["Détruire : %s (1 sur %d)"] = "Destroy: %s (1 of %d)",
    ["Fermer"] = "Close",
    ["Sans risque (%d)"] = "Safe (%d)",
    ["À vérifier (%d)"] = "Check first (%d)",
    ["À jeter toi-même (%d)"] = "Throw away yourself (%d)",
    ["Quête déjà rendue"] = "Quest already turned in",
    ["%s est sur ton curseur. Clique dans le décor (hors des fenêtres), puis sur Oui."] = "%s is on your cursor. Click in the world (outside any window), then Yes.",
    ["Nettoyer"] = "Clean up",
    ["1 objet de quête ne sert plus et encombre tes sacs. %s"] = "1 quest item is no longer needed and clutters your bags. %s",
    ["%d objets de quête ne servent plus et encombrent tes sacs. %s"] = "%d quest items are no longer needed and clutter your bags. %s",
    ["Rien à jeter : tes sacs sont propres."] = "Nothing to throw away: your bags are clean.",
    ["impossible en combat."] = "not possible in combat.",
    ["%d pile(s) détruite(s)."] = "%d stack(s) destroyed.",
    ["%s détruit."] = "%s destroyed.",
    ["%s est sur ton curseur : clique dans le monde (hors des fenêtres), puis confirme pour le détruire."] = "%s is on your cursor: click in the world (outside any window), then confirm to destroy it.",
    ["Coche ce que tu veux détruire"] = "Tick what you want to destroy",
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
local ROW_H, PAD = 56, 14
local COIN_POUCHES = { 284583, 284584, 284585, 284586 }
local CHECK_TEX = "Interface\\Buttons\\UI-CheckBox-Check"

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
local RANK_TITLE = { "Sans risque (%d)", "À vérifier (%d)", "À jeter toi-même (%d)" }

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
                            e.manual, e.reason = true, L("Objet rare : à détruire toi-même")
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
                                and L("Quête inconnue dans ton journal : à détruire toi-même")
                                or L("Pas lié à une quête rendue : à détruire toi-même si tu es sûr")
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
    if InCombatLockdown() then WP.Print(L("impossible en combat.")); return end
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
        WP.Print(string.format(L("%s est sur ton curseur : clique dans le monde (hors des fenêtres), puis confirme pour le détruire."), name))
        if win and win.step then
            win.step:SetText(string.format(L("%s est sur ton curseur. Clique dans le décor (hors des fenêtres), puis sur Oui."), name))
            win.step:Show()
        end
    end
    dirty = true
    C_Timer.After(0.3, function() if Refresh then Refresh(true) end end)
end

-- ---------------------------------------------------------------- window

local rows, offset = {}, 0
local heads = {}            -- group titles, a pool of font strings
local HEAD_H = 24

local function Paint(row, e)
    local on = IsChecked(e)
    row.box:SetShown(not e.manual)
    row.fill:SetColorTexture(C.brand[1], C.brand[2], C.brand[3], on and 1 or 0)
    row.boxBorder(on and C.brand or { 0.353, 0.373, 0.400 })
    row.check:SetShown(on)
    row.icon:SetTexture(S.ItemIcon(e.id))
    row.icon:SetDesaturated(e.manual and true or false)
    local q = S.QualityColor(e.id)
    if e.quality and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[e.quality] then
        local c = ITEM_QUALITY_COLORS[e.quality]; q = { c.r, c.g, c.b }
    end
    row.name:SetText((e.name or "?") .. (e.count > 1 and (" x" .. e.count) or ""))
    row.name:SetTextColor(q[1], q[2], q[3])
    local rc = (e.amber or e.keep) and C.warn or e.manual and C.muted or C.dim
    row.reason:SetText(e.reason or "")
    row.reason:SetTextColor(rc[1], rc[2], rc[3])
end

local function MakeRow(parent)
    local row = CreateFrame("Button", nil, parent)
    row:SetHeight(ROW_H)
    local hl = S.Solid(row, "BACKGROUND", C.hover, 0)
    hl:SetAllPoints()
    local line = S.Solid(row, "BORDER", C.divider)
    line:SetPoint("BOTTOMLEFT"); line:SetPoint("BOTTOMRIGHT"); line:SetHeight(1)

    row.box = CreateFrame("Frame", nil, row)
    row.box:SetSize(16, 16); row.box:SetPoint("LEFT", 0, 0)
    row.fill = S.Solid(row.box, "BACKGROUND", C.brand, 0)
    row.fill:SetAllPoints()
    row.boxBorder = S.Border(row.box, C.border)
    row.check = row.box:CreateTexture(nil, "ARTWORK")
    row.check:SetTexture(CHECK_TEX)
    row.check:SetDesaturated(true)
    row.check:SetVertexColor(1, 1, 1)
    row.check:SetPoint("CENTER"); row.check:SetSize(18, 18)

    local iconHolder = CreateFrame("Frame", nil, row)
    iconHolder:SetSize(22, 22); iconHolder:SetPoint("LEFT", 26, 0)
    row.icon = iconHolder:CreateTexture(nil, "ARTWORK")
    row.icon:SetPoint("TOPLEFT", 1, -1); row.icon:SetPoint("BOTTOMRIGHT", -1, 1)
    row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    S.Border(iconHolder, { 0.314, 0.337, 0.365 })

    row.name = S.Text(row, 15, C.text)
    row.name:SetPoint("TOPLEFT", 58, -7); row.name:SetPoint("TOPRIGHT", -4, -7)
    row.name:SetJustifyH("LEFT")
    row.reason = S.Text(row, 13, C.dim)
    row.reason:SetPoint("TOPLEFT", row.name, "BOTTOMLEFT", 0, -3); row.reason:SetPoint("RIGHT", -4, 0)
    row.reason:SetJustifyH("LEFT"); row.reason:SetJustifyV("TOP")
    -- the reason may take two lines: never cut with "..."
    row.reason:SetWordWrap(true); if row.reason.SetMaxLines then row.reason:SetMaxLines(2) end

    row:SetScript("OnEnter", function(self)
        hl:SetColorTexture(C.hover[1], C.hover[2], C.hover[3], 1)
        local s = self.entry and self.entry.slots[1]
        if s then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            safe(GameTooltip.SetBagItem, GameTooltip, s[1], s[2])
            GameTooltip:Show()
        end
    end)
    row:SetScript("OnLeave", function() hl:SetColorTexture(C.hover[1], C.hover[2], C.hover[3], 0); GameTooltip:Hide() end)
    row:SetScript("OnClick", function(self)
        local e = self.entry
        if not e or e.manual then return end
        userChecked[e.id] = not IsChecked(e)
        Paint(self, e)
        win.UpdateFooter()
    end)
    return row
end

local function Layout()
    local viewH = win.list:GetHeight()
    local h = win.contentH or #entries * ROW_H
    local maxOff = math.max(0, h - viewH)
    offset = math.max(0, math.min(offset, maxOff))
    win.content:ClearAllPoints()
    win.content:SetPoint("TOPLEFT", 0, offset)
    win.content:SetPoint("TOPRIGHT", 0, offset)
    win.content:SetHeight(math.max(1, h))
end

Refresh = function(rescan)
    if not win or not win:IsShown() then return end
    if rescan or dirty then Scan() end
    -- the item left the cursor (destroyed, put back): the step is over
    local kind = GetCursorInfo and GetCursorInfo()
    if kind ~= "item" and win.step then win.step:Hide() end
    local count = { 0, 0, 0 }
    for _, e in ipairs(entries) do count[rank(e)] = count[rank(e)] + 1 end
    local y, lastRank, k = 0, nil, 0
    for i, e in ipairs(entries) do
        local r = rank(e)
        if r ~= lastRank then
            -- a title above each group: "Safe (3)", "Check first (1)"...
            lastRank, k = r, k + 1
            local h = heads[k]
            if not h then
                h = S.Text(win.content, 13, C.muted)
                h:SetJustifyH("LEFT")
                heads[k] = h
            end
            h:ClearAllPoints()
            h:SetPoint("TOPLEFT", 0, -y - 6)
            h:SetText(string.format(L(RANK_TITLE[r]), count[r]))
            h:Show()
            y = y + HEAD_H
        end
        local row = rows[i]
        if not row then
            row = MakeRow(win.content)
            rows[i] = row
        end
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", 0, -y)
        row:SetPoint("TOPRIGHT", 0, -y)
        y = y + ROW_H
        row.entry = e
        Paint(row, e)
        row:Show()
    end
    for i = #entries + 1, #rows do rows[i]:Hide(); rows[i].entry = nil end
    for i = k + 1, #heads do heads[i]:Hide() end
    win.contentH = y
    win.empty:SetShown(#entries == 0)
    Layout()
    win.UpdateFooter()
end

local function CheckedCount()
    local n = 0
    for _, e in ipairs(entries) do if IsChecked(e) then n = n + 1 end end
    return n
end

local function Build()
    win = S.Window("WLHelperCleaner", 460, 500, L("Objets de quête inutiles"), nil, WLWritsDB, "cleanerPos")

    local intro = S.Text(win, 14, C.dim)
    intro:SetWordWrap(true)
    intro:SetJustifyH("LEFT"); intro:SetJustifyV("TOP")
    intro:SetPoint("TOPLEFT", PAD, -38 - PAD)
    intro:SetWidth(460 - 2 * PAD)
    intro:SetText(L("Objets de quête qu'aucune quête de ton journal ne demande.\nCochés : sans risque. Orange : lis la raison avant de cocher. Gris : objets rares ou sans quête connue, à jeter toi-même depuis tes sacs."))

    local footer = CreateFrame("Frame", nil, win)
    footer:SetPoint("BOTTOMLEFT", 1, 1); footer:SetPoint("BOTTOMRIGHT", -1, 1); footer:SetHeight(84)
    local fline = S.Solid(footer, "BORDER", C.divider)
    fline:SetPoint("TOPLEFT"); fline:SetPoint("TOPRIGHT"); fline:SetHeight(1)

    local cancelW = 90
    local cancel = S.Button(footer, L("Fermer"), cancelW, 36, "secondary", function() win:Hide() end)
    cancel:SetPoint("TOPRIGHT", -(PAD - 1), -12)
    local destroy = S.Button(footer, "", 460 - 2 * PAD - 8 - cancelW, 36, "primary", Destroy)
    destroy:SetPoint("TOPLEFT", PAD - 1, -12)
    -- a long item name is cut instead of overflowing the button
    destroy.label:SetWordWrap(false)
    destroy.label:SetWidth(460 - 2 * PAD - 8 - cancelW - 16)

    -- the step in progress, under the buttons: what to do with the item on the cursor
    win.step = S.Text(footer, 13, C.warn)
    win.step:SetPoint("BOTTOMLEFT", PAD, 8)
    win.step:SetWidth(460 - 2 * PAD)
    win.step:SetJustifyH("LEFT")
    win.step:SetWordWrap(true)
    win.step:Hide()

    function win.UpdateFooter()
        local n = CheckedCount()
        -- the first checked entry is the one Destroy picks up: name it
        local first
        for _, e in ipairs(entries) do if IsChecked(e) then first = e.name or "?"; break end end
        if n == 0 then destroy.label:SetText(L("Coche ce que tu veux détruire"))
        elseif n == 1 then destroy.label:SetText(string.format(L("Détruire : %s"), first))
        else destroy.label:SetText(string.format(L("Détruire : %s (1 sur %d)"), first, n)) end
        destroy:SetEnabled(n > 0)
        -- only greyed items: nothing to tick, say it instead of "tick what you want"
        local any = false
        for _, e in ipairs(entries) do if not e.manual then any = true end end
        if n == 0 and not any and #entries > 0 then destroy.label:SetText(L("Rien que l'addon puisse détruire")) end
        destroy.Paint(false)
    end

    -- Clipped list, scrolled one row per wheel tick.
    local list = CreateFrame("Frame", nil, win)
    list:SetPoint("TOPLEFT", intro, "BOTTOMLEFT", 0, -PAD)
    list:SetPoint("RIGHT", win, "RIGHT", -PAD, 0)
    list:SetPoint("BOTTOM", footer, "TOP", 0, 0)
    list:SetClipsChildren(true)
    list:EnableMouseWheel(true)
    list:SetScript("OnMouseWheel", function(_, delta)
        offset = offset - delta * ROW_H
        Layout()
    end)
    list:SetScript("OnSizeChanged", function() if win:IsShown() then Layout() end end)
    win.list = list
    win.content = CreateFrame("Frame", nil, list)

    win.empty = S.Text(list, 14, C.dim)
    win.empty:SetPoint("CENTER", 0, 10)
    win.empty:SetText(L("Rien à jeter : tes sacs sont propres."))
    win.empty:Hide()

    win:SetScript("OnShow", function() offset = 0; win.step:Hide(); Refresh(true) end)
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
    local link = "|cff6fdc8c|H" .. CLEAN_LINK .. "|h[" .. L("Nettoyer") .. "]|h|r"
    if n == 1 then
        WP.Print(string.format(L("1 objet de quête ne sert plus et encombre tes sacs. %s"), link))
    else
        WP.Print(string.format(L("%d objets de quête ne servent plus et encombrent tes sacs. %s"), n, link))
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
