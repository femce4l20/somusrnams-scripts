loadstring(game:HttpGet('https://api.luarmor.net/files/v3/loaders/49f02b0d8c1f60207c84ae76e12abc1e.lua'))()

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

-- === STATE ===
local selectedTools = {}   -- [toolName] = true/false, persists across refreshes
local toolButtons = {}
local activated = false

-- === THEME ===
local THEME = {
    bg          = Color3.fromRGB(15, 15, 20),
    panel       = Color3.fromRGB(22, 22, 30),
    titleBar    = Color3.fromRGB(28, 28, 40),
    accent      = Color3.fromRGB(99, 102, 241),   -- indigo
    accentHover = Color3.fromRGB(129, 132, 255),
    selected    = Color3.fromRGB(79, 209, 127),   -- green
    unequip     = Color3.fromRGB(239, 68, 68),    -- red
    btnIdle     = Color3.fromRGB(35, 35, 50),
    btnHover    = Color3.fromRGB(48, 48, 68),
    textPrimary = Color3.fromRGB(240, 240, 255),
    textMuted   = Color3.fromRGB(130, 130, 160),
    scrollBar   = Color3.fromRGB(99, 102, 241),
    border      = Color3.fromRGB(50, 50, 70),
    refresh     = Color3.fromRGB(59, 130, 246),
}

-- === HELPERS ===
local function Lerp(a, b, m) return a + (b - a) * m end

local function tween(obj, props, t, style, dir)
    local info = TweenInfo.new(t or 0.15, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out)
    TweenService:Create(obj, info, props):Play()
end

local function addCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 10)
    c.Parent = parent
    return c
end

local function addStroke(parent, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or THEME.border
    s.Thickness = thickness or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

-- === GUI ROOT ===
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ToolEquipGuiV2"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = game.CoreGui

-- === MAIN FRAME ===
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 240, 0, 360)
MainFrame.Position = UDim2.new(0.38, 0, 0.22, 0)
MainFrame.BackgroundColor3 = THEME.bg
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui
addCorner(MainFrame, 14)
addStroke(MainFrame, THEME.border, 1.5)

-- Drop shadow
local Shadow = Instance.new("ImageLabel")
Shadow.Size = UDim2.new(1, 40, 1, 40)
Shadow.Position = UDim2.new(0, -20, 0, -10)
Shadow.BackgroundTransparency = 1
Shadow.Image = "rbxassetid://6014261993"
Shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
Shadow.ImageTransparency = 0.5
Shadow.ScaleType = Enum.ScaleType.Slice
Shadow.SliceCenter = Rect.new(49, 49, 450, 450)
Shadow.ZIndex = -1
Shadow.Parent = MainFrame

-- === TITLE BAR ===
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 44)
TitleBar.BackgroundColor3 = THEME.titleBar
TitleBar.BorderSizePixel = 0
TitleBar.ZIndex = 2
TitleBar.Parent = MainFrame
addCorner(TitleBar, 14)

-- Fix bottom-radius of title bar
local TitleFix = Instance.new("Frame")
TitleFix.Size = UDim2.new(1, 0, 0.5, 0)
TitleFix.Position = UDim2.new(0, 0, 0.5, 0)
TitleFix.BackgroundColor3 = THEME.titleBar
TitleFix.BorderSizePixel = 0
TitleFix.ZIndex = 2
TitleFix.Parent = TitleBar

-- Accent bar under title
local AccentLine = Instance.new("Frame")
AccentLine.Size = UDim2.new(1, 0, 0, 2)
AccentLine.Position = UDim2.new(0, 0, 1, -2)
AccentLine.BackgroundColor3 = THEME.accent
AccentLine.BorderSizePixel = 0
AccentLine.ZIndex = 3
AccentLine.Parent = TitleBar

