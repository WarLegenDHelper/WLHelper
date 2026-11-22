-- =====================================================================
--  Quest guides: world quest chains that reward something worth the trip (bags, the Elemental
--  Attractor), not tied to a dungeon. Each one is a card in the picker's "Quests" tab: a
--  pseudo-dungeon (cq = "QG", qg = true) whose quests are its chain's last ones, so the route
--  walks the whole chain outside, like the key cards (Writs/Keys.lua).
--  Sources: Wowhead WoW Forever (quest pages and the November 2026 bag news posts), NaowhForever
--  DiscoveryData (givers, turn-ins, objective spots), LibForeverData (objectives, counts), the
--  client's French quest names (via Polestar_frFR).
-- =====================================================================
local _, ns = ...
if not (ns.Q and ns.D and ns.ORDER) then return end
ns.TR = ns.TR or {}

-- ---------------------------------------------------------------- 16 slots: Demon Hide Sack
-- The Fallen Hero of the Horde chain (Swamp of Sorrows, Blasted Lands, Azshara, Stranglethorn)
ns.Q[2784]={n="Fall From Grace",nf="Perte d'honneur",l=50,r=45,fa="Horde",d="QG_DemonSack",role="pre",s={m=1435,x=34.3,y=66.1,n="Fallen Hero of the Horde"},st="Fallen Hero of the Horde",f={m=1435,x=34.2,y=65.4,n="Fallen Hero of the Horde"},ft="Fallen Hero of the Horde",o={{k="event",n="Fallen Hero of the Horde",c=1,ins=false,unk=false,ns=false,w={m=1435,x=34.2,y=65.7,n="Fallen Hero of the Horde"},t={"Fallen Hero of the Horde"}}},xp=470}
ns.Q[2621]={n="The Disgraced One",nf="Le déshonoré",l=50,r=45,fa="Horde",d="QG_DemonSack",role="pre",p={2784},s={m=1435,x=34.3,y=66.1,n="Fallen Hero of the Horde"},st="Fallen Hero of the Horde",f={m=1435,x=47.8,y=55,n="Dispatch Commander Ruag"},ft="Dispatch Commander Ruag",xp=1200}
ns.Q[2622]={n="The Missing Orders",nf="Les ordres disparus",l=50,r=45,fa="Horde",d="QG_DemonSack",role="pre",p={2621},s={m=1435,x=47.8,y=54.9,n="Dispatch Commander Ruag"},st="Dispatch Commander Ruag",f={m=1435,x=45,y=57.2,n="Bengor"},ft="Bengor",xp=1200}
ns.Q[2623]={n="The Swamp Talker",nf="Le Parleur des marécages",l=55,r=45,fa="Horde",d="QG_DemonSack",role="pre",p={2622},s={m=1435,x=45.0,y=57.4,n="Bengor"},st="Bengor",f={m=1435,x=34.2,y=65.4,n="Fallen Hero of the Horde"},ft="Fallen Hero of the Horde",o={{k="item",n="Warchief's Orders",c=1,ins=false,unk=false,ns=false,w={m=1435,x=61.6,y=87.3,n="Swamp Talker"},t={"Swamp Talker"},src={{"Swamp Talker",100}}}},xp=5650}
ns.Q[2783]={n="Petty Squabbles",nf="Querelles mesquines",l=57,r=50,fa="Alliance",d="QG_DemonSack",role="pre",s={m=1419,x=67.6,y=19.3,n="Ambassador Ardalan"},st="Ambassador Ardalan",f={m=1435,x=34.2,y=65.4,n="Fallen Hero of the Horde"},ft="Fallen Hero of the Horde",xp=4500}
ns.Q[2801]={n="A Tale of Sorrow",nf="Une histoire de chagrin",l=57,r=45,fa="Both",d="QG_DemonSack",role="pre",p={2623,2783},s={m=1435,x=34.3,y=66.1,n="Fallen Hero of the Horde"},st="Fallen Hero of the Horde",f={m=1435,x=34.2,y=65.4,n="Fallen Hero of the Horde"},ft="Fallen Hero of the Horde",o={{k="event",n="Fallen Hero of the Horde",c=1,ins=false,unk=false,ns=false,w={m=1435,x=34.2,y=65.7,n="Fallen Hero of the Horde"},t={"Fallen Hero of the Horde"}}},xp=600}
ns.Q[2681]={n="The Stones That Bind Us",nf="Les pierres qui nous lient",l=57,r=45,fa="Both",d="QG_DemonSack",role="pre",p={2801},s={m=1435,x=34.3,y=66.1,n="Fallen Hero of the Horde"},st="Fallen Hero of the Horde",f={m=1435,x=34.2,y=65.4,n="Fallen Hero of the Horde"},ft="Fallen Hero of the Horde",o={{k="kill",n="Servant of Razelikh",c=9,ins=false,unk=false,ns=false,w={m=1419,x=57.7,y=51.1,n="Servant of Razelikh"},t={"Servant of Razelikh"}},{k="kill",n="Servant of Grol",c=3,ins=false,unk=false,ns=false,w={m=1419,x=42.3,y=12.9,n="Servant of Grol"},t={"Servant of Grol"}},{k="kill",n="Servant of Allistarj",c=3,ins=false,unk=false,ns=false,w={m=1419,x=63.9,y=34.4,n="Servant of Allistarj"},t={"Servant of Allistarj"}},{k="kill",n="Servant of Sevine",c=3,ins=false,unk=false,ns=false,w={m=1419,x=42.2,y=40.4,n="Servant of Sevine"},t={"Servant of Sevine"}}},xp=7550}
ns.Q[2702]={n="Heroes of Old",nf="Les héros des Anciens",l=57,r=45,fa="Both",d="QG_DemonSack",role="pre",p={2681},s={m=1435,x=34.3,y=66.1,n="Fallen Hero of the Horde"},st="Fallen Hero of the Horde",f={m=1435,x=33.4,y=66,n="Corporal Thund Splithoof"},ft="Corporal Thund Splithoof",xp=3000}
ns.Q[2701]={n="Heroes of Old",nf="Les héros des Anciens",l=57,r=45,fa="Both",d="QG_DemonSack",role="pre",p={2702},s={m=1435,x=33.4,y=66.0,n="Corporal Thund Splithoof"},st="Corporal Thund Splithoof",f={m=1435,x=33.4,y=66,n="Spectral Lockbox"},ft="Spectral Lockbox",xp=6000}
ns.Q[2721]={n="Kirith",l=58,r=45,fa="Both",d="QG_DemonSack",role="pre",p={2701},s={m=1435,x=34.3,y=66.1,n="Fallen Hero of the Horde"},st="Fallen Hero of the Horde",f={m=1419,x=66.8,y=31.2,n="Spirit of Kirith"},ft="Spirit of Kirith",xp=6200}
ns.Q[2743]={n="The Cover of Darkness",nf="Le couvert de l'obscurité",l=60,r=45,fa="Both",d="QG_DemonSack",role="pre",p={2721},s={m=1419,x=68.4,y=31.2,n="Spirit of Kirith"},st="Spirit of Kirith",f={m=1435,x=34.2,y=65.4,n="Fallen Hero of the Horde"},ft="Fallen Hero of the Horde",xp=3300}
ns.Q[2744]={n="The Demon Hunter",nf="Le chasseur de démons",l=60,r=45,fa="Both",d="QG_DemonSack",role="pre",p={2743},s={m=1435,x=34.3,y=66.1,n="Fallen Hero of the Horde"},st="Fallen Hero of the Horde",f={m=1447,x=60.8,y=66.4,n="Loramus Thalipedes"},ft="Loramus Thalipedes",o={{k="event",n="Loramus Thalipedes",c=1,ins=false,unk=false,ns=false,w={m=1447,x=60.8,y=66.5,n="Loramus Thalipedes"},t={"Loramus Thalipedes"}}},xp=6600}
ns.Q[3141]={n="Loramus",l=57,r=45,fa="Both",d="QG_DemonSack",role="pre",p={2744},s={m=1447,x=60.8,y=66.4,n="Loramus Thalipedes"},st="Loramus Thalipedes",f={m=1447,x=60.8,y=66.4,n="Loramus Thalipedes"},ft="Loramus Thalipedes",o={{k="event",n="Loramus Thalipedes",c=1,ins=false,unk=false,ns=false,w={m=1447,x=60.8,y=66.5,n="Loramus Thalipedes"},t={"Loramus Thalipedes"}}},xp=600}
ns.Q[3508]={n="Breaking the Ward",nf="Briser l'Amulette",l=58,r=45,fa="Both",d="QG_DemonSack",role="pre",p={3141},s={m=1447,x=60.8,y=66.4,n="Loramus Thalipedes"},st="Loramus Thalipedes",f={m=1447,x=60.8,y=66.4,n="Loramus Thalipedes"},ft="Loramus Thalipedes",xp=3100}
ns.Q[3509]={n="The Name of the Beast",nf="Le nom de la bête",l=58,r=45,fa="Both",d="QG_DemonSack",role="pre",p={3508},s={m=1447,x=60.8,y=66.4,n="Loramus Thalipedes"},st="Loramus Thalipedes",f={m=1447,x=77.2,y=42.8,n="Lord Arkkoroc"},ft="Lord Arkkoroc",xp=6200}
ns.Q[3510]={n="The Name of the Beast",nf="Le nom de la bête",l=58,r=45,fa="Both",d="QG_DemonSack",role="pre",p={3509},s={m=1447,x=77.1,y=42.8,n="Lord Arkkoroc"},st="Lord Arkkoroc",f={m=1447,x=77.2,y=42.8,n="Lord Arkkoroc"},ft="Lord Arkkoroc",o={{k="item",n="Hetaera's Beaten Head",c=1,ins=false,unk=false,ns=false,w={m=1447,x=58.1,y=42.5,n="Hetaera"},t={"Hetaera"},src={{"Hetaera",100}}},{k="item",n="Hetaera's Bloodied Head",c=1,ins=false,unk=false,ns=false,w={m=1447,x=58.1,y=42.5,n="Hetaera"},t={"Hetaera"},src={{"Hetaera",100}}},{k="item",n="Hetaera's Bruised Head",c=1,ins=false,unk=false,ns=false,w={m=1447,x=58.1,y=42.5,n="Hetaera"},t={"Hetaera"},src={{"Hetaera",100}}}},xp=6200}
ns.Q[3511]={n="The Name of the Beast",nf="Le nom de la bête",l=58,r=45,fa="Both",d="QG_DemonSack",role="pre",p={3510},s={m=1447,x=77.1,y=42.8,n="Lord Arkkoroc"},st="Lord Arkkoroc",f={m=1447,x=60.8,y=66.4,n="Loramus Thalipedes"},ft="Loramus Thalipedes",xp=3100}
ns.Q[3602]={n="Azsharite",l=58,r=45,fa="Both",d="QG_DemonSack",role="pre",p={3511},s={m=1447,x=60.8,y=66.4,n="Loramus Thalipedes"},st="Loramus Thalipedes",f={m=1447,x=60.8,y=66.4,n="Loramus Thalipedes"},ft="Loramus Thalipedes",o={{k="item",n="Crystallized Azsharite",c=20,ins=false,unk=false,ns=false,w={m=1447,x=54.1,y=82,n="Azsharite Formation"},t={"Azsharite Formation"},src={{"Azsharite Formation",100}}}},xp=7750}
ns.Q[3621]={n="The Formation of Felbane",nf="La Formation de Felbane",l=58,r=45,fa="Both",d="QG_DemonSack",role="pre",p={3602},s={m=1447,x=60.8,y=66.4,n="Loramus Thalipedes"},st="Loramus Thalipedes",f={m=1434,x=50.4,y=20.4,n="Galvan the Ancient"},ft="Galvan the Ancient",xp=4650}
ns.Q[3625]={n="Enchanted Azsharite Fel Weaponry",nf="Armes Fel en Azsharite enchantée",l=58,r=45,fa="Both",d="QG_DemonSack",role="pre",p={3621},s={m=1434,x=50.6,y=20.5,n="Galvan the Ancient"},st="Galvan the Ancient",f={m=1434,x=50.4,y=20.4,n="Galvan the Ancient"},ft="Galvan the Ancient",o={{k="event",n="Galvan the Ancient",c=1,ins=false,unk=false,ns=false,w={m=1434,x=50.5,y=20.5,n="Galvan the Ancient"},t={"Galvan the Ancient"}}},xp=620}
ns.Q[3626]={n="Return to the Blasted Lands",nf="Retour aux Terres foudroyées",l=58,r=45,fa="Both",d="QG_DemonSack",role="pre",p={3625},s={m=1434,x=50.6,y=20.5,n="Galvan the Ancient"},st="Galvan the Ancient",f={m=1435,x=34.2,y=65.4,n="Fallen Hero of the Horde"},ft="Fallen Hero of the Horde",xp=1550}
ns.Q[3627]={n="Uniting the Shattered Amulet",nf="Réunir les morceaux de l'Amulette brisée",l=60,r=45,fa="Both",d="QG_DemonSack",role="pre",p={3626},s={m=1435,x=34.3,y=66.1,n="Fallen Hero of the Horde"},st="Fallen Hero of the Horde",f={m=1435,x=34.2,y=65.4,n="Fallen Hero of the Horde"},ft="Fallen Hero of the Horde",o={{k="item",n="Amulet of Allistarj",c=1,ins=false,unk=false,ns=false,w={m=1419,x=66.3,y=30.9,n="Archmage Allistarj"},t={"Archmage Allistarj"},src={{"Archmage Allistarj",100}}},{k="item",n="Amulet of Grol",c=1,ins=false,unk=false,ns=false,w={m=1419,x=42.9,y=13.8,n="Grol the Destroyer"},t={"Grol the Destroyer"},src={{"Grol the Destroyer",100}}},{k="item",n="Amulet of Sevine",c=1,ins=false,unk=false,ns=false,w={m=1419,x=40.6,y=30.3,n="Lady Sevine"},t={"Lady Sevine"},src={{"Lady Sevine",100}}}},xp=8300}
ns.Q[3628]={n="You Are Rakh'likh, Demon",nf="Vous êtes Rakh'likh, démon",l=60,r=45,fa="Both",d="QG_DemonSack",role="main",noin=true,p={3627},s={m=1435,x=34.3,y=66.1,n="Fallen Hero of the Horde"},st="Fallen Hero of the Horde",f={m=1435,x=34.2,y=65.4,n="Fallen Hero of the Horde"},ft="Fallen Hero of the Horde",o={{k="item",n="Severed Horn of the Defiler",c=1,ins=false,unk=false,ns=false,w={m=1419,x=47.5,y=29.1,n="Razelikh the Defiler"},t={"Razelikh the Defiler"},src={{"Razelikh the Defiler",100}}}},xp=9950}

