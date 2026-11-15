-- Writs/Arrow.lua: the GPS HUD, readable while running: the HD arrow (or the painted icon of a flight,
-- a boat or zeppelin, a teleport; the HD check once you are there), one large line (the distance or
-- the state), the step and the next step under it. Step lines wrap to two lines and the HUD grows
-- with them: nothing is cut. A long flight master's name drops its zone ("Brackenwall Village");
-- the whole route, with the full names, is in the HUD's tooltip.
-- A button appears when it saves a click: take the planned flight while the flight map is open, or
-- cast the teleport.
--
-- The teleport button is secure, so it is parented AND anchored to UIParent (placed at the HUD's
-- button row out of combat): the HUD itself stays an ordinary frame that may move, resize, show and
-- hide in combat. The text is redrawn 4 times a second, only when it changes; the arrow turns 20 times.
local ADDON, root = ...
root.Writs = root.Writs or {}
local ns = root.Writs
local WP = ns.WP
local L = ns.L
local S = ns.S
local C = S.C
local GPS = WP.GPS

ns.AddEnglish({
    ["Tu y es"] = "You're here",
    ["Parle à %s"] = "Talk to %s",
    ["Dans le donjon"] = "Inside the dungeon",
    ["Au maître de vol"] = "At the flight master",
    ["Prends le vol pour %s"] = "Take the flight to %s",
    ["Prendre le vol pour %s"] = "Take the flight to %s",
    ["Le chemin le plus rapide : la téléportation."] = "The fastest way: teleport.",
    ["Attends le bateau"] = "Wait for the boat",
    ["Attends le zeppelin"] = "Wait for the zeppelin",
    ["Autre continent"] = "Other continent",
    ["Pas d'itinéraire connu : la flèche va tout droit."] = "No known route: the arrow points straight there.",
    ["Parle à un maître de vol : le GPS apprendra tes trajets."] = "Talk to a flight master: the GPS will learn your routes.",
    ["Étape %d sur %d"] = "Step %d of %d",
    ["~%d min"] = "~%d min",
    ["Place la flèche"] = "Place the arrow",
    ["Glisse-la où tu veux."] = "Drag it where you want it.",
    ["Clique sur la croix pour la fixer ici."] = "Click the cross to lock it here.",
    ["Lancer la téléportation"] = "Cast the teleport",
    ["Téléportation demandée..."] = "Teleport requested...",
    ["Téléportation en cours..."] = "Teleporting...",
    ["Interrompue : clique pour relancer"] = "Interrupted: click to try again",
    ["Indisponible en combat"] = "Not available in combat",
    ["Arrêter le GPS"] = "Stop the GPS",
    ["Clic : arrêter le guidage"] = "Click: stop the guidance",
    ["Fixer la flèche"] = "Lock the arrow",
    ["Clic : la fixer à cet endroit"] = "Click: lock it in this spot",
    ["GPS"] = "GPS",
    ["Glisser : déplacer la flèche"] = "Drag: move the arrow",
    ["Clic : prendre ce vol"] = "Click: take this flight",
    ["Clic : lancer le sort"] = "Click: cast the spell",
    ["La téléportation attend la fin du combat."] = "The teleport waits for the end of the fight.",
})

local arrow, teleport, demo
local ICON_LINK = "Interface\\Icons\\INV_Misc_Map_01"
local ICON_DUNGEON = "Interface\\Icons\\INV_Misc_Key_03"
local TURN_EVERY, TEXT_EVERY = 0.05, 0.25
-- HUD-like width (design system: 360). The arrow 48 px at 12, 12; text from x = 72 to the close
-- button (28 px hit area at -4): 252 px wide.
local HUD_W, ARROW_SIZE, TEXT_X = 360, 48, 72
local TEXT_W = HUD_W - TEXT_X - 36
local BTN_H = 32

local function FlyIcon()
    return UnitFactionGroup("player") == "Alliance" and "Interface\\Icons\\Ability_Mount_Gryphon_01"
        or "Interface\\Icons\\Ability_Mount_Wyvern_01"
end

local function Opt(k, d)
    local o = WLWritsDB and WLWritsDB.gpsOpts
    local v = o and o[k]
    if v == nil then return d end
    return v
end

