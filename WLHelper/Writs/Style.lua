-- Writs/Style.lua: WL Helper's look, shared by the Comptoir, the GPS arrow, the options and the bag
-- cleaner. War Legend colours (red #CE1918 for actions), fixed colour meanings, and the widgets
-- every screen is built from. Text goes through the guide's theme (Theme.lua) so fonts follow it.
local ADDON, root = ...
root.Writs = root.Writs or {}
local ns = root.Writs

local S = {}
ns.S = S

-- ---------------------------------------------------------------- tokens
-- One meaning per colour: brand = action; ready = done / ready; warn = something to do;
-- info = an alternative (teleport, an item you craft); danger = blocked.
S.C = {
    bg      = { 0.051, 0.055, 0.063, 0.97 },
    header  = { 0.031, 0.035, 0.043, 0.98 },
    card    = { 0.082, 0.090, 0.102, 1 },
    border  = { 0.141, 0.153, 0.173, 1 },
    divider = { 0.110, 0.122, 0.137, 1 },
    hover   = { 0.102, 0.114, 0.129, 1 },
    text    = { 0.925, 0.925, 0.937 },
    dim     = { 0.627, 0.651, 0.682 },
    muted   = { 0.553, 0.576, 0.608 },
    brand   = { 0.808, 0.098, 0.094 },
    brandHi = { 0.886, 0.188, 0.165 },
    brandBg = { 0.165, 0.071, 0.075 },
    brandSoft = { 1, 0.561, 0.525 },
    ready   = { 0.435, 0.863, 0.549 },
    warn    = { 0.949, 0.757, 0.306 },
    info    = { 0.486, 0.769, 1 },
    danger  = { 0.886, 0.322, 0.290 },
}
S.LOGO = "Interface\\AddOns\\" .. ADDON .. "\\Media\\Logo64"

function S.Hex(c)
    local function b(v) return math.floor(math.max(0, math.min(1, v)) * 255 + 0.5) end
    return string.format("|cff%02x%02x%02x", b(c[1]), b(c[2]), b(c[3]))
end

-- ---------------------------------------------------------------- primitives

function S.Text(parent, size, color, bold)
    local fs = root.Text and root.Text(parent, size, color or S.C.text, bold) or parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fs:SetJustifyV("MIDDLE")
    fs:SetWordWrap(false)
    return fs
end

function S.Solid(parent, layer, c, a)
    local t = parent:CreateTexture(nil, layer or "BACKGROUND")
    t:SetColorTexture(c[1], c[2], c[3], a or c[4] or 1)
    return t
end

-- One-pixel border; returns a setter for its colour.
function S.Border(frame, c, a)
    local edges = {}
    for i, p in ipairs({ { "TOPLEFT", "TOPRIGHT" }, { "BOTTOMLEFT", "BOTTOMRIGHT" }, { "TOPLEFT", "BOTTOMLEFT" }, { "TOPRIGHT", "BOTTOMRIGHT" } }) do
        local t = S.Solid(frame, "BORDER", c, a)
        t:SetPoint(p[1]); t:SetPoint(p[2])
        if i <= 2 then t:SetHeight(1) else t:SetWidth(1) end
        edges[i] = t
    end
    return function(c2, a2) for _, t in ipairs(edges) do t:SetColorTexture(c2[1], c2[2], c2[3], a2 or 1) end end
end

function S.Tip(owner, lines)
    if root.ShowTip then root.ShowTip(owner, lines) end
end
function S.HideTip() GameTooltip:Hide() end

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
    return S.C.text
end

-- A zone level range coloured like the game colours quests against your level.
function S.LevelColor(level)
    if GetQuestDifficultyColor and level then
        local ok, c = pcall(GetQuestDifficultyColor, level)
        if ok and c then return { c.r, c.g, c.b } end
    end
    return S.C.dim
end

-- ---------------------------------------------------------------- icons
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
    if coords then tex:SetTexCoord(coords[1], coords[2], coords[3], coords[4]) else tex:SetTexCoord(0, 1, 0, 1) end
    return false
end

-- Whether an atlas exists (for |A...|a text markup, which shows nothing when it does not).
function S.HasAtlas(name)
    if not (C_Texture and C_Texture.GetAtlasInfo) then return false end
    local ok, info = pcall(C_Texture.GetAtlasInfo, name)
    return ok and info ~= nil
end

local CIRCLES = "Interface\\TargetingFrame\\UI-Classes-Circles"
-- The class's icon: the modern square one, else the old circle sheet. False when neither is known.
function S.ClassIcon(tex, class)
    if not class then return false end
    if TryAtlas(tex, "classicon-" .. class:lower()) then return true end
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
    return string.format("|T%s:%d:%d:0:0:64:64:%d:%d:%d:%d|t", ROLE_SHEET, size, size, px[1], px[2], px[3], px[4])
end

-- Drawn glyphs: a close cross, chevrons and a tick made of two crisp lines (no font glyph, no
-- blown-up 16 px texture). g:SetKind("x" | "right" | "left" | "down" | "up" | "check"), g:SetColor(c, a).
local GLYPH = {
    x     = function(r) return { { -r, r, r, -r }, { -r, -r, r, r } } end,
    right = function(r) return { { -r * 0.45, r, r * 0.45, 0 }, { r * 0.45, 0, -r * 0.45, -r } } end,
    left  = function(r) return { { r * 0.45, r, -r * 0.45, 0 }, { -r * 0.45, 0, r * 0.45, -r } } end,
    down  = function(r) return { { -r, r * 0.45, 0, -r * 0.45 }, { 0, -r * 0.45, r, r * 0.45 } } end,
    up    = function(r) return { { -r, -r * 0.45, 0, r * 0.45 }, { 0, r * 0.45, r, -r * 0.45 } } end,
    check = function(r) return { { -r, 0, -r * 0.3, -r * 0.7 }, { -r * 0.3, -r * 0.7, r, r * 0.75 } } end,
}
-- when this client cannot draw lines: the old textures, same meaning
local GLYPH_FALLBACK = {
    x = "Interface\\Buttons\\UI-StopButton", check = "Interface\\Buttons\\UI-CheckBox-Check",
    right = "Interface\\Buttons\\UI-PlusButton-Up", left = "Interface\\Buttons\\UI-PlusButton-Up",
    down = "Interface\\Buttons\\UI-MinusButton-Up", up = "Interface\\Buttons\\UI-MinusButton-Up",
}

function S.Glyph(parent, kind, size, color, thickness)
    local g = CreateFrame("Frame", nil, parent)
    size = size or 12
    g:SetSize(size, size)
    g.th = thickness or (size >= 12 and 2 or 1.5)
    local l1 = g.CreateLine and g:CreateLine(nil, "ARTWORK")
    if l1 and l1.SetStartPoint and l1.SetEndPoint and l1.SetThickness then
        g.lines = { l1, g:CreateLine(nil, "ARTWORK") }
        for _, l in ipairs(g.lines) do l:SetThickness(g.th) end
    else
        if l1 and l1.Hide then l1:Hide() end
        g.tex = g:CreateTexture(nil, "ARTWORK")
        g.tex:SetAllPoints()
    end
    function g:SetColor(c, a)
        self.c, self.a = c, a
        if self.lines then
            for _, l in ipairs(self.lines) do l:SetColorTexture(c[1], c[2], c[3], a or 1) end
        else
            self.tex:SetVertexColor(c[1], c[2], c[3], a or 1)
        end
    end
    function g:SetKind(k)
        if not GLYPH[k] then k = "x" end
        if self.kind == k then return end
        self.kind = k
        if self.lines then
            local r = size / 2 - self.th / 2
            local e = self.th * 0.35   -- each stroke a little longer: no notch where two meet
            for i, s in ipairs(GLYPH[k](r)) do
                local dx, dy = s[3] - s[1], s[4] - s[2]
                local len = math.sqrt(dx * dx + dy * dy)
                local ux, uy = len > 0 and dx / len or 0, len > 0 and dy / len or 0
                local l = self.lines[i]
                l:SetStartPoint("CENTER", self, s[1] - ux * e, s[2] - uy * e)
                l:SetEndPoint("CENTER", self, s[3] + ux * e, s[4] + uy * e)
            end
        else
            self.tex:SetTexture(GLYPH_FALLBACK[k])
            self.tex:SetDesaturated(k == "check")
        end
    end
    g:SetKind(kind or "x")
    g:SetColor(color or S.C.dim)
    return g
end

-- A close button: a drawn cross, dim, white with a soft square under the mouse.
function S.CloseButton(parent, size, onClick, tip, glyphSize)
    local C = S.C
    size = size or 24
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(size, size)
    local inset = size >= 28 and 4 or 1
    local hl = S.Solid(b, "BACKGROUND", { 1, 1, 1 }, 0)
    hl:SetPoint("TOPLEFT", inset, -inset); hl:SetPoint("BOTTOMRIGHT", -inset, inset)
    b.glyph = S.Glyph(b, "x", glyphSize or math.max(8, math.floor(size * 0.36 + 0.5)), C.dim)
    b.glyph:SetPoint("CENTER")
    b:SetScript("OnEnter", function(self)
        hl:SetColorTexture(1, 1, 1, 0.08); self.glyph:SetColor({ 1, 1, 1 })
        if tip then S.Tip(self, tip) end
    end)
    b:SetScript("OnLeave", function(self)
        hl:SetColorTexture(1, 1, 1, 0); self.glyph:SetColor(C.dim)
        if tip then S.HideTip() end
    end)
    if onClick then b:SetScript("OnClick", onClick) end
    return b
end

-- ---------------------------------------------------------------- widgets

-- Buttons: "primary" (filled red, one per screen), "secondary" (outlined), "ghost" (text only),
-- "warn" (amber outline), "info" (blue, for an alternative).
function S.Button(parent, label, width, height, kind, onClick, tip)
    kind = kind or "secondary"
    local C = S.C
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(width, height or 30)
    local fill = S.Solid(b, "BACKGROUND", C.brand, 0)
    fill:SetAllPoints()
    local border = S.Border(b, C.border)
    b.label = S.Text(b, 13, C.text, kind == "primary")
    b.label:SetPoint("CENTER")
    b.label:SetJustifyH("CENTER")
    b.label:SetText(label or "")
    local function paint(hover)
        local enabled = b:IsEnabled()
        if kind == "primary" then
            local c = enabled and (hover and C.brandHi or C.brand) or C.divider
            fill:SetColorTexture(c[1], c[2], c[3], 1); border(c)
            b.label:SetTextColor(1, 1, 1, enabled and 1 or 0.4)
        elseif kind == "warn" then
            fill:SetColorTexture(C.warn[1], C.warn[2], C.warn[3], hover and 0.12 or 0)
            border(C.warn, enabled and 0.45 or 0.2); b.label:SetTextColor(C.warn[1], C.warn[2], C.warn[3], enabled and 1 or 0.4)
        elseif kind == "info" then
            fill:SetColorTexture(0.086, 0.196, 0.290, 1)
            border({ 0.169, 0.353, 0.502 }); b.label:SetTextColor(0.85, 0.93, 1, enabled and 1 or 0.4)
        elseif kind == "ghost" then
            fill:SetColorTexture(1, 1, 1, hover and 0.05 or 0); border(C.border, 0)
            b.label:SetTextColor(C.dim[1], C.dim[2], C.dim[3], enabled and 1 or 0.4)
        else
            fill:SetColorTexture(1, 1, 1, hover and 0.05 or 0)
            border(hover and C.dim or { 0.227, 0.243, 0.267 }); b.label:SetTextColor(C.text[1], C.text[2], C.text[3], enabled and 1 or 0.4)
        end
    end
    b.Paint = paint
    b:SetScript("OnEnter", function(self)
        paint(true)
        if tip then S.Tip(self, type(tip) == "function" and tip() or tip) end
    end)
    b:SetScript("OnLeave", function() paint(false); if tip then S.HideTip() end end)
    b:SetScript("OnEnable", function() paint(false) end)
    b:SetScript("OnDisable", function() paint(false) end)
    if onClick then b:SetScript("OnClick", onClick) end
    paint(false)
    return b
end

-- Switch bound to get() / set(v).
function S.Switch(parent, get, set, label)
    local C = S.C
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(38, 22)
    local track = S.Solid(b, "BACKGROUND", C.border)
    track:SetAllPoints()
    local knob = S.Solid(b, "ARTWORK", C.dim)
    knob:SetSize(18, 18)
    function b:Update()
        local on = get() and true or false
        track:SetColorTexture(on and C.brand[1] or 0.18, on and C.brand[2] or 0.196, on and C.brand[3] or 0.22, 1)
        knob:SetColorTexture(on and 1 or C.dim[1], on and 1 or C.dim[2], on and 1 or C.dim[3], 1)
        knob:ClearAllPoints()
        knob:SetPoint(on and "RIGHT" or "LEFT", on and -2 or 2, 0)
    end
    b:SetScript("OnClick", function(self) set(not get()); self:Update() end)
    if label then
        b:SetScript("OnEnter", function(self) S.Tip(self, { label }) end)
        b:SetScript("OnLeave", S.HideTip)
    end
    b:Update()
    return b
end

-- Segmented choice: options = { { value, label, disabled }, ... }.
function S.Segmented(parent, options, get, set, height)
    local C = S.C
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetHeight(height or 30)
    S.Border(holder, { 0.18, 0.196, 0.22 })
    local buttons, x = {}, 0
    for i, o in ipairs(options) do
        local b = CreateFrame("Button", nil, holder)
        b:SetHeight(height or 30)
        b.fill = S.Solid(b, "BACKGROUND", C.brandBg, 0)
        b.fill:SetAllPoints()
        b.label = S.Text(b, 13, C.text, false)
        b.label:SetPoint("CENTER")
        b.label:SetText(o[2])
        local w = b.label:GetStringWidth() + 28
        b:SetWidth(w)
        b:SetPoint("LEFT", x, 0)
        x = x + w
        if i < #options then
            local sep = S.Solid(holder, "BORDER", { 0.18, 0.196, 0.22 })
            sep:SetPoint("TOPLEFT", x, 0); sep:SetPoint("BOTTOMLEFT", x, 0); sep:SetWidth(1)
        end
        b.value, b.disabled = o[1], o[3]
        b:SetScript("OnClick", function(self)
            if self.disabled then return end
            set(self.value); holder:Update()
        end)
        buttons[i] = b
    end
    holder:SetWidth(x)
    function holder:Update()
        local cur = get()
        for _, b in ipairs(buttons) do
            local on = b.value == cur
            b.fill:SetColorTexture(C.brandBg[1], C.brandBg[2], C.brandBg[3], on and 1 or 0)
            if b.disabled then b.label:SetTextColor(0.37, 0.4, 0.43)
            elseif on then b.label:SetTextColor(C.brandSoft[1], C.brandSoft[2], C.brandSoft[3])
            else b.label:SetTextColor(C.text[1], C.text[2], C.text[3]) end
        end
    end
    function holder:SetDisabled(value, disabled)
        for _, b in ipairs(buttons) do if b.value == value then b.disabled = disabled end end
        holder:Update()
    end
    holder:Update()
    return holder
end

-- Slider (min, max, step) bound to get() / set(v); fmt(v) gives the value text.
function S.Slider(parent, min, max, step, get, set, fmt, width)
    local C = S.C
    local s = CreateFrame("Slider", nil, parent)
    s:SetSize(width or 180, 16)
    s:SetOrientation("HORIZONTAL")
    s:SetMinMaxValues(min, max)
    s:SetValueStep(step)
    if s.SetObeyStepOnDrag then s:SetObeyStepOnDrag(true) end
    local track = S.Solid(s, "BACKGROUND", C.border)
    track:SetPoint("LEFT"); track:SetPoint("RIGHT"); track:SetHeight(4)
    local thumb = s:CreateTexture(nil, "ARTWORK")
    thumb:SetColorTexture(C.brand[1], C.brand[2], C.brand[3], 1)
    thumb:SetSize(10, 16)
    s:SetThumbTexture(thumb)
    s.value = S.Text(parent, 13, C.dim)
    s.value:SetPoint("LEFT", s, "RIGHT", 10, 0)
    s.value:SetWidth(48)
    s:SetScript("OnValueChanged", function(self, v)
        v = math.floor(v / step + 0.5) * step
        set(v)
        self.value:SetText(fmt and fmt(v) or tostring(v))
    end)
    s:SetValue(get())
    s.value:SetText(fmt and fmt(get()) or tostring(get()))
    return s
end

-- Tabs: list = { { key, label }, ... }; badge(key) may return a number to show.
function S.Tabs(parent, list, get, set, badge)
    local C = S.C
    local bar = CreateFrame("Frame", nil, parent)
    bar:SetHeight(36)
    local line = S.Solid(bar, "BORDER", C.divider)
    line:SetPoint("BOTTOMLEFT"); line:SetPoint("BOTTOMRIGHT"); line:SetHeight(1)
    local tabs, x = {}, 10
    for i, t in ipairs(list) do
        local b = CreateFrame("Button", nil, bar)
        b:SetHeight(36)
        b.label = S.Text(b, 14, C.dim)
        b.label:SetPoint("LEFT", 10, 0)
        b.label:SetText(t[2])
        b.badge = CreateFrame("Frame", nil, b)
        b.badge:SetSize(18, 16)
        b.badge:SetPoint("LEFT", b.label, "RIGHT", 6, 0)
        S.Solid(b.badge, "BACKGROUND", C.brandBg):SetAllPoints()
        b.badge.text = S.Text(b.badge, 11, C.brandSoft, true)
        b.badge.text:SetPoint("CENTER")
        b.under = S.Solid(b, "ARTWORK", C.brand)
        b.under:SetPoint("BOTTOMLEFT"); b.under:SetPoint("BOTTOMRIGHT"); b.under:SetHeight(2)
        b.key = t[1]
        b:SetScript("OnClick", function(self) set(self.key) end)
        tabs[i] = b
    end
    function bar:Update()
        local cur, x = get(), 10
        for _, b in ipairs(tabs) do
            local on = b.key == cur
            b.label:SetTextColor(on and C.text[1] or C.dim[1], on and C.text[2] or C.dim[2], on and C.text[3] or C.dim[3])
            b.under:SetShown(on)
            local n = badge and badge(b.key)
            if n and n > 0 then b.badge.text:SetText(n); b.badge:SetWidth(b.badge.text:GetStringWidth() + 10); b.badge:Show()
            else b.badge:Hide() end
            local w = b.label:GetStringWidth() + 20 + (b.badge:IsShown() and b.badge:GetWidth() + 6 or 0)
            b:SetWidth(w)
            b:ClearAllPoints(); b:SetPoint("LEFT", x, 0)
            x = x + w
        end
    end
    bar:Update()
    return bar
end

-- "‹ Accueil": a drawn arrow (no special character: every font shows it) and the word, framed.
-- Used by every window's header, the dungeon guide and the picker.
function S.HomeButton(parent, onClick)
    -- the hearthstone: "home" in WoW's own picture language; no frame, it lights up under the mouse
    local C = S.C
    local b = CreateFrame("Button", nil, parent)
    b:SetHeight(24)
    local fill = S.Solid(b, "BACKGROUND", { 1, 1, 1 }, 0); fill:SetAllPoints()
    local icon = b:CreateTexture(nil, "ARTWORK")
    icon:SetTexture("Interface\\Icons\\INV_Misc_Rune_01")
    icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
    icon:SetSize(16, 16); icon:SetPoint("LEFT", 6, 0)
    icon:SetDesaturated(true); icon:SetAlpha(0.8)
    local label = S.Text(b, 12, C.dim, true)
    label:SetPoint("LEFT", icon, "RIGHT", 6, 0)
    label:SetText(ns.L and ns.L("Accueil") or "Home")
    b:SetWidth(label:GetStringWidth() + 36)
    b:SetScript("OnEnter", function(self)
        fill:SetColorTexture(1, 1, 1, 0.06); icon:SetDesaturated(false); icon:SetAlpha(1); label:SetTextColor(1, 1, 1)
        S.Tip(self, { ns.L and ns.L("Retour à l'accueil") or "Back to home" })
    end)
    b:SetScript("OnLeave", function()
        fill:SetColorTexture(1, 1, 1, 0); icon:SetDesaturated(true); icon:SetAlpha(0.8)
        label:SetTextColor(C.dim[1], C.dim[2], C.dim[3])
        S.HideTip()
    end)
    b:SetScript("OnClick", onClick)
    b.label = label
    return b
end

-- A window with WL Helper's header: logo, title, subtitle, close; moves with the header, saved
-- position under db[posKey], Escape closes it.
function S.Window(name, width, height, title, subtitle, db, posKey)
    local C = S.C
    local f = CreateFrame("Frame", name, UIParent)
    f:SetSize(width, height)
    f:SetFrameStrata("HIGH")
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    local pos = db and db[posKey]
    if pos then f:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4]) else f:SetPoint("CENTER") end
    tinsert(UISpecialFrames, name)
    S.Solid(f, "BACKGROUND", C.bg):SetAllPoints()
    S.Border(f, C.border)

    local h = CreateFrame("Frame", nil, f)
    h:SetPoint("TOPLEFT", 1, -1); h:SetPoint("TOPRIGHT", -1, -1); h:SetHeight(38)
    S.Solid(h, "BACKGROUND", C.header):SetAllPoints()
    local line = S.Solid(h, "BORDER", C.divider)
    line:SetPoint("BOTTOMLEFT"); line:SetPoint("BOTTOMRIGHT"); line:SetHeight(1)
    h:EnableMouse(true)
    h:RegisterForDrag("LeftButton")
    h:SetScript("OnDragStart", function() f:StartMoving() end)
    h:SetScript("OnDragStop", function()
        f:StopMovingOrSizing()
        if db then local p, _, rp, x, y = f:GetPoint(); db[posKey] = { p, rp, x, y } end
    end)
    -- back to the home page: "‹" and the logo, in every window but the home page and the small popups
    local NO_BACK = { WLHelperHome = true, WLHelperDecline = true, WLHelperWelcome = true }
    local logoX = 9
    local function GoHome()
        f:Hide()
        local WP = ns.WP
        if WP and WP.OpenHome then WP.OpenHome() end
    end
    local function HomeTip(self) S.Tip(self, { ns.L and ns.L("Retour à l'accueil") or "Home" }) end
    if not NO_BACK[name or ""] then
        f.back = S.HomeButton(h, GoHome)
        f.back:SetPoint("LEFT", 6, 0)
        logoX = nil
    end
    local logo = h:CreateTexture(nil, "ARTWORK")
    logo:SetSize(20, 20); logo:SetTexture(S.LOGO)
    if logoX then logo:SetPoint("LEFT", logoX, 0) else logo:SetPoint("LEFT", f.back, "RIGHT", 10, 0) end
    if not NO_BACK[name or ""] then
        local lb = CreateFrame("Button", nil, h)
        lb:SetAllPoints(logo)
        lb:SetScript("OnClick", GoHome)
        lb:SetScript("OnEnter", HomeTip); lb:SetScript("OnLeave", S.HideTip)
    end
    f.title = S.Text(h, 15, C.text, true)
    f.title:SetPoint("LEFT", logo, "RIGHT", 8, 0)
    f.title:SetText(title or "")
    f.subtitle = S.Text(h, 13, C.dim)
    f.subtitle:SetPoint("LEFT", f.title, "RIGHT", 8, 0)
    f.subtitle:SetText(subtitle or "")
    local close = S.CloseButton(h, 32, function() f:Hide() end, nil, 11)
    close:SetPoint("RIGHT", -2, 0)
    f.header, f.close = h, close
    -- Two windows open at once must not mix: the one clicked or opened last comes on top, whole.
    f:SetToplevel(true)
    local raiser = CreateFrame("Frame", nil, f)
    raiser:SetScript("OnShow", function() f:Raise() end)
    f:Hide()
    return f
