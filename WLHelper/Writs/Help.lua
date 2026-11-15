-- Writs/Help.lua: the quick start guide. One window that says, module by module, what WL Helper
-- does, with a button that opens each one. From the home page (its own tile), /wlh aide, and the
-- end of the welcome window.
local ADDON, root = ...
root.Writs = root.Writs or {}
local ns = root.Writs
local WP = ns.WP
local L = ns.L
local S = ns.S
local C = S.C

local W, H, PAD = 470, 600, 14

-- { icon, title, text, open }
local function Sections()
    return {
        { "Interface\\Icons\\INV_Misc_Map_01", L("Guide de quêtes"),
          L("Choisis un ou plusieurs donjons, raids ou quêtes de classe : l'addon calcule la route depuis ta position, prend les quêtes dans le bon ordre et te guide étape par étape. Bouton « Prêt ? » : la check-list avant d'entrer. Partage les quêtes au groupe en un clic."),
          function() if root.ShowPicker then root.ShowPicker() end end },
        { "Interface\\Icons\\INV_Misc_Spyglass_03", L("GPS et flèche"),
          L("Une flèche te montre la direction, la distance et le meilleur trajet : vols, zeppelins, bateaux et téléportations compris. Le bouton GPS d'une étape la suit ; un clic sur le bouton de téléportation lance le sort."),
          nil },
        { "Interface\\Icons\\INV_Letter_15", L("Writs"),
          L("Les Craftsman's Writs pour la réputation : l'addon choisit les moins chers à l'hôtel des ventes, fait la liste d'achats (une ligne par writ, enveloppe et objet ensemble) et la tournée de remise la plus courte."),
          function() WP.Open("writs") end },
        { "Interface\\Icons\\INV_Crate_04", L("Faveur du marchand"),
          L("Ce que coûtent les caisses de faveur et quoi acheter pour monter au prochain palier, au meilleur prix."),
          function() WP.Open("favor") end },
        { "Interface\\Icons\\INV_Misc_Bag_08", L("Sacs"),
          L("Trouve les objets de quête qui ne servent plus. Sacs pleins : « Libérer une place » jette en un clic l'objet gris le moins cher. Les objets gris se vendent tout seuls chez les marchands."),
          function() if WP.Cleaner then WP.Cleaner.Toggle() end end },
        { "Interface\\Icons\\INV_Misc_Note_01", L("Commandes"),
          L("Demande un objet à fabriquer : les artisans de la guilde le voient, le premier qui accepte le prend. L'addon te dit quoi lui envoyer, peut acheter les composants qui manquent, prépare le courrier et voit tout seul l'échange et la livraison."),
          function() if WP.ToggleOrders then WP.ToggleOrders() end end },
        { "Interface\\Icons\\INV_BannerPVP_01", L("Guilde"),
          L("Toute la guilde : recherche, tri par niveau, classe ou rôle, où sont les gens. Clic : chuchoter, clic droit : inviter. Classement PvP de la semaine et de la saison."),
          function() if WP.ToggleGuild then WP.ToggleGuild() end end },
        { "Interface\\Icons\\Ability_Warrior_BattleShout", L("Groupes"),
          L("Prévois un donjon ou un raid avec la guilde : date, rôles, inscriptions, rappel et invitations automatiques. « Groupe maintenant » : dis ce que tu cherches, la guilde le voit."),
          function() if WP.ToggleEvents then WP.ToggleEvents() end end },
        { "Interface\\Icons\\INV_Chest_Cloth_17", L("Améliorations"),
          L("Une flèche verte sur les objets meilleurs que les tiens, dans les sacs, chez les marchands et en récompense de quête, avec le gain en % dans l'infobulle. Choisis ta spé dans ses réglages."),
          function() if WP.ShowOptionsPage then WP.ShowOptionsPage("upgrades") end end },
        { "Interface\\Icons\\Trade_Engineering", L("Réglages"),
          L("Allume ou éteins chaque module, choisis la langue, la police et les clics (tir à la baguette au clic droit, désactivé par défaut)."),
          function() if WP.OpenOptions then WP.OpenOptions("general") end end },
    }
