-- Writs/OrdersUI.lua: the Orders window (the guild's crafters by profession, a request, the open
-- orders, my orders, the orders for me) and the panel beside the mailbox that fills the mail for an
-- order. Engine: Orders.lua. Drawn with the design system (Style.lua): one 640 px window that fits
-- its content, HD icons for glyphs, painted game icons for things, text that wraps or shows its full
-- text in the tooltip.
local ADDON, root = ...
root.Writs = root.Writs or {}
local ns = root.Writs
local WP = ns.WP
local L = ns.L
local S = ns.S
local C = S.C
local F = S.F
local O = WP.Orders

ns.AddEnglish({
    -- window and tabs
    ["Faire fabriquer par la guilde"] = "Have the guild craft for you",
    ["Artisans"] = "Crafters",
    ["Demande"] = "Request",
    ["Ouvertes"] = "Open",
    ["Mes commandes"] = "My orders",
    ["Pour moi"] = "For me",
    ["1 artisan connu, en ligne"] = "1 known crafter, online",
    ["1 artisan connu, hors ligne"] = "1 known crafter, offline",
    ["%d artisans connus, dont %d en ligne"] = "%d known crafters, %d online",
    ["%d artisans connus, aucun en ligne"] = "%d known crafters, none online",
    ["Aucun artisan connu pour l'instant"] = "No known crafters yet",
    -- the profession grid
    ["Ex. Sac en étoffe runique, ou Maj-clic sur un objet"] = "E.g. Runecloth Bag, or shift-click an item",
    ["Aucun artisan"] = "No crafters",
    ["1 artisan"] = "1 crafter",
    ["%d artisans"] = "%d crafters",
    ["1 objet"] = "1 item",
    ["%d objets"] = "%d items",
    ["1 en ligne"] = "1 online",
    ["%d en ligne"] = "%d online",
    ["Personne en ligne"] = "Nobody online",
    ["En ligne : %s"] = "Online: %s",
    ["Clic : ouvrir le catalogue du métier"] = "Click: open the profession's catalogue",
    ["Aucun artisan connu"] = "No known crafters",
    ["Les membres qui ont WL Helper partagent leurs métiers en se connectant."] =
        "Members who have WL Helper share their professions when they log in.",
    ["Faire une demande"] = "Make a request",
    ["Partager mes recettes"] = "Share my recipes",
    ["Tu n'as pas encore de métier lu par l'addon. Ouvre ta fenêtre de métier une fois."] =
        "The addon has not read any of your professions yet. Open your profession window once.",
    ["%s %d : %s"] = "%s %d: %s",
    ["1 recette"] = "1 recipe",
    ["%d recettes"] = "%d recipes",
    ["pas encore lues"] = "not read yet",
    ["Ouvre ta fenêtre de métier une fois pour les partager."] = "Open your profession window once to share them.",
    ["Les autres membres voient ce que tu sais fabriquer et peuvent te commander."] =
        "Other members see what you can craft and can order from you.",
    ["Tes recettes restent sur ton ordinateur."] = "Your recipes stay on your computer.",
    -- a profession's catalogue
    ["Tous les métiers"] = "All professions",
    ["Clic : revenir à la liste des métiers"] = "Click: back to the list of professions",
    ["Clic : revenir au catalogue %s"] = "Click: back to the %s catalogue",
    ["En ligne seulement"] = "Online only",
    ["Seulement les objets qu'un artisan en ligne peut fabriquer"] = "Only items an online crafter can make",
    ["Ex. Potion de soins"] = "E.g. Healing Potion",
    ["Ex. Plastron"] = "E.g. Breastplate",
    ["Ex. Sac en étoffe"] = "E.g. Cloth Bag",
    ["Ex. Bottes"] = "E.g. Boots",
    ["Ex. Lunette"] = "E.g. Scope",
    ["Ex. Bracelets"] = "E.g. Bracers",
    ["Ex. Ragoût"] = "E.g. Stew",
    ["Ex. Bandage"] = "E.g. Bandage",
    ["Ex. Barre"] = "E.g. Bar",
    ["Aucune recette partagée"] = "No recipes shared",
    ["Les recettes arrivent quand les artisans de ce métier ouvrent leur fenêtre de métier."] =
        "Recipes show up when this profession's crafters open their profession window.",
    ["Aucun objet trouvé"] = "No items found",
    ["Aucun artisan en ligne ne fabrique ce que tu cherches."] = "No online crafter makes what you are looking for.",
    ["Voir aussi hors ligne"] = "Include offline",
    ["Personne n'a partagé de recette qui correspond à ce nom."] = "Nobody shared a recipe that matches this name.",
    ["Niveau %d requis"] = "Requires level %d",
    ["Composants inconnus"] = "Reagents unknown",
    ["Peuvent le fabriquer : %s"] = "Can craft it: %s",
    ["Clic : commander à %s"] = "Click: order from %s",
    ["Clic : commander à la guilde"] = "Click: order from the guild",
    ["Maj-clic : demander à toute la guilde"] = "Shift-click: ask the whole guild",
    ["Artisans de ce métier"] = "Crafters of this profession",
    ["Voir les recettes"] = "See recipes",
    ["Clic : voir les recettes de %s"] = "Click: see %s's recipes",
    ["en ligne"] = "online",
    ["hors ligne"] = "offline",
    ["vu il y a %d jours"] = "seen %d days ago",
    ["vu il y a plus d'un mois"] = "seen over a month ago",
    ["vu hier"] = "seen yesterday",
    ["toi"] = "you",
    ["(toi)"] = "(you)",
    ["Pas encore de recettes partagées par %s."] = "No recipes shared yet by %s.",
    ["Pas encore de recettes partagées par %s. Elles arrivent quand ce membre ouvre sa fenêtre de métier."] =
        "No recipes shared yet by %s. They show up when this member opens their profession window.",
    ["Pas encore de recettes partagées par %s. Elles arrivent quand ils ouvrent leur fenêtre de métier."] =
        "No recipes shared yet by %s. They show up when they open their profession window.",
    ["Ouvre ta fenêtre de métier pour partager les tiennes."] = "Open your profession window to share yours.",
    ["%d étoiles reçues pour des commandes livrées"] = "%d stars received for delivered orders",
    ["1 étoile reçue pour une commande livrée"] = "1 star received for a delivered order",
    ["Clic : commander à toute la guilde (le premier artisan qui accepte s'en charge)"] = "Click: order from the whole guild (the first crafter to accept takes it)",
    ["Maj-clic : commander à %s seulement"] = "Shift-click: order from %s only",
    ["Affine la recherche pour voir la suite (%d objets affichés sur %d)."] = "Narrow the search to see the rest (%d of %d items shown).",
    -- the catalogue's categories
    ["Niv. %d"] = "Lvl %d",
    ["Armes"] = "Weapons",
    ["Armure"] = "Armor",
    ["Sacs"] = "Bags",
    ["Consommables"] = "Consumables",
    ["Gemmes"] = "Gems",
    ["Munitions"] = "Ammo",
    ["Recettes"] = "Recipes",
    ["Divers"] = "Miscellaneous",
    ["Enchantements"] = "Enchants",
    ["Autres"] = "Other",
    ["Clic : replier la catégorie"] = "Click: fold the category",
    ["Clic : déplier la catégorie"] = "Click: unfold the category",
    -- a crafter's recipes
    ["Recettes de %s"] = "%s's recipes",
    ["%s %d"] = "%s %d",
    ["Commander"] = "Order",
    ["Recettes pas encore arrivées"] = "Recipes not here yet",
    ["Elles arrivent quand ce membre ouvre sa fenêtre de métier."] = "They show up when this member opens their profession window.",
    -- search results and a linked item
    ["Commander à la guilde"] = "Order from the guild",
    ["1 artisan possible"] = "1 possible crafter",
    ["%d artisans possibles"] = "%d possible crafters",
    ["Personne n'a déclaré ce métier : toute la guilde verra quand même ta commande."] =
        "Nobody declared this profession: the whole guild will still see your order.",
    ["Toute la guilde verra ta commande."] = "The whole guild will see your order.",
    ["Artisans possibles"] = "Possible crafters",
    ["recette connue"] = "knows the recipe",
    ["métier compatible"] = "has the profession",
    ["Personne n'a partagé cette recette"] = "Nobody shared this recipe",
    ["Une demande prévient quand même les artisans du métier."] = "A request still tells the profession's crafters.",
    ["Tape au moins 2 lettres."] = "Type at least 2 letters.",
    -- a new order
    ["Quantité"] = "Quantity",
    ["Pour"] = "For",
    ["Toute la guilde"] = "Whole guild",
    ["Seulement %s"] = "Only %s",
    ["Composants"] = "Reagents",
    ["Tu fournis · %d/%d"] = "You provide · %d/%d",
    ["L'artisan fournit"] = "Crafter provides",
    ["L'artisan fournit · ~%s"] = "Crafter provides · ~%s",
    ["Clic : c'est l'artisan qui le fournit"] = "Click: the crafter provides it",
    ["Clic : c'est toi qui le fournis"] = "Click: you provide it",
    ["Tu en as %d (sacs et banque)."] = "You have %d (bags and bank).",
    ["Composants à l'HV : %s%s. Commission conseillée : %s."] = "Reagents at the AH: %s%s. Suggested fee: %s.",
    ["Recette inconnue : précise dans le mot pour l'artisan qui fournit quels composants."] =
        "Recipe unknown: use the note to tell the crafter who provides which reagents.",
    ["Commission (po)"] = "Fee (g)",
    ["Pourboire (po)"] = "Tip (g)",
    ["Valable"] = "Valid for",
    ["3 j"] = "3 d",
    ["Un mot pour l'artisan"] = "A note for the crafter",
    ["Ex. Pas pressé, merci !"] = "E.g. No rush, thanks!",
    ["Payer d'avance"] = "Pay upfront",
    ["L'or part avec les composants. Sinon, tu paies à la livraison."] =
        "The gold goes with the reagents. Otherwise you pay on delivery.",
    ["Publier la commande"] = "Publish order",
    ["Rien ne part par la poste avant qu'un artisan accepte."] = "Nothing is mailed before a crafter accepts.",
    ["Les artisans prévenus la voient dans l'onglet Ouvertes."] = "The crafters told see it in the Open tab.",
    -- the Request tab
    ["Ce que tu veux"] = "What you want",
    ["Objet reconnu : %s"] = "Item found: %s",
    ["Pas un objet du jeu : ta demande partira avec ce texte."] = "Not an item the game knows: your request goes with this text.",
    ["Un nom d'objet suffit, même approximatif. Maj-clic marche depuis les sacs, le chat et les recettes."] =
        "An item name is enough, even a rough one. Shift-click works from bags, chat and recipes.",
    ["Métier"] = "Profession",
    ["Je ne sais pas"] = "I don't know",
    ["Tous les artisans de la guilde seront prévenus"] = "Every crafter of the guild will be told",
    ["Clic : prévenir les artisans de ce métier"] = "Click: tell this profession's crafters",
    ["Clic : prévenir tous les artisans"] = "Click: tell every crafter",
    ["1 artisan prévenu : %s"] = "1 crafter told: %s",
    ["%d artisans prévenus, dont %d en ligne : %s"] = "%d crafters told, %d online: %s",
    ["%d artisans prévenus, aucun en ligne : %s"] = "%d crafters told, none online: %s",
    ["Aucun artisan connu pour ce métier : toute la guilde verra quand même ta demande."] =
        "No known crafter for this profession: the whole guild will still see your request.",
    ["Publier la demande"] = "Publish request",
    ["Écris ce que tu veux, par exemple Sac en étoffe runique."] = "Type what you want, for example Runecloth Bag.",
    ["Demande publiée : %s ×%d (%s). Tu la suis dans Mes commandes."] = "Request published: %s ×%d (%s). Follow it in My orders.",
    -- order cards
    ["Ouverte"] = "Open", ["Prise"] = "Taken", ["Fabriquée"] = "Crafted", ["Livrée"] = "Delivered",
    ["Refusée"] = "Declined", ["Annulée"] = "Cancelled", ["Expirée"] = "Expired",
    ["Pour %s"] = "For %s",
    ["Pour la guilde"] = "For the guild",
    ["par %s"] = "by %s",
    ["De %s"] = "From %s",
    ["pour toi"] = "for you",
    ["pour la guilde"] = "for the guild",
    ["expire dans %d h"] = "expires in %d h",
    ["expire dans %d jours"] = "expires in %d days",
    ["expire bientôt"] = "expires soon",
    ["Commission et pourboire : %s"] = "Fee and tip: %s",
    ["pour %s"] = "for %s",
    ["Recette connue de %s"] = "Recipe known by %s",
    ["%s a le métier, recette pas encore partagée"] = "%s has the profession, recipe not shared yet",
    ["Message"] = "Message",
    ["Métier : %s"] = "Profession: %s",
    ["À envoyer à %s : %s"] = "To send to %s: %s",
    ["dont %d en banque"] = "%d in the bank",
    ["%s d'avance"] = "%s upfront",
    ["Tu fournis : %s"] = "You provide: %s",
    ["%s fournit : %s"] = "%s provides: %s",
    ["envoyés"] = "sent",
    ["L'artisan fournit : %s"] = "The crafter provides: %s",
    ["Reçu : %s"] = "Received: %s",
    ["tout est arrivé"] = "everything arrived",
    ["or : %s sur %s"] = "gold: %s of %s",
    ["Raison : %s"] = "Reason: %s",
    ["« %s »"] = "\"%s\"",
    ["Suivi : %s"] = "History: %s",
    ["%s : %s"] = "%s: %s",
    ["Accepte-la si tu peux la fabriquer."] = "Accept it if you can craft it.",
    ["En attente d'un artisan."] = "Waiting for a crafter.",
    ["Il te manque des composants à envoyer à %s."] = "You are missing reagents to send to %s.",
    ["Sors les composants de la banque, puis envoie-les à %s par la poste ou en échange."] =
        "Take the reagents out of the bank, then send them to %s by mail or trade.",
    ["Envoie les composants à %s par la poste ou en échange."] = "Send the reagents to %s by mail or trade.",
    ["%s fabrique ta commande."] = "%s is crafting your order.",
    ["Fabriquée : %s te l'envoie par la poste ou en échange."] = "Crafted: %s sends it to you by mail or trade.",
    ["Fabrique l'objet : l'addon le voit tout seul dans tes sacs."] = "Craft the item: the addon sees it in your bags on its own.",
    ["Fabrique-la, puis marque-la comme fabriquée."] = "Craft it, then mark it as crafted.",
    ["Livre-la à %s par la poste ou en échange."] = "Deliver it to %s by mail or trade.",
    ["Commande terminée."] = "Order complete.",
    ["Accepter"] = "Accept",
    ["Clic : accepter cette commande"] = "Click: accept this order",
    ["Refuser"] = "Decline",
    ["Clic : choisir la raison du refus"] = "Click: pick the reason to decline",
    ["Masquer"] = "Hide",
    ["Seulement pour toi : le reste de la guilde la voit toujours."] = "Only for you: the rest of the guild still sees it.",
    ["Clic : masquer cette commande"] = "Click: hide this order",
    ["Marquer fabriquée"] = "Mark crafted",
    ["Marquer livrée"] = "Mark delivered",
    ["Marquer reçue"] = "Mark received",
    ["Si l'addon ne l'a pas vue arriver (enchantement, courrier pas encore ouvert)."] =
        "If the addon did not see it arrive (an enchant, a mail not opened yet).",
    ["Annuler la commande"] = "Cancel order",
    ["La guilde ne la voit plus."] = "The guild no longer sees it.",
    ["Clic : annuler (un second clic confirme)"] = "Click: cancel (a second click confirms)",
    ["Payé à la livraison ou en échange : l'addon ne déplace jamais d'or tout seul."] =
        "Paid on delivery or by trade: the addon never moves gold by itself.",
    ["%s est prévenu que sa commande est prête."] = "%s is told their order is ready.",
    ["Si tu l'as remise en échange ou si l'addon ne l'a pas vue partir."] = "If you handed it over by trade or the addon did not see it leave.",
    ["Seuls le client et l'artisan voient ce message."] = "Only the customer and the crafter see this message.",
    ["Confirmer l'annulation"] = "Confirm cancel",
    ["Acheter 1 composant"] = "Buy 1 reagent",
    ["Acheter %d composants"] = "Buy %d reagents",
    ["À l'HV : chaque achat ouvre le suivant."] = "At the AH: each purchase opens the next one.",
    ["L'HV n'est pas ouvert : parle à un commissaire-priseur, puis reclique sur Acheter."] =
        "The AH is not open: talk to an auctioneer, then click Buy again.",
    ["Préparer le courrier"] = "Fill in the mail",
    ["À la boîte aux lettres, l'addon remplit le destinataire, les composants et l'or."] =
        "At the mailbox, the addon fills in the recipient, the reagents and the gold.",
    ["Aucune boîte aux lettres ouverte : va à une boîte aux lettres, ou échange les composants avec %s."] =
        "No mailbox open: go to a mailbox, or trade the reagents with %s.",
    ["Ajouter 1 po de pourboire"] = "Add a 1 g tip",
    ["Pourboire ajouté"] = "Tip added",
    ["Remercier"] = "Thank",
    ["Clic : donner une étoile à %s"] = "Click: give %s a star",
    ["Commander à nouveau"] = "Order again",
    ["Clic : refaire la même commande"] = "Click: place the same order again",
    ["Clic : la proposer à toute la guilde"] = "Click: offer it to the whole guild",
    ["Refusée par %s : Commander à nouveau la propose à toute la guilde."] = "Declined by %s: Order again offers it to the whole guild.",
    ["Écrire à %s"] = "Message %s",
    ["Pourboire pour %s : %s au total. Il est payé à la réception (contre-remboursement) ou en échange."] =
        "Tip for %s: %s in total. It is paid on receipt (cash on delivery) or by trade.",
    ["Pourboire pour %s : %s au total. Envoie-le par la poste ou en échange : l'addon ne déplace jamais d'or tout seul."] =
        "Tip for %s: %s in total. Send it by mail or trade: the addon never moves gold by itself.",
    -- empty lists
    ["Aucune commande pour tes métiers"] = "No orders for your professions",
    ["Les commandes que tu sais fabriquer apparaîtront ici."] = "Orders you can craft will show up here.",
    ["Voir toutes les commandes"] = "See all orders",
    ["Aucune commande ouverte"] = "No open orders",
    ["Les commandes des membres de la guilde apparaîtront ici."] = "Guild members' orders will show up here.",
    ["Seulement ce que je sais fabriquer"] = "Only what I can craft",
    ["Tu n'as rien commandé"] = "You have not ordered anything",
    ["Tes commandes et leur suivi apparaîtront ici."] = "Your orders and their progress will show up here.",
    ["Aucune commande pour toi"] = "No orders for you",
    ["Les commandes qu'un membre t'adresse, ou que tu acceptes, apparaîtront ici."] =
        "Orders a member sends you, or that you accept, will show up here.",
    ["Voir les commandes ouvertes"] = "See open orders",
    -- message and decline windows
    ["Message à %s"] = "Message to %s",
    ["Ton message"] = "Your message",
    ["Ex. Les composants arrivent ce soir"] = "E.g. The reagents arrive tonight",
    ["Envoyer le message"] = "Send message",
    ["Refuser la commande"] = "Decline the order",
    ["Choisis la raison : le client la verra."] = "Pick a reason: the customer will see it.",
    -- beside the mailbox
    ["Commandes à poster"] = "Orders to mail",
    ["Un clic remplit le courrier. Vérifie-le, puis clique sur Envoyer."] = "One click fills in the mail. Check it, then click Send.",
    ["Pour %s · composants"] = "For %s · reagents",
    ["Pour %s · livraison"] = "For %s · delivery",
    ["Prêt, clique sur Envoyer"] = "Ready, click Send",
    ["Il manque dans tes sacs : %s. Sors-les de la banque ou achète-les, puis reclique."] =
        "Missing from your bags: %s. Take them out of the bank or buy them, then click again.",
})

