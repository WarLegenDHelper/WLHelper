-- Writs/Upgrades.lua: a green arrow on the bag items that are an upgrade for you, and a line in
-- every item tooltip ("WL Helper · Givre    +24 %", then "Remplace [icon] Old item").
--
-- The judge, first that can: Naowh Forever's stat weights for a spec whose weights you changed
-- yourself in Naowh (Writs/NaowhBiS.lua; Naowh's defaults are level 60 sims without caps or
-- leveling, so they never judge on their own), then WL Helper Gear / Geared Forever (hit and
-- defense caps, leveling), then WL Helper's own stat weights (Writs/Weights.lua): your class,
-- your spec (the talent tree with the most points, or the one picked in Settings > Upgrades) and
-- what you wear. When your Naowh weights judge a spec and Naowh writes its own upgrade line for
-- it, ours steps aside (no line twice).
-- Bags: the game's own and Baganator (corner widgets and its "upgrade" search).
-- Several specs (Settings > Upgrades > Specs to compare): one tooltip line per spec ticked, the main
-- spec first; the bag arrow follows the main spec, or any of them when the setting says so.
-- Under the percent, a short grey line says why in words, the two stats that move it most
-- ("Surtout : DPS de baguette en plus, moins de dégâts de givre"), only for a percent of 3 or more;
-- with Shift held, the numbers instead ("+12,8 DPS baguette (+30 %) · -4 dégâts de givre (-5 %) ·
-- +5 End (+2 %) · -3 Int (-2 %)"), from the judge's own sum.
-- Settings > Upgrades: how often you use your wand (its DPS counts in full, half or a tenth; by
-- default often before level 40, sometimes after), and armor lighter than yours ignored from level
-- 40 ("Armure plus légère que la tienne", no arrow).
local ADDON, root = ...
root.Writs = root.Writs or {}
local ns = root.Writs
local WP = ns.WP
local L = ns.L
local W = WP.Weights
local T = ns.S.C

ns.AddEnglish({
    ["(spé à choisir)"] = "(pick your spec)",
    ["Améliorations : ta spé n'a pas pu être lue dans tes talents, %s est supposée. Choisis-la dans WL Helper, Améliorations, Spé évaluée."] =
        "Upgrades: your spec could not be read from your talents, %s is assumed. Pick it in WL Helper, Upgrades, Rated spec.",
    ["Améliorations"] = "Upgrades",
    ["Flèche verte sur les objets meilleurs que les tiens"] = "Green arrow on items better than yours",
    ["vide"] = "empty",
    ["%s%d %%"] = "%s%d%%",
    ["Déjà équipé"] = "Already equipped",
    ["Emplacement vide"] = "Empty slot",
    ["en attente des infos de l'objet porté"] = "waiting for the worn item's data",
    ["Équipable au niveau %d"] = "Equippable at level %d",
    ["Remplace"] = "Replaces",
    ["Flèche verte pour : %s"] = "Green arrow for: %s",
    ["(poids Naowh)"] = "(Naowh weights)",
    -- the line under the percent: why
    ["Armure plus légère que la tienne"] = "Armor lighter than yours",
    ["DPS baguette"] = "wand DPS", ["DPS à distance"] = "ranged DPS", ["DPS de l'arme"] = "weapon DPS",
    ["End"] = "Sta", ["Int"] = "Int", ["Agi"] = "Agi",
    ["armure"] = "armor", ["PA"] = "AP", ["PA à distance"] = "RAP", ["crit"] = "crit", ["toucher"] = "hit",
    ["hâte"] = "haste", ["expertise"] = "expertise", ["défense"] = "defense", ["esquive"] = "dodge",
    ["parade"] = "parry", ["blocage"] = "block", ["valeur de blocage"] = "block value",
    ["puissance des sorts"] = "spell power", ["dégâts des sorts"] = "spell damage", ["soins"] = "healing",
    ["mana/5 s"] = "mp5", ["pénétration des sorts"] = "spell penetration",
    ["dégâts de feu"] = "fire damage", ["dégâts de givre"] = "frost damage", ["dégâts d'ombre"] = "shadow damage",
    ["dégâts des arcanes"] = "arcane damage", ["dégâts de nature"] = "nature damage", ["dégâts du sacré"] = "holy damage",
    ["effets"] = "effects", ["bonus d'ensemble"] = "set bonus",
    -- Settings > Upgrades (Options.lua)
    ["Calcul"] = "Scoring",
    ["J'utilise ma baguette"] = "I use my wand",
    ["Souvent"] = "Often", ["Parfois"] = "Sometimes",
    ["Automatique (souvent avant 40, parfois après)"] = "Automatic (often before 40, sometimes after)",
    ["Automatique : souvent avant le niveau 40, parfois ensuite (tes sorts comptent plus). Souvent : son DPS compte en entier. Parfois : à moitié. Jamais : presque pas, une meilleure baguette reste un peu meilleure."] =
        "Automatic: often before level 40, sometimes after (your spells count more). Often: its DPS counts in full. Sometimes: half. Never: hardly, a better wand stays a little better.",
    -- the short line under the percent (Shift: the numbers)
    ["Surtout : %s"] = "Mostly: %s",
    ["Presque pareil (%s)"] = "About the same (%s)",
    ["Seulement ~%d %s d'écart : garde celui que tu préfères."] = "Only ~%d %s apart: keep the one you like.",
    ["Écart réel : ~%d %s seulement."] = "Real gap: only ~%d %s.",
    ["Presque pareil"] = "About the same",
    ["Écart réel : ~%d %s (l'objet remplacé n'a presque pas de stats)."] = "Real gap: ~%d %s (the item replaced has almost no stats).",
    ["Bijou : les effets « Utiliser : » ne sont pas comptés, seulement les stats."] = "Trinket: \"Use:\" effects are not counted, only the stats.",
    ["de puissance des sorts"] = "spell power",
    ["de soins"] = "healing",
    ["de puissance d'attaque"] = "attack power",
    ["d'endurance"] = "stamina",
    ["%s en plus"] = "more %s", ["moins de %s"] = "less %s", ["moins d'%s"] = "less %s",
    ["DPS de baguette"] = "wand DPS", ["force"] = "strength", ["agilité"] = "agility", ["endurance"] = "stamina",
    ["intelligence"] = "intellect", ["esprit"] = "spirit", ["puissance d'attaque"] = "attack power",
    ["puissance d'attaque à distance"] = "ranged attack power", ["coups critiques"] = "crit",
    ["régénération de mana"] = "mana regen",
    ["Pourquoi, en mots. Maj : les chiffres."] = "Why, in words. Shift: the numbers.",
    ["Sous le pourcentage, une ligne grise dit en mots ce qui le fait le plus : « Surtout : DPS de baguette en plus, moins de dégâts de givre ». Garde Maj enfoncée pour les chiffres : « +12,8 DPS baguette (+30 %) · -4 dégâts de givre (-5 %) »."] =
        "Under the percent, a grey line says in words what makes it most: \"Mostly: more wand DPS, less frost damage\". Hold Shift for the numbers: \"+12.8 wand DPS (+30%) · -4 frost damage (-5%)\".",
    ["Ce que vaut le DPS d'une baguette."] = "What a wand's DPS is worth.",
    ["Ignorer les armures plus légères que la mienne (dès le niv. 40)"] = "Ignore armor lighter than mine (from level 40)",
    ["Ni % ni flèche sur une armure plus légère."] = "No % or arrow on lighter armor.",
    ["Expliquer le pourcentage"] = "Explain the percent",
    ["Dès le niveau 40 : chaman et chasseur sans cuir ni tissu, guerrier et paladin sans mailles, cuir ni tissu, druide et voleur sans tissu. L'infobulle dit « Armure plus légère que la tienne »."] =
        "From level 40: shaman and hunter without leather or cloth, warrior and paladin without mail, leather or cloth, druid and rogue without cloth. The tooltip says \"Armor lighter than yours\".",
})

local GREEN = T.ok        -- a gain
local RED = T.bad         -- a loss
local GREY = T.muted      -- equipped, no change
-- the game's own green "upgrade" arrow of the bags when this client has it (already green: no
-- tint); otherwise the HD arrow tinted with the gain colour
local function PaintArrow(tex)
    -- SetAtlas returns nothing on this engine: S.SetIcon checks the result with GetAtlas
    if ns.S.HasAtlas and ns.S.HasAtlas("bags-greenarrow") and ns.S.SetIcon(tex, { "bags-greenarrow" }, nil) then
        tex:SetVertexColor(1, 1, 1)
    else
        root.SetHDIcon(tex, "arrow_up", GREEN)
    end
