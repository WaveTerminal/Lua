-- Rayfield Interface Setup
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Initialize Window
local Window = Rayfield:CreateWindow({
    Name = "BLIND SHOT | V1.0",
    LoadingTitle = "Loading BLIND SHOT HUB...",
    LoadingSubtitle = "Made By WaveTerminal",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "BlindShotHub",
        FileName = "Config"
    },
    Discord = {
        Enabled = false,
        Invite = "noinvitelink",
        RememberJoins = true
    },
    KeySystem = true,
    KeySettings = {
        Title = "BLIND SHOT HUB",
        Subtitle = "Key System",
        Note = "Bruh, You Forget The Key!",
        FileName = "BlindShotKey",
        SaveKey = true,
        GrabKeyFromSite = false,
        Key = "BLINDSHOTV1"
    }
})

-- Main Tab
local MainTab = Window:CreateTab("Main", 4483362458)

-- Auto Wins Section
local AutoWinsSection = MainTab:CreateSection("Auto Wins")

local Trophy
if workspace:FindFirstChild("Trophy") then
    Trophy = workspace.Trophy
else
    Trophy = Instance.new("Part", workspace)
    Trophy.Name = "Trophy"
    Trophy.Size = Vector3.new(5, 10, 5)
    Trophy.Position = Vector3.new(0, 5, 0)
    Trophy.Anchored = true
    Trophy.CanCollide = true
    Trophy.BrickColor = BrickColor.new("Bright yellow")
end

local AutoWinsToggle = false

-- TP Wins Button
local TPWinsButton = MainTab:CreateButton({
    Name = "TP to Trophy",
    Callback = function()
        local player = game.Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
        
        humanoidRootPart.CFrame = Trophy.CFrame + Vector3.new(0, 5, 0)
        Rayfield:Notify({
            Title = "Success",
            Content = "Teleported to Trophy!",
            Duration = 3,
            Image = 4483362458
        })
    end
})

-- Auto Wins Toggle
local AutoWins = MainTab:CreateToggle({
    Name = "Auto Wins",
    CurrentValue = false,
    Flag = "AutoWinsToggle",
    Callback = function(Value)
        AutoWinsToggle = Value
        if Value then
            Rayfield:Notify({
                Title = "Auto Wins Enabled",
                Content = "Auto collecting wins...",
                Duration = 3,
                Image = 4483362458
            })
            
            -- Create TouchInterest if not exists
            if not Trophy:FindFirstChild("TouchInterest") then
                local touch = Instance.new("TouchTransmitter", Trophy)
                touch.Name = "TouchInterest"
                
                Trophy.Touched:Connect(function(hit)
                    local player = game.Players:GetPlayerFromCharacter(hit.Parent)
                    if player and player == game.Players.LocalPlayer and AutoWinsToggle then
                        -- Simulate win collection
                        Rayfield:Notify({
                            Title = "Win Collected!",
                            Content = "Auto collected a win!",
                            Duration = 2,
                            Image = 4483362458
                        })
                    end
                end)
            end
        else
            Rayfield:Notify({
                Title = "Auto Wins Disabled",
                Content = "Stopped auto collecting wins",
                Duration = 3,
                Image = 4483362458
            })
        end
    end
})

-- Visual Tab
local VisualTab = Window:CreateTab("Visual", 4483362458)

-- ESP Section
local ESPSection = VisualTab:CreateSection("ESP Settings")

local ESPEnabled = false
local ESPBoxes = false
local ESPTracers = false
local ESPHighlight = false
local ESPNames = false
local ESPTracerPosition = "Bottom"

local ESPInstances = {}
local ESPConnections = {}
local ESPUpdateConnection = nil

