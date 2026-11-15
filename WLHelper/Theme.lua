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
  bg       = { 0.051, 0.055, 0.063, 0.97 }, -- #0D0E10 window backdrop
  panel    = { 0.086, 0.090, 0.102, 0.96 }, -- #16171A inputs, dropdown lists, tooltips
  line     = { 0.180, 0.192, 0.212, 1 },    -- #2E3136 rule under the header, input borders
  trackOff = { 0.239, 0.255, 0.275, 1 },    -- #3D4146 switch off, scrollbar thumb
  fg       = { 0.941, 0.945, 0.953 },       -- #F0F1F3 main text, titles
  text     = { 0.788, 0.800, 0.820 },       -- #C9CCD1 body sentences
  muted    = { 0.604, 0.620, 0.651 },       -- #9A9EA6 meta, descriptions, icons at rest
  faint    = { 0.420, 0.435, 0.463 },       -- #6B6F76 disabled, placeholders
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
  -- alpha layers (white or black over bg)
  cardFill     = { 1, 1, 1, 0.030 },
  cardEdge     = { 0, 0, 0, 0.70 },
  divider      = { 1, 1, 1, 0.06 },
  hoverFill    = { 1, 1, 1, 0.05 },
  pressFill    = { 0, 0, 0, 0.35 },
  btnFill      = { 1, 1, 1, 0.04 },
  btnEdge      = { 1, 1, 1, 0.22 },
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
T.header    = { 0.051, 0.055, 0.063, 1 }       -- = bg, opaque: no title-bar colour of its own
T.card      = { 0.079, 0.083, 0.091, 1 }       -- = cardFill over bg
T.hover     = { 0.098, 0.102, 0.110, 1 }       -- = hoverFill over bg
T.brandBg   = { 0.157, 0.061, 0.067, 1 }       -- = selFill over bg (never a solid red block)
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
  local okS, sw = pcall(fs.GetStringWidth, fs)
  local okW, w = pcall(fs.GetWidth, fs)
  if not (okS and okW) or type(sw) ~= "number" or type(w) ~= "number" or secret(sw) or secret(w) then return false end
  return w > 0 and sw > w + 0.5
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
    if type(l) == "table" then GameTooltip:AddLine(l[1], l[2], l[3], l[4], true)
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
    local ok, sw = pcall(self.label.GetStringWidth, self.label)
    if ok and type(sw) == "number" and not secret(sw) and sw > 0 then
      local need = math.ceil(sw) + 24
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
    local m = ns._chipMeasure
    if not m then m = UIParent:CreateFontString(nil, "OVERLAY"); m:Hide(); ns._chipMeasure = m end
    local okF, font, size, flags = pcall(c.text.GetFont, c.text)
    local w = 0
    if okF and font then
      pcall(m.SetFont, m, font, size, flags)
      m:SetText(c.text:GetText() or "")
      local getW = m.GetUnboundedStringWidth or m.GetStringWidth
      local ok, mw = pcall(getW, m)
      if ok and type(mw) == "number" and not secret(mw) then w = mw end
    end
    if w <= 0 then
      local getW = c.text.GetUnboundedStringWidth or c.text.GetStringWidth
      local ok, tw = pcall(getW, c.text)
      if ok and type(tw) == "number" and not secret(tw) then w = tw end
    end
    w = math.ceil(w) + 2
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
function ns.RegisterWindow(f)
  if not f then return end
  f.wlOwned = true
  for _, w in ipairs(ns.windows) do if w == f then return end end
  table.insert(ns.windows, f)
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
