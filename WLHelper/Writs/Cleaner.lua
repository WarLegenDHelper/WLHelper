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
    ["Objets de quête inutiles"] = "Useless quest items",
    ["Aucune quête de ton journal ne les demande.\nLes objets qui lancent une quête ne sont jamais proposés."] =
        "No quest in your log needs them.\nItems that start a quest are never offered.",
    ["Quête rendue : %s"] = "Quest turned in: %s",
    ["Aucune quête ne le demande"] = "No quest asks for it",
    ["Peut servir à une quête suivante"] = "May be needed for a later quest",
    ["Qualité rare ou plus : à détruire à la main"] = "Rare quality or better: destroy it by hand",
    ["Détruire les %d objets cochés"] = "Destroy the %d checked items",
    ["Détruire l'objet coché"] = "Destroy the checked item",
    ["Annuler"] = "Cancel",
    ["Rien à jeter : tes sacs sont propres."] = "Nothing to throw away: your bags are clean.",
    ["impossible en combat."] = "not possible in combat.",
    ["%d pile(s) détruite(s)."] = "%d stack(s) destroyed.",
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
local ROW_H, PAD = 46, 14
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
local function LogNeeds()
    local ids, texts, active = {}, {}, {}
    local readAny = false
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
            -- the item the quest gives you to use ("use the torch on ...") is never a required item
            local link = GetQuestLogSpecialItemInfo and safe(GetQuestLogSpecialItemInfo, i)
            local sid = type(link) == "string" and tonumber(link:match("item:(%d+)"))
            if sid then ids[sid] = true end
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
    return ids, texts, readAny or #active == 0
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

-- The client's (localised) quest title when it knows it, else LibForeverData's English one.
local function QuestTitle(q)
    local t = C_QuestLog and (C_QuestLog.GetTitleForQuestID or C_QuestLog.GetQuestInfo)
    t = t and safe(t, q.id)
    if type(t) == "string" and t ~= "" then return t end
    return q.name or ("#" .. q.id)
end

local entries = {}          -- { id, name, count, quality, slots, reason, amber, manual }
local userChecked = {}      -- itemID -> true/false once the player clicked its box
local dirty = true

local function NumBags() return NUM_BAG_SLOTS or 4 end

local function Scan()
    if not (C_Container and C_Container.GetContainerItemInfo and C_Item and C_Item.GetItemInfoInstant) then
        entries, dirty = {}, false
        return entries
    end
    BuildIndex()
    local needIds, texts, readLog = LogNeeds()
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
                            e.manual, e.keep, e.reason = true, true, L(KEEP[id])
                        elseif e.quality >= MANUAL_QUALITY then
                            e.manual, e.reason = true, L("Qualité rare ou plus : à détruire à la main")
                        elseif usableCache[id] and not done then
                            -- it does something when used: maybe a summon, a key, a teleport
                            e.amber, e.reason = true, L("Objet utilisable : lis son infobulle avant de le jeter")
                        elseif pending then
                            e.amber, e.reason = true, L("Peut servir à une quête suivante")
                        elseif done then
                            e.reason = L("Quête rendue : %s"):format(QuestTitle(done))
                        else
                            e.reason = L("Aucune quête ne le demande")
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
    local function rank(e) return e.manual and 3 or e.amber and 2 or 1 end
    table.sort(list, function(a, b)
        if rank(a) ~= rank(b) then return rank(a) < rank(b) end
        return (a.name or "") < (b.name or "")
    end)
    entries, dirty = list, false
    return list
end

local function IsChecked(e)
    if e.manual then return false end
    local u = userChecked[e.id]
    if u ~= nil then return u end
    return not e.amber
end

-- ---------------------------------------------------------------- destroy

