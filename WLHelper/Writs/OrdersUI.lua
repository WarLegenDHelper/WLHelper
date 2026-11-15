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
    ["Par la poste (bouton Préparer à la boîte aux lettres) ou en échange : l'addon le voit tout seul."] = "By mail (Prepare button at a mailbox) or by trade: the addon sees it on its own.",
    ["envoyés"] = "sent",
    ["Acheter le manquant"] = "Buy what's missing",
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
    ["Merci ★"] = "Thanks ★",
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
    ["Fabriquée"] = "Crafted", ["Livrée"] = "Delivered", ["+ Pourboire"] = "+ Tip",
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
})

local W, H, PAD = 400, 600, 14
local win, tabs, pages, current = nil, nil, {}, "find"
local ui = { find = {}, mine = {}, recv = {}, new = {}, board = {} }

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

-- ---------------------------------------------------------------- page 1: crafters (search)
local function BuildFind(p)
    local f = ui.find
    f.box = Box(p, W - 2 * PAD, 30, false, L("Chercher un objet, ou Maj-clic sur un objet pour le commander"))
    f.box:SetPoint("TOPLEFT", PAD, -12)
    f.box:HookScript("OnTextChanged", function() WP.RefreshOrders() end)
    f.info = S.Text(p, 12, C.dim); f.info:SetPoint("TOPLEFT", PAD, -48); f.info:SetPoint("RIGHT", -PAD, 0)
    f.info:SetJustifyH("LEFT"); f.info:SetWordWrap(false)
    -- your own professions on their own line (up to two lines), so the counts are never cut
    f.mine = S.Text(p, 12, C.dim); f.mine:SetPoint("TOPLEFT", PAD, -64); f.mine:SetPoint("RIGHT", -PAD, 0)
    f.mine:SetJustifyH("LEFT"); f.mine:SetWordWrap(true); if f.mine.SetMaxLines then f.mine:SetMaxLines(2) end
    f.list = List(p, -96, 52, function(parent)
        local r = CreateFrame("Frame", nil, parent)
        r:SetSize(W - 2 * PAD, 40)
        r.bg = S.Solid(r, "BACKGROUND", C.card); r.bg:SetAllPoints(); S.Border(r, C.border)
        r.icon = r:CreateTexture(nil, "ARTWORK"); r.icon:SetSize(22, 22); r.icon:SetPoint("LEFT", 9, 0); r.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        r.name = S.Text(r, 14, C.text); r.name:SetPoint("TOPLEFT", 40, -5); r.name:SetPoint("RIGHT", -96, 0); r.name:SetJustifyH("LEFT"); r.name:SetWordWrap(false)
        r.sub = S.Text(r, 12, C.dim); r.sub:SetPoint("BOTTOMLEFT", 40, 6); r.sub:SetPoint("RIGHT", -96, 0); r.sub:SetJustifyH("LEFT"); r.sub:SetWordWrap(false)
        r.btn = S.Button(r, L("Commander"), 80, 26, "secondary", function()
            if r.item then WP.NewOrder(r.item, r.crafter)
            elseif r.open then ui.find.view = r.open; f.list.sf:SetVerticalScroll(0); WP.RefreshOrders()
            elseif r.whisper and ChatFrame_OpenChat then ChatFrame_OpenChat("/w " .. r.whisper .. " ") end
        end)
        r.btn:SetPoint("RIGHT", -7, 0)
        return r
    end)
    f.empty = S.Text(f.list.content, 13, C.dim); f.empty:SetPoint("TOPLEFT", 2, -8); f.empty:SetWidth(W - 2 * PAD - 4); f.empty:SetWordWrap(true)
    f.back = S.Button(p, L("Tous les artisans"), 130, 24, "secondary", function() f.view = nil; WP.RefreshOrders() end)
    f.back:SetPoint("TOPRIGHT", -PAD, -46); f.back:Hide()
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
    leatherworking = { "Travail du cuir", "Leatherworking", "Interface\\Icons\\INV_Misc_ArmorKit_17" },
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

