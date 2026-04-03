-- ============================================================
--  TailPhysics LocalScript  (R15)
--  Physics-based tail simulation inspired by Tux Physics Tails
--  by @R3dTuxedo  –  github.com/R3dTuxedo/tux-physics-tails-v3
-- ============================================================
-- Placement: StarterCharacterScripts  (recommended)
--            or StarterPlayerScripts  (also works)
-- ============================================================

local RunService = game:GetService("RunService")
local Players    = game:GetService("Players")

local player    = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

-- ================================================================
--  CONFIGURATION
-- ================================================================
local CONFIG = {
	-- Spring-damper physics
	STIFFNESS       = 28,            -- Pull-back force toward rest pose (higher = snappier)
	DAMPING         = .7,             -- Oscillation friction      (higher = less bounce)
	INERTIA_SCALE   = 0.045,         -- Overall movement influence on the tail

	-- Make the tail react less to walking side-to-side
	SIDE_DEADZONE   = 1.25,          -- Ignore tiny lateral motion
	FORWARD_DEADZONE = 0.75,         -- Ignore tiny forward/back motion

	-- Forward-trailing bias
	FORWARD_DRAG_BIAS    = -0.012,    -- Extra backward pull when moving forward
	FORWARD_YAW_REDUCTION = 0.88,     -- Reduce yaw while moving forward
	FORWARD_MOTION_FULL   = 8,        -- Speed where forward gating reaches full strength
	YAW_UNLOCK_ANGLE      = math.rad(14), -- Tail must be "below" this much before yaw opens up
	YAW_FULL_UNLOCK       = math.rad(24),  -- Full yaw unlock by this angle

	-- Idle wag (sinusoidal left-right sway when standing still)
	WAG_SPEED       = 5,             -- Wag frequency in rad/s
	WAG_AMPLITUDE   = 0.09,          -- Wag magnitude in radians
	WAG_FADE_SPEED  = 0.12,          -- How quickly wag fades as the character moves

	-- Animation / pose influence
	ANIMATION_INFLUENCE         = 0.35,  -- How much animation pose influences the tail
	ANIMATION_LINEAR_INFLUENCE  = 0.42,   -- How much animated body translation affects tail motion
	ANIMATION_MOTOR_INFLUENCE   = 0.30,   -- How much joint motor transforms affect tail motion
	ANIMATION_BLEND_SMOOTHING   = 0.18,   -- Lower = smoother, higher = more responsive

	-- Safety clamps
	MAX_ANGLE       = math.rad(70),  -- Maximum swing angle (radians)

	-- Fixed timestep for frame-rate-independent simulation
	TIMESTEP        = 1 / 120,
}

-- ================================================================
--  ACCESSORY DETECTION
--  An accessory gets physics applied if:
--    (a) its Name contains "tail" (case-insensitive), OR
--    (b) its Name is in the WHITELIST below (exact match).
-- ================================================================
local WHITELIST = {
	"Circle.032Accessory",
	-- Add more exact accessory names here as needed:
	-- "MyCustomTailAccessory",
}

local function isTailAccessory(acc)
	if acc.Name:lower():find("tail") then
		return true
	end
	for _, name in ipairs(WHITELIST) do
		if acc.Name == name then
			return true
		end
	end
	return false
end

-- ================================================================
--  ANIMATION SAMPLING
--  We sample body-relative motion + Motor6D.Transform so tail motion
--  reacts to animation pose changes, not just root velocity.
-- ================================================================
local function getMotorWeight(name: string): number
	name = name:lower()

	if name == "rootjoint" or name == "root" then
		return 1.00
	end
	if name == "waist" then
		return 0.95
	end
	if name == "neck" then
		return 0.55
	end
	if name:find("hip") then
		return 0.30
	end
	if name:find("shoulder") then
		return 0.18
	end
	if name:find("knee") or name:find("elbow") then
		return 0.08
	end

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

	local angularVel = axis * (angle / dt)
	local linearVel = (currentCF.Position - prevCF.Position) / dt

	return linearVel, angularVel
end

-- ================================================================
--  CORE PHYSICS SETUP
-- ================================================================
local activeConnections = {}