end

local function Active() return WP.ModuleOn("upgrades") end
WP.UpgradesActive = Active

local cache = {}
local NO = { up = false }
-- a verdict that waits for the item you wear (its data not loaded yet, or not readable now):
-- never "empty slot", never cached, asked again when that item's data arrives
local WAIT = "wornwait"
WP.UPGRADE_WAIT = WAIT
-- armor lighter than yours, ignored (Settings > Upgrades): no percent, no arrow, its own line
local LIGHT = "lighter"
WP.UPGRADE_LIGHTER = LIGHT

-- ---------------------------------------------------------------- Geared Forever, when installed
-- Its ranking is finer than our weights (per level range, per spec): when it is installed, its own
-- verdict is read live from the item's tooltip (nothing of it is copied: it writes its lines in a
-- hidden tooltip as on any tooltip, and the line of your spec carries its green "up" arrow).
-- No setting picks the judge: WL Helper Gear ships with WL Helper and is used whenever it is loaded
-- and knows your spec; WL Helper's weights judge otherwise (Gear disabled, a spec it has no ranking
-- for), with nothing to choose.
local GF_ARROW = "GearedForever\\Media\\ArrowUp"
local function Loaded(name)
    local f = (C_AddOns and C_AddOns.IsAddOnLoaded) or IsAddOnLoaded
    return f and f(name) and true or false
end
-- WL Helper Gear (our sub-addon, Geared Forever's engine, GPLv3) is asked first through its API
local function Gear() return Loaded("WLHelper_Gear") and WLHelperGear and WLHelperGear.Compare and WLHelperGear or nil end
-- WL Helper Gear is told the spec WL Helper sees (talent tabs read the way that works on this
-- client, or your choice in Settings > Upgrades): its own talent scan can miss on Forever and
-- would then fall back to the class's first spec (a frost mage judged as arcane).
-- false when Gear has no ranking for that spec: WL Helper's weights judge it instead.
local GEAR_KEY = { aff = "affli" }
-- the settings WL Helper Gear scores with: the wand's share and the lighter armor rule (its own
-- callers, the dungeon overview, see the same); told again only when they change
local gearOpts = {}
local function PushGearOptions(G)
    if not (G and G.SetOptions) then return end
    local wand = W.WandFactor and W.WandFactor() or 1
    local lighter = (not W.LighterOn) or W.LighterOn()
    if gearOpts.G == G and gearOpts.wand == wand and gearOpts.lighter == lighter then return end
    gearOpts.G, gearOpts.wand, gearOpts.lighter = G, wand, lighter
    pcall(G.SetOptions, { wand = wand, lighter = lighter })
end
local function SyncGearSpec(G)
    PushGearOptions(G)
    local Wt = WP.Weights
    local s = Wt and Wt.Spec and Wt.Spec()
    if not (s and G.SetSpec) then return true end
    local key = GEAR_KEY[s[1]] or s[1]
    if key == G._wlSpec then return true end
    if key == G._wlNoSpec then return false end
    local ok, done = pcall(G.SetSpec, key)
    if ok and done ~= false then
        G._wlSpec, G._wlNoSpec = key, nil
        return true
    end
    G._wlSpec, G._wlNoSpec = nil, key
    return false
end
-- for the other tools that ask WL Helper Gear (Best.lua): the same spec and options first
WP.SyncGearSpec = function() local G = Gear(); if G then return SyncGearSpec(G) end end
-- kept until Refresh (talents, spec settings, login): asked for every bag slot and tooltip
local gfMemo
local function UseGF()
    if gfMemo == nil then
        local G = Gear()
        if G then gfMemo = SyncGearSpec(G)
        else gfMemo = Loaded("GearedForever") end
    end
    return gfMemo
end
-- Hides Geared Forever's block in item tooltips while our line shows the same % (an option, on by
-- default); puts it back when the option or our line is off.
function WP.ApplyGFTip()
    local db = GearedForeverDB
    if not db or not Loaded("GearedForever") then return end
    local hide = UseGF() and WLWritsDB.upgradeTip ~= false and WLWritsDB.hideGFTip ~= false
    if hide then
        if db.tooltip ~= false then WLWritsDB.gfTipHidden = true end
        db.tooltip = false
    elseif WLWritsDB.gfTipHidden then
        db.tooltip = true; WLWritsDB.gfTipHidden = nil
    end
end
WP.UpgradeUsesGF = UseGF
local gfTip
local function GFSpec()
    local G = Gear()
    if G then
        local Wt = WP.Weights
        if Wt and Wt.SpecName then return Wt.SpecName() end
    end
    local _, token = UnitClass("player")
    local key = GearedForeverDB and GearedForeverDB.specs and GearedForeverDB.specs[token]
    if type(key) ~= "string" or key == "" then return nil end
    return key:sub(1, 1):upper() .. key:sub(2)
end
-- true + "+24%" / false / nil when Geared Forever wrote nothing yet (item not loaded)
-- Geared Forever's verdict for your spec's line: a signed percent (up arrow +, down arrow -),
-- "empty" for an empty slot, "equipped", or nil when it wrote nothing yet (item not loaded)
local GF_DOWN = "GearedForever\\Media\\ArrowDown"
-- WL Helper Gear's Compare result read the same way: percent, 1000 (empty), "equipped", false, nil
local function GearResult(res)
    if not res then return nil end                      -- not cached yet: retried later
    if res.lighter then return res.equipped and "equipped" or LIGHT end
    if res.canUse ~= true or res.blocked then return false end
    if res.equipped then return "equipped" end
    if res.empty then
        -- an empty off hand: a main-hand result is in res.other
        if res.other and res.other.pct then return math.min(999, res.other.pct) end
        return 1000
    end
    -- what you wear can't be read yet: waiting, not an empty slot
    if res.unknown then return WAIT end
    -- capped like our weights' percent: "+999 %" at most, never "+1128 %"
    return res.pct and math.max(-999, math.min(999, res.pct)) or false
end
local function GFVerdict(link)
    local G = Gear()
    if G then
        SyncGearSpec(G)
        local ok, res = pcall(G.Compare, link)
        if not ok then return false end
        return GearResult(res)
    end
    if not gfTip then gfTip = CreateFrame("GameTooltip", "WLHelperGFTip", nil, "GameTooltipTemplate") end
    gfTip:SetOwner(WorldFrame, "ANCHOR_NONE")
    gfTip:ClearLines()
    -- Geared Forever's own block may be hidden from the player's tooltips (it repeats our %):
    -- it is switched on just for this private read
    local db = GearedForeverDB
    local was, wasShift = db and db.tooltip, db and db.tooltipShift
    if db then db.tooltip = true; db.tooltipShift = nil end
    local okSet = pcall(gfTip.SetHyperlink, gfTip, link)
    if db then db.tooltip = was; db.tooltipShift = wasShift end
    if not okSet then gfTip:Hide(); return false end
    local want = GFSpec()
    local saw, best, equipped = false, nil, false
    for i = 1, gfTip:NumLines() do
        local left = _G["WLHelperGFTipTextLeft" .. i]
        local right = _G["WLHelperGFTipTextRight" .. i]
        local l = left and left:GetText()
        if l and l:find("^Geared Forever") then saw = true
        elseif saw and l and (not want or l == want) then
            local r = right and right:GetText()
            if r then
                local plain = r:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
                if plain:lower():find("equipped", 1, true) then equipped = true end
                -- one-hand weapons can show both hands: keep the best
                for chunk in plain:gmatch("[^,]+") do
                    local n = tonumber(chunk:match("(%d+)%%"))
                    if chunk:find("empty slot", 1, true) then n = 1000
                    elseif n and chunk:find(GF_DOWN, 1, true) then n = -n
                    elseif n and not chunk:find(GF_ARROW, 1, true) then n = nil end
                    if n and (not best or n > best) then best = n end
                end
            end
        end
    end
    gfTip:Hide()
    if best then return best end
    if equipped then return "equipped" end
    if saw then return false end
    return nil
end
local function GFRead(link)
    local v = GFVerdict(link)
    if v == nil or v == WAIT then return nil end
    if type(v) == "number" and v > 0 then return true, v >= 1000 and L("vide") or ("+" .. v .. "%"), v end
    return false