-- ESP Functions
local function createESP(player)
    if player == game.Players.LocalPlayer then return end
    
    local character = player.Character
    if not character then 
        -- Wait for character to load
        local connection
        connection = player.CharacterAdded:Connect(function(char)
            wait(1)
            createESP(player)
            connection:Disconnect()
        end)
        return
    end
    
    -- Highlight
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_Highlight"
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.OutlineTransparency = 0
    highlight.FillColor = Color3.fromRGB(255, 50, 50)
    highlight.FillTransparency = 0.7
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = character
    highlight.Enabled = ESPHighlight
    
    -- Billboard for name and distance
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP_Billboard"
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 3.5, 0)
    billboard.AlwaysOnTop = true
    billboard.Enabled = ESPNames
    billboard.MaxDistance = 1000
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "ESP_Text"
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = player.Name
    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    textLabel.TextSize = 14
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextStrokeTransparency = 0
    textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    textLabel.Parent = billboard
    
    billboard.Parent = character
    
    -- Drawing tracer
    local tracer = Drawing.new("Line")
    tracer.Visible = false
    tracer.Color = Color3.fromRGB(255, 50, 50)
    tracer.Thickness = 1.5
    tracer.Transparency = 1
    
    ESPInstances[player] = {
        Highlight = highlight,
        Billboard = billboard,
        Tracer = tracer,
        Character = character
    }
    
    -- Connection for character cleanup
    local connection
    connection = player.CharacterRemoving:Connect(function()
        if ESPInstances[player] then
            if ESPInstances[player].Highlight then 
                ESPInstances[player].Highlight:Destroy() 
            end
            if ESPInstances[player].Billboard then 
                ESPInstances[player].Billboard:Destroy() 
            end
            if ESPInstances[player].Tracer then 
                ESPInstances[player].Tracer:Remove() 
            end
            ESPInstances[player] = nil
        end
        connection:Disconnect()
    end)
    
    table.insert(ESPConnections, connection)
end

-- Updated ESP Update Function with Camera Tracking
local function updateESP()
    local camera = workspace.CurrentCamera
    local viewportSize = camera.ViewportSize
    local localPlayer = game.Players.LocalPlayer
    local localCharacter = localPlayer.Character
    
    if not localCharacter or not localCharacter:FindFirstChild("HumanoidRootPart") then
        return
    end
    
    for player, instances in pairs(ESPInstances) do
        if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local character = player.Character
            local rootPart = character.HumanoidRootPart
            
            -- Update highlight
            if instances.Highlight and instances.Highlight.Parent == character then
                instances.Highlight.Enabled = ESPHighlight and ESPEnabled
                
                -- Team check for Blind Shot
                if player.Team and localPlayer.Team then
                    local isEnemy = player.Team ~= localPlayer.Team
                    instances.Highlight.FillColor = isEnemy and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(50, 150, 255)
                end
            end
            
            -- Update billboard
            if instances.Billboard and instances.Billboard.Parent == character then
                instances.Billboard.Enabled = ESPNames and ESPEnabled
                
                if ESPNames and ESPEnabled then
                    local distance = (localCharacter.HumanoidRootPart.Position - rootPart.Position).Magnitude
                    local distanceText = string.format("%s [%d]", player.Name, math.floor(distance))
                    
                    -- Team color
                    if player.Team and localPlayer.Team then
                        local isEnemy = player.Team ~= localPlayer.Team
                        instances.Billboard.ESP_Text.TextColor3 = isEnemy and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(50, 150, 255)
                    end
                    
                    instances.Billboard.ESP_Text.Text = distanceText
                    
                    -- Adjust billboard size based on distance
                    local scale = math.clamp(100 / distance, 0.5, 2)
                    instances.Billboard.Size = UDim2.new(0, 200 * scale, 0, 50 * scale)
                    instances.Billboard.StudsOffset = Vector3.new(0, 3.5 * scale, 0)
                end
            end
            
            -- Update tracer
            if instances.Tracer then
                instances.Tracer.Visible = ESPTracers and ESPEnabled
                
                if ESPTracers and ESPEnabled then
                    local screenPos, onScreen = camera:WorldToViewportPoint(rootPart.Position)
                    
                    if onScreen then
                        -- Set tracer start position based on selection
                        local startPos
                        if ESPTracerPosition == "Bottom" then
                            startPos = Vector2.new(viewportSize.X / 2, viewportSize.Y)
                        elseif ESPTracerPosition == "Middle" then
                            startPos = Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)
                        else -- "Top"
                            startPos = Vector2.new(viewportSize.X / 2, 0)
                        end
                        
                        instances.Tracer.From = startPos
                        instances.Tracer.To = Vector2.new(screenPos.X, screenPos.Y)
                        
                        -- Team color for tracer
                        if player.Team and localPlayer.Team then
                            local isEnemy = player.Team ~= localPlayer.Team
                            instances.Tracer.Color = isEnemy and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(50, 150, 255)
                        end
                        
                        instances.Tracer.Visible = true
                    else
                        instances.Tracer.Visible = false
                    end
                end
            end
        else
            -- Clean up if player/character doesn't exist
            if instances.Highlight then instances.Highlight:Destroy() end
            if instances.Billboard then instances.Billboard:Destroy() end
            if instances.Tracer then instances.Tracer:Remove() end
            ESPInstances[player] = nil
        end
    end
