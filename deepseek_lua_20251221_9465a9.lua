-- RUN FROM FAST FREADBEAR - Ultimate Script v1.2
-- Made with Rayfield UI

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Variables
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local ESPEnabled = false
local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "UNNMAED_ESP"
ESPFolder.Parent = Camera

-- Settings
local Settings = {
    -- ESP Settings
    ESPEnabled = false,
    BoxESP = true,
    TracerESP = true,
    DistanceESP = true,
    HighlightESP = true,
    
    -- Colors
    BoxColor = Color3.fromRGB(255, 0, 0),
    TracerColor = Color3.fromRGB(255, 0, 0),
    TextColor = Color3.fromRGB(255, 255, 255),
    
    -- Other
    MaxDistance = 1000,
    WalkSpeed = 16,
    JumpPower = 50,
    InfJump = false,
    Noclip = false,
    AutoHey = false,
    HeyCooldown = 5,
    LastHeyTime = 0
}

-- Teleport Locations
local TeleportLocations = {
    ["Living Room"] = workspace.NavPoints.Part1,
    ["Kitchen"] = workspace.NavPoints.Part2,
    ["Bathroom"] = workspace.NavPoints.Part3,
    ["Bedroom"] = workspace.NavPoints.Part4,
    ["Storage Room"] = workspace.NavPoints.Part5,
    ["2nd Floor"] = workspace.NavPoints.Part6,
    ["Front of FreadBear House"] = workspace.NavPoints.Part7,
    ["Back of FreadBear House"] = workspace.NavPoints.Part8,
    ["Car"] = workspace.InteractiveObjects.Car
}

-- Rayfield UI Library
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Create Window
local Window = Rayfield:CreateWindow({
    Name = "RUN FROM FAST FREADBEAR",
    LoadingTitle = "Loading Ultimate Script...",
    LoadingSubtitle = "by WITTY PROTECTED",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "FreadBearScript",
        FileName = "Config"
    },
    Discord = {
        Enabled = false,
        Invite = "noinvitelink",
        RememberJoins = true
    },
    KeySystem = true,
    KeySettings = {
        Title = "WITTY PROTECTED",
        Subtitle = "KEY SYSTEM",
        Note = "Wait, You're forget something ?",
        FileName = "FreadBearKey",
        SaveKey = true,
        GrabKeyFromSite = false,
        Key = {"WYKEY_e59GkEWYSbWvC6NOxlKh"}
    }
})

-- Main Tab
local MainTab = Window:CreateTab("Main", 4483362458)

-- Hey Voice Section
local VoiceSection = MainTab:CreateSection("Hey Voice")

local HeyButton = MainTab:CreateButton({
    Name = "Hey Voice (One Click)",
    Callback = function()
        if os.time() - Settings.LastHeyTime >= Settings.HeyCooldown then
            local args = {LocalPlayer.Character}
            local success, result = pcall(function()
                ReplicatedStorage:WaitForChild("HeyEffect"):FireServer(unpack(args))
            end)
            if success then
                Rayfield:Notify({
                    Title = "Hey Voice",
                    Content = "Successfully activated!",
                    Duration = 3,
                    Image = 4483362458
                })
                Settings.LastHeyTime = os.time()
            else
                Rayfield:Notify({
                    Title = "Error",
                    Content = "Failed to activate Hey Voice",
                    Duration = 3,
                    Image = 4483362458
                })
            end
        else
            Rayfield:Notify({
                Title = "Cooldown",
                Content = "Please wait " .. (Settings.HeyCooldown - (os.time() - Settings.LastHeyTime)) .. " seconds",
                Duration = 3,
                Image = 4483362458
            })
        end
    end
})

local AutoHeyToggle = MainTab:CreateToggle({
    Name = "Auto Hey Voice",
    CurrentValue = Settings.AutoHey,
    Flag = "AutoHey",
    Callback = function(Value)
        Settings.AutoHey = Value
        if Value then
            StartAutoHey()
        else
            StopAutoHey()
        end
    end
})