-- shift-click an item while the search box has the focus: its link goes in the box
if hooksecurefunc and ChatEdit_InsertLink then
    hooksecurefunc("ChatEdit_InsertLink", function(link)
        local box = ui.find and ui.find.box
        if box and box:HasFocus() and type(link) == "string" then box:SetText(link) end
    end)
end

local function RenderFind()
    local f = ui.find
    local q = (f.box:GetText() or ""):lower()
    local crafters, online = 0, 0
    local on = O.OnlineGuild()
    for name in pairs(O.DB().crafters) do crafters = crafters + 1; if on[name] then online = online + 1 end end
    -- what this copy read of your own professions (so you can see that sharing works)
    local mineT = {}
    for prof, p in pairs(O.DB().mine or {}) do
        local n = 0
        for _ in pairs(p.recipes or {}) do n = n + 1 end
        mineT[#mineT + 1] = prof .. " " .. (p.rank or 0) .. " (" .. n .. ")"
    end
    table.sort(mineT)
    f.info:SetText(string.format(L("%d artisans connus · %d en ligne"), crafters, online))
    f.mine:SetText(#mineT > 0 and string.format(L("tes métiers : %s"), table.concat(mineT, ", ")) or L("tes métiers : aucun"))
    local catalog = O.Catalog()
    local rows = {}
    if #q >= 2 then
        for id, prof in pairs(catalog) do
            local n = Name(id):lower()
            if n:find(q, 1, true) then
                for _, c in ipairs(O.Crafters(id)) do rows[#rows + 1] = { item = id, prof = prof, c = c } end
            end
        end
    end
    table.sort(rows, function(a, b)
        if a.item ~= b.item then return Name(a.item) < Name(b.item) end
        if a.c.online ~= b.c.online then return a.c.online end
        return a.c.rank > b.c.rank
    end)
    -- one crafter picked: what they make (when their recipe list arrived)
    if f.view and #q < 2 then
        local v = f.view
        local p = v.me and O.DB().mine[v.prof] or (O.DB().crafters[v.name] or {})[v.prof]
        local items = {}
        for id in pairs(p and p.recipes or {}) do items[#items + 1] = id end
        table.sort(items, function(a, b) return Name(a) < Name(b) end)
        f.back:Show()
        f.mine:SetText(string.format(L("Recettes de %s : %s %d"), v.name, ProfLabel(ProfKey(v.prof), v.prof), p and p.rank or 0))
        local y = 0
        for i, id in ipairs(items) do
            local row = f.list.Get(i)
            row:ClearAllPoints(); row:SetPoint("TOPLEFT", 0, -y)
            row.item, row.crafter, row.whisper, row.open = id, not v.me and v.name or nil, nil, nil
            row.icon:Show(); row.icon:SetTexture(S.ItemIcon(id))
            row.name:SetText(Name(id)); local qc = S.QualityColor(id); row.name:SetTextColor(qc[1], qc[2], qc[3])
            row.sub:SetText(Reagents(O.DB() and (p.recipes[id] or ""), 1))
            row.btn.label:SetText(L("Commander")); row.btn:SetShown(not v.me)
            row.bg:SetColorTexture(C.card[1], C.card[2], C.card[3], 1)
            y = y + 46
            if i >= 150 then break end
        end
        f.list.HideFrom(math.min(#items, 150) + 1)
        f.empty:SetShown(#items == 0)
        f.empty:SetText(L("Ses recettes ne sont pas encore arrivées : elles viennent quand il ouvre sa fenêtre de métier, ou de Mastercraft s'il l'a."))
        f.list.content:SetHeight(math.max(10, y))
        return
    end
    f.back:Hide()
    -- an item link (shift-click an item) or "item:12345": order it from the guild, recipe known or not
    local linked = tonumber((f.box:GetText() or ""):match("item:(%d+)"))
    if linked then
        local row = f.list.Get(1)
        row:ClearAllPoints(); row:SetPoint("TOPLEFT", 0, 0)
        row.item, row.crafter, row.whisper, row.open = linked, nil, nil, nil
        row.icon:Show(); row.icon:SetTexture(S.ItemIcon(linked))
        row.name:SetText(Name(linked)); local qc = S.QualityColor(linked); row.name:SetTextColor(qc[1], qc[2], qc[3])
        local who = O.Possible(linked)
        row.sub:SetText(#who > 0 and string.format(L("%d artisans possibles · Commander : toute la guilde la voit"), #who) or L("personne n'a encore déclaré ce métier : la guilde verra quand même la commande"))
        row.btn.label:SetText(L("Commander")); row.btn:Show()
        row.bg:SetColorTexture(C.brandBg[1], C.brandBg[2], C.brandBg[3], 1)
        -- each possible crafter: exact (shared recipe) or by profession, online first
        local y = 46
        for i, c in ipairs(who) do
            local cr = f.list.Get(i + 1)
            cr:ClearAllPoints(); cr:SetPoint("TOPLEFT", 0, -y)
            cr.item, cr.crafter, cr.whisper, cr.open = linked, c.name, nil, nil
            cr.icon:Hide()
            local stars = O.Stars(c.name)
            cr.name:SetText("   " .. c.name .. (stars > 0 and (" " .. S.Hex(C.warn) .. "★" .. stars .. "|r") or ""))
            cr.name:SetTextColor(C.text[1], C.text[2], C.text[3])
            cr.sub:SetText("   " .. c.prof .. " " .. (c.rank or 0) .. "  ·  " .. (c.online and (S.Hex(C.ready) .. L("en ligne") .. "|r") or L("hors ligne"))
                .. "  ·  " .. (c.exact and L("recette connue") or L("métier compatible")))
            cr.btn.label:SetText(L("À lui")); cr.btn:Show()
            cr.bg:SetColorTexture(C.card[1], C.card[2], C.card[3], 1)
            y = y + 46
            if i >= 30 then break end
        end
        f.list.HideFrom(math.min(#who, 30) + 2)
        f.empty:Hide()
        f.list.content:SetHeight(y + 4)
        return
    end
    -- nothing typed: the guild's crafters, grouped by profession (shared at login, recipes or not)
    if #q < 2 then
        local groups = {}
        local function Add(name, prof, p, me)
            local key = ProfKey(prof) or prof
            groups[key] = groups[key] or {}
            local n = 0
            for _ in pairs(p.recipes or {}) do n = n + 1 end
            table.insert(groups[key], { name = name, prof = prof, rank = p.rank or 0, online = me or on[name] or false, n = n, me = me })
        end
        for name, profs in pairs(O.DB().crafters) do for prof, p in pairs(profs) do Add(name, prof, p) end end
        for prof, p in pairs(O.DB().mine or {}) do Add(UnitName("player"), prof, p, true) end
        local order = {}
        for _, k in ipairs(PROF_ORDER) do if groups[k] then order[#order + 1] = k end end
        for k in pairs(groups) do if not PROFS[k] then order[#order + 1] = k end end
        local y, i = 0, 0
        for _, key in ipairs(order) do
            local members = groups[key]
            table.sort(members, function(a, b)
                if a.online ~= b.online then return a.online end
                return a.rank > b.rank
            end)
            -- the profession's header
            i = i + 1
            local h = f.list.Get(i)
            h:ClearAllPoints(); h:SetPoint("TOPLEFT", 0, -y)
            h.item, h.crafter, h.whisper, h.open = nil, nil, nil, nil
            h.icon:Show(); h.icon:SetTexture(ProfIcon(key))
            h.name:SetText(ProfLabel(key, members[1].prof)); h.name:SetTextColor(C.text[1], C.text[2], C.text[3])
            h.sub:SetText(string.format(L("%d artisans"), #members))
            h.btn:Hide()
            h.bg:SetColorTexture(C.brandBg[1], C.brandBg[2], C.brandBg[3], 1)
            y = y + 46
            for _, c in ipairs(members) do
                i = i + 1
                local row = f.list.Get(i)
                row:ClearAllPoints(); row:SetPoint("TOPLEFT", 0, -y)
                row.item, row.crafter = nil, nil
                row.whisper = (not c.me and c.online) and c.name or nil
                row.open = c.n > 0 and { name = c.name, prof = c.prof, me = c.me } or nil
                row.icon:Hide()
                row.name:SetText("   " .. c.name .. (c.me and (" " .. S.Hex(C.muted) .. L("(toi)") .. "|r") or ""))
                row.name:SetTextColor(C.text[1], C.text[2], C.text[3])
                row.sub:SetText("   " .. c.rank .. "  ·  " .. (c.online and (S.Hex(C.ready) .. L("en ligne") .. "|r") or L("hors ligne"))
                    .. "  ·  " .. (c.n > 0 and string.format(L("%d recettes"), c.n) or L("recettes pas encore partagées")))
                row.btn.label:SetText(c.n > 0 and L("Recettes") or L("Chuchoter"))
                row.btn:SetShown(c.n > 0 or row.whisper ~= nil)
                row.bg:SetColorTexture(C.card[1], C.card[2], C.card[3], 1)
                y = y + 46
            end
            if i >= 200 then break end
        end
        f.list.HideFrom(i + 1)
        f.empty:SetShown(i == 0)
        f.empty:SetText(L("Aucun artisan connu pour l'instant : les membres qui ont WL Helper partagent leurs métiers en se connectant. Tape un objet pour chercher qui le fabrique."))
        f.list.content:SetHeight(math.max(10, y))
        return
    end
    local y = 0
    for i, r in ipairs(rows) do
        local row = f.list.Get(i)
        row:ClearAllPoints(); row:SetPoint("TOPLEFT", 0, -y)
        row.item, row.crafter, row.whisper = r.item, not r.c.me and r.c.name or nil, nil
        row.btn.label:SetText(L("Commander"))
        row.icon:SetTexture(S.ItemIcon(r.item))
        row.name:SetText(Name(r.item)); local qc = S.QualityColor(r.item); row.name:SetTextColor(qc[1], qc[2], qc[3])
        local where = r.c.online and S.Hex(C.ready) .. L("en ligne") .. "|r"
            or (r.c.seen and string.format(L("vu il y a %d j"), math.floor((time() - r.c.seen) / 86400)) or L("hors ligne"))
        row.sub:SetText(r.c.name .. " · " .. r.c.prof .. " " .. (r.c.rank or 0) .. " · " .. where)
        row.btn:SetShown(not r.c.me)
        y = y + 46
        if i >= 60 then break end
    end
    f.list.HideFrom(math.min(#rows, 60) + 1)
    f.empty:SetShown(#rows == 0)
    f.empty:SetText(next(catalog) == nil and L("Aucune recette connue pour l'instant. Chaque membre qui a WL Helper, toi compris, doit ouvrir une fois sa fenêtre de métier pour partager ses recettes.")
        or (#q < 2 and L("Tape au moins 2 lettres.") or ""))
    f.list.content:SetHeight(math.max(10, y))
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

-- ---------------------------------------------------------------- pages 3 and 4: my orders, received
local function OrderCard(parent)
    local c = CreateFrame("Frame", nil, parent)
    c:SetWidth(W - 2 * PAD)
    S.Solid(c, "BACKGROUND", C.card):SetAllPoints(); S.Border(c, C.border)
    c.title = S.Text(c, 15, C.text, true); c.title:SetPoint("TOPLEFT", 10, -8); c.title:SetPoint("RIGHT", -100, 0); c.title:SetJustifyH("LEFT"); c.title:SetWordWrap(false)
    c.fee = S.Text(c, 14, C.warn, true); c.fee:SetPoint("TOPRIGHT", -10, -8); c.fee:SetJustifyH("RIGHT")
    c.who = S.Text(c, 12, C.dim); c.who:SetPoint("TOPLEFT", 10, -28); c.who:SetPoint("RIGHT", -10, 0); c.who:SetJustifyH("LEFT")
    c.detail = S.Text(c, 12, C.text); c.detail:SetPoint("TOPLEFT", 10, -46); c.detail:SetPoint("RIGHT", -10, 0); c.detail:SetJustifyH("LEFT"); c.detail:SetWordWrap(true)
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

local function PaintOrder(c, o, side)
    c.o = o
    c.title:SetText((o.qty or 1) .. "× " .. Name(o.item))
    c.fee:SetText(Money((o.fee or 0) + (o.tip or 0)))
    local col = STATUS_COL[o.status] or C.dim
    local st = S.Hex(col) .. L(STATUS[o.status] or o.status) .. "|r"
    local who
    local function Star(name) local n = name and O.Stars(name) or 0; return n > 0 and (" " .. S.Hex(C.warn) .. "★" .. n .. "|r") or "" end
    if side == "mine" then who = (o.to and string.format(L("pour %s"), o.to) or L("pour la guilde")) .. (o.by and (" · " .. string.format(L("par %s"), o.by) .. Star(o.by)) or "")
    else who = o.from .. " · " .. (o.to and string.format(L("pour %s"), o.to) or L("pour la guilde")) end
    if o.status == "open" and o.expires then who = who .. " · " .. string.format(L("expire dans %d h"), math.max(0, math.floor((o.expires - time()) / 3600))) end
    c.who:SetText(st .. " · " .. who)
    local lines = {}
    local missing = {}
    if side == "mine" and o.status == "accepted" and o.give and o.give ~= "" and not o.sentGive then
        -- what to send to the crafter, with what you have (bags and bank) and what is missing
        local t = {}
        for _, g in ipairs(O.ToSend(o)) do
            local ok = g.have >= g.need
            if not ok then missing[#missing + 1] = g end
            t[#t + 1] = S.Hex(ok and C.ready or C.danger) .. g.need .. "× " .. Name(g.id) .. " (" .. math.min(g.have, g.need) .. "/" .. g.need .. ")|r"
        end
        lines[#lines + 1] = S.Hex(C.text) .. string.format(L("À envoyer à %s :"), o.by or "?") .. "|r " .. table.concat(t, ", ")
        lines[#lines + 1] = S.Hex(C.muted) .. L("Par la poste (bouton Préparer à la boîte aux lettres) ou en échange : l'addon le voit tout seul.") .. "|r"
    elseif o.give and o.give ~= "" then
        local who = side == "mine" and L("je fournis") or string.format(L("%s fournit"), o.from)
        lines[#lines + 1] = S.Hex(C.ready) .. who .. "|r " .. Reagents(o.give, o.qty) .. (o.sentGive and (" · " .. S.Hex(C.ready) .. L("envoyés") .. "|r") or "")
    end
    if o.crafter and o.crafter ~= "" then lines[#lines + 1] = S.Hex(C.warn) .. L("l'artisan fournit") .. "|r " .. Reagents(o.crafter, o.qty) end
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
        lines[#lines + 1] = S.Hex(C.muted) .. table.concat(t, "  ›  ") .. "|r"
    end
    for i = math.max(1, #(o.msgs or {}) - 2), #(o.msgs or {}) do
        local m = o.msgs[i]
        lines[#lines + 1] = S.Hex(C.info) .. m.from .. "|r : " .. m.text
    end
    c.detail:SetText(table.concat(lines, "\n"))
    -- buttons by side and status
    c.a1, c.a2 = nil, nil
    if side == "board" then
        c.b1.label:SetText(L("Accepter")); c.a1 = function() O.Accept(o); WP.ShowOrdersTab("recv") end
        c.b2.label:SetText(L("Masquer")); c.a2 = function() O.Decline(o, "Autre") end
    elseif side == "recv" and o.status == "open" then
        c.b1.label:SetText(L("Accepter")); c.a1 = function() O.Accept(o) end
        c.b2.label:SetText(L("Refuser")); c.a2 = function() WP.AskDecline(o) end
    elseif side == "recv" and o.status == "accepted" then
        c.b1.label:SetText(L("Fabriquée")); c.a1 = function() O.Crafted(o) end
    elseif side == "recv" and o.status == "crafted" then
        c.b1.label:SetText(L("Livrée")); c.a1 = function() O.Delivered(o) end
    elseif side == "mine" and o.status == "accepted" and #missing > 0 then
        c.b1.label:SetText(L("Acheter le manquant")); c.a1 = function()
            if not (WP.AuctionHouseOpen and WP.AuctionHouseOpen()) then WP.Print(L("Ouvre l'hôtel des ventes, puis reclique.")); return end
            local g = missing[1]
            if WP.Scan and WP.Scan.OpenToBuy then WP.Scan.OpenToBuy(g.id, g.need - g.have) end
        end
        c.b2.label:SetText(L("Annuler")); c.a2 = function() O.Cancel(o) end
    elseif side == "mine" and o.status == "accepted" and o.give and o.give ~= "" and not o.sentGive then
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
        c.b2.label:SetText(L("+ Pourboire")); c.a2 = function() O.AddTip(o, 10000); WP.RefreshOrders() end
    elseif side == "mine" and o.status == "delivered" then
        if not o.thanked and o.by then
            c.b1.label:SetText(L("Merci ★")); c.a1 = function() O.Thank(o) end
        else
            c.b1.label:SetText(L("Recommander")); c.a1 = function() WP.NewOrder(o.item, o.by, o) end
        end
        c.b2.label:SetText(L("+ Pourboire")); c.a2 = function() O.AddTip(o, 10000); WP.RefreshOrders() end
    elseif side == "mine" and (o.status == "cancelled" or o.status == "expired" or o.status == "declined") then
        c.b1.label:SetText(L("Recommander")); c.a1 = function() WP.NewOrder(o.item, o.status == "declined" and nil or o.to, o) end
    end
    -- messages: between the customer and the crafter, once someone took the order
    c.b3:SetShown(o.by ~= nil and (o.status == "accepted" or o.status == "crafted" or o.status == "delivered")
        and (UnitName("player") == o.from or UnitName("player") == o.by))
    c.b1:SetShown(c.a1 ~= nil); c.b2:SetShown(c.a2 ~= nil)
    if not c.a1 and c.a2 then c.b2:ClearAllPoints(); c.b2:SetPoint("BOTTOMLEFT", 10, 8)
    else c.b2:ClearAllPoints(); c.b2:SetPoint("LEFT", c.b1, "RIGHT", 8, 0) end
    local h = 54 + math.max(14, (c.detail:GetStringHeight() or 14)) + ((c.a1 or c.a2 or c.b3:IsShown()) and 40 or 8)
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
    msgBox.title:SetText(string.format(L("Message · %s"), Name(o.item)))
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
    tabs = S.Tabs(win, { { "find", L("Artisans") }, { "board", L("Ouvertes") }, { "mine", L("Mes commandes") }, { "recv", L("Reçues") } },
        function() return current == "new" and "find" or current end, function(k) WP.ShowOrdersTab(k) end, function(k)
            if k == "find" then return nil end
            if k == "board" then local n = #O.Board(WLWritsDB.ordersBoardMine ~= false); return n > 0 and n or nil end
            local mine, forMe = O.Lists()
            local n = 0
            if k == "recv" then for _, o in ipairs(forMe) do if o.status == "open" then n = n + 1 end end
            else for _, o in ipairs(mine) do if o.status == "accepted" or o.status == "crafted" then n = n + 1 end end end
            return n > 0 and n or nil
        end)
    tabs:SetPoint("TOPLEFT", 1, -39); tabs:SetPoint("TOPRIGHT", -1, -39)
    for _, k in ipairs({ "find", "new", "board", "mine", "recv" }) do
        local p = CreateFrame("Frame", nil, win)
        p:SetPoint("TOPLEFT", 0, -76); p:SetPoint("BOTTOMRIGHT")
        p:Hide()
        pages[k] = p
    end
    BuildFind(pages.find); BuildNew(pages.new); BuildOrders(pages.mine, "mine"); BuildOrders(pages.recv, "recv")
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
        r.text:SetText((a.o.qty or 1) .. "× " .. Name(a.o.item))
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
