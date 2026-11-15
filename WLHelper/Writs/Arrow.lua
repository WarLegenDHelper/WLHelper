-- Writs/Arrow.lua: the GPS arrow, readable while running: a big arrow (or the game's own icon for a
-- flight, a boat or zeppelin, a teleport), the distance in large type, one line for the step and
-- "step 2 of 4". A button appears when it saves a click: take the planned flight while the flight
-- map is open, or cast the teleport.
--
-- The teleport button is secure, so it is parented AND anchored to UIParent (placed at the arrow's
-- spot out of combat): the arrow itself stays an ordinary frame that may move, resize, show and hide
-- in combat. The text is redrawn 4 times a second, only when it changes; the arrow turns 20 times.
local ADDON, root = ...
root.Writs = root.Writs or {}
local ns = root.Writs
local WP = ns.WP
local L = ns.L
local S = ns.S
local C = S.C
local GPS = WP.GPS

ns.AddEnglish({
    ["Téléportation demandée..."] = "Teleport requested...",
    ["Téléportation en cours..."] = "Teleporting...",
    ["Interrompue : clique pour recommencer"] = "Interrupted: click to try again",
    ["Dans le donjon"] = "Inside the dungeon",
    ["Téléportation, le plus rapide"] = "Teleport, fastest",
})

local arrow, teleport, demo
local ARROW_TEX = "Interface\\Minimap\\MinimapArrow"
local ICON_LINK = "Interface\\Icons\\INV_Misc_Map_01"
local ICON_HERE = "Interface\\RaidFrame\\ReadyCheck-Ready"   -- fallback of the modern tick
local ATLAS_HERE = { "common-icon-checkmark" }
local ICON_DUNGEON = "Interface\\Icons\\INV_Misc_Key_03"
local SHORT, TALL = 86, 128
local TURN_EVERY, TEXT_EVERY = 0.05, 0.25

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

-- "Prends le vol" -> "prends le vol", also for an accented capital (UTF-8 É).
local function LowerFirst(s)
    if s:sub(1, 2) == "\195\137" then return "\195\169" .. s:sub(3) end
    return (s:gsub("^%u", string.lower))
end

local function SpellIcon(id)
    if C_Spell and C_Spell.GetSpellTexture then
        local ok, t = pcall(C_Spell.GetSpellTexture, id)
        if ok and t then return t end
    end
    return GetSpellTexture and GetSpellTexture(id) or ICON_LINK
end

-- Sets a font string or texture only when the value changes (no work, no garbage when it doesn't).
local function SetText(fs, t)
    if fs.cur ~= t then fs.cur = t; fs:SetText(t) end
end
local function SetIcon(self, tex, crop)
    self.tex:Hide(); self.icon:Show()
    if self.icon.cur ~= tex then
        self.icon.cur = tex
        -- "you are there": the crisp modern tick when this client has it (the old one is 32 px)
        S.SetIcon(self.icon, tex == ICON_HERE and ATLAS_HERE or nil, tex, crop and { 0.08, 0.92, 0.08, 0.92 } or nil)
    end
end

-- ---------------------------------------------------------------- the teleport button

-- Put on the arrow's button row, in UIParent coordinates (both frames share the scale). Out of combat only.
local function PlaceTeleport()
    if not (teleport and arrow) or InCombatLockdown() then return end
    local left, top = arrow:GetLeft(), arrow:GetTop()
    if not (left and top) then return end
    teleport:SetScale(arrow:GetScale())
    teleport:ClearAllPoints()
    teleport:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left + 12, top - (TALL - 10 - 32))
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
    self.turn = false
    if now.arrived then
        SetIcon(self, ICON_HERE, false)
        SetText(self.big, L("Tu y es"))
        local w = now.dest and now.dest.writ
        SetText(self.step, w and w.npcName and string.format(L("Parle à %s"), w.npcName) or (now.dest and now.dest.name) or "")
        SetText(self.sub, w and WP.ItemName(w.item, w.itemName) or "")
    elseif not now.map and IsInInstance and IsInInstance() then
        -- inside a dungeon there is no map position: the step alone
        SetIcon(self, ICON_DUNGEON, true)
        SetText(self.big, L("Dans le donjon"))
        SetText(self.step, now.dest and now.dest.name or "")
        SetText(self.sub, "")
    elseif leg and leg.kind == "fly" then
        SetIcon(self, FlyIcon(), true)
        local mapOpen = (TaxiFrame and TaxiFrame:IsShown()) or (FlightMapFrame and FlightMapFrame:IsShown())
        SetText(self.big, L("Au maître de vol"))
        SetText(self.step, mapOpen and "" or string.format(L("Vol pour %s"), leg.to.name))
        local nxt = legs[2]
        SetText(self.sub, nxt and (L("puis ") .. LowerFirst(GPS.Describe(nxt))) or stepText)
        if mapOpen then
            button = "fly"
            SetText(self.fly.label, combat and L("En combat") or string.format(L("Vol pour %s"), leg.to.name))
        end
    elseif leg and leg.kind == "teleport" then
        SetIcon(self, SpellIcon(leg.to.spell), true)
        -- the destination alone in large type: "Téléport. <city>" did not fit
        SetText(self.big, leg.to.name)
        SetText(self.step, L("Téléportation, le plus rapide"))
        SetText(self.sub, stepText)
        button = "teleport"
    else
        -- riding (or waiting for a boat or zeppelin at its dock): the arrow
        local atDock = leg and leg.kind == "link" and now.dist and now.dist < 30
        if atDock then
            SetIcon(self, ICON_LINK, true)
            SetText(self.big, L("Attends à quai"))
        else
            self.icon:Hide(); self.tex:Show()
            self.turn = true
            SetText(self.big, now.dist and Distance(now.dist) or L("Autre continent"))
        end
        SetText(self.step, leg and GPS.Describe(leg) or (now.dest and now.dest.name) or "")
        if not legs then
            SetText(self.sub, L("itinéraire indisponible, ligne droite"))
        elseif GPS.KnownFlights() == 0 then
            SetText(self.sub, L("Ouvre une carte de vol pour aller plus vite"))
        else
            SetText(self.sub, stepText)
        end
    end

    -- the button row
    self.fly:SetShown(button == "fly")
    if button == "fly" then
        if combat then self.fly:Disable() else self.fly:Enable() end
    end
    SetTeleport(button == "teleport" and leg.to.spell or nil)
    local tall = button ~= nil
    if tall ~= self.tall then self.tall = tall; self:SetHeight(tall and TALL or SHORT) end
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
        self.tex:SetRotation(0); self.tex:SetVertexColor(0.5, 0.5, 0.5)
    end