end

ns.AddEnglish({
    ["Guide de démarrage"] = "Quick start guide",
    ["Ce que fait WL Helper, module par module."] = "What WL Helper does, module by module.",
    ["Ouvrir"] = "Open",
    ["GPS et flèche"] = "GPS and arrow",
    ["Réglages"] = "Settings",
    ["Commandes"] = "Orders",
    ["Groupes"] = "LFG",
    ["Guilde"] = "Guild",
    ["Sacs"] = "Bags",
    ["Améliorations"] = "Upgrades",
    ["Writs"] = "Writs",
    ["Faveur du marchand"] = "Merchant's Favor",
    ["Guide de quêtes"] = "Quest guide",
    ["Tout est dans /wlh : /wlh aide pour revoir ce guide."] = "Everything is in /wlh: /wlh help shows this guide again.",
    ["Que fait l'addon ?"] = "What does the addon do?",
    ["Clic : le guide de démarrage"] = "Click: the quick start guide",
    ["Choisis un ou plusieurs donjons, raids ou quêtes de classe : l'addon calcule la route depuis ta position, prend les quêtes dans le bon ordre et te guide étape par étape. Bouton « Prêt ? » : la check-list avant d'entrer. Partage les quêtes au groupe en un clic."] =
        "Pick one or more dungeons, raids or class quests: the addon works out the route from where you stand, takes the quests in the right order and guides you step by step. \"Ready?\" button: the check-list before you go in. Share the quests with your group in one click.",
    ["Une flèche te montre la direction, la distance et le meilleur trajet : vols, zeppelins, bateaux et téléportations compris. Le bouton GPS d'une étape la suit ; un clic sur le bouton de téléportation lance le sort."] =
        "An arrow shows the direction, the distance and the best way: flights, zeppelins, boats and teleports included. A step's GPS button follows it; a click on the teleport button casts the spell.",
    ["Les Craftsman's Writs pour la réputation : l'addon choisit les moins chers à l'hôtel des ventes, fait la liste d'achats (une ligne par writ, enveloppe et objet ensemble) et la tournée de remise la plus courte."] =
        "Craftsman's Writs for reputation: the addon picks the cheapest at the auction house, makes the shopping list (one line per writ, envelope and item together) and the shortest turn-in tour.",
    ["Ce que coûtent les caisses de faveur et quoi acheter pour monter au prochain palier, au meilleur prix."] =
        "What the favor crates cost and what to buy to reach the next rank, at the best price.",
    ["Trouve les objets de quête qui ne servent plus. Sacs pleins : « Libérer une place » jette en un clic l'objet gris le moins cher. Les objets gris se vendent tout seuls chez les marchands."] =
        "Finds the quest items you no longer need. Bags full: \"Free a slot\" throws away the cheapest grey item in one click. Grey items sell by themselves at merchants.",
    ["Demande un objet à fabriquer : les artisans de la guilde le voient, le premier qui accepte le prend. L'addon te dit quoi lui envoyer, peut acheter les composants qui manquent, prépare le courrier et voit tout seul l'échange et la livraison."] =
        "Ask for an item to be crafted: the guild's crafters see it, the first who accepts takes it. The addon tells you what to send, can buy the missing reagents, prepares the mail and sees the trade and the delivery on its own.",
    ["Toute la guilde : recherche, tri par niveau, classe ou rôle, où sont les gens. Clic : chuchoter, clic droit : inviter. Classement PvP de la semaine et de la saison."] =
        "The whole guild: search, sort by level, class or role, where people are. Click: whisper, right-click: invite. PvP ranking of the week and the season.",
    ["Prévois un donjon ou un raid avec la guilde : date, rôles, inscriptions, rappel et invitations automatiques. « Groupe maintenant » : dis ce que tu cherches, la guilde le voit."] =
        "Plan a dungeon or a raid with the guild: date, roles, sign-ups, reminder and automatic invites. \"Group now\": say what you are looking for, the guild sees it.",
    ["Une flèche verte sur les objets meilleurs que les tiens, dans les sacs, chez les marchands et en récompense de quête, avec le gain en % dans l'infobulle. Choisis ta spé dans ses réglages."] =
        "A green arrow on items better than yours, in your bags, at merchants and in quest rewards, with the gain in % in the tooltip. Pick your spec in its settings.",
    ["Allume ou éteins chaque module, choisis la langue, la police et les clics (tir à la baguette au clic droit, désactivé par défaut)."] =
        "Turn each module on or off, pick the language, the font and the clicks (wand shot on right-click, off by default).",
})

