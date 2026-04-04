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
	-- Spring-damper physics
	STIFFNESS       = 32,
	DAMPING         = 0.55,
	INERTIA_SCALE   = 0.065,

	-- Deadzones
	SIDE_DEADZONE     = 1.80,
	FORWARD_DEADZONE  = 0.60,

	-- Forward-trailing bias
	FORWARD_DRAG_BIAS      = -0.008,
	FORWARD_YAW_REDUCTION  = 0.82,
	FORWARD_MOTION_FULL    = 8,
	YAW_UNLOCK_ANGLE       = math.rad(10),
	YAW_FULL_UNLOCK        = math.rad(20),

	-- Momentum / trailing behavior
	MOTION_TRAIL_SMOOTHING   = 0.14,
	MOTION_ACCEL_INFLUENCE   = 0.055,
	TRAIL_RELEASE            = 0.10,

	-- Rotation tracking
	ROTATION_YAW_INFLUENCE   = 0.05,
	ROTATION_ROLL_INFLUENCE  = 0.55,
	ROTATION_PITCH_INFLUENCE = 0.10,
	ROTATION_SMOOTHING       = 0.22,

	-- Roll axis
	ROLL_STIFFNESS   = 24,
	ROLL_DAMPING     = 0.50,
	MAX_ROLL_ANGLE   = math.rad(38),
	YAW_TO_ROLL      = 0.30,
	SIDE_TO_ROLL     = 0.018,

	-- Direction-change "whip"
	WHIP_THRESHOLD   = 3.5,
	WHIP_STRENGTH    = 1.80,
	WHIP_COOLDOWN    = 0.18,

	-- Smear
	SMEAR_MAX_ANGLE     = math.rad(88),
	SMEAR_SPEED_FULL    = 20,

	-- Idle wag
	WAG_SPEED               = 1,
	WAG_AMPLITUDE           = 0.175,
	WAG_FADE_SPEED          = 0.085,
	WAG_SECONDARY_SPEED     = 6.5,
	WAG_SECONDARY_AMPLITUDE = 0.042,
	WAG_PITCH_BOB           = math.rad(2.0),
	WAG_ROLL_AMPLITUDE      = math.rad(4.5),
	WAG_ROLL_SPEED          = 4.8,

	-- Animation / pose influence
	ANIMATION_INFLUENCE         = 0.65,
	ANIMATION_LINEAR_INFLUENCE  = 0.42,
	ANIMATION_MOTOR_INFLUENCE   = 0.30,
	ANIMATION_BLEND_SMOOTHING   = 0.28,

	-- Coupling
	YAW_TO_PITCH_COUPLING       = 0.080,
	PITCH_TO_YAW_COUPLING       = 0.024,
	YAW_VELOCITY_TO_PITCH       = 0.0022,
	PITCH_VELOCITY_TO_YAW       = 0.0014,

	-- Chaotic secondary motion
	CHAOS_STRENGTH   = 0.012,
	CHAOS_RESPONSE   = 0.08,
	CHAOS_DAMPING    = 0.90,

	-- Speed-dependent inversion / exaggeration
	SPRINT_SPEED             = 16,
	MIN_INVERSION_STRENGTH   = 0.20,
	MAX_INVERSION_STRENGTH   = 1.00,

	-- Safety clamps
	MAX_ANGLE  = math.rad(70),

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