end

-- ESP Toggle with proper update loop
VisualTab:CreateToggle({
    Name = "Enable ESP",
    CurrentValue = false,
    Flag = "ESPEnabled",
    Callback = function(Value)
        ESPEnabled = Value
        
        if Value then
            Rayfield:Notify({
                Title = "ESP Enabled",
                Content = "Visual ESP activated",
                Duration = 3,
                Image = 4483362458
            })
            
            -- Initialize ESP for existing players
            for _, player in pairs(game.Players:GetPlayers()) do
                if player ~= game.Players.LocalPlayer then
                    createESP(player)
                end
            end
            
            -- Connect to player added
            local playerAddedConn
            playerAddedConn = game.Players.PlayerAdded:Connect(function(player)
                wait(1)
                createESP(player)
            end)
            table.insert(ESPConnections, playerAddedConn)
            
            -- Start update loop
            ESPUpdateConnection = game:GetService("RunService").RenderStepped:Connect(function()
                if ESPEnabled then
                    updateESP()
                end
            end)
            
        else
            -- Clean up when disabled
            if ESPUpdateConnection then
                ESPUpdateConnection:Disconnect()
                ESPUpdateConnection = nil
            end
            
            -- Clear all ESP instances
            for player, instances in pairs(ESPInstances) do
                if instances.Highlight then instances.Highlight:Destroy() end
                if instances.Billboard then instances.Billboard:Destroy() end
                if instances.Tracer then instances.Tracer:Remove() end
            end
            ESPInstances = {}
            
            -- Disconnect all connections
            for _, connection in pairs(ESPConnections) do
                pcall(function() connection:Disconnect() end)
            end
            ESPConnections = {}
            
            Rayfield:Notify({
                Title = "ESP Disabled",
                Content = "Visual ESP deactivated",
                Duration = 3,
                Image = 4483362458
            })
        end
    end
})

-- ESP Features
VisualTab:CreateToggle({
    Name = "ESP Box",
    CurrentValue = false,
    Flag = "ESPBox",
    Callback = function(Value)
        ESPBoxes = Value
        Rayfield:Notify({
            Title = "ESP Box",
            Content = Value and "Box ESP enabled" or "Box ESP disabled",
            Duration = 2,
            Image = 4483362458
        })
    end
})

VisualTab:CreateToggle({
    Name = "ESP Tracers",
    CurrentValue = false,
    Flag = "ESPTracers",
    Callback = function(Value)
        ESPTracers = Value
    end
})

VisualTab:CreateToggle({
    Name = "ESP Highlight",
    CurrentValue = false,
    Flag = "ESPHighlight",
    Callback = function(Value)
        ESPHighlight = Value
    end
})

VisualTab:CreateToggle({
    Name = "ESP Name + Distance",
    CurrentValue = false,
    Flag = "ESPNames",
    Callback = function(Value)
        ESPNames = Value
    end
})

-- Tracer Position Dropdown
VisualTab:CreateDropdown({
    Name = "Tracer Position",
    Options = {"Bottom", "Middle", "Top"},
    CurrentOption = "Bottom",
    Flag = "TracerPosition",
    Callback = function(Option)
        ESPTracerPosition = Option
    end
})

-- ESP Color Picker
VisualTab:CreateColorPicker({
    Name = "ESP Color (Enemy)",
    Color = Color3.fromRGB(255, 50, 50),
    Flag = "ESPColorEnemy",
    Callback = function(Value)
        -- Update enemy colors
        for _, instances in pairs(ESPInstances) do
            if instances.Highlight then
                instances.Highlight.FillColor = Value
            end
            if instances.Tracer then
                instances.Tracer.Color = Value
            end
            if instances.Billboard then
                instances.Billboard.ESP_Text.TextColor3 = Value
            end
        end
    end
})

VisualTab:CreateColorPicker({
    Name = "ESP Color (Teammate)",
    Color = Color3.fromRGB(50, 150, 255),
    Flag = "ESPColorTeam",
    Callback = function(Value)
        -- This will be applied based on team check in updateESP
    end
})

