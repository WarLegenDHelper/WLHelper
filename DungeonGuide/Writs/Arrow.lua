-- Arrow.lua: the GPS arrow. It points at the current step's spot, colours itself by how far you
-- face away from it, and says what to do: ride to a flight master, take a flight (a button takes
-- it while the flight map is open), a zeppelin or a boat, or cast a teleport (a button casts it).
local ADDON, root = ...
-- The Writs module of WL Helper keeps its own table inside the addon's namespace.
root.Writs = root.Writs or {}
local ns = root.Writs
local WP = ns.WP
local L = ns.L
local GPS = WP.GPS

local arrow, teleport

local function Meters(yards)
    if ns.English() then return string.format(L("%d m"), math.floor(yards + 0.5)) end
    return string.format(L("%d m"), math.floor(yards * 0.9144 + 0.5))
end

local function Minutes(seconds)
    if not seconds then return "" end
    local m = math.max(1, math.floor(seconds / 60 + 0.5))
    return string.format(L("~%d min"), m)
end

-- The teleport button is a secure spell button: its spell is only changed out of combat.
local shownSpell = false
local function SetTeleport(leg)
    if not teleport or InCombatLockdown() then return end
    local spell = leg and leg.to.spell or nil
    if spell == shownSpell then return end   -- only when it changes
    shownSpell = spell
    if leg then
        teleport:SetAttribute("type", "spell")
        teleport:SetAttribute("spell", leg.to.spell)
        teleport.label:SetText(string.format(L("Lancer : %s"), leg.to.name))
        teleport:Show()
    else
        teleport:Hide()
    end
end

local function Build()
    local S = ns.Style
    local ar, ag, ab = S.Accent()
    arrow = CreateFrame("Frame", "WLGPSArrow", UIParent)
    arrow:SetSize(230, 124)
    local pos = WLWritsDB.arrowPos
    if pos then arrow:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4]) else arrow:SetPoint("TOP", 0, -150) end
    arrow:SetFrameStrata("MEDIUM")
    arrow:SetClampedToScreen(true)
    arrow:SetMovable(true)
    arrow:EnableMouse(true)
    arrow:RegisterForDrag("LeftButton")
    arrow:SetScript("OnDragStart", function(self) if not InCombatLockdown() then self:StartMoving() end end)
    arrow:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local p, _, rp, x, y = self:GetPoint()
        WLWritsDB.arrowPos = { p, rp, x, y }
    end)
    S.Solid(arrow, "BACKGROUND", 0.069, 0.058, 0.047, 0.82):SetAllPoints()
    S.Border(arrow, 1, 1, 1, 0.08)
    local top = S.Solid(arrow, "ARTWORK", ar, ag, ab, 0.9)
    top:SetPoint("TOPLEFT"); top:SetPoint("TOPRIGHT"); top:SetHeight(2)

    arrow.tex = arrow:CreateTexture(nil, "ARTWORK")
    arrow.tex:SetSize(44, 44)
    arrow.tex:SetPoint("TOPLEFT", 8, -10)
    arrow.tex:SetTexture("Interface\\Minimap\\MinimapArrow")

    arrow.step = S.Text(arrow, 13)
    arrow.step:SetPoint("TOPLEFT", 60, -10)
    arrow.step:SetPoint("TOPRIGHT", -22, -10)
    arrow.step:SetWordWrap(true)
    arrow.step:SetHeight(32)
    arrow.step:SetJustifyV("TOP")
    arrow.dist = S.Text(arrow, 12)
    arrow.dist:SetPoint("TOPLEFT", 60, -44)
    arrow.dist:SetTextColor(ar, ag, ab)
    arrow.next = S.Text(arrow, 10)
    arrow.next:SetPoint("TOPLEFT", 10, -62)
    arrow.next:SetPoint("TOPRIGHT", -10, -62)
    arrow.next:SetTextColor(1, 1, 1, 0.53)

    local close = CreateFrame("Button", nil, arrow)
    close:SetSize(16, 16)
    close:SetPoint("TOPRIGHT", -4, -4)
    local x = S.Text(close, 13)
    x:SetPoint("CENTER"); x:SetText("x"); x:SetTextColor(1, 1, 1, 0.53)
    close:SetScript("OnClick", function()
        if WLWritsCharDB.gps then WP.ToggleGPS() else GPS.Stop() end
    end)

    arrow.fly = S.Button(arrow, "", 214, function() GPS.TakeFlight() end)
    arrow.fly:SetPoint("BOTTOM", 0, 8)
    arrow.fly:Hide()

    teleport = CreateFrame("Button", "WLGPSTeleport", arrow, "SecureActionButtonTemplate")
    teleport:SetSize(214, 22)
    teleport:SetPoint("BOTTOM", 0, 8)
    teleport:RegisterForClicks("AnyUp", "AnyDown")
    S.Solid(teleport, "BACKGROUND", 0.077, 0.068, 0.058, 0.92):SetAllPoints()
    S.Border(teleport, ar, ag, ab, 0.6)
    teleport.label = S.Text(teleport, 12)
    teleport.label:SetPoint("CENTER")
    teleport.label:SetJustifyH("CENTER")
    teleport.label:SetTextColor(ar, ag, ab)
    teleport:Hide()

    local acc = 0
    arrow:SetScript("OnUpdate", function(self, elapsed)
        acc = acc + elapsed
        if acc < 0.05 then return end
        acc = 0
        local now = GPS.Now()
        if not now then self:Hide(); return end
        self.step:SetText(now.text)
        self.next:SetText(now.next and (L("Ensuite : ") .. now.next) or "")
        local leg = now.leg
        -- Buttons: the flight while the flight map is open, the teleport when it is the step.
        local flight = GPS.FlightLeg()
        local mapOpen = (TaxiFrame and TaxiFrame:IsShown()) or (FlightMapFrame and FlightMapFrame:IsShown())
        if flight and mapOpen then
            self.fly.label:SetText(string.format(L("Prendre le vol : %s"), flight.to.name))
            self.fly:Show()
        else
            self.fly:Hide()
        end
        if not InCombatLockdown() then SetTeleport(GPS.TeleportLeg()) end
        if now.arrived then
            self.tex:SetRotation(0)
            self.tex:SetVertexColor(ar, ag, ab)
            self.dist:SetText(L("Tu y es"))
            return
        end
        local angle = now.target and GPS.Bearing(now.target)
        if not angle then
            self.tex:SetRotation(0)
            self.tex:SetVertexColor(0.5, 0.5, 0.5)
            self.dist:SetText(leg and leg.kind ~= "ride" and Minutes(now.eta) or L("autre continent ou instance"))
            return
        end
        self.tex:SetRotation(angle)
        local off = math.abs(((angle + math.pi) % (2 * math.pi)) - math.pi) / math.pi   -- 0 ahead, 1 behind
        self.tex:SetVertexColor(math.min(1, 2 * off), math.min(1, 2 * (1 - off)), 0.2)
        self.dist:SetText((now.dist and Meters(now.dist) or "") .. "   " .. Minutes(now.eta))
    end)
    arrow:Hide()
end

function GPS.Show()
    if not arrow then Build() end
    arrow:Show()
end

function GPS.Hide()
    if arrow then arrow:Hide() end
    if teleport and not InCombatLockdown() then teleport:Hide(); shownSpell = false end
end

function GPS.OnChanged()
    if arrow and GPS.Active() then arrow:Show() end
end
