-- Writs/AltClick.lua: Alt + left-click on an item in your bags does the obvious thing for it.
--   Disenchant  you know Enchanting (the Disenchant spell) and the item is a green or blue weapon or
--               armour piece (not a shirt, a tabard or a fishing pole). One click destroys the item,
--               so what could be a mistake is never offered: epics, items of an equipment set, items
--               the Upgrades module marks as upgrades, and (unless altclick.boe) unbound items, which
--               may be worth gold at the auction house;
--   Pick Lock   you are a rogue who knows Pick Lock and the lockbox says "Locked";
--   Comprehend  you are a mage and the item is one of the untranslated scrolls. Only when the
--               stand-alone AltComprehend is not loaded: it already binds the same click.
-- The idea comes from Levjski's AltComprehend: one secure button laid over the hovered bag slot
-- while Alt is held, so the click itself is a hardware click on a secure button (a spell cast
-- on an item cannot be started from addon code). Written anew for WL Helper.
-- The button casts the spell with the bag slot as its target (type "spell", target-bag, target-slot):
-- the secure template gives the item only to a spell waiting for its target, so a cast that fails
-- (cooldown, moving, another cast) never "uses" the item, which for armour would equip and bind it.
-- The game forbids moving or changing a secure button in combat: then nothing happens and the
-- item keeps its normal click. Switches in the options: altclick.on (on by default), altclick.boe
-- (unbound items too, off by default).
local ADDON, root = ...
root.Writs = root.Writs or {}
local ns = root.Writs
local WP = ns.WP
local L = ns.L
local S = ns.S

ns.AddEnglish({
    ["Alt-clic : désenchanter"] = "Alt-click: disenchant",
    ["Alt-clic : crocheter"] = "Alt-click: pick the lock",
    ["Alt-clic : déchiffrer le parchemin"] = "Alt-click: read the scroll",
    ["Alt-clic pour désenchanter / crocheter"] = "Alt-click to disenchant / pick locks",
    ["Alt + clic gauche sur un objet de tes sacs : désenchanter (enchanteur), crocheter un coffret (voleur), déchiffrer un parchemin (mage)."] =
        "Alt + left-click an item in your bags: disenchant it (enchanter), pick a lockbox (rogue), read a scroll (mage).",
    ["Les objets épiques, ceux d'un ensemble d'équipement et tes améliorations ne sont jamais proposés."] =
        "Epic items, items of an equipment set and your upgrades are never offered.",
    ["Avec Baganator, ce clic remplace son Alt-clic (surligner les objets semblables)."] =
        "With Baganator, this click replaces its Alt-click (highlight similar items).",
    ["Désenchanter aussi les objets non liés"] = "Disenchant unbound items too",
    ["Par défaut, seuls les objets liés à toi sont proposés : un objet non lié peut se vendre à l'hôtel des ventes."] =
        "By default only items bound to you are offered: an unbound item may sell at the auction house.",
    ["Alt-clic dans les sacs : activé."] = "Alt-click in bags: on.",
    ["Alt-clic dans les sacs : désactivé."] = "Alt-click in bags: off.",
    ["Ce que tu peux faire : %s."] = "What you can do: %s.",
    ["Rien pour ce personnage : ni Désenchantement, ni Crochetage."] = "Nothing for this character: no Disenchant, no Pick Lock.",
    ["désenchanter"] = "disenchant",
    ["crocheter"] = "pick locks",
    ["déchiffrer les parchemins"] = "read scrolls",
})

local A = {}
WP.AltClick = A

-- Spells, by ID first (any language), then by their names (Forever sometimes renumbers spells:
-- a name only matches a spell you know).
local DISENCHANT = { ids = { 13262 }, names = { "Disenchant", "Désenchanter", "Désenchantement" } }
local PICK_LOCK = { ids = { 1804 }, names = { "Pick Lock", "Crochetage", "Crocheter" } }
-- Forever's Comprehend ranks and its untranslated scrolls (item IDs), as AltComprehend lists them
local COMPREHEND = { ids = { 1296017, 1309965, 1309973, 1310029, 1310030 }, names = {} }
local SCROLLS = {
    [211780] = true, [211784] = true, [211785] = true, [211786] = true, [211787] = true,
    [211853] = true, [211854] = true, [211855] = true, [213543] = true, [213544] = true,
    [213545] = true, [213546] = true, [213547] = true, [281015] = true, [281016] = true,
    [281017] = true, [281018] = true,
}