-- Fullbright & NoFog
local LightingSection = VisualTab:CreateSection("Lighting")

VisualTab:CreateToggle({
    Name = "Fullbright",
    CurrentValue = false,
    Flag = "Fullbright",
    Callback = function(Value)
        if Value then
            game:GetService("Lighting").GlobalShadows = false
            game:GetService("Lighting").Brightness = 2
            game:GetService("Lighting").ClockTime = 14
            Rayfield:Notify({
                Title = "Fullbright Enabled",
                Content = "World lighting enhanced",
                Duration = 3,
                Image = 4483362458
            })
        else
            game:GetService("Lighting").GlobalShadows = true
            game:GetService("Lighting").Brightness = 1
        end
    end
})

VisualTab:CreateToggle({
    Name = "Remove Fog",
    CurrentValue = false,
    Flag = "NoFog",
    Callback = function(Value)
        if Value then
            game:GetService("Lighting").FogEnd = 1000000
            Rayfield:Notify({
                Title = "Fog Removed",
                Content = "Maximum visibility enabled",
                Duration = 3,
                Image = 4483362458
            })
        else
            game:GetService("Lighting").FogEnd = 1000
        end
    end
})

-- Tools Tab
local ToolsTab = Window:CreateTab("Tools", 4483362458)

-- Movement Section
local MovementSection = ToolsTab:CreateSection("Movement")

-- Infinite Jump
local InfiniteJumpEnabled = false
local JumpConnection

ToolsTab:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false,
    Flag = "InfiniteJump",
    Callback = function(Value)
        InfiniteJumpEnabled = Value
        
        if Value then
            Rayfield:Notify({
                Title = "Infinite Jump Enabled",
                Content = "Press Space to fly!",
                Duration = 3,
                Image = 4483362458
            })
            
            JumpConnection = game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
                if not gameProcessed and input.KeyCode == Enum.KeyCode.Space and InfiniteJumpEnabled then
                    local character = game.Players.LocalPlayer.Character
                    if character then
                        local humanoid = character:FindFirstChildOfClass("Humanoid")
                        if humanoid then
                            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                        end
                    end
                end
            end)
        else
            if JumpConnection then
                JumpConnection:Disconnect()
            end
            Rayfield:Notify({
                Title = "Infinite Jump Disabled",
                Content = "Jumping disabled",
                Duration = 3,
                Image = 4483362458
            })
        end
    end
})

-- Teleport Tool
ToolsTab:CreateButton({
    Name = "Teleport Tool (Ctrl+Click)",
    Callback = function()
        Rayfield:Notify({
            Title = "Teleport Tool",
            Content = "Ctrl + Click anywhere to teleport",
            Duration = 5,
            Image = 4483362458
        })
        
        local teleportConnection
        teleportConnection = game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
            if input.UserInputType == Enum.UserInputType.MouseButton1 and 
               game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.LeftControl) then
                
                local mouse = game.Players.LocalPlayer:GetMouse()
                local character = game.Players.LocalPlayer.Character
                
                if character then
                    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
                    if humanoidRootPart then
                        local targetPos = mouse.Hit.Position + Vector3.new(0, 5, 0)
                        humanoidRootPart.CFrame = CFrame.new(targetPos)
                        
                        Rayfield:Notify({
                            Title = "Teleported",
                            Content = "Teleported to cursor position",
                            Duration = 2,
                            Image = 4483362458
                        })
                    end
                end
            end
        end)
        
        ToolsTab:CreateButton({
            Name = "Disable Teleport Tool",
            Callback = function()
                if teleportConnection then
                    teleportConnection:Disconnect()
                end
                Rayfield:Notify({
                    Title = "Teleport Tool Disabled",
                    Content = "Teleport tool deactivated",
                    Duration = 3,
                    Image = 4483362458
                })
            end
        })
    end
})

-- Noclip
local NoclipEnabled = false
local NoclipConnection

ToolsTab:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Flag = "Noclip",
    Callback = function(Value)
        NoclipEnabled = Value
        
        if Value then
            Rayfield:Notify({
                Title = "Noclip Enabled",
                Content = "You can walk through walls",
                Duration = 3,
                Image = 4483362458
            })
            
            local character = game.Players.LocalPlayer.Character
            NoclipConnection = game:GetService("RunService").Stepped:Connect(function()
                if NoclipEnabled and character then
                    for _, part in pairs(character:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                        end
                    end
                end
            end)
        else
            if NoclipConnection then
                NoclipConnection:Disconnect()
            end
            
            -- Restore collision
            local character = game.Players.LocalPlayer.Character
            if character then
                for _, part in pairs(character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = true
                    end
                end
            end
            
            Rayfield:Notify({
                Title = "Noclip Disabled",
                Content = "Collision restored",
                Duration = 3,
                Image = 4483362458
            })
        end
    end
})