local HeyCooldownSlider = MainTab:CreateSlider({
    Name = "Hey Cooldown",
    Range = {1, 30},
    Increment = 1,
    Suffix = "seconds",
    CurrentValue = Settings.HeyCooldown,
    Flag = "HeyCooldown",
    Callback = function(Value)
        Settings.HeyCooldown = Value
    end
})

-- Jumpscare Section
local JumpscareSection = MainTab:CreateSection("Jumpscare")

local JumpscareButton = MainTab:CreateButton({
    Name = "Delete Jumpscare Folder",
    Callback = function()
        local success, result = pcall(function()
            ReplicatedStorage.Jumpscare:Destroy()
        end)
        
        if success then
            Rayfield:Notify({
                Title = "Jumpscare",
                Content = "Jumpscare folder deleted successfully!",
                Duration = 5,
                Image = 4483362458
            })
        else
            Rayfield:Notify({
                Title = "Error",
                Content = "Failed to delete jumpscare folder",
                Duration = 5,
                Image = 4483362458
            })
        end
    end
})

-- Movement Tab
local MovementTab = Window:CreateTab("Movement", 4483362458)

local WalkSpeedSlider = MovementTab:CreateSlider({
    Name = "WalkSpeed",
    Range = {16, 200},
    Increment = 1,
    Suffix = "speed",
    CurrentValue = Settings.WalkSpeed,
    Flag = "WalkSpeed",
    Callback = function(Value)
        Settings.WalkSpeed = Value
        UpdateHumanoid()
    end
})

local JumpPowerSlider = MovementTab:CreateSlider({
    Name = "JumpPower",
    Range = {50, 500},
    Increment = 10,
    Suffix = "power",
    CurrentValue = Settings.JumpPower,
    Flag = "JumpPower",
    Callback = function(Value)
        Settings.JumpPower = Value
        UpdateHumanoid()
    end
})

local InfJumpToggle = MovementTab:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = Settings.InfJump,
    Flag = "InfJump",
    Callback = function(Value)
        Settings.InfJump = Value
        if Value then
            EnableInfiniteJump()
        else
            DisableInfiniteJump()
        end
    end
})

local NoclipToggle = MovementTab:CreateToggle({
    Name = "Noclip",
    CurrentValue = Settings.Noclip,
    Flag = "Noclip",
    Callback = function(Value)
        Settings.Noclip = Value
        if Value then
            EnableNoclip()
        else
            DisableNoclip()
        end
    end
})

-- Visual Tab (ESP System)
local VisualTab = Window:CreateTab("Visual", 4483362458)

-- ESP Master Control
VisualTab:CreateSection("ESP Master Control")

local ESPMasterToggle = VisualTab:CreateToggle({
    Name = "ESP Master Switch",
    CurrentValue = Settings.ESPEnabled,
    Flag = "ESPMaster",
    Callback = function(Value)
        Settings.ESPEnabled = Value
        ESPEnabled = Value
        if Value then
            StartESP()
        else
            StopESP()
        end
    end
})

-- ESP Features
VisualTab:CreateSection("ESP Features")

local BoxESPToggle = VisualTab:CreateToggle({
    Name = "Box ESP",
    CurrentValue = Settings.BoxESP,
    Flag = "BoxESP",
    Callback = function(Value)
        Settings.BoxESP = Value
        UpdateESPVisibility()
    end
})

local TracerESPToggle = VisualTab:CreateToggle({
    Name = "Tracer ESP (From Top)",
    CurrentValue = Settings.TracerESP,
    Flag = "TracerESP",
    Callback = function(Value)
        Settings.TracerESP = Value
        UpdateESPVisibility()
    end
})

local DistanceESPToggle = VisualTab:CreateToggle({
    Name = "Distance ESP",
    CurrentValue = Settings.DistanceESP,
    Flag = "DistanceESP",
    Callback = function(Value)
        Settings.DistanceESP = Value
        UpdateESPVisibility()
    end
})

local HighlightESPToggle = VisualTab:CreateToggle({
    Name = "Highlight ESP",
    CurrentValue = Settings.HighlightESP,
    Flag = "HighlightESP",
    Callback = function(Value)
        Settings.HighlightESP = Value
        UpdateESPVisibility()
    end
})