local function Distance(yards)
    if WLWritsDB and WLWritsDB.gpsOpts and WLWritsDB.gpsOpts.yards then
        return string.format("%d yd", math.floor(yards + 0.5))
    end
    local m = yards * 0.9144
    local comma = not ns.English()
    if m >= 1000 then
        local t = string.format("%.1f km", m / 1000)
        return comma and (t:gsub("%.", ",")) or t
    end
    if m >= 100 then m = math.floor(m / 10 + 0.5) * 10 end   -- 350 m, not 347 m, while far
    return string.format("%d m", math.floor(m + 0.5))
end
GPS.Distance = Distance

local function Minutes(seconds)
    if not seconds then return "" end
    return string.format(L("~%d min"), math.max(1, math.floor(seconds / 60 + 0.5)))
end

local function SpellIcon(id)
    if C_Spell and C_Spell.GetSpellTexture then
        local ok, t = pcall(C_Spell.GetSpellTexture, id)
        if ok and t then return t end
    end
    return GetSpellTexture and GetSpellTexture(id) or ICON_LINK
end

-- Sets a font string only when the value changes (no work, no garbage when it doesn't); true when it did.
local function SetText(fs, t)
    t = t or ""
    if fs.cur ~= t then fs.cur = t; fs:SetText(t); return true end
    return false
end
-- The top line: a distance is the HUD's one hero number (20 fg) with its unit small and muted
-- beside it ("350" + "m"); a state ("Tu y es", "Attends le zeppelin", a city) is a 14 fg sentence.
local function SetTop(self, text, isDistance)
    text = text or ""
    local num, unit
    if isDistance then num, unit = text:match("^(%S+)%s+(%S+)$") end
    if not num then num, unit = isDistance and text or "", "" end
    local a = SetText(self.big, num)
    local b = SetText(self.unit, unit)
    local c = SetText(self.state, isDistance and "" or text)
    return a or b or c
end
-- The painted icon of a thing (flight, boat, spell, dungeon key) in place of the arrow.
local function SetPaintedIcon(self, path)
    self.tex:Hide(); self.icon:Show()
    if self.icon.cur ~= path then
        self.icon.cur = path
        S.Painted(self.icon, path, ARROW_SIZE)
        self.icon:SetVertexColor(1, 1, 1, 1)
    end
end
-- "You are there": the HD check in the ok colour (it pulses slowly, see OnUpdate).
local function SetHereIcon(self)
    self.tex:Hide(); self.icon:Show()
    if self.icon.cur ~= "here" then
        self.icon.cur = "here"
        S.HDIcon(self.icon, "check", C.ok)
        self.icon:SetSize(40, 40)
    end
end

-- ---------------------------------------------------------------- layout

-- The HUD grows with its text: big line, step (2 lines max), next step (2 lines max), then the
-- button row when there is one. Called only when a text or the button changed.
local function Layout(self)
    local y = 12
    local topH
    if (self.big.cur or "") ~= "" then
        self.big:Show(); self.unit:Show(); self.state:Hide()
        -- measure the whole number (a width left from a shorter one used to cut it as "4...")
        self.big:SetWidth(TEXT_W - 24)
        local getW = self.big.GetUnboundedStringWidth or self.big.GetStringWidth
        local okW, w = pcall(getW, self.big)
        w = (okW and type(w) == "number" and not (root.IsSecret and root.IsSecret(w))) and w or 0
        self.big:SetWidth(math.min(TEXT_W - 24, math.ceil(w) + 4))
        -- the font may land a frame later: measure again then
        if not self.bigRefit and C_Timer and C_Timer.After then
            self.bigRefit = true
            C_Timer.After(0, function()
                self.bigRefit = nil
                self.big:SetWidth(TEXT_W - 24)
                local ok2, w2 = pcall(getW, self.big)
                if ok2 and type(w2) == "number" and not (root.IsSecret and root.IsSecret(w2)) and w2 > 0 then
                    self.big:SetWidth(math.min(TEXT_W - 24, math.ceil(w2) + 4))
                end
            end)
        end
        local okB, bigH = pcall(self.big.GetStringHeight, self.big)
        topH = (okB and type(bigH) == "number" and not (root.IsSecret and root.IsSecret(bigH))) and bigH or 0
        if topH < S.F.hero then topH = S.F.hero + 2 end
    else
        self.big:Hide(); self.unit:Hide(); self.state:Show()
        topH = S.FitText(self.state, 2, TEXT_W, self)
        if topH < S.F.heading then topH = S.F.heading + 2 end
    end
    y = y + topH
    local function line(fs, size, gap)
        if (fs.cur or "") == "" then fs:Hide() return end
        fs:Show()
        y = y + gap
        fs:ClearAllPoints(); fs:SetPoint("TOPLEFT", TEXT_X, -y)
        local h = S.FitText(fs, 2, TEXT_W, self)
        if h < size then h = size + 2 end
        y = y + h
    end
    line(self.step, S.F.label, 4)
    line(self.sub, S.F.meta, 3)
    y = math.max(y, 12 + ARROW_SIZE) + 12
    self.btnY = y
    if self.button then y = y + BTN_H + 12 end
    y = math.ceil(y)
    if self.h ~= y then self.h = y; self:SetHeight(y) end
    self.fly:ClearAllPoints(); self.fly:SetPoint("TOPLEFT", 12, -self.btnY)
end

-- ---------------------------------------------------------------- the teleport button

-- Put on the HUD's button row, in UIParent coordinates (both frames share the scale). Out of combat only.
local function PlaceTeleport()
    if not (teleport and arrow) or InCombatLockdown() then return end
    local left, top = arrow:GetLeft(), arrow:GetTop()
    if not (left and top) then return end
    teleport:SetScale(arrow:GetScale())
    teleport:ClearAllPoints()
    teleport:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left + 12, top - (arrow.btnY or (12 + ARROW_SIZE + 12)))
