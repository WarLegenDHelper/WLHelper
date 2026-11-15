-- Writs/Locale.lua: the module's text is written in French; this table gives the English for every
-- string. The language is WL Helper's own (its FR/EN button and /wl lang), the client's by default.
local ADDON, root = ...
-- The Writs module of WL Helper keeps its own table inside the addon's namespace.
root.Writs = root.Writs or {}
local ns = root.Writs

local EN = {
    -- reputation and tiers
    ["Neutre"] = "Neutral", ["Amical"] = "Friendly", ["Honoré"] = "Honored", ["Révéré"] = "Revered", ["Exalté"] = "Exalted",
    ["Compagnon"] = "Journeyman",
    -- money
    ["%.2f po"] = "%.2fg", ["%d pa"] = "%ds", ["%d pc"] = "%dc",
    -- price sources
    ["Instantané"] = "Snapshot", ["aucun prix"] = "no price",
    -- chat messages
    ["Auctionator n'est pas chargé."] = "Auctionator is not loaded.",
    ["tout est déjà acheté."] = "everything is already bought.",
    ["liste Auctionator « WL Helper » créée (%d objets, avec prix plafond)."] = "Auctionator list \"WL Helper\" created (%d items, with price ceilings).",
    ["ouvre l'hôtel des ventes d'abord."] = "open the auction house first.",
    ["lieu de remise inconnu pour "] = "turn-in spot unknown for ",
    ["impossible de poser un point sur cette carte."] = "can't place a waypoint on this map.",
    ["rien à chercher."] = "nothing to search.",
    ["mesures de bourse et faction réinitialisées."] = "Coin Pouch samples and faction reset.",
    -- table
    ["État"] = "State", ["Objet demandé"] = "Requested item", ["Remise"] = "Turn-in", ["Rép"] = "Rep",
    ["Writ"] = "Writ", ["Objet"] = "Item", ["Net"] = "Net", ["/100 rép"] = "/100 rep",
    ["Rendu"] = "Turned in", ["Prêt"] = "Ready", ["Objet manquant"] = "Item missing", ["Dans le sac"] = "In bags",
    ["> À acheter"] = "> To buy", ["possédé"] = "owned", ["acheté"] = "bought",
    ["%d writs affichés"] = "%d writs shown",
    -- row tooltip
    ["%s · %d de réputation · %s"] = "%s · %d reputation · %s",
    [", vu il y a %d j"] = ", seen %d d ago",
    ["Coin Pouch (estimée)"] = "Coin Pouch (estimated)",
    ["Coût net"] = "Net cost",
    ["Tu sais fabriquer cet objet (Mastercraft)."] = "You can craft this item (Mastercraft).",
    ["Remise : %s %.1f, %.1f"] = "Turn in: %s %.1f, %.1f",
    ["Zone prévue pour le niveau %d+"] = "Zone meant for level %d+",
    ["Lieu de remise inconnu : ouvre l'enveloppe pour voir la quête."] = "Turn-in spot unknown: open the envelope to see the quest.",
    
    ["Maj-clic : chercher writ + objet à l'HV (Auctionator)"] = "Shift-click: search writ + item at the AH (Auctionator)",
    -- shopping list
    ["Liste d'achat"] = "Shopping list",
    ["Clic : chercher cet objet à l'HV · se coche quand il est dans tes sacs"] = "Click: search this item at the AH · ticks itself once it is in your bags",
    ["Rien à acheter : ton plan est couvert."] = "Nothing to buy: your plan is covered.",
    ["+%d autres"] = "+%d more",
    ["Reste %d objets ~ %s   ·   %d achetés"] = "%d items left ~ %s   ·   %d bought",
    ["Dans tes sacs"] = "In your bags", ["Prix attendu"] = "Expected price", ["Plafond de recherche"] = "Search ceiling",
    ["Le writ lui-même"] = "The writ itself", ["Pour "] = "For ",
    ["Liste Auctionator"] = "Auctionator list",
    ["max "] = "max ",
    -- header and summary
    ["Réputation des comptoirs"] = "Trade company rep",
    ["   ·   %s dans %d de réputation"] = "   ·   %s in %d reputation",
    ["Faction introuvable : ouvre l'onglet Réputation une fois (touche U)."] = "Faction not found: open the Reputation tab once (U key).",
    ["Prêts : |cff59f273%d rép|r   ·   Déjà possédés : %d rép"] = "Ready: |cff59f273%d rep|r   ·   Already owned: %d rep",
    ["   ·   |cff59f273Rien à acheter : ce que tu as suffit|r"] = "   ·   |cff59f273Nothing to buy: what you have is enough|r",
    ["   ·   Plan : |cffffd200%d writs|r pour %s net"] = "   ·   Plan: |cffffd200%d writs|r for %s net",
    ["Zones à visiter : "] = "Zones to visit: ",
    ["   ·   Reset dans %d h %02d"] = "   ·   Reset in %d h %02d",
    ["Coin Pouch ~ %s (%d mesures)"] = "Coin Pouch ~ %s (%d samples)",
    ["Coin Pouch ~ %s (estimation, ouvre une bourse pour mesurer)"] = "Coin Pouch ~ %s (estimate, open a pouch to measure it)",
    ["Prix : %s%s, sinon instantané TSM du %s   ·   blanc = Auctionator récent, jaune pâle = 2 j+, gris = instantané"] =
        "Prices: %s%s, else TSM snapshot of %s   ·   white = recent Auctionator, pale yellow = 2 d+, grey = snapshot",
    -- filters and buttons
    ["Masquer zones trop hautes"] = "Hide zones too high", ["Masquer lieu inconnu"] = "Hide unknown spot",
    ["Masquer rendus aujourd'hui"] = "Hide turned in today",
    ["Objectif : rang suivant"] = "Goal: next standing", ["Objectif : %s"] = "Goal: %s",
   
    
    
    -- own scan and buying
    ["scan terminé : %d objets, %d en vente."] = "scan done: %d items, %d for sale.",
    ["un scan est déjà en cours."] = "a scan is already running.",
    ["le scan n'est pas disponible sur ce client."] = "scanning is not available on this client.",
    ["pas en vente (scan)"] = "not for sale (scan)",
    ["scan, %d en vente"] = "scan, %d for sale",
    ["À rendre à %s"] = "Turn in to %s",
    ["absent"] = "none listed",
    ["%d en vente"] = "%d for sale",
    ["En vente (dernier scan)"] = "Listed (last scan)",
    ["Clic : acheter à l'HV · Maj-clic : Auctionator · se coche une fois dans tes sacs"] = "Click: buy at the AH · Shift-click: Auctionator · ticks once in your bags",
    ["Rescanner la liste"] = "Rescan the list",
    ["Rescan à l'ouverture de l'HV"] = "Rescan when the AH opens",
    ["Scanner les prix (HV)"] = "Scan prices (AH)",
    ["Scan %d/%d (arrêter)"] = "Scan %d/%d (stop)",
    ["Absent"] = "Not listed",
    ["Prix : scan%s%s, sinon instantané TSM du %s   ·   turquoise = scan, blanc = Auctionator récent, jaune pâle = 2 j+, gris = instantané, rouge = pas en vente"] =
        "Prices: scan%s%s, else TSM snapshot of %s   ·   teal = scan, white = recent Auctionator, pale yellow = 2 d+, grey = snapshot, red = not listed",
    ["Coin Pouch (mesurée)"] = "Coin Pouch (measured)",
    ["Coin Pouch : "] = "Coin Pouch: ",
    ["   (? = estimation, ouvre une bourse pour mesurer)"] = "   (? = estimate, open a pouch to measure it)",
    -- route and GPS
    ["GPS tournée"] = "GPS tour", ["GPS : arrêter"] = "GPS: stop",
    ["GPS : aucun writ prêt à rendre, tournée terminée."] = "GPS: no writ ready to hand in, tour done.",
    ["GPS : %s, %s %.0f %.0f%s (%d à rendre)%s"] = "GPS: %s, %s %.0f %.0f%s (%d to hand in)%s",
    [" · ouvre l'enveloppe d'abord"] = " · open the envelope first",
    ["oui"] = "yes", ["non"] = "no",
    -- GPS
    ["Clic : GPS jusqu'au PNJ"] = "Click: GPS to the NPC",
    ["Va au maître de vol : %s"] = "Go to the flight master: %s",
    ["Va au bateau pour %s"] = "Go to the boat to %s",
    ["Va au zeppelin pour %s"] = "Go to the zeppelin to %s",
    ["Va à %s"] = "Go to %s",
    ["Prends le vol pour %s"] = "Take the flight to %s",
    ["Prends le bateau pour %s"] = "Take the boat to %s",
    ["Prends le zeppelin pour %s"] = "Take the zeppelin to %s",
    ["Lance Téléportation : %s"] = "Cast Teleport: %s",
    ["Lancer : %s"] = "Cast: %s",
    ["Prendre le vol : %s"] = "Take the flight: %s",
    ["Ensuite : "] = "Then: ",
    ["Tu y es"] = "You are there",
    ["autre continent ou instance"] = "other continent or instance",
    ["%d m"] = "%d yd",
    ["~%d min"] = "~%d min",
    ["ouvre une carte de vol une fois : le GPS apprendra tes points de vol."] = "open a flight map once: the GPS will learn your flight paths.",
    -- commands
    ["commandes :"] = "commands:",
    ["  /writs : ouvre ou ferme la fenêtre"] = "  /writs: open or close the window",
    ["  /writs gps : lance ou arrête la tournée GPS (writs prêts à rendre)"] = "  /writs gps: start or stop the GPS tour (writs ready to hand in)",
    ["  /writs stop : arrête le GPS"] = "  /writs stop: stop the GPS",
    ["  /writs scan : scanne la liste d'achat à l'HV"] = "  /writs scan: scan the shopping list at the AH",
    ["  /writs reset : oublie les bourses mesurées et la faction"] = "  /writs reset: forget the measured pouches and the faction",
}

-- French unless the client is not French; WLWritsDB.lang ("fr" or "en") overrides.
local function English()
    if root.lang then return root.lang ~= "fr" end
    return GetLocale() ~= "frFR"
end

ns.English = English

function ns.L(s)
    if English() then return EN[s] or s end
    return s
end