-- ESP Colors
VisualTab:CreateSection("ESP Colors")

local BoxColorPicker = VisualTab:CreateColorPicker({
    Name = "Box Color",
    Color = Settings.BoxColor,
    Flag = "BoxColor",
    Callback = function(Value)
        Settings.BoxColor = Value
        UpdateESPColors()
    end
})

local TracerColorPicker = VisualTab:CreateColorPicker({
    Name = "Tracer Color",
    Color = Settings.TracerColor,
    Flag = "TracerColor",
    Callback = function(Value)
        Settings.TracerColor = Value
        UpdateESPColors()
    end
})

local TextColorPicker = VisualTab:CreateColorPicker({
    Name = "Text Color",
    Color = Settings.TextColor,
    Flag = "TextColor",
    Callback = function(Value)
        Settings.TextColor = Value
        UpdateESPColors()
    end
})

-- ESP Settings
VisualTab:CreateSection("ESP Settings")

local MaxDistanceSlider = VisualTab:CreateSlider({
    Name = "Max Distance",
    Range = {50, 5000},
    Increment = 50,
    Suffix = "studs",
    CurrentValue = Settings.MaxDistance,
    Flag = "ESPMaxDistance",
    Callback = function(Value)
        Settings.MaxDistance = Value
    end
})

-- Teleport Tab (Simplified)
local TeleportTab = Window:CreateTab("Teleport", 4483362458)

-- Quick Teleport Buttons only
TeleportTab:CreateSection("Quick Teleport")

for locationName, locationPart in pairs(TeleportLocations) do
    TeleportTab:CreateButton({
        Name = "TP to " .. locationName,
        Callback = function()
            if locationPart and locationPart:IsA("BasePart") then
                local character = LocalPlayer.Character
                if character then
                    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
                    if humanoidRootPart then
                        humanoidRootPart.CFrame = CFrame.new(locationPart.Position)
                        Rayfield:Notify({
                            Title = "Teleport",
                            Content = "Teleported to " .. locationName,
                            Duration = 3,
                            Image = 4483362458
                        })
                    end
                end
            end
        end
    })
end

-- ESP Core System
local ESPObjects = {}
local ESPCore = {}
ESPCore.__index = ESPCore

function ESPCore:Create(player)
    local self = setmetatable({}, ESPCore)
    self.Player = player
    self.Character = player.Character
    self.Highlight = nil
    self.Box = nil
    self.Tracer = nil
    self.DistanceLabel = nil
    self.Connections = {}
    
    self:Initialize()
    return self
end

function ESPCore:Initialize()
    if not self.Character then
        self.Character = self.Player.CharacterAdded:Wait()
    end
    
    self:CreateComponents()
    
    -- Character added event
    table.insert(self.Connections, self.Player.CharacterAdded:Connect(function(char)
        self.Character = char
        self:DestroyComponents()
        task.wait(0.5)
        self:CreateComponents()
    end))
    
    -- Character removed event
    table.insert(self.Connections, self.Character.Destroying:Connect(function()
        self:Destroy()
    end))
end

