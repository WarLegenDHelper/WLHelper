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
-- pieces of the other side (its battleground reputations, its vendors), and pieces of raids and
-- world bosses the data does not file as raid loot: left out of the lists that should not have them
local SIDE = {
    Alliance = { "League of Arathor", "Silverwing", "Stormpike", "Theramore Expeditionary", "Illiyana Moonblaze", "%(Alliance%)" },
    Horde = { "Defilers", "Warsong Outriders", "Frostwolf", "Darkspear Raiders", "Kelm Hargunth", "%(Horde%)" },
}
local RAIDLIKE = { "Four Horsemen", "Naxxramas", "Molten Core", "Blackwing", "Onyxia", "Hyjal Summit", "Barrow Deeps",
    "Zul'Gurub", "Ahn'Qiraj", "Taerar", "Ysondre", "Emeriss", "Lethon", "Azuregos", "Kazzak" }
local function Has(src, list)
    for _, p in ipairs(list) do if src:find(p) then return true end end
    return false
end
function Best.Keep(src, mode, faction)
    src = type(src) == "string" and src or ""
    local other = faction == "Horde" and SIDE.Alliance or faction == "Alliance" and SIDE.Horde or nil
    if other and Has(src, other) then return false end
    if mode ~= "bis" and Has(src, RAIDLIKE) then return false end
    if mode == "pvp" then return IsPvP(src) end
    if mode == "pre" and IsPvP(src) then return false end
    return true
end
function Best.Rows(level, top, mode)
    local G = _G.WLHelperGear
    if not (G and G.Best) then return nil end
    if WP.SyncGearSpec then pcall(WP.SyncGearSpec) end
    top = top or 3
    local show = { raid = false }
    if mode == "pre" then show = { raid = false, pvp = false }
    elseif mode == "bis" then show = {} end
    local faction = UnitFactionGroup and Plain((UnitFactionGroup("player"))) or nil
    local out, pending = {}, false
    for _, s in ipairs(Best.SECTIONS) do
        local ok, list = pcall(G.Best, s[1], { level = level, top = mode == "pvp" and 40 or top + 8, show = show })
        if ok and type(list) == "table" then
            local keep, seen = {}, {}
            for _, it in ipairs(list) do
                if #keep < top and not seen[it.id] and Best.Keep(it.source, mode, faction) then
                    seen[it.id] = true; keep[#keep + 1] = it
                end
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
            out[#out + 1] = { word = s[2], key = s[1], rows = rows }
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
-- "Meilleur équipement": a table of your best piece per slot (armor, jewelry, weapons) with what it
-- adds over what you wear and where it drops, the other picks folded under it; above it, how many
-- of them you wear and "À faire ensuite": the dungeons, crafts and vendors that give the most of
-- your missing pieces, a click opens the dungeon's guide. Tabs: for your level now; the pre-raid set
-- at 60 (no raid, no PvP); the full set at 60 (raids in); PvP at 60. Filters: all, to get, in bags.
-- The ranking is WL Helper Gear's (your stats, talents and caps), never another addon's list.
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
    ["Tout"] = "All", ["À obtenir"] = "To get", ["Dans les sacs"] = "In bags",
    ["%d/%d portés"] = "%d/%d worn",
    ["%d à obtenir · %d dans tes sacs"] = "%d to get · %d in your bags",
    ["À faire ensuite"] = "Next",
    ["Armure"] = "Armor", ["Bijoux"] = "Jewelry", ["Armes"] = "Weapons",
    ["Anneau %d"] = "Ring %d", ["Bijou %d"] = "Trinket %d",
    ["Équipé"] = "Worn", ["Dans tes sacs"] = "In your bags", ["vide"] = "empty",
    ["%d choix"] = "%d picks",
    ["Niv. %d"] = "Lvl %d",
    ["%s : %d pièces"] = "%s: %d pieces",
    ["Quête : %s"] = "Quest: %s",
    ["Ouvrir le guide"] = "Open the guide",
    ["Clic : ouvrir le guide de ce donjon"] = "Click: open this dungeon's guide",
    ["Maj-clic : le lien dans la discussion"] = "Shift-click: its link in the chat",
    ["Clic : voir les autres choix"] = "Click: see the other picks",
    ["WL Helper Gear n'est pas chargé"] = "WL Helper Gear is not loaded",
    ["Active-le dans Échap > AddOns : c'est lui qui classe les pièces pour ta spé."] =
        "Turn it on in Esc > AddOns: it ranks the pieces for your spec.",
    ["Rien à proposer ici"] = "Nothing to suggest here",
    ["Aucune pièce de ce type n'est connue pour ta classe."] = "No piece of this kind is known for your class.",
    ["Rien dans ce filtre"] = "Nothing in this filter",
    ["Change de filtre pour voir les autres emplacements."] = "Pick another filter to see the other slots.",
    ["Certaines pièces ne sont pas encore lues par le jeu : rouvre l'onglet dans un instant."] =
        "Some pieces are not read by the game yet: open the tab again in a moment.",
})

