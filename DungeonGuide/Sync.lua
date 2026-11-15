-- Synchronisation de groupe : chaque membre qui a Dungeon Guide envoie les quêtes de donjon
-- de son journal (et si elles sont prêtes). Le guide affiche qui a quoi avant d'entrer.
local ADDON, ns = ...
local PREFIX = "WLDT"
ns.party = {}

local CI = C_ChatInfo
local Register = (CI and CI.RegisterAddonMessagePrefix) or RegisterAddonMessagePrefix
local Send = (CI and CI.SendAddonMessage) or SendAddonMessage
if Register then pcall(Register, PREFIX) end

local function Channel()
  if IsInRaid and IsInRaid() then return "RAID" end
  if IsInGroup and IsInGroup() then return "PARTY" end
end

local function Short(name) return name and (name:gsub("%-.*$", "")) end
local me

local lastSent, pending = "", false
function ns.SyncSend(force)
  local ch = Channel()
  if not (ch and Send) then return end
  local log = ns.LogEntries()
  local ids = {}
  for id, e in pairs(log) do
    if ns.Q[id] then table.insert(ids, id .. (e.complete and "*" or "")) end
  end
  table.sort(ids)
  local payload = table.concat(ids, ",")
  if payload == lastSent and not force then return end
  lastSent = payload
  -- messages de 240 caractères max : « n/total:liste »
  local chunks, cur = {}, ""
  for _, s in ipairs(ids) do
    if #cur + #s + 1 > 230 then table.insert(chunks, cur); cur = "" end
    cur = (cur == "" and s) or (cur .. "," .. s)
  end
  table.insert(chunks, cur)
  for i, c in ipairs(chunks) do pcall(Send, PREFIX, i .. "/" .. #chunks .. ":" .. c, ch) end
end

local function Schedule()
  if pending then return end
  pending = true
  C_Timer.After(2, function() pending = false; ns.SyncSend() end)
end

local buf = {}
local function OnMessage(prefix, msg, channel, sender)
  if prefix ~= PREFIX or not msg then return end
  local who = Short(sender)
  me = me or UnitName("player")
  if not who or who == me then return end
  if msg == "HELLO" then lastSent = ""; Schedule(); return end
  local i, n, body = msg:match("^(%d+)/(%d+):(.*)$")
  if not i then return end
  i, n = tonumber(i), tonumber(n)
  if i == 1 then buf[who] = {} end
  buf[who] = buf[who] or {}
  for tok in body:gmatch("[^,]+") do
    local id, star = tok:match("^(%d+)(%*?)$")
    if id then buf[who][tonumber(id)] = (star == "*") and "ready" or "on" end
  end
  if i == n then
    ns.party[who] = buf[who]; buf[who] = nil
    if ns.Render then ns.Render() end
  end
end

local function Prune()
  local keep = {}
  local n = (GetNumGroupMembers and GetNumGroupMembers()) or 0
  local unit = (IsInRaid and IsInRaid()) and "raid" or "party"
  for k = 1, n do
    local nm = UnitName(unit .. k)
    if nm then keep[Short(nm)] = true end
  end
  for who in pairs(ns.party) do if not keep[who] then ns.party[who] = nil end end
end

-- « Bob ✓, Ann (en cours) · sans la quête : Jim » pour une quête donnée
function ns.PartyLine(qid)
  local has, miss = {}, {}
  for who, list in pairs(ns.party) do
    local s = list[qid]
    if s == "ready" then table.insert(has, "|cff59e67a" .. who .. "|r")
    elseif s == "on" then table.insert(has, who)
    else table.insert(miss, "|cffff9933" .. who .. "|r") end
  end
  if #has == 0 and #miss == 0 then return nil end
  local t = {}
  if #has > 0 then table.insert(t, ns.L.PARTY_HAS:format(table.concat(has, ", "))) end
  if #miss > 0 then table.insert(t, ns.L.PARTY_MISS:format(table.concat(miss, ", "))) end
  return table.concat(t, "  ·  ")
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("CHAT_MSG_ADDON")
ev:RegisterEvent("GROUP_ROSTER_UPDATE")
ev:RegisterEvent("QUEST_LOG_UPDATE")
ev:RegisterEvent("PLAYER_ENTERING_WORLD")
local wasGrouped = false
ev:SetScript("OnEvent", function(_, e, ...)
  if e == "CHAT_MSG_ADDON" then OnMessage(...) return end
  local ch = Channel()
  if e == "GROUP_ROSTER_UPDATE" then
    Prune()
    if ch and not wasGrouped and Send then pcall(Send, PREFIX, "HELLO", ch); lastSent = "" end
    wasGrouped = ch ~= nil
    if not ch then wipe(ns.party) end
  end
  if ch then Schedule() end
end)