-- Title icon + text
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -50, 1, 0)
TitleLabel.Position = UDim2.new(0, 12, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "🎒  Tool Equip"
TitleLabel.TextColor3 = THEME.textPrimary
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 15
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.ZIndex = 3
TitleLabel.Parent = TitleBar

-- Tool count badge
local CountBadge = Instance.new("TextLabel")
CountBadge.Size = UDim2.new(0, 28, 0, 18)
CountBadge.Position = UDim2.new(1, -38, 0.5, -9)
CountBadge.BackgroundColor3 = THEME.accent
CountBadge.Text = "0"
CountBadge.TextColor3 = Color3.fromRGB(255, 255, 255)
CountBadge.Font = Enum.Font.GothamBold
CountBadge.TextSize = 11
CountBadge.ZIndex = 4
CountBadge.Parent = TitleBar
addCorner(CountBadge, 9)

-- === SEARCH BAR ===
local SearchContainer = Instance.new("Frame")
SearchContainer.Size = UDim2.new(1, -16, 0, 30)
SearchContainer.Position = UDim2.new(0, 8, 0, 50)
SearchContainer.BackgroundColor3 = THEME.btnIdle
SearchContainer.BorderSizePixel = 0
SearchContainer.Parent = MainFrame
addCorner(SearchContainer, 8)
addStroke(SearchContainer, THEME.border, 1)

local SearchIcon = Instance.new("TextLabel")
SearchIcon.Size = UDim2.new(0, 26, 1, 0)
SearchIcon.BackgroundTransparency = 1
SearchIcon.Text = "🔍"
SearchIcon.TextSize = 13
SearchIcon.Font = Enum.Font.Gotham
SearchIcon.TextColor3 = THEME.textMuted
SearchIcon.Parent = SearchContainer

local SearchBox = Instance.new("TextBox")
SearchBox.Size = UDim2.new(1, -30, 1, 0)
SearchBox.Position = UDim2.new(0, 26, 0, 0)
SearchBox.BackgroundTransparency = 1
SearchBox.Text = ""
SearchBox.PlaceholderText = "Search tools..."
SearchBox.PlaceholderColor3 = THEME.textMuted
SearchBox.TextColor3 = THEME.textPrimary
SearchBox.Font = Enum.Font.Gotham
SearchBox.TextSize = 13
SearchBox.TextXAlignment = Enum.TextXAlignment.Left
SearchBox.ClearTextOnFocus = false
SearchBox.Parent = SearchContainer

-- === CONTROLS ROW (Select All / Deselect / Refresh) ===
local ControlRow = Instance.new("Frame")
ControlRow.Size = UDim2.new(1, -16, 0, 26)
ControlRow.Position = UDim2.new(0, 8, 0, 86)
ControlRow.BackgroundTransparency = 1
ControlRow.Parent = MainFrame

local ControlLayout = Instance.new("UIListLayout")
ControlLayout.FillDirection = Enum.FillDirection.Horizontal
ControlLayout.Padding = UDim.new(0, 5)
ControlLayout.SortOrder = Enum.SortOrder.LayoutOrder
ControlLayout.Parent = ControlRow

local function makeSmallBtn(text, color, order)
    local btn = Instance.new("TextButton")
    btn.BackgroundColor3 = color
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 11
    btn.AutomaticSize = Enum.AutomaticSize.X
    btn.Size = UDim2.new(0, 0, 1, 0)
    btn.LayoutOrder = order
    btn.Parent = ControlRow
    addCorner(btn, 7)
    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 8)
    pad.PaddingRight = UDim.new(0, 8)
    pad.Parent = btn
    -- hover effect
    btn.MouseEnter:Connect(function()
        tween(btn, {BackgroundColor3 = color:Lerp(Color3.new(1,1,1), 0.12)}, 0.1)
    end)
    btn.MouseLeave:Connect(function()
        tween(btn, {BackgroundColor3 = color}, 0.1)
    end)
    return btn
end

local SelectAllBtn  = makeSmallBtn("✔ All",    Color3.fromRGB(55, 160, 90),  1)
local DeselectBtn   = makeSmallBtn("✖ None",   Color3.fromRGB(90, 90, 110),  2)
local RefreshBtn    = makeSmallBtn("↺ Refresh", THEME.refresh,                3)

-- === SCROLL FRAME ===
local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Size = UDim2.new(1, -16, 1, -180)
ScrollFrame.Position = UDim2.new(0, 8, 0, 118)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.BorderSizePixel = 0
ScrollFrame.ScrollBarThickness = 4
ScrollFrame.ScrollBarImageColor3 = THEME.scrollBar
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y  -- infinite scroll!
ScrollFrame.Parent = MainFrame

local ListLayout = Instance.new("UIListLayout")
ListLayout.Padding = UDim.new(0, 4)
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ListLayout.Parent = ScrollFrame

