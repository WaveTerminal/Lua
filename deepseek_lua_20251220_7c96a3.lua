-- Universal ESP - Clean Mobile UI
-- Created by WaveTerminal

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- Player
local Player = Players.LocalPlayer

-- ESP Settings
local ESP = {
    Enabled = false,
    ShowTeam = true,
    ShowEnemy = true,
    Names = false,
    Distance = false,
    Health = false,
    Boxes = false,
    Tracers = false,
    HeatDots = false,
    Theme = "Amethyst",
    Font = "Gotham"
}

-- Color Themes
local Themes = {
    Amethyst = Color3.fromRGB(155, 89, 182),
    Rose = Color3.fromRGB(231, 76, 60),
    Black = Color3.fromRGB(45, 45, 45),
    Red = Color3.fromRGB(231, 76, 60),
    Green = Color3.fromRGB(46, 204, 113),
    Blue = Color3.fromRGB(52, 152, 219)
}

-- Font Options
local Fonts = {
    Code = Enum.Font.Code,
    Gotham = Enum.Font.Gotham,
    SourceSans = Enum.Font.SourceSans,
    Roboto = Enum.Font.GothamSemibold,
    Arial = Enum.Font.SourceSansBold
}

-- Font Names for UI
local FontNames = {"Code", "Gotham", "SourceSans", "Roboto", "Arial"}

-- ESP Instances Storage
local ESPInstances = {}
local ESPConnections = {}

-- UI Variables
local CurrentColor = Themes[ESP.Theme]
local CurrentFont = Fonts[ESP.Font]
local ScreenGui = nil
local MainFrame = nil
local ContentFrame = nil

-- UI Colors
local UIColors = {
    Background = Color3.fromRGB(25, 25, 30),
    Header = CurrentColor,
    Button = Color3.fromRGB(40, 40, 45),
    ButtonHover = Color3.fromRGB(50, 50, 55),
    Text = Color3.fromRGB(255, 255, 255),
    SubText = Color3.fromRGB(200, 200, 220),
    ToggleOn = CurrentColor,
    ToggleOff = Color3.fromRGB(80, 80, 85),
    Section = Color3.fromRGB(35, 35, 40)
}

-- Cleanup function for ESP instances
local function cleanupESP(player)
    if ESPInstances[player] then
        for _, instance in pairs(ESPInstances[player]) do
            if instance then
                if instance:IsA("Highlight") or instance:IsA("BillboardGui") or instance:IsA("BoxHandleAdornment") then
                    instance:Destroy()
                elseif typeof(instance) == "table" and instance.Remove then
                    instance:Remove() -- For Drawing objects
                end
            end
        end
        ESPInstances[player] = nil
    end
end

