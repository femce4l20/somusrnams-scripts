local PlayerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- =============================================
-- PROTECTED TOOLS — these are NEVER dropped
-- =============================================
local PROTECTED_TOOLS = {
    "RainbowPeriastron",
    "GalaxyPeriastron",
    "CrimsonPeriastron",
    "IvoryPeriastron",
    "ChartreusePeriastron",
}

local function isProtected(name)
    for _, n in ipairs(PROTECTED_TOOLS) do
        if n == name then return true end
    end
    return false
end

-- =============================================
-- GUI CONSTRUCTION
-- =============================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "LuckyBlockGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

-- Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.BackgroundColor3 = Color3.fromRGB(14, 14, 22)
MainFrame.BorderSizePixel = 0
MainFrame.Position = UDim2.new(0, 60, 0, 120)
MainFrame.Size = UDim2.new(0, 340, 0, 250)
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(110, 50, 200)
MainStroke.Thickness = 2
MainStroke.Parent = MainFrame

-- ---- Title Bar ----
local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.BackgroundColor3 = Color3.fromRGB(26, 16, 46)
TitleBar.BorderSizePixel = 0
TitleBar.Size = UDim2.new(1, 0, 0, 42)
TitleBar.ZIndex = 5
TitleBar.Parent = MainFrame

-- Patch round corners only on top
local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 12)
TitleCorner.Parent = TitleBar

local TitlePatch = Instance.new("Frame") -- fills in the bottom two corners
TitlePatch.BackgroundColor3 = Color3.fromRGB(26, 16, 46)
TitlePatch.BorderSizePixel = 0
TitlePatch.Position = UDim2.new(0, 0, 0.55, 0)
TitlePatch.Size = UDim2.new(1, 0, 0.5, 0)
TitlePatch.ZIndex = 5
TitlePatch.Parent = TitleBar

-- Icon label
local IconLabel = Instance.new("TextLabel")
IconLabel.BackgroundTransparency = 1
IconLabel.Position = UDim2.new(0, 10, 0, 0)
IconLabel.Size = UDim2.new(0, 30, 1, 0)
IconLabel.Font = Enum.Font.GothamBold
IconLabel.Text = "✨"
IconLabel.TextScaled = true
IconLabel.ZIndex = 6
IconLabel.Parent = TitleBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.BackgroundTransparency = 1
TitleLabel.Position = UDim2.new(0, 44, 0, 0)
TitleLabel.Size = UDim2.new(1, -130, 1, 0)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.Text = "Lucky Block Farm"
TitleLabel.TextColor3 = Color3.fromRGB(210, 170, 255)
TitleLabel.TextScaled = true
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.ZIndex = 6
TitleLabel.Parent = TitleBar

-- Minimize Button
local MinimizeButton = Instance.new("TextButton")
MinimizeButton.BackgroundColor3 = Color3.fromRGB(230, 185, 40)
MinimizeButton.Position = UDim2.new(1, -74, 0.5, -11)
MinimizeButton.Size = UDim2.new(0, 22, 0, 22)
MinimizeButton.Font = Enum.Font.GothamBold
MinimizeButton.Text = "–"
MinimizeButton.TextColor3 = Color3.fromRGB(60, 40, 0)
MinimizeButton.TextScaled = true
MinimizeButton.ZIndex = 7
MinimizeButton.Parent = TitleBar

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(1, 0)
MinCorner.Parent = MinimizeButton

-- Close Button
local CloseButton = Instance.new("TextButton")
CloseButton.BackgroundColor3 = Color3.fromRGB(210, 55, 55)
CloseButton.Position = UDim2.new(1, -40, 0.5, -11)
CloseButton.Size = UDim2.new(0, 22, 0, 22)
CloseButton.Font = Enum.Font.GothamBold
CloseButton.Text = "✕"
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.TextScaled = true
CloseButton.ZIndex = 7
CloseButton.Parent = TitleBar

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(1, 0)
CloseCorner.Parent = CloseButton

-- ---- Content Frame ----
local ContentFrame = Instance.new("Frame")
ContentFrame.Name = "ContentFrame"
ContentFrame.BackgroundTransparency = 1
ContentFrame.Position = UDim2.new(0, 0, 0, 42)
ContentFrame.Size = UDim2.new(1, 0, 1, -42)
ContentFrame.Parent = MainFrame