local function cleanupAll()
	for _, c in ipairs(activeConnections) do
		if typeof(c) == "RBXScriptConnection" then
			c:Disconnect()
		end
	end
	activeConnections = {}
end

local function setupPhysicsTail(accessory, char)
	local handle = accessory:FindFirstChild("Handle")
	if not handle then
		warn("[TailPhysics] Accessory has no Handle:", accessory.Name)
		return
	end

	-- Wait for Roblox to create the AccessoryWeld
	local weld
	for _ = 1, 30 do
		weld = handle:FindFirstChildWhichIsA("Weld")
		if weld then
			break
		end
		task.wait(0.05)
	end
	if not weld then
		warn("[TailPhysics] No Weld found for accessory:", accessory.Name)
		return
	end

	local part0 = weld.Part0
	if not part0 then
		warn("[TailPhysics] Weld has no Part0 for accessory:", accessory.Name)
		return
	end

	local humanoid = char:FindFirstChildOfClass("Humanoid")
	local root = char:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root then
		warn("[TailPhysics] Missing Humanoid or HumanoidRootPart for accessory:", accessory.Name)
		return
	end

	-- Capture rest pose
	local baseC0 = weld.C0
	local pivotPos = baseC0.Position
	local baseC0Rot = CFrame.new(-pivotPos.X, -pivotPos.Y, -pivotPos.Z) * baseC0

	-- Physics state
	local yawAngle, yawVel = 0, 0
	local pitchAngle, pitchVel = 0, 0

	local accumulator = 0
	local wagTime = 0
	local lastRootPos = root.Position
	local firstFrame = true

	-- Animation-aware state
	local animationMotors = collectAnimationMotors(char)
	local lastBodyRelativeCF = nil
	local smoothedLocalVel = Vector3.zero
	local smoothedAnimLinear = Vector3.zero
	local smoothedAnimAngular = Vector3.zero

	local conn
	conn = RunService.Heartbeat:Connect(function(dt)
		dt = math.clamp(dt, 0.001, 0.1)
		accumulator += dt
		wagTime += dt

		-- Safety: stop if anything important is gone
		if not character
			or not character.Parent
			or not char
			or not char.Parent
			or not part0
			or not part0.Parent
			or not weld
			or not weld.Parent then
			if conn then
				conn:Disconnect()
			end
			return
		end

		root = char:FindFirstChild("HumanoidRootPart")
		humanoid = char:FindFirstChildOfClass("Humanoid")
		if not root or not humanoid then
			return
		end

		-- Rebuild animation motor cache if needed (useful after respawn edge cases)
		if #animationMotors == 0 then
			animationMotors = collectAnimationMotors(char)
		end

		-- ============================================================
		-- Movement sampling
		-- ============================================================

		-- Character velocity in world space from root motion
		local curPos = root.Position
		local charVel
		if firstFrame then
			charVel = Vector3.zero
			firstFrame = false
		else
			charVel = (curPos - lastRootPos) / dt
		end
		lastRootPos = curPos

		-- Base motion in local space
		local localVel = root.CFrame:VectorToObjectSpace(charVel)

		-- Add a small amount of movement intent so the tail feels responsive
		-- even before the root velocity fully updates.
		local moveIntent = humanoid.MoveDirection * humanoid.WalkSpeed
		local moveLocal = root.CFrame:VectorToObjectSpace(moveIntent)

		-- ============================================================
		-- Animation / pose sampling
		-- ============================================================

		-- Track body pose relative to root so animation-driven torso shifts
		-- are detected separately from world locomotion.
		local bodyRelativeCF = root.CFrame:ToObjectSpace(part0.CFrame)
		local bodyPoseLinear = Vector3.zero
		local bodyPoseAngular = Vector3.zero

		if lastBodyRelativeCF then
			bodyPoseLinear, bodyPoseAngular = cframeDeltaToLocalVectors(lastBodyRelativeCF, bodyRelativeCF, dt)
		end
		lastBodyRelativeCF = bodyRelativeCF

		-- Sample Motor6D.Transform changes to capture animation blending,
		-- pose transitions, leaning, crouching, and other joint-driven motion.
		local motorPoseLinear = Vector3.zero
		local motorPoseAngular = Vector3.zero

		for _, tracker in ipairs(animationMotors) do
			local motor = tracker.motor
			if motor and motor.Parent and motor.Part0 then
				local currentTransform = motor.Transform
				if tracker.prevTransform then
					local delta = tracker.prevTransform:Inverse() * currentTransform
					local axis, angle = delta:ToAxisAngle()
					local localAngular = axis * (angle / math.max(dt, 1e-3))
					local localLinear = (currentTransform.Position - tracker.prevTransform.Position) / math.max(dt, 1e-3)

					-- Convert motor-local motion into world and then into root-local space.
					-- This lets animation pose shifts affect the tail directionally.
					local part0CF = motor.Part0.CFrame
					local worldLinear = part0CF:VectorToWorldSpace(localLinear)
					local worldAngular = part0CF:VectorToWorldSpace(localAngular)

					motorPoseLinear += root.CFrame:VectorToObjectSpace(worldLinear) * tracker.weight
					motorPoseAngular += root.CFrame:VectorToObjectSpace(worldAngular) * tracker.weight
				end

				tracker.prevTransform = currentTransform
			end
		end

		-- Blend + smooth the motion so walking affects the tail less aggressively
		-- while still allowing pose and animation movement to influence it.
		local rawLocalVel =
			(localVel * 0.62) +
			(moveLocal * 0.16) +
			(bodyPoseLinear * CONFIG.ANIMATION_LINEAR_INFLUENCE) +
			(motorPoseLinear * CONFIG.ANIMATION_MOTOR_INFLUENCE)

		local rawAnimAngular =
			root.CFrame:VectorToObjectSpace(part0.AssemblyAngularVelocity) * 0.55 +
			(bodyPoseAngular * CONFIG.ANIMATION_INFLUENCE) +
			(motorPoseAngular * CONFIG.ANIMATION_MOTOR_INFLUENCE)

		smoothedLocalVel = smoothedLocalVel:Lerp(rawLocalVel, CONFIG.ANIMATION_BLEND_SMOOTHING)
		smoothedAnimLinear = smoothedAnimLinear:Lerp(bodyPoseLinear + motorPoseLinear, CONFIG.ANIMATION_BLEND_SMOOTHING)
		smoothedAnimAngular = smoothedAnimAngular:Lerp(rawAnimAngular, CONFIG.ANIMATION_BLEND_SMOOTHING)

		-- Final effective local velocity used by tail simulation
		local effectiveLocalVel = smoothedLocalVel

		-- Fold in a small amount of animation linear motion so the tail reacts
		-- to stepping, leaning, torso bob, and animated positioning.
		effectiveLocalVel += smoothedAnimLinear * 0.20

		-- ============================================================
		-- Fixed-timestep spring-damper integration
		-- ============================================================
		while accumulator >= CONFIG.TIMESTEP do
			local ts = CONFIG.TIMESTEP

			-- Positive Z means moving backward in object space.
			-- We use the absolute longitudinal speed for gating so forward/backward
			-- motion behaves consistently, while the pitch direction itself is inverted.
			local longitudinalMotion = math.abs(effectiveLocalVel.Z)
			local forwardMotion = math.max(-effectiveLocalVel.Z, 0)
			local backwardMotion = math.max(effectiveLocalVel.Z, 0)
			local sideMotion = effectiveLocalVel.X

			-- Reduce small twitch from walking / animation noise
			if math.abs(sideMotion) < CONFIG.SIDE_DEADZONE then
				sideMotion = 0
			end
			if math.abs(effectiveLocalVel.Z) < CONFIG.FORWARD_DEADZONE then
				effectiveLocalVel = Vector3.new(effectiveLocalVel.X, effectiveLocalVel.Y, 0)
				longitudinalMotion = math.abs(effectiveLocalVel.Z)
				forwardMotion = math.max(-effectiveLocalVel.Z, 0)
				backwardMotion = math.max(effectiveLocalVel.Z, 0)
			end

			local forwardFactor = math.clamp(longitudinalMotion / CONFIG.FORWARD_MOTION_FULL, 0, 1)
			local belowFactor = math.clamp(
				(math.abs(pitchAngle) - CONFIG.YAW_UNLOCK_ANGLE) / (CONFIG.YAW_FULL_UNLOCK - CONFIG.YAW_UNLOCK_ANGLE),
				0,
				1
			)

			-- When moving, keep the tail from snapping too freely sideways.
			-- The unlock still depends on how far the tail has already dropped.
			local yawGate = (1 - forwardFactor * CONFIG.FORWARD_YAW_REDUCTION) * belowFactor
			local targetYaw = -sideMotion * CONFIG.INERTIA_SCALE * yawGate

			-- Invert forward/backward behavior:
			--  * walking forward now pushes the tail backward
			--  * walking backward now pushes the tail forward
			local targetPitch = (-effectiveLocalVel.Z * CONFIG.INERTIA_SCALE * 0.55)
			targetPitch += forwardMotion * CONFIG.FORWARD_DRAG_BIAS
			targetPitch -= backwardMotion * CONFIG.FORWARD_DRAG_BIAS

			-- Animation pose adds subtle corrections so the tail follows
			-- torso tilts, crouches, leaning, and moving poses.
			targetYaw += smoothedAnimAngular.Y * 0.035
			targetYaw += smoothedAnimLinear.X * 0.006

			targetPitch += -smoothedAnimAngular.X * 0.045
			targetPitch += -smoothedAnimLinear.Z * 0.012

			-- Idle wag fades out when moving
			local speed = effectiveLocalVel.Magnitude
			local wagFade = math.max(0, 1 - speed * CONFIG.WAG_FADE_SPEED)
			targetYaw += math.sin(wagTime * CONFIG.WAG_SPEED) * CONFIG.WAG_AMPLITUDE * wagFade

			-- Semi-implicit Euler
			yawVel = yawVel + (-CONFIG.STIFFNESS * (yawAngle - targetYaw) - CONFIG.DAMPING * yawVel) * ts
			yawAngle = yawAngle + yawVel * ts

			pitchVel = pitchVel + (-CONFIG.STIFFNESS * (pitchAngle - targetPitch) - CONFIG.DAMPING * pitchVel) * ts
			pitchAngle = pitchAngle + pitchVel * ts

			accumulator -= CONFIG.TIMESTEP
		end

		-- Hard clamp to prevent extreme / clipping poses
		yawAngle = math.clamp(yawAngle, -CONFIG.MAX_ANGLE, CONFIG.MAX_ANGLE)
		pitchAngle = math.clamp(pitchAngle, -CONFIG.MAX_ANGLE, CONFIG.MAX_ANGLE)

		-- Write rotation back to the weld
		local physRot = CFrame.Angles(pitchAngle, yawAngle, 0)
		weld.C0 = CFrame.new(pivotPos) * physRot * baseC0Rot
	end)

	return conn