local S, C = ns.S, ns.S and ns.S.C
local INSET = 16
local SLOT_W, ICON, ROW_H, ALT_H = 92, 20, 40, 34
local MODES = { { "now", "Pour ton niveau" }, { "pre", "Pré-BiS 60" }, { "bis", "BiS 60 (raids)" }, { "pvp", "PvP 60" } }
local INTRO = {
    pre = "Le pré-BiS : les meilleures pièces de niveau 60 hors raid et hors PvP (donjons, quêtes, métiers, réputations).",
    bis = "Le BiS au niveau 60, raids compris (Onyxia, Sommet d'Hyjal, Barrow Deeps : ils ouvrent sur Forever le 9 décembre 2026, leurs pièces arrivent dans la liste au fil des données).",
    pvp = "Les pièces PvP (rangs d'honneur, réputations des champs de bataille), classées pour ta spé avec les mêmes poids que le PvE.",
}
local GROUPS = {
    { "Armure", { Head = 1, Shoulder = 2, Back = 3, Chest = 4, Wrist = 5, Hands = 6, Waist = 7, Legs = 8, Feet = 9 } },
    { "Bijoux", { Neck = 1, Ring = 2, Trinket = 3 } },
    { "Armes", { ["Two-Hand"] = 1, ["Main Hand"] = 2, ["Off Hand"] = 3, Shield = 4, Ranged = 5 } },
}
local PAIRS = { Ring = "Anneau %d", Trinket = "Bijou %d" }

local win
local mode, filter = "now", "all"
local open = {}            -- [slot label] = true: its other picks shown

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

local function Info(id)
    if not GetItemInfo then return nil end
    local ok, name, link, _, _, minLevel = pcall(GetItemInfo, id)
    if not ok then return nil end
    return Plain(name), Plain(link), tonumber(Plain(minLevel))
end
local function BagCount(id)
    local f = (C_Item and C_Item.GetItemCount) or GetItemCount
    if not f then return 0 end
    local ok, n = pcall(f, id)
    n = ok and tonumber(Plain(n)) or 0
    return n or 0
end

-- where a piece comes from, read from the data's English source: kind, place, who
-- ("Drop: Highlord Omokk (Blackrock Spire)" -> "dungeon", "Blackrock Spire", "Highlord Omokk")
function Best.Place(src)
    src = type(src) == "string" and src:gsub("^~", "") or ""
    local who, where = src:match("^Drop: (.-) %((.-)%)$")
    if who then return "dungeon", where, who end
    where = src:match("^Drop: (.+)$")
    if where then return "dungeon", where, nil end
    local prof = src:match("^Crafted: (.+)$")
    if prof then return "craft", prof, nil end
    local q = src:match("^Quest: (.+)$")
    if q then return "quest", q, nil end
    who, where = src:match("^Vendor: (.-) %((.-)%)$")
    if who then return "vendor", where, who end
    local fac = src:match("^Reputation vendor: (.+)$")
    if fac then return "rep", fac, nil end
    return nil
end
-- the guide's dungeon for an English dungeon name (Blackrock Spire: the lower one, where most of
-- the pre-raid pieces drop), or nil
local function DungeonKey(name)
    if type(name) ~= "string" or not root.D then return nil end
    if name == "Blackrock Spire" then name = "Lower Blackrock Spire" end
    for k, d in pairs(root.D) do
        if d.n == name and not d.cq then return k end
    end
    return nil
