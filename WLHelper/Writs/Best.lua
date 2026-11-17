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
function Best.Rows(level, top)
    local G = _G.WLHelperGear
    if not (G and G.Best) then return nil end
    if WP.SyncGearSpec then pcall(WP.SyncGearSpec) end
    top = top or 3
    local out, pending = {}, false
    for _, s in ipairs(Best.SECTIONS) do
        local ok, list = pcall(G.Best, s[1], { level = level, top = top, show = { raid = false } })
        if ok and type(list) == "table" and #list > 0 then
            local rows = {}
            for _, it in ipairs(list) do
                local r = { id = it.id, name = it.name, source = Best.Source(it.source) }
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

function Best.Show(rest)
    local lvl = rest and tonumber((tostring(rest):match("(%d+)")))
    for _, l in ipairs(Best.Lines(lvl)) do WP.Print(l) end
end
