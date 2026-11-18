-- Writs/Feedback.lua: "Une idée, un bug ?" An addon cannot reach the internet, so this window builds
-- the link of a GitHub issue form, already filled with the addon version, the client and the
-- character, for the player to copy into a browser. Three forms: an idea, a bug, a wrong quest data.
-- Opened from the home page footer, the options (About) and /wlh idea.
local ADDON, root = ...
root.Writs = root.Writs or {}
local ns = root.Writs
local WP = ns.WP
local L = ns.L
local S = ns.S
local C = S.C
local F = S.F

ns.AddEnglish({
    ["Une idée, un bug ?"] = "An idea, a bug?",
    ["Écris-nous ici : ton message part tout seul à l'équipe WL Helper, par la guilde. Aucun compte à créer."] =
        "Write to us here: your message goes straight to the WL Helper team, through the guild. No account to make.",
    ["Ton message"] = "Your message",
    ["Ce qui se passe, où, et ce que tu attendais."] = "What happens, where, and what you expected.",
    ["Une capture d'écran ? Mets-la sur Discord ou imgur, puis colle son lien ici (facultatif)."] =
        "A screenshot? Put it on Discord or imgur, then paste its link here (optional).",
    ["Lien de la capture (Ctrl+V)"] = "Screenshot link (Ctrl+V)",
    ["Envoyer"] = "Send",
    ["Écris d'abord ton message."] = "Write your message first.",
    ["Envoyé, merci ! Ta position, ton étape du guide et ta version partent avec."] = "Sent, thanks! Your position, guide step and version go with it.",
    ["Gardé : il partira dès qu'un responsable de la guilde sera connecté."] = "Kept: it will go as soon as a guild officer is online.",
    ["Tu n'es pas dans une guilde : utilise le formulaire GitHub plus bas."] = "You are not in a guild: use the GitHub form below.",
    ["Avec un compte GitHub (facultatif)"] = "With a GitHub account (optional)",
    ["Plus simple, sans compte : tape /wlh bug ou /wlh idee suivi de ton message, il part directement à l'équipe par la guilde."] =
        "Simpler, no account: type /wlh bug or /wlh idea followed by your message, it goes straight to the team through the guild.",
    -- the buttons of the options' About page open this window on a form
    ["Proposer une idée"] = "Suggest an idea",
    ["Signaler un bug"] = "Report a bug",
    ["Le jeu ne laisse pas les addons aller sur internet : tu nous écris depuis ton navigateur, en trois étapes."] =
        "The game does not let addons go online: you write to us from your browser, in three steps.",
    ["Choisis ce que tu veux nous dire."] = "Pick what you want to tell us.",
    ["Une idée"] = "An idea",
    ["Un bug"] = "A bug",
    ["Une erreur de quête"] = "Wrong quest data",
    ["Une quête, un PNJ ou une position qui ne correspond pas au jeu."] = "A quest, an NPC or a position that does not match the game.",
    ["Ce qui ne marche pas. Le formulaire reçoit ta version et la dernière action bloquée par le jeu."] =
        "What does not work. The form gets your version and the last action the game blocked.",
    ["Ce qui te manque ou ce qui pourrait être plus simple."] = "What you miss or what could be simpler.",
    ["Copie le lien : il est déjà sélectionné, fais Ctrl+C."] = "Copy the link: it is already selected, press Ctrl+C.",
    ["Lien copié"] = "Link copied",
    ["Clic : sélectionner tout le lien"] = "Click: select the whole link",
    ["Colle-le dans ton navigateur : le formulaire s'ouvre déjà rempli avec ta version. Il te faut un compte GitHub, c'est gratuit."] =
        "Paste it into your browser: the form opens already filled in with your version. You need a GitHub account, it is free.",
})

