local RunService    = game:GetService("RunService")
local Players       = game:GetService("Players")
local TweenService  = game:GetService("TweenService")

local player    = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

-- ================================================================
--  CONFIGS (per accessory type)
-- ================================================================

local CONFIGS = {}

CONFIGS.wings = {
	-- Spring-damper physics
	STIFFNESS       = 150,
	DAMPING         = 3.2,
	INERTIA_SCALE   = 0.02,

	-- Deadzones
	SIDE_DEADZONE     = 2.0,
	FORWARD_DEADZONE  = 0.7,

	-- Forward-trailing bias
	FORWARD_DRAG_BIAS      = -0.01,
	FORWARD_YAW_REDUCTION  = 0.80,
	FORWARD_MOTION_FULL    = 9,
	YAW_UNLOCK_ANGLE       = math.rad(7),
	YAW_FULL_UNLOCK        = math.rad(12),

	-- Momentum / trailing behavior
	MOTION_TRAIL_SMOOTHING   = 0.07,
	MOTION_ACCEL_INFLUENCE   = 0.02,
	TRAIL_RELEASE            = 0.04,

	-- Rotation tracking
	ROTATION_YAW_INFLUENCE   = 0.05,
	ROTATION_ROLL_INFLUENCE  = 0.55,
	ROTATION_PITCH_INFLUENCE = 0.08,
	ROTATION_SMOOTHING       = 0.22,

	-- Roll axis
	ROLL_STIFFNESS   = 50,
	ROLL_DAMPING     = 0.75,
	MAX_ROLL_ANGLE   = math.rad(45),
	YAW_TO_ROLL      = 0.25,
	SIDE_TO_ROLL     = 0.02,

	-- Direction-change "whip"
	WHIP_THRESHOLD   = 3.0,
	WHIP_STRENGTH    = 1.5,
	WHIP_COOLDOWN    = 0.2,

	-- Smear
	SMEAR_MAX_ANGLE     = math.rad(90),
	SMEAR_SPEED_FULL    = 18,

	-- Idle wag
	WAG_SPEED               = 0.7,
	WAG_AMPLITUDE           = 0.10,
	WAG_FADE_SPEED          = 0.05,
	WAG_SECONDARY_SPEED     = 4.5,
	WAG_SECONDARY_AMPLITUDE = 0.025,
	WAG_PITCH_BOB           = math.rad(1.2),
	WAG_ROLL_AMPLITUDE      = math.rad(2.5),
	WAG_ROLL_SPEED          = 3.8,

	-- Animation / pose influence
	ANIMATION_INFLUENCE         = 0.45,
	ANIMATION_LINEAR_INFLUENCE  = 0.30,
	ANIMATION_MOTOR_INFLUENCE   = 0.22,
	ANIMATION_BLEND_SMOOTHING   = 0.25,

	-- Coupling
	YAW_TO_PITCH_COUPLING       = 0.05,
	PITCH_TO_YAW_COUPLING       = 0.015,
	YAW_VELOCITY_TO_PITCH       = 0.0015,
	PITCH_VELOCITY_TO_YAW       = 0.0008,

	-- Chaotic secondary motion
	CHAOS_STRENGTH   = 0.012,
	CHAOS_RESPONSE   = 0.08,
	CHAOS_DAMPING    = 0.90,

	-- Speed-dependent inversion / exaggeration
	SPRINT_SPEED             = 16,
	MIN_INVERSION_STRENGTH   = 0.12,
	MAX_INVERSION_STRENGTH   = 0.70,

	-- Safety clamps
	MAX_ANGLE  = math.rad(60),

	-- Fixed timestep
	TIMESTEP   = 1 / 120,
}

CONFIGS.tails = {
	-- Spring-damper physics (stronger + more damped)
	STIFFNESS       = 40,     -- slightly higher to resist lag buildup
	DAMPING         = 0.85,   -- MUCH higher to kill infinite oscillation
	INERTIA_SCALE   = 0.045,  -- reduced so velocity doesn't stack endlessly

	-- Deadzones (slightly increased for heavy tails)
	SIDE_DEADZONE     = 2.1,
	FORWARD_DEADZONE  = 0.75,

	-- Forward-trailing bias
	FORWARD_DRAG_BIAS      = -0.010,
	FORWARD_YAW_REDUCTION  = 0.88,
	FORWARD_MOTION_FULL    = 10,
	YAW_UNLOCK_ANGLE       = math.rad(12),
	YAW_FULL_UNLOCK        = math.rad(24),

	-- Momentum / trailing behavior (critical fixes)
	MOTION_TRAIL_SMOOTHING   = 0.20,  -- smoother = less jitter stacking
	MOTION_ACCEL_INFLUENCE   = 0.035, -- reduced to stop runaway acceleration
	TRAIL_RELEASE            = 0.22,  -- MUCH stronger decay (key fix)

	-- Rotation tracking (less reactive)
	ROTATION_YAW_INFLUENCE   = 0.035,
	ROTATION_ROLL_INFLUENCE  = 0.45,
	ROTATION_PITCH_INFLUENCE = 0.08,
	ROTATION_SMOOTHING       = 0.30,  -- smoother = more stable

	-- Roll axis (more controlled)
	ROLL_STIFFNESS   = 28,
	ROLL_DAMPING     = 0.75,
	MAX_ROLL_ANGLE   = math.rad(32),
	YAW_TO_ROLL      = 0.22,
	SIDE_TO_ROLL     = 0.014,

	-- Direction-change "whip" (reduced energy injection)
	WHIP_THRESHOLD   = 4.5,
	WHIP_STRENGTH    = 1.1,
	WHIP_COOLDOWN    = 0.28,

	-- Smear
	SMEAR_MAX_ANGLE     = math.rad(75),
	SMEAR_SPEED_FULL    = 24,

	-- Idle wag (toned down for heavy mass feel)
	WAG_SPEED               = 0.8,
	WAG_AMPLITUDE           = 0.12,
	WAG_FADE_SPEED          = 0.12,
	WAG_SECONDARY_SPEED     = 5.5,
	WAG_SECONDARY_AMPLITUDE = 0.028,
	WAG_PITCH_BOB           = math.rad(1.5),
	WAG_ROLL_AMPLITUDE      = math.rad(3.2),
	WAG_ROLL_SPEED          = 4.2,

	-- Animation / pose influence
	ANIMATION_INFLUENCE         = 0.55,
	ANIMATION_LINEAR_INFLUENCE  = 0.35,
	ANIMATION_MOTOR_INFLUENCE   = 0.25,
	ANIMATION_BLEND_SMOOTHING   = 0.35,

	-- Coupling (reduced feedback loops)
	YAW_TO_PITCH_COUPLING       = 0.060,
	PITCH_TO_YAW_COUPLING       = 0.018,
	YAW_VELOCITY_TO_PITCH       = 0.0015,
	PITCH_VELOCITY_TO_YAW       = 0.0010,

	-- Chaotic secondary motion (heavily damped)
	CHAOS_STRENGTH   = 0.006,
	CHAOS_RESPONSE   = 0.05,
	CHAOS_DAMPING    = 0.96,

	-- Speed-dependent inversion / exaggeration
	SPRINT_SPEED             = 16,
	MIN_INVERSION_STRENGTH   = 0.15,
	MAX_INVERSION_STRENGTH   = 0.75,

	-- Safety clamps (slightly tighter)
	MAX_ANGLE  = math.rad(60),

	-- Fixed timestep
	TIMESTEP   = 1 / 120,
}

