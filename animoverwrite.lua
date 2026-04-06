-- meow


local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ContentProvider = game:GetService("ContentProvider")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")


local flingActive = false
local flingThread = nil
local flingCooldown = false          -- <-- cooldown flag
local flingCooldownTimer = nil       -- <-- to reset cooldown after delay

local function startFling()
	if flingActive or flingCooldown then return end   -- <-- cooldown check
	flingActive = true

	flingThread = task.spawn(function()
		local move = 0.1
		while flingActive do
			RunService.Heartbeat:Wait()
			local character = player.Character
			local rootPart = character and character:FindFirstChild("HumanoidRootPart")
			if rootPart then
				local vel = rootPart.Velocity
				rootPart.Velocity = vel * 10000 + Vector3.new(0, 10000, 0)
				RunService.RenderStepped:Wait()
				rootPart.Velocity = vel
				RunService.Stepped:Wait()
				rootPart.Velocity = vel + Vector3.new(0, move, 0)
				move = -move
			end
		end
	end)
end

local function stopFling()
	if not flingActive then return end
	flingActive = false
	flingThread = nil

	-- start cooldown (0.3 sec)
	if flingCooldownTimer then
		task.cancel(flingCooldownTimer)
	end
	flingCooldown = true
	flingCooldownTimer = task.delay(0.5, function()
		flingCooldown = false
		flingCooldownTimer = nil
	end)
end

-- ============================================================
--  GOD MODE CORE
-- ============================================================

local function applyGodMode(humanoid)
	pcall(function()
		humanoid.MaxHealth = math.huge
		humanoid.Health = math.huge
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
	end)
end

local function connectGodMode(humanoid)
	applyGodMode(humanoid)

	humanoid.HealthChanged:Connect(function()
		applyGodMode(humanoid)
	end)

	humanoid.StateChanged:Connect(function(_, newState)
		if newState == Enum.HumanoidStateType.Dead
			or newState == Enum.HumanoidStateType.FallingDown then
			applyGodMode(humanoid)
		end
	end)

	humanoid.Died:Connect(function()
		task.wait()
		applyGodMode(humanoid)
	end)
end

local function watchCharacterGodMode(character)
	local humanoid = character:WaitForChild("Humanoid")
	connectGodMode(humanoid)

	character.ChildAdded:Connect(function(child)
		if child:IsA("Humanoid") then
			connectGodMode(child)
		end
	end)
end

if player.Character then
	task.spawn(watchCharacterGodMode, player.Character)
end

player.CharacterAdded:Connect(function(character)
	task.wait()
	watchCharacterGodMode(character)
end)

RunService.Heartbeat:Connect(function()
	local char = player.Character
	if char then
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum and hum.Health < math.huge then
			applyGodMode(hum)
		end
	end
end)

-- ============================================================
--  KEYBIND / EMOTE CONFIGURATION
-- ============================================================

local keybindActions = {
	--[[
	Keys row 1
	]]
	{
		name = "Wave",
		keyCode = Enum.KeyCode.Q,
		mode = "hold",
		animationId = "86074172929360",
		looped = true,
		priority = Enum.AnimationPriority.Action,
	},
	{
		name = "PatHead",
		keyCode = Enum.KeyCode.E,
		mode = "hold",
		animationId = "140058263980955",
		looped = true,
		priority = Enum.AnimationPriority.Action,
	},
	{
		name = "LaidUpJiggle",
		keyCode = Enum.KeyCode.R,
		mode = "toggle",
		animationId = "80914010483365",
		looped = true,
		priority = Enum.AnimationPriority.Action,
	},
	{
		name = "LaidUpSide",
		keyCode = Enum.KeyCode.T,
		mode = "toggle",
		animationId = "125317011031079",
		looped = true,
		priority = Enum.AnimationPriority.Action,
	},
	{
		name = "CuteSit",
		keyCode = Enum.KeyCode.Y,
		mode = "toggle",
		animationId = "73928805853047",
		looped = true,
		priority = Enum.AnimationPriority.Action,
	},
	{
		name = "SitPretty",
		keyCode = Enum.KeyCode.U,
		mode = "toggle",
		animationId = "113986788014462",
		looped = true,
		priority = Enum.AnimationPriority.Action,
	},
	--[[
	Keys row 2
	]]
	{
		-- DropKick
		name = "DropKick",
		keyCode = Enum.KeyCode.F,
		mode = "press",
		animationId = "133566007754001",
		looped = false,
		priority = Enum.AnimationPriority.Action,
		useFling = true,
	},
	{
		name = "CuteDanceIdk",
		keyCode = Enum.KeyCode.G,
		mode = "toggle",
		animationId = "131673340109237",
		looped = true,
		priority = Enum.AnimationPriority.Action,
	},
	{
		name = "VibingJiggle",
		keyCode = Enum.KeyCode.H,
		mode = "toggle",
		animationId = "111799322743206",
		looped = true,
		priority = Enum.AnimationPriority.Action,
	},
	{
		name = "StripClubDance",
		keyCode = Enum.KeyCode.J,
		mode = "toggle",
		animationId = "94463184061457",
		looped = true,
		priority = Enum.AnimationPriority.Action,
	},
	{
		name = "JiggleDance",
		keyCode = Enum.KeyCode.K,
		mode = "toggle",
		animationId = "125763702777221",
		looped = true,
		priority = Enum.AnimationPriority.Action,
	},
	--[[
	Keys row 3
	]]
	{
		name = "SitOnIt",
		keyCode = Enum.KeyCode.Z,
		mode = "toggle",
		animationId = "120446020975705",
		looped = true,
		priority = Enum.AnimationPriority.Action,
	},
	{
		name = "SplitsLay",
		keyCode = Enum.KeyCode.X,
		mode = "toggle",
		animationId = "88361934268015",
		looped = true,
		priority = Enum.AnimationPriority.Action,
	},
	{
		name = "Succ/3sum",
		keyCode = Enum.KeyCode.C,
		mode = "toggle",
		animationId = "124873747842579",
		looped = true,
		priority = Enum.AnimationPriority.Action,
	},
	{
		name = "Bending",
		keyCode = Enum.KeyCode.V,
		mode = "toggle",
		animationId = "74591149880936",
		looped = true,
		priority = Enum.AnimationPriority.Action,
	},
	{
		name = "Rub/Finger",
		keyCode = Enum.KeyCode.B,
		mode = "hold",
		animationId = "124575754112740",
		looped = true,
		priority = Enum.AnimationPriority.Action,
	},
	{
		name = "SitOnIt2",
		keyCode = Enum.KeyCode.N,
		mode = "toggle",
		animationId = "103890015669349",
		looped = true,
		priority = Enum.AnimationPriority.Action,
	},
	{
		name = "Splits",
		keyCode = Enum.KeyCode.M,
		mode = "toggle",
		animationId = "118947009579831",
		looped = true,
		priority = Enum.AnimationPriority.Action,
		startTime = 3.19,
		endTime = 5.47,
	},
}

local function normalizeAnimationId(animationId)
	animationId = tostring(animationId)
	if animationId:match("^rbxassetid://") then
		return animationId
	end
	local numericId = animationId:match("(%d+)")
	if numericId then
		return "rbxassetid://" .. numericId
	end
	return animationId
end

-- ============================================================
--  UI HELPERS
-- ============================================================

local uiState = {
	created = false,
	listVisible = true,
	introPlayed = false,
	gui = nil,
	listFrame = nil,
	listContainer = nil,
}