-- A Tale of Sorrow takes either faction's lead-in: each names the other as its twin
if ns.Q[2623] then ns.Q[2623].tw = 2783 end
if ns.Q[2783] then ns.Q[2783].tw = 2623 end

-- ---------------------------------------------------------------- 16 slots: Red Bag
-- A former Season of Discovery chain, open to every class on Forever (Wowhead news, 19 November 2026)
ns.Q[84135]={n="Beach Bot",l=60,r=55,fa="Both",d="QG_RedBag",role="pre",s={m=1446,x=59.2,y=91.5,n="Half-Buried Mech"},st="Half-Buried Mech",f={m=1446,x=59.2,y=91.5,n="Access Hatch"},ft="Access Hatch",xp=1650,ftask=true}
ns.Q[84137]={n="Mechanical Romance",l=60,r=55,fa="Both",d="QG_RedBag",role="pre",p={84135},s={m=1446,x=59.2,y=91.5,n="Half-Buried Mech"},st="Half-Buried Mech",ft="Sebastian Jurgens",xp=4950,ftask=true}
ns.Q[84138]={n="Frosty Favors",l=60,r=55,fa="Both",d="QG_RedBag",role="pre",p={84137},st="Sebastian Jurgens",f={m=1452,x=61.2,y=37.0,n="Nami"},ft="Nami",xp=4950}
ns.Q[84146]={n="Red Bag Blues",l=60,r=55,fa="Both",d="QG_RedBag",role="main",noin=true,ftask=true,p={84138},s={m=1452,x=61.2,y=37.0,n="Nami"},st="Nami",f={m=1428,x=53.0,y=24.8,n="Red Bag"},ft="Red Bag",ri={"Red Bag"},xp=6600}

