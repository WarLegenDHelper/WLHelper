-- Writs/Home.lua: WL Helper's home page and the minimap button's tooltip and menu.
-- One card per module with where you stand (dungeon route, writs, bag items), the GPS line, then
-- "An idea, a bug?" and the settings. Opened by /wlh and a click on the minimap button.
local ADDON, root = ...
root.Writs = root.Writs or {}
local ns = root.Writs
local WP = ns.WP
local L = ns.L
local S = ns.S
local C = S.C

ns.AddEnglish({
    ["%s · niv. %d"] = "%s · lvl %d",
    ["en cours"] = "in progress",
    ["Reprendre"] = "Resume",
    ["Choisir"] = "Pick",
    ["étape %d sur %d"] = "step %d of %d",
    ["Route depuis ta position"] = "Route from where you stand",
    ["%d writs prêts à rendre"] = "%d writs ready to hand in",
    ["%d enveloppes à ouvrir"] = "%d envelopes to open",
    ["Rien à rendre pour l'instant"] = "Nothing to hand in yet",
    ["Faction pas encore vue"] = "Faction not seen yet",
    ["Sacs"] = "Bags",
    ["Rien à jeter"] = "Nothing to throw away",
    ["vers %s"] = "to %s",
    ["Arrêter"] = "Stop",
    ["Réglages"] = "Settings",
    ["GPS"] = "GPS",
    ["Donjons"] = "Dungeons",
    ["Clic : accueil · Clic droit : menu"] = "Click: home · Right-click: menu",
    ["Glisser pour déplacer"] = "Drag to move",
    ["Arrêter le GPS"] = "Stop the GPS",
    ["%d / %d"] = "%d / %d",
    ["%d prêts"] = "%d ready",
    ["%d à jeter"] = "%d to throw away",
    ["aucun"] = "none",
    ["Maintenant : "] = "Now: ",
    ["%d commandes à accepter"] = "%d orders to accept",
    ["%d de tes commandes en cours"] = "%d of your orders running",
    ["terminé"] = "done",
    ["Route terminée"] = "Route finished",
    ["Aucun donjon choisi"] = "No dungeon picked",
    ["Craftsman's Writs"] = "Craftsman's Writs",
    ["Zone mise de côté : Réglages › Comptoir"] = "Zone set aside: Settings › Trading Post",
    ["lieu de remise sur la carte"] = "turn-in spot on the map",
    ["niv. %d+"] = "lvl %d+",
    ["mis de côté"] = "set aside",
    ["Clic droit : ne pas le faire"] = "Right-click: skip it",
    ["Clic droit : le remettre dans le plan"] = "Right-click: back in the plan",
    ["%d objets de quête à jeter"] = "%d quest items to drop",
    ["Commander à la guilde"] = "Order from the guild",
    ["%d améliorations en sac"] = "%d upgrades in your bags",
    ["Tu es %de cette semaine"] = "You are #%d this week",
    ["Réglages : spé et poids"] = "Settings: spec, weights",
})

local W, PAD, CARD_H, TILE_H = 440, 14, 72, 84

local function Guide() return root end
local function Version()
    local meta = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
    return meta and meta(ADDON, "Version") or "?"
end

-- ---------------------------------------------------------------- what each module has to say

local function DungeonState()
    if not root.GuideStatus then return nil end
    return root.GuideStatus()   -- three values: never through "a and f()", which keeps only one
end

local function WritState()
    local name = WP.Reputation()
    if not name then return nil end
    local need, goal = WP.RepNeeded()
    local ready, bag = 0, 0
    for _, r in ipairs(WP.Rows()) do
        if r.state == "ready" then ready = ready + 1 elseif r.state == "bag" then bag = bag + 1 end
    end
    return need, goal, ready, bag
end

local function BagCount()
    return WP.Cleaner and WP.Cleaner.Count and WP.Cleaner.Count() or 0
end

-- ---------------------------------------------------------------- the window

local win
local cards = {}

