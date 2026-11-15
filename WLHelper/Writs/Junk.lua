-- Writs/Junk.lua: room in your bags.
-- "Libérer une place" throws away (or sells, at a merchant) the cheapest junk of your bags in one
-- click: a grey item, or a white weapon or armour piece. Nothing else is ever touched: no quest
-- item, no consumable, no trade good, no shirt or tabard, nothing green or better. The game lets
-- an addon delete only poor and common items; the rest stays with you.
-- When the bag is full while looting, a small banner offers the same click.
-- At a merchant, grey items are sold by themselves (a switch), unless EllesmereUI or another addon
-- already does it.
local ADDON, root = ...
root.Writs = root.Writs or {}
local ns = root.Writs
local WP = ns.WP
local L = ns.L
local S = ns.S
local C = S.C

ns.AddEnglish({
    ["Libérer une place"] = "Free a slot",
    ["Tes sacs sont pleins"] = "Your bags are full",
    ["Le moins cher à jeter : %s, qui vaut %s."] = "Cheapest to throw away: %s, worth %s.",
    ["Rien à jeter : aucun objet gris, ni arme ou armure blanche, dans tes sacs."] =
        "Nothing to throw away: no grey item, and no white weapon or armour, in your bags.",
    ["%s jeté : il valait %s."] = "%s thrown away: it was worth %s.",
    ["%s vendu pour %s."] = "%s sold for %s.",
    ["%s est sur ton curseur : clique dans le décor, puis confirme pour le jeter."] = "%s is on your cursor: click in the world, then confirm to throw it away.",
    ["1 objet gris vendu pour %s."] = "1 grey item sold for %s.",
    ["%d objets gris vendus pour %s."] = "%d grey items sold for %s.",
    ["Clic : jeter l'objet le moins cher de tes sacs (gris, ou arme ou armure blanche). Chez un marchand, il est vendu."] =
        "Click: throw away the cheapest item in your bags (grey, or a white weapon or armour). At a merchant it is sold.",
    ["Libère une place en jetant l'objet le moins cher. Rien d'autre n'est touché."] =
        "Frees a slot by throwing away the cheapest item. Nothing else is touched.",
    ["Masquer"] = "Hide",
    ["Clic : masquer ce message"] = "Click: hide this message",
    ["Impossible en combat : réessaie une fois le combat fini."] = "Not possible in combat: try again once the fight is over.",
})

local function Info(bag, slot)
    local ok, info = pcall(C_Container.GetContainerItemInfo, bag, slot)
    return ok and info or nil
end

local function NumBags() return NUM_BAG_SLOTS or 4 end

-- grey: anything; white: weapons and armour only (never shirts, tabards, bags, food or reagents)
local function IsJunk(id, quality)
    if not id or quality == nil or quality > 1 then return false end
    local GetInfo = (C_Item and C_Item.GetItemInfo) or GetItemInfo
    local _, _, _, _, _, _, _, _, equipLoc, _, sell, classID = GetInfo(id)
    if classID == 12 then return false end                   -- quest items: the cleaner's job
    if quality == 0 then return true, sell or 0 end
    if classID ~= 2 and classID ~= 4 then return false end
    if equipLoc == "INVTYPE_BODY" or equipLoc == "INVTYPE_TABARD" or equipLoc == "" or not equipLoc then return false end
    if not sell or sell <= 0 then return false end
    return true, sell
end

-- The cheapest junk stack: { bag, slot, id, name, value, count, link }
local function Cheapest()
    local best
    for bag = 0, NumBags() do
        local n = C_Container.GetContainerNumSlots(bag) or 0
        for slot = 1, n do
            local info = Info(bag, slot)
            if info and info.itemID and not info.isLocked then
                local ok, sell = IsJunk(info.itemID, info.quality)
                if ok then
                    local value = (sell or 0) * (info.stackCount or 1)
                    if not best or value < best.value then
                        best = { bag = bag, slot = slot, id = info.itemID, value = value, count = info.stackCount or 1,
                                 link = info.hyperlink, name = WP.ItemName and WP.ItemName(info.itemID) or tostring(info.itemID) }
                    end
                end
            end
        end
    end
    return best
