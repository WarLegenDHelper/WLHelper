-- Writs/PvP.lua: the PvP guide ("/wlh pvp"). What the rare (blue) PvP set costs on WoW Forever and
-- what you still miss for each piece: honour (currency 1792) and battleground marks (items). Prices
-- read on Wowhead WoW Forever (Lady Palanseer's "Sells" tab, 2026-11-17): the "Premier" pieces, item
-- level 60, from level 55, honour plus marks; the "Premier Emboldened" seals (honour only) make a
-- piece epic later, with a PvP rank. Field of Honor: Wizzik Dustfizz in Gadgetzan (Wowhead).
-- The best piece per slot for your spec comes from WL Helper Gear when it is loaded (the same
-- percent as the tooltips); your class's other sets are named after it.
local ADDON, root = ...
local ns = root.Writs
local WP = ns.WP
local L = ns.L

local PvP = {}
WP.PvP = PvP

ns.AddEnglish({
    ["Guide PvP"] = "PvP guide",
    ["Honneur : %s. Marques : %s."] = "Honor: %s. Marks: %s.",
    ["%s : %s, %s honneur + %d %s"] = "%s: %s, %s honor + %d %s",
    ["il te manque %s"] = "you still need %s",
    ["%s honneur"] = "%s honor",
    ["%d marques %s"] = "%d %s marks",
    ["tu peux l'acheter"] = "you can buy it",
    ["déjà à toi"] = "already yours",
    ["Total pour le set : %s honneur, %s."] = "Whole set: %s honor, %s.",
    ["Il te manque en tout : %s."] = "Still missing in all: %s.",
    ["Champ de bataille à faire en premier : %s (%d marques à gagner ; une victoire en donne 3, une défaite 1)."] =
        "Battleground to do first: %s (%d marks to earn; a win gives 3, a loss 1).",
    ["Quête Field of Honor : Wizzik Dustfizz, Gadgetzan (Tanaris 51,8 27,2), niveau 60. Semaine 1 : gagner 10 duels (à deux, chacun gagne 10 fois). Semaine 2 : 3 batailles au Goulet des Chanteguerres. Chaque semaine : 300 honneur et 500 points de rang. /way Tanaris 51,8 27,2 pour y aller."] =
        "Field of Honor quest: Wizzik Dustfizz, Gadgetzan (Tanaris 51.8 27.2), level 60. Week 1: win 10 duels (with a friend, each wins 10). Week 2: 3 Warsong Gulch battles. Each week: 300 honor and 500 rank points. /way Tanaris 51.8 27.2 to go there.",
    ["Plus tard : un sceau « Emboldened » (%s à %s honneur, avec un rang PvP) rend une pièce épique. Garde tes pièces bleues, et enchante-les."] =
        "Later: an \"Emboldened\" seal (%s to %s honor, with a PvP rank) makes a piece epic. Keep your blue pieces, and enchant them.",
    ["Prix lus sur Wowhead Forever (vendeur Lady Palanseer). Survole une pièce chez le vendeur : le pourcentage d'amélioration s'affiche comme partout."] =
        "Prices read on Wowhead Forever (vendor Lady Palanseer). Hover a piece at the vendor: the upgrade percent shows as everywhere.",
    ["Pas de set PvP pour ta classe dans les données."] = "No PvP set for your class in the data.",
    ["Goulet des Chanteguerres"] = "Warsong Gulch",
    ["Bassin d'Arathi"] = "Arathi Basin",
    ["Vallée d'Alterac"] = "Alterac Valley",
    ["Îles Darkspear"] = "Darkspear Islands",
    ["Tête"] = "Head", ["Épaules"] = "Shoulders", ["Torse"] = "Chest", ["Poignets"] = "Wrists",
    ["Mains"] = "Hands", ["Taille"] = "Waist", ["Jambes"] = "Legs", ["Pieds"] = "Feet",
    ["(ou %s)"] = "(or %s)",
})

-- { item id, slot (Wowhead: 1 head, 3 shoulders, 5 chest, 6 waist, 7 legs, 8 feet, 9 wrists, 10 hands),
--   class mask (1 warrior, 2 paladin, 4 hunter, 8 rogue, 16 priest, 64 shaman, 128 mage, 256 warlock,
--   1024 druid), honour, mark item, marks }
PvP.ITEMS = {
    { 272453, 8, 128, 7500, 274895, 10 },  -- Premier Magus Footwraps
    { 272454, 9, 128, 4500, 20558, 10 },  -- Premier Magus Cuffs
    { 272455, 10, 128, 7500, 20558, 10 },  -- Premier Magus Gloves
    { 272456, 6, 128, 6000, 20559, 10 },  -- Premier Magus Belt
    { 272457, 1, 128, 9000, 20560, 15 },  -- Premier Magus Hood
    { 272458, 7, 128, 9000, 20558, 15 },  -- Premier Magus Pants
    { 272459, 5, 128, 9350, 20559, 15 },  -- Premier Magus Robes
    { 272461, 9, 1024, 4500, 20558, 10 },  -- Premier Kodohide Armguards
    { 272462, 8, 1024, 7500, 274895, 10 },  -- Premier Dragonhide Boots
    { 272463, 6, 1024, 6000, 20559, 10 },  -- Premier Dragonhide Waistband
    { 272464, 10, 1024, 7500, 20558, 10 },  -- Premier Kodohide Gauntlets
    { 272465, 9, 8, 4500, 20558, 10 },  -- Premier Shadowhide Armguards
    { 272467, 10, 8, 7500, 20558, 10 },  -- Premier Shadowhide Vices
    { 272468, 6, 8, 6000, 20559, 10 },  -- Premier Shadowhide Girdle
    { 272469, 3, 1024, 6350, 20559, 10 },  -- Premier Dragonhide Spaulders
    { 272470, 7, 1024, 9000, 20558, 15 },  -- Premier Dragonhide Trousers
    { 272471, 1, 1024, 9000, 20560, 15 },  -- Premier Dragonhide Helm
    { 272472, 5, 1024, 9350, 20559, 15 },  -- Premier Dragonhide Breastplate
    { 272473, 5, 8, 9350, 20559, 15 },  -- Premier Shadowhide Hauberk
    { 272474, 1, 8, 9000, 20560, 15 },  -- Premier Shadowhide Headguard
    { 272475, 3, 8, 6350, 20559, 10 },  -- Premier Shadowhide Mantle
    { 272476, 7, 8, 9000, 20558, 15 },  -- Premier Shadowhide Leggings
    { 272477, 8, 1, 7500, 274895, 10 },  -- Premier Mortarplate Boots
    { 272478, 10, 1, 7500, 20558, 10 },  -- Premier Mortarplate Gloves
    { 272479, 5, 1, 9350, 20559, 15 },  -- Premier Mortarplate Armor
    { 272480, 1, 1, 9000, 20560, 15 },  -- Premier Mortarplate Headguard
    { 272481, 7, 1, 9000, 20558, 15 },  -- Premier Mortarplate Legguards
    { 272483, 9, 4, 4500, 20558, 10 },  -- Premier Chain Bracers
    { 272484, 8, 64, 7500, 274895, 10 },  -- Premier Mail Walkers
    { 272485, 10, 64, 7500, 20558, 10 },  -- Premier Linked Grips
    { 272486, 1, 64, 9000, 20560, 15 },  -- Premier Mail Helm
    { 272487, 5, 64, 9350, 20559, 15 },  -- Premier Mail Chestpiece
    { 272488, 7, 64, 9000, 20558, 15 },  -- Premier Linked Leggings
    { 272489, 3, 64, 6350, 20559, 10 },  -- Premier Linked Shoulders
    { 272490, 5, 4, 9350, 20559, 15 },  -- Premier Chain Breastplate
    { 272491, 1, 4, 9000, 20560, 15 },  -- Premier Chain Headguard
    { 272492, 7, 4, 9000, 20558, 15 },  -- Premier Chain Leggings
    { 272494, 6, 4, 6000, 20559, 10 },  -- Premier Chain Girdle
    { 272495, 10, 4, 7500, 20558, 10 },  -- Premier Chain Gauntlets
    { 272496, 8, 4, 7500, 274895, 10 },  -- Premier Chain Boots
    { 272497, 9, 64, 4500, 20558, 10 },  -- Premier Linked Wristguards
    { 272548, 5, 256, 9350, 20559, 15 },  -- Premier Felweave Robe
    { 272549, 3, 256, 6350, 20559, 10 },  -- Premier Felweave Shoulders
    { 272550, 6, 256, 6000, 20559, 10 },  -- Premier Felweave Belt
    { 272551, 9, 256, 4500, 20558, 10 },  -- Premier Felweave Bracers
    { 272552, 8, 256, 7500, 274895, 10 },  -- Premier Felweave Boots
    { 272553, 10, 256, 7500, 20558, 10 },  -- Premier Felweave Gloves
    { 272562, 1, 16, 9000, 20560, 15 },  -- Premier Satin Cowl
    { 272563, 7, 16, 9000, 20558, 15 },  -- Premier Satin Trousers
    { 272564, 5, 16, 9350, 20559, 15 },  -- Premier Satin Vestments
    { 272565, 3, 16, 6350, 20559, 10 },  -- Premier Satin Shoulderpads
    { 272566, 6, 16, 6000, 20559, 10 },  -- Premier Satin Sash
    { 272567, 9, 16, 4500, 20558, 10 },  -- Premier Satin Cuffs
    { 272568, 8, 16, 7500, 274895, 10 },  -- Premier Satin Boots
    { 272569, 10, 16, 7500, 20558, 10 },  -- Premier Satin Gloves
    { 272579, 9, 1, 4500, 20558, 10 },  -- Premier Mortarplate Bracers
    { 272582, 9, 1024, 4500, 20558, 10 },  -- Premier Dragonhide Armguards
    { 272606, 8, 1024, 7500, 274895, 10 },  -- Premier Kodohide Treads
    { 272608, 8, 8, 7500, 274895, 10 },  -- Premier Shadowhide Walkers
    { 272609, 8, 64, 7500, 274895, 10 },  -- Premier Linked Greaves
    { 272611, 8, 16, 7500, 274895, 10 },  -- Premier Silken Walkers
    { 272614, 10, 1024, 7500, 20558, 10 },  -- Premier Dragonhide Grips
    { 272617, 10, 64, 7500, 20558, 10 },  -- Premier Mail Vices
    { 272619, 10, 16, 7500, 20558, 10 },  -- Premier Silken Handwraps
    { 272625, 5, 64, 9350, 20559, 15 },  -- Premier Linked Hauberk
    { 272626, 5, 1024, 9350, 20559, 15 },  -- Premier Kodohide Chestpiece
    { 272627, 7, 1024, 9000, 20558, 15 },  -- Premier Kodohide Leggings
    { 272630, 7, 256, 9000, 20558, 15 },  -- Premier Felweave Legguards
    { 272634, 5, 16, 9350, 20559, 15 },  -- Premier Silken Tunic
    { 272636, 7, 64, 9000, 20558, 15 },  -- Premier Mail Legguards
    { 272637, 3, 1, 6350, 20559, 10 },  -- Premier Mortarplate Shoulders
    { 272640, 3, 4, 6350, 20559, 10 },  -- Premier Chain Shoulders
    { 272641, 1, 1024, 9000, 20560, 15 },  -- Premier Kodohide Headguard
    { 272642, 3, 1024, 6350, 20559, 10 },  -- Premier Kodohide Shoulders
    { 272643, 1, 256, 9000, 20560, 15 },  -- Premier Felweave Cowl
    { 272647, 1, 64, 9000, 20560, 15 },  -- Premier Linked Headguard
    { 272648, 3, 64, 6350, 20559, 10 },  -- Premier Mail Pauldrons
    { 272649, 1, 16, 9000, 20560, 15 },  -- Premier Silken Hood
    { 272650, 3, 16, 6350, 20559, 10 },  -- Premier Silken Mantle
    { 272663, 7, 16, 9000, 20558, 15 },  -- Premier Silken Legguards
    { 272680, 3, 128, 6350, 20559, 10 },  -- Premier Magus Mantle
    { 273324, 6, 1, 6000, 20559, 10 },  -- Premier Mortarplate Girdle
    { 273352, 6, 64, 6000, 20559, 10 },  -- Premier Linked Girdle
    { 273353, 9, 64, 4500, 20558, 10 },  -- Premier Mail Wristguards
    { 273355, 8, 64, 7500, 274895, 10 },  -- Premier Ringmail Walkers
    { 273356, 1, 64, 9000, 20560, 15 },  -- Premier Ringmail Helm
    { 273357, 5, 64, 9350, 20559, 15 },  -- Premier Ringmail Chestpiece
    { 273358, 10, 64, 7500, 20558, 10 },  -- Premier Ringmail Vices
    { 273359, 7, 64, 9000, 20558, 15 },  -- Premier Ringmail Legguards
    { 273360, 3, 64, 6350, 20559, 10 },  -- Premier Ringmail Pauldrons
    { 273361, 9, 64, 4500, 20558, 10 },  -- Premier Ringmail Wristguards
    { 273362, 6, 64, 6000, 20559, 10 },  -- Premier Ringmail Girdle
    { 273367, 6, 1024, 6000, 20559, 10 },  -- Premier Kodohide Waistband
    { 273372, 6, 64, 6000, 20559, 10 },  -- Premier Mail Girdle
    { 273381, 9, 1024, 4500, 20558, 10 },  -- Premier Wyrmhide Armguards
    { 273382, 10, 1024, 7500, 20558, 10 },  -- Premier Wyrmhide Gauntlets
    { 273383, 8, 1024, 7500, 274895, 10 },  -- Premier Wyrmhide Treads
    { 273384, 5, 1024, 9350, 20559, 15 },  -- Premier Wyrmhide Chestpiece
    { 273385, 7, 1024, 9000, 20558, 15 },  -- Premier Wyrmhide Leggings
    { 273386, 1, 1024, 9000, 20560, 15 },  -- Premier Wyrmhide Headguard
    { 273387, 3, 1024, 6350, 20559, 10 },  -- Premier Wyrmhide Shoulders
    { 273388, 6, 1024, 6000, 20559, 10 },  -- Premier Wyrmhide Waistband
    { 273450, 9, 16, 4500, 20558, 10 },  -- Premier Silken Cuffs
    { 274226, 8, 2, 7500, 274895, 10 },  -- Premier Scaled Sabatons
    { 274227, 10, 2, 7500, 20558, 10 },  -- Premier Scaled Gauntlets
    { 274228, 6, 2, 6000, 20559, 10 },  -- Premier Scaled Cinch
    { 274229, 9, 2, 4500, 20558, 10 },  -- Premier Scaled Armsplints
    { 274230, 5, 2, 9350, 20559, 15 },  -- Premier Scaled Breastplate
    { 274231, 1, 2, 9000, 20560, 15 },  -- Premier Scaled Headguard
    { 274232, 7, 2, 9000, 20558, 15 },  -- Premier Scaled Leggings
    { 274233, 3, 2, 6350, 20559, 10 },  -- Premier Scaled Shoulders
    { 274244, 5, 2, 9350, 20559, 15 },  -- Premier Lamellar Breastplate
    { 274245, 7, 2, 9000, 20558, 15 },  -- Premier Lamellar Leggings
    { 274246, 1, 2, 9000, 20560, 15 },  -- Premier Lamellar Headguard
    { 274247, 3, 2, 6350, 20559, 10 },  -- Premier Lamellar Shoulders
    { 274256, 10, 2, 7500, 20558, 10 },  -- Premier Lamellar Gauntlets
    { 274257, 9, 2, 4500, 20558, 10 },  -- Premier Lamellar Armsplints
    { 274258, 8, 2, 7500, 274895, 10 },  -- Premier Lamellar Sabatons
    { 274259, 6, 2, 6000, 20559, 10 },  -- Premier Lamellar Cinch
    { 275437, 6, 16, 6000, 20559, 10 },  -- Premier Silken Sash
}
-- the pieces' English names (Wowhead Forever), shown until the game has the item in its cache
PvP.NAMES = {
    [272453] = "Premier Magus Footwraps",
    [272454] = "Premier Magus Cuffs",
    [272455] = "Premier Magus Gloves",
    [272456] = "Premier Magus Belt",
    [272457] = "Premier Magus Hood",
    [272458] = "Premier Magus Pants",
    [272459] = "Premier Magus Robes",
    [272461] = "Premier Kodohide Armguards",
    [272462] = "Premier Dragonhide Boots",
    [272463] = "Premier Dragonhide Waistband",
    [272464] = "Premier Kodohide Gauntlets",
    [272465] = "Premier Shadowhide Armguards",
    [272467] = "Premier Shadowhide Vices",
    [272468] = "Premier Shadowhide Girdle",
    [272469] = "Premier Dragonhide Spaulders",
    [272470] = "Premier Dragonhide Trousers",
    [272471] = "Premier Dragonhide Helm",
    [272472] = "Premier Dragonhide Breastplate",
    [272473] = "Premier Shadowhide Hauberk",
    [272474] = "Premier Shadowhide Headguard",
    [272475] = "Premier Shadowhide Mantle",
    [272476] = "Premier Shadowhide Leggings",
    [272477] = "Premier Mortarplate Boots",
    [272478] = "Premier Mortarplate Gloves",
    [272479] = "Premier Mortarplate Armor",
    [272480] = "Premier Mortarplate Headguard",
    [272481] = "Premier Mortarplate Legguards",
    [272483] = "Premier Chain Bracers",
    [272484] = "Premier Mail Walkers",
    [272485] = "Premier Linked Grips",
    [272486] = "Premier Mail Helm",
    [272487] = "Premier Mail Chestpiece",
    [272488] = "Premier Linked Leggings",
    [272489] = "Premier Linked Shoulders",
    [272490] = "Premier Chain Breastplate",
    [272491] = "Premier Chain Headguard",
    [272492] = "Premier Chain Leggings",
    [272494] = "Premier Chain Girdle",
    [272495] = "Premier Chain Gauntlets",
    [272496] = "Premier Chain Boots",
    [272497] = "Premier Linked Wristguards",
    [272548] = "Premier Felweave Robe",
    [272549] = "Premier Felweave Shoulders",
    [272550] = "Premier Felweave Belt",
    [272551] = "Premier Felweave Bracers",
    [272552] = "Premier Felweave Boots",
    [272553] = "Premier Felweave Gloves",
    [272562] = "Premier Satin Cowl",
    [272563] = "Premier Satin Trousers",
    [272564] = "Premier Satin Vestments",
    [272565] = "Premier Satin Shoulderpads",
    [272566] = "Premier Satin Sash",
    [272567] = "Premier Satin Cuffs",
    [272568] = "Premier Satin Boots",
    [272569] = "Premier Satin Gloves",
    [272579] = "Premier Mortarplate Bracers",
    [272582] = "Premier Dragonhide Armguards",
    [272606] = "Premier Kodohide Treads",
    [272608] = "Premier Shadowhide Walkers",
    [272609] = "Premier Linked Greaves",
    [272611] = "Premier Silken Walkers",
    [272614] = "Premier Dragonhide Grips",
    [272617] = "Premier Mail Vices",
    [272619] = "Premier Silken Handwraps",
    [272625] = "Premier Linked Hauberk",
    [272626] = "Premier Kodohide Chestpiece",
    [272627] = "Premier Kodohide Leggings",
    [272630] = "Premier Felweave Legguards",
    [272634] = "Premier Silken Tunic",
    [272636] = "Premier Mail Legguards",
    [272637] = "Premier Mortarplate Shoulders",
    [272640] = "Premier Chain Shoulders",
    [272641] = "Premier Kodohide Headguard",
    [272642] = "Premier Kodohide Shoulders",
    [272643] = "Premier Felweave Cowl",
    [272647] = "Premier Linked Headguard",
    [272648] = "Premier Mail Pauldrons",
    [272649] = "Premier Silken Hood",
    [272650] = "Premier Silken Mantle",
    [272663] = "Premier Silken Legguards",
    [272680] = "Premier Magus Mantle",
    [273324] = "Premier Mortarplate Girdle",
    [273352] = "Premier Linked Girdle",
    [273353] = "Premier Mail Wristguards",
    [273355] = "Premier Ringmail Walkers",
    [273356] = "Premier Ringmail Helm",
    [273357] = "Premier Ringmail Chestpiece",
    [273358] = "Premier Ringmail Vices",
    [273359] = "Premier Ringmail Legguards",
    [273360] = "Premier Ringmail Pauldrons",
    [273361] = "Premier Ringmail Wristguards",
    [273362] = "Premier Ringmail Girdle",
    [273367] = "Premier Kodohide Waistband",
    [273372] = "Premier Mail Girdle",
    [273381] = "Premier Wyrmhide Armguards",
    [273382] = "Premier Wyrmhide Gauntlets",
    [273383] = "Premier Wyrmhide Treads",
    [273384] = "Premier Wyrmhide Chestpiece",
    [273385] = "Premier Wyrmhide Leggings",
    [273386] = "Premier Wyrmhide Headguard",
    [273387] = "Premier Wyrmhide Shoulders",
    [273388] = "Premier Wyrmhide Waistband",
    [273450] = "Premier Silken Cuffs",
    [274226] = "Premier Scaled Sabatons",
    [274227] = "Premier Scaled Gauntlets",
    [274228] = "Premier Scaled Cinch",
    [274229] = "Premier Scaled Armsplints",
    [274230] = "Premier Scaled Breastplate",
    [274231] = "Premier Scaled Headguard",
    [274232] = "Premier Scaled Leggings",
    [274233] = "Premier Scaled Shoulders",
    [274244] = "Premier Lamellar Breastplate",
    [274245] = "Premier Lamellar Leggings",
    [274246] = "Premier Lamellar Headguard",
    [274247] = "Premier Lamellar Shoulders",
    [274256] = "Premier Lamellar Gauntlets",
    [274257] = "Premier Lamellar Armsplints",
    [274258] = "Premier Lamellar Sabatons",
    [274259] = "Premier Lamellar Cinch",
    [275437] = "Premier Silken Sash",
}
-- the seals that make a piece epic later: { item id, honour }
PvP.SEALS = {
    { 275229, 2250 },  -- Premier Emboldened Shoulder Seal
    { 275238, 2650 },  -- Premier Emboldened Chest Seal
    { 275239, 2250 },  -- Premier Emboldened Hands Seal
    { 275240, 1200 },  -- Premier Emboldened Wrist Seal
    { 275241, 2650 },  -- Premier Emboldened Head Seal
    { 275242, 2650 },  -- Premier Emboldened Legs Seal
    { 275243, 1500 },  -- Premier Emboldened Feet Seal
    { 275244, 1500 },  -- Premier Emboldened Belt Seal
}
PvP.HONOR = 1792
PvP.MARKS = {
    [20558] = "Goulet des Chanteguerres",
    [20559] = "Bassin d'Arathi",
    [20560] = "Vallée d'Alterac",
    [274895] = "Îles Darkspear",
}
local SLOT_ORDER = { 1, 3, 5, 9, 10, 6, 7, 8 }
local SLOT_WORD = { [1] = "Tête", [3] = "Épaules", [5] = "Torse", [9] = "Poignets", [10] = "Mains", [6] = "Taille", [7] = "Jambes", [8] = "Pieds" }
local CLASS_BIT = { WARRIOR = 1, PALADIN = 2, HUNTER = 4, ROGUE = 8, PRIEST = 16, SHAMAN = 64, MAGE = 128, WARLOCK = 256, DRUID = 1024 }

local function Plain(v)
    if v == nil or (issecretvalue and issecretvalue(v)) then return nil end
    return v
end
local function Int(n)
    n = math.floor(tonumber(n) or 0)
    local s = tostring(n)
    local sep = (GetLocale and GetLocale() == "frFR") and "\194\160" or ","
    while true do
        local k
        s, k = s:gsub("^(%d+)(%d%d%d)", "%1" .. sep .. "%2")
        if k == 0 then break end
    end
    return s
end
PvP.Int = Int

function PvP.Honor()
    local C = C_CurrencyInfo
    if not (C and C.GetCurrencyInfo) then return 0 end
    local ok, info = pcall(C.GetCurrencyInfo, PvP.HONOR)
    if not ok or type(info) ~= "table" then return 0 end
    return tonumber(Plain(info.quantity)) or 0
end
function PvP.Count(item)
    local f = (C_Item and C_Item.GetItemCount) or GetItemCount
    if not f then return 0 end
    local ok, n = pcall(f, item, true)
    return ok and tonumber(Plain(n)) or 0
end
local function Name(id, fallback)
    local n
    if C_Item and C_Item.GetItemNameByID then
        local ok, v = pcall(C_Item.GetItemNameByID, id)
        if ok then n = Plain(v) end
    end
    if type(n) ~= "string" and GetItemInfo then
        local ok, v = pcall(GetItemInfo, id)
        if ok then n = Plain(v) end
    end
    if type(n) ~= "string" and C_Item and C_Item.RequestLoadItemDataByID then pcall(C_Item.RequestLoadItemDataByID, id) end
    return type(n) == "string" and n or fallback
end
-- WL Helper Gear's percent for the piece (nil when Gear is off or the item is not read yet)
local function Pct(id)
    local G = _G.WLHelperGear
    if not (G and G.Compare) then return nil end
    local ok, r = pcall(G.Compare, id)
    if not ok or type(r) ~= "table" then return nil end
    if r.empty then return 999 end
    return tonumber(r.pct)
end

-- Your class's pieces per slot: { [slot] = { pick = row, pct, others = { rows } } }, the pick being
-- the best by Gear's percent (else the first set)
function PvP.Plan(cls)
    local bit = CLASS_BIT[cls or ""]
    if not bit then return nil end
    local by = {}
    for _, r in ipairs(PvP.ITEMS) do
        if r[3] == bit then
            by[r[2]] = by[r[2]] or {}
            table.insert(by[r[2]], r)
        end
    end
    local plan = {}
    for slot, rows in pairs(by) do
        local best, bestP
        for _, r in ipairs(rows) do
            local p = Pct(r[1])
            if p and (not bestP or p > bestP) then best, bestP = r, p end
        end
        best = best or rows[1]
        local others = {}
        for _, r in ipairs(rows) do if r ~= best then others[#others + 1] = r end end
        plan[slot] = { pick = best, pct = bestP, others = others }
    end
    return plan
end

-- The set as data (the battlegrounds window draws it): { honor, have = { [mark] = n },
-- rows = { { slot, word, id, honor, mark, marks, pct, owned, others = { ids } } } in slot order,
-- needH, needM = { [mark] = n } (what the pieces not owned cost in all), first, firstN (the
-- battleground with the most marks still missing) }. nil without a set for the class.
PvP.SLOT_ORDER, PvP.SLOT_WORD = SLOT_ORDER, SLOT_WORD
function PvP.Data(cls)
    if not cls then local _, c = UnitClass("player"); cls = Plain(c) end
    local plan = PvP.Plan(cls)
    if not plan or not next(plan) then return nil end
    local d = { honor = PvP.Honor(), have = {}, rows = {}, needH = 0, needM = {} }
    for id in pairs(PvP.MARKS) do d.have[id] = PvP.Count(id) end
    for _, slot in ipairs(SLOT_ORDER) do
        local e = plan[slot]
        if e then
            local r = e.pick
            local others = {}
            for _, o in ipairs(e.others) do others[#others + 1] = o[1] end
            local owned = PvP.Count(r[1]) > 0
            d.rows[#d.rows + 1] = { slot = slot, word = SLOT_WORD[slot], id = r[1], honor = r[4], mark = r[5], marks = r[6],
                pct = (e.pct and e.pct < 999) and e.pct or nil, owned = owned, others = others }
            if not owned then d.needH = d.needH + r[4]; d.needM[r[5]] = (d.needM[r[5]] or 0) + r[6] end
        end
    end
    local worst = 0
    for id, n in pairs(d.needM) do
        local m = n - (d.have[id] or 0)
        if m > worst then d.first, d.firstN, worst = id, m, m end
    end
    return d
end

-- The lines "/wlh pvp" prints
function PvP.Lines()
    local out = {}
    local _, cls = UnitClass("player")
    local plan = PvP.Plan(Plain(cls))
    local honor = PvP.Honor()
    local have, marks = {}, {}
    for id, word in pairs(PvP.MARKS) do
        have[id] = PvP.Count(id)
        marks[#marks + 1] = string.format("%s %d", L(word), have[id])
    end
    table.sort(marks)
    out[#out + 1] = string.format(L("Honneur : %s. Marques : %s."), Int(honor), table.concat(marks, ", "))
    if not plan or not next(plan) then out[#out + 1] = L("Pas de set PvP pour ta classe dans les données."); return out end
    local needH, needM, totH, totM = 0, {}, 0, {}
    for _, slot in ipairs(SLOT_ORDER) do
        local e = plan[slot]
        if e then
            local r = e.pick
            local name = Name(r[1], "?")
            local owned = PvP.Count(r[1]) > 0
            local line = string.format(L("%s : %s, %s honneur + %d %s"), L(SLOT_WORD[slot]), name, Int(r[4]), r[6], L(PvP.MARKS[r[5]] or "?"))
            if e.pct and e.pct < 999 then line = line .. string.format(" (%+d %%)", math.floor(e.pct + 0.5)) end
            if #e.others > 0 then
                local alt = {}
                for _, o in ipairs(e.others) do alt[#alt + 1] = Name(o[1], "?") end
                line = line .. " " .. string.format(L("(ou %s)"), table.concat(alt, ", "))
            end
            totH = totH + r[4]; totM[r[5]] = (totM[r[5]] or 0) + r[6]
            if owned then line = line .. " - " .. L("déjà à toi")
            else
                needH = needH + r[4]; needM[r[5]] = (needM[r[5]] or 0) + r[6]
                local miss = {}
                local h = r[4] - honor
                if h > 0 then miss[#miss + 1] = string.format(L("%s honneur"), Int(h)) end
                local m = r[6] - (have[r[5]] or 0)
                if m > 0 then miss[#miss + 1] = string.format(L("%d marques %s"), m, L(PvP.MARKS[r[5]] or "?")) end
                line = line .. " - " .. (#miss > 0 and string.format(L("il te manque %s"), table.concat(miss, ", ")) or L("tu peux l'acheter"))
            end
            out[#out + 1] = line
        end
    end
    local function MarkList(t)
        local parts = {}
        for id, n in pairs(t) do parts[#parts + 1] = string.format(L("%d marques %s"), n, L(PvP.MARKS[id] or "?")) end
        table.sort(parts)
        return table.concat(parts, ", ")
    end
    out[#out + 1] = string.format(L("Total pour le set : %s honneur, %s."), Int(totH), MarkList(totM))
    local missAll, worst, worstN = {}, nil, 0
    if needH - honor > 0 then missAll[#missAll + 1] = string.format(L("%s honneur"), Int(needH - honor)) end
    for id, n in pairs(needM) do
        local m = n - (have[id] or 0)
        if m > 0 then
            missAll[#missAll + 1] = string.format(L("%d marques %s"), m, L(PvP.MARKS[id] or "?"))
            if m > worstN then worst, worstN = id, m end
        end
    end
    table.sort(missAll)
    if #missAll > 0 then out[#out + 1] = string.format(L("Il te manque en tout : %s."), table.concat(missAll, ", ")) end
    if worst then
        out[#out + 1] = string.format(L("Champ de bataille à faire en premier : %s (%d marques à gagner ; une victoire en donne 3, une défaite 1)."), L(PvP.MARKS[worst]), worstN)
    end
    out[#out + 1] = L("Quête Field of Honor : Wizzik Dustfizz, Gadgetzan (Tanaris 51,8 27,2), niveau 60. Semaine 1 : gagner 10 duels (à deux, chacun gagne 10 fois). Semaine 2 : 3 batailles au Goulet des Chanteguerres. Chaque semaine : 300 honneur et 500 points de rang. /way Tanaris 51,8 27,2 pour y aller.")
    local lo, hi
    for _, s in ipairs(PvP.SEALS) do lo = math.min(lo or s[2], s[2]); hi = math.max(hi or s[2], s[2]) end
    if lo then
        out[#out + 1] = string.format(L("Plus tard : un sceau « Emboldened » (%s à %s honneur, avec un rang PvP) rend une pièce épique. Garde tes pièces bleues, et enchante-les."), Int(lo), Int(hi))
    end
    out[#out + 1] = L("Prix lus sur Wowhead Forever (vendeur Lady Palanseer). Survole une pièce chez le vendeur : le pourcentage d'amélioration s'affiche comme partout.")
    return out
end

function PvP.Show()
    WP.Print(L("Guide PvP"))
    for _, l in ipairs(PvP.Lines()) do WP.Print(l) end
end