-- ================================================================
--  WHITELISTS (per accessory type)
-- ================================================================

local WHITELISTS = {
	wings = {
		"Accessory (Devil Wings)",
	},
	tails = {
		"Circle.032Accessory",
		"Accessory (Handle)",
	},
}

-- ================================================================
--  MODE-SELECTION UI
-- ================================================================

local function createModeUI(onSelected)
	local playerGui = player:WaitForChild("PlayerGui")

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name             = "PhysicsModeSelector"
	screenGui.ResetOnSpawn     = false
	screenGui.IgnoreGuiInset   = true
	screenGui.ZIndexBehavior   = Enum.ZIndexBehavior.Sibling
	screenGui.Parent           = playerGui

	local blur = Instance.new("Frame")
	blur.Size                   = UDim2.fromScale(1, 1)
	blur.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
	blur.BackgroundTransparency = 0.55
	blur.BorderSizePixel        = 0
	blur.ZIndex                 = 1
	blur.Parent                 = screenGui

	local card = Instance.new("Frame")
	card.Size             = UDim2.fromOffset(340, 230)
	card.Position         = UDim2.fromScale(0.5, 0.5)
	card.AnchorPoint      = Vector2.new(0.5, 0.5)
	card.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
	card.BorderSizePixel  = 0
	card.ZIndex           = 2
	card.Parent           = screenGui

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 14)
	cardCorner.Parent       = card

	local cardStroke = Instance.new("UIStroke")
	cardStroke.Color        = Color3.fromRGB(90, 90, 130)
	cardStroke.Thickness    = 1.5
	cardStroke.Transparency = 0.35
	cardStroke.Parent       = card

	local dragBar = Instance.new("TextLabel")
	dragBar.Size             = UDim2.new(1, 0, 0, 36)
	dragBar.Position         = UDim2.fromOffset(0, 0)
	dragBar.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
	dragBar.BorderSizePixel  = 0
	dragBar.Text             = "⚙  Physics Mode"
	dragBar.TextColor3       = Color3.fromRGB(200, 200, 220)
	dragBar.Font             = Enum.Font.GothamBold
	dragBar.TextSize         = 14
	dragBar.ZIndex           = 3
	dragBar.Parent           = card

	local dragBarCorner = Instance.new("UICorner")
	dragBarCorner.CornerRadius = UDim.new(0, 14)
	dragBarCorner.Parent       = dragBar

	local dragBarBottom = Instance.new("Frame")
	dragBarBottom.Size             = UDim2.new(1, 0, 0, 14)
	dragBarBottom.Position         = UDim2.new(0, 0, 1, -14)
	dragBarBottom.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
	dragBarBottom.BorderSizePixel  = 0
	dragBarBottom.ZIndex           = 3
	dragBarBottom.Parent           = dragBar

	local sub = Instance.new("TextLabel")
	sub.Size               = UDim2.new(1, -20, 0, 24)
	sub.Position           = UDim2.fromOffset(10, 42)
	sub.BackgroundTransparency = 1
	sub.Text               = "Select which accessories to apply physics to:"
	sub.TextColor3         = Color3.fromRGB(150, 150, 170)
	sub.Font               = Enum.Font.Gotham
	sub.TextSize           = 12
	sub.TextWrapped        = true
	sub.TextXAlignment     = Enum.TextXAlignment.Left
	sub.ZIndex             = 3
	sub.Parent             = card

	local BUTTON_DATA = {
		{ label = "🕊️  Wings", mode = "wings", color = Color3.fromRGB(90, 120, 220) },
		{ label = "🐾  Tails", mode = "tails", color = Color3.fromRGB(200, 90, 140) },
		{ label = "✨  Both",  mode = "both",  color = Color3.fromRGB(100, 180, 140) },
	}

	local buttonHolder = Instance.new("Frame")
	buttonHolder.Size                   = UDim2.new(1, -24, 0, 54)
	buttonHolder.Position               = UDim2.fromOffset(12, 80)
	buttonHolder.BackgroundTransparency = 1
	buttonHolder.ZIndex                 = 3
	buttonHolder.Parent                 = card

	local buttonLayout = Instance.new("UIListLayout")
	buttonLayout.FillDirection       = Enum.FillDirection.Horizontal
	buttonLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	buttonLayout.VerticalAlignment   = Enum.VerticalAlignment.Center
	buttonLayout.Padding             = UDim.new(0, 10)
	buttonLayout.SortOrder           = Enum.SortOrder.LayoutOrder
	buttonLayout.Parent              = buttonHolder

	local function makeButton(data, order)
		local btn = Instance.new("TextButton")
		btn.Size            = UDim2.fromOffset(90, 50)
		btn.BackgroundColor3 = data.color
		btn.BorderSizePixel = 0
		btn.Text            = data.label
		btn.TextColor3      = Color3.fromRGB(255, 255, 255)
		btn.Font            = Enum.Font.GothamBold
		btn.TextSize        = 13
		btn.AutoButtonColor = false
		btn.LayoutOrder     = order
		btn.ZIndex          = 4
		btn.Parent          = buttonHolder

		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 10)
		btnCorner.Parent       = btn

		local btnStroke = Instance.new("UIStroke")
		btnStroke.Color        = Color3.fromRGB(255, 255, 255)
		btnStroke.Thickness    = 1
		btnStroke.Transparency = 0.75
		btnStroke.Parent       = btn

		btn.MouseEnter:Connect(function()
			TweenService:Create(btn, TweenInfo.new(0.12), {
				BackgroundColor3 = data.color:Lerp(Color3.fromRGB(255,255,255), 0.18),
				Size = UDim2.fromOffset(94, 54),
			}):Play()
		end)
		btn.MouseLeave:Connect(function()
			TweenService:Create(btn, TweenInfo.new(0.12), {
				BackgroundColor3 = data.color,
				Size = UDim2.fromOffset(90, 50),
			}):Play()
		end)

		btn.MouseButton1Click:Connect(function()
			TweenService:Create(card, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
				Size     = UDim2.fromOffset(340, 0),
				Position = UDim2.new(0.5, 0, 0.5, 115),
			}):Play()
			TweenService:Create(blur, TweenInfo.new(0.25), {
				BackgroundTransparency = 1,
			}):Play()
			task.delay(0.28, function()
				screenGui:Destroy()
				onSelected(data.mode)
			end)
		end)

		return btn
	end

	for i, data in ipairs(BUTTON_DATA) do
		makeButton(data, i)
	end

	local credit = Instance.new("TextLabel")
	credit.Size                  = UDim2.new(1, -20, 0, 20)
	credit.Position              = UDim2.new(0, 10, 1, -28)
	credit.BackgroundTransparency = 1
	credit.Text                  = "Tail/Wing physics made by cvtmvtt ♡"
	credit.TextColor3            = Color3.fromRGB(100, 100, 120)
	credit.Font                  = Enum.Font.Gotham
	credit.TextSize              = 11
	credit.TextXAlignment        = Enum.TextXAlignment.Center
	credit.ZIndex                = 3
	credit.Parent                = card

	local dragging   = false
	local dragOffset = Vector2.zero

	dragBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging   = true
			local absPos = card.AbsolutePosition
			dragOffset = Vector2.new(
				input.Position.X - absPos.X,
				input.Position.Y - absPos.Y
			)
		end
	end)

	game:GetService("UserInputService").InputChanged:Connect(function(input)
		if dragging and (
			input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch
		) then
			local vp = screenGui.AbsoluteSize
			local nx  = math.clamp(input.Position.X - dragOffset.X, 0, vp.X - card.AbsoluteSize.X)
			local ny  = math.clamp(input.Position.Y - dragOffset.Y, 0, vp.Y - card.AbsoluteSize.Y)
			card.Position  = UDim2.fromOffset(nx, ny)
			card.AnchorPoint = Vector2.zero
		end
	end)

	game:GetService("UserInputService").InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	card.Size        = UDim2.fromOffset(340, 0)
	card.Position    = UDim2.new(0.5, 0, 0.5, 115)
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	blur.BackgroundTransparency = 1

	TweenService:Create(card, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size     = UDim2.fromOffset(340, 230),
		Position = UDim2.fromScale(0.5, 0.5),
	}):Play()
	TweenService:Create(blur, TweenInfo.new(0.25), {
		BackgroundTransparency = 0.55,
	}):Play()
