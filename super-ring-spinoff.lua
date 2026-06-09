local player = game.Players.LocalPlayer
local workspace = game:GetService("Workspace")
local runService = game:GetService("RunService")
local userInputService = game:GetService("UserInputService")
local camera = workspace.CurrentCamera

-- Localize math
local math_cos = math.cos
local math_sin = math.sin
local math_pi = math.pi
local math_clamp = math.clamp
local math_round = math.round
local Vector3_new = Vector3.new

-- Network ownership trick
player.ReplicationFocus = workspace
pcall(function()
    sethiddenproperty(player, "SimulationRadius", math.huge)
end)

-- ========== SWITCHES ==========
local enabled = true
local mode = "circle"   -- "circle" or "mouse"

-- ========== SETTINGS ==========
local function getOrDefaultAttribute(attrName, defaultValue)
    local current = player:GetAttribute(attrName)
    if current == nil then
        player:SetAttribute(attrName, defaultValue)
        return defaultValue
    end
    return current
end

local settings = {
    Radius = getOrDefaultAttribute("CircleRadius", 20),
    HeightOffset = getOrDefaultAttribute("CircleHeightOffset", 15),
    PullSpeed = getOrDefaultAttribute("CirclePullSpeed", 80)
}

-- ========== CHARACTER & MOUSE ==========
local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")
local mouseHitPos = Vector3_new(0, 0, 0)

-- ========== PART TRACKING ==========
local partsList = {}
local partAngles = {}
local partCount = 0
local lastPartCount = 0
local orbitAngle = 0

-- Reusable table for raycast blacklist (avoids GC)
local raycastFilterList = {}

-- Dynamic radius (circle mode)
local function getDynamicRadius(count)
    local base = settings.Radius
    if count <= 2 then
        return math.min(base * 2.5, 50)
    elseif count <= 5 then
        return math.min(base * 1.8, 45)
    else
        return base
    end
end

local function getSpinSpeed()
    return settings.PullSpeed / 40
end

-- Fast check: part belongs to local character?
local function isPartOfCharacter(part)
    local p = part.Parent
    while p do
        if p == character then return true end
        p = p.Parent
    end
    return false
end

-- Add / remove parts
local function addPart(part)
    if not part or not part.Parent then return end
    if part.Anchored then return end
    if partAngles[part] then return end
    if isPartOfCharacter(part) then return end
    part.CanCollide = false
    table.insert(partsList, part)
    partCount = partCount + 1
end

local function removePart(part)
    local idx = table.find(partsList, part)
    if idx then
        table.remove(partsList, idx)
        partAngles[part] = nil
        partCount = partCount - 1
    end
end

local function redistributeAngles()
    local count = partCount
    if count == 0 then return end
    local angleStep = (2 * math_pi) / count
    for i = 1, count do
        local part = partsList[i]
        partAngles[part] = angleStep * (i - 1)
    end
    lastPartCount = count
end