-- Section label: "Single Spawn"
local SingleLabel = Instance.new("TextLabel")
SingleLabel.BackgroundTransparency = 1
SingleLabel.Position = UDim2.new(0.05, 0, 0.02, 0)
SingleLabel.Size = UDim2.new(0.9, 0, 0.12, 0)
SingleLabel.Font = Enum.Font.Gotham
SingleLabel.Text = "SINGLE SPAWN"
SingleLabel.TextColor3 = Color3.fromRGB(120, 100, 160)
SingleLabel.TextScaled = true
SingleLabel.TextXAlignment = Enum.TextXAlignment.Left
SingleLabel.Parent = ContentFrame

-- Rainbow Button
local RainbowButton = Instance.new("TextButton")
RainbowButton.BackgroundColor3 = Color3.fromRGB(55, 22, 88)
RainbowButton.Position = UDim2.new(0.05, 0, 0.15, 0)
RainbowButton.Size = UDim2.new(0.43, 0, 0.24, 0)
RainbowButton.Font = Enum.Font.GothamBold
RainbowButton.Text = "🌈  Rainbow"
RainbowButton.TextColor3 = Color3.fromRGB(240, 190, 255)
RainbowButton.TextScaled = true
RainbowButton.Parent = ContentFrame

local RainbowCorner = Instance.new("UICorner")
RainbowCorner.CornerRadius = UDim.new(0, 8)
RainbowCorner.Parent = RainbowButton

local RainbowStroke = Instance.new("UIStroke")
RainbowStroke.Color = Color3.fromRGB(170, 70, 255)
RainbowStroke.Thickness = 1.5
RainbowStroke.Parent = RainbowButton

-- Galaxy Button
local GalaxyButton = Instance.new("TextButton")
GalaxyButton.BackgroundColor3 = Color3.fromRGB(14, 22, 66)
GalaxyButton.Position = UDim2.new(0.52, 0, 0.15, 0)
GalaxyButton.Size = UDim2.new(0.43, 0, 0.24, 0)
GalaxyButton.Font = Enum.Font.GothamBold
GalaxyButton.Text = "🌌  Galaxy"
GalaxyButton.TextColor3 = Color3.fromRGB(140, 200, 255)
GalaxyButton.TextScaled = true
GalaxyButton.Parent = ContentFrame

local GalaxyCorner = Instance.new("UICorner")
GalaxyCorner.CornerRadius = UDim.new(0, 8)
GalaxyCorner.Parent = GalaxyButton

local GalaxyStroke = Instance.new("UIStroke")
GalaxyStroke.Color = Color3.fromRGB(50, 110, 255)
GalaxyStroke.Thickness = 1.5
GalaxyStroke.Parent = GalaxyButton

-- Divider
local Divider = Instance.new("Frame")
Divider.BackgroundColor3 = Color3.fromRGB(55, 40, 80)
Divider.BorderSizePixel = 0
Divider.Position = UDim2.new(0.05, 0, 0.42, 0)
Divider.Size = UDim2.new(0.9, 0, 0, 1)
Divider.Parent = ContentFrame

-- Section label: "Auto Farm"
local AutoLabel = Instance.new("TextLabel")
AutoLabel.BackgroundTransparency = 1
AutoLabel.Position = UDim2.new(0.05, 0, 0.44, 0)
AutoLabel.Size = UDim2.new(0.9, 0, 0.12, 0)
AutoLabel.Font = Enum.Font.Gotham
AutoLabel.Text = "AUTO FARM  (Rainbow + Galaxy)"
AutoLabel.TextColor3 = Color3.fromRGB(120, 100, 160)
AutoLabel.TextScaled = true
AutoLabel.TextXAlignment = Enum.TextXAlignment.Left
AutoLabel.Parent = ContentFrame

-- Auto Farm Button (merged)
local AutoFarmButton = Instance.new("TextButton")
AutoFarmButton.BackgroundColor3 = Color3.fromRGB(48, 18, 78)
AutoFarmButton.Position = UDim2.new(0.05, 0, 0.57, 0)
AutoFarmButton.Size = UDim2.new(0.9, 0, 0.24, 0)
AutoFarmButton.Font = Enum.Font.GothamBold
AutoFarmButton.Text = "🤖  Start Auto Farm"
AutoFarmButton.TextColor3 = Color3.fromRGB(210, 170, 255)
AutoFarmButton.TextScaled = true
AutoFarmButton.Parent = ContentFrame