end

-- ================================================================
--  ACCESSORY CLASSIFICATION
-- ================================================================

local function classifyAccessory(acc, mode)
	local nameLower = acc.Name:lower()

	local function matchesWhitelist(list)
		for _, name in ipairs(list) do
			if acc.Name == name then return true end
		end
		return false
	end

	if mode == "wings" or mode == "both" then
		if nameLower:find("wing") or matchesWhitelist(WHITELISTS.wings) then
			return "wings"
		end
	end

	if mode == "tails" or mode == "both" then
		if nameLower:find("tail") or matchesWhitelist(WHITELISTS.tails) then
			return "tails"
		end
	end

	return nil
end

-- ================================================================
--  SMALL HELPERS
-- ================================================================

local function clamp01(x)  return math.clamp(x, 0, 1) end

local function smoothstep(edge0, edge1, x)
	if edge0 == edge1 then return x >= edge1 and 1 or 0 end
	local t = math.clamp((x - edge0) / (edge1 - edge0), 0, 1)
	return t * t * (3 - 2 * t)
end

local function hashString(str)
	local h = 0
	for i = 1, #str do
		h = (h * 33 + string.byte(str, i)) % 100000
	end
	return h
end

-- ================================================================
--  ANIMATION SAMPLING
-- ================================================================

local function getMotorWeight(name: string): number
	name = name:lower()
	if name == "rootjoint" or name == "root" then return 1.00 end
	if name == "waist"                        then return 0.95 end
	if name == "neck"                         then return 0.55 end
	if name:find("hip")                       then return 0.30 end
	if name:find("shoulder")                  then return 0.18 end
	if name:find("knee") or name:find("elbow")then return 0.08 end
	return 0.10
end

local function collectAnimationMotors(char)
	local tracked = {}
	for _, desc in ipairs(char:GetDescendants()) do
		if desc:IsA("Motor6D") then
			table.insert(tracked, {
				motor = desc,
				weight = getMotorWeight(desc.Name),
				prevTransform = nil,
			})
		end
	end
	return tracked
end

local function cframeDeltaToLocalVectors(prevCF: CFrame, currentCF: CFrame, dt: number)
	dt = math.max(dt, 1e-3)
	local delta = prevCF:Inverse() * currentCF
	local axis, angle = delta:ToAxisAngle()
	return (currentCF.Position - prevCF.Position) / dt, axis * (angle / dt)
