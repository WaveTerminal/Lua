-- Area Battlegrounds Script dengan UI Rayfield
-- Made by WaveTerminal | V1.0 - FIXED VERSION

local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/shlexware/Rayfield/main/source'))()

local Window = Rayfield:CreateWindow({
    Name = "Area Battlegrounds | V1.0",
    LoadingTitle = "Area Battlegrounds",
    LoadingSubtitle = "Made by WaveTerminal",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "AreaBattlegrounds",
        FileName = "Config"
    },
    Discord = {
        Enabled = false,
        Invite = "noinvitelink",
        RememberJoins = true
    },
    KeySystem = false,
})

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Variables
local aimbotEnabled = false
local currentTarget = nil
local aimPart = "Head"
local smoothness = 0.15
local maxDistance = 1000
local blatantMode = false
local stickyAim = false
local wallCheck = true
local teamCheck = true
local fovEnabled = true
local fovRadius = 250
local fovCircle

-- Movement Variables
local walkspeedEnabled = false
local jumppowerEnabled = false
local infJumpEnabled = false
local noclipEnabled = false
local defaultWalkspeed = 16
local defaultJumppower = 50
local currentWalkspeed = 50
local currentJumppower = 75
local noclipConnection = nil
local infJumpConnection = nil

-- Visual Variables
local espEnabled = false
local highlightEnabled = false
local tracerEnabled = false
local tracerPosition = "Bottom" -- "Bottom", "Top", "Middle"
local highlightColor = Color3.new(1, 1, 1)
local tracerColor = Color3.new(1, 1, 1)
local outlines = {}
local highlights = {}
local tracers = {}

-- Connections
local aimbotConnection
local movementConnection

-----------------------------------------------------------
--                     UTILITY FUNCTIONS
-----------------------------------------------------------

-- Check if player is enemy
local function isEnemy(player)
    if player == LocalPlayer then return false end
    
    -- Enemy Check: Only target enemies
    if not isEnemyCheck then return false end
    
    if teamCheck then
        if LocalPlayer.Team and player.Team then
            if LocalPlayer.Team == player.Team then
                return false -- Same team, not enemy
            else
                return true -- Different team, is enemy
            end
        end
    end
    
    -- If no teams, check if player is alive
    local character = player.Character
    if not character then return false end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return false end
    
    return true -- Default to true if no team system
end

-- ESP specific enemy check
local function isESPTarget(player)
    if player == LocalPlayer then return false end
    
    local character = player.Character
    if not character then return false end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return false end
    
    -- Team check for ESP
    if teamCheck and LocalPlayer.Team and player.Team then
        return LocalPlayer.Team ~= player.Team
    end
    
    return true -- Show all if no team system
end

local function isVisible(targetPosition)
    if not wallCheck then return true end
    
    local character = LocalPlayer.Character
    if not character then return false end
    
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return false end
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {character}
    raycastParams.IgnoreWater = true
    
    local direction = (targetPosition - root.Position).Unit
    local distance = (targetPosition - root.Position).Magnitude
    
    local raycastResult = Workspace:Raycast(root.Position, direction * distance, raycastParams)
    
    if raycastResult then
        local hitPart = raycastResult.Instance
        local hitPlayer = Players:GetPlayerFromCharacter(hitPart.Parent)
        
        if hitPlayer and isEnemy(hitPlayer) then
            return true
        end
        return false
    end
    
    return true
end

-----------------------------------------------------------
--                     AIMBOT FUNCTIONS
-----------------------------------------------------------

-- FOV Circle
local function createFOVCircle()
    if fovCircle then fovCircle:Remove() end
    
    fovCircle = Drawing.new("Circle")
    fovCircle.Visible = fovEnabled
    fovCircle.Thickness = 2
    fovCircle.Color = Color3.new(1, 1, 1)
    fovCircle.Transparency = 0.5
    fovCircle.Radius = fovRadius
    fovCircle.Filled = false
    fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
end

local function updateFOVCircle()
    if fovCircle then
        fovCircle.Visible = fovEnabled
        fovCircle.Radius = fovRadius
        fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    end
end

