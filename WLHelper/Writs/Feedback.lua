-- Writs/Feedback.lua: "Une idée, un bug ?" An addon cannot reach the internet, so this window builds
-- the link of a GitHub issue form, already filled with the addon version, the client and the
-- character, for the player to copy into a browser. Three forms: an idea, a bug, a wrong quest data.
-- Opened from the options (À propos), /wl idee, /comptoir idee.
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
    ["Le jeu ne laisse pas un addon aller sur internet : copie ce lien (Ctrl+C) et colle-le dans ton navigateur. Le formulaire GitHub s'ouvre déjà rempli avec ta version ; il te faut un compte GitHub (gratuit)."] =
        "The game does not let an addon go online: copy this link (Ctrl+C) and paste it into your browser. The GitHub form opens already filled with your version; you need a (free) GitHub account.",
    ["Lien copié dans la zone : Ctrl+C"] = "Link selected: Ctrl+C",
})

local REPO = "https://github.com/NEM3S15/WLHelper/issues/new"
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
local function Build()
    win = S.Window("WLHelperFeedback", 460, 236, L("Une idée, un bug ?"), nil, WLWritsDB, "feedbackPos")
    local PAD = 14
    local intro = S.Text(win, 13, C.dim)
    intro:SetPoint("TOPLEFT", PAD, -38 - PAD)
    intro:SetPoint("TOPRIGHT", -PAD, -38 - PAD)
    intro:SetJustifyH("LEFT"); intro:SetWordWrap(true)
    intro:SetText(L("Le jeu ne laisse pas un addon aller sur internet : copie ce lien (Ctrl+C) et colle-le dans ton navigateur. Le formulaire GitHub s'ouvre déjà rempli avec ta version ; il te faut un compte GitHub (gratuit)."))

    local eb = CreateFrame("EditBox", nil, win)
    eb:SetPoint("BOTTOMLEFT", PAD, PAD)
    eb:SetPoint("BOTTOMRIGHT", -PAD, PAD)
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

    -- one button per form; the chosen one is the primary
    local w = (460 - 2 * PAD - 2 * 8) / 3
    win.buttons = {}
    for i, kind in ipairs(ORDER) do
        local b = S.Button(win, L(FORMS[kind].label), w, 32, "secondary", function() WP.Feedback(kind) end)
        b:SetPoint("BOTTOMLEFT", PAD + (i - 1) * (w + 8), PAD + 28 + 12)
        win.buttons[kind] = b
    end
end

-- Opens the window on a form ("idea" by default) with its link selected, ready for Ctrl+C.
function WP.Feedback(kind)
    if not win then Build() end
    kind = FORMS[kind] and kind or "idea"
    win.link = Link(kind)
    for k, b in pairs(win.buttons) do
        if b.label then b.label:SetTextColor((k == kind and C.text or C.dim)[1], (k == kind and C.text or C.dim)[2], (k == kind and C.text or C.dim)[3]) end
    end
    win:Show()
    win.box:SetText(win.link)
    win.box:SetFocus()
    win.box:HighlightText()
end
