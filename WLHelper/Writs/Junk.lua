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
    ["Sacs pleins"] = "Bags full",
    ["Jeter %s (vaut %s)"] = "Throw away %s (worth %s)",
    ["Vendre %s (%s)"] = "Sell %s (%s)",
    ["Aucun objet gris ou blanc sans valeur à jeter."] = "No grey or plain white item to throw away.",
    ["%s jeté (valait %s)."] = "%s thrown away (was worth %s).",
    ["%s vendu (%s)."] = "%s sold (%s).",
    ["%s est sur ton curseur : clique dans le monde, puis confirme."] = "%s is on your cursor: click in the world, then confirm.",
    ["Objets gris vendus : %d pour %s."] = "Grey items sold: %d for %s.",
    ["Clic : jeter l'objet le moins cher (gris, ou arme et armure blanches). Au marchand, il est vendu."] =
        "Click: throw away the cheapest item (grey, or a white weapon or armour). At a merchant it is sold.",
    ["Fermer"] = "Close",
    ["impossible en combat."] = "not possible in combat.",
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
    if InCombatLockdown() then WP.Print(L("impossible en combat.")); return end
    local e = Cheapest()
    if not e then WP.Print(L("Aucun objet gris ou blanc sans valeur à jeter.")); return end
    local label = (e.link or e.name) .. (e.count > 1 and (" x" .. e.count) or "")
    if MerchantOpen() then
        C_Container.UseContainerItem(e.bag, e.slot)
        WP.Print(string.format(L("%s vendu (%s)."), label, S.Money(e.value)))
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
            WP.Print(string.format(L("%s jeté (valait %s)."), label, S.Money(e.value)))
        elseif GetCursorInfo() == "item" then
            WP.Print(string.format(L("%s est sur ton curseur : clique dans le monde, puis confirme."), label))
        end
    end)
end

-- ---------------------------------------------------------------- the banner when the bags are full
local banner
local function Banner()
    if banner then return banner end
    local b = CreateFrame("Frame", "WLHelperFreeSlot", UIParent)
    b:SetSize(330, 58); b:SetPoint("TOP", 0, -150); b:SetFrameStrata("DIALOG")
    S.Solid(b, "BACKGROUND", C.bg):SetAllPoints()
    S.Border(b, C.border)
    b.icon = b:CreateTexture(nil, "ARTWORK"); b.icon:SetSize(34, 34); b.icon:SetPoint("LEFT", 12, 0); b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    b.title = S.Text(b, 13, C.warn, true); b.title:SetPoint("TOPLEFT", 56, -10); b.title:SetText(L("Sacs pleins"))
    b.text = S.Text(b, 12, C.dim); b.text:SetPoint("TOPLEFT", 56, -30); b.text:SetWidth(150); b.text:SetWordWrap(false)
    b.go = S.Button(b, L("Libérer une place"), 112, 30, "primary", function() Free(); b:Hide() end)
    b.go:SetPoint("RIGHT", -30, 0)
    b.close = S.Button(b, "x", 20, 20, "secondary", function() b:Hide() end, { L("Fermer") })
    b.close:SetPoint("TOPRIGHT", -4, -4)
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
    b.icon:SetTexture(S.ItemIcon(e.id))
    b.text:SetText(string.format(L("Jeter %s (vaut %s)"), e.name, S.Money(e.value)))
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
    if n > 0 then WP.Print(string.format(L("Objets gris vendus : %d pour %s."), n, S.Money(total))) end
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
    Tip = function() return L("Clic : jeter l'objet le moins cher (gris, ou arme et armure blanches). Au marchand, il est vendu.") end,
}