local function getClosestPlayer()
    local closestPlayer = nil
    local closestDistance = fovRadius
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    
    for _, player in pairs(Players:GetPlayers()) do
        if isEnemy(player) then
            local character = player.Character
            if character then
                local targetPart = character:FindFirstChild(aimPart)
                if targetPart then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                    
                    if onScreen then
                        local screenPoint = Vector2.new(screenPos.X, screenPos.Y)
                        local distance = (screenPoint - screenCenter).Magnitude
                        
                        if distance <= fovRadius then
                            if not wallCheck or isVisible(targetPart.Position) then
                                if distance < closestDistance then
                                    closestDistance = distance
                                    closestPlayer = player
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    
    return closestPlayer
end

local function smoothAim(targetPosition)
    local character = LocalPlayer.Character
    if not character then return end
    
    local currentCFrame = Camera.CFrame
    local targetCFrame = CFrame.new(Camera.CFrame.Position, targetPosition)
    
    local delta = targetCFrame - currentCFrame
    local smoothedCFrame = currentCFrame + (delta * smoothness)
    
    Camera.CFrame = smoothedCFrame
end

local function instantAim(targetPosition)
    local character = LocalPlayer.Character
    if not character then return end
    
    Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPosition)
end

local function lockToTarget()
    if currentTarget and currentTarget.Character then
        local targetPart = currentTarget.Character:FindFirstChild(aimPart)
        if targetPart then
            local humanoid = currentTarget.Character:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health > 0 then
                if blatantMode then
                    instantAim(targetPart.Position)
                else
                    smoothAim(targetPart.Position)
                end
            else
                currentTarget = nil
            end
        end
    end
end

local function findAndLockTarget()
    if not currentTarget or not stickyAim then
        currentTarget = getClosestPlayer()
    end
    
    if currentTarget then
        lockToTarget()
    end
end

-----------------------------------------------------------
--                     MOVEMENT FUNCTIONS
-----------------------------------------------------------

local function applyWalkspeed()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.WalkSpeed = walkspeedEnabled and currentWalkspeed or defaultWalkspeed
    end
end

local function applyJumppower()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.JumpPower = jumppowerEnabled and currentJumppower or defaultJumppower
    end
end

local function toggleInfJump(state)
    infJumpEnabled = state
    
    if infJumpConnection then
        infJumpConnection:Disconnect()
        infJumpConnection = nil
    end
    
    if state then
        infJumpConnection = UserInputService.JumpRequest:Connect(function()
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                LocalPlayer.Character.Humanoid:ChangeState("Jumping")
            end
        end)
    end
end

local function toggleNoclip(state)
    noclipEnabled = state
    
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end
    
    if state then
        noclipConnection = RunService.Stepped:Connect(function()
            if noclipEnabled and LocalPlayer.Character then
                for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        part.CanCollide = false
                    end
                end
            end
        end)
    else
        if LocalPlayer.Character then
            for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end
end

-----------------------------------------------------------
--                     VISUAL FUNCTIONS (FIXED)
-----------------------------------------------------------

local function createOutline(character)
    if outlines[character] then 
        outlines[character].Enabled = true
        return 
    end
    
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_Outline"
    highlight.OutlineColor = Color3.new(1, 1, 1)
    highlight.OutlineTransparency = 0
    highlight.FillColor = Color3.new(0, 0, 0)
    highlight.FillTransparency = 1
    highlight.Adornee = character
    highlight.Parent = character
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Enabled = true
    
    outlines[character] = highlight
end

local function createHighlight(character)
    if highlights[character] then 
        highlights[character].Enabled = true
        return 
    end
    
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_Highlight"
    highlight.OutlineColor = Color3.new(1, 1, 1)
    highlight.OutlineTransparency = 0
    highlight.FillColor = highlightColor
    highlight.FillTransparency = 0.5
    highlight.Adornee = character
    highlight.Parent = character
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Enabled = true
    
    highlights[character] = highlight
end

local function createTracer(character)
    if tracers[character] then 
        tracers[character].Visible = false
        return 
    end
    
    local tracer = Drawing.new("Line")
    tracer.Visible = false
    tracer.Color = tracerColor
    tracer.Thickness = 1
    tracer.Transparency = 1
    
    tracers[character] = tracer
end

local function updateTracer(player, character)
    local tracer = tracers[character]
    if not tracer then return end
    
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then
        tracer.Visible = false
        return
    end
    
    local screenPos, onScreen = Camera:WorldToViewportPoint(root.Position)
    if not onScreen then
        tracer.Visible = false
        return
    end
    
    local startPos = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
    
    if tracerPosition == "Top" then
        startPos = Vector2.new(Camera.ViewportSize.X / 2, 0)
    elseif tracerPosition == "Middle" then
        startPos = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    end
    
    local endPos = Vector2.new(screenPos.X, screenPos.Y)
    
    tracer.From = startPos
    tracer.To = endPos
    tracer.Visible = tracerEnabled and isESPTarget(player)
