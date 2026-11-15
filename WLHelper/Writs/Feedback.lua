-- Writs/Feedback.lua: "Une idée, un bug ?" An addon cannot reach the internet, so this window builds
-- the link of a GitHub issue form, already filled with the addon version, the client and the
-- character, for the player to copy into a browser. Three forms: an idea, a bug, a wrong quest data.
-- Opened from the options (About) and /wl idea.
local ADDON, root = ...
root.Writs = root.Writs or {}
local ns = root.Writs
local WP = ns.WP
local L = ns.L
local S = ns.S
local C = S.C

ns.AddEnglish({
    ["Une idée, un bug ?"] = "An idea, a bug?",
    ["Proposer une idée"] = "Suggest an idea",
    ["Signaler un bug"] = "Report a bug",
    ["Quête ou donnée fausse"] = "Wrong quest data",
    ["Le jeu interdit aux addons d'aller sur internet. Il te faut trois clics :"] =
        "The game does not let addons go online. Three clicks:",
    ["Choisis ce que tu veux envoyer"] = "Pick what you want to send",
    ["Copie le lien (Ctrl+C)"] = "Copy the link (Ctrl+C)",
    ["Colle-le dans ton navigateur : le formulaire s'ouvre déjà rempli avec ta version."] =
        "Paste it into your browser: the form opens already filled with your version.",
    ["Il faut un compte GitHub, c'est gratuit."] = "You need a GitHub account, it is free.",
})

local REPO = "https://github.com/WarLegenDHelper/WLHelper/issues/new"
local FORMS = {
    idea = { template = "idea.yml", label = "Proposer une idée" },
    bug  = { template = "bug.yml",  label = "Signaler un bug" },
    data = { template = "data.yml", label = "Quête ou donnée fausse" },
}
local ORDER = { "idea", "bug", "data" }

local function Encode(s)
    return (tostring(s):gsub("[^%w%-%._~]", function(c) return string.format("%%%02X", c:byte()) end))
end

local function Version()
    local meta = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
    return meta and meta(ADDON, "Version") or "?"
end

-- What the form gets: version, client language, character (no name: nothing personal).
local function Context(kind)
    local _, cls = UnitClass("player")
    local parts = {
        "WL Helper " .. Version(),
        "client " .. (GetLocale and GetLocale() or "?") .. " / " .. ((GetBuildInfo and select(1, GetBuildInfo())) or "?"),
        (UnitFactionGroup("player") or "?") .. " " .. (cls or "?") .. " " .. (UnitLevel("player") or "?"),
        "langue addon " .. (root.lang or "?"),
    }
    if kind == "data" and type(WLDTDB) == "table" and type(WLDTDB.sel) == "table" then
        local sel = {}
        for k in pairs(WLDTDB.sel) do sel[#sel + 1] = k end
        table.sort(sel)
        if #sel > 0 then parts[#parts + 1] = "donjons " .. table.concat(sel, ", ") end
    end
    return table.concat(parts, " · ")
end

local function Link(kind)
    local f = FORMS[kind] or FORMS.idea
    return REPO .. "?template=" .. f.template .. "&version=" .. Encode(Version()) .. "&context=" .. Encode(Context(kind))
end

local win
local W, PAD = 460, 16

-- A numbered step: the number in the brand colour, the text beside it.
local function Step(parent, n, text, y)
    local num = S.Text(parent, 15, C.brandSoft or C.brand, true)
    num:SetPoint("TOPLEFT", PAD, y); num:SetText(n)
    local t = S.Text(parent, 14, C.text)
    t:SetPoint("TOPLEFT", PAD + 22, y); t:SetPoint("RIGHT", -PAD, 0)
    t:SetJustifyH("LEFT"); t:SetWordWrap(true); t:SetText(text)
    return t
end

local function Build()
    win = S.Window("WLHelperFeedback", W, 10, L("Une idée, un bug ?"), nil, WLWritsDB, "feedbackPos")
    local y = -38 - PAD
    local intro = S.Text(win, 13, C.dim)
    intro:SetPoint("TOPLEFT", PAD, y); intro:SetPoint("RIGHT", -PAD, 0); intro:SetJustifyH("LEFT")
    intro:SetText(L("Le jeu interdit aux addons d'aller sur internet. Il te faut trois clics :"))
    y = y - 30

    -- 1. what to send: one button per form, the chosen one bright
    Step(win, "1", L("Choisis ce que tu veux envoyer"), y)
    y = y - 26
    local w = (W - 2 * PAD - 22 - 2 * 8) / 3
    win.buttons = {}
    for i, kind in ipairs(ORDER) do
        local bt = S.Button(win, L(FORMS[kind].label), w, 30, "secondary", function() WP.Feedback(kind) end)
        bt:SetPoint("TOPLEFT", PAD + 22 + (i - 1) * (w + 8), y)
        win.buttons[kind] = bt
    end
    y = y - 30 - 18

    -- 2. the link, selected, ready for Ctrl+C
    Step(win, "2", L("Copie le lien (Ctrl+C)"), y)
    y = y - 26
    local eb = CreateFrame("EditBox", nil, win)
    eb:SetPoint("TOPLEFT", PAD + 22, y); eb:SetPoint("RIGHT", -PAD, 0)
    eb:SetHeight(28)
    eb:SetAutoFocus(false)
    local probe = S.Text(win, 13, C.text)
    local font, size, flags = probe:GetFont()
    probe:Hide()
    if font then eb:SetFont(font, size or 13, flags or "") else eb:SetFontObject(ChatFontNormal) end
    eb:SetTextColor(C.info[1], C.info[2], C.info[3])
    eb:SetTextInsets(8, 8, 0, 0)
    S.Solid(eb, "BACKGROUND", C.card):SetAllPoints()
    S.Border(eb, C.border)
    eb:SetScript("OnTextChanged", function(self, user) if user then self:SetText(win.link or ""); self:HighlightText() end end)
    eb:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
    eb:SetScript("OnMouseUp", function(self) self:SetFocus(); self:HighlightText() end)
    eb:SetScript("OnEscapePressed", function(self) self:ClearFocus(); win:Hide() end)
    eb:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    win.box = eb
    y = y - 28 - 18

    -- 3. into the browser
    local t3 = Step(win, "3", L("Colle-le dans ton navigateur : le formulaire s'ouvre déjà rempli avec ta version."), y)
    y = y - math.max(18, math.ceil(t3:GetStringHeight() or 18)) - 16

    local note = S.Text(win, 12, C.dim)
    note:SetPoint("TOPLEFT", PAD + 22, y); note:SetText(L("Il faut un compte GitHub, c'est gratuit."))
    y = y - 18 - PAD
    win:SetHeight(-y)
end

-- Opens the window on a form ("idea" by default) with its link selected, ready for Ctrl+C.
function WP.Feedback(kind)
    if not win then Build() end
    kind = FORMS[kind] and kind or "idea"
    win.link = Link(kind)
    for k, bt in pairs(win.buttons) do
        local c = k == kind and (C.brandSoft or C.brand) or C.dim
        if bt.label then bt.label:SetTextColor(c[1], c[2], c[3]) end
    end
    win:Show()
    win.box:SetText(win.link)
    win.box:SetCursorPosition(0)   -- the start of the link shows, not its tail
    win.box:SetFocus()
    win.box:HighlightText()
end