-- ---------------------------------------------------------------- 18 slots: Hyjal Postal Satchel
ns.Q[93197]={n="Mending Communications",l=58,r=56,fa="Both",d="QG_Hyjal",role="pre",s={m=2482,x=70.8,y=51.4,n="Sebelia"},st="Sebelia",f={m=1452,x=61.2,y=38.8,n="Innkeeper Vizzie"},ft="Innkeeper Vizzie",xp=3100}
ns.Q[93406]={n="Unfrozen Deliveries",l=56,r=56,fa="Both",d="QG_Hyjal",role="pre",p={93197},s={m=1452,x=61.2,y=38.8,n="Innkeeper Vizzie"},st="Innkeeper Vizzie",f={m=1452,x=61.2,y=38.8,n="Innkeeper Vizzie"},ft="Innkeeper Vizzie",o={{k="item",n="Missing Mail",c=4,ins=false,unk=false,ns=false,w={m=1452,x=55.2,y=33.2,n="Ice Thistle Yeti"},t={"Ice Thistle Yeti"},src={{"Ice Thistle Yeti",100}}}},xp=4350}
ns.Q[93269]={n="Top of the Post",l=58,r=56,fa="Both",d="QG_Hyjal",role="main",noin=true,p={93406},s={m=1452,x=61.2,y=38.8,n="Innkeeper Vizzie"},st="Innkeeper Vizzie",f={m=2482,x=70.8,y=51.4,n="Sebelia"},ft="Sebelia",ri={"Hyjal Postal Satchel","Hyjal Postal Clasp"},xp=620}

