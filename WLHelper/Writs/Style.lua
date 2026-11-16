-- Writs/Style.lua: WL Helper's components, shared by every window (the Writs modules, the home page,
-- the options, the GPS, and the guide through root.S). The tokens, the HD icons, the pixel borders,
-- the text helpers and the tooltip live in Theme.lua; here are the widgets built from them:
-- window, tabs, buttons, segmented, switch, input, card, list row, section header, empty state,
-- banner, toast, pill, counter, dropdown. Colours come only from the token table (S.C = root.Tok).
local ADDON, root = ...
root.Writs = root.Writs or {}
local ns = root.Writs

local S = {}
ns.S = S
root.S = S      -- the guide (UI.lua, Picker.lua, Journal.lua, Nav.lua) uses the same components
root.UI = S

local T = root.Tok
S.C = T
S.F = root.F
S.SP = root.SP
S.LOGO = root.LOGO
S.Hex = root.Hex
S.State = root.State
S.Tween = root.Tween
S.HEADER_H = 44          -- the header of the design system
S.LEGACY_HEADER_H = 38   -- windows that still place their content under a 38 px header
S.TABS_H = 32
S.FOOTER_H = 24
S.windows = root.windows

-- The size rule and the grids (Theme.lua, design system 3.1 and 3.22), under both namespaces so a
-- Writs module writes ns.Cols / ns.Grid like the guide does.
for _, k in ipairs({ "WinSize", "ScreenSize", "UIScale", "GRID", "Cols", "Columns", "Grid" }) do
    S[k] = root[k]
    ns[k] = root[k]
end

local function L(s) return ns.L and ns.L(s) or s end
local function secret(v) return root.IsSecret and root.IsSecret(v) end
local function num(v) return type(v) == "number" and not secret(v) and v or nil end

-- ---------------------------------------------------------------- primitives

-- S.Text(parent, size, color, bold): wraps to 2 lines by default (the container grows with it).
-- fs:SetWordWrap(true) makes it a paragraph (no line limit); fs:SetWordWrap(false) a single line
-- (use S.ClampLabel then, so the full text is in the tooltip).
function S.Text(parent, size, color, bold)
    local fs = root.Text(parent, size, color or T.text, bold)
    fs:SetJustifyV("MIDDLE")
    fs:SetWordWrap(true)
    if fs.SetMaxLines then fs:SetMaxLines(2) end
    local wrap = fs.SetWordWrap
    fs.SetWordWrap = function(self, on)
        wrap(self, on)
        if on and self.SetMaxLines then self:SetMaxLines(0) end
    end
    return fs
end

function S.Solid(parent, layer, c, a)
    local t = parent:CreateTexture(nil, layer or "BACKGROUND")
    t:SetColorTexture(c[1], c[2], c[3], a or c[4] or 1)
    return t
end

-- One physical pixel border; returns a setter setter(color, alpha).
function S.Border(frame, c, a)
    local set = root.Outline(frame, c or T.cardEdge, a)
    return set
end

-- A 1 px divider (white 0.06) anchored by the caller.
function S.Rule(parent, c) return root.Rule(parent, c or T.divider) end

function S.Tip(owner, lines)
    if root.ShowTip then root.ShowTip(owner, lines) end
end
function S.HideTip() GameTooltip:Hide() end

S.FitText = root.FitText        -- S.FitText(fs, maxLines, width, owner) -> height
S.ClampLabel = root.ClampLabel  -- S.ClampLabel(fs, fullText, owner)
S.IsCut = root.IsCut

-- ---------------------------------------------------------------- money, items, levels