end

-- the slots of a tab: { group, label, best, alts, state } (state: "worn", "bag", "get")
local function Slots(list)
    local out = {}
    for gi, g in ipairs(GROUPS) do
        local here = {}
        for _, sec in ipairs(list or {}) do
            local order = g[2][sec.key]
            if order then
                local n = PAIRS[sec.key] and 2 or 1
                for k = 1, n do
                    local best = sec.rows[k]
                    if best then
                        local alts = {}
                        for i = n + 1, #sec.rows do alts[#alts + 1] = sec.rows[i] end
                        local label = n == 2 and string.format(L(PAIRS[sec.key]), k) or L(sec.word)
                        local state = best.worn and "worn" or (BagCount(best.id) > 0 and "bag") or "get"
                        here[#here + 1] = { group = gi, label = label, best = best, alts = alts, state = state, order = order * 10 + k }
                    end
                end
            end
        end
        table.sort(here, function(a, b) return a.order < b.order end)
        for _, s in ipairs(here) do out[#out + 1] = s end
    end
    return out
end

-- "À faire ensuite": the places giving the most of the pieces still to get, best first (3)
local function NextPlaces(slots)
    local by, order = {}, {}
    for _, s in ipairs(slots) do
        if s.state == "get" then
            local kind, place, who = Best.Place(s.best.raw)
            if kind and place and place ~= "" then
                local key = kind .. ":" .. place
                local e = by[key]
                if not e then
                    e = { kind = kind, place = place, slots = {}, who = {}, gain = 0, n = 0 }
                    if kind == "dungeon" then e.dkey = DungeonKey(place) end
                    by[key] = e; order[#order + 1] = e
                end
                e.n = e.n + 1
                e.slots[#e.slots + 1] = s.label
                if who and not e.who[who] then e.who[who] = true; e.who[#e.who + 1] = who end
                e.gain = e.gain + math.max(0, s.best.pct or 0)
            end
        end
    end
    table.sort(order, function(a, b)
        if a.n ~= b.n then return a.n > b.n end
        if a.gain ~= b.gain then return a.gain > b.gain end
        return a.place < b.place
    end)
    local out = {}
    for i = 1, math.min(3, #order) do out[i] = order[i] end
    return out
end

local function PlaceTitle(e)
    if e.kind == "dungeon" then return e.dkey and root.DName and root.DName(e.dkey) or e.place end
    if e.kind == "quest" then return string.format(L("Quête : %s"), e.place) end
    return e.place
end

-- ---------------------------------------------------------------- rows
local function ShowItemTip(self, id, extra)
    if not id then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    local ok = pcall(GameTooltip.SetItemByID, GameTooltip, id)
    if not ok then GameTooltip:SetText(tostring(id)) end
    for _, l in ipairs(extra or {}) do GameTooltip:AddLine(l, C.hint[1], C.hint[2], C.hint[3], true) end
    GameTooltip:Show()
end

local function MakeRow(parent)
    local r = CreateFrame("Button", nil, parent)
    r.bg = S.Solid(r, "BACKGROUND", C.cardFill or { 1, 1, 1, 0.04 }); r.bg:SetAllPoints()
    r.hl = S.Solid(r, "BORDER", { 1, 1, 1, 0.05 }); r.hl:SetAllPoints(); r.hl:Hide()
    r.slot = S.Text(r, S.F.label, C.muted); r.slot:SetJustifyH("LEFT"); r.slot:SetWordWrap(false)
    r.icon = r:CreateTexture(nil, "ARTWORK"); r.icon:SetSize(ICON, ICON)
    r.name = S.Text(r, S.F.label, C.fg); r.name:SetJustifyH("LEFT"); r.name:SetWordWrap(false)
    r.src = S.Text(r, S.F.meta, C.muted); r.src:SetJustifyH("LEFT"); r.src:SetWordWrap(false)
    r.gain = S.Text(r, S.F.label, C.ok); r.gain:SetJustifyH("RIGHT"); r.gain:SetWordWrap(false)
    r.more = CreateFrame("Button", nil, r)
    r.more.text = S.Text(r.more, S.F.meta, C.accentSoft or C.fg); r.more.text:SetPoint("RIGHT"); r.more.text:SetJustifyH("RIGHT")
    r.more:SetScript("OnClick", function() if r.slotLabel then open[r.slotLabel] = not open[r.slotLabel] or nil; Best.Fill() end end)
    r.more:SetScript("OnEnter", function(self) S.Tip(self, { L("Clic : voir les autres choix") }) end)
    r.more:SetScript("OnLeave", S.HideTip)
    r:SetScript("OnEnter", function(self) self.hl:Show(); ShowItemTip(self, self.itemID, { L("Maj-clic : le lien dans la discussion") }) end)
    r:SetScript("OnLeave", function(self) self.hl:Hide(); GameTooltip:Hide() end)
    r:SetScript("OnClick", function(self)
        if self.itemID and IsModifiedClick and IsModifiedClick("CHATLINK") then
            local _, link = Info(self.itemID)
            if link and ChatEdit_InsertLink then ChatEdit_InsertLink(link) end
        end
    end)
    return r
end

-- one row: the slot's best piece (alt: one of its other picks, indented and without a slot label)
local function PaintRow(r, W, it, slotLabel, state, nAlts, alt)
    r.itemID, r.slotLabel = it.id, slotLabel
    r:SetHeight(alt and ALT_H or ROW_H)
    r.bg:SetShown(not alt)
    local x = 8
    if alt then r.slot:Hide(); x = 8 + SLOT_W
    else
        r.slot:SetText(slotLabel); r.slot:ClearAllPoints(); r.slot:SetPoint("LEFT", 8, 0); r.slot:SetWidth(SLOT_W - 8); r.slot:Show()
        x = 8 + SLOT_W
    end
    r.icon:ClearAllPoints(); r.icon:SetPoint("LEFT", x, 0)
    S.Painted(r.icon, S.ItemIcon(it.id)); r.icon:SetAlpha(alt and 0.8 or 1)
    x = x + ICON + 8
    -- right side: the "N picks" toggle, then the gain or the state
    local right = 8
    if nAlts and nAlts > 0 then
        r.more.text:SetText(string.format(L("%d choix"), nAlts + 1) .. (open[slotLabel] and " ▾" or " ›"))
        local mw = math.ceil(root.TextWidth(r.more.text) or 48) + 4
        r.more:SetSize(mw, 20); r.more:ClearAllPoints(); r.more:SetPoint("RIGHT", -right, 0); r.more:Show()
        right = right + mw + 12
    else r.more:Hide() end
    local g, gc
    if state == "worn" then g, gc = L("Équipé"), C.ok
    elseif state == "bag" then g, gc = L("Dans tes sacs"), C.gold
    elseif it.empty then g, gc = L("vide"), C.muted
    elseif it.pct then
        local p = math.floor(it.pct * 10 + 0.5) / 10
        g, gc = string.format(p == math.floor(p) and "%+d %%" or "%+.1f %%", p), p > 0 and C.ok or C.muted
    end
    r.gain:SetText(g or ""); if gc then r.gain:SetTextColor(gc[1], gc[2], gc[3]) end
    r.gain:SetWidth(84); r.gain:ClearAllPoints(); r.gain:SetPoint("RIGHT", -right, 0)
    right = right + 84 + 12
    local textW = math.max(60, W - x - right)
    local name, _, minLevel = Info(it.id)
    r.name:SetText(name or tostring(it.name or it.id))
    local qc = S.QualityColor(it.id) or C.fg
    r.name:SetTextColor(qc[1], qc[2], qc[3])
    r.name:SetWidth(textW); r.name:ClearAllPoints(); r.name:SetPoint("TOPLEFT", x, alt and -4 or -6)
    local src = it.source or ""
    if minLevel and minLevel > MyLevel() then
        local lv = "|cff" .. string.format("%02x%02x%02x", C.bad[1] * 255, C.bad[2] * 255, C.bad[3] * 255) .. string.format(L("Niv. %d"), minLevel) .. "|r"
        src = src ~= "" and (src .. "  ·  " .. lv) or lv
    end
    r.src:SetText(src); r.src:SetWidth(textW); r.src:ClearAllPoints(); r.src:SetPoint("TOPLEFT", x, alt and -18 or -22)
    r:SetWidth(W)
end

local function MakeNext(parent)
    local r = CreateFrame("Button", nil, parent)
    r.bg = S.Solid(r, "BACKGROUND", C.cardFill or { 1, 1, 1, 0.04 }); r.bg:SetAllPoints()
    r.hl = S.Solid(r, "BORDER", { 1, 1, 1, 0.05 }); r.hl:SetAllPoints(); r.hl:Hide()
    r.pin = r:CreateTexture(nil, "ARTWORK"); r.pin:SetSize(14, 14); r.pin:SetPoint("TOPLEFT", 10, -8)
    r.name = S.Text(r, S.F.body, C.fg); r.name:SetJustifyH("LEFT"); r.name:SetWordWrap(false)
    r.name:SetPoint("TOPLEFT", 32, -6)
    r.detail = S.Text(r, S.F.meta, C.muted); r.detail:SetJustifyH("LEFT"); r.detail:SetWordWrap(false)
    r.detail:SetPoint("TOPLEFT", 32, -24)
    r.count = S.Text(r, S.F.label, C.gold); r.count:SetJustifyH("RIGHT")
    r.gain = S.Text(r, S.F.label, C.ok); r.gain:SetJustifyH("RIGHT")
    r.go = S.Text(r, S.F.label, C.accentSoft or C.fg); r.go:SetJustifyH("RIGHT")
    r:SetScript("OnEnter", function(self)
        self.hl:Show()
        local lines = { self.title or "" }
        if self.entry then
            lines[#lines + 1] = table.concat(self.entry.slots, ", ")
            if #self.entry.who > 0 then lines[#lines + 1] = table.concat(self.entry.who, ", ") end
            if self.entry.dkey then lines[#lines + 1] = L("Clic : ouvrir le guide de ce donjon") end
        end
        S.Tip(self, lines)
    end)
    r:SetScript("OnLeave", function(self) self.hl:Hide(); S.HideTip() end)
    r:SetScript("OnClick", function(self)
        local e = self.entry
        if e and e.dkey then
            if root.ShowOverview then root.ShowOverview(e.dkey) elseif root.OpenQuests then root.OpenQuests(e.dkey) end
        end
    end)
    return r
end

-- ---------------------------------------------------------------- fill
local pools = { rows = {}, heads = {}, next = {} }
local function Take(kind, maker, parent)
    local p = pools[kind]
    p.n = (p.n or 0) + 1
    local f = p[p.n]
    if not f then f = maker(parent); p[p.n] = f end
    f:Show()
    return f
end

local function Fill()
    if not win then return end
    local lvl = LevelOf(mode)
    local spec = SpecName()
    win.sub:SetText(spec and string.format(L("Ta spé : %s"), spec) or "")
    win.intro:SetText(mode == "now" and string.format(L("Les meilleures pièces à ton niveau (%d), raids exclus."), lvl) or L(INTRO[mode]))
    local list, pending = Best.Rows(lvl, 4, mode)
    local slots = Slots(list)
    local W = math.floor((win:GetWidth() or 760) - 2 * INSET - 8)
    local child = win.list.child
    child:SetWidth(W)
    for _, p in pairs(pools) do
        for i = 1, #p do p[i]:Hide() end
        p.n = 0
    end
    -- the summary: worn of all, then the segments
    local worn, bag, get = 0, 0, 0
    for _, s in ipairs(slots) do
        if s.state == "worn" then worn = worn + 1 elseif s.state == "bag" then bag = bag + 1 else get = get + 1 end
    end
    win.count:SetText(string.format(L("%d/%d portés"), worn, #slots))
    win.countSub:SetText(string.format(L("%d à obtenir · %d dans tes sacs"), get, bag))
    win.segs = win.segs or {}
    for _, t in ipairs(win.segs) do t:Hide() end
    local y = 0
    local segW = #slots > 0 and math.floor((W - (#slots - 1) * 3) / #slots) or 0
    for i, s in ipairs(slots) do
        local t = win.segs[i] or child:CreateTexture(nil, "ARTWORK"); win.segs[i] = t
        local c = s.state == "worn" and C.ok or s.state == "bag" and C.gold or C.line or { 0.3, 0.3, 0.3 }
        t:SetColorTexture(c[1], c[2], c[3], s.state == "get" and 0.9 or 1)
        t:SetSize(segW, 4); t:ClearAllPoints(); t:SetPoint("TOPLEFT", (i - 1) * (segW + 3), -y); t:Show()
    end
    y = y + 4 + 14
    -- "À faire ensuite"
    local nexts = NextPlaces(slots)
    if #nexts > 0 and filter ~= "bag" then
        local hd = Take("heads", function(p) return S.SectionHeader(p, "", 0, nil, nil, true) end, child)
        hd:Set(L("À faire ensuite"), #nexts)
        hd:ClearAllPoints(); hd:SetPoint("TOPLEFT", 0, -y); hd:SetWidth(W)
        y = y + 32 + 4
        for _, e in ipairs(nexts) do
            local r = Take("next", MakeNext, child)
            r.entry, r.title = e, PlaceTitle(e)
            root.SetHDIcon(r.pin, e.kind == "dungeon" and "portal" or e.kind == "craft" and "gear" or "pin", C.info or C.muted)
            r.name:SetText(r.title)
            local who = #e.who > 0 and ("  ·  " .. table.concat(e.who, ", ")) or ""
            r.detail:SetText(table.concat(e.slots, ", ") .. who)
            r.count:SetText(string.format("★ %d", e.n))
            r.gain:SetText(e.gain > 0 and string.format("+%d %%", math.floor(e.gain + 0.5)) or "")
            r.go:SetText(e.dkey and (L("Ouvrir le guide") .. " ›") or "")
            r.go:ClearAllPoints(); r.go:SetPoint("RIGHT", -10, 0)
            local goW = e.dkey and (math.ceil(root.TextWidth(r.go) or 90) + 16) or 10
            r.gain:SetWidth(60); r.gain:ClearAllPoints(); r.gain:SetPoint("RIGHT", -(goW + 8), 0)
            r.count:SetWidth(40); r.count:ClearAllPoints(); r.count:SetPoint("RIGHT", -(goW + 8 + 60 + 8), 0)
            local textW = math.max(80, W - 32 - (goW + 8 + 60 + 8 + 40 + 12))
            r.name:SetWidth(textW); r.detail:SetWidth(textW)
            r:SetSize(W, 42); r:ClearAllPoints(); r:SetPoint("TOPLEFT", 0, -y)
            y = y + 42 + 2
        end
        y = y + 12
    end
    -- the table, by group
    local shown = 0
    for gi, g in ipairs(GROUPS) do
        local inGroup, wornN = {}, 0
        for _, s in ipairs(slots) do
            if s.group == gi then
                if s.state == "worn" then wornN = wornN + 1 end
                if filter == "all" or (filter == "get" and s.state == "get") or (filter == "bag" and s.state == "bag") then
                    inGroup[#inGroup + 1] = s
                end
            end
        end
        if #inGroup > 0 then
            local hd = Take("heads", function(p) return S.SectionHeader(p, "", 0, nil, nil, true) end, child)
            hd:Set(L(g[1]), #inGroup)
            hd:ClearAllPoints(); hd:SetPoint("TOPLEFT", 0, -y); hd:SetWidth(W)
            y = y + 32 + 4
            for _, s in ipairs(inGroup) do
                local r = Take("rows", MakeRow, child)
                PaintRow(r, W, s.best, s.label, s.state, #s.alts, false)
                r:ClearAllPoints(); r:SetPoint("TOPLEFT", 0, -y)
                y = y + ROW_H + 2
                shown = shown + 1
                if open[s.label] then
                    for _, a in ipairs(s.alts) do
                        local ar = Take("rows", MakeRow, child)
                        PaintRow(ar, W, a, s.label, a.worn and "worn" or (BagCount(a.id) > 0 and "bag") or "get", 0, true)
                        ar:ClearAllPoints(); ar:SetPoint("TOPLEFT", 0, -y)
                        y = y + ALT_H + 2
                    end
                end
            end
            y = y + 12
        end
    end
    local G = _G.WLHelperGear
    if not (G and G.Best) then
        win.empty:Set("gear", L("WL Helper Gear n'est pas chargé"), L("Active-le dans Échap > AddOns : c'est lui qui classe les pièces pour ta spé."))
    elseif #slots == 0 then
        win.empty:Set("gear", L("Rien à proposer ici"), L("Aucune pièce de ce type n'est connue pour ta classe."))
    else
        win.empty:Set("filter", L("Rien dans ce filtre"), L("Change de filtre pour voir les autres emplacements."))
    end
    win.empty:SetShown(shown == 0)
    win.pending:SetShown(pending == true)
    win.listH = y
    win.shown = shown
    win.Layout()
end
Best.Fill = Fill

local function Build()
    local w0 = (root.WinSize and root.WinSize("workspace")) or 900
    win = S.Window("WLHelperBest", w0, 640, L("Meilleur équipement"), nil,
        WLWritsDB, "bestPos", { header = S.HEADER_H, minH = 360, size = "workspace" })
    win.OnResize = function() Fill() end
    local top = win:ContentTop()
    local tabList = {}
    for _, m in ipairs(MODES) do tabList[#tabList + 1] = { m[1], L(m[2]) } end
    win.tabs = S.Tabs(win, tabList, function() return mode end, function(m) mode = m; win.list:ScrollTo(0, true); Fill(); win.tabs:Paint() end)
    win.tabs:SetPoint("TOPLEFT", 0, -top); win.tabs:SetPoint("TOPRIGHT", 0, -top)
    win.count = S.Text(win, S.F.title, C.fg); win.count:SetJustifyH("LEFT")
    win.countSub = S.Text(win, S.F.label, C.muted); win.countSub:SetJustifyH("LEFT")
    win.filter = S.Segmented(win, { { "all", L("Tout") }, { "get", L("À obtenir") }, { "bag", L("Dans les sacs") } },
        function() return filter end, function(v) filter = v; win.list:ScrollTo(0, true); Fill() end)
    win.sub = S.Text(win, S.F.label, C.muted); win.sub:SetJustifyH("LEFT")
    win.intro = S.Text(win, S.F.label, C.text); win.intro:SetJustifyH("LEFT"); win.intro:SetJustifyV("TOP")
    win.pending = S.Text(win, S.F.label, C.warn); win.pending:SetJustifyH("LEFT")
    win.pending:SetText(L("Certaines pièces ne sont pas encore lues par le jeu : rouvre l'onglet dans un instant."))
    win.list = S.ScrollArea(win)
    win.empty = S.EmptyState(win, "gear", "", "")
    function win.Layout()
        local W = math.floor((win:GetWidth() or 760) - 2 * INSET)
        local y = top + S.TABS_H + 14
        -- summary at the left, the filter at the right
        win.count:ClearAllPoints(); win.count:SetPoint("TOPLEFT", INSET, -y)
        win.filter:SetWidth(300); win.filter:ClearAllPoints(); win.filter:SetPoint("TOPRIGHT", -INSET, -(y - 2))
        if win.filter.Update then win.filter:Update() end
        y = y + S.F.title + 4
        win.countSub:ClearAllPoints(); win.countSub:SetPoint("TOPLEFT", INSET, -y)
        y = y + S.F.label + 10
        local line = {}
        if win.sub:GetText() ~= "" then line[#line + 1] = win.sub:GetText() end
        win.sub:Hide()
        win.intro:SetText((#line > 0 and (line[1] .. "  ·  ") or "") .. (win.intro:GetText() or ""))
        win.intro:ClearAllPoints(); win.intro:SetPoint("TOPLEFT", INSET, -y)
        y = y + S.FitText(win.intro, 0, W, win) + 8
        if win.pending:IsShown() then
            win.pending:ClearAllPoints(); win.pending:SetPoint("TOPLEFT", INSET, -y)
            y = y + S.FitText(win.pending, 0, W, win) + 8
        end
        win.list:ClearAllPoints()
        win.list:SetPoint("TOPLEFT", INSET, -y); win.list:SetPoint("BOTTOMRIGHT", -INSET + 8, 12)
        win.list:SetContentHeight(win.listH or 0)
        win.empty:ClearAllPoints(); win.empty:SetPoint("TOP", win.list, "TOP", 0, -((win.listH or 0) + 12))
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
-- for the offline tests
Best._Slots, Best._Next = Slots, NextPlaces
function Best._SetFilter(v) filter = v; Fill() end