local AutoFarmCorner = Instance.new("UICorner")
AutoFarmCorner.CornerRadius = UDim.new(0, 8)
AutoFarmCorner.Parent = AutoFarmButton

local AutoFarmStroke = Instance.new("UIStroke")
AutoFarmStroke.Color = Color3.fromRGB(130, 55, 215)
AutoFarmStroke.Thickness = 1.5
AutoFarmStroke.Parent = AutoFarmButton

-- Status Label
local StatusLabel = Instance.new("TextLabel")
StatusLabel.BackgroundColor3 = Color3.fromRGB(10, 10, 18)
StatusLabel.Position = UDim2.new(0.05, 0, 0.84, 0)
StatusLabel.Size = UDim2.new(0.9, 0, 0.13, 0)
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.Text = "Idle"
StatusLabel.TextColor3 = Color3.fromRGB(160, 150, 190)
StatusLabel.TextScaled = true
StatusLabel.Parent = ContentFrame

local StatusCorner = Instance.new("UICorner")
StatusCorner.CornerRadius = UDim.new(0, 6)
StatusCorner.Parent = StatusLabel

local StatusStroke = Instance.new("UIStroke")
StatusStroke.Color = Color3.fromRGB(50, 45, 70)
StatusStroke.Thickness = 1
StatusStroke.Parent = StatusLabel

-- =============================================
-- HELPER FUNCTIONS
-- =============================================
local function waitWithDrift(minTime, maxTime)
    task.wait(minTime + math.random() * (maxTime - minTime))
end

local function getInventoryTools()
    local tools = {}
    for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
        if tool:IsA("Tool") then
            table.insert(tools, tool.Name)
        end
    end
    if LocalPlayer.Character then
        local heldTool = LocalPlayer.Character:FindFirstChildWhichIsA("Tool")
        if heldTool then
            table.insert(tools, heldTool.Name)
        end
    end
    return tools
end

-- Drops every non-protected tool in backpack and character
local function dropUnprotectedTools()
    for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
        if tool:IsA("Tool") and not isProtected(tool.Name) then
            tool.Parent = workspace
        end
    end
    if LocalPlayer.Character then
        local heldTool = LocalPlayer.Character:FindFirstChildWhichIsA("Tool")
        if heldTool and not isProtected(heldTool.Name) then
            heldTool.Parent = workspace
        end
    end
end

local function setStatus(text, r, g, b)
    StatusLabel.Text = text
    StatusLabel.TextColor3 = Color3.fromRGB(r, g, b)
end

-- =============================================
-- AUTO FARM  (Rainbow + Galaxy merged)
-- =============================================
local autoFarmRunning = false
local autoFarmThread = nil

