-- Writs/Home.lua: WL Helper's home page and the minimap button's tooltip and menu.
-- "Now": the one thing worth doing right now and its button (hidden when nothing waits), a line
-- when a newer version exists, the quest guide card, then one tile per module with where you stand.
-- Settings in the header (gear), "Nous écrire" and the version in the footer. The window fits its
-- content; past 80 % of the screen the cards scroll. Opened by /wlh and a click on the minimap button.
local ADDON, root = ...
root.Writs = root.Writs or {}
local ns = root.Writs
local WP = ns.WP
local L = ns.L
local S = ns.S
local C = S.C
local F = S.F

ns.AddEnglish({
    ["%s, niveau %d"] = "%s, level %d",
    ["Réglages"] = "Settings",
    ["Clic : ouvrir les réglages"] = "Click: open settings",
    ["Une idée, un bug ?"] = "An idea, a bug?",
    ["Clic : ouvrir le formulaire pour nous écrire"] = "Click: open the form to write to us",
    -- "now"
    ["Le GPS te guide vers %s."] = "The GPS is guiding you to %s.",
    ["Arrêter le GPS"] = "Stop the GPS",
    ["1 commande attend ta réponse."] = "1 order is waiting for your answer.",
    ["%d commandes attendent ta réponse."] = "%d orders are waiting for your answer.",
    ["Voir les commandes"] = "See orders",
    ["1 Writ est prêt à rendre."] = "1 Writ is ready to turn in.",
    ["%d Writs sont prêts à rendre."] = "%d Writs are ready to turn in.",
    ["1 enveloppe à ouvrir dans tes sacs."] = "1 envelope to open in your bags.",
    ["%d enveloppes à ouvrir dans tes sacs."] = "%d envelopes to open in your bags.",
    ["Voir les Writs"] = "See Writs",
    ["%s commence dans %d min."] = "%s starts in %d min.",
    ["%s a commencé."] = "%s has started.",
    ["Voir l'événement"] = "See the event",
    ["Prochaine étape : %s"] = "Next step: %s",
    ["Reprendre le guide"] = "Resume guide",
    ["1 objet de quête ne sert plus."] = "1 quest item is no longer needed.",
    ["%d objets de quête ne servent plus."] = "%d quest items are no longer needed.",
    ["Nettoyer les sacs"] = "Clean bags",
    -- the cards
    ["Guide de quêtes"] = "Quest guide",
    ["Étape %d sur %d"] = "Step %d of %d",
    ["Choisis tes prochains donjons."] = "Pick your next dungeons.",
    ["Aucun donjon choisi"] = "No dungeon picked",
    ["Donjons, raids et quêtes de classe, depuis là où tu es."] = "Dungeons, raids and class quests, from where you are.",
    ["Terminée"] = "Finished",
    ["Clic : ouvrir le guide"] = "Click: open the guide",
    ["Clic : choisir les donjons"] = "Click: pick dungeons",
    ["Writs"] = "Writs",
    ["%s dans %d points"] = "%s in %d points",
    ["%s atteint"] = "%s reached",
    ["Faction pas encore vue"] = "Faction not seen yet",
    ["Parle à un PNJ de cette faction pour qu'elle apparaisse."] = "Talk to one of the faction's NPCs to unlock it.",
    ["1 Writ prêt à rendre"] = "1 Writ ready to turn in",
    ["%d Writs prêts à rendre"] = "%d Writs ready to turn in",
    ["1 enveloppe à ouvrir"] = "1 envelope to open",
    ["%d enveloppes à ouvrir"] = "%d envelopes to open",
    ["Rien à rendre pour l'instant"] = "Nothing to turn in yet",
    ["Clic : ouvrir les Writs"] = "Click: open the Writs window",
    ["Faveur du marchand"] = "Merchant's Favor",
    ["1 point de Faveur"] = "1 Favor",
    ["%d points de Faveur"] = "%d Favor",
    ["Pas encore de Faveur"] = "No Favor yet",
    ["Les caisses les moins chères et où les rendre"] = "The cheapest crates and where to turn them in",
    ["Clic : voir les caisses"] = "Click: see the crates",
    ["Sacs"] = "Bags",
    ["1 objet de quête à jeter"] = "1 quest item to throw away",
    ["%d objets de quête à jeter"] = "%d quest items to throw away",
    ["Rien à jeter"] = "Nothing to throw away",
    ["Les objets de quête qui ne servent plus"] = "Quest items you no longer need",
    ["Clic : voir les objets à jeter"] = "Click: see the items to throw away",
    ["Commandes"] = "Orders",
    ["1 commande à accepter"] = "1 order to accept",
    ["%d commandes à accepter"] = "%d orders to accept",
    ["Faire fabriquer par la guilde"] = "Get things crafted by the guild",
    ["Tu as 1 commande en cours"] = "You have 1 order in progress",
    ["Tu as %d commandes en cours"] = "You have %d orders in progress",
    ["Clic : ouvrir les commandes"] = "Click: open orders",
    ["Guilde"] = "Guild",
    ["1 membre en ligne"] = "1 member online",
    ["%d membres en ligne"] = "%d members online",
    ["Tu es 1er au classement PvP de la semaine"] = "You are #1 in this week's PvP ranking",
    ["Tu es %de au classement PvP de la semaine"] = "You are #%d in this week's PvP ranking",
    ["Classement PvP de la semaine"] = "This week's PvP ranking",
    ["Tu n'es pas dans une guilde"] = "You are not in a guild",
    ["Clic : ouvrir la guilde"] = "Click: open the guild",
    ["LFG"] = "LFG",
    ["Aucun événement prévu"] = "No events planned",
    ["1 joueur cherche un groupe"] = "1 player looking for a group",
    ["%d joueurs cherchent un groupe"] = "%d players looking for a group",
    ["1 événement à venir"] = "1 upcoming event",
    ["%d événements à venir"] = "%d upcoming events",
    ["Clic : ouvrir le LFG"] = "Click: open events",
    ["Améliorations"] = "Upgrades",
    ["1 amélioration dans tes sacs"] = "1 upgrade in your bags",
    ["%d améliorations dans tes sacs"] = "%d upgrades in your bags",
    ["Rien de mieux dans tes sacs"] = "Nothing better in your bags",
    ["Selon ta spé %s"] = "Based on your %s spec",
    ["Clic : choisir ta spé et voir tes améliorations"] = "Click: pick your spec and see your upgrades",
    ["Comment faire... ?"] = "How do I...?",
    ["Les gestes utiles, pas à pas"] = "Common tasks, step by step",
    ["Questions fréquentes et commandes"] = "Common questions and commands",
    ["Clic : ouvrir Comment faire... ?"] = "Click: open How do I...?",
    ["Module éteint"] = "Module off",
    ["Clic : allumer le module"] = "Click: turn the module on",
    -- what each module does (home tiles when off, welcome window)
    ["Les quêtes de tes donjons dans le bon ordre, avec le GPS."] = "Your dungeon quests in the right order, with the GPS.",
    ["Les Writs les moins chers, la liste d'achat, la tournée de remise et la Faveur du marchand."] = "The cheapest Writs, the shopping list, the turn-in tour and Merchant's Favor.",
    ["Les objets de quête qui ne servent plus, et une place libre en un clic."] = "Quest items you no longer need, and a free slot in one click.",
    ["Faire fabriquer par la guilde, ou fabriquer pour elle."] = "Get things crafted by the guild, or craft for it.",
    ["Les membres, leurs métiers et le classement PvP."] = "Members, their professions and the PvP ranking.",
    ["Les donjons et raids prévus par la guilde, et qui cherche un groupe."] = "Dungeons and raids the guild plans, and who is looking for a group.",
    ["Une flèche verte sur les objets meilleurs que les tiens."] = "A green arrow on items better than yours.",
    -- minimap button
    ["Éteint"] = "Off",
    ["Aucune route"] = "No route",
    ["%s, étape %d sur %d"] = "%s, step %d of %d",
    ["%s, terminée"] = "%s, finished",
    ["1 Writ prêt"] = "1 Writ ready",
    ["%d Writs prêts"] = "%d Writs ready",
    ["%d à jeter"] = "%d to throw away",
    ["%d à accepter"] = "%d to accept",
    ["1 cherche un groupe"] = "1 looking for a group",
    ["%d cherchent un groupe"] = "%d looking for a group",
    ["Clic : ouvrir l'Accueil"] = "Click: open Home",
    ["Clic droit : ouvrir un module"] = "Right-click: open a module",
    ["Glisser : déplacer le bouton"] = "Drag: move the button",
    ["Aucun trajet GPS en cours."] = "No GPS route running.",
    ["Nous écrire"] = "Write to us",
    ["Clic : ouvrir le guide de quêtes"] = "Click: open the quest guide",
    ["Clic : arrêter le GPS"] = "Click: stop the GPS",
})