-- ESP Creation Function
local function createESP(player)
    if player == Player then return end
    
    local character = player.Character
    if not character then
        -- Wait for character and then create ESP
        local conn
        conn = player.CharacterAdded:Connect(function(char)
            wait(0.5) -- Wait a bit for character to fully load
            if ESP.Enabled then
                createESP(player)
            end
            conn:Disconnect()
        end)
        return
    end
    
    -- Clean up any existing ESP for this player
    cleanupESP(player)
    
    -- Create Highlight
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_Highlight_" .. player.UserId
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.OutlineTransparency = 0.8
    highlight.FillColor = CurrentColor
    highlight.FillTransparency = 0.85
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Enabled = ESP.Enabled
    highlight.Parent = character
    
    -- Create Billboard for info
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP_Billboard_" .. player.UserId
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 4, 0)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = 1000
    billboard.Enabled = ESP.Enabled and (ESP.Names or ESP.Distance or ESP.Health)
    billboard.Parent = character
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "ESP_Text"
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = player.Name
    textLabel.TextColor3 = CurrentColor
    textLabel.TextSize = 14
    textLabel.Font = CurrentFont
    textLabel.TextStrokeTransparency = 0.3
    textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    textLabel.Parent = billboard
    
    -- Create Box
    local box = Instance.new("BoxHandleAdornment")
    box.Name = "ESP_Box_" .. player.UserId
    box.Size = Vector3.new(4, 6, 2)
    box.Color3 = CurrentColor
    box.Transparency = 0.7
    box.AlwaysOnTop = true
    box.Visible = ESP.Enabled and ESP.Boxes
    box.Adornee = character:WaitForChild("HumanoidRootPart")
    box.Parent = character
    
    -- Create Drawing objects for Tracers and HeatDots
    local tracer = Drawing.new("Line")
    tracer.Visible = ESP.Enabled and ESP.Tracers
    tracer.Color = CurrentColor
    tracer.Thickness = 1.5
    tracer.Transparency = 0.8
    
    local heatDot = Drawing.new("Circle")
    heatDot.Visible = ESP.Enabled and ESP.HeatDots
    heatDot.Color = CurrentColor
    heatDot.Thickness = 2
    heatDot.Transparency = 0.8
    heatDot.Filled = true
    heatDot.Radius = 4
    
    -- Store instances
    ESPInstances[player] = {
        Highlight = highlight,
        Billboard = billboard,
        Box = box,
        Tracer = tracer,
        HeatDot = heatDot,
        Character = character
    }
    
    -- Handle player leaving
    local leaveConn = player.AncestryChanged:Connect(function()
        if not player.Parent then
            cleanupESP(player)
        end
    end)
    
    -- Handle character death/removal
    local charRemovedConn = player.CharacterRemoving:Connect(function()
        cleanupESP(player)
    end)
    
    -- Store connections for cleanup
    table.insert(ESPConnections, leaveConn)
    table.insert(ESPConnections, charRemovedConn)
end

-- ESP Update Function
local function updateESP()
    if not ESP.Enabled then return end
    
    local camera = workspace.CurrentCamera
    local viewportSize = camera.ViewportSize
    
    for player, instances in pairs(ESPInstances) do
        -- Check if player still exists and has character
        if not player or not player.Parent or not player.Character then
            cleanupESP(player)
            continue
        end
        
        local character = player.Character
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        
        if not rootPart or not humanoid or humanoid.Health <= 0 then
            -- Hide ESP if player is dead
            if instances.Highlight then instances.Highlight.Enabled = false end
            if instances.Billboard then instances.Billboard.Enabled = false end
            if instances.Box then instances.Box.Visible = false end
            if instances.Tracer then instances.Tracer.Visible = false end
            if instances.HeatDot then instances.HeatDot.Visible = false end
            continue
        end
        
        -- Team check
        local isTeammate = false
        if player.Team and Player.Team then
            isTeammate = player.Team == Player.Team
        end
        
        local shouldShow = (isTeammate and ESP.ShowTeam) or (not isTeammate and ESP.ShowEnemy)
        
        if not shouldShow then
            if instances.Highlight then instances.Highlight.Enabled = false end
            if instances.Billboard then instances.Billboard.Enabled = false end
            if instances.Box then instances.Box.Visible = false end
            if instances.Tracer then instances.Tracer.Visible = false end
            if instances.HeatDot then instances.HeatDot.Visible = false end
            continue
        end
        
        -- Update instances
        if instances.Highlight then
            instances.Highlight.Enabled = true
            instances.Highlight.FillColor = CurrentColor
        end
        
        if instances.Billboard then
            instances.Billboard.Enabled = ESP.Names or ESP.Distance or ESP.Health
            
            if instances.Billboard.Enabled then
                local text = ""
                if ESP.Names then
                    text = player.Name .. "\n"
                end
                
                if ESP.Distance and Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
                    local distance = (Player.Character.HumanoidRootPart.Position - rootPart.Position).Magnitude
                    text = text .. string.format("Dist: %d\n", math.floor(distance))
                end
                
                if ESP.Health then
                    text = text .. string.format("HP: %d/%d", 
                        math.floor(humanoid.Health), 
                        math.floor(humanoid.MaxHealth))
                end
                
                instances.Billboard.ESP_Text.Text = text
                instances.Billboard.ESP_Text.TextColor3 = CurrentColor
                instances.Billboard.ESP_Text.Font = CurrentFont
            end
        end
        
        if instances.Box then
            instances.Box.Visible = ESP.Boxes
            instances.Box.Color3 = CurrentColor
        end
        
        -- Update Drawing objects
        local screenPos, onScreen = camera:WorldToViewportPoint(rootPart.Position)
        
        if instances.Tracer then
            instances.Tracer.Visible = ESP.Tracers and onScreen
            
            if instances.Tracer.Visible then
                instances.Tracer.Color = CurrentColor
                instances.Tracer.From = Vector2.new(viewportSize.X / 2, viewportSize.Y)
                instances.Tracer.To = Vector2.new(screenPos.X, screenPos.Y)
            end
        end
        
        if instances.HeatDot then
            instances.HeatDot.Visible = ESP.HeatDots and onScreen
            
            if instances.HeatDot.Visible then
                instances.HeatDot.Color = CurrentColor
                instances.HeatDot.Position = Vector2.new(screenPos.X, screenPos.Y)
            end
        end
    end
