-- watagandastyl

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

-- ============================================================
-- MODE CONFIG
-- ============================================================
local MODE_CONFIG = {
	["Bang1"] = {
		animId = "rbxassetid://86745448648267",
		offset = CFrame.new(0, 0, 1.1),
		speed  = 10,
	},
	["Bang2"] = {
		animId = "rbxassetid://138802982118351",
		offset = CFrame.new(0, 0, 1.1),
		speed  = 2,
	},
	["EatingOut"] = {
		animId = "rbxassetid://72149474467473",
		offset = CFrame.new(0, 0, 2),
		speed  = 1,
	},
	["Fingering"] = {
		animId = "rbxassetid://124575754112740",
		offset = CFrame.new(-2, -1.6, 1.7),
		speed  = 2.5,
	},
	["Exercising"] = {
		animId = "rbxassetid://5918726674",      -- replace with exercising anim
		offset = CFrame.new(0, 0, 1.2) * CFrame.Angles(0, math.rad(180), 0),
		speed  = 4,
	},
	["Studying"] = {
		animId = "rbxassetid://5918726674",      -- replace with studying anim
		offset = CFrame.new(1.5, 0, 0) * CFrame.Angles(0, math.rad(-90), 0),
		speed  = 1.5,
	},
	["Gaming"] = {
		animId = "rbxassetid://5918726674",      -- replace with gaming anim
		offset = CFrame.new(-1.1, 0, 0) * CFrame.Angles(0, math.rad(90), 0),
		speed  = 2,
	},
	["Idle"] = {
		animId = "rbxassetid://5918726674",      -- replace with idle anim
		offset = CFrame.new(0, 0, 2.0),
		speed  = 1,
	},
}

-- ============================================================
-- CONSTANTS
-- ============================================================
local REFRESH_INTERVAL   = 5
local TWEEN_FAST         = TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local TWEEN_MED          = TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

local PALETTE = {
	BG          = Color3.fromRGB(10,  12,  18),
	SURFACE     = Color3.fromRGB(18,  21,  30),
	CARD        = Color3.fromRGB(24,  28,  40),
	CARD_HOVER  = Color3.fromRGB(32,  37,  54),
	ACCENT      = Color3.fromRGB(99,  179, 237),
	ACCENT2     = Color3.fromRGB(154, 117, 255),
	SUCCESS     = Color3.fromRGB(72,  199, 142),
	DANGER      = Color3.fromRGB(252, 100, 100),
	TEXT        = Color3.fromRGB(230, 235, 245),
	SUBTEXT     = Color3.fromRGB(120, 130, 160),
	BORDER      = Color3.fromRGB(40,  46,  65),
	SELECTED    = Color3.fromRGB(99,  179, 237),
}

local MODE_BUTTONS = {
	"Bang1", "Bang2", "EatingOut", "Fingering",
	"Exercising", "Studying", "Gaming", "Idle",
}

-- ============================================================
-- HELPERS
-- ============================================================
local function createInstance(className, properties)
	local obj = Instance.new(className)
	for k, v in pairs(properties) do
		obj[k] = v
	end
	return obj
end