-- Returns a Promise-like: calls onSelected(mode) where mode is
-- "wings", "tails", or "both".
local function createModeUI(onSelected)
	local playerGui = player:WaitForChild("PlayerGui")

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name             = "PhysicsModeSelector"
	screenGui.ResetOnSpawn     = false
	screenGui.IgnoreGuiInset   = true
	screenGui.ZIndexBehavior   = Enum.ZIndexBehavior.Sibling
	screenGui.Parent           = playerGui

	-- Backdrop blur / dim
	local blur = Instance.new("Frame")
	blur.Size            = UDim2.fromScale(1, 1)
	blur.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	blur.BackgroundTransparency = 0.55
	blur.BorderSizePixel = 0
	blur.ZIndex          = 1
	blur.Parent          = screenGui

	-- Card
	local card = Instance.new("Frame")
	card.Size                    = UDim2.fromOffset(340, 230)
	card.Position                = UDim2.fromScale(0.5, 0.5)
	card.AnchorPoint             = Vector2.new(0.5, 0.5)
	card.BackgroundColor3        = Color3.fromRGB(18, 18, 24)
	card.BorderSizePixel         = 0
	card.ZIndex                  = 2
	card.Parent                  = screenGui

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 14)
	cardCorner.Parent       = card

	local cardStroke = Instance.new("UIStroke")
	cardStroke.Color       = Color3.fromRGB(90, 90, 130)
	cardStroke.Thickness   = 1.5
	cardStroke.Transparency = 0.35
	cardStroke.Parent      = card

	-- Drag bar
	local dragBar = Instance.new("TextLabel")
	dragBar.Size                  = UDim2.new(1, 0, 0, 36)
	dragBar.Position              = UDim2.fromOffset(0, 0)
	dragBar.BackgroundColor3      = Color3.fromRGB(28, 28, 38)
	dragBar.BorderSizePixel       = 0
	dragBar.Text                  = "⚙  Physics Mode"
	dragBar.TextColor3            = Color3.fromRGB(200, 200, 220)
	dragBar.Font                  = Enum.Font.GothamBold
	dragBar.TextSize              = 14
	dragBar.ZIndex                = 3
	dragBar.Parent                = card

	local dragBarCorner = Instance.new("UICorner")
	dragBarCorner.CornerRadius = UDim.new(0, 14)
	dragBarCorner.Parent       = dragBar

	-- Clamp corners to top only via a cover strip
	local dragBarBottom = Instance.new("Frame")
	dragBarBottom.Size                    = UDim2.new(1, 0, 0, 14)
	dragBarBottom.Position                = UDim2.new(0, 0, 1, -14)
	dragBarBottom.BackgroundColor3        = Color3.fromRGB(28, 28, 38)
	dragBarBottom.BorderSizePixel         = 0
	dragBarBottom.ZIndex                  = 3
	dragBarBottom.Parent                  = dragBar

	-- Sub-label
	local sub = Instance.new("TextLabel")
	sub.Size             = UDim2.new(1, -20, 0, 24)
	sub.Position         = UDim2.fromOffset(10, 42)
	sub.BackgroundTransparency = 1
	sub.Text             = "Select which accessories to apply physics to:"
	sub.TextColor3       = Color3.fromRGB(150, 150, 170)
	sub.Font             = Enum.Font.Gotham
	sub.TextSize         = 12
	sub.TextWrapped      = true
	sub.TextXAlignment   = Enum.TextXAlignment.Left
	sub.ZIndex           = 3
	sub.Parent           = card

	-- Button factory
	local BUTTON_DATA = {
		{ label = "🕊️  Wings", mode = "wings", color = Color3.fromRGB(90, 120, 220) },
		{ label = "🐾  Tails", mode = "tails", color = Color3.fromRGB(200, 90, 140) },
		{ label = "✨  Both",  mode = "both",  color = Color3.fromRGB(100, 180, 140) },
	}

	local buttonHolder = Instance.new("Frame")
	buttonHolder.Size                    = UDim2.new(1, -24, 0, 54)
	buttonHolder.Position                = UDim2.fromOffset(12, 80)
	buttonHolder.BackgroundTransparency  = 1
	buttonHolder.ZIndex                  = 3
	buttonHolder.Parent                  = card

	local buttonLayout = Instance.new("UIListLayout")
	buttonLayout.FillDirection  = Enum.FillDirection.Horizontal
	buttonLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	buttonLayout.VerticalAlignment   = Enum.VerticalAlignment.Center
	buttonLayout.Padding        = UDim.new(0, 10)
	buttonLayout.SortOrder      = Enum.SortOrder.LayoutOrder
	buttonLayout.Parent         = buttonHolder

	local function makeButton(data, order)
		local btn = Instance.new("TextButton")
		btn.Size                  = UDim2.fromOffset(90, 50)
		btn.BackgroundColor3      = data.color
		btn.BorderSizePixel       = 0
		btn.Text                  = data.label
		btn.TextColor3            = Color3.fromRGB(255, 255, 255)
		btn.Font                  = Enum.Font.GothamBold
		btn.TextSize              = 13
		btn.AutoButtonColor       = false
		btn.LayoutOrder           = order
		btn.ZIndex                = 4
		btn.Parent                = buttonHolder

		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 10)
		btnCorner.Parent       = btn

		local btnStroke = Instance.new("UIStroke")
		btnStroke.Color       = Color3.fromRGB(255, 255, 255)
		btnStroke.Thickness   = 1
		btnStroke.Transparency = 0.75
		btnStroke.Parent      = btn

		-- Hover
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
			-- Animate out
			TweenService:Create(card, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
				Size = UDim2.fromOffset(340, 0),
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

	-- Credit line
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

	-- ── Drag logic ────────────────────────────────────────────
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

	-- Entrance animation
	card.Size = UDim2.fromOffset(340, 0)
	card.Position = UDim2.new(0.5, 0, 0.5, 115)
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

	local weld
	for _ = 1, 30 do
		weld = handle:FindFirstChildWhichIsA("Weld")
		if weld then break end
		task.wait(0.05)
	end
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

	-- Capture rest pose
	local baseC0    = weld.C0
	local pivotPos  = baseC0.Position
	local baseC0Rot = CFrame.new(-pivotPos.X, -pivotPos.Y, -pivotPos.Z) * baseC0

	-- ── Physics state ──────────────────────────────────────────
	local yawAngle,   yawVel   = 0, 0
	local pitchAngle, pitchVel = 0, 0
	local rollAngle,  rollVel  = 0, 0

	local accumulator = 0
	local wagTime     = 0
	local lastRootPos = root.Position
	local firstFrame  = true

	-- ── Rotation tracking ─────────────────────────────────────
	local prevRootCF      = root.CFrame
	local smoothedYawRate = 0

	-- ── Direction-change whip ─────────────────────────────────
	local prevMotionDir   = Vector3.zero
	local whipCooldown    = 0

	-- ── Wobble detection & stabilisation ──────────────────────
	-- Wobbling = velocity sign reversing faster than the spring
	-- can damp it, causing runaway oscillation.
	-- Detection: count sign-flip events per axis; each flip
	-- increments a score that decays naturally over time.
	-- When score >= threshold the stabiliser engages.
	local WOBBLE = {
		FLIP_DECAY           = 7,     -- score units shed per second (passive decay)
		FLIP_THRESHOLD       = 5,     -- score that triggers stabilisation
		MIN_VEL              = 0.6,   -- |vel| must exceed this for a flip to count
		HARD_VEL_LIMIT       = 35,    -- hard instantaneous cap on any single velocity
		STABILIZE_DURATION   = 0.45,  -- seconds of recovery after trigger
		STABILIZE_VEL_DRAG   = 0.88,  -- velocity multiplied by this per frame during recovery
		STABILIZE_ANGLE_PULL = 0.06,  -- fraction angles are pulled toward 0 per frame
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
		accumulator += dt
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
		local rotDelta    = prevRootCF:Inverse() * root.CFrame
		local rotAxis, rotAngle = rotDelta:ToAxisAngle()
		local rawYawRate  = rotAxis.Y * rotAngle / math.max(dt, 1e-3)
		smoothedYawRate   = smoothedYawRate + (rawYawRate - smoothedYawRate) * CONFIG.ROTATION_SMOOTHING
		prevRootCF        = root.CFrame

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

		-- ── Direction-change WHIP impulse ─────────────────────
		local flatVel   = Vector3.new(effectiveLocalVel.X, 0, effectiveLocalVel.Z)
		local flatSpeed = flatVel.Magnitude
		if flatSpeed > 0.1 then
			local flatDir = flatVel / flatSpeed
			if prevMotionDir.Magnitude > 0.1 then
				local dotDir = flatDir:Dot(prevMotionDir)
				if dotDir < -0.35 and flatSpeed >= CONFIG.WHIP_THRESHOLD and whipCooldown <= 0
					and stabilizeTimer <= 0 then   -- suppress during wobble recovery
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

			-- Base targets
			local targetYaw   = -sideMotion * CONFIG.INERTIA_SCALE * yawGate
			local targetPitch = (-motion.Z  * CONFIG.INERTIA_SCALE * 0.55) * inversionStrength
			targetPitch += forwardMotion  * CONFIG.FORWARD_DRAG_BIAS * inversionStrength
			targetPitch -= backwardMotion * CONFIG.FORWARD_DRAG_BIAS * (0.45 + 0.55 * speedFactor)

			-- Rotation influence
			targetYaw   += -smoothedYawRate * CONFIG.ROTATION_YAW_INFLUENCE
			targetPitch += math.abs(smoothedYawRate) * CONFIG.ROTATION_PITCH_INFLUENCE * 0.015

			-- Animation pose corrections
			targetYaw   += smoothedAnimAngular.Y * 0.035
			targetYaw   += smoothedAnimLinear.X  * 0.006
			targetPitch += -smoothedAnimAngular.X * 0.045
			targetPitch += -smoothedAnimLinear.Z  * 0.012

			-- Natural coupling
			targetPitch += math.abs(targetYaw) * CONFIG.YAW_TO_PITCH_COUPLING
			targetYaw   += pitchAngle  * CONFIG.PITCH_TO_YAW_COUPLING
			targetPitch += yawVel      * CONFIG.YAW_VELOCITY_TO_PITCH
			targetYaw   += pitchVel    * CONFIG.PITCH_VELOCITY_TO_YAW

			-- Roll target
			local targetRoll = yawAngle * CONFIG.YAW_TO_ROLL
				+ sideMotion * CONFIG.SIDE_TO_ROLL
				- smoothedYawRate * CONFIG.ROTATION_ROLL_INFLUENCE * 0.04

			-- Chaos secondary motion
			chaosPhase += ts * (1.8 + speedFactor * 2.4)
			local chaoticDrive = clamp01((motionDelta.Magnitude / math.max(CONFIG.SPRINT_SPEED, 1)) * 1.35)
			local chaosWaveA   = math.sin(chaosPhase * 1.7 + seed * 9.1)
			local chaosWaveB   = math.cos(chaosPhase * 2.3 + seed * 5.7)
			local chaosWaveC   = math.sin(chaosPhase * 0.9 + seed * 13.3)

			local chaosTargetYaw   = (chaosWaveA * 0.65 + chaosWaveB * 0.35) * CONFIG.CHAOS_STRENGTH * chaoticDrive
			local chaosTargetPitch = (chaosWaveC * 0.70 + chaosWaveA * 0.30) * (CONFIG.CHAOS_STRENGTH * 0.72) * chaoticDrive

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

			-- Semi-implicit Euler integration
			yawVel    += (-CONFIG.STIFFNESS * (yawAngle   - targetYaw)   - CONFIG.DAMPING * yawVel)   * ts
			yawAngle  += yawVel   * ts

			pitchVel  += (-CONFIG.STIFFNESS * (pitchAngle - targetPitch) - CONFIG.DAMPING * pitchVel) * ts
			pitchAngle+= pitchVel * ts

			rollVel   += (-CONFIG.ROLL_STIFFNESS * (rollAngle - targetRoll) - CONFIG.ROLL_DAMPING * rollVel) * ts
			rollAngle += rollVel  * ts

			accumulator -= CONFIG.TIMESTEP
		end

		-- ── Wobble detection & auto-correction ────────────────────
		-- Layer 1: hard velocity cap — stops any single runaway frame
		-- from feeding amplified energy into the next step.
		yawVel   = math.clamp(yawVel,   -WOBBLE.HARD_VEL_LIMIT, WOBBLE.HARD_VEL_LIMIT)
		pitchVel = math.clamp(pitchVel, -WOBBLE.HARD_VEL_LIMIT, WOBBLE.HARD_VEL_LIMIT)
		rollVel  = math.clamp(rollVel,  -WOBBLE.HARD_VEL_LIMIT, WOBBLE.HARD_VEL_LIMIT)

		-- Layer 2: decay flip-score counters over time.
		local flipDecay = dt * WOBBLE.FLIP_DECAY
		yawFlipScore   = math.max(0, yawFlipScore   - flipDecay)
		pitchFlipScore = math.max(0, pitchFlipScore - flipDecay)
		rollFlipScore  = math.max(0, rollFlipScore  - flipDecay)

		-- Count genuine velocity sign reversals (ignore noise near zero).
		local function trackFlip(vel, lastSign, score)
			local s = vel >  WOBBLE.MIN_VEL and  1
				or vel < -WOBBLE.MIN_VEL and -1
				or 0
			if s ~= 0 and lastSign ~= 0 and s ~= lastSign then
				score += 1
			end
			-- Preserve last known non-zero sign so short zero-crossings
			-- (during target drag) don't reset the reference.
			return s ~= 0 and s or lastSign, score
		end

		prevYawVelSign,   yawFlipScore   = trackFlip(yawVel,   prevYawVelSign,   yawFlipScore)
		prevPitchVelSign, pitchFlipScore = trackFlip(pitchVel, prevPitchVelSign, pitchFlipScore)
		prevRollVelSign,  rollFlipScore  = trackFlip(rollVel,  prevRollVelSign,  rollFlipScore)

		-- Layer 3: trigger stabiliser when any axis is wobbling.
		if yawFlipScore   >= WOBBLE.FLIP_THRESHOLD
			or pitchFlipScore >= WOBBLE.FLIP_THRESHOLD
			or rollFlipScore  >= WOBBLE.FLIP_THRESHOLD then
			stabilizeTimer = WOBBLE.STABILIZE_DURATION
			-- Reset counters so a fresh trigger needs fresh evidence.
			yawFlipScore, pitchFlipScore, rollFlipScore = 0, 0, 0
		end

		-- Layer 4: apply progressive recovery drag.
		-- Strength is 1 at the start of the window and smoothly
		-- fades to 0, so the transition back to normal feels natural.
		if stabilizeTimer > 0 then
			stabilizeTimer     = math.max(0, stabilizeTimer - dt)
			local strength     = stabilizeTimer / WOBBLE.STABILIZE_DURATION
			local velMul       = 1 - (1 - WOBBLE.STABILIZE_VEL_DRAG)   * strength
			local angleBleed   = WOBBLE.STABILIZE_ANGLE_PULL * strength
			yawVel    *= velMul;   yawAngle   *= (1 - angleBleed)
			pitchVel  *= velMul;   pitchAngle *= (1 - angleBleed)
			rollVel   *= velMul;   rollAngle  *= (1 - angleBleed)
		end

		-- Smaer: speed-adaptive clamp
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
