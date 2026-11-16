-- Writs/Transports.lua: when the zeppelins and boats leave (WP.Transports, also GPS.Transports).
-- Each ship of Route.lua's LINKS runs one fixed cycle: it leaves side A, crosses (rideAB), waits at
-- side B (DWELL), crosses back (rideBA), waits at side A, and so on. Knowing one moment of that cycle
-- (the "anchor": a time the ship leaves side A, in server time) gives every departure.
-- Where the anchor comes from, best first:
--   "naowh"     NaowhForever_QoL's live ship timings, read at each call through _G.NaowhForever
--               (TransportTimes.Next), when that addon is loaded and has a usable timing;
--   "synced"    our own: an arrival this character saw (stood at a dock, then reached the other end
--               in about one crossing), or one a guild mate saw and shared; newest wins;
--   "estimated" nothing known: the router keeps the old flat AVERAGE for the whole link and the
--               arrow says "~2 min (estimé)".
-- The cycle facts (crossing times, period, 60 s at each dock) are the timed facts published by
-- NauticusClassic (MIT); nothing here comes from NaowhForever's code or data.
-- Guild sharing: "S|<link id>|<anchor>" on our own prefix, only for what we saw ourselves, at most one
-- per link every 60 s (sent and taken); a share from the future, too old, for an unknown ship, or one
-- that contradicts a fresh observation of our own is dropped.
-- Other timer addons: ForeverTransport ("FTrans2") and NauticusClassic / NauticusClassicResurrected
-- ("NauticSync", MIT) share timings over addon messages; we read their public wire formats with our own
-- parser (the same checks as a guild share) and, standing at a dock with no fresh timing, ask them once
-- (YELL, at most every 2 min). We never answer their asks.
local ADDON, root = ...
root.Writs = root.Writs or {}
local ns = root.Writs
local WP = ns.WP
local L = ns.L
local GPS = WP.GPS

local T = {}
WP.Transports = T
if GPS then GPS.Transports = T end

ns.AddEnglish({
    ["Zeppelin pour %s dans %s"] = "Zeppelin to %s in %s",
    ["Bateau pour %s dans %s"] = "Boat to %s in %s",
    ["Zeppelin pour %s à quai, part dans %s"] = "Zeppelin to %s docked, leaves in %s",
    ["Bateau pour %s à quai, part dans %s"] = "Boat to %s docked, leaves in %s",
    ["Zeppelin pour %s dans ~%d min (estimé)"] = "Zeppelin to %s in ~%d min (estimated)",
    ["Bateau pour %s dans ~%d min (estimé)"] = "Boat to %s in ~%d min (estimated)",
    ["%s (départ dans %s)"] = "%s (leaves in %s)",
    ["%s (à quai)"] = "%s (docked)",
})