local function startAutoFarm()
    if autoFarmThread then
        task.cancel(autoFarmThread)
    end

    autoFarmRunning = true
    AutoFarmButton.Text = "⏹  Stop Auto Farm"
    AutoFarmButton.BackgroundColor3 = Color3.fromRGB(90, 18, 18)
    AutoFarmStroke.Color = Color3.fromRGB(200, 50, 50)

    autoFarmThread = task.spawn(function()
        while autoFarmRunning do
            -- Inventory snapshot
            local toolSet = {}
            for _, n in ipairs(getInventoryTools()) do
                toolSet[n] = true
            end

            local hasRainbow    = toolSet["RainbowPeriastron"]    == true
            local hasCrimson    = toolSet["CrimsonPeriastron"]    == true
            local hasIvory      = toolSet["IvoryPeriastron"]      == true
            local hasChartreuse = toolSet["ChartreusePeriastron"] == true

            local needRainbow = not hasRainbow
            local needGalaxy  = not (hasCrimson and hasIvory and hasChartreuse)

            -- Done?
            if not needRainbow and not needGalaxy then
                setStatus("🎉 All targets found! Cleaning up...", 100, 255, 140)
                dropUnprotectedTools()
                task.wait(1.2)
                setStatus("✅ Farm complete!", 100, 255, 140)
                autoFarmRunning = false
                break
            end

            -- Build a short readable status
            local rainbowMark = hasRainbow and "🌈✓" or "🌈…"
            local galaxyMark  = "🌌(" ..
                (hasCrimson    and "C" or "·") ..
                (hasIvory      and "I" or "·") ..
                (hasChartreuse and "Ch" or "··") .. ")"

            local burstSize = math.random(5, 8)
            setStatus("Farming " .. rainbowMark .. "  " .. galaxyMark .. " ×" .. burstSize, 180, 140, 255)

            for i = 1, burstSize do
                if not autoFarmRunning then break end

                if needRainbow and needGalaxy then
                    -- Alternate between both types
                    if i % 2 == 1 then
                        ReplicatedStorage.SpawnRainbowBlock:FireServer()
                    else
                        ReplicatedStorage.SpawnGalaxyBlock:FireServer()
                    end
                elseif needRainbow then
                    ReplicatedStorage.SpawnRainbowBlock:FireServer()
                else
                    ReplicatedStorage.SpawnGalaxyBlock:FireServer()
                end

                waitWithDrift(0.3, 0.6)
            end

            waitWithDrift(3, 6)
        end

        -- Restore UI after stop or completion
        autoFarmRunning = false
        AutoFarmButton.Text = "🤖  Start Auto Farm"
        AutoFarmButton.BackgroundColor3 = Color3.fromRGB(48, 18, 78)
        AutoFarmStroke.Color = Color3.fromRGB(130, 55, 215)
        if StatusLabel.Text ~= "✅ Farm complete!" then
            setStatus("Idle", 160, 150, 190)
        end
    end)
end

local function stopAutoFarm()
    autoFarmRunning = false
    if autoFarmThread then
        task.cancel(autoFarmThread)
        autoFarmThread = nil
    end
    AutoFarmButton.Text = "🤖  Start Auto Farm"
    AutoFarmButton.BackgroundColor3 = Color3.fromRGB(48, 18, 78)
    AutoFarmStroke.Color = Color3.fromRGB(130, 55, 215)
    setStatus("Idle", 160, 150, 190)
end

-- =============================================
-- BUTTON CONNECTIONS
-- =============================================
RainbowButton.MouseButton1Click:Connect(function()
    ReplicatedStorage.SpawnRainbowBlock:FireServer()
    setStatus("Spawned Rainbow Block", 230, 180, 255)
    task.delay(1.5, function()
        if not autoFarmRunning then
            setStatus("Idle", 160, 150, 190)
        end
    end)
end)

GalaxyButton.MouseButton1Click:Connect(function()
    ReplicatedStorage.SpawnGalaxyBlock:FireServer()
    setStatus("Spawned Galaxy Block", 130, 195, 255)
    task.delay(1.5, function()
        if not autoFarmRunning then
            setStatus("Idle", 160, 150, 190)
        end
    end)
end)

AutoFarmButton.MouseButton1Click:Connect(function()
    if autoFarmRunning then
        stopAutoFarm()
    else
        startAutoFarm()
    end
end)

-- =============================================
-- MINIMIZE & CLOSE
-- =============================================
local minimized = false
local FULL_HEIGHT = 250
local MINI_HEIGHT = 42

MinimizeButton.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        ContentFrame.Visible = false
        MainFrame.Size = UDim2.new(0, 340, 0, MINI_HEIGHT)
        MinimizeButton.Text = "□"
    else
        ContentFrame.Visible = true
        MainFrame.Size = UDim2.new(0, 340, 0, FULL_HEIGHT)
        MinimizeButton.Text = "–"
    end
end)

CloseButton.MouseButton1Click:Connect(function()
    stopAutoFarm()
    ScreenGui:Destroy()
end)

-- =============================================
-- DRAGGING  (title bar only, offset-based)
-- =============================================
local dragging = false
local dragStartPos   -- Vector2: mouse position at drag start
local frameStartPos  -- UDim2: frame position at drag start

TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStartPos = Vector2.new(input.Position.X, input.Position.Y)
        frameStartPos = MainFrame.Position
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = Vector2.new(input.Position.X, input.Position.Y) - dragStartPos
        MainFrame.Position = UDim2.new(
            frameStartPos.X.Scale,
            frameStartPos.X.Offset + delta.X,
            frameStartPos.Y.Scale,
            frameStartPos.Y.Offset + delta.Y
        )
    end
end)