-- ---------------------------------------------------------------- Elemental Attractor
-- Earthen Ring (Horde, Mulgore) and its Alliance twin (Alterac Mountains): the Attractor comes with
-- the quest; the motes drop from elite spellcasters while its buff (Magical Awareness) is on
local MOTES = "Use the Elemental Attractor (Magical Awareness) first: motes only drop while it is on. Best spots on Wowhead's drop list: the Blackmaw Hold elites in Azshara (about 30 to 40%), then Blackrock Depths (Anvilrage Medics, Fireguard Destroyers), Lower Blackrock Spire casters and Scholomance."
ns.TR[MOTES] = "Utilise d'abord l'Attracteur élémentaire (Conscience magique) : les granules ne tombent que pendant ce buff. Meilleurs coins d'après Wowhead : les élites de Blackmaw Hold en Azshara (30 à 40 % environ), puis les Profondeurs de Rochenoire (médecins et destructeurs), les lanceurs de sorts du Pic Rochenoire inférieur et Scholomance."
ns.Q[98477]={n="Unstable Magic",l=60,r=48,fa="Horde",d="QG_Attractor",role="main",noin=true,s={m=1412,x=33.5,y=22.7,n="Nuara Tremorhoof"},st="Nuara Tremorhoof",f={m=1412,x=33.4,y=22.4,n="Nuara Tremorhoof"},ft="Nuara Tremorhoof",req={{"Mote of Unstable Magic",10,MOTES}},oe="Bring 10 Motes of Unstable Magic to Nuara Tremorhoof.",ri={"Elemental Attractor"},xp=8300}
ns.Q[96603]={n="Unstable Magic",l=60,r=48,fa="Alliance",d="QG_Attractor",role="main",noin=true,s={m=1416,x=14.2,y=60.0,n="Archmage Celindra"},st="Archmage Celindra",f={m=1416,x=14.2,y=60,n="Archmage Celindra"},ft="Archmage Celindra",req={{"Mote of Unstable Magic",10,MOTES}},oe="Bring 10 Motes of Unstable Magic to Archmage Celindra.",ri={"Elemental Attractor"},xp=8300}

