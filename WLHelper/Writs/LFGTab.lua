-- Writs/LFGTab.lua: a WL Helper tab on the game's Group Finder (LFGParentFrame), under its side
-- tabs like LFG Forever's (report: "can't you make a button like that on the LFG, like LFG
-- Forever?"). A launcher only: a click closes the game's window (out of combat) and opens WL
-- Helper's Groups window on "Trouver un groupe".
--
-- Written for WL Helper (CC BY-NC-SA). Taint rules, the same as the Finder's: never a field on a
-- Blizzard frame, never a Blizzard LFG panel shown, read or hooked; the tab is our own frame from
-- LargeSideTabButtonTemplate (Blizzard_SharedXML, loaded always), its hooks are on our own frame.
local ADDON, root = ...
root.Writs = root.Writs or {}
local ns = root.Writs
local WP = ns.WP
local L = ns.L

if ns.AddEnglish then ns.AddEnglish({ ["Commandes d'artisanat"] = "Crafting orders" }) end

-- the tabs, top to bottom: { frame name, icon, tooltip, module, open }
local DEFS = {
    { "WLHelperLFGTab", nil, "Trouver un groupe", "events", function() if WP.ShowEventsTab then WP.ShowEventsTab("find") end end },
    { "WLHelperLFGOrdersTab", "Interface\\Icons\\Trade_BlackSmithing", "Commandes d'artisanat", "orders",
      function() if WP.ShowOrdersTab then WP.ShowOrdersTab("find") end end },
}
local tabs = {}

-- under the last side tab there: LFG Forever's when it has one, else the game's Who tab; each of
-- ours under the one before
local function Anchor()
    local parent = _G.LFGParentFrame
    if not parent then return end
    local above = _G.LFGForeverBlizzardTab or parent.WhoListingTab
    for _, t in ipairs(tabs) do
        if not above then return end
        t:ClearAllPoints()
        t:SetPoint("TOPLEFT", above, "BOTTOMLEFT", 0, -2)
        above = t
    end
end

local function Open(def)
    local off = WP.ModuleOff or function() return false end
    if off(def[4]) then return end
    if not (InCombatLockdown and InCombatLockdown()) and HideUIPanel and _G.LFGParentFrame then
        pcall(HideUIPanel, _G.LFGParentFrame)
    end
    def[5]()
end

local function Build()
    if #tabs > 0 or not _G.LFGParentFrame then return end
    for _, def in ipairs(DEFS) do
        local ok, t = pcall(CreateFrame, "Frame", def[1], _G.LFGParentFrame, "LargeSideTabButtonTemplate")
        if ok and t then
            tabs[#tabs + 1] = t
            if t.Icon then
                t.Icon:SetTexture(def[2] or root.LOGO or ("Interface\\AddOns\\" .. ADDON .. "\\Media\\Logo64"))
                t.Icon:SetSize(30, 30)
            end
            if t.SetFillToInterior then t:SetFillToInterior(true) end
            if t.SetChecked then t:SetChecked(false) end
            t.tooltipText = "WL Helper : " .. L(def[3])
            if t.SetCustomOnMouseUpHandler then
                t:SetCustomOnMouseUpHandler(function(_, button, upInside)
                    if button == "LeftButton" and upInside then Open(def) end
                end)
            else
                t:SetScript("OnMouseUp", function(_, button) if button == "LeftButton" then Open(def) end end)
            end
            -- LFG Forever may build its tab after ours: placed again each time the window shows
            t:HookScript("OnShow", Anchor)
        end
    end
    Anchor()
end
WP.LFGTab = function(k) return tabs[k or 1] end
WP.BuildLFGTab = Build

local ev = CreateFrame("Frame")
ev:RegisterEvent("ADDON_LOADED")
ev:RegisterEvent("PLAYER_LOGIN")
ev:SetScript("OnEvent", function(_, e, name)
    if e == "ADDON_LOADED" and name ~= "Blizzard_GroupFinder_VanillaStyle" and name ~= ADDON then return end
    if _G.LFGParentFrame then pcall(Build) end
end)