-- Initial scan: deferred and chunked to avoid freezing on load
local function scanWorkspace()
    task.defer(function()
        local descendants = workspace:GetDescendants()
        local CHUNK = 200
        for i = 1, #descendants, CHUNK do
            for j = i, math.min(i + CHUNK - 1, #descendants) do
                local obj = descendants[j]
                if obj:IsA("BasePart") and not obj.Anchored and not isPartOfCharacter(obj) then
                    obj.CanCollide = false
                    table.insert(partsList, obj)
                    partCount = partCount + 1
                end
            end
            task.wait()
        end
        redistributeAngles()
    end)
end
scanWorkspace()

-- Dynamic updates
workspace.DescendantAdded:Connect(function(desc)
    if desc:IsA("BasePart") and not desc.Anchored and not isPartOfCharacter(desc) and not partAngles[desc] then
        desc.CanCollide = false
        table.insert(partsList, desc)
        partCount = partCount + 1
        redistributeAngles()
    end
end)

workspace.DescendantRemoving:Connect(function(desc)
    if partAngles[desc] then
        removePart(desc)
        redistributeAngles()
    end
end)

player.CharacterAdded:Connect(function(newChar)
    character = newChar
    rootPart = character:WaitForChild("HumanoidRootPart")
    for i = #partsList, 1, -1 do
        if isPartOfCharacter(partsList[i]) then
            table.remove(partsList, i)
            partCount = partCount - 1
        end
    end
    redistributeAngles()
end)

-- ========== RAYCAST (attempts to ignore controlled parts & character) ==========
local function updateMouseHitPos()
    local mousePos = userInputService:GetMouseLocation()
    local ray = camera:ViewportPointToRay(mousePos.X, mousePos.Y)

    -- Build blacklist: character + all controlled parts
    -- Reuse raycastFilterList table to avoid allocations
    for i = 1, #raycastFilterList do
        raycastFilterList[i] = nil
    end
    table.insert(raycastFilterList, character)
    for i = 1, partCount do
        table.insert(raycastFilterList, partsList[i])
    end

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = raycastFilterList

    local hit = workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
    if hit then
        mouseHitPos = hit.Position
    else
        -- Fallback: 20 studs in front of character
        local cf = rootPart.CFrame
        mouseHitPos = cf.Position + cf.LookVector * 20
    end
end

-- ========== UI ==========
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CircleConfigUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 220, 0, 170)
mainFrame.Position = UDim2.new(0.5, -110, 0.5, -85)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
mainFrame.BackgroundTransparency = 0.15
mainFrame.BorderSizePixel = 1
mainFrame.BorderColor3 = Color3.fromRGB(100, 100, 120)
mainFrame.Parent = screenGui

-- Title bar
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 25)
titleBar.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
titleBar.BackgroundTransparency = 0.1
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(1, -110, 1, 0)
titleText.Position = UDim2.new(0, 5, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "⚙️ Circle/Mouse"
titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
titleText.TextSize = 14
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Font = Enum.Font.Gotham
titleText.Parent = titleBar

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 25, 1, 0)
closeBtn.Position = UDim2.new(1, -25, 0, 0)
closeBtn.BackgroundTransparency = 1
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
closeBtn.TextSize = 14
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = titleBar
closeBtn.MouseButton1Click:Connect(function()
    screenGui.Enabled = false
end)

-- Master ON/OFF
local masterButton = Instance.new("TextButton")
masterButton.Size = UDim2.new(0, 55, 0, 22)
masterButton.Position = UDim2.new(1, -85, 0, 2)
masterButton.BackgroundColor3 = Color3.fromRGB(70, 130, 70)
masterButton.TextColor3 = Color3.fromRGB(255, 255, 255)
masterButton.TextSize = 11
masterButton.Font = Enum.Font.GothamBold
masterButton.Text = "ON"
masterButton.BorderSizePixel = 1
masterButton.BorderColor3 = Color3.fromRGB(100, 100, 100)
masterButton.Parent = titleBar

masterButton.MouseButton1Click:Connect(function()
    enabled = not enabled
    masterButton.BackgroundColor3 = enabled and Color3.fromRGB(70, 130, 70) or Color3.fromRGB(130, 70, 70)
    masterButton.Text = enabled and "ON" or "OFF"
end)

-- Mode toggle
local modeButton = Instance.new("TextButton")
modeButton.Size = UDim2.new(0, 55, 0, 22)
modeButton.Position = UDim2.new(1, -145, 0, 2)
modeButton.BackgroundColor3 = Color3.fromRGB(70, 70, 130)
modeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
modeButton.TextSize = 11
modeButton.Font = Enum.Font.GothamBold
modeButton.Text = "Mouse"
modeButton.BorderSizePixel = 1
modeButton.BorderColor3 = Color3.fromRGB(100, 100, 100)
modeButton.Parent = titleBar

modeButton.MouseButton1Click:Connect(function()
    if mode == "circle" then
        mode = "mouse"
        modeButton.Text = "Circle"
        modeButton.BackgroundColor3 = Color3.fromRGB(130, 70, 70)
    else
        mode = "circle"
        modeButton.Text = "Mouse"
        modeButton.BackgroundColor3 = Color3.fromRGB(70, 70, 130)
    end
end)