-- ---------------------------------------------------------------- notes (English, French)
-- ---------------------------------------------------------------- Mark of Fordring (neck, BiS for many specs)
-- Tirion Fordring's chain in the Plaguelands (Naowh's BiS: Mark of Fordring, rank 1 for 9 specs):
-- Demon Dogs, Blood Tinged Skies, Carrion Grubbage -> Redemption -> ... -> In Dreams. Givers,
-- turn-ins and objectives from NaowhForever DiscoveryData; the Symbol of Lost Honor's spot from
-- LibForeverData's spawns; French names from the client (Polestar_frFR). The quests our data
-- already has (the Stratholme: Living chain, up to Of Love and Family) are kept as they are: only
-- Find Myranda, Scarlet Subterfuge and In Dreams are new.
if not ns.Q[5542] then ns.Q[5542]={nf="Chiens-démons",n="Demon Dogs",l=56,r=52,fa="Both",d="QG_Fordring",role="pre",s={m=1423,x=5.0,y=35.5,n="Tirion Fordring"},st="Tirion Fordring",f={m=1423,x=7.4,y=43.4,n="Tirion Fordring"},ft="Tirion Fordring",o={{k="kill",n="Plaguehound Runt",c=20,ins=false,unk=false,ns=false,w={m=1423,x=17.1,y=61.8,n="Plaguehound Runt"},t={"Plaguehound Runt"}},{k="kill",n="Plaguehound",c=5,ins=false,unk=false,ns=false,w={m=1423,x=57.7,y=55.3,n="Plaguehound"},t={"Plaguehound"}},{k="kill",n="Frenzied Plaguehound",c=5,ins=false,unk=false,ns=false,w={m=1423,x=41.4,y=18.1,n="Frenzied Plaguehound"},t={"Frenzied Plaguehound"}}},xp=5800} end
if not ns.Q[5543] then ns.Q[5543]={nf="Ciel couleur de sang",n="Blood Tinged Skies",l=56,r=52,fa="Both",d="QG_Fordring",role="pre",s={m=1423,x=5.0,y=35.5,n="Tirion Fordring"},st="Tirion Fordring",f={m=1423,x=7.4,y=43.4,n="Tirion Fordring"},ft="Tirion Fordring",o={{k="kill",n="Plaguebat",c=30,ins=false,unk=false,ns=false,w={m=1423,x=31.8,y=61.4,n="Plaguebat"},t={"Plaguebat"}}},xp=5800} end
if not ns.Q[5544] then ns.Q[5544]={nf="Larve putride",n="Carrion Grubbage",l=56,r=52,fa="Both",d="QG_Fordring",role="pre",s={m=1423,x=5.0,y=35.5,n="Tirion Fordring"},st="Tirion Fordring",f={m=1423,x=7.4,y=43.4,n="Tirion Fordring"},ft="Tirion Fordring",o={{k="item",n="Slab of Carrion Worm Meat",c=15,ins=false,unk=false,ns=false,w={m=1423,x=30.2,y=58,n="Carrion Grub"},t={"Carrion Grub","Carrion Devourer"},src={{"Carrion Grub",100},{"Carrion Devourer",100}}}},xp=5800} end
if not ns.Q[5742] then ns.Q[5742]={nf="Rédemption",n="Redemption",l=56,r=52,fa="Both",d="QG_Fordring",role="pre",p={5542,5543,5544},s={m=1423,x=5.0,y=35.5,n="Tirion Fordring"},st="Tirion Fordring",f={m=1423,x=7.4,y=43.4,n="Tirion Fordring"},ft="Tirion Fordring",o={{k="event",n="Tirion Fordring",c=1,ins=false,unk=false,ns=false,w={m=1423,x=5.1,y=35.4,n="Tirion Fordring"},t={"Tirion Fordring"}}},xp=580} end
if not ns.Q[5781] then ns.Q[5781]={nf="Aux mémoires perdues",n="Of Forgotten Memories",l=57,r=52,fa="Both",d="QG_Fordring",role="pre",p={5742},s={m=1423,x=5.0,y=35.5,n="Tirion Fordring"},st="Tirion Fordring",f={m=1423,x=7.4,y=43.4,n="Tirion Fordring"},ft="Tirion Fordring",o={{k="item",n="Taelan's Hammer",c=1,ins=false,unk=false,ns=false,w={m=1423,x=23.4,y=73.5,n="Mercutio Filthgorger"},t={"Mercutio Filthgorger"},src={{"Mercutio Filthgorger",100}}}},xp=6000} end
if not ns.Q[5845] then ns.Q[5845]={nf="De l'honneur perdu",n="Of Lost Honor",l=58,r=52,fa="Both",d="QG_Fordring",role="pre",p={5781},s={m=1423,x=5.0,y=35.5,n="Tirion Fordring"},st="Tirion Fordring",f={m=1423,x=7.4,y=43.4,n="Tirion Fordring"},ft="Tirion Fordring",o={{k="item",n="Symbol of Lost Honor",c=1,ins=false,unk=false,ns=false,w={m=1423,x=62.5,y=26.8,n="Symbol of Lost Honor"}}},xp=6200} end
if not ns.Q[5846] then ns.Q[5846]={nf="L'amour et la famille",n="Of Love and Family",l=58,r=52,fa="Both",d="QG_Fordring",role="pre",p={5845},s={m=1423,x=5.0,y=35.5,n="Tirion Fordring"},st="Tirion Fordring",f={m=1422,x=65.4,y=75.4,n="Artist Renfray"},ft="Artist Renfray",xp=6200} end
if not ns.Q[5848] then ns.Q[5848]={nf="De l'amour et de la famille",n="Of Love and Family",l=60,r=52,fa="Both",d="QG_Fordring",role="pre",p={5846},s={m=1422,x=65.8,y=75.4,n="Artist Renfray"},st="Artist Renfray",f={m=1423,x=7.4,y=43.4,n="Tirion Fordring"},ft="Tirion Fordring",o={{k="item",n="Of Love and Family",c=1,ins=false,unk=false,ns=true}},xp=6600} end
if not ns.Q[5861] then ns.Q[5861]={nf="Trouver Myranda",n="Find Myranda",l=60,r=52,fa="Both",d="QG_Fordring",role="pre",p={5848},s={m=1423,x=5.0,y=35.5,n="Tirion Fordring"},st="Tirion Fordring",f={m=1422,x=50.8,y=77.8,n="Myranda the Hag"},ft="Myranda the Hag",xp=4950} end
if not ns.Q[5862] then ns.Q[5862]={nf="Le subterfuge écarlate",n="Scarlet Subterfuge",l=60,r=52,fa="Both",d="QG_Fordring",role="pre",p={5861},s={m=1422,x=50.8,y=77.8,n="Myranda the Hag"},st="Myranda the Hag",f={m=1422,x=42,y=14.8,n="Highlord Taelan Fordring"},ft="Highlord Taelan Fordring",xp=6600} end
if not ns.Q[5944] then ns.Q[5944]={nf="En rêves",n="In Dreams",l=60,r=52,fa="Both",d="QG_Fordring",role="main",noin=true,p={5862},s={m=1422,x=42.0,y=14.8,n="Highlord Taelan Fordring"},st="Highlord Taelan Fordring",f={m=1422,x=53.8,y=24.4,n="Lord Tirion Fordring"},ft="Lord Tirion Fordring",ri={"Mark of Fordring"},xp=9950} end