local function roundCorner(obj, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = obj
	return corner
end

local function addPadding(obj, top, right, bottom, left)
	local pad = Instance.new("UIPadding")
	pad.PaddingTop    = UDim.new(0, top)
	pad.PaddingRight  = UDim.new(0, right)
	pad.PaddingBottom = UDim.new(0, bottom)
	pad.PaddingLeft   = UDim.new(0, left)
	pad.Parent = obj
	return pad
end

local function addStroke(obj, color, thickness, transparency)
	local stroke = Instance.new("UIStroke")
	stroke.Color        = color or PALETTE.BORDER
	stroke.Thickness    = thickness or 1
	stroke.Transparency = transparency or 0
	stroke.Parent       = obj
	return stroke
end

local function tween(obj, props)
	TweenService:Create(obj, TWEEN_FAST, props):Play()
end

local function tweenMed(obj, props)
	TweenService:Create(obj, TWEEN_MED, props):Play()
end

local function getThumb(userId)
	local ok, img = pcall(function()
		return Players:GetUserThumbnailAsync(
			userId,
			Enum.ThumbnailType.HeadShot,
			Enum.ThumbnailSize.Size100x100
		)
	end)
	return ok and img or "rbxasset://textures/ui/GuiImagePlaceholder.png"
end

local function getRoot(character)
	return character and character:FindFirstChild("HumanoidRootPart")
end

local function getTorso(character)
	return character and (
		character:FindFirstChild("HumanoidRootPart") or
		character:FindFirstChild("UpperTorso")
	)
end

-- ============================================================
-- WINDOW STATE
-- ============================================================
local WINDOW_EXPANDED_SIZE = UDim2.new(0, 560, 0, 520)
local WINDOW_MINIMIZED_SIZE = UDim2.new(0, 560, 0, 44)

local isMinimized = false
local isClosed = false

-- ============================================================
-- ANIMATION STATE
-- ============================================================
local bangAnim, bang, bangDied, bangLoop
local activeBaseSpeed = nil
local currentSpeedMultiplier = 1

-- Prevent the default Roblox Animate controller from blending in
-- movement/climb/jump animations over the custom track.
local disabledAnimateScript = nil
local disabledAnimateWasDisabled = nil

local function disableDefaultAnimate(character)
	if disabledAnimateScript then
		return
	end

	local animate = character and character:FindFirstChild("Animate")
	if animate and animate:IsA("LocalScript") then
		disabledAnimateScript = animate
		disabledAnimateWasDisabled = animate.Disabled
		animate.Disabled = true
	end
end

local function restoreDefaultAnimate()
	if disabledAnimateScript and disabledAnimateScript.Parent then
		disabledAnimateScript.Disabled = disabledAnimateWasDisabled
	end
	disabledAnimateScript = nil
	disabledAnimateWasDisabled = nil
end

local function applyCurrentSpeed()
	if bang and activeBaseSpeed then
		bang:AdjustSpeed(activeBaseSpeed * currentSpeedMultiplier)
	end
end

local function stopBang()
	if bangLoop  then bangLoop:Disconnect();  bangLoop  = nil end
	if bangDied  then bangDied:Disconnect();  bangDied  = nil end
	if bang      then bang:Stop();            bang      = nil end
	if bangAnim  then bangAnim:Destroy();     bangAnim  = nil end
	activeBaseSpeed = nil
	restoreDefaultAnimate()
end

local function startBang(targetName, modeName)
	stopBang()

	local config = MODE_CONFIG[modeName]
	if not config then
		warn("[ServerUI] No config found for mode: " .. tostring(modeName))
		return
	end

	local character = LocalPlayer.Character
	if not character then
		warn("[ServerUI] Local character not found.")
		return
	end

	local humanoid = character:FindFirstChildWhichIsA("Humanoid")
	if not humanoid then
		warn("[ServerUI] Humanoid not found.")
		return
	end

	disableDefaultAnimate(character)

	-- Load & play animation (R15 only)
	bangAnim = Instance.new("Animation")
	bangAnim.AnimationId = config.animId
	bang = humanoid:LoadAnimation(bangAnim)

	-- Highest useful priority so climb/walk/jump do not override it
	bang.Priority = Enum.AnimationPriority.Action4

	bang:Play(0.1, 1, 1)

	activeBaseSpeed = config.speed
	applyCurrentSpeed()

	-- Auto-stop when character dies
	bangDied = humanoid.Died:Connect(function()
		stopBang()
	end)

	-- Position loop relative to target player
	local targetPlayer = Players:FindFirstChild(targetName)
	if targetPlayer then
		local bangOffset = config.offset
		bangLoop = RunService.Stepped:Connect(function()
			pcall(function()
				local otherRoot = getTorso(targetPlayer.Character)
				local myRoot    = getRoot(character)
				if otherRoot and myRoot then
					myRoot.CFrame = otherRoot.CFrame * bangOffset
				end
			end)
		end)
	else
		warn("[ServerUI] Target player not found: " .. tostring(targetName))
	end
end

-- ============================================================
-- BUILD GUI
-- ============================================================
local ScreenGui = createInstance("ScreenGui", {
	Name            = "ServerListUI",
	ResetOnSpawn    = false,
	IgnoreGuiInset  = true,
	ZIndexBehavior  = Enum.ZIndexBehavior.Sibling,
	Parent          = LocalPlayer:WaitForChild("PlayerGui"),
})

-- ── Draggable Main Window ─────────────────────────────────────
local MainFrame = createInstance("Frame", {
	Name             = "MainFrame",
	Size             = WINDOW_EXPANDED_SIZE,
	Position         = UDim2.new(0.5, -280, 0.5, -260),
	BackgroundColor3 = PALETTE.BG,
	BorderSizePixel  = 0,
	ClipsDescendants = true,
	Parent           = ScreenGui,
})
roundCorner(MainFrame, 14)
addStroke(MainFrame, PALETTE.BORDER, 1, 0)

local Shadow = createInstance("Frame", {
	Name                   = "Shadow",
	Size                   = UDim2.new(1, 20, 1, 20),
	Position               = UDim2.new(0, -10, 0, 6),
	BackgroundColor3       = Color3.fromRGB(0, 0, 0),
	BackgroundTransparency = 0.65,
	BorderSizePixel        = 0,
	ZIndex                 = MainFrame.ZIndex - 1,
	Parent                 = MainFrame,
})
roundCorner(Shadow, 18)

-- ── Title Bar ─────────────────────────────────────────────────
local TitleBar = createInstance("Frame", {
	Name             = "TitleBar",
	Size             = UDim2.new(1, 0, 0, 44),
	BackgroundColor3 = PALETTE.SURFACE,
	BorderSizePixel  = 0,
	Parent           = MainFrame,
})
roundCorner(TitleBar, 14)
local TitleBarMask = createInstance("Frame", {
	Size             = UDim2.new(1, 0, 0, 14),
	Position         = UDim2.new(0, 0, 1, -14),
	BackgroundColor3 = PALETTE.SURFACE,
	BorderSizePixel  = 0,
	Parent           = TitleBar,
})

local TitleIcon = createInstance("Frame", {
	Name             = "TitleIcon",
	Size             = UDim2.new(0, 10, 0, 10),
	Position         = UDim2.new(0, 16, 0.5, -5),
	BackgroundColor3 = PALETTE.ACCENT,
	BorderSizePixel  = 0,
	Parent           = TitleBar,
})
roundCorner(TitleIcon, 5)

local TitleLabel = createInstance("TextLabel", {
	Name                   = "TitleLabel",
	Size                   = UDim2.new(1, -160, 1, 0),
	Position               = UDim2.new(0, 36, 0, 0),
	BackgroundTransparency = 1,
	Text                   = "Bang them hoes",
	TextColor3             = PALETTE.TEXT,
	Font                   = Enum.Font.GothamBold,
	TextSize               = 14,
	TextXAlignment         = Enum.TextXAlignment.Left,
	Parent                 = TitleBar,
})

local StatusDot = createInstance("Frame", {
	Name             = "StatusDot",
	Size             = UDim2.new(0, 8, 0, 8),
	Position         = UDim2.new(1, -92, 0.5, -4),
	BackgroundColor3 = PALETTE.SUCCESS,
	BorderSizePixel  = 0,
	Parent           = TitleBar,
})
roundCorner(StatusDot, 4)

local function makeTitleButton(text, xOffset)
	local btn = createInstance("TextButton", {
		Size = UDim2.new(0, 28, 0, 24),
		Position = UDim2.new(1, xOffset, 0.5, -12),
		BackgroundColor3 = Color3.fromRGB(26, 30, 42),
		BorderSizePixel = 0,
		Text = text,
		TextColor3 = PALETTE.TEXT,
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		AutoButtonColor = false,
		ZIndex = 10,
		Parent = TitleBar,
	})
	roundCorner(btn, 7)
	addStroke(btn, PALETTE.BORDER, 1, 0)
	return btn
end

local MinimizeBtn = makeTitleButton("–", -66)
local CloseBtn = makeTitleButton("×", -34)

MinimizeBtn.MouseEnter:Connect(function()
	tween(MinimizeBtn, { BackgroundColor3 = Color3.fromRGB(40, 46, 65) })
end)
MinimizeBtn.MouseLeave:Connect(function()
	tween(MinimizeBtn, { BackgroundColor3 = Color3.fromRGB(26, 30, 42) })
end)

CloseBtn.MouseEnter:Connect(function()
	tween(CloseBtn, { BackgroundColor3 = Color3.fromRGB(90, 40, 45) })
end)
CloseBtn.MouseLeave:Connect(function()
	tween(CloseBtn, { BackgroundColor3 = Color3.fromRGB(26, 30, 42) })
end)

local ContentFrame = createInstance("Frame", {
	Name                   = "Content",
	Size                   = UDim2.new(1, 0, 1, -44),
	Position               = UDim2.new(0, 0, 0, 44),
	BackgroundTransparency = 1,
	BorderSizePixel        = 0,
	Parent                 = MainFrame,
})
addPadding(ContentFrame, 14, 14, 14, 14)

local function setWindowMinimized(state)
	if isClosed then
		return
	end

	isMinimized = state and true or false
	MinimizeBtn.Text = isMinimized and "+" or "–"

	if isMinimized then
		ContentFrame.Visible = false
		tweenMed(MainFrame, { Size = WINDOW_MINIMIZED_SIZE })
	else
		tweenMed(MainFrame, { Size = WINDOW_EXPANDED_SIZE })
		task.delay(TWEEN_MED.Time, function()
			if not isClosed and not isMinimized and ContentFrame then
				ContentFrame.Visible = true
			end
		end)
	end
end

CloseBtn.MouseButton1Click:Connect(function()
	isClosed = true
	stopBang()
	if ScreenGui then
		ScreenGui:Destroy()
	end
end)

MinimizeBtn.MouseButton1Click:Connect(function()
	setWindowMinimized(not isMinimized)
end)

-- Drag logic
local dragging, dragStart, startPos = false, nil, nil
TitleBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or
	   input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos  = MainFrame.Position
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or
		input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - dragStart
		MainFrame.Position = UDim2.new(
			startPos.X.Scale, startPos.X.Offset + delta.X,
			startPos.Y.Scale, startPos.Y.Offset + delta.Y
		)
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or
	   input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)

