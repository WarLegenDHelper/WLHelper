-- Writs/Arrow.lua: the GPS HUD, readable while running. One column, centred:
--   the action, big: on a cast leg (a teleport, the Hearthstone, Astral Recall, Moonglade) the spell or
--   item icon IS the button (click it to cast); at the flight master the flight icon; at a dock the
--   boat icon; else the HD arrow (the HD check once you are there);
--   line 1, what to do ("Lance Téléportation : Fossoyeuse", "Va voir Woodwyrd");
--   line 2, where, in gold ("Fossoyeuse"); on the way to a zeppelin or boat and at its dock, when it
--   leaves, counting down ("Zeppelin pour Grom'gol dans 1:20", Transports.lua);
--   line 3, how far and how long ("550 m · 1:10": the walk left along the path when there is one,
--   the time from your speed's moving average, hidden while you stand still);
--   line 4, muted, the next legs when it has several ("Puis vol jusqu'à Orgrimmar > zeppelin pour
--   Undercity > vol jusqu'à Moulin-de-Tarren": its casts, flights and crossings and the last walk, at
--   most 3; after a teleport, "Puis 690 m jusqu'à Dran Droffers").
-- Lines wrap and the HUD grows with them: nothing is cut. The whole route, with the full names, is
-- in the HUD's tooltip. While the flight map is open a button takes the planned flight.
--
-- The cast button is secure, so it is parented AND anchored to UIParent (placed over the HUD's icon
-- spot out of combat): the HUD itself stays an ordinary frame that may move, resize, show and hide in
-- combat. Its attributes never change in combat: a cast leg that comes in combat shows its icon
-- (not clickable) and the button is set after the fight. The text is redrawn 4 times a second, only
-- when it changes; the arrow turns 20 times.
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
    ["Va voir %s"] = "Go to %s",
    ["Dans le donjon"] = "Inside the dungeon",
    ["Parle au maître de vol"] = "Talk to the flight master",
    ["Vol pour %s"] = "Flight to %s",
    ["Prendre ce vol"] = "Take this flight",
    ["Lance %s"] = "Cast %s",
    ["Utilise %s"] = "Use %s",
    ["Utilise ta pierre de foyer"] = "Use your Hearthstone",
    ["Attends le bateau"] = "Wait for the boat",
    ["Attends le zeppelin"] = "Wait for the zeppelin",
    ["Autre continent"] = "Other continent",
    ["Pas d'itinéraire connu : la flèche va tout droit."] = "No known route: the arrow points straight there.",
    ["Parle à un maître de vol : le GPS apprendra tes trajets."] = "Talk to a flight master: the GPS will learn your routes.",
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
    ["Clic : lancer %s"] = "Click: cast %s",
    ["Clic : utiliser %s"] = "Click: use %s",
    ["La téléportation attend la fin du combat."] = "The teleport waits for the end of the fight.",
    ["En vol vers %s"] = "Flying to %s",
    -- the itinerary line comes after the leg under way: "Puis 690 m jusqu'à Dran Droffers"
    ["puis %s"] = "then %s",
    ["Alt-clic : prendre l'autre trajet"] = "Alt-click: take the other route",
})

local arrow, teleport, demo
local ICON_LINK = "Interface\\Icons\\INV_Misc_Map_01"
local ICON_DUNGEON = "Interface\\Icons\\INV_Misc_Key_03"
local HEARTHSTONE = 6948
local TURN_EVERY, TEXT_EVERY = 0.05, 0.25
-- HUD-like width (design system: 360). The action icon 48 px, centred at the top; the lines under it,
-- centred, 16 from each edge; the close button (28 px hit area at -4, -4) beside the icon.
local HUD_W, ICON, PAD = 360, 48, 12
local ARROW_SIZE = ICON
local LINE_W = HUD_W - 32
local ICON_X = (HUD_W - ICON) / 2
local BTN_H = 32
local MOVING = 0.5          -- yards a second: slower than this, you stand (no time shown)
local AVG_OVER = 4          -- seconds: the speed's moving average

local function IsSecret(v) return root.IsSecret and root.IsSecret(v) end
local function Num(v) if type(v) == "number" and not IsSecret(v) then return v end end
local function Str(v) if type(v) == "string" and not IsSecret(v) and v ~= "" then return v end end
local function Clock() return GetTime and GetTime() or 0 end

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

-- "1:10", "12:05", "1:02:30"
local function Duration(seconds)
    local s = math.floor(seconds + 0.5)
    if s >= 3600 then return string.format("%d:%02d:%02d", math.floor(s / 3600), math.floor(s / 60) % 60, s % 60) end
    return string.format("%d:%02d", math.floor(s / 60), s % 60)
end

local function SpellIcon(id)
    if C_Spell and C_Spell.GetSpellTexture then
        local ok, t = pcall(C_Spell.GetSpellTexture, id)
        if ok and t and not IsSecret(t) then return t end
    end
    if GetSpellTexture then
        local ok, t = pcall(GetSpellTexture, id)
        if ok and t and not IsSecret(t) then return t end
    end
    return ICON_LINK
end

local function ItemIcon(id)
    local f = (C_Item and C_Item.GetItemIconByID) or GetItemIcon
    if f then
        local ok, t = pcall(f, id)
        if ok and t and not IsSecret(t) then return t end
    end
    return "Interface\\Icons\\INV_Misc_Rune_01"
end