local NOTES = {
  [5542] = { "Start: Tirion Fordring, by his house at the western edge of the Eastern Plaguelands. Take his three quests together (Demon Dogs, Blood Tinged Skies, Carrion Grubbage).",
             "Départ : Tirion Fordring, près de sa maison à l'ouest des Maleterres de l'Est. Prends ses trois quêtes ensemble (Chiens-démons, Ciel couleur de sang, Larve putride)." },
  [5845] = { "The Symbol of Lost Honor is an object in the Eastern Plaguelands.",
             "Le Symbole de l'honneur perdu est un objet dans les Maleterres de l'Est." },
  [5944] = { "The last step happens in Hearthglen (Western Plaguelands), among Scarlet elites: bring a group. Its reward is the Mark of Fordring, a neck many specs rank first.",
             "La dernière étape se passe à Hearthglen (Maleterres de l'Ouest), au milieu d'élites écarlates : viens en groupe. Sa récompense est la Marque de Fordring, un collier que beaucoup de spés classent premier." },
  [2784] = { "Start of the Horde side: the Fallen Hero of the Horde stands in the Swamp of Sorrows, by the road to the Blasted Lands. Alliance players start with Petty Squabbles in the Blasted Lands.",
             "Départ côté Horde : le Héros déchu de la Horde est dans le marais des Chagrins, au bord de la route des Terres foudroyées. L'Alliance commence par Querelles mesquines dans les Terres foudroyées." },
  [2681] = { "The servants are spread over the Blasted Lands.",
             "Les serviteurs sont répartis dans les Terres foudroyées." },
  [3602] = { "The Azsharite Formations are the crystals of southern Azshara.",
             "Les formations d'azsharite sont les cristaux du sud d'Azshara." },
  [3621] = { "Galvan the Ancient is in northern Stranglethorn Vale.",
             "Galvan l'Ancien est dans le nord de la vallée de Strangleronce." },
  [3627] = { "Archmage Allistarj, Grol the Destroyer and Lady Sevine are elites of the Blasted Lands: bring a group.",
             "L'archimage Allistarj, Grol le Destructeur et dame Sevine sont des élites des Terres foudroyées : viens en groupe." },
  [3628] = { "Razelikh the Defiler is an elite of the Blasted Lands: bring a group. The Demon Hide Sack (16 slots) is this quest's reward.",
             "Razelikh le Souilleur est un élite des Terres foudroyées : viens en groupe. Le Sac en peau de démon (16 places) est la récompense de cette quête." },
  [84135] = { "The Half-Buried Mech lies on the far south shore of Tanaris: walk along the shore from about 63, 64. Click it once to take the quest and again to hand it in; it gives the Guided Buoyancy Accelerant (swim speed).",
              "Le Half-Buried Mech est sur la plage tout au sud de Tanaris : longe la côte depuis 63, 64 environ. Clique-le une fois pour prendre la quête, une autre pour la rendre ; elle donne le Guided Buoyancy Accelerant (vitesse de nage)." },
  [84137] = { "Swim south toward the lighthouse with the Accelerant on, then straight to the island past the fatigue line. Keep swimming even when fatigue hurts; it stops before the island. Sebastian Jurgens is on the oil rig's first floor, behind the island.",
              "Nage vers le sud en direction du phare avec l'Accelerant, puis tout droit vers l'île au-delà de la limite de fatigue. Continue même si la fatigue fait mal ; elle s'arrête avant l'île. Sebastian Jurgens est au premier étage de la plateforme pétrolière, derrière l'île." },
  [84138] = { "Nami is in Everlook (Winterspring).",
              "Nami est à Long-Guet (Berceau-de-l'Hiver)." },
  [84146] = { "Walk up the mountain from about 59, 29 in the Burning Steppes to the camp at 53, 25: the quest ends at the Red Bag, and the Red Bag (16 slots) is the reward. Worn, it lowers stealth by 2 (rogues, druids).",
              "Monte la montagne depuis 59, 29 environ dans les steppes Ardentes jusqu'au camp en 53, 25 : la quête se rend au Red Bag, et le Red Bag (16 places) est la récompense. Porté, il baisse le camouflage de 2 (voleurs, druides)." },
  [93197] = { "Sebelia is at the summit camp of Mount Hyjal. Take her parcels to Everlook.",
              "Sebelia est au camp du sommet du mont Hyjal. Apporte ses colis à Long-Guet." },
  [93406] = { "The Missing Mail drops from the Ice Thistle Yetis in the hills north of Everlook.",
              "Le courrier perdu tombe sur les yétis Chardon de glace dans les collines au nord de Long-Guet." },
  [93269] = { "Take the mail back up to Sebelia: the Hyjal Postal Satchel (18 slots) is the reward.",
              "Remonte le courrier à Sebelia : la Sacoche de la poste d’Hyjal (18 places) est la récompense." },
}
-- the Symbol of Lost Honor's spot (LibForeverData spawn), on our existing quest when it has none
do
  local q = ns.Q[5845]
  if q and not q.o then
    q.o = { { k = "item", n = "Symbol of Lost Honor", c = 1, ins = false, unk = false, ns = false,
      w = { m = 1423, x = 62.5, y = 26.8, n = "Symbol of Lost Honor" } } }
  end