end

-- ================================================================
--  CHARACTER INITIALISATION
-- ================================================================
local function initCharacter(char)
	character = char
	cleanupAll()

	char:WaitForChild("HumanoidRootPart")
	char:WaitForChild("LowerTorso")
	char:WaitForChild("UpperTorso")
	char:WaitForChild("Humanoid")

	-- Small delay to let Roblox attach accessories and create their welds
	task.wait(0.25)

	-- Apply physics to any matching accessories already on the character
	for _, child in ipairs(char:GetChildren()) do
		if child:IsA("Accessory") and isTailAccessory(child) then
			local conn = setupPhysicsTail(child, char)
			if conn then
				table.insert(activeConnections, conn)
			end
		end
	end

	-- Watch for accessories added at runtime
	local childAddedConn = char.ChildAdded:Connect(function(child)
		if child:IsA("Accessory") and isTailAccessory(child) then
			task.wait(0.1) -- let Roblox create the weld first
			local conn = setupPhysicsTail(child, char)
			if conn then
				table.insert(activeConnections, conn)
			end
		end
	end)
	table.insert(activeConnections, childAddedConn)
end

-- ================================================================
--  LIFECYCLE
-- ================================================================
initCharacter(character)

player.CharacterAdded:Connect(initCharacter)
player.CharacterRemoving:Connect(cleanupAll)