end

-- Shows the button for this spell, or hides it. Out of combat only; called again after combat.
local shownSpell = false
local function SetTeleport(spell)
    if not teleport or InCombatLockdown() then return end
    if spell == shownSpell then return end
    shownSpell = spell
    if spell then
        teleport:SetAttribute("type", "spell")
        teleport:SetAttribute("spell", spell)
        PlaceTeleport()
        teleport:Show()
    else
        teleport:Hide()
    end
end

local function WantedTeleport()
    if not (arrow and arrow:IsShown()) or demo then return nil end
    local leg = GPS.TeleportLeg()
    return leg and leg.to.spell or nil
end

-- ---------------------------------------------------------------- drawing

local function Draw(self, now, combat)
    local leg, legs = now.leg, now.legs
    local n = legs and #legs or 0
    local total = legs and (legs.total or n) or 0
    local stepText = (total > 1) and string.format(L("Étape %d sur %d"), math.max(1, total - n + 1), total) or Minutes(now.eta)

    local button = nil
    local changed = false
    local function T(fs, t) if SetText(fs, t) then changed = true end end
    self.turn = false
    self.arrived = now.arrived and true or false
    if now.arrived then
        SetHereIcon(self)
        if SetTop(self, L("Tu y es")) then changed = true end
        local w = now.dest and now.dest.writ
        T(self.step, w and w.npcName and string.format(L("Parle à %s"), w.npcName) or (now.dest and now.dest.name) or "")
        T(self.sub, w and WP.ItemName(w.item, w.itemName) or "")
    elseif not now.map and IsInInstance and IsInInstance() then
        -- inside a dungeon there is no map position: the step alone
        SetPaintedIcon(self, ICON_DUNGEON)
        if SetTop(self, L("Dans le donjon")) then changed = true end
        T(self.step, now.dest and now.dest.name or "")
        T(self.sub, "")
    elseif leg and leg.kind == "fly" then
        SetPaintedIcon(self, FlyIcon())
        local mapOpen = (TaxiFrame and TaxiFrame:IsShown()) or (FlightMapFrame and FlightMapFrame:IsShown())
        local place = GPS.ShortPlace(leg.to.name)
        if SetTop(self, L("Au maître de vol")) then changed = true end
        T(self.step, mapOpen and "" or string.format(L("Prends le vol pour %s"), place))
        local nxt = legs[2]
        T(self.sub, nxt and GPS.DescribeNext(nxt) or stepText)
        if mapOpen then
            button = "fly"
            -- the label keeps its verb; in combat the button is disabled and its reason says why
            local label = string.format(L("Prendre le vol pour %s"), place)
            if self.fly:GetText() ~= label then self.fly:SetText(label); changed = true end
        end
    elseif leg and leg.kind == "teleport" then
        SetPaintedIcon(self, SpellIcon(leg.to.spell))
        -- the destination alone in large type
        if SetTop(self, GPS.ShortPlace(leg.to.name)) then changed = true end
        T(self.step, L("Le chemin le plus rapide : la téléportation."))
        T(self.sub, stepText)
        button = "teleport"
    else
        -- riding (or waiting for a boat or zeppelin at its dock): the arrow
        local atDock = leg and leg.kind == "link" and now.dist and now.dist < 30
        if atDock then
            SetPaintedIcon(self, ICON_LINK)
            local boat = leg.from and leg.from.link and leg.from.link.mode == "boat"
            if SetTop(self, boat and L("Attends le bateau") or L("Attends le zeppelin")) then changed = true end
        else
            self.icon:Hide(); self.tex:Show()
            self.turn = true
            if SetTop(self, now.dist and Distance(now.dist) or L("Autre continent"), now.dist ~= nil) then changed = true end
        end
        T(self.step, leg and GPS.Describe(leg) or (now.dest and now.dest.name) or "")
        if not legs then
            T(self.sub, L("Pas d'itinéraire connu : la flèche va tout droit."))
        elseif GPS.KnownFlights() == 0 then
            T(self.sub, L("Parle à un maître de vol : le GPS apprendra tes trajets."))
        else
            local nxt = legs[2]
            T(self.sub, nxt and GPS.DescribeNext(nxt) or stepText)
        end
    end

    -- the button row
    self.fly:SetShown(button == "fly")
    if button == "fly" then
        if combat then self.fly:Disable() else self.fly:Enable() end
    end
    if button ~= self.button then self.button = button; changed = true end
    if changed then Layout(self); PlaceTeleport() end
    SetTeleport(button == "teleport" and leg.to.spell or nil)
