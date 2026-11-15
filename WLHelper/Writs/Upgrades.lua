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

-- ---------------------------------------------------------------- Geared Forever, when installed
-- Its ranking is finer than our weights (per level range, per spec): when it is installed, its own
-- verdict is read live from the item's tooltip (nothing of it is copied: it writes its lines in a
-- hidden tooltip as on any tooltip, and the line of your spec carries its green "up" arrow).
-- Settings > Upgrades > Calculation: "auto" (Geared Forever when installed) or WL Helper's weights.
local GF_ARROW = "GearedForever\\Media\\ArrowUp"
local function Loaded(name)
    local f = (C_AddOns and C_AddOns.IsAddOnLoaded) or IsAddOnLoaded
    return f and f(name) and true or false
end
local function UseGF() return WLWritsDB.upgradeSource ~= "wl" and Loaded("GearedForever") end
WP.UpgradeUsesGF = UseGF
local gfTip
local function GFSpec()
    local _, token = UnitClass("player")
    local key = GearedForeverDB and GearedForeverDB.specs and GearedForeverDB.specs[token]
    if type(key) ~= "string" or key == "" then return nil end
    return key:sub(1, 1):upper() .. key:sub(2)
end
-- true + "+24%" / false / nil when Geared Forever wrote nothing yet (item not loaded)
local function GFRead(link)
    if not gfTip then gfTip = CreateFrame("GameTooltip", "WLHelperGFTip", nil, "GameTooltipTemplate") end
    gfTip:SetOwner(WorldFrame, "ANCHOR_NONE")
    gfTip:ClearLines()
    if not pcall(gfTip.SetHyperlink, gfTip, link) then gfTip:Hide(); return false end
    local want = GFSpec()
    local saw, best = false, nil
    for i = 1, gfTip:NumLines() do
        local left = _G["WLHelperGFTipTextLeft" .. i]
        local right = _G["WLHelperGFTipTextRight" .. i]
        local l = left and left:GetText()
        if l and l:find("^Geared Forever") then saw = true
        elseif saw and l and (not want or l == want) then
            local r = right and right:GetText()
            if r and r:find(GF_ARROW, 1, true) then
                local plain = r:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
                for chunk in plain:gmatch("[^,]+") do
                    if chunk:find(GF_ARROW, 1, true) then
                        local n = tonumber(chunk:match("(%d+)%%"))
                        if chunk:find("empty slot", 1, true) then n = 1000 end
                        if n and (not best or n > best) then best = n end
                    end
                end
                best = best or 1
            end
        end
    end
    gfTip:Hide()
    if best then return true, best >= 1000 and L("vide") or ("+" .. best .. "%"), best end
    if saw then return false end
    return nil
end
local tries, retryQueued = {}, false
-- item IDs asked while not loaded yet: only their GET_ITEM_INFO_RECEIVED repaints the bags
local pending = {}
local function Pending(link)
    local id = tonumber(link:match("item:(%d+)"))
    if id then pending[id] = true end
end

-- { up = true/false, text = "+24%" }
local function Check(link)
    if type(link) ~= "string" or not Active() then return NO end
    local c = cache[link]
    if c then return c end
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
            tries[link] = (tries[link] or 0) + 1
            if tries[link] > 5 then cache[link] = NO; return NO end
            if not retryQueued then
                retryQueued = true
                C_Timer.After(1, function() retryQueued = false; cache = {}; if WP.RefreshUpgrades then WP.RefreshUpgrades() end end)
            end
            return NO
        end
        local r = (up and (n or 0) >= (WLWritsDB.upgradeMin or 1)) and { up = true, text = text } or NO
        cache[link] = r
        return r
    end
    local can = W.CanWear(link)
    if can == nil then Pending(link); return NO end   -- item not loaded yet: not cached, asked again later
    local gain = can and W.Gain(link)
    local r
    if gain == "empty" then r = { up = true, text = L("vide") }
    elseif type(gain) == "number" and gain >= (WLWritsDB.upgradeMin or 1) then r = { up = true, text = gain >= 999 and "+999%" or ("+" .. math.floor(gain + 0.5) .. "%") }
    else r = NO end
    cache[link] = r
    return r
end
WP.UpgradeCheck = Check
local function IsUpgrade(link) return Check(link).up end

-- ---------------------------------------------------------------- tooltip line
local function TooltipLine(tip, link)
    if not (Active() and link) or WLWritsDB.upgradeTip == false or UseGF() then return end
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
    -- no tip:Show() here: the game resizes the tooltip itself; calling it from an addon can taint it
    tip:AddDoubleLine("|cffce1918WL Helper|r · " .. spec, text, 1, 1, 1, col[1], col[2], col[3])
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

-- ---------------------------------------------------------------- bag slots (the game's bags, EllesmereUI Bags...)
-- Every bag slot built on the game's item-button template is marked: the game's own bags (separate
-- or combined) and the bag addons that use it (EllesmereUI Bags). Slot buttons are protected frames:
-- nothing is written on them; the marks live in a table of our own, keyed by the button.
local marks = setmetatable({}, { __mode = "k" })
local function Mark(button, link)
    local r = link and Check(link) or NO
    local m = marks[button]
    if not r.up then
        if m then m.arrow:Hide(); m.text:Hide() end
        return
    end
    if not m then
        m = {}
        m.arrow = button:CreateTexture(nil, "OVERLAY", nil, 7)
        m.arrow:SetTexture(ARROW)
        m.arrow:SetVertexColor(GREEN[1], GREEN[2], GREEN[3])
        m.arrow:SetSize(16, 16)
        m.arrow:SetPoint("TOPLEFT", -1, 1)
        m.text = button:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
        m.text:SetPoint("TOPRIGHT", -1, -2)
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
        if not known[f] and f.GetObjectType and f:GetObjectType() == "ItemButton" and (f.GetBagID or f.UpdateNewItem or f.SetItemButtonTexture) then
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

local ev = CreateFrame("Frame")
pcall(ev.RegisterEvent, ev, "PLAYER_LOGIN")
for _, e in ipairs({ "PLAYER_EQUIPMENT_CHANGED", "PLAYER_LEVEL_UP", "CHARACTER_POINTS_CHANGED", "GET_ITEM_INFO_RECEIVED", "BAG_UPDATE_DELAYED" }) do
    pcall(ev.RegisterEvent, ev, e)
end
ev:SetScript("OnEvent", function(_, e, ...)
    if e == "PLAYER_LOGIN" then
        HookBaganator()
        if EUI_Bags and EUI_Bags.RefreshInventory then
            hooksecurefunc(EUI_Bags, "RefreshInventory", function() walked = 0; PaintSoon() end)
        end
        for _, f in ipairs({ ContainerFrameCombinedBags }) do
            if f and f.HookScript then f:HookScript("OnShow", function() walked = 0; PaintSoon() end) end
        end
        return
    end
    if not Active() then return end
    if e == "GET_ITEM_INFO_RECEIVED" then
        -- only an item we asked for and that was not loaded: a repaint, not a full refresh
        local id = tonumber((...))
        if not (id and pending[id]) then return end
        pending[id] = nil
        cache = {}
        PaintSoon()
        return
    end
    if e == "BAG_UPDATE_DELAYED" then PaintSoon(); return end
    -- what you wear, your level or your talents changed: Geared Forever may answer differently now
    wipe(tries)
    Soon()
end)