end

-- UI Creation Functions
local function updateUIColors()
    CurrentColor = Themes[ESP.Theme]
    CurrentFont = Fonts[ESP.Font]
    
    UIColors.Header = CurrentColor
    UIColors.ToggleOn = CurrentColor
    
    if ScreenGui then
        -- Update header color
        local header = ScreenGui:FindFirstChild("Header")
        if header then
            header.BackgroundColor3 = UIColors.Header
        end
        
        -- Update toggle buttons
        for _, toggle in pairs(ScreenGui:GetDescendants()) do
            if toggle:IsA("TextButton") and toggle.Name:find("Toggle_") then
                local toggleName = toggle.Name:gsub("Toggle_", "")
                if ESP[toggleName] == true then
                    toggle.BackgroundColor3 = UIColors.ToggleOn
                end
            end
        end
    end
end

local function createToggleButton(parent, name, currentState, callback)
    local toggleFrame = Instance.new("Frame")
    toggleFrame.Name = "Toggle_" .. name
    toggleFrame.Size = UDim2.new(1, 0, 0, 40)
    toggleFrame.BackgroundTransparency = 1
    toggleFrame.Parent = parent
    
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Name = "Button"
    toggleBtn.Size = UDim2.new(1, 0, 1, 0)
    toggleBtn.BackgroundColor3 = currentState and UIColors.ToggleOn or UIColors.ToggleOff
    toggleBtn.BorderSizePixel = 0
    toggleBtn.Text = ""
    toggleBtn.AutoButtonColor = false
    toggleBtn.Parent = toggleFrame
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = toggleBtn
    
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = UIColors.Text
    label.TextSize = 14
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = toggleBtn
    
    local status = Instance.new("TextLabel")
    status.Name = "Status"
    status.Size = UDim2.new(0, 30, 0, 20)
    status.Position = UDim2.new(1, -40, 0.5, -10)
    status.BackgroundTransparency = 1
    status.Text = currentState and "ON" or "OFF"
    status.TextColor3 = currentState and Color3.fromRGB(255, 255, 255) or UIColors.SubText
    status.TextSize = 12
    status.Font = Enum.Font.GothamBold
    status.Parent = toggleBtn
    
    -- Hover effects
    toggleBtn.MouseEnter:Connect(function()
        TweenService:Create(toggleBtn, TweenInfo.new(0.2), {
            BackgroundColor3 = currentState and CurrentColor:Lerp(Color3.new(1,1,1), 0.1) 
                               or UIColors.ButtonHover
        }):Play()
    end)
    
    toggleBtn.MouseLeave:Connect(function()
        TweenService:Create(toggleBtn, TweenInfo.new(0.2), {
            BackgroundColor3 = currentState and UIColors.ToggleOn or UIColors.ToggleOff
        }):Play()
    end)
    
    -- Click handler
    toggleBtn.MouseButton1Click:Connect(function()
        local newState = not currentState
        currentState = newState
        
        TweenService:Create(toggleBtn, TweenInfo.new(0.2), {
            BackgroundColor3 = newState and UIColors.ToggleOn or UIColors.ToggleOff
        }):Play()
        
        status.Text = newState and "ON" or "OFF"
        status.TextColor3 = newState and Color3.fromRGB(255, 255, 255) or UIColors.SubText
        
        if callback then
            callback(newState)
        end
    end)
    
    return toggleFrame