-- one window, 640 wide (a wide tool: five tabs with their counters fit); content inset 16
local W, PAD = 640, 16
local CW = W - 2 * PAD
local win, tabs, pages, current = nil, nil, {}, "find"
local ui = { find = {}, mine = {}, recv = {}, new = {}, board = {}, ask = {} }
WP.OrdersUI = ui   -- the pages' widgets, for the offline tests

local function secret(v) return root.IsSecret and root.IsSecret(v) end
local function num(v) return type(v) == "number" and not secret(v) and v or nil end
-- n == 1 or not, in both languages (the strings come through L at the call site)
local function P(n, one, many) return string.format(n == 1 and one or many, n) end
local STAR = S.IconMarkup("star", 12, C.gold)
local function Money(c) return S.Money(c or 0) end
local function Name(id) return O.Name(id) end
local function Clock(t)
    if root.lang == "en" then return (date("%I:%M %p", t):gsub("^0", "")) end
    return date("%H:%M", t)
end
local STATUS = { open = "Ouverte", accepted = "Prise", crafted = "Fabriquée", delivered = "Livrée",
    declined = "Refusée", cancelled = "Annulée", expired = "Expirée" }
local STATUS_COL = { open = C.fg, accepted = C.fg, crafted = C.fg, delivered = C.ok, declined = C.bad, cancelled = C.fg, expired = C.fg }
local STATUS_ICON = { delivered = "check", declined = "warning" }

-- ---------------------------------------------------------------- shared pieces

-- hover fill (0.10 s), pressed fill, and the tooltip (self.tip: lines or a function; self.tipFill
-- runs first) on anything clickable
local function Feedback(b)
    b.hl = S.Solid(b, "BORDER", C.hoverFill); b.hl:SetAllPoints(); b.hl:SetAlpha(0)
    b.press = S.Solid(b, "BORDER", C.pressFill); b.press:SetAllPoints(); b.press:Hide()
    b:SetScript("OnEnter", function(self)
        S.Tween(self, self.hov or 0, 1, 0.10, function(v) self.hov = v; self.hl:SetAlpha(v) end)
        if self.OnHover then self:OnHover(true) end
        if self.tipFill then self.tipFill() end
        local t = self.tip
        if type(t) == "function" then t = t(self) end
        if type(t) == "table" then S.Tip(self, t)
        elseif self.wlClamped then local cut = root.CutLines(self); if #cut > 0 then S.Tip(self, cut) end end
    end)
    b:SetScript("OnLeave", function(self)
        S.Tween(self, self.hov or 0, 0, 0.10, function(v) self.hov = v; self.hl:SetAlpha(v) end)
        if self.OnHover then self:OnHover(false) end
        S.HideTip()
    end)
    b:SetScript("OnMouseDown", function(self) self.press:Show() end)
    b:SetScript("OnMouseUp", function(self) self.press:Hide() end)
end

-- a painted game icon in a 1 px dark frame
local function Painted(parent, size)
    local fr = CreateFrame("Frame", nil, parent)
    fr:SetSize(size, size)
    S.Border(fr, C.cardEdge)
    fr.tex = fr:CreateTexture(nil, "ARTWORK"); fr.tex:SetAllPoints()
    return fr
end

-- a list in a scroll area (the bar shows only when the window reached its height cap):
-- l.Get(i), l.HideFrom(i), l.Top(y) (where the list starts in its page)
local function List(page, make)
    local sa = S.ScrollArea(page)
    sa:SetPoint("TOPLEFT", 0, 0); sa:SetPoint("BOTTOMRIGHT", 0, 0)
    sa.child:SetWidth(CW)
    local l = { sf = sa, content = sa.child, items = {} }
    function l.Get(i) local f = l.items[i]; if not f then f = make(sa.child); l.items[i] = f end; f:Show(); return f end
    function l.HideFrom(i) for j = i, #l.items do l.items[j]:Hide() end end
    function l.Top(y) sa:ClearAllPoints(); sa:SetPoint("TOPLEFT", 0, -y); sa:SetPoint("BOTTOMRIGHT", 0, 0) end
    function l.Reset() sa:ScrollTo(0, true) end
    return l
end

-- the window takes the page's height: its fixed top plus its list
local function Fit(page, list, listH)
    listH = math.max(0, math.ceil(listH or 0))
    local sa = list and (list.sf or list)
    if win then win:FitHeight((page.topH or 0) + listH) end
    if sa then sa:SetContentHeight(listH) end
end

-- a reading row (design system 3.9): painted icon 28 (or a class icon 20), name 13, detail 11
-- muted, up to two 24 px buttons at the right; the row itself is clickable
local function Row(parent)
    local r = CreateFrame("Button", nil, parent)
    r.wlOwned = true
    r.bg = S.Solid(r, "BACKGROUND", C.cardFill); r.bg:SetAllPoints()
    Feedback(r)
    r.iconFrame = Painted(r, 28); r.icon = r.iconFrame.tex
    r.cls = r:CreateTexture(nil, "ARTWORK"); r.cls:SetSize(20, 20); r.cls:Hide()
    r.name = S.Text(r, F.body, C.fg); r.name:SetJustifyH("LEFT"); r.name:SetJustifyV("TOP")
    r.detail = S.Text(r, F.meta, C.muted); r.detail:SetJustifyH("LEFT"); r.detail:SetJustifyV("TOP")
    r.sub = r.detail
    r.buttons = {}
    function r:Fit(width)
        self:SetWidth(width)
        local x = 8
        local iconW = self.iconFrame:IsShown() and 28 or (self.cls:IsShown() and 20 or 0)
        if iconW > 0 then
            self.iconFrame:ClearAllPoints(); self.iconFrame:SetPoint("LEFT", 8, 0)
            self.cls:ClearAllPoints(); self.cls:SetPoint("LEFT", 12, 0)
            x = 44
        end
        local right = 12
        for i = #self.buttons, 1, -1 do
            local b = self.buttons[i]
            if b:IsShown() then
                b:ClearAllPoints(); b:SetPoint("RIGHT", self, "RIGHT", -right, 0)
                right = right + (num(b:GetWidth()) or 80) + 8
            end
        end
        local textW = math.max(80, width - x - right)
        local nameH = S.FitText(self.name, 2, textW, self)
        local detH = 0
        if self.detail:IsShown() then detH = S.FitText(self.detail, 2, textW, self) end
        local block = nameH + (detH > 0 and (3 + detH) or 0)
        local h = math.max(44, math.ceil(6 + block + 8))
        local top = math.floor((h - block) / 2)
        self.name:ClearAllPoints(); self.name:SetPoint("TOPLEFT", x, -top)
        self.detail:ClearAllPoints(); self.detail:SetPoint("TOPLEFT", self.name, "BOTTOMLEFT", 0, -3)
        self:SetHeight(h)
        return h
    end
    return r
end