-- A module card: icon square, title, two lines, an optional bar, and a button or a chevron.
local function Card(parent, y, icon, tint, onClick, col)
    local c = CreateFrame("Button", nil, parent)
    c.tile = col ~= nil
    if col then
        local half = (W - 2 * PAD - 10) / 2
        c:SetSize(half, TILE_H)
        c:SetPoint("TOPLEFT", PAD + (col - 1) * (half + 10), y)
    else
        c:SetHeight(CARD_H)
        c:SetPoint("TOPLEFT", PAD, y); c:SetPoint("TOPRIGHT", -PAD, y)
    end
    S.Solid(c, "BACKGROUND", C.card):SetAllPoints()
    c.border = S.Border(c, C.border)
    c.edge = S.Solid(c, "ARTWORK", C.border)
    c.edge:SetPoint("TOPLEFT"); c.edge:SetPoint("BOTTOMLEFT"); c.edge:SetWidth(3)
    local hl = S.Solid(c, "HIGHLIGHT", { 1, 1, 1 }, 0.04); hl:SetAllPoints()

    local box = CreateFrame("Frame", nil, c)
    box:SetSize(42, 42); box:SetPoint("LEFT", 14, 0)
    S.Solid(box, "BACKGROUND", { tint[1] * 0.25, tint[2] * 0.25, tint[3] * 0.25 }):SetAllPoints()
    S.Border(box, { tint[1] * 0.55, tint[2] * 0.55, tint[3] * 0.55 })
    c.icon = box:CreateTexture(nil, "ARTWORK")
    c.icon:SetPoint("TOPLEFT", 3, -3); c.icon:SetPoint("BOTTOMRIGHT", -3, 3)
    c.icon:SetTexture(icon); c.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    if c.tile then box:SetSize(30, 30); box:ClearAllPoints(); box:SetPoint("TOPLEFT", 10, -10) end
    c.title = S.Text(c, c.tile and 15 or 17, C.text, true)
    c.title:SetPoint("TOPLEFT", box, "TOPRIGHT", 12, 1)
    c.tag = S.Text(c, c.tile and 11 or 13, C.dim)
    c.line1 = S.Text(c, c.tile and 12 or 14, { 0.79, 0.8, 0.82 })
    if c.tile then
        -- a tile: the title and its tag beside the icon, the two lines under it
        c.title:ClearAllPoints(); c.title:SetPoint("TOPLEFT", box, "TOPRIGHT", 8, 0); c.title:SetPoint("RIGHT", c, "RIGHT", -26, 0)
        c.title:SetJustifyH("LEFT"); c.title:SetWordWrap(false)
        c.tag:SetPoint("TOPLEFT", c.title, "BOTTOMLEFT", 0, -2); c.tag:SetPoint("RIGHT", c, "RIGHT", -8, 0); c.tag:SetJustifyH("LEFT"); c.tag:SetWordWrap(false)
        c.line1:SetPoint("TOPLEFT", box, "BOTTOMLEFT", 0, -8)
    else
        c.tag:SetPoint("BOTTOMLEFT", c.title, "BOTTOMRIGHT", 8, 1)
        c.line1:SetPoint("TOPLEFT", c.title, "BOTTOMLEFT", 0, -5)
    end
    c.line1:SetPoint("RIGHT", c, "RIGHT", -40, 0); c.line1:SetJustifyH("LEFT"); c.line1:SetWordWrap(false)
    c.line2 = S.Text(c, c.tile and 11 or 13, C.ready)
    c.line2:SetPoint("TOPLEFT", c.line1, "BOTTOMLEFT", 0, -4)
    c.line2:SetPoint("RIGHT", c, "RIGHT", -40, 0); c.line2:SetJustifyH("LEFT"); c.line2:SetWordWrap(false)
    c.bar = CreateFrame("Frame", nil, c)
    c.bar:SetHeight(4)
    if c.tile then
        c.bar:SetPoint("TOPLEFT", c.line2, "BOTTOMLEFT", 0, -6); c.bar:SetPoint("RIGHT", c, "RIGHT", -110, 0)
    end
    S.Solid(c.bar, "BACKGROUND", C.divider):SetAllPoints()
    c.fill = S.Solid(c.bar, "ARTWORK", C.brand)
    c.fill:SetPoint("TOPLEFT"); c.fill:SetPoint("BOTTOMLEFT")

    -- a switched-off module: the card turns it back on
    local function Click()
        if c.off then return end   -- a switched-off card: only its button acts
        onClick()
    end
    c.action = S.Button(c, "", 86, 30, "primary", function()
        if c.off then WP.SetModule(c.key, true) else onClick() end
    end)
    c.action:SetPoint("RIGHT", -12, 0)
    if not c.tile then
        -- the full card's bar sits under its button: under line2 it would fall below the card
        c.bar:SetPoint("TOPLEFT", c.action, "BOTTOMLEFT", 0, -6); c.bar:SetPoint("TOPRIGHT", c.action, "BOTTOMRIGHT", 0, -6)
    end
    c.chev = S.Text(c, 18, C.muted, true)
    c.chev:SetPoint("RIGHT", -14, 0); c.chev:SetText(">")
    if c.tile then
        c.action:SetSize(70, 22); c.action:ClearAllPoints(); c.action:SetPoint("BOTTOMRIGHT", -8, 8)
        c.chev:ClearAllPoints(); c.chev:SetPoint("TOPRIGHT", -10, -14)
    end
    c:SetScript("OnClick", Click)
    -- a switched-off card: its line is cut short, the whole module hint shows on hover
    c:SetScript("OnEnter", function(self)
        if self.off and self.hintFull and self.hintFull ~= "" then S.Tip(self, { self.title:GetText() or "", self.hintFull }) end
    end)
    c:SetScript("OnLeave", S.HideTip)
    -- with a button on the right, the text stops before it
    function c:Narrow(on)
        if self.tile then
            -- a tile: the "on" button sits at the bottom right; the title keeps its width and
            -- line1 stops before the button
            self.title:SetPoint("RIGHT", self, "RIGHT", -26, 0)
            self.line1:SetPoint("RIGHT", self, "RIGHT", on and -84 or -8, 0); self.line2:SetPoint("RIGHT", self, "RIGHT", -8, 0)
            return
        end
        local r = on and -110 or -40
        self.line1:SetPoint("RIGHT", self, "RIGHT", r, 0)
        self.line2:SetPoint("RIGHT", self, "RIGHT", r, 0)
    end
    return c