end

-- A small icon button (header actions). texture: a file path, or { atlases = { ... }, path = file }.
function S.IconButton(parent, texture, size, tip, onClick)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(size or 28, size or 28)
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetSize((size or 28) - 12, (size or 28) - 12)
    b.icon:SetPoint("CENTER")
    if type(texture) == "table" then S.SetIcon(b.icon, texture.atlases, texture.path, texture.coords)
    else b.icon:SetTexture(texture) end
    b.icon:SetVertexColor(S.C.dim[1], S.C.dim[2], S.C.dim[3])
    b:SetScript("OnEnter", function(self) self.icon:SetVertexColor(1, 1, 1); if tip then S.Tip(self, tip) end end)
    b:SetScript("OnLeave", function(self) self.icon:SetVertexColor(S.C.dim[1], S.C.dim[2], S.C.dim[3]); S.HideTip() end)
    b:SetScript("OnClick", onClick)
    return b
end

-- Section label in option pages (the only place uppercase labels are used).
function S.Section(parent, text)
    local fs = S.Text(parent, 12, S.C.dim, true)
    fs:SetText(root.Upper and root.Upper(text) or text:upper())
    return fs
end

-- Strings other modules add to the English table (they write their own French keys).
function ns.AddEnglish(t)
    if ns.EN then for k, v in pairs(t) do ns.EN[k] = v end end
end