local DWELL = 60            -- seconds a ship waits at each dock
local AVERAGE = 150         -- the router's flat cost of a link when nothing is known (wait + ride)
local BOARD = 3             -- seconds: reaching the dock this close to the departure misses it
local MAX_CYCLES = 40       -- a synced anchor older than this many cycles is no longer trusted
local SHARE_AGE = 60        -- seconds: a genuine share is the last departure from A, at most a period (+ this) old
local FOLLOW_GRACE = 10     -- seconds: the plan you follow still "makes" a ship it would miss by this little
local FRESH_CYCLES = 10     -- our own observation this recent is not overruled by a guild share
local AGREE = 15            -- seconds: a guild share further than this from a fresh own one is absurd
local SHARE_EVERY = 60      -- seconds: one share per link sent (and taken) at most this often
local DOCK_R = 40           -- yards: standing at a dock
local BAND = 45             -- seconds: the crossing seen may differ this much from the known one
local ENTER_LAG = 3         -- seconds: entering the dock's circle comes this long before the ship docks
local PREFIX = "WLHship"
-- rows learnt from another timer addon (projected from their timing, not a sighting of ours or a guild mate's)
local FOREIGN_SRC = { nauticus = true, ftrans = true }

-- The ships of our links (Route.lua LINKS' id): crossing A->B and B->A in seconds, the period (to the
-- hundredth: a whole-second period drifts up to 20 s over the 40 cycles a timing is kept), and the stop
-- names NaowhForever_QoL times them under (lookup strings for its runtime API).
local SHIPS = {
    ["uc-org"]   = { rideAB = 105, rideBA = 131, period = 356.29, naowhA = "1420:Zeppelin to Orgrimmar", naowhB = "1411:Zeppelin to Undercity" },
    ["uc-grom"]  = { rideAB = 96, rideBA = 119, period = 335.30, naowhA = "1420:Zeppelin to Grom'gol", naowhB = "1434:Zeppelin to Undercity" },
    ["org-grom"] = { rideAB = 78, rideBA = 105, period = 303.47, naowhA = "1411:Zeppelin to Grom'gol", naowhB = "1434:Zeppelin to Orgrimmar" },
    ["bb-rat"]   = { rideAB = 124, rideBA = 107, period = 350.82, naowhA = "1434:Boat to Ratchet", naowhB = "1413:Boat to Booty Bay" },
    ["sw-aub"]   = { rideAB = 58, rideBA = 69, period = 246.5, naowhA = "1453:Boat to Auberdine", naowhB = "1439:Boat to Stormwind Harbor" },
    ["men-ther"] = { rideAB = 104, rideBA = 105, period = 329.32, naowhA = "1437:Boat to Theramore", naowhB = "1445:Boat to Menethil Harbor" },
}
T.SHIPS = SHIPS
T.AVERAGE = AVERAGE

local function IsSecret(v) return issecretvalue ~= nil and issecretvalue(v) == true end
local function Num(v) if type(v) == "number" and v == v and v ~= math.huge and v ~= -math.huge and not IsSecret(v) then return v end end
local function ServerNow()
    local t = GetServerTime and Num(GetServerTime())
    return t or (time and time()) or 0
end
T._Now = ServerNow

local function Ship(link)
    local id = type(link) == "table" and link.id or link
    if type(id) ~= "string" then return nil end
    return SHIPS[id], id
end
local function Ride(s, fromA) return fromA and s.rideAB or s.rideBA end
-- seconds after the anchor (the ship leaving A) when it leaves this side
local function LeaveOffset(s, fromA) return fromA and 0 or (s.rideAB + DWELL) end
-- the gap between two phases on a cycle (0 .. period / 2)
local function PhaseGap(a, b, p)
    local d = (a - b) % p
    if d > p / 2 then d = p - d end
    return d
end

local function Opt(key, default)
    local o = WLWritsDB and WLWritsDB.gpsOpts
    local v = o and o[key]
    if v == nil then return default end
    return v
end

-- ---------------------------------------------------------------- saved timings

-- WLWritsDB.ships[realm][id] = { at = anchor (server time the ship left A), src = "seen"|"guild", by, t }
local function Rows()
    if type(WLWritsDB) ~= "table" then return nil end
    local realm = GetRealmName and GetRealmName()
    if type(realm) ~= "string" or IsSecret(realm) or realm == "" then realm = "?" end
    WLWritsDB.ships = type(WLWritsDB.ships) == "table" and WLWritsDB.ships or {}
    local r = WLWritsDB.ships[realm]
    if type(r) ~= "table" then r = {}; WLWritsDB.ships[realm] = r end
    return r
end
T._Rows = Rows

-- A row still worth using now: not from the future (a changed clock) and not too old.
local function UsableRow(s, row, now)
    if type(row) ~= "table" then return nil end
    local at = Num(row.at)
    if not at or at > now + 5 or now - at > MAX_CYCLES * s.period then return nil end
    return row
end

-- ---------------------------------------------------------------- NaowhForever_QoL (live, optional)

-- The anchor from Naowh's timing of one of the two stops, or nil. Its addon is separate and may load
-- late (or not at all): looked up at each call, every call guarded.
local SIDES = { true, false }
local function NaowhAnchor(s, now)
    local N = rawget(_G, "NaowhForever")
    local TT = type(N) == "table" and rawget(N, "TransportTimes")
    if type(TT) ~= "table" or type(TT.Next) ~= "function" then return nil end
    for _, fromA in ipairs(SIDES) do
        local key = fromA and s.naowhA or s.naowhB
        local ok, secs, kind = pcall(TT.Next, key, now)
        secs = ok and Num(secs)
        if secs and secs >= 0 and secs < 2 * s.period and (kind == "departure" or kind == "arrival") then
            local leave = kind == "departure" and secs or (secs + DWELL)
            return now + leave - LeaveOffset(s, fromA)
        end
    end
    return nil
end

-- ---------------------------------------------------------------- the timing

-- The anchor and where it comes from ("naowh" | "synced"), or nil.
local function Anchor(s, id, now)
    local a = NaowhAnchor(s, now)
    if a then return a, "naowh" end
    local rows = Rows()
    local row = rows and UsableRow(s, rows[id], now)
    if row then return row.at, "synced" end
    return nil
end

-- When the ship of `link` (a LINKS entry or its id) next leaves the `fromA` side, seen from server time
-- `t` (default now): wait (seconds from t), ride (seconds on board), confidence ("naowh" | "synced" |
-- "estimated"), docked (the ship is at that dock at t), period. Estimated: wait is half a cycle.
-- nil for a link that is no ship (a druid's flight).
function T.Next(link, fromA, t)
    local s, id = Ship(link)
    if not s then return nil end
    fromA = fromA and true or false
    local now = ServerNow()
    t = Num(t) or now
    local ride, period = Ride(s, fromA), s.period
    local anchor, conf = Anchor(s, id, now)
    if not anchor then return math.floor(period / 2), ride, "estimated", false, period end
    local wait = (anchor + LeaveOffset(s, fromA) - t) % period
    return wait, ride, conf, wait <= DWELL, period
end

-- What the link costs reaching its dock at server time `t`: seconds (wait + ride) and the confidence.
-- Unknown timing: the old flat AVERAGE (plans without timing stay as they were). Arriving a few seconds
-- before it leaves misses that ship: the next one. `follow` (the plan you already follow): the other
-- way round, a ship it would miss by under FOLLOW_GRACE seconds still counts as caught. New plans are
-- strict, the followed one lenient: as the countdown and the walking estimate move, the route does not
-- flip between the zeppelin and the Hearthstone at each replan (nor while you stand on the deck).
function T.Cost(link, fromA, t, follow)
    local wait, ride, conf, _, period = T.Next(link, fromA, t)
    if not wait then return nil end
    if conf == "estimated" then return AVERAGE, conf, nil, nil end
    if follow then
        if wait > period - FOLLOW_GRACE then wait = 0 end
    elseif wait < BOARD then
        wait = wait + period
    end
    return wait + ride, conf, wait, ride
end

-- "1:20"
local function Clock(seconds)
    local s = math.max(0, math.floor(seconds + 0.5))
    return string.format("%d:%02d", math.floor(s / 60), s % 60)
end
T.Clock = Clock

-- The arrow's line for a ship leg, live: "Zeppelin pour Grom'gol dans 1:20", "… à quai, part dans
-- 0:35", "… dans ~2 min (estimé)"; and the colour key ("gold" docked, "warn" leaving within 30 s,
-- "ok" coming, "muted" estimated). nil for a link that is no ship.
function T.Line(link, fromA, place)
    local wait, _, conf, docked = T.Next(link, fromA)
    if not wait then return nil end
    local boat = type(link) == "table" and link.mode == "boat"
    if not boat and type(link) == "string" then
        boat = link == "bb-rat" or link == "sw-aub" or link == "men-ther"
    end
    place = place or "?"
    if conf == "estimated" then
        local m = math.max(1, math.floor(wait / 60))
        return string.format(boat and L("Bateau pour %s dans ~%d min (estimé)") or L("Zeppelin pour %s dans ~%d min (estimé)"), place, m), "muted", conf
    end
    if docked then
        return string.format(boat and L("Bateau pour %s à quai, part dans %s") or L("Zeppelin pour %s à quai, part dans %s"), place, Clock(wait)),
            wait < 30 and "warn" or "gold", conf
    end
    return string.format(boat and L("Bateau pour %s dans %s") or L("Zeppelin pour %s dans %s"), place, Clock(wait)), "ok", conf
end

-- A plan's ship leg told on a card (not live): "Zeppelin pour Grom'gol (départ dans ~3 min)", "(à
-- quai)" when it waits at the dock as you get there; the text unchanged when the timing is estimated.
function T.CardPart(text, leg)
    if type(leg) ~= "table" or not leg.departAt or leg.conf == "estimated" or not leg.conf then return text end
    local left = leg.departAt - ServerNow()
    if left <= 0 then return text end
    if left < 60 then return string.format(L("%s (à quai)"), text) end
    local m = GPS and GPS.Minutes and GPS.Minutes(left)
    if not m then return text end
    return string.format(L("%s (départ dans %s)"), text, m)
end

-- ---------------------------------------------------------------- learning: an arrival seen

local share   -- forward

-- The ship of `link` reached the `atA` side at server time `arrival` (seen by this character): the
-- anchor is kept ("synced", newest wins) and shared with the guild. Returns the anchor.
function T.Observe(link, atA, arrival)
    local s, id = Ship(link)
    arrival = Num(arrival)
    if not (s and arrival) then return nil end
    local now = ServerNow()
    if arrival > now + 5 or now - arrival > s.period then return nil end
    local anchor = arrival + DWELL - LeaveOffset(s, atA and true or false)
    -- kept as a departure already gone (a time to come would read as a changed clock)
    while anchor > now do anchor = anchor - s.period end
    local rows = Rows()
    if not rows then return nil end
    rows[id] = { at = anchor, src = "seen", by = UnitName and UnitName("player") or nil, t = now }
    if share then pcall(share, id, anchor) end
    return anchor
end

-- The position stream (one sample a second, near docks): you stood within DOCK_R of dock X, then you
-- are within DOCK_R of the other end Y about one crossing later: you rode the ship, it docked at Y
-- about ENTER_LAG seconds after you entered Y's circle. Nothing else crosses the sea in that time, so
-- no ride path data is needed. `docks`: the GPS dock points (Route.lua), each with link, start (A side)
-- and other.
local left        -- { cont, wx, wy, t }: the last sample at a dock before leaving it
local atDockNow   -- true while the last sample was at a dock
local function Near(p, cont, wx, wy, r)
    if p.cont ~= cont then return false end
    local dx, dy = p.wx - wx, p.wy - wy
    return dx * dx + dy * dy <= r * r
end
function T._Sample(t, cont, wx, wy, docks)
    if not (Num(t) and cont and Num(wx) and Num(wy) and type(docks) == "table") then return nil end
    local here
    for _, d in ipairs(docks) do
        if d.link and SHIPS[d.link.id or ""] and Near(d, cont, wx, wy, DOCK_R) then here = here or {}; here[#here + 1] = d end
    end
    local seen
    if here and left and not atDockNow then
        -- arrived at a dock: is it the other end of the dock we left, about one crossing later?
        for _, y in ipairs(here) do
            local x = y.other
            local s = SHIPS[y.link.id]
            if x and Near(x, left[1], left[2], left[3], DOCK_R) then
                local ride = Ride(s, x.start and true or false)
                local took = t - left[4]
                if took >= ride * 0.5 and took <= ride + BAND then
                    seen = T.Observe(y.link, y.start and true or false, t + ENTER_LAG)
                    break
                end
            end
        end
        left = nil
    end
    if here then
        left = { cont, wx, wy, t }
        atDockNow = true
    else
        atDockNow = false
        if left and t - left[4] > 300 then left = nil end
    end
    return seen
end
function T._ResetWatch() left, atDockNow = nil, nil end

-- On board: the watcher saw you at the `fromA` dock of `link` until about when its (timed) ship left,
-- you are at no dock since, and the crossing is not over. The seconds of the crossing left, else nil.
-- `dock`: that dock's point (a GPS dock, with cont / wx / wy).
function T.Aboard(link, fromA, dock, now)
    local s = Ship(link)
    if not (s and left and not atDockNow and type(dock) == "table") then return nil end
    now = Num(now) or ServerNow()
    local wait, ride, conf, _, period = T.Next(link, fromA, now)
    if not wait or conf == "estimated" then return nil end
    local gone = now + wait - period          -- its last departure from that side
    if now - gone > ride + BAND or left[4] < gone - 5 or left[4] > gone + 30 then return nil end
    if not Near(dock, left[1], left[2], left[3], DOCK_R) then return nil end
    return math.max(0, gone + ride - now)
end

-- ---------------------------------------------------------------- guild sharing

local CI = C_ChatInfo
local Register = (CI and CI.RegisterAddonMessagePrefix) or RegisterAddonMessagePrefix
if Register then pcall(Register, PREFIX) end
local sentAt, takenAt = {}, {}
local function Clk() return GetTime and GetTime() or 0 end

share = function(id, anchor)
    if Opt("shipShare", true) == false then return end
    if not (IsInGuild and IsInGuild()) then return end
    local c = Clk()
    if sentAt[id] and c - sentAt[id] < SHARE_EVERY then return end
    local send = (C_ChatInfo and C_ChatInfo.SendAddonMessage) or SendAddonMessage
    if not send then return end
    sentAt[id] = c
    pcall(send, PREFIX, string.format("S|%s|%d", id, math.floor(anchor + 0.5)), "GUILD")
end

local function Short(n) return type(n) == "string" and (n:gsub("[%- ].*$", "")) or nil end

-- A guild mate's share: taken when it is newer than ours and makes sense. True when kept.
function T._OnShare(msg, sender)
    if type(msg) ~= "string" or IsSecret(msg) or #msg > 64 then return false end
    local verb, id, at = msg:match("^([^|]*)|([^|]*)|([^|]*)")
    if verb ~= "S" then return false end
    local s = SHIPS[id or ""]
    at = tonumber(at)
    if not (s and Num(at)) then return false end
    local now = ServerNow()
    -- from the future, or older than a fresh sighting can be (a sender shares the last departure from
    -- A when it sees the ship arrive, so at most one period old): absurd or replayed
    if at > now + 5 or now - at > s.period + SHARE_AGE then return false end
    local c = Clk()
    if takenAt[id] and c - takenAt[id] < SHARE_EVERY then return false end
    local rows = Rows()
    if not rows then return false end
    local row = UsableRow(s, rows[id], now)
    -- a row from another addon (projected from an older timing) gives way to a guild mate's sighting
    if row and not FOREIGN_SRC[row.src] then
        if row.at >= at then return false end            -- ours is as new
        if row.src == "seen" and now - row.at < FRESH_CYCLES * s.period and PhaseGap(at, row.at, s.period) > AGREE then
            return false                                 -- contradicts what we saw ourselves
        end
    end
    takenAt[id] = c
    rows[id] = { at = at, src = "guild", by = Short(sender), t = now }
    return true
end
function T._ResetShare() sentAt, takenAt = {}, {} end

-- ---------------------------------------------------------------- other timer addons

-- Wire facts of NauticusClassic's protocol (MIT, github.com/psynct/NauticusClassic and
-- github.com/sam-k-taylor/NauticusClassicResurrected), whose ship ids ForeverTransport uses too: each
-- ship's id, whether its "platform 1" is our A side, and when the ship leaves platform 1 in Nauticus'
-- cycle (0 = the ship reaching platform 1). Id 5 (the old Menethil - Auberdine Bravery) is no ship of ours.
local WIRE = {
    ["uc-org"]   = { id = 1, p1A = false, p1Leave = 60 },       -- platform 1: Orgrimmar
    ["org-grom"] = { id = 2, p1A = true, p1Leave = 60 },        -- Orgrimmar
    ["uc-grom"]  = { id = 3, p1A = true, p1Leave = 60 },        -- Undercity
    ["bb-rat"]   = { id = 4, p1A = false, p1Leave = 60 },       -- Ratchet
    ["men-ther"] = { id = 6, p1A = true, p1Leave = 60 },        -- Menethil Harbor
    ["sw-aub"]   = { id = 11, p1A = true, p1Leave = 77.105 },   -- Stormwind Harbor (Forever only)
}
local BY_WIRE = {}
for id, w in pairs(WIRE) do BY_WIRE[w.id] = id end
T._WIRE = WIRE

local FT_PREFIX, NAUT_PREFIX = "FTrans2", "NauticSync"
local FT_ASK = "Q|5"
local HEARD = { GUILD = true, PARTY = true, RAID = true, YELL = true }
local NAUT_MAX_SINCE = 3 * 86400 * 1000   -- ms: a Nauticus cycle known for longer drifts on our 1/100 s periods
local ASK_EVERY = 120                    -- seconds between two asks
local MAX_FIELD = 8                      -- digits of one Nauticus number

-- Nauticus numbers: base-N digits, least significant first, over this alphabet (no space, comma,
-- colon, "s", "S", "%", tab, line feed, carriage return, "|").
local DIGITS = "0123456789ABCDEFGHIJKLMNOPQRTUVWXYZabcdefghijklmnopqrtuvwxyz!\"#$&'()*+-./;<=>?@[\\]^_`{}~"
    .. "\1\2\3\4\5\6\7\8\11\12\14\15\16\17\18\19\20\21\22\23\24\25\26\27\28\29\30\31\127"
local NBASE = #DIGITS
local DVAL = {}
for i = 1, NBASE do DVAL[DIGITS:byte(i)] = i - 1 end
-- read from the most significant digit (the last one) down
local function Decode(text)
    local len = type(text) == "string" and #text or 0
    if len == 0 or len > MAX_FIELD then return nil end
    local n = 0
    for i = len, 1, -1 do
        local v = DVAL[text:byte(i)]
        if v == nil then return nil end
        n = n * NBASE + v
    end
    return n
end
local function Encode(n)
    n = math.floor(n)
    local d = n % NBASE
    local head = DIGITS:sub(d + 1, d + 1)
    if n < NBASE then return head end
    return head .. Encode((n - d) / NBASE)
end
-- the checksum their messages carry (the classic WoW string hash)
local function Hash(text)
    local c, len = 1, #text
    for i = 1, len, 3 do
        c = (c * 8161) % 4294967279 + text:byte(i) * 16776193
            + (text:byte(i + 1) or (len - i + 256)) * 8372226
            + (text:byte(i + 2) or (len - i + 256)) * 3932164
    end
    return c % 4294967291
end
T._Decode, T._Encode, T._Hash = Decode, Encode, Hash

-- our ask: every ship of ours by its wire id, none with a timing ("tell me"), then the checksum
local function NautAsk()
    local wanted = {}
    for _, link in ipairs({ "uc-org", "org-grom", "uc-grom", "bb-rat", "men-ther", "sw-aub" }) do
        wanted[#wanted + 1] = Encode(WIRE[link].id)
    end
    local body = table.concat(wanted, ",")
    return string.format("KWN4 4 %s %s", body, Encode(Hash(body)))
end
local NAUT_ASK = NautAsk()
T._NAUT_ASK, T._FT_ASK = NAUT_ASK, FT_ASK

-- A timing that is ours or a guild mate's and recent (or another addon's, taken recently).
local function Fresh(s, row, now)
    if FOREIGN_SRC[row.src] then return now - (Num(row.t) or 0) < FRESH_CYCLES * s.period end
    return now - row.at < FRESH_CYCLES * s.period
end

local foreignAt = {}
-- Another addon's timing for `id` as an anchor (any cycle): kept as the last departure from A at or
-- before now, unless a fresh timing of ours / a guild mate's exists (within AGREE it adds nothing, beyond
-- it the other addon is the one wrong), or one was taken for this ship in the last 60 s. True when kept.
local function TakeForeign(id, anchor, src, sender)
    local s = SHIPS[id]
    anchor = Num(anchor)
    if not (s and anchor) then return false end
    local now = ServerNow()
    anchor = anchor + math.floor((now - anchor) / s.period) * s.period
    local c = Clk()
    if foreignAt[id] and c - foreignAt[id] < SHARE_EVERY then return false end
    local rows = Rows()
    if not rows then return false end
    local row = UsableRow(s, rows[id], now)
    if row and not FOREIGN_SRC[row.src] and Fresh(s, row, now) then return false end
    foreignAt[id] = c
    rows[id] = { at = anchor, src = src, by = Short(sender), t = now }
    return true
