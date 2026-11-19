-- Writs/Best.lua: "Meilleur pour toi" ("/wlh bis [level]"). For each slot, the best pieces you can
-- wear (at your level, or the level typed) for your class and spec, ranked by WL Helper Gear with
-- your real stats, talents and hit caps (WLHelperGear.Best), with the gain over what you wear and
-- where each piece comes from. Raids are left out until they open; PvP pieces point to "/wlh pvp".
-- Computed, never copied from a guide's list: Forever changed many items, so a list made for
-- Classic is often wrong here.
local ADDON, root = ...
local ns = root.Writs
local WP = ns.WP
local L = ns.L

local Best = {}
WP.Best = Best

ns.AddEnglish({
    ["Meilleur pour toi (%s, niveau %d)"] = "Best for you (%s, level %d)",
    ["Meilleur pour toi : WL Helper Gear n'est pas chargé (Échap > AddOns)."] = "Best for you: WL Helper Gear is not loaded (Esc > AddOns).",
    ["déjà équipé"] = "already worn",
    ["emplacement vide"] = "empty slot",
    ["puis %s"] = "then %s",
    ["PvP, honneur (/wlh pvp)"] = "PvP, honor (/wlh pvp)",
    ["Calculé par WL Helper Gear pour ta spé, avec tes stats et tes plafonds de toucher ; raids exclus tant qu'ils ne sont pas ouverts. « /wlh bis 60 » : au niveau 60."] =
        "Worked out by WL Helper Gear for your spec, with your stats and hit caps; raids left out until they open. \"/wlh bis 60\": at level 60.",
    ["Certaines pièces ne sont pas encore lues par le jeu : retape la commande dans un instant."] =
        "Some pieces are not read by the game yet: type the command again in a moment.",
    ["Tête"] = "Head", ["Cou"] = "Neck", ["Épaules"] = "Shoulders", ["Dos"] = "Back", ["Torse"] = "Chest",
    ["Poignets"] = "Wrists", ["Mains"] = "Hands", ["Taille"] = "Waist", ["Jambes"] = "Legs", ["Pieds"] = "Feet",
    ["Anneau"] = "Ring", ["Bijou"] = "Trinket", ["Deux mains"] = "Two-Hand", ["Main droite"] = "Main Hand",
    ["Main gauche"] = "Off Hand", ["Bouclier"] = "Shield", ["À distance"] = "Ranged",
})

-- WL Helper Gear's sections, in the character sheet's order, with their words
Best.SECTIONS = {
    { "Head", "Tête" }, { "Neck", "Cou" }, { "Shoulder", "Épaules" }, { "Back", "Dos" }, { "Chest", "Torse" },
    { "Wrist", "Poignets" }, { "Hands", "Mains" }, { "Waist", "Taille" }, { "Legs", "Jambes" }, { "Feet", "Pieds" },
    { "Ring", "Anneau" }, { "Trinket", "Bijou" }, { "Two-Hand", "Deux mains" }, { "Main Hand", "Main droite" },
    { "Off Hand", "Main gauche" }, { "Shield", "Bouclier" }, { "Ranged", "À distance" },
}

local function Plain(v)
    if v == nil or (issecretvalue and issecretvalue(v)) then return nil end
    return v
end

-- the place a piece comes from, in short: the data's English source, PvP pieces to the PvP guide
function Best.Source(src)
    src = type(src) == "string" and src or ""
    if src:find("^PvP") then return L("PvP, honneur (/wlh pvp)") end
    src = src:gsub("^~", "")
    return src
end

