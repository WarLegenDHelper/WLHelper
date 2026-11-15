-- Writs/Help.lua: "Comment faire... ?", the task guide. One card per thing a player wants to do,
-- with three or four numbered clicks and a "Montre-moi" button that opens the right window and
-- makes the right button glow for a few seconds (WP.Spotlight). Then the questions that come up
-- in the guild, with real answers, and the useful /wlh commands (a click runs them).
-- Opened from its tile on the home page, /wlh aide and the end of the welcome window.
local ADDON, root = ...
root.Writs = root.Writs or {}
local ns = root.Writs
local WP = ns.WP
local L = ns.L
local S = ns.S
local C = S.C
local F = S.F

ns.AddEnglish({
    ["Comment faire... ?"] = "How do I...?",
    ["Montre-moi"] = "Show me",
    ["Clic : ouvrir la fenêtre et montrer le bouton"] = "Click: open the window and point at the button",
    ["Ouvre la fenêtre et fait briller le bouton à utiliser."] = "Opens the window and highlights the button to click.",
    ["Questions fréquentes"] = "Common questions",
    ["Commandes du chat"] = "Chat commands",
    ["Clic : lancer la commande"] = "Click: run the command",
    ["Une question sans réponse ? Écris-nous"] = "A question we missed? Tell us",
    -- the tasks (a quoted label comes from the button's own text: they cannot drift apart)
    ["Faire mes quêtes de donjon"] = "Do my dungeon quests",
    ["Sur l'Accueil, clique sur la tuile Guide de quêtes pour choisir tes donjons."] = "On Home, click the Quest guide tile to pick your dungeons.",
    ["Clique sur les donjons que tu veux faire. Plusieurs donjons donnent une seule route."] = "Click the dungeons you want to do. Several dungeons make one route.",
    ["Clique sur « %s » (le nombre suit tes choix) : la route part de là où tu es."] = "Click \"%s\" (the number follows what you picked): the route starts where you are.",
    ["Suis les étapes : « %s » lance le GPS vers l'étape en cours."] = "Follow the steps: \"%s\" starts the GPS to the current step.",
    ["Monter ma réputation avec les Writs"] = "Raise my reputation with Writs",
    ["À l'hôtel des ventes, ouvre les Writs, onglet Achats."] = "At the Auction House, open the Writs window, Shopping tab.",
    ["La fenêtre Writs choisit les Writs les moins chers. Clique sur « %s » (le nombre suit ta liste) : chaque page d'achat s'ouvre à la suite, et tu valides avec le bouton Acheter du jeu."] =
        "The Writs window picks the cheapest Writs. Click \"%s\" (the number follows your list): each purchase page opens in turn, and you confirm with the game's Buy button.",
    ["Ouvre les enveloppes dans tes sacs : chacune te donne sa quête de remise."] = "Open the envelopes in your bags: each one gives you its turn-in quest.",
    ["Dans l'onglet Aujourd'hui, « %s » te mène à chaque lieu de remise."] = "On the Today tab, \"%s\" takes you to each turn-in spot.",
    ["Faire fabriquer un objet"] = "Get an item crafted",
    ["Ouvre Commandes, onglet Artisans."] = "Open Orders, Crafters tab.",
    ["Tape le nom de l'objet, ou fais Maj-clic sur l'objet dans le chat."] = "Type the item's name, or shift-click the item in chat.",
    ["Clique sur « %s », puis dis ce que tu fournis et ce que tu paies."] = "Click \"%s\", then say what you provide and what you pay.",
    ["Clique sur « %s » : le premier artisan qui l'accepte la fabrique pour toi."] = "Click \"%s\": the first crafter who accepts it makes it for you.",
    ["Mes sacs sont pleins"] = "My bags are full",
    ["Ouvre Sacs : la liste des objets de quête qui ne servent plus."] = "Open Bags: the list of quest items you no longer need.",
    ["Clique sur « %s » : un objet par clic, jusqu'au bout de la liste."] = "Click \"%s\": one item per click, down to the end of the list.",
    ["Si tes sacs sont pleins quand tu ramasses du butin, un bouton « %s » apparaît : un clic jette l'objet le moins cher (gris, ou arme ou armure blanche)."] =
        "If your bags are full when you loot, a \"%s\" button shows up: one click throws away the cheapest item (grey, or a white weapon or armor).",
    ["Chez un marchand, tes objets gris se vendent tout seuls (Réglages, Sacs)."] = "At a merchant, your grey items sell by themselves (Settings, Bags).",
    ["Organiser un donjon avec la guilde"] = "Organize a dungeon with the guild",
    ["Ouvre LFG, onglet Créer."] = "Open Events, Create tab.",
    ["Choisis le donjon, le jour, l'heure et les places par rôle."] = "Pick the dungeon, the day, the time and the slots per role.",
    ["Clique sur « %s » : toute la guilde le voit et peut s'inscrire."] = "Click \"%s\": the whole guild sees it and can sign up.",
    ["À l'heure, « %s » forme le groupe en un clic."] = "When it is time, \"%s\" forms the group in one click.",
    ["Savoir si un objet est une amélioration"] = "Check if an item is an upgrade",
    ["Ouvre Réglages, Améliorations, et choisis ta spé."] = "Open Settings, Upgrades, and pick your spec.",
    ["Une flèche verte marque les objets meilleurs que les tiens : sacs, marchands, récompenses de quête."] = "A green arrow marks items better than yours: bags, merchants, quest rewards.",
    ["Survole l'objet : son infobulle donne le gain en %."] = "Hover the item: its tooltip gives the gain in %.",
    ["Aller quelque part (GPS)"] = "Go somewhere (GPS)",
    ["Dans le guide de quêtes, clique sur « %s » ; dans la fenêtre Writs, sur « %s »."] = "In the quest guide, click \"%s\"; in the Writs window, click \"%s\".",
    ["La flèche montre où aller et à quelle distance. Le trajet passe par les vols, bateaux, zeppelins et portails."] =
        "The arrow shows where to go and how far. The route uses flights, boats, zeppelins and portals.",
    ["Elle devient verte quand tu vas dans la bonne direction ; à l'arrivée, une coche verte s'affiche."] =
        "It turns green when you head the right way; when you arrive, a green check shows.",
    ["Pour l'arrêter, clique sur la croix de la flèche ou tape /wlh gps."] = "To stop it, click the arrow's cross or type /wlh gps.",
    -- the questions
    ["Pourquoi personne n'apparaît dans Artisans ?"] = "Why is nobody listed under Crafters?",
    ["Un artisan n'apparaît que s'il a WL Helper et qu'il a ouvert au moins une fois la fenêtre de son métier avec. Demande-le en guilde : ça suffit pour que ses recettes arrivent chez tout le monde."] =
        "A crafter shows up only once they have WL Helper and have opened their profession window at least once with it. Ask in guild chat: that is enough for their recipes to reach everyone.",
    ["Pourquoi le GPS m'envoie par là ?"] = "Why does the GPS send me that way?",
    ["Il cherche le trajet le plus rapide depuis là où tu es : à cheval, par les vols que tu connais, les bateaux, les zeppelins et les portails de mage. Un détour par un maître de vol est souvent plus court que la ligne droite. Le trajet est recalculé en continu, pendant que tu avances."] =
        "It looks for the fastest way from where you are: riding, the flight paths you know, boats, zeppelins and mage portals. A detour through a flight master is often shorter than the straight line. The route is worked out again all the time, as you move.",
    ["Comment déplacer la flèche ?"] = "How do I move the arrow?",
    ["Fais-la glisser avec le clic gauche : sa place est gardée. Sans route en cours, Réglages, GPS, « Déplacer la flèche » l'affiche pour que tu la places."] =
        "Drag it with the left mouse button: its spot is saved. With no route running, Settings, GPS, \"Move the arrow\" shows it so you can place it.",
    ["Comment éteindre un module ?"] = "How do I turn a module off?",
    ["Réglages, Général, Modules : un interrupteur par module. Un module éteint disparaît partout, sauf sa tuile grisée sur l'Accueil : un clic dessus le rallume."] =
        "Settings, General, Modules: one switch per module. A module that is off disappears everywhere except its greyed-out tile on Home: a click on it turns it back on.",
    ["Mètres ou yards ?"] = "Meters or yards?",
    ["Les distances sont en mètres et en kilomètres. Pour les yards du jeu : Réglages, GPS, « Distances en yards »."] =
        "Distances are in meters and kilometers. For the game's yards: Settings, GPS, \"Distances in yards\".",
    -- the commands (French words in French, English words in English: both work)
    ["/wlh"] = "/wlh",
    ["/wlh donjons"] = "/wlh dungeons",
    ["/wlh choisir"] = "/wlh pick",
    ["/wlh comptoir"] = "/wlh trade",
    ["/wlh sacs"] = "/wlh bags",
    ["/wlh commandes"] = "/wlh orders",
    ["/wlh evenements"] = "/wlh events",
    ["/wlh guilde"] = "/wlh guild",
    ["/wlh gps"] = "/wlh gps",
    ["/wlh reglages"] = "/wlh settings",
    ["/wlh idee"] = "/wlh idea",
    ["/wlh aide"] = "/wlh help",
    ["Ouvrir l'Accueil"] = "Open Home",
    ["Ouvrir le guide de quêtes"] = "Open the quest guide",
    ["Choisir les donjons"] = "Pick dungeons",
    ["Ouvrir les Writs"] = "Open the Writs window",
    ["Trier les objets de quête"] = "Sort out quest items",
    ["Ouvrir les commandes"] = "Open orders",
    ["Ouvrir les événements"] = "Open events",
    ["Ouvrir la guilde"] = "Open the guild",
    ["Arrêter ou relancer le GPS"] = "Stop or restart the GPS",
    ["Ouvrir les réglages"] = "Open settings",
    ["Envoyer une idée ou un bug"] = "Send an idea or a bug",
    ["Afficher cette page et la liste dans le chat"] = "Show this page and the list in chat",
})

local W = 520
local CW = W - 32            -- content width (inset 16 on both sides)
local PAD = 12               -- card pad

-- ---------------------------------------------------------------- spotlight

-- WP.Spotlight(frame, seconds): a pulsing accent ring around `frame` and the GPS arrow above it,
-- pointing down at it, for a few seconds. It never takes the mouse: the button stays clickable.
local spot
local function BuildSpot()
    spot = CreateFrame("Frame", nil, UIParent)
    spot.wlOwned = true
    spot:SetFrameStrata("FULLSCREEN_DIALOG")
    spot:EnableMouse(false)
    -- a 2 px accent ring just outside the target, a soft one 4 px further out
    for i, inset in ipairs({ 3, 4 }) do
        local r = CreateFrame("Frame", nil, spot)
        r:SetPoint("TOPLEFT", -inset, inset); r:SetPoint("BOTTOMRIGHT", inset, -inset)
        S.Border(r, C.accent, 1)
        spot["ring" .. i] = r
    end
    spot.halo = CreateFrame("Frame", nil, spot)
    spot.halo:SetPoint("TOPLEFT", -8, 8); spot.halo:SetPoint("BOTTOMRIGHT", 8, -8)
    S.Border(spot.halo, C.accentSoft, 0.45)
    spot.fill = S.Solid(spot, "BACKGROUND", C.accent, 0.10); spot.fill:SetAllPoints()
    -- the GPS arrow, pointing down at the button
    spot.arrow = spot:CreateTexture(nil, "ARTWORK")
    spot.arrow:SetSize(28, 28)
    local ok = pcall(spot.arrow.SetTexture, spot.arrow, root.ARROW, nil, nil, "TRILINEAR")
    if not ok then spot.arrow:SetTexture(root.ARROW) end
    if spot.arrow.SetRotation then pcall(spot.arrow.SetRotation, spot.arrow, math.pi) end
    spot.arrow:SetVertexColor(C.accentSoft[1], C.accentSoft[2], C.accentSoft[3], 1)
    spot:SetScript("OnUpdate", function(self, dt)
        self.t = (self.t or 0) + (dt or 0.016)
        local target = self.target
        local okV, vis = pcall(function() return target and target:IsVisible() end)
        if not (okV and vis) or self.t > self.life then self:Hide(); return end
        -- a slow pulse; the last 0.3 s fade out
        local pulse = 0.55 + 0.45 * (0.5 + 0.5 * math.cos(self.t * 2 * math.pi / 0.9))
        local fade = math.min(1, (self.life - self.t) / 0.3)
        self:SetAlpha(pulse * fade)
        self.arrow:ClearAllPoints()
        self.arrow:SetPoint("BOTTOM", self, "TOP", 0, 10 + 4 * math.abs(math.sin(self.t * math.pi / 0.6)))
    end)
    spot:Hide()
end

function WP.Spotlight(target, seconds)
    if not target then return end
    if not spot then BuildSpot() end
    spot:ClearAllPoints()
    spot:SetPoint("TOPLEFT", target, "TOPLEFT", 0, 0)
    spot:SetPoint("BOTTOMRIGHT", target, "BOTTOMRIGHT", 0, 0)
    spot.target = target
    spot.t, spot.life = 0, seconds or 5
    spot:SetAlpha(1)
    spot:Show()
end

-- ---------------------------------------------------------------- finding the button to show

local function Visible(f)
    local ok, v = pcall(function() return f:IsVisible() end)
    return ok and v == true
end
local function TextOf(obj)
    local ok, t = pcall(function() return obj:GetText() end)
    if ok and type(t) == "string" and not (root.IsSecret and root.IsSecret(t)) then return t end
    return nil
end
local function Matches(text, words)
    if not text or text == "" then return false end
    local low = text:lower()
    for _, w in ipairs(words) do
        if w ~= "" and low:find(w:lower(), 1, true) then return true end
    end
    return false
end
-- The first visible frame under `rootFrame` for which test(frame) is true (depth first).
local function Find(rootFrame, test, depth)
    depth = depth or 0
    if not rootFrame or depth > 20 then return nil end
    local ok, kids = pcall(function() return { rootFrame:GetChildren() } end)
    if not ok then return nil end
    for _, c in ipairs(kids) do
        if Visible(c) then
            local okT, hit = pcall(test, c)
            if okT and hit then return c end
            local deeper = Find(c, test, depth + 1)
            if deeper then return deeper end
        end
    end
    return nil
end
local function IsButton(f)
    local ok, t = pcall(function() return f:GetObjectType() end)
    return ok and t == "Button"
end
local function FontTexts(f)
    local out = {}
    local ok, regs = pcall(function() return { f:GetRegions() } end)
    if ok then
        for _, r in ipairs(regs) do
            local okT, ty = pcall(function() return r:GetObjectType() end)
            if okT and ty == "FontString" then out[#out + 1] = TextOf(r) end
        end
    end
    return out
end
-- what = "primary" (the view's main button), "editbox", a function giving a frame, or a list of
-- words found in a button's label (then in any text of the window).
local function Resolve(win, what)
    if type(what) == "function" then
        local ok, f = pcall(what)
        return ok and f and Visible(f) and f or nil
    end
    if not win then return nil end
    if what == "primary" then
        return Find(win, function(f) return IsButton(f) and f.kind == "primary" end)
    elseif what == "editbox" then
        return Find(win, function(f) return f:GetObjectType() == "EditBox" end)
    elseif type(what) == "table" then
        local b = Find(win, function(f)
            if not IsButton(f) then return false end
            if Matches(TextOf(f), what) then return true end
            for _, t in ipairs(FontTexts(f)) do if Matches(t, what) then return true end end
            return false
        end)
        if b then return b end
        return Find(win, function(f)
            for _, t in ipairs(FontTexts(f)) do if Matches(t, what) then return true end end
            return false
        end)
    end
    return nil
end

-- Opens a window with open(), then, once it is drawn, glows the first of `targets` found in the
-- window that windowFn() gives (the whole window when none is found).
local function ShowMe(open, windowFn, targets)
    if open then
        local ok, err = pcall(open)
        if not ok and geterrorhandler then geterrorhandler()(err) end
    end
    local function Glow()
        local win = windowFn and windowFn()
        if not (win and Visible(win)) then return end
        local hit
        for _, t in ipairs(targets or {}) do
            hit = Resolve(win, t)
            if hit then break end
        end
        WP.Spotlight(hit or win, 5)
    end
    if C_Timer and C_Timer.After then C_Timer.After(0.2, Glow) else Glow() end
end

-- ---------------------------------------------------------------- the content

local function GuideWord(key)
    local ok, v = pcall(function() return root.L and root.L[key] end)
    return ok and type(v) == "string" and v or ""
end
local function Win(name) return function() return _G[name] end end
local function ModuleOn(key) return not WP.ModuleOn or WP.ModuleOn(key) end
local function PickerGo() return _G.WLDTPicker and _G.WLDTPicker.go end

-- A step that quotes a button: the label is the button's own text (same key), so they never drift.
local function Quote(sentence, ...) return string.format(L(sentence), ...) end

-- the Options' "Spé évaluée" control (its row's choice), not the sidebar's page description
local function SpecControl()
    local w = _G.WLHelperOptions
    if not w then return nil end
    local want = L("Spé évaluée")
    local row = Find(w, function(f) return f.label and TextOf(f.label) == want end)
    return row and (row.control or row) or nil
end

local function Tasks()
    return {
        { key = "dungeons", icon = "Interface\\Icons\\INV_Misc_Map_01", title = L("Faire mes quêtes de donjon"),
          steps = { L("Sur l'Accueil, clique sur la tuile Guide de quêtes pour choisir tes donjons."),
                    L("Clique sur les donjons que tu veux faire. Plusieurs donjons donnent une seule route."),
                    Quote("Clique sur « %s » (le nombre suit tes choix) : la route part de là où tu es.", string.format(GuideWord("PICK_GON"), 3)),
                    Quote("Suis les étapes : « %s » lance le GPS vers l'étape en cours.", GuideWord("GO")) },
          show = function()
              ShowMe(function() if root.ShowPicker then root.ShowPicker() end end, Win("WLDTPicker"),
                  { PickerGo, { GuideWord("PICK_GO") } })
          end },
        { key = "writs", icon = "Interface\\Icons\\INV_Letter_15", title = L("Monter ma réputation avec les Writs"),
          steps = { L("À l'hôtel des ventes, ouvre les Writs, onglet Achats."),
                    Quote("La fenêtre Writs choisit les Writs les moins chers. Clique sur « %s » (le nombre suit ta liste) : chaque page d'achat s'ouvre à la suite, et tu valides avec le bouton Acheter du jeu.",
                        string.format(L("Acheter les %d objets"), 3)),
                    L("Ouvre les enveloppes dans tes sacs : chacune te donne sa quête de remise."),
                    Quote("Dans l'onglet Aujourd'hui, « %s » te mène à chaque lieu de remise.", L("Lancer la tournée GPS")) },
          show = function()
              ShowMe(function() WP.Open("writs"); if WP.ShowTab then WP.ShowTab("shop") end end, Win("WLHelperComptoir"), { "primary" })
          end },
        { key = "orders", icon = "Interface\\Icons\\Trade_BlackSmithing", title = L("Faire fabriquer un objet"),
          steps = { L("Ouvre Commandes, onglet Artisans."),
                    L("Tape le nom de l'objet, ou fais Maj-clic sur l'objet dans le chat."),
                    Quote("Clique sur « %s », puis dis ce que tu fournis et ce que tu paies.", L("Commander")),
                    Quote("Clique sur « %s » : le premier artisan qui l'accepte la fabrique pour toi.", L("Publier la commande")) },
          show = function()
              ShowMe(function() if WP.ShowOrdersTab then WP.ShowOrdersTab("find") end end, Win("WLHelperOrders"), { "editbox" })
          end },
        { key = "bags", icon = "Interface\\Icons\\INV_Misc_Bag_08", title = L("Mes sacs sont pleins"),
          steps = { L("Ouvre Sacs : la liste des objets de quête qui ne servent plus."),
                    Quote("Clique sur « %s » : un objet par clic, jusqu'au bout de la liste.", L("Détruire")),
                    Quote("Si tes sacs sont pleins quand tu ramasses du butin, un bouton « %s » apparaît : un clic jette l'objet le moins cher (gris, ou arme ou armure blanche).", L("Libérer une place")),
                    L("Chez un marchand, tes objets gris se vendent tout seuls (Réglages, Sacs).") },
          show = function()
              ShowMe(function()
                  local w = _G.WLHelperCleaner
                  if not (w and w:IsShown()) and WP.Cleaner then WP.Cleaner.Toggle() end
              end, Win("WLHelperCleaner"), { "primary" })
          end },
        { key = "events", icon = "Interface\\Icons\\Ability_Warrior_BattleShout", title = L("Organiser un donjon avec la guilde"),
          steps = { L("Ouvre LFG, onglet Créer."),
                    L("Choisis le donjon, le jour, l'heure et les places par rôle."),
                    Quote("Clique sur « %s » : toute la guilde le voit et peut s'inscrire.", L("Publier l'événement")),
                    Quote("À l'heure, « %s » forme le groupe en un clic.", L("Inviter les inscrits")) },
          show = function()
              ShowMe(function() if WP.ShowEventsTab then WP.ShowEventsTab("create") end end, Win("WLHelperEvents"), { "primary" })
          end },
        { key = "upgrades", icon = "Interface\\Icons\\INV_Chest_Cloth_17", title = L("Savoir si un objet est une amélioration"),
          steps = { L("Ouvre Réglages, Améliorations, et choisis ta spé."),
                    L("Une flèche verte marque les objets meilleurs que les tiens : sacs, marchands, récompenses de quête."),
                    L("Survole l'objet : son infobulle donne le gain en %.") },
          show = function()
              ShowMe(function() if WP.ShowOptionsPage then WP.ShowOptionsPage("upgrades") end end, Win("WLHelperOptions"),
                  { SpecControl })
          end },
        { key = "gps", icon = "Interface\\Icons\\Ability_Tracking", title = L("Aller quelque part (GPS)"),
          steps = { Quote("Dans le guide de quêtes, clique sur « %s » ; dans la fenêtre Writs, sur « %s ».", GuideWord("GO"), L("Y aller")),
                    L("La flèche montre où aller et à quelle distance. Le trajet passe par les vols, bateaux, zeppelins et portails."),
                    L("Elle devient verte quand tu vas dans la bonne direction ; à l'arrivée, une coche verte s'affiche."),
                    L("Pour l'arrêter, clique sur la croix de la flèche ou tape /wlh gps.") },
          show = function()
              local route = root.GuideStatus and root.GuideStatus()
              if route and ModuleOn("dungeons") then
                  ShowMe(function() if root.ShowGuide then root.ShowGuide() end end, function() return root.frame end,
                      { function() return root.frame and root.frame.go end, { GuideWord("GO") } })
              elseif ModuleOn("writs") then
                  ShowMe(function() WP.Open("writs"); if WP.ShowTab then WP.ShowTab("today") end end, Win("WLHelperComptoir"),
                      { { L("Y aller") } })
              else
                  ShowMe(function() if root.ShowPicker then root.ShowPicker() end end, Win("WLDTPicker"), { PickerGo })
              end
          end },
    }
end

local function Questions()
    return {
        { L("Pourquoi personne n'apparaît dans Artisans ?"),
          L("Un artisan n'apparaît que s'il a WL Helper et qu'il a ouvert au moins une fois la fenêtre de son métier avec. Demande-le en guilde : ça suffit pour que ses recettes arrivent chez tout le monde.") },
        { L("Pourquoi le GPS m'envoie par là ?"),
          L("Il cherche le trajet le plus rapide depuis là où tu es : à cheval, par les vols que tu connais, les bateaux, les zeppelins et les portails de mage. Un détour par un maître de vol est souvent plus court que la ligne droite. Le trajet est recalculé en continu, pendant que tu avances.") },
        { L("Comment déplacer la flèche ?"),
          L("Fais-la glisser avec le clic gauche : sa place est gardée. Sans route en cours, Réglages, GPS, « Déplacer la flèche » l'affiche pour que tu la places.") },
        { L("Comment éteindre un module ?"),
          L("Réglages, Général, Modules : un interrupteur par module. Un module éteint disparaît partout, sauf sa tuile grisée sur l'Accueil : un clic dessus le rallume.") },
        { L("Mètres ou yards ?"),
          L("Les distances sont en mètres et en kilomètres. Pour les yards du jeu : Réglages, GPS, « Distances en yards ».") },
    }
end

-- { shown command, what it does, the word sent to /wlh (nil: not clickable) }
local function Commands()
    return {
        { L("/wlh"), L("Ouvrir l'Accueil"), "" },
        { L("/wlh donjons"), L("Ouvrir le guide de quêtes"), "dungeons" },
        { L("/wlh choisir"), L("Choisir les donjons"), "pick" },
        { L("/wlh comptoir"), L("Ouvrir les Writs"), "trade" },
        { L("/wlh sacs"), L("Trier les objets de quête"), "bags" },
        { L("/wlh commandes"), L("Ouvrir les commandes"), "orders" },
        { L("/wlh evenements"), L("Ouvrir les événements"), "events" },
        { L("/wlh guilde"), L("Ouvrir la guilde"), "guild" },
        { L("/wlh gps"), L("Arrêter ou relancer le GPS"), "gps" },
        { L("/wlh reglages"), L("Ouvrir les réglages"), "options" },
        { L("/wlh idee"), L("Envoyer une idée ou un bug"), "idea" },
        { L("/wlh aide"), L("Afficher cette page et la liste dans le chat"), nil },
    }
end

-- ---------------------------------------------------------------- building blocks

local function CardBase(parent)
    local c = CreateFrame("Frame", nil, parent)
    c.wlOwned = true
    S.Solid(c, "BACKGROUND", C.cardFill):SetAllPoints()
    S.Border(c, C.cardEdge)
    return c
end

-- A task card: painted icon, the need as title, "Montre-moi" at the right, numbered steps.
local function TaskCard(parent, task, onShow)
    local c = CardBase(parent)
    c.key = task.key
    c.iconFrame = CreateFrame("Frame", nil, c)
    c.iconFrame:SetSize(32, 32); c.iconFrame:SetPoint("TOPLEFT", PAD, -PAD)
    c.icon = c.iconFrame:CreateTexture(nil, "ARTWORK"); c.icon:SetAllPoints()
    S.Painted(c.icon, task.icon)
    S.Border(c.iconFrame, C.cardEdge)
    c.title = S.Text(c, F.heading, C.fg)
    c.title:SetJustifyH("LEFT"); c.title:SetJustifyV("TOP")
    c.title:SetText(task.title)
    c.show = S.Button(c, L("Montre-moi"), 0, 24, "secondary", function() onShow(task) end,
        { L("Montre-moi"), L("Ouvre la fenêtre et fait briller le bouton à utiliser."), L("Clic : ouvrir la fenêtre et montrer le bouton") })
    c.show:SetIcon("search")
    c.show:SetPoint("TOPRIGHT", -PAD, -(PAD + 4))
    c.steps = {}
    for i, text in ipairs(task.steps) do
        local s = {}
        -- the number in a soft round chip under the icon column
        s.dot = root.Icon(c, "dot", 20, "ARTWORK", { 1, 1, 1 })
        s.dot:SetVertexColor(1, 1, 1, 0.14)
        s.num = S.Text(c, F.meta, C.fg, true)
        s.num:SetWordWrap(false); s.num:SetJustifyH("CENTER")
        s.num:SetPoint("CENTER", s.dot, "CENTER", 0, 0)
        s.num:SetText(tostring(i))
        s.text = S.Text(c, F.body, C.text)
        s.text:SetJustifyH("LEFT"); s.text:SetJustifyV("TOP")
        s.text:SetWordWrap(true)   -- a paragraph: no line limit
        s.text:SetText(text)
        c.steps[i] = s
    end
    function c:Fit(width)
        local x = PAD + 32 + 8
        local okW, bw = pcall(self.show.GetWidth, self.show)
        local btnW = (okW and type(bw) == "number" and bw > 0) and bw or 96
        local th = S.FitText(self.title, 2, width - x - PAD - btnW - 8, self)
        self.title:ClearAllPoints(); self.title:SetPoint("TOPLEFT", x, -PAD)
        local y = PAD + math.max(32, math.ceil(th)) + 8
        local textW = width - x - PAD
        for _, s in ipairs(self.steps) do
            local h = math.ceil(S.FitText(s.text, 0, textW, self))
            -- one line sits centred on its 20 px chip; more lines start at the chip's top
            s.text:ClearAllPoints(); s.text:SetPoint("TOPLEFT", x, -(y + (h <= 16 and 3 or 1)))
            s.dot:ClearAllPoints(); s.dot:SetPoint("TOPLEFT", PAD + 6, -y)
            y = y + math.max(20, h) + 8
        end
        local total = math.ceil(y - 8 + PAD)
        self:SetHeight(total)
        return total
    end
    return c
end

-- The questions: one card, a question (13 fg) then its answer (12 muted) per block, rules between.
local function FaqCard(parent, list)
    local c = CardBase(parent)
    c.items = {}
    for i, q in ipairs(list) do
        local it = {}
        it.q = S.Text(c, F.body, C.fg); it.q:SetJustifyH("LEFT"); it.q:SetJustifyV("TOP"); it.q:SetText(q[1])
        it.a = S.Text(c, F.label, C.muted); it.a:SetJustifyH("LEFT"); it.a:SetJustifyV("TOP")
        it.a:SetWordWrap(true); it.a:SetText(q[2])
        if i > 1 then it.rule = S.Rule(c) end
        c.items[i] = it
    end
    function c:Fit(width)
        local textW = width - 2 * PAD
        local y = PAD
        for _, it in ipairs(self.items) do
            if it.rule then
                it.rule:ClearAllPoints()
                it.rule:SetPoint("TOPLEFT", PAD, -(y + 6)); it.rule:SetPoint("TOPRIGHT", -PAD, -(y + 6))
                y = y + 12
            end
            it.q:ClearAllPoints(); it.q:SetPoint("TOPLEFT", PAD, -y)
            y = y + math.ceil(S.FitText(it.q, 2, textW, self)) + 4
            it.a:ClearAllPoints(); it.a:SetPoint("TOPLEFT", PAD, -y)
            y = y + math.ceil(S.FitText(it.a, 0, textW, self))
        end
        local total = math.ceil(y + PAD)
        self:SetHeight(total)
        return total
    end
    return c
end

-- The commands: one card, one row each (the command, then what it does); a click runs it.
local CMD_W = 132
local function CommandsCard(parent, list, onRun)
    local c = CardBase(parent)
    c.rows = {}
    for i, cmd in ipairs(list) do
        local r = CreateFrame("Button", nil, c)
        r.wlOwned = true
        r.hl = S.Solid(r, "BACKGROUND", C.hoverFill); r.hl:SetAllPoints(); r.hl:SetAlpha(0)
        r.press = S.Solid(r, "BORDER", C.pressFill); r.press:SetAllPoints(); r.press:Hide()
        r.cmd = S.Text(r, F.label, C.fg)
        r.cmd:SetPoint("TOPLEFT", PAD, -7); r.cmd:SetWidth(CMD_W - 8)
        r.cmd:SetText(cmd[1])
        S.ClampLabel(r.cmd, cmd[1], r)
        r.desc = S.Text(r, F.label, C.muted)
        r.desc:SetJustifyH("LEFT"); r.desc:SetJustifyV("TOP")
        r.desc:SetText(cmd[2])
        r.word = cmd[3]
        if i > 1 then r.rule = S.Rule(r); r.rule:SetPoint("TOPLEFT", PAD, 0); r.rule:SetPoint("TOPRIGHT", -PAD, 0) end
        if r.word then
            r:SetScript("OnEnter", function(self)
                root.Tween(self, self.hov or 0, 1, 0.10, function(v) self.hov = v; self.hl:SetAlpha(v) end)
                S.Tip(self, { cmd[1], cmd[2], L("Clic : lancer la commande") })
            end)
            r:SetScript("OnLeave", function(self)
                root.Tween(self, self.hov or 0, 0, 0.10, function(v) self.hov = v; self.hl:SetAlpha(v) end)
                S.HideTip()
            end)
            r:SetScript("OnMouseDown", function(self) self.press:Show() end)
            r:SetScript("OnMouseUp", function(self) self.press:Hide() end)
            r:SetScript("OnClick", function(self) onRun(self.word) end)
        else
            r:EnableMouse(false)
        end
        c.rows[i] = r
    end
    function c:Fit(width)
        local y = 4
        local descW = width - PAD - CMD_W - PAD
        for _, r in ipairs(self.rows) do
            local h = math.ceil(S.FitText(r.desc, 2, descW, r))
            r.desc:ClearAllPoints(); r.desc:SetPoint("TOPLEFT", PAD + CMD_W, -7)
            local rh = math.max(28, h + 14)
            r:ClearAllPoints()
            r:SetPoint("TOPLEFT", 0, -y); r:SetPoint("TOPRIGHT", 0, -y)
            r:SetHeight(rh)
            y = y + rh
        end
        local total = y + 4
        self:SetHeight(total)
        return total
    end
    return c
end

-- ---------------------------------------------------------------- the window

local win

-- Places every block in the scroll area (inset 16, 12 under the header rule) and fits the window.
local function Layout()
    if not win then return end
    local inner = win.inner
    local y = 12
    local function Place(f, h, gap)
        f:ClearAllPoints()
        f:SetPoint("TOPLEFT", inner, "TOPLEFT", 16, -y)
        f:SetWidth(CW)
        f:SetHeight(h)
        y = y + h + (gap or 0)
    end
    for i, card in ipairs(win.tasks) do
        Place(card, card:Fit(CW), i < #win.tasks and 12 or 0)
    end
    y = y + 16
    Place(win.faqHead, 32, 8)
    Place(win.faq, win.faq:Fit(CW), 0)
    y = y + 16
    Place(win.cmdHead, 32, 8)
    Place(win.cmds, win.cmds:Fit(CW), 8)
    -- a ghost button: its text starts on the content's left edge
    win.more:ClearAllPoints()
    win.more:SetPoint("TOPLEFT", inner, "TOPLEFT", 16 - 12, -y)
    y = y + 24
    local innerH = math.ceil(y - 12)
    win.scroll:SetContentHeight(innerH + 24)
    win:FitHeight(innerH)
end

local function Run(word)
    if SlashCmdList and SlashCmdList.WLDUNGEONTOOL then SlashCmdList.WLDUNGEONTOOL(word) end
end

local function Build()
    win = S.Window("WLHelperHelp", W, 400, L("Comment faire... ?"), nil, WLWritsDB, "helpPos", { header = 44, minH = 240 })
    local sa = S.ScrollArea(win)
    sa:SetPoint("TOPLEFT", win, "TOPLEFT", 0, -(win.headerH + 1))
    sa:SetPoint("BOTTOMRIGHT", win, "BOTTOMRIGHT", 0, 0)
    win.scroll = sa
    win.inner = sa.child
    local function onShow(task)
        if task.key ~= "gps" and WP.ModuleOff and WP.ModuleOff(task.key) then return end
        win:Hide()
        task.show()
    end
    win.tasks = {}
    for _, t in ipairs(Tasks()) do win.tasks[#win.tasks + 1] = TaskCard(win.inner, t, onShow) end
    win.faqHead = S.SectionHeader(win.inner, L("Questions fréquentes"))
    win.faq = FaqCard(win.inner, Questions())
    win.cmdHead = S.SectionHeader(win.inner, L("Commandes du chat"))
    win.cmds = CommandsCard(win.inner, Commands(), Run)
    win.more = S.Button(win.inner, L("Une question sans réponse ? Écris-nous"), 0, 24, "ghost", function()
        win:Hide(); if WP.Feedback then WP.Feedback("idea") end
    end)
    win.more:SetChevron(true)
    -- wrapped heights are right once the widths are applied: measure again on the next frame
    win:SetScript("OnShow", function()
        Layout()
        if C_Timer and C_Timer.After then C_Timer.After(0, function() if win:IsShown() then Layout() end end) end
    end)
end

WP.Help = {
    Toggle = function()
        if win and win:IsShown() then win:Hide(); return end
        if not win then Build() end
        win:Show()
        Layout()
    end,
    -- runs a task's "Montre-moi" without the window (WP.Help.ShowMe("bags")); false if unknown.
    -- A switched-off module only gets Core's chat line.
    ShowMe = function(key)
        for _, t in ipairs(Tasks()) do
            if t.key == key then
                if key ~= "gps" and WP.ModuleOff and WP.ModuleOff(key) then return true end
                t.show(); return true
            end
        end
        return false
    end,
}