end

local function MerchantOpen() return MerchantFrame and MerchantFrame:IsShown() end

-- One click: the cheapest junk goes (sold at a merchant, deleted elsewhere).
local function Free()
    if InCombatLockdown() then WP.Print(L("Impossible en combat : réessaie une fois le combat fini."), true); return end
    local e = Cheapest()
    if not e then WP.Print(L("Rien à jeter : aucun objet gris, ni arme ou armure blanche, dans tes sacs."), true); return end
    local label = (e.link or e.name) .. (e.count > 1 and (" x" .. e.count) or "")
    if MerchantOpen() then
        C_Container.UseContainerItem(e.bag, e.slot)
        WP.Print(string.format(L("%s vendu pour %s."), label, S.Money(e.value)))
        return
    end
    ClearCursor()
    C_Container.PickupContainerItem(e.bag, e.slot)
    local kind, cid = GetCursorInfo()
    if kind ~= "item" or cid ~= e.id then ClearCursor(); return end
    local ok = pcall(DeleteCursorItem)
    C_Timer.After(0.2, function()
        local still = Info(e.bag, e.slot)
        if ok and not (still and still.itemID == e.id) then
            WP.Print(string.format(L("%s jeté : il valait %s."), label, S.Money(e.value)))
        elseif GetCursorInfo() == "item" then
            WP.Print(string.format(L("%s est sur ton curseur : clique dans le décor, puis confirme pour le jeter."), label))
        end
    end)
end

-- ---------------------------------------------------------------- the banner when the bags are full
-- A toast at the top of the screen (360 wide, panel fill, 1 px edge): the item's painted icon, the
-- fact, the item it would throw away, and the one action. Its height is measured from the text.
local BANNER_W = 360
local banner
local function Banner()
    if banner then return banner end
    local b = CreateFrame("Frame", "WLHelperFreeSlot", UIParent)
    b.wlOwned = true
    b:SetSize(BANNER_W, 96); b:SetPoint("TOP", 0, -120); b:SetFrameStrata("DIALOG")
    S.Solid(b, "BACKGROUND", C.panel, 0.96):SetAllPoints()
    S.Border(b, C.cardEdge)
    local holder = CreateFrame("Frame", nil, b)
    holder:SetSize(28, 28); holder:SetPoint("TOPLEFT", 12, -12)
    b.icon = holder:CreateTexture(nil, "ARTWORK"); b.icon:SetAllPoints()
    S.Border(holder, C.cardEdge)
    b.title = S.Text(b, S.F.heading, C.fg)
    b.title:SetPoint("TOPLEFT", 52, -12); b.title:SetJustifyH("LEFT")
    b.title:SetText(L("Tes sacs sont pleins"))
    b.text = S.Text(b, S.F.meta, C.muted)
    b.text:SetJustifyH("LEFT"); b.text:SetJustifyV("TOP")
    b.go = S.Button(b, L("Libérer une place"), 0, 28, "primary", function() Free(); b:Hide() end,
        function() return { L("Libérer une place"), L("Libère une place en jetant l'objet le moins cher. Rien d'autre n'est touché."), L("Clic : jeter l'objet le moins cher de tes sacs (gris, ou arme ou armure blanche). Chez un marchand, il est vendu.") } end)
    b.go:SetIcon("trash")
    b.close = S.CloseButton(b, 28, function() b:Hide() end, { L("Masquer"), L("Clic : masquer ce message") })
    b.close:SetPoint("TOPRIGHT", -4, -4)
    -- title and sentence wrap between the icon and the close button; the window grows with them
    function b:Layout()
        local textW = BANNER_W - 52 - 36
        local y = 12 + S.FitText(self.title, 2, textW, self)
        y = math.max(y, 12 + S.F.heading + 2)
        y = y + 3
        self.text:ClearAllPoints(); self.text:SetPoint("TOPLEFT", 52, -y)
        local th = S.FitText(self.text, 2, textW, self)
        y = y + math.max(th, S.F.meta + 2) + 12
        self.go:ClearAllPoints(); self.go:SetPoint("TOPLEFT", 52, -y)
        y = math.max(y + 28 + 12, 12 + 28 + 12)
        self:SetHeight(math.ceil(y))
    end
    b:SetScript("OnShow", function(self) self:SetAlpha(0); root.Tween(self, 0, 1, 0.15, function(v) self:SetAlpha(v) end) end)
    b:Hide()
    banner = b
    return b
