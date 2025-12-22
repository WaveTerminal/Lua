-- Teleport to All Brainrots
-- This script will work immediately

-- Поиск рабочего пространства Brainrots
local function teleportToAllBrainrots()
    -- Получить игрока
    local player = game.Players.LocalPlayer
    if not player then return end
    
    -- Дождитесь появления персонажа
    local character = player.Character
    if not character then
        character = player.CharacterAdded:Wait()
    end
    
    -- Wait for HumanoidRootPart
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    
    -- Search ब्रेनरोट्स फ़ोल्डर
    local brainrotsFolder = workspace:FindFirstChild("Brainrots")
    if not brainrotsFolder then
        warn("Brainrots folder not found!")
        return
    end
    
    -- 脑残
    local brainrots = brainrotsFolder:GetChildren()
    if #brainrots == 0 then
        warn("No Brainrot found!")
        return
    end
    
    print("Starting teleport to " .. #brainrots .. " Brainrots...")
    
    -- Loop through all brainrot
    for i, brainrot in ipairs(brainrots) do
        -- Get the brainrot position
        local position = brainrot:GetPivot().Position
        local targetCFrame = CFrame.new(position.X, position.Y + 3, position.Z)
        
        -- Teleport directly 没有缓动
        humanoidRootPart.CFrame = targetCFrame
        
        -- Wait a moment
        wait(0.5)
        
        print("Teleport ke Brainrot " .. i .. ": " .. brainrot.Name)
    end
    
    print("Selesai! Telah mengunjungi semua " .. #brainrots .. " Brainrots")
end

-- UI Rayfield
local success, Rayfield = pcall(function()
    return loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
end)

if success and Rayfield then
    -- Made window
    local Window = Rayfield:CreateWindow({
        Name = "Brainrot Teleporter",
        LoadingTitle = "Loading...",
        LoadingSubtitle = "By Witty"
    })
    
    -- Create tab
    local MainTab = Window:CreateTab("Main", 4483362458)
    
    -- Section teleport
    MainTab:CreateSection("Teleport Options")
    
    -- Teleport all button
    MainTab:CreateButton({
        Name = "Teleport to All Brainrots",
        Callback = function()
            teleportToAllBrainrots()
        end
    })
    
    -- Brainrot check button
    MainTab:CreateButton({
        Name = "Check the Number of Brainrots",
        Callback = function()
            local brainrotsFolder = workspace:FindFirstChild("Brainrots")
            if brainrotsFolder then
                local count = #brainrotsFolder:GetChildren()
                Rayfield:Notify({
                    Title = "Info",
                    Content = "Number of Brainrots: " .. count,
                    Duration = 3
                })
            else
                Rayfield:Notify({
                    Title = "Error",
                    Content = "Brainrots folder not found!",
                    Duration = 3
                })
            end
        end
    })
    
    print("UI Brainrot Teleporter successfully loaded!")
else
    -- If Rayfield fails, create a simple UI with text buttons
    print("Creating a simple UI...")
    
    -- Create ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "BrainrotTeleporterUI"
    screenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
    
    -- Create a main frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 300, 0, 200)
    mainFrame.Position = UDim2.new(0.5, -150, 0.5, -100)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    
    -- For title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.Text = "Brainrot Teleporter"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 20
    title.Parent = mainFrame
    
    -- Create a teleport button
    local teleportButton = Instance.new("TextButton")
    teleportButton.Size = UDim2.new(0.8, 0, 0, 50)
    teleportButton.Position = UDim2.new(0.1, 0, 0.3, 0)
    teleportButton.Text = "TELEPORT TO ALL BRAINROTS"
    teleportButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    teleportButton.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
    teleportButton.Font = Enum.Font.GothamBold
    teleportButton.TextSize = 16
    teleportButton.Parent = mainFrame
    
    -- Function when button is clicked
    teleportButton.MouseButton1Click:Connect(function()
        teleportToAllBrainrots()
    end)
    
    -- Create a close button
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0.8, 0, 0, 40)
    closeButton.Position = UDim2.new(0.1, 0, 0.7, 0)
    closeButton.Text = "CLOSED UI"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    closeButton.Font = Enum.Font.GothamBold
    closeButton.TextSize = 14
    closeButton.Parent = mainFrame
    
    closeButton.MouseButton1Click:Connect(function()
        screenGui:Destroy()
    end)
    
    print("Simple UI successfully created!")
end

-- Run auto-teleport if desired
-- Uncomment the following to auto-teleport:
-- teleportToAllBrainrots()