end

-- ================================================================
--  WELD DETECTION
-- ================================================================

--[[
	Finds the AccessoryWeld that controls this handle.
	Roblox names the auto-generated weld "AccessoryWeld"; we prefer
	that over a generic Weld search so we never accidentally grab an
	internal decoration weld that some accessories contain.
]]
local function findAccessoryWeld(handle)
	-- Preferred: the canonical AccessoryWeld child
	local named = handle:FindFirstChild("AccessoryWeld")
	if named and named:IsA("Weld") then return named end

	-- Fallback: poll for any Weld (original behaviour)
	for _ = 1, 30 do
		local w = handle:FindFirstChildWhichIsA("Weld")
		if w then return w end
		task.wait(0.05)
	end

	return nil
end

-- ================================================================
--  SMART PIVOT DETECTION
-- ================================================================

--[[
	Returns the best rotation pivot (in Handle-local space).

	Priority order:
	  1. Named Attachment  — designer-specified; most accurate for
	     purpose-built accessories (AccessoryAttachment etc.)
	  2. Generic Attachment that sits near the weld C0 position —
	     avoids using decorative attachments far from the joint.
	  3. Geometric face-snap — for elongated meshes whose weld C0
	     sits near their geometric centre, we find which face of the
	     bounding box is nearest to Part0 and lerp the pivot toward
	     that face.  This naturally places the pivot at the "root"
	     end of a tail or the shoulder end of a wing.
	  4. weld.C0.Position — original behaviour, always safe.
]]
local NAMED_ATTACHMENT_CANDIDATES = {
	"AccessoryAttachment",
	"BodyBackAttachment",
	"WaistBackAttachment",
	"TailAttachment",
	"WingAttachment",
	"NeckAttachment",
	"RootAttachment",
}

local function findBestPivot(handle, weld, part0)
	-- 1. Named attachment
	for _, name in ipairs(NAMED_ATTACHMENT_CANDIDATES) do
		local att = handle:FindFirstChild(name)
		if att and att:IsA("Attachment") then
			return att.Position
		end
	end

	-- 2. Generic attachment — only if it's reasonably close to the weld joint
	local att = handle:FindFirstChildOfClass("Attachment")
	if att then
		local maxDim = math.max(handle.Size.X, handle.Size.Y, handle.Size.Z)
		if (att.Position - weld.C0.Position).Magnitude < maxDim * 0.55 then
			return att.Position
		end
	end

	-- 3. Geometric face-snap
	--    Find which face-centre of the bounding box is nearest to part0.
	--    Only apply if the result differs meaningfully from C0 (avoids
	--    shifting the pivot on accessories that are already centred correctly,
	--    e.g. devil-horn pairs whose C0 is intentionally centred).
	local ok, part0Local = pcall(function()
		return handle.CFrame:PointToObjectSpace(part0.Position)
	end)

	if ok then
		local half  = handle.Size * 0.5
		local faces = {
			Vector3.new(-half.X, 0, 0), Vector3.new( half.X, 0, 0),
			Vector3.new(0, -half.Y, 0), Vector3.new(0,  half.Y, 0),
			Vector3.new(0, 0, -half.Z), Vector3.new(0, 0,  half.Z),
		}

		local bestFace, bestDist = Vector3.zero, math.huge
		for _, face in ipairs(faces) do
			local d = (face - part0Local).Magnitude
			if d < bestDist then bestDist = d; bestFace = face end
		end

		-- Only shift if the face is meaningfully different from C0.
		-- We lerp rather than snap so we don't fully discard the original
		-- C0 intent (some accessories deliberately offset their pivot).
		local shiftDist = (bestFace - weld.C0.Position).Magnitude
		if shiftDist > handle.Size.Magnitude * 0.12 then
			return weld.C0.Position:Lerp(bestFace, 0.55)
		end
	end

	-- 4. Fallback
	return weld.C0.Position
end

-- ================================================================
--  SIZE-BASED CONFIG SCALING
-- ================================================================

--[[
	Automatically tunes physics parameters for accessories that are
	significantly larger than a "standard" reference (~3 studs on the
	longest axis).

	Large accessories receive:
	  • Higher damping   — heavier object, more velocity resistance.
	  • Wider deadzones  — prevents micro-inputs from jostling a large tail.
	  • Lower inertia    — avoids exaggerated over-swing on a big mesh.
	  • Calmer chaos     — secondary noise looks like jitter on big tails.
	  • Gentler wag      — idle sway should feel weighty, not frantic.
	  • Sluggish trail   — large object reacts more slowly to direction changes.
	  • Softer springs   — oscillates at a lower, more natural frequency.
	  • Higher whip gate — requires stronger input to trigger the impulse.

	Returns the original table unchanged for accessories within ±15 % of
	the reference size so standard accessories pay zero overhead.
]]
local SCALE_REF_SIZE = 3.0  -- studs (longest axis of a "reference" accessory)