local LABEL = {
    disenchant = "Alt-clic : désenchanter",
    picklock = "Alt-clic : crocheter",
    comprehend = "Alt-clic : déchiffrer le parchemin",
}

local function IsSecret(v) return issecretvalue ~= nil and issecretvalue(v) end
local function Num(v) if type(v) == "number" and not IsSecret(v) then return v end end
local function pass(ok, ...) if ok then return ... end end
local function safe(f, ...)
    if type(f) ~= "function" then return nil end
    return pass(pcall(f, ...))
end
local function Loaded(name)
    local f = (C_AddOns and C_AddOns.IsAddOnLoaded) or IsAddOnLoaded
    return safe(f, name) and true or false
end

-- ---------------------------------------------------------------- settings
function A.On()
    local d = WLWritsDB and WLWritsDB.altclick
    return not d or d.on ~= false
end
function A.SetOn(v)
    if not WLWritsDB then return end
    WLWritsDB.altclick = type(WLWritsDB.altclick) == "table" and WLWritsDB.altclick or {}
    WLWritsDB.altclick.on = v and true or false
    if not v and A.Hide then A.Hide(true) end
end
-- Unbound (bind-on-equip) items offered for disenchanting too: off by default, they may be worth gold.
function A.BoE()
    local d = WLWritsDB and WLWritsDB.altclick
    return type(d) == "table" and d.boe == true
end
function A.SetBoE(v)
    if not WLWritsDB then return end
    WLWritsDB.altclick = type(WLWritsDB.altclick) == "table" and WLWritsDB.altclick or {}
    WLWritsDB.altclick.boe = v and true or false
end
-- The main switch's description; the Baganator line only when Baganator is there.
function A.OptionDesc()
    local t = L("Alt + clic gauche sur un objet de tes sacs : désenchanter (enchanteur), crocheter un coffret (voleur), déchiffrer un parchemin (mage).")
        .. " " .. L("Les objets épiques, ceux d'un ensemble d'équipement et tes améliorations ne sont jamais proposés.")
    if Loaded("Baganator") then t = t .. " " .. L("Avec Baganator, ce clic remplace son Alt-clic (surligner les objets semblables).") end
    return t
end
function A.BoEDesc()
    return L("Par défaut, seuls les objets liés à toi sont proposés : un objet non lié peut se vendre à l'hôtel des ventes.")
end

-- ---------------------------------------------------------------- the decision (no side effect)
local function Known(id)
    if C_SpellBook and type(C_SpellBook.IsSpellKnown) == "function" then
        if safe(C_SpellBook.IsSpellKnown, id) then return true end
    end
    if safe(IsPlayerSpell, id) then return true end
    return safe(IsSpellKnown, id) and true or false
end
local function NameOf(spell)
    if C_Spell and type(C_Spell.GetSpellName) == "function" then
        local n = safe(C_Spell.GetSpellName, spell)
        if type(n) == "string" and not IsSecret(n) and n ~= "" then return n end
    end
    if C_Spell and type(C_Spell.GetSpellInfo) == "function" then
        local info = safe(C_Spell.GetSpellInfo, spell)
        local n = type(info) == "table" and info.name
        if type(n) == "string" and not IsSecret(n) and n ~= "" then return n end
    end
    local n = safe(GetSpellInfo, spell)
    if type(n) == "string" and not IsSecret(n) and n ~= "" then return n end
end
-- The client's name of the spell when you know it (what the button casts), else nil.
local function LookupSpell(spell)
    for _, id in ipairs(spell.ids) do
        if Known(id) then
            local n = NameOf(id)
            if n then return n end
        end
    end
    -- looked up by name: the game only answers for a spell in your spellbook
    for _, name in ipairs(spell.names) do
        local id
        if C_Spell and type(C_Spell.GetSpellInfo) == "function" then
            local info = safe(C_Spell.GetSpellInfo, name)
            id = type(info) == "table" and info.spellID
        end
        if type(id) == "number" and not IsSecret(id) and Known(id) then return NameOf(id) or name end
    end
