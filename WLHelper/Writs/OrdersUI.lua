-- Writs/OrdersUI.lua: the Orders window (the guild's crafters by profession, a request, the open
-- orders, my orders, the orders for me) and the panel beside the mailbox that fills the mail for an
-- order. Engine: Orders.lua. Drawn with the design system (Style.lua): one 640 px window that fits
-- its content, HD icons for glyphs, painted game icons for things, text that wraps or shows its full
-- text in the tooltip. Words shared with the summary: levels in words ("Utilisable dès le niv. 30",
-- never a bare "Niv. 30"), counts with their unit ("Mylla · 12 recettes"), and a card says each fact
-- once (the pill gives the state, the sentence under it only what to do next).
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
    ["Choisis un métier à gauche pour voir son catalogue, ou cherche un objet ci-dessus."] =
        "Pick a profession on the left to see its catalogue, or search for an item above.",
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
    ["Utilisable dès le niv. %d"] = "Usable from level %d",
    ["Composants inconnus"] = "Reagents unknown",
    ["Peuvent le fabriquer : %s"] = "Can craft it: %s",
    ["Clic : commander à %s"] = "Click: order from %s",
    ["Clic : commander à la guilde"] = "Click: order from the guild",
    ["Maj-clic : demander à toute la guilde"] = "Shift-click: ask the whole guild",
    ["Artisans :"] = "Crafters:",
    ["Artisan :"] = "Crafter:",
    ["1 autre artisan"] = "1 more crafter",
    ["%d autres artisans"] = "%d more crafters",
    ["Clic : voir tous les artisans"] = "Click: show every crafter",
    ["Réduire"] = "Show less",
    ["Clic : n'afficher que les premiers artisans"] = "Click: show only the first crafters",
    ["Clic : voir les recettes de %s"] = "Click: see %s's recipes",
    ["Artisans : %s · %d en tout"] = "Crafters: %s · %d in all",
    ["aucun en ligne"] = "none online",
    ["Chercher un artisan"] = "Search for a crafter",
    ["Clic : chercher un artisan et voir ses recettes"] = "Click: search for a crafter and see their recipes",
    ["rien de partagé"] = "nothing shared",
    ["Aucun artisan ne correspond à ce nom."] = "No crafter matches this name.",
    ["en ligne"] = "online",
    ["hors ligne"] = "offline",
    ["vu il y a %d jours"] = "seen %d days ago",
    ["vu il y a plus d'un mois"] = "seen over a month ago",
    ["vu hier"] = "seen yesterday",
    ["toi"] = "you",
    ["(toi)"] = "(you)",
    ["Pas encore de recettes partagées par %s. Elles arrivent quand ce membre ouvre sa fenêtre de métier."] =
        "No recipes shared yet by %s. They show up when this member opens their profession window.",
    ["Ouvre ta fenêtre de métier pour partager les tiennes."] = "Open your profession window to share yours.",
    ["%d étoiles reçues pour des commandes livrées"] = "%d stars received for delivered orders",
    ["1 étoile reçue pour une commande livrée"] = "1 star received for a delivered order",
    ["Clic : commander à toute la guilde (le premier artisan qui accepte s'en charge)"] = "Click: order from the whole guild (the first crafter to accept takes it)",
    ["Clic : commander à %s, le seul artisan qui sait le fabriquer"] = "Click: order from %s, the only crafter who can make it",
    ["Maj-clic : commander à %s seulement"] = "Shift-click: order from %s only",
    ["Affine la recherche pour voir la suite (%d objets affichés sur %d)."] = "Narrow the search to see the rest (%d of %d items shown).",
    -- the catalogue's categories
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
    ["Ouverte pendant"] = "Open for",
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
    ["Ton mot : « %s »"] = "Your note: \"%s\"",
    ["Mot de %s : « %s »"] = "Note from %s: \"%s\"",
    ["Historique : %s"] = "History: %s",
    ["%s : %s"] = "%s: %s",
    ["Accepte-la si tu peux la fabriquer."] = "Accept it if you can craft it.",
    ["En attente d'un artisan."] = "Waiting for a crafter.",
    ["Il te manque des composants à envoyer à %s."] = "You are missing reagents to send to %s.",
    ["Sors les composants de la banque, puis envoie-les à %s par la poste ou en échange."] =
        "Take the reagents out of the bank, then send them to %s by mail or trade.",
    ["Envoie les composants à %s par la poste ou en échange."] = "Send the reagents to %s by mail or trade.",
    ["%s fabrique ta commande."] = "%s is crafting your order.",
    ["%s te l'envoie par la poste ou en échange."] = "%s sends it to you by mail or trade.",
    ["Tu l'as reçue. Remercie %s pour lui donner une étoile."] = "You got it. Thank %s to give them a star.",
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
    ["Tes commandes et leur historique apparaîtront ici."] = "Your orders and their history will show up here.",
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
-- The Crafters tab in two columns (T-55, T-57): the professions on the left (200), a 1 px rule at
-- x = 216 of the page, what you look at on the right (376, from x = 232): the search and your
-- sharing, a profession's catalogue, a search's results or a crafter's recipes.
-- 200 + 16 + 1 + 15 + 376 = 608. While nobody shares anything, the page stays one column.
local LW = 200
local RULE_X = LW + 16
local RX = RULE_X + 1 + 15
local RW = CW - RX
local findW = CW   -- the width of the Crafters tab's right side (CW while it is one column)
local win, tabs, pages, current = nil, nil, {}, "find"
local ui = { find = {}, mine = {}, recv = {}, new = {}, board = {}, ask = {} }
WP.OrdersUI = ui   -- the pages' widgets, for the offline tests
-- the crafters' home and its pages (T-60): its functions, filled before RenderFind
local H = {}
ui.H = H

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
    -- l.Top(y): the page's width; l.Top(y, x, w): a column x from the page's left, w wide
    function l.Top(y, x, w)
        sa:ClearAllPoints()
        if x then
            sa:SetPoint("TOPLEFT", x, -y); sa:SetPoint("BOTTOMLEFT", x, 0)
            sa:SetWidth(w); sa.child:SetWidth(w)
        else
            sa:SetPoint("TOPLEFT", 0, -y); sa:SetPoint("BOTTOMRIGHT", 0, 0); sa.child:SetWidth(CW)
        end
    end
    function l.Reset() sa:ScrollTo(0, true) end
    return l
end

-- the window takes the page's height: its fixed top plus its list
local function Fit(page, list, listH)
    listH = math.max(0, math.ceil(listH or 0))
    local sa = list and (list.sf or list)
    -- page.sideH: a column beside the list (the professions of the Crafters tab) that may be taller
    if win then win:FitHeight(math.max((page.topH or 0) + listH, page.sideH or 0)) end
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
        -- icon actions (watch, favourite, remove), left of the buttons; never counted as buttons
        for i = #(self.acts or {}), 1, -1 do
            local b = self.acts[i]
            if b:IsShown() then
                b:ClearAllPoints(); b:SetPoint("RIGHT", self, "RIGHT", -right, 0)
                right = right + 24 + 4
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
    e:SetWrapWidth(e.wlW or CW)
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

local CAT_MAX = 200   -- catalogue rows drawn at most (the search narrows the rest)

