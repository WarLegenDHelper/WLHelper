-- Writs/Clicks.lua: two click helpers, each a switch in Settings > General > Clicks, all off by
-- default (the welcome screen offers them).
--   Alt-click invite (from Alandir's own Alt-Click Invite): Alt + left-click a player's name in chat,
--     a friendly player in the world or a portrait to invite them; an [Invite] link on messages
--     that ask for one ("inv", "invite"...).
--   Shoot: modifier + right-click on a living enemy targets it and starts your ranged attack
--     (Auto Shot, wand, gun, crossbow, bow or throw, from the ranged slot).
--     The key is per class (Shift by default); with "None", right-click alone shoots. Turning
--     shooting on in the welcome screen sets "None" for mages, priests and warlocks, the first
--     time only (WP.OfferWand): right-click alone starts their wand.
-- Bindings only exist while the cursor is over the right kind of unit (secure state drivers), so
-- every other click keeps its normal behaviour. When the stand-alone addon is still loaded, its
-- feature here stays off: no double invite, no double binding.
local ADDON, root = ...
root.Writs = root.Writs or {}
local ns = root.Writs
local WP = ns.WP
local L = ns.L

ns.AddEnglish({
    ["Inviter"] = "Invite",
    ["Aucune"] = "None",
    ["Maj"] = "Shift",
    ["%s est déjà dans ton groupe."] = "%s is already in your group.",
    ["Seul le chef du raid ou un assistant peut inviter : demande au chef de te passer assistant."] =
        "Only the raid leader or an assistant can invite: ask the leader to make you an assistant.",
    ["Seul le chef du groupe peut inviter : demande-lui d'inviter %s ou de te passer chef."] =
        "Only the party leader can invite: ask them to invite %s or to make you leader.",
    ["Ton groupe est plein : passe-le en raid pour inviter plus de monde."] = "Your party is full: convert it to a raid to invite more people.",
})

-- the wand classes: the welcome screen sets their key to "None" (right-click alone shoots)
local WAND_CLASSES = { MAGE = true, PRIEST = true, WARLOCK = true }

local function IsSecret(v) return issecretvalue ~= nil and issecretvalue(v) end
local function Loaded(name)
    local f = (C_AddOns and C_AddOns.IsAddOnLoaded) or IsAddOnLoaded
    return f and f(name) and true or false
end
local modsLoaded = false
local function DB()
    WLWritsDB.clicks = WLWritsDB.clicks or {}
    local d = WLWritsDB.clicks
    -- off until you turn them on (welcome screen or Settings): they change what a click does.
    -- v1: the betas 11-15 had them on by default; they go off once, the welcome screen asks.
    if not d.v then
        for _, k in ipairs({ "chat", "world", "link", "shoot" }) do d[k] = false end
        d.v = 1
    end
    for _, k in ipairs({ "chat", "world", "link", "shoot" }) do if d[k] == nil then d[k] = false end end
    -- the key is per class (saved in d.mods at each apply): every class holds Shift by default;
    -- "None" makes right-click alone shoot (WP.OfferWand sets it for the wand classes, once).
    if not modsLoaded then
        modsLoaded = true
        local _, class = UnitClass("player")
        d.mods = type(d.mods) == "table" and d.mods or {}
        d.wandOffered = type(d.wandOffered) == "table" and d.wandOffered or {}
        -- the former "plain right-click = wand" switch, once: a class that had it on gets "None"
        -- (right-click alone keeps shooting), and the switch is gone
        if d.wands ~= nil then
            if type(d.wands) == "table" then
                for c, on in pairs(d.wands) do if on then d.mods[c] = "NONE" end end
            end
            d.wands = nil
        end
        d.wandRight = nil
        d.shootMod = d.mods[class] or "SHIFT"
    end
    if type(d.words) ~= "table" or #d.words == 0 then d.words = { "inv", "invite", "invit", "invi" } end
    return d
end
WP.ClicksDB = DB

-- Whether a stand-alone addon already does it (then ours stays off)
function WP.ClickOwner(feature)
    if feature == "invite" and Loaded("AltClickInvite") then return "Alt-Click Invite" end
    if feature == "shoot" and (Loaded("ForeverRightClickShoot_Camelot") or Loaded("ForeverRightClickShoot")) then return "Forever Right-Click Shoot" end
end

-- ================================================================ invite
local LINK_PREFIX = "addon:wlhelperinvite:"
local function ShortName(name) return Ambiguate and Ambiguate(name, "none") or name end
local function InGroup(name) return (UnitInParty(name) or UnitInRaid(name)) and true or false end

local function Invite(name)
    if type(name) ~= "string" or IsSecret(name) or name == "" then return end
    local short = ShortName(name)
    if short == UnitName("player") then return end
    if InGroup(short) then WP.Print(string.format(L("%s est déjà dans ton groupe."), short)); return end
    -- a party has no assistants: only its leader invites; in a raid, assistants can too
    if IsInRaid() then
        if not (UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")) then
            WP.Print(L("Seul le chef du raid ou un assistant peut inviter : demande au chef de te passer assistant.")); return
        end
    elseif IsInGroup() and not UnitIsGroupLeader("player") then
        WP.Print(string.format(L("Seul le chef du groupe peut inviter : demande-lui d'inviter %s ou de te passer chef."), short)); return
    end
    if IsInGroup() and not IsInRaid() and GetNumSubgroupMembers() >= (MAX_PARTY_MEMBERS or 4) then
        WP.Print(L("Ton groupe est plein : passe-le en raid pour inviter plus de monde.")); return
    end
    local invite = (C_PartyInfo and C_PartyInfo.InviteUnit) or InviteUnit
    if invite then invite(name) end
end

-- the choices of key for shooting, for a segmented control
function WP.ShootKeys()
    return { { "NONE", L("Aucune") }, { "SHIFT", L("Maj") }, { "CTRL", "Ctrl" }, { "ALT", "Alt" } }
end

local function InviteOn(key)
    return not WP.ClickOwner("invite") and DB()[key]
end

-- an [Invite] link on messages that ask for an invite
local function AsksForInvite(msg)
    local text = msg:gsub("|H.-|h(.-)|h", "%1"):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):lower()
    for _, word in ipairs(DB().words) do
        if text:find("%f[%w]" .. word:lower():gsub("%p", "%%%0") .. "%f[%W]") then return true end
    end
    return false
end
local function InviteFilter(_, _, msg, sender, ...)
    if not (WLWritsDB and InviteOn("link")) then return false end
    if type(msg) ~= "string" or type(sender) ~= "string" or IsSecret(msg) or IsSecret(sender) then return false end
    if msg:find(LINK_PREFIX, 1, true) or not AsksForInvite(msg) then return false end
    local short = ShortName(sender)
    if short == UnitName("player") or InGroup(short) then return false end
    -- the link colour of the design system (accentSoft #E8605A)
    return false, msg .. " " .. ("|cffe8605a|H%s%s|h[%s]|h|r"):format(LINK_PREFIX, sender, L("Inviter")), sender, ...
end
local AddFilter = (ChatFrameUtil and ChatFrameUtil.AddMessageEventFilter) or ChatFrame_AddMessageEventFilter
if AddFilter then
    for _, e in ipairs({ "CHAT_MSG_SAY", "CHAT_MSG_YELL", "CHAT_MSG_WHISPER", "CHAT_MSG_CHANNEL", "CHAT_MSG_GUILD", "CHAT_MSG_OFFICER" }) do
        AddFilter(e, InviteFilter)
    end
end
-- runs after the game handled the click: nothing of Blizzard's is replaced
if SetItemRef then
    hooksecurefunc("SetItemRef", function(link, _, button)
        if type(link) ~= "string" or IsSecret(link) or not WLWritsDB then return end
        local requester = link:sub(1, #LINK_PREFIX) == LINK_PREFIX and link:sub(#LINK_PREFIX + 1)
        if requester then Invite(requester); return end
        if InviteOn("chat") and button == "LeftButton" and IsAltKeyDown() and not IsShiftKeyDown() and not IsControlKeyDown() then
            local player = link:match("^player:([^:]+)")
            if player then Invite(player) end
        end
    end)
end

-- the world: Alt + left-click a friendly player (a binding that only exists over one)
local inviteButton = CreateFrame("Button", "WLHelperInviteButton", UIParent, "SecureActionButtonTemplate")
inviteButton:RegisterForClicks("AnyDown", "AnyUp")
inviteButton:SetAttribute("type", "macro")
inviteButton:SetAttribute("macrotext", "/target [@mouseover,help,nodead]\n/invite\n/targetlasttarget")
inviteButton:SetScript("PreClick", function(self, _, down)
    if InCombatLockdown() then return end   -- the secure macro invites
    -- a friendly NPC: Alt + left-click keeps targeting it, as without the addon
    if not UnitIsPlayer("mouseover") then
        self:SetAttribute("macrotext", "/target [@mouseover]")
        return
    end
    self:SetAttribute("type", nil)
    local cvarBool = (C_CVar and C_CVar.GetCVarBool) or GetCVarBool
    local keyDown = cvarBool and cvarBool("ActionButtonUseKeyDown") and true or false
    if down ~= keyDown then return end
    if UnitIsUnit("mouseover", "player") then return end
    Invite(GetUnitName("mouseover", true))
end)
inviteButton:SetScript("PostClick", function(self)
    if InCombatLockdown() then return end
    self:SetAttribute("type", "macro")
    self:SetAttribute("macrotext", "/target [@mouseover,help,nodead]\n/invite\n/targetlasttarget")
end)
local inviteDriver = CreateFrame("Frame", "WLHelperInviteDriver", UIParent, "SecureHandlerStateTemplate")
inviteDriver:SetFrameRef("button", inviteButton)
inviteDriver:SetAttribute("_onstate-invite", [[
    if newstate == "on" then self:SetBindingClick(true, "ALT-BUTTON1", self:GetFrameRef("button"))
    else self:ClearBindings() end
]])

-- portraits: on every mouse press, the unit under the cursor (its own click still happens)
local function UnitUnderCursor()
    local focus = GetMouseFoci and GetMouseFoci()[1] or (GetMouseFocus and GetMouseFocus())
    for _ = 1, 6 do
        if not focus or focus == WorldFrame then return nil end
        if focus.IsForbidden and focus:IsForbidden() then return nil end
        local ok, unit = pcall(focus.GetAttribute, focus, "unit")
        if ok and type(unit) == "string" and not IsSecret(unit) and unit ~= "" then return unit end
        focus = focus.GetParent and focus:GetParent()
    end
end

-- ================================================================ shoot
local SUB = Enum and Enum.ItemWeaponSubclass or {}
local SHOT_BY_WEAPON = {
    [SUB.Wand or 19] = 5019,       -- Shoot (wand)
    [SUB.Bows or 2] = 75,          -- Auto Shot
    [SUB.Guns or 3] = 75,
    [SUB.Crossbow or 18] = 75,
    [SUB.Thrown or 16] = 2764,     -- Throw
}
local function ShotSpell()
    local link = GetInventoryItemLink("player", INVSLOT_RANGED or 18)
    if not link then return nil end
    local GetInfo = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
    local _, _, _, _, _, classID, subID = GetInfo(link)
    local spell = classID == 2 and SHOT_BY_WEAPON[subID]
    -- hunters without Auto Shot learned yet, or another class with a bow: the weapon's own shot
    local known = ns.SpellKnown(75)
    if spell == 75 and not known then
        spell = ({ [SUB.Bows or 2] = 2480, [SUB.Guns or 3] = 7918, [SUB.Crossbow or 18] = 7919 })[subID]
    end
    if not spell then return nil end
    return (C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(spell)) or (GetSpellInfo and GetSpellInfo(spell)), spell
end

-- The welcome screen turns shooting on: the first time for this class, mages, priests and
-- warlocks get the key "None", so right-click alone starts their wand. Once per class, so a later
-- choice is never overwritten; choosing a key (Settings or welcome screen) calls it first too.
function WP.OfferWand()
    local d = DB()
    local _, class = UnitClass("player")
    if d.wandOffered[class] then return end
    d.wandOffered[class] = true
    if WAND_CLASSES[class] then d.shootMod = "NONE" end
end

local shootButton = CreateFrame("Button", "WLHelperShootButton", UIParent, "SecureActionButtonTemplate")
shootButton:RegisterForClicks("AnyDown", "AnyUp")
shootButton:SetAttribute("type", "macro")
local shootDriver = CreateFrame("Frame", "WLHelperShootDriver", UIParent, "SecureHandlerStateTemplate")
shootDriver:SetFrameRef("button", shootButton)
-- "on": the chosen key + right-click; "plain": right-click alone (the key "None"); "off": nothing
shootDriver:SetAttribute("_onstate-shoot", [[
    self:ClearBindings()
    if newstate == "on" then self:SetBindingClick(true, self:GetAttribute("key"), self:GetFrameRef("button"))
    elseif newstate == "plain" then self:SetBindingClick(true, "BUTTON2", self:GetFrameRef("button")) end
]])

-- ================================================================ applying the switches
local pending = false
function WP.ApplyClicks()
    if not WLWritsDB then return end
    if InCombatLockdown() then pending = true; return end
    pending = false
    local d = DB()
    local _, class = UnitClass("player")
    d.mods = type(d.mods) == "table" and d.mods or {}
    d.mods[class] = d.shootMod
    UnregisterStateDriver(inviteDriver, "invite"); inviteDriver:SetAttribute("state-invite", "off"); ClearOverrideBindings(inviteDriver)
    if InviteOn("world") then RegisterStateDriver(inviteDriver, "invite", "[@mouseover,help,nodead] on; off") end
    UnregisterStateDriver(shootDriver, "shoot"); shootDriver:SetAttribute("state-shoot", "off"); ClearOverrideBindings(shootDriver)
    local spell = ShotSpell()
    if d.shoot and not WP.ClickOwner("shoot") and spell then
        shootButton:SetAttribute("macrotext", "/target [@mouseover,harm,nodead]\n/cast !" .. spell)   -- "!" never toggles Auto Shot / Shoot off
        if d.shootMod == "NONE" then
            -- right-click alone on an enemy; with any key held, right-click does what it always did
            RegisterStateDriver(shootDriver, "shoot", "[@mouseover,harm,nodead,nomod] plain; off")
        else
            shootDriver:SetAttribute("key", d.shootMod .. "-BUTTON2")
            RegisterStateDriver(shootDriver, "shoot", "[@mouseover,harm,nodead,mod:" .. d.shootMod:lower() .. "] on; off")
        end
    end
end

local ev = CreateFrame("Frame")
pcall(ev.RegisterEvent, ev, "PLAYER_LOGIN")
pcall(ev.RegisterEvent, ev, "PLAYER_REGEN_ENABLED")
pcall(ev.RegisterEvent, ev, "PLAYER_EQUIPMENT_CHANGED")
pcall(ev.RegisterEvent, ev, "SPELLS_CHANGED")
ev:SetScript("OnEvent", function(self, e, a1)
    if e == "PLAYER_LOGIN" then
        WP.ApplyClicks()
        pcall(self.RegisterEvent, self, "GLOBAL_MOUSE_DOWN")
    elseif e == "GLOBAL_MOUSE_DOWN" then
        if a1 ~= "LeftButton" or not IsAltKeyDown() or IsShiftKeyDown() or IsControlKeyDown() or not InviteOn("world") then return end
        local unit = UnitUnderCursor()
        if unit and UnitIsPlayer(unit) and not UnitIsUnit(unit, "player") and not UnitInParty(unit) and not UnitInRaid(unit) then
            Invite(GetUnitName(unit, true))
        end
    elseif e == "PLAYER_REGEN_ENABLED" then
        if pending then WP.ApplyClicks() end
    else
        WP.ApplyClicks()
    end
end)