-- a button in a row: secondary, 24 high, as wide as its label
local function RowButton(row, label, onClick, tip)
    local b = S.Button(row, label, 0, 24, "secondary", onClick, tip)
    row.buttons[#row.buttons + 1] = b
    return b
end

-- the empty state of a list, placed at the top of its content; returns the height it takes
local function Empty(e, on, icon, title, text, label, click, kind)
    if not on then e:Hide(); return 0 end
    e:SetWrapWidth(CW)
    local h = e:Set(icon, title, text, label, click, kind or "primary")
    e:Show()
    return 24 + (h or 0) + 12
end

-- a section header in a list (design system 3.10)
local function Header(parent)
    local h = S.SectionHeader(parent, "")
    h:SetWidth(CW)
    return h
end

-- the reagent list as text: "5× Étoffe de mage, 2× Fil"
local function Reagents(s, qty)
    local t = {}
    for _, r in ipairs(O.Decode(s)) do t[#t + 1] = (r[2] * (qty or 1)) .. "× " .. Name(r[1]) end
    return table.concat(t, ", ")
end

-- ---------------------------------------------------------------- professions
-- One key per profession whatever the client's language, its name in yours and its icon.
local PROFS = {
    alchemy = { "Alchimie", "Alchemy", "Interface\\Icons\\Trade_Alchemy" },
    blacksmithing = { "Forge", "Blacksmithing", "Interface\\Icons\\Trade_BlackSmithing" },
    enchanting = { "Enchantement", "Enchanting", "Interface\\Icons\\Trade_Engraving" },
    engineering = { "Ingénierie", "Engineering", "Interface\\Icons\\Trade_Engineering" },
    leatherworking = { "Travail du cuir", "Leatherworking", "Interface\\Icons\\Trade_LeatherWorking" },
    tailoring = { "Couture", "Tailoring", "Interface\\Icons\\Trade_Tailoring" },
    herbalism = { "Herboristerie", "Herbalism", "Interface\\Icons\\Spell_Nature_NatureTouchGrow" },
    mining = { "Minage", "Mining", "Interface\\Icons\\Trade_Mining" },
    skinning = { "Dépeçage", "Skinning", "Interface\\Icons\\INV_Misc_Pelt_Wolf_01" },
    cooking = { "Cuisine", "Cooking", "Interface\\Icons\\INV_Misc_Food_15" },
    firstaid = { "Secourisme", "First Aid", "Interface\\Icons\\Spell_Holy_SealOfSacrifice" },
    fishing = { "Pêche", "Fishing", "Interface\\Icons\\Trade_Fishing" },
}
-- the search example of each profession's catalogue
local PROF_EXAMPLE = {
    alchemy = "Ex. Potion de soins", blacksmithing = "Ex. Plastron", tailoring = "Ex. Sac en étoffe",
    leatherworking = "Ex. Bottes", engineering = "Ex. Lunette", enchanting = "Ex. Bracelets",
    cooking = "Ex. Ragoût", firstaid = "Ex. Bandage", mining = "Ex. Barre",
}
local profByName
local function ProfKey(name)
    if not profByName then
        profByName = {}
        for k, p in pairs(PROFS) do profByName[p[1]:lower()], profByName[p[2]:lower()] = k, k end
    end
    return name and profByName[tostring(name):lower()] or nil
end
local function ProfLabel(key, raw) local p = PROFS[key]; return p and ((root.lang == "en") and p[2] or p[1]) or raw or "?" end
local function ProfIcon(key) local p = PROFS[key]; return p and p[3] or "Interface\\Icons\\INV_Misc_Note_01" end
-- a profession's icon inside a text, its edges cropped like the icons
local function ProfMarkup(key, size)
    size = size or 14
    return "|T" .. ProfIcon(key) .. ":" .. size .. ":" .. size .. ":0:-1:64:64:5:59:5:59|t"
end

-- shift-click an item while one of our item boxes (search, request) has the focus: its link goes in it
local function InsertLink(link)
    if type(link) ~= "string" then return end
    for _, box in ipairs({ ui.find.box or false, ui.find.cbox or false, ui.ask.box or false }) do
        if box and box:HasFocus() then box:SetText(link) end
    end
end
WP.OrdersInsertLink = InsertLink
if hooksecurefunc and ChatEdit_InsertLink then hooksecurefunc("ChatEdit_InsertLink", InsertLink) end

-- a member's row: the class icon and the class colour on the name
local function SetClass(row, name)
    local cls = name and O.ClassOf(name)
    row.iconFrame:Hide()
    if cls and S.ClassIcon(row.cls, cls) then row.cls:Show() else row.cls:Hide() end
    local cc = cls and RAID_CLASS_COLORS and RAID_CLASS_COLORS[cls]
    if cc then row.name:SetTextColor(cc.r, cc.g, cc.b) else row.name:SetTextColor(C.fg[1], C.fg[2], C.fg[3]) end
end
local function SetItem(row, tex, id)
    row.cls:Hide(); row.iconFrame:Show(); S.Painted(row.icon, tex)
    local qc = (id and id > 0) and S.QualityColor(id) or C.fg
    row.name:SetTextColor(qc[1], qc[2], qc[3])
    return qc
end
local function Stars(name)
    local n = name and O.Stars(name) or 0
    return n > 0 and (" " .. STAR .. S.Hex(C.gold) .. n .. "|r") or ""
end
local function StarLine(name)
    local n = name and O.Stars(name) or 0
    if n == 0 then return nil end
    return n == 1 and L("1 étoile reçue pour une commande livrée") or string.format(L("%d étoiles reçues pour des commandes livrées"), n)
end

-- ---------------------------------------------------------------- the guild's crafts
local GRID_PROFS = { "alchemy", "blacksmithing", "tailoring", "leatherworking", "engineering", "enchanting", "cooking", "firstaid", "mining" }
local GRID_COLS, GRID_GAP = 4, 12
local CAT_MAX = 200   -- catalogue rows drawn at most (the search narrows the rest)

-- The guild's crafts by profession, read once per render:
-- [key] = { crafters = { c }, items = { [id] = { id, re, who = { c }, online } }, nItems, nOnline, unshared = { names } }
-- c = { name, prof, rank, online, me, n = recipes shared, stars }
local function GuildCrafts()
    local on = O.OnlineGuild()
    local me = UnitName("player")
    local out = {}
    local function Add(name, prof, p, mine)
        local key = ProfKey(prof)
        if not key or type(p) ~= "table" then return end
        local isMe = mine or name == me
        local e = out[key]
        if not e then e = { key = key, crafters = {}, byName = {}, items = {}, nItems = 0, nOnline = 0, unshared = {} }; out[key] = e end
        local c = e.byName[name]
        if not c then
            c = { name = name, prof = prof, rank = p.rank or 0, online = (isMe or on[name]) and true or false, me = isMe or nil, n = 0,
                stars = isMe and 0 or O.Stars(name) }
            e.byName[name] = c; e.crafters[#e.crafters + 1] = c
            if c.online and not c.me then e.nOnline = e.nOnline + 1 end
        elseif (p.rank or 0) > c.rank then c.rank, c.prof = p.rank, prof end
        for id, re in pairs(p.recipes or {}) do
            local it = e.items[id]
            if not it then it = { id = id, re = re, who = {}, by = {} }; e.items[id] = it; e.nItems = e.nItems + 1 end
            if not it.by[name] then
                it.by[name] = true; it.who[#it.who + 1] = c; c.n = c.n + 1
                if c.online and not c.me then it.online = true end
            end
        end
    end
    for name, profs in pairs(O.DB().crafters) do
        if type(profs) == "table" then for prof, p in pairs(profs) do Add(name, prof, p) end end
    end
    for prof, p in pairs(O.DB().mine or {}) do Add(me, prof, p, true) end
    for _, e in pairs(out) do
        for _, c in ipairs(e.crafters) do
            if c.n == 0 then
                if c.me then e.meUnshared = true else e.unshared[#e.unshared + 1] = c.name end
            end
        end
        table.sort(e.unshared)
    end
    return out
end

-- crafters: online first (others before you), then stars, rank, name
local function ByCrafter(a, b)
    if a.online ~= b.online then return a.online end
    if (a.me or false) ~= (b.me or false) then return not a.me end
    if a.stars ~= b.stars then return a.stars > b.stars end
    if a.rank ~= b.rank then return a.rank > b.rank end
    return a.name < b.name
end
local function CrafterName(c)
    local n = c.me and L("toi") or c.name
    if c.online and not c.me then n = S.Hex(C.ok) .. n .. "|r" end
    if c.stars > 0 then n = n .. " " .. STAR .. S.Hex(C.gold) .. c.stars .. "|r" end
    return n
end
-- "Mylla, Grok +2"
local function WhoText(who, max)
    local t = {}
    for i = 1, math.min(#who, max) do t[i] = CrafterName(who[i]) end
    local s = table.concat(t, ", ")
    if #who > max then s = s .. " " .. S.Hex(C.muted) .. "+" .. (#who - max) .. "|r" end
    return s
end
local function Where(online, seen)
    if online then return S.Hex(C.ok) .. L("en ligne") .. "|r" end
    if seen then
        local d = math.floor((time() - seen) / 86400)
        if d == 1 then return L("vu hier") end
        if d > 30 then return L("vu il y a plus d'un mois") end
        if d > 1 then return string.format(L("vu il y a %d jours"), d) end
    end
    return L("hors ligne")
end

-- an item's icon, or an enchant's (a negative spell ID)
local function ItemTex(id)
    if id > 0 then return S.ItemIcon(id) end
    return ((C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(-id)) or (GetSpellTexture and GetSpellTexture(-id)))
        or "Interface\\Icons\\Trade_Engraving"
end
-- the level an item asks for, when the game knows it (nil below 2)
local function ReqLevel(id)
    if id <= 0 then return nil end
    local info = (C_Item and C_Item.GetItemInfo) or GetItemInfo
    if not info then return nil end
    local ok, _, _, _, _, minLevel = pcall(info, id)
    return ok and type(minLevel) == "number" and minLevel > 1 and minLevel or nil
end
-- an item's tooltip: name, level, every reagent on its own line, who makes it, what a click does
-- (a click orders from the whole guild, shift-click from the best crafter only)
local function ItemTip(id, re, who, best)
    local qc = id > 0 and S.QualityColor(id) or C.fg
    local tip = { S.Hex(qc) .. Name(id) .. "|r" }
    local lvl = ReqLevel(id)
    if lvl then tip[#tip + 1] = string.format(L("Niveau %d requis"), lvl) end
    local rg = O.Decode(re or "")
    if #rg == 0 then tip[#tip + 1] = L("Composants inconnus") end
    for _, r in ipairs(rg) do tip[#tip + 1] = r[2] .. "× " .. Name(r[1]) end
    if who and #who > 0 then
        local all = {}
        for _, c in ipairs(who) do all[#all + 1] = CrafterName(c) end
        tip[#tip + 1] = string.format(L("Peuvent le fabriquer : %s"), table.concat(all, ", "))
    end
    tip[#tip + 1] = L("Clic : commander à toute la guilde (le premier artisan qui accepte s'en charge)")
    if best then tip[#tip + 1] = string.format(L("Maj-clic : commander à %s seulement"), best) end
    return tip
end

-- ---------------------------------------------------------------- the catalogue's categories
-- Grouped like a profession window: the item's class (weapons, armour, bags...), then its slot
-- (armour) or its subclass (the rest); enchants (negative spell IDs) by the slot their name names.
-- Inside a group: required level, then quality (best first), then name.
local CLASS_GROUP = {   -- classID = { group key, order, label }
    [2] = { "weapon", 1, "Armes" }, [4] = { "armor", 2, "Armure" }, [1] = { "bag", 3, "Sacs" }, [11] = { "bag", 3, "Sacs" },
    [0] = { "consumable", 4, "Consommables" }, [3] = { "gem", 5, "Gemmes" }, [7] = { "reagent", 6, "Composants" },
    [5] = { "reagent", 6, "Composants" }, [6] = { "ammo", 7, "Munitions" }, [9] = { "recipe", 9, "Recettes" },
    [15] = { "misc", 10, "Divers" },
}
local ENCHANT_ORDER, OTHER_ORDER = 8, 99
local SLOT_ORDER = {}
for i, s in ipairs({ "INVTYPE_HEAD", "INVTYPE_NECK", "INVTYPE_SHOULDER", "INVTYPE_CLOAK", "INVTYPE_CHEST", "INVTYPE_BODY",
    "INVTYPE_TABARD", "INVTYPE_WRIST", "INVTYPE_HAND", "INVTYPE_WAIST", "INVTYPE_LEGS", "INVTYPE_FEET", "INVTYPE_FINGER",
    "INVTYPE_TRINKET", "INVTYPE_HOLDABLE" }) do SLOT_ORDER[s] = i end
local SLOT_SAME = { INVTYPE_ROBE = "INVTYPE_CHEST" }
local catCache = {}   -- [id] = { top, order, label, sub, subOrder, subLabel }: what the class says never changes

local function SubClassName(classID, subID)
    local f = (C_Item and C_Item.GetItemSubClassInfo) or GetItemSubClassInfo
    if not (f and classID and subID) then return nil end
    local ok, n = pcall(f, classID, subID)
    return ok and type(n) == "string" and n ~= "" and n or nil
end
-- "Enchant Bracer - Minor Health" / "Enchantement de bracelets - Vie mineure": "Bracer" / "Bracelets"
local function EnchantSlot(name)
    local head = type(name) == "string" and name:match("^(.-)%s+%-%s+")
    if not head then return nil end
    head = head:gsub("^[Ee]nchantement%s+d[e']%s*", ""):gsub("^[Ee]nchantement%s+", ""):gsub("^[Ee]nchanter%s+", "")
        :gsub("^[Ee]nchant%s+", ""):gsub("^%s+", ""):gsub("%s+$", "")
    if head == "" or head:find("item:", 1, true) then return nil end
    return (head:gsub("^%l", string.upper))
end
local function CatOf(id, name)
    local c = catCache[id]
    if c then return c end
    if id < 0 then
        local slot = EnchantSlot(name)
        -- an enchant's name may not be known yet: only a found slot is kept
        c = { "enchant", ENCHANT_ORDER, L("Enchantements"), slot and slot:lower() or "other", slot and 1 or 99, slot or L("Autres") }
        if slot then catCache[id] = c end
        return c
    end
    local instant = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
    local classID, subID, equipLoc
    if instant then
        local ok, iid, _, _, loc, _, cls, sub = pcall(instant, id)
        if ok and iid then classID, subID, equipLoc = cls, sub, loc end
    end
    local g = classID and CLASS_GROUP[classID]
    if not classID then return { "other", OTHER_ORDER, L("Autres"), "other", 99, L("Autres") } end
    local top, order, label
    if g then top, order, label = g[1], g[2], L(g[3])
    else
        local cf = (C_Item and C_Item.GetItemClassInfo) or GetItemClassInfo
        local ok, n = false, nil
        if cf then ok, n = pcall(cf, classID) end
        top, order, label = "class" .. classID, 20, (ok and type(n) == "string" and n ~= "") and n or L("Autres")
    end
    local sub, subOrder, subLabel
    if classID == 4 and subID ~= 6 and type(equipLoc) == "string" and equipLoc ~= "" then
        local loc = SLOT_SAME[equipLoc] or equipLoc
        local sl = _G[loc]
        if type(sl) == "string" and sl ~= "" then sub, subOrder, subLabel = loc, SLOT_ORDER[loc] or 50, sl end
    end
    if not sub then
        local sn = SubClassName(classID, subID)
        if sn then sub, subOrder, subLabel = "s" .. classID .. "." .. tostring(subID), (classID == 4 and subID == 6) and 60 or 50, sn
        else sub, subOrder, subLabel = "other", 99, L("Autres") end
    end
    -- [7]: an armour piece's subclass ("Mailles"), told apart in a slot shared by several
    c = { top, order, label, sub, subOrder, subLabel, (classID == 4 and sub ~= nil and sub:sub(1, 1) ~= "s") and SubClassName(classID, subID) or nil }
    catCache[id] = c
    return c
end
-- an item's level asked and quality, when the game has it cached (0 / -1 meanwhile)
local function LevelQuality(id)
    if id <= 0 then return 0, -1 end
    local info = (C_Item and C_Item.GetItemInfo) or GetItemInfo
    if not info then return 0, -1 end
    local ok, n, _, q, _, minLevel = pcall(info, id)
    if not ok or not n then return 0, -1 end
    return type(minLevel) == "number" and minLevel or 0, type(q) == "number" and q or -1
end
-- the items in their groups: { { key, label, n, subs = { { key, label, n, items } } } }, sorted
local function Group(items)
    local tops, byTop = {}, {}
    for _, it in ipairs(items) do
        local c = CatOf(it.id, it.name)
        it.lvl, it.q = LevelQuality(it.id)
        it.kind = c[7]
        local t = byTop[c[1]]
        if not t then
            t = { key = c[1], order = c[2], label = c[3], n = 0, subs = {}, bySub = {} }
            byTop[c[1]] = t; tops[#tops + 1] = t
        end
        local s = t.bySub[c[4]]
        if not s then
            s = { key = c[1] .. "/" .. c[4], order = c[5], label = c[6], items = {} }
            t.bySub[c[4]] = s; t.subs[#t.subs + 1] = s
        end
        s.items[#s.items + 1] = it
        if it.kind then
            if s.kind == nil then s.kind = it.kind elseif s.kind ~= it.kind then s.mixed = true end
        end
        t.n = t.n + 1
    end
    local function ByOrder(a, b) if a.order ~= b.order then return a.order < b.order end return a.label < b.label end
    -- a level not known yet (item info still on its way) sorts last, so known rows keep their place
    local function Lvl(it) return (it.q == -1 and it.lvl == 0) and math.huge or it.lvl end
    local function ByItem(a, b)
        local la, lb = Lvl(a), Lvl(b)
        if la ~= lb then return la < lb end
        if a.q ~= b.q then return a.q > b.q end
        if a.name ~= b.name then return a.name < b.name end
        return a.id < b.id
    end
    table.sort(tops, ByOrder)
    for _, t in ipairs(tops) do
        table.sort(t.subs, ByOrder)
        for _, s in ipairs(t.subs) do table.sort(s.items, ByItem) end
    end
    return tops
end
-- the folded groups of a profession's catalogue, kept between sessions
local function Folds(prof)
    WLWritsDB.ordersFold = type(WLWritsDB.ordersFold) == "table" and WLWritsDB.ordersFold or {}
    local t = WLWritsDB.ordersFold[prof]
    if type(t) ~= "table" then t = {}; WLWritsDB.ordersFold[prof] = t end
    return t
end

-- a category head of the catalogue: chevron, label, count, the rule under it; a click folds it.
-- sub: a slot or subclass inside a group (24 high, indented, label 12 text)
local function CatHead(parent, sub)
    local b = CreateFrame("Button", nil, parent)
    b.wlOwned = true
    b.sub = sub
    b:SetHeight(sub and 24 or 32); b:SetWidth(CW - (sub and 12 or 0))
    b.hl = S.Solid(b, "BACKGROUND", C.hoverFill); b.hl:SetAllPoints(); b.hl:SetAlpha(0)
    b.chev = S.Icon(b, "chevron_down", 12, "ARTWORK", C.muted)
    b.label = sub and S.Text(b, F.label, C.text) or S.Text(b, F.body, C.fg); b.label:SetWordWrap(false)
    S.ClampLabel(b.label, nil, b)
    b.chev:SetPoint("BOTTOMLEFT", 0, sub and 6 or 8)
    b.label:SetPoint("BOTTOMLEFT", 18, sub and 5 or 6)
    b.count = S.Text(b, F.meta, C.muted); b.count:SetWordWrap(false)
    b.count:SetPoint("BOTTOMLEFT", b.label, "BOTTOMRIGHT", 6, 0)
    b.rule = S.Rule(b); b.rule:SetPoint("BOTTOMLEFT"); b.rule:SetPoint("BOTTOMRIGHT")
    b:SetScript("OnClick", function(self) if self.foldable and self.onFold then self.onFold(self) end end)
    b:SetScript("OnEnter", function(self)
        if not self.foldable then return end
        self.hl:SetAlpha(1); self.chev:SetVertexColor(C.fg[1], C.fg[2], C.fg[3])
        S.Tip(self, { self.label:GetText(), self.folded and L("Clic : déplier la catégorie") or L("Clic : replier la catégorie") })
    end)
    b:SetScript("OnLeave", function(self) self.hl:SetAlpha(0); self.chev:SetVertexColor(C.muted[1], C.muted[2], C.muted[3]); S.HideTip() end)
    function b:Set(text, n, foldable, folded)
        self.foldable, self.folded = foldable, folded
        local indent = self.sub and 12 or 0
        S.HDIcon(self.chev, folded and "chevron_right" or "chevron_down", C.muted)
        self.label:SetText(text or "")
        self.count:SetText(n or ""); self.count:SetShown(n ~= nil)
        local ok, w = pcall(self.label.GetStringWidth, self.label)
        self.label:SetWidth(math.max(40, math.min(math.ceil((ok and num(w)) or 100) + 1, CW - indent - 18 - 48)))
    end
    return b
end

-- ---------------------------------------------------------------- page: crafters
local function BuildFind(p)
    local f = ui.find
    -- the item search, on top of the grid and of the results
    f.box = S.Input(p, CW, { search = true, placeholder = L("Ex. Sac en étoffe runique, ou Maj-clic sur un objet") })
    f.box:SetPoint("TOPLEFT", 0, 0)
    -- a real query typed here wins over a crafter's view or a catalogue
    f.box:HookScript("OnTextChanged", function(self)
        local t = ((self:GetText() or ""):gsub("^%s+", ""):gsub("%s+$", ""))
        if #t >= 2 or t:match("item:%d+") then f.view, f.prof = nil, nil end
        WP.RefreshOrders()
    end)
    -- out of a crafter's recipes: back to the profession's catalogue, or to the grid
    f.back = S.Button(p, L("Tous les métiers"), 0, 24, "ghost", function()
        f.view = nil; f.list.Reset(); WP.RefreshOrders()
    end, function()
        return { f.back:GetText(), f.prof and string.format(L("Clic : revenir au catalogue %s"), ProfLabel(f.prof)) or L("Clic : revenir à la liste des métiers") }
    end)
    f.back:SetIcon("chevron_left")
    f.back:SetPoint("TOPLEFT", 0, -36); f.back:Hide()

    -- the result list (search, a linked item, a crafter's recipes)
    f.list = List(p, function(parent)
        local r = Row(parent)
        r.btn = RowButton(r, L("Commander"), function()
            if r.item then WP.NewOrder(r.item, r.crafter)
            elseif r.open then ui.find.view = r.open; f.list.Reset(); WP.RefreshOrders() end
        end, function() return r.btnTip or { r.btn:GetText() } end)
        -- on a crafter's recipe, shift-click asks the whole guild for it (the Request form filled in)
        r:SetScript("OnClick", function(self)
            if self.askProf and self.item and IsShiftKeyDown and IsShiftKeyDown() and WP.AskOrder then WP.AskOrder(self.item, self.askProf); return end
            if self.btn:IsShown() then self.btn:Click() end
        end)
        return r
    end)
    f.empty = S.EmptyState(f.list.content, "search", "", nil, nil, nil)
    f.listHead = Header(f.list.content)

    -- the grid: one tile per profession
    f.grid = List(p, function(parent)
        local t = CreateFrame("Button", nil, parent)
        t.wlOwned = true
        S.Solid(t, "BACKGROUND", C.cardFill):SetAllPoints()
        S.Border(t, C.cardEdge)
        Feedback(t)
        t.iconFrame = Painted(t, 32); t.icon = t.iconFrame.tex
        t.iconFrame:SetPoint("TOP", 0, -12)
        t.name = S.Text(t, F.body, C.fg); t.name:SetJustifyH("CENTER"); t.name:SetJustifyV("TOP")
        t.count = S.Text(t, F.meta, C.muted); t.count:SetJustifyH("CENTER"); t.count:SetJustifyV("TOP")
        t.online = S.Text(t, F.meta, C.ok); t.online:SetJustifyH("CENTER"); t.online:SetJustifyV("TOP")
        t:SetScript("OnClick", function(self)
            -- empty the box before f.prof is set: its hook then renders nothing, one render below
            if (f.cbox:GetText() or "") ~= "" then f.cbox:SetText("") end
            f.prof, f.view = self.key, nil
            f.cat.Reset()
            WP.RefreshOrders()
        end)
        return t
    end)
    f.gridEmpty = S.EmptyState(f.grid.content, "hammer", "", nil, nil, nil)
    -- sharing my recipes (on by default): a settings row under the grid, with what was read of mine
    local sh = CreateFrame("Button", nil, f.grid.content)
    sh.wlOwned = true
    S.Solid(sh, "BACKGROUND", C.cardFill):SetAllPoints(); S.Border(sh, C.cardEdge)
    sh.label = S.Text(sh, F.body, C.fg); sh.label:SetPoint("TOPLEFT", 12, -12); sh.label:SetText(L("Partager mes recettes"))
    S.ClampLabel(sh.label, nil, sh)
    sh.desc = S.Text(sh, F.meta, C.muted); sh.desc:SetJustifyH("LEFT"); sh.desc:SetJustifyV("TOP")
    sh.desc:SetPoint("TOPLEFT", sh.label, "BOTTOMLEFT", 0, -3)
    sh.switch = S.Switch(sh, function() return WLWritsDB.ordersShare ~= false end,
        function(v) WLWritsDB.ordersShare = v; if v then O.Announce() end; WP.RefreshOrders() end)
    sh.switch:SetPoint("RIGHT", -12, 0)
    sh.switch:AttachRow(sh)
    f.share = sh

    -- a profession's catalogue: back, online filter, the profession, its search
    local h = CreateFrame("Frame", nil, p)
    h:SetPoint("TOPLEFT"); h:SetPoint("TOPRIGHT"); h:SetHeight(108); h:Hide()
    f.chead = h
    f.cback = S.Button(h, L("Tous les métiers"), 0, 24, "ghost", function()
        f.prof, f.view = nil, nil
        f.grid.Reset()
        WP.RefreshOrders()
    end, { L("Tous les métiers"), L("Clic : revenir à la liste des métiers") })
    f.cback:SetIcon("chevron_left")
    f.cback:SetPoint("TOPLEFT", 0, 0)
    local ol = CreateFrame("Button", nil, h)
    ol:SetHeight(24); ol:SetPoint("TOPRIGHT", 0, 0)
    f.conline = S.Switch(ol, function() return f.onlineOnly end, function(v) f.onlineOnly = v and true or false; WP.RefreshOrders() end,
        { L("En ligne seulement"), L("Seulement les objets qu'un artisan en ligne peut fabriquer") })
    f.conline:SetPoint("RIGHT", 0, 0)
    ol.label = S.Text(ol, F.label, C.text); ol.label:SetPoint("RIGHT", f.conline, "LEFT", -8, 0); ol.label:SetText(L("En ligne seulement"))
    S.ClampLabel(ol.label, nil, ol)
    local okW, lw = pcall(ol.label.GetStringWidth, ol.label)
    ol:SetWidth(40 + 8 + math.ceil((okW and num(lw)) or 100))
    f.conline:AttachRow(ol)
    f.cicon = Painted(h, 32); f.cicon:SetPoint("TOPLEFT", 0, -36)
    f.ctitle = S.Text(h, F.heading, C.fg); f.ctitle:SetPoint("TOPLEFT", f.cicon, "TOPRIGHT", 8, 0)
    f.ctitle:SetWidth(CW - 40); S.ClampLabel(f.ctitle, nil, h)
    f.ccount = S.Text(h, F.meta, C.muted); f.ccount:SetPoint("TOPLEFT", f.ctitle, "BOTTOMLEFT", 0, -3)
    f.ccount:SetWidth(CW - 40); S.ClampLabel(f.ccount, nil, h)
    f.cbox = S.Input(h, CW, { search = true, placeholder = L("Ex. Potion de soins") })
    f.cbox:SetPoint("TOPLEFT", 0, -80)
    f.cbox:HookScript("OnTextChanged", function() if f.prof then WP.RefreshOrders() end end)

    -- the catalogue's rows: an item (who makes it, Request), or a crafter (Recipes)
    -- the row does what its button does: an item opens the order form for the whole guild (the
    -- first crafter who accepts takes it), shift-click for its best crafter only; a crafter, his recipes
    local function Act(r)
        if r.kind == "item" then
            local shift = IsShiftKeyDown and IsShiftKeyDown()
            WP.NewOrder(r.item, (shift and r.crafter) or nil)
        elseif r.kind == "crafter" and r.open then f.view = r.open; f.list.Reset(); WP.RefreshOrders() end
    end
    f.cat = List(p, function(parent)
        local r = Row(parent)
        r.who = r.detail
        r.btn = RowButton(r, L("Commander"), function() Act(r) end, function() return r.btnTip or { r.btn:GetText() } end)
        r:SetScript("OnClick", Act)
        return r
    end)
    -- the category heads (a group, a slot or subclass inside it): a click folds it, kept per profession
    local function Fold(hd)
        if not (f.prof and hd.foldKey) then return end
        local t = Folds(f.prof)
        t[hd.foldKey] = (not t[hd.foldKey]) or nil
        WP.RefreshOrders()
    end
    f.catHeads, f.catSubs = {}, {}
    function f.CatHeadGet(i, sub)
        local pool = sub and f.catSubs or f.catHeads
        local h = pool[i]
        if not h then h = CatHead(f.cat.content, sub); h.onFold = Fold; pool[i] = h end
        h:Show()
        return h
    end
    function f.CatHeadsHideFrom(i, sub)
        local pool = sub and f.catSubs or f.catHeads
        for j = i, #pool do pool[j]:Hide() end
    end
    f.catEmpty = S.EmptyState(f.cat.content, "search", "", nil, nil, nil)
    f.catHead = Header(f.cat.content)
    f.catNote = S.Text(f.cat.content, F.meta, C.muted)
    f.catNote:SetJustifyH("LEFT"); f.catNote:SetJustifyV("TOP"); f.catNote:Hide()
    f.catMore = S.Text(f.cat.content, F.meta, C.muted)
    f.catMore:SetJustifyH("LEFT"); f.catMore:SetJustifyV("TOP"); f.catMore:Hide()
end

-- which of the page's areas shows: the result list, the grid, or a catalogue; and where it starts
local function SetMode(f, mode)
    local p = pages.find
    f.list.sf:SetShown(mode == "list"); f.grid.sf:SetShown(mode == "grid"); f.cat.sf:SetShown(mode == "cat")
    local cat = mode == "cat"
    f.chead:SetShown(cat); f.box:SetShown(not cat)
    f.back:SetShown(mode == "list" and f.view ~= nil)
    p.topH = cat and 120 or (f.back:IsShown() and (28 + 8 + 24 + 12) or (28 + 12))
    local l = mode == "list" and f.list or (mode == "grid" and f.grid or f.cat)
    l.Top(p.topH)
    return l
end

local function RenderGrid(f, g)
    local keys = {}
    for _, k in ipairs(GRID_PROFS) do
        if k ~= "mining" or (g.mining and g.mining.nItems > 0) then keys[#keys + 1] = k end
    end
    local anyone = false
    for _, key in ipairs(keys) do if g[key] and #g[key].crafters > 0 then anyone = true end end
    local tw = math.floor((CW - GRID_GAP * (GRID_COLS - 1)) / GRID_COLS)
    local th = 0
    if anyone then
        for i, key in ipairs(keys) do
            local e = g[key]
            local nC, nI, nO = e and #e.crafters or 0, e and e.nItems or 0, e and e.nOnline or 0
            local t = f.grid.Get(i)
            t.key = key
            S.Painted(t.icon, ProfIcon(key)); t.icon:SetDesaturated(nC == 0); t.icon:SetAlpha(nC == 0 and 0.5 or 1)
            t.name:SetText(ProfLabel(key))
            local nc = nC > 0 and C.fg or C.muted
            t.name:SetTextColor(nc[1], nc[2], nc[3])
            local counts = nC == 0 and L("Aucun artisan") or (P(nC, L("1 artisan"), L("%d artisans")) .. " · " .. P(nI, L("1 objet"), L("%d objets")))
            t.count:SetText(counts)
            local onNames = {}
            if e then
                table.sort(e.crafters, ByCrafter)
                for _, c in ipairs(e.crafters) do if c.online and not c.me then onNames[#onNames + 1] = c.name end end
            end
            if nO > 0 then
                t.online:SetText(P(nO, L("1 en ligne"), L("%d en ligne"))); t.online:SetTextColor(C.ok[1], C.ok[2], C.ok[3])
            else
                t.online:SetText(nC > 0 and L("Personne en ligne") or ""); t.online:SetTextColor(C.muted[1], C.muted[2], C.muted[3])
            end
            t.online:SetShown(nC > 0)
            t.tip = { ProfLabel(key), counts }
            if #onNames > 0 then t.tip[#t.tip + 1] = string.format(L("En ligne : %s"), table.concat(onNames, ", ")) end
            t.tip[#t.tip + 1] = L("Clic : ouvrir le catalogue du métier")
            -- every text wraps inside the tile; the tallest tile sets the row height
            local y = 12 + 32 + 8
            t.name:ClearAllPoints(); t.name:SetPoint("TOP", 0, -y)
            y = y + S.FitText(t.name, 2, tw - 16, t) + 3
            t.count:ClearAllPoints(); t.count:SetPoint("TOP", 0, -y)
            y = y + S.FitText(t.count, 2, tw - 16, t)
            if t.online:IsShown() then
                y = y + 3
                t.online:ClearAllPoints(); t.online:SetPoint("TOP", 0, -y)
                y = y + S.FitText(t.online, 2, tw - 16, t)
            end
            y = y + 12
            if y > th then th = y end
        end
        th = math.max(108, math.ceil(th))
        for i = 1, #keys do
            local t = f.grid.Get(i)
            local col, row = (i - 1) % GRID_COLS, math.floor((i - 1) / GRID_COLS)
            t:SetSize(tw, th); t:ClearAllPoints(); t:SetPoint("TOPLEFT", col * (tw + GRID_GAP), -row * (th + GRID_GAP))
        end
        f.grid.HideFrom(#keys + 1)
    else
        f.grid.HideFrom(1)
    end
    local y = anyone and (math.ceil(#keys / GRID_COLS) * (th + GRID_GAP) - GRID_GAP) or 0
    y = y + Empty(f.gridEmpty, not anyone, "hammer", L("Aucun artisan connu"),
        L("Les membres qui ont WL Helper partagent leurs métiers en se connectant."),
        L("Faire une demande"), function() WP.ShowOrdersTab("ask") end)
    -- your own professions, as this copy read them, and the sharing switch
    local sh = f.share
    if anyone then
        local mineT, noRecipe = {}, true
        for prof, pr in pairs(O.DB().mine or {}) do
            local n = 0
            for _ in pairs(pr.recipes or {}) do n = n + 1 end
            if n > 0 then noRecipe = false end
            mineT[#mineT + 1] = string.format(L("%s %d : %s"), ProfLabel(ProfKey(prof), prof), pr.rank or 0,
                n > 0 and P(n, L("1 recette"), L("%d recettes")) or L("pas encore lues"))
        end
        table.sort(mineT)
        local desc
        if #mineT == 0 then desc = L("Tu n'as pas encore de métier lu par l'addon. Ouvre ta fenêtre de métier une fois.")
        else
            desc = table.concat(mineT, " · ") .. ". "
            if noRecipe then desc = desc .. L("Ouvre ta fenêtre de métier une fois pour les partager.")
            elseif WLWritsDB.ordersShare ~= false then desc = desc .. L("Les autres membres voient ce que tu sais fabriquer et peuvent te commander.")
            else desc = desc .. L("Tes recettes restent sur ton ordinateur.") end
        end
        sh.desc:SetText(desc)
        sh.switch:Update()
        sh:SetWidth(CW)
        local dh = S.FitText(sh.desc, 0, CW - 12 - 40 - 12 - 12, sh)
        local hh = math.max(44, math.ceil(12 + F.body + 3 + dh + 12))
        sh:SetHeight(hh)
        sh:ClearAllPoints(); sh:SetPoint("TOPLEFT", 0, -(y + 16))
        sh:Show()
        y = y + 16 + hh
    else sh:Hide() end
    f.grid.content:SetHeight(math.max(1, y))
    return y
end

local function RenderCatalog(f, g)
    local key = f.prof
    local e = g[key] or { crafters = {}, items = {}, nItems = 0, nOnline = 0, unshared = {} }
    S.Painted(f.cicon.tex, ProfIcon(key))
    f.ctitle:SetText(ProfLabel(key))
    local counts = (#e.crafters == 0 and L("Aucun artisan") or P(#e.crafters, L("1 artisan"), L("%d artisans")))
        .. " · " .. P(e.nItems, L("1 objet"), L("%d objets"))
    if e.nOnline > 0 then counts = counts .. " · " .. S.Hex(C.ok) .. P(e.nOnline, L("1 en ligne"), L("%d en ligne")) .. "|r" end
    f.ccount:SetText(counts)
    f.conline:Update()
    f.cbox:SetPlaceholder(L(PROF_EXAMPLE[key] or "Ex. Potion de soins"))
    local raw = ((f.cbox:GetText() or ""):gsub("^%s+", ""):gsub("%s+$", ""))
    local linked = tonumber(raw:match("item:(%d+)"))
    local q = linked and "" or raw:lower()
    local filtered = q ~= "" or linked ~= nil or f.onlineOnly
    -- the matching items, names read once each
    local items = {}
    for id, it in pairs(e.items) do
        if not f.onlineOnly or it.online then
            if linked then
                if id == linked then it.name = Name(id); items[#items + 1] = it end
            else
                local n = Name(id)
                if q == "" or n:lower():find(q, 1, true) then it.name = n; items[#items + 1] = it end
            end
        end
    end
    local y, i = 0, 0
    if #items == 0 then
        if e.nItems == 0 then
            y = Empty(f.catEmpty, true, "hammer", L("Aucune recette partagée"),
                L("Les recettes arrivent quand les artisans de ce métier ouvrent leur fenêtre de métier."),
                L("Faire une demande"), function() WP.AskOrder(nil, PROFS[key] and PROFS[key][2]) end)
        elseif f.onlineOnly then
            y = Empty(f.catEmpty, true, "search", L("Aucun objet trouvé"), L("Aucun artisan en ligne ne fabrique ce que tu cherches."),
                L("Voir aussi hors ligne"), function() f.onlineOnly = false; WP.RefreshOrders() end, "secondary")
        else
            y = Empty(f.catEmpty, true, "search", L("Aucun objet trouvé"), L("Personne n'a partagé de recette qui correspond à ce nom."),
                L("Faire une demande"), function() WP.AskOrder(nil, PROFS[key] and PROFS[key][2]) end)
        end
    else f.catEmpty:Hide() end
    -- the items by category, like a profession window: a search opens every category it matches
    local folds = Folds(key)
    local searching = q ~= "" or linked ~= nil
    local nh, ns, drawn = 0, 0, 0
    local function Item(it, mixed)
        i = i + 1
        local r = f.cat.Get(i)
        r.kind, r.item, r.prof, r.open = "item", it.id, key, nil
        table.sort(it.who, ByCrafter)
        local best
        for _, c in ipairs(it.who) do if not c.me then best = c; break end end
        r.crafter = best and best.name or nil
        SetItem(r, ItemTex(it.id), it.id)
        r.name:SetText(it.name)
        local lvl = (it.lvl or 0) > 1 and (S.Hex(C.text) .. string.format(L("Niv. %d"), it.lvl) .. "|r") or ""
        if mixed and it.kind then lvl = lvl .. (lvl ~= "" and " · " or "") .. it.kind end
        if lvl ~= "" then lvl = lvl .. "  " end
        r.detail:SetText(lvl .. S.IconMarkup("user", 12, C.muted) .. " " .. WhoText(it.who, 3)); r.detail:Show()
        r.btn:SetText(L("Commander")); r.btn:Show()
        r.btnTip = { L("Commander"), L("Clic : commander à toute la guilde (le premier artisan qui accepte s'en charge)") }
        if r.crafter then r.btnTip[3] = string.format(L("Maj-clic : commander à %s seulement"), r.crafter) end
        -- the reagents and every crafter go in the tooltip, built on hover only
        local id, re, who, crafter = it.id, it.re, it.who, r.crafter
        r.tip = function() return ItemTip(id, re, who, crafter) end
        r.tipFill = nil
        local rh = r:Fit(CW)
        r:ClearAllPoints(); r:SetPoint("TOPLEFT", 0, -y)
        y = y + rh + 2
    end
    local groups = #items > 0 and Group(items) or {}
    local cut = false
    for gi, g in ipairs(groups) do
        if drawn >= CAT_MAX then cut = true; break end
        nh = nh + 1
        local hd = f.CatHeadGet(nh, false)
        local folded = (not searching) and folds[g.key] == true
        hd.foldKey = g.key
        hd:Set(g.label, g.n, not searching, folded)
        if gi > 1 then y = y + 8 end
        hd:ClearAllPoints(); hd:SetPoint("TOPLEFT", 0, -y)
        y = y + 32 + 4
        if not folded then
            local showSubs = #g.subs > 1
            for _, s in ipairs(g.subs) do
                if drawn >= CAT_MAX then cut = true; break end
                local sfolded = false
                if showSubs then
                    ns = ns + 1
                    local sh = f.CatHeadGet(ns, true)
                    sfolded = (not searching) and folds[s.key] == true
                    sh.foldKey = s.key
                    sh:Set(s.label, #s.items, not searching, sfolded)
                    sh:ClearAllPoints(); sh:SetPoint("TOPLEFT", 12, -y)
                    y = y + 24 + 4
                end
                if not sfolded then
                    for _, it in ipairs(s.items) do
                        if drawn >= CAT_MAX then cut = true; break end
                        drawn = drawn + 1
                        Item(it, s.mixed)
                    end
                end
            end
        end
    end
    f.CatHeadsHideFrom(nh + 1, false); f.CatHeadsHideFrom(ns + 1, true)
    -- the list was cut at CAT_MAX: say so
    if cut then
        f.catMore:SetText(string.format(L("Affine la recherche pour voir la suite (%d objets affichés sur %d)."), drawn, #items))
        f.catMore:ClearAllPoints(); f.catMore:SetPoint("TOPLEFT", 0, -(y + 6))
        y = y + 6 + S.FitText(f.catMore, 0, CW, f.cat.content)
        f.catMore:Show()
    else f.catMore:Hide() end
    -- the profession's crafters who shared recipes: their own lists
    local sharing = {}
    if not filtered then
        for _, c in ipairs(e.crafters) do if c.n > 0 then sharing[#sharing + 1] = c end end
        table.sort(sharing, ByCrafter)
    end
    if #sharing > 0 then
        f.catHead:Set(L("Artisans de ce métier"), #sharing)
        f.catHead:ClearAllPoints(); f.catHead:SetPoint("TOPLEFT", 0, -(y + 14)); f.catHead:Show()
        y = y + 14 + 32 + 8
        for _, c in ipairs(sharing) do
            i = i + 1
            local r = f.cat.Get(i)
            r.kind, r.item, r.crafter, r.it = "crafter", nil, nil, nil
            r.open = { name = c.name, prof = c.prof, me = c.me }
            SetClass(r, c.name)
            r.name:SetText(c.name .. (c.me and (" " .. S.Hex(C.muted) .. L("(toi)") .. "|r") or "")
                .. (c.stars > 0 and (" " .. STAR .. S.Hex(C.gold) .. c.stars .. "|r") or ""))
            r.detail:SetText(string.format(L("%s %d"), ProfLabel(key), c.rank) .. " · " .. Where(c.online)
                .. " · " .. P(c.n, L("1 recette"), L("%d recettes"))); r.detail:Show()
            r.btn:SetText(L("Voir les recettes")); r.btn:Show()
            r.btnTip = { string.format(L("Recettes de %s"), c.name), string.format(L("Clic : voir les recettes de %s"), c.name) }
            local tip = { c.name, r.detail:GetText() }
            local sl = StarLine(c.name); if sl then tip[#tip + 1] = sl end
            tip[#tip + 1] = string.format(L("Clic : voir les recettes de %s"), c.name)
            r.tip, r.tipFill = tip, nil
            local rh = r:Fit(CW)
            r:ClearAllPoints(); r:SetPoint("TOPLEFT", 0, -y)
            y = y + rh + 2
        end
    else f.catHead:Hide() end
    f.cat.HideFrom(i + 1)
    -- declared the profession, shared nothing: who, and what they have to do
    -- (under the empty state, which already says how recipes arrive: the names only)
    if (#e.unshared > 0 or e.meUnshared) and not filtered then
        local parts = {}
        if #e.unshared > 0 then
            local names = table.concat(e.unshared, ", ")
            if f.catEmpty:IsShown() then parts[1] = string.format(L("Pas encore de recettes partagées par %s."), names)
            elseif #e.unshared == 1 then parts[1] = string.format(L("Pas encore de recettes partagées par %s. Elles arrivent quand ce membre ouvre sa fenêtre de métier."), names)
            else parts[1] = string.format(L("Pas encore de recettes partagées par %s. Elles arrivent quand ils ouvrent leur fenêtre de métier."), names) end
        end
        if e.meUnshared then parts[#parts + 1] = L("Ouvre ta fenêtre de métier pour partager les tiennes.") end
        f.catNote:SetText(S.IconMarkup("info", 12, C.muted) .. " " .. table.concat(parts, " "))
        f.catNote:ClearAllPoints(); f.catNote:SetPoint("TOPLEFT", 0, -(y + 10))
        y = y + 10 + S.FitText(f.catNote, 0, CW, f.cat.content)
        f.catNote:Show()
    else f.catNote:Hide() end
    f.cat.content:SetHeight(math.max(1, y))
    return y
end

-- the window's subtitle: how many crafters this copy knows
local function CrafterCount()
    local crafters, online = 0, 0
    local on = O.OnlineGuild()
    for name in pairs(O.DB().crafters) do crafters = crafters + 1; if on[name] then online = online + 1 end end
    if crafters == 0 then return L("Aucun artisan connu pour l'instant") end
    if crafters == 1 then return online == 1 and L("1 artisan connu, en ligne") or L("1 artisan connu, hors ligne") end
    if online == 0 then return string.format(L("%d artisans connus, aucun en ligne"), crafters) end
    return string.format(L("%d artisans connus, dont %d en ligne"), crafters, online)
end

local function RenderFind()
    local f = ui.find
    local p = pages.find
    local q = (f.box:GetText() or ""):lower()
    win.subtitle:SetText(CrafterCount())
    f.listHead:Hide(); f.empty:Hide()
    -- one crafter picked: what they make (when their recipe list arrived)
    if f.view and #q < 2 then
        local v = f.view
        f.back:SetText(f.prof and ProfLabel(f.prof) or L("Tous les métiers"))
        f.back:Show()
        local l = SetMode(f, "list")
        local pr = v.me and O.DB().mine[v.prof] or (O.DB().crafters[v.name] or {})[v.prof]
        local items = {}
        for id in pairs(pr and pr.recipes or {}) do items[#items + 1] = { id = id, name = Name(id) } end
        table.sort(items, function(a, b) return a.name < b.name end)
        f.listHead:Set(string.format(L("Recettes de %s"), v.name), string.format(L("%s %d"), ProfLabel(ProfKey(v.prof), v.prof), pr and pr.rank or 0))
        f.listHead:ClearAllPoints(); f.listHead:SetPoint("TOPLEFT", 0, 0); f.listHead:Show()
        local y = 32 + 8
        local shown = 0
        for i, it in ipairs(items) do
            local id = it.id
            local row = f.list.Get(i)
            row.item, row.crafter, row.open = id, not v.me and v.name or nil, nil
            SetItem(row, ItemTex(id), id)
            row.name:SetText(it.name)
            local reag = Reagents(pr.recipes[id] or "", 1)
            row.detail:SetText(reag ~= "" and reag or L("Composants inconnus")); row.detail:Show()
            -- name and every reagent on its own line, built on hover only
            local qc = id > 0 and S.QualityColor(id) or C.fg
            local tip = { S.Hex(qc) .. it.name .. "|r" }
            row.tip = tip
            local crafter = row.crafter
            row.tipFill = function()
                for k = #tip, 2, -1 do tip[k] = nil end
                for _, rg in ipairs(O.Decode(pr.recipes[id] or "")) do tip[#tip + 1] = rg[2] .. "× " .. Name(rg[1]) end
                if crafter then
                    tip[#tip + 1] = string.format(L("Clic : commander à %s"), crafter)
                    tip[#tip + 1] = L("Maj-clic : demander à toute la guilde")
                end
            end
            row.btn:SetText(L("Commander")); row.btn:SetShown(not v.me)
            row.btnTip = crafter and { L("Commander"), string.format(L("Clic : commander à %s"), crafter) } or nil
            row.askProf = (not v.me) and v.prof or nil
            local rh = row:Fit(CW)
            row:ClearAllPoints(); row:SetPoint("TOPLEFT", 0, -y)
            y = y + rh + 2
            shown = i
            if i >= 150 then break end
        end
        f.list.HideFrom(shown + 1)
        if #items == 0 then
            f.listHead:Hide()
            y = Empty(f.empty, true, "clock", L("Recettes pas encore arrivées"),
                L("Elles arrivent quand ce membre ouvre sa fenêtre de métier."))
        end
        f.list.content:SetHeight(math.max(1, y))
        Fit(p, l, y)
        return
    end
    -- a profession picked in the grid: its catalogue
    if f.prof then
        local l = SetMode(f, "cat")
        Fit(p, l, RenderCatalog(f, GuildCrafts()))
        return
    end
    -- an item link (shift-click an item) or "item:12345": order it from the guild, recipe known or not
    local linked = tonumber((f.box:GetText() or ""):match("item:(%d+)"))
    if linked then
        local l = SetMode(f, "list")
        local who = O.Possible(linked)
        local row = f.list.Get(1)
        row.item, row.crafter, row.open = linked, nil, nil
        local qc = SetItem(row, S.ItemIcon(linked), linked)
        row.name:SetText(Name(linked))
        row.detail:SetText(#who > 0 and P(#who, L("1 artisan possible"), L("%d artisans possibles"))
            or L("Personne n'a déclaré ce métier : toute la guilde verra quand même ta commande.")); row.detail:Show()
        row.tip, row.tipFill = { S.Hex(qc) .. Name(linked) .. "|r", L("Toute la guilde verra ta commande."), L("Clic : commander à la guilde") }, nil
        row.btn:SetText(L("Commander à la guilde")); row.btn:Show(); row.askProf = nil
        row.btnTip = { L("Commander à la guilde"), L("Toute la guilde verra ta commande."), L("Clic : commander à la guilde") }
        local y = row:Fit(CW)
        row:ClearAllPoints(); row:SetPoint("TOPLEFT", 0, 0)
        -- each possible crafter: exact (shared recipe) or by profession, online first
        local shown = 0
        if #who > 0 then
            f.listHead:Set(L("Artisans possibles"), #who)
            f.listHead:ClearAllPoints(); f.listHead:SetPoint("TOPLEFT", 0, -(y + 8)); f.listHead:Show()
            y = y + 8 + 32 + 8
        end
        for i, c in ipairs(who) do
            local cr = f.list.Get(i + 1)
            cr.item, cr.crafter, cr.open = linked, c.name, nil
            cr.name:SetText(c.name .. Stars(c.name))
            SetClass(cr, c.name)
            local key = ProfKey(c.prof)
            cr.detail:SetText(ProfMarkup(key) .. " " .. string.format(L("%s %d"), ProfLabel(key, c.prof), c.rank or 0)
                .. " · " .. Where(c.online) .. " · " .. (c.exact and L("recette connue") or L("métier compatible"))); cr.detail:Show()
            local tip = { c.name, cr.detail:GetText() }
            local sl = StarLine(c.name); if sl then tip[#tip + 1] = sl end
            tip[#tip + 1] = string.format(L("Clic : commander à %s"), c.name)
            cr.tip, cr.tipFill = tip, nil
            cr.btn:SetText(L("Commander")); cr.btn:Show(); cr.askProf = nil
            cr.btnTip = { L("Commander"), string.format(L("Clic : commander à %s"), c.name) }
            local rh = cr:Fit(CW)
            cr:ClearAllPoints(); cr:SetPoint("TOPLEFT", 0, -y)
            y = y + rh + 2
            shown = i
            if i >= 30 then break end
        end
        f.list.HideFrom(shown + 2)
        f.list.content:SetHeight(math.max(1, y))
        Fit(p, l, y)
        return
    end
    -- nothing typed: the profession grid
    if #q < 2 then
        local l = SetMode(f, "grid")
        Fit(p, l, RenderGrid(f, GuildCrafts()))
        return
    end
    -- a name typed: every shared recipe whose item matches, one row per crafter
    local l = SetMode(f, "list")
    local catalog = O.Catalog()
    local rows, names = {}, {}
    for id, prof in pairs(catalog) do
        local n = Name(id)
        if n:lower():find(q, 1, true) then
            names[id] = n
            for _, c in ipairs(O.Crafters(id)) do rows[#rows + 1] = { item = id, prof = prof, c = c } end
        end
    end
    table.sort(rows, function(a, b)
        if a.item ~= b.item then return names[a.item] < names[b.item] end
        if a.c.online ~= b.c.online then return a.c.online end
        return a.c.rank > b.c.rank
    end)
    local y, shown = 0, 0
    for i, r in ipairs(rows) do
        local row = f.list.Get(i)
        row.item, row.crafter, row.open = r.item, not r.c.me and r.c.name or nil, nil
        SetItem(row, ItemTex(r.item), r.item)
        row.name:SetText(names[r.item])
        row.detail:SetText((r.c.me and L("toi") or (r.c.name .. Stars(r.c.name))) .. " · "
            .. string.format(L("%s %d"), ProfLabel(ProfKey(r.c.prof), r.c.prof), r.c.rank or 0) .. " · " .. Where(r.c.online, r.c.seen)); row.detail:Show()
        local qc = r.item > 0 and S.QualityColor(r.item) or C.fg
        local tip = { S.Hex(qc) .. names[r.item] .. "|r", row.detail:GetText() }
        if row.crafter then tip[#tip + 1] = string.format(L("Clic : commander à %s"), row.crafter) end
        row.tip, row.tipFill = tip, nil
        row.btn:SetText(L("Commander")); row.btn:SetShown(not r.c.me); row.askProf = nil
        row.btnTip = row.crafter and { L("Commander"), string.format(L("Clic : commander à %s"), row.crafter) } or nil
        local rh = row:Fit(CW)
        row:ClearAllPoints(); row:SetPoint("TOPLEFT", 0, -y)
        y = y + rh + 2
        shown = i
        if i >= 60 then break end
    end
    f.list.HideFrom(shown + 1)
    if next(catalog) == nil then
        y = Empty(f.empty, true, "hammer", L("Aucune recette partagée"),
            L("Les membres qui ont WL Helper partagent leurs métiers en se connectant."),
            L("Faire une demande"), function() WP.AskOrder(nil, nil, { title = O.CleanTitle(f.box:GetText() or "") }) end)
    elseif #rows == 0 then
        y = Empty(f.empty, true, "search", L("Personne n'a partagé cette recette"), L("Une demande prévient quand même les artisans du métier."),
            L("Faire une demande"), function() WP.AskOrder(nil, nil, { title = O.CleanTitle(f.box:GetText() or "") }) end)
    end
    f.list.content:SetHeight(math.max(1, y))
    Fit(p, l, y)
end

-- ---------------------------------------------------------------- page: a new order
local draft
local LBL = 16   -- a field's label above it: 11 px text and its 4 px gap

-- a numeric field with its label above
local function NumberBox(parent, width, label, placeholder)
    local eb = S.Input(parent, width, { label = label, placeholder = placeholder })
    eb:SetNumeric(true); eb:SetMaxLetters(6)
    return eb
end

-- a settings-like row: label 13, description 11 under it, switch at the right; the row is the target
local function SwitchRow(parent, label, desc, get, set)
    local r = CreateFrame("Button", nil, parent)
    r.wlOwned = true
    S.Solid(r, "BACKGROUND", C.cardFill):SetAllPoints(); S.Border(r, C.cardEdge)
    r.label = S.Text(r, F.body, C.fg); r.label:SetPoint("TOPLEFT", 12, -10); r.label:SetText(label)
    S.ClampLabel(r.label, nil, r)
    r.desc = S.Text(r, F.meta, C.muted); r.desc:SetJustifyH("LEFT"); r.desc:SetJustifyV("TOP")
    r.desc:SetPoint("TOPLEFT", r.label, "BOTTOMLEFT", 0, -3); r.desc:SetText(desc)
    r.switch = S.Switch(r, get, set)
    r.switch:SetPoint("RIGHT", -12, 0)
    r.switch:AttachRow(r)
    function r:Fit(width)
        self:SetWidth(width)
        local dh = S.FitText(self.desc, 2, width - 12 - 40 - 24, self)
        local h = math.max(44, math.ceil(10 + F.body + 3 + dh + 10))
        self:SetHeight(h)
        return h
    end
    return r
end

local function BuildNew(p)
    local n = ui.new
    n.page = p
    n.sa = S.ScrollArea(p)
    n.sa:SetPoint("TOPLEFT"); n.sa:SetPoint("BOTTOMRIGHT")
    local c = n.sa.child
    c:SetWidth(CW)
    n.iconFrame = Painted(c, 40); n.icon = n.iconFrame.tex
    n.iconFrame:SetPoint("TOPLEFT", 0, 0)
    n.name = S.Text(c, F.heading, C.fg); n.name:SetJustifyH("LEFT"); n.name:SetJustifyV("TOP")
    n.name:SetPoint("TOPLEFT", n.iconFrame, "TOPRIGHT", 12, 0)
    n.sub = S.Text(c, F.meta, C.muted); n.sub:SetJustifyH("LEFT"); n.sub:SetJustifyV("TOP")
    n.sub:SetPoint("TOPLEFT", n.name, "BOTTOMLEFT", 0, -3)
    n.qtyBox = NumberBox(c, 64, L("Quantité"))
    n.qtyBox:SetPoint("TOPRIGHT", 0, -LBL)
    n.qtyBox:HookScript("OnTextChanged", function(self, user) if user then draft.qty = math.max(1, tonumber(self:GetText() or "") or 1); WP.RefreshOrders() end end)
    -- to the whole guild, or only to the crafter picked in the list (one control per crafter name)
    n.forLabel = S.Text(c, F.meta, C.muted); n.forLabel:SetText(L("Pour")); S.ClampLabel(n.forLabel, nil, c)
    n.toText = S.Text(c, F.label, C.text); n.toText:SetText(L("Toute la guilde verra ta commande."))
    n.toSeg = {}
    n.rhead = Header(c)
    n.noRecipe = S.Text(c, F.body, C.muted); n.noRecipe:SetJustifyH("LEFT"); n.noRecipe:SetJustifyV("TOP")
    n.noRecipe:SetText(L("Recette inconnue : précise dans le mot pour l'artisan qui fournit quels composants."))
    n.rows = {}
    for i = 1, 8 do
        local r = CreateFrame("Button", nil, c)
        r.wlOwned = true
        S.Solid(r, "BACKGROUND", C.cardFill):SetAllPoints()
        Feedback(r)
        r.iconFrame = Painted(r, 20); r.iconFrame:SetPoint("LEFT", 8, 0)
        r.tag = S.Pill(r)
        r.tag:SetPoint("RIGHT", -12, 0)
        r.name = S.Text(r, F.label, C.fg); r.name:SetJustifyH("LEFT")
        r.name:SetPoint("LEFT", r.iconFrame, "RIGHT", 8, 0)
        S.ClampLabel(r.name, nil, r)
        r:SetScript("OnClick", function(self) if self.id then draft.crafterGives[self.id] = not draft.crafterGives[self.id]; WP.RefreshOrders() end end)
        n.rows[i] = r
    end
    n.cost = S.Text(c, F.meta, C.muted); n.cost:SetJustifyH("LEFT"); n.cost:SetJustifyV("TOP")
    n.fee = NumberBox(c, 96, L("Commission (po)"), "0")
    n.fee:HookScript("OnTextChanged", function(self, user) if user then draft.fee = (tonumber(self:GetText() or "") or 0) * 10000 end end)
    n.tip = NumberBox(c, 96, L("Pourboire (po)"), "0")
    n.tip:HookScript("OnTextChanged", function(self, user) if user then draft.tip = (tonumber(self:GetText() or "") or 0) * 10000 end end)
    n.hoursLabel = S.Text(c, F.meta, C.muted); n.hoursLabel:SetText(L("Valable")); S.ClampLabel(n.hoursLabel, nil, c)
    n.hours = S.Segmented(c, { { 12, "12 h" }, { 24, "24 h" }, { 72, L("3 j") } }, function() return draft and draft.hours or 24 end,
        function(v) draft.hours = v; WP.RefreshOrders() end, 28)
    n.note = S.Input(c, CW, { label = L("Un mot pour l'artisan"), placeholder = L("Ex. Pas pressé, merci !") })
    n.note:SetMaxLetters(60)
    n.payUp = SwitchRow(c, L("Payer d'avance"), L("L'or part avec les composants. Sinon, tu paies à la livraison."),
        function() return draft and draft.payUp end, function(v) draft.payUp = v end)
    n.go = S.Button(c, L("Publier la commande"), 0, 32, "primary", function()
        local give, crafter = {}, {}
        for _, r in ipairs(O.Reagents(draft.item)) do
            if draft.crafterGives[r[1]] then crafter[#crafter + 1] = r[1] .. ":" .. r[2] else give[#give + 1] = r[1] .. ":" .. r[2] end
        end
        local fee = draft.fee or 0
        O.Publish({ to = draft.to, item = draft.item, qty = draft.qty or 1, give = table.concat(give, ","), crafter = table.concat(crafter, ","),
            fee = fee, tip = draft.tip or 0, paid = draft.payUp and (fee + (draft.tip or 0)) or 0, note = n.note:GetText() or "", hours = draft.hours or 24 })
        WP.ShowOrdersTab("mine")
    end)
    n.hint = S.Text(c, F.meta, C.muted); n.hint:SetJustifyH("LEFT"); n.hint:SetJustifyV("MIDDLE")
    n.hint:SetText(L("Rien ne part par la poste avant qu'un artisan accepte."))
end

-- the "to" control for this crafter: Whole guild / Only <name>
local function ToControl(n, crafter)
    local seg = n.toSeg[crafter]
    if not seg then
        seg = S.Segmented(n.sa.child, { { "guild", L("Toute la guilde") }, { "one", string.format(L("Seulement %s"), crafter) } },
            function() return (draft and draft.to) and "one" or "guild" end,
            function(v) draft.to = (v == "one") and draft.crafter or nil; WP.RefreshOrders() end, 28)
        n.toSeg[crafter] = seg
    end
    for name, s in pairs(n.toSeg) do s:SetShown(name == crafter) end
    seg:SetMaxWidth(CW)
    seg:Update()
    return seg
end

local function RenderNew()
    local n = ui.new
    if not draft then return end
    local c = n.sa.child
    pages.new.topH = 0
    S.Painted(n.icon, ItemTex(draft.item))
    local qc = draft.item > 0 and S.QualityColor(draft.item) or C.fg
    n.name:SetText(Name(draft.item)); n.name:SetTextColor(qc[1], qc[2], qc[3])
    local nameW = CW - 52 - 64 - 16
    local y = S.FitText(n.name, 2, nameW, c)
    -- the crafter picked in the list
    n.sub:SetShown(draft.crafter ~= nil)
    if draft.crafter then
        local knows = false
        for _, cr in ipairs(O.Crafters(draft.item)) do if cr.name == draft.crafter then knows = true end end
        n.sub:SetText(string.format(knows and L("Recette connue de %s") or L("%s a le métier, recette pas encore partagée"), draft.crafter))
        y = y + 3 + S.FitText(n.sub, 2, nameW, c)
    end
    if not n.qtyBox:HasFocus() then n.qtyBox:SetText(tostring(draft.qty or 1)) end
    y = math.max(40, y, LBL + 28) + 16
    -- for whom
    n.forLabel:ClearAllPoints(); n.forLabel:SetPoint("TOPLEFT", 0, -y)
    n.forLabel:SetShown(draft.crafter ~= nil)
    if draft.crafter then
        local seg = ToControl(n, draft.crafter)
        seg:ClearAllPoints(); seg:SetPoint("TOPLEFT", 0, -(y + LBL))
        n.toText:Hide()
        y = y + LBL + 28
    else
        for _, s in pairs(n.toSeg) do s:Hide() end
        n.toText:ClearAllPoints(); n.toText:SetPoint("TOPLEFT", 0, -y)
        n.toText:Show()
        y = y + S.FitText(n.toText, 2, CW, c)
    end
    -- the reagents: who provides each one (click to switch)
    local reagents = O.Reagents(draft.item)
    n.rhead:Set(L("Composants"), #reagents > 0 and #reagents or nil)
    n.rhead:ClearAllPoints(); n.rhead:SetPoint("TOPLEFT", 0, -(y + 8))
    y = y + 8 + 32 + 8
    if #reagents == 0 then
        n.noRecipe:ClearAllPoints(); n.noRecipe:SetPoint("TOPLEFT", 0, -y); n.noRecipe:Show()
        y = y + S.FitText(n.noRecipe, 0, CW, c)
    else n.noRecipe:Hide() end
    local total, priced = 0, true
    for i, r in ipairs(n.rows) do
        local rg = reagents[i]
        r:SetShown(rg ~= nil)
        if rg then
            r.id = rg[1]
            local need = rg[2] * (draft.qty or 1)
            local have = WP.OwnedCount and WP.OwnedCount(rg[1]) or 0
            local pr = WP.Price and WP.Price(rg[1])
            if pr then total = total + pr * need else priced = false end
            S.Painted(r.iconFrame.tex, S.ItemIcon(rg[1]))
            r.name:SetText(need .. "× " .. Name(rg[1]))
            local gives = draft.crafterGives[rg[1]]
            if gives then
                r.tag:Set(pr and string.format(L("L'artisan fournit · ~%s"), Money(pr * need)) or L("L'artisan fournit"), C.warn)
            else
                r.tag:Set(string.format(L("Tu fournis · %d/%d"), math.min(have, need), need), have >= need and C.ok or C.bad)
            end
            local rq = S.QualityColor(rg[1])
            r.tip = { S.Hex(rq) .. Name(rg[1]) .. "|r", string.format(L("Tu en as %d (sacs et banque)."), have),
                gives and L("Clic : c'est toi qui le fournis") or L("Clic : c'est l'artisan qui le fournit") }
            r:SetSize(CW, 36)
            r.name:SetWidth(math.max(60, CW - 36 - 12 - (num(r.tag:GetWidth()) or 100) - 12))
            r:ClearAllPoints(); r:SetPoint("TOPLEFT", 0, -y)
            y = y + 36 + 2
        end
    end
    -- what the reagents cost at the auction house, and a fee in proportion (10 %, at least 1 gold)
    if #reagents > 0 and total > 0 then
        local fee = math.max(10000, math.floor(total * 0.1 / 100) * 100)
        n.cost:SetText(string.format(L("Composants à l'HV : %s%s. Commission conseillée : %s."), priced and "" or "~", Money(total), Money(fee)))
        n.cost:ClearAllPoints(); n.cost:SetPoint("TOPLEFT", 0, -(y + 4)); n.cost:Show()
        y = y + 4 + S.FitText(n.cost, 2, CW, c)
    else n.cost:Hide() end
    -- fee, tip, how long it stays open
    y = y + 16
    n.fee:ClearAllPoints(); n.fee:SetPoint("TOPLEFT", 0, -(y + LBL))
    n.tip:ClearAllPoints(); n.tip:SetPoint("TOPLEFT", 96 + 16, -(y + LBL))
    n.hoursLabel:ClearAllPoints(); n.hoursLabel:SetPoint("TOPLEFT", 2 * (96 + 16), -y)
    n.hours:ClearAllPoints(); n.hours:SetPoint("TOPLEFT", 2 * (96 + 16), -(y + LBL))
    n.hours:Update()
    y = y + LBL + 28 + 16
    n.note:ClearAllPoints(); n.note:SetPoint("TOPLEFT", 0, -(y + LBL))
    y = y + LBL + 28 + 16
    n.payUp:ClearAllPoints(); n.payUp:SetPoint("TOPLEFT", 0, -y)
    n.payUp.switch:Update()
    y = y + n.payUp:Fit(CW) + 16
    n.go:ClearAllPoints(); n.go:SetPoint("TOPLEFT", 0, -y)
    local gw = num(n.go:GetWidth()) or 160
    n.hint:ClearAllPoints(); n.hint:SetPoint("LEFT", n.go, "RIGHT", 12, 0)
    S.FitText(n.hint, 2, math.max(80, CW - gw - 12), c)
    y = y + 32
    c:SetHeight(y)
    Fit(pages.new, n.sa, y)
end

-- from: an earlier order to copy (quantity, fee, tip, note, who gives what)
function WP.NewOrder(item, crafter, from)
    if WP.ModuleOff and WP.ModuleOff("orders") then return end
    draft = { item = item, crafter = crafter, to = crafter, qty = from and from.qty or 1, hours = 24, crafterGives = {}, fee = from and from.fee or 0, tip = from and from.tip or 0 }
    if from and from.crafter then for _, r in ipairs(O.Decode(from.crafter)) do draft.crafterGives[r[1]] = true end end
    if not win then WP.ShowOrdersTab("find") end
    ui.new.fee:SetText(from and (from.fee or 0) > 0 and tostring(math.floor(from.fee / 10000)) or "")
    ui.new.tip:SetText(from and (from.tip or 0) > 0 and tostring(math.floor(from.tip / 10000)) or "")
    ui.new.note:SetText(from and from.note or "")
    WP.ShowOrdersTab("new")
end

-- ---------------------------------------------------------------- page: a request
-- For a lost player: anything, on the list of shared recipes or not. A typed name or a shift-clicked
-- item; when the game knows the item the order carries its ID, otherwise only the text. The
-- profession picked decides who is alerted ("I don't know": every crafter of the guild).
local ASK_PROFS = { "alchemy", "blacksmithing", "enchanting", "engineering", "leatherworking", "tailoring", "cooking", "firstaid", "mining" }
local askState = { prof = "", hours = 24 }
local askNames   -- { at = GetTime(), map = { [lowercase name] = item } } of the guild's recipes

local function Trim(t) return (tostring(t or ""):gsub("^%s+", ""):gsub("%s+$", "")) end

-- the item a text names: a link ("item:123"), a name the game knows, or one of the guild's recipes
local function Resolve(text)
    text = text or ""
    local f = askState.forced
    if f and f.text == text then return f.id end
    local id = tonumber(text:match("item:(%d+)"))
    if id then return id end
    local name = Trim(text)
    if #name < 2 or name:find("|", 1, true) then return nil end
    local instant = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
    if instant then
        local ok, iid = pcall(instant, name)
        if ok and type(iid) == "number" and iid > 0 then return iid end
    end
    local info = (C_Item and C_Item.GetItemInfo) or GetItemInfo
    if info then
        local ok, _, link = pcall(info, name)
        id = ok and type(link) == "string" and tonumber(link:match("item:(%d+)"))
        if id then return id end
    end
    -- the guild's recipes by lowercase name, built once (not per keystroke): rebuilt when the tab
    -- opens, when item names arrive, and at most every 10 s for recipes shared meanwhile
    if #name < 3 then return nil end
    local now = GetTime and GetTime() or 0
    if not askNames or now - askNames.at > 10 then
        local map = {}
        for cid in pairs(O.Catalog()) do
            if cid > 0 then
                local n = WP.ItemName(cid, "")   -- "" while the game does not know it yet
                if n ~= "" then map[n:lower()] = map[n:lower()] or cid end
            end
        end
        askNames = { at = now, map = map }
    end
    return askNames.map[name:lower()]
end

-- a choice tile (a profession's icon, or a word): selection fill and a 1 px accent border when picked
local function Choice(parent, w, h)
    local b = CreateFrame("Button", nil, parent)
    b.wlOwned = true
    b:SetSize(w, h)
    S.Solid(b, "BACKGROUND", C.cardFill):SetAllPoints()
    b.sel = S.Solid(b, "BACKGROUND", C.selFill); b.sel:SetAllPoints(); b.sel:Hide()
    b.edge = S.Border(b, C.cardEdge)
    Feedback(b)
    function b:SetSelected(on, dimmed)
        self.sel:SetShown(on and true or false)
        self.edge(on and C.accent or C.cardEdge, 1)
        if self.icon then self.icon:SetDesaturated(dimmed and true or false); self.icon:SetAlpha(dimmed and 0.6 or 1) end
        if self.label then local c = on and C.fg or C.muted; self.label:SetTextColor(c[1], c[2], c[3]) end
    end
    return b
end

local function BuildAsk(p)
    local a = ui.ask
    a.sa = S.ScrollArea(p)
    a.sa:SetPoint("TOPLEFT"); a.sa:SetPoint("BOTTOMRIGHT")
    local c = a.sa.child
    c:SetWidth(CW)
    a.box = S.Input(c, CW, { label = L("Ce que tu veux"), placeholder = L("Ex. Sac en étoffe runique, ou Maj-clic sur un objet") })
    a.box:SetPoint("TOPLEFT", 0, -LBL)
    a.box:HookScript("OnTextChanged", function() WP.RefreshOrders() end)
    a.err = a.box.err
    -- what the text was recognised as (never the typed text itself: it could be any length)
    a.foundIcon = c:CreateTexture(nil, "ARTWORK"); a.foundIcon:SetSize(16, 16)
    a.found = S.Text(c, F.meta, C.muted); a.found:SetJustifyH("LEFT"); a.found:SetJustifyV("TOP")
    -- the profession: its icons, and "I don't know"
    a.profLabel = S.Text(c, F.meta, C.muted); a.profLabel:SetText(L("Métier")); S.ClampLabel(a.profLabel, nil, c)
    a.profName = S.Text(c, F.label, C.fg); a.profName:SetJustifyH("LEFT")
    a.profName:SetPoint("LEFT", a.profLabel, "RIGHT", 8, 0); a.profName:SetWidth(CW - 60); S.ClampLabel(a.profName, nil, c)
    a.profs = {}
    for i, key in ipairs(ASK_PROFS) do
        local b = Choice(c, 36, 36)
        b.icon = b:CreateTexture(nil, "ARTWORK"); b.icon:SetSize(28, 28); b.icon:SetPoint("CENTER")
        S.Painted(b.icon, ProfIcon(key))
        b.key = key
        b.tip = function(self) return { ProfLabel(self.key), L("Clic : prévenir les artisans de ce métier") } end
        b:SetScript("OnClick", function(self) askState.prof, askState.picked = self.key, true; WP.RefreshOrders() end)
        a.profs[i] = b
    end
    -- "I don't know": a framed word the same height as the icons
    local dk = Choice(c, 100, 36)
    dk.label = S.Text(dk, F.label, C.muted); dk.label:SetPoint("CENTER"); dk.label:SetText(L("Je ne sais pas"))
    S.ClampLabel(dk.label, nil, dk)
    local okW, dw = pcall(dk.label.GetStringWidth, dk.label)
    dk:SetWidth(math.max(64, math.ceil((okW and num(dw)) or 80) + 24))
    dk.tip = { L("Je ne sais pas"), L("Tous les artisans de la guilde seront prévenus"), L("Clic : prévenir tous les artisans") }
    dk:SetScript("OnClick", function() askState.prof, askState.picked = "", true; WP.RefreshOrders() end)
    a.dunno = dk
    -- quantity, fee in gold, how long it stays open
    a.qty = NumberBox(c, 64, L("Quantité")); a.qty:SetText("1")
    a.fee = NumberBox(c, 96, L("Commission (po)"), "0")
    a.hoursLabel = S.Text(c, F.meta, C.muted); a.hoursLabel:SetText(L("Valable")); S.ClampLabel(a.hoursLabel, nil, c)
    a.hours = S.Segmented(c, { { 12, "12 h" }, { 24, "24 h" }, { 72, L("3 j") } }, function() return askState.hours or 24 end,
        function(v) askState.hours = v end, 28)
    a.note = S.Input(c, CW, { label = L("Un mot pour l'artisan"), placeholder = L("Ex. Pas pressé, merci !") })
    a.note:SetMaxLetters(60)
    -- who will be told (online first)
    a.summary = S.Text(c, F.meta, C.muted); a.summary:SetJustifyH("LEFT"); a.summary:SetJustifyV("TOP")
    a.go = S.Button(c, L("Publier la demande"), 0, 32, "primary", function()
        local text = a.box:GetText() or ""
        local id = Resolve(text)
        local title = (not id) and O.CleanTitle(text) or nil
        if not id and (not title or title == "") then
            a.box:SetError(L("Écris ce que tu veux, par exemple Sac en étoffe runique."))
            WP.RefreshOrders()
            return
        end
        local key = askState.prof or ""
        local prof = (key ~= "" and PROFS[key]) and PROFS[key][2] or ""
        local qty = math.max(1, tonumber(a.qty:GetText() or "") or 1)
        local fee = (tonumber(a.fee:GetText() or "") or 0) * 10000
        local o = O.Publish({ item = id, title = title, prof = prof, qty = qty, give = "", crafter = "", fee = fee, tip = 0, paid = 0,
            note = a.note:GetText() or "", hours = askState.hours or 24 })
        WP.Print(string.format(L("Demande publiée : %s ×%d (%s). Tu la suis dans Mes commandes."), Name(o), qty, O.ProfName(prof)))
        askState = { prof = "", hours = 24 }
        a.box:SetText(""); a.note:SetText(""); a.fee:SetText(""); a.qty:SetText("1"); a.box:SetError(nil)
        WP.ShowOrdersTab("mine")
    end)
    a.hint = S.Text(c, F.meta, C.muted); a.hint:SetJustifyH("LEFT"); a.hint:SetJustifyV("MIDDLE")
    a.hint:SetText(L("Les artisans prévenus la voient dans l'onglet Ouvertes."))
end

local function RenderAsk()
    local a = ui.ask
    local c = a.sa.child
    pages.ask.topH = 0
    local text = a.box:GetText() or ""
    local id = Resolve(text)
    if Trim(text) ~= "" and a.err:IsShown() then a.box:SetError(nil) end
    -- a new item: its profession preselected, unless one was picked by hand
    if id and id ~= askState.lastItem then
        askState.lastItem = id
        if not askState.picked then
            local key
            local cr = O.Crafters(id)[1]
            if cr then key = ProfKey(cr.prof) end
            if not key then local lp = O.LikelyProfs(id)[1]; key = lp and ProfKey(lp) end
            for _, k in ipairs(ASK_PROFS) do if k == key then askState.prof = key end end
        end
    elseif not id then askState.lastItem = nil end
    local y = LBL + 28
    if a.err:IsShown() then y = y + 4 + S.FitText(a.err, 2, CW, c) end
    y = y + 8
    if id then
        S.Painted(a.foundIcon, S.ItemIcon(id)); a.foundIcon:SetSize(16, 16); a.foundIcon:Show()
        a.found:SetText(string.format(L("Objet reconnu : %s"), S.Hex(S.QualityColor(id)) .. Name(id) .. "|r"))
    elseif Trim(text) ~= "" then
        S.HDIcon(a.foundIcon, "info", C.muted); a.foundIcon:Show()
        a.found:SetText(L("Pas un objet du jeu : ta demande partira avec ce texte."))
    else
        a.foundIcon:Hide()
        a.found:SetText(L("Un nom d'objet suffit, même approximatif. Maj-clic marche depuis les sacs, le chat et les recettes."))
    end
    local fx = a.foundIcon:IsShown() and 22 or 0
    a.foundIcon:ClearAllPoints(); a.foundIcon:SetPoint("TOPLEFT", 0, -y)
    a.found:ClearAllPoints(); a.found:SetPoint("TOPLEFT", fx, -(y + 1))
    y = y + math.max(16, S.FitText(a.found, 2, CW - fx, c)) + 16
    -- the profession picked: selection fill and accent border; the others dimmed while one is picked
    local cur = askState.prof or ""
    a.profLabel:ClearAllPoints(); a.profLabel:SetPoint("TOPLEFT", 0, -y)
    a.profName:SetText(cur == "" and L("Tous les artisans de la guilde seront prévenus") or ProfLabel(cur))
    y = y + LBL
    local x = 0
    for _, b in ipairs(a.profs) do
        b:ClearAllPoints(); b:SetPoint("TOPLEFT", x, -y)
        b:SetSelected(b.key == cur, cur ~= "" and b.key ~= cur)
        x = x + 36 + 6
    end
    a.dunno:SetSelected(cur == "")
    a.dunno:ClearAllPoints()
    local dw = num(a.dunno:GetWidth()) or 100
    if x + 2 + dw <= CW then a.dunno:SetPoint("TOPLEFT", x + 2, -y); y = y + 36
    else a.dunno:SetPoint("TOPLEFT", 0, -(y + 36 + 6)); y = y + 36 + 6 + 36 end
    y = y + 16
    -- quantity, fee, how long
    if not a.qty:HasFocus() and (a.qty:GetText() or "") == "" then a.qty:SetText("1") end
    a.qty:ClearAllPoints(); a.qty:SetPoint("TOPLEFT", 0, -(y + LBL))
    a.fee:ClearAllPoints(); a.fee:SetPoint("TOPLEFT", 64 + 16, -(y + LBL))
    a.hoursLabel:ClearAllPoints(); a.hoursLabel:SetPoint("TOPLEFT", 64 + 16 + 96 + 16, -y)
    a.hours:ClearAllPoints(); a.hours:SetPoint("TOPLEFT", 64 + 16 + 96 + 16, -(y + LBL))
    a.hours:Update()
    y = y + LBL + 28 + 16
    a.note:ClearAllPoints(); a.note:SetPoint("TOPLEFT", 0, -(y + LBL))
    y = y + LBL + 28 + 12
    -- who will be told: the same rule as the alert (recipe known, or the profession; any one when unknown)
    local prof = (cur ~= "" and PROFS[cur]) and PROFS[cur][2] or ""
    local me = UnitName("player")
    local who, on, off, online = O.Possible(id, prof), {}, {}, 0
    local n = 0
    for _, cr in ipairs(who) do
        if not cr.me and cr.name ~= me then
            n = n + 1
            if cr.online then online = online + 1; on[#on + 1] = S.Hex(C.ok) .. cr.name .. "|r" else off[#off + 1] = cr.name end
        end
    end
    if n == 0 then
        a.summary:SetText(L("Aucun artisan connu pour ce métier : toute la guilde verra quand même ta demande."))
    else
        local names = {}
        for _, s in ipairs(on) do if #names < 4 then names[#names + 1] = s end end
        for _, s in ipairs(off) do if #names < 4 then names[#names + 1] = s end end
        local list = table.concat(names, ", ") .. (n > #names and (" " .. S.Hex(C.muted) .. "+" .. (n - #names) .. "|r") or "")
        if n == 1 then a.summary:SetText(string.format(L("1 artisan prévenu : %s"), list))
        elseif online == 0 then a.summary:SetText(string.format(L("%d artisans prévenus, aucun en ligne : %s"), n, list))
        else a.summary:SetText(string.format(L("%d artisans prévenus, dont %d en ligne : %s"), n, online, list)) end
    end
    a.summary:ClearAllPoints(); a.summary:SetPoint("TOPLEFT", 0, -y)
    y = y + S.FitText(a.summary, 2, CW, c) + 16
    a.go:ClearAllPoints(); a.go:SetPoint("TOPLEFT", 0, -y)
    local gw = num(a.go:GetWidth()) or 160
    a.hint:ClearAllPoints(); a.hint:SetPoint("LEFT", a.go, "RIGHT", 12, 0)
    S.FitText(a.hint, 2, math.max(80, CW - gw - 12), c)
    y = y + 32
    c:SetHeight(y)
    Fit(pages.ask, a.sa, y)
end

-- The Request tab, filled in: an item (ID), a profession (a name in either language or an English
-- key), and from an earlier request its quantity, fee, note, title.
function WP.AskOrder(item, prof, from)
    if WP.ModuleOff and WP.ModuleOff("orders") then return end
    if not win then WP.ShowOrdersTab("find") end
    askState = { prof = "", hours = 24 }
    askNames = nil
    local key = prof and prof ~= "" and ProfKey(prof)
    for _, k in ipairs(ASK_PROFS) do if k == key then askState.prof, askState.picked = key, true end end
    if from and from.prof == "" then askState.picked = true end
    local text = ""
    if item and item ~= 0 then
        text = Name(item)
        askState.forced = { text = text, id = item }
    elseif from and from.title then text = from.title end
    local a = ui.ask
    a.box:SetText(text)
    a.qty:SetText(tostring(from and from.qty or 1))
    a.fee:SetText(from and (from.fee or 0) > 0 and tostring(math.floor(from.fee / 10000)) or "")
    a.note:SetText(from and from.note or "")
    a.box:SetError(nil)
    WP.ShowOrdersTab("ask")
end

-- ---------------------------------------------------------------- order cards
-- buttons placed left to right, wrapping to a new line when the card is too narrow; returns the height
local function FlowButtons(card, list, x0, y0, width)
    local x, y, lineH = x0, y0, 0
    for _, b in ipairs(list) do
        if b:IsShown() then
            local bw = num(b:GetWidth()) or 100
            if x > x0 and x + bw > x0 + width then x = x0; y = y + lineH + 8; lineH = 0 end
            b:ClearAllPoints(); b:SetPoint("TOPLEFT", card, "TOPLEFT", x, -y)
            x = x + bw + 8
            lineH = math.max(lineH, num(b:GetHeight()) or 28)
        end
    end
    return lineH > 0 and (y - y0 + lineH) or 0
end

local function OrderCard(parent)
    local c = CreateFrame("Frame", nil, parent)
    c.wlOwned = true
    S.Solid(c, "BACKGROUND", C.cardFill):SetAllPoints(); S.Border(c, C.cardEdge)
    c.iconFrame = Painted(c, 32); c.icon = c.iconFrame.tex
    c.iconFrame:SetPoint("TOPLEFT", 12, -12)
    c.title = S.Text(c, F.heading, C.fg); c.title:SetJustifyH("LEFT"); c.title:SetJustifyV("TOP")
    c.pill = S.Pill(c)
    c.fee = S.Text(c, F.label, C.gold); c.fee:SetJustifyH("RIGHT"); S.ClampLabel(c.fee, nil, c)
    c:EnableMouse(true)
    c:SetScript("OnEnter", function(self)
        local t = { self.title:GetText() or "" }
        if self.feeTip then t[#t + 1] = self.feeTip end
        S.Tip(self, t)
    end)
    c:SetScript("OnLeave", S.HideTip)
    c.who = S.Text(c, F.meta, C.muted); c.who:SetJustifyH("LEFT"); c.who:SetJustifyV("TOP")
    -- what to do now, in one sentence (a warning icon before it when it is your turn)
    c.next = S.Text(c, F.body, C.text); c.next:SetJustifyH("LEFT"); c.next:SetJustifyV("TOP")
    c.detail = S.Text(c, F.meta, C.muted); c.detail:SetJustifyH("LEFT"); c.detail:SetJustifyV("TOP")
    c.b1 = S.Button(c, "", 0, 28, "secondary", function(self) if c.a1 then c.a1(self) end end, function() return c.t1 or { c.b1:GetText() } end)
    c.b2 = S.Button(c, "", 0, 28, "secondary", function(self) if c.a2 then c.a2(self) end end, function() return c.t2 or { c.b2:GetText() } end)
    c.b3 = S.Button(c, "", 0, 28, "secondary", function() if c.o then WP.AskMessage(c.o) end end,
        function() return { c.b3:GetText(), L("Seuls le client et l'artisan voient ce message.") } end)
    c.b3:SetIcon("mail")
    function c:Fit(width)
        self:SetWidth(width)
        local pad = 12
        local x = pad + 32 + 8
        -- right cluster: commission and the status pill
        self.pill:ClearAllPoints(); self.pill:SetPoint("TOPRIGHT", -pad, -pad)
        local pw = self.pill:IsShown() and (num(self.pill:GetWidth()) or 60) or 0
        local feeW = 0
        if self.fee:IsShown() then
            local ok, sw = pcall(self.fee.GetStringWidth, self.fee)
            feeW = math.min(120, math.ceil((ok and num(sw)) or 60) + 1)
            self.fee:SetWidth(feeW)
            self.fee:ClearAllPoints(); self.fee:SetPoint("TOPRIGHT", -(pad + pw + (pw > 0 and 8 or 0)), -(pad + 2))
        end
        local rightW = pw + (pw > 0 and 8 or 0) + feeW + (feeW > 0 and 8 or 0)
        self.title:ClearAllPoints(); self.title:SetPoint("TOPLEFT", x, -pad)
        local th = S.FitText(self.title, 2, math.max(80, width - x - pad - rightW), self)
        self.who:ClearAllPoints(); self.who:SetPoint("TOPLEFT", self.title, "BOTTOMLEFT", 0, -3)
        local wh = S.FitText(self.who, 2, width - x - pad, self)
        local y = pad + math.max(32, th + 3 + wh)
        if self.next:IsShown() then
            y = y + 8
            self.next:ClearAllPoints(); self.next:SetPoint("TOPLEFT", pad, -y)
            y = y + S.FitText(self.next, 2, width - 2 * pad, self)
        end
        if self.detail:IsShown() then
            y = y + 4
            self.detail:ClearAllPoints(); self.detail:SetPoint("TOPLEFT", pad, -y)
            y = y + S.FitText(self.detail, 0, width - 2 * pad, self)
        end
        local bh = FlowButtons(self, { self.b1, self.b2, self.b3 }, pad, y + 12, width - 2 * pad)
        if bh > 0 then y = y + 12 + bh end
        local h = math.ceil(y + pad)
        self:SetHeight(h)
        return h
    end
    return c
end

-- a tip of 1 gold more, and where it goes
local function AddTip(o, b)
    O.AddTip(o, 10000)
    if o.status == "crafted" then
        WP.Print(string.format(L("Pourboire pour %s : %s au total. Il est payé à la réception (contre-remboursement) ou en échange."), o.by or "?", Money(o.tip)))
    else
        WP.Print(string.format(L("Pourboire pour %s : %s au total. Envoie-le par la poste ou en échange : l'addon ne déplace jamais d'or tout seul."), o.by or "?", Money(o.tip)))
    end
    WP.RefreshOrders()
    if b and b.Flash then b:Flash(L("Pourboire ajouté")) end
end

-- order again: a request (o.prof set, or no item) goes back to the Request tab, filled in
local function Reorder(o, crafter)
    if o.prof or not o.item or o.item == 0 then WP.AskOrder(o.item, o.prof, o)
    else WP.NewOrder(o.item, crafter, o) end
end

-- cards are repainted on every refresh (guild messages, item names): a button still showing the same
-- order and action keeps its armed confirmation or its flash; any other one starts clean
local function SetButton(b, label, icon, kind)
    local key = tostring(b.wlOrder) .. "|" .. label
    if b.wlFor == key and (b.armed or b.flashing) then return end
    b.wlFor = key
    b.flashToken, b.flashing = nil, nil
    b.armToken = nil
    b:SetKind(kind or "secondary")
    b:SetConfirm(nil); b.armed = nil
    b:SetIcon(icon)
    b:SetText(label)
end

-- built when painted, so they follow the language picked in the options
local function CancelTip() return { L("Annuler la commande"), L("La guilde ne la voit plus."), L("Clic : annuler (un second clic confirme)") } end
local function TipTip() return { L("Ajouter 1 po de pourboire"), L("Payé à la livraison ou en échange : l'addon ne déplace jamais d'or tout seul.") } end

local function PaintOrder(c, o, side)
    c.o = o
    c.b1.wlOrder, c.b2.wlOrder = o.id, o.id
    local me = UnitName("player")
    -- the item's icon (an enchant: its spell's; a request with no item: its profession's)
    local item = o.item or 0
    local tex
    if item ~= 0 then tex = ItemTex(item)
    else
        local pk = o.prof and o.prof ~= "" and ProfKey(o.prof)
        tex = pk and ProfIcon(pk) or "Interface\\Icons\\INV_Misc_QuestionMark"
    end
    S.Painted(c.icon, tex)
    local qc = item > 0 and S.QualityColor(item) or C.fg
    c.title:SetTextColor(qc[1], qc[2], qc[3])
    c.title:SetText((o.qty or 1) .. "× " .. Name(o))
    local money = (o.fee or 0) + (o.tip or 0)
    c.fee:SetText(money > 0 and Money(money) or ""); c.fee:SetShown(money > 0)
    c.feeTip = money > 0 and string.format(L("Commission et pourboire : %s"), Money(money)) or nil
    c.pill:Set(L(STATUS[o.status] or o.status), STATUS_COL[o.status] or C.fg, STATUS_ICON[o.status])
    -- for whom, by whom, until when
    local who
    if side == "mine" then
        who = o.to and string.format(L("Pour %s"), o.to) or L("Pour la guilde")
        if o.by then who = who .. " · " .. string.format(L("par %s"), o.by) .. Stars(o.by) end
    else
        who = string.format(L("De %s"), o.from or "?") .. " · " .. ((o.to == me) and L("pour toi") or (o.to and string.format(L("pour %s"), o.to) or L("pour la guilde")))
    end
    if o.status == "open" and o.expires then
        local hrs = math.floor((o.expires - time()) / 3600)
        who = who .. " · " .. (hrs >= 48 and string.format(L("expire dans %d jours"), math.floor(hrs / 24))
            or (hrs >= 1 and string.format(L("expire dans %d h"), hrs) or L("expire bientôt")))
    end
    c.who:SetText(who)
    local lines = {}
    if o.prof and o.prof ~= "" then lines[#lines + 1] = string.format(L("Métier : %s"), O.ProfName(o.prof)) end
    local missing, inBank = {}, false
    -- something still to send to the crafter: reagents, or an upfront payment
    local toSend = ((o.give and o.give ~= "") or (o.paid or 0) > 0) and not o.sentGive
    if side == "mine" and o.status == "accepted" and toSend then
        -- what to send to the crafter, with what you have (bags and bank) and what is missing
        local t = {}
        for _, g in ipairs(O.ToSend(o)) do
            local ok = g.have >= g.need
            local bank = g.bank or 0
            if not ok then missing[#missing + 1] = g end
            -- enough in all, but not in the bags: take them out of the bank first
            if ok and (g.have - bank) < g.need then inBank = true end
            local s = g.need .. "× " .. Name(g.id) .. " (" .. math.min(g.have, g.need) .. "/" .. g.need
                .. (bank > 0 and (", " .. string.format(L("dont %d en banque"), math.min(bank, g.need))) or "") .. ")"
            t[#t + 1] = ok and s or (S.Hex(C.bad) .. s .. "|r")
        end
        if (o.paid or 0) > 0 then t[#t + 1] = string.format(L("%s d'avance"), Money(o.paid)) end
        lines[#lines + 1] = string.format(L("À envoyer à %s : %s"), o.by or "?", table.concat(t, ", "))
    elseif o.give and o.give ~= "" then
        local s = side == "mine" and string.format(L("Tu fournis : %s"), Reagents(o.give, o.qty))
            or string.format(L("%s fournit : %s"), o.from or "?", Reagents(o.give, o.qty))
        if o.sentGive then s = s .. ", " .. S.Hex(C.ok) .. L("envoyés") .. "|r" end
        lines[#lines + 1] = s
    end
    if o.crafter and o.crafter ~= "" then
        if side == "recv" and o.status == "accepted" then
            -- the crafter's own share, with what they hold
            local t = {}
            for _, r in ipairs(O.Decode(o.crafter)) do
                local need = r[2] * (o.qty or 1)
                local have = WP.OwnedCount and WP.OwnedCount(r[1]) or 0
                local s = need .. "× " .. Name(r[1]) .. " (" .. math.min(have, need) .. "/" .. need .. ")"
                t[#t + 1] = have >= need and s or (S.Hex(C.bad) .. s .. "|r")
            end
            lines[#lines + 1] = string.format(L("Tu fournis : %s"), table.concat(t, ", "))
        else
            lines[#lines + 1] = string.format(L("L'artisan fournit : %s"), Reagents(o.crafter, o.qty))
        end
    end
    -- the next step, said plainly: whose turn it is and what to do
    local nxt, mineTurn = "", false
    local stt = o.status
    if side == "board" or (side == "recv" and stt == "open") then
        nxt, mineTurn = L("Accepte-la si tu peux la fabriquer."), true
    elseif side == "mine" and stt == "open" then
        nxt = L("En attente d'un artisan.")
    elseif side == "mine" and stt == "accepted" then
        if toSend then
            mineTurn = true
            if #missing > 0 then nxt = string.format(L("Il te manque des composants à envoyer à %s."), o.by or "?")
            elseif inBank then nxt = string.format(L("Sors les composants de la banque, puis envoie-les à %s par la poste ou en échange."), o.by or "?")
            else nxt = string.format(L("Envoie les composants à %s par la poste ou en échange."), o.by or "?") end
        else
            nxt = string.format(L("%s fabrique ta commande."), o.by or "?")
        end
    elseif side == "mine" and stt == "crafted" then
        nxt = string.format(L("Fabriquée : %s te l'envoie par la poste ou en échange."), o.by or "?")
    elseif side == "recv" and stt == "accepted" then
        -- with no item ID the addon cannot see it in the bags: the button says it
        nxt, mineTurn = (item > 0) and L("Fabrique l'objet : l'addon le voit tout seul dans tes sacs.") or L("Fabrique-la, puis marque-la comme fabriquée."), true
    elseif side == "recv" and stt == "crafted" then
        nxt, mineTurn = string.format(L("Livre-la à %s par la poste ou en échange."), o.from or "?"), true
    elseif stt == "delivered" then
        nxt = L("Commande terminée.")
    elseif side == "mine" and stt == "declined" then
        nxt = string.format(L("Refusée par %s : Commander à nouveau la propose à toute la guilde."), o.by or "?")
    end
    -- your turn: a warning icon before the sentence, the sentence itself in the text colour
    c.next:SetText((mineTurn and nxt ~= "") and (S.IconMarkup("warning", 14, C.warn) .. " " .. nxt) or nxt); c.next:SetShown(nxt ~= "")
    c.next:SetTextColor(C.text[1], C.text[2], C.text[3])
    -- what reached the crafter (read in the crafter's mailbox)
    if side == "recv" and o.status == "accepted" then
        local got, gold = O.Received(o)
        local parts, all = {}, true
        for _, g in ipairs(got) do
            parts[#parts + 1] = math.min(g.have, g.need) .. "/" .. g.need .. " " .. Name(g.id)
            if g.have < g.need then all = false end
        end
        local paid = (o.paid or 0)
        if paid > 0 then parts[#parts + 1] = string.format(L("or : %s sur %s"), Money(math.min(gold, paid)), Money(paid)); if gold < paid then all = false end end
        if #parts > 0 then lines[#lines + 1] = string.format(L("Reçu : %s"), all and (S.Hex(C.ok) .. L("tout est arrivé") .. "|r") or table.concat(parts, ", ")) end
    end
    if o.reason then lines[#lines + 1] = string.format(L("Raison : %s"), S.Hex(C.bad) .. L(o.reason) .. "|r") end
    if o.note and o.note ~= "" then lines[#lines + 1] = string.format(L("« %s »"), o.note) end
    -- the steps so far, and the last messages between customer and crafter
    if o.log and #o.log > 1 then
        local t = {}
        for i, e in ipairs(o.log) do
            local w = L(STATUS[e.s] or e.s)
            if i > 1 then w = w:lower() end
            t[#t + 1] = w .. " " .. Clock(e.t)
        end
        lines[#lines + 1] = string.format(L("Suivi : %s"), table.concat(t, ", "))
    end
    for i = math.max(1, #(o.msgs or {}) - 2), #(o.msgs or {}) do
        local m = o.msgs[i]
        local cls = O.ClassOf and O.ClassOf(m.from)
        local cc = cls and RAID_CLASS_COLORS and RAID_CLASS_COLORS[cls]
        lines[#lines + 1] = string.format(L("%s : %s"), (cc and S.Hex({ cc.r, cc.g, cc.b }) or S.Hex(C.fg)) .. m.from .. "|r", m.text)
    end
    c.detail:SetText(table.concat(lines, "\n")); c.detail:SetShown(#lines > 0)
    -- buttons by side and status
    c.a1, c.a2, c.t1, c.t2 = nil, nil, nil, nil
    local by = o.by or "?"
    if side == "board" then
        SetButton(c.b1, L("Accepter"), "check"); c.t1 = { L("Accepter"), L("Clic : accepter cette commande") }
        c.a1 = function() O.Accept(o); WP.ShowOrdersTab("recv") end
        if o.to then
            -- sent to me: a real refusal, with its reason
            SetButton(c.b2, L("Refuser"), "close"); c.t2 = { L("Refuser"), L("Clic : choisir la raison du refus") }
            c.a2 = function() WP.AskDecline(o) end
        else
            -- a guild order: only hidden here, the others still see it
            SetButton(c.b2, L("Masquer"), "minus"); c.t2 = { L("Masquer"), L("Seulement pour toi : le reste de la guilde la voit toujours."), L("Clic : masquer cette commande") }
            c.a2 = function() O.Decline(o, "Autre") end
        end
    elseif side == "recv" and o.status == "open" then
        SetButton(c.b1, L("Accepter"), "check"); c.t1 = { L("Accepter"), L("Clic : accepter cette commande") }
        c.a1 = function() O.Accept(o) end
        if o.to then
            SetButton(c.b2, L("Refuser"), "close"); c.t2 = { L("Refuser"), L("Clic : choisir la raison du refus") }
            c.a2 = function() WP.AskDecline(o) end
        else
            -- a guild order I can craft: only hidden here, its customer is not told
            SetButton(c.b2, L("Masquer"), "minus"); c.t2 = { L("Masquer"), L("Seulement pour toi : le reste de la guilde la voit toujours."), L("Clic : masquer cette commande") }
            c.a2 = function() O.Decline(o, "Autre") end
        end
    elseif side == "recv" and o.status == "accepted" then
        SetButton(c.b1, L("Marquer fabriquée"), "hammer"); c.a1 = function() O.Crafted(o) end
        c.t1 = { L("Marquer fabriquée"), string.format(L("%s est prévenu que sa commande est prête."), o.from or "?") }
    elseif side == "recv" and o.status == "crafted" then
        SetButton(c.b1, L("Marquer livrée"), "check"); c.a1 = function() O.Delivered(o) end
        c.t1 = { L("Marquer livrée"), L("Si tu l'as remise en échange ou si l'addon ne l'a pas vue partir.") }
    elseif side == "mine" and o.status == "accepted" and #missing > 0 then
        SetButton(c.b1, P(#missing, L("Acheter 1 composant"), L("Acheter %d composants")), "coin")
        c.t1 = { c.b1:GetText(), L("À l'HV : chaque achat ouvre le suivant.") }
        c.a1 = function()
            if not (WP.AuctionHouseOpen and WP.AuctionHouseOpen()) then
                WP.Print(L("L'HV n'est pas ouvert : parle à un commissaire-priseur, puis reclique sur Acheter.")); return
            end
            -- every missing reagent in one chain: the next buy page opens after each purchase
            local q = {}
            for _, g in ipairs(missing) do q[#q + 1] = { id = g.id, qty = g.need - g.have } end
            if WP.Scan and WP.Scan.BuyQueue then WP.Scan.BuyQueue(q)
            elseif WP.Scan and WP.Scan.OpenToBuy then WP.Scan.OpenToBuy(missing[1].id, missing[1].need - missing[1].have) end
        end
        SetButton(c.b2, L("Annuler la commande"), "trash", "danger"); c.b2:SetConfirm(L("Confirmer l'annulation")); c.t2 = CancelTip()
        c.a2 = function() O.Cancel(o) end
    elseif side == "mine" and o.status == "accepted" and toSend then
        SetButton(c.b1, L("Préparer le courrier"), "mail")
        c.t1 = { L("Préparer le courrier"), L("À la boîte aux lettres, l'addon remplit le destinataire, les composants et l'or.") }
        c.a1 = function()
            if MailFrame and MailFrame:IsShown() then
                if MailFrameTab2 and not (SendMailFrame and SendMailFrame:IsShown()) then MailFrameTab2:Click() end
                O.FillMail(o, "give")
            else WP.Print(string.format(L("Aucune boîte aux lettres ouverte : va à une boîte aux lettres, ou échange les composants avec %s."), by)) end
        end
        SetButton(c.b2, L("Annuler la commande"), "trash", "danger"); c.b2:SetConfirm(L("Confirmer l'annulation")); c.t2 = CancelTip()
        c.a2 = function() O.Cancel(o) end
    elseif side == "mine" and (o.status == "open" or o.status == "accepted") then
        SetButton(c.b2, L("Annuler la commande"), "trash", "danger"); c.b2:SetConfirm(L("Confirmer l'annulation")); c.t2 = CancelTip()
        c.a2 = function() O.Cancel(o) end
    elseif side == "mine" and o.status == "crafted" then
        -- by hand when the addon could not see it arrive (an enchant, a mail still in the inbox)
        SetButton(c.b1, L("Marquer reçue"), "check")
        c.t1 = { L("Marquer reçue"), L("Si l'addon ne l'a pas vue arriver (enchantement, courrier pas encore ouvert).") }
        c.a1 = function() O.Delivered(o) end
        SetButton(c.b2, L("Ajouter 1 po de pourboire"), "coin"); c.a2 = function(b) AddTip(o, b) end; c.t2 = TipTip()
    elseif side == "mine" and o.status == "delivered" then
        if not o.thanked and o.by then
            SetButton(c.b1, L("Remercier"), "star"); c.t1 = { L("Remercier"), string.format(L("Clic : donner une étoile à %s"), by) }
            c.a1 = function() O.Thank(o) end
        else
            SetButton(c.b1, L("Commander à nouveau"), "refresh"); c.t1 = { L("Commander à nouveau"), L("Clic : refaire la même commande") }
            c.a1 = function() Reorder(o, o.by) end
        end
        SetButton(c.b2, L("Ajouter 1 po de pourboire"), "coin"); c.a2 = function(b) AddTip(o, b) end; c.t2 = TipTip()
    elseif side == "mine" and (o.status == "cancelled" or o.status == "expired" or o.status == "declined") then
        SetButton(c.b1, L("Commander à nouveau"), "refresh")
        c.t1 = { L("Commander à nouveau"), o.status == "declined" and L("Clic : la proposer à toute la guilde") or L("Clic : refaire la même commande") }
        c.a1 = function() Reorder(o, o.status == "declined" and nil or o.to) end
    end
    -- messages: between the customer and the crafter, once someone took the order
    local other = (me == o.from) and o.by or o.from
    c.b3:SetShown(o.by ~= nil and (o.status == "accepted" or o.status == "crafted" or o.status == "delivered")
        and (me == o.from or me == o.by))
    if c.b3:IsShown() then c.b3:SetText(string.format(L("Écrire à %s"), other or "?")) end
    c.b1:SetShown(c.a1 ~= nil); c.b2:SetShown(c.a2 ~= nil)
    if not c.a1 then c.b1.wlFor = nil end
    if not c.a2 then c.b2.wlFor = nil end
    return c:Fit(CW)
end

local EMPTY = {
    board = function()
        if WLWritsDB.ordersBoardMine ~= false then
            return "hammer", L("Aucune commande pour tes métiers"), L("Les commandes que tu sais fabriquer apparaîtront ici."),
                L("Voir toutes les commandes"), function() WLWritsDB.ordersBoardMine = false; WP.RefreshOrders() end, "secondary"
        end
        return "hammer", L("Aucune commande ouverte"), L("Les commandes des membres de la guilde apparaîtront ici."),
            L("Faire une demande"), function() WP.ShowOrdersTab("ask") end, "primary"
    end,
    mine = function()
        return "bag", L("Tu n'as rien commandé"), L("Tes commandes et leur suivi apparaîtront ici."),
            L("Faire une demande"), function() WP.ShowOrdersTab("ask") end, "primary"
    end,
    recv = function()
        return "hammer", L("Aucune commande pour toi"), L("Les commandes qu'un membre t'adresse, ou que tu acceptes, apparaîtront ici."),
            L("Voir les commandes ouvertes"), function() WP.ShowOrdersTab("board") end, "secondary"
    end,
}

local function BuildOrders(p, key)
    ui[key].list = List(p, OrderCard)
    ui[key].empty = S.EmptyState(ui[key].list.content, "hammer", "", nil, nil, nil)
end
local function RenderOrders(key, list)
    local u = ui[key]
    local p = pages[key]
    local y = 0
    for i, o in ipairs(list) do
        local c = u.list.Get(i)
        local h = PaintOrder(c, o, key)
        c:ClearAllPoints(); c:SetPoint("TOPLEFT", 0, -y)
        y = y + h + 12
    end
    if #list > 0 then y = y - 12 end
    u.list.HideFrom(#list + 1)
    if #list == 0 then
        local icon, title, text, label, click, kind = EMPTY[key]()
        y = Empty(u.empty, true, icon, title, text, label, click, kind)
    else u.empty:Hide() end
    u.list.content:SetHeight(math.max(1, y))
    Fit(p, u.list, y)
end

-- ---------------------------------------------------------------- message and decline windows
-- a message on an order (a small window)
local msgBox
function WP.AskMessage(o)
    if not msgBox then
        msgBox = S.Window("WLHelperOrderMsg", 360, 160, L("Message"), nil, nil, nil, { header = 44, noHome = true, minH = 120 })
        local top = msgBox:ContentTop() + 12
        msgBox.eb = S.Input(msgBox, 360 - 2 * PAD, { label = L("Ton message"), placeholder = L("Ex. Les composants arrivent ce soir") })
        msgBox.eb:SetPoint("TOPLEFT", PAD, -(top + LBL)); msgBox.eb:SetMaxLetters(120)
        msgBox.send = S.Button(msgBox, L("Envoyer le message"), 0, 32, "primary", function()
            if msgBox.order then O.Say(msgBox.order, msgBox.eb:GetText()) end
            msgBox.eb:SetText(""); msgBox:Hide()
        end)
        msgBox.send:SetIcon("mail")
        msgBox.send:SetPoint("TOPLEFT", PAD, -(top + LBL + 28 + 16))
        msgBox.eb:SetScript("OnEnterPressed", function() msgBox.send:Click() end)
    end
    msgBox.order = o
    local me = UnitName("player")
    local other = (o.from == me) and o.by or o.from
    msgBox.title:SetText(string.format(L("Message à %s"), other or "?"))
    msgBox.subtitle:SetText((o.qty or 1) .. "× " .. Name(o))
    msgBox:Show(); msgBox.eb:SetFocus()
    msgBox:FitHeight(LBL + 28 + 16 + 32)
end

-- decline with a reason (a small window of reasons; the reason's French key travels)
local declineMenu
function WP.AskDecline(o)
    if not declineMenu then
        declineMenu = S.Window("WLHelperDecline", 360, 300, L("Refuser la commande"), nil, nil, nil, { header = 44, noHome = true, minH = 120 })
        local top = declineMenu:ContentTop() + 12
        local cw = 360 - 2 * PAD
        declineMenu.text = S.Text(declineMenu, F.label, C.muted); declineMenu.text:SetJustifyH("LEFT"); declineMenu.text:SetJustifyV("TOP")
        declineMenu.text:SetPoint("TOPLEFT", PAD, -top)
        declineMenu.text:SetText(L("Choisis la raison : le client la verra."))
        declineMenu.buttons = {}
        for _, r in ipairs({ "Commission trop basse", "Pas les composants", "Pas le temps", "Recharge en cours", "Autre" }) do
            local b = S.Button(declineMenu, L(r), cw, 28, "secondary", function()
                if declineMenu.order then O.Decline(declineMenu.order, r) end
                declineMenu:Hide()
            end)
            declineMenu.buttons[#declineMenu.buttons + 1] = b
        end
        function declineMenu:Layout()
            local y = top
            local th = S.FitText(self.text, 2, cw, self)
            y = y + th + 12
            for _, b in ipairs(self.buttons) do
                b:ClearAllPoints(); b:SetPoint("TOPLEFT", PAD, -y)
                y = y + 28 + 8
            end
            return y - 8 - top
        end
    end
    declineMenu.order = o
    declineMenu.subtitle:SetText((o.qty or 1) .. "× " .. Name(o))
    declineMenu:Show()
    declineMenu:FitHeight(declineMenu:Layout())
end

-- ---------------------------------------------------------------- the window
local function Build()
    win = S.Window("WLHelperOrders", W, 400, L("Commandes"), L("Faire fabriquer par la guilde"), WLWritsDB, "ordersPos",
        { header = 44, minH = 280 })
    tabs = S.Tabs(win, { { "find", L("Artisans") }, { "ask", L("Demande") }, { "board", L("Ouvertes") }, { "mine", L("Mes commandes") }, { "recv", L("Pour moi") } },
        function() return current == "new" and "find" or current end, function(k) WP.ShowOrdersTab(k) end, function(k)
            if k == "find" or k == "ask" then return nil end
            if k == "board" then local n = #O.Board(WLWritsDB.ordersBoardMine ~= false); return n > 0 and n or nil end
            local mine, forMe = O.Lists()
            local n = 0
            -- orders for me waiting for my answer: they count as things to do now
            if k == "recv" then for _, o in ipairs(forMe) do if o.status == "open" then n = n + 1 end end; return n > 0 and n or nil, true end
            for _, o in ipairs(mine) do if o.status == "accepted" or o.status == "crafted" then n = n + 1 end end
            return n > 0 and n or nil
        end)
    tabs:SetPoint("TOPLEFT", 0, -(win.headerH + 1)); tabs:SetPoint("TOPRIGHT", 0, -(win.headerH + 1))
    local top = win:ContentTop() + 12
    for _, k in ipairs({ "find", "ask", "new", "board", "mine", "recv" }) do
        local p = CreateFrame("Frame", nil, win)
        p:SetPoint("TOPLEFT", PAD, -top); p:SetPoint("BOTTOMRIGHT", -PAD, 12)
        p.topH = 0
        p:Hide()
        pages[k] = p
    end
    BuildFind(pages.find); BuildAsk(pages.ask); BuildNew(pages.new); BuildOrders(pages.mine, "mine"); BuildOrders(pages.recv, "recv")
    -- the board: the guild's open orders, all of them or only what you make
    local bp = pages.board
    local only = CreateFrame("Button", nil, bp)
    only:SetHeight(28); only:SetPoint("TOPLEFT"); only:SetPoint("TOPRIGHT")
    ui.board.only = S.Switch(only, function() return WLWritsDB.ordersBoardMine ~= false end,
        function(v) WLWritsDB.ordersBoardMine = v; WP.RefreshOrders() end)
    ui.board.only:SetPoint("RIGHT", 0, 0)
    local ol = S.Text(only, F.label, C.text); ol:SetJustifyH("LEFT"); ol:SetPoint("LEFT", 0, 0); ol:SetText(L("Seulement ce que je sais fabriquer"))
    ol:SetWidth(CW - 40 - 12); S.ClampLabel(ol, nil, only)
    ui.board.only:AttachRow(only)
    bp.topH = 28 + 12
    ui.board.list = List(bp, OrderCard)
    ui.board.list.Top(bp.topH)
    ui.board.empty = S.EmptyState(ui.board.list.content, "hammer", "", nil, nil, nil)
    win:SetScript("OnShow", function()
        -- warm the item cache so the search can match names the client has not seen yet
        if C_Item and C_Item.RequestLoadItemDataByID then
            for id in pairs(O.Catalog()) do if id > 0 then pcall(C_Item.RequestLoadItemDataByID, id) end end
        end
        if O.AskRecipes then O.AskRecipes() end; WP.RefreshOrders()
    end)
end

function WP.ShowOrdersTab(k)
    if not win then Build() end
    current = k
    if WP.ordersPendingTab == k then WP.ordersPendingTab = nil end
    if k == "ask" then askNames = nil end
    for key, p in pairs(pages) do p:SetShown(key == k) end
    win:Show()
    WP.RefreshOrders()
    -- wrapped text measures right once its width is applied: measure again on the next frame
    if C_Timer and C_Timer.After then
        C_Timer.After(0, function() if win:IsShown() and current == k then WP.RefreshOrders() end end)
    end
end

function WP.RefreshOrders()
    if WP.RefreshMailPanel then WP.RefreshMailPanel() end
    if not (win and win:IsShown()) then return end
    tabs:Update()
    if current ~= "find" then win.subtitle:SetText(L("Faire fabriquer par la guilde")) end
    if current == "find" then RenderFind()
    elseif current == "new" then RenderNew()
    elseif current == "ask" then RenderAsk()
    elseif current == "board" then
        ui.board.only:Update()
        RenderOrders("board", O.Board(WLWritsDB.ordersBoardMine ~= false))
    else
        local mine, forMe = O.Lists()
        if current == "mine" then RenderOrders("mine", mine) else RenderOrders("recv", forMe) end
    end
end

-- /wlh orders, the home card: after a chat line about an order (Orders.lua sets WP.ordersPendingTab),
-- the tab that line names; otherwise the last tab used. Already open on another tab: go there.
function WP.ToggleOrders()
    local want = WP.ordersPendingTab
    WP.ordersPendingTab = nil
    if win and win:IsShown() then
        if want and want ~= current then WP.ShowOrdersTab(want) else win:Hide() end
        return
    end
    if WP.ModuleOff and WP.ModuleOff("orders") then return end
    if not win then Build() end
    WP.ShowOrdersTab(want or (current == "new" and "find" or current))
end

-- item names arriving from the server: redraw once (names and search results were "item:N")
local itemEv, itemPend = CreateFrame("Frame"), false
pcall(itemEv.RegisterEvent, itemEv, "GET_ITEM_INFO_RECEIVED")
itemEv:SetScript("OnEvent", function()
    askNames = nil   -- a recipe's name may have just arrived
    if win and win:IsShown() and not itemPend then
        itemPend = true
        C_Timer.After(0.3, function() itemPend = false; WP.RefreshOrders() end)
    end
end)

-- ---------------------------------------------------------------- beside the mailbox
local panel
local PANEL_W = 280
local function MailActions()
    local me = UnitName("player")
    local acts = {}
    for _, o in pairs(O.DB().list) do
        if o.from == me and o.status == "accepted" and ((o.give and o.give ~= "") or (o.paid or 0) > 0) and not o.sentGive then
            acts[#acts + 1] = { o = o, kind = "give", to = o.by or "?" }
        elseif o.by == me and o.status == "crafted" and (o.item or 0) > 0 then
            acts[#acts + 1] = { o = o, kind = "deliver", to = o.from }
        end
    end
    return acts
end

function WP.RefreshMailPanel()
    if not (MailFrame and MailFrame:IsShown()) then if panel then panel:Hide() end; return end
    local acts = MailActions()
    if #acts == 0 then if panel then panel:Hide() end; return end
    local cw = PANEL_W - 24
    if not panel then
        panel = CreateFrame("Frame", "WLHelperMailOrders", MailFrame)
        panel.wlOwned = true
        panel:SetWidth(PANEL_W); panel:SetPoint("TOPLEFT", MailFrame, "TOPRIGHT", 6, -20)
        S.Solid(panel, "BACKGROUND", C.bg):SetAllPoints(); S.Border(panel, C.cardEdge)
        panel.title = S.Text(panel, F.heading, C.fg); panel.title:SetPoint("TOPLEFT", 12, -12); panel.title:SetText(L("Commandes à poster"))
        panel.title:SetWidth(cw); S.ClampLabel(panel.title, nil, panel)
        panel.text = S.Text(panel, F.meta, C.muted); panel.text:SetJustifyH("LEFT"); panel.text:SetJustifyV("TOP")
        panel.text:SetText(L("Un clic remplit le courrier. Vérifie-le, puis clique sur Envoyer."))
        panel.rows = {}
    end
    local y = 12 + F.heading + 4
    panel.text:ClearAllPoints(); panel.text:SetPoint("TOPLEFT", 12, -y)
    y = y + S.FitText(panel.text, 2, cw, panel) + 12
    for i, a in ipairs(acts) do
        local r = panel.rows[i]
        if not r then
            r = CreateFrame("Frame", nil, panel)
            r.iconFrame = Painted(r, 28); r.iconFrame:SetPoint("TOPLEFT", 0, 0)
            r.text = S.Text(r, F.label, C.fg); r.text:SetJustifyH("LEFT"); r.text:SetJustifyV("TOP")
            r.text:SetPoint("TOPLEFT", 36, 0)
            r.sub = S.Text(r, F.meta, C.muted); r.sub:SetJustifyH("LEFT"); r.sub:SetJustifyV("TOP")
            r.sub:SetPoint("TOPLEFT", r.text, "BOTTOMLEFT", 0, -3)
            r.btn = S.Button(r, L("Préparer le courrier"), cw, 28, "secondary", function()
                if MailFrameTab2 and not (SendMailFrame and SendMailFrame:IsShown()) then MailFrameTab2:Click() end
                panel.pending = nil
                local missing = O.FillMail(r.act.o, r.act.kind)
                if not missing then return end
                if #missing > 0 then
                    local t = {}
                    for _, m in ipairs(missing) do t[#t + 1] = m[2] .. "× " .. Name(m[1]) end
                    WP.Print(string.format(L("Il manque dans tes sacs : %s. Sors-les de la banque ou achète-les, puis reclique."), table.concat(t, ", ")))
                    return
                end
                -- noted once this very mail leaves (same recipient), see SendMail below
                panel.pending = r.act
                panel.pendingTo = (r.act.kind == "give" and (r.act.o.by or r.act.o.to) or r.act.o.from)
                r.btn:Flash(L("Prêt, clique sur Envoyer"), 4)
            end)
            r.btn:SetIcon("mail")
            panel.rows[i] = r
        end
        r.act = a
        r:SetWidth(cw)
        S.Painted(r.iconFrame.tex, ItemTex(a.o.item or 0))
        r.text:SetText((a.o.qty or 1) .. "× " .. Name(a.o))
        local qc = (a.o.item or 0) > 0 and S.QualityColor(a.o.item) or C.fg
        r.text:SetTextColor(qc[1], qc[2], qc[3])
        r.sub:SetText(string.format(a.kind == "give" and L("Pour %s · composants") or L("Pour %s · livraison"), a.to or "?"))
        local th = S.FitText(r.text, 2, cw - 36, r) + 3 + S.FitText(r.sub, 1, cw - 36, r)
        local top = math.max(28, math.ceil(th)) + 8
        r.btn:ClearAllPoints(); r.btn:SetPoint("TOPLEFT", 0, -top)
        local rh = top + 28
        r:SetHeight(rh)
        r:ClearAllPoints(); r:SetPoint("TOPLEFT", 12, -y)
        r:Show()
        y = y + rh + 16
    end
    for i = #acts + 1, #panel.rows do panel.rows[i]:Hide() end
    panel:SetHeight(math.ceil(y - 16 + 12))
    panel:Show()
end

-- the mail actually sent: only the one to the order's recipient counts
local sending
if SendMail then
    hooksecurefunc("SendMail", function(to)
        sending = panel and panel.pending and type(to) == "string"
            and to:gsub("%-.*$", ""):lower() == (panel.pendingTo or ""):lower() and panel.pending or nil
    end)
end
local mf = CreateFrame("Frame")
pcall(mf.RegisterEvent, mf, "MAIL_SHOW"); pcall(mf.RegisterEvent, mf, "MAIL_CLOSED"); pcall(mf.RegisterEvent, mf, "MAIL_SEND_SUCCESS"); pcall(mf.RegisterEvent, mf, "MAIL_FAILED")
mf:SetScript("OnEvent", function(_, e)
    if e == "MAIL_SEND_SUCCESS" and sending then
        -- the mail of an order left: note it (reagents sent, or the order delivered)
        local a = sending; sending = nil
        if panel then panel.pending = nil end
        if a.kind == "give" then a.o.sentGive = true else O.Delivered(a.o) end
    elseif e == "MAIL_FAILED" or e == "MAIL_CLOSED" then
        sending = nil
        if e == "MAIL_CLOSED" and panel then panel.pending = nil end
    elseif e == "MAIL_SEND_SUCCESS" then
        sending = nil
    end
    C_Timer.After(0.2, function() if WP.RefreshMailPanel then WP.RefreshMailPanel() end end)
end)