local function sectionLabel(parent, text, posY)
	return createInstance("TextLabel", {
		Size                   = UDim2.new(1, 0, 0, 16),
		Position               = UDim2.new(0, 0, 0, posY),
		BackgroundTransparency = 1,
		Text                   = text,
		TextColor3             = PALETTE.SUBTEXT,
		Font                   = Enum.Font.GothamBold,
		TextSize               = 10,
		TextXAlignment         = Enum.TextXAlignment.Left,
		Parent                 = parent,
	})
end

-- ============================================================
-- SERVER LIST (horizontal scroll)
-- ============================================================
sectionLabel(ContentFrame, "PLAYERS IN SERVER", 0)

local ServerListOuter = createInstance("Frame", {
	Name             = "ServerListOuter",
	Size             = UDim2.new(1, 0, 0, 108),
	Position         = UDim2.new(0, 0, 0, 22),
	BackgroundColor3 = PALETTE.SURFACE,
	BorderSizePixel  = 0,
	ClipsDescendants = true,
	Parent           = ContentFrame,
})
roundCorner(ServerListOuter, 10)
addStroke(ServerListOuter, PALETTE.BORDER, 1, 0)

local ServerListScroll = createInstance("ScrollingFrame", {
	Name                   = "ServerListScroll",
	Size                   = UDim2.new(1, 0, 1, 0),
	BackgroundTransparency = 1,
	BorderSizePixel        = 0,
	ScrollBarThickness     = 3,
	ScrollBarImageColor3   = PALETTE.ACCENT,
	ScrollingDirection     = Enum.ScrollingDirection.X,
	CanvasSize             = UDim2.new(0, 0, 1, 0),
	AutomaticCanvasSize    = Enum.AutomaticSize.X,
	Parent                 = ServerListOuter,
})
addPadding(ServerListScroll, 10, 10, 10, 10)