end

local function LagSeconds()
    if type(GetNetStats) ~= "function" then return 0 end
    local ok, _, _, lag = pcall(GetNetStats)
    lag = ok and Num(lag)
    if not lag or lag < 0 or lag > 10000 then return 0 end
    return lag / 1000
end

-- NauticusClassic: "KWN4 4 <id>[:<ms since a cycle start>[:swaps[:boots]]],... <checksum>", numbers in
-- their base-N digits. The number of ships taken.
function T._OnNauticus(msg, sender)
    if type(msg) ~= "string" or IsSecret(msg) or #msg >= 254 then return 0 end
    local list, hash = msg:match("^KWN4 4 ([^ ]+) ([^ ]+)$")
    if not list or Decode(hash) ~= Hash(list) then return 0 end
    local now, lag, n = ServerNow(), LagSeconds(), 0
    for entry in list:gmatch("[^,]+") do
        -- "<id>:<since>[:swaps[:boots]]"; an id alone is their ask, nothing to take
        local c1 = entry:find(":", 1, true)
        local c2 = c1 and entry:find(":", c1 + 1, true)
        local id = c1 and BY_WIRE[Decode(entry:sub(1, c1 - 1)) or -1]
        local since = c1 and Decode(entry:sub(c1 + 1, (c2 or 0) - 1))
        if id and since and since <= NAUT_MAX_SINCE then
            local s, w = SHIPS[id], WIRE[id]
            local zero = now - since / 1000 - lag            -- their cycle's zero (platform 1)
            if TakeForeign(id, zero + w.p1Leave - LeaveOffset(s, w.p1A), "nauticus", sender) then n = n + 1 end
        end
    end
    return n
