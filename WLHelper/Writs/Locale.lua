-- Writs/Locale.lua: the module's text is written in French; this table gives the English for every
-- string. The language is WL Helper's own (its FR/EN button and /wlh lang), the client's by default.
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
    ["Maître de vol, %s"] = "Flight master, %s",
    ["Bateau pour %s"] = "Boat to %s",
    ["Zeppelin pour %s"] = "Zeppelin to %s",
    ["Téléportation : %s"] = "Teleport: %s",
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
    ["  /wlh trade : ouvre ou ferme les Writs"] = "  /wlh trade: open or close the Trading Post",
    ["  /wlh trade gps : lance ou arrête la tournée GPS (writs prêts à rendre)"] = "  /wlh trade gps: start or stop the GPS tour (writs ready to hand in)",
    ["  /wlh trade stop : arrête le GPS"] = "  /wlh trade stop: stop the GPS",
    ["  /wlh trade scan : scanne la liste d'achat à l'HV"] = "  /wlh trade scan: scan the shopping list at the AH",
    ["  /wlh trade reset : oublie les bourses mesurées et la faction"] = "  /wlh trade reset: forget the measured pouches and the faction",
    -- Comptoir window and GPS arrow (v2)
    ["%d rép · %s %.0f, %.0f"] = "%d rep · %s %.0f, %.0f",
    ["%s atteint"] = "%s reached",
    ["%s dans %d rép"] = "%s in %d rep",
    ["%s, %d seul"] = "%s, only %d",
    ["%s, à rendre là-bas"] = "%s, turned in there",
    [", niv. %d+"] = ", lvl %d+",
    ["> Plus tard : %d writs dans des zones trop hautes"] = "> Later: %d writs in zones too high",
    ["Achats"] = "Shopping",
    ["Arrêter la tournée GPS"] = "Stop the GPS tour",
    ["Attends à quai"] = "Wait at the dock",
    ["Au maître de vol"] = "At the flight master",
    ["Aucun writ abordable aujourd'hui : reviens demain, quand ils changent."] = "No affordable writ today: come back tomorrow, when they change.",
    ["Aucun writ en main. Achète ceux de l'onglet Achats, puis ouvre les enveloppes."] = "No writ in hand. Buy those in the Shopping tab, then open the envelopes.",
    ["Aujourd'hui"] = "Today",
    ["Autre continent"] = "Other continent",
    ["Choisis un objectif plus haut dans les options des Writs."] = "Pick a higher goal in the Trading Post options.",
    ["Clic : GPS · Maj-clic : chercher à l'HV"] = "Click: GPS · Shift-click: search the AH",
    ["Clic : acheter à l'HV · Maj-clic : Auctionator"] = "Click: buy at the AH · Shift-click: Auctionator",
    ["Dans tes sacs : %d / %d"] = "In your bags: %d / %d",
    ["Déplace-moi"] = "Move me",
    ["En combat"] = "In combat",
    ["En vente (dernier scan) : %d"] = "Listed (last scan): %d",
    ["Enveloppe %s · objet %s · Coin Pouch -%s"] = "Envelope %s · item %s · Coin Pouch -%s",
    ["Enveloppe : "] = "Envelope: ",
    ["Glisse la flèche où tu veux"] = "Drag the arrow where you want",
    ["Lancer la tournée GPS"] = "Start the GPS tour",
    ["Lancer la téléportation"] = "Cast the teleport",
    ["Objet ou zone"] = "Item or zone",
    ["Tout décocher"] = "Untick all",
    ["Coche les writs que tu veux faire"] = "Tick the writs you want to do",
    ["Sans coche, le plan prend les moins chers pour ton objectif."] = "With nothing ticked, the plan takes the cheapest for your goal.",
    ["%d writs · %s · +%d rép"] = "%d writs · %s · +%d rep",
    ["%s après les Coin Pouch · la liste d'achat suit ta sélection"] = "%s after Coin Pouches · the shopping list follows your pick",
    ["(%d sans prix)"] = "(%d without a price)",
    ["À rendre en %s · %d writs"] = "Turn in at %s · %d writs",
    ["Enveloppe"] = "Envelope",
    ["Scan %d / %d"] = "Scan %d / %d",
    ["%d en banque"] = "%d in the bank",
    ["Options des Writs"] = "Trading Post settings",
    ["Ouvre l'hôtel des ventes pour scanner"] = "Open the auction house to scan",
    ["Ouvre une carte de vol pour aller plus vite"] = "Open a flight map to go faster",
    ["Ouvrir l'enveloppe"] = "Open the envelope",
    ["Parle à %s"] = "Talk to %s",
    ["Plafond de recherche : %s"] = "Search ceiling: %s",
    ["Plus tard, zones trop hautes ou lieu inconnu"] = "Later, zones too high or unknown spot",
    ["Rang"] = "Rank",
    ["Rends les %d writs prêts, achète-en %d de plus."] = "Hand in the %d ready writs, buy %d more.",
    ["Rends tes %d writs et c'est bon."] = "Hand in your %d writs and you're done.",
    ["Rendus aujourd'hui"] = "Turned in today",
    ["Rescanner"] = "Rescan",
    ["Rien à acheter"] = "Nothing to buy",
    ["Scan %d/%d"] = "Scan %d/%d",
    ["Scanner les prix de la liste d'achat"] = "Scan the shopping list prices",
    ["Tes writs suffisent pour l'objectif."] = "Your writs are enough for the goal.",
    ["Ton plan du jour est couvert."] = "Today's plan is covered.",
    ["Tous"] = "All",
    ["Tous les writs"] = "All writs",
    ["Tout est rendu pour aujourd'hui."] = "Everything is turned in for today.",
    ["Téléport. %s"] = "Teleport %s",
    ["Vol pour %s"] = "Flight to %s",
    ["Vol → %s"] = "Fly → %s",
    ["Y aller"] = "Go",
    ["itinéraire indisponible, ligne droite"] = "no route, straight line",
    ["le plus rapide d'ici"] = "fastest from here",
    ["lieu inconnu"] = "unknown spot",
    ["objet manquant"] = "item missing",
    ["ouvre l'HV pour scanner"] = "open the AH to scan",
    ["possédée"] = "owned",
    ["Pour %d writs, qui rapportent %d points de réputation. Clique un objet pour l'acheter à l'HV."] = "For %d writs, worth %d reputation points. Click an item to buy it at the AH.",
    ["Coût"] = "Cost",
    ["Clic : remettre cette zone dans le plan"] = "Click: put this zone back in the plan",
    ["Clic : laisser cette zone de côté (le plan prend d'autres writs)"] = "Click: leave this zone out (the plan takes other writs)",
    ["(exclure)"] = "(leave out)",
    ["Zone exclue : %s · clic pour la remettre"] = "Zone left out: %s · click to put it back",
    ["Ensuite : %s (s'ouvre après l'achat)."] = "Next: %s (opens after the purchase).",
    ["Clic : acheter l'enveloppe et son objet à l'HV · Maj-clic : Auctionator"] = "Click: buy the envelope and its item at the AH · Shift-click: Auctionator",
    ["Prix max pour 100 points"] = "Max price per 100 points",
    ["sans"] = "none",
    ["Writs"] = "Writs",
    ["Faveur du marchand"] = "Merchant's Favor",
    ["prix d'il y a %d min"] = "prices from %d min ago",
    ["prêt"] = "ready",
    ["puis "] = "then ",
    ["rendu"] = "done",
    ["nouveaux writs dans %d h"] = "new writs in %d h",
    ["Retour à l'accueil"] = "Back to home",
    ["Accueil"] = "Home",
    ["Achète %d writs dans l'onglet Achats."] = "Buy %d writs in the Shopping tab.",
    ["rép"] = "rep",
    ["· tu le fabriques"] = "· you craft it",
    ["À faire, le moins cher d'abord"] = "To do, cheapest first",
    ["À rendre maintenant"] = "To hand in now",
    ["Étape %d sur %d"] = "Step %d of %d",
    ["× pour terminer"] = "× to finish",

    -- shared components (Style.lua): tooltips of the icon buttons, banners and inputs
    ["Fermer"] = "Close",
    ["Clic : fermer la fenêtre"] = "Click: close the window",
    ["Clic : revenir à l'accueil"] = "Click: back to Home",
    ["Masquer ce message"] = "Hide this message",
    ["Clic : masquer ce message"] = "Click: hide this message",
    ["Effacer"] = "Clear",
    ["Clic : effacer la recherche"] = "Click: clear the search",
    ["Indisponible en combat"] = "Not available in combat",

    -- /wlh textes (debug: the texts the engine cuts in the open windows)
    ["Texte coupé : 1 dans 1 fenêtre."] = "Truncated text: 1 in 1 window.",
    ["Textes coupés : %d dans 1 fenêtre."] = "Truncated texts: %d in 1 window.",
    ["Textes coupés : %d dans %d fenêtres."] = "Truncated texts: %d in %d windows.",
    ["(1 ligne)"] = "(1 line)",
    ["(%d lignes)"] = "(%d lines)",
    ["(sans limite)"] = "(no limit)",
    ["(limite)"] = "(at limit)",
    ["[%s] %s %dpx %dx%d %s : %s"] = "[%s] %s %dpx %dx%d %s: %s",
    ["Et 1 autre : ferme quelques fenêtres puis relance /wlh textes."] = "And 1 more: close a few windows, then run /wlh texts again.",
    ["Et %d autres : ferme quelques fenêtres puis relance /wlh textes."] = "And %d more: close a few windows, then run /wlh texts again.",
    ["Aucun texte coupé dans les fenêtres ouvertes."] = "No truncated text in the open windows.",
    ["1 fenêtre cachée n'a pas été vérifiée."] = "1 hidden window was not checked.",
    ["%d fenêtres cachées n'ont pas été vérifiées."] = "%d hidden windows were not checked.",
    ["Debug : /wlh textes liste les textes coupés dans les fenêtres ouvertes (ajoute « all » pour voir aussi ceux à la limite)."] = "Debug: /wlh texts lists the cut texts in the open windows (add \"all\" to also see those at the limit).",
}

-- French unless the client is not French; WLWritsDB.lang ("fr" or "en") overrides.
local function English()
    if root.lang then return root.lang ~= "fr" end
    return GetLocale() ~= "frFR"
end

ns.English = English
ns.EN = EN

function ns.L(s)
    if English() then return EN[s] or s end
    return s
end

-- Is this spell known? Forever's client may lack IsPlayerSpell and IsSpellKnown: C_SpellBook first,
-- then the old globals (any of them saying yes is enough; AltClick.lua reads it the same way).
local function Secret(v) return issecretvalue ~= nil and issecretvalue(v) end
function ns.SpellKnown(id)
    if id == nil then return false end
    local SB = C_SpellBook
    for _, f in ipairs({ SB and SB.IsSpellKnown or false, IsPlayerSpell or false, IsSpellKnown or false }) do
        if type(f) == "function" then
            local ok, v = pcall(f, id)
            if ok and not Secret(v) and v then return true end
        end
    end
    return false
end
-- the root's item lookups (Locale.lua), for the Writs files
ns.ItemInfo, ns.ItemCount, ns.ItemIcon, ns.IsEquipped = root.ItemInfo, root.ItemCount, root.ItemIcon, root.IsEquipped
