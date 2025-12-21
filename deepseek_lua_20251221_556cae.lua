-- Universal Script dengan Rayfield UI
-- Made By Witty

-- Load Rayfield Library
local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/shlexware/Rayfield/main/source.lua'))()

-- Buat Window
local Window = Rayfield:CreateWindow({
   Name = "🔫 Universal Script",
   LoadingTitle = "Universal Script Loading...",
   LoadingSubtitle = "Made By Witty",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "UniversalScript",
      FileName = "UniversalConfig"
   },
   Discord = {
      Enabled = false,
      Invite = "noinvitelink",
      RememberJoins = true
   },
   KeySystem = false,
   KeySettings = {
      Title = "Universal Script",
      Subtitle = "Key System",
      Note = "No method of obtaining the key is provided",
      FileName = "Key",
      SaveKey = true,
      GrabKeyFromSite = false,
      Key = {"Universal"}
   }
})

-- Variables
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- Configuration
local Settings = {
    AimbotEnabled = false,
    ESPEnabled = false,
    TriggerbotEnabled = false,
    TeamCheck = true,
    WallCheck = true,
    FOV = 250,
    HoldingE = false,
    Smoothness = 1.0,
    AimKey = "E",
    TriggerbotKey = "Q",
    TriggerbotDelay = 0.1
}

-- ESP Objects storage
local ESPObjects = {}

-- FOV Circle
local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = false
FOVCircle.Radius = Settings.FOV
FOVCircle.Color = Color3.fromRGB(0, 255, 0)
FOVCircle.Thickness = 1
FOVCircle.NumSides = 100
FOVCircle.Transparency = 1
FOVCircle.Filled = false

-- Hitbox Variables
local HitboxSettings = {
    HeadSize = 50,
    Enabled = false,
    Transparency = 0.7,
    Color = "Really blue"
}

-- Buat Tabs
local MainTab = Window:CreateTab("🎯 Main", 4483362458)
local VisualTab = Window:CreateTab("👁️ Visual", 4483362458)
local MiscTab = Window:CreateTab("🛠️ Misc", 4483362458)
local HitboxTab = Window:CreateTab("🎯 Hitbox", 4483362458)

-- ==================== FUNCTIONS ====================

-- Function untuk cek tim
local function IsEnemy(player)
    if player == LocalPlayer then return false end
    if not Settings.TeamCheck then return true end
    
    local localTeam = LocalPlayer.Team
    local playerTeam = player.Team
    
    return localTeam ~= playerTeam
end

-- Function untuk wall check
local function IsVisible(targetChar)
    if not Settings.WallCheck then return true end
    if not LocalPlayer.Character then return false end
    
    local origin = LocalPlayer.Character:FindFirstChild("HumanoidRootPart") or LocalPlayer.Character:FindFirstChild("Head")
    local targetPart = targetChar:FindFirstChild("Head")
    
    if not origin or not targetPart then return false end
    
    local ray = Ray.new(origin.Position, (targetPart.Position - origin.Position).Unit * 1000)
    local hit, position = Workspace:FindPartOnRayWithIgnoreList(ray, {LocalPlayer.Character, targetChar})
    
    return hit == nil or hit:IsDescendantOf(targetChar)
end

-- Function untuk ESP (dari script universal)
local function AddESP(player)
    if player == LocalPlayer then return end
    if not player.Character then return end
    if ESPObjects[player] then return end

    local h = Instance.new("Highlight")
    h.Name = "ESP"
    h.FillColor = Color3.fromRGB(0, 140, 255)
    h.OutlineColor = Color3.fromRGB(0, 200, 255)
    h.FillTransparency = 0.5
    h.OutlineTransparency = 0
    h.Parent = player.Character

    ESPObjects[player] = h
end

local function RemoveESP(player)
    if ESPObjects[player] then
        ESPObjects[player]:Destroy()
        ESPObjects[player] = nil
    end
end

-- Function untuk dapatkan target terdekat (dari script universal)
local function GetClosest()
    local closest, dist = nil, Settings.FOV
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") then
            -- Cek tim jika team check aktif
            if Settings.TeamCheck then
                if not IsEnemy(p) then continue end
            end
            
            -- Cek wall check jika aktif
            if Settings.WallCheck then
                if not IsVisible(p.Character) then continue end
            end
            
            local pos, onscreen = Camera:WorldToViewportPoint(p.Character.Head.Position)
            if onscreen then
                local mag = (Vector2.new(pos.X, pos.Y) - Vector2.new(Mouse.X, Mouse.Y)).Magnitude
                if mag < dist then
                    dist = mag
                    closest = p
                end
            end
        end
    end
    return closest
end

-- Function untuk Triggerbot
local function Triggerbot()
    if not Settings.TriggerbotEnabled then return end
    if not LocalPlayer.Character then return end
    
    local target = GetClosest()
    if target and target.Character and target.Character:FindFirstChild("Head") then
        -- Cek apakah target dalam FOV
        local pos, onscreen = Camera:WorldToViewportPoint(target.Character.Head.Position)
        if onscreen then
            local mag = (Vector2.new(pos.X, pos.Y) - Vector2.new(Mouse.X, Mouse.Y)).Magnitude
            if mag < Settings.FOV then
                -- Trigger mouse click
                mouse1click()
                wait(Settings.TriggerbotDelay)
            end
        end
    end