end

-- ---------------------------------------------------------------- the frame

local function SavePos(self)
    -- kept as TOPLEFT so a taller arrow grows downward and the button row stays put
    local left, top = self:GetLeft(), self:GetTop()
    if not (left and top) then return end
    self:ClearAllPoints()
    self:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
    WLWritsDB.arrowPos = { "TOPLEFT", "BOTTOMLEFT", left, top }
    PlaceTeleport()
end

local function Build()
    arrow = CreateFrame("Frame", "WLGPSArrow", UIParent)
    arrow:SetSize(320, SHORT)
    local pos = WLWritsDB.arrowPos
    if pos then arrow:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4]) else arrow:SetPoint("TOP", 0, -150) end
    arrow:SetFrameStrata("MEDIUM")
    arrow:SetClampedToScreen(true)
    arrow:SetMovable(true)
    arrow:EnableMouse(true)
    arrow:RegisterForDrag("LeftButton")
    arrow:SetScript("OnDragStart", function(self) self:StartMoving() end)
    arrow:SetScript("OnDragStop", function(self) self:StopMovingOrSizing(); SavePos(self) end)
    arrow.bg = S.Solid(arrow, "BACKGROUND", { 0.04, 0.043, 0.047 }, 0.6)
    arrow.bg:SetAllPoints()

    arrow.tex = arrow:CreateTexture(nil, "ARTWORK")
    arrow.tex:SetSize(60, 60)
    arrow.tex:SetPoint("TOPLEFT", 12, -12)
    -- the game's own smooth navigation arrow (the one of its tracked waypoints); the old minimap
    -- arrow only when this client has no such drawing
    -- WL Helper's own HD arrow (Media/Arrow.tga, 256 px, smooth at any scale)
    arrow.tex:SetTexture("Interface\\AddOns\\WLHelper\\Media\\Arrow")
    arrow.tex:SetSize(60, 60); arrow.tex:ClearAllPoints(); arrow.tex:SetPoint("TOPLEFT", 12, -12)
    arrow.icon = arrow:CreateTexture(nil, "ARTWORK")
    arrow.icon:SetSize(48, 48)
    arrow.icon:SetPoint("CENTER", arrow.tex, "CENTER")
    arrow.icon:Hide()

    arrow.big = S.Text(arrow, 22, C.text, true)
    arrow.big:SetPoint("TOPLEFT", 86, -14)
    arrow.big:SetPoint("RIGHT", -22, 0)   -- up to the close ×
    arrow.step = S.Text(arrow, 14, C.text)
    arrow.step:SetPoint("TOPLEFT", 86, -42)
    arrow.step:SetPoint("RIGHT", -22, 0)   -- up to the close ×
    arrow.sub = S.Text(arrow, 12, { 0.79, 0.8, 0.82 })
    arrow.sub:SetPoint("TOPLEFT", 86, -62)
    arrow.sub:SetPoint("RIGHT", -22, 0)   -- up to the close ×

    local close = S.CloseButton(arrow, 18, nil, nil, 8)
    close:SetPoint("TOPRIGHT", -2, -2)
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

    arrow.fly = S.Button(arrow, "", 246, 32, "primary", function() GPS.TakeFlight() end)
    arrow.fly:SetPoint("BOTTOM", 0, 10)
    arrow.fly:Hide()

    teleport = CreateFrame("Button", "WLGPSTeleport", UIParent, "SecureActionButtonTemplate")
    teleport:SetSize(246, 32)
    teleport:SetFrameStrata("MEDIUM")
    teleport:SetFrameLevel(arrow:GetFrameLevel() + 5)
    teleport:RegisterForClicks("AnyUp", "AnyDown")   -- the game acts on the press or the release (its "cast on key down" setting): both registered
    S.Solid(teleport, "BACKGROUND", { 0.086, 0.196, 0.290 }):SetAllPoints()
    S.Border(teleport, { 0.169, 0.353, 0.502 })
    -- what the click does, seen: lighter on hover, pressed look on click, then the cast's progress
    local hover = S.Solid(teleport, "HIGHLIGHT", { 1, 1, 1 }, 0.10); hover:SetAllPoints()
    local press = S.Solid(teleport, "ARTWORK", { 0, 0, 0 }, 0.35); press:SetAllPoints(); press:Hide()
    local fill = S.Solid(teleport, "BORDER", { 0.25, 0.55, 0.85 }, 0.55)
    fill:SetPoint("TOPLEFT", 1, -1); fill:SetPoint("BOTTOMLEFT", 1, 1); fill:SetWidth(1); fill:Hide()
    local tl = S.Text(teleport, 13, { 0.85, 0.93, 1 }, true)
    tl:SetPoint("CENTER")
    tl:SetText(L("Lancer la téléportation"))
    teleport.label = tl
    teleport:HookScript("OnMouseDown", function() press:Show(); tl:SetPoint("CENTER", 1, -1) end)
    teleport:HookScript("OnMouseUp", function() press:Hide(); tl:SetPoint("CENTER", 0, 0) end)
    teleport:HookScript("OnClick", function()
        tl:SetText(L("Téléportation demandée..."))
        C_Timer.After(1.5, function()
            if not teleport.casting then tl:SetText(L("Lancer la téléportation")) end
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
            tl:SetText(L("Téléportation en cours...")); fill:Show()
        elseif e == "UNIT_SPELLCAST_SUCCEEDED" then
            teleport.casting = false; fill:Hide(); tl:SetText(L("Lancer la téléportation"))
        else
            if teleport.casting then
                teleport.casting = false; fill:Hide()
                tl:SetText(L("Interrompue : clique pour recommencer"))
                C_Timer.After(3, function() if not teleport.casting then tl:SetText(L("Lancer la téléportation")) end end)
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

    local turnAcc, textAcc = 0, TEXT_EVERY
    arrow:SetScript("OnUpdate", function(self, elapsed)
        if demo then return end
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
end

-- After combat: the teleport button catches up with what the arrow shows now.
local ev = CreateFrame("Frame")
pcall(ev.RegisterEvent, ev, "PLAYER_REGEN_ENABLED")
ev:SetScript("OnEvent", function()
    -- restored here, not in SetTeleport (which returns early for the spell already shown)
    if teleport then teleport:SetAlpha(1); SetTeleport(WantedTeleport()) end
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

-- Shows the arrow with sample text so it can be dragged into place; the × locks it again.
function GPS.UnlockArrow()
    if not arrow then Build() end
    GPS.ApplyLook()
    demo = true
    arrow.icon:Hide(); arrow.tex:Show(); arrow.tex:SetRotation(0.3)
    arrow.tex:SetVertexColor(C.ready[1], C.ready[2], C.ready[3])
    SetText(arrow.big, L("Déplace-moi"))
    SetText(arrow.step, L("Glisse la flèche où tu veux"))
    SetText(arrow.sub, L("× pour terminer"))
    arrow.fly:Hide()
    SetTeleport(nil)
    arrow:Show()
end

function GPS.Lock()
    demo = false
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