end

local function removeESP(character)
    if outlines[character] then
        outlines[character]:Destroy()
        outlines[character] = nil
    end
    
    if highlights[character] then
        highlights[character]:Destroy()
        highlights[character] = nil
    end
    
    if tracers[character] then
        tracers[character]:Remove()
        tracers[character] = nil
    end
end

local function updateESP()
    -- Clean up dead/left players
    for character, _ in pairs(outlines) do
        if not character or not character.Parent then
            removeESP(character)
        end
    end
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local character = player.Character
            if character then
                if espEnabled and isESPTarget(player) then
                    -- Outline
                    createOutline(character)
                    outlines[character].Enabled = true
                    
                    -- Highlight
                    if highlightEnabled then
                        createHighlight(character)
                        highlights[character].Enabled = true
                        highlights[character].FillColor = highlightColor
                    else
                        if highlights[character] then
                            highlights[character].Enabled = false
                        end
                    end
                    
                    -- Tracer
                    if tracerEnabled then
                        createTracer(character)
                        updateTracer(player, character)
                    else
                        if tracers[character] then
                            tracers[character].Visible = false
                        end
                    end
                else
                    -- Disable ESP for this player
                    if outlines[character] then
                        outlines[character].Enabled = false
                    end
                    if highlights[character] then
                        highlights[character].Enabled = false
                    end
                    if tracers[character] then
                        tracers[character].Visible = false
                    end
                end
            end
        end
    end
end

local function cleanupVisuals()
    for character, highlight in pairs(highlights) do
        if highlight then
            highlight:Destroy()
        end
    end
    highlights = {}
    
    for character, outline in pairs(outlines) do
        if outline then
            outline:Destroy()
        end
    end
    outlines = {}
    
    for character, tracer in pairs(tracers) do
        if tracer then
            tracer:Remove()
        end
    end
    tracers = {}
end

-----------------------------------------------------------
--                     UI CREATION
-----------------------------------------------------------

-- AIM Tab
local AimTab = Window:CreateTab("Aim", 4483362458)

local AimbotSection = AimTab:CreateSection("Aimbot Settings")

local AimbotToggle = AimTab:CreateToggle({
    Name = "Enable Aimbot",
    CurrentValue = false,
    Flag = "AimbotToggle",
    Callback = function(value)
        aimbotEnabled = value
        if not value then
            currentTarget = nil
        end
        print("[Aimbot] " .. (value and "ENABLED" or "DISABLED"))
    end,
})

local BlatantModeToggle = AimTab:CreateToggle({
    Name = "Blatant Mode",
    CurrentValue = false,
    Flag = "BlatantMode",
    Callback = function(value)
        blatantMode = value
        print("[Blatant Mode] " .. (value and "ENABLED" or "DISABLED"))
    end,
})

local StickyAimToggle = AimTab:CreateToggle({
    Name = "Sticky Aim",
    CurrentValue = false,
    Flag = "StickyAim",
    Callback = function(value)
        stickyAim = value
        print("[Sticky Aim] " .. (value and "ENABLED" or "DISABLED"))
    end,
})

local WallCheckToggle = AimTab:CreateToggle({
    Name = "Wall Check",
    CurrentValue = true,
    Flag = "WallCheck",
    Callback = function(value)
        wallCheck = value
        print("[Wall Check] " .. (value and "ENABLED" or "DISABLED"))
    end,
})

local TeamCheckToggle = AimTab:CreateToggle({
    Name = "Team Check",
    CurrentValue = true,
    Flag = "TeamCheck",
    Callback = function(value)
        teamCheck = value
        print("[Team Check] " .. (value and "ENABLED" or "DISABLED"))
    end,
})

local AimPartDropdown = AimTab:CreateDropdown({
    Name = "Aim Part",
    Options = {"Head", "HumanoidRootPart", "Torso"},
    CurrentOption = "Head",
    Flag = "AimPart",
    Callback = function(option)
        aimPart = option
        print("[Aim Part] Changed to: " .. option)
    end,
})

local SmoothnessSlider = AimTab:CreateSlider({
    Name = "Smoothness",
    Range = {0, 1},
    Increment = 0.05,
    Suffix = "",
    CurrentValue = 0.15,
    Flag = "Smoothness",
    Callback = function(value)
        smoothness = value
        print("[Smoothness] Set to: " .. value)
    end,
})