-- Sliders
local radiusLabel = Instance.new("TextLabel")
radiusLabel.Size = UDim2.new(1, -10, 0, 20)
radiusLabel.Position = UDim2.new(0, 5, 0, 32)
radiusLabel.BackgroundTransparency = 1
radiusLabel.Text = "Radius: 20"
radiusLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
radiusLabel.TextSize = 12
radiusLabel.TextXAlignment = Enum.TextXAlignment.Left
radiusLabel.Font = Enum.Font.Gotham
radiusLabel.Parent = mainFrame

local radiusSlider = Instance.new("TextButton")
radiusSlider.Size = UDim2.new(0, 150, 0, 4)
radiusSlider.Position = UDim2.new(0, 5, 0, 54)
radiusSlider.BackgroundColor3 = Color3.fromRGB(70, 70, 90)
radiusSlider.BorderSizePixel = 0
radiusSlider.AutoButtonColor = false
radiusSlider.Parent = mainFrame

local sliderFill = Instance.new("Frame")
sliderFill.Size = UDim2.new(0.5, 0, 1, 0)
sliderFill.BackgroundColor3 = Color3.fromRGB(255, 200, 100)
sliderFill.BorderSizePixel = 0
sliderFill.Parent = radiusSlider

local heightLabel = Instance.new("TextLabel")
heightLabel.Size = UDim2.new(1, -10, 0, 20)
heightLabel.Position = UDim2.new(0, 5, 0, 62)
heightLabel.BackgroundTransparency = 1
heightLabel.Text = "Height: 15"
heightLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
heightLabel.TextSize = 12
heightLabel.TextXAlignment = Enum.TextXAlignment.Left
heightLabel.Font = Enum.Font.Gotham
heightLabel.Parent = mainFrame

local heightSlider = Instance.new("TextButton")
heightSlider.Size = UDim2.new(0, 150, 0, 4)
heightSlider.Position = UDim2.new(0, 5, 0, 84)
heightSlider.BackgroundColor3 = Color3.fromRGB(70, 70, 90)
heightSlider.BorderSizePixel = 0
heightSlider.AutoButtonColor = false
heightSlider.Parent = mainFrame

local heightFill = Instance.new("Frame")
heightFill.Size = UDim2.new(0.5, 0, 1, 0)
heightFill.BackgroundColor3 = Color3.fromRGB(255, 200, 100)
heightFill.BorderSizePixel = 0
heightFill.Parent = heightSlider

local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(1, -10, 0, 20)
speedLabel.Position = UDim2.new(0, 5, 0, 92)
speedLabel.BackgroundTransparency = 1
speedLabel.Text = "Speed: 80"
speedLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
speedLabel.TextSize = 12
speedLabel.TextXAlignment = Enum.TextXAlignment.Left
speedLabel.Font = Enum.Font.Gotham
speedLabel.Parent = mainFrame

local speedSlider = Instance.new("TextButton")
speedSlider.Size = UDim2.new(0, 150, 0, 4)
speedSlider.Position = UDim2.new(0, 5, 0, 114)
speedSlider.BackgroundColor3 = Color3.fromRGB(70, 70, 90)
speedSlider.BorderSizePixel = 0
speedSlider.AutoButtonColor = false
speedSlider.Parent = mainFrame

local speedFill = Instance.new("Frame")
speedFill.Size = UDim2.new(0.5, 0, 1, 0)
speedFill.BackgroundColor3 = Color3.fromRGB(255, 200, 100)
speedFill.BorderSizePixel = 0
speedFill.Parent = speedSlider

local function updateSliderFill(sliderFillObj, value, minVal, maxVal)
    sliderFillObj.Size = UDim2.new((value - minVal) / (maxVal - minVal), 0, 1, 0)
end

