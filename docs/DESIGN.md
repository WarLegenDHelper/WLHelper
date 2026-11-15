# WL Helper design system

Status: the spec every WL Helper window follows. When the code and this file disagree, change the code.
Scope: every frame the addon draws: the guide (UI.lua, Picker.lua, Journal.lua, Nav.lua), the Writs modules (Writs/*.lua), the GPS HUD, tooltips and chat output.
Client: WoW Forever (interface 16001, Lua 5.1, vanilla content on a modern engine). Everything here can be built with SetColorTexture, white tintable textures, FontStrings and PixelUtil. No code or data from other addons: the principles below were learned from reading them, and the numbers are our own.

---

## 0. The rules in one screen

1. **One accent.** WaR LegenD red `#CE1918` marks only three things: the one main action of a view, what is selected or on, and keyboard focus. Every other surface is a neutral dark colour or white at an alpha.
2. **No side stripes.** No coloured bar on the left or right of a card, row, chip or nav item, ever. Show state with a fill, a brighter text colour, an icon or a word.
3. **No "..." from the engine.** Text wraps to 2 lines and its container grows. Only text whose container truly cannot grow (tab label, pill, single-line HUD) is cut, and then the full text is in the tooltip.
4. **Windows fit their content.** Height is measured after every render. A window is never more than about 40 px taller than what it shows.
5. **HD icons only.** Interface glyphs come from `Media/Icons/*.tga` (and `Media/Arrow.tga` for the GPS). Things (items, professions, classes, dungeons, modules) use painted `Interface\\Icons\\*`, cropped 0.08-0.92, 48 px max. No font glyphs, no stock low-res buttons.
6. **Every sentence is written for its place.** Read the title, the sentence and the button of a view out loud in order before shipping. French and English are each written as natural sentences, not translated word by word.
7. **One primary button per view.** Everything else is secondary, ghost or a row click.

---

## 1. Tokens

All tokens live in ONE table, `ns.T` (Theme.lua). `Writs/Style.lua` reads `S.C = ns.T` instead of keeping its own palette. No widget may contain a raw colour triple: only token names. `ns.Hex` is the one hex helper (S.Hex becomes an alias).

### 1.1 Colours

Base neutrals (opaque):

| Token | Hex | RGB 0-1 | Use |
|---|---|---|---|
| `bg` | `#0D0E10` | 0.051, 0.055, 0.063 | window backdrop, at alpha 0.97 |
| `panel` | `#16171A` | 0.086, 0.090, 0.102 | input field fill, dropdown list, tooltip backdrop (alpha 0.96) |
| `line` | `#2E3136` | 0.180, 0.192, 0.212 | the rule under the header, input borders |
| `trackOff` | `#3D4146` | 0.239, 0.255, 0.275 | switch track when off, scrollbar thumb base |
| `fg` | `#F0F1F3` | 0.941, 0.945, 0.953 | main text, titles, icons on hover |
| `text` | `#C9CCD1` | 0.788, 0.800, 0.820 | body sentences |
| `muted` | `#9A9EA6` | 0.604, 0.620, 0.651 | meta lines, descriptions, footer, icons at rest |
| `faint` | `#6B6F76` | 0.420, 0.435, 0.463 | disabled text, placeholders (never for information the player needs) |

Accent:

| Token | Hex | Use |
|---|---|---|
| `accent` | `#CE1918` | primary button fill, active tab underline, switch on, focus border, selected border |
| `accentHover` | `#E0302E` | primary button on hover |
| `accentPress` | `#A81412` | primary button pressed |
| `accentSoft` | `#E8605A` | links, selected text, icons that act as links at rest |

Semantic (text colour, icon tint, or 14-16 % fill behind a pill; never a stripe, never a whole sentence):

| Token | Hex | Meaning |
|---|---|---|
| `ok` | `#4CD07A` | have, done, ready, online |
| `warn` | `#FB923C` | attention, soon, reserve, overflow |
| `bad` | `#F87171` | error, destructive action (always with the trash or warning icon so it is not read as the accent) |
| `gold` | `#E6CC80` | money, top 3 rank, legendary quality |
| `info` | `#7AB8F5` | neutral information icon only |

Rule: at most 2 semantic colours in one row. Class colours only on player names. Item quality colours only on item names.

Alpha layers (white or black over `bg`; never a new grey):

| Token | Value | Use |
|---|---|---|
| `cardFill` | white 0.030 | card, list row, settings group |
| `cardEdge` | black 0.70, 1 px | card outline |
| `divider` | white 0.06, 1 px | rule between rows, under a section header |
| `hoverFill` | white 0.05 | row or card under the mouse |
| `pressFill` | black 0.35 | flat button or row pressed |
| `btnFill` | white 0.04 | secondary button at rest |
| `btnEdge` | white 0.22 | secondary button border (0.40 on hover) |
| `selFill` | accent 0.14 | selected row, selected segment, selected nav item |
| `tabFill` | accent 0.12 | active tab background |
| `tabHover` | accent 0.06 | tab under the mouse |
| `zebra` | black 0.10 / 0.18 | alternate rows in long settings or ranking lists |
| `disabled` | 0.35 on the whole widget | disabled controls |
| `scrim` | black 0.55 | behind a modal confirm |

`brandBg` as a solid dark-red fill is removed everywhere. Use `selFill` or `tabFill`.

### 1.2 Typography

One font family (the client's standard UI font; the heading weight is the same face). Only these sizes exist:

| Token | Size | Colour | Use |
|---|---|---|---|
| `F.title` | 16 | fg | window title |
| `F.hero` | 20 | fg or gold | one hero number per view (gold, ranking score), never a sentence |
| `F.heading` | 14 | fg | card title, empty-state title, settings label |
| `F.body` | 13 | text | sentences, row names in reading views |
| `F.label` | 12 | fg | buttons, tabs, segmented, inputs, list row name in dense lists |
| `F.meta` | 11 | muted | descriptions, detail line, subtitle, tooltip body |
| `F.foot` | 10 | muted | footer only |

Rules:
- Line gap 3 px inside a two-line row (name, then detail). Paragraph gap 4 px.
- No text shadow on panel text. Shadow (black 0.9, offset 1,-1) only on text drawn over the 3D world: GPS HUD, arrow distance, floating labels.
- Sentence case everywhere: section headers, tabs, buttons. No ALL CAPS headers ("GUIDE" becomes "Guide"). Uppercase only for a 2-3 letter tag that is a real abbreviation (PvP, HV).
- A detail line differs from the line above by colour (muted) AND size (one step down). Never two adjacent lines at the same size and colour when one is the answer and the other the detail.
- Numbers the player acts on ("3 writs prêts à rendre") are body, not meta.

### 1.3 Spacing

4-based scale, with 2 and 6 for hairline-level adjustments only:

| Token | px | Use |
|---|---|---|
| `SP.xxs` | 2 | gap between list rows, icon-to-edge in a pill |
| `SP.xs` | 4 | label above its field, title-to-description, pill side pad |
| `SP.sm` | 8 | related items, icon-to-text in a row, card inner gap |
| `SP.md` | 12 | window pad, card pad, label-to-control gap, gap between cards |
| `SP.lg` | 16 | panel content inset, gap between groups, settings card pad |
| `SP.xl` | 24 | empty-state top margin, gap between sections in a long page |

One left edge per panel: titles, body text, list icons and buttons all start at the content inset (16). Right-aligned controls share one right edge (16 from the window edge). All offsets are multiples of 2, and of 4 whenever possible.

### 1.4 Borders, radii, pixels

- Every border and rule is exactly 1 physical pixel: thickness = `PixelUtil.GetPixelToUIUnitFactor() / frame:GetEffectiveScale()`, refit on `UI_SCALE_CHANGED` and `DISPLAY_SIZE_CHANGED` (both registered through pcall).
- The only thicker line is the 2 px underline of the active tab.
- Corners: square everywhere. No mixing of rounded and square. The two round shapes allowed are the switch knob and the dot icon, both drawn from `Media/Icons/dot`.
- Recorded exception: creature portraits (the dungeon boss panel, Bosses.lua) are round, as the game draws them (`SetPortraitTextureFromCreatureDisplayID`, `SetPortraitTexture`). Every layer of a portrait stays round: the dark disc, the veil, the hover light and the painted fallback icon use the game's portrait mask `Interface\CharacterFrame\TempPortraitAlphaMask`, the edge is the HD `ring`. The panel around them stays square.
- Card: `cardFill` + 1 px `cardEdge`. No gradient, no inner glow, no stripe.

### 1.5 Motion

- Hover and state changes fade over 0.10 s (alpha or colour lerp in OnUpdate, stopped when done).
- Panels and toasts fade in or out over 0.15 s. No bounce, no slide-in from off screen.
- Switch knob slides over 0.08 s.
- The only looping animation: a slow pulse (alpha 1 to 0.6, 1.2 s) on the GPS arrow when arrived.
- Press feedback: content moves 1 px down and `pressFill` shows; released on mouse up.

---

## 2. Icons

### 2.1 HD interface icons

Path `Interface\\AddOns\\WLHelper\\Media\\Icons\\<name>`, white, 128 px, bevel lit from the top-left. Available: check, close, plus, minus, chevron_right, chevron_left, chevron_down, chevron_up, home, gear, search, refresh, pin, star, info, warning, clock, bag, trash, filter, user, group, mail, coin, calendar, hammer, shield, heal, sword, arrow_up, arrow_down, external, dot, flag, portal, skull, ring. Plus `Media/Arrow.tga` for the GPS.

Loading (one helper, `ns.Icon(parent, name, size, layer)`):
- `tex:SetTexture(path, nil, nil, "TRILINEAR")`, `tex:SetSnapToPixelGrid(false)`, `tex:SetTexelSnappingBias(0)` so the 128 px art stays sharp at 12-24 px.
- Tint with `SetVertexColor`, never by swapping textures.

Sizes:

| Context | Icon | Hit area |
|---|---|---|
| inside a pill or chip | 12 | - |
| inline with 12-13 px text | 14 | - |
| inside a button, leading the label | 16 | button |
| row action (pin, trash, chevron) | 16 | 24 x 24 |
| header action (gear, minus, refresh) | 18 | 28 x 28 |
| header home | 18 | 28 x 28 |
| close | 18 | 28 x 28, inset 8 from top-right |
| nav / empty-state glyph | 32 | - |

Tint: `muted` at rest, `fg` on hover, `accentSoft` when the icon is a link or toggled on, `faint` when disabled. Semantic icons (warning, check) use their semantic colour.

Mapping of the old glyphs: `<` chevron_left, `>` and `›` chevron_right, `▾` chevron_down, `x` and `✕` close, `-` minus, `+` plus, `...` gear (or a real menu: see 3.13), `★` star, `✓` check, stone rune "Accueil" home, `?` info. The drawn-line `S.Glyph` and the `GLYPH_FALLBACK` stock textures (UI-StopButton, UI-PlusButton, UI-CheckBox-Check) are deleted.

### 2.2 Painted game icons

For things only: items, professions, classes, dungeons, modules, factions.
- `SetTexCoord(0.08, 0.92, 0.08, 0.92)`. Class icons from the classicon atlas when present (crop 0.02).
- Sizes: 14-16 inline in text (`|T` at font size, y offset -1), 20 in a dense list, 28-30 in an item row, 32 in a card, 40-48 hero maximum. Never above 48, never upscale a texture smaller than its display size.
- 1 px `cardEdge` border around painted icons in rows and cards.

### 2.3 Logo

The header shows a 28 px clean guild mark (HD, at least 128 px source, from `docs/logo-512.png` reduced into `Media/`). The pixel skull is retired from headers.

---

## 3. Components

All components live in one module (`ns.UI`, reused by Writs through `S`), each with the states rest / hover / pressed / disabled / selected where they apply, set through one `ns.State(widget, state)` helper.

### 3.1 Window frame

```
+------------------------------------------------------------+
| [home] [logo] Title 16                    [gear][-][close] |  header 44
|               Subtitle 11 muted                            |
+------------------------------------------------------------+  1 px line
| Tab  Tab  Tab                                              |  tabs 32 (optional)
+------------------------------------------------------------+  1 px divider
|                                                            |
|  content, inset 16                                         |
|                                                            |
+------------------------------------------------------------+
| footer note 10 muted                         status 10     |  footer 24 (optional)
+------------------------------------------------------------+
```

- Backdrop `bg` at 0.97, 1 px `cardEdge` outline. No title-bar gradient.
- Width is fixed per window and chosen from: 360 (HUD-like), 420 (single list), 520 (two columns), 640 (wide tools). Width is never computed from text.
- One recorded exception: the guide tracker (Tracker.lua) is 300, a compact overlay that stays on screen beside the game's own trackers.
- Second recorded exception: the dungeon boss panel (Bosses.lua) is 248, five 40 px portraits with 6 px gaps and a 12 px pad, docked beside the guide like a dungeon journal.
- Movable by the header; position saved per window; clamped to screen.
- Strata MEDIUM, raised on mouse down. Escape closes (UISpecialFrames).

Header (44 px):
- Home button at x=8: 28 x 28 hit area, 18 px `home` icon, `muted` at rest, `fg` on hover. Tooltip "Accueil" / "Home" + "Clic : revenir à l'accueil" / "Click: back to Home". Hidden in the Home window itself. No "Accueil" text next to it.
- Logo 28 px at x=40 (x=8 when no home button).
- Title 16 fg, left at logo + 8. With a subtitle: title top at 6, subtitle 11 muted 2 px below on the same left edge, single line, cut only at the right cluster with the full text in the title tooltip. Without a subtitle: title centred vertically.
- Right cluster: 28 px hit areas, 4 px apart, close at x=-8. Order from the right: close, minus (collapse), gear, refresh, then any module icon. Max 4 icons.
- One 1 px `line` rule under the header across the full width.

### 3.2 Window sizing to content

Every window exposes `f:FitHeight()`, called at the end of every Render, after every tab change, and on the next frame after wrapped text was set (GetStringHeight is only right once the width is applied).

```
height = header 44 + (tabs 32 + 1 if tabs) + 12 + contentH + 12 + (footer 24 if footer)
height = clamp(height, minH, floor(UIParent:GetHeight() * 0.80))
```

- `contentH` is measured: the sum of rows and gaps, or the empty-state block height.
- `minH` = header + tabs + the tallest empty-state block of that window (typically 200-240). Never a fixed 560-860.
- Over the cap, the content scrolls inside the fixed frame (3.15). Under it, no scrollbar is shown and no empty space is left.
- The window keeps its TOP anchor when it changes height, so it grows downward and the header never jumps.
- The footer sticks to the content (it is the last element), not to an arbitrary bottom.
- Resizable windows (if any) save the size and use `SetResizeBounds(minW, minH, maxW, 0.8 * screenH)`.

### 3.3 Tabs

- Bar 32 px high, under the header, tabs start at x=16, 4 px apart.
- Each tab: label 12, width = text width + 24 (min 56). Off: `muted` text. Hover: `fg` text + `tabHover`. Active: `fg` text + `tabFill` + 2 px `accent` underline as wide as the text + 12, centred, sitting on the bar's bottom divider.
- Count badge in a tab: a neutral pill (3.11) after the label, 4 px gap. Not red unless it needs action now.
- If the tabs do not fit the width, shrink the widest tabs first down to 56, cut their label, and show the full label in the tab tooltip. Never wrap a tab label.
- Tab names reuse the glossary word (section 6). A tab is a noun ("Agenda", "Créer"), the button inside it repeats the word with its object ("Créer un événement").

### 3.4 Buttons

Common: label 12 `F.label`, leading HD icon 16 px with 6 px gap when the verb benefits from one, horizontal padding 12, width = max(minW, icon + gap + text width + 24). Width is never set smaller than the label: the button hooks its SetText and regrows. Heights: 24 (in rows), 28 (default), 32 (the main call to action of a view). Disabled: whole button at 0.35, no hover, tooltip line explaining why ("Indisponible en combat" / "Not available in combat").

| Variant | Rest | Hover | Pressed | Use |
|---|---|---|---|---|
| Primary | `accent` fill, `fg` text, no border | `accentHover` | `accentPress`, label 1 px down | the one main action of the view. Max one per view. |
| Secondary | `btnFill`, 1 px `btnEdge` (white 0.22), `fg` at 0.85 | border white 0.40, text 1.0, `hoverFill` | `pressFill` | every other button |
| Ghost / link | no fill, no border, `accentSoft` text, optional 10 px chevron_right after | `fg` text, 1 px underline under the text | text 1 px down | tertiary actions, "Voir tout", "Ouvrir le guide" |
| Danger | Secondary with `bad` text and the trash/warning icon | border `bad` at 0.6 | `pressFill` | destructive. Never primary. |
| Icon | 16-18 px HD icon in a 24-28 px hit area, no fill | `hoverFill` square + icon `fg` | `pressFill` | header and row actions. Tooltip required. |

Destructive pattern: first click changes the label to the confirmation ("Annuler l'événement" becomes "Confirmer l'annulation" / "Cancel event" becomes "Confirm cancel"), border `bad`; it returns to its normal label by itself after 4 s; the second click acts.

Feedback in place: after a successful action the button shows the check icon + the past tense for 2 s ("Inscrit" / "Signed up"), then returns to normal or disappears if the action no longer applies.

Secure buttons (macro, target, item use): never moved, shown or hidden in combat. If a change is needed in combat, it is queued to `PLAYER_REGEN_ENABLED` and the tooltip says why it is waiting.

### 3.5 Segmented control

- Height 28, label 12, each segment width = text width + 32 (min 56). Segments touch; the group has one 1 px `btnEdge` border, with 1 px `divider` between segments.
- Off: no fill, `muted` text. Hover: `hoverFill`, `fg` text. Selected: `selFill` (accent 0.14) + 1 px `accent` border around that segment + `fg` text. Never a solid red or dark-red block.
- French labels widen their segment; when the group would exceed the content width, it becomes a dropdown instead of cutting labels.

### 3.6 Switch

- 40 x 20, track drawn from a white pill texture (or two `dot` caps + a bar), knob = `dot` icon 16 px, 2 px pad.
- Off: track `trackOff` at 0.65, knob white 0.55, knob left. On: track `accent` at 0.85, knob white 1.0, knob right. Slide 0.08 s.
- Hover: knob white +0.15. Disabled: 0.35.
- The whole settings row is the click target, not only the switch.

### 3.7 Text input and search

- Height 28, `panel` fill, 1 px `line` border; focus: 1 px `accent` border. Text 12 `fg`, placeholder 12 `faint`, text inset 8.
- Search variant: HD `search` icon 14 px at x=8, `muted` (`fg` when focused), text starts at x=28. A clear button (HD `close` 12 px in a 20 px hit area, x=-4) appears only when there is text.
- Label above the field: 11 `muted`, 4 px above. Error under the field: 11 `bad`, 4 px below, one sentence that says what to type ("Heure invalide : écris par exemple 20:30." / "Invalid time: type for example 20:30.").
- Placeholders are examples, not instructions: "Ex. Zul'Farrak" / "E.g. Zul'Farrak".

### 3.8 Cards

- `cardFill` + 1 px `cardEdge`, pad 12 (16 for a settings group), gap 12 between cards.
- Optional painted icon 32 px at top-left, title 14 fg 8 px right of it, then lines below.
- Home card pattern (the model): icon + title + optional pill on the right, a state line (13 text), a next-step line (11 muted), a chevron_right 16 px muted at the right edge, centred on the card. Hover: `hoverFill` and chevron `fg`. Tooltip ends with "Clic : ouvrir ..." / "Click: open ...".
- Height = pad + content + pad, measured. Typical 64-84. No fixed heights that leave holes.
- No side stripe for "active" or "attention": use a pill or an icon.

### 3.9 List rows

Two densities:

| | Dense row | Reading row |
|---|---|---|
| Min height | 36 | 44 |
| Icon | 20-28 painted or 16 HD, left at 8 | 30 painted |
| Name | 12 fg | 13 fg |
| Detail | 11 muted, 3 px under the name | 11 muted, 3 px under |
| Insets | left 8, top 6, bottom 8, right 12 | same |

- Each row is `cardFill` with 2 px between rows, or a zebra list (black 0.10 / 0.18, no borders) for long settings and rankings. Not both in one list.
- Height = top 6 + lines x (size + 3) + bottom 8, so 36 for one 12 px line and 51 for two. The row grows when the name wraps.
- Hover `hoverFill`; selected `selFill` + name `fg`; pressed `pressFill`.
- Numbers right-aligned in a fixed column ending at the row's right inset; unit in 11 muted after the number. The name column takes all the remaining width (no dead space in the middle of the row).
- Rank column: 24 px, 12 bold, `gold` for 1-3, `muted` after.
- Row actions (pin, trash) at the right edge, 16 px icons, visible at 0.6 at rest and 1.0 on row hover. One idea per row: name + one detail line + one action. A third line goes in the tooltip.

### 3.10 Section headers

- Height 32 (24 when tight, in a card). Label 13 `fg` sentence case, bottom-left at x=16, 6 px above a 1 px `divider` spanning the content width.
- Optional count in 11 `muted` after the label ("Commandes ouvertes 3"), optional ghost link at the right ("Tout voir").
- Space above a section header: 16 (the first one: 8).

### 3.11 Badges, counters and pills

- Pill: height = font + 6 (12 px text gives 18), side pad 6, text 11. Fill = its colour at 0.16, 1 px border = its colour at 0.50, text in its colour (neutral: white 0.10 fill, white 0.20 border, `fg` text).
- Pills carry words, never codes: "À prendre" / "To take", "En cours" / "In progress", "Rendue" / "Turned in", "Dans le sac" / "In bags" (not HAVE, TAKE, "?"). An optional 12 px HD icon inside at 4 px left pad.
- Counter (number only, on a tab or icon): min width 18, height 16, text 10 bold, neutral fill; `accent` fill only when it counts things that need action now (pending invites, ready writs).
- A pill is single-line; if cut, the full text goes in its tooltip.

### 3.12 Empty state

One composed block, centred horizontally in the content area, 24 px from the top of the content:

1. HD icon 32 px, `muted` (calendar for events, group for LFG, hammer for orders, sword for PvP, bag for bags...).
2. 8 px gap, title 14 `fg`: the fact. "Aucun événement prévu" / "No events planned".
3. 4 px gap, optional sentence 12 `muted`, wrap width 320 max: why, or what will appear. "Les sorties de la guilde apparaîtront ici." / "Guild outings will show up here." It never tells the player to go somewhere or to press the button below.
4. 12 px gap, the one action, sized to its text (primary if it is the view's main action, else secondary): "Créer un événement" / "Create an event".

The window then fits this block (3.2). Options that belong to the view (auto-accept the organizer's invite) go in Settings or right under the list when the list is not empty, never alone at the bottom of an empty window.

Designed states for every list and card, before shipping: unknown/loading ("Faction pas encore vue. Parle à un PNJ de la faction pour la voir." + how), empty (above), normal, overflow ("+3 en réserve" in `warn`, scrolling).

### 3.13 Dropdowns and menus

- Trigger: secondary button with the current value and a 12 px chevron_down at the right, inset 8.
- List: `panel` at 0.98, 1 px `cardEdge`, rows 24 tall, text 12, hover `hoverFill`, the current value has a 12 px `check` at the left in `accentSoft`. Max 10 rows, then scroll.
- A "more actions" menu uses the gear icon, never a "..." text button.

### 3.14 Banners and toasts

- Banner (inside a window, under the tabs): height measured, pad 8 / 12, `cardFill` + a 16 % fill of its semantic colour, 1 px border of that colour at 0.4, a 16 px HD icon (info, warning, check) in that colour at left 12, text 12 `fg` wrapping to the full width, optional ghost link at the right. No side stripe. Dismissible with a 12 px close icon when it is not a blocking state.
- Toast (outside windows, top-centre under the screen top at y=-120): width 320, pad 10, `panel` at 0.96, 1 px `cardEdge`, 16 px icon + one sentence 12 `fg` (+ 11 muted second line max). Fades in 0.15 s, stays 4 s (6 s if it has a link), fades out. Max 2 stacked, 6 px apart. Toasts never replace an in-place confirmation on the button that acted.

### 3.15 Scroll areas

- Only when the window reached its height cap. Overlay bar 4 px wide, inset 2 from the right, 4 from top and bottom. Track white 0.02, thumb white 0.27 (0.45 on hover or drag), min thumb 30. Hidden when nothing overflows.
- Wheel step 48 px, smoothed (lerp speed 12). No stock UIPanelScrollFrame bar.

### 3.16 Tooltips

- GameTooltip styled: `panel` at 0.96, 1 px `cardEdge`, pad 8, max width 260 (text wraps).
- Line 1: the thing's name, 12 `fg` (or item quality / class colour).
- Then one line per fact, 11 `muted`, wrapped.
- Last line(s): what the mouse does, starting with the mouse word, 11 `accentSoft`: "Clic : ouvrir le guide" / "Click: open the guide", "Clic droit : désépingler" / "Right-click: unpin", "Maj-clic : lier dans le chat" / "Shift-click: link in chat".
- Every clickable element without a visible verb (card, icon button, chevron, pin, row) has that last line. A tooltip never only repeats the visible label.
- A cut label puts its full text as line 1.
- Disabled element: a line in `warn` saying why ("Indisponible en combat").

### 3.17 Footer

- 24 px, separated from the content by 12 px (no rule unless the content scrolls).
- Left: note 10 `muted` at x=16, one readable fragment: "Prix scannés il y a 3 min" / "Prices scanned 3 min ago"; 0 min reads "Prix scannés à l'instant" / "Prices scanned just now". Not "prix d'il y a 0 min".
- Right: a short status 10 `muted`, or one secondary 24 px button with a verb ("Scanner l'HV" / "Scan the AH", not "Rescanner").
- A footer note longer than one line is not a footer note: it moves into a banner or the tooltip of an info icon in the header.

### 3.18 Settings rows

- Label 13 `fg` at left 16, control right-aligned at right 16, at least 12 px between them.
- Description 11 `muted` on a SECOND line under the label, wrapping across the full row width minus the control column (control width + 12). Never squeezed between label and control on the label's line.
- Height: 36 without description; 6 + 13 + 3 + description height + 8 with one (50 for a one-line description, grows when it wraps).
- Rows separated by a 1 px `divider`, grouped under section headers (3.10) inside a settings card.

### 3.19 GPS HUD

- `Media/Arrow.tga` at 48 px (36 compact), tinted `fg`, `ok` when within 10 yd, with the arrival pulse. No other arrow texture anywhere.
- Destination line 12 `fg` with shadow, max width 260. It is single-line by nature: if it does not fit, shorten the content (drop the zone, keep the place: "Vol vers Brackenwall Village") and put the full route in the tooltip. Never let the engine cut it.
- Step line 11 `muted` with shadow ("puis Tabetha" / "then Tabetha"). NPC and player names keep their capital letter.
- Distance 13 `fg` with shadow, unit 11 muted ("120 m").

---

## 4. Text rules

### 4.1 Wrap or tooltip

- Default for every FontString created by the addon helpers (`ns.Text`, `S.Text`): explicit width, `SetWordWrap(true)`, `SetMaxLines(2)`, justify LEFT, the parent's height computed from `GetStringHeight()` after the width is set.
- `SetWordWrap(false)` is allowed only for: tab labels, pills and counters, window title and subtitle, the GPS destination line, number columns. Each of those uses `ns.ClampLabel(fs, fullText)`, which detects truncation (`fs:IsTruncated()`, or `GetStringWidth() > GetWidth() + 0.5` when IsTruncated is missing; both guarded with `issecretvalue`) and puts the full text in the owner's tooltip.
- `ns.SetChip`'s maxW truncation is removed. If a 2-line text would need a third line, the third line goes in the tooltip and the visible text is rewritten shorter, not cut.
- Strings never contain the "…" glyph: write "..." when an ellipsis is part of the copy (rare).

### 4.2 Maximum widths

| Text | Max width |
|---|---|
| Body paragraph in a window | content width (window - 32), never more than 480 |
| Empty-state sentence | 320 |
| Tooltip | 260 |
| Toast | 300 |
| GPS destination | 260 |
| Button label | 22 characters by design; the button grows, it never cuts |
| Settings description | row width - control column |

### 4.3 Numbers, plurals and dates

- Branch on n == 1 in both languages: "1 inscrit" / "2 inscrits", "1 sign-up" / "2 sign-ups". Never "(s)", never "quest(s)".
- French: space before ":", "?" and "!" (ordinary space, the font has no narrow one); 24 h time "21:00"; decimal comma "1,5"; thousands with a space "12 500".
- English: no space before ":"; 12 h time "9:00 PM"; "1.5"; "12,500".
- Money: `|T` coin textures at font size, gold first, zero parts omitted.
- Relative time: "à l'instant", "il y a 3 min", "il y a 2 h", "hier" / "just now", "3 min ago", "2 h ago", "yesterday".

---

## 5. Microcopy

### 5.1 Voice

- French: tu, warm and direct, short sentences, no jargon a new guildmate would not know. English: you, sentence case, plain words. Never Title Case On Every Word.
- Write the French sentence first, in its place on screen; then write the English sentence as a native would, not word by word. Check both fit the same width (French runs 15-20 % longer).
- Every user-facing string exists in French and English (`L.KEY` in Locale.lua for the guide; `L("...")` with `ns.AddEnglish` in Writs files). `writ/l10n_check.py` must report 0 missing.
- Never name another addon in user copy (TOC Notes included).

### 5.2 Buttons

- Verb + object, French infinitive, English imperative: "Inviter les inscrits" / "Invite sign-ups", "Publier l'événement" / "Publish event", "Scanner l'HV" / "Scan the AH", "Ajouter 3 donjons" / "Add 3 dungeons".
- Banned alone: "OK", "Valider", "Choisir", "Pick", "Rescanner". Counts go inside the label when they change the meaning ("Valider (3)" becomes "Ajouter 3 donjons").
- 22 characters by design.

### 5.3 Titles, sentences, empty states

- Titles state the thing or the fact, no final period: "Aucune commande ouverte" / "No open orders".
- Sentences end with a period. One idea each.
- A view's title, sentence and button must not repeat each other. Read them in order out loud.
- Anti-pattern (to remove everywhere): "No event planned. Create the first one in the Create tab." above a "Create an event" button.

### 5.4 Chat messages

- Prefix the addon tag once: "|cffCE1918WL|r ", then one complete sentence with subject and verb, then what to do next with a verb: "Nouvel événement : Zul'Farrak, demain 21:00 (par Alandir). Tape /wlh events pour t'inscrire." / "New event: Zul'Farrak, tomorrow 9:00 PM (by Alandir). Type /wlh events to sign up."
- Never a bare slash command at the end of a line.
- Errors say what went wrong and how to fix it.
- Repeats are rate-limited (same message at most once per 30 s). The addon never whispers.

### 5.5 Status words

| Concept | Français | English |
|---|---|---|
| quest/writ not picked up | À prendre | To take |
| in the quest log | En cours | In progress |
| item in bags | Dans le sac | In bags |
| ready to hand in | Prête à rendre | Ready to turn in |
| handed in | Rendue | Turned in |
| signed up | Inscrit | Signed up |
| reserve | En réserve | Reserve |
| order open / taken / delivered | Ouverte / Prise / Livrée | Open / Taken / Delivered |

---

## 6. Glossary

One word per concept, everywhere: tab names, card titles, buttons, tooltips, chat. Kept in sync with the glossary block at the top of Locale.lua.

| Français | English | Meaning / rule |
|---|---|---|
| WL Helper | WL Helper | the addon's name, never translated |
| WaR LegenD | WaR LegenD | the guild, exact capitalisation |
| Accueil | Home | the hub window and the home button |
| Guide de quêtes | Quest guide | the dungeon-quest guide (UI.lua); "le guide" in running text |
| Donjon | Dungeon | |
| Choisir les donjons | Pick dungeons | the Picker; the button says what it adds ("Ajouter 3 donjons") |
| Quête de donjon | Dungeon quest | |
| GPS | GPS | the arrow guidance; "Guider vers ..." / "Guide me to ..." |
| Épingler / Désépingler | Pin / Unpin | uses the pin icon |
| Événement | Event | any planned guild outing; not "sortie", "raid night", "outing" in UI labels |
| Groupe | Group | a party formed for an event or LFG; an event creates a group |
| Agenda | Upcoming | the list of events |
| Créer un événement | Create an event | |
| S'inscrire / Inscrit / Inscrits | Sign up / Signed up / Sign-ups | |
| Organisateur | Organizer | |
| Places | Slots | per role: Tank, Soigneur / Healer, DPS |
| Commande | Order | a guildmate asks for a craft |
| Demande | Request | the content of an order from the asker's side |
| Artisan | Crafter | the player who can craft it |
| Comptoir | Trading post | the Writs module window |
| Writ | Writ | the merchant contract item; same word in both languages, capital W |
| Faveur du marchand | Merchant's Favor | the reputation/currency earned by writs; "Faveur" alone after first mention |
| Caisse | Crate | writ reward container |
| HV (Hôtel des ventes) | AH (Auction House) | |
| Sacs | Bags | the bag cleaner |
| Réglages | Settings | the options page; command words "options", "settings" |
| Guilde | Guild | |
| PvP / Victoires honorables | PvP / Honorable kills | |
| Idée / Bug | Idea / Bug | the feedback command |
| Suivi du guide | Guide tracker | the small window with the current action and the next two; "le suivi" / "the tracker" in running text; `/wlh tracker` (or `/wlh suivi`) |
| Vue d'ensemble | Overview | one dungeon's page: picture, entrance, key, its quests in three parts |
| Boss et rares | Bosses and rares | the panel of a dungeon's bosses and rare mobs, with "Cibler et marquer" / "Target and mark" |
| Actif | On | a step row's GPS button while the GPS leads there; never "Suivi", which is the tracker |

---

## 7. Debug command: `/wlh textes`

Purpose: list every truncated FontString in the WL Helper frames that are shown right now, so cut text is found in game instead of in screenshots.

### 7.1 Command

- Words: `textes`, `texts`, `truncated` (all route to `ns.DebugTexts()`). Accents are already stripped by the slash handler. Listed in `/wlh help` under a "Debug" line in both languages.
- Optional argument `all`: also report strings that wrap to their max lines exactly (near misses), marked "(limite)" / "(at limit)".

### 7.2 Which frames

1. Roots: every frame in the addon's window registry (`ns.windows`, filled by `ns.Window` / `S.Window` on creation), plus the GPS HUD, the minimap button, the Home window, the Picker and the guide frame (`ns.frame`).
2. Fallback for frames created outside the registry: `EnumerateFrames()` over all frames, keep those whose name starts with `WL` or `WLDT`, or that have the field `wlOwned = true` set by the helpers, and whose parent is not already a kept frame.
3. Only roots with `IsVisible()` true. Hidden roots are skipped (they print one summary line count only with `all`).

### 7.3 Walk

- Depth-first over `GetChildren()` and `GetRegions()`, max depth 25, skipping hidden children (`IsShown()` false) and forbidden frames (`IsForbidden` true, guarded with pcall).
- For each region with `GetObjectType() == "FontString"`:
  - `local ok, cut = pcall(fs.IsTruncated, fs)`; if the method is missing or fails, fallback: not word-wrapped and `GetStringWidth() > GetWidth() + 0.5`.
  - Guard every value read (`GetText`, `GetStringWidth`, `GetWidth`, `IsTruncated` result) with `issecretvalue` when it exists: a secret value counts as "unknown" and the string is skipped.
  - Report when `cut == true`.
- Each report line: window title (the root's `titleText:GetText()`, else its name, else "?"), the path of keys from the root (`f.tabs[2].label`, built from the parent's fields that point at the child when found, else `ObjectType#index`), the font size, width x height, max lines, and the text (first 80 characters with "..." appended in the report only, colour codes stripped).

### 7.4 Output

- Header line: "|cffCE1918WL|r Textes coupés : 3 dans 2 fenêtres." / "|cffCE1918WL|r Truncated texts: 3 in 2 windows." (singular forms for 1).
- Then one line per hit, grouped by window: `[Comptoir] rows[4].name 12px 220x15 (1 ligne) : Enveloppe · potion de protection contre l'ombre` / `[Trading post] rows[4].name 12px 220x15 (1 line): ...`.
- At most 40 lines, then one closing line: "Et 12 autres : ferme quelques fenêtres puis relance /wlh textes." / "And 12 more: close a few windows, then run /wlh texts again." The full list is always in `WLDTDB.debugTexts`.
- No hit: "|cffCE1918WL|r Aucun texte coupé dans les fenêtres ouvertes." / "|cffCE1918WL|r No truncated text in the open windows."
- Also stores the last result in `WLDTDB.debugTexts = { time = time(), lines = {...} }` so it can be read from the SavedVariables file offline.
- Never runs automatically; cost is one walk on demand, no OnUpdate.

### 7.5 Reference shape (to implement in Main.lua or a new Debug.lua)

```lua
local function secret(v) return issecretvalue and issecretvalue(v) end

local function isCut(fs)
  if fs.IsTruncated then
    local ok, cut = pcall(fs.IsTruncated, fs)
    if ok and not secret(cut) then return cut == true end
  end
  if fs.CanWordWrap and fs:CanWordWrap() then return false end
  local sw, w = fs:GetStringWidth(), fs:GetWidth()
  if secret(sw) or secret(w) then return false end
  return w > 0 and sw > w + 0.5
end

local function walk(frame, root, path, depth, out)
  if depth > 25 or not frame:IsShown() then return end
  for i, r in ipairs({ frame:GetRegions() }) do
    if r:GetObjectType() == "FontString" and r:IsShown() and isCut(r) then
      out[#out + 1] = { root = root, path = path .. "." .. (ns.KeyOf(frame, r) or ("FontString#" .. i)), fs = r }
    end
  end
  for i, c in ipairs({ frame:GetChildren() }) do
    local okF, forbidden = pcall(c.IsForbidden, c)
    if not (okF and forbidden) then
      walk(c, root, path .. "." .. (ns.KeyOf(frame, c) or (c:GetObjectType() .. "#" .. i)), depth + 1, out)
    end
  end
end
```

`ns.KeyOf(parent, child)` scans the parent's table fields (and one level into array fields such as `rows`) for the child and returns `"name"` or `"rows[4]"`.

### 7.6 Definition of done for the text pass

`/wlh textes` reports 0 lines with every module window open in frFR and enUS, at UI scale 0.64 and 1.0, with the longest real data (long item names, long NPC names, a full event).

---

## 8. Checklist before shipping a view

- [ ] One primary button at most; destructive actions are two-step and never primary.
- [ ] No side stripe, no solid red block for selection, no gradient card.
- [ ] Every glyph is an HD icon; every painted icon is cropped 0.08-0.92 and at most 48 px.
- [ ] Only the type sizes of 1.2; no shadow on panel text.
- [ ] All gaps from the spacing scale; one left edge, one right edge.
- [ ] `FitHeight` called after render; no window much taller than its content; footer sticks to content.
- [ ] Empty, loading/unknown, normal and overflow states designed.
- [ ] `/wlh textes` reports nothing in frFR and enUS.
- [ ] Every icon-only or verb-less clickable has a tooltip ending with "Clic : ..." / "Click: ...".
- [ ] Every string exists in French and English; plurals branch on n == 1; no "(s)", no "…".
- [ ] Glossary words used; NPC and player names capitalised.
- [ ] Events registered through pcall; secret values guarded; secure buttons untouched in combat.
- [ ] Tests: luatest10 (failures: 0), luatest12_guide frFR and enUS (no FAIL), luatest11_run frFR, l10n_check (0 missing).
