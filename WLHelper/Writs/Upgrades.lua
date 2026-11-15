-- Writs/Upgrades.lua: a green arrow on the bag items that are an upgrade for you, and a line in
-- every item tooltip ("WL Helper · Givre    +24 %", then "Remplace [icon] Old item").
--
-- The judge is WL Helper's own stat weights (Writs/Weights.lua): your class, your spec (the talent
-- tree with the most points, or the one picked in Settings > Upgrades) and what you wear.
-- Bags: the game's own and Baganator (corner widgets and its "upgrade" search).
local ADDON, root = ...
root.Writs = root.Writs or {}
local ns = root.Writs
local WP = ns.WP
local L = ns.L
local W = WP.Weights
local T = ns.S.C

ns.AddEnglish({
    ["(spé à choisir)"] = "(pick your spec)",
    ["Améliorations : ta spé n'a pas pu être lue dans tes talents, %s est supposée. Choisis-la dans Réglages, Améliorations, Spé jugée."] =
        "Upgrades: your spec could not be read from your talents, %s is assumed. Pick it in Settings, Upgrades, Judged spec.",
    ["Améliorations"] = "Upgrades",
    ["Flèche verte sur les objets meilleurs que les tiens"] = "Green arrow on items better than yours",
    ["vide"] = "empty",
    ["%s%d %%"] = "%s%d%%",
    ["Déjà équipé"] = "Already equipped",
    ["Emplacement vide"] = "Empty slot",
    ["Équipable au niveau %d"] = "Equippable at level %d",
    ["Remplace"] = "Replaces",
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
-- WL Helper Gear (our sub-addon, Geared Forever's engine, GPLv3) is asked first through its API
local function Gear() return Loaded("WLHelper_Gear") and WLHelperGear and WLHelperGear.Compare and WLHelperGear or nil end
local function UseGF() return WLWritsDB.upgradeSource ~= "wl" and (Gear() ~= nil or Loaded("GearedForever")) end
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
-- WL Helper Gear is told the spec WL Helper sees (talent tabs read the way that works on this
-- client, or your choice in Settings > Upgrades): its own talent scan can miss on Forever and
-- would then fall back to the class's first spec (a frost mage judged as arcane).
local GEAR_KEY = { aff = "affli" }
local function SyncGearSpec(G)
    local Wt = WP.Weights
    local s = Wt and Wt.Spec and Wt.Spec()
    if not (s and G.SetSpec) then return end
    local key = GEAR_KEY[s[1]] or s[1]
    if key ~= G._wlSpec then
        local ok, done = pcall(G.SetSpec, key)
        G._wlSpec = (ok and done ~= false) and key or nil
    end
end
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
local function GFVerdict(link)
    local G = Gear()
    if G then
        SyncGearSpec(G)
        local ok, res = pcall(G.Compare, link)
        if not ok then return false end
        if not res then return nil end                  -- not cached yet: retried later
        if res.canUse ~= true or res.blocked then return false end
        if res.equipped then return "equipped" end
        if res.empty then
            -- an empty off hand: a main-hand result is in res.other
            if res.other and res.other.pct then return res.other.pct end
            return 1000
        end
        if res.unknown then return nil end
        return res.pct or false
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
    if v == nil then return nil end
    if type(v) == "number" and v > 0 then return true, v >= 1000 and L("vide") or ("+" .. v .. "%"), v end
    return false
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
    local slot = (#slots == 1 and slots[1]) or select(2, W.Gain(link))
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
end

-- the left half of the line: the addon's tag, then the spec judged
local function Tag(spec)
    local guess = W.SpecGuessed and W.SpecGuessed()
    return ns.S.Hex(T.accent) .. "WL Helper|r · " .. (spec or "") .. (guess and (" " .. ns.S.Hex(T.warn) .. L("(spé à choisir)") .. "|r") or "")
end

local function TooltipLine(tip, link)
    if not (Active() and link) or WLWritsDB.upgradeTip == false then return end
    if UseGF() then
        local v = GFVerdict(link)
        local text, col
        local pct = false
        if v == "equipped" then text, col = L("Déjà équipé"), GREY
        elseif type(v) == "number" and v >= 1000 then text, col = L("Emplacement vide"), GREEN
        elseif type(v) == "number" then
            text, pct = Percent(v), true
            col = v > 0 and GREEN or (v < 0 and RED or GREY)
        else return end
        tip:AddDoubleLine(Tag(W.SpecNameFor(GFSpec())), text, T.fg[1], T.fg[2], T.fg[3], col[1], col[2], col[3])
        if pct then InsteadOf(tip, link) end
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
    elseif gain == "empty" then text, col = L("Emplacement vide"), GREEN
    elseif type(gain) == "number" then
        local n = math.floor(gain + 0.5)
        text, pct = Percent(n), true
        col = n >= 1 and GREEN or (n <= -1 and RED or GREY)
    else return end
    -- no tip:Show() here: the game resizes the tooltip itself; calling it from an addon can taint it
    tip:AddDoubleLine(Tag(spec), text, T.fg[1], T.fg[2], T.fg[3], col[1], col[2], col[3])
    if pct then InsteadOf(tip, link) end
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
for _, e in ipairs({ "PLAYER_EQUIPMENT_CHANGED", "PLAYER_LEVEL_UP", "CHARACTER_POINTS_CHANGED", "GET_ITEM_INFO_RECEIVED", "BAG_UPDATE_DELAYED",
        "QUEST_COMPLETE", "QUEST_DETAIL", "QUEST_PROGRESS", "QUEST_LOG_UPDATE" }) do
    pcall(ev.RegisterEvent, ev, e)
end
ev:SetScript("OnEvent", function(_, e, ...)
    if e == "PLAYER_LOGIN" then
        -- once per login: the spec is only a guess, say how to set it
        C_Timer.After(15, function()
            if W.SpecGuessed and W.SpecGuessed() and WP.ModuleOn and WP.ModuleOn("upgrades") then
                WP.Print(string.format(L("Améliorations : ta spé n'a pas pu être lue dans tes talents, %s est supposée. Choisis-la dans Réglages, Améliorations, Spé jugée."), W.SpecName()))
            end
        end)
        WP.ApplyGFTip()
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
        if (QuestFrame and QuestFrame:IsShown()) or (QuestLogFrame and QuestLogFrame:IsShown()) then QuestSoon() end
        if MerchantFrame and MerchantFrame:IsShown() then C_Timer.After(0.1, PaintMerchant) end
        return
    end
    if e == "BAG_UPDATE_DELAYED" then PaintSoon(); return end
    -- a quest giver's page or the quest log: the rewards
    if e == "QUEST_COMPLETE" or e == "QUEST_DETAIL" or e == "QUEST_PROGRESS" or e == "QUEST_LOG_UPDATE" then QuestSoon(); return end
    -- what you wear, your level or your talents changed: Geared Forever may answer differently now
    wipe(tries)
    Soon()
end)
