--[[
╔══════════════════════════════════════════════════════════════════════════════╗
║                              VoidUI  v3.0                                    ║
║                    Modern Roblox Executor UI Library                         ║
║                                                                              ║
║  Style  : Violet/Rose, glassmorphism, gradients, animations fluides          ║
║  Auteur : VoidUI                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝

USAGE :
    local VoidUI = loadstring(game:HttpGet("VOTRE_URL_RAW"))()

    local Win = VoidUI:CreateWindow({
        Title = "Mon Script",
        Size  = UDim2.new(0, 580, 0, 440),
    })

    local Tab = Win:AddTab("Main")

    -- Grille de cards (pour les oeufs, items visuels)
    Tab:AddCardGrid({
        Items    = { { Name = "EpicEgg", Icon = "rbxassetid://123" } },
        Columns  = 3,
        Callback = function(selected) print(selected) end,
    })

    -- Composants classiques
    Tab:AddToggle    ({ Label = "Auto Farm",  Default = false,            Callback = function(v) end })
    Tab:AddSlider    ({ Label = "Speed",      Min = 0, Max = 100, Default = 16, Callback = function(v) end })
    Tab:AddButton    ({ Label = "Teleport",   Callback = function() end })
    Tab:AddDropdown  ({ Label = "Mode",       Options = {"Fast","Safe"},  Callback = function(v) end })
    Tab:AddTextInput ({ Label = "Name",       Placeholder = "...",        Callback = function(v) end })
    Tab:AddKeybind   ({ Label = "Toggle UI",  Default = Enum.KeyCode.F,   Callback = function(k) end })
    Tab:AddColorPicker({ Label = "Couleur",   Default = Color3.new(1,0,1),Callback = function(c) end })
    Tab:AddProgressBar({ Label = "XP",        Value = 50, Max = 100 })
    Tab:AddMultiToggle({ Label = "Options",   Options = {"A","B","C"},    Callback = function(t) end })
    Tab:AddLabel("Section : Misc")

    -- Notifications (appelées depuis n'importe où)
    VoidUI:Notify({
        Title    = "Chargé !",
        Message  = "Le script est actif.",
        Type     = "success",   -- "info" | "success" | "warning" | "error"
        Duration = 3,
    })
]]

-- ════════════════════════════════════════════════════════════════════════════
--  SERVICES
-- ════════════════════════════════════════════════════════════════════════════
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players          = game:GetService("Players")

-- ════════════════════════════════════════════════════════════════════════════
--  PALETTE DE COULEURS
--  Violet chaud + rose, loin du bleu générique habituel
-- ════════════════════════════════════════════════════════════════════════════
local C = {
    -- Fonds (du plus sombre au plus clair)
    BgDeep      = Color3.fromRGB(8,   8,  12),
    BgMid       = Color3.fromRGB(14,  14, 20),
    BgLight     = Color3.fromRGB(22,  22, 32),
    BgLighter   = Color3.fromRGB(30,  28, 45),

    -- Accents principaux
    Accent      = Color3.fromRGB(130, 80,  255),   -- violet vif
    AccentSoft  = Color3.fromRGB(100, 60,  200),   -- violet foncé (pressed)
    AccentPink  = Color3.fromRGB(220, 80,  160),   -- rose (dégradé secondaire)
    AccentGlow  = Color3.fromRGB(160, 110, 255),   -- violet clair (hover glow)

    -- Textes
    TextBright  = Color3.fromRGB(240, 238, 255),   -- blanc teinté violet
    TextMid     = Color3.fromRGB(160, 155, 190),   -- gris violet
    TextDim     = Color3.fromRGB(85,  82,  115),   -- très atténué

    -- Bordures
    BorderDim   = Color3.fromRGB(35,  32,  58),    -- bordure normale
    BorderGlow  = Color3.fromRGB(130, 80,  255),   -- bordure active/sélectionnée

    -- États
    Success     = Color3.fromRGB(55,  210, 120),
    Warning     = Color3.fromRGB(255, 185, 40),
    Error       = Color3.fromRGB(230, 55,  75),
    Info        = Color3.fromRGB(60,  155, 255),

    -- Utilitaires
    White       = Color3.fromRGB(255, 255, 255),
    Black       = Color3.fromRGB(0,   0,   0),
}

-- ════════════════════════════════════════════════════════════════════════════
--  HELPERS — fonctions réutilisables pour créer les instances UI
-- ════════════════════════════════════════════════════════════════════════════

-- Tween simplifié avec valeurs par défaut sensées
local function Tween(obj, props, duration, style, direction)
    duration  = duration  or 0.15
    style     = style     or Enum.EasingStyle.Quint
    direction = direction or Enum.EasingDirection.Out
    TweenService:Create(obj, TweenInfo.new(duration, style, direction), props):Play()
end

-- UICorner rapide
local function Corner(radius, parent)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 6)
    c.Parent = parent
    return c
end

-- UIStroke rapide
local function Stroke(thickness, color, parent, transparency)
    local s = Instance.new("UIStroke")
    s.Thickness       = thickness    or 1
    s.Color           = color        or C.BorderDim
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Transparency    = transparency or 0
    s.Parent          = parent
    return s
end

-- UIPadding rapide
local function Pad(top, bottom, left, right, parent)
    local p = Instance.new("UIPadding")
    p.PaddingTop    = UDim.new(0, top    or 0)
    p.PaddingBottom = UDim.new(0, bottom or 0)
    p.PaddingLeft   = UDim.new(0, left   or 0)
    p.PaddingRight  = UDim.new(0, right  or 0)
    p.Parent = parent
    return p
end

-- UIGradient horizontal ou vertical entre deux couleurs
local function Gradient(color0, color1, parent, rotation)
    local g = Instance.new("UIGradient")
    g.Color    = ColorSequence.new(color0, color1)
    g.Rotation = rotation or 0
    g.Parent   = parent
    return g
end

-- Frame basique
local function MakeFrame(parent, size, position, bgColor, bgTransparency)
    local f = Instance.new("Frame")
    f.Size                   = size             or UDim2.new(1, 0, 1, 0)
    f.Position               = position         or UDim2.new(0, 0, 0, 0)
    f.BackgroundColor3       = bgColor          or C.BgMid
    f.BackgroundTransparency = bgTransparency   or 0
    f.BorderSizePixel        = 0
    f.Parent                 = parent
    return f
end

-- TextLabel basique
local function MakeLabel(parent, text, size, position, textColor, textSize, font, xAlign)
    local l = Instance.new("TextLabel")
    l.Size                   = size      or UDim2.new(1, 0, 1, 0)
    l.Position               = position  or UDim2.new(0, 0, 0, 0)
    l.BackgroundTransparency = 1
    l.Text                   = text      or ""
    l.TextColor3             = textColor or C.TextBright
    l.TextSize               = textSize  or 13
    l.Font                   = font      or Enum.Font.GothamBold
    l.TextXAlignment         = xAlign    or Enum.TextXAlignment.Left
    l.BorderSizePixel        = 0
    l.Parent                 = parent
    return l
end

-- Rend un frame déplaçable en le saisissant via une poignée (handle)
local function MakeDraggable(handle, frame)
    local dragging = false
    local dragStart, startPos

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging  = true
            dragStart = input.Position
            startPos  = frame.Position
        end
    end)

    handle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- Crée la petite barre déco gauche avec gradient violet->rose
