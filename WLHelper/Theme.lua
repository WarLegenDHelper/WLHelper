-- Theme.lua: WL Helper's design tokens and the primitives every window is drawn with (the guide and
-- the Writs modules). One palette (ns.Tok), one type scale (ns.F), one spacing scale (ns.SP), the HD
-- icons, 1-physical-pixel borders, text that wraps or shows its full text in the tooltip, and the
-- tooltip itself. Writs/Style.lua builds the components (S.*) on top of these.
local ADDON, ns = ...

-- =====================================================================
--  Tokens (docs: design system, section 1). Widgets use these names only.
-- =====================================================================
local ACC = { 0.808, 0.098, 0.094 }        -- WaR LegenD red #CE1918
local T = {
  -- base neutrals
  bg       = { 0.106, 0.118, 0.137, 0.97 }, -- #1B1E23 window backdrop (lifted: easier to read)
  panel    = { 0.133, 0.149, 0.173, 0.97 }, -- #22262C inputs, dropdown lists, tooltips
  line     = { 0.220, 0.239, 0.271, 1 },    -- #383D45 rule under the header, input borders
  trackOff = { 0.290, 0.310, 0.341, 1 },    -- #4A4F57 switch off, scrollbar thumb
  fg       = { 0.941, 0.945, 0.953 },       -- #F0F1F3 main text, titles
  text     = { 0.831, 0.843, 0.863 },       -- #D4D7DC body sentences
  muted    = { 0.655, 0.675, 0.706 },       -- #A7ACB4 meta, descriptions, icons at rest
  faint    = { 0.482, 0.502, 0.533 },       -- #7B8088 disabled, placeholders
  -- accent
  accent      = { ACC[1], ACC[2], ACC[3] }, -- #CE1918
  accentHover = { 0.878, 0.188, 0.180 },    -- #E0302E
  accentPress = { 0.659, 0.078, 0.071 },    -- #A81412
  accentSoft  = { 0.910, 0.376, 0.353 },    -- #E8605A links, selected text
  hint        = { 0.659, 0.733, 0.835 },    -- #A8BBD5 "Click: ..." lines in tooltips (calm, not an alert)
  -- semantic
  ok   = { 0.298, 0.816, 0.478 },           -- #4CD07A
  warn = { 0.984, 0.573, 0.235 },           -- #FB923C
  bad  = { 0.973, 0.443, 0.443 },           -- #F87171
  gold = { 0.902, 0.800, 0.502 },           -- #E6CC80
  info = { 0.478, 0.722, 0.961 },           -- #7AB8F5
  silver = { 0.800, 0.820, 0.860 },         -- #CCD1DB rare mobs (frame and icon)
  head = { 0.902, 0.800, 0.502 },           -- = gold: block headings inside cards (ns.TyHeading)
  -- alpha layers (white or black over bg)
  cardFill     = { 1, 1, 1, 0.045 },
  cardEdge     = { 1, 1, 1, 0.09 },   -- a light edge: the cards stand out from the backdrop
  divider      = { 1, 1, 1, 0.08 },
  hoverFill    = { 1, 1, 1, 0.05 },
  pressFill    = { 0, 0, 0, 0.35 },
  btnFill      = { 1, 1, 1, 0.04 },
  btnEdge      = { 1, 1, 1, 0.26 },
  btnEdgeHover = { 1, 1, 1, 0.40 },
  selFill      = { ACC[1], ACC[2], ACC[3], 0.14 },
  tabFill      = { ACC[1], ACC[2], ACC[3], 0.12 },
  tabHover     = { ACC[1], ACC[2], ACC[3], 0.06 },
  zebraA       = { 0, 0, 0, 0.10 },
  zebraB       = { 0, 0, 0, 0.18 },
  scrim        = { 0, 0, 0, 0.55 },
  disabledAlpha = 0.35,
  -- fonts (the client's standard face; the heading weight is the same face)
  font = STANDARD_TEXT_FONT, bold = STANDARD_TEXT_FONT,
}
-- Older names still read by the windows: each is one of the tokens above (opaque versions of the
-- alpha layers where the old code paints them with alpha 1). No new code uses them.
T.dim       = T.muted
T.brand     = T.accent
T.brandHi   = T.accentHover
T.brandSoft = T.accentSoft
T.ready     = T.ok
T.danger    = T.bad
T.border    = T.cardEdge
T.header    = { 0.106, 0.118, 0.137, 1 }       -- = bg, opaque: no title-bar colour of its own
T.card      = { 0.146, 0.158, 0.176, 1 }       -- = cardFill over bg
T.hover     = { 0.151, 0.162, 0.180, 1 }       -- = hoverFill over bg
T.brandBg   = { 0.204, 0.115, 0.131, 1 }       -- = selFill over bg (never a solid red block)
T.kind = { a = { 1.00, 0.80, 0.25 }, c = { 0.40, 0.72, 1.00 }, o = { 0.40, 0.72, 1.00 }, t = { 0.35, 0.90, 0.48 },
           h = { 0.95, 0.95, 0.95 }, i = { 0.80, 0.60, 1.00 } }

-- ns.T is the quest-text translator (Locale.lua): the token table is ns.Tok (ns.T_ for older code).
ns.Tok = T
ns.T_ = T

-- Type scale (1.2) and spacing scale (1.3).
ns.F = { title = 16, hero = 20, heading = 14, body = 13, label = 12, meta = 11, foot = 10 }
ns.SP = { xxs = 2, xs = 4, sm = 8, md = 12, lg = 16, xl = 24 }

local EUI = "Interface\\AddOns\\EllesmereUI\\media\\fonts\\"
local fonts, accents = {}, {}
ns.skin = nil

function ns.IsLoaded(name)
  if C_AddOns and C_AddOns.IsAddOnLoaded then return C_AddOns.IsAddOnLoaded(name) end
  return IsAddOnLoaded and IsAddOnLoaded(name)
end

local function secret(v) return issecretvalue ~= nil and issecretvalue(v) end
ns.IsSecret = secret

-- Readable(v): true when our (always tainted) code may compare, join, format, count or use v as a
-- table key. canaccessvalue is the strict test (a value can be unreadable without being a secret);
-- issecretvalue the older one; on a client with neither, every value is readable.
function ns.Readable(v)
  if canaccessvalue then
    local ok, r = pcall(canaccessvalue, v)
    return ok and r == true
  end
  if issecretvalue then
    local ok, r = pcall(issecretvalue, v)
    return ok and r == false
  end
  return true
end
-- SenderKey(name): the key a player's data is kept under when it comes from the network. A player
-- of my realm (or a name with no realm) by the name alone, as always; a player of another realm as
-- "Name-Realm", so a namesake from a connected realm never writes over a member's entry. nil for a
-- secret, empty or malformed value (the handlers then drop the message).
local function RealmOnly(r) return (tostring(r or ""):gsub("[%s%-']", ""):lower()) end
function ns.SenderKey(n)
  if type(n) ~= "string" or secret(n) or not ns.Readable(n) or n == "" or #n > 64 or n:find("[|%c]") then return nil end
  local name, realm = n:match("^([^%-%s]+)[%-%s](.*)$")
  if not name then return n end
  realm = RealmOnly(realm)
  if realm == "" then return name end
  local mine = GetNormalizedRealmName and GetNormalizedRealmName()
  mine = (type(mine) == "string" and ns.Readable(mine)) and RealmOnly(mine) or ""
  local full = GetRealmName and GetRealmName()
  full = (type(full) == "string" and ns.Readable(full)) and RealmOnly(full) or ""
  if (mine == "" and full == "") or realm == mine or realm == full then return name end
  -- the realm as the game wrote it (spaces out), so an invite or a whisper to the key still works
  return name .. "-" .. n:match("^[^%-%s]+[%-%s](.*)$"):gsub("%s", "")
end
-- NameIs(field, sender): a name written inside a message names its sender (sender is a SenderKey).
-- Copies send their own name without the realm: that short form is accepted for the sender, and
-- the data is then kept under the sender's key, never under the bare name.
function ns.NameIs(field, sender)
  if type(field) ~= "string" or type(sender) ~= "string" or secret(field) or not ns.Readable(field) then return false end
  if field == sender or ns.SenderKey(field) == sender then return true end
  return not field:find("[%-%s]") and field == sender:match("^([^%-%s]+)")
end
-- the same for several values at once (geometry, multiple returns)
function ns.ReadableAll(...)
  if canaccessallvalues then
    local ok, r = pcall(canaccessallvalues, ...)
    return ok and r == true
  end
  for i = 1, select("#", ...) do
    if not ns.Readable((select(i, ...))) then return false end
  end
  return true
end

function ns.Hex(c)
  local function b(v) return math.floor(math.max(0, math.min(1, v)) * 255 + 0.5) end
  return ("|cff%02x%02x%02x"):format(b(c[1]), b(c[2]), b(c[3]))
end

-- =====================================================================
--  Motion: one shared driver, stopped as soon as nothing moves.
-- =====================================================================
local tweens, pendingTweens, stepping = {}, {}, false
local driver = CreateFrame("Frame")
local function TweenStep(_, elapsed)
  stepping = true
  local alive = false
  for key, a in pairs(tweens) do
    a.t = a.t + (elapsed or 0)
    local p = a.dur > 0 and math.min(1, a.t / a.dur) or 1
    a.fn(a.from + (a.to - a.from) * p)
    if p >= 1 then tweens[key] = nil else alive = true end
  end
  stepping = false
  for key, a in pairs(pendingTweens) do tweens[key] = a; pendingTweens[key] = nil; alive = true end
  if not alive then driver:SetScript("OnUpdate", nil) end
end
-- ns.Tween(key, from, to, seconds, fn(v)): fn runs now with `from`, then every frame up to `to`.
-- A new tween on the same key replaces the old one.
function ns.Tween(key, from, to, dur, fn)
  fn(from)
  if from == to or not dur or dur <= 0 then fn(to); tweens[key] = nil; return end
  local a = { t = 0, dur = dur, from = from, to = to, fn = fn }
  if stepping then pendingTweens[key] = a else tweens[key] = a end
  driver:SetScript("OnUpdate", TweenStep)
end
function ns.StopTween(key) tweens[key] = nil; pendingTweens[key] = nil end

-- One state helper for every widget: rest / hover / pressed / disabled / selected.
function ns.State(widget, state)
  if widget and widget.ApplyState then widget:ApplyState(state) end
end

-- =====================================================================
--  Pixels: every border and rule is exactly one physical pixel.
-- =====================================================================
function ns.Px(frame)
  local factor
  if PixelUtil and PixelUtil.GetPixelToUIUnitFactor then
    local ok, v = pcall(PixelUtil.GetPixelToUIUnitFactor)
    if ok and type(v) == "number" and v > 0 then factor = v end
  end
  if not factor and GetPhysicalScreenSize then
    local ok, _, h = pcall(GetPhysicalScreenSize)
    if ok and type(h) == "number" and h > 0 then factor = 768 / h end
  end
  if not factor then return 1 end
  local scale = frame and frame.GetEffectiveScale and frame:GetEffectiveScale()
  if type(scale) ~= "number" or secret(scale) or scale <= 0 then scale = 1 end
  return factor / scale
end

local lines1px = setmetatable({}, { __mode = "k" })  -- texture -> { frame, horizontal }
local function FitLine(t, info)
  local px = ns.Px(info[1])
  if info[2] then t:SetHeight(px) else t:SetWidth(px) end
end
-- Registers a texture as a 1 px line (horizontal: its height is set; else its width).
function ns.PixelLine(frame, t, horizontal)
  local info = { frame, horizontal and true or false }
  lines1px[t] = info
  FitLine(t, info)
  return t
end
function ns.RefitPixels()
  for t, info in pairs(lines1px) do FitLine(t, info) end
end
do
  local pe = CreateFrame("Frame")
  for _, e in ipairs({ "UI_SCALE_CHANGED", "DISPLAY_SIZE_CHANGED", "PLAYER_ENTERING_WORLD" }) do pcall(pe.RegisterEvent, pe, e) end
  pe:SetScript("OnEvent", function() ns.RefitPixels() end)
end

function ns.Tex(parent, layer, c)
  local t = parent:CreateTexture(nil, layer or "BACKGROUND")
  t:SetColorTexture(c[1], c[2], c[3], c[4] or 1)
  return t
end
local Tex = ns.Tex

-- A 1 px outline on the four sides; returns a setter setter(color, alpha).
function ns.Outline(frame, c, a, layer)
  local edges = {}
  for i, p in ipairs({ { "TOPLEFT", "TOPRIGHT" }, { "BOTTOMLEFT", "BOTTOMRIGHT" }, { "TOPLEFT", "BOTTOMLEFT" }, { "TOPRIGHT", "BOTTOMRIGHT" } }) do
    local t = frame:CreateTexture(nil, layer or "BORDER")
    t:SetColorTexture(c[1], c[2], c[3], a or c[4] or 1)
    t:SetPoint(p[1]); t:SetPoint(p[2])
    ns.PixelLine(frame, t, i <= 2)
    edges[i] = t
  end
  local function set(c2, a2)
    for _, t in ipairs(edges) do t:SetColorTexture(c2[1], c2[2], c2[3], a2 or c2[4] or 1) end
  end
  return set, edges
end

-- A horizontal 1 px rule (divider) across a frame; anchor it yourself or pass y from the top.
function ns.Rule(frame, c, layer)
  local t = frame:CreateTexture(nil, layer or "BORDER")
  local col = c or T.divider
  t:SetColorTexture(col[1], col[2], col[3], col[4] or 1)
  ns.PixelLine(frame, t, true)
  return t
end

-- =====================================================================
--  HD icons (Media/Icons/<name>.tga, white 128 px, tinted with SetVertexColor)
-- =====================================================================
ns.ICONS = "Interface\\AddOns\\" .. ADDON .. "\\Media\\Icons\\"
ns.ARROW = "Interface\\AddOns\\" .. ADDON .. "\\Media\\Arrow"
ns.LOGO = "Interface\\AddOns\\" .. ADDON .. "\\Media\\Logo64"
ns.HD_NAMES = {}
for _, n in ipairs({ "check", "close", "plus", "minus", "chevron_right", "chevron_left", "chevron_down", "chevron_up",
  "home", "gear", "search", "refresh", "pin", "star", "info", "warning", "clock", "bag", "trash", "filter", "user",
  "group", "mail", "coin", "calendar", "hammer", "shield", "heal", "sword", "arrow_up", "arrow_down", "external", "dot",
  "flag", "portal", "skull", "ring" }) do ns.HD_NAMES[n] = true end

function ns.IconPath(name) return ns.ICONS .. name end

-- Sets an HD icon on a texture (kept sharp from 12 to 32 px) and tints it.
function ns.SetHDIcon(tex, name, color, alpha)
  if not tex then return end
  local path = (name and name:find("\\", 1, true)) and name or ns.IconPath(name or "dot")
  local ok = pcall(tex.SetTexture, tex, path, nil, nil, "TRILINEAR")
  if not ok then tex:SetTexture(path) end
  if tex.SetTexCoord then tex:SetTexCoord(0, 1, 0, 1) end
  if tex.SetSnapToPixelGrid then pcall(tex.SetSnapToPixelGrid, tex, false) end
  if tex.SetTexelSnappingBias then pcall(tex.SetTexelSnappingBias, tex, 0) end
  tex.wlIcon = name
  local c = color or T.muted
  tex:SetVertexColor(c[1], c[2], c[3], alpha or c[4] or 1)
  return tex
end

-- ns.Icon(parent, name, size, layer, color) -> texture with the HD icon.
function ns.Icon(parent, name, size, layer, color)
  local t = parent:CreateTexture(nil, layer or "ARTWORK")
  t:SetSize(size or 16, size or 16)
  ns.SetHDIcon(t, name, color)
  return t
end

-- Painted game icons (items, professions, classes...): cropped 0.08-0.92, never above 48 px.
function ns.SetPainted(tex, path, size)
  tex:SetTexture(path)
  tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  if size then size = math.min(48, size); tex:SetSize(size, size) end
  return tex
end

-- =====================================================================
--  Text
-- =====================================================================
local function SetFont(fs)
  local ok = pcall(fs.SetFont, fs, fs._bold and T.bold or T.font, fs._size, fs._flags)
  if not ok or not fs:GetFont() then fs:SetFont(STANDARD_TEXT_FONT, fs._size, fs._flags) end
end
ns.SetFont = SetFont

-- Text over the 3D world (GPS HUD, floating labels) keeps a shadow; panel text has none.
function ns.Shadow(fs, on)
  if on == false then fs:SetShadowColor(0, 0, 0, 0); fs:SetShadowOffset(0, 0)
  else fs:SetShadowColor(0, 0, 0, 0.9); fs:SetShadowOffset(1, -1) end
end
local function WorldParent(parent)
  if not parent then return false end
  if parent.wlWorld then return true end
  local n = parent.GetName and parent:GetName()
  return type(n) == "string" and n:find("^WLGPS") ~= nil
end
ns.WorldParent = WorldParent

-- ns.Text(parent, size, color, bold, flags): flags are font flags ("OUTLINE"...), plus the word
-- "SHADOW" for text drawn over the world. Guide paragraphs wrap without a line limit.
function ns.Text(parent, size, color, bold, flags)
  local fs = parent:CreateFontString(nil, "OVERLAY")
  local shadow = false
  if type(flags) == "string" and flags:find("SHADOW", 1, true) then
    shadow = true
    flags = flags:gsub(",?%s*SHADOW", ""):gsub("^,", "")
  end
  fs._size, fs._flags, fs._bold = size, flags or "", bold
  ns.Shadow(fs, shadow or WorldParent(parent))
  SetFont(fs)
  local c = color or T.text
  fs:SetTextColor(c[1], c[2], c[3], c[4] or 1)
  fs:SetJustifyH("LEFT"); fs:SetJustifyV("TOP")
  fs:SetWordWrap(true)
  fs.wlOwned = true
  table.insert(fonts, fs)
  return fs
end

-- ns.TextWidth(fs [, text] [, onLate]): the width the words of `fs` need on ONE line, whatever
-- width the FontString has right now. Measured on a hidden twin FontString with fs's own font
-- (GetUnboundedStringWidth when the client has it): the FontString's own GetStringWidth is bounded
-- by its current width and gave "In..." labels. `text` measures other words with fs's font.
-- When the font lands late (the next frame), onLate(w) runs then with the new measure so the
-- caller can size its widget again.
local twin
local function Twin()
  if not twin and UIParent and UIParent.CreateFontString then
    twin = UIParent:CreateFontString(nil, "OVERLAY"); twin:Hide()
    ns._chipMeasure = twin
  end
  return twin
end
local function MeasureOn(m, getName)
  local fn = m[getName]
  if type(fn) ~= "function" then return nil end
  local ok, w = pcall(fn, m)
  if ok and type(w) == "number" and not secret(w) then return w end
end
function ns.TextWidth(fs, text, onLate)
  if not fs then return 0 end
  if text == nil then
    local ok, t = pcall(fs.GetText, fs)
    text = (ok and type(t) == "string" and not secret(t)) and t or ""
  end
  if type(text) ~= "string" or text == "" then return 0 end
  local w
  local m = Twin()
  local okF, font, size, flags = pcall(fs.GetFont, fs)
  if m and okF and type(font) == "string" and not secret(font) then
    if pcall(m.SetFont, m, font, size, flags or "") then
      pcall(m.SetText, m, text)
      w = MeasureOn(m, "GetUnboundedStringWidth") or MeasureOn(m, "GetStringWidth")
    end
  end
  if not w or w <= 0 then
    -- no twin or no font yet: the FontString itself, unbounded when the client can
    local okT, cur = pcall(fs.GetText, fs)
    if not okT or secret(cur) then cur = nil end
    local swap = cur ~= text
    if swap then pcall(fs.SetText, fs, text) end
    w = MeasureOn(fs, "GetUnboundedStringWidth") or MeasureOn(fs, "GetStringWidth") or 0
    if swap then pcall(fs.SetText, fs, cur) end
  end
  w = math.ceil(w)
  if onLate and C_Timer and C_Timer.After then
    C_Timer.After(0, function()
      local w2 = ns.TextWidth(fs, text)
      if w2 ~= w and w2 > 0 then onLate(w2) end
    end)
  end
  return w
end

-- Is this FontString cut by the engine ("...")? Secret or unknown values count as "not cut".
function ns.IsCut(fs)
  if not fs then return false end
  if fs.IsTruncated then
    local ok, cut = pcall(fs.IsTruncated, fs)
    if ok and cut ~= nil and not secret(cut) then return cut == true end
  end
  if fs.CanWordWrap then
    local ok, wrap = pcall(fs.CanWordWrap, fs)
    if ok and wrap == true then return false end
  end
  local sw = ns.TextWidth(fs)
  local okW, w = pcall(fs.GetWidth, fs)
  if not okW or type(w) ~= "number" or secret(w) then return false end
  return w > 0 and sw > w + 1
end

-- Labels that cannot grow (tabs, pills, titles, number columns): one line; when the engine cuts
-- it, the owner's tooltip starts with the full text.
local function CutLines(owner)
  local out = {}
  for _, fs in ipairs(owner.wlClamped or {}) do
    local full = fs.wlFull
    if fs.wlFullAuto then
      local ok, t = pcall(fs.GetText, fs)
      full = (ok and not secret(t)) and t or nil
    end
    if full and full ~= "" and fs:IsShown() and ns.IsCut(fs) then out[#out + 1] = full end
  end
  return out
end
ns.CutLines = CutLines

-- Registers fs under its owner: hovering the owner shows the full text of its cut labels.
local function WatchCut(fs, owner)
  owner = owner or (fs.GetParent and fs:GetParent())
  if not owner then return end
  owner.wlClamped = owner.wlClamped or {}
  local known
  for _, x in ipairs(owner.wlClamped) do if x == fs then known = true end end
  if not known then table.insert(owner.wlClamped, fs) end
  if not owner.wlClampHooked and owner.HookScript then
    owner.wlClampHooked = true
    if owner.SetMouseMotionEnabled and owner.IsMouseMotionEnabled then
      local ok, on = pcall(owner.IsMouseMotionEnabled, owner)
      if ok and not on then pcall(owner.SetMouseMotionEnabled, owner, true) end
    end
    pcall(owner.HookScript, owner, "OnEnter", function(self)
      -- the owner's own tooltip already went through ns.ShowTip (which adds the full text)
      if GameTooltip:IsShown() and GameTooltip:GetOwner() == self then return end
      local cut = CutLines(self)
      if #cut > 0 then ns.ShowTip(self, cut) end
    end)
    pcall(owner.HookScript, owner, "OnLeave", function(self)
      if GameTooltip:GetOwner() == self then GameTooltip:Hide() end
    end)
  end
end
ns.WatchCut = WatchCut

local function FullText(fs, given)
  if given ~= nil then return given end
  local ok, t = pcall(fs.GetText, fs)
  return (ok and not secret(t)) and t or nil
end

function ns.ClampLabel(fs, fullText, owner)
  if not fs then return end
  fs:SetWordWrap(false)
  if fs.SetMaxLines then fs:SetMaxLines(1) end
  fs.wlFull = FullText(fs, fullText)
  fs.wlFullAuto = (fullText == nil)
  WatchCut(fs, owner)
end

-- Wrapping text: `maxLines` lines (2 by default; 0 = no limit) at `width` (when given); returns
-- the text height. When even that is not enough the full text goes to the owner's tooltip.
function ns.FitText(fs, maxLines, width, owner)
  if not fs then return 0 end
  if width then fs:SetWidth(width) end
  fs:SetWordWrap(true)
  if fs.SetMaxLines then fs:SetMaxLines(maxLines or 2) end
  fs.wlFull = FullText(fs); fs.wlFullAuto = true
  if (maxLines or 2) > 0 then WatchCut(fs, owner) end
  local okH, h = pcall(fs.GetStringHeight, fs)
  if not okH or type(h) ~= "number" or secret(h) then return 0 end
  return h
end

-- =====================================================================
--  Text structure (design system 3.21): block heading, body, muted line, bullets, facts, stat.
--  Every piece is placed on `parent` at TOPLEFT (x, -y), y counted downward from the parent's top,
--  and returns the height it uses so callers stack: y = y + piece:Place(...). Pieces never take the
--  mouse (no frame, no tooltip hook): they can sit inside a clickable card. Text wraps without a
--  line limit (reading text, 4.1).
-- =====================================================================
ns.TY = {
  -- a heading is one step above the text under it (14 over 13) and gold: size, colour and space
  -- set it apart (the client has one face, so `bold` changes nothing without EllesmereUI's font)
  head = { size = ns.F.heading, color = "head", bold = true, top = 14, bottom = 4, icon = 12, iconGap = 4 },
  body = { size = 13, color = "text" },
  muted = { size = 11, color = "muted" },
  gap = 4,                                    -- between two pieces that are not a heading
  bullet = { dot = 5, indent = 12, gap = 4, color = "muted", mark = 12, markColor = "ok" },
  fact = { size = 12, label = "muted", value = "fg", gap = 8, minValue = 64, stackGap = 2 },
  stat = { size = 12, label = "muted", count = "fg", barTop = 4, bar = 2, subTop = 4,
           track = { 1, 1, 1, 0.08 }, fill = "ok" },
}
local TY = ns.TY
local function Col(c) if type(c) == "string" then return T[c] or T.text end return c or T.text end
local function Str(s) return type(s) == "string" and s ~= "" and not secret(s) end
-- height of a wrapped text at `width`: whole pixels, at least one line when there is text
local function Measure(fs, width, size)
  local h = ns.FitText(fs, 0, width)
  if type(h) ~= "number" or h < size then h = size end
  return math.ceil(h)
end
local function At(r, parent, x, y)
  r:ClearAllPoints(); r:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -y)
end
local function NewFS(parent, size, color, bold)
  local fs = ns.Text(parent, size, Col(color), bold)
  fs:SetJustifyH("LEFT"); fs:SetJustifyV("TOP")
  return fs
end
local function Paint(fs, c) c = Col(c); fs:SetTextColor(c[1], c[2], c[3], c[4] or 1) end

-- ns.TyHeading(parent) -> h. h:Place(text, x, y, width [, opts]) -> used height
--   = (opts.first and 0 or 14) + text height (14 a line) + 4. opts.icon: an HD icon name drawn 12 px in the
--   heading colour before the words (text starts 16 further right). opts.first: no space above.
--   The text itself starts at y + top: h.top tells the caller where it went.
function ns.TyHeading(parent)
  local s = TY.head
  local h = { parent = parent }
  h.fs = NewFS(parent, s.size, s.color, s.bold)
  function h:Place(text, x, y, width, opts)
    opts = opts or {}
    if not Str(text) then self:Hide(); return 0 end
    local top = opts.first and 0 or s.top
    local tx = x
    if opts.icon then
      self.icon = self.icon or parent:CreateTexture(nil, "ARTWORK")
      self.icon:SetSize(s.icon, s.icon)
      ns.SetHDIcon(self.icon, opts.icon, Col(s.color))
      At(self.icon, parent, x, y + top + math.floor((s.size - s.icon) / 2))   -- on the line's middle
      self.icon:Show()
      tx = x + s.icon + s.iconGap
    elseif self.icon then self.icon:Hide() end
    self.fs:SetText(text); Paint(self.fs, opts.color or s.color)
    At(self.fs, parent, tx, y + top)
    local th = Measure(self.fs, width - (tx - x), s.size)
    self.fs:Show()
    self.top, self.textH, self.x = top, th, tx
    return top + th + s.bottom
  end
  function h:Hide() self.fs:Hide(); if self.icon then self.icon:Hide() end end
  return h
end

-- ns.TyBody(parent [, kind]) -> b, kind "body" (13 text, default) or "muted" (11 muted).
-- b:Place(text, x, y, width [, color [, size]]) -> text height (no margin). `size` overrides the
-- kind's size for this render (a muted line kept at 12 on a small UI scale).
function ns.TyBody(parent, kind)
  local s = TY[kind == "muted" and "muted" or "body"]
  local b = { kind = kind or "body" }
  b.fs = NewFS(parent, s.size, s.color, false)
  function b:Place(text, x, y, width, color, size)
    if not Str(text) then self.fs:Hide(); return 0 end
    size = size or s.size
    if self.fs._size ~= size then self.fs._size = size; ns.SetFont(self.fs) end
    self.fs:SetText(text); Paint(self.fs, color or s.color)
    At(self.fs, parent, x, y)
    self.fs:Show()
    return Measure(self.fs, width, size)
  end
  function b:Hide() self.fs:Hide() end
  return b
end

-- ns.TyBullets(parent) -> l. l:Place(items, x, y, width [, opts]) -> height: sum of item heights
--   + 4 between items. Each item: a 5 px dot (HD "dot", muted) at x, its text at x + 12 with width
--   - 12, so wrapped lines align under the first word. opts.size (13), opts.color (text),
--   opts.colors[i] (one item's colour, e.g. an item quality), opts.marks[i] (an HD icon name drawn
--   12 px in `ok` in place of that item's dot, e.g. "check" for a done objective: one marker per
--   item, the words still at x + 12). l.rows[i] = { dot, mark, fs, y, h }.
function ns.TyBullets(parent)
  local s = TY.bullet
  local l = { rows = {} }
  function l:Place(items, x, y, width, opts)
    opts = opts or {}
    local size = opts.size or TY.body.size
    local used, n = 0, 0
    for _, text in ipairs(items or {}) do
      if Str(text) then
        n = n + 1
        local r = self.rows[n]
        if not r then
          r = { dot = ns.Icon(parent, "dot", s.dot, "ARTWORK", Col(s.color)), fs = NewFS(parent, size, TY.body.color, false) }
          self.rows[n] = r
        end
        if r.fs._size ~= size then r.fs._size = size; ns.SetFont(r.fs) end
        if n > 1 then used = used + s.gap end
        local iy = y + used
        r.fs:SetText(text); Paint(r.fs, (opts.colors and opts.colors[n]) or opts.color or TY.body.color)
        At(r.fs, parent, x + s.indent, iy)
        local ih = Measure(r.fs, width - s.indent, size)
        -- the dot (or the mark) sits on the middle of the first line, on whole pixels
        local mark = opts.marks and opts.marks[n]
        if mark then
          r.mark = r.mark or parent:CreateTexture(nil, "ARTWORK")
          r.mark:SetSize(s.mark, s.mark)
          ns.SetHDIcon(r.mark, mark, Col(s.markColor))
          At(r.mark, parent, x - math.floor((s.mark - s.dot) / 2 + 0.5), iy + math.floor((size - s.mark) / 2 + 0.5))
          r.mark:Show(); r.dot:Hide()
        else
          if r.mark then r.mark:Hide() end
          At(r.dot, parent, x, iy + math.floor((size - s.dot) / 2 + 0.5))
          r.dot:Show()
        end
        r.fs:Show()
        r.y, r.h = iy, ih
        used = used + ih
      end
    end
    for j = n + 1, #self.rows do
      local r = self.rows[j]; r.fs:Hide(); r.dot:Hide(); if r.mark then r.mark:Hide() end
    end
    self.n = n
    return used
  end
  function l:Hide() for _, r in ipairs(self.rows) do r.fs:Hide(); r.dot:Hide(); if r.mark then r.mark:Hide() end end end
  return l
end

-- ns.TyFact(parent) -> f. f:Place(label, value, x, y, width [, opts]) -> height.
--   Label 12 muted at x, value 12 fg at x + labelW + 8 ("Niveau conseillé  37-46"). labelW is
--   opts.labelW (to line up a column of facts) or the label's own width. When the value would get
--   less than 64 px it goes under the label (2 px gap). Height = max(label, value), or label + 2
--   + value when stacked. opts.valueColor (fg). f.stacked tells which layout was used.
function ns.TyFact(parent)
  local s = TY.fact
  local f = {}
  f.label = NewFS(parent, s.size, s.label, false)
  f.value = NewFS(parent, s.size, s.value, false)
  function f:Place(label, value, x, y, width, opts)
    opts = opts or {}
    if not Str(label) and not Str(value) then self:Hide(); return 0 end
    if not Str(value) then value = "" end
    label = Str(label) and label or ""
    local lw = opts.labelW or ns.TextWidth(self.label, label)
    if lw > width then lw = width end
    self.label:SetText(label); Paint(self.label, s.label)
    self.value:SetText(value); Paint(self.value, opts.valueColor or s.value)
    At(self.label, parent, x, y)
    local lh = label ~= "" and Measure(self.label, lw + 1, s.size) or 0
    local vx = x + (label ~= "" and (lw + s.gap) or 0)
    local vw = width - (vx - x)
    local h
    if value == "" then self.value:Hide(); h = lh; self.stacked = false
    elseif vw < s.minValue then
      At(self.value, parent, x, y + lh + s.stackGap)
      h = lh + s.stackGap + Measure(self.value, width, s.size)
      self.stacked = true
    else
      At(self.value, parent, vx, y)
      h = math.max(lh, Measure(self.value, vw, s.size))
      self.stacked = false
    end
    self.label:SetShown(label ~= ""); if value ~= "" then self.value:Show() end
    self.vx, self.labelW = vx, lw
    return h
  end
  function f:Hide() self.label:Hide(); self.value:Hide() end
  return f
end

-- ns.TyStat(parent) -> st. st:Place(label, done, total, x, y, width [, opts]) -> height
--   = row (12) + 4 + bar 2 [+ 4 + sub line]. Row: label 12 muted at x (wraps in width - count - 8),
--   count "done/total" 12 fg right-aligned at x + width. Bar: track white 0.08 across width, fill
--   `ok` for done/total (hidden at 0). opts.count (text instead of "5/6"), opts.sub (an 11 muted
--   line under the bar, e.g. "1 attend un prérequis"), opts.subSize (12 on a small UI scale),
--   opts.fill (colour token). The count never wraps: 2 px of slack against pixel snapping.
function ns.TyStat(parent)
  local s = TY.stat
  local st = {}
  st.label = NewFS(parent, s.size, s.label, false)
  st.count = NewFS(parent, s.size, s.count, false)
  st.count:SetJustifyH("RIGHT"); st.count:SetWordWrap(false)
  st.track = Tex(parent, "ARTWORK", s.track)
  st.fill = Tex(parent, "OVERLAY", Col(s.fill))
  st.sub = ns.TyBody(parent, "muted")
  function st:Place(label, done, total, x, y, width, opts)
    opts = opts or {}
    done, total = tonumber(done) or 0, tonumber(total) or 0
    local ctext = opts.count or (total > 0 and (done .. "/" .. total) or "")
    self.count:SetText(ctext)
    local cw = ctext ~= "" and ns.TextWidth(self.count, ctext) or 0
    if cw > 0 then cw = math.ceil(cw) end
    At(self.count, parent, x + width - cw - 2, y)
    if cw > 0 then self.count:SetWidth(cw + 2); self.count:Show() else self.count:Hide() end
    self.label:SetText(Str(label) and label or ""); Paint(self.label, s.label)
    At(self.label, parent, x, y)
    local rowH = Str(label) and Measure(self.label, width - (cw > 0 and cw + 8 or 0), s.size) or s.size
    self.label:SetShown(Str(label))
    local by = y + rowH + s.barTop
    At(self.track, parent, x, by); self.track:SetSize(width, s.bar); self.track:Show()
    local p = total > 0 and math.min(1, math.max(0, done / total)) or 0
    local fc = Col(opts.fill or s.fill)
    self.fill:SetColorTexture(fc[1], fc[2], fc[3], fc[4] or 1)
    At(self.fill, parent, x, by)
    self.fill:SetSize(math.max(1, math.floor(width * p + 0.5)), s.bar)
    self.fill:SetShown(p > 0)
    self.p, self.barY = p, by
    local h = rowH + s.barTop + s.bar
    local sh = self.sub:Place(opts.sub, x, by + s.bar + s.subTop, width, nil, opts.subSize)
    if sh > 0 then h = h + s.subTop + sh end
    return h
  end
  function st:Hide() self.label:Hide(); self.count:Hide(); self.track:Hide(); self.fill:Hide(); self.sub:Hide() end
  return st
end

-- ns.TextStack(parent) -> stack, built once; every render:
--   stack:Begin(x, y, width)          -- forget the last render
--   stack:Heading(text [, icon])      -- 14 above (0 when first), 4 below
--   stack:Body(text [, color]) / stack:Muted(text [, color])
--   stack:Bullets(items [, opts]) / stack:Fact(label, value [, opts])
--   stack:Stat(label, done, total [, opts]) / stack:Gap(px)
--   local h = stack:End()             -- total height from y; unused pieces are hidden
-- Each call returns the height it added (its gap included). A non-heading piece after another
-- piece gets 4 above (none right under a heading: the heading's 4 below is the gap). Empty text
-- adds nothing.
function ns.TextStack(parent)
  local stk = { parent = parent, pools = {}, used = {} }
  local MAKE = { head = ns.TyHeading, body = function(p) return ns.TyBody(p, "body") end,
    muted = function(p) return ns.TyBody(p, "muted") end, bullets = ns.TyBullets, fact = ns.TyFact, stat = ns.TyStat }
  local function Take(kind)
    local pool = stk.pools[kind] or {}; stk.pools[kind] = pool
    local n = (stk.used[kind] or 0) + 1; stk.used[kind] = n
    pool[n] = pool[n] or MAKE[kind](parent)
    return pool[n]
  end
  local function Add(self, h, isHead)
    if h > 0 then self.y = self.y + h; self.n = self.n + 1; self.lastHead = isHead end
    return h
  end
  -- the gap before a non-heading piece
  local function Lead(self) return (self.n > 0 and not self.lastHead) and TY.gap or 0 end
  function stk:Begin(x, y, width)
    self.x, self.y0, self.y, self.w, self.n, self.lastHead = x or 0, y or 0, y or 0, width or 100, 0, false
    for k in pairs(self.used) do self.used[k] = 0 end
    return self
  end
  function stk:Heading(text, icon)
    if not Str(text) then return 0 end
    local h = Take("head"):Place(text, self.x, self.y, self.w, { first = self.n == 0, icon = icon })
    return Add(self, h, true)
  end
  local function Simple(kind)
    return function(self, text, color)
      if not Str(text) then return 0 end
      local lead = Lead(self)
      local h = Take(kind):Place(text, self.x, self.y + lead, self.w, color)
      return Add(self, h > 0 and lead + h or 0, false)
    end
  end
  stk.Body, stk.Muted = Simple("body"), Simple("muted")
  function stk:Bullets(items, opts)
    local lead = Lead(self)
    local h = Take("bullets"):Place(items, self.x, self.y + lead, self.w, opts)
    return Add(self, h > 0 and lead + h or 0, false)
  end
  function stk:Fact(label, value, opts)
    local lead = Lead(self)
    local h = Take("fact"):Place(label, value, self.x, self.y + lead, self.w, opts)
    return Add(self, h > 0 and lead + h or 0, false)
  end
  function stk:Stat(label, done, total, opts)
    local lead = Lead(self)
    local h = Take("stat"):Place(label, done, total, self.x, self.y + lead, self.w, opts)
    return Add(self, h > 0 and lead + h or 0, false)
  end
  function stk:Gap(px) self.y = self.y + (px or 0); return px or 0 end
  function stk:End()
    for kind, pool in pairs(self.pools) do
      for i = (self.used[kind] or 0) + 1, #pool do pool[i]:Hide() end
    end
    return self.y - self.y0
  end
  return stk
end

-- =====================================================================
--  Window size rule (design system 3.1) and grids (3.22). Pure functions: no frame is made here.
-- =====================================================================

local function Clamp(v, lo, hi) if v < lo then v = lo end if v > hi then v = hi end return v end

-- The screen in UI units (UIParent's size), secret-safe; 1366 x 768 when it cannot be read.
-- A size under 320 x 240 is not a real screen (a test stub): the default is used.
local function ScreenSide(given, getter, default, floor)
  if type(given) == "number" and not secret(given) and given >= floor then return given end
  if UIParent and UIParent[getter] then
    local ok, v = pcall(UIParent[getter], UIParent)
    if ok and type(v) == "number" and not secret(v) and v >= floor then return v end
  end
  return default
end
function ns.ScreenSize(uw, uh)
  return ScreenSide(uw, "GetWidth", 1366, 320), ScreenSide(uh, "GetHeight", 768, 240)
end

-- The UI scale for real-pixel guards (1 when unknown, secret or not positive).
function ns.UIScale()
  if UIParent and UIParent.GetEffectiveScale then
    local ok, s = pcall(UIParent.GetEffectiveScale, UIParent)
    if ok and type(s) == "number" and not secret(s) and s > 0 then return s end
  end
  return 1
end

-- ns.WinSize(tier, uw, uh) -> defW, defH, minW, minH, maxW, maxH (UI units).
--   "workspace": W = clamp(70 % of uw, min(900, 96 % uw), 1400), H = clamp(78 % of uh,
--                min(620, 80 % uh), 900); the user drags between the minimums and 96 % x 90 %.
--   "panel":     W = clamp(45 % of uw, min(560, 96 % uw), 860); the height fits the content
--                (defH and minH are nil), capped at 80 % of uh.
--   anything else: nil (hud windows keep their own fixed size).
function ns.WinSize(tier, uw, uh)
  uw, uh = ns.ScreenSize(uw, uh)
  local fl = math.floor
  local maxW = fl(uw * 0.96)
  if tier == "workspace" then
    local minW, minH = math.min(900, maxW), math.min(620, fl(uh * 0.80))
    return Clamp(fl(uw * 0.70), minW, 1400), Clamp(fl(uh * 0.78), minH, 900), minW, minH, maxW, fl(uh * 0.90)
  elseif tier == "panel" then
    local minW = math.min(560, maxW)
    return Clamp(fl(uw * 0.45), minW, math.max(860, minW)), nil, minW, nil, maxW, fl(uh * 0.80)
  end
  return nil
end

-- The standard grids (3.22), tuned here only. minPx: the real-pixel guard (3.21), min(200, minW).
ns.GRID = {
  settings    = { minW = 320, gap = 12, rowGap = 0,  maxCols = 3, minPx = 200 },  -- rows in a settings card
  hubRows     = { minW = 280, gap = 12, rowGap = 6,  maxCols = 3, minPx = 200 },  -- Home lines
  homeCards   = { minW = 320, gap = 16, rowGap = 16, maxCols = 3, minPx = 200 },  -- Home activity cards
  moduleTiles = { minW = 200, gap = 12, rowGap = 12, maxCols = 4, minPx = 200 },  -- General modules, Setup interests
  profTiles   = { minW = 150, gap = 8,  rowGap = 8,  maxCols = 3, minPx = 150 },  -- Orders professions
  cards       = { minW = 300, gap = 12, rowGap = 12, maxCols = 3, minPx = 200 },  -- Welcome, Help tasks, Keys, zones
  orderCards  = { minW = 420, gap = 12, rowGap = 12, maxCols = 3, minPx = 200 },
  toggles     = { minW = 200, gap = 12, rowGap = 0,  maxCols = 4, minPx = 200 },  -- Writs zones, weights
  listGrid    = { minW = 300, gap = 12, rowGap = 0,  maxCols = 3, minPx = 200 },  -- dense rows as a grid
}

-- ns.Cols(w, minW, gap, maxCols [, minPx]) -> n, colW, xs, lastW
--   n columns of at least minW (1..maxCols), whole pixels; the leftover pixels go to the last
--   column (lastW). With minPx, columns are dropped until each keeps minPx real screen pixels.
function ns.Cols(w, minW, gap, maxCols, minPx)
  w = math.max(0, math.floor(tonumber(w) or 0))
  gap = gap or 12
  minW = math.max(1, minW or w)
  maxCols = math.max(1, maxCols or 3)
  local n = Clamp(math.floor((w + gap) / (minW + gap)), 1, maxCols)
  local function ColW(k) return math.floor((w - (k - 1) * gap) / k) end
  if minPx then
    local sc = ns.UIScale() * (ns.WindowScale and ns.WindowScale() or 1)  -- the other windows' grids
    while n > 1 and ColW(n) * sc < minPx do n = n - 1 end
  end
  local colW = math.max(0, ColW(n))
  local xs = {}
  for i = 1, n do xs[i] = (i - 1) * (colW + gap) end
  return n, colW, xs, math.max(0, w - xs[n])
end

-- ns.Columns(w, n, gap) -> xs, colW, lastW: a fixed split (two panes).
function ns.Columns(w, n, gap)
  w = math.max(0, math.floor(tonumber(w) or 0)); n = math.max(1, n or 2); gap = gap or 16
  local colW = math.max(0, math.floor((w - (n - 1) * gap) / n))
  local xs = {}
  for i = 1, n do xs[i] = (i - 1) * (colW + gap) end
  return xs, colW, math.max(0, w - xs[n])
end

-- ns.Grid(): a reusable placer (no frame of its own). Cells go left to right, then the next line,
-- in the order they are added (never reflowed by height).
--   g:Begin(parent, x, y, w, { minW, gap, rowGap, maxCols, minPx, equal })   -- or ns.GRID.<name>
--   g:Add(frame, fit [, { span = "full" }]) -> cell width, height
--       fit(frame, cellW) -> height (nil: the frame's own height); the frame is anchored TOPLEFT of
--       parent at the cell and given the cell width. span "full" closes the line, takes the whole
--       width and opens a new line.
--   g:Break()                      -- close the current line
--   g:End() -> height, n, colW      -- height used from y (no trailing gap)
-- g.cells = { { frame, x, y, w, h, line, col, full }, ... } and g.lines = { { y, h, n, full } }
-- describe the last layout (x, y relative to the parent's top-left, y downward).
function ns.Grid()
  local g = { cells = {}, lines = {} }
  local function CloseLine(self)
    local line = self.cur
    if not line or #line.cells == 0 then return end
    if self.equal then
      for _, c in ipairs(line.cells) do
        c.h = line.h
        if c.frame.SetHeight then c.frame:SetHeight(line.h) end
      end
    end
    self.lines[#self.lines + 1] = { y = line.y, h = line.h, n = #line.cells, full = line.full }
    self.bottom = line.y + line.h
    self.y = self.bottom + self.rowGap
    self.cur = nil
  end
  local function OpenLine(self, full)
    self.cur = { y = self.y, h = 0, cells = {}, full = full }
    return self.cur
  end
  local function Place(self, frame, fit, x, w, line, col, full)
    if frame.ClearAllPoints then frame:ClearAllPoints() end
    frame:SetPoint("TOPLEFT", self.parent, "TOPLEFT", self.x0 + x, -(self.y0 + line.y))
    if frame.SetWidth then frame:SetWidth(w) end
    local h = fit and fit(frame, w)
    if type(h) ~= "number" then
      local ok, fh = pcall(frame.GetHeight, frame)
      h = (ok and type(fh) == "number" and not secret(fh)) and fh or 0
    end
    h = math.max(0, math.ceil(h))
    local c = { frame = frame, x = x, y = line.y, w = w, h = h, line = #self.lines + 1, col = col, full = full }
    line.cells[#line.cells + 1] = c
    self.cells[#self.cells + 1] = c
    if h > line.h then line.h = h end
    return w, h
  end
  function g:Begin(parent, x, y, w, o)
    o = o or {}
    self.parent, self.x0, self.y0, self.w = parent, x or 0, y or 0, math.max(0, math.floor(w or 0))
    self.gap = o.gap or 12
    self.rowGap = o.rowGap or self.gap
    self.equal = o.equal and true or false
    self.n, self.colW, self.xs, self.lastW = ns.Cols(self.w, o.minW or self.w, self.gap, o.maxCols or 3, o.minPx)
    self.y, self.bottom, self.cur = 0, 0, nil
    self.cells, self.lines = {}, {}
    return self
  end
  function g:Add(frame, fit, opts)
    if opts and opts.span == "full" then
      CloseLine(self)
      local line = OpenLine(self, true)
      local w, h = Place(self, frame, fit, 0, self.w, line, 1, true)
      CloseLine(self)
      return w, h
    end
    local line = self.cur
    if line and #line.cells >= self.n then CloseLine(self); line = nil end
    line = line or OpenLine(self, false)
    local col = #line.cells + 1
    local w = (col == self.n) and self.lastW or self.colW
    return Place(self, frame, fit, self.xs[col], w, line, col, false)
  end
  function g:Break() CloseLine(self) end
  function g:End()
    CloseLine(self)
    return self.bottom or 0, self.n, self.colW
  end
  return g
end

-- =====================================================================
--  Tooltip: panel colour, 1 px dark edge, name first, facts muted, mouse lines in the link colour.
-- =====================================================================
local MOUSE_WORDS = { "^Clic", "^Click", "^Right%-click", "^Maj%-clic", "^Shift%-click", "^Ctrl%-clic", "^Ctrl%-click",
  "^Alt%-clic", "^Alt%-click", "^Molette", "^Wheel", "^Glisser", "^Drag", "^Double%-clic", "^Double%-click" }
local function IsMouseLine(s)
  if type(s) ~= "string" then return false end
  local plain = s:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
  for _, p in ipairs(MOUSE_WORDS) do if plain:find(p) then return true end end
  return false
end
ns.IsMouseLine = IsMouseLine

local styled = false
local function RestoreTip(tt)
  if not styled then return end
  styled = false
  local ns9 = tt.NineSlice
  if type(ns9) ~= "table" then return end
  if GameTooltip_SetBackdropStyle and GAME_TOOLTIP_BACKDROP_STYLE_DEFAULT then
    pcall(GameTooltip_SetBackdropStyle, tt, GAME_TOOLTIP_BACKDROP_STYLE_DEFAULT)
  else
    local bgc, edc = TOOLTIP_DEFAULT_BACKGROUND_COLOR, TOOLTIP_DEFAULT_COLOR
    if bgc and bgc.GetRGB and ns9.SetCenterColor then pcall(ns9.SetCenterColor, ns9, bgc:GetRGB()) end
    if edc and edc.GetRGB and ns9.SetBorderColor then pcall(ns9.SetBorderColor, ns9, edc:GetRGB()) end
  end
end
local function StyleTip(tt)
  local ns9 = tt.NineSlice
  if type(ns9) ~= "table" or type(ns9.SetCenterColor) ~= "function" or type(ns9.SetBorderColor) ~= "function" then return end
  pcall(ns9.SetCenterColor, ns9, T.panel[1], T.panel[2], T.panel[3], 0.96)
  pcall(ns9.SetBorderColor, ns9, 0, 0, 0, 0.7)
  styled = true
end
do
  local hooked = false
  function ns.HookTooltip()
    if hooked or not GameTooltip then return end
    hooked = true
    if hooksecurefunc and GameTooltip.SetOwner then pcall(hooksecurefunc, GameTooltip, "SetOwner", function(self) RestoreTip(self) end) end
    if GameTooltip.HookScript then pcall(GameTooltip.HookScript, GameTooltip, "OnHide", function(self) RestoreTip(self) end) end
  end
end

-- ns.ShowTip(owner, lines): lines[1] is the name; strings after it are facts (muted) or, when
-- they start with the mouse word ("Clic :", "Click:"...), what the mouse does (link colour).
-- A table line is { text, r, g, b }. A cut label of the owner comes first; a disabled owner
-- with owner.disabledReason gets that reason in the warning colour.
function ns.ShowTip(owner, lines)
  if not owner then return end
  ns.HookTooltip()
  GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
  GameTooltip:ClearLines()
  lines = lines or {}
  local cut = owner.wlClamped and CutLines(owner) or {}
  local first = lines[1]
  local n = 0
  for _, full in ipairs(cut) do
    if full ~= first then GameTooltip:AddLine(full, T.fg[1], T.fg[2], T.fg[3], true); n = n + 1 end
  end
  for _, l in ipairs(lines) do
    n = n + 1
    -- { gap = true }: a blank line between blocks; { text, r, g, b, right = "Pill", rc = colour }:
    -- the text with a short word on the right (a pill in words)
    if type(l) == "table" and l.gap then GameTooltip:AddLine(" ")
    elseif type(l) == "table" and l.right and GameTooltip.AddDoubleLine then
      local rc = l.rc or T.muted
      GameTooltip:AddDoubleLine(l[1], l.right, l[2] or T.fg[1], l[3] or T.fg[2], l[4] or T.fg[3], rc[1], rc[2], rc[3])
    elseif type(l) == "table" then GameTooltip:AddLine(l[1], l[2], l[3], l[4], true)
    elseif n == 1 then GameTooltip:AddLine(l, T.fg[1], T.fg[2], T.fg[3], true)
    elseif IsMouseLine(l) then GameTooltip:AddLine(l, (T.hint or T.muted)[1], (T.hint or T.muted)[2], (T.hint or T.muted)[3], true)
    else GameTooltip:AddLine(l, T.muted[1], T.muted[2], T.muted[3], true) end
  end
  local enabled = true
  if owner.IsEnabled then local ok, e = pcall(owner.IsEnabled, owner); enabled = not ok or e ~= false end
  if not enabled and owner.disabledReason then
    GameTooltip:AddLine(owner.disabledReason, T.warn[1], T.warn[2], T.warn[3], true)
  end
  StyleTip(GameTooltip)
  GameTooltip:Show()
end
function ns.HideTip() GameTooltip:Hide() end

-- =====================================================================
--  Flat frames and the guide's buttons
-- =====================================================================
function ns.Flat(frame, bg, border)
  frame._bg = Tex(frame, "BACKGROUND", bg); frame._bg:SetAllPoints()
  frame._edges = {}
  local set, edges = ns.Outline(frame, border or T.cardEdge)
  frame._edges.TOP, frame._edges.BOTTOM, frame._edges.LEFT, frame._edges.RIGHT = edges[1], edges[2], edges[3], edges[4]
  frame._edgeSet = set
end

function ns.Accent(t, a)
  t._accentAlpha = a or 1
  table.insert(accents, t)
  t:SetColorTexture(T.accent[1], T.accent[2], T.accent[3], t._accentAlpha)
end

-- Old one-character labels become HD icons (the game font cannot draw most glyphs).
local GLYPH_ICON = { ["x"] = "close", ["X"] = "close", ["-"] = "minus", ["+"] = "plus", ["<"] = "chevron_left",
  [">"] = "chevron_right", ["..."] = "gear", ["?"] = "info" }
ns.GLYPH_ICON = GLYPH_ICON

-- ns.Button(parent, w, h, label, onClick, tip): the guide's button, styled as a secondary button
-- (ns.Primary makes it the view's main action). A one-glyph label ("x", "-", "<", "...") becomes an
-- icon button. The button is never narrower than its label.
function ns.Button(parent, w, h, label, onClick, tip)
  local b = CreateFrame("Button", nil, parent)
  b:SetSize(w, h)
  b.wlOwned = true
  b.minW = w
  ns.Flat(b, T.btnFill, T.btnEdge)
  b.hl = Tex(b, "BACKGROUND", T.hoverFill); b.hl:SetAllPoints(); b.hl:SetAlpha(0)
  b.press = Tex(b, "ARTWORK", T.pressFill); b.press:SetAllPoints(); b.press:Hide()
  b.icon = b:CreateTexture(nil, "OVERLAY")
  b.icon:SetPoint("CENTER"); b.icon:Hide()
  b.label = ns.Text(b, ns.F.label, T.fg, false)
  b.label:SetPoint("CENTER"); b.label:SetJustifyH("CENTER"); b.label:SetJustifyV("MIDDLE"); b.label:SetWordWrap(false)
  local labelSet = b.label.SetText
  local function Paint()
    local hov = b.hov or 0
    if b.primary then
      local c = b.pressed and T.accentPress or (hov > 0.5 and T.accentHover or T.accent)
      b._bg:SetColorTexture(c[1], c[2], c[3], 1)
      b._edgeSet(c, 0)
      b.hl:SetAlpha(0)
    elseif b.iconOnly then
      b._bg:SetColorTexture(1, 1, 1, 0)
      b._edgeSet(T.btnEdge, 0)
      b.hl:SetAlpha(hov)
      local c = (hov > 0.5) and T.fg or T.muted
      b.icon:SetVertexColor(c[1], c[2], c[3])
    else
      b._bg:SetColorTexture(T.btnFill[1], T.btnFill[2], T.btnFill[3], T.btnFill[4])
      b._edgeSet(T.btnEdge, T.btnEdge[4] + (T.btnEdgeHover[4] - T.btnEdge[4]) * hov)
      b.hl:SetAlpha(hov)
    end
    local enabled = b:IsEnabled() ~= false
    b:SetAlpha(enabled and 1 or T.disabledAlpha)
    b.label:SetTextColor(T.fg[1], T.fg[2], T.fg[3], (b.primary or hov > 0.5) and 1 or 0.85)
  end
  b.Paint = Paint
  function b:Fit()
    if self.iconOnly then return end
    local sw = ns.TextWidth(self.label)
    if sw > 0 then
      local need = sw + 24
      if need > (self.minW or 0) then self:SetWidth(need) end
    end
  end
  b.label.SetText = function(fs, t)
    local icon = type(t) == "string" and GLYPH_ICON[t]
    if icon then
      labelSet(fs, "")
      b.iconOnly = true
      local s = math.max(12, math.min(18, math.min(b.minW or 16, h or 16) - 4))
      b.icon:SetSize(s, s); ns.SetHDIcon(b.icon, icon, T.muted); b.icon:Show()
    else
      labelSet(fs, t)
      if b.iconOnly then b.iconOnly = false; b.icon:Hide() end
      b:Fit()
    end
    Paint()
  end
  b.label:SetText(label)
  b:SetScript("OnClick", function(self, ...)
    PlaySound(SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or 856)
    onClick(self, ...)
  end)
  b:SetScript("OnMouseDown", function(self)
    if self:IsEnabled() == false then return end
    self.pressed = true; self.press:Show(); self.label:SetPoint("CENTER", 0, -1); self.icon:SetPoint("CENTER", 0, -1); Paint()
  end)
  b:SetScript("OnMouseUp", function(self)
    self.pressed = false; self.press:Hide(); self.label:SetPoint("CENTER", 0, 0); self.icon:SetPoint("CENTER", 0, 0); Paint()
  end)
  b:SetScript("OnEnable", function() Paint() end)
  b:SetScript("OnDisable", function() Paint() end)
  b:SetScript("OnEnter", function(self)
    if self:IsEnabled() ~= false then ns.Tween(self, self.hov or 0, 1, 0.10, function(v) self.hov = v; Paint() end) end
    if tip then ns.ShowTip(self, type(tip) == "function" and tip() or tip)
    elseif self.wlClamped then local cut = CutLines(self); if #cut > 0 then ns.ShowTip(self, cut) end end
  end)
  b:SetScript("OnLeave", function(self)
    ns.Tween(self, self.hov or 0, 0, 0.10, function(v) self.hov = v; Paint() end)
    GameTooltip:Hide()
  end)
  Paint()
  return b
end

-- The view's one main action: accent fill, no border.
function ns.Primary(b)
  b.primary = true
  if b.Paint then b.Paint() return end
  ns.Accent(b._bg, 1)
  for _, e in pairs(b._edges) do e:SetAlpha(0) end
end

-- =====================================================================
--  Pills (ns.Chip): fill at 0.16, 1 px border at 0.50, text 11 in its colour. No side stripe.
-- =====================================================================
function ns.Chip(parent)
  local c = CreateFrame("Frame", nil, parent)
  c:SetHeight(ns.F.meta + 6)
  c.wlOwned = true
  c.bg = Tex(c, "BACKGROUND", { 1, 1, 1, 0.10 }); c.bg:SetAllPoints()
  c.border = ns.Outline(c, { 1, 1, 1, 0.20 })
  -- kept for older code; a pill never shows a side stripe
  c.edge = Tex(c, "ARTWORK", { 1, 1, 1, 0 }); c.edge:SetPoint("TOPLEFT"); c.edge:SetPoint("BOTTOMLEFT"); c.edge:SetWidth(1); c.edge:SetAlpha(0); c.edge:Hide()
  c.edge.Show = function() end
  c.edge.SetShown = function() end
  c.text = ns.Text(c, ns.F.meta, T.fg, false)
  c.text:SetPoint("LEFT", 6, 0); c.text:SetJustifyV("MIDDLE")
  ns.ClampLabel(c.text, nil, c)
  return c
end
-- The pill is as wide as its words: it is never cut (design system 4.1). maxW is still accepted
-- for older callers; c.overflow is true when the words need more than it, so the caller can
-- write a shorter label (and /wlh textes would list any text the engine still cuts).
function ns.SetChip(c, label, col, maxW)
  if not label then c:Hide() return end
  col = col or T.fg
  c.text:SetText(label); c.text.wlFull = label
  c.text:SetTextColor(col[1], col[2], col[3])
  c.bg:SetColorTexture(col[1], col[2], col[3], 0.16)
  c.border(col, 0.50)
  -- The words set the width. They are measured on a hidden twin FontString with the same font
  -- (a font applied a moment later, or a width the client keeps, used to cut them as "In...");
  -- measured again on the next frame once the font is final.
  c.text:SetWordWrap(false)
  local function Fit()
    local w = ns.TextWidth(c.text) + 2
    c.overflow = (maxW ~= nil and w + 12 > maxW) or nil
    local okP, _, _, _, left = pcall(c.text.GetPoint, c.text, 1)
    left = (okP and type(left) == "number" and left > 6) and left or 6
    c.text:SetWidth(w)
    c:SetWidth(w + left + 6)
  end
  Fit(); c:Show()
  if C_Timer and C_Timer.After then C_Timer.After(0, Fit); C_Timer.After(0.5, Fit) end
end

-- icône officielle de classe en texte (|T...|t), pour les puces et les lignes
function ns.ClassIconText(cls, size)
  local c = CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[cls]
  if not c then return "" end
  size = size or 14
  return ("|TInterface\\TargetingFrame\\UI-Classes-Circles:%d:%d:0:-1:256:256:%d:%d:%d:%d|t "):format(size, size, c[1] * 256, c[2] * 256, c[3] * 256, c[4] * 256)
end

-- majuscules qui gèrent les accents français (string.upper ne touche que l'ASCII)
local UP = { ["é"] = "É", ["è"] = "È", ["ê"] = "Ê", ["ë"] = "Ë", ["à"] = "À", ["â"] = "Â", ["ç"] = "Ç",
  ["î"] = "Î", ["ï"] = "Ï", ["ô"] = "Ô", ["û"] = "Û", ["ù"] = "Ù", ["ü"] = "Ü" }
function ns.Upper(s)
  if not s then return "" end
  s = s:upper()
  for a, b in pairs(UP) do s = s:gsub(a, b) end
  return s
end

function ns.ClassInfo(cls)
  local name = (LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[cls]) or (cls:sub(1, 1) .. cls:sub(2):lower())
  local c = RAID_CLASS_COLORS and RAID_CLASS_COLORS[cls]
  return name, c and { c.r, c.g, c.b } or { 0.41, 0.8, 0.94 }
end

-- =====================================================================
--  Window registry (filled by S.Window; read by /wlh textes)
-- =====================================================================
ns.windows = ns.windows or {}
-- The size of every WL Helper window, one setting (report: "+ or - for the ratio of all the windows,
-- 100 %, 90 % and so on"): WLDTDB.uiScale, 60 % to 150 %. The GPS arrow keeps its own size.
local SCALE_MIN, SCALE_MAX = 0.6, 1.5
ns.WIN_SCALE_MIN, ns.WIN_SCALE_MAX = SCALE_MIN, SCALE_MAX
function ns.WindowScale()
  local v = WLDTDB and tonumber(WLDTDB.uiScale)
  if not v then return 1 end
  return math.max(SCALE_MIN, math.min(SCALE_MAX, v))
end
-- The guide (its window, the modern view, the boss panel) has its own size (report: "the ratio also
-- shrinks the guide, it becomes tiny and everything sticks together"): WLDTDB.guideScale, 70 % to
-- 150 %, 100 % by default whatever the other windows' size.
local GUIDE_MIN, GUIDE_MAX = 0.7, 1.5
ns.GUIDE_SCALE_MIN, ns.GUIDE_SCALE_MAX = GUIDE_MIN, GUIDE_MAX
function ns.GuideScale()
  local v = WLDTDB and tonumber(WLDTDB.guideScale)
  if not v then return 1 end
  return math.max(GUIDE_MIN, math.min(GUIDE_MAX, v))
end
local function ScaleOf(f)
  if f and f.wlScaleKind == "guide" then return ns.GuideScale() end
  return ns.WindowScale()
end
ns.ScaleOf = ScaleOf
-- a new size: the window keeps its top-left corner where it is on screen (and its saved place follows)
local function Rescale(f, s)
  local old = f:GetScale()
  if type(old) ~= "number" or math.abs(old - s) < 0.001 then return end
  local l, t = f:GetLeft(), f:GetTop()
  f:SetScale(s)
  if type(l) == "number" and type(t) == "number" and not secret(l) and not secret(t) then
    local x, y = l * old / s, t * old / s
    f:ClearAllPoints(); f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, y)
    if type(f.wlDb) == "table" and f.wlPosKey then f.wlDb[f.wlPosKey] = { "TOPLEFT", "BOTTOMLEFT", x, y } end
  end
end
local scaleWait
function ns.ScaleWindows()
  -- a window holding a secure button cannot change size in combat: after the fight
  if InCombatLockdown and InCombatLockdown() then
    if not scaleWait then
      scaleWait = CreateFrame("Frame")
      scaleWait:SetScript("OnEvent", function(self) self:UnregisterAllEvents(); ns.ScaleWindows() end)
    end
    scaleWait:RegisterEvent("PLAYER_REGEN_ENABLED")
    return false
  end
  for _, f in ipairs(ns.windows) do pcall(Rescale, f, ScaleOf(f)) end
  return true
end
local function Step(v, cur, lo, hi)
  if v == "+" then v = cur + 0.1 elseif v == "-" then v = cur - 0.1 end
  v = tonumber(v)
  if not v then return nil end
  -- typed as a percent ("90") or a fraction ("0.9")
  if v > 3 then v = v / 100 end
  v = math.floor(v * 20 + 0.5) / 20
  return math.max(lo, math.min(hi, v))
end
-- v: a fraction (0.9), a percent (90), or "+" / "-" (10 % more or less). -> the size set
function ns.SetGuideScale(v)
  WLDTDB = WLDTDB or {}
  local s = Step(v, ns.GuideScale(), GUIDE_MIN, GUIDE_MAX)
  if not s then return ns.GuideScale() end
  if math.abs(s - 1) < 0.001 then WLDTDB.guideScale = nil else WLDTDB.guideScale = s end
  ns.ScaleWindows()
  return s
end
-- v: a fraction (0.9), or "+" / "-" (10 % more or less). -> the size set
function ns.SetWindowScale(v)
  WLDTDB = WLDTDB or {}
  local cur = ns.WindowScale()
  v = Step(v, cur, SCALE_MIN, SCALE_MAX)
  if not v then return cur end
  if math.abs(v - 1) < 0.001 then WLDTDB.uiScale = nil else WLDTDB.uiScale = v end
  ns.ScaleWindows()
  return v
end

-- ns.PerfRun(tag, fn, ...): runs fn and keeps how long it took in WLWritsDB.perf[tag] ({ n, total,
-- max, last } in ms, debugprofilestop), so a freeze can be read from the saved variables (report: "M
-- and L freeze the game"). ns.PerfNote(tag, ms) keeps a time measured elsewhere.
function ns.PerfNote(tag, dt)
  local db = WLWritsDB
  if type(db) ~= "table" or type(dt) ~= "number" then return end
  db.perf = type(db.perf) == "table" and db.perf or {}
  local p = db.perf[tag]
  if type(p) ~= "table" then p = { n = 0, total = 0, max = 0 }; db.perf[tag] = p end
  p.n = p.n + 1; p.total = p.total + dt; p.last = math.floor(dt * 10 + 0.5) / 10
  if dt > p.max then p.max = math.floor(dt * 10 + 0.5) / 10 end
end
-- ns.Throttle(fn, gap, tag) -> a function that runs fn at most once every `gap` seconds: the first
-- call at once, the calls in between folded into one more run when the gap is over (OpenMap's view
-- signal comes every frame while it glides; WL Helper redrew its map lines each time: a freeze on M
-- and L with OpenMap on). tag: timed in WLWritsDB.perf.
function ns.Throttle(fn, gap, tag)
  local last, waiting = -1e9, false
  local function run()
    last = (GetTime and GetTime()) or 0
    if tag and ns.PerfRun then ns.PerfRun(tag, function() pcall(fn) end) else pcall(fn) end
  end
  return function()
    local now = (GetTime and GetTime()) or 0
    if now - last >= gap then run(); return end
    if waiting then return end
    waiting = true
    if C_Timer and C_Timer.After then
      C_Timer.After(math.max(0.01, gap - (now - last)), function() waiting = false; run() end)
    else waiting = false; run() end
  end
end

function ns.PerfRun(tag, fn, ...)
  local clock = debugprofilestop
  if not clock then return fn(...) end
  local t0 = clock()
  local a, b = fn(...)
  ns.PerfNote(tag, clock() - t0)
  return a, b
end

-- kind: "guide" for the guide's own frames (their own size, ns.GuideScale), nil for the others
function ns.RegisterWindow(f, kind)
  if not f then return end
  f.wlOwned = true
  if kind then f.wlScaleKind = kind end
  for _, w in ipairs(ns.windows) do if w == f then return end end
  table.insert(ns.windows, f)
  -- born at the size chosen (its saved place was saved at that size)
  local v = ScaleOf(f)
  if math.abs(v - 1) > 0.001 and not (InCombatLockdown and InCombatLockdown()) then pcall(f.SetScale, f, v) end
end

-- ns.FitWindow(f, contentH): sizes any window to its content (design system 3.2). Windows built
-- with S.Window have f:FitHeight; older guide frames get the same formula here.
-- headerH defaults to f.headerH or 44; tabs and footer count when f.wlTabs / f.footer are shown.
function ns.FitWindow(f, contentH, opts)
  if not f then return nil end
  if f.FitHeight then return f:FitHeight(contentH) end
  if type(contentH) ~= "number" then return nil end
  opts = opts or {}
  local h = (opts.header or f.headerH or 44)
  if f.wlTabs and f.wlTabs.IsShown and f.wlTabs:IsShown() then h = h + 32 + 1 end
  h = h + 12 + contentH + 12
  if f.footer and f.footer.IsShown and f.footer:IsShown() then h = h + 24 end
  local okH, screen = pcall(UIParent.GetHeight, UIParent)
  if not okH or type(screen) ~= "number" or secret(screen) then screen = 768 end
  local minH = opts.minH or f.minH or 200
  h = math.min(math.max(math.ceil(h), minH), math.max(math.floor(screen * 0.80), minH))
  -- keep the top edge where it is: the window grows downward
  local p = f:GetPoint()
  if p ~= "TOPLEFT" then
    local l, t = f:GetLeft(), f:GetTop()
    if type(l) == "number" and type(t) == "number" and not secret(l) and not secret(t) then
      f:ClearAllPoints(); f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", l, t)
    end
  end
  f:SetHeight(h)
  return h
end

-- The key under which `parent` keeps `child` ("title", "rows[4]"), for debug paths.
function ns.KeyOf(parent, child)
  if type(parent) ~= "table" then return nil end
  local seen = 0
  for k, v in pairs(parent) do
    seen = seen + 1
    if seen > 400 then break end
    if v == child and type(k) == "string" then return k end
  end
  seen = 0
  for k, v in pairs(parent) do
    seen = seen + 1
    if seen > 400 then break end
    if type(k) == "string" and type(v) == "table" and v ~= child and rawget(v, 0) == nil then
      local n = 0
      for i, x in pairs(v) do
        n = n + 1
        if n > 200 then break end
        if x == child then return k .. "[" .. tostring(i) .. "]" end
      end
    end
  end
  return nil
end

-- A font file can be missing (another EllesmereUI version): the text would then be invisible.
-- A hidden probe draws "Ag" with it; no width = no font, the game's own is used instead.
local probe
local function FontWorks(path)
  if not probe then
    local holder = CreateFrame("Frame", nil, UIParent); holder:Hide()
    probe = holder:CreateFontString(nil, "OVERLAY")
  end
  local ok, set = pcall(probe.SetFont, probe, path, 12, "")
  if not ok or set == false then return false end
  local f = probe:GetFont()
  if not f or (type(f) == "string" and f:lower() ~= path:lower()) then return false end
  probe:SetText("Ag")
  local w = probe:GetStringWidth()
  return w and w > 0
end
ns.FontWorks = FontWorks

function ns.ApplyLooks()
  -- The accent stays War Legend red. The font is the game's own unless you pick EllesmereUI's in the
  -- settings (WLWritsDB.font = "eui"): on some installs its font left short labels blank.
  T.font, T.bold = STANDARD_TEXT_FONT, STANDARD_TEXT_FONT
  if ns.IsLoaded("EllesmereUI") and WLWritsDB and WLWritsDB.font == "eui" then
    local medium, bold = EUI .. "FiraSans Medium.ttf", EUI .. "FiraSans Bold.ttf"
    if FontWorks(medium) and FontWorks(bold) then T.font, T.bold = medium, bold
    else T.font, T.bold = STANDARD_TEXT_FONT, STANDARD_TEXT_FONT end
  end
  for _, fs in ipairs(fonts) do SetFont(fs) end
  for _, t in ipairs(accents) do t:SetColorTexture(T.accent[1], T.accent[2], T.accent[3], t._accentAlpha) end
  ns.RefitPixels()
  if ns.Render then ns.Render() end
end

if EllesmereUI and EllesmereUI.RegisterSkin then
  EllesmereUI.RegisterSkin(ADDON, function(S)
    ns.skin = S
    if S.OnLooksChanged then S.OnLooksChanged(ns.ApplyLooks) end
    ns.ApplyLooks()
  end)
end

-- =====================================================================
--  Whispers (guild report: « Aucun joueur nommé 'X' ne joue actuellement. » spam). Every whisper
--  WL Helper sends, chat or addon message, goes through ns.ChatWhisper / ns.AddonWhisper: only to a
--  player confirmed online right now (in my group, online in the guild roster, or heard from in the
--  last 60 s), never in a loop over names. The game's "not playing" line for a name we whispered in
--  the last 10 s is hidden (a player logged off between the check and the send). Everything else
--  goes on the GUILD or group channel.
-- =====================================================================
local HEARD_FOR, HIDE_FOR, ROSTER_FOR = 60, 10, 10
local heard, whispered = {}, {}     -- [lower short name] = GetTime()
local rosterAt, rosterOn = nil, {}  -- [lower short name] = true/false (the guild roster's online flag)
local function WClock() return (GetTime and GetTime()) or 0 end
-- a readable name as the key ("Name-Realm" or "Name Realm" -> "name"); nil when hidden or malformed
local function WKey(n)
  if type(n) ~= "string" or secret(n) or not ns.Readable(n) or n == "" or #n > 64 or n:find("[|%c]") then return nil end
  local s = n:match("^([^%-%s]+)") or n
  return s:lower()
end
local function Yes(v) return v ~= nil and not secret(v) and ns.Readable(v) and v and true or false end

-- a player we just heard from (a whisper, a chat line, an addon message): online at that moment
function ns.HeardFrom(name)
  local k = WKey(name)
  if k then heard[k] = WClock() end
end
function ns.ForgetWhispers() heard, whispered, rosterAt, rosterOn = {}, {}, nil, {} end

local function RosterOnline(k)
  local now = WClock()
  if not rosterAt or now - rosterAt >= ROSTER_FOR then
    rosterAt, rosterOn = now, {}
    local inGuild = IsInGuild and select(2, pcall(IsInGuild))
    if Yes(inGuild) and GetNumGuildMembers and GetGuildRosterInfo then
      local ok, n = pcall(GetNumGuildMembers)
      n = (ok and type(n) == "number" and not secret(n)) and n or 0
      for i = 1, math.min(n, 1000) do
        local ok2, name, _, _, _, _, _, _, _, online = pcall(GetGuildRosterInfo, i)
        local key = ok2 and WKey(name)
        if key then rosterOn[key] = Yes(online) end
      end
    end
  end
  return rosterOn[k]
end

-- OnlineNow(name): true only when the player is surely online right now
function ns.OnlineNow(name)
  local k = WKey(name)
  if not k then return false end
  local me = UnitName and WKey((UnitName("player")))
  if me and me == k then return false end
  if UnitInParty and Yes(select(2, pcall(UnitInParty, name))) then return true end
  if UnitInRaid and Yes(select(2, pcall(UnitInRaid, name))) then return true end
  local t = heard[k]
  if t and WClock() - t <= HEARD_FOR then return true end
  return RosterOnline(k) == true
end

local function Mark(name)
  local k = WKey(name)
  if k then whispered[k] = WClock() end
end
-- the one way WL Helper whispers a chat line; false (nothing sent) when the player is not surely online
function ns.ChatWhisper(text, name)
  if type(text) ~= "string" or text == "" or not ns.Readable(text) or not ns.OnlineNow(name) then return false, "offline" end
  local send = (C_ChatInfo and C_ChatInfo.SendChatMessage) or SendChatMessage
  if type(send) ~= "function" then return false, "none" end
  Mark(name)
  return (pcall(send, text, "WHISPER", nil, name)), nil
end
-- the one way WL Helper whispers an addon message (none does today: the guild channel carries them)
function ns.AddonWhisper(prefix, msg, name)
  if type(msg) ~= "string" or not ns.OnlineNow(name) then return false, "offline" end
  local send = (C_ChatInfo and C_ChatInfo.SendAddonMessage) or SendAddonMessage
  if type(send) ~= "function" then return false, "none" end
  Mark(name)
  return (pcall(send, prefix, msg, "WHISPER", name)), nil
end

-- The one door for WL Helper's addon messages (every module, every prefix). The server allows each
-- prefix a reserve of 10 messages that refills one a second, and drops the rest without a word; past
-- that, too many bytes at once can cost the chat connection (ChatThrottleLib's own note). So: a
-- message goes now when its prefix has a token and the shared byte budget allows it (800 bytes a
-- second, 4000 at most saved up, as ChatThrottleLib), else it waits its turn; one the client refuses
-- as throttled (result 3 or 8) waits 1.5 s and goes again, three times at most. fn: the module's own
-- sender (tests watch it), else the game's. True when sent or queued.
do
  local BURST_MSG, BYTES_PER_S, BYTES_MAX, OVERHEAD = 10, 800, 4000, 40
  local buckets, waiting = {}, {}
  local bytes, bytesAt = BYTES_MAX, nil
  local timerOn = false
  local function Clock() local t = GetTime and GetTime(); return type(t) == "number" and t or 0 end
  local function Refill(now)
    bytesAt = bytesAt or now
    if now > bytesAt then bytes = math.min(BYTES_MAX, bytes + (now - bytesAt) * BYTES_PER_S) end
    bytesAt = now
  end
  local function Bucket(prefix, now)
    local b = buckets[prefix]
    if not b then b = { n = BURST_MSG, at = now }; buckets[prefix] = b end
    if now > b.at then b.n = math.min(BURST_MSG, b.n + (now - b.at)) end
    b.at = now
    return b
  end
  local function Cost(m) return #m.msg + #m.prefix + OVERHEAD end
  local Pump
  local inPump = false
  local stuckAt = nil   -- the clock of a pump that sent nothing: no new timer until time moves
  -- a timer that fires at once (some stubs do) never re-enters the pump it was set from
  local function Later(delay)
    if timerOn or not (C_Timer and C_Timer.After) then return end
    timerOn = true
    C_Timer.After(delay, function() timerOn = false; if not inPump then Pump() end end)
  end
  -- one try: "wait" (no token, no bytes, or the client said throttled), else done
  local function Try(m, now)
    if m.notBefore and m.notBefore > now then return "wait" end
    local b = Bucket(m.prefix, now)
    Refill(now)
    if b.n < 1 or bytes < Cost(m) then return "wait" end
    local fn = m.fn or (C_ChatInfo and C_ChatInfo.SendAddonMessage) or SendAddonMessage
    if type(fn) ~= "function" then return "gone" end
    b.n = b.n - 1; bytes = bytes - Cost(m)
    local ok, r = pcall(fn, m.prefix, m.msg, m.chan, m.target)
    if ok and (r == 3 or r == 8) and (m.tries or 0) < 3 then
      m.tries = (m.tries or 0) + 1
      b.n = 0
      m.notBefore = now + 1.5
      return "wait"
    end
    return "sent"
  end
  local function Delay(m, now)
    if m.notBefore and m.notBefore > now then return m.notBefore - now end
    local b = buckets[m.prefix]
    return math.max(0.1, 1 - (b and b.n or 0), (Cost(m) - bytes) / BYTES_PER_S)
  end
  Pump = function()
    inPump = true
    local okP, err = pcall(function()
    local now = Clock()
    local i, soonest, held, moved = 1, nil, {}, false
    while waiting[i] do
      local m = waiting[i]
      -- in order within a prefix: one that waits holds the rest of its prefix
      local res = held[m.prefix] and "wait" or Try(m, now)
      if res == "wait" then
        held[m.prefix] = true
        local d = Delay(m, now)
        soonest = soonest and math.min(soonest, d) or d
        i = i + 1
      else
        table.remove(waiting, i); moved = true
      end
    end
    if moved or stuckAt ~= now then
      stuckAt = (not moved) and now or nil
      if #waiting > 0 then Later(soonest or 1) end
    end
    end)
    inPump = false
    if not okP then error(err, 0) end
  end
  function ns.AddonSend(prefix, msg, chan, target, fn)
    if type(prefix) ~= "string" or type(msg) ~= "string" then return false end
    local m = { prefix = prefix, msg = msg, chan = chan or "GUILD", target = target, fn = fn }
    local behind = false
    for _, w in ipairs(waiting) do if w.prefix == prefix then behind = true break end end
    if not behind then
      local now = Clock()
      if Try(m, now) ~= "wait" then return true end
      waiting[#waiting + 1] = m
      Later(Delay(m, now))
      return true
    end
    waiting[#waiting + 1] = m
    Later(1)
    return true
  end
  ns._AddonWaiting = function() return waiting end   -- tests
  ns._AddonPump = function() Pump() end               -- tests
  ns._AddonReset = function() buckets, waiting, bytes, bytesAt, timerOn, stuckAt = {}, {}, BYTES_MAX, nil, false, nil end
end

-- the game's "No player named '%s' is currently playing." as a pattern, built from its own string
local notFound
local function NotFoundPattern()
  if notFound ~= nil then return notFound or nil end
  local g = ERR_CHAT_PLAYER_NOT_FOUND_S
  notFound = false
  if type(g) == "string" and not secret(g) and ns.Readable(g) then
    local p = g:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%0")
    -- "%s", or "%1$s" in a translation that numbers its arguments
    local n
    p, n = p:gsub("%%%%%d%%%$s", "(.-)", 1)
    if n == 0 then p, n = p:gsub("%%%%s", "(.-)", 1) end
    if n == 1 then notFound = "^" .. p .. "$" end
  end
  return notFound or nil
end
-- the name of a "not playing" line when we whispered that player in the last 10 s, else nil
function ns.OurNotFound(text)
  if type(text) ~= "string" or secret(text) or not ns.Readable(text) then return nil end
  local p = NotFoundPattern()
  if not p then return nil end
  local ok, name = pcall(string.match, text, p)
  local k = ok and WKey(name)
  local t = k and whispered[k]
  if t and WClock() - t <= HIDE_FOR then return name end
  return nil
end
local function NotFoundFilter(_, _, text)
  local ok, name = pcall(ns.OurNotFound, text)
  return (ok and name) and true or false
end
ns.NotFoundFilter = NotFoundFilter
local AddFilter = (ChatFrameUtil and ChatFrameUtil.AddMessageEventFilter) or ChatFrame_AddMessageEventFilter
if type(AddFilter) == "function" then pcall(AddFilter, "CHAT_MSG_SYSTEM", NotFoundFilter) end

-- who we hear from: the sender of a chat line (2nd argument) or of an addon message (4th)
if CreateFrame then
  local hf = CreateFrame("Frame")
  local CHAT = { "CHAT_MSG_WHISPER", "CHAT_MSG_SAY", "CHAT_MSG_YELL", "CHAT_MSG_CHANNEL", "CHAT_MSG_GUILD",
    "CHAT_MSG_OFFICER", "CHAT_MSG_PARTY", "CHAT_MSG_PARTY_LEADER", "CHAT_MSG_RAID", "CHAT_MSG_RAID_LEADER", "CHAT_MSG_ADDON" }
  for _, e in ipairs(CHAT) do pcall(hf.RegisterEvent, hf, e) end
  pcall(hf.RegisterEvent, hf, "GUILD_ROSTER_UPDATE")
  hf:SetScript("OnEvent", function(_, e, a1, a2, a3, a4)
    if e == "GUILD_ROSTER_UPDATE" then rosterAt = nil; return end
    -- the name is never tested here: HeardFrom drops a hidden (secret) one
    if e == "CHAT_MSG_ADDON" then pcall(ns.HeardFrom, a4) else pcall(ns.HeardFrom, a2) end
  end)
end