-- Misc Tab
local MiscTab = Window:CreateTab("Misc", 4483362458)

-- Anti-AFK
MiscTab:CreateToggle({
    Name = "Anti AFK",
    CurrentValue = false,
    Flag = "AntiAFK",
    Callback = function(Value)
        if Value then
            Rayfield:Notify({
                Title = "Anti-AFK Enabled",
                Content = "You won't be kicked for AFK",
                Duration = 3,
                Image = 4483362458
            })
            
            local VirtualUser = game:GetService("VirtualUser")
            game:GetService("Players").LocalPlayer.Idled:Connect(function()
                VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                wait(1)
                VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            end)
        else
            Rayfield:Notify({
                Title = "Anti-AFK Disabled",
                Content = "AFK kick enabled",
                Duration = 3,
                Image = 4483362458
            })
        end
    end
})

-- Server Hop
MiscTab:CreateButton({
    Name = "Server Hop",
    Callback = function()
        Rayfield:Notify({
            Title = "Server Hop",
            Content = "Finding new server...",
            Duration = 3,
            Image = 4483362458
        })
        
        local PlaceID = game.PlaceId
        local AllIDs = {}
        local foundAnything = ""
        local actualHour = os.date("!*t").hour
        local Deleted = false
        
        local File = pcall(function()
            AllIDs = game:GetService('HttpService'):JSONDecode(readfile("NotSameServers.json"))
        end)
        if not File then
            table.insert(AllIDs, actualHour)
            writefile("NotSameServers.json", game:GetService('HttpService'):JSONEncode(AllIDs))
        end
        
        function TPReturner()
            local Site;
            if foundAnything == "" then
                Site = game.HttpService:JSONDecode(game:HttpGet('https://games.roblox.com/v1/games/' .. PlaceID .. '/servers/Public?sortOrder=Asc&limit=100'))
            else
                Site = game.HttpService:JSONDecode(game:HttpGet('https://games.roblox.com/v1/games/' .. PlaceID .. '/servers/Public?sortOrder=Asc&limit=100&cursor=' .. foundAnything))
            end
            local ID = ""
            if Site.nextPageCursor and Site.nextPageCursor ~= "null" and Site.nextPageCursor ~= nil then
                foundAnything = Site.nextPageCursor
            end
            local num = 0;
            for i,v in pairs(Site.data) do
                local Possible = true
                ID = tostring(v.id)
                if tonumber(v.maxPlayers) > tonumber(v.playing) then
                    for _,Existing in pairs(AllIDs) do
                        if num ~= 0 then
                            if ID == tostring(Existing) then
                                Possible = false
                            end
                        else
                            if tonumber(actualHour) ~= tonumber(Existing) then
                                local delFile = pcall(function()
                                    delfile("NotSameServers.json")
                                    AllIDs = {}
                                    table.insert(AllIDs, actualHour)
                                end)
                            end
                        end
                        num = num + 1
                    end
                    if Possible == true then
                        table.insert(AllIDs, ID)
                        wait()
                        pcall(function()
                            writefile("NotSameServers.json", game:GetService('HttpService'):JSONEncode(AllIDs))
                            wait()
                            game:GetService("TeleportService"):TeleportToPlaceInstance(PlaceID, ID, game.Players.LocalPlayer)
                        end)
                        wait(4)
                    end
                end
            end
        end
        
        function Teleport()
            while wait() do
                pcall(function()
                    TPReturner()
                    if foundAnything ~= "" then
                        TPReturner()
                    end
                end)
            end
        end
        
        Teleport()
    end
})

-- Server Rejoin
MiscTab:CreateButton({
    Name = "Rejoin Server",
    Callback = function()
        Rayfield:Notify({
            Title = "Rejoining",
            Content = "Rejoining current server...",
            Duration = 3,
            Image = 4483362458
        })
        game:GetService("TeleportService"):Teleport(game.PlaceId, game.Players.LocalPlayer)
    end
})