end
local tries, retryQueued = {}, false
-- [item ID] = times the data of an item you wear arrived and refreshed every verdict (5 at most)
local wornHits = {}
-- item IDs asked while not loaded yet: only their GET_ITEM_INFO_RECEIVED repaints the bags
local pending = {}
local function Pending(link)
    local id = tonumber(link:match("item:(%d+)"))
    if id then pending[id] = true end
end
-- an answer that is not there yet although the item is loaded (Gear cannot read what you wear yet):
-- asked again in 1 s, at most 5 times per key, then false. Returns true once the tries are spent.
local function Retry(key)
    tries[key] = (tries[key] or 0) + 1
    if tries[key] > 5 then return true end
    if not retryQueued then
        retryQueued = true
        C_Timer.After(1, function() retryQueued = false; cache = {}; if WP.RefreshUpgrades then WP.RefreshUpgrades() end end)
    end
    return false
end

local function Worn(link)
    local equipLoc = select(9, ((C_Item and C_Item.GetItemInfo) or GetItemInfo)(link))
    for _, s in ipairs(W.SLOTS[equipLoc or ""] or {}) do
        if GetInventoryItemLink("player", s) == link then return true end
    end
    return false
end
-- armor lighter than yours that the setting ignores (and that you do not wear)
local function Lighter(link)
    return W.Lighter ~= nil and W.Lighter(link) == true and not Worn(link)
end

-- ---------------------------------------------------------------- Naowh Forever's weights, when yours
-- Asked first for a spec whose weights the player changed in Naowh (WP.NaowhBiS.JudgeKey, loaded
-- after this file: read when called); Naowh's tooltip and marks switches do not decide. Who may wear it, worn and empty slots stay ours; the percent is Naowh's.
local NOJUDGE = {}             -- Naowh does not judge this spec: the next judge does
local nbMemo = {}              -- [our spec key] = Naowh key or false, until Refresh
local function NaowhKey(spec)
    local NB = WP.NaowhBiS
    if not (NB and spec) then return false end
    local k = nbMemo[spec[1]]
    if k == nil then k = NB.JudgeKey(spec) or false; nbMemo[spec[1]] = k end
    return k
end
local function NaowhMain()
    local s = W.Spec()
    return s and NaowhKey(s) or false
end
-- Naowh's own tooltip line already gives this spec's percent
local function NaowhTipShown(spec)
    local k = NaowhKey(spec)
    return k and WP.NaowhBiS.TipShows(k) or false
end
-- a percent, 1000 (empty slot), "equipped", false, nil (not loaded yet) or NOJUDGE
local function NaowhVerdict(link, spec)
    local key = NaowhKey(spec)
    if not key then return NOJUDGE end
    local can = W.CanWear(link)
    if can == nil then return nil end
    if not can then return false end
    if Worn(link) then return "equipped" end
    local wg = W.Gain(link, spec)
    if wg == "empty" then return 1000 end
    if wg == "pending" then return WAIT end
    local g, why = WP.NaowhBiS.Gain(link, key)
    if type(g) == "number" then return math.max(-999, math.min(999, g)) end
    if why == "loading" then return nil end
    -- Naowh cannot judge now (gone, no weights, cannot read your stats, an error): the next judge
    if why == "absent" or why == "nospec" or why == "nopower" or why == "error" then return NOJUDGE end
    return false
end
WP.UpgradeNaowhVerdict = NaowhVerdict

-- { up = true/false, text = "+24%", n = gain } for the main spec
local function CheckMain(link)
    if type(link) ~= "string" or not Active() then return NO end
    local c = cache[link]
    if c then return c end
    if Lighter(link) then cache[link] = NO; return NO end
    local main = W.Spec()
    local nv = main and NaowhVerdict(link, main) or NOJUDGE
    if nv ~= NOJUDGE then
        if nv == nil or nv == WAIT then
            Pending(link)
            if Retry(link) then cache[link] = NO end
            return NO
        end
        local r
        if nv == 1000 then r = { up = true, text = L("vide"), n = 1000 }
        elseif type(nv) == "number" and nv >= (WLWritsDB.upgradeMin or 1) then
            r = { up = true, text = nv >= 999 and "+999%" or ("+" .. math.floor(nv + 0.5) .. "%"), n = nv }
        else r = NO end
        cache[link] = r
        return r
    end
    if UseGF() then
        -- not gear (potion, reagent): Geared Forever writes nothing on it, no need to wait for it
        local Instant = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
        if Instant then
            local _, _, _, equipLoc = Instant(link)
            if not (equipLoc and W.SLOTS[equipLoc]) then cache[link] = NO; return NO end
        end
        local up, text, n = GFRead(link)
        if up == nil then
            Pending(link)
            if Retry(link) then cache[link] = NO end
            return NO
        end
        local r = (up and (n or 0) >= (WLWritsDB.upgradeMin or 1)) and { up = true, text = text, n = n } or NO
        cache[link] = r
        return r
    end
    local can = W.CanWear(link)
    if can == nil then Pending(link); return NO end   -- item not loaded yet: not cached, asked again later
    local gain = can and W.Gain(link)
    if gain == "pending" then return NO end            -- what you wear is not loaded yet: not cached
    local r
    if gain == "empty" then r = { up = true, text = L("vide"), n = 1000 }
    elseif type(gain) == "number" and gain >= (WLWritsDB.upgradeMin or 1) then r = { up = true, text = gain >= 999 and "+999%" or ("+" .. math.floor(gain + 0.5) .. "%"), n = gain }
    else r = NO end
    cache[link] = r
    return r
end

-- ---------------------------------------------------------------- several specs
-- One verdict per spec: a percent (number), 1000 for an empty slot, "equipped", false (nothing to
-- say: not for you, blocked) or nil (not loaded yet: asked again later). Cached per item link and
-- spec; Refresh empties the cache (equipment, level and talent changes, settings).
local specCache = {}
local specByNaowh = {}         -- [link|spec] = true when Naowh's weights gave that verdict
-- WL Helper's weights for one spec
local function WeightsVerdict(link, spec)
    local can = W.CanWear(link)
    if can == nil then return nil end
    if not can then return false end
    if Worn(link) then return "equipped" end
    local gain = W.Gain(link, spec)
    if gain == "empty" then return 1000 end
    if gain == "pending" then return WAIT end
    if type(gain) == "number" then return math.max(-999, math.min(999, gain)) end
    return false
end
-- WL Helper Gear asked for another spec: SetSpec to it, Compare, then back to the main spec
local function GearFor(G, link, spec)
    local key = GEAR_KEY[spec[1]] or spec[1]
    local ok, done = pcall(G.SetSpec, key)
    local v
    if ok and done ~= false then
        G._wlSpec = key
        local okC, res = pcall(G.Compare, link)
        if okC then v = GearResult(res) else v = false end
    else
        v = WeightsVerdict(link, spec)                  -- a spec Gear does not know: our weights
    end
    G._wlSpec = nil
    SyncGearSpec(G)
    -- the main spec could not be set back: Gear's own choice rather than the other spec
    if not G._wlSpec then pcall(G.SetSpec, nil) end
    return v
end
-- the verdict, and true when Naowh's weights gave it
local function SpecVerdict(link, spec, isMain)
    local ck = link .. "|" .. spec[1]
    local c = specCache[ck]
    if c ~= nil then return c, specByNaowh[ck] or false end
    if Lighter(link) then specCache[ck] = LIGHT; return LIGHT, false end
    local v = NaowhVerdict(link, spec)
    local byNaowh = v ~= NOJUDGE
    if v == NOJUDGE then
        if UseGF() then
            local G = Gear()
            if isMain then v = GFVerdict(link)
            elseif G then v = GearFor(G, link, spec)
            else v = WeightsVerdict(link, spec) end     -- Geared Forever alone judges the main spec only
        else
            v = WeightsVerdict(link, spec)
        end
    end
    if v ~= nil and v ~= WAIT then specCache[ck] = v; specByNaowh[ck] = byNaowh or nil end
    return v, byNaowh
end
WP.UpgradeSpecVerdict = SpecVerdict
local function IsGear(link)
    local Instant = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
    if not Instant then return true end
    local _, _, _, equipLoc = Instant(link)
    return equipLoc and W.SLOTS[equipLoc] and true or false
