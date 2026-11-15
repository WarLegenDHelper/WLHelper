-- Writs/OrdersUI.lua: the Orders window (crafters of the guild, my orders, orders received) and the
-- panel beside the mailbox that fills the mail for an order. Engine: Orders.lua.
local ADDON, root = ...
root.Writs = root.Writs or {}
local ns = root.Writs
local WP = ns.WP
local L = ns.L
local S = ns.S
local C = S.C
local O = WP.Orders

ns.AddEnglish({
    ["Artisans"] = "Crafters",
    ["Mes commandes"] = "My orders",
    ["Reçues"] = "Received",
    ["Chercher un objet, ou Maj-clic sur un objet pour le commander"] = "Search an item, or shift-click an item to order it",
    ["%d artisans connus · %d en ligne"] = "%d crafters known · %d online",
    ["Chuchoter"] = "Whisper",
    ["À envoyer à %s :"] = "To send to %s:",
    ["envoyés"] = "sent",
    ["Acheter le manquant (%d)"] = "Buy what's missing (%d)",
    [" dont %d en banque"] = " %d of them in the bank",
    ["%s d'avance"] = "%s upfront",
    ["Tu fournis :"] = "You provide:",
    ["En attente d'un artisan."] = "Waiting for a crafter.",
    ["À toi : il te manque des composants à envoyer à %s."] = "Your turn: you are missing reagents to send to %s.",
    ["À toi : envoie les composants à %s (poste ou échange)."] = "Your turn: send the reagents to %s (mail or trade).",
    ["À toi : sors les composants de la banque, puis va à une boîte aux lettres ou échange avec %s."] =
        "Your turn: take the reagents out of the bank, then go to a mailbox or trade with %s.",
    ["%s fabrique ta commande."] = "%s is crafting your order.",
    ["Fabriquée : elle arrive par la poste ou en échange avec %s."] = "Crafted: it comes by mail or by trade with %s.",
    ["À toi : accepte si tu peux la fabriquer."] = "Your turn: accept if you can craft it.",
    ["À toi : fabrique l'objet, l'addon le voit tout seul."] = "Your turn: craft the item, the addon sees it on its own.",
    ["À toi : livre à %s (boîte aux lettres ou échange)."] = "Your turn: deliver to %s (mailbox or trade).",
    ["Terminée."] = "Done.",
    ["J'ai reçu"] = "I got it",
    ["Pourboire pour %s : %s au total, payé à la réception (contre-remboursement) ou en échange."] =
        "Tip for %s: %s in total, paid on receipt (cash on delivery) or by trade.",
    ["Pourboire pour %s : %s au total. Envoie-le par la poste ou en échange : l'addon ne déplace pas d'or tout seul."] =
        "Tip for %s: %s in total. Send it by mail or trade: the addon never moves gold by itself.",
    ["Ouvre une fois ta fenêtre de métier pour partager tes recettes."] = "Open your profession window once to share your recipes.",
    ["Ouvre l'hôtel des ventes, puis reclique."] = "Open the auction house, then click again.",
    ["Préparer le courrier"] = "Prepare the mail",
    ["Va à une boîte aux lettres, ou échange-les directement avec %s."] = "Go to a mailbox, or trade them directly with %s.",
    ["%d artisans possibles · Commander : toute la guilde la voit"] = "%d possible crafters · Order: the whole guild sees it",
    ["personne n'a encore déclaré ce métier : la guilde verra quand même la commande"] = "nobody declared this profession yet: the guild will still see the order",
    ["recette connue"] = "recipe known",
    ["métier compatible"] = "matching profession",
    ["À lui"] = "To them",
    ["Ouvertes"] = "Open",
    ["Ce que je sais fabriquer"] = "What I can make",
    ["Aucune commande ouverte pour ce que tu sais fabriquer. Décoche le filtre pour tout voir."] = "No open order for what you can make. Untick the filter to see them all.",
    ["Aucune commande ouverte dans la guilde."] = "No open order in the guild.",
    ["Masquer"] = "Hide",
    ["Message"] = "Message",
    ["Message · %s"] = "Message · %s",
    ["Ton message (120 caractères)"] = "Your message (120 characters)",
    ["Envoyer"] = "Send",
    ["Merci"] = "Thanks",
    ["Recommander"] = "Order again",
    ["%d artisans connus pour cet objet"] = "%d crafters known for this item",
    ["aucune recette partagée : la guilde verra la commande"] = "no recipe shared: the guild will see the order",
    ["Recette inconnue : écris dans la note qui fournit quoi, l'artisan verra la commande."] = "Unknown recipe: write in the note who provides what, the crafter will see the order.",
    ["composants %s%s · commission conseillée %s"] = "reagents %s%s · suggested fee %s",
    ["Recettes"] = "Recipes",
    ["Recettes de %s : %s %d"] = "%s's recipes: %s %d",
    ["Tous les artisans"] = "All crafters",
    ["%d artisans"] = "%d crafters",
    ["(toi)"] = "(you)",
    ["%d recettes"] = "%d recipes",
    ["recettes pas encore partagées"] = "recipes not shared yet",
    ["Ses recettes ne sont pas encore arrivées : elles viennent quand il ouvre sa fenêtre de métier, ou de Mastercraft s'il l'a."] =
        "Their recipes have not arrived yet: they come when they open their profession window, or from Mastercraft if they have it.",
    ["Aucun artisan connu pour l'instant : les membres qui ont WL Helper partagent leurs métiers en se connectant. Tape un objet pour chercher qui le fabrique."] =
        "No crafter known yet: members who have WL Helper share their professions when they log in. Type an item to find who makes it.",
    ["tes métiers : %s"] = "yours: %s",
    ["tes métiers : aucun"] = "yours: none yet",
    ["en ligne"] = "online",
    ["vu il y a %d j"] = "seen %d d ago",
    ["hors ligne"] = "offline",
    ["Commander"] = "Order",
    ["Aucune recette connue pour l'instant. Chaque membre qui a WL Helper, toi compris, doit ouvrir une fois sa fenêtre de métier pour partager ses recettes."] =
        "No recipe known yet. Each member who has WL Helper, you included, has to open their profession window once to share their recipes.",
    ["Tape au moins 2 lettres."] = "Type at least 2 letters.",
    ["Nouvelle commande"] = "New order",
    ["Toute la guilde"] = "Whole guild",
    ["Seulement %s"] = "Only %s",
    ["je fournis"] = "I provide",
    ["l'artisan fournit"] = "crafter provides",
    ["Composants"] = "Reagents",
    ["Clic : qui le fournit"] = "Click: who provides it",
    ["Commission"] = "Commission",
    ["Pourboire"] = "Tip",
    ["Valable"] = "Valid for",
    ["Payer d'avance"] = "Pay upfront",
    ["Un mot pour l'artisan"] = "A word for the crafter",
    ["Publier la commande"] = "Publish the order",
    ["Rien ne part par la poste avant qu'un artisan ait accepté."] = "Nothing is mailed before a crafter accepts.",
    ["po"] = "g",
    ["Aucune commande."] = "No order.",
    ["ouverte"] = "open", ["acceptée"] = "accepted", ["fabriquée"] = "crafted", ["livrée"] = "delivered",
    ["refusée"] = "declined", ["annulée"] = "cancelled", ["expirée"] = "expired",
    ["pour %s"] = "for %s", ["pour la guilde"] = "for the guild", ["par %s"] = "by %s",
    ["expire dans %d h"] = "expires in %d h",
    ["Accepter"] = "Accept", ["Refuser"] = "Decline", ["Annuler"] = "Cancel",
    ["Fabriquée"] = "Crafted", ["Livrée"] = "Delivered", ["Pourboire +1 po"] = "Tip +1 g",
    ["Reçu : %s"] = "Received: %s",
    ["argent %s / %s"] = "money %s / %s",
    ["tout est arrivé"] = "everything arrived",
    ["Commandes à poster"] = "Orders to mail",
    ["Envoyer à %s"] = "Send to %s",
    ["Livrer à %s"] = "Deliver to %s",
    ["Courrier prêt : clique sur Envoyer."] = "Mail ready: click Send.",
    ["Manque : %s"] = "Missing: %s",
    ["Raison du refus"] = "Reason",
    ["%s fournit"] = "%s provides",
    ["Tes recettes sont partagées avec la guilde"] = "Your recipes are shared with the guild",
    ["3 j"] = "3 d",
    -- the Request tab
    ["Demander"] = "Request",
    ["Ce que tu veux"] = "What you want",
    ["Nom de l'objet, ou Maj-clic sur un objet"] = "Item name, or shift-click an item",
    ["Objet reconnu : %s"] = "Item found: %s",
    ["Pas un objet connu du jeu : la demande part avec ce texte."] = "Not an item the game knows: the request goes with this text.",
    ["Tape un nom, ou Maj-clic sur un objet (sacs, chat, recette)."] = "Type a name, or shift-click an item (bags, chat, recipe).",
    ["Métier"] = "Profession",
    ["Je ne sais pas"] = "I don't know",
    ["Je ne sais pas : tous les artisans sont prévenus"] = "I don't know: every crafter is told",
    ["Quantité"] = "Quantity",
    ["%d artisans prévenus · %d en ligne"] = "%d crafters told · %d online",
    ["Publier"] = "Publish",
    ["Écris ce que tu veux, ou Maj-clic sur un objet."] = "Write what you want, or shift-click an item.",
    ["Demande publiée : %s ×%d (%s). Les artisans de la guilde sont prévenus."] = "Request published: %s ×%d (%s). The guild's crafters are told.",
    ["Demander à toute la guilde : ouvre l'onglet Demander, déjà rempli."] = "Ask the whole guild: opens the Request tab, already filled in.",
    ["Demande"] = "Request",
    ["À toi : fabrique l'objet, puis clique sur Fabriquée."] = "Your turn: craft the item, then click Crafted.",
    -- the profession grid and a profession's catalogue
    ["Tous les métiers"] = "All professions",
    ["%d artisans · %d objets"] = "%d crafters · %d items",
    ["%d en ligne"] = "%d online",
    ["personne en ligne"] = "nobody online",
    ["En ligne : %s"] = "Online: %s",
    ["Clic : le catalogue de ce métier"] = "Click: this profession's catalogue",
    ["Aucun artisan connu"] = "No crafter known yet",
    ["Les membres qui ont WL Helper partagent leurs métiers en se connectant : reviens dans un moment, ou publie une demande dans l'onglet Demander."] =
        "Members who have WL Helper share their professions when they log in: come back in a moment, or post a request in the Request tab.",
    ["Seulement les objets qu'un artisan en ligne peut fabriquer"] = "Only items an online crafter can make",
    ["Chercher dans ce métier"] = "Search this profession",
    ["Aucune recette partagée"] = "No recipe shared",
    ["Les artisans de ce métier doivent ouvrir une fois leur fenêtre de métier pour que leurs recettes arrivent ici."] =
        "This profession's crafters have to open their profession window once for their recipes to show up here.",
    ["Aucun objet trouvé"] = "No item found",
    ["Aucun artisan en ligne ne fabrique ce que tu cherches : décoche « en ligne » pour tout voir."] =
        "No online crafter makes what you are looking for: switch off online to see everything.",
    ["Rien dans ce métier ne correspond : essaie un autre mot, ou publie une demande dans l'onglet Demander."] =
        "Nothing in this profession matches: try another word, or post a request in the Request tab.",
    ["niv. %d"] = "lvl %d",
    ["composants inconnus"] = "reagents unknown",
    ["Peuvent le fabriquer : %s"] = "Can make it: %s",
    ["Clic : commander à %s"] = "Click: order from %s",
    ["Clic : commander à la guilde"] = "Click: order from the guild",
    ["Artisans de ce métier"] = "Crafters of this profession",
    ["Recettes non partagées : %s — ils doivent ouvrir leur fenêtre de métier une fois."] =
        "Recipes not shared: %s — they have to open their profession window once.",
    ["toi"] = "you",
    ["Recettes pas encore arrivées"] = "Recipes not here yet",
    ["Ses recettes arrivent quand il ouvre sa fenêtre de métier, ou de Mastercraft s'il l'a."] =
        "Their recipes arrive when they open their profession window, or from Mastercraft if they have it.",
    ["Chaque membre qui a WL Helper, toi compris, partage ses recettes en ouvrant une fois sa fenêtre de métier."] =
        "Each member who has WL Helper, you included, shares their recipes by opening their profession window once.",
    ["Personne n'a partagé cette recette : l'onglet Demander prévient quand même toute la guilde."] =
        "Nobody shared this recipe: the Request tab still tells the whole guild.",
})