local ListPadding = Instance.new("UIPadding")
ListPadding.PaddingTop = UDim.new(0, 2)
ListPadding.PaddingBottom = UDim.new(0, 4)
ListPadding.Parent = ScrollFrame

-- Empty state label
local EmptyLabel = Instance.new("TextLabel")
EmptyLabel.Size = UDim2.new(1, 0, 0, 60)
EmptyLabel.BackgroundTransparency = 1
EmptyLabel.Text = "No tools found\nin your backpack"
EmptyLabel.TextColor3 = THEME.textMuted
EmptyLabel.Font = Enum.Font.Gotham
EmptyLabel.TextSize = 13
EmptyLabel.Visible = false
EmptyLabel.Parent = ScrollFrame

-- === DIVIDER ===
local Divider = Instance.new("Frame")
Divider.Size = UDim2.new(1, -16, 0, 1)
Divider.Position = UDim2.new(0, 8, 1, -58)
Divider.BackgroundColor3 = THEME.border
Divider.BorderSizePixel = 0
Divider.Parent = MainFrame

-- === EQUIP BUTTON ===
local EquipButton = Instance.new("TextButton")
EquipButton.Size = UDim2.new(1, -16, 0, 44)
EquipButton.Position = UDim2.new(0, 8, 1, -52)
EquipButton.BackgroundColor3 = THEME.selected
EquipButton.BorderSizePixel = 0
EquipButton.Text = "⚔  Equip Selected"
EquipButton.TextColor3 = Color3.fromRGB(255, 255, 255)
EquipButton.Font = Enum.Font.GothamBold
EquipButton.TextSize = 14
EquipButton.Parent = MainFrame
addCorner(EquipButton, 11)
addStroke(EquipButton, Color3.fromRGB(0,0,0), 0)

EquipButton.MouseEnter:Connect(function()
    tween(EquipButton, {BackgroundColor3 = EquipButton.BackgroundColor3:Lerp(Color3.new(1,1,1), 0.1)}, 0.1)
end)
EquipButton.MouseLeave:Connect(function()
    tween(EquipButton, {BackgroundColor3 = activated and THEME.unequip or THEME.selected}, 0.1)
end)

-- === DRAG LOGIC (Title Bar) ===
local dragging = false
local dragStart
local startPos
local lastGoalPos

TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = UserInputService:GetMouseLocation()
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

RunService.Heartbeat:Connect(function(dt)
    if not startPos then return end
    if not dragging and lastGoalPos then
        MainFrame.Position = UDim2.new(
            startPos.X.Scale, Lerp(MainFrame.Position.X.Offset, lastGoalPos.X.Offset, dt * 10),
            startPos.Y.Scale, Lerp(MainFrame.Position.Y.Offset, lastGoalPos.Y.Offset, dt * 10)
        )
        return
    end
    if dragging then
        local mouse = UserInputService:GetMouseLocation()
        local dx = mouse.X - dragStart.X
        local dy = mouse.Y - dragStart.Y
        local xGoal = startPos.X.Offset + dx
        local yGoal = startPos.Y.Offset + dy
        lastGoalPos = UDim2.new(startPos.X.Scale, xGoal, startPos.Y.Scale, yGoal)
        MainFrame.Position = UDim2.new(
            startPos.X.Scale, Lerp(MainFrame.Position.X.Offset, xGoal, dt * 10),
            startPos.Y.Scale, Lerp(MainFrame.Position.Y.Offset, yGoal, dt * 10)
        )
    end
end)

-- === TOOL BUTTON LOGIC ===
local function getToolCount()
    local n = 0
    for _ in pairs(toolButtons) do n = n + 1 end
    return n
end

local function updateCountBadge()
    local total = getToolCount()
    local sel = 0
    for _, v in pairs(selectedTools) do if v then sel = sel + 1 end end
    CountBadge.Text = total > 0 and tostring(total) or "0"
    EmptyLabel.Visible = (total == 0)
end

local function applySearch(query)
    query = query:lower()
    for name, btn in pairs(toolButtons) do
        btn.Visible = (query == "" or name:lower():find(query, 1, true) ~= nil)
    end
end