local W = 520
local CW = W - 32          -- content width
local GAP = 12             -- between cards
local TILE_W = (CW - GAP) / 2

local function Version()
    local meta = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
    return meta and meta(ADDON, "Version") or "?"
end
-- "1 objet" / "3 objets": the singular key when n == 1
local function N(n, one, many) return n == 1 and L(one) or string.format(L(many), n) end

-- Each module's name and what it does, in the words of the glossary (home tiles, welcome window).
local MODULE_COPY = {
    dungeons = { "Guide de quêtes", "Les quêtes de tes donjons dans le bon ordre, avec le GPS." },
    writs    = { "Writs", "Les Writs les moins chers, la liste d'achat, la tournée de remise et la Faveur du marchand." },
    bags     = { "Sacs", "Les objets de quête qui ne servent plus, et une place libre en un clic." },
    orders   = { "Commandes", "Faire fabriquer par la guilde, ou fabriquer pour elle." },
    guild    = { "Guilde", "Les membres, leurs métiers et le classement PvP." },
    events   = { "Événements", "Les donjons et raids prévus par la guilde, et qui cherche un groupe." },
    upgrades = { "Améliorations", "Une flèche verte sur les objets meilleurs que les tiens." },
}
-- WP.ModuleCopy(key) -> name, description (translated); unknown keys fall back to WP.MODULES.
function WP.ModuleCopy(key)
    local c = MODULE_COPY[key]
    if c then return L(c[1]), L(c[2]) end
    for _, m in ipairs(WP.MODULES or {}) do if m.key == key then return L(m.label), L(m.hint or "") end end
    return key, ""
end