local ServerListLayout = createInstance("UIListLayout", {
	FillDirection  = Enum.FillDirection.Horizontal,
	SortOrder      = Enum.SortOrder.LayoutOrder,
	Padding        = UDim.new(0, 8),
	Parent         = ServerListScroll,
})

-- ── Player Card builder ───────────────────────────────────────
local selectedCard = nil
local selectedPlayer = nil
local onPlayerSelected

local function buildPlayerCard(player)
	local card = createInstance("Frame", {
		Name             = player.Name,
		Size             = UDim2.new(0, 80, 1, 0),
		BackgroundColor3 = PALETTE.CARD,
		BorderSizePixel  = 0,
		LayoutOrder      = player.UserId,
		Parent           = ServerListScroll,
	})
	roundCorner(card, 8)
	local stroke = addStroke(card, PALETTE.BORDER, 1, 0)

	local avatar = createInstance("ImageLabel", {
		Name             = "Avatar",
		Size             = UDim2.new(0, 44, 0, 44),
		Position         = UDim2.new(0.5, -22, 0, 8),
		BackgroundColor3 = PALETTE.BG,
		BorderSizePixel  = 0,
		Image            = getThumb(player.UserId),
		Parent           = card,
	})
	roundCorner(avatar, 22)
	addStroke(avatar, PALETTE.BORDER, 1.5, 0)

	createInstance("TextLabel", {
		Name                   = "DisplayName",
		Size                   = UDim2.new(1, -6, 0, 14),
		Position               = UDim2.new(0, 3, 0, 56),
		BackgroundTransparency = 1,
		Text                   = player.DisplayName,
		TextColor3             = PALETTE.TEXT,
		Font                   = Enum.Font.GothamBold,
		TextSize               = 10,
		TextXAlignment         = Enum.TextXAlignment.Center,
		TextTruncate           = Enum.TextTruncate.AtEnd,
		Parent                 = card,
	})

	createInstance("TextLabel", {
		Name                   = "Username",
		Size                   = UDim2.new(1, -6, 0, 12),
		Position               = UDim2.new(0, 3, 0, 70),
		BackgroundTransparency = 1,
		Text                   = "@" .. player.Name,
		TextColor3             = PALETTE.SUBTEXT,
		Font                   = Enum.Font.Gotham,
		TextSize               = 9,
		TextXAlignment         = Enum.TextXAlignment.Center,
		TextTruncate           = Enum.TextTruncate.AtEnd,
		Parent                 = card,
	})

	local btn = createInstance("TextButton", {
		Name                   = "ClickOverlay",
		Size                   = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text                   = "",
		ZIndex                 = card.ZIndex + 2,
		Parent                 = card,
	})

	btn.MouseEnter:Connect(function()
		if selectedPlayer ~= player then
			tween(card, { BackgroundColor3 = PALETTE.CARD_HOVER })
		end
	end)
	btn.MouseLeave:Connect(function()
		if selectedPlayer ~= player then
			tween(card, { BackgroundColor3 = PALETTE.CARD })
			tween(stroke, { Color = PALETTE.BORDER })
		end
	end)
	btn.MouseButton1Click:Connect(function()
		onPlayerSelected(player, card, stroke)
	end)

	return card