end

-- ForeverTransport: "A|<id>|<dock 1|2>|<server time the ship reached that dock>|<server time seen>|...".
-- True when kept.
function T._OnForever(msg, sender)
    if type(msg) ~= "string" or IsSecret(msg) or #msg > 250 then return false end
    local wid, dock, arrival, seen, rest = msg:match("^A|(%d+)|(%d+)|(%d+%.?%d*)|(%d+%.?%d*)(.*)$")
    if not wid or (rest ~= "" and rest:sub(1, 1) ~= "|") then return false end
    local id = BY_WIRE[tonumber(wid)]
    dock, arrival, seen = tonumber(dock), Num(tonumber(arrival)), Num(tonumber(seen))
    if not (id and arrival and seen) or (dock ~= 1 and dock ~= 2) then return false end
    local s, w = SHIPS[id], WIRE[id]
    local now = ServerNow()
    -- seen in the future or longer ago than we keep a timing; an arrival far from when it was seen
    if seen > now + 5 or now - seen > MAX_CYCLES * s.period then return false end
    if arrival > seen + s.period + 5 or seen - arrival > MAX_CYCLES * s.period then return false end
    local atA = (dock == 1) == w.p1A
    return TakeForeign(id, arrival + DWELL - LeaveOffset(s, atA), "ftrans", sender)