function ESPCore:CreateComponents()
    if not self.Character then return end
    
    local hrp = self.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    -- Highlight ESP
    if Settings.HighlightESP then
        self.Highlight = Instance.new("Highlight")
        self.Highlight.Name = "ESP_Highlight"
        self.Highlight.FillColor = Settings.BoxColor
        self.Highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        self.Highlight.FillTransparency = 0.3
        self.Highlight.OutlineTransparency = 0
        self.Highlight.Adornee = self.Character
        self.Highlight.Enabled = ESPEnabled
        self.Highlight.Parent = ESPFolder
    end
    
    -- Box ESP (Universal untuk R6 dan R15)
    if Settings.BoxESP then
        self.Box = Instance.new("BillboardGui")
        self.Box.Name = "ESP_Box"
        self.Box.Size = UDim2.new(4, 0, 6, 0)
        self.Box.StudsOffset = Vector3.new(0, 3, 0)
        self.Box.AlwaysOnTop = true
        self.Box.Adornee = hrp
        self.Box.Enabled = ESPEnabled and Settings.BoxESP
        self.Box.Parent = ESPFolder
        
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 1, 0)
        frame.BackgroundTransparency = 1
        frame.Parent = self.Box
        
        local outline = Instance.new("UIStroke")
        outline.Color = Settings.BoxColor
        outline.Thickness = 2
        outline.Parent = frame
    end
    
    -- Tracer ESP (Dari atas layar)
    if Settings.TracerESP then
        self.Tracer = Instance.new("Frame")
        self.Tracer.Name = "ESP_Tracer"
        self.Tracer.BackgroundColor3 = Settings.TracerColor
        self.Tracer.BorderSizePixel = 0
        self.Tracer.Size = UDim2.new(0, 2, 0, 100)
        self.Tracer.Position = UDim2.new(0.5, -1, 0, 0)
        self.Tracer.Visible = ESPEnabled and Settings.TracerESP
        self.Tracer.Parent = ESPFolder
    end
    
    -- Distance ESP
    if Settings.DistanceESP then
        self.DistanceLabel = Instance.new("BillboardGui")
        self.DistanceLabel.Name = "ESP_Distance"
        self.DistanceLabel.Size = UDim2.new(0, 100, 0, 20)
        self.DistanceLabel.StudsOffset = Vector3.new(0, 4, 0)
        self.DistanceLabel.AlwaysOnTop = true
        self.DistanceLabel.Adornee = hrp
        self.DistanceLabel.Enabled = ESPEnabled and Settings.DistanceESP
        self.DistanceLabel.Parent = ESPFolder
        
        local text = Instance.new("TextLabel")
        text.Size = UDim2.new(1, 0, 1, 0)
        text.BackgroundTransparency = 1
        text.Text = "0 studs"
        text.TextColor3 = Settings.TextColor
        text.TextSize = 12
        text.Font = Enum.Font.Code
        text.TextStrokeTransparency = 0
        text.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        text.Parent = self.DistanceLabel
    end
end

function ESPCore:Update()
    if not ESPEnabled or not self.Character then return end
    
    local hrp = self.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    -- Distance check
    local distance = (hrp.Position - Camera.CFrame.Position).Magnitude
    if distance > Settings.MaxDistance then
        self:SetVisible(false)
        return
    end
    
    self:SetVisible(true)
    
    -- Update Distance Text
    if self.DistanceLabel and self.DistanceLabel:FindFirstChild("TextLabel") then
        self.DistanceLabel.TextLabel.Text = string.format("%d studs", math.floor(distance))
    end
    
    -- Update Tracer (Dari atas layar)
    if self.Tracer then
        local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
        if onScreen then
            local tracerLength = math.clamp(distance / 10, 50, 200)
            self.Tracer.Size = UDim2.new(0, 2, 0, tracerLength)
            self.Tracer.Position = UDim2.new(
                screenPos.X / Camera.ViewportSize.X, 
                -1, 
                0,  -- Selalu dari atas (Y = 0)
                0
            )
            self.Tracer.Visible = true
        else
            self.Tracer.Visible = false
        end
    end
    
    -- Update Colors
    if self.Highlight then
        self.Highlight.FillColor = Settings.BoxColor
    end
    
    if self.Box and self.Box:FindFirstChild("Frame") then
        self.Box.Frame.UIStroke.Color = Settings.BoxColor
    end
    
    if self.Tracer then
        self.Tracer.BackgroundColor3 = Settings.TracerColor
    end
end

function ESPCore:SetVisible(state)
    if self.Highlight then
        self.Highlight.Enabled = state and Settings.HighlightESP
    end
    
    if self.Box then
        self.Box.Enabled = state and Settings.BoxESP
    end
    
    if self.Tracer then
        self.Tracer.Visible = state and Settings.TracerESP
    end
    
    if self.DistanceLabel then
        self.DistanceLabel.Enabled = state and Settings.DistanceESP
    end
end

function ESPCore:DestroyComponents()
    if self.Highlight then
        self.Highlight:Destroy()
        self.Highlight = nil
    end
    
    if self.Box then
        self.Box:Destroy()
        self.Box = nil
    end
    
    if self.Tracer then
        self.Tracer:Destroy()
        self.Tracer = nil
    end
    
    if self.DistanceLabel then
        self.DistanceLabel:Destroy()
        self.DistanceLabel = nil
    end