end

-- Turns the arrow toward the target; red to green as you face it, amber in combat.
local function Turn(self, now, combat)
    local angle = now.target and GPS.Bearing(now.target, now)
    if angle then
        self.tex:SetRotation(angle)
        if combat then
            self.tex:SetVertexColor(C.warn[1], C.warn[2], C.warn[3])
        else
            -- gold off course, green when facing it (within about 25 degrees), a smooth blend between
            local off = math.abs(((angle + math.pi) % (2 * math.pi)) - math.pi) / math.pi
            local k = math.max(0, math.min(1, (off - 0.08) / 0.25))
            self.tex:SetVertexColor(0.40 + 0.60 * k, 0.90 - 0.08 * k, 0.45 - 0.17 * k)
        end
    else
        self.tex:SetRotation(0); self.tex:SetVertexColor(C.muted[1], C.muted[2], C.muted[3])
    end
end

-- The HUD's tooltip: where it leads, every leg with its full names, and what the mouse does.
local function RouteTip(self)
    if demo then
        S.Tip(self, { L("Place la flèche"), L("Glisser : déplacer la flèche") })
        return
    end
    local now = GPS.Now()
    local lines = { (now and now.dest and now.dest.name) or L("GPS") }
    if now and now.legs then
        for i, leg in ipairs(now.legs) do
            local d = GPS.Describe(leg, true)
            if d ~= "" then lines[#lines + 1] = i .. ". " .. d end
        end
    end
    lines[#lines + 1] = L("Glisser : déplacer la flèche")
    S.Tip(self, lines)
end

-- ---------------------------------------------------------------- the frame

local function SavePos(self)
    -- kept as TOPLEFT so a taller HUD grows downward and the button row stays put
    local left, top = self:GetLeft(), self:GetTop()
    if not (left and top) then return end
    self:ClearAllPoints()
    self:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
    WLWritsDB.arrowPos = { "TOPLEFT", "BOTTOMLEFT", left, top }
    PlaceTeleport()
end

local function Build()
    arrow = CreateFrame("Frame", "WLGPSArrow", UIParent)
    arrow.wlOwned = true
    arrow.wlWorld = true            -- text drawn over the world: with a shadow
    arrow:SetSize(HUD_W, 12 + ARROW_SIZE + 12)
    local pos = WLWritsDB.arrowPos
    if pos then arrow:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4]) else arrow:SetPoint("TOP", 0, -150) end
    arrow:SetFrameStrata("MEDIUM")
    arrow:SetClampedToScreen(true)
    arrow:SetMovable(true)
    arrow:EnableMouse(true)
    arrow:RegisterForDrag("LeftButton")
    arrow:SetScript("OnDragStart", function(self) self:StartMoving() end)
    arrow:SetScript("OnDragStop", function(self) self:StopMovingOrSizing(); SavePos(self) end)
    arrow:SetScript("OnEnter", RouteTip)
    arrow:SetScript("OnLeave", S.HideTip)
    -- the optional box under the HUD (options: opacity, 0 by default)
    arrow.bg = S.Solid(arrow, "BACKGROUND", C.bg, 1)
    arrow.bg:SetAllPoints()

    -- WL Helper's own HD arrow (Media/Arrow.tga, smooth at any scale)
    arrow.tex = arrow:CreateTexture(nil, "ARTWORK")
    arrow.tex:SetTexture("Interface\\AddOns\\WLHelper\\Media\\Arrow")
    arrow.tex:SetSize(ARROW_SIZE, ARROW_SIZE)
    arrow.tex:SetPoint("TOPLEFT", 12, -12)
    arrow.icon = arrow:CreateTexture(nil, "ARTWORK")
    arrow.icon:SetSize(ARROW_SIZE, ARROW_SIZE)
    arrow.icon:SetPoint("CENTER", arrow.tex, "CENTER")
    arrow.icon:Hide()

    -- the distance: one hero number, its unit small and muted beside it
    arrow.big = S.Text(arrow, S.F.hero, C.fg, true)
    arrow.big:SetPoint("TOPLEFT", TEXT_X, -12)
    arrow.big:SetJustifyH("LEFT")
    arrow.big:SetWordWrap(false)
    arrow.big:SetWidth(TEXT_W)
    arrow.unit = S.Text(arrow, S.F.meta, C.muted)
    arrow.unit:SetWordWrap(false)
    arrow.unit:SetPoint("BOTTOMLEFT", arrow.big, "BOTTOMRIGHT", 3, 2)
    -- or the state, a short sentence ("Tu y es", "Attends le zeppelin", a city) at heading size
    arrow.state = S.Text(arrow, S.F.heading, C.fg, true)
    arrow.state:SetPoint("TOPLEFT", TEXT_X, -12)
    arrow.state:SetJustifyH("LEFT"); arrow.state:SetJustifyV("TOP")
    -- the step and the next one wrap to two lines; the HUD grows with them
    arrow.step = S.Text(arrow, S.F.label, C.fg)
    arrow.step:SetJustifyH("LEFT"); arrow.step:SetJustifyV("TOP")
    arrow.sub = S.Text(arrow, S.F.meta, C.muted)
    arrow.sub:SetJustifyH("LEFT"); arrow.sub:SetJustifyV("TOP")
    for _, fs in ipairs({ arrow.big, arrow.unit, arrow.state, arrow.step, arrow.sub }) do root.Shadow(fs, true) end

    local close = S.CloseButton(arrow, 28, nil, function()
        if demo then return { L("Fixer la flèche"), L("Clic : la fixer à cet endroit") } end
        return { L("Arrêter le GPS"), L("Clic : arrêter le guidage") }
    end)
    close:SetPoint("TOPRIGHT", -4, -4)
    close:SetScript("OnClick", function()
        if demo then GPS.Lock(); return end
        if GPS.Source() == "dungeon" then
            if WLDTDB then WLDTDB.arrow = false end
            GPS.Stop("dungeon")
            if root.Render then root.Render() end
        elseif WLWritsCharDB.gps then
            WP.ToggleGPS()
        else
            GPS.Stop()
        end
    end)
    arrow.close = close

    arrow.fly = S.Button(arrow, "", HUD_W - 24, BTN_H, "primary", function() GPS.TakeFlight() end,
        function()
            if arrow.fly:IsEnabled() == false then return nil end   -- the label and its reason, once
            return { arrow.fly:GetText(), L("Clic : prendre ce vol") }
        end)
    arrow.fly:SetIcon("flag")
    arrow.fly:SetDisabledReason(L("Indisponible en combat"))
    arrow.fly:Hide()

    -- the teleport: a secure button drawn like a secondary button (fill, 1 px edge, HD portal icon)
    teleport = CreateFrame("Button", "WLGPSTeleport", UIParent, "SecureActionButtonTemplate")
    teleport.wlOwned = true
    teleport:SetSize(HUD_W - 24, BTN_H)
    teleport:SetFrameStrata("MEDIUM")
    teleport:SetFrameLevel(arrow:GetFrameLevel() + 5)
    teleport:RegisterForClicks("AnyUp", "AnyDown")   -- the game acts on the press or the release (its "cast on key down" setting): both registered
    S.Solid(teleport, "BACKGROUND", C.bg, 0.92):SetAllPoints()
    S.Solid(teleport, "BACKGROUND", C.btnFill):SetAllPoints()
    local edge = S.Border(teleport, C.btnEdge)
    -- what the click does, seen: lighter on hover, pressed look on click, then the cast's progress
    local hover = S.Solid(teleport, "BORDER", C.hoverFill); hover:SetAllPoints(); hover:SetAlpha(0)
    local press = S.Solid(teleport, "ARTWORK", C.pressFill); press:SetAllPoints(); press:Hide()
    local fill = S.Solid(teleport, "BORDER", C.accent, 0.35)
    fill:SetPoint("TOPLEFT", 1, -1); fill:SetPoint("BOTTOMLEFT", 1, 1); fill:SetWidth(1); fill:Hide()
    local tl = S.Text(teleport, S.F.label, C.fg)
    tl:SetWordWrap(false)
    tl:SetPoint("CENTER", 11, 0)
    local ti = S.Icon(teleport, "portal", 16, "OVERLAY", C.fg)
    ti:SetPoint("RIGHT", tl, "LEFT", -6, 0)
    local function Label(t) tl:SetText(t) end
    Label(L("Lancer la téléportation"))
    teleport.label = tl
    teleport:HookScript("OnEnter", function(self)
        hover:SetAlpha(1); edge(C.btnEdgeHover)
        local lines = { L("Lancer la téléportation"), L("Clic : lancer le sort") }
        if InCombatLockdown() then lines[#lines + 1] = { L("La téléportation attend la fin du combat."), C.warn[1], C.warn[2], C.warn[3] } end
        S.Tip(self, lines)
    end)
    teleport:HookScript("OnLeave", function() hover:SetAlpha(0); edge(C.btnEdge); S.HideTip() end)
    teleport:HookScript("OnMouseDown", function() press:Show(); tl:SetPoint("CENTER", 11, -1) end)
    teleport:HookScript("OnMouseUp", function() press:Hide(); tl:SetPoint("CENTER", 11, 0) end)
    teleport:HookScript("OnClick", function()
        Label(L("Téléportation demandée..."))
        C_Timer.After(1.5, function()
            if not teleport.casting then Label(L("Lancer la téléportation")) end
        end)
    end)
    -- the cast bar inside the button: filled from the player's cast (numbers read under pcall,
    -- they may be secret on this client)
    local cev = CreateFrame("Frame", nil, teleport)
    for _, e in ipairs({ "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_STOP", "UNIT_SPELLCAST_FAILED", "UNIT_SPELLCAST_INTERRUPTED", "UNIT_SPELLCAST_SUCCEEDED" }) do
        pcall(cev.RegisterUnitEvent or cev.RegisterEvent, cev, e, "player")
    end
    cev:SetScript("OnEvent", function(_, e, unit)
        if unit ~= "player" or not teleport:IsShown() then return end
        if e == "UNIT_SPELLCAST_START" then
            teleport.casting = true
            Label(L("Téléportation en cours...")); fill:Show()
        elseif e == "UNIT_SPELLCAST_SUCCEEDED" then
            teleport.casting = false; fill:Hide(); Label(L("Lancer la téléportation"))
        else
            if teleport.casting then
                teleport.casting = false; fill:Hide()
                Label(L("Interrompue : clique pour relancer"))
                C_Timer.After(3, function() if not teleport.casting then Label(L("Lancer la téléportation")) end end)
            end
        end
    end)
    teleport:HookScript("OnUpdate", function(self)
        if not self.casting then return end
        local ok, k = pcall(function()
            local _, _, _, startMS, endMS = UnitCastingInfo("player")
            if not (startMS and endMS) or endMS <= startMS then return nil end
            return math.max(0, math.min(1, (GetTime() * 1000 - startMS) / (endMS - startMS)))
        end)
        if ok and k then fill:SetWidth(math.max(1, (self:GetWidth() - 2) * k)) end
    end)
    teleport:Hide()

    local turnAcc, textAcc, pulse = 0, TEXT_EVERY, 0
    arrow:SetScript("OnUpdate", function(self, elapsed)
        if demo then return end
        -- the only looping animation: a slow pulse on the check once you are there
        if self.arrived then
            pulse = (pulse + elapsed) % 1.2
            self.icon:SetAlpha(0.8 + 0.2 * math.cos(pulse / 1.2 * 2 * math.pi))
        elseif pulse ~= 0 then
            pulse = 0; self.icon:SetAlpha(1)
        end
        turnAcc, textAcc = turnAcc + elapsed, textAcc + elapsed
        if turnAcc < TURN_EVERY then return end
        turnAcc = 0
        local now = GPS.Now()
        if not now then self:Hide(); SetTeleport(nil); return end
        local combat = InCombatLockdown()
        if combat ~= self.combat then
            self.combat = combat
            self:SetAlpha(combat and Opt("hideCombat", false) and 0 or 1)
            -- the secure teleport button cannot hide in combat, but it can go transparent
            if teleport then teleport:SetAlpha(self:GetAlpha()) end
            textAcc = TEXT_EVERY            -- redraw now: amber, buttons off
        end
        if textAcc >= TEXT_EVERY then
            textAcc = 0
            Draw(self, now, combat)
        end
        if self.turn then Turn(self, now, combat) end
    end)
    arrow:SetScript("OnHide", function()
        if teleport and InCombatLockdown() then teleport:SetAlpha(0) end
        SetTeleport(nil)
    end)
    arrow:Hide()
    -- the drawn values belong to the frame: forget them so the next show draws everything
    arrow:HookScript("OnShow", function(self) textAcc = TEXT_EVERY; self.combat = nil end)
    Layout(arrow)
