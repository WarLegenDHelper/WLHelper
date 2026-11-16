-- WhatsNewUI.lua: "Quoi de neuf" — after an update (however it was installed), a window lists what
-- changed since the version you last saw, once. /wlh nouveautes (or news) opens it again.
-- Layout: one block per version (the version on the left, its date muted on the right; a 1 px rule
-- with 16 px of air between versions), then its changes grouped by kind (Nouveautés in green,
-- Changements in blue, Corrections in gold: a small label in the kind's colour), each change a 5 px
-- dot of that colour, its title (fg 13) and one muted sentence (12) under it, 8 px between changes.
-- English items without an English text fall back to the French one. The window fits its content
-- (DESIGN 3.2) and scrolls past 80 % of the screen; the footer says how to open it again.
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

local W, PAD = 480, 16
local CW = W - 2 * PAD
local INDENT = 16            -- the dot, then the change's text
local DOT = 5                -- the kind's dot before each change
local ITEM_GAP = 8           -- between two changes
local VERSION_GAP = 16       -- above and under the rule between two versions
local MONTHS_FR = { "janvier", "février", "mars", "avril", "mai", "juin", "juillet", "août", "septembre", "octobre", "novembre", "décembre" }
local MONTHS_EN = { "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December" }
-- kind, French label, English label, colour token
local KINDS = { { "add", "Nouveautés", "New", "ok" }, { "chg", "Changements", "Changes", "info" }, { "fix", "Corrections", "Fixes", "gold" } }

-- "2026-11-16" -> "16 novembre 2026" / "November 16, 2026"
local function DateText(d)
  local y, m, dd = tostring(d or ""):match("^(%d+)%-(%d+)%-(%d+)$")
  m = tonumber(m)
  if not (y and m and MONTHS_FR[m]) then return nil end
  if Fr() then return tonumber(dd) .. " " .. MONTHS_FR[m] .. " " .. y end
  return MONTHS_EN[m] .. " " .. tonumber(dd) .. ", " .. y
end

-- the generated text may hold the "…" glyph: the design system writes "..."
local function Clean(t)
  if type(t) ~= "string" then return nil end
  t = t:gsub("\226\128\166", "...")
  t = t:gsub("^%s+", ""):gsub("%s+$", "")
  return t ~= "" and t or nil
end

-- One change in the reader's language: title, sentence (either may be nil).
local function ItemText(it)
  local fr = type(it.fr) == "table" and it.fr or {}
  local en = type(it.en) == "table" and it.en or {}
  if Fr() then return Clean(fr[1]) or Clean(en[1]), Clean(fr[2]) end
  local title, text = Clean(en[1]), Clean(en[2])
  if not title then return Clean(fr[1]), Clean(fr[2]) end
  return title, text
end

local win
local function Build()
  local St = S()
  if not (St and St.Window) then return end
  win = St.Window("WLHelperWhatsNew", W, 420, Fr() and "Quoi de neuf" or "What's new", nil, WLDTDB, "newsPos",
    { header = St.HEADER_H, footer = true, minH = 160 })
  local top = (win.ContentTop and win:ContentTop() or 44) + 12
  local foot = St.FOOTER_H or 24
  local sa = St.ScrollArea and St.ScrollArea(win)
  local holder = sa and sa.child or CreateFrame("Frame", nil, win)
  if sa then sa:SetPoint("TOPLEFT", PAD, -top); sa:SetPoint("BOTTOMRIGHT", -PAD, 12 + foot)
  else holder:SetPoint("TOPLEFT", PAD, -top); holder:SetPoint("BOTTOMRIGHT", -PAD, 12 + foot) end
  holder:SetWidth(CW)
  win.sa, win.holder = sa, holder
  win.texts, win.dots, win.rules, win.dates = {}, {}, {}, {}
end

local function Fill(sinceKey)
  local St = S()
  local fr = Fr()
  local F = ns.F or { heading = 14, body = 13, label = 12, meta = 11 }
  local C = St.C or {}
  local y, nt, nd, nr, nv = 0, 0, 0, 0, 0
  local gap = 0                -- the space the last line asked for under it
  -- a line of text at (x, y), `w` wide (the rest of the column by default); returns its top
  local function Text(text, size, color, x, after, w)
    nt = nt + 1
    local fs = win.texts[nt]
    if not fs then
      fs = St.Text(win.holder, size, color)
      fs:SetJustifyH("LEFT"); fs:SetJustifyV("TOP"); fs:SetWordWrap(true)
      win.texts[nt] = fs
    end
    -- a reused line takes this line's size through the addon's font helper (font and fallback)
    if fs._size ~= size and ns.SetFont then fs._size = size; ns.SetFont(fs) end
    local c = color or C.fg or { 1, 1, 1 }
    fs:SetTextColor(c[1], c[2], c[3], 1)
    fs:ClearAllPoints(); fs:SetPoint("TOPLEFT", x or 0, -y)
    fs:SetText(text); fs:Show()
    w = w or (CW - (x or 0))
    local h = St.FitText and St.FitText(fs, 0, w, win.holder)
    if not (type(h) == "number" and h > 0) then
      fs:SetWidth(w)
      local ok, sh = pcall(fs.GetStringHeight, fs)
      h = (ok and type(sh) == "number" and sh > 0) and sh or size + 2
    end
    local at = y
    gap = after or 4
    y = y + h + gap
    return at
  end
  -- the date, muted, at the right end of the version line (one line, never cut: the version wraps)
  local function Date(text, at)
    nv = nv + 1
    local fs = win.dates[nv]
    if not fs then
      fs = St.Text(win.holder, F.meta, C.muted)
      fs:SetJustifyH("RIGHT"); fs:SetJustifyV("TOP"); fs:SetWordWrap(false)
      win.dates[nv] = fs
    end
    local c = C.muted or { 0.6, 0.6, 0.6 }
    fs:SetTextColor(c[1], c[2], c[3], 1)
    fs:SetText(text)
    local w = ns.TextWidth and ns.TextWidth(fs)
    if not (type(w) == "number" and w > 0) then
      local ok, sw = pcall(fs.GetStringWidth, fs)
      w = (ok and type(sw) == "number" and sw > 0) and sw or #text * 6
    end
    w = math.ceil(w) + 2
    fs:SetWidth(w)
    fs:ClearAllPoints()
    -- 14 px version, 11 px date: the date sits on the version's baseline
    fs:SetPoint("TOPRIGHT", win.holder, "TOPRIGHT", 0, -(at + (F.heading - F.meta)))
    fs:Show()
    return w
  end
  local function Dot(color, at, size)
    nd = nd + 1
    local d = win.dots[nd]
    if not d then
      d = St.Icon and St.Icon(win.holder, "dot", DOT, "ARTWORK", color) or win.holder:CreateTexture(nil, "ARTWORK")
      win.dots[nd] = d
    end
    d:SetSize(DOT, DOT)
    d:SetVertexColor(color[1], color[2], color[3])
    -- centred on the title's first line
    d:ClearAllPoints(); d:SetPoint("TOPLEFT", 3, -(at + math.floor((size + 2 - DOT) / 2 + 0.5)))
    d:Show()
  end
  local function Rule()
    nr = nr + 1
    local r = win.rules[nr]
    if not r then r = St.Rule(win.holder); win.rules[nr] = r end
    -- 16 px under the last change, the rule, 16 px over the next version
    y = y - gap + VERSION_GAP
    r:ClearAllPoints(); r:SetPoint("TOPLEFT", 0, -y); r:SetPoint("TOPRIGHT", 0, -y)
    r:Show()
    y = y + 1 + VERSION_GAP
    gap = 0
  end
  local shown, last, lastDate = 0, nil, nil
  for _, e in ipairs(ns.WHATSNEW or {}) do
    if Key(e.v) > sinceKey or shown == 0 then
      shown = shown + 1
      if shown > 1 then Rule() end
      last = e.v
      -- the date once per day: a version from the same day as the one above it shows none
      local date = DateText(e.date)
      if date and date == lastDate then date = nil elseif date then lastDate = date end
      local at = y
      local dw = date and Date(date, at) or 0
      Text("Version " .. e.v, F.heading, C.fg, 0, 12, CW - (dw > 0 and dw + 12 or 0))
      local items = type(e.items) == "table" and e.items or {}
      -- an older entry without kinds: its lines as plain changes
      if #items == 0 then
        items = {}
        for _, t in ipairs((fr and e.fr) or e.en or e.fr or {}) do items[#items + 1] = { s = "chg", fr = { t }, en = { t } } end
      end
      local groups = 0
      for _, kind in ipairs(KINDS) do
        local col = C[kind[4]] or C.fg
        local any = false
        for _, it in ipairs(items) do
          if it.s == kind[1] then
            local title, text = ItemText(it)
            if title or text then
              if not any then
                -- a new group: 12 px under the last change of the one before
                if groups > 0 then y = y - gap + 12 end
                groups = groups + 1
                Text(fr and kind[2] or kind[3], F.meta, col, 0, 6)
                any = true
              end
              local at2 = Text(title or text, F.body, C.fg, INDENT, (title and text) and 3 or ITEM_GAP)
              Dot(col, at2, F.body)
              if title and text then Text(text, F.label, C.muted, INDENT, ITEM_GAP) end
            end
          end
        end
      end
      if shown >= 8 then break end
    end
  end
  for k = nt + 1, #win.texts do win.texts[k]:Hide() end
  for k = nd + 1, #win.dots do win.dots[k]:Hide() end
  for k = nr + 1, #win.rules do win.rules[k]:Hide() end
  for k = nv + 1, #win.dates do win.dates[k]:Hide() end
  y = math.max(math.ceil(y - gap), 10)
  win.holder:SetHeight(y)
  if win.sa and win.sa.SetContentHeight then win.sa:SetContentHeight(y) end
  -- what the list covers, then how to see it again
  if win.subtitle then
    win.subtitle:SetText((shown > 1 and last) and ((fr and "Depuis la version " or "Since version ") .. last) or "")
  end
  if win.SetFooter then
    win:SetFooter(fr and "Tape /wlh nouveautes pour revoir cette liste." or "Type /wlh news to see this list again.", "")
  end
  if win.FitHeight then win:FitHeight(y) end
  if win.FitHeightLater then win:FitHeightLater(y) end
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