end

-- Every card looks the same; what needs you is said by its button, not by a coloured edge.
local function SetActive(c, on)
    c.edge:SetColorTexture(C.border[1], C.border[2], C.border[3], 0)
end

local function Close() if win then win:Hide() end end

local function Build()
    win = S.Window("WLHelperHome", W, 10, "WaR |cffce1918LegenD|r Helper", nil, WLWritsDB, "homePos")

    local y = -38 - PAD
    cards.dungeons = Card(win, y, "Interface\\Icons\\INV_Misc_Map_01", C.brandHi or C.brand, function()
        Close()
        if DungeonState() then root.ShowGuide() else root.ShowPicker() end
    end)
    y = y - CARD_H - 10
    cards.writs = Card(win, y, "Interface\\Icons\\INV_Letter_15", C.warn, function() Close(); WP.Open() end, 1)
    cards.bags = Card(win, y, "Interface\\Icons\\INV_Misc_Bag_08", C.info, function()
        Close(); if WP.Cleaner then WP.Cleaner.Toggle() end
    end, 2)
    y = y - TILE_H - 10
    cards.orders = Card(win, y, "Interface\\Icons\\INV_Misc_Note_01", C.ready, function()
        Close(); if WP.ToggleOrders then WP.ToggleOrders() end
    end, 1)
    cards.guild = Card(win, y, "Interface\\Icons\\INV_BannerPVP_01", C.brandSoft or C.info, function()
        Close(); if WP.ToggleGuild then WP.ToggleGuild() end
    end, 2)
    y = y - TILE_H - 10
    cards.events = Card(win, y, "Interface\\Icons\\Ability_Warrior_BattleShout", C.warn, function()
        Close(); if WP.ToggleEvents then WP.ToggleEvents() end
    end, 1)
    cards.upgrades = Card(win, y, "Interface\\Icons\\INV_Chest_Cloth_17", C.ready, function()
        Close(); if WP.ShowOptionsPage then WP.ShowOptionsPage("upgrades") end
    end, 2)
    y = y - TILE_H - 10

    win.afterCards = y

    -- an update seen on another player's copy (Version.lua)
    local upd = CreateFrame("Frame", nil, win)
    upd:SetHeight(34)
    S.Solid(upd, "BACKGROUND", C.brandBg or C.card):SetAllPoints()
    S.Border(upd, C.brand)
    upd.text = S.Text(upd, 13, C.text)
    upd.text:SetPoint("LEFT", 12, 0); upd.text:SetPoint("RIGHT", -12, 0); upd.text:SetJustifyH("LEFT"); upd.text:SetWordWrap(false)
    win.upd = upd

    -- the GPS line, only while it guides
    local gps = CreateFrame("Frame", nil, win)
    gps:SetHeight(40)
    S.Border(gps, C.divider)
    gps.text = S.Text(gps, 14, C.dim)
    gps.text:SetPoint("LEFT", 12, 0); gps.text:SetPoint("RIGHT", -84, 0); gps.text:SetJustifyH("LEFT"); gps.text:SetWordWrap(false)
    gps.stop = S.Button(gps, L("Arrêter"), 70, 26, "secondary", function()
        WP.StopGPS()
    end)
    gps.stop:SetPoint("RIGHT", -7, 0)
    win.gps = gps

    -- footer: an idea, the settings, the version (placed by Layout under what is shown)
    local half = (W - 2 * PAD - 8) / 2
    win.idea = S.Button(win, L("Une idée, un bug ?"), half, 34, "secondary", function()
        Close(); if WP.Feedback then WP.Feedback("idea") end
    end)
    win.set = S.Button(win, L("Réglages"), half, 34, "secondary", function()
        Close(); if WP.ShowOptionsPage then WP.ShowOptionsPage() end
    end)
    win.ver = S.Text(win, 12, C.muted)
    win.ver:SetText("v" .. Version() .. " · /wlh")

    -- stacks the optional lines under the cards, then the footer, and sizes the window
    function win.Layout(showUpdate, showGps)
        local yy = win.afterCards
        local function place(f, h, gap)
            f:ClearAllPoints(); f:SetPoint("TOPLEFT", PAD, yy); f:SetPoint("TOPRIGHT", -PAD, yy); f:Show()
            yy = yy - h - gap
        end
        if showUpdate then place(upd, 34, 10) else upd:Hide() end
        if showGps then place(gps, 40, 14) else gps:Hide() end
        win.idea:ClearAllPoints(); win.idea:SetPoint("TOPLEFT", PAD, yy)
        win.set:ClearAllPoints(); win.set:SetPoint("TOPRIGHT", -PAD, yy)
        yy = yy - 34 - 8
        win.ver:ClearAllPoints(); win.ver:SetPoint("TOP", 0, yy)
        win:SetHeight(-yy + 12 + 14)
    end
    win.Layout(false, false)

    cards.dungeons.key, cards.writs.key, cards.bags.key, cards.orders.key, cards.guild.key = "dungeons", "writs", "bags", "orders", "guild"
    cards.events.key, cards.upgrades.key = "events", "upgrades"
    win:SetScript("OnShow", function() WP.RefreshHome() end)
    local ev = CreateFrame("Frame", nil, win)
    pcall(ev.RegisterEvent, ev, "QUEST_LOG_UPDATE"); pcall(ev.RegisterEvent, ev, "BAG_UPDATE_DELAYED"); pcall(ev.RegisterEvent, ev, "UPDATE_FACTION")
    local queued = false
    ev:SetScript("OnEvent", function()
        if not win:IsShown() or queued then return end
        queued = true
        C_Timer.After(0.5, function() queued = false; WP.RefreshHome() end)
    end)