end
-- The specs judged, main first: W.CompareSpecs reads the talents (a full C_Traits scan), so it is
-- kept until Refresh (talents, spec settings) instead of being read again for every bag slot.
-- With Geared Forever alone, the main line is Geared Forever's own spec: that spec is left out of
-- the extras so it is never shown twice.
local specsMemo, judgedMemo, judgedGF
local function Judged()
    if not specsMemo then specsMemo = W.CompareSpecs and W.CompareSpecs() or {}; judgedMemo = nil end
    local gfKey = false
    if UseGF() and not Gear() and not NaowhMain() and W.SpecKeyFor then gfKey = W.SpecKeyFor(GFSpec()) or false end
    if judgedMemo and judgedGF == gfKey then return judgedMemo end
    local out = {}
    for i, spec in ipairs(specsMemo) do
        if i == 1 or spec[1] ~= gfKey then out[#out + 1] = spec end
    end
    judgedMemo, judgedGF = out, gfKey
    return out
end
local function MultiSpec() return #Judged() > 1 end
local function ArrowAny() return WLWritsDB.upgradeArrowFor == "any" and MultiSpec() end
-- the specs (names) whose gain puts the arrow on the item, main first
local function ArrowSpecs(link)
    local out = {}
    if not IsGear(link) then return out end
    local min = WLWritsDB.upgradeMin or 1
    for i, spec in ipairs(Judged()) do
        local v = SpecVerdict(link, spec, i == 1)
        if type(v) == "number" and v >= min then out[#out + 1] = W.SpecName(spec) end
    end
    return out
end
WP.UpgradeArrowSpecs = ArrowSpecs

-- { up = true/false, text = "+24%" }: the main spec, or the best of your specs when the arrow is
-- for any of them
local function Check(link)
    if type(link) ~= "string" or not Active() then return NO end
    local key = "any|" .. link
    local c = cache[key]
    if c then return c end
    local r = CheckMain(link)
    if not ArrowAny() then return r end
    if not IsGear(link) then cache[key] = NO; return NO end
    local min = WLWritsDB.upgradeMin or 1
    local best, waiting = r.up and r or nil, false
    local specs = Judged()
    for i = 2, #specs do
        local v = SpecVerdict(link, specs[i], false)
        if v == nil or v == WAIT then
            -- nothing yet for this spec: asked again in 1 s, false after 5 tries
            local ck = link .. "|" .. specs[i][1]
            if Retry(ck) then specCache[ck] = false else waiting = true end
        elseif type(v) == "number" and v >= min and not (best and (best.n or 0) >= v) then
            local text = v >= 1000 and L("vide") or (v >= 999 and "+999%" or ("+" .. math.floor(v + 0.5) .. "%"))
            best = { up = true, text = text, n = v }
        end
    end
    if waiting then Pending(link) end
    local res = best or NO
    if not waiting then cache[key] = res end
    return res
end
WP.UpgradeCheck = Check
local function IsUpgrade(link) return Check(link).up end

-- ---------------------------------------------------------------- tooltip line
-- "+24 %" in French, "+24%" in English (a negative number carries its own sign)
local function Percent(n)
    return string.format(L("%s%d %%"), n > 0 and "+" or "", n)
end
-- "instead of [icon] Old Item" under the percent: the item(s) it would replace (both hands for a
-- two-hander when an off hand is worn)
local function InsteadOf(tip, link)
    local equipLoc = select(9, ((C_Item and C_Item.GetItemInfo) or GetItemInfo)(link))
    local slots = equipLoc and W.SLOTS[equipLoc]
    if not slots then return end
    local slot = (#slots == 1 and slots[1]) or nil
    if not slot and UseGF() then
        local G = Gear()
        if G then
            SyncGearSpec(G)
            local ok, res = pcall(G.Compare, link)
            if ok and type(res) == "table" and type(res.slot) == "number" then slot = res.slot end
        end
    end
    slot = slot or select(2, W.Gain(link))
    if not slot then return end
    local list = { slot }
    if equipLoc == "INVTYPE_2HWEAPON" and GetInventoryItemLink("player", 17) then list[#list + 1] = 17 end
    for _, s in ipairs(list) do
        local cur = GetInventoryItemLink("player", s)
        local tex = GetInventoryItemTexture and GetInventoryItemTexture("player", s)
        if cur and tex then
            tip:AddLine(L("Remplace") .. " |T" .. tex .. ":14:14:0:-1:64:64:5:59:5:59|t " .. cur, GREY[1], GREY[2], GREY[3])
        end
    end
    -- a trinket is mostly its effect, which the percent does not see
    if equipLoc == "INVTYPE_TRINKET" then
        tip:AddLine(L("Bijou : les effets « Utiliser : » ne sont pas comptés, seulement les stats."), GREY[1], GREY[2], GREY[3], true)
    end
end

-- ---------------------------------------------------------------- why this percent
-- The judge's own sum, stat by stat: WP.NaowhBiS.Explain (Naowh's weights), WLHelperGear.Explain,
-- or W.Explain (WL Helper's weights). Rows { stat, amount, pct }: the spell damage of the spec's
-- school and plain spell damage are one row ("+5 spell damage" and "-9 frost damage" are "-4
-- dégâts de givre"); the 4 biggest, "+12,8 DPS baguette (+30 %) · -4 dégâts de givre (-5 %)".
local SPELL_GROUP = { sp = true, sdmg = true, fire = true, frost = true, shadow = true, arcane = true, nature = true, holy = true }
local SCHOOLS = { fire = true, frost = true, shadow = true, arcane = true, nature = true, holy = true }
local function English() return ns.English ~= nil and ns.English() == true end
local function StatLabel(stat, link)
    if stat == "dps" then
        local Instant = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
        local loc, cid, sid
        if Instant then local _; _, _, _, loc, _, cid, sid = Instant(link) end
        if cid == 2 and sid == 19 then return L("DPS baguette") end
        if loc == "INVTYPE_RANGED" or loc == "INVTYPE_RANGEDRIGHT" or loc == "INVTYPE_THROWN" then return L("DPS à distance") end
        return L("DPS de l'arme")
    end
    local t = {
        str = L("Force"), agi = L("Agi"), sta = L("End"), int = L("Int"), spi = L("Esprit"), armor = L("armure"),
        ap = L("PA"), rap = L("PA à distance"), crit = L("crit"), hit = L("toucher"), haste = L("hâte"),
        exp = L("expertise"), def = L("défense"), dodge = L("esquive"), parry = L("parade"), block = L("blocage"),
        bv = L("valeur de blocage"), sp = L("puissance des sorts"), sdmg = L("dégâts des sorts"), heal = L("soins"),
        mp5 = L("mana/5 s"), spen = L("pénétration des sorts"), fire = L("dégâts de feu"), frost = L("dégâts de givre"),
        shadow = L("dégâts d'ombre"), arcane = L("dégâts des arcanes"), nature = L("dégâts de nature"),
        holy = L("dégâts du sacré"), other = L("effets"), set = L("bonus d'ensemble"),
    }
    return t[stat] or stat
end
-- "+12,8" / "+12.8" (DPS) or "+5"; "-3"
local function Amount(n, decimal)
    local sign = n < 0 and "-" or "+"
    local a = math.abs(n)
    local txt
    if decimal or (a > 0 and a < 0.95) then txt = string.format("%.1f", a) else txt = tostring(math.floor(a + 0.5)) end
    if txt:find("%.0$") and not decimal then txt = txt:sub(1, -3) end
    if not English() then txt = txt:gsub("%.", ",") end
    return sign .. txt
end
local MAX_ROWS = 4
-- rows -> the rows merged (the spell damage family as one), biggest share first
local function Merge(rows)
    -- the spell damage family: one row, named after its school when one is in it
    local merged, group = {}, nil
    for _, r in ipairs(rows) do
        if SPELL_GROUP[r.stat] then
            if not group then
                group = { stat = r.stat, amount = 0, pct = 0, school = nil, schoolPct = 0 }
                merged[#merged + 1] = group
            end
            group.amount, group.pct = group.amount + (r.amount or 0), group.pct + (r.pct or 0)
            if SCHOOLS[r.stat] and math.abs(r.pct or 0) >= group.schoolPct then group.school, group.schoolPct = r.stat, math.abs(r.pct or 0) end
            -- plain spell damage and spell power together: spell power
            if r.stat == "sp" then group.stat = "sp" end
        else
            merged[#merged + 1] = { stat = r.stat, amount = r.amount or 0, pct = r.pct or 0 }
        end
    end
    if group and group.school then group.stat = group.school end
    table.sort(merged, function(a, b) return math.abs(a.pct) > math.abs(b.pct) end)
    return merged
end
-- rows -> the numbers ("+12,8 DPS baguette (+30 %) · ..."), or nil
local function ExplainFormat(rows, link)
    if type(rows) ~= "table" or #rows == 0 then return nil end
    local merged = Merge(rows)
    local parts = {}
    for _, r in ipairs(merged) do
        if #parts >= MAX_ROWS then break end
        if math.abs(r.pct) >= 0.05 then
            local label = StatLabel(r.stat, link)
            local txt
            -- no amount for effects and sets, nor when the amounts cancel out ("+5 sp, -5 frost")
            if r.stat == "other" or r.stat == "set" or math.abs(r.amount) < 0.05 then txt = label
            else txt = Amount(r.amount, r.stat == "dps") .. " " .. label end
            local p = math.floor(math.abs(r.pct) + 0.5)
            if p >= 1 then txt = txt .. " (" .. string.format(L("%s%d %%"), r.pct < 0 and "-" or "+", p) .. ")" end
            parts[#parts + 1] = txt
        end
    end
    if #parts == 0 then return nil end
    return table.concat(parts, " · ")
end
-- the stat in words, for the short line ("DPS de baguette", "endurance", "dégâts de givre")
local function StatWord(stat, link)
    if stat == "dps" then
        local l = StatLabel(stat, link)
        if l == L("DPS baguette") then return L("DPS de baguette") end
        return l
    end
    local t = {
        str = L("force"), agi = L("agilité"), sta = L("endurance"), int = L("intelligence"), spi = L("esprit"),
        ap = L("puissance d'attaque"), rap = L("puissance d'attaque à distance"), crit = L("coups critiques"),
        mp5 = L("régénération de mana"),
    }
    return t[stat] or StatLabel(stat, link)
end
local SHORT_ROWS = 2
-- rows -> "Surtout : DPS de baguette en plus, moins de dégâts de givre", or nil
local function ExplainShort(rows, link)
    if type(rows) ~= "table" or #rows == 0 then return nil end
    local parts = {}
    for _, r in ipairs(Merge(rows)) do
        if #parts >= SHORT_ROWS or math.abs(r.pct) < 0.5 then break end
        local word = StatWord(r.stat, link)
        -- more or less of the stat (its amount; the share when the amounts cancel out)
        local more
        if math.abs(r.amount) >= 0.05 and r.stat ~= "other" and r.stat ~= "set" then more = r.amount > 0 else more = r.pct > 0 end
        local txt
        if more then txt = string.format(L("%s en plus"), word)
        elseif not English() and (word:find("^[aeiouyAEIOUY]") or word:find("^\195[\168\169\170\136\137]")) then
            txt = string.format(L("moins d'%s"), word)
        else txt = string.format(L("moins de %s"), word) end
        parts[#parts + 1] = txt
    end
    if #parts == 0 then return nil end
    return string.format(L("Surtout : %s"), table.concat(parts, ", "))
end
WP.UpgradeExplainShort = ExplainShort
local explainCache = {}
-- the text for the spec judged (byNaowh: Naowh's weights judged it), or nil; short: in words
local function ExplainText(link, spec, byNaowh, short)
    if type(link) ~= "string" or not spec then return nil end
    local ck = link .. "|" .. tostring(spec[1]) .. (byNaowh and "|n" or "") .. (short and "|s" or "")
    local c = explainCache[ck]
    if c ~= nil then return c or nil end
    local res
    if byNaowh then
        local k = NaowhKey(spec)
        local NB = WP.NaowhBiS
        if k and NB and NB.Explain then res = NB.Explain(link, k) end
    elseif UseGF() then
        local G = Gear()
        if G and G.Explain then
            SyncGearSpec(G)
            local ok, r = pcall(G.Explain, link)
            res = ok and r or nil
        end
    elseif W.Explain then
        local ok, r = pcall(W.Explain, link, spec)
        res = ok and r or nil
    end
    local text = res and (short and ExplainShort or ExplainFormat)(res.rows, link) or nil
    if text then explainCache[ck] = text end
    return text
end
-- the main spec's "why" (its percent's biggest stats, the numbers; short: in words), for other pages
function WP.UpgradeExplain(link, short)
    if type(link) ~= "string" or not Active() then return nil end
    local main = W.Spec()
    if not main then return nil end
    local v, byNaowh = SpecVerdict(link, main, true)
    if type(v) ~= "number" or v >= 1000 then return nil end
    return ExplainText(link, main, byNaowh, short)
end
WP.UpgradeExplainFormat = ExplainFormat
-- A near tie: WL Helper Gear scores in the spec's main stat (spell power, healing, attack power,
-- or Stamina for tanks), so score minus old is the gap in those points. A gap of a few points
-- reads "Presque pareil" under 10 %; from 10 % on the percent stays, with the gap in points under it.
-- -> points, the unit's words; nil when not a near tie or not judged by WL Helper Gear
local NEAR = { sp = 5, heal = 8, ap = 10, sta = 5 }
local NEAR_WORD = { sp = "de puissance des sorts", heal = "de soins", ap = "de puissance d'attaque", sta = "d'endurance" }
local function NearTie(link)
    local G = Gear()
    if not (G and G.Weights and G.Compare) then return nil end
    SyncGearSpec(G)
    local ok, res = pcall(G.Compare, link)
    if not ok or type(res) ~= "table" or res.empty or res.equipped or not res.pct
        or type(res.score) ~= "number" or type(res.old) ~= "number" or res.old <= 0 then return nil end
    local okW, wt = pcall(G.Weights)
    if not okW or type(wt) ~= "table" or type(wt.stats) ~= "table" then return nil end
    for _, k in ipairs({ "sp", "heal", "ap", "sta" }) do
        if wt.stats[k] == 1 then
            local pts = math.abs(res.score - res.old)
            -- the worn item is worth a few points only (a trinket whose worth is its "Use:"
            -- effect: Theka's Last Breath, 6 mana per 5 s): any gap is a huge percent, so the
            -- points say it (report: "+125 % with no stat at all")
            local small = res.old < NEAR[k] * 1.5
            if small then return pts, L(NEAR_WORD[k]), true, k end
            if math.abs(res.pct) >= 25 then return nil end
            if pts <= NEAR[k] then return pts, L(NEAR_WORD[k]) end
            return nil
        end
    end
    return nil
end
WP.UpgradeNearTie = NearTie
-- the percent's text and colour for a near tie ("Presque pareil (-14 %)", grey) and the line under
-- it; unchanged and nil otherwise (v: the percent, WL Helper Gear judging)
local function Near(link, v, text, col)
    if type(v) ~= "number" or math.abs(math.floor(v + 0.5)) < 1 then return text, col end
    local ok, pts, word, small, key = pcall(NearTie, link)
    if not ok or not pts then return text, col end
    local n = math.max(1, math.floor(pts + 0.5))
    if small then
        -- next to an item with almost no stats a percent means nothing: a few points are a tie,
        -- more stay a gain or a loss with the points under it
        if pts <= (NEAR[key] or 5) then
            return L("Presque pareil"), GREY, string.format(L("Seulement ~%d %s d'écart : garde celui que tu préfères."), n, word)
        end
        return text, col, string.format(L("Écart réel : ~%d %s (l'objet remplacé n'a presque pas de stats)."), n, word)
    end
    -- 10 % and more stays a gain or a loss in its colour (a +12 % belt is an upgrade, even when its
    -- 2 spell power are few): the grey line under it says how small the gap really is
    if math.abs(v) >= 10 then
        return text, col, string.format(L("Écart réel : ~%d %s seulement."), math.max(1, math.floor(pts + 0.5)), word)
    end
    return string.format(L("Presque pareil (%s)"), text), GREY,
        string.format(L("Seulement ~%d %s d'écart : garde celui que tu préfères."), math.max(1, math.floor(pts + 0.5)), word)
end
-- WL Helper Gear's weights when it judges (Settings > Upgrades shows them): { { key, weight } },
-- biggest first, and its Weights() result; nil when our own weights judge
function WP.UpgradeGearWeights()
    if not UseGF() then return nil end
    local G = Gear()
    if not (G and G.Weights) then return nil end
    local ok, wt = pcall(G.Weights)
    if not ok or type(wt) ~= "table" or type(wt.stats) ~= "table" then return nil end
    local t = {}
    for k, v in pairs(wt.stats) do if type(v) == "number" and v >= 0.005 then t[#t + 1] = { k, v } end end
    table.sort(t, function(a, b) if a[2] ~= b[2] then return a[2] > b[2] end return a[1] < b[1] end)
    return t, wt
end
-- under the percent shown (n, rounded): the short line for 3 % or more; Shift held: the numbers
local SHORT_MIN = 3
local function Shift() return IsShiftKeyDown and IsShiftKeyDown() and true or false end
local function ExplainLine(tip, link, spec, byNaowh, n)
    if WLWritsDB and WLWritsDB.upgradeWhy == false then return end
    local full = Shift()
    if not full and not (type(n) == "number" and math.abs(n) >= SHORT_MIN) then return end
    local ok, text = pcall(ExplainText, link, spec, byNaowh, not full)
    if ok and text then tip:AddLine(text, GREY[1], GREY[2], GREY[3], true) end
end

-- the left half of the line: the addon's tag, then the spec judged ("(poids Naowh)" when Naowh's
-- weights judged it)
local function Tag(spec, extra, naowh)
    local guess = not extra and W.SpecGuessed and W.SpecGuessed()
    return ns.S.Hex(T.accent) .. "WL Helper|r · " .. (spec or "") .. (guess and (" " .. ns.S.Hex(T.warn) .. L("(spé à choisir)") .. "|r") or "")
        .. (naowh and (" " .. ns.S.Hex(T.muted) .. L("(poids Naowh)") .. "|r") or "")
end

-- the right half of a spec's line: text, colour, true for a percent
local function VerdictText(v)
    if v == "equipped" then return L("Déjà équipé"), GREY end
    if v == LIGHT then return L("Armure plus légère que la tienne"), GREY end
    if v == WAIT then return L("en attente des infos de l'objet porté"), GREY end
    if type(v) == "number" and v >= 1000 then return L("Emplacement vide"), GREEN end
    if type(v) == "number" then
        local n = math.floor(v + 0.5)
        return Percent(n), n >= 1 and GREEN or (n <= -1 and RED or GREY), true
    end
end
-- one line per spec judged ("WL Helper · Protection  +6 %", "WL Helper · Fureur  -3 %"), main first
local function MultiLines(tip, link)
    if not IsGear(link) then return end
    local nMain = NaowhMain()
    if not UseGF() or nMain then
        -- only your level stops you (the same for every spec): the one line saying from which level
        local can, why, lvl = W.CanWear(link)
        if not can then
            if why == "level" and lvl then
                tip:AddDoubleLine(Tag(W.SpecName(), nil, nMain and true), string.format(L("Équipable au niveau %d"), lvl), T.fg[1], T.fg[2], T.fg[3], T.warn[1], T.warn[2], T.warn[3])
            end
            return
        end
    end
    local pct, shown = false, false
    for i, spec in ipairs(Judged()) do
        local v, byNaowh = SpecVerdict(link, spec, i == 1)
        local name = W.SpecName(spec)
        if i == 1 and UseGF() and not byNaowh then name = W.SpecNameFor(GFSpec()) end
        local text, col, isPct = VerdictText(v)
        -- Naowh writes this spec's percent itself: ours steps aside (worn: Naowh says nothing)
        if text and not (byNaowh and type(v) == "number" and NaowhTipShown(spec)) then
            -- a gap of a few points of the main stat: "Presque pareil (-14 %)", in grey
            local near
            if i == 1 and isPct and not byNaowh and UseGF() then text, col, near = Near(link, v, text, col) end
            tip:AddDoubleLine(Tag(name, i > 1, byNaowh), text, T.fg[1], T.fg[2], T.fg[3], col[1], col[2], col[3])
            shown = true
            pct = pct or isPct
            if near then tip:AddLine(near, GREY[1], GREY[2], GREY[3], true) end
            if i == 1 and isPct then ExplainLine(tip, link, spec, byNaowh, math.floor(v + 0.5)) end
        end
        -- the item you wear, or lighter armor: one line is enough
        if i == 1 and (v == "equipped" or v == LIGHT) then return end
    end
    if shown and ArrowAny() then
        local who = ArrowSpecs(link)
        if #who > 0 then
            tip:AddLine(string.format(L("Flèche verte pour : %s"), table.concat(who, ", ")), GREEN[1], GREEN[2], GREEN[3])
        end
    end
    if pct then InsteadOf(tip, link) end
end

local function TooltipLine(tip, link)
    if not (Active() and link) or WLWritsDB.upgradeTip == false then return end
    if MultiSpec() then return MultiLines(tip, link) end
    local main = W.Spec()
    if Lighter(link) then
        local name = (UseGF() and not (main and NaowhKey(main))) and W.SpecNameFor(GFSpec()) or W.SpecName()
        tip:AddDoubleLine(Tag(name), L("Armure plus légère que la tienne"), T.fg[1], T.fg[2], T.fg[3], GREY[1], GREY[2], GREY[3])
        return
    end
    if main and NaowhKey(main) then
        -- Naowh's weights judge (cached per link): ours with "(poids Naowh)"; Naowh's own tooltip line
        -- gives the percent already (ours steps aside), not the worn or level lines
        local v, byNaowh = SpecVerdict(link, main, true)
        if byNaowh then
            if type(v) == "number" and NaowhTipShown(main) then return end
            if v == nil then return end
            if v == false then
                local can, why, lvl = W.CanWear(link)
                if not can and why == "level" and lvl then
                    tip:AddDoubleLine(Tag(W.SpecName(main), nil, true), string.format(L("Équipable au niveau %d"), lvl), T.fg[1], T.fg[2], T.fg[3], T.warn[1], T.warn[2], T.warn[3])
                end
                return
            end
            local text, col, isPct = VerdictText(v)
            if not text then return end
            tip:AddDoubleLine(Tag(W.SpecName(main), nil, true), text, T.fg[1], T.fg[2], T.fg[3], col[1], col[2], col[3])
            if isPct then ExplainLine(tip, link, main, true, math.floor(v + 0.5)); InsteadOf(tip, link) end
            return
        end
    end
    if UseGF() then
        local v = GFVerdict(link)
        local text, col
        local pct = false
        if v == "equipped" then text, col = L("Déjà équipé"), GREY
        elseif v == LIGHT then text, col = L("Armure plus légère que la tienne"), GREY
        elseif v == WAIT then text, col = L("en attente des infos de l'objet porté"), GREY
        elseif type(v) == "number" and v >= 1000 then text, col = L("Emplacement vide"), GREEN
        elseif type(v) == "number" then
            text, pct = Percent(v), true
            col = v > 0 and GREEN or (v < 0 and RED or GREY)
        else return end
        local near
        if pct then text, col, near = Near(link, v, text, col) end
        tip:AddDoubleLine(Tag(W.SpecNameFor(GFSpec())), text, T.fg[1], T.fg[2], T.fg[3], col[1], col[2], col[3])
        if near then tip:AddLine(near, GREY[1], GREY[2], GREY[3], true) end
        if pct then ExplainLine(tip, link, main, false, math.floor(v + 0.5)); InsteadOf(tip, link) end
        return
    end
    local spec = W.SpecName()
    local can, why, lvl = W.CanWear(link)
    if not can then
        -- only your level stops you: say from which level
        if why == "level" and lvl then
            tip:AddDoubleLine(Tag(spec), string.format(L("Équipable au niveau %d"), lvl), T.fg[1], T.fg[2], T.fg[3], T.warn[1], T.warn[2], T.warn[3])
        end
        return
    end
    local gain = W.Gain(link)
    local text, col
    local pct = false
    local equipped = false
    for _, slots in pairs({ W.SLOTS[select(9, ((C_Item and C_Item.GetItemInfo) or GetItemInfo)(link)) or ""] or {} }) do
        for _, s in ipairs(slots) do if GetInventoryItemLink("player", s) == link then equipped = true end end
    end
    if equipped then text, col = L("Déjà équipé"), GREY
    elseif gain == "pending" then text, col = L("en attente des infos de l'objet porté"), GREY
    elseif gain == "empty" then text, col = L("Emplacement vide"), GREEN
    elseif type(gain) == "number" then
        local n = math.floor(gain + 0.5)
        text, pct = Percent(n), true
        col = n >= 1 and GREEN or (n <= -1 and RED or GREY)
    else return end
    -- no tip:Show() here: the game resizes the tooltip itself; calling it from an addon can taint it
    tip:AddDoubleLine(Tag(spec), text, T.fg[1], T.fg[2], T.fg[3], col[1], col[2], col[3])
    if pct then ExplainLine(tip, link, main, false, math.floor(gain + 0.5)); InsteadOf(tip, link) end
end
WP.UpgradeTooltipLine = TooltipLine
if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tip)
        if tip ~= GameTooltip and tip ~= ItemRefTooltip then return end
        local _, link = tip:GetItem()
        pcall(TooltipLine, tip, link)
    end)
else
    for _, t in ipairs({ GameTooltip, ItemRefTooltip }) do
        if t and t.HookScript then
            t:HookScript("OnTooltipSetItem", function(tip) local _, link = tip:GetItem(); pcall(TooltipLine, tip, link) end)
        end
    end
end

-- ---------------------------------------------------------------- bag slots (the game's bags, EllesmereUI Bags...)
-- Every bag slot built on the game's item-button template is marked: the game's own bags (separate
-- or combined) and the bag addons that use it (EllesmereUI Bags). Slot buttons are protected frames:
-- nothing is written on them; the marks live in a table of our own, keyed by the button.
local marks = setmetatable({}, { __mode = "k" })
-- icon: the button's icon texture when the button is not a square bag slot (quest rewards): the
-- marks then sit on the icon itself
local function Mark(button, link, icon)
    local r = link and Check(link) or NO
    local m = marks[button]
    if not r.up then
        if m then m.arrow:Hide(); m.text:Hide() end
        return
    end
    if not m then
        m = {}
        m.arrow = button:CreateTexture(nil, "OVERLAY", nil, 7)
        PaintArrow(m.arrow)
        m.arrow:SetSize(16, 16)
        m.text = button:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
        if icon then
            m.arrow:SetPoint("TOPLEFT", icon, "TOPLEFT", -1, 1)
            m.text:SetPoint("TOPRIGHT", icon, "TOPRIGHT", -1, -2)
        else
            m.arrow:SetPoint("TOPLEFT", -1, 1)
            m.text:SetPoint("TOPRIGHT", -1, -2)
        end
        m.text:SetPoint("TOPLEFT", m.arrow, "TOPRIGHT", -2, -3)
        m.text:SetJustifyH("RIGHT")
        if m.text.SetWordWrap then m.text:SetWordWrap(false) end
        m.text:SetTextColor(GREEN[1], GREEN[2], GREEN[3])
        marks[button] = m
    end
    m.arrow:Show()
    -- "+250%" is too wide next to the arrow on a slot: "250%" keeps the width of "+24%"
    local t = r.text or ""
    if #t > 4 then t = t:gsub("^%+", "") end
    m.text:SetText(t); m.text:Show()
end

local GetLink = C_Container and C_Container.GetContainerItemLink or GetContainerItemLink
-- bag and slot of an item button, or nil when it is not a bag slot
local function BagSlot(b)
    if not (b.GetID and b:IsVisible()) then return nil end
    local ok, bag = false, nil
    if b.GetBagID then ok, bag = pcall(b.GetBagID, b) end
    if not (ok and type(bag) == "number") then
        local parent = b.GetParent and b:GetParent()
        bag = parent and parent.GetID and parent:GetID()
    end
    local slot = b:GetID()
    if type(bag) ~= "number" or type(slot) ~= "number" or slot < 1 or bag < 0 or bag > 12 then return nil end
    return bag, slot
end
-- the item buttons of the bags on screen: the game's frames, then every other one built on its
-- container template (found by walking the frames once, then remembered)
local known = setmetatable({}, { __mode = "k" })
local walked = 0
local function Walk()
    if GetTime() - walked < 2 then return end
    walked = GetTime()
    local f = EnumerateFrames and EnumerateFrames()
    while f do
        -- forbidden frames (protected Blizzard or other addons' secure ones) are never touched
        local okF, forbidden = pcall(function() return f.IsForbidden and f:IsForbidden() end)
        local okT, ot = false, nil
        if okF and not forbidden then okT, ot = pcall(f.GetObjectType, f) end
        if not known[f] and okT and ot == "ItemButton" and (f.GetBagID or f.UpdateNewItem or f.SetItemButtonTexture) then
            -- Baganator's slots get its own corner widgets (below): not marked twice
            local ok, dn = pcall(f.GetDebugName, f)
            if not (ok and type(dn) == "string" and dn:find("Baganator", 1, true)) then known[f] = true end
        end
        f = EnumerateFrames(f)
    end
end
local function PaintBags()
    if not Active() then
        for b, m in pairs(marks) do m.arrow:Hide(); m.text:Hide() end
        return
    end
    Walk()
    for b in pairs(known) do
        local bag, slot = BagSlot(b)
        if bag then Mark(b, GetLink and GetLink(bag, slot))
        elseif marks[b] then marks[b].arrow:Hide(); marks[b].text:Hide() end
    end
end
local paintQueued = false
local function PaintSoon()
    if paintQueued then return end
    paintQueued = true
    C_Timer.After(0.2, function() paintQueued = false; PaintBags() end)
end

-- ---------------------------------------------------------------- quest rewards and merchant
-- The same arrow and percent on the rewards of a quest (quest giver and quest log) and on the
-- merchant's items: the percent of each reward is enough to compare them.
local function RewardIcon(btn)
    return btn.Icon or btn.icon or _G[(btn:GetName() or "") .. "IconTexture"]
end
local REWARD_PREFIXES = { "QuestInfoRewardsFrameQuestInfoItem", "QuestInfoItem", "QuestLogItem", "QuestRewardItem" }
local function PaintQuestRewards()
    if not Active() then return end
    local seen, list = {}, {}
    local function add(btn, prefix)
        if btn and not seen[btn] then seen[btn] = true; list[#list + 1] = { btn, prefix } end
    end
    if QuestInfoRewardsFrame and type(QuestInfoRewardsFrame.RewardButtons) == "table" then
        for _, btn in ipairs(QuestInfoRewardsFrame.RewardButtons) do add(btn) end
    end
    for _, prefix in ipairs(REWARD_PREFIXES) do
        for i = 1, 10 do add(_G[prefix .. i], prefix) end
    end
    for _, it in ipairs(list) do
        local btn, prefix = it[1], it[2]
        -- hidden buttons keep their (hidden) marks with them
        if btn.IsVisible and btn:IsVisible() and (btn.objectType == nil or btn.objectType == "item") then
            local kind = btn.type or "choice"
            local ok, link = pcall(function()
                local id = btn:GetID()
                if prefix == "QuestLogItem" then return GetQuestLogItemLink and GetQuestLogItemLink(kind, id) end
                return (QuestFrame and QuestFrame:IsShown() and GetQuestItemLink and GetQuestItemLink(kind, id))
                    or (GetQuestLogItemLink and GetQuestLogItemLink(kind, id))
            end)
            Mark(btn, ok and link or nil, RewardIcon(btn))
        end
    end
end
local questQueued = false
local function QuestSoon()
    if questQueued then return end
    questQueued = true
    C_Timer.After(0.1, function() questQueued = false; PaintQuestRewards() end)
end
if QuestInfo_Display then hooksecurefunc("QuestInfo_Display", function() C_Timer.After(0, PaintQuestRewards) end) end
if QuestLog_UpdateQuestDetails then hooksecurefunc("QuestLog_UpdateQuestDetails", function() C_Timer.After(0, PaintQuestRewards) end) end

-- the merchant's Buy tab (its Buyback tab hides the marks)
local function PaintMerchant()
    for i = 1, (MERCHANT_ITEMS_PER_PAGE or 10) do
        local btn = _G["MerchantItem" .. i .. "ItemButton"]
        if btn then
            if Active() and MerchantFrame and (MerchantFrame.selectedTab or 1) == 1 and btn:IsVisible() then
                local link
                if GetMerchantItemLink then
                    local ok, l = pcall(GetMerchantItemLink, btn:GetID())
                    link = ok and l or nil
                end
                Mark(btn, link)
            else
                Mark(btn, nil)
            end
        end
    end
end
if MerchantFrame_Update then hooksecurefunc("MerchantFrame_Update", PaintMerchant) end

-- ---------------------------------------------------------------- Baganator
-- the IDs Geared Arrows used, so Baganator keeps the corners you had set
local baganator = false
local function HookBaganator()
    if baganator or not (Baganator and Baganator.API) then return end
    baganator = true
    local API = Baganator.API
    pcall(API.RegisterCornerWidget, "WL Helper", "gearedforever", function(_, details)
        return IsUpgrade(details.itemLink)
    end, function(itemButton)
        local arrow = itemButton:CreateTexture(nil, "OVERLAY")
        PaintArrow(arrow)
        arrow:SetSize(16, 16)
        return arrow
    end, { corner = "top_left", priority = 1 })
    pcall(API.RegisterCornerWidget, "WL Helper %", "gearedforever_pct", function(text, details)
        local r = Check(details.itemLink)
        if not r.up then return false end
        text:SetText(r.text)
        return true
    end, function(itemButton)
        local text = itemButton:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
        text:SetTextColor(GREEN[1], GREEN[2], GREEN[3])
        text.sizeFont = true
        return text
    end, { corner = "top_right", priority = 1 })
    if API.RegisterUpgradePlugin then pcall(API.RegisterUpgradePlugin, "WL Helper", "gearedforever", IsUpgrade) end
end

-- ---------------------------------------------------------------- refresh
local queued = false
local function Refresh()
    cache = {}
    wipe(specCache)
    wipe(specByNaowh)
    wipe(explainCache)
    specsMemo, judgedMemo = nil, nil
    gfMemo = nil
    local G = Gear()
    if G then PushGearOptions(G) end
    wipe(nbMemo)
    W.Reset()
    if baganator and Baganator.API.RequestItemButtonsRefresh then pcall(Baganator.API.RequestItemButtonsRefresh) end
    walked = 0
    PaintSoon()
end
WP.RefreshUpgrades = Refresh
local function Soon()
    if queued then return end
    queued = true
    C_Timer.After(0.3, function() queued = false; Refresh() end)
end

-- opening a bag, the game refreshing it, EllesmereUI Bags refreshing its window
for _, name in ipairs({ "ContainerFrame_Update", "OpenAllBags", "ToggleAllBags", "ToggleBackpack", "OpenBag", "ToggleBag" }) do
    if _G[name] then hooksecurefunc(name, function() walked = 0; PaintSoon() end) end
end

-- Shift pressed or released over an item: its tooltip drawn again (the short line or the numbers)
local function RedrawTip()
    if not (Active() and WLWritsDB.upgradeTip ~= false and WLWritsDB.upgradeWhy ~= false) then return end
    for _, tip in ipairs({ GameTooltip, ItemRefTooltip }) do
        if tip and tip.IsShown and tip:IsShown() and tip.GetItem then
            local _, link = tip:GetItem()
            if link then
                if tip.RefreshData then pcall(tip.RefreshData, tip)
                elseif tip == ItemRefTooltip then pcall(tip.SetHyperlink, tip, link)
                else
                    -- the frame under the mouse shows its tooltip again (not in combat)
                    local owner = tip.GetOwner and tip:GetOwner()
                    local enter = owner and owner.GetScript and owner:GetScript("OnEnter")
                    if enter and not (InCombatLockdown and InCombatLockdown()) and (not owner.IsMouseOver or owner:IsMouseOver()) then
                        pcall(enter, owner)
                    end
                end
            end
        end
    end
end
WP.UpgradeRedrawTip = RedrawTip

local ev = CreateFrame("Frame")
pcall(ev.RegisterEvent, ev, "PLAYER_LOGIN")
pcall(ev.RegisterEvent, ev, "MODIFIER_STATE_CHANGED")
for _, e in ipairs({ "PLAYER_EQUIPMENT_CHANGED", "PLAYER_LEVEL_UP", "CHARACTER_POINTS_CHANGED", "GET_ITEM_INFO_RECEIVED", "BAG_UPDATE_DELAYED",
        "PLAYER_TALENT_UPDATE", "TRAIT_CONFIG_UPDATED", "ACTIVE_TALENT_GROUP_CHANGED",
        "QUEST_COMPLETE", "QUEST_DETAIL", "QUEST_PROGRESS", "QUEST_LOG_UPDATE" }) do
    pcall(ev.RegisterEvent, ev, e)
end
ev:SetScript("OnEvent", function(_, e, ...)
    if e == "PLAYER_LOGIN" then
        -- once per login: the spec is only a guess, say how to set it
        C_Timer.After(15, function()
            -- not while the welcome is open or still to come: its spec step asks the same question
            if WP.WelcomeActive and WP.WelcomeActive() then return end
            if W.SpecGuessed and W.SpecGuessed() and WP.ModuleOn and WP.ModuleOn("upgrades") then
                WP.Print(string.format(L("Améliorations : ta spé n'a pas pu être lue dans tes talents, %s est supposée. Choisis-la dans WL Helper, Améliorations, Spé évaluée."), W.SpecName()))
            end
        end)
        specsMemo, judgedMemo, gfMemo = nil, nil, nil
        -- WL Helper Gear scores with your settings (the dungeon overview asks it directly)
        if Gear() then PushGearOptions(Gear()) end
        -- the old "Method" setting (Automatic / WL Helper weights) is gone: nobody stays on weights only
        WLWritsDB.upgradeSource = nil
        WP.ApplyGFTip()
        -- Naowh's lists, weights or their settings changed: judged again
        if WP.NaowhBiS and WP.NaowhBiS.OnChange and not WP._upgradesNaowhHooked then
            WP._upgradesNaowhHooked = true
            WP.NaowhBiS.OnChange(function() if Active() then Soon() end end)
        end
        HookBaganator()
        if EUI_Bags and EUI_Bags.RefreshInventory then
            hooksecurefunc(EUI_Bags, "RefreshInventory", function() walked = 0; PaintSoon() end)
        end
        for _, f in ipairs({ ContainerFrameCombinedBags }) do
            if f and f.HookScript then f:HookScript("OnShow", function() walked = 0; PaintSoon() end) end
        end
        return
    end
    if e == "MODIFIER_STATE_CHANGED" then
        local key = ...
        if key == "LSHIFT" or key == "RSHIFT" then RedrawTip() end
        return
    end
    if not Active() then return end
    if e == "GET_ITEM_INFO_RECEIVED" then
        -- only an item we asked for and that was not loaded: a repaint, not a full refresh
        local id = tonumber((...))
        if not id then return end
        -- an item you wear: every verdict that waited for it is asked again (not for an item the
        -- server does not know, and at most 5 times per item until your gear changes, so an item
        -- that never loads cannot make the bags repaint over and over)
        local worn = false
        if not pending[id] and GetInventoryItemID and select(2, ...) ~= false and (wornHits[id] or 0) < 5 then
            for s = 1, 19 do
                local ok, wid = pcall(GetInventoryItemID, "player", s)
                if ok and type(wid) == "number" and not (issecretvalue and issecretvalue(wid)) and wid == id then worn = true break end
            end
        end
        if not (pending[id] or worn) then return end
        pending[id] = nil
        if worn then wornHits[id] = (wornHits[id] or 0) + 1; wipe(tries); wipe(specCache); wipe(specByNaowh); wipe(explainCache); W.Reset() end
        cache = {}
        PaintSoon()
        if (QuestFrame and QuestFrame:IsShown()) or (QuestLogFrame and QuestLogFrame:IsShown()) then QuestSoon() end
        if MerchantFrame and MerchantFrame:IsShown() then C_Timer.After(0.1, PaintMerchant) end
        return
    end
    if e == "BAG_UPDATE_DELAYED" then PaintSoon(); return end
    -- a quest giver's page or the quest log: the rewards
    if e == "QUEST_COMPLETE" or e == "QUEST_DETAIL" or e == "QUEST_PROGRESS" or e == "QUEST_LOG_UPDATE" then QuestSoon(); return end
    -- what you wear, your level or your talents changed: Geared Forever may answer differently now
    wipe(tries); wipe(wornHits)
    specsMemo, judgedMemo = nil, nil
    Soon()
    -- a new level: the wand's automatic share may change at 40 (the level read again once the game has it)
    if e == "PLAYER_LEVEL_UP" then C_Timer.After(2, Refresh) end
end)