-- { { word, rows = { { id, name, source, pct, worn, empty } } } } for the slots your class uses;
-- second value: true when some piece could not be compared yet
-- mode: nil / "now" (raids left out), "pre" (raids and PvP left out: the pre-raid set), "bis"
-- (raids in), "pvp" (only PvP pieces: honor ranks and battleground reputations)
local function IsPvP(src) return type(src) == "string" and src:find("^PvP") ~= nil end
function Best.Rows(level, top, mode)
    local G = _G.WLHelperGear
    if not (G and G.Best) then return nil end
    if WP.SyncGearSpec then pcall(WP.SyncGearSpec) end
    top = top or 3
    local show = { raid = false }
    if mode == "pre" then show = { raid = false, pvp = false }
    elseif mode == "bis" then show = {} end
    local ask = mode == "pvp" and 40 or top
    local out, pending = {}, false
    for _, s in ipairs(Best.SECTIONS) do
        local ok, list = pcall(G.Best, s[1], { level = level, top = ask, show = show })
        if ok and type(list) == "table" and mode == "pvp" then
            local keep = {}
            for _, it in ipairs(list) do
                if IsPvP(it.source) and #keep < top then keep[#keep + 1] = it end
            end
            list = keep
        end
        if ok and type(list) == "table" and #list > 0 then
            local rows = {}
            for _, it in ipairs(list) do
                local r = { id = it.id, name = it.name, source = Best.Source(it.source), raw = it.source, quality = it.quality }
                if G.Compare then
                    local okC, c = pcall(G.Compare, it.id, level)
                    if okC and type(c) == "table" then
                        r.pct, r.worn, r.empty = tonumber(c.pct), c.equipped == true, c.empty == true
                        if c.unknown then pending = true end
                    else pending = true end
                end
                rows[#rows + 1] = r
            end
            out[#out + 1] = { word = s[2], rows = rows }
        end
    end
    return out, pending
end

local function NameOf(r)
    local n
    if GetItemInfo then
        local ok, name, link = pcall(GetItemInfo, r.id)
        if ok then n = Plain(link) or Plain(name) end
    end
    return type(n) == "string" and n or ("[" .. tostring(r.name or r.id) .. "]")
end

function Best.Lines(level)
    local lvl = tonumber(level) or tonumber(Plain(UnitLevel("player"))) or 60
    lvl = math.max(1, math.min(60, math.floor(lvl)))
    local G = _G.WLHelperGear
    if not (G and G.Best) then return { L("Meilleur pour toi : WL Helper Gear n'est pas chargé (Échap > AddOns).") } end
    local spec = "?"
    if G.Spec then
        local ok, _, _, name = pcall(G.Spec)
        if ok and type(name) == "string" then spec = name end
    end
    local out = { string.format(L("Meilleur pour toi (%s, niveau %d)"), spec, lvl) }
    local rows, pending = Best.Rows(lvl, 3)
    for _, slot in ipairs(rows or {}) do
        local r = slot.rows[1]
        local tag
        if r.worn then tag = L("déjà équipé")
        elseif r.empty then tag = L("emplacement vide")
        elseif r.pct then tag = string.format("%+d %%", math.floor(r.pct + 0.5)) end
        local line = L(slot.word) .. " : " .. NameOf(r) .. (tag and (" " .. tag) or "") .. (r.source ~= "" and (" - " .. r.source) or "")
        local more = {}
        for i = 2, #slot.rows do more[#more + 1] = NameOf(slot.rows[i]) end
        if #more > 0 then line = line .. " ; " .. string.format(L("puis %s"), table.concat(more, ", ")) end
        out[#out + 1] = line
    end
    if pending then out[#out + 1] = L("Certaines pièces ne sont pas encore lues par le jeu : retape la commande dans un instant.") end
    out[#out + 1] = L("Calculé par WL Helper Gear pour ta spé, avec tes stats et tes plafonds de toucher ; raids exclus tant qu'ils ne sont pas ouverts. « /wlh bis 60 » : au niveau 60.")
    return out
end

function Best.Print(lvl)
    for _, l in ipairs(Best.Lines(lvl)) do WP.Print(l) end
end
-- "/wlh bis": the window (on the pre-BiS tab with a level of 60 typed); "/wlh bis chat [level]": the chat
function Best.Show(rest)
    rest = rest and tostring(rest) or ""
    local lvl = tonumber((rest:match("(%d+)")))
    if rest:lower():find("chat") or not (Best.Toggle and ns.S and ns.S.Window) then return Best.Print(lvl) end
    Best.Toggle(lvl and (lvl >= 60 and "pre" or "now") or nil, true)
end

-- ---------------------------------------------------------------- the window
-- "Meilleur équipement": the same ranking in a window, one block per slot, its 3 best pieces with
-- where each comes from and what it adds over what you wear. Tabs: for your level now; the pre-raid
-- set at 60 (no raid, no PvP); the full set at 60 (raids in); PvP at 60 (honor ranks and the
-- battleground reputations). Shift-click a piece: its link in the chat.
ns.AddEnglish({
    ["Meilleur équipement"] = "Best gear",
    ["Pour ton niveau"] = "For your level",
    ["Pré-BiS 60"] = "Pre-BiS 60",
    ["BiS 60 (raids)"] = "BiS 60 (raids)",
    ["PvP 60"] = "PvP 60",
    ["Ta spé : %s"] = "Your spec: %s",
    ["Les meilleures pièces à ton niveau (%d), raids exclus."] = "The best pieces at your level (%d), raids left out.",
    ["Le pré-BiS : les meilleures pièces de niveau 60 hors raid et hors PvP (donjons, quêtes, métiers, réputations)."] =
        "Pre-BiS: the best level 60 pieces outside raids and PvP (dungeons, quests, crafts, reputations).",
    ["Le BiS au niveau 60, raids compris (Onyxia, Sommet d'Hyjal, Barrow Deeps : ils ouvrent sur Forever le 9 décembre 2026, leurs pièces arrivent dans la liste au fil des données)."] =
        "BiS at level 60, raids included (Onyxia, Hyjal Summit, Barrow Deeps: they open on Forever on December 9, 2026; their pieces join the list as the data comes in).",
    ["Les pièces PvP (rangs d'honneur, réputations des champs de bataille), classées pour ta spé avec les mêmes poids que le PvE."] =
        "PvP pieces (honor ranks, battleground reputations), ranked for your spec with the same weights as PvE.",
    ["équipé"] = "worn",
    ["vide"] = "empty",
    ["Maj-clic : le lien dans la discussion"] = "Shift-click: its link in the chat",
    ["WL Helper Gear n'est pas chargé"] = "WL Helper Gear is not loaded",
    ["Active-le dans Échap > AddOns : c'est lui qui classe les pièces pour ta spé."] =
        "Turn it on in Esc > AddOns: it ranks the pieces for your spec.",
    ["Rien à proposer ici"] = "Nothing to suggest here",
    ["Aucune pièce de ce type n'est connue pour ta classe."] = "No piece of this kind is known for your class.",
    ["Certaines pièces ne sont pas encore lues par le jeu : rouvre l'onglet dans un instant."] =
        "Some pieces are not read by the game yet: open the tab again in a moment.",
})

local S, C = ns.S, ns.S and ns.S.C
local INSET = 16
local MODES = { { "now", "Pour ton niveau" }, { "pre", "Pré-BiS 60" }, { "bis", "BiS 60 (raids)" }, { "pvp", "PvP 60" } }
local INTRO = {
    pre = "Le pré-BiS : les meilleures pièces de niveau 60 hors raid et hors PvP (donjons, quêtes, métiers, réputations).",
    bis = "Le BiS au niveau 60, raids compris (Onyxia, Sommet d'Hyjal, Barrow Deeps : ils ouvrent sur Forever le 9 décembre 2026, leurs pièces arrivent dans la liste au fil des données).",
    pvp = "Les pièces PvP (rangs d'honneur, réputations des champs de bataille), classées pour ta spé avec les mêmes poids que le PvE.",
}
local win
local mode = "now"
local heads, rows = {}, {}

local function MyLevel()
    local l = tonumber(Plain(UnitLevel and UnitLevel("player"))) or 60
    return math.max(1, math.min(60, math.floor(l)))
end
local function LevelOf(m) return m == "now" and MyLevel() or 60 end

local function SpecName()
    local G = _G.WLHelperGear
    if G and G.Spec then
        local ok, _, _, name = pcall(G.Spec)
        if ok and type(name) == "string" then return name end
    end
    return nil
end

local function ItemName(r)
    local n
    if GetItemInfo then
        local ok, name = pcall(GetItemInfo, r.id)
        if ok then n = Plain(name) end
    end
    return type(n) == "string" and n or tostring(r.name or r.id)
end

local function MakeRow(parent)
    local row = S.ListRow(parent, {
        onClick = function(self)
            local r = self.item
            if not r then return end
            if IsModifiedClick and IsModifiedClick("CHATLINK") and GetItemInfo then
                local ok, _, link = pcall(GetItemInfo, r.id)
                if ok and Plain(link) and ChatEdit_InsertLink then ChatEdit_InsertLink(link) end
            end
        end,
    })
    row.valueW = 72
    return row
end

local function Fill()
    if not win then return end
    local lvl = LevelOf(mode)
    local spec = SpecName()
    win.sub:SetText(spec and string.format(L("Ta spé : %s"), spec) or "")
    win.intro:SetText(mode == "now" and string.format(L("Les meilleures pièces à ton niveau (%d), raids exclus."), lvl) or L(INTRO[mode]))
    local list, pending = Best.Rows(lvl, 3, mode)
    local W = math.floor((win:GetWidth() or 614) - 2 * INSET - 8)
    local child = win.list.child
    child:SetWidth(W)
    local y, h, k = 0, 0, 0
    for _, hd in ipairs(heads) do hd:Hide() end
    for _, r in ipairs(rows) do r:Hide() end
    for _, slot in ipairs(list or {}) do
        h = h + 1
        local hd = heads[h] or S.SectionHeader(child, L(slot.word), #slot.rows, nil, nil, true); heads[h] = hd
        hd:Set(L(slot.word), #slot.rows)
        hd:ClearAllPoints(); hd:SetPoint("TOPLEFT", 0, -y); hd:SetWidth(W); hd:Show()
        y = y + 32 + 4
        for i, it in ipairs(slot.rows) do
            k = k + 1
            local row = rows[k] or MakeRow(child); rows[k] = row
            row.item = it
            local value, vcol
            if it.worn then value, vcol = L("équipé"), C.ok
            elseif it.empty then value, vcol = L("vide"), C.muted
            elseif it.pct then
                local p = math.floor(it.pct + 0.5)
                value, vcol = string.format("%+d %%", p), p > 0 and C.ok or C.muted
            end
            row:Set({ rank = i, icon = S.ItemIcon(it.id), name = ItemName(it), nameColor = S.QualityColor(it.id),
                detail = it.source ~= "" and it.source or nil, value = value,
                tip = { ItemName(it), it.source ~= "" and it.source or nil, L("Maj-clic : le lien dans la discussion") } })
            if value and vcol then row.value:SetTextColor(vcol[1], vcol[2], vcol[3]) end
            row:ClearAllPoints(); row:SetPoint("TOPLEFT", 0, -y); row:SetWidth(W)
            local rh = row:Fit(W)
            row:SetHeight(rh)
            row:Show()
            y = y + rh + 2
        end
        y = y + 10
    end
    local G = _G.WLHelperGear
    if not (G and G.Best) then
        win.empty:Set("gear", L("WL Helper Gear n'est pas chargé"), L("Active-le dans Échap > AddOns : c'est lui qui classe les pièces pour ta spé."))
    else
        win.empty:Set("gear", L("Rien à proposer ici"), L("Aucune pièce de ce type n'est connue pour ta classe."))
    end
    win.empty:SetShown(h == 0)
    win.list:SetShown(h > 0)
    win.pending:SetShown(pending == true)
    win.listH = y
    win.Layout()
end
Best.Fill = Fill

local function Build()
    win = S.Window("WLHelperBest", (root.WinSize and root.WinSize("panel")) or 614, 560, L("Meilleur équipement"), nil,
        WLWritsDB, "bestPos", { header = S.HEADER_H, minH = 300, size = "panel" })
    win.OnResize = function() Fill() end
    local top = win:ContentTop()
    win.tabs = S.Tabs(win, (function()
        local t = {}
        for _, m in ipairs(MODES) do t[#t + 1] = { m[1], L(m[2]) } end
        return t
    end)(), function() return mode end, function(m) mode = m; win.list:ScrollTo(0, true); Fill(); win.tabs:Paint() end)
    win.tabs:SetPoint("TOPLEFT", 0, -top); win.tabs:SetPoint("TOPRIGHT", 0, -top)
    win.sub = S.Text(win, S.F.label, C.muted); win.sub:SetJustifyH("LEFT")
    win.intro = S.Text(win, S.F.body, C.text); win.intro:SetJustifyH("LEFT"); win.intro:SetJustifyV("TOP")
    win.pending = S.Text(win, S.F.label, C.warn); win.pending:SetJustifyH("LEFT")
    win.pending:SetText(L("Certaines pièces ne sont pas encore lues par le jeu : rouvre l'onglet dans un instant."))
    win.list = S.ScrollArea(win)
    win.empty = S.EmptyState(win, "gear", "", "")
    function win.Layout()
        local W = math.floor((win:GetWidth() or 614) - 2 * INSET)
        local y = top + S.TABS_H + 12
        win.sub:ClearAllPoints(); win.sub:SetPoint("TOPLEFT", INSET, -y)
        local sh = win.sub:GetText() ~= "" and S.FitText(win.sub, 1, W, win) or 0
        if sh > 0 then y = y + sh + 4 end
        win.intro:ClearAllPoints(); win.intro:SetPoint("TOPLEFT", INSET, -y)
        y = y + S.FitText(win.intro, 0, W, win) + 8
        if win.pending:IsShown() then
            win.pending:ClearAllPoints(); win.pending:SetPoint("TOPLEFT", INSET, -y)
            y = y + S.FitText(win.pending, 0, W, win) + 8
        end
        win.list:ClearAllPoints()
        win.list:SetPoint("TOPLEFT", INSET, -y); win.list:SetPoint("BOTTOMRIGHT", -INSET + 8, 12)
        win.list:SetContentHeight(win.listH or 0)
        win.empty:ClearAllPoints(); win.empty:SetPoint("TOP", win, "TOP", 0, -(y + 24))
        if win.empty.Fit then win.empty:Fit() end
    end
    win:SetScript("OnShow", function() Fill(); win.tabs:Paint() end)
    win:Hide()
end

-- Best.Toggle([mode [, show]]): opens on that tab (or the last one), closes when open and no tab asked
function Best.Toggle(m, show)
    if not win then Build() end
    if m then mode = m end
    if win:IsShown() and not show and not m then win:Hide(); return end
    win:Show(); win:Raise()
    Fill(); win.tabs:Paint()
end