local function scaleConfigForSize(handle, baseConfig)
	local maxDim = math.max(handle.Size.X, handle.Size.Y, handle.Size.Z)
	local scale  = math.clamp(maxDim / SCALE_REF_SIZE, 0.5, 5.0)

	if scale <= 1.15 then return baseConfig end  -- standard size — no changes

	local cfg    = {}
	for k, v in pairs(baseConfig) do cfg[k] = v end  -- shallow copy

	local excess = scale - 1.0  -- 0 at reference, positive above it

	-- Heavier feel
	cfg.DAMPING              = baseConfig.DAMPING      * (1 + excess * 0.40)
	cfg.ROLL_DAMPING         = baseConfig.ROLL_DAMPING * (1 + excess * 0.35)

	-- Less twitchy on small inputs
	cfg.SIDE_DEADZONE        = baseConfig.SIDE_DEADZONE    * (1 + excess * 0.30)
	cfg.FORWARD_DEADZONE     = baseConfig.FORWARD_DEADZONE * (1 + excess * 0.25)

	-- Less over-swing
	cfg.INERTIA_SCALE        = baseConfig.INERTIA_SCALE / (1 + excess * 0.35)

	-- Calmer secondary noise
	cfg.CHAOS_STRENGTH       = baseConfig.CHAOS_STRENGTH / (1 + excess * 0.60)

	-- Gentler idle sway
	cfg.WAG_AMPLITUDE              = baseConfig.WAG_AMPLITUDE              / (1 + excess * 0.30)
	cfg.WAG_SECONDARY_AMPLITUDE    = baseConfig.WAG_SECONDARY_AMPLITUDE    / (1 + excess * 0.30)
	cfg.WAG_PITCH_BOB              = baseConfig.WAG_PITCH_BOB              / (1 + excess * 0.20)
	cfg.WAG_ROLL_AMPLITUDE         = baseConfig.WAG_ROLL_AMPLITUDE         / (1 + excess * 0.20)

	-- Sluggish trail (more inertia in direction tracking)
	cfg.MOTION_TRAIL_SMOOTHING     = baseConfig.MOTION_TRAIL_SMOOTHING / (1 + excess * 0.20)

	-- Softer springs (lower natural frequency)
	cfg.STIFFNESS                  = baseConfig.STIFFNESS      / (1 + excess * 0.25)
	cfg.ROLL_STIFFNESS             = baseConfig.ROLL_STIFFNESS / (1 + excess * 0.25)

	-- Stronger input needed to trigger whip impulse
	cfg.WHIP_THRESHOLD             = baseConfig.WHIP_THRESHOLD * (1 + excess * 0.20)

	return cfg
end

-- ================================================================
--  CORE PHYSICS SETUP
-- ================================================================

local activeConnections = {}

local function cleanupAll()
	for _, c in ipairs(activeConnections) do
		if typeof(c) == "RBXScriptConnection" then c:Disconnect() end
	end
	activeConnections = {}
end

print("made by cvtmvtt <3")

