-- Writs/FinderPick.lua: "Find a group", where to search, picked on cards (report: "the dungeon
-- choice in the LFG should look like the guide's, with the dungeons' pictures, very visual").
-- A window of three tabs:
--  * Dungeons and Raids: one card per instance, its picture (the guide's ns.DungeonArt), its name,
--    its levels, "your route" and "your quests" badges; a click ticks it (F.sel, the tab's dungeon
--    choice). An instance the game's finder does not list is greyed.
--  * Quests and zones: the game finder's other activities (questing zones), one tile each, with
--    its levels; the zone of a group quest in your log says so ("Your quest: Summoning Shadra").
--    A click ticks it (F.selZone: activity IDs searched beside the dungeons).
-- And the group quests themselves: WP.Finder.GroupQuests() reads the log (elite / group quests and
-- their zone); Finder.lua offers "Your group quests" as a source, its zones ticked.
-- Never: a Blizzard frame shown or touched, a listing created (the game keeps that to itself).
local ADDON, root = ...
local ns = root.Writs
local WP = ns.WP
local L = ns.L
local S = ns.S
local C = S.C
local FS = S.F

local F = WP.Finder
if not F then return end

ns.AddEnglish({
    ["Choisir où chercher"] = "Choose where to search",
    ["Clique les cartes à chercher, puis Chercher."] = "Click the cards to search, then Search.",
    ["Donjons"] = "Dungeons",
    ["Raids"] = "Raids",
    ["Quêtes et zones"] = "Quests and zones",
    ["Ta route"] = "Your route",
    ["Tes quêtes : %d"] = "Your quests: %d",
    ["Ta quête : %s"] = "Your quest: %s",
    ["Tes quêtes : %s"] = "Your quests: %s",
    ["Niveaux %d-%d"] = "Levels %d-%d",
    ["Niveau %d"] = "Level %d",
    ["Pas dans la recherche de groupe du jeu"] = "Not in the game's group finder",
    ["Pour ton niveau"] = "For your level",
    ["Autres niveaux"] = "Other levels",
    ["%d choisis"] = "%d picked",
    ["1 choisi"] = "1 picked",
    ["Rien de choisi : tout ce qui est à ton niveau."] = "Nothing picked: everything at your level.",
    ["Effacer"] = "Clear",
    ["Clic : cocher ou décocher"] = "Click: tick or untick",
    ["La recherche de groupe du jeu n'a pas encore répondu : rouvre dans un instant."] = "The game's group finder has not answered yet: open again in a moment.",
    ["Aucune activité de quête ou de zone dans la recherche de groupe du jeu."] = "No quest or zone activity in the game's group finder.",
    ["Tes quêtes de groupe : %s"] = "Your group quests: %s",
    ["Quête : %s (%s), on cherche du monde"] = "Quest: %s (%s), looking for people",
})

local function Readable(v) return v ~= nil and not (issecretvalue and issecretvalue(v)) end
local function Str(v) return type(v) == "string" and Readable(v) and v ~= "" and v or nil end
local function Int(v) return type(v) == "number" and Readable(v) and math.floor(v) or nil end
local function Call(name, ...)
    local api = C_LFGList and C_LFGList[name]
    if type(api) ~= "function" then return false end
    return pcall(api, ...)
end

-- ================================================================= the group quests of the log
-- { { id, title, zone } } of the quests in the log made for a group: an elite or group tag, or a
-- suggested group size. zone: the log's header above the quest (the zone it belongs to).
local function TagIsGroup(id)
    local f = C_QuestLog and C_QuestLog.GetQuestTagInfo
    if type(f) == "function" then
        local ok, info = pcall(f, id)
        if ok and type(info) == "table" then
            local n = Str(info.tagName) or ""
            if n:lower():find("lit") or n:lower():find("group") or n:lower():find("groupe") then return true end
            if Int(info.tagID) == 1 then return true end   -- "Group"
        end
    end
    if type(GetQuestTagInfo) == "function" then
        local ok, tagID, tagName = pcall(GetQuestTagInfo, id)
        if ok and (Int(tagID) == 1 or ((Str(tagName) or ""):lower():find("lit"))) then return true end
    end
    return false
end
function F.GroupQuests()
    local out = {}
    local n = 0
    if C_QuestLog and type(C_QuestLog.GetNumQuestLogEntries) == "function" then
        local ok, a = pcall(C_QuestLog.GetNumQuestLogEntries); n = ok and Int(a) or 0
    elseif type(GetNumQuestLogEntries) == "function" then
        local ok, a = pcall(GetNumQuestLogEntries); n = ok and Int(a) or 0
    end
    local zone
    for i = 1, math.min(n or 0, 120) do
        local title, header, id, group
        local info
        if C_QuestLog and type(C_QuestLog.GetInfo) == "function" then
            local ok, t = pcall(C_QuestLog.GetInfo, i); info = ok and type(t) == "table" and t or nil
        end
        if info then
            title, header, id, group = Str(info.title), info.isHeader == true, Int(info.questID), Int(info.suggestedGroup)
        elseif type(GetQuestLogTitle) == "function" then
            local ok, t, _, sg, isH, _, _, _, qid = pcall(GetQuestLogTitle, i)
            if ok then title, header, id, group = Str(t), isH == true, Int(qid), Int(sg) end
        end
        if header then zone = title
        elseif title and id then
            -- a dungeon's own quest is the dungeon cards' business
            local q = root.Q and root.Q[id]
            local dungeon = q and q.d
            if not dungeon and ((group or 0) > 1 or TagIsGroup(id)) then
                out[#out + 1] = { id = id, title = title, zone = zone }
            end
        end
    end
    return out
end

-- The questing activities of the game's finder: { cat, name, list = { activity } } for every
-- category that holds none of the guide's dungeons or raids.
local function ZoneCats()
    local map = F.BuildMap()
    local held = {}
    for _, ids in pairs(map.byKey or {}) do
        for _, id in ipairs(ids) do local a = map.acts[id]; if a then held[a.cat] = true end end
    end
    local out = {}
    for _, cat in ipairs(map.cats or {}) do
        if not held[cat] then
            local okI, info = Call("GetLfgCategoryInfo", cat)
            local name = okI and type(info) == "table" and Str(info.name) or tostring(cat)
            local list = {}
            for _, a in pairs(map.acts) do if a.cat == cat then list[#list + 1] = a end end
            table.sort(list, function(x, y) if x.lo ~= y.lo then return x.lo < y.lo end return x.name < y.name end)
            if #list > 0 then out[#out + 1] = { cat = cat, name = name, list = list } end
        end
    end
    return out
end
F.ZoneCats = ZoneCats

-- the activity of a zone name (the log's header), or nil
local function Fold(s) return F.Norm and F.Norm(s or "") or tostring(s or ""):lower() end
function F.ZoneActivity(zone)
    if not zone then return nil end
    local z = Fold(zone)
    if z == "" then return nil end
    for _, c in ipairs(ZoneCats()) do
        for _, a in ipairs(c.list) do
            local n = Fold(a.name)
            if n == z or (n ~= "" and (n:find(z, 1, true) or z:find(n, 1, true))) then return a end
        end
    end
    return nil
end
-- { [activityID] = { quest titles } } of the group quests in the log
function F.GroupQuestZones()
    local out = {}
    for _, q in ipairs(F.GroupQuests()) do
        local a = F.ZoneActivity(q.zone)
        if a then out[a.id] = out[a.id] or {}; table.insert(out[a.id], q.title) end
    end
    return out
end

-- ================================================================= the window
local CW, CH, GAP, PAD = 196, 112, 10, 16
local COLS = 4
local WW = PAD * 2 + COLS * CW + (COLS - 1) * GAP + 8
local win, ui = nil, {}

local function QuestCount(k)
    local d = root.D and root.D[k]
    if not (d and type(d.q) == "table") then return 0 end
    local ok, log = pcall(root.LogEntries or function() return {} end)
    if not ok or type(log) ~= "table" then return 0 end
    local n = 0
    for _, q in ipairs(d.q) do if log[q] then n = n + 1 end end
    return n
end
local function InRoute(k)
    local picked = root.PickedKeys and root.PickedKeys() or {}
    for _, x in ipairs(picked) do if x == k then return true end end
    return false
end
local function Levels(lo, hi)
    if not lo or lo <= 0 then return "" end
    if not hi or hi == lo then return string.format(L("Niveau %d"), lo) end
    return string.format(L("Niveaux %d-%d"), lo, hi)
end

-- the choice changed: the tab follows (a source that ignores the choice gives way to "level",
-- which searches the choice when there is one)
local function Changed()
    local src = F.Source()
    if (src == "mine" or src == "pick") and F.SwitchKeepChoice then F.SwitchKeepChoice("level") end
    if F.Render then F.Render() end
end

local function MakeCard(parent)
    local c = CreateFrame("Button", nil, parent)
    c:SetSize(CW, CH)
    root.Flat(c, root.Tok.panel, root.Tok.cardEdge)
    c.art = c:CreateTexture(nil, "ARTWORK"); c.art:SetPoint("TOPLEFT", 1, -1); c.art:SetPoint("BOTTOMRIGHT", -1, 1)
    c.shade = c:CreateTexture(nil, "ARTWORK", nil, 2); c.shade:SetPoint("TOPLEFT", 1, -1); c.shade:SetPoint("BOTTOMRIGHT", -1, 1)
    c.top = c:CreateTexture(nil, "ARTWORK", nil, 3); c.top:SetPoint("TOPLEFT", 1, -1); c.top:SetPoint("TOPRIGHT", -1, -1); c.top:SetHeight(30)
    c.top:SetColorTexture(0, 0, 0, 0.60)
    c.bot = c:CreateTexture(nil, "ARTWORK", nil, 3); c.bot:SetPoint("BOTTOMLEFT", 1, 1); c.bot:SetPoint("BOTTOMRIGHT", -1, 1); c.bot:SetHeight(42)
    c.bot:SetColorTexture(0, 0, 0, 0.80)
    c.name = S.Text(c, root.F.heading, C.fg, true); c.name:SetPoint("TOPLEFT", 10, -8); c.name:SetWidth(CW - 44)
    c.name:SetJustifyH("LEFT"); c.name:SetWordWrap(false)
    c.lvl = S.Text(c, root.F.label, C.text); c.lvl:SetPoint("BOTTOMLEFT", 10, 24); c.lvl:SetJustifyH("LEFT")
    c.badge = S.Text(c, root.F.label, C.gold or C.fg); c.badge:SetPoint("BOTTOMLEFT", 10, 8); c.badge:SetWidth(CW - 20)
    c.badge:SetJustifyH("LEFT"); c.badge:SetWordWrap(false)
    c.sel = c:CreateTexture(nil, "ARTWORK", nil, 5); c.sel:SetPoint("TOPLEFT", 1, -1); c.sel:SetPoint("BOTTOMRIGHT", -1, 1)
    c.sel:SetColorTexture(root.Tok.selFill[1], root.Tok.selFill[2], root.Tok.selFill[3], root.Tok.selFill[4]); c.sel:Hide()
    c.edge = root.Outline(c, root.Tok.accent, 0, "OVERLAY")
    c.box = c:CreateTexture(nil, "OVERLAY", nil, 1); c.box:SetSize(18, 18); c.box:SetPoint("TOPRIGHT", -8, -6)
    c.boxEdge = c:CreateTexture(nil, "OVERLAY", nil, 0); c.boxEdge:SetSize(20, 20); c.boxEdge:SetPoint("CENTER", c.box, "CENTER")
    c.boxEdge:SetColorTexture(1, 1, 1, 0.55)
    c.tick = c:CreateTexture(nil, "OVERLAY", nil, 2); c.tick:SetSize(12, 12); c.tick:SetPoint("CENTER", c.box, "CENTER")
    root.SetHDIcon(c.tick, "check", root.Tok.fg)
    c.hl = c:CreateTexture(nil, "HIGHLIGHT"); c.hl:SetAllPoints(); c.hl:SetColorTexture(1, 1, 1, 0.06)
    c:SetScript("OnClick", function(self)
        if self.off then return end
        if self.onToggle then self.onToggle() end
        PlaySound(SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or 856)
        Changed()
        if F.RenderPicker then F.RenderPicker() end
    end)
    c:SetScript("OnEnter", function(self) if self.tip then S.Tip(self, self.tip) end end)
    c:SetScript("OnLeave", function() S.HideTip() end)
    return c
end

-- a card: { name, lvl, badge, badgeColor, art = function(tex) | nil, on, off, onToggle, tip }
local function FillCard(c, it)
    c.name:SetText(it.name or "")
    c.lvl:SetText(it.lvl or "")
    c.badge:SetText(it.badge or "")
    local bc = it.badgeColor or C.gold or C.fg
    c.badge:SetTextColor(bc[1], bc[2], bc[3])
    if it.art then
        c.art:SetTexCoord(0, 1, 0, 1)
        pcall(it.art, c.art)
        c.art:Show()
    else
        -- a zone: a plain tile in the theme
        c.art:SetTexture(nil)
        c.art:SetColorTexture(0.10, 0.12, 0.10, 1)
        c.art:Show()
    end
    c.art:SetDesaturated(it.off and true or false)
    c.shade:SetColorTexture(0, 0, 0, it.on and 0.10 or (it.off and 0.60 or 0.30))
    c.sel:SetShown(it.on and true or false)
    c.edge(root.Tok.accent, it.on and 1 or 0)
    c.box:SetColorTexture(it.on and root.Tok.accent[1] or 0, it.on and root.Tok.accent[2] or 0, it.on and root.Tok.accent[3] or 0, it.on and 1 or 0.75)
    c.tick:SetShown(it.on and true or false)
    c.boxEdge:SetShown(not it.off)
    c.box:SetShown(not it.off)
    c.off, c.onToggle, c.tip = it.off, it.onToggle, it.tip
    c:SetAlpha(it.off and 0.65 or 1)
end

-- the cards of a tab, in sections: { { title, items } }
local function Sections(tab)
    local lv = Int(UnitLevel("player")) or 1
    if tab == "zones" then
        local quests = F.GroupQuestZones()
        local secs = {}
        F.selZone = F.selZone or {}
        for _, cat in ipairs(ZoneCats()) do
            local items = {}
            for _, a in ipairs(cat.list) do
                local q = quests[a.id]
                items[#items + 1] = {
                    name = a.name, lvl = Levels(a.lo, a.hi),
                    badge = q and (#q == 1 and string.format(L("Ta quête : %s"), q[1]) or string.format(L("Tes quêtes : %s"), table.concat(q, ", "))) or nil,
                    on = F.selZone[a.id] == true, mine = q ~= nil,
                    onToggle = function() F.selZone[a.id] = (not F.selZone[a.id]) or nil end,
                    tip = { a.name, Levels(a.lo, a.hi), q and table.concat(q, ", ") or nil, L("Clic : cocher ou décocher") },
                }
            end
            -- your quests' zones first
            table.sort(items, function(x, y) if (x.mine and 1 or 0) ~= (y.mine and 1 or 0) then return x.mine end return false end)
            secs[#secs + 1] = { cat.name, items }
        end
        return secs
    end
    local mine, rest = {}, {}
    for _, e in ipairs(WP.GroupInstances and WP.GroupInstances(tab == "raid" and "raid" or "dg") or {}) do
        local k = e[1]
        local matched = F.Matched(k)
        local nq = QuestCount(k)
        local route = InRoute(k)
        local badge, bcol
        if route and nq > 0 then badge = L("Ta route") .. "  ·  " .. string.format(L("Tes quêtes : %d"), nq)
        elseif route then badge = L("Ta route")
        elseif nq > 0 then badge = string.format(L("Tes quêtes : %d"), nq) end
        -- what it has for your gear: after the route and the quests ("Ta route · 3 BiS")
        local gtxt = root.DungeonGearText and root.DungeonGearText(k, true)
        if gtxt then badge = badge and (badge .. "  ·  " .. gtxt) or gtxt end
        if not matched then badge, bcol = L("Pas dans la recherche de groupe du jeu"), C.muted end
        local it = {
            name = e[2], lvl = Levels(e[3], e[4]), badge = badge, badgeColor = bcol,
            art = function(tex) if root.DungeonArt then root.DungeonArt(tex, k) end end,
            on = F.sel and F.sel[k] == true, off = not matched,
            onToggle = function() F.sel = F.sel or {}; F.sel[k] = (not F.sel[k]) or nil end,
            tip = { e[2], Levels(e[3], e[4]), badge, matched and L("Clic : cocher ou décocher") or nil },
        }
        if lv >= e[3] - 4 and lv <= e[4] + 1 then mine[#mine + 1] = it else rest[#rest + 1] = it end
    end
    local secs = {}
    if #mine > 0 then secs[#secs + 1] = { L("Pour ton niveau"), mine } end
    if #rest > 0 then secs[#secs + 1] = { L("Autres niveaux"), rest } end
    return secs
end

local function PickedCount()
    local n = 0
    for _ in pairs(F.sel or {}) do n = n + 1 end
    for _ in pairs(F.selZone or {}) do n = n + 1 end
    return n
end

function F.RenderPicker()
    if not (win and win:IsShown()) then return end
    ui.tabs:Update()
    local tab = ui.tab or "dg"
    local secs = Sections(tab)
    local y = 0
    local used = 0
    ui.heads = ui.heads or {}
    ui.cards = ui.cards or {}
    local hi = 0
    for _, sec in ipairs(secs) do
        hi = hi + 1
        local h = ui.heads[hi]
        if not h then h = S.Text(ui.content, root.F.label, C.muted, true); ui.heads[hi] = h end
        h:SetText(sec[1]); h:ClearAllPoints(); h:SetPoint("TOPLEFT", 0, -y); h:Show()
        y = y + 22
        for i, it in ipairs(sec[2]) do
            used = used + 1
            local c = ui.cards[used]
            if not c then c = MakeCard(ui.content); ui.cards[used] = c end
            FillCard(c, it)
            local col, row = (i - 1) % COLS, math.floor((i - 1) / COLS)
            c:ClearAllPoints(); c:SetPoint("TOPLEFT", col * (CW + GAP), -(y + row * (CH + GAP)))
            c:Show()
        end
        y = y + math.ceil(#sec[2] / COLS) * (CH + GAP) + 8
    end
    for i = hi + 1, #ui.heads do ui.heads[i]:Hide() end
    for i = used + 1, #ui.cards do ui.cards[i]:Hide() end
    ui.empty:SetShown(#secs == 0)
    if #secs == 0 then
        ui.empty:SetText(F.BuildMap().ok and L("Aucune activité de quête ou de zone dans la recherche de groupe du jeu.")
            or L("La recherche de groupe du jeu n'a pas encore répondu : rouvre dans un instant."))
    end
    ui.content:SetHeight(math.max(1, y))
    ui.sa:SetContentHeight(y)
    local n = PickedCount()
    ui.count:SetText(n == 0 and L("Rien de choisi : tout ce qui est à ton niveau.") or (n == 1 and L("1 choisi") or string.format(L("%d choisis"), n)))
end

local function Build()
    if win then return win end
    win = S.Window("WLHelperFinderPick", WW, 600, L("Choisir où chercher"), L("Clique les cartes à chercher, puis Chercher."),
        WLWritsDB, "finderPickPos", { header = 44, noHome = true, strata = "DIALOG" })
    local top = win.ContentTop and win:ContentTop() or 44
    ui.tab = "dg"
    ui.tabs = S.Segmented(win, { { "dg", L("Donjons") }, { "raid", L("Raids") }, { "zones", L("Quêtes et zones") } },
        function() return ui.tab end, function(v) ui.tab = v; F.RenderPicker() end, 28)
    ui.tabs:SetPoint("TOPLEFT", PAD, -(top + 12))
    ui.sa = S.ScrollArea(win)
    ui.sa:SetPoint("TOPLEFT", win, "TOPLEFT", PAD, -(top + 12 + 28 + 12))
    ui.sa:SetPoint("BOTTOMRIGHT", win, "BOTTOMRIGHT", -PAD + 4, 56)
    ui.content = ui.sa.child
    ui.content:SetWidth(COLS * CW + (COLS - 1) * GAP)
    ui.empty = S.Text(ui.content, root.F.body, C.muted); ui.empty:SetPoint("TOPLEFT", 0, -4); ui.empty:SetWidth(COLS * CW)
    ui.empty:SetJustifyH("LEFT")
    -- the foot: how many picked, clear, search
    ui.count = S.Text(win, root.F.body, C.text); ui.count:SetPoint("BOTTOMLEFT", PAD, 22)
    ui.go = S.Button(win, L("Chercher"), 120, 28, "primary", function()
        win:Hide()
        if F.Search then F.Search() end
        if F.Render then F.Render() end
    end, { L("Chercher"), L("Clic : chercher ces donjons dans la recherche de groupe du jeu") })
    ui.go:SetPoint("BOTTOMRIGHT", -PAD, 16)
    if ui.go.SetIcon then ui.go:SetIcon("search") end
    ui.clear = S.Button(win, L("Effacer"), 0, 28, "ghost", function()
        F.sel, F.selZone = {}, {}
        Changed(); F.RenderPicker()
    end)
    ui.clear:SetPoint("RIGHT", ui.go, "LEFT", -8, 0)
    win:SetScript("OnShow", function() F.RenderPicker() end)
    win:Hide()
    return win
end

function F.OpenPicker(tab)
    Build()
    if tab then ui.tab = tab end
    F.BuildMap()
    win:Show(); win:Raise()
    F.RenderPicker()
end
function F.PickerWindow() return win end
function F._PickerUI() return ui end