local win
local function Build()
    win = S.Window("WLHelperHelp", W, H, L("Guide de démarrage"), nil, WLWritsDB, "helpPos")
    local intro = S.Text(win, 13, C.dim)
    intro:SetPoint("TOPLEFT", PAD, -38 - 12); intro:SetPoint("RIGHT", -PAD, 0); intro:SetJustifyH("LEFT")
    intro:SetText(L("Ce que fait WL Helper, module par module."))

    local sf = CreateFrame("ScrollFrame", nil, win)
    sf:SetPoint("TOPLEFT", PAD, -38 - 36); sf:SetPoint("BOTTOMRIGHT", -PAD, 40)
    local content = CreateFrame("Frame", nil, sf)
    content:SetWidth(W - 2 * PAD); content:SetHeight(10)
    sf:SetScrollChild(content)
    sf:EnableMouseWheel(true)
    sf:SetScript("OnMouseWheel", function(self, d)
        local max = math.max(0, content:GetHeight() - self:GetHeight())
        self:SetVerticalScroll(math.max(0, math.min(max, self:GetVerticalScroll() - d * 60)))
    end)

    local y = 0
    for _, sec in ipairs(Sections()) do
        local card = CreateFrame("Frame", nil, content)
        card:SetPoint("TOPLEFT", 0, -y); card:SetPoint("RIGHT", content, "RIGHT", 0, 0)
        S.Solid(card, "BACKGROUND", C.card):SetAllPoints()
        S.Border(card, C.border)
        local ic = card:CreateTexture(nil, "ARTWORK"); ic:SetSize(32, 32); ic:SetPoint("TOPLEFT", 10, -10)
        ic:SetTexture(sec[1]); ic:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        local t = S.Text(card, 15, C.text, true); t:SetPoint("TOPLEFT", 52, -10); t:SetText(sec[2])
        local body = S.Text(card, 12, C.dim)
        body:SetPoint("TOPLEFT", 52, -32); body:SetWidth(W - 2 * PAD - 52 - 12)
        body:SetJustifyH("LEFT"); body:SetWordWrap(true); body:SetSpacing(2)
        body:SetText(sec[3])
        local h = 32 + math.ceil(body:GetStringHeight() or 30) + 12
        if sec[4] then
            local b = S.Button(card, L("Ouvrir"), 80, 22, "secondary", function() win:Hide(); sec[4]() end)
            b:SetPoint("TOPRIGHT", -10, -8)
            t:SetPoint("RIGHT", b, "LEFT", -8, 0); t:SetJustifyH("LEFT"); t:SetWordWrap(false)
        end
        card:SetHeight(math.max(56, h))
        y = y + math.max(56, h) + 8
    end
    content:SetHeight(y)

    local foot = S.Text(win, 12, C.muted)
    foot:SetPoint("BOTTOMLEFT", PAD, 14); foot:SetPoint("RIGHT", -PAD, 0); foot:SetJustifyH("LEFT")
    foot:SetText(L("Tout est dans /wlh : /wlh aide pour revoir ce guide."))
end

WP.Help = {
    Toggle = function()
        if win and win:IsShown() then win:Hide(); return end
        if not win then Build() end
        win:Show()
    end,
}