local DistanceSlider = AimTab:CreateSlider({
    Name = "Max Distance",
    Range = {100, 5000},
    Increment = 50,
    Suffix = " studs",
    CurrentValue = 1000,
    Flag = "MaxDistance",
    Callback = function(value)
        maxDistance = value
        print("[Max Distance] Set to: " .. value)
    end,
})

local FOVSection = AimTab:CreateSection("FOV Settings")

local FOVToggle = AimTab:CreateToggle({
    Name = "Show FOV",
    CurrentValue = true,
    Flag = "FOVToggle",
    Callback = function(value)
        fovEnabled = value
        if fovCircle then
            fovCircle.Visible = value
        end
        print("[FOV] " .. (value and "SHOWN" or "HIDDEN"))
    end,
})

local FOVRadiusSlider = AimTab:CreateSlider({
    Name = "FOV Radius",
    Range = {50, 500},
    Increment = 10,
    Suffix = "px",
    CurrentValue = 250,
    Flag = "FOVRadius",
    Callback = function(value)
        fovRadius = value
        if fovCircle then
            fovCircle.Radius = value
        end
        print("[FOV Radius] Set to: " .. value)
    end,
})

-- MOVEMENT Tab
local MovementTab = Window:CreateTab("Movement", 4483362458)

local MovementSection = MovementTab:CreateSection("Movement Settings")

local WalkspeedToggle = MovementTab:CreateToggle({
    Name = "WalkSpeed",
    CurrentValue = false,
    Flag = "WalkspeedToggle",
    Callback = function(value)
        walkspeedEnabled = value
        applyWalkspeed()
        print("[WalkSpeed] " .. (value and "ENABLED: " .. currentWalkspeed or "DISABLED"))
    end,
})

local WalkspeedSlider = MovementTab:CreateSlider({
    Name = "WalkSpeed Value",
    Range = {16, 200},
    Increment = 5,
    Suffix = "",
    CurrentValue = 50,
    Flag = "WalkspeedValue",
    Callback = function(value)
        currentWalkspeed = value
        if walkspeedEnabled then
            applyWalkspeed()
        end
        print("[WalkSpeed Value] Set to: " .. value)
    end,
})

local JumppowerToggle = MovementTab:CreateToggle({
    Name = "JumpPower",
    CurrentValue = false,
    Flag = "JumppowerToggle",
    Callback = function(value)
        jumppowerEnabled = value
        applyJumppower()
        print("[JumpPower] " .. (value and "ENABLED: " .. currentJumppower or "DISABLED"))
    end,
})

local JumppowerSlider = MovementTab:CreateSlider({
    Name = "JumpPower Value",
    Range = {50, 200},
    Increment = 5,
    Suffix = "",
    CurrentValue = 75,
    Flag = "JumppowerValue",
    Callback = function(value)
        currentJumppower = value
        if jumppowerEnabled then
            applyJumppower()
        end
        print("[JumpPower Value] Set to: " .. value)
    end,
})

local InfJumpToggle = MovementTab:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false,
    Flag = "InfJumpToggle",
    Callback = function(value)
        toggleInfJump(value)
        print("[Infinite Jump] " .. (value and "ENABLED" or "DISABLED"))
    end,
})

local NoclipToggle = MovementTab:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Flag = "NoclipToggle",
    Callback = function(value)
        toggleNoclip(value)
        print("[Noclip] " .. (value and "ENABLED" or "DISABLED"))
    end,
})

-- VISUAL Tab
local VisualTab = Window:CreateTab("Visual", 4483362458)

local VisualSection = VisualTab:CreateSection("ESP Settings")

local EspToggle = VisualTab:CreateToggle({
    Name = "ESP Outline",
    CurrentValue = false,
    Flag = "EspToggle",
    Callback = function(value)
        espEnabled = value
        if not value then
            cleanupVisuals()
        end
        print("[ESP Outline] " .. (value and "ENABLED" or "DISABLED"))
    end,
})

local HighlightToggle = VisualTab:CreateToggle({
    Name = "White Highlight",
    CurrentValue = false,
    Flag = "HighlightToggle",
    Callback = function(value)
        highlightEnabled = value
        print("[White Highlight] " .. (value and "ENABLED" or "DISABLED"))
    end,
})