end

-- After combat: the teleport button catches up with what the HUD shows now.
local ev = CreateFrame("Frame")
pcall(ev.RegisterEvent, ev, "PLAYER_REGEN_ENABLED")
ev:SetScript("OnEvent", function()
    -- restored here, not in SetTeleport (which returns early for the spell already shown)
    if teleport then teleport:SetAlpha(1); PlaceTeleport(); SetTeleport(WantedTeleport()) end
end)

-- Size and background opacity from the options.
function GPS.ApplyLook()
    if not arrow then return end
    -- the grey box under the arrow is off by default since 1.0.0-beta.24: the old default (0.6) goes once
    local o = WLWritsDB and WLWritsDB.gpsOpts
    if o and not o.alphaV2 then
        if o.alpha == 0.6 then o.alpha = 0 end
        o.alphaV2 = true
    end
    arrow:SetScale(Opt("scale", 1))
    arrow.bg:SetAlpha(Opt("alpha", 0))
    PlaceTeleport()
end

-- Shows the HUD with sample text so it can be dragged into place; the cross locks it again.
function GPS.UnlockArrow()
    if not arrow then Build() end
    GPS.ApplyLook()
    demo = true
    arrow.arrived = false
    arrow.icon:Hide(); arrow.icon:SetAlpha(1); arrow.tex:Show(); arrow.tex:SetRotation(0.3)
    arrow.tex:SetVertexColor(C.ok[1], C.ok[2], C.ok[3])
    SetTop(arrow, L("Place la flèche"))
    SetText(arrow.step, L("Glisse-la où tu veux."))
    SetText(arrow.sub, L("Clique sur la croix pour la fixer ici."))
    arrow.fly:Hide()
    arrow.button = nil
    Layout(arrow)
    SetTeleport(nil)
    arrow:Show()
end

function GPS.Lock()
    demo = false
    if arrow then SetTop(arrow, ""); SetText(arrow.step, ""); SetText(arrow.sub, ""); arrow.icon.cur = nil end
    if arrow and not GPS.Active() then arrow:Hide() end
end

function GPS.Show()
    if not arrow then Build() end
    GPS.ApplyLook()
    arrow:Show()
end

function GPS.Hide()
    if arrow and not demo then arrow:Hide() end
    SetTeleport(nil)
end

function GPS.OnChanged()
    if arrow and GPS.Active() and GPS.Now() then arrow:Show() end
end