end

function WP.RefreshHome()
    if not (win and win:IsShown()) then return end
    local level = UnitLevel("player")
    win.subtitle:SetText(string.format(L("%s · niv. %d"), UnitName("player") or "", level or 0))

    -- dungeons
    local d = cards.dungeons
    d.title:SetText(L("Quêtes de donjon"))
    local label, cur, total, finished, nextStep = DungeonState()
    d.line2:SetTextColor(C.dim[1], C.dim[2], C.dim[3])
    if label and not finished then
        -- where: the route and the step; then what to do next
        d.tag:SetText(string.format(L("étape %d sur %d"), cur, total))
        d.line1:SetText(label)
        d.line2:SetText(nextStep and nextStep ~= "" and (L("Maintenant : ") .. nextStep) or "")
        d.bar:Show(); d.fill:SetWidth(math.max(0.01, (d.bar:GetWidth() > 0 and d.bar:GetWidth() or 200) * (cur - 1) / math.max(1, total)))
        d.action.label:SetText(L("Reprendre"))
        SetActive(d, true)
    elseif label then
        d.tag:SetText(L("terminé"))
        d.line1:SetText(label); d.line2:SetText(L("Route terminée"))
        d.bar:Hide()
        d.action.label:SetText(L("Choisir"))
        SetActive(d, false)
    else
        d.tag:SetText("")
        d.line1:SetText(L("Aucun donjon choisi"))
        d.line2:SetText(L("Route depuis ta position"))
        d.bar:Hide()
        d.action.label:SetText(L("Choisir"))
        SetActive(d, false)
    end
    d.action:Show(); d.chev:Hide(); d:Narrow(true)

    -- Trading Post
    local c = cards.writs
    c.title:SetText(L("Writs & Favor")); c.tag:SetText(L("Craftsman's Writs")); c.bar:Hide(); c.action:Hide(); c.chev:Show(); c:Narrow(false)
    local need, goal, ready, bag = WritState()
    if need then
        local favor = WP.FavorNow and WP.FavorNow()
        c.line1:SetText((need > 0 and string.format(L("%s dans %d rép"), WP.Reaction(goal), need) or string.format(L("%s atteint"), WP.Reaction(goal)))
            .. (favor and ("  ·  " .. string.format(L("%d Favor"), favor)) or ""))
        local parts = {}
        if ready > 0 then parts[#parts + 1] = string.format(L("%d writs prêts à rendre"), ready) end
        if bag > 0 then parts[#parts + 1] = string.format(L("%d enveloppes à ouvrir"), bag) end
        c.line2:SetText(#parts > 0 and table.concat(parts, " · ") or L("Rien à rendre pour l'instant"))
        c.line2:SetTextColor((#parts > 0 and C.ready or C.dim)[1], (#parts > 0 and C.ready or C.dim)[2], (#parts > 0 and C.ready or C.dim)[3])
        SetActive(c, ready > 0)
    else
        c.line1:SetText(L("Faction pas encore vue")); c.line2:SetText(""); SetActive(c, false)
    end

    -- bags
    local b = cards.bags
    b.title:SetText(L("Sacs")); b.tag:SetText(""); b.bar:Hide(); b.action:Hide(); b.chev:Show(); b.line2:SetText(""); b:Narrow(false)
    local n = BagCount()
    b.line1:SetText(n > 0 and string.format(L("%d objets de quête à jeter"), n) or L("Rien à jeter"))
    SetActive(b, false)

    -- orders: what waits for you
    local oc = cards.orders
    oc.title:SetText(L("Commandes")); oc.tag:SetText(""); oc.bar:Hide(); oc.action:Hide(); oc.chev:Show(); oc:Narrow(false)
    if WP.Orders then
        local mine, forMe = WP.Orders.Lists()
        local open, running = 0, 0
        for _, o in ipairs(forMe) do if o.status == "open" then open = open + 1 end end
        for _, o in ipairs(mine) do if o.status == "open" or o.status == "accepted" or o.status == "crafted" then running = running + 1 end end
        oc.line1:SetText(open > 0 and string.format(L("%d commandes à accepter"), open) or L("Commander à la guilde"))
        oc.line2:SetText(running > 0 and string.format(L("%d de tes commandes en cours"), running) or "")
        oc.line2:SetTextColor(C.dim[1], C.dim[2], C.dim[3])
    end

    -- guild: who is on, and where you stand in this week's PvP ranking
    local gc = cards.guild
    gc.title:SetText(L("Guilde")); gc.tag:SetText(""); gc.bar:Hide(); gc.action:Hide(); gc.chev:Show(); gc:Narrow(false)
    if IsInGuild and IsInGuild() and WP.GuildRoster then
        local _, online = WP.GuildRoster(true)
        gc.tag:SetText(GetGuildInfo and GetGuildInfo("player") or "")
        gc.line1:SetText(string.format(L("%d en ligne"), online))
        local pos
        for i, e in ipairs(WP.GuildRanking and WP.GuildRanking(true) or {}) do if e.name == UnitName("player") then pos = i end end
        gc.line2:SetText(pos and string.format(L("Tu es %de cette semaine"), pos) or L("Classement PvP"))
    else
        gc.line1:SetText(L("Pas de guilde.")); gc.line2:SetText("")
    end
    gc.line2:SetTextColor(C.dim[1], C.dim[2], C.dim[3])

    -- events: the next one, and who looks for a group now
    local ec = cards.events
    ec.title:SetText("LFG"); ec.tag:SetText(""); ec.bar:Hide(); ec.action:Hide(); ec.chev:Show(); ec:Narrow(false)
    if WP.EventList then
        local list = WP.EventList()
        local nextE
        for _, e in ipairs(list) do if e.status == "open" and e.when >= time() - 1800 then nextE = e; break end end
        ec.tag:SetText(#list > 0 and string.format(L("%d événements à venir"), #list) or "")
        ec.line1:SetText(nextE and string.format(L("Prochain : %s, %s"), nextE.title, WP.EventWhen(nextE.when)) or L("Rien de prévu"))
        local n = #WP.LFGList()
        ec.line2:SetText(n > 0 and string.format(L("%d cherchent un groupe"), n) or "")
    end
    ec.line2:SetTextColor(C.ready[1], C.ready[2], C.ready[3])

    -- upgrades: the spec judged, and how many bag items are better than what you wear
    local uc = cards.upgrades
    uc.title:SetText(L("Améliorations")); uc.tag:SetText(""); uc.bar:Hide(); uc.action:Hide(); uc.chev:Show(); uc:Narrow(false)
    local Wt = WP.Weights
    if Wt then
        local _, bracket = Wt.Bracket()
        uc.tag:SetText(Wt.SpecName() .. " · " .. string.format(L("niv. %s"), bracket))
        local n = 0
        local GetLink = C_Container and C_Container.GetContainerItemLink
        if GetLink and WP.UpgradeCheck then
            for bag = 0, NUM_BAG_SLOTS or 4 do
                for slot = 1, (C_Container.GetContainerNumSlots(bag) or 0) do
                    local link = GetLink(bag, slot)
                    if link and WP.UpgradeCheck(link).up then n = n + 1 end
                end
            end
        end
        uc.line1:SetText(n > 0 and string.format(L("%d améliorations en sac"), n) or L("Rien de mieux dans tes sacs"))
        uc.line2:SetText(L("Réglages : spé et poids"))
        uc.line2:SetTextColor(C.dim[1], C.dim[2], C.dim[3])
    end

    -- switched-off modules: dimmed, "off", one button to turn them back on
    local hints = {}
    for _, m in ipairs(WP.MODULES) do hints[m.key] = m.hint end
    for key, card in pairs(cards) do
        card.off = not WP.ModuleOn(key)
        -- dim the card's content, never its button
        local a = card.off and 0.45 or 1
        card.icon:SetAlpha(a); card.title:SetAlpha(a); card.tag:SetAlpha(a); card.line1:SetAlpha(a); card.line2:SetAlpha(a)
        if card.off then
            card.hintFull = L(hints[key] or "")
            card.tag:SetText(L("éteint")); card.line1:SetText(card.hintFull)
            card.line2:SetText(""); card.bar:Hide(); card.chev:Hide()
            card.action.label:SetText(L("Allumer")); card.action:Show(); card:Narrow(true)
            SetActive(card, false)
        end
    end

    -- GPS (only while it guides) and an update seen on another player's copy
    local g = win.gps
    local guiding = WP.GPS.Active()
    if guiding then
        g.text:SetText(S.Hex(C.text) .. L("GPS") .. "|r · " .. string.format(L("vers %s"), WP.GPS.DestName() or "?"))
    end
    local newer = WP.UpdateAvailable and WP.UpdateAvailable()
    if newer then win.upd.text:SetText(string.format(L("Mise à jour disponible : %s · WowUp › Update"), newer)) end
    win.Layout(newer ~= nil, guiding)
end

function WP.OpenHome()
    if not win then Build() end
    win:Show(); WP.RefreshHome()
end

function WP.ToggleHome()
    if not win then Build() end
    if win:IsShown() then win:Hide() else WP.OpenHome() end
end

-- ---------------------------------------------------------------- minimap button

-- Tooltip: where you stand first, then the two clicks.
function WP.MinimapTooltip(owner)
    local tt = GameTooltip
    tt:SetOwner(owner, "ANCHOR_LEFT")
    tt:AddLine("WaR |cffce1918LegenD|r Helper", 1, 1, 1)
    local label, cur, total, finished = DungeonState()
    tt:AddDoubleLine(L("Quêtes de donjon"), not WP.ModuleOn("dungeons") and L("éteint") or label and (label .. ", " .. (finished and L("terminé") or string.format(L("%d / %d"), cur, total))) or L("aucun"),
        C.dim[1], C.dim[2], C.dim[3], C.text[1], C.text[2], C.text[3])
    local need, _, ready = WritState()
    if not WP.ModuleOn("writs") then
        tt:AddDoubleLine(L("Writs & Favor"), L("éteint"), C.dim[1], C.dim[2], C.dim[3], C.dim[1], C.dim[2], C.dim[3])
    elseif need then
        local col = ready > 0 and C.ready or C.text
        tt:AddDoubleLine(L("Writs & Favor"), string.format(L("%d prêts"), ready), C.dim[1], C.dim[2], C.dim[3], col[1], col[2], col[3])
    end
    tt:AddDoubleLine(L("Sacs"), WP.ModuleOn("bags") and string.format(L("%d à jeter"), BagCount()) or L("éteint"),
        C.dim[1], C.dim[2], C.dim[3], C.text[1], C.text[2], C.text[3])
    local newer = WP.UpdateAvailable and WP.UpdateAvailable()
    if newer then
        tt:AddLine(" ")
        tt:AddLine(string.format(L("Mise à jour disponible : %s · WowUp › Update"), newer), C.brandSoft[1], C.brandSoft[2], C.brandSoft[3])
    end
    tt:AddLine(" ")
    tt:AddLine(L("Clic : accueil · Clic droit : menu"), C.warn[1], C.warn[2], C.warn[3])
    tt:AddLine(L("Glisser pour déplacer"), C.dim[1], C.dim[2], C.dim[3])
    tt:Show()
end

-- Right-click menu: straight to a module.
local menu
function WP.MinimapMenu(owner)
    if not menu then
        menu = CreateFrame("Frame", "WLHelperMinimapMenu", UIParent)
        -- above minimap button bars and every window
        menu:SetFrameStrata("TOOLTIP"); menu:SetFrameLevel(50); menu:SetClampedToScreen(true); menu:EnableMouse(true)
        S.Solid(menu, "BACKGROUND", C.card):SetAllPoints()
        S.Border(menu, C.border)
        tinsert(UISpecialFrames, "WLHelperMinimapMenu")
        local items = {
            { L("Quêtes de donjon"), function() if DungeonState() then root.ShowGuide() else root.ShowPicker() end end, "dungeons" },
            { L("Writs & Favor"), function() WP.Open() end, "writs" },
            { L("Sacs"), function() if WP.Cleaner then WP.Cleaner.Toggle() end end, "bags" },
            { L("Commandes"), function() if WP.ToggleOrders then WP.ToggleOrders() end end, "orders" },
            { L("Guilde"), function() if WP.ToggleGuild then WP.ToggleGuild() end end, "guild" },
            { "LFG", function() if WP.ToggleEvents then WP.ToggleEvents() end end, "events" },
            { L("Améliorations"), function() if WP.ShowOptionsPage then WP.ShowOptionsPage("upgrades") end end, "upgrades" },
            false,
            { L("Arrêter le GPS"), function() WP.StopGPS() end, "gps" },
            { L("Réglages"), function() if WP.ShowOptionsPage then WP.ShowOptionsPage() end end },
        }
        local y = -4
        menu.buttons = {}
        for _, it in ipairs(items) do
            if it then
                local b = S.Button(menu, it[1], 184, 26, "ghost", function() menu:Hide(); it[2]() end)
                b.label:ClearAllPoints(); b.label:SetPoint("LEFT", 10, 0)
                b:SetPoint("TOPLEFT", 4, y)
                if it[3] then menu.buttons[it[3]] = b end
                y = y - 26
            else
                local line = S.Solid(menu, "BORDER", C.divider)
                line:SetPoint("TOPLEFT", 4, y - 4); line:SetPoint("TOPRIGHT", -4, y - 4); line:SetHeight(1)
                y = y - 9
            end
        end
        menu:SetSize(192, -y + 4)
        -- closes when the mouse has left it for a moment
        menu:SetScript("OnUpdate", function(self, dt)
            if self:IsMouseOver() or (self.owner and self.owner:IsMouseOver()) then self.away = 0; return end
            self.away = (self.away or 0) + dt
            if self.away > 1.5 then self:Hide() end
        end)
    end
    if menu:IsShown() then menu:Hide(); return end
    menu.owner = owner; menu.away = 0
    menu.buttons.gps:SetEnabled(WP.GPS.Active())
    for _, m in ipairs(WP.MODULES) do
        local b = menu.buttons[m.key]
        if b then b.label:SetAlpha(WP.ModuleOn(m.key) and 1 or 0.45) end
    end
    menu:ClearAllPoints()
    menu:SetPoint("TOPRIGHT", owner, "BOTTOMLEFT", 4, 4)
    GameTooltip:Hide()
    menu:Show()
end