-- The guild's crafts by profession, read once per render:
-- [key] = { crafters = { c }, items = { [id] = { id, re, who = { c }, online } }, nItems, nOnline, unshared = { names } }
-- c = { name, prof, rank, online, me, n = recipes shared, stars }
-- Kept between renders while nothing it reads has changed: a keystroke in the search redraws the
-- left column without building every item again. The stamp reads the crafters' entries (each list
-- arrives as a new table with its hash), a checksum of each list (one walk, nothing allocated),
-- their rank and stars, and who is online (a new table every 30 s).
local gcCache, gcStamp
local function CraftsStamp(on, me)
    local s = { on, me }
    local function Put(name, prof, p)
        s[#s + 1] = name; s[#s + 1] = prof; s[#s + 1] = p
        if type(p) == "table" then
            -- a list changed in place still shows: its count, the sum of its ids and of its reagent lengths
            local n, ids, len = 0, 0, 0
            if type(p.recipes) == "table" then
                for id, re in pairs(p.recipes) do
                    n = n + 1
                    if type(id) == "number" then ids = ids + id end
                    if type(re) == "string" then len = len + #re end
                end
            end
            s[#s + 1] = p.recipes or false; s[#s + 1] = n; s[#s + 1] = ids; s[#s + 1] = len
            s[#s + 1] = p.hash or false; s[#s + 1] = p.rank or 0
        end
    end
    for name, profs in pairs(O.DB().crafters) do
        s[#s + 1] = profs
        if type(profs) == "table" then
            s[#s + 1] = O.Stars(name)
            for prof, p in pairs(profs) do Put(name, prof, p) end
        end
    end
    for prof, p in pairs(O.DB().mine or {}) do Put(me, prof, p) end
    return s
end
local function SameStamp(a, b)
    if not a or not b or #a ~= #b then return false end
    for i = 1, #a do if a[i] ~= b[i] then return false end end
    return true
end
local function GuildCrafts()
    local on = O.OnlineGuild()
    local me = UnitName("player")
    local stamp = CraftsStamp(on, me)
    if gcCache and SameStamp(stamp, gcStamp) then return gcCache end
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
    gcCache, gcStamp = out, stamp
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
-- "Mylla, Grok +2" (total: how many in all, when who holds only the first ones)
local function WhoText(who, max, total)
    local t = {}
    for i = 1, max do if who[i] then t[#t + 1] = CrafterName(who[i]) end end
    total = total or #who
    local s = table.concat(t, ", ")
    if total > #t then s = s .. " " .. S.Hex(C.muted) .. "+" .. (total - #t) .. "|r" end
    return s
end
local function ByOrd(a, b) return (a.ord or 0) < (b.ord or 0) end
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
    if lvl then tip[#tip + 1] = string.format(L("Utilisable dès le niv. %d"), lvl) end
    local rg = O.Decode(re or "")
    if #rg == 0 then tip[#tip + 1] = L("Composants inconnus") end
    for _, r in ipairs(rg) do tip[#tip + 1] = r[2] .. "× " .. Name(r[1]) end
    if who and #who > 0 then
        local all = {}
        for _, c in ipairs(who) do all[#all + 1] = CrafterName(c) end
        tip[#tip + 1] = string.format(L("Peuvent le fabriquer : %s"), table.concat(all, ", "))
    end
    local others = 0
    for _, c in ipairs(who or {}) do if not c.me then others = others + 1 end end
    if best and others == 1 then
        tip[#tip + 1] = string.format(L("Clic : commander à %s, le seul artisan qui sait le fabriquer"), best)
    else
        tip[#tip + 1] = L("Clic : commander à toute la guilde (le premier artisan qui accepte s'en charge)")
        if best then tip[#tip + 1] = string.format(L("Maj-clic : commander à %s seulement"), best) end
    end
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
        local w = root.TextWidth(self.label)
        self:SetWidth(findW - indent)
        self.label:SetWidth(math.max(40, math.min((w > 0 and w or 100) + 1, findW - indent - 18 - 48)))
    end
    return b
end

-- ---------------------------------------------------------------- page: crafters
local function BuildFind(p)
    local f = ui.find
    -- the item search, on top of the grid and of the results
    -- players, items and materials (Enter keeps the search among the recent ones)
    f.box = S.Input(p, CW, { search = true, placeholder = L("Ex. Brakk, Heaume cœur-de-lion, Étoffe runique"),
        onEnter = function(t) if O.AddSearch then O.AddSearch(t) end end })
    f.box:SetPoint("TOPLEFT", 0, 0)
    -- a real query typed here wins over a crafter's view, a catalogue or a page of the home
    f.box:HookScript("OnTextChanged", function(self)
        local t = ((self:GetText() or ""):gsub("^%s+", ""):gsub("%s+$", ""))
        if #t >= 2 or t:match("item:%d+") then f.view, f.prof, f.page = nil, nil, nil end
        if t ~= f.lastQuery then f.lastQuery, f.searchCaps = t, nil end
        WP.RefreshOrders()
    end)
    -- focused and empty: the recent searches under it (hidden a moment after, so a click lands)
    f.box:HookScript("OnEditFocusGained", function() WP.RefreshOrders() end)
    f.box:HookScript("OnEditFocusLost", function()
        if C_Timer and C_Timer.After then C_Timer.After(0.2, function() WP.RefreshOrders() end) end
    end)
    -- out of a crafter's recipes: back to the profession's catalogue, the crafter's page or the home;
    -- out of a page of the home: back where it was opened from
    f.back = S.Button(p, L("Tous les métiers"), 0, 24, "ghost", function()
        if f.view then f.view = nil
        elseif f.page then f.page, f.pageFrom = f.pageFrom, nil end
        f.list.Reset(); WP.RefreshOrders()
    end, function()
        if f.view and f.prof then return { f.back:GetText(), string.format(L("Clic : revenir au catalogue %s"), ProfLabel(f.prof)) } end
        if f.view and f.page == "crafter" then return { f.back:GetText(), string.format(L("Clic : revenir à la fiche de %s"), f.cpName or "?") } end
        return { f.back:GetText(), L("Clic : revenir à l'accueil des artisans") }
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
        -- icon actions of the home's rows: watch a recipe, a favourite, remove (hidden by default)
        local function Act(icon, tipKey, fnKey)
            local b = S.IconButton(r, icon, 24, function() return r[tipKey] end, function() if r[fnKey] then r[fnKey](r) end end)
            b:Hide()
            return b
        end
        r.flag = Act("flag", "flagTip", "onFlag")
        r.trash = Act("trash", "trashTip", "onTrash")
        r.star = Act("star", "starTip", "onStar")
        r.acts = { r.flag, r.trash, r.star }
        -- on a crafter's recipe, shift-click asks the whole guild for it (the Request form filled in)
        r:SetScript("OnClick", function(self)
            if self.onRowClick then self.onRowClick(self); return end
            if self.askProf and self.item and IsShiftKeyDown and IsShiftKeyDown() and WP.AskOrder then WP.AskOrder(self.item, self.askProf); return end
            if self.btn:IsShown() then self.btn:Click() end
        end)
        return r
    end)
    f.empty = S.EmptyState(f.list.content, "search", "", nil, nil, nil)
    f.listHead = Header(f.list.content)

    -- the professions, a list on the left (f.grid, its old name: a grid of tiles before T-57): one
    -- row per profession, 200 wide; the open one in selFill, no side band
    f.grid = List(p, function(parent)
        local t = CreateFrame("Button", nil, parent)
        t.wlOwned = true
        t:SetWidth(LW)
        S.Solid(t, "BACKGROUND", C.cardFill):SetAllPoints()
        t.sel = S.Solid(t, "BACKGROUND", C.selFill, nil); t.sel:SetDrawLayer("BACKGROUND", 1); t.sel:SetAllPoints(); t.sel:Hide()
        Feedback(t)
        t.iconFrame = Painted(t, 28); t.icon = t.iconFrame.tex
        t.iconFrame:SetPoint("TOPLEFT", 8, -8)
        t.name = S.Text(t, F.body, C.fg); t.name:SetJustifyH("LEFT"); t.name:SetJustifyV("TOP")
        t.count = S.Text(t, F.meta, C.muted); t.count:SetJustifyH("LEFT"); t.count:SetJustifyV("TOP")
        t.online = S.Text(t, F.meta, C.ok); t.online:SetJustifyH("LEFT"); t.online:SetJustifyV("TOP")
        t:SetScript("OnClick", function(self)
            -- empty the box before f.prof is set: its hook then renders nothing, one render below
            if (f.cbox:GetText() or "") ~= "" then f.cbox:SetText("") end
            f.prof, f.view, f.page = self.key, nil, nil
            f.cat.Reset()
            WP.RefreshOrders()
        end)
        return t
    end)
    -- the crafters' home, first row of the left column (not one of f.grid.items: those are professions)
    local hr = CreateFrame("Button", nil, f.grid.content)
    hr.wlOwned = true
    hr:SetSize(LW, 36)
    S.Solid(hr, "BACKGROUND", C.cardFill):SetAllPoints()
    hr.sel = S.Solid(hr, "BACKGROUND", C.selFill, nil); hr.sel:SetDrawLayer("BACKGROUND", 1); hr.sel:SetAllPoints(); hr.sel:Hide()
    Feedback(hr)
    hr.icon = S.Icon(hr, "home", 16, "ARTWORK", C.muted); hr.icon:SetPoint("LEFT", 14, 0)
    hr.name = S.Text(hr, F.body, C.fg); hr.name:SetJustifyH("LEFT"); hr.name:SetWordWrap(false)
    hr.name:SetPoint("LEFT", 44, 0); hr.name:SetText(L("Accueil"))
    hr.tip = { L("Accueil"), L("Artisans, favoris, recherche"), L("Clic : revenir à l'accueil des artisans") }
    hr:SetScript("OnClick", function()
        f.prof, f.view, f.page, f.pageFrom = nil, nil, nil, nil
        if (f.box:GetText() or "") ~= "" then f.box:SetText("") end
        f.list.Reset(); WP.RefreshOrders()
    end)
    hr:Hide()
    f.homeRow = hr
    f.gridEmpty = S.EmptyState(f.grid.content, "hammer", "", nil, nil, nil)
    f.gridEmpty.wlW = CW
    -- a second action under the empty state (secondary)
    f.gridEmpty.second = S.Button(f.gridEmpty, "", 0, 28, "secondary", function() if f.gridEmpty.onSecond then f.gridEmpty.onSecond() end end)
    f.gridEmpty.second:Hide()
    -- the 1 px rule between the two columns
    f.rule = S.Solid(p, "BORDER", C.divider)
    f.rule:SetPoint("TOPLEFT", RULE_X, 0); f.rule:SetPoint("BOTTOMLEFT", RULE_X, 0); f.rule:SetWidth(1)
    if root.PixelLine then root.PixelLine(p, f.rule, false) end
    f.rule:Hide()
    -- the right side before a profession is open: one sentence, then sharing my recipes
    f.pickHint = S.Text(f.list.content, F.label, C.muted)
    f.pickHint:SetJustifyH("LEFT"); f.pickHint:SetJustifyV("TOP"); f.pickHint:SetWordWrap(true)
    f.pickHint:SetText(L("Choisis un métier à gauche pour voir son catalogue, ou cherche un objet ci-dessus."))
    f.pickHint:Hide()
    -- sharing my recipes (on by default): a settings row, with what was read of mine
    local sh = CreateFrame("Button", nil, f.list.content)
    sh.wlOwned = true
    S.Solid(sh, "BACKGROUND", C.cardFill):SetAllPoints(); S.Border(sh, C.cardEdge)
    sh.label = S.Text(sh, F.body, C.fg); sh.label:SetPoint("TOPLEFT", 12, -12); sh.label:SetJustifyH("LEFT"); sh.label:SetText(L("Partager mes recettes"))
    S.ClampLabel(sh.label, nil, sh)
    sh.desc = S.Text(sh, F.meta, C.muted); sh.desc:SetJustifyH("LEFT"); sh.desc:SetJustifyV("TOP")
    sh.desc:SetPoint("TOPLEFT", sh.label, "BOTTOMLEFT", 0, -3)
    sh.switch = S.Switch(sh, function() return WLWritsDB.ordersShare ~= false end,
        function(v)
            WLWritsDB.ordersShare = v
            if v then O.Announce() end
            if O.ShareChanged then O.ShareChanged() end   -- the profile says it too
            WP.RefreshOrders()
        end)
    sh.switch:SetPoint("TOPRIGHT", -12, -12)
    sh.switch:AttachRow(sh)
    sh:Hide()
    f.share = sh

    -- a profession's catalogue: back, online filter, the profession, its search
    local h = CreateFrame("Frame", nil, p)
    h:SetPoint("TOPLEFT"); h:SetPoint("TOPRIGHT"); h:SetHeight(108); h:Hide()
    f.chead = h
    f.cback = S.Button(h, L("Accueil"), 0, 24, "ghost", function()
        f.prof, f.view, f.page = nil, nil, nil
        f.grid.Reset()
        WP.RefreshOrders()
    end, { L("Accueil"), L("Clic : revenir à l'accueil des artisans") })
    f.cback:SetIcon("chevron_left")
    f.cback:SetPoint("TOPLEFT", 0, 0)
    local ol = CreateFrame("Button", nil, h)
    ol:SetHeight(24); ol:SetPoint("TOPRIGHT", 0, 0)
    f.conline = S.Switch(ol, function() return f.onlineOnly end, function(v) f.onlineOnly = v and true or false; WP.RefreshOrders() end,
        { L("En ligne seulement"), L("Seulement les objets qu'un artisan en ligne peut fabriquer") })
    f.conline:SetPoint("RIGHT", 0, 0)
    ol.label = S.Text(ol, F.label, C.text); ol.label:SetPoint("RIGHT", f.conline, "LEFT", -8, 0); ol.label:SetText(L("En ligne seulement"))
    S.ClampLabel(ol.label, nil, ol)
    local lw = root.TextWidth(ol.label, nil, function(w2) ol:SetWidth(40 + 8 + w2) end)
    ol:SetWidth(40 + 8 + (lw > 0 and lw or 100))
    f.conline:AttachRow(ol)
    f.cicon = Painted(h, 32); f.cicon:SetPoint("TOPLEFT", 0, -36)
    f.ctitle = S.Text(h, F.heading, C.fg); f.ctitle:SetPoint("TOPLEFT", f.cicon, "TOPRIGHT", 8, 0)
    f.ctitle:SetWidth(CW - 40); S.ClampLabel(f.ctitle, nil, h)
    f.ccount = S.Text(h, F.meta, C.muted); f.ccount:SetPoint("TOPLEFT", f.ctitle, "BOTTOMLEFT", 0, -3)
    f.ccount:SetWidth(CW - 40); S.ClampLabel(f.ccount, nil, h)
    -- the profession's crafters, one pill each, between the title and the search (CrafterStrip)
    f.cwho = S.Text(h, F.meta, C.muted); f.cwho:SetText(L("Artisans :")); f.cwho:Hide()
    S.ClampLabel(f.cwho, nil, h)
    f.cchips = {}
    f.cbox = S.Input(h, CW, { search = true, placeholder = L("Ex. Potion de soins") })
    f.cbox:SetPoint("TOPLEFT", 0, -80)
    f.cbox:HookScript("OnTextChanged", function() if f.prof then WP.RefreshOrders() end end)

    -- the catalogue's rows: an item (who makes it, Request); the row does what its button does: the
    -- order form for the whole guild (the first crafter who accepts takes it), shift-click for its
    -- best crafter only
    local function Act(r)
        if r.kind == "item" then
            local shift = IsShiftKeyDown and IsShiftKeyDown()
            WP.NewOrder(r.item, (shift and r.crafter) or nil)
        end
    end
    f.cat = List(p, function(parent)
        local r = Row(parent)
        r.who = r.detail
        r.btn = RowButton(r, L("Commander"), function() Act(r) end, function() return r.btnTip or { r.btn:GetText() } end)
        -- watch the recipe (the flag): told when a member learns it
        r.flag = S.IconButton(r, "flag", 24, function() return r.flagTip end, function() if r.onFlag then r.onFlag(r) end end)
        r.flag:Hide()
        r.acts = { r.flag }
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
    f.catMore = S.Text(f.cat.content, F.meta, C.muted)
    f.catMore:SetJustifyH("LEFT"); f.catMore:SetJustifyV("TOP"); f.catMore:Hide()
end

-- which of the page's areas shows: the result list, the professions, or a catalogue; where it
-- starts. Two columns (f.split, someone shares): the professions always on the left, the mode's
-- area on the right ("grid" there: the search, a sentence and the sharing row, in f.list).
local function SetMode(f, mode)
    local p = pages.find
    local split = f.split and true or false
    findW = split and RW or CW
    local x = split and RX or 0
    f.grid.sf:SetShown(split or mode == "grid")
    f.list.sf:SetShown(mode == "list" or (split and mode == "grid"))
    f.cat.sf:SetShown(mode == "cat")
    f.rule:SetShown(split)
    local cat = mode == "cat"
    f.chead:SetShown(cat); f.box:SetShown(not cat)
    f.back:SetShown(mode == "list" and (f.view ~= nil or f.page ~= nil))
    f.box:ClearAllPoints(); f.box:SetPoint("TOPLEFT", x, 0); f.box:SetWidth(findW)
    f.back:ClearAllPoints(); f.back:SetPoint("TOPLEFT", x, -36)
    f.chead:ClearAllPoints(); f.chead:SetPoint("TOPLEFT", x, 0); f.chead:SetWidth(findW)
    f.cbox:SetWidth(findW); f.ctitle:SetWidth(findW - 40); f.ccount:SetWidth(findW - 40)
    f.listHead:SetWidth(findW)
    f.empty.wlW, f.catEmpty.wlW = findW, findW
    if not (split and mode == "grid") then f.pickHint:Hide(); f.share:Hide() end
    p.topH = cat and ((f.cheadH or 108) + 12) or (f.back:IsShown() and (28 + 8 + 24 + 12) or (28 + 12))
    p.sideH = nil
    if split then f.grid.Top(0, 0, LW) end
    local l = mode == "list" and f.list or (mode == "grid" and (split and f.list or f.grid) or f.cat)
    if split then l.Top(p.topH, RX, RW) else l.Top(p.topH) end
    return l
end

-- the professions shown (mining only when someone shares it), and whether anyone shares anything
local function ProfKeys(g)
    local keys = {}
    for _, k in ipairs(GRID_PROFS) do
        if k ~= "mining" or (g.mining and g.mining.nItems > 0) then keys[#keys + 1] = k end
    end
    local anyone = false
    for _, key in ipairs(keys) do if g[key] and #g[key].crafters > 0 then anyone = true end end
    return keys, anyone
end

-- the left column: one row per profession (icon 28, its name, the counts, who is online); returns
-- its height, also kept in pages.find.sideH so the window fits the taller column
local function RenderProfList(f, g, keys)
    local tw = LW - 44 - 8
    -- the home first: selected on the home and its pages
    local hr = f.homeRow
    hr:ClearAllPoints(); hr:SetPoint("TOPLEFT", 0, 0); hr:Show()
    local atHome = f.prof == nil and (f.view == nil or f.page ~= nil)
    hr.sel:SetShown(atHome)
    hr.tip[3] = (not atHome or f.page or f.view) and L("Clic : revenir à l'accueil des artisans") or nil
    local y = 36 + 2
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
        if f.prof ~= key then t.tip[#t.tip + 1] = L("Clic : ouvrir le catalogue du métier") end
        t.sel:SetShown(f.prof == key)
        -- every text wraps inside the row; the row grows with it
        local ty = 8
        t.name:ClearAllPoints(); t.name:SetPoint("TOPLEFT", 44, -ty)
        ty = ty + S.FitText(t.name, 2, tw, t) + 2
        t.count:ClearAllPoints(); t.count:SetPoint("TOPLEFT", 44, -ty)
        ty = ty + S.FitText(t.count, 2, tw, t)
        if t.online:IsShown() then
            ty = ty + 2
            t.online:ClearAllPoints(); t.online:SetPoint("TOPLEFT", 44, -ty)
            ty = ty + S.FitText(t.online, 2, tw, t)
        end
        local h = math.max(44, math.ceil(ty + 8))
        t:SetSize(LW, h); t:ClearAllPoints(); t:SetPoint("TOPLEFT", 0, -y)
        y = y + h + 2
    end
    f.grid.HideFrom(#keys + 1)
    y = math.max(0, y - 2)
    f.grid.sf:SetContentHeight(y)
    pages.find.sideH = y
    return y
end

-- the right side before a profession is open (two columns): a sentence, then the sharing row
local function RenderPickHome(f)
    f.list.HideFrom(1)
    f.pickHint:Show()
    f.pickHint:ClearAllPoints(); f.pickHint:SetPoint("TOPLEFT", 0, 0)
    local y = S.FitText(f.pickHint, 0, findW, f.list.content) + 16
    local sh = f.share
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
    sh:SetWidth(findW)
    local textW = findW - 12 - 40 - 12 - 12
    local lh = S.FitText(sh.label, 2, textW, sh)
    local dh = S.FitText(sh.desc, 0, textW, sh)
    local hh = math.max(44, math.ceil(12 + lh + 3 + dh + 12))
    sh:SetHeight(hh)
    sh:ClearAllPoints(); sh:SetPoint("TOPLEFT", 0, -y)
    sh:Show()
    y = y + hh
    f.list.content:SetHeight(math.max(1, y))
    return y
end

-- one column (nobody shares anything yet): the empty state where the professions would be
local function RenderGrid(f, g)
    f.grid.HideFrom(1)
    f.homeRow:Hide()
    f.share:Hide(); f.pickHint:Hide()
    local e = f.gridEmpty
    e:ClearAllPoints(); e:SetPoint("TOP", f.grid.content, "TOP", 0, -24)
    local y = Empty(e, true, "hammer", L("Aucun artisan connu"),
        L("Les membres qui ont WL Helper partagent leurs métiers en se connectant."),
        L("Faire une demande"), function() WP.ShowOrdersTab("ask") end)
    -- second way out: share my recipes (sharing off), else my crafter profile
    local off = WLWritsDB.ordersShare == false
    e.second:SetText(off and L("Partager mes recettes") or L("Ma fiche d'artisan"))
    e.onSecond = function()
        if off then
            WLWritsDB.ordersShare = true; O.Announce()
            if O.ShareChanged then O.ShareChanged() end
            WP.RefreshOrders()
        elseif WP.OpenCrafterPage then WP.OpenCrafterPage(nil) end
    end
    e.second:ClearAllPoints(); e.second:SetPoint("TOP", e, "TOP", 0, -((e.blockH or 0) + 8))
    e.second:Show()
    y = y + 8 + 28
    f.grid.content:SetHeight(math.max(1, y))
    return y
end

-- ---------------------------------------------------------------- the catalogue's crafters
-- One pill per crafter under the profession's title, above its search: a click opens that
-- crafter's recipes. Online first. A crafter who shared nothing yet is a quiet pill, its tooltip
-- says why. Two lines at most, then "+N" (its tooltip names the rest, a click shows more: five
-- lines at most, so the items keep their room).
local CHIP_H, CHIP_GAP, CHIP_LINES, CHIP_LINES_ALL = 20, 4, 2, 5
local STRIP_Y = 76   -- under the profession icon (36 + 32 + 8)

local function ClassHex(c)
    local cls = c.me and select(2, UnitClass("player")) or O.ClassOf(c.name)
    local cc = cls and RAID_CLASS_COLORS and RAID_CLASS_COLORS[cls]
    if not cc then return S.Hex(C.fg) end
    return string.format("|cff%02x%02x%02x", math.floor(cc.r * 255 + 0.5), math.floor(cc.g * 255 + 0.5), math.floor(cc.b * 255 + 0.5))
end

local function CrafterChip(parent)
    local c = CreateFrame("Button", nil, parent)
    c.wlOwned = true
    c:SetHeight(CHIP_H)
    c.bg = S.Solid(c, "BACKGROUND", { 1, 1, 1, 0.10 }); c.bg:SetAllPoints()
    c.edge = S.Border(c, { 1, 1, 1 }, 0.20)
    c.dot = S.Icon(c, "dot", 8, "ARTWORK", C.ok); c.dot:SetPoint("LEFT", 7, 0); c.dot:Hide()
    c.label = S.Text(c, F.meta, C.fg); c.label:SetJustifyH("LEFT"); c.label:SetWordWrap(false)
    S.ClampLabel(c.label, nil, c)
    function c:Paint()
        if self.quiet or self.dim then
            self.bg:SetColorTexture(1, 1, 1, self.hov and 0.07 or 0.04); self.edge({ 1, 1, 1 }, self.hov and 0.24 or 0.12)
        else
            self.bg:SetColorTexture(1, 1, 1, self.hov and 0.16 or 0.10); self.edge({ 1, 1, 1 }, self.hov and 0.40 or 0.20)
        end
    end
    -- the words set the width (measured like the pills, never cut)
    function c:Measure(text)
        self.label:SetText(text)
        local left = self.dot:IsShown() and 19 or 8
        local tw = root.TextWidth(self.label) + 2
        self.wlNeed = tw
        self.label:ClearAllPoints(); self.label:SetPoint("LEFT", left, 0)
        local w = left + tw + 8
        if w > findW then tw = findW - left - 8; w = findW end   -- one pill wider than its column: the tooltip has the name
        self.label:SetWidth(tw); self.wlTextW = tw
        self:SetWidth(w); self.wlW = w
        return w
    end
    c:SetScript("OnClick", function(self) if self.onClick then self.onClick(self) end end)
    c:SetScript("OnEnter", function(self)
        self.hov = true; self:Paint()
        local t = self.tip
        if type(t) == "function" then t = t(self) end
        if type(t) == "table" then S.Tip(self, t) end
    end)
    c:SetScript("OnLeave", function(self) self.hov = nil; self:Paint(); S.HideTip() end)
    return c
end

local function OpenCrafter(f, c)
    f.view = { name = c.name, prof = c.prof, me = c.me }
    f.list.Reset(); WP.RefreshOrders()
end

-- "Forge 151 · en ligne · 38 recettes"
local function CrafterFacts(key, c)
    local s = string.format(L("%s %d"), ProfLabel(key), c.rank) .. " · " .. Where(c.online)
    if c.n > 0 then s = s .. " · " .. P(c.n, L("1 recette"), L("%d recettes")) end
    return s
end

-- a crafter's tooltip (a pill, a row of the crafters list): who, how far, why nothing is shared yet
local function CrafterTip(key, c)
    local tip = { ClassHex(c) .. c.name .. "|r", CrafterFacts(key, c) }
    local sl = (not c.me) and StarLine(c.name) or nil
    if sl then tip[#tip + 1] = sl end
    if c.n == 0 then
        tip[#tip + 1] = c.me and L("Ouvre ta fenêtre de métier pour partager les tiennes.")
            or string.format(L("Pas encore de recettes partagées par %s. Elles arrivent quand ce membre ouvre sa fenêtre de métier."), c.name)
    else
        tip[#tip + 1] = string.format(L("Clic : voir les recettes de %s"), c.name)
    end
    return tip
end

local function FillChip(f, ch, key, c)
    ch.quiet = c.n == 0
    -- "online only": an offline crafter stays reachable, only quieter
    ch.dim = (not ch.quiet and f.onlineOnly and not c.online and not c.me) and true or nil
    ch.dot:SetShown(c.online and not c.me and true or false)
    ch.dot:SetAlpha(ch.quiet and 0.6 or 1)
    local name = c.name
    local text
    if ch.quiet then
        text = S.Hex(C.muted) .. name .. (c.me and (" " .. L("(toi)")) or "") .. "|r"
    else
        text = (ch.dim and S.Hex(C.muted) or ClassHex(c)) .. name .. "|r" .. (c.me and (" " .. S.Hex(C.muted) .. L("(toi)") .. "|r") or "")
            .. " " .. S.Hex(C.muted) .. "· " .. P(c.n, L("1 recette"), L("%d recettes")) .. "|r"   -- a bare number read as anything
            .. (c.stars > 0 and (" " .. STAR .. S.Hex(C.gold) .. c.stars .. "|r") or "")
    end
    ch.crafter = c
    ch.onClick = (not ch.quiet) and function() OpenCrafter(f, c) end or nil
    ch.tip = CrafterTip(key, c)
    ch:Paint()
    return ch:Measure(text)
end

-- ---------------------------------------------------------------- many crafters: one control, a list
-- Above STRIP_MAX crafters the pills would fill the window: one control instead ("Artisans : 3 en
-- ligne · 24 en tout"), that opens a list under it: a search on top, ten rows at a time (the rows
-- are reused while it scrolls), online first, then by recipes shared; who shared nothing at the
-- bottom, grey, not clickable, the tooltip says why. Escape, a click outside or a pick closes it.
local STRIP_MAX = 8
local PICK_H, MENU_W, MENU_ROWS, MENU_ROW_H, MENU_TOP = 24, 340, 10, 24, 8 + 28 + 6
local MENU_NAME, WIN_NAME = "WLHelperOrdersCrafters", "WLHelperOrders"

-- online first (others before you), then recipes shared, stars, name; nothing shared: last
local function ByMenu(a, b)
    local qa, qb = a.n == 0, b.n == 0
    if qa ~= qb then return qb end
    if a.online ~= b.online then return a.online end
    if (a.me or false) ~= (b.me or false) then return not a.me end
    if a.n ~= b.n then return a.n > b.n end
    if a.stars ~= b.stars then return a.stars > b.stars end
    return a.name < b.name
end

-- One Escape hides every shown frame of UISpecialFrames: while the list is open the Orders window
-- leaves that list, so Escape closes the list only (same as the LFG picker)
local function Unlist(name)
    if not UISpecialFrames then return end
    for k = #UISpecialFrames, 1, -1 do if UISpecialFrames[k] == name then table.remove(UISpecialFrames, k) end end
end
local function List1(name)
    if not UISpecialFrames then return end
    for _, v in ipairs(UISpecialFrames) do if v == name then return end end
    tinsert(UISpecialFrames, name)
end

local function CloseCrafterMenu(f)
    local m = f.cmenu
    if not m then return end
    if m:IsShown() then m:Hide() end
    if m.Done then m:Done() end
end

local function BuildCrafterMenu(f)
    local m = CreateFrame("Frame", MENU_NAME, f.chead)
    m.wlOwned = true
    m:SetFrameStrata("DIALOG")
    if m.SetToplevel then m:SetToplevel(true) end
    if m.SetClampedToScreen then m:SetClampedToScreen(true) end
    m:EnableMouse(true)
    m:SetWidth(MENU_W)
    S.Solid(m, "BACKGROUND", C.panel, 0.98):SetAllPoints()
    S.Border(m, C.cardEdge)
    m.shown, m.rows, m.off = {}, {}, 0
    m.box = S.Input(m, MENU_W - 16, { search = true, placeholder = L("Chercher un artisan") })
    m.box:SetPoint("TOPLEFT", 8, -8)
    m.box:HookScript("OnTextChanged", function() m:Filter() end)
    m.box:SetScript("OnEscapePressed", function() CloseCrafterMenu(f) end)
    -- Enter: the first crafter that matches and shared something
    m.box:SetScript("OnEnterPressed", function()
        for _, c in ipairs(m.shown) do
            if c.n > 0 then CloseCrafterMenu(f); OpenCrafter(f, c); return end
        end
    end)
    m.empty = S.Text(m, F.meta, C.muted); m.empty:SetJustifyH("LEFT")
    m.empty:SetPoint("TOPLEFT", 12, -(MENU_TOP + 4)); m.empty:SetWidth(MENU_W - 24)
    m.empty:SetText(L("Aucun artisan ne correspond à ce nom.")); m.empty:Hide()
    -- the scroll position: a thin bar on the right, only when the list is longer than ten rows
    m.bar = S.Solid(m, "ARTWORK", { 1, 1, 1, 0.27 }); m.bar:SetWidth(3); m.bar:Hide()

    local function Row(i)
        local r = m.rows[i]
        if r then return r end
        r = CreateFrame("Button", nil, m)
        r.wlOwned = true
        r:SetHeight(MENU_ROW_H)
        r:SetPoint("TOPLEFT", 1, -(MENU_TOP + (i - 1) * MENU_ROW_H)); r:SetPoint("TOPRIGHT", -8, -(MENU_TOP + (i - 1) * MENU_ROW_H))
        r.hl = S.Solid(r, "BACKGROUND", C.hoverFill); r.hl:SetAllPoints(); r.hl:SetAlpha(0)
        r.dot = S.Icon(r, "dot", 8, "ARTWORK", C.ok); r.dot:SetPoint("LEFT", 8, 0)
        r.right = S.Text(r, F.meta, C.muted); r.right:SetJustifyH("RIGHT"); r.right:SetWordWrap(false)
        r.right:SetPoint("RIGHT", -6, 0)
        r.name = S.Text(r, F.label, C.fg); r.name:SetJustifyH("LEFT"); r.name:SetWordWrap(false)
        r.name:SetPoint("LEFT", 22, 0); r.name:SetPoint("RIGHT", r.right, "LEFT", -8, 0)
        S.ClampLabel(r.name, nil, r)
        r:SetScript("OnEnter", function(self)
            if self.c and self.c.n > 0 then self.hl:SetAlpha(1) end
            if self.c then S.Tip(self, CrafterTip(f.prof, self.c)) end
        end)
        r:SetScript("OnLeave", function(self) self.hl:SetAlpha(0); S.HideTip() end)
        r:SetScript("OnClick", function(self)
            local c = self.c
            if not (c and c.n > 0) then return end   -- shared nothing: the tooltip says why
            CloseCrafterMenu(f); OpenCrafter(f, c)
        end)
        m.rows[i] = r
        return r
    end

    -- draws the ten rows at m.off (the only per-scroll work: ten rows, no new frame)
    function m:Fill()
        local total = #self.shown
        self.off = math.max(0, math.min(self.off, total - MENU_ROWS))
        local n = math.min(MENU_ROWS, total)
        for i = 1, n do
            local r, c = Row(i), self.shown[i + self.off]
            r.c = c
            local quiet = c.n == 0
            local dim = (not quiet) and f.onlineOnly and not c.online and not c.me
            r.dot:SetShown(c.online and not c.me and true or false)
            r.dot:SetAlpha(quiet and 0.6 or 1)
            local you = c.me and (" " .. S.Hex(C.muted) .. L("(toi)") .. "|r") or ""
            r.name:SetText(((quiet or dim) and S.Hex(C.muted) or ClassHex(c)) .. c.name .. "|r" .. you)
            if quiet then
                r.right:SetText(L("rien de partagé"))
            else
                r.right:SetText(P(c.n, L("1 recette"), L("%d recettes")) .. (c.stars > 0 and (" " .. STAR .. S.Hex(C.gold) .. c.stars .. "|r") or ""))
            end
            r.hl:SetAlpha(0)
            r:Show()
            -- the wheel moved another crafter under the pointer: its highlight and tooltip
            if self:IsShown() and r:IsMouseOver() then r:GetScript("OnEnter")(r) end
        end
        for i = n + 1, #self.rows do self.rows[i]:Hide(); self.rows[i].c = nil end
        self.empty:SetShown(total == 0)
        local listH = total == 0 and MENU_ROW_H or n * MENU_ROW_H
        self:SetHeight(MENU_TOP + listH + 6)
        if total > MENU_ROWS then
            local trackH = MENU_ROWS * MENU_ROW_H
            local th = math.max(16, math.floor(trackH * MENU_ROWS / total))
            local y = math.floor((trackH - th) * self.off / (total - MENU_ROWS))
            self.bar:ClearAllPoints(); self.bar:SetPoint("TOPRIGHT", -3, -(MENU_TOP + y)); self.bar:SetHeight(th)
            self.bar:Show()
        else
            self.bar:Hide()
        end
    end
    -- what the search keeps (one pass over the list, on each letter typed)
    function m:Filter(keepOff)
        local q = ((self.box:GetText() or ""):gsub("^%s+", ""):gsub("%s+$", "")):lower()
        local out = {}
        for _, c in ipairs(f.cmenuList or {}) do
            if q == "" or c.name:lower():find(q, 1, true) then out[#out + 1] = c end
        end
        self.shown = out
        if not keepOff then self.off = 0 end
        self:Fill()
    end
    function m:Scroll(delta)
        self.off = self.off - (delta or 0) * 3
        self:Fill()
    end
    m:EnableMouseWheel(true)
    m:SetScript("OnMouseWheel", function(self, delta) self:Scroll(delta) end)
    -- a click anywhere else closes it (the control toggles it itself)
    m:SetScript("OnEvent", function(self, ev)
        if ev == "GLOBAL_MOUSE_DOWN" and self:IsShown() and not self:IsMouseOver() and not (f.cpick and f.cpick:IsMouseOver()) then
            CloseCrafterMenu(f)
        end
    end)
    -- closing: no event left, the keyboard back to the game, Escape back to the Orders window
    function m:Done()
        if self.done then return end
        self.done = true
        if self.UnregisterEvent then pcall(self.UnregisterEvent, self, "GLOBAL_MOUSE_DOWN") end
        if self.box.ClearFocus then self.box:ClearFocus() end
        Unlist(MENU_NAME)
        -- one frame later: CloseSpecialWindows may still be walking the list
        -- back even when the window itself is closing (its X, its key): the list is where it lives
        -- while hidden too, or the next Escape would not close it
        local function Relist() if not m:IsShown() then List1(WIN_NAME) end end
        if C_Timer and C_Timer.After then C_Timer.After(0, Relist) else Relist() end
    end
    m:SetScript("OnHide", function(self) self:Done() end)
    function m:Open()
        self.done, self.key = nil, f.cmenuKey
        self:ClearAllPoints(); self:SetPoint("TOPLEFT", f.cpick, "BOTTOMLEFT", 0, -2)
        self.box:SetText("")
        self:Filter()
        self:Show()
        if self.RegisterEvent then pcall(self.RegisterEvent, self, "GLOBAL_MOUSE_DOWN") end
        Unlist(WIN_NAME); List1(MENU_NAME)
        if self.box.SetFocus then self.box:SetFocus() end
    end
    m:Hide()
    f.cmenu = m
    return m
end

-- the control that stands for the pills: "Artisans : 3 en ligne · 24 en tout", and its list's
-- content (sorted once per render)
local function CrafterPicker(f, e, key)
    local b = f.cpick
    if not b then
        b = S.Button(f.chead, "", 0, PICK_H, "secondary", function()
            local m = f.cmenu or BuildCrafterMenu(f)
            if m:IsShown() then CloseCrafterMenu(f) else m:Open() end
        end, { L("Artisans"), L("Clic : chercher un artisan et voir ses recettes") })
        b.arrow = b.content:CreateTexture(nil, "ARTWORK")
        b.arrow:SetSize(12, 12); b.arrow:SetPoint("RIGHT", -8, 0)
        root.SetHDIcon(b.arrow, "chevron_down", C.muted)
        b.extraW = 12 + 4 - 4
        b.label:SetJustifyH("LEFT")
        function b:CustomLayout(dy)
            self.label:ClearAllPoints()
            self.label:SetPoint("LEFT", self.content, "LEFT", 8, dy)
            self.label:SetPoint("RIGHT", self.arrow, "LEFT", -4, dy)
        end
        f.cpick = b
    end
    local on = e.nOnline > 0 and (S.Hex(C.ok) .. P(e.nOnline, L("1 en ligne"), L("%d en ligne")) .. "|r") or L("aucun en ligne")
    b:SetText(string.format(L("Artisans : %s · %d en tout"), on, #e.crafters))
    b:ClearAllPoints(); b:SetPoint("TOPLEFT", 0, -STRIP_Y)
    b:Show()
    local list = {}
    for i, c in ipairs(e.crafters) do list[i] = c end
    table.sort(list, ByMenu)
    f.cmenuList, f.cmenuKey = list, key
    local m = f.cmenu
    if m and m:IsShown() then
        if m.key ~= key then CloseCrafterMenu(f) else m:Filter(true) end   -- open across a refresh: kept, same scroll
    end
end

-- places the pills, the search under them, and sets the header's height (f.cheadH)
local function CrafterTipName(c)
    return (c.n > 0 and ClassHex(c) or S.Hex(C.muted)) .. c.name .. "|r"
        .. (c.n > 0 and (S.Hex(C.muted) .. " · " .. P(c.n, L("1 recette"), L("%d recettes")) .. "|r") or "")
end

local function CrafterStrip(f, e, key)
    -- a big guild: the control and its list instead of the pills
    if e and #e.crafters > STRIP_MAX then
        f.cwho:Hide()
        for j = 1, #f.cchips do f.cchips[j]:Hide() end
        if f.cchips.more then f.cchips.more:Hide() end
        if f.cchips.fold then f.cchips.fold:Hide() end
        CrafterPicker(f, e, key)
        f.cchipsN, f.cchipLines = 0, 1
        local boxY = STRIP_Y + PICK_H + 10
        f.cbox:ClearAllPoints(); f.cbox:SetPoint("TOPLEFT", 0, -boxY)
        f.cheadH = boxY + 28
        f.chead:SetHeight(f.cheadH)
        return
    end
    if f.cpick then f.cpick:Hide(); CloseCrafterMenu(f) end
    local list, quiet = {}, {}
    for _, c in ipairs(e and e.crafters or {}) do
        if c.n > 0 then list[#list + 1] = c else quiet[#quiet + 1] = c end
    end
    table.sort(list, ByCrafter); table.sort(quiet, ByCrafter)
    for _, c in ipairs(quiet) do list[#list + 1] = c end
    local pool = f.cchips
    local function Get(i)
        local ch = pool[i]
        if not ch then ch = CrafterChip(f.chead); pool[i] = ch end
        return ch
    end
    local used, lines = 0, 0
    if #list > 0 then
        f.cwho:Show()
        local lw = root.TextWidth(f.cwho) + 2
        f.cwho:SetWidth(lw)
        f.cwho:ClearAllPoints(); f.cwho:SetPoint("TOPLEFT", 0, -(STRIP_Y + math.floor((CHIP_H - F.meta) / 2)))
        local indent = math.min(lw + 8, 120)
        f.chipsAll = f.chipsAll or {}
        local all = f.chipsAll[key] and true or false
        local cap = all and CHIP_LINES_ALL or CHIP_LINES
        local more, fold = pool.more, pool.fold
        if not more then more = CrafterChip(f.chead); pool.more = more end
        if not fold then fold = CrafterChip(f.chead); pool.fold = fold end
        local function MoreW(n) more.dot:Hide(); return more:Measure(S.Hex(C.fg) .. "+" .. n .. "|r") end
        local function FoldW() fold.dot:Hide(); return fold:Measure(S.Hex(C.fg) .. L("Réduire") .. "|r") end
        -- what must still fit after the last pill of the last allowed line: "+N", and "Réduire" when open
        local function Tail(rest)
            local w = rest > 0 and MoreW(rest) or 0
            if all then w = (w > 0 and (w + CHIP_GAP) or 0) + FoldW() end
            return w
        end
        local x, line, cut = indent, 1, nil
        local function Place(ch, w)
            ch:ClearAllPoints(); ch:SetPoint("TOPLEFT", x, -(STRIP_Y + (line - 1) * (CHIP_H + CHIP_GAP)))
            ch.wlX, ch.wlLine = x, line
            ch:Show()
            x = x + w + CHIP_GAP
        end
        for i, c in ipairs(list) do
            local ch = Get(i)
            local w = FillChip(f, ch, key, c)
            local rest = #list - i
            local function Need()
                if line < cap then return w end
                local t = Tail(rest)
                return t > 0 and (w + CHIP_GAP + t) or w
            end
            if x > indent and x + Need() > findW then
                if line >= cap then cut = i; break end
                line, x = line + 1, indent
            end
            if line >= cap and x > indent and x + Need() > findW then cut = i; break end
            Place(ch, w)
            used = i
        end
        for j = used + 1, #pool do pool[j]:Hide() end
        local rest = cut and (#list - cut + 1) or 0
        if rest > 0 then
            local mw = MoreW(rest)
            more.quiet = nil; more:Paint()
            local tip = { P(rest, L("1 autre artisan"), L("%d autres artisans")) }
            for j = cut, math.min(#list, cut + 14) do tip[#tip + 1] = CrafterTipName(list[j]) end
            if rest > 15 then tip[#tip + 1] = S.Hex(C.muted) .. "+" .. (rest - 15) .. "|r" end
            if all then
                more.onClick = nil   -- already open: the tooltip names the rest
            else
                tip[#tip + 1] = L("Clic : voir tous les artisans")
                more.onClick = function() f.chipsAll[key] = true; WP.RefreshOrders() end
            end
            more.tip = tip
            if x + mw > findW then line, x = line + 1, indent end
            Place(more, mw)
        else
            more:Hide()
        end
        if all then
            -- a way back to the short strip
            local fw = FoldW()
            fold.quiet = nil; fold:Paint()
            fold.tip = { L("Réduire"), L("Clic : n'afficher que les premiers artisans") }
            fold.onClick = function() f.chipsAll[key] = nil; WP.RefreshOrders() end
            if x > indent and x + fw > findW then line, x = line + 1, indent end
            Place(fold, fw)
        else
            fold:Hide()
        end
        lines = line
    else
        f.cwho:Hide()
        for j = 1, #pool do pool[j]:Hide() end
        if pool.more then pool.more:Hide() end
        if pool.fold then pool.fold:Hide() end
    end
    f.cchipsN, f.cchipLines = used, lines
    local boxY = lines > 0 and (STRIP_Y + lines * CHIP_H + (lines - 1) * CHIP_GAP + 10) or 80
    f.cbox:ClearAllPoints(); f.cbox:SetPoint("TOPLEFT", 0, -boxY)
    f.cheadH = boxY + 28
    f.chead:SetHeight(f.cheadH)
end

local function RenderCatalog(f, g)
    local key = f.prof
    local e = g[key] or { crafters = {}, items = {}, nItems = 0, nOnline = 0, unshared = {} }
    -- the crafters' order, once per render: each row then reads c.ord instead of sorting its list
    table.sort(e.crafters, ByCrafter)
    for k, c in ipairs(e.crafters) do c.ord = k end
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
        -- the two first crafters in the guild's order (c.ord, sorted once per render), the best
        -- other than you, and how many others: one pass, no sort per row
        local a, b, best, others = nil, nil, nil, 0
        for _, c in ipairs(it.who) do
            if not a or c.ord < a.ord then a, b = c, a elseif not b or c.ord < b.ord then b = c end
            if not c.me then
                others = others + 1
                if not best or c.ord < best.ord then best = c end
            end
        end
        r.crafter = best and best.name or nil
        SetItem(r, ItemTex(it.id), it.id)
        r.name:SetText(it.name)
        -- the level in words, like the summary ("se prend dès le niv. 30"): "Niv. 30" alone read as
        -- the item's own level
        local lvl = (it.lvl or 0) > 1 and (S.Hex(C.text) .. string.format(L("Utilisable dès le niv. %d"), it.lvl) .. "|r") or ""
        if mixed and it.kind then lvl = lvl .. (lvl ~= "" and " · " or "") .. it.kind end
        if lvl ~= "" then lvl = lvl .. " · " end
        -- the crafters in words ("Crafters: ..."), not behind a person icon (icon audit, Orders)
        -- two names at most ("Surfeuze, Jander +5"): every name is in the tooltip
        r.detail:SetText(lvl .. L(#it.who == 1 and "Artisan :" or "Artisans :") .. " " .. WhoText({ a, b }, 2, #it.who)); r.detail:Show()
        r.btn:SetText(L("Commander")); r.btn:Show()
        -- one crafter only: shift-click would do the same as a click, so it is not offered
        if r.crafter and others == 1 then
            r.btnTip = { L("Commander"), string.format(L("Clic : commander à %s, le seul artisan qui sait le fabriquer"), r.crafter) }
        else
            r.btnTip = { L("Commander"), L("Clic : commander à toute la guilde (le premier artisan qui accepte s'en charge)") }
            if r.crafter then r.btnTip[3] = string.format(L("Maj-clic : commander à %s seulement"), r.crafter) end
        end
        -- the reagents and every crafter go in the tooltip, built on hover only
        local id, re, who, crafter = it.id, it.re, it.who, r.crafter
        r.tip = function()
            table.sort(who, ByOrd)   -- on hover only, in the same order as the row
            return ItemTip(id, re, who, crafter)
        end
        r.tipFill = nil
        H.SetFlag(r, it.id)
        local rh = r:Fit(findW)
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
        y = y + 6 + S.FitText(f.catMore, 0, findW, f.cat.content)
        f.catMore:Show()
    else f.catMore:Hide() end
    f.cat.HideFrom(i + 1)
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

-- ---------------------------------------------------------------- the crafters' home (T-60)
-- The right side when nothing is open: my crafter card, the search (above), four tiles (crafters
-- online, favourites, my recent orders, watched recipes) and the week's top crafters; the
-- professions stay on the left. Pages reached from it: the crafters online, a crafter's profile,
-- my profile, the search results. Every number of a render reads one O.CrafterSet().
H.SCOL = { a = C.ok, b = C.warn, o = C.fg, d = C.fg }
function H.En() return ns.English and ns.English() or false end
function H.Quote(s) return H.En() and ('"' .. s .. '"') or ("« " .. s .. " »") end
-- "12 min", "3 h", "2 j"
function H.Ago(secs)
    secs = math.max(0, secs or 0)
    if secs < 3600 then return string.format(L("%d min"), math.max(1, math.floor(secs / 60))) end
    if secs < 86400 then return string.format(L("%d h"), math.floor(secs / 3600)) end
    return string.format(L("%d j"), math.floor(secs / 86400))
end
-- a status as a pill (nil: no pill, "online" alone says it); returns the pill's width
function H.SetPill(p, s)
    if not s or not O.StatusWord(s) then p:Hide(); return 0 end
    p:Set(O.StatusWord(s), H.SCOL[s], s == "d" and "clock" or nil)
    p:Show()
    return num(p:GetWidth()) or 60
end
-- a crafter's state in words, coloured (rows)
function H.StatusText(g)
    if not g.online then return S.Hex(C.muted) .. L("hors ligne") .. "|r" end
    if not g.status then return S.Hex(C.ok) .. L("En ligne") .. "|r" end
    return S.Hex(H.SCOL[g.status]) .. O.StatusWord(g.status) .. "|r"
end
-- "Forge 300 · Alchimie 285"
function H.ProfText(profs, max)
    local t = {}
    for i, pr in ipairs(profs or {}) do
        if i > (max or 3) then break end
        local raw = pr.raw or pr.key
        t[#t + 1] = string.format(L("%s %d"), ProfLabel(ProfKey(raw) or ProfKey(pr.key), raw), pr.rank or 0)
    end
    return table.concat(t, " · ")
end
-- "Niveau 60 · Forge 300 · +2 rerolls · Tanaris · « note »" (offline: when last seen, no zone)
function H.GroupDetail(g, offline)
    local t = {}
    if g.level then t[#t + 1] = string.format(L("Niveau %d"), g.level) end
    local pt = H.ProfText(g.profs, 3)
    if pt ~= "" then t[#t + 1] = pt end
    if (g.alts or 0) > 0 then t[#t + 1] = P(g.alts, L("+1 reroll"), L("+%d rerolls")) end
    if offline then
        if g.lastOnline then t[#t + 1] = string.format(L("Vu il y a %s"), H.Ago(g.lastOnline)) end
    elseif g.zone then t[#t + 1] = g.zone end
    if g.note then t[#t + 1] = H.Quote(g.note) end
    return table.concat(t, " · ")
end
function H.ClassText(name, cls)
    local cc = cls and RAID_CLASS_COLORS and RAID_CLASS_COLORS[cls]
    if not cc then return name end
    return string.format("|cff%02x%02x%02x", math.floor(cc.r * 255 + 0.5), math.floor(cc.g * 255 + 0.5), math.floor(cc.b * 255 + 0.5)) .. name .. "|r"
end

-- every widget of the home and its pages: hidden at the start of each render, shown by its page
function H.Own(f, w) f.hx = f.hx or {}; f.hx[#f.hx + 1] = w; w:Hide(); return w end
function H.Reset(f)
    for _, w in ipairs(f.hx or {}) do w:Hide() end
    for _, r in ipairs(f.list.items) do
        r.star:Hide(); r.flag:Hide(); r.trash:Hide()
        r.onRowClick, r.onStar, r.onFlag, r.onTrash = nil, nil, nil, nil
        r:SetAlpha(1)
    end
    for _, r in ipairs(f.cat.items) do r.flag:Hide() end
    if f.homeRow then f.homeRow:Hide() end
    if f.gridEmpty and f.gridEmpty.second then f.gridEmpty.second:Hide() end
end

-- the watch flag on an item row (16 in a 24 hit area): muted, accentSoft when watched
function H.SetFlag(r, id)
    if not (r.flag and id and O.IsWatched) then return end
    local on = O.IsWatched(id)
    local full = not on and O.WatchCount() >= O.WATCH_MAX
    r.flag:SetToggled(on)
    if full then r.flag:Disable() else r.flag:Enable() end
    r.flagTip = { L("Surveiller cette recette"), L("Tu seras prévenu quand un membre de la guilde saura la faire."),
        full and (S.Hex(C.warn) .. L("30 recettes surveillées au plus : retire-en une d'abord.") .. "|r")
        or (on and L("Clic : ne plus surveiller") or L("Clic : surveiller")) }
    r.onFlag = function() O.ToggleWatch(id); WP.RefreshOrders() end
    r.flag:Show()
end
-- the favourite star on a crafter's row: a player with alts is one favourite
function H.ToggleFav(g)
    if g.fav then
        for _, c in ipairs(g.chars or { { name = g.name } }) do if O.IsFav(c.name) then O.ToggleFav(c.name) end end
    else
        local ok = O.ToggleFav(g.name)
        if not ok then WP.Print(L("50 favoris au plus : retire-en un d'abord.")) end
    end
    WP.RefreshOrders()
end
function H.SetStar(r, g)
    r.star:SetToggled(g.fav)
    r.starTip = { g.fav and L("Retirer des favoris") or L("Ajouter aux favoris"),
        g.fav and L("Clic : retirer des favoris") or L("Clic : ajouter aux favoris") }
    r.onStar = function() H.ToggleFav(g) end
    r.star:Show()
end

-- opens a page of the home: "online", "crafter" (name), "me"
function H.Open(f, page, name)
    if page == "crafter" then
        f.pageFrom = (f.page == "online") and "online" or nil
        f.cpName = name
    else
        f.pageFrom = nil
    end
    f.page, f.view, f.prof = page, nil, nil
    if (f.box:GetText() or "") ~= "" then f.box:SetText("") end
    f.list.Reset(); WP.RefreshOrders()
end
-- a crafter's profile from anywhere (a toast's link); nil or my name: my profile
function WP.OpenCrafterPage(name)
    if WP.ModuleOff and WP.ModuleOff("orders") then return end
    if not win then WP.ShowOrdersTab("find") end
    local f = ui.find
    f.page, f.pageFrom, f.view, f.prof = nil, nil, nil, nil
    if (f.box:GetText() or "") ~= "" then f.box:SetText("") end
    if not name or name == UnitName("player") then f.page = "me" else f.page, f.cpName = "crafter", name end
    WP.ShowOrdersTab("find")
end

-- a row of the crafters lists (online page, favourites, search): class icon, name and state,
-- the details, the star; a click opens the profile
function H.FillGroupRow(f, r, g, offline)
    r.item, r.crafter, r.open, r.askProf = nil, nil, nil, nil
    r.name:SetText(g.name .. "  " .. H.StatusText(g))
    SetClass(r, g.name)
    if not O.ClassOf(g.name) and g.class and S.ClassIcon(r.cls, g.class) then r.cls:Show() end
    local det = H.GroupDetail(g, offline)
    r.detail:SetText(det); r.detail:SetShown(det ~= "")
    r.btn:Hide()
    H.SetStar(r, g)
    r.tip = { H.ClassText(g.name, g.class) }
    if det ~= "" then r.tip[2] = det end
    r.tip[#r.tip + 1] = string.format(L("Clic : voir la fiche de %s"), g.name)
    r.tipFill = nil
    r.onRowClick = function() H.Open(f, "crafter", g.name) end
    r:SetAlpha(offline and 0.6 or 1)
end

-- ---- the home
function H.BuildHome(f)
    if f.hm then return f.hm end
    local c = f.list.content
    local hm = {}
    -- my crafter card: class icon, name, status pill, professions and note, "My profile"
    local card = H.Own(f, CreateFrame("Button", nil, c))
    card.wlOwned = true
    S.Solid(card, "BACKGROUND", C.cardFill):SetAllPoints(); S.Border(card, C.cardEdge)
    Feedback(card)
    if card.RegisterForClicks then pcall(card.RegisterForClicks, card, "LeftButtonUp", "RightButtonUp") end
    card.clsFrame = CreateFrame("Frame", nil, card); card.clsFrame:SetSize(32, 32); S.Border(card.clsFrame, C.cardEdge)
    card.clsFrame:SetPoint("LEFT", 12, 0)
    card.cls = card.clsFrame:CreateTexture(nil, "ARTWORK"); card.cls:SetAllPoints()
    card.name = S.Text(card, F.heading, C.fg); card.name:SetJustifyH("LEFT"); card.name:SetWordWrap(false)
    card.pill = S.Pill(card)
    card.detail = S.Text(card, F.meta, C.muted); card.detail:SetJustifyH("LEFT"); card.detail:SetJustifyV("TOP")
    card.chev = S.Icon(card, "chevron_right", 10, "ARTWORK", C.muted); card.chev:SetPoint("RIGHT", -12, 0)
    card.link = S.Text(card, F.label, C.text); card.link:SetWordWrap(false); card.link:SetText(L("Ma fiche"))
    card.link:SetPoint("RIGHT", card.chev, "LEFT", -4, 0)
    card:SetScript("OnClick", function(_, button)
        if button == "RightButton" then O.CycleStatus(); return end
        H.Open(f, "me")
    end)
    card.tip = { L("Ma fiche d'artisan"), L("Ce que la guilde voit de toi."), L("Clic : modifier ma fiche"), L("Clic droit : changer d'état") }
    hm.card = card
    -- recent searches (the box focused and empty)
    hm.recentHead = H.Own(f, S.Text(c, F.meta, C.muted)); hm.recentHead:SetText(L("Recherches récentes"))
    hm.recentClear = H.Own(f, S.Button(c, L("Effacer"), 0, 24, "ghost", function()
        local d = O.DB(); d.searches = {}; WP.RefreshOrders()
    end, { L("Effacer"), L("Clic : oublier les recherches récentes") }))
    hm.chips = {}
    -- the four tiles
    hm.tiles = {}
    for i, icon in ipairs({ "group", "star", "clock", "flag" }) do
        local t = H.Own(f, CreateFrame("Button", nil, c))
        t.wlOwned = true
        S.Solid(t, "BACKGROUND", C.cardFill):SetAllPoints(); S.Border(t, C.cardEdge)
        Feedback(t)
        t.icon = S.Icon(t, icon, 16, "ARTWORK", C.muted); t.icon:SetPoint("TOPLEFT", 12, -12)
        t.title = S.Text(t, F.heading, C.fg); t.title:SetJustifyH("LEFT"); t.title:SetWordWrap(false); t.title:SetPoint("TOPLEFT", 36, -10)
        t.counter = S.Counter(t); t.counter:SetPoint("TOPRIGHT", -32, -11)
        t.chev = S.Icon(t, "chevron_right", 16, "ARTWORK", C.muted); t.chev:SetPoint("RIGHT", -8, 0)
        t.state = S.Text(t, F.body, C.text); t.state:SetJustifyH("LEFT"); t.state:SetWordWrap(false); t.state:SetPoint("TOPLEFT", 12, -31)
        t.next = S.Text(t, F.meta, C.muted); t.next:SetJustifyH("LEFT"); t.next:SetWordWrap(false)
        t.next:SetPoint("TOPLEFT", t.state, "BOTTOMLEFT", 0, -3)
        t:SetScript("OnClick", function(self) if self.onClick then self.onClick() end end)
        hm.tiles[i] = t
    end
    -- the week's top crafters
    hm.topHead = H.Own(f, S.SectionHeader(c, L("Meilleurs artisans de la semaine"), nil, L("Tout voir"), function()
        H.Filter().seg = "all"; f.onlineSort = "week"; H.Open(f, "online")
    end, true))
    hm.topRows = {}
    hm.topEmpty = H.Own(f, S.Text(c, F.meta, C.muted)); hm.topEmpty:SetJustifyH("LEFT"); hm.topEmpty:SetJustifyV("TOP")
    hm.topEmpty:SetText(L("Personne n'a encore livré de commande cette semaine."))
    -- nobody known but me
    hm.empty = H.Own(f, S.EmptyState(c, "hammer", "", nil, nil, nil))
    f.hm = hm
    return hm
end
function H.TopRow(f, i)
    local hm = f.hm
    local r = hm.topRows[i]
    if r then return r end
    r = H.Own(f, CreateFrame("Button", nil, f.list.content))
    r.wlOwned = true
    r:SetHeight(36)
    S.Solid(r, "BACKGROUND", C.cardFill):SetAllPoints()
    Feedback(r)
    r.rank = S.Text(r, F.label, C.muted); r.rank:SetPoint("LEFT", 4, 0); r.rank:SetWidth(24); r.rank:SetJustifyH("CENTER")
    r.dot = S.Icon(r, "dot", 8, "ARTWORK", C.ok); r.dot:SetPoint("LEFT", 32, 0)
    r.unit = S.Text(r, F.meta, C.muted); r.unit:SetPoint("RIGHT", -8, 0); r.unit:SetWordWrap(false)
    r.num = S.Text(r, F.label, C.fg); r.num:SetPoint("RIGHT", r.unit, "LEFT", -4, 0); r.num:SetWordWrap(false); r.num:SetJustifyH("RIGHT")
    r.name = S.Text(r, F.label, C.fg); r.name:SetPoint("TOPLEFT", 48, -4); r.name:SetJustifyH("LEFT"); r.name:SetWordWrap(false)
    r.detail = S.Text(r, F.meta, C.muted); r.detail:SetPoint("TOPLEFT", r.name, "BOTTOMLEFT", 0, -2)
    r.detail:SetJustifyH("LEFT"); r.detail:SetWordWrap(false)
    r:SetScript("OnClick", function(self) if self.onClick then self.onClick() end end)
    hm.topRows[i] = r
    return r
end

-- my card: returns its height
function H.FillCard(f, card, W)
    local me = UnitName("player")
    local cls = select(2, UnitClass("player"))
    if not S.ClassIcon(card.cls, cls) then card.cls:SetTexture(nil) end
    card.name:SetText(H.ClassText(me, cls))
    -- my profile as the guild sees it: professions, then the note (or what to add)
    local mine = {}
    for prof, pr in pairs(O.DB().mine or {}) do mine[#mine + 1] = { raw = prof, key = prof, rank = pr.rank or 0 } end
    table.sort(mine, function(a, b) if a.rank ~= b.rank then return a.rank > b.rank end return a.raw < b.raw end)
    local note = O.Profile().note
    local det
    if #mine == 0 then det = L("Aucun métier lu : ouvre ta fenêtre de métier une fois.")
    else det = H.ProfText(mine, 3) .. " · " .. ((note ~= "") and H.Quote(note) or L("Ajoute une note pour les acheteurs.")) end
    card.detail:SetText(det)
    card:SetWidth(W)
    local linkW = (root.TextWidth(card.link) or 50) + 4 + 10 + 12
    local textW = math.max(80, W - 56 - linkW - 12)
    card.pill.maxW = 120
    local pw = H.SetPill(card.pill, (O.MyStatus()))
    local nw = math.min((root.TextWidth(card.name) or 80) + 2, textW - (pw > 0 and pw + 8 or 0))
    card.name:SetWidth(math.max(40, nw))
    card.name:ClearAllPoints(); card.name:SetPoint("TOPLEFT", 56, -12)
    card.pill:ClearAllPoints(); card.pill:SetPoint("LEFT", card.name, "RIGHT", 8, 0)
    card.detail:ClearAllPoints(); card.detail:SetPoint("TOPLEFT", card.name, "BOTTOMLEFT", 0, -3)
    local dh = S.FitText(card.detail, 2, textW, card)
    local h = math.max(64, math.ceil(12 + F.heading + 3 + dh + 12))
    card:SetHeight(h)
    card:Show()
    return h
end

-- a tile: title, counter, state line, next line, tooltip (the whole text, then the click), click
function H.FillTile(t, w, title, n, urgent, state, nxt, tip, onClick)
    t:SetSize(w, 72)
    t.title:SetText(title)
    t.counter:SetCount(n, urgent)
    local cw = (n and n > 0) and ((num(t.counter:GetWidth()) or 18) + 8) or 0
    S.FitText(t.title, 1, math.max(40, w - 36 - 32 - cw), t)
    t.state:SetText(state or ""); S.FitText(t.state, 1, math.max(40, w - 12 - 32), t)
    t.next:SetText(nxt or ""); S.FitText(t.next, 1, math.max(40, w - 12 - 32), t)
    local lines = { title }
    if state and state ~= "" then lines[#lines + 1] = state end
    if nxt and nxt ~= "" then lines[#lines + 1] = nxt end
    for _, l in ipairs(tip or {}) do lines[#lines + 1] = l end
    t.tip = lines
    t.onClick = onClick
    t:Show()
end

-- the next step of a recent order, in the words of the order cards
function H.RecentOrderLine(e)
    local st, who = e.st, e.who or "?"
    if e.side == "in" then return string.format(L("De %s"), who) .. " · " .. L(STATUS[st] or "Ouverte") end
    if st == "delivered" then return string.format(L("Livrée par %s"), who) end
    if st == "accepted" then return string.format(L("Prise par %s"), who) end
    if st == "crafted" then return string.format(L("Fabriquée par %s"), who) end
    if st == "declined" then return string.format(L("Refusée par %s"), who) end
    if st == "open" then return e.who and string.format(L("Envoyée à %s"), who) or L("Ouverte à toute la guilde") end
    return L(STATUS[st] or "Ouverte")
end

function H.Home(f)
    local hm = H.BuildHome(f)
    local set = O.CrafterSet()
    f.set = set
    local W = findW
    local d = O.DB()
    local c = f.list.content
    local y = H.FillCard(f, hm.card, W)
    hm.card:ClearAllPoints(); hm.card:SetPoint("TOPLEFT", 0, 0)
    y = y + 12
    -- recent searches, while the box is focused and empty
    local searches = d.searches or {}
    if f.box.HasFocus and f.box:HasFocus() and (f.box:GetText() or "") == "" and #searches > 0 then
        hm.recentHead:ClearAllPoints(); hm.recentHead:SetPoint("TOPLEFT", 0, -(y + 6)); hm.recentHead:Show()
        hm.recentClear:ClearAllPoints(); hm.recentClear:SetPoint("TOPRIGHT", c, "TOPRIGHT", 0, -y); hm.recentClear:Show()
        y = y + 24 + 4
        local x = 0
        for i, q in ipairs(searches) do
            local b = hm.chips[i]
            if not b then
                b = H.Own(f, S.Button(c, "", 0, 24, "secondary", function(self) f.box:SetText(self.q or "") end))
                hm.chips[i] = b
            end
            b.q = q
            b:SetText(q)
            local bw = num(b:GetWidth()) or 80
            if x > 0 and x + bw > W then x, y = 0, y + 24 + 4 end
            b:ClearAllPoints(); b:SetPoint("TOPLEFT", x, -y); b:Show()
            x = x + bw + 4
        end
        y = y + 24 + 12
    end
    -- nobody known but me: one composed block, two ways out
    if set.known == 0 then
        local off = WLWritsDB.ordersShare == false
        return H.SecondaryEmpty(f, hm.empty, y, W, "hammer", L("Aucun artisan connu"),
            L("Les métiers des membres qui utilisent WL Helper apparaîtront ici."),
            off and L("Partager mes recettes") or L("Faire une demande"), function()
                if off then H.ShareOn() else WP.ShowOrdersTab("ask") end
            end,
            off and L("Faire une demande") or L("Ma fiche d'artisan"), function()
                if off then WP.ShowOrdersTab("ask") else H.Open(f, "me") end
            end)
    end
    -- the tiles: 2 x 2 when the side is wide, else one under the other
    local cols = W >= 560 and 2 or 1
    local tw = cols == 2 and math.floor((W - 12) / 2) or W
    local function Place(i, t)
        local col, line = (i - 1) % cols, math.floor((i - 1) / cols)
        t:ClearAllPoints(); t:SetPoint("TOPLEFT", col * (tw + 12), -(y + line * (72 + 12)))
    end
    local T = hm.tiles
    H.TileOnline(f, T[1], tw, set); Place(1, T[1])
    H.TileFavs(f, T[2], tw, set, d); Place(2, T[2])
    H.TileRecent(f, T[3], tw, d); Place(3, T[3])
    H.TileWatch(f, T[4], tw, d); Place(4, T[4])
    y = y + math.ceil(4 / cols) * (72 + 12) - 12
    -- the week's top crafters (self-reported, one per customer per day)
    return H.Top(f, hm, set, y + 16, W)
end

-- A. crafters online: "2 available of 3 online", "1 in your zone"
function H.TileOnline(f, t, tw, set)
    local avail = {}
    for _, g in ipairs(set.list) do if g.available then avail[#avail + 1] = g.name end end
    table.sort(avail)
    local state, nxt
    if set.online == 0 then
        state = L("Personne en ligne pour l'instant")
        nxt = P(set.known, L("1 artisan connu dans la guilde"), L("%d artisans connus dans la guilde"))
    else
        state = set.avail == 1 and string.format(L("1 disponible sur %d en ligne"), set.online)
            or string.format(L("%d disponibles sur %d en ligne"), set.avail, set.online)
        nxt = P(set.zone, L("1 dans ta zone"), L("%d dans ta zone"))
    end
    local tip = {}
    if #avail > 0 then
        tip[1] = string.format(L("Disponibles : %s"), table.concat(avail, ", ", 1, math.min(8, #avail)) .. (#avail > 8 and (" +" .. (#avail - 8)) or ""))
    end
    tip[#tip + 1] = L("Clic : voir les artisans en ligne")
    H.FillTile(t, tw, L("Artisans en ligne"), set.online, false, state, nxt, tip,
        function() H.Filter().seg = "all"; f.onlineSort = nil; H.Open(f, "online") end)
end
-- B. favourites: who of them is online
function H.TileFavs(f, t, tw, set, d)
    local nFav = 0
    for _ in pairs(d.favs or {}) do nFav = nFav + 1 end
    local on = {}
    for _, g in ipairs(set.list) do if g.fav and g.online then on[#on + 1] = g.name end end
    table.sort(on)
    local state, nxt
    if nFav == 0 then state, nxt = L("Aucun favori"), L("Mets une étoile sur un artisan pour le garder ici.")
    else
        nxt = P(nFav, L("1 favori"), L("%d favoris"))
        if #on == 0 then state = L("Aucun favori en ligne")
        elseif #on == 1 then state = string.format(L("%s en ligne"), on[1])
        elseif #on == 2 then state = string.format(L("%s et %s en ligne"), on[1], on[2])
        elseif #on == 3 then state = string.format(L("%s, %s et 1 autre en ligne"), on[1], on[2])
        else state = string.format(L("%s, %s et %d autres en ligne"), on[1], on[2], #on - 2) end
    end
    H.FillTile(t, tw, L("Favoris"), #on, false, state, nxt, { L("Clic : voir mes favoris") },
        function() H.Filter().seg = "fav"; f.onlineSort = nil; H.Open(f, "online") end)
end
-- C. my recent orders (14 days): the newest one and its step
function H.TileRecent(f, t, tw, d)
    local list, now = {}, time()
    for _, e in ipairs(d.recent or {}) do if type(e) == "table" and (e.t or 0) >= now - 14 * 86400 then list[#list + 1] = e end end
    local state, nxt
    local first = list[1]
    if not first then state, nxt = L("Aucune commande récente"), L("Tes commandes des deux dernières semaines apparaîtront ici.")
    else
        local id = first.item or 0
        local qc = id > 0 and S.QualityColor(id) or C.fg
        local nm = (id ~= 0) and Name(id) or (first.title or "?")
        state = S.Hex(qc) .. nm .. "|r ×" .. (first.qty or 1) .. " · " .. string.format(L("il y a %s"), H.Ago(now - (first.t or now)))
        nxt = H.RecentOrderLine(first)
    end
    local inSide = first and first.side == "in"
    H.FillTile(t, tw, L("Mes commandes récentes"), #list, false, state, nxt,
        { inSide and L("Clic : voir les commandes pour moi") or L("Clic : voir mes commandes") },
        function() WP.ShowOrdersTab(inSide and "recv" or "mine") end)
end
-- D. watched recipes: the counter (accent: something to act on) = those someone online makes
function H.TileWatch(f, t, tw, d)
    local ids = {}
    for id in pairs(d.watch or {}) do ids[#ids + 1] = id end
    table.sort(ids)
    local ready, firstWho, firstId, anyone = 0, nil, nil, false
    for _, id in ipairs(ids) do
        local onName
        for _, c in ipairs(O.Crafters(id)) do
            if not c.me then
                anyone = true
                if c.online and not onName then onName = c.name end
            end
        end
        if onName then
            ready = ready + 1
            if not firstWho then firstWho, firstId = onName, id end
        end
    end
    local state, nxt
    if #ids == 0 then state, nxt = L("Aucune recette surveillée"), L("Le drapeau sur un objet te prévient quand un membre l'apprend.")
    elseif firstWho then
        state = string.format(L("%s sait faire %s"), firstWho, Name(firstId))
        nxt = string.format(L("%s est en ligne maintenant."), firstWho)
    else
        state = P(#ids, L("1 recette surveillée"), L("%d recettes surveillées"))
        nxt = anyone and L("Personne en ligne ne sait les faire.") or L("Personne ne sait encore les faire.")
    end
    H.FillTile(t, tw, L("Recettes surveillées"), ready, ready > 0, state, nxt, { L("Clic : voir mes recettes surveillées") },
        function() H.Open(f, "me") end)
end
-- the week's top 5: delivered orders as each crafter reports them
function H.Top(f, hm, set, y, W)
    local hd = hm.topHead
    hd:SetWidth(W); hd:ClearAllPoints(); hd:SetPoint("TOPLEFT", 0, -y); hd:Show()
    hd.link:SetShown(#set.top > 0)
    y = y + 24 + 8
    local n = math.min(5, #set.top)
    for i = 1, n do
        local g = set.top[i]
        local r = H.TopRow(f, i)
        r:SetWidth(W)
        r.rank:SetText(tostring(i))
        local rc = i <= 3 and C.gold or C.muted
        r.rank:SetTextColor(rc[1], rc[2], rc[3])
        local dc = (not g.online) and C.faint or (g.available and C.ok or C.warn)
        r.dot:SetVertexColor(dc[1], dc[2], dc[3])
        r.name:SetText(H.ClassText(g.name, g.class))
        r.detail:SetText(H.ProfText(g.profs, 1) .. (g.stars > 0 and (" · " .. STAR .. " " .. g.stars) or ""))
        r.num:SetText(tostring(g.week))
        r.unit:SetText(g.week == 1 and L("livrée") or L("livrées"))
        local rw = (root.TextWidth(r.num) or 20) + (root.TextWidth(r.unit) or 40) + 4 + 8 + 12
        S.FitText(r.name, 1, math.max(40, W - 48 - rw), r)
        S.FitText(r.detail, 1, math.max(40, W - 48 - rw), r)
        r.tip = { H.ClassText(g.name, g.class), string.format(L("%d commandes livrées ces 7 jours, %d en tout."), g.week, g.tot),
            string.format(L("Annoncé par %s ; tu en as vu %d."), g.name, g.seen), L("Clic : voir sa fiche") }
        r.onClick = function() H.Open(f, "crafter", g.name) end
        r:ClearAllPoints(); r:SetPoint("TOPLEFT", 0, -y); r:Show()
        y = y + 36 + 2
    end
    if n == 0 then
        hm.topEmpty:ClearAllPoints(); hm.topEmpty:SetPoint("TOPLEFT", 0, -y)
        y = y + S.FitText(hm.topEmpty, 0, W, f.list.content)
        hm.topEmpty:Show()
    else y = y - 2 end
    return y + 4
end

-- ---- the pages
function H.Filter()
    local t = WLWritsDB.ordersOnlineFilter
    if type(t) ~= "table" then t = {}; WLWritsDB.ordersOnlineFilter = t end
    if t.seg ~= "all" and t.seg ~= "avail" and t.seg ~= "fav" then t.seg = "all" end
    if type(t.prof) ~= "string" then t.prof = "" end
    return t
end
function H.ShareOn()
    WLWritsDB.ordersShare = true
    O.Announce()
    if O.ShareChanged then O.ShareChanged() end
    WP.RefreshOrders()
end
-- a page's title (14) and its sentence (11 muted); returns where the page goes on
function H.PageTitle(f, key, text, sentence, y, W)
    f.pt = f.pt or {}
    local t = f.pt[key]
    if not t then
        t = { title = H.Own(f, S.Text(f.list.content, F.heading, C.fg)), sub = H.Own(f, S.Text(f.list.content, F.meta, C.muted)) }
        t.title:SetJustifyH("LEFT"); t.title:SetJustifyV("TOP"); t.sub:SetJustifyH("LEFT"); t.sub:SetJustifyV("TOP")
        f.pt[key] = t
    end
    t.title:SetText(text); t.title:ClearAllPoints(); t.title:SetPoint("TOPLEFT", 0, -y); t.title:Show()
    y = y + S.FitText(t.title, 2, W, f.list.content)
    if sentence then
        t.sub:SetText(sentence); t.sub:ClearAllPoints(); t.sub:SetPoint("TOPLEFT", 0, -(y + 3)); t.sub:Show()
        y = y + 3 + S.FitText(t.sub, 0, W, f.list.content)
    end
    return y
end
-- an empty state with a primary action and, when given, a secondary one under it
function H.SecondaryEmpty(f, e, y, W, icon, title, text, label, click, label2, click2)
    e:ClearAllPoints(); e:SetPoint("TOP", f.list.content, "TOP", 0, -(y + 12))
    e:SetWrapWidth(W)
    local h = e:Set(icon, title, text, label, click, "primary") or 0
    e:Show()
    if not e.second then e.second = S.Button(e, "", 0, 28, "secondary", function() if e.onSecond then e.onSecond() end end) end
    if label2 then
        e.second:SetText(label2); e.onSecond = click2
        e.second:ClearAllPoints(); e.second:SetPoint("TOP", e, "TOP", 0, -(h + 8)); e.second:Show()
        h = h + 8 + 28
    else e.second:Hide() end
    return y + 12 + h + 12
end

-- crafters online ("See all"): All / Available / Favourites, a profession, my zone only
function H.Online(f, set)
    local W = findW
    f.onl = f.onl or {}
    local o = f.onl
    local flt = H.Filter()
    local c = f.list.content
    if not o.seg then
        o.seg = H.Own(f, S.Segmented(c, { { "all", L("Tous") }, { "avail", L("Disponibles") }, { "fav", L("Favoris") } },
            function() return H.Filter().seg end, function(v) H.Filter().seg = v; WP.RefreshOrders() end))
        local opts = { { "", L("Tous les métiers") } }
        for _, k in ipairs(GRID_PROFS) do opts[#opts + 1] = { k, ProfLabel(k) } end
        o.prof = H.Own(f, S.Dropdown(c, opts, function() return H.Filter().prof end, function(v) H.Filter().prof = v; WP.RefreshOrders() end, 160))
        o.zoneRow = H.Own(f, CreateFrame("Button", nil, c))
        o.zoneRow:SetHeight(28)
        o.zone = S.Switch(o.zoneRow, function() return H.Filter().zone and true or false end,
            function(v) H.Filter().zone = v and true or nil; WP.RefreshOrders() end, { L("Ma zone seulement"), L("Seulement les artisans dans ta zone") })
        o.zone:SetPoint("RIGHT", 0, 0)
        o.zoneLabel = S.Text(o.zoneRow, F.label, C.text); o.zoneLabel:SetPoint("RIGHT", o.zone, "LEFT", -8, 0); o.zoneLabel:SetText(L("Ma zone seulement"))
        o.zoneLabel:SetWordWrap(false)
        o.zone:AttachRow(o.zoneRow)
        o.offHead = H.Own(f, Header(c))
        o.empty = H.Own(f, S.EmptyState(c, "group", "", nil, nil, nil))
    end
    local y = H.PageTitle(f, "online", L("Artisans en ligne"), nil, 0, W) + 8
    o.seg:SetMaxWidth(W); o.seg:Update()
    o.seg:ClearAllPoints(); o.seg:SetPoint("TOPLEFT", 0, -y); o.seg:Show()
    y = y + 28 + 8
    o.prof:Update(); o.prof:ClearAllPoints(); o.prof:SetPoint("TOPLEFT", 0, -y); o.prof:Show()
    local lw = root.TextWidth(o.zoneLabel) or 100
    if lw <= 0 then lw = 100 end
    o.zoneRow:SetWidth(40 + 8 + lw); o.zone:Update()
    if W < 160 + 12 + 40 + 8 + lw then y = y + 28 + 8; o.zoneRow:ClearAllPoints(); o.zoneRow:SetPoint("TOPLEFT", 0, -y)
    else o.zoneRow:ClearAllPoints(); o.zoneRow:SetPoint("TOPRIGHT", c, "TOPRIGHT", 0, -y) end
    o.zoneRow:Show()
    y = y + 28 + 12
    -- who shows: online, then the filters; the Favourites segment adds the offline ones under them
    local myZone = GetRealZoneText and GetRealZoneText() or nil
    local function HasProf(g)
        if flt.prof == "" then return true end
        for _, pr in ipairs(g.profs) do if ProfKey(pr.raw or pr.key) == flt.prof or ProfKey(pr.key) == flt.prof then return true end end
        return false
    end
    local function Keep(g)
        if flt.seg == "avail" and not g.available then return false end
        if flt.seg == "fav" and not g.fav then return false end
        if flt.zone and g.zone ~= myZone then return false end
        return HasProf(g)
    end
    local list, offline = {}, {}
    for _, g in ipairs(set.list) do
        if g.online and Keep(g) then list[#list + 1] = g
        elseif not g.online and flt.seg == "fav" and g.fav and HasProf(g) then offline[#offline + 1] = g end
    end
    local function Best(g) return g.profs[1] and g.profs[1].rank or 0 end
    table.sort(list, function(a, b)
        if f.onlineSort == "week" and a.week ~= b.week then return a.week > b.week end
        if a.available ~= b.available then return a.available end
        if a.fav ~= b.fav then return a.fav end
        local za, zb = (myZone ~= nil and a.zone == myZone), (myZone ~= nil and b.zone == myZone)
        if za ~= zb then return za end
        if a.week ~= b.week then return a.week > b.week end
        if Best(a) ~= Best(b) then return Best(a) > Best(b) end
        return a.name < b.name
    end)
    table.sort(offline, function(a, b)
        if (a.lastOnline or 1e12) ~= (b.lastOnline or 1e12) then return (a.lastOnline or 1e12) < (b.lastOnline or 1e12) end
        return a.name < b.name
    end)
    local i = 0
    for _, g in ipairs(list) do
        if i >= 100 then break end
        i = i + 1
        local r = f.list.Get(i)
        H.FillGroupRow(f, r, g, false)
        local rh = r:Fit(W)
        r:ClearAllPoints(); r:SetPoint("TOPLEFT", 0, -y)
        y = y + rh + 2
    end
    if #offline > 0 then
        o.offHead:SetWidth(W); o.offHead:Set(L("Hors ligne"), #offline)
        o.offHead:ClearAllPoints(); o.offHead:SetPoint("TOPLEFT", 0, -(y + 8)); o.offHead:Show()
        y = y + 8 + 32 + 8
        for _, g in ipairs(offline) do
            if i >= 150 then break end
            i = i + 1
            local r = f.list.Get(i)
            H.FillGroupRow(f, r, g, true)
            local rh = r:Fit(W)
            r:ClearAllPoints(); r:SetPoint("TOPLEFT", 0, -y)
            y = y + rh + 2
        end
    end
    f.list.HideFrom(i + 1)
    if i == 0 then
        if set.online == 0 then
            -- nobody online at all: a request still reaches them when they log in
            local off = WLWritsDB.ordersShare == false
            y = H.SecondaryEmpty(f, o.empty, y, W, "group", L("Aucun artisan en ligne"),
                L("Ta demande reste ouverte : les artisans la verront en se connectant."),
                L("Faire une demande"), function() WP.ShowOrdersTab("ask") end,
                off and L("Partager mes recettes") or nil, H.ShareOn)
        else
            y = H.SecondaryEmpty(f, o.empty, y, W, "search", L("Aucun artisan ne correspond à ces filtres."), nil,
                L("Voir tous les artisans en ligne"), function()
                    local t = H.Filter(); t.seg, t.prof, t.zone = "all", "", nil; WP.RefreshOrders()
                end)
        end
    end
    return y
end

-- a crafter's profile: who, where, their note and counts, the star; then one row per character
-- and profession (a click shows the recipes)
function H.Crafter(f, set)
    local W = findW
    local name = f.cpName or "?"
    local g = set.byName[name]
    f.cp = f.cp or {}
    local cp = f.cp
    local c = f.list.content
    if not cp.head then
        local h = H.Own(f, CreateFrame("Frame", nil, c))
        h.wlOwned = true
        S.Solid(h, "BACKGROUND", C.cardFill):SetAllPoints(); S.Border(h, C.cardEdge)
        h.clsFrame = CreateFrame("Frame", nil, h); h.clsFrame:SetSize(40, 40); S.Border(h.clsFrame, C.cardEdge)
        h.clsFrame:SetPoint("TOPLEFT", 12, -12)
        h.cls = h.clsFrame:CreateTexture(nil, "ARTWORK"); h.cls:SetAllPoints()
        h.name = S.Text(h, F.heading, C.fg); h.name:SetJustifyH("LEFT"); h.name:SetWordWrap(false)
        h.pill = S.Pill(h)
        h.line = S.Text(h, F.meta, C.muted); h.line:SetJustifyH("LEFT"); h.line:SetJustifyV("TOP")
        h.note = S.Text(h, F.body, C.text); h.note:SetJustifyH("LEFT"); h.note:SetJustifyV("TOP")
        h.stats = S.Text(h, F.meta, C.muted); h.stats:SetJustifyH("LEFT"); h.stats:SetJustifyV("TOP")
        h.star = S.IconButton(h, "star", 28, function() return h.starTip end, function() if h.onStar then h.onStar() end end)
        h.star:SetPoint("TOPRIGHT", -8, -8)
        cp.head = h
        cp.profHead = H.Own(f, Header(c))
    end
    local h = cp.head
    local m = O.Member(name) or {}
    local cls = (g and g.class) or m.class or O.ClassOf(name)
    if not S.ClassIcon(h.cls, cls) then h.cls:SetTexture(nil) end
    h.name:SetText(H.ClassText(name, cls))
    local online = (g and g.online) or (m.online and true) or false
    local textW = W - 64 - 40
    h.pill.maxW = 120
    local pw = H.SetPill(h.pill, online and g and g.status or nil)
    h.name:SetWidth(math.max(40, math.min((root.TextWidth(h.name) or 80) + 2, textW - (pw > 0 and pw + 8 or 0))))
    h.name:ClearAllPoints(); h.name:SetPoint("TOPLEFT", 64, -12)
    h.pill:ClearAllPoints(); h.pill:SetPoint("LEFT", h.name, "RIGHT", 8, 0)
    local lvl = (g and g.level) or m.level
    local line = {}
    if lvl then
        local cn = cls and LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[cls]
        line[#line + 1] = cn and string.format(L("Niveau %d %s"), lvl, cn) or string.format(L("Niveau %d"), lvl)
    end
    if not online then
        local lo = (g and g.lastOnline) or m.lastOnline
        line[#line + 1] = lo and string.format(L("Vu il y a %s"), H.Ago(lo)) or L("hors ligne")
    elseif g and g.zone then line[#line + 1] = g.zone end
    if g and g.alts > 0 then line[#line + 1] = P(g.alts, L("+1 reroll"), L("+%d rerolls")) end
    h.line:SetText(table.concat(line, " · ")); h.line:SetShown(#line > 0)
    local y = 12 + F.heading + 4
    h.line:ClearAllPoints(); h.line:SetPoint("TOPLEFT", 64, -y)
    if #line > 0 then y = y + S.FitText(h.line, 2, textW, h) end
    local note = g and g.note
    h.note:SetShown(note ~= nil)
    if note then
        h.note:SetText(H.Quote(note)); h.note:ClearAllPoints(); h.note:SetPoint("TOPLEFT", 64, -(y + 4))
        y = y + 4 + S.FitText(h.note, 3, textW, h)
    end
    local stars = g and g.stars or O.Stars(name)
    h.stats:SetText(STAR .. " " .. stars .. " · " .. string.format(L("%d livrées cette semaine · %d en tout"), g and g.week or 0, g and g.tot or 0))
    h.stats:ClearAllPoints(); h.stats:SetPoint("TOPLEFT", 64, -(y + 4))
    y = y + 4 + S.FitText(h.stats, 1, textW, h)
    local grp = g or { name = name, fav = O.IsFav(name), chars = { { name = name } } }
    h.star:SetToggled(grp.fav)
    h.starTip = { grp.fav and L("Retirer des favoris") or L("Ajouter aux favoris"), grp.fav and L("Clic : retirer des favoris") or L("Clic : ajouter aux favoris") }
    h.onStar = function() H.ToggleFav(grp) end
    local hh = math.max(64, math.ceil(y + 12))
    h:SetSize(W, hh); h:ClearAllPoints(); h:SetPoint("TOPLEFT", 0, 0); h:Show()
    y = hh + 16
    cp.profHead:SetWidth(W); cp.profHead:Set(L("Métiers"))
    cp.profHead:ClearAllPoints(); cp.profHead:SetPoint("TOPLEFT", 0, -y); cp.profHead:Show()
    y = y + 32 + 8
    local rows = {}
    for _, ch in ipairs((g and g.chars) or { { name = name } }) do
        for pname, pr in pairs(O.DB().crafters[ch.name] or {}) do
            if type(pr) == "table" then
                local n = 0
                for _ in pairs(pr.recipes or {}) do n = n + 1 end
                rows[#rows + 1] = { char = ch.name, raw = pname, rank = pr.rank or 0, n = n }
            end
        end
    end
    table.sort(rows, function(a, b)
        if (a.char == name) ~= (b.char == name) then return a.char == name end
        if a.rank ~= b.rank then return a.rank > b.rank end
        if a.raw ~= b.raw then return a.raw < b.raw end
        return a.char < b.char
    end)
    for i, e in ipairs(rows) do
        local r = f.list.Get(i)
        local key = ProfKey(e.raw) or ProfKey(O.ProfKeyOf(e.raw))
        r.item, r.crafter, r.open, r.askProf = nil, nil, nil, nil
        SetItem(r, ProfIcon(key), nil)
        local label = string.format(L("%s %d"), ProfLabel(key, e.raw), e.rank)
        if e.char ~= name then label = label .. " · " .. string.format(L("%s (reroll)"), e.char) end
        r.name:SetText(label)
        r.detail:SetText(e.n > 0 and P(e.n, L("1 recette"), L("%d recettes")) or L("rien de partagé")); r.detail:Show()
        r.btn:Hide()
        r.tip = { label, e.n > 0 and string.format(L("Clic : voir les recettes de %s"), e.char)
            or string.format(L("Pas encore de recettes partagées par %s. Elles arrivent quand ce membre ouvre sa fenêtre de métier."), e.char) }
        r.tipFill = nil
        r.onRowClick = function()
            if e.n == 0 then return end   -- nothing to show: the tooltip says why
            f.view = { name = e.char, prof = e.raw }; f.list.Reset(); WP.RefreshOrders()
        end
        local rh = r:Fit(W)
        r:ClearAllPoints(); r:SetPoint("TOPLEFT", 0, -y)
        y = y + rh + 2
    end
    f.list.HideFrom(#rows + 1)
    if #rows == 0 then
        cp.profHead:Hide()
        local eh = Empty(f.empty, true, "clock", L("Recettes pas encore arrivées"), L("Elles arrivent quand ce membre ouvre sa fenêtre de métier."))
        f.empty:ClearAllPoints(); f.empty:SetPoint("TOP", c, "TOP", 0, -(hh + 16 + 24))
        y = hh + 16 + eh
    end
    return y
end

-- a settings row of my profile: label 13, sentence 11 under it, the switch (or a control) at the right
function H.SwitchRow(f, label, desc, get, set, tip)
    local r = H.Own(f, CreateFrame("Button", nil, f.list.content))
    r.wlOwned = true
    S.Solid(r, "BACKGROUND", C.cardFill):SetAllPoints(); S.Border(r, C.cardEdge)
    r.label = S.Text(r, F.body, C.fg); r.label:SetPoint("TOPLEFT", 12, -10); r.label:SetJustifyH("LEFT"); r.label:SetText(label)
    S.ClampLabel(r.label, nil, r)
    r.desc = S.Text(r, F.meta, C.muted); r.desc:SetJustifyH("LEFT"); r.desc:SetJustifyV("TOP")
    r.desc:SetPoint("TOPLEFT", r.label, "BOTTOMLEFT", 0, -3); r.desc:SetText(desc)
    if get then
        r.switch = S.Switch(r, get, set, tip)
        r.switch:SetPoint("RIGHT", -12, 0)
        r.switch:AttachRow(r)
    end
    -- rightW: the control's width at the right (40 for a switch)
    function r:Fit(width, rightW)
        self:SetWidth(width)
        local tw = width - 12 - (rightW or 40) - 24
        self.label:SetWidth(math.max(40, tw))
        local dh = S.FitText(self.desc, 2, math.max(40, tw), self)
        local h = math.max(44, math.ceil(10 + F.body + 3 + dh + 10))
        self:SetHeight(h)
        if self.switch then self.switch:Update() end
        return h
    end
    return r
end

-- a dense row of my profile (a profession, a watched recipe, a favourite) from the list's pool
function H.DenseRow(f, i, y, W, tex, id, name, detail, tip)
    local r = f.list.Get(i)
    r.item, r.crafter, r.open, r.askProf = nil, nil, nil, nil
    SetItem(r, tex, id)
    r.name:SetText(name)
    r.detail:SetText(detail or ""); r.detail:SetShown(detail ~= nil and detail ~= "")
    r.btn:Hide()
    r.tip, r.tipFill = tip, nil
    return r
end

-- ---- my crafter profile: status, note, my professions, what I share, alerts, watched, favourites
function H.Me(f)
    local W = findW
    local c = f.list.content
    f.me = f.me or {}
    local m = f.me
    if not m.seg then
        m.seg = H.Own(f, S.Segmented(c, { { "a", O.StatusWord("a") }, { "b", O.StatusWord("b") }, { "o", O.StatusWord("o") } },
            function() return O.BaseStatus() end, function(v) O.SetCrafterStatus(v) end))
        m.banner = H.Own(f, S.Banner(c, "info", ""))
        m.note = H.Own(f, S.Input(c, W, { label = L("Note pour les acheteurs"), placeholder = L("Ex. Je fournis le charbon, 5 po la pièce."),
            onEnter = function(t) H.SaveNote(f, t) end }))
        m.note:SetMaxLetters(200)
        if m.note.label then H.Own(f, m.note.label) end
        m.note:HookScript("OnEditFocusLost", function(self) H.SaveNote(f, self:GetText() or "") end)
        m.note:HookScript("OnTextChanged", function(self)
            m.count:SetText(string.format("%d/50", math.min(50, O.NoteLength(O.CleanNote(self:GetText() or "")))))
        end)
        m.count = H.Own(f, S.Text(c, F.foot or F.meta, C.muted)); m.count:SetJustifyH("RIGHT")
        m.noteErr = H.Own(f, S.Text(c, F.meta, C.bad)); m.noteErr:SetJustifyH("LEFT"); m.noteErr:SetJustifyV("TOP")
        m.noteErr:SetText(L("Les liens ne passent pas dans la note : écris le nom en toutes lettres."))
        m.profHead = H.Own(f, Header(c))
        m.setHead = H.Own(f, Header(c))
        m.alertHead = H.Own(f, Header(c))
        m.watchHead = H.Own(f, Header(c))
        m.favHead = H.Own(f, Header(c))
        local p = function() return O.Profile() end
        m.rows = {
            share = H.SwitchRow(f, L("Partager mes recettes"), L("La guilde voit ce que tu sais fabriquer."),
                function() return WLWritsDB.ordersShare ~= false end, function(v) if v then H.ShareOn() else WLWritsDB.ordersShare = false; O.ShareChanged(); WP.RefreshOrders() end end),
            hideAlts = H.SwitchRow(f, L("Cacher mes rerolls"), L("Tes autres personnages n'apparaissent pas sous ton nom."),
                function() return p().hideAlts end, function(v) O.SetProfileFlag("hideAlts", v and true or false) end),
            showZone = H.SwitchRow(f, L("Montrer ma zone"), L("Ta zone s'affiche sur ta fiche d'artisan. La liste de guilde du jeu la montre quand même."),
                function() return p().showZone ~= false end, function(v) O.SetProfileFlag("showZone", v and true or false) end),
            quiet = H.SwitchRow(f, L("Mode calme en donjon"), L("En donjon, raid ou champ de bataille, les commandes attendent sans bruit ; l'acheteur sait où tu es."),
                function() return p().quiet end, function(v) O.SetProfileFlag("quiet", v and true or false) end),
            autoBusy = H.SwitchRow(f, L("Occupé tout seul"), L("Quand tu es absent (AFK) ou en file d'attente. Ton état revient ensuite."),
                function() return p().autoBusy end, function(v) O.SetProfileFlag("autoBusy", v and true or false) end),
            main = H.SwitchRow(f, L("Personnage principal"), L("Tes rerolls sont regroupés sous ce nom.")),
            alertFav = H.SwitchRow(f, L("Prévenir quand un favori se connecte"), L("Une alerte au plus toutes les 30 min par favori."),
                function() return WLWritsDB.ordersAlertFav ~= false end, function(v) WLWritsDB.ordersAlertFav = v and true or false end),
            alertWatch = H.SwitchRow(f, L("Prévenir quand une recette surveillée est apprise"), L("Une fois par membre et par recette."),
                function() return WLWritsDB.ordersAlertWatch ~= false end, function(v) WLWritsDB.ordersAlertWatch = v and true or false end),
        }
        m.mainDD = S.Dropdown(m.rows.main, { { "", L("Automatique") } }, function() return O.Profile().main or "" end,
            function(v) O.SetProfileFlag("main", (v ~= "" and v) or nil) end, 160)
        m.mainDD:SetPoint("RIGHT", -12, 0)
        m.empty = H.Own(f, S.Text(c, F.meta, C.muted)); m.empty:SetJustifyH("LEFT"); m.empty:SetJustifyV("TOP")
        m.empty2 = H.Own(f, S.Text(c, F.meta, C.muted)); m.empty2:SetJustifyH("LEFT"); m.empty2:SetJustifyV("TOP")
    end
    local y = H.PageTitle(f, "me", L("Ma fiche d'artisan"), L("Ce que la guilde voit quand elle cherche un artisan."), 0, W) + 12
    -- state
    m.seg:SetMaxWidth(W); m.seg:Update()
    m.seg:ClearAllPoints(); m.seg:SetPoint("TOPLEFT", 0, -y); m.seg:Show()
    y = y + 28
    local s, why = O.MyStatus()
    local bt = (why == "afk" and L("Occupé tout seul : tu es absent (AFK).")) or (why == "queue" and L("Occupé tout seul : tu es en file d'attente."))
        or (why == "inst" and L("En donjon : tes commandes attendent sans bruit.")) or nil
    if bt then
        m.banner:SetText(bt, "info"); m.banner:SetWidth(W)
        m.banner:ClearAllPoints(); m.banner:SetPoint("TOPLEFT", 0, -(y + 8)); m.banner:Show()
        y = y + 8 + m.banner:Fit(W)
    end
    -- the note (saved on Enter or when the box loses the focus)
    y = y + 16
    m.note:SetWidth(W)
    m.note:ClearAllPoints(); m.note:SetPoint("TOPLEFT", 0, -(y + 16)); m.note:Show()
    if m.note.label then m.note.label:Show() end
    if not m.note:HasFocus() then m.note:SetText(O.Profile().note or "") end
    y = y + 16 + 28
    m.count:SetText(string.format("%d/50", O.NoteLength(O.CleanNote(m.note:GetText() or ""))))
    m.count:ClearAllPoints(); m.count:SetPoint("TOPRIGHT", c, "TOPRIGHT", 0, -(y + 4)); m.count:Show()
    if m.linkErr then
        m.noteErr:ClearAllPoints(); m.noteErr:SetPoint("TOPLEFT", 0, -(y + 4)); m.noteErr:Show()
        y = y + 4 + S.FitText(m.noteErr, 2, W - 48, c)
    else y = y + 4 + 12 end
    -- my professions
    y = y + 16
    m.profHead:SetWidth(W); m.profHead:Set(L("Mes métiers"))
    m.profHead:ClearAllPoints(); m.profHead:SetPoint("TOPLEFT", 0, -y); m.profHead:Show()
    y = y + 32 + 8
    local mine = {}
    for prof, pr in pairs(O.DB().mine or {}) do
        if type(pr) == "table" then
            local n = 0
            for _ in pairs(pr.recipes or {}) do n = n + 1 end
            mine[#mine + 1] = { raw = prof, rank = pr.rank or 0, max = pr.max or 0, n = n }
        end
    end
    table.sort(mine, function(a, b) if a.rank ~= b.rank then return a.rank > b.rank end return a.raw < b.raw end)
    local i = 0
    local share = WLWritsDB.ordersShare ~= false
    for _, e in ipairs(mine) do
        i = i + 1
        local key = ProfKey(e.raw) or ProfKey(O.ProfKeyOf(e.raw))
        local label = ProfLabel(key, e.raw) .. " " .. e.rank .. (e.max > 0 and ("/" .. e.max) or "")
        local det = share and P(e.n, L("1 recette partagée"), L("%d recettes partagées")) or P(e.n, L("1 recette, non partagée"), L("%d recettes, non partagées"))
        local r = H.DenseRow(f, i, y, W, ProfIcon(key), nil, label, det, { label, det })
        local rh = r:Fit(W)
        r:ClearAllPoints(); r:SetPoint("TOPLEFT", 0, -y)
        y = y + rh + 2
    end
    if #mine == 0 then
        m.empty:SetText(L("Aucun métier lu : ouvre ta fenêtre de métier une fois."))
        m.empty:ClearAllPoints(); m.empty:SetPoint("TOPLEFT", 0, -y); m.empty:Show()
        y = y + S.FitText(m.empty, 0, W, c) + 2
    end
    -- what the guild sees
    y = y + 14
    m.setHead:SetWidth(W); m.setHead:Set(L("Ce que la guilde voit"))
    m.setHead:ClearAllPoints(); m.setHead:SetPoint("TOPLEFT", 0, -y); m.setHead:Show()
    y = y + 32 + 8
    -- the alts it hides, in the tooltip of its row
    local alts = {}
    for n in pairs(O.Profile().alts) do if n ~= UnitName("player") then alts[#alts + 1] = n end end
    table.sort(alts)
    m.rows.hideAlts.tip = { L("Cacher mes rerolls"), #alts > 0 and string.format(L("Mes rerolls : %s"), table.concat(alts, ", "))
        or L("Aucun reroll connu : chacun s'ajoute en se connectant dans la guilde."), L("Clic : changer") }
    local opts = { { "", L("Automatique") } }
    local allAlts = {}
    for n in pairs(O.Profile().alts) do allAlts[#allAlts + 1] = n end
    table.sort(allAlts)
    for _, n in ipairs(allAlts) do opts[#opts + 1] = { n, n } end
    m.mainDD.options = opts
    m.mainDD:Update()
    for _, k in ipairs({ "share", "hideAlts", "showZone", "quiet", "autoBusy", "main" }) do
        local r = m.rows[k]
        local rh = r:Fit(W, k == "main" and 160 or 40)
        r:ClearAllPoints(); r:SetPoint("TOPLEFT", 0, -y); r:Show()
        y = y + rh + 2
    end
    -- alerts
    y = y + 14
    m.alertHead:SetWidth(W); m.alertHead:Set(L("Alertes"))
    m.alertHead:ClearAllPoints(); m.alertHead:SetPoint("TOPLEFT", 0, -y); m.alertHead:Show()
    y = y + 32 + 8
    for _, k in ipairs({ "alertFav", "alertWatch" }) do
        local r = m.rows[k]
        local rh = r:Fit(W, 40)
        r:ClearAllPoints(); r:SetPoint("TOPLEFT", 0, -y); r:Show()
        y = y + rh + 2
    end
    -- watched recipes
    local d = O.DB()
    local ids = {}
    for id in pairs(d.watch or {}) do ids[#ids + 1] = id end
    table.sort(ids, function(a, b) return Name(a) < Name(b) end)
    y = y + 14
    m.watchHead:SetWidth(W); m.watchHead:Set(L("Recettes surveillées"), #ids > 0 and #ids or nil)
    m.watchHead:ClearAllPoints(); m.watchHead:SetPoint("TOPLEFT", 0, -y); m.watchHead:Show()
    y = y + 32 + 8
    for _, id in ipairs(ids) do
        i = i + 1
        local who, on = {}, false
        for _, cr in ipairs(O.Crafters(id)) do
            if not cr.me then who[#who + 1] = cr.name; if cr.online then on = true end end
        end
        local det = #who == 0 and L("Personne ne sait la faire")
            or (table.concat(who, ", ", 1, math.min(3, #who)) .. (#who > 3 and (" +" .. (#who - 3)) or "") .. (on and L(" · en ligne") or ""))
        local qc = id > 0 and S.QualityColor(id) or C.fg
        local r = H.DenseRow(f, i, y, W, ItemTex(id), id, Name(id), det, { S.Hex(qc) .. Name(id) .. "|r", det,
            #who > 0 and L("Clic : commander") or L("Clic : faire une demande à la guilde") })
        r.trash:Show()
        r.trashTip = { L("Ne plus surveiller"), L("Clic : ne plus surveiller") }
        r.onTrash = function() O.ToggleWatch(id); WP.RefreshOrders() end
        r.onRowClick = function()
            if #who > 0 then WP.NewOrder(id, nil) elseif WP.AskOrder then WP.AskOrder(id) end
        end
        local rh = r:Fit(W)
        r:ClearAllPoints(); r:SetPoint("TOPLEFT", 0, -y)
        y = y + rh + 2
    end
    if #ids == 0 then
        m.empty2:SetText(L("Le drapeau sur un objet te prévient quand un membre l'apprend."))
        m.empty2:ClearAllPoints(); m.empty2:SetPoint("TOPLEFT", 0, -y); m.empty2:Show()
        y = y + S.FitText(m.empty2, 0, W, c) + 2
    end
    -- favourites (offline ones too)
    local favs = {}
    for n in pairs(d.favs or {}) do favs[#favs + 1] = n end
    table.sort(favs)
    y = y + 14
    m.favHead:SetWidth(W); m.favHead:Set(L("Favoris"), #favs > 0 and #favs or nil)
    m.favHead:ClearAllPoints(); m.favHead:SetPoint("TOPLEFT", 0, -y); m.favHead:Show()
    y = y + 32 + 8
    local set = f.set or O.CrafterSet()
    for _, n in ipairs(favs) do
        i = i + 1
        local g = set.byName[n] or { name = n, fav = true, chars = { { name = n } }, profs = {}, alts = 0, online = O.OnlineGuild()[n] and true or false }
        local r = f.list.Get(i)
        H.FillGroupRow(f, r, g, not g.online)
        if g.name ~= n then r.name:SetText(n .. "  " .. H.StatusText(g)) end
        local rh = r:Fit(W)
        r:ClearAllPoints(); r:SetPoint("TOPLEFT", 0, -y)
        y = y + rh + 2
    end
    f.list.HideFrom(i + 1)
    if #favs == 0 then y = y + 0 else y = y - 2 end
    return y + 4
end
function H.SaveNote(f, t)
    local cur = O.Profile().note or ""
    local _, link = O.SetNote(t)
    f.me = f.me or {}
    f.me.linkErr = link and true or nil
    if link or O.Profile().note ~= cur then WP.RefreshOrders() end
end

-- ---- search results: players, items, materials (each group capped, "See N more")
function H.Search(f, q)
    local W = findW
    local c = f.list.content
    f.sr = f.sr or { heads = {}, more = {} }
    local sr = f.sr
    local set = O.CrafterSet()
    f.set = set
    f.searchCaps = f.searchCaps or {}
    local res = O.Search(q, f.searchCaps, set)
    local y, i, gi = 0, 0, 0
    local function Head(label, total)
        gi = gi + 1
        local h = sr.heads[gi]
        if not h then h = H.Own(f, S.SectionHeader(c, "", nil, nil, nil, true)); sr.heads[gi] = h end
        h:SetWidth(W); h:Set(label, total)
        h:ClearAllPoints(); h:SetPoint("TOPLEFT", 0, -(y + (y > 0 and 16 or 0))); h:Show()
        y = y + (y > 0 and 16 or 0) + 24 + 8
    end
    local function More(key, g)
        if g.total <= #g.list then return end
        local b = sr.more[key]
        if not b then
            b = H.Own(f, S.Button(c, "", 0, 24, "ghost", function() f.searchCaps[key] = 200; WP.RefreshOrders() end))
            sr.more[key] = b
        end
        b:SetText(string.format(L("Voir les %d autres"), g.total - #g.list))
        b.tip = { b:GetText(), L("Clic : tout montrer") }
        b:ClearAllPoints(); b:SetPoint("TOPLEFT", 0, -(y + 2)); b:Show()
        y = y + 2 + 24
    end
    local function Save() O.AddSearch(f.box:GetText() or "") end
    -- players
    if res.players.total > 0 then
        Head(L("Joueurs"), res.players.total)
        for _, g in ipairs(res.players.list) do
            i = i + 1
            local r = f.list.Get(i)
            H.FillGroupRow(f, r, g, not g.online)
            r.onRowClick = function() Save(); H.Open(f, "crafter", g.name) end
            local rh = r:Fit(W)
            r:ClearAllPoints(); r:SetPoint("TOPLEFT", 0, -y)
            y = y + rh + 2
        end
        y = y - 2
        More("players", res.players)
    end
    -- items
    if res.items.total > 0 or res.use ~= nil then
        local useName = res.use and Name(res.use)
        Head(useName and string.format(L("Objets faits avec %s"), useName) or L("Objets"), res.items.total)
        for _, it in ipairs(res.items.list) do
            i = i + 1
            local id = it.id
            local det = it.online and string.format(L("%s · %s en ligne"), P(it.n, L("1 artisan"), L("%d artisans")), it.online)
                or string.format(L("%s · personne en ligne"), P(it.n, L("1 artisan"), L("%d artisans")))
            local r = H.DenseRow(f, i, y, W, ItemTex(id), id, it.name, det, nil)
            r.item, r.crafter = id, nil
            r.btn:SetText(L("Commander")); r.btn:Show()
            r.btnTip = { L("Commander"), L("Toute la guilde verra ta commande."), L("Clic : commander à la guilde") }
            local qc = id > 0 and S.QualityColor(id) or C.fg
            r.tip = { S.Hex(qc) .. it.name .. "|r", det, L("Clic : voir qui le fabrique"), id > 0 and L("Maj-clic : le lier dans la discussion") or nil }
            H.SetFlag(r, id)
            r.onRowClick = function()
                Save()
                local link = id > 0 and select(2, GetItemInfo(id))
                if IsShiftKeyDown and IsShiftKeyDown() and link and ChatEdit_InsertLink then
                    if not f.box:HasFocus() then ChatEdit_InsertLink(link) end
                    return
                end
                if id > 0 then f.box:SetText(link or ("item:" .. id)) else WP.NewOrder(id, nil) end
            end
            local rh = r:Fit(W)
            r:ClearAllPoints(); r:SetPoint("TOPLEFT", 0, -y)
            y = y + rh + 2
        end
        y = y - 2
        More("items", res.items)
    end
    -- materials
    if res.mats.total > 0 then
        Head(L("Composants"), res.mats.total)
        for _, mt in ipairs(res.mats.list) do
            i = i + 1
            local det = P(mt.n, L("Utilisé dans 1 recette"), L("Utilisé dans %d recettes"))
            local r = H.DenseRow(f, i, y, W, S.ItemIcon(mt.id), mt.id, mt.name, det,
                { mt.name, det, L("Clic : voir les objets faits avec") })
            r.onRowClick = function() Save(); f.box:SetText(L("Utilise : ") .. mt.name) end
            local rh = r:Fit(W)
            r:ClearAllPoints(); r:SetPoint("TOPLEFT", 0, -y)
            y = y + rh + 2
        end
        y = y - 2
        More("mats", res.mats)
    end
    f.list.HideFrom(i + 1)
    -- nothing: what the search covers, and asking the guild instead
    if i == 0 then
        if not sr.empty then sr.empty = H.Own(f, S.EmptyState(c, "search", "", nil, nil, nil, "secondary")) end
        local text = (tostring(q or ""):gsub("^%s+", ""):gsub("%s+$", ""))
        local short = text
        if #short > 40 then short = short:sub(1, 40):gsub("[\192-\255][\128-\191]*$", "") end
        y = H.SecondaryEmpty(f, sr.empty, 0, W, "search", string.format(L("Rien pour %s"), H.Quote(short)),
            L("La recherche couvre les joueurs, les objets et les composants de la guilde."),
            string.format(L("Demander %s à la guilde"), H.Quote(short)), function()
                if WP.AskOrder then WP.AskOrder(nil) end
                if ui.ask and ui.ask.box then ui.ask.box:SetText(text) end
            end)
        sr.empty.button:SetKind("secondary")
    end
    return y + 4
end

-- a page of the home (f.page): the crafters online, a crafter's profile, my profile
function H.RenderPage(f)
    local set = O.CrafterSet()
    f.set = set
    f.back:SetText(f.pageFrom == "online" and L("Artisans en ligne") or L("Accueil"))
    local y
    if f.page == "online" then y = H.Online(f, set)
    elseif f.page == "crafter" then y = H.Crafter(f, set)
    else y = H.Me(f) end
    f.list.content:SetHeight(math.max(1, y))
    return y
end

-- the crafters' home (T-60): its words in English
ns.AddEnglish({
    ["Artisans, favoris, recherche"] = "Crafters, favourites, search",
    ["Clic : revenir à l'accueil des artisans"] = "Click: back to the crafters' home",
    ["Clic : revenir à la fiche de %s"] = "Click: back to %s's profile",
    ["Ex. Brakk, Heaume cœur-de-lion, Étoffe runique"] = "E.g. Brakk, Lionheart Helm, Runecloth",
    ["Recherches récentes"] = "Recent searches",
    ["Clic : oublier les recherches récentes"] = "Click: forget the recent searches",
    ["Ma fiche"] = "My profile",
    ["Ma fiche d'artisan"] = "My crafter profile",
    ["Ce que la guilde voit de toi."] = "What the guild sees about you.",
    ["Clic : modifier ma fiche"] = "Click: edit my profile",
    ["Clic droit : changer d'état"] = "Right-click: change status",
    ["Aucun métier lu : ouvre ta fenêtre de métier une fois."] = "No profession read yet: open your profession window once.",
    ["Ajoute une note pour les acheteurs."] = "Add a note for buyers.",
    ["%d min"] = "%d min",
    ["%d h"] = "%d h",
    ["%d j"] = "%d d",
    ["il y a %s"] = "%s ago",
    ["Vu il y a %s"] = "Seen %s ago",
    ["Niveau %d"] = "Level %d",
    ["Niveau %d %s"] = "Level %d %s",
    ["+1 reroll"] = "+1 alt",
    ["+%d rerolls"] = "+%d alts",
    ["%s (reroll)"] = "%s (alt)",
    ["Ajouter aux favoris"] = "Add to favourites",
    ["Retirer des favoris"] = "Remove from favourites",
    ["Clic : ajouter aux favoris"] = "Click: add to favourites",
    ["Clic : retirer des favoris"] = "Click: remove from favourites",
    ["50 favoris au plus : retire-en un d'abord."] = "50 favourites at most: remove one first.",
    ["Clic : voir la fiche de %s"] = "Click: open %s's profile",
    ["Surveiller cette recette"] = "Watch this recipe",
    ["Tu seras prévenu quand un membre de la guilde saura la faire."] = "You will be told when a guild member can make it.",
    ["30 recettes surveillées au plus : retire-en une d'abord."] = "30 watched recipes at most: remove one first.",
    ["Clic : surveiller"] = "Click: watch",
    ["Clic : ne plus surveiller"] = "Click: stop watching",
    ["Ne plus surveiller"] = "Stop watching",
    -- tiles
    ["Artisans en ligne"] = "Crafters online",
    ["Personne en ligne pour l'instant"] = "Nobody online right now",
    ["1 artisan connu dans la guilde"] = "1 crafter known in the guild",
    ["%d artisans connus dans la guilde"] = "%d crafters known in the guild",
    ["1 disponible sur %d en ligne"] = "1 available of %d online",
    ["%d disponibles sur %d en ligne"] = "%d available of %d online",
    ["1 dans ta zone"] = "1 in your zone",
    ["%d dans ta zone"] = "%d in your zone",
    ["Disponibles : %s"] = "Available: %s",
    ["Clic : voir les artisans en ligne"] = "Click: see crafters online",
    ["Favoris"] = "Favourites",
    ["Aucun favori"] = "No favourites",
    ["Mets une étoile sur un artisan pour le garder ici."] = "Star a crafter to keep them here.",
    ["1 favori"] = "1 favourite",
    ["%d favoris"] = "%d favourites",
    ["Aucun favori en ligne"] = "No favourites online",
    ["%s en ligne"] = "%s online",
    ["%s et %s en ligne"] = "%s and %s online",
    ["%s, %s et 1 autre en ligne"] = "%s, %s and 1 other online",
    ["%s, %s et %d autres en ligne"] = "%s, %s and %d others online",
    ["Clic : voir mes favoris"] = "Click: see my favourites",
    ["Mes commandes récentes"] = "My recent orders",
    ["Aucune commande récente"] = "No recent orders",
    ["Tes commandes des deux dernières semaines apparaîtront ici."] = "Your orders from the last two weeks will show up here.",
    ["Livrée par %s"] = "Delivered by %s",
    ["Prise par %s"] = "Taken by %s",
    ["Fabriquée par %s"] = "Crafted by %s",
    ["Refusée par %s"] = "Declined by %s",
    ["Envoyée à %s"] = "Sent to %s",
    ["Ouverte à toute la guilde"] = "Open to the whole guild",
    ["Clic : voir mes commandes"] = "Click: see my orders",
    ["Clic : voir les commandes pour moi"] = "Click: see the orders for me",
    ["Recettes surveillées"] = "Watched recipes",
    ["Aucune recette surveillée"] = "No watched recipes",
    ["Le drapeau sur un objet te prévient quand un membre l'apprend."] = "The flag on an item tells you when a member learns it.",
    ["%s sait faire %s"] = "%s can make %s",
    ["%s est en ligne maintenant."] = "%s is online now.",
    ["1 recette surveillée"] = "1 watched recipe",
    ["%d recettes surveillées"] = "%d watched recipes",
    ["Personne en ligne ne sait les faire."] = "Nobody online can make them.",
    ["Personne ne sait encore les faire."] = "Nobody can make them yet.",
    ["Clic : voir mes recettes surveillées"] = "Click: see my watched recipes",
    ["Meilleurs artisans de la semaine"] = "Top crafters this week",
    ["Tout voir"] = "See all",
    ["livrée"] = "delivered",
    ["livrées"] = "delivered",
    ["%d commandes livrées ces 7 jours, %d en tout."] = "%d orders delivered in the last 7 days, %d in all.",
    ["Annoncé par %s ; tu en as vu %d."] = "As reported by %s; you saw %d.",
    ["Clic : voir sa fiche"] = "Click: open their profile",
    ["Personne n'a encore livré de commande cette semaine."] = "Nobody has delivered an order this week yet.",
    ["Les métiers des membres qui utilisent WL Helper apparaîtront ici."] = "The professions of members who use WL Helper will show up here.",
    -- crafters online, a crafter's profile
    ["Disponibles"] = "Available",
    ["Ma zone seulement"] = "My zone only",
    ["Seulement les artisans dans ta zone"] = "Only crafters in your zone",
    ["Aucun artisan en ligne"] = "No crafters online",
    ["Ta demande reste ouverte : les artisans la verront en se connectant."] = "Your request stays open: crafters will see it when they log in.",
    ["Aucun artisan ne correspond à ces filtres."] = "No crafter matches these filters.",
    ["Voir tous les artisans en ligne"] = "See all crafters online",
    ["%d livrées cette semaine · %d en tout"] = "%d delivered this week · %d in all",
    ["Métiers"] = "Professions",
    -- my profile
    ["Ce que la guilde voit quand elle cherche un artisan."] = "What the guild sees when looking for a crafter.",
    ["Occupé tout seul : tu es absent (AFK)."] = "Busy automatically: you are AFK.",
    ["Occupé tout seul : tu es en file d'attente."] = "Busy automatically: you are queued.",
    ["En donjon : tes commandes attendent sans bruit."] = "In a dungeon: your orders wait silently.",
    ["Note pour les acheteurs"] = "Note for buyers",
    ["Ex. Je fournis le charbon, 5 po la pièce."] = "E.g. I bring the coal, 5 g each.",
    ["Les liens ne passent pas dans la note : écris le nom en toutes lettres."] = "Links don't fit in the note: type the name instead.",
    ["Mes métiers"] = "My professions",
    ["1 recette partagée"] = "1 recipe shared",
    ["%d recettes partagées"] = "%d recipes shared",
    ["1 recette, non partagée"] = "1 recipe, not shared",
    ["%d recettes, non partagées"] = "%d recipes, not shared",
    ["Ce que la guilde voit"] = "What the guild sees",
    ["La guilde voit ce que tu sais fabriquer."] = "The guild sees what you can craft.",
    ["Cacher mes rerolls"] = "Hide my alts",
    ["Tes autres personnages n'apparaissent pas sous ton nom."] = "Your other characters are not listed under your name.",
    ["Mes rerolls : %s"] = "My alts: %s",
    ["Aucun reroll connu : chacun s'ajoute en se connectant dans la guilde."] = "No alts known yet: each one adds itself when it logs in to the guild.",
    ["Clic : changer"] = "Click: change",
    ["Montrer ma zone"] = "Show my zone",
    ["Ta zone s'affiche sur ta fiche d'artisan. La liste de guilde du jeu la montre quand même."] = "Your zone shows on your crafter card. The game's guild list shows it anyway.",
    ["Mode calme en donjon"] = "Quiet in dungeons",
    ["En donjon, raid ou champ de bataille, les commandes attendent sans bruit ; l'acheteur sait où tu es."] =
        "In a dungeon, raid or battleground, orders wait silently; the buyer knows where you are.",
    ["Occupé tout seul"] = "Busy automatically",
    ["Quand tu es absent (AFK) ou en file d'attente. Ton état revient ensuite."] = "When you are AFK or queued. Your status comes back afterwards.",
    ["Personnage principal"] = "Main character",
    ["Tes rerolls sont regroupés sous ce nom."] = "Your alts are grouped under this name.",
    ["Alertes"] = "Alerts",
    ["Prévenir quand un favori se connecte"] = "Tell me when a favourite logs in",
    ["Une alerte au plus toutes les 30 min par favori."] = "One alert at most every 30 min per favourite.",
    ["Prévenir quand une recette surveillée est apprise"] = "Tell me when a watched recipe is learned",
    ["Une fois par membre et par recette."] = "Once per member and recipe.",
    ["Personne ne sait la faire"] = "Nobody can make it",
    [" · en ligne"] = " · online",
    ["Clic : commander"] = "Click: order",
    ["Clic : faire une demande à la guilde"] = "Click: make a request to the guild",
    -- search
    ["Joueurs"] = "Players",
    ["Objets"] = "Items",
    ["Objets faits avec %s"] = "Items made with %s",
    ["%s · %s en ligne"] = "%s · %s online",
    ["%s · personne en ligne"] = "%s · nobody online",
    ["Clic : voir qui le fabrique"] = "Click: see who makes it",
    ["Maj-clic : le lier dans la discussion"] = "Shift-click: link it in chat",
    ["Utilisé dans 1 recette"] = "Used in 1 recipe",
    ["Utilisé dans %d recettes"] = "Used in %d recipes",
    ["Clic : voir les objets faits avec"] = "Click: see the items made with it",
    ["Voir les %d autres"] = "See %d more",
    ["Clic : tout montrer"] = "Click: show them all",
    ["Rien pour %s"] = "Nothing for %s",
    ["La recherche couvre les joueurs, les objets et les composants de la guilde."] = "Search covers the guild's players, items and materials.",
    ["Demander %s à la guilde"] = "Ask the guild for %s",
    -- buyer side: a crafter in a dungeon
    ["%s est en donjon : ta commande attendra sa sortie."] = "%s is in a dungeon: your order will wait until they are out.",
})

local function RenderFind()
    local f = ui.find
    local p = pages.find
    local q = (f.box:GetText() or ""):lower()
    win.subtitle:SetText(CrafterCount())
    f.listHead:Hide(); f.empty:Hide()
    H.Reset(f)   -- the home's own widgets and the rows' icon actions, shown again by what uses them
    -- two columns as soon as someone shares a profession: the professions stay on the left
    local g = GuildCrafts()
    local keys, anyone = ProfKeys(g)
    f.split = anyone
    local function Left() if f.split then RenderProfList(f, g, keys) end end
    -- one crafter picked: what they make (when their recipe list arrived)
    if f.view and #q < 2 then
        local v = f.view
        f.back:SetText(f.prof and ProfLabel(f.prof) or (f.page == "crafter" and f.cpName) or L("Accueil"))
        f.back:Show()
        local l = SetMode(f, "list")
        Left()
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
            if not v.me then H.SetFlag(row, id) end
            local rh = row:Fit(findW)
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
        findW = f.split and RW or CW          -- the strip wraps at the right side's width
        CrafterStrip(f, g[f.prof], f.prof)   -- sets the header's height before the list is placed
        local l = SetMode(f, "cat")
        Left()
        Fit(p, l, RenderCatalog(f, g))
        return
    end
    -- an item link (shift-click an item) or "item:12345": order it from the guild, recipe known or not
    local linked = tonumber((f.box:GetText() or ""):match("item:(%d+)"))
    if linked then
        local l = SetMode(f, "list")
        Left()
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
        local y = row:Fit(findW)
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
            -- the profession by its name only: an icon before "Forge 300" repeated it (icon audit, Orders)
            cr.detail:SetText(string.format(L("%s %d"), ProfLabel(key, c.prof), c.rank or 0)
                .. " · " .. Where(c.online) .. " · " .. (c.exact and L("recette connue") or L("métier compatible"))); cr.detail:Show()
            local tip = { c.name, cr.detail:GetText() }
            local sl = StarLine(c.name); if sl then tip[#tip + 1] = sl end
            tip[#tip + 1] = string.format(L("Clic : commander à %s"), c.name)
            cr.tip, cr.tipFill = tip, nil
            cr.btn:SetText(L("Commander")); cr.btn:Show(); cr.askProf = nil
            cr.btnTip = { L("Commander"), string.format(L("Clic : commander à %s"), c.name) }
            local rh = cr:Fit(findW)
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
    -- nothing typed: a page of the home (online crafters, a crafter, my profile), or the home itself
    -- (the professions on the left, the home on the right); nobody shares anything yet: one
    -- column and its empty state
    if #q < 2 then
        if f.page then
            local l = SetMode(f, "list")
            Left()
            Fit(p, l, H.RenderPage(f))
            return
        end
        local l = SetMode(f, "grid")
        if f.split then
            Left()
            f.grid.content:SetHeight(math.max(1, pages.find.sideH or 1))
            f.gridEmpty:Hide()
            Fit(p, l, H.Home(f))
        else
            Fit(p, l, RenderGrid(f, g))
        end
        return
    end
    -- two letters or more: players, items and materials of the guild
    local l = SetMode(f, "list")
    Left()
    Fit(p, l, H.Search(f, f.box:GetText() or ""))
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
    n.hoursLabel = S.Text(c, F.meta, C.muted); n.hoursLabel:SetText(L("Ouverte pendant")); S.ClampLabel(n.hoursLabel, nil, c)
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
        local sub = string.format(knows and L("Recette connue de %s") or L("%s a le métier, recette pas encore partagée"), draft.crafter)
        -- in a dungeon (quiet mode): the order waits until they are out
        local dun = O.StatusOf and O.StatusOf(draft.crafter) == "d"
        if dun then sub = sub .. "\n" .. string.format(L("%s est en donjon : ta commande attendra sa sortie."), draft.crafter) end
        n.sub:SetText(sub)
        y = y + 3 + S.FitText(n.sub, dun and 4 or 2, nameW, c)
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
    local dw = root.TextWidth(dk.label, nil, function(w2) dk:SetWidth(math.max(64, w2 + 24)) end)
    dk:SetWidth(math.max(64, (dw > 0 and dw or 80) + 24))
    dk.tip = { L("Je ne sais pas"), L("Tous les artisans de la guilde seront prévenus"), L("Clic : prévenir tous les artisans") }
    dk:SetScript("OnClick", function() askState.prof, askState.picked = "", true; WP.RefreshOrders() end)
    a.dunno = dk
    -- quantity, fee in gold, how long it stays open
    a.qty = NumberBox(c, 64, L("Quantité")); a.qty:SetText("1")
    a.fee = NumberBox(c, 96, L("Commission (po)"), "0")
    a.hoursLabel = S.Text(c, F.meta, C.muted); a.hoursLabel:SetText(L("Ouverte pendant")); S.ClampLabel(a.hoursLabel, nil, c)
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
    function c:Fit(width)
        self:SetWidth(width)
        local pad = 12
        local x = pad + 32 + 8
        -- right cluster: commission and the status pill
        self.pill:ClearAllPoints(); self.pill:SetPoint("TOPRIGHT", -pad, -pad)
        local pw = self.pill:IsShown() and (num(self.pill:GetWidth()) or 60) or 0
        local feeW = 0
        if self.fee:IsShown() then
            local sw = root.TextWidth(self.fee)
            feeW = math.min(120, (sw > 0 and sw or 60) + 1)
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
    -- labelled buttons keep an icon only for danger (the trash on "Cancel the order"): a check, a
    -- coin or a star beside a verb only repeated it (design system 3.4, icon audit G3)
    b:SetIcon(icon == "trash" and icon or nil)
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
        -- "Pour Mylla · par Mylla" said the crafter twice: the stars go on the one name
        if o.by and o.by == o.to then who = who .. Stars(o.by)
        elseif o.by then who = who .. " · " .. string.format(L("par %s"), o.by) .. Stars(o.by) end
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
        nxt = string.format(L("%s te l'envoie par la poste ou en échange."), o.by or "?")   -- the pill already says Fabriquée
    elseif side == "recv" and stt == "accepted" then
        -- with no item ID the addon cannot see it in the bags: the button says it
        nxt, mineTurn = (item > 0) and L("Fabrique l'objet : l'addon le voit tout seul dans tes sacs.") or L("Fabrique-la, puis marque-la comme fabriquée."), true
    elseif side == "recv" and stt == "crafted" then
        nxt, mineTurn = string.format(L("Livre-la à %s par la poste ou en échange."), o.from or "?"), true
    elseif side == "mine" and stt == "delivered" and not o.thanked and o.by then
        nxt = string.format(L("Tu l'as reçue. Remercie %s pour lui donner une étoile."), o.by)
    elseif stt == "delivered" then
        nxt = L("Commande terminée.")
    elseif side == "mine" and stt == "declined" then
        nxt = string.format(L("Refusée par %s : Commander à nouveau la propose à toute la guilde."), o.by or "?")
    end
    -- my crafter is in a dungeon (quiet mode): the order waits, and where it stands in their line
    local qx = side == "mine" and not mineTurn and (stt == "open" or stt == "accepted") and (o.by or o.to) or nil
    if qx and O.StatusOf and O.StatusOf(qx) == "d" then
        nxt = string.format(L("%s est en donjon : ta commande attend, tu es %s dans sa file."), qx, O.Ordinal(O.PlaceInLine(o) or 1))
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
    -- the note says whose it is (always the customer's)
    if o.note and o.note ~= "" then
        lines[#lines + 1] = (o.from == me or side == "mine") and string.format(L("Ton mot : « %s »"), o.note)
            or string.format(L("Mot de %s : « %s »"), o.from or "?", o.note)
    end
    -- the steps so far, and the last messages between customer and crafter
    if o.log and #o.log > 1 then
        local t = {}
        for i, e in ipairs(o.log) do
            local w = L(STATUS[e.s] or e.s)
            if i > 1 then w = w:lower() end
            t[#t + 1] = w .. " " .. Clock(e.t)
        end
        -- "Historique", not "Suivi": "le suivi" is the guide tracker in the glossary
        lines[#lines + 1] = string.format(L("Historique : %s"), table.concat(t, ", "))
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
        return "hammer", L("Tu n'as rien commandé"), L("Tes commandes et leur historique apparaîtront ici."),
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