end

local function highlightModeButton(btn, stroke, isSelected)
	if isSelected then
		tween(btn, {
			BackgroundColor3 = Color3.fromRGB(22, 40, 65),
			TextColor3 = PALETTE.ACCENT,
		})
		tween(stroke, { Color = PALETTE.ACCENT })
	else
		tween(btn, {
			BackgroundColor3 = PALETTE.CARD,
			TextColor3 = PALETTE.SUBTEXT,
		})
		tween(stroke, { Color = PALETTE.BORDER })
	end
end

local modeButtonsByName = {}
local selectedMode = nil

onPlayerSelected = function(player, card, stroke)
	if selectedCard then
		tween(selectedCard.card,   { BackgroundColor3 = PALETTE.CARD })
		tween(selectedCard.stroke, { Color = PALETTE.BORDER })
	end
	selectedPlayer = player
	selectedCard   = { card = card, stroke = stroke }
	tween(card,   { BackgroundColor3 = Color3.fromRGB(28, 45, 70) })
	tween(stroke, { Color = PALETTE.ACCENT })

	if _G.ServerUI_TargetInput then
		_G.ServerUI_TargetInput.Text = player.Name
	end
end

-- ── Refresh server list ──────────────────────────────────────
local cardCache = {}

local function refreshServerList()
	local currentPlayers = {}
	for _, p in ipairs(Players:GetPlayers()) do
		currentPlayers[p.Name] = p
	end

	for name, card in pairs(cardCache) do
		if not currentPlayers[name] then
			card:Destroy()
			cardCache[name] = nil
			if selectedPlayer and selectedPlayer.Name == name then
				selectedPlayer = nil
				selectedCard   = nil
			end
		end
	end

	for name, player in pairs(currentPlayers) do
		if not cardCache[name] then
			cardCache[name] = buildPlayerCard(player)
		end
	end