local function createToolButton(toolName)
    if toolButtons[toolName] then return end

    local isSelected = selectedTools[toolName] == true

    local Row = Instance.new("Frame")
    Row.Name = toolName
    Row.Size = UDim2.new(1, 0, 0, 36)
    Row.BackgroundColor3 = isSelected and Color3.fromRGB(30, 60, 35) or THEME.btnIdle
    Row.BorderSizePixel = 0
    Row.Parent = ScrollFrame
    addCorner(Row, 8)
    if isSelected then
        addStroke(Row, THEME.selected, 1)
    else
        addStroke(Row, THEME.border, 1)
    end

    -- Checkbox indicator
    local Check = Instance.new("Frame")
    Check.Size = UDim2.new(0, 18, 0, 18)
    Check.Position = UDim2.new(0, 8, 0.5, -9)
    Check.BackgroundColor3 = isSelected and THEME.selected or THEME.btnHover
    Check.BorderSizePixel = 0
    Check.Parent = Row
    addCorner(Check, 5)

    local CheckMark = Instance.new("TextLabel")
    CheckMark.Size = UDim2.new(1, 0, 1, 0)
    CheckMark.BackgroundTransparency = 1
    CheckMark.Text = isSelected and "✓" or ""
    CheckMark.TextColor3 = Color3.fromRGB(255, 255, 255)
    CheckMark.Font = Enum.Font.GothamBold
    CheckMark.TextSize = 12
    CheckMark.Parent = Check

    local NameLabel = Instance.new("TextLabel")
    NameLabel.Size = UDim2.new(1, -38, 1, 0)
    NameLabel.Position = UDim2.new(0, 34, 0, 0)
    NameLabel.BackgroundTransparency = 1
    NameLabel.Text = toolName
    NameLabel.TextColor3 = isSelected and THEME.textPrimary or THEME.textMuted
    NameLabel.Font = Enum.Font.GothamSemibold
    NameLabel.TextSize = 13
    NameLabel.TextXAlignment = Enum.TextXAlignment.Left
    NameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    NameLabel.Parent = Row

    -- Click button overlay
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, 0, 1, 0)
    Btn.BackgroundTransparency = 1
    Btn.Text = ""
    Btn.ZIndex = 2
    Btn.Parent = Row

    Btn.MouseEnter:Connect(function()
        if not selectedTools[toolName] then
            tween(Row, {BackgroundColor3 = THEME.btnHover}, 0.1)
        end
    end)
    Btn.MouseLeave:Connect(function()
        if not selectedTools[toolName] then
            tween(Row, {BackgroundColor3 = THEME.btnIdle}, 0.1)
        end
    end)

    local function setSelected(state)
        selectedTools[toolName] = state
        if state then
            tween(Row, {BackgroundColor3 = Color3.fromRGB(30, 60, 35)}, 0.12)
            tween(Check, {BackgroundColor3 = THEME.selected}, 0.12)
            CheckMark.Text = "✓"
            NameLabel.TextColor3 = THEME.textPrimary
            -- update stroke
            for _, s in pairs(Row:GetChildren()) do
                if s:IsA("UIStroke") then s.Color = THEME.selected end
            end
        else
            tween(Row, {BackgroundColor3 = THEME.btnIdle}, 0.12)
            tween(Check, {BackgroundColor3 = THEME.btnHover}, 0.12)
            CheckMark.Text = ""
            NameLabel.TextColor3 = THEME.textMuted
            for _, s in pairs(Row:GetChildren()) do
                if s:IsA("UIStroke") then s.Color = THEME.border end
            end
        end
        updateCountBadge()
    end

    Btn.MouseButton1Click:Connect(function()
        setSelected(not selectedTools[toolName])
    end)

    toolButtons[toolName] = Row
    updateCountBadge()
end

local function removeToolButton(toolName)
    if toolButtons[toolName] then
        toolButtons[toolName]:Destroy()
        toolButtons[toolName] = nil
        -- NOTE: selectedTools[toolName] is intentionally kept for memory
        updateCountBadge()
    end
end

local function loadBackpack()
    for _, tool in pairs(LocalPlayer.Backpack:GetChildren()) do
        if tool:IsA("Tool") then createToolButton(tool.Name) end
    end
    if LocalPlayer.Character then
        for _, tool in pairs(LocalPlayer.Character:GetChildren()) do
            if tool:IsA("Tool") then createToolButton(tool.Name) end
        end
    end
    updateCountBadge()
end

