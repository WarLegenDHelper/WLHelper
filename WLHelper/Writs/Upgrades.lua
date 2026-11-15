-- Writs/Upgrades.lua: a green arrow on the bag items that are an upgrade for you.
--
-- The judge is Geared Forever (its stat weights and its "% vs equipped" for the spec picked in
-- /geared): nothing of it is copied. A hidden tooltip opens on the item, Geared Forever writes
-- its lines there as on any tooltip, and the arrow shows when your spec's line carries its green
-- "up" arrow. Bags: Baganator (corner widgets, its "upgrade" search) and the game's own bags.
-- Taken over from the user's own Geared Arrows: when that addon is still loaded, it keeps the job.
local ADDON, root = ...
root.Writs = root.Writs or {}
local ns = root.Writs
local WP = ns.WP
local L = ns.L

ns.AddEnglish({
    ["Améliorations"] = "Upgrades",
    ["Flèche verte sur les objets meilleurs que les tiens (Geared Forever)"] = "Green arrow on items better than yours (Geared Forever)",
    ["vide"] = "empty",
})

local ARROW_TEX = "GearedForever\\Media\\ArrowUp"
local ARROW_PATH = "Interface\\AddOns\\GearedForever\\Media\\ArrowUp"
local TIP_NAME = "WLHelperUpgradeTip"

local function Loaded(name)
    local f = (C_AddOns and C_AddOns.IsAddOnLoaded) or IsAddOnLoaded
    return f and f(name) and true or false
end
-- On only with Geared Forever, and not twice with Geared Arrows
local function Active()
    return WP.ModuleOn("upgrades") and Loaded("GearedForever") and not Loaded("GearedArrows")
end
WP.UpgradesActive = Active

local tip
local cache, tries = {}, {}
local refreshQueued = false
local Refresh

-- Your spec's line label in Geared Forever ("Frost"), or nil to accept any spec.
local function SpecLabel()
    local _, token = UnitClass("player")
    local key = GearedForeverDB and GearedForeverDB.specs and GearedForeverDB.specs[token]
    if type(key) ~= "string" or key == "" then return nil end
    return key:sub(1, 1):upper() .. key:sub(2)
end

-- true + "+24%", false, or nil when Geared Forever wrote nothing (item not loaded yet).
local function ReadTooltip(link)
    if not tip then
        tip = CreateFrame("GameTooltip", TIP_NAME, nil, "GameTooltipTemplate")
    end
    tip:SetOwner(WorldFrame, "ANCHOR_NONE")
    tip:ClearLines()
    local ok = pcall(tip.SetHyperlink, tip, link)
    if not ok then tip:Hide(); return false end
    local want = SpecLabel()
    local sawHeader, best = false, nil
    for i = 1, tip:NumLines() do
        local left = _G[TIP_NAME .. "TextLeft" .. i]
        local right = _G[TIP_NAME .. "TextRight" .. i]
        local l = left and left:GetText()
        if l and l:find("^Geared Forever") then
            sawHeader = true
        elseif sawHeader and l and (not want or l == want) then
            local r = right and right:GetText()
            if r and r:find(ARROW_TEX, 1, true) then
                -- one-hand weapons can show main and off hand: keep the biggest gain
                local plain = r:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
                for chunk in plain:gmatch("[^,]+") do
                    if chunk:find(ARROW_TEX, 1, true) then
                        local n = tonumber(chunk:match("(%d+)%%"))
                        if chunk:find("empty slot", 1, true) then n = 1000 end
                        if n and (not best or n > best) then best = n end
                    end
                end
                best = best or 1
            end
        end
    end
    tip:Hide()
    if best then
        if best >= 1000 then return true, L("vide") end
        return true, best >= 999 and "+999%" or ("+" .. best .. "%")
    end
    if sawHeader then return false end
    return nil
end

local NO = { up = false }
local function Retry(link)
    tries[link] = (tries[link] or 0) + 1
    if tries[link] > 5 then cache[link] = NO; return end
    if not refreshQueued then
        refreshQueued = true
        C_Timer.After(1, function() refreshQueued = false; Refresh(true) end)
    end
end