end

refreshServerList()
Players.PlayerAdded:Connect(refreshServerList)
Players.PlayerRemoving:Connect(function()
	task.wait(0.1)
	refreshServerList()
end)

-- ============================================================
-- MODE BUTTONS  (was "ACTIONS")
-- ============================================================
sectionLabel(ContentFrame, "MODES", 142)

local ModeGrid = createInstance("Frame", {
	Name                   = "ModeGrid",
	Size                   = UDim2.new(1, 0, 0, 96),
	Position               = UDim2.new(0, 0, 0, 162),
	BackgroundTransparency = 1,
	Parent                 = ContentFrame,
})

createInstance("UIGridLayout", {
	CellSize    = UDim2.new(0.23, -4, 0, 40),
	CellPadding = UDim2.new(0.01, 0, 0, 6),
	SortOrder   = Enum.SortOrder.LayoutOrder,
	Parent      = ModeGrid,
})

for i, modeName in ipairs(MODE_BUTTONS) do
	local btn = createInstance("TextButton", {
		Name             = modeName,
		BackgroundColor3 = PALETTE.CARD,
		BorderSizePixel  = 0,
		Text             = modeName,
		TextColor3       = PALETTE.SUBTEXT,
		Font             = Enum.Font.GothamBold,
		TextSize         = 11,
		LayoutOrder      = i,
		AutoButtonColor  = false,
		Parent           = ModeGrid,
	})
	roundCorner(btn, 8)
	local stroke = addStroke(btn, PALETTE.BORDER, 1, 0)

	modeButtonsByName[modeName] = {
		btn = btn,
		stroke = stroke,
	}

	local function selectMode()
		if selectedMode and selectedMode.btn ~= btn then
			highlightModeButton(selectedMode.btn, selectedMode.stroke, false)
		end
		selectedMode = { btn = btn, stroke = stroke }
		highlightModeButton(btn, stroke, true)
	end

	btn.MouseEnter:Connect(function()
		if not selectedMode or selectedMode.btn ~= btn then
			tween(btn, { BackgroundColor3 = PALETTE.CARD_HOVER })
		end
	end)
	btn.MouseLeave:Connect(function()
		if not selectedMode or selectedMode.btn ~= btn then
			tween(btn, { BackgroundColor3 = PALETTE.CARD })
		end
	end)
	btn.MouseButton1Click:Connect(selectMode)
end

-- Make Bang1 highlighted by default
task.defer(function()
	local normal = modeButtonsByName["Bang1"]
	if normal then
		selectedMode = { btn = normal.btn, stroke = normal.stroke }
		highlightModeButton(normal.btn, normal.stroke, true)
	end
end)

-- ============================================================
-- ANIMATION SPEED SLIDER
-- ============================================================
sectionLabel(ContentFrame, "ANIMATION SPEED", 272)

local SPEED_MIN = 0.1
local SPEED_MAX = 5

local SpeedContainer = createInstance("Frame", {
	Name = "SpeedContainer",
	Size = UDim2.new(1, 0, 0, 56),
	Position = UDim2.new(0, 0, 0, 292),
	BackgroundColor3 = PALETTE.SURFACE,
	BorderSizePixel = 0,
	Parent = ContentFrame,
})
roundCorner(SpeedContainer, 10)
addStroke(SpeedContainer, PALETTE.BORDER, 1, 0)