end

-- Standing at a dock (YELL reaches the people on it): when one of its ships has no fresh timing, one
-- ask in both formats, at most every ASK_EVERY seconds. `docks`: the GPS dock points. True when sent.
local askedAt
local function TimedFresh(id, now)
    local s = SHIPS[id]
    if NaowhAnchor(s, now) then return true end
    local rows = Rows()
    local row = rows and UsableRow(s, rows[id], now)
    return row ~= nil and row ~= false and Fresh(s, row, now)
end
function T._AskAtDock(cont, wx, wy, docks)
    if not (cont and Num(wx) and Num(wy) and type(docks) == "table") then return false end
    if Opt("shipShare", true) == false then return false end
    if IsInInstance and IsInInstance() then return false end
    local c = Clk()
    if askedAt and c - askedAt < ASK_EVERY then return false end
    local now, need = ServerNow(), false
    for _, d in ipairs(docks) do
        local id = d.link and d.link.id
        if id and SHIPS[id] and Near(d, cont, wx, wy, DOCK_R) and not TimedFresh(id, now) then need = true; break end
    end
    if not need then return false end
    local send = (C_ChatInfo and C_ChatInfo.SendAddonMessage) or SendAddonMessage
    if not send then return false end
    askedAt = c
    pcall(send, FT_PREFIX, FT_ASK, "YELL")
    pcall(send, NAUT_PREFIX, NAUT_ASK, "YELL")
    return true