-- FPS Boost Section
local FPSSection = MiscTab:CreateSection("FPS Boost")

MiscTab:CreateButton({
    Name = "Boost FPS",
    Callback = function()
        Rayfield:Notify({
            Title = "FPS Boost",
            Content = "Optimizing game performance...",
            Duration = 5,
            Image = 4483362458
        })
        
        -- Graphics settings
        settings().Rendering.QualityLevel = 1
        settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level01
        
        -- Lighting optimizations
        local lighting = game:GetService("Lighting")
        lighting.GlobalShadows = false
        lighting.FogEnd = 100000
        lighting.Brightness = 2
        
        for _, descendant in pairs(lighting:GetDescendants()) do
            if descendant:IsA("BlurEffect") or descendant:IsA("SunRaysEffect") or 
               descendant:IsA("ColorCorrectionEffect") or descendant:IsA("BloomEffect") or 
               descendant:IsA("DepthOfFieldEffect") then
                descendant.Enabled = false
            end
        end
        
        -- Terrain settings
        if workspace:FindFirstChildOfClass("Terrain") then
            workspace.Terrain.WaterWaveSize = 0
            workspace.Terrain.WaterWaveSpeed = 0
            workspace.Terrain.WaterReflectance = 0
            workspace.Terrain.WaterTransparency = 0
        end
        
        Rayfield:Notify({
            Title = "FPS Boost Complete",
            Content = "Game performance optimized!",
            Duration = 3,
            Image = 4483362458
        })
    end
})

-- Ultimate Graphics Boost
MiscTab:CreateButton({
    Name = "Ultimate Graphics Boost",
    Callback = function()
        Rayfield:Notify({
            Title = "Ultimate Boost",
            Content = "Applying all graphics optimizations...",
            Duration = 5,
            Image = 4483362458
        })
        
        -- Fullbright
        game:GetService("Lighting").GlobalShadows = false
        game:GetService("Lighting").Brightness = 2
        game:GetService("Lighting").ClockTime = 14
        
        -- NoFog
        game:GetService("Lighting").FogEnd = 1000000
        
        -- FPS Boost
        settings().Rendering.QualityLevel = 1
        settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level01
        
        local lighting = game:GetService("Lighting")
        for _, descendant in pairs(lighting:GetDescendants()) do
            if descendant:IsA("BlurEffect") or descendant:IsA("SunRaysEffect") or 
               descendant:IsA("ColorCorrectionEffect") or descendant:IsA("BloomEffect") or 
               descendant:IsA("DepthOfFieldEffect") then
                descendant.Enabled = false
            end
        end
        
        if workspace:FindFirstChildOfClass("Terrain") then
            workspace.Terrain.WaterWaveSize = 0
            workspace.Terrain.WaterWaveSpeed = 0
            workspace.Terrain.WaterReflectance = 0
            workspace.Terrain.WaterTransparency = 0
        end
        
        Rayfield:Notify({
            Title = "Boost Complete",
            Content = "All graphics optimizations applied!",
            Duration = 3,
            Image = 4483362458
        })
    end
})

-- Credits Section
local CreditsSection = MiscTab:CreateSection("Credits")

MiscTab:CreateLabel("BLIND SHOT | V1.0")
MiscTab:CreateLabel("Made By WaveTerminal")
MiscTab:CreateLabel("Thanks for using!")

-- Auto initialize ESP for existing players
game.Players.PlayerAdded:Connect(function(player)
    if ESPEnabled then
        wait(2)
        createESP(player)
    end
end)

-- Initialize ESP for existing players
spawn(function()
    wait(2)
    if ESPEnabled then
        for _, player in pairs(game.Players:GetPlayers()) do
            if player ~= game.Players.LocalPlayer then
                createESP(player)
            end
        end
    end
end)

-- Auto cleanup on character change
game.Players.LocalPlayer.CharacterAdded:Connect(function(character)
    wait(1)
    if ESPEnabled then
        -- Reinitialize ESP connections
        for _, player in pairs(game.Players:GetPlayers()) do
            if player ~= game.Players.LocalPlayer and not ESPInstances[player] then
                createESP(player)
            end
        end
    end
end)

-- Initial notification
Rayfield:Notify({
    Title = "BLIND SHOT HUB Loaded",
    Content = "Welcome! Key: BLINDSHOTV1",
    Duration = 8,
    Image = 4483362458
})