-- The spell's name in the client's language ("Téléportation : Fossoyeuse"), nil when unknown.
local function SpellName(id)
    if not id then return nil end
    if C_Spell and C_Spell.GetSpellName then
        local ok, n = pcall(C_Spell.GetSpellName, id)
        if ok and Str(n) then return n end
    end
    if C_Spell and C_Spell.GetSpellInfo then
        local ok, info = pcall(C_Spell.GetSpellInfo, id)
        if ok and type(info) == "table" and Str(info.name) then return info.name end
    end
    if GetSpellInfo then
        local ok, n = pcall(GetSpellInfo, id)
        if ok and Str(n) then return n end
    end
end

-- A place's short name ("Brackenwall Village"), "" when there is none.
local function Place(name)
    if type(name) ~= "string" or name == "" then return "" end
    return GPS.ShortPlace(name) or ""
end

-- A zeppelin's or boat's departure from `dock` (a GPS dock point), live (Transports.lua): "Zeppelin
-- pour Grom'gol dans 1:20" in green, "à quai, part dans 0:35" in gold (under 30 s in amber), "~2 min
-- (estimé)" muted. "" for a druid's flight or when the timing module is not there.
local function ShipLine(dock)
    local T = WP.Transports
    local l = dock and dock.link
    if not (T and T.Line and l and l.mode ~= "flight") then return "" end
    local ok, text, color = pcall(T.Line, l, dock.start == true, Place(dock.other and dock.other.name))
    if not ok or type(text) ~= "string" then return "" end
    return S.Hex(C[color] or C.muted) .. text .. "|r"
end
GPS._ShipLine = ShipLine

local function CastIcon(kind, id)
    if kind == "item" then return ItemIcon(id) end
    return SpellIcon(id)
end

-- The cast's name: the spell's or the item's ("Pierre de foyer" when the game has not loaded it yet).
local function CastName(kind, id, leg)
    if kind == "item" then return WP.ItemName(id, L("Pierre de foyer")) end
    return SpellName(id) or (leg and GPS.Describe(leg)) or L("Lancer la téléportation")
end

-- Line 1 of a cast leg: "Lance Téléportation : Fossoyeuse", "Utilise ta pierre de foyer".
local function CastWhat(kind, id, leg)
    if kind == "item" then
        if id == HEARTHSTONE then return L("Utilise ta pierre de foyer") end
        return string.format(L("Utilise %s"), CastName(kind, id, leg))
    end
    return string.format(L("Lance %s"), CastName(kind, id, leg))
end

-- Sets a font string only when the value changes (no work, no garbage when it doesn't); true when it did.
local function SetText(fs, t)
    t = t or ""
    if fs.cur ~= t then fs.cur = t; fs:SetText(t); return true end
    return false
end

-- The big visual: "arrow" (the HD arrow turns), "painted" (a game icon), "here" (the HD check),
-- "cast" (the secure button draws the icon itself). True when it changed.
local function SetVisual(self, mode, path)
    local key = mode .. ":" .. tostring(path)
    if self.visual == key then return false end
    self.visual = key
    self.tex:SetShown(mode == "arrow")
    self.icon:SetShown(mode == "painted" or mode == "here")
    if mode == "painted" then
        S.Painted(self.icon, path, ICON)
        self.icon:SetVertexColor(1, 1, 1, 1)
        self.icon:SetDesaturated(false)
    elseif mode == "here" then
        S.HDIcon(self.icon, "check", C.ok)
        self.icon:SetSize(40, 40)
    end
    return true
end

-- ---------------------------------------------------------------- speed

-- Your speed, sampled each redraw: the game's own (GetUnitSpeed) when readable, else from how far you
-- moved. speedNow: this sample; speedAvg: its moving average over about AVG_OVER seconds of moving.
local speedNow, speedAvg
local lastC, lastX, lastY, lastT
local function SampleSpeed(now)
    local t = Clock()
    local v
    if GetUnitSpeed then
        local ok, s = pcall(GetUnitSpeed, "player")
        if ok then v = Num(s) end
    end
    local dt = lastT and (t - lastT) or 0
    if not v and lastT and dt > 0 and now.cont and now.cont == lastC and Num(now.px) and Num(now.py) then
        local dx, dy = now.px - lastX, now.py - lastY
        v = math.sqrt(dx * dx + dy * dy) / dt
    end
    if Num(now.px) and Num(now.py) then lastC, lastX, lastY = now.cont, now.px, now.py else lastC = nil end
    lastT = t
    speedNow = v
    if v and v > MOVING then
        if speedAvg and dt > 0 then
            speedAvg = speedAvg + (v - speedAvg) * math.min(1, dt / AVG_OVER)
        else
            speedAvg = v
        end
    end
end

-- "550 m · 1:10": the distance in the warm accent, the time in fg (only while you move).
local function DistLine(yards)
    local d = S.Hex(C.accentSoft) .. Distance(yards) .. "|r"
    if speedNow and speedNow > MOVING and speedAvg and speedAvg > MOVING then
        local secs = yards / speedAvg
        if secs < 5 * 3600 then
            return d .. S.Hex(C.muted) .. "  \194\183  |r" .. Duration(secs)
        end
    end
    return d
end

-- ---------------------------------------------------------------- layout

-- The column: the icon, then the lines that have text, then the flight button when there is one.
-- Called only when a line comes, goes or changes length (not for the distance ticking down).
local function Layout(self)
    local top = PAD + ICON + 8
    local y = top
    local function line(fs, maxLines, gap)
        if (fs.cur or "") == "" then fs:Hide() return end
        fs:Show()
        if y > top then y = y + gap end
        fs:ClearAllPoints(); fs:SetPoint("TOP", self, "TOP", 0, -y)
        local h = S.FitText(fs, maxLines, LINE_W, self)
        if h < fs.size then h = fs.size + 2 end
        y = y + h
    end
    line(self.goal, 2, 0)
    line(self.what, 2, 6)
    line(self.where, 2, 2)
    line(self.dist, 1, 4)
    line(self.route, 3, 6)
    local okH, h = pcall(self.route.GetStringHeight, self.route)
    self.routeH = okH and Num(h) or 0
    y = y + PAD
    self.btnY = y
    if self.button then y = y + BTN_H + PAD end
    y = math.ceil(y)
    if self.h ~= y then self.h = y; self:SetHeight(y) end
    self.fly:ClearAllPoints(); self.fly:SetPoint("TOPLEFT", PAD, -self.btnY)
end

-- ---------------------------------------------------------------- the cast button

-- Put over the HUD's icon spot, in UIParent coordinates (both frames share the scale). Out of combat only.
local function PlaceTeleport()
    if not (teleport and arrow) or InCombatLockdown() then return end
    local left, top = arrow:GetLeft(), arrow:GetTop()
    if not (left and top) then return end
    teleport:SetScale(arrow:GetScale())
    teleport:ClearAllPoints()
    teleport:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left + ICON_X, top - PAD)