end

-- Function untuk Hitbox (dari script yang diberikan)
local function UpdateHitboxes()
    if not HitboxSettings.Enabled then return end
    
    for i, v in next, Players:GetPlayers() do
        if v.Name ~= LocalPlayer.Name and v.Character then
            pcall(function()
                local hrp = v.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.Size = Vector3.new(HitboxSettings.HeadSize, HitboxSettings.HeadSize, HitboxSettings.HeadSize)
                    hrp.Transparency = HitboxSettings.Transparency
                    hrp.BrickColor = BrickColor.new(HitboxSettings.Color)
                    hrp.Material = "Neon"
                    hrp.CanCollide = false
                end
            end)
        end
    end
end

-- ==================== MAIN TAB ====================
MainTab:CreateSection("🎯 Aimbot Settings")

local AimbotToggle = MainTab:CreateToggle({
    Name = "Enable Aimbot",
    CurrentValue = Settings.AimbotEnabled,
    Flag = "AimbotToggle",
    Callback = function(Value)
        Settings.AimbotEnabled = Value
    end,
})

local TeamCheckToggle = MainTab:CreateToggle({
    Name = "Team Check",
    CurrentValue = Settings.TeamCheck,
    Flag = "TeamCheckToggle",
    Callback = function(Value)
        Settings.TeamCheck = Value
    end,
})

local WallCheckToggle = MainTab:CreateToggle({
    Name = "Wall Check",
    CurrentValue = Settings.WallCheck,
    Flag = "WallCheckToggle",
    Callback = function(Value)
        Settings.WallCheck = Value
    end,
})

local SmoothSlider = MainTab:CreateSlider({
    Name = "Smoothness",
    Range = {1, 50},
    Increment = 1,
    Suffix = "",
    CurrentValue = Settings.Smoothness * 10,
    Flag = "SmoothSlider",
    Callback = function(Value)
        Settings.Smoothness = Value / 10
    end,
})

MainTab:CreateSection("🎯 Triggerbot")

local TriggerbotToggle = MainTab:CreateToggle({
    Name = "Enable Triggerbot",
    CurrentValue = Settings.TriggerbotEnabled,
    Flag = "TriggerbotToggle",
    Callback = function(Value)
        Settings.TriggerbotEnabled = Value
    end,
})

local TriggerKeyDropdown = MainTab:CreateDropdown({
    Name = "Triggerbot Key",
    Options = {"Q", "E", "LeftShift", "F", "V"},
    CurrentOption = Settings.TriggerbotKey,
    Flag = "TriggerKeyDropdown",
    Callback = function(Option)
        Settings.TriggerbotKey = Option
    end,
})

local TriggerDelaySlider = MainTab:CreateSlider({
    Name = "Triggerbot Delay",
    Range = {1, 50},
    Increment = 1,
    Suffix = "ms",
    CurrentValue = Settings.TriggerbotDelay * 100,
    Flag = "TriggerDelaySlider",
    Callback = function(Value)
        Settings.TriggerbotDelay = Value / 100
    end,
})

-- ==================== VISUAL TAB ====================
VisualTab:CreateSection("👁️ ESP Settings")

local ESPToggle = VisualTab:CreateToggle({
    Name = "Enable ESP",
    CurrentValue = Settings.ESPEnabled,
    Flag = "ESPToggle",
    Callback = function(Value)
        Settings.ESPEnabled = Value
        
        if Value then
            for _, p in ipairs(Players:GetPlayers()) do
                AddESP(p)
            end
        else
            for _, p in ipairs(Players:GetPlayers()) do
                RemoveESP(p)
            end
        end
    end,
})

local FOVSlider = VisualTab:CreateSlider({
    Name = "FOV Size",
    Range = {50, 500},
    Increment = 10,
    Suffix = "px",
    CurrentValue = Settings.FOV,
    Flag = "FOVSlider",
    Callback = function(Value)
        Settings.FOV = Value
        FOVCircle.Radius = Value
    end,
})

local ShowFOVToggle = VisualTab:CreateToggle({
    Name = "Show FOV Circle",
    CurrentValue = false,
    Flag = "ShowFOVToggle",
    Callback = function(Value)
        FOVCircle.Visible = Value
    end,
})

local FOVColorPicker = VisualTab:CreateColorPicker({
    Name = "FOV Color",
    Color = Color3.fromRGB(0, 255, 0),
    Flag = "FOVColorPicker",
    Callback = function(Color)
        FOVCircle.Color = Color
    end
})

-- ==================== HITBOX TAB ====================
HitboxTab:CreateSection("🎯 Hitbox Settings")

local HitboxToggle = HitboxTab:CreateToggle({
    Name = "Enable Hitbox",
    CurrentValue = HitboxSettings.Enabled,
    Flag = "HitboxToggle",
    Callback = function(Value)
        HitboxSettings.Enabled = Value
    end,
})