end

function ESPCore:Destroy()
    self:DestroyComponents()
    
    for _, conn in ipairs(self.Connections) do
        conn:Disconnect()
    end
    
    ESPObjects[self.Player] = nil
end

-- ESP Management Functions
function StartESP()
    ESPEnabled = true
    
    -- Create ESP for all existing players
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            if not ESPObjects[player] then
                ESPObjects[player] = ESPCore:Create(player)
            end
            ESPObjects[player]:SetVisible(true)
        end
    end
    
    -- Start update loop
    coroutine.wrap(function()
        while ESPEnabled do
            for _, esp in pairs(ESPObjects) do
                esp:Update()
            end
            task.wait(0.03) -- ~30 FPS
        end
    end)()
end

function StopESP()
    ESPEnabled = false
    for _, esp in pairs(ESPObjects) do
        esp:SetVisible(false)
    end
end

function UpdateESPVisibility()
    for _, esp in pairs(ESPObjects) do
        esp:SetVisible(ESPEnabled)
    end
end

function UpdateESPColors()
    for _, esp in pairs(ESPObjects) do
        esp:Update()
    end
end

-- Player tracking
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(char)
        if ESPEnabled and player ~= LocalPlayer then
            if not ESPObjects[player] then
                ESPObjects[player] = ESPCore:Create(player)
            end
            ESPObjects[player]:SetVisible(true)
        end
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    if ESPObjects[player] then
        ESPObjects[player]:Destroy()
    end
end)

-- Movement Functions
function UpdateHumanoid()
    local character = LocalPlayer.Character
    if character then
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = Settings.WalkSpeed
            humanoid.JumpPower = Settings.JumpPower
        end
    end
end

local InfJumpConnection = nil
function EnableInfiniteJump()
    InfJumpConnection = UserInputService.JumpRequest:Connect(function()
        if Settings.InfJump then
            local character = LocalPlayer.Character
            if character then
                local humanoid = character:FindFirstChild("Humanoid")
                if humanoid then
                    humanoid:ChangeState("Jumping")
                end
            end
        end
    end)
end

function DisableInfiniteJump()
    if InfJumpConnection then
        InfJumpConnection:Disconnect()
        InfJumpConnection = nil
    end
end

local IsNoclipping = false
local NoClipConnections = {}
function EnableNoclip()
    if IsNoclipping then return end
    IsNoclipping = true
    local character = LocalPlayer.Character
    if character then
        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                table.insert(NoClipConnections, RunService.Heartbeat:Connect(function()
                    if IsNoclipping and part then
                        part.CanCollide = false
                    end
                end))
            end
        end
    end
end

function DisableNoclip()
    IsNoclipping = false
    for _, conn in ipairs(NoClipConnections) do
        conn:Disconnect()
    end
    NoClipConnections = {}
    local character = LocalPlayer.Character
    if character then
        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end
end

-- Auto Hey Functions
local AutoHeyRunning = false
function StartAutoHey()
    AutoHeyRunning = true
    coroutine.wrap(function()
        while AutoHeyRunning and Settings.AutoHey do
            local args = {LocalPlayer.Character}
            pcall(function()
                ReplicatedStorage:WaitForChild("HeyEffect"):FireServer(unpack(args))
            end)
            task.wait(Settings.HeyCooldown)
        end
    end)()
end

function StopAutoHey()
    AutoHeyRunning = false
end

-- Character Added Connection
LocalPlayer.CharacterAdded:Connect(function(character)
    task.wait(1)
    UpdateHumanoid()
    if Settings.Noclip then
        EnableNoclip()
    end
end)

-- Initial Setup
if LocalPlayer.Character then
    UpdateHumanoid()
end

if Settings.InfJump then
    EnableInfiniteJump()
end

if Settings.Noclip then
    EnableNoclip()
end

if Settings.AutoHey then
    StartAutoHey()
end

Rayfield:Notify({
    Title = "WITTY PROTECTED",
    Content = "Script loaded successfully!",
    Duration = 5,
    Image = 4483362458
})