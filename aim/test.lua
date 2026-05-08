--[[
    Enhanced Aim Assistant with UI
    Features:
    - Master toggle (enables/disables everything)
    - Aim-lock toggle (right-click hold aiming)
    - Trigger-bot toggle (hover + hold left mouse button)
    - Radius slider for aim-lock detection
    - Trigger-bot now holds left click instead of spamming clicks
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local vim = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local camera = workspace.CurrentCamera

-- ========================== CONFIGURATION ==========================
-- These values are adjustable via the UI
local RADIUS = 150
local RIGHT_CLICK_HOLD_TIME = 0.2
local SMOOTHING_FACTOR = 0.3
local PREDICTION_ENABLED = true
local PREDICTION_TIME = 0.2
local TARGET_SWITCH_DELAY = 0.5
local MAX_TARGET_DISTANCE = 300

-- Toggle states (UI controlled)
local masterEnabled = true
local aimlockEnabled = true
local triggerbotEnabled = true

-- Internal variables (do not change)
local lastTarget = nil
local isLeftMouseHeld = false          -- for trigger-bot hold
local isLooking = false
local lookLoopTask = nil
local currentTarget = nil
local targetVelocity = Vector3.new()
local lastTargetPosition = nil
local lastTargetTime = nil
local targetSwitchTimer = 0
local currentSmoothCFrame = nil
local rightClickHeld = false
local rightClickStartTime = 0
local isRightClickActive = false

-- Helper: check if humanoid is alive
local function isHumanoidAlive(humanoid)
    return humanoid and humanoid.Health > 0
end

-- Helper: get humanoid and model from a part
local function getHumanoidFromPart(part)
    if not part then return nil, nil end
    local model = part:FindFirstAncestorOfClass("Model")
    if not model then return nil, nil end
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if humanoid and isHumanoidAlive(humanoid) then
        return humanoid, model
    end
    return nil, nil
end

-- ========================== AIM-LOCK LOGIC (mostly original) ==========================

local function calculateTargetVelocity(targetCharacter)
    if not targetCharacter or not targetCharacter.PrimaryPart then
        return Vector3.new()
    end
    local currentPosition = targetCharacter.PrimaryPart.Position
    local currentTime = tick()
    if lastTargetPosition and lastTargetTime and lastTarget == targetCharacter then
        local deltaTime = currentTime - lastTargetTime
        if deltaTime > 0 and deltaTime < 0.5 then
            local velocity = (currentPosition - lastTargetPosition) / deltaTime
            if velocity.Magnitude > 100 then
                velocity = velocity.Unit * 100
            end
            return velocity
        end
    end
    lastTargetPosition = currentPosition
    lastTargetTime = currentTime
    return Vector3.new()
end

local function getPredictedPosition(targetCharacter, currentPosition)
    if not PREDICTION_ENABLED then
        return currentPosition
    end
    local velocity = calculateTargetVelocity(targetCharacter)
    if velocity.Magnitude > 0.1 then
        local predicted = currentPosition + (velocity * PREDICTION_TIME)
        local dist = (predicted - currentPosition).Magnitude
        if dist > 20 then
            predicted = currentPosition + (velocity.Unit * 20)
        end
        return predicted
    end
    return currentPosition
end

local function lookAtHumanoidEnhanced(targetCharacter)
    if not targetCharacter or not targetCharacter.PrimaryPart then return end
    local targetHumanoid = targetCharacter:FindFirstChildOfClass("Humanoid")
    if not targetHumanoid or not isHumanoidAlive(targetHumanoid) then return end

    local humanoidRootPart = targetCharacter.PrimaryPart
    local character = player.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    if rootPart and humanoidRootPart then
        local currentTargetPos = humanoidRootPart.Position
        local predictedTargetPos = getPredictedPosition(targetCharacter, currentTargetPos)
        local currentPosition = rootPart.Position
        local targetDirection = (predictedTargetPos - currentPosition).Unit
        local targetCFrame = CFrame.new(currentPosition, predictedTargetPos)
        if not currentSmoothCFrame then
            currentSmoothCFrame = targetCFrame
        else
            currentSmoothCFrame = currentSmoothCFrame:Lerp(targetCFrame, SMOOTHING_FACTOR)
        end
        camera.CFrame = currentSmoothCFrame
        local characterTargetCFrame = CFrame.new(rootPart.Position, Vector3.new(predictedTargetPos.X, rootPart.Position.Y, predictedTargetPos.Z))
        rootPart.CFrame = rootPart.CFrame:Lerp(characterTargetCFrame, SMOOTHING_FACTOR * 0.5)
    end
end

local function scoreTarget(character, cursorDistance)
    local score = 0
    local cursorScore = math.max(0, 1 - (cursorDistance / RADIUS))
    score = score + cursorScore * 0.4

    local playerCharacter = player.Character
    local playerRoot = playerCharacter and playerCharacter.PrimaryPart
    local targetRoot = character and character.PrimaryPart
    if playerRoot and targetRoot then
        local distanceToPlayer = (targetRoot.Position - playerRoot.Position).Magnitude
        local distanceScore = math.max(0, 1 - (distanceToPlayer / MAX_TARGET_DISTANCE))
        score = score + distanceScore * 0.3
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        local healthPercent = humanoid.Health / humanoid.MaxHealth
        local healthScore = 1 - healthPercent
        score = score + healthScore * 0.2
    end

    if currentTarget == character then
        score = score + 0.1
    end
    return score
end

local function findBestHumanoidInRadius()
    local bestTarget = nil
    local bestScore = -1
    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= player then
            local character = otherPlayer.Character
            if character and character.PrimaryPart then
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid and isHumanoidAlive(humanoid) then
                    local rootPart = character.PrimaryPart
                    local screenPoint, onScreen = camera:WorldToScreenPoint(rootPart.Position)
                    if onScreen then
                        local cursorPos = Vector2.new(mouse.X, mouse.Y)
                        local distanceFromCursor = (Vector2.new(screenPoint.X, screenPoint.Y) - cursorPos).Magnitude
                        if distanceFromCursor <= RADIUS then
                            local score = scoreTarget(character, distanceFromCursor)
                            if score > bestScore then
                                bestScore = score
                                bestTarget = character
                            end
                        end
                    end
                end
            end
        end
    end
    return bestTarget
end

local function startLookingEnhanced()
    if lookLoopTask then return end
    isLooking = true
    lookLoopTask = task.spawn(function()
        local lastUpdateTime = tick()
        while isLooking and isRightClickActive and masterEnabled and aimlockEnabled do
            local newTarget = findBestHumanoidInRadius()
            if newTarget ~= currentTarget then
                if targetSwitchTimer <= 0 then
                    currentTarget = newTarget
                    targetSwitchTimer = TARGET_SWITCH_DELAY
                    if currentTarget then
                        lastTargetPosition = nil
                        lastTargetTime = nil
                    end
                else
                    targetSwitchTimer = targetSwitchTimer - (tick() - lastUpdateTime)
                end
            else
                targetSwitchTimer = 0
            end
            if currentTarget then
                calculateTargetVelocity(currentTarget)
                lookAtHumanoidEnhanced(currentTarget)
            end
            lastUpdateTime = tick()
            task.wait(0.016)
        end
        currentTarget = nil
        currentSmoothCFrame = nil
        targetSwitchTimer = 0
    end)
end

local function stopLooking()
    isLooking = false
    if lookLoopTask then
        task.cancel(lookLoopTask)
        lookLoopTask = nil
    end
    isRightClickActive = false
    currentTarget = nil
    currentSmoothCFrame = nil
end

-- ========================== TRIGGER-BOT (HOLD LEFT MOUSE) ==========================

-- Simulate holding left mouse button down
local function holdLeftMouse()
    if not isLeftMouseHeld then
        vim:SendMouseButtonEvent(0, 0, 0, true, game, 0)  -- Left button down
        isLeftMouseHeld = true
    end
end

-- Release left mouse button
local function releaseLeftMouse()
    if isLeftMouseHeld then
        vim:SendMouseButtonEvent(0, 0, 0, false, game, 0) -- Left button up
        isLeftMouseHeld = false
    end
end

-- This replaces the old click loop: no timer, just hold while hovering
local function onHoverStart()
    if not masterEnabled or not triggerbotEnabled then return end
    holdLeftMouse()
end

local function onHoverEnd()
    releaseLeftMouse()
end

-- ========================== RIGHT-CLICK AIM-LOCK ACTIVATION ==========================

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        rightClickHeld = true
        rightClickStartTime = tick()
        task.wait(RIGHT_CLICK_HOLD_TIME)
        if rightClickHeld and masterEnabled and aimlockEnabled then
            isRightClickActive = true
            startLookingEnhanced()
        end
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        rightClickHeld = false
        stopLooking()
    end
end)

-- ========================== HOVER DETECTION (for trigger-bot) ==========================

RunService.RenderStepped:Connect(function()
    if not masterEnabled then
        -- If master off, ensure left mouse is released and no aiming
        if isLeftMouseHeld then releaseLeftMouse() end
        return
    end

    local targetPart = mouse.Target
    local humanoid, character = getHumanoidFromPart(targetPart)

    if humanoid and character and character ~= player.Character and isHumanoidAlive(humanoid) then
        if lastTarget ~= character then
            lastTarget = character
            onHoverStart()
        end
    else
        if lastTarget ~= nil then
            lastTarget = nil
            onHoverEnd()
        end
    end
end)

-- ========================== UI CREATION ==========================

local function createUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AimAssistantUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = player:WaitForChild("PlayerGui")

    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 250, 0, 200)
    mainFrame.Position = UDim2.new(0, 10, 0, 10)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    mainFrame.BackgroundTransparency = 0.1
    mainFrame.BorderSizePixel = 0
    mainFrame.ClipsDescendants = true
    mainFrame.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = mainFrame

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 30)
    title.Text = "Aim Assistant"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.Parent = mainFrame

    -- Master Toggle
    local masterToggle = Instance.new("TextButton")
    masterToggle.Size = UDim2.new(0, 120, 0, 30)
    masterToggle.Position = UDim2.new(0, 10, 0, 40)
    masterToggle.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
    masterToggle.Text = "Master: ON"
    masterToggle.TextColor3 = Color3.new(1,1,1)
    masterToggle.Font = Enum.Font.Gotham
    masterToggle.TextSize = 14
    masterToggle.Parent = mainFrame
    local masterCorner = Instance.new("UICorner")
    masterCorner.CornerRadius = UDim.new(0, 4)
    masterCorner.Parent = masterToggle

    masterToggle.MouseButton1Click:Connect(function()
        masterEnabled = not masterEnabled
        masterToggle.Text = masterEnabled and "Master: ON" or "Master: OFF"
        masterToggle.BackgroundColor3 = masterEnabled and Color3.fromRGB(0,200,0) or Color3.fromRGB(200,0,0)
        if not masterEnabled then
            -- Stop any ongoing actions
            releaseLeftMouse()
            stopLooking()
            lastTarget = nil
            isRightClickActive = false
        end
    end)

    -- Aim-lock Toggle
    local aimlockToggle = Instance.new("TextButton")
    aimlockToggle.Size = UDim2.new(0, 120, 0, 30)
    aimlockToggle.Position = UDim2.new(0, 140, 0, 40)
    aimlockToggle.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
    aimlockToggle.Text = "Aim-lock: ON"
    aimlockToggle.TextColor3 = Color3.new(1,1,1)
    aimlockToggle.Font = Enum.Font.Gotham
    aimlockToggle.TextSize = 14
    aimlockToggle.Parent = mainFrame
    local aimCorner = Instance.new("UICorner")
    aimCorner.CornerRadius = UDim.new(0, 4)
    aimCorner.Parent = aimlockToggle

    aimlockToggle.MouseButton1Click:Connect(function()
        aimlockEnabled = not aimlockEnabled
        aimlockToggle.Text = aimlockEnabled and "Aim-lock: ON" or "Aim-lock: OFF"
        aimlockToggle.BackgroundColor3 = aimlockEnabled and Color3.fromRGB(0,200,0) or Color3.fromRGB(200,0,0)
        if not aimlockEnabled then
            stopLooking()
        end
    end)

    -- Trigger-bot Toggle
    local triggerToggle = Instance.new("TextButton")
    triggerToggle.Size = UDim2.new(0, 120, 0, 30)
    triggerToggle.Position = UDim2.new(0, 10, 0, 80)
    triggerToggle.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
    triggerToggle.Text = "Trigger: ON"
    triggerToggle.TextColor3 = Color3.new(1,1,1)
    triggerToggle.Font = Enum.Font.Gotham
    triggerToggle.TextSize = 14
    triggerToggle.Parent = mainFrame
    local trigCorner = Instance.new("UICorner")
    trigCorner.CornerRadius = UDim.new(0, 4)
    trigCorner.Parent = triggerToggle

    triggerToggle.MouseButton1Click:Connect(function()
        triggerbotEnabled = not triggerbotEnabled
        triggerToggle.Text = triggerbotEnabled and "Trigger: ON" or "Trigger: OFF"
        triggerToggle.BackgroundColor3 = triggerbotEnabled and Color3.fromRGB(0,200,0) or Color3.fromRGB(200,0,0)
        if not triggerbotEnabled then
            releaseLeftMouse()
        end
    end)

    -- Radius Slider
    local radiusLabel = Instance.new("TextLabel")
    radiusLabel.Size = UDim2.new(0, 100, 0, 20)
    radiusLabel.Position = UDim2.new(0, 10, 0, 120)
    radiusLabel.Text = "Radius: " .. RADIUS
    radiusLabel.TextColor3 = Color3.new(1,1,1)
    radiusLabel.BackgroundTransparency = 1
    radiusLabel.Font = Enum.Font.Gotham
    radiusLabel.TextSize = 12
    radiusLabel.Parent = mainFrame

    local radiusSlider = Instance.new("Frame")
    radiusSlider.Size = UDim2.new(0, 120, 0, 4)
    radiusSlider.Position = UDim2.new(0, 110, 0, 128)
    radiusSlider.BackgroundColor3 = Color3.fromRGB(80,80,80)
    radiusSlider.BorderSizePixel = 0
    radiusSlider.Parent = mainFrame

    local sliderFill = Instance.new("Frame")
    sliderFill.Size = UDim2.new((RADIUS - 50) / 250, 0, 1, 0)  -- range 50-300 -> 250 range
    sliderFill.BackgroundColor3 = Color3.fromRGB(0,200,255)
    sliderFill.BorderSizePixel = 0
    sliderFill.Parent = radiusSlider

    local sliderButton = Instance.new("TextButton")
    sliderButton.Size = UDim2.new(0, 12, 0, 12)
    sliderButton.Position = UDim2.new((RADIUS - 50) / 250, -6, 0.5, -6)
    sliderButton.BackgroundColor3 = Color3.fromRGB(255,255,255)
    sliderButton.Text = ""
    sliderButton.AutoButtonColor = false
    sliderButton.Parent = radiusSlider
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(1, 0)
    btnCorner.Parent = sliderButton

    local dragging = false
    local function updateRadius(input)
        local relativeX = math.clamp((input.Position.X - radiusSlider.AbsolutePosition.X) / radiusSlider.AbsoluteSize.X, 0, 1)
        local newRadius = math.floor(50 + relativeX * 250)  -- range 50 to 300
        RADIUS = newRadius
        radiusLabel.Text = "Radius: " .. RADIUS
        sliderFill.Size = UDim2.new(relativeX, 0, 1, 0)
        sliderButton.Position = UDim2.new(relativeX, -6, 0.5, -6)
    end

    sliderButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            updateRadius(input)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateRadius(input)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    -- Optional: small visual indicator for radius (replaces old one)
    local function createRadiusIndicator()
        local indicatorGui = Instance.new("ScreenGui")
        indicatorGui.Name = "RadiusIndicator"
        indicatorGui.Parent = player.PlayerGui
        local circle = Instance.new("Frame")
        circle.Size = UDim2.new(0, RADIUS*2, 0, RADIUS*2)
        circle.Position = UDim2.new(0, mouse.X - RADIUS, 0, mouse.Y - RADIUS)
        circle.BackgroundTransparency = 0.85
        circle.BackgroundColor3 = Color3.new(1,0,0)
        circle.BorderSizePixel = 2
        circle.BorderColor3 = Color3.new(1,1,1)
        circle.Active = false
        circle.Parent = indicatorGui
        local dot = Instance.new("Frame")
        dot.Size = UDim2.new(0,4,0,4)
        dot.Position = UDim2.new(0.5,-2,0.5,-2)
        dot.BackgroundColor3 = Color3.new(1,1,1)
        dot.BackgroundTransparency = 0.5
        dot.BorderSizePixel = 0
        dot.Parent = circle
        RunService.RenderStepped:Connect(function()
            if not masterEnabled then
                circle.Visible = false
                return
            end
            circle.Visible = true
            if isRightClickActive and currentTarget then
                circle.BackgroundColor3 = Color3.new(0,1,0)
                circle.BackgroundTransparency = 0.7
                dot.BackgroundTransparency = 0
            elseif isRightClickActive then
                circle.BackgroundColor3 = Color3.new(1,1,0)
                circle.BackgroundTransparency = 0.8
                dot.BackgroundTransparency = 0.3
            else
                circle.BackgroundColor3 = Color3.new(1,0,0)
                circle.BackgroundTransparency = 0.85
                dot.BackgroundTransparency = 0.7
            end
            circle.Position = UDim2.new(0, mouse.X - RADIUS, 0, mouse.Y - RADIUS)
            circle.Size = UDim2.new(0, RADIUS*2, 0, RADIUS*2)
        end)
    end
    createRadiusIndicator()
end

-- Initialize UI
createUI()

print("=== Enhanced Aim Assistant with UI Loaded ===")
print("Trigger-bot now HOLDS left mouse button while hovering.")
print("Use the UI in the top-left corner to adjust settings.")