end

local lastBanner = 0
local function OfferFree()
    if WLWritsDB.freeSlotPrompt == false or InCombatLockdown() then return end
    if GetTime() - lastBanner < 20 then return end
    local e = Cheapest()
    if not e then return end
    lastBanner = GetTime()
    local b = Banner()
    S.Painted(b.icon, S.ItemIcon(e.id))
    local q = S.QualityColor(e.id)
    local name = S.Hex(q) .. (e.name or "?") .. (e.count > 1 and (" x" .. e.count) or "") .. "|r"
    b.text:SetText(string.format(L("Le moins cher à jeter : %s, qui vaut %s."), name, S.Money(e.value)))
    b:Layout()
    b:Show()
    C_Timer.After(20, function() if b:IsShown() and GetTime() - lastBanner >= 19 then b:Hide() end end)
end

-- ---------------------------------------------------------------- selling greys at merchants
-- EllesmereUI sells greys by itself unless switched off; we never sell twice.
local function OtherSeller()
    if C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded("EllesmereUIQoL") and EllesmereUIDB and EllesmereUIDB.autoSellJunk ~= false then
        return true
    end
    return false
end

local function SellGreys()
    if WLWritsDB.sellGreys == false or OtherSeller() then return end
    local n, total = 0, 0
    for bag = 0, NumBags() do
        for slot = 1, C_Container.GetContainerNumSlots(bag) or 0 do
            local info = Info(bag, slot)
            if info and info.quality == 0 and not info.isLocked and not info.hasNoValue and n < 80 then
                local ok, sell = IsJunk(info.itemID, 0)
                if ok and (sell or 0) > 0 then
                    C_Container.UseContainerItem(bag, slot)
                    n, total = n + 1, total + sell * (info.stackCount or 1)
                end
            end
        end
    end
    if n == 1 then WP.Print(string.format(L("1 objet gris vendu pour %s."), S.Money(total)))
    elseif n > 1 then WP.Print(string.format(L("%d objets gris vendus pour %s."), n, S.Money(total))) end
end

local ev = CreateFrame("Frame")
pcall(ev.RegisterEvent, ev, "MERCHANT_SHOW")
pcall(ev.RegisterEvent, ev, "UI_ERROR_MESSAGE")
ev:SetScript("OnEvent", function(_, e, a1, a2)
    if not (WLWritsDB and WP.ModuleOn("bags")) then return end
    if e == "MERCHANT_SHOW" then
        C_Timer.After(0.3, function() if MerchantOpen() then SellGreys() end end)
    elseif e == "UI_ERROR_MESSAGE" then
        local ok, full = pcall(function() return ERR_INV_FULL and (a2 == ERR_INV_FULL or a1 == ERR_INV_FULL) end)
        if ok and full then OfferFree() end
    end
end)

WP.Junk = {
    Cheapest = Cheapest,
    Free = Free,
    OtherSeller = OtherSeller,
    Offer = OfferFree,
    Tip = function() return L("Clic : jeter l'objet le moins cher de tes sacs (gris, ou arme ou armure blanche). Chez un marchand, il est vendu.") end,
}