local function makeSlider(sliderButton, fillFrame, labelObj, settingName, minVal, maxVal, step)
    local dragging = false
    sliderButton.MouseButton1Down:Connect(function()
        dragging = true
    end)
    userInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    sliderButton.MouseMoved:Connect(function()
        if dragging then
            local mousePos = userInputService:GetMouseLocation()
            local absPos = sliderButton.AbsolutePosition
            local width = sliderButton.AbsoluteSize.X
            local relative = (mousePos.X - absPos.X) / width
            local newVal = math_clamp(minVal + relative * (maxVal - minVal), minVal, maxVal)
            if step then
                newVal = math_round(newVal / step) * step
            end
            settings[settingName] = newVal
            player:SetAttribute("Circle" .. settingName, newVal)
            labelObj.Text = settingName .. ": " .. tostring(newVal)
            updateSliderFill(fillFrame, newVal, minVal, maxVal)
        end
    end)
    updateSliderFill(fillFrame, settings[settingName], minVal, maxVal)
    labelObj.Text = settingName .. ": " .. tostring(settings[settingName])
end

makeSlider(radiusSlider, sliderFill, radiusLabel, "Radius", 5, 40, 1)
makeSlider(heightSlider, heightFill, heightLabel, "HeightOffset", -35, 35, 1)
makeSlider(speedSlider, speedFill, speedLabel, "PullSpeed", 30, 200, 5)

-- UI dragging
local dragStartPos, frameStartPos
local draggingFrame = false
titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingFrame = true
        dragStartPos = input.Position
        frameStartPos = mainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                draggingFrame = false
            end
        end)
    end
end)
userInputService.InputChanged:Connect(function(input)
    if draggingFrame and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStartPos
        mainFrame.Position = UDim2.new(
            frameStartPos.X.Scale,
            frameStartPos.X.Offset + delta.X,
            frameStartPos.Y.Scale,
            frameStartPos.Y.Offset + delta.Y
        )
    end
end)

-- ========== MAIN LOOP ==========
local circleCenter = Vector3_new()
local directionVec = Vector3_new()
local targetPos = Vector3_new()

runService.Heartbeat:Connect(function(deltaTime)
    if not enabled then return end
    if not rootPart or not rootPart.Parent then return end
    if partCount == 0 then return end

    if mode == "circle" then
        -- Circle mode: dynamic radius + spin
        orbitAngle = orbitAngle + getSpinSpeed() * deltaTime
        orbitAngle = orbitAngle % (2 * math_pi)

        local dynamicR = getDynamicRadius(partCount)
        local center = rootPart.Position
        circleCenter = Vector3_new(center.X, center.Y + settings.HeightOffset, center.Z)

        for i = 1, partCount do
            local part = partsList[i]
            if part and part.Parent and not part.Anchored then
                if isPartOfCharacter(part) then
                    removePart(part)
                    redistributeAngles()
                    i = i - 1
                else
                    local personalAngle = partAngles[part]
                    if personalAngle then
                        local finalAngle = personalAngle + orbitAngle
                        targetPos = Vector3_new(
                            circleCenter.X + dynamicR * math_cos(finalAngle),
                            circleCenter.Y,
                            circleCenter.Z + dynamicR * math_sin(finalAngle)
                        )
                        directionVec = (targetPos - part.Position).Unit
                        part.Velocity = directionVec * settings.PullSpeed
                    end
                end
            else
                removePart(part)
                redistributeAngles()
                i = i - 1
            end
        end

    else -- mouse mode
        -- Update mouse hit position (raycast attempts to ignore controlled parts)
        updateMouseHitPos()

        local forcedR = 5
        for i = 1, partCount do
            local part = partsList[i]
            if part and part.Parent and not part.Anchored then
                if isPartOfCharacter(part) then
                    removePart(part)
                    redistributeAngles()
                    i = i - 1
                else
                    local personalAngle = partAngles[part]
                    if personalAngle then
                        targetPos = Vector3_new(
                            mouseHitPos.X + forcedR * math_cos(personalAngle),
                            mouseHitPos.Y,
                            mouseHitPos.Z + forcedR * math_sin(personalAngle)
                        )
                        directionVec = (targetPos - part.Position).Unit
                        part.Velocity = directionVec * settings.PullSpeed
                    end
                end
            else
                removePart(part)
                redistributeAngles()
                i = i - 1
            end
        end
    end
end)