local SpeedTitle = createInstance("TextLabel", {
	Name = "SpeedTitle",
	Size = UDim2.new(1, -20, 0, 16),
	Position = UDim2.new(0, 10, 0, 8),
	BackgroundTransparency = 1,
	Text = "Playback Speed",
	TextColor3 = PALETTE.TEXT,
	Font = Enum.Font.GothamBold,
	TextSize = 12,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = SpeedContainer,
})

local SpeedValue = createInstance("TextLabel", {
	Name = "SpeedValue",
	Size = UDim2.new(0, 90, 0, 16),
	Position = UDim2.new(1, -100, 0, 8),
	BackgroundTransparency = 1,
	Text = "1.00x",
	TextColor3 = PALETTE.ACCENT,
	Font = Enum.Font.GothamBold,
	TextSize = 12,
	TextXAlignment = Enum.TextXAlignment.Right,
	Parent = SpeedContainer,
})

local SliderTrack = createInstance("Frame", {
	Name = "SliderTrack",
	Size = UDim2.new(1, -20, 0, 10),
	Position = UDim2.new(0, 10, 0, 32),
	BackgroundColor3 = Color3.fromRGB(14, 17, 25),
	BorderSizePixel = 0,
	Parent = SpeedContainer,
})
roundCorner(SliderTrack, 5)
addStroke(SliderTrack, PALETTE.BORDER, 1, 0.3)

local SliderFill = createInstance("Frame", {
	Name = "SliderFill",
	Size = UDim2.new(0.18, 0, 1, 0),
	BackgroundColor3 = PALETTE.ACCENT,
	BorderSizePixel = 0,
	Parent = SliderTrack,
})
roundCorner(SliderFill, 5)

local SliderKnob = createInstance("Frame", {
	Name = "SliderKnob",
	Size = UDim2.new(0, 14, 0, 14),
	Position = UDim2.new(0.18, -7, 0.5, -7),
	BackgroundColor3 = PALETTE.TEXT,
	BorderSizePixel = 0,
	Parent = SliderTrack,
})
roundCorner(SliderKnob, 7)
addStroke(SliderKnob, PALETTE.BORDER, 1, 0)

local sliderDragging = false
local function updateSliderVisualFromMultiplier(multiplier)
	local clamped = math.clamp(multiplier, SPEED_MIN, SPEED_MAX)
	currentSpeedMultiplier = clamped

	local alpha = (clamped - SPEED_MIN) / (SPEED_MAX - SPEED_MIN)
	SliderFill.Size = UDim2.new(alpha, 0, 1, 0)
	SliderKnob.Position = UDim2.new(alpha, -7, 0.5, -7)
	SpeedValue.Text = string.format("%.2fx", clamped)

	applyCurrentSpeed()
end

local function setMultiplierFromX(screenX)
	local absPos = SliderTrack.AbsolutePosition.X
	local absSize = SliderTrack.AbsoluteSize.X
	local ratio = math.clamp((screenX - absPos) / math.max(absSize, 1), 0, 1)
	local value = SPEED_MIN + (SPEED_MAX - SPEED_MIN) * ratio
	updateSliderVisualFromMultiplier(value)
end

SliderTrack.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or
	   input.UserInputType == Enum.UserInputType.Touch then
		sliderDragging = true
		setMultiplierFromX(input.Position.X)
	end
end)

SliderKnob.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or
	   input.UserInputType == Enum.UserInputType.Touch then
		sliderDragging = true
		setMultiplierFromX(input.Position.X)
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if sliderDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or
		input.UserInputType == Enum.UserInputType.Touch) then
		setMultiplierFromX(input.Position.X)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or
	   input.UserInputType == Enum.UserInputType.Touch then
		sliderDragging = false
	end
end)

updateSliderVisualFromMultiplier(1)

-- ============================================================
-- TARGET INPUT
-- ============================================================
sectionLabel(ContentFrame, "TARGET", 362)

local InputRow = createInstance("Frame", {
	Name                   = "InputRow",
	Size                   = UDim2.new(1, 0, 0, 38),
	Position               = UDim2.new(0, 0, 0, 381),
	BackgroundTransparency = 1,
	Parent                 = ContentFrame,
})