end
for id, t in pairs(NOTES) do
  local q = ns.Q[id]
  if q then q.ne = t[1]; ns.TR[t[1]] = t[2] end
end

-- ---------------------------------------------------------------- the cards
local CARDS = {
  { key = "QG_DemonSack", n = "16-slot bag: Demon Hide Sack", nf = "Sac 16 places : Sac en peau de démon",
    lvl = { 55, 60 }, loc = "Swamp of Sorrows, Blasted Lands, Azshara", locf = "Marais des Chagrins, Terres foudroyées, Azshara",
    icon = "Interface\\Icons\\INV_Misc_Bag_10", q = { 3628 },
    ed = "The long Fallen Hero of the Horde chain; its last quest rewards the Demon Hide Sack (16 slots). Elites at the end: bring a group.",
    edf = "La longue chaîne du Héros déchu de la Horde ; sa dernière quête donne le Sac en peau de démon (16 places). Des élites à la fin : viens en groupe." },
  { key = "QG_RedBag", n = "16-slot bag: Red Bag", nf = "Sac 16 places : Red Bag",
    lvl = { 55, 60 }, loc = "Tanaris, Winterspring, Burning Steppes", locf = "Tanaris, Berceau-de-l'Hiver, steppes Ardentes",
    icon = "Interface\\Icons\\INV_Misc_Bag_10_Red", q = { 84146 },
    ed = "A former Season of Discovery chain open to every class: a mech on the Tanaris shore, a swim to an oil rig, Nami in Everlook, then the Red Bag (16 slots) in the Burning Steppes.",
    edf = "Une ancienne chaîne de Season of Discovery ouverte à toutes les classes : un robot sur la plage de Tanaris, une traversée à la nage jusqu'à une plateforme, Nami à Long-Guet, puis le Red Bag (16 places) dans les steppes Ardentes." },
  { key = "QG_Hyjal", n = "18-slot bag: Hyjal Postal Satchel", nf = "Sac 18 places : Sacoche de la poste d’Hyjal",
    lvl = { 56, 60 }, loc = "Mount Hyjal, Winterspring", locf = "Mont Hyjal, Berceau-de-l'Hiver",
    icon = "Interface\\Icons\\INV_Misc_Bag_09", q = { 93269 },
    ed = "Three mail quests between the Mount Hyjal summit camp and Everlook; the last one rewards the Hyjal Postal Satchel (18 slots).",
    edf = "Trois quêtes de courrier entre le camp du sommet du mont Hyjal et Long-Guet ; la dernière donne la Sacoche de la poste d’Hyjal (18 places)." },
  { key = "QG_Attractor", n = "Elemental Attractor", nf = "Attracteur élémentaire",
    lvl = { 48, 60 }, loc = "Mulgore (Horde), Alterac Mountains (Alliance)", locf = "Mulgore (Horde), montagnes d'Alterac (Alliance)",
    icon = "Interface\\Icons\\INV_Elemental_Primal_Mana", q = { 98477, 96603 },
    ed = "Unstable Magic, the Earthen Ring quest that gives the Elemental Attractor: with its buff on, elite spellcasters drop Motes of Unstable Magic. Ten of them complete the quest.",
    edf = "Unstable Magic, la quête du Cercle terrestre qui donne l'Attracteur élémentaire : avec son buff, les lanceurs de sorts élites lâchent des granules de magie instable. Il en faut dix." },
  { key = "QG_Fordring", n = "Neck: Mark of Fordring", nf = "Collier : Marque de Fordring",
    lvl = { 56, 60 }, loc = "Eastern and Western Plaguelands, Stratholme", locf = "Maleterres de l'Est et de l'Ouest, Stratholme",
    icon = "Interface\\Icons\\INV_Jewelry_Talisman_07", q = { 5944 },
    ed = "Tirion Fordring's chain in the Plaguelands (11 quests, Stratholme on the way, a group for the end). Its last quest, In Dreams, rewards the Mark of Fordring: a neck Naowh's simulations rank first for many specs.",
    edf = "La chaîne de Tirion Fordring dans les Maleterres (11 quêtes, Stratholme en chemin, un groupe pour la fin). Sa dernière quête, En rêves, donne la Marque de Fordring : un collier que les simulations de Naowh classent premier pour beaucoup de spés." },
}
ns.QGUIDES = {}
for _, c in ipairs(CARDS) do
  if not ns.D[c.key] then
    ns.D[c.key] = { key = c.key, n = c.n, nf = c.nf, lvl = c.lvl, loc = c.loc, locf = c.locf, icon = c.icon,
      ed = c.ed, cq = "QG", qg = true, q = c.q }
    ns.TR[c.ed] = c.edf
    table.insert(ns.ORDER, c.key)
    ns.QGUIDES[#ns.QGUIDES + 1] = c.key
  end
end