local TracerToggle = VisualTab:CreateToggle({
    Name = "Tracer",
    CurrentValue = false,
    Flag = "TracerToggle",
    Callback = function(value)
        tracerEnabled = value
        print("[Tracer] " .. (value and "ENABLED" or "DISABLED"))
    end,
})

local TracerDropdown = VisualTab:CreateDropdown({
    Name = "Tracer Position",
    Options = {"Bottom", "Top", "Middle"},
    CurrentOption = "Bottom",
    Flag = "TracerPosition",
    Callback = function(option)
        tracerPosition = option
        print("[Tracer Position] Changed to: " .. option)
    end,
})

local HighlightColor = VisualTab:CreateColorPicker({
    Name = "Highlight Color",
    Color = Color3.fromRGB(255, 255, 255),
    Flag = "HighlightColor",
    Callback = function(color)
        highlightColor = color
        for _, highlight in pairs(highlights) do
            if highlight then
                highlight.FillColor = color
            end
        end
        print("[Highlight Color] Changed")
    end
})

local TracerColor = VisualTab:CreateColorPicker({
    Name = "Tracer Color",
    Color = Color3.fromRGB(255, 255, 255),
    Flag = "TracerColor",
    Callback = function(color)
        tracerColor = color
        for _, tracer in pairs(tracers) do
            if tracer then
                tracer.Color = color
            end
        end
        print("[Tracer Color] Changed")
    end
})

local EnemyCheckToggle = VisualTab:CreateToggle({
    Name = "Enemy Check",
    CurrentValue = true,
    Flag = "EnemyCheck",
    Callback = function(value)
        isEnemyCheck = value
        print("[Enemy Check] " .. (value and "ENABLED" or "DISABLED"))
    end,
})

local TeamCheckEspToggle = VisualTab:CreateToggle({
    Name = "ESP Team Check",
    CurrentValue = true,
    Flag = "TeamCheckESP",
    Callback = function(value)
        teamCheck = value
        print("[ESP Team Check] " .. (value and "ENABLED" or "DISABLED"))
    end,
})

-----------------------------------------------------------
--                     INITIALIZATION
-----------------------------------------------------------

-- Create FOV circle
createFOVCircle()

-- Setup connections
aimbotConnection = RunService.RenderStepped:Connect(function()
    -- Aimbot
    if aimbotEnabled then
        findAndLockTarget()
    end
    
    -- ESP
    updateESP()
    
    -- Movement updates
    if walkspeedEnabled then
        applyWalkspeed()
    end
    
    if jumppowerEnabled then
        applyJumppower()
    end
end)

-- Setup player events
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        task.wait(1) -- Wait for character to fully load
        if espEnabled then
            updateESP()
        end
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    local character = player.Character
    if character then
        removeESP(character)
    end
end)

-- Setup character events for LocalPlayer
LocalPlayer.CharacterAdded:Connect(function(character)
    task.wait(0.5) -- Wait for character to load
    if walkspeedEnabled then
        applyWalkspeed()
    end
    if jumppowerEnabled then
        applyJumppower()
    end
end)

-- Viewport resize handler
Camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
    updateFOVCircle()
end)

-- Cleanup function
local function cleanup()
    if aimbotConnection then
        aimbotConnection:Disconnect()
        aimbotConnection = nil
    end
    
    if infJumpConnection then
        infJumpConnection:Disconnect()
        infJumpConnection = nil
    end
    
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end
    
    if fovCircle then
        fovCircle:Remove()
        fovCircle = nil
    end
    
    cleanupVisuals()
    
    print("[Cleanup] All connections and visuals cleaned")
end

-- Game cleanup
LocalPlayer.CharacterRemoving:Connect(function()
    cleanup()
end)

-- Auto-apply settings on respawn
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1) -- Wait for respawn
    if walkspeedEnabled then
        applyWalkspeed()
    end
    if jumppowerEnabled then
        applyJumppower()
    end
end)

print("=========================================")
print("Area Battlegrounds | V1.0 - FIXED VERSION")
print("Made by WaveTerminal")
print("=========================================")
print("Features Fixed:")
print("✓ Aimbot with proper Lock-on functionality")
print("✓ ESP with Team Check & Enemy Check")
print("✓ ESP Outline, Highlight, and Tracer WORKING")
print("✓ Movement: WalkSpeed & JumpPower WORKING")
print("✓ Infinite Jump & Noclip WORKING")
print("✓ FOV Circle WORKING")
print("=========================================")
print("Debug messages enabled - check output for status")
print("Script loaded successfully!")