end
function T._ResetForeign() foreignAt, askedAt = {}, nil end
if Register then
    pcall(Register, FT_PREFIX)
    pcall(Register, NAUT_PREFIX)
end

-- ---------------------------------------------------------------- events

local function Me() return UnitName and UnitName("player") end

local ticker
local function Tick()
    if not (GPS and GPS._Here and GPS._Docks) then return end
    if UnitOnTaxi and UnitOnTaxi("player") then return end
    local cont, wx, wy = GPS._Here()
    if not cont then return end
    local docks = GPS._Docks()
    pcall(T._Sample, ServerNow(), cont, wx, wy, docks)
    pcall(T._AskAtDock, cont, wx, wy, docks)
end

local f = CreateFrame("Frame")
pcall(f.RegisterEvent, f, "PLAYER_LOGIN")
pcall(f.RegisterEvent, f, "CHAT_MSG_ADDON")
f:SetScript("OnEvent", function(_, event, prefix, msg, channel, sender)
    if event == "PLAYER_LOGIN" then
        -- old rows go (and a clock gone back leaves none from the future)
        local rows = Rows()
        if rows then
            local now = ServerNow()
            for id, row in pairs(rows) do
                local s = SHIPS[id]
                if not (s and UsableRow(s, row, now)) then rows[id] = nil end
            end
        end
        if not ticker and C_Timer and C_Timer.NewTicker then ticker = C_Timer.NewTicker(1, Tick) end
    elseif event == "CHAT_MSG_ADDON" then
        if IsSecret(prefix) or IsSecret(channel) or IsSecret(sender) then return end
        if prefix ~= PREFIX and prefix ~= FT_PREFIX and prefix ~= NAUT_PREFIX then return end
        if Short(sender) == Me() then return end
        if prefix == PREFIX then
            if channel == "GUILD" then pcall(T._OnShare, msg, sender) end
        elseif HEARD[channel] then
            if prefix == FT_PREFIX then pcall(T._OnForever, msg, sender) else pcall(T._OnNauticus, msg, sender) end
        end
    end
end)