-- (présente sur presque tous les composants)
local function MakeAccentBar(parent)
    local bar = MakeFrame(parent,
        UDim2.new(0, 3, 0.55, 0),
        UDim2.new(0, 0, 0.225, 0),
        C.White, 0
    )
    Corner(2, bar)
    Gradient(C.Accent, C.AccentPink, bar, 90)
    return bar
end

-- ════════════════════════════════════════════════════════════════════════════
--  MODULE PRINCIPAL
-- ════════════════════════════════════════════════════════════════════════════
local VoidUI = {}
VoidUI.__index = VoidUI

-- ════════════════════════════════════════════════════════════════════════════
--  SYSTÈME DE NOTIFICATIONS
--  Toast qui apparaît en bas à droite avec barre de progression temporelle
-- ════════════════════════════════════════════════════════════════════════════
do
    local notifGui = Instance.new("ScreenGui")
    notifGui.Name           = "VoidUI_Notifs"
    notifGui.ResetOnSpawn   = false
    notifGui.DisplayOrder   = 9999
    notifGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    -- Essaie CoreGui d'abord (executor), fallback PlayerGui
    local ok = pcall(function() notifGui.Parent = game:GetService("CoreGui") end)
    if not ok then
        notifGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    end

    -- Conteneur fixe en bas à droite
    local container = MakeFrame(notifGui,
        UDim2.new(0, 300, 1, 0),
        UDim2.new(1, -310, 0, 0),
        C.Black, 1
    )

    local containerLayout = Instance.new("UIListLayout")
    containerLayout.SortOrder        = Enum.SortOrder.LayoutOrder
    containerLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    containerLayout.Padding          = UDim.new(0, 8)
    containerLayout.Parent           = container
    Pad(0, 16, 0, 0, container)

    local notifCount = 0

    function VoidUI:Notify(cfg)
        cfg = cfg or {}
        local title    = cfg.Title    or "VoidUI"
        local message  = cfg.Message  or ""
        local duration = cfg.Duration or 3
        local ntype    = cfg.Type     or "info"

        -- Couleur d'accent selon le type de notification
        local accent = C.Info
        if     ntype == "success" then accent = C.Success
        elseif ntype == "warning" then accent = C.Warning
        elseif ntype == "error"   then accent = C.Error
        end

        notifCount = notifCount + 1

        -- Carte de notification principale
        local notif = MakeFrame(container,
            UDim2.new(1, 0, 0, 72),
            nil,
            C.BgMid, 0
        )
        notif.ClipsDescendants = true
        notif.LayoutOrder      = notifCount
        Corner(10, notif)
        Stroke(1, accent, notif)

        -- Barre colorée verticale à gauche (indicateur de type)
        local leftBar = MakeFrame(notif,
            UDim2.new(0, 3, 1, 0),
            UDim2.new(0, 0, 0, 0),
            accent, 0
        )
        Corner(3, leftBar)

        -- Titre
        local titleLabel = MakeLabel(notif, title,
            UDim2.new(1, -20, 0, 22),
            UDim2.new(0, 14, 0, 8),
            C.TextBright, 13, Enum.Font.GothamBold
        )

        -- Message (peut être multilignes)
        local msgLabel = MakeLabel(notif, message,
            UDim2.new(1, -20, 0, 30),
            UDim2.new(0, 14, 0, 30),
            C.TextMid, 11, Enum.Font.Gotham
        )
        msgLabel.TextWrapped = true

        -- Barre de progression en bas qui rétrécit avec le temps
        local progressBg = MakeFrame(notif,
            UDim2.new(1, -16, 0, 2),
            UDim2.new(0, 8, 1, -5),
            C.BgLight, 0
        )
        Corner(2, progressBg)

        local progressFill = MakeFrame(progressBg,
            UDim2.new(1, 0, 1, 0),
            nil, accent, 0
        )
        Corner(2, progressFill)

        -- Animation d'entrée : slide depuis la droite
        notif.Position               = UDim2.new(1, 20, 0, 0)
        notif.BackgroundTransparency = 1

        Tween(notif, {
            BackgroundTransparency = 0,
            Position = UDim2.new(0, 0, 0, 0),
        }, 0.3, Enum.EasingStyle.Back)

        -- Rétrécissement de la barre de progression
        Tween(progressFill,
            { Size = UDim2.new(0, 0, 1, 0) },
            duration, Enum.EasingStyle.Linear
        )

        -- Sortie après la durée
        task.delay(duration, function()
            Tween(notif, {
                BackgroundTransparency = 1,
                Position = UDim2.new(1, 20, 0, 0),
            }, 0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
            task.wait(0.3)
            notif:Destroy()
        end)
    end
end

-- ════════════════════════════════════════════════════════════════════════════
--  CRÉER UNE FENÊTRE
-- ════════════════════════════════════════════════════════════════════════════
function VoidUI:CreateWindow(cfg)
    cfg = cfg or {}
    local title = cfg.Title or "VoidUI"
    local size  = cfg.Size  or UDim2.new(0, 580, 0, 440)

    -- ScreenGui
    local sg = Instance.new("ScreenGui")
    sg.Name           = "VoidUI_" .. title
    sg.ResetOnSpawn   = false
    sg.DisplayOrder   = 999
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local ok = pcall(function() sg.Parent = game:GetService("CoreGui") end)
    if not ok then
        sg.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    end

    -- (shadow supprimée car elle ne suivait pas la fenêtre au drag)

    -- ── Fenêtre principale ──
    local main = MakeFrame(sg,
        size,
        UDim2.new(0.5, -size.X.Offset/2, 0.5, -size.Y.Offset/2),
        C.BgDeep, 0
    )
    main.ClipsDescendants = false
    -- Shadow DANS main pour suivre le drag
    local shadow = MakeFrame(main, UDim2.new(1,22,1,22), UDim2.new(0,-11,0,-11), C.Black, 0.45)
    shadow.ZIndex = -1
    Corner(14, shadow)
    Corner(12, main)
    Stroke(1, C.BorderDim, main)

    -- Ligne gradient décorative tout en haut (violet → rose, 2px)
    local topLine = MakeFrame(main,
        UDim2.new(1, 0, 0, 2),
        UDim2.new(0, 0, 0, 0),
        C.White, 0
    )
    Gradient(C.Accent, C.AccentPink, topLine, 0)

    -- ── Barre de titre ──
    local titleBar = MakeFrame(main,
        UDim2.new(1, 0, 0, 40),
        UDim2.new(0, 0, 0, 2),
        C.BgDeep, 0
    )

    -- Titre
    MakeLabel(titleBar, title,
        UDim2.new(1, -120, 1, 0),
        UDim2.new(0, 14, 0, 0),
        C.TextBright, 14, Enum.Font.GothamBold
    )

    -- Version (petit, discret)
    MakeLabel(titleBar, "v3.0",
        UDim2.new(0, 35, 1, 0),
        UDim2.new(0, 14, 0, 0),
        C.Accent, 10, Enum.Font.Gotham
    )

    -- Bouton Fermer (×)
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size             = UDim2.new(0, 24, 0, 24)
    closeBtn.Position         = UDim2.new(1, -32, 0.5, -12)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 70)
    closeBtn.Text             = "×"
    closeBtn.TextColor3       = C.White
    closeBtn.TextSize         = 16
    closeBtn.Font             = Enum.Font.GothamBold
    closeBtn.BorderSizePixel  = 0
    closeBtn.Parent           = titleBar
    Corner(6, closeBtn)

    closeBtn.MouseEnter:Connect(function()
        Tween(closeBtn, { BackgroundColor3 = Color3.fromRGB(235, 70, 90) }, 0.1)
    end)
    closeBtn.MouseLeave:Connect(function()
        Tween(closeBtn, { BackgroundColor3 = Color3.fromRGB(200, 50, 70) }, 0.1)
    end)
    closeBtn.MouseButton1Click:Connect(function()
        Tween(main, { Size = UDim2.new(0, size.X.Offset, 0, 0), BackgroundTransparency = 1 }, 0.2)
        task.wait(0.25)
        sg:Destroy()
    end)

    -- Bouton Minimiser (—)
    local minBtn = Instance.new("TextButton")
    minBtn.Size             = UDim2.new(0, 24, 0, 24)
    minBtn.Position         = UDim2.new(1, -60, 0.5, -12)
    minBtn.BackgroundColor3 = C.BgLight
    minBtn.Text             = "—"
    minBtn.TextColor3       = C.TextMid
    minBtn.TextSize         = 13
    minBtn.Font             = Enum.Font.GothamBold
    minBtn.BorderSizePixel  = 0
    minBtn.Parent           = titleBar
    Corner(6, minBtn)
    Stroke(1, C.BorderDim, minBtn)

    minBtn.MouseEnter:Connect(function()
        Tween(minBtn, { BackgroundColor3 = C.Accent, TextColor3 = C.White }, 0.1)
    end)
    minBtn.MouseLeave:Connect(function()
        Tween(minBtn, { BackgroundColor3 = C.BgLight, TextColor3 = C.TextMid }, 0.1)
    end)

    -- Séparateur dégradé sous le titre
    local titleSep = MakeFrame(main,
        UDim2.new(1, 0, 0, 1),
        UDim2.new(0, 0, 0, 42),
        C.White, 0
    )
    Gradient(C.Accent, C.AccentPink, titleSep, 0)

    -- Le titre est la zone de drag
    MakeDraggable(titleBar, main)

    -- ── Pill (fenêtre réduite / minimisée) ──
    local pill = Instance.new("TextButton")
    pill.Size             = UDim2.new(0, 145, 0, 36)
    pill.Position         = UDim2.new(0, 16, 1, -54)
    pill.BackgroundColor3 = C.BgMid
    pill.BorderSizePixel  = 0
    pill.Text             = ""
    pill.Visible          = false
    pill.ZIndex           = 100
    pill.Parent           = sg
    Corner(18, pill)
    Stroke(1, C.Accent, pill)

    -- Point pulsant dans la pill
    local pillDot = MakeFrame(pill,
        UDim2.new(0, 7, 0, 7),
        UDim2.new(0, 11, 0.5, -3),
        C.Accent, 0
    )
    pillDot.ZIndex = 101
    Corner(4, pillDot)

    -- Titre dans la pill
    local pillLabel = MakeLabel(pill, title,
        UDim2.new(1, -44, 1, 0),
        UDim2.new(0, 25, 0, 0),
        C.TextBright, 12, Enum.Font.GothamBold
    )
    pillLabel.ZIndex = 101

    -- Icône expand (↗)
    local pillArrow = MakeLabel(pill, "↗",
        UDim2.new(0, 20, 1, 0),
        UDim2.new(1, -24, 0, 0),
        C.Accent, 13, Enum.Font.GothamBold,
        Enum.TextXAlignment.Center
    )
    pillArrow.ZIndex = 101

    -- La pill est aussi draggable
    MakeDraggable(pill, pill)

    -- Hover sur la pill
    pill.MouseEnter:Connect(function()
        Tween(pill, { BackgroundColor3 = C.BgLighter }, 0.1)
    end)
    pill.MouseLeave:Connect(function()
        Tween(pill, { BackgroundColor3 = C.BgMid }, 0.1)
    end)

    -- Animation pulsante du point dans la pill (quand visible)
    coroutine.wrap(function()
        while true do
            if pill.Visible then
                Tween(pillDot, { BackgroundTransparency = 0.1 }, 0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
                task.wait(0.8)
                Tween(pillDot, { BackgroundTransparency = 0.8 }, 0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
                task.wait(0.8)
            else
                task.wait(0.3)
            end
        end
    end)()

    -- État minimisation
    local minimized = false
    local savedPos  = main.Position

    -- Minimiser : fenêtre -> pill
    minBtn.MouseButton1Click:Connect(function()
        if minimized then return end
        minimized = true
        savedPos  = main.Position

        Tween(main, {
            Size = UDim2.new(0, size.X.Offset, 0, 0),
            BackgroundTransparency = 1,
        }, 0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.In)

        task.wait(0.22)
        main.Visible             = false
        main.Size                = size
        main.BackgroundTransparency = 0

        -- Pill apparaît avec animation
        pill.Visible = true
        pill.Size    = UDim2.new(0, 0, 0, 36)
        Tween(pill, { Size = UDim2.new(0, 145, 0, 36) }, 0.28, Enum.EasingStyle.Back)
    end)

    -- Restaurer : pill -> fenêtre
    pill.MouseButton1Click:Connect(function()
        if not minimized then return end
        minimized = false

        Tween(pill, { Size = UDim2.new(0, 0, 0, 36) }, 0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        task.wait(0.18)
        pill.Visible = false
        pill.Size    = UDim2.new(0, 145, 0, 36)

        main.Visible = true
        main.Size    = UDim2.new(0, size.X.Offset, 0, 0)
        main.Position = savedPos
        Tween(main, { Size = size }, 0.3, Enum.EasingStyle.Back)
    end)

    -- ── Barre des onglets ──
    local tabBar = MakeFrame(main,
        UDim2.new(1, 0, 0, 34),
        UDim2.new(0, 0, 0, 43),
        C.BgDeep, 0
    )

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.SortOrder     = Enum.SortOrder.LayoutOrder
    tabLayout.Padding       = UDim.new(0, 2)
    tabLayout.Parent        = tabBar
    Pad(4, 4, 8, 8, tabBar)

    -- Séparateur sous la tab bar
    local tabSep = MakeFrame(main,
        UDim2.new(1, 0, 0, 1),
        UDim2.new(0, 0, 0, 77),
        C.BorderDim, 0
    )

    -- ── Zone de contenu (scrolling par onglet) ──
    local contentArea = MakeFrame(main,
        UDim2.new(1, 0, 1, -79),
        UDim2.new(0, 0, 0, 79),
        C.BgDeep, 0
    )
    contentArea.ClipsDescendants = true

    -- Animation d'ouverture de la fenêtre
    main.Size = UDim2.new(0, size.X.Offset, 0, 0)
    Tween(main, { Size = size }, 0.38, Enum.EasingStyle.Back)

    -- ════════════════════════════════════════════════════════════════════════
    --  OBJET FENÊTRE (Window)
    -- ════════════════════════════════════════════════════════════════════════
    local Window = {
        _tabs      = {},
        _activeTab = nil,
        _tabBtns   = {},
        _tabFrames = {},
    }

    -- Active visuellement un onglet et cache les autres
    local function SetActiveTab(name)
        for n, frame in pairs(Window._tabFrames) do
            frame.Visible = (n == name)
        end
        for n, btn in pairs(Window._tabBtns) do
            if n == name then
                Tween(btn, { BackgroundColor3 = C.BgLight }, 0.15)
                btn.TextColor3 = C.TextBright
                local uline = btn:FindFirstChild("Uline")
                if uline then Tween(uline, { BackgroundColor3 = C.Accent }, 0.15) end
            else
                Tween(btn, { BackgroundColor3 = C.BgDeep }, 0.15)
                btn.TextColor3 = C.TextDim
                local uline = btn:FindFirstChild("Uline")
                if uline then Tween(uline, { BackgroundColor3 = C.BgDeep }, 0.15) end
            end
        end
        Window._activeTab = name
    end

    -- ── AJOUTER UN ONGLET ──
    function Window:AddTab(name)
        -- Bouton de l'onglet
        local tabBtn = Instance.new("TextButton")
        tabBtn.Size             = UDim2.new(0, 88, 1, 0)
        tabBtn.BackgroundColor3 = C.BgDeep
        tabBtn.BorderSizePixel  = 0
        tabBtn.Text             = name
        tabBtn.TextColor3       = C.TextDim
        tabBtn.TextSize         = 12
        tabBtn.Font             = Enum.Font.GothamBold
        tabBtn.LayoutOrder      = #Window._tabs + 1
        tabBtn.Parent           = tabBar
        Corner(6, tabBtn)

        -- Soulignement qui s'allume quand actif
        local uline = MakeFrame(tabBtn,
            UDim2.new(0.65, 0, 0, 2),
            UDim2.new(0.175, 0, 1, -2),
            C.BgDeep, 0
        )
        uline.Name = "Uline"
        Corner(2, uline)

        -- Hover sur le bouton d'onglet
        tabBtn.MouseEnter:Connect(function()
            if Window._activeTab ~= name then
                Tween(tabBtn, { BackgroundColor3 = C.BgLight }, 0.1)
            end
        end)
        tabBtn.MouseLeave:Connect(function()
            if Window._activeTab ~= name then
                Tween(tabBtn, { BackgroundColor3 = C.BgDeep }, 0.1)
            end
        end)
        tabBtn.MouseButton1Click:Connect(function()
            SetActiveTab(name)
        end)

        -- ScrollingFrame pour le contenu de cet onglet
        local scrollFrame = Instance.new("ScrollingFrame")
        scrollFrame.Size                 = UDim2.new(1, 0, 1, 0)
        scrollFrame.BackgroundTransparency = 1
        scrollFrame.BorderSizePixel      = 0
        scrollFrame.ScrollBarThickness   = 3
        scrollFrame.ScrollBarImageColor3 = C.Accent
        scrollFrame.CanvasSize           = UDim2.new(0, 0, 0, 0)
        scrollFrame.Visible              = false
        scrollFrame.Parent               = contentArea

        -- Layout vertical avec espacement entre les éléments
        local listLayout = Instance.new("UIListLayout")
        listLayout.SortOrder = Enum.SortOrder.LayoutOrder
        listLayout.Padding   = UDim.new(0, 6)
        listLayout.Parent    = scrollFrame
        Pad(10, 10, 10, 10, scrollFrame)

        -- Redimensionne automatiquement le canvas quand le contenu change
        listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            scrollFrame.CanvasSize = UDim2.new(0, 0, 0,
                listLayout.AbsoluteContentSize.Y + 20
            )
        end)

        Window._tabBtns[name]   = tabBtn
        Window._tabFrames[name] = scrollFrame
        table.insert(Window._tabs, name)

        -- Le premier onglet est actif par défaut
        if #Window._tabs == 1 then
            SetActiveTab(name)
        end

        -- ════════════════════════════════════════════════════════════════════
        --  OBJET ONGLET (Tab)
        --  Contient tous les composants UI
        -- ════════════════════════════════════════════════════════════════════
        local Tab = {
            _frame = scrollFrame,
            _order = 0,
        }

        -- Incrémente le LayoutOrder pour maintenir l'ordre d'insertion
        local function NextOrder()
            Tab._order = Tab._order + 1
            return Tab._order
        end

        -- Crée un wrapper transparent dans la liste (hauteur configurable)
        local function MakeItem(height)
            local f = MakeFrame(scrollFrame,
                UDim2.new(1, 0, 0, height or 34),
                nil, C.Black, 1
            )
            f.LayoutOrder = NextOrder()
            return f
        end

        -- Refresh du canvas (à appeler après les composants dépliables)
        local function RefreshCanvas()
            task.defer(function()
                scrollFrame.CanvasSize = UDim2.new(0, 0, 0,
                    listLayout.AbsoluteContentSize.Y + 20
                )
            end)
        end

        -- ── LABEL / SECTION ──────────────────────────────────────────────
        function Tab:AddLabel(text)
            local it = MakeItem(22)
            it.BackgroundTransparency = 1

            -- Ligne dégradée en fond
            local line = MakeFrame(it,
                UDim2.new(1, 0, 0, 1),
                UDim2.new(0, 0, 0.5, 0),
                C.White, 0
            )
            Gradient(C.Accent, C.AccentPink, line, 0)

            -- Badge texte centré sur la ligne
            local badge = MakeFrame(it,
                UDim2.new(0, 0, 1, 0),
                UDim2.new(0, 0, 0, 0),
                C.BgDeep, 0
            )
            badge.AutomaticSize = Enum.AutomaticSize.X
            Pad(0, 0, 6, 6, badge)

            local lbl = MakeLabel(badge, text,
                UDim2.new(0, 0, 1, 0), nil,
                C.Accent, 11, Enum.Font.GothamBold
            )
            lbl.AutomaticSize = Enum.AutomaticSize.X

            return {
                SetText = function(_, v) lbl.Text = v end,
                GetText = function() return lbl.Text end,
            }
        end

        -- ── BOUTON ───────────────────────────────────────────────────────
        function Tab:AddButton(cfg)
            cfg = cfg or {}
            local it = MakeItem(34)

            local btn = Instance.new("TextButton")
            btn.Size             = UDim2.new(1, 0, 1, 0)
            btn.BackgroundColor3 = C.BgLight
            btn.BorderSizePixel  = 0
            btn.Text             = cfg.Label or "Button"
            btn.TextColor3       = C.TextBright
            btn.TextSize         = 13
            btn.Font             = Enum.Font.GothamBold
            btn.Parent           = it
            Corner(8, btn)
            Stroke(1, C.BorderDim, btn)
            MakeAccentBar(btn)

            -- Overlay gradient violet/rose très subtil
            local grad = Instance.new("UIGradient")
            grad.Color    = ColorSequence.new(C.Accent, C.AccentPink)
            grad.Rotation = 0
            grad.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.87),
                NumberSequenceKeypoint.new(1, 0.87),
            })
            grad.Parent = btn

            local function SetGradAlpha(alpha)
                grad.Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, alpha),
                    NumberSequenceKeypoint.new(1, alpha),
                })
            end

            btn.MouseEnter:Connect(function()
                Tween(btn, { BackgroundColor3 = C.AccentSoft }, 0.12)
                SetGradAlpha(0.65)
            end)
            btn.MouseLeave:Connect(function()
                Tween(btn, { BackgroundColor3 = C.BgLight }, 0.12)
                SetGradAlpha(0.87)
            end)
            btn.MouseButton1Down:Connect(function()
                Tween(btn, { BackgroundColor3 = C.Accent }, 0.08)
                SetGradAlpha(0.5)
            end)
            btn.MouseButton1Up:Connect(function()
                Tween(btn, { BackgroundColor3 = C.BgLight }, 0.12)
                SetGradAlpha(0.87)
            end)
            btn.MouseButton1Click:Connect(function()
                if cfg.Callback then cfg.Callback() end
            end)

            return {
                SetLabel = function(_, v) btn.Text = v end,
            }
        end

        -- ── TOGGLE ───────────────────────────────────────────────────────
        function Tab:AddToggle(cfg)
            cfg = cfg or {}
            local state = cfg.Default or false
            local it    = MakeItem(34)

            local bg = MakeFrame(it, UDim2.new(1, 0, 1, 0), nil, C.BgLight, 0)
            Corner(8, bg)
            Stroke(1, C.BorderDim, bg)
            MakeAccentBar(bg)

            MakeLabel(bg, cfg.Label or "Toggle",
                UDim2.new(1, -70, 1, 0),
                UDim2.new(0, 14, 0, 0),
                C.TextBright, 13, Enum.Font.GothamBold
            )

            -- Pill du toggle
            local pill = MakeFrame(bg,
                UDim2.new(0, 42, 0, 22),
                UDim2.new(1, -50, 0.5, -11),
                state and C.Accent or C.BgDeep, 0
            )
            Corner(11, pill)
            Stroke(1, C.BorderDim, pill)

            -- Knob (boule blanche)
            local knob = MakeFrame(pill,
                UDim2.new(0, 16, 0, 16),
                state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
                C.White, 0
            )
            Corner(8, knob)

            local function UpdateToggle()
                Tween(pill, { BackgroundColor3 = state and C.Accent or C.BgDeep }, 0.2)
                Tween(knob, {
                    Position = state
                        and UDim2.new(1, -18, 0.5, -8)
                        or  UDim2.new(0, 2, 0.5, -8)
                }, 0.2)
                if cfg.Callback then cfg.Callback(state) end
            end

            -- Zone de clic invisible sur tout le composant
            local cz = Instance.new("TextButton")
            cz.Size                 = UDim2.new(1, 0, 1, 0)
            cz.BackgroundTransparency = 1
            cz.Text                 = ""
            cz.Parent               = bg
            cz.MouseButton1Click:Connect(function()
                state = not state
                UpdateToggle()
            end)

            if state and cfg.Callback then cfg.Callback(true) end

            return {
                SetValue = function(_, v) state = v UpdateToggle() end,
                GetValue = function() return state end,
            }
        end

        -- ── SLIDER ───────────────────────────────────────────────────────
        function Tab:AddSlider(cfg)
            cfg = cfg or {}
            local minVal = cfg.Min     or 0
            local maxVal = cfg.Max     or 100
            local curVal = math.clamp(cfg.Default or minVal, minVal, maxVal)
            local suffix = cfg.Suffix  or ""
            local it     = MakeItem(50)

            local bg = MakeFrame(it, UDim2.new(1, 0, 1, 0), nil, C.BgLight, 0)
            Corner(8, bg)
            Stroke(1, C.BorderDim, bg)
            MakeAccentBar(bg)

            MakeLabel(bg, cfg.Label or "Slider",
                UDim2.new(1, -70, 0, 22),
                UDim2.new(0, 14, 0, 4),
                C.TextBright, 13, Enum.Font.GothamBold
            )

            local valLabel = MakeLabel(bg,
                tostring(curVal) .. suffix,
                UDim2.new(0, 55, 0, 22),
                UDim2.new(1, -62, 0, 4),
                C.Accent, 12, Enum.Font.GothamBold,
                Enum.TextXAlignment.Right
            )

            -- Track du slider
            local track = MakeFrame(bg,
                UDim2.new(1, -20, 0, 5),
                UDim2.new(0, 10, 1, -12),
                C.BgDeep, 0
            )
            Corner(3, track)

            -- Remplissage avec gradient violet->rose
            local fill = MakeFrame(track,
                UDim2.new((curVal - minVal) / (maxVal - minVal), 0, 1, 0),
                nil, C.White, 0
            )
            Corner(3, fill)
            Gradient(C.Accent, C.AccentPink, fill, 0)

            -- Poignée ronde
            local handle = MakeFrame(track,
                UDim2.new(0, 14, 0, 14),
                UDim2.new((curVal - minVal) / (maxVal - minVal), 0, 0.5, 0),
                C.White, 0
            )
            handle.AnchorPoint = Vector2.new(0.5, 0.5)
            Corner(7, handle)

            -- Bouton de drag invisible sur le track
            local dragBtn = Instance.new("TextButton")
            dragBtn.Size                 = UDim2.new(1, 0, 0, 26)
            dragBtn.Position             = UDim2.new(0, 0, 0, -10)
            dragBtn.BackgroundTransparency = 1
            dragBtn.Text                 = ""
            dragBtn.Parent               = track

            local sliding = false

            local function UpdateSlider(mouseX)
                local rel = math.clamp(
                    (mouseX - track.AbsolutePosition.X) / track.AbsoluteSize.X,
                    0, 1
                )
                curVal = math.floor(minVal + rel * (maxVal - minVal))
                Tween(fill,   { Size     = UDim2.new(rel, 0, 1, 0)      }, 0.05)
                Tween(handle, { Position = UDim2.new(rel, 0, 0.5, 0)     }, 0.05)
                valLabel.Text = tostring(curVal) .. suffix
                if cfg.Callback then cfg.Callback(curVal) end
            end

            dragBtn.MouseButton1Down:Connect(function()
                sliding = true
                UpdateSlider(UserInputService:GetMouseLocation().X)
            end)
            UserInputService.InputChanged:Connect(function(input)
                if sliding and input.UserInputType == Enum.UserInputType.MouseMovement then
                    UpdateSlider(input.Position.X)
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    sliding = false
                end
            end)

            return {
                SetValue = function(_, v)
                    v = math.clamp(v, minVal, maxVal)
                    curVal = v
                    local rel = (v - minVal) / (maxVal - minVal)
                    fill.Size       = UDim2.new(rel, 0, 1, 0)
                    handle.Position = UDim2.new(rel, 0, 0.5, 0)
                    valLabel.Text   = tostring(v) .. suffix
                    if cfg.Callback then cfg.Callback(v) end
                end,
                GetValue = function() return curVal end,
            }
        end

        -- ── DROPDOWN ─────────────────────────────────────────────────────
        function Tab:AddDropdown(cfg)
            cfg = cfg or {}
            local options  = cfg.Options or {}
            local selected = options[1] or "None"
            local open     = false
            local it       = MakeItem(34)

            -- Wrapper sans clipping pour que la liste dépasse
            local wrap = MakeFrame(it, UDim2.new(1, 0, 0, 34), nil, C.Black, 1)
            wrap.ClipsDescendants = false
            wrap.Parent = it

            local btn = Instance.new("TextButton")
            btn.Size             = UDim2.new(1, 0, 0, 34)
            btn.BackgroundColor3 = C.BgLight
            btn.BorderSizePixel  = 0
            btn.Text             = ""
            btn.Parent           = wrap
            Corner(8, btn)
            Stroke(1, C.BorderDim, btn)
            MakeAccentBar(btn)

            MakeLabel(btn, cfg.Label or "Dropdown",
                UDim2.new(0.5, 0, 1, 0),
                UDim2.new(0, 14, 0, 0),
                C.TextMid, 11, Enum.Font.Gotham
            )

            local selLabel = MakeLabel(btn, selected,
                UDim2.new(0.42, -28, 1, 0),
                UDim2.new(0.5, 0, 0, 0),
                C.TextBright, 12, Enum.Font.GothamBold,
                Enum.TextXAlignment.Right
            )

            local arrow = MakeLabel(btn, "▾",
                UDim2.new(0, 16, 1, 0),
                UDim2.new(1, -20, 0, 0),
                C.Accent, 12, Enum.Font.GothamBold,
                Enum.TextXAlignment.Center
            )

            -- Liste déroulante
            local dropList = MakeFrame(wrap,
                UDim2.new(1, 0, 0, #options * 28),
                UDim2.new(0, 0, 0, 36),
                C.BgMid, 0
            )
            dropList.Visible = false
            dropList.ZIndex  = 20
            Corner(8, dropList)
            Stroke(1, C.Accent, dropList)

            local dropLayout = Instance.new("UIListLayout")
            dropLayout.SortOrder = Enum.SortOrder.LayoutOrder
            dropLayout.Parent    = dropList

            for i, opt in ipairs(options) do
                local optBtn = Instance.new("TextButton")
                optBtn.Size                 = UDim2.new(1, 0, 0, 28)
                optBtn.BackgroundTransparency = 1
                optBtn.BorderSizePixel      = 0
                optBtn.Text                 = opt
                optBtn.TextColor3           = C.TextMid
                optBtn.TextSize             = 12
                optBtn.Font                 = Enum.Font.Gotham
                optBtn.ZIndex               = 21
                optBtn.LayoutOrder          = i
                optBtn.Parent               = dropList

                optBtn.MouseEnter:Connect(function()
                    Tween(optBtn, { TextColor3 = C.TextBright }, 0.1)
                    optBtn.BackgroundColor3       = C.BgLight
                    optBtn.BackgroundTransparency = 0
                end)
                optBtn.MouseLeave:Connect(function()
                    Tween(optBtn, { TextColor3 = C.TextMid }, 0.1)
                    optBtn.BackgroundTransparency = 1
                end)
                optBtn.MouseButton1Click:Connect(function()
                    selected         = opt
                    selLabel.Text    = opt
                    open             = false
                    dropList.Visible = false
                    arrow.Text       = "▾"
                    it.Size          = UDim2.new(1, 0, 0, 34)
                    RefreshCanvas()
                    if cfg.Callback then cfg.Callback(opt) end
                end)
            end

            btn.MouseButton1Click:Connect(function()
                open             = not open
                dropList.Visible = open
                arrow.Text       = open and "▴" or "▾"
                it.Size = open
                    and UDim2.new(1, 0, 0, 34 + #options * 28 + 6)
                    or  UDim2.new(1, 0, 0, 34)
                RefreshCanvas()
            end)

            return {
                SetValue = function(_, v)
                    selected      = v
                    selLabel.Text = v
                    if cfg.Callback then cfg.Callback(v) end
                end,
                GetValue = function() return selected end,
            }
        end

        -- ── TEXT INPUT ───────────────────────────────────────────────────
        function Tab:AddTextInput(cfg)
            cfg = cfg or {}
            local it = MakeItem(34)

            local bg = MakeFrame(it, UDim2.new(1, 0, 1, 0), nil, C.BgLight, 0)
            Corner(8, bg)
            Stroke(1, C.BorderDim, bg)
            MakeAccentBar(bg)

            MakeLabel(bg, cfg.Label or "Input",
                UDim2.new(0, 80, 1, 0),
                UDim2.new(0, 12, 0, 0),
                C.TextMid, 11, Enum.Font.Gotham
            )

            local box = Instance.new("TextBox")
            box.Size                 = UDim2.new(1, -100, 0, 22)
            box.Position             = UDim2.new(0, 94, 0.5, -11)
            box.BackgroundColor3     = C.BgDeep
            box.BorderSizePixel      = 0
            box.Text                 = ""
            box.PlaceholderText      = cfg.Placeholder or "Type here..."
            box.PlaceholderColor3    = C.TextDim
            box.TextColor3           = C.TextBright
            box.TextSize             = 11
            box.Font                 = Enum.Font.Gotham
            box.ClearTextOnFocus     = false
            box.Parent               = bg
            Corner(6, box)
            local boxStroke = Stroke(1, C.BorderDim, box)
            Pad(0, 0, 6, 6, box)

            box.Focused:Connect(function()
                Tween(boxStroke, { Color = C.Accent }, 0.12)
            end)
            box.FocusLost:Connect(function(enter)
                Tween(boxStroke, { Color = C.BorderDim }, 0.12)
                if enter and cfg.Callback then cfg.Callback(box.Text) end
            end)

            return {
                SetValue = function(_, v) box.Text = v end,
                GetValue = function() return box.Text end,
            }
        end

        -- ── KEYBIND ──────────────────────────────────────────────────────
        function Tab:AddKeybind(cfg)
            cfg = cfg or {}
            local currentKey = cfg.Default or Enum.KeyCode.F
            local listening  = false
            local it         = MakeItem(34)

            local bg = MakeFrame(it, UDim2.new(1, 0, 1, 0), nil, C.BgLight, 0)
            Corner(8, bg)
            Stroke(1, C.BorderDim, bg)
            MakeAccentBar(bg)

            MakeLabel(bg, cfg.Label or "Keybind",
                UDim2.new(1, -80, 1, 0),
                UDim2.new(0, 14, 0, 0),
                C.TextBright, 13, Enum.Font.GothamBold
            )

            local keyBtn = Instance.new("TextButton")
            keyBtn.Size             = UDim2.new(0, 68, 0, 24)
            keyBtn.Position         = UDim2.new(1, -76, 0.5, -12)
            keyBtn.BackgroundColor3 = C.BgDeep
            keyBtn.BorderSizePixel  = 0
            keyBtn.Text             = currentKey.Name
            keyBtn.TextColor3       = C.Accent
            keyBtn.TextSize         = 11
            keyBtn.Font             = Enum.Font.GothamBold
            keyBtn.Parent           = bg
            Corner(6, keyBtn)
            Stroke(1, C.Accent, keyBtn)

            -- Clic : entre en mode écoute
            keyBtn.MouseButton1Click:Connect(function()
                listening          = true
                keyBtn.Text        = "..."
                keyBtn.TextColor3  = C.Warning
            end)

            -- Écoute la prochaine touche pressée
            UserInputService.InputBegan:Connect(function(input, gameProcessed)
                if listening and input.UserInputType == Enum.UserInputType.Keyboard then
                    listening         = false
                    currentKey        = input.KeyCode
                    keyBtn.Text       = currentKey.Name
                    keyBtn.TextColor3 = C.Accent
                end
                -- Fire le callback quand la touche est pressée en jeu
                if not listening and not gameProcessed and input.KeyCode == currentKey then
                    if cfg.Callback then cfg.Callback(currentKey) end
                end
            end)

            return {
                GetValue = function() return currentKey end,
            }
        end

        -- ── COLOR PICKER (HSV) ───────────────────────────────────────────
        function Tab:AddColorPicker(cfg)
            cfg = cfg or {}
            local color = cfg.Default or Color3.fromRGB(200, 80, 200)
            local open  = false
            local it    = MakeItem(34)

            local bg = MakeFrame(it, UDim2.new(1, 0, 0, 34), nil, C.BgLight, 0)
            bg.ClipsDescendants = false
            Corner(8, bg)
            Stroke(1, C.BorderDim, bg)
            MakeAccentBar(bg)

            MakeLabel(bg, cfg.Label or "Color",
                UDim2.new(1, -80, 1, 0),
                UDim2.new(0, 14, 0, 0),
                C.TextBright, 13, Enum.Font.GothamBold
            )

            -- Carré de prévisualisation de la couleur
            local swatch = MakeFrame(bg,
                UDim2.new(0, 28, 0, 20),
                UDim2.new(1, -40, 0.5, -10),
                color, 0
            )
            Corner(5, swatch)
            Stroke(1, C.BorderDim, swatch)

            local arrow = MakeLabel(bg, "▾",
                UDim2.new(0, 14, 1, 0),
                UDim2.new(1, -16, 0, 0),
                C.Accent, 11, Enum.Font.GothamBold,
                Enum.TextXAlignment.Center
            )

            -- Panneau HSV dépliable
            local panel = MakeFrame(bg,
                UDim2.new(1, 0, 0, 88),
                UDim2.new(0, 0, 1, 4),
                C.BgMid, 0
            )
            panel.Visible = false
            panel.ZIndex  = 15
            Corner(8, panel)
            Stroke(1, C.Accent, panel)
            Pad(8, 8, 8, 8, panel)

            local panelLayout = Instance.new("UIListLayout")
            panelLayout.Padding   = UDim.new(0, 5)
            panelLayout.Parent    = panel

            local h, s, v = Color3.toHSV(color)
            local hsvValues = { h, s, v }

            -- Crée un slider HSV pour H, S ou V
            local sliderLabels = { "H", "S", "V" }
            local sliderColors = {
                Color3.fromRGB(255, 100, 100),
                Color3.fromRGB(100, 220, 100),
                Color3.fromRGB(120, 160, 255),
            }

            for i = 1, 3 do
                local row = MakeFrame(panel, UDim2.new(1, 0, 0, 18), nil, C.Black, 1)
                row.LayoutOrder = i

                MakeLabel(row, sliderLabels[i],
                    UDim2.new(0, 14, 1, 0), nil,
                    sliderColors[i], 10, Enum.Font.GothamBold,
                    Enum.TextXAlignment.Center
                )

                local track = MakeFrame(row,
                    UDim2.new(1, -52, 0, 4),
                    UDim2.new(0, 18, 0.5, -2),
                    C.BgDeep, 0
                )
                Corner(2, track)

                local fill = MakeFrame(track,
                    UDim2.new(hsvValues[i], 0, 1, 0),
                    nil, C.White, 0
                )
                Corner(2, fill)
                Gradient(sliderColors[i], C.White, fill, 0)

                local valLbl = MakeLabel(row,
                    tostring(math.floor(hsvValues[i] * 255)),
                    UDim2.new(0, 28, 1, 0),
                    UDim2.new(1, -30, 0, 0),
                    C.TextDim, 10, Enum.Font.Gotham,
                    Enum.TextXAlignment.Right
                )

                local dragBtn = Instance.new("TextButton")
                dragBtn.Size                 = UDim2.new(1, 0, 0, 22)
                dragBtn.Position             = UDim2.new(0, 0, 0, -9)
                dragBtn.BackgroundTransparency = 1
                dragBtn.Text                 = ""
                dragBtn.ZIndex               = 16
                dragBtn.Parent               = track

                local sliding = false
                local idx     = i  -- capture de l'index dans la closure

                local function SlideHSV(mouseX)
                    local rel = math.clamp(
                        (mouseX - track.AbsolutePosition.X) / track.AbsoluteSize.X,
                        0, 1
                    )
                    hsvValues[idx] = rel
                    fill.Size      = UDim2.new(rel, 0, 1, 0)
                    valLbl.Text    = tostring(math.floor(rel * 255))
                    color          = Color3.fromHSV(hsvValues[1], hsvValues[2], hsvValues[3])
                    swatch.BackgroundColor3 = color
                    if cfg.Callback then cfg.Callback(color) end
                end

                dragBtn.MouseButton1Down:Connect(function()
                    sliding = true
                    SlideHSV(UserInputService:GetMouseLocation().X)
                end)
                UserInputService.InputChanged:Connect(function(input)
                    if sliding and input.UserInputType == Enum.UserInputType.MouseMovement then
                        SlideHSV(input.Position.X)
                    end
                end)
                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        sliding = false
                    end
                end)
            end

            -- Ouvrir/fermer le panneau au clic
            local clickZone = Instance.new("TextButton")
            clickZone.Size                 = UDim2.new(1, 0, 0, 34)
            clickZone.BackgroundTransparency = 1
            clickZone.Text                 = ""
            clickZone.Parent               = bg

            clickZone.MouseButton1Click:Connect(function()
                open          = not open
                panel.Visible = open
                arrow.Text    = open and "▴" or "▾"
                it.Size = open
                    and UDim2.new(1, 0, 0, 128)
                    or  UDim2.new(1, 0, 0, 34)
                RefreshCanvas()
            end)

            return {
                SetValue = function(_, c)
                    color = c
                    swatch.BackgroundColor3 = c
                    if cfg.Callback then cfg.Callback(c) end
                end,
                GetValue = function() return color end,
            }
        end

        -- ── PROGRESS BAR (non-interactive, mise à jour via SetValue) ─────
        function Tab:AddProgressBar(cfg)
            cfg = cfg or {}
            local maxVal = cfg.Max    or 100
            local curVal = math.clamp(cfg.Value or 0, 0, maxVal)
            local suffix = cfg.Suffix or ""
            local it     = MakeItem(46)

            local bg = MakeFrame(it, UDim2.new(1, 0, 1, 0), nil, C.BgLight, 0)
            Corner(8, bg)
            Stroke(1, C.BorderDim, bg)
            MakeAccentBar(bg)

            MakeLabel(bg, cfg.Label or "Progress",
                UDim2.new(1, -70, 0, 22),
                UDim2.new(0, 14, 0, 4),
                C.TextBright, 13, Enum.Font.GothamBold
            )

            local valLabel = MakeLabel(bg,
                tostring(curVal) .. suffix,
                UDim2.new(0, 55, 0, 22),
                UDim2.new(1, -62, 0, 4),
                C.Accent, 12, Enum.Font.GothamBold,
                Enum.TextXAlignment.Right
            )

            local track = MakeFrame(bg,
                UDim2.new(1, -20, 0, 6),
                UDim2.new(0, 10, 1, -12),
                C.BgDeep, 0
            )
            Corner(3, track)

            local fill = MakeFrame(track,
                UDim2.new(curVal / maxVal, 0, 1, 0),
                nil, C.White, 0
            )
            Corner(3, fill)
            Gradient(C.Accent, C.AccentPink, fill, 0)

            return {
                SetValue = function(_, v)
                    v = math.clamp(v, 0, maxVal)
                    curVal = v
                    Tween(fill, { Size = UDim2.new(v / maxVal, 0, 1, 0) }, 0.3)
                    valLabel.Text = tostring(v) .. suffix
                end,
                GetValue = function() return curVal end,
            }
        end

        -- ── CARD GRID ★ ─────────────────────────────────────────────────
        --  Affiche des items visuels (oeufs, items, etc.) en grille N colonnes
        --
        --  Chaque card contient :
        --    • Grande image centrée en haut
        --    • Nom en bas (tronqué si trop long)
        --    • Checkmark ✓ dans le coin sup droit quand sélectionné
        --    • Bordure violette + fond éclairci au hover et à la sélection
        --
        --  cfg.Items    = { { Name = "EpicEgg", Icon = "rbxassetid://..." }, ... }
        --  cfg.Columns  = 3 (défaut)
        --  cfg.Callback = function(selectedTable) end
        --    → selectedTable est { ["EpicEgg"] = true, ... }
        -- ─────────────────────────────────────────────────────────────────
        function Tab:AddCardGrid(cfg)
            cfg = cfg or {}
            local items    = cfg.Items    or {}
            local cols     = cfg.Columns  or 3
            local callback = cfg.Callback or function() end
            local selected = {}

            -- Hauteur d'une card et espacement
            local cardH = 115
            local gap   = 8

            -- Calcule la hauteur totale du conteneur
            local rows   = math.ceil(#items / cols)
            local totalH = rows * (cardH + gap) + gap

            local it = MakeItem(totalH)

            -- Conteneur de la grille
            local grid = MakeFrame(it, UDim2.new(1, 0, 1, 0), nil, C.Black, 1)

            -- UIGridLayout pour l'arrangement automatique en colonnes
            local gridLayout = Instance.new("UIGridLayout")
            gridLayout.CellSize      = UDim2.new(1/cols, -(gap * (cols + 1) / cols), 0, cardH)
            gridLayout.CellPadding   = UDim2.new(0, gap, 0, gap)
            gridLayout.SortOrder     = Enum.SortOrder.LayoutOrder
            gridLayout.FillDirection = Enum.FillDirection.Horizontal
            gridLayout.Parent        = grid
            Pad(gap, gap, gap, gap, grid)

            for i, item in ipairs(items) do
                -- ── Card individuelle ──
                local card = MakeFrame(grid, UDim2.new(0, 1, 0, 1), nil, C.BgMid, 0)
                card.LayoutOrder = i
                Corner(10, card)
                local cardStroke = Stroke(1, C.BorderDim, card)

                -- Léger gradient sur la card (fond haut -> bas)
                Gradient(C.BgMid, C.BgLight, card, 90)

                -- Image grande centrée en haut de la card
                local img = Instance.new("ImageLabel")
                img.Size                   = UDim2.new(0.72, 0, 0, 68)
                img.Position               = UDim2.new(0.14, 0, 0, 7)
                img.BackgroundTransparency = 1
                img.Image                  = item.Icon or ""
                img.ScaleType              = Enum.ScaleType.Fit
                img.Parent                 = card

                -- Nom de l'item en bas de la card
                local nameLabel = MakeLabel(card,
                    item.Name or "",
                    UDim2.new(1, -6, 0, 18),
                    UDim2.new(0, 3, 1, -22),
                    C.TextMid, 10, Enum.Font.GothamBold,
                    Enum.TextXAlignment.Center
                )
                nameLabel.TextTruncate = Enum.TextTruncate.AtEnd

                -- Checkmark dans le coin supérieur droit
                -- Caché (transparent) par défaut, apparaît à la sélection
                local checkBg = MakeFrame(card,
                    UDim2.new(0, 22, 0, 22),
                    UDim2.new(1, -26, 0, 4),
                    C.Accent, 1   -- transparent par défaut
                )
                Corner(11, checkBg)

                local checkLabel = MakeLabel(checkBg, "✓",
                    UDim2.new(1, 0, 1, 0), nil,
                    C.White, 12, Enum.Font.GothamBold,
                    Enum.TextXAlignment.Center
                )
                checkLabel.TextYAlignment = Enum.TextYAlignment.Center

                -- Zone de clic couvrant toute la card
                local clickZone = Instance.new("TextButton")
                clickZone.Size                 = UDim2.new(1, 0, 1, 0)
                clickZone.BackgroundTransparency = 1
                clickZone.Text                 = ""
                clickZone.Parent               = card

                local isSelected = false

                local function SetCardSelected(v)
                    isSelected = v

                    if v then
                        -- Sélection : bordure violette épaisse, fond éclairci, checkmark visible
                        selected[item.Name] = true
                        Tween(cardStroke,  { Color = C.Accent, Thickness = 2 },       0.2)
                        Tween(card,        { BackgroundColor3 = C.BgLighter },         0.2)
                        Tween(checkBg,     { BackgroundTransparency = 0 },             0.2)
                        Tween(nameLabel,   { TextColor3 = C.TextBright },              0.2)
                        Tween(img,         { ImageTransparency = 0 },                  0.1)
                    else
                        -- Désélection : retour à l'état neutre
                        selected[item.Name] = nil
                        Tween(cardStroke,  { Color = C.BorderDim, Thickness = 1 },    0.2)
                        Tween(card,        { BackgroundColor3 = C.BgMid },             0.2)
                        Tween(checkBg,     { BackgroundTransparency = 1 },             0.2)
                        Tween(nameLabel,   { TextColor3 = C.TextMid },                 0.2)
                    end

                    callback(selected)
                end

                -- Effet hover (uniquement si pas sélectionné)
                clickZone.MouseEnter:Connect(function()
                    if not isSelected then
                        Tween(card,       { BackgroundColor3 = C.BgLight },  0.12)
                        Tween(cardStroke, { Color = C.AccentGlow },          0.12)
                    end
                end)
                clickZone.MouseLeave:Connect(function()
                    if not isSelected then
                        Tween(card,       { BackgroundColor3 = C.BgMid },    0.12)
                        Tween(cardStroke, { Color = C.BorderDim },           0.12)
                    end
                end)

                -- Clic : toggle la sélection
                clickZone.MouseButton1Click:Connect(function()
                    SetCardSelected(not isSelected)
                end)
            end

            return {
                -- Retourne la table des éléments sélectionnés { [name] = true }
                GetSelected = function()
                    return selected
                end,
                -- Permet de forcer la sélection d'un item par code
                SetSelected = function(_, name, value)
                    -- À implémenter si nécessaire
                end,
            }
        end

        -- ── MULTI TOGGLE ─────────────────────────────────────────────────
        --  Liste de toggles indépendants
        --  Callback reçoit { ["Option1"] = true, ... }
        -- ─────────────────────────────────────────────────────────────────
        function Tab:AddMultiToggle(cfg)
            cfg = cfg or {}
            local options  = cfg.Options  or {}
            local callback = cfg.Callback or function() end
            local selected = {}
            local rowH     = 30

            local it = MakeItem(24 + #options * (rowH + 5))

            MakeLabel(it, cfg.Label or "Multi",
                UDim2.new(1, 0, 0, 22), nil,
                C.Accent, 11, Enum.Font.GothamBold
            )

            for i, opt in ipairs(options) do
                local state = false
                local yPos  = 24 + (i - 1) * (rowH + 5)

                local row = MakeFrame(it,
                    UDim2.new(1, 0, 0, rowH),
                    UDim2.new(0, 0, 0, yPos),
                    C.BgLight, 0
                )
                Corner(8, row)
                Stroke(1, C.BorderDim, row)
                MakeAccentBar(row)

                MakeLabel(row, opt,
                    UDim2.new(1, -56, 1, 0),
                    UDim2.new(0, 14, 0, 0),
                    C.TextBright, 12, Enum.Font.Gotham
                )

                local pill = MakeFrame(row,
                    UDim2.new(0, 40, 0, 20),
                    UDim2.new(1, -48, 0.5, -10),
                    C.BgDeep, 0
                )
                Corner(10, pill)

                local knob = MakeFrame(pill,
                    UDim2.new(0, 14, 0, 14),
                    UDim2.new(0, 2, 0.5, -7),
                    C.White, 0
                )
                Corner(7, knob)

                local cz = Instance.new("TextButton")
                cz.Size                 = UDim2.new(1, 0, 1, 0)
                cz.BackgroundTransparency = 1
                cz.Text                 = ""
                cz.Parent               = row

                cz.MouseButton1Click:Connect(function()
                    state = not state
                    if state then
                        selected[opt] = true
                        Tween(pill, { BackgroundColor3 = C.Accent }, 0.18)
                        Tween(knob, { Position = UDim2.new(1, -16, 0.5, -7) }, 0.18)
                    else
                        selected[opt] = nil
                        Tween(pill, { BackgroundColor3 = C.BgDeep }, 0.18)
                        Tween(knob, { Position = UDim2.new(0, 2, 0.5, -7) }, 0.18)
                    end
                    callback(selected)
                end)
            end

            return {
                GetValue = function() return selected end,
            }
        end

        return Tab
    end -- AddTab

    return Window
end -- CreateWindow

return VoidUI