local function keyCodeToText(keyCode)
	if keyCode == Enum.KeyCode.RightAlt then
		return "Right Alt"
	end
	return keyCode.Name
end

local function modeToText(mode)
	if mode == "hold" then return "Hold"
	elseif mode == "press" then return "Press"
	elseif mode == "toggle" then return "Toggle"
	end
	return tostring(mode or "Unknown")
end

local function setEmoteListVisible(visible)
	uiState.listVisible = visible and true or false
	if uiState.gui then
		uiState.gui.Enabled = uiState.listVisible
	end
end

local function toggleEmoteList()
	if not uiState.created then return end
	setEmoteListVisible(not uiState.listVisible)
end

local function populateEmoteList()
	if not uiState.listContainer then return end
	for _, child in ipairs(uiState.listContainer:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
	for _, binding in ipairs(keybindActions) do
		local row = Instance.new("Frame")
		row.Name = (binding.name or "Action") .. "Row"
		row.BackgroundTransparency = 1
		row.Size = UDim2.new(1, -6, 0, 28)
		row.Parent = uiState.listContainer

		local nameLabel = Instance.new("TextLabel")
		nameLabel.BackgroundTransparency = 1
		nameLabel.Position = UDim2.new(0, 0, 0, 0)
		nameLabel.Size = UDim2.new(0.58, 0, 1, 0)
		nameLabel.Font = Enum.Font.Gotham
		nameLabel.Text = tostring(binding.name or "CustomAction")
		nameLabel.TextColor3 = Color3.fromRGB(245, 245, 245)
		nameLabel.TextSize = 14
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Parent = row

		local keyLabel = Instance.new("TextLabel")
		keyLabel.BackgroundTransparency = 1
		keyLabel.Position = UDim2.new(0.58, 0, 0, 0)
		keyLabel.Size = UDim2.new(0.18, 0, 1, 0)
		keyLabel.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
		keyLabel.Text = keyCodeToText(binding.keyCode)
		keyLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
		keyLabel.TextSize = 14
		keyLabel.TextXAlignment = Enum.TextXAlignment.Right
		keyLabel.Parent = row

		local modeLabel = Instance.new("TextLabel")
		modeLabel.BackgroundTransparency = 1
		modeLabel.Position = UDim2.new(0.77, 0, 0, 0)
		modeLabel.Size = UDim2.new(0.23, 0, 1, 0)
		modeLabel.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
		modeLabel.Text = modeToText(binding.mode)
		modeLabel.TextColor3 = Color3.fromRGB(140, 210, 255)
		modeLabel.TextSize = 14
		modeLabel.TextXAlignment = Enum.TextXAlignment.Right
		modeLabel.Parent = row
	end
end

local function createEmoteOverlay()
	if uiState.created then return end
	uiState.created = true

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "EmoteKeybindOverlay"
	screenGui.IgnoreGuiInset = true
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Enabled = false
	screenGui.Parent = playerGui

	local listFrame = Instance.new("Frame")
	listFrame.Name = "KeybindList"
	listFrame.AnchorPoint = Vector2.new(1, 0)
	listFrame.Position = UDim2.new(1, -18, 0.18, 0)
	listFrame.Size = UDim2.new(0, 320, 0, 380)
	listFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
	listFrame.BackgroundTransparency = 0.15
	listFrame.BorderSizePixel = 0
	listFrame.Parent = screenGui
	uiState.listFrame = listFrame
	uiState.gui = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = listFrame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(70, 70, 70)
	stroke.Thickness = 1
	stroke.Transparency = 0.2
	stroke.Parent = listFrame

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Position = UDim2.new(0, 14, 0, 10)
	title.Size = UDim2.new(1, -28, 0, 22)
	title.Font = Enum.Font.GothamBold
	title.Text = "Emotes / Keybinds"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 18
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = listFrame

	local hint = Instance.new("TextLabel")
	hint.BackgroundTransparency = 1
	hint.Position = UDim2.new(0, 14, 0, 33)
	hint.Size = UDim2.new(1, -28, 0, 18)
	hint.Font = Enum.Font.Gotham
	hint.Text = "Right Alt toggles this list"
	hint.TextColor3 = Color3.fromRGB(180, 180, 180)
	hint.TextSize = 12
	hint.TextXAlignment = Enum.TextXAlignment.Left
	hint.Parent = listFrame

	local divider = Instance.new("Frame")
	divider.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	divider.BorderSizePixel = 0
	divider.Position = UDim2.new(0, 14, 0, 56)
	divider.Size = UDim2.new(1, -28, 0, 1)
	divider.Parent = listFrame

	local header = Instance.new("Frame")
	header.BackgroundTransparency = 1
	header.Position = UDim2.new(0, 14, 0, 62)
	header.Size = UDim2.new(1, -28, 0, 18)
	header.Parent = listFrame

	local actionHeader = Instance.new("TextLabel")
	actionHeader.BackgroundTransparency = 1
	actionHeader.Size = UDim2.new(0.58, 0, 1, 0)
	actionHeader.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
	actionHeader.Text = "Action"
	actionHeader.TextColor3 = Color3.fromRGB(150, 150, 150)
	actionHeader.TextSize = 12
	actionHeader.TextXAlignment = Enum.TextXAlignment.Left
	actionHeader.Parent = header

	local keyHeader = Instance.new("TextLabel")
	keyHeader.BackgroundTransparency = 1
	keyHeader.Position = UDim2.new(0.58, 0, 0, 0)
	keyHeader.Size = UDim2.new(0.18, 0, 1, 0)
	keyHeader.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
	keyHeader.Text = "Key"
	keyHeader.TextColor3 = Color3.fromRGB(150, 150, 150)
	keyHeader.TextSize = 12
	keyHeader.TextXAlignment = Enum.TextXAlignment.Right
	keyHeader.Parent = header

	local modeHeader = Instance.new("TextLabel")
	modeHeader.BackgroundTransparency = 1
	modeHeader.Position = UDim2.new(0.77, 0, 0, 0)
	modeHeader.Size = UDim2.new(0.23, 0, 1, 0)
	modeHeader.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
	modeHeader.Text = "Mode"
	modeHeader.TextColor3 = Color3.fromRGB(150, 150, 150)
	modeHeader.TextSize = 12
	modeHeader.TextXAlignment = Enum.TextXAlignment.Right
	modeHeader.Parent = header

	local scrollingFrame = Instance.new("ScrollingFrame")
	scrollingFrame.Name = "List"
	scrollingFrame.BackgroundTransparency = 1
	scrollingFrame.BorderSizePixel = 0
	scrollingFrame.Position = UDim2.new(0, 12, 0, 86)
	scrollingFrame.Size = UDim2.new(1, -24, 1, -98)
	scrollingFrame.ScrollBarThickness = 4
	scrollingFrame.ScrollBarImageColor3 = Color3.fromRGB(130, 130, 130)
	scrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	scrollingFrame.Parent = listFrame

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = scrollingFrame

	uiState.listContainer = scrollingFrame
	populateEmoteList()
	setEmoteListVisible(true)
end

local function playIntro()
	if uiState.introPlayed then return end
	uiState.introPlayed = true

	task.wait(3)

	local introGui = Instance.new("ScreenGui")
	introGui.Name = "IntroDecalGui"
	introGui.IgnoreGuiInset = true
	introGui.ResetOnSpawn = false
	introGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	introGui.DisplayOrder = 999
	introGui.Enabled = false
	introGui.Parent = playerGui

	local backdrop = Instance.new("Frame")
	backdrop.Name = "Backdrop"
	backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	backdrop.BackgroundTransparency = 1
	backdrop.BorderSizePixel = 0
	backdrop.Size = UDim2.fromScale(1, 1)
	backdrop.Parent = introGui

	local backdropFade = Instance.new("Frame")
	backdropFade.Name = "BackdropFade"
	backdropFade.BackgroundColor3 = Color3.fromRGB(6, 6, 10)
	backdropFade.BackgroundTransparency = 1
	backdropFade.BorderSizePixel = 0
	backdropFade.Size = UDim2.fromScale(1, 1)
	backdropFade.Parent = introGui

	local holder = Instance.new("Frame")
	holder.Name = "Holder"
	holder.BackgroundTransparency = 1
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Position = UDim2.new(0.5, 0, 0.42, 0)
	holder.Size = UDim2.new(0, 800, 0, 509)
	holder.Rotation = -8
	holder.Parent = introGui

	local holderScale = Instance.new("UIScale")
	holderScale.Scale = 0.72
	holderScale.Parent = holder

	local glow = Instance.new("Frame")
	glow.Name = "Glow"
	glow.BackgroundColor3 = Color3.fromRGB(120, 170, 255)
	glow.BackgroundTransparency = 1
	glow.BorderSizePixel = 0
	glow.AnchorPoint = Vector2.new(0.5, 0.5)
	glow.Position = UDim2.new(0.5, 0, 0.5, 0)
	glow.Size = UDim2.new(1, 84, 1, 84)
	glow.ZIndex = 1
	glow.Parent = holder

	local glowCorner = Instance.new("UICorner")
	glowCorner.CornerRadius = UDim.new(0, 26)
	glowCorner.Parent = glow

	local glowStroke = Instance.new("UIStroke")
	glowStroke.Color = Color3.fromRGB(150, 205, 255)
	glowStroke.Thickness = 4
	glowStroke.Transparency = 1
	glowStroke.Parent = glow

	local shadow = Instance.new("ImageLabel")
	shadow.Name = "Shadow"
	shadow.BackgroundTransparency = 1
	shadow.BorderSizePixel = 0
	shadow.AnchorPoint = Vector2.new(0.5, 0.5)
	shadow.Position = UDim2.new(0.5, 18, 0.5, 24)
	shadow.Size = UDim2.new(1, 18, 1, 18)
	shadow.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
	shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
	shadow.ImageTransparency = 1
	shadow.ScaleType = Enum.ScaleType.Fit
	shadow.Parent = holder
	shadow.ZIndex = 1

	local image = Instance.new("ImageLabel")
	image.Name = "Decal"
	image.BackgroundTransparency = 1
	image.BorderSizePixel = 0
	image.AnchorPoint = Vector2.new(0.5, 0.5)
	image.Position = UDim2.new(0.5, 0, 0.5, 0)
	image.Size = UDim2.new(1, 0, 1, 0)
	image.Image = "rbxassetid://99946360339614"
	image.ImageTransparency = 1
	image.ScaleType = Enum.ScaleType.Fit
	image.ZIndex = 3
	image.Parent = holder

	local imageCorner = Instance.new("UICorner")
	imageCorner.CornerRadius = UDim.new(0, 20)
	imageCorner.Parent = image

	local imageStroke = Instance.new("UIStroke")
	imageStroke.Color = Color3.fromRGB(255, 255, 255)
	imageStroke.Thickness = 2
	imageStroke.Transparency = 1
	imageStroke.Parent = image

	local rim = Instance.new("Frame")
	rim.Name = "Rim"
	rim.BackgroundTransparency = 1
	rim.BorderSizePixel = 0
	rim.AnchorPoint = Vector2.new(0.5, 0.5)
	rim.Position = UDim2.new(0.5, 0, 0.5, 0)
	rim.Size = UDim2.new(1, 10, 1, 10)
	rim.ZIndex = 2
	rim.Parent = holder

	local rimCorner = Instance.new("UICorner")
	rimCorner.CornerRadius = UDim.new(0, 22)
	rimCorner.Parent = rim

	local rimStroke = Instance.new("UIStroke")
	rimStroke.Color = Color3.fromRGB(255, 255, 255)
	rimStroke.Thickness = 2
	rimStroke.Transparency = 1
	rimStroke.Parent = rim

	local scan = Instance.new("Frame")
	scan.Name = "Scan"
	scan.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	scan.BackgroundTransparency = 1
	scan.BorderSizePixel = 0
	scan.Size = UDim2.new(1, 0, 0, 0)
	scan.Position = UDim2.new(0, 0, 0.12, 0)
	scan.ZIndex = 4
	scan.Parent = image

	local scanGradient = Instance.new("UIGradient")
	scanGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(170, 220, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
	})
	scanGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 0.35),
		NumberSequenceKeypoint.new(1, 1),
	})
	scanGradient.Parent = scan

	local preloadOk = pcall(function()
		ContentProvider:PreloadAsync({ image })
	end)

	introGui.Enabled = true

	local fadeInInfo = TweenInfo.new(0.22, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	local popInfo = TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	local settleInfo = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	TweenService:Create(backdrop, fadeInInfo, { BackgroundTransparency = 0.38 }):Play()
	TweenService:Create(backdropFade, fadeInInfo, { BackgroundTransparency = 0.72 }):Play()
	TweenService:Create(holderScale, popInfo, { Scale = 1.08 }):Play()
	TweenService:Create(holder, popInfo, {
		Rotation = 0,
		Position = UDim2.new(0.5, 0, 0.43, 0),
	}):Play()
	TweenService:Create(glow, fadeInInfo, { BackgroundTransparency = 0.88 }):Play()
	TweenService:Create(glowStroke, fadeInInfo, { Transparency = 0.45 }):Play()
	TweenService:Create(rimStroke, fadeInInfo, { Transparency = 0.55 }):Play()
	TweenService:Create(imageStroke, fadeInInfo, { Transparency = 0.62 }):Play()
	TweenService:Create(shadow, fadeInInfo, { ImageTransparency = 0.75 }):Play()

	if preloadOk then
		TweenService:Create(image, TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			ImageTransparency = 0,
		}):Play()
	else
		TweenService:Create(image, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			ImageTransparency = 0,
		}):Play()
	end

	task.delay(0.3, function()
		if not introGui.Parent then return end
		TweenService:Create(holderScale, settleInfo, { Scale = 1 }):Play()
		TweenService:Create(holder, settleInfo, { Rotation = 0 }):Play()
		TweenService:Create(glow, settleInfo, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(glowStroke, settleInfo, { Transparency = 1 }):Play()
	end)

	task.delay(0.72, function()
		if not introGui.Parent then return end
		local fadeOutInfo = TweenInfo.new(0.42, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		TweenService:Create(image, fadeOutInfo, { ImageTransparency = 1 }):Play()
		TweenService:Create(shadow, fadeOutInfo, { ImageTransparency = 1 }):Play()
		TweenService:Create(rimStroke, fadeOutInfo, { Transparency = 1 }):Play()
		TweenService:Create(imageStroke, fadeOutInfo, { Transparency = 1 }):Play()
		TweenService:Create(backdrop, fadeOutInfo, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(backdropFade, fadeOutInfo, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(holderScale, fadeOutInfo, { Scale = 1.03 }):Play()
		TweenService:Create(holder, fadeOutInfo, {
			Position = UDim2.new(0.5, 0, 0.415, 0),
			Rotation = 2,
		}):Play()
		task.delay(0.46, function()
			if introGui then introGui:Destroy() end
		end)
	end)
end

createEmoteOverlay()
playIntro()

UserInputService.InputBegan:Connect(function(inputObject, gameProcessed)
	if gameProcessed then return end
	if inputObject.KeyCode == Enum.KeyCode.RightAlt then
		toggleEmoteList()
	end
end)

-- ============================================================
--  ANIMATION DATA
-- ============================================================

local animNames = {
	idle = {
		{ id = "http://www.roblox.com/asset/?id=78809479095741", weight = 1 }, -- hands up
		{ id = "http://www.roblox.com/asset/?id=89179616136359", weight = 1 }, -- lil jig
		{ id = "http://www.roblox.com/asset/?id=79493772354232", weight = 1 }, -- feelin queen
		{ id = "http://www.roblox.com/asset/?id=114843552733773", weight = 1 }, -- meh
		{ id = "http://www.roblox.com/asset/?id=80997638859162", weight = 1 },
	},
	walk      = { { id = "http://www.roblox.com/asset/?id=81902773529444",  weight = 10 } },
	run       = { { id = "http://www.roblox.com/asset/?id=85475131476587",  weight = 10 } },
	swim      = { { id = "http://www.roblox.com/asset/?id=16738339158",     weight = 10 } },
	swimidle  = { { id = "http://www.roblox.com/asset/?id=16738339817",     weight = 10 } },
	jump      = { { id = "http://www.roblox.com/asset/?id=16738336650",     weight = 10 } },
	fall      = { { id = "http://www.roblox.com/asset/?id=16738333171",     weight = 10 } },
	climb     = { { id = "http://www.roblox.com/asset/?id=16738332169",     weight = 10 } },
	sit       = { { id = "http://www.roblox.com/asset/?id=2506281703",      weight = 10 } },
	toolnone  = { { id = "http://www.roblox.com/asset/?id=507768375",       weight = 10 } },
	toolslash = { { id = "http://www.roblox.com/asset/?id=522635514",       weight = 10 } },
	toollunge = { { id = "http://www.roblox.com/asset/?id=522638767",       weight = 10 } },
	wave      = { { id = "http://www.roblox.com/asset/?id=507770239",       weight = 10 } },
	point     = { { id = "http://www.roblox.com/asset/?id=507770453",       weight = 10 } },
	dance = {
		{ id = "http://www.roblox.com/asset/?id=507771019", weight = 10 },
		{ id = "http://www.roblox.com/asset/?id=507771955", weight = 10 },
		{ id = "http://www.roblox.com/asset/?id=507772104", weight = 10 },
	},
	dance2 = {
		{ id = "http://www.roblox.com/asset/?id=507776043", weight = 10 },
		{ id = "http://www.roblox.com/asset/?id=507776720", weight = 10 },
		{ id = "http://www.roblox.com/asset/?id=507776879", weight = 10 },
	},
	dance3 = {
		{ id = "http://www.roblox.com/asset/?id=507777268", weight = 10 },
		{ id = "http://www.roblox.com/asset/?id=507777451", weight = 10 },
		{ id = "http://www.roblox.com/asset/?id=507777623", weight = 10 },
	},
	laugh = { { id = "http://www.roblox.com/asset/?id=507770818", weight = 10 } },
	cheer = { { id = "http://www.roblox.com/asset/?id=507770677", weight = 10 } },
}

local emoteNames = {
	wave = false, point = false,
	dance = true, dance2 = true, dance3 = true,
	laugh = false, cheer = false,
}

local EMOTE_TRANSITION_TIME = 0.1
local HumanoidHipHeight = 2

local activeCleanup = nil

-- ============================================================
--  PER-CHARACTER ANIMATION SETUP
-- ============================================================

local function startForCharacter(Character)
	if activeCleanup then
		activeCleanup()
		activeCleanup = nil
	end

	-- Also stop any fling that was running from a previous character session
	stopFling()

	local Humanoid = Character:WaitForChild("Humanoid")
	local Animator = Humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator")
	Animator.Parent = Humanoid

	connectGodMode(Humanoid)

	local defaultAnimate = Character:FindFirstChild("Animate")
	if defaultAnimate then defaultAnimate:Destroy() end

	for _, track in ipairs(Animator:GetPlayingAnimationTracks()) do
		pcall(function() track:Stop(0); track:Destroy() end)
	end

	local pose = "Standing"
	local AnimationSpeedDampeningObject = script:FindFirstChild("ScaleDampeningPercent")

	local currentAnim = ""
	local currentAnimInstance = nil
	local currentAnimTrack = nil
	local currentAnimKeyframeHandler = nil
	local currentAnimSpeed = 1.0

	local runAnimTrack = nil
	local runAnimKeyframeHandler = nil

	local PreloadedAnims = {}
	local animTable = {}

	local toolAnim = "None"
	local toolAnimTime = 0
	local jumpAnimTime = 0
	local jumpAnimDuration = 0.31
	local toolTransitionTime = 0.1
	local fallTransitionTime = 0.2
	local currentlyPlayingEmote = false

	local toolAnimName = ""
	local toolAnimTrack = nil
	local toolAnimInstance = nil
	local currentToolAnimKeyframeHandler = nil

	local connections = {}

	local isIdle = false
	local currentIdleIndex = 1
	local nextIdleIndex = 1
	local idleTrack = nil

	local function buildCustomBindings()
		local bindings = {}
		for _, binding in ipairs(keybindActions) do
			local newBinding = {
				name = binding.name or "CustomAction",
				keyCode = binding.keyCode,
				mode = binding.mode or "press",
				animationId = normalizeAnimationId(binding.animationId),
				looped = binding.looped,
				priority = binding.priority or Enum.AnimationPriority.Action,
				track = nil,
				animation = nil,
				isActive = false,
				ignoreStop = false,
				useFling = binding.useFling or false,   -- carry the fling flag through
			}
			if binding.startTime then newBinding.startTime = binding.startTime end
			if binding.endTime   then newBinding.endTime   = binding.endTime   end
			table.insert(bindings, newBinding)
		end
		return bindings
	end
	local customBindings = buildCustomBindings()
	local currentCustomAction = nil

	local function connect(signal, fn)
		local c = signal:Connect(fn)
		table.insert(connections, c)
		return c
	end

	local function cleanupConnections()
		for _, c in ipairs(connections) do
			pcall(function() c:Disconnect() end)
		end
		table.clear(connections)
	end

	local function stopTrack(track, fadeTime)
		if track then
			pcall(function() track:Stop(fadeTime or 0); track:Destroy() end)
		end
	end

	local function stopMainAnimationTracks(fadeTime)
		if currentAnimKeyframeHandler then
			pcall(function() currentAnimKeyframeHandler:Disconnect() end)
			currentAnimKeyframeHandler = nil
		end
		if runAnimKeyframeHandler then
			pcall(function() runAnimKeyframeHandler:Disconnect() end)
			runAnimKeyframeHandler = nil
		end
		stopTrack(currentAnimTrack, fadeTime)
		stopTrack(runAnimTrack, fadeTime)
		currentAnimTrack = nil
		runAnimTrack = nil
		currentAnim = ""
		currentAnimInstance = nil
	end

	local function stopIdleTrack(fadeTime)
		stopTrack(idleTrack, fadeTime)
		idleTrack = nil
	end

	local function getRigScale()
		return Character:GetScale()
	end

	local function getIdleCount()
		if animTable.idle and animTable.idle.count then
			return animTable.idle.count
		end
		return 0
	end

	local function pickRandomIdleIndex(exceptIndex)
		local count = getIdleCount()
		if count <= 1 then return 1 end
		local chosen = exceptIndex or 0
		while chosen == exceptIndex do
			chosen = math.random(1, count)
		end
		return chosen
	end

	local function configureAnimationSet(name, fileList)
		if animTable[name] ~= nil then
			for _, connection in ipairs(animTable[name].connections or {}) do
				pcall(function() connection:Disconnect() end)
			end
		end

		animTable[name] = {}
		animTable[name].count = 0
		animTable[name].totalWeight = 0
		animTable[name].connections = {}

		local allowCustomAnimations = true
		pcall(function()
			allowCustomAnimations = game:GetService("StarterPlayer").AllowCustomAnimations
		end)

		local config = script:FindFirstChild(name)
		if allowCustomAnimations and config ~= nil then
			table.insert(animTable[name].connections, config.ChildAdded:Connect(function()
				configureAnimationSet(name, fileList)
			end))
			table.insert(animTable[name].connections, config.ChildRemoved:Connect(function()
				configureAnimationSet(name, fileList)
			end))

			for _, childPart in pairs(config:GetChildren()) do
				if childPart:IsA("Animation") then
					local newWeight = 1
					local weightObject = childPart:FindFirstChild("Weight")
					if weightObject ~= nil then newWeight = weightObject.Value end
					animTable[name].count += 1
					local idx = animTable[name].count
					animTable[name][idx] = { anim = childPart, weight = newWeight }
					animTable[name].totalWeight += newWeight
					table.insert(animTable[name].connections, childPart.Changed:Connect(function()
						configureAnimationSet(name, fileList)
					end))
					table.insert(animTable[name].connections, childPart.ChildAdded:Connect(function()
						configureAnimationSet(name, fileList)
					end))
					table.insert(animTable[name].connections, childPart.ChildRemoved:Connect(function()
						configureAnimationSet(name, fileList)
					end))
				end
			end
		end

		if animTable[name].count <= 0 then
			for idx, anim in pairs(fileList) do
				animTable[name][idx] = {}
				animTable[name][idx].anim = Instance.new("Animation")
				animTable[name][idx].anim.Name = name
				animTable[name][idx].anim.AnimationId = anim.id
				animTable[name][idx].weight = anim.weight
				animTable[name].count += 1
				animTable[name].totalWeight += anim.weight
			end
		end

		for _, animType in pairs(animTable) do
			for idx = 1, animType.count do
				local animationId = animType[idx].anim.AnimationId
				if PreloadedAnims[animationId] == nil then
					pcall(function() Animator:LoadAnimation(animType[idx].anim) end)
					PreloadedAnims[animationId] = true
				end
			end
		end
	end

	local function rollAnimation(animName)
		local roll = math.random(1, animTable[animName].totalWeight)
		local idx = 1
		while roll > animTable[animName][idx].weight do
			roll -= animTable[animName][idx].weight
			idx += 1
		end
		return idx
	end

	local function getHeightScale()
		if Humanoid then
			if not Humanoid.AutomaticScalingEnabled then
				return getRigScale()
			end
			local scale = Humanoid.HipHeight / HumanoidHipHeight
			if AnimationSpeedDampeningObject == nil then
				AnimationSpeedDampeningObject = script:FindFirstChild("ScaleDampeningPercent")
			end
			if AnimationSpeedDampeningObject ~= nil then
				scale = 1 + (Humanoid.HipHeight - HumanoidHipHeight) * AnimationSpeedDampeningObject.Value / HumanoidHipHeight
			end
			return scale
		end
		return getRigScale()
	end

	local function rootMotionCompensation(speed)
		return (speed * 1.25) / getHeightScale()
	end

	local smallButNotZero = 0.0001
	local function setRunSpeed(speed)
		local normalizedWalkSpeed = 0.5
		local normalizedRunSpeed = 1
		local runSpeed = rootMotionCompensation(speed)
		local walkAnimationWeight = smallButNotZero
		local runAnimationWeight = smallButNotZero
		local timeWarp = 1

		if runSpeed <= normalizedWalkSpeed then
			walkAnimationWeight = 1
			timeWarp = runSpeed / normalizedWalkSpeed
		elseif runSpeed < normalizedRunSpeed then
			local fadeInRun = (runSpeed - normalizedWalkSpeed) / (normalizedRunSpeed - normalizedWalkSpeed)
			walkAnimationWeight = 1 - fadeInRun
			runAnimationWeight = fadeInRun
		else
			timeWarp = runSpeed / normalizedRunSpeed
			runAnimationWeight = 1
		end

		if currentAnimTrack then
			currentAnimTrack:AdjustWeight(walkAnimationWeight)
			currentAnimTrack:AdjustSpeed(timeWarp)
		end
		if runAnimTrack then
			runAnimTrack:AdjustWeight(runAnimationWeight)
			runAnimTrack:AdjustSpeed(timeWarp)
		end
	end

	local function setAnimationSpeed(speed)
		if currentAnim == "walk" then
			setRunSpeed(speed)
		else
			if speed ~= currentAnimSpeed and currentAnimTrack then
				currentAnimSpeed = speed
				currentAnimTrack:AdjustSpeed(currentAnimSpeed)
			end
		end
	end

	local function playIdle(index, transitionTime)
		local idleSet = animTable.idle
		if not idleSet or idleSet.count <= 0 then return end
		index = math.clamp(index or 1, 1, idleSet.count)
		currentIdleIndex = index
		stopMainAnimationTracks(transitionTime or 0.15)
		stopIdleTrack(0)
		local anim = idleSet[index].anim
		idleTrack = Animator:LoadAnimation(anim)
		idleTrack.Priority = Enum.AnimationPriority.Core
		idleTrack.Looped = true
		idleTrack:Play(transitionTime or 0.15)
		currentAnim = "idle"
		currentAnimInstance = anim
		currentAnimTrack = idleTrack
		currentlyPlayingEmote = false
	end

	local function setIdleState(shouldIdle, transitionTime)
		if shouldIdle then
			if not isIdle or idleTrack == nil or currentAnim ~= "idle" then
				isIdle = true
				if nextIdleIndex < 1 or nextIdleIndex > getIdleCount() then
					nextIdleIndex = math.random(1, math.max(getIdleCount(), 1))
				end
				playIdle(nextIdleIndex, transitionTime or 0.15)
			end
		else
			if isIdle then
				isIdle = false
				nextIdleIndex = pickRandomIdleIndex(currentIdleIndex)
				stopIdleTrack(transitionTime or 0.1)
				currentAnimTrack = nil
				currentAnimInstance = nil
				currentAnim = ""
			end
		end
	end

	local function stopCurrentCustomAction(fadeTime, goIdle)
		if currentCustomAction == nil then return end
		local action = currentCustomAction
		currentCustomAction = nil
		action.isActive = false
		action.ignoreStop = true

		-- --------------------------------------------------------
		--  FLING CLEANUP: stop fling if this action had it active
		-- --------------------------------------------------------
		if action.useFling then
			stopFling()
		end

		if action.pingPongConnection then
			action.pingPongConnection:Disconnect()
			action.pingPongConnection = nil
		end

		if action.track then
			local track = action.track
			action.track = nil
			action.animation = nil
			pcall(function() track:Stop(fadeTime or 0) end)
			pcall(function() track:Destroy() end)
		end

		action.ignoreStop = false

		if goIdle and Character.Parent ~= nil and Humanoid.Parent ~= nil then
			setIdleState(true, fadeTime or 0.15)
		end
	end

	local function playCustomAction(action, transitionTime)
		if action == nil or Humanoid.Parent == nil then return end

		if currentCustomAction and currentCustomAction ~= action then
			stopCurrentCustomAction(transitionTime or 0, false)
		end

		if currentCustomAction == action and action.track then
			pcall(function() action.track:Stop(0); action.track:Destroy() end)
			action.track = nil
			action.animation = nil
			action.isActive = false
			currentCustomAction = nil
		end

		stopMainAnimationTracks(transitionTime or 0)
		stopIdleTrack(transitionTime or 0)

		local anim = Instance.new("Animation")
		anim.Name = action.name
		anim.AnimationId = action.animationId

		local track = Animator:LoadAnimation(anim)
		track.Priority = action.priority or Enum.AnimationPriority.Action

		action.animation = anim
		action.track = track
		action.isActive = true
		action.ignoreStop = false
		currentCustomAction = action

		currentAnim = action.name
		currentAnimInstance = anim
		currentAnimTrack = track
		currentlyPlayingEmote = false
		currentAnimSpeed = 1.0
		isIdle = false

		local isPingPong = action.startTime and action.endTime

		if isPingPong then
			track.Looped = true
			track:Play(transitionTime or 0.1)
			track.TimePosition = action.startTime

			local direction = 1
			local speed = 1
			local heartbeatConn

			heartbeatConn = RunService.Heartbeat:Connect(function()
				if not track or not track.IsPlaying then
					if heartbeatConn then heartbeatConn:Disconnect() end
					if currentCustomAction == action then
						stopCurrentCustomAction(0, true)
					end
					return
				end
				local pos = track.TimePosition
				if direction == 1 and pos >= action.endTime then
					direction = -1
					track:AdjustSpeed(direction * speed)
					track.TimePosition = action.endTime
				elseif direction == -1 and pos <= action.startTime then
					direction = 1
					track:AdjustSpeed(direction * speed)
					track.TimePosition = action.startTime
				end
			end)

			action.pingPongConnection = heartbeatConn
			action.pingPongDirection = direction
			action.pingPongSpeed = speed
		else
			track.Looped = (action.mode ~= "press") and (action.looped == true or action.looped == nil or action.mode == "hold" or action.mode == "toggle") or false
			track:Play(transitionTime or 0.1)
		end

		-- --------------------------------------------------------
		--  FLING START: begin fling loop if this action requests it
		-- --------------------------------------------------------
		if action.useFling then
			startFling()
		end

		local stoppedConnection
		stoppedConnection = track.Stopped:Connect(function()
			if currentCustomAction ~= action then return end
			if action.ignoreStop then return end

			-- --------------------------------------------------------
			--  FLING STOP: animation ended naturally, kill the fling
			-- --------------------------------------------------------
			if action.useFling then
				stopFling()
			end

			action.isActive = false
			action.track = nil
			action.animation = nil
			currentCustomAction = nil
			currentAnimTrack = nil
			currentAnimInstance = nil
			currentAnim = ""
			pose = "Standing"
			if action.mode == "press" then
				setIdleState(true, 0.15)
			end
		end)
		table.insert(connections, stoppedConnection)
	end

	local function playAnimation(animName, transitionTime, humanoid)
		if currentCustomAction and animName ~= "idle" then return end

		if animName == "idle" then
			setIdleState(true, transitionTime)
			return
		end

		local idx = rollAnimation(animName)
		local anim = animTable[animName][idx].anim

		if anim ~= currentAnimInstance then
			if currentAnim == "idle" then
				setIdleState(false, transitionTime)
			end
			if currentAnimTrack ~= nil then
				stopTrack(currentAnimTrack, transitionTime)
				currentAnimTrack = nil
			end
			if runAnimTrack ~= nil then
				stopTrack(runAnimTrack, transitionTime)
				runAnimTrack = nil
			end

			currentAnimSpeed = 1.0
			currentAnimTrack = humanoid:LoadAnimation(anim)
			currentAnimTrack.Priority = Enum.AnimationPriority.Core
			currentAnimTrack:Play(transitionTime)
			currentAnim = animName
			currentAnimInstance = anim

			if currentAnimKeyframeHandler ~= nil then
				pcall(function() currentAnimKeyframeHandler:Disconnect() end)
			end
			currentAnimKeyframeHandler = currentAnimTrack.KeyframeReached:Connect(function(frameName)
				if frameName == "End" then
					if currentAnim == "walk" then
						if runAnimTrack and runAnimTrack.Looped ~= true then
							runAnimTrack.TimePosition = 0.0
						end
						if currentAnimTrack and currentAnimTrack.Looped ~= true then
							currentAnimTrack.TimePosition = 0.0
						end
					else
						local repeatAnim = currentAnim
						if emoteNames[repeatAnim] ~= nil and emoteNames[repeatAnim] == false then
							repeatAnim = "idle"
						end
						if currentlyPlayingEmote then
							if currentAnimTrack and currentAnimTrack.Looped then return end
							repeatAnim = "idle"
							currentlyPlayingEmote = false
						end
						if repeatAnim == "idle" then
							setIdleState(true, 0.15)
						else
							local animSpeed = currentAnimSpeed
							playAnimation(repeatAnim, 0.15, humanoid)
							setAnimationSpeed(animSpeed)
						end
					end
				end
			end)

			if animName == "walk" then
				local runAnimName = "run"
				local runIdx = rollAnimation(runAnimName)
				runAnimTrack = humanoid:LoadAnimation(animTable[runAnimName][runIdx].anim)
				runAnimTrack.Priority = Enum.AnimationPriority.Core
				runAnimTrack:Play(transitionTime)

				if runAnimKeyframeHandler ~= nil then
					pcall(function() runAnimKeyframeHandler:Disconnect() end)
				end
				runAnimKeyframeHandler = runAnimTrack.KeyframeReached:Connect(function(frameName)
					if frameName == "End" then
						if runAnimTrack.Looped ~= true then
							runAnimTrack.TimePosition = 0.0
						end
						if currentAnimTrack and currentAnimTrack.Looped ~= true then
							currentAnimTrack.TimePosition = 0.0
						end
					end
				end)
			end
		end
	end

	local function playEmote(emoteAnim, transitionTime, humanoid)
		if currentCustomAction then return end
		stopIdleTrack(transitionTime)
		stopMainAnimationTracks(transitionTime)
		currentAnimTrack = humanoid:LoadAnimation(emoteAnim)
		currentAnimTrack.Priority = Enum.AnimationPriority.Core
		currentAnimTrack:Play(transitionTime)
		currentAnim = emoteAnim.Name
		currentAnimInstance = emoteAnim
		currentlyPlayingEmote = true
	end

	local function stopAllAnimations()
		local oldAnim = currentAnim

		if currentCustomAction then
			-- Stop fling for any active custom action that uses it
			if currentCustomAction.useFling then
				stopFling()
			end
			currentCustomAction.isActive = false
			currentCustomAction.ignoreStop = true
			currentCustomAction = nil
		end

		if emoteNames[oldAnim] ~= nil and emoteNames[oldAnim] == false then
			oldAnim = "idle"
		end
		if currentlyPlayingEmote then
			oldAnim = "idle"
			currentlyPlayingEmote = false
		end

		currentAnim = ""
		currentAnimInstance = nil

		if currentAnimKeyframeHandler ~= nil then
			pcall(function() currentAnimKeyframeHandler:Disconnect() end)
			currentAnimKeyframeHandler = nil
		end
		if runAnimKeyframeHandler ~= nil then
			pcall(function() runAnimKeyframeHandler:Disconnect() end)
			runAnimKeyframeHandler = nil
		end

		stopTrack(currentAnimTrack, 0)
		stopTrack(runAnimTrack, 0)
		stopTrack(idleTrack, 0)

		currentAnimTrack = nil
		runAnimTrack = nil
		idleTrack = nil

		return oldAnim
	end

	local function onRunning(speed)
		if currentCustomAction then return end
		local heightScale = getHeightScale()

		if Character:FindFirstChildOfClass("ControllerManager") and Humanoid.EvaluateStateMachine == false then
			local charGroundSensor = Character:FindFirstChildOfClass("ControllerManager").GroundSensor
			local charControllerManager = Character:FindFirstChildOfClass("ControllerManager")
			if charGroundSensor ~= nil and charControllerManager ~= nil then
				local hrp = Humanoid.RootPart
				local sensedPart = charGroundSensor.SensedPart
				if sensedPart then
					local pos = charGroundSensor.HitFrame.Position
					local floorVel = sensedPart:GetVelocityAtPosition(pos)
					local assemblyVel = hrp.AssemblyLinearVelocity
					local relVel = Vector3.new(assemblyVel.X - floorVel.X, 0, assemblyVel.Z - floorVel.Z)
					local relSpeed = relVel.Magnitude
					local moveMag = charControllerManager.MovingDirection.Magnitude
					if moveMag < 0.1 then relSpeed = 0; moveMag = 0
					elseif moveMag > 1.0 then moveMag = 1.0 end
					speed = relSpeed * moveMag
				end
			end
		end

		local movedDuringEmote = currentlyPlayingEmote and Humanoid.MoveDirection == Vector3.new(0, 0, 0)
		local speedThreshold = movedDuringEmote and (Humanoid.WalkSpeed / heightScale) or 0.75

		if speed > speedThreshold * heightScale then
			if isIdle then setIdleState(false, 0.1) end
			local scale = 16.0
			playAnimation("walk", 0.2, Humanoid)
			setAnimationSpeed(speed / scale)
			pose = "Running"
		else
			setIdleState(true, 0.2)
			pose = "Standing"
		end
	end

	local function onDied()
		stopCurrentCustomAction(0, false)
		pose = "Dead"
		task.spawn(applyGodMode, Humanoid)
	end

	local function onJumping()
		if currentCustomAction then return end
		if isIdle then setIdleState(false, 0.1) end
		playAnimation("jump", 0.1, Humanoid)
		jumpAnimTime = jumpAnimDuration
		pose = "Jumping"
	end

	local function onClimbing(speed)
		if currentCustomAction then return end
		if isIdle then setIdleState(false, 0.1) end
		speed /= getHeightScale()
		local scale = 5.0
		playAnimation("climb", 0.1, Humanoid)
		setAnimationSpeed(speed / scale)
		pose = "Climbing"
	end

	local function onGettingUp()    pose = "GettingUp"          end
	local function onFallingDown()
		applyGodMode(Humanoid)
		pose = "FallingDown"
	end
	local function onPlatformStanding() pose = "PlatformStanding" end

	local function onFreeFall()
		if currentCustomAction then return end
		if isIdle then setIdleState(false, 0.1) end
		if jumpAnimTime <= 0 then
			playAnimation("fall", fallTransitionTime, Humanoid)
		end
		pose = "FreeFall"
	end

	local function onSeated()
		if currentCustomAction then return end
		if isIdle then setIdleState(false, 0.1) end
		pose = "Seated"
	end

	local function onSwimming(speed)
		if currentCustomAction then return end
		if isIdle then setIdleState(false, 0.1) end
		speed /= getHeightScale()
		if speed > 1.0 then
			local scale = 10.0
			playAnimation("swim", 0.4, Humanoid)
			setAnimationSpeed(speed / scale)
			pose = "Swimming"
		else
			playAnimation("swimidle", 0.4, Humanoid)
			pose = "Standing"
		end
	end

	local function animateTool()
		if currentCustomAction then return end
		if toolAnim == "None" then
			playAnimation("toolnone", toolTransitionTime, Humanoid)
			if currentAnimTrack then currentAnimTrack.Priority = Enum.AnimationPriority.Idle end
			return
		end
		if toolAnim == "Slash" then
			playAnimation("toolslash", 0, Humanoid)
			if currentAnimTrack then currentAnimTrack.Priority = Enum.AnimationPriority.Action end
			return
		end
		if toolAnim == "Lunge" then
			playAnimation("toollunge", 0, Humanoid)
			if currentAnimTrack then currentAnimTrack.Priority = Enum.AnimationPriority.Action end
			return
		end
	end

	local function getToolAnim(tool)
		for _, c in ipairs(tool:GetChildren()) do
			if c.Name == "toolanim" and c:IsA("StringValue") then
				return c
			end
		end
		return nil
	end

	local playToolAnimation -- forward declaration

	local function toolKeyFrameReachedFunc(frameName)
		if frameName == "End" then
			playToolAnimation(toolAnimName, 0.0, Humanoid)
		end
	end

	playToolAnimation = function(animName, transitionTime, humanoid, priority)
		if currentCustomAction then return end
		local idx = rollAnimation(animName)
		local anim = animTable[animName][idx].anim

		if toolAnimInstance ~= anim then
			if toolAnimTrack ~= nil then
				toolAnimTrack:Stop()
				toolAnimTrack:Destroy()
				transitionTime = 0
			end

			toolAnimTrack = humanoid:LoadAnimation(anim)
			if priority then
				toolAnimTrack.Priority = priority
			end
			toolAnimTrack:Play(transitionTime)

			toolAnimName = animName
			toolAnimInstance = anim

			if currentToolAnimKeyframeHandler ~= nil then
				currentToolAnimKeyframeHandler:Disconnect()
				currentToolAnimKeyframeHandler = nil
			end

			currentToolAnimKeyframeHandler = toolAnimTrack.KeyframeReached:Connect(toolKeyFrameReachedFunc)
		end
	end

	local function stopToolAnimations()
		local oldAnim = toolAnimName

		if currentToolAnimKeyframeHandler ~= nil then
			currentToolAnimKeyframeHandler:Disconnect()
			currentToolAnimKeyframeHandler = nil
		end

		toolAnimName = ""
		toolAnimInstance = nil

		if toolAnimTrack ~= nil then
			toolAnimTrack:Stop()
			toolAnimTrack:Destroy()
			toolAnimTrack = nil
		end

		return oldAnim
	end

	local lastTick = 0

	local function stepAnimate(currentTime)
		if currentCustomAction then return end
		local deltaTime = currentTime - lastTick
		lastTick = currentTime

		if jumpAnimTime > 0 then jumpAnimTime -= deltaTime end

		if pose == "FreeFall" and jumpAnimTime <= 0 then
			playAnimation("fall", fallTransitionTime, Humanoid)
		elseif pose == "Seated" then
			playAnimation("sit", 0.5, Humanoid)
			return
		elseif pose == "Running" then
			playAnimation("walk", 0.2, Humanoid)
		elseif pose == "Dead" or pose == "GettingUp" or pose == "FallingDown"
			or pose == "Seated" or pose == "PlatformStanding" then
			stopAllAnimations()
		end

		local tool = Character:FindFirstChildOfClass("Tool")
		if tool and tool:FindFirstChild("Handle") then
			local animStringValueObject = getToolAnim(tool)
			if animStringValueObject then
				toolAnim = animStringValueObject.Value
				animStringValueObject.Parent = nil
				toolAnimTime = currentTime + 0.3
			end
			if currentTime > toolAnimTime then
				toolAnimTime = 0
				toolAnim = "None"
			end
			animateTool()
		else
			stopToolAnimations()
			toolAnim = "None"
			toolAnimInstance = nil
			toolAnimTime = 0
		end
	end

	local function getBindingForKeyCode(keyCode)
		for _, binding in ipairs(customBindings) do
			if binding.keyCode == keyCode then return binding end
		end
		return nil
	end

	local function handleCustomBindPressed(inputObject, gameProcessed)
		if gameProcessed then return end
		local binding = getBindingForKeyCode(inputObject.KeyCode)
		if not binding then return end

		if binding.mode == "hold" or binding.mode == "press" then
			playCustomAction(binding, 0.05)
		elseif binding.mode == "toggle" then
			if currentCustomAction == binding then
				stopCurrentCustomAction(0.1, true)
			else
				playCustomAction(binding, 0.05)
			end
		end
	end

	local function handleCustomBindReleased(inputObject, gameProcessed)
		if gameProcessed then return end
		local binding = getBindingForKeyCode(inputObject.KeyCode)
		if not binding then return end
		if binding.mode == "hold" and currentCustomAction == binding then
			stopCurrentCustomAction(0.1, true)
		end
	end

	-- Setup animation sets
	for name, fileList in pairs(animNames) do
		configureAnimationSet(name, fileList)
	end

	-- Event connections
	connect(Humanoid.Died,             onDied)
	connect(Humanoid.Running,          onRunning)
	connect(Humanoid.Jumping,          onJumping)
	connect(Humanoid.Climbing,         onClimbing)
	connect(Humanoid.GettingUp,        onGettingUp)
	connect(Humanoid.FreeFalling,      onFreeFall)
	connect(Humanoid.FallingDown,      onFallingDown)
	connect(Humanoid.Seated,           onSeated)
	connect(Humanoid.PlatformStanding, onPlatformStanding)
	connect(Humanoid.Swimming,         onSwimming)

	connect(UserInputService.InputBegan,  handleCustomBindPressed)
	connect(UserInputService.InputEnded,  handleCustomBindReleased)

	connect(player.Chatted, function(msg)
		if currentCustomAction then return end
		local emote = ""
		if string.sub(msg, 1, 3) == "/e " then
			emote = string.sub(msg, 4)
		elseif string.sub(msg, 1, 7) == "/emote " then
			emote = string.sub(msg, 8)
		end
		if pose == "Standing" and emoteNames[emote] ~= nil then
			playAnimation(emote, EMOTE_TRANSITION_TIME, Humanoid)
		end
	end)

	local playEmoteBindable = script:FindFirstChild("PlayEmote")
	if playEmoteBindable and playEmoteBindable:IsA("BindableFunction") then
		playEmoteBindable.OnInvoke = function(emote)
			if currentCustomAction then return false end
			if pose ~= "Standing" then return end
			if emoteNames[emote] ~= nil then
				playAnimation(emote, EMOTE_TRANSITION_TIME, Humanoid)
				return true, currentAnimTrack
			elseif typeof(emote) == "Instance" and emote:IsA("Animation") then
				playEmote(emote, EMOTE_TRANSITION_TIME, Humanoid)
				return true, currentAnimTrack
			end
			return false
		end
	end

	if Character.Parent ~= nil then
		nextIdleIndex = math.random(1, math.max(getIdleCount(), 1))
		setIdleState(true, 0.1)
		pose = "Standing"
	end

	-- -----------------------------------------------------------------
	-- TELEPORT DETECTION
	-- Stop any toggle animation if the character teleports
	-- -----------------------------------------------------------------
	local lastRootPosition = nil
	local function checkTeleport()
		if not currentCustomAction then return end
		if currentCustomAction.mode ~= "toggle" then return end   -- only toggle animations

		local rootPart = Character:FindFirstChild("HumanoidRootPart")
		if not rootPart then return end

		local currentPos = rootPart.Position
		if lastRootPosition then
			local distance = (currentPos - lastRootPosition).Magnitude
			-- If moved more than 50 studs in one frame, consider it a teleport
			if distance > 50 then
				-- Stop the toggle animation
				stopCurrentCustomAction(0.1, true)
				-- reset position to avoid repeated triggers
				lastRootPosition = currentPos
				return
			end
		end
		lastRootPosition = currentPos
	end

	local heartbeatConnection
	heartbeatConnection = RunService.Heartbeat:Connect(function(dt)
		if Character.Parent == nil or Humanoid.Parent == nil then
			if heartbeatConnection then heartbeatConnection:Disconnect() end
			cleanupConnections()
			-- Safety: stop fling if character leaves
			stopFling()
			return
		end
		stepAnimate(dt)
		checkTeleport()   -- <-- teleport check after stepAnimate
	end)

	table.insert(connections, heartbeatConnection)

	activeCleanup = function()
		cleanupConnections()

		-- Stop the fling when cleaning up for a new character
		stopFling()

		if currentCustomAction then
			if currentCustomAction.pingPongConnection then
				currentCustomAction.pingPongConnection:Disconnect()
			end
			currentCustomAction.isActive = false
			currentCustomAction.ignoreStop = true
			currentCustomAction = nil
		end

		if currentAnimKeyframeHandler then
			pcall(function() currentAnimKeyframeHandler:Disconnect() end)
		end
		if runAnimKeyframeHandler then
			pcall(function() runAnimKeyframeHandler:Disconnect() end)
		end
		if currentToolAnimKeyframeHandler then
			pcall(function() currentToolAnimKeyframeHandler:Disconnect() end)
		end

		if currentAnimTrack then
			pcall(function() currentAnimTrack:Stop(0); currentAnimTrack:Destroy() end)
		end
		if runAnimTrack then
			pcall(function() runAnimTrack:Stop(0); runAnimTrack:Destroy() end)
		end
		if toolAnimTrack then
			pcall(function() toolAnimTrack:Stop(0); toolAnimTrack:Destroy() end)
		end
		if idleTrack then
			pcall(function() idleTrack:Stop(0); idleTrack:Destroy() end)
		end
	end
end

-- ============================================================
--  BOOTSTRAP
-- ============================================================

if player.Character then
	startForCharacter(player.Character)
end

player.CharacterAdded:Connect(function(character)
	startForCharacter(character)
end)

loadstring(game:HttpGet(('https://raw.githubusercontent.com/femce4l20/somusrnams-scripts/refs/heads/main/credits-plugin.lua'),true))()
wait(0.5)
loadstring(game:HttpGet(('https://raw.githubusercontent.com/femce4l20/somusrnams-scripts/refs/heads/main/physics/physics.lua'),true))()