-- === REFRESH ===
local function refresh()
    -- Clear buttons (not selectedTools — that persists!)
    for name, btn in pairs(toolButtons) do
        btn:Destroy()
        toolButtons[name] = nil
    end
    loadBackpack()
    -- Re-apply search filter if active
    applySearch(SearchBox.Text)
end

RefreshBtn.MouseButton1Click:Connect(function()
    -- Spin animation
    tween(RefreshBtn, {TextTransparency = 0.5}, 0.1)
    refresh()
    tween(RefreshBtn, {TextTransparency = 0}, 0.2)
end)

-- === SELECT ALL / NONE ===
SelectAllBtn.MouseButton1Click:Connect(function()
    for name, btn in pairs(toolButtons) do
        if btn.Visible then
            local row = btn
            selectedTools[name] = true
            tween(row, {BackgroundColor3 = Color3.fromRGB(30, 60, 35)}, 0.12)
            local check = row:FindFirstChildWhichIsA("Frame")
            if check then tween(check, {BackgroundColor3 = THEME.selected}, 0.12) end
            local mark = check and check:FindFirstChildWhichIsA("TextLabel")
            if mark then mark.Text = "✓" end
            local lbl = row:FindFirstChildWhichIsA("TextLabel")
            if lbl then lbl.TextColor3 = THEME.textPrimary end
            for _, s in pairs(row:GetChildren()) do
                if s:IsA("UIStroke") then s.Color = THEME.selected end
            end
        end
    end
    updateCountBadge()
end)

DeselectBtn.MouseButton1Click:Connect(function()
    for name, btn in pairs(toolButtons) do
        if btn.Visible then
            local row = btn
            selectedTools[name] = false
            tween(row, {BackgroundColor3 = THEME.btnIdle}, 0.12)
            local check = row:FindFirstChildWhichIsA("Frame")
            if check then tween(check, {BackgroundColor3 = THEME.btnHover}, 0.12) end
            local mark = check and check:FindFirstChildWhichIsA("TextLabel")
            if mark then mark.Text = "" end
            local lbl = row:FindFirstChildWhichIsA("TextLabel")
            if lbl then lbl.TextColor3 = THEME.textMuted end
            for _, s in pairs(row:GetChildren()) do
                if s:IsA("UIStroke") then s.Color = THEME.border end
            end
        end
    end
    updateCountBadge()
end)

-- === SEARCH ===
SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    applySearch(SearchBox.Text)
end)

-- === BACKPACK WATCHERS ===
LocalPlayer.Backpack.ChildAdded:Connect(function(child)
    if child:IsA("Tool") then createToolButton(child.Name) end
end)

LocalPlayer.Backpack.ChildRemoved:Connect(function(child)
    if child:IsA("Tool") then
        task.wait(0.1)
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild(child.Name) then
            removeToolButton(child.Name)
        end
    end
end)

local function connectCharacter(char)
    char.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then createToolButton(child.Name) end
    end)
end

if LocalPlayer.Character then connectCharacter(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(function(char)
    -- Clear buttons but KEEP selectedTools memory
    for name, btn in pairs(toolButtons) do
        btn:Destroy()
        toolButtons[name] = nil
    end
    activated = false
    EquipButton.Text = "⚔  Equip Selected"
    tween(EquipButton, {BackgroundColor3 = THEME.selected}, 0.2)
    task.wait(0.6)
    loadBackpack()
    connectCharacter(char)
end)

-- === EQUIP / UNEQUIP ===
EquipButton.MouseButton1Click:Connect(function()
    local char = LocalPlayer.Character
    if not char then return end

    if activated then
        for _, tool in pairs(char:GetChildren()) do
            if tool:IsA("Tool") and selectedTools[tool.Name] then
                tool.Parent = LocalPlayer.Backpack
            end
        end
        activated = false
        EquipButton.Text = "⚔  Equip Selected"
        tween(EquipButton, {BackgroundColor3 = THEME.selected}, 0.2)
    else
        for _, tool in pairs(LocalPlayer.Backpack:GetChildren()) do
            if tool:IsA("Tool") and selectedTools[tool.Name] then
                tool.Parent = char
            end
        end
        activated = true
        EquipButton.Text = "✖  Unequip Selected"
        tween(EquipButton, {BackgroundColor3 = THEME.unequip}, 0.2)
    end
end)

-- === INIT ===
loadBackpack()