end

-- The cast's cooldown on the button, when the game gives readable numbers (they may be secret).
local shownSpell, shownKind, shownId = false, nil, nil
local function RefreshCooldown()
    local cd = teleport and teleport.cd
    if not cd then return end
    local s, d
    if shownKind == "item" then
        local f = (C_Container and C_Container.GetItemCooldown) or GetItemCooldown
        if f then
            local ok, a, b = pcall(f, shownId)
            if ok then s, d = Num(a), Num(b) end
        end
    elseif shownKind == "spell" then
        if C_Spell and C_Spell.GetSpellCooldown then
            local ok, info = pcall(C_Spell.GetSpellCooldown, shownId)
            if ok and type(info) == "table" then
                local ok2, a, b = pcall(function() return info.startTime, info.duration end)
                if ok2 then s, d = Num(a), Num(b) end
            end
        elseif GetSpellCooldown then
            local ok, a, b = pcall(GetSpellCooldown, shownId)
            if ok then s, d = Num(a), Num(b) end
        end
    end
    if s and d and d > 1.5 then
        pcall(cd.SetCooldown, cd, s, d)
    else
        if not (cd.Clear and pcall(cd.Clear, cd)) then pcall(cd.SetCooldown, cd, 0, 0) end
    end
end

-- Shows the button for this spell (kind "spell") or item (kind "item": the Hearthstone), or hides it
-- (no kind). Out of combat only: in combat the change waits (PLAYER_REGEN_ENABLED sets it).
local function SetTeleport(kind, id)
    if not teleport then return end
    if InCombatLockdown() then
        teleport.pending = true
        return
    end
    teleport.pending = nil
    if not id then kind = nil end
    local key = kind and (kind .. ":" .. tostring(id)) or nil
    if key == shownSpell then return end
    shownSpell, shownKind, shownId = key, kind, id
    -- another cast (or none): the bar and the "in progress" of the last one go
    if teleport.ResetCast then teleport.ResetCast() end
    if kind == "item" then
        teleport:SetAttribute("type", "item")
        teleport:SetAttribute("spell", nil)
        teleport:SetAttribute("item", "item:" .. id)
    elseif kind then
        teleport:SetAttribute("type", "spell")
        teleport:SetAttribute("item", nil)
        teleport:SetAttribute("spell", id)
    end
    if kind then
        teleport.tex:SetTexture(CastIcon(kind, id))
        PlaceTeleport()
        teleport:Show()
        RefreshCooldown()
    else
        teleport:Hide()
        if teleport.ResetLook then teleport.ResetLook() end   -- hidden under the mouse: no hover left on
    end
end

-- The cast the current leg wants: "spell"/"item", id (GPS.CastOf), or nil.
local function CastOf(leg)
    if GPS.CastOf then return GPS.CastOf(leg) end
    if leg and leg.kind == "teleport" then return "spell", leg.to.spell end
end

local function WantedTeleport()
    if not (arrow and arrow:IsShown()) or demo then return nil end
    return CastOf(GPS.TeleportLeg())
end

-- What the cast is doing, shown as line 1 for a moment: requested, casting, interrupted.
local castNote, castNoteUntil, casting = nil, 0, false
local clickedAt = -100     -- when the button was last clicked: a cast starting just after is ours
local flyStart             -- when the current flight started (Clock), nil when not on a taxi
local function Note(text, seconds)
    castNote, castNoteUntil = text, Clock() + (seconds or 0)
    if arrow then arrow.redraw = true end
end

-- ---------------------------------------------------------------- drawing