-- ---------------------------------------------------------------- what each module has to say

local function DungeonState()
    if not root.GuideStatus then return nil end
    return root.GuideStatus()   -- five values: never through "a and f()", which keeps only one
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

-- orders placed for you that nobody has accepted yet
local function OrdersOpen()
    if not WP.Orders then return 0 end
    local _, forMe = WP.Orders.Lists()
    local open = 0
    for _, o in ipairs(forMe or {}) do if o.status == "open" then open = open + 1 end end
    return open
end

local function OpenGuide()
    if DungeonState() then root.ShowGuide() else root.ShowPicker() end
end

-- ---------------------------------------------------------------- the window

local win
local cards = {}
local ORDER = { "writs", "favor", "bags", "orders", "guild", "events", "upgrades", "help" }

local function Close() if win then win:Hide() end end

-- A home card: the design system's card (icon, title, state line, next-step line, chevron), a
-- counter on the icon's corner, and the switched-off look (a click turns the module back on).
local function Card(key, icon, onClick)
    local c
    c = S.Card(win.inner, { icon = icon, title = "", line1 = "", line2 = "", onClick = function()
        if c.off then
            WP.SetModule(c.module or key, true)
            WP.RefreshHome()
            return
        end
        Close(); onClick()
    end })
    c.key, c.module = key, key
    c.counter = S.Counter(c)
    c.counter:SetPoint("CENTER", c.iconFrame, "TOPRIGHT", -2, -2)
    pcall(c.counter.SetFrameLevel, c.counter, (c.iconFrame:GetFrameLevel() or 1) + 3)
    c.tip = function()
        local lines = { c.title:GetText() or "" }
        for _, fs in ipairs({ c.line1, c.line2 }) do
            local t = fs:IsShown() and fs:GetText()
            if t and t ~= "" then lines[#lines + 1] = t end
        end
        if c.off and c.offDesc and c.offDesc ~= "" then lines[#lines + 1] = c.offDesc end
        if c.clickHint then lines[#lines + 1] = c.clickHint end
        return lines
    end
    -- o: title, line1, line2, lineColor (line1's colour), pill, pillColor, count, urgent, hint
    function c:Show2(o)
        self.off = false
        self:SetContent({ icon = icon, title = o.title, line1 = o.line1, line2 = o.line2, pill = o.pill, pillColor = o.pillColor })
        local lc = o.lineColor or C.text
        self.line1:SetTextColor(lc[1], lc[2], lc[3])
        self.clickHint = o.hint
        self.iconFrame:SetAlpha(1); self.title:SetAlpha(1); self.line1:SetAlpha(1); self.line2:SetAlpha(1)
        root.SetHDIcon(self.chev, "chevron_right", C.muted)
        self.counter:SetCount(o.count or 0, o.urgent)
    end
    -- a switched-off module: dimmed, "Module éteint", a plus where the chevron was
    function c:ShowOff(title)
        local _, desc = WP.ModuleCopy(self.module)
        self.off = true
        -- what the module does goes in the tooltip: a tile is too narrow for it
        self:SetContent({ icon = icon, title = title, line1 = L("Module éteint") })
        self.line1:SetTextColor(C.muted[1], C.muted[2], C.muted[3])
        self.offDesc = desc
        self.clickHint = L("Clic : allumer le module")
        self.iconFrame:SetAlpha(0.45); self.title:SetAlpha(0.6); self.line1:SetAlpha(1)
        root.SetHDIcon(self.chev, "plus", C.muted)
        self.counter:SetCount(0)
    end
    return c
end

-- "Now": a painted (or HD) icon, one sentence that may wrap, and the view's one primary button.
local function BuildNow()
    local t = CreateFrame("Frame", nil, win.inner)
    t.wlOwned = true
    S.Solid(t, "BACKGROUND", C.cardFill):SetAllPoints()
    S.Border(t, C.cardEdge)
    t.iconFrame = CreateFrame("Frame", nil, t)
    t.iconFrame:SetSize(28, 28); t.iconFrame:SetPoint("LEFT", 12, 0)
    t.icon = t.iconFrame:CreateTexture(nil, "ARTWORK"); t.icon:SetAllPoints()
    t.edge = S.Border(t.iconFrame, C.cardEdge)
    t.text = S.Text(t, F.body, C.fg)
    t.text:SetJustifyH("LEFT"); t.text:SetJustifyV("MIDDLE")
    t.text:SetPoint("LEFT", t.iconFrame, "RIGHT", 8, 0)
    t.go = S.Button(t, "", 0, 28, "primary", function() if t.fn then t.fn() end end)
    t.go:SetPoint("RIGHT", -12, 0)
    -- icon: a painted path, or { hd = name or path }
    function t:Set(icon, text, label, fn, kind)
        if type(icon) == "table" then
            root.SetHDIcon(self.icon, icon.hd, C.fg); self.edge(C.cardEdge, 0)
        else
            S.Painted(self.icon, icon); self.icon:SetVertexColor(1, 1, 1); self.edge(C.cardEdge)
        end
        self.text:SetText(text)
        self.go:SetText(label)
        self.go:SetKind(kind or "primary")
        self.fn = fn
    end
    function t:Fit(width)
        local okW, bw = pcall(self.go.GetWidth, self.go)
        bw = (okW and type(bw) == "number") and bw or 100
        local th = S.FitText(self.text, 2, math.max(80, width - 12 - 28 - 8 - 12 - bw - 12), self)
        local h = math.ceil(math.max(28, th) + 24)
        self:SetHeight(h)
        return h
    end
    return t
end

-- Stacks what is shown and sizes the window to it.
local function Layout()
    if not win then return end
    local inner = win.inner
    local y = 0
    local function Place(f, h, x, w)
        f:ClearAllPoints()
        f:SetPoint("TOPLEFT", inner, "TOPLEFT", 16 + (x or 0), -(12 + y))
        f:SetWidth(w or CW)
        f:SetHeight(h)
    end
    if win.now:IsShown() then
        local h = win.now:Fit(CW); Place(win.now, h); y = y + h + GAP
    end
    if win.upd:IsShown() then
        local h = win.upd:Fit(CW); Place(win.upd, h); y = y + h + GAP
    end
    local d = cards.dungeons
    local dh = d:Fit(CW); Place(d, dh); y = y + dh + GAP
    for i = 1, #ORDER, 2 do
        local a, b = cards[ORDER[i]], cards[ORDER[i + 1]]
        local h = math.max(a:Fit(TILE_W), b and b:Fit(TILE_W) or 0)
        Place(a, h, 0, TILE_W)
        if b then Place(b, h, TILE_W + GAP, TILE_W) end
        y = y + h + (i + 2 <= #ORDER and GAP or 0)
    end
    y = math.ceil(y)
    win.scroll:SetContentHeight(y + 24)
    win:FitHeight(y)
end

local upN, bagsDirty = 0, true   -- the upgrades tile's bag scan, redone only after the bags changed

local function Build()
    win = S.Window("WLHelperHome", W, 400, "WL Helper", nil, WLWritsDB, "homePos", { header = 44, footer = true, minH = 240 })

    local gear = S.IconButton(win.header, "gear", 28, { L("Réglages"), L("Clic : ouvrir les réglages") }, function()
        Close(); if WP.ShowOptionsPage then WP.ShowOptionsPage() end
    end)
    win:AddHeaderButton(gear)
    win.gear = gear

    -- footer: the version on the left, "Nous écrire" on the right
    local idea = S.Button(win.footer, L("Nous écrire"), 0, 24, "ghost", function()
        Close(); if WP.Feedback then WP.Feedback("idea") end
    end, { L("Une idée, un bug ?"), L("Clic : ouvrir le formulaire pour nous écrire") })
    idea:SetPoint("RIGHT", win.footer, "RIGHT", -4, 0)
    win.footer.button = idea
    win.idea = idea
    win:SetFooter("WL Helper " .. Version(), "")

    -- the cards scroll when the screen is too short for them; the footer stays under them
    local sa = S.ScrollArea(win)
    sa:SetPoint("TOPLEFT", win, "TOPLEFT", 0, -win:ContentTop())
    sa:SetPoint("BOTTOMRIGHT", win.footer, "TOPRIGHT", 0, 0)
    win.scroll, win.inner = sa, sa.child

    win.now = BuildNow()
    win.now:Hide()
    win.upd = S.Banner(win.inner, "info", "")
    win.upd:Hide()

    cards.dungeons = Card("dungeons", "Interface\\Icons\\INV_Misc_Map_01", OpenGuide)
    cards.writs = Card("writs", "Interface\\Icons\\INV_Letter_15", function() WP.Open("writs") end)
    cards.favor = Card("favor", "Interface\\Icons\\INV_Crate_04", function() WP.Open("favor") end)
    cards.favor.module = "writs"
    cards.bags = Card("bags", "Interface\\Icons\\INV_Misc_Bag_08", function() if WP.Cleaner then WP.Cleaner.Toggle() end end)
    cards.orders = Card("orders", "Interface\\Icons\\Trade_BlackSmithing", function() if WP.ToggleOrders then WP.ToggleOrders() end end)
    cards.guild = Card("guild", "Interface\\Icons\\INV_BannerPVP_01", function() if WP.ToggleGuild then WP.ToggleGuild() end end)
    cards.events = Card("events", "Interface\\Icons\\Ability_Warrior_BattleShout", function() if WP.ToggleEvents then WP.ToggleEvents() end end)
    cards.upgrades = Card("upgrades", "Interface\\Icons\\INV_Chest_Cloth_17", function() if WP.ShowOptionsPage then WP.ShowOptionsPage("upgrades") end end)
    cards.help = Card("help", "Interface\\Icons\\INV_Misc_Book_09", function() if WP.Help then WP.Help.Toggle() end end)
    cards.help.module = nil

    win:SetScript("OnShow", function() bagsDirty = true; WP.RefreshHome() end)
    local ev = CreateFrame("Frame", nil, win)
    pcall(ev.RegisterEvent, ev, "QUEST_LOG_UPDATE"); pcall(ev.RegisterEvent, ev, "BAG_UPDATE_DELAYED"); pcall(ev.RegisterEvent, ev, "UPDATE_FACTION")
    local queued = false
    ev:SetScript("OnEvent", function(self, event)
        if event == "BAG_UPDATE_DELAYED" then bagsDirty = true end
        if not win:IsShown() or queued then return end
        queued = true
        C_Timer.After(0.5, function() queued = false; WP.RefreshHome() end)
    end)
end

local function Refresh()
    local On = WP.ModuleOn
    win.subtitle:SetText(string.format(L("%s, niveau %d"), UnitName("player") or "", UnitLevel("player") or 0))
    local open, ready, bag, nextE = 0, 0, 0, nil

    -- quest guide
    local dLabel, cur, total, dFinished, nextStep = DungeonState()
    local d = cards.dungeons
    if dLabel and not dFinished then
        d:Show2({ title = L("Guide de quêtes"), line1 = dLabel,
            line2 = (nextStep and nextStep ~= "") and string.format(L("Prochaine étape : %s"), nextStep) or nil,
            pill = string.format(L("Étape %d sur %d"), cur or 1, total or 1), hint = L("Clic : ouvrir le guide") })
    elseif dLabel then
        d:Show2({ title = L("Guide de quêtes"), line1 = dLabel, line2 = L("Choisis tes prochains donjons."),
            pill = L("Terminée"), pillColor = C.ok, hint = L("Clic : choisir les donjons") })
    else
        d:Show2({ title = L("Guide de quêtes"), line1 = L("Aucun donjon choisi"),
            line2 = L("Donjons, raids et quêtes de classe, depuis là où tu es."), hint = L("Clic : choisir les donjons") })
    end

    -- Writs: the reputation, then what waits
    local need, goal, nReady, nBag = WritState()
    if need then
        ready, bag = nReady, nBag
        local parts = {}
        if ready > 0 then parts[#parts + 1] = N(ready, "1 Writ prêt à rendre", "%d Writs prêts à rendre") end
        if bag > 0 then parts[#parts + 1] = N(bag, "1 enveloppe à ouvrir", "%d enveloppes à ouvrir") end
        cards.writs:Show2({ title = L("Writs"),
            line1 = need > 0 and string.format(L("%s dans %d points"), WP.Reaction(goal), need) or string.format(L("%s atteint"), WP.Reaction(goal)),
            line2 = #parts > 0 and table.concat(parts, " · ") or L("Rien à rendre pour l'instant"),
            count = ready + bag, urgent = ready > 0, hint = L("Clic : ouvrir les Writs") })
    else
        cards.writs:Show2({ title = L("Writs"), line1 = L("Faction pas encore vue"), line2 = L("Parle à un PNJ de cette faction pour qu'elle apparaisse."),
            lineColor = C.muted, hint = L("Clic : ouvrir les Writs") })
    end

    -- Merchant's Favor
    local favor = WP.FavorNow and WP.FavorNow()
    cards.favor:Show2({ title = L("Faveur du marchand"),
        line1 = favor and N(favor, "1 point de Faveur", "%d points de Faveur") or L("Pas encore de Faveur"),
        line2 = L("Les caisses les moins chères et où les rendre"), hint = L("Clic : voir les caisses") })

    -- bags
    local nBag = On("bags") and BagCount() or 0
    cards.bags:Show2({ title = L("Sacs"),
        line1 = nBag > 0 and N(nBag, "1 objet de quête à jeter", "%d objets de quête à jeter") or L("Rien à jeter"),
        lineColor = nBag > 0 and C.warn or C.text,
        line2 = L("Les objets de quête qui ne servent plus"), count = nBag, hint = L("Clic : voir les objets à jeter") })

    -- orders: what waits for you
    local running = 0
    if WP.Orders then
        open = OrdersOpen()
        for _, o in ipairs(WP.Orders.Lists() or {}) do
            if o.status == "open" or o.status == "accepted" or o.status == "crafted" then running = running + 1 end
        end
    end
    cards.orders:Show2({ title = L("Commandes"),
        line1 = open > 0 and N(open, "1 commande à accepter", "%d commandes à accepter") or L("Faire fabriquer par la guilde"),
        line2 = running > 0 and N(running, "Tu as 1 commande en cours", "Tu as %d commandes en cours") or nil,
        count = open, urgent = open > 0, hint = L("Clic : ouvrir les commandes") })

    -- guild: who is on, and where you stand in this week's PvP ranking
    if IsInGuild and IsInGuild() and WP.GuildRoster then
        local _, online = WP.GuildRoster(true)
        online = online or 0
        local pos
        for i, e in ipairs(WP.GuildRanking and WP.GuildRanking(true) or {}) do if e.name == UnitName("player") then pos = i end end
        cards.guild:Show2({ title = L("Guilde"), line1 = N(online, "1 membre en ligne", "%d membres en ligne"),
            line2 = pos and (pos == 1 and L("Tu es 1er au classement PvP de la semaine") or string.format(L("Tu es %de au classement PvP de la semaine"), pos))
                or L("Classement PvP de la semaine"),
            hint = L("Clic : ouvrir la guilde") })
    else
        cards.guild:Show2({ title = L("Guilde"), line1 = L("Tu n'es pas dans une guilde"), lineColor = C.muted, hint = L("Clic : ouvrir la guilde") })
    end

    -- events: the next one, and who looks for a group now
    local lfg, nEvents = 0, 0
    if WP.EventList then
        local list = WP.EventList()
        nEvents = #list
        for _, e in ipairs(list) do if e.status == "open" and e.when >= time() - 1800 then nextE = e; break end end
        lfg = WP.LFGList and #WP.LFGList() or 0
    end
    cards.events:Show2({ title = L("LFG"),
        line1 = nextE and (tostring(nextE.title) .. " · " .. WP.EventWhen(nextE.when)) or L("Aucun événement prévu"),
        lineColor = nextE and C.text or C.muted,
        line2 = lfg > 0 and N(lfg, "1 joueur cherche un groupe", "%d joueurs cherchent un groupe")
            or (nEvents > 0 and N(nEvents, "1 événement à venir", "%d événements à venir") or nil),
        count = lfg, hint = L("Clic : ouvrir le LFG") })

    -- upgrades: how many bag items are better than what you wear, for which spec
    local Wt = WP.Weights
    if Wt then
        local GetLink = C_Container and C_Container.GetContainerItemLink
        if bagsDirty and GetLink and WP.UpgradeCheck then
            -- every bag slot is checked: only after the bags changed, not on every refresh
            upN = 0
            for bagID = 0, NUM_BAG_SLOTS or 4 do
                for slot = 1, (C_Container.GetContainerNumSlots(bagID) or 0) do
                    local link = GetLink(bagID, slot)
                    if link and WP.UpgradeCheck(link).up then upN = upN + 1 end
                end
            end
            bagsDirty = false
        end
        cards.upgrades:Show2({ title = L("Améliorations"),
            line1 = upN > 0 and N(upN, "1 amélioration dans tes sacs", "%d améliorations dans tes sacs") or L("Rien de mieux dans tes sacs"),
            lineColor = upN > 0 and C.ok or C.text,
            line2 = string.format(L("Selon ta spé %s"), Wt.SpecName() or "?"),
            count = upN, hint = L("Clic : choisir ta spé et voir tes améliorations") })
    else
        cards.upgrades:Show2({ title = L("Améliorations"), line1 = L("Rien de mieux dans tes sacs"), hint = L("Clic : choisir ta spé et voir tes améliorations") })
    end

    -- the task guide
    cards.help:Show2({ title = L("Comment faire... ?"), line1 = L("Les gestes utiles, pas à pas"),
        line2 = L("Questions fréquentes et commandes"), hint = L("Clic : ouvrir Comment faire... ?") })

    -- switched-off modules: dimmed, a click turns them back on
    for _, card in pairs(cards) do
        if card.module and not On(card.module) then card:ShowOff(card.title:GetText()) end
    end

    -- "now": the first thing that waits, from the most urgent down; nothing waits: no strip
    local t = win.now
    local shown = true
    if On("orders") and open > 0 then
        t:Set("Interface\\Icons\\Trade_BlackSmithing", N(open, "1 commande attend ta réponse.", "%d commandes attendent ta réponse."), L("Voir les commandes"),
            function() Close(); if WP.ToggleOrders then WP.ToggleOrders() end end)
    elseif On("writs") and ready > 0 then
        t:Set("Interface\\Icons\\INV_Letter_15", N(ready, "1 Writ est prêt à rendre.", "%d Writs sont prêts à rendre."), L("Y aller"), function()
            Close()
            -- the tour already runs: on to the next stop; otherwise start it
            if WLWritsCharDB and WLWritsCharDB.gps then WP.GoNext() else WP.ToggleGPS() end
        end)
    elseif On("writs") and bag > 0 then
        t:Set("Interface\\Icons\\INV_Letter_15", N(bag, "1 enveloppe à ouvrir dans tes sacs.", "%d enveloppes à ouvrir dans tes sacs."), L("Voir les Writs"),
            function() Close(); WP.Open("writs") end)
    elseif On("events") and nextE and nextE.when - time() < 3600 then
        local mins = math.ceil((nextE.when - time()) / 60)
        t:Set("Interface\\Icons\\Ability_Warrior_BattleShout",
            mins > 0 and string.format(L("%s commence dans %d min."), nextE.title, mins) or string.format(L("%s a commencé."), nextE.title),
            L("Voir l'événement"), function() Close(); if WP.ToggleEvents then WP.ToggleEvents() end end)
    elseif On("dungeons") and dLabel and not dFinished and nextStep and nextStep ~= "" then
        t:Set("Interface\\Icons\\INV_Misc_Map_01", string.format(L("Prochaine étape : %s"), nextStep), L("Reprendre le guide"),
            function() Close(); root.ShowGuide() end)
    elseif On("bags") and nBag > 0 then
        t:Set("Interface\\Icons\\INV_Misc_Bag_08", N(nBag, "1 objet de quête ne sert plus.", "%d objets de quête ne servent plus."), L("Nettoyer les sacs"),
            function() Close(); if WP.Cleaner then WP.Cleaner.Toggle() end end)
    elseif WP.GPS and WP.GPS.Active() then
        -- only a running GPS: a quiet line, its stop is not the main thing to do
        t:Set({ hd = root.ARROW }, string.format(L("Le GPS te guide vers %s."), WP.GPS.DestName() or "?"), L("Arrêter le GPS"),
            function() WP.StopGPS(); WP.RefreshHome() end, "secondary")
    else
        shown = false
    end
    t:SetShown(shown)

    -- a newer version seen on another player's copy
    local newer = WP.UpdateAvailable and WP.UpdateAvailable()
    if newer and WP.UpdateText then win.upd:SetText(WP.UpdateText(newer), "info") end
    win.upd:SetShown(newer ~= nil and WP.UpdateText ~= nil)

    Layout()
end

function WP.RefreshHome()
    if not (win and win:IsShown()) then return end
    Refresh()
    -- wrapped lines measure right once their width is applied: once more on the next frame
    if C_Timer and C_Timer.After then C_Timer.After(0, function() if win:IsShown() then Layout() end end) end
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

-- Tooltip: where you stand first, then what the mouse does.
function WP.MinimapTooltip(owner)
    local tt = GameTooltip
    tt:SetOwner(owner, "ANCHOR_LEFT")
    tt:AddLine("WL Helper", C.fg[1], C.fg[2], C.fg[3])
    local function Row(label, value, col)
        col = col or C.fg
        tt:AddDoubleLine(label, value, C.muted[1], C.muted[2], C.muted[3], col[1], col[2], col[3])
    end
    local label, cur, total, finished = DungeonState()
    if not WP.ModuleOn("dungeons") then Row(L("Guide de quêtes"), L("Éteint"), C.faint)
    elseif label then Row(L("Guide de quêtes"), finished and string.format(L("%s, terminée"), label) or string.format(L("%s, étape %d sur %d"), label, cur or 1, total or 1))
    else Row(L("Guide de quêtes"), L("Aucune route"), C.muted) end
    local need, _, ready = WritState()
    if not WP.ModuleOn("writs") then Row(L("Writs"), L("Éteint"), C.faint)
    elseif need then Row(L("Writs"), N(ready, "1 Writ prêt", "%d Writs prêts"), ready > 0 and C.ok or C.fg) end
    if not WP.ModuleOn("bags") then Row(L("Sacs"), L("Éteint"), C.faint)
    else
        local n = BagCount()
        Row(L("Sacs"), n > 0 and string.format(L("%d à jeter"), n) or L("Rien à jeter"), n > 0 and C.warn or C.fg)
    end
    local open = WP.ModuleOn("orders") and OrdersOpen() or 0
    if open > 0 then Row(L("Commandes"), string.format(L("%d à accepter"), open), C.ok) end
    local lfg = WP.ModuleOn("events") and WP.LFGList and #WP.LFGList() or 0
    if lfg > 0 then Row(L("LFG"), N(lfg, "1 cherche un groupe", "%d cherchent un groupe")) end
    local newer = WP.UpdateAvailable and WP.UpdateAvailable()
    if newer and WP.UpdateText then
        tt:AddLine(" ")
        tt:AddLine(WP.UpdateText(newer), C.info[1], C.info[2], C.info[3], true)
    end
    tt:AddLine(" ")
    local a = C.accentSoft
    tt:AddLine(L("Clic : ouvrir l'Accueil"), a[1], a[2], a[3])
    tt:AddLine(L("Clic droit : ouvrir un module"), a[1], a[2], a[3])
    tt:AddLine(L("Glisser : déplacer le bouton"), a[1], a[2], a[3])
    tt:Show()
end

-- Right-click menu: straight to a module. A list in the dropdown style (24 px rows, icons).
local menu
local function MenuRow(parent, y, icon, text, onClick, disabledReason, hint)
    local b = CreateFrame("Button", nil, parent)
    b.wlOwned = true
    b:SetHeight(24)
    b:SetPoint("TOPLEFT", 1, y); b:SetPoint("TOPRIGHT", -1, y)
    b.hl = S.Solid(b, "BACKGROUND", C.hoverFill); b.hl:SetAllPoints(); b.hl:SetAlpha(0)
    b.press = S.Solid(b, "BORDER", C.pressFill); b.press:SetAllPoints(); b.press:Hide()
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetSize(16, 16); b.icon:SetPoint("LEFT", 8, 0)
    b.hd = type(icon) == "table"
    if b.hd then root.SetHDIcon(b.icon, icon.hd, C.muted) else S.Painted(b.icon, icon) end
    b.label = S.Text(b, F.label, C.fg)
    b.label:SetPoint("LEFT", b.icon, "RIGHT", 8, 0); b.label:SetPoint("RIGHT", -8, 0)
    b.label:SetJustifyH("LEFT")
    b.label:SetText(text)
    S.ClampLabel(b.label, text, b)
    b.disabledReason = disabledReason
    local function Paint()
        local on = b:IsEnabled() ~= false
        b:SetAlpha(on and (b.off and 0.45 or 1) or C.disabledAlpha)
        if b.hd then local c = (b.hov and on) and C.fg or C.muted; b.icon:SetVertexColor(c[1], c[2], c[3]) end
    end
    b:SetScript("OnEnter", function(self)
        self.hov = true
        if self:IsEnabled() ~= false then root.Tween(self, 0, 1, 0.10, function(v) self.hl:SetAlpha(v) end) end
        Paint()
        if self:IsEnabled() == false then
            if self.disabledReason then S.Tip(self, { text, self.disabledReason }) end
        elseif self.off then
            S.Tip(self, { text, L("Module éteint"), L("Clic : allumer le module") })
        elseif hint then
            S.Tip(self, { text, hint })
        end
    end)
    b:SetScript("OnLeave", function(self)
        self.hov = nil
        root.Tween(self, 1, 0, 0.10, function(v) self.hl:SetAlpha(v) end)
        Paint(); S.HideTip()
    end)
    b:SetScript("OnMouseDown", function(self) if self:IsEnabled() ~= false then self.press:Show() end end)
    b:SetScript("OnMouseUp", function(self) self.press:Hide() end)
    b:SetScript("OnEnable", Paint); b:SetScript("OnDisable", Paint)
    b:SetScript("OnClick", function(self)
        menu:Hide()
        if self.off and self.module then WP.SetModule(self.module, true) end
        onClick()
    end)
    function b:SetOff(off) self.off = off and true or nil; Paint() end
    Paint()
    return b
end

function WP.MinimapMenu(owner)
    if not menu then
        menu = CreateFrame("Frame", "WLHelperMinimapMenu", UIParent)
        menu.wlOwned = true
        -- above minimap button bars and every window
        menu:SetFrameStrata("TOOLTIP"); menu:SetFrameLevel(50); menu:SetClampedToScreen(true); menu:EnableMouse(true)
        S.Solid(menu, "BACKGROUND", C.panel, 0.98):SetAllPoints()
        S.Border(menu, C.cardEdge)
        tinsert(UISpecialFrames, "WLHelperMinimapMenu")
        -- { icon, label, onClick, module (dimmed when off), key in menu.buttons, why disabled, click hint }
        local items = {
            { "Interface\\Icons\\INV_Misc_Map_01", L("Guide de quêtes"), OpenGuide, "dungeons", nil, nil, L("Clic : ouvrir le guide de quêtes") },
            { "Interface\\Icons\\INV_Letter_15", L("Writs"), function() WP.Open("writs") end, "writs", nil, nil, L("Clic : ouvrir les Writs") },
            { "Interface\\Icons\\INV_Crate_04", L("Faveur du marchand"), function() WP.Open("favor") end, "writs", "favor", nil, L("Clic : voir les caisses") },
            { "Interface\\Icons\\INV_Misc_Bag_08", L("Sacs"), function() if WP.Cleaner then WP.Cleaner.Toggle() end end, "bags", nil, nil, L("Clic : voir les objets à jeter") },
            { "Interface\\Icons\\Trade_BlackSmithing", L("Commandes"), function() if WP.ToggleOrders then WP.ToggleOrders() end end, "orders", nil, nil, L("Clic : ouvrir les commandes") },
            { "Interface\\Icons\\INV_BannerPVP_01", L("Guilde"), function() if WP.ToggleGuild then WP.ToggleGuild() end end, "guild", nil, nil, L("Clic : ouvrir la guilde") },
            { "Interface\\Icons\\Ability_Warrior_BattleShout", L("LFG"), function() if WP.ToggleEvents then WP.ToggleEvents() end end, "events", nil, nil, L("Clic : ouvrir le LFG") },
            { "Interface\\Icons\\INV_Chest_Cloth_17", L("Améliorations"), function() if WP.ShowOptionsPage then WP.ShowOptionsPage("upgrades") end end, "upgrades", nil, nil, L("Clic : choisir ta spé et voir tes améliorations") },
            false,
            { { hd = root.ARROW }, L("Arrêter le GPS"), function() WP.StopGPS() end, nil, "gps", L("Aucun trajet GPS en cours."), L("Clic : arrêter le GPS") },
            { { hd = "info" }, L("Comment faire... ?"), function() if WP.Help then WP.Help.Toggle() end end, nil, nil, nil, L("Clic : ouvrir Comment faire... ?") },
            { { hd = "gear" }, L("Réglages"), function() if WP.ShowOptionsPage then WP.ShowOptionsPage() end end, nil, nil, nil, L("Clic : ouvrir les réglages") },
            { { hd = "mail" }, L("Nous écrire"), function() if WP.Feedback then WP.Feedback("idea") end end, nil, nil, nil, L("Clic : ouvrir le formulaire pour nous écrire") },
        }
        local y = -4
        menu.buttons, menu.rows = {}, {}
        for _, it in ipairs(items) do
            if it then
                local b = MenuRow(menu, y, it[1], it[2], it[3], it[6], it[7])
                b.module = it[4]
                menu.rows[#menu.rows + 1] = b
                local key = it[5] or it[4]
                if key then menu.buttons[key] = b end
                y = y - 24
            else
                local line = S.Rule(menu)
                line:SetPoint("TOPLEFT", 8, y - 4); line:SetPoint("TOPRIGHT", -8, y - 4)
                y = y - 9
            end
        end
        menu:SetSize(208, -y + 4)
        -- closes when the mouse has left it for a moment
        menu:SetScript("OnUpdate", function(self, dt)
            if self:IsMouseOver() or (self.owner and self.owner:IsMouseOver()) then self.away = 0; return end
            self.away = (self.away or 0) + dt
            if self.away > 1.5 then self:Hide() end
        end)
    end
    if menu:IsShown() then menu:Hide(); return end
    menu.owner = owner; menu.away = 0
    menu.buttons.gps:SetEnabled(WP.GPS.Active() and true or false)
    for _, b in ipairs(menu.rows) do
        if b.module then b:SetOff(not WP.ModuleOn(b.module)) end
    end
    menu:ClearAllPoints()
    menu:SetPoint("TOPRIGHT", owner, "BOTTOMLEFT", 4, 4)
    GameTooltip:Hide()
    menu:Show()
end
