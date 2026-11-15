-- WhatsNewUI.lua: "Quoi de neuf" — after an update (however it was installed), a window lists what
-- changed since the version you last saw, once. /wlh nouveautes (or news) opens it again.
local ADDON, ns = ...

local function S() return ns.Writs and ns.Writs.S end
local function Fr() return ns.lang == "fr" end
local function Cur()
  local meta = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
  return meta and meta(ADDON, "Version") or ns.VERSION or "?"
end

-- "1.0.0-beta.12" -> comparable numbers
local function Key(v)
  local a, b, c, n = tostring(v or ""):match("^(%d+)%.(%d+)%.(%d+)%-?%a*%.?(%d*)")
  return (tonumber(a) or 0) * 1e9 + (tonumber(b) or 0) * 1e6 + (tonumber(c) or 0) * 1e3 + (tonumber(n) or 0)
end

local win
local function Build()
  local St = S()
  if not (St and St.Window) then return end
  win = St.Window("WLHelperWhatsNew", 480, 420, Fr() and "Quoi de neuf" or "What's new", nil, WLDTDB, "newsPos")
  local sa = St.ScrollArea and St.ScrollArea(win)
  local holder = sa and sa.child or CreateFrame("Frame", nil, win)
  if sa then sa:SetPoint("TOPLEFT", 14, -54); sa:SetPoint("BOTTOMRIGHT", -14, 14)
  else holder:SetPoint("TOPLEFT", 14, -54); holder:SetPoint("BOTTOMRIGHT", -14, 14) end
  holder:SetWidth(440)
  win.sa, win.holder, win.lines = sa, holder, {}
end

local function Fill(sinceKey)
  local St = S()
  local fr = Fr()
  local y, i = 0, 0
  local function Line(text, size, color, gap)
    i = i + 1
    local fs = win.lines[i]
    if not fs then
      fs = St.Text(win.holder, size, color)
      fs:SetJustifyH("LEFT"); fs:SetWordWrap(true)
      win.lines[i] = fs
    end
    fs:ClearAllPoints(); fs:SetPoint("TOPLEFT", 0, -y); fs:SetWidth(440)
    fs:SetText(text); fs:Show()
    local ok, h = pcall(fs.GetStringHeight, fs)
    y = y + ((ok and type(h) == "number" and h > 0) and h or size + 2) + (gap or 6)
  end
  local C = St.C or {}
  local shown = 0
  for _, e in ipairs(ns.WHATSNEW or {}) do
    if Key(e.v) > sinceKey or shown == 0 then
      shown = shown + 1
      Line("Version " .. e.v, 14, C.text or { 1, 1, 1 }, 4)
      for _, t in ipairs((fr and e.fr) or e.en or {}) do Line("• " .. t, 12, C.muted or { 0.8, 0.8, 0.8 }, 4) end
      if not fr and (#(e.en or {}) == 0) then for _, t in ipairs(e.fr or {}) do Line("• " .. t, 12, C.muted or { 0.8, 0.8, 0.8 }, 4) end end
      y = y + 8
      if shown >= 8 then break end
    end
  end
  for k = i + 1, #win.lines do win.lines[k]:Hide() end
  win.holder:SetHeight(math.max(y, 10))
  if win.sa and win.sa.SetContentHeight then win.sa:SetContentHeight(y) end
end

function ns.ShowWhatsNew(sinceVersion)
  if not win then Build() end
  if not win then return end
  Fill(Key(sinceVersion))
  win:Show()
end

local ev = CreateFrame("Frame")
pcall(ev.RegisterEvent, ev, "PLAYER_LOGIN")
ev:SetScript("OnEvent", function()
  C_Timer.After(8, function()
    if not WLDTDB then return end
    local cur = Cur()
    local seen = WLDTDB.seenVersion
    WLDTDB.seenVersion = cur
    -- first install: no list (the welcome screen speaks); an update: what changed since then
    if seen and seen ~= cur and Key(cur) > Key(seen) and not InCombatLockdown() then ns.ShowWhatsNew(seen) end
  end)
end)

local hook = CreateFrame("Frame")
pcall(hook.RegisterEvent, hook, "PLAYER_LOGIN")
hook:SetScript("OnEvent", function()
  local orig = SlashCmdList and SlashCmdList.WLDUNGEONTOOL
  if not orig then return end
  SlashCmdList.WLDUNGEONTOOL = function(msg, ...)
    local w = ((msg or ""):match("^%s*(%S+)") or ""):lower()
    if w == "nouveautes" or w == "nouveautés" or w == "news" or w == "changelog" then ns.ShowWhatsNew(WLDTDB and WLDTDB.newsFrom); return end
    return orig(msg, ...)
  end
end)
