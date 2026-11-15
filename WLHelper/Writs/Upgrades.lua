-- Writs/Upgrades.lua: a green arrow on the bag items that are an upgrade for you, and a line in
-- every item tooltip ("WL Helper · Frost: +24%").
--
-- The judge is WL Helper's own stat weights (Writs/Weights.lua): your class, your spec (the talent
-- tree with the most points, or the one picked in Settings > Bags) and what you wear.
-- Bags: the game's own and Baganator (corner widgets and its "upgrade" search).
local ADDON, root = ...
root.Writs = root.Writs or {}
local ns = root.Writs
local WP = ns.WP
local L = ns.L
local W = WP.Weights

ns.AddEnglish({
    ["Améliorations"] = "Upgrades",
    ["Flèche verte sur les objets meilleurs que les tiens"] = "Green arrow on items better than yours",
    ["vide"] = "empty",
    ["emplacement vide"] = "empty slot",
    ["équipé"] = "equipped",
    ["moins bien"] = "worse",
})

local ARROW = "Interface\\Buttons\\Arrow-Up-Up"
local GREEN = { 0.25, 1, 0.3 }

local function Active() return WP.ModuleOn("upgrades") end
WP.UpgradesActive = Active

local cache = {}
local NO = { up = false }

-- { up = true/false, text = "+24%" }
local function Check(link)
    if type(link) ~= "string" or not Active() then return NO end
    local c = cache[link]
    if c then return c end
    local can = W.CanWear(link)
    if can == nil then return NO end   -- item not loaded yet: not cached, asked again later
    local gain = can and W.Gain(link)
    local r
    if gain == "empty" then r = { up = true, text = L("vide") }
    elseif type(gain) == "number" and gain >= 1 then r = { up = true, text = gain >= 999 and "+999%" or ("+" .. math.floor(gain + 0.5) .. "%") }
    else r = NO end
    cache[link] = r
    return r
end
WP.UpgradeCheck = Check
local function IsUpgrade(link) return Check(link).up end

-- ---------------------------------------------------------------- tooltip line
local function TooltipLine(tip, link)
    if not (Active() and link) then return end
    local can = W.CanWear(link)
    if not can then return end
    local spec = W.SpecName()
    local gain = W.Gain(link)
    local text, col
    local equipped = false
    for _, slots in pairs({ W.SLOTS[select(9, ((C_Item and C_Item.GetItemInfo) or GetItemInfo)(link)) or ""] or {} }) do
        for _, s in ipairs(slots) do if GetInventoryItemLink("player", s) == link then equipped = true end end
    end
    if equipped then text, col = L("équipé"), { 0.7, 0.7, 0.7 }
    elseif gain == "empty" then text, col = L("emplacement vide"), GREEN
    elseif type(gain) == "number" then
        local n = math.floor(gain + 0.5)
        text = (n >= 0 and "+" or "") .. n .. "%"
        col = n >= 1 and GREEN or (n <= -1 and { 1, 0.35, 0.3 } or { 0.8, 0.8, 0.8 })
    else return end
    tip:AddDoubleLine("|cffce1918WL Helper|r · " .. spec, text, 1, 1, 1, col[1], col[2], col[3])
    tip:Show()
end
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

-- ---------------------------------------------------------------- the game's own bags
local function Mark(button, link)
    local r = Check(link)
    if not r.up then
        if button.wlUp then button.wlUp:Hide(); button.wlUpText:Hide() end
        return
    end
    if not button.wlUp then
        button.wlUp = button:CreateTexture(nil, "OVERLAY", nil, 7)
        button.wlUp:SetTexture(ARROW)
        button.wlUp:SetVertexColor(GREEN[1], GREEN[2], GREEN[3])
        button.wlUp:SetSize(16, 16)
        button.wlUp:SetPoint("TOPLEFT", -1, 1)
        button.wlUpText = button:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
        button.wlUpText:SetPoint("TOPRIGHT", -1, -2)
        button.wlUpText:SetTextColor(GREEN[1], GREEN[2], GREEN[3])
    end
    button.wlUp:Show()
    button.wlUpText:SetText(r.text or ""); button.wlUpText:Show()
end

local function PaintBlizzard()
    local GetLink = C_Container and C_Container.GetContainerItemLink or GetContainerItemLink
    for f = 1, (NUM_CONTAINER_FRAMES or 13) do
        local frame = _G["ContainerFrame" .. f]
        if frame and frame:IsShown() then
            local bag = frame:GetID()
            for i = 1, (frame.size or 36) do
                local button = _G["ContainerFrame" .. f .. "Item" .. i]
                if button then
                    local link = Active() and GetLink and GetLink(bag, button:GetID())
                    if link then Mark(button, link)
                    elseif button.wlUp then button.wlUp:Hide(); button.wlUpText:Hide() end
                end
            end
        end
    end
end

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
        arrow:SetTexture(ARROW)
        arrow:SetVertexColor(GREEN[1], GREEN[2], GREEN[3])
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
    W.Reset()
    if baganator and Baganator.API.RequestItemButtonsRefresh then pcall(Baganator.API.RequestItemButtonsRefresh) end
    PaintBlizzard()
end
WP.RefreshUpgrades = Refresh
local function Soon()
    if queued then return end
    queued = true
    C_Timer.After(0.3, function() queued = false; Refresh() end)
end

if ContainerFrame_Update then hooksecurefunc("ContainerFrame_Update", function() PaintBlizzard() end) end

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
for _, e in ipairs({ "PLAYER_EQUIPMENT_CHANGED", "PLAYER_LEVEL_UP", "CHARACTER_POINTS_CHANGED", "GET_ITEM_INFO_RECEIVED", "BAG_UPDATE_DELAYED" }) do
    pcall(ev.RegisterEvent, ev, e)
end
ev:SetScript("OnEvent", function(_, e)
    if e == "PLAYER_LOGIN" then HookBaganator(); return end
    if e == "BAG_UPDATE_DELAYED" then C_Timer.After(0.1, PaintBlizzard) else Soon() end
end)
