-- Thème plat façon EllesmereUI : couleur d'accent et police d'EUI si présents, repli propre sinon.
local ADDON, ns = ...

local T = {
  accent = { 0.808, 0.098, 0.094 },   -- WaR LegenD red #CE1918
  bg     = { 0.055, 0.058, 0.066, 0.97 },
  header = { 0.030, 0.032, 0.038, 0.98 },
  card   = { 0.085, 0.090, 0.100, 0.92 },
  border = { 0, 0, 0, 1 },
  text   = { 0.92, 0.92, 0.94 },
  dim    = { 0.70, 0.72, 0.76 },
  kind   = { a = { 1.00, 0.80, 0.25 }, c = { 0.40, 0.72, 1.00 }, o = { 0.40, 0.72, 1.00 }, t = { 0.35, 0.90, 0.48 },
             h = { 0.95, 0.95, 0.95 }, i = { 0.80, 0.60, 1.00 } },
  font   = STANDARD_TEXT_FONT, bold = STANDARD_TEXT_FONT,
}
ns.T_ = T
local EUI = "Interface\\AddOns\\EllesmereUI\\media\\fonts\\"
local fonts, accents = {}, {}
ns.skin = nil

function ns.IsLoaded(name)
  if C_AddOns and C_AddOns.IsAddOnLoaded then return C_AddOns.IsAddOnLoaded(name) end
  return IsAddOnLoaded and IsAddOnLoaded(name)
end

local function SetFont(fs)
  local ok = pcall(fs.SetFont, fs, fs._bold and T.bold or T.font, fs._size, fs._flags)
  if not ok or not fs:GetFont() then fs:SetFont(STANDARD_TEXT_FONT, fs._size, fs._flags) end
end
ns.SetFont = SetFont

function ns.Text(parent, size, color, bold, flags)
  local fs = parent:CreateFontString(nil, "OVERLAY")
  fs._size, fs._flags, fs._bold = size, flags or "", bold
  fs:SetShadowColor(0, 0, 0, 0.9); fs:SetShadowOffset(1, -1)
  SetFont(fs)
  fs:SetTextColor(unpack(color or T.text))
  fs:SetJustifyH("LEFT"); fs:SetJustifyV("TOP")
  fs:SetWordWrap(true)
  table.insert(fonts, fs)
  return fs
end

function ns.Tex(parent, layer, c)
  local t = parent:CreateTexture(nil, layer or "BACKGROUND")
  t:SetColorTexture(c[1], c[2], c[3], c[4] or 1)
  return t
end
local Tex = ns.Tex

function ns.Flat(frame, bg, border)
  frame._bg = Tex(frame, "BACKGROUND", bg); frame._bg:SetAllPoints()
  frame._edges = {}
  for _, side in ipairs({ "TOP", "BOTTOM", "LEFT", "RIGHT" }) do
    local e = Tex(frame, "BORDER", border or T.border)
    if side == "TOP" or side == "BOTTOM" then e:SetPoint(side .. "LEFT"); e:SetPoint(side .. "RIGHT"); e:SetHeight(1)
    else e:SetPoint("TOP" .. side); e:SetPoint("BOTTOM" .. side); e:SetWidth(1) end
    frame._edges[side] = e
  end
end

function ns.Accent(t, a)
  t._accentAlpha = a or 1
  table.insert(accents, t)
  t:SetColorTexture(T.accent[1], T.accent[2], T.accent[3], t._accentAlpha)
end

function ns.Hex(c)
  local function b(v) return math.floor(math.max(0, math.min(1, v)) * 255 + 0.5) end
  return ("|cff%02x%02x%02x"):format(b(c[1]), b(c[2]), b(c[3]))
end

function ns.ShowTip(owner, lines)
  GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
  GameTooltip:ClearLines()
  for i, l in ipairs(lines) do
    if type(l) == "table" then GameTooltip:AddLine(l[1], l[2], l[3], l[4], true)
    elseif i == 1 then GameTooltip:AddLine(l, 1, 1, 1, true)
    else GameTooltip:AddLine(l, 0.85, 0.85, 0.85, true) end
  end
  GameTooltip:Show()
end
function ns.HideTip() GameTooltip:Hide() end