end

local function createSection(parent, title)
    local section = Instance.new("Frame")
    section.Name = "Section_" .. title
    section.Size = UDim2.new(1, 0, 0, 50)
    section.BackgroundTransparency = 1
    section.Parent = parent
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -20, 0, 25)
    titleLabel.Position = UDim2.new(0, 10, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = CurrentColor
    titleLabel.TextSize = 16
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = section
    
    local line = Instance.new("Frame")
    line.Size = UDim2.new(1, -20, 0, 1)
    line.Position = UDim2.new(0, 10, 0, 30)
    line.BackgroundColor3 = CurrentColor
    line.BorderSizePixel = 0
    line.Parent = section
    
    local contentFrame = Instance.new("Frame")
    contentFrame.Name = "Content"
    contentFrame.Size = UDim2.new(1, 0, 0, 0)
    contentFrame.Position = UDim2.new(0, 0, 0, 35)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Parent = section
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 5)
    listLayout.Parent = contentFrame
    
    return contentFrame
end

local function createThemeSelector(parent)
    local selectorFrame = Instance.new("Frame")
    selectorFrame.Name = "ThemeSelector"
    selectorFrame.Size = UDim2.new(1, 0, 0, 120)
    selectorFrame.BackgroundTransparency = 1
    selectorFrame.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 25)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = "Theme Color"
    label.TextColor3 = UIColors.Text
    label.TextSize = 14
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = selectorFrame
    
    -- Create theme buttons in a grid
    local themeGrid = Instance.new("Frame")
    themeGrid.Name = "ThemeGrid"
    themeGrid.Size = UDim2.new(1, 0, 0, 80)
    themeGrid.Position = UDim2.new(0, 0, 0, 30)
    themeGrid.BackgroundTransparency = 1
    themeGrid.Parent = selectorFrame
    
    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellSize = UDim2.new(0, 50, 0, 35)
    gridLayout.CellPadding = UDim2.new(0, 8, 0, 8)
    gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    gridLayout.Parent = themeGrid
    
    for themeName, color in pairs(Themes) do
        local themeBtn = Instance.new("TextButton")
        themeBtn.Name = themeName
        themeBtn.Size = UDim2.new(0, 50, 0, 35)
        themeBtn.BackgroundColor3 = color
        themeBtn.BorderSizePixel = 0
        themeBtn.Text = ""
        themeBtn.Parent = themeGrid
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = themeBtn
        
        themeBtn.MouseButton1Click:Connect(function()
            ESP.Theme = themeName
            updateUIColors()
            
            -- Update ESP colors
            for player, instances in pairs(ESPInstances) do
                if instances.Highlight then
                    instances.Highlight.FillColor = CurrentColor
                end
                if instances.Billboard then
                    instances.Billboard.ESP_Text.TextColor3 = CurrentColor
                end
                if instances.Box then
                    instances.Box.Color3 = CurrentColor
                end
                if instances.Tracer then
                    instances.Tracer.Color = CurrentColor
                end
                if instances.HeatDot then
                    instances.HeatDot.Color = CurrentColor
                end
            end
        end)
        
        -- Highlight current theme
        if themeName == ESP.Theme then
            local selection = Instance.new("Frame")
            selection.Name = "Selection"
            selection.Size = UDim2.new(1, 4, 1, 4)
            selection.Position = UDim2.new(0, -2, 0, -2)
            selection.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            selection.BorderSizePixel = 0
            selection.Parent = themeBtn
            
            local selectionCorner = Instance.new("UICorner")
            selectionCorner.CornerRadius = UDim.new(0, 8)
            selectionCorner.Parent = selection
        end
    end
    
    return selectorFrame