-- { up = true/false, text = "+24%" }
local function Check(link)
    if type(link) ~= "string" or not Active() then return NO end
    local cached = cache[link]
    if cached ~= nil then return cached end
    local GetInfo = (C_Item and C_Item.GetItemInfo) or GetItemInfo
    local _, _, _, _, minLevel, _, _, _, _, _, _, classID = GetInfo(link)
    if not classID then Retry(link); return NO end
    local ARMOR = Enum and Enum.ItemClass and Enum.ItemClass.Armor or 4
    local WEAPON = Enum and Enum.ItemClass and Enum.ItemClass.Weapon or 2
    if classID ~= ARMOR and classID ~= WEAPON then cache[link] = NO; return NO end
    if minLevel and minLevel > UnitLevel("player") then cache[link] = NO; return NO end
    local up, text = ReadTooltip(link)
    if up == nil then Retry(link); return NO end
    local result = up and { up = true, text = text } or NO
    cache[link] = result
    return result
end
WP.UpgradeCheck = Check
local function IsUpgrade(link) return Check(link).up end

-- ---------------------------------------------------------------- the game's own bags
local function Mark(button, link)
    local r = Check(link)
    if not r.up then
        if button.wlUp then button.wlUp:Hide(); button.wlUpText:Hide() end
        return
    end
    if not button.wlUp then
        button.wlUp = button:CreateTexture(nil, "OVERLAY", nil, 7)
        button.wlUp:SetTexture(ARROW_PATH)
        button.wlUp:SetSize(14, 14)
        button.wlUp:SetPoint("TOPLEFT", 1, -1)
        button.wlUpText = button:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
        button.wlUpText:SetPoint("TOPRIGHT", -1, -2)
        button.wlUpText:SetTextColor(0.2, 1, 0.2)
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
            local size = (C_Container and C_Container.GetContainerNumSlots and C_Container.GetContainerNumSlots(bag)) or frame.size or 0
            for i = 1, (frame.size or size or 0) do
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
local baganator = false
-- same names and IDs as Geared Arrows: Baganator keeps the corners you had set for it
local function HookBaganator()
    if baganator or not (Baganator and Baganator.API) then return end
    baganator = true
    local API = Baganator.API
    pcall(API.RegisterCornerWidget, "Geared Forever", "gearedforever", function(_, details)
        return IsUpgrade(details.itemLink)
    end, function(itemButton)
        local arrow = itemButton:CreateTexture(nil, "OVERLAY")
        arrow:SetTexture(ARROW_PATH)
        arrow:SetSize(14, 14)
        return arrow
    end, { corner = "top_left", priority = 1 })
    pcall(API.RegisterCornerWidget, "Geared Forever %", "gearedforever_pct", function(text, details)
        local r = Check(details.itemLink)
        if not r.up then return false end
        text:SetText(r.text)
        return true
    end, function(itemButton)
        local text = itemButton:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
        text:SetTextColor(0.2, 1, 0.2)
        text.sizeFont = true
        return text
    end, { corner = "top_right", priority = 1 })
    if API.RegisterUpgradePlugin then pcall(API.RegisterUpgradePlugin, "Geared Forever", "gearedforever", IsUpgrade) end
end

-- ---------------------------------------------------------------- refresh
function Refresh(keepTries)
    cache = {}
    if not keepTries then tries = {} end
    if baganator and Baganator.API.RequestItemButtonsRefresh then pcall(Baganator.API.RequestItemButtonsRefresh) end
    PaintBlizzard()
end
WP.RefreshUpgrades = function() Refresh() end

if ContainerFrame_Update then hooksecurefunc("ContainerFrame_Update", function() PaintBlizzard() end) end

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
ev:RegisterEvent("PLAYER_LEVEL_UP")
ev:RegisterEvent("BAG_UPDATE_DELAYED")
ev:SetScript("OnEvent", function(_, e)
    if e == "PLAYER_LOGIN" then
        if Loaded("GearedForever") and not Loaded("GearedArrows") then HookBaganator() end
        return
    end
    if e == "BAG_UPDATE_DELAYED" then
        C_Timer.After(0.1, PaintBlizzard)
    else
        C_Timer.After(0.2, function() Refresh() end)
    end
end)