-- 520 wide: five tabs (Artisans, Demander, Ouvertes, Mes commandes, Reçues) with their count badges
-- need about 490 px at the tab font's size
local W, H, PAD = 520, 600, 14
local win, tabs, pages, current = nil, nil, {}, "find"
local ui = { find = {}, mine = {}, recv = {}, new = {}, board = {}, ask = {} }
WP.OrdersUI = ui   -- the pages' widgets, for the offline tests

-- the addon's HD interface icons: white 128 px TGAs, tinted
local ICONS = "Interface\\AddOns\\" .. ADDON .. "\\Media\\Icons\\"
local function Icon(parent, name, size, color, layer)
    local t = parent:CreateTexture(nil, layer or "ARTWORK")
    t:SetSize(size, size); t:SetTexture(ICONS .. name)
    local c = color or C.dim
    t:SetVertexColor(c[1], c[2], c[3], c[4] or 1)
    return t
end
-- the same icon inside a text, tinted
local function IconMarkup(name, size, c)
    c = c or C.dim
    local function b(v) return math.floor(math.max(0, math.min(1, v)) * 255 + 0.5) end
    return string.format("|T%s%s:%d:%d:0:0:128:128:0:128:0:128:%d:%d:%d|t", ICONS, name, size, size, b(c[1]), b(c[2]), b(c[3]))
end
-- the game font cannot draw a star: the HD star icon instead
local STAR = IconMarkup("star", 12, C.warn)
local function Money(c) return S.Money(c or 0) end
local function Name(id) return O.Name(id) end
local STATUS = { open = "ouverte", accepted = "acceptée", crafted = "fabriquée", delivered = "livrée",
    declined = "refusée", cancelled = "annulée", expired = "expirée" }
local STATUS_COL = { open = C.warn, accepted = C.info, crafted = C.ready, delivered = C.dim, declined = C.danger, cancelled = C.dim, expired = C.dim }

-- a scroll list of rows built with make(); Get(i) / HideFrom(i)
local function List(parent, top, bottom, make)
    local sf = CreateFrame("ScrollFrame", nil, parent)
    sf:SetPoint("TOPLEFT", PAD, top); sf:SetPoint("BOTTOMRIGHT", -PAD, bottom)
    local content = CreateFrame("Frame", nil, sf); content:SetSize(W - 2 * PAD, 10); sf:SetScrollChild(content)
    sf:EnableMouseWheel(true)
    sf:SetScript("OnMouseWheel", function(self, d)
        local max = math.max(0, content:GetHeight() - self:GetHeight())
        self:SetVerticalScroll(math.max(0, math.min(max, self:GetVerticalScroll() - d * 40)))
    end)
    local l = { sf = sf, content = content, items = {} }
    function l.Get(i) local f = l.items[i]; if not f then f = make(content); l.items[i] = f end; f:Show(); return f end
    function l.HideFrom(i) for j = i, #l.items do l.items[j]:Hide() end end
    return l
end

local function Box(parent, w, h, numeric, hint)
    local eb = CreateFrame("EditBox", nil, parent)
    eb:SetSize(w, h); eb:SetAutoFocus(false)
    if numeric then eb:SetNumeric(true); eb:SetMaxLetters(6) end
    local probe = S.Text(parent, 14, C.text)
    local font, size, flags = probe:GetFont(); probe:Hide()
    if font then eb:SetFont(font, size or 14, flags or "") else eb:SetFontObject(ChatFontNormal) end
    eb:SetTextColor(C.text[1], C.text[2], C.text[3]); eb:SetTextInsets(8, 8, 0, 0)
    S.Solid(eb, "BACKGROUND", C.card):SetAllPoints()
    S.Border(eb, C.border)
    if hint then
        eb.hint = S.Text(eb, 13, C.muted); eb.hint:SetPoint("LEFT", 8, 0); eb.hint:SetText(hint)
        eb:HookScript("OnTextChanged", function(self) self.hint:SetShown((self:GetText() or "") == "") end)
    end
    eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    eb:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    return eb
end

-- a magnifier at the start of a search box; the text and the hint move right of it
local function SearchIcon(eb)
    eb.glass = Icon(eb, "search", 14, C.muted, "OVERLAY"); eb.glass:SetPoint("LEFT", 9, 0)
    eb:SetTextInsets(29, 8, 0, 0)
    if eb.hint then
        eb.hint:ClearAllPoints(); eb.hint:SetPoint("LEFT", 29, 0)
        eb.hint:SetWidth(math.max(40, (eb:GetWidth() or 100) - 37))
    end
end

-- an empty state: a short title and one helpful sentence, wrapped to the width
local function EmptyState(parent, width)
    local e = CreateFrame("Frame", nil, parent)
    e:SetSize(width, 60)
    e.title = S.Text(e, 14, C.text, true); e.title:SetPoint("TOPLEFT", 0, 0); e.title:SetWidth(width)
    e.title:SetJustifyH("LEFT"); e.title:SetWordWrap(true)
    e.text = S.Text(e, 13, C.dim); e.text:SetPoint("TOPLEFT", e.title, "BOTTOMLEFT", 0, -6); e.text:SetWidth(width)
    e.text:SetJustifyH("LEFT"); e.text:SetJustifyV("TOP"); e.text:SetWordWrap(true)
    function e:Set(title, text)
        self.title:SetText(title); self.text:SetText(text)
        self:SetHeight((self.title:GetStringHeight() or 16) + 6 + (self.text:GetStringHeight() or 14))
        self:Show()
    end
    -- shown with these texts, or hidden
    function e:When(on, title, text) if on then self:Set(title, text) else self:Hide() end end
    e:Hide()
    return e
end

-- a back button: an HD chevron, then its label, as wide as the label needs
local function BackButton(parent, label, onClick)
    local b = S.Button(parent, label, 120, 30, "secondary", onClick)
    b.chev = Icon(b, "chevron_left", 14, C.dim, "OVERLAY"); b.chev:SetPoint("LEFT", 10, 0)
    function b:SetLabel(t)
        self.label:SetText(t)
        self.label:ClearAllPoints(); self.label:SetPoint("LEFT", 30, 0)
        self:SetWidth(math.max(90, math.ceil(self.label:GetStringWidth() or 60) + 44))
    end
    b:SetLabel(label)
    return b
end

-- ---------------------------------------------------------------- page 1: crafters (search)
local BuildBrowse   -- the profession grid and a profession's catalogue, defined with the professions below
local function BuildFind(p)
    local f = ui.find
    f.box = Box(p, W - 2 * PAD, 30, false, L("Chercher un objet, ou Maj-clic sur un objet pour le commander"))
    f.box:SetPoint("TOPLEFT", PAD, -12)
    SearchIcon(f.box)
    -- a real query typed here wins over a crafter's view or a catalogue: leave them for the item search
    f.box:HookScript("OnTextChanged", function(self)
        local t = ((self:GetText() or ""):gsub("^%s+", ""):gsub("%s+$", ""))
        if #t >= 2 or t:match("item:%d+") then f.view, f.prof = nil, nil end
        WP.RefreshOrders()
    end)
    -- widths, not right anchors: the back button takes the end of these lines in a crafter's view
    f.info = S.Text(p, 12, C.dim); f.info:SetPoint("TOPLEFT", PAD, -48); f.info:SetWidth(W - 2 * PAD)
    f.info:SetJustifyH("LEFT"); f.info:SetWordWrap(false)
    -- your own professions on their own line (up to two lines), so the counts are never cut
    f.mine = S.Text(p, 12, C.dim); f.mine:SetPoint("TOPLEFT", PAD, -64); f.mine:SetWidth(W - 2 * PAD)
    f.mine:SetJustifyH("LEFT"); f.mine:SetWordWrap(true); if f.mine.SetMaxLines then f.mine:SetMaxLines(2) end
    f.list = List(p, -96, 52, function(parent)
        local r = CreateFrame("Frame", nil, parent)
        r:SetSize(W - 2 * PAD, 40)
        r.bg = S.Solid(r, "BACKGROUND", C.card); r.bg:SetAllPoints(); S.Border(r, C.border)
        r.icon = r:CreateTexture(nil, "ARTWORK"); r.icon:SetSize(22, 22); r.icon:SetPoint("LEFT", 9, 0); r.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        r.cls = r:CreateTexture(nil, "ARTWORK"); r.cls:SetSize(20, 20); r.cls:SetPoint("LEFT", 10, 0); r.cls:Hide()
        r.name = S.Text(r, 14, C.text); r.name:SetPoint("TOPLEFT", 40, -5); r.name:SetPoint("RIGHT", -96, 0); r.name:SetJustifyH("LEFT"); r.name:SetWordWrap(false)
        r.sub = S.Text(r, 12, C.dim); r.sub:SetPoint("BOTTOMLEFT", 40, 6); r.sub:SetPoint("RIGHT", -96, 0); r.sub:SetJustifyH("LEFT"); r.sub:SetWordWrap(false)
        r.btn = S.Button(r, L("Commander"), 80, 26, "secondary", function()
            if r.item then WP.NewOrder(r.item, r.crafter)
            elseif r.open then ui.find.view = r.open; f.list.sf:SetVerticalScroll(0); WP.RefreshOrders()
            elseif r.whisper and ChatFrame_OpenChat then ChatFrame_OpenChat("/w " .. r.whisper .. " ") end
        end)
        r.btn:SetPoint("RIGHT", -7, 0)
        -- on a crafter's recipe: ask the whole guild for it, the Request form already filled in
        r.ask = S.Button(r, L("Demander"), 80, 26, "secondary", function()
            if r.item and WP.AskOrder then WP.AskOrder(r.item, r.askProf) end
        end, { L("Demander à toute la guilde : ouvre l'onglet Demander, déjà rempli.") })
        r.ask:SetPoint("RIGHT", r.btn, "LEFT", -6, 0); r.ask:Hide()
        -- the lines may be cut: the tooltip says everything
        r:EnableMouse(true)
        r:SetScript("OnEnter", function(self)
            if self.tipFill then self.tipFill() end
            if self.tip then S.Tip(self, self.tip) end
        end)
        r:SetScript("OnLeave", S.HideTip)
        return r
    end)
    f.empty = EmptyState(f.list.content, W - 2 * PAD - 4); f.empty:SetPoint("TOPLEFT", 2, -8)
    -- out of a crafter's recipes: back to the profession's catalogue, or to the grid
    f.back = BackButton(p, L("Tous les métiers"), function() f.view = nil; f.list.sf:SetVerticalScroll(0); WP.RefreshOrders() end)
    f.back:SetHeight(26); f.back:SetPoint("TOPRIGHT", -PAD, -46); f.back:Hide()
    BuildBrowse(p)
    -- sharing my recipes: on by default
    local foot = CreateFrame("Frame", nil, p); foot:SetPoint("BOTTOMLEFT"); foot:SetPoint("BOTTOMRIGHT"); foot:SetHeight(48)
    local fl = S.Solid(foot, "BORDER", C.divider); fl:SetPoint("TOPLEFT"); fl:SetPoint("TOPRIGHT"); fl:SetHeight(1)
    local t = S.Text(foot, 13, C.dim); t:SetPoint("LEFT", PAD, 0); t:SetText(L("Tes recettes sont partagées avec la guilde"))
    local sw = S.Switch(foot, function() return WLWritsDB.ordersShare ~= false end, function(v) WLWritsDB.ordersShare = v; if v then O.Announce() end end)
    sw:SetPoint("RIGHT", -PAD, 0)
end

local Reagents   -- defined with the order cards below
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
local PROF_ORDER = { "alchemy", "blacksmithing", "enchanting", "engineering", "leatherworking", "tailoring",
    "cooking", "firstaid", "herbalism", "mining", "skinning", "fishing" }
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

