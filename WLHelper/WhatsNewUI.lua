-- WhatsNewUI.lua: "Quoi de neuf" — after an update (however it was installed), a window shows what
-- changed since the version you last saw, once. /wlh nouveautes (or news) and the star button of
-- the WL Helper window open it again.
-- A workspace window (DESIGN 3.1: 70 % of the screen's width, resizable, its size kept):
--   left, a 199 px sidebar (the Hub's nav, 3.20): "Depuis ta connexion" when versions are unseen,
--     then every version (beta.N, its date muted), newest first, a 6 px accent dot on the unseen
--     ones; a click selects.
--   right, at the top: one summary sentence (« 12 nouveautés depuis ta dernière connexion
--     (beta.84 → beta.90) ») and the filter (Tout / Nouveau / Changé / Corrigé); under a rule, the
--     cards area, the only part that scrolls: per version a heading (version, date muted at the
--     right, once per day) then its changes as cards in a grid (3.22: 320 px minimum, 12 apart, 3
--     columns at most, a card never wider than 480 for a readable line). A card: the kind's pill
--     (green new, blue changed, gold fixed), the title (13, fg), at most 3 lines of text (12) and
--     "Voir plus" when it is longer, which unfolds the text in place ("Voir moins" folds it).
--   footer: the switch « Ne plus afficher à la connexion » and « Fermer ».
-- English items without an English text fall back to the French one.
local ADDON, ns = ...

local function S() return ns.Writs and ns.Writs.S end
local function Fr() return ns.lang == "fr" end
local function Cur()
  local meta = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
  return meta and meta(ADDON, "Version") or ns.VERSION or "?"
end

-- "1.0.0-beta.12" -> comparable numbers: alpha < beta < rc < the release itself
-- (1.0.0-beta.83 < 1.0.0-rc.1 < 1.0.0 < 1.0.1-beta.1)
local TAG_RANK = { alpha = 0, beta = 1, rc = 2 }
local function Key(v)
  local a, b, c, tag, n = tostring(v or ""):match("^(%d+)%.(%d+)%.(%d+)%-?(%a*)%.?(%d*)")
  if not a then return 0 end
  local rank = (tag == "") and 3 or TAG_RANK[tag:lower()] or 0
  return (((tonumber(a) * 1000 + tonumber(b)) * 1000 + tonumber(c)) * 4 + rank) * 1000 + (tonumber(n) or 0)
end
ns.WhatsNewKey = Key   -- for the offline tests

local PAD = 16
local SIDE_W = 199           -- the sidebar, then a 1 px divider (as the Hub's nav)
local ROW_H, ROW_GAP = 40, 2 -- a version in the sidebar
local TOP_H = 76             -- summary + filter, then the rule over the cards
local FOOT_H = 48            -- the switch and "Fermer"
local CARD_MIN, CARD_MAX = 320, 480
local GAP = 12               -- between cards, both ways
local MAX_COLS = 3
local CARD_PAD = 12
local LINES = 3              -- a folded card's text
local VERSION_GAP = 16       -- above and under the rule between two versions
local MORE_H = 20
local MONTHS_FR = { "janvier", "février", "mars", "avril", "mai", "juin", "juillet", "août", "septembre", "octobre", "novembre", "décembre" }
local MONTHS_EN = { "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December" }
-- kind -> French pill, English pill, colour token
local KIND = { add = { "Nouveau", "New", "ok" }, chg = { "Changé", "Changed", "info" }, fix = { "Corrigé", "Fixed", "gold" } }
local ORDER = { add = 1, chg = 2, fix = 3 }
local FILTERS = { { "all", "Tout", "All" }, { "add", "Nouveau", "New" }, { "chg", "Changé", "Changed" }, { "fix", "Corrigé", "Fixed" } }

-- "2026-11-16" -> "16 novembre 2026" / "November 16, 2026"
local function DateText(d)
  local y, m, dd = tostring(d or ""):match("^(%d+)%-(%d+)%-(%d+)$")
  m = tonumber(m)
  if not (y and m and MONTHS_FR[m]) then return nil end
  if Fr() then return tonumber(dd) .. " " .. MONTHS_FR[m] .. " " .. y end
  return MONTHS_EN[m] .. " " .. tonumber(dd) .. ", " .. y
end

-- "1.0.0-beta.90" -> "beta.90" (a release keeps its number)
local function Short(v)
  v = tostring(v or "")
  return v:match("^%d+%.%d+%.%d+%-(%a+%.%d+)$") or v
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

-- A version's changes with words, in the kinds' order (new, changed, fixed), filtered:
-- { { id, kind, title, text }, ... }. An older entry without kinds: its lines as changes.
local function Items(e, filter)
  local items = type(e.items) == "table" and e.items or {}
  if #items == 0 then
    items = {}
    for _, t in ipairs((Fr() and e.fr) or e.en or e.fr or {}) do items[#items + 1] = { s = "chg", fr = { t }, en = { t } } end
  end
  local out = {}
  for i, it in ipairs(items) do
    local kind = KIND[it.s] and it.s or "chg"
    if filter == nil or filter == "all" or filter == kind then
      local title, text = ItemText(it)
      if title or text then
        out[#out + 1] = { id = tostring(e.v) .. "#" .. i, kind = kind, title = title or text, text = title and text or nil, i = i }
      end
    end
  end
  table.sort(out, function(a, b)
    if ORDER[a.kind] ~= ORDER[b.kind] then return ORDER[a.kind] < ORDER[b.kind] end
    return a.i < b.i
  end)
  return out
end

-- the versions newer than `since`, newest first (the list is newest first)
local function Unseen(since)
  local out = {}
  for _, e in ipairs(ns.WHATSNEW or {}) do if Key(e.v) > since then out[#out + 1] = e end end
  return out
end

local function Plural(n, one, many) return n .. " " .. (n == 1 and one or many) end

local win
local Layout

-- a text height at width w (no line limit when maxLines is 0)
local function Fit(St, fs, w, maxLines, owner)
  local h = St.FitText and St.FitText(fs, maxLines, w, owner)
  if not (type(h) == "number" and h > 0) then
    fs:SetWidth(w)
    if fs.SetMaxLines then fs:SetMaxLines(maxLines) end
    local ok, sh = pcall(fs.GetStringHeight, fs)
    h = (ok and type(sh) == "number" and sh > 0) and sh or 14
  end
  return math.ceil(h)
end

-- the text needs more than its folded lines
local function Cut(fs, w)
  if ns.IsCut and ns.IsCut(fs) then return true end
  local tw = ns.TextWidth and ns.TextWidth(fs)
  return type(tw) == "number" and tw > LINES * w * 0.92
end

local function Select(key)
  if not win then return end
  win.sel = key
  if win.sa and win.sa.ScrollTo then win.sa:ScrollTo(0, true) end
  Layout()
end

local function SetFilter(v)
  if not win then return end
  win.filter = v
  if win.sa and win.sa.ScrollTo then win.sa:ScrollTo(0, true) end
  Layout()
end

-- one row of the sidebar (pooled)
local function SideRow(St, i)
  local r = win.rows[i]
  if r then return r end
  local C = St.C or {}
  local F = ns.F or { body = 13, meta = 11 }
  r = CreateFrame("Button", nil, win.sideHolder)
  r:SetHeight(ROW_H)
  r.sel = St.Solid(r, "BACKGROUND", C.selFill); r.sel:SetAllPoints(); r.sel:Hide()
  r.hl = St.Solid(r, "BACKGROUND", C.hoverFill); r.hl:SetAllPoints(); r.hl:SetAlpha(0)
  r.name = St.Text(r, F.body, C.fg)
  r.name:SetJustifyH("LEFT"); r.name:SetWordWrap(false)
  r.name:SetPoint("TOPLEFT", 12, -5); r.name:SetPoint("RIGHT", -24, 0)
  r.meta = St.Text(r, F.meta, C.muted)
  r.meta:SetJustifyH("LEFT"); r.meta:SetWordWrap(false)
  r.meta:SetPoint("TOPLEFT", r.name, "BOTTOMLEFT", 0, -2); r.meta:SetPoint("RIGHT", -24, 0)
  if St.ClampLabel then St.ClampLabel(r.name, nil, r); St.ClampLabel(r.meta, nil, r) end
  r.dot = St.Icon and St.Icon(r, "dot", 6, "ARTWORK", C.accent) or r:CreateTexture(nil, "ARTWORK")
  r.dot:SetSize(6, 6); r.dot:SetPoint("RIGHT", -12, 0)
  r:SetScript("OnEnter", function(self) self.hl:SetAlpha(1) end)
  r:SetScript("OnLeave", function(self) self.hl:SetAlpha(0) end)
  r:SetScript("OnClick", function(self) Select(self.key) end)
  win.rows[i] = r
  return r
end

-- one card (pooled)
local function Card(St, i)
  local c = win.cards[i]
  if c then return c end
  local C = St.C or {}
  local F = ns.F or { body = 13, label = 12 }
  c = CreateFrame("Frame", nil, win.holder)
  c.bg = St.Solid(c, "BACKGROUND", C.cardFill); c.bg:SetAllPoints()
  if St.Border then St.Border(c, C.cardEdge) end
  c.pill = St.Pill(c, "", C.fg)
  c.title = St.Text(c, F.body, C.fg, true)
  c.title:SetJustifyH("LEFT"); c.title:SetJustifyV("TOP")
  c.body = St.Text(c, F.label, C.text)
  c.body:SetJustifyH("LEFT"); c.body:SetJustifyV("TOP")
  c.more = St.Button(c, "", 0, MORE_H, "ghost", function(self)
    local id = self.id
    if not id then return end
    win.expanded[id] = not win.expanded[id] or nil
    Layout()
  end)
  win.cards[i] = c
  return c
end

-- a card's layout at width w -> its height
local function FitCard(St, c, w, it)
  local C = St.C or {}
  local fr = Fr()
  local inner = w - 2 * CARD_PAD
  local k = KIND[it.kind]
  c.pill:Set(fr and k[1] or k[2], C[k[3]] or C.fg)
  c.pill:ClearAllPoints(); c.pill:SetPoint("TOPLEFT", c, "TOPLEFT", CARD_PAD, -CARD_PAD)
  local ok, ph = pcall(c.pill.GetHeight, c.pill)
  local y = CARD_PAD + ((ok and type(ph) == "number" and ph > 0) and ph or 17) + 8
  c.title:SetText(it.title)
  c.title:ClearAllPoints(); c.title:SetPoint("TOPLEFT", c, "TOPLEFT", CARD_PAD, -y)
  y = y + Fit(St, c.title, inner, 0, c)
  c.title:Show()
  c.more.id = nil
  c.more:Hide()
  if it.text then
    y = y + 4
    local open = win.expanded[it.id] and true or false
    c.body:SetText(it.text)
    c.body:ClearAllPoints(); c.body:SetPoint("TOPLEFT", c, "TOPLEFT", CARD_PAD, -y)
    -- measured whole first, then folded (the folded fit is the last one, so it holds): a text that
    -- wraps to a 4th line is cut even when its raw width is under 3 lines'
    local full = Fit(St, c.body, inner, 0, c)
    local h = open and full or Fit(St, c.body, inner, LINES, c)
    local cut = open or full > h + 1 or Cut(c.body, inner)
    y = y + h
    c.body:Show()
    if cut then
      c.more.id = it.id
      c.more:SetText(open and (fr and "Voir moins" or "Show less") or (fr and "Voir plus" or "Show more"))
      c.more:ClearAllPoints(); c.more:SetPoint("TOPLEFT", c, "TOPLEFT", CARD_PAD - 8, -(y + 4))
      c.more:Show()
      y = y + 4 + MORE_H
    end
    if cut and not open then win.nCut = win.nCut + 1 end
  else
    c.body:SetText(""); c.body:Hide()
  end
  c.it = it
  return y + CARD_PAD
end

local function Build()
  local St = S()
  if not (St and St.Window) then return end
  local C = St.C or {}
  local F = ns.F or { body = 13, label = 12, meta = 11 }
  local fr = Fr()
  win = St.Window("WLHelperWhatsNew", 900, 600, fr and "Quoi de neuf" or "What's new", nil, WLDTDB, "newsPos",
    { header = St.HEADER_H, minH = 400, size = "workspace" })
  win.OnResize = function() if win.since and Layout then Layout() end end
  win.rows, win.cards, win.texts, win.dates, win.rules = {}, {}, {}, {}, {}
  win.heads = {}
  win.expanded = {}
  win.filter = "all"
  local top = win.ContentTop and win:ContentTop() or 45

  -- the sidebar: its own scroll, a divider at its right
  local side = CreateFrame("Frame", nil, win)
  side:SetPoint("TOPLEFT", 0, -top); side:SetPoint("BOTTOMLEFT", 0, FOOT_H + 1)
  side:SetWidth(SIDE_W)
  local edge = St.Solid(win, "BORDER", C.divider)
  edge:SetPoint("TOPLEFT", SIDE_W, -top); edge:SetPoint("BOTTOMLEFT", SIDE_W, FOOT_H + 1); edge:SetWidth(1)
  local ssa = St.ScrollArea and St.ScrollArea(side)
  local sh = ssa and ssa.child or CreateFrame("Frame", nil, side)
  if ssa then ssa:SetPoint("TOPLEFT", 0, -8); ssa:SetPoint("BOTTOMRIGHT", 0, 8)
  else sh:SetPoint("TOPLEFT", 0, -8); sh:SetPoint("BOTTOMRIGHT", 0, 8) end
  sh:SetWidth(SIDE_W)
  win.side, win.sideSA, win.sideHolder = side, ssa, sh
  win.sideHead = St.Text(sh, F.meta, C.muted)
  win.sideHead:SetJustifyH("LEFT"); win.sideHead:SetWordWrap(false)
  win.sideHead:SetText("Versions")

  -- the main pane: summary and filter, a rule, the cards
  local main = CreateFrame("Frame", nil, win)
  main:SetPoint("TOPLEFT", SIDE_W + 1, -top); main:SetPoint("BOTTOMRIGHT", 0, FOOT_H + 1)
  win.main = main
  win.summary = St.Text(main, F.body, C.fg)
  win.summary:SetJustifyH("LEFT"); win.summary:SetJustifyV("TOP")
  win.summary:SetPoint("TOPLEFT", PAD, -14)
  local opts = {}
  for _, f in ipairs(FILTERS) do opts[#opts + 1] = { f[1], fr and f[2] or f[3] } end
  win.filterBar = St.Segmented(main, opts, function() return win.filter end, SetFilter, 24)
  win.filterBar:SetPoint("TOPLEFT", PAD, -(TOP_H - 12 - 24))
  local rule = St.Rule(main)
  rule:SetPoint("TOPLEFT", 0, -TOP_H); rule:SetPoint("TOPRIGHT", 0, -TOP_H)
  local sa = St.ScrollArea and St.ScrollArea(main)
  local holder = sa and sa.child or CreateFrame("Frame", nil, main)
  if sa then sa:SetPoint("TOPLEFT", PAD, -(TOP_H + 1)); sa:SetPoint("BOTTOMRIGHT", -PAD, 0)
  else holder:SetPoint("TOPLEFT", PAD, -(TOP_H + 1)); holder:SetPoint("BOTTOMRIGHT", -PAD, 0) end
  win.sa, win.holder = sa, holder
  win.empty = St.Text(holder, F.label, C.muted)
  win.empty:SetJustifyH("LEFT")

  -- the footer: the switch, "Fermer"
  local foot = CreateFrame("Frame", nil, win)
  foot:SetPoint("BOTTOMLEFT", 0, 0); foot:SetPoint("BOTTOMRIGHT", 0, 0); foot:SetHeight(FOOT_H)
  local frule = St.Rule(foot)
  frule:SetPoint("TOPLEFT", 0, 0); frule:SetPoint("TOPRIGHT", 0, 0)
  local swRow = CreateFrame("Frame", nil, foot)
  swRow:SetPoint("LEFT", PAD, 0); swRow:SetHeight(28)
  local swText = fr and "Ne plus afficher à la connexion" or "Don't show at login"
  win.autoSwitch = St.Switch(swRow, function() return WLDTDB and WLDTDB.newsNoAuto end,
    function(v) if WLDTDB then WLDTDB.newsNoAuto = v and true or nil end end,
    { swText, fr and "Tu peux toujours l'ouvrir avec l'étoile de la fenêtre WL Helper ou /wlh nouveautes."
      or "You can still open it with the star of the WL Helper window or /wlh news." })
  win.autoSwitch:SetPoint("LEFT", 0, 0)
  win.autoLabel = St.Text(swRow, F.label, C.text)
  win.autoLabel:SetJustifyH("LEFT"); win.autoLabel:SetWordWrap(false)
  win.autoLabel:SetText(swText)
  win.autoLabel:SetPoint("LEFT", win.autoSwitch, "RIGHT", 8, 0)
  local lw = ns.TextWidth and ns.TextWidth(win.autoLabel)
  lw = (type(lw) == "number" and lw > 0) and math.ceil(lw) + 2 or 220
  win.autoLabel:SetWidth(lw)
  swRow:SetWidth(40 + 8 + lw)
  if win.autoSwitch.AttachRow then win.autoSwitch:AttachRow(swRow) end
  -- 24 px from the right: the resize grip keeps its corner
  win.closeBtn = St.Button(foot, fr and "Fermer" or "Close", 96, 28, "secondary", function() win:Hide() end)
  win.closeBtn:SetPoint("RIGHT", -24, 0)
  win.foot = foot
end

Layout = function()
  local St = S()
  if not (St and win) then return end
  local C = St.C or {}
  local F = ns.F or { heading = 14, body = 13, label = 12, meta = 11 }
  local fr = Fr()
  local since = win.since or 0
  local list = ns.WHATSNEW or {}
  local unseen = Unseen(since)
  if win.sel == "unseen" and #unseen == 0 then win.sel = nil end
  if win.sel ~= "unseen" then
    local found
    for _, e in ipairs(list) do if e.v == win.sel then found = true end end
    if not found then win.sel = list[1] and list[1].v end
  end

  -- sizes from the window (the rule's default while the frame cannot tell)
  local W = win.GetWidth and win:GetWidth()
  if type(W) ~= "number" or (issecretvalue and issecretvalue(W)) or W < 400 then
    W = (win.SizeRule and win:SizeRule()) or 900
  end
  W = math.floor(W)
  local CW = W - SIDE_W - 1 - 2 * PAD
  win.W, win.CW = W, CW

  -- sidebar
  local y, n = 0, 0
  local function Row(key, name, meta, dot)
    n = n + 1
    local r = SideRow(St, n)
    r.key = key
    r.name:SetText(name); r.meta:SetText(meta or "")
    r.dot:SetShown(dot and true or false)
    r.sel:SetShown(win.sel == key)
    local c = (win.sel == key) and C.fg or C.text or C.fg
    if c then r.name:SetTextColor(c[1], c[2], c[3]) end
    r:ClearAllPoints()
    r:SetPoint("TOPLEFT", win.sideHolder, "TOPLEFT", 8, -y)
    r:SetWidth(SIDE_W - 16)
    r:Show()
    y = y + ROW_H + ROW_GAP
  end
  local total = 0
  for _, e in ipairs(unseen) do total = total + #Items(e) end
  if #unseen > 0 then
    Row("unseen", fr and "Depuis ta connexion" or "Since your last login",
      fr and Plural(total, "nouveauté", "nouveautés") or Plural(total, "change", "changes"), false)
    y = y + 8
  end
  win.sideHead:ClearAllPoints(); win.sideHead:SetPoint("TOPLEFT", win.sideHolder, "TOPLEFT", 20, -(y + 4))
  win.sideHead:SetWidth(SIDE_W - 40)
  y = y + 24
  for _, e in ipairs(list) do
    Row(e.v, Short(e.v), DateText(e.date) or "", Key(e.v) > since)
  end
  for k = n + 1, #win.rows do win.rows[k]:Hide() end
  win.nRows = n
  if win.sideSA and win.sideSA.SetContentHeight then win.sideSA:SetContentHeight(y) else win.sideHolder:SetHeight(y) end

  -- which versions, the summary
  local shownList = {}
  if win.sel == "unseen" then shownList = unseen
  else for _, e in ipairs(list) do if e.v == win.sel then shownList = { e } end end end
  local sum
  if win.sel == "unseen" then
    local range = Short(unseen[#unseen].v)
    if #unseen > 1 then range = range .. " → " .. Short(unseen[1].v) end
    sum = fr and (Plural(total, "nouveauté", "nouveautés") .. " depuis ta dernière connexion (" .. range .. ")")
      or (Plural(total, "change", "changes") .. " since your last login (" .. range .. ")")
  elseif shownList[1] then
    local e = shownList[1]
    local cnt = #Items(e)
    local d = DateText(e.date)
    sum = fr and (Plural(cnt, "changement", "changements") .. " dans la version " .. Short(e.v) .. (d and (", le " .. d) or ""))
      or (Plural(cnt, "change", "changes") .. " in " .. Short(e.v) .. (d and (", " .. d) or ""))
  end
  win.summary:SetText(sum or "")
  win.summary:SetWidth(math.max(100, math.min(CW, 600)))
  if win.summary.SetMaxLines then win.summary:SetMaxLines(1) end
  win.summaryText = sum
  if win.filterBar.SetMaxWidth then win.filterBar:SetMaxWidth(CW) end
  win.filterBar:Update()
  if win.subtitle then
    local before = list[#unseen + 1]
    win.subtitle:SetText((win.sel == "unseen" and before) and ((fr and "Depuis la version " or "Since version ") .. before.v) or "")
  end

  -- the cards
  local cols = (ns.Cols or St.Cols)(CW, CARD_MIN, GAP, MAX_COLS, 200)
  local gridW = math.min(CW, cols * CARD_MAX + (cols - 1) * GAP)
  win.cols, win.gridW = cols, gridW
  win.texts = {}
  win.nCut = 0
  win.shownIds = {}
  local nh, nd, nr, nc = 0, 0, 0, 0
  local function Head(text, at, w)
    nh = nh + 1
    local fs = win.heads[nh]
    if not fs then
      fs = St.Text(win.holder, F.heading, C.fg)
      fs:SetJustifyH("LEFT"); fs:SetJustifyV("TOP")
      win.heads[nh] = fs
    end
    fs:SetText(text)
    fs:ClearAllPoints(); fs:SetPoint("TOPLEFT", win.holder, "TOPLEFT", 0, -at)
    local h = Fit(St, fs, w, 2, win.holder)
    fs:Show()
    win.texts[#win.texts + 1] = fs
    return h
  end
  local function Date(text, at)
    nd = nd + 1
    local fs = win.dates[nd]
    if not fs then
      fs = St.Text(win.holder, F.meta, C.muted)
      fs:SetJustifyH("RIGHT"); fs:SetJustifyV("TOP"); fs:SetWordWrap(false)
      win.dates[nd] = fs
    end
    local c = C.muted or { 0.6, 0.6, 0.6 }
    fs:SetTextColor(c[1], c[2], c[3], 1)
    fs:SetText(text)
    local w = ns.TextWidth and ns.TextWidth(fs)
    if not (type(w) == "number" and w > 0) then w = #text * 6 end
    w = math.ceil(w) + 2
    fs:SetWidth(w)
    fs:ClearAllPoints()
    -- 14 px version, 11 px date: the date sits on the version's baseline
    fs:SetPoint("TOPRIGHT", win.holder, "TOPLEFT", gridW, -(at + (F.heading - F.meta)))
    fs:Show()
    return w
  end
  local function Rule(at)
    nr = nr + 1
    local r = win.rules[nr]
    if not r then r = St.Rule(win.holder); win.rules[nr] = r end
    r:ClearAllPoints()
    r:SetPoint("TOPLEFT", win.holder, "TOPLEFT", 0, -at)
    r:SetPoint("TOPRIGHT", win.holder, "TOPLEFT", gridW, -at)
    r:Show()
  end
  local grid = win.grid or (ns.Grid or St.Grid)()
  win.grid = grid
  y = 12
  local versions, lastDate = 0, nil
  for _, e in ipairs(shownList) do
    local items = Items(e, win.filter)
    if #items > 0 then
      versions = versions + 1
      if versions > 1 then
        y = y + VERSION_GAP; Rule(y); y = y + 1 + VERSION_GAP
      end
      -- the date once per day: a version from the same day as the one above it shows none
      local date = DateText(e.date)
      if date and date == lastDate then date = nil elseif date then lastDate = date end
      local dw = date and Date(date, y) or 0
      y = y + Head("Version " .. e.v, y, gridW - (dw > 0 and dw + 12 or 0)) + 12
      grid:Begin(win.holder, 0, y, gridW, { minW = CARD_MIN, gap = GAP, rowGap = GAP, maxCols = MAX_COLS, minPx = 200 })
      for _, it in ipairs(items) do
        nc = nc + 1
        local c = Card(St, nc)
        c:Show()
        grid:Add(c, function(frame, w)
          local h = FitCard(St, frame, w, it)
          frame:SetHeight(h)
          return h
        end)
        win.texts[#win.texts + 1] = c.title
        if c.body:IsShown() then win.texts[#win.texts + 1] = c.body end
        win.shownIds[#win.shownIds + 1] = it.id
      end
      local gh = grid:End()
      win.lastCols = grid.n
      y = y + gh
    end
  end
  if versions == 0 then
    -- a filter that leaves nothing points back to "Tout"; with "Tout" itself there is just no note
    local msg
    if win.filter ~= "all" then
      msg = fr and "Rien de ce type ici. Choisis « Tout » pour tout revoir." or "Nothing of this kind here. Pick \"All\" to see everything."
    else
      msg = fr and "Pas encore de notes pour cette version." or "No notes for this version yet."
    end
    win.empty:SetText(msg)
    win.empty:ClearAllPoints(); win.empty:SetPoint("TOPLEFT", win.holder, "TOPLEFT", 0, -y)
    y = y + Fit(St, win.empty, math.min(CW, 320), 2, win.holder)
    win.empty:Show()
  else
    win.empty:Hide()
  end
  for k = nh + 1, #win.heads do win.heads[k]:Hide() end
  for k = nd + 1, #win.dates do win.dates[k]:Hide() end
  for k = nr + 1, #win.rules do win.rules[k]:Hide() end
  for k = nc + 1, #win.cards do win.cards[k]:Hide() end
  win.nCards, win.nVersions = nc, versions
  y = math.ceil(y + 12)
  win.holder:SetWidth(CW)
  win.holder:SetHeight(y)
  if win.sa and win.sa.SetContentHeight then win.sa:SetContentHeight(y) end
  if win.FitHeight then win:FitHeight(y) end
end

-- sinceVersion: the version seen before the update (WLDTDB.newsFrom); older than every entry
-- shows them all as unseen, nil none. The unseen versions open merged; with none, the newest one.
function ns.ShowWhatsNew(sinceVersion)
  if not win then Build() end
  if not win then return end
  -- no version recorded yet (fresh install, the star before any update): nothing counts as unseen,
  -- the newest version opens (not every version as "depuis ta dernière connexion")
  local newest = ns.WHATSNEW and ns.WHATSNEW[1]
  win.since = (sinceVersion == nil and newest) and Key(newest.v) or Key(sinceVersion)
  win.sel = (#Unseen(win.since) > 0) and "unseen" or nil
  win.filter = "all"
  if win.sa and win.sa.ScrollTo then win.sa:ScrollTo(0, true) end
  if win.autoSwitch and win.autoSwitch.Update then win.autoSwitch:Update() end
  Layout()
  win:Show()
end
ns.WhatsNewSelect = Select       -- for the offline tests (a click on a sidebar row)
ns.WhatsNewFilter = SetFilter    -- (a click on a filter)

local ev = CreateFrame("Frame")
pcall(ev.RegisterEvent, ev, "PLAYER_LOGIN")
-- first install: no list (the welcome screen speaks); an update: what changed since then, once
-- (unless "Ne plus afficher à la connexion" is on: the star and /wlh nouveautes still open it).
-- In combat the version stays unseen and the window waits for the end of the fight.
local function CheckUpdate()
  if not WLDTDB then return end
  local cur = Cur()
  local seen = WLDTDB.seenVersion
  if not seen or seen == cur or Key(cur) <= Key(seen) then WLDTDB.seenVersion = cur; return end
  WLDTDB.newsFrom = seen   -- the star button and /wlh nouveautes start from there too
  if WLDTDB.newsNoAuto then WLDTDB.seenVersion = cur; return end
  if InCombatLockdown() then pcall(ev.RegisterEvent, ev, "PLAYER_REGEN_ENABLED"); return end
  WLDTDB.seenVersion = cur
  ns.ShowWhatsNew(seen)
end
ns.WhatsNewCheck = CheckUpdate   -- for the offline tests
ev:SetScript("OnEvent", function(self, event)
  if event == "PLAYER_REGEN_ENABLED" then
    pcall(self.UnregisterEvent, self, "PLAYER_REGEN_ENABLED")
    CheckUpdate()
    return
  end
  if event == "PLAYER_LOGIN" then C_Timer.After(8, CheckUpdate) end
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