end

local function createFontSelector(parent)
    local selectorFrame = Instance.new("Frame")
    selectorFrame.Name = "FontSelector"
    selectorFrame.Size = UDim2.new(1, 0, 0, 80)
    selectorFrame.BackgroundTransparency = 1
    selectorFrame.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 25)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = "Font Style"
    label.TextColor3 = UIColors.Text
    label.TextSize = 14
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = selectorFrame
    
    -- Font dropdown
    local dropdown = Instance.new("TextButton")
    dropdown.Name = "FontDropdown"
    dropdown.Size = UDim2.new(1, 0, 0, 40)
    dropdown.Position = UDim2.new(0, 0, 0, 30)
    dropdown.BackgroundColor3 = UIColors.Button
    dropdown.BorderSizePixel = 0
    dropdown.Text = ESP.Font
    dropdown.TextColor3 = UIColors.Text
    dropdown.TextSize = 14
    dropdown.Font = Enum.Font.Gotham
    dropdown.Parent = selectorFrame
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = dropdown
    
    -- Font list
    local fontList = Instance.new("ScrollingFrame")
    fontList.Name = "FontList"
    fontList.Size = UDim2.new(1, 0, 0, 0)
    fontList.Position = UDim2.new(0, 0, 1, 5)
    fontList.BackgroundColor3 = UIColors.Background
    fontList.BorderSizePixel = 0
    fontList.ScrollBarThickness = 2
    fontList.Visible = false
    fontList.Parent = selectorFrame
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.Parent = fontList
    
    -- Populate font list
    for _, fontName in ipairs(FontNames) do
        local fontOption = Instance.new("TextButton")
        fontOption.Name = fontName
        fontOption.Size = UDim2.new(1, 0, 0, 30)
        fontOption.BackgroundColor3 = UIColors.Button
        fontOption.BorderSizePixel = 0
        fontOption.Text = fontName
        fontOption.TextColor3 = UIColors.Text
        fontOption.TextSize = 13
        fontOption.Font = Fonts[fontName]
        fontOption.Parent = fontList
        
        fontOption.MouseButton1Click:Connect(function()
            ESP.Font = fontName
            CurrentFont = Fonts[fontName]
            dropdown.Text = fontName
            
            -- Update ESP fonts
            for player, instances in pairs(ESPInstances) do
                if instances.Billboard then
                    instances.Billboard.ESP_Text.Font = CurrentFont
                end
            end
            
            fontList.Visible = false
            TweenService:Create(fontList, TweenInfo.new(0.2), {
                Size = UDim2.new(1, 0, 0, 0)
            }):Play()
        end)
    end
    
    -- Toggle font list
    dropdown.MouseButton1Click:Connect(function()
        local isVisible = not fontList.Visible
        fontList.Visible = isVisible
        
        if isVisible then
            TweenService:Create(fontList, TweenInfo.new(0.2), {
                Size = UDim2.new(1, 0, 0, math.min(#FontNames * 32, 160))
            }):Play()
        else
            TweenService:Create(fontList, TweenInfo.new(0.2), {
                Size = UDim2.new(1, 0, 0, 0)
            }):Play()
        end
    end)
    
    return selectorFrame
end

-- Main UI Creation
local function createUI()
    -- Cleanup existing UI
    if ScreenGui then
        ScreenGui:Destroy()
    end
    
    -- Create ScreenGui
    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "UniversalESP_UI"
    ScreenGui.Parent = game.CoreGui
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    ScreenGui.DisplayOrder = 999
    
    -- Main Container
    MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainContainer"
    MainFrame.Size = UDim2.new(0, 340, 0, 500)
    MainFrame.Position = UDim2.new(0.5, -170, 0.5, -250)
    MainFrame.BackgroundColor3 = UIColors.Background
    MainFrame.BackgroundTransparency = 0.05
    MainFrame.BorderSizePixel = 0
    MainFrame.ClipsDescendants = true
    MainFrame.Parent = ScreenGui
    
    -- Rounded Corners
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 14)
    mainCorner.Parent = MainFrame
    
    -- Drop Shadow
    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color = Color3.fromRGB(0, 0, 0)
    mainStroke.Thickness = 2
    mainStroke.Transparency = 0.7
    mainStroke.Parent = MainFrame
    
    -- Header
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 50)
    header.BackgroundColor3 = UIColors.Header
    header.BorderSizePixel = 0
    header.Parent = MainFrame
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 14, 0, 0)
    headerCorner.Parent = header
    
    -- Icon
    local icon = Instance.new("ImageLabel")
    icon.Name = "Icon"
    icon.Size = UDim2.new(0, 32, 0, 32)
    icon.Position = UDim2.new(0, 12, 0.5, -16)
    icon.BackgroundTransparency = 1
    icon.Image = "rbxassetid://5188283269"
    icon.ImageColor3 = Color3.fromRGB(255, 255, 255)
    icon.Parent = header
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -120, 1, 0)
    title.Position = UDim2.new(0, 52, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "Universal - ESP"
    title.TextColor3 = UIColors.Text
    title.TextSize = 18
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header
    
    -- Subtitle
    local subtitle = Instance.new("TextLabel")
    subtitle.Name = "Subtitle"
    subtitle.Size = UDim2.new(0, 100, 0, 20)
    subtitle.Position = UDim2.new(1, -110, 1, -25)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "Made WaveTerminal"
    subtitle.TextColor3 = UIColors.SubText
    subtitle.TextSize = 11
    subtitle.Font = Enum.Font.Gotham
    subtitle.TextXAlignment = Enum.TextXAlignment.Right
    subtitle.Parent = header
    
    -- Window Controls
    local controls = Instance.new("Frame")
    controls.Name = "Controls"
    controls.Size = UDim2.new(0, 70, 0, 30)
    controls.Position = UDim2.new(1, -80, 0, 10)
    controls.BackgroundTransparency = 1
    controls.Parent = header
    
    -- Minimize Button
    local minimizeBtn = Instance.new("TextButton")
    minimizeBtn.Name = "Minimize"
    minimizeBtn.Size = UDim2.new(0, 30, 0, 30)
    minimizeBtn.BackgroundTransparency = 1
    minimizeBtn.Text = "−"
    minimizeBtn.TextColor3 = UIColors.Text
    minimizeBtn.TextSize = 24
    minimizeBtn.Font = Enum.Font.GothamBold
    minimizeBtn.Parent = controls
    
    -- Close Button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "Close"
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(0, 40, 0, 0)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = "×"
    closeBtn.TextColor3 = UIColors.Text
    closeBtn.TextSize = 24
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Parent = controls
    
    -- Content Area
    ContentFrame = Instance.new("ScrollingFrame")
    ContentFrame.Name = "Content"
    ContentFrame.Size = UDim2.new(1, -20, 1, -70)
    ContentFrame.Position = UDim2.new(0, 10, 0, 60)
    ContentFrame.BackgroundTransparency = 1
    ContentFrame.BorderSizePixel = 0
    ContentFrame.ScrollBarThickness = 4
    ContentFrame.ScrollBarImageColor3 = CurrentColor
    ContentFrame.ScrollBarImageTransparency = 0.5
    ContentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    ContentFrame.Parent = MainFrame
    
    local contentLayout = Instance.new("UIListLayout")
    contentLayout.Padding = UDim.new(0, 15)
    contentLayout.Parent = ContentFrame
    
    -- Main ESP Toggle
    local mainToggle = createToggleButton(ContentFrame, "ESP Enable", ESP.Enabled, function(state)
        ESP.Enabled = state
        
        if state then
            -- Create ESP for existing players
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= Player then
                    createESP(player)
                end
            end
            
            -- Player added connection
            local playerAddedConn = Players.PlayerAdded:Connect(function(player)
                wait(0.5)
                createESP(player)
            end)
            table.insert(ESPConnections, playerAddedConn)
            
            -- Start update loop
            local updateConn = RunService.RenderStepped:Connect(updateESP)
            table.insert(ESPConnections, updateConn)
        else
            -- Cleanup all ESP
            for player in pairs(ESPInstances) do
                cleanupESP(player)
            end
            ESPInstances = {}
            
            -- Disconnect all connections
            for _, conn in pairs(ESPConnections) do
                pcall(function() conn:Disconnect() end)
            end
            ESPConnections = {}
        end
    end)
    
    -- ESP Features Section
    local espFeatures = createSection(ContentFrame, "ESP Features")
    espFeatures.Size = UDim2.new(1, 0, 0, 280)
    
    createToggleButton(espFeatures, "ESP Names", ESP.Names, function(state)
        ESP.Names = state
    end)
    
    createToggleButton(espFeatures, "ESP Distance", ESP.Distance, function(state)
        ESP.Distance = state
    end)
    
    createToggleButton(espFeatures, "ESP Health", ESP.Health, function(state)
        ESP.Health = state
    end)
    
    createToggleButton(espFeatures, "ESP Boxes", ESP.Boxes, function(state)
        ESP.Boxes = state
    end)
    
    createToggleButton(espFeatures, "ESP Tracers", ESP.Tracers, function(state)
        ESP.Tracers = state
    end)
    
    createToggleButton(espFeatures, "ESP Heat Dots", ESP.HeatDots, function(state)
        ESP.HeatDots = state
    end)
    
    -- Team Settings Section
    local teamSettings = createSection(ContentFrame, "Team Settings")
    teamSettings.Size = UDim2.new(1, 0, 0, 90)
    
    createToggleButton(teamSettings, "Show Team", ESP.ShowTeam, function(state)
        ESP.ShowTeam = state
    end)
    
    createToggleButton(teamSettings, "Show Enemy", ESP.ShowEnemy, function(state)
        ESP.ShowEnemy = state
    end)
    
    -- Customization Section
    local customization = createSection(ContentFrame, "Customization")
    customization.Size = UDim2.new(1, 0, 0, 250)
    
    -- Theme Selector
    createThemeSelector(customization)
    
    -- Font Selector
    createFontSelector(customization)
    
    -- Auto-update canvas size
    contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        ContentFrame.CanvasSize = UDim2.new(0, 0, 0, contentLayout.AbsoluteContentSize.Y + 20)
    end)
    
    -- Window Controls
    local isMinimized = false
    local originalSize = MainFrame.Size
    
    minimizeBtn.MouseButton1Click:Connect(function()
        isMinimized = not isMinimized
        
        if isMinimized then
            minimizeBtn.Text = "+"
            TweenService:Create(MainFrame, TweenInfo.new(0.3), {
                Size = UDim2.new(0, 340, 0, 50)
            }):Play()
            ContentFrame.Visible = false
        else
            minimizeBtn.Text = "−"
            TweenService:Create(MainFrame, TweenInfo.new(0.3), {
                Size = originalSize
            }):Play()
            ContentFrame.Visible = true
        end
    end)
    
    closeBtn.MouseButton1Click:Connect(function()
        -- Cleanup everything
        for player in pairs(ESPInstances) do
            cleanupESP(player)
        end
        
        for _, conn in pairs(ESPConnections) do
            pcall(function() conn:Disconnect() end)
        end
        
        ScreenGui:Destroy()
    end)
    
    -- Dragging
    local dragging = false
    local dragStart, frameStart
    
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            frameStart = MainFrame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or 
                        input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(
                frameStart.X.Scale, 
                frameStart.X.Offset + delta.X,
                frameStart.Y.Scale, 
                frameStart.Y.Offset + delta.Y
            )
        end
    end)
end

-- Initialize
createUI()
updateUIColors()

print("Universal ESP UI Loaded!")
print("Made by WaveTerminal")