local COIN = "|TInterface\\MoneyFrame\\UI-%sIcon:0:0:2:0|t"
-- 12345 -> "1 g 23 s 45 c" with the game's coin icons; negative values get a minus.
function S.Money(c)
    if not c then return "?" end
    local neg = c < 0
    c = math.floor(math.abs(c) + 0.5)
    local g, s, cp = math.floor(c / 10000), math.floor((c % 10000) / 100), c % 100
    local parts = {}
    if g > 0 then parts[#parts + 1] = g .. COIN:format("Gold") end
    if s > 0 or (g > 0 and cp > 0) then parts[#parts + 1] = s .. COIN:format("Silver") end
    if g == 0 and (cp > 0 or s == 0) then parts[#parts + 1] = cp .. COIN:format("Copper") end
    return (neg and "-" or "") .. table.concat(parts, " ")
end

function S.ItemIcon(id)
    local f = C_Item and C_Item.GetItemIconByID or GetItemIcon
    local ok, icon = pcall(f, id)
    return ok and icon or 134400
end

function S.QualityColor(id)
    local f = C_Item and C_Item.GetItemQualityByID
    local ok, q = pcall(f or function() return nil end, id)
    local c = ok and q and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[q]
    if c then return { c.r, c.g, c.b } end
    return T.fg
end

-- A zone level range coloured like the game colours quests against your level.
function S.LevelColor(level)
    if GetQuestDifficultyColor and level then
        local ok, c = pcall(GetQuestDifficultyColor, level)
        if ok and c then return { c.r, c.g, c.b } end
    end
    return T.muted
end

-- ---------------------------------------------------------------- icons

-- HD interface icons: S.HDIcon(tex, name, color) on an existing texture, S.Icon(parent, name, size,
-- layer, color) for a new one. Names: Media/Icons/<name>.tga (check, close, gear, pin...).
S.HDIcon = root.SetHDIcon
S.Icon = root.Icon
S.IconPath = root.IconPath
S.Painted = root.SetPainted   -- S.Painted(tex, path, size): game icon cropped 0.08-0.92, 48 px max

-- Modern art where this client has it: the first atlas of the list that exists; otherwise a file
-- every client has, with its own texture coordinates. A missing atlas never shows a green square.
local function TryAtlas(tex, name)
    if not (tex.SetAtlas and name) then return false end
    local ok, res = pcall(tex.SetAtlas, tex, name, false)
    if not ok or res == false then return false end
    local okG, cur = pcall(tex.GetAtlas, tex)
    return okG and type(cur) == "string" and cur:lower() == name:lower()
end

-- S.SetIcon(tex, { "atlas1", "atlas2" }, fallbackPath, { l, r, t, b }) -> true when an atlas was used.
function S.SetIcon(tex, atlases, path, coords)
    if type(atlases) == "string" then atlases = { atlases } end
    for _, a in ipairs(atlases or {}) do
        if TryAtlas(tex, a) then return true end
    end
    tex:SetTexture(path)
    if coords then tex:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
    elseif type(path) == "string" and path:find("^Interface\\Icons\\") then tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    else tex:SetTexCoord(0, 1, 0, 1) end
    return false
end

-- Whether an atlas exists (for |A...|a text markup, which shows nothing when it does not).
function S.HasAtlas(name)
    if not (C_Texture and C_Texture.GetAtlasInfo) then return false end
    local ok, info = pcall(C_Texture.GetAtlasInfo, name)
    return ok and info ~= nil
end

local CIRCLES = "Interface\\TargetingFrame\\UI-Classes-Circles"
-- The class's icon: the modern square one (cropped 0.02), else the old circle sheet.
function S.ClassIcon(tex, class)
    if not class then return false end
    if TryAtlas(tex, "classicon-" .. class:lower()) then
        tex:SetTexCoord(0.02, 0.98, 0.02, 0.98)
        return true
    end
    local tc = CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[class]
    if not tc then return false end
    tex:SetTexture(CIRCLES); tex:SetTexCoord(tc[1], tc[2], tc[3], tc[4])
    return true
end

-- Role icons: the modern ones, else the LFG portrait sheet (coordinates in 64ths).
local ROLE_SHEET = "Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES"
local ROLE_PX = { tank = { 0, 19, 22, 41 }, heal = { 20, 39, 1, 20 }, dps = { 20, 39, 22, 41 } }
local ROLE_ATLAS = {
    tank = { "roleicon-tiny-tank", "UI-LFG-RoleIcon-Tank", "groupfinder-icon-role-large-tank" },
    heal = { "roleicon-tiny-healer", "UI-LFG-RoleIcon-Healer", "groupfinder-icon-role-large-heal" },
    dps  = { "roleicon-tiny-dps", "UI-LFG-RoleIcon-DPS", "groupfinder-icon-role-large-dps" },
}
function S.RoleIcon(tex, role)
    role = ROLE_PX[role] and role or "dps"
    local px = ROLE_PX[role]
    return S.SetIcon(tex, ROLE_ATLAS[role], ROLE_SHEET, { px[1] / 64, px[2] / 64, px[3] / 64, px[4] / 64 })
end
-- The same icon as text markup, for labels.
function S.RoleMarkup(role, size)
    role = ROLE_PX[role] and role or "dps"
    size = size or 16
    for _, a in ipairs(ROLE_ATLAS[role]) do
        if S.HasAtlas(a) then return string.format("|A:%s:%d:%d|a", a, size, size) end
    end
    local px = ROLE_PX[role]
    return string.format("|T%s:%d:%d:0:-1:64:64:%d:%d:%d:%d|t", ROLE_SHEET, size, size, px[1], px[2], px[3], px[4])
end

-- An HD icon as text markup, at the font size (e.g. inside a sentence).
function S.IconMarkup(name, size, color)
    size = size or 14
    local c = color or T.muted
    local function b(v) return math.floor(v * 255 + 0.5) end
    return string.format("|T%s:%d:%d:0:-1:128:128:0:128:0:128:%d:%d:%d|t", root.IconPath(name), size, size, b(c[1]), b(c[2]), b(c[3]))
end

-- S.Glyph(parent, kind, size, color): an HD icon in a small frame (older name; kinds "x", "right",
-- "left", "down", "up", "check"). g:SetKind(kind), g:SetColor(c, a).
local GLYPH_HD = { x = "close", right = "chevron_right", left = "chevron_left", down = "chevron_down",
    up = "chevron_up", check = "check", plus = "plus", minus = "minus" }
function S.Glyph(parent, kind, size, color)
    local g = CreateFrame("Frame", nil, parent)
    size = size or 12
    g:SetSize(size, size)
    g.tex = g:CreateTexture(nil, "ARTWORK")
    -- the HD art has a margin: drawn a little larger than the box it sits in, centred on it
    local s = math.max(12, math.floor(size * 1.3 / 2 + 0.5) * 2)
    g.tex:SetSize(s, s); g.tex:SetPoint("CENTER")
    function g:SetColor(c, a)
        self.c, self.a = c, a
        self.tex:SetVertexColor(c[1], c[2], c[3], a or c[4] or 1)
    end
    function g:SetKind(k)
        local name = GLYPH_HD[k] or (root.HD_NAMES[k] and k) or "close"
        if self.kind == name then return end
        self.kind = name
        root.SetHDIcon(self.tex, name, self.c or T.muted, self.a)
    end
    g:SetKind(kind or "x")
    g:SetColor(color or T.muted)
    return g
end

-- ---------------------------------------------------------------- icon buttons

-- Stock low-resolution textures some windows still pass: their HD equivalent.
local STOCK_HD = {
    ["Interface\\Buttons\\UI-StopButton"] = "close", ["Interface\\Buttons\\UI-OptionsButton"] = "gear",
    ["Interface\\Buttons\\UI-RefreshButton"] = "refresh", ["Interface\\Buttons\\UI-MinusButton-Up"] = "minus",
    ["Interface\\Buttons\\UI-PlusButton-Up"] = "plus", ["Interface\\Buttons\\UI-CheckBox-Check"] = "check",
    ["Interface\\Buttons\\UI-Panel-MinimizeButton-Up"] = "close", ["Interface\\Common\\VoiceChat-Speaker"] = "info",
}
local function HDNameFor(texture)
    if type(texture) == "string" then
        if root.HD_NAMES[texture] then return texture end
        return STOCK_HD[texture]
    elseif type(texture) == "table" then
        if texture.hd then return texture.hd end
        for _, a in ipairs(texture.atlases or {}) do
            local l = a:lower()
            if l:find("setting") or l:find("gear") or l:find("cog") then return "gear" end
            if l:find("refresh") then return "refresh" end
        end
        if texture.path then return STOCK_HD[texture.path] end
    end
end
S.HDNameFor = HDNameFor

-- S.IconButton(parent, texture, size, tip, onClick): an HD icon (18 px in a 28 hit area, 16 in 24)
-- with a soft square under the mouse. texture: an HD icon name ("gear"), a file path, or
-- { atlases = { ... }, path = file }. b:SetIcon(name), b:SetToggled(on).
function S.IconButton(parent, texture, size, tip, onClick)
    size = size or 28
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(size, size)
    b.wlOwned = true
    local iconSize = size >= 28 and 18 or (size >= 24 and 16 or math.max(12, size - 6))
    b.hl = S.Solid(b, "BACKGROUND", T.hoverFill); b.hl:SetAllPoints(); b.hl:SetAlpha(0)
    b.press = S.Solid(b, "BORDER", T.pressFill); b.press:SetAllPoints(); b.press:Hide()
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetSize(iconSize, iconSize)
    b.icon:SetPoint("CENTER")
    local hd = HDNameFor(texture)
    b.hd = hd
    if hd then root.SetHDIcon(b.icon, hd, T.muted)
    elseif type(texture) == "table" then S.SetIcon(b.icon, texture.atlases, texture.path, texture.coords)
    elseif texture then b.icon:SetTexture(texture) end
    local function Paint()
        local hov = b.hov or 0
        local enabled = b:IsEnabled() ~= false
        b:SetAlpha(enabled and 1 or T.disabledAlpha)
        b.hl:SetAlpha(enabled and hov or 0)
        local c = b.toggled and T.accentSoft or (hov > 0.5 and T.fg or T.muted)
        if b.tint then c = b.tint end
        if hd or b.hd then b.icon:SetVertexColor(c[1], c[2], c[3])
        else local v = 0.75 + 0.25 * hov; b.icon:SetVertexColor(v, v, v) end
    end
    b.Paint = Paint
    function b:SetIcon(name, color)
        self.hd = name; hd = name; self.tint = color
        root.SetHDIcon(self.icon, name, color or T.muted); Paint()
    end
    function b:SetToggled(on) self.toggled = on and true or nil; Paint() end
    function b:ApplyState(state)
        if state == "disabled" then self:Disable() elseif state == "selected" then self:SetToggled(true)
        else self:Enable(); self:SetToggled(false) end
        Paint()
    end
    b:SetScript("OnEnter", function(self)
        if self:IsEnabled() ~= false then root.Tween(self, self.hov or 0, 1, 0.10, function(v) self.hov = v; Paint() end) end
        local t = type(tip) == "function" and tip() or tip
        if t then S.Tip(self, t) end
    end)
    b:SetScript("OnLeave", function(self)
        root.Tween(self, self.hov or 0, 0, 0.10, function(v) self.hov = v; Paint() end)
        S.HideTip()
    end)
    b:SetScript("OnMouseDown", function(self)
        if self:IsEnabled() == false then return end
        self.press:Show(); self.icon:SetPoint("CENTER", 0, -1)
    end)
    b:SetScript("OnMouseUp", function(self) self.press:Hide(); self.icon:SetPoint("CENTER", 0, 0) end)
    b:SetScript("OnEnable", Paint)
    b:SetScript("OnDisable", Paint)
    b:SetScript("OnClick", onClick)
    Paint()
    return b
end

-- A close button: the HD cross. size is the hit area (28 in a header).
function S.CloseButton(parent, size, onClick, tip)
    local b = S.IconButton(parent, "close", size or 28,
        tip or { L("Fermer"), L("Clic : fermer la fenêtre") }, onClick)
    b.glyph = { SetColor = function(_, c) b.tint = c; b.Paint() end, SetKind = function() end }
    return b
end

-- ---------------------------------------------------------------- buttons

-- S.Button(parent, label, width, height, kind, onClick, tip)
-- kind: "primary" (accent fill, the one main action of a view), "secondary" (default), "ghost"
-- (link text), "danger" (destructive, two-step with b:SetConfirm), "warn" and "info" (older names:
-- a secondary button). The button is never narrower than its label: width is a minimum.
-- b:SetText(t), b:SetIcon(name), b:SetKind(kind), b:SetConfirm(text), b:Flash(text),
-- b:SetDisabledReason(text), b:SetChevron(on).
function S.Button(parent, label, width, height, kind, onClick, tip)
    kind = kind or "secondary"
    local b = CreateFrame("Button", nil, parent)
    height = height or 28
    b.wlOwned = true
    b.kind = kind
    b.minW = width or 0
    local setW = b.SetWidth
    setW(b, math.max(b.minW, 1)); b:SetHeight(height)
    b.fill = S.Solid(b, "BACKGROUND", T.btnFill); b.fill:SetAllPoints()
    b.press = S.Solid(b, "BORDER", T.pressFill); b.press:SetAllPoints(); b.press:Hide()
    b.border = S.Border(b, T.btnEdge)
    b.content = CreateFrame("Frame", nil, b)
    b.content:SetAllPoints()
    b.label = S.Text(b.content, root.F.label, T.fg, false)
    b.label:SetJustifyH("CENTER")
    b.label:SetWordWrap(false)
    if b.label.SetMaxLines then b.label:SetMaxLines(1) end
    b.icon = b.content:CreateTexture(nil, "ARTWORK")
    b.icon:SetSize(16, 16); b.icon:Hide()
    b.chev = b.content:CreateTexture(nil, "ARTWORK")
    b.chev:SetSize(10, 10); b.chev:Hide()
    b.under = S.Solid(b.content, "ARTWORK", T.fg)
    b.under:SetPoint("TOPLEFT", b.label, "BOTTOMLEFT", 0, -1)
    b.under:SetPoint("TOPRIGHT", b.label, "BOTTOMRIGHT", 0, -1)
    root.PixelLine(b.content, b.under, true)
    b.under:Hide()

    local labelSet = b.label.SetText
    local function Need()
        local w = root.TextWidth(b.label) + 24
        if b.icon:IsShown() then w = w + 16 + 6 end
        if b.chev:IsShown() then w = w + 10 + 4 end
        return w + (b.extraW or 0)
    end
    local function Layout()
        local dy = b.pressed and -1 or 0
        if b.CustomLayout then b:CustomLayout(dy) return end
        local iconW = b.icon:IsShown() and 22 or 0
        local chevW = b.chev:IsShown() and 14 or 0
        b.label:ClearAllPoints()
        b.label:SetPoint("CENTER", b.content, "CENTER", (iconW - chevW) / 2, dy)
        b.icon:ClearAllPoints(); b.icon:SetPoint("RIGHT", b.label, "LEFT", -6, 0)
        b.chev:ClearAllPoints(); b.chev:SetPoint("LEFT", b.label, "RIGHT", 4, 0)
    end
    function b:Fit()
        setW(self, math.max(self.minW or 0, Need()))
        Layout()
    end
    -- the caller's width is a minimum: the label always fits
    b.SetWidth = function(self, w) self.minW = w or 0; self:Fit() end
    b.SetSize = function(self, w, hh) self:SetHeight(hh); self:SetWidth(w) end
    local function Paint()
        local hov = b.hov or 0
        local enabled = b:IsEnabled() ~= false
        if not enabled then hov = 0 end
        local k = b.kind
        b:SetAlpha(enabled and 1 or T.disabledAlpha)
        b.press:SetShown(b.pressed and k ~= "primary" and k ~= "ghost")
        b.under:SetShown(k == "ghost" and hov > 0.5)
        if k == "primary" then
            local c = b.pressed and T.accentPress or (hov > 0.5 and T.accentHover or T.accent)
            b.fill:SetColorTexture(c[1], c[2], c[3], 1)
            b.border(c, 0)
            b.label:SetTextColor(T.fg[1], T.fg[2], T.fg[3], 1)
            b.icon:SetVertexColor(T.fg[1], T.fg[2], T.fg[3])
        elseif k == "ghost" then
            b.fill:SetColorTexture(1, 1, 1, 0)
            b.border(T.btnEdge, 0)
            local c = hov > 0.5 and T.fg or T.accentSoft
            b.label:SetTextColor(c[1], c[2], c[3], 1)
            b.icon:SetVertexColor(c[1], c[2], c[3]); b.chev:SetVertexColor(c[1], c[2], c[3])
        else
            local text, edge, edgeA = T.fg, T.btnEdge, T.btnEdge[4] + (T.btnEdgeHover[4] - T.btnEdge[4]) * hov
            if k == "danger" then
                text = T.bad
                if b.armed then edge, edgeA = T.bad, 1 elseif hov > 0 then edge, edgeA = T.bad, 0.6 * hov + T.btnEdge[4] * (1 - hov) end
            elseif k == "warn" then
                text, edge, edgeA = T.warn, T.warn, 0.45
            end
            b.fill:SetColorTexture(1, 1, 1, T.btnFill[4] + T.hoverFill[4] * hov)
            b.border(edge, edgeA)
            local a = (k == "danger" or k == "warn") and 1 or (0.85 + 0.15 * hov)
            b.label:SetTextColor(text[1], text[2], text[3], a)
            local ic = b.flashing and T.ok or text
            if b.painted then ic = { 1, 1, 1 } end
            b.icon:SetVertexColor(ic[1], ic[2], ic[3])
        end
    end
    b.Paint = Paint
    function b:SetText(t)
        labelSet(self.label, t or "")
        self:Fit()
    end
    b.label.SetText = function(_, t) b:SetText(t) end
    function b:GetText() return self.label:GetText() end
    function b:SetKind(k) self.kind = (k == "info") and "secondary" or (k or "secondary"); Paint() end
    function b:SetIcon(name)
        self.painted = nil
        if name then root.SetHDIcon(self.icon, name, T.fg); self.icon:Show() else self.icon:Hide() end
        self:Fit(); Paint()
    end
    -- a painted game icon (a thing: a map, a dungeon) instead of an HD glyph, cropped, never tinted
    function b:SetPaintedIcon(path)
        self.painted = true
        self.icon:SetTexture(path); self.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92); self.icon:Show()
        self:Fit(); Paint()
    end
    function b:SetChevron(on)
        if on then root.SetHDIcon(self.chev, "chevron_right", T.accentSoft); self.chev:Show() else self.chev:Hide() end
        self:Fit(); Paint()
    end
    function b:SetDisabledReason(text) self.disabledReason = text end
    -- destructive pattern: the first click asks (label becomes `text`), the second acts; back by itself after 4 s
    function b:SetConfirm(text) self.confirmText = text end
    function b:Disarm()
        if not self.armed then return end
        self.armed = nil
        self:SetText(self.normalText)
        Paint()
    end
    -- feedback in place: check icon + past tense for 2 s, then the normal label again
    function b:Flash(text, seconds)
        local normal, normalIcon = self:GetText(), self.icon:IsShown() and self.icon.wlIcon or nil
        self.flashing = true
        root.SetHDIcon(self.icon, "check", T.ok); self.icon:Show()
        self:SetText(text); Paint()
        local token = {}
        self.flashToken = token
        C_Timer.After(seconds or 2, function()
            if self.flashToken ~= token then return end
            self.flashing = nil
            if normalIcon then self:SetIcon(normalIcon) else self.icon:Hide() end
            self:SetText(normal); Paint()
        end)
    end
    function b:ApplyState(state)
        if state == "disabled" then self:Disable() else self:Enable() end
        Paint()
    end
    b:SetScript("OnEnter", function(self)
        if self:IsEnabled() ~= false then root.Tween(self, self.hov or 0, 1, 0.10, function(v) self.hov = v; Paint() end) end
        local t = type(tip) == "function" and tip() or tip
        if t then S.Tip(self, t)
        elseif self:IsEnabled() == false and self.disabledReason then S.Tip(self, { self:GetText() })
        elseif self.wlClamped then local cut = root.CutLines(self); if #cut > 0 then S.Tip(self, cut) end end
    end)
    b:SetScript("OnLeave", function(self)
        root.Tween(self, self.hov or 0, 0, 0.10, function(v) self.hov = v; Paint() end)
        S.HideTip()
    end)
    b:SetScript("OnMouseDown", function(self)
        if self:IsEnabled() == false then return end
        self.pressed = true; Layout(); Paint()
    end)
    b:SetScript("OnMouseUp", function(self) self.pressed = false; Layout(); Paint() end)
    b:SetScript("OnEnable", function() Paint() end)
    b:SetScript("OnDisable", function() b.pressed = false; Paint() end)
    if onClick then
        b:SetScript("OnClick", function(self, ...)
            if self.confirmText and not self.armed then
                self.armed = true
                self.normalText = self:GetText()
                self:SetText(self.confirmText)
                Paint()
                local token = {}
                self.armToken = token
                C_Timer.After(4, function() if self.armToken == token then self:Disarm() end end)
                return
            end
            if self.armed then self.armToken = nil; self:Disarm() end
            onClick(self, ...)
        end)
    end
    if kind == "info" then b.kind = "secondary" end
    b:SetText(label or "")
    Paint()
    return b
end

-- ---------------------------------------------------------------- switch

-- Switch bound to get() / set(v): 40 x 20, round track, round knob that slides.
-- b:AttachRow(row) makes the whole settings row the click target.
local DOT_L, DOT_R, DOT_T, DOT_B = 0.22, 0.78, 0.26, 0.82   -- the dot art inside its 128 px canvas
function S.Switch(parent, get, set, label)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(40, 20)
    b.wlOwned = true
    local function Piece(layer)
        local t = b:CreateTexture(nil, layer or "BACKGROUND")
        root.SetHDIcon(t, "dot", T.trackOff)
        return t
    end
    local capL, capR = Piece(), Piece()
    capL:SetSize(10, 20); capL:SetPoint("LEFT"); capL:SetTexCoord(DOT_L, 0.5, DOT_T, DOT_B)
    capR:SetSize(10, 20); capR:SetPoint("RIGHT"); capR:SetTexCoord(0.5, DOT_R, DOT_T, DOT_B)
    -- the bar is the dot's middle column stretched: same shading as the round caps
    local bar = Piece()
    bar:SetTexCoord(0.49, 0.51, DOT_T, DOT_B)
    bar:SetPoint("TOPLEFT", 10, 0); bar:SetPoint("BOTTOMRIGHT", -10, 0)
    local knob = Piece("ARTWORK")
    knob:SetSize(16, 16); knob:SetTexCoord(DOT_L, DOT_R, DOT_T, DOT_B)
    b.track, b.knob = { capL, capR, bar }, knob
    local function Paint()
        local on = b.on
        local c, a = on and T.accent or T.trackOff, on and 0.85 or 0.65
        for _, t in ipairs(b.track) do t:SetVertexColor(c[1], c[2], c[3], a) end
        local k = (on and 1 or 0.55) + ((b.hov and b:IsEnabled() ~= false) and 0.15 or 0)
        knob:SetVertexColor(1, 1, 1, math.min(1, k))
        b:SetAlpha(b:IsEnabled() ~= false and 1 or T.disabledAlpha)
    end
    local function PlaceKnob(x) knob:ClearAllPoints(); knob:SetPoint("CENTER", b, "LEFT", x, 0) end
    function b:Update()
        local on = get() and true or false
        local to = on and 30 or 10
        local from = self.kx or to
        self.on = on
        Paint()
        root.Tween(knob, from, to, 0.08, function(v) self.kx = v; PlaceKnob(v) end)
    end
    function b:ApplyState(state)
        if state == "disabled" then self:Disable() else self:Enable() end
        Paint()
    end
    function b:AttachRow(row)
        if not row then return end
        if row.EnableMouse then row:EnableMouse(true) end
        if row.HookScript then
            row:HookScript("OnMouseUp", function(_, button)
                if button ~= "RightButton" and b:IsEnabled() ~= false and b:IsVisible() then b:Click() end
            end)
            row:HookScript("OnEnter", function() b.hov = true; Paint() end)
            row:HookScript("OnLeave", function() b.hov = nil; Paint() end)
        end
    end
    b:SetScript("OnClick", function(self)
        if PlaySound then PlaySound(SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or 856) end
        set(not get()); self:Update()
    end)
    b:SetScript("OnEnter", function(self) self.hov = true; Paint(); if label then S.Tip(self, type(label) == "table" and label or { label }) end end)
    b:SetScript("OnLeave", function(self) self.hov = nil; Paint(); S.HideTip() end)
    b:SetScript("OnEnable", Paint)
    b:SetScript("OnDisable", Paint)
    b:Update()
    return b
end

-- ---------------------------------------------------------------- dropdown

local openList
-- S.Dropdown(parent, options, get, set, width): options = { { value, label }, ... }.
-- Trigger: a secondary button showing the current value and a chevron; list: up to 10 rows.
function S.Dropdown(parent, options, get, set, width)
    local d = S.Button(parent, "", width or 120, 28, "secondary")
    d.options = options
    d.arrow = d.content:CreateTexture(nil, "ARTWORK")
    d.arrow:SetSize(12, 12); d.arrow:SetPoint("RIGHT", -8, 0)
    root.SetHDIcon(d.arrow, "chevron_down", T.muted)
    d.extraW = 12 + 4 - 4   -- the chevron, its gap; the label's left inset is 8 instead of 12
    d.label:SetJustifyH("LEFT")
    function d:CustomLayout(dy)
        self.label:ClearAllPoints()
        self.label:SetPoint("LEFT", self.content, "LEFT", 8, dy)
        self.label:SetPoint("RIGHT", self.arrow, "LEFT", -4, dy)
    end
    local function LabelOf(v)
        for _, o in ipairs(d.options) do if o[1] == v then return o[2] end end
        return ""
    end
    function d:Update() self:SetText(LabelOf(get())) end
    local list
    local function Close() if list then list:Hide() end; if openList == list then openList = nil end end
    local function Open()
        if openList and openList ~= list then openList:Hide() end
        if not list then
            list = CreateFrame("Frame", nil, d)
            list:SetFrameStrata("DIALOG")
            S.Solid(list, "BACKGROUND", T.panel, 0.98):SetAllPoints()
            S.Border(list, T.cardEdge)
            list.rows = {}
            list.off = 0
            list:EnableMouseWheel(true)
            list:SetScript("OnMouseWheel", function(self, delta)
                local max = math.max(0, #d.options - 10)
                self.off = math.max(0, math.min(max, self.off - delta))
                self:Fill()
            end)
            function list:Fill()
                local n = math.min(10, #d.options)
                local cur = get()
                for i = 1, n do
                    local r = self.rows[i]
                    if not r then
                        r = CreateFrame("Button", nil, self)
                        r:SetHeight(24)
                        r:SetPoint("TOPLEFT", 1, -1 - (i - 1) * 24); r:SetPoint("TOPRIGHT", -1, -1 - (i - 1) * 24)
                        r.hl = S.Solid(r, "BACKGROUND", T.hoverFill); r.hl:SetAllPoints(); r.hl:SetAlpha(0)
                        r.check = root.Icon(r, "check", 12, "ARTWORK", T.accentSoft); r.check:SetPoint("LEFT", 8, 0)
                        r.text = S.Text(r, root.F.label, T.fg); r.text:SetPoint("LEFT", 26, 0); r.text:SetPoint("RIGHT", -8, 0)
                        r.text:SetJustifyH("LEFT"); S.ClampLabel(r.text, nil, r)
                        r:SetScript("OnEnter", function(self) self.hl:SetAlpha(1) end)
                        r:SetScript("OnLeave", function(self) self.hl:SetAlpha(0); S.HideTip() end)
                        r:SetScript("OnClick", function(self) set(self.value); d:Update(); Close() end)
                        self.rows[i] = r
                    end
                    local o = d.options[i + self.off]
                    r.value = o and o[1]
                    r.text:SetText(o and o[2] or "")
                    r.check:SetShown(o ~= nil and o[1] == cur)
                    r:Show()
                end
                for i = n + 1, #self.rows do self.rows[i]:Hide() end
                self:SetHeight(n * 24 + 2)
            end
        end
        list:ClearAllPoints()
        list:SetPoint("TOPLEFT", d, "BOTTOMLEFT", 0, -2)
        list:SetWidth(math.max(d:GetWidth() or 120, 120))
        list:Fill()
        list:Show()
        openList = list
    end
    d:SetScript("OnClick", function() if list and list:IsShown() then Close() else Open() end end)
    d:HookScript("OnHide", Close)
    d:Update()
    return d
end

-- ---------------------------------------------------------------- segmented

-- Segmented choice: options = { { value, label, disabled }, ... }. Height 28, segments touch,
-- the selected one has the selection fill and a 1 px accent border. holder:SetMaxWidth(w): when
-- the labels need more than w, the control becomes a dropdown instead of cutting them.
function S.Segmented(parent, options, get, set, height)
    height = height or 28
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetHeight(height)
    holder.wlOwned = true
    holder.border = S.Border(holder, T.btnEdge)
    local buttons, seps = {}, {}
    for i, o in ipairs(options) do
        local b = CreateFrame("Button", nil, holder)
        b:SetHeight(height)
        b.fill = S.Solid(b, "BACKGROUND", T.selFill); b.fill:SetAllPoints(); b.fill:SetAlpha(0)
        b.hl = S.Solid(b, "BACKGROUND", T.hoverFill); b.hl:SetAllPoints(); b.hl:SetAlpha(0)
        b.sel = S.Border(b, T.accent, 0)
        b.label = S.Text(b, root.F.label, T.muted, false)
        b.label:SetPoint("CENTER")
        b.label:SetWordWrap(false)
        b.label:SetText(o[2])
        b.value, b.disabled = o[1], o[3]
        b:SetScript("OnClick", function(self)
            if self.disabled then return end
            set(self.value); holder:Update()
        end)
        b:SetScript("OnEnter", function(self) self.hover = true; holder:Update(); if self.tip then S.Tip(self, self.tip) end end)
        b:SetScript("OnLeave", function(self) self.hover = nil; holder:Update(); S.HideTip() end)
        buttons[i] = b
        if i < #options then
            local sep = S.Solid(holder, "BORDER", T.divider)
            sep:SetWidth(1); root.PixelLine(holder, sep, false)
            seps[i] = sep
        end
    end
    holder.buttons = buttons
    local function Layout()
        local x = 0
        for i, b in ipairs(buttons) do
            local w = math.max(56, root.TextWidth(b.label) + 32)
            b:SetWidth(w)
            b:ClearAllPoints(); b:SetPoint("LEFT", x, 0)
            x = x + w
            if seps[i] then seps[i]:ClearAllPoints(); seps[i]:SetPoint("TOPLEFT", x, 0); seps[i]:SetPoint("BOTTOMLEFT", x, 0) end
        end
        return x
    end
    holder.natural = Layout()
    holder:SetWidth(holder.natural)
    function holder:Update()
        if self.dropdown and self.dropdown:IsShown() then self.dropdown:Update() return end
        local cur = get()
        for _, b in ipairs(buttons) do
            local on = b.value == cur
            b.fill:SetAlpha(on and 1 or 0)
            b.hl:SetAlpha((b.hover and not on and not b.disabled) and 1 or 0)
            b.sel(T.accent, on and 1 or 0)
            local c = b.disabled and T.faint or ((on or b.hover) and T.fg or T.muted)
            b.label:SetTextColor(c[1], c[2], c[3])
        end
    end
    function holder:SetDisabled(value, disabled)
        for _, b in ipairs(buttons) do if b.value == value then b.disabled = disabled end end
        holder:Update()
    end
    function holder:SetMaxWidth(w)
        self.maxW = w
        local tooWide = w and self.natural > w
        if tooWide and not self.dropdown then
            local opts = {}
            for _, o in ipairs(options) do if not o[3] then opts[#opts + 1] = { o[1], o[2] } end end
            self.dropdown = S.Dropdown(self, opts, get, function(v) set(v) end, math.min(w, 200))
            self.dropdown:SetPoint("LEFT")
        end
        for _, b in ipairs(buttons) do b:SetShown(not tooWide) end
        for _, s in pairs(seps) do s:SetShown(not tooWide) end
        if self.dropdown then self.dropdown:SetShown(tooWide and true or false) end
        self.border(T.btnEdge, tooWide and 0 or nil)
        self:SetWidth(tooWide and self.dropdown:GetWidth() or self.natural)
        self:Update()
    end
    holder:Update()
    return holder
end

-- Slider (min, max, step) bound to get() / set(v); fmt(v) gives the value text.
function S.Slider(parent, min, max, step, get, set, fmt, width)
    local s = CreateFrame("Slider", nil, parent)
    s:SetSize(width or 180, 16)
    s:SetOrientation("HORIZONTAL")
    s:SetMinMaxValues(min, max)
    s:SetValueStep(step)
    if s.SetObeyStepOnDrag then s:SetObeyStepOnDrag(true) end
    local track = S.Solid(s, "BACKGROUND", T.trackOff)
    track:SetPoint("LEFT"); track:SetPoint("RIGHT"); track:SetHeight(4)
    local thumb = s:CreateTexture(nil, "ARTWORK")
    root.SetHDIcon(thumb, "dot", { 1, 1, 1 })
    thumb:SetTexCoord(DOT_L, DOT_R, DOT_T, DOT_B)
    thumb:SetSize(14, 14)
    s:SetThumbTexture(thumb)
    s.value = S.Text(parent, root.F.label, T.muted)
    s.value:SetPoint("LEFT", s, "RIGHT", 12, 0)
    s.value:SetWidth(48)
    s.value:SetWordWrap(false)
    s:SetScript("OnValueChanged", function(self, v)
        v = math.floor(v / step + 0.5) * step
        set(v)
        self.value:SetText(fmt and fmt(v) or tostring(v))
    end)
    s:SetValue(get())
    s.value:SetText(fmt and fmt(get()) or tostring(get()))
    return s
end

-- ---------------------------------------------------------------- badges, counters, pills

-- Counter (a number on a tab or an icon): neutral; accent only when it counts things to act on now.
function S.Counter(parent)
    local c = CreateFrame("Frame", nil, parent)
    c:SetSize(18, 16)
    c.bg = S.Solid(c, "BACKGROUND", { 1, 1, 1, 0.10 }); c.bg:SetAllPoints()
    c.text = S.Text(c, root.F.foot, T.fg, true)
    c.text:SetPoint("CENTER"); c.text:SetWordWrap(false)
    function c:SetCount(n, urgent)
        if not n or n == 0 then self:Hide() return end
        self.text:SetText(n)
        if urgent then self.bg:SetColorTexture(T.accent[1], T.accent[2], T.accent[3], 1)
        else self.bg:SetColorTexture(1, 1, 1, 0.10) end
        self:SetWidth(math.max(18, root.TextWidth(self.text) + 8))
        self:Show()
    end
    c:Hide()
    return c
end

-- Pill: words, never codes ("Dans le sac", "En cours"). S.Pill(parent, text, color, icon);
-- p:Set(text, color, icon). Single line; the widest it may be is p.maxW (full text in its tooltip).
function S.Pill(parent, text, color, icon)
    local p = root.Chip(parent)
    p.icon = p:CreateTexture(nil, "ARTWORK")
    p.icon:SetSize(12, 12); p.icon:SetPoint("LEFT", 4, 0); p.icon:Hide()
    function p:Set(t, col, iconName)
        if not t then self:Hide() return end
        col = col or T.fg
        local neutral = (col == T.fg)
        if iconName then root.SetHDIcon(self.icon, iconName, col); self.icon:Show() else self.icon:Hide() end
        self.text:ClearAllPoints()
        self.text:SetPoint("LEFT", iconName and 20 or 6, 0)
        root.SetChip(self, t, col, self.maxW and (self.maxW - (iconName and 14 or 0)) or nil)
        if neutral then self.bg:SetColorTexture(1, 1, 1, 0.10); self.border({ 1, 1, 1 }, 0.20) end
    end
    if text then p:Set(text, color, icon) else p:Hide() end
    return p
end
S.Badge = S.Pill

-- ---------------------------------------------------------------- tabs

-- Tabs: list = { { key, label }, ... }; badge(key) may return a number (and true when it counts
-- things to act on now). Bar 32 px; tabs from x = 16, 4 apart; active: fill + 2 px accent underline.
-- When the tabs do not fit, the widest shrink first (down to 56) and show their full label in
-- the tooltip. bar:Update().
function S.Tabs(parent, list, get, set, badge)
    local bar = CreateFrame("Frame", nil, parent)
    bar:SetHeight(S.TABS_H)
    bar.wlOwned = true
    parent.wlTabs = bar
    local line = S.Solid(bar, "BORDER", T.divider)
    line:SetPoint("BOTTOMLEFT"); line:SetPoint("BOTTOMRIGHT"); root.PixelLine(bar, line, true)
    local tabs = {}
    bar.tabs = tabs
    for i, t in ipairs(list) do
        local b = CreateFrame("Button", nil, bar)
        b:SetHeight(S.TABS_H)
        b.fill = S.Solid(b, "BACKGROUND", T.tabFill); b.fill:SetAllPoints(); b.fill:SetAlpha(0)
        b.hl = S.Solid(b, "BACKGROUND", T.tabHover); b.hl:SetAllPoints(); b.hl:SetAlpha(0)
        b.label = S.Text(b, root.F.label, T.muted)
        b.label:SetPoint("LEFT", 12, 0)
        b.label:SetText(t[2])
        S.ClampLabel(b.label, t[2], b)
        b.badge = S.Counter(b)
        b.badge:SetPoint("LEFT", b.label, "RIGHT", 4, 0)
        b.under = S.Solid(b, "ARTWORK", T.accent)
        b.under:SetHeight(2)
        b.key = t[1]
        b:SetScript("OnClick", function(self) set(self.key) end)
        b:SetScript("OnEnter", function(self)
            self.hover = true; bar:Paint()
            local cut = root.CutLines(self)
            if #cut > 0 then S.Tip(self, cut) end
        end)
        b:SetScript("OnLeave", function(self) self.hover = nil; bar:Paint(); S.HideTip() end)
        tabs[i] = b
    end
    function bar:Paint()
        local cur = get()
        for _, b in ipairs(tabs) do
            local on = b.key == cur
            local c = (on or b.hover) and T.fg or T.muted
            b.label:SetTextColor(c[1], c[2], c[3])
            b.fill:SetAlpha(on and 1 or 0)
            b.hl:SetAlpha((b.hover and not on) and 1 or 0)
            b.under:SetShown(on)
        end
    end
    function bar:Update()
        local x = 16
        local widths, natural = {}, {}
        for i, b in ipairs(tabs) do
            local n, urgent = nil, nil
            if badge then n, urgent = badge(b.key) end
            if type(n) == "number" and n > 0 then b.badge:SetCount(n, urgent) else b.badge:Hide() end
            local sw = root.TextWidth(b.label)
            b.textW = sw
            local extra = b.badge:IsShown() and (b.badge:GetWidth() + 4) or 0
            natural[i] = sw
            widths[i] = math.max(56, sw + 24 + extra)
        end
        -- shrink the widest first when the bar is too narrow
        local avail = num(self:GetWidth())
        if avail and avail > 0 then
            local total = 16 + 4 * math.max(0, #tabs - 1)
            for _, w in ipairs(widths) do total = total + w end
            local guard = 0
            while total > avail - 16 and guard < 200 do
                guard = guard + 1
                local wi, ww = nil, 56
                for i, w in ipairs(widths) do if w > ww then wi, ww = i, w end end
                if not wi then break end
                local cut = math.min(ww - 56, total - (avail - 16))
                if cut <= 0 then break end
                widths[wi] = ww - cut; total = total - cut
            end
        end
        for i, b in ipairs(tabs) do
            local w = widths[i]
            local extra = b.badge:IsShown() and (b.badge:GetWidth() + 4) or 0
            local labelW = math.min(natural[i], w - 24 - extra)
            b.label:SetWidth(math.max(1, labelW + 1))
            b:SetWidth(w)
            b:ClearAllPoints(); b:SetPoint("TOPLEFT", x, 0)
            -- 2 px underline as wide as the text + 12, centred under it, on the bar's divider
            b.under:ClearAllPoints()
            b.under:SetWidth(math.min(w, labelW + 12))
            b.under:SetPoint("BOTTOMLEFT", b, "BOTTOMLEFT", 6, 0)
            x = x + w + 4
        end
        self:Paint()
    end
    bar:Update()
    return bar
end

-- ---------------------------------------------------------------- section header

-- Section header (32 px, 24 when tight): label 13 fg, optional count 11 muted, optional ghost link
-- at the right, 1 px divider at the bottom. h:Set(label, count).
-- tight: true or { tight = true }. h.after is the space a page leaves under it: 8 when tight
-- (24 + 8, inside a card or a column), 12 otherwise.
function S.SectionHeader(parent, label, count, linkLabel, onLink, tight)
    if type(tight) == "table" then tight = tight.tight end
    local h = CreateFrame("Frame", nil, parent)
    h.tight = tight and true or false
    h.after = tight and 8 or 12
    h:SetHeight(tight and 24 or 32)
    h.label = S.Text(h, root.F.body, T.fg)
    h.label:SetPoint("BOTTOMLEFT", 0, 6)
    h.label:SetWordWrap(false)
    S.ClampLabel(h.label, nil, h)
    h.count = S.Text(h, root.F.meta, T.muted)
    h.count:SetPoint("BOTTOMLEFT", h.label, "BOTTOMRIGHT", 6, 0)
    h.count:SetWordWrap(false)
    h.rule = S.Rule(h)
    h.rule:SetPoint("BOTTOMLEFT"); h.rule:SetPoint("BOTTOMRIGHT")
    if linkLabel then
        h.link = S.Button(h, linkLabel, 0, 24, "ghost", onLink)
        h.link:SetPoint("BOTTOMRIGHT", 0, 2)
        h.label:SetPoint("RIGHT", h.link, "LEFT", -12, 0)
    end
    function h:Set(text, n)
        self.label:SetText(text or "")
        if n then self.count:SetText(n); self.count:Show() else self.count:Hide() end
    end
    h:Set(label, count)
    return h
end

-- Older section label (options): 13 fg, sentence case.
function S.Section(parent, text)
    local fs = S.Text(parent, root.F.body, T.fg)
    fs:SetWordWrap(false)
    fs:SetText(text or "")
    return fs
end

-- ---------------------------------------------------------------- card

-- S.Card(parent, opts): cardFill + 1 px cardEdge, pad 12 (16 for a settings group).
-- opts: pad, icon (painted path, 32 px), title, line1 (13 text), line2 (11 muted), pill, pillColor,
-- onClick (adds the hover fill and a chevron), tip (lines or function).
-- c:SetContent(opts) and c:Fit(width) -> measured height.
function S.Card(parent, opts)
    opts = opts or {}
    local clickable = opts.onClick ~= nil
    local c = CreateFrame(clickable and "Button" or "Frame", nil, parent)
    c.wlOwned = true
    c.pad = opts.pad or 12
    c.bg = S.Solid(c, "BACKGROUND", T.cardFill); c.bg:SetAllPoints()
    c.hl = S.Solid(c, "BACKGROUND", T.hoverFill); c.hl:SetAllPoints(); c.hl:SetAlpha(0)
    c.edge = S.Border(c, T.cardEdge)
    c.iconFrame = CreateFrame("Frame", nil, c)
    c.iconFrame:SetSize(32, 32)
    c.icon = c.iconFrame:CreateTexture(nil, "ARTWORK"); c.icon:SetAllPoints()
    S.Border(c.iconFrame, T.cardEdge)
    c.iconFrame:Hide()
    c.title = S.Text(c, root.F.heading, T.fg)
    c.title:SetJustifyH("LEFT"); c.title:SetJustifyV("TOP")
    c.line1 = S.Text(c, root.F.body, T.text)
    c.line1:SetJustifyH("LEFT"); c.line1:SetJustifyV("TOP")
    c.line2 = S.Text(c, root.F.meta, T.muted)
    c.line2:SetJustifyH("LEFT"); c.line2:SetJustifyV("TOP")
    c.pill = S.Pill(c)
    if clickable then
        c.chev = root.Icon(c, "chevron_right", 16, "ARTWORK", T.muted)
        c.chev:SetPoint("RIGHT", -c.pad, 0)
        c:SetScript("OnClick", opts.onClick)
        c:SetScript("OnMouseDown", function(self) self.hl:SetColorTexture(T.pressFill[1], T.pressFill[2], T.pressFill[3], T.pressFill[4]) end)
        c:SetScript("OnMouseUp", function(self) self.hl:SetColorTexture(T.hoverFill[1], T.hoverFill[2], T.hoverFill[3], T.hoverFill[4]) end)
    end
    c:SetScript("OnEnter", function(self)
        if clickable then
            root.Tween(self, self.hov or 0, 1, 0.10, function(v) self.hov = v; self.hl:SetAlpha(v) end)
            self.chev:SetVertexColor(T.fg[1], T.fg[2], T.fg[3])
        end
        local t = type(self.tip) == "function" and self.tip() or self.tip
        if t then S.Tip(self, t) else local cut = root.CutLines(self); if #cut > 0 then S.Tip(self, cut) end end
    end)
    c:SetScript("OnLeave", function(self)
        if clickable then
            root.Tween(self, self.hov or 0, 0, 0.10, function(v) self.hov = v; self.hl:SetAlpha(v) end)
            self.chev:SetVertexColor(T.muted[1], T.muted[2], T.muted[3])
        end
        S.HideTip()
    end)
    function c:SetContent(o)
        o = o or {}
        if o.icon then S.Painted(self.icon, o.icon); self.iconFrame:Show() else self.iconFrame:Hide() end
        self.title:SetText(o.title or ""); self.title:SetShown(o.title ~= nil)
        self.line1:SetText(o.line1 or ""); self.line1:SetShown(o.line1 ~= nil)
        self.line2:SetText(o.line2 or ""); self.line2:SetShown(o.line2 ~= nil)
        if o.pill then self.pill:Set(o.pill, o.pillColor, o.pillIcon) else self.pill:Hide() end
        if o.tip ~= nil then self.tip = o.tip end
    end
    function c:Fit(width)
        width = width or num(self:GetWidth()) or 0
        local pad = self.pad
        local x = pad + (self.iconFrame:IsShown() and 40 or 0)
        local right = pad + (self.chev and 24 or 0)
        local textW = math.max(40, width - x - right)
        self.iconFrame:ClearAllPoints(); self.iconFrame:SetPoint("TOPLEFT", pad, -pad)
        local pillW = self.pill:IsShown() and (num(self.pill:GetWidth()) or 0) + 8 or 0
        self.pill:ClearAllPoints(); self.pill:SetPoint("TOPRIGHT", -right, -pad)
        local y = pad
        local h = 0
        if self.title:IsShown() then
            self.title:ClearAllPoints(); self.title:SetPoint("TOPLEFT", x, -y)
            h = root.FitText(self.title, 2, textW - pillW, self)
            y = y + h
        end
        if self.line1:IsShown() then
            if y > pad then y = y + 4 end
            self.line1:ClearAllPoints(); self.line1:SetPoint("TOPLEFT", x, -y)
            y = y + root.FitText(self.line1, 2, textW, self)
        end
        if self.line2:IsShown() then
            if y > pad then y = y + 3 end
            self.line2:ClearAllPoints(); self.line2:SetPoint("TOPLEFT", x, -y)
            y = y + root.FitText(self.line2, 2, textW, self)
        end
        local inner = math.max(y - pad, self.iconFrame:IsShown() and 32 or 0)
        local total = pad + inner + pad
        self:SetHeight(total)
        return total
    end
    c.tip = opts.tip
    c:SetContent(opts)
    return c
end

-- ---------------------------------------------------------------- the WL Helper window (Hub)

-- Draws a page or module icon: a painted path (white, cropped) or { hd = glyph, color } (an HD
-- glyph in its own colour, else `rest`). -> true for a glyph
function S.PaintIcon(tex, icon, rest)
    if type(icon) == "table" then
        root.SetHDIcon(tex, icon.hd, icon.color or rest or T.muted)
        return true
    end
    S.Painted(tex, icon); tex:SetVertexColor(1, 1, 1)
    return false
end

-- S.NavItem(parent, def): one entry of a side nav (32 px; the caller places it 8 px from both
-- edges). Icon box 20 at x=8: a painted icon fills it inside a 1 px edge, an HD glyph is 16 px,
-- no edge, tinted like the label. Label 12 at x=36, one line (full text in the tooltip), a counter
-- at the right (search hits). Selected: selFill and the fg label, no side band; hover: hoverFill
-- and fg. def: key, label (shown text), icon, tip (lines or function), onClick(self),
-- onHover(self) (the caller repaints its nav). b:Paint(selected).
function S.NavItem(parent, def)
    local b = CreateFrame("Button", nil, parent)
    b.wlOwned = true
    b:SetHeight(32)
    b.sel = S.Solid(b, "BACKGROUND", T.selFill); b.sel:SetAllPoints(); b.sel:Hide()
    b.hl = S.Solid(b, "BACKGROUND", T.hoverFill); b.hl:SetAllPoints(); b.hl:SetAlpha(0)
    b.press = S.Solid(b, "BORDER", T.pressFill); b.press:SetAllPoints(); b.press:Hide()
    b.iconFrame = CreateFrame("Frame", nil, b)
    b.iconFrame:SetSize(20, 20); b.iconFrame:SetPoint("LEFT", 8, 0)
    b.icon = b.iconFrame:CreateTexture(nil, "ARTWORK")
    b.hdIcon = S.PaintIcon(b.icon, def.icon or { hd = "dot" })
    b.hdColor = b.hdIcon and type(def.icon) == "table" and def.icon.color or nil
    if b.hdIcon then
        b.icon:SetSize(16, 16); b.icon:SetPoint("CENTER")
    else
        b.icon:SetAllPoints()
        S.Border(b.iconFrame, T.cardEdge)
    end
    b.count = S.Counter(b)
    b.count:SetPoint("RIGHT", -8, 0)
    b.label = S.Text(b, root.F.label, T.muted)
    b.label:SetPoint("LEFT", 36, 0); b.label:SetPoint("RIGHT", -8, 0)
    b.label:SetJustifyH("LEFT")
    b.label:SetText(def.label or "")
    S.ClampLabel(b.label, def.label, b)
    b.key = def.key
    function b:Paint(selected)
        self.selected = selected and true or nil
        self.sel:SetShown(self.selected == true)
        local c = (self.selected or self.hover) and T.fg or T.muted
        self.label:SetTextColor(c[1], c[2], c[3])
        if self.hdIcon and not self.hdColor then self.icon:SetVertexColor(c[1], c[2], c[3]) end
        self.iconFrame:SetAlpha((self.selected or self.hover) and 1 or 0.8)
    end
    b:SetScript("OnEnter", function(self)
        root.Tween(self.hl, num(self.hl:GetAlpha()) or 0, 1, 0.10, function(v) self.hl:SetAlpha(v) end)
        self.hover = true
        if def.onHover then def.onHover(self) else self:Paint(self.selected) end
        local t = type(def.tip) == "function" and def.tip(self) or def.tip
        if t then S.Tip(self, t) end
    end)
    b:SetScript("OnLeave", function(self)
        root.Tween(self.hl, num(self.hl:GetAlpha()) or 0, 0, 0.10, function(v) self.hl:SetAlpha(v) end)
        self.hover = nil
        if def.onHover then def.onHover(self) else self:Paint(self.selected) end
        S.HideTip()
    end)
    b:SetScript("OnMouseDown", function(self) self.press:Show() end)
    b:SetScript("OnMouseUp", function(self) self.press:Hide() end)
    b:SetScript("OnClick", function(self) if def.onClick then def.onClick(self) end end)
    b:Paint(false)
    return b
end

-- S.NavHeader(parent, text): an activity's title in the nav, 24 px: 11 muted at x=16, its baseline
-- 4 px above the first item under it. Sentence case, never capitals (DESIGN 1.2).
function S.NavHeader(parent, text)
    local h = CreateFrame("Frame", nil, parent)
    h:SetHeight(24)
    h.label = S.Text(h, root.F.meta, T.muted)
    h.label:SetPoint("BOTTOMLEFT", 16, 4); h.label:SetPoint("RIGHT", -8, 0)
    h.label:SetJustifyH("LEFT")
    h.label:SetText(text or "")
    S.ClampLabel(h.label, nil, h)
    return h
end

-- S.HubRow(parent, onClick): one window on the Hub's Home (DESIGN 3.20), 46 px, the width set by
-- the caller (a column, 306 at 860). The whole line is the click target (3.9): cardFill, a 1 px
-- edge, hoverFill under the mouse, pressFill on click. Icon box 28 at x=8 (painted, 1 px cardEdge;
-- an HD glyph is 16 in it), the name 13 fg at x=44 (top 7), one state line 11 under it (cut, the
-- full text in the tooltip), chevron_right 16 muted at the right, a 6 px accent dot left of it when
-- something waits. A switched-off module: alpha 0.5, an "Éteint" pill instead of the chevron, and a
-- click turns it back on (r.onTurnOn).
-- r:Show2{ title, line1, line2, lineColor, pill, pillColor, hint, dot } (the old Home card's call),
-- r:Set(name, state, hint, dot, reason) (the old tool tile's call), r:ShowOff(title),
-- r:SetIcon(icon), r:SetOnRightClick(fn, hint). r.desc: what the window does (tooltip).
function S.HubRow(parent, onClick)
    local r = CreateFrame("Button", nil, parent)
    r.wlOwned = true
    r:SetHeight(46)
    r.bg = S.Solid(r, "BACKGROUND", T.cardFill); r.bg:SetAllPoints()
    S.Border(r, T.cardEdge)
    r.hl = S.Solid(r, "BORDER", T.hoverFill); r.hl:SetAllPoints(); r.hl:SetAlpha(0)
    r.press = S.Solid(r, "BORDER", T.pressFill); r.press:SetAllPoints(); r.press:Hide()
    r.iconFrame = CreateFrame("Frame", nil, r)
    r.iconFrame:SetSize(28, 28); r.iconFrame:SetPoint("LEFT", 8, 0)
    S.Border(r.iconFrame, T.cardEdge)
    r.icon = r.iconFrame:CreateTexture(nil, "ARTWORK")
    r.name = S.Text(r, root.F.body, T.fg)
    r.name:SetJustifyH("LEFT")
    r.name:SetPoint("TOPLEFT", 44, -7); r.name:SetPoint("RIGHT", -40, 0)
    S.ClampLabel(r.name, nil, r)
    r.stateText = S.Text(r, root.F.meta, T.muted)
    r.stateText:SetJustifyH("LEFT")
    r.stateText:SetPoint("TOPLEFT", r.name, "BOTTOMLEFT", 0, -2); r.stateText:SetPoint("RIGHT", -40, 0)
    S.ClampLabel(r.stateText, nil, r)
    r.title, r.line1 = r.name, r.stateText   -- the old card's names, for its callers
    r.chev = root.Icon(r, "chevron_right", 16, "ARTWORK", T.muted)
    r.chev:SetPoint("RIGHT", -8, 0)
    r.dot = r:CreateTexture(nil, "OVERLAY")
    r.dot:SetSize(6, 6); r.dot:SetPoint("RIGHT", -30, 0)
    root.SetHDIcon(r.dot, "dot", T.accent)
    r.dot:Hide()
    r.offPill = S.Pill(r)
    r.offPill:SetPoint("RIGHT", -8, 0)
    r.offPill:Hide()
    function r:SetIcon(icon)
        self.iconSrc = icon
        self.icon:ClearAllPoints()
        if S.PaintIcon(self.icon, icon or { hd = "dot" }, T.fg) then
            self.icon:SetSize(16, 16); self.icon:SetPoint("CENTER")
        else
            self.icon:SetAllPoints()
        end
    end
    local function TextRight()
        local right = 8 + 16 + 16          -- the chevron and the dot's place
        if r.offPill:IsShown() then right = 8 + (num(r.offPill:GetWidth()) or 40) + 8 end
        r.name:SetPoint("RIGHT", -right, 0); r.stateText:SetPoint("RIGHT", -right, 0)
    end
    local function Look(off)
        r.off = off and true or false
        r:SetAlpha(off and 0.5 or 1)
        r.chev:SetShown(not off)
        if off then r.offPill:Set(L("Éteint"), T.muted); r.offPill:Show(); r.dot:Hide() else r.offPill:Hide() end
        TextRight()
    end
    -- the old card's call: the pill goes before line 1 ("Étape 3 sur 6 · Deadmines"); line 2 and
    -- the hint go to the tooltip
    function r:Show2(o)
        o = o or {}
        self.name:SetText(o.title or "")
        local state = o.line1 or ""
        if o.pill and o.pill ~= "" then state = (state ~= "") and (o.pill .. " · " .. state) or o.pill end
        self.state, self.line2, self.clickHint, self.reason = state, o.line2, o.hint, nil
        self.stateText:SetText(state)
        local lc = o.lineColor or T.muted
        self.stateText:SetTextColor(lc[1], lc[2], lc[3])
        self.dot:SetShown(o.dot and true or false)
        Look(false)
    end
    -- the old tile's call
    function r:Set(name, state, hint, dot, reason)
        self.name:SetText(name or "")
        self.state, self.line2, self.clickHint, self.reason = state, nil, hint, reason
        self.stateText:SetText(state or "")
        self.stateText:SetTextColor(T.muted[1], T.muted[2], T.muted[3])
        self.dot:SetShown(dot and true or false)
        Look(false)
    end
    function r:ShowOff(title, state, hint)
        self.name:SetText(title or self.name:GetText() or "")
        self.state, self.line2, self.clickHint, self.reason = state or L("Module éteint"), nil, hint or L("Clic : allumer le module"), nil
        self.stateText:SetText(self.state)
        self.stateText:SetTextColor(T.muted[1], T.muted[2], T.muted[3])
        Look(true)
    end
    function r:SetOnRightClick(fn, hint)
        self.onRightClick, self.rightHint = fn, fn and hint or nil
        self:RegisterForClicks(fn and "AnyUp" or "LeftButtonUp")
    end
    -- name, state, line 2, what it does, why the dot, the clicks
    function r:TipLines()
        local t = { self.name:GetText() or "" }
        local function add(x) if type(x) == "string" and x ~= "" then t[#t + 1] = x end end
        add(self.state); add(self.line2); add(self.desc)
        if self.dot:IsShown() then add(self.reason) end
        add(self.clickHint)
        add(self.rightHint)
        return t
    end
    r.tip = function() return r:TipLines() end
    r:SetScript("OnEnter", function(self)
        root.Tween(self, self.hov or 0, 1, 0.10, function(v) self.hov = v; self.hl:SetAlpha(v) end)
        self.chev:SetVertexColor(T.fg[1], T.fg[2], T.fg[3])
        S.Tip(self, self:TipLines())
    end)
    r:SetScript("OnLeave", function(self)
        root.Tween(self, self.hov or 0, 0, 0.10, function(v) self.hov = v; self.hl:SetAlpha(v) end)
        self.chev:SetVertexColor(T.muted[1], T.muted[2], T.muted[3])
        S.HideTip()
    end)
    r:SetScript("OnMouseDown", function(self)
        self.press:Show()
        self.iconFrame:SetPoint("LEFT", 8, -1)
    end)
    r:SetScript("OnMouseUp", function(self)
        self.press:Hide()
        self.iconFrame:SetPoint("LEFT", 8, 0)
    end)
    r:SetScript("OnClick", function(self, button)
        if button == "RightButton" then
            -- its settings, even switched off (the module's switch is there too)
            if self.onRightClick then self.onRightClick(self) end
            return
        end
        if self.off then
            if self.onTurnOn then self.onTurnOn(self) end
            return
        end
        if onClick then onClick(self) end
    end)
    Look(false)
    return r
end

-- ---------------------------------------------------------------- list row

-- S.ListRow(parent, opts): opts.density "dense" (min 36, name 12) or "reading" (min 44, name 13),
-- opts.onClick, opts.tip, opts.zebra (index: black 0.10 / 0.18 fill instead of cardFill).
-- row:Set{ icon = path | hd = name, name, nameColor, detail, value, unit, rank }
-- row:AddAction(iconName, tip, onClick), row:SetSelected(on), row:Fit(width) -> measured height.
-- row:Fit(width, { columns = true }): wide mode; from S.LISTROW_WIDE (640) the detail sits in its own
-- column at x + 45 % of the text area (row.detailX), on the name's line, instead of under the name.
S.LISTROW_WIDE = 640
function S.ListRow(parent, opts)
    opts = opts or {}
    local reading = opts.density == "reading"
    local r = CreateFrame("Button", nil, parent)
    r.wlOwned = true
    r.minH = reading and 44 or 36
    r.bg = S.Solid(r, "BACKGROUND", T.cardFill); r.bg:SetAllPoints()
    if opts.zebra then
        local z = (opts.zebra % 2 == 0) and T.zebraB or T.zebraA
        r.bg:SetColorTexture(z[1], z[2], z[3], z[4])
    end
    r.sel = S.Solid(r, "BACKGROUND", T.selFill); r.sel:SetAllPoints(); r.sel:Hide()
    r.hl = S.Solid(r, "BORDER", T.hoverFill); r.hl:SetAllPoints(); r.hl:SetAlpha(0)
    r.press = S.Solid(r, "BORDER", T.pressFill); r.press:SetAllPoints(); r.press:Hide()
    r.rank = S.Text(r, root.F.label, T.muted, true)
    r.rank:SetWordWrap(false); r.rank:SetJustifyH("CENTER"); r.rank:SetWidth(24); r.rank:Hide()
    r.icon = r:CreateTexture(nil, "ARTWORK"); r.icon:Hide()
    r.name = S.Text(r, reading and root.F.body or root.F.label, T.fg)
    r.name:SetJustifyH("LEFT"); r.name:SetJustifyV("TOP")
    r.detail = S.Text(r, root.F.meta, T.muted)
    r.detail:SetJustifyH("LEFT"); r.detail:SetJustifyV("TOP")
    r.value = S.Text(r, root.F.label, T.fg)
    r.value:SetJustifyH("RIGHT"); S.ClampLabel(r.value, nil, r)
    r.unit = S.Text(r, root.F.meta, T.muted)
    r.unit:SetWordWrap(false)
    r.actions = {}
    function r:AddAction(iconName, tip, onClick)
        local a = S.IconButton(self, iconName, 24, tip, onClick)
        a.icon:SetSize(16, 16)
        a:SetAlpha(0.6)
        self.actions[#self.actions + 1] = a
        return a
    end
    local function Hover(on)
        root.Tween(r, r.hov or 0, on and 1 or 0, 0.10, function(v) r.hov = v; r.hl:SetAlpha(v) end)
        for _, a in ipairs(r.actions) do a:SetAlpha(on and 1 or 0.6) end
    end
    r:SetScript("OnEnter", function(self)
        Hover(true)
        local t = type(self.tip) == "function" and self.tip(self) or self.tip
        if t then S.Tip(self, t) else local cut = root.CutLines(self); if #cut > 0 then S.Tip(self, cut) end end
    end)
    r:SetScript("OnLeave", function() Hover(false); S.HideTip() end)
    r:SetScript("OnMouseDown", function(self) self.press:Show() end)
    r:SetScript("OnMouseUp", function(self) self.press:Hide() end)
    if opts.onClick then r:SetScript("OnClick", opts.onClick) end
    r.tip = opts.tip
    function r:SetSelected(on) self.selected = on and true or nil; self.sel:SetShown(on and true or false) end
    function r:ApplyState(state) self:SetSelected(state == "selected") end
    function r:Set(o)
        o = o or {}
        local iconSize = reading and 30 or 20
        if o.hd then
            self.icon:SetSize(16, 16); root.SetHDIcon(self.icon, o.hd, o.hdColor or T.muted); self.icon:Show()
        elseif o.icon then
            self.icon:SetSize(o.iconSize or iconSize, o.iconSize or iconSize); S.Painted(self.icon, o.icon); self.icon:SetVertexColor(1, 1, 1); self.icon:Show()
        else self.icon:Hide() end
        if o.rank then
            self.rank:SetText(o.rank)
            local c = (type(o.rank) == "number" and o.rank <= 3) and T.gold or T.muted
            self.rank:SetTextColor(c[1], c[2], c[3]); self.rank:Show()
        else self.rank:Hide() end
        self.name:SetText(o.name or "")
        local nc = o.nameColor or T.fg
        self.name:SetTextColor(nc[1], nc[2], nc[3])
        self.detail:SetText(o.detail or ""); self.detail:SetShown(o.detail ~= nil and o.detail ~= "")
        self.value:SetText(o.value or ""); self.value:SetShown(o.value ~= nil)
        self.unit:SetText(o.unit or ""); self.unit:SetShown(o.unit ~= nil)
        if o.tip ~= nil then self.tip = o.tip end
    end
    function r:Fit(width, fopts)
        width = width or num(self:GetWidth()) or 0
        local x = 8
        if self.rank:IsShown() then self.rank:ClearAllPoints(); self.rank:SetPoint("TOPLEFT", x, -6); x = x + 24 + 4 end
        if self.icon:IsShown() then
            self.icon:ClearAllPoints(); self.icon:SetPoint("TOPLEFT", x, -6)
            x = x + (num(self.icon:GetWidth()) or 20) + 8
        end
        local right = 12
        for i = #self.actions, 1, -1 do
            local a = self.actions[i]
            if a:IsShown() then
                a:ClearAllPoints(); a:SetPoint("RIGHT", -right + 4, 0)
                right = right + 24
            end
        end
        if self.unit:IsShown() then
            self.unit:ClearAllPoints(); self.unit:SetPoint("TOPRIGHT", -right, -7)
            right = right + root.TextWidth(self.unit) + 4
        end
        if self.value:IsShown() then
            local vw = self.valueW or 64
            self.value:ClearAllPoints(); self.value:SetPoint("TOPRIGHT", -right, -6); self.value:SetWidth(vw)
            right = right + vw + 8
        end
        local textW = math.max(40, width - x - right)
        self.name:ClearAllPoints(); self.name:SetPoint("TOPLEFT", x, -6)
        local h
        -- wide mode (fopts.columns, rows of 640 and more): the detail gets its own column at the
        -- right of the name instead of a line under it
        local wide = fopts and fopts.columns and width >= S.LISTROW_WIDE and self.detail:IsShown()
        self.wideCols = wide and true or nil
        if wide then
            local detailX = x + math.floor((width - x - right) * 0.45)
            local nameH = root.FitText(self.name, 2, math.max(40, detailX - x - 12), self)
            self.detail:ClearAllPoints(); self.detail:SetPoint("TOPLEFT", detailX, -7)
            local detailH = root.FitText(self.detail, 2, math.max(40, width - right - detailX), self)
            self.detailX = detailX
            h = 6 + math.max(nameH, detailH + 1)
        else
            self.detailX = nil
            h = 6 + root.FitText(self.name, 2, textW, self)
            if self.detail:IsShown() then
                self.detail:ClearAllPoints(); self.detail:SetPoint("TOPLEFT", self.name, "BOTTOMLEFT", 0, -3)
                h = h + 3 + root.FitText(self.detail, 2, textW, self)
            end
        end
        h = math.max(self.minH, math.ceil(h + 8))
        self:SetHeight(h)
        return h
    end
    return r
end

-- ---------------------------------------------------------------- settings row

-- S.SettingRow(parent, o): one setting (design system 3.18).
--   o.label   13 fg, one line; wraps to 2 lines when it does not fit (the row grows by 17, no cut)
--   o.desc    11 muted, ONE line, cut with its full text in the row's tooltip
--   o.long    a longer explanation, tooltip only
--   o.control "switch" | "segmented" | "dropdown" | "slider" | "value" | a frame (placed as is)
--   o.get, o.set, o.options ({ { value, label }, ... }), o.tip (extra tooltip lines)
--   o.controlW (dropdown 160, slider 160), o.min, o.max, o.step, o.fmt (slider), o.maxW (value)
--   o.wide    takes a full grid line; the control goes under the label when wider than half the row
-- row:Fit(width) -> height: 36 without desc, 50 with one, + 17 when the label wraps (+ the control
-- and 8 when it sits under the label). Label at x 12, control's right edge at width - 12.
-- row:Update() re-reads get() into the control; row:SetLabel(t), row:SetDesc(t), row:SetLong(t).
-- row.control, row.switch (for a switch), row.label, row.desc, row.divider, row.wide.
S.SETTING = { inset = 12, gap = 12, h = 36, hDesc = 50, wrapExtra = 17, minText = 120 }
local function TweenAlpha(t, to)
    root.Tween(t, num(t:GetAlpha()) or 0, to, 0.10, function(v) t:SetAlpha(v) end)
end
function S.SettingRow(parent, o)
    o = o or {}
    local K = S.SETTING
    local row = CreateFrame("Frame", nil, parent)
    row.wlOwned = true
    row.wide = o.wide and true or false
    row.hl = S.Solid(row, "BACKGROUND", T.hoverFill); row.hl:SetAllPoints(); row.hl:SetAlpha(0)
    row.label = S.Text(row, root.F.body, T.fg)
    row.label:SetJustifyH("LEFT"); row.label:SetJustifyV("TOP")
    row.desc = S.Text(row, root.F.meta, T.muted)
    row.desc:SetJustifyH("LEFT"); row.desc:SetJustifyV("TOP")
    S.ClampLabel(row.desc, nil, row)
    row.divider = S.Rule(row)
    row.divider:SetPoint("BOTTOMLEFT", K.inset, 0); row.divider:SetPoint("BOTTOMRIGHT", -K.inset, 0)
    row.divider:Hide()
    function row:SetLabel(t) self.labelText = t or ""; self.label:SetText(self.labelText) end
    function row:SetDesc(t)
        self.descText = (type(t) == "string" and t ~= "") and t or nil
        self.desc:SetText(self.descText or "")
        self.desc.wlFull = self.descText
        self.desc:SetShown(self.descText ~= nil)
    end
    function row:SetLong(t) self.longText = (type(t) == "string" and t ~= "") and t or nil end
    row:SetLabel(o.label); row:SetDesc(o.desc); row:SetLong(o.long)

    -- the control
    local get, set = o.get or function() end, o.set or function() end
    local kind, c = o.control, nil
    if kind == "switch" then
        c = S.Switch(row, get, set)
        c:AttachRow(row)
        row.switch = c
    elseif kind == "segmented" then
        c = S.Segmented(row, o.options or {}, get, set)
    elseif kind == "dropdown" then
        c = S.Dropdown(row, o.options or {}, get, set, o.controlW or 160)
    elseif kind == "slider" then
        local sw = o.controlW or 160
        c = CreateFrame("Frame", nil, row)
        c:SetSize(sw + 12 + 48, 20)
        local s = S.Slider(c, o.min or 0, o.max or 100, o.step or 1, get, set, o.fmt, sw)
        s:SetPoint("LEFT")
        s.value:SetJustifyH("RIGHT")
        c.slider = s
        function c:Update() local v = get(); if num(v) then s:SetValue(v) end end
    elseif kind == "value" then
        c = CreateFrame("Frame", nil, row)
        c:SetSize(24, 20)
        c.text = S.Text(c, root.F.label, T.fg)
        c.text:SetJustifyH("RIGHT"); c.text:SetPoint("RIGHT")
        S.ClampLabel(c.text, nil, row)
        local maxW = o.maxW or 220
        function c:Update()
            local v = get()
            local t = (v ~= nil and not secret(v)) and tostring(v) or ""
            self.text:SetText(t); self.text.wlFull = t
            local w = math.max(24, math.min(maxW, root.TextWidth(self.text) + 2))
            self.text:SetWidth(w); self:SetWidth(w)
        end
        c:Update()
    elseif type(kind) == "table" then
        c = kind
        if c.SetParent then c:SetParent(row) end
    end
    row.control = c

    -- tooltip: label, desc (always: it may be cut), long, extra lines, then what a click does
    function row:TipLines()
        local t = { self.labelText or "" }
        if self.descText then t[#t + 1] = self.descText end
        if self.longText then t[#t + 1] = self.longText end
        if type(o.tip) == "table" then for _, l in ipairs(o.tip) do t[#t + 1] = l end
        elseif type(o.tip) == "string" then t[#t + 1] = o.tip end
        if self.switch then t[#t + 1] = get() and L("Clic : désactiver") or L("Clic : activer") end
        return t
    end
    row:EnableMouse(true)
    local function Over(f) local ok, v = pcall(f.IsMouseOver, f); return ok and v end
    local function Enter() TweenAlpha(row.hl, 1); S.Tip(row, row:TipLines()) end
    local function Leave() TweenAlpha(row.hl, 0); S.HideTip() end
    row:SetScript("OnEnter", Enter)
    row:SetScript("OnLeave", function() if not (c and c.IsMouseOver and Over(c)) then Leave() end end)
    if c and c.HookScript and (kind == "switch") then
        -- the switch is a button over the row: moving onto it keeps the row lit and its tooltip
        c:HookScript("OnEnter", Enter)
        c:HookScript("OnLeave", function() if not Over(row) then Leave() end end)
        c:HookScript("OnClick", function()
            local ok, owner = pcall(function() return GameTooltip:IsShown() and GameTooltip:GetOwner() end)
            if ok and owner == row then S.Tip(row, row:TipLines()) end
        end)
    end

    function row:Update()
        local ctl = self.control
        if ctl and ctl.Update then ctl:Update() end
    end

    function row:Fit(width)
        width = math.floor(width or num(self:GetWidth()) or 0)
        local ctl = self.control
        local cw, ch = 0, 0
        if ctl then
            if ctl.SetMaxWidth then
                -- a segmented control: a wide row may give it the whole row, a paired row keeps
                -- minText for the texts (it becomes a dropdown when its labels need more)
                ctl:SetMaxWidth(self.wide and (width - 2 * K.inset) or (width - 2 * K.inset - K.gap - K.minText))
            end
            cw, ch = num(ctl:GetWidth()) or 0, num(ctl:GetHeight()) or 0
        end
        local under = self.wide and cw > width * 0.5
        self.controlUnder = under or nil
        local textW = under and (width - 2 * K.inset) or math.max(40, width - 2 * K.inset - (cw > 0 and (cw + K.gap) or 0))
        self.textW = textW
        -- label: one line, two when it does not fit (never cut)
        self.label:SetWidth(textW)
        self.label:SetWordWrap(true)
        if self.label.SetMaxLines then self.label:SetMaxLines(2) end
        local wraps = root.TextWidth(self.label) > textW + 0.5
        self.labelWraps = wraps or nil
        local lh = wraps and 32 or 15
        local hasDesc = self.desc:IsShown()
        local top = hasDesc and 9 or 10
        self.label:ClearAllPoints(); self.label:SetPoint("TOPLEFT", K.inset, -top)
        local y = top + lh
        if hasDesc then
            self.desc:ClearAllPoints(); self.desc:SetPoint("TOPLEFT", K.inset, -(y + 3))
            self.desc:SetWidth(textW)
            y = y + 3 + 13
        end
        local h
        if under then
            y = y + 8
            ctl:ClearAllPoints(); ctl:SetPoint("TOPLEFT", self, "TOPLEFT", K.inset, -y)
            h = y + ch + 10
        else
            h = math.max(hasDesc and K.hDesc or K.h, y + (hasDesc and 10 or 11))
            if ctl then ctl:ClearAllPoints(); ctl:SetPoint("RIGHT", self, "RIGHT", -K.inset, 0) end
        end
        h = math.ceil(h)
        self:SetWidth(width)
        self:SetHeight(h)
        return h
    end
    return row
end

-- S.SettingsCard(parent): a settings card (cardFill + 1 px cardEdge) whose rows flow through
-- ns.Grid with ns.GRID.settings: 1 column under 652, 2 from 652, 3 from 984 of card width. A wide
-- row takes a whole line. A 1 px divider under each row except on the card's last line, and a
-- 1 px vertical divider between the columns of a line.
-- card:AddRow(o) -> S.SettingRow on the card; card:Add(row) adds a row built elsewhere;
-- card:Fit(width) -> height; card:Update() re-reads every control; card.grid holds the layout;
-- card:SetRowShown(row, on) leaves a row out of the layout.
function S.SettingsCard(parent, opts)
    opts = opts or {}
    local card = CreateFrame("Frame", nil, parent)
    card.wlOwned = true
    card.bg = S.Solid(card, "BACKGROUND", T.cardFill); card.bg:SetAllPoints()
    S.Border(card, T.cardEdge)
    card.rows = {}
    card.vlines = {}
    card.grid = root.Grid()
    card.gridOpts = opts.grid or root.GRID.settings
    function card:Add(row)
        if row.SetParent then row:SetParent(self) end
        self.rows[#self.rows + 1] = row
        return row
    end
    function card:AddRow(o) return self:Add(S.SettingRow(self, o)) end
    -- a row left out of the layout (row.wlHidden); call card:Fit again after
    function card:SetRowShown(row, on) row.wlHidden = not on or nil; row:SetShown(on and true or false) end
    function card:Update() for _, r in ipairs(self.rows) do if r.Update then r:Update() end end end
    function card:Fit(width)
        width = math.floor(width or num(self:GetWidth()) or 0)
        local g = self.grid
        local go = self.gridOpts
        g:Begin(self, 0, 0, width, { minW = go.minW, gap = go.gap, rowGap = 0, maxCols = go.maxCols, minPx = go.minPx, equal = true })
        for _, r in ipairs(self.rows) do
            if not r.wlHidden then
                r:Show()
                g:Add(r, function(f, w) return f:Fit(w) end, r.wide and { span = "full" } or nil)
            else
                r:Hide()
            end
        end
        local h = g:End()
        local nLines = #g.lines
        for _, c in ipairs(g.cells) do
            c.frame.divider:SetShown(c.line < nLines)
            c.frame.gridLine, c.frame.gridCol = c.line, c.col
        end
        -- vertical dividers between the cells of a line
        local used = 0
        for li, line in ipairs(g.lines) do
            if not line.full and line.n > 1 then
                for col = 2, line.n do
                    used = used + 1
                    local v = self.vlines[used]
                    if not v then
                        v = S.Solid(self, "BORDER", T.divider); v:SetWidth(1)
                        self.vlines[used] = v
                    end
                    local x = g.xs[col] - math.floor(g.gap / 2)
                    v:ClearAllPoints()
                    v:SetPoint("TOPLEFT", self, "TOPLEFT", x, -(line.y + 8))
                    v:SetHeight(math.max(1, line.h - 16))
                    v.gridLine = li
                    v:Show()
                end
            end
        end
        for i = used + 1, #self.vlines do self.vlines[i]:Hide() end
        h = math.max(1, h)
        self:SetWidth(width)
        self:SetHeight(h)
        return h
    end
    return card
end

-- ---------------------------------------------------------------- empty state

-- S.EmptyState(parent, iconName, title, text, buttonLabel, onClick, kind): one block centred
-- 24 px under the top of `parent`: HD icon 32 muted, title 14 fg (the fact), an optional sentence
-- 12 muted (why, or what will show up here), and the one action (primary unless kind says
-- otherwise). e:Set(...) with the same arguments; e:Fit() -> block height (for f:FitHeight).
function S.EmptyState(parent, iconName, title, text, buttonLabel, onClick, kind)
    local e = CreateFrame("Frame", nil, parent)
    e.wlOwned = true
    e.wrapW = 320
    e:SetWidth(e.wrapW)
    e:SetPoint("TOP", parent, "TOP", 0, -24)
    e.icon = root.Icon(e, iconName or "info", 32, "ARTWORK", T.muted)
    e.icon:SetPoint("TOP", 0, 0)
    e.title = S.Text(e, root.F.heading, T.fg)
    e.title:SetJustifyH("CENTER"); e.title:SetJustifyV("TOP")
    e.text = S.Text(e, root.F.label, T.muted)
    e.text:SetJustifyH("CENTER"); e.text:SetJustifyV("TOP")
    e.button = S.Button(e, "", 0, 28, kind or "primary", function(...) if e.onClick then e.onClick(...) end end)
    function e:Set(icon, t, s, label, click, k)
        if icon then root.SetHDIcon(self.icon, icon, T.muted) end
        self.title:SetText(t or "")
        self.text:SetText(s or ""); self.text:SetShown(s ~= nil and s ~= "")
        self.onClick = click
        if k then self.button:SetKind(k) end
        if label then self.button:SetText(label); self.button:Show() else self.button:Hide() end
        return self:Fit()
    end
    -- wrap width: 320, or less when the content area is narrower
    function e:SetWrapWidth(w) self.wrapW = math.min(320, w); self:SetWidth(self.wrapW); return self:Fit() end
    function e:Fit()
        local w = self.wrapW
        local y = 32 + 8
        self.title:ClearAllPoints(); self.title:SetPoint("TOP", 0, -y)
        y = y + root.FitText(self.title, 2, w, self)
        if self.text:IsShown() then
            y = y + 4
            self.text:ClearAllPoints(); self.text:SetPoint("TOP", 0, -y)
            y = y + root.FitText(self.text, 0, w, self)
        end
        if self.button:IsShown() then
            y = y + 12
            self.button:ClearAllPoints(); self.button:SetPoint("TOP", 0, -y)
            y = y + 28
        end
        y = math.ceil(y)
        self:SetHeight(y)
        self.blockH = y
        return y
    end
    e:Set(iconName, title, text, buttonLabel, onClick)
    return e
end

-- ---------------------------------------------------------------- banner and toast

local SEMANTIC_ICON = { info = "info", warn = "warning", ok = "check", bad = "warning" }

-- S.Banner(parent, kind, text, linkLabel, onLink, dismissible): inside a window, under the tabs.
-- kind: "info" | "warn" | "ok" | "bad". b:SetText(text, kind), b:Fit(width) -> height.
function S.Banner(parent, kind, text, linkLabel, onLink, dismissible)
    local b = CreateFrame("Frame", nil, parent)
    b.wlOwned = true
    b.base = S.Solid(b, "BACKGROUND", T.cardFill); b.base:SetAllPoints()
    b.tint = S.Solid(b, "BACKGROUND", T.info, 0.16); b.tint:SetAllPoints()
    b.edge = S.Border(b, T.info, 0.4)
    b.icon = root.Icon(b, "info", 16, "ARTWORK", T.info)
    b.icon:SetPoint("TOPLEFT", 12, -8)
    b.text = S.Text(b, root.F.label, T.fg)
    b.text:SetJustifyH("LEFT"); b.text:SetJustifyV("TOP")
    b.text:SetPoint("TOPLEFT", b.icon, "TOPRIGHT", 8, 0)
    if linkLabel then
        b.link = S.Button(b, linkLabel, 0, 24, "ghost", onLink)
        b.link:SetPoint("RIGHT", dismissible and -32 or -12, 0)
    end
    if dismissible then
        b.close = S.IconButton(b, "close", 20, { L("Masquer ce message"), L("Clic : masquer ce message") }, function()
            b:Hide(); if b.onDismiss then b.onDismiss() end
        end)
        b.close.icon:SetSize(12, 12)
        b.close:SetPoint("TOPRIGHT", -6, -6)
    end
    function b:SetText(t, k)
        k = k or self.kind or "info"
        self.kind = k
        local c = T[k] or T.info
        self.tint:SetColorTexture(c[1], c[2], c[3], 0.16)
        self.edge(c, 0.4)
        root.SetHDIcon(self.icon, SEMANTIC_ICON[k] or "info", c)
        self.text:SetText(t or "")
    end
    function b:Fit(width)
        width = width or num(self:GetWidth()) or 0
        local right = 12 + (self.link and ((num(self.link:GetWidth()) or 0) + 8) or 0) + (self.close and 20 or 0)
        local th = root.FitText(self.text, 0, math.max(40, width - 12 - 16 - 8 - right), self)
        local h = math.ceil(math.max(16, th) + 16)
        self:SetHeight(h)
        return h
    end
    b:SetText(text, kind)
    return b
end

local toastPool, toastShown = {}, {}
local function RestackToasts()
    local y = -120
    for _, t in ipairs(toastShown) do
        t:ClearAllPoints(); t:SetPoint("TOP", UIParent, "TOP", 0, y)
        y = y - (num(t:GetHeight()) or 40) - 6
    end
end
local function DropToast(t)
    for i, x in ipairs(toastShown) do if x == t then table.remove(toastShown, i) break end end
    t:Hide()
    toastPool[#toastPool + 1] = t
    RestackToasts()
end
-- S.Toast(text, sub, kind, linkLabel, onLink): top centre, 4 s (6 with a link), at most 2.
-- Never a replacement for the in-place confirmation on the button that acted.
function S.Toast(text, sub, kind, linkLabel, onLink)
    local t = table.remove(toastPool)
    if not t then
        t = CreateFrame("Frame", nil, UIParent)
        t.wlOwned = true
        t:SetFrameStrata("DIALOG")
        t:SetWidth(320)
        S.Solid(t, "BACKGROUND", T.panel, 0.96):SetAllPoints()
        S.Border(t, T.cardEdge)
        t.icon = root.Icon(t, "info", 16, "ARTWORK", T.info)
        t.icon:SetPoint("TOPLEFT", 10, -10)
        t.text = S.Text(t, root.F.label, T.fg)
        t.text:SetJustifyH("LEFT"); t.text:SetJustifyV("TOP")
        t.text:SetPoint("TOPLEFT", t.icon, "TOPRIGHT", 8, 0)
        t.sub = S.Text(t, root.F.meta, T.muted)
        t.sub:SetJustifyH("LEFT"); t.sub:SetJustifyV("TOP")
        t.sub:SetPoint("TOPLEFT", t.text, "BOTTOMLEFT", 0, -3)
        t.link = S.Button(t, "", 0, 24, "ghost")
        t.link:SetPoint("BOTTOMRIGHT", -6, 6)
    end
    while #toastShown >= 2 do DropToast(toastShown[1]) end
    kind = kind or "info"
    local c = T[kind] or T.info
    root.SetHDIcon(t.icon, SEMANTIC_ICON[kind] or "info", c)
    t.text:SetText(text or "")
    local th = root.FitText(t.text, 2, 320 - 10 - 16 - 8 - 10, t)
    local h = 10 + th
    if sub then
        t.sub:SetText(sub); t.sub:Show()
        h = h + 3 + root.FitText(t.sub, 1, 320 - 10 - 16 - 8 - 10, t)
    else t.sub:Hide() end
    if linkLabel then
        t.link:SetText(linkLabel); t.link:SetScript("OnClick", function() if onLink then onLink() end; DropToast(t) end)
        t.link:Show(); h = h + 4 + 24
    else t.link:Hide() end
    t:SetHeight(math.max(36, math.ceil(h + 10)))
    toastShown[#toastShown + 1] = t
    RestackToasts()
    t:SetAlpha(0); t:Show()
    root.Tween(t, 0, 1, 0.15, function(v) t:SetAlpha(v) end)
    local token = {}
    t.token = token
    C_Timer.After(linkLabel and 6 or 4, function()
        if t.token ~= token then return end
        root.Tween(t, 1, 0, 0.15, function(v)
            t:SetAlpha(v)
            if v <= 0 and t.token == token then DropToast(t) end
        end)
    end)
    return t
end

-- ---------------------------------------------------------------- input

-- S.Input(parent, width, opts): an edit box 28 high, panel fill, 1 px line border (accent when
-- focused). opts: search (HD search icon + clear button), placeholder ("Ex. Zul'Farrak"), label
-- (11 muted above), onChange(text), onEnter(text). box:SetError(text) shows one sentence under it.
function S.Input(parent, width, opts)
    opts = opts or {}
    local eb = CreateFrame("EditBox", nil, parent)
    eb.wlOwned = true
    eb:SetSize(width or 200, 28)
    eb:SetAutoFocus(false)
    local ok = pcall(eb.SetFont, eb, T.font or STANDARD_TEXT_FONT, root.F.label, "")
    if not ok and eb.SetFontObject then eb:SetFontObject("ChatFontNormal") end
    eb:SetTextColor(T.fg[1], T.fg[2], T.fg[3])
    S.Solid(eb, "BACKGROUND", T.panel, 1):SetAllPoints()
    eb.border = S.Border(eb, T.line)
    local left, right = 8, 8
    if opts.search then
        eb.searchIcon = root.Icon(eb, "search", 14, "ARTWORK", T.muted)
        eb.searchIcon:SetPoint("LEFT", 8, 0)
        left = 28
        eb.clear = S.IconButton(eb, "close", 20, { L("Effacer"), L("Clic : effacer la recherche") }, function()
            eb:SetText(""); eb:ClearFocus()
            if opts.onChange then opts.onChange("") end
        end)
        eb.clear.icon:SetSize(12, 12)
        eb.clear:SetPoint("RIGHT", -4, 0)
        eb.clear:Hide()
        right = 24
    end
    eb:SetTextInsets(left, right, 0, 0)
    eb.placeholder = S.Text(eb, root.F.label, T.faint)
    eb.placeholder:SetPoint("LEFT", left, 0); eb.placeholder:SetPoint("RIGHT", -right, 0)
    eb.placeholder:SetJustifyH("LEFT")
    S.ClampLabel(eb.placeholder, opts.placeholder or "", eb)
    eb.placeholder:SetText(opts.placeholder or "")
    if opts.label then
        eb.label = S.Text(parent, root.F.meta, T.muted)
        eb.label:SetPoint("BOTTOMLEFT", eb, "TOPLEFT", 0, 4)
        eb.label:SetText(opts.label)
    end
    eb.err = S.Text(parent, root.F.meta, T.bad)
    eb.err:SetPoint("TOPLEFT", eb, "BOTTOMLEFT", 0, -4)
    eb.err:SetJustifyH("LEFT")
    eb.err:Hide()
    local function Paint()
        local focused = eb.focused
        local bad = eb.err:IsShown()
        eb.border(bad and T.bad or (focused and T.accent or T.line), 1)
        if eb.searchIcon then
            local c = focused and T.fg or T.muted
            eb.searchIcon:SetVertexColor(c[1], c[2], c[3])
        end
        local t = eb:GetText() or ""
        eb.placeholder:SetShown(t == "")
        if eb.clear then eb.clear:SetShown(t ~= "") end
    end
    eb.Paint = Paint
    function eb:SetError(text)
        if text and text ~= "" then
            self.err:SetText(text); self.err:SetWidth(num(self:GetWidth()) or 200); self.err:Show()
        else self.err:Hide() end
        Paint()
    end
    function eb:SetPlaceholder(text) self.placeholder:SetText(text or ""); self.placeholder.wlFull = text end
    eb:SetScript("OnEditFocusGained", function(self) self.focused = true; Paint() end)
    eb:SetScript("OnEditFocusLost", function(self) self.focused = nil; Paint() end)
    eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    eb:SetScript("OnEnterPressed", function(self)
        if opts.onEnter then opts.onEnter(self:GetText() or "") end
        self:ClearFocus()
    end)
    eb:SetScript("OnTextChanged", function(self, user)
        Paint()
        if user and opts.onChange then opts.onChange(self:GetText() or "") end
    end)
    Paint()
    return eb
end

-- ---------------------------------------------------------------- scroll area

-- S.ScrollArea(parent): a scroll frame with a thin overlay bar (only shown when something
-- overflows: 4 px, inset 2 from the right and 4 from the top and bottom, thumb white 0.27, 0.45
-- on hover or drag, 30 px minimum). Wheel step 48 px, smoothed. Put the content in sa.child and
-- call sa:SetContentHeight(h) after each render. sa:ScrollTo(y), sa:GetScroll().
function S.ScrollArea(parent)
    local sa = CreateFrame("ScrollFrame", nil, parent)
    sa.wlOwned = true
    sa.child = CreateFrame("Frame", nil, sa)
    sa.child:SetSize(1, 1)
    sa:SetScrollChild(sa.child)
    sa.contentH, sa.target, sa.cur = 0, 0, 0
    local bar = CreateFrame("Frame", nil, sa)
    bar:SetWidth(4)
    bar:SetPoint("TOPRIGHT", sa, "TOPRIGHT", -2, -4)
    bar:SetPoint("BOTTOMRIGHT", sa, "BOTTOMRIGHT", -2, 4)
    bar:SetFrameLevel((sa:GetFrameLevel() or 1) + 5)
    S.Solid(bar, "BACKGROUND", { 1, 1, 1, 0.02 }):SetAllPoints()
    local thumb = CreateFrame("Frame", nil, bar)
    thumb:SetWidth(4)
    thumb:EnableMouse(true)
    thumb.tex = S.Solid(thumb, "ARTWORK", { 1, 1, 1, 0.27 }); thumb.tex:SetAllPoints()
    sa.bar, sa.thumb = bar, thumb
    local function ViewH() return num(sa:GetHeight()) or 0 end
    local function MaxScroll() return math.max(0, sa.contentH - ViewH()) end
    local function PaintThumb()
        local a = (thumb.hover or thumb.drag) and 0.45 or 0.27
        thumb.tex:SetColorTexture(1, 1, 1, a)
    end
    local function PlaceThumb()
        local max = MaxScroll()
        if max <= 0 then bar:Hide(); return end
        bar:Show()
        local trackH = num(bar:GetHeight()) or 0
        local th = math.max(30, trackH * ViewH() / math.max(1, sa.contentH))
        th = math.min(th, trackH)
        thumb:SetHeight(th)
        local y = (trackH - th) * (sa.cur / max)
        thumb:ClearAllPoints(); thumb:SetPoint("TOPLEFT", bar, "TOPLEFT", 0, -y)
    end
    local function Apply(y)
        sa.cur = y
        sa:SetVerticalScroll(y)
        PlaceThumb()
    end
    -- smoothed wheel: lerp toward the target (speed 12), stopped when it arrives
    local function Step(_, elapsed)
        local d = sa.target - sa.cur
        if math.abs(d) < 0.5 then Apply(sa.target); sa:SetScript("OnUpdate", nil); return end
        Apply(sa.cur + d * math.min(1, (elapsed or 0.016) * 12))
    end
    function sa:ScrollTo(y, instant)
        self.target = math.max(0, math.min(MaxScroll(), y or 0))
        if instant then Apply(self.target); self:SetScript("OnUpdate", nil)
        else self:SetScript("OnUpdate", Step) end
    end
    function sa:GetScroll() return self.cur end
    function sa:SetContentHeight(h)
        self.contentH = math.max(0, h or 0)
        self.child:SetHeight(math.max(1, self.contentH))
        self.child:SetWidth(math.max(1, num(self:GetWidth()) or 1))
        if self.target > MaxScroll() then self:ScrollTo(MaxScroll(), true) else PlaceThumb() end
    end
    sa:EnableMouseWheel(true)
    sa:SetScript("OnMouseWheel", function(self, delta) self:ScrollTo(self.target - delta * 48) end)
    sa:SetScript("OnSizeChanged", function(self, w)
        if num(w) then self.child:SetWidth(math.max(1, w)) end
        PlaceThumb()
    end)
    thumb:SetScript("OnEnter", function(self) self.hover = true; PaintThumb() end)
    thumb:SetScript("OnLeave", function(self) self.hover = nil; PaintThumb() end)
    thumb:SetScript("OnMouseDown", function(self)
        local _, cy = GetCursorPosition()
        local scale = num(bar:GetEffectiveScale()) or 1
        self.drag = { y = (num(cy) or 0) / scale, from = sa.cur }
        PaintThumb()
        self:SetScript("OnUpdate", function()
            local d = self.drag
            if not d then return end
            local _, y2 = GetCursorPosition()
            local trackH = (num(bar:GetHeight()) or 0) - (num(self:GetHeight()) or 0)
            if trackH <= 0 then return end
            local dy = d.y - (num(y2) or 0) / scale
            sa:ScrollTo(d.from + dy / trackH * MaxScroll(), true)
        end)
    end)
    thumb:SetScript("OnMouseUp", function(self) self.drag = nil; self:SetScript("OnUpdate", nil); PaintThumb() end)
    bar:Hide()
    return sa
end

-- Sizes a window to its content (f:FitHeight for S.Window, the same formula for older frames).
S.FitWindow = root.FitWindow

-- ---------------------------------------------------------------- window

-- The back button of every window but Home: an HD chevron_left (18 px) in a 28 x 28 hit area,
-- hover and press fills, tooltip "Accueil". The guild logo stays on the Home window only.
-- (S.BackLogo is its older name: the logo is no longer part of it.)
function S.BackButton(parent, onClick)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(28, 28)
    b.wlOwned = true
    b.hl = S.Solid(b, "BACKGROUND", T.hoverFill); b.hl:SetAllPoints(); b.hl:SetAlpha(0)
    b.press = S.Solid(b, "BORDER", T.pressFill); b.press:SetAllPoints(); b.press:Hide()
    b.chev = b:CreateTexture(nil, "ARTWORK"); b.chev:SetSize(18, 18); b.chev:SetPoint("CENTER", 0, 0)
    root.SetHDIcon(b.chev, "chevron_left", T.muted)
    b:SetScript("OnEnter", function(self)
        self.hl:SetAlpha(1); self.chev:SetVertexColor(T.fg[1], T.fg[2], T.fg[3])
        S.Tip(self, { L("Accueil"), L("Clic : revenir à l'accueil") })
    end)
    b:SetScript("OnLeave", function(self) self.hl:SetAlpha(0); self.press:Hide(); self.chev:SetVertexColor(T.muted[1], T.muted[2], T.muted[3]); S.HideTip() end)
    b:SetScript("OnMouseDown", function(self) self.press:Show(); self.chev:SetPoint("CENTER", 0, -1) end)
    b:SetScript("OnMouseUp", function(self) self.press:Hide(); self.chev:SetPoint("CENTER", 0, 0) end)
    b:SetScript("OnClick", function() if onClick then onClick() end end)
    return b
end
S.BackLogo = S.BackButton

function S.HomeButton(parent, onClick)
    local b = S.IconButton(parent, "home", 28, { L("Accueil"), L("Clic : revenir à l'accueil") }, onClick)
    return b
end

-- Windows that are the home page or small popups: no home button.
local NO_BACK = { WLHelperHub = true, WLHelperHome = true, WLHelperDecline = true, WLHelperWelcome = true, WLHelperOrderMsg = true }

-- Converts the window's anchor to TOPLEFT so a new height grows downward (the header stays put).
local function KeepTop(f)
    local p = f:GetPoint()
    if p == "TOPLEFT" then return end
    local l, t = num(f:GetLeft()), num(f:GetTop())
    if not (l and t) then return end
    f:ClearAllPoints()
    f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", l, t)
end

-- Lowest visible point of the window's content (not anchored to the window's bottom), for
-- windows that do not give their content height.
local function MeasureBottom(f)
    local top, bottom = num(f:GetTop()), num(f:GetBottom())
    if not (top and bottom) then return nil end
    local lowest = top
    local function consider(obj)
        if obj == f.footer or (obj.IsShown and not obj:IsShown()) then return end
        local b = num(obj:GetBottom())
        if b and b > bottom + 0.5 and b < lowest then lowest = b end
    end
    for _, c in ipairs({ f:GetChildren() }) do consider(c) end
    for _, r in ipairs({ f:GetRegions() }) do consider(r) end
    return top - lowest
end

-- ---------------------------------------------------------------- resizable windows (3.1, 3.2)

local function Clamp(v, lo, hi) if v < lo then v = lo end if v > hi then v = hi end return v end
local function CallIf(f, method, ...)
    local fn = f[method]
    if type(fn) == "function" then return pcall(fn, f, ...) end
    return false
end

-- Every window with a size tier, re-sized 0.25 s after the last screen change. A secure window
-- waits for the end of combat (its secure buttons forbid SetSize in combat).
local tiered = {}
S.tieredWindows = tiered
local screenTimer
local regen = CreateFrame("Frame")
local function InCombat() return InCombatLockdown and InCombatLockdown() and true or false end
local function ResizeOne(f)
    if f.wlSecure and InCombat() then
        f.wlSizeLater = true
        pcall(regen.RegisterEvent, regen, "PLAYER_REGEN_ENABLED")
        return
    end
    f.wlSizeLater = nil
    f:ApplySize()
end
function S.OnScreenChanged()
    for _, f in ipairs(tiered) do ResizeOne(f) end
end
regen:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_REGEN_ENABLED" then
        pcall(self.UnregisterEvent, self, "PLAYER_REGEN_ENABLED")
        for _, f in ipairs(tiered) do if f.wlSizeLater then ResizeOne(f) end end
        return
    end
    -- the new size is known on the next frame; a screen being dragged sends many events
    if screenTimer and screenTimer.Cancel then screenTimer:Cancel() end
    screenTimer = nil
    if C_Timer and C_Timer.NewTimer then
        screenTimer = C_Timer.NewTimer(0.25, function() screenTimer = nil; S.OnScreenChanged() end)
    elseif C_Timer and C_Timer.After then C_Timer.After(0, S.OnScreenChanged) else S.OnScreenChanged() end
end)
pcall(regen.RegisterEvent, regen, "DISPLAY_SIZE_CHANGED")
pcall(regen.RegisterEvent, regen, "UI_SCALE_CHANGED")
S.sizeEvents = regen

-- S.MakeResizable(f, tier, db, key, opts): gives a window the size rule of its tier ("workspace":
-- both axes, size saved; "panel": width only, width saved, height fits the content), the resize
-- grip at the bottom right, its bounds, and the re-layout hook. S.Window calls it for opts.size;
-- a window with its own frame (the Hub) calls it directly. opts.secure: no resizing in combat.
--   f:SizeRule() -> defW, defH, minW, minH, maxW, maxH for the current screen
--   f:ApplySize() -> w, h: rule + saved size (clamped), bounds, SetSize
--   f:ResetSize(): forgets the saved size (the grip's double-click)
--   f.OnResize = function(self, w, h) end: the owner's layout, at most once per frame while the
--   size changes and only while the window is shown (a hidden one lays out on its next show)
-- The size is saved as db[key .. "Size"] = { w, h } (panel: { w }).
function S.MakeResizable(f, tier, db, key, opts)
    opts = opts or {}
    f.wlTier = tier
    f.wlSecure = opts.secure and true or false
    f.wlSizeDb, f.wlSizeKey = db, key and (key .. "Size") or nil
    function f:SizeRule()
        local defW, defH, minW, minH, maxW, maxH = root.WinSize(self.wlTier)
        if self.wlTier ~= "workspace" then
            minH = self.minH or 200
            defH = Clamp(num(self:GetHeight()) or minH, minH, math.max(minH, maxH))
        end
        return defW, defH, minW, minH, maxW, maxH
    end
    function f:SavedSize()
        local d, k = self.wlSizeDb, self.wlSizeKey
        local s = d and k and d[k]
        if type(s) ~= "table" then return nil end
        return num(s[1]), num(s[2])
    end
    function f:ApplySize()
        local defW, defH, minW, minH, maxW, maxH = self:SizeRule()
        if not defW then return nil end
        local sw, sh = self:SavedSize()
        local w = sw and Clamp(math.floor(sw), minW, maxW) or defW
        local h = defH
        if self.wlTier == "workspace" and sh then h = Clamp(math.floor(sh), minH, maxH) end
        -- bounds while dragging (a panel keeps its height: only its width is dragged)
        local bMinH, bMaxH = minH, maxH
        if self.wlTier ~= "workspace" then bMinH, bMaxH = 1, math.max(maxH, h) end
        if self.SetResizeBounds then
            CallIf(self, "SetResizeBounds", minW, bMinH, maxW, bMaxH)
        else
            CallIf(self, "SetMinResize", minW, bMinH)
            CallIf(self, "SetMaxResize", maxW, bMaxH)
        end
        self.wlBounds = { minW, minH, maxW, maxH }
        if self.wlTier == "workspace" then self:SetSize(w, h) else self:SetWidth(w); self:SetHeight(h) end
        return w, h
    end
    function f:ResetSize()
        local d, k = self.wlSizeDb, self.wlSizeKey
        if d and k then d[k] = nil end
        return self:ApplySize()
    end
    function f:SaveSize()
        local d, k = self.wlSizeDb, self.wlSizeKey
        local w, h = num(self:GetWidth()), num(self:GetHeight())
        if not (d and k and w) then return end
        if self.wlTier == "workspace" and h then d[k] = { math.floor(w + 0.5), math.floor(h + 0.5) }
        else d[k] = { math.floor(w + 0.5) } end
    end
    CallIf(f, "SetResizable", true)

    -- the grip: the guide's look (chevron 12 turned to the corner, faint, fg on hover)
    local grip = CreateFrame("Button", nil, f)
    grip:SetSize(16, 16); grip:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
    grip:SetFrameLevel((num(f:GetFrameLevel()) or 1) + 10)
    grip.icon = root.Icon(grip, "chevron_right", 12, "OVERLAY", T.faint); grip.icon:SetPoint("CENTER", 1, -1)
    if grip.icon.SetRotation then pcall(grip.icon.SetRotation, grip.icon, -math.pi / 4) end
    local function Blocked() return f.wlSecure and InCombat() end
    grip:SetScript("OnEnter", function(self)
        self.icon:SetVertexColor(T.fg[1], T.fg[2], T.fg[3])
        if Blocked() then S.Tip(self, { L("Redimensionner"), L("Indisponible en combat") })
        else S.Tip(self, { L("Redimensionner"), L("Glisser : changer la taille. Double-clic : taille par défaut.") }) end
    end)
    grip:SetScript("OnLeave", function(self) self.icon:SetVertexColor(T.faint[1], T.faint[2], T.faint[3]); S.HideTip() end)
    grip:SetScript("OnMouseDown", function(self, button)
        if button == "RightButton" or Blocked() then return end
        f.wlSizing = true
        f:StartSizing(f.wlTier == "workspace" and "BOTTOMRIGHT" or "RIGHT")
    end)
    grip:SetScript("OnMouseUp", function()
        if not f.wlSizing then return end
        f.wlSizing = nil
        f:StopMovingOrSizing()
        KeepTop(f)
        f:SaveSize()
        local d, pk = f.wlDb, f.wlPosKey
        if d and pk then local p, _, rp, x, y = f:GetPoint(); if p then d[pk] = { p, rp, x, y } end end
    end)
    grip:SetScript("OnDoubleClick", function()
        if Blocked() then return end
        f:ResetSize()
    end)
    f.grip = grip

    -- re-layout: once per frame while the size changes, only while shown
    local function Relayout()
        f.wlResizePending = nil
        if not f:IsShown() then return end
        local w, h = num(f:GetWidth()), num(f:GetHeight())
        if w and f.OnResize then f:OnResize(w, h) end
    end
    local function SizeChanged()
        if f.wlResizePending then return end
        f.wlResizePending = true
        if C_Timer and C_Timer.After then C_Timer.After(0, Relayout) else Relayout() end
    end
    if f.HookScript and f.GetScript and f:GetScript("OnSizeChanged") then f:HookScript("OnSizeChanged", SizeChanged)
    else f:SetScript("OnSizeChanged", SizeChanged) end

    tinsert(tiered, f)
    if f.wlSecure and InCombat() then f.wlSizeLater = true; pcall(regen.RegisterEvent, regen, "PLAYER_REGEN_ENABLED")
    else f:ApplySize() end
    return f
end

-- S.Window(name, width, height, title, subtitle, db, posKey, opts)
-- opts.size = "workspace" | "panel" (nil: the fixed width/height given, the hud tier): the size
-- rule of 3.1 through S.MakeResizable (grip, bounds, saved size, f.OnResize); width/height are
-- then only the starting values. opts.secure: the grip and the screen re-size wait out combat.
-- A workspace window keeps its size: f:FitHeight only updates f.overflow.
-- opts: header (44 for the design-system header; 38 by default for windows not migrated yet),
-- footer (true: a 24 px footer with f.footer.note and f.footer.status), minH, strata, noHome.
-- f:FitHeight(contentH) sizes the window to its content (measured when contentH is nil);
-- f:FitHeightLater(contentH) does it on the next frame (after wrapped text got its width).
-- f:AddHeaderButton(btn) puts an icon in the right cluster; f:SetFooter(note, status).
-- f:ContentTop() is the y of the content area (under the header and the tabs).
function S.Window(name, width, height, title, subtitle, db, posKey, opts)
    opts = opts or {}
    local f = CreateFrame("Frame", name, UIParent)
    f:SetSize(width, height)
    f:SetFrameStrata(opts.strata or "MEDIUM")
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f.wlDb, f.wlPosKey = db, posKey
    local pos = db and posKey and db[posKey]
    if pos then f:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4]) else f:SetPoint("CENTER") end
    if name then tinsert(UISpecialFrames, name) end
    root.RegisterWindow(f)
    S.Solid(f, "BACKGROUND", T.bg):SetAllPoints()
    S.Border(f, T.cardEdge)

    local HH = opts.header or S.LEGACY_HEADER_H
    f.headerH = HH
    f.minH = opts.minH or 200
    local h = CreateFrame("Frame", nil, f)
    h:SetPoint("TOPLEFT", 0, 0); h:SetPoint("TOPRIGHT", 0, 0); h:SetHeight(HH)
    local rule = S.Solid(f, "BORDER", T.line)
    rule:SetPoint("TOPLEFT", 0, -HH); rule:SetPoint("TOPRIGHT", 0, -HH)
    root.PixelLine(f, rule, true)
    f.headerRule = rule
    h:EnableMouse(true)
    h:RegisterForDrag("LeftButton")
    h:SetScript("OnMouseDown", function() f:Raise() end)
    h:SetScript("OnDragStart", function() f:StartMoving() end)
    h:SetScript("OnDragStop", function()
        f:StopMovingOrSizing()
        KeepTop(f)
        if db and posKey then local p, _, rp, x, y = f:GetPoint(); db[posKey] = { p, rp, x, y } end
    end)
    local function GoHome()
        f:Hide()
        local WP = ns.WP
        if WP and WP.OpenHome then WP.OpenHome() end
    end
    local midY = -math.floor((HH - 28) / 2)
    -- the left of the header: on the WL Helper window (the Hub) the guild logo (the app's mark), on
    -- every other window one HD "<" back to the Hub's Home; the Welcome window (the first contact)
    -- keeps the logo too (both pass opts.logo); small popups have neither. The title follows it.
    local titleX = 16
    if opts.logo then
        local logo = h:CreateTexture(nil, "ARTWORK")
        logo:SetSize(28, 28); logo:SetTexture(S.LOGO)
        logo:SetPoint("TOPLEFT", 8, midY)
        f.logo = logo
        titleX = 8 + 28 + 8
    elseif not (NO_BACK[name or ""] or opts.noHome) then
        f.back = S.BackButton(h, GoHome)
        f.back:SetPoint("TOPLEFT", 6, midY)
        titleX = 6 + 28 + 6
    end
    f.title = S.Text(h, root.F.title, T.fg, true)
    f.title:SetJustifyH("LEFT")
    S.ClampLabel(f.title, nil, h)
    f.subtitle = S.Text(h, root.F.meta, T.muted)
    f.subtitle:SetJustifyH("LEFT")
    S.ClampLabel(f.subtitle, nil, h)
    local close = S.CloseButton(h, 28, function() f:Hide() end)
    close:SetPoint("TOPRIGHT", -8, midY)
    f.header, f.close = h, close
    f.rightIcons = { close }
    local function TitleRight()
        -- the right cluster plus one free slot for icons that older windows place themselves
        local n = #f.rightIcons + (f.legacySlot ~= false and 1 or 0)
        return -(8 + n * 28 + (n - 1) * 4 + 8)
    end
    local function LayoutTitle()
        local sub = f.subtitle:GetText()
        local hasSub = type(sub) == "string" and sub ~= ""
        f.title:ClearAllPoints(); f.subtitle:ClearAllPoints()
        local x = titleX
        if hasSub then
            local top = math.max(3, math.floor((HH - 32) / 2))
            f.title:SetPoint("TOPLEFT", h, "TOPLEFT", x, -top)
            f.title:SetPoint("TOPRIGHT", h, "TOPRIGHT", TitleRight(), -top)
            f.subtitle:SetPoint("TOPLEFT", f.title, "BOTTOMLEFT", 0, -2)
            f.subtitle:SetPoint("TOPRIGHT", f.title, "BOTTOMRIGHT", 0, -2)
            f.subtitle:Show()
        else
            f.title:SetPoint("LEFT", h, "LEFT", x, 0)
            f.title:SetPoint("RIGHT", h, "RIGHT", TitleRight(), 0)
            f.subtitle:Hide()
        end
    end
    local tset, sset = f.title.SetText, f.subtitle.SetText
    f.title.SetText = function(self, t) tset(self, t); LayoutTitle() end
    f.subtitle.SetText = function(self, t) sset(self, t); LayoutTitle() end
    f.title:SetText(title or "")
    f.subtitle:SetText(subtitle or "")
    function f:AddHeaderButton(btn)
        local last = self.rightIcons[#self.rightIcons]
        btn:ClearAllPoints()
        btn:SetPoint("RIGHT", last, "LEFT", -4, 0)
        table.insert(self.rightIcons, btn)
        self.legacySlot = false
        LayoutTitle()
        return btn
    end

    if opts.footer then
        local ft = CreateFrame("Frame", nil, f)
        ft:SetHeight(S.FOOTER_H)
        ft:SetPoint("BOTTOMLEFT", 0, 0); ft:SetPoint("BOTTOMRIGHT", 0, 0)
        ft.note = S.Text(ft, root.F.foot, T.muted)
        ft.note:SetPoint("LEFT", 16, 0); ft.note:SetJustifyH("LEFT")
        ft.status = S.Text(ft, root.F.foot, T.muted)
        ft.status:SetPoint("RIGHT", -16, 0); ft.status:SetJustifyH("RIGHT")
        ft.status:SetWordWrap(false)
        ft.note:SetPoint("RIGHT", ft.status, "LEFT", -12, 0)
        S.ClampLabel(ft.note, nil, ft)
        f.footer = ft
    end
    function f:SetFooter(note, status)
        if not self.footer then return end
        self.footer.note:SetText(note or "")
        self.footer.status:SetText(status or "")
        self.footer:SetShown((note and note ~= "") or (status and status ~= "") or self.footer.button ~= nil)
    end

    function f:ContentTop()
        local y = self.headerH + 1
        if self.wlTabs and self.wlTabs:IsShown() then y = y + S.TABS_H + 1 end
        return y
    end
    function f:FitHeight(contentH)
        if contentH == nil and self.Measure then contentH = self:Measure() end
        local footH = (self.footer and self.footer:IsShown()) and S.FOOTER_H or 0
        if self.wlTier == "workspace" then
            -- a workspace window keeps its size (rule 0.4): its pages scroll inside
            local cur = num(self:GetHeight())
            if contentH and cur then self.overflow = (self:ContentTop() + 24 + contentH + footH > cur) else self.overflow = nil end
            return cur
        end
        local hgt
        if contentH then
            hgt = self:ContentTop() + 12 + contentH + 12 + footH
        else
            local used = MeasureBottom(self)
            if not used then return nil end
            hgt = used + 12 + footH
        end
        local maxH = math.floor((num(UIParent:GetHeight()) or 768) * 0.80)
        local minH = self.minH or 200
        hgt = math.min(math.max(math.ceil(hgt), minH), math.max(maxH, minH))
        KeepTop(self)
        self:SetHeight(hgt)
        self.overflow = contentH and (self:ContentTop() + 24 + contentH + footH > hgt) or nil
        return hgt
    end
    function f:FitHeightLater(contentH)
        local fn = function() if self:IsShown() then self:FitHeight(contentH) end end
        if C_Timer and C_Timer.After then C_Timer.After(0, fn) else fn() end
    end

    if opts.size == "workspace" or opts.size == "panel" then
        S.MakeResizable(f, opts.size, db, posKey, { secure = opts.secure })
    end

    -- Two windows open at once must not mix: the one clicked or opened last comes on top, whole.
    f:SetToplevel(true)
    local raiser = CreateFrame("Frame", nil, f)
    raiser:SetScript("OnShow", function() f:Raise() end)
    f:Hide()
    return f
end

-- Strings other modules add to the English table (they write their own French keys).
function ns.AddEnglish(t)
    if ns.EN then for k, v in pairs(t) do ns.EN[k] = v end end
end

ns.AddEnglish({
    ["Redimensionner"] = "Resize",
    ["Clic : activer"] = "Click: turn on",
    ["Clic : désactiver"] = "Click: turn off",
    ["Indisponible en combat"] = "Not available in combat",
    ["Glisser : changer la taille. Double-clic : taille par défaut."] = "Drag: change the size. Double-click: default size.",
})