local HeadSizeSlider = HitboxTab:CreateSlider({
    Name = "Head Size",
    Range = {10, 200},
    Increment = 5,
    Suffix = "",
    CurrentValue = HitboxSettings.HeadSize,
    Flag = "HeadSizeSlider",
    Callback = function(Value)
        HitboxSettings.HeadSize = Value
    end,
})

local TransparencySlider = HitboxTab:CreateSlider({
    Name = "Transparency",
    Range = {0, 100},
    Increment = 5,
    Suffix = "%",
    CurrentValue = HitboxSettings.Transparency * 100,
    Flag = "TransparencySlider",
    Callback = function(Value)
        HitboxSettings.Transparency = Value / 100
    end,
})

local ColorDropdown = HitboxTab:CreateDropdown({
    Name = "Hitbox Color",
    Options = {"Really blue", "Bright red", "Lime green", "Bright yellow", "Hot pink", "Bright orange"},
    CurrentOption = HitboxSettings.Color,
    Flag = "ColorDropdown",
    Callback = function(Option)
        HitboxSettings.Color = Option
    end,
})

-- Teks informasi di Hitbox Tab
HitboxTab:CreateSection("ℹ️ Information")
HitboxTab:CreateLabel("Hitbox Script:")
HitboxTab:CreateLabel("Membuat hitbox lebih besar pada musuh")
HitboxTab:CreateLabel("sehingga lebih mudah mengenai target")
HitboxTab:CreateLabel("")
HitboxTab:CreateLabel("Fitur:")
HitboxTab:CreateLabel("- Adjustable head size")
HitboxTab:CreateLabel("- Color customization")
HitboxTab:CreateLabel("- Transparency control")
HitboxTab:CreateLabel("- Neon material effect")

-- ==================== MISC TAB ====================
MiscTab:CreateSection("⚙️ UI Settings")

local UIToggleKey = MiscTab:CreateKeybind({
    Name = "Toggle UI",
    CurrentKeybind = "RightControl",
    HoldToInteract = false,
    Flag = "UIToggleKeybind",
    Callback = function(Key)
        Rayfield:Toggle()
    end,
})

MiscTab:CreateButton({
    Name = "Destroy UI",
    Callback = function()
        Rayfield:Destroy()
        FOVCircle:Remove()
        
        -- Clean up ESP
        for _, player in pairs(Players:GetPlayers()) do
            RemoveESP(player)
        end
    end,
})

MiscTab:CreateSection("📊 Status")

local StatusLabel = MiscTab:CreateLabel("Status: Ready")
local TargetLabel = MiscTab:CreateLabel("Target: None")
local FPSLabel = MiscTab:CreateLabel("FPS: 60")

-- ==================== LOGIC LOOPS ====================

-- Update FOV Circle
RunService.RenderStepped:Connect(function()
    FOVCircle.Position = UserInputService:GetMouseLocation()
    
    -- Update hitboxes
    UpdateHitboxes()
    
    -- Update status
    if Settings.AimbotEnabled then
        local target = GetClosest()
        if target then
            StatusLabel:Set("Status: 🔍 Searching")
            TargetLabel:Set("Target: " .. target.Name)
        else
            StatusLabel:Set("Status: ✅ Active")
            TargetLabel:Set("Target: None")
        end
    else
        StatusLabel:Set("Status: ❌ Disabled")
        TargetLabel:Set("Target: None")
    end
end)

-- Aimbot Logic (dari script universal)
RunService.RenderStepped:Connect(function()
    if Settings.AimbotEnabled and HoldingE then
        local target = GetClosest()
        if target and target.Character and target.Character:FindFirstChild("Head") then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Character.Head.Position)
        end
    end
end)

-- Triggerbot Loop
spawn(function()
    while wait() do
        if Settings.TriggerbotEnabled then
            Triggerbot()
        end
    end
end)

-- Input untuk aim key (E)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.E then
        HoldingE = true
    end
    
    if not gameProcessed and input.KeyCode == Enum.KeyCode[Settings.TriggerbotKey] then
        Settings.TriggerbotEnabled = not Settings.TriggerbotEnabled
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.E then
        HoldingE = false
    end
end)

-- ESP Character Added Support
for _, p in ipairs(Players:GetPlayers()) do
    p.CharacterAdded:Connect(function()
        task.wait(0.2)
        if Settings.ESPEnabled then
            AddESP(p)
        end
    end)
end

Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function()
        task.wait(0.2)
        if Settings.ESPEnabled then
            AddESP(p)
        end
    end)
end)

-- FPS Counter
spawn(function()
    while wait(1) do
        local fps = math.floor(1 / RunService.RenderStepped:Wait())
        FPSLabel:Set("FPS: " .. fps)
    end
end)

-- Notification saat load
Rayfield:Notify({
    Title = "Universal Script Loaded",
    Content = "Made By Witty - Enjoy!",
    Duration = 6.5,
    Image = 4483362458,
})