-- a member's row: the class icon (same texture as the guild tab's class filter) and the class colour
local function SetClass(row, name)
    local cls = name and O.ClassOf(name)
    -- the modern square class icon where the client has it, else the circle sheet
    if cls and S.ClassIcon(row.cls, cls) then row.cls:Show() else row.cls:Hide() end
    local cc = cls and RAID_CLASS_COLORS and RAID_CLASS_COLORS[cls]
    if cc then row.name:SetTextColor(cc.r, cc.g, cc.b) else row.name:SetTextColor(C.text[1], C.text[2], C.text[3]) end
end

-- a row with the "Demander" button beside "Commander" (a crafter's recipe), or not: the texts stop before
-- the buttons either way
local function TwoButtons(row, on, prof)
    row.ask:SetShown(on and true or false); row.askProf = prof
    local right = on and -182 or -96
    row.name:SetPoint("RIGHT", right, 0); row.sub:SetPoint("RIGHT", right, 0)
end

-- a profession's icon inside a text, its edges cropped like the icons
local function ProfMarkup(key, size)
    size = size or 14
    return "|T" .. ProfIcon(key) .. ":" .. size .. ":" .. size .. ":0:0:64:64:5:59:5:59|t"
end

-- ---------------------------------------------------------------- the profession grid and catalogues
-- The grid's professions, in the order players think of them; Mining only once it has recipes.
local GRID_PROFS = { "alchemy", "blacksmithing", "tailoring", "leatherworking", "engineering", "enchanting", "cooking", "firstaid", "mining" }
local GRID_COLS, GRID_GAP = 4, 8
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
            if c.n == 0 then e.unshared[#e.unshared + 1] = c.me and (c.name .. " " .. L("(toi)")) or c.name end
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
    if c.online and not c.me then n = S.Hex(C.ready) .. n .. "|r" end
    if c.stars > 0 then n = n .. " " .. STAR .. S.Hex(C.warn) .. c.stars .. "|r" end
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

BuildBrowse = function(p)
    local f = ui.find
    -- the grid: one tile per profession, sized at render from the window's width
    f.grid = List(p, -100, 52, function(parent)
        local t = CreateFrame("Button", nil, parent)
        t:SetSize(110, 130)
        S.Solid(t, "BACKGROUND", C.card):SetAllPoints()
        t.border = S.Border(t, C.border)
        S.Solid(t, "HIGHLIGHT", { 1, 1, 1 }, 0.04):SetAllPoints()
        t.icon = t:CreateTexture(nil, "ARTWORK"); t.icon:SetSize(40, 40); t.icon:SetPoint("TOP", 0, -12)
        t.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        t.name = S.Text(t, 13, C.text, true); t.name:SetPoint("TOP", t.icon, "BOTTOM", 0, -8)
        t.name:SetJustifyH("CENTER"); t.name:SetWordWrap(true)
        t.count = S.Text(t, 12, C.dim); t.count:SetPoint("TOP", t.name, "BOTTOM", 0, -4)
        t.count:SetJustifyH("CENTER"); t.count:SetWordWrap(true)
        t.online = S.Text(t, 12, C.ready); t.online:SetPoint("TOP", t.count, "BOTTOM", 0, -3)
        t.online:SetJustifyH("CENTER"); t.online:SetWordWrap(true)
        t:SetScript("OnClick", function(self)
            -- empty the box before f.prof is set: its hook then renders nothing, one render below
            if (f.cbox:GetText() or "") ~= "" then f.cbox:SetText("") end
            f.prof, f.view = self.key, nil
            f.cat.sf:SetVerticalScroll(0)
            WP.RefreshOrders()
        end)
        t:SetScript("OnEnter", function(self) self.border(C.brand); if self.tip then S.Tip(self, self.tip) end end)
        t:SetScript("OnLeave", function(self) self.border(C.border); S.HideTip() end)
        return t
    end)
    f.gridEmpty = EmptyState(f.grid.content, W - 2 * PAD - 4)

    -- a profession's catalogue: back, search, "online" on one line, then the profession's title
    local h = CreateFrame("Frame", nil, p)
    h:SetPoint("TOPLEFT"); h:SetPoint("TOPRIGHT"); h:SetHeight(80); h:Hide()
    f.chead = h
    f.cback = BackButton(h, L("Tous les métiers"), function()
        f.prof, f.view = nil, nil
        f.grid.sf:SetVerticalScroll(0)
        WP.RefreshOrders()
    end)
    f.cback:SetPoint("TOPLEFT", PAD, -12)
    f.conline = S.Switch(h, function() return f.onlineOnly end, function(v) f.onlineOnly = v and true or false; WP.RefreshOrders() end,
        L("Seulement les objets qu'un artisan en ligne peut fabriquer"))
    f.conline:SetPoint("TOPRIGHT", -PAD, -16)
    local ol = S.Text(h, 13, C.text); ol:SetPoint("RIGHT", f.conline, "LEFT", -8, 0); ol:SetText(L("en ligne"))
    local olW = math.ceil(ol:GetStringWidth() or 50)
    local boxW = W - 2 * PAD - (f.cback:GetWidth() or 120) - 8 - (38 + 8 + olW + 12)
    f.cbox = Box(h, math.max(120, boxW), 30, false, L("Chercher dans ce métier"))
    f.cbox:SetPoint("LEFT", f.cback, "RIGHT", 8, 0)
    SearchIcon(f.cbox)
    f.cbox:HookScript("OnTextChanged", function() if f.prof then WP.RefreshOrders() end end)
    f.cicon = h:CreateTexture(nil, "ARTWORK"); f.cicon:SetSize(22, 22); f.cicon:SetPoint("TOPLEFT", PAD, -52)
    f.cicon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    f.ctitle = S.Text(h, 15, C.text, true); f.ctitle:SetPoint("LEFT", f.cicon, "RIGHT", 8, 0); f.ctitle:SetJustifyH("LEFT")
    f.ccount = S.Text(h, 12, C.dim); f.ccount:SetPoint("LEFT", f.ctitle, "RIGHT", 10, 0); f.ccount:SetJustifyH("LEFT")

    -- the catalogue's rows: an item (who makes it, Request), a section title, or a crafter (Recipes)
    local textW = W - 2 * PAD - 52 - 104
    f.cat = List(p, -84, 52, function(parent)
        local r = CreateFrame("Button", nil, parent)
        r:SetSize(W - 2 * PAD, 56)
        r.bg = S.Solid(r, "BACKGROUND", C.card); r.bg:SetAllPoints(); r.border = S.Border(r, C.border)
        r.hl = S.Solid(r, "HIGHLIGHT", { 1, 1, 1 }, 0.04); r.hl:SetAllPoints()
        r.icon = r:CreateTexture(nil, "ARTWORK"); r.icon:SetSize(32, 32); r.icon:SetPoint("LEFT", 10, 0); r.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        r.cls = r:CreateTexture(nil, "ARTWORK"); r.cls:SetSize(22, 22); r.cls:SetPoint("LEFT", 15, 0); r.cls:Hide()
        r.name = S.Text(r, 14, C.text); r.name:SetPoint("TOPLEFT", 52, -6); r.name:SetWidth(textW); r.name:SetJustifyH("LEFT"); r.name:SetWordWrap(false)
        r.sub = S.Text(r, 12, C.dim); r.sub:SetPoint("TOPLEFT", 52, -24); r.sub:SetWidth(textW); r.sub:SetJustifyH("LEFT"); r.sub:SetWordWrap(false)
        r.who = S.Text(r, 12, C.dim); r.who:SetPoint("TOPLEFT", 52, -39); r.who:SetWidth(textW); r.who:SetJustifyH("LEFT"); r.who:SetWordWrap(false)
        local function Open(self)
            if self.kind == "item" then WP.NewOrder(self.item, self.crafter)
            elseif self.kind == "crafter" and self.open then f.view = self.open; f.list.sf:SetVerticalScroll(0); WP.RefreshOrders() end
        end
        r.btn = S.Button(r, L("Demander"), 92, 26, "secondary", function()
            if r.kind == "item" then
                if WP.AskOrder then WP.AskOrder(r.item, PROFS[r.prof] and PROFS[r.prof][2] or r.prof) end
            else Open(r) end
        end, function() return r.btnTip or { "" } end)
        r.btn:SetPoint("RIGHT", -8, 0)
        -- the row itself: an item opens the order form (to its best crafter), a crafter his recipes
        r:SetScript("OnClick", Open)
        -- an item's tooltip is built on hover only (decoding every row's reagents per render is costly)
        r:SetScript("OnEnter", function(self)
            local it = self.kind == "item" and self.it
            if it then
                local qc = it.id > 0 and S.QualityColor(it.id) or C.text
                local tip = { S.Hex(qc) .. (it.name or Name(it.id)) .. "|r" }
                if self.lvl then tip[#tip + 1] = string.format(L("niv. %d"), self.lvl) end
                for _, rg in ipairs(O.Decode(it.re)) do tip[#tip + 1] = S.Hex(C.dim) .. rg[2] .. "× " .. Name(rg[1]) .. "|r" end
                local all = {}
                for _, c in ipairs(it.who) do all[#all + 1] = CrafterName(c) end
                tip[#tip + 1] = string.format(L("Peuvent le fabriquer : %s"), table.concat(all, ", "))
                tip[#tip + 1] = self.crafter and string.format(L("Clic : commander à %s"), self.crafter) or L("Clic : commander à la guilde")
                S.Tip(self, tip)
            elseif self.tip then S.Tip(self, self.tip) end
        end)
        r:SetScript("OnLeave", S.HideTip)
        return r
    end)
    f.catEmpty = EmptyState(f.cat.content, W - 2 * PAD - 4)
    f.catNote = S.Text(f.cat.content, 12, C.dim); f.catNote:SetWidth(W - 2 * PAD - 4)
    f.catNote:SetJustifyH("LEFT"); f.catNote:SetJustifyV("TOP"); f.catNote:SetWordWrap(true); f.catNote:Hide()
end

-- which of the page's three areas shows: the result list, the grid, or a catalogue
local function SetMode(f, mode)
    f.list.sf:SetShown(mode == "list"); f.grid.sf:SetShown(mode == "grid"); f.cat.sf:SetShown(mode == "cat")
    local cat = mode == "cat"
    f.chead:SetShown(cat); f.box:SetShown(not cat); f.info:SetShown(not cat); f.mine:SetShown(not cat)
    f.back:Hide()
    -- the back button only in a crafter's view: the lines above take the whole width otherwise
    f.info:SetWidth(W - 2 * PAD); f.mine:SetWidth(W - 2 * PAD)
end

local function RenderGrid(f, g)
    local keys = {}
    for _, k in ipairs(GRID_PROFS) do
        if k ~= "mining" or (g.mining and g.mining.nItems > 0) then keys[#keys + 1] = k end
    end
    local tw = math.floor((W - 2 * PAD - GRID_GAP * (GRID_COLS - 1)) / GRID_COLS)
    local anyone, th = false, 0
    for i, key in ipairs(keys) do
        local e = g[key]
        local nC, nI, nO = e and #e.crafters or 0, e and e.nItems or 0, e and e.nOnline or 0
        if nC > 0 then anyone = true end
        local t = f.grid.Get(i)
        t.key = key
        t.icon:SetTexture(ProfIcon(key)); t.icon:SetDesaturated(nC == 0); t.icon:SetAlpha(nC == 0 and 0.5 or 1)
        -- every text wraps inside the tile rather than being cut
        for _, fs in ipairs({ t.name, t.count, t.online }) do fs:SetWidth(tw - 12) end
        t.name:SetText(ProfLabel(key))
        local nc = nC > 0 and C.text or C.dim
        t.name:SetTextColor(nc[1], nc[2], nc[3])
        t.count:SetText(string.format(L("%d artisans · %d objets"), nC, nI))
        local onNames = {}
        if e then
            table.sort(e.crafters, ByCrafter)
            for _, c in ipairs(e.crafters) do if c.online and not c.me then onNames[#onNames + 1] = c.name end end
        end
        if nO > 0 then
            t.online:SetText(string.format(L("%d en ligne"), nO)); t.online:SetTextColor(C.ready[1], C.ready[2], C.ready[3])
        else
            t.online:SetText(nC > 0 and L("personne en ligne") or ""); t.online:SetTextColor(C.muted[1], C.muted[2], C.muted[3])
        end
        t.tip = { ProfLabel(key), string.format(L("%d artisans · %d objets"), nC, nI) }
        if #onNames > 0 then t.tip[#t.tip + 1] = S.Hex(C.ready) .. string.format(L("En ligne : %s"), table.concat(onNames, ", ")) .. "|r" end
        t.tip[#t.tip + 1] = L("Clic : le catalogue de ce métier")
        -- the tallest tile sets the row height (names and counts may wrap on two lines)
        local need = 12 + 40 + 8 + (t.name:GetStringHeight() or 15) + 4 + (t.count:GetStringHeight() or 14)
            + 3 + (t.online:GetStringHeight() or 14) + 12
        if need > th then th = need end
    end
    th = math.max(130, math.ceil(th))
    for i = 1, #keys do
        local t = f.grid.Get(i)
        local col, row = (i - 1) % GRID_COLS, math.floor((i - 1) / GRID_COLS)
        t:SetSize(tw, th); t:ClearAllPoints(); t:SetPoint("TOPLEFT", col * (tw + GRID_GAP), -row * (th + GRID_GAP))
    end
    f.grid.HideFrom(#keys + 1)
    local y = math.ceil(#keys / GRID_COLS) * (th + GRID_GAP)
    f.gridEmpty:When(not anyone, L("Aucun artisan connu"),
        L("Les membres qui ont WL Helper partagent leurs métiers en se connectant : reviens dans un moment, ou publie une demande dans l'onglet Demander."))
    if not anyone then
        f.gridEmpty:ClearAllPoints(); f.gridEmpty:SetPoint("TOPLEFT", 2, -(y + 4))
        y = y + 4 + (f.gridEmpty:GetHeight() or 60) + 8
    end
    f.grid.content:SetHeight(math.max(10, y))
end

local function RenderCatalog(f, g)
    local key = f.prof
    local e = g[key] or { crafters = {}, items = {}, nItems = 0, nOnline = 0, unshared = {} }
    f.cicon:SetTexture(ProfIcon(key))
    f.ctitle:SetText(ProfLabel(key))
    local counts = string.format(L("%d artisans · %d objets"), #e.crafters, e.nItems)
    if e.nOnline > 0 then counts = counts .. "  ·  " .. S.Hex(C.ready) .. string.format(L("%d en ligne"), e.nOnline) .. "|r" end
    f.ccount:SetText(counts)
    f.ccount:SetWidth(math.max(60, W - 2 * PAD - 30 - math.ceil(f.ctitle:GetStringWidth() or 80) - 10))
    f.conline:Update()
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
    table.sort(items, function(a, b) if a.name ~= b.name then return a.name < b.name end return a.id < b.id end)
    local y, i = 0, 0
    if #items == 0 then
        if e.nItems == 0 then
            f.catEmpty:Set(L("Aucune recette partagée"), L("Les artisans de ce métier doivent ouvrir une fois leur fenêtre de métier pour que leurs recettes arrivent ici."))
        elseif f.onlineOnly then
            f.catEmpty:Set(L("Aucun objet trouvé"), L("Aucun artisan en ligne ne fabrique ce que tu cherches : décoche « en ligne » pour tout voir."))
        else
            f.catEmpty:Set(L("Aucun objet trouvé"), L("Rien dans ce métier ne correspond : essaie un autre mot, ou publie une demande dans l'onglet Demander."))
        end
        f.catEmpty:ClearAllPoints(); f.catEmpty:SetPoint("TOPLEFT", 2, -8)
        y = 8 + (f.catEmpty:GetHeight() or 60) + 14
    else f.catEmpty:Hide() end
    for n, it in ipairs(items) do
        if n > CAT_MAX then break end
        i = i + 1
        local r = f.cat.Get(i)
        r:ClearAllPoints(); r:SetPoint("TOPLEFT", 0, -y); r:SetHeight(56)
        r.kind, r.item, r.prof, r.open = "item", it.id, key, nil
        table.sort(it.who, ByCrafter)
        local best
        for _, c in ipairs(it.who) do if not c.me then best = c; break end end
        r.crafter = best and best.name or nil
        r.icon:SetTexture(ItemTex(it.id)); r.icon:Show(); r.cls:Hide()
        local qc = it.id > 0 and S.QualityColor(it.id) or C.text
        r.name:SetText(it.name); r.name:SetTextColor(qc[1], qc[2], qc[3])
        local lvl = ReqLevel(it.id)
        local reag = Reagents(it.re, 1)
        r.sub:SetText((lvl and (string.format(L("niv. %d"), lvl) .. "  ·  ") or "") .. (reag ~= "" and reag or L("composants inconnus")))
        r.who:SetText(IconMarkup("user", 12, C.muted) .. " " .. WhoText(it.who, 2)); r.who:Show()
        r.btn.label:SetText(L("Demander")); r.btn:Show()
        r.btnTip = { L("Demander à toute la guilde : ouvre l'onglet Demander, déjà rempli.") }
        -- the row's lines may be cut: the tooltip (built on hover) says everything
        r.it, r.lvl, r.tip = it, lvl, nil
        r.bg:SetColorTexture(C.card[1], C.card[2], C.card[3], 1); r.border(C.border); r.hl:Show()
        y = y + 60
    end
    -- the profession's crafters who shared recipes: their own lists
    if not filtered then
        local sharing = {}
        for _, c in ipairs(e.crafters) do if c.n > 0 then sharing[#sharing + 1] = c end end
        table.sort(sharing, ByCrafter)
        if #sharing > 0 then
            i = i + 1
            local hd = f.cat.Get(i)
            hd:ClearAllPoints(); hd:SetPoint("TOPLEFT", 0, -(y + 4)); hd:SetHeight(26)
            hd.kind, hd.item, hd.open, hd.crafter, hd.tip, hd.it = "head", nil, nil, nil, nil, nil
            hd.icon:Hide(); hd.cls:Hide(); hd.who:Hide(); hd.btn:Hide(); hd.sub:SetText("")
            hd.name:SetText(L("Artisans de ce métier")); hd.name:SetTextColor(C.dim[1], C.dim[2], C.dim[3])
            hd.bg:SetColorTexture(0, 0, 0, 0); hd.border(C.border, 0); hd.hl:Hide()
            y = y + 34
            for _, c in ipairs(sharing) do
                i = i + 1
                local r = f.cat.Get(i)
                r:ClearAllPoints(); r:SetPoint("TOPLEFT", 0, -y); r:SetHeight(46)
                r.kind, r.item, r.crafter, r.it = "crafter", nil, nil, nil
                r.open = { name = c.name, prof = c.prof, me = c.me }
                r.icon:Hide(); r.who:Hide()
                r.name:SetText(c.name .. (c.me and (" " .. S.Hex(C.muted) .. L("(toi)") .. "|r") or "")
                    .. (c.stars > 0 and (" " .. STAR .. S.Hex(C.warn) .. c.stars .. "|r") or ""))
                SetClass(r, c.name)
                r.sub:SetText(c.rank .. "  ·  " .. (c.online and (S.Hex(C.ready) .. L("en ligne") .. "|r") or L("hors ligne"))
                    .. "  ·  " .. string.format(L("%d recettes"), c.n))
                r.btn.label:SetText(L("Recettes")); r.btn:Show()
                r.btnTip = { string.format(L("Recettes de %s : %s %d"), c.name, ProfLabel(key), c.rank) }
                r.tip = r.btnTip
                r.bg:SetColorTexture(C.card[1], C.card[2], C.card[3], 1); r.border(C.border); r.hl:Show()
                y = y + 50
            end
        end
    end
    f.cat.HideFrom(i + 1)
    -- declared the profession, shared nothing: who, and what they have to do
    if #e.unshared > 0 then
        f.catNote:ClearAllPoints(); f.catNote:SetPoint("TOPLEFT", 2, -(y + 6))
        f.catNote:SetText(IconMarkup("info", 12, C.muted) .. " "
            .. string.format(L("Recettes non partagées : %s — ils doivent ouvrir leur fenêtre de métier une fois."), table.concat(e.unshared, ", ")))
        f.catNote:Show()
        y = y + 6 + (f.catNote:GetStringHeight() or 14) + 8
    else f.catNote:Hide() end
    f.cat.content:SetHeight(math.max(10, y))
end

local function RenderFind()
    local f = ui.find
    local q = (f.box:GetText() or ""):lower()
    local crafters, online = 0, 0
    local on = O.OnlineGuild()
    for name in pairs(O.DB().crafters) do crafters = crafters + 1; if on[name] then online = online + 1 end end
    -- what this copy read of your own professions (so you can see that sharing works)
    local mineT, noRecipe = {}, true
    for prof, p in pairs(O.DB().mine or {}) do
        local n = 0
        for _ in pairs(p.recipes or {}) do n = n + 1 end
        if n > 0 then noRecipe = false end
        mineT[#mineT + 1] = ProfLabel(ProfKey(prof), prof) .. " " .. (p.rank or 0) .. " · "
            .. (n > 0 and string.format(L("%d recettes"), n) or L("recettes pas encore partagées"))
    end
    table.sort(mineT)
    f.info:SetText(string.format(L("%d artisans connus · %d en ligne"), crafters, online))
    local mineLine = #mineT > 0 and string.format(L("tes métiers : %s"), table.concat(mineT, "   ")) or L("tes métiers : aucun")
    -- the profession list with none of your recipes shared yet: how to share them
    if #mineT > 0 and noRecipe and #q < 2 and not f.view then
        mineLine = mineLine .. "\n" .. L("Ouvre une fois ta fenêtre de métier pour partager tes recettes.")
    end
    f.mine:SetText(mineLine)
    -- one crafter picked: what they make (when their recipe list arrived)
    if f.view and #q < 2 then
        SetMode(f, "list")
        local v = f.view
        local p = v.me and O.DB().mine[v.prof] or (O.DB().crafters[v.name] or {})[v.prof]
        local items = {}
        for id in pairs(p and p.recipes or {}) do items[#items + 1] = { id = id, name = Name(id) } end
        table.sort(items, function(a, b) return a.name < b.name end)
        -- back to the profession's catalogue it came from, else to the grid; the lines stop before it
        f.back:SetLabel(f.prof and ProfLabel(f.prof) or L("Tous les métiers")); f.back:Show()
        local lw = W - 2 * PAD - (f.back:GetWidth() or 130) - 8
        f.info:SetWidth(lw); f.mine:SetWidth(lw)
        f.mine:SetText(string.format(L("Recettes de %s : %s %d"), v.name, ProfLabel(ProfKey(v.prof), v.prof), p and p.rank or 0))
        local y = 0
        for i, it in ipairs(items) do
            local id = it.id
            local row = f.list.Get(i)
            row:ClearAllPoints(); row:SetPoint("TOPLEFT", 0, -y)
            row.item, row.crafter, row.whisper, row.open = id, not v.me and v.name or nil, nil, nil
            row.cls:Hide(); row.icon:Show(); row.icon:SetTexture(ItemTex(id))
            row.name:SetText(it.name); local qc = id > 0 and S.QualityColor(id) or C.text; row.name:SetTextColor(qc[1], qc[2], qc[3])
            row.sub:SetText(Reagents(p.recipes[id] or "", 1))
            -- name and every reagent on its own line, built on hover only
            local tip = { S.Hex(qc) .. it.name .. "|r" }
            row.tip = tip
            row.tipFill = function()
                for k = #tip, 2, -1 do tip[k] = nil end
                for _, rg in ipairs(O.Decode(p.recipes[id] or "")) do tip[#tip + 1] = S.Hex(C.dim) .. rg[2] .. "× " .. Name(rg[1]) .. "|r" end
            end
            row.btn.label:SetText(L("Commander")); row.btn:SetShown(not v.me)
            TwoButtons(row, not v.me, v.prof)
            row.bg:SetColorTexture(C.card[1], C.card[2], C.card[3], 1)
            y = y + 46
            if i >= 150 then break end
        end
        f.list.HideFrom(math.min(#items, 150) + 1)
        f.empty:When(#items == 0, L("Recettes pas encore arrivées"),
            L("Ses recettes arrivent quand il ouvre sa fenêtre de métier, ou de Mastercraft s'il l'a."))
        f.list.content:SetHeight(math.max(10, y + (#items == 0 and 80 or 0)))
        return
    end
    -- a profession picked in the grid: its catalogue
    if f.prof then
        SetMode(f, "cat")
        RenderCatalog(f, GuildCrafts())
        return
    end
    -- an item link (shift-click an item) or "item:12345": order it from the guild, recipe known or not
    local linked = tonumber((f.box:GetText() or ""):match("item:(%d+)"))
    if linked then
        SetMode(f, "list")
        local row = f.list.Get(1)
        row:ClearAllPoints(); row:SetPoint("TOPLEFT", 0, 0)
        row.item, row.crafter, row.whisper, row.open = linked, nil, nil, nil
        row.cls:Hide(); row.icon:Show(); row.icon:SetTexture(S.ItemIcon(linked))
        row.name:SetText(Name(linked)); local qc = S.QualityColor(linked); row.name:SetTextColor(qc[1], qc[2], qc[3])
        local who = O.Possible(linked)
        row.sub:SetText(#who > 0 and string.format(L("%d artisans possibles · Commander : toute la guilde la voit"), #who) or L("personne n'a encore déclaré ce métier : la guilde verra quand même la commande"))
        row.tip, row.tipFill = { S.Hex(qc) .. Name(linked) .. "|r", row.sub:GetText() }, nil
        row.btn.label:SetText(L("Commander")); row.btn:Show(); TwoButtons(row, false)
        row.bg:SetColorTexture(C.brandBg[1], C.brandBg[2], C.brandBg[3], 1)
        -- each possible crafter: exact (shared recipe) or by profession, online first
        local y = 46
        for i, c in ipairs(who) do
            local cr = f.list.Get(i + 1)
            cr:ClearAllPoints(); cr:SetPoint("TOPLEFT", 0, -y)
            cr.item, cr.crafter, cr.whisper, cr.open = linked, c.name, nil, nil
            cr.icon:Hide()
            local stars = O.Stars(c.name)
            cr.name:SetText(c.name .. (stars > 0 and (" " .. STAR .. S.Hex(C.warn) .. stars .. "|r") or ""))
            SetClass(cr, c.name)
            local key = ProfKey(c.prof)
            cr.sub:SetText(ProfMarkup(key) .. " " .. ProfLabel(key, c.prof) .. " " .. (c.rank or 0)
                .. "  ·  " .. (c.online and (S.Hex(C.ready) .. L("en ligne") .. "|r") or L("hors ligne"))
                .. "  ·  " .. (c.exact and L("recette connue") or L("métier compatible")))
            cr.tip, cr.tipFill = { cr.name:GetText(), cr.sub:GetText() }, nil
            cr.btn.label:SetText(L("À lui")); cr.btn:Show(); TwoButtons(cr, false)
            cr.bg:SetColorTexture(C.card[1], C.card[2], C.card[3], 1)
            y = y + 46
            if i >= 30 then break end
        end
        f.list.HideFrom(math.min(#who, 30) + 2)
        f.empty:Hide()
        f.list.content:SetHeight(y + 4)
        return
    end
    -- nothing typed: the profession grid
    if #q < 2 then
        SetMode(f, "grid")
        RenderGrid(f, GuildCrafts())
        return
    end
    -- a name typed: every shared recipe whose item matches, one row per crafter
    SetMode(f, "list")
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
    local y = 0
    for i, r in ipairs(rows) do
        local row = f.list.Get(i)
        row:ClearAllPoints(); row:SetPoint("TOPLEFT", 0, -y)
        row.item, row.crafter, row.whisper, row.open = r.item, not r.c.me and r.c.name or nil, nil, nil
        row.btn.label:SetText(L("Commander"))
        row.cls:Hide(); row.icon:Show(); row.icon:SetTexture(ItemTex(r.item))
        row.bg:SetColorTexture(C.card[1], C.card[2], C.card[3], 1)
        row.name:SetText(names[r.item]); local qc = r.item > 0 and S.QualityColor(r.item) or C.text; row.name:SetTextColor(qc[1], qc[2], qc[3])
        local where = r.c.online and S.Hex(C.ready) .. L("en ligne") .. "|r"
            or (r.c.seen and string.format(L("vu il y a %d j"), math.floor((time() - r.c.seen) / 86400)) or L("hors ligne"))
        row.sub:SetText(r.c.name .. " · " .. ProfLabel(ProfKey(r.c.prof), r.c.prof) .. " " .. (r.c.rank or 0) .. " · " .. where)
        row.tip, row.tipFill = { S.Hex(qc) .. names[r.item] .. "|r", row.sub:GetText() }, nil
        row.btn:SetShown(not r.c.me); TwoButtons(row, false)
        y = y + 46
        if i >= 60 then break end
    end
    f.list.HideFrom(math.min(#rows, 60) + 1)
    if next(catalog) == nil then
        f.empty:Set(L("Aucune recette partagée"), L("Chaque membre qui a WL Helper, toi compris, partage ses recettes en ouvrant une fois sa fenêtre de métier."))
    else
        f.empty:When(#rows == 0, L("Aucun objet trouvé"), L("Personne n'a partagé cette recette : l'onglet Demander prévient quand même toute la guilde."))
    end
    f.list.content:SetHeight(math.max(10, y + (#rows == 0 and 80 or 0)))
end

-- ---------------------------------------------------------------- page 2: a new order
local draft
local function BuildNew(p)
    local n = ui.new
    n.icon = p:CreateTexture(nil, "ARTWORK"); n.icon:SetSize(36, 36); n.icon:SetPoint("TOPLEFT", PAD, -12); n.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    n.name = S.Text(p, 17, C.text, true); n.name:SetPoint("TOPLEFT", n.icon, "TOPRIGHT", 10, -2); n.name:SetPoint("RIGHT", -100, 0); n.name:SetJustifyH("LEFT")
    n.qtyBox = Box(p, 50, 28, true); n.qtyBox:SetPoint("TOPRIGHT", -PAD, -14)
    n.qtyBox:HookScript("OnTextChanged", function(self, user) if user then draft.qty = math.max(1, tonumber(self:GetText() or "") or 1); WP.RefreshOrders() end end)
    -- to the whole guild, or only to the crafter picked in the list
    local half = (W - 2 * PAD - 8) / 2
    n.toGuild = S.Button(p, L("Toute la guilde"), half, 28, "secondary", function() draft.to = nil; WP.RefreshOrders() end)
    n.toGuild:SetPoint("TOPLEFT", PAD, -60)
    n.toOne = S.Button(p, "", half, 28, "secondary", function() if draft.crafter then draft.to = draft.crafter; WP.RefreshOrders() end end)
    n.toOne:SetPoint("LEFT", n.toGuild, "RIGHT", 8, 0)
    n.rlabel = S.Section(p, L("Composants")); n.rlabel:SetPoint("TOPLEFT", PAD, -100)
    n.cost = S.Text(p, 12, C.dim); n.cost:SetPoint("TOPRIGHT", -PAD, -100); n.cost:SetJustifyH("RIGHT")
    n.noRecipe = S.Text(p, 12, C.dim); n.noRecipe:SetPoint("TOPLEFT", PAD, -122); n.noRecipe:SetPoint("RIGHT", -PAD, 0)
    n.noRecipe:SetJustifyH("LEFT"); n.noRecipe:SetWordWrap(true)
    n.noRecipe:SetText(L("Recette inconnue : écris dans la note qui fournit quoi, l'artisan verra la commande."))
    n.rows = {}
    for i = 1, 8 do
        local r = CreateFrame("Button", nil, p)
        r:SetSize(W - 2 * PAD, 26); r:SetPoint("TOPLEFT", PAD, -118 - (i - 1) * 28)
        S.Solid(r, "BACKGROUND", C.card):SetAllPoints()
        S.Solid(r, "HIGHLIGHT", { 1, 1, 1 }, 0.05):SetAllPoints()
        r.tag = S.Text(r, 12, C.ready); r.tag:SetPoint("RIGHT", -8, 0); r.tag:SetWidth(170); r.tag:SetJustifyH("RIGHT"); r.tag:SetWordWrap(false)
        r.name = S.Text(r, 13, C.text); r.name:SetPoint("LEFT", 8, 0); r.name:SetPoint("RIGHT", r.tag, "LEFT", -6, 0); r.name:SetJustifyH("LEFT"); r.name:SetWordWrap(false)
        r:SetScript("OnClick", function(self) if self.id then draft.crafterGives[self.id] = not draft.crafterGives[self.id]; WP.RefreshOrders() end end)
        r:SetScript("OnEnter", function(self) S.Tip(self, { L("Clic : qui le fournit") }) end)
        r:SetScript("OnLeave", S.HideTip)
        n.rows[i] = r
    end
    local y0 = -118 - 8 * 28 - 6
    local fl = S.Text(p, 13, C.dim); fl:SetPoint("TOPLEFT", PAD, y0); fl:SetText(L("Commission"))
    n.fee = Box(p, 80, 28, true, L("po")); n.fee:SetPoint("TOPLEFT", PAD, y0 - 18)
    n.fee:HookScript("OnTextChanged", function(self, user) if user then draft.fee = (tonumber(self:GetText() or "") or 0) * 10000 end end)
    local tl = S.Text(p, 13, C.dim); tl:SetPoint("TOPLEFT", PAD + 96, y0); tl:SetText(L("Pourboire"))
    n.tip = Box(p, 80, 28, true, L("po")); n.tip:SetPoint("TOPLEFT", PAD + 96, y0 - 18)
    n.tip:HookScript("OnTextChanged", function(self, user) if user then draft.tip = (tonumber(self:GetText() or "") or 0) * 10000 end end)
    local vl = S.Text(p, 13, C.dim); vl:SetPoint("TOPLEFT", PAD + 192, y0); vl:SetText(L("Valable"))
    n.hours = S.Segmented(p, { { 12, "12 h" }, { 24, "24 h" }, { 72, L("3 j") } }, function() return draft and draft.hours or 24 end,
        function(v) draft.hours = v; WP.RefreshOrders() end, 28)
    n.hours:SetPoint("TOPLEFT", PAD + 192, y0 - 18)
    n.note = Box(p, W - 2 * PAD, 28, false, L("Un mot pour l'artisan")); n.note:SetPoint("TOPLEFT", PAD, y0 - 52)
    n.note:SetMaxLetters(60)
    n.payUp = S.Switch(p, function() return draft and draft.payUp end, function(v) draft.payUp = v end)
    n.payUp:SetPoint("TOPRIGHT", -PAD, y0 - 86)
    local pl = S.Text(p, 13, C.text); pl:SetPoint("RIGHT", n.payUp, "LEFT", -10, 0); pl:SetText(L("Payer d'avance"))
    n.go = S.Button(p, L("Publier la commande"), W - 2 * PAD, 34, "primary", function()
        local give, crafter = {}, {}
        for _, r in ipairs(O.Reagents(draft.item)) do
            if draft.crafterGives[r[1]] then crafter[#crafter + 1] = r[1] .. ":" .. r[2] else give[#give + 1] = r[1] .. ":" .. r[2] end
        end
        local fee = draft.fee or 0
        O.Publish({ to = draft.to, item = draft.item, qty = draft.qty or 1, give = table.concat(give, ","), crafter = table.concat(crafter, ","),
            fee = fee, tip = draft.tip or 0, paid = draft.payUp and (fee + (draft.tip or 0)) or 0, note = n.note:GetText() or "", hours = draft.hours or 24 })
        WP.ShowOrdersTab("mine")
    end)
    n.go:SetPoint("BOTTOMLEFT", PAD, 30)
    local hint = S.Text(p, 12, C.dim); hint:SetPoint("BOTTOM", 0, 12); hint:SetText(L("Rien ne part par la poste avant qu'un artisan ait accepté."))
end

local function RenderNew()
    local n = ui.new
    if not draft then return end
    n.icon:SetTexture(S.ItemIcon(draft.item))
    n.name:SetText(Name(draft.item))
    if not n.qtyBox:HasFocus() then n.qtyBox:SetText(tostring(draft.qty or 1)) end
    n.toOne.label:SetText(draft.crafter and string.format(L("Seulement %s"), draft.crafter) or "—")
    n.toOne:SetEnabled(draft.crafter ~= nil)
    local sel, dim = C.brandSoft or C.brand, C.dim
    local g, o = draft.to and dim or sel, draft.to and sel or dim
    n.toGuild.label:SetTextColor(g[1], g[2], g[3]); n.toOne.label:SetTextColor(o[1], o[2], o[3])
    local reagents = O.Reagents(draft.item)
    n.noRecipe:SetShown(#reagents == 0)
    -- what the reagents cost at the auction house, and a fee in proportion (10 %, at least 1 gold)
    local total, priced = 0, true
    for _, rg in ipairs(reagents) do
        local pr = WP.Price and WP.Price(rg[1])
        if pr then total = total + pr * rg[2] * (draft.qty or 1) else priced = false end
    end
    if #reagents > 0 and total > 0 then
        local fee = math.max(10000, math.floor(total * 0.1 / 100) * 100)
        n.cost:SetText(string.format(L("composants %s%s · commission conseillée %s"), priced and "" or "~", Money(total), Money(fee)))
    else n.cost:SetText("") end
    for i, r in ipairs(n.rows) do
        local rg = reagents[i]
        r:SetShown(rg ~= nil)
        if rg then
            r.id = rg[1]
            local need = rg[2] * (draft.qty or 1)
            local have = WP.OwnedCount and WP.OwnedCount(rg[1]) or 0
            r.name:SetText(need .. "× " .. Name(rg[1]))
            if draft.crafterGives[rg[1]] then
                local p = WP.Price(rg[1])
                r.tag:SetText(L("l'artisan fournit") .. (p and (" · ~" .. Money(p * need)) or "")); r.tag:SetTextColor(C.warn[1], C.warn[2], C.warn[3])
            else
                r.tag:SetText(L("je fournis") .. " · " .. have .. "/" .. need)
                local c = have >= need and C.ready or C.danger
                r.tag:SetTextColor(c[1], c[2], c[3])
            end
        end
    end
    n.hours:Update()
    if n.payUp.Update then n.payUp:Update() end
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

-- ---------------------------------------------------------------- the Request tab
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

local function BuildAsk(p)
    local a = ui.ask
    local lt = S.Text(p, 13, C.dim); lt:SetPoint("TOPLEFT", PAD, -12); lt:SetText(L("Ce que tu veux"))
    a.box = Box(p, W - 2 * PAD, 30, false, L("Nom de l'objet, ou Maj-clic sur un objet"))
    a.box:SetPoint("TOPLEFT", PAD, -30)
    a.box:HookScript("OnTextChanged", function() WP.RefreshOrders() end)
    -- what the text was recognised as (never the typed text itself: it could be any length)
    a.foundIcon = p:CreateTexture(nil, "ARTWORK"); a.foundIcon:SetSize(18, 18); a.foundIcon:SetPoint("TOPLEFT", PAD, -68)
    a.foundIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    a.found = S.Text(p, 12, C.dim); a.found:SetPoint("LEFT", a.foundIcon, "RIGHT", 6, 0); a.found:SetPoint("RIGHT", p, "RIGHT", -PAD, 0)
    a.found:SetJustifyH("LEFT")
    -- the profession: its icons, and "I don't know"
    local pl = S.Text(p, 13, C.dim); pl:SetPoint("TOPLEFT", PAD, -98); pl:SetText(L("Métier"))
    a.profName = S.Text(p, 13, C.text); a.profName:SetPoint("LEFT", pl, "RIGHT", 8, 0); a.profName:SetPoint("RIGHT", p, "RIGHT", -PAD, 0)
    a.profName:SetJustifyH("LEFT")
    a.profs = {}
    local x = PAD
    for i, key in ipairs(ASK_PROFS) do
        local b = CreateFrame("Button", nil, p)
        b:SetSize(32, 32); b:SetPoint("TOPLEFT", x, -116)
        S.Solid(b, "BACKGROUND", C.card):SetAllPoints()
        b.icon = b:CreateTexture(nil, "ARTWORK"); b.icon:SetPoint("TOPLEFT", 2, -2); b.icon:SetPoint("BOTTOMRIGHT", -2, 2)
        b.icon:SetTexture(ProfIcon(key)); b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        b.border = S.Border(b, C.border)
        b.key = key
        b:SetScript("OnClick", function(self) askState.prof, askState.picked = self.key, true; WP.RefreshOrders() end)
        b:SetScript("OnEnter", function(self) S.Tip(self, { ProfLabel(self.key) }) end)
        b:SetScript("OnLeave", S.HideTip)
        a.profs[i] = b
        x = x + 38
    end
    -- "I don't know": a framed word the same height as the icons, in the room left on the line
    local dk = CreateFrame("Button", nil, p)
    dk:SetHeight(32); dk:SetPoint("TOPLEFT", x + 4, -116)
    S.Solid(dk, "BACKGROUND", C.card):SetAllPoints()
    dk.label = S.Text(dk, 13, C.text); dk.label:SetPoint("CENTER"); dk.label:SetText(L("Je ne sais pas"))
    dk:SetWidth(math.min(W - PAD - (x + 4), math.max(90, (dk.label:GetStringWidth() or 80) + 24)))
    dk.border = S.Border(dk, C.border)
    dk:SetScript("OnClick", function() askState.prof, askState.picked = "", true; WP.RefreshOrders() end)
    dk:SetScript("OnEnter", function(self) S.Tip(self, { L("Je ne sais pas : tous les artisans sont prévenus") }) end)
    dk:SetScript("OnLeave", S.HideTip)
    a.dunno = dk
    -- quantity, fee in gold, how long it stays open
    local y0 = -162
    local ql = S.Text(p, 13, C.dim); ql:SetPoint("TOPLEFT", PAD, y0); ql:SetText(L("Quantité"))
    a.qty = Box(p, 80, 28, true); a.qty:SetPoint("TOPLEFT", PAD, y0 - 18); a.qty:SetText("1")
    local fl = S.Text(p, 13, C.dim); fl:SetPoint("TOPLEFT", PAD + 96, y0); fl:SetText(L("Commission"))
    a.fee = Box(p, 80, 28, true, L("po")); a.fee:SetPoint("TOPLEFT", PAD + 96, y0 - 18)
    local vl = S.Text(p, 13, C.dim); vl:SetPoint("TOPLEFT", PAD + 192, y0); vl:SetText(L("Valable"))
    a.hours = S.Segmented(p, { { 12, "12 h" }, { 24, "24 h" }, { 72, L("3 j") } }, function() return askState.hours or 24 end,
        function(v) askState.hours = v end, 28)
    a.hours:SetPoint("TOPLEFT", PAD + 192, y0 - 18)
    a.note = Box(p, W - 2 * PAD, 28, false, L("Un mot pour l'artisan")); a.note:SetPoint("TOPLEFT", PAD, y0 - 58)
    a.note:SetMaxLetters(60)
    -- who will be told (online first), up to three lines
    a.summary = S.Text(p, 12, C.dim); a.summary:SetPoint("TOPLEFT", PAD, y0 - 100); a.summary:SetWidth(W - 2 * PAD)
    a.summary:SetJustifyH("LEFT"); a.summary:SetJustifyV("TOP"); a.summary:SetWordWrap(true)
    if a.summary.SetMaxLines then a.summary:SetMaxLines(3) end
    a.err = S.Text(p, 13, C.danger); a.err:SetPoint("BOTTOMLEFT", PAD, 72); a.err:SetWidth(W - 2 * PAD); a.err:SetJustifyH("LEFT"); a.err:Hide()
    a.go = S.Button(p, L("Publier"), W - 2 * PAD, 34, "primary", function()
        local text = a.box:GetText() or ""
        local id = Resolve(text)
        local title = (not id) and O.CleanTitle(text) or nil
        if not id and (not title or title == "") then
            a.err:SetText(L("Écris ce que tu veux, ou Maj-clic sur un objet.")); a.err:Show()
            return
        end
        local key = askState.prof or ""
        local prof = (key ~= "" and PROFS[key]) and PROFS[key][2] or ""
        local qty = math.max(1, tonumber(a.qty:GetText() or "") or 1)
        local fee = (tonumber(a.fee:GetText() or "") or 0) * 10000
        local o = O.Publish({ item = id, title = title, prof = prof, qty = qty, give = "", crafter = "", fee = fee, tip = 0, paid = 0,
            note = a.note:GetText() or "", hours = askState.hours or 24 })
        WP.Print(string.format(L("Demande publiée : %s ×%d (%s). Les artisans de la guilde sont prévenus."), Name(o), qty, O.ProfName(prof)))
        askState = { prof = "", hours = 24 }
        a.box:SetText(""); a.note:SetText(""); a.fee:SetText(""); a.qty:SetText("1"); a.err:Hide()
        WP.ShowOrdersTab("mine")
    end)
    a.go:SetPoint("BOTTOMLEFT", PAD, 30)
    local hint = S.Text(p, 12, C.dim); hint:SetPoint("BOTTOM", 0, 12); hint:SetText(L("Rien ne part par la poste avant qu'un artisan ait accepté."))
end

local function RenderAsk()
    local a = ui.ask
    local text = a.box:GetText() or ""
    local id = Resolve(text)
    if text ~= "" then a.err:Hide() end
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
    if id then
        a.foundIcon:SetTexture(S.ItemIcon(id)); a.foundIcon:Show()
        a.found:SetText(string.format(L("Objet reconnu : %s"), S.Hex(S.QualityColor(id)) .. Name(id) .. "|r"))
    elseif Trim(text) ~= "" then
        a.foundIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark"); a.foundIcon:Show()
        a.found:SetText(L("Pas un objet connu du jeu : la demande part avec ce texte."))
    else
        a.foundIcon:Hide()
        a.found:SetText(L("Tape un nom, ou Maj-clic sur un objet (sacs, chat, recette)."))
    end
    -- the profession picked: brand border; the others dimmed while one is picked
    local cur = askState.prof or ""
    for _, b in ipairs(a.profs) do
        local on = b.key == cur
        b.border(on and C.brand or C.border)
        b.icon:SetDesaturated(cur ~= "" and not on)
        b.icon:SetAlpha((cur ~= "" and not on) and 0.6 or 1)
    end
    a.dunno.border(cur == "" and C.brand or C.border)
    local dc = cur == "" and (C.brandSoft or C.text) or C.dim
    a.dunno.label:SetTextColor(dc[1], dc[2], dc[3])
    a.profName:SetText(cur == "" and L("Je ne sais pas : tous les artisans sont prévenus") or ProfLabel(cur))
    if not a.qty:HasFocus() and (a.qty:GetText() or "") == "" then a.qty:SetText("1") end
    a.hours:Update()
    -- who will be told: the same rule as the alert (recipe known, or the profession; any one when unknown)
    local prof = (cur ~= "" and PROFS[cur]) and PROFS[cur][2] or ""
    local me = UnitName("player")
    local who, on, off, online = O.Possible(id, prof), {}, {}, 0
    local n = 0
    for _, c in ipairs(who) do
        if not c.me and c.name ~= me then
            n = n + 1
            if c.online then online = online + 1; on[#on + 1] = S.Hex(C.ready) .. c.name .. "|r" else off[#off + 1] = c.name end
        end
    end
    if n == 0 then
        a.summary:SetText(L("personne n'a encore déclaré ce métier : la guilde verra quand même la commande"))
    else
        local names = {}
        for _, s in ipairs(on) do if #names < 6 then names[#names + 1] = s end end
        for _, s in ipairs(off) do if #names < 6 then names[#names + 1] = s end end
        a.summary:SetText(string.format(L("%d artisans prévenus · %d en ligne"), n, online) .. " : " .. table.concat(names, ", ")
            .. (n > #names and ", ..." or ""))
    end
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
    a.err:Hide()
    WP.ShowOrdersTab("ask")
end

-- ---------------------------------------------------------------- pages 3 and 4: my orders, received
local function OrderCard(parent)
    local c = CreateFrame("Frame", nil, parent)
    c:SetWidth(W - 2 * PAD)
    S.Solid(c, "BACKGROUND", C.card):SetAllPoints(); S.Border(c, C.border)
    c.icon = c:CreateTexture(nil, "ARTWORK"); c.icon:SetSize(28, 28); c.icon:SetPoint("TOPLEFT", 10, -8); c.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    c.title = S.Text(c, 15, C.text, true); c.title:SetPoint("TOPLEFT", 46, -8); c.title:SetPoint("RIGHT", -100, 0); c.title:SetJustifyH("LEFT"); c.title:SetWordWrap(false)
    c.fee = S.Text(c, 14, C.warn, true); c.fee:SetPoint("TOPRIGHT", -10, -8); c.fee:SetJustifyH("RIGHT")
    c.who = S.Text(c, 12, C.dim); c.who:SetPoint("TOPLEFT", 46, -28); c.who:SetPoint("RIGHT", -10, 0); c.who:SetJustifyH("LEFT")
    -- what to do now, in one line (highlighted when it is your turn)
    c.next = S.Text(c, 13, C.text, true); c.next:SetPoint("TOPLEFT", 10, -46); c.next:SetPoint("RIGHT", -10, 0); c.next:SetJustifyH("LEFT"); c.next:SetWordWrap(true)
    c.detail = S.Text(c, 12, C.text); c.detail:SetPoint("TOPLEFT", c.next, "BOTTOMLEFT", 0, -4); c.detail:SetPoint("RIGHT", -10, 0); c.detail:SetJustifyH("LEFT"); c.detail:SetWordWrap(true)
    c.b1 = S.Button(c, "", 110, 26, "primary", function() if c.a1 then c.a1() end end)
    c.b2 = S.Button(c, "", 110, 26, "secondary", function() if c.a2 then c.a2() end end)
    c.b3 = S.Button(c, L("Message"), 90, 26, "secondary", function() if c.o then WP.AskMessage(c.o) end end)
    c.b1:SetPoint("BOTTOMLEFT", 10, 8); c.b2:SetPoint("LEFT", c.b1, "RIGHT", 8, 0)
    c.b3:SetPoint("BOTTOMRIGHT", -10, 8)
    return c
end

Reagents = function(s, qty)
    local t = {}
    for _, r in ipairs(O.Decode(s)) do t[#t + 1] = (r[2] * (qty or 1)) .. "× " .. Name(r[1]) end
    return table.concat(t, ", ")
end

-- a tip of 1 gold more, and where it goes
local function AddTip(o)
    O.AddTip(o, 10000)
    if o.status == "crafted" then
        WP.Print(string.format(L("Pourboire pour %s : %s au total, payé à la réception (contre-remboursement) ou en échange."), o.by or "?", Money(o.tip)))
    else
        WP.Print(string.format(L("Pourboire pour %s : %s au total. Envoie-le par la poste ou en échange : l'addon ne déplace pas d'or tout seul."), o.by or "?", Money(o.tip)))
    end
    WP.RefreshOrders()
end

-- order again: a request (o.prof set, or no item) goes back to the Request tab, filled in
local function Reorder(o, crafter)
    if o.prof or not o.item or o.item == 0 then WP.AskOrder(o.item, o.prof, o)
    else WP.NewOrder(o.item, crafter, o) end
end

local function PaintOrder(c, o, side)
    c.o = o
    -- the item's icon (an enchant: its spell's), title in the item's quality colour
    local item = o.item or 0
    local tex
    if item > 0 then tex = S.ItemIcon(item)
    elseif item < 0 then
        tex = ((C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(-item)) or (GetSpellTexture and GetSpellTexture(-item)))
            or "Interface\\Icons\\Trade_Engraving"
    else
        local pk = o.prof and o.prof ~= "" and ProfKey(o.prof)
        tex = pk and ProfIcon(pk) or "Interface\\Icons\\INV_Misc_QuestionMark"
    end
    c.icon:SetTexture(tex)
    if item > 0 then
        local qc = S.QualityColor(item); c.title:SetTextColor(qc[1], qc[2], qc[3])
    else c.title:SetTextColor(C.text[1], C.text[2], C.text[3]) end
    c.title:SetText((o.qty or 1) .. "× " .. Name(o))
    c.fee:SetText(Money((o.fee or 0) + (o.tip or 0)))
    local col = STATUS_COL[o.status] or C.dim
    local st = S.Hex(col) .. L(STATUS[o.status] or o.status) .. "|r"
    local who
    local function Star(name) local n = name and O.Stars(name) or 0; return n > 0 and (" " .. STAR .. S.Hex(C.warn) .. n .. "|r") or "" end
    if side == "mine" then who = (o.to and string.format(L("pour %s"), o.to) or L("pour la guilde")) .. (o.by and (" · " .. string.format(L("par %s"), o.by) .. Star(o.by)) or "")
    else who = o.from .. " · " .. (o.to and string.format(L("pour %s"), o.to) or L("pour la guilde")) end
    if o.status == "open" and o.expires then who = who .. " · " .. string.format(L("expire dans %d h"), math.max(0, math.floor((o.expires - time()) / 3600))) end
    c.who:SetText(st .. " · " .. who)
    local lines = {}
    if o.prof then lines[#lines + 1] = S.Hex(C.info) .. L("Demande") .. "|r · " .. O.ProfName(o.prof) end
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
            t[#t + 1] = S.Hex(ok and C.ready or C.danger) .. g.need .. "× " .. Name(g.id) .. " (" .. math.min(g.have, g.need) .. "/" .. g.need .. ")|r"
                .. (bank > 0 and (S.Hex(C.warn) .. string.format(L(" dont %d en banque"), math.min(bank, g.need)) .. "|r") or "")
        end
        if (o.paid or 0) > 0 then t[#t + 1] = S.Hex(C.warn) .. string.format(L("%s d'avance"), Money(o.paid)) .. "|r" end
        lines[#lines + 1] = S.Hex(C.text) .. string.format(L("À envoyer à %s :"), o.by or "?") .. "|r " .. table.concat(t, ", ")
    elseif o.give and o.give ~= "" then
        local who = side == "mine" and L("je fournis") or string.format(L("%s fournit"), o.from)
        lines[#lines + 1] = S.Hex(C.ready) .. who .. "|r " .. Reagents(o.give, o.qty) .. (o.sentGive and (" · " .. S.Hex(C.ready) .. L("envoyés") .. "|r") or "")
    end
    if o.crafter and o.crafter ~= "" then
        if side == "recv" and o.status == "accepted" then
            -- the crafter's own share, with what they hold
            local t = {}
            for _, r in ipairs(O.Decode(o.crafter)) do
                local need = r[2] * (o.qty or 1)
                local have = WP.OwnedCount and WP.OwnedCount(r[1]) or 0
                t[#t + 1] = S.Hex(have >= need and C.ready or C.danger) .. need .. "× " .. Name(r[1]) .. " (" .. math.min(have, need) .. "/" .. need .. ")|r"
            end
            lines[#lines + 1] = S.Hex(C.warn) .. L("Tu fournis :") .. "|r " .. table.concat(t, ", ")
        else
            lines[#lines + 1] = S.Hex(C.warn) .. L("l'artisan fournit") .. "|r " .. Reagents(o.crafter, o.qty)
        end
    end
    -- the next step, said plainly: whose turn it is and what to do
    local nxt, mineTurn = "", false
    local stt = o.status
    if side == "board" or (side == "recv" and stt == "open") then
        nxt, mineTurn = L("À toi : accepte si tu peux la fabriquer."), true
    elseif side == "mine" and stt == "open" then
        nxt = L("En attente d'un artisan.")
    elseif side == "mine" and stt == "accepted" then
        if toSend then
            mineTurn = true
            if #missing > 0 then nxt = string.format(L("À toi : il te manque des composants à envoyer à %s."), o.by or "?")
            elseif inBank then nxt = string.format(L("À toi : sors les composants de la banque, puis va à une boîte aux lettres ou échange avec %s."), o.by or "?")
            else nxt = string.format(L("À toi : envoie les composants à %s (poste ou échange)."), o.by or "?") end
        else
            nxt = string.format(L("%s fabrique ta commande."), o.by or "?")
        end
    elseif side == "mine" and stt == "crafted" then
        nxt = string.format(L("Fabriquée : elle arrive par la poste ou en échange avec %s."), o.by or "?")
    elseif side == "recv" and stt == "accepted" then
        -- with no item ID the addon cannot see it in the bags: the button says it
        nxt, mineTurn = (item > 0) and L("À toi : fabrique l'objet, l'addon le voit tout seul.") or L("À toi : fabrique l'objet, puis clique sur Fabriquée."), true
    elseif side == "recv" and stt == "crafted" then
        nxt, mineTurn = string.format(L("À toi : livre à %s (boîte aux lettres ou échange)."), o.from or "?"), true
    elseif stt == "delivered" then
        nxt = L("Terminée.")
    end
    c.next:SetText(nxt)
    local nc = mineTurn and C.warn or C.dim
    c.next:SetTextColor(nc[1], nc[2], nc[3])
    -- what reached the crafter (read in the crafter's mailbox)
    if side == "recv" and o.status == "accepted" then
        local got, money = O.Received(o)
        local parts, all = {}, true
        for _, g in ipairs(got) do
            parts[#parts + 1] = math.min(g.have, g.need) .. "/" .. g.need .. " " .. Name(g.id)
            if g.have < g.need then all = false end
        end
        local fee = (o.paid or 0)
        if fee > 0 then parts[#parts + 1] = string.format(L("argent %s / %s"), Money(math.min(money, fee)), Money(fee)); if money < fee then all = false end end
        if #parts > 0 then lines[#lines + 1] = string.format(L("Reçu : %s"), all and L("tout est arrivé") or table.concat(parts, ", ")) end
    end
    if o.reason then lines[#lines + 1] = S.Hex(C.danger) .. L(o.reason) .. "|r" end
    if o.note and o.note ~= "" then lines[#lines + 1] = "« " .. o.note .. " »" end
    -- the steps so far, and the last messages between customer and crafter
    if o.log and #o.log > 1 then
        local t = {}
        for _, e in ipairs(o.log) do t[#t + 1] = L(STATUS[e.s] or e.s) .. " " .. date("%H:%M", e.t) end
        lines[#lines + 1] = S.Hex(C.muted) .. table.concat(t, "  >  ") .. "|r"
    end
    for i = math.max(1, #(o.msgs or {}) - 2), #(o.msgs or {}) do
        local m = o.msgs[i]
        lines[#lines + 1] = S.Hex(C.info) .. m.from .. "|r : " .. m.text
    end
    c.detail:SetText(table.concat(lines, "\n"))
    -- buttons by side and status
    c.a1, c.a2 = nil, nil
    c.b1:SetWidth(110); c.b2:SetWidth(110)   -- cards are recycled: some branches widen them
    if side == "board" then
        c.b1.label:SetText(L("Accepter")); c.a1 = function() O.Accept(o); WP.ShowOrdersTab("recv") end
        if o.to then
            -- sent to me: a real refusal, with its reason
            c.b2.label:SetText(L("Refuser")); c.a2 = function() WP.AskDecline(o) end
        else
            -- a guild order: only hidden here, the others still see it
            c.b2.label:SetText(L("Masquer")); c.a2 = function() O.Decline(o, "Autre") end
        end
    elseif side == "recv" and o.status == "open" then
        c.b1.label:SetText(L("Accepter")); c.a1 = function() O.Accept(o) end
        c.b2.label:SetText(L("Refuser")); c.a2 = function() WP.AskDecline(o) end
    elseif side == "recv" and o.status == "accepted" then
        c.b1.label:SetText(L("Fabriquée")); c.a1 = function() O.Crafted(o) end
    elseif side == "recv" and o.status == "crafted" then
        c.b1.label:SetText(L("Livrée")); c.a1 = function() O.Delivered(o) end
    elseif side == "mine" and o.status == "accepted" and #missing > 0 then
        c.b1:SetWidth(170)
        c.b1.label:SetText(string.format(L("Acheter le manquant (%d)"), #missing)); c.a1 = function()
            if not (WP.AuctionHouseOpen and WP.AuctionHouseOpen()) then WP.Print(L("Ouvre l'hôtel des ventes, puis reclique.")); return end
            -- every missing reagent in one chain: the next buy page opens after each purchase
            local q = {}
            for _, g in ipairs(missing) do q[#q + 1] = { id = g.id, qty = g.need - g.have } end
            if WP.Scan and WP.Scan.BuyQueue then WP.Scan.BuyQueue(q)
            elseif WP.Scan and WP.Scan.OpenToBuy then WP.Scan.OpenToBuy(missing[1].id, missing[1].need - missing[1].have) end
        end
        c.b2.label:SetText(L("Annuler")); c.a2 = function() O.Cancel(o) end
    elseif side == "mine" and o.status == "accepted" and toSend then
        c.b1.label:SetText(L("Préparer le courrier")); c.a1 = function()
            if MailFrame and MailFrame:IsShown() then
                if MailFrameTab2 and not (SendMailFrame and SendMailFrame:IsShown()) then MailFrameTab2:Click() end
                O.FillMail(o, "give")
            else WP.Print(string.format(L("Va à une boîte aux lettres, ou échange-les directement avec %s."), o.by or "?")) end
        end
        c.b2.label:SetText(L("Annuler")); c.a2 = function() O.Cancel(o) end
    elseif side == "mine" and (o.status == "open" or o.status == "accepted") then
        c.b2.label:SetText(L("Annuler")); c.a2 = function() O.Cancel(o) end
    elseif side == "mine" and o.status == "crafted" then
        -- by hand when the addon could not see it arrive (an enchant, a mail still in the inbox)
        c.b1.label:SetText(L("J'ai reçu")); c.a1 = function() O.Delivered(o) end
        c.b2:SetWidth(130); c.b2.label:SetText(L("Pourboire +1 po")); c.a2 = function() AddTip(o) end
    elseif side == "mine" and o.status == "delivered" then
        if not o.thanked and o.by then
            c.b1.label:SetText(L("Merci")); c.a1 = function() O.Thank(o) end
        else
            c.b1.label:SetText(L("Recommander")); c.a1 = function() Reorder(o, o.by) end
        end
        c.b2:SetWidth(130); c.b2.label:SetText(L("Pourboire +1 po")); c.a2 = function() AddTip(o) end
    elseif side == "mine" and (o.status == "cancelled" or o.status == "expired" or o.status == "declined") then
        c.b1.label:SetText(L("Recommander")); c.a1 = function() Reorder(o, o.status == "declined" and nil or o.to) end
    end
    -- messages: between the customer and the crafter, once someone took the order
    c.b3:SetShown(o.by ~= nil and (o.status == "accepted" or o.status == "crafted" or o.status == "delivered")
        and (UnitName("player") == o.from or UnitName("player") == o.by))
    c.b1:SetShown(c.a1 ~= nil); c.b2:SetShown(c.a2 ~= nil)
    if not c.a1 and c.a2 then c.b2:ClearAllPoints(); c.b2:SetPoint("BOTTOMLEFT", 10, 8)
    else c.b2:ClearAllPoints(); c.b2:SetPoint("LEFT", c.b1, "RIGHT", 8, 0) end
    local h = 54 + (nxt ~= "" and (c.next:GetStringHeight() or 14) + 4 or 0)
        + math.max(14, c.detail:GetStringHeight() or 14) + ((c.a1 or c.a2 or c.b3:IsShown()) and 40 or 8)
    c:SetHeight(h)
    return h
end

local function BuildOrders(p, key)
    ui[key].list = List(p, -12, 8, OrderCard)
    ui[key].empty = S.Text(ui[key].list.content, 13, C.dim); ui[key].empty:SetPoint("TOPLEFT", 2, -8); ui[key].empty:SetText(L("Aucune commande."))
end
local function RenderOrders(key, list)
    local u = ui[key]
    local y = 0
    for i, o in ipairs(list) do
        local c = u.list.Get(i)
        c:ClearAllPoints(); c:SetPoint("TOPLEFT", 0, -y)
        y = y + PaintOrder(c, o, key) + 10
    end
    u.list.HideFrom(#list + 1)
    u.empty:SetShown(#list == 0)
    u.list.content:SetHeight(math.max(10, y))
end

-- a message on an order (a small box)
local msgBox
function WP.AskMessage(o)
    if not msgBox then
        msgBox = S.Window("WLHelperOrderMsg", 340, 130, L("Message"), nil, nil, nil)
        msgBox.eb = Box(msgBox, 312, 28, false, L("Ton message (120 caractères)"))
        msgBox.eb:SetPoint("TOPLEFT", 14, -52); msgBox.eb:SetMaxLetters(120)
        local send = S.Button(msgBox, L("Envoyer"), 312, 30, "primary", function()
            if msgBox.order then O.Say(msgBox.order, msgBox.eb:GetText()) end
            msgBox.eb:SetText(""); msgBox:Hide()
        end)
        send:SetPoint("TOPLEFT", 14, -88)
        msgBox.eb:SetScript("OnEnterPressed", function() send:Click() end)
    end
    msgBox.order = o
    msgBox.title:SetText(string.format(L("Message · %s"), Name(o)))
    msgBox:Show(); msgBox.eb:SetFocus()
end

-- decline with a reason (a small menu of reasons)
local declineMenu
function WP.AskDecline(o)
    if not declineMenu then
        declineMenu = S.Window("WLHelperDecline", 300, 220, L("Raison du refus"), nil, nil, nil)
        local y = -48
        for _, r in ipairs({ "Commission trop basse", "Pas les composants", "Pas le temps", "Recharge en cours", "Autre" }) do
            local b = S.Button(declineMenu, L(r), 272, 28, "secondary", function()
                if declineMenu.order then O.Decline(declineMenu.order, r) end
                declineMenu:Hide()
            end)
            b:SetPoint("TOP", 0, y); y = y - 32
        end
    end
    declineMenu.order = o
    declineMenu:Show()
end

-- ---------------------------------------------------------------- the window
local function Build()
    win = S.Window("WLHelperOrders", W, H, L("Commandes"), nil, WLWritsDB, "ordersPos")
    tabs = S.Tabs(win, { { "find", L("Artisans") }, { "ask", L("Demander") }, { "board", L("Ouvertes") }, { "mine", L("Mes commandes") }, { "recv", L("Reçues") } },
        function() return current == "new" and "find" or current end, function(k) WP.ShowOrdersTab(k) end, function(k)
            if k == "find" or k == "ask" then return nil end
            if k == "board" then local n = #O.Board(WLWritsDB.ordersBoardMine ~= false); return n > 0 and n or nil end
            local mine, forMe = O.Lists()
            local n = 0
            if k == "recv" then for _, o in ipairs(forMe) do if o.status == "open" then n = n + 1 end end
            else for _, o in ipairs(mine) do if o.status == "accepted" or o.status == "crafted" then n = n + 1 end end end
            return n > 0 and n or nil
        end)
    tabs:SetPoint("TOPLEFT", 1, -39); tabs:SetPoint("TOPRIGHT", -1, -39)
    for _, k in ipairs({ "find", "ask", "new", "board", "mine", "recv" }) do
        local p = CreateFrame("Frame", nil, win)
        p:SetPoint("TOPLEFT", 0, -76); p:SetPoint("BOTTOMRIGHT")
        p:Hide()
        pages[k] = p
    end
    BuildFind(pages.find); BuildAsk(pages.ask); BuildNew(pages.new); BuildOrders(pages.mine, "mine"); BuildOrders(pages.recv, "recv")
    -- the board: the guild's open orders, all of them or only what you make
    ui.board.list = List(pages.board, -50, 8, OrderCard)
    ui.board.empty = S.Text(ui.board.list.content, 13, C.dim); ui.board.empty:SetPoint("TOPLEFT", 2, -8)
    ui.board.empty:SetWidth(W - 2 * PAD - 4); ui.board.empty:SetWordWrap(true)
    local only = S.Switch(pages.board, function() return WLWritsDB.ordersBoardMine ~= false end, function(v) WLWritsDB.ordersBoardMine = v; WP.RefreshOrders() end)
    only:SetPoint("TOPRIGHT", -PAD, -12)
    local ol = S.Text(pages.board, 13, C.text); ol:SetPoint("RIGHT", only, "LEFT", -8, 0); ol:SetText(L("Ce que je sais fabriquer"))
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
    if k == "ask" then askNames = nil end
    for key, p in pairs(pages) do p:SetShown(key == k) end
    win:Show()
    WP.RefreshOrders()
end

function WP.RefreshOrders()
    if WP.RefreshMailPanel then WP.RefreshMailPanel() end
    if not (win and win:IsShown()) then return end
    tabs:Update()
    if current == "find" then RenderFind()
    elseif current == "new" then RenderNew()
    elseif current == "ask" then RenderAsk()
    else
        if current == "board" then
            local list = O.Board(WLWritsDB.ordersBoardMine ~= false)
            RenderOrders("board", list)
            ui.board.empty:SetText(WLWritsDB.ordersBoardMine ~= false and L("Aucune commande ouverte pour ce que tu sais fabriquer. Décoche le filtre pour tout voir.")
                or L("Aucune commande ouverte dans la guilde."))
        else
            local mine, forMe = O.Lists()
            if current == "mine" then RenderOrders("mine", mine) else RenderOrders("recv", forMe) end
        end
    end
end

function WP.ToggleOrders()
    if win and win:IsShown() then win:Hide(); return end
    if WP.ModuleOff and WP.ModuleOff("orders") then return end
    if not win then Build() end
    WP.ShowOrdersTab(current == "new" and "find" or current)
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
local function MailActions()
    local me = UnitName("player")
    local acts = {}
    for _, o in pairs(O.DB().list) do
        if o.from == me and o.status == "accepted" and ((o.give and o.give ~= "") or (o.paid or 0) > 0) and not o.sentGive then
            acts[#acts + 1] = { o = o, kind = "give", label = string.format(L("Envoyer à %s"), o.by or "?") }
        elseif o.by == me and o.status == "crafted" and (o.item or 0) > 0 then
            acts[#acts + 1] = { o = o, kind = "deliver", label = string.format(L("Livrer à %s"), o.from) }
        end
    end
    return acts
end

function WP.RefreshMailPanel()
    if not (MailFrame and MailFrame:IsShown()) then if panel then panel:Hide() end; return end
    local acts = MailActions()
    if #acts == 0 then if panel then panel:Hide() end; return end
    if not panel then
        panel = CreateFrame("Frame", "WLHelperMailOrders", MailFrame)
        panel:SetWidth(260); panel:SetPoint("TOPLEFT", MailFrame, "TOPRIGHT", 6, -20)
        S.Solid(panel, "BACKGROUND", C.bg):SetAllPoints(); S.Border(panel, C.border)
        panel.title = S.Text(panel, 14, C.text, true); panel.title:SetPoint("TOPLEFT", 10, -10); panel.title:SetText(L("Commandes à poster"))
        panel.rows = {}
    end
    for i, a in ipairs(acts) do
        local r = panel.rows[i]
        if not r then
            r = CreateFrame("Frame", nil, panel); r:SetSize(240, 52)
            r.text = S.Text(r, 13, C.text); r.text:SetPoint("TOPLEFT", 0, 0); r.text:SetPoint("RIGHT", 0, 0); r.text:SetJustifyH("LEFT"); r.text:SetWordWrap(false)
            r.btn = S.Button(r, "", 240, 26, "primary", function()
                if MailFrameTab2 and not (SendMailFrame and SendMailFrame:IsShown()) then MailFrameTab2:Click() end
                panel.pending = nil
                local missing = O.FillMail(r.act.o, r.act.kind)
                if not missing then return end
                if #missing > 0 then
                    local t = {}
                    for _, m in ipairs(missing) do t[#t + 1] = m[2] .. "× " .. Name(m[1]) end
                    WP.Print(string.format(L("Manque : %s"), table.concat(t, ", ")))
                    return
                end
                -- noted once this very mail leaves (same recipient), see SendMail below
                panel.pending = r.act
                panel.pendingTo = (r.act.kind == "give" and (r.act.o.by or r.act.o.to) or r.act.o.from)
                WP.Print(L("Courrier prêt : clique sur Envoyer."))
            end)
            r.btn:SetPoint("BOTTOMLEFT", 0, 0)
            panel.rows[i] = r
        end
        r.act = a
        r:SetPoint("TOPLEFT", 10, -34 - (i - 1) * 58)
        r.text:SetText((a.o.qty or 1) .. "× " .. Name(a.o))
        r.btn.label:SetText(a.label)
        r:Show()
    end
    for i = #acts + 1, #panel.rows do panel.rows[i]:Hide() end
    panel:SetHeight(44 + #acts * 58)
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