function ns.Button(parent, w, h, label, onClick, tip)
  local b = CreateFrame("Button", nil, parent)
  b:SetSize(w, h)
  ns.Flat(b, { 0.12, 0.125, 0.14, 0.95 })
  b.hl = Tex(b, "HIGHLIGHT", { 1, 1, 1, 0.07 }); b.hl:SetAllPoints()
  b.label = ns.Text(b, 12, T.text, true)
  b.label:SetPoint("CENTER"); b.label:SetJustifyH("CENTER"); b.label:SetWordWrap(false)
  b.label:SetText(label)
  b:SetScript("OnClick", function(self, ...)
    PlaySound(SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or 856)
    onClick(self, ...)
  end)
  b:SetScript("OnEnable", function(self) self.label:SetTextColor(unpack(T.text)); self:SetAlpha(1) end)
  b:SetScript("OnDisable", function(self) self.label:SetTextColor(unpack(T.dim)); self:SetAlpha(0.55) end)
  if tip then
    b:SetScript("OnEnter", function(self) ns.ShowTip(self, type(tip) == "function" and tip() or tip) end)
    b:SetScript("OnLeave", ns.HideTip)
  end
  return b
end

function ns.Primary(b)
  ns.Accent(b._bg, 0.22)
  for _, e in pairs(b._edges) do ns.Accent(e, 0.9) end
end

function ns.Chip(parent)
  local c = CreateFrame("Frame", nil, parent)
  c:SetHeight(19)
  c.bg = Tex(c, "BACKGROUND", { 1, 1, 1, 0.1 }); c.bg:SetAllPoints()
  c.edge = Tex(c, "ARTWORK", { 1, 1, 1, 1 }); c.edge:SetPoint("TOPLEFT"); c.edge:SetPoint("BOTTOMLEFT"); c.edge:SetWidth(2)
  c.text = ns.Text(c, 10, T.text, true); c.text:SetPoint("LEFT", 7, 0); c.text:SetWordWrap(false); c.text:SetJustifyV("MIDDLE")
  return c
end
function ns.SetChip(c, label, col)
  if not label then c:Hide() return end
  c.text:SetText(label); c.text:SetTextColor(col[1], col[2], col[3])
  c.bg:SetColorTexture(col[1], col[2], col[3], 0.14); c.edge:SetColorTexture(col[1], col[2], col[3], 1)
  c:SetWidth(c.text:GetStringWidth() + 14); c:Show()
end

-- icône officielle de classe en texte (|T...|t), pour les puces et les lignes
function ns.ClassIconText(cls, size)
  local c = CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[cls]
  if not c then return "" end
  size = size or 14
  return ("|TInterface\\TargetingFrame\\UI-Classes-Circles:%d:%d:0:0:256:256:%d:%d:%d:%d|t "):format(size, size, c[1] * 256, c[2] * 256, c[3] * 256, c[4] * 256)
end

-- majuscules qui gèrent les accents français (string.upper ne touche que l'ASCII)
local ACC = { ["é"] = "É", ["è"] = "È", ["ê"] = "Ê", ["ë"] = "Ë", ["à"] = "À", ["â"] = "Â", ["ç"] = "Ç",
  ["î"] = "Î", ["ï"] = "Ï", ["ô"] = "Ô", ["û"] = "Û", ["ù"] = "Ù", ["ü"] = "Ü" }
function ns.Upper(s)
  if not s then return "" end
  s = s:upper()
  for a, b in pairs(ACC) do s = s:gsub(a, b) end
  return s
end

function ns.ClassInfo(cls)
  local name = (LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[cls]) or (cls:sub(1, 1) .. cls:sub(2):lower())
  local c = RAID_CLASS_COLORS and RAID_CLASS_COLORS[cls]
  return name, c and { c.r, c.g, c.b } or { 0.41, 0.8, 0.94 }
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
  if ns.Render then ns.Render() end
end

if EllesmereUI and EllesmereUI.RegisterSkin then
  EllesmereUI.RegisterSkin(ADDON, function(S)
    ns.skin = S
    if S.OnLooksChanged then S.OnLooksChanged(ns.ApplyLooks) end
    ns.ApplyLooks()
  end)
end