end
-- Kept until the spellbook changes (SPELLS_CHANGED): tooltips ask several times a second.
local known = {}
local function KnownSpell(spell)
    local v = known[spell]
    if v == nil then v = LookupSpell(spell) or false; known[spell] = v end
    return v or nil
end
function A.ForgetSpells() known = {} end

local function IsBag(bag) return type(bag) == "number" and bag >= 0 and bag <= 5 end

local function Info(bag, slot)
    if not (C_Container and C_Container.GetContainerItemInfo) then return nil end
    local info = safe(C_Container.GetContainerItemInfo, bag, slot)
    return type(info) == "table" and info or nil
end

local function ItemType(id)
    local f = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
    local _, _, _, equipLoc, _, classID, subID = safe(f, id)
    return classID, subID, equipLoc
end

-- The lines of the item's tooltip (read from the game's data, else from a hidden tooltip)
local scanTip
local function TooltipLines(bag, slot)
    local out = {}
    if C_TooltipInfo and type(C_TooltipInfo.GetBagItem) == "function" then
        local data = safe(C_TooltipInfo.GetBagItem, bag, slot)
        for _, line in ipairs(type(data) == "table" and data.lines or {}) do
            local t = line.leftText
            if type(t) == "string" and not IsSecret(t) then out[#out + 1] = t end
        end
        if #out > 0 then return out end
    end
    if not CreateFrame then return out end
    if not scanTip then
        scanTip = CreateFrame("GameTooltip", "WLHelperAltClickScanTip", nil, "GameTooltipTemplate")
    end
    if not scanTip or not scanTip.SetBagItem then return out end
    safe(scanTip.SetOwner, scanTip, WorldFrame, "ANCHOR_NONE")
    safe(scanTip.ClearLines, scanTip)
    safe(scanTip.SetBagItem, scanTip, bag, slot)
    for i = 1, (safe(scanTip.NumLines, scanTip) or 0) do
        local fs = _G["WLHelperAltClickScanTipTextLeft" .. i]
        local t = fs and fs.GetText and fs:GetText()
        if type(t) == "string" and not IsSecret(t) then out[#out + 1] = t end
    end
    safe(scanTip.Hide, scanTip)
    return out
end

local LOCKED_WORDS = { ["Locked"] = true, ["Verrouillé"] = true }
local function IsLockedBox(bag, slot)
    local word = type(LOCKED) == "string" and not IsSecret(LOCKED) and LOCKED or nil
    for _, t in ipairs(TooltipLines(bag, slot)) do
        if t == word or LOCKED_WORDS[t] then return true end
    end
    return false
end

-- Bound to you? From the slot's info, else the item's location. Unknown counts as unbound (the
-- careful answer: an unbound item is offered only when the player asked for it).
local function IsBound(info, bag, slot)
    if type(info.isBound) == "boolean" and not IsSecret(info.isBound) then return info.isBound end
    if C_Item and type(C_Item.IsBound) == "function" and ItemLocation and type(ItemLocation.CreateFromBagAndSlot) == "function" then
        local loc = safe(ItemLocation.CreateFromBagAndSlot, ItemLocation, bag, slot)
        local b = loc and safe(C_Item.IsBound, loc)
        if type(b) == "boolean" and not IsSecret(b) then return b end
    end
    return false
end

local function InEquipmentSet(bag, slot)
    local f = C_Container and C_Container.GetContainerItemEquipmentSetInfo
    local inSet = safe(f, bag, slot)
    return inSet == true
end

-- The Upgrades module's verdict (an upgrade for one of your specs is kept)
local function IsUpgrade(info)
    if type(WP.UpgradeCheck) ~= "function" or type(info.hyperlink) ~= "string" then return false end
    local r = safe(WP.UpgradeCheck, info.hyperlink)
    return type(r) == "table" and r.up == true
end

-- Shirts, tabards, cosmetic armour and fishing poles never give dust
local NO_DUST_SLOT = { [""] = true, INVTYPE_BODY = true, INVTYPE_TABARD = true, INVTYPE_NON_EQUIP = true, INVTYPE_NON_EQUIP_IGNORE = true }
-- Greens and blues only: an epic costs too much to lose to a wrong click (disenchant it by hand).
local function Disenchantable(info, id, bag, slot)
    local q = Num(info.quality)
    if not q then
        q = Num(safe(C_Item and C_Item.GetItemQualityByID, id)) or Num((select(3, safe(GetItemInfo, id))))
    end
    if not q or q < 2 or q > 3 then return false end
    local classID, subID, equipLoc = ItemType(id)
    if classID ~= 2 and classID ~= 4 then return false end
    if type(equipLoc) ~= "string" or NO_DUST_SLOT[equipLoc] then return false end
    if classID == 4 and subID == 5 then return false end    -- cosmetic
    if classID == 2 and subID == 20 then return false end   -- fishing pole
    if InEquipmentSet(bag, slot) then return false end
    if not A.BoE() and not IsBound(info, bag, slot) then return false end
    if IsUpgrade(info) then return false end
    return true
end

local function PlayerClass()
    local _, class = safe(UnitClass, "player")
    return class
end

-- What Alt + left-click does on this bag slot, or nil. Returns { kind, spell, label, id } where
-- spell is the client's name of the spell, label the French tooltip line (pass it to L()) and id
-- the item it was decided for.
-- Reads the game only: changes nothing, so it can be asked at every tooltip.
function A.ActionFor(bag, slot)
    if not IsBag(bag) or type(slot) ~= "number" then return nil end
    local info = Info(bag, slot)
    if not info or info.isLocked then return nil end   -- isLocked: being moved or traded
    local id = info.itemID
    if type(id) ~= "number" and type(info.hyperlink) == "string" then
        id = tonumber(info.hyperlink:match("item:(%d+)"))
    end
    if type(id) ~= "number" or IsSecret(id) then return nil end
    local class = PlayerClass()
    if SCROLLS[id] then
        if class ~= "MAGE" or Loaded("AltComprehend") then return nil end
        local spell = KnownSpell(COMPREHEND)
        return spell and { kind = "comprehend", spell = spell, label = LABEL.comprehend, id = id } or nil
    end
    -- the tooltip is read only for a box (a misc item, or one holding loot): it is the costly part
    if class == "ROGUE" and (ItemType(id) == 15 or info.hasLoot == true) then
        local spell = KnownSpell(PICK_LOCK)
        if spell and IsLockedBox(bag, slot) then
            return { kind = "picklock", spell = spell, label = LABEL.picklock, id = id }
        end
    end
    if Disenchantable(info, id, bag, slot) then
        local spell = KnownSpell(DISENCHANT)
        if spell then return { kind = "disenchant", spell = spell, label = LABEL.disenchant, id = id } end
    end
    return nil
end

-- What this character can do with it, for /wlh altclick
function A.Status()
    local can = {}
    if KnownSpell(DISENCHANT) then can[#can + 1] = L("désenchanter") end
    if PlayerClass() == "ROGUE" and KnownSpell(PICK_LOCK) then can[#can + 1] = L("crocheter") end
    if PlayerClass() == "MAGE" and not Loaded("AltComprehend") and KnownSpell(COMPREHEND) then
        can[#can + 1] = L("déchiffrer les parchemins")
    end
    WP.Print(A.On() and L("Alt-clic dans les sacs : activé.") or L("Alt-clic dans les sacs : désactivé."))
    if #can > 0 then WP.Print(string.format(L("Ce que tu peux faire : %s."), table.concat(can, ", ")))
    else WP.Print(L("Rien pour ce personnage : ni Désenchantement, ni Crochetage.")) end
end

-- ---------------------------------------------------------------- the secure button
if not CreateFrame or not UIParent then return end

local hover = {}   -- the bag slot under the cursor: bag, slot, owner (its item button)
local overlay = CreateFrame("Button", "WLHelperAltClickButton", UIParent, "SecureActionButtonTemplate")
overlay:SetFrameStrata("TOOLTIP")
if overlay.SetFrameLevel then overlay:SetFrameLevel(100) end
overlay:RegisterForClicks("AnyUp", "AnyDown")
-- only Alt + left button casts: any other button on it does nothing rather than something unexpected
overlay:SetAttribute("alt-type1", "spell")
overlay:Hide()
A.button = overlay

-- a calm mark on the armed slot: the accent at low alpha and a 1 px accent border
local T = (S and S.C) or root.Tok or {}
local accent = T.accent or { 0.85, 0.25, 0.22 }
if overlay.CreateTexture then
    local fill = overlay:CreateTexture(nil, "BACKGROUND")
    if fill then
        fill:SetAllPoints()
        fill:SetColorTexture(accent[1], accent[2], accent[3], 0.22)
    end
end
if S and S.Border then pcall(S.Border, overlay, accent, 1) end

local function Clear()
    hover.bag, hover.slot, hover.owner, hover.action, hover.id = nil, nil, nil, nil, nil
end

local function Unset()
    overlay:SetAttribute("spell", nil)
    overlay:SetAttribute("target-bag", nil)
    overlay:SetAttribute("target-slot", nil)
end

-- Takes the button off the slot (out of combat only: the game forbids it in combat, and the
-- state driver below already hides it there).
function A.Hide(forget)
    if not InCombatLockdown() then
        overlay:Hide()
        overlay:ClearAllPoints()
        Unset()
    end
    if forget then Clear() end
end

-- Lays the button exactly over the item button, in UIParent's coordinates (bag addons scale
-- their frames: the screen rectangle is the only common ground).
local function Place(owner)
    local left, bottom, w, h
    if owner.GetScaledRect then
        left, bottom, w, h = owner:GetScaledRect()
    elseif owner.GetLeft and owner.GetEffectiveScale then
        local s = owner:GetEffectiveScale() or 1
        left, bottom = owner:GetLeft(), owner:GetBottom()
        left, bottom = left and left * s, bottom and bottom * s
        w, h = (owner:GetWidth() or 0) * s, (owner:GetHeight() or 0) * s
    end
    if type(left) ~= "number" or type(bottom) ~= "number" or type(w) ~= "number" or type(h) ~= "number" then return false end
    if IsSecret(left) or IsSecret(w) or w <= 0 or h <= 0 then return false end
    local ui = UIParent:GetEffectiveScale() or 1
    overlay:ClearAllPoints()
    overlay:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", left / ui, bottom / ui)
    overlay:SetSize(w / ui, h / ui)
    return true
end

-- Arms the button on the hovered slot when Alt is held and the item has an action
function A.Arm()
    if InCombatLockdown() then return false end
    local bag, slot, owner = hover.bag, hover.slot, hover.owner
    if not (A.On() and bag and owner and IsAltKeyDown and IsAltKeyDown()) then A.Hide(false); return false end
    -- an item on the cursor or a spell waiting for its target: the click belongs to them
    if (GetCursorInfo and GetCursorInfo()) or (SpellIsTargeting and SpellIsTargeting()) then A.Hide(false); return false end
    if owner.IsMouseOver and not owner:IsMouseOver() then A.Hide(false); return false end
    local act = A.ActionFor(bag, slot)
    -- the slot now holds another item than the tooltip was about (moved, swapped): nothing
    if act and hover.id and act.id ~= hover.id then act = nil end
    hover.action = act
    if not act or not Place(owner) then A.Hide(false); return false end
    -- the slot goes only to a spell waiting for its target: a failed cast leaves the item alone
    overlay:SetAttribute("spell", act.spell)
    overlay:SetAttribute("target-bag", bag)
    overlay:SetAttribute("target-slot", slot)
    overlay:Show()
    return true
end

-- The bag slot a tooltip is about: the item's location from the tooltip data first (works for
-- every bag addon), else what a bag's item button itself says. Anything else (gear you wear,
-- action bars, a merchant, loot) is no bag slot: a wrong slot here would destroy another item.
local function SlotOf(tooltip, data)
    if type(data) == "table" and data.guid and C_Item and type(C_Item.GetItemLocation) == "function" then
        local loc = safe(C_Item.GetItemLocation, data.guid)
        if not (loc and loc.IsBagAndSlot and safe(loc.IsBagAndSlot, loc)) then return nil end
        local bag, slot = safe(loc.GetBagAndSlot, loc)
        return Num(bag), Num(slot)
    end
    local owner = tooltip and tooltip.GetOwner and tooltip:GetOwner()
    if not owner then return nil end
    if owner.GetSlotAndBagID then
        local slot, bag = safe(owner.GetSlotAndBagID, owner)
        if Num(bag) then return bag, Num(slot) end
    end
    if owner.GetBagID and owner.GetID then
        local bag = Num(safe(owner.GetBagID, owner))
        if bag then return bag, Num(safe(owner.GetID, owner)) end
    end
    -- the default bags' older buttons: the bag is the frame's ID, and only on a ContainerFrameN
    local parent = owner.GetParent and owner:GetParent()
    local pname = parent and parent.GetName and safe(parent.GetName, parent)
    if type(pname) == "string" and pname:match("^ContainerFrame%d+$") and owner.GetID and parent.GetID then
        return Num(safe(parent.GetID, parent)), Num(safe(owner.GetID, owner))
    end
end

local function AddHint(tooltip, act)
    local c = T.muted or { 0.6, 0.62, 0.65 }
    tooltip:AddLine(L(act.label), c[1], c[2], c[3])
    tooltip:Show()
end

local function OnItemTooltip(tooltip, data)
    if tooltip ~= GameTooltip or (tooltip.IsForbidden and tooltip:IsForbidden()) then return end
    if not A.On() or InCombatLockdown() then return end
    local owner = tooltip.GetOwner and tooltip:GetOwner()
    if not owner then return end
    if owner == overlay then
        -- our own tooltip (the button took the cursor): the hint again
        if hover.action then AddHint(tooltip, hover.action) end
        return
    end
    local bag, slot = SlotOf(tooltip, data)
    if not IsBag(bag) or type(slot) ~= "number" then A.Hide(true); return end
    -- the tooltip's own item must be the one in that slot
    local want = type(data) == "table" and Num(data.id) or nil
    hover.bag, hover.slot, hover.owner, hover.id = bag, slot, owner, want
    local act = A.ActionFor(bag, slot)
    if act and want and act.id ~= want then act = nil end
    hover.action = act
    -- the hint only while Alt is held (the click is then one away): no clutter on every tooltip
    local alt = IsAltKeyDown and IsAltKeyDown()
    if act and alt then AddHint(tooltip, act) end
    if act and alt then A.Arm() else A.Hide(false) end
end
A.OnItemTooltip = OnItemTooltip

if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, OnItemTooltip)
elseif GameTooltip and hooksecurefunc then
    hooksecurefunc(GameTooltip, "SetBagItem", function(tooltip) OnItemTooltip(tooltip, nil) end)
end

overlay:SetScript("OnEnter", function(self)
    if not (hover.bag and hover.slot) then return end
    local right = self:GetRight()
    GameTooltip:SetOwner(self, (right and GetScreenWidth and right >= GetScreenWidth() / 2) and "ANCHOR_LEFT" or "ANCHOR_RIGHT")
    GameTooltip:SetBagItem(hover.bag, hover.slot)
    GameTooltip:Show()
end)
overlay:SetScript("OnLeave", function()
    GameTooltip:Hide()
    A.Hide(true)
end)
-- the bag closed under the button: take it away
local since = 0
overlay:SetScript("OnUpdate", function(_, elapsed)
    since = since + (elapsed or 0)
    if since < 0.2 then return end
    since = 0
    local owner = hover.owner
    if not owner or (owner.IsVisible and not owner:IsVisible()) then A.Hide(true) end
end)

-- Shown only out of combat and with Alt held, decided by the game itself: in combat the button
-- disappears even though addon code may not touch it.
if RegisterStateDriver then RegisterStateDriver(overlay, "visibility", "[combat] hide; [mod:alt] show; hide") end

local ev = CreateFrame("Frame")
pcall(ev.RegisterEvent, ev, "MODIFIER_STATE_CHANGED")
pcall(ev.RegisterEvent, ev, "BAG_UPDATE_DELAYED")
pcall(ev.RegisterEvent, ev, "PLAYER_REGEN_DISABLED")
pcall(ev.RegisterEvent, ev, "PLAYER_REGEN_ENABLED")
pcall(ev.RegisterEvent, ev, "SPELLS_CHANGED")
ev:SetScript("OnEvent", function(_, e)
    if e == "SPELLS_CHANGED" then
        A.ForgetSpells()
    elseif e == "MODIFIER_STATE_CHANGED" then
        if IsAltKeyDown and IsAltKeyDown() and hover.owner then A.Arm() else A.Hide(false) end
    elseif e == "BAG_UPDATE_DELAYED" then
        -- the item may be gone (disenchanted, opened): ask again for the same slot
        if overlay:IsShown() then A.Arm() end
    else
        A.Hide(true)
    end
end)