local TargetInput = createInstance("TextBox", {
	Name              = "TargetInput",
	Size              = UDim2.new(1, 0, 1, 0),
	BackgroundColor3  = PALETTE.CARD,
	BorderSizePixel   = 0,
	Text              = "",
	PlaceholderText   = "Click a player or type a name...",
	TextColor3        = PALETTE.TEXT,
	PlaceholderColor3 = PALETTE.SUBTEXT,
	Font              = Enum.Font.Gotham,
	TextSize          = 13,
	TextXAlignment    = Enum.TextXAlignment.Left,
	ClearTextOnFocus  = false,
	Parent            = InputRow,
})
roundCorner(TargetInput, 8)
addPadding(TargetInput, 0, 12, 0, 12)
local inputStroke = addStroke(TargetInput, PALETTE.BORDER, 1, 0)

TargetInput.Focused:Connect(function()
	tween(inputStroke, { Color = PALETTE.ACCENT })
end)
TargetInput.FocusLost:Connect(function()
	tween(inputStroke, { Color = PALETTE.BORDER })
end)

_G.ServerUI_TargetInput = TargetInput

-- ============================================================
-- START / STOP BUTTON
-- ============================================================
local isRunning = false

local StartStopBtn = createInstance("TextButton", {
	Name             = "StartStopBtn",
	Size             = UDim2.new(1, 0, 0, 44),
	Position         = UDim2.new(0, 0, 0, 432),
	BackgroundColor3 = PALETTE.SUCCESS,
	BorderSizePixel  = 0,
	Text             = "▶  START",
	TextColor3       = Color3.fromRGB(10, 12, 18),
	Font             = Enum.Font.GothamBold,
	TextSize         = 14,
	AutoButtonColor   = false,
	Parent           = ContentFrame,
})
roundCorner(StartStopBtn, 10)

local function updateStartStopVisual()
	if isRunning then
		tweenMed(StartStopBtn, {
			BackgroundColor3 = PALETTE.DANGER,
			TextColor3 = Color3.fromRGB(255, 255, 255),
		})
		StartStopBtn.Text = "◼  STOP"
		tween(StatusDot, { BackgroundColor3 = PALETTE.DANGER })
	else
		tweenMed(StartStopBtn, {
			BackgroundColor3 = PALETTE.SUCCESS,
			TextColor3 = Color3.fromRGB(10, 12, 18),
		})
		StartStopBtn.Text = "▶  START"
		tween(StatusDot, { BackgroundColor3 = PALETTE.SUCCESS })
	end
end

StartStopBtn.MouseEnter:Connect(function()
	tween(StartStopBtn, {
		BackgroundColor3 = isRunning
			and Color3.fromRGB(255, 130, 130)
			or  Color3.fromRGB(90, 215, 160),
	})
end)
StartStopBtn.MouseLeave:Connect(function()
	updateStartStopVisual()
end)

StartStopBtn.MouseButton1Click:Connect(function()
	isRunning = not isRunning
	updateStartStopVisual()

	local target = TargetInput.Text
	local mode   = selectedMode and selectedMode.btn.Name or "Bang1"

	if isRunning then
		print(("[ServerUI] Started — Target: %s | Mode: %s"):format(target, mode))
		startBang(target, mode)
	else
		print("[ServerUI] Stopped")
		stopBang()
	end
end)

-- ============================================================
-- ENTRY ANIMATION
-- ============================================================
MainFrame.Position = UDim2.new(0.5, -280, 0.5, -260)
MainFrame.BackgroundTransparency = 1
MainFrame.Size = WINDOW_EXPANDED_SIZE

for _, desc in ipairs(MainFrame:GetDescendants()) do
	if desc:IsA("GuiObject") then
		desc.Visible = false
	end
end

task.defer(function()
	MainFrame.BackgroundTransparency = 0
	for _, desc in ipairs(MainFrame:GetDescendants()) do
		if desc:IsA("GuiObject") then
			desc.Visible = true
		end
	end
	ContentFrame.Visible = not isMinimized
	local orig = MainFrame.Position
	MainFrame.Position = UDim2.new(orig.X.Scale, orig.X.Offset, orig.Y.Scale, orig.Y.Offset + 20)
	tweenMed(MainFrame, { Position = orig })
end)

print("[ServerUI] Loaded successfully.")