local REPO = "https://github.com/WarLegenDHelper/WLHelper/issues/new"
local FORMS = {
    idea = { template = "idea.yml", label = "Une idée", hint = "Ce qui te manque ou ce qui pourrait être plus simple." },
    bug  = { template = "bug.yml",  label = "Un bug", hint = "Ce qui ne marche pas. Le formulaire reçoit ta version et la dernière action bloquée par le jeu." },
    data = { template = "data.yml", label = "Une erreur de quête", hint = "Une quête, un PNJ ou une position qui ne correspond pas au jeu." },
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
    -- the last action the game blocked (Writs/Core.lua), for a bug report
    local b = WLWritsDB and WLWritsDB.lastBlocked
    if kind == "bug" and b then
        parts[#parts + 1] = "bloqué " .. tostring(b.func) .. (b.combat and " (combat)" or "") .. " v" .. tostring(b.ver)
    end
    return table.concat(parts, " · ")
end

local function Link(kind)
    local f = FORMS[kind] or FORMS.idea
    return REPO .. "?template=" .. f.template .. "&version=" .. Encode(Version()) .. "&context=" .. Encode(Context(kind))
end

local CW = 614 - 32       -- the content width, read again by Dims() at every layout
local TEXT_X = 28          -- the step's text starts after its number chip (20) and a gap of 8

local win

-- The width from the window (a panel, DESIGN 3.1: 576 to 860 from the screen, the player can drag
-- it); not sized yet: the rule's default.
local function WinW()
    local w = win and win:GetWidth()
    if type(w) ~= "number" or (root.IsSecret and root.IsSecret(w)) or w < 300 then
        w = (root.WinSize and root.WinSize("panel")) or 614
    end
    return math.floor(w)
end
local function Dims() CW = WinW() - 32; return CW end

-- A numbered step: the number in a soft round chip, the sentence beside it (wraps).
local function Step(parent, n, text)
    local s = {}
    s.dot = root.Icon(parent, "dot", 20, "ARTWORK", { 1, 1, 1 })
    s.dot:SetVertexColor(1, 1, 1, 0.14)
    s.num = S.Text(parent, F.meta, C.fg, true)
    s.num:SetWordWrap(false); s.num:SetJustifyH("CENTER")
    s.num:SetPoint("CENTER", s.dot, "CENTER", 0, 0)
    s.num:SetText(tostring(n))
    s.text = S.Text(parent, F.body, C.fg)
    s.text:SetJustifyH("LEFT"); s.text:SetJustifyV("TOP")
    s.text:SetWordWrap(true)
    s.text:SetText(text)
    -- places the step at y (from the content top); returns its height
    function s:Place(y)
        local h = math.ceil(S.FitText(self.text, 0, CW - TEXT_X, parent))
        self.dot:ClearAllPoints(); self.dot:SetPoint("TOPLEFT", parent, "TOPLEFT", 16, -y)
        self.text:ClearAllPoints(); self.text:SetPoint("TOPLEFT", parent, "TOPLEFT", 16 + TEXT_X, -(y + (h <= 16 and 3 or 1)))
        return math.max(20, h)
    end
    return s
end

local function Layout()
    if not win then return end
    Dims()
    if win.kinds.SetMaxWidth then win.kinds:SetMaxWidth(CW - TEXT_X) end
    local top = win:ContentTop() + 12
    local y = top
    local x = 16 + TEXT_X
    win.intro:ClearAllPoints(); win.intro:SetPoint("TOPLEFT", 16, -y)
    y = y + math.ceil(S.FitText(win.intro, 0, CW, win)) + 16
    -- 1. what to send
    y = y + win.step1:Place(y) + 8
    win.kinds:ClearAllPoints(); win.kinds:SetPoint("TOPLEFT", x, -y)
    y = y + 28 + 4
    win.hint:ClearAllPoints(); win.hint:SetPoint("TOPLEFT", x, -y)
    y = y + math.ceil(S.FitText(win.hint, 2, CW - TEXT_X, win)) + 16
    -- 2. the message
    y = y + win.step2m:Place(y) + 8
    win.msg:ClearAllPoints(); win.msg:SetPoint("TOPLEFT", x, -y); win.msg:SetPoint("RIGHT", win, "RIGHT", -16, 0)
    win.msg:SetHeight(96)
    y = y + 96 + 16
    -- 3. a screenshot's link, then Send
    y = y + win.step3s:Place(y) + 8
    win.shot:ClearAllPoints(); win.shot:SetPoint("TOPLEFT", x, -y); win.shot:SetPoint("RIGHT", win, "RIGHT", -16, 0)
    y = y + 28 + 12
    win.send:ClearAllPoints(); win.send:SetPoint("TOPLEFT", x, -y)
    y = y + 32
    if (win.status:GetText() or "") ~= "" then
        y = y + 6
        win.status:ClearAllPoints(); win.status:SetPoint("TOPLEFT", x, -y)
        y = y + math.ceil(S.FitText(win.status, 2, CW - TEXT_X, win))
    end
    y = y + 20
    win.ghHead:ClearAllPoints(); win.ghHead:SetPoint("TOPLEFT", 16, -y)
    y = y + 20
    -- 4. the link, selected, ready for Ctrl+C
    y = y + win.step2:Place(y) + 8
    win.box:ClearAllPoints(); win.box:SetPoint("TOPLEFT", x, -y); win.box:SetPoint("RIGHT", win, "RIGHT", -16, 0)
    y = y + 28
    if win.copied:IsShown() then
        -- "Lien copié" under the box, its check icon first
        y = y + 4
        win.copiedIcon:ClearAllPoints(); win.copiedIcon:SetPoint("TOPLEFT", x, -y)
        win.copied:ClearAllPoints(); win.copied:SetPoint("TOPLEFT", x + 18, -(y + 1))
        y = y + 14
    end
    y = y + 16
    -- 5. into the browser
    y = y + win.step3:Place(y)
    win:FitHeight(y - top)
end

local function ShowCopied(on)
    if not win then return end
    local was = win.copied:IsShown()
    win.copied:SetShown(on and true or false)
    win.copiedIcon:SetShown(on and true or false)
    if was ~= (on and true or false) and win:IsShown() then Layout() end
end

local function Build()
    win = S.Window("WLHelperFeedback", (root.WinSize("panel")) or 614, 300, L("Une idée, un bug ?"), nil, WLWritsDB, "feedbackPos",
        { header = 44, minH = 240, size = "panel" })
    win.OnResize = function() Layout() end
    win.intro = S.Text(win, F.body, C.text)
    win.intro:SetJustifyH("LEFT"); win.intro:SetJustifyV("TOP"); win.intro:SetWordWrap(true)
    win.intro:SetText(L("Écris-nous ici : ton message part tout seul à l'équipe WL Helper, par la guilde. Aucun compte à créer."))

    -- 1. what to send: a segmented choice, and one sentence on what that form is for
    win.step1 = Step(win, 1, L("Choisis ce que tu veux nous dire."))
    local opts = {}
    for _, kind in ipairs(ORDER) do opts[#opts + 1] = { kind, L(FORMS[kind].label) } end
    win.kinds = S.Segmented(win, opts, function() return win.kind end, function(v) WP.Feedback(v) end, 28)
    win.hint = S.Text(win, F.meta, C.muted)
    win.hint:SetJustifyH("LEFT"); win.hint:SetJustifyV("TOP")

    -- 2. the message, written here (report: "/wlh bug is too much trouble, a button and a screenshot")
    win.step2m = Step(win, 2, L("Ton message"))
    local msg = CreateFrame("EditBox", nil, win)
    msg.wlOwned = true
    msg:SetMultiLine(true)
    msg:SetAutoFocus(false)
    msg:SetMaxLetters(500)
    do
        local p2 = S.Text(win, F.label, C.fg)
        local fnt, sz, fl = p2:GetFont()
        p2:Hide()
        if fnt then msg:SetFont(fnt, sz or 12, fl or "") else msg:SetFontObject(ChatFontNormal) end
    end
    msg:SetTextColor(C.fg[1], C.fg[2], C.fg[3])
    msg:SetTextInsets(8, 8, 6, 6)
    S.Solid(msg, "BACKGROUND", C.panel):SetAllPoints()
    local msgEdge = S.Border(msg, C.line)
    msg.placeholder = S.Text(msg, F.label, C.faint)
    msg.placeholder:SetPoint("TOPLEFT", 8, -6)
    msg.placeholder:SetText(L("Ce qui se passe, où, et ce que tu attendais."))
    msg:SetScript("OnTextChanged", function(self) self.placeholder:SetShown((self:GetText() or "") == "") end)
    msg:SetScript("OnEditFocusGained", function() msgEdge(C.accent) end)
    msg:SetScript("OnEditFocusLost", function() msgEdge(C.line) end)
    msg:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    msg:SetScript("OnMouseDown", function(self) self:SetFocus() end)
    win.msg = msg
    -- 3. a screenshot, by its link (the game lets no addon attach or send an image)
    win.step3s = Step(win, 3, L("Une capture d'écran ? Mets-la sur Discord ou imgur, puis colle son lien ici (facultatif)."))
    win.shot = S.Input(win, 300, { placeholder = L("Lien de la capture (Ctrl+V)") })
    win.send = S.Button(win, L("Envoyer"), 0, 32, "primary", function()
        local text = win.msg:GetText() or ""
        if not text:find("%S") then win.status:SetText(L("Écris d'abord ton message.")); win.status:SetTextColor(C.warn[1], C.warn[2], C.warn[3]); Layout(); return end
        if not (IsInGuild and IsInGuild()) then win.status:SetText(L("Tu n'es pas dans une guilde : utilise le formulaire GitHub plus bas.")); win.status:SetTextColor(C.warn[1], C.warn[2], C.warn[3]); Layout(); return end
        local kind = win.kind == "data" and "quest" or win.kind
        local rec = WP.Reports and WP.Reports.New(kind, text, win.shot:GetText())
        if rec then
            win.msg:SetText(""); win.shot:SetText(""); win.msg:ClearFocus(); win.shot:ClearFocus()
            if win.shot.Paint then win.shot.Paint() end
            win.status:SetText(rec.delivered and L("Envoyé, merci ! Ta position, ton étape du guide et ta version partent avec.")
                or L("Gardé : il partira dès qu'un responsable de la guilde sera connecté."))
            win.status:SetTextColor(C.ok[1], C.ok[2], C.ok[3])
            Layout()
        end
    end)
    win.status = S.Text(win, F.meta, C.ok)
    win.status:SetJustifyH("LEFT"); win.status:SetWordWrap(true)
    -- the GitHub form, as before, under its own heading
    win.ghHead = S.Text(win, F.label, C.muted, true)
    win.ghHead:SetText(L("Avec un compte GitHub (facultatif)"))
    win.step2 = Step(win, 4, L("Copie le lien : il est déjà sélectionné, fais Ctrl+C."))
    local eb = CreateFrame("EditBox", nil, win)
    eb.wlOwned = true
    eb:SetHeight(28)
    eb:SetAutoFocus(false)
    local probe = S.Text(win, F.label, C.fg)
    local font, size, flags = probe:GetFont()
    probe:Hide()
    if font then eb:SetFont(font, size or 12, flags or "") else eb:SetFontObject(ChatFontNormal) end
    eb:SetTextColor(C.accentSoft[1], C.accentSoft[2], C.accentSoft[3])
    eb:SetTextInsets(8, 8, 0, 0)
    S.Solid(eb, "BACKGROUND", C.panel):SetAllPoints()
    local edge = S.Border(eb, C.line)
    eb:SetScript("OnTextChanged", function(self, user) if user then self:SetText(win.link or ""); self:HighlightText() end end)
    eb:SetScript("OnEditFocusGained", function(self) edge(C.accent); self:HighlightText() end)
    eb:SetScript("OnEditFocusLost", function() edge(C.line) end)
    eb:SetScript("OnMouseUp", function(self) self:SetFocus(); self:HighlightText() end)
    eb:SetScript("OnEscapePressed", function(self) self:ClearFocus(); win:Hide() end)
    eb:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    eb:SetScript("OnEnter", function(self) S.Tip(self, { L("Copie le lien : il est déjà sélectionné, fais Ctrl+C."), L("Clic : sélectionner tout le lien") }) end)
    eb:SetScript("OnLeave", S.HideTip)
    -- Ctrl+C in the box: say it worked, right under it
    pcall(eb.HookScript, eb, "OnKeyDown", function(_, key)
        if key == "C" and IsControlKeyDown and IsControlKeyDown() then ShowCopied(true) end
    end)
    win.box = eb
    win.copiedIcon = root.Icon(win, "check", 14, "ARTWORK", C.ok)
    win.copied = S.Text(win, F.meta, C.ok)
    win.copied:SetWordWrap(false)
    win.copied:SetText(L("Lien copié"))
    ShowCopied(false)

    -- 3. into the browser
    win.step3 = Step(win, 5, L("Colle-le dans ton navigateur : le formulaire s'ouvre déjà rempli avec ta version. Il te faut un compte GitHub, c'est gratuit."))

    win:SetScript("OnShow", function()
        Layout()
        if C_Timer and C_Timer.After then C_Timer.After(0, function() if win:IsShown() then Layout() end end) end
    end)
end

-- Opens the window on a form ("idea" by default) with its link selected, ready for Ctrl+C.
function WP.Feedback(kind)
    -- the simpler way, no account: written here, sent through the guild (Writs/Reports.lua)
    if not win then Build() end
    kind = FORMS[kind] and kind or "idea"
    win.link = Link(kind)
    win.kind = kind
    win.hint:SetText(L(FORMS[kind].hint))
    win.kinds:Update()
    ShowCopied(false)
    win:Show()
    win.box:SetText(win.link)
    win.box:SetCursorPosition(0)   -- the start of the link shows, not its tail
    win.status:SetText("")
    -- the message first: the box ready to type in
    win.msg:SetFocus()
    Layout()
end