local function setupPhysicsAccessory(accessory, char, CONFIG)
	local handle = accessory:FindFirstChild("Handle")
	if not handle then
		warn("[TailPhysics] No Handle:", accessory.Name); return
	end

	-- Use smart weld finder
	local weld = findAccessoryWeld(handle)
	if not weld then
		warn("[TailPhysics] No Weld:", accessory.Name); return
	end

	local part0 = weld.Part0
	if not part0 then
		warn("[TailPhysics] Weld has no Part0:", accessory.Name); return
	end

	local humanoid = char:FindFirstChildOfClass("Humanoid")
	local root     = char:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root then
		warn("[TailPhysics] Missing Humanoid or HRP:", accessory.Name); return
	end

	-- Auto-scale config for large accessories before anything else
	CONFIG = scaleConfigForSize(handle, CONFIG)

	-- Capture rest pose using smart pivot detection
	local baseC0    = weld.C0
	local pivotPos  = findBestPivot(handle, weld, part0)
	local baseC0Rot = CFrame.new(-pivotPos.X, -pivotPos.Y, -pivotPos.Z) * baseC0

	-- ── Physics state ──────────────────────────────────────────
	local yawAngle,   yawVel   = 0, 0
	local pitchAngle, pitchVel = 0, 0
	local rollAngle,  rollVel  = 0, 0

	local accumulator = 0
	local wagTime     = 0
	local lastRootPos = root.Position
	local firstFrame  = true

	-- ── Idle tracking ──────────────────────────────────────────
	--   When the character has been standing still long enough we
	--   apply a gentle velocity bleed so residual spring energy
	--   doesn't sustain micro-oscillations indefinitely.
	local idleTime          = 0
	local IDLE_SPEED_THRESH = 0.6   -- stud/s below which we count as "idle"
	local IDLE_BLEED_DELAY  = 1.8   -- seconds before bleed activates
	local IDLE_BLEED_RATE   = 0.018 -- fraction of velocity removed per frame

	-- ── Rotation tracking ─────────────────────────────────────
	local prevRootCF      = root.CFrame
	local smoothedYawRate = 0

	-- ── Direction-change whip ─────────────────────────────────
	local prevMotionDir   = Vector3.zero
	local whipCooldown    = 0

	-- ── Wobble detection & stabilisation ──────────────────────
	local WOBBLE = {
		FLIP_DECAY           = 7,
		FLIP_THRESHOLD       = 5,
		MIN_VEL              = 0.6,
		HARD_VEL_LIMIT       = 35,
		STABILIZE_DURATION   = 0.45,
		STABILIZE_VEL_DRAG   = 0.88,
		STABILIZE_ANGLE_PULL = 0.06,
	}

	local yawFlipScore,   prevYawVelSign   = 0, 0
	local pitchFlipScore, prevPitchVelSign = 0, 0
	local rollFlipScore,  prevRollVelSign  = 0, 0
	local stabilizeTimer = 0

	-- ── Animation-aware state ──────────────────────────────────
	local animationMotors    = collectAnimationMotors(char)
	local lastBodyRelativeCF = nil
	local smoothedLocalVel   = Vector3.zero
	local smoothedAnimLinear = Vector3.zero
	local smoothedAnimAngular= Vector3.zero
	local motionMemory       = Vector3.zero
	local prevMotionMemory   = Vector3.zero
	local chaosYaw, chaosPitch         = 0, 0
	local chaosYawVel, chaosPitchVel   = 0, 0

	local seed       = (hashString(accessory.Name) % 1000) / 1000
	local chaosPhase = seed * math.pi * 2

	local conn
	conn = RunService.Heartbeat:Connect(function(dt)
		dt = math.clamp(dt, 0.001, 0.1)

		-- Cap accumulator: prevents a single lag spike from
		-- firing dozens of sub-steps and amplifying energy.
		accumulator = math.min(accumulator + dt, CONFIG.TIMESTEP * 8)
		wagTime     += dt
		whipCooldown = math.max(0, whipCooldown - dt)

		if not character or not character.Parent
			or not char or not char.Parent
			or not part0 or not part0.Parent
			or not weld  or not weld.Parent then
			if conn then conn:Disconnect() end
			return
		end

		root     = char:FindFirstChild("HumanoidRootPart")
		humanoid = char:FindFirstChildOfClass("Humanoid")
		if not root or not humanoid then return end

		if #animationMotors == 0 then
			animationMotors = collectAnimationMotors(char)
		end

		-- ── Movement sampling ─────────────────────────────────
		local curPos  = root.Position
		local charVel
		if firstFrame then
			charVel    = Vector3.zero
			firstFrame = false
		else
			charVel = (curPos - lastRootPos) / dt
		end
		lastRootPos = curPos

		local localVel   = root.CFrame:VectorToObjectSpace(charVel)
		local moveIntent = humanoid.MoveDirection * humanoid.WalkSpeed
		local moveLocal  = root.CFrame:VectorToObjectSpace(moveIntent)

		-- ── Rotation tracking ─────────────────────────────────
		local rotDelta       = prevRootCF:Inverse() * root.CFrame
		local rotAxis, rotAngle = rotDelta:ToAxisAngle()
		local rawYawRate     = rotAxis.Y * rotAngle / math.max(dt, 1e-3)
		smoothedYawRate      = smoothedYawRate + (rawYawRate - smoothedYawRate) * CONFIG.ROTATION_SMOOTHING
		prevRootCF           = root.CFrame

		-- ── Animation / pose sampling ─────────────────────────
		local bodyRelativeCF  = root.CFrame:ToObjectSpace(part0.CFrame)
		local bodyPoseLinear  = Vector3.zero
		local bodyPoseAngular = Vector3.zero
		if lastBodyRelativeCF then
			bodyPoseLinear, bodyPoseAngular =
				cframeDeltaToLocalVectors(lastBodyRelativeCF, bodyRelativeCF, dt)
		end
		lastBodyRelativeCF = bodyRelativeCF

		local motorPoseLinear  = Vector3.zero
		local motorPoseAngular = Vector3.zero
		for _, tracker in ipairs(animationMotors) do
			local motor = tracker.motor
			if motor and motor.Parent and motor.Part0 then
				local currentTransform = motor.Transform
				if tracker.prevTransform then
					local delta2 = tracker.prevTransform:Inverse() * currentTransform
					local axis2, angle2 = delta2:ToAxisAngle()
					local localAngular2 = axis2 * (angle2 / math.max(dt, 1e-3))
					local localLinear2  = (currentTransform.Position - tracker.prevTransform.Position) / math.max(dt, 1e-3)
					local p0CF = motor.Part0.CFrame
					motorPoseLinear  += root.CFrame:VectorToObjectSpace(p0CF:VectorToWorldSpace(localLinear2))  * tracker.weight
					motorPoseAngular += root.CFrame:VectorToObjectSpace(p0CF:VectorToWorldSpace(localAngular2)) * tracker.weight
				end
				tracker.prevTransform = currentTransform
			end
		end

		local rawLocalVel =
			(localVel  * 0.62) +
			(moveLocal * 0.16) +
			(bodyPoseLinear  * CONFIG.ANIMATION_LINEAR_INFLUENCE) +
			(motorPoseLinear * CONFIG.ANIMATION_MOTOR_INFLUENCE)

		local rawAnimAngular =
			root.CFrame:VectorToObjectSpace(part0.AssemblyAngularVelocity) * 0.55 +
			(bodyPoseAngular  * CONFIG.ANIMATION_INFLUENCE) +
			(motorPoseAngular * CONFIG.ANIMATION_MOTOR_INFLUENCE)

		smoothedLocalVel    = smoothedLocalVel:Lerp(rawLocalVel,      CONFIG.ANIMATION_BLEND_SMOOTHING)
		smoothedAnimLinear  = smoothedAnimLinear:Lerp(bodyPoseLinear + motorPoseLinear, CONFIG.ANIMATION_BLEND_SMOOTHING)
		smoothedAnimAngular = smoothedAnimAngular:Lerp(rawAnimAngular, CONFIG.ANIMATION_BLEND_SMOOTHING)

		local effectiveLocalVel = smoothedLocalVel
		effectiveLocalVel += smoothedAnimLinear * 0.20

		-- ── Idle time accumulation ────────────────────────────
		--   Track how long the character has been effectively still.
		--   We measure the smoothed velocity magnitude so brief pauses
		--   mid-walk don't falsely trigger the bleed.
		local currentSpeed = effectiveLocalVel.Magnitude
		if currentSpeed < IDLE_SPEED_THRESH then
			idleTime = idleTime + dt
		else
			idleTime = 0
		end

		-- ── Direction-change WHIP impulse ─────────────────────
		local flatVel   = Vector3.new(effectiveLocalVel.X, 0, effectiveLocalVel.Z)
		local flatSpeed = flatVel.Magnitude
		if flatSpeed > 0.1 then
			local flatDir = flatVel / flatSpeed
			if prevMotionDir.Magnitude > 0.1 then
				local dotDir = flatDir:Dot(prevMotionDir)
				if dotDir < -0.35 and flatSpeed >= CONFIG.WHIP_THRESHOLD and whipCooldown <= 0
					and stabilizeTimer <= 0 then
					yawVel   += -effectiveLocalVel.X * CONFIG.INERTIA_SCALE * CONFIG.WHIP_STRENGTH * 60
					pitchVel += effectiveLocalVel.Z  * CONFIG.INERTIA_SCALE * CONFIG.WHIP_STRENGTH * 60
					rollVel  += -effectiveLocalVel.X * CONFIG.SIDE_TO_ROLL  * CONFIG.WHIP_STRENGTH * 40
					whipCooldown = CONFIG.WHIP_COOLDOWN
				end
			end
			prevMotionDir = flatDir
		end

		-- Momentum trail
		prevMotionMemory = motionMemory
		motionMemory     = motionMemory:Lerp(effectiveLocalVel, CONFIG.MOTION_TRAIL_SMOOTHING)
		local motionDelta = (motionMemory - prevMotionMemory) / math.max(dt, 1e-3)

		-- ── Fixed-timestep spring-damper integration ──────────
		while accumulator >= CONFIG.TIMESTEP do
			local ts = CONFIG.TIMESTEP
			local motion = motionMemory + (motionDelta * CONFIG.MOTION_ACCEL_INFLUENCE)

			local speed       = motion.Magnitude
			local speedFactor = smoothstep(0, CONFIG.SPRINT_SPEED, speed)

			local forwardMotion  = math.max(-motion.Z, 0)
			local backwardMotion = math.max(motion.Z,  0)
			local sideMotion     = motion.X

			local sideAbs  = math.abs(sideMotion)
			local sideEase = smoothstep(CONFIG.SIDE_DEADZONE * 0.65, CONFIG.SIDE_DEADZONE * 2.0, sideAbs)
			sideMotion *= sideEase

			local forwardAbs = math.abs(motion.Z)
			if forwardAbs < CONFIG.FORWARD_DEADZONE then
				motion         = Vector3.new(motion.X, motion.Y, 0)
				forwardMotion  = 0
				backwardMotion = 0
			end

			local yawUnlock = smoothstep(CONFIG.YAW_UNLOCK_ANGLE, CONFIG.YAW_FULL_UNLOCK, math.abs(pitchAngle))
			local yawGate   = (0.20 + 0.80 * yawUnlock) * (1 - speedFactor * CONFIG.FORWARD_YAW_REDUCTION)

			local inversionStrength = CONFIG.MIN_INVERSION_STRENGTH +
				(CONFIG.MAX_INVERSION_STRENGTH - CONFIG.MIN_INVERSION_STRENGTH) * speedFactor

			local targetYaw   = -sideMotion * CONFIG.INERTIA_SCALE * yawGate
			local targetPitch = (-motion.Z  * CONFIG.INERTIA_SCALE * 0.55) * inversionStrength
			targetPitch += forwardMotion  * CONFIG.FORWARD_DRAG_BIAS * inversionStrength
			targetPitch -= backwardMotion * CONFIG.FORWARD_DRAG_BIAS * (0.45 + 0.55 * speedFactor)

			targetYaw   += -smoothedYawRate * CONFIG.ROTATION_YAW_INFLUENCE
			targetPitch += math.abs(smoothedYawRate) * CONFIG.ROTATION_PITCH_INFLUENCE * 0.015

			targetYaw   += smoothedAnimAngular.Y * 0.035
			targetYaw   += smoothedAnimLinear.X  * 0.006
			targetPitch += -smoothedAnimAngular.X * 0.045
			targetPitch += -smoothedAnimLinear.Z  * 0.012

			targetPitch += math.abs(targetYaw) * CONFIG.YAW_TO_PITCH_COUPLING
			targetYaw   += pitchAngle  * CONFIG.PITCH_TO_YAW_COUPLING
			targetPitch += yawVel      * CONFIG.YAW_VELOCITY_TO_PITCH
			targetYaw   += pitchVel    * CONFIG.PITCH_VELOCITY_TO_YAW

			local targetRoll = yawAngle * CONFIG.YAW_TO_ROLL
				+ sideMotion * CONFIG.SIDE_TO_ROLL
				- smoothedYawRate * CONFIG.ROTATION_ROLL_INFLUENCE * 0.04

			-- Chaos secondary motion
			chaosPhase += ts * (1.8 + speedFactor * 2.4)
			local chaoticDrive = clamp01((motionDelta.Magnitude / math.max(CONFIG.SPRINT_SPEED, 1)) * 1.35)
			local chaosWaveA   = math.sin(chaosPhase * 1.7 + seed * 9.1)
			local chaosWaveB   = math.cos(chaosPhase * 2.3 + seed * 5.7)
			local chaosWaveC   = math.sin(chaosPhase * 0.9 + seed * 13.3)

			-- Suppress chaos during idle to prevent resting micro-jitter
			local chaosIdleSuppress = math.max(0, 1 - smoothstep(IDLE_BLEED_DELAY, IDLE_BLEED_DELAY + 1.5, idleTime))

			local chaosTargetYaw   = (chaosWaveA * 0.65 + chaosWaveB * 0.35) * CONFIG.CHAOS_STRENGTH * chaoticDrive * chaosIdleSuppress
			local chaosTargetPitch = (chaosWaveC * 0.70 + chaosWaveA * 0.30) * (CONFIG.CHAOS_STRENGTH * 0.72) * chaoticDrive * chaosIdleSuppress

			chaosYawVel   += ((chaosTargetYaw   - chaosYaw)   * CONFIG.CHAOS_RESPONSE - chaosYawVel   * (1 - CONFIG.CHAOS_DAMPING)) * ts * 60
			chaosPitchVel += ((chaosTargetPitch - chaosPitch) * CONFIG.CHAOS_RESPONSE - chaosPitchVel * (1 - CONFIG.CHAOS_DAMPING)) * ts * 60
			chaosYaw   += chaosYawVel   * ts
			chaosPitch += chaosPitchVel * ts

			targetYaw   += chaosYaw
			targetPitch += chaosPitch

			-- Idle wag
			local wagFade      = math.max(0, 1 - speed * CONFIG.WAG_FADE_SPEED)
			local idleStrength = wagFade * wagFade

			local primaryWag   = math.sin(wagTime * CONFIG.WAG_SPEED)
			local secondaryWag = math.sin(wagTime * CONFIG.WAG_SECONDARY_SPEED + 0.8)

			targetYaw   += (primaryWag * CONFIG.WAG_AMPLITUDE + secondaryWag * CONFIG.WAG_SECONDARY_AMPLITUDE) * idleStrength
			targetPitch += math.abs(primaryWag) * CONFIG.WAG_PITCH_BOB * idleStrength
			targetRoll  += math.sin(wagTime * CONFIG.WAG_ROLL_SPEED) * CONFIG.WAG_ROLL_AMPLITUDE * idleStrength

			-- Semi-implicit Euler
			yawVel    += (-CONFIG.STIFFNESS      * (yawAngle   - targetYaw)   - CONFIG.DAMPING      * yawVel)   * ts
			yawAngle  += yawVel   * ts

			pitchVel  += (-CONFIG.STIFFNESS      * (pitchAngle - targetPitch) - CONFIG.DAMPING      * pitchVel) * ts
			pitchAngle+= pitchVel * ts

			rollVel   += (-CONFIG.ROLL_STIFFNESS * (rollAngle  - targetRoll)  - CONFIG.ROLL_DAMPING * rollVel)  * ts
			rollAngle += rollVel  * ts

			accumulator -= CONFIG.TIMESTEP
		end

		-- ── Idle velocity bleed ───────────────────────────────
		--   Once the character has been still for IDLE_BLEED_DELAY seconds,
		--   gently drain residual spring velocity so the accessory settles
		--   to its wag-only rest pose instead of drifting indefinitely.
		--   Strength ramps up smoothly so the transition is imperceptible.
		if idleTime > IDLE_BLEED_DELAY then
			local bleedStrength = math.min(1, (idleTime - IDLE_BLEED_DELAY) * 0.5)
			local velDecay      = 1 - IDLE_BLEED_RATE * bleedStrength * (dt * 60)
			yawVel   *= velDecay
			pitchVel *= velDecay
			rollVel  *= velDecay
		end

		-- ── Wobble detection & auto-correction ────────────────
		-- Layer 1: hard velocity cap
		yawVel   = math.clamp(yawVel,   -WOBBLE.HARD_VEL_LIMIT, WOBBLE.HARD_VEL_LIMIT)
		pitchVel = math.clamp(pitchVel, -WOBBLE.HARD_VEL_LIMIT, WOBBLE.HARD_VEL_LIMIT)
		rollVel  = math.clamp(rollVel,  -WOBBLE.HARD_VEL_LIMIT, WOBBLE.HARD_VEL_LIMIT)

		-- Layer 2: decay flip-score counters over time
		local flipDecay = dt * WOBBLE.FLIP_DECAY
		yawFlipScore   = math.max(0, yawFlipScore   - flipDecay)
		pitchFlipScore = math.max(0, pitchFlipScore - flipDecay)
		rollFlipScore  = math.max(0, rollFlipScore  - flipDecay)

		-- Layer 3: count velocity sign reversals per axis
		local function trackFlip(vel, lastSign, score)
			local s = vel >  WOBBLE.MIN_VEL and  1
				or vel < -WOBBLE.MIN_VEL and -1
				or 0
			if s ~= 0 and lastSign ~= 0 and s ~= lastSign then
				score += 1
			end
			return s ~= 0 and s or lastSign, score
		end

		prevYawVelSign,   yawFlipScore   = trackFlip(yawVel,   prevYawVelSign,   yawFlipScore)
		prevPitchVelSign, pitchFlipScore = trackFlip(pitchVel, prevPitchVelSign, pitchFlipScore)
		prevRollVelSign,  rollFlipScore  = trackFlip(rollVel,  prevRollVelSign,  rollFlipScore)

		-- Layer 4: trigger stabiliser when any axis is wobbling
		if yawFlipScore   >= WOBBLE.FLIP_THRESHOLD
			or pitchFlipScore >= WOBBLE.FLIP_THRESHOLD
			or rollFlipScore  >= WOBBLE.FLIP_THRESHOLD then
			stabilizeTimer = WOBBLE.STABILIZE_DURATION
			yawFlipScore, pitchFlipScore, rollFlipScore = 0, 0, 0
		end

		-- Layer 5: progressive recovery drag
		if stabilizeTimer > 0 then
			stabilizeTimer   = math.max(0, stabilizeTimer - dt)
			local strength   = stabilizeTimer / WOBBLE.STABILIZE_DURATION
			local velMul     = 1 - (1 - WOBBLE.STABILIZE_VEL_DRAG)   * strength
			local angleBleed = WOBBLE.STABILIZE_ANGLE_PULL * strength
			yawVel    *= velMul;   yawAngle   *= (1 - angleBleed)
			pitchVel  *= velMul;   pitchAngle *= (1 - angleBleed)
			rollVel   *= velMul;   rollAngle  *= (1 - angleBleed)
		end

		-- Smear: speed-adaptive angle clamp
		local smearFactor = smoothstep(0, CONFIG.SMEAR_SPEED_FULL, motionMemory.Magnitude)
		local dynamicMax  = CONFIG.MAX_ANGLE + (CONFIG.SMEAR_MAX_ANGLE - CONFIG.MAX_ANGLE) * smearFactor

		yawAngle   = math.clamp(yawAngle,   -dynamicMax,            dynamicMax)
		pitchAngle = math.clamp(pitchAngle, -dynamicMax,            dynamicMax)
		rollAngle  = math.clamp(rollAngle,  -CONFIG.MAX_ROLL_ANGLE, CONFIG.MAX_ROLL_ANGLE)

		-- Write result back to weld
		local physRot = CFrame.Angles(pitchAngle, yawAngle, rollAngle)
		weld.C0 = CFrame.new(pivotPos) * physRot * baseC0Rot
	end)

	return conn
end

-- ================================================================
--  CHARACTER INITIALISATION
-- ================================================================

local function initCharacter(char, mode)
	character = char
	cleanupAll()

	char:WaitForChild("HumanoidRootPart")
	char:WaitForChild("LowerTorso")
	char:WaitForChild("UpperTorso")
	char:WaitForChild("Humanoid")

	task.wait(0.25)

	local function trySetup(child)
		if not child:IsA("Accessory") then return end
		local accType = classifyAccessory(child, mode)
		if accType then
			local conn = setupPhysicsAccessory(child, char, CONFIGS[accType])
			if conn then table.insert(activeConnections, conn) end
		end
	end

	for _, child in ipairs(char:GetChildren()) do
		trySetup(child)
	end

	local childAddedConn = char.ChildAdded:Connect(function(child)
		task.wait(0.1)
		trySetup(child)
	end)
	table.insert(activeConnections, childAddedConn)
end

-- ================================================================
--  ENTRY POINT — show UI, then init on selection
-- ================================================================

createModeUI(function(selectedMode)
	initCharacter(character, selectedMode)

	player.CharacterAdded:Connect(function(char)
		initCharacter(char, selectedMode)
	end)
	player.CharacterRemoving:Connect(cleanupAll)
end)