local function Draw(self, now, combat)
    local leg, legs = now.leg, now.legs
    local n = legs and #legs or 0
    local changed = false
    local function T(fs, t) if SetText(fs, t) then changed = true end end
    local what, where, dist, route, goal = "", "", "", "", ""
    local told             -- a leg already said on line 2 (the ride after a flight)
    local button = nil
    self.turn = false
    self.arrived = now.arrived and true or false
    -- on a flight the plan stays on its "fly" leg until the landing (GPS.Replan waits): the clock
    -- starts when the taxi does
    local onTaxi = UnitOnTaxi and UnitOnTaxi("player") == true or false
    if onTaxi then flyStart = flyStart or Clock() else flyStart = nil end

    local castLeg = leg and (leg.kind == "teleport" or leg.kind == "hearth") and not now.arrived
    local kind, id
    if castLeg then kind, id = CastOf(leg) end
    if not id then kind = nil end
    SetTeleport(kind, id)          -- waits for the end of the fight when in combat
    local wantKey = kind and (kind .. ":" .. tostring(id)) or nil
    local ready = wantKey ~= nil and shownSpell == wantKey

    if now.arrived then
        if SetVisual(self, "here") then changed = true end
        what = L("Tu y es")
        local w = now.dest and now.dest.writ
        where = w and w.npcName and string.format(L("Parle à %s"), w.npcName) or (now.dest and now.dest.name) or ""
        route = (w and w.item and WP.ItemName(w.item, w.itemName)) or (w and w.itemName) or ""
    elseif now.spf then
        -- Shortest Path's route under our arrow: its legs in its own words, the arrow on its next point
        if SetVisual(self, "arrow") then changed = true end
        self.turn = true
        local sl = now.spf.legs
        what = sl[1] and sl[1].text or L("Shortest Path calcule le trajet...")
        if sl[2] then where = GPS.UpperFirst(string.format(L("puis %s"), sl[2].text)) end
        dist = now.dist and DistLine(now.dist) or (S.Hex(C.muted) .. L("Autre continent") .. "|r")
        local rest = {}
        for i = 3, math.min(#sl, 5) do rest[#rest + 1] = sl[i].text end
        route = table.concat(rest, GPS.SEP or " > ")
    elseif not now.map and IsInInstance and IsInInstance() then
        -- inside a dungeon there is no map position: the place alone
        if SetVisual(self, "painted", ICON_DUNGEON) then changed = true end
        what = L("Dans le donjon")
        where = now.dest and now.dest.name or ""
    elseif castLeg and kind then
        -- the icon is the button; in combat before it was set, the icon alone (not clickable)
        if SetVisual(self, ready and "cast" or "painted", ready and wantKey or CastIcon(kind, id)) then changed = true end
        if casting then what = L("Téléportation en cours...")
        elseif castNote and Clock() < castNoteUntil then what = castNote
        else what = CastWhat(kind, id, leg) end
        where = Place(leg.to and leg.to.name)
        if combat then dist = S.Hex(C.warn) .. L("La téléportation attend la fin du combat.") .. "|r" end
    elseif leg and leg.kind == "fly" then
        if SetVisual(self, "painted", FlyIcon()) then changed = true end
        local mapOpen = (TaxiFrame and TaxiFrame:IsShown()) or (FlightMapFrame and FlightMapFrame:IsShown())
        local place = Place(leg.to and leg.to.name)
        if onTaxi then
            -- in the air (the plan waits for the landing): where to, then what comes after, and the
            -- time left from the flight's own estimate
            what = string.format(L("En vol vers %s"), place ~= "" and place or "?")
            where = legs and legs[2] and GPS.DescribeNext(legs[2]) or ""
            -- a ride after the landing: line 2 says how far and to whom ("Puis 1,2 km jusqu'à
            -- Tabetha"), and the itinerary line does not tell it again
            if legs and legs[2] and legs[2].kind == "ride" and GPS.Itinerary then
                local okI, items = pcall(GPS.Itinerary, { leg, legs[2] })
                local it = okI and type(items) == "table" and items[2]
                if it and type(it.text) == "string" and it.text ~= "" then
                    where = GPS.UpperFirst(string.format(L("puis %s"), it.text))
                    told = legs[2]
                end
            end
            if type(leg.seconds) == "number" and flyStart then
                dist = S.Hex(C.muted) .. Duration(math.max(0, leg.seconds - (Clock() - flyStart))) .. "|r"
            end
        elseif mapOpen then
            -- the map is open: the sentence names the place, the button takes the flight
            what = GPS.Describe(leg)
            button = "fly"
        else
            what = L("Parle au maître de vol")
            where = place ~= "" and string.format(L("Vol pour %s"), place) or ""
        end
    else
        -- riding (or waiting for a boat or zeppelin at its dock): the arrow
        local atDock = leg and leg.kind == "link" and now.dist and now.dist < 30
        local mode = atDock and leg.from and leg.from.link and leg.from.link.mode
        if atDock and mode == "flight" then
            -- a druid's flight home: talk to the flight master
            if SetVisual(self, "painted", FlyIcon()) then changed = true end
            what = L("Parle au maître de vol")
            local p = Place(leg.to and leg.to.name)
            where = p ~= "" and string.format(L("Vol pour %s"), p) or ""
        elseif atDock then
            if SetVisual(self, "painted", ICON_LINK) then changed = true end
            what = mode == "boat" and L("Attends le bateau") or L("Attends le zeppelin")
            -- when it leaves, counting down; the place alone when it is not known
            where = ShipLine(leg.from)
            if where == "" then where = Place(leg.to and leg.to.name) end
        else
            if SetVisual(self, "arrow") then changed = true end
            self.turn = true
            local final = not leg or (leg.kind == "ride" and leg.to and leg.to.kind ~= "taxi" and leg.to.kind ~= "dock")
            local dest = now.dest
            if final then
                local w = dest and dest.writ
                if w and w.npcName then what = string.format(L("Va voir %s"), w.npcName)
                else what = GPS.UpperFirst(dest and dest.name or (leg and leg.to and leg.to.name) or "") end
                -- the zone, when it is not the one you are in
                if dest and dest.map and now.map and dest.map ~= now.map and WP.ZoneName then
                    local z = WP.ZoneName(dest.map)
                    if z ~= tostring(dest.map) and z ~= "?" then where = z end
                end
            else
                what = GPS.Describe(leg)
                -- on the way to a zeppelin or a boat: when it leaves ("Zeppelin pour Grom'gol dans 1:20")
                if leg and leg.kind == "ride" and leg.to and leg.to.kind == "dock" then where = ShipLine(leg.to) end
            end
            dist = now.dist and DistLine(now.dist) or (S.Hex(C.muted) .. L("Autre continent") .. "|r")
        end
        -- a long ride with no flight: why, in one muted line (T-89); worked out once per plan
        local note
        if legs and GPS.RideNote then
            if self.noteLegs ~= legs then
                local okN, s = pcall(GPS.RideNote, legs)
                self.noteLegs, self.note = legs, okN and type(s) == "string" and s or nil
            end
            note = self.note
        end
        if not legs then
            route = L("Pas d'itinéraire connu : la flèche va tout droit.")
        elseif note then
            route = note
        elseif GPS.KnownFlights() == 0 then
            route = L("Parle à un maître de vol : le GPS apprendra tes trajets.")
        end
    end

    -- the next legs in one muted line ("Puis vol jusqu'à Orgrimmar > zeppelin pour Undercity > vol
    -- jusqu'à Moulin-de-Tarren"), when the way has more than one leg and you are not there yet: the leg
    -- under way is lines 1-3 already (its walk measured along the trail there), so it is not told twice;
    -- the walks between two crossings are left out and at most 3 legs are told (the tooltip lists every
    -- leg); "puis": it comes after that leg
    if not now.arrived and legs and n > 1 and GPS.Itinerary and GPS.NextLegs then
        local okR, items = pcall(GPS.Itinerary, legs)
        if okR and type(items) == "table" then
            local parts = GPS.NextLegs(items, 3, function(it) return it.leg == leg or it.leg == told end)
            if #parts > 0 then
                parts[1] = GPS.UpperFirst(string.format(L("puis %s"), parts[1]))
                route = table.concat(parts, GPS.SEP or " > ")
            end
        end
    end
    -- a supposed flight path ahead (Route.lua's guess, a continent with no flight map opened yet): the
    -- line says to check it on the flight master's map (opening it ends the guess, the plan is made again)
    if not now.arrived and not onTaxi and legs and GPS.GuessedFlight and GPS.GuessedFlight(legs) then
        route = L("Vol supposé connu : ouvre la carte du maître de vol pour vérifier")
    end

    -- the trip's end, on top while a leg on the way is told (a flight, a ship, a walk to a dock): you
    -- always see where all this goes ("Destination : Moulin-de-Tarren, Contreforts de Hautebrande ~12 min")
    if now.spf then
        local d = now.dest
        if not now.arrived and d and d.name and #now.spf.legs > 1 then
            goal = S.Hex(C.gold) .. string.format(L("Destination : %s"), d.name) .. "|r"
            local mins = now.spf.left and GPS.Minutes(now.spf.left)
            if mins then goal = goal .. S.Hex(C.muted) .. "  " .. mins .. "|r" end
        end
    elseif not now.arrived and now.dest and legs and n > 0 then
        local last = legs[n]
        local finalNow = n == 1 and leg and leg.kind == "ride"
        if not finalNow then
            local d = now.dest
            local w = d.writ
            local name = (w and w.npcName) or d.name or (last and last.to and last.to.name)
            if name and name ~= "" then
                local z = d.map and WP.ZoneName and WP.ZoneName(d.map)
                if z and z ~= tostring(d.map) and z ~= "?" and z ~= name then name = name .. ", " .. z end
                goal = S.Hex(C.gold) .. string.format(L("Destination : %s"), name) .. "|r"
                local mins = GPS.TripMinutes and GPS.TripMinutes()
                if mins then goal = goal .. S.Hex(C.muted) .. "  " .. mins .. "|r" end
            end
        end
    end
    if SetText(self.goal, goal) then changed = true end
    T(self.what, what)
    T(self.where, where)
    -- the distance and the itinerary's walks count down every tick: lay the HUD out again only when a
    -- line comes or goes, or the itinerary wraps to another number of lines
    local was = self.dist.cur or ""
    if SetText(self.dist, dist) and ((was == "") ~= (dist == "")) then changed = true end
    was = self.route.cur or ""
    if SetText(self.route, route) then
        if (was == "") ~= (route == "") then
            changed = true
        elseif route ~= "" then
            local okH, h = pcall(self.route.GetStringHeight, self.route)
            if okH and Num(h) and math.abs(h - (self.routeH or 0)) > 0.5 then changed = true end
        end
    end

    -- the flight button
    self.fly:SetShown(button == "fly")
    if button == "fly" then
        if combat then self.fly:Disable() else self.fly:Enable() end
        self.flyTitle = GPS.Describe(leg, true)
    end
    if button ~= self.button then self.button = button; changed = true end
    if changed then Layout(self); PlaceTeleport() end

    -- the secure button follows the HUD's alpha; in combat, one left from a leg already done goes
    -- transparent (it cannot hide before the fight ends)
    if teleport and teleport:IsShown() then
        teleport:SetAlpha((combat and shownSpell ~= wantKey) and 0 or self:GetAlpha())
    end
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
    -- the time of this trip and the runner-up ("Autre trajet : zeppelin pour Grom'gol, puis vol jusqu'à
    -- Kargath (~6 min)"): Alt-click takes it
    local mins = GPS.TripMinutes and GPS.TripMinutes()
    local alt = GPS.Alternative and GPS.Alternative()
    if mins then lines[#lines + 1] = { string.format(L("Ce trajet : %s"), mins), C.fg[1], C.fg[2], C.fg[3] } end
    if alt then
        lines[#lines + 1] = { alt.text, C.gold[1], C.gold[2], C.gold[3] }
        lines[#lines + 1] = L("Alt-clic : prendre l'autre trajet")
    end
    lines[#lines + 1] = L("Glisser : déplacer la flèche")
    S.Tip(self, lines)
end
GPS._RouteTip = function(self) return RouteTip(self) end

-- ---------------------------------------------------------------- the frame

local function SavePos(self)
    -- kept as TOPLEFT so a taller HUD grows downward and the icon stays put
    local left, top = self:GetLeft(), self:GetTop()
    if not (left and top) then return end
    self:ClearAllPoints()
    self:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
    WLWritsDB.arrowPos = { "TOPLEFT", "BOTTOMLEFT", left, top }
    PlaceTeleport()
end

local function Line(parent, size, color, bold, maxLines)
    local fs = S.Text(parent, size, color, bold)
    fs.size = size
    fs:SetJustifyH("CENTER"); fs:SetJustifyV("TOP")
    fs:SetWidth(LINE_W)
    if fs.SetMaxLines then fs:SetMaxLines(maxLines) end
    root.Shadow(fs, true)
    return fs
end

local function BuildTeleport()
    -- the cast: a secure button that IS the big icon (48 px, square, 1 px accent ring)
    teleport = CreateFrame("Button", "WLGPSTeleport", UIParent, "SecureActionButtonTemplate")
    teleport.wlOwned = true
    teleport:SetSize(ICON, ICON)
    teleport:SetFrameStrata("HIGH")
    teleport:SetFrameLevel(arrow:GetFrameLevel() + 5)
    teleport:RegisterForClicks("AnyUp", "AnyDown")   -- the game acts on the press or the release (its "cast on key down" setting): both registered
    S.Solid(teleport, "BACKGROUND", C.bg, 0.92):SetAllPoints()
    local tex = teleport:CreateTexture(nil, "ARTWORK")
    tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    tex:SetPoint("TOPLEFT", 1, -1); tex:SetPoint("BOTTOMRIGHT", -1, 1)
    teleport.tex = tex
    local ring = S.Border(teleport, C.accent, 0.55)
    -- the cooldown's swipe over the icon, when readable
    local okCd, cd = pcall(CreateFrame, "Cooldown", nil, teleport, "CooldownFrameTemplate")
    if okCd and cd then
        cd:SetAllPoints(tex)
        pcall(cd.SetDrawEdge, cd, false)
        teleport.cd = cd
    end
    -- what the click does, seen: lighter on hover, pressed look on click, then the cast's progress
    local hover = S.Solid(teleport, "OVERLAY", C.hoverFill); hover:SetAllPoints(tex); hover:SetAlpha(0)
    local press = S.Solid(teleport, "OVERLAY", C.pressFill); press:SetAllPoints(tex); press:Hide()
    local fill = S.Solid(teleport, "OVERLAY", C.accent, 0.35)
    fill:SetPoint("BOTTOMLEFT", 1, 1); fill:SetPoint("BOTTOMRIGHT", -1, 1); fill:SetHeight(1); fill:Hide()
    teleport:HookScript("OnEnter", function(self)
        hover:SetAlpha(1); ring(C.accent, 1)
        local leg = GPS.TeleportLeg()
        local name = CastName(shownKind, shownId, leg)
        local lines = { (leg and leg.to and leg.to.name) or L("Lancer la téléportation"),
            string.format(shownKind == "item" and L("Clic : utiliser %s") or L("Clic : lancer %s"), name) }
        if InCombatLockdown() then lines[#lines + 1] = { L("La téléportation attend la fin du combat."), C.warn[1], C.warn[2], C.warn[3] } end
        S.Tip(self, lines)
    end)
    teleport:HookScript("OnLeave", function() hover:SetAlpha(0); ring(C.accent, 0.55); S.HideTip() end)
    teleport:HookScript("OnMouseDown", function()
        press:Show(); tex:SetPoint("TOPLEFT", 2, -2); tex:SetPoint("BOTTOMRIGHT", 0, 0)
    end)
    teleport:HookScript("OnMouseUp", function()
        press:Hide(); tex:SetPoint("TOPLEFT", 1, -1); tex:SetPoint("BOTTOMRIGHT", -1, 1)
    end)
    teleport:HookScript("OnClick", function()
        if InCombatLockdown() then return end    -- the cast cannot start: no "requested"
        clickedAt = Clock()
        if not casting then Note(L("Téléportation demandée..."), 1.5) end
    end)
    teleport.ResetLook = function()
        hover:SetAlpha(0); ring(C.accent, 0.55); press:Hide()
        tex:SetPoint("TOPLEFT", 1, -1); tex:SetPoint("BOTTOMRIGHT", -1, 1)
    end
    teleport.ResetCast = function()
        casting = false; fill:Hide(); fill:SetHeight(1)
    end
    -- the cast bar inside the icon, from the bottom: filled from the player's cast (numbers read
    -- under pcall, they may be secret on this client)
    local cev = CreateFrame("Frame", nil, teleport)
    for _, e in ipairs({ "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_STOP", "UNIT_SPELLCAST_FAILED", "UNIT_SPELLCAST_INTERRUPTED", "UNIT_SPELLCAST_SUCCEEDED" }) do
        pcall(cev.RegisterUnitEvent or cev.RegisterEvent, cev, e, "player")
    end
    pcall(cev.RegisterEvent, cev, "SPELL_UPDATE_COOLDOWN")
    pcall(cev.RegisterEvent, cev, "BAG_UPDATE_COOLDOWN")
    cev:SetScript("OnEvent", function(_, e, unit, _, spellID)
        if e == "SPELL_UPDATE_COOLDOWN" or e == "BAG_UPDATE_COOLDOWN" then
            if teleport:IsShown() then RefreshCooldown() end
            return
        end
        if unit ~= "player" then return end
        if e == "UNIT_SPELLCAST_START" then
            -- only the button's own cast: its spell, or (an item, a secret id) one started just after
            -- a click; a mount or any other spell is not the teleport
            if not teleport:IsShown() then return end
            local sid = Num(spellID)
            local ours = (shownKind == "spell" and sid ~= nil and sid == shownId) or (Clock() - clickedAt < 2)
            if not ours then return end
            casting = true; fill:Show(); Note(nil)
        elseif not casting then
            return
        elseif shownKind == "spell" and Num(spellID) and Num(spellID) ~= shownId then
            return      -- another spell refused during the cast ("another action is in progress")
        elseif e == "UNIT_SPELLCAST_SUCCEEDED" then
            -- the end resets even when the button hid meanwhile (Stop pressed, leg changed)
            casting = false; fill:Hide(); Note(nil)
        else
            casting = false; fill:Hide()
            if teleport:IsShown() then Note(L("Interrompue : clique pour relancer"), 3) end
        end
    end)
    teleport:HookScript("OnUpdate", function(self)
        if not casting then return end
        local ok, k = pcall(function()
            local _, _, _, startMS, endMS = UnitCastingInfo("player")
            if not (startMS and endMS) or endMS <= startMS then return nil end
            return math.max(0, math.min(1, (GetTime() * 1000 - startMS) / (endMS - startMS)))
        end)
        if ok and k then fill:SetHeight(math.max(1, (ICON - 2) * k)) end
    end)
    -- in combat the button may not hide: when its leg is done or the HUD is closed it only goes
    -- transparent. The secure wrap drops every click in combat, so a button you cannot see never casts
    -- (the HUD says the teleport waits for the end of the fight).
    if SecureHandlerWrapScript and not teleport.wlWrapped then
        local okH, hdr = pcall(CreateFrame, "Frame", nil, UIParent, "SecureHandlerBaseTemplate")
        if okH and hdr and pcall(SecureHandlerWrapScript, teleport, "OnClick", hdr, "if PlayerInCombat() then return false end") then
            teleport.wlWrapped = true
        end
    end
    teleport:Hide()
end

local function Build()
    arrow = CreateFrame("Frame", "WLGPSArrow", UIParent)
    arrow.wlOwned = true
    arrow.wlWorld = true            -- text drawn over the world: with a shadow
    arrow:SetSize(HUD_W, PAD + ICON + PAD)
    local pos = WLWritsDB.arrowPos
    if pos then arrow:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4]) else arrow:SetPoint("TOP", 0, -150) end
    arrow:SetFrameStrata("HIGH")   -- above unit frames and action bars (EllesmereUI and others draw at MEDIUM)
    arrow:SetClampedToScreen(true)
    arrow:SetMovable(true)
    arrow:EnableMouse(true)
    arrow:RegisterForDrag("LeftButton")
    arrow:SetScript("OnDragStart", function(self)
        self.dragged = true
        -- in combat the cast button cannot follow: the HUD stays with it
        if InCombatLockdown() and teleport and teleport:IsShown() then return end
        self:StartMoving(); self.moving = true
    end)
    -- Alt-click: the other trip (the runner-up the tooltip tells); a drag is no click
    arrow:SetScript("OnMouseDown", function(self) self.dragged = nil end)
    arrow:SetScript("OnMouseUp", function(self, button)
        if demo or self.dragged or button ~= "LeftButton" then return end
        if not (IsAltKeyDown and IsAltKeyDown()) then return end
        if GPS.TakeAlternative and GPS.TakeAlternative() then
            self.redraw = true
            if GameTooltip and GameTooltip.IsOwned and GameTooltip:IsOwned(self) then RouteTip(self) end
        end
    end)
    arrow:SetScript("OnDragStop", function(self) self:StopMovingOrSizing(); self.moving = nil; SavePos(self) end)
    arrow:SetScript("OnEnter", RouteTip)
    arrow:SetScript("OnLeave", S.HideTip)
    -- the optional box under the HUD (options: opacity, 0 by default)
    arrow.bg = S.Solid(arrow, "BACKGROUND", C.bg, 1)
    arrow.bg:SetAllPoints()

    -- WL Helper's own HD arrow (Media/Arrow.tga, smooth at any scale), centred at the top
    arrow.tex = arrow:CreateTexture(nil, "ARTWORK")
    arrow.tex:SetTexture("Interface\\AddOns\\WLHelper\\Media\\Arrow")
    arrow.tex:SetSize(ARROW_SIZE, ARROW_SIZE)
    arrow.tex:SetPoint("TOPLEFT", ICON_X, -PAD)
    -- or a painted icon (flight, boat, dungeon, a cast not clickable yet), or the check
    arrow.icon = arrow:CreateTexture(nil, "ARTWORK")
    arrow.icon:SetSize(ICON, ICON)
    arrow.icon:SetPoint("CENTER", arrow.tex, "CENTER")
    arrow.icon:Hide()

    -- line 1 what to do, line 2 where, line 3 how far and how long, line 4 the whole way
    arrow.goal = Line(arrow, S.F.label, C.gold, true, 2)
    arrow.what = Line(arrow, S.F.heading, C.fg, true, 2)
    arrow.where = Line(arrow, S.F.label, C.gold, false, 2)
    arrow.dist = Line(arrow, S.F.body, C.fg, true, 1)
    arrow.route = Line(arrow, S.F.meta, C.muted, false, 3)

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

    arrow.fly = S.Button(arrow, L("Prendre ce vol"), HUD_W - 2 * PAD, BTN_H, "primary", function() GPS.TakeFlight() end,
        function()
            if arrow.fly:IsEnabled() == false then return nil end   -- the label and its reason, once
            return { arrow.flyTitle or L("Prendre ce vol"), L("Clic : prendre ce vol") }
        end)
    arrow.fly:SetIcon("flag")
    arrow.fly:SetDisabledReason(L("Indisponible en combat"))
    arrow.fly:Hide()

    -- the secure button cannot be made in combat (size, strata, clicks are protected): after the fight
    if not InCombatLockdown() then BuildTeleport() end

    local turnAcc, textAcc, pulse = 0, TEXT_EVERY, 0
    arrow:SetScript("OnUpdate", function(self, elapsed)
        if demo then
            if self.moving then PlaceTeleport() end
            return
        end
        -- the only looping animation: a slow pulse on the check once you are there
        if self.arrived then
            pulse = (pulse + elapsed) % 1.2
            self.icon:SetAlpha(0.8 + 0.2 * math.cos(pulse / 1.2 * 2 * math.pi))
        elseif pulse ~= 0 then
            pulse = 0; self.icon:SetAlpha(1)
        end
        turnAcc, textAcc = turnAcc + elapsed, textAcc + elapsed
        if self.redraw then self.redraw = nil; textAcc = TEXT_EVERY; turnAcc = TURN_EVERY end
        if turnAcc < TURN_EVERY then return end
        turnAcc = 0
        local now = GPS.Now()
        if not now then self:Hide(); SetTeleport(nil); return end
        local combat = InCombatLockdown()
        if combat ~= self.combat then
            self.combat = combat
            -- "hide in combat": transparent, and no longer catching clicks or drags (not a secure frame)
            local hidden = combat and Opt("hideCombat", false) and true or false
            self:SetAlpha(hidden and 0 or 1)
            self:EnableMouse(not hidden)
            if self.close then self.close:EnableMouse(not hidden) end
            textAcc = TEXT_EVERY            -- redraw now: amber, buttons off
        end
        if self.moving then PlaceTeleport() end
        if textAcc >= TEXT_EVERY then
            textAcc = 0
            SampleSpeed(now)
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

-- After combat: the cast button catches up with what the HUD shows now.
local ev = CreateFrame("Frame")
pcall(ev.RegisterEvent, ev, "PLAYER_REGEN_ENABLED")
ev:SetScript("OnEvent", function()
    if not teleport and arrow then BuildTeleport() end
    if not teleport then return end
    teleport.pending = nil
    teleport:SetAlpha(arrow and arrow:GetAlpha() or 1)
    PlaceTeleport()
    SetTeleport(WantedTeleport())
    if arrow then arrow.redraw = true end
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
    arrow.icon:SetAlpha(1)
    SetVisual(arrow, "arrow")
    arrow.tex:SetRotation(0.3)
    arrow.tex:SetVertexColor(C.ok[1], C.ok[2], C.ok[3])
    SetText(arrow.what, L("Place la flèche"))
    SetText(arrow.where, L("Glisse-la où tu veux."))
    SetText(arrow.dist, S.Hex(C.accentSoft) .. Distance(600) .. "|r" .. S.Hex(C.muted) .. "  \194\183  |r" .. Duration(70))
    SetText(arrow.route, L("Clique sur la croix pour la fixer ici."))
    arrow.fly:Hide()
    arrow.button = nil
    Layout(arrow)
    SetTeleport(nil)
    arrow:Show()
end

function GPS.Lock()
    demo = false
    if arrow then
        for _, fs in ipairs({ arrow.goal, arrow.what, arrow.where, arrow.dist, arrow.route }) do SetText(fs, "") end
        arrow.visual = nil
    end
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