-- Runs only from the confirm button's OnClick (a hardware event): one PickupContainerItem +
-- DeleteCursorItem per stack, each stack re-read first so a moved or swapped slot is never hit.
local Refresh
local function Destroy()
    if InCombatLockdown() then WP.Print(L("impossible en combat.")); return end
    -- Bags or quest log changed since the list was drawn: show the fresh list, destroy nothing.
    if dirty then
        Refresh(true)
        WP.Print(L("La liste a changé : vérifie-la et clique encore."))
        return
    end
    ClearCursor()
    local n = 0
    for _, e in ipairs(entries) do
        if IsChecked(e) then
            for _, s in ipairs(e.slots) do
                local info = safe(C_Container.GetContainerItemInfo, s[1], s[2])
                if info and info.itemID == e.id and not info.isLocked and (info.quality or 0) < MANUAL_QUALITY then
                    C_Container.PickupContainerItem(s[1], s[2])
                    local kind, cid = GetCursorInfo()
                    if kind == "item" and cid == e.id then DeleteCursorItem(); n = n + 1 end
                    ClearCursor()
                end
            end
            userChecked[e.id] = nil
        end
    end
    if n > 0 then WP.Print(L("%d pile(s) détruite(s)."):format(n)) end
    dirty = true
    C_Timer.After(0.3, function() if Refresh then Refresh(true) end end)
end

-- ---------------------------------------------------------------- window

local win, rows, offset = nil, {}, 0

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
    row.name:SetText((e.name or "?") .. (e.count > 1 and (" ×" .. e.count) or ""))
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
    row.reason:SetJustifyH("LEFT")

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
    local maxOff = math.max(0, #entries * ROW_H - viewH)
    offset = math.max(0, math.min(offset, maxOff))
    win.content:ClearAllPoints()
    win.content:SetPoint("TOPLEFT", 0, offset)
    win.content:SetPoint("TOPRIGHT", 0, offset)
    win.content:SetHeight(math.max(1, #entries * ROW_H))
end

Refresh = function(rescan)
    if not win or not win:IsShown() then return end
    if rescan or dirty then Scan() end
    for i, e in ipairs(entries) do
        local row = rows[i]
        if not row then
            row = MakeRow(win.content)
            row:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_H)
            row:SetPoint("TOPRIGHT", 0, -(i - 1) * ROW_H)
            rows[i] = row
        end
        row.entry = e
        Paint(row, e)
        row:Show()
    end
    for i = #entries + 1, #rows do rows[i]:Hide(); rows[i].entry = nil end
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
    win = S.Window("WLHelperCleaner", 400, 480, L("Objets de quête inutiles"), nil, WLWritsDB, "cleanerPos")

    local intro = S.Text(win, 14, C.dim)
    intro:SetWordWrap(true)
    intro:SetJustifyH("LEFT"); intro:SetJustifyV("TOP")
    intro:SetPoint("TOPLEFT", PAD, -38 - PAD)
    intro:SetWidth(400 - 2 * PAD)
    intro:SetText(L("Aucune quête de ton journal ne les demande.\nLes objets qui lancent une quête ne sont jamais proposés."))

    local footer = CreateFrame("Frame", nil, win)
    footer:SetPoint("BOTTOMLEFT", 1, 1); footer:SetPoint("BOTTOMRIGHT", -1, 1); footer:SetHeight(60)
    local fline = S.Solid(footer, "BORDER", C.divider)
    fline:SetPoint("TOPLEFT"); fline:SetPoint("TOPRIGHT"); fline:SetHeight(1)

    local cancelW = 90
    local cancel = S.Button(footer, L("Annuler"), cancelW, 36, "secondary", function() win:Hide() end)
    cancel:SetPoint("TOPRIGHT", -(PAD - 1), -12)
    local destroy = S.Button(footer, "", 400 - 2 * PAD - 8 - cancelW, 36, "primary", Destroy)
    destroy:SetPoint("TOPLEFT", PAD - 1, -12)

    function win.UpdateFooter()
        local n = CheckedCount()
        destroy.label:SetText(n == 1 and L("Détruire l'objet coché") or L("Détruire les %d objets cochés"):format(n))
        destroy:SetEnabled(n > 0)
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

    win:SetScript("OnShow", function() offset = 0; Refresh(true) end)
end

-- ---------------------------------------------------------------- events

local pending = false
local ev = CreateFrame("Frame")
ev:RegisterEvent("BAG_UPDATE_DELAYED")
ev:RegisterEvent("QUEST_LOG_UPDATE")
ev:RegisterEvent("QUEST_TURNED_IN")
ev:SetScript("OnEvent", function()
    if not WP.ModuleOn("bags") then return end
    dirty = true
    if win and win:IsShown() and not pending then
        pending = true
        C_Timer.After(0.5, function() pending = false; Refresh(true) end)
    end
end